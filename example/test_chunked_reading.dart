import 'dart:io';
import 'package:dartframe/dartframe.dart';

void main() async {
  // Enable debug mode
  setHdf5DebugMode(true);

  print('Testing chunked dataset reading...\n');

  final file = 'example/data/test_chunked.h5';
  if (!File(file).existsSync()) {
    print('Error: $file not found. Run create_chunked_hdf5.py first.');
    exit(1);
  }

  try {
    // Test 1D chunked dataset
    print('=== Test 1: 1D Chunked Dataset ===');
    final hdf5File = await Hdf5File.open(file);
    final dataset1d = await hdf5File.dataset('/chunked_1d');
    print('Dataset shape: ${dataset1d.shape}');
    print('Dataset dtype: ${dataset1d.datatype}');

    final data1d =
        await dataset1d.readData(ByteReader(await File(file).open()));
    print('Data length: ${data1d.length}');
    print('First 10 elements: ${data1d.take(10).toList()}');
    print('Last 10 elements: ${data1d.skip(data1d.length - 10).toList()}');

    // Verify data
    bool correct1d = true;
    for (int i = 0; i < data1d.length; i++) {
      if ((data1d[i] as num).toDouble() != i.toDouble()) {
        print('ERROR: Element $i is ${data1d[i]}, expected $i');
        correct1d = false;
        break;
      }
    }
    print('Data verification: ${correct1d ? "PASSED ✓" : "FAILED ✗"}\n');

    // Test 2D chunked dataset
    print('=== Test 2: 2D Chunked Dataset ===');
    final dataset2d = await hdf5File.dataset('/chunked_2d');
    print('Dataset shape: ${dataset2d.shape}');
    print('Dataset dtype: ${dataset2d.datatype}');

    final data2d =
        await dataset2d.readData(ByteReader(await File(file).open()));
    print('Data length: ${data2d.length}');
    print('First 10 elements: ${data2d.take(10).toList()}');

    // Verify data (should be 0-59)
    bool correct2d = true;
    for (int i = 0; i < data2d.length; i++) {
      if (data2d[i] != i) {
        print('ERROR: Element $i is ${data2d[i]}, expected $i');
        correct2d = false;
        break;
      }
    }
    print('Data verification: ${correct2d ? "PASSED ✓" : "FAILED ✗"}\n');

    // Test larger 2D chunked dataset
    print('=== Test 3: Larger 2D Chunked Dataset ===');
    final datasetLarge = await hdf5File.dataset('/chunked_large');
    print('Dataset shape: ${datasetLarge.shape}');
    print('Dataset dtype: ${datasetLarge.datatype}');

    final dataLarge =
        await datasetLarge.readData(ByteReader(await File(file).open()));
    print('Data length: ${dataLarge.length}');
    print('First 10 elements: ${dataLarge.take(10).toList()}');

    // Verify data (should be 0-99)
    bool correctLarge = true;
    for (int i = 0; i < dataLarge.length; i++) {
      if ((dataLarge[i] as num).toDouble() != i.toDouble()) {
        print('ERROR: Element $i is ${dataLarge[i]}, expected $i');
        correctLarge = false;
        break;
      }
    }
    print('Data verification: ${correctLarge ? "PASSED ✓" : "FAILED ✗"}\n');

    await hdf5File.close();

    print('=== Summary ===');
    print('All tests completed!');
    if (correct1d && correct2d && correctLarge) {
      print('✓ All chunked datasets read correctly!');
    } else {
      print('✗ Some tests failed');
      exit(1);
    }
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
