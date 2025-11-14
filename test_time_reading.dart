import 'package:dartframe/dartframe.dart';

/// Test reading time data from HDF5 file
void main() async {
  print('=== Testing Time Data Reading ===\n');

  try {
    final file = await Hdf5File.open('test_time.h5');
    print('Opened: test_time.h5\n');

    // Test 1: Read 64-bit timestamps
    print('Test 1: Reading /timestamps dataset (64-bit)');
    final timestampsDataset = await file.dataset('/timestamps');
    print('  Datatype: ${timestampsDataset.datatype.typeName}');
    print('  Shape: ${timestampsDataset.shape}');

    final timestamps = await file.readDataset('/timestamps');
    print('  Values:');
    for (int i = 0; i < timestamps.length; i++) {
      if (timestamps[i] is DateTime) {
        final dt = timestamps[i] as DateTime;
        print('    [$i] ${dt.toUtc()}');
      } else {
        print('    [$i] ${timestamps[i]} (type: ${timestamps[i].runtimeType})');
      }
    }
    print('  ✓ Successfully read 64-bit timestamps\n');

    // Test 2: Read 32-bit timestamps
    print('Test 2: Reading /timestamps_32bit dataset (32-bit)');
    final timestamps32Dataset = await file.dataset('/timestamps_32bit');
    print('  Datatype: ${timestamps32Dataset.datatype.typeName}');
    print('  Shape: ${timestamps32Dataset.shape}');

    final timestamps32 = await file.readDataset('/timestamps_32bit');
    print('  Values:');
    for (int i = 0; i < timestamps32.length; i++) {
      if (timestamps32[i] is DateTime) {
        final dt = timestamps32[i] as DateTime;
        print('    [$i] ${dt.toUtc()}');
      } else {
        print(
            '    [$i] ${timestamps32[i]} (type: ${timestamps32[i].runtimeType})');
      }
    }
    print('  ✓ Successfully read 32-bit timestamps\n');

    // Test 3: Read millisecond timestamps
    print('Test 3: Reading /timestamps_ms dataset (milliseconds)');
    final timestampsMsDataset = await file.dataset('/timestamps_ms');
    print('  Datatype: ${timestampsMsDataset.datatype.typeName}');
    print('  Shape: ${timestampsMsDataset.shape}');

    final timestampsMs = await file.readDataset('/timestamps_ms');
    print('  Values:');
    for (int i = 0; i < timestampsMs.length; i++) {
      if (timestampsMs[i] is DateTime) {
        final dt = timestampsMs[i] as DateTime;
        print('    [$i] ${dt.toUtc()}');
      } else {
        print(
            '    [$i] ${timestampsMs[i]} (type: ${timestampsMs[i].runtimeType})');
      }
    }
    print('  ✓ Successfully read millisecond timestamps\n');

    // Test 4: Verify dates
    print('Test 4: Verifying expected dates');
    final expected = [
      DateTime.utc(2020, 1, 1, 0, 0, 0),
      DateTime.utc(2021, 6, 15, 12, 30, 0),
      DateTime.utc(2022, 12, 31, 23, 59, 59),
    ];

    bool allMatch = true;
    for (int i = 0; i < 3; i++) {
      if (timestamps[i] is DateTime) {
        final dt = timestamps[i] as DateTime;
        final matches = dt.year == expected[i].year &&
            dt.month == expected[i].month &&
            dt.day == expected[i].day &&
            dt.hour == expected[i].hour &&
            dt.minute == expected[i].minute;

        if (!matches) {
          print('  ✗ Mismatch at index $i: got $dt, expected ${expected[i]}');
          allMatch = false;
        }
      }
    }

    if (allMatch) {
      print('  ✓ All dates match expected values\n');
    }

    await file.close();
    print('=== All Tests Passed ===');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}
