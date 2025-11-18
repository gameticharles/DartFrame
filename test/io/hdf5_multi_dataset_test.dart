import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/hdf5_file_builder.dart';
import 'package:dartframe/src/io/hdf5/write_options.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';

void main() {
  group('HDF5FileBuilder Multi-Dataset Support', () {
    late HDF5FileBuilder builder;

    setUp(() {
      builder = HDF5FileBuilder();
    });

    // ========== Test adding multiple datasets to root ==========

    test('can add multiple datasets to root', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);
      final array2 = NDArray.fromFlat([4.0, 5.0, 6.0], [3]);

      await builder.addDataset('/data1', array1);
      await builder.addDataset('/data2', array2);

      final bytes = await builder.finalize();

      // Check HDF5 signature
      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      expect(bytes.length, greaterThan(200));
    });

    test('can add many datasets to root', () async {
      // Add 5 datasets to test multiple entries
      for (int i = 0; i < 5; i++) {
        final array = NDArray.fromFlat(
          List.generate(10, (j) => (i * 10 + j).toDouble()),
          [10],
        );
        await builder.addDataset('/dataset_$i', array);
      }

      final bytes = await builder.finalize();

      // Verify file is valid
      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));

      // Verify all datasets are tracked
      final addresses = builder.addresses;
      for (int i = 0; i < 5; i++) {
        expect(addresses['dataset_/dataset_$i'], isNotNull);
      }
    });

    test('can add datasets with different shapes to root', () async {
      final array1D = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);
      final array2D = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
      final array3D = NDArray.fromFlat(
        List.generate(8, (i) => i.toDouble()),
        [2, 2, 2],
      );

      await builder.addDataset('/data1d', array1D);
      await builder.addDataset('/data2d', array2D);
      await builder.addDataset('/data3d', array3D);

      final bytes = await builder.finalize();

      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
    });

    // ========== Test creating nested group hierarchies ==========

    test('can create groups', () async {
      await builder.createGroup('/group1');

      final array = NDArray.fromFlat([1.0, 2.0], [2]);
      await builder.addDataset('/group1/data', array);

      final bytes = await builder.finalize();

      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
    });

    test('can create nested groups automatically', () async {
      final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);

      await builder.addDataset(
        '/group1/group2/data',
        array,
        options: const WriteOptions(createIntermediateGroups: true),
      );

      final bytes = await builder.finalize();

      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
    });

    test('can create deeply nested group hierarchy', () async {
      // Create a 5-level deep hierarchy
      final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);

      await builder.addDataset(
        '/level1/level2/level3/level4/level5/data',
        array,
        options: const WriteOptions(createIntermediateGroups: true),
      );

      final bytes = await builder.finalize();

      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));

      // Verify group addresses are tracked
      final addresses = builder.addresses;
      expect(addresses['group_/level1'], isNotNull);
      expect(addresses['group_/level1/level2'], isNotNull);
      expect(addresses['group_/level1/level2/level3'], isNotNull);
    });

    test('can create multiple nested groups with datasets', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);
      final array3 = NDArray.fromFlat([5.0, 6.0], [2]);

      await builder.addDataset('/experiments/trial1/data', array1);
      await builder.addDataset('/experiments/trial2/data', array2);
      await builder.addDataset('/experiments/trial1/results', array3);

      final bytes = await builder.finalize();

      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));

      // Verify all groups are created
      final addresses = builder.addresses;
      expect(addresses['group_/experiments'], isNotNull);
      expect(addresses['group_/experiments/trial1'], isNotNull);
      expect(addresses['group_/experiments/trial2'], isNotNull);
    });

    test('can create groups with attributes', () async {
      await builder.createGroup(
        '/metadata',
        attributes: {
          'description': 'Experimental metadata',
          'version': 1,
        },
      );

      final array = NDArray.fromFlat([1.0, 2.0], [2]);
      await builder.addDataset('/metadata/data', array);

      final bytes = await builder.finalize();

      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
    });

    test('can create complex hierarchy with mixed groups and datasets',
        () async {
      // Create a complex structure:
      // /
      // ├── root_data
      // ├── experiments/
      // │   ├── trial1/
      // │   │   ├── input
      // │   │   └── output
      // │   └── trial2/
      // │       └── results
      // └── metadata/
      //     └── info

      final rootData = NDArray.fromFlat([1.0, 2.0], [2]);
      final input1 = NDArray.fromFlat([3.0, 4.0], [2]);
      final output1 = NDArray.fromFlat([5.0, 6.0], [2]);
      final results2 = NDArray.fromFlat([7.0, 8.0], [2]);
      final info = NDArray.fromFlat([9.0, 10.0], [2]);

      await builder.addDataset('/root_data', rootData);
      await builder.addDataset('/experiments/trial1/input', input1);
      await builder.addDataset('/experiments/trial1/output', output1);
      await builder.addDataset('/experiments/trial2/results', results2);
      await builder.addDataset('/metadata/info', info);

      final bytes = await builder.finalize();

      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));

      // Verify all datasets are tracked
      final addresses = builder.addresses;
      expect(addresses['dataset_/root_data'], isNotNull);
      expect(addresses['dataset_/experiments/trial1/input'], isNotNull);
      expect(addresses['dataset_/experiments/trial1/output'], isNotNull);
      expect(addresses['dataset_/experiments/trial2/results'], isNotNull);
      expect(addresses['dataset_/metadata/info'], isNotNull);
    });

    // ========== Test path conflict detection ==========

    test('rejects duplicate dataset paths', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);

      await builder.addDataset('/data', array1);

      await expectLater(
        builder.addDataset('/data', array2),
        throwsArgumentError,
      );
    });

    test('rejects dataset/group name conflicts', () async {
      await builder.createGroup('/mygroup');

      final array = NDArray.fromFlat([1.0, 2.0], [2]);

      expect(
        () => builder.addDataset('/mygroup', array),
        throwsArgumentError,
      );
    });

    test('rejects group/dataset name conflicts', () async {
      final array = NDArray.fromFlat([1.0, 2.0], [2]);
      await builder.addDataset('/mydata', array);

      expect(
        () => builder.createGroup('/mydata'),
        throwsArgumentError,
      );
    });

    test('rejects nested path conflicts', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);

      // Create a dataset at /group1/data
      await builder.addDataset('/group1/data', array1);

      // Try to create a group at the same path - should fail
      expect(
        () => builder.createGroup('/group1/data'),
        throwsArgumentError,
      );

      // Try to add another dataset at the same path - should fail
      await expectLater(
        builder.addDataset('/group1/data', array2),
        throwsArgumentError,
      );
    });

    test('rejects conflicts with intermediate groups', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);

      // Create a dataset at /parent/child
      await builder.addDataset('/parent/child', array1);

      // Try to create a dataset where 'child' would need to be a group
      // This should fail because 'child' is already a dataset
      await expectLater(
        builder.addDataset('/parent/child/data', array2),
        throwsArgumentError,
      );
    });

    test('detects conflicts in complex hierarchies', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);

      // Build a hierarchy
      await builder.addDataset('/a/b/c/data1', array1);

      // Try to create a dataset where 'c' would need to be both group and dataset
      await expectLater(
        builder.addDataset('/a/b/c', array2),
        throwsArgumentError,
      );
    });

    test('validates paths correctly', () async {
      final array = NDArray.fromFlat([1.0, 2.0], [2]);

      // Invalid: no leading slash
      expect(
        () => builder.addDataset('data', array),
        throwsArgumentError,
      );

      // Invalid: ends with slash
      expect(
        () => builder.addDataset('/data/', array),
        throwsArgumentError,
      );

      // Invalid: consecutive slashes
      expect(
        () => builder.addDataset('/group//data', array),
        throwsArgumentError,
      );

      // Invalid: contains dots
      expect(
        () => builder.addDataset('/group/./data', array),
        throwsArgumentError,
      );
    });

    test('requires at least one dataset before finalize', () async {
      expect(
        () => builder.finalize(),
        throwsA(isA<Exception>()),
      );
    });

    // ========== Test address tracking and resolution ==========

    test('tracks addresses for multiple datasets', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);

      await builder.addDataset('/data1', array1);
      await builder.addDataset('/data2', array2);

      await builder.finalize();

      final addresses = builder.addresses;
      expect(addresses['dataset_/data1'], isNotNull);
      expect(addresses['dataset_/data2'], isNotNull);
      expect(addresses['rootGroup'], isNotNull);
    });

    test('tracks addresses for groups and datasets', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);

      await builder.addDataset('/group1/data1', array1);
      await builder.addDataset('/group2/data2', array2);

      await builder.finalize();

      final addresses = builder.addresses;

      // Check dataset addresses
      expect(addresses['dataset_/group1/data1'], isNotNull);
      expect(addresses['dataset_/group2/data2'], isNotNull);

      // Check group addresses
      expect(addresses['group_/group1'], isNotNull);
      expect(addresses['group_/group2'], isNotNull);

      // Check root group
      expect(addresses['rootGroup'], isNotNull);
    });

    test('tracks addresses for nested group hierarchy', () async {
      final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);

      await builder.addDataset('/a/b/c/data', array);

      await builder.finalize();

      final addresses = builder.addresses;

      // Check all group addresses in hierarchy
      expect(addresses['group_/a'], isNotNull);
      expect(addresses['group_/a/b'], isNotNull);
      expect(addresses['group_/a/b/c'], isNotNull);

      // Check dataset address
      expect(addresses['dataset_/a/b/c/data'], isNotNull);

      // Verify addresses are unique
      final addressValues = addresses.values.toSet();
      expect(addressValues.length, equals(addresses.length),
          reason: 'All addresses should be unique');
    });

    test('tracks addresses for complex multi-dataset structure', () async {
      // Create multiple datasets in different groups
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 2; j++) {
          final array = NDArray.fromFlat([1.0, 2.0], [2]);
          await builder.addDataset('/group$i/dataset$j', array);
        }
      }

      await builder.finalize();

      final addresses = builder.addresses;

      // Verify all datasets are tracked
      for (int i = 0; i < 3; i++) {
        expect(addresses['group_/group$i'], isNotNull);
        for (int j = 0; j < 2; j++) {
          expect(addresses['dataset_/group$i/dataset$j'], isNotNull);
        }
      }

      // Verify superblock and root group
      expect(addresses['superblock'], isNotNull);
      expect(addresses['rootGroup'], isNotNull);
      expect(addresses['endOfFile'], isNotNull);
    });

    test('addresses are valid file offsets', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);

      await builder.addDataset('/data1', array1);
      await builder.addDataset('/data2', array2);

      final bytes = await builder.finalize();
      final addresses = builder.addresses;

      // All addresses should be within file bounds (except endOfFile which equals file length)
      for (final entry in addresses.entries) {
        expect(entry.value, greaterThanOrEqualTo(0),
            reason: '${entry.key} address should be non-negative');

        // endOfFile is allowed to equal file length
        if (entry.key == 'endOfFile') {
          expect(entry.value, lessThanOrEqualTo(bytes.length),
              reason: '${entry.key} address should not exceed file bounds');
        } else {
          expect(entry.value, lessThan(bytes.length),
              reason: '${entry.key} address should be within file bounds');
        }
      }

      // Superblock should be at offset 0
      expect(addresses['superblock'], equals(0));

      // End of file should match file length
      expect(addresses['endOfFile'], equals(bytes.length));
    });

    test('can retrieve addresses by name', () async {
      final array = NDArray.fromFlat([1.0, 2.0], [2]);
      await builder.addDataset('/mydata', array);

      await builder.finalize();

      // Test getAddress method
      expect(builder.getAddress('dataset_/mydata'), isNotNull);
      expect(builder.getAddress('rootGroup'), isNotNull);
      expect(builder.getAddress('superblock'), equals(0));
      expect(builder.getAddress('nonexistent'), isNull);
    });

    test('handles datasets with attributes', () async {
      final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);

      await builder.addDataset(
        '/data',
        array,
        options: WriteOptions(
          attributes: {
            'units': 'meters',
            'description': 'Test data',
          },
        ),
      );

      final bytes = await builder.finalize();

      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
    });

    test('can mix root and grouped datasets', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);
      final array3 = NDArray.fromFlat([5.0, 6.0], [2]);

      await builder.addDataset('/root_data', array1);
      await builder.addDataset('/group1/data1', array2);
      await builder.addDataset('/group1/data2', array3);

      final bytes = await builder.finalize();

      expect(bytes.sublist(0, 8),
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      expect(bytes.length, greaterThan(300));
    });
  });
}
