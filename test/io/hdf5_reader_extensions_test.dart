import 'dart:io';
import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

// Helper functions for cleaner test code
Future<NDArray> readNDArray(String path, {String dataset = '/data'}) =>
    NDArrayHDF5.fromHDF5(path, dataset: dataset);

Future<DataCube> readDataCube(String path, {String dataset = '/data'}) =>
    DataCubeHDF5.fromHDF5(path, dataset: dataset);

void main() {
  // Cleanup helper
  Future<void> cleanup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  group('NDArray HDF5 Reader', () {
    final testFile = 'test_read_array.h5';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('read 1D array', () async {
      // Write test data
      final original = NDArray([1, 2, 3, 4, 5]);
      await original.toHDF5(testFile, dataset: '/data');

      // Read back
      final loaded = await readNDArray(testFile, dataset: '/data');

      expect(loaded.shape.toList(), [5]);
      expect(loaded.getValue([0]), 1);
      expect(loaded.getValue([4]), 5);
    });

    test('read 2D array', () async {
      // Write test data
      final original = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      await original.toHDF5(testFile, dataset: '/measurements');

      // Read back
      final loaded = await readNDArray(testFile, dataset: '/measurements');

      expect(loaded.shape.toList(), [2, 3]);
      expect(loaded.getValue([0, 0]), 1);
      expect(loaded.getValue([1, 2]), 6);
    });

    test('read 3D array', () async {
      // Write test data
      final original = NDArray([
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ]
      ]);
      await original.toHDF5(testFile, dataset: '/data3d');

      // Read back
      final loaded = await readNDArray(testFile, dataset: '/data3d');

      expect(loaded.shape.toList(), [2, 2, 2]);
      expect(loaded.getValue([0, 0, 0]), 1);
      expect(loaded.getValue([1, 1, 1]), 8);
    });

    test('read with attributes', () async {
      // Write test data with attributes
      final original = NDArray([1, 2, 3]);
      original.attrs['units'] = 'meters';
      original.attrs['description'] = 'Distance measurements';
      await original.toHDF5(testFile, dataset: '/distances');

      // Read back
      final loaded = await readNDArray(testFile, dataset: '/distances');

      expect(loaded.attrs['units'], 'meters');
      expect(loaded.attrs['description'], 'Distance measurements');
    });

    test('read large array', () async {
      // Write test data
      final original = NDArray.zeros([100, 100]);
      await original.toHDF5(testFile, dataset: '/large');

      // Read back
      final loaded = await readNDArray(testFile, dataset: '/large');

      expect(loaded.shape.toList(), [100, 100]);
      expect(loaded.size, 10000);
    });

    test('read non-existent dataset throws', () async {
      // Write test data
      final original = NDArray([1, 2, 3]);
      await original.toHDF5(testFile, dataset: '/data');

      // Try to read non-existent dataset
      expect(
        () => readNDArray(testFile, dataset: '/nonexistent'),
        throwsArgumentError,
      );
    });
  });

  group('DataCube HDF5 Reader', () {
    final testFile = 'test_read_cube.h5';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('read DataCube', () async {
      // Write test data
      final original = DataCube.zeros(3, 4, 5);
      await original.toHDF5(testFile, dataset: '/cube');

      // Read back
      final loaded = await readDataCube(testFile, dataset: '/cube');

      expect(loaded.depth, 3);
      expect(loaded.rows, 4);
      expect(loaded.columns, 5);
    });

    test('read DataCube with attributes', () async {
      // Write test data with attributes
      final original = DataCube.ones(2, 3, 4);
      original.attrs['units'] = 'celsius';
      original.attrs['sensor'] = 'TMP36';
      await original.toHDF5(testFile, dataset: '/temperature');

      // Read back
      final loaded = await readDataCube(testFile, dataset: '/temperature');

      expect(loaded.attrs['units'], 'celsius');
      expect(loaded.attrs['sensor'], 'TMP36');
    });

    test('read DataCube with data', () async {
      // Write test data
      final original =
          DataCube.generate(2, 3, 4, (d, r, c) => d * 100 + r * 10 + c);
      await original.toHDF5(testFile, dataset: '/data');

      // Read back
      final loaded = await readDataCube(testFile, dataset: '/data');

      expect(loaded.getValue([0, 0, 0]), 0);
      expect(loaded.getValue([1, 2, 3]), 123);
    });

    test('read non-3D dataset throws', () async {
      // Write 2D data
      final original = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      await original.toHDF5(testFile, dataset: '/data2d');

      // Try to read as DataCube
      expect(
        () => readDataCube(testFile, dataset: '/data2d'),
        throwsArgumentError,
      );
    });
  });

  group('HDF5Reader Utility', () {
    final testFile = 'test_utility_read.h5';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('readNDArray', () async {
      // Write test data
      final original = NDArray([1, 2, 3, 4]);
      await original.toHDF5(testFile, dataset: '/data');

      // Read back
      final loaded =
          await HDF5ReaderUtil.readNDArray(testFile, dataset: '/data');

      expect(loaded.shape.toList(), [4]);
      expect(loaded.getValue([0]), 1);
    });

    test('readDataCube', () async {
      // Write test data
      final original = DataCube.zeros(2, 3, 4);
      await original.toHDF5(testFile, dataset: '/cube');

      // Read back
      final loaded =
          await HDF5ReaderUtil.readDataCube(testFile, dataset: '/cube');

      expect(loaded.depth, 2);
      expect(loaded.rows, 3);
      expect(loaded.columns, 4);
    });

    test('getDatasetInfo', () async {
      // Write test data
      final original = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      original.attrs['units'] = 'meters';
      await original.toHDF5(testFile, dataset: '/data');

      // Get info
      final info = await HDF5ReaderUtil.getDatasetInfo(testFile, '/data');

      expect(info['shape'], [2, 3]);
      expect(info['ndim'], 2);
      expect(info['size'], 6);
      expect(info['attributes'], isA<Map>());
    });
  });

  group('Round-trip Tests', () {
    final testFile = 'test_roundtrip.h5';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('NDArray round-trip preserves data', () async {
      final original = NDArray.generate([10, 20], (i) => i[0] * 20 + i[1]);

      await original.toHDF5(testFile, dataset: '/data');
      final loaded = await readNDArray(testFile, dataset: '/data');

      expect(loaded.shape.toList(), original.shape.toList());

      // Check all values
      for (int i = 0; i < original.shape[0]; i++) {
        for (int j = 0; j < original.shape[1]; j++) {
          expect(loaded.getValue([i, j]), original.getValue([i, j]));
        }
      }
    });

    test('DataCube round-trip preserves data', () async {
      final original = DataCube.generate(3, 4, 5, (d, r, c) => d + r + c);

      await original.toHDF5(testFile, dataset: '/cube');
      final loaded = await readDataCube(testFile, dataset: '/cube');

      expect(loaded.depth, original.depth);
      expect(loaded.rows, original.rows);
      expect(loaded.columns, original.columns);

      // Check sample values
      expect(loaded.getValue([0, 0, 0]), original.getValue([0, 0, 0]));
      expect(loaded.getValue([2, 3, 4]), original.getValue([2, 3, 4]));
    });

    test('attributes round-trip', () async {
      final original = NDArray([1, 2, 3]);
      original.attrs['name'] = 'test';
      original.attrs['version'] = 1;

      await original.toHDF5(testFile, dataset: '/data');
      final loaded = await readNDArray(testFile, dataset: '/data');

      expect(loaded.attrs['name'], 'test');
      expect(loaded.attrs['version'], 1);
    });
  });

  group('Edge Cases', () {
    final testFile = 'test_edge_read.h5';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('read empty array', () async {
      final original = NDArray.zeros([0]);
      await original.toHDF5(testFile);

      final loaded = await readNDArray(testFile);

      expect(loaded.size, 0);
    });

    test('read single element', () async {
      final original = NDArray([42]);
      await original.toHDF5(testFile);

      final loaded = await readNDArray(testFile);

      expect(loaded.getValue([0]), 42);
    });
  });
}
