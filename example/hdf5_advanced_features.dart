import 'package:dartframe/dartframe.dart';

/// HDF5 Advanced Features Examples
///
/// This example demonstrates advanced HDF5 reading capabilities:
/// - Reading compressed datasets
/// - Reading chunked datasets
/// - Handling large files efficiently
/// - Debug mode for troubleshooting
void main() async {
  print('=== DartFrame HDF5 Advanced Features Examples ===\n');

  // Example 1: Reading compressed datasets
  await example1CompressedData();

  // Example 2: Reading chunked datasets
  await example2ChunkedData();

  // Example 3: Using debug mode
  await example3DebugMode();

  // Example 4: MATLAB file compatibility
  await example4MatlabFiles();

  print('\n=== Examples Complete ===');
}

/// Example 1: Reading compressed datasets
///
/// Shows how to read datasets with gzip or lzf compression
Future<void> example1CompressedData() async {
  print('Example 1: Reading Compressed Datasets');
  print('-' * 50);

  final filePath = 'example/data/test_compressed.h5';

  if (!FileIO().fileExistsSync(filePath)) {
    print('Compressed test file not found: $filePath');
    print('Note: Create using create_compressed_hdf5.py\n');
    return;
  }

  try {
    // DartFrame automatically handles decompression
    print('Reading gzip-compressed dataset...');
    final df = await FileReader.readHDF5(
      filePath,
      dataset: '/gzip_1d',
    );

    print('Success! Decompression handled automatically.');
    print('Shape: ${df.shape}');
    print('First few values: ${df[0].data.take(5).toList()}');
    print('');

    // Try LZF compression if available
    try {
      print('Reading lzf-compressed dataset...');
      final dfLzf = await FileReader.readHDF5(
        filePath,
        dataset: '/lzf_1d',
      );
      print('Success! LZF decompression handled automatically.');
      print('Shape: ${dfLzf.shape}');
    } catch (e) {
      print('LZF dataset not available or not supported');
    }
  } catch (e) {
    print('Error: $e');
  }

  print('');
}

/// Example 2: Reading chunked datasets
///
/// Demonstrates reading datasets stored in chunks for efficient access
Future<void> example2ChunkedData() async {
  print('Example 2: Reading Chunked Datasets');
  print('-' * 50);

  final filePath = 'example/data/test_chunked.h5';

  if (!FileIO().fileExistsSync(filePath)) {
    print('Chunked test file not found: $filePath');
    print('Note: Create using create_chunked_hdf5.py\n');
    return;
  }

  try {
    // Read 1D chunked dataset
    print('Reading 1D chunked dataset...');
    final df1d = await FileReader.readHDF5(
      filePath,
      dataset: '/chunked_1d',
    );

    print('Success! Chunks assembled automatically.');
    print('Shape: ${df1d.shape}');
    print('First values: ${df1d[0].data.take(5).toList()}');
    print('Last values: ${df1d[0].data.skip(df1d.shape[0] - 5).toList()}');
    print('');

    // Read 2D chunked dataset
    print('Reading 2D chunked dataset...');
    final df2d = await FileReader.readHDF5(
      filePath,
      dataset: '/chunked_2d',
    );

    print('Success! 2D chunks assembled automatically.');
    print('Shape: ${df2d.shape}');
    print('Columns: ${df2d.columns}');
  } catch (e) {
    print('Error: $e');
  }

  print('');
}

/// Example 3: Using debug mode
///
/// Shows how to enable debug mode for troubleshooting
Future<void> example3DebugMode() async {
  print('Example 3: Using Debug Mode');
  print('-' * 50);

  print('Debug mode provides verbose logging for troubleshooting.');
  print('Enable it when you need to understand what\'s happening:\n');

  final filePath = 'example/data/test1.h5';

  if (!FileIO().fileExistsSync(filePath)) {
    print('Test file not found: $filePath\n');
    return;
  }

  try {
    // Enable debug mode for detailed logging
    print('Reading with debug mode enabled...');
    print('(Debug output will show file structure parsing)\n');

    final df = await FileReader.readHDF5(
      filePath,
      dataset: '/data',
      options: {'debug': true}, // Enable debug mode via options
    );

    print('\nSuccess! Shape: ${df.shape}');
    print('Debug mode helps diagnose issues with:');
    print('  - File format problems');
    print('  - Unsupported features');
    print('  - Data corruption');
    print('  - Performance bottlenecks');
  } catch (e) {
    print('Error: $e');
  }

  print('');
}

/// Example 4: MATLAB file compatibility
///
/// Demonstrates reading MATLAB v7.3 MAT-files (which are HDF5-based)
Future<void> example4MatlabFiles() async {
  print('Example 4: MATLAB File Compatibility');
  print('-' * 50);

  final filePath = 'example/data/processdata.h5';

  if (!FileIO().fileExistsSync(filePath)) {
    print('MATLAB test file not found: $filePath');
    print('');
    print('DartFrame can read MATLAB v7.3 MAT-files:');
    print('  - Automatically detects 512-byte offset');
    print('  - Handles MATLAB-specific structures');
    print('  - Reads variables as datasets');
    print('');
    print('Example usage:');
    print('```dart');
    print('// Read a MATLAB variable');
    print('final df = await FileReader.readHDF5(');
    print('  "data.mat",');
    print('  dataset: "/myVariable",');
    print(');');
    print('```');
  } else {
    try {
      // List datasets in MATLAB file
      print('Inspecting MATLAB file...');
      final datasets = await HDF5Reader.listDatasets(filePath);

      print('Available MATLAB variables: $datasets');
      print('');
      print('MATLAB v7.3 files are HDF5 files with:');
      print('  - 512-byte header offset (handled automatically)');
      print('  - Variables stored as datasets');
      print('  - Metadata in attributes');
    } catch (e) {
      print('Error: $e');
    }
  }

  print('');
}
