import 'package:dartframe/dartframe.dart';
import 'dart:io';

/// Example: Writing compressed chunked datasets
///
/// This example demonstrates how to write HDF5 files with chunked storage
/// and compression. Chunked storage is required for compression and provides
/// efficient access to subsets of large datasets.
Future<void> main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║     Writing Compressed Chunked Datasets Example           ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');

  // Example 1: GZIP compression with different levels
  print('Example 1: GZIP Compression Levels\n');

  final testData = NDArray.generate([500, 500], (i) => i[0] * 500 + i[1]);
  print('Test data: ${testData.shape} (${testData.size} elements)');
  print('Uncompressed size: ~${(testData.size * 8) / 1024} KB\n');

  // Level 1: Fastest compression
  print('Writing with GZIP level 1 (fastest)...');
  final stopwatch1 = Stopwatch()..start();
  await testData.toHDF5(
    'compressed_gzip_level1.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [100, 100],
      compression: CompressionType.gzip,
      compressionLevel: 1,
    ),
  );
  stopwatch1.stop();
  final size1 = File('compressed_gzip_level1.h5').lengthSync();
  print('✓ Time: ${stopwatch1.elapsedMilliseconds}ms');
  print('✓ File size: ${size1 / 1024} KB\n');

  // Level 6: Balanced (default)
  print('Writing with GZIP level 6 (balanced)...');
  final stopwatch6 = Stopwatch()..start();
  await testData.toHDF5(
    'compressed_gzip_level6.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [100, 100],
      compression: CompressionType.gzip,
      compressionLevel: 6,
    ),
  );
  stopwatch6.stop();
  final size6 = File('compressed_gzip_level6.h5').lengthSync();
  print('✓ Time: ${stopwatch6.elapsedMilliseconds}ms');
  print('✓ File size: ${size6 / 1024} KB\n');

  // Level 9: Best compression
  print('Writing with GZIP level 9 (best compression)...');
  final stopwatch9 = Stopwatch()..start();
  await testData.toHDF5(
    'compressed_gzip_level9.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [100, 100],
      compression: CompressionType.gzip,
      compressionLevel: 9,
    ),
  );
  stopwatch9.stop();
  final size9 = File('compressed_gzip_level9.h5').lengthSync();
  print('✓ Time: ${stopwatch9.elapsedMilliseconds}ms');
  print('✓ File size: ${size9 / 1024} KB\n');

  print('Compression comparison:');
  print('  Level 1: ${size1 / 1024} KB in ${stopwatch1.elapsedMilliseconds}ms');
  print('  Level 6: ${size6 / 1024} KB in ${stopwatch6.elapsedMilliseconds}ms');
  print('  Level 9: ${size9 / 1024} KB in ${stopwatch9.elapsedMilliseconds}ms');
  print('');

  // Example 2: LZF compression (faster alternative)
  print('Example 2: LZF Compression\n');

  print('Writing with LZF compression...');
  final stopwatchLzf = Stopwatch()..start();
  await testData.toHDF5(
    'compressed_lzf.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [100, 100],
      compression: CompressionType.lzf,
    ),
  );
  stopwatchLzf.stop();
  final sizeLzf = File('compressed_lzf.h5').lengthSync();
  print('✓ Time: ${stopwatchLzf.elapsedMilliseconds}ms');
  print('✓ File size: ${sizeLzf / 1024} KB\n');

  print('LZF vs GZIP comparison:');
  print(
      '  LZF:     ${sizeLzf / 1024} KB in ${stopwatchLzf.elapsedMilliseconds}ms');
  print('  GZIP-6:  ${size6 / 1024} KB in ${stopwatch6.elapsedMilliseconds}ms');
  print(
      '  Speed improvement: ${((stopwatch6.elapsedMilliseconds - stopwatchLzf.elapsedMilliseconds) / stopwatch6.elapsedMilliseconds * 100).toStringAsFixed(1)}%');
  print('');

  // Example 3: Different chunk sizes
  print('Example 3: Chunk Size Impact\n');

  // Small chunks (10x10)
  print('Writing with small chunks (10x10)...');
  final stopwatchSmall = Stopwatch()..start();
  await testData.toHDF5(
    'chunked_small.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [10, 10],
      compression: CompressionType.gzip,
      compressionLevel: 6,
    ),
  );
  stopwatchSmall.stop();
  final sizeSmall = File('chunked_small.h5').lengthSync();
  print('✓ Time: ${stopwatchSmall.elapsedMilliseconds}ms');
  print('✓ File size: ${sizeSmall / 1024} KB\n');

  // Medium chunks (100x100)
  print('Writing with medium chunks (100x100)...');
  final stopwatchMedium = Stopwatch()..start();
  await testData.toHDF5(
    'chunked_medium.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [100, 100],
      compression: CompressionType.gzip,
      compressionLevel: 6,
    ),
  );
  stopwatchMedium.stop();
  final sizeMedium = File('chunked_medium.h5').lengthSync();
  print('✓ Time: ${stopwatchMedium.elapsedMilliseconds}ms');
  print('✓ File size: ${sizeMedium / 1024} KB\n');

  // Large chunks (250x250)
  print('Writing with large chunks (250x250)...');
  final stopwatchLarge = Stopwatch()..start();
  await testData.toHDF5(
    'chunked_large.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [250, 250],
      compression: CompressionType.gzip,
      compressionLevel: 6,
    ),
  );
  stopwatchLarge.stop();
  final sizeLarge = File('chunked_large.h5').lengthSync();
  print('✓ Time: ${stopwatchLarge.elapsedMilliseconds}ms');
  print('✓ File size: ${sizeLarge / 1024} KB\n');

  print('Chunk size comparison:');
  print(
      '  10x10:   ${sizeSmall / 1024} KB in ${stopwatchSmall.elapsedMilliseconds}ms');
  print(
      '  100x100: ${sizeMedium / 1024} KB in ${stopwatchMedium.elapsedMilliseconds}ms');
  print(
      '  250x250: ${sizeLarge / 1024} KB in ${stopwatchLarge.elapsedMilliseconds}ms');
  print('');

  // Example 4: Auto-calculated chunk size
  print('Example 4: Auto-Calculated Chunk Size\n');

  print('Writing with auto-calculated chunks...');
  final stopwatchAuto = Stopwatch()..start();
  await testData.toHDF5(
    'chunked_auto.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      // chunkDimensions not specified - will be auto-calculated
      compression: CompressionType.gzip,
      compressionLevel: 6,
    ),
  );
  stopwatchAuto.stop();
  final sizeAuto = File('chunked_auto.h5').lengthSync();
  print('✓ Time: ${stopwatchAuto.elapsedMilliseconds}ms');
  print('✓ File size: ${sizeAuto / 1024} KB');
  print('✓ DartFrame automatically chose optimal chunk size\n');

  // Example 5: Large dataset with compression
  print('Example 5: Large Dataset\n');

  final largeData = NDArray.generate([2000, 2000], (i) => i[0] * 2000 + i[1]);
  print('Large data: ${largeData.shape} (${largeData.size} elements)');
  print('Uncompressed size: ~${(largeData.size * 8) / (1024 * 1024)} MB\n');

  print('Writing large dataset with compression...');
  final stopwatchLargeData = Stopwatch()..start();
  await largeData.toHDF5(
    'large_compressed.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [200, 200],
      compression: CompressionType.gzip,
      compressionLevel: 6,
      attributes: {
        'description': 'Large dataset example',
        'shape': '${largeData.shape}',
        'compression': 'gzip level 6',
      },
    ),
  );
  stopwatchLargeData.stop();
  final sizeLargeData = File('large_compressed.h5').lengthSync();
  print('✓ Time: ${stopwatchLargeData.elapsedMilliseconds}ms');
  print('✓ File size: ${sizeLargeData / (1024 * 1024)} MB');
  print(
      '✓ Compression ratio: ${((largeData.size * 8) / sizeLargeData).toStringAsFixed(2)}:1\n');

  // Python usage example
  print('═' * 60);
  print('Python Usage Examples:\n');
  print('# Read compressed dataset');
  print("import h5py");
  print("with h5py.File('compressed_gzip_level6.h5', 'r') as f:");
  print("    data = f['/data'][:]");
  print("    print(f'Shape: {data.shape}')");
  print("    print(f'Compression: {f['/data'].compression}')");
  print("    print(f'Compression opts: {f['/data'].compression_opts}')");
  print('');
  print('# Read subset of chunked dataset (efficient!)');
  print("with h5py.File('chunked_medium.h5', 'r') as f:");
  print("    # Only reads necessary chunks");
  print("    subset = f['/data'][0:100, 0:100]");
  print("    print(f'Subset shape: {subset.shape}')");
  print('');
  print('# Compare file sizes');
  print("import os");
  print(
      "for file in ['compressed_gzip_level1.h5', 'compressed_gzip_level6.h5', 'compressed_gzip_level9.h5']:");
  print("    size = os.path.getsize(file) / 1024");
  print("    print(f'{file}: {size:.2f} KB')");
  print('');

  print('═' * 60);
  print('Key Takeaways:\n');
  print('1. GZIP level 6 provides good balance of speed and compression');
  print('2. LZF is faster but compresses less than GZIP');
  print('3. Chunk size affects both performance and file size');
  print('4. Auto-calculated chunks work well for most cases');
  print('5. Compression is essential for large datasets');
  print('');
  print('✓ All examples completed successfully!');
}
