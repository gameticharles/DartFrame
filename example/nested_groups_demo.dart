/// Nested Group HDF5 Write/Read Test
///
/// This demo creates an HDF5 file with nested groups, writes it,
/// then reads it back using the universal reader to verify.
///
/// Run with: dart run example/nested_groups_demo.dart

import 'dart:io';
import 'package:dartframe/dartframe.dart';

void main() async {
  print('╔════════════════════════════════════════════════════╗');
  print('║  HDF5 Nested Groups - Write & Read Verification   ║');
  print('╚════════════════════════════════════════════════════╝\n');

  final testFile = 'test_output/nested_groups_demo.h5';

  // Ensure output directory exists
  await Directory('test_output').create(recursive: true);

  // ======== STEP 1: Write nested groups ========
  print('Step 1: Writing HDF5 file with nested groups...');
  print('─────────────────────────────────────────────────────');

  try {
    final builder = HDF5FileBuilder();

    // Create test data
    final data1 = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
    final data2 = NDArray.fromFlat([5.0, 6.0, 7.0, 8.0], [2, 2]);
    final data3 = NDArray.fromFlat([9.0, 10.0, 11.0, 12.0], [2, 2]);
    final data4 = NDArray.fromFlat([13.0, 14.0, 15.0, 16.0], [2, 2]);

    print('  Adding datasets to nested structure:');
    print('    /group1/dataset1');
    print('    /group1/subgroup/dataset2');
    print('    /group1/subgroup/deep/dataset3');
    print('    /group2/dataset4');

    // Add datasets in nested groups
    await builder.addDataset('/group1/dataset1', data1);
    await builder.addDataset('/group1/subgroup/dataset2', data2);
    await builder.addDataset('/group1/subgroup/deep/dataset3', data3);
    await builder.addDataset('/group2/dataset4', data4);

    // Build the file
    final bytes = await builder.finalize();

    // Write to disk
    await File(testFile).writeAsBytes(bytes);

    print('\n  ✓ File written: $testFile');
    print('  ✓ File size: ${bytes.length} bytes');
    print('  ✓ Datasets: 4');
    print('  ✓ Groups created: 5 (root, group1, group2, subgroup, deep)');
  } catch (e, stack) {
    print('  ✗ FAILED to write file:');
    print('    Error: $e');
    print('    Stack: $stack');
    exit(1);
  }

  print('');

  // ======== STEP 2: Read and verify using HDF5Reader ========
  print('Step 2: Reading and verifying with HDF5Reader...');
  print('─────────────────────────────────────────────────────────');

  try {
    final reader = HDF5Reader();

    print('  Reading datasets:');

    // Read each dataset
    final df1 =
        await reader.read(testFile, options: {'dataset': '/group1/dataset1'});
    final data1 = df1.toNDArray();
    print('    ✓ /group1/dataset1: shape=${data1.shape}');

    final df2 = await reader
        .read(testFile, options: {'dataset': '/group1/subgroup/dataset2'});
    final data2 = df2.toNDArray();
    print('    ✓ /group1/subgroup/dataset2: shape=${data2.shape}');

    final df3 = await reader
        .read(testFile, options: {'dataset': '/group1/subgroup/deep/dataset3'});
    final data3 = df3.toNDArray();
    print('    ✓ /group1/subgroup/deep/dataset3: shape=${data3.shape}');

    final df4 =
        await reader.read(testFile, options: {'dataset': '/group2/dataset4'});
    final data4 = df4.toNDArray();
    print('    ✓ /group2/dataset4: shape=${data4.shape}');

    print('\n  Data verification:');

    // Verify data integrity
    final original1 = [1.0, 2.0, 3.0, 4.0];
    bool match1 = true;
    for (int i = 0; i < 4; i++) {
      if (data1[i] != original1[i]) {
        match1 = false;
        break;
      }
    }

    if (match1) {
      print('    ✓ dataset1: Data matches [${original1.join(', ')}]');
    } else {
      print('    ✗ dataset1: Data mismatch!');
    }

    final original2 = [5.0, 6.0, 7.0, 8.0];
    bool match2 = true;
    for (int i = 0; i < 4; i++) {
      if (data2[i] != original2[i]) {
        match2 = false;
        break;
      }
    }

    if (match2) {
      print('    ✓ dataset2: Data matches [${original2.join(', ')}]');
    } else {
      print('    ✗ dataset2: Data mismatch!');
    }

    final original3 = [9.0, 10.0, 11.0, 12.0];
    bool match3 = true;
    for (int i = 0; i < 4; i++) {
      if (data3[i] != original3[i]) {
        match3 = false;
        break;
      }
    }

    if (match3) {
      print('    ✓ dataset3: Data matches [${original3.join(', ')}]');
    } else {
      print('    ✗ dataset3: Data mismatch!');
    }

    if (match1 && match2 && match3) {
      print('\n╔══════════════════════════════════════════════════╗');
      print('║              ✓ ALL TESTS PASSED!                  ║');
      print('║   Nested group writing and reading works!         ║');
      print('╚═══════════════════════════════════════════════════╝');
      print('\nTo see full file structure, run:');
      print('  dart run example/hdf5_universal_reader.dart $testFile\n');
      exit(0);
    } else {
      print('\n✗ Some data verification failed');
      exit(1);
    }
  } catch (e, stack) {
    print('  ✗ FAILED to read file:');
    print('    Error: $e');
    print('    Stack: $stack');
    exit(1);
  }
}
