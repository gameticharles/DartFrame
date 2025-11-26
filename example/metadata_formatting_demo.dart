import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Metadata & Formatting Features Demo ===\n');

  // ========== DATAFRAME FEATURES ==========
  print('=== DATAFRAME FEATURES ===\n');

  // 1. attrs - Metadata storage
  print('1. attrs - Metadata storage:');
  var df = DataFrame.fromMap({
    'name': ['Alice', 'Bob', 'Charlie'],
    'age': [25, 30, 35],
    'salary': [50000.0, 60000.0, 70000.0],
  });

  df.attrs['source'] = 'HR Database';
  df.attrs['timestamp'] = DateTime.now();
  df.attrs['version'] = '1.0';

  print('DataFrame:');
  print(df);
  print('\nMetadata:');
  print('  source: ${df.attrs['source']}');
  print('  timestamp: ${df.attrs['timestamp']}');
  print('  version: ${df.attrs['version']}');
  print('\n');

  // 2. flags - DataFrame flags
  print('2. flags - DataFrame flags:');
  print('Current flags: ${df.flags}');
  var newDf = df.setFlags(allowsDuplicateLabels: false);
  print('New flags: ${newDf.flags}');
  print('\n');

  // 3. toStringEnhanced - Enhanced formatting
  print('3. toStringEnhanced - Enhanced formatting:');
  var largeDf = DataFrame.fromMap({
    'name': ['Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Frank', 'Grace'],
    'value': [1.23456, 2.34567, 3.45678, 4.56789, 5.67890, 6.78901, 7.89012],
    'count': [100, 200, 300, 400, 500, 600, 700],
  });

  print('With max rows and formatters:');
  print(largeDf.toStringEnhanced(
    maxRows: 4,
    formatters: {
      'value': (v) => v is num ? v.toStringAsFixed(2) : v.toString(),
    },
    showDtype: true,
  ));
  print('\n');

  // 4. squeeze - Squeeze to scalar/Series
  print('4. squeeze - Squeeze to scalar/Series:');

  var singleValue = DataFrame.fromMap({
    'A': [42]
  });
  print('Single value DataFrame:');
  print(singleValue);
  var squeezed = singleValue.squeeze();
  print('Squeezed: $squeezed (type: ${squeezed.runtimeType})');
  print('');

  var singleColumn = DataFrame.fromMap({
    'A': [1, 2, 3]
  });
  print('Single column DataFrame:');
  print(singleColumn);
  var squeezedCol = singleColumn.squeeze();
  print('Squeezed to Series:');
  print(squeezedCol);
  print('');

  var singleRow = DataFrame.fromMap({
    'A': [1],
    'B': [2],
    'C': [3]
  });
  print('Single row DataFrame:');
  print(singleRow);
  var squeezedRow = singleRow.squeeze();
  print('Squeezed to Series:');
  print(squeezedRow);
  print('\n');

  // ========== SERIES FEATURES ==========
  print('=== SERIES FEATURES ===\n');

  // 5. mapEnhanced - Enhanced map with na_action
  print('5. mapEnhanced - Enhanced map with na_action:');
  var s = Series([1, null, 3, null, 5], name: 'values');
  print('Original Series:');
  print(s);

  var mapped = s.map(
    (x) => x * 2,
    naAction: 'ignore',
  );
  print('\nMapped with na_action="ignore":');
  print(mapped);
  print('\n');

  // 6. replaceEnhanced - Enhanced replace with regex
  print('6. replaceEnhanced - Enhanced replace with regex:');
  var s2 = Series(['test123', 'test456', 'other', 'test789'], name: 'codes');
  print('Original Series:');
  print(s2);

  var replaced = s2.replaceEnhanced(
    toReplace: r'test\d+',
    value: 'replaced',
    regex: true,
  );
  print('\nReplaced with regex:');
  print(replaced);
  print('\n');

  // 7. repeatElements - Repeat elements
  print('7. repeatElements - Repeat elements:');
  var s3 = Series([1, 2, 3], name: 'numbers');
  print('Original Series:');
  print(s3);

  var repeated = s3.repeatElements(2);
  print('\nRepeated 2 times:');
  print(repeated);

  var repeated2 = s3.repeatElements([1, 2, 3]);
  print('\nRepeated [1, 2, 3] times:');
  print(repeated2);
  print('\n');

  // 8. squeeze - Squeeze Series
  print('8. squeeze - Squeeze Series:');
  var s4 = Series([42], name: 'single');
  print('Single element Series:');
  print(s4);
  var squeezedS = s4.squeeze();
  print('Squeezed: $squeezedS (type: ${squeezedS.runtimeType})');
  print('\n');

  // 9. dtypeEnhanced - Enhanced dtype inference
  print('9. dtypeEnhanced - Enhanced dtype inference:');
  var intSeries = Series([1, 2, 3], name: 'ints');
  print('Integer Series dtype: ${intSeries.dtypeEnhanced}');

  var doubleSeries = Series([1.5, 2.5, 3.5], name: 'doubles');
  print('Double Series dtype: ${doubleSeries.dtypeEnhanced}');

  var stringSeries = Series(['a', 'b', 'c'], name: 'strings');
  print('String Series dtype: ${stringSeries.dtypeEnhanced}');

  var dateSeries = Series([DateTime.now(), DateTime.now()], name: 'dates');
  print('DateTime Series dtype: ${dateSeries.dtypeEnhanced}');
  print('\n');

  // 10. attrs and flags for Series
  print('10. attrs and flags for Series:');
  var s5 = Series([1, 2, 3], name: 'data');
  s5.attrs['unit'] = 'meters';
  s5.attrs['sensor'] = 'sensor_1';
  print('Series metadata:');
  print('  unit: ${s5.attrs['unit']}');
  print('  sensor: ${s5.attrs['sensor']}');
  print('  flags: ${s5.flags}');
  print('\n');

  // 11. toStringEnhanced for Series
  print('11. toStringEnhanced for Series:');
  var s6 = Series(
    [1.23456, 2.34567, 3.45678, 4.56789, 5.67890, 6.78901, 7.89012],
    name: 'measurements',
  );

  print(s6.toStringEnhanced(
    maxRows: 4,
    formatter: (v) => v is num ? v.toStringAsFixed(2) : v.toString(),
    showDtype: true,
  ));
  print('\n');

  // ========== PRACTICAL EXAMPLES ==========
  print('=== PRACTICAL EXAMPLES ===\n');

  // Example 1: Data with metadata
  print('Example 1: Data with metadata');
  var sensorData = DataFrame.fromMap({
    'timestamp': [
      DateTime(2023, 1, 1, 10, 0),
      DateTime(2023, 1, 1, 10, 5),
      DateTime(2023, 1, 1, 10, 10),
    ],
    'temperature': [20.123, 21.456, 19.789],
    'humidity': [65.234, 70.567, 68.890],
  });

  sensorData.attrs['location'] = 'Room A';
  sensorData.attrs['device_id'] = 'SENSOR_001';
  sensorData.attrs['calibration_date'] = DateTime(2023, 1, 1);

  print('Sensor Data:');
  print(sensorData.toStringEnhanced(
    formatters: {
      'temperature': (v) =>
          v is num ? '${v.toStringAsFixed(1)}°C' : v.toString(),
      'humidity': (v) => v is num ? '${v.toStringAsFixed(1)}%' : v.toString(),
    },
  ));
  print('\nMetadata:');
  print('  Location: ${sensorData.attrs['location']}');
  print('  Device ID: ${sensorData.attrs['device_id']}');
  print('  Calibration: ${sensorData.attrs['calibration_date']}');
  print('\n');

  // Example 2: Data cleaning with enhanced replace
  print('Example 2: Data cleaning with enhanced replace');
  var rawData = Series([
    'ID_001',
    'ID_002',
    'invalid',
    'ID_003',
    'error',
    'ID_004',
  ], name: 'product_ids');

  print('Raw data:');
  print(rawData);

  var cleaned = rawData.replaceEnhanced(
    toReplace: r'^(?!ID_)',
    value: 'ID_UNKNOWN',
    regex: true,
  );

  print('\nCleaned data:');
  print(cleaned);
  print('\n');

  print('=== Demo Complete ===');
}
