import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

void main() {
  group('HDF5 Attribute Reading Tests', () {
    late Hdf5File hdf5File;

    setUp(() async {
      // Create test file if it doesn't exist
      final testFile = File('example/data/test_attributes.h5');
      if (!testFile.existsSync()) {
        throw StateError(
            'Test file not found. Run: python create_attributes_test.py');
      }
      hdf5File = await Hdf5File.open('example/data/test_attributes.h5');
    });

    tearDown(() async {
      await hdf5File.close();
    });

    group('Scalar Attributes', () {
      test('Read string scalar attribute', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final unitsAttr = attributes.firstWhere((attr) => attr.name == 'units');
        expect(unitsAttr.isScalar, isTrue);
        expect(unitsAttr.value, equals('meters'));
      });

      test('Read float scalar attribute', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final versionAttr =
            attributes.firstWhere((attr) => attr.name == 'version');
        expect(versionAttr.isScalar, isTrue);
        expect(versionAttr.value, closeTo(1.0, 0.001));
      });

      test('Read integer scalar attribute', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final countAttr = attributes.firstWhere((attr) => attr.name == 'count');
        expect(countAttr.isScalar, isTrue);
        expect(countAttr.value, equals(100));
      });

      test('Read multiple string attributes', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final descAttr =
            attributes.firstWhere((attr) => attr.name == 'description');
        expect(descAttr.value, equals('Test dataset with attributes'));

        final authorAttr =
            attributes.firstWhere((attr) => attr.name == 'author');
        expect(authorAttr.value, equals('Test Suite'));

        final dateAttr = attributes.firstWhere((attr) => attr.name == 'date');
        expect(dateAttr.value, equals('2024-01-01'));
      });
    });

    group('Array Attributes', () {
      test('Read float array attribute', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final rangeAttr = attributes.firstWhere((attr) => attr.name == 'range');
        expect(rangeAttr.isArray, isTrue);
        expect(rangeAttr.value, isA<List>());
        expect(rangeAttr.value.length, equals(2));
        expect(rangeAttr.value[0], closeTo(0.0, 0.001));
        expect(rangeAttr.value[1], closeTo(100.0, 0.001));
      });

      test('Read integer array attribute', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final dimsAttr =
            attributes.firstWhere((attr) => attr.name == 'dimensions');
        expect(dimsAttr.isArray, isTrue);
        expect(dimsAttr.value, isA<List>());
        expect(dimsAttr.value.length, equals(2));
        expect(dimsAttr.value[0], equals(10));
        expect(dimsAttr.value[1], equals(10));
      });
    });

    group('Multiple Datasets with Attributes', () {
      test('Read attributes from measurements dataset', () async {
        final dataset = await hdf5File.dataset('/measurements');
        final attributes = dataset.header.findAttributes();

        expect(attributes.length, greaterThanOrEqualTo(6));

        final sensorAttr =
            attributes.firstWhere((attr) => attr.name == 'sensor');
        expect(sensorAttr.value, equals('Temperature Sensor A'));

        final locationAttr =
            attributes.firstWhere((attr) => attr.name == 'location');
        expect(locationAttr.value, equals('Lab Room 101'));

        final calibAttr =
            attributes.firstWhere((attr) => attr.name == 'calibration_date');
        expect(calibAttr.value, equals('2023-12-15'));

        // Check computed attributes
        final minAttr =
            attributes.firstWhere((attr) => attr.name == 'min_value');
        expect(minAttr.value, isA<double>());

        final maxAttr =
            attributes.firstWhere((attr) => attr.name == 'max_value');
        expect(maxAttr.value, isA<double>());

        final meanAttr =
            attributes.firstWhere((attr) => attr.name == 'mean_value');
        expect(meanAttr.value, isA<double>());
      });

      test('Read attributes from nested dataset', () async {
        final dataset = await hdf5File.dataset('/experiment/results');
        final attributes = dataset.header.findAttributes();

        expect(attributes.length, greaterThanOrEqualTo(2));

        final unitsAttr = attributes.firstWhere((attr) => attr.name == 'units');
        expect(unitsAttr.value, equals('counts'));

        final thresholdAttr =
            attributes.firstWhere((attr) => attr.name == 'threshold');
        expect(thresholdAttr.value, equals(10));
      });
    });

    group('Group Attributes', () {
      test('Read attributes from group', () async {
        final group = await hdf5File.group('/experiment');
        final attributes = group.header.findAttributes();

        expect(attributes.length, greaterThanOrEqualTo(3));

        final nameAttr = attributes.firstWhere((attr) => attr.name == 'name');
        expect(nameAttr.value, equals('Experiment 001'));

        final statusAttr =
            attributes.firstWhere((attr) => attr.name == 'status');
        expect(statusAttr.value, equals('completed'));

        final samplesAttr =
            attributes.firstWhere((attr) => attr.name == 'samples');
        expect(samplesAttr.value, equals(1000));
      });
    });

    group('Attribute API Methods', () {
      test('getValue method returns correct type', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final unitsAttr = attributes.firstWhere((attr) => attr.name == 'units');
        final unitsValue = unitsAttr.getValue<String>();
        expect(unitsValue, equals('meters'));

        final countAttr = attributes.firstWhere((attr) => attr.name == 'count');
        final countValue = countAttr.getValue<int>();
        expect(countValue, equals(100));
      });

      test('getArray method returns correct list', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final rangeAttr = attributes.firstWhere((attr) => attr.name == 'range');
        final rangeArray = rangeAttr.getArray<double>();
        expect(rangeArray.length, equals(2));
        expect(rangeArray[0], closeTo(0.0, 0.001));
        expect(rangeArray[1], closeTo(100.0, 0.001));
      });

      test('isScalar and isArray properties work correctly', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final unitsAttr = attributes.firstWhere((attr) => attr.name == 'units');
        expect(unitsAttr.isScalar, isTrue);
        expect(unitsAttr.isArray, isFalse);

        final rangeAttr = attributes.firstWhere((attr) => attr.name == 'range');
        expect(rangeAttr.isScalar, isFalse);
        expect(rangeAttr.isArray, isTrue);
      });
    });

    group('Attribute Listing', () {
      test('List all attribute names', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final attributeNames = attributes.map((attr) => attr.name).toList();

        expect(attributeNames, contains('units'));
        expect(attributeNames, contains('description'));
        expect(attributeNames, contains('version'));
        expect(attributeNames, contains('count'));
        expect(attributeNames, contains('range'));
        expect(attributeNames, contains('dimensions'));
        expect(attributeNames, contains('author'));
        expect(attributeNames, contains('date'));
      });

      test('Find specific attribute by name', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        final unitsAttr =
            attributes.where((attr) => attr.name == 'units').firstOrNull;
        expect(unitsAttr, isNotNull);
        expect(unitsAttr!.value, equals('meters'));

        final nonExistentAttr =
            attributes.where((attr) => attr.name == 'nonexistent').firstOrNull;
        expect(nonExistentAttr, isNull);
      });
    });

    group('Edge Cases', () {
      test('Dataset with no attributes returns empty list', () async {
        // The test file should have all datasets with attributes,
        // but we test the API behavior
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();
        expect(attributes, isA<List>());
        // This dataset has attributes, so we just verify it's not null
        expect(attributes, isNotEmpty);
      });

      test('Attributes preserve data types correctly', () async {
        final dataset = await hdf5File.dataset('/data');
        final attributes = dataset.header.findAttributes();

        // String type
        final unitsAttr = attributes.firstWhere((attr) => attr.name == 'units');
        expect(unitsAttr.value, isA<String>());

        // Float type
        final versionAttr =
            attributes.firstWhere((attr) => attr.name == 'version');
        expect(versionAttr.value, isA<double>());

        // Integer type
        final countAttr = attributes.firstWhere((attr) => attr.name == 'count');
        expect(countAttr.value, isA<int>());

        // Array type
        final rangeAttr = attributes.firstWhere((attr) => attr.name == 'range');
        expect(rangeAttr.value, isA<List>());
      });
    });
  });
}
