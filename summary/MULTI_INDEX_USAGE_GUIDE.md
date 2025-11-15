# MultiIndex Usage Guide with DataFrame

## Overview

This guide shows how to use MultiIndex and specialized indices with DataFrame in DartFrame. MultiIndex provides hierarchical indexing for organizing and analyzing multi-dimensional data.

## Quick Start

### Creating a DataFrame with MultiIndex

```dart
// Method 1: Create MultiIndex separately and set it
var df = DataFrame.fromMap({
  'value': [10, 20, 30, 40]
});

var idx = MultiIndex.fromArrays([
  ['A', 'A', 'B', 'B'],
  [1, 2, 1, 2]
], names: ['letter', 'number']);

var dfIndexed = df.setMultiIndex(idx);

// Method 2: Create from DataFrame columns
var df = DataFrame.fromMap({
  'letter': ['A', 'A', 'B', 'B'],
  'number': [1, 2, 1, 2],
  'value': [10, 20, 30, 40]
});

var dfIndexed = df.setIndexFromColumns(['letter', 'number']);
// Now 'letter' and 'number' are the index, 'value' is the only column
```

## Core Operations

### 1. Setting a MultiIndex

#### From Existing MultiIndex
```dart
var df = DataFrame.fromMap({
  'sales': [100, 150, 120, 180],
  'profit': [20, 30, 25, 35]
});

var idx = MultiIndex.fromArrays([
  ['North', 'North', 'South', 'South'],
  ['Widget', 'Gadget', 'Widget', 'Gadget']
], names: ['region', 'product']);

var dfIndexed = df.setMultiIndex(idx);
```

#### From DataFrame Columns
```dart
var df = DataFrame.fromMap({
  'region': ['North', 'North', 'South', 'South'],
  'product': ['Widget', 'Gadget', 'Widget', 'Gadget'],
  'sales': [100, 150, 120, 180]
});

// Drop the index columns (default)
var dfIndexed = df.setIndexFromColumns(['region', 'product']);

// Keep the index columns
var dfIndexed = df.setIndexFromColumns(['region', 'product'], drop: false);
```

### 2. Selecting Data by MultiIndex

```dart
var df = DataFrame.fromMap({
  'value': [10, 20, 30, 40]
});

var idx = MultiIndex.fromArrays([
  ['A', 'A', 'B', 'B'],
  [1, 2, 1, 2]
]);

var dfIndexed = df.setMultiIndex(idx);

// Select all rows where first level is 'A'
var dfA = dfIndexed.selectByMultiIndex(['A']);
// Returns rows with index ['A', 1] and ['A', 2]

// Select specific tuple
var dfA1 = dfIndexed.selectByMultiIndex(['A', 1]);
// Returns only the row with index ['A', 1]

// Select by second level value
var df1 = dfIndexed.selectByMultiIndex(['B', 1]);
// Returns only the row with index ['B', 1]
```

### 3. Grouping by Index Levels

```dart
var df = DataFrame.fromMap({
  'sales': [100, 150, 120, 180]
});

var idx = MultiIndex.fromArrays([
  ['North', 'North', 'South', 'South'],
  ['Widget', 'Gadget', 'Widget', 'Gadget']
], names: ['region', 'product']);

var dfIndexed = df.setMultiIndex(idx);

// Group by first level (region)
var byRegion = dfIndexed.groupByIndexLevel(0);
// Returns: {'North': DataFrame, 'South': DataFrame}

// Group by second level (product)
var byProduct = dfIndexed.groupByIndexLevel(1);
// Returns: {'Widget': DataFrame, 'Gadget': DataFrame}

// Group by multiple levels
var byBoth = dfIndexed.groupByIndexLevel([0, 1]);
// Returns: {['North', 'Widget']: DataFrame, ...}
```

### 4. Resetting the Index

```dart
var df = DataFrame.fromMap({
  'letter': ['A', 'A', 'B', 'B'],
  'number': [1, 2, 1, 2],
  'value': [10, 20, 30, 40]
});

var dfIndexed = df.setIndexFromColumns(['letter', 'number']);

// Reset and add index as columns
var dfReset = dfIndexed.resetMultiIndex();
// Columns: level_0, level_1, value
// Index: [0, 1, 2, 3]

// Reset and drop the index
var dfReset = dfIndexed.resetMultiIndex(drop: true);
// Columns: value
// Index: [0, 1, 2, 3]
```

### 5. Checking Index Properties

```dart
// Check if DataFrame has MultiIndex
if (df.hasMultiIndex) {
  print('DataFrame has hierarchical index');
}

// Get number of index levels
var levels = df.indexLevels;
print('Number of index levels: $levels');
```

## DatetimeIndex Integration

### Setting a DatetimeIndex

```dart
// Method 1: Create DatetimeIndex separately
var df = DataFrame.fromMap({
  'value': [10, 20, 30, 40, 50]
});

var idx = DatetimeIndex.dateRange(
  start: DateTime(2024, 1, 1),
  periods: 5,
  frequency: 'D',
);

var dfIndexed = df.setDatetimeIndex(idx);

// Method 2: From DataFrame column
var df = DataFrame.fromMap({
  'date': [
    DateTime(2024, 1, 1),
    DateTime(2024, 1, 2),
    DateTime(2024, 1, 3)
  ],
  'value': [10, 20, 30]
});

var dfIndexed = df.setDatetimeIndexFromColumn('date');
```

### Using DatetimeIndex with Time Series Operations

```dart
var df = DataFrame.fromMap({
  'date': [
    DateTime(2024, 1, 1, 9, 0),
    DateTime(2024, 1, 1, 10, 0),
    DateTime(2024, 1, 1, 11, 0),
    DateTime(2024, 1, 1, 12, 0)
  ],
  'temperature': [20, 22, 24, 23]
});

var dfIndexed = df.setDatetimeIndexFromColumn('date');

// Now can use time-based operations
var morning = dfIndexed.atTime('09:00:00');
var shifted = dfIndexed.shift(1);
var lagged = dfIndexed.lag(1);
```

## Real-World Examples

### Example 1: Sales Analysis by Region and Product

```dart
var sales = DataFrame.fromMap({
  'region': ['North', 'North', 'North', 'South', 'South', 'South'],
  'product': ['Widget', 'Gadget', 'Doohickey', 'Widget', 'Gadget', 'Doohickey'],
  'sales': [100, 150, 80, 120, 180, 90],
  'profit': [20, 30, 15, 25, 35, 18]
});

// Set hierarchical index
var salesIndexed = sales.setIndexFromColumns(['region', 'product']);

// Analyze by region
var byRegion = salesIndexed.groupByIndexLevel(0);

for (var entry in byRegion.entries) {
  var region = entry.key;
  var regionData = entry.value;
  var totalSales = regionData['sales'].data.reduce((a, b) => a + b);
  print('$region: \$${totalSales}');
}

// Select specific region
var northSales = salesIndexed.selectByMultiIndex(['North']);
print('North region sales:');
print(northSales);

// Select specific product across all regions
var widgetSales = salesIndexed.selectByMultiIndex(['Widget']);
```

### Example 2: Time Series with Categories

```dart
var data = DataFrame.fromMap({
  'category': ['Electronics', 'Electronics', 'Clothing', 'Clothing'],
  'date': [
    DateTime(2024, 1, 1),
    DateTime(2024, 1, 2),
    DateTime(2024, 1, 1),
    DateTime(2024, 1, 2)
  ],
  'quantity': [5, 8, 12, 15],
  'revenue': [500, 800, 240, 300]
});

// Create hierarchical index with category and date
var indexed = data.setIndexFromColumns(['category', 'date']);

// Analyze by category
var byCategory = indexed.groupByIndexLevel(0);

print('Electronics:');
print(byCategory['Electronics']);

print('Clothing:');
print(byCategory['Clothing']);

// Reset to get back original structure
var original = indexed.resetMultiIndex();
```

### Example 3: Multi-Level Aggregation

```dart
var employees = DataFrame.fromMap({
  'department': ['Sales', 'Sales', 'IT', 'IT', 'HR', 'HR'],
  'team': ['A', 'B', 'A', 'B', 'A', 'B'],
  'employee': ['John', 'Jane', 'Bob', 'Alice', 'Charlie', 'Diana'],
  'salary': [50000, 55000, 60000, 65000, 45000, 48000]
});

var indexed = employees.setIndexFromColumns(['department', 'team']);

// Group by department
var byDept = indexed.groupByIndexLevel(0);

print('Department Totals:');
for (var entry in byDept.entries) {
  var dept = entry.key;
  var deptData = entry.value;
  var totalSalary = deptData['salary'].data.reduce((a, b) => a + b);
  var avgSalary = totalSalary / deptData.rowCount;
  print('$dept: Total=\$${totalSalary}, Average=\$${avgSalary}');
}

// Group by team
var byTeam = indexed.groupByIndexLevel(1);

print('\nTeam Totals:');
for (var entry in byTeam.entries) {
  var team = entry.key;
  var teamData = entry.value;
  var totalSalary = teamData['salary'].data.reduce((a, b) => a + b);
  print('Team $team: \$${totalSalary}');
}
```

### Example 4: Stock Data with DatetimeIndex

```dart
var stocks = DataFrame.fromMap({
  'date': [
    DateTime(2024, 1, 1),
    DateTime(2024, 1, 2),
    DateTime(2024, 1, 3),
    DateTime(2024, 1, 4),
    DateTime(2024, 1, 5)
  ],
  'price': [100, 102, 98, 105, 103],
  'volume': [1000, 1500, 800, 2000, 1200]
});

// Set datetime index
var stocksIndexed = stocks.setDatetimeIndexFromColumn('date');

// Calculate returns
stocksIndexed['prev_price'] = stocksIndexed.lag(1)['price'].data;
stocksIndexed['return'] = stocksIndexed.eval('(price - prev_price) / prev_price * 100');

// Resample to weekly
var weekly = stocksIndexed.resampleOHLC('W', valueColumn: 'price');
```

## Best Practices

### 1. When to Use MultiIndex

Use MultiIndex when you have:
- Hierarchical or nested data structures
- Multiple categorical dimensions
- Data that naturally groups at multiple levels
- Need for efficient multi-level aggregation

### 2. Choosing Index Columns

Good index columns are:
- Categorical or discrete values
- Values you frequently filter or group by
- Natural hierarchies (region → city, category → subcategory)

Avoid using:
- Continuous numeric values
- Unique identifiers (unless needed for joins)
- High-cardinality columns (too many unique values)

### 3. Performance Considerations

- MultiIndex operations are efficient for grouping and selection
- Keep index levels to 2-3 for best performance
- Use `drop=true` when setting index to reduce memory usage
- Reset index when you need to perform column-based operations

### 4. Working with MultiIndex

```dart
// Good: Set index once, perform multiple operations
var indexed = df.setIndexFromColumns(['region', 'product']);
var north = indexed.selectByMultiIndex(['North']);
var byRegion = indexed.groupByIndexLevel(0);

// Less efficient: Reset and re-index repeatedly
var indexed = df.setIndexFromColumns(['region', 'product']);
var reset = indexed.resetMultiIndex();
var reindexed = reset.setIndexFromColumns(['region', 'product']);
```

## Common Patterns

### Pattern 1: Hierarchical Aggregation

```dart
// Start with flat data
var data = df.setIndexFromColumns(['level1', 'level2']);

// Aggregate at different levels
var byLevel1 = data.groupByIndexLevel(0);
var byLevel2 = data.groupByIndexLevel(1);
var byBoth = data.groupByIndexLevel([0, 1]);
```

### Pattern 2: Drill-Down Analysis

```dart
// Start broad
var all = dfIndexed.selectByMultiIndex([]);

// Drill down to specific category
var category = dfIndexed.selectByMultiIndex(['Electronics']);

// Drill down further
var specific = dfIndexed.selectByMultiIndex(['Electronics', 'Laptop']);
```

### Pattern 3: Temporary Indexing

```dart
// Set index for specific operations
var indexed = df.setIndexFromColumns(['key1', 'key2']);

// Perform operations
var filtered = indexed.selectByMultiIndex(['value']);
var grouped = indexed.groupByIndexLevel(0);

// Reset when done
var final = indexed.resetMultiIndex();
```

## API Reference

### DataFrame Methods

```dart
// MultiIndex operations
DataFrame setMultiIndex(MultiIndex multiIndex)
DataFrame setIndexFromColumns(List<String> columns, {bool drop = true})
DataFrame resetMultiIndex({bool drop = false})
DataFrame selectByMultiIndex(List<dynamic> values)
Map<dynamic, DataFrame> groupByIndexLevel(dynamic level)

// DatetimeIndex operations
DataFrame setDatetimeIndex(DatetimeIndex datetimeIndex)
DataFrame setDatetimeIndexFromColumn(String column, {bool drop = true})

// Properties
bool hasMultiIndex
bool hasDatetimeIndex
int indexLevels
```

## Troubleshooting

### Issue: "MultiIndex length must match DataFrame length"
**Solution:** Ensure your MultiIndex has the same number of elements as DataFrame rows.

### Issue: "Column not found"
**Solution:** Check column names are correct when using `setIndexFromColumns()`.

### Issue: "DataFrame does not have a MultiIndex"
**Solution:** Use `setMultiIndex()` or `setIndexFromColumns()` before calling MultiIndex-specific methods.

### Issue: Selection returns empty DataFrame
**Solution:** Check that your selection values match the actual index values (case-sensitive).

## Summary

MultiIndex provides powerful hierarchical indexing for DataFrame:
- ✅ Create from arrays, tuples, or DataFrame columns
- ✅ Select data by index levels
- ✅ Group by index levels
- ✅ Reset index when needed
- ✅ Integrate with time series operations
- ✅ Efficient multi-level aggregation

Use MultiIndex when you need to organize and analyze data with natural hierarchies or multiple dimensions.
