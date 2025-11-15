import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Enhanced Sampling Operations', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame.fromMap({
        'A': [1, 2, 3, 4, 5],
        'B': [10, 20, 30, 40, 50],
        'C': [100, 200, 300, 400, 500],
      });
    });

    group('sampleWeighted()', () {
      test('Sample with uniform weights', () {
        final sampled = df.sampleWeighted(n: 3, randomState: 42);

        expect(sampled.rowCount, equals(3));
        expect(sampled.columns, equals(df.columns));
      });

      test('Sample with column weights', () {
        final dfWeighted = DataFrame.fromMap({
          'item': ['A', 'B', 'C', 'D'],
          'weight': [0.1, 0.2, 0.3, 0.4]
        });

        final sampled = dfWeighted.sampleWeighted(
          n: 2,
          weights: 'weight',
          randomState: 42,
        );

        expect(sampled.rowCount, equals(2));
        expect(sampled.columns, contains('item'));
        expect(sampled.columns, contains('weight'));
      });

      test('Sample with list weights', () {
        final sampled = df.sampleWeighted(
          n: 2,
          weights: [1, 2, 3, 4, 5],
          randomState: 42,
        );

        expect(sampled.rowCount, equals(2));
      });

      test('Sample with frac parameter', () {
        final sampled = df.sampleWeighted(
          frac: 0.6,
          weights: [1, 1, 1, 1, 1],
          randomState: 42,
        );

        expect(sampled.rowCount, equals(3)); // 60% of 5 = 3
      });

      test('Sample with replacement', () {
        final sampled = df.sampleWeighted(
          n: 10,
          replace: true,
          weights: [1, 1, 1, 1, 1],
          randomState: 42,
        );

        expect(sampled.rowCount, equals(10));
      });

      test('Sample without replacement', () {
        final sampled = df.sampleWeighted(
          n: 3,
          replace: false,
          weights: [1, 2, 3, 4, 5],
          randomState: 42,
        );

        expect(sampled.rowCount, equals(3));

        // Check no duplicates (indices should be unique)
        final indices = <dynamic>{};
        for (var idx in sampled.index) {
          expect(indices.contains(idx), isFalse);
          indices.add(idx);
        }
      });

      test('Reproducible with randomState', () {
        final sampled1 = df.sampleWeighted(
          n: 3,
          weights: [1, 2, 3, 4, 5],
          randomState: 42,
        );

        final sampled2 = df.sampleWeighted(
          n: 3,
          weights: [1, 2, 3, 4, 5],
          randomState: 42,
        );

        expect(sampled1.index, equals(sampled2.index));
      });

      test('Different results without randomState', () {
        final sampled1 = df.sampleWeighted(n: 3, weights: [1, 2, 3, 4, 5]);
        final sampled2 = df.sampleWeighted(n: 3, weights: [1, 2, 3, 4, 5]);

        // Results might be different (not guaranteed, but very likely)
        // Just check they're valid
        expect(sampled1.rowCount, equals(3));
        expect(sampled2.rowCount, equals(3));
      });
    });

    group('take()', () {
      test('Take specific rows', () {
        final result = df.take([0, 2, 4]);

        expect(result.rowCount, equals(3));
        expect(result['A'].data, equals([1, 3, 5]));
        expect(result['B'].data, equals([10, 30, 50]));
      });

      test('Take with negative indices', () {
        final result = df.take([-1, -2]);

        expect(result.rowCount, equals(2));
        expect(result['A'].data, equals([5, 4]));
      });

      test('Take specific columns', () {
        final result = df.take([0, 2], axis: 1);

        expect(result.columns.length, equals(2));
        expect(result.columns, contains('A'));
        expect(result.columns, contains('C'));
        expect(result.rowCount, equals(5));
      });

      test('Take with negative column indices', () {
        final result = df.take([-1], axis: 1);

        expect(result.columns.length, equals(1));
        expect(result.columns[0], equals('C'));
      });

      test('Take preserves order', () {
        final result = df.take([4, 2, 0]);

        expect(result['A'].data, equals([5, 3, 1]));
      });

      test('Take allows duplicates', () {
        final result = df.take([0, 0, 1]);

        expect(result.rowCount, equals(3));
        expect(result['A'].data, equals([1, 1, 2]));
      });

      test('Take empty list returns empty DataFrame', () {
        final result = df.take([]);

        expect(result.rowCount, equals(0));
        expect(result.columns, equals(df.columns));
      });

      test('Take out of bounds throws error', () {
        expect(
          () => df.take([10]),
          throwsRangeError,
        );
      });

      test('Take preserves index', () {
        final dfWithIndex = DataFrame.fromMap(
          {
            'A': [1, 2, 3]
          },
          index: ['a', 'b', 'c'],
        );

        final result = dfWithIndex.take([0, 2]);

        expect(result.index, equals(['a', 'c']));
      });
    });

    group('sampleFrac()', () {
      test('Sample with n parameter', () {
        final sampled = df.sampleFrac(n: 3, randomState: 42);

        expect(sampled.rowCount, equals(3));
      });

      test('Sample with frac parameter', () {
        final sampled = df.sampleFrac(frac: 0.6, randomState: 42);

        expect(sampled.rowCount, equals(3)); // 60% of 5 = 3
      });

      test('Sample with replacement', () {
        final sampled = df.sampleFrac(
          n: 10,
          replace: true,
          randomState: 42,
        );

        expect(sampled.rowCount, equals(10));
      });

      test('Sample without replacement', () {
        final sampled = df.sampleFrac(
          n: 3,
          replace: false,
          randomState: 42,
        );

        expect(sampled.rowCount, equals(3));
      });

      test('Reproducible with randomState', () {
        final sampled1 = df.sampleFrac(n: 3, randomState: 42);
        final sampled2 = df.sampleFrac(n: 3, randomState: 42);

        expect(sampled1.index, equals(sampled2.index));
      });

      test('Sample columns', () {
        final sampled = df.sampleFrac(n: 2, axis: 1, randomState: 42);

        expect(sampled.columns.length, equals(2));
        expect(sampled.rowCount, equals(5));
      });

      test('Sample columns with frac', () {
        final sampled = df.sampleFrac(frac: 0.67, axis: 1, randomState: 42);

        expect(sampled.columns.length, equals(2)); // 67% of 3 = 2
      });

      test('Cannot specify both n and frac', () {
        expect(
          () => df.sampleFrac(n: 3, frac: 0.5),
          throwsArgumentError,
        );
      });

      test('Must specify either n or frac', () {
        expect(
          () => df.sampleFrac(),
          throwsArgumentError,
        );
      });
    });

    group('Real-world Use Cases', () {
      test('Stratified sampling with weights', () {
        final customers = DataFrame.fromMap({
          'id': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          'segment': ['A', 'B', 'A', 'C', 'B', 'A', 'C', 'B', 'A', 'C'],
          'value': [100, 200, 150, 300, 250, 120, 280, 230, 140, 310],
        });

        // Sample with weights based on customer value
        final sampled = customers.sampleWeighted(
          n: 5,
          weights: 'value',
          randomState: 42,
        );

        expect(sampled.rowCount, equals(5));
        expect(sampled.columns, contains('segment'));
      });

      test('Bootstrap sampling', () {
        final data = DataFrame.fromMap({
          'value': [10, 20, 30, 40, 50],
        });

        // Bootstrap sample (with replacement)
        final bootstrap = data.sampleFrac(
          frac: 1.0,
          replace: true,
          randomState: 42,
        );

        expect(bootstrap.rowCount, equals(5));
      });

      test('Cross-validation split', () {
        final data = DataFrame.fromMap({
          'X': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          'y': [2, 4, 6, 8, 10, 12, 14, 16, 18, 20],
        });

        // Take 80% for training
        final train = data.sampleFrac(frac: 0.8, randomState: 42);

        expect(train.rowCount, equals(8));
      });

      test('Select specific observations', () {
        final timeSeries = DataFrame.fromMap({
          'date': [
            '2024-01-01',
            '2024-01-02',
            '2024-01-03',
            '2024-01-04',
            '2024-01-05'
          ],
          'value': [100, 102, 98, 105, 103],
        });

        // Take first, middle, and last observations
        final selected = timeSeries.take([0, 2, 4]);

        expect(selected.rowCount, equals(3));
        expect(selected['date'].data,
            equals(['2024-01-01', '2024-01-03', '2024-01-05']));
      });

      test('Feature selection', () {
        final features = DataFrame.fromMap({
          'feature1': [1, 2, 3],
          'feature2': [4, 5, 6],
          'feature3': [7, 8, 9],
          'feature4': [10, 11, 12],
          'target': [0, 1, 0],
        });

        // Select specific features
        final selected = features.take([0, 2, 4], axis: 1);

        expect(selected.columns.length, equals(3));
        expect(selected.columns, contains('feature1'));
        expect(selected.columns, contains('feature3'));
        expect(selected.columns, contains('target'));
      });
    });

    group('Edge Cases', () {
      test('Sample from single row DataFrame', () {
        final single = DataFrame.fromMap({
          'A': [1]
        });

        final sampled = single.sampleWeighted(n: 1, randomState: 42);

        expect(sampled.rowCount, equals(1));
      });

      test('Sample with all zero weights except one', () {
        final sampled = df.sampleWeighted(
          n: 3,
          weights: [0, 0, 1, 0, 0],
          replace: true,
          randomState: 42,
        );

        expect(sampled.rowCount, equals(3));
        // All samples should be from index 2
        expect(sampled['A'].data.every((v) => v == 3), isTrue);
      });

      test('Take with single index', () {
        final result = df.take([2]);

        expect(result.rowCount, equals(1));
        expect(result['A'].data[0], equals(3));
      });

      test('Sample 100% of data', () {
        final sampled = df.sampleFrac(frac: 1.0, randomState: 42);

        expect(sampled.rowCount, equals(df.rowCount));
      });
    });

    group('Error Handling', () {
      test('Weights length mismatch throws error', () {
        expect(
          () => df.sampleWeighted(n: 2, weights: [1, 2, 3]),
          throwsArgumentError,
        );
      });

      test('Negative weights throw error', () {
        expect(
          () => df.sampleWeighted(n: 2, weights: [1, -1, 3, 4, 5]),
          throwsArgumentError,
        );
      });

      test('All zero weights throw error', () {
        expect(
          () => df.sampleWeighted(n: 2, weights: [0, 0, 0, 0, 0]),
          throwsArgumentError,
        );
      });

      test('Invalid weight column throws error', () {
        expect(
          () => df.sampleWeighted(n: 2, weights: 'invalid_column'),
          throwsArgumentError,
        );
      });

      test('Sample size exceeds DataFrame size without replacement', () {
        expect(
          () => df.sampleWeighted(n: 10, replace: false),
          throwsArgumentError,
        );
      });

      test('Take with invalid axis throws error', () {
        expect(
          () => df.take([0], axis: 2),
          throwsArgumentError,
        );
      });

      test('Negative sample size throws error', () {
        expect(
          () => df.sampleFrac(n: -1),
          throwsArgumentError,
        );
      });

      test('Zero sample size throws error', () {
        expect(
          () => df.sampleFrac(n: 0),
          throwsArgumentError,
        );
      });
    });

    group('Performance', () {
      test('Large weighted sample', () {
        final large = DataFrame.fromMap({
          'value': List.generate(1000, (i) => i),
          'weight': List.generate(1000, (i) => i + 1),
        });

        final sampled = large.sampleWeighted(
          n: 100,
          weights: 'weight',
          randomState: 42,
        );

        expect(sampled.rowCount, equals(100));
      });

      test('Large take operation', () {
        final large = DataFrame.fromMap({
          'value': List.generate(1000, (i) => i),
        });

        final indices = List.generate(100, (i) => i * 10);
        final result = large.take(indices);

        expect(result.rowCount, equals(100));
      });
    });
  });
}
