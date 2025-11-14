import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Test comprehensive error diagnostics
Future<void> main() async {
  print('Testing HDF5 Error Diagnostics\n');
  print('=' * 60);

  // Test 1: File not found
  print('\n1. Testing FileAccessError (file not found):');
  print('-' * 60);
  try {
    await Hdf5File.open('nonexistent_file.h5');
  } catch (e) {
    print(e);
  }

  // Test 2: Invalid HDF5 file
  print('\n2. Testing InvalidHdf5SignatureError:');
  print('-' * 60);
  final tempFile = File('temp_invalid.h5');
  await tempFile.writeAsBytes([1, 2, 3, 4, 5, 6, 7, 8]);
  try {
    await Hdf5File.open('temp_invalid.h5');
  } catch (e) {
    print(e);
  } finally {
    await tempFile.delete();
  }

  // Test 3: Dataset not found (using a real file if available)
  print('\n3. Testing DatasetNotFoundError:');
  print('-' * 60);
  final testFiles = [
    'example/data/test1.h5',
    'example/data/test_simple.h5',
    'example/data/processdata.h5',
  ];

  String? validFile;
  for (final file in testFiles) {
    if (await File(file).exists()) {
      validFile = file;
      break;
    }
  }

  if (validFile != null) {
    try {
      final file = await Hdf5File.open(validFile);
      await file.dataset('/nonexistent_dataset');
      await file.close();
    } catch (e) {
      print(e);
    }
  } else {
    print('No test HDF5 file available for this test');
  }

  // Test 4: Path not found
  print('\n4. Testing PathNotFoundError:');
  print('-' * 60);
  if (validFile != null) {
    try {
      final file = await Hdf5File.open(validFile);
      await file.getObjectType('/nonexistent/path/to/object');
      await file.close();
    } catch (e) {
      print(e);
    }
  } else {
    print('No test HDF5 file available for this test');
  }

  // Test 5: Debug mode
  print('\n5. Testing Debug Mode:');
  print('-' * 60);
  if (validFile != null) {
    print('Enabling debug mode...\n');
    HDF5Reader.setDebugMode(true);
    try {
      final file = await Hdf5File.open(validFile);
      final info = file.info;
      print('\nFile info: $info');
      await file.close();
    } catch (e) {
      print('Error: $e');
    } finally {
      HDF5Reader.setDebugMode(false);
    }
  } else {
    print('No test HDF5 file available for this test');
  }

  // Test 6: Not a dataset error
  print('\n6. Testing NotADatasetError (root group):');
  print('-' * 60);
  if (validFile != null) {
    try {
      final file = await Hdf5File.open(validFile);
      await file.dataset('/');
      await file.close();
    } catch (e) {
      print(e);
    }
  } else {
    print('No test HDF5 file available for this test');
  }

  print('\n' + '=' * 60);
  print('Error diagnostics testing complete!');
}
