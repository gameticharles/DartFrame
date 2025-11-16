import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame qcut()', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame([
        [1, 100, 10.0],
        [2, 200, 20.0],
        [3, 300, 30.0],
        [4, 400, 40.0],
        [5, 500, 50.0],
        [6, 600, 60.0],
        [7, 700, 70.0],
        [8, 800, 80.0],
      ], columns: [
        'A',
        'B',
        'C'
      ]);
    });

    test('discretizes single column into quartiles', () {
      var result = df.qcut('A', 4);

      expect(result.rowCount, equals(8));
      expect(result.columnCount, equals(3));

      // Column A should be discretized
      var aValues = result['A'].toList();
      expect(aValues.every((v) => v is String), isTrue);

      // Other columns should remain unchanged
      expect(result['B'].toList(), equals(df['B'].toList()));
      expect(result['C'].toList(), equals(df['C'].toList()));
    });

    test('discretizes multiple columns', () {
      var result = df.qcut(['A', 'B'], 3);

      expect(result.rowCount, equals(8));

      // Both A and B should be discretized
      var aValues = result['A'].toList();
      var bValues = result['B'].toList();
      expect(aValues.every((v) => v is String), isTrue);
      expect(bValues.every((v) => v is String), isTrue);

      // Column C should remain unchanged
      expect(result['C'].toList(), equals(df['C'].toList()));
    });

    test('works with custom labels', () {
      var result = df.qcut('A', 3, labels: ['Low', 'Medium', 'High']);

      var aValues = result['A'].toList();
      expect(
          aValues.every((v) => ['Low', 'Medium', 'High'].contains(v)), isTrue);
    });

    test('works with integer indicators when labels=false', () {
      var result = df.qcut('A', 4, labels: false);

      var aValues = result['A'].toList();
      expect(aValues.every((v) => v is int), isTrue);
    });

    test('works with custom quantiles', () {
      var result = df.qcut('A', [0, 0.25, 0.5, 0.75, 1.0]);

      expect(result.rowCount, equals(8));
      var aValues = result['A'].toList();
      expect(aValues.every((v) => v is String), isTrue);
    });

    test('throws error for non-existent column', () {
      expect(
        () => df.qcut('NonExistent', 4),
        throwsArgumentError,
      );
    });

    test('throws error for invalid columns parameter', () {
      expect(
        () => df.qcut(123, 4),
        throwsArgumentError,
      );
    });

    test('preserves index', () {
      var indexedDf = DataFrame(
        [
          [1],
          [2],
          [3],
          [4]
        ],
        columns: ['A'],
        index: ['w', 'x', 'y', 'z'],
      );

      var result = indexedDf.qcut('A', 2);

      expect(result.index, equals(['w', 'x', 'y', 'z']));
    });

    test('handles precision parameter', () {
      var result = df.qcut('A', 2, precision: 1);

      expect(result.rowCount, equals(8));
      var aValues = result['A'].toList();
      expect(aValues.every((v) => v is String), isTrue);
    });

    test('handles duplicates parameter', () {
      var dfDuplicates = DataFrame([
        [1, 100],
        [1, 200],
        [1, 300],
        [2, 400],
      ], columns: [
        'A',
        'B'
      ]);

      // With duplicates='drop', should not throw
      var result = dfDuplicates.qcut('A', 3, duplicates: 'drop');
      expect(result.rowCount, equals(4));
    });

    test('works with single column DataFrame', () {
      var singleCol = DataFrame([
        [1],
        [2],
        [3],
        [4],
      ], columns: [
        'A'
      ]);

      var result = singleCol.qcut('A', 2);

      expect(result.columnCount, equals(1));
      expect(result.rowCount, equals(4));
    });

    test('discretizes all specified columns independently', () {
      var result = df.qcut(['A', 'C'], 2);

      // Each column should have its own bins
      var aValues = result['A'].toList();
      var cValues = result['C'].toList();

      expect(aValues.every((v) => v is String), isTrue);
      expect(cValues.every((v) => v is String), isTrue);
    });

    test('handles empty column list', () {
      var result = df.qcut([], 4);

      // Should return unchanged DataFrame
      expect(result['A'].toList(), equals(df['A'].toList()));
      expect(result['B'].toList(), equals(df['B'].toList()));
    });

    test('can be chained with other operations', () {
      var result = df.qcut('A', 3).clip(lower: 0, upper: 1000);

      expect(result.rowCount, equals(8));
    });

    test('works with different q values', () {
      var result2 = df.qcut('A', 2);
      var result3 = df.qcut('A', 3);
      var result5 = df.qcut('A', 5);

      expect(result2.rowCount, equals(8));
      expect(result3.rowCount, equals(8));
      expect(result5.rowCount, equals(8));
    });
  });

  group('DataFrame qcut() Edge Cases', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame([
        [1, 100, 10.0],
        [2, 200, 20.0],
        [3, 300, 30.0],
        [4, 400, 40.0],
        [5, 500, 50.0],
        [6, 600, 60.0],
        [7, 700, 70.0],
        [8, 800, 80.0],
      ], columns: [
        'A',
        'B',
        'C'
      ]);
    });

    test('handles DataFrame with null values', () {
      var dfWithNull = DataFrame([
        [1, 100],
        [null, 200],
        [3, 300],
        [4, 400],
      ], columns: [
        'A',
        'B'
      ]);

      var result = dfWithNull.qcut('A', 2);

      expect(result.rowCount, equals(4));
    });

    test('handles small DataFrame', () {
      var small = DataFrame([
        [1, 10],
        [2, 20],
      ], columns: [
        'A',
        'B'
      ]);

      var result = small.qcut('A', 2);

      expect(result.rowCount, equals(2));
    });

    test('handles large number of quantiles', () {
      var result = df.qcut('A', 8);

      expect(result.rowCount, equals(8));
    });
  });

  group('DataFrame qcut() Real-World Examples', () {
    test('categorizes income levels', () {
      var income = DataFrame([
        [25000],
        [35000],
        [45000],
        [55000],
        [65000],
        [75000],
        [85000],
        [95000],
      ], columns: [
        'Income'
      ]);

      var result = income.qcut(
        'Income',
        4,
        labels: ['Low', 'Medium-Low', 'Medium-High', 'High'],
      );

      var categories = result['Income'].toList();
      expect(categories.every((v) => v is String), isTrue);
      expect(categories.contains('Low'), isTrue);
      expect(categories.contains('High'), isTrue);
    });

    test('creates age groups', () {
      var ages = DataFrame([
        [18, 'Alice'],
        [25, 'Bob'],
        [35, 'Charlie'],
        [45, 'David'],
        [55, 'Eve'],
        [65, 'Frank'],
      ], columns: [
        'Age',
        'Name'
      ]);

      var result = ages.qcut(
        'Age',
        3,
        labels: ['Young', 'Middle', 'Senior'],
      );

      expect(result['Name'].toList(), equals(ages['Name'].toList()));
      var ageGroups = result['Age'].toList();
      expect(ageGroups.every((v) => ['Young', 'Middle', 'Senior'].contains(v)),
          isTrue);
    });

    test('segments customer spending', () {
      var spending = DataFrame([
        [100, 'Customer1'],
        [200, 'Customer2'],
        [300, 'Customer3'],
        [400, 'Customer4'],
        [500, 'Customer5'],
      ], columns: [
        'Spending',
        'Customer'
      ]);

      var result = spending.qcut('Spending', 3);

      expect(result.rowCount, equals(5));
      expect(
          result['Customer'].toList(), equals(spending['Customer'].toList()));
    });
  });
}
