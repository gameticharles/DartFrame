# HDF5 Performance Benchmarking

This document describes the HDF5 performance benchmarking suite for DartFrame.

## Overview

The HDF5 benchmarking suite measures the performance of various HDF5 reading operations to ensure the implementation meets performance requirements and to identify optimization opportunities.

## Benchmark Files

### 1. `hdf5_benchmark.dart`

Comprehensive performance benchmark suite that measures:

- **File Opening**: Time to open and parse HDF5 file headers
- **Contiguous Dataset Reading**: Performance of reading datasets with contiguous storage
- **Chunked Dataset Reading**: Performance of reading chunked datasets with B-tree navigation
- **Compressed Dataset Reading**: Performance of reading and decompressing compressed datasets
- **String Dataset Reading**: Performance of reading string datasets
- **Compound Dataset Reading**: Performance of reading compound (struct) datasets
- **Group Navigation**: Performance of navigating through group hierarchies
- **Metadata Caching**: Effectiveness of metadata caching
- **Attribute Reading**: Performance of reading attributes
- **File Inspection**: Performance of inspecting file structure without reading data

### 2. `hdf5_memory_benchmark.dart`

Memory profiling tool that measures:

- Memory usage for file opening
- Memory usage for dataset reading
- Memory usage for recursive listing
- Memory efficiency of caching

## Running the Benchmarks

### Prerequisites

1. Ensure Dart SDK is installed
2. Run `dart pub get` to fetch dependencies
3. Ensure test HDF5 files exist in the expected locations

### Running Performance Benchmarks

```bash
dart benchmark/hdf5_benchmark.dart
```

This will:
- Run all available HDF5 performance tests
- Generate detailed performance metrics
- Save results to `benchmark/performance_report.txt`

### Running Memory Profiling

```bash
dart benchmark/hdf5_memory_benchmark.dart
```

This will:
- Profile memory usage for various HDF5 operations
- Display memory consumption estimates
- Show execution times for each operation

## Test Files

The benchmarks use the following test files:

- `example/data/test_simple.h5` - Simple contiguous datasets
- `example/data/test_chunked.h5` - Chunked datasets
- `example/data/test_compressed.h5` - Compressed datasets
- `test/fixtures/string_test.h5` - String datasets
- `test/fixtures/compound_test.h5` - Compound datasets
- `example/data/test_attributes.h5` - Datasets with attributes
- `example/data/processdata.h5` - Real-world MATLAB file

## Performance Metrics

### Key Metrics Measured

1. **Execution Time (ms)**: Time to complete the operation
2. **Throughput (MB/s)**: Data read rate for dataset operations
3. **Memory Usage (bytes)**: Estimated memory consumption
4. **Elements Read**: Number of data elements processed
5. **Cache Hit Ratio**: Effectiveness of metadata caching

### Performance Requirements

Based on the requirements document (10.1-10.5):

- **File Opening**: Should complete within 100ms for files under 100MB
- **Dataset Reading**: Should achieve at least 50MB/s throughput
- **Memory Usage**: Should not exceed 2x the dataset size being read
- **Caching**: Should show improved performance on repeated access

## Interpreting Results

### Execution Time

Lower execution times indicate better performance. Compare times across:
- Different file types (contiguous vs chunked vs compressed)
- Different data types (numeric vs string vs compound)
- Different file sizes

### Throughput

Higher throughput (MB/s) indicates better read performance. Expected ranges:
- Contiguous datasets: 100-500 MB/s
- Chunked datasets: 50-200 MB/s
- Compressed datasets: 20-100 MB/s (depends on compression ratio)

### Memory Usage

Memory usage should be proportional to data size. Watch for:
- Memory leaks (increasing usage over iterations)
- Excessive overhead (memory >> data size)
- Caching efficiency (stable memory with repeated access)

### Caching Performance

Caching effectiveness is measured by comparing:
- First access time vs subsequent access times
- Average time per access over multiple iterations
- Memory stability across iterations

Expected improvements:
- 50-90% reduction in access time for cached metadata
- Stable memory usage across iterations

## Bottleneck Identification

### Common Bottlenecks

1. **File I/O**: Excessive seeks or small reads
   - Solution: Batch reads, optimize seek patterns

2. **B-tree Navigation**: Slow chunk lookup
   - Solution: Cache B-tree nodes, optimize traversal

3. **Decompression**: CPU-bound decompression
   - Solution: Optimize decompression algorithms, consider parallel processing

4. **Memory Allocation**: Frequent allocations
   - Solution: Pre-allocate buffers, reuse objects

5. **Type Conversion**: Slow byte-to-type conversion
   - Solution: Use typed data views, optimize conversion loops

### Profiling Tools

Use Dart's built-in profiling tools for deeper analysis:

```bash
# CPU profiling
dart --observe benchmark/hdf5_benchmark.dart

# Memory profiling
dart --observe --pause-isolates-on-start benchmark/hdf5_memory_benchmark.dart
```

Then connect to the Observatory URL to analyze:
- CPU hotspots
- Memory allocation patterns
- Garbage collection behavior

## Optimization Strategies

### 1. I/O Optimization

- Minimize file seeks
- Read contiguous blocks when possible
- Use buffered I/O for small reads
- Reuse file handles

### 2. Caching Optimization

- Cache frequently accessed metadata
- Implement LRU eviction policy
- Set appropriate cache size limits
- Cache B-tree nodes

### 3. Memory Optimization

- Use typed data (Uint8List, Float64List, etc.)
- Avoid unnecessary copies
- Stream large datasets
- Release resources promptly

### 4. Algorithm Optimization

- Optimize B-tree traversal
- Batch chunk reads
- Parallelize independent operations
- Use efficient data structures

## Benchmark Results Format

The benchmark runner generates a report with:

```
=== PERFORMANCE TEST RESULTS ===

Summary:
- Total tests: 15
- Successful: 15
- Failed: 0
- Success rate: 100.0%

Successful Tests:
HDF5 File Open (10.5 KB):
  Execution time: 5ms
  File size: 10752 bytes

HDF5 Contiguous Read (/dataset, 100 elements):
  Execution time: 3ms
  Elements read: 100
  Data size: 800 bytes
  Throughput: 256.00 MB/s

Performance Analysis:
Execution Times:
  Average: 12.50ms
  Median: 8ms
  Min: 3ms
  Max: 45ms
```

## Continuous Monitoring

### Regression Testing

Run benchmarks regularly to detect performance regressions:

```bash
# Run benchmarks and save results
dart benchmark/hdf5_benchmark.dart > results_$(date +%Y%m%d).txt

# Compare with baseline
diff results_baseline.txt results_$(date +%Y%m%d).txt
```

### Performance Tracking

Track key metrics over time:
- File opening time
- Dataset read throughput
- Memory usage
- Cache hit ratio

Set up alerts for:
- Execution time increases > 20%
- Throughput decreases > 20%
- Memory usage increases > 50%

## Troubleshooting

### Slow Performance

1. Check file location (local vs network)
2. Verify file is not corrupted
3. Check system resources (CPU, memory, disk)
4. Profile to identify bottlenecks
5. Review recent code changes

### High Memory Usage

1. Check for memory leaks
2. Verify proper resource cleanup
3. Review caching strategy
4. Consider streaming for large datasets
5. Profile memory allocation patterns

### Inconsistent Results

1. Run multiple iterations
2. Warm up the JIT compiler
3. Close other applications
4. Use consistent test data
5. Check for background processes

## Future Enhancements

Potential benchmark improvements:

1. **Parallel Processing**: Benchmark parallel chunk reading
2. **Large Files**: Test with files > 1GB
3. **Network I/O**: Test with remote files
4. **Comparison**: Compare with other HDF5 libraries
5. **Automated Regression**: CI/CD integration
6. **Visualization**: Generate performance graphs
7. **Stress Testing**: Test with extreme conditions

## References

- Requirements: `.kiro/specs/hdf5-full-support/requirements.md` (10.1-10.5)
- Design: `.kiro/specs/hdf5-full-support/design.md`
- Performance Test Runner: `benchmark/performance_test_runner.dart`
