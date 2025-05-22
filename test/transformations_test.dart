import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame.getDummies()', () {
    final dfSimple = DataFrame.fromRows([
      {'ID': 1, 'Category': 'A', 'Value': 100},
      {'ID': 2, 'Category': 'B', 'Value': 200},
      {'ID': 3, 'Category': 'A', 'Value': 300},
      {'ID': 4, 'Category': 'C', 'Value': 400},
      {'ID': 5, 'Category': 'B', 'Value': 500},
      {'ID': 6, 'Category': null, 'Value': 600}, // For dummyNA tests
    ]);

    final dfMixedTypes = DataFrame.fromRows([
      {'ID': 1, 'ColStr': 'x', 'ColInt': 10, 'ColBool': true, 'ColDouble': 1.1},
      {'ID': 2, 'ColStr': 'y', 'ColInt': 20, 'ColBool': false, 'ColDouble': 2.2},
      {'ID': 3, 'ColStr': 'x', 'ColInt': 30, 'ColBool': true, 'ColDouble': 3.3},
    ]);
    
    final dfWithNumericCat = DataFrame.fromRows([
        {'ID':1, 'NumCat': 101, 'Data': 'A'},
        {'ID':2, 'NumCat': 102, 'Data': 'B'},
        {'ID':3, 'NumCat': 101, 'Data': 'C'},
    ]);


    group('Basic Functionality:', () {
      test('Single column specified', () {
        final result = dfSimple.getDummies(['Category']);
        expect(result.columns, containsAll(['ID', 'Value']));
        expect(result.columns, containsAll(['Category_A', 'Category_B', 'Category_C']));
        expect(result.columns, isNot(contains('Category')));
        expect(result.rowCount, equals(dfSimple.rowCount));

        // Verify content of dummy columns
        final colA = result.column('Category_A').data;
        final colB = result.column('Category_B').data;
        final colC = result.column('Category_C').data;

        expect(colA, equals([1, 0, 1, 0, 0, 0]));
        expect(colB, equals([0, 1, 0, 0, 1, 0]));
        expect(colC, equals([0, 0, 0, 1, 0, 0]));
      });

      test('Multiple columns specified', () {
        final dfMulti = DataFrame.fromRows([
          {'ID': 1, 'Cat1': 'A', 'Cat2': 'X', 'Value': 10},
          {'ID': 2, 'Cat1': 'B', 'Cat2': 'Y', 'Value': 20},
          {'ID': 3, 'Cat1': 'A', 'Cat2': 'X', 'Value': 30},
        ]);
        final result = dfMulti.getDummies(['Cat1', 'Cat2']);
        expect(result.columns, containsAll(['ID', 'Value']));
        expect(result.columns, containsAll(['Cat1_A', 'Cat1_B', 'Cat2_X', 'Cat2_Y']));
        expect(result.columns, isNot(containsAll(['Cat1', 'Cat2'])));
        
        expect(result.column('Cat1_A').data, equals([1,0,1]));
        expect(result.column('Cat2_X').data, equals([1,0,1]));
      });
    });

    group('Column Auto-Detection (columns = null):', () {
      test('Auto-detects string columns, leaves others', () {
        final result = dfMixedTypes.getDummies(null); // Pass null for columns
        expect(result.columns, containsAll(['ID', 'ColInt', 'ColBool', 'ColDouble']));
        expect(result.columns, containsAll(['ColStr_x', 'ColStr_y']));
        expect(result.columns, isNot(contains('ColStr')));
        
        expect(result.column('ColStr_x').data, equals([1,0,1]));
        expect(result.column('ColStr_y').data, equals([0,1,0]));
        expect(result.column('ColInt').data, equals([10,20,30])); // Unchanged
      });
    });

    group('prefix Parameter:', () {
      test('Single string prefix for one column', () {
        final result = dfSimple.getDummies(['Category'], prefix: 'Type');
        expect(result.columns, containsAll(['Type_A', 'Type_B', 'Type_C']));
        expect(result.columns, isNot(contains('Category_A')));
      });

      test('Single string prefix for multiple columns (applies to all)', () {
        final dfMulti = DataFrame.fromRows([
          {'Cat1': 'A', 'Cat2': 'X'},
          {'Cat1': 'B', 'Cat2': 'Y'},
        ]);
        final result = dfMulti.getDummies(['Cat1', 'Cat2'], prefix: 'PFX');
        // The current implementation of getDummies uses the prefix for *all* specified columns.
        // So, it would be PFX_A, PFX_B for Cat1, and PFX_X, PFX_Y for Cat2 if prefix was column-specific.
        // However, if prefix is a single string, it's used as the prefix for the *new column name part derived from category value*,
        // and the original column name is used as the first part of the prefix.
        // E.g., colName_prefix_value. Let's re-check the implementation from previous phase.
        // The implementation was: newColName = '$currentPrefix$sep$categoryStr'; where currentPrefix = prefix ?? colName;
        // So if prefix is given, it REPLACES colName as the prefix part.
        expect(result.columns, containsAll(['PFX_A', 'PFX_B', 'PFX_X', 'PFX_Y']));
        expect(result.columns, isNot(containsAll(['Cat1_A', 'Cat2_X'])));
      });
    });
    
    group('prefixSep Parameter:', () {
      test('Custom prefixSep', () {
        final result = dfSimple.getDummies(['Category'], prefixSep: '|');
        expect(result.columns, containsAll(['Category|A', 'Category|B', 'Category|C']));
      });
      
      test('Custom prefixSep with prefix', () {
        final result = dfSimple.getDummies(['Category'], prefix: 'Type', prefixSep: '--');
        expect(result.columns, containsAll(['Type--A', 'Type--B', 'Type--C']));
      });
    });

    group('dummyNA Parameter:', () {
      test('dummyNA = true creates NA column', () {
        final result = dfSimple.getDummies(['Category'], dummyNA: true);
        expect(result.columns, contains('Category_na'));
        expect(result.column('Category_na').data, equals([0,0,0,0,0,1]));
        expect(result.column('Category_A').data, equals([1,0,1,0,0,0])); // Ensure other columns are correct
      });

      test('dummyNA = false (default) does not create NA column', () {
        final result = dfSimple.getDummies(['Category'], dummyNA: false);
        expect(result.columns, isNot(contains('Category_na')));
        expect(result.columns, isNot(contains('Category_null')));
      });
      
       test('dummyNA = true when no actual NA values present', () {
        final dfNoNa = DataFrame.fromRows([
          {'Category': 'A'}, {'Category': 'B'}
        ]);
        final result = dfNoNa.getDummies(['Category'], dummyNA: true);
        // No NA column should be created if no NA values were in the original Series for that column
        expect(result.columns, isNot(contains('Category_na')));
        expect(result.columns, containsAll(['Category_A', 'Category_B']));
      });
    });

    group('dropFirst Parameter:', () {
      test('dropFirst = true removes first category', () {
        // Categories (sorted): A, B, C, null (if dummyNA=true)
        // If dummyNA=false: A, B, C. Drops A.
        final result = dfSimple.getDummies(['Category'], dropFirst: true, dummyNA: false);
        expect(result.columns, isNot(contains('Category_A')));
        expect(result.columns, containsAll(['Category_B', 'Category_C']));
        expect(result.column('Category_B').data, equals([0,1,0,0,1,0]));
      });
      
      test('dropFirst = true with dummyNA = true', () {
        // Categories (sorted): A, B, C, then NA placeholder
        // Drops A.
        final result = dfSimple.getDummies(['Category'], dropFirst: true, dummyNA: true);
        expect(result.columns, isNot(contains('Category_A')));
        expect(result.columns, containsAll(['Category_B', 'Category_C', 'Category_na']));
        expect(result.column('Category_na').data, equals([0,0,0,0,0,1]));
      });

      test('dropFirst = false (default)', () {
        final result = dfSimple.getDummies(['Category'], dropFirst: false, dummyNA: false);
        expect(result.columns, containsAll(['Category_A', 'Category_B', 'Category_C']));
      });
    });
    
    group('Column Naming and Uniqueness:', () {
      test('Generated name conflicts with existing column', () {
        final dfConflict = DataFrame.fromRows([
          {'Category': 'A', 'Category_B': 99},
          {'Category': 'B', 'Category_B': 88},
        ]);
        final result = dfConflict.getDummies(['Category']);
        // Expect Category_A, and Category_B_1 (or similar unique name)
        expect(result.columns, contains('Category_A'));
        expect(result.columns, contains('Category_B_1')); // Assuming _1 suffix for conflict
        expect(result.columns, contains('Category_B')); // Original conflicting column
      });
      
      test('Category values are numbers', () {
        final result = dfWithNumericCat.getDummies(['NumCat']);
        expect(result.columns, containsAll(['ID', 'Data', 'NumCat_101', 'NumCat_102']));
        expect(result.column('NumCat_101').data, equals([1,0,1]));
        expect(result.column('NumCat_102').data, equals([0,1,0]));
      });
      
      test('Category values with special characters (default prefixSep)', () {
        final dfSpecial = DataFrame.fromRows([{'Spec': 'val*1'}, {'Spec': 'val?2'}]);
        final result = dfSpecial.getDummies(['Spec']);
        // Default prefixSep is '_'
        expect(result.columns, containsAll(['Spec_val*1', 'Spec_val?2']));
      });
    });

    group('Data Types:', () {
      test('Dummy columns are integer (0 or 1)', () {
        final result = dfSimple.getDummies(['Category']);
        expect(result.column('Category_A').data.every((e) => e is int), isTrue);
        expect(result.column('Category_B').data.every((e) => e is int), isTrue);
      });
    });

    group('Edge Cases:', () {
      test('DataFrame with no columns to encode (all numeric)', () {
        final dfNum = DataFrame.fromRows([{'X':1, 'Y':2}]);
        final result = dfNum.getDummies(null); // Auto-detect
        expect(result.columns, equals(dfNum.columns));
        expect(result.rows, equals(dfNum.rows));
        expect(identical(result, dfNum), isFalse); // Should be a copy
      });
      
      test('DataFrame with no columns to encode (specified non-string column)', () {
        // Current heuristic only dummifies string types when columns=null.
        // If a numeric column is explicitly passed, it should still be processed
        // (though it might result in many columns if not truly categorical).
        // The implementation treats non-string categories by their toString() value.
        final result = dfWithNumericCat.getDummies(['NumCat']); // NumCat is int
        expect(result.columns, containsAll(['ID', 'Data', 'NumCat_101', 'NumCat_102']));
      });

      test('Column with only one unique value', () {
        final dfOneUnique = DataFrame.fromRows([{'Cat': 'A'}, {'Cat': 'A'}]);
        final result = dfOneUnique.getDummies(['Cat']);
        expect(result.columns, equals(['Cat_A']));
        expect(result.column('Cat_A').data, equals([1,1]));
        
        final resultDropFirst = dfOneUnique.getDummies(['Cat'], dropFirst: true);
        expect(resultDropFirst.columnCount, equals(0)); // The only category 'A' is dropped
      });

      test('Column with only missing values', () {
        final dfOnlyNa = DataFrame.fromRows([
          {'Col': null}, {'Col': null},
        ], columns: ['Col']);
        dfOnlyNa.replaceMissingValueWith = null; // Explicitly for clarity

        final resultNoDummyNa = dfOnlyNa.getDummies(['Col'], dummyNA: false);
        expect(resultNoDummyNa.columnCount, equals(0)); // No categories, no NA column

        final resultDummyNa = dfOnlyNa.getDummies(['Col'], dummyNA: true);
        expect(resultDummyNa.columns, equals(['Col_na']));
        expect(resultDummyNa.column('Col_na').data, equals([1,1]));
        
        final resultDummyNaDropFirst = dfOnlyNa.getDummies(['Col'], dummyNA: true, dropFirst:true);
        // If NA is the only category, dropFirst will remove it.
        expect(resultDummyNaDropFirst.columnCount, equals(0));
      });

      test('Empty DataFrame (no rows)', () {
        final dfEmpty = DataFrame.fromNames(['Category', 'Value']);
        final result = dfEmpty.getDummies(['Category']);
        expect(result.rowCount, equals(0));
        // Columns should still be transformed: Value, Category_?, Category_??
        // This depends on whether unique values are derived from data or potential types.
        // Current implementation derives categories from data, so no dummy cols.
        expect(result.columns, equals(['Value'])); 
      });
      
      test('Empty DataFrame (no columns)', () {
        final dfEmptyCols = DataFrame.fromRows([{}, {}]);
        final result = dfEmptyCols.getDummies(null);
        expect(result.rowCount, equals(2));
        expect(result.columnCount, equals(0));
      });
    });
  });
}

