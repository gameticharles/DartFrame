import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Advanced DataFrame Features Demo ===\n');

  // ========== MERGING & JOINING ADVANCED ==========
  print('=== MERGING & JOINING ADVANCED ===\n');

  // 1. joinMultiple - Join multiple DataFrames
  print('1. joinMultiple - Join multiple DataFrames:');
  var df1 = DataFrame.fromMap({
    'key': [1, 2, 3],
    'A': [10, 20, 30]
  });
  var df2 = DataFrame.fromMap({
    'key': [1, 2, 3],
    'B': [40, 50, 60]
  });
  var df3 = DataFrame.fromMap({
    'key': [1, 2, 3],
    'C': [70, 80, 90]
  });

  print('DataFrame 1:');
  print(df1);
  print('\nDataFrame 2:');
  print(df2);
  print('\nDataFrame 3:');
  print(df3);

  var joinedMultiple = df1.joinMultiple([df2, df3], on: 'key');
  print('\nJoined result:');
  print(joinedMultiple);
  print('\n');

  // 2. joinWithSuffix - Join with custom suffixes
  print('2. joinWithSuffix - Join with custom suffixes:');
  var leftSuffix = DataFrame.fromMap({
    'id': [1, 2, 3],
    'value': [100, 200, 300]
  });
  var rightSuffix = DataFrame.fromMap({
    'id': [1, 2, 3],
    'value': [150, 250, 350]
  });

  print('Left DataFrame:');
  print(leftSuffix);
  print('\nRight DataFrame:');
  print(rightSuffix);

  var joinedSuffix = leftSuffix.joinWithSuffix(
    rightSuffix,
    on: 'id',
    lsuffix: '_left',
    rsuffix: '_right',
  );
  print('\nJoined with suffixes:');
  print(joinedSuffix);
  print('\n');

  // ========== GROUPBY ADVANCED ==========
  print('=== GROUPBY ADVANCED ===\n');

  var dfGroup = DataFrame.fromMap({
    'category': ['A', 'B', 'A', 'B', 'A', 'B'],
    'value': [10, 20, 30, 40, 50, 60],
    'count': [1, 2, 3, 4, 5, 6],
  });

  print('DataFrame for grouping:');
  print(dfGroup);
  print('\n');

  // 3. groupByEnhanced - Enhanced groupby
  print('3. groupByEnhanced:');
  var grouped = dfGroup.groupBy('category', dropna: true);
  print('Groups: ${grouped.keys.toList()}');
  for (var key in grouped.keys) {
    print('\nGroup $key:');
    print(grouped[key]);
  }
  print('\n');

  // 4. rollingEnhanced - Enhanced rolling with center parameter
  print('4. rollingEnhanced with center:');
  var dfRoll = DataFrame.fromMap({
    'A': [1, 2, 3, 4, 5, 6, 7],
    'B': [10, 20, 30, 40, 50, 60, 70],
  });

  print('Original data:');
  print(dfRoll);

  var rolling = dfRoll.rollingWindow(3, center: true);
  var rollingMean = rolling.mean();
  print('\nRolling mean (centered, window=3):');
  print(rollingMean);
  print('\n');

  // 5. expandingEnhanced - Enhanced expanding window
  print('5. expandingEnhanced:');
  var expanding = dfRoll.expanding(minPeriods: 2);
  var expandingSum = expanding.sum();
  print('Expanding sum (minPeriods=2):');
  print(expandingSum);
  print('\n');

  // 6. ewmEnhanced - Enhanced exponentially weighted functions
  print('6. ewmEnhanced:');
  var ewm = dfRoll.ewm(span: 3, adjustWeights: true);
  var ewmMean = ewm.mean();
  print('Exponentially weighted mean (span=3):');
  print(ewmMean);
  print('\n');

  // ========== TIME SERIES ADVANCED ==========
  print('=== TIME SERIES ADVANCED ===\n');

  var dfTime = DataFrame.fromMap({
    'temperature': [20.1, 21.5, 19.8, 22.3, 23.1],
    'humidity': [65, 70, 68, 72, 75],
  }, index: [
    DateTime(2023, 1, 1, 12, 0),
    DateTime(2023, 1, 2, 12, 0),
    DateTime(2023, 1, 3, 12, 0),
    DateTime(2023, 1, 4, 12, 0),
    DateTime(2023, 1, 5, 12, 0),
  ]);

  print('Time series DataFrame:');
  print(dfTime);
  print('\n');

  // 7. inferFreq - Infer frequency
  print('7. inferFreq:');
  var freq = dfTime.inferFreq();
  print('Inferred frequency: $freq (D = Daily)');
  print('\n');

  // 8. tzLocalize - Localize to timezone (using existing method)
  print('8. tzLocalize (existing method):');
  var localized = dfTime.tzLocalize('UTC');
  print('Localized to UTC:');
  print(localized);
  print('\n');

  // 9. tzConvert - Convert timezone (using existing method)
  print('9. tzConvert (existing method):');
  var converted = localized.tzConvert('America/New_York');
  print('Converted timezone:');
  print(converted);
  print('\n');

  // 10. toPeriod - Convert to periods
  print('10. toPeriod:');
  var periods = dfTime.toPeriod('D');
  print('As daily periods:');
  print(periods);
  print('\n');

  // 11. toTimestamp - Convert periods to timestamps
  print('11. toTimestamp:');
  var dfPeriods = DataFrame.fromMap({
    'sales': [100, 110, 105],
  }, index: [
    '2023-01',
    '2023-02',
    '2023-03'
  ]);

  print('Period DataFrame (monthly):');
  print(dfPeriods);

  var timestamps = dfPeriods.toTimestamp('M', how: 'start');
  print('\nConverted to timestamps (start of month):');
  print(timestamps);
  print('\n');

  // 12. normalize - Normalize to midnight
  print('12. normalize:');
  var dfNorm = DataFrame.fromMap({
    'value': [1, 2, 3],
  }, index: [
    DateTime(2023, 1, 1, 14, 30),
    DateTime(2023, 1, 2, 9, 15),
    DateTime(2023, 1, 3, 18, 45),
  ]);

  print('Original with times:');
  print(dfNorm);

  var normalized = dfNorm.normalize();
  print('\nNormalized to midnight:');
  print(normalized);
  print('\n');

  // ========== PRACTICAL EXAMPLES ==========
  print('=== PRACTICAL EXAMPLES ===\n');

  // Example 1: Multi-source data joining
  print('Example 1: Multi-source business data joining');
  var sales = DataFrame.fromMap({
    'id': [1, 2, 3],
    'sales': [1000, 2000, 3000]
  });
  var costs = DataFrame.fromMap({
    'id': [1, 2, 3],
    'costs': [500, 800, 1200]
  });
  var profits = DataFrame.fromMap({
    'id': [1, 2, 3],
    'margin': [50, 120, 180]
  });

  var business = sales.joinMultiple(
    [costs, profits],
    on: 'id',
  );
  print(business);
  print('\n');

  // Example 2: Time series analysis with rolling windows
  print('Example 2: Temperature analysis with rolling windows');
  var tempData = DataFrame.fromMap({
    'temp': [20.1, 21.5, 19.8, 22.3, 23.1, 21.9, 20.5, 22.0],
  }, index: [
    DateTime(2023, 1, 1),
    DateTime(2023, 1, 2),
    DateTime(2023, 1, 3),
    DateTime(2023, 1, 4),
    DateTime(2023, 1, 5),
    DateTime(2023, 1, 6),
    DateTime(2023, 1, 7),
    DateTime(2023, 1, 8),
  ]);

  print('Temperature data:');
  print(tempData);

  print('\nInferred frequency: ${tempData.inferFreq()}');

  var rollingTemp = tempData.rollingWindow(3, center: true);
  var smoothed = rollingTemp.mean();
  print('\nSmoothed (3-day centered average):');
  print(smoothed);

  var ewmTemp = tempData.ewm(span: 3);
  var ewmSmoothed = ewmTemp.mean();
  print('\nExponentially weighted mean (span=3):');
  print(ewmSmoothed);
  print('\n');

  // Example 3: Period conversion
  print('Example 3: Period conversion for quarterly data');
  var quarterly = DataFrame.fromMap({
    'revenue': [100, 120, 110, 130],
  }, index: [
    '2023Q1',
    '2023Q2',
    '2023Q3',
    '2023Q4'
  ]);

  print('Quarterly data:');
  print(quarterly);

  var quarterTimestamps = quarterly.toTimestamp('Q', how: 'start');
  print('\nConverted to timestamps (start of quarter):');
  print(quarterTimestamps);
  print('\n');

  print('=== Demo Complete ===');
  print('\nAll advanced features demonstrated successfully!');
}
