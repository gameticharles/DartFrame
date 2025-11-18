import 'package:dartframe/dartframe.dart';
import 'package:dartframe/src/io/hdf5/byte_writer.dart';

/// Example demonstrating HDF5 compression filters
///
/// This example shows how to use the compression filter system with
/// chunked storage layouts to reduce file sizes.
void main() async {
  print('=== HDF5 Compression Filter Example ===\n');

  // Create sample data - repetitive data compresses well
  final data = List.generate(10000, (i) => (i % 100).toDouble());
  final array = NDArray.fromFlat(data, [100, 100]);

  print('Dataset shape: ${array.shape}');
  print('Dataset size: ${data.length} elements\n');

  // Example 1: Gzip compression with different levels
  print('--- Gzip Compression ---');

  for (final level in [1, 6, 9]) {
    final pipeline = FilterPipeline(filters: [
      GzipFilter(compressionLevel: level),
    ]);

    final writer = ChunkedLayoutWriter(
      chunkDimensions: [25, 25],
      datasetDimensions: [100, 100],
      filterPipeline: pipeline,
    );

    final byteWriter = ByteWriter();
    await writer.writeData(byteWriter, array);

    print('Gzip level $level: ${byteWriter.size} bytes');
  }

  // Example 2: LZF compression (faster, moderate compression)
  print('\n--- LZF Compression ---');

  final lzfPipeline = FilterPipeline(filters: [
    LzfFilter(),
  ]);

  final lzfWriter = ChunkedLayoutWriter(
    chunkDimensions: [25, 25],
    datasetDimensions: [100, 100],
    filterPipeline: lzfPipeline,
  );

  final lzfByteWriter = ByteWriter();
  await lzfWriter.writeData(lzfByteWriter, array);

  print('LZF compression: ${lzfByteWriter.size} bytes');

  // Example 3: No compression (baseline)
  print('\n--- No Compression (Baseline) ---');

  final noCompWriter = ChunkedLayoutWriter(
    chunkDimensions: [25, 25],
    datasetDimensions: [100, 100],
  );

  final noCompByteWriter = ByteWriter();
  await noCompWriter.writeData(noCompByteWriter, array);

  print('No compression: ${noCompByteWriter.size} bytes');

  // Example 4: Filter pipeline message
  print('\n--- Filter Pipeline Message ---');

  final pipeline = FilterPipeline(filters: [
    GzipFilter(compressionLevel: 6),
  ]);

  final message = pipeline.writeMessage();
  print('Pipeline message size: ${message.length} bytes');
  print('Message version: ${message[0]}');
  print('Number of filters: ${message[1]}');

  // Example 5: Auto-calculated chunks with compression
  print('\n--- Auto-Calculated Chunks with Compression ---');

  final autoWriter = ChunkedLayoutWriter.auto(
    datasetDimensions: [100, 100],
    elementSize: 8, // float64
    filterPipeline: FilterPipeline(filters: [
      GzipFilter(compressionLevel: 6),
    ]),
  );

  print('Auto-calculated chunk dimensions: ${autoWriter.chunkDimensions}');

  final autoByteWriter = ByteWriter();
  await autoWriter.writeData(autoByteWriter, array);

  print('Compressed size: ${autoByteWriter.size} bytes');

  print('\n=== Example Complete ===');
}
