import 'package:dartframe/dartframe.dart';

/// Comprehensive example demonstrating advanced statistical operations in DartFrame
/// This example showcases the enhanced statistical capabilities that provide
/// pandas-like functionality for data analysis.
void main() async {
  print('=== DartFrame Statistical Operations Example ===\n');

  // Create sample dataset for statistical analysis
  final salesData = DataFrame.fromRows([
    {
      'Month': 'Jan',
      'Sales': 1200,
      'Profit': 240,
      'Customers': 45,
      'Region': 'North'
    },
    {
      'Month': 'Feb',
      'Sales': 1350,
      'Profit': 270,
      'Customers': 52,
      'Region': 'North'
    },
    {
      'Month': 'Mar',
      'Sales': 1100,
      'Profit': 220,
      'Customers': 41,
      'Region': 'North'
    },
    {
      'Month': 'Apr',
      'Sales': 1450,
      'Profit': 290,
      'Customers': 58,
      'Region': 'South'
    },
    {
      'Month': 'May',
      'Sales': 1600,
      'Profit': 320,
      'Customers': 64,
      'Region': 'South'
    },
    {
      'Month': 'Jun',
      'Sales': 1380,
      'Profit': 276,
      'Customers': 55,
      'Region': 'South'
    },
    {
      'Month': 'Jul',
      'Sales': 1520,
      'Profit': 304,
      'Customers': 61,
      'Region': 'East'
    },
    {
      'Month': 'Aug',
      'Sales': 1420,
      'Profit': 284,
      'Customers': 57,
      'Region': 'East'
    },
    {
      'Month': 'Sep',
      'Sales': 1300,
      'Profit': 260,
      'Customers': 52,
      'Region': 'East'
    },
    {
      'Month': 'Oct',
      'Sales': 1480,
      'Profit': 296,
      'Customers': 59,
      'Region': 'West'
    },
    {
      'Month': 'Nov',
      'Sales': 1650,
      'Profit': 330,
      'Customers': 66,
      'Region': 'West'
    },
    {
      'Month': 'Dec',
      'Sales': 1750,
      'Profit': 350,
      'Customers': 70,
      'Region': 'West'
    },
  ]);

  print('Sample Sales Data:');
  print(salesData.head());
  print('');

  // 1. Basic Statistical Summary
  print('1. BASIC STATISTICAL SUMMARY');
  print('=' * 40);

  final basicStats = salesData.describe();
  print('Basic Statistics:');
  print(basicStats);
  print('');

  // 2. Advanced Statistical Measures
  print('2. ADVANCED STATISTICAL MEASURES');
  print('=' * 40);

  // Calculate median, mode, and quantiles
  final salesSeries = salesData['Sales'] as Series;
  print('Sales Statistics:');
  print('Mean: ${salesSeries.mean()}');
  print('Min: ${salesSeries.min()}');
  print('Max: ${salesSeries.max()}');
  print('Count: ${salesSeries.count()}');

  // Use the advanced statistical methods to avoid conflicts
  try {
    print('Median: ${salesSeries.median()}');
    print('Mode: ${salesSeries.mode()}');
    print('Standard Deviation: ${salesSeries.std()}');
    print('Variance: ${salesSeries.variance()}');
    print('Skewness: ${salesSeries.skew()}');
    print('Kurtosis: ${salesSeries.kurtosis()}');
    print('25th Percentile: ${salesSeries.quantile(0.25)}');
    print('75th Percentile: ${salesSeries.quantile(0.75)}');
  } catch (e) {
    print('Advanced statistics error: $e');
  }
  print('');

  // 3. Correlation Analysis
  print('3. CORRELATION ANALYSIS');
  print('=' * 40);

  final corrMatrix = salesData.corr();
  print('Correlation Matrix:');
  print(corrMatrix);
  print('');

  final covMatrix = salesData.cov();
  print('Covariance Matrix:');
  print(covMatrix);
  print('');

  // 4. Rolling Window Operations
  print('4. ROLLING WINDOW OPERATIONS');
  print('=' * 40);

  final rolling = salesData.rollingWindow(3);
  final rollingMean = rolling.mean();
  final rollingStd = rolling.std();

  print('3-Month Rolling Average:');
  print(rollingMean[['Month', 'Sales', 'Profit']]);
  print('');

  print('3-Month Rolling Standard Deviation:');
  print(rollingStd[['Month', 'Sales', 'Profit']]);
  print('');

  // 5. Groupby Operations with Advanced Statistics
  print('5. GROUPBY OPERATIONS WITH ADVANCED STATISTICS');
  print('=' * 40);

  // Use groupByAgg for aggregation operations
  final regionStatsMean = salesData.groupByAgg(
      'Region', {'Sales': 'mean', 'Profit': 'mean', 'Customers': 'mean'});

  final regionStatsSum = salesData.groupByAgg(
      'Region', {'Sales': 'sum', 'Profit': 'sum', 'Customers': 'count'});

  final regionStatsMinMax =
      salesData.groupByAgg('Region', {'Sales': 'min', 'Profit': 'max'});

  print('Mean Statistics by Region:');
  print(regionStatsMean);
  print('');

  print('Sum/Count Statistics by Region:');
  print(regionStatsSum);
  print('');

  print('Min/Max Statistics by Region:');
  print(regionStatsMinMax);
  print('');

  // 6. Cumulative Statistics
  print('6. CUMULATIVE STATISTICS');
  print('=' * 40);

  salesData['CumSales'] = salesData['Sales'].cumsum();
  salesData['CumProfit'] = salesData['Profit'].cumsum();
  salesData['RunningAvgSales'] = salesData['Sales'].expanding().mean();

  print('Cumulative and Running Statistics:');
  print(salesData[['Month', 'Sales', 'CumSales', 'RunningAvgSales']]);
  print('');

  // 7. Percentile Analysis
  print('7. PERCENTILE ANALYSIS');
  print('=' * 40);

  final percentiles = [0.1, 0.25, 0.5, 0.75, 0.9];
  print('Sales Percentiles:');
  for (final p in percentiles) {
    print('${(p * 100).toInt()}th percentile: ${salesSeries.quantile(p)}');
  }
  print('');

  // 8. Statistical Tests and Analysis
  print('8. STATISTICAL TESTS AND ANALYSIS');
  print('=' * 40);

  // Normality test (conceptual - would need actual implementation)
  print('Distribution Analysis:');
  print('Sales Mean: ${salesSeries.mean()}');
  print('Sales Median: ${salesSeries.median()}');
  print(
      'Mean vs Median difference: ${(salesSeries.mean() - salesSeries.median()).abs()}');

  if ((salesSeries.mean() - salesSeries.median()).abs() <
      salesSeries.std() * 0.1) {
    print('Distribution appears approximately normal');
  } else {
    print('Distribution may be skewed');
  }
  print('');

  // 9. Outlier Detection
  print('9. OUTLIER DETECTION');
  print('=' * 40);

  final q1 = salesSeries.quantile(0.25);
  final q3 = salesSeries.quantile(0.75);
  final iqr = q3 - q1;
  final lowerBound = q1 - 1.5 * iqr;
  final upperBound = q3 + 1.5 * iqr;

  print('IQR Analysis for Sales:');
  print('Q1: $q1');
  print('Q3: $q3');
  print('IQR: $iqr');
  print('Lower Bound: $lowerBound');
  print('Upper Bound: $upperBound');

  // Create boolean mask for outliers
  final isOutlier = salesData['Sales'].apply(
      (sales) => sales != null && (sales < lowerBound || sales > upperBound));

  // Filter DataFrame using boolean indexing
  final outliers = salesData[isOutlier];

  if (outliers.rowCount > 0) {
    print('Outliers detected:');
    print(outliers[['Month', 'Sales']]);
  } else {
    print('No outliers detected in sales data');
  }
  print('');

  // 10. Time Series Statistics
  print('10. TIME SERIES STATISTICS');
  print('=' * 40);

  // Calculate month-over-month growth
  final salesList = salesData['Sales'].data.cast<num>();
  final momGrowth = <double>[];
  momGrowth.add(0.0); // First month has no previous month

  for (int i = 1; i < salesList.length; i++) {
    final growth = ((salesList[i] - salesList[i - 1]) / salesList[i - 1]) * 100;
    momGrowth.add(growth);
  }

  salesData['MoM_Growth'] = Series(momGrowth, name: 'MoM_Growth');

  print('Month-over-Month Growth Analysis:');
  print(salesData[['Month', 'Sales', 'MoM_Growth']]);
  print('');

  print('Growth Statistics:');
  final growthSeries = salesData['MoM_Growth'];
  print('Average Growth: ${growthSeries.mean().toStringAsFixed(2)}%');
  print('Growth Std Dev: ${growthSeries.std().toStringAsFixed(2)}%');
  print('Max Growth: ${growthSeries.max().toStringAsFixed(2)}%');
  print('Min Growth: ${growthSeries.min().toStringAsFixed(2)}%');

  print('\n=== Statistical Operations Example Complete ===');
}
