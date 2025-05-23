import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  const missingMarker = -999; // For tests involving DataFrame context

  group('Series Constructor and Core Properties', () {
    test('constructor with int data, no index', () {
      final s = Series([1, 2, 3], name: 'integers');
      expect(s.data, equals([1, 2, 3]));
      expect(s.name, equals('integers'));
      expect(s.index, equals([0, 1, 2])); // Default index
      expect(s.length, 3);
      expect(s.dtype, int);
    });

    test('constructor with double data, custom index', () {
      final s = Series([1.1, 2.2, 3.3], name: 'doubles', index: ['a', 'b', 'c']);
      expect(s.data, equals([1.1, 2.2, 3.3]));
      expect(s.name, equals('doubles'));
      expect(s.index, equals(['a', 'b', 'c']));
      expect(s.length, 3);
      expect(s.dtype, double);
    });

    test('constructor with string data', () {
      final s = Series(['apple', 'banana', 'cherry'], name: 'fruits');
      expect(s.data, equals(['apple', 'banana', 'cherry']));
      expect(s.dtype, String);
    });

    test('constructor with bool data', () {
      final s = Series([true, false, true], name: 'booleans');
      expect(s.data, equals([true, false, true]));
      expect(s.dtype, bool);
    });

    test('constructor with mixed data (dynamic dtype)', () {
      final s = Series([1, 'hello', 2.5, true], name: 'mixed');
      expect(s.data, equals([1, 'hello', 2.5, true]));
      // Dtype for mixed list: current implementation checks first element or most common.
      // Let's assume it refers to the most common, or dynamic if truly mixed.
      // The current Series.dtype returns the most common non-missing type.
      // If all are unique types, it might be the first or dynamic.
      // For [1, 'hello', 2.5, true], all are different.
      // The current implementation of dtype will pick the first one if all counts are 1.
      // This test might need adjustment based on specific Series.dtype behavior for ties.
      // Let's assume if counts are equal, it might pick the first one it encountered, or the last.
      // For now, let's expect `dynamic` if no single type is predominant.
      // The current Series.dtype returns the type of the first element if counts are equal.
      // So, for [1, 'hello', 2.5, true], it should be int.
      expect(s.dtype, int); 
    });
    
    test('constructor with mixed data where one type is more common', () {
      final s = Series([1, 'hello', 2, 3, 'world', 4], name: 'mixed_common_int');
      expect(s.dtype, int); // int is most common
       final s2 = Series(['a', 1, 'b', 'c', 2, 'd'], name: 'mixed_common_string');
      expect(s2.dtype, String); // String is most common
    });


    test('constructor with empty list', () {
      final s = Series<int>([], name: 'empty');
      expect(s.data, isEmpty);
      expect(s.name, equals('empty'));
      expect(s.index, isEmpty);
      expect(s.length, 0);
      expect(s.dtype, dynamic); // Empty series has dynamic type
    });

    test('name property', () {
      final s = Series([1], name: 'test_name');
      expect(s.name, 'test_name');
    });

    test('index property', () {
      final s1 = Series([1], name: 's1');
      expect(s1.index, equals([0]));
      final s2 = Series([1], name: 's2', index: ['x']);
      expect(s2.index, equals(['x']));
    });

    test('data property', () {
      final dataList = [10, 20, 30];
      final s = Series(dataList, name: 'data_prop');
      expect(s.data, equals(dataList));
      // Test that it's a copy or that direct modification doesn't affect Series internal?
      // Current Series constructor uses the passed list directly.
      // dataList.add(40); // If this affected s.data, it's not a copy.
      // expect(s.data, isNot(equals([10,20,30,40]))); // This would fail if not copied.
      // For now, just testing access. Defensive copying is a deeper design choice.
    });

    test('length getter', () {
      expect(Series([], name: 'l0').length, 0);
      expect(Series([1,2,3], name: 'l3').length, 3);
    });

    test('dtype with only missing values (null)', () {
      final s = Series([null, null, null], name: 'all_nulls');
      expect(s.dtype, dynamic);
    });

    test('dtype with only missing values (custom marker)', () {
      final df = DataFrame.fromMap({'col': [missingMarker, missingMarker]}, replaceMissingValueWith: missingMarker);
      final s = df['col'];
      s.setParent(df, 'col');
      expect(s.dtype, dynamic);
    });
    
    test('dtype with mixed missing and non-missing', () {
      final s = Series([1, null, 2, 'text', null], name: 'mixed_missing');
      expect(s.dtype, int); // int is the most common non-missing
    });
  });

  group('Series.toString()', () {
    test('toString basic numeric series with default index', () {
      final s = Series([1, 2, 3], name: 'nums');
      final str = s.toString();
      expect(str, contains('nums'));
      expect(str, contains('0       1'));
      expect(str, contains('1       2'));
      expect(str, contains('2       3'));
      expect(str, contains('Length: 3'));
      expect(str, contains('Type: int'));
    });

    test('toString string series with custom index', () {
      final s = Series(['a', 'b'], name: 'chars', index: ['x', 'y']);
      final str = s.toString();
      expect(str, contains('chars'));
      expect(str, contains('x       a'));
      expect(str, contains('y       b'));
      expect(str, contains('Length: 2'));
      expect(str, contains('Type: String'));
    });

    test('toString empty series', () {
      final s = Series<int>([], name: 'empty_series');
      expect(s.toString(), equals('Empty Series: empty_series'));
    });
    
    test('toString with long strings and column spacing', () {
      final s = Series(['long string value', 'short'], name: 'long_strings', index: [0,1]);
      // Default spacing is 2. 'long string value' is 17 chars. header 'long_strings' is 12.
      // col width for val = 17. col width for name = 12. Max is 17.
      // Padded width is 17 + 2 = 19.
      // Index width for '0','1' is 1. Padded index width is 1 + 2 = 3. (min 5+2=7)
      final str = s.toString();
      expect(str, contains('long_strings'.padRight(19))); // Header padding
      expect(str, contains('0'.padRight(7) + 'long string value'.padRight(19)));
      expect(str, contains('1'.padRight(7) + 'short'.padRight(19)));
    });
  });

  group('Series.toDataFrame()', () {
    test('toDataFrame basic', () {
      final s = Series([10, 20], name: 'col_data', index: ['r1', 'r2']);
      final df = s.toDataFrame();
      
      expect(df, isA<DataFrame>());
      expect(df.columns, equals(['col_data']));
      expect(df.rowCount, 2);
      expect(df['col_data'].data, equals([10, 20]));
      // toDataFrame currently doesn't preserve Series index as DataFrame index.
      // It creates a default 0..N-1 index for the DataFrame.
      expect(df.index, equals([0, 1])); 
    });

    test('toDataFrame empty series', () {
      final s = Series<String>([], name: 'empty_col');
      final df = s.toDataFrame();

      expect(df.columns, equals(['empty_col']));
      expect(df.rowCount, 0);
      expect(df['empty_col'].data, isEmpty);
    });
  });
}
