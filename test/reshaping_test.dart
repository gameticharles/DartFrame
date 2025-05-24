import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame.pivotTable', () {
    test('Basic pivotTable with mean aggregation', () {
      final df = DataFrame.fromRows([
        {'A': 'foo', 'B': 'one', 'C': 1, 'D': 10},
        {'A': 'foo', 'B': 'one', 'C': 2, 'D': 20},
        {'A': 'foo', 'B': 'two', 'C': 3, 'D': 30},
        {'A': 'bar', 'B': 'one', 'C': 4, 'D': 40},
        {'A': 'bar', 'B': 'two', 'C': 5, 'D': 50},
        {'A': 'bar', 'B': 'two', 'C': 6, 'D': 60},
      ]);
      final pivoted = df.pivotTable(index: 'A', columns: 'B', values: 'C');
      // Expected:
      // A | one | two
      //---|-----|----
      //foo| 1.5 | 3.0
      //bar| 4.0 | 5.5
      expect(pivoted.columns, equals(['A', 'one', 'two']));
      expect(pivoted.rows.length, equals(2));
      // foo row
      expect(pivoted.rows[0][0], equals('foo'));
      expect(pivoted.rows[0][1], equals(1.5)); // (1+2)/2
      expect(pivoted.rows[0][2], equals(3.0));
      // bar row
      expect(pivoted.rows[1][0], equals('bar'));
      expect(pivoted.rows[1][1], equals(4.0));
      expect(pivoted.rows[1][2], equals(5.5)); // (5+6)/2
    });

    test('pivotTable with sum aggregation', () {
      final df = DataFrame.fromRows([
        {'A': 'foo', 'B': 'one', 'C': 1},
        {'A': 'foo', 'B': 'one', 'C': 2},
        {'A': 'foo', 'B': 'two', 'C': 3},
        {'A': 'bar', 'B': 'one', 'C': 4},
      ]);
      final pivoted =
          df.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'sum');
      expect(pivoted.rows[0][1], equals(3)); // 1+2
      expect(pivoted.rows[0][2], equals(3));
      expect(pivoted.rows[1][1], equals(4));
    });

    test('pivotTable with count aggregation', () {
      final df = DataFrame.fromRows([
        {'A': 'foo', 'B': 'one', 'C': 1},
        {'A': 'foo', 'B': 'one', 'C': 2},
        {'A': 'foo', 'B': 'two', 'C': 3},
      ]);
      final pivoted = df.pivotTable(
          index: 'A', columns: 'B', values: 'C', aggFunc: 'count');
      expect(pivoted.rows[0][1], equals(2));
      expect(pivoted.rows[0][2], equals(1));
    });

    test('pivotTable with min aggregation', () {
      final df = DataFrame.fromRows([
        {'A': 'foo', 'B': 'one', 'C': 10},
        {'A': 'foo', 'B': 'one', 'C': 2},
        {'A': 'foo', 'B': 'two', 'C': 3},
      ]);
      final pivoted =
          df.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'min');
      expect(pivoted.rows[0][1], equals(2));
      expect(pivoted.rows[0][2], equals(3));
    });

    test('pivotTable with max aggregation', () {
      final df = DataFrame.fromRows([
        {'A': 'foo', 'B': 'one', 'C': 10},
        {'A': 'foo', 'B': 'one', 'C': 2},
        {'A': 'foo', 'B': 'two', 'C': 30},
      ]);
      final pivoted =
          df.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'max');
      expect(pivoted.rows[0][1], equals(10));
      expect(pivoted.rows[0][2], equals(30));
    });

    test('pivotTable with fill_value', () {
      final df = DataFrame.fromRows([
        {'A': 'foo', 'B': 'one', 'C': 1},
        {'A': 'bar', 'B': 'two', 'C': 2},
      ]);
      final pivoted =
          df.pivotTable(index: 'A', columns: 'B', values: 'C', fillValue: 0);
      // Expected:
      // A | one | two
      //---|-----|----
      //foo| 1   | 0
      //bar| 0   | 2
      expect(pivoted.rows[0][0], equals('foo'));
      expect(pivoted.rows[0][1], equals(1));
      expect(pivoted.rows[0][2], equals(0)); // filled
      expect(pivoted.rows[1][0], equals('bar'));
      expect(pivoted.rows[1][1], equals(0)); // filled
      expect(pivoted.rows[1][2], equals(2));
    });

    test('pivotTable with non-numeric values and min/max aggFunc', () {
      final df = DataFrame.fromRows([
        {'A': 'group1', 'B': 'cat1', 'C': 'apple'},
        {'A': 'group1', 'B': 'cat1', 'C': 'banana'},
        {'A': 'group1', 'B': 'cat2', 'C': 'cherry'},
        {'A': 'group2', 'B': 'cat1', 'C': 'date'},
      ]);

      final pivotedMin =
          df.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'min');
      expect(pivotedMin.columns, equals(['A', 'cat1', 'cat2']));
      expect(pivotedMin.row({'A': 'group1'})['cat1'], equals('apple'));
      expect(pivotedMin.row({'A': 'group1'})['cat2'], equals('cherry'));
      expect(pivotedMin.row({'A': 'group2'})['cat1'], equals('date'));

      final pivotedMax =
          df.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'max');
      expect(pivotedMax.row({'A': 'group1'})['cat1'], equals('banana'));
    });
  });

  group('DataFrame.pivot (strict)', () {
    test('Basic strict pivot', () {
      final df = DataFrame.fromRows([
        {'A': 'foo', 'B': 'one', 'C': 10},
        {'A': 'foo', 'B': 'two', 'C': 20},
        {'A': 'bar', 'B': 'one', 'C': 30},
        {'A': 'bar', 'B': 'two', 'C': 40},
      ]);
      final pivoted = df.pivot(index: 'A', columns: 'B', values: 'C');
      // Expected:
      // A | one | two
      //---|-----|----
      //bar| 30  | 40
      //foo| 10  | 20
      expect(pivoted.columns, equals(['A', 'one', 'two']));
      expect(pivoted.rows[0], equals(['bar', 30, 40]));
      expect(pivoted.rows[1], equals(['foo', 10, 20]));
    });

    test('Strict pivot throws error on duplicate index/column pairs', () {
      final df = DataFrame.fromRows([
        {'A': 'foo', 'B': 'one', 'C': 10},
        {'A': 'foo', 'B': 'one', 'C': 20}, // Duplicate
        {'A': 'bar', 'B': 'two', 'C': 30},
      ]);
      expect(
        () => df.pivot(index: 'A', columns: 'B', values: 'C'),
        throwsArgumentError,
      );
    });

    test('Strict pivot with implicit value column (one remaining)', () {
      final df = DataFrame.fromRows([
        {'index_col': 'idx1', 'column_col': 'colA', 'value_col': 100},
        {'index_col': 'idx1', 'column_col': 'colB', 'value_col': 200},
        {'index_col': 'idx2', 'column_col': 'colA', 'value_col': 300},
      ]);
      final pivoted = df.pivot(
          index: 'index_col',
          columns: 'column_col'); // values='value_col' inferred
      expect(pivoted.columns, equals(['index_col', 'colA', 'colB']));
      expect(pivoted.row({'index_col': 'idx1'})['colA'], equals(100));
      expect(pivoted.row({'index_col': 'idx1'})['colB'], equals(200));
      expect(pivoted.row({'index_col': 'idx2'})['colA'], equals(300));
      expect(pivoted.row({'index_col': 'idx2'})['colB'], isNull);
    });

    test(
        'Strict pivot with implicit value column (multiple remaining - uses first)',
        () {
      final df = DataFrame.fromRows([
        {'index': 'r1', 'cols': 'c1', 'val1': 1, 'val2': 10},
        {'index': 'r1', 'cols': 'c2', 'val1': 2, 'val2': 20},
        {'index': 'r2', 'cols': 'c1', 'val1': 3, 'val2': 30},
      ]);
      // Expectation: val1 will be used, a warning would be printed (cannot test print directly)
      final pivoted = df.pivot(index: 'index', columns: 'cols');
      expect(pivoted.columns, equals(['index', 'c1', 'c2']));
      expect(pivoted.row({'index': 'r1'})['c1'], equals(1));
      expect(pivoted.row({'index': 'r1'})['c2'], equals(2));
      expect(pivoted.row({'index': 'r2'})['c1'], equals(3));
    });

    test('Strict pivot throws error if no value column can be inferred', () {
      final df = DataFrame.fromRows([
        {'index': 'r1', 'cols': 'c1'},
        {'index': 'r1', 'cols': 'c2'},
      ]);
      expect(
        () => df.pivot(index: 'index', columns: 'cols'),
        throwsArgumentError,
      );
    });
  });

  group('DataFrame.crosstab', () {
    final df = DataFrame.fromRows([
      {'A': 'foo', 'B': 'one', 'C': 10, 'D': 100},
      {'A': 'foo', 'B': 'one', 'C': 20, 'D': 200},
      {'A': 'foo', 'B': 'two', 'C': 30, 'D': 300},
      {'A': 'bar', 'B': 'one', 'C': 40, 'D': 400},
      {'A': 'bar', 'B': 'two', 'C': 50, 'D': 500},
      {'A': 'bar', 'B': 'two', 'C': 60, 'D': 600},
      {'A': 'baz', 'B': 'one', 'C': 70, 'D': 700},
    ]);

    test('Basic crosstab (counts)', () {
      final ct = df.crosstab(index: 'A', column: 'B');
      // B      one  two
      // A
      // foo      2    1
      // bar      1    2
      // baz      1    0 (or null, then filled to 0 by default)
      expect(ct.columns, equals(['A', 'one', 'two']));
      expect(ct.row({'A': 'foo'})['one'], equals(2));
      expect(ct.row({'A': 'foo'})['two'], equals(1));
      expect(ct.row({'A': 'bar'})['one'], equals(1));
      expect(ct.row({'A': 'bar'})['two'], equals(2));
      expect(ct.row({'A': 'baz'})['one'], equals(1));
      expect(ct.row({'A': 'baz'})['two'],
          equals(0)); // Assuming missing combinations are 0
    });

    test('Crosstab with values and aggFunc=sum', () {
      final ct =
          df.crosstab(index: 'A', column: 'B', values: 'C', aggfunc: 'sum');
      // B      one  two
      // A
      // foo     30   30   (10+20)
      // bar     40  110   (50+60)
      // baz     70    0
      expect(ct.row({'A': 'foo'})['one'], equals(30));
      expect(ct.row({'A': 'foo'})['two'], equals(30));
      expect(ct.row({'A': 'bar'})['one'], equals(40));
      expect(ct.row({'A': 'bar'})['two'], equals(110));
      expect(ct.row({'A': 'baz'})['one'], equals(70));
      expect(ct.row({'A': 'baz'})['two'],
          equals(0)); // No 'baz' 'two' combo, sum is 0
    });

    test('Crosstab with margins=true', () {
      final ct = df.crosstab(
          index: 'A', column: 'B', margins: true, marginsName: 'Total');
      //      B  one  two  Total
      // A
      // foo      2    1      3
      // bar      1    2      3
      // baz      1    0      1
      // Total    4    3      7
      expect(ct.columns, equals(['A', 'one', 'two', 'Total']));
      expect(ct.rows.length, equals(4)); // foo, bar, baz, Total
      expect(ct.row({'A': 'foo'})['Total'], equals(3));
      expect(ct.row({'A': 'bar'})['Total'], equals(3));
      expect(ct.row({'A': 'baz'})['Total'], equals(1));
      final totalRow = ct.rows.firstWhere((r) => r[0] == 'Total');
      expect(totalRow[ct.columns.indexOf('one')], equals(4));
      expect(totalRow[ct.columns.indexOf('two')], equals(3));
      expect(totalRow[ct.columns.indexOf('Total')], equals(7));
    });

    test('Crosstab with normalize=true (all)', () {
      final ct = df.crosstab(index: 'A', column: 'B', normalize: true);
      final totalObservations = 7.0;
      // Expected proportions
      expect(
          ct.row({'A': 'foo'})['one'], closeTo(2 / totalObservations, 0.001));
      expect(
          ct.row({'A': 'foo'})['two'], closeTo(1 / totalObservations, 0.001));
      // ... check other cells
    });

    test('Crosstab with normalize=\'index\'', () {
      final ct = df.crosstab(index: 'A', column: 'B', normalize: 'index');
      // Foo row sum: 2+1=3
      expect(ct.row({'A': 'foo'})['one'], closeTo(2 / 3, 0.001));
      expect(ct.row({'A': 'foo'})['two'], closeTo(1 / 3, 0.001));
      // Bar row sum: 1+2=3
      expect(ct.row({'A': 'bar'})['one'], closeTo(1 / 3, 0.001));
      expect(ct.row({'A': 'bar'})['two'], closeTo(2 / 3, 0.001));
      // Baz row sum: 1+0=1
      expect(ct.row({'A': 'baz'})['one'], closeTo(1 / 1, 0.001));
      expect(ct.row({'A': 'baz'})['two'], closeTo(0 / 1, 0.001));
    });

    test('Crosstab with normalize=\'columns\'', () {
      final ct = df.crosstab(index: 'A', column: 'B', normalize: 'columns');
      // 'one' column sum: 2+1+1 = 4
      // 'two' column sum: 1+2+0 = 3
      expect(ct.row({'A': 'foo'})['one'], closeTo(2 / 4, 0.001));
      expect(ct.row({'A': 'bar'})['one'], closeTo(1 / 4, 0.001));
      expect(ct.row({'A': 'baz'})['one'], closeTo(1 / 4, 0.001));

      expect(ct.row({'A': 'foo'})['two'], closeTo(1 / 3, 0.001));
      expect(ct.row({'A': 'bar'})['two'], closeTo(2 / 3, 0.001));
      expect(ct.row({'A': 'baz'})['two'], closeTo(0 / 3, 0.001));
    });

    test('Crosstab with normalize=\'all\' and margins=true', () {
      final ct = df.crosstab(
          index: 'A',
          column: 'B',
          normalize: 'all',
          margins: true,
          marginsName: 'Overall');
      final totalObservations = 7.0;
      // Check a few values
      expect(
          ct.row({'A': 'foo'})['one'], closeTo(2 / totalObservations, 0.001));
      expect(ct.row({'A': 'foo'})['Overall'],
          closeTo(3 / totalObservations, 0.001));

      final totalRow = ct.rows.firstWhere((r) => r[0] == 'Overall');
      expect(totalRow[ct.columns.indexOf('one')],
          closeTo(4 / totalObservations, 0.001));
      expect(totalRow[ct.columns.indexOf('Overall')],
          closeTo(1.0, 0.001)); // Grand total of proportions
    });

    test('Crosstab with values, aggFunc, normalize, and margins', () {
      final ct = df.crosstab(
          index: 'A',
          column: 'B',
          values: 'C',
          aggfunc: 'sum',
          normalize: 'index',
          margins: true);

      // Calculate expected sums for normalization and margins
      // Row sums before normalization (for 'index' normalization base):
      // foo: (10+20) + 30 = 60
      // bar: 40 + (50+60) = 150
      // baz: 70 + 0 = 70

      // Check 'foo' row
      expect(ct.row({'A': 'foo'})['one'],
          closeTo(30.0 / 60.0, 0.001)); // (10+20)/60
      expect(ct.row({'A': 'foo'})['two'], closeTo(30.0 / 60.0, 0.001)); // 30/60
      expect(
          ct.row({'A': 'foo'})['All'], closeTo(1.0, 0.001)); // (30+30)/60 = 1.0

      // Check 'bar' row
      expect(ct.row({'A': 'bar'})['one'], closeTo(40.0 / 150.0, 0.001));
      expect(ct.row({'A': 'bar'})['two'], closeTo(110.0 / 150.0, 0.001));
      expect(ct.row({'A': 'bar'})['All'], closeTo(1.0, 0.001));

      // Check 'All' (margins) row - these sums are of the *normalized* values
      // 'one' column normalized sum: (30/60) + (40/150) + (70/70)
      double expectedAllOne = (30.0 / 60.0) + (40.0 / 150.0) + (70.0 / 70.0);
      // 'two' column normalized sum: (30/60) + (110/150) + (0/70)
      double expectedAllTwo = (30.0 / 60.0) + (110.0 / 150.0) + (0 / 70.0);
      // 'All' column normalized sum: 1.0 + 1.0 + 1.0 (sum of row proportions)
      double expectedAllAll = 1.0 + 1.0 + 1.0;

      final totalRow = ct.rows.firstWhere((r) => r[0] == 'All');
      expect(
          totalRow[ct.columns.indexOf('one')], closeTo(expectedAllOne, 0.001));
      expect(
          totalRow[ct.columns.indexOf('two')], closeTo(expectedAllTwo, 0.001));
      expect(
          totalRow[ct.columns.indexOf('All')], closeTo(expectedAllAll, 0.001));
    });
  });

  group('DataFrame.bin', () {
    final df = DataFrame.fromRows([
      {'value': 1},
      {'value': 2},
      {'value': 3},
      {'value': 4},
      {'value': 5},
      {'value': 6},
      {'value': 7},
      {'value': 8},
      {'value': 9},
      {'value': 10},
    ]);

    test('bin with int bins, default right=true, include_lowest=false', () {
      final binned = df.bin('value', 3, newColumn: 'value_bin');
      // Expected bins for data 1-10 with 3 bins:
      // Min: 1, Max: 10. Range: 9. Step: 3.
      // Edges: 1, 4, 7, 10
      // Bins: (1, 4], (4, 7], (7, 10]
      // Labels: (1.00, 4.00], (4.00, 7.00], (7.00, 10.00]
      // Data: 1 (no), 2,3,4 (yes) | 5,6,7 (yes) | 8,9,10 (yes)
      // Actual numericData: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      // binIndices (index in numericData):
      // 1 -> null (or first bin if include_lowest=true and right=true for first bin)
      // 2,3,4 -> bin 0: (1.00, 4.00]
      // 5,6,7 -> bin 1: (4.00, 7.00]
      // 8,9,10 -> bin 2: (7.00, 10.00]
      // The original implementation of `bin` in the prompt had an issue in its data mapping part.
      // Assuming the corrected `bin` from the previous phase:
      expect(
          binned.column('value_bin').data,
          equals([
            null, // 1 is not > 1 and <= 4. If include_lowest, it would be in [1,4]
            '(1.00, 4.00]', '(1.00, 4.00]', '(1.00, 4.00]', // 2,3,4
            '(4.00, 7.00]', '(4.00, 7.00]', '(4.00, 7.00]', // 5,6,7
            '(7.00, 10.00]', '(7.00, 10.00]', '(7.00, 10.00]', // 8,9,10
          ]));
    });

    test('bin with int bins, right=true, include_lowest=true', () {
      final binned =
          df.bin('value', 3, newColumn: 'value_bin', includeLowest: true);
      // Edges: 1, 4, 7, 10
      // Bins: [1, 4], (4, 7], (7, 10]
      expect(
          binned.column('value_bin').data,
          equals([
            '[1.00, 4.00]', // 1
            '[1.00, 4.00]', '[1.00, 4.00]', '[1.00, 4.00]', // 2,3,4
            '(4.00, 7.00]', '(4.00, 7.00]', '(4.00, 7.00]', // 5,6,7
            '(7.00, 10.00]', '(7.00, 10.00]', '(7.00, 10.00]', // 8,9,10
          ]));
    });

    test(
        'bin with int bins, right=false, include_lowest=false (effectively true for first bin)',
        () {
      final binned = df.bin('value', 3, newColumn: 'value_bin', right: false);
      // Edges: 1, 4, 7, 10
      // Bins: [1, 4), [4, 7), [7, 10]
      expect(
          binned.column('value_bin').data,
          equals([
            '[1.00, 4.00)', '[1.00, 4.00)', '[1.00, 4.00)', // 1,2,3
            '[4.00, 7.00)', '[4.00, 7.00)', '[4.00, 7.00)', // 4,5,6
            '[7.00, 10.00]', '[7.00, 10.00]', '[7.00, 10.00]',
            '[7.00, 10.00]', // 7,8,9,10
          ]));
    });

    test('bin with List<num> bins', () {
      final binned = df.bin('value', [0, 5, 10], newColumn: 'value_bin_list');
      // Bins: (0,5], (5,10] (default right=true)
      expect(
          binned.column('value_bin_list').data,
          equals([
            '(0.00, 5.00]', '(0.00, 5.00]', '(0.00, 5.00]', '(0.00, 5.00]',
            '(0.00, 5.00]', // 1,2,3,4,5
            '(5.00, 10.00]', '(5.00, 10.00]', '(5.00, 10.00]', '(5.00, 10.00]',
            '(5.00, 10.00]', // 6,7,8,9,10
          ]));
    });

    test('bin with List<num> bins and include_lowest=true', () {
      final binned = df.bin('value', [1, 5, 10],
          newColumn: 'value_bin_list_incl', includeLowest: true);
      // Bins: [1,5], (5,10]
      expect(
          binned.column('value_bin_list_incl').data,
          equals([
            '[1.00, 5.00]', '[1.00, 5.00]', '[1.00, 5.00]', '[1.00, 5.00]',
            '[1.00, 5.00]', // 1,2,3,4,5
            '(5.00, 10.00]', '(5.00, 10.00]', '(5.00, 10.00]', '(5.00, 10.00]',
            '(5.00, 10.00]', // 6,7,8,9,10
          ]));
    });

    test('bin with List<num> bins, right=false', () {
      final binned = df.bin('value', [1, 5, 10],
          newColumn: 'value_bin_list_rf', right: false);
      // Bins: [1,5), [5,10]
      expect(
          binned.column('value_bin_list_rf').data,
          equals([
            '[1.00, 5.00)', '[1.00, 5.00)', '[1.00, 5.00)',
            '[1.00, 5.00)', // 1,2,3,4
            '[5.00, 10.00]', '[5.00, 10.00]', '[5.00, 10.00]', '[5.00, 10.00]',
            '[5.00, 10.00]', '[5.00, 10.00]', // 5,6,7,8,9,10
          ]));
    });

    test('bin with duplicate bin edges raises error by default', () {
      expect(() => df.bin('value', [1, 5, 5, 10]), throwsArgumentError);
    });

    test('bin with duplicate bin edges and duplicates="drop"', () {
      final binned = df.bin('value', [1, 5, 5, 10],
          newColumn: 'value_bin_dup_drop', duplicates: 'drop');
      // Effective bins: [1,5], (5,10] (with include_lowest=false default for list bins)
      // This is equivalent to df.bin('value', [1, 5, 10], newColumn: 'value_bin_list_incl_default_right', include_lowest: false);
      // Bins with include_lowest=false, right=true: (1,5], (5,10]
      // Values: 1 (null), 2,3,4,5 (bin1) | 6,7,8,9,10 (bin2)
      expect(
          binned.column('value_bin_dup_drop').data,
          equals([
            null, // 1 is not > 1
            '(1.00, 5.00]', '(1.00, 5.00]', '(1.00, 5.00]',
            '(1.00, 5.00]', // 2,3,4,5
            '(5.00, 10.00]', '(5.00, 10.00]', '(5.00, 10.00]', '(5.00, 10.00]',
            '(5.00, 10.00]', // 6,7,8,9,10
          ]));
    });

    test('bin with provided labels', () {
      final binned = df.bin('value', 2,
          newColumn: 'value_bin_labels', labels: ['low', 'high']);
      // Edges: 1, 5.5, 10. Bins: (1, 5.5], (5.5, 10]
      // 1 (null), 2,3,4,5 (low) | 6,7,8,9,10 (high)
      expect(
          binned.column('value_bin_labels').data,
          equals([
            null,
            'low',
            'low',
            'low',
            'low',
            'high',
            'high',
            'high',
            'high',
            'high',
          ]));
    });

    test('bin with single unique value in column', () {
      final dfSingle = DataFrame.fromRows([
        {'value': 5},
        {'value': 5},
        {'value': 5},
      ]);
      final binned = dfSingle.bin('value', 2, newColumn: 'value_bin_single');
      // dataMin and dataMax will be adjusted slightly, e.g., 4.995 to 5.005 if value is 5
      // Edges might be like [4.995, 5.000, 5.005]
      // Bins: (4.995, 5.000], (5.000, 5.005]
      // All 5s should fall into the second bin if right=true.
      // The default labels would be (4.99, 5.00] and (5.00, 5.01] (approx)
      // It is tricky to assert exact labels due to floating point adjustments.
      // Let's check if all values fall into *some* bin.
      expect(binned.column('value_bin_single').data.every((e) => e != null),
          isTrue);
      expect(binned.column('value_bin_single').data.length, equals(3));
    });

    test('bin on empty data throws error', () {
      final dfEmpty = DataFrame.fromRows([
        {'value': double.nan}
      ]); // Effectively empty numericData
      expect(() => dfEmpty.bin('value', 3), throwsArgumentError);
    });
  });
}
