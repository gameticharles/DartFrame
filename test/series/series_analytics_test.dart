import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  const missingMarker = -999;

  group('Series.nunique()', () {
    test('nunique basic with duplicates', () {
      final s = Series([1, 2, 1, 3, 2, 4, 1, 5], name: 'numbers');
      expect(s.nunique(), 5);
    });

    test('nunique no duplicates', () {
      final s = Series([1, 2, 3, 4, 5], name: 'no_dupes');
      expect(s.nunique(), 5);
    });

    test('nunique with null values', () {
      // nunique counts non-missing unique values. null is typically missing.
      final s = Series([1, null, 2, null, 1, 3], name: 'null_nunique');
      expect(s.nunique(), 3); // 1, 2, 3 are unique non-missing
    });

    test('nunique with custom missing marker', () {
      var df = DataFrame.fromMap({
        'col1': [10, missingMarker, 20, 10, missingMarker, 30]
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');
      expect(s.nunique(), 3); // 10, 20, 30
    });

    test('nunique on empty series', () {
      final s = Series([], name: 'empty');
      expect(s.nunique(), 0);
    });

    test('nunique with all same non-missing values', () {
      final s = Series([7, 7, 7, 7], name: 'sevens');
      expect(s.nunique(), 1);
    });

    test('nunique with all missing values (null)', () {
      final s = Series([null, null, null], name: 'all_nulls');
      expect(s.nunique(), 0);
    });

    test('nunique with all missing values (custom marker)', () {
      var df = DataFrame.fromMap({
        'col1': [missingMarker, missingMarker, missingMarker]
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');
      expect(s.nunique(), 0);
    });
  });

  group('Series.valueCounts()', () {
    test('valueCounts basic', () {
      final s = Series(['a', 'b', 'a', 'c', 'a', 'b'], name: 'letters');
      final counts = s.valueCounts(); // sort=true, ascending=false by default
      expect(counts.index, equals(['a', 'b', 'c']));
      expect(counts.data, equals([3, 2, 1]));
      expect(counts.name, equals('letters_value_counts'));
    });

    test('valueCounts with normalize=true', () {
      final s = Series(['a', 'b', 'a', 'c', 'a', 'b'], name: 'letters');
      final counts = s.valueCounts(normalize: true);
      expect(counts.index, equals(['a', 'b', 'c']));
      expect(counts.data, orderedEquals([3 / 6, 2 / 6, 1 / 6]));
    });

    test('valueCounts with sort=false', () {
      final sUnsorted =
          Series(['z', 'a', 'z', 'b', 'a', 'z'], name: 'unsorted_val_counts');
      final countsUnsorted = sUnsorted.valueCounts(sort: false);
      // Map: {'z':3, 'a':2, 'b':1}. Keys: 'z', 'a', 'b'. Sorted keys: 'a', 'b', 'z'
      expect(countsUnsorted.index, equals(['z', 'a', 'b']));
      expect(countsUnsorted.data, equals([3, 2, 1]));
    });

    test('valueCounts with ascending=true', () {
      final s = Series(['a', 'b', 'a', 'c', 'a', 'b'], name: 'letters');
      final counts =
          s.valueCounts(ascending: true); // Sorts by frequency ascending
      expect(counts.index, equals(['c', 'b', 'a']));
      expect(counts.data, equals([1, 2, 3]));
    });

    test('valueCounts with dropna=false (nulls)', () {
      final s =
          Series(['a', null, 'a', 'b', null, null], name: 'letters_nulls');
      final counts = s.valueCounts(dropna: false); // sort=true, ascending=false
      // Expected: null:3, a:2, b:1
      expect(counts.index, equals([null, 'a', 'b']));
      expect(counts.data, equals([3, 2, 1]));
    });

    test('valueCounts with dropna=false (custom marker)', () {
      var df = DataFrame.fromMap({
        'col1': ['a', missingMarker, 'a', 'b', missingMarker, missingMarker]
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');
      final counts = s.valueCounts(dropna: false);
      expect(counts.index, equals([missingMarker, 'a', 'b']));
      expect(counts.data, equals([3, 2, 1]));
    });

    test('valueCounts with dropna=true (default)', () {
      final s =
          Series(['a', null, 'a', 'b', null, null], name: 'letters_nulls_drop');
      final counts = s.valueCounts(); // dropna=true by default
      expect(counts.index, equals(['a', 'b']));
      expect(counts.data, equals([2, 1]));
    });

    test('valueCounts on empty series', () {
      final s = Series([], name: 'empty_vc');
      final counts = s.valueCounts();
      expect(counts.data, isEmpty);
      expect(counts.index, isEmpty);
    });

    test(
        'valueCounts normalize with sum of counts being zero (e.g. all missing and dropna=true)',
        () {
      final s = Series([null, null], name: 'all_missing_norm');
      final counts = s.valueCounts(normalize: true, dropna: true);
      expect(counts.data, isEmpty); // No non-missing values to count

      final s2 = Series([null, null], name: 'all_missing_norm_keepna');
      final counts2 = s2.valueCounts(normalize: true, dropna: false);
      // Count for null is 2. Total count is 2. Normalized is 2/2 = 1.0
      expect(counts2.data, equals([1.0]));
      expect(counts2.index, equals([null]));
    });
  });

  group('Series.isna() / Series.notna()', () {
    test('isna basic with nulls', () {
      final s = Series([1, null, 3, null, 5], name: 'data_nulls');
      final result = s.isna();
      expect(result.data, equals([false, true, false, true, false]));
      expect(result.name, equals('data_nulls_isna'));
      expect(result.index, s.index);
    });

    test('notna basic with nulls', () {
      final s = Series([1, null, 3, null, 5], name: 'data_nulls');
      final result = s.notna();
      expect(result.data, equals([true, false, true, false, true]));
      expect(result.name, equals('data_nulls_notna'));
    });

    test('isna with no missing values', () {
      final s = Series([1, 2, 3], name: 'no_missing');
      expect(s.isna().data, equals([false, false, false]));
    });

    test('notna with no missing values', () {
      final s = Series([1, 2, 3], name: 'no_missing');
      expect(s.notna().data, equals([true, true, true]));
    });

    test('isna with all nulls', () {
      final s = Series([null, null], name: 'all_nulls_is');
      expect(s.isna().data, equals([true, true]));
    });

    test('notna with all nulls', () {
      final s = Series([null, null], name: 'all_nulls_not');
      expect(s.notna().data, equals([false, false]));
    });

    test('isna with custom missing marker', () {
      var df = DataFrame.fromMap({
        'col1': [10, missingMarker, 20, missingMarker, 30]
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');

      final result = s.isna();
      expect(result.data, equals([false, true, false, true, false]));
    });

    test('notna with custom missing marker', () {
      var df = DataFrame.fromMap({
        'col1': [10, missingMarker, 20, missingMarker, 30]
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');

      final result = s.notna();
      expect(result.data, equals([true, false, true, false, true]));
    });

    test('isna on empty series', () {
      final s = Series([], name: 'empty_isna');
      expect(s.isna().data, isEmpty);
    });

    test('notna on empty series', () {
      final s = Series([], name: 'empty_notna');
      expect(s.notna().data, isEmpty);
    });
  });
}
