# HDF5 Caching and Streaming

This document describes the metadata caching and dataset streaming features in DartFrame's HDF5 reader.

## Metadata Caching

The HDF5 reader implements an LRU (Least Recently Used) cache for frequently accessed metadata to minimize file I/O operations and improve performance.

### What is Cached

- **Superblock**: The file's superblock (one per file)
- **Root Group**: The root group structure (one per file)
- **Groups**: Group structures accessed during navigation
- **Datatypes**: Datatype definitions (future enhancement)
- **Dataspaces**: Dataspace definitions (future enhancement)
- **B-tree Nodes**: B-tree nodes used for chunk indexing

### Cache Configuration

The cache has configurable size limits with default values:
- Groups: 100 entries
- Datatypes: 50 entries
- Dataspaces: 50 entries

When a cache reaches its limit, the least recently used entry is evicted.

### Using the Cache

The cache is automatically used when you navigate the file structure:

```dart
final file = await Hdf5File.open('data.h5');

// First access - reads from file
final group1 = await file.group('/experiment');

// Second access - uses cache
final group2 = await file.group('/experiment');

// Check cache statistics
print(file.cacheStats);
// Output: {superblock: cached, rootGroup: cached, groups: 1, ...}

// Clear cache if needed
file.clearCache();
```

### B-tree Node Caching

B-tree nodes used for chunk indexing are automatically cached to minimize file seeks during chunked dataset reading. This significantly improves performance when reading multiple chunks from the same dataset.

## Dataset Streaming

For large datasets that don't fit in memory, DartFrame provides streaming and slicing capabilities.

### Reading Dataset Slices

Read a subset of a dataset without loading the entire dataset:

```dart
final file = await Hdf5File.open('large_data.h5');

// Read rows 100-200 from a 2D dataset
final slice = await file.readDatasetSlice(
  '/measurements',
  start: [100, 0],
  end: [200, null], // null means to the end
);

// Read with step (every 2nd element)
final steppedSlice = await file.readDatasetSlice(
  '/data',
  start: [0, 0],
  end: [100, 50],
  step: [2, 1], // Every 2nd row, all columns
);
```

### Chunked Reading (Streaming)

Process large datasets incrementally using a stream:

```dart
final file = await Hdf5File.open('huge_data.h5');

// Process dataset in chunks of 10,000 elements
await for (final chunk in file.readDatasetChunked('/data', chunkSize: 10000)) {
  // Process each chunk
  print('Processing ${chunk.length} elements');
  
  // Calculate statistics, transform data, etc.
  final sum = chunk.fold<double>(0, (a, b) => a + (b as num).toDouble());
  print('Chunk sum: $sum');
}
```

### Direct Dataset API

You can also use the streaming API directly on Dataset objects:

```dart
final file = await Hdf5File.open('data.h5');
final dataset = await file.dataset('/measurements');

// Read a slice
final slice = await dataset.readSlice(
  ByteReader(file._raf),
  start: [0, 0],
  end: [10, 5],
);

// Stream chunks
await for (final chunk in dataset.readChunked(
  ByteReader(file._raf),
  chunkSize: 1000,
)) {
  // Process chunk
}
```

## Performance Benefits

### Caching Benefits

1. **Reduced File I/O**: Frequently accessed metadata is read once and cached
2. **Faster Navigation**: Repeated access to groups uses cached data
3. **Improved B-tree Performance**: Cached B-tree nodes reduce seeks during chunk reading

### Streaming Benefits

1. **Memory Efficiency**: Process large datasets without loading everything into memory
2. **Progressive Processing**: Start processing data before the entire dataset is read
3. **Flexible Chunk Sizes**: Adjust chunk size based on available memory and processing needs

## Example: Processing a Large Dataset

```dart
import 'dart:io';
import 'package:dartframe/dartframe.dart';

Future<void> processLargeDataset() async {
  final file = await Hdf5File.open('large_scientific_data.h5');
  
  try {
    // Check cache stats
    print('Initial cache: ${file.cacheStats}');
    
    // Process dataset in chunks
    double totalSum = 0;
    int totalElements = 0;
    
    await for (final chunk in file.readDatasetChunked(
      '/measurements',
      chunkSize: 100000,
    )) {
      // Process each chunk
      for (final value in chunk) {
        totalSum += (value as num).toDouble();
        totalElements++;
      }
      
      print('Processed $totalElements elements so far...');
    }
    
    final average = totalSum / totalElements;
    print('Average: $average');
    
    // Check cache stats after processing
    print('Final cache: ${file.cacheStats}');
    
  } finally {
    await file.close();
  }
}
```

## Best Practices

1. **Use Caching for Repeated Access**: If you need to access the same groups or datasets multiple times, the cache will automatically improve performance.

2. **Clear Cache When Done**: For long-running applications, clear the cache periodically to free memory:
   ```dart
   file.clearCache();
   ```

3. **Choose Appropriate Chunk Sizes**: For streaming, balance memory usage and I/O efficiency:
   - Smaller chunks (1,000-10,000): Lower memory usage, more I/O operations
   - Larger chunks (100,000-1,000,000): Higher memory usage, fewer I/O operations

4. **Use Slicing for Subsets**: If you only need part of a dataset, use slicing instead of reading the entire dataset:
   ```dart
   // Good: Read only what you need
   final subset = await file.readDatasetSlice('/data', start: [0], end: [1000]);
   
   // Avoid: Reading entire dataset when you only need part
   final allData = await file.readDataset('/data');
   final subset = allData.sublist(0, 1000);
   ```

5. **Monitor Cache Statistics**: Use `file.cacheStats` to understand cache usage and tune your application.

## Limitations

1. **Slice Optimization**: Currently, slicing reads the entire dataset and then slices it. Future versions will optimize this to read only the necessary chunks for chunked datasets.

2. **Multi-dimensional Streaming**: Streaming for multi-dimensional datasets currently processes row-by-row. More sophisticated streaming patterns may be added in the future.

3. **Cache Size**: Cache sizes are fixed at initialization. Dynamic cache sizing may be added in future versions.

## Future Enhancements

- Optimized slice reading for chunked datasets (read only necessary chunks)
- Configurable cache sizes
- Cache warming (pre-load frequently accessed metadata)
- Parallel chunk reading for improved performance
- More sophisticated streaming patterns for multi-dimensional data
