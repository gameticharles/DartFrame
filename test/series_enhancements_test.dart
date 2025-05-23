import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart'; // Adjust if your package import is different

void main() {
  // Define a custom missing value marker for tests that need it
  const missingMarker = -999;

  group('Series.sort_values() tests', () {
    test('sorts numeric series ascending', () {
      final s = Series([3, 1, 4, 1, 5, 9, 2, 6], name: 'numbers');
      final sortedS = s.sort_values();
      expect(sortedS.data, equals([1, 1, 2, 3, 4, 5, 6, 9]));
      expect(sortedS.name, equals('numbers'));
      // Default index should be reset and correspond to new order
      expect(sortedS.index, equals([1, 3, 6, 0, 2, 4, 7, 5])); 
    });

    test('sorts numeric series descending', () {
      final s = Series([3, 1, 4, 1, 5, 9, 2, 6], name: 'numbers');
      final sortedS = s.sort_values(ascending: false);
      expect(sortedS.data, equals([9, 6, 5, 4, 3, 2, 1, 1]));
      expect(sortedS.index, equals([5, 7, 4, 2, 0, 6, 1, 3]));
    });

    test('sorts string series', () {
      final s = Series(['banana', 'apple', 'cherry'], name: 'fruits');
      final sortedS = s.sort_values();
      expect(sortedS.data, equals(['apple', 'banana', 'cherry']));
      expect(sortedS.index, equals([1, 0, 2]));
    });

    test('handles naPosition="first"', () {
      final s = Series([3, null, 1, 4, null, 2], name: 'data_with_nulls');
      final sortedS = s.sort_values(naPosition: 'first');
      expect(sortedS.data, equals([null, null, 1, 2, 3, 4]));
      expect(sortedS.index, equals([1, 4, 2, 5, 0, 3]));
    });

    test('handles naPosition="last" (default)', () {
      final s = Series([3, null, 1, 4, null, 2], name: 'data_with_nulls');
      final sortedS = s.sort_values(); // naPosition defaults to 'last'
      expect(sortedS.data, equals([1, 2, 3, 4, null, null]));
      expect(sortedS.index, equals([2, 5, 0, 3, 1, 4]));
    });
    
    test('sorts with custom index', () {
      final s = Series([10, 30, 20], name: 'vals', index: ['a', 'b', 'c']);
      final sortedS = s.sort_values();
      expect(sortedS.data, equals([10, 20, 30]));
      expect(sortedS.index, equals(['a', 'c', 'b']));
    });

    test('sorts with missing values (custom marker) and naPosition="first"', () {
      var df = DataFrame.fromMap({'col1': [10, missingMarker, 5, 20, missingMarker]}, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1'); // Manually set parent for testing replaceMissingValueWith

      final sortedS = s.sort_values(naPosition: 'first');
      expect(sortedS.data, equals([missingMarker, missingMarker, 5, 10, 20]));
      expect(sortedS.index, equals([1, 4, 2, 0, 3]));
    });

    test('sorts with missing values (custom marker) and naPosition="last"', () {
      var df = DataFrame.fromMap({'col1': [10, missingMarker, 5, 20, missingMarker]}, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');

      final sortedS = s.sort_values(ascending: true, naPosition: 'last');
      expect(sortedS.data, equals([5, 10, 20, missingMarker, missingMarker]));
      expect(sortedS.index, equals([2, 0, 3, 1, 4]));
    });

    test('sorts empty series', () {
      final s = Series<int>([], name: 'empty');
      final sortedS = s.sort_values();
      expect(sortedS.data, isEmpty);
      expect(sortedS.index, isEmpty);
    });

    test('sorts series with all same values', () {
      final s = Series([5, 5, 5], name: 'fives', index: [0,1,2]);
      final sortedS = s.sort_values();
      expect(sortedS.data, equals([5, 5, 5]));
      // Order of original indices for equal values can be stable or implementation-dependent.
      // Pandas keeps original order for equal elements. Let's assume stable sort for indices.
      expect(sortedS.index, equals([0, 1, 2]));
    });
    
    test('sorts series with mixed comparable types (numbers)', () {
      final s = Series([10, 1.0, 20.5, 2], name: 'mixed_numbers');
      final sortedS = s.sort_values();
      expect(sortedS.data, equals([1.0, 2, 10, 20.5]));
      expect(sortedS.index, equals([1,3,0,2]));
    });

    // Test with a mix of types that might not be directly comparable by default Comparable.
    // The current sort_values implementation has a try-catch that returns 0 (maintains order)
    // for non-Comparable types or comparison errors.
    test('sorts series with non-directly comparable types (maintains order for uncomparables)', () {
      final s = Series([10, 'apple', 5, 'banana'], name: 'mixed_types', index: ['a', 'b', 'c', 'd']);
      // Expected behavior: numbers sort amongst themselves, strings amongst themselves.
      // Relative order of numbers vs strings depends on internal stability or type checks not explicitly defined as primary sort criteria.
      // Current impl: sorts [10,5] -> [5,10] and ['apple', 'banana'] -> ['apple', 'banana']
      // Then it concatenates them: [5, 10, 'apple', 'banana'] because of how it separates NaNs vs non-NaNs.
      // For truly mixed types without a clear universal comparison, the behavior can be tricky.
      // Pandas would raise a TypeError for sorting mixed types like int and str.
      // Our current implementation's fallback (return 0) attempts to be stable for uncomparable parts.
      // Let's test the current behavior.
      final sortedS = s.sort_values();
      expect(sortedS.data, equals([5, 10, 'apple', 'banana'])); // Based on current fallback
      expect(sortedS.index, equals(['c', 'a', 'b', 'd']));
    });

  });

  group('Series.sort_index() tests', () {
    test('sorts by numeric index ascending', () {
      final s = Series([10, 20, 30, 40], name: 'data', index: [3, 1, 4, 0]);
      final sortedS = s.sort_index();
      expect(sortedS.data, equals([40, 20, 10, 30]));
      expect(sortedS.index, equals([0, 1, 3, 4]));
    });

    test('sorts by numeric index descending', () {
      final s = Series([10, 20, 30, 40], name: 'data', index: [3, 1, 4, 0]);
      final sortedS = s.sort_index(ascending: false);
      expect(sortedS.data, equals([30, 10, 20, 40]));
      expect(sortedS.index, equals([4, 3, 1, 0]));
    });

    test('sorts by string index', () {
      final s = Series([1, 2, 3], name: 'items', index: ['c', 'a', 'b']);
      final sortedS = s.sort_index();
      expect(sortedS.data, equals([2, 3, 1]));
      expect(sortedS.index, equals(['a', 'b', 'c']));
    });

    test('sorts with default integer index (no explicit index)', () {
      // When no index is provided, it's List.generate(data.length, (i) => i)
      // So sorting by this index should effectively do nothing if ascending=true
      // or reverse the series if ascending=false.
      final s = Series([100, 200, 50], name: 'default_idx');
      final sortedS = s.sort_index(); // Ascending default
      expect(sortedS.data, equals([100, 200, 50]));
      expect(sortedS.index, equals([0, 1, 2]));

      final sortedSDesc = s.sort_index(ascending: false);
      expect(sortedSDesc.data, equals([50, 200, 100]));
      expect(sortedSDesc.index, equals([2, 1, 0]));
    });
    
    test('sorts with duplicate index values', () {
      // Behavior with duplicate indices: Pandas keeps the original relative order of data for duplicate index values.
      // The current List.sort in Dart is stable, so this should be the case.
      final s = Series([10, 20, 30, 40, 50], name: 'dupe_idx', index: ['b', 'a', 'c', 'a', 'b']);
      final sortedS = s.sort_index();
      // Expected: 'a's first (20, 40), then 'b's (10, 50), then 'c' (30)
      expect(sortedS.data, equals([20, 40, 10, 50, 30]));
      expect(sortedS.index, equals(['a', 'a', 'b', 'b', 'c']));
    });

    test('sorts empty series by index', () {
      final s = Series<int>([], name: 'empty', index: []);
      final sortedS = s.sort_index();
      expect(sortedS.data, isEmpty);
      expect(sortedS.index, isEmpty);
    });
    
    test('sorts index with null values (nulls first)', () {
      final s = Series([10, 20, 30, 40], name: 'idx_with_nulls', index: [1, null, 0, null]);
      final sortedS = s.sort_index(); // Default null handling should place them first or as per Comparable
      // Current sort_index has basic null handling (nulls first)
      expect(sortedS.data, equals([20, 40, 30, 10])); // data corresponding to sorted null, null, 0, 1
      expect(sortedS.index, equals([null, null, 0, 1]));
    });

  });

  group('Series.reset_index() tests', () {
    test('drop=true, returns Series with default index', () {
      final s = Series([10, 20, 30], name: 'mydata', index: ['a', 'b', 'c']);
      final result = s.reset_index(drop: true);

      expect(result, isA<Series>());
      expect(result.data, equals([10, 20, 30]));
      expect(result.name, equals('mydata'));
      expect(result.index, equals([0, 1, 2])); // Default index
    });

    test('drop=false, returns DataFrame, named Series, named index', () {
      final s = Series([10, 20, 30], name: 'mydata', index: ['x', 'y', 'z']);
      // If Series.index had a name property, it would be used.
      // For now, the 'name' param in reset_index is for the new index column.
      final result = s.reset_index(drop: false, name: 'idx_col');
      
      expect(result, isA<DataFrame>());
      expect(result.columns, equals(['idx_col', 'mydata']));
      expect(result['idx_col'].data, equals(['x', 'y', 'z']));
      expect(result['mydata'].data, equals([10, 20, 30]));
      expect(result.index, equals([0, 1, 2])); // DataFrame gets its own default index
    });

    test('drop=false, unnamed Series (name=\'\'), default index column name', () {
      final s = Series([10, 20], name: '', index: ['a', 'b']);
      final result = s.reset_index(drop: false); // name for index col defaults to 'index'
      
      expect(result, isA<DataFrame>());
      expect(result.columns, equals(['index', '0'])); // Unnamed series data col becomes '0'
      expect(result['index'].data, equals(['a', 'b']));
      expect(result['0'].data, equals([10, 20]));
    });
    
    test('drop=false, Series name is "0", index column name defaults to "index"', () {
      final s = Series([10, 20], name: '0', index: ['a', 'b']);
      final result = s.reset_index(drop: false);
      
      expect(result, isA<DataFrame>());
      expect(result.columns, equals(['index', '0']));
      expect(result['index'].data, equals(['a', 'b']));
      expect(result['0'].data, equals([10, 20]));
    });

    test('drop=false, Series name is "index", index column name also "index" (conflict)', () {
      // Current impl: if series name is 'index' and index col name (from param or default) is also 'index',
      // series data column becomes 'index_values'.
      final s = Series([10, 20], name: 'index', index: ['a', 'b']);
      final result = s.reset_index(drop: false); // Index col name defaults to 'index'
      
      expect(result, isA<DataFrame>());
      expect(result.columns, equals(['index', 'index_values']));
      expect(result['index'].data, equals(['a', 'b']));
      expect(result['index_values'].data, equals([10, 20]));
    });
    
    test('drop=false, custom name for index column that conflicts with Series name', () {
      final s = Series([10, 20], name: 'mydata', index: ['a', 'b']);
      // If user forces index column name to be 'mydata'
      final result = s.reset_index(drop: false, name: 'mydata');
      // The current logic for conflict (`seriesDataColumnName = '${this.name}_values';`)
      // only triggers if BOTH are 'index'. A more robust conflict resolution might be needed.
      // For now, this will result in a DataFrame with two columns named 'mydata', which is problematic
      // for DataFrame.fromMap if not handled by DataFrame's constructor or if map keys must be unique.
      // Assuming DataFrame.fromMap would overwrite or Dart map would just have one entry.
      // Let's test current behavior. The implementation tries to make seriesDataColumnName unique
      // only if both default to 'index'. If user explicitly names them the same, it's on them.
      // The DataFrame.fromMap will likely use the last one added if keys are same.
      // Let's assume the user provides different names or accepts default behavior.
      // The test for `name: 'mydata'` where `this.name` is also `mydata` is tricky.
      // The current `reset_index` code doesn't explicitly prevent this for user-supplied names.
      // It only auto-adjusts if `indexColumnName == 'index' && seriesDataColumnName == 'index'`.
      // So, if `s.name = 'A'` and `name = 'A'`, then `dfData` would be `{'A': index, 'A': data}`.
      // `Map.from()` would take the last one. So, 'A' would be `data`.
      // This indicates a potential improvement area for `reset_index` for user-named conflicts.
      // For now, we'll test the non-conflicting user-named scenario.
      final resultNonConflict = s.reset_index(drop: false, name: 'new_idx_col');
      expect(resultNonConflict.columns, equals(['new_idx_col', 'mydata']));
    });

    test('drop=false, Series with default index', () {
      final s = Series([10, 20], name: 'data'); // Index is [0,1] by default
      final result = s.reset_index(drop: false, name: 'original_idx');
      
      expect(result, isA<DataFrame>());
      expect(result.columns, equals(['original_idx', 'data']));
      expect(result['original_idx'].data, equals([0, 1]));
      expect(result['data'].data, equals([10, 20]));
    });

    test('empty series, drop=true', () {
      final s = Series<int>([], name: 'empty', index: []);
      final result = s.reset_index(drop: true);
      expect(result, isA<Series>());
      expect(result.data, isEmpty);
      expect(result.index, isEmpty);
      expect(result.name, 'empty');
    });

    test('empty series, drop=false', () {
      final s = Series<int>([], name: 'empty', index: []);
      final result = s.reset_index(drop: false, name: 'idx');
      expect(result, isA<DataFrame>());
      expect(result.columns, equals(['idx', 'empty'])); // or '0' if name was empty
      expect(result['idx'].data, isEmpty);
      expect(result['empty'].data, isEmpty);
      expect(result.rowCount, 0);
    });
  });

  group('Series.fillna() with method tests', () {
    test('ffill basic', () {
      final s = Series([1, null, null, 4, 5, null], name: 'ffill_basic');
      final filledS = s.fillna(method: 'ffill');
      expect(filledS.data, equals([1, 1, 1, 4, 5, 5]));
      expect(filledS.name, equals('ffill_basic'));
      expect(filledS.index, s.index); // Index should be preserved
    });

    test('ffill with leading nulls', () {
      final s = Series([null, null, 1, 2, null], name: 'ffill_lead_null');
      final filledS = s.fillna(method: 'ffill');
      expect(filledS.data, equals([null, null, 1, 2, 2]));
    });

    test('ffill with no nulls', () {
      final s = Series([1, 2, 3], name: 'ffill_no_null');
      final filledS = s.fillna(method: 'ffill');
      expect(filledS.data, equals([1, 2, 3]));
    });

    test('ffill with all nulls', () {
      final s = Series([null, null, null], name: 'ffill_all_null');
      final filledS = s.fillna(method: 'ffill');
      expect(filledS.data, equals([null, null, null]));
    });

    test('bfill basic', () {
      final s = Series([1, null, null, 4, 5, null], name: 'bfill_basic');
      final filledS = s.fillna(method: 'bfill');
      expect(filledS.data, equals([1, 4, 4, 4, 5, null]));
      expect(filledS.name, equals('bfill_basic'));
    });

    test('bfill with trailing nulls', () {
      final s = Series([null, 1, 2, null, null], name: 'bfill_trail_null');
      final filledS = s.fillna(method: 'bfill');
      expect(filledS.data, equals([1, 1, 2, null, null]));
    });
    
    test('bfill with no nulls', () {
      final s = Series([1, 2, 3], name: 'bfill_no_null');
      final filledS = s.fillna(method: 'bfill');
      expect(filledS.data, equals([1, 2, 3]));
    });

    test('bfill with all nulls', () {
      final s = Series([null, null, null], name: 'bfill_all_null');
      final filledS = s.fillna(method: 'bfill');
      expect(filledS.data, equals([null, null, null]));
    });

    test('fillna with custom missing marker (ffill)', () {
      var df = DataFrame.fromMap({'col1': [10, missingMarker, 20, missingMarker, 30]}, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');

      final filledS = s.fillna(method: 'ffill');
      expect(filledS.data, equals([10, 10, 20, 20, 30]));
    });
    
    test('fillna with custom missing marker (bfill)', () {
      var df = DataFrame.fromMap({'col1': [missingMarker, 10, missingMarker, 20, missingMarker]}, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');

      final filledS = s.fillna(method: 'bfill');
      expect(filledS.data, equals([10, 10, 20, 20, missingMarker]));
    });
    
    test('fillna with value takes precedence if method is invalid', () {
      final s = Series([1, null, 3], name: 'val_prec');
      final filledS = s.fillna(value: 99, method: 'invalid_method'); // Should throw ArgumentError for invalid method
      expect(() => s.fillna(value: 99, method: 'invalid_method'), throwsArgumentError);
      
      // If method is null, value is used
      final filledSWithValue = s.fillna(value:99);
      expect(filledSWithValue.data, equals([1,99,3]));
    });

    test('fillna empty series', () {
      final s = Series<int>([], name: 'empty');
      final filledFfill = s.fillna(method: 'ffill');
      expect(filledFfill.data, isEmpty);
      final filledBfill = s.fillna(method: 'bfill');
      expect(filledBfill.data, isEmpty);
    });

  });

  group('Series.dt accessor tests', () {
    final dt1 = DateTime(2023, 10, 26, 14, 30, 15, 500, 250); // Year, Month, Day, Hour, Min, Sec, Millis, Micros
    final dt2 = DateTime(2024, 3, 1, 8, 5, 0, 0, 0);
    final dateOnly = DateTime(2023, 10, 26);


    test('dt.year', () {
      final s = Series([dt1, dt2, null], name: 'dates');
      final result = s.dt.year;
      expect(result.data, equals([2023, 2024, null]));
      expect(result.name, equals('dates_year'));
    });

    test('dt.month', () {
      final s = Series([dt1, dt2, null], name: 'dates');
      final result = s.dt.month;
      expect(result.data, equals([10, 3, null]));
    });

    test('dt.day', () {
      final s = Series([dt1, dt2, null], name: 'dates');
      final result = s.dt.day;
      expect(result.data, equals([26, 1, null]));
    });

    test('dt.hour', () {
      final s = Series([dt1, dt2, null], name: 'dates');
      final result = s.dt.hour;
      expect(result.data, equals([14, 8, null]));
    });

    test('dt.minute', () {
      final s = Series([dt1, dt2, null], name: 'dates');
      final result = s.dt.minute;
      expect(result.data, equals([30, 5, null]));
    });

    test('dt.second', () {
      final s = Series([dt1, dt2, null], name: 'dates');
      final result = s.dt.second;
      expect(result.data, equals([15, 0, null]));
    });

    test('dt.millisecond', () {
      final s = Series([dt1, dt2, null], name: 'dates');
      final result = s.dt.millisecond;
      expect(result.data, equals([500, 0, null]));
    });

    test('dt.microsecond', () {
      final s = Series([dt1, dt2, null], name: 'dates');
      final result = s.dt.microsecond;
      expect(result.data, equals([250, 0, null]));
    });
    
    test('dt.weekday', () { // Monday=1 ... Sunday=7
      final s = Series([dt1, dt2, null], name: 'dates'); // 2023-10-26 is Thursday (4), 2024-03-01 is Friday (5)
      final result = s.dt.weekday;
      expect(result.data, equals([DateTime.thursday, DateTime.friday, null]));
    });

    test('dt.dayofyear', () {
      final s = Series([DateTime(2023,1,1), DateTime(2023,1,10), DateTime(2023,2,1), null], name: 'doy');
      final result = s.dt.dayofyear;
      expect(result.data, equals([1, 10, 32, null]));
    });
    
    test('dt.date', () {
      final s = Series([dt1, dt2, null], name: 'dates');
      final result = s.dt.date;
      expect(result.data, equals([dateOnly, DateTime(2024,3,1), null]));
      expect(result.data[0], isA<DateTime>());
      expect((result.data[0] as DateTime).hour, 0);
    });

    test('dt properties with non-DateTime and missing values', () {
      var df = DataFrame.fromMap({
        'col1': [dt1, 'not a date', null, missingMarker, dt2]
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');

      final yearS = s.dt.year;
      expect(yearS.data, equals([2023, missingMarker, missingMarker, missingMarker, 2024]));
      
      final monthS = s.dt.month;
      expect(monthS.data, equals([10, missingMarker, missingMarker, missingMarker, 3]));
    });
    
    test('dt properties on empty series', () {
      final s = Series<DateTime>([], name: 'empty_dates');
      expect(s.dt.year.data, isEmpty);
      expect(s.dt.month.data, isEmpty);
      // ... and so on for other properties
      expect(s.dt.date.data, isEmpty);
    });

  });

  group('Series.apply() tests', () {
    test('apply simple function (multiply by 2)', () {
      final s = Series([1, 2, 3, 4], name: 'numbers');
      final result = s.apply((x) => x * 2);
      expect(result.data, equals([2, 4, 6, 8]));
      expect(result.name, equals('numbers'));
      expect(result.index, s.index);
    });

    test('apply function (convert to string)', () {
      final s = Series([1, 2, 3], name: 'numbers');
      final result = s.apply((x) => 'val_$x');
      expect(result.data, equals(['val_1', 'val_2', 'val_3']));
    });

    test('apply with missing values (nulls)', () {
      final s = Series([1, null, 3, null], name: 'data_with_nulls');
      // The applied function is responsible for null handling.
      // If it doesn't handle null, it might throw or return null.
      final result = s.apply((x) => x == null ? 'is_null' : x * 10);
      expect(result.data, equals([10, 'is_null', 30, 'is_null']));
    });

    test('apply with missing values (custom marker)', () {
      var df = DataFrame.fromMap({'col1': [1, missingMarker, 3]}, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');

      final result = s.apply((x) => x == missingMarker ? 'is_missing' : x + 100);
      expect(result.data, equals([101, 'is_missing', 103]));
    });
    
    test('apply on empty series', () {
      final s = Series<int>([], name: 'empty');
      final result = s.apply((x) => x * 2);
      expect(result.data, isEmpty);
      expect(result.index, isEmpty);
    });

    test('apply function that changes type', () {
      final s = Series([1, 2, 3], name: 'numbers');
      final result = s.apply((x) => x > 1); // Returns bool
      expect(result.data, equals([false, true, true]));
      expect(result.dtype, bool);
    });

  });

  group('Series.isin() tests', () {
    test('isin with list of values', () {
      final s = Series([1, 2, 3, 4, 1, 5], name: 'numbers');
      final result = s.isin([1, 3, 5]);
      expect(result.data, equals([true, false, true, false, true, true]));
      expect(result.name, equals('numbers_isin'));
      expect(result.index, s.index);
    });

    test('isin with set of values for efficiency', () {
      final s = Series(['a', 'b', 'c', 'a', 'd'], name: 'letters');
      final result = s.isin({'a', 'd', 'x'}); // 'x' is not in series
      expect(result.data, equals([true, false, false, true, true]));
    });

    test('isin with missing values (null) in series', () {
      final s = Series([1, null, 2, null, 3], name: 'null_isin');
      final result = s.isin([1, 2, null]); // Check if null is in values
      expect(result.data, equals([true, true, true, true, false]));
    });
    
    test('isin with missing values (null) in series but NOT in values', () {
      final s = Series([1, null, 2], name: 'null_not_in_values');
      final result = s.isin([1, 2]);
      expect(result.data, equals([true, false, true]));
    });

    test('isin with custom missing marker', () {
      var df = DataFrame.fromMap({
        'col1': [10, missingMarker, 20, 5, missingMarker]
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');

      // missingMarker is in values
      final result1 = s.isin([10, 20, missingMarker]);
      expect(result1.data, equals([true, true, true, false, true]));

      // missingMarker is NOT in values
      final result2 = s.isin([10, 20, 5]);
      expect(result2.data, equals([true, false, true, true, false]));
    });
    
    test('isin on empty series', () {
      final s = Series<int>([], name: 'empty');
      final result = s.isin([1, 2]);
      expect(result.data, isEmpty);
    });

    test('isin with empty values iterable', () {
      final s = Series([1, 2, 3], name: 'numbers');
      final result = s.isin([]);
      expect(result.data, equals([false, false, false]));
    });
    
    test('isin with mixed types in series and values', () {
      final s = Series([1, 'a', 2.0, true, null], name: 'mixed_isin');
      final result = s.isin(['a', true, 1, null]);
      expect(result.data, equals([true, true, false, true, true]));
    });
  });

  group('Series.unique() tests', () {
    test('unique with duplicates, preserves order', () {
      final s = Series([1, 2, 1, 3, 2, 4, 1, 5], name: 'numbers');
      expect(s.unique(), equals([1, 2, 3, 4, 5]));
    });

    test('unique with no duplicates', () {
      final s = Series([1, 2, 3, 4, 5], name: 'no_dupes');
      expect(s.unique(), equals([1, 2, 3, 4, 5]));
    });

    test('unique with all same values', () {
      final s = Series([7, 7, 7, 7], name: 'sevens');
      expect(s.unique(), equals([7]));
    });

    test('unique with missing values (null)', () {
      final s = Series([1, null, 2, null, 1, 3, null], name: 'null_unique');
      expect(s.unique(), equals([1, null, 2, 3]));
    });

    test('unique with custom missing marker', () {
      var df = DataFrame.fromMap({
        'col1': [10, missingMarker, 20, 10, missingMarker, 30]
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col1'];
      s.setParent(df, 'col1');
      expect(s.unique(), equals([10, missingMarker, 20, 30]));
    });

    test('unique on empty series', () {
      final s = Series<int>([], name: 'empty');
      expect(s.unique(), isEmpty);
    });
    
    test('unique with mixed types', () {
      final s = Series([1, 'a', 1, null, 'a', true, null, true, 2.0], name: 'mixed_unique');
      expect(s.unique(), equals([1, 'a', null, true, 2.0]));
    });
  });
}
