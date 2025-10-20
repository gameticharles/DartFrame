import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame Rolling Operations', () {
    late DataFrame df;
    late DataFrame dfWithMissing;
    late DataFrame smallDf;
    late DataFrame largeDf;

    setUp(() {
      // Basic numeric DataFrame
      df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
        [10, 11, 12],
        [13, 14, 15]
      ], columns: [
        'A',
        'B',
        'C'
      ]);

      // DataFrame with missing values
      dfWithMissing = DataFrame([
        [1, 2, null],
        [4, null, 6],
        [null, 8, 9],
        [10, 11, 12],
        [13, 14, 15]
      ], columns: [
        'A',
        'B',
        'C'
      ]);

      // Small DataFrame for edge case testing
      smallDf = DataFrame([
        [1, 2],
        [3, 4]
      ], columns: [
        'X',
        'Y'
      ]);

      // Large DataFrame for performance testing
      var largeData = <List<dynamic>>[];
      for (int i = 0; i < 1000; i++) {
        largeData.add([i, i * 2, i * 3, i * 4, i * 5]);
      }
      largeDf = DataFrame(largeData, columns: ['A', 'B', 'C', 'D', 'E']);
    });

    group('rollingWindow() creation', () {
      test('creates RollingDataFrame object with valid parameters', () {
        var rolling = df.rollingWindow(3);
        expect(rolling, isA<RollingDataFrame>());
        expect(rolling.window, equals(3));
      });

      test('throws error for invalid window size', () {
        expect(() => df.rollingWindow(0), throwsArgumentError);
        expect(() => df.rollingWindow(-1), throwsArgumentError);
        expect(() => df.rollingWindow(10),
            throwsArgumentError); // Larger than DataFrame
      });

      test('accepts optional parameters', () {
        var rolling = df.rollingWindow(3, minPeriods: 2, center: true);
        expect(rolling.window, equals(3));
        expect(rolling.minPeriods, equals(2));
        expect(rolling.center, isTrue);
      });

      test('throws error for invalid minPeriods', () {
        expect(() => df.rollingWindow(3, minPeriods: 0), throwsArgumentError);
        expect(() => df.rollingWindow(3, minPeriods: -1), throwsArgumentError);
      });
    });

    group('Rolling calculations with different window sizes', () {
      test('window size 2 - mean calculation', () {
        var rolling = df.rollingWindow(2);
        var result = rolling.mean();

        // First value should be missing
        expect(result.iloc(0, 0), isNull);
        expect(result.iloc(0, 1), isNull);
        expect(result.iloc(0, 2), isNull);

        // Second value: mean of [1,4], [2,5], [3,6]
        expect(result.iloc(1, 0), equals(2.5)); // (1+4)/2
        expect(result.iloc(1, 1), equals(3.5)); // (2+5)/2
        expect(result.iloc(1, 2), equals(4.5)); // (3+6)/2

        // Third value: mean of [4,7], [5,8], [6,9]
        expect(result.iloc(2, 0), equals(5.5)); // (4+7)/2
        expect(result.iloc(2, 1), equals(6.5)); // (5+8)/2
        expect(result.iloc(2, 2), equals(7.5)); // (6+9)/2
      });

      test('window size 3 - sum calculation', () {
        var rolling = df.rollingWindow(3);
        var result = rolling.sum();

        // First two values should be missing
        expect(result.iloc(0, 0), isNull);
        expect(result.iloc(1, 0), isNull);

        // Third value: sum of [1,4,7], [2,5,8], [3,6,9]
        expect(result.iloc(2, 0), equals(12)); // 1+4+7
        expect(result.iloc(2, 1), equals(15)); // 2+5+8
        expect(result.iloc(2, 2), equals(18)); // 3+6+9

        // Fourth value: sum of [4,7,10], [5,8,11], [6,9,12]
        expect(result.iloc(3, 0), equals(21)); // 4+7+10
        expect(result.iloc(3, 1), equals(24)); // 5+8+11
        expect(result.iloc(3, 2), equals(27)); // 6+9+12
      });

      test('window size 4 - standard deviation calculation', () {
        var rolling = df.rollingWindow(4);
        var result = rolling.std();

        // First three values should be missing
        expect(result.iloc(0, 0), isNull);
        expect(result.iloc(1, 0), isNull);
        expect(result.iloc(2, 0), isNull);

        // Fourth value: std of [1,4,7,10]
        // Mean = 5.5, variance = ((1-5.5)^2 + (4-5.5)^2 + (7-5.5)^2 + (10-5.5)^2) / 3
        // = (20.25 + 2.25 + 2.25 + 20.25) / 3 = 15
        // std = sqrt(15) ≈ 3.873
        expect(result.iloc(3, 0), closeTo(3.873, 0.01));
      });

      test('window size 5 - variance calculation', () {
        var rolling = df.rollingWindow(5);
        var result = rolling.variance();

        // Only the last value should have a result (all 5 values)
        expect(result.iloc(0, 0), isNull);
        expect(result.iloc(1, 0), isNull);
        expect(result.iloc(2, 0), isNull);
        expect(result.iloc(3, 0), isNull);

        // Fifth value: variance of [1,4,7,10,13]
        // Mean = 7, variance = ((1-7)^2 + (4-7)^2 + (7-7)^2 + (10-7)^2 + (13-7)^2) / 4
        // = (36 + 9 + 0 + 9 + 36) / 4 = 22.5
        expect(result.iloc(4, 0), closeTo(22.5, 0.01));
      });
    });

    group('Edge cases with small datasets', () {
      test('window size equal to DataFrame size', () {
        var rolling = smallDf.rollingWindow(2);
        var result = rolling.mean();

        expect(result.iloc(0, 0), isNull);
        expect(result.iloc(0, 1), isNull);

        expect(result.iloc(1, 0), equals(2.0)); // (1+3)/2
        expect(result.iloc(1, 1), equals(3.0)); // (2+4)/2
      });

      test('single row DataFrame', () {
        var singleRowDf = DataFrame([
          [1, 2, 3]
        ], columns: [
          'A',
          'B',
          'C'
        ]);
        var rolling = singleRowDf.rollingWindow(1);
        var result = rolling.mean();

        expect(result.iloc(0, 0), equals(1));
        expect(result.iloc(0, 1), equals(2));
        expect(result.iloc(0, 2), equals(3));
      });

      test('minPeriods parameter with small dataset', () {
        var rolling = smallDf.rollingWindow(2, minPeriods: 1);
        var result = rolling.mean();

        // With minPeriods=1, should have values even with insufficient window
        expect(result.iloc(0, 0), equals(1.0)); // mean of [1]
        expect(result.iloc(0, 1), equals(2.0)); // mean of [2]

        expect(result.iloc(1, 0), equals(2.0)); // mean of [1,3]
        expect(result.iloc(1, 1), equals(3.0)); // mean of [2,4]
      });
    });

    group('Missing data handling', () {
      test('rolling mean with missing values', () {
        var rolling = dfWithMissing.rollingWindow(3);
        var result = rolling.mean();

        // Third row: [1,4,null], [2,null,8], [null,6,9]
        expect(result.iloc(2, 0), equals(2.5)); // mean of [1,4] (null ignored)
        expect(result.iloc(2, 1), equals(5.0)); // mean of [2,8] (null ignored)
        expect(result.iloc(2, 2), equals(7.5)); // mean of [6,9] (null ignored)
      });

      test('rolling operations skip missing values correctly', () {
        var rolling = dfWithMissing.rollingWindow(2);
        var result = rolling.sum();

        // Second row: [1,4], [2,null], [null,6]
        expect(result.iloc(1, 0), equals(5)); // 1+4
        expect(result.iloc(1, 1), equals(2)); // only 2 (null ignored)
        expect(result.iloc(1, 2), equals(6)); // only 6 (null ignored)
      });
    });

    group('Advanced rolling operations', () {
      test('rolling min and max', () {
        var rolling = df.rollingWindow(3);
        var minResult = rolling.min();
        var maxResult = rolling.max();

        // Third row: min/max of [1,4,7], [2,5,8], [3,6,9]
        expect(minResult.iloc(2, 0), equals(1));
        expect(minResult.iloc(2, 1), equals(2));
        expect(minResult.iloc(2, 2), equals(3));

        expect(maxResult.iloc(2, 0), equals(7));
        expect(maxResult.iloc(2, 1), equals(8));
        expect(maxResult.iloc(2, 2), equals(9));
      });

      test('rolling median', () {
        var rolling = df.rollingWindow(3);
        var result = rolling.median();

        // Third row: median of [1,4,7], [2,5,8], [3,6,9]
        expect(result.iloc(2, 0), equals(4)); // median of [1,4,7]
        expect(result.iloc(2, 1), equals(5)); // median of [2,5,8]
        expect(result.iloc(2, 2), equals(6)); // median of [3,6,9]
      });

      test('rolling quantile', () {
        var rolling = df.rollingWindow(3);
        var result = rolling.quantile(0.5); // 50th percentile (median)

        // Should be same as median
        expect(result.iloc(2, 0), equals(4));
        expect(result.iloc(2, 1), equals(5));
        expect(result.iloc(2, 2), equals(6));
      });

      test('rolling quantile with different percentiles', () {
        var rolling = df.rollingWindow(3);
        var q25 = rolling.quantile(0.25);
        var q75 = rolling.quantile(0.75);

        // For [1,4,7]: 25th percentile ≈ 2.5, 75th percentile ≈ 5.5
        expect(q25.iloc(2, 0), closeTo(2.5, 0.1));
        expect(q75.iloc(2, 0), closeTo(5.5, 0.1));
      });

      test('rolling skewness and kurtosis', () {
        var rolling = df.rollingWindow(4);
        var skewResult = rolling.skew();
        var kurtResult = rolling.kurt();

        // Should have values starting from 4th row
        expect(skewResult.iloc(0, 0), isNull);
        expect(skewResult.iloc(1, 0), isNull);
        expect(skewResult.iloc(2, 0), isNull);
        expect(skewResult.iloc(3, 0), isNotNull);

        expect(kurtResult.iloc(0, 0), isNull);
        expect(kurtResult.iloc(1, 0), isNull);
        expect(kurtResult.iloc(2, 0), isNull);
        expect(kurtResult.iloc(3, 0), isNotNull);
      });
    });

    group('Rolling correlation and covariance', () {
      test('rolling correlation with another DataFrame', () {
        var df2 = DataFrame([
          [2, 3, 4],
          [5, 6, 7],
          [8, 9, 10],
          [11, 12, 13],
          [14, 15, 16]
        ], columns: [
          'A',
          'B',
          'C'
        ]);

        var rolling = df.rollingWindow(3);
        var result = rolling.corr(other: df2);

        // Should have perfect positive correlation (1.0)
        expect(result.iloc(2, 0), closeTo(1.0, 0.01));
        expect(result.iloc(2, 1), closeTo(1.0, 0.01));
        expect(result.iloc(2, 2), closeTo(1.0, 0.01));
      });

      test('rolling covariance with another DataFrame', () {
        var df2 = DataFrame([
          [2, 4, 6],
          [8, 10, 12],
          [14, 16, 18],
          [20, 22, 24],
          [26, 28, 30]
        ], columns: [
          'A',
          'B',
          'C'
        ]);

        var rolling = df.rollingWindow(3);
        var result = rolling.cov(other: df2);

        // Should have positive covariance values
        expect(result.iloc(2, 0), greaterThan(0));
        expect(result.iloc(2, 1), greaterThan(0));
        expect(result.iloc(2, 2), greaterThan(0));
      });

      test('pairwise rolling correlation', () {
        var rolling = df.rollingWindow(3);
        var result = rolling.corr(pairwise: true);

        // Should have correlation matrix flattened
        expect(result.columns.length, equals(9)); // 3x3 matrix flattened
        expect(result.shape.rows, equals(5)); // Same number of rows as original

        // Diagonal elements should be 1.0 (self-correlation)
        expect(result.iloc(2, 0), closeTo(1.0, 0.01)); // A_A
        expect(result.iloc(2, 4), closeTo(1.0, 0.01)); // B_B
        expect(result.iloc(2, 8), closeTo(1.0, 0.01)); // C_C
      });
    });

    group('Center parameter', () {
      test('centered rolling window', () {
        var rolling = df.rollingWindow(3, center: true);
        var result = rolling.mean();

        // With center=true, the window is centered around each point
        // For row index 1 (middle of first 3 rows), should have mean of [1,4,7]
        expect(result.iloc(1, 0), equals(4.0)); // mean of [1,4,7]
        expect(result.iloc(1, 1), equals(5.0)); // mean of [2,5,8]
        expect(result.iloc(1, 2), equals(6.0)); // mean of [3,6,9]
      });
    });

    group('Custom apply function', () {
      test('apply custom aggregation function', () {
        var rolling = df.rollingWindow(3);
        var result = rolling.apply((List<num> window) {
          return window.reduce((a, b) => a > b ? a : b) -
              window.reduce((a, b) => a < b ? a : b); // range
        });

        // Third row: range of [1,4,7], [2,5,8], [3,6,9]
        expect(result.iloc(2, 0), equals(6)); // 7-1
        expect(result.iloc(2, 1), equals(6)); // 8-2
        expect(result.iloc(2, 2), equals(6)); // 9-3
      });
    });

    group('Performance with large datasets', () {
      test('rolling operations complete within reasonable time', () {
        var stopwatch = Stopwatch()..start();

        var rolling = largeDf.rollingWindow(10);
        var meanResult = rolling.mean();
        var sumResult = rolling.sum();
        var stdResult = rolling.std();

        stopwatch.stop();

        // Should complete within 5 seconds for 1000 rows
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        // Verify results are computed
        expect(meanResult.shape.rows, equals(1000));
        expect(sumResult.shape.rows, equals(1000));
        expect(stdResult.shape.rows, equals(1000));

        // Verify some calculations
        expect(meanResult.iloc(9, 0), isNotNull); // 10th row should have value
        expect(meanResult.iloc(9, 0), equals(4.5)); // mean of [0,1,2,...,9]
      });

      test('memory usage remains reasonable with large datasets', () {
        // Test that rolling operations don't cause memory issues
        var rolling = largeDf.rollingWindow(50);

        // Perform multiple operations
        var results = <DataFrame>[];
        for (int i = 0; i < 10; i++) {
          results.add(rolling.mean());
          results.add(rolling.sum());
          results.add(rolling.std());
        }

        // Should complete without memory errors
        expect(results.length, equals(30));

        // Verify last result
        var lastResult = results.last;
        expect(lastResult.shape.rows, equals(1000));
      });
    });

    group('Error handling', () {
      test('throws error for mismatched DataFrame sizes in correlation', () {
        var differentSizeDf = DataFrame([
          [1, 2],
          [3, 4]
        ], columns: [
          'A',
          'B'
        ]);

        var rolling = df.rollingWindow(2);
        expect(() => rolling.corr(other: differentSizeDf), throwsArgumentError);
      });

      test('throws error for invalid quantile values', () {
        var rolling = df.rollingWindow(3);
        expect(() => rolling.quantile(-0.1), throwsArgumentError);
        expect(() => rolling.quantile(1.1), throwsArgumentError);
      });

      test('handles DataFrame with no numeric columns', () {
        var textDf = DataFrame([
          ['a', 'b', 'c'],
          ['d', 'e', 'f'],
          ['g', 'h', 'i']
        ], columns: [
          'X',
          'Y',
          'Z'
        ]);

        var rolling = textDf.rollingWindow(2);
        var result = rolling.mean();

        // Should return DataFrame with missing values for non-numeric data
        expect(result.iloc(1, 0), isNull);
        expect(result.iloc(1, 1), isNull);
        expect(result.iloc(1, 2), isNull);
      });
    });
  });
}
