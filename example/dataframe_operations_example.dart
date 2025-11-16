import 'package:dartframe/dartframe.dart';

void main() {
  print('=== DataFrame Operations Example ===\n');

  // Create sample data with some extreme values
  var df = DataFrame([
    [-5, -50.123, 100],
    [2, 20.456, 200],
    [10, 100.789, 300],
    [-3, -30.234, 400],
    [7, 70.567, 500],
  ], columns: [
    'A',
    'B',
    'C'
  ]);

  print('Original DataFrame:');
  print(df);
  print('\n');

  // Demonstrate clip()
  print('=== clip() - Trim values at thresholds ===');
  print('Clip values between -2 and 8:');
  var clipped = df.clip(lower: -2, upper: 8);
  print(clipped);
  print('\n');

  print('Clip only lower bound (minimum 0):');
  var clippedLower = df.clip(lower: 0);
  print(clippedLower);
  print('\n');

  print('Clip only upper bound (maximum 50):');
  var clippedUpper = df.clip(upper: 50);
  print(clippedUpper);
  print('\n');

  // Demonstrate abs()
  print('=== abs() - Absolute values ===');
  var absValues = df.abs();
  print(absValues);
  print('\n');

  // Demonstrate round()
  print('=== round() - Round to decimals ===');
  print('Round to 2 decimal places:');
  var rounded2 = df.round(2);
  print(rounded2);
  print('\n');

  print('Round to integers:');
  var rounded0 = df.round(0);
  print(rounded0);
  print('\n');

  print('Round only column B to 1 decimal:');
  var roundedB = df.round(1, columns: ['B']);
  print(roundedB);
  print('\n');

  // Demonstrate method chaining
  print('=== Method Chaining ===');
  print('Chain: clip(-2, 8) -> abs() -> round(1)');
  var chained = df.clip(lower: -2, upper: 8).abs().round(1);
  print(chained);
  print('\n');

  // Real-world example: Financial data processing
  print('=== Real-World Example: Stock Prices ===');
  var stockPrices = DataFrame([
    [100.12345, -5.67890], // Negative price (error)
    [102.34567, 3.45678],
    [98.76543, -2.34567], // Negative change (error)
    [105.43210, 7.89012],
    [103.21098, 1.23456],
  ], columns: [
    'Price',
    'Change'
  ]);

  print('Raw stock data (with errors):');
  print(stockPrices);
  print('\n');

  print('Cleaned data (abs + round to 2 decimals):');
  var cleanedPrices = stockPrices.abs().round(2);
  print(cleanedPrices);
  print('\n');

  print('Capped changes (clip to ±5):');
  var cappedChanges = stockPrices.clip(lower: -5, upper: 5).round(2);
  print(cappedChanges);
  print('\n');

  // Example: Outlier handling
  print('=== Outlier Handling Example ===');
  var data = DataFrame([
    [1, 10],
    [2, 20],
    [3, 30],
    [100, 1000], // Outlier
    [4, 40],
    [5, 50],
    [-50, -500], // Outlier
  ], columns: [
    'X',
    'Y'
  ]);

  print('Data with outliers:');
  print(data);
  print('\n');

  print('After clipping outliers (0 to 10):');
  var noOutliers = data.clip(lower: 0, upper: 10);
  print(noOutliers);
}
