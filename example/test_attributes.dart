import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Test attribute reading functionality
///
/// This example demonstrates how to read attributes from HDF5 datasets.
/// Attributes are metadata attached to datasets or groups.
void main() async {
  print('Testing HDF5 Attribute Reading\n');
  print('=' * 50);

  // Test with a file that has attributes (if available)
  final testFiles = [
    'example/data/test_attributes.h5',
    'example/data/test1.h5',
    'example/data/processdata.h5',
    'example/data/test_chunked.h5',
  ];

  for (final filePath in testFiles) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('\nSkipping $filePath (file not found)');
      continue;
    }

    print('\n\nFile: $filePath');
    print('-' * 50);

    try {
      // Try to read attributes from the default dataset
      final attrs = await HDF5Reader.readAttributes(
        filePath,
        dataset: '/data',
        debug: false,
      );

      if (attrs.isEmpty) {
        print('No attributes found on /data dataset');
      } else {
        print('Attributes found:');
        attrs.forEach((name, value) {
          print('  $name: $value');
        });
      }
    } catch (e) {
      print('Error reading attributes: $e');

      // Try listing datasets to see what's available
      try {
        final datasets = await HDF5Reader.listDatasets(filePath);
        print('Available datasets: $datasets');

        // Try reading attributes from the first dataset
        if (datasets.isNotEmpty) {
          final firstDataset = '/${datasets.first}';
          print('\nTrying dataset: $firstDataset');

          final attrs = await HDF5Reader.readAttributes(
            filePath,
            dataset: firstDataset,
            debug: false,
          );

          if (attrs.isEmpty) {
            print('No attributes found');
          } else {
            print('Attributes:');
            attrs.forEach((name, value) {
              print('  $name: $value');
            });
          }
        }
      } catch (e2) {
        print('Error: $e2');
      }
    }
  }

  print('\n' + '=' * 50);
  print('Attribute reading test complete');
}
