// ignore_for_file: unused_local_variable

import 'package:dartframe/dartframe.dart';

/// Example demonstrating DataFrame compound writer functionality
///
/// This example shows how to use the DataFrameCompoundWriter to convert
/// a DataFrame into HDF5 compound datatype format, which stores each row
/// as a struct-like record.
void main() {
  print('DataFrame Compound Writer Example\n');
  print('=' * 50);

  // Example 1: Simple DataFrame with mixed types
  print('\n1. Simple DataFrame with mixed types:');
  final df1 = DataFrame([
    [1, 'Alice', 25.5, true],
    [2, 'Bob', 30.0, false],
    [3, 'Charlie', 35.5, true],
  ], columns: [
    'id',
    'name',
    'age',
    'active'
  ]);

  print(df1);

  final writer = DataFrameCompoundWriter();
  final result1 = writer.createCompoundDataset(df1);

  print('\nCompound Dataset Info:');
  print('  Column names: ${result1['columnNames']}');
  print('  Shape: ${result1['shape']}');
  print('  Record size: ${result1['recordSize']} bytes');
  print('  Number of records: ${(result1['recordBytes'] as List).length}');

  // Example 2: Get detailed field information
  print('\n2. Field Information:');
  final fieldInfo = writer.getFieldInfo(df1);
  print('  Total compound size: ${fieldInfo['totalSize']} bytes');
  print('  Fields:');
  for (final field in fieldInfo['fields']) {
    print('    - ${field['name']}: ${field['type']} '
        '(size=${field['size']}, offset=${field['offset']})');
  }

  // Example 3: DataFrame with null values
  print('\n3. DataFrame with null values:');
  final df2 = DataFrame([
    [1, 'Alice', 25.5],
    [2, null, 30.0],
    [3, 'Charlie', null],
  ], columns: [
    'id',
    'name',
    'age'
  ]);

  print(df2);

  final result2 = writer.createCompoundDataset(df2);
  print('\nHandled null values successfully!');
  print('  Record size: ${result2['recordSize']} bytes');

  // Example 4: Integer-only DataFrame
  print('\n4. Integer-only DataFrame:');
  final df3 = DataFrame([
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12],
  ], columns: [
    'a',
    'b',
    'c',
    'd'
  ]);

  final result3 = writer.createCompoundDataset(df3);
  final fieldInfo3 = writer.getFieldInfo(df3);

  print('  All fields are int64:');
  for (final field in fieldInfo3['fields']) {
    print('    - ${field['name']}: ${field['type']}');
  }

  // Example 5: String-only DataFrame
  print('\n5. String-only DataFrame:');
  final df4 = DataFrame([
    ['Alice', 'Engineer', 'NYC'],
    ['Bob', 'Designer', 'LA'],
    ['Charlie', 'Manager', 'SF'],
  ], columns: [
    'name',
    'job',
    'city'
  ]);

  final result4 = writer.createCompoundDataset(df4);
  final fieldInfo4 = writer.getFieldInfo(df4);

  print('  All fields are fixed-length strings:');
  for (final field in fieldInfo4['fields']) {
    print('    - ${field['name']}: ${field['type']} (size=${field['size']})');
  }

  // Example 6: Boolean DataFrame
  print('\n6. Boolean DataFrame:');
  final df5 = DataFrame([
    [true, false, true],
    [false, true, false],
    [true, true, false],
  ], columns: [
    'flag1',
    'flag2',
    'flag3'
  ]);

  final result5 = writer.createCompoundDataset(df5);
  final fieldInfo5 = writer.getFieldInfo(df5);

  print('  All fields are boolean (8-bit enum):');
  for (final field in fieldInfo5['fields']) {
    print('    - ${field['name']}: ${field['type']} (size=${field['size']})');
  }

  print('\n${'=' * 50}');
  print('Example completed successfully!');
  print('\nKey Features Demonstrated:');
  print('  ✓ Mixed datatype columns (int, string, float, bool)');
  print('  ✓ Null value handling');
  print('  ✓ Automatic datatype inference');
  print('  ✓ Field offset calculation and alignment');
  print('  ✓ Compound record encoding');
  print('\nThe compound datatype approach:');
  print('  - Stores data row-by-row as struct-like records');
  print('  - Each column becomes a field in the compound type');
  print('  - Efficient for row-oriented access patterns');
  print('  - Compatible with pandas and h5py');
}
