import 'package:dartframe/dartframe.dart';

void main() {
  print('=== SQL-Style Window Ranking Functions Examples ===\n');

  // Example 1: Basic Ranking
  print('1. Basic Ranking with Different Methods:');
  var salesData = DataFrame([
    ['Alice', 100],
    ['Bob', 150],
    ['Charlie', 100],
    ['David', 200],
    ['Eve', 150],
  ], columns: [
    'Name',
    'Sales'
  ]);

  print('\nOriginal Data:');
  print(salesData);

  // Average ranking (default)
  var avgRanked = salesData.rankWindow(columns: ['Sales'], method: 'average');
  print('\nAverage Ranking:');
  print(avgRanked);

  // Min ranking
  var minRanked = salesData.rankWindow(columns: ['Sales'], method: 'min');
  print('\nMin Ranking:');
  print(minRanked);

  // Dense ranking
  var denseRanked = salesData.denseRank(columns: ['Sales']);
  print('\nDense Ranking:');
  print(denseRanked);

  // Example 2: Row Numbers
  print('\n2. Row Numbers:');
  var employees = DataFrame([
    ['Engineering', 'Alice', 90000],
    ['Engineering', 'Bob', 95000],
    ['Sales', 'Charlie', 80000],
    ['Sales', 'David', 85000],
  ], columns: [
    'Department',
    'Name',
    'Salary'
  ]);

  var numbered = employees.rowNumber();
  print(numbered);

  // Example 3: Percent Rank
  print('\n3. Percent Rank (Percentile):');
  var scores = DataFrame([
    [85],
    [90],
    [75],
    [95],
    [80],
  ], columns: [
    'Score'
  ]);

  var pctRank = scores.percentRank(columns: ['Score']);
  print(pctRank);

  // Example 4: Cumulative Distribution
  print('\n4. Cumulative Distribution:');
  var values = DataFrame([
    [10],
    [20],
    [20],
    [30],
    [40],
  ], columns: [
    'Value'
  ]);

  var cumeDist = values.cumulativeDistribution(columns: ['Value']);
  print(cumeDist);

  // Example 5: Descending Ranking
  print('\n5. Descending Ranking (Highest First):');
  var rankings = DataFrame([
    ['Product A', 500],
    ['Product B', 750],
    ['Product C', 500],
    ['Product D', 1000],
  ], columns: [
    'Product',
    'Revenue'
  ]);

  var descRanked = rankings.rankWindow(columns: ['Revenue'], ascending: false);
  print(descRanked);

  // Example 6: Percentile Ranks
  print('\n6. Percentile Ranks (0 to 1):');
  var testScores = DataFrame([
    [60],
    [70],
    [80],
    [90],
    [100],
  ], columns: [
    'Score'
  ]);

  var pctRanks = testScores.rankWindow(columns: ['Score'], pct: true);
  print(pctRanks);

  // Example 7: Multiple Column Ranking
  print('\n7. Ranking Multiple Columns:');
  var multiData = DataFrame([
    [100, 50],
    [200, 50],
    [100, 75],
    [300, 100],
  ], columns: [
    'Sales',
    'Profit'
  ]);

  var multiRanked = multiData.rankWindow(columns: ['Sales', 'Profit']);
  print(multiRanked);

  print('\n=== Window Ranking Examples Complete ===');
}
