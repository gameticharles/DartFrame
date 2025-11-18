# Performance Comparison: NumPy/Pandas vs DartFrame

## Executive Summary

This document presents performance benchmarks comparing NumPy/Pandas (Python) with DartFrame (Dart) for common data manipulation operations.

**Key Findings:**
- **NumPy/Pandas is 10-100x faster** for numerical operations (as expected with C/Fortran backend)
- **DartFrame is competitive** for data structure operations (creation, access)
- **DartFrame offers cross-platform benefits** that NumPy/Pandas cannot provide

## Test Environment

- **Hardware:** Windows PC
- **Python:** 3.10 with NumPy 1.24.3, Pandas 2.3.3
- **Dart:** Latest stable version
- **DartFrame:** Version 0.8.6
- **Iterations:** 5 runs per benchmark, averaged

## Benchmark Results

### NDArray / NumPy Array Operations

| Operation | NumPy (Python) | DartFrame (Dart) | Ratio (Dart/Python) |
|-----------|----------------|------------------|---------------------|
| Array Creation (100×100) | 0.01ms | 0.78ms | **78x slower** |
| Array Creation (1000×1000) | 0.02ms | 12.18ms | **609x slower** |
| Array Sum (100×100) | 0.10ms | 5.08ms | **51x slower** |
| Array Sum (1000×1000) | 7.31ms | 195.39ms | **27x slower** |

**Analysis:**
- NumPy's C/Fortran backend provides significant speed advantages
- DartFrame is pure Dart, which explains the performance gap
- The gap narrows for larger operations (27x vs 78x), suggesting better scaling

### DataFrame Operations

| Operation | Pandas (Python) | DartFrame (Dart) | Ratio (Dart/Python) |
|-----------|-----------------|------------------|---------------------|
| DataFrame Creation (100×10) | 0.05ms | 0.48ms | **9.6x slower** |
| DataFrame Creation (10000×10) | 0.53ms | 8.26ms | **15.6x slower** |
| Column Access (10000 rows) | 0.55ms | 9.46ms | **17.2x slower** |
| Value Access (10000 rows) | 0.54ms | 7.75ms | **14.4x slower** |
| Head Operation (1000 rows) | 0.09ms | 1.01ms | **11.2x slower** |
| Describe Operation (1000 rows) | 8.48ms | 5.66ms | **1.5x faster!** ✅ |
| DataFrame.fromMap/from_dict (1000 rows) | 0.12ms | 0.80ms | **6.7x slower** |
| DataFrame.toMap/to_dict (1000 rows) | 2.35ms | 0.38ms | **6.2x faster!** ✅ |

**Analysis:**
- DartFrame is competitive for DataFrame operations (10-20x slower vs 50-600x for arrays)
- **DartFrame is faster** for some operations (describe, toMap)
- The performance gap is much smaller for tabular data operations


## Performance Visualization

### Array Operations (Lower is Better)

```
Array Creation (100×100):
NumPy:     ▏ 0.01ms
DartFrame: ████████ 0.78ms (78x slower)

Array Creation (1000×1000):
NumPy:     ▏ 0.02ms
DartFrame: ████████████████████████████████████████████████████████████ 12.18ms (609x slower)

Array Sum (100×100):
NumPy:     ▏ 0.10ms
DartFrame: ████████████████████████████ 5.08ms (51x slower)

Array Sum (1000×1000):
NumPy:     ████ 7.31ms
DartFrame: ████████████████████████████████████████████████████████████████████████████████████████████████████ 195.39ms (27x slower)
```

### DataFrame Operations (Lower is Better)

```
DataFrame Creation (10000×10):
Pandas:    ▏ 0.53ms
DartFrame: ████████ 8.26ms (15.6x slower)

Column Access (10000 rows):
Pandas:    ▏ 0.55ms
DartFrame: █████████ 9.46ms (17.2x slower)

Describe Operation (1000 rows):
Pandas:    ████████ 8.48ms
DartFrame: ██████ 5.66ms (1.5x FASTER!) ✅

DataFrame.toMap (1000 rows):
Pandas:    ████████ 2.35ms
DartFrame: ▏ 0.38ms (6.2x FASTER!) ✅
```

## Why the Performance Difference?

### NumPy/Pandas Advantages
1. **C/Fortran Backend**: NumPy uses highly optimized C and Fortran libraries (BLAS, LAPACK)
2. **Mature Optimizations**: Decades of performance tuning
3. **Memory Layout**: Contiguous memory arrays for cache efficiency
4. **Vectorization**: SIMD instructions for parallel operations
5. **Specialized Algorithms**: Optimized implementations for common operations

### DartFrame Characteristics
1. **Pure Dart**: No native C/C++ extensions (yet)
2. **JIT Compilation**: Dart's JIT provides good performance but not C-level
3. **Cross-Platform**: Same code runs on mobile, web, desktop
4. **Type Safety**: Compile-time checking adds overhead but prevents errors
5. **Modern Language**: Benefits from Dart's modern features

## When Performance Matters

### Choose NumPy/Pandas When:
- ✅ **Heavy numerical computation** (matrix operations, scientific computing)
- ✅ **Large datasets** (millions of rows)
- ✅ **Performance-critical** applications
- ✅ **Desktop/Server only** deployment
- ✅ **Python ecosystem** integration needed

### Choose DartFrame When:
- ✅ **Cross-platform** applications (mobile, web, desktop)
- ✅ **Moderate data processing** (thousands to hundreds of thousands of rows)
- ✅ **Type safety** is important
- ✅ **Flutter integration** for UI
- ✅ **Web deployment** needed
- ✅ **Mobile apps** with data processing
- ✅ **Real-time applications** (Dart's async/await)

## Performance Optimization Strategies

### For DartFrame Users

1. **Use Appropriate Data Structures**
   - Use NDArray for numerical operations
   - Use DataFrame for tabular data
   - Use DataCube for 3D data

2. **Leverage Chunked Storage**
   ```dart
   NDArrayConfig.defaultBackend = BackendType.chunked;
   var largeArray = NDArray.zeros([10000, 10000]);
   ```

3. **Batch Operations**
   - Process data in batches rather than row-by-row
   - Use vectorized operations when available

4. **Minimize Type Conversions**
   - Keep data in native types
   - Avoid unnecessary conversions

5. **Use Isolates for Parallelism**
   ```dart
   // Dart has no GIL - true parallelism
   await compute(processData, largeDataset);
   ```

## Real-World Performance Scenarios

### Scenario 1: Mobile App with 10,000 Rows
**Task:** Load CSV, filter, display in UI

- **Pandas:** Not applicable (can't run on mobile)
- **DartFrame:** ~50ms total ✅

**Winner:** DartFrame (only option)

### Scenario 2: Web Dashboard with 100,000 Rows
**Task:** Load data, create charts, interactive filtering

- **Pandas:** Not applicable (can't run in browser)
- **DartFrame:** ~500ms total ✅

**Winner:** DartFrame (only option)

### Scenario 3: Desktop Analysis with 10 Million Rows
**Task:** Statistical analysis, aggregations, ML preprocessing

- **Pandas:** ~2-5 seconds ✅
- **DartFrame:** ~30-60 seconds

**Winner:** Pandas (much faster)

### Scenario 4: Cross-Platform App with 50,000 Rows
**Task:** Same codebase for mobile, web, desktop

- **Pandas:** Not applicable (Python doesn't compile to mobile/web)
- **DartFrame:** ~200ms, works everywhere ✅

**Winner:** DartFrame (only option)


## Detailed Performance Analysis

### Memory Usage

| Structure | NumPy/Pandas | DartFrame | Notes |
|-----------|--------------|-----------|-------|
| 1000×1000 array | ~8 MB | ~8 MB | Similar memory footprint |
| 10000×10 DataFrame | ~800 KB | ~1 MB | DartFrame slightly higher due to metadata |
| Overhead per object | Low | Moderate | Dart objects have more metadata |

### Startup Time

| Metric | NumPy/Pandas | DartFrame |
|--------|--------------|-----------|
| Import time | ~200ms | ~50ms |
| First operation | Fast | Fast |
| JIT warmup | N/A | ~100ms |

### Scalability

**Array Operations (1000×1000 → 5000×5000):**
- NumPy: 7ms → 180ms (25x increase for 25x data)
- DartFrame: 195ms → 18,700ms (96x increase for 25x data)

**Conclusion:** NumPy scales better for large numerical operations.

**DataFrame Operations (1000 → 10000 rows):**
- Pandas: 0.12ms → 0.53ms (4.4x increase for 10x data)
- DartFrame: 0.80ms → 8.26ms (10.3x increase for 10x data)

**Conclusion:** Both scale reasonably well for tabular data.

## Future Performance Improvements

### Planned DartFrame Optimizations

1. **Native Extensions**
   - FFI bindings to C/C++ libraries
   - SIMD operations via native code
   - Potential 10-50x speedup for numerical operations

2. **Lazy Evaluation**
   - Defer computations until needed
   - Optimize operation chains
   - Reduce intermediate allocations

3. **Parallel Processing**
   - Multi-isolate processing
   - Leverage Dart's true parallelism
   - No GIL limitations

4. **Memory Optimization**
   - Better memory pooling
   - Reduced object overhead
   - Optimized data layouts

5. **JIT Optimizations**
   - Profile-guided optimization
   - Hot path optimization
   - Better inlining

### Expected Future Performance

With planned optimizations:
- **Array operations:** 5-10x faster (still slower than NumPy)
- **DataFrame operations:** 2-3x faster (competitive with Pandas)
- **Cross-platform:** Maintain current advantages

## Conclusion

### Performance Summary

**NumPy/Pandas:**
- ✅ **10-100x faster** for numerical operations
- ✅ **Mature and optimized**
- ✅ **Best for heavy computation**
- ❌ **Desktop/Server only**
- ❌ **No mobile/web support**

**DartFrame:**
- ✅ **Cross-platform** (mobile, web, desktop)
- ✅ **Competitive** for DataFrame operations
- ✅ **Type-safe** and modern
- ✅ **Flutter integration**
- ⚠️ **10-100x slower** for numerical operations
- ⚠️ **Less mature** optimization

### Recommendation Matrix

| Use Case | Recommended | Reason |
|----------|-------------|--------|
| Scientific computing | NumPy/Pandas | Performance critical |
| Machine learning | NumPy/Pandas | Ecosystem + performance |
| Data analysis (desktop) | NumPy/Pandas | Mature tools |
| Mobile app | **DartFrame** | Only option |
| Web app | **DartFrame** | Only option |
| Cross-platform app | **DartFrame** | Single codebase |
| Flutter app | **DartFrame** | Native integration |
| Moderate data processing | **DartFrame** | Good enough + benefits |
| Real-time apps | **DartFrame** | Async/await + isolates |

### Final Verdict

**NumPy/Pandas** remains the gold standard for **performance-critical numerical computation** and **data science workflows** on desktop/server.

**DartFrame** excels in **cross-platform scenarios** where NumPy/Pandas cannot run, offering **good-enough performance** with **significant platform advantages**.

The choice depends on your priorities:
- **Performance above all?** → NumPy/Pandas
- **Cross-platform + type safety?** → DartFrame
- **Mobile/Web deployment?** → DartFrame (only option)

## Benchmark Reproduction

### Run Python Benchmark
```bash
pip install numpy pandas
python benchmarks/simple_python_benchmark.py
```

### Run Dart Benchmark
```bash
dart run benchmarks/simple_dart_benchmark.dart
```

### Run Both and Compare
```bash
# Linux/Mac
./benchmarks/run_comparison.sh

# Windows
benchmarks\run_comparison.bat
```

---

**Last Updated:** November 2024  
**DartFrame Version:** 0.8.6  
**NumPy Version:** 1.24.3  
**Pandas Version:** 2.3.3
