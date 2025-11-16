import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';
import 'dart:math';

void main() {
  group('Advanced Statistical Operations', () {
    group('DataFrame Statistics', () {
      late DataFrame df;
      late DataFrame dfWithMissing;
      late DataFrame dfMixed;

      setUp(() {
        // Basic numeric DataFrame
        df = DataFrame([
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
          [10, 11, 12]
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
          [10, 11, 12]
        ], columns: [
          'A',
          'B',
          'C'
        ]);

        // Mixed data types DataFrame
        dfMixed = DataFrame([
          [1, 'text', 3.5],
          [2, 'more', 4.5],
          [3, 'data', 5.5]
        ], columns: [
          'numeric',
          'text',
          'float'
        ]);
      });

      group('median()', () {
        test('calculates median for numeric columns', () {
          var result = df.median();
          expect(result.data, equals([5.5, 6.5, 7.5])); // Median of each column
          expect(result.index, equals(['A', 'B', 'C']));
          expect(result.name, equals('median'));
        });

        test('handles missing values correctly', () {
          var result = dfWithMissing.median();
          expect(result.data[0], equals(4)); // [1, 4, 10] -> median = 4
          expect(result.data[1], equals(8)); // [2, 8, 11] -> median = 8
          expect(result.data[2], equals(9)); // [6, 9, 12] -> median = 9
        });

        test('handles non-numeric columns', () {
          var result = dfMixed.median();
          expect(result.data[0], equals(2.0)); // numeric column median
          expect(result.data[1],
              equals(dfMixed.replaceMissingValueWith)); // text column
          expect(result.data[2], equals(4.5)); // float column median
        });

        test('skipna parameter works correctly', () {
          var resultSkip = dfWithMissing.median(skipna: true);
          var resultNoSkip = dfWithMissing.median(skipna: false);

          // With skipna=true, should ignore nulls
          expect(resultSkip.data[0], equals(4));

          // Results should be the same since nulls are filtered in both cases
          expect(resultSkip.data, equals(resultNoSkip.data));
        });
      });

      group('mode()', () {
        test('calculates mode for columns with repeated values', () {
          var dfMode = DataFrame([
            [1, 'a', 1.0],
            [2, 'b', 1.0],
            [1, 'a', 2.0],
            [3, 'a', 1.0]
          ], columns: [
            'A',
            'B',
            'C'
          ]);

          var result = dfMode.mode();
          expect(result.data[0], equals(1)); // Most frequent in column A
          expect(result.data[1], equals('a')); // Most frequent in column B
          expect(result.data[2], equals(1.0)); // Most frequent in column C
        });

        test('handles missing values', () {
          var dfModeWithNull = DataFrame([
            [1, null, 1.0],
            [null, 2, 1.0],
            [1, 2, null],
            [1, 2, 1.0]
          ], columns: [
            'A',
            'B',
            'C'
          ]);

          var result = dfModeWithNull.mode(dropna: true);
          expect(result.data[0], equals(1)); // Mode ignoring nulls
          expect(result.data[1], equals(2)); // Mode ignoring nulls
          expect(result.data[2], equals(1.0)); // Mode ignoring nulls
        });
      });

      group('quantileStats()', () {
        test('calculates quantiles correctly', () {
          var result = df.quantileStats(0.5); // Median
          expect(result.data, equals([5.5, 6.5, 7.5]));
          expect(result.name, equals('quantile_0.5'));
        });

        test('calculates different quantiles', () {
          var q25 = df.quantileStats(0.25);
          var q75 = df.quantileStats(0.75);

          expect(q25.data[0],
              closeTo(3.25, 0.01)); // 25th percentile of [1,4,7,10]
          expect(q75.data[0],
              closeTo(7.75, 0.01)); // 75th percentile of [1,4,7,10]
        });

        test('throws error for invalid quantile values', () {
          expect(() => df.quantileStats(-0.1), throwsArgumentError);
          expect(() => df.quantileStats(1.1), throwsArgumentError);
        });

        test('handles edge cases', () {
          var singleRow = DataFrame([
            [5]
          ], columns: [
            'A'
          ]);
          var result = singleRow.quantileStats(0.5);
          expect(result.data[0], equals(5));
        });
      });

      group('stdAdvanced()', () {
        test('calculates standard deviation', () {
          var result = df.std();

          // Manual calculation for column A: [1,4,7,10]
          // Mean = 5.5, variance = ((1-5.5)² + (4-5.5)² + (7-5.5)² + (10-5.5)²) / 3
          // = (20.25 + 2.25 + 2.25 + 20.25) / 3 = 15
          // std = sqrt(15) ≈ 3.873
          expect(result.data[0], closeTo(3.873, 0.01));
        });

        test('handles ddof parameter', () {
          var resultDdof1 = df.std(ddof: 1); // Sample std
          var resultDdof0 = df.std(ddof: 0); // Population std

          // Population std should be smaller than sample std
          expect(resultDdof0.data[0], lessThan(resultDdof1.data[0]));
        });

        test('handles insufficient data', () {
          var singleValue = DataFrame([
            [1]
          ], columns: [
            'A'
          ]);
          var result = singleValue.std(ddof: 1);
          expect(result.data[0], equals(singleValue.replaceMissingValueWith));
        });
      });

      group('variance()', () {
        test('calculates variance correctly', () {
          var result = df.variance();

          // For column A: [1,4,7,10], variance should be 15 (with ddof=1)
          expect(result.data[0], closeTo(15.0, 0.01));
        });

        test('variance equals std squared', () {
          var stdResult = df.std();
          var varResult = df.variance();

          for (int i = 0; i < stdResult.length; i++) {
            if (stdResult.data[i] is num && varResult.data[i] is num) {
              expect(
                  varResult.data[i], closeTo(pow(stdResult.data[i], 2), 0.01));
            }
          }
        });
      });

      group('corrAdvanced()', () {
        test('calculates Pearson correlation matrix', () {
          var result = df.corr(method: 'pearson');

          // Diagonal should be 1.0 (perfect correlation with self)
          expect(result.iloc(0, 0), equals(1.0));
          expect(result.iloc(1, 1), equals(1.0));
          expect(result.iloc(2, 2), equals(1.0));

          // Off-diagonal elements should be 1.0 for perfectly correlated data
          expect(result.iloc(0, 1), closeTo(1.0, 0.01));
          expect(result.iloc(1, 2), closeTo(1.0, 0.01));
        });

        test('calculates Spearman correlation matrix', () {
          var result = df.corr(method: 'spearman');

          // Should also be perfect correlation for monotonic data
          expect(result.iloc(0, 0), equals(1.0));
          expect(result.iloc(0, 1), closeTo(1.0, 0.01));
        });

        test('throws error for invalid method', () {
          expect(() => df.corr(method: 'invalid'), throwsArgumentError);
        });

        test('handles non-numeric columns', () {
          // Should only include numeric columns in correlation matrix
          var result = dfMixed.corr();
          expect(result.columns.length,
              equals(2)); // Only numeric and float columns
          expect(result.columns, contains('numeric'));
          expect(result.columns, contains('float'));
          expect(result.columns, isNot(contains('text')));
        });
      });

      group('cov()', () {
        test('calculates covariance matrix', () {
          var result = df.cov();

          // Diagonal should be variance
          var variance = df.variance();
          expect(result.iloc(0, 0), closeTo(variance.data[0], 0.01));
          expect(result.iloc(1, 1), closeTo(variance.data[1], 0.01));
          expect(result.iloc(2, 2), closeTo(variance.data[2], 0.01));
        });

        test('covariance matrix is symmetric', () {
          var result = df.cov();

          expect(result.iloc(0, 1), closeTo(result.iloc(1, 0), 0.01));
          expect(result.iloc(0, 2), closeTo(result.iloc(2, 0), 0.01));
          expect(result.iloc(1, 2), closeTo(result.iloc(2, 1), 0.01));
        });
      });
    });

    group('Series Statistics', () {
      late Series numericSeries;
      late Series seriesWithMissing;
      late Series mixedSeries;

      setUp(() {
        numericSeries = Series([1, 2, 3, 4, 5], name: 'numeric');
        seriesWithMissing = Series([1, null, 3, null, 5], name: 'with_missing');
        mixedSeries = Series([1, 'text', 3, 4.5], name: 'mixed');
      });

      group('median()', () {
        test('calculates median for odd number of elements', () {
          expect(numericSeries.median(), equals(3));
        });

        test('calculates median for even number of elements', () {
          var evenSeries = Series([1, 2, 3, 4], name: 'even');
          expect(evenSeries.median(), equals(2.5));
        });

        test('handles missing values', () {
          // [1, 3, 5] -> median = 3
          expect(seriesWithMissing.median(), equals(3));
        });

        test('handles non-numeric values', () {
          // Should only consider [1, 3, 4.5] -> median = 3
          expect(mixedSeries.median(), equals(3));
        });

        test('returns missing representation for empty series', () {
          var emptySeries = Series([], name: 'empty');
          var result = emptySeries.median();
          expect(result, isNull); // Should return null for empty series
        });
      });

      group('mode()', () {
        test('calculates mode correctly', () {
          var seriesWithMode = Series([1, 2, 2, 3, 2, 4], name: 'mode_test');
          expect(seriesWithMode.mode(), equals(2));
        });

        test('handles ties by returning first encountered', () {
          var tiedSeries = Series([1, 2, 1, 2], name: 'tied');
          // Should return the first mode encountered
          var mode = tiedSeries.mode();
          expect([1, 2], contains(mode));
        });

        test('handles missing values', () {
          var seriesWithNull = Series([1, null, 2, 2, null], name: 'with_null');
          expect(seriesWithNull.mode(dropna: true), equals(2));
        });
      });

      group('quantileAdvanced()', () {
        test('calculates quantiles correctly', () {
          expect(numericSeries.quantile(0.0), equals(1));
          expect(numericSeries.quantile(0.5), equals(3));
          expect(numericSeries.quantile(1.0), equals(5));
        });

        test('interpolates between values', () {
          expect(numericSeries.quantile(0.25), equals(2.0));
          expect(numericSeries.quantile(0.75), equals(4.0));
        });

        test('throws error for invalid quantile', () {
          expect(() => numericSeries.quantile(-0.1), throwsA(isA<Exception>()));
          expect(() => numericSeries.quantile(1.1), throwsA(isA<Exception>()));
        });

        test('handles single value', () {
          var singleSeries = Series([42], name: 'single');
          expect(singleSeries.quantile(0.5), equals(42));
        });
      });

      group('stdAdvanced()', () {
        test('calculates standard deviation', () {
          // For [1,2,3,4,5]: mean=3, variance=2.5, std=sqrt(2.5)≈1.58
          expect(numericSeries.std(), closeTo(1.58, 0.01));
        });

        test('handles ddof parameter', () {
          var stdSample = numericSeries.std(ddof: 1);
          var stdPopulation = numericSeries.std(ddof: 0);

          expect(stdPopulation, lessThan(stdSample));
        });

        test('returns NaN for insufficient data', () {
          var singleSeries = Series([1], name: 'single');
          expect(singleSeries.std(ddof: 1).isNaN, isTrue);
        });
      });

      group('variance()', () {
        test('calculates variance correctly', () {
          // For [1,2,3,4,5]: variance = 2.5 (with ddof=1)
          expect(numericSeries.variance(), closeTo(2.5, 0.01));
        });

        test('variance equals std squared', () {
          var std = numericSeries.std();
          var variance = numericSeries.variance();

          expect(variance, closeTo(pow(std, 2), 0.01));
        });
      });

      group('skew()', () {
        test('calculates skewness for symmetric data', () {
          var symmetricSeries = Series([1, 2, 3, 4, 5], name: 'symmetric');
          // Symmetric data should have skewness close to 0
          expect(symmetricSeries.skew().abs(), lessThan(0.1));
        });

        test('calculates positive skew for right-tailed data', () {
          var rightSkewed = Series([1, 1, 1, 2, 5], name: 'right_skewed');
          expect(rightSkewed.skew(), greaterThan(0));
        });

        test('calculates negative skew for left-tailed data', () {
          var leftSkewed = Series([1, 4, 5, 5, 5], name: 'left_skewed');
          expect(leftSkewed.skew(), lessThan(0));
        });

        test('returns NaN for insufficient data', () {
          var smallSeries = Series([1, 2], name: 'small');
          expect(smallSeries.skew().isNaN, isTrue);
        });
      });

      group('kurtosis()', () {
        test('calculates kurtosis', () {
          var result = numericSeries.kurtosis();
          expect(result, isA<double>());
          expect(result.isFinite, isTrue);
        });

        test('Fisher vs Pearson definition', () {
          var fisherKurt = numericSeries.kurtosis(fisher: true);
          var pearsonKurt = numericSeries.kurtosis(fisher: false);

          // Fisher kurtosis should be approximately 3 less than Pearson
          expect(fisherKurt, lessThan(pearsonKurt));
        });

        test('returns NaN for insufficient data', () {
          var smallSeries = Series([1, 2, 3], name: 'small');
          expect(smallSeries.kurtosis().isNaN, isTrue);
        });
      });

      group('rolling()', () {
        test('creates RollingSeries object', () {
          var rolling = numericSeries.rolling(3);
          expect(rolling, isA<RollingSeries>());
          expect(rolling.window, equals(3));
        });

        test('throws error for invalid window size', () {
          expect(() => numericSeries.rolling(0), throwsArgumentError);
          expect(() => numericSeries.rolling(-1), throwsArgumentError);
          expect(() => numericSeries.rolling(10),
              throwsArgumentError); // Larger than series
        });

        group('RollingSeries operations', () {
          late RollingSeries rolling;

          setUp(() {
            rolling = numericSeries.rolling(3);
          });

          test('mean() calculates rolling mean', () {
            var result = rolling.mean();

            // First two values should be missing
            expect(result.data[0], isNull);
            expect(result.data[1], isNull);

            // Third value: mean of [1,2,3] = 2.0
            expect(result.data[2], equals(2.0));

            // Fourth value: mean of [2,3,4] = 3.0
            expect(result.data[3], equals(3.0));

            // Fifth value: mean of [3,4,5] = 4.0
            expect(result.data[4], equals(4.0));
          });

          test('sum() calculates rolling sum', () {
            var result = rolling.sum();

            expect(result.data[2], equals(6)); // 1+2+3
            expect(result.data[3], equals(9)); // 2+3+4
            expect(result.data[4], equals(12)); // 3+4+5
          });

          test('std() calculates rolling standard deviation', () {
            var result = rolling.std();

            // Standard deviation of [1,2,3] = 1.0
            expect(result.data[2], closeTo(1.0, 0.01));
          });

          test('min() calculates rolling minimum', () {
            var result = rolling.min();

            expect(result.data[2], equals(1)); // min of [1,2,3]
            expect(result.data[3], equals(2)); // min of [2,3,4]
            expect(result.data[4], equals(3)); // min of [3,4,5]
          });

          test('max() calculates rolling maximum', () {
            var result = rolling.max();

            expect(result.data[2], equals(3)); // max of [1,2,3]
            expect(result.data[3], equals(4)); // max of [2,3,4]
            expect(result.data[4], equals(5)); // max of [3,4,5]
          });
        });
      });
    });

    group('Edge Cases and Error Handling', () {
      test('handles empty DataFrame', () {
        var emptyDf = DataFrame([], columns: []);

        expect(() => emptyDf.median(), returnsNormally);
        expect(() => emptyDf.mode(), returnsNormally);
      });

      test('handles DataFrame with no numeric columns', () {
        var textDf = DataFrame([
          ['a', 'b'],
          ['c', 'd']
        ], columns: [
          'col1',
          'col2'
        ]);

        expect(() => textDf.corr(), throwsArgumentError);
        expect(() => textDf.cov(), throwsArgumentError);
      });

      test('handles Series with all missing values', () {
        var allMissingSeries = Series([null, null, null], name: 'all_missing');

        expect(allMissingSeries.median(), isNull);
        expect(allMissingSeries.std().isNaN, isTrue);
        expect(allMissingSeries.variance().isNaN, isTrue);
      });

      test('statistical accuracy validation', () {
        // Test against known statistical values
        var knownSeries = Series([2, 4, 4, 4, 5, 5, 7, 9], name: 'known');

        // Known values calculated manually
        expect(knownSeries.median(), equals(4.5));
        expect(knownSeries.mode(), equals(4));
        expect(knownSeries.std(), closeTo(2.138, 0.01));
        expect(knownSeries.variance(), closeTo(4.571, 0.01));
      });
    });
  });
}
