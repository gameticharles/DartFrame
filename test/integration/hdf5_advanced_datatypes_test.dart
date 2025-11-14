import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

/// Integration tests for HDF5 advanced datatypes (array and enum)
/// Tests Requirements 3.6: Advanced datatype support
void main() {
  group('HDF5 Array Datatype Tests', () {
    late Hdf5File hdf5File;

    setUp(() async {
      if (!File('test/fixtures/array_test.h5').existsSync()) {
        throw StateError(
          'Test file not found: test/fixtures/array_test.h5. '
          'Run create_array_datatype_test.py first.',
        );
      }
      hdf5File = await Hdf5File.open('test/fixtures/array_test.h5');
    });

    tearDown(() async {
      await hdf5File.close();
    });

    test('reads compound with 1D array field', () async {
      // Test simple_array dataset: compound with 3-element integer array
      final data = await hdf5File.readDataset('/simple_array');

      expect(data, isA<List>());
      expect(data.length, equals(3));

      // Check first record
      expect(data[0]['id'], equals(1));
      expect(data[0]['values'], isA<List>());
      expect(data[0]['values'].length, equals(3));
      expect(data[0]['values'][0], equals(10));
      expect(data[0]['values'][1], equals(20));
      expect(data[0]['values'][2], equals(30));

      // Check second record
      expect(data[1]['id'], equals(2));
      expect(data[1]['values'][0], equals(40));
      expect(data[1]['values'][1], equals(50));
      expect(data[1]['values'][2], equals(60));

      // Check third record
      expect(data[2]['id'], equals(3));
      expect(data[2]['values'][0], equals(70));
      expect(data[2]['values'][1], equals(80));
      expect(data[2]['values'][2], equals(90));
    });

    test('reads compound with 2D array field', () async {
      // Test matrix_array dataset: compound with 2x3 float array
      final data = await hdf5File.readDataset('/matrix_array');

      expect(data, isA<List>());
      expect(data.length, equals(2));

      // Check first record
      expect(data[0]['name'], equals('first'));
      expect(data[0]['matrix'], isA<List>());
      expect(data[0]['matrix'].length, equals(6)); // Flattened 2x3 = 6 elements

      // Check values (flattened row-major order)
      expect(data[0]['matrix'][0], closeTo(1.1, 0.01));
      expect(data[0]['matrix'][1], closeTo(1.2, 0.01));
      expect(data[0]['matrix'][2], closeTo(1.3, 0.01));
      expect(data[0]['matrix'][3], closeTo(1.4, 0.01));
      expect(data[0]['matrix'][4], closeTo(1.5, 0.01));
      expect(data[0]['matrix'][5], closeTo(1.6, 0.01));

      // Check second record
      expect(data[1]['name'], equals('second'));
      expect(data[1]['matrix'][0], closeTo(2.1, 0.01));
      expect(data[1]['matrix'][5], closeTo(2.6, 0.01));
    });

    test('reads compound with multiple array fields', () async {
      // Test multi_array dataset: compound with coords (3 floats) and flags (4 bytes)
      final data = await hdf5File.readDataset('/multi_array');

      expect(data, isA<List>());
      expect(data.length, equals(2));

      // Check first record
      expect(data[0]['id'], equals(1));

      expect(data[0]['coords'], isA<List>());
      expect(data[0]['coords'].length, equals(3));
      expect(data[0]['coords'][0], closeTo(1.0, 0.01));
      expect(data[0]['coords'][1], closeTo(2.0, 0.01));
      expect(data[0]['coords'][2], closeTo(3.0, 0.01));

      expect(data[0]['flags'], isA<List>());
      expect(data[0]['flags'].length, equals(4));
      expect(data[0]['flags'][0], equals(1));
      expect(data[0]['flags'][1], equals(0));
      expect(data[0]['flags'][2], equals(1));
      expect(data[0]['flags'][3], equals(0));

      // Check second record
      expect(data[1]['id'], equals(2));
      expect(data[1]['coords'][0], closeTo(4.0, 0.01));
      expect(data[1]['flags'][0], equals(0));
      expect(data[1]['flags'][1], equals(1));
    });

    test('reads sensor data with array measurements', () async {
      // Test sensor_data dataset: compound with 5-element measurement array
      final data = await hdf5File.readDataset('/sensor_data');

      expect(data, isA<List>());
      expect(data.length, equals(3));

      // Check first record
      expect(data[0]['timestamp'], equals(1000));
      expect(data[0]['measurements'], isA<List>());
      expect(data[0]['measurements'].length, equals(5));
      expect(data[0]['measurements'][0], closeTo(1.1, 0.01));
      expect(data[0]['measurements'][4], closeTo(5.5, 0.01));
      expect(data[0]['status'], equals(1));

      // Check second record
      expect(data[1]['timestamp'], equals(2000));
      expect(data[1]['measurements'][0], closeTo(6.6, 0.01));
      expect(data[1]['measurements'][4], closeTo(10.0, 0.01));
      expect(data[1]['status'], equals(2));

      // Check third record
      expect(data[2]['timestamp'], equals(3000));
      expect(data[2]['measurements'][0], closeTo(11.1, 0.01));
      expect(data[2]['status'], equals(3));
    });
  });

  group('HDF5 Enum Datatype Tests', () {
    late Hdf5File hdf5File;

    setUp(() async {
      if (!File('test/fixtures/enum_test.h5').existsSync()) {
        throw StateError(
          'Test file not found: test/fixtures/enum_test.h5. '
          'Run create_enum_datatype_test.py first.',
        );
      }
      hdf5File = await Hdf5File.open('test/fixtures/enum_test.h5');
    });

    tearDown(() async {
      await hdf5File.close();
    });

    test('reads simple color enum dataset', () async {
      // Test colors dataset: RED=0, GREEN=1, BLUE=2
      final data = await hdf5File.readDataset('/colors');

      expect(data, isA<List>());
      expect(data.length, equals(5));

      // Values should be the enum integer values
      expect(data[0], equals(0)); // RED
      expect(data[1], equals(1)); // GREEN
      expect(data[2], equals(2)); // BLUE
      expect(data[3], equals(1)); // GREEN
      expect(data[4], equals(0)); // RED
    });

    test('reads status enum dataset', () async {
      // Test status dataset: IDLE=0, RUNNING=1, PAUSED=2, STOPPED=3, ERROR=4
      final data = await hdf5File.readDataset('/status');

      expect(data, isA<List>());
      expect(data.length, equals(7));

      expect(data[0], equals(0)); // IDLE
      expect(data[1], equals(1)); // RUNNING
      expect(data[2], equals(1)); // RUNNING
      expect(data[3], equals(2)); // PAUSED
      expect(data[4], equals(3)); // STOPPED
      expect(data[5], equals(1)); // RUNNING
      expect(data[6], equals(4)); // ERROR
    });

    test('reads compound with enum field', () async {
      // Test tasks dataset: compound with priority enum
      final data = await hdf5File.readDataset('/tasks');

      expect(data, isA<List>());
      expect(data.length, equals(4));

      // Check first record
      expect(data[0]['id'], equals(1));
      expect(data[0]['priority'], equals(0)); // LOW
      expect(data[0]['value'], closeTo(10.5, 0.01));

      // Check second record
      expect(data[1]['id'], equals(2));
      expect(data[1]['priority'], equals(2)); // HIGH
      expect(data[1]['value'], closeTo(20.3, 0.01));

      // Check third record
      expect(data[2]['id'], equals(3));
      expect(data[2]['priority'], equals(3)); // CRITICAL
      expect(data[2]['value'], closeTo(30.1, 0.01));

      // Check fourth record
      expect(data[3]['id'], equals(4));
      expect(data[3]['priority'], equals(1)); // MEDIUM
      expect(data[3]['value'], closeTo(40.7, 0.01));
    });

    test('reads compound with multiple enum fields', () async {
      // Test weather_log dataset: compound with day and weather enums
      final data = await hdf5File.readDataset('/weather_log');

      expect(data, isA<List>());
      expect(data.length, equals(3));

      // Check first record: Monday, Sunny, 25.5°C
      expect(data[0]['day'], equals(0)); // MONDAY
      expect(data[0]['weather'], equals(0)); // SUNNY
      expect(data[0]['temperature'], closeTo(25.5, 0.01));

      // Check second record: Tuesday, Cloudy, 22.3°C
      expect(data[1]['day'], equals(1)); // TUESDAY
      expect(data[1]['weather'], equals(1)); // CLOUDY
      expect(data[1]['temperature'], closeTo(22.3, 0.01));

      // Check third record: Wednesday, Rainy, 18.7°C
      expect(data[2]['day'], equals(2)); // WEDNESDAY
      expect(data[2]['weather'], equals(2)); // RAINY
      expect(data[2]['temperature'], closeTo(18.7, 0.01));
    });

    test('reads enum with uint8 base type', () async {
      // Test log_levels dataset: enum with uint8 base
      final data = await hdf5File.readDataset('/log_levels');

      expect(data, isA<List>());
      expect(data.length, equals(6));

      expect(data[0], equals(2)); // INFO
      expect(data[1], equals(2)); // INFO
      expect(data[2], equals(3)); // WARN
      expect(data[3], equals(4)); // ERROR
      expect(data[4], equals(2)); // INFO
      expect(data[5], equals(1)); // DEBUG
    });
  });

  group('HDF5 Advanced Datatype Metadata Tests', () {
    test('array datatype metadata is accessible', () async {
      final hdf5File = await Hdf5File.open('test/fixtures/array_test.h5');

      final dataset = await hdf5File.dataset('/simple_array');

      // Verify dataset has compound datatype
      expect(dataset.datatype.isCompound, isTrue);

      // Verify shape
      expect(dataset.shape, isA<List<int>>());
      expect(dataset.shape.isNotEmpty, isTrue);

      await hdf5File.close();
    });

    test('enum datatype metadata is accessible', () async {
      final hdf5File = await Hdf5File.open('test/fixtures/enum_test.h5');

      final dataset = await hdf5File.dataset('/colors');

      // Verify dataset has enum datatype
      expect(dataset.datatype.isEnum, isTrue);

      // Verify enum info is available
      expect(dataset.datatype.enumInfo, isNotNull);
      expect(dataset.datatype.enumInfo!.members, isNotEmpty);

      // Verify enum members
      final members = dataset.datatype.enumInfo!.members;
      expect(members.length, equals(3));

      // Check member names (order may vary)
      final memberNames = members.map((m) => m.name).toList();
      expect(memberNames, contains('RED'));
      expect(memberNames, contains('GREEN'));
      expect(memberNames, contains('BLUE'));

      await hdf5File.close();
    });
  });
}
