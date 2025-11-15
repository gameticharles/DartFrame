import 'package:dartframe/dartframe.dart';

/// Example demonstrating metadata caching and streaming features
Future<void> main() async {
  // Test with a sample HDF5 file
  // Use test_chunked.h5 as it has good data for demonstrating caching
  final testFile = 'example/data/test_chunked.h5';

  if (!FileIO().fileExistsSync(testFile)) {
    print('Test file not found: $testFile');
    print('Trying alternative file...');
    final altFile = 'example/data/test_simple.h5';
    if (FileIO().fileExistsSync(altFile)) {
      print('Using $altFile instead\n');
      return _runDemo(altFile);
    }
    print('No suitable test files found');
    return;
  }

  await _runDemo(testFile);
}

Future<void> _runDemo(String testFile) async {
  print('=== HDF5 Metadata Caching Demo ===\n');

  final file = await Hdf5File.open(testFile);

  try {
    // Show initial cache stats
    print('Initial cache stats:');
    print(file.cacheStats);
    print('');

    // Navigate through the file to populate cache
    print('Navigating file structure...');
    final structure = await file.listRecursive();
    print('Found ${structure.length} objects');
    print('');

    // Show cache stats after navigation
    print('Cache stats after navigation:');
    print(file.cacheStats);
    print('');

    // Access the same groups again (should use cache)
    print('Accessing groups again (should use cache)...');
    for (final path in structure.keys) {
      try {
        final type = await file.getObjectType(path);
        if (type == 'group') {
          await file.group(path);
        }
      } catch (e) {
        // Skip objects that can't be read (e.g., virtual datasets)
        print('  Skipping $path: ${e.toString().split('\n').first}');
      }
    }
    print('');

    // Show final cache stats
    print('Final cache stats:');
    print(file.cacheStats);
    print('');

    // Test streaming for datasets
    print('=== Dataset Streaming Demo ===\n');
    for (final entry in structure.entries) {
      if (entry.value['type'] == 'dataset') {
        final path = entry.key;
        final shape = entry.value['shape'] as List;
        final totalElements = shape.fold<int>(1, (a, b) => (a * (b as int)));

        print('Dataset: $path');
        print('  Shape: $shape');
        print('  Total elements: $totalElements');

        if (totalElements > 10) {
          // Test slicing
          print('  Testing slice...');
          try {
            // Create appropriate start/end for the dataset dimensions
            final start = List<int?>.filled(shape.length, 0);
            final end = List<int?>.filled(shape.length, null);
            // Limit first dimension to 5 elements
            end[0] = (shape[0] as int) < 5 ? shape[0] as int : 5;

            final slice = await file.readDatasetSlice(
              path,
              start: start,
              end: end,
            );
            print('  Slice result (first 5): ${slice.take(5).toList()}');
          } catch (e) {
            print('  Slice failed: $e');
          }

          // Test chunked reading
          print('  Testing chunked reading...');
          try {
            int chunkCount = 0;
            await for (final chunk
                in file.readDatasetChunked(path, chunkSize: 10)) {
              chunkCount++;
              if (chunkCount == 1) {
                print('  First chunk size: ${chunk.length}');
              }
            }
            print('  Total chunks read: $chunkCount');
          } catch (e) {
            print('  Chunked reading failed: $e');
          }
        } else {
          print('  Dataset too small for streaming demo');
        }
        print('');
      }
    }

    // Clear cache
    print('Clearing cache...');
    file.clearCache();
    print('Cache stats after clear:');
    print(file.cacheStats);
  } finally {
    await file.close();
  }

  print('\nDemo complete!');
}
