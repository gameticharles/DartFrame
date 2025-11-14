import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Test converting integer timestamps to DateTime
void main() async {
  print('=== Testing Timestamp to DateTime Conversion ===\n');

  try {
    final file = await Hdf5File.open('test_time.h5');
    print('Opened: test_time.h5\n');

    // Test 1: Auto-detect seconds timestamps
    print('Test 1: Auto-detect 64-bit timestamps (seconds)');
    final timestampsDataset = await file.dataset('/timestamps');
    final raf = await File('test_time.h5').open();
    final reader = ByteReader(raf);

    final dates = await timestampsDataset.readAsDateTime(reader);
    print('  Converted ${dates.length} timestamps to DateTime:');
    for (int i = 0; i < dates.length; i++) {
      print('    [$i] ${dates[i].toUtc()}');
    }
    print('  ✓ Successfully converted seconds timestamps\n');

    // Test 2: Auto-detect milliseconds timestamps
    print('Test 2: Auto-detect millisecond timestamps');
    final timestampsMsDataset = await file.dataset('/timestamps_ms');
    final datesMs = await timestampsMsDataset.readAsDateTime(reader);
    print('  Converted ${datesMs.length} timestamps to DateTime:');
    for (int i = 0; i < datesMs.length; i++) {
      print('    [$i] ${datesMs[i].toUtc()}');
    }
    print('  ✓ Successfully converted millisecond timestamps\n');

    // Test 3: Force seconds interpretation
    print('Test 3: Force seconds interpretation');
    final datesForced = await timestampsDataset.readAsDateTime(
      reader,
      unit: 'seconds',
    );
    print('  First date: ${datesForced[0].toUtc()}');
    print('  ✓ Successfully forced seconds interpretation\n');

    // Test 4: Verify expected dates
    print('Test 4: Verifying expected dates');
    final expected = [
      DateTime.utc(2020, 1, 1, 0, 0, 0),
      DateTime.utc(2021, 6, 15, 12, 30, 0),
      DateTime.utc(2022, 12, 31, 23, 59, 59),
      DateTime.utc(2023, 7, 4, 16, 20, 0),
      DateTime.utc(2024, 11, 14, 10, 0, 0),
    ];

    bool allMatch = true;
    for (int i = 0; i < expected.length; i++) {
      final dt = dates[i];
      final exp = expected[i];
      final matches = dt.year == exp.year &&
          dt.month == exp.month &&
          dt.day == exp.day &&
          dt.hour == exp.hour &&
          dt.minute == exp.minute;

      if (!matches) {
        print('  ✗ Mismatch at index $i:');
        print('    Got:      $dt');
        print('    Expected: $exp');
        allMatch = false;
      } else {
        print('  ✓ Date $i matches: ${dt.toUtc()}');
      }
    }

    if (allMatch) {
      print('\n  ✓ All dates match expected values\n');
    }

    await raf.close();
    await file.close();
    print('=== All Tests Passed ===');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}
