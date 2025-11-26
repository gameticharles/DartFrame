import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Sorting & Aggregation Enhancements Demo ===\n');

  // ========== SORTING ENHANCEMENTS ==========
  print('=== SORTING ENHANCEMENTS ===\n');

  var df = DataFrame.fromMap({
    'Name': ['Alice', 'bob', 'Charlie', 'david'],
    'Age': [25, 30, 35, 28],
    'Score': [85.5, 92.3, 78.9, 88.1],
  });

  print('Original DataFrame:');
  print(df);
  print('\n');

  // 1. Sort with key function (case-insensitive)
  print('1. sortValuesEnhanced with key function:');
  var sorted1 = df.sortValuesEnhanced(
    by: 'Name',
    key: (value) => value.toString().toLowerCase(),
  );
  print(sorted1);
  print('\n');

  // 2. Sort with ignoreIndex
  print('2. sortValuesEnhanced with ignoreIndex:');
  var sorted2 = df.sortValuesEnhanced(
    by: 'Age',
    ignoreIndex: true,
  );
  print(sorted2);
  print('\n');

  // 3. Sort with stable algorithm
  print('3. sortValuesEnhanced with stable sort:');
  var sorted3 = df.sortValuesEnhanced(
    by: 'Score',
    kind: 'stable',
    ascending: false,
  );
  print(sorted3);
  print('\n');

  // 4. Sort index with key function
  var dfIndex = DataFrame.fromMap({
    'A': [1, 2, 3],
    'B': [4, 5, 6],
  }, index: [
    'C',
    'a',
    'B'
  ]);

  print('4. sortIndexEnhanced with key function:');
  print('Original:');
  print(dfIndex);
  print('\nSorted (case-insensitive):');
  var sortedIndex = dfIndex.sortIndexEnhanced(
    key: (idx) => idx.toString().toLowerCase(),
  );
  print(sortedIndex);
  print('\n');

  // 5. Sort columns
  var dfCols = DataFrame.fromMap({
    'Z': [1, 2, 3],
    'A': [4, 5, 6],
    'M': [7, 8, 9],
  });

  print('5. sortIndexEnhanced on columns (axis=1):');
  print('Original:');
  print(dfCols);
  print('\nSorted columns:');
  var sortedCols = dfCols.sortIndexEnhanced(axis: 1);
  print(sortedCols);
  print('\n');

  // ========== AGGREGATION ENHANCEMENTS ==========
  print('=== AGGREGATION ENHANCEMENTS ===\n');

  var dfAgg = DataFrame.fromMap({
    'A': [1, 2, 3, 4, 5],
    'B': [10, 20, 30, 40, 50],
    'C': [100, 200, 300, 400, 500],
  });

  print('DataFrame for aggregation:');
  print(dfAgg);
  print('\n');

  // 6. aggEnhanced with different functions per column
  print('6. aggEnhanced with different functions per column:');
  var agg1 = dfAgg.aggEnhanced({
    'A': ['sum', 'mean', 'std'],
    'B': ['min', 'max'],
    'C': ['median'],
  });
  print(agg1);
  print('\n');

  // 7. aggEnhanced with multiple functions for all columns
  print('7. aggEnhanced with multiple functions:');
  var agg2 = dfAgg.aggEnhanced(['sum', 'mean', 'std']);
  print(agg2);
  print('\n');

  // 8. prod() - Product of values
  print('8. prod() - Product of values:');
  var products = dfAgg.prod();
  print(products);
  print('\n');

  // 9. sem() - Standard error of mean
  print('9. sem() - Standard error of mean:');
  var semValues = dfAgg.sem();
  print(semValues);
  print('\n');

  // 10. mad() - Mean absolute deviation
  print('10. mad() - Mean absolute deviation:');
  var madValues = dfAgg.mad();
  print(madValues);
  print('\n');

  // 11. nunique() - Count unique values per column
  var dfUnique = DataFrame.fromMap({
    'A': [1, 1, 2, 3, 3, 3],
    'B': ['a', 'a', 'b', 'c', 'c', 'd'],
    'C': [10, 10, 10, 20, 20, 30],
  });

  print('11. nunique() - Count unique values:');
  print('DataFrame:');
  print(dfUnique);
  print('\nUnique counts:');
  var uniqueCounts = dfUnique.nunique();
  print(uniqueCounts);
  print('\n');

  // 12. valueCountsDataFrame() - Count unique rows
  var dfRows = DataFrame.fromMap({
    'A': [1, 1, 2, 2, 1],
    'B': ['x', 'x', 'y', 'y', 'x'],
  });

  print('12. valueCountsDataFrame() - Count unique rows:');
  print('DataFrame:');
  print(dfRows);
  print('\nRow counts:');
  var rowCounts = dfRows.valueCountsDataFrame();
  print(rowCounts);
  print('\n');

  // ========== PRACTICAL EXAMPLES ==========
  print('=== PRACTICAL EXAMPLES ===\n');

  // Example 1: Case-insensitive sorting
  print('Example 1: Case-insensitive name sorting');
  var people = DataFrame.fromMap({
    'Name': ['Alice', 'bob', 'Charlie', 'DAVID', 'eve'],
    'Salary': [50000, 60000, 55000, 65000, 52000],
  });

  print('Original:');
  print(people);
  print('\nSorted by name (case-insensitive):');
  var sortedPeople = people.sortValuesEnhanced(
    by: 'Name',
    key: (v) => v.toString().toLowerCase(),
  );
  print(sortedPeople);
  print('\n');

  // Example 2: Comprehensive statistics
  print('Example 2: Comprehensive statistics');
  var sales = DataFrame.fromMap({
    'Q1': [100, 150, 200, 180, 220],
    'Q2': [120, 160, 210, 190, 230],
    'Q3': [110, 155, 205, 185, 225],
    'Q4': [130, 165, 215, 195, 235],
  });

  print('Sales data:');
  print(sales);
  print('\nComprehensive statistics:');
  var stats =
      sales.aggEnhanced(['sum', 'mean', 'std', 'min', 'max', 'sem', 'mad']);
  print(stats);
  print('\n');

  // Example 3: Product calculations
  print('Example 3: Product calculations');
  var factors = DataFrame.fromMap({
    'Factor1': [1.1, 1.2, 1.3],
    'Factor2': [2.0, 2.5, 3.0],
    'Factor3': [0.9, 0.95, 1.0],
  });

  print('Factors:');
  print(factors);
  print('\nProducts:');
  var factorProducts = factors.prod();
  print(factorProducts);
  print('\n');

  // Example 4: Data quality check
  print('Example 4: Data quality check');
  var data = DataFrame.fromMap({
    'ID': [1, 1, 2, 3, 3, 3, 4],
    'Category': ['A', 'A', 'B', 'C', 'C', 'C', 'D'],
    'Value': [10, 10, 20, 30, 30, 30, 40],
  });

  print('Data:');
  print(data);
  print('\nUnique value counts per column:');
  var uniqueness = data.nunique();
  print(uniqueness);
  print('\nDuplicate row analysis:');
  var duplicates = data.valueCountsDataFrame(sort: true, ascending: false);
  print(duplicates);
  print('\n');

  print('=== Demo Complete ===');
}
