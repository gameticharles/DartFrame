import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Basic HDF5 Reading Examples
///
/// This example demonstrates the fundamental operations for reading HDF5 files
/// with DartFrame, including:
/// - Opening and reading datasets
/// - Converting to DataFrames
/// - Handling different data types
/// - Error handling
void main() async {
  print('=== DartFrame HDF5 Basic Reading Examples ===\n');

  // Example 1: Reading a simple dataset
  await example1BasicReading();

  // Example 2: Reading with error handling
  await example2ErrorHandling();

  // Example 3: Reading different data types
  await example3DataTypes();

  print('\n=== Examples Complete ===');
}

/// Example 1: Basic dataset reading
///
/// Shows how to read a dataset from an HDF5 file and convert it to a DataFrame
Future<void> example1BasicReading() async {
  print('Example 1: Basic Dataset Reading');
  print('-' * 50);

  try {
    // Read a dataset from an HDF5 file
    // The dataset parameter specifies the path to the dataset within the file
    final df = await FileReader.readHDF5(
      'example/data/test1.h5',
      dataset: '/data', // Path to dataset in HDF5 file
    );

    print('Successfully read dataset!');
    print('Shape: ${df.shape}'); // (rows, columns)
    print('Columns: ${df.columns}');
    print('\nFirst few rows:');
    print(df.head(5));
  } catch (e) {
    print('Error: $e');
  }

  print('');
}

/// Example 2: Error handling
///
/// Demonstrates proper error handling when reading HDF5 files
Future<void> example2ErrorHandling() async {
  print('Example 2: Error Handling');
  print('-' * 50);

  // Try to read a non-existent file
  try {
    await FileReader.readHDF5(
      'nonexistent.h5',
      dataset: '/data',
    );
  } catch (e) {
    print('Caught expected error for missing file:');
    print('  ${e.runtimeType}: ${e.toString().split('\n').first}');
  }

  // Try to read a non-existent dataset
  try {
    await FileReader.readHDF5(
      'example/data/test1.h5',
      dataset: '/nonexistent',
    );
  } catch (e) {
    print('\nCaught expected error for missing dataset:');
    print('  ${e.runtimeType}: ${e.toString().split('\n').first}');
  }

  print('');
}

/// Example 3: Reading different data types
///
/// Shows how DartFrame handles various HDF5 data types
Future<void> example3DataTypes() async {
  print('Example 3: Different Data Types');
  print('-' * 50);

  final testCases = [
    ('Integer data', 'example/data/test1.h5', '/data'),
    ('Float data', 'example/data/test_chunked.h5', '/chunked_1d'),
  ];

  for (final testCase in testCases) {
    final (description, filePath, dataset) = testCase;

    if (!File(filePath).existsSync()) {
      print('$description: File not found, skipping');
      continue;
    }

    try {
      final df = await FileReader.readHDF5(filePath, dataset: dataset);
      print('$description:');
      print('  Shape: ${df.shape}');
      print('  Data type: ${df[0].dtype}');
      print('  Sample values: ${df[0].data.take(3).toList()}');
    } catch (e) {
      print('$description: Error - ${e.toString().split('\n').first}');
    }
  }

  print('');
}
