import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('HDF5 NDArray Writer', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('hdf5_ndarray_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('writes 2D NDArray with contiguous storage', () async {
      final array = NDArray.generate([10, 20], (indices) {
        return indices[0] * 20 + indices[1];
      });

      final filePath = '${tempDir.path}/test_contiguous.h5';

      await array.toHDF5(
        filePath,
        dataset: '/data',
        attributes: {'description': 'Test array', 'units': 'meters'},
      );

      expect(File(filePath).existsSync(), isTrue);
      expect(File(filePath).lengthSync(), greaterThan(0));
    });

    test('writes 3D NDArray with chunked storage', () async {
      final array = NDArray.generate([5, 10, 15], (indices) {
        return indices[0] * 150.0 + indices[1] * 15.0 + indices[2];
      });

      final filePath = '${tempDir.path}/test_chunked.h5';

      await array.toHDF5(
        filePath,
        dataset: '/measurements',
        options: WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [2, 5, 5],
        ),
      );

      expect(File(filePath).existsSync(), isTrue);
      expect(File(filePath).lengthSync(), greaterThan(0));
    });

    test('writes NDArray with GZIP compression', () async {
      final array = NDArray.generate([20, 30], (indices) {
        return (indices[0] + indices[1]).toDouble();
      });

      final filePath = '${tempDir.path}/test_compressed.h5';

      await array.toHDF5(
        filePath,
        dataset: '/compressed_data',
        options: WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [10, 10],
          compression: CompressionType.gzip,
          compressionLevel: 6,
        ),
      );

      expect(File(filePath).existsSync(), isTrue);
      expect(File(filePath).lengthSync(), greaterThan(0));
    });

    test('writes NDArray with auto-calculated chunk dimensions', () async {
      final array = NDArray.generate([100, 200], (indices) {
        return indices[0] * 200 + indices[1];
      });

      final filePath = '${tempDir.path}/test_auto_chunks.h5';

      await array.toHDF5(
        filePath,
        dataset: '/auto_chunked',
        options: WriteOptions(
          layout: StorageLayout.chunked,
          compression: CompressionType.gzip,
        ),
      );

      expect(File(filePath).existsSync(), isTrue);
      expect(File(filePath).lengthSync(), greaterThan(0));
    });

    test('writes NDArray with LZF compression', () async {
      final array = NDArray.generate([15, 25], (indices) {
        return (indices[0] * 25 + indices[1]).toDouble();
      });

      final filePath = '${tempDir.path}/test_lzf.h5';

      await array.toHDF5(
        filePath,
        dataset: '/lzf_data',
        options: WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: [5, 10],
          compression: CompressionType.lzf,
        ),
      );

      expect(File(filePath).existsSync(), isTrue);
      expect(File(filePath).lengthSync(), greaterThan(0));
    });

    test('preserves NDArray attributes in HDF5', () async {
      final array = NDArray.zeros([5, 5]);
      array.attrs['units'] = 'meters';
      array.attrs['description'] = 'Test data';
      array.attrs['version'] = 1;

      final filePath = '${tempDir.path}/test_attrs.h5';

      await array.toHDF5(
        filePath,
        dataset: '/data_with_attrs',
      );

      expect(File(filePath).existsSync(), isTrue);
    });

    test('writes large NDArray with memory-efficient chunking', () async {
      // Create a larger array to test chunked processing
      final array = NDArray.generate([50, 100, 80], (indices) {
        return (indices[0] + indices[1] + indices[2]).toDouble();
      });

      final filePath = '${tempDir.path}/test_large.h5';

      await array.toHDF5(
        filePath,
        dataset: '/large_data',
        options: WriteOptions(
          layout: StorageLayout.chunked,
          compression: CompressionType.gzip,
          compressionLevel: 4,
        ),
      );

      expect(File(filePath).existsSync(), isTrue);
      expect(File(filePath).lengthSync(), greaterThan(0));
    });

    test('writes NDArray with int64 datatype', () async {
      final array = NDArray.generate([10, 10], (indices) {
        return indices[0] * 10 + indices[1];
      });

      final filePath = '${tempDir.path}/test_int64.h5';

      await array.toHDF5(
        filePath,
        dataset: '/int_data',
      );

      expect(File(filePath).existsSync(), isTrue);
    });

    test('writes NDArray with float64 datatype', () async {
      final array = NDArray.generate([10, 10], (indices) {
        return (indices[0] * 10 + indices[1]).toDouble();
      });

      final filePath = '${tempDir.path}/test_float64.h5';

      await array.toHDF5(
        filePath,
        dataset: '/float_data',
      );

      expect(File(filePath).existsSync(), isTrue);
    });

    test('writes multiple NDArrays to single HDF5 file', () async {
      final array1 = NDArray.ones([5, 5]);
      final array2 = NDArray.zeros([10, 10]);
      final array3 = NDArray.generate([3, 4], (i) => i[0] * 4 + i[1]);

      final filePath = '${tempDir.path}/test_multiple.h5';

      await HDF5WriterUtils.writeMultiple(
        filePath,
        {
          '/data1': array1,
          '/data2': array2,
          '/data3': array3,
        },
      );

      expect(File(filePath).existsSync(), isTrue);
    });
  });
}
