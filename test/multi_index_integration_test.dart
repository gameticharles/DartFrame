import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('MultiIndex Integration with DataFrame', () {
    group('setMultiIndex()', () {
      test('Set MultiIndex on DataFrame', () {
        final df = DataFrame.fromMap({
          'value': [10, 20, 30, 40]
        });

        final idx = MultiIndex.fromArrays([
          ['A', 'A', 'B', 'B'],
          [1, 2, 1, 2]
        ], names: [
          'letter',
          'number'
        ]);

        final dfIndexed = df.setMultiIndex(idx);

        expect(dfIndexed.rowCount, equals(4));
        expect(dfIndexed.hasMultiIndex, isTrue);
        expect(dfIndexed.indexLevels, equals(2));
      });

      test('MultiIndex length must match DataFrame', () {
        final df = DataFrame.fromMap({
          'value': [10, 20, 30]
        });

        final idx = MultiIndex.fromArrays([
          ['A', 'B'],
          [1, 2]
        ]);

        expect(() => df.setMultiIndex(idx), throwsArgumentError);
      });
    });

    group('setIndexFromColumns()', () {
      test('Create MultiIndex from columns', () {
        final df = DataFrame.fromMap({
          'letter': ['A', 'A', 'B', 'B'],
          'number': [1, 2, 1, 2],
          'value': [10, 20, 30, 40]
        });

        final dfIndexed = df.setIndexFromColumns(['letter', 'number']);

        expect(dfIndexed.hasMultiIndex, isTrue);
        expect(dfIndexed.indexLevels, equals(2));
        expect(dfIndexed.columns.length, equals(1)); // Only 'value' remains
        expect(dfIndexed.columns, contains('value'));
      });

      test('Keep columns when drop=false', () {
        final df = DataFrame.fromMap({
          'letter': ['A', 'A', 'B', 'B'],
          'number': [1, 2, 1, 2],
          'value': [10, 20, 30, 40]
        });

        final dfIndexed =
            df.setIndexFromColumns(['letter', 'number'], drop: false);

        expect(dfIndexed.hasMultiIndex, isTrue);
        expect(dfIndexed.columns.length, equals(3)); // All columns remain
      });

      test('Throws error for non-existent column', () {
        final df = DataFrame.fromMap({
          'value': [10, 20, 30]
        });

        expect(
          () => df.setIndexFromColumns(['invalid']),
          throwsArgumentError,
        );
      });
    });

    group('resetMultiIndex()', () {
      test('Reset MultiIndex to integer index', () {
        final df = DataFrame.fromMap({
          'letter': ['A', 'A', 'B', 'B'],
          'number': [1, 2, 1, 2],
          'value': [10, 20, 30, 40]
        });

        final dfIndexed = df.setIndexFromColumns(['letter', 'number']);
        final dfReset = dfIndexed.resetMultiIndex();

        expect(dfReset.hasMultiIndex, isFalse);
        expect(dfReset.columns.length, equals(3)); // level_0, level_1, value
        expect(dfReset.index, equals([0, 1, 2, 3]));
      });

      test('Reset with drop=true', () {
        final df = DataFrame.fromMap({
          'letter': ['A', 'A', 'B', 'B'],
          'number': [1, 2, 1, 2],
          'value': [10, 20, 30, 40]
        });

        final dfIndexed = df.setIndexFromColumns(['letter', 'number']);
        final dfReset = dfIndexed.resetMultiIndex(drop: true);

        expect(dfReset.hasMultiIndex, isFalse);
        expect(dfReset.columns.length, equals(1)); // Only 'value'
        expect(dfReset.index, equals([0, 1, 2, 3]));
      });
    });

    group('selectByMultiIndex()', () {
      late DataFrame dfIndexed;

      setUp(() {
        final df = DataFrame.fromMap({
          'value': [10, 20, 30, 40]
        });

        final idx = MultiIndex.fromArrays([
          ['A', 'A', 'B', 'B'],
          [1, 2, 1, 2]
        ], names: [
          'letter',
          'number'
        ]);

        dfIndexed = df.setMultiIndex(idx);
      });

      test('Select by first level', () {
        final result = dfIndexed.selectByMultiIndex(['A']);

        expect(result.rowCount, equals(2));
        expect(result['value'].data, equals([10, 20]));
      });

      test('Select by full tuple', () {
        final result = dfIndexed.selectByMultiIndex(['A', 1]);

        expect(result.rowCount, equals(1));
        expect(result['value'].data, equals([10]));
      });

      test('Select by different first level', () {
        final result = dfIndexed.selectByMultiIndex(['B']);

        expect(result.rowCount, equals(2));
        expect(result['value'].data, equals([30, 40]));
      });

      test('Throws error on non-MultiIndex DataFrame', () {
        final df = DataFrame.fromMap({
          'value': [10, 20, 30]
        });

        expect(() => df.selectByMultiIndex(['A']), throwsStateError);
      });
    });

    group('groupByIndexLevel()', () {
      late DataFrame dfIndexed;

      setUp(() {
        final df = DataFrame.fromMap({
          'value': [10, 20, 30, 40]
        });

        final idx = MultiIndex.fromArrays([
          ['A', 'A', 'B', 'B'],
          [1, 2, 1, 2]
        ], names: [
          'letter',
          'number'
        ]);

        dfIndexed = df.setMultiIndex(idx);
      });

      test('Group by first level', () {
        final groups = dfIndexed.groupByIndexLevel(0);

        expect(groups.length, equals(2));
        expect(groups.containsKey('A'), isTrue);
        expect(groups.containsKey('B'), isTrue);

        expect(groups['A']!.rowCount, equals(2));
        expect(groups['B']!.rowCount, equals(2));
      });

      test('Group by second level', () {
        final groups = dfIndexed.groupByIndexLevel(1);

        expect(groups.length, equals(2));
        expect(groups.containsKey(1), isTrue);
        expect(groups.containsKey(2), isTrue);

        expect(groups[1]!.rowCount, equals(2));
        expect(groups[2]!.rowCount, equals(2));
      });

      test('Group by multiple levels', () {
        final groups = dfIndexed.groupByIndexLevel([0, 1]);

        expect(groups.length, equals(4));

        // Check that we have the right number of groups
        // List keys don't work well with containsKey, so check length and values
        expect(groups.values.every((df) => df.rowCount == 1), isTrue);
      });
    });

    group('Real-world Examples', () {
      test('Sales data with region and product hierarchy', () {
        final df = DataFrame.fromMap({
          'region': ['North', 'North', 'South', 'South'],
          'product': ['Widget', 'Gadget', 'Widget', 'Gadget'],
          'sales': [100, 150, 120, 180],
          'profit': [20, 30, 25, 35]
        });

        // Set hierarchical index
        final dfIndexed = df.setIndexFromColumns(['region', 'product']);

        expect(dfIndexed.hasMultiIndex, isTrue);
        expect(dfIndexed.columns, equals(['sales', 'profit']));

        // Select all North region sales
        final north = dfIndexed.selectByMultiIndex(['North']);
        expect(north.rowCount, equals(2));

        // Group by region
        final byRegion = dfIndexed.groupByIndexLevel(0);
        expect(byRegion.length, equals(2));
      });

      test('Time series with category hierarchy', () {
        final df = DataFrame.fromMap({
          'category': ['Electronics', 'Electronics', 'Clothing', 'Clothing'],
          'subcategory': ['Laptop', 'Phone', 'Shirt', 'Pants'],
          'date': [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 2),
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 2)
          ],
          'quantity': [5, 8, 12, 15]
        });

        // Create hierarchical index
        final dfIndexed = df.setIndexFromColumns(['category', 'subcategory']);

        // Select all electronics
        final electronics = dfIndexed.selectByMultiIndex(['Electronics']);
        expect(electronics.rowCount, equals(2));
        expect(electronics['quantity'].data, equals([5, 8]));

        // Reset index to get back original structure
        final dfReset = dfIndexed.resetMultiIndex();
        expect(dfReset.columns.length, equals(4));
      });

      test('Multi-level aggregation', () {
        final df = DataFrame.fromMap({
          'dept': ['Sales', 'Sales', 'IT', 'IT'],
          'team': ['A', 'B', 'A', 'B'],
          'revenue': [1000, 1500, 800, 1200]
        });

        final dfIndexed = df.setIndexFromColumns(['dept', 'team']);

        // Group by department
        final byDept = dfIndexed.groupByIndexLevel(0);

        // Calculate total revenue per department
        final salesTotal =
            byDept['Sales']!['revenue'].data.reduce((a, b) => a + b);
        final itTotal = byDept['IT']!['revenue'].data.reduce((a, b) => a + b);

        expect(salesTotal, equals(2500));
        expect(itTotal, equals(2000));
      });
    });
  });

  group('DatetimeIndex Integration with DataFrame', () {
    group('setDatetimeIndex()', () {
      test('Set DatetimeIndex on DataFrame', () {
        final df = DataFrame.fromMap({
          'value': [10, 20, 30, 40, 50]
        });

        final idx = DatetimeIndex.dateRange(
          start: DateTime(2024, 1, 1),
          periods: 5,
          frequency: 'D',
        );

        final dfIndexed = df.setDatetimeIndex(idx);

        expect(dfIndexed.rowCount, equals(5));
        expect(dfIndexed.hasDatetimeIndex, isTrue);
      });

      test('DatetimeIndex length must match DataFrame', () {
        final df = DataFrame.fromMap({
          'value': [10, 20, 30]
        });

        final idx = DatetimeIndex.dateRange(
          start: DateTime(2024, 1, 1),
          periods: 5,
          frequency: 'D',
        );

        expect(() => df.setDatetimeIndex(idx), throwsArgumentError);
      });
    });

    group('setDatetimeIndexFromColumn()', () {
      test('Create DatetimeIndex from column', () {
        final df = DataFrame.fromMap({
          'date': [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 2),
            DateTime(2024, 1, 3)
          ],
          'value': [10, 20, 30]
        });

        final dfIndexed = df.setDatetimeIndexFromColumn('date');

        expect(dfIndexed.hasDatetimeIndex, isTrue);
        expect(dfIndexed.columns.length, equals(1)); // Only 'value' remains
      });

      test('Keep column when drop=false', () {
        final df = DataFrame.fromMap({
          'date': [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 2),
            DateTime(2024, 1, 3)
          ],
          'value': [10, 20, 30]
        });

        final dfIndexed = df.setDatetimeIndexFromColumn('date', drop: false);

        expect(dfIndexed.hasDatetimeIndex, isTrue);
        expect(dfIndexed.columns.length, equals(2)); // Both columns remain
      });

      test('Throws error for non-DateTime column', () {
        final df = DataFrame.fromMap({
          'value': [10, 20, 30]
        });

        expect(
          () => df.setDatetimeIndexFromColumn('value'),
          throwsArgumentError,
        );
      });
    });

    group('Real-world Examples', () {
      test('Time series analysis with DatetimeIndex', () {
        final df = DataFrame.fromMap({
          'date': [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 2),
            DateTime(2024, 1, 3),
            DateTime(2024, 1, 4),
            DateTime(2024, 1, 5)
          ],
          'price': [100, 102, 98, 105, 103],
          'volume': [1000, 1500, 800, 2000, 1200]
        });

        // Set datetime index
        final dfIndexed = df.setDatetimeIndexFromColumn('date');

        expect(dfIndexed.hasDatetimeIndex, isTrue);
        expect(dfIndexed.columns, equals(['price', 'volume']));

        // Now can use time series operations
        final lagged = dfIndexed.lag(1);
        expect(lagged['price'].data[0], isNull);
        expect(lagged['price'].data[1], equals(100));
      });

      test('Combining DatetimeIndex with time series operations', () {
        final df = DataFrame.fromMap({
          'timestamp': [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
            DateTime(2024, 1, 1, 12, 0)
          ],
          'temperature': [20, 22, 24, 23]
        });

        final dfIndexed = df.setDatetimeIndexFromColumn('timestamp');

        // Can now use time-based operations
        final morning = dfIndexed.atTime('09:00:00');
        expect(morning.rowCount, equals(1));
        expect(morning['temperature'].data[0], equals(20));
      });
    });
  });
}
