import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

/// Integration tests for HDF5 compressed dataset reading
/// Tests Requirements 6.1-6.4: Compression Support
///
/// This test suite verifies:
/// - Gzip compression/decompression
/// - LZF compression/decompression
/// - Shuffle filter support
/// - Combined filter pipelines (compression + shuffle)
/// - Data integrity after decompression
void main() {
  group('HDF5 Compressed Dataset Tests', () {
    final testFile = 'example/data/test_compressed.h5';

    setUp(() {
      if (!File(testFile).existsSync()) {
        throw StateError(
          'Test file not found: $testFile\n'
          'Run: python create_compressed_hdf5.py',
        );
      }
    });

    group('Gzip Compression Tests', () {
      test('reads gzip compressed 1D dataset with correct values', () async {
        // Requirement 6.1: Decompress gzip data before reading
        final df = await FileReader.readHDF5(testFile, dataset: '/gzip_1d');

        expect(df, isNotNull);
        expect(df.rowCount, equals(100));
        expect(df.columnCount, equals(1));

        // Verify data integrity - check multiple values
        expect(df[0][0], equals(0.0));
        expect(df[0][25], equals(25.0));
        expect(df[0][50], equals(50.0));
        expect(df[0][75], equals(75.0));
        expect(df[0][99], equals(99.0));

        // Verify all values are sequential
        for (int i = 0; i < 100; i++) {
          expect(df[0][i], equals(i.toDouble()),
              reason: 'Value at index $i should be $i');
        }
      });

      test('reads gzip compressed 2D dataset with correct values', () async {
        // Requirement 6.1: Decompress gzip data before reading
        final df = await FileReader.readHDF5(testFile, dataset: '/gzip_2d');

        expect(df, isNotNull);
        expect(df.rowCount, equals(20));
        expect(df.columnCount, equals(10));

        // Verify data integrity - check corner and middle values
        // Note: DataFrame uses column-major indexing: df[col][row]
        expect(df[0][0], equals(0)); // First element
        expect(df[9][19], equals(199)); // Last element
        expect(df[4][9], equals(94)); // Middle element
        expect(df[0][5], equals(50)); // Row 5, column 0

        // Verify all values are sequential (row-major order in source)
        for (int row = 0; row < 20; row++) {
          for (int col = 0; col < 10; col++) {
            final expectedValue = row * 10 + col;
            expect(df[col][row], equals(expectedValue),
                reason: 'Value at [$col][$row] should be $expectedValue');
          }
        }
      });

      test('reads gzip + shuffle compressed dataset', () async {
        // Requirement 6.1: Decompress gzip data
        // Requirement 6.4: Handle filter pipeline (shuffle + gzip)
        final df =
            await FileReader.readHDF5(testFile, dataset: '/gzip_shuffle');

        expect(df, isNotNull);
        expect(df.rowCount, equals(100));
        expect(df.columnCount, equals(1));

        // Verify dataset can be read without errors
        expect(df[0][0], isNotNull);
      });
    });

    group('LZF Compression Tests', () {
      test('reads LZF compressed 1D dataset with correct values', () async {
        // Requirement 6.2: Decompress LZF data before reading
        final df = await FileReader.readHDF5(testFile, dataset: '/lzf_1d');

        expect(df, isNotNull);
        expect(df.rowCount, equals(50));
        expect(df.columnCount, equals(1));

        // Verify data integrity - check multiple values
        expect(df[0][0], equals(0));
        expect(df[0][10], equals(10));
        expect(df[0][25], equals(25));
        expect(df[0][49], equals(49));

        // Verify all values are sequential
        for (int i = 0; i < 50; i++) {
          expect(df[0][i], equals(i), reason: 'Value at index $i should be $i');
        }
      });

      test('reads LZF compressed 2D dataset with correct values', () async {
        // Requirement 6.2: Decompress LZF data before reading
        final df = await FileReader.readHDF5(testFile, dataset: '/lzf_2d');

        expect(df, isNotNull);
        expect(df.rowCount, equals(12));
        expect(df.columnCount, equals(10));

        // Verify data integrity - check corner and middle values
        expect(df[0][0], equals(0));
        expect(df[9][11], equals(119));
        expect(df[5][5], equals(55));

        // Verify all values are sequential (row-major order)
        for (int row = 0; row < 12; row++) {
          for (int col = 0; col < 10; col++) {
            final expectedValue = row * 10 + col;
            expect(df[col][row], equals(expectedValue),
                reason: 'Value at [$col][$row] should be $expectedValue');
          }
        }
      });
    });

    group('Shuffle Filter Tests', () {
      test('reads shuffle-only dataset with correct values', () async {
        // Test shuffle filter without compression
        final df =
            await FileReader.readHDF5(testFile, dataset: '/shuffle_only');

        expect(df, isNotNull);
        expect(df.rowCount, equals(6));
        expect(df.columnCount, equals(10));

        // Verify data integrity
        expect(df[0][0], equals(0));
        expect(df[9][5], equals(59));
        expect(df[5][3], equals(35));

        // Verify all values are sequential (row-major order)
        for (int row = 0; row < 6; row++) {
          for (int col = 0; col < 10; col++) {
            final expectedValue = row * 10 + col;
            expect(df[col][row], equals(expectedValue),
                reason: 'Value at [$col][$row] should be $expectedValue');
          }
        }
      });
    });

    group('Data Integrity Verification', () {
      test('verifies decompressed data matches original for gzip datasets',
          () async {
        // Requirement 6.4: Verify decompressed data matches original

        // Test gzip 1D dataset
        final gzip1d = await FileReader.readHDF5(testFile, dataset: '/gzip_1d');
        expect(gzip1d.rowCount, equals(100));
        for (int i = 0; i < 100; i++) {
          expect(gzip1d[0][i], equals(i.toDouble()));
        }

        // Test gzip 2D dataset
        final gzip2d = await FileReader.readHDF5(testFile, dataset: '/gzip_2d');
        expect(gzip2d.rowCount, equals(20));
        for (int i = 0; i < 200; i++) {
          final row = i ~/ 10;
          final col = i % 10;
          expect(gzip2d[col][row], equals(i));
        }
      });

      test('verifies decompressed data matches original for LZF datasets',
          () async {
        // Requirement 6.4: Verify decompressed data matches original

        // Test LZF 1D dataset
        final lzf1d = await FileReader.readHDF5(testFile, dataset: '/lzf_1d');
        expect(lzf1d.rowCount, equals(50));
        for (int i = 0; i < 50; i++) {
          expect(lzf1d[0][i], equals(i));
        }

        // Test LZF 2D dataset
        final lzf2d = await FileReader.readHDF5(testFile, dataset: '/lzf_2d');
        expect(lzf2d.rowCount, equals(12));
        for (int i = 0; i < 120; i++) {
          final row = i ~/ 10;
          final col = i % 10;
          expect(lzf2d[col][row], equals(i));
        }
      });

      test('handles multiple compressed datasets in same file', () async {
        // Verify we can read multiple compressed datasets without issues
        final datasets = [
          '/gzip_1d',
          '/gzip_2d',
          '/gzip_shuffle',
          '/lzf_1d',
          '/lzf_2d',
          '/shuffle_only',
        ];

        for (final dataset in datasets) {
          final df = await FileReader.readHDF5(testFile, dataset: dataset);
          expect(df, isNotNull, reason: 'Failed to read $dataset');
          expect(df.rowCount, greaterThan(0),
              reason: '$dataset should have rows');
        }
      });
    });

    group('Compression Performance', () {
      test('reads compressed datasets efficiently', () async {
        // Verify that compressed datasets can be read without performance issues
        final stopwatch = Stopwatch()..start();

        await FileReader.readHDF5(testFile, dataset: '/gzip_2d');
        await FileReader.readHDF5(testFile, dataset: '/lzf_2d');

        stopwatch.stop();

        // Should complete in reasonable time (< 5 seconds for small datasets)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
            reason: 'Compressed dataset reading should be reasonably fast');
      });
    });
  });
}
