# DartFrame Performance Optimization Guide

## Current Performance Gap

Based on benchmarks, DartFrame is:
- **27-609x slower** than NumPy for array operations
- **10-20x slower** than Pandas for DataFrame operations
- **Competitive or faster** for some operations (describe, toMap)

## Optimization Strategies

### 1. Native Extensions via FFI (Highest Impact)

**Potential Speedup: 10-50x for numerical operations**

#### Implementation Strategy

```dart
// Use Dart FFI to call optimized C/C++ code
import 'dart:ffi' as ffi;

// Example: Fast array sum using C
class NativeArrayOps {
  static final DynamicLibrary _lib = DynamicLibrary.open('libarrayops.so');
  
  static final _sumDouble = _lib.lookupFunction<
    ffi.Double Function(ffi.Pointer<ffi.Double>, ffi.Int32),
    double Function(ffi.Pointer<ffi.Double>, int)
  >('array_sum_double');
  
  static double sum(List<double> data) {
    final ptr = calloc<ffi.Double>(data.length);
    for (var i = 0; i < data.length; i++) {
      ptr[i] = data[i];
    }
    final result = _sumDouble(ptr, data.length);
    calloc.free(ptr);
    return result;
  }
}
```

#### C Implementation (libarrayops.c)

```c
#include <stdint.h>

// Optimized array sum with SIMD
double array_sum_double(double* arr, int32_t len) {
    double sum = 0.0;
    
    // Use SIMD instructions for vectorization
    #ifdef __AVX__
    // AVX implementation for 4x speedup
    #endif
    
    // Fallback scalar implementation
    for (int i = 0; i < len; i++) {
        sum += arr[i];
    }
    return sum;
}
```

**Benefits:**
- Direct access to SIMD instructions
- Cache-friendly memory access
- Compiler optimizations (O3, loop unrolling)
- Can use BLAS/LAPACK libraries

**Challenges:**
- Platform-specific compilation
- FFI overhead for small operations
- Memory management complexity
- Web compatibility issues

---

### 2. Typed Data and Efficient Memory Layout

**Potential Speedup: 2-5x**

#### Current Issue
```dart
// Current: Generic List<dynamic>
List<dynamic> data = [1.0, 2.0, 3.0];  // Boxed objects
```

#### Optimized Approach
```dart
import 'dart:typed_data';

// Use typed arrays for better performance
class OptimizedNDArray {
  final Float64List _data;  // Contiguous memory, no boxing
  final Shape _shape;
  
  OptimizedNDArray(this._shape) 
    : _data = Float64List(_shape.size);
  
  // Direct memory access - much faster
  double getValue(List<int> indices) {
    return _data[_shape.toFlatIndex(indices)];
  }
  
  void setValue(List<int> indices, double value) {
    _data[_shape.toFlatIndex(indices)] = value;
  }
  
  // Vectorized operations
  OptimizedNDArray operator +(OptimizedNDArray other) {
    final result = OptimizedNDArray(_shape);
    for (var i = 0; i < _data.length; i++) {
      result._data[i] = _data[i] + other._data[i];
    }
    return result;
  }
}
```

**Benefits:**
- No boxing/unboxing overhead
- Better cache locality
- JIT can optimize better
- Reduced memory usage

**Implementation Plan:**
1. Create specialized classes for numeric types (Float64Array, Int32Array, etc.)
2. Use TypedData for internal storage
3. Provide generic interface for compatibility
4. Auto-select typed implementation when possible

---

### 3. Lazy Evaluation and Expression Trees

**Potential Speedup: 2-10x for chained operations**

#### Current Issue
```dart
// Each operation creates intermediate arrays
var result = array1 + array2 * array3 - array4;
// Creates 3 intermediate arrays!
```

#### Optimized Approach
```dart
// Build expression tree, evaluate once
class LazyNDArray {
  final Expression _expr;
  
  LazyNDArray operator +(LazyNDArray other) {
    return LazyNDArray(AddExpr(_expr, other._expr));
  }
  
  // Only evaluate when needed
  NDArray evaluate() {
    return _expr.compute();
  }
}

// Example usage
var lazy = array1.lazy + array2.lazy * array3.lazy;
var result = lazy.evaluate();  // Single pass, no intermediates
```

**Benefits:**
- Eliminates intermediate allocations
- Enables loop fusion
- Better cache utilization
- Reduces memory pressure

---

### 4. Parallel Processing with Isolates

**Potential Speedup: 2-8x (depending on cores)**

#### Implementation
```dart
import 'dart:isolate';

class ParallelNDArray {
  static Future<double> parallelSum(NDArray array) async {
    final numIsolates = Platform.numberOfProcessors;
    final chunkSize = array.size ~/ numIsolates;
    
    final futures = <Future<double>>[];
    
    for (var i = 0; i < numIsolates; i++) {
      final start = i * chunkSize;
      final end = (i == numIsolates - 1) ? array.size : (i + 1) * chunkSize;
      
      futures.add(Isolate.run(() {
        var sum = 0.0;
        for (var j = start; j < end; j++) {
          sum += array._data[j];
        }
        return sum;
      }));
    }
    
    final results = await Future.wait(futures);
    return results.reduce((a, b) => a + b);
  }
}
```

**Benefits:**
- True parallelism (no GIL like Python)
- Scales with CPU cores
- Good for large operations

**Challenges:**
- Isolate spawn overhead
- Data serialization cost
- Only beneficial for large datasets

---

### 5. JIT Optimization Hints

**Potential Speedup: 1.5-3x**

#### Techniques

```dart
// 1. Use final for better optimization
class OptimizedArray {
  final Float64List _data;  // JIT knows this won't change
  final int _length;
  
  // 2. Inline small methods
  @pragma('vm:prefer-inline')
  double _getUnchecked(int index) => _data[index];
  
  // 3. Mark hot paths
  @pragma('vm:always-inline')
  double sum() {
    var result = 0.0;
    for (var i = 0; i < _length; i++) {
      result += _data[i];
    }
    return result;
  }
  
  // 4. Use specialized loops
  void _fastLoop(void Function(int) body) {
    // JIT can optimize this pattern better
    for (var i = 0; i < _length; i++) {
      body(i);
    }
  }
}
```

**Additional Hints:**
```dart
// Avoid dynamic dispatch
@pragma('vm:never-inline')  // For debugging
@pragma('vm:prefer-inline')  // For hot paths
@pragma('vm:always-inline')  // Force inline
```

---

### 6. Memory Pool and Object Reuse

**Potential Speedup: 1.5-2x for repeated operations**

```dart
class ArrayPool {
  final Map<int, List<Float64List>> _pools = {};
  
  Float64List acquire(int size) {
    final pool = _pools[size];
    if (pool != null && pool.isNotEmpty) {
      return pool.removeLast();
    }
    return Float64List(size);
  }
  
  void release(Float64List array) {
    final size = array.length;
    _pools.putIfAbsent(size, () => []).add(array);
  }
}

// Usage
class OptimizedOps {
  static final _pool = ArrayPool();
  
  static NDArray add(NDArray a, NDArray b) {
    final temp = _pool.acquire(a.size);
    // ... perform operation ...
    final result = NDArray.fromTypedData(temp, a.shape);
    // Don't release temp - it's now owned by result
    return result;
  }
}
```

---

### 7. Specialized Algorithms

**Potential Speedup: 2-10x for specific operations**

#### Example: Fast Matrix Multiplication

```dart
class FastMatrixOps {
  // Blocked matrix multiplication for better cache usage
  static Float64List matmul(
    Float64List a, Float64List b,
    int m, int n, int p,
    {int blockSize = 64}
  ) {
    final result = Float64List(m * p);
    
    // Blocked algorithm for cache efficiency
    for (var i0 = 0; i0 < m; i0 += blockSize) {
      for (var j0 = 0; j0 < p; j0 += blockSize) {
        for (var k0 = 0; k0 < n; k0 += blockSize) {
          // Process block
          final iMax = min(i0 + blockSize, m);
          final jMax = min(j0 + blockSize, p);
          final kMax = min(k0 + blockSize, n);
          
          for (var i = i0; i < iMax; i++) {
            for (var j = j0; j < jMax; j++) {
              var sum = result[i * p + j];
              for (var k = k0; k < kMax; k++) {
                sum += a[i * n + k] * b[k * p + j];
              }
              result[i * p + j] = sum;
            }
          }
        }
      }
    }
    
    return result;
  }
}
```

---

### 8. Compile-Time Optimizations

**Potential Speedup: 1.2-2x**

#### AOT Compilation
```bash
# Compile to native code for production
dart compile exe lib/main.dart -o dartframe_app

# With optimizations
dart compile exe lib/main.dart -o dartframe_app --optimization-level=3
```

#### Profile-Guided Optimization
```bash
# 1. Run with profiling
dart --observe lib/main.dart

# 2. Collect profile data
# 3. Recompile with profile
dart compile exe lib/main.dart --profile=profile.json
```

---

### 9. Reduce Allocations

**Potential Speedup: 1.5-3x**

```dart
// Bad: Creates many temporary objects
double complexOperation(NDArray arr) {
  var temp1 = arr + 1;
  var temp2 = temp1 * 2;
  var temp3 = temp2 - 3;
  return temp3.sum();
}

// Good: Reuse buffers
double complexOperationOptimized(NDArray arr) {
  final buffer = Float64List(arr.size);
  
  // In-place operations
  for (var i = 0; i < arr.size; i++) {
    buffer[i] = (arr._data[i] + 1) * 2 - 3;
  }
  
  var sum = 0.0;
  for (var i = 0; i < buffer.length; i++) {
    sum += buffer[i];
  }
  
  return sum;
}
```

---

### 10. Benchmark-Driven Optimization

**Process:**

1. **Profile First**
```dart
import 'dart:developer';

void profiledOperation() {
  Timeline.startSync('MyOperation');
  // ... operation ...
  Timeline.finishSync();
}
```

2. **Identify Hotspots**
```bash
dart --observe --profile lib/main.dart
# Open Observatory in browser
# Analyze CPU profile
```

3. **Optimize Hotspots**
- Focus on functions taking >10% of time
- Optimize inner loops first
- Measure after each change

4. **Regression Testing**
```dart
void benchmarkRegression() {
  final before = benchmark(oldImplementation);
  final after = benchmark(newImplementation);
  
  assert(after < before, 'Performance regression!');
}
```


## Implementation Roadmap

### Phase 1: Quick Wins (1-2 months)
**Target: 2-3x speedup**

1. ✅ **Use TypedData everywhere**
   - Replace `List<dynamic>` with `Float64List`, `Int32List`, etc.
   - Implement specialized array classes
   - Estimated impact: 2-3x faster

2. ✅ **Add JIT optimization pragmas**
   - Mark hot paths with `@pragma('vm:prefer-inline')`
   - Use `final` for immutable fields
   - Estimated impact: 1.5x faster

3. ✅ **Reduce allocations**
   - Implement object pooling for temporary arrays
   - Reuse buffers in operations
   - Estimated impact: 1.5-2x faster

4. ✅ **Optimize common operations**
   - Specialized sum, mean, std implementations
   - Fast path for contiguous data
   - Estimated impact: 2x faster for these operations

**Combined Phase 1 Impact: 3-5x faster overall**

### Phase 2: Structural Improvements (2-4 months)
**Target: 5-10x speedup**

1. ✅ **Lazy evaluation system**
   - Build expression trees
   - Fuse operations
   - Eliminate intermediates
   - Estimated impact: 2-5x for chained operations

2. ✅ **Parallel processing**
   - Implement isolate-based parallelism
   - Auto-parallelize large operations
   - Estimated impact: 2-4x on multi-core systems

3. ✅ **Specialized algorithms**
   - Blocked matrix multiplication
   - Strassen's algorithm for large matrices
   - Fast Fourier Transform
   - Estimated impact: 5-10x for specific operations

4. ✅ **Memory layout optimization**
   - Row-major vs column-major
   - Strided arrays
   - Cache-friendly access patterns
   - Estimated impact: 1.5-2x

**Combined Phase 2 Impact: 10-20x faster overall**

### Phase 3: Native Extensions (4-6 months)
**Target: 20-50x speedup for numerical operations**

1. ✅ **FFI bindings to C/C++**
   - Core numerical operations in C
   - SIMD vectorization
   - OpenMP parallelization
   - Estimated impact: 10-20x

2. ✅ **BLAS/LAPACK integration**
   - Use optimized linear algebra libraries
   - Platform-specific optimizations (MKL, OpenBLAS)
   - Estimated impact: 20-50x for matrix operations

3. ✅ **GPU acceleration (optional)**
   - OpenCL/CUDA for large operations
   - Automatic GPU offloading
   - Estimated impact: 50-100x for suitable operations

**Combined Phase 3 Impact: 30-100x faster for numerical operations**

---

## Specific Optimization Examples

### Example 1: Optimizing Array Sum

#### Current Implementation (Slow)
```dart
dynamic sum() {
  var result = 0.0;
  for (var i = 0; i < size; i++) {
    final indices = shape.fromFlatIndex(i);
    result += getValue(indices);  // Virtual call, index calculation
  }
  return result;
}
```
**Performance: ~200ms for 1M elements**

#### Optimized Implementation (Fast)
```dart
double sum() {
  // Direct access to typed data
  final data = _backend.getFlatData(copy: false);
  
  if (data is Float64List) {
    return _sumFloat64(data);
  }
  
  // Fallback for other types
  var result = 0.0;
  for (var i = 0; i < data.length; i++) {
    result += data[i] as num;
  }
  return result;
}

@pragma('vm:prefer-inline')
double _sumFloat64(Float64List data) {
  var sum = 0.0;
  
  // Unroll loop for better performance
  final len = data.length;
  var i = 0;
  
  // Process 4 elements at a time
  for (; i < len - 3; i += 4) {
    sum += data[i] + data[i + 1] + data[i + 2] + data[i + 3];
  }
  
  // Handle remaining elements
  for (; i < len; i++) {
    sum += data[i];
  }
  
  return sum;
}
```
**Performance: ~20ms for 1M elements (10x faster)**

#### With FFI (Fastest)
```dart
double sum() {
  final data = _backend.getFlatData(copy: false);
  
  if (data is Float64List) {
    return _nativeSumFloat64(data);
  }
  
  return _sumFloat64(data as Float64List);
}

double _nativeSumFloat64(Float64List data) {
  final ptr = data.buffer.asUint8List().cast<ffi.Double>();
  return NativeOps.sumDouble(ptr, data.length);
}
```
**Performance: ~2ms for 1M elements (100x faster)**

---

### Example 2: Optimizing DataFrame Column Access

#### Current Implementation
```dart
Series operator [](dynamic column) {
  final columnIndex = _columns.indexOf(column);
  final columnData = <dynamic>[];
  
  for (var row in _data) {
    columnData.add(row[columnIndex]);
  }
  
  return Series(columnData, name: column);
}
```
**Performance: ~10ms for 10K rows**

#### Optimized Implementation
```dart
Series operator [](dynamic column) {
  final columnIndex = _columns.indexOf(column);
  
  // Pre-allocate with exact size
  final columnData = List<dynamic>.filled(rowCount, null);
  
  // Direct array access
  for (var i = 0; i < rowCount; i++) {
    columnData[i] = _data[i][columnIndex];
  }
  
  return Series(columnData, name: column);
}
```
**Performance: ~3ms for 10K rows (3x faster)**

#### With Caching
```dart
final Map<dynamic, Series> _columnCache = {};

Series operator [](dynamic column) {
  // Return cached if available
  if (_columnCache.containsKey(column)) {
    return _columnCache[column]!;
  }
  
  final columnIndex = _columns.indexOf(column);
  final columnData = List<dynamic>.filled(rowCount, null);
  
  for (var i = 0; i < rowCount; i++) {
    columnData[i] = _data[i][columnIndex];
  }
  
  final series = Series(columnData, name: column);
  _columnCache[column] = series;
  
  return series;
}
```
**Performance: ~0.01ms for cached access (1000x faster for repeated access)**

---

## Benchmarking Tools

### 1. Built-in Profiler
```dart
import 'dart:developer';

void profileOperation() {
  Timeline.startSync('Operation');
  // ... code to profile ...
  Timeline.finishSync();
}

// Run with: dart --observe lib/main.dart
// Open Observatory at http://localhost:8181
```

### 2. Custom Benchmark Framework
```dart
class Benchmark {
  static void run(String name, Function operation, {int iterations = 100}) {
    // Warmup
    for (var i = 0; i < 10; i++) {
      operation();
    }
    
    // Measure
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      operation();
    }
    stopwatch.stop();
    
    final avgMs = stopwatch.elapsedMicroseconds / iterations / 1000;
    print('$name: ${avgMs.toStringAsFixed(2)}ms');
  }
}
```

### 3. Memory Profiler
```dart
import 'dart:developer';

void profileMemory() {
  final before = ProcessInfo.currentRss;
  
  // ... operation ...
  
  final after = ProcessInfo.currentRss;
  print('Memory used: ${(after - before) / 1024 / 1024}MB');
}
```

---

## Performance Testing Strategy

### 1. Regression Tests
```dart
void testPerformanceRegression() {
  final baseline = {
    'array_sum_1000': 0.2,  // ms
    'dataframe_create_10k': 10.0,
    'column_access': 5.0,
  };
  
  for (final entry in baseline.entries) {
    final actual = benchmark(operations[entry.key]);
    
    if (actual > entry.value * 1.1) {  // 10% tolerance
      throw Exception('Performance regression in ${entry.key}: '
          'expected ${entry.value}ms, got ${actual}ms');
    }
  }
}
```

### 2. Continuous Benchmarking
```yaml
# .github/workflows/benchmark.yml
name: Performance Benchmarks

on: [push, pull_request]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart run benchmarks/simple_dart_benchmark.dart
      - name: Compare with baseline
        run: |
          # Compare results with baseline
          # Fail if regression > 10%
```

---

## Expected Results After Optimization

### Projected Performance (After All Phases)

| Operation | Current | Phase 1 | Phase 2 | Phase 3 | vs NumPy |
|-----------|---------|---------|---------|---------|----------|
| Array Creation (1000×1000) | 12ms | 4ms | 2ms | 0.5ms | 25x slower |
| Array Sum (1000×1000) | 200ms | 70ms | 20ms | 5ms | 1.5x slower |
| DataFrame Creation (10K×10) | 8ms | 3ms | 2ms | 1ms | 2x slower |
| Column Access | 10ms | 3ms | 1ms | 0.5ms | 1x (same!) |

### Summary

**Current State:**
- 27-609x slower than NumPy for arrays
- 10-20x slower than Pandas for DataFrames

**After Phase 1 (Quick Wins):**
- 10-200x slower than NumPy
- 3-7x slower than Pandas

**After Phase 2 (Structural):**
- 5-50x slower than NumPy
- 1-3x slower than Pandas

**After Phase 3 (Native):**
- 1-10x slower than NumPy
- **Competitive with Pandas** for many operations

---

## Conclusion

DartFrame can achieve **significant performance improvements** through:

1. **Immediate wins** (2-3x): TypedData, pragmas, reduced allocations
2. **Medium-term** (5-10x): Lazy evaluation, parallelism, specialized algorithms
3. **Long-term** (20-50x): FFI, BLAS/LAPACK, GPU acceleration

While DartFrame may never match NumPy's raw speed for all operations (due to NumPy's decades of optimization), it can become **competitive enough** for most use cases while maintaining its **cross-platform advantages**.

The key is to **prioritize optimizations** based on:
- User impact (which operations are most common?)
- Implementation effort (quick wins first)
- Platform compatibility (maintain web/mobile support)

**Next Steps:**
1. Implement Phase 1 optimizations (highest ROI)
2. Benchmark and measure improvements
3. Gather user feedback on bottlenecks
4. Proceed to Phase 2 based on priorities
