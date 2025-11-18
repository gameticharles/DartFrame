# DartFrame Performance Benchmarks

This directory contains performance benchmarks comparing DartFrame with NumPy/Pandas.

## Quick Start

### Run Dart Benchmarks
```bash
dart run benchmarks/simple_dart_benchmark.dart
```

### Run Python Benchmarks
```bash
# Install dependencies first
pip install numpy pandas

# Run benchmark
python benchmarks/simple_python_benchmark.py
```

### Run Comparison (Both)
```bash
# Linux/Mac
chmod +x benchmarks/run_comparison.sh
./benchmarks/run_comparison.sh

# Windows
benchmarks\run_comparison.bat
```

## Benchmark Files

- `simple_dart_benchmark.dart` - DartFrame performance tests
- `simple_python_benchmark.py` - NumPy/Pandas performance tests
- `dart_benchmark.dart` - Comprehensive Dart benchmarks (work in progress)
- `python_benchmark.py` - Comprehensive Python benchmarks (work in progress)
- `run_comparison.sh` - Unix script to run both benchmarks
- `run_comparison.bat` - Windows script to run both benchmarks

## Results

See `../PERFORMANCE_COMPARISON.md` for detailed analysis and results.

### Summary

**NumPy/Pandas:**
- 10-100x faster for numerical operations
- Best for heavy computation
- Desktop/Server only

**DartFrame:**
- Cross-platform (mobile, web, desktop)
- Competitive for DataFrame operations
- Good enough for moderate data processing

## Adding New Benchmarks

### Dart Benchmark Template
```dart
void myBenchmark() {
  // Setup
  final data = ...;
  
  // Operation to benchmark
  final result = someOperation(data);
}

// Add to main()
print(benchmark(myBenchmark, 'My Benchmark Description'));
```

### Python Benchmark Template
```python
def my_benchmark():
    # Setup
    data = ...
    
    # Operation to benchmark
    result = some_operation(data)

# Add to main
print(benchmark(my_benchmark, "My Benchmark Description"))
```

## Requirements

### Dart
- Dart SDK (latest stable)
- DartFrame package

### Python
- Python 3.7+
- NumPy
- Pandas

## Notes

- All benchmarks run 5 iterations and report average time
- Results may vary based on hardware and system load
- Benchmarks focus on common operations, not edge cases
- Memory usage is not currently measured (future enhancement)
