/// Example demonstrating HDF5 writer for NDArray with chunking and compression
///
/// This example shows how to write N-dimensional arrays to HDF5 files with:
/// - Contiguous and chunked storage layouts
/// - GZIP and LZF compression
/// - Attribute preservation
/// - Memory-efficient writing of large datasets
/// - C-contiguous (row-major) layout for MATLAB/Python compatibility
library;

import 'dart:io';
import 'package:dartframe/dartframe.dart';

void main() async {
  print('=== HDF5 NDArray Writer Examples ===\n');

  // Create output directory
  final outputDir = Directory('test_output/hdf5_examples');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // Example 1: Basic contiguous storage
  await example1ContiguousStorage(outputDir);

  // Example 2: Chunked storage
  await example2ChunkedStorage(outputDir);

  // Example 3: GZIP compression
  await example3GzipCompression(outputDir);

  // Example 4: LZF compression
  await example4LzfCompression(outputDir);

  // Example 5: Auto-calculated chunk dimensions
  await example5AutoChunking(outputDir);

  // Example 6: Attribute preservation
  await example6AttributePreservation(outputDir);

  // Example 7: Large dataset with memory-efficient writing
  await example7LargeDataset(outputDir);

  // Example 8: Multiple datasets in one file
  await example8MultipleDatasets(outputDir);

  // Example 9: Different datatypes
  await example9Datatypes(outputDir);

  print('\n=== All examples completed successfully! ===');
  print('Output files written to: ${outputDir.path}');
}

/// Example 1: Basic contiguous storage
Future<void> example1ContiguousStorage(Directory outputDir) async {
  print('Example 1: Contiguous Storage');
  print('------------------------------');

  // Create a 2D array
  final array = NDArray.generate([10, 20], (indices) {
    return indices[0] * 20 + indices[1];
  });

  final filePath = '${outputDir.path}/contiguous.h5';

  // Write with default contiguous storage
  await array.toHDF5(
    filePath,
    dataset: '/data',
    attributes: {
      'description': 'Contiguous storage example',
      'storage_type': 'contiguous',
    },
  );

  print('✓ Written 10x20 array with contiguous storage');
  print('  File: $filePath');
  print('  Size: ${File(filePath).lengthSync()} bytes\n');
}

/// Example 2: Chunked storage
Future<void> example2ChunkedStorage(Directory outputDir) async {
  print('Example 2: Chunked Storage');
  print('---------------------------');

  // Create a 3D array
  final array = NDArray.generate([20, 30, 40], (indices) {
    return (indices[0] * 1200 + indices[1] * 40 + indices[2]).toDouble();
  });

  final filePath = '${outputDir.path}/chunked.h5';

  // Write with explicit chunk dimensions
  await array.toHDF5(
    filePath,
    dataset: '/measurements',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [10, 10, 10],
      attributes: {
        'description': 'Chunked storage example',
        'chunk_size': '10x10x10',
      },
    ),
  );

  print('✓ Written 20x30x40 array with chunked storage');
  print('  Chunk dimensions: 10x10x10');
  print('  File: $filePath');
  print('  Size: ${File(filePath).lengthSync()} bytes\n');
}

/// Example 3: GZIP compression
Future<void> example3GzipCompression(Directory outputDir) async {
  print('Example 3: GZIP Compression');
  print('----------------------------');

  // Create a 2D array with some redundancy (compresses well)
  final array = NDArray.generate([100, 200], (indices) {
    // Create a pattern that compresses well
    return ((indices[0] ~/ 10) * 20 + (indices[1] ~/ 10)).toDouble();
  });

  final filePath = '${outputDir.path}/gzip_compressed.h5';

  // Write with GZIP compression
  await array.toHDF5(
    filePath,
    dataset: '/compressed_data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [50, 50],
      compression: CompressionType.gzip,
      compressionLevel: 6,
      attributes: {
        'description': 'GZIP compressed data',
        'compression': 'gzip',
        'compression_level': 6,
      },
    ),
  );

  print('✓ Written 100x200 array with GZIP compression (level 6)');
  print('  File: $filePath');
  print('  Size: ${File(filePath).lengthSync()} bytes\n');
}

/// Example 4: LZF compression
Future<void> example4LzfCompression(Directory outputDir) async {
  print('Example 4: LZF Compression');
  print('---------------------------');

  // Create a 2D array
  final array = NDArray.generate([80, 120], (indices) {
    return (indices[0] + indices[1]).toDouble();
  });

  final filePath = '${outputDir.path}/lzf_compressed.h5';

  // Write with LZF compression (faster than GZIP)
  await array.toHDF5(
    filePath,
    dataset: '/fast_compressed',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [40, 40],
      compression: CompressionType.lzf,
      attributes: {
        'description': 'LZF compressed data (fast)',
        'compression': 'lzf',
      },
    ),
  );

  print('✓ Written 80x120 array with LZF compression');
  print('  File: $filePath');
  print('  Size: ${File(filePath).lengthSync()} bytes\n');
}

/// Example 5: Auto-calculated chunk dimensions
Future<void> example5AutoChunking(Directory outputDir) async {
  print('Example 5: Auto-Calculated Chunks');
  print('----------------------------------');

  // Create a large array
  final array = NDArray.generate([200, 300], (indices) {
    return indices[0] * 300 + indices[1];
  });

  final filePath = '${outputDir.path}/auto_chunked.h5';

  // Write with auto-calculated chunks (aims for ~1MB chunks)
  await array.toHDF5(
    filePath,
    dataset: '/auto_chunked_data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      compression: CompressionType.gzip,
      compressionLevel: 4,
      attributes: {
        'description': 'Auto-calculated chunk dimensions',
        'note': 'Chunks optimized for ~1MB size',
      },
    ),
  );

  print('✓ Written 200x300 array with auto-calculated chunks');
  print('  File: $filePath');
  print('  Size: ${File(filePath).lengthSync()} bytes\n');
}

/// Example 6: Attribute preservation
Future<void> example6AttributePreservation(Directory outputDir) async {
  print('Example 6: Attribute Preservation');
  print('----------------------------------');

  // Create an array with attributes
  final array = NDArray.zeros([15, 25]);
  array.attrs['units'] = 'meters';
  array.attrs['description'] = 'Temperature measurements';
  array.attrs['sensor_id'] = 'TEMP-001';
  array.attrs['calibration_date'] = '2024-01-15';
  array.attrs['version'] = 2;

  final filePath = '${outputDir.path}/with_attributes.h5';

  // Attributes are automatically preserved
  await array.toHDF5(
    filePath,
    dataset: '/temperature',
  );

  print('✓ Written 15x25 array with preserved attributes:');
  print('  - units: ${array.attrs['units']}');
  print('  - description: ${array.attrs['description']}');
  print('  - sensor_id: ${array.attrs['sensor_id']}');
  print('  - calibration_date: ${array.attrs['calibration_date']}');
  print('  - version: ${array.attrs['version']}');
  print('  File: $filePath\n');
}

/// Example 7: Large dataset with memory-efficient writing
Future<void> example7LargeDataset(Directory outputDir) async {
  print('Example 7: Large Dataset (Memory-Efficient)');
  print('--------------------------------------------');

  // Create a larger 3D array
  final array = NDArray.generate([50, 100, 80], (indices) {
    return (indices[0] * 8000 + indices[1] * 80 + indices[2]).toDouble();
  });

  final filePath = '${outputDir.path}/large_dataset.h5';

  print('Creating large dataset (50x100x80 = 400,000 elements)...');

  // Write with chunking and compression for efficiency
  await array.toHDF5(
    filePath,
    dataset: '/large_data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      compression: CompressionType.gzip,
      compressionLevel: 4,
      attributes: {
        'description': 'Large dataset example',
        'total_elements': 400000,
      },
    ),
  );

  print('✓ Written 50x100x80 array (400,000 elements)');
  print('  File: $filePath');
  print('  Size: ${File(filePath).lengthSync()} bytes\n');
}

/// Example 8: Multiple datasets in one file
Future<void> example8MultipleDatasets(Directory outputDir) async {
  print('Example 8: Multiple Datasets');
  print('-----------------------------');

  // Create multiple arrays
  final temperature = NDArray.generate([10, 10], (i) => (i[0] + i[1]) * 2.5);
  final pressure = NDArray.generate([10, 10], (i) => (i[0] * 10 + i[1]) * 0.1);
  final humidity = NDArray.generate([10, 10], (i) => 50.0 + i[0] + i[1]);

  final filePath = '${outputDir.path}/multiple_datasets.h5';

  // Write all datasets to one file
  await HDF5WriterUtils.writeMultiple(
    filePath,
    {
      '/temperature': temperature,
      '/pressure': pressure,
      '/humidity': humidity,
    },
    defaultOptions: WriteOptions(
      layout: StorageLayout.chunked,
      compression: CompressionType.gzip,
      compressionLevel: 5,
    ),
  );

  print('✓ Written 3 datasets to single file:');
  print('  - /temperature (10x10)');
  print('  - /pressure (10x10)');
  print('  - /humidity (10x10)');
  print('  File: $filePath');
  print('  Size: ${File(filePath).lengthSync()} bytes\n');
}

/// Example 9: Different datatypes
Future<void> example9Datatypes(Directory outputDir) async {
  print('Example 9: Different Datatypes');
  print('-------------------------------');

  // Integer array
  final intArray = NDArray.generate([5, 5], (i) => i[0] * 5 + i[1]);

  // Float array
  final floatArray = NDArray.generate([5, 5], (i) => (i[0] * 5 + i[1]) * 1.5);

  final filePath = '${outputDir.path}/datatypes.h5';

  await HDF5WriterUtils.writeMultiple(
    filePath,
    {
      '/int_data': intArray,
      '/float_data': floatArray,
    },
  );

  print('✓ Written arrays with different datatypes:');
  print('  - /int_data: int64 (5x5)');
  print('  - /float_data: float64 (5x5)');
  print('  File: $filePath');
  print('  Size: ${File(filePath).lengthSync()} bytes\n');
}
