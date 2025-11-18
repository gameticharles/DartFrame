import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataCube HDF5 Extensions', () {
    final testFile = 'test/fixtures/datacube_test_output.h5';

    tearDown(() async {
      // Clean up test file
      final file = File(testFile);
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('toHDF5 writes DataCube with correct dimensions', () async {
      // Create a 3D DataCube
      final cube = DataCube.zeros(2, 3, 4);

      // Fill with test data
      for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 3; j++) {
          for (int k = 0; k < 4; k++) {
            cube.setValue([i, j, k], (i * 12 + j * 4 + k).toDouble());
          }
        }
      }

      // Write to HDF5
      await cube.toHDF5(testFile, dataset: '/cube');

      // Read back
      final file = await Hdf5File.open(testFile);
      try {
        final dataset = await file.dataset('/cube');
        final data = await file.readDataset('/cube');

        // Verify dimensions
        expect(dataset.dataspace.dimensions, equals([2, 3, 4]));

        // Verify data
        expect(data, isA<List>());
        final flatData = _flattenData(data);
        expect(flatData.length, equals(24));

        // Check a few values
        expect(flatData[0], equals(0.0));
        expect(flatData[1], equals(1.0));
        expect(flatData[23], equals(23.0));
      } finally {
        await file.close();
      }
    });

    test('toHDF5 preserves DataCube attributes', () async {
      final cube = DataCube.zeros(2, 2, 2);
      cube.attrs['units'] = 'meters';
      cube.attrs['description'] = 'Test cube';

      await cube.toHDF5(testFile, dataset: '/cube');

      final file = await Hdf5File.open(testFile);
      try {
        final dataset = await file.dataset('/cube');
        final attributes = dataset.attributes;

        expect(attributes.length, equals(2));

        final unitsAttr = attributes.firstWhere((a) => a.name == 'units');
        expect(unitsAttr.value, equals('meters'));

        final descAttr = attributes.firstWhere((a) => a.name == 'description');
        expect(descAttr.value, equals('Test cube'));
      } finally {
        await file.close();
      }
    });

    test('toHDF5 converts DataCube to NDArray correctly', () async {
      final cube = DataCube.zeros(3, 4, 5);

      // Fill with sequential values
      int value = 0;
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 4; j++) {
          for (int k = 0; k < 5; k++) {
            cube.setValue([i, j, k], value.toDouble());
            value++;
          }
        }
      }

      await cube.toHDF5(testFile, dataset: '/cube');

      final file = await Hdf5File.open(testFile);
      try {
        final data = await file.readDataset('/cube');
        final flatData = _flattenData(data);

        // Verify all values are preserved
        for (int i = 0; i < 60; i++) {
          expect(flatData[i], equals(i.toDouble()));
        }
      } finally {
        await file.close();
      }
    });

    test('toHDF5 handles various cube sizes', () async {
      final testCases = [
        [1, 1, 1],
        [2, 2, 2],
        [5, 10, 15],
        [10, 1, 10],
      ];

      for (final shape in testCases) {
        final cube = DataCube.zeros(shape[0], shape[1], shape[2]);
        await cube.toHDF5(testFile, dataset: '/cube');

        final file = await Hdf5File.open(testFile);
        try {
          final dataset = await file.dataset('/cube');
          expect(dataset.dataspace.dimensions, equals(shape));
        } finally {
          await file.close();
        }

        // Clean up for next iteration
        await File(testFile).delete();
      }
    });

    test('toHDF5 with custom dataset path', () async {
      final cube = DataCube.zeros(2, 2, 2);

      await cube.toHDF5(testFile, dataset: '/custompath');

      final file = await Hdf5File.open(testFile);
      try {
        final dataset = await file.dataset('/custompath');
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
