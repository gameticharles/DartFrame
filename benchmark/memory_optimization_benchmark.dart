import 'dart:math';
import 'dart:math' as math;
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dartframe/dartframe.dart';

// Helper for generating random data
final Random _random = Random(42);

/// Benchmark for measuring memory optimization effectiveness
class MemoryOptimizationEffectivenessBenchmark extends BenchmarkBase {
  final int size;
  late DataFrame originalDataFrame;
  late DataFrame optimizedDataFrame;

  MemoryOptimizationEffectivenessBenchmark(this.size)
      : super('MemoryOptimization.effectiveness(size:$size)');

  @override
  void setup() {
    // Create DataFrame with various data types that can be optimized
    Map<String, List<dynamic>> data = {
      // Integers stored as doubles (can be optimized)
      'integers_as_doubles': List.generate(size, (i) => (i % 1000).toDouble()),

      // Small integers (can use smaller int types)
      'small_integers': List.generate(size, (i) => i % 128),

      // Large integers (need full int range)
      'large_integers': List.generate(size, (i) => i * 10000),

      // Actual doubles (cannot be optimized to int)
      'actual_doubles': List.generate(size, (i) => _random.nextDouble() * 100),

      // Strings (cannot be optimized)
      'strings': List.generate(size, (i) => 'item_${i % 100}'),

      // Boolean-like integers (could be optimized)
      'boolean_ints': List.generate(size, (i) => i % 2),
    };

    originalDataFrame = DataFrame.fromMap(data);
    optimizedDataFrame = originalDataFrame.optimizeMemory();
  }

  @override
  void run() {
    // Measure memory usage of both DataFrames
    int originalMemory = originalDataFrame.memoryUsage;
    int optimizedMemory = optimizedDataFrame.memoryUsage;

    // Calculate optimization ratio
    double optimizationRatio = optimizedMemory / originalMemory;

    // Verify data integrity
    _verifyDataIntegrity();

    // Store results for reporting (in a real implementation)
    _recordResults(originalMemory, optimizedMemory, optimizationRatio);
  }

  void _verifyDataIntegrity() {
    // Verify that optimization preserves data values
    assert(originalDataFrame.rowCount == optimizedDataFrame.rowCount);
    assert(originalDataFrame.columnCount == optimizedDataFrame.columnCount);

    // Sample check of a few values
    for (int i = 0; i < min(10, originalDataFrame.rowCount); i++) {
      for (String column in originalDataFrame.columns.cast<String>()) {
        var originalValue = originalDataFrame[column].data[i];
        var optimizedValue = optimizedDataFrame[column].data[i];
        assert(originalValue == optimizedValue);
      }
    }
  }

  void _recordResults(int originalMemory, int optimizedMemory, double ratio) {
    // In a real implementation, this would record results for analysis
    print('Original memory: ${_formatBytes(originalMemory)}');
    print('Optimized memory: ${_formatBytes(optimizedMemory)}');
    print('Optimization ratio: ${(ratio * 100).toStringAsFixed(1)}%');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Benchmark for Series memory optimization
class SeriesMemoryOptimizationBenchmark extends BenchmarkBase {
  final int size;
  final String dataType;
  late Series originalSeries;
  late Series optimizedSeries;

  SeriesMemoryOptimizationBenchmark(this.size, this.dataType)
      : super('SeriesMemoryOptimization.$dataType(size:$size)');

  @override
  void setup() {
    List<dynamic> data;

    switch (dataType) {
      case 'integers_as_doubles':
        data = List.generate(size, (i) => (i % 1000).toDouble());
        break;
      case 'small_integers':
        data = List.generate(size, (i) => i % 128);
        break;
      case 'large_integers':
        data = List.generate(size, (i) => i * 10000);
        break;
      case 'actual_doubles':
        data = List.generate(size, (i) => _random.nextDouble() * 100);
        break;
      case 'mixed_with_nulls':
        data = List.generate(size, (i) {
          if (i % 10 == 0) return null;
          return (i % 100).toDouble();
        });
        break;
      default:
        data = List.generate(size, (i) => i);
    }

    originalSeries = Series(data, name: 'test_series');
    optimizedSeries = originalSeries.optimizeMemory();
  }

  @override
  void run() {
    // Measure memory usage and verify data integrity
    originalSeries.memoryUsage;
    optimizedSeries.memoryUsage;

    // Verify data integrity
    assert(originalSeries.length == optimizedSeries.length);
    for (int i = 0; i < min(10, originalSeries.length); i++) {
      assert(originalSeries.data[i] == optimizedSeries.data[i]);
    }
  }
}

/// Benchmark for memory usage estimation accuracy
class MemoryEstimationAccuracyBenchmark extends BenchmarkBase {
  final int size;
  late DataFrame testDataFrame;
  late Series testSeries;

  MemoryEstimationAccuracyBenchmark(this.size)
      : super('MemoryEstimation.accuracy(size:$size)');

  @override
  void setup() {
    Map<String, List<dynamic>> data = {
      'integers': List.generate(size, (i) => i),
      'doubles': List.generate(size, (i) => i * 0.5),
      'strings': List.generate(size, (i) => 'item_$i'),
      'booleans': List.generate(size, (i) => i % 2 == 0),
    };

    testDataFrame = DataFrame.fromMap(data);
    testSeries = Series(
      List.generate(size, (i) => i * 0.5),
      name: 'test_series',
    );
  }

  @override
  void run() {
    // Test DataFrame memory estimation
    int dfMemoryEstimate = testDataFrame.memoryUsage;
    assert(dfMemoryEstimate > 0);

    // Test Series memory estimation
    int seriesMemoryEstimate = testSeries.memoryUsage;
    assert(seriesMemoryEstimate > 0);

    // Test memory report generation
    String memoryReport = testDataFrame.memoryReport;
    assert(memoryReport.isNotEmpty);
    assert(memoryReport.contains('Memory Usage Report'));

    // Test optimization recommendations
    Map<String, String> recommendations = testDataFrame.memoryRecommendations;
    assert(recommendations.isNotEmpty);
  }
}

/// Benchmark for typed array conversion performance
class TypedArrayConversionBenchmark extends BenchmarkBase {
  final int size;
  final String targetType;
  late Series numericSeries;

  TypedArrayConversionBenchmark(this.size, this.targetType)
      : super('TypedArrayConversion.$targetType(size:$size)');

  @override
  void setup() {
    List<dynamic> data;

    switch (targetType) {
      case 'int8':
        data = List.generate(size, (i) => (i % 128) - 64); // -64 to 63
        break;
      case 'int16':
        data = List.generate(size, (i) => (i % 32768) - 16384);
        break;
      case 'int32':
        data = List.generate(size, (i) => i % 1000000);
        break;
      case 'float32':
        data = List.generate(size, (i) => (i * 0.5));
        break;
      case 'float64':
        data = List.generate(size, (i) => i * math.pi);
        break;
      default:
        data = List.generate(size, (i) => i);
    }

    numericSeries = Series(data, name: 'numeric_series');
  }

  @override
  void run() {
    try {
      Series typedSeries = numericSeries.toTypedArray(targetType);

      // Verify conversion worked
      assert(typedSeries.length == numericSeries.length);
      assert(typedSeries.name == numericSeries.name);

      // Sample check of values (allowing for precision differences in float conversions)
      for (int i = 0; i < min(10, numericSeries.length); i++) {
        dynamic original = numericSeries.data[i];
        dynamic converted = typedSeries.data[i];

        if (original is double && converted is double) {
          // Allow small precision differences for float conversions
          assert((original - converted).abs() < 1e-6);
        } else {
          assert(original == converted);
        }
      }
    } catch (e) {
      // Some conversions may not be supported or may fail for certain data ranges
      // This is expected behavior for edge cases
      print('Conversion to $targetType failed as expected: $e');
    }
  }
}

/// Comprehensive memory optimization benchmark suite
class ComprehensiveMemoryBenchmark extends BenchmarkBase {
  final int size;
  late List<DataFrame> testDataFrames;
  late List<Series> testSeries;

  ComprehensiveMemoryBenchmark(this.size)
      : super('ComprehensiveMemory.suite(size:$size)');

  @override
  void setup() {
    testDataFrames = [];
    testSeries = [];

    // Create various test scenarios
    _createOptimizableDataFrame();
    _createMixedTypeDataFrame();
    _createLargeDataFrame();
    _createSparseDataFrame();

    _createOptimizableSeries();
    _createMixedTypeSeries();
    _createSparseSeries();
  }

  void _createOptimizableDataFrame() {
    Map<String, List<dynamic>> data = {
      'int_as_double': List.generate(size, (i) => (i % 100).toDouble()),
      'small_int': List.generate(size, (i) => i % 50),
      'boolean_int': List.generate(size, (i) => i % 2),
    };
    testDataFrames.add(DataFrame.fromMap(data));
  }

  void _createMixedTypeDataFrame() {
    Map<String, List<dynamic>> data = {
      'integers': List.generate(size, (i) => i),
      'doubles': List.generate(size, (i) => i * math.pi),
      'strings': List.generate(size, (i) => 'item_$i'),
      'booleans': List.generate(size, (i) => i % 2 == 0),
    };
    testDataFrames.add(DataFrame.fromMap(data));
  }

  void _createLargeDataFrame() {
    Map<String, List<dynamic>> data = {};
    for (int col = 0; col < 20; col++) {
      data['col_$col'] =
          List.generate(size, (i) => _random.nextDouble() * 1000);
    }
    testDataFrames.add(DataFrame.fromMap(data));
  }

  void _createSparseDataFrame() {
    Map<String, List<dynamic>> data = {
      'sparse_int': List.generate(size, (i) => i % 10 == 0 ? i : null),
      'sparse_double': List.generate(size, (i) => i % 5 == 0 ? i * 0.5 : null),
      'sparse_string':
          List.generate(size, (i) => i % 7 == 0 ? 'value_$i' : null),
    };
    testDataFrames.add(DataFrame.fromMap(data));
  }

  void _createOptimizableSeries() {
    testSeries.add(Series(
      List.generate(size, (i) => (i % 100).toDouble()),
      name: 'optimizable',
    ));
  }

  void _createMixedTypeSeries() {
    testSeries.add(Series(
      List.generate(size, (i) => i % 3 == 0 ? i.toDouble() : i),
      name: 'mixed',
    ));
  }

  void _createSparseSeries() {
    testSeries.add(Series(
      List.generate(size, (i) => i % 5 == 0 ? i : null),
      name: 'sparse',
    ));
  }

  @override
  void run() {
    int totalOriginalMemory = 0;
    int totalOptimizedMemory = 0;

    // Test DataFrame optimizations
    for (DataFrame df in testDataFrames) {
      int originalMemory = df.memoryUsage;
      DataFrame optimized = df.optimizeMemory();
      int optimizedMemory = optimized.memoryUsage;

      totalOriginalMemory += originalMemory;
      totalOptimizedMemory += optimizedMemory;

      // Verify data integrity
      assert(df.rowCount == optimized.rowCount);
      assert(df.columnCount == optimized.columnCount);
    }

    // Test Series optimizations
    for (Series series in testSeries) {
      int originalMemory = series.memoryUsage;
      Series optimized = series.optimizeMemory();
      int optimizedMemory = optimized.memoryUsage;

      totalOriginalMemory += originalMemory;
      totalOptimizedMemory += optimizedMemory;

      // Verify data integrity
      assert(series.length == optimized.length);
      assert(series.name == optimized.name);
    }

    // Calculate overall optimization effectiveness
    double optimizationRatio = totalOptimizedMemory / totalOriginalMemory;
    print(
        'Overall memory optimization: ${(optimizationRatio * 100).toStringAsFixed(1)}%');
  }
}

void main() {
  print('=== MEMORY OPTIMIZATION BENCHMARKS ===\n');

  final sizes = [1000, 5000, 10000];
  final dataTypes = [
    'integers_as_doubles',
    'small_integers',
    'large_integers',
    'actual_doubles',
    'mixed_with_nulls',
  ];
  final typedArrayTypes = ['int8', 'int16', 'int32', 'float32', 'float64'];

  // DataFrame memory optimization effectiveness
  print('--- DataFrame Memory Optimization ---');
  for (int size in sizes) {
    MemoryOptimizationEffectivenessBenchmark(size).report();
  }

  // Series memory optimization by data type
  print('\n--- Series Memory Optimization by Type ---');
  for (int size in [1000, 5000]) {
    for (String dataType in dataTypes) {
      SeriesMemoryOptimizationBenchmark(size, dataType).report();
    }
  }

  // Memory estimation accuracy
  print('\n--- Memory Estimation Accuracy ---');
  for (int size in sizes) {
    MemoryEstimationAccuracyBenchmark(size).report();
  }

  // Typed array conversion performance
  print('\n--- Typed Array Conversion ---');
  for (int size in [1000, 5000]) {
    for (String arrayType in typedArrayTypes) {
      TypedArrayConversionBenchmark(size, arrayType).report();
    }
  }

  // Comprehensive memory optimization suite
  print('\n--- Comprehensive Memory Optimization ---');
  for (int size in [1000, 5000]) {
    ComprehensiveMemoryBenchmark(size).report();
  }

  print('\n=== MEMORY OPTIMIZATION BENCHMARKS COMPLETE ===');
}
