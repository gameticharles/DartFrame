import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Test reading boolean data from HDF5 file
void main() async {
  print('=== Testing Boolean Data Reading ===\n');

  final file = await Hdf5File.open('test_boolean.h5');
  print('Opened: test_boolean.h5\n');

  // Test 1: Read 1D boolean array
  print('Test 1: Reading /flags dataset');
  final flagsDataset = await file.dataset('/flags');
  print('  Datatype: ${flagsDataset.datatype.typeName}');
  print('  Is boolean-compatible: ${flagsDataset.datatype.isBoolean}');
  print('  Shape: ${flagsDataset.shape}');

  if (flagsDataset.datatype.isBoolean) {
    // Use the file's internal reader
    final raf = await File('test_boolean.h5').open();
    final reader = ByteReader(raf);

    final boolArray = await flagsDataset.readAsBoolean(reader);
    print('  Values: $boolArray');
    print('  ✓ Successfully read as boolean array\n');

    await raf.close();
  }

  // Test 2: Read 2D boolean array using readDataset
  print('Test 2: Reading /mask_2d dataset');
  final maskData = await file.readDataset('/mask_2d');
  print('  Raw data: $maskData');
  print('  ✓ Successfully read dataset\n');

  await file.close();
  print('=== All Tests Passed ===');
}
