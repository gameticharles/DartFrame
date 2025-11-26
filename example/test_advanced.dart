import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Testing Advanced Methods ===\n');

  // Test inferFreq
  var df = DataFrame.fromMap({
    'value': [1, 2, 3],
  }, index: [
    DateTime(2023, 1, 1),
    DateTime(2023, 1, 2),
    DateTime(2023, 1, 3),
  ]);

  print('DataFrame with DateTime index:');
  print(df);

  try {
    var freq = df.inferFreq();
    print('\nInferred frequency: $freq');
  } catch (e) {
    print('\nError calling inferFreq: $e');
  }

  // Test mergeOrdered
  var left = DataFrame.fromMap({
    'time': [1, 3, 5],
    'value': [10, 30, 50],
  });

  var right = DataFrame.fromMap({
    'time': [2, 4, 6],
    'price': [20, 40, 60],
  });

  try {
    var merged = left.mergeOrdered(right, on: 'time', fillMethod: 'ffill');
    print('\nMerged DataFrame:');
    print(merged);
  } catch (e) {
    print('\nError calling mergeOrdered: $e');
  }

  print('\n=== Test Complete ===');
}
