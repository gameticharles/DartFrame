# SQL-Style Window Ranking Functions

This document provides a comprehensive overview of the SQL-style window ranking functions implemented in DartFrame.

## Overview

Window ranking functions provide SQL-like ranking capabilities for DataFrames, allowing you to assign ranks, row numbers, percentiles, and cumulative distributions to your data.

## Features

### 1. rankWindow() - Flexible Ranking

Compute numerical ranks along columns with various tie-breaking methods.

**Parameters:**
- `columns`: List of column names to rank (null = all numeric columns)
- `method`: Tie-breaking method
  - `'average'`: Average rank of tied values (default)
  - `'min'`: Lowest rank in the group
  - `'max'`: Highest rank in the group
  - `'first'`: Ranks assigned in order of appearance
  - `'dense'`: Like 'min', but rank always increases by 1
- `ascending`: Rank in ascending (true) or descending (false) order
- `pct`: Return percentile ranks (0 to 1) instead of integer ranks

**Example:**
```dart
var df = DataFrame([
  [100],
  [100],
  [200],
  [300],
], columns: ['Score']);

// Average ranking (ties get average rank)
var ranked = df.rankWindow(columns: ['Score'], method: 'average');
// Result: [1.5, 1.5, 3.0, 4.0]

// Dense ranking (no gaps in rank sequence)
var denseRanked = df.rankWindow(columns: ['Score'], method: 'dense');
// Result: [1.0, 1.0, 2.0, 3.0]
```

### 2. denseRank() - Dense Ranking

Convenience method for dense ranking (rank always increases by 1 between groups).

**Parameters:**
- `columns`: List of column names to rank
- `ascending`: Rank in ascending or descending order

**Example:**
```dart
var df = DataFrame([
  [100],
  [100],
  [200],
  [300],
], columns: ['Score']);

var ranked = df.denseRank(columns: ['Score']);
// Result: [1, 1, 2, 3]
```

### 3. rowNumber() - Sequential Row Numbers

Assign a unique sequential integer to each row, starting from 1.

**Parameters:**
- `columnName`: Name of the new column (default: 'row_number')

**Example:**
```dart
var df = DataFrame([
  ['Alice', 100],
  ['Bob', 200],
  ['Charlie', 150],
], columns: ['Name', 'Score']);

var numbered = df.rowNumber();
// Adds 'row_number' column: [1, 2, 3]
```

### 4. percentRank() - Relative Rank (Percentile)

Compute the relative rank (percentile) of each value.

**Formula:** `(rank - 1) / (n - 1)` where n is the number of rows.

**Parameters:**
- `columns`: List of column names to compute percent rank
- `ascending`: Rank in ascending or descending order

**Example:**
```dart
var df = DataFrame([
  [100],
  [200],
  [300],
  [400],
], columns: ['Score']);

var pctRank = df.percentRank(columns: ['Score']);
// Result: [0.0, 0.333, 0.667, 1.0]
```

### 5. cumulativeDistribution() - Cumulative Distribution

Compute the cumulative distribution of values.

**Formula:** `(number of rows with value <= current value) / (total number of rows)`

**Parameters:**
- `columns`: List of column names to compute cumulative distribution
- `ascending`: Compute in ascending or descending order

**Example:**
```dart
var df = DataFrame([
  [100],
  [200],
  [200],
  [300],
], columns: ['Score']);

var cumeDist = df.cumulativeDistribution(columns: ['Score']);
// Result: [0.25, 0.75, 0.75, 1.0]
```

## Comparison with SQL Window Functions

| DartFrame Method | SQL Equivalent | Description |
|-----------------|----------------|-------------|
| `rankWindow(method: 'min')` | `RANK()` | Standard ranking with gaps |
| `denseRank()` | `DENSE_RANK()` | Ranking without gaps |
| `rowNumber()` | `ROW_NUMBER()` | Sequential numbering |
| `percentRank()` | `PERCENT_RANK()` | Relative rank (0 to 1) |
| `cumulativeDistribution()` | `CUME_DIST()` | Cumulative distribution |

## Use Cases

### 1. Sales Ranking
```dart
var sales = DataFrame([
  ['Alice', 50000],
  ['Bob', 75000],
  ['Charlie', 50000],
  ['David', 100000],
], columns: ['Employee', 'Sales']);

var ranked = sales.rankWindow(
  columns: ['Sales'],
  method: 'dense',
  ascending: false,
);
// Rank employees by sales (highest first)
```

### 2. Percentile Analysis
```dart
var scores = DataFrame([
  [85],
  [90],
  [75],
  [95],
  [80],
], columns: ['Score']);

var percentiles = scores.percentRank(columns: ['Score']);
// Get percentile rank for each score
```

### 3. Top N Selection
```dart
var products = DataFrame([
  ['Product A', 500],
  ['Product B', 750],
  ['Product C', 500],
  ['Product D', 1000],
], columns: ['Product', 'Revenue']);

var ranked = products.rankWindow(
  columns: ['Revenue'],
  ascending: false,
);

// Filter top 3 products
var top3 = ranked.query('Revenue_rank <= 3');
```

### 4. Cumulative Distribution Analysis
```dart
var data = DataFrame([
  [10],
  [20],
  [20],
  [30],
  [40],
], columns: ['Value']);

var cumeDist = data.cumulativeDistribution(columns: ['Value']);
// Analyze how values are distributed
```

## Performance Considerations

- **Time Complexity:** O(n log n) for sorting + O(n) for ranking = O(n log n)
- **Space Complexity:** O(n) for storing ranks
- **Optimization:** Ranking is performed column-by-column, allowing for efficient memory usage

## Best Practices

1. **Choose the Right Method:**
   - Use `'average'` for statistical analysis
   - Use `'min'` for standard SQL-like ranking
   - Use `'dense'` when you need consecutive ranks
   - Use `'first'` when order matters

2. **Handle Ties Appropriately:**
   - Consider your use case when choosing tie-breaking method
   - Document your choice for reproducibility

3. **Use Percentile Ranks for Normalization:**
   - `pct=true` gives you normalized ranks (0 to 1)
   - Useful for comparing across different datasets

4. **Combine with Other Operations:**
   - Chain with `query()` for filtering
   - Use with `groupBy()` for group-wise ranking
   - Combine with `sort()` for ordered results

## Testing

All window ranking functions have been thoroughly tested with:
- 31 unit tests covering all methods and edge cases
- Tests for ties, empty DataFrames, single rows, and mixed types
- Performance validation with 1000+ row datasets

## See Also

- [Window Functions Summary](WINDOW_FUNCTIONS_SUMMARY.md) - EWM and expanding window functions
- [GroupBy Enhancements](GROUPBY_ENHANCEMENTS_SUMMARY.md) - Group-wise operations
- [Advanced Slicing](ADVANCED_SLICING_SUMMARY.md) - Data selection methods

## References

- SQL Window Functions: https://www.postgresql.org/docs/current/functions-window.html
- Pandas Ranking: https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.rank.html
