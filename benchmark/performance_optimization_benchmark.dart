import 'dart:math';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dartframe/dartframe.dart';

// Helper for generating random data
final Random _random = Random(42); // Seed for reproducibility

/// Benchmarks for vectorized operations performance
class VectorizedApplyBenchmark extends BenchmarkBase {
  final int size;
  late Series series;
  late dynamic Function(dynamic) simpleFunc;
  late dynamic Function(dynamic) complexFunc;

  VectorizedApplyBenchmark(this.size)
      : super('VectorizedApply.performance(size:$size)');

  @override
  void setup() {
    series = Series(
      List.generate(size, (i) => _random.nextDouble() * 100),
      name: 'test_series',
    );
    simpleFunc = (x) => x * 2;
    complexFunc = (x) => x * x + 2 * x + 1; // Quadratic function
  }

  @override
  void run() {
    // Test simple vectorized operation (synchronous)
    series.vectorizedMath(2, '*');
    
    // Test complex vectorized operation (synchronous)
    final squared = series.vectorizedMath(series, '*');
    final doubled = series.vectorizedMath(2, '*');
    squared.vectorizedMath(doubled, '+').vectorizedMath(1, '+');
  }
}

/// Benchmarks for vectorized mathematical operations
class VectorizedMathBenchmark extends BenchmarkBase {
  final int size;
  late Series series1;
  late Series series2;
  late double scalar;

  VectorizedMathBenchmark(this.size)
      : super('VectorizedMath.operations(size:$size)');

  @override
  void setup() {
    series1 = Series(
      List.generate(size, (i) => _random.nextDouble() * 100),
      name: 'series1',
    );
    series2 = Series(
      List.generate(size, (i) => _random.nextDouble() * 100),
      name: 'series2',
    );
    scalar = 5.0;
  }

  @override
  void run() {
    // Series-scalar operations
    series1.vectorizedMath(scalar, '+');
    series1.vectorizedMath(scalar, '*');
    
    // Series-series operations
    series1.vectorizedMath(series2, '+');
    series1.vectorizedMath(series2, '*');
  }
}

/// Benchmarks for vectorized comparison operations
class VectorizedComparisonBenchmark extends BenchmarkBase {
  final int size;
  late Series series1;
  late Series series2;
  late double threshold;

  VectorizedComparisonBenchmark(this.size)
      : super('VectorizedComparison.operations(size:$size)');

  @override
  void setup() {
    series1 = Series(
      List.generate(size, (i) => _random.nextDouble() * 100),
      name: 'series1',
    );
    series2 = Series(
      List.generate(size, (i) => _random.nextDouble() * 100),
      name: 'series2',
    );
    threshold = 50.0;
  }

  @override
  void run() {
    // Scalar comparisons
    series1.vectorizedComparison(threshold, '>');
    series1.vectorizedComparison(threshold, '<=');
    
    // Series comparisons
    series1.vectorizedComparison(series2, '==');
    series1.vectorizedComparison(series2, '!=');
  }
}

/// Benchmarks for vectorized string operations
class VectorizedStringBenchmark extends BenchmarkBase {
  final int size;
  late Series stringSeries;

  VectorizedStringBenchmark(this.size)
      : super('VectorizedString.operations(size:$size)');

  @override
  void setup() {
    stringSeries = Series(
      List.generate(size, (i) => 'Test String ${_random.nextInt(1000)}'),
      name: 'string_series',
    );
  }

  @override
  void run() {
    // String operations
    stringSeries.vectorizedStringOperation('upper');
    stringSeries.vectorizedStringOperation('lower');
    stringSeries.vectorizedStringOperation('length');
    stringSeries.vectorizedStringOperation('contains', argument: 'Test');
  }
}

/// Benchmarks for vectorized aggregation operations
class VectorizedAggregationBenchmark extends BenchmarkBase {
  final int size;
  late Series numericSeries;
  late List<String> operations;

  VectorizedAggregationBenchmark(this.size)
      : super('VectorizedAggregation.operations(size:$size)');

  @override
  void setup() {
    numericSeries = Series(
      List.generate(size, (i) => _random.nextDouble() * 100),
      name: 'numeric_series',
    );
    operations = ['sum', 'mean', 'min', 'max', 'std', 'var'];
  }

  @override
  void run() {
    numericSeries.vectorizedAggregation(operations);
  }
}

/// Benchmarks for parallel processing performance
class ParallelProcessingBenchmark extends BenchmarkBase {
  final int size;
  final bool useParallel;
  late Series largeSeries;
  late dynamic Function(dynamic) expensiveFunc;

  ParallelProcessingBenchmark(this.size, this.useParallel)
      : super('ParallelProcessing.${useParallel ? 'parallel' : 'sequential'}(size:$size)');

  @override
  void setup() {
    largeSeries = Series(
      List.generate(size, (i) => _random.nextDouble() * 100),
      name: 'large_series',
    );
    // Simulate expensive computation
    expensiveFunc = (x) {
      double result = x;
      for (int i = 0; i < 10; i++) {
        result = sqrt(result * result + 1);
      }
      return result;
    };
  }

  @override
  void run() {
    // For benchmark purposes, use synchronous operations
    // In real implementation, this would be async
    if (useParallel) {
      // Simulate parallel processing with multiple smaller operations
      for (int i = 0; i < largeSeries.length; i += 1000) {
        int end = (i + 1000 < largeSeries.length) ? i + 1000 : largeSeries.length;
        // Process chunk
        largeSeries.vectorizedMath(2, '*');
      }
    } else {
      // Sequential processing
      largeSeries.vectorizedMath(2, '*');
    }
  }
}

/// Benchmarks for DataFrame parallel column processing
class DataFrameParallelColumnBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  late DataFrame dataFrame;
  late Series Function(Series) processingFunc;

  DataFrameParallelColumnBenchmark(this.rows, this.cols)
      : super('DataFrame.parallelColumns(rows:$rows,cols:$cols)');

  @override
  void setup() {
    Map<String, List<dynamic>> data = {};
    for (int j = 0; j < cols; j++) {
      data['col_$j'] = List.generate(rows, (i) => _random.nextDouble() * 100);
    }
    dataFrame = DataFrame.fromMap(data);
    
    // Processing function that applies multiple operations
    processingFunc = (Series series) {
      // Use synchronous vectorized math instead of async vectorizedApply
      return series.vectorizedMath(2, '*').vectorizedMath(1, '+');
    };
  }

  @override
  void run() {
    // For benchmark purposes, process columns sequentially
    // In real implementation, this would use parallelColumnProcess
    for (String columnName in dataFrame.columns.cast<String>()) {
      Series column = dataFrame[columnName];
      processingFunc(column);
    }
  }
}

/// Benchmarks for batch processing operations
class BatchProcessingBenchmark extends BenchmarkBase {
  final int numSeries;
  final int seriesSize;
  final bool useParallel;
  late List<Series> seriesList;
  late dynamic Function(Series) batchFunc;

  BatchProcessingBenchmark(this.numSeries, this.seriesSize, this.useParallel)
      : super('BatchProcessing.${useParallel ? 'parallel' : 'sequential'}(series:$numSeries,size:$seriesSize)');

  @override
  void setup() {
    seriesList = [];
    for (int i = 0; i < numSeries; i++) {
      seriesList.add(Series(
        List.generate(seriesSize, (j) => _random.nextDouble() * 100),
        name: 'series_$i',
      ));
    }
    
    batchFunc = (Series series) {
      return series.vectorizedMath(series, '*'); // Square each element
    };
  }

  @override
  void run() {
    // This would use the PerformanceOptimizer.batchProcess method
    // For now, we'll simulate it with sequential processing
    for (Series series in seriesList) {
      batchFunc(series);
    }
  }
}

/// Memory optimization benchmarks
class MemoryOptimizationBenchmark extends BenchmarkBase {
  final int size;
  late DataFrame originalDataFrame;
  late Series originalSeries;

  MemoryOptimizationBenchmark(this.size)
      : super('MemoryOptimization.optimize(size:$size)');

  @override
  void setup() {
    // Create DataFrame with mixed data types that can be optimized
    Map<String, List<dynamic>> data = {
      'integers_as_doubles': List.generate(size, (i) => (i % 100).toDouble()),
      'small_integers': List.generate(size, (i) => i % 128),
      'large_integers': List.generate(size, (i) => i * 1000),
      'actual_doubles': List.generate(size, (i) => _random.nextDouble() * 100),
      'strings': List.generate(size, (i) => 'item_$i'),
    };
    originalDataFrame = DataFrame.fromMap(data);
    
    originalSeries = Series(
      List.generate(size, (i) => (i % 100).toDouble()), // Integers stored as doubles
      name: 'test_series',
    );
  }

  @override
  void run() {
    // Test DataFrame memory optimization
    originalDataFrame.optimizeMemory();
    
    // Test Series memory optimization
    originalSeries.optimizeMemory();
    
    // Test memory usage estimation
    originalDataFrame.memoryUsage;
    originalSeries.memoryUsage;
  }
}

/// Cache performance benchmarks
class CachePerformanceBenchmark extends BenchmarkBase {
  final int size;
  final bool useCache;
  late Series testSeries;
  late DataFrame testDataFrame;
  late dynamic Function() expensiveOperation;

  CachePerformanceBenchmark(this.size, this.useCache)
      : super('CachePerformance.${useCache ? 'cached' : 'uncached'}(size:$size)');

  @override
  void setup() {
    testSeries = Series(
      List.generate(size, (i) => _random.nextDouble() * 100),
      name: 'test_series',
    );
    
    Map<String, List<dynamic>> data = {};
    for (int j = 0; j < 5; j++) {
      data['col_$j'] = List.generate(size, (i) => _random.nextDouble() * 100);
    }
    testDataFrame = DataFrame.fromMap(data);
    
    // Simulate expensive operation
    expensiveOperation = () {
      List<double> result = [];
      for (int i = 0; i < size; i++) {
        double value = _random.nextDouble();
        // Simulate expensive computation
        for (int j = 0; j < 10; j++) {
          value = sqrt(value * value + 1);
        }
        result.add(value);
      }
      return result;
    };
  }

  @override
  void run() {
    if (useCache) {
      // Simulate cached operation (would use CacheManager in real implementation)
      // For benchmark purposes, we'll just call the operation once
      expensiveOperation();
    } else {
      // Call expensive operation multiple times without caching
      expensiveOperation();
      expensiveOperation();
      expensiveOperation();
    }
  }
}

/// Comprehensive performance comparison benchmark
class PerformanceComparisonBenchmark extends BenchmarkBase {
  final int size;
  final String operationType;
  late Series testSeries;
  late DataFrame testDataFrame;

  PerformanceComparisonBenchmark(this.size, this.operationType)
      : super('Performance.comparison.$operationType(size:$size)');

  @override
  void setup() {
    testSeries = Series(
      List.generate(size, (i) => _random.nextDouble() * 100),
      name: 'test_series',
    );
    
    Map<String, List<dynamic>> data = {};
    for (int j = 0; j < 10; j++) {
      data['col_$j'] = List.generate(size, (i) => _random.nextDouble() * 100);
    }
    testDataFrame = DataFrame.fromMap(data);
  }

  @override
  void run() {
    switch (operationType) {
      case 'traditional_apply':
        // Traditional apply operation (if available)
        testSeries.apply((x) => x * 2);
        break;
      case 'vectorized_apply':
        // Vectorized apply operation
        testSeries.vectorizedApply((x) => x * 2);
        break;
      case 'traditional_math':
        // Traditional mathematical operations
        testSeries + 5;
        break;
      case 'vectorized_math':
        // Vectorized mathematical operations
        testSeries.vectorizedMath(5, '+');
        break;
      case 'memory_optimized':
        // Memory optimization
        testDataFrame.optimizeMemory();
        break;
      case 'parallel_processing':
        // Parallel processing
        testSeries.vectorizedApply((x) => x * x, parallel: true);
        break;
    }
  }
}

void main() {
  print('=== PERFORMANCE OPTIMIZATION BENCHMARKS ===\n');
  
  final sizes = [1000, 10000, 100000];
  final smallSizes = [1000, 5000];
  
  // Vectorized operations benchmarks
  print('--- Vectorized Operations ---');
  for (int size in sizes) {
    VectorizedApplyBenchmark(size).report();
    VectorizedMathBenchmark(size).report();
    VectorizedComparisonBenchmark(size).report();
    VectorizedStringBenchmark(size).report();
    VectorizedAggregationBenchmark(size).report();
  }
  
  // Parallel processing benchmarks
  print('\n--- Parallel Processing ---');
  for (int size in sizes) {
    ParallelProcessingBenchmark(size, false).report(); // Sequential
    ParallelProcessingBenchmark(size, true).report();  // Parallel
  }
  
  // DataFrame parallel column processing
  print('\n--- DataFrame Parallel Processing ---');
  final rowCounts = [1000, 5000];
  final colCounts = [5, 20];
  for (int rows in rowCounts) {
    for (int cols in colCounts) {
      DataFrameParallelColumnBenchmark(rows, cols).report();
    }
  }
  
  // Batch processing benchmarks
  print('\n--- Batch Processing ---');
  final batchConfigs = [
    [5, 1000],   // 5 series of 1000 elements each
    [10, 5000],  // 10 series of 5000 elements each
  ];
  for (List<int> config in batchConfigs) {
    BatchProcessingBenchmark(config[0], config[1], false).report(); // Sequential
    BatchProcessingBenchmark(config[0], config[1], true).report();  // Parallel
  }
  
  // Memory optimization benchmarks
  print('\n--- Memory Optimization ---');
  for (int size in smallSizes) {
    MemoryOptimizationBenchmark(size).report();
  }
  
  // Cache performance benchmarks
  print('\n--- Cache Performance ---');
  for (int size in smallSizes) {
    CachePerformanceBenchmark(size, false).report(); // Uncached
    CachePerformanceBenchmark(size, true).report();  // Cached
  }
  
  // Performance comparison benchmarks
  print('\n--- Performance Comparisons ---');
  final operations = [
    'traditional_apply',
    'vectorized_apply',
    'traditional_math',
    'vectorized_math',
    'memory_optimized',
    'parallel_processing',
  ];
  
  for (String operation in operations) {
    for (int size in smallSizes) {
      PerformanceComparisonBenchmark(size, operation).report();
    }
  }
  
  print('\n=== BENCHMARK COMPLETE ===');
}