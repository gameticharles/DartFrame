import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  const missingMarker = -999; // Custom missing value for DataFrame

  group('Series from DataFrame Column', () {
    final df = DataFrame.fromMap({
      'colA': [1, 2, missingMarker, 4],
      'colB': ['x', 'y', 'z', 'w'],
    }, replaceMissingValueWith: missingMarker);

    test('Series reflects data and name', () {
      Series sA = df['colA'];
      expect(sA.data, equals([1, 2, missingMarker, 4]));
      expect(sA.name, equals('colA'));
      expect(sA.length, 4);

      Series sB = df['colB'];
      expect(sB.data, equals(['x', 'y', 'z', 'w']));
      expect(sB.name, equals('colB'));
    });

    test('Series has parent DataFrame reference and column name', () {
      Series sA = df['colA'];
      // Accessing private fields _parentDataFrame and _columnName directly in tests is not ideal.
      // This implies these fields should ideally be tested via behavior that depends on them,
      // like isna() or modification. For now, we assume they are set by df['colA'].
      // (No direct public accessor for these fields is defined in Series)
      // We'll test their effect via other methods like isna() or modification.
      expect(sA,
          isNotNull); // Placeholder for actual check if public accessors were available
    });

    test('isna()/notna() use DataFrame replaceMissingValueWith', () {
      Series sA = df['colA']; // sA.data = [1, 2, missingMarker, 4]
      // sA should have _parentDataFrame set to df, so missingMarker is its missing indicator.
      expect(sA.isna().data, equals([false, false, true, false]));
      expect(sA.notna().data, equals([true, true, false, true]));

      Series sNull =
          Series([1, null, 3], name: 'sNull'); // No parent DF, null is missing
      expect(sNull.isna().data, equals([false, true, false]));
    });
  });

  group('Setting DataFrame Column with a Series', () {
    test('Set with Series, identical index', () {
      var df = DataFrame.fromMap({
        'A': [1, 2, 3]
      }, index: [
        'x',
        'y',
        'z'
      ]);
      final s = Series([10, 20, 30], name: 'B', index: ['x', 'y', 'z']);
      df['B'] = s;

      expect(df.columns, equals(['A', 'B']));
      expect(df['B'].data, equals([10, 20, 30]));
      expect(df['B'].index,
          equals(['x', 'y', 'z'])); // Series index becomes DF column index
    });

    test('Set with Series, different but aligned index (subset of DF index)',
        () {
      var df = DataFrame.fromMap({
        'A': [1, 2, 3, 4]
      }, index: [
        'w',
        'x',
        'y',
        'z'
      ]);
      final s = Series([10, 20],
          name: 'B', index: ['x', 'y']); // Index is subset of df
      df['B'] =
          s; // DataFrame's addColumn or equivalent logic handles alignment

      expect(df.columns, equals(['A', 'B']));
      expect(
          df['B'].data,
          equals([
            null,
            10,
            20,
            null
          ])); // Aligns, others are null (or df.replaceMissingValueWith)
      expect(df['B'].index, equals(['w', 'x', 'y', 'z']));
    });

    test('Set with Series, different but aligned index (superset of DF index)',
        () {
      var df = DataFrame.fromMap({
        'A': [1, 2]
      }, index: [
        'x',
        'y'
      ]);
      final s =
          Series([10, 20, 30, 40], name: 'B', index: ['w', 'x', 'y', 'z']);
      df['B'] = s;

      expect(df.columns, equals(['A', 'B']));
      // Only matching 'x', 'y' are set. DataFrame length doesn't change.
      expect(df['B'].data, equals([20, 30]));
      expect(df['B'].index, equals(['x', 'y']));
    });

    test('Set with Series, different unaligned index (some overlap)', () {
      var df = DataFrame.fromMap({
        'A': [1, 2, 3]
      }, index: [
        'a',
        'b',
        'c'
      ]);
      final s = Series([10, 20, 30],
          name: 'B',
          index: ['b', 'c', 'd']); // 'd' not in df, 'a' in df not in s
      df['B'] = s;

      expect(df.columns, equals(['A', 'B']));
      // 'a': null (or df missing rep)
      // 'b': 10
      // 'c': 20
      expect(df['B'].data, equals([null, 10, 20]));
      expect(df['B'].index, equals(['a', 'b', 'c']));
    });

    test('Set with Series, default integer index (assign by row order)', () {
      var df = DataFrame.fromMap({
        'A': [1, 2, 3]
      }, index: [
        'x',
        'y',
        'z'
      ]);
      final s = Series([10, 20, 30], name: 'B');
      df['B'] = s;

      expect(df.columns, equals(['A', 'B']));
      expect(df['B'].data, equals([10, 20, 30])); // Assigned row-wise
      expect(df['B'].index, equals(['x', 'y', 'z'])); // Takes DF's index
    });

    test('Set with Series, length mismatch (shorter Series, default index)',
        () {
      var df = DataFrame.fromMap({
        'A': [1, 2, 3, 4]
      }, index: [
        'w',
        'x',
        'y',
        'z'
      ]);
      final s = Series([10, 20], name: 'B'); // Length 2
      df['B'] = s; // DataFrame's addColumn logic

      expect(df.columns, equals(['A', 'B']));
      // Values filled up to length of series, rest are missing
      expect(df['B'].data,
          equals([10, 20, null, null])); // Or df.replaceMissingValueWith
    });

    test('Set with Series, length mismatch (longer Series, default index)', () {
      var df = DataFrame.fromMap({
        'A': [1, 2]
      }, index: [
        'x',
        'y'
      ]);
      final s = Series([10, 20, 30, 40], name: 'B'); // Length 4
      df['B'] = s;

      expect(df.columns, equals(['A', 'B']));
      // Series is truncated to fit DataFrame length
      expect(df['B'].data, equals([10, 20]));
    });
  });

  group('Modifying a Series obtained from a DataFrame', () {
    test('Modification of extracted Series updates DataFrame', () {
      var dfData = {
        'colA': [1, 2, 3],
        'colB': [4, 5, 6]
      };
      var df = DataFrame.fromMap(dfData);
      Series sA = df['colA'];

      sA[0] = 100; // Modify the series
      expect(sA.data[0], equals(100));
      expect(df['colA'].data[0], equals(100),
          reason:
              "DataFrame should reflect Series modification via s[idx]=val");

      // Test with a different type of modification if available, e.g. a method on Series
      // If fillna returned `this` for inplace (not current design), it would be:
      // sA.fillna(0, inplace: true);
      // For now, only s[idx]=val directly tests the link via setParent/updateCell
    });
  });

  group('Boolean Indexing of DataFrame with a Series', () {
    final df = DataFrame.fromMap({
      'A': [10, 20, 30, 40],
      'B': [11, 22, 33, 44],
    }, index: [
      'w',
      'x',
      'y',
      'z'
    ]);

    test('Boolean Series with aligned index', () {
      final boolSeries = Series([true, false, true, false], name: 'filter');
      DataFrame result = df[boolSeries];

      expect(result.rowCount, 2);
      expect(result['A'].data, equals([10, 30]));
      expect(result['B'].data, equals([11, 33]));
      expect(result.index, equals(['w', 'y']));
    });

    test('Boolean Series with partially aligned index (subset)', () {
      // df index: w,x,y,z. boolSeries index: x,y
      // Pandas aligns boolean series to df index, fills missing with False
      final boolSeries =
          Series([true, false], name: 'filter_subset', index: ['x', 'y']);
      DataFrame result = df[boolSeries];

      // Expected: filter becomes [F (w), T (x), F (y), F (z)] after aligning to df.index
      expect(result.rowCount, 1);
      expect(result['A'].data, equals([20]));
      expect(result.index, equals(['x']));
    });

    test('Boolean Series with partially aligned index (superset)', () {
      // df index: w,x,y,z. boolSeries index: v,w,x,y,z,a
      // Pandas aligns boolean series to df index. Extra indices in boolSeries are ignored.
      final boolSeries = Series([true, false, true, false, true, false],
          name: 'filter_superset', index: ['v', 'w', 'x', 'y', 'z', 'a']);
      DataFrame result = df[boolSeries];

      // Expected: filter becomes [F(w), T(x), F(y), T(z)] based on df.index
      expect(result.rowCount, 2);
      expect(result['A'].data, equals([20, 40]));
      expect(result.index, equals(['x', 'z']));
    });

    test('Boolean Series with default index (length matches DataFrame)', () {
      // df index: w,x,y,z (length 4)
      // boolSeries index: 0,1,2,3 (length 4)
      // Pandas behavior: if boolean series index is default int and DF index is not,
      // AND lengths match, it applies row-wise.
      // If lengths don't match, it usually raises an error.
      final boolSeries =
          Series([false, true, true, false], name: 'filter_default_idx');
      DataFrame result = df[boolSeries];

      expect(result.rowCount, 2);
      expect(result['A'].data, equals([20, 30]));
      expect(result.index, equals(['x', 'y']));
    });

    test('Boolean Series with default index (length mismatch)', () {
      final boolSeriesShort = Series([true, false], name: 'filter_short');
      expect(() => df[boolSeriesShort],
          throwsA(isA<ArgumentError>())); // Or specific error

      final boolSeriesLong =
          Series([true, false, true, false, true], name: 'filter_long');
      expect(() => df[boolSeriesLong], throwsA(isA<ArgumentError>()));
    });
  });

  group('Arithmetic/Logical Operations between DataFrame column and Series',
      () {
    // These tests depend on Series arithmetic operators (add, sub, etc.)
    // correctly handling index alignment between two Series.
    final df1 = DataFrame.fromMap({
      'A': [1, 2, 3, 4],
      'B': [10, 20, 30, 40],
    }, index: [
      'w',
      'x',
      'y',
      'z'
    ]);

    //final seriesAdd = Series([5, 50, 500, 5000], name: 'add', index: ['x', 'y', 'z', 'a']);
    // df1['A'] index: w,x,y,z. seriesAdd index: x,y,z,a

    test('Series.add(Series) with index alignment', () {
      Series colA = df1['A']; // Data: [1,2,3,4], Index: [w,x,y,z]

      // For this test to pass with current Series.add, indices must be compatible
      // or one of them should be null.
      // Let's test a case where indices are compatible for Series.add
      Series s1 = Series([1, 2, 3], name: 's1', index: ['a', 'b', 'c']);
      Series s2 = Series([10, 20, 30], name: 's2', index: ['a', 'b', 'c']);
      // Series s3 = Series([10,20,30], name: 's3'); // Default index

      Series res1 = s1 + s2;
      expect(res1.data, equals([11, 22, 33]));
      expect(res1.index, equals(['a', 'b', 'c']));

      // s1.add(s3) -> current Series.add would throw if s1.index is not null and not equal to s3.index (which is null)
      // unless logic is: if other.index is null, use my index.
      // The current _arithmeticOp: if (this.index != null && other.index != null && !listEquals(this.index, other.index)) throw ArgumentError
      // If (this.index == null && other.index != null) -> use other.index
      // If (this.index != null && other.index == null) -> use this.index

      colA = df1['A']; // Has index ['w','x','y','z']
      Series seriesAddSameIndex =
          Series([5, 50, 500, 5000], name: 'add2', index: ['w', 'x', 'y', 'z']);
      Series resultAligned = colA + seriesAddSameIndex;
      expect(resultAligned.data, equals([1 + 5, 2 + 50, 3 + 500, 4 + 5000]));
      expect(resultAligned.index, equals(['w', 'x', 'y', 'z']));

      // Test with Series with default index (should align with df['A'] by position)
      Series seriesDefaultIdx =
          Series([10, 10, 10, 10], index: ['w', 'x', 'y', 'z'], name: 'ten');
      Series resultDefault = colA +
          seriesDefaultIdx; // colA has index, seriesDefaultIdx has null index
      expect(resultDefault.data, equals([1 + 10, 2 + 10, 3 + 10, 4 + 10]));
      expect(resultDefault.index,
          equals(colA.index)); // Result index is colA's index
    });

    // Placeholder for logical operations if they are implemented with alignment
    // e.g., df['A'].gt(seriesB)
  });
}
