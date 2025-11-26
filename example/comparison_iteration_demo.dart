import 'package:dartframe/dartframe.dart';

void main() {
  print('=== DataFrame Comparison, Iteration & Missing Data Demo ===\n');

  // Create sample DataFrames
  var df1 = DataFrame.fromMap({
    'A': [1, 2, 3, 4],
    'B': [10, 20, 30, 40],
    'C': ['a', 'b', 'c', 'd'],
  });

  var df2 = DataFrame.fromMap({
    'A': [1, 2, 9, 4],
    'B': [10, 25, 30, 40],
    'C': ['a', 'b', 'c', 'd'],
  });

  print('DataFrame 1:');
  print(df1);
  print('\nDataFrame 2:');
  print(df2);
  print('\n');

  // ========== COMPARISON METHODS ==========

  print('=== COMPARISON METHODS ===\n');

  // 1. equals() - Test equality
  print('1. df1.equals(df2):');
  print(df1.equals(df2)); // false
  print('\n');

  print('df1.equals(df1):');
  print(df1.equals(df1)); // true
  print('\n');

  // 2. compare() - Show differences
  print('2. df1.compare(df2):');
  var diff = df1.compare(df2);
  print(diff);
  print('\n');

  // 3. eq() - Element-wise equality
  print('3. df1.eq(2):');
  var eqResult = df1.eq(2);
  print(eqResult);
  print('\n');

  // 4. ne() - Element-wise not-equal
  print('4. df1.ne(2):');
  var neResult = df1.ne(2);
  print(neResult);
  print('\n');

  // 5. lt() - Element-wise less-than
  print('5. df1.lt(3):');
  var ltResult = df1.lt(3);
  print(ltResult);
  print('\n');

  // 6. gt() - Element-wise greater-than
  print('6. df1.gt(2):');
  var gtResult = df1.gt(2);
  print(gtResult);
  print('\n');

  // 7. le() - Element-wise less-than-or-equal
  print('7. df1.le(2):');
  var leResult = df1.le(2);
  print(leResult);
  print('\n');

  // 8. ge() - Element-wise greater-than-or-equal
  print('8. df1.ge(3):');
  var geResult = df1.ge(3);
  print(geResult);
  print('\n');

  // ========== ITERATION METHODS ==========

  print('=== ITERATION METHODS ===\n');

  // 9. iterrows() - Iterate over rows
  print('9. df1.iterrows():');
  var rowCount = 0;
  for (var row in df1.iterrows()) {
    print('  Index: ${row.key}');
    print('  Data: ${row.value.data}');
    rowCount++;
    if (rowCount >= 2) break; // Show only first 2 rows
  }
  print('  ... (${df1.rowCount - 2} more rows)\n');

  // 10. itertuples() - Iterate as named tuples
  print('10. df1.itertuples():');
  var tupleCount = 0;
  for (var row in df1.itertuples()) {
    print('  $row');
    tupleCount++;
    if (tupleCount >= 2) break; // Show only first 2 rows
  }
  print('  ... (${df1.rowCount - 2} more rows)\n');

  // 11. items() - Iterate over columns
  print('11. df1.items():');
  for (var item in df1.items()) {
    print('  Column: ${item.key}');
    print('  Data: ${item.value.data}');
  }
  print('\n');

  // 12. keys() - Get column names
  print('12. df1.keys():');
  print(df1.keys());
  print('\n');

  // 13. values - Get data as list
  print('13. df1.values:');
  print(df1.values);
  print('\n');

  // ========== MISSING DATA METHODS ==========

  print('=== MISSING DATA METHODS ===\n');

  // Create DataFrame with missing values
  var dfMissing = DataFrame.fromMap({
    'A': [1, null, 3, null, 5],
    'B': [10, 20, null, 40, 50],
    'C': ['a', 'b', 'c', null, 'e'],
  });

  print('DataFrame with missing values:');
  print(dfMissing);
  print('\n');

  // 14. isna() - Detect missing values
  print('14. dfMissing.isna():');
  var isnaResult = dfMissing.isna();
  print(isnaResult);
  print('\n');

  // 15. notna() - Detect non-missing values
  print('15. dfMissing.notna():');
  var notnaResult = dfMissing.notna();
  print(notnaResult);
  print('\n');

  // 16. isnaCounts() - Count missing values per column
  print('16. dfMissing.isnaCounts():');
  var counts = dfMissing.isnaCounts();
  print(counts);
  print('\n');

  // 17. isnaPercentage() - Percentage of missing values
  print('17. dfMissing.isnaPercentage():');
  var percentages = dfMissing.isnaPercentage();
  print(percentages);
  print('\n');

  // 18. hasna() - Check if column has any missing values
  print('18. dfMissing.hasna():');
  var hasna = dfMissing.hasna();
  print(hasna);
  print('\n');

  // ========== SERIES COMPARISON & ITERATION ==========

  print('=== SERIES COMPARISON & ITERATION ===\n');

  var s1 =
      Series([1, 2, 3, 4, 5], name: 'data', index: ['a', 'b', 'c', 'd', 'e']);
  var s2 =
      Series([1, 2, 9, 4, 5], name: 'data', index: ['a', 'b', 'c', 'd', 'e']);

  print('Series 1:');
  print(s1);
  print('\nSeries 2:');
  print(s2);
  print('\n');

  // 19. Series.equals()
  print('19. s1.equals(s2):');
  print(s1.equals(s2)); // false
  print('\n');

  // 20. Series.compare()
  print('20. s1.compare(s2):');
  var seriesDiff = s1.compare(s2);
  print(seriesDiff);
  print('\n');

  // 21. Series.items()
  print('21. s1.items():');
  var itemCount = 0;
  for (var item in s1.items()) {
    print('  Index: ${item.key}, Value: ${item.value}');
    itemCount++;
    if (itemCount >= 3) break; // Show only first 3
  }
  print('  ... (${s1.length - 3} more items)\n');

  // 22. Series.keys()
  print('22. s1.keys():');
  print(s1.keys());
  print('\n');

  // 23. Series.values
  print('23. s1.values:');
  print(s1.values);
  print('\n');

  // ========== PRACTICAL EXAMPLES ==========

  print('=== PRACTICAL EXAMPLES ===\n');

  // Example 1: Find rows where values differ
  print('Example 1: Find rows where DataFrames differ');
  var differences = df1.compare(df2);
  print('Differences found at ${differences.rowCount} positions:');
  print(differences);
  print('\n');

  // Example 2: Filter using comparison
  print('Example 2: Filter rows where A > 2');
  var gtMask = df1.gt(DataFrame.fromMap({
    'A': [2, 2, 2, 2],
    'B': [2, 2, 2, 2],
    'C': ['', '', '', '']
  }));
  print('Comparison result:');
  print(gtMask);
  print('\n');

  // Example 3: Process each row
  print('Example 3: Calculate row sums');
  for (var row in df1.iterrows()) {
    var aVal = row.value.data[0]; // A is first column
    var bVal = row.value.data[1]; // B is second column
    if (aVal is num && bVal is num) {
      var sum = aVal + bVal;
      print('Row ${row.key}: A + B = $sum');
    }
  }
  print('\n');

  // Example 4: Missing data analysis
  print('Example 4: Missing data summary');
  print('Total missing values per column:');
  print(dfMissing.isnaCounts());
  print('\nPercentage missing:');
  print(dfMissing.isnaPercentage());
  print('\nColumns with missing data:');
  var colsWithMissing = dfMissing.hasna();
  for (var item in colsWithMissing.items()) {
    if (item.value == true) {
      print('  ${item.key}');
    }
  }
  print('\n');

  print('=== Demo Complete ===');
}
