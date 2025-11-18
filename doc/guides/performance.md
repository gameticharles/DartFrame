# Performance Optimization Guide

## Overview

This guide covers best practices for optimizing performance when working with DartFrame, especially for large datasets.

## General Principles

### 1. Choose the Right Data Type

Using appropriate data types can significantly reduce memory usage and improve performance.

```dart
// Bad: Using float64 for integer data
final wasteful = NDArray([1, 2, 3, 4, 5], dtype: DType.float64);
// 40 bytes (8 bytes × 5)

// Good: Using int32 for integer data
final efficient = NDArray([1, 2, 3, 4, 5], dtype: DType.int32);
// 20 bytes (4 bytes × 5)
```

**Data Type Sizes:**
- `int8`: 1 byte (-128 to 127)
- `int16`: 2 bytes (-32,768 to 32,767)
- `int32`: 4 bytes (-2B to 2B)
- `int64`: 8 bytes (very large range)
- `float32`: 4 bytes (7 decimal digits precision)
- `float64`: 8 bytes (15 decimal digits precision)

### 2. Use Lazy Evaluation

Chain operations lazily to avoid creating intermediate arrays.

```dart
// Bad: Creates intermediate arrays
final step1 = array.map((x) => x * 2);
final step2 = step1.map((x) => x + 10);
final result = step2.where((x) => x > 20);

// Good: Single pass through data
final result = array.lazy()
  .map((x) => x * 2)
  .map((x) => x + 10)
  .filter((x) => x > 20)
  .compute();
```

### 3. Leverage Broadcasting

Broadcasting avoids explicit loops and creates more efficient operations.

```dart
// Bad: Manual element-wise operation
final result = NDArray.zeros(array.shape.toList());
for (int i = 0; i < array.size; i++) {
  result.data[i] = array.data[i] * 2 + 10;
}

// Good: Use broadcasting
final result = array * 2 + 10;
```

## Memory Management

### 1. Use Memory-Mapped Files for Large Data

For datasets larger than available RAM, use memory-mapped files.

```dart
// Create large array with memory mapping
final large = NDArray.zeros([100000, 10000]);
await large.save('large.bin', backend: 'mmap');

// Load without reading entire file into memory
final loaded = await NDArray.load('large.bin', backend: 'mmap');

// Operations work on disk-backed data
final result = loaded.slice([
  SliceRange(0, 1000),
  SliceRange(0, 1000),
]);
```

**When to use memory mapping:**
- Dataset size > 50% of available RAM
- Random access patterns
- Don't need to modify data frequently

### 2. Enable Compression

Compression reduces storage size and can improve I/O performance.

```dart
// Save with compression
await cube.save('data.h5', 
  compression: ZstdCodec(level: 3)
);

// Compression ratios (typical):
// - Zstd level 1: 2-3x, very fast
// - Zstd level 3: 3-5x, fast (recommended)
// - Zstd level 10: 4-6x, slower
```

**Compression trade-offs:**
- Higher compression = smaller files but slower I/O
- Level 3 is usually the sweet spot
- Use compression for cold storage
- Skip compression for frequently accessed data

### 3. Batch Operations

Process data in batches to control memory usage.

```dart
// Bad: Load entire dataset
final allData = await DataCube.load('huge.h5');
final result = allData.map((x) => expensiveOperation(x));

// Good: Process in batches
final batchSize = 100;
for (int i = 0; i < totalFrames; i += batchSize) {
  final batch = await loadFrames(i, i + batchSize);
  final processed = batch.map((x) => expensiveOperation(x));
  await saveResults(processed);
}
```

## Computational Performance

### 1. Vectorize Operations

Use array operations instead of loops.

```dart
// Bad: Explicit loop (slow)
final result = NDArray.zeros(array.shape.toList());
for (int i = 0; i < array.size; i++) {
  result.data[i] = array.data[i] * array.data[i] + 2 * array.data[i] + 1;
}

// Good: Vectorized (fast)
final result = array * array + array * 2 + 1;
```

### 2. Use Axis-Specific Operations

Specify axis for aggregations to avoid unnecessary computation.

```dart
// Bad: Compute full sum then extract
final allSums = array.sum();
// Then manually extract what you need

// Good: Sum along specific axis
final rowSums = array.sum(axis: 1);  // Only compute row sums
```

### 3. Avoid Unnecessary Copies

Use views and slices instead of copying data.

```dart
// Bad: Creates a copy
final subset = array.toList().sublist(0, 100);
final subArray = NDArray(subset);

// Good: Creates a view (no copy)
final subArray = array.slice([SliceRange(0, 100)]);
```

## I/O Performance

### 1. Choose the Right Format

Different formats have different performance characteristics.

```dart
// HDF5: Best for large numerical data
await cube.save('data.h5', format: 'hdf5');
// + Fast random access
// + Compression support
// + Metadata support
// - Requires HDF5 library

// Binary: Fastest for sequential access
await array.save('data.bin', format: 'binary');
// + Fastest I/O
// + Smallest overhead
// - No metadata
// - No compression

// CSV: Best for interoperability
await frame.toCSV('data.csv');
// + Human readable
// + Universal support
// - Slow for large data
// - No type information
```

### 2. Parallel I/O

Load multiple files in parallel.

```dart
// Sequential (slow)
final cubes = <DataCube>[];
for (final path in paths) {
  cubes.add(await DataCube.load(path));
}

// Parallel (fast)
final futures = paths.map((path) => DataCube.load(path));
final cubes = await Future.wait(futures);
```

### 3. Chunk Size Optimization

Adjust chunk sizes for your access patterns.

```dart
// For row-wise access
await cube.save('data.h5', 
  chunkSize: [1, 1000, 100]  // Optimize for reading full rows
);

// For column-wise access
await cube.save('data.h5',
  chunkSize: [100, 100, 1]  // Optimize for reading full columns
);
```

## Benchmarking

### Measure Performance

```dart
import 'dart:io';

void benchmark(String name, Function fn) {
  final sw = Stopwatch()..start();
  fn();
  sw.stop();
  print('$name: ${sw.elapsedMilliseconds}ms');
}

void main() {
  final array = NDArray.zeros([10000, 10000]);
  
  benchmark('Sum', () => array.sum());
  benchmark('Mean', () => array.mean());
  benchmark('Transpose', () => array.transpose());
}
```

### Profile Memory Usage

```dart
import 'dart:io';

void printMemoryUsage(String label) {
  final info = ProcessInfo.currentRss;
  print('$label: ${info ~/ 1024 ~/ 1024} MB');
}

void main() {
  printMemoryUsage('Start');
  
  final array = NDArray.zeros([10000, 10000]);
  printMemoryUsage('After allocation');
  
  final result = array * 2 + 10;
  printMemoryUsage('After computation');
}
```

## Performance Checklist

### Before Optimization
- [ ] Profile to find bottlenecks
- [ ] Measure current performance
- [ ] Set performance goals

### Data Type Optimization
- [ ] Use smallest appropriate dtype
- [ ] Consider int32 instead of int64
- [ ] Consider float32 instead of float64

### Memory Optimization
- [ ] Use memory mapping for large data
- [ ] Enable compression for storage
- [ ] Process data in batches
- [ ] Avoid unnecessary copies

### Computational Optimization
- [ ] Vectorize operations
- [ ] Use lazy evaluation
- [ ] Leverage broadcasting
- [ ] Specify axes in aggregations

### I/O Optimization
- [ ] Choose appropriate file format
- [ ] Use parallel I/O when possible
- [ ] Optimize chunk sizes
- [ ] Enable compression

## Common Performance Pitfalls

### 1. Creating Unnecessary Copies

```dart
// Bad: Multiple copies
final copy1 = array.toList();
final copy2 = NDArray(copy1);
final copy3 = copy2.reshape([...]);

// Good: Chain operations
final result = array.reshape([...]);
```

### 2. Not Using Vectorization

```dart
// Bad: Loop over elements
for (int i = 0; i < array.size; i++) {
  array.data[i] = array.data[i] * 2;
}

// Good: Vectorized operation
array = array * 2;
```

### 3. Loading Entire Dataset

```dart
// Bad: Load everything
final allData = await loadAllData();
final result = allData.slice([SliceRange(0, 100)]);

// Good: Load only what you need
final result = await loadSlice(0, 100);
```

### 4. Ignoring Data Types

```dart
// Bad: Default float64 for everything
final array = NDArray([1, 2, 3, 4, 5]);

// Good: Use appropriate type
final array = NDArray([1, 2, 3, 4, 5], dtype: DType.int32);
```

## Performance Targets

### Typical Performance (on modern hardware)

**Array Operations:**
- Element-wise operations: 1-10 GB/s
- Reductions (sum, mean): 5-20 GB/s
- Transpose: 2-8 GB/s

**I/O Performance:**
- HDF5 read: 500 MB/s - 2 GB/s
- HDF5 write: 300 MB/s - 1 GB/s
- Binary read: 1-4 GB/s
- Binary write: 800 MB/s - 3 GB/s

**Memory Usage:**
- Overhead per array: ~100 bytes
- Data storage: dtype size × number of elements

## See Also

- [NDArray Basics](ndarray_basics.md)
- [Large Datasets Guide](large_datasets.md)
- [API Reference](../api/ndarray.md)
