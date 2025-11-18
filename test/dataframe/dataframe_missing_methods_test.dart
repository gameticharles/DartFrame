import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame Missing Methods', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame([
        [100, 200, 1.0],
        [110, 220, 1.1],
        [121, 242, 1.21],
        [133, 266, 1.33],
      ], columns: [
        'A',
        'B',
        'C'
      ], index: [
        'w',
        'x',
        'y',
        'z'
      ]);
    });

    group('pctChange()', () {
      test('calculates percentage change', () {
        var result = df.pctChange();

        expect(result.rowCount, equals(4));
        expect(result['A'].toList()[0], isNull);
        expect(result['A'].toList()[1], closeTo(0.1, 0.01));
        expect(result['A'].toList()[2], closeTo(0.1, 0.01));
      });

      test('handles periods parameter', () {
        var result = df.pctChange(periods: 2);

        expect(result['A'].toList()[0], isNull);
        expect(result['A'].toList()[1], isNull);
        expect(result['A'].toList()[2], closeTo(0.21, 0.01));
      });

      test('handles null values', () {
        var dfWithNull = DataFrame([
          [100, null],
          [110, 220],
          [null, 242],
        ], columns: [
          'A',
          'B'
        ]);

        var result = dfWithNull.pctChange();

        expect(result['A'].toList()[1], closeTo(0.1, 0.01));
        expect(result['A'].toList()[2], isNull);
        expect(result['B'].toList()[1], isNull);
      });

      test('handles division by zero', () {
        var dfWithZero = DataFrame([
          [0, 10],
          [5, 20],
        ], columns: [
          'A',
          'B'
        ]);

        var result = dfWithZero.pctChange();

        expect(result['A'].toList()[1], isNull);
        expect(result['B'].toList()[1], equals(1.0));
      });

      test('throws error for non-positive periods', () {
        expect(() => df.pctChange(periods: 0), throwsArgumentError);
        expect(() => df.pctChange(periods: -1), throwsArgumentError);
      });

      test('preserves index', () {
        var result = df.pctChange();
        expect(result.index, equals(['w', 'x', 'y', 'z']));
      });
    });

    group('diff()', () {
      test('calculates first difference', () {
        var result = df.diff();

        expect(result.rowCount, equals(4));
        expect(result['A'].toList()[0], isNull);
        expect(result['A'].toList()[1], equals(10));
        expect(result['A'].toList()[2], equals(11));
      });

      test('handles periods parameter', () {
        var result = df.diff(periods: 2);

        expect(result['A'].toList()[0], isNull);
        expect(result['A'].toList()[1], isNull);
        expect(result['A'].toList()[2], equals(21));
      });

      test('handles null values', () {
        var dfWithNull = DataFrame([
          [100, null],
          [110, 220],
          [null, 242],
        ], columns: [
          'A',
          'B'
        ]);

        var result = dfWithNull.diff();

        expect(result['A'].toList()[1], equals(10));
        expect(result['A'].toList()[2], isNull);
        expect(result['B'].toList()[1], isNull);
      });

      test('handles negative differences', () {
        var dfDesc = DataFrame([
          [100, 200],
          [90, 180],
          [85, 170],
        ], columns: [
          'A',
          'B'
        ]);

        var result = dfDesc.diff();

        expect(result['A'].toList()[1], equals(-10));
        expect(result['A'].toList()[2], equals(-5));
      });

      test('throws error for non-positive periods', () {
        expect(() => df.diff(periods: 0), throwsArgumentError);
        expect(() => df.diff(periods: -1), throwsArgumentError);
      });

      test('preserves index', () {
        var result = df.diff();
        expect(result.index, equals(['w', 'x', 'y', 'z']));
      });
    });

    group('idxmax()', () {
      test('returns index of maximum values', () {
        var result = df.idxmax();

        expect(result.name, equals('idxmax'));
        expect(result.data[0], equals('z')); // Column A max at index z
        expect(result.data[1], equals('z')); // Column B max at index z
        expect(result.index, equals(['A', 'B', 'C']));
      });

      test('handles ties (keeps first)', () {
        var dfTies = DataFrame([
          [1, 10],
          [3, 10],
          [2, 5],
        ], columns: [
          'A',
          'B'
        ], index: [
          'x',
          'y',
          'z'
        ]);

        var result = dfTies.idxmax();

        expect(result.data[0], equals('y')); // A max at y
        expect(result.data[1], equals('x')); // B max at x (first occurrence)
      });

      test('handles null values with skipna=true', () {
        var dfWithNull = DataFrame([
          [1, null],
          [3, 20],
          [null, 15],
        ], columns: [
          'A',
          'B'
        ], index: [
          'x',
          'y',
          'z'
        ]);

        var result = dfWithNull.idxmax(skipna: true);

        expect(result.data[0], equals('y'));
        expect(result.data[1], equals('y'));
      });

      test('handles all null column', () {
        var dfAllNull = DataFrame([
          [1, null],
          [2, null],
        ], columns: [
          'A',
          'B'
        ], index: [
          'x',
          'y'
        ]);

        var result = dfAllNull.idxmax();

        expect(result.data[0], equals('y'));
        expect(result.data[1], isNull);
      });

      test('handles negative values', () {
        var dfNeg = DataFrame([
          [-5, -50],
          [-3, -30],
          [-10, -100],
        ], columns: [
          'A',
          'B'
        ], index: [
          'x',
          'y',
          'z'
        ]);

        var result = dfNeg.idxmax();

        expect(result.data[0], equals('y')); // -3 is max
        expect(result.data[1], equals('y')); // -30 is max
      });
    });

    group('idxmin()', () {
      test('returns index of minimum values', () {
        var result = df.idxmin();

        expect(result.name, equals('idxmin'));
        expect(result.data[0], equals('w')); // Column A min at index w
        expect(result.data[1], equals('w')); // Column B min at index w
        expect(result.index, equals(['A', 'B', 'C']));
      });

      test('handles ties (keeps first)', () {
        var dfTies = DataFrame([
          [1, 5],
          [3, 10],
          [1, 5],
        ], columns: [
          'A',
          'B'
        ], index: [
          'x',
          'y',
          'z'
        ]);

        var result = dfTies.idxmin();

        expect(result.data[0], equals('x')); // A min at x (first occurrence)
        expect(result.data[1], equals('x')); // B min at x (first occurrence)
      });

      test('handles null values with skipna=true', () {
        var dfWithNull = DataFrame([
          [null, 20],
          [3, null],
          [1, 15],
        ], columns: [
          'A',
          'B'
        ], index: [
          'x',
          'y',
          'z'
        ]);

        var result = dfWithNull.idxmin(skipna: true);

        expect(result.data[0], equals('z'));
        expect(result.data[1], equals('z'));
      });

      test('handles all null column', () {
        var dfAllNull = DataFrame([
          [1, null],
          [2, null],
        ], columns: [
          'A',
          'B'
        ], index: [
          'x',
          'y'
        ]);

        var result = dfAllNull.idxmin();

        expect(result.data[0], equals('x'));
        expect(result.data[1], isNull);
      });

      test('handles negative values', () {
        var dfNeg = DataFrame([
          [-5, -50],
          [-3, -30],
          [-10, -100],
        ], columns: [
          'A',
          'B'
        ], index: [
          'x',
          'y',
          'z'
        ]);

        var result = dfNeg.idxmin();

        expect(result.data[0], equals('z')); // -10 is min
        expect(result.data[1], equals('z')); // -100 is min
      });
    });

    group('Integration Tests', () {
      test('pctChange and diff can be chained', () {
        var pct = df.pctChange();
        var diffPct = pct.diff();

        expect(diffPct.rowCount, equals(4));
      });

      test('idxmax and idxmin work together', () {
        var maxIdx = df.idxmax();
        var minIdx = df.idxmin();

        expect(maxIdx.data[0], equals('z'));
        expect(minIdx.data[0], equals('w'));
      });

      test('all methods preserve DataFrame structure', () {
        var pct = df.pctChange();
        var diff = df.diff();
        var maxIdx = df.idxmax();
        var minIdx = df.idxmin();

        expect(pct.columns, equals(df.columns));
        expect(diff.columns, equals(df.columns));
        expect(maxIdx.length, equals(df.columnCount));
        expect(minIdx.length, equals(df.columnCount));
      });
    });

    group('Edge Cases', () {
      test('handles empty DataFrame', () {
        var empty = DataFrame.empty(columns: ['A', 'B']);

        var pct = empty.pctChange();
        var diff = empty.diff();
        var maxIdx = empty.idxmax();
        var minIdx = empty.idxmin();

        expect(pct.rowCount, equals(0));
        expect(diff.rowCount, equals(0));
        expect(maxIdx.length, equals(2));
        expect(minIdx.length, equals(2));
      });

      test('handles single row DataFrame', () {
        var single = DataFrame([
          [1, 2]
        ], columns: [
          'A',
          'B'
        ]);

        var pct = single.pctChange();
        var diff = single.diff();

        expect(pct['A'].toList()[0], isNull);
        expect(diff['A'].toList()[0], isNull);
      });

      test('handles non-numeric columns', () {
        var mixed = DataFrame([
          ['a', 1, 10],
          ['b', 2, 20],
        ], columns: [
          'text',
          'int',
          'float'
        ]);

        var pct = mixed.pctChange();
        var diff = mixed.diff();

        expect(pct['text'].toList()[1], isNull);
        expect(diff['text'].toList()[1], isNull);
        expect(pct['int'].toList()[1], equals(1.0));
        expect(diff['int'].toList()[1], equals(1));
      });
    });
  });
}
