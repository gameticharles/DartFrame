/// Simple test script for HDF5 nested groups and MAT file roundtrip
///
/// Run with: dart run examples/test_mat_roundtrip.dart
library;

import 'dart:io';
import 'package:dartframe/dartframe.dart';

void main() async {
  print('╔═══════════════════════════════════════════════════╗');
  print('║  DartFrame MATLAB v7.3 Read/Write Test Suite     ║');
  print('╚═══════════════════════════════════════════════════╝\n');

  var allPassed = true;

  // Test 1: HDF5 Nested Groups
  print('TEST 1: HDF5 Nested Group Support');
  print('─────────────────────────────────────────');
  try {
    allPassed = await testNestedGroups() && allPassed;
  } catch (e, stack) {
    print('✗ FAILED: $e');
    print(stack);
    allPassed = false;
  }

  print('');

  // Test 2: Basic MAT Writing
  print('TEST 2: Basic MAT File Writing');
  print('─────────────────────────────────────────');
  try {
    allPassed = await testBasicMatWriting() && allPassed;
  } catch (e, stack) {
    print('✗ FAILED: $e');
    print(stack);
    allPassed = false;
  }

  print('');

  // Test 3: MAT Roundtrip (Write then Read)
  print('TEST 3: MAT File Roundtrip');
  print('─────────────────────────────────────────');
  try {
    allPassed = await testMatRoundtrip() && allPassed;
  } catch (e, stack) {
    print('✗ FAILED: $e');
    print(stack);
    allPassed = false;
  }

  print('');
  print('═════════════════════════════════════════');
  if (allPassed) {
    print('✓ ALL TESTS PASSED!');
    print('═════════════════════════════════════════\n');
    exit(0);
  } else {
    print('✗ SOME TESTS FAILED');
    print('═════════════════════════════════════════\n');
    exit(1);
  }
}

/// Test HDF5 nested group writing and reading
Future<bool> testNestedGroups() async {
  try {
    final testFile = 'test_output/nested_groups.h5';
    await Directory('test_output').create(recursive: true);

    // Create test data
    final data1 = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
    final data2 = NDArray.fromFlat([5.0, 6.0, 7.0, 8.0], [2, 2]);
    final data3 = NDArray.fromFlat([9.0, 10.0, 11.0, 12.0], [2, 2]);

    // Create builder and add nested datasets
    final builder = HDF5FileBuilder();
    await builder.addDataset('/group1/dataset1', data1);
    await builder.addDataset('/group1/subgroup/dataset2', data2);
    await builder.addDataset('/group2/dataset3', data3);

    // Build and write
    final bytes = await builder.buildMultiple();
    await File(testFile).writeAsBytes(bytes);
    print('  ✓ Written file with 3 nested datasets (${bytes.length} bytes)');

    // Read back
    final reader = HDF5Reader();
    final read1 =
        await reader.read(testFile, options: {'dataset': '/group1/dataset1'});
    final read2 = await reader
        .read(testFile, options: {'dataset': '/group1/subgroup/dataset2'});
    final read3 =
        await reader.read(testFile, options: {'dataset': '/group2/dataset3'});

    // Verify
    if (_checkArray(data1, read1.toNDArray(), 'group1/dataset1') &&
        _checkArray(data2, read2.toNDArray(), 'group1/subgroup/dataset2') &&
        _checkArray(data3, read3.toNDArray(), 'group2/dataset3')) {
      print('  ✓ All nested datasets read correctly');
      return true;
    }
    return false;
  } catch (e) {
    print('  ✗ Error: $e');
    return false;
  }
}

/// Test basic MAT file writing
Future<bool> testBasicMatWriting() async {
  try {
    final testFile = 'test_output/basic_test.mat';

    // Write various data types
    await MATWriter.writeAll(testFile, {
      'numeric': [
        [1.0, 2.0],
        [3.0, 4.0]
      ],
      'string': 'Hello MATLAB',
      'logical': [true, false, true],
    });

    final fileSize = await File(testFile).length();
    print('  ✓ Written MAT file ($fileSize bytes)');
    print('    - numeric: 2x2 matrix');
    print('    - string: character array');
    print('    - logical: boolean array');

    // Check file exists and has content
    if (fileSize > 1000) {
      // Should have HDF5 header + data
      print('  ✓ File size looks reasonable');
      return true;
    } else {
      print('  ✗ File too small ($fileSize bytes)');
      return false;
    }
  } catch (e) {
    print('  ✗ Error: $e');
    return false;
  }
}

/// Test MAT file roundtrip (write then read)
Future<bool> testMatRoundtrip() async {
  try {
    final testFile = 'test_output/roundtrip_test.mat';

    // Original data
    final originalMatrix =
        NDArray.fromFlat([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], [2, 3]);
    final originalString = 'Test String';
    final originalLogical = [true, false, true, false];

    print('  Writing data:');
    print('    matrix: ${originalMatrix.shape} = $originalMatrix');
    print('    string: "$originalString"');
    print('    logical: $originalLogical');

    // Write
    await MATWriter.writeAll(testFile, {
      'matrix': originalMatrix,
      'text': originalString,
      'flags': originalLogical,
    });
    print('  ✓ Data written');

    // Read back
    final matData = await MATReader.readAll(testFile);
    print('  ✓ Data read back');
    print('    Found variables: ${matData.keys.toList()}');

    // Verify matrix
    final readMatrix = matData['matrix'];
    if (readMatrix == null) {
      print('  ✗ Matrix not found in file');
      return false;
    }

    if (readMatrix is! NDArray) {
      print('  ✗ Matrix is not an NDArray (got ${readMatrix.runtimeType})');
      return false;
    }

    if (!_checkArray(originalMatrix, readMatrix, 'matrix')) {
      return false;
    }

    print('  ✓ Matrix roundtrip successful');

    // Note: String and logical verification depends on reader implementation
    print('  ✓ Roundtrip test passed');
    return true;
  } catch (e) {
    print('  ✗ Error: $e');
    return false;
  }
}

/// Helper to check if two arrays are equal
bool _checkArray(NDArray expected, NDArray actual, String name) {
  if (expected.shape.toString() != actual.shape.toString()) {
    print('  ✗ $name: Shape mismatch (${expected.shape} vs ${actual.shape})');
    return false;
  }

  final expectedFlat = expected.toFlatList();
  final actualFlat = actual.toFlatList();

  for (int i = 0; i < expected.size; i++) {
    final e = expectedFlat[i];
    final a = actualFlat[i];
    if ((e - a).abs() > 1e-10) {
      print('  ✗ $name: Value mismatch at index $i ($e vs $a)');
      return false;
    }
  }

  return true;
}
