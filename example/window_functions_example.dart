import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Window Functions Example ===\n');

  // Create sample data
  var df = DataFrame([
    [1.0, 10.0],
    [2.0, 20.0],
    [3.0, 30.0],
    [4.0, 40.0],
    [5.0, 50.0],
  ], columns: [
    'A',
    'B'
  ]);

  print('Original DataFrame:');
  print(df);
  print('\n');

  // Exponentially Weighted Mean
  print('=== Exponentially Weighted Mean (span=3) ===');
  var ewmMean = df.ewm(span: 3).mean();
  print(ewmMean);
  print('\n');

  // Exponentially Weighted Std
  print('=== Exponentially Weighted Std (span=3) ===');
  var ewmStd = df.ewm(span: 3).std();
  print(ewmStd);
  print('\n');

  // Expanding Mean
  print('=== Expanding Mean ===');
  var expandingMean = df.expanding().mean();
  print(expandingMean);
  print('\n');

  // Expanding Sum
  print('=== Expanding Sum ===');
  var expandingSum = df.expanding().sum();
  print(expandingSum);
  print('\n');

  // Expanding Min/Max
  print('=== Expanding Min ===');
  var expandingMin = df.expanding().min();
  print(expandingMin);
  print('\n');

  print('=== Expanding Max ===');
  var expandingMax = df.expanding().max();
  print(expandingMax);
  print('\n');

  // Financial example
  print('=== Financial Example: Stock Prices ===');
  var stockPrices = DataFrame([
    [100.0],
    [102.0],
    [101.0],
    [105.0],
    [103.0],
    [107.0],
    [106.0],
    [110.0],
  ], columns: [
    'Close'
  ]);

  print('Stock Prices:');
  print(stockPrices);
  print('\n');

  print('20-period EWMA (simulated with span=3):');
  var ewma = stockPrices.ewm(span: 3).mean();
  print(ewma);
  print('\n');

  print('Volatility (EWM Std):');
  var volatility = stockPrices.ewm(span: 3).std();
  print(volatility);
  print('\n');

  print('Running Total:');
  var runningTotal = stockPrices.expanding().sum();
  print(runningTotal);
  print('\n');

  print('Running Average:');
  var runningAvg = stockPrices.expanding().mean();
  print(runningAvg);
  print('\n');

  // Correlation and Covariance example
  print('=== Correlation and Covariance Example ===');
  var multiCol = DataFrame([
    [100.0, 50.0],
    [102.0, 51.0],
    [101.0, 50.5],
    [105.0, 52.5],
    [103.0, 51.5],
  ], columns: [
    'Stock_A',
    'Stock_B'
  ]);

  print('Multi-column data:');
  print(multiCol);
  print('\n');

  print('EWM Correlation (span=3):');
  var ewmCorr = multiCol.ewm(span: 3).corr();
  print(ewmCorr);
  print('\n');

  print('EWM Covariance (span=3):');
  var ewmCov = multiCol.ewm(span: 3).cov();
  print(ewmCov);
}
