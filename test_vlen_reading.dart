import 'package:dartframe/dartframe.dart';

/// Test reading variable-length data from HDF5 file
void main() async {
  print('=== Testing Variable-Length Data Reading ===\n');

  try {
    final file = await Hdf5File.open('test_vlen.h5');
    print('Opened: test_vlen.h5\n');

    // Test 1: Read 1D vlen string array
    print('Test 1: Reading /vlen_strings dataset');
    final vlenStrDataset = await file.dataset('/vlen_strings');
    print('  Datatype: ${vlenStrDataset.datatype.typeName}');
    print('  Shape: ${vlenStrDataset.shape}');
    print(
        '  Is variable-length: ${vlenStrDataset.datatype.stringInfo?.isVariableLength}');

    final vlenStrData = await file.readDataset('/vlen_strings');
    print('  Values: $vlenStrData');
    print('  ✓ Successfully read vlen strings\n');

    // Test 2: Read 2D vlen string array
    print('Test 2: Reading /vlen_strings_2d dataset');
    final vlenStr2dDataset = await file.dataset('/vlen_strings_2d');
    print('  Datatype: ${vlenStr2dDataset.datatype.typeName}');
    print('  Shape: ${vlenStr2dDataset.shape}');

    final vlenStr2dData = await file.readDataset('/vlen_strings_2d');
    print('  Values: $vlenStr2dData');

    // Reshape for display
    final rows = vlenStr2dDataset.shape[0];
    final cols = vlenStr2dDataset.shape[1];
    print('  As 2D array:');
    for (int i = 0; i < rows; i++) {
      final row = vlenStr2dData.sublist(i * cols, (i + 1) * cols);
      print('    $row');
    }
    print('  ✓ Successfully read 2D vlen strings\n');

    // Test 3: Read vlen integer array
    print('Test 3: Reading /vlen_ints dataset');
    final vlenIntsDataset = await file.dataset('/vlen_ints');
    print('  Datatype: ${vlenIntsDataset.datatype.typeName}');
    print('  Shape: ${vlenIntsDataset.shape}');
    print('  Is variable-length: ${vlenIntsDataset.datatype.isVariableLength}');
    print('  Base type: ${vlenIntsDataset.datatype.baseType?.typeName}');

    final vlenIntsData = await file.readDataset('/vlen_ints');
    print('  Values: $vlenIntsData');
    print('  ✓ Successfully read vlen integer arrays\n');

    await file.close();
    print('=== All Tests Passed ===');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}
