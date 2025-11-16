import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Window Ranking Functions', () {
    group('rank()', () {
      test('rank with average method (default)', () {
        var df = DataFrame([
          [1.0, 100],
          [2.0, 100],
          [3.0, 200],
          [4.0, 300],
        ], columns: [
          'A',
          'B'
        ]);

        var ranked = df.rankWindow(columns: ['B'], method: 'average');

        expect(ranked['B'][0], equals(1.5));
        expect(ranked['B'][1], equals(1.5));
        expect(ranked['B'][2], equals(3.0));
        expect(ranked['B'][3], equals(4.0));
      });

      test('rank with min method', () {
        var df = DataFrame([
          [100],
          [100],
          [200],
          [300],
        ], columns: [
          'Score'
        ]);

        var ranked = df.rankWindow(columns: ['Score'], method: 'min');

        expect(ranked['Score'][0], equals(1.0));
        expect(ranked['Score'][1], equals(1.0));
        expect(ranked['Score'][2], equals(3.0));
        expect(ranked['Score'][3], equals(4.0));
      });

      test('rank with max method', () {
        var df = DataFrame([
          [100],
          [100],
          [200],
          [300],
        ], columns: [
          'Score'
        ]);

        var ranked = df.rankWindow(columns: ['Score'], method: 'max');

        expect(ranked['Score'][0], equals(2.0));
        expect(ranked['Score'][1], equals(2.0));
        expect(ranked['Score'][2], equals(3.0));
        expect(ranked['Score'][3], equals(4.0));
      });

      test('rank with first method', () {
        var df = DataFrame([
          [100],
          [100],
          [200],
        ], columns: [
          'Score'
        ]);

        var ranked = df.rankWindow(columns: ['Score'], method: 'first');

        expect(ranked['Score'][0], equals(1.0));
        expect(ranked['Score'][1], equals(2.0));
        expect(ranked['Score'][2], equals(3.0));
      });

      test('rank with dense method', () {
        var df = DataFrame([
          [100],
          [100],
          [200],
          [300],
        ], columns: [
          'Score'
        ]);

        var ranked = df.rankWindow(columns: ['Score'], method: 'dense');

        expect(ranked['Score'][0], equals(1.0));
        expect(ranked['Score'][1], equals(1.0));
        expect(ranked['Score'][2], equals(2.0));
        expect(ranked['Score'][3], equals(3.0));
      });

      test('rank with descending order', () {
        var df = DataFrame([
          [100],
          [200],
          [300],
        ], columns: [
          'Score'
        ]);

        var ranked = df.rankWindow(columns: ['Score'], ascending: false);

        expect(ranked['Score'][0], equals(3.0));
        expect(ranked['Score'][1], equals(2.0));
        expect(ranked['Score'][2], equals(1.0));
      });

      test('rank with percentile', () {
        var df = DataFrame([
          [100],
          [200],
          [300],
          [400],
        ], columns: [
          'Score'
        ]);

        var ranked = df.rankWindow(columns: ['Score'], pct: true);

        expect(ranked['Score'][0], equals(0.25));
        expect(ranked['Score'][1], equals(0.5));
        expect(ranked['Score'][2], equals(0.75));
        expect(ranked['Score'][3], equals(1.0));
      });

      test('rank multiple columns', () {
        var df = DataFrame([
          [1, 100],
          [2, 200],
          [3, 100],
        ], columns: [
          'A',
          'B'
        ]);

        var ranked = df.rankWindow(columns: ['A', 'B']);

        expect(ranked['A'][0], equals(1.0));
        expect(ranked['A'][1], equals(2.0));
        expect(ranked['A'][2], equals(3.0));
        expect(ranked['B'][0], equals(1.5));
        expect(ranked['B'][1], equals(3.0));
        expect(ranked['B'][2], equals(1.5));
      });

      test('rank with invalid method throws error', () {
        var df = DataFrame([
          [1],
          [2],
        ], columns: [
          'A'
        ]);

        expect(
          () => df.rankWindow(columns: ['A'], method: 'invalid'),
          throwsArgumentError,
        );
      });

      test('rank with non-existent column throws error', () {
        var df = DataFrame([
          [1],
          [2],
        ], columns: [
          'A'
        ]);

        expect(
          () => df.rankWindow(columns: ['B']),
          throwsArgumentError,
        );
      });
    });

    group('denseRank()', () {
      test('dense rank basic functionality', () {
        var df = DataFrame([
          [100],
          [100],
          [200],
          [300],
        ], columns: [
          'Score'
        ]);

        var ranked = df.denseRank(columns: ['Score']);

        expect(ranked['Score'][0], equals(1.0));
        expect(ranked['Score'][1], equals(1.0));
        expect(ranked['Score'][2], equals(2.0));
        expect(ranked['Score'][3], equals(3.0));
      });

      test('dense rank with gaps in values', () {
        var df = DataFrame([
          [10],
          [10],
          [50],
          [50],
          [100],
        ], columns: [
          'Value'
        ]);

        var ranked = df.denseRank(columns: ['Value']);

        expect(ranked['Value'][0], equals(1.0));
        expect(ranked['Value'][1], equals(1.0));
        expect(ranked['Value'][2], equals(2.0));
        expect(ranked['Value'][3], equals(2.0));
        expect(ranked['Value'][4], equals(3.0));
      });

      test('dense rank descending', () {
        var df = DataFrame([
          [100],
          [200],
          [200],
          [300],
        ], columns: [
          'Score'
        ]);

        var ranked = df.denseRank(columns: ['Score'], ascending: false);

        expect(ranked['Score'][0], equals(3.0));
        expect(ranked['Score'][1], equals(2.0));
        expect(ranked['Score'][2], equals(2.0));
        expect(ranked['Score'][3], equals(1.0));
      });
    });

    group('rowNumber()', () {
      test('row number basic functionality', () {
        var df = DataFrame([
          ['Alice', 100],
          ['Bob', 200],
          ['Charlie', 150],
        ], columns: [
          'Name',
          'Score'
        ]);

        var numbered = df.rowNumber();

        expect(numbered.columns.contains('row_number'), isTrue);
        expect(numbered['row_number'][0], equals(1));
        expect(numbered['row_number'][1], equals(2));
        expect(numbered['row_number'][2], equals(3));
      });

      test('row number with custom column name', () {
        var df = DataFrame([
          [1],
          [2],
          [3],
        ], columns: [
          'Value'
        ]);

        var numbered = df.rowNumber(columnName: 'id');

        expect(numbered.columns.contains('id'), isTrue);
        expect(numbered['id'][0], equals(1));
        expect(numbered['id'][1], equals(2));
        expect(numbered['id'][2], equals(3));
      });

      test('row number preserves original columns', () {
        var df = DataFrame([
          ['A', 10],
          ['B', 20],
        ], columns: [
          'Letter',
          'Number'
        ]);

        var numbered = df.rowNumber();

        expect(numbered.columns.length, equals(3));
        expect(numbered['Letter'][0], equals('A'));
        expect(numbered['Number'][0], equals(10));
      });

      test('row number on empty DataFrame', () {
        var df = DataFrame([], columns: ['A']);

        var numbered = df.rowNumber();

        expect(numbered['row_number'].length, equals(0));
      });
    });

    group('percentRank()', () {
      test('percent rank basic functionality', () {
        var df = DataFrame([
          [100],
          [200],
          [300],
          [400],
        ], columns: [
          'Score'
        ]);

        var pctRank = df.percentRank(columns: ['Score']);

        expect(pctRank['Score'][0], closeTo(0.0, 0.001));
        expect(pctRank['Score'][1], closeTo(0.333, 0.001));
        expect(pctRank['Score'][2], closeTo(0.667, 0.001));
        expect(pctRank['Score'][3], closeTo(1.0, 0.001));
      });

      test('percent rank with ties', () {
        var df = DataFrame([
          [100],
          [100],
          [200],
          [300],
        ], columns: [
          'Score'
        ]);

        var pctRank = df.percentRank(columns: ['Score']);

        // Both 100s get rank 1, so (1-1)/(4-1) = 0
        expect(pctRank['Score'][0], equals(0.0));
        expect(pctRank['Score'][1], equals(0.0));
        // 200 gets rank 3, so (3-1)/(4-1) = 0.667
        expect(pctRank['Score'][2], closeTo(0.667, 0.001));
        // 300 gets rank 4, so (4-1)/(4-1) = 1.0
        expect(pctRank['Score'][3], equals(1.0));
      });

      test('percent rank descending', () {
        var df = DataFrame([
          [100],
          [200],
          [300],
        ], columns: [
          'Score'
        ]);

        var pctRank = df.percentRank(columns: ['Score'], ascending: false);

        expect(pctRank['Score'][0], equals(1.0));
        expect(pctRank['Score'][1], equals(0.5));
        expect(pctRank['Score'][2], equals(0.0));
      });

      test('percent rank with single row', () {
        var df = DataFrame([
          [100],
        ], columns: [
          'Score'
        ]);

        var pctRank = df.percentRank(columns: ['Score']);

        expect(pctRank['Score'][0], equals(0.0));
      });

      test('percent rank with two rows', () {
        var df = DataFrame([
          [100],
          [200],
        ], columns: [
          'Score'
        ]);

        var pctRank = df.percentRank(columns: ['Score']);

        expect(pctRank['Score'][0], equals(0.0));
        expect(pctRank['Score'][1], equals(1.0));
      });
    });

    group('cumulativeDistribution()', () {
      test('cumulative distribution basic functionality', () {
        var df = DataFrame([
          [100],
          [200],
          [300],
          [400],
        ], columns: [
          'Score'
        ]);

        var cumeDist = df.cumulativeDistribution(columns: ['Score']);

        expect(cumeDist['Score'][0], equals(0.25));
        expect(cumeDist['Score'][1], equals(0.5));
        expect(cumeDist['Score'][2], equals(0.75));
        expect(cumeDist['Score'][3], equals(1.0));
      });

      test('cumulative distribution with ties', () {
        var df = DataFrame([
          [100],
          [200],
          [200],
          [300],
        ], columns: [
          'Score'
        ]);

        var cumeDist = df.cumulativeDistribution(columns: ['Score']);

        expect(cumeDist['Score'][0], equals(0.25));
        // Both 200s: 3 values <= 200, so 3/4 = 0.75
        expect(cumeDist['Score'][1], equals(0.75));
        expect(cumeDist['Score'][2], equals(0.75));
        expect(cumeDist['Score'][3], equals(1.0));
      });

      test('cumulative distribution descending', () {
        var df = DataFrame([
          [100],
          [200],
          [300],
        ], columns: [
          'Score'
        ]);

        var cumeDist =
            df.cumulativeDistribution(columns: ['Score'], ascending: false);

        // In descending: 100 has 1 value >= 100 (all 3), so 3/3 = 1.0
        expect(cumeDist['Score'][0], equals(1.0));
        // 200 has 2 values >= 200, so 2/3 = 0.667
        expect(cumeDist['Score'][1], closeTo(0.667, 0.001));
        // 300 has 1 value >= 300, so 1/3 = 0.333
        expect(cumeDist['Score'][2], closeTo(0.333, 0.001));
      });

      test('cumulative distribution on empty DataFrame', () {
        var df = DataFrame([], columns: ['Score']);

        var cumeDist = df.cumulativeDistribution(columns: ['Score']);

        expect(cumeDist['Score'].length, equals(0));
      });

      test('cumulative distribution with single value', () {
        var df = DataFrame([
          [100],
        ], columns: [
          'Score'
        ]);

        var cumeDist = df.cumulativeDistribution(columns: ['Score']);

        expect(cumeDist['Score'][0], equals(1.0));
      });
    });

    group('Edge Cases', () {
      test('ranking with all equal values', () {
        var df = DataFrame([
          [100],
          [100],
          [100],
        ], columns: [
          'Score'
        ]);

        var ranked = df.rankWindow(columns: ['Score'], method: 'average');

        expect(ranked['Score'][0], equals(2.0));
        expect(ranked['Score'][1], equals(2.0));
        expect(ranked['Score'][2], equals(2.0));
      });

      test('ranking with mixed numeric types', () {
        var df = DataFrame([
          [1],
          [2.5],
          [3],
        ], columns: [
          'Value'
        ]);

        var ranked = df.rankWindow(columns: ['Value']);

        expect(ranked['Value'][0], equals(1.0));
        expect(ranked['Value'][1], equals(2.0));
        expect(ranked['Value'][2], equals(3.0));
      });

      test('ranking preserves non-ranked columns', () {
        var df = DataFrame([
          ['A', 100],
          ['B', 200],
          ['C', 150],
        ], columns: [
          'Name',
          'Score'
        ]);

        var ranked = df.rankWindow(columns: ['Score']);

        expect(ranked['Name'][0], equals('A'));
        expect(ranked['Name'][1], equals('B'));
        expect(ranked['Name'][2], equals('C'));
      });

      test('ranking with null columns parameter ranks all columns', () {
        var df = DataFrame([
          [1, 10],
          [2, 20],
        ], columns: [
          'A',
          'B'
        ]);

        var ranked = df.rankWindow();

        expect(ranked['A'][0], equals(1.0));
        expect(ranked['B'][0], equals(1.0));
      });
    });
  });
}
