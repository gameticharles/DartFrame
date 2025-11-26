import 'package:dartframe/dartframe.dart';

void main() {
  print('=== DataFrame New Methods Demo ===\n');

  // Create sample DataFrame
  var df = DataFrame.fromMap({
    'A': [1, 2, 3, 4, 5],
    'B': [10.5, 20.3, 30.1, 40.8, 50.2],
    'C': ['apple', 'banana', 'cherry', 'date', 'elderberry'],
    'D': [true, false, true, false, true],
  });

  print('Original DataFrame:');
  print(df);
  print('\n');

  // 1. DataFrame.info() - Print concise summary
  print('1. DataFrame.info():');
  df.info();
  print('\n');

  // 2. DataFrame.describeDataFrame() - Descriptive statistics
  print('2. DataFrame.describeDataFrame():');
  var stats = df.describeDataFrame();
  print(stats);
  print('\n');

  // 3. DataFrame.memoryUsageDetailed() - Memory usage per column
  print('3. DataFrame.memoryUsageDetailed():');
  var mem = df.memoryUsageDetailed();
  print(mem);
  print('\n');

  // 4. DataFrame.selectDtypes() - Select columns by type
  print('4. DataFrame.selectDtypes(include: [\'num\']):');
  var numericDf = df.selectDtypes(include: ['num']);
  print(numericDf);
  print('\n');

  // 5. DataFrame.reindex() - Conform to new index
  print('5. DataFrame.reindex():');
  var reindexed = df.reindex(index: [0, 1, 2, 3, 4, 5, 6], fillValue: 0);
  print(reindexed);
  print('\n');

  // 6. DataFrame.align() - Align two DataFrames
  print('6. DataFrame.align():');
  var df2 = DataFrame.fromMap({
    'A': [100, 200],
    'E': [1.1, 2.2],
  }, index: [
    3,
    4
  ]);

  var aligned = df.align(df2, join: 'outer', fillValue: 0);
  print('Aligned df1:');
  print(aligned[0]);
  print('\nAligned df2:');
  print(aligned[1]);
  print('\n');

  // 7. DataFrame.where() - Conditional replacement
  print('7. DataFrame.where():');
  var dfNum = DataFrame.fromMap({
    'X': [1, 2, 3, 4, 5],
    'Y': [10, 20, 30, 40, 50],
  });
  // Create boolean condition
  var cond = DataFrame.fromMap({
    'X': [false, false, false, true, true],
    'Y': [false, false, true, true, true],
  });
  var whereResult = dfNum.where(cond, other: 0);
  print(whereResult);
  print('\n');

  // 8. DataFrame.mask() - Inverse of where
  print('8. DataFrame.mask():');
  var maskResult = dfNum.mask(cond, other: 999);
  print(maskResult);
  print('\n');

  // 9. DataFrame.assign() - Assign new columns
  print('9. DataFrame.assign():');
  var assigned = dfNum.assign({
    'Z': [100, 200, 300, 400, 500],
    'Constant': 42, // Scalar broadcast
  });
  print(assigned);
  print('\n');

  // 10. DataFrame.insert() - Insert column at position
  print('10. DataFrame.insert():');
  var dfInsert = dfNum.copy();
  dfInsert.insert(1, 'Middle', value: [5, 6, 7, 8, 9]);
  print(dfInsert);
  print('\n');

  // 11. DataFrame.pop() - Remove and return column
  print('11. DataFrame.pop():');
  var dfPop = dfNum.copy();
  var popped = dfPop.pop('Y');
  print('Popped column:');
  print(popped);
  print('\nRemaining DataFrame:');
  print(dfPop);
  print('\n');

  print('=== Series New Methods Demo ===\n');

  // Create sample Series
  var s = Series([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], name: 'numbers');

  // 12. Series.describeSeries() - Descriptive statistics
  print('12. Series.describeSeries():');
  var seriesStats = s.describeSeries();
  print(seriesStats);
  print('\n');

  // 13. Series.info() - Print summary
  print('13. Series.info():');
  s.info();
  print('\n');

  // 14. Series.hasnans - Check for missing values
  print('14. Series.hasnans:');
  var sWithNulls = Series([1, null, 3, 4], name: 'data');
  print('Series with nulls has NaNs: ${sWithNulls.hasnans}');
  print('Series without nulls has NaNs: ${s.hasnans}');
  print('\n');

  // 15. Series.firstValidIndex() / lastValidIndex()
  print('15. Series.firstValidIndex() / lastValidIndex():');
  var sSparse = Series([null, null, 3, 4, 5, null],
      name: 'sparse', index: ['a', 'b', 'c', 'd', 'e', 'f']);
  print('First valid index: ${sSparse.firstValidIndex()}');
  print('Last valid index: ${sSparse.lastValidIndex()}');
  print('\n');

  // 16. Series.reindex() - Conform to new index
  print('16. Series.reindex():');
  var sReindexed = s.reindex(['a', 'b', 'c'], fillValue: 0);
  print(sReindexed);
  print('\n');

  // 17. Series.align() - Align two Series
  print('17. Series.align():');
  var s1 = Series([1, 2, 3], name: 'A', index: ['a', 'b', 'c']);
  var s2 = Series([4, 5, 6], name: 'B', index: ['b', 'c', 'd']);
  var alignedSeries = s1.align(s2, join: 'outer', fillValue: 0);
  print('Aligned s1:');
  print(alignedSeries[0]);
  print('\nAligned s2:');
  print(alignedSeries[1]);
  print('\n');

  // 18. Series.where() - Conditional replacement
  print('18. Series.where():');
  var sWhere = s.where(s > 5, other: 0);
  print(sWhere);
  print('\n');

  // 19. Series.mask() - Inverse of where
  print('19. Series.mask():');
  var sMask = s.mask(s > 5, other: 999);
  print(sMask);
  print('\n');

  // 20. Series.between() - Check if values are between bounds
  print('20. Series.between():');
  var sBetween = s.between(3, 7);
  print(sBetween);
  print('\n');

  // 21. Series.update() - Update from another Series
  print('21. Series.update():');
  var sUpdate = Series([1, 2, 3, 4], name: 'data', index: ['a', 'b', 'c', 'd']);
  var sUpdates = Series([null, 20, null, 40],
      name: 'updates', index: ['a', 'b', 'c', 'd']);
  sUpdate.update(sUpdates);
  print(sUpdate);
  print('\n');

  // 22. Series.combine() - Combine with function
  print('22. Series.combine():');
  var sCombine1 = Series([1, 2, 3], name: 'A', index: ['a', 'b', 'c']);
  var sCombine2 = Series([10, 20, 30], name: 'B', index: ['a', 'b', 'c']);
  var sCombined = sCombine1.combine(sCombine2, (a, b) => a * b);
  print(sCombined);
  print('\n');

  // 23. Series.combineFirst() - Fill nulls from another Series
  print('23. Series.combineFirst():');
  var sFirst = Series([1, null, 3], name: 'A', index: ['a', 'b', 'c']);
  var sSecond = Series([10, 20, 30], name: 'B', index: ['a', 'b', 'c']);
  var sCombineFirst = sFirst.combineFirst(sSecond);
  print(sCombineFirst);
  print('\n');

  print('=== Demo Complete ===');
}
