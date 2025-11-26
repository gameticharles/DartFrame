import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Advanced DataFrame Methods Demo ===\n');

  // ========== DATA INSPECTION ==========
  print('=== DATA INSPECTION ===\n');

  var df = DataFrame.fromMap({
    'A': ['1', '2', '3'],
    'B': [1.0, 2.0, 3.0],
    'C': ['true', 'false', 'true'],
  });

  print('Original DataFrame:');
  print(df);
  print('\n');

  // 1. dtypesSeries - Get column data types
  print('1. df.dtypesSeries:');
  print(df.dtypesSeries);
  print('\n');

  // 2. inferObjects - Infer better dtypes
  print('2. df.inferObjects():');
  var inferred = df.inferObjects();
  print(inferred);
  print('Dtypes after inference:');
  print(inferred.dtypesSeries);
  print('\n');

  // 3. convertDtypes - Convert to best dtypes
  print('3. df.convertDtypes():');
  var converted = df.convertDtypes();
  print(converted);
  print('Dtypes after conversion:');
  print(converted.dtypesSeries);
  print('\n');

  // ========== DATA ALIGNMENT ==========
  print('=== DATA ALIGNMENT ===\n');

  var df1 = DataFrame.fromMap({
    'A': [1, 2, 3, 4],
    'B': [10, 20, 30, 40],
  }, index: [
    'a',
    'b',
    'c',
    'd'
  ]);

  var df2 = DataFrame.fromMap({
    'X': [100, 200],
    'Y': [300, 400],
  }, index: [
    'a',
    'b'
  ]);

  print('DataFrame 1:');
  print(df1);
  print('\nDataFrame 2:');
  print(df2);
  print('\n');

  // 4. reindexLike - Match indices to another DataFrame
  print('4. df1.reindexLike(df2):');
  var reindexed = df1.reindexLike(df2);
  print(reindexed);
  print('\n');

  // Series reindexLike
  var s1 = Series([1, 2, 3, 4], name: 'data', index: ['a', 'b', 'c', 'd']);
  var s2 = Series([10, 20], name: 'other', index: ['a', 'b']);

  print('5. Series.reindexLike():');
  print('s1:');
  print(s1);
  print('\ns2:');
  print(s2);
  print('\ns1.reindexLike(s2):');
  var sReindexed = s1.reindexLike(s2);
  print(sReindexed);
  print('\n');

  // ========== MISSING DATA HANDLING ==========
  print('=== MISSING DATA HANDLING ===\n');

  var dfMissing = DataFrame.fromMap({
    'A': [1.0, null, null, 4.0, 5.0],
    'B': [10.0, 20.0, null, 40.0, 50.0],
    'C': [100.0, 200.0, 300.0, 400.0, 500.0],
  });

  print('DataFrame with missing values:');
  print(dfMissing);
  print('\n');

  // 6. Note: interpolate already exists in DartFrame
  print('6. Interpolation (using existing method):');
  var interpolated = dfMissing.interpolate();
  print(interpolated);
  print('\n');

  // 7. dropnaEnhanced - Drop rows with thresh parameter
  var dfDrop = DataFrame.fromMap({
    'A': [1, null, 3, null],
    'B': [4, 5, null, 7],
    'C': [8, 9, 10, 11],
  });

  print('7. dropnaEnhanced with thresh:');
  print('Original:');
  print(dfDrop);
  print('\nDrop rows with less than 2 non-NA values:');
  var dropped = dfDrop.dropnaEnhanced(thresh: 2);
  print(dropped);
  print('\n');

  // 8. dropnaEnhanced with subset
  print('8. dropnaEnhanced with subset:');
  print('Drop rows with NA in columns A and B only:');
  var droppedSubset = dfDrop.dropnaEnhanced(subset: ['A', 'B']);
  print(droppedSubset);
  print('\n');

  // 9. fillnaEnhanced - Fill from another DataFrame
  var dfFill = DataFrame.fromMap({
    'A': [1, null, 3],
    'B': [4, 5, null],
  });

  var dfOther = DataFrame.fromMap({
    'A': [10, 20, 30],
    'B': [40, 50, 60],
  });

  print('9. fillnaEnhanced with other DataFrame:');
  print('Original:');
  print(dfFill);
  print('\nFill from:');
  print(dfOther);
  print('\nResult:');
  var filled = dfFill.fillnaEnhanced(other: dfOther);
  print(filled);
  print('\n');

  // 10. fillnaEnhanced with method and limit
  print('10. fillnaEnhanced with method and limit:');
  var dfFillMethod = DataFrame.fromMap({
    'A': [1.0, null, null, null, 5.0],
    'B': [10.0, null, null, 40.0, 50.0],
  });

  print('Original:');
  print(dfFillMethod);
  print('\nForward fill with limit=2:');
  var filledLimit = dfFillMethod.fillnaEnhanced(method: 'ffill', limit: 2);
  print(filledLimit);
  print('\n');

  // ========== PRACTICAL EXAMPLES ==========
  print('=== PRACTICAL EXAMPLES ===\n');

  // Example 1: Data type conversion pipeline
  print('Example 1: Data type conversion pipeline');
  var rawData = DataFrame.fromMap({
    'id': ['1', '2', '3'],
    'value': ['10.5', '20.3', '30.1'],
    'active': ['true', 'false', 'true'],
  });

  print('Raw data (all strings):');
  print(rawData);
  print('Dtypes:');
  print(rawData.dtypesSeries);

  var processed = rawData.inferObjects().convertDtypes();
  print('\nAfter inference and conversion:');
  print(processed);
  print('Dtypes:');
  print(processed.dtypesSeries);
  print('\n');

  // Example 2: Missing data cleaning workflow
  print('Example 2: Missing data cleaning workflow');
  var messyData = DataFrame.fromMap({
    'temperature': [20.0, null, null, 23.0, 24.0, null, 26.0],
    'humidity': [60.0, 62.0, null, null, 65.0, 66.0, 67.0],
    'pressure': [1013.0, 1014.0, 1015.0, 1016.0, 1017.0, 1018.0, 1019.0],
  });

  print('Messy data:');
  print(messyData);

  print('\nStep 1: Interpolate missing values');
  var cleaned = messyData.interpolate();
  print(cleaned);

  print('\nStep 2: Drop rows with any remaining NA');
  var finalCleaned = cleaned.dropnaEnhanced();
  print(finalCleaned);
  print('\n');

  // Example 3: Aligning data from different sources
  print('Example 3: Aligning data from different sources');
  var sales = DataFrame.fromMap({
    'Q1': [100, 200, 300],
    'Q2': [150, 250, 350],
  }, index: [
    'Product A',
    'Product B',
    'Product C'
  ]);

  var costs = DataFrame.fromMap({
    'Q1': [50, 100],
    'Q2': [60, 110],
  }, index: [
    'Product A',
    'Product B'
  ]);

  print('Sales data:');
  print(sales);
  print('\nCosts data:');
  print(costs);

  print('\nAlign costs to match sales structure:');
  var alignedCosts = costs.reindexLike(sales, fillValue: 0);
  print(alignedCosts);
  print('\n');

  print('=== Demo Complete ===');
}
