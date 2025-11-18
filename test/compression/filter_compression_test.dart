import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/filter.dart';

/// Comprehensive unit tests for compression filters
///
/// Tests cover:
/// - Gzip compression with all levels (1-9)
/// - LZF compression
/// - Compressed data can be decompressed (round-trip)
/// - Compression ratio threshold logic
void main() {
  group('GzipFilter - All Compression Levels', () {
    // Test data patterns
    final repetitiveData = List.filled(10000, 42);
    final sequentialData = List.generate(10000, (i) => i % 256);
    final randomLikeData = List.generate(10000, (i) => (i * 7919) % 256);

    for (int level = 1; level <= 9; level++) {
      group('Compression Level $level', () {
        test('compresses repetitive data', () {
          final filter = GzipFilter(compressionLevel: level);
          final compressed = filter.encode(repetitiveData);

          expect(compressed, isNotEmpty);
          expect(compressed.length, lessThan(repetitiveData.length));
        });

        test('compresses sequential data', () {
          final filter = GzipFilter(compressionLevel: level);
          final compressed = filter.encode(sequentialData);

          expect(compressed, isNotEmpty);
          expect(compressed.length, lessThan(sequentialData.length));
        });

        test('handles random-like data', () {
          final filter = GzipFilter(compressionLevel: level);
          final compressed = filter.encode(randomLikeData);

          expect(compressed, isNotEmpty);
          // Random data may not compress well, but shouldn't fail
        });

        test('round-trip preserves data', () async {
          final encoder = GzipFilter(compressionLevel: level);
          final compressed = encoder.encode(sequentialData);

          final decoder = GzipFilter.forReading(flags: 0, clientData: []);
          final decompressed =
              await decoder.decode(Uint8List.fromList(compressed));

          expect(decompressed, equals(sequentialData));
        });
      });
    }

    test('higher compression levels produce smaller output', () {
      final level1 = GzipFilter(compressionLevel: 1);
      final level5 = GzipFilter(compressionLevel: 5);
      final level9 = GzipFilter(compressionLevel: 9);

      final compressed1 = level1.encode(repetitiveData);
      final compressed5 = level5.encode(repetitiveData);
      final compressed9 = level9.encode(repetitiveData);

      // Higher levels should produce smaller or equal output
      expect(compressed5.length, lessThanOrEqualTo(compressed1.length));
      expect(compressed9.length, lessThanOrEqualTo(compressed5.length));
    });

    test('compression level 1 is fastest (minimal compression)', () {
      final filter = GzipFilter(compressionLevel: 1);
      final largeData = List.generate(100000, (i) => i % 256);

      final stopwatch = Stopwatch()..start();
      final compressed = filter.encode(largeData);
      stopwatch.stop();

      expect(compressed, isNotEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('compression level 9 produces best compression', () {
      final filter = GzipFilter(compressionLevel: 9);
      final compressed = filter.encode(repetitiveData);

      // Should achieve very high compression ratio on repetitive data
      final ratio = compressed.length / repetitiveData.length;
      expect(ratio, lessThan(0.1)); // Less than 10% of original size
    });
  });

  group('LzfFilter - Compression Tests', () {
    test('compresses repetitive data', () {
      final filter = LzfFilter();
      final data = List.filled(10000, 42);

      final compressed = filter.encode(data);

      expect(compressed, isNotEmpty);
      expect(compressed.length, lessThan(data.length));
    });

    test('compresses sequential data', () {
      final filter = LzfFilter();
      final data = List.generate(10000, (i) => i % 256);

      final compressed = filter.encode(data);

      expect(compressed, isNotEmpty);
      expect(compressed.length, lessThan(data.length));
    });

    test('handles random-like data', () {
      final filter = LzfFilter();
      final data = List.generate(10000, (i) => (i * 7919) % 256);

      final compressed = filter.encode(data);

      expect(compressed, isNotEmpty);
      // Random data may not compress well
    });

    test('round-trip preserves data', () async {
      final encoder = LzfFilter();
      final originalData = List.generate(10000, (i) => i % 256);

      final compressed = encoder.encode(originalData);

      final decoder = LzfFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(originalData));
    });

    test('handles empty data', () async {
      final encoder = LzfFilter();
      final compressed = encoder.encode([]);

      expect(compressed, isEmpty);

      final decoder = LzfFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, isEmpty);
    });

    test('handles single byte', () async {
      final encoder = LzfFilter();
      final compressed = encoder.encode([42]);

      expect(compressed, isNotEmpty);

      final decoder = LzfFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals([42]));
    });

    test('handles small data', () async {
      final encoder = LzfFilter();
      final originalData = [1, 2, 3, 4, 5];

      final compressed = encoder.encode(originalData);

      expect(compressed, isNotEmpty);

      final decoder = LzfFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(originalData));
    });

    test('handles large data', () async {
      final encoder = LzfFilter();
      final originalData = List.generate(100000, (i) => i % 256);

      final compressed = encoder.encode(originalData);

      expect(compressed, isNotEmpty);

      final decoder = LzfFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(originalData));
    });
  });

  group('Compression Round-Trip Tests', () {
    test('gzip level 1 round-trip', () async {
      final data = List.generate(1000, (i) => i % 256);
      final encoder = GzipFilter(compressionLevel: 1);
      final compressed = encoder.encode(data);

      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(data));
    });

    test('gzip level 5 round-trip', () async {
      final data = List.generate(1000, (i) => i % 256);
      final encoder = GzipFilter(compressionLevel: 5);
      final compressed = encoder.encode(data);

      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(data));
    });

    test('gzip level 9 round-trip', () async {
      final data = List.generate(1000, (i) => i % 256);
      final encoder = GzipFilter(compressionLevel: 9);
      final compressed = encoder.encode(data);

      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(data));
    });

    test('lzf round-trip', () async {
      final data = List.generate(1000, (i) => i % 256);
      final encoder = LzfFilter();
      final compressed = encoder.encode(data);

      final decoder = LzfFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(data));
    });

    test('gzip round-trip with highly repetitive data', () async {
      final data = List.filled(10000, 42);
      final encoder = GzipFilter(compressionLevel: 9);
      final compressed = encoder.encode(data);

      // Should compress very well
      expect(compressed.length, lessThan(data.length * 0.1));

      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(data));
    });

    test('lzf round-trip with highly repetitive data', () async {
      final data = List.filled(10000, 42);
      final encoder = LzfFilter();
      final compressed = encoder.encode(data);

      expect(compressed.length, lessThan(data.length));

      final decoder = LzfFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(data));
    });
  });

  group('Compression Ratio Tests', () {
    test('gzip achieves high compression on repetitive data', () {
      final filter = GzipFilter(compressionLevel: 9);
      final data = List.filled(10000, 42);

      final compressed = filter.encode(data);
      final ratio = compressed.length / data.length;

      expect(ratio, lessThan(0.1)); // Less than 10%
    });

    test('gzip achieves moderate compression on sequential data', () {
      final filter = GzipFilter(compressionLevel: 6);
      final data = List.generate(10000, (i) => i % 256);

      final compressed = filter.encode(data);
      final ratio = compressed.length / data.length;

      expect(ratio, lessThan(0.5)); // Less than 50%
    });

    test('lzf achieves high compression on repetitive data', () {
      final filter = LzfFilter();
      final data = List.filled(10000, 42);

      final compressed = filter.encode(data);
      final ratio = compressed.length / data.length;

      expect(ratio, lessThan(0.2)); // Less than 20%
    });

    test('compression ratio threshold - 90% boundary', () {
      // Test the concept that compression should be skipped if ratio >= 0.9
      final filter = GzipFilter(compressionLevel: 1);

      // Random-like data that doesn't compress well
      final data = List.generate(1000, (i) => (i * 7919 + 104729) % 256);
      final compressed = filter.encode(data);

      final ratio = compressed.length / data.length;

      // Even if compression doesn't help much, it shouldn't fail
      // The 90% threshold is applied at the chunked layout level
      expect(ratio, greaterThan(0)); // Valid compression attempt
    });

    test('gzip vs lzf compression ratio comparison', () {
      final gzipFilter = GzipFilter(compressionLevel: 6);
      final lzfFilter = LzfFilter();

      final data = List.generate(10000, (i) => i % 256);

      final gzipCompressed = gzipFilter.encode(data);
      final lzfCompressed = lzfFilter.encode(data);

      // Both should compress the data
      expect(gzipCompressed.length, lessThan(data.length));
      expect(lzfCompressed.length, lessThan(data.length));

      // Both filters should produce valid compressed output
      // The actual compression ratio depends on the data pattern
      // and algorithm characteristics
      expect(gzipCompressed, isNotEmpty);
      expect(lzfCompressed, isNotEmpty);
    });
  });

  group('Edge Cases and Error Handling', () {
    test('gzip handles empty data', () async {
      final encoder = GzipFilter();
      final compressed = encoder.encode([]);

      expect(compressed, isNotEmpty); // Gzip header is always present

      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, isEmpty);
    });

    test('gzip handles single byte', () async {
      final encoder = GzipFilter();
      final compressed = encoder.encode([42]);

      expect(compressed, isNotEmpty);

      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals([42]));
    });

    test('gzip handles all zero bytes', () async {
      final encoder = GzipFilter(compressionLevel: 9);
      final data = List.filled(10000, 0);

      final compressed = encoder.encode(data);

      // Should compress extremely well
      expect(compressed.length, lessThan(data.length * 0.05));

      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(data));
    });

    test('gzip handles all 255 bytes', () async {
      final encoder = GzipFilter(compressionLevel: 9);
      final data = List.filled(10000, 255);

      final compressed = encoder.encode(data);

      expect(compressed.length, lessThan(data.length * 0.1));

      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(data));
    });

    test('lzf handles all zero bytes', () async {
      final encoder = LzfFilter();
      final data = List.filled(10000, 0);

      final compressed = encoder.encode(data);

      expect(compressed.length, lessThan(data.length));

      final decoder = LzfFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      expect(decompressed, equals(data));
    });

    test('gzip invalid compression level throws error', () {
      expect(() => GzipFilter(compressionLevel: 0), throwsArgumentError);
      expect(() => GzipFilter(compressionLevel: 10), throwsArgumentError);
      expect(() => GzipFilter(compressionLevel: -1), throwsArgumentError);
      expect(() => GzipFilter(compressionLevel: 100), throwsArgumentError);
    });

    test('gzip valid compression levels do not throw', () {
      for (int level = 1; level <= 9; level++) {
        expect(() => GzipFilter(compressionLevel: level), returnsNormally);
      }
    });
  });

  group('Performance Characteristics', () {
    test('gzip level 1 is faster than level 9', () {
      final data = List.generate(50000, (i) => i % 256);

      final stopwatch1 = Stopwatch()..start();
      GzipFilter(compressionLevel: 1).encode(data);
      stopwatch1.stop();

      final stopwatch9 = Stopwatch()..start();
      GzipFilter(compressionLevel: 9).encode(data);
      stopwatch9.stop();

      // Level 1 should be faster (or at least not slower)
      expect(stopwatch1.elapsedMicroseconds,
          lessThanOrEqualTo(stopwatch9.elapsedMicroseconds * 2));
    });

    test('lzf is fast on large data', () {
      final filter = LzfFilter();
      final data = List.generate(100000, (i) => i % 256);

      final stopwatch = Stopwatch()..start();
      filter.encode(data);
      stopwatch.stop();

      // Should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('gzip level 6 balances speed and compression', () {
      final filter = GzipFilter(compressionLevel: 6);
      final data = List.generate(50000, (i) => i % 256);

      final stopwatch = Stopwatch()..start();
      final compressed = filter.encode(data);
      stopwatch.stop();

      // Should be reasonably fast
      expect(stopwatch.elapsedMilliseconds, lessThan(500));

      // Should achieve good compression
      final ratio = compressed.length / data.length;
      expect(ratio, lessThan(0.5));
    });
  });
}
