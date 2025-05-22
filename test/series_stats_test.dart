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
      var s = Series(['a', 'b', 'a', 'c', 'a', 'b', null, 'd', null], name: 'counts_test');
      final defaultMissingRep = null;

      var dfSpecific = DataFrame.empty(replaceMissingValueWith: 'MISSING');
      var sSpecificMissing = Series(['x', 'y', 'x', 'MISSING', 'z', 'MISSING'], name: 'specific_counts');
      sSpecificMissing.setParent(dfSpecific, 'specific_counts');
      final specificMissingRep = 'MISSING';

      test('basic counts (sorted descending, dropna=true)', () {
        var counts = s.valueCounts(dropna: false);  // Changed to include nulls
        expect(counts.index, containsAll(['a', 'b', 'c', 'd', null])); // Order might vary if counts are same
        expect(counts.data, containsAll([3, 2, 1, 1, 2])); // Default sort is by count desc
        // To make test robust to tie-breaking in sort, check as map
        Map<dynamic, dynamic> countsMap = {};
        for(int i=0; i<counts.index!.length; ++i) {
            countsMap[counts.index![i]] = counts.data[i];
        }
        expect(countsMap, equals({'a':3, 'b':2, null:2, 'd':1, 'c':1}));


        var result = s.valueCounts(); // dropna = true by default
        expect(result.index, containsAllInOrder(['a', 'b'])); // a:3, b:2
        expect(result.data, containsAllInOrder([3, 2]));
        expect(result.index, isNot(contains(defaultMissingRep)));
        expect(result.name, equals('counts_test_value_counts'));
      });
      
       test('basic counts explicit dropna=true', () {
        var result = s.valueCounts(dropna: true);
        expect(result.data.reduce((a,b) => a+b), equals(7)); // 3a, 2b, 1c, 1d
        expect(result.index, isNot(contains(defaultMissingRep)));
      });


      test('normalize=true', () {
        var result = s.valueCounts(normalize: true, dropna: true);
        expect(result.data[0], closeTo(3/7, 0.001)); // 'a': 3/7
        expect(result.data[1], closeTo(2/7, 0.001)); // 'b': 2/7
      });

      test('sort=false', () {
        var result = s.valueCounts(sort: false, dropna: true);
        // Order might not be guaranteed, but check if all elements are present
        expect(result.length, equals(4)); // a,b,c,d
        expect(result.index, containsAll(['a', 'b', 'c', 'd']));
      });

      test('ascending=true', () {
        var result = s.valueCounts(ascending: true, dropna: true);
        expect(result.data.first <= result.data.last, isTrue); // Check if sorted ascending by count
        expect(result.index!.last, equals('a')); // 'a' has highest count
      });

      test('dropna=false (default missing)', () {
        var result = s.valueCounts(dropna: false, sort:true, ascending:false); // Sort to make it predictable
        expect(result.index, contains(defaultMissingRep));
        // Expected order by count: a (3), b (2), null (2), c (1), d (1)
        // Find index of null
        int nullIdx = result.index!.indexOf(defaultMissingRep);
        expect(nullIdx, isNot(-1));
        expect(result.data[nullIdx], equals(2));
        expect(result.data.reduce((a,b) => a+b), equals(s.length)); // Sum of counts should be total length
      });

      test('dropna=false (specific missing)', () {
        var result = sSpecificMissing.valueCounts(dropna: false, sort:true, ascending:false);
        expect(result.index, contains(specificMissingRep));
        int missingIdx = result.index!.indexOf(specificMissingRep);
        expect(missingIdx, isNot(-1));
        expect(result.data[missingIdx], equals(2)); // 'MISSING': 2
        expect(result.data.reduce((a,b) => a+b), equals(sSpecificMissing.length));
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
        expect(resultNoDrop.index![0], isNull);
        expect(resultNoDrop.data[0], equals(2));
      });
    });
  });
}
