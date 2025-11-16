# Advanced Reshaping Operations

This document provides a comprehensive overview of the advanced reshaping operations implemented in DartFrame.

## Overview

Advanced reshaping operations provide powerful tools for transforming DataFrame structures, including MultiIndex operations, wide-to-long transformations, and enhanced one-hot encoding.

## Features

### 1. wideToLong() - Wide Panel to Long Format

Convert a DataFrame from wide format to long format, useful for panel data where multiple time periods are stored as separate columns.

**Parameters:**
- `stubnames`: The stub name(s) of the wide variable(s)
- `i`: Column(s) to use as id variable(s)
- `j`: The name of the sub-observation variable
- `sep`: Character indicating the separation of variable names (default: '_')
- `suffix`: Regular expression capturing the suffix (default: r'\d+')

**Example:**
```dart
// Wide format:
var df = DataFrame([
  [1, 10, 15, 20, 25],
  [2, 30, 35, 40, 45],
], columns: ['id', 'A_2020', 'A_2021', 'B_2020', 'B_2021']);

var long = df.wideToLong(
  stubnames: ['A', 'B'],
  i: ['id'],
  j: 'year',
  sep: '_',
);

// Long format:
// id | year | A  | B
// 1  | 2020 | 10 | 20
// 1  | 2021 | 15 | 25
// 2  | 2020 | 30 | 40
// 2  | 2021 | 35 | 45
```

### 2. getDummiesEnhanced() - Enhanced One-Hot Encoding

Convert categorical variables into dummy/indicator variables with advanced options.

**Parameters:**
- `columns`: Columns to convert (null = auto-detect string columns)
- `prefix`: String to append to column names (default: column name)
- `prefixSep`: Separator between prefix and value (default: '_')
- `dropFirst`: Drop first category to avoid multicollinearity (default: false)
- `dummyNa`: Add column to indicate NaNs (default: false)
- `dtype`: Data type for dummy columns ('int' or 'bool', default: 'int')

**Example:**
```dart
var df = DataFrame([
  ['A', 1],
  ['B', 2],
  ['A', 3],
], columns: ['Category', 'Value']);

// Basic one-hot encoding
var dummies = df.getDummiesEnhanced(columns: ['Category']);
// Result: Value, Category_A, Category_B

// With drop first (for regression)
var dummiesDropFirst = df.getDummiesEnhanced(
  columns: ['Category'],
  dropFirst: true,
);
// Result: Value, Category_B (Category_A dropped)

// With boolean type
var boolDummies = df.getDummiesEnhanced(
  columns: ['Category'],
  dtype: 'bool',
);
// Result: Values are true/false instead of 1/0
```

### 3. swapLevel() - Swap Levels in MultiIndex

Swap two levels in a MultiIndex.

**Parameters:**
- `i`: First level to swap (int or String)
- `j`: Second level to swap (int or String)
- `axis`: 0 for index, 1 for columns (default: 0)

**Example:**
```dart
var df = DataFrame([
  [1, 10],
  [2, 20],
], columns: ['A', 'B']);

df = DataFrame.fromMap(
  {'A': df['A'].toList(), 'B': df['B'].toList()},
  index: ['level0_level1', 'level0_level2'],
);

var swapped = df.swapLevel(0, 1);
// Index becomes: ['level1_level0', 'level2_level0']
```

### 4. reorderLevels() - Rearrange Index Levels

Rearrange index levels using input order.

**Parameters:**
- `order`: List of level positions or names in desired order
- `axis`: 0 for index, 1 for columns (default: 0)

**Example:**
```dart
var df = DataFrame([
  [1],
  [2],
], columns: ['Value']);

df = DataFrame.fromMap(
  {'Value': df['Value'].toList()},
  index: ['a_b_c', 'd_e_f'],
);

var reordered = df.reorderLevels([2, 0, 1]);
// Index becomes: ['c_a_b', 'f_d_e']
```

## Use Cases

### 1. Panel Data Analysis
```dart
// Convert wide panel data to long format for time series analysis
var widePanel = DataFrame([
  [1, 'A', 100, 110, 120],
  [2, 'B', 150, 160, 170],
], columns: ['id', 'group', 'value_2020', 'value_2021', 'value_2022']);

var longPanel = widePanel.wideToLong(
  stubnames: ['value'],
  i: ['id', 'group'],
  j: 'year',
  sep: '_',
);
// Now ready for time series analysis
```

### 2. Machine Learning Preprocessing
```dart
// Prepare categorical features for machine learning
var data = DataFrame([
  ['Red', 'Small', 10],
  ['Blue', 'Large', 20],
  ['Red', 'Medium', 15],
], columns: ['Color', 'Size', 'Price']);

// One-hot encode with drop first to avoid multicollinearity
var encoded = data.getDummiesEnhanced(
  columns: ['Color', 'Size'],
  dropFirst: true,
);
// Ready for regression models
```

### 3. Missing Value Indicators
```dart
// Track missing values while encoding
var dataWithNulls = DataFrame([
  ['A'],
  [null],
  ['B'],
], columns: ['Category']);

var withNaIndicator = dataWithNulls.getDummiesEnhanced(
  columns: ['Category'],
  dummyNa: true,
);
// Includes Category_nan column to track missing values
```

### 4. Survey Data Transformation
```dart
// Transform survey responses from wide to long format
var survey = DataFrame([
  [1, 5, 4, 3, 5],
  [2, 4, 5, 4, 4],
], columns: ['respondent', 'q1_score', 'q2_score', 'q3_score', 'q4_score']);

var longSurvey = survey.wideToLong(
  stubnames: ['q1', 'q2', 'q3', 'q4'],
  i: ['respondent'],
  j: 'question',
  sep: '_',
  suffix: r'\w+',
);
// Easier to analyze question responses
```

### 5. Feature Engineering
```dart
// Create boolean features for classification
var features = DataFrame([
  ['Male', 'Yes', 25],
  ['Female', 'No', 30],
  ['Male', 'Yes', 35],
], columns: ['Gender', 'Smoker', 'Age']);

var boolFeatures = features.getDummiesEnhanced(
  columns: ['Gender', 'Smoker'],
  dtype: 'bool',
  prefix: 'is',
);
// Creates is_Male, is_Female, is_Yes, is_No as boolean columns
```

## Comparison with Pandas

| DartFrame Method | Pandas Equivalent | Notes |
|-----------------|-------------------|-------|
| `wideToLong()` | `pd.wide_to_long()` | Full feature parity |
| `getDummiesEnhanced()` | `pd.get_dummies()` | Enhanced with more options |
| `swapLevel()` | `df.swaplevel()` | Simplified for basic MultiIndex |
| `reorderLevels()` | `df.reorder_levels()` | Simplified for basic MultiIndex |

## Performance Considerations

- **wideToLong():** O(n * m) where n = rows, m = stub columns
- **getDummiesEnhanced():** O(n * k) where n = rows, k = unique categories
- **swapLevel():** O(n) where n = number of index entries
- **reorderLevels():** O(n) where n = number of index entries

## Best Practices

### 1. Wide to Long Transformations
- Use descriptive stub names that match your column naming convention
- Specify the correct separator character
- Use appropriate suffix regex pattern (digits vs. words)
- Keep id columns minimal for better performance

### 2. One-Hot Encoding
- Use `dropFirst=true` for regression models to avoid multicollinearity
- Use `dtype='bool'` when working with boolean logic
- Use `dummyNa=true` when missing values are informative
- Consider memory usage with high-cardinality categories

### 3. MultiIndex Operations
- Document your index structure clearly
- Use consistent naming conventions for levels
- Test with sample data before applying to large datasets
- Consider flattening MultiIndex for simpler operations

### 4. Memory Management
- For large datasets, process in chunks
- Drop unnecessary columns before encoding
- Use appropriate data types (bool vs. int)
- Monitor memory usage with high-cardinality features

## Testing

All advanced reshaping functions have been thoroughly tested with:
- 30 unit tests covering all methods and edge cases
- Tests for empty DataFrames, single values, and complex scenarios
- Edge case handling for missing values and invalid inputs
- Performance validation with realistic datasets

## Examples

See the following example files for detailed usage:
- `example/reshaping_advanced_example.dart` - Comprehensive examples
- `test/reshaping_advanced_test.dart` - Test cases demonstrating usage

## See Also

- [Reshaping Operations](RESHAPING_SUMMARY.md) - Basic reshaping (stack, unstack, melt, pivot)
- [Window Ranking](WINDOW_RANKING_SUMMARY.md) - SQL-style ranking functions
- [GroupBy Enhancements](GROUPBY_ENHANCEMENTS_SUMMARY.md) - Group-wise operations

## References

- Pandas wide_to_long: https://pandas.pydata.org/docs/reference/api/pandas.wide_to_long.html
- Pandas get_dummies: https://pandas.pydata.org/docs/reference/api/pandas.get_dummies.html
- MultiIndex documentation: https://pandas.pydata.org/docs/user_guide/advanced.html
