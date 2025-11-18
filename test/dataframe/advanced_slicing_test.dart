import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Advanced Slicing', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame.fromMap({
        'A': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        'B': [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
        'C': [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
      });
    });

    group('slice() with step', () {
      test('Every other row', () {
        final result = df.slice(start: 0, end: 10, step: 2);

        expect(result.rowCount, equals(5));
        expect(result['A'].data, equals([1, 3, 5, 7, 9]));
      });

      test('Every third row', () {
        final result = df.slice(start: 0, end: 10, step: 3);

        expect(result.rowCount, equals(4));
        expect(result['A'].data, equals([1, 4, 7, 10]));
      });

      test('Every other row starting from 1', () {
        final result = df.slice(start: 1, end: 10, step: 2);

        expect(result.rowCount, equals(5));
        expect(result['A'].data, equals([2, 4, 6, 8, 10]));
      });

      test('Reverse order with negative step', () {
        final result = df.slice(start: 9, end: -1, step: -1);

        expect(result.rowCount, equals(10));
        expect(result['A'].data, equals([10, 9, 8, 7, 6, 5, 4, 3, 2, 1]));
      });

      test('Every other row in reverse', () {
        final result = df.slice(start: 9, end: -1, step: -2);

        expect(result.rowCount, equals(5));
        expect(result['A'].data, equals([10, 8, 6, 4, 2]));
      });

      test('Slice columns with step', () {
        final result = df.slice(start: 0, end: 3, step: 2, axis: 1);

        expect(result.columns.length, equals(2));
        expect(result.columns, equals(['A', 'C']));
      });

      test('Default start and end', () {
        final result = df.slice(step: 2);

        expect(result.rowCount, equals(5));
        expect(result['A'].data, equals([1, 3, 5, 7, 9]));
      });

      test('Step of 1 returns all rows', () {
        final result = df.slice(start: 0, end: 10, step: 1);

        expect(result.rowCount, equals(10));
      });

      test('Zero step throws error', () {
        expect(() => df.slice(step: 0), throwsArgumentError);
      });
    });

    group('sliceByLabel()', () {
      late DataFrame dfLabeled;

      setUp(() {
        dfLabeled = DataFrame.fromMap({
          'value': [10, 20, 30, 40, 50]
        }, index: [
          'a',
          'b',
          'c',
          'd',
          'e'
        ]);
      });

      test('Slice from b to d', () {
        final result = dfLabeled.sliceByLabel(start: 'b', end: 'd');

        expect(result.rowCount, equals(3));
        expect(result['value'].data, equals([20, 30, 40]));
        expect(result.index, equals(['b', 'c', 'd']));
      });

      test('Slice from start to c', () {
        final result = dfLabeled.sliceByLabel(end: 'c');

        expect(result.rowCount, equals(3));
        expect(result['value'].data, equals([10, 20, 30]));
      });

      test('Slice from c to end', () {
        final result = dfLabeled.sliceByLabel(start: 'c');

        expect(result.rowCount, equals(3));
        expect(result['value'].data, equals([30, 40, 50]));
      });

      test('Slice columns by label', () {
        final dfMultiCol = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
          'C': [7, 8, 9],
          'D': [10, 11, 12]
        });

        final result = dfMultiCol.sliceByLabel(start: 'B', end: 'C', axis: 1);

        expect(result.columns.length, equals(2));
        expect(result.columns, equals(['B', 'C']));
      });

      test('Invalid start label throws error', () {
        expect(
          () => dfLabeled.sliceByLabel(start: 'z'),
          throwsArgumentError,
        );
      });

      test('Invalid end label throws error', () {
        expect(
          () => dfLabeled.sliceByLabel(end: 'z'),
          throwsArgumentError,
        );
      });
    });

    group('sliceByPosition()', () {
      test('Slice rows and columns', () {
        final result =
            df.sliceByPosition(rowSlice: [0, 5, 2], colSlice: [0, 2, 1]);

        expect(result.rowCount, equals(3));
        expect(result.columns.length, equals(2));
        expect(result['A'].data, equals([1, 3, 5]));
      });

      test('Slice only rows', () {
        final result = df.sliceByPosition(rowSlice: [0, 10, 3]);

        expect(result.rowCount, equals(4));
        expect(result.columns.length, equals(3));
      });

      test('Slice only columns', () {
        final result = df.sliceByPosition(colSlice: [0, 3, 2]);

        expect(result.rowCount, equals(10));
        expect(result.columns.length, equals(2));
      });
    });

    group('sliceByLabelWithStep()', () {
      late DataFrame dfLabeled;

      setUp(() {
        dfLabeled = DataFrame.fromMap({
          'A': [1, 2, 3, 4, 5],
          'B': [10, 20, 30, 40, 50],
          'C': [100, 200, 300, 400, 500]
        }, index: [
          'a',
          'b',
          'c',
          'd',
          'e'
        ]);
      });

      test('Slice with row step', () {
        final result = dfLabeled.sliceByLabelWithStep(
            rowStart: 'a', rowEnd: 'd', rowStep: 2);

        expect(result.rowCount, equals(2));
        expect(result.index, equals(['a', 'c']));
      });

      test('Slice with column step', () {
        final result = dfLabeled.sliceByLabelWithStep(
            colStart: 'A', colEnd: 'C', colStep: 2);

        expect(result.columns.length, equals(2));
        expect(result.columns, equals(['A', 'C']));
      });

      test('Slice both dimensions with step', () {
        final result = dfLabeled.sliceByLabelWithStep(
            rowStart: 'a',
            rowEnd: 'e',
            rowStep: 2,
            colStart: 'A',
            colEnd: 'C',
            colStep: 2);

        expect(result.rowCount, equals(3));
        expect(result.columns.length, equals(2));
      });
    });

    group('everyNthRow()', () {
      test('Every 2nd row', () {
        final result = df.everyNthRow(2);

        expect(result.rowCount, equals(5));
        expect(result['A'].data, equals([1, 3, 5, 7, 9]));
      });

      test('Every 3rd row', () {
        final result = df.everyNthRow(3);

        expect(result.rowCount, equals(4));
        expect(result['A'].data, equals([1, 4, 7, 10]));
      });

      test('Every 2nd row with offset', () {
        final result = df.everyNthRow(2, offset: 1);

        expect(result.rowCount, equals(5));
        expect(result['A'].data, equals([2, 4, 6, 8, 10]));
      });

      test('Every 5th row', () {
        final result = df.everyNthRow(5);

        expect(result.rowCount, equals(2));
        expect(result['A'].data, equals([1, 6]));
      });

      test('Zero or negative n throws error', () {
        expect(() => df.everyNthRow(0), throwsArgumentError);
        expect(() => df.everyNthRow(-1), throwsArgumentError);
      });
    });

    group('everyNthColumn()', () {
      test('Every 2nd column', () {
        final result = df.everyNthColumn(2);

        expect(result.columns.length, equals(2));
        expect(result.columns, equals(['A', 'C']));
      });

      test('Every 2nd column with offset', () {
        final result = df.everyNthColumn(2, offset: 1);

        expect(result.columns.length, equals(1));
        expect(result.columns, equals(['B']));
      });

      test('Every 3rd column', () {
        final result = df.everyNthColumn(3);

        expect(result.columns.length, equals(1));
        expect(result.columns, equals(['A']));
      });
    });

    group('reverseRows()', () {
      test('Reverse row order', () {
        final result = df.reverseRows();

        expect(result.rowCount, equals(10));
        expect(result['A'].data, equals([10, 9, 8, 7, 6, 5, 4, 3, 2, 1]));
        expect(result['B'].data,
            equals([100, 90, 80, 70, 60, 50, 40, 30, 20, 10]));
      });

      test('Reverse preserves columns', () {
        final result = df.reverseRows();

        expect(result.columns, equals(df.columns));
      });

      test('Double reverse returns original order', () {
        final result = df.reverseRows().reverseRows();

        expect(result['A'].data, equals(df['A'].data));
      });
    });

    group('reverseColumns()', () {
      test('Reverse column order', () {
        final result = df.reverseColumns();

        expect(result.columns.length, equals(3));
        expect(result.columns, equals(['C', 'B', 'A']));
      });

      test('Reverse preserves data', () {
        final result = df.reverseColumns();

        expect(result['A'].data, equals(df['A'].data));
        expect(result['B'].data, equals(df['B'].data));
        expect(result['C'].data, equals(df['C'].data));
      });

      test('Double reverse returns original order', () {
        final result = df.reverseColumns().reverseColumns();

        expect(result.columns, equals(df.columns));
      });
    });

    group('Real-world Use Cases', () {
      test('Downsample time series', () {
        final timeSeries =
            DataFrame.fromMap({'value': List.generate(100, (i) => i)});

        // Take every 10th point
        final downsampled = timeSeries.everyNthRow(10);

        expect(downsampled.rowCount, equals(10));
        expect(downsampled['value'].data[0], equals(0));
        expect(downsampled['value'].data[1], equals(10));
      });

      test('Select alternating features', () {
        final features = DataFrame.fromMap({
          'f1': [1],
          'f2': [2],
          'f3': [3],
          'f4': [4],
          'f5': [5],
          'f6': [6]
        });

        // Select every other feature
        final selected = features.everyNthColumn(2);

        expect(selected.columns, equals(['f1', 'f3', 'f5']));
      });

      test('Reverse chronological order', () {
        final events = DataFrame.fromMap({
          'event': ['first', 'second', 'third', 'fourth', 'fifth']
        });

        final reversed = events.reverseRows();

        expect(reversed['event'].data,
            equals(['fifth', 'fourth', 'third', 'second', 'first']));
      });

      test('Slice training data range', () {
        final data = DataFrame.fromMap({'value': List.generate(100, (i) => i)},
            index: List.generate(100, (i) => 'row_$i'));

        // Get rows 20-80
        final train = data.sliceByLabel(start: 'row_20', end: 'row_80');

        expect(train.rowCount, equals(61)); // Inclusive on both ends
      });

      test('Sample every nth observation', () {
        final observations = DataFrame.fromMap(
            {'measurement': List.generate(1000, (i) => i * 0.1)});

        // Sample every 100th observation
        final sampled = observations.everyNthRow(100);

        expect(sampled.rowCount, equals(10));
      });
    });

    group('Edge Cases', () {
      test('Slice empty DataFrame', () {
        final empty = DataFrame.fromMap({'A': []});

        final result = empty.slice(step: 2);

        expect(result.rowCount, equals(0));
      });

      test('Step larger than DataFrame', () {
        final small = DataFrame.fromMap({
          'A': [1, 2, 3]
        });

        final result = small.everyNthRow(10);

        expect(result.rowCount, equals(1));
        expect(result['A'].data, equals([1]));
      });

      test('Reverse single row', () {
        final single = DataFrame.fromMap({
          'A': [1]
        });

        final result = single.reverseRows();

        expect(result.rowCount, equals(1));
        expect(result['A'].data, equals([1]));
      });

      test('Slice with start equals end', () {
        final result = df.slice(start: 5, end: 5);

        expect(result.rowCount, equals(0));
      });
    });
  });
}
