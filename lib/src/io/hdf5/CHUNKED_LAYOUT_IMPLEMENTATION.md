# Chunked Storage Layout Writer Implementation

## Overview

This document describes the implementation of chunked storage layout for HDF5 datasets in the dartframe library. Chunked storage divides datasets into fixed-size chunks for efficient partial I/O and compression support.

## Components Implemented

### 1. StorageLayoutWriter (Base Class)

**File**: `lib/src/io/hdf5/storage_layout_writer.dart`

Abstract base class for all storage layout writers. Defines the interface for:
- Writing layout messages for object headers
- Writing dataset data to files
- Identifying layout class (contiguous, chunked, compact)

### 2. ChunkedLayoutWriter

**File**: `lib/src/io/hdf5/chunked_layout_writer.dart`

Main implementation for chunked storage layout with the following features:

#### Key Features

1. **Chunk Dimension Validation**
   - Validates chunk dimensions against dataset dimensions
   - Ensures chunk dimensions don't exceed dataset dimensions
   - Checks dimension count matches

2. **Auto-Calculation of Optimal Chunk Dimensions**
   - Factory method `ChunkedLayoutWriter.auto()`
   - Targets ~1MB chunks for optimal performance
   - Maintains proportions relative to dataset shape
   - Algorithm: `targetElements = 1MB / elementSize`, then scale dimensions proportionally

3. **Memory-Efficient Chunk Processing**
   - Processes one chunk at a time
   - Extracts chunk data using recursive multi-dimensional iteration
   - Releases memory after each chunk is written
   - Memory usage: O(chunk_size) rather than O(dataset_size)

4. **Chunk Division and Writing**
   - Uses `ChunkCalculator` for coordinate calculations
   - Handles boundary chunks (partial chunks at dataset edges)
   - Writes chunks sequentially to file
   - Tracks chunk addresses and sizes for B-tree indexing

5. **B-tree Index Creation**
   - Creates B-tree v1 index for chunk lookup
   - Stores scaled coordinates (chunk_index * chunk_size)
   - Includes element size dimension (always 0)
   - Enables efficient random access to chunks

6. **Layout Message Generation**
   - HDF5 format version 3 layout message
   - Includes B-tree address, dimensionality, chunk dimensions
   - Must be called after `writeData()`

#### Data Structures

```dart
class WrittenChunkInfo {
  final List<int> chunkIndices;  // Position in chunk grid
  final int address;              // File offset
  final int size;                 // Chunk size in bytes
  final int filterMask;           // For compression filters
}
```

### 3. BTreeV1Writer

**File**: `lib/src/io/hdf5/btree_v1_writer.dart`

Writer for B-tree version 1 structures used for chunk indexing.

#### Features

1. **Chunk Index Creation**
   - Creates B-tree nodes for chunk lookup
   - Sorts entries by coordinates for proper ordering
   - Currently implements single leaf node (suitable for small-medium datasets)
   - TODO: Implement node splitting for very large datasets

2. **Entry Format**
   - Chunk size (4 bytes)
   - Filter mask (4 bytes)
   - Chunk coordinates (8 bytes each, scaled)
   - Chunk address (configurable offset size: 2, 4, or 8 bytes)

3. **Node Structure**
   - Signature: "TREE"
   - Node type: 1 (chunked raw data B-tree)
   - Node level: 0 (leaf node)
   - Entries used count
   - Left/right sibling addresses (undefined for single node)

#### Data Structures

```dart
class BTreeV1ChunkEntry {
  final int chunkSize;
  final int filterMask;
  final List<int> chunkCoordinates;  // Scaled coordinates
  final int chunkAddress;
}
```

## Usage Examples

### Basic Usage with Explicit Chunk Dimensions

```dart
// Create 2D array
final array = NDArray.fromFlat(
  List.generate(10000, (i) => i.toDouble()),
  [100, 100],
);

// Create chunked layout writer
final writer = ChunkedLayoutWriter(
  chunkDimensions: [10, 10],
  datasetDimensions: [100, 100],
);

// Write data
final byteWriter = ByteWriter();
final btreeAddress = await writer.writeData(byteWriter, array);

// Get layout message for object header
final layoutMessage = writer.writeLayoutMessage();
```

### Auto-Calculated Chunk Dimensions

```dart
// Let the writer calculate optimal chunk dimensions
final writer = ChunkedLayoutWriter.auto(
  datasetDimensions: [1000, 1000],
  elementSize: 8,  // float64
);

// Chunk dimensions are automatically calculated to target ~1MB chunks
print('Auto-calculated chunks: ${writer.chunkDimensions}');
```

### Handling Non-Uniform Datasets

```dart
// Dataset size not evenly divisible by chunk size
final array = NDArray.fromFlat(
  List.generate(47, (i) => i.toDouble()),
  [47],
);

final writer = ChunkedLayoutWriter(
  chunkDimensions: [10],
  datasetDimensions: [47],
);

// Automatically handles boundary chunks (last chunk will be size 7)
await writer.writeData(byteWriter, array);
```

## Integration with HDF5FileBuilder

The chunked layout writer is designed to integrate with the existing `HDF5FileBuilder` class. Future integration will involve:

1. Adding a `WriteOptions` parameter to specify chunked vs contiguous layout
2. Using `ChunkedLayoutWriter` when chunked layout is requested
3. Updating the data layout message in the dataset object header
4. Supporting compression filters in the chunk pipeline

## Performance Characteristics

### Memory Usage

- **Contiguous Layout**: O(dataset_size) - entire dataset in memory
- **Chunked Layout**: O(chunk_size) - one chunk at a time
- **Overhead**: ~10MB for B-tree structures and metadata

### Write Performance

- **Sequential Write**: Similar to contiguous for small datasets
- **Large Datasets**: Better memory efficiency, slightly slower due to B-tree overhead
- **Optimal Chunk Size**: ~1MB provides good balance

### Chunk Size Guidelines

- **Too Small**: High B-tree overhead, many file seeks
- **Too Large**: High memory usage, poor partial I/O performance
- **Recommended**: 1MB target (auto-calculated by default)

## Testing

Comprehensive test suite in `test/io/chunked_layout_writer_test.dart`:

- ✅ Chunk dimension validation
- ✅ Auto-calculation of chunk dimensions
- ✅ 1D and 2D array writing
- ✅ Boundary chunk handling
- ✅ Integer and float data types
- ✅ Layout message generation
- ✅ Error handling

All tests passing.

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **Requirement 6.1**: Chunked storage divides datasets into fixed-size chunks ✅
- **Requirement 6.2**: Validates chunk dimensions don't exceed dataset dimensions ✅
- **Requirement 6.6**: Auto-calculates optimal chunk dimensions when not specified ✅
- **Requirement 11.2**: Memory-efficient chunk extraction (one chunk at a time) ✅

## Future Enhancements

1. **B-tree Node Splitting**: Implement proper B-tree splitting for very large datasets (>1000 chunks)
2. **Compression Integration**: Add filter pipeline support for chunk compression
3. **B-tree v2 Support**: Implement B-tree v2 for HDF5 format version 2+
4. **Parallel Chunk Writing**: Process multiple chunks concurrently for better performance
5. **Chunk Caching**: Cache frequently accessed chunks during write operations

## Related Files

- `lib/src/io/hdf5/chunk_calculator.dart` - Chunk coordinate calculations
- `lib/src/io/hdf5/data_layout_message_writer.dart` - Contiguous layout writer
- `lib/src/io/hdf5/btree_v1.dart` - B-tree v1 reader (for testing round-trips)
- `lib/src/io/hdf5/hdf5_file_builder.dart` - Main file builder (integration point)

## References

- HDF5 File Format Specification 3.2: Data Layout Message
- HDF5 File Format Specification 3.1: B-tree v1 Format
- HDF5 User Guide: Chunking in HDF5
