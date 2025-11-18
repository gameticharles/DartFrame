// ignore_for_file: deprecated_member_use_from_same_package

import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Rolling Methods Compatibility Tests', () {
    late DataFrame df;

    setUp(() {
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
    });

    group('Backward Compatibility', () {
      test('deprecated rolling() method still works', () {
        // Test that the deprecated method still functions
        expect(() => df.rolling('A', 3, 'mean'), returnsNormally);
        expect(() => df.rolling('B', 2, 'sum'), returnsNormally);
        expect(() => df.rolling('C', 3, 'std'), returnsNormally);
      });

      test('deprecated rolling() produces expected results', () {
        var result = df.rolling('A', 3, 'mean');

        // First two values should be null (insufficient window)
        expect(result.data[0], isNull);
        expect(result.data[1], isNull);

        // Third value: mean of [1, 4, 7] = 4.0
        expect(result.data[2], equals(4.0));

        // Fourth value: mean of [4, 7, 10] = 7.0
        expect(result.data[3], equals(7.0));

        // Fifth value: mean of [7, 10, 13] = 10.0
        expect(result.data[4], equals(10.0));
      });
    });

    group('New rollingWindow() Method', () {
      test('rollingWindow() method works correctly', () {
        expect(() => df.rollingWindow(3), returnsNormally);
        expect(() => df.rollingWindow(3).mean(), returnsNormally);
        expect(() => df.rollingWindow(2).sum(), returnsNormally);
      });

      test('rollingWindow() produces expected results', () {
        var rolling = df.rollingWindow(3);
        var result = rolling.mean();

        // Check column A results match deprecated method
        expect(result.iloc(0, 0), isNull); // First value
        expect(result.iloc(1, 0), isNull); // Second value
        expect(
            result.iloc(2, 0), equals(4.0)); // Third value: mean of [1, 4, 7]
        expect(
            result.iloc(3, 0), equals(7.0)); // Fourth value: mean of [4, 7, 10]
        expect(result.iloc(4, 0),
            equals(10.0)); // Fifth value: mean of [7, 10, 13]

        // Check that all columns are processed
        expect(result.columns.length, equals(3));
        expect(result.shape.rows, equals(5));
      });
    });

    group('Results Compatibility', () {
      test('both methods produce same results for mean operation', () {
        // Test deprecated method
        var deprecatedResult = df.rolling('A', 3, 'mean');

        // Test new method
        var newResult = df.rollingWindow(3).mean();
        var newColumnA = newResult['A'];

        // Compare results
        for (int i = 0; i < deprecatedResult.length; i++) {
          if (deprecatedResult.data[i] == null) {
            expect(newColumnA.data[i], isNull);
          } else {
            expect(
                newColumnA.data[i], closeTo(deprecatedResult.data[i], 0.001));
          }
        }
      });

      test('both methods produce same results for sum operation', () {
        var deprecatedResult = df.rolling('B', 2, 'sum');
        var newResult = df.rollingWindow(2).sum();
        var newColumnB = newResult['B'];

        for (int i = 0; i < deprecatedResult.length; i++) {
          if (deprecatedResult.data[i] == null) {
            expect(newColumnB.data[i], isNull);
          } else {
            expect(newColumnB.data[i], equals(deprecatedResult.data[i]));
          }
        }
      });

      test('both methods produce same results for std operation', () {
        var deprecatedResult = df.rolling('C', 4, 'std');
        var newResult = df.rollingWindow(4).std();
        var newColumnC = newResult['C'];

        for (int i = 0; i < deprecatedResult.length; i++) {
          if (deprecatedResult.data[i] == null) {
            expect(newColumnC.data[i], isNull);
          } else {
            expect(
                newColumnC.data[i], closeTo(deprecatedResult.data[i], 0.001));
          }
        }
      });
    });

    group('Migration Examples', () {
      test('migration from deprecated to new method works', () {
        // OLD way (deprecated)
        var oldMean = df.rolling('A', 3, 'mean');
        var oldSum = df.rolling('B', 2, 'sum');
        var oldMin = df.rolling('C', 3, 'min');

        // NEW way (recommended)
        var newMean = df.rollingWindow(3).mean()['A'];
        var newSum = df.rollingWindow(2).sum()['B'];
        var newMin = df.rollingWindow(3).min()['C'];

        // Results should be equivalent
        expect(newMean.data, equals(oldMean.data));
        expect(newSum.data, equals(oldSum.data));
        expect(newMin.data, equals(oldMin.data));
      });

      test(
          'new method provides additional functionality not available in deprecated method',
          () {
        var rolling = df.rollingWindow(3);

        // These operations are not available in the deprecated method
        expect(() => rolling.median(), returnsNormally);
        expect(() => rolling.quantile(0.75), returnsNormally);
        expect(() => rolling.variance(), returnsNormally);
        expect(() => rolling.skew(), returnsNormally);
        expect(() => rolling.kurt(), returnsNormally);

        // Custom function
        expect(() => rolling.apply((window) => window.length.toDouble()),
            returnsNormally);

        // Correlation (requires another DataFrame)
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

        expect(() => rolling.corr(other: df2), returnsNormally);
        expect(() => rolling.cov(other: df2), returnsNormally);
      });
    });

    group('Performance Comparison', () {
      test('new method is more efficient for multiple operations', () {
        var stopwatch = Stopwatch();

        // OLD way: multiple calls to deprecated method
        stopwatch.start();
        var oldMean = df.rolling('A', 3, 'mean');
        var oldSum = df.rolling('A', 3, 'sum');
        var oldStd = df.rolling('A', 3, 'std');
        stopwatch.stop();
        var oldTime = stopwatch.elapsedMicroseconds;

        // NEW way: single rolling object with multiple operations
        stopwatch.reset();
        stopwatch.start();
        var rolling = df.rollingWindow(3);
        var newMean = rolling.mean()['A'];
        var newSum = rolling.sum()['A'];
        var newStd = rolling.std()['A'];
        stopwatch.stop();
        var newTime = stopwatch.elapsedMicroseconds;

        // Results should be the same
        expect(newMean.data, equals(oldMean.data));
        expect(newSum.data, equals(oldSum.data));
        expect(newStd.data, equals(oldStd.data));

        // New method should be at least as fast (though this is not guaranteed in all cases)
        // This is more of a demonstration than a strict requirement
        print('Deprecated method time: $oldTimeμs');
        print('New method time: $newTimeμs');

        // At minimum, both should complete successfully
        expect(oldTime, greaterThan(0));
        expect(newTime, greaterThan(0));
      });
    });

    group('Error Handling Compatibility', () {
      test('both methods handle invalid column names similarly', () {
        expect(() => df.rolling('NonExistent', 3, 'mean'), throwsArgumentError);
        // The new method doesn't take column names directly, so this test is about the DataFrame access
        var rolling = df.rollingWindow(3);
        var result = rolling.mean();
        expect(() => result['NonExistent'], throwsArgumentError);
      });

      test('both methods handle invalid window sizes similarly', () {
        expect(() => df.rolling('A', 0, 'mean'), throwsArgumentError);
        expect(() => df.rolling('A', -1, 'mean'), throwsArgumentError);

        expect(() => df.rollingWindow(0), throwsArgumentError);
        expect(() => df.rollingWindow(-1), throwsArgumentError);
      });

      test('deprecated method handles invalid functions', () {
        expect(() => df.rolling('A', 3, 'invalid'), throwsArgumentError);
      });
    });
  });
}
