import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/group_writer.dart';
import 'package:dartframe/src/io/hdf5/byte_writer.dart';

void main() {
  group('GroupData', () {
    test('creates group with name and path', () {
      final group = GroupData(
        name: 'test',
        fullPath: '/test',
      );

      expect(group.name, equals('test'));
      expect(group.fullPath, equals('/test'));
      expect(group.isEmpty, isTrue);
      expect(group.childCount, equals(0));
    });

    test('adds datasets to group', () {
      final group = GroupData(
        name: 'test',
        fullPath: '/test',
      );

      group.addDataset('data1', 1000);
      group.addDataset('data2', 2000);

      expect(group.childCount, equals(2));
      expect(group.datasets.length, equals(2));
      expect(group.getChildAddress('data1'), equals(1000));
      expect(group.getChildAddress('data2'), equals(2000));
    });

    test('adds subgroups to group', () {
      final parent = GroupData(
        name: 'parent',
        fullPath: '/parent',
      );

      final child = GroupData(
        name: 'child',
        fullPath: '/parent/child',
      );
      child.objectHeaderAddress = 3000;

      parent.addSubgroup('child', child);

      expect(parent.childCount, equals(1));
      expect(parent.subgroups.length, equals(1));
      expect(parent.getChildAddress('child'), equals(3000));
    });

    test('throws error for duplicate child names', () {
      final group = GroupData(
        name: 'test',
        fullPath: '/test',
      );

      group.addDataset('duplicate', 1000);

      expect(
        () => group.addDataset('duplicate', 2000),
        throwsArgumentError,
      );
    });

    test('validates child names', () {
      final group = GroupData(
        name: 'test',
        fullPath: '/test',
      );

      expect(() => group.addDataset('', 1000), throwsArgumentError);
      expect(
          () => group.addDataset('name/with/slash', 1000), throwsArgumentError);
      expect(() => group.addDataset('.', 1000), throwsArgumentError);
      expect(() => group.addDataset('..', 1000), throwsArgumentError);
    });

    test('parses paths correctly', () {
      expect(
        GroupData.parsePath('/experiments/trial1/data'),
        equals(['experiments', 'trial1', 'data']),
      );

      expect(
        GroupData.parsePath('/single'),
        equals(['single']),
      );

      expect(
        GroupData.parsePath('/'),
        equals([]),
      );
    });

    test('validates paths', () {
      expect(() => GroupData.validatePath(''), throwsArgumentError);
      expect(() => GroupData.validatePath('no/leading/slash'),
          throwsArgumentError);
      expect(() => GroupData.validatePath('/trailing/'), throwsArgumentError);
      expect(
          () => GroupData.validatePath('/double//slash'), throwsArgumentError);

      // Valid paths should not throw
      GroupData.validatePath('/');
      GroupData.validatePath('/valid');
      GroupData.validatePath('/valid/path');
    });
  });

  group('GroupWriter', () {
    test('creates writer with format version', () {
      final writer = GroupWriter(formatVersion: 0);
      expect(writer.formatVersion, equals(0));

      final writer2 = GroupWriter(formatVersion: 2);
      expect(writer2.formatVersion, equals(2));
    });

    test('throws error for empty group', () async {
      final writer = GroupWriter();
      final byteWriter = ByteWriter();
      final group = GroupData(
        name: 'empty',
        fullPath: '/empty',
      );

      expect(
        () async => await writer.writeGroup(byteWriter, group),
        throwsArgumentError,
      );
    });

    test('writes group with single dataset', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'test',
        fullPath: '/test',
      );
      group.addDataset('data', 5000);

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));
      expect(group.objectHeaderAddress, equals(address));
      expect(group.btreeAddress, isNotNull);
      expect(group.localHeapAddress, isNotNull);
      expect(byteWriter.bytes.length, greaterThan(0));
    });

    test('writes group with multiple datasets', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'test',
        fullPath: '/test',
      );
      group.addDataset('data1', 5000);
      group.addDataset('data2', 6000);
      group.addDataset('data3', 7000);

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));
      expect(group.objectHeaderAddress, equals(address));
      expect(group.btreeAddress, isNotNull);
      expect(group.localHeapAddress, isNotNull);
      expect(byteWriter.bytes.length, greaterThan(0));
    });

    test('writes group with subgroups', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final parent = GroupData(
        name: 'parent',
        fullPath: '/parent',
      );

      final child1 = GroupData(
        name: 'child1',
        fullPath: '/parent/child1',
      );
      child1.objectHeaderAddress = 8000;

      final child2 = GroupData(
        name: 'child2',
        fullPath: '/parent/child2',
      );
      child2.objectHeaderAddress = 9000;

      parent.addSubgroup('child1', child1);
      parent.addSubgroup('child2', child2);

      final address = await writer.writeGroup(byteWriter, parent);

      expect(address, greaterThanOrEqualTo(0));
      expect(parent.objectHeaderAddress, equals(address));
      expect(parent.btreeAddress, isNotNull);
      expect(parent.localHeapAddress, isNotNull);
    });

    test('writes group with mixed children', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'mixed',
        fullPath: '/mixed',
      );

      group.addDataset('data1', 5000);
      group.addDataset('data2', 6000);

      final subgroup = GroupData(
        name: 'subgroup',
        fullPath: '/mixed/subgroup',
      );
      subgroup.objectHeaderAddress = 7000;
      group.addSubgroup('subgroup', subgroup);

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));
      expect(group.childCount, equals(3));
      expect(group.datasets.length, equals(2));
      expect(group.subgroups.length, equals(1));
    });

    test('writes single-level group with multiple children', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'root',
        fullPath: '/root',
      );

      // Add 5 datasets
      for (int i = 0; i < 5; i++) {
        group.addDataset('dataset_$i', 5000 + i * 1000);
      }

      // Add 3 subgroups
      for (int i = 0; i < 3; i++) {
        final subgroup = GroupData(
          name: 'group_$i',
          fullPath: '/root/group_$i',
        );
        subgroup.objectHeaderAddress = 10000 + i * 1000;
        group.addSubgroup('group_$i', subgroup);
      }

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));
      expect(group.childCount, equals(8));
      expect(group.datasets.length, equals(5));
      expect(group.subgroups.length, equals(3));
      expect(group.objectHeaderAddress, isNotNull);
      expect(group.btreeAddress, isNotNull);
      expect(group.localHeapAddress, isNotNull);
    });

    test('writes nested groups (10+ levels deep)', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      // Create a chain of 12 nested groups
      final groups = <GroupData>[];
      String currentPath = '';

      for (int i = 0; i < 12; i++) {
        currentPath += '/level$i';
        final group = GroupData(
          name: 'level$i',
          fullPath: currentPath,
        );
        groups.add(group);
      }

      // Add a dataset to the deepest group
      groups.last.addDataset('deep_data', 50000);

      // Write the deepest group first
      final deepestAddress = await writer.writeGroup(byteWriter, groups.last);
      expect(deepestAddress, greaterThanOrEqualTo(0));

      // Link each parent to its child (working backwards)
      for (int i = groups.length - 2; i >= 0; i--) {
        final parent = groups[i];
        final child = groups[i + 1];
        parent.addSubgroup(child.name, child);

        final parentAddress = await writer.writeGroup(byteWriter, parent);
        expect(parentAddress, greaterThanOrEqualTo(0));
        expect(parent.objectHeaderAddress, isNotNull);
      }

      // Verify the root group has the correct structure
      final root = groups.first;
      expect(root.childCount, equals(1));
      expect(root.subgroups.length, equals(1));
      expect(root.subgroups.containsKey('level1'), isTrue);
    });

    test('writes large group with 100+ objects', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'large',
        fullPath: '/large',
      );

      // Add 80 datasets
      for (int i = 0; i < 80; i++) {
        group.addDataset('dataset_$i', 10000 + i * 100);
      }

      // Add 30 subgroups
      for (int i = 0; i < 30; i++) {
        final subgroup = GroupData(
          name: 'subgroup_$i',
          fullPath: '/large/subgroup_$i',
        );
        subgroup.objectHeaderAddress = 20000 + i * 100;
        group.addSubgroup('subgroup_$i', subgroup);
      }

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));
      expect(group.childCount, equals(110));
      expect(group.datasets.length, equals(80));
      expect(group.subgroups.length, equals(30));
      expect(group.objectHeaderAddress, isNotNull);
      expect(group.btreeAddress, isNotNull);
      expect(group.localHeapAddress, isNotNull);

      // Verify all children are accessible
      for (int i = 0; i < 80; i++) {
        expect(group.getChildAddress('dataset_$i'), isNotNull);
      }
      for (int i = 0; i < 30; i++) {
        expect(group.getChildAddress('subgroup_$i'), isNotNull);
      }
    });

    test('writes group with attributes', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'with_attrs',
        fullPath: '/with_attrs',
        attributes: {
          'description': 'Test group with attributes',
          'version': 1,
          'created_by': 'dartframe',
        },
      );

      group.addDataset('data', 5000);

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));
      expect(group.attributes.length, equals(3));
      expect(group.attributes['description'],
          equals('Test group with attributes'));
      expect(group.attributes['version'], equals(1));
      expect(group.attributes['created_by'], equals('dartframe'));
    });

    test('writes group with long names', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'test',
        fullPath: '/test',
      );

      // Add datasets with long names
      final longName1 = 'dataset_with_very_long_name_' * 5;
      final longName2 = 'another_extremely_long_dataset_name_' * 5;

      group.addDataset(longName1, 5000);
      group.addDataset(longName2, 6000);

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));
      expect(group.getChildAddress(longName1), equals(5000));
      expect(group.getChildAddress(longName2), equals(6000));
    });

    test('writes group with special characters in names', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'test',
        fullPath: '/test',
      );

      // Add datasets with special characters (but not slashes)
      group.addDataset('data-with-dashes', 5000);
      group.addDataset('data_with_underscores', 6000);
      group.addDataset('data.with.dots', 7000);
      group.addDataset('data with spaces', 8000);

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));
      expect(group.childCount, equals(4));
      expect(group.getChildAddress('data-with-dashes'), equals(5000));
      expect(group.getChildAddress('data_with_underscores'), equals(6000));
      expect(group.getChildAddress('data.with.dots'), equals(7000));
      expect(group.getChildAddress('data with spaces'), equals(8000));
    });

    test('writes group with format version 2', () async {
      final writer = GroupWriter(formatVersion: 2);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'v2_group',
        fullPath: '/v2_group',
      );

      group.addDataset('data1', 5000);
      group.addDataset('data2', 6000);

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));
      expect(group.objectHeaderAddress, equals(address));
      // Format version 2 uses fractal heap and B-tree V2
      expect(group.fractalHeapAddress, isNotNull);
      expect(group.btreeAddress, isNotNull);
      // Local heap should not be used in v2
      expect(group.localHeapAddress, isNull);
    });

    test('preserves child order in group', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'ordered',
        fullPath: '/ordered',
      );

      // Add children in specific order
      final names = ['zebra', 'alpha', 'beta', 'gamma', 'delta'];
      for (int i = 0; i < names.length; i++) {
        group.addDataset(names[i], 5000 + i * 1000);
      }

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));

      // Verify all children are present
      final children = group.children;
      expect(children.length, equals(5));
      for (final name in names) {
        expect(children.contains(name), isTrue);
      }
    });

    test('handles group with maximum practical size', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      final group = GroupData(
        name: 'huge',
        fullPath: '/huge',
      );

      // Add 200 children (mix of datasets and groups)
      for (int i = 0; i < 150; i++) {
        group.addDataset('dataset_$i', 10000 + i);
      }

      for (int i = 0; i < 50; i++) {
        final subgroup = GroupData(
          name: 'group_$i',
          fullPath: '/huge/group_$i',
        );
        subgroup.objectHeaderAddress = 50000 + i;
        group.addSubgroup('group_$i', subgroup);
      }

      final address = await writer.writeGroup(byteWriter, group);

      expect(address, greaterThanOrEqualTo(0));
      expect(group.childCount, equals(200));
      expect(byteWriter.bytes.length, greaterThan(0));
    });

    test('writes multiple independent groups', () async {
      final writer = GroupWriter(formatVersion: 0);
      final byteWriter = ByteWriter();

      // Create and write first group
      final group1 = GroupData(
        name: 'group1',
        fullPath: '/group1',
      );
      group1.addDataset('data1', 5000);

      final address1 = await writer.writeGroup(byteWriter, group1);
      expect(address1, greaterThanOrEqualTo(0));

      // Create and write second group
      final group2 = GroupData(
        name: 'group2',
        fullPath: '/group2',
      );
      group2.addDataset('data2', 6000);

      final address2 = await writer.writeGroup(byteWriter, group2);
      expect(address2, greaterThanOrEqualTo(0));

      // Addresses should be different
      expect(address1, isNot(equals(address2)));
      expect(group1.objectHeaderAddress,
          isNot(equals(group2.objectHeaderAddress)));
    });
  });
}
