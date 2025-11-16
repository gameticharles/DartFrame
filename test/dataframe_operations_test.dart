import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame Operations', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame([
        [1, 10, 1.5],
        [2, 20, 2.5],
        [3, 30, 3.5],
        [4, 40, 4.5],
        [5, 50, 5.5],
      ], columns: [
        'A',
        'B',
        'C'
      ]);
    });

    group('clip()', () {
      test('clips values with both lower and upper bounds', () {
        var result = df.clip(lower: 2, upper: 4);

        expect(result.rowCount, equals(5));
        expect(result.columnCount, equals(3));

        var aValues = result['A'].toList();
        expect(aValues, equals([2, 2, 3, 4, 4]));

        // Column B values are also clipped since they're numeric
        var bValues = result['B'].toList();
        expect(bValues, equals([4, 4, 4, 4, 4]));
      });

      test('clips values with only lower bound', () {
        var result = df.clip(lower: 3);

        var aValues = result['A'].toList();
        expect(aValues, equals([3, 3, 3, 4, 5]));
      });

      test('clips values with only upper bound', () {
        var result = df.clip(upper: 3);

        var aValues = result['A'].toList();
        expect(aValues, equals([1, 2, 3, 3, 3]));
      });

      test('clips decimal values', () {
        var result = df.clip(lower: 2.0, upper: 4.0);

        var cValues = result['C'].toList();
        expect(cValues, equals([2.0, 2.5, 3.5, 4.0, 4.0]));
      });

      test('throws error when neither lower nor upper specified', () {
        expect(
          () => df.clip(),
          throwsArgumentError,
        );
      });

      test('throws error when lower > upper', () {
        expect(
          () => df.clip(lower: 5, upper: 2),
          throwsArgumentError,
        );
      });

      test('handles negative values', () {
        var negDf = DataFrame([
          [-5, -50],
          [-3, -30],
          [-1, -10],
          [1, 10],
          [3, 30],
        ], columns: [
          'A',
          'B'
        ]);

        var result = negDf.clip(lower: -2, upper: 2);

        var aValues = result['A'].toList();
        expect(aValues, equals([-2, -2, -1, 1, 2]));
      });

      test('handles mixed numeric and non-numeric columns', () {
        var mixedDf = DataFrame([
          ['a', 1, 10],
          ['b', 2, 20],
          ['c', 3, 30],
        ], columns: [
          'text',
          'int',
          'float'
        ]);

        var result = mixedDf.clip(lower: 2, upper: 25);

        expect(result['text'].toList(), equals(['a', 'b', 'c']));
        expect(result['int'].toList(), equals([2, 2, 3]));
        expect(result['float'].toList(), equals([10, 20, 25]));
      });

      test('handles null values', () {
        var nullDf = DataFrame([
          [1, null],
          [2, 20],
          [null, 30],
        ], columns: [
          'A',
          'B'
        ]);

        var result = nullDf.clip(lower: 2, upper: 25);

        expect(result['A'].toList()[0], equals(2));
        expect(result['A'].toList()[1], equals(2));
        expect(result['A'].toList()[2], isNull);
        expect(result['B'].toList()[0], isNull);
      });

      test('preserves index', () {
        var indexedDf = DataFrame(
          [
            [1],
            [2],
            [3]
          ],
          columns: ['A'],
          index: ['x', 'y', 'z'],
        );

        var result = indexedDf.clip(lower: 2);

        expect(result.index, equals(['x', 'y', 'z']));
      });

      test('works with single value DataFrame', () {
        var singleDf = DataFrame([
          [5]
        ], columns: [
          'A'
        ]);

        var result = singleDf.clip(lower: 3, upper: 7);

        expect(result['A'].toList()[0], equals(5));
      });

      test('clips all values when outside range', () {
        var result = df.clip(lower: 10, upper: 20);

        var aValues = result['A'].toList();
        expect(aValues, equals([10, 10, 10, 10, 10]));
      });
    });

    group('abs()', () {
      test('computes absolute values', () {
        var negDf = DataFrame([
          [-1, -10],
          [2, -20],
          [-3, 30],
          [4, -40],
          [-5, 50],
        ], columns: [
          'A',
          'B'
        ]);

        var result = negDf.abs();

        expect(result['A'].toList(), equals([1, 2, 3, 4, 5]));
        expect(result['B'].toList(), equals([10, 20, 30, 40, 50]));
      });

      test('handles positive values', () {
        var result = df.abs();

        expect(result['A'].toList(), equals([1, 2, 3, 4, 5]));
        expect(result['B'].toList(), equals([10, 20, 30, 40, 50]));
      });

      test('handles zero', () {
        var zeroDf = DataFrame([
          [0, -0],
          [-0, 0],
        ], columns: [
          'A',
          'B'
        ]);

        var result = zeroDf.abs();

        expect(result['A'].toList(), equals([0, 0]));
        expect(result['B'].toList(), equals([0, 0]));
      });

      test('handles decimal values', () {
        var decimalDf = DataFrame([
          [-1.5, 2.5],
          [3.5, -4.5],
        ], columns: [
          'A',
          'B'
        ]);

        var result = decimalDf.abs();

        expect(result['A'].toList(), equals([1.5, 3.5]));
        expect(result['B'].toList(), equals([2.5, 4.5]));
      });

      test('handles mixed numeric and non-numeric columns', () {
        var mixedDf = DataFrame([
          ['a', -1, -10.5],
          ['b', 2, -20.5],
        ], columns: [
          'text',
          'int',
          'float'
        ]);

        var result = mixedDf.abs();

        expect(result['text'].toList(), equals(['a', 'b']));
        expect(result['int'].toList(), equals([1, 2]));
        expect(result['float'].toList(), equals([10.5, 20.5]));
      });

      test('handles null values', () {
        var nullDf = DataFrame([
          [-1, null],
          [null, -20],
        ], columns: [
          'A',
          'B'
        ]);

        var result = nullDf.abs();

        expect(result['A'].toList()[0], equals(1));
        expect(result['A'].toList()[1], isNull);
        expect(result['B'].toList()[0], isNull);
        expect(result['B'].toList()[1], equals(20));
      });

      test('preserves index', () {
        var indexedDf = DataFrame(
          [
            [-1],
            [-2]
          ],
          columns: ['A'],
          index: ['x', 'y'],
        );

        var result = indexedDf.abs();

        expect(result.index, equals(['x', 'y']));
      });
    });

    group('round()', () {
      test('rounds to specified decimals', () {
        var decimalDf = DataFrame([
          [1.234, 10.567],
          [2.345, 20.678],
          [3.456, 30.789],
        ], columns: [
          'A',
          'B'
        ]);

        var result = decimalDf.round(2);

        expect(result['A'].toList()[0], closeTo(1.23, 0.01));
        expect(result['A'].toList()[1], closeTo(2.35, 0.01));
        expect(result['B'].toList()[0], closeTo(10.57, 0.01));
      });

      test('rounds to integers when decimals=0', () {
        var decimalDf = DataFrame([
          [1.4, 10.6],
          [2.5, 20.5],
          [3.6, 30.4],
        ], columns: [
          'A',
          'B'
        ]);

        var result = decimalDf.round(0);

        // Note: Dart's round() uses "round half away from zero" for .5 values
        expect(result['A'].toList(), equals([1.0, 3.0, 4.0]));
        expect(result['B'].toList(), equals([11.0, 21.0, 30.0]));
      });

      test('rounds to 1 decimal', () {
        var decimalDf = DataFrame([
          [1.234],
          [2.567],
        ], columns: [
          'A'
        ]);

        var result = decimalDf.round(1);

        expect(result['A'].toList()[0], closeTo(1.2, 0.01));
        expect(result['A'].toList()[1], closeTo(2.6, 0.01));
      });

      test('handles negative values', () {
        var negDf = DataFrame([
          [-1.234, -10.567],
          [-2.345, -20.678],
        ], columns: [
          'A',
          'B'
        ]);

        var result = negDf.round(2);

        expect(result['A'].toList()[0], closeTo(-1.23, 0.01));
        expect(result['B'].toList()[0], closeTo(-10.57, 0.01));
      });

      test('handles integers', () {
        var result = df.round(2);

        expect(result['A'].toList(), equals([1, 2, 3, 4, 5]));
        expect(result['B'].toList(), equals([10, 20, 30, 40, 50]));
      });

      test('handles mixed numeric and non-numeric columns', () {
        var mixedDf = DataFrame([
          ['a', 1.234, 10.567],
          ['b', 2.345, 20.678],
        ], columns: [
          'text',
          'float1',
          'float2'
        ]);

        var result = mixedDf.round(1);

        expect(result['text'].toList(), equals(['a', 'b']));
        expect(result['float1'].toList()[0], closeTo(1.2, 0.01));
        expect(result['float2'].toList()[0], closeTo(10.6, 0.01));
      });

      test('handles null values', () {
        var nullDf = DataFrame([
          [1.234, null],
          [null, 20.678],
        ], columns: [
          'A',
          'B'
        ]);

        var result = nullDf.round(1);

        expect(result['A'].toList()[0], closeTo(1.2, 0.01));
        expect(result['A'].toList()[1], isNull);
        expect(result['B'].toList()[0], isNull);
        expect(result['B'].toList()[1], closeTo(20.7, 0.01));
      });

      test('throws error for negative decimals', () {
        expect(
          () => df.round(-1),
          throwsArgumentError,
        );
      });

      test('preserves index', () {
        var indexedDf = DataFrame(
          [
            [1.234]
          ],
          columns: ['A'],
          index: ['x'],
        );

        var result = indexedDf.round(1);

        expect(result.index, equals(['x']));
      });

      test('rounds to 3 decimals', () {
        var decimalDf = DataFrame([
          [1.23456],
          [2.34567],
        ], columns: [
          'A'
        ]);

        var result = decimalDf.round(3);

        expect(result['A'].toList()[0], closeTo(1.235, 0.001));
        expect(result['A'].toList()[1], closeTo(2.346, 0.001));
      });
    });

    group('Integration Tests', () {
      test('clip and abs can be chained', () {
        var negDf = DataFrame([
          [-5, -50],
          [-3, -30],
          [1, 10],
          [3, 30],
          [5, 50],
        ], columns: [
          'A',
          'B'
        ]);

        var result = negDf.clip(lower: -2, upper: 2).abs();

        expect(result['A'].toList(), equals([2, 2, 1, 2, 2]));
      });

      test('abs and round can be chained', () {
        var decimalDf = DataFrame([
          [-1.234, -10.567],
          [2.345, 20.678],
        ], columns: [
          'A',
          'B'
        ]);

        var result = decimalDf.abs().round(1);

        expect(result['A'].toList()[0], closeTo(1.2, 0.01));
        expect(result['B'].toList()[0], closeTo(10.6, 0.01));
      });

      test('clip and round can be chained', () {
        var decimalDf = DataFrame([
          [1.234, 10.567],
          [2.345, 20.678],
          [3.456, 30.789],
        ], columns: [
          'A',
          'B'
        ]);

        var result = decimalDf.clip(lower: 2.0, upper: 3.0).round(1);

        expect(result['A'].toList()[0], closeTo(2.0, 0.01));
        expect(result['A'].toList()[1], closeTo(2.3, 0.01));
        expect(result['A'].toList()[2], closeTo(3.0, 0.01));
      });

      test('all three operations can be chained', () {
        var df = DataFrame([
          [-5.678, -50.123],
          [3.456, 30.789],
        ], columns: [
          'A',
          'B'
        ]);

        var result = df.clip(lower: -3, upper: 3).abs().round(1);

        expect(result['A'].toList()[0], closeTo(3.0, 0.01));
        expect(result['A'].toList()[1], closeTo(3.0, 0.01));
      });
    });

    group('Edge Cases', () {
      test('handles empty DataFrame', () {
        var emptyDf = DataFrame.empty(columns: ['A', 'B']);

        var clipped = emptyDf.clip(lower: 0, upper: 10);
        var absed = emptyDf.abs();
        var rounded = emptyDf.round(0);

        expect(clipped.rowCount, equals(0));
        expect(absed.rowCount, equals(0));
        expect(rounded.rowCount, equals(0));
      });

      test('handles single row DataFrame', () {
        var singleRow = DataFrame([
          [1.234, -5.678]
        ], columns: [
          'A',
          'B'
        ]);

        var clipped = singleRow.clip(lower: 0, upper: 5);
        var absed = singleRow.abs();
        var rounded = singleRow.round(1);

        expect(clipped['A'].toList()[0], closeTo(1.234, 0.001));
        expect(absed['B'].toList()[0], closeTo(5.678, 0.001));
        expect(rounded['A'].toList()[0], closeTo(1.2, 0.01));
      });

      test('handles single column DataFrame', () {
        var singleCol = DataFrame([
          [1.234],
          [2.345],
          [3.456],
        ], columns: [
          'A'
        ]);

        var clipped = singleCol.clip(lower: 2, upper: 3);
        var absed = singleCol.abs();
        var rounded = singleCol.round(1);

        expect(clipped.columnCount, equals(1));
        expect(absed.columnCount, equals(1));
        expect(rounded.columnCount, equals(1));
      });
    });
  });
}
