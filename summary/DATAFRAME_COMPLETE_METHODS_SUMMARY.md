# DataFrame Complete Statistical Methods Summary

## Overview
Successfully implemented all missing statistical methods for DataFrame to achieve feature parity with Series, completing the statistical methods suite.

## Newly Implemented Methods

### 1. pctChange() - Percentage Change
Calculates the percentage change between consecutive rows.

#### Signature
```dart
DataFrame pctChange({int periods = 1, int axis = 0})
```

#### Parameters
- **periods**: Periods to shift for calculating percent change (default: 1)
- **axis**: 0 for rows (default), 1 for columns (not yet supported)

#### Formula
```
pct_change = (current - previous) / previous
```

#### Example
```dart
var df = DataFrame([
  [100, 200],
  [110, 220],
  [121, 242],
], columns: ['A', 'B']);

var pct = df.pctChange();
// A: [null, 0.1, 0.1]  (10% increase)
// B: [null, 0.1, 0.1]
```

### 2. diff() - First Discrete Difference
Calculates the difference between consecutive rows.

#### Signature
```dart
DataFrame diff({int periods = 1, int axis = 0})
```

#### Parameters
- **periods**: Periods to shift for calculating difference (default: 1)
- **axis**: 0 for rows (default), 1 for columns (not yet supported)

#### Formula
```
diff = current - previous
```

#### Example
```dart
var df = DataFrame([
  [1, 10],
  [3, 15],
  [6, 25],
], columns: ['A', 'B']);

var diff = df.diff();
// A: [null, 2, 3]
// B: [null, 5, 10]
```

### 3. idxmax() - Index of Maximum
Returns the index label of the maximum value for each column.

#### Signature
```dart
Series idxmax({int axis = 0, bool skipna = true})
```

#### Parameters
- **axis**: 0 for columns (default), 1 for rows (not yet supported)
- **skipna**: Exclude NA/null values (default: true)

#### Returns
A Series with index labels of maximum values.

#### Example
```dart
var df = DataFrame([
  [1, 10],
  [3, 5],
  [2, 15],
], columns: ['A', 'B'], index: ['x', 'y', 'z']);

var idxmax = df.idxmax();
// A: 'y' (value 3 at index y)
// B: 'z' (value 15 at index z)
```

### 4. idxmin() - Index of Minimum
Returns the index label of the minimum value for each column.

#### Signature
```dart
Series idxmin({int axis = 0, bool skipna = true})
```

#### Parameters
- **axis**: 0 for columns (default), 1 for rows (not yet supported)
- **skipna**: Exclude NA/null values (default: true)

#### Returns
A Series with index labels of minimum values.

#### Example
```dart
var df = DataFrame([
  [1, 10],
  [3, 5],
  [2, 15],
], columns: ['A', 'B'], index: ['x', 'y', 'z']);

var idxmin = df.idxmin();
// A: 'x' (value 1 at index x)
// B: 'y' (value 5 at index y)
```

## Test Results

Created comprehensive test suite (`test/dataframe_missing_methods_test.dart`) with **28 passing tests**:

### Test Coverage

#### pctChange() Tests (6 tests)
- ✅ Calculates percentage change
- ✅ Handles periods parameter
- ✅ Handles null values
- ✅ Handles division by zero
- ✅ Throws error for non-positive periods
- ✅ Preserves index

#### diff() Tests (6 tests)
- ✅ Calculates first difference
- ✅ Handles periods parameter
- ✅ Handles null values
- ✅ Handles negative differences
- ✅ Throws error for non-positive periods
- ✅ Preserves index

#### idxmax() Tests (5 tests)
- ✅ Returns index of maximum values
- ✅ Handles ties (keeps first)
- ✅ Handles null values with skipna
- ✅ Handles all null column
- ✅ Handles negative values

#### idxmin() Tests (5 tests)
- ✅ Returns index of minimum values
- ✅ Handles ties (keeps first)
- ✅ Handles null values with skipna
- ✅ Handles all null column
- ✅ Handles negative values

#### Integration Tests (3 tests)
- ✅ pctChange and diff can be chained
- ✅ idxmax and idxmin work together
- ✅ All methods preserve DataFrame structure

#### Edge Cases (3 tests)
- ✅ Handles empty DataFrame
- ✅ Handles single row DataFrame
- ✅ Handles non-numeric columns

## Complete Statistical Methods for DataFrame

All statistical methods are now implemented for DataFrame:

1. ✅ **rank()** - Compute numerical data ranks
2. ✅ **pctChange()** - Percentage change between elements ✨ NEW
3. ✅ **diff()** - First discrete difference ✨ NEW
4. ✅ **clip()** - Trim values at input thresholds
5. ✅ **qcut()** - Quantile-based discretization (via bin())
6. ✅ **nlargest() / nsmallest()** - Return n largest/smallest values
7. ✅ **idxmax() / idxmin()** - Return index of max/min values ✨ NEW
8. ✅ **abs()** - Absolute values
9. ✅ **round()** - Round to specified decimals
10. ✅ **cov()** - Covariance with methods
11. ✅ **corr()** - Correlation with methods

## Feature Parity

DataFrame now has complete feature parity with Series for all statistical methods!

| Method | Series | DataFrame |
|--------|--------|-----------|
| rank() | ✅ | ✅ |
| pctChange() | ✅ | ✅ |
| diff() | ✅ | ✅ |
| clip() | ✅ | ✅ |
| qcut() | ✅ | ✅ |
| nlargest() | ✅ | ✅ |
| nsmallest() | ✅ | ✅ |
| idxmax() | ✅ | ✅ |
| idxmin() | ✅ | ✅ |
| abs() | ✅ | ✅ |
| round() | ✅ | ✅ |
| cov() | ✅ | ✅ |
| corr() | ✅ | ✅ |

## Real-World Applications

### Time Series Analysis
```dart
// Calculate returns and changes
var prices = df['Close'];
var returns = df.pctChange();
var changes = df.diff();

// Find peaks and troughs
var maxIdx = df.idxmax();
var minIdx = df.idxmin();
```

### Financial Analysis
```dart
// Daily returns
var dailyReturns = stockPrices.pctChange();

// Price changes
var priceChanges = stockPrices.diff();

// Find best and worst days
var bestDay = stockPrices.idxmax();
var worstDay = stockPrices.idxmin();
```

### Data Exploration
```dart
// Identify extremes
var maxValues = df.idxmax();
var minValues = df.idxmin();

// Analyze trends
var changes = df.diff();
var percentChanges = df.pctChange();
```

## Files Created/Modified

### Created:
1. `test/dataframe_missing_methods_test.dart` - 28 comprehensive tests

### Modified:
1. `lib/src/data_frame/operations.dart` - Added pctChange(), diff(), idxmax(), idxmin()

## Technical Details

### Implementation Approach
- All methods operate row-wise (axis=0)
- Null values are handled gracefully
- Non-numeric values return null for calculations
- Index is preserved in all operations
- Efficient O(n*m) implementations

### Performance
- pctChange(): O(n*m) time, O(n*m) space
- diff(): O(n*m) time, O(n*m) space
- idxmax(): O(n*m) time, O(m) space
- idxmin(): O(n*m) time, O(m) space

Where n = rows, m = columns

## Comparison with Pandas

### Similarities
- ✅ Same method names
- ✅ Same parameter names
- ✅ Same default behaviors
- ✅ Same null handling
- ✅ Same return types

### Differences
- Pandas supports axis=1 (column-wise operations) - not yet implemented
- Pandas has more options for fill methods - not yet implemented
- This implementation focuses on core functionality

## Error Handling

### pctChange()
- Throws `ArgumentError` if periods ≤ 0
- Returns null for division by zero
- Returns null for non-numeric values

### diff()
- Throws `ArgumentError` if periods ≤ 0
- Returns null for non-numeric values

### idxmax() / idxmin()
- Throws `ArgumentError` if axis ≠ 0
- Returns null for all-null columns
- Skips null values when skipna=true

## Total Test Coverage

**Combined Test Results: 83 tests passing**
- 36 tests: DataFrame operations (clip, abs, round)
- 28 tests: DataFrame missing methods (pctChange, diff, idxmax, idxmin)
- 19 tests: Series clip

## Conclusion

Successfully implemented all missing statistical methods for DataFrame:
- ✅ pctChange() - Percentage change calculations
- ✅ diff() - Discrete differences
- ✅ idxmax() - Index of maximum values
- ✅ idxmin() - Index of minimum values

DataFrame now has complete feature parity with Series for all statistical methods. All 83 tests pass, demonstrating robust implementation with comprehensive edge case handling.

**Statistical Methods: 100% Complete for Both DataFrame and Series! 🎉**
