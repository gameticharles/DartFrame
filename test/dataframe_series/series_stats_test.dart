import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Series Statistical Methods', () {
    group('Series.nunique()', () {
      test('all unique values', () {
        var s = Series([1, 2, 3, 4], name: 'unique_nums');
        expect(s.nunique(), equals(4));
      });

      test('with duplicate values', () {
        var s = Series([1, 2, 2, 3, 1, 4, 4, 4], name: 'duplicates');
        expect(s.nunique(), equals(4));
      });

      test('with null (default missing) values', () {
        var s = Series([1, 2, null, 3, 2, null], name: 'with_nulls');
        expect(s.nunique(), equals(3)); // nulls are not counted
      });

      test('with specific missing value placeholder', () {
        var df = DataFrame.empty(replaceMissingValueWith: -1);
        var s = Series([1, 2, -1, 3, 2, -1], name: 'specific_missing');
        s.setParent(df, 'specific_missing');
        expect(s.nunique(), equals(3)); // -1 is ignored
      });

      test('empty series', () {
        var s = Series([], name: 'empty');
        expect(s.nunique(), equals(0));
      });

      test('series with only nulls/missing values', () {
        var sNull = Series([null, null, null], name: 'all_nulls');
        expect(sNull.nunique(), equals(0));

        var df = DataFrame.empty(replaceMissingValueWith: 'NA');
        var sNa = Series(['NA', 'NA'], name: 'all_na');
        sNa.setParent(df, 'all_na');
        expect(sNa.nunique(), equals(0));
      });
    });

    group('Series.value_counts()', () {
      var s = Series(['a', 'b', 'a', 'c', 'a', 'b', null, 'd', null],
          name: 'counts_test');
      final defaultMissingRep = null;

      var dfSpecific = DataFrame.empty(replaceMissingValueWith: 'MISSING');
      var sSpecificMissing = Series(['x', 'y', 'x', 'MISSING', 'z', 'MISSING'],
          name: 'specific_counts');
      sSpecificMissing.setParent(dfSpecific, 'specific_counts');
      final specificMissingRep = 'MISSING';

      test('basic counts (sorted descending, dropna=true)', () {
        var counts = s.valueCounts(dropna: false); // Changed to include nulls
        expect(
            counts.index,
            containsAll([
              'a',
              'b',
              'c',
              'd',
              null
            ])); // Order might vary if counts are same
        expect(counts.data,
            containsAll([3, 2, 1, 1, 2])); // Default sort is by count desc
        // To make test robust to tie-breaking in sort, check as map
        Map<dynamic, dynamic> countsMap = {};
        for (int i = 0; i < counts.index.length; ++i) {
          countsMap[counts.index[i]] = counts.data[i];
        }
        expect(countsMap, equals({'a': 3, 'b': 2, null: 2, 'd': 1, 'c': 1}));

        var result = s.valueCounts(); // dropna = true by default
        expect(result.index, containsAllInOrder(['a', 'b'])); // a:3, b:2
        expect(result.data, containsAllInOrder([3, 2]));
        expect(result.index, isNot(contains(defaultMissingRep)));
        expect(result.name, equals('counts_test_value_counts'));
      });

      test('basic counts explicit dropna=true', () {
        var result = s.valueCounts(dropna: true);
        expect(
            result.data.reduce((a, b) => a + b), equals(7)); // 3a, 2b, 1c, 1d
        expect(result.index, isNot(contains(defaultMissingRep)));
      });

      test('normalize=true', () {
        var result = s.valueCounts(normalize: true, dropna: true);
        expect(result.data[0], closeTo(3 / 7, 0.001)); // 'a': 3/7
        expect(result.data[1], closeTo(2 / 7, 0.001)); // 'b': 2/7
      });

      test('sort=false', () {
        var result = s.valueCounts(sort: false, dropna: true);
        // Order might not be guaranteed, but check if all elements are present
        expect(result.length, equals(4)); // a,b,c,d
        expect(result.index, containsAll(['a', 'b', 'c', 'd']));
      });

      test('ascending=true', () {
        var result = s.valueCounts(ascending: true, dropna: true);
        expect(result.data.first <= result.data.last,
            isTrue); // Check if sorted ascending by count
        expect(result.index.last, equals('a')); // 'a' has highest count
      });

      test('dropna=false (default missing)', () {
        var result = s.valueCounts(
            dropna: false,
            sort: true,
            ascending: false); // Sort to make it predictable
        expect(result.index, contains(defaultMissingRep));
        // Expected order by count: a (3), b (2), null (2), c (1), d (1)
        // Find index of null
        int nullIdx = result.index.indexOf(defaultMissingRep);
        expect(nullIdx, isNot(-1));
        expect(result.data[nullIdx], equals(2));
        expect(result.data.reduce((a, b) => a + b),
            equals(s.length)); // Sum of counts should be total length
      });

      test('dropna=false (specific missing)', () {
        var result = sSpecificMissing.valueCounts(
            dropna: false, sort: true, ascending: false);
        expect(result.index, contains(specificMissingRep));
        int missingIdx = result.index.indexOf(specificMissingRep);
        expect(missingIdx, isNot(-1));
        expect(result.data[missingIdx], equals(2)); // 'MISSING': 2
        expect(result.data.reduce((a, b) => a + b),
            equals(sSpecificMissing.length));
      });

      test('value_counts on empty series', () {
        var sEmpty = Series([], name: 'empty_s');
        var result = sEmpty.valueCounts();
        expect(result.length, equals(0));
        expect(result.name, equals('empty_s_value_counts'));
      });

      test('value_counts on series with only missing values', () {
        var sAllMissing = Series([null, null], name: 'all_miss_s');
        var resultDrop = sAllMissing.valueCounts(dropna: true);
        expect(resultDrop.length, equals(0));

        var resultNoDrop = sAllMissing.valueCounts(dropna: false);
        expect(resultNoDrop.length, equals(1));
        expect(resultNoDrop.index[0], isNull);
        expect(resultNoDrop.data[0], equals(2));
      });
    });
  });

  group('Series.quantile()', () {
    test('quantile on empty series throws Exception', () {
      var s = Series<double>([], name: 'empty_double');
      expect(
          () => s.quantile(0.5),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            contains(
                'Cannot calculate quantile of an empty series or series with all missing values'),
          )));
    });

    test('quantile on series with non-numeric data throws Exception', () {
      var s = Series(['a', 'b', 'c'], name: 'string_series');
      // This case also throws "Cannot calculate quantile of an empty series or series with all missing values"
      // because non-numeric values are treated as missing/invalid for quantile.
      expect(
          () => s.quantile(0.5),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            contains(
                'Cannot calculate quantile of an empty series or series with all missing values'),
          )));
      var sMix = Series([1, 'b', 3.0], name: 'mixed_series');
      // If non-numeric values are converted to null, data becomes [1, null, 3.0]
      // Quantile of [1.0, 3.0] at 0.5 is 1.0 + (3.0-1.0)*0.5 = 2.0
      expect(sMix.quantile(0.5), equals(2.0));
    });

    test('quantile on series with nulls (ignores them)', () {
      var s = Series([1.0, null, 2.0, null, 3.0, 4.0, null, 5.0],
          name: 'with_nulls');
      // Effective data: [1.0, 2.0, 3.0, 4.0, 5.0]
      expect(s.quantile(0.5), equals(3.0)); // Median
      expect(s.quantile(0), equals(1.0));
      expect(s.quantile(1), equals(5.0));
      expect(
          s.quantile(0.25),
          equals(
              2.0)); // (1*0.25 + 2*0.75) if we consider positions. Interpolation: 1 + (5-1)*0.25 = 2.0. Let's verify.
      // Sorted: [1,2,3,4,5]. n=5. (n-1)*q = 4*0.25 = 1. Index 1 is 2.0
      expect(
          s.quantile(0.75),
          equals(
              4.0)); // Sorted: [1,2,3,4,5]. (n-1)*q = 4*0.75 = 3. Index 3 is 4.0
    });

    test('quantile with different percentile inputs', () {
      var s = Series([1.0, 2.0, 3.0, 4.0, 5.0], name: 'numeric');
      expect(s.quantile(0), equals(1.0));
      expect(
          s.quantile(0.25), equals(2.0)); // (5-1)*0.25 = 1. Element at index 1.
      expect(
          s.quantile(0.5), equals(3.0)); // (5-1)*0.5 = 2. Element at index 2.
      expect(
          s.quantile(0.75), equals(4.0)); // (5-1)*0.75 = 3. Element at index 3.
      expect(s.quantile(1), equals(5.0));

      var sEven = Series([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], name: 'numeric_even');
      // n=6. (n-1)*q :
      // q=0: (6-1)*0 = 0. Index 0 -> 1.0
      // q=0.25: (6-1)*0.25 = 1.25. val[1] + (val[2]-val[1])*0.25 = 2.0 + (3.0-2.0)*0.25 = 2.25
      // q=0.5: (6-1)*0.5 = 2.5. val[2] + (val[3]-val[2])*0.5 = 3.0 + (4.0-3.0)*0.5 = 3.5
      // q=0.75: (6-1)*0.75 = 3.75. val[3] + (val[4]-val[3])*0.75 = 4.0 + (5.0-4.0)*0.75 = 4.75
      // q=1: (6-1)*1 = 5. Index 5 -> 6.0
      expect(sEven.quantile(0), equals(1.0));
      expect(sEven.quantile(0.25), equals(2.25));
      expect(sEven.quantile(0.5), equals(3.5));
      expect(sEven.quantile(0.75), equals(4.75));
      expect(sEven.quantile(1), equals(6.0));
    });

    test('quantile with percentile input outside 0-1 throws Exception', () {
      var s = Series([1.0, 2.0, 3.0], name: 'bounds_test');
      expect(
          () => s.quantile(-0.1),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            contains('Percentile must be between 0 and 1'),
          )));
      expect(
          () => s.quantile(1.1),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            contains('Percentile must be between 0 and 1'),
          )));
    });

    test('quantile on series where all values are the same', () {
      var s = Series([7.0, 7.0, 7.0, 7.0], name: 'same_values');
      expect(s.quantile(0), equals(7.0));
      expect(s.quantile(0.25), equals(7.0));
      expect(s.quantile(0.5), equals(7.0));
      expect(s.quantile(0.75), equals(7.0));
      expect(s.quantile(1), equals(7.0));
    });

    test('quantile on series with a mix of positive and negative numbers', () {
      var s = Series([-1.0, -2.0, 0.0, 1.0, 2.0], name: 'mixed_sign');
      // Sorted: [-2.0, -1.0, 0.0, 1.0, 2.0]
      // n=5. (n-1)*q
      // q=0: -2.0
      // q=0.25: (5-1)*0.25 = 1. Index 1 -> -1.0
      // q=0.5: (5-1)*0.5 = 2. Index 2 -> 0.0
      // q=0.75: (5-1)*0.75 = 3. Index 3 -> 1.0
      // q=1: 2.0
      expect(s.quantile(0), equals(-2.0));
      expect(s.quantile(0.25), equals(-1.0));
      expect(s.quantile(0.5), equals(0.0));
      expect(s.quantile(0.75), equals(1.0));
      expect(s.quantile(1), equals(2.0));
    });

    test('quantile on series with a single value', () {
      var s = Series([42.0], name: 'single_value');
      expect(s.quantile(0), equals(42.0));
      expect(s.quantile(0.25), equals(42.0));
      expect(s.quantile(0.5), equals(42.0));
      expect(s.quantile(0.75), equals(42.0));
      expect(s.quantile(1), equals(42.0));
    });

    test('quantile with specific missing value placeholder (ignores them)', () {
      var df = DataFrame.empty(replaceMissingValueWith: -999.0);
      var s = Series([10.0, -999.0, 20.0, -999.0, 30.0, 40.0, -999.0, 50.0],
          name: 'specific_missing');
      s.setParent(df, 'specific_missing');
      // Effective data: [10.0, 20.0, 30.0, 40.0, 50.0]
      expect(s.quantile(0.5), equals(30.0));
      expect(s.quantile(0), equals(10.0));
      expect(s.quantile(1), equals(50.0));
      expect(s.quantile(0.25), equals(20.0));
      expect(s.quantile(0.75), equals(40.0));
    });

    test('quantile on series with only nulls/missing values throws Exception',
        () {
      var sNull = Series<double>([null, null, null], name: 'all_nulls_double');
      expect(
          () => sNull.quantile(0.5),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            contains(
                'Cannot calculate quantile of an empty series or series with all missing values'),
          )));

      var df = DataFrame.empty(replaceMissingValueWith: -1.0);
      var sMissing = Series<double>([-1.0, -1.0], name: 'all_missing_double');
      sMissing.setParent(df, 'all_missing_double');
      expect(
          () => sMissing.quantile(0.5),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            contains(
                'Cannot calculate quantile of an empty series or series with all missing values'),
          )));
    });

    test('quantile calculation precision for interpolated values', () {
      // Test case from pandas documentation example for linear interpolation
      // s = pd.Series([1, 2, 3, 4])
      // s.quantile(0.4) -> 2.2 ( (4-1)*0.4 = 1.2. val[1] + (val[2]-val[1])*0.2 = 2 + (3-2)*0.2 = 2.2 )
      // s.quantile(0.6) -> 2.8 ( (4-1)*0.6 = 1.8. val[1] + (val[2]-val[1])*0.8 = 2 + (3-2)*0.8 = 2.8 )
      // Let's recheck with dartframe logic: (n-1)*q.
      // For [1,2,3,4], n=4.
      // q=0.4: (4-1)*0.4 = 1.2. index = floor(1.2) = 1. fraction = 0.2.
      // result = data[1] + (data[2] - data[1]) * 0.2 = 2 + (3-2)*0.2 = 2.2
      var s = Series([1.0, 2.0, 3.0, 4.0], name: 'interpolation_test');
      expect(s.quantile(0.4), closeTo(2.2, 0.0000001));
      expect(s.quantile(0.6), closeTo(2.8, 0.0000001));

      // q=0.1: (4-1)*0.1 = 0.3. index = 0, fraction = 0.3
      // result = data[0] + (data[1]-data[0])*0.3 = 1 + (2-1)*0.3 = 1.3
      expect(s.quantile(0.1), closeTo(1.3, 0.0000001));

      // q=0.9: (4-1)*0.9 = 2.7. index = 2, fraction = 0.7
      // result = data[2] + (data[3]-data[2])*0.7 = 3 + (4-3)*0.7 = 3.7
      expect(s.quantile(0.9), closeTo(3.7, 0.0000001));
    });
  });
}
