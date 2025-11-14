import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// HDF5 Group Navigation Examples
///
/// This example demonstrates how to navigate HDF5 file hierarchies:
/// - Inspecting file structure
/// - Listing datasets and groups
/// - Accessing nested datasets
/// - Understanding file organization
void main() async {
  print('=== DartFrame HDF5 Group Navigation Examples ===\n');

  // Example 1: Inspecting file structure
  await example1InspectFile();

  // Example 2: Listing datasets
  await example2ListDatasets();

  // Example 3: Reading nested datasets
  await example3NestedDatasets();

  print('\n=== Examples Complete ===');
}

/// Example 1: Inspecting HDF5 file structure
///
/// Shows how to get information about an HDF5 file without reading all data
Future<void> example1InspectFile() async {
  print('Example 1: Inspecting File Structure');
  print('-' * 50);

  final filePath = 'example/data/test1.h5';

  if (!File(filePath).existsSync()) {
    print('File not found: $filePath\n');
    return;
  }

  try {
    // Inspect the file to see its structure
    final info = await HDF5Reader.inspect(filePath);

    print('File: $filePath');
    print('HDF5 Version: ${info['version']}');
    print('Root children: ${info['rootChildren']}');
    print('Available datasets: ${info['datasets']}');
  } catch (e) {
    print('Error inspecting file: $e');
  }

  print('');
}

/// Example 2: Listing all datasets
///
/// Demonstrates how to list all datasets in an HDF5 file
Future<void> example2ListDatasets() async {
  print('Example 2: Listing Datasets');
  print('-' * 50);

  final testFiles = [
    'example/data/test1.h5',
    'example/data/test_chunked.h5',
    'example/data/test_compressed.h5',
  ];

  for (final filePath in testFiles) {
    if (!File(filePath).existsSync()) {
      print('$filePath: Not found');
      continue;
    }

    try {
      // List all datasets in the file
      final datasets = await HDF5Reader.listDatasets(filePath);

      print('\n$filePath:');
      if (datasets.isEmpty) {
        print('  No datasets found');
      } else {
        print('  Datasets (${datasets.length}):');
        for (final dataset in datasets) {
          print('    - $dataset');
        }
      }
    } catch (e) {
      print('$filePath: Error - $e');
    }
  }

  print('');
}

/// Example 3: Reading nested datasets
///
/// Shows how to access datasets in nested group structures
Future<void> example3NestedDatasets() async {
  print('Example 3: Reading Nested Datasets');
  print('-' * 50);

  // Example of reading datasets at different paths
  final testCases = [
    ('Root level dataset', 'example/data/test1.h5', '/data'),
    ('Nested dataset', 'example/data/test_chunked.h5', '/chunked_1d'),
  ];

  for (final testCase in testCases) {
    final (description, filePath, datasetPath) = testCase;

    if (!File(filePath).existsSync()) {
      print('$description: File not found');
      continue;
    }

    try {
      print('\n$description:');
      print('  File: $filePath');
      print('  Dataset path: $datasetPath');

      final df = await FileReader.readHDF5(filePath, dataset: datasetPath);

      print('  Shape: ${df.shape}');
      print('  First value: ${df[0].data.first}');
    } catch (e) {
      print('  Error: ${e.toString().split('\n').first}');
    }
  }

  print('');
}
