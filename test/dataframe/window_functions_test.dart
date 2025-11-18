import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Exponentially Weighted Window (EWM)', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame([
        [1.0, 10.0],
        [2.0, 20.0],
        [3.0, 30.0],
        [4.0, 40.0],
        [5.0, 50.0],
      ], columns: [
        'A',
        'B'
      ]);
    });

    group('EWM Creation', () {
      test('creates EWM with span', () {
        var ewm = df.ewm(span: 3);
        expect(ewm, isA<ExponentialWeightedWindow>());
      });

      test('creates EWM with alpha', () {
        var ewm = df.ewm(alpha: 0.5);
        expect(ewm, isA<ExponentialWeightedWindow>());
      });

      test('creates EWM with halflife', () {
        var ewm = df.ewm(halflife: 2);
        expect(ewm, isA<ExponentialWeightedWindow>());
      });

      test('creates EWM with com', () {
        var ewm = df.ewm(com: 1.0);
        expect(ewm, isA<ExponentialWeightedWindow>());
      });

      test('throws error when no parameter specified', () {
        expect(
          () => df.ewm(),
          throwsArgumentError,
        );
      });

      test('throws error when multiple parameters specified', () {
        expect(
          () => df.ewm(span: 3, alpha: 0.5),
          throwsArgumentError,
        );
      });

      test('throws error for invalid alpha', () {
        expect(
          () => df.ewm(alpha: 0.0).mean(),
          throwsArgumentError,
        );

        expect(
          () => df.ewm(alpha: 1.5).mean(),
          throwsArgumentError,
        );
      });

      test('throws error for invalid span', () {
        expect(
          () => df.ewm(span: 0).mean(),
          throwsArgumentError,
        );
      });
    });

    group('EWM Mean', () {
      test('calculates EWM mean with span', () {
        var result = df.ewm(span: 2).mean();

        expect(result.rowCount, equals(5));
        expect(result.columnCount, equals(2));
        expect(result.columns, equals(['A', 'B']));

        // First value should be the same
        expect(result['A'].toList()[0], equals(1.0));

        // Values should be increasing
        var aValues = result['A'].toList();
        for (int i = 1; i < aValues.length; i++) {
          expect(aValues[i], greaterThan(aValues[i - 1]));
        }
      });

      test('EWM mean with alpha=0.5', () {
        var result = df.ewm(alpha: 0.5).mean();

        expect(result.rowCount, equals(5));

        // First value should be 1.0
        expect(result['A'].toList()[0], equals(1.0));

        // Second value: 0.5 * 2 + 0.5 * 1 = 1.5
        expect(result['A'].toList()[1], closeTo(1.5, 0.01));
      });

      test('handles null values', () {
        var dfWithNull = DataFrame([
          [1.0, 10.0],
          [null, 20.0],
          [3.0, 30.0],
        ], columns: [
          'A',
          'B'
        ]);

        var result = dfWithNull.ewm(span: 2).mean();

        expect(result.rowCount, equals(3));
        expect(result['A'].toList()[1], isNull);
      });
    });

    group('EWM Standard Deviation', () {
      test('calculates EWM std', () {
        var result = df.ewm(span: 3).std();

        expect(result.rowCount, equals(5));
        expect(result.columnCount, equals(2));

        // First value should be 0
        expect(result['A'].toList()[0], equals(0.0));

        // Subsequent values should be non-negative
        var aValues = result['A'].toList();
        for (var value in aValues) {
          expect(value, greaterThanOrEqualTo(0.0));
        }
      });

      test('EWM std increases with variance', () {
        var result = df.ewm(span: 2).std();

        var aValues = result['A'].toList();
        // Std should generally increase as we see more varied data
        expect(aValues.last, greaterThan(aValues[1]));
      });
    });

    group('EWM Variance', () {
      test('calculates EWM variance', () {
        var result = df.ewm(span: 3).var_();

        expect(result.rowCount, equals(5));
        expect(result.columnCount, equals(2));

        // First value should be 0
        expect(result['A'].toList()[0], equals(0.0));

        // Variance should be non-negative
        var aValues = result['A'].toList();
        for (var value in aValues) {
          expect(value, greaterThanOrEqualTo(0.0));
        }
      });

      test('variance equals std squared', () {
        var variance = df.ewm(span: 2).var_();
        var std = df.ewm(span: 2).std();

        for (int i = 0; i < df.rowCount; i++) {
          var varValue = variance['A'].toList()[i];
          var stdValue = std['A'].toList()[i];

          if (varValue != null && stdValue != null) {
            expect(varValue, closeTo(stdValue * stdValue, 0.0001));
          }
        }
      });
    });

    group('EWM Correlation', () {
      test('calculates pairwise EWM correlation', () {
        var result = df.ewm(span: 3).corr();

        expect(result.rowCount, equals(2)); // 2 columns
        expect(result.columnCount, equals(2));

        // Diagonal should be 1.0
        expect(result['A'].toList()[0], equals(1.0));
        expect(result['B'].toList()[1], equals(1.0));

        // Correlation should be between -1 and 1
        var corrAB = result['B'].toList()[0];
        if (corrAB != null) {
          expect(corrAB, greaterThanOrEqualTo(-1.0));
          expect(corrAB, lessThanOrEqualTo(1.0));
        }
      });

      test('EWM correlation is symmetric', () {
        var result = df.ewm(span: 3).corr();

        var corrAB = result['B'].toList()[0];
        var corrBA = result['A'].toList()[1];

        if (corrAB != null && corrBA != null) {
          expect(corrAB, closeTo(corrBA, 0.0001));
        }
      });

      test('handles single column DataFrame', () {
        var singleCol = DataFrame([
          [1.0],
          [2.0],
          [3.0],
        ], columns: [
          'A'
        ]);

        var result = singleCol.ewm(span: 2).corr();

        expect(result.rowCount, equals(1));
        expect(result['A'].toList()[0], equals(1.0));
      });
    });

    group('EWM Covariance', () {
      test('calculates pairwise EWM covariance', () {
        var result = df.ewm(span: 3).cov();

        expect(result.rowCount, equals(2)); // 2 columns
        expect(result.columnCount, equals(2));

        // Covariance should be non-negative for diagonal
        var covAA = result['A'].toList()[0];
        var covBB = result['B'].toList()[1];

        if (covAA != null) expect(covAA, greaterThanOrEqualTo(0.0));
        if (covBB != null) expect(covBB, greaterThanOrEqualTo(0.0));
      });

      test('EWM covariance is symmetric', () {
        var result = df.ewm(span: 3).cov();

        var covAB = result['B'].toList()[0];
        var covBA = result['A'].toList()[1];

        if (covAB != null && covBA != null) {
          expect(covAB, closeTo(covBA, 0.0001));
        }
      });

      test('covariance with perfectly correlated data', () {
        var perfectCorr = DataFrame([
          [1.0, 2.0],
          [2.0, 4.0],
          [3.0, 6.0],
        ], columns: [
          'A',
          'B'
        ]);

        var result = perfectCorr.ewm(span: 2).cov();

        expect(result.rowCount, equals(2));

        // Covariance should be positive
        var covAB = result['B'].toList()[0];
        if (covAB != null) {
          expect(covAB, greaterThan(0.0));
        }
      });
    });

    group('EWM with Different Parameters', () {
      test('span parameter works correctly', () {
        var result = df.ewm(span: 5).mean();
        expect(result.rowCount, equals(5));
      });

      test('halflife parameter works correctly', () {
        var result = df.ewm(halflife: 3).mean();
        expect(result.rowCount, equals(5));
      });

      test('com parameter works correctly', () {
        var result = df.ewm(com: 2.0).mean();
        expect(result.rowCount, equals(5));
      });

      test('adjustWeights parameter is accepted', () {
        var adjusted = df.ewm(span: 2, adjustWeights: true).mean();
        var unadjusted = df.ewm(span: 2, adjustWeights: false).mean();

        // Both should produce valid results
        expect(adjusted.rowCount, equals(5));
        expect(unadjusted.rowCount, equals(5));
      });
    });
  });

  group('Expanding Window', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame([
        [1.0, 10.0],
        [2.0, 20.0],
        [3.0, 30.0],
        [4.0, 40.0],
        [5.0, 50.0],
      ], columns: [
        'A',
        'B'
      ]);
    });

    group('Expanding Creation', () {
      test('creates expanding window', () {
        var expanding = df.expanding();
        expect(expanding, isA<ExpandingWindow>());
      });

      test('creates expanding window with minPeriods', () {
        var expanding = df.expanding(minPeriods: 2);
        expect(expanding, isA<ExpandingWindow>());
      });

      test('throws error for invalid minPeriods', () {
        expect(
          () => df.expanding(minPeriods: 0),
          throwsArgumentError,
        );
      });
    });

    group('Expanding Mean', () {
      test('calculates expanding mean', () {
        var result = df.expanding().mean();

        expect(result.rowCount, equals(5));
        expect(result.columnCount, equals(2));

        // Check column A values
        var aValues = result['A'].toList();
        expect(aValues[0], equals(1.0)); // 1
        expect(aValues[1], equals(1.5)); // (1+2)/2
        expect(aValues[2], equals(2.0)); // (1+2+3)/3
        expect(aValues[3], equals(2.5)); // (1+2+3+4)/4
        expect(aValues[4], equals(3.0)); // (1+2+3+4+5)/5
      });

      test('expanding mean with minPeriods', () {
        var result = df.expanding(minPeriods: 3).mean();

        var aValues = result['A'].toList();
        expect(aValues[0], isNull); // Not enough data
        expect(aValues[1], isNull); // Not enough data
        expect(aValues[2], equals(2.0)); // (1+2+3)/3
        expect(aValues[3], equals(2.5)); // (1+2+3+4)/4
      });

      test('handles null values', () {
        var dfWithNull = DataFrame([
          [1.0, 10.0],
          [null, 20.0],
          [3.0, 30.0],
        ], columns: [
          'A',
          'B'
        ]);

        var result = dfWithNull.expanding().mean();

        expect(result.rowCount, equals(3));
        // Mean should skip null values
        expect(result['A'].toList()[2], equals(2.0)); // (1+3)/2
      });
    });

    group('Expanding Sum', () {
      test('calculates expanding sum', () {
        var result = df.expanding().sum();

        var aValues = result['A'].toList();
        expect(aValues[0], equals(1.0)); // 1
        expect(aValues[1], equals(3.0)); // 1+2
        expect(aValues[2], equals(6.0)); // 1+2+3
        expect(aValues[3], equals(10.0)); // 1+2+3+4
        expect(aValues[4], equals(15.0)); // 1+2+3+4+5
      });

      test('expanding sum with minPeriods', () {
        var result = df.expanding(minPeriods: 2).sum();

        var aValues = result['A'].toList();
        expect(aValues[0], isNull);
        expect(aValues[1], equals(3.0));
      });
    });

    group('Expanding Std', () {
      test('calculates expanding std', () {
        var result = df.expanding().std();

        expect(result.rowCount, equals(5));

        // First value should be 0 (only one value)
        expect(result['A'].toList()[0], equals(0.0));

        // Std should be non-negative
        var aValues = result['A'].toList();
        for (var value in aValues) {
          expect(value, greaterThanOrEqualTo(0.0));
        }
      });

      test('expanding std matches manual calculation', () {
        var result = df.expanding().std();

        // For [1, 2], std = sqrt(((1-1.5)^2 + (2-1.5)^2) / 2) = sqrt(0.25) ≈ 0.5
        expect(result['A'].toList()[1], closeTo(0.5, 0.01));
      });
    });

    group('Expanding Min', () {
      test('calculates expanding min', () {
        var result = df.expanding().min();

        var aValues = result['A'].toList();
        expect(aValues[0], equals(1.0));
        expect(aValues[1], equals(1.0));
        expect(aValues[2], equals(1.0));
        expect(aValues[3], equals(1.0));
        expect(aValues[4], equals(1.0));
      });

      test('expanding min with decreasing values', () {
        var dfDesc = DataFrame([
          [5.0],
          [4.0],
          [3.0],
          [2.0],
          [1.0],
        ], columns: [
          'A'
        ]);

        var result = dfDesc.expanding().min();

        var aValues = result['A'].toList();
        expect(aValues[0], equals(5.0));
        expect(aValues[1], equals(4.0));
        expect(aValues[2], equals(3.0));
        expect(aValues[3], equals(2.0));
        expect(aValues[4], equals(1.0));
      });
    });

    group('Expanding Max', () {
      test('calculates expanding max', () {
        var result = df.expanding().max();

        var aValues = result['A'].toList();
        expect(aValues[0], equals(1.0));
        expect(aValues[1], equals(2.0));
        expect(aValues[2], equals(3.0));
        expect(aValues[3], equals(4.0));
        expect(aValues[4], equals(5.0));
      });

      test('expanding max with decreasing values', () {
        var dfDesc = DataFrame([
          [5.0],
          [4.0],
          [3.0],
          [2.0],
          [1.0],
        ], columns: [
          'A'
        ]);

        var result = dfDesc.expanding().max();

        var aValues = result['A'].toList();
        expect(aValues[0], equals(5.0));
        expect(aValues[1], equals(5.0));
        expect(aValues[2], equals(5.0));
        expect(aValues[3], equals(5.0));
        expect(aValues[4], equals(5.0));
      });
    });
  });

  group('Integration Tests', () {
    test('EWM and expanding can be chained', () {
      var df = DataFrame([
        [1.0, 10.0],
        [2.0, 20.0],
        [3.0, 30.0],
      ], columns: [
        'A',
        'B'
      ]);

      var ewmResult = df.ewm(span: 2).mean();
      var expandingResult = ewmResult.expanding().sum();

      expect(expandingResult.rowCount, equals(3));
    });

    test('works with larger datasets', () {
      var data = List.generate(100, (i) => [i.toDouble(), (i * 2).toDouble()]);
      var df = DataFrame(data, columns: ['A', 'B']);

      var ewmMean = df.ewm(span: 10).mean();
      var expandingMean = df.expanding(minPeriods: 5).mean();

      expect(ewmMean.rowCount, equals(100));
      expect(expandingMean.rowCount, equals(100));
    });

    test('handles mixed numeric and non-numeric columns', () {
      var df = DataFrame([
        ['a', 1.0, 10],
        ['b', 2.0, 20],
        ['c', 3.0, 30],
      ], columns: [
        'text',
        'float',
        'int'
      ]);

      var ewmResult = df.ewm(span: 2).mean();
      var expandingResult = df.expanding().sum();

      expect(ewmResult.rowCount, equals(3));
      expect(expandingResult.rowCount, equals(3));

      // Non-numeric column should have nulls
      expect(ewmResult['text'].toList().every((v) => v == null), isTrue);
    });
  });

  group('Edge Cases', () {
    test('handles single row DataFrame', () {
      var df = DataFrame([
        [1.0, 10.0]
      ], columns: [
        'A',
        'B'
      ]);

      var ewmMean = df.ewm(span: 2).mean();
      var expandingMean = df.expanding().mean();

      expect(ewmMean['A'].toList()[0], equals(1.0));
      expect(expandingMean['A'].toList()[0], equals(1.0));
    });

    test('handles empty DataFrame', () {
      var df = DataFrame.empty(columns: ['A', 'B']);

      var ewmMean = df.ewm(span: 2).mean();
      var expandingMean = df.expanding().mean();

      expect(ewmMean.rowCount, equals(0));
      expect(expandingMean.rowCount, equals(0));
    });

    test('handles all null values', () {
      var df = DataFrame([
        [null, null],
        [null, null],
        [null, null],
      ], columns: [
        'A',
        'B'
      ]);

      var ewmMean = df.ewm(span: 2).mean();
      var expandingMean = df.expanding().mean();

      expect(ewmMean['A'].toList().every((v) => v == null), isTrue);
      expect(expandingMean['A'].toList().every((v) => v == null), isTrue);
    });
  });

  group('Performance Tests', () {
    test('EWM performs efficiently on large dataset', () {
      var data = List.generate(1000, (i) => [i.toDouble(), (i * 2).toDouble()]);
      var df = DataFrame(data, columns: ['A', 'B']);

      var stopwatch = Stopwatch()..start();
      var result = df.ewm(span: 10).mean();
      stopwatch.stop();

      expect(result.rowCount, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('Expanding performs efficiently on large dataset', () {
      var data = List.generate(1000, (i) => [i.toDouble(), (i * 2).toDouble()]);
      var df = DataFrame(data, columns: ['A', 'B']);

      var stopwatch = Stopwatch()..start();
      var result = df.expanding().mean();
      stopwatch.stop();

      expect(result.rowCount, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
