import 'package:test/test.dart';
import 'package:dartframe/src/core/ndarray_config.dart';
import 'package:dartframe/src/core/shape.dart';
import 'package:dartframe/src/storage/inmemory_backend.dart';
import 'package:dartframe/src/storage/chunked_backend.dart';

void main() {
  setUp(() {
    // Reset to defaults before each test
    NDArrayConfig.resetToDefaults();
  });

  group('NDArrayConfig - Defaults', () {
    test('has sensible defaults', () {
      expect(NDArrayConfig.maxMemoryBytes, equals(1024 * 1024 * 1024));
      expect(NDArrayConfig.defaultChunkSize, equals(1000));
      expect(NDArrayConfig.maxCachedChunks, equals(10));
      expect(NDArrayConfig.lazyByDefault, isTrue);
      expect(NDArrayConfig.autoSelectBackend, isTrue);
    });
  });

  group('NDArrayConfig - Memory Settings', () {
    test('can modify memory limits', () {
      NDArrayConfig.maxMemoryBytes = 2 * 1024 * 1024 * 1024;
      expect(NDArrayConfig.maxMemoryBytes, equals(2 * 1024 * 1024 * 1024));
    });

    test('can modify chunk settings', () {
      NDArrayConfig.defaultChunkSize = 5000;
      NDArrayConfig.maxCachedChunks = 20;

      expect(NDArrayConfig.defaultChunkSize, equals(5000));
      expect(NDArrayConfig.maxCachedChunks, equals(20));
    });
  });

  group('NDArrayConfig - Backend Selection', () {
    test('selects InMemory for small data', () {
      var backend = NDArrayConfig.selectBackend(Shape([10, 10]));
      expect(backend, isA<InMemoryBackend>());
    });

    test('selects Chunked for large data', () {
      // 1000x1000 * 8 bytes = 8 MB > chunkedThreshold (100 MB default)
      // Actually, let's make it larger
      NDArrayConfig.chunkedThreshold = 1000; // 1 KB threshold for testing

      var backend = NDArrayConfig.selectBackend(Shape([100, 100]));
      expect(backend, isA<ChunkedBackend>());
    });

    test('respects autoSelectBackend flag', () {
      NDArrayConfig.autoSelectBackend = false;

      var backend = NDArrayConfig.selectBackend(Shape([1000, 1000]));
      expect(backend, isA<InMemoryBackend>());
    });

    test('uses initial data when provided', () {
      var data = List.generate(100, (i) => i);
      var backend = NDArrayConfig.selectBackend(
        Shape([10, 10]),
        initialData: data,
      );

      expect(backend, isA<InMemoryBackend>());
      expect(backend.getValue([0, 0]), equals(0));
    });
  });

  group('NDArrayConfig - Reset', () {
    test('resetToDefaults restores defaults', () {
      NDArrayConfig.maxMemoryBytes = 999;
      NDArrayConfig.defaultChunkSize = 999;
      NDArrayConfig.lazyByDefault = false;

      NDArrayConfig.resetToDefaults();

      expect(NDArrayConfig.maxMemoryBytes, equals(1024 * 1024 * 1024));
      expect(NDArrayConfig.defaultChunkSize, equals(1000));
      expect(NDArrayConfig.lazyByDefault, isTrue);
    });
  });

  group('NDArrayConfig - Serialization', () {
    test('toMap returns configuration', () {
      var config = NDArrayConfig.toMap();

      expect(config, isA<Map<String, dynamic>>());
      expect(config['maxMemoryBytes'], equals(1024 * 1024 * 1024));
      expect(config['defaultChunkSize'], equals(1000));
      expect(config['lazyByDefault'], isTrue);
    });

    test('fromMap loads configuration', () {
      NDArrayConfig.fromMap({
        'maxMemoryBytes': 2 * 1024 * 1024 * 1024,
        'defaultChunkSize': 5000,
        'lazyByDefault': false,
      });

      expect(NDArrayConfig.maxMemoryBytes, equals(2 * 1024 * 1024 * 1024));
      expect(NDArrayConfig.defaultChunkSize, equals(5000));
      expect(NDArrayConfig.lazyByDefault, isFalse);
    });

    test('fromMap ignores unknown keys', () {
      expect(
        () => NDArrayConfig.fromMap({'unknownKey': 123}),
        returnsNormally,
      );
    });

    test('fromMap partial update', () {
      NDArrayConfig.maxMemoryBytes = 999;

      NDArrayConfig.fromMap({'defaultChunkSize': 5000});

      expect(NDArrayConfig.maxMemoryBytes, equals(999));
      expect(NDArrayConfig.defaultChunkSize, equals(5000));
    });
  });

  group('NDArrayConfig - Performance Settings', () {
    test('can modify worker count', () {
      NDArrayConfig.defaultWorkers = 8;
      expect(NDArrayConfig.defaultWorkers, equals(8));
    });

    test('can toggle lazy evaluation', () {
      NDArrayConfig.lazyByDefault = false;
      expect(NDArrayConfig.lazyByDefault, isFalse);
    });

    test('can toggle copy-on-write', () {
      NDArrayConfig.copyOnWrite = false;
      expect(NDArrayConfig.copyOnWrite, isFalse);
    });
  });

  group('NDArrayConfig - Compression Settings', () {
    test('can enable compression', () {
      NDArrayConfig.compressFiles = true;
      expect(NDArrayConfig.compressFiles, isTrue);
    });

    test('can set compression level', () {
      NDArrayConfig.compressionLevel = 9;
      expect(NDArrayConfig.compressionLevel, equals(9));
    });
  });

  group('NDArrayConfig - Behavior Settings', () {
    test('can toggle strict types', () {
      NDArrayConfig.strictTypes = true;
      expect(NDArrayConfig.strictTypes, isTrue);
    });

    test('can set default fill value', () {
      NDArrayConfig.defaultFillValue = -1;
      expect(NDArrayConfig.defaultFillValue, equals(-1));
    });

    test('can enable statistics', () {
      NDArrayConfig.enableStats = true;
      expect(NDArrayConfig.enableStats, isTrue);
    });
  });
}
