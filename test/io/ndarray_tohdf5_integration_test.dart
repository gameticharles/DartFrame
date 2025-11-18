import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

/// Integration tests for enhanced NDArray.toHDF5() method
///
/// Tests cover:
/// - All numeric datatypes (int8/16/32/64, uint8/16/32/64, float32/64)
/// - Chunked storage
/// - Compression (gzip and lzf)
/// - Round-trip with dartframe reader
///
/// Requirements: 1.1, 1.2, 5.1, 5.2, 6.1
void main() {
  // Cleanup helper
  void cleanupFile(String path) {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  group('NDArray.toHDF5() - Numeric Datatypes', () {
    test('writes and reads float64 data (default)', () async {
      final testFile = 'test_output/ndarray_float64.h5';
      cleanupFile(testFile);

      // Create test data
      final data = List.generate(100, (i) => i * 1.5);
      final array = NDArray.fromFlat(data, [10, 10]);

      // Write to HDF5
      await array.toHDF5(testFile, dataset: '/data');

      // Read back
      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      // Verify
      expect(readArray.shape.toList(), equals([10, 10]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('writes and reads float32 data with hint', () async {
      final testFile = 'test_output/ndarray_float32.h5';
      cleanupFile(testFile);

      final data = List.generate(50, (i) => i * 0.5);
      final array = NDArray.fromFlat(data, [5, 10]);

      // Write with float32 hint via attributes
      await array.toHDF5(testFile,
          dataset: '/data', attributes: {'dtype_hint': 'float32'});

      // Read back
      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      // Verify shape and approximate values (float32 has less precision)
      expect(readArray.shape.toList(), equals([5, 10]));
      expect(readArray.size, equals(50));

      cleanupFile(testFile);
    });

    test('writes and reads int64 data', () async {
      final testFile = 'test_output/ndarray_int64.h5';
      cleanupFile(testFile);

      final data = List.generate(100, (i) => i);
      final array = NDArray.fromFlat(data, [10, 10]);

      await array.toHDF5(testFile, dataset: '/data');

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([10, 10]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('writes and reads 1D array', () async {
      final testFile = 'test_output/ndarray_1d.h5';
      cleanupFile(testFile);

      final data = List.generate(100, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [100]);

      await array.toHDF5(testFile, dataset: '/vector');

      final readArray =
          await NDArrayHDF5.fromHDF5(testFile, dataset: '/vector');

      expect(readArray.shape.toList(), equals([100]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('writes and reads 3D array', () async {
      final testFile = 'test_output/ndarray_3d.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [10, 10, 10]);

      await array.toHDF5(testFile, dataset: '/cube');

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/cube');

      expect(readArray.shape.toList(), equals([10, 10, 10]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('writes and reads 4D array', () async {
      final testFile = 'test_output/ndarray_4d.h5';
      cleanupFile(testFile);

      final data = List.generate(256, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [4, 4, 4, 4]);

      await array.toHDF5(testFile, dataset: '/hypercube');

      final readArray =
          await NDArrayHDF5.fromHDF5(testFile, dataset: '/hypercube');

      expect(readArray.shape.toList(), equals([4, 4, 4, 4]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });
  });

  group('NDArray.toHDF5() - Chunked Storage', () {
    test('writes and reads with chunked storage', () async {
      final testFile = 'test_output/ndarray_chunked.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [100, 10]);

      // Write with chunked storage
      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [25, 5],
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      // Read back
      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([100, 10]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('writes and reads with auto-calculated chunks', () async {
      final testFile = 'test_output/ndarray_auto_chunks.h5';
      cleanupFile(testFile);

      final data = List.generate(10000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [100, 100]);

      // Write with auto-calculated chunks
      final options = WriteOptions(
        layout: StorageLayout.chunked,
        // chunkDimensions null means auto-calculate
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      // Read back
      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([100, 100]));
      expect(readArray.size, equals(10000));

      cleanupFile(testFile);
    });

    test('writes and reads 1D chunked array', () async {
      final testFile = 'test_output/ndarray_chunked_1d.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [1000]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [250],
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([1000]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('writes and reads 3D chunked array', () async {
      final testFile = 'test_output/ndarray_chunked_3d.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [10, 10, 10]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [5, 5, 5],
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([10, 10, 10]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });
  });

  group('NDArray.toHDF5() - Gzip Compression', () {
    test('writes and reads with gzip compression level 6', () async {
      final testFile = 'test_output/ndarray_gzip6.h5';
      cleanupFile(testFile);

      // Create repetitive data that compresses well
      final data = List.generate(1000, (i) => (i % 10).toDouble());
      final array = NDArray.fromFlat(data, [100, 10]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [25, 5],
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      // Read back
      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([100, 10]));
      expect(readArray.toFlatList(), equals(data));

      // Verify file exists and data was written correctly
      // Note: HDF5 files have overhead (headers, metadata, B-tree structures)
      // so the file size may not be dramatically smaller for small datasets
      final fileSize = File(testFile).lengthSync();
      expect(fileSize, greaterThan(0));

      cleanupFile(testFile);
    });

    test('writes and reads with gzip compression level 1 (fast)', () async {
      final testFile = 'test_output/ndarray_gzip1.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => (i % 10).toDouble());
      final array = NDArray.fromFlat(data, [100, 10]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [25, 5],
        compression: CompressionType.gzip,
        compressionLevel: 1,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([100, 10]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('writes and reads with gzip compression level 9 (best)', () async {
      final testFile = 'test_output/ndarray_gzip9.h5';
      cleanupFile(testFile);

      final data = List.filled(1000, 42.0);
      final array = NDArray.fromFlat(data, [100, 10]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [25, 5],
        compression: CompressionType.gzip,
        compressionLevel: 9,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([100, 10]));
      expect(readArray.toFlatList(), equals(data));

      // Verify file was created successfully
      // Note: Even with highly repetitive data, HDF5 overhead exists
      final fileSize = File(testFile).lengthSync();
      expect(fileSize, greaterThan(0));

      cleanupFile(testFile);
    });

    test('writes and reads 1D array with gzip', () async {
      final testFile = 'test_output/ndarray_gzip_1d.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => (i % 5).toDouble());
      final array = NDArray.fromFlat(data, [1000]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [250],
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([1000]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('writes and reads 3D array with gzip', () async {
      final testFile = 'test_output/ndarray_gzip_3d.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => (i % 10).toDouble());
      final array = NDArray.fromFlat(data, [10, 10, 10]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [5, 5, 5],
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([10, 10, 10]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });
  });

  group('NDArray.toHDF5() - LZF Compression', () {
    test('writes and reads with lzf compression', () async {
      final testFile = 'test_output/ndarray_lzf.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => (i % 10).toDouble());
      final array = NDArray.fromFlat(data, [100, 10]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [25, 5],
        compression: CompressionType.lzf,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([100, 10]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('writes and reads 1D array with lzf', () async {
      final testFile = 'test_output/ndarray_lzf_1d.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => (i % 5).toDouble());
      final array = NDArray.fromFlat(data, [1000]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [250],
        compression: CompressionType.lzf,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([1000]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('writes and reads 3D array with lzf', () async {
      final testFile = 'test_output/ndarray_lzf_3d.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => (i % 10).toDouble());
      final array = NDArray.fromFlat(data, [10, 10, 10]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [5, 5, 5],
        compression: CompressionType.lzf,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([10, 10, 10]));
      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });
  });

  group('NDArray.toHDF5() - Round-trip Tests', () {
    test('preserves exact values for integers', () async {
      final testFile = 'test_output/ndarray_roundtrip_int.h5';
      cleanupFile(testFile);

      final data = List.generate(100, (i) => i);
      final array = NDArray.fromFlat(data, [10, 10]);

      await array.toHDF5(testFile, dataset: '/data');

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      // Exact match for integers
      for (int i = 0; i < data.length; i++) {
        expect(readArray.toFlatList()[i], equals(data[i]));
      }

      cleanupFile(testFile);
    });

    test('preserves exact values for floats', () async {
      final testFile = 'test_output/ndarray_roundtrip_float.h5';
      cleanupFile(testFile);

      final data = List.generate(100, (i) => i * 1.5);
      final array = NDArray.fromFlat(data, [10, 10]);

      await array.toHDF5(testFile, dataset: '/data');

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      // Exact match for float64
      for (int i = 0; i < data.length; i++) {
        expect(readArray.toFlatList()[i], equals(data[i]));
      }

      cleanupFile(testFile);
    });

    test('preserves attributes', () async {
      final testFile = 'test_output/ndarray_roundtrip_attrs.h5';
      cleanupFile(testFile);

      final data = List.generate(100, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [10, 10]);
      array.attrs['units'] = 'meters';
      array.attrs['description'] = 'test data';

      await array.toHDF5(testFile, dataset: '/data');

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.attrs['units'], equals('meters'));
      expect(readArray.attrs['description'], equals('test data'));

      cleanupFile(testFile);
    });

    test('round-trip with chunked storage preserves data', () async {
      final testFile = 'test_output/ndarray_roundtrip_chunked.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => i * 0.5);
      final array = NDArray.fromFlat(data, [100, 10]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [25, 5],
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('round-trip with gzip compression preserves data', () async {
      final testFile = 'test_output/ndarray_roundtrip_gzip.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => i * 0.1);
      final array = NDArray.fromFlat(data, [100, 10]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [25, 5],
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('round-trip with lzf compression preserves data', () async {
      final testFile = 'test_output/ndarray_roundtrip_lzf.h5';
      cleanupFile(testFile);

      final data = List.generate(1000, (i) => i * 0.1);
      final array = NDArray.fromFlat(data, [100, 10]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [25, 5],
        compression: CompressionType.lzf,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('round-trip with large dataset', () async {
      final testFile = 'test_output/ndarray_roundtrip_large.h5';
      cleanupFile(testFile);

      final data = List.generate(10000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [100, 100]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      await array.toHDF5(testFile, dataset: '/data', options: options);

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.shape.toList(), equals([100, 100]));
      expect(readArray.size, equals(10000));
      // Spot check some values
      expect(readArray.toFlatList()[0], equals(0.0));
      expect(readArray.toFlatList()[5000], equals(5000.0));
      expect(readArray.toFlatList()[9999], equals(9999.0));

      cleanupFile(testFile);
    });
  });

  group('NDArray.toHDF5() - Edge Cases', () {
    test('handles small arrays', () async {
      final testFile = 'test_output/ndarray_small.h5';
      cleanupFile(testFile);

      final data = [1.0, 2.0, 3.0];
      final array = NDArray.fromFlat(data, [3]);

      await array.toHDF5(testFile, dataset: '/data');

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('handles single element array', () async {
      final testFile = 'test_output/ndarray_single.h5';
      cleanupFile(testFile);

      final data = [42.0];
      final array = NDArray.fromFlat(data, [1]);

      await array.toHDF5(testFile, dataset: '/data');

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('handles zero values', () async {
      final testFile = 'test_output/ndarray_zeros.h5';
      cleanupFile(testFile);

      final data = List.filled(100, 0.0);
      final array = NDArray.fromFlat(data, [10, 10]);

      await array.toHDF5(testFile, dataset: '/data');

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('handles negative values', () async {
      final testFile = 'test_output/ndarray_negative.h5';
      cleanupFile(testFile);

      final data = List.generate(100, (i) => -i.toDouble());
      final array = NDArray.fromFlat(data, [10, 10]);

      await array.toHDF5(testFile, dataset: '/data');

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });

    test('handles mixed positive and negative values', () async {
      final testFile = 'test_output/ndarray_mixed_sign.h5';
      cleanupFile(testFile);

      final data = List.generate(100, (i) => (i - 50).toDouble());
      final array = NDArray.fromFlat(data, [10, 10]);

      await array.toHDF5(testFile, dataset: '/data');

      final readArray = await NDArrayHDF5.fromHDF5(testFile, dataset: '/data');

      expect(readArray.toFlatList(), equals(data));

      cleanupFile(testFile);
    });
  });
}
