# HDF5 Performance Benchmarking - Quick Start Guide

## Overview

This directory contains a comprehensive performance benchmarking suite for HDF5 file reading in DartFrame. The benchmarks measure read throughput, memory usage, and identify performance bottlenecks.

## Quick Start

### Run All Benchmarks

```bash
dart benchmark/hdf5_benchmark.dart
```

This will:
- Test file opening performance
- Measure dataset reading throughput
- Evaluate caching effectiveness
- Profile memory usage
- Generate a detailed report in `performance_report.txt`

### Run Memory Profiling

```bash
dart benchmark/hdf5_memory_benchmark.dart
```

This will:
- Profile memory usage for various operations
- Show execution times
- Display data size estimates

## Files

| File | Purpose |
|------|---------|
| `hdf5_benchmark.dart` | Main performance benchmark suite |
| `hdf5_memory_benchmark.dart` | Memory profiling tool |
| `HDF5_BENCHMARKING.md` | Detailed documentation |
| `HDF5_PERFORMANCE_RESULTS.md` | Latest benchmark results and analysis |
| `performance_report.txt` | Generated report (created after running benchmarks) |

## What Gets Measured

### Performance Metrics
- **Execution Time**: How long operations take
- **Throughput**: MB/s for dataset reading
- **Memory Usage**: Bytes consumed by operations
- **Cache Effectiveness**: Improvement from metadata caching

### Operations Tested
1. File opening and header parsing
2. Contiguous dataset reading
3. Chunked dataset reading (with B-tree navigation)
4. Compressed dataset reading (gzip, lzf)
5. String dataset reading
6. Compound dataset reading
7. Group navigation and traversal
8. Metadata caching
9. Attribute reading
10. File structure inspection

## Test Files Required

The benchmarks use these test files:
- `example/data/test_simple.h5` - Simple contiguous datasets
- `example/data/test_chunked.h5` - Chunked datasets
- `example/data/test_compressed.h5` - Compressed datasets
- `test/fixtures/string_test.h5` - String datasets
- `test/fixtures/compound_test.h5` - Compound datasets
- `example/data/test_attributes.h5` - Datasets with attributes
- `example/data/processdata.h5` - Real-world MATLAB file

## Interpreting Results

### Good Performance Indicators
- File opening < 100ms for files under 100MB ✓
- Dataset reading ≥ 50 MB/s ✓
- Memory usage ≤ 2x data size ✓
- Caching shows improvement on repeated access ✓

### Warning Signs
- Execution time increasing significantly with file size
- Memory usage growing faster than data size
- No improvement from caching
- Throughput < 50 MB/s for large datasets

## Current Results Summary

**Last Run**: November 14, 2025

- **Success Rate**: 94.1% (16/17 tests)
- **Average Execution Time**: 25.69ms
- **File Opening**: < 20ms for files < 15KB
- **Caching Improvement**: 10% faster on repeated access
- **Memory Efficiency**: ~1.1x data size (excellent)

See `HDF5_PERFORMANCE_RESULTS.md` for detailed analysis.

## Known Limitations

1. **Variable-length strings**: Not yet supported (1 test fails)
2. **Small test datasets**: Current datasets are < 1KB, limiting throughput measurements
3. **No large file tests**: Need datasets > 100MB for realistic throughput testing

## Next Steps

1. Create larger test datasets (1MB, 10MB, 100MB)
2. Implement variable-length string support
3. Add comparison benchmarks with Python h5py
4. Profile with real-world scientific datasets

## Troubleshooting

### Benchmarks Fail to Run
- Check that test files exist in expected locations
- Run `dart pub get` to ensure dependencies are installed
- Verify Dart SDK is properly installed

### Inconsistent Results
- Close other applications to reduce system load
- Run benchmarks multiple times and average results
- Ensure test files are on local disk (not network)

### Poor Performance
- Check system resources (CPU, memory, disk)
- Profile to identify specific bottlenecks
- Review recent code changes
- Compare with baseline results

## Contributing

When adding new benchmarks:
1. Follow the existing test pattern in `hdf5_benchmark.dart`
2. Extend `PerformanceTest` class
3. Add test to the runner in `main()`
4. Update documentation
5. Run and verify results

## References

- **Requirements**: `.kiro/specs/hdf5-full-support/requirements.md` (10.1-10.5)
- **Design**: `.kiro/specs/hdf5-full-support/design.md`
- **Implementation**: `lib/src/io/hdf5/`
- **Test Runner**: `benchmark/performance_test_runner.dart`

---

For detailed information, see `HDF5_BENCHMARKING.md`
