import 'dart:io';
import 'dart:math';
import 'package:dartframe/dartframe.dart';

/// Comprehensive performance test runner for DartFrame enhancements.
///
/// This runner executes various performance tests and generates detailed
/// reports on the effectiveness of performance optimizations.
class PerformanceTestRunner {
  final List<PerformanceTest> _tests = [];
  final List<PerformanceResult> _results = [];

  /// Adds a performance test to the runner.
  void addTest(PerformanceTest test) {
    _tests.add(test);
  }

  /// Runs all registered performance tests.
  Future<void> runAllTests() async {
    print('=== DARTFRAME PERFORMANCE TEST SUITE ===\n');
    print('Running ${_tests.length} performance tests...\n');

    for (int i = 0; i < _tests.length; i++) {
      PerformanceTest test = _tests[i];
      print('Running test ${i + 1}/${_tests.length}: ${test.name}');

      try {
        PerformanceResult result = await test.run();
        _results.add(result);
        print('✓ ${test.name} completed in ${result.executionTime}ms');

        if (result.memoryUsage != null) {
          print('  Memory usage: ${_formatBytes(result.memoryUsage!)}');
        }

        if (result.additionalMetrics.isNotEmpty) {
          result.additionalMetrics.forEach((key, value) {
            print('  $key: $value');
          });
        }
      } catch (e) {
        print('✗ ${test.name} failed: $e');
        _results.add(PerformanceResult(
          testName: test.name,
          executionTime: -1,
          success: false,
          errorMessage: e.toString(),
        ));
      }

      print('');
    }

    _generateReport();
  }

  /// Generates a comprehensive performance report.
  void _generateReport() {
    print('=== PERFORMANCE TEST RESULTS ===\n');

    List<PerformanceResult> successfulResults =
        _results.where((r) => r.success).toList();
    List<PerformanceResult> failedResults =
        _results.where((r) => !r.success).toList();

    print('Summary:');
    print('- Total tests: ${_results.length}');
    print('- Successful: ${successfulResults.length}');
    print('- Failed: ${failedResults.length}');
    print(
        '- Success rate: ${(successfulResults.length / _results.length * 100).toStringAsFixed(1)}%\n');

    if (successfulResults.isNotEmpty) {
      _printSuccessfulResults(successfulResults);
    }

    if (failedResults.isNotEmpty) {
      _printFailedResults(failedResults);
    }

    _printPerformanceAnalysis(successfulResults);

    // Save detailed report to file
    _saveReportToFile();
  }

  void _printSuccessfulResults(List<PerformanceResult> results) {
    print('Successful Tests:');
    print('================');

    results.sort((a, b) => a.executionTime.compareTo(b.executionTime));

    for (PerformanceResult result in results) {
      print('${result.testName}:');
      print('  Execution time: ${result.executionTime}ms');

      if (result.memoryUsage != null) {
        print('  Memory usage: ${_formatBytes(result.memoryUsage!)}');
      }

      if (result.throughput != null) {
        print('  Throughput: ${result.throughput!.toStringAsFixed(2)} ops/sec');
      }

      result.additionalMetrics.forEach((key, value) {
        print('  $key: $value');
      });

      print('');
    }
  }

  void _printFailedResults(List<PerformanceResult> results) {
    print('Failed Tests:');
    print('=============');

    for (PerformanceResult result in results) {
      print('${result.testName}:');
      print('  Error: ${result.errorMessage}');
      print('');
    }
  }

  void _printPerformanceAnalysis(List<PerformanceResult> results) {
    if (results.isEmpty) return;

    print('Performance Analysis:');
    print('====================');

    // Execution time analysis
    List<int> executionTimes = results.map((r) => r.executionTime).toList();
    executionTimes.sort();

    double avgTime =
        executionTimes.reduce((a, b) => a + b) / executionTimes.length;
    int medianTime = executionTimes[executionTimes.length ~/ 2];
    int minTime = executionTimes.first;
    int maxTime = executionTimes.last;

    print('Execution Times:');
    print('  Average: ${avgTime.toStringAsFixed(2)}ms');
    print('  Median: ${medianTime}ms');
    print('  Min: ${minTime}ms');
    print('  Max: ${maxTime}ms');

    // Memory usage analysis
    List<int> memoryUsages = results
        .where((r) => r.memoryUsage != null)
        .map((r) => r.memoryUsage!)
        .toList();

    if (memoryUsages.isNotEmpty) {
      memoryUsages.sort();
      double avgMemory =
          memoryUsages.reduce((a, b) => a + b) / memoryUsages.length;
      int medianMemory = memoryUsages[memoryUsages.length ~/ 2];

      print('Memory Usage:');
      print('  Average: ${_formatBytes(avgMemory.round())}');
      print('  Median: ${_formatBytes(medianMemory)}');
      print('  Min: ${_formatBytes(memoryUsages.first)}');
      print('  Max: ${_formatBytes(memoryUsages.last)}');
    }

    // Throughput analysis
    List<double> throughputs = results
        .where((r) => r.throughput != null)
        .map((r) => r.throughput!)
        .toList();

    if (throughputs.isNotEmpty) {
      throughputs.sort();
      double avgThroughput =
          throughputs.reduce((a, b) => a + b) / throughputs.length;
      double medianThroughput = throughputs[throughputs.length ~/ 2];

      print('Throughput:');
      print('  Average: ${avgThroughput.toStringAsFixed(2)} ops/sec');
      print('  Median: ${medianThroughput.toStringAsFixed(2)} ops/sec');
      print('  Min: ${throughputs.first.toStringAsFixed(2)} ops/sec');
      print('  Max: ${throughputs.last.toStringAsFixed(2)} ops/sec');
    }

    print('');
  }

  void _saveReportToFile() {
    try {
      final file = File('benchmark/performance_report.txt');
      final buffer = StringBuffer();

      buffer.writeln('DartFrame Performance Test Report');
      buffer.writeln('Generated: ${DateTime.now()}');
      buffer.writeln('=' * 50);
      buffer.writeln();

      buffer.writeln('Test Summary:');
      buffer.writeln('Total tests: ${_results.length}');
      buffer.writeln('Successful: ${_results.where((r) => r.success).length}');
      buffer.writeln('Failed: ${_results.where((r) => !r.success).length}');
      buffer.writeln();

      buffer.writeln('Detailed Results:');
      buffer.writeln('-' * 20);

      for (PerformanceResult result in _results) {
        buffer.writeln('${result.testName}:');
        buffer.writeln('  Success: ${result.success}');
        buffer.writeln('  Execution time: ${result.executionTime}ms');

        if (result.memoryUsage != null) {
          buffer
              .writeln('  Memory usage: ${_formatBytes(result.memoryUsage!)}');
        }

        if (result.throughput != null) {
          buffer.writeln(
              '  Throughput: ${result.throughput!.toStringAsFixed(2)} ops/sec');
        }

        if (result.errorMessage != null) {
          buffer.writeln('  Error: ${result.errorMessage}');
        }

        result.additionalMetrics.forEach((key, value) {
          buffer.writeln('  $key: $value');
        });

        buffer.writeln();
      }

      file.writeAsStringSync(buffer.toString());
      print('Detailed report saved to: ${file.path}');
    } catch (e) {
      print('Failed to save report to file: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Abstract base class for performance tests.
abstract class PerformanceTest {
  final String name;
  final String description;

  PerformanceTest(this.name, this.description);

  /// Runs the performance test and returns the result.
  Future<PerformanceResult> run();
}

/// Result of a performance test.
class PerformanceResult {
  final String testName;
  final int executionTime; // in milliseconds
  final bool success;
  final int? memoryUsage; // in bytes
  final double? throughput; // operations per second
  final String? errorMessage;
  final Map<String, dynamic> additionalMetrics;

  PerformanceResult({
    required this.testName,
    required this.executionTime,
    this.success = true,
    this.memoryUsage,
    this.throughput,
    this.errorMessage,
    this.additionalMetrics = const {},
  });
}

/// Vectorized operations performance test.
class VectorizedOperationsTest extends PerformanceTest {
  final int dataSize;

  VectorizedOperationsTest(this.dataSize)
      : super(
          'Vectorized Operations Test (size: $dataSize)',
          'Tests performance of vectorized operations vs traditional approaches',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    // Create test data
    final series = Series(
      List.generate(dataSize, (i) => Random().nextDouble() * 100),
      name: 'test_series',
    );

    int memoryBefore = series.memoryUsage;

    // Test vectorized operations
    final doubled = await series.vectorizedApply((x) => x * 2);
    final compared = series.vectorizedComparison(50.0, '>');
    final aggregated = series.vectorizedAggregation(['sum', 'mean', 'std']);

    stopwatch.stop();

    int memoryAfter = doubled.memoryUsage + compared.memoryUsage;
    double throughput = (dataSize * 3) /
        (stopwatch.elapsedMicroseconds / 1000000); // 3 operations

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      memoryUsage: memoryAfter,
      throughput: throughput,
      additionalMetrics: {
        'data_size': dataSize,
        'operations_performed': 3,
        'memory_before': memoryBefore,
        'memory_after': memoryAfter,
        'sum_result': aggregated['sum'],
        'mean_result': aggregated['mean'],
        'std_result': aggregated['std'],
      },
    );
  }
}

/// Memory optimization performance test.
class MemoryOptimizationTest extends PerformanceTest {
  final int dataSize;

  MemoryOptimizationTest(this.dataSize)
      : super(
          'Memory Optimization Test (size: $dataSize)',
          'Tests effectiveness of memory optimization techniques',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    // Create DataFrame with inefficient data types
    final data = {
      'integers_as_doubles':
          List.generate(dataSize, (i) => (i % 1000).toDouble()),
      'small_integers': List.generate(dataSize, (i) => i % 128),
      'large_integers': List.generate(dataSize, (i) => i * 10000),
      'actual_doubles':
          List.generate(dataSize, (i) => Random().nextDouble() * 100),
    };

    final originalDf = DataFrame.fromMap(data);
    int memoryBefore = originalDf.memoryUsage;

    // Optimize memory
    final optimizedDf = originalDf.optimizeMemory();
    int memoryAfter = optimizedDf.memoryUsage;

    stopwatch.stop();

    double optimizationRatio = memoryAfter / memoryBefore;
    double memorySaved = (memoryBefore - memoryAfter) / memoryBefore * 100;

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      memoryUsage: memoryAfter,
      additionalMetrics: {
        'data_size': dataSize,
        'memory_before': memoryBefore,
        'memory_after': memoryAfter,
        'optimization_ratio': optimizationRatio,
        'memory_saved_percent': memorySaved,
        'rows': originalDf.rowCount,
        'columns': originalDf.columnCount,
      },
    );
  }
}

/// Cache performance test.
class CachePerformanceTest extends PerformanceTest {
  final int operationCount;

  CachePerformanceTest(this.operationCount)
      : super(
          'Cache Performance Test (operations: $operationCount)',
          'Tests effectiveness of caching mechanisms',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    CacheManager.clearCache();

    int cacheHits = 0;
    int cacheMisses = 0;

    // Simulate expensive operations with caching
    for (int i = 0; i < operationCount; i++) {
      String key = 'operation_${i % 10}'; // Reuse keys to test cache hits

      CacheManager.cacheOperation(key, () {
        cacheMisses++;
        // Simulate expensive computation
        double value = 0;
        for (int j = 0; j < 1000; j++) {
          value += sqrt(j.toDouble());
        }
        return 'result_$value';
      });

      if (i % 10 != i) cacheHits++; // Approximate cache hits
    }

    stopwatch.stop();

    final stats = CacheManager.getCacheStats();
    double hitRatio = cacheHits / operationCount;
    double throughput =
        operationCount / (stopwatch.elapsedMicroseconds / 1000000);

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      throughput: throughput,
      additionalMetrics: {
        'operation_count': operationCount,
        'cache_hits': cacheHits,
        'cache_misses': cacheMisses,
        'hit_ratio': hitRatio,
        'cache_entries': stats.totalEntries,
        'cache_size': stats.totalSize,
      },
    );
  }
}

/// Parallel processing performance test.
class ParallelProcessingTest extends PerformanceTest {
  final int dataSize;
  final bool useParallel;

  ParallelProcessingTest(this.dataSize, this.useParallel)
      : super(
          'Parallel Processing Test (size: $dataSize, parallel: $useParallel)',
          'Tests performance of parallel vs sequential processing',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    // Create test data
    final series = Series(
      List.generate(dataSize, (i) => Random().nextDouble() * 100),
      name: 'test_series',
    );

    // Expensive computation function
    dynamic expensiveFunc(dynamic x) {
      double result = x;
      for (int i = 0; i < 100; i++) {
        result = sqrt(result * result + 1);
      }
      return result;
    }

    // Apply function with or without parallelization
    final result = await series.vectorizedApply(
      expensiveFunc,
      parallel: useParallel,
      chunkSize: 1000,
    );

    stopwatch.stop();

    double throughput = dataSize / (stopwatch.elapsedMicroseconds / 1000000);

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      memoryUsage: result.memoryUsage,
      throughput: throughput,
      additionalMetrics: {
        'data_size': dataSize,
        'parallel_processing': useParallel,
        'chunk_size': useParallel ? 1000 : dataSize,
        'result_length': result.length,
      },
    );
  }
}

/// Main function to run all performance tests.
void main() async {
  final runner = PerformanceTestRunner();

  // Add vectorized operations tests
  runner.addTest(VectorizedOperationsTest(1000));
  runner.addTest(VectorizedOperationsTest(10000));
  runner.addTest(VectorizedOperationsTest(100000));

  // Add memory optimization tests
  runner.addTest(MemoryOptimizationTest(1000));
  runner.addTest(MemoryOptimizationTest(5000));
  runner.addTest(MemoryOptimizationTest(10000));

  // Add cache performance tests
  runner.addTest(CachePerformanceTest(100));
  runner.addTest(CachePerformanceTest(500));
  runner.addTest(CachePerformanceTest(1000));

  // Add parallel processing tests
  runner.addTest(ParallelProcessingTest(1000, false)); // Sequential
  runner.addTest(ParallelProcessingTest(1000, true)); // Parallel
  runner.addTest(ParallelProcessingTest(5000, false)); // Sequential
  runner.addTest(ParallelProcessingTest(5000, true)); // Parallel

  // Run all tests
  await runner.runAllTests();
}
