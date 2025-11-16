import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Series clip() Example ===\n');

  // Create sample Series with some extreme values
  var s = Series([1, 2, 3, 4, 5, 10, 15, 20], name: 'values');

  print('Original Series:');
  print(s);
  print('\n');

  // Clip with both bounds
  print('Clip values between 3 and 12:');
  var clipped = s.clip(lower: 3, upper: 12);
  print(clipped);
  print('Data: ${clipped.data}');
  print('\n');

  // Clip only lower bound
  print('Clip with minimum of 5:');
  var clippedLower = s.clip(lower: 5);
  print(clippedLower);
  print('Data: ${clippedLower.data}');
  print('\n');

  // Clip only upper bound
  print('Clip with maximum of 8:');
  var clippedUpper = s.clip(upper: 8);
  print(clippedUpper);
  print('Data: ${clippedUpper.data}');
  print('\n');

  // Example with negative values
  print('=== Handling Negative Values ===');
  var negSeries = Series([-10, -5, 0, 5, 10], name: 'temperatures');
  print('Original temperatures:');
  print('Data: ${negSeries.data}');
  print('\n');

  print('Clip to range [-3, 7]:');
  var clippedTemp = negSeries.clip(lower: -3, upper: 7);
  print('Data: ${clippedTemp.data}');
  print('\n');

  // Example with decimal values
  print('=== Decimal Values ===');
  var prices = Series([9.99, 12.50, 15.75, 20.00, 25.50], name: 'prices');
  print('Original prices:');
  print('Data: ${prices.data}');
  print('\n');

  print('Clip to range [10.00, 20.00]:');
  var clippedPrices = prices.clip(lower: 10.00, upper: 20.00);
  print('Data: ${clippedPrices.data}');
  print('\n');

  // Method chaining example
  print('=== Method Chaining ===');
  var data = Series([-15, -10, -5, 5, 10, 15], name: 'data');
  print('Original data:');
  print('Data: ${data.data}');
  print('\n');

  print('Chain: clip(-8, 8) -> abs():');
  var chained = data.clip(lower: -8, upper: 8).abs();
  print('Data: ${chained.data}');
  print('\n');

  // Real-world example: Sensor data
  print('=== Real-World Example: Sensor Readings ===');
  var sensorReadings = Series([
    -5, // Error: below valid range
    20,
    25,
    30,
    150, // Error: above valid range
    28,
    22,
  ], name: 'temperature_celsius');

  print('Raw sensor readings (with errors):');
  print('Data: ${sensorReadings.data}');
  print('\n');

  print('Cleaned readings (valid range: 0-50°C):');
  var cleanedReadings = sensorReadings.clip(lower: 0, upper: 50);
  print('Data: ${cleanedReadings.data}');
  print('\n');

  // Example with null values
  print('=== Handling Null Values ===');
  var incomplete = Series([1, null, 3, 4, null, 6], name: 'incomplete');
  print('Series with nulls:');
  print('Data: ${incomplete.data}');
  print('\n');

  print('After clipping (2-5):');
  var clippedIncomplete = incomplete.clip(lower: 2, upper: 5);
  print('Data: ${clippedIncomplete.data}');
  print('(Null values are preserved)');
}
