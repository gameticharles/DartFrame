import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/write_options.dart';

void main() {
  group('WriteOptions', () {
    group('default values', () {
      test('should have correct default values', () {
        const options = WriteOptions();

        expect(options.layout, equals(StorageLayout.contiguous));
        expect(options.chunkDimensions, isNull);
        expect(options.compression, equals(CompressionType.none));
        expect(options.compressionLevel, equals(6));
        expect(options.formatVersion, equals(0));
        expect(options.createIntermediateGroups, isTrue);
        expect(options.dfStrategy, equals(DataFrameStorageStrategy.compound));
        expect(options.attributes, isNull);
      });
    });

    group('validation', () {
      test('should pass validation with default options', () {
        const options = WriteOptions();
        expect(() => options.validate(), returnsNormally);
      });

      test('should reject compression without chunked storage', () {
        const options = WriteOptions(
          compression: CompressionType.gzip,
          layout: StorageLayout.contiguous,
        );

        expect(
          () => options.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Compression requires chunked storage layout'),
            ),
          ),
        );
      });

      test('should accept compression with chunked storage', () {
        const options = WriteOptions(
          compression: CompressionType.gzip,
          layout: StorageLayout.chunked,
        );

        expect(() => options.validate(), returnsNormally);
      });

      test('should reject gzip compression level below 1', () {
        const options = WriteOptions(
          compression: CompressionType.gzip,
          layout: StorageLayout.chunked,
          compressionLevel: 0,
        );

        expect(
          () => options.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Compression level must be between 1 and 9'),
            ),
          ),
        );
      });

      test('should reject gzip compression level above 9', () {
        const options = WriteOptions(
          compression: CompressionType.gzip,
          layout: StorageLayout.chunked,
          compressionLevel: 10,
        );

        expect(
          () => options.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Compression level must be between 1 and 9'),
            ),
          ),
        );
      });

      test('should accept valid gzip compression levels 1-9', () {
        for (int level = 1; level <= 9; level++) {
          final options = WriteOptions(
            compression: CompressionType.gzip,
            layout: StorageLayout.chunked,
            compressionLevel: level,
          );

          expect(() => options.validate(), returnsNormally);
        }
      });

      test('should reject empty chunk dimensions', () {
        const options = WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [],
        );

        expect(
          () => options.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Chunk dimensions cannot be empty'),
            ),
          ),
        );
      });

      test('should reject negative chunk dimensions', () {
        const options = WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [10, -5],
        );

        expect(
          () => options.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('All chunk dimensions must be positive'),
            ),
          ),
        );
      });

      test('should reject zero chunk dimensions', () {
        const options = WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [10, 0],
        );

        expect(
          () => options.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('All chunk dimensions must be positive'),
            ),
          ),
        );
      });

      test('should reject chunk dimensions exceeding dataset dimensions', () {
        const options = WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [100, 200],
        );

        expect(
          () => options.validate(datasetDimensions: [50, 100]),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('Chunk dimension at index 0'),
                contains('exceeds dataset dimension'),
              ),
            ),
          ),
        );
      });

      test('should reject mismatched chunk and dataset dimension ranks', () {
        const options = WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [10, 20],
        );

        expect(
          () => options.validate(datasetDimensions: [100, 200, 300]),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains(
                  'Chunk dimensions rank (2) must match dataset dimensions rank (3)'),
            ),
          ),
        );
      });

      test('should accept valid chunk dimensions', () {
        const options = WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [50, 100],
        );

        expect(
          () => options.validate(datasetDimensions: [100, 200]),
          returnsNormally,
        );
      });

      test('should reject invalid format version below 0', () {
        const options = WriteOptions(formatVersion: -1);

        expect(
          () => options.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Format version must be 0, 1, or 2'),
            ),
          ),
        );
      });

      test('should reject invalid format version above 2', () {
        const options = WriteOptions(formatVersion: 3);

        expect(
          () => options.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Format version must be 0, 1, or 2'),
            ),
          ),
        );
      });

      test('should accept valid format versions 0, 1, 2', () {
        for (int version = 0; version <= 2; version++) {
          final options = WriteOptions(formatVersion: version);
          expect(() => options.validate(), returnsNormally);
        }
      });
    });

    group('error messages', () {
      test('compression error message should be descriptive', () {
        const options = WriteOptions(
          compression: CompressionType.gzip,
          layout: StorageLayout.contiguous,
        );

        try {
          options.validate();
          fail('Should have thrown ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          final error = e as ArgumentError;
          expect(error.message,
              contains('Compression requires chunked storage layout'));
          expect(
              error.message, contains('Set layout to StorageLayout.chunked'));
        }
      });

      test('compression level error message should include actual value', () {
        const options = WriteOptions(
          compression: CompressionType.gzip,
          layout: StorageLayout.chunked,
          compressionLevel: 15,
        );

        try {
          options.validate();
          fail('Should have thrown ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          final error = e as ArgumentError;
          expect(error.message,
              contains('Compression level must be between 1 and 9'));
          expect(error.message, contains('Got: 15'));
        }
      });

      test('chunk dimension error message should include dimensions', () {
        const options = WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [10, -5, 20],
        );

        try {
          options.validate();
          fail('Should have thrown ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          final error = e as ArgumentError;
          expect(
              error.message, contains('All chunk dimensions must be positive'));
          expect(error.message, contains('[10, -5, 20]'));
        }
      });

      test('chunk exceeds dataset error message should be detailed', () {
        const options = WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [150, 50],
        );

        try {
          options.validate(datasetDimensions: [100, 200]);
          fail('Should have thrown ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          final error = e as ArgumentError;
          expect(error.message, contains('Chunk dimension at index 0 (150)'));
          expect(error.message, contains('exceeds dataset dimension (100)'));
          expect(error.message, contains('Chunk dimensions: [150, 50]'));
          expect(error.message, contains('Dataset dimensions: [100, 200]'));
        }
      });

      test('rank mismatch error message should include both ranks', () {
        const options = WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [10, 20],
        );

        try {
          options.validate(datasetDimensions: [100]);
          fail('Should have thrown ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          final error = e as ArgumentError;
          expect(error.message, contains('Chunk dimensions rank (2)'));
          expect(error.message, contains('dataset dimensions rank (1)'));
          expect(error.message, contains('Chunk dimensions: [10, 20]'));
          expect(error.message, contains('Dataset dimensions: [100]'));
        }
      });

      test('format version error message should include actual value', () {
        const options = WriteOptions(formatVersion: 5);

        try {
          options.validate();
          fail('Should have thrown ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          final error = e as ArgumentError;
          expect(error.message, contains('Format version must be 0, 1, or 2'));
          expect(error.message, contains('Got: 5'));
        }
      });
    });

    group('copyWith', () {
      test('should create copy with modified values', () {
        const original = WriteOptions(
          layout: StorageLayout.contiguous,
          compression: CompressionType.none,
        );

        final modified = original.copyWith(
          layout: StorageLayout.chunked,
          compression: CompressionType.gzip,
        );

        expect(modified.layout, equals(StorageLayout.chunked));
        expect(modified.compression, equals(CompressionType.gzip));
        expect(modified.compressionLevel, equals(original.compressionLevel));
      });

      test('should preserve unmodified values', () {
        const original = WriteOptions(
          layout: StorageLayout.chunked,
          compressionLevel: 9,
          formatVersion: 2,
        );

        final modified = original.copyWith(compression: CompressionType.lzf);

        expect(modified.layout, equals(original.layout));
        expect(modified.compressionLevel, equals(original.compressionLevel));
        expect(modified.formatVersion, equals(original.formatVersion));
        expect(modified.compression, equals(CompressionType.lzf));
      });
    });

    group('toString', () {
      test('should provide readable string representation', () {
        const options = WriteOptions(
          layout: StorageLayout.chunked,
          compression: CompressionType.gzip,
          formatVersion: 1,
        );

        final str = options.toString();
        expect(str, contains('WriteOptions'));
        expect(str, contains('layout: StorageLayout.chunked'));
        expect(str, contains('compression: CompressionType.gzip'));
        expect(str, contains('formatVersion: 1'));
      });
    });
  });
}
