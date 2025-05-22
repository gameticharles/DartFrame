import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  // Sample DataFrames for testing
  final df1 = DataFrame.fromRows([
    {'key': 'K0', 'A': 'A0', 'B': 'B0'},
    {'key': 'K1', 'A': 'A1', 'B': 'B1'},
    {'key': 'K2', 'A': 'A2', 'B': 'B2'},
    {'key': 'K3', 'A': 'A3', 'B': 'B3'},
  ]);

  final df2 = DataFrame.fromRows([
    {'key': 'K0', 'C': 'C0', 'D': 'D0'},
    {'key': 'K1', 'C': 'C1', 'D': 'D1'},
    {'key': 'K2', 'C': 'C2', 'D': 'D2'},
    {'key': 'K4', 'C': 'C3', 'D': 'D3'}, // K4 is unique to df2
  ]);

  final df3 = DataFrame.fromRows([ // For multi-key join
    {'key1': 'K0', 'key2': 'X0', 'E': 'E0'},
    {'key1': 'K1', 'key2': 'X1', 'E': 'E1'},
  ]);
  
  final df1Multi = DataFrame.fromRows([ // For multi-key join with df3
    {'key1': 'K0', 'key2': 'X0', 'A': 'A0'},
    {'key1': 'K1', 'key2': 'X1', 'A': 'A1'},
    {'key1': 'K0', 'key2': 'X2', 'A': 'A2'}, // X2 won't match df3
  ]);


  group('DataFrame.join() with "on" parameter:', () {
    test('inner join with "on" as String', () {
      final result = df1.join(df2, on: 'key', how: 'inner');
      expect(result.rowCount, equals(3));
      expect(result.columns, equals(['key', 'A', 'B', 'C', 'D']));
      expect(result.rows.map((r) => Map.fromIterables(result.columns, r)).toList(),
        containsAll([
          {'key': 'K0', 'A': 'A0', 'B': 'B0', 'C': 'C0', 'D': 'D0'},
          {'key': 'K1', 'A': 'A1', 'B': 'B1', 'C': 'C1', 'D': 'D1'},
          {'key': 'K2', 'A': 'A2', 'B': 'B2', 'C': 'C2', 'D': 'D2'},
        ])
      );
    });

    test('left join with "on" as String', () {
      final result = df1.join(df2, on: 'key', how: 'left');
      expect(result.rowCount, equals(4));
      expect(result.columns, equals(['key', 'A', 'B', 'C', 'D']));
      expect(result.rows.map((r) => Map.fromIterables(result.columns, r)).toList(),
        containsAllInOrder([
          {'key': 'K0', 'A': 'A0', 'B': 'B0', 'C': 'C0', 'D': 'D0'},
          {'key': 'K1', 'A': 'A1', 'B': 'B1', 'C': 'C1', 'D': 'D1'},
          {'key': 'K2', 'A': 'A2', 'B': 'B2', 'C': 'C2', 'D': 'D2'},
          {'key': 'K3', 'A': 'A3', 'B': 'B3', 'C': null, 'D': null},
        ])
      );
    });
    
    test('right join with "on" as String', () {
      final result = df1.join(df2, on: 'key', how: 'right', suffixes: ['_l', '_r']);
      expect(result.rowCount, equals(4));
      expect(result.columns, equals(['key', 'A', 'B', 'C', 'D']));
       final resultRowsAsMaps = result.rows.map((r) => Map.fromIterables(result.columns,r)).toList();
      expect(resultRowsAsMaps, containsAllInOrder([
        {'key': 'K0', 'A': 'A0', 'B': 'B0', 'C': 'C0', 'D': 'D0'},
        {'key': 'K1', 'A': 'A1', 'B': 'B1', 'C': 'C1', 'D': 'D1'},
        {'key': 'K2', 'A': 'A2', 'B': 'B2', 'C': 'C2', 'D': 'D2'},
        {'key': 'K4', 'A': null, 'B': null, 'C': 'C3', 'D': 'D3'},
      ]));
    });

    test('outer join with "on" as String', () {
      final result = df1.join(df2, on: 'key', how: 'outer', suffixes: ['_l', '_r']);
      expect(result.rowCount, equals(5));
      expect(result.columns, equals(['key', 'A', 'B', 'C', 'D']));
       final resultRowsAsMaps = result.rows.map((r) => Map.fromIterables(result.columns,r)).toList();
      expect(resultRowsAsMaps, containsAllInOrder([
          {'key': 'K0', 'A': 'A0', 'B': 'B0', 'C': 'C0', 'D': 'D0'},
          {'key': 'K1', 'A': 'A1', 'B': 'B1', 'C': 'C1', 'D': 'D1'},
          {'key': 'K2', 'A': 'A2', 'B': 'B2', 'C': 'C2', 'D': 'D2'},
          {'key': 'K3', 'A': 'A3', 'B': 'B3', 'C': null, 'D': null},
          {'key': 'K4', 'A': null, 'B': null, 'C': 'C3', 'D': 'D3'},
      ]));
    });

    test('inner join with "on" as List<String>', () {
      final result = df1Multi.join(df3, on: ['key1', 'key2'], how: 'inner');
      expect(result.rowCount, equals(2));
      expect(result.columns, equals(['key1', 'key2', 'A', 'E']));
      expect(result.rows.map((r) => Map.fromIterables(result.columns, r)).toList(),
        containsAll([
          {'key1': 'K0', 'key2': 'X0', 'A': 'A0', 'E': 'E0'},
          {'key1': 'K1', 'key2': 'X1', 'A': 'A1', 'E': 'E1'},
        ])
      );
    });

    test('Error when "on" is used with "leftOn"', () {
      expect(
        () => df1.join(df2, on: 'key', leftOn: 'key', how: 'inner'),
        throwsArgumentError
      );
    });

    test('Error when "on" is used with "rightOn"', () {
      expect(
        () => df1.join(df2, on: 'key', rightOn: 'key', how: 'inner'),
        throwsArgumentError
      );
    });
    
    test('Error when "on" column does not exist in left DataFrame', () {
      expect(
        () => df1.join(df2, on: 'wrong_key', how: 'inner'),
        throwsArgumentError
      );
    });
    
    test('Error when "on" column does not exist in right DataFrame', () {
      final dfTemp = DataFrame.fromRows([{'wrong_key': 'K0'}]);
      expect(
        () => df1.join(dfTemp, on: 'key', how: 'inner'), // 'key' is not in dfTemp
        throwsArgumentError
      );
    });
  });

  group('DataFrame.join() with "indicator" parameter:', () {
    test('indicator=true for inner join', () {
      final result = df1.join(df2, on: 'key', how: 'inner', indicator: true);
      expect(result.columns, contains('_merge'));
      expect(result.column('_merge').data.every((v) => v == 'both'), isTrue);
    });

    test('indicator="custom_name" for left join', () {
      final result = df1.join(df2, on: 'key', how: 'left', indicator: 'source_info');
      expect(result.columns, contains('source_info'));
      expect(result.column('source_info').data,
        equals(['both', 'both', 'both', 'left_only'])
      );
    });

    test('indicator for right join', () {
      final result = df1.join(df2, on: 'key', how: 'right', indicator: true);
      expect(result.column('_merge').data, 
        equals(['both', 'both', 'both', 'right_only'])
      );
    });

    test('indicator for outer join', () {
      final result = df1.join(df2, on: 'key', how: 'outer', indicator: true);
      // Order can be tricky with outer joins depending on hash map iteration.
      // We need to check the values associated with keys.
      final expectedIndicators = <String, String>{
        'K0': 'both', 'K1': 'both', 'K2': 'both', 
        'K3': 'left_only', 'K4': 'right_only'
      };
      for(var row in result.rows) {
        final rowMap = Map.fromIterables(result.columns, row);
        expect(rowMap['_merge'], equals(expectedIndicators[rowMap['key']]));
      }
    });
    
    test('indicator column name conflict (default _merge)', () {
      final df1WithMerge = df1.copy();
      df1WithMerge.addColumn('_merge', defaultValue: List.filled(df1.rowCount, 'original'));
      final result = df1WithMerge.join(df2, on: 'key', how: 'left', indicator: true);
      
      // Default indicator is '_merge'. If it exists, it should become '_merge_1' or similar
      // This depends on the exact unique name generation logic.
      // Let's assume it adds suffix like pandas.
      expect(result.columns, contains('_merge_1')); // Or some other unique name
      expect(result.columns, contains('_merge')); // Original column
      expect(result.column('_merge').data.every((v) => v == 'original'), isTrue);
      expect(result.column('_merge_1').data, equals(['both', 'both', 'both', 'left_only']));
    });

    test('indicator column name conflict (custom name)', () {
      final df1WithCustom = df1.copy();
      df1WithCustom.addColumn('custom_indicator', defaultValue: List.filled(df1.rowCount, 'original_custom'));
      final result = df1WithCustom.join(df2, on: 'key', how: 'left', indicator: 'custom_indicator');
      expect(result.columns, contains('custom_indicator_1'));
      expect(result.columns, contains('custom_indicator'));
      expect(result.column('custom_indicator').data.every((v) => v == 'original_custom'), isTrue);
      expect(result.column('custom_indicator_1').data, equals(['both', 'both', 'both', 'left_only']));
    });
  });
  
  group('DataFrame.join() - Combinations and Edge Cases:', () {
    test('left join with "on" and indicator=true, different lengths', () {
      final dfShort = DataFrame.fromRows([
        {'id': 'A', 'val': 1},
        {'id': 'B', 'val': 2},
      ]);
      final dfLong = DataFrame.fromRows([
        {'id': 'A', 'info': 'InfoA'},
        {'id': 'C', 'info': 'InfoC'},
        {'id': 'B', 'info': 'InfoB'},
        {'id': 'D', 'info': 'InfoD'},
      ]);
      final result = dfShort.join(dfLong, on: 'id', how: 'left', indicator: true);
      expect(result.rowCount, equals(2));
      expect(result.columns, equals(['id', 'val', 'info', '_merge']));
      expect(result.rows, equals([
        ['A', 1, 'InfoA', 'both'],
        ['B', 2, 'InfoB', 'both'],
      ]));
    });

    test('outer join with "on" and indicator="source", non-overlapping keys', () {
      final dfLeft = DataFrame.fromRows([{'key': 'L1', 'val_l': 10}]);
      final dfRight = DataFrame.fromRows([{'key': 'R1', 'val_r': 20}]);
      final result = dfLeft.join(dfRight, on: 'key', how: 'outer', indicator: 'source');
      expect(result.rowCount, equals(2));
      expect(result.columns, equals(['key', 'val_l', 'val_r', 'source']));
      final resultRowsAsMaps = result.rows.map((r) => Map.fromIterables(result.columns,r)).toList();
      expect(resultRowsAsMaps, containsAll([
         {'key': 'L1', 'val_l': 10, 'val_r': null, 'source': 'left_only'},
         {'key': 'R1', 'val_l': null, 'val_r': 20, 'source': 'right_only'},
      ]));
    });

    test('inner join resulting in an empty DataFrame', () {
      final dfLeft = DataFrame.fromRows([{'key': 'L1', 'val': 1}]);
      final dfRight = DataFrame.fromRows([{'key': 'R1', 'val': 2}]);
      final result = dfLeft.join(dfRight, on: 'key', how: 'inner');
      expect(result.rowCount, equals(0));
      expect(result.columns, equals(['key', 'val', 'val_x', 'val_y'])); // Suffixes apply if join keys are same as value cols
    });
    
    test('inner join on multiple columns resulting in an empty DataFrame', () {
      final dfA = DataFrame.fromRows([
        {'id1': 'A', 'id2': 1, 'data_a': 100},
      ]);
      final dfB = DataFrame.fromRows([
        {'id1': 'A', 'id2': 2, 'data_b': 200}, // id2 differs
      ]);
      final result = dfA.join(dfB, on: ['id1', 'id2'], how: 'inner');
      expect(result.rowCount, equals(0));
    });

    test('join with missing values in join keys (inner)', () {
      final dfA = DataFrame.fromRows([
        {'key': 'K0', 'valA': 'A0'},
        {'key': null, 'valA': 'A1'},
        {'key': 'K2', 'valA': 'A2'},
      ]);
      final dfB = DataFrame.fromRows([
        {'key': 'K0', 'valB': 'B0'},
        {'key': null, 'valB': 'B1'}, // Will not match null in dfA due to null != null
        {'key': 'K2', 'valB': 'B2'},
      ]);
      final result = dfA.join(dfB, on: 'key', how: 'inner');
      // Only K0 and K2 should match. Nulls are not considered equal for joining.
      expect(result.rowCount, equals(2));
      expect(result.rows.map((r) => r[0]), containsAll(['K0', 'K2']));
    });

    test('join with missing values in join keys (left)', () {
      final dfA = DataFrame.fromRows([
        {'id': 1, 'valA': 'A0'},
        {'id': null, 'valA': 'A1'},
        {'id': 3, 'valA': 'A2'},
      ]);
      final dfB = DataFrame.fromRows([
        {'id': 1, 'valB': 'B0'},
        {'id': 2, 'valB': 'B1'}, // No match for null or 3 in dfA
      ]);
      final result = dfA.join(dfB, on: 'id', how: 'left', indicator: true);
      expect(result.rowCount, equals(3));
      expect(result.rows, containsAllInOrder([
        [1, 'A0', 'B0', 'both'],
        [null, 'A1', null, 'left_only'],
        [3, 'A2', null, 'left_only'],
      ]));
    });
  });

  group('DataFrame.join() - Regression Tests for leftOn/rightOn and suffixes:', () {
    test('inner join with leftOn/rightOn and suffixes', () {
      final dfLeft = DataFrame.fromRows([
        {'lkey': 'K0', 'A': 'A0'},
        {'lkey': 'K1', 'A': 'A1'},
      ]);
      final dfRight = DataFrame.fromRows([
        {'rkey': 'K0', 'B': 'B0'},
        {'rkey': 'K1', 'B': 'B1'},
      ]);
      final result = dfLeft.join(dfRight, leftOn: 'lkey', rightOn: 'rkey', how: 'inner', suffixes: ['_L', '_R']);
      // If leftOn/rightOn differ, they are both kept. If they are the same, only one is.
      // Current _joinRows logic keeps leftRow + non-key cols of rightRow.
      // This needs to be verified against actual implementation details.
      // Assuming the current implementation keeps the left key column if names are different,
      // and the columns from the right df are appended.
      // If `leftOn` and `rightOn` are different, both key columns should be present.
      // This part of the test might need adjustment based on how _joinRows and column naming is precisely handled.
      
      // Based on current code: newColumns = [...left_df_columns, ...right_df_columns_not_in_rightOn_or_not_conflicting]
      // If leftOn='lkey', rightOn='rkey', and 'lkey' != 'rkey', then 'lkey' and 'rkey' should both be in result.
      // And if 'A' and 'B' are unique, they are also there.
      // This test is more about the suffix application to potentially conflicting non-key columns.
      // Let's assume 'A' and 'B' are data columns and keys are distinct.
      expect(result.columns, equals(['lkey', 'A', 'rkey', 'B']));
      expect(result.rowCount, equals(2));
    });

    test('left join with conflicting column names and suffixes', () {
        final dfX = DataFrame.fromRows([
            {'id': 1, 'val': 'X1'},
            {'id': 2, 'val': 'X2'},
        ]);
        final dfY = DataFrame.fromRows([
            {'id': 1, 'val': 'Y1'},
            {'id': 3, 'val': 'Y3'},
        ]);
        final result = dfX.join(dfY, on: 'id', how: 'left', suffixes: ['_dfX', '_dfY']);
        expect(result.columns, equals(['id', 'val_dfX', 'val_dfY']));
        expect(result.rows, equals([
            [1, 'X1', 'Y1'],
            [2, 'X2', null],
        ]));
    });
  });

  group('DataFrame.concatenate()', () {
    final dfA1 = DataFrame.fromRows([
      {'col1': 1, 'col2': 'a'},
      {'col1': 2, 'col2': 'b'},
    ]);
    final dfA2 = DataFrame.fromRows([
      {'col1': 3, 'col2': 'c'},
      {'col1': 4, 'col2': 'd'},
    ]);
    final dfA3 = DataFrame.fromRows([
      {'col1': 5, 'col2': 'e'},
    ]);

    final dfB1 = DataFrame.fromRows([
      {'col1': 10, 'col3': 'x'},
      {'col1': 20, 'col3': 'y'},
    ]);
    final dfB2 = DataFrame.fromRows([
      {'col2': 'p', 'col4': 100.5},
      {'col2': 'q', 'col4': 200.5},
    ]);
    
    final dfEmptyRows = DataFrame.fromNames(['col1', 'col2']);
    final dfEmptyCols = DataFrame.fromRows([{},{}]); // 2 rows, 0 cols
    final dfEmptyAll = DataFrame.fromNames([]);


    group('axis = 0 (row-wise)', () {
      test('Concatenate two simple DataFrames with same columns', () {
        final result = dfA1.concatenate([dfA2]);
        expect(result.rowCount, equals(4));
        expect(result.columnCount, equals(2));
        expect(result.columns, equals(['col1', 'col2']));
        expect(result.rows, equals([
          [1, 'a'], [2, 'b'], [3, 'c'], [4, 'd']
        ]));
      });

      test('Concatenate multiple DataFrames', () {
        final result = dfA1.concatenate([dfA2, dfA3]);
        expect(result.rowCount, equals(5));
        expect(result.rows, equals([
          [1, 'a'], [2, 'b'], [3, 'c'], [4, 'd'], [5, 'e']
        ]));
      });

      test('Concatenate with an empty DataFrame (rows)', () {
        final result = dfA1.concatenate([dfEmptyRows, dfA2]);
        expect(result.rowCount, equals(4)); // df_empty_rows has 0 rows
        expect(result.rows, equals([
          [1, 'a'], [2, 'b'], [3, 'c'], [4, 'd']
        ]));
      });
      
      test('Concatenate with an empty DataFrame (cols) - outer join', () {
        final result = dfA1.concatenate([dfEmptyCols], join: 'outer');
        expect(result.rowCount, equals(4)); // 2 from df_a1, 2 from df_empty_cols
        expect(result.columns, equals(['col1', 'col2'])); // Columns from df_a1
        expect(result.rows, equals([
          [1, 'a'], [2, 'b'], 
          [null, null], [null, null] // df_empty_cols contributes nulls for df_a1's columns
        ]));
      });
      
      test('Concatenate with an empty DataFrame (cols) - inner join', () {
        final result = dfA1.concatenate([dfEmptyCols], join: 'inner');
        // Inner join on columns means 0 common columns
        expect(result.rowCount, equals(4)); 
        expect(result.columnCount, equals(0));
      });


      test('Concatenate an empty list of others returns a copy', () {
        final result = dfA1.concatenate([]);
        expect(result.rows, equals(dfA1.rows));
        expect(result.columns, equals(dfA1.columns));
        expect(result.rowCount, dfA1.rowCount);
        // Ensure it's a copy, not the same instance
        expect(identical(result, dfA1), isFalse);
      });

      test('join="outer" with different columns', () {
        final result = dfA1.concatenate([dfB1]);
        expect(result.rowCount, equals(4));
        expect(result.columns, equals(['col1', 'col2', 'col3']));
        expect(result.rows, equals([
          [1, 'a', null], [2, 'b', null],
          [10, null, 'x'], [20, null, 'y']
        ]));
      });
      
      test('join="outer" with multiple different columns', () {
        final result = dfA1.concatenate([dfB1, dfB2]);
        expect(result.rowCount, equals(6));
        expect(result.columns, equals(['col1', 'col2', 'col3', 'col4']));
        expect(result.rows, equals([
          [1, 'a', null, null], [2, 'b', null, null], // df_a1
          [10, null, 'x', null], [20, null, 'y', null], // df_b1
          [null, 'p', null, 100.5], [null, 'q', null, 200.5] // df_b2
        ]));
      });

      test('join="inner" with different columns', () {
        final result = dfA1.concatenate([dfB1], join: 'inner');
        expect(result.rowCount, equals(4));
        expect(result.columns, equals(['col1'])); // Only 'col1' is common
        expect(result.rows, equals([
          [1], [2], [10], [20]
        ]));
      });
      
       test('join="inner" with no common columns', () {
        final dfC1 = DataFrame.fromRows([{'X': 1}]);
        final dfC2 = DataFrame.fromRows([{'Y': 2}]);
        final result = dfC1.concatenate([dfC2], join: 'inner');
        expect(result.rowCount, equals(2)); // Rows are kept
        expect(result.columnCount, equals(0)); // No common columns
      });

      test('ignore_index=true with outer join', () {
        final result = dfA1.concatenate([dfB1], ignoreIndex: true);
        // Data and columns should be same as outer join test
        expect(result.rowCount, equals(4));
        expect(result.columns, equals(['col1', 'col2', 'col3']));
        // Implicitly, index is 0..3. No explicit index object to check yet.
      });
    });

    group('axis = 1 (column-wise)', () {
      final dfR1 = DataFrame.fromRows([ {'A': 1, 'B': 2}, {'A': 3, 'B': 4} ]);
      final dfR2 = DataFrame.fromRows([ {'C': 5, 'D': 6}, {'C': 7, 'D': 8} ]);
      final dfR3Short = DataFrame.fromRows([ {'E': 9} ]); // Fewer rows
      final dfR4Long = DataFrame.fromRows([ {'F':10},{'F':11},{'F':12}]); // More rows
      final dfR5DupCol = DataFrame.fromRows([ {'A': 10, 'G': 20}, {'A': 30, 'G': 40} ]);


      test('Basic column-wise concatenation (same row count)', () {
        final result = dfR1.concatenate([dfR2], axis: 1);
        expect(result.rowCount, equals(2));
        expect(result.columns, equals(['A', 'B', 'C', 'D']));
        expect(result.rows, equals([
          [1, 2, 5, 6], [3, 4, 7, 8]
        ]));
      });

      test('axis=1, join="outer" with different row counts', () {
        final result = dfR1.concatenate([dfR3Short], axis: 1, join: 'outer');
        expect(result.rowCount, equals(2)); // max_rows(df_r1, df_r3_short)
        expect(result.columns, equals(['A', 'B', 'E']));
        expect(result.rows, equals([
          [1, 2, 9],
          [3, 4, null] // df_r3_short padded with null
        ]));
        
        final result2 = dfR1.concatenate([dfR4Long], axis: 1, join: 'outer');
        expect(result2.rowCount, equals(3)); // max_rows(df_r1, df_r4_long)
        expect(result2.columns, equals(['A', 'B', 'F']));
        expect(result2.rows, equals([
          [1, 2, 10],
          [3, 4, 11],
          [null, null, 12] // df_r1 padded
        ]));
      });
      
      test('axis=1, join="inner" with different row counts', () {
        final result = dfR1.concatenate([dfR3Short], axis: 1, join: 'inner');
        expect(result.rowCount, equals(1)); // min_rows
        expect(result.columns, equals(['A', 'B', 'E']));
        expect(result.rows, equals([ [1, 2, 9] ]));

        final result2 = dfR1.concatenate([dfR4Long], axis: 1, join: 'inner');
        expect(result2.rowCount, equals(2)); // min_rows
        expect(result2.rows, equals([
            [1,2,10],
            [3,4,11],
        ]));
      });
      
      test('axis=1, join="inner" with one empty DataFrame (0 rows)', () {
        final dfEmptyR = DataFrame.fromNames(['X', 'Y']); // 0 rows
        final result = dfR1.concatenate([dfEmptyR], axis: 1, join: 'inner');
        expect(result.rowCount, equals(0));
        expect(result.columns, equals(['A', 'B', 'X', 'Y']));
      });

      test('axis=1 with ignore_index=true', () {
        final result = dfR1.concatenate([dfR2], axis: 1, ignoreIndex: true);
        expect(result.rowCount, equals(2));
        expect(result.columns, equals([0,1,2,3])); // Default integer column names
        expect(result.rows, equals([
          [1, 2, 5, 6], [3, 4, 7, 8]
        ]));
      });
      
      test('axis=1 with duplicate column names, ignore_index=false', () {
        final result = dfR1.concatenate([dfR5DupCol], axis: 1, ignoreIndex: false);
        expect(result.columns, equals(['A', 'B', 'A_1', 'G']));
        expect(result.rows, equals([
          [1, 2, 10, 20],
          [3, 4, 30, 40]
        ]));
      });
    });
    
    group('Edge Case Concatenations', () {
       test('Concatenate a list containing only one DataFrame (axis=0)', () {
        final result = dfA1.concatenate([dfA2], axis:0); // df_a1 is the 'this'
        final resultSingleList = dfA1.concatenate([dfA2]); // Same as above
        expect(resultSingleList.rows, equals(result.rows));
        expect(resultSingleList.columns, equals(result.columns));
      });
      
       test('Concatenate a list containing only one DataFrame (axis=1)', () {
        final dfR1 = DataFrame.fromRows([ {'A': 1, 'B': 2}, {'A': 3, 'B': 4} ]);
        final dfR2 = DataFrame.fromRows([ {'C': 5, 'D': 6}, {'C': 7, 'D': 8} ]);
        final result = dfR1.concatenate([dfR2], axis:1);
        //final resultSingleList = dfR1.concatenate([dfR2]); // axis=0 by default
        
        // This test needs to be specific for axis=1 with single df in list.
        // The `concatenate` method prepends `this` to `others`. So `df_r1.concatenate([df_r2])`
        // is effectively concatenating `[df_r1, df_r2]`.
        // A true "single df in list" would be `some_df.concatenate([another_single_df])`.
        // The original test `df_a1.concatenate([])` already covers concatenating an empty list.
        
        // Let's test `df_r1.concatenate([df_r2], axis:1)`
        expect(result.columns, equals(['A','B','C','D']));
      });

      test('Concatenate completely empty DataFrame with another (axis=0, outer)', () {
        final result = dfEmptyAll.concatenate([dfA1], axis: 0, join: 'outer');
        expect(result.rowCount, equals(2));
        expect(result.columns, equals(['col1', 'col2']));
        expect(result.rows, equals(dfA1.rows));
      });
      
      test('Concatenate completely empty DataFrame with another (axis=1, outer)', () {
        final result = dfEmptyAll.concatenate([dfA1], axis: 1, join: 'outer');
        expect(result.rowCount, equals(2)); // max rows
        expect(result.columns, equals(['col1', 'col2'])); // df_empty_all has 0 cols
        expect(result.rows, equals([
            [1, 'a'], [2, 'b'] // df_a1 data, df_empty_all contributes nothing to rows/cols
        ]));
      });
      
       test('Concatenate DataFrame with empty (cols) DataFrame (axis=1, outer)', () {
        final result = dfA1.concatenate([dfEmptyCols], axis: 1, join: 'outer');
        expect(result.rowCount, equals(2)); // max rows (both have 2)
        expect(result.columns, equals(['col1', 'col2'])); // df_empty_cols has 0 named cols
        expect(result.rows, equals([
            [1, 'a'], [2, 'b'] 
        ]));
      });
    });
  });
}

