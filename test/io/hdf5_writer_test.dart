import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';
import 'package:dartframe/src/datacube/datacube.dart';
import 'package:dartframe/src/io/hdf5/hdf5_writer.dart'
    show HDF5WriterUtils, NDArrayHDF5Writer, DataCubeHDF5Writer;

void main() {
  // Cleanup helper
  Future<void> cleanup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  group('NDArray HDF5 Writer', () {
    final testFile = 'test_array.h5';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('write 1D array', () async {
      final array = NDArray([1, 2, 3, 4, 5]);

      await array.toHDF5(testFile, dataset: '/data');

      final file = File(testFile);
      expect(await file.exists(), true);

      // Check HDF5 signature
      final bytes = await file.readAsBytes();
      expect(bytes.sublist(0, 8),
          [0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]);
    });

    test('write 2D array', () async {
      final array = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);

      await array.toHDF5(testFile, dataset: '/measurements');

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('write 3D array', () async {
      final array = NDArray([
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ]
      ]);

      await array.toHDF5(testFile, dataset: '/data3d');

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('write with attributes', () async {
      final array = NDArray([1, 2, 3]);
      array.attrs['units'] = 'meters';
      array.attrs['description'] = 'Distance measurements';

      await array.toHDF5(testFile, dataset: '/distances');

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('write with custom attributes', () async {
      final array = NDArray([1, 2, 3]);

      await array.toHDF5(
        testFile,
        dataset: '/data',
        attributes: {
          'custom': 'value',
          'version': 1,
        },
      );

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('write large array', () async {
      final array = NDArray.zeros([100, 100]);

      await array.toHDF5(testFile, dataset: '/large');

      final file = File(testFile);
      expect(await file.exists(), true);

      // Check file size is reasonable
      final size = await file.length();
      expect(size, greaterThan(1000));
    });
  });

  group('DataCube HDF5 Writer', () {
    final testFile = 'test_cube.h5';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('write DataCube', () async {
      final cube = DataCube.zeros(3, 4, 5);

      await cube.toHDF5(testFile, dataset: '/cube');

      final file = File(testFile);
      expect(await file.exists(), true);

      // Check HDF5 signature
      final bytes = await file.readAsBytes();
      expect(bytes.sublist(0, 8),
          [0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]);
    });

    test('write DataCube with attributes', () async {
      final cube = DataCube.ones(2, 3, 4);
      cube.attrs['units'] = 'celsius';
      cube.attrs['sensor'] = 'TMP36';

      await cube.toHDF5(testFile, dataset: '/temperature');

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('write DataCube with data', () async {
      final cube =
          DataCube.generate(2, 3, 4, (d, r, c) => d * 100 + r * 10 + c);

      await cube.toHDF5(testFile, dataset: '/data');

      final file = File(testFile);
      expect(await file.exists(), true);
    });
  });

  group('HDF5WriterUtils Utility', () {
    final testFile = 'test_utility.h5';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('writeNDArray', () async {
      final array = NDArray([1, 2, 3, 4]);

      await HDF5WriterUtils.writeNDArray(testFile, array, dataset: '/data');

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('writeDataCube', () async {
      final cube = DataCube.zeros(2, 3, 4);

      await HDF5WriterUtils.writeDataCube(testFile, cube, dataset: '/cube');

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('writeMultiple', () async {
      final array1 = NDArray([1, 2, 3]);
      final array2 = NDArray([4, 5, 6]);

      await HDF5WriterUtils.writeMultiple(testFile, {
        '/data1': array1,
        '/data2': array2,
      });

      final file = File(testFile);
      expect(await file.exists(), true);
    });
  });

  group('HDF5 File Format', () {
    final testFile = 'test_format.h5';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('file has valid HDF5 signature', () async {
      final array = NDArray([1, 2, 3]);
      await array.toHDF5(testFile);

      final file = File(testFile);
      final bytes = await file.readAsBytes();

      // Check HDF5 signature
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x48); // 'H'
      expect(bytes[2], 0x44); // 'D'
      expect(bytes[3], 0x46); // 'F'
      expect(bytes[4], 0x0D);
      expect(bytes[5], 0x0A);
      expect(bytes[6], 0x1A);
      expect(bytes[7], 0x0A);
    });

    test('file has superblock', () async {
      final array = NDArray([1, 2, 3]);
      await array.toHDF5(testFile);

      final file = File(testFile);
      final bytes = await file.readAsBytes();

      // Check superblock version
      expect(bytes[8], 0); // Version 0

      // Check size of offsets and lengths
      expect(bytes[13], 8); // 8-byte offsets
      expect(bytes[14], 8); // 8-byte lengths
    });

    test('file contains shape information', () async {
      final array = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      await array.toHDF5(testFile);

      final file = File(testFile);
      final bytes = await file.readAsBytes();

      // File should contain shape data
      expect(bytes.length, greaterThan(100));
    });
  });

  group('Edge Cases', () {
    final testFile = 'test_edge.h5';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('write empty array should fail', () async {
      final array = NDArray.zeros([0]);

      expect(
        () => array.toHDF5(testFile),
        throwsA(isA<Exception>()),
      );
    });

    test('write single element', () async {
      final array = NDArray([42]);

      await array.toHDF5(testFile);

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('overwrite existing file', () async {
      final array1 = NDArray([1, 2, 3]);
      await array1.toHDF5(testFile);

      final array2 = NDArray([4, 5, 6]);
      await array2.toHDF5(testFile);

      final file = File(testFile);
      expect(await file.exists(), true);
    });
  });
}
