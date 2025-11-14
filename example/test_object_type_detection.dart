import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Test object type detection for HDF5 files
void main() async {
  print('=== Testing Object Type Detection ===\n');

  final files = [
    'example/data/test1.h5',
    'example/data/test_simple.h5',
    'example/data/processdata.h5',
  ];

  for (final filename in files) {
    final path = filename;
    final file = File(path);

    if (!file.existsSync()) {
      print('$filename: NOT FOUND\n');
      continue;
    }

    print('Testing file: $filename');
    try {
      final hdf5File = await Hdf5File.open(path);

      print('  Root children: ${hdf5File.root.children}');

      // Test object type detection for each child
      for (final child in hdf5File.root.children) {
        try {
          final objectType = await hdf5File.getObjectType('/$child');
          print('  - $child: $objectType');

          // Try to read if it's a dataset
          if (objectType == 'dataset') {
            try {
              final dataset = await hdf5File.dataset('/$child');
              print('    Shape: ${dataset.shape}');
            } catch (e) {
              print('    Error reading dataset: $e');
            }
          }
        } catch (e) {
          print('  - $child: Error - $e');
        }
      }

      await hdf5File.close();
      print('');
    } catch (e) {
      print('  Error opening file: $e\n');
    }
  }
}
