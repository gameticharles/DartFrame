import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Example demonstrating DataFrame column-wise storage in HDF5
///
/// This example shows how to write a DataFrame to HDF5 using the column-wise
/// storage strategy, where each column is stored as a separate dataset within
/// a group.
///
/// The column-wise strategy is particularly efficient for:
/// - Column-oriented access patterns
/// - Large DataFrames
/// - Mixed datatype columns
/// - Compatibility with pandas column-wise storage
void main() async {
  print('DataFrame Column-wise Writer Example\n');
  print('=' * 50);

  // Create a sample DataFrame with numeric datatypes
  // Note: String and boolean datatypes require task 3 to be completed
  final df = DataFrame([
    [1, 101, 25.5, 50000.0, 2.5],
    [2, 102, 30.0, 60000.0, 3.0],
    [3, 103, 35.5, 70000.0, 5.5],
    [4, 104, 28.0, 55000.0, 1.5],
    [5, 105, 32.5, 65000.0, 4.0],
  ], columns: [
    'id',
    'employee_code',
    'age',
    'salary',
    'years_experience'
  ]);

  print('\nOriginal DataFrame:');
  print(df);

  // Example 1: Write DataFrame with column-wise storage
  print('\n\nExample 1: Basic Column-wise Storage');
  print('-' * 50);

  final builder1 = HDF5FileBuilder();
  final writer1 = DataFrameColumnWriter();

  await writer1.write(builder1, '/employees', df);
  final bytes1 = await builder1.finalize();

  final file1 = File('example_columnwise.h5');
  await file1.writeAsBytes(bytes1);

  print('✓ Written DataFrame to example_columnwise.h5');
  print('  Group: /employees');
  print('  Datasets:');
  print('    - /employees/id (integer column)');
  print('    - /employees/employee_code (integer column)');
  print('    - /employees/age (float column)');
  print('    - /employees/salary (float column)');
  print('    - /employees/years_experience (float column)');
  print('  File size: ${bytes1.length} bytes');

  // Example 2: Write multiple DataFrames to different groups
  print('\n\nExample 2: Multiple DataFrames in One File');
  print('-' * 50);

  final df2 = DataFrame([
    [101, 1001, 29.99],
    [102, 1002, 49.99],
    [103, 1003, 19.99],
  ], columns: [
    'product_id',
    'category_code',
    'price'
  ]);

  final builder2 = HDF5FileBuilder();
  final writer2 = DataFrameColumnWriter();

  // Write first DataFrame
  await writer2.write(builder2, '/employees', df);

  // Write second DataFrame
  await writer2.write(builder2, '/products', df2);

  final bytes2 = await builder2.finalize();
  final file2 = File('example_multi_columnwise.h5');
  await file2.writeAsBytes(bytes2);

  print('✓ Written multiple DataFrames to example_multi_columnwise.h5');
  print('  Groups:');
  print('    - /employees (5 rows, 5 numeric columns)');
  print('    - /products (3 rows, 3 numeric columns)');
  print('  File size: ${bytes2.length} bytes');

  // Example 3: Write with compression (requires chunked storage)
  print('\n\nExample 3: Column-wise Storage with Compression');
  print('-' * 50);

  final builder3 = HDF5FileBuilder();
  final writer3 = DataFrameColumnWriter();

  // Create write options with compression
  final options = WriteOptions(
    layout: StorageLayout.chunked,
    chunkDimensions: [2], // Chunk size for 1D column arrays
    compression: CompressionType.gzip,
    compressionLevel: 6,
  );

  await writer3.write(builder3, '/employees', df, options: options);
  final bytes3 = await builder3.finalize();

  final file3 = File('example_compressed_columnwise.h5');
  await file3.writeAsBytes(bytes3);

  print('✓ Written compressed DataFrame to example_compressed_columnwise.h5');
  print('  Compression: gzip (level 6)');
  print('  Chunk size: [2]');
  print('  File size: ${bytes3.length} bytes');
  print(
      '  Compression ratio: ${(bytes1.length / bytes3.length).toStringAsFixed(2)}x');

  // Example 4: Numeric-only DataFrame
  print('\n\nExample 4: Numeric-only DataFrame');
  print('-' * 50);

  final numericDf = DataFrame([
    [1.0, 2.0, 3.0, 4.0],
    [5.0, 6.0, 7.0, 8.0],
    [9.0, 10.0, 11.0, 12.0],
  ], columns: [
    'col1',
    'col2',
    'col3',
    'col4'
  ]);

  final builder4 = HDF5FileBuilder();
  final writer4 = DataFrameColumnWriter();

  await writer4.write(builder4, '/numeric_data', numericDf);
  final bytes4 = await builder4.finalize();

  final file4 = File('example_numeric_columnwise.h5');
  await file4.writeAsBytes(bytes4);

  print('✓ Written numeric DataFrame to example_numeric_columnwise.h5');
  print('  All columns stored as float64 datasets');
  print('  File size: ${bytes4.length} bytes');

  // Summary
  print('\n\n' + '=' * 50);
  print('Summary');
  print('=' * 50);
  print('\nColumn-wise storage benefits:');
  print('  ✓ Each column is a separate dataset');
  print('  ✓ Efficient for column-oriented access');
  print('  ✓ Handles mixed datatypes naturally');
  print('  ✓ Compatible with pandas column-wise format');
  print('  ✓ Supports compression per column');
  print('\nFiles created:');
  print('  - example_columnwise.h5');
  print('  - example_multi_columnwise.h5');
  print('  - example_compressed_columnwise.h5');
  print('  - example_numeric_columnwise.h5');
  print('\nYou can read these files with:');
  print('  - Python: pandas.read_hdf() or h5py');
  print('  - MATLAB: h5read()');
  print('  - R: rhdf5 package');
  print('  - dartframe: HDF5Reader (coming soon)');
}
