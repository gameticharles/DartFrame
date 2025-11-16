import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Advanced Reshaping Functions', () {
    group('swapLevel()', () {
      test('swap levels in multi-level index', () {
        var df = DataFrame([
          [1, 10],
          [2, 20],
          [3, 30],
        ], columns: [
          'A',
          'B'
        ]);

        // Create multi-level index
        df = DataFrame.fromMap(
          {'A': df['A'].toList(), 'B': df['B'].toList()},
          index: ['level0_level1', 'level0_level2', 'level1_level1'],
        );

        var swapped = df.swapLevel(0, 1);

        expect(swapped.index[0], equals('level1_level0'));
        expect(swapped.index[1], equals('level2_level0'));
        expect(swapped.index[2], equals('level1_level1'));
      });

      test('swap levels preserves data', () {
        var df = DataFrame([
          [1, 10],
          [2, 20],
        ], columns: [
          'A',
          'B'
        ]);

        df = DataFrame.fromMap(
          {'A': df['A'].toList(), 'B': df['B'].toList()},
          index: ['a_b', 'c_d'],
        );

        var swapped = df.swapLevel(0, 1);

        expect(swapped['A'][0], equals(1));
        expect(swapped['B'][0], equals(10));
        expect(swapped['A'][1], equals(2));
        expect(swapped['B'][1], equals(20));
      });

      test('swap levels with single-level index returns unchanged', () {
        var df = DataFrame([
          [1, 10],
          [2, 20],
        ], columns: [
          'A',
          'B'
        ]);

        var swapped = df.swapLevel(0, 1);

        expect(swapped.index[0], equals(0));
        expect(swapped.index[1], equals(1));
      });

      test('swap levels with invalid axis throws error', () {
        var df = DataFrame([
          [1],
        ], columns: [
          'A'
        ]);

        expect(
          () => df.swapLevel(0, 1, axis: 2),
          throwsArgumentError,
        );
      });
    });

    group('reorderLevels()', () {
      test('reorder levels in multi-level index', () {
        var df = DataFrame([
          [1],
          [2],
        ], columns: [
          'Value'
        ]);

        df = DataFrame.fromMap(
          {'Value': df['Value'].toList()},
          index: ['a_b_c', 'd_e_f'],
        );

        var reordered = df.reorderLevels([2, 0, 1]);

        expect(reordered.index[0], equals('c_a_b'));
        expect(reordered.index[1], equals('f_d_e'));
      });

      test('reorder levels preserves data', () {
        var df = DataFrame([
          [100],
        ], columns: [
          'Score'
        ]);

        df = DataFrame.fromMap(
          {'Score': df['Score'].toList()},
          index: ['x_y_z'],
        );

        var reordered = df.reorderLevels([1, 2, 0]);

        expect(reordered['Score'][0], equals(100));
      });

      test('reorder levels with out of bounds index throws error', () {
        var df = DataFrame([
          [1],
        ], columns: [
          'A'
        ]);

        df = DataFrame.fromMap(
          {'A': df['A'].toList()},
          index: ['a_b'],
        );

        expect(
          () => df.reorderLevels([0, 5]),
          throwsArgumentError,
        );
      });

      test('reorder levels with single-level index returns unchanged', () {
        var df = DataFrame([
          [1],
        ], columns: [
          'A'
        ]);

        var reordered = df.reorderLevels([0]);

        expect(reordered.index[0], equals(0));
      });
    });

    group('wideToLong()', () {
      test('wide to long basic transformation', () {
        var df = DataFrame([
          [1, 10, 15, 20, 25],
          [2, 30, 35, 40, 45],
        ], columns: [
          'id',
          'A_2020',
          'A_2021',
          'B_2020',
          'B_2021'
        ]);

        var long = df.wideToLong(
          stubnames: ['A', 'B'],
          i: ['id'],
          j: 'year',
          sep: '_',
        );

        expect(long.columns.contains('id'), isTrue);
        expect(long.columns.contains('year'), isTrue);
        expect(long.columns.contains('A'), isTrue);
        expect(long.columns.contains('B'), isTrue);
        expect(long.rowCount, equals(4)); // 2 rows * 2 years
      });

      test('wide to long with single stub', () {
        var df = DataFrame([
          [1, 100, 200],
          [2, 300, 400],
        ], columns: [
          'id',
          'value_2020',
          'value_2021'
        ]);

        var long = df.wideToLong(
          stubnames: ['value'],
          i: ['id'],
          j: 'year',
          sep: '_',
        );

        expect(long.rowCount, equals(4));
        expect(long['id'][0], equals(1));
        expect(long['year'][0], equals('2020'));
        expect(long['value'][0], equals(100));
      });

      test('wide to long with multiple id columns', () {
        var df = DataFrame([
          ['A', 1, 10, 20],
          ['B', 2, 30, 40],
        ], columns: [
          'group',
          'id',
          'score_pre',
          'score_post'
        ]);

        var long = df.wideToLong(
          stubnames: ['score'],
          i: ['group', 'id'],
          j: 'time',
          sep: '_',
          suffix: r'\w+', // Match word characters instead of just digits
        );

        expect(long.columns.contains('group'), isTrue);
        expect(long.columns.contains('id'), isTrue);
        expect(long.columns.contains('time'), isTrue);
        expect(long.rowCount, equals(4));
      });

      test('wide to long with missing id column throws error', () {
        var df = DataFrame([
          [1, 10],
        ], columns: [
          'id',
          'value'
        ]);

        expect(
          () => df.wideToLong(
            stubnames: ['value'],
            i: ['nonexistent'],
            j: 'time',
          ),
          throwsArgumentError,
        );
      });

      test('wide to long with no matching columns throws error', () {
        var df = DataFrame([
          [1, 10],
        ], columns: [
          'id',
          'value'
        ]);

        expect(
          () => df.wideToLong(
            stubnames: ['score'],
            i: ['id'],
            j: 'time',
            sep: '_',
          ),
          throwsArgumentError,
        );
      });

      test('wide to long handles missing stub values', () {
        var df = DataFrame([
          [1, 10, 20],
        ], columns: [
          'id',
          'A_2020',
          'B_2021'
        ]);

        var long = df.wideToLong(
          stubnames: ['A', 'B'],
          i: ['id'],
          j: 'year',
          sep: '_',
        );

        // Should have null for missing combinations
        expect(long.rowCount, equals(2));
      });
    });

    group('getDummiesEnhanced()', () {
      test('get dummies basic functionality', () {
        var df = DataFrame([
          ['A', 1],
          ['B', 2],
          ['A', 3],
        ], columns: [
          'Category',
          'Value'
        ]);

        var dummies = df.getDummiesEnhanced(columns: ['Category']);

        expect(dummies.columns.contains('Value'), isTrue);
        expect(dummies.columns.contains('Category_A'), isTrue);
        expect(dummies.columns.contains('Category_B'), isTrue);
        expect(dummies['Category_A'][0], equals(1));
        expect(dummies['Category_A'][1], equals(0));
        expect(dummies['Category_B'][1], equals(1));
      });

      test('get dummies with drop first', () {
        var df = DataFrame([
          ['A', 1],
          ['B', 2],
          ['C', 3],
        ], columns: [
          'Category',
          'Value'
        ]);

        var dummies = df.getDummiesEnhanced(
          columns: ['Category'],
          dropFirst: true,
        );

        expect(dummies.columns.contains('Category_A'), isFalse);
        expect(dummies.columns.contains('Category_B'), isTrue);
        expect(dummies.columns.contains('Category_C'), isTrue);
      });

      test('get dummies with custom prefix', () {
        var df = DataFrame([
          ['A'],
          ['B'],
        ], columns: [
          'Cat'
        ]);

        var dummies = df.getDummiesEnhanced(
          columns: ['Cat'],
          prefix: 'is',
        );

        expect(dummies.columns.contains('is_A'), isTrue);
        expect(dummies.columns.contains('is_B'), isTrue);
      });

      test('get dummies with custom separator', () {
        var df = DataFrame([
          ['A'],
          ['B'],
        ], columns: [
          'Category'
        ]);

        var dummies = df.getDummiesEnhanced(
          columns: ['Category'],
          prefixSep: '.',
        );

        expect(dummies.columns.contains('Category.A'), isTrue);
        expect(dummies.columns.contains('Category.B'), isTrue);
      });

      test('get dummies with boolean dtype', () {
        var df = DataFrame([
          ['A'],
          ['B'],
        ], columns: [
          'Category'
        ]);

        var dummies = df.getDummiesEnhanced(
          columns: ['Category'],
          dtype: 'bool',
        );

        expect(dummies['Category_A'][0], equals(true));
        expect(dummies['Category_A'][1], equals(false));
        expect(dummies['Category_B'][0], equals(false));
        expect(dummies['Category_B'][1], equals(true));
      });

      test('get dummies with dummy NA', () {
        var df = DataFrame([
          ['A'],
          [null],
          ['B'],
        ], columns: [
          'Category'
        ]);

        var dummies = df.getDummiesEnhanced(
          columns: ['Category'],
          dummyNa: true,
        );

        expect(dummies.columns.contains('Category_nan'), isTrue);
        expect(dummies['Category_nan'][0], equals(0));
        expect(dummies['Category_nan'][1], equals(1));
        expect(dummies['Category_nan'][2], equals(0));
      });

      test('get dummies with null columns auto-detects string columns', () {
        var df = DataFrame([
          ['A', 1, 'X'],
          ['B', 2, 'Y'],
        ], columns: [
          'Cat1',
          'Num',
          'Cat2'
        ]);

        var dummies = df.getDummiesEnhanced();

        expect(dummies.columns.contains('Num'), isTrue);
        expect(dummies.columns.contains('Cat1_A'), isTrue);
        expect(dummies.columns.contains('Cat2_X'), isTrue);
      });

      test('get dummies preserves non-converted columns', () {
        var df = DataFrame([
          ['A', 100, 'X'],
          ['B', 200, 'Y'],
        ], columns: [
          'Cat',
          'Value',
          'Type'
        ]);

        var dummies = df.getDummiesEnhanced(columns: ['Cat']);

        expect(dummies.columns.contains('Value'), isTrue);
        expect(dummies.columns.contains('Type'), isTrue);
        expect(dummies['Value'][0], equals(100));
      });

      test('get dummies with multiple columns', () {
        var df = DataFrame([
          ['A', 'X'],
          ['B', 'Y'],
        ], columns: [
          'Cat1',
          'Cat2'
        ]);

        var dummies = df.getDummiesEnhanced(columns: ['Cat1', 'Cat2']);

        expect(dummies.columns.contains('Cat1_A'), isTrue);
        expect(dummies.columns.contains('Cat1_B'), isTrue);
        expect(dummies.columns.contains('Cat2_X'), isTrue);
        expect(dummies.columns.contains('Cat2_Y'), isTrue);
      });

      test('get dummies with empty DataFrame', () {
        var df = DataFrame([], columns: ['Category']);

        var dummies = df.getDummiesEnhanced(columns: ['Category']);

        expect(dummies.rowCount, equals(0));
      });

      test('get dummies with single category', () {
        var df = DataFrame([
          ['A'],
          ['A'],
        ], columns: [
          'Category'
        ]);

        var dummies = df.getDummiesEnhanced(columns: ['Category']);

        expect(dummies.columns.contains('Category_A'), isTrue);
        expect(dummies['Category_A'][0], equals(1));
        expect(dummies['Category_A'][1], equals(1));
      });

      test('get dummies with drop first on single category', () {
        var df = DataFrame([
          ['A'],
          ['A'],
        ], columns: [
          'Category'
        ]);

        var dummies = df.getDummiesEnhanced(
          columns: ['Category'],
          dropFirst: true,
        );

        // With only one category and dropFirst=true, no dummy columns created
        expect(dummies.columns.contains('Category_A'), isFalse);
      });
    });

    group('Edge Cases', () {
      test('swap level with empty DataFrame', () {
        var df = DataFrame([], columns: ['A']);

        var swapped = df.swapLevel(0, 1);

        expect(swapped.rowCount, equals(0));
      });

      test('reorder levels with empty DataFrame', () {
        var df = DataFrame([], columns: ['A']);

        var reordered = df.reorderLevels([0]);

        expect(reordered.rowCount, equals(0));
      });

      test('wide to long with empty DataFrame', () {
        var df = DataFrame([], columns: ['id', 'A_2020', 'B_2020']);

        var long = df.wideToLong(
          stubnames: ['A', 'B'],
          i: ['id'],
          j: 'year',
          sep: '_',
        );

        expect(long.rowCount, equals(0));
      });

      test('get dummies with no string columns returns copy', () {
        var df = DataFrame([
          [1, 2],
          [3, 4],
        ], columns: [
          'A',
          'B'
        ]);

        var dummies = df.getDummiesEnhanced();

        expect(dummies.columns.length, equals(2));
        expect(dummies['A'][0], equals(1));
      });
    });
  });
}
