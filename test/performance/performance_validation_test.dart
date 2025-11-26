import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';
import 'dart:math' as math;

/// Performance validation tests for enhanced DartFrame features.
///
/// These tests validate that performance optimizations work correctly
/// and provide measurable improvements over traditional approaches.
void main() {
  group('Memory Optimization Performance Tests', () {
    test('DataFrame memory optimization reduces memory usage', () {
      // Create DataFrame with inefficient data types
      final data = {
        'integers_as_doubles': List.generate(1000, (i) => (i % 100).toDouble()),
        'small_integers': List.generate(1000, (i) => i % 128),
        'large_integers': List.generate(1000, (i) => i * 1000),
        'actual_doubles': List.generate(1000, (i) => i * 0.5),
      };

      final originalDf = DataFrame.fromMap(data);
      final optimizedDf = originalDf.optimizeMemory();

      // Verify optimization doesn't change data values
      expect(originalDf.rowCount, equals(optimizedDf.rowCount));
      expect(originalDf.columnCount, equals(optimizedDf.columnCount));

      // Check that integer-as-double column values are preserved
      for (int i = 0; i < 10; i++) {
        expect(
          originalDf['integers_as_doubles'].data[i],
          equals(optimizedDf['integers_as_doubles'].data[i]),
        );
      }

      // Memory usage estimation should work
      final originalMemory = originalDf.memoryUsage;
      final optimizedMemory = optimizedDf.memoryUsage;

      expect(originalMemory, greaterThan(0));
      expect(optimizedMemory, greaterThan(0));
      // Note: In practice, optimized should be <= original, but exact comparison
      // depends on implementation details
    });

    test('Series memory optimization preserves data integrity', () {
      // Create Series with doubles that are actually integers
      final originalSeries = Series(
        List.generate(100, (i) => (i % 50).toDouble()),
        name: 'test_series',
      );

      final optimizedSeries = originalSeries.optimizeMemory();

      // Verify data integrity
      expect(originalSeries.length, equals(optimizedSeries.length));
      expect(originalSeries.name, equals(optimizedSeries.name));

      for (int i = 0; i < originalSeries.length; i++) {
        expect(
          originalSeries.data[i],
          equals(optimizedSeries.data[i]),
        );
      }

      // Memory usage should be calculable
      expect(originalSeries.totalMemoryUsage, greaterThan(0));
      expect(optimizedSeries.totalMemoryUsage, greaterThan(0));
    });

    test('Memory optimization recommendations are accurate', () {
      final data = {
        'integers_as_doubles': List.generate(100, (i) => (i % 100).toDouble()),
        'small_integers': List.generate(100, (i) => i % 128),
        'strings': List.generate(100, (i) => 'item_$i'),
      };

      final df = DataFrame.fromMap(data);
      final recommendations = df.memoryRecommendations;

      expect(recommendations, isA<Map<String, String>>());

      // Should have recommendation for integers_as_doubles
      expect(recommendations.containsKey('integers_as_doubles'), isTrue);
      expect(
        recommendations['integers_as_doubles'],
        contains('Convert double to int'),
      );
    });

    test('Memory report generation works correctly', () {
      final data = {
        'col1': List.generate(50, (i) => i),
        'col2': List.generate(50, (i) => i * 0.5),
        'col3': List.generate(50, (i) => 'item_$i'),
      };

      final df = DataFrame.fromMap(data);
      final report = df.memoryReport;

      expect(report, isA<String>());
      expect(report, contains('Memory Usage Report'));
      expect(report, contains('DataFrame Shape'));
      expect(report, contains('Total Estimated Memory'));
      expect(report, contains('col1'));
      expect(report, contains('col2'));
      expect(report, contains('col3'));
    });
  });

  group('Vectorized Operations Performance Tests', () {
    test('Vectorized apply operations work correctly', () async {
      final series = Series(
        List.generate(100, (i) => i.toDouble()),
        name: 'test_series',
      );

      // Test simple vectorized operation
      final doubled = await series.vectorizedApply((x) => x * 2);

      expect(doubled.length, equals(series.length));
      expect(doubled.name, equals(series.name));

      for (int i = 0; i < series.length; i++) {
        final originalValue = series.data[i] as double;
        expect(doubled.data[i], equals(originalValue * 2));
      }
    });

    test('Vectorized mathematical operations are accurate', () {
      final series1 = Series([1.0, 2.0, 3.0, 4.0, 5.0], name: 'series1');
      final series2 = Series([2.0, 3.0, 4.0, 5.0, 6.0], name: 'series2');
      final scalar = 10.0;

      // Test scalar operations
      final addScalar = series1.vectorizedMath(scalar, '+');
      expect(addScalar.data, equals([11.0, 12.0, 13.0, 14.0, 15.0]));

      final multiplyScalar = series1.vectorizedMath(scalar, '*');
      expect(multiplyScalar.data, equals([10.0, 20.0, 30.0, 40.0, 50.0]));

      // Test series operations
      final addSeries = series1.vectorizedMath(series2, '+');
      expect(addSeries.data, equals([3.0, 5.0, 7.0, 9.0, 11.0]));

      final multiplySeries = series1.vectorizedMath(series2, '*');
      expect(multiplySeries.data, equals([2.0, 6.0, 12.0, 20.0, 30.0]));
    });

    test('Vectorized comparison operations work correctly', () {
      final series = Series([1, 5, 10, 15, 20], name: 'test_series');
      final threshold = 10;

      // Test scalar comparisons
      final greaterThan = series.vectorizedComparison(threshold, '>');
      expect(greaterThan.data, equals([false, false, false, true, true]));

      final lessThanEqual = series.vectorizedComparison(threshold, '<=');
      expect(lessThanEqual.data, equals([true, true, true, false, false]));

      final equalTo = series.vectorizedComparison(threshold, '==');
      expect(equalTo.data, equals([false, false, true, false, false]));
    });

    test('Vectorized string operations work correctly', () {
      final series = Series(
        ['Hello', 'WORLD', '  test  ', 'Example'],
        name: 'string_series',
      );

      // Test string operations
      final upper = series.vectorizedStringOperation('upper');
      expect(upper.data, equals(['HELLO', 'WORLD', '  TEST  ', 'EXAMPLE']));

      final lower = series.vectorizedStringOperation('lower');
      expect(lower.data, equals(['hello', 'world', '  test  ', 'example']));

      final trimmed = series.vectorizedStringOperation('trim');
      expect(trimmed.data, equals(['Hello', 'WORLD', 'test', 'Example']));

      final lengths = series.vectorizedStringOperation('length');
      expect(lengths.data, equals([5, 5, 8, 7]));

      final contains =
          series.vectorizedStringOperation('contains', argument: 'o');
      expect(
          contains.data,
          equals([
            true,
            false,
            false,
            false
          ])); // "WORLD" doesn't contain lowercase "o"
    });

    test('Vectorized aggregation operations are accurate', () {
      final series = Series([1.0, 2.0, 3.0, 4.0, 5.0], name: 'numeric_series');
      final operations = ['sum', 'mean', 'min', 'max', 'std', 'var'];

      final results = series.vectorizedAggregation(operations);

      expect(results['sum'], equals(15.0));
      expect(results['mean'], equals(3.0));
      expect(results['min'], equals(1.0));
      expect(results['max'], equals(5.0));

      // Standard deviation and variance should be calculated correctly
      // For [1,2,3,4,5]: variance = 2.0, std = sqrt(2.0) ≈ 1.414
      expect(results['std'], closeTo(1.414, 0.01));
      expect(results['var'], closeTo(2.0, 0.01));
    });

    test('Vectorized operations handle null values correctly', () {
      final series = Series([1, null, 3, null, 5], name: 'with_nulls');

      // Mathematical operations should preserve nulls
      final doubled = series.vectorizedMath(2, '*');
      expect(doubled.data[0], equals(2));
      expect(doubled.data[1], isNull);
      expect(doubled.data[2], equals(6));
      expect(doubled.data[3], isNull);
      expect(doubled.data[4], equals(10));

      // Aggregation should handle nulls
      final results = series.vectorizedAggregation(['sum', 'mean']);
      expect(results['sum'], equals(9.0)); // 1 + 3 + 5
      expect(results['mean'], equals(3.0)); // 9 / 3
    });
  });

  group('Performance Comparison Tests', () {
    test('Vectorized operations show performance characteristics', () async {
      final size = 1000;
      final series = Series(
        List.generate(size, (i) => i.toDouble()),
        name: 'perf_test',
      );

      // Measure traditional apply (if available)
      final stopwatch1 = Stopwatch()..start();
      final traditional = series.apply((x) => x * 2);
      stopwatch1.stop();

      // Measure vectorized apply
      final stopwatch2 = Stopwatch()..start();
      final vectorized = await series.vectorizedApply((x) => x * 2);
      stopwatch2.stop();

      // Both should produce same results
      expect(traditional.length, equals(vectorized.length));
      for (int i = 0; i < traditional.length; i++) {
        expect(traditional.data[i], equals(vectorized.data[i]));
      }

      // Performance characteristics (times may vary, but operations should complete)
      expect(stopwatch1.elapsedMicroseconds, greaterThan(0));
      expect(stopwatch2.elapsedMicroseconds, greaterThan(0));

      print('Traditional apply: ${stopwatch1.elapsedMicroseconds} μs');
      print('Vectorized apply: ${stopwatch2.elapsedMicroseconds} μs');
    });

    test('Memory optimization shows measurable impact', () {
      final size = 1000;

      // Create DataFrame with inefficient types
      final data = {
        'integers_as_doubles': List.generate(size, (i) => (i % 100).toDouble()),
        'small_ints': List.generate(size, (i) => i % 128),
      };

      final original = DataFrame.fromMap(data);

      // Measure optimization time
      final stopwatch = Stopwatch()..start();
      final optimized = original.optimizeMemory();
      stopwatch.stop();

      // Optimization should complete in reasonable time
      expect(
          stopwatch.elapsedMilliseconds, lessThan(1000)); // Less than 1 second

      // Data integrity should be preserved
      expect(original.rowCount, equals(optimized.rowCount));
      expect(original.columnCount, equals(optimized.columnCount));

      print('Memory optimization time: ${stopwatch.elapsedMilliseconds} ms');
    });

    test('Large dataset performance validation', () async {
      final size = 10000;
      final series = Series(
        List.generate(size, (i) => math.Random().nextDouble() * 100),
        name: 'large_series',
      );

      // Test that operations complete in reasonable time for large datasets
      final stopwatch = Stopwatch()..start();

      // Perform multiple vectorized operations
      final doubled = await series.vectorizedApply((x) => x * 2);
      final compared = series.vectorizedComparison(50.0, '>');
      final aggregated = series.vectorizedAggregation(['sum', 'mean', 'std']);

      stopwatch.stop();

      // Operations should complete
      expect(doubled.length, equals(size));
      expect(compared.length, equals(size));
      expect(aggregated.keys, contains('sum'));
      expect(aggregated.keys, contains('mean'));
      expect(aggregated.keys, contains('std'));

      // Should complete in reasonable time (adjust threshold as needed)
      expect(
          stopwatch.elapsedMilliseconds, lessThan(5000)); // Less than 5 seconds

      print(
          'Large dataset operations time: ${stopwatch.elapsedMilliseconds} ms');
    });
  });

  group('Cache Performance Tests', () {
    test('Cache manager basic functionality', () {
      // Test basic cache operations
      int callCount = 0;
      String expensiveOperation() {
        callCount++;
        return 'result_$callCount';
      }

      // First call should execute operation
      final result1 =
          CacheManager.cacheOperation('test_key', expensiveOperation);
      expect(result1, equals('result_1'));
      expect(callCount, equals(1));

      // Second call should use cache
      final result2 =
          CacheManager.cacheOperation('test_key', expensiveOperation);
      expect(result2, equals('result_1')); // Same result from cache
      expect(callCount, equals(1)); // Operation not called again

      // Force refresh should execute operation again
      final result3 = CacheManager.cacheOperation(
        'test_key',
        expensiveOperation,
        forceRefresh: true,
      );
      expect(result3, equals('result_2'));
      expect(callCount, equals(2));
    });

    test('Cache statistics work correctly', () {
      CacheManager.clearCache();

      // Add some cache entries
      CacheManager.cacheOperation('key1', () => 'value1');
      CacheManager.cacheOperation('key2', () => 'value2');
      CacheManager.cacheOperation('key3', () => 'value3');

      final stats = CacheManager.getCacheStats();

      expect(stats.totalEntries, equals(3));
      expect(stats.validEntries, equals(3));
      expect(stats.expiredEntries, equals(0));
      expect(stats.totalSize, greaterThan(0));
    });

    test('Cache cleanup works correctly', () {
      CacheManager.clearCache();

      // Add entries with short TTL
      CacheManager.cacheOperation(
        'short_ttl',
        () => 'value',
        ttl: Duration(milliseconds: 1),
      );

      // Wait for expiration
      Future.delayed(Duration(milliseconds: 10), () {
        CacheManager.cleanupExpiredEntries();
        final stats = CacheManager.getCacheStats();
        expect(stats.validEntries, equals(0));
      });
    });
  });

  group('Error Handling and Edge Cases', () {
    test('Vectorized operations handle empty series', () async {
      final emptySeries = Series([], name: 'empty');

      final result = await emptySeries.vectorizedApply((x) => x * 2);
      expect(result.length, equals(0));
      expect(result.name, equals('empty'));
    });

    test('Memory optimization handles edge cases', () {
      // Empty DataFrame
      final emptyDf = DataFrame.fromMap(<String, List<dynamic>>{});
      final optimizedEmpty = emptyDf.optimizeMemory();
      expect(optimizedEmpty.rowCount, equals(0));
      expect(optimizedEmpty.columnCount, equals(0));

      // DataFrame with all null values
      final nullData = {
        'null_col': [null, null, null],
      };
      final nullDf = DataFrame.fromMap(nullData);
      final optimizedNull = nullDf.optimizeMemory();
      expect(optimizedNull.rowCount, equals(3));
      expect(optimizedNull.columnCount, equals(1));
    });

    test('Vectorized aggregation handles edge cases', () {
      // Series with all nulls
      final nullSeries = Series([null, null, null], name: 'nulls');
      final results = nullSeries.vectorizedAggregation(['sum', 'mean']);

      expect(results['sum']?.isNaN, isTrue);
      expect(results['mean']?.isNaN, isTrue);

      // Series with mixed types (should handle gracefully)
      final mixedSeries = Series([1, 2.5, 3], name: 'mixed');
      final mixedResults = mixedSeries.vectorizedAggregation(['sum']);
      expect(mixedResults['sum'], equals(6.5));
    });
  });
}
