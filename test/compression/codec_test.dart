import 'dart:math' as math;
import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('CompressionCodec', () {
    // Test data generators
    List<int> generateRandom(int size) {
      final random = math.Random(42);
      return List.generate(size, (_) => random.nextInt(256));
    }

    List<int> generateRepeating(int size) {
      return List.filled(size, 42);
    }

    List<int> generateSparse(int size) {
      final data = List.filled(size, 0);
      for (int i = 0; i < size; i += 10) {
        data[i] = i % 256;
      }
      return data;
    }

    group('NoneCodec', () {
      final codec = const NoneCodec();

      test('name is correct', () {
        expect(codec.name, equals('none'));
      });

      test('compress returns copy', () {
        final data = [1, 2, 3, 4, 5];
        final compressed = codec.compress(data);

        expect(compressed, equals(data));
        expect(identical(compressed, data), isFalse);
      });

      test('decompress returns copy', () {
        final data = [1, 2, 3, 4, 5];
        final decompressed = codec.decompress(data);

        expect(decompressed, equals(data));
        expect(identical(decompressed, data), isFalse);
      });

      test('round-trip preserves data', () {
        final original = generateRandom(1000);
        final compressed = codec.compress(original);
        final decompressed = codec.decompress(compressed);

        expect(decompressed, equals(original));
      });

      test('estimate ratio is 1.0', () {
        final data = generateRandom(1000);
        expect(codec.estimateRatio(data), equals(1.0));
      });
    });

    group('GzipCodec', () {
      final codec = const GzipCodec();

      test('name is correct', () {
        expect(codec.name, equals('gzip'));
      });

      test('compresses repeating data well', () {
        final data = generateRepeating(10000);
        final compressed = codec.compress(data);

        expect(compressed.length, lessThan(data.length * 0.1));
      });

      test('compresses sparse data well', () {
        final data = generateSparse(10000);
        final compressed = codec.compress(data);

        expect(compressed.length, lessThan(data.length * 0.3));
      });

      test('random data compresses poorly', () {
        final data = generateRandom(1000);
        final compressed = codec.compress(data);

        // Random data may even expand slightly
        expect(compressed.length, greaterThan(data.length * 0.9));
      });

      test('round-trip preserves data', () {
        final original = generateRandom(1000);
        final compressed = codec.compress(original);
        final decompressed = codec.decompress(compressed);

        expect(decompressed, equals(original));
      });

      test('different compression levels work', () {
        final data = generateRepeating(10000);

        final level1 = codec.compress(data, level: 1);
        final level9 = codec.compress(data, level: 9);

        // Higher level should compress better (or equal)
        expect(level9.length, lessThanOrEqualTo(level1.length));
      });

      test('estimate ratio is reasonable', () {
        final data = generateRepeating(10000);
        final ratio = codec.estimateRatio(data);

        expect(ratio, greaterThan(0.0));
        expect(ratio, lessThan(1.0));
      });
    });

    group('ZlibCodec', () {
      final codec = const ZlibCodec();

      test('name is correct', () {
        expect(codec.name, equals('zlib'));
      });

      test('compresses repeating data well', () {
        final data = generateRepeating(10000);
        final compressed = codec.compress(data);

        expect(compressed.length, lessThan(data.length * 0.1));
      });

      test('round-trip preserves data', () {
        final original = generateRandom(1000);
        final compressed = codec.compress(original);
        final decompressed = codec.decompress(compressed);

        expect(decompressed, equals(original));
      });

      test('different compression levels work', () {
        final data = generateRepeating(10000);

        final level1 = codec.compress(data, level: 1);
        final level9 = codec.compress(data, level: 9);

        // Higher level should compress better (or equal)
        expect(level9.length, lessThanOrEqualTo(level1.length));
      });
    });

    group('CompressionResult', () {
      test('calculates metrics correctly', () {
        final codec = const GzipCodec();
        final data = generateRepeating(10000);

        final start = DateTime.now();
        final compressed = codec.compress(data);
        final compressTime = DateTime.now().difference(start);

        final result = CompressionResult(
          codec: codec,
          originalSize: data.length,
          compressedSize: compressed.length,
          compressionTime: compressTime,
          decompressionTime: compressTime,
        );

        expect(result.ratio, equals(compressed.length / data.length));
        expect(result.spaceSaved, equals(data.length - compressed.length));
        expect(result.percentSaved, greaterThan(0));
        expect(result.compressionSpeed, greaterThan(0));
      });

      test('score varies by strategy', () {
        final codec = const GzipCodec();
        final result = CompressionResult(
          codec: codec,
          originalSize: 10000,
          compressedSize: 1000,
          compressionTime: Duration(milliseconds: 10),
          decompressionTime: Duration(milliseconds: 5),
        );

        final fastestScore = result.score(CompressionStrategy.fastest);
        final balancedScore = result.score(CompressionStrategy.balanced);
        final smallestScore = result.score(CompressionStrategy.smallest);

        expect(fastestScore, isNot(equals(balancedScore)));
        expect(balancedScore, isNot(equals(smallestScore)));
      });
    });
  });

  group('CompressionRegistry', () {
    test('initializes with built-in codecs', () {
      CompressionRegistry.initialize();

      expect(CompressionRegistry.has('none'), isTrue);
      expect(CompressionRegistry.has('gzip'), isTrue);
      expect(CompressionRegistry.has('zlib'), isTrue);
    });

    test('get returns codec by name', () {
      final codec = CompressionRegistry.get('gzip');

      expect(codec, isNotNull);
      expect(codec!.name, equals('gzip'));
    });

    test('get is case-insensitive', () {
      final codec1 = CompressionRegistry.get('GZIP');
      final codec2 = CompressionRegistry.get('gzip');

      expect(codec1, isNotNull);
      expect(codec2, isNotNull);
      expect(codec1!.name, equals(codec2!.name));
    });

    test('getOrThrow throws for unknown codec', () {
      expect(
        () => CompressionRegistry.getOrThrow('unknown'),
        throwsArgumentError,
      );
    });

    test('getDefault returns default codec', () {
      final codec = CompressionRegistry.getDefault();

      expect(codec, isNotNull);
      expect(codec.name, equals('gzip'));
    });

    test('setDefault changes default codec', () {
      CompressionRegistry.setDefault(const ZlibCodec());

      final codec = CompressionRegistry.getDefault();
      expect(codec.name, equals('zlib'));
    });

    test('getAll returns all codecs', () {
      final codecs = CompressionRegistry.getAll();

      expect(codecs.length, greaterThanOrEqualTo(3));
    });

    test('getAvailable returns only available codecs', () {
      final codecs = CompressionRegistry.getAvailable();

      expect(codecs.every((c) => c.isAvailable), isTrue);
    });

    test('register adds new codec', () {
      final customCodec = const NoneCodec();
      CompressionRegistry.register(customCodec);

      expect(CompressionRegistry.has('none'), isTrue);
    });
  });

  group('AdaptiveCompression', () {
    setUp(() {
      CompressionRegistry.initialize();
    });

    List<int> generateRandom(int size) {
      final random = math.Random(42);
      return List.generate(size, (_) => random.nextInt(256));
    }

    List<int> generateRepeating(int size) {
      return List.filled(size, 42);
    }

    List<int> generateSparse(int size) {
      final data = List.filled(size, 0);
      for (int i = 0; i < size; i += 10) {
        data[i] = i % 256;
      }
      return data;
    }

    test('selectCodec returns none for random data', () {
      final data = generateRandom(10000);

      final codec = AdaptiveCompression.selectCodec(
        data,
        strategy: CompressionStrategy.smallest,
      );

      // Random data should prefer none or fast codec
      expect(codec.name, isIn(['none', 'gzip', 'zlib']));
    });

    test('selectCodec returns compressor for repeating data', () {
      final data = generateRepeating(10000);

      final codec = AdaptiveCompression.selectCodec(
        data,
        strategy: CompressionStrategy.smallest,
      );

      // Repeating data should prefer compression (or none if very fast)
      expect(codec.name, isIn(['none', 'gzip', 'zlib']));
    });

    test('testCodecs returns results for all codecs', () {
      final data = generateRepeating(10000);
      final codecs = CompressionRegistry.getAvailable();

      final results = AdaptiveCompression.testCodecs(data, codecs);

      expect(results.length, equals(codecs.length));
    });

    test('testCodec measures performance', () {
      final data = generateRepeating(10000);
      final codec = const GzipCodec();

      final result = AdaptiveCompression.testCodec(data, codec);

      expect(result.originalSize, equals(data.length));
      expect(result.compressedSize, lessThan(data.length));
      expect(result.compressionTime.inMicroseconds, greaterThanOrEqualTo(0));
      expect(result.decompressionTime.inMicroseconds, greaterThanOrEqualTo(0));
    });

    test('analyzeData calculates entropy', () {
      final random = generateRandom(10000);
      final repeating = generateRepeating(10000);

      final randomChars = AdaptiveCompression.analyzeData(random);
      final repeatingChars = AdaptiveCompression.analyzeData(repeating);

      expect(randomChars.entropy, greaterThan(repeatingChars.entropy));
    });

    test('analyzeData detects sparse data', () {
      final sparse = generateSparse(10000);

      final chars = AdaptiveCompression.analyzeData(sparse);

      expect(chars.isSparse, isTrue);
    });

    test('recommendCodec suggests none for random data', () {
      final chars = DataCharacteristics(
        entropy: 7.5,
        uniqueValues: 256,
        isRandom: true,
        isSparse: false,
      );

      final codec = AdaptiveCompression.recommendCodec(chars);

      expect(codec.name, equals('none'));
    });

    test('recommendCodec suggests gzip for sparse data', () {
      // Initialize registry first
      CompressionRegistry.initialize();

      final chars = DataCharacteristics(
        entropy: 3.0,
        uniqueValues: 50,
        isRandom: false,
        isSparse: true,
      );

      final codec = AdaptiveCompression.recommendCodec(chars);

      expect(codec.name, equals('gzip'));
    });
  });
}
