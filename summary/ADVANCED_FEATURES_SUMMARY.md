# Advanced Features Implementation Summary

## Overview

This document summarizes the implementation of advanced DataFrame features including merging/joining enhancements, groupby operations, and time series functionality.

## Implemented Features

### 1. Merging & Joining (Advanced)

#### mergeOrdered()
Merge DataFrames with optional filling/interpolation for ordered data (e.g., time series).

**Parameters:**
- `right`: DataFrame to merge with
- `on`: Column name to join on
- `leftOn`/`rightOn`: Separate column names for left/right DataFrames
- `fillMethod`: Fill method ('ffill' or 'bfill')
- `suffixes`: Suffixes for overlapping columns

**Example:**
```dart
var left = DataFrame.fromMap({
  'time': [1, 3, 5],
  'value': [10, 30, 50],
});

var right = DataFrame.fromMap({
  'time': [2, 4, 6],
  'price': [20, 40, 60],
});

var merged = left.mergeOrdered(right, on: 'time', fillMethod: 'ffill');
```

#### joinMultiple()
Join multiple DataFrames at once.

**Parameters:**
- `others`: List of DataFrames to join
- `on`: Column name(s) to join on
- `how`: Type of join ('inner', 'outer', 'left', 'right')
- `suffixes`: List of suffixes for each DataFrame

**Example:**
```dart
var df1 = DataFrame.fromMap({'key': [1, 2, 3], 'A': [10, 20, 30]});
var df2 = DataFrame.fromMap({'key': [1, 2, 3], 'B': [40, 50, 60]});
var df3 = DataFrame.fromMap({'key': [1, 2, 3], 'C': [70, 80, 90]});

var joined = df1.joinMultiple([df2, df3], on: 'key');
```

#### joinWithSuffix()
Enhanced join with lsuffix and rsuffix parameters.

**Parameters:**
- `other`: DataFrame to join with
- `on`: Column name(s) to join on
- `how`: Type of join
- `lsuffix`: Suffix for left DataFrame's overlapping columns
- `rsuffix`: Suffix for right DataFrame's overlapping columns

**Example:**
```dart
var left = DataFrame.fromMap({'id': [1, 2], 'value': [100, 200]});
var right = DataFrame.fromMap({'id': [1, 2], 'value': [150, 250]});

var joined = left.joinWithSuffix(
  right,
  on: 'id',
  lsuffix: '_left',
  rsuffix: '_right',
);
```

### 2. Grouping (Advanced)

#### groupByEnhanced()
Enhanced groupby with additional parameters.

**Parameters:**
- `by`: Column name(s) to group by
- `asIndex`: Whether to use group keys as index (default: true)
- `groupKeys`: Whether to add group keys to index (default: true)
- `observed`: Only show observed values for categorical groupers (default: false)
- `dropna`: Whether to drop NA values from groups (default: true)
- `sort`: Whether to sort group keys (default: true)

**Example:**
```dart
var df = DataFrame.fromMap({
  'category': ['A', 'B', 'A', 'B'],
  'value': [10, 20, 30, 40],
});

var grouped = df.groupByEnhanced('category', dropna: true);
```

#### rollingEnhanced()
Enhanced rolling window with additional parameters.

**Parameters:**
- `window`: Size of the moving window
- `minPeriods`: Minimum number of observations required
- `center`: Whether to center the window around current observation
- `winType`: Type of window ('boxcar', 'triang', 'blackman', etc.)

**Example:**
```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4, 5, 6, 7],
  'B': [10, 20, 30, 40, 50, 60, 70],
});

var rolling = df.rollingEnhanced(3, center: true);
var mean = rolling.mean();
```

#### expandingEnhanced()
Enhanced expanding window with additional parameters.

**Parameters:**
- `minPeriods`: Minimum number of observations required
- `center`: Whether to center the window

**Example:**
```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4, 5],
  'B': [10, 20, 30, 40, 50],
});

var expanding = df.expandingEnhanced(minPeriods: 2);
var sum = expanding.sum();
```

#### ewmEnhanced()
Enhanced exponentially weighted functions with additional parameters.

**Parameters:**
- `com`: Center of mass (alternative to span)
- `span`: Span (alternative to com)
- `halflife`: Half-life (alternative to com/span)
- `alpha`: Smoothing factor (alternative to com/span/halflife)
- `minPeriods`: Minimum number of observations required
- `adjust`: Whether to use bias adjustment
- `ignoreNA`: Whether to ignore missing values

**Example:**
```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4, 5],
  'B': [10, 20, 30, 40, 50],
});

var ewm = df.ewmEnhanced(span: 3, adjust: true);
var mean = ewm.mean();
```

### 3. Time Series (Advanced)

#### inferFreq()
Infer the most likely frequency given the input index.

**Returns:** String representing the inferred frequency or null if cannot infer
- 'D' = Daily
- 'W' = Weekly
- 'M' = Monthly
- 'Y' = Yearly
- 'H' = Hourly
- 'T' = Minutely
- 'S' = Secondly

**Example:**
```dart
var df = DataFrame.fromMap({
  'value': [1, 2, 3, 4],
}, index: [
  DateTime(2023, 1, 1),
  DateTime(2023, 1, 2),
  DateTime(2023, 1, 3),
  DateTime(2023, 1, 4),
]);

var freq = df.inferFreq();
print(freq); // 'D' for daily
```

#### toPeriod()
Convert DatetimeIndex to PeriodIndex.

**Parameters:**
- `freq`: Frequency to convert to ('D', 'M', 'Y', 'Q', 'H')

**Example:**
```dart
var df = DataFrame.fromMap({
  'value': [1, 2, 3],
}, index: [
  DateTime(2023, 1, 15),
  DateTime(2023, 2, 15),
  DateTime(2023, 3, 15),
]);

var periods = df.toPeriod('M');
// Index becomes: ['2023-01', '2023-02', '2023-03']
```

#### toTimestamp()
Convert PeriodIndex to DatetimeIndex.

**Parameters:**
- `freq`: Frequency of the periods ('D', 'M', 'Y', 'Q')
- `how`: How to convert ('start', 'end')

**Example:**
```dart
var df = DataFrame.fromMap({
  'value': [1, 2, 3],
}, index: ['2023-01', '2023-02', '2023-03']);

var timestamps = df.toTimestamp('M', how: 'start');
// Index becomes DateTime objects at start of each month
```

#### normalize()
Normalize DatetimeIndex to midnight.

**Example:**
```dart
var df = DataFrame.fromMap({
  'value': [1, 2, 3],
}, index: [
  DateTime(2023, 1, 1, 14, 30),
  DateTime(2023, 1, 2, 9, 15),
  DateTime(2023, 1, 3, 18, 45),
]);

var normalized = df.normalize();
// All times set to 00:00:00
```

## File Structure

The implementation is organized into the following files:

- `lib/src/data_frame/merging_advanced.dart` - Advanced merging and joining operations
- `lib/src/data_frame/groupby_advanced.dart` - Enhanced groupby and window operations
- `lib/src/data_frame/timeseries_advanced.dart` - Advanced time series operations

## Examples

A comprehensive demo is available at:
- `example/advanced_features_complete_demo.dart`

Run it with:
```bash
dart run example/advanced_features_complete_demo.dart
```

## Practical Use Cases

### 1. Financial Data Analysis
```dart
// Merge price and volume data with forward fill
var prices = DataFrame.fromMap({
  'date': [1, 2, 3, 4, 5],
  'price': [100.0, 101.5, 99.8, 102.3, 103.1],
});

var volumes = DataFrame.fromMap({
  'date': [1, 3, 5, 7],
  'volume': [1000, 1500, 1200, 800],
});

var financial = prices.mergeOrdered(
  volumes,
  on: 'date',
  fillMethod: 'ffill',
);
```

### 2. Multi-Source Business Data
```dart
// Join sales, costs, and profit data
var sales = DataFrame.fromMap({'id': [1, 2, 3], 'sales': [1000, 2000, 3000]});
var costs = DataFrame.fromMap({'id': [1, 2, 3], 'costs': [500, 800, 1200]});
var profits = DataFrame.fromMap({'id': [1, 2, 3], 'margin': [50, 120, 180]});

var business = sales.joinMultiple([costs, profits], on: 'id');
```

### 3. Temperature Analysis
```dart
// Analyze temperature with rolling windows
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

// Infer frequency
print('Frequency: ${tempData.inferFreq()}'); // 'D'

// Smooth with centered rolling window
var rolling = tempData.rollingEnhanced(3, center: true);
var smoothed = rolling.mean();

// Exponentially weighted mean
var ewm = tempData.ewmEnhanced(span: 3);
var ewmSmoothed = ewm.mean();
```

### 4. Quarterly Data Conversion
```dart
// Convert quarterly periods to timestamps
var quarterly = DataFrame.fromMap({
  'revenue': [100, 120, 110, 130],
}, index: ['2023Q1', '2023Q2', '2023Q3', '2023Q4']);

var timestamps = quarterly.toTimestamp('Q', how: 'start');
// Converts to DateTime at start of each quarter
```

## Notes

- **tzLocalize()** and **tzConvert()** already existed in the library and are available for timezone operations
- The enhanced methods delegate to existing implementations where appropriate, adding new parameters for flexibility
- All methods maintain compatibility with existing DataFrame operations
- The implementation follows pandas conventions for parameter names and behavior

## Testing

All features have been tested with the comprehensive demo. The demo covers:
- Multiple DataFrame joining
- Custom suffix handling
- Enhanced groupby operations
- Centered rolling windows
- Expanding windows
- Exponentially weighted functions
- Frequency inference
- Period/timestamp conversion
- DateTime normalization

## Future Enhancements

Potential areas for future development:
- Additional merge validation parameters (one-to-one, one-to-many, many-to-one)
- Merge indicator parameter to show merge type
- merge_asof() enhancements with tolerance and direction parameters
- Additional window types for rolling operations
- More sophisticated timezone handling with proper timezone libraries
