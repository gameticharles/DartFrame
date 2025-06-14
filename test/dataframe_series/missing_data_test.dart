import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Series Missing Data Functions:', () {
    group('Series.isna()', () {
      test('Basic functionality with nulls', () {
        final s = Series([1, null, 3, null, 5], name: 's_nulls');
        final expected = Series([false, true, false, true, false],
            name: 's_nulls_isna', index: s.index);
        final result = s.isna();
        expect(result.data, equals(expected.data));
        expect(result.name, equals(expected.name));
        expect(result.index, equals(expected.index));
        expect(result.dtype, equals(bool));
      });

      test('No missing values', () {
        final s = Series([1, 2, 3], name: 's_no_nulls');
        final expected = Series([false, false, false],
            name: 's_no_nulls_isna', index: s.index);
        final result = s.isna();
        expect(result.data, equals(expected.data));
        expect(result.name, equals(expected.name));
      });

      test('All missing values (null)', () {
        final s = Series([null, null, null], name: 's_all_nulls');
        final expected = Series([true, true, true],
            name: 's_all_nulls_isna', index: s.index);
        final result = s.isna();
        expect(result.data, equals(expected.data));
        expect(result.name, equals(expected.name));
      });

      test('Empty series', () {
        final s = Series([], name: 's_empty');
        final expected = Series([], name: 's_empty_isna', index: s.index);
        final result = s.isna();
        expect(result.data, equals(expected.data));
        expect(result.name, equals(expected.name));
      });

      test('Custom missing value (-999) via DataFrame context', () {
        final df = DataFrame.fromRows([
          {'colA': 1},
          {'colA': -999},
          {'colA': 3},
        ], replaceMissingValueWith: -999);
        final s = df['colA'];
        final expected =
            Series([false, true, false], name: 'colA_isna', index: s.index);
        final result = s.isna();
        expect(result.data, equals(expected.data));
        expect(result.name, equals(expected.name));
      });

      test('Custom missing value ("NA") via DataFrame context', () {
        final df = DataFrame.fromRows([
          {'colA': 'apple'},
          {'colA': 'NA'},
          {'colA': 'banana'},
        ], replaceMissingValueWith: 'NA');
        final s = df['colA'];
        final expected =
            Series([false, true, false], name: 'colA_isna', index: s.index);
        final result = s.isna();
        expect(result.data, equals(expected.data));
        expect(result.name, equals(expected.name));
      });

      test('Series of int with null', () {
        final s = Series([1, 2, null, 4], name: 's_int_null');
        final expected = Series([false, false, true, false],
            name: 's_int_null_isna', index: s.index);
        final result = s.isna();
        expect(result.data, equals(expected.data));
      });

      test('Series of double with null', () {
        final s = Series([1.1, null, 3.3], name: 's_double_null');
        final expected = Series([false, true, false],
            name: 's_double_null_isna', index: s.index);
        final result = s.isna();
        expect(result.data, equals(expected.data));
      });

      test('Series of bool with null', () {
        final s = Series([true, false, null], name: 's_bool_null');
        final expected = Series([false, false, true],
            name: 's_bool_null_isna', index: s.index);
        final result = s.isna();
        expect(result.data, equals(expected.data));
      });
    });

    group('Series.notna()', () {
      test('Basic functionality with nulls', () {
        final s = Series([1, null, 3, null, 5], name: 's_nulls');
        final expected = Series([true, false, true, false, true],
            name: 's_nulls_notna', index: s.index);
        final result = s.notna();
        expect(result.data, equals(expected.data));
        expect(result.name, equals(expected.name));
        expect(result.index, equals(expected.index));
        expect(result.dtype, equals(bool));
      });

      test('No missing values', () {
        final s = Series([1, 2, 3], name: 's_no_nulls');
        final expected = Series([true, true, true],
            name: 's_no_nulls_notna', index: s.index);
        final result = s.notna();
        expect(result.data, equals(expected.data));
        expect(result.name, equals(expected.name));
      });

      test('All missing values (null)', () {
        final s = Series([null, null, null], name: 's_all_nulls');
        final expected = Series([false, false, false],
            name: 's_all_nulls_notna', index: s.index);
        final result = s.notna();
        expect(result.data, equals(expected.data));
        expect(result.name, equals(expected.name));
      });

      test('Custom missing value (-1) via DataFrame context', () {
        final df = DataFrame.fromRows([
          {'colA': 1},
          {'colA': -1},
          {'colA': 0},
        ], replaceMissingValueWith: -1);
        final s = df['colA'];
        final expected =
            Series([true, false, true], name: 'colA_notna', index: s.index);
        final result = s.notna();
        expect(result.data, equals(expected.data));
        expect(result.name, equals(expected.name));
      });
    });
  });

  group('DataFrame Missing Data Functions:', () {
    final df1 = DataFrame.fromRows([
      {'A': 1, 'B': 'x', 'C': null},
      {'A': null, 'B': 'y', 'C': true},
      {'A': 3, 'B': null, 'C': false},
    ]);
    df1.replaceMissingValueWith = null; // Explicit for clarity

    final dfNoMissing = DataFrame.fromRows([
      {'X': 1, 'Y': 'a'},
      {'X': 2, 'Y': 'b'},
    ]);

    final dfAllMissing = DataFrame.fromRows([
      {'M': null, 'N': null},
      {'M': null, 'N': null},
    ], columns: [
      'M',
      'N'
    ]);
    dfAllMissing.replaceMissingValueWith = null;

    final dfCustomMissing = DataFrame.fromRows([
      {'P': 10, 'Q': 'val1'},
      {'P': -99, 'Q': 'MISSING'},
      {'P': 30, 'Q': 'val2'},
    ], replaceMissingValueWith: -99);
    // Note: 'MISSING' string won't be treated as NA unless replaceMissingValueWith is 'MISSING'
    // or we have per-column missing value markers (not current feature).
    // For this test, -99 is NA for column P. For Q, only actual null would be NA by default.

    final dfCustomMissingStr = DataFrame.fromRows([
      {'P': 10, 'Q': 'val1'},
      {'P': -99, 'Q': 'MISSING'},
      {'P': 30, 'Q': 'val2'},
    ], replaceMissingValueWith: 'MISSING');

    group('DataFrame.isna()', () {
      test('Basic functionality with nulls', () {
        final result = df1.isna();
        expect(result.columns, equals(df1.columns));
        expect(result.rowCount, equals(df1.rowCount));
        expect(
            result.rows,
            equals([
              [false, false, true],
              [true, false, false],
              [false, true, false],
            ]));
        expect(result.column('A').dtype, equals(bool));
        expect(result.column('B').dtype, equals(bool));
        expect(result.column('C').dtype, equals(bool));
      });

      test('No missing values', () {
        final result = dfNoMissing.isna();
        expect(
            result.rows,
            equals([
              [false, false],
              [false, false],
            ]));
      });

      test('All missing values (null)', () {
        final result = dfAllMissing.isna();
        expect(
            result.rows,
            equals([
              [true, true],
              [true, true],
            ]));
      });

      test('Custom missing value (-99) for numeric column', () {
        final result = dfCustomMissing.isna();
        // For column P, -99 is NA. For Q, only actual null is NA.
        expect(result.column('P').data, equals([false, true, false]));
        expect(result.column('Q').data,
            equals([false, false, false])); // 'MISSING' is a valid string here
      });

      test('Custom missing value ("MISSING") for string column', () {
        final result = dfCustomMissingStr.isna();
        // For column Q, "MISSING" is NA. For P, only actual null is NA.
        expect(result.column('P').data,
            equals([false, false, false])); // -99 is a valid number here
        expect(result.column('Q').data, equals([false, true, false]));
      });

      test('Empty DataFrame (no rows, with columns)', () {
        final dfEmptyRows = DataFrame.fromNames(['X', 'Y']);
        final result = dfEmptyRows.isna();
        expect(result.rowCount, equals(0));
        expect(result.columns, equals(['X', 'Y']));
      });

      test('Empty DataFrame (no columns, with rows)', () {
        final dfEmptyCols = DataFrame.fromRows([{}, {}]);
        final result = dfEmptyCols.isna();
        expect(result.rowCount, equals(2));
        expect(result.columnCount, equals(0));
      });

      test('Empty DataFrame (no rows, no columns)', () {
        final dfEmpty = DataFrame.fromNames([]);
        final result = dfEmpty.isna();
        expect(result.rowCount, equals(0));
        expect(result.columnCount, equals(0));
      });
    });

    group('DataFrame.notna()', () {
      test('Basic functionality with nulls', () {
        final result = df1.notna();
        expect(result.columns, equals(df1.columns));
        expect(result.rowCount, equals(df1.rowCount));
        expect(
            result.rows,
            equals([
              [true, true, false],
              [false, true, true],
              [true, false, true],
            ]));
        expect(result.column('A').dtype, equals(bool));
      });

      test('No missing values', () {
        final result = dfNoMissing.notna();
        expect(
            result.rows,
            equals([
              [true, true],
              [true, true],
            ]));
      });

      test('All missing values (null)', () {
        final result = dfAllMissing.notna();
        expect(
            result.rows,
            equals([
              [false, false],
              [false, false],
            ]));
      });

      test('Custom missing value (-99) for numeric column', () {
        final result = dfCustomMissing.notna();
        expect(result.column('P').data, equals([true, false, true]));
        expect(result.column('Q').data, equals([true, true, true]));
      });
    });
  });
}
