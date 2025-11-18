import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

/// Comprehensive integration tests for Week 18 features.
///
/// Tests the integration of:
/// - ArrayUtils with NDArray operations
/// - Conversions between all DartData types
/// - Profiler with operation correctness
/// - Operations on different storage backends
/// - Round-trip conversion data integrity
void main() {
  group('Week 18 Integration - ArrayUtils with NDArray Operations', () {
    test('ArrayUtils.zeros integrates with NDArray operations', () {
      final arr = ArrayUtils.zeros([3, 4]);

      expect(arr.shape.toList(), equals([3, 4]));
      expect(arr.sum(), equals(0));
      expect(arr.mean(), equals(0));

      // Test with operations
      final added = arr + 5;
      expect(added.sum(), equals(60)); // 3*4*5
    });

    test('ArrayUtils.ones integrates with NDArray operations', () {
      final arr = ArrayUtils.ones([2, 3]);

      expect(arr.sum(), equals(6));
      expect(arr.mean(), equals(1));

      // Test transpose
      final transposed = arr.transpose();
      expect(transposed.shape.toList(), equals([3, 2]));
      expect(transposed.sum(), equals(6));
    });

    test('ArrayUtils.arange integrates with axis-aware aggregations', () {
      final arr = ArrayUtils.arange(0, 12).reshape([3, 4]);

      // Test axis-aware sum
      final sumAxis0 = arr.sum(axis: 0);
      expect(sumAxis0.shape.toList(), equals([4]));
      expect(sumAxis0.toFlatList(), equals([12, 15, 18, 21]));

      final sumAxis1 = arr.sum(axis: 1);
      expect(sumAxis1.shape.toList(), equals([3]));
      expect(sumAxis1.toFlatList(), equals([6, 22, 38]));
    });

    test('ArrayUtils.random integrates with statistical operations', () {
      final arr = ArrayUtils.random([100], seed: 42);

      // Random values should be between 0 and 1
      final min = arr.min();
      final max = arr.max();
      expect(min, greaterThanOrEqualTo(0));
      expect(max, lessThan(1));

      // Mean should be around 0.5
      final mean = arr.mean();
      expect(mean, greaterThan(0.3));
      expect(mean, lessThan(0.7));
    });

    test('ArrayUtils.randomNormal integrates with transformations', () {
      final arr =
          ArrayUtils.randomNormal([10, 10], mean: 5.0, std: 2.0, seed: 123);

      // Test flatten
      final flattened = arr.flatten();
      expect(flattened.shape.toList(), equals([100]));
      expect(flattened.size, equals(100));

      // Mean should be close to 5.0
      final mean = arr.mean();
      expect(mean, greaterThan(3.0));
      expect(mean, lessThan(7.0));
    });

    test('ArrayUtils.eye integrates with matrix operations', () {
      final identity = ArrayUtils.eye(3);

      // Test properties of identity matrix
      expect(identity.getValue([0, 0]), equals(1));
      expect(identity.getValue([1, 1]), equals(1));
      expect(identity.getValue([2, 2]), equals(1));
      expect(identity.getValue([0, 1]), equals(0));

      // Sum of identity matrix equals its dimension
      expect(identity.sum(), equals(3));
    });

    test('ArrayUtils.linspace integrates with reshaping', () {
      final arr = ArrayUtils.linspace(0, 1, 12);
      final reshaped = arr.reshape([3, 4]);

      expect(reshaped.shape.toList(), equals([3, 4]));
      expect(reshaped.getValue([0, 0]), equals(0.0));
      expect(reshaped.getValue([2, 3]), closeTo(1.0, 0.001));
    });

    test('ArrayUtils.fromList and toList round-trip', () {
      final original = [
        [1, 2, 3],
        [4, 5, 6]
      ];
      final arr = ArrayUtils.fromList(original);
      final result = ArrayUtils.toList(arr);

      expect(result, equals(original));
    });
  });

  group('Week 18 Integration - DartData Type Conversions', () {
    test('NDArray -> Series -> DataFrame -> DataCube chain', () {
      final arr = ArrayUtils.arange(1, 7);

      final series = arr.toSeries();
      expect(series.length, equals(6));
      expect(series.data, equals([1, 2, 3, 4, 5, 6]));

      final df = series.toDataFrame();
      expect(df.rowCount, equals(6));
      expect(df.columnCount, equals(1));

      final cube = df.toDataCube();
      expect(cube.depth, equals(1));
      expect(cube.rows, equals(6));
      expect(cube.columns, equals(1));
    });

    test('DataCube -> NDArray -> reshape -> back to DataCube', () {
      final cube =
          DataCube.generate(2, 3, 4, (d, r, c) => d * 100 + r * 10 + c);

      final arr = cube.toNDArray();
      expect(arr.shape.toList(), equals([2, 3, 4]));

      // Reshape and convert back
      final flattened = arr.flatten();
      final reshaped = flattened.reshape([2, 3, 4]);
      final newCube = reshaped.toDataCube();

      expect(newCube.depth, equals(cube.depth));
      expect(newCube.rows, equals(cube.rows));
      expect(newCube.columns, equals(cube.columns));

      // Verify data integrity
      for (int d = 0; d < 2; d++) {
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 4; c++) {
            expect(
                newCube.getValue([d, r, c]), equals(cube.getValue([d, r, c])));
          }
        }
      }
    });

    test('Series -> NDArray -> operations -> back to Series', () {
      final series = Series([1.0, 2.0, 3.0, 4.0, 5.0], name: 'test');
      final arr = series.toNDArray();

      // Perform operations
      final doubled = arr * 2;
      final result = doubled.toSeries();

      expect(result.length, equals(5));
      expect(result.data, equals([2.0, 4.0, 6.0, 8.0, 10.0]));
    });

    test('DataFrame -> NDArray -> transpose -> back to DataFrame', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6]
      ], columns: [
        'A',
        'B',
        'C'
      ]);

      final arr = df.toNDArray();
      final transposed = arr.transpose();
      final resultDf = transposed.toDataFrame();

      expect(resultDf.rowCount, equals(3));
      expect(resultDf.columnCount, equals(2));
      expect(resultDf.iloc(0, 0), equals(1));
      expect(resultDf.iloc(0, 1), equals(4));
      expect(resultDf.iloc(2, 0), equals(3));
      expect(resultDf.iloc(2, 1), equals(6));
    });

    test('complex conversion chain preserves data', () {
      final original = ArrayUtils.arange(1, 25).reshape([2, 3, 4]);

      // NDArray -> DataCube -> DataFrame -> Series -> NDArray
      final cube = original.toDataCube();
      final df = cube.getFrame(0);
      final series = df.toSeries();
      final arr = series.toNDArray();

      // Should have first column of first frame
      expect(arr.shape.toList(), equals([3]));
      expect(arr.getValue([0]), equals(1));
      expect(arr.getValue([1]), equals(5));
      expect(arr.getValue([2]), equals(9));
    });
  });

  group('Week 18 Integration - Profiler with Operations', () {
    setUp(() {
      Profiler.reset();
      Profiler.enabled = true;
    });

    test('profiling ArrayUtils operations does not affect results', () {
      Profiler.start('zeros');
      final arr1 = ArrayUtils.zeros([10, 10]);
      Profiler.stop('zeros');

      Profiler.start('ones');
      final arr2 = ArrayUtils.ones([10, 10]);
      Profiler.stop('ones');

      // Verify results are correct
      expect(arr1.sum(), equals(0));
      expect(arr2.sum(), equals(100));

      // Verify profiling captured the operations
      final report = Profiler.getReport();
      expect(report.entries.keys, contains('zeros'));
      expect(report.entries.keys, contains('ones'));
      expect(report.entries['zeros']!.count, equals(1));
      expect(report.entries['ones']!.count, equals(1));
    });

    test('profiling NDArray operations does not affect results', () {
      final arr = ArrayUtils.arange(0, 100).reshape([10, 10]);

      Profiler.start('sum');
      final sum = arr.sum();
      Profiler.stop('sum');

      Profiler.start('mean');
      final mean = arr.mean();
      Profiler.stop('mean');

      Profiler.start('transpose');
      final transposed = arr.transpose();
      Profiler.stop('transpose');

      // Verify results
      expect(sum, equals(4950));
      expect(mean, equals(49.5));
      expect(transposed.shape.toList(), equals([10, 10]));

      // Verify profiling
      final report = Profiler.getReport();
      expect(report.entries.length, equals(3));
    });

    test('profiling conversions does not affect data integrity', () {
      final arr = ArrayUtils.arange(1, 13).reshape([3, 4]);

      Profiler.start('toDataFrame');
      final df = arr.toDataFrame();
      Profiler.stop('toDataFrame');

      Profiler.start('toNDArray');
      final backToArr = df.toNDArray();
      Profiler.stop('toNDArray');

      // Verify data integrity
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 4; j++) {
          expect(backToArr.getValue([i, j]), equals(arr.getValue([i, j])));
        }
      }

      // Verify profiling
      final report = Profiler.getReport();
      expect(report.entries['toDataFrame']!.count, equals(1));
      expect(report.entries['toNDArray']!.count, equals(1));
    });

    test('profiler accumulates statistics for repeated operations', () {
      for (int i = 0; i < 5; i++) {
        Profiler.start('operation');
        final arr = ArrayUtils.zeros([10, 10]);
        final sum = arr.sum();
        expect(sum, equals(0));
        Profiler.stop('operation');
      }

      final report = Profiler.getReport();
      final entry = report.entries['operation']!;

      expect(entry.count, equals(5));
      expect(entry.totalTime.inMicroseconds, greaterThan(0));
      expect(entry.avgTime.inMicroseconds, greaterThan(0));
      expect(entry.minTime.inMicroseconds, greaterThan(0));
      expect(entry.maxTime.inMicroseconds,
          greaterThanOrEqualTo(entry.minTime.inMicroseconds));
    });

    test('disabled profiler has no effect', () {
      Profiler.enabled = false;

      Profiler.start('test');
      final arr = ArrayUtils.ones([5, 5]);
      final sum = arr.sum();
      Profiler.stop('test');

      expect(sum, equals(25));

      final report = Profiler.getReport();
      expect(report.entries.isEmpty, isTrue);

      Profiler.enabled = true;
    });
  });

  group('Week 18 Integration - Storage Backend Consistency', () {
    test('operations produce consistent results with InMemoryBackend', () {
      // Create arrays with same data
      final data = List.generate(100, (i) => i.toDouble());

      // Create two arrays with InMemoryBackend
      final arr1 = NDArray.fromFlat(data, [10, 10]);
      final arr2 = NDArray.fromFlat(List.from(data), [10, 10]);

      // Test aggregations produce same results
      expect(arr1.sum(), equals(arr2.sum()));
      expect(arr1.mean(), equals(arr2.mean()));
      expect(arr1.min(), equals(arr2.min()));
      expect(arr1.max(), equals(arr2.max()));

      // Test element access
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
          expect(arr1.getValue([i, j]), equals(arr2.getValue([i, j])));
        }
      }
    });

    test('operations maintain consistency across transformations', () {
      final arr1 = ArrayUtils.arange(0, 24).reshape([4, 6]);
      final arr2 = NDArray.fromFlat(List.generate(24, (i) => i), [4, 6]);

      // Test transpose
      final t1 = arr1.transpose();
      final t2 = arr2.transpose();
      expect(t1.shape.toList(), equals(t2.shape.toList()));
      expect(t1.sum(), equals(t2.sum()));

      // Test flatten
      final f1 = arr1.flatten();
      final f2 = arr2.flatten();
      expect(f1.toFlatList(), equals(f2.toFlatList()));

      // Test axis-aware operations
      final s1 = arr1.sum(axis: 0);
      final s2 = arr2.sum(axis: 0);
      expect(s1.toFlatList(), equals(s2.toFlatList()));
    });

    test('conversions produce consistent results', () {
      // Create arrays from different sources
      final arr1 = ArrayUtils.arange(1, 13).reshape([3, 4]);
      final arr2 = NDArray.fromFlat(List.generate(12, (i) => i + 1), [3, 4]);

      // Convert both to DataFrame
      final df1 = arr1.toDataFrame();
      final df2 = arr2.toDataFrame();

      // Results should be identical
      expect(df1.rowCount, equals(df2.rowCount));
      expect(df1.columnCount, equals(df2.columnCount));

      // Convert back to NDArray
      final back1 = df1.toNDArray();
      final back2 = df2.toNDArray();
      expect(back1.toFlatList(), equals(back2.toFlatList()));
    });

    test('different creation methods produce consistent arrays', () {
      // Create same array using different methods
      final arr1 = ArrayUtils.full([5, 5], 3);
      final arr2 = NDArray.filled([5, 5], 3);
      final arr3 = NDArray.generate([5, 5], (_) => 3);

      // All should have same sum
      expect(arr1.sum(), equals(75));
      expect(arr2.sum(), equals(75));
      expect(arr3.sum(), equals(75));

      // All should have same shape
      expect(arr1.shape.toList(), equals([5, 5]));
      expect(arr2.shape.toList(), equals([5, 5]));
      expect(arr3.shape.toList(), equals([5, 5]));
    });
  });

  group('Week 18 Integration - Round-Trip Data Integrity', () {
    test('integer data round-trip through all types', () {
      final original = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

      // NDArray -> DataCube -> NDArray
      final arr1 = NDArray.fromFlat(original, [2, 2, 3]);
      final cube = arr1.toDataCube();
      final arr2 = cube.toNDArray();

      expect(arr2.toFlatList(), equals(original));
    });

    test('floating point data round-trip preserves precision', () {
      final original = [1.1, 2.2, 3.3, 4.4, 5.5, 6.6];

      // Series -> NDArray -> Series
      final series1 = Series(original, name: 'test');
      final arr = series1.toNDArray();
      final series2 = arr.toSeries();

      for (int i = 0; i < original.length; i++) {
        expect(series2.data[i], closeTo(original[i], 0.0001));
      }
    });

    test('mixed type data round-trip', () {
      final original = [1, 'two', 3.0, true, null, 6];

      final arr1 = NDArray(original);
      final series = arr1.toSeries();
      final df = series.toDataFrame();
      final series2 = df.toSeries();
      final arr2 = series2.toNDArray();

      expect(arr2.toFlatList(), equals(original));
    });

    test('large data round-trip maintains integrity', () {
      final size = 1000;
      final original = List.generate(size, (i) => i * 1.5);

      final arr1 = NDArray.fromFlat(original, [size]);
      final series = arr1.toSeries();
      final df = series.toDataFrame();
      final arr2 = df.toNDArray();
      final flattened = arr2.flatten();

      expect(flattened.size, equals(size));
      for (int i = 0; i < size; i++) {
        expect(flattened.getValue([i]), closeTo(original[i], 0.0001));
      }
    });

    test('3D data round-trip through multiple conversions', () {
      final arr1 = ArrayUtils.arange(0, 60).reshape([3, 4, 5]);

      // NDArray -> DataCube -> NDArray -> flatten -> reshape
      final cube = arr1.toDataCube();
      final arr2 = cube.toNDArray();
      final flat = arr2.flatten();
      final arr3 = flat.reshape([3, 4, 5]);

      // Verify all elements match
      for (int d = 0; d < 3; d++) {
        for (int r = 0; r < 4; r++) {
          for (int c = 0; c < 5; c++) {
            expect(arr3.getValue([d, r, c]), equals(arr1.getValue([d, r, c])));
          }
        }
      }
    });

    test('empty data structures round-trip correctly', () {
      // Empty Series
      final emptySeries = Series([], name: 'empty');
      final emptyDf = emptySeries.toDataFrame();
      expect(emptyDf.rowCount, equals(0));

      // Empty NDArray
      final emptyArr = NDArray.fromFlat([], [0]);
      expect(emptyArr.size, equals(0));
      final emptySeries2 = emptyArr.toSeries();
      expect(emptySeries2.length, equals(0));
    });

    test('single element round-trip', () {
      final single = [42];

      final arr = NDArray(single);
      final series = arr.toSeries();
      final df = series.toDataFrame();
      final cube = df.toDataCube();
      final backArr = cube.toNDArray();

      expect(backArr.getValue([0, 0, 0]), equals(42));
    });
  });

  group('Week 18 Integration - Complex Workflows', () {
    test('data analysis workflow with all components', () {
      // Generate random data
      final data = ArrayUtils.randomNormal([100], mean: 50, std: 10, seed: 42);

      Profiler.start('analysis');

      // Convert to Series for analysis
      final series = data.toSeries();
      expect(series.length, equals(100));

      // Statistical operations
      final mean = series.mean();
      final std = series.std();
      expect(mean, greaterThan(40));
      expect(mean, lessThan(60));
      expect(std, greaterThan(5));
      expect(std, lessThan(15));

      // Convert to DataFrame
      final df = series.toDataFrame();
      expect(df.rowCount, equals(100));

      // Back to NDArray for numerical operations
      final arr = df.toNDArray();
      final normalized = (arr - mean) / std;

      Profiler.stop('analysis');

      // Verify normalization
      final normalizedMean = normalized.mean();
      expect(normalizedMean, closeTo(0, 0.1));

      // Check profiling
      final report = Profiler.getReport();
      expect(report.entries['analysis']!.count, equals(1));
    });

    test('matrix operations workflow', () {
      // Create identity matrix
      final identity = ArrayUtils.eye(4);

      // Create data matrix
      final data = ArrayUtils.arange(1, 17).reshape([4, 4]);

      // Operations
      final sum = data + identity;
      final transposed = sum.transpose();

      // Convert to DataFrame for inspection
      final df = transposed.toDataFrame();
      expect(df.rowCount, equals(4));
      expect(df.columnCount, equals(4));

      // After transpose, check that values are correct
      // Original data matrix: [[1,2,3,4], [5,6,7,8], [9,10,11,12], [13,14,15,16]]
      // After adding identity: [[2,2,3,4], [5,7,7,8], [9,10,12,12], [13,14,15,17]]
      // After transpose: [[2,5,9,13], [2,7,10,14], [3,7,12,15], [4,8,12,17]]
      expect(df.iloc(0, 0), equals(2)); // (1+1)
      expect(df.iloc(1, 1), equals(7)); // (6+1)
      expect(df.iloc(2, 2), equals(12)); // (11+1)
      expect(df.iloc(3, 3), equals(17)); // (16+1)
    });

    test('time series simulation workflow', () {
      // Generate time series data
      final time = ArrayUtils.linspace(0, 10, 100);
      final values = ArrayUtils.randomNormal([100], mean: 0, std: 1, seed: 123);

      // Combine into DataFrame-like structure
      final timeSeries = time.toSeries();
      final valueSeries = values.toSeries();

      expect(timeSeries.length, equals(100));
      expect(valueSeries.length, equals(100));

      // Statistical analysis
      final mean = valueSeries.mean();
      final std = valueSeries.std();

      expect(mean, closeTo(0, 0.3));
      expect(std, closeTo(1, 0.3));
    });

    test('data transformation pipeline', () {
      Profiler.reset();

      // Step 1: Generate data
      Profiler.start('generate');
      final raw = ArrayUtils.arange(1, 101);
      Profiler.stop('generate');

      // Step 2: Reshape
      Profiler.start('reshape');
      final matrix = raw.reshape([10, 10]);
      Profiler.stop('reshape');

      // Step 3: Transpose
      Profiler.start('transpose');
      final transposed = matrix.transpose();
      Profiler.stop('transpose');

      // Step 4: Convert to DataCube
      Profiler.start('convert');
      final reshaped = transposed.flatten().reshape([2, 5, 10]);
      final cube = reshaped.toDataCube();
      Profiler.stop('convert');

      // Step 5: Extract and analyze
      Profiler.start('analyze');
      final frame = cube.getFrame(0);
      final series = frame.toSeries();
      final sum = series.sum();
      Profiler.stop('analyze');

      expect(sum, greaterThan(0));

      // Verify all steps were profiled
      final report = Profiler.getReport();
      expect(report.entries.length, equals(5));
      expect(report.entries.keys, contains('generate'));
      expect(report.entries.keys, contains('reshape'));
      expect(report.entries.keys, contains('transpose'));
      expect(report.entries.keys, contains('convert'));
      expect(report.entries.keys, contains('analyze'));
    });
  });

  group('Week 18 Integration - Performance Validation', () {
    test('operations complete in reasonable time', () {
      final stopwatch = Stopwatch()..start();

      // Create large arrays
      final arr1 = ArrayUtils.zeros([100, 100]);
      final arr2 = ArrayUtils.ones([100, 100]);

      // Perform operations
      final sum = arr1 + arr2;
      final transposed = sum.transpose();
      final flattened = transposed.flatten();

      // Convert between types
      final df = sum.toDataFrame();
      final cube = df.toDataCube();
      final backArr = cube.toNDArray();

      stopwatch.stop();

      // Should complete in under 5 seconds
      expect(stopwatch.elapsed.inSeconds, lessThan(5));
      // DataCube adds a depth dimension, so shape is [1, 100, 100]
      expect(backArr.shape.toList(), equals([1, 100, 100]));
    });

    test('profiler overhead is minimal', () {
      final iterations = 100;

      // Without profiling
      Profiler.enabled = false;
      final stopwatch1 = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        final arr = ArrayUtils.zeros([10, 10]);
        arr.sum();
      }
      stopwatch1.stop();
      final timeWithoutProfiling = stopwatch1.elapsedMicroseconds;

      // With profiling
      Profiler.enabled = true;
      Profiler.reset();
      final stopwatch2 = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        Profiler.start('op');
        final arr = ArrayUtils.zeros([10, 10]);
        arr.sum();
        Profiler.stop('op');
      }
      stopwatch2.stop();
      final timeWithProfiling = stopwatch2.elapsedMicroseconds;

      // Overhead should be less than 50% (generous threshold)
      final overhead =
          (timeWithProfiling - timeWithoutProfiling) / timeWithoutProfiling;
      expect(overhead, lessThan(0.5));
    });
  });
}
