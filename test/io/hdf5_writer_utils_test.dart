import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('HDF5WriterUtils', () {
    final testFile = 'test/fixtures/writer_utils_test_output.h5';

    tearDown(() async {
      // Clean up test file
      final file = File(testFile);
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('writeNDArray creates valid HDF5 file', () async {
      final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);

      await HDF5WriterUtils.writeNDArray(testFile, array, dataset: '/matrix');

      final file = await Hdf5File.open(testFile);
      try {
        final dataset = await file.dataset('/matrix');
        expect(dataset.dataspace.dimensions, equals([2, 2]));

        final data = await file.readDataset('/matrix');
        final flatData = _flattenData(data);
        expect(flatData, equals([1.0, 2.0, 3.0, 4.0]));
      } finally {
        await file.close();
      }
    });

    test('writeNDArray with attributes', () async {
      final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);

      await HDF5WriterUtils.writeNDArray(
        testFile,
        array,
        dataset: '/data',
        attributes: {'units': 'meters', 'description': 'Test data'},
      );

      final file = await Hdf5File.open(testFile);
      try {
        final dataset = await file.dataset('/data');
        final attributes = dataset.attributes;

        expect(attributes.length, equals(2));
        expect(attributes.any((a) => a.name == 'units'), isTrue);
        expect(attributes.any((a) => a.name == 'description'), isTrue);
      } finally {
        await file.close();
      }
    });

    test('writeDataCube creates valid HDF5 file', () async {
      final cube = DataCube.zeros(2, 3, 4);

      // Fill with test data
      int value = 0;
      for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 3; j++) {
          for (int k = 0; k < 4; k++) {
            cube.setValue([i, j, k], value.toDouble());
            value++;
          }
        }
      }

      await HDF5WriterUtils.writeDataCube(testFile, cube, dataset: '/cube');

      final file = await Hdf5File.open(testFile);
      try {
        final dataset = await file.dataset('/cube');
        expect(dataset.dataspace.dimensions, equals([2, 3, 4]));

        final data = await file.readDataset('/cube');
        final flatData = _flattenData(data);
        expect(flatData.length, equals(24));

        // Check sequential values
        for (int i = 0; i < 24; i++) {
          expect(flatData[i], equals(i.toDouble()));
        }
      } finally {
        await file.close();
      }
    });

    test('writeDataCube with attributes', () async {
      final cube = DataCube.zeros(2, 2, 2);

      await HDF5WriterUtils.writeDataCube(
        testFile,
        cube,
        dataset: '/cube',
        attributes: {'type': '3D data', 'version': 1},
      );

      final file = await Hdf5File.open(testFile);
      try {
        final dataset = await file.dataset('/cube');
        final attributes = dataset.attributes;

        expect(attributes.length, greaterThanOrEqualTo(1));
        expect(attributes.any((a) => a.name == 'type'), isTrue);
      } finally {
        await file.close();
      }
    });

    test('writeMultiple writes first dataset', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);

      await HDF5WriterUtils.writeMultiple(testFile, {
        '/data1': array1,
        '/data2': array2,
      });

      final file = await Hdf5File.open(testFile);
      try {
        // Should have at least the first dataset
        final structure = await file.listRecursive();
        expect(structure.isNotEmpty, isTrue);

        // Currently only writes first dataset
        final dataset = await file.dataset('/data1');
        expect(dataset.dataspace.dimensions, equals([2]));
      } finally {
        await file.close();
      }
    });

    test('API consistency between methods', () async {
      // Test that both methods produce compatible files
      final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);

      // Write using utility method
      await HDF5WriterUtils.writeNDArray(testFile, array, dataset: '/data');

      final file1 = await Hdf5File.open(testFile);
      final data1 = await file1.readDataset('/data');
      await file1.close();

      // Clean up
      await File(testFile).delete();

      // Write using extension method
      await array.toHDF5(testFile, dataset: '/data');

      final file2 = await Hdf5File.open(testFile);
      final data2 = await file2.readDataset('/data');
      await file2.close();

      // Both should produce identical data
      expect(_flattenData(data1), equals(_flattenData(data2)));
    });

    test('writeNDArray with default dataset name', () async {
      final array = NDArray.fromFlat([1.0, 2.0], [2]);

      await HDF5WriterUtils.writeNDArray(testFile, array);

      final file = await Hdf5File.open(testFile);
      try {
        final dataset = await file.dataset('/data');
        expect(dataset.dataspace.dimensions, equals([2]));
      } finally {
        await file.close();
      }
    });

    test('writeDataCube with default dataset name', () async {
      final cube = DataCube.zeros(2, 2, 2);

      await HDF5WriterUtils.writeDataCube(testFile, cube);

      final file = await Hdf5File.open(testFile);
      try {
        final dataset = await file.dataset('/data');
        expect(dataset.dataspace.dimensions, equals([2, 2, 2]));
      } finally {
        await file.close();
      }
    });
  });
}

/// Helper to flatten nested list data
List<num> _flattenData(dynamic data) {
  final result = <num>[];

  void flatten(dynamic item) {
    if (item is num) {
      result.add(item);
    } else if (item is List) {
      for (final element in item) {
        flatten(element);
      }
    }
  }

  flatten(data);
  return result;
}
