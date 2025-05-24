


          
# DataFrame Class Documentation

The `DataFrame` class in DartFrame provides a powerful 2-dimensional labeled data structure similar to those found in popular data analysis libraries like pandas. It allows for columns of potentially different types and offers a comprehensive set of methods for data manipulation, analysis, and transformation.

## Table of Contents

- [DataFrame Class Documentation](#dataframe-class-documentation)
  - [Table of Contents](#table-of-contents)
  - [Creating a DataFrame](#creating-a-dataframe)
    - [1. Constructor (`DataFrame()`)](#1-constructor-dataframe)
    - [2. `DataFrame.empty()`](#2-dataframeempty)
    - [3. `DataFrame.fromCSV()`](#3-dataframefromcsv)
    - [4. `DataFrame.fromJson()`](#4-dataframefromjson)
    - [5. `DataFrame.fromMap()`](#5-dataframefrommap)
    - [6. `DataFrame.fromRows()`](#6-dataframefromrows)
    - [7. `DataFrame.fromNames()`](#7-dataframefromnames)
    - [8. Understanding Missing Data Handling](#8-understanding-missing-data-handling)
  - [Accessing Data](#accessing-data)
    - [1. Accessing Columns](#1-accessing-columns)
    - [2. Accessing Rows](#2-accessing-rows)
    - [3. Accessing Single Elements](#3-accessing-single-elements)
    - [4. Position-Based Selection (`iloc`)](#4-position-based-selection-iloc)
    - [5. Label-Based Selection (`loc`)](#5-label-based-selection-loc)
    - [6. DataFrame Properties](#6-dataframe-properties)
  - [Modifying Data](#modifying-data)
    - [1. Setting Columns](#1-setting-columns)
    - [2. Adding Rows](#2-adding-rows)
    - [3. Updating Cell Values](#3-updating-cell-values)
  - [Handling Missing Data](#handling-missing-data)
    - [1. Identifying Missing Data](#1-identifying-missing-data)
    - [2. Filling Missing Data](#2-filling-missing-data)
    - [3. Dropping Missing Data](#3-dropping-missing-data)
  - [Data Transformation](#data-transformation)
    - [1. Binning / Discretization](#1-binning--discretization)
    - [2. One-Hot Encoding](#2-one-hot-encoding)
  - [Reshaping and Pivoting](#reshaping-and-pivoting)
    - [1. Pivot Table](#1-pivot-table)
    - [2. Strict Pivot](#2-strict-pivot)
    - [3. Crosstabulation](#3-crosstabulation)
  - [Combining DataFrames](#combining-dataframes)
    - [1. Joining DataFrames](#1-joining-dataframes)
    - [2. Concatenating DataFrames](#2-concatenating-dataframes)
  - [Common Operations](#common-operations)
    - [1. Descriptive Statistics](#1-descriptive-statistics)
    - [2. Viewing Data](#2-viewing-data)
    - [3. Grouping Data](#3-grouping-data)
    - [4. Value Counts](#4-value-counts)
    - [5. Replacing Values](#5-replacing-values)
    - [6. Renaming Columns](#6-renaming-columns)
    - [7. Dropping Columns/Rows](#7-dropping-columnsrows)
    - [8. Shuffling Data](#8-shuffling-data)
    - [9. Exporting Data](#9-exporting-data)

## Creating a DataFrame

There are several ways to create a `DataFrame`:

### 1. Constructor (`DataFrame()`)

Create a DataFrame directly by providing data as a list of lists, with optional column names and index.

**Syntax:**
```dart
DataFrame(
  List<List<dynamic>>? data, {
  List<dynamic> columns = const [],
  List<dynamic> index = const [],
  bool allowFlexibleColumns = false,
  dynamic replaceMissingValueWith,
  List<dynamic> missingDataIndicator = const [],
  bool formatData = false,
})
```

**Parameters:**
- `data`: A list of rows, where each row is a list of values.
- `columns`: (Optional) A list of column names. If not provided and `data` is not null, columns will be auto-named.
- `index`: (Optional) A list to use as the index for the DataFrame. If not provided, a default integer index will be generated.
- `allowFlexibleColumns`: (Optional) If `true`, allows operations that might change the number of columns. Defaults to `false`.
- `replaceMissingValueWith`: (Optional) A value to replace any missing data.
- `missingDataIndicator`: (Optional) A list of values to be treated as missing data.
- `formatData`: (Optional) If `true`, attempts to clean data types and handle missing values. Defaults to `false`.

**Example:**
```dart
// Basic instantiation
final df = DataFrame([
  [1, 2, 3.0], 
  [4, 5, 6], 
  [7, 'hi', 9]
], 
index: ['RowA', 'RowB', 'RowC'], 
columns: ['col_int', 'col_str', 'col_float']);

// Handling missing data during construction
final dfMissing = DataFrame(
  [[1, 'NA', 3.0], [null, 5, ''], [7, 'missing', 9]],
  columns: ['A', 'B', 'C'],
  missingDataIndicator: ['NA', 'missing', 'N/A'], // These values will be treated as missing
  replaceMissingValueWith: -1, // Replace missing values with -1
  formatData: true, // Enable processing of missingDataIndicator and nulls/empty strings
);
```

### 2. `DataFrame.empty()`

Creates an empty DataFrame, optionally with predefined column names.

**Syntax:**
```dart
DataFrame.empty({
  List<dynamic>? columns,
  bool allowFlexibleColumns = false,
  dynamic replaceMissingValueWith,
  List<dynamic> missingDataIndicator = const [],
})
```

**Example:**
```dart
final emptyDf = DataFrame.empty(columns: ['Name', 'Age']);
expect(emptyDf.rows, isEmpty);
expect(emptyDf.columns, equals(['Name', 'Age']));
```

### 3. `DataFrame.fromCSV()`

Constructs a DataFrame from a CSV string or file.

**Syntax:**
```dart
DataFrame.fromCSV({
  String? csv,
  String delimiter = ',',
  String? inputFilePath,
  bool hasHeader = true,
  bool formatData = false,
  List<dynamic> missingDataIndicator = const [],
  dynamic replaceMissingValueWith,
})
```

**Example:**
```dart
// From CSV string
final csvString = 'colA,colB\n1,apple\n2,banana';
final dfFromCsv = await DataFrame.fromCSV(csv: csvString);

// With custom delimiter and no header
final csvNoHeader = '1;x\n2;y';
final dfNoHeader = await DataFrame.fromCSV(
  csv: csvNoHeader, 
  delimiter: ';', 
  hasHeader: false
);

// With missing value handling
final csvWithMissing = 'val,cat\n10,A\n,B\n30,NA';
final dfFormattedCsv = await DataFrame.fromCSV(
  csv: csvWithMissing,
  formatData: true,
  missingDataIndicator: ['NA'], // 'NA' strings become missing
  replaceMissingValueWith: -1   // Missing values become -1
);
```

### 4. `DataFrame.fromJson()`

Constructs a DataFrame from a JSON string (list of objects) or file.

**Syntax:**
```dart
DataFrame.fromJson({
  String? jsonString,
  String? inputFilePath,
  bool formatData = false,
  List<dynamic> missingDataIndicator = const [],
  dynamic replaceMissingValueWith,
})
```

**Example:**
```dart
// From JSON string
final jsonString = '[{"name":"John","age":30},{"name":"Jane","age":25}]';
final dfFromJson = await DataFrame.fromJson(jsonString: jsonString);

// With missing value handling
final jsonWithNull = '[{"X": 1, "Y": null}, {"X": null, "Y": "bar"}]';
final dfJsonMissing = await DataFrame.fromJson(
  jsonString: jsonWithNull,
  replaceMissingValueWith: "JSON_NULL",
  formatData: true
);
```

### 5. `DataFrame.fromMap()`

Constructs a DataFrame from a map of column names to lists of column data.

**Syntax:**
```dart
DataFrame.fromMap(
  Map<String, List<dynamic>> map, {
  List<dynamic> index = const [],
  bool allowFlexibleColumns = false,
  dynamic replaceMissingValueWith,
  List<dynamic> missingDataIndicator = const [],
  bool formatData = false,
})
```

**Example:**
```dart
final mapData = {'col1': [1, 2, 3], 'col2': ['a', 'b', 'c']};
final dfFromMap = DataFrame.fromMap(mapData);
// dfFromMap.columns is ['col1', 'col2']
// dfFromMap.rows[0] is [1, 'a']

// With missing value handling
final mapWithNull = {'A': [1, null], 'B': ['x', 'y']};
final dfMapMissing = DataFrame.fromMap(
  mapWithNull,
  replaceMissingValueWith: -999,
  formatData: true
);
// dfMapMissing.rows[1][0] is -999
```

### 6. `DataFrame.fromRows()`

Constructs a DataFrame from a list of maps, where each map represents a row.

**Syntax:**
```dart
DataFrame.fromRows(
  List<Map<dynamic, dynamic>> rows, {
  List<dynamic>? columns,
  List<dynamic> index = const [],
  bool allowFlexibleColumns = false,
  dynamic replaceMissingValueWith,
  List<dynamic> missingDataIndicator = const [],
  bool formatData = false,
})
```

**Example:**
```dart
final dfFromRows = DataFrame.fromRows([
  {'ID': 1, 'Category': 'A', 'Value': 100},
  {'ID': 2, 'Category': 'B', 'Value': 200},
]);
// dfFromRows.columns will be ['ID', 'Category', 'Value']
```

### 7. `DataFrame.fromNames()`

Creates a DataFrame with no rows but with the specified columns.

**Syntax:**
```dart
DataFrame.fromNames(
  List<dynamic> columns, {
  bool allowFlexibleColumns = false,
  dynamic replaceMissingValueWith,
  List missingDataIndicator = const [],
})
```

**Example:**
```dart
final df = DataFrame.fromNames(['Name', 'Age', 'City']);
// Creates an empty DataFrame with columns 'Name', 'Age', and 'City'
```

### 8. Understanding Missing Data Handling

DartFrame provides robust mechanisms for handling missing data:

- **`missingDataIndicator`**: A list of values to be treated as missing data (e.g., `['NA', 'N/A', 'missing']`).
- **`replaceMissingValueWith`**: A value to replace missing data with (e.g., `-1`, `0`, `'MISSING'`).
- **`formatData`**: When `true`, the DataFrame will:
  - Convert strings that match `missingDataIndicator` to missing values
  - Treat `null` and empty strings as missing values
  - Replace all missing values with `replaceMissingValueWith` (if specified)

**Example:**
```dart
// Default behavior (replaceMissingValueWith = null)
final df1 = DataFrame.empty(missingDataIndicator: ['NA']);
expect(df1.cleanData('NA'), isNull);
expect(df1.cleanData(null), isNull);
expect(df1.cleanData(''), isNull);

// With specific replaceMissingValueWith
final df2 = DataFrame.empty(
  missingDataIndicator: ['NA'], 
  replaceMissingValueWith: 'MISSING'
);
expect(df2.cleanData('NA'), equals('MISSING'));
expect(df2.cleanData(null), equals('MISSING'));
```

## Accessing Data

### 1. Accessing Columns

You can access a DataFrame column as a `Series` using its name (String) or integer position (int).

**Example:**
```dart
final df = DataFrame.fromMap({'col1': [1,2], 'col2': ['a','b']});

// Access by name
Series seriesByName = df['col1']; 
// seriesByName.data is [1, 2]

// Access by index
Series seriesByIndex = df[0];    
// seriesByIndex.data is [1, 2]

// Attempting to access a non-existent column throws ArgumentError
expect(() => df['badColumn'], throwsA(isA<ArgumentError>()));
```

### 2. Accessing Rows

Access rows as lists or create a new DataFrame with selected rows.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x'},
  {'A': 2, 'B': 'y'}
]);

// Access all rows
List<List<dynamic>> allRows = df.rows;

// Access a specific row by index
List<dynamic> secondRow = df.rows[1]; // [2, 'y']
```

### 3. Accessing Single Elements

Access individual elements using various methods.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x'},
  {'A': 2, 'B': 'y'}
]);

// Using column then row
var value1 = df['A'][1]; // 2

// Using iloc for positional access
var value2 = df.iloc(0, 1); // 'x'

// Using loc for label-based access (if index is set)
var dfWithIndex = DataFrame.fromRows(
  [{'A': 1, 'B': 'x'}, {'A': 2, 'B': 'y'}],
  index: ['row1', 'row2']
);
var value3 = dfWithIndex.loc('row1', 'B'); // 'x'
```

### 4. Position-Based Selection (`iloc`)

`iloc` allows selection by integer position (0-indexed).

**Example:**
```dart
var df = DataFrame([[1,'a'],[2,'b']], columns:['c1','c2'], index:['r1','r2']);

// Select a single row by position, returns a Series
var secondRow = df.iloc[1]; // secondRow.data is [2, 'b'], name 'r2', index ['c1','c2']

// Select a single element by row and column positions
var value = df.iloc(0, 1); // value is 'a'

// Select specific columns from a single row, returns a Series
var series = df.iloc(0, [1, 0]); // series.data is ['a', 1]

// Select multiple rows, returns a new DataFrame
var newDf = df.iloc[[1, 0]]; // Selects 2nd then 1st row

// Select a single column from multiple rows, returns a Series
var series2 = df.iloc([0, 1], 0); // series2.data is [1, 2]

// Select a sub-DataFrame with multiple rows and columns
var subDf = df.iloc([0, 1], [1, 0]); // Selects rows 0,1 and columns 1,0
```

### 5. Label-Based Selection (`loc`)

`loc` allows selection by index and column labels.

**Example:**
```dart
var dfStrIdx = DataFrame([[1,'a'],[2,'b']], columns:['cA','cB'], index:['rX','rY']);

// Select a single row by label, returns a Series
var rowX = dfStrIdx.loc['rX']; // rowX.data is [1,'a']

// Select a single element by row and column labels
var value = dfStrIdx.loc('rX', 'cB'); // value is 'a'

// Select specific columns from a single row by labels, returns a Series
var series = dfStrIdx.loc('rX', ['cA', 'cB']); // series.data is [1, 'a']

// Select multiple rows by labels, returns a new DataFrame
var newDf = dfStrIdx.loc[['rX', 'rY']];

// Select a single column from multiple rows by labels, returns a Series
var series2 = dfStrIdx.loc(['rX', 'rY'], 'cA'); // series2.data is [1, 2]

// Select a sub-DataFrame with multiple rows and columns by labels
var subDf = dfStrIdx.loc(['rX', 'rY'], ['cA', 'cB']);
```

### 6. DataFrame Properties

Access basic properties of the DataFrame.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x'},
  {'A': 2, 'B': 'y'}
]);

// Get dimensions
var shape = df.shape; // {rows: 2, columns: 2}

// Get index (row labels)
var index = df.index; // [0, 1] (default integer index)

// Get column names
var columns = df.columns; // ['A', 'B']
```

## Modifying Data

### 1. Setting Columns

Add new columns or modify existing ones.

**Example:**
```dart
final df = DataFrame.empty(columns:['A']); 

// Add values to column A
df['A'] = [10, 20]; // If df was empty before, this sets 2 rows for column A

// Add a new column
df['B'] = [30, 40]; // Adds column B
// df.rows would be [[10,30], [20,40]]

// Add the first column to an empty DataFrame
final emptyDf = DataFrame.empty();
emptyDf['col1'] = [1, 2, 3];
// emptyDf.columns is ['col1'], emptyDf.rows is [[1],[2],[3]]

// Set all column names
df.columns = ['New1', 'New2']; // Length must match existing column count unless allowFlexibleColumns is true
```

### 2. Adding Rows

Add new rows to the DataFrame.

**Example:**
```dart
final df = DataFrame.empty();
df.addRow([1, 'apple']); // Columns become 'Column1', 'Column2'. Rows: [[1, 'apple']]
df.addRow([2, 'banana']); // Rows: [[1, 'apple'], [2, 'banana']]

// Add row with specific index label
df.addRow([3, 'cherry'], index: 'row3');
```

### 3. Updating Cell Values

Update individual cell values.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x'},
  {'A': 2, 'B': 'y'}
]);

// Update a cell by row and column indices
df.updateCell(0, 1, 'new_value'); // First row, second column

// Update a cell by row index and column name
df.updateCell(1, 'A', 99); // Second row, column 'A'
```

## Handling Missing Data

### 1. Identifying Missing Data

Identify missing values in your DataFrame.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x', 'C': null},
  {'A': null, 'B': 'y', 'C': true},
  {'A': 3, 'B': null, 'C': false},
]);

// Check for missing values in the entire DataFrame
DataFrame missingMask = df.isna();
// missingMask contains boolean values (true where value is missing)

// Check for non-missing values
DataFrame validMask = df.notna();

// Check for missing values in a specific column
Series colMissing = df['A'].isna();
// colMissing.data is [false, true, false]

// With custom missing value
final dfCustomMissing = DataFrame.fromRows([
  {'P': 10, 'Q': 'val1'},
  {'P': -99, 'Q': 'MISSING'},
  {'P': 30, 'Q': 'val2'},
], replaceMissingValueWith: -99);

Series customMissing = dfCustomMissing['P'].isna();
// customMissing.data is [false, true, false]
```

### 2. Filling Missing Data

Replace missing values with specified values.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x', 'C': null},
  {'A': null, 'B': 'y', 'C': true},
]);

// Fill all missing values with a single value
DataFrame filled = df.fillna(0);
// filled.rows[0][2] is 0, filled.rows[1][0] is 0

// Fill with different values for each column
DataFrame filledByCol = df.fillna({'A': -1, 'C': false});
// filledByCol.rows[1][0] is -1, filledByCol.rows[0][2] is false

// Fill forward (use previous valid value)
DataFrame filledForward = df.fillna(method: 'ffill');

// Fill backward (use next valid value)
DataFrame filledBackward = df.fillna(method: 'bfill');
```

### 3. Dropping Missing Data

Remove rows or columns with missing values.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x', 'C': null},
  {'A': null, 'B': 'y', 'C': true},
  {'A': 3, 'B': null, 'C': false},
]);

// Drop rows with any missing values
DataFrame cleanRows = df.dropna();
// cleanRows has 0 rows (all rows have at least one missing value)

// Drop rows only if all values are missing
DataFrame someCleanRows = df.dropna(how: 'all');
// someCleanRows has 3 rows (no row has all missing values)

// Drop rows if specific columns have missing values
DataFrame filteredRows = df.dropna(subset: ['A', 'B']);
// filteredRows has 0 rows (all rows have missing values in A or B)

// Drop columns with any missing values
DataFrame cleanCols = df.dropna(axis: 'columns');
// cleanCols has 0 columns (all columns have at least one missing value)
```

## Data Transformation

### 1. Binning / Discretization

Bin continuous data into discrete intervals.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'Value': 5},
  {'Value': 15},
  {'Value': 25},
  {'Value': 35},
  {'Value': 45},
]);

// Create bins with equal width
DataFrame binned = df.bin(
  column: 'Value',
  bins: 3,
  labels: ['Low', 'Medium', 'High']
);
// New column 'Value_bin' contains: ['Low', 'Low', 'Medium', 'High', 'High']

// Create bins with custom boundaries
DataFrame customBinned = df.bin(
  column: 'Value',
  binEdges: [0, 10, 30, 50],
  labels: ['Low', 'Medium', 'High']
);
```

### 2. One-Hot Encoding

Convert categorical variables into a one-hot encoded format.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'ID': 1, 'Category': 'A', 'Value': 100},
  {'ID': 2, 'Category': 'B', 'Value': 200},
  {'ID': 3, 'Category': 'A', 'Value': 300},
  {'ID': 4, 'Category': 'C', 'Value': 400},
]);

// One-hot encode a single column
DataFrame encoded = df.getDummies(['Category']);
// Result contains columns: 'ID', 'Value', 'Category_A', 'Category_B', 'Category_C'
// 'Category_A' column contains: [1, 0, 1, 0]
// 'Category_B' column contains: [0, 1, 0, 0]
// 'Category_C' column contains: [0, 0, 0, 1]

// With custom prefix
DataFrame encodedCustom = df.getDummies(['Category'], prefix: 'Type');
// Result contains: 'ID', 'Value', 'Type_A', 'Type_B', 'Type_C'

// With custom separator
DataFrame encodedSep = df.getDummies(['Category'], prefixSep: '|');
// Result contains: 'ID', 'Value', 'Category|A', 'Category|B', 'Category|C'

// Drop first category (useful for avoiding multicollinearity)
DataFrame encodedDrop = df.getDummies(['Category'], dropFirst: true);
// Result contains: 'ID', 'Value', 'Category_B', 'Category_C' (Category_A is dropped)

// Handle null values
final dfWithNull = DataFrame.fromRows([
  {'ID': 1, 'Category': 'A'},
  {'ID': 2, 'Category': null},
]);
DataFrame encodedNull = dfWithNull.getDummies(['Category'], dummyNA: true);
// Result contains: 'ID', 'Category_A', 'Category_na'
```

## Reshaping and Pivoting

### 1. Pivot Table

Create a spreadsheet-style pivot table from DataFrame data.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 'foo', 'B': 'one', 'C': 1, 'D': 10},
  {'A': 'foo', 'B': 'one', 'C': 2, 'D': 20},
  {'A': 'foo', 'B': 'two', 'C': 3, 'D': 30},
  {'A': 'bar', 'B': 'one', 'C': 4, 'D': 40},
  {'A': 'bar', 'B': 'two', 'C': 5, 'D': 50},
  {'A': 'bar', 'B': 'two', 'C': 6, 'D': 60},
]);

// Basic pivot table with mean aggregation (default)
DataFrame pivoted = df.pivotTable(index: 'A', columns: 'B', values: 'C');
// Result:
// A | one | two
//---|-----|----
//foo| 1.5 | 3.0
//bar| 4.0 | 5.5

// With sum aggregation
DataFrame pivotedSum = df.pivotTable(
  index: 'A', 
  columns: 'B', 
  values: 'C', 
  aggFunc: 'sum'
);
// foo/one cell contains 3 (1+2)

// With count aggregation
DataFrame pivotedCount = df.pivotTable(
  index: 'A', 
  columns: 'B', 
  values: 'C', 
  aggFunc: 'count'
);
// foo/one cell contains 2 (two values)

// With fill value for missing combinations
DataFrame pivotedFill = df.pivotTable(
  index: 'A', 
  columns: 'B', 
  values: 'C', 
  fillValue: 0
);
// Any missing combinations will be filled with 0
```

### 2. Strict Pivot

Reshape data without aggregation (requires unique index/column combinations).

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 'foo', 'B': 'one', 'C': 10},
  {'A': 'foo', 'B': 'two', 'C': 20},
  {'A': 'bar', 'B': 'one', 'C': 30},
  {'A': 'bar', 'B': 'two', 'C': 40},
]);

// Basic pivot
DataFrame pivoted = df.pivot(index: 'A', columns: 'B', values: 'C');
// Result:
// A | one | two
//---|-----|----
//bar| 30  | 40
//foo| 10  | 20

// Pivot throws error on duplicate index/column pairs
final dfDuplicate = DataFrame.fromRows([
  {'A': 'foo', 'B': 'one', 'C': 10},
  {'A': 'foo', 'B': 'one', 'C': 20}, // Duplicate
]);
// dfDuplicate.pivot(index: 'A', columns: 'B', values: 'C') throws ArgumentError

// Pivot with implicit value column (when only one remains)
final dfImplicit = DataFrame.fromRows([
  {'index_col': 'idx1', 'column_col': 'colA', 'value_col': 100},
  {'index_col': 'idx1', 'column_col': 'colB', 'value_col': 200},
]);
DataFrame pivotedImplicit = dfImplicit.pivot(
  index: 'index_col', 
  columns: 'column_col'
); // values='value_col' inferred
```

### 3. Crosstabulation

Compute a simple cross-tabulation of two (or more) factors.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 'foo', 'B': 'one'},
  {'A': 'foo', 'B': 'two'},
  {'A': 'foo', 'B': 'one'},
  {'A': 'bar', 'B': 'two'},
]);

// Basic crosstab
DataFrame crosstabResult = DataFrame.crosstab(df['A'], df['B']);
// Result:
// A   | one | two
//-----|-----|----
// bar |  0  |  1
// foo |  2  |  1

// With normalization (proportions)
DataFrame crosstabNorm = DataFrame.crosstab(
  df['A'], 
  df['B'], 
  normalize: true
);
// Result shows proportions of total

// With custom aggregation function
DataFrame crosstabCustom = DataFrame.crosstab(
  df['A'], 
  df['B'], 
  values: df['C'], 
  aggFunc: 'sum'
);
```

## Combining DataFrames

### 1. Joining DataFrames

Combine DataFrames using database-style joins.

**Example:**
```dart
final df1 = DataFrame.fromRows([
  {'key': 'K0', 'A': 'A0', 'B': 'B0'},
  {'key': 'K1', 'A': 'A1', 'B': 'B1'},
  {'key': 'K2', 'A': 'A2', 'B': 'B2'},
  {'key': 'K3', 'A': 'A3', 'B': 'B3'},
]);

final df2 = DataFrame.fromRows([
  {'key': 'K0', 'C': 'C0', 'D': 'D0'},
  {'key': 'K1', 'C': 'C1', 'D': 'D1'},
  {'key': 'K2', 'C': 'C2', 'D': 'D2'},
  {'key': 'K4', 'C': 'C3', 'D': 'D3'}, // K4 is unique to df2
]);

// Inner join
DataFrame innerJoin = df1.join(df2, on: 'key', how: 'inner');
// Result has 3 rows (K0, K1, K2) and columns


### 2. Strict Pivot

Reshape data without aggregation (requires unique index/column combinations).

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 'foo', 'B': 'one', 'C': 10},
  {'A': 'foo', 'B': 'two', 'C': 20},
  {'A': 'bar', 'B': 'one', 'C': 30},
  {'A': 'bar', 'B': 'two', 'C': 40},
]);

// Basic pivot (no aggregation)
DataFrame pivoted = df.pivot(index: 'A', columns: 'B', values: 'C');
// Result:
// A | one | two
//---|-----|----
//foo| 10  | 20
//bar| 30  | 40

// If there are duplicate index/column combinations, an error will be thrown
final dfDuplicates = DataFrame.fromRows([
  {'A': 'foo', 'B': 'one', 'C': 10},
  {'A': 'foo', 'B': 'one', 'C': 20}, // Duplicate combination
]);
// dfDuplicates.pivot(index: 'A', columns: 'B', values: 'C') will throw an error
```

### 3. Crosstabulation

Create a frequency table of the factors.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 'foo', 'B': 'one'},
  {'A': 'foo', 'B': 'two'},
  {'A': 'foo', 'B': 'one'},
  {'A': 'bar', 'B': 'one'},
  {'A': 'bar', 'B': 'two'},
  {'A': 'bar', 'B': 'two'},
]);

// Basic crosstab (counts occurrences)
DataFrame crosstabbed = DataFrame.crosstab(df['A'], df['B']);
// Result:
// A | one | two
//---|-----|----
//foo| 2   | 1
//bar| 1   | 2

// With normalized values (row proportions)
DataFrame normalizedCrosstab = DataFrame.crosstab(
  df['A'], 
  df['B'], 
  normalize: 'index'
);
// Result:
// A | one    | two
//---|--------|--------
//foo| 0.6667 | 0.3333
//bar| 0.3333 | 0.6667
```

## Combining DataFrames

### 1. Joining DataFrames

Merge DataFrames based on common columns or indices.

**Example:**
```dart
final df1 = DataFrame.fromRows([
  {'key': 'A', 'value1': 1},
  {'key': 'B', 'value1': 2},
]);

final df2 = DataFrame.fromRows([
  {'key': 'A', 'value2': 'x'},
  {'key': 'C', 'value2': 'z'},
]);

// Inner join (only keep matching keys)
DataFrame innerJoin = df1.join(
  df2, 
  on: 'key', 
  how: 'inner'
);
// Result has 1 row: {'key': 'A', 'value1': 1, 'value2': 'x'}

// Left join (keep all rows from left DataFrame)
DataFrame leftJoin = df1.join(
  df2, 
  on: 'key', 
  how: 'left'
);
// Result has 2 rows:
// {'key': 'A', 'value1': 1, 'value2': 'x'}
// {'key': 'B', 'value1': 2, 'value2': null}

// Right join (keep all rows from right DataFrame)
DataFrame rightJoin = df1.join(
  df2, 
  on: 'key', 
  how: 'right'
);
// Result has 2 rows:
// {'key': 'A', 'value1': 1, 'value2': 'x'}
// {'key': 'C', 'value1': null, 'value2': 'z'}

// Outer join (keep all rows from both DataFrames)
DataFrame outerJoin = df1.join(
  df2, 
  on: 'key', 
  how: 'outer'
);
// Result has 3 rows:
// {'key': 'A', 'value1': 1, 'value2': 'x'}
// {'key': 'B', 'value1': 2, 'value2': null}
// {'key': 'C', 'value1': null, 'value2': 'z'}

// Join on multiple columns
final dfMulti1 = DataFrame.fromRows([
  {'key1': 'A', 'key2': 'X', 'value1': 1},
  {'key1': 'B', 'key2': 'Y', 'value1': 2},
]);

final dfMulti2 = DataFrame.fromRows([
  {'key1': 'A', 'key2': 'X', 'value2': 'x'},
  {'key1': 'C', 'key2': 'Z', 'value2': 'z'},
]);

DataFrame multiJoin = dfMulti1.join(
  dfMulti2, 
  on: ['key1', 'key2'], 
  how: 'inner'
);
// Result has 1 row: {'key1': 'A', 'key2': 'X', 'value1': 1, 'value2': 'x'}
```

### 2. Concatenating DataFrames

Combine DataFrames by stacking them vertically or horizontally.

**Example:**
```dart
final df1 = DataFrame.fromRows([
  {'A': 1, 'B': 2},
  {'A': 3, 'B': 4},
]);

final df2 = DataFrame.fromRows([
  {'A': 5, 'B': 6},
  {'A': 7, 'B': 8},
]);

// Vertical concatenation (stack rows)
DataFrame verticalConcat = DataFrame.concatenate([df1, df2]);
// Result has 4 rows:
// {'A': 1, 'B': 2}
// {'A': 3, 'B': 4}
// {'A': 5, 'B': 6}
// {'A': 7, 'B': 8}

// With different columns
final df3 = DataFrame.fromRows([
  {'A': 9, 'C': 10},
  {'A': 11, 'C': 12},
]);

// Vertical concatenation with different columns
DataFrame mixedConcat = DataFrame.concatenate([df1, df3]);
// Result has 4 rows:
// {'A': 1, 'B': 2, 'C': null}
// {'A': 3, 'B': 4, 'C': null}
// {'A': 9, 'B': null, 'C': 10}
// {'A': 11, 'B': null, 'C': 12}

// Horizontal concatenation (stack columns)
final df4 = DataFrame.fromRows([
  {'C': 'x', 'D': true},
  {'C': 'y', 'D': false},
]);

DataFrame horizontalConcat = DataFrame.concatenate(
  [df1, df4], 
  axis: 'columns'
);
// Result has 2 rows:
// {'A': 1, 'B': 2, 'C': 'x', 'D': true}
// {'A': 3, 'B': 4, 'C': 'y', 'D': false}
```

## Common Operations

### 1. Descriptive Statistics

Calculate summary statistics for numeric columns.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 10, 'C': 'x'},
  {'A': 2, 'B': 20, 'C': 'y'},
  {'A': 3, 'B': 30, 'C': 'z'},
  {'A': 4, 'B': 40, 'C': 'w'},
]);

// Get summary statistics for all numeric columns
DataFrame stats = df.describe();
// Result contains rows for count, mean, std, min, 25%, 50%, 75%, max
// Only for columns A and B (C is non-numeric)

// Calculate specific statistics
double mean = df['A'].mean(); // 2.5
double sum = df['B'].sum(); // 100
double min = df['A'].min(); // 1
double max = df['B'].max(); // 40
double median = df['A'].median(); // 2.5
double variance = df['B'].variance(); // 166.67
double stdDev = df['A'].std(); // 1.29
```

### 2. Viewing Data

View subsets of the DataFrame.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'a'},
  {'A': 2, 'B': 'b'},
  {'A': 3, 'B': 'c'},
  {'A': 4, 'B': 'd'},
  {'A': 5, 'B': 'e'},
  {'A': 6, 'B': 'f'},
  {'A': 7, 'B': 'g'},
  {'A': 8, 'B': 'h'},
  {'A': 9, 'B': 'i'},
  {'A': 10, 'B': 'j'},
]);

// Get first n rows
DataFrame first5 = df.head(); // Default is 5 rows
DataFrame first3 = df.head(3);

// Get last n rows
DataFrame last5 = df.tail(); // Default is 5 rows
DataFrame last2 = df.tail(2);

// Get a sample of rows
DataFrame sample = df.sample(3); // Random 3 rows

// Get a specific number of rows from the beginning
DataFrame limited = df.limit(4); // First 4 rows
```

### 3. Grouping Data

Group data by one or more columns and apply aggregation functions.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'Category': 'A', 'Value': 10, 'Count': 1},
  {'Category': 'B', 'Value': 20, 'Count': 2},
  {'Category': 'A', 'Value': 30, 'Count': 3},
  {'Category': 'B', 'Value': 40, 'Count': 4},
  {'Category': 'A', 'Value': 50, 'Count': 5},
]);

// Group by a single column and calculate mean
DataFrame grouped = df.groupBy(['Category']).mean();
// Result:
// Category | Value | Count
//----------|-------|------
// A        | 30    | 3
// B        | 30    | 3

// Group by a single column and calculate sum
DataFrame groupedSum = df.groupBy(['Category']).sum();
// Result:
// Category | Value | Count
//----------|-------|------
// A        | 90    | 9
// B        | 60    | 6

// Group by a single column and calculate multiple aggregations
DataFrame groupedMulti = df.groupBy(['Category']).agg({
  'Value': ['mean', 'sum', 'min', 'max'],
  'Count': ['sum']
});
// Result contains columns:
// Category, Value_mean, Value_sum, Value_min, Value_max, Count_sum

// Group by multiple columns
final dfMulti = DataFrame.fromRows([
  {'Category': 'A', 'SubCat': 'X', 'Value': 10},
  {'Category': 'A', 'SubCat': 'Y', 'Value': 20},
  {'Category': 'B', 'SubCat': 'X', 'Value': 30},
  {'Category': 'B', 'SubCat': 'Y', 'Value': 40},
]);

DataFrame groupedMultiCol = dfMulti.groupBy(['Category', 'SubCat']).mean();
// Result:
// Category | SubCat | Value
//----------|--------|------
// A        | X      | 10
// A        | Y      | 20
// B        | X      | 30
// B        | Y      | 40
```

### 4. Value Counts

Count the occurrences of unique values in a column.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'Category': 'A', 'Value': 10},
  {'Category': 'B', 'Value': 20},
  {'Category': 'A', 'Value': 30},
  {'Category': 'B', 'Value': 20},
  {'Category': 'A', 'Value': 10},
]);

// Count occurrences of each unique value in a column
Series categoryCounts = df['Category'].valueCounts();
// categoryCounts.data is [3, 2]
// categoryCounts.index is ['A', 'B']

// Count occurrences of each unique value in a column with normalization
Series normalizedCounts = df['Category'].valueCounts(normalize: true);
// normalizedCounts.data is [0.6, 0.4]
// normalizedCounts.index is ['A', 'B']

// Count occurrences of each unique value in a column, sorted by value
Series sortedCounts = df['Value'].valueCounts(sort: true);
// sortedCounts.data is [2, 2, 1]
// sortedCounts.index is [10, 20, 30]
```

### 5. Replacing Values

Replace values in the DataFrame.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x'},
  {'A': 2, 'B': 'y'},
  {'A': 3, 'B': 'z'},
]);

// Replace a single value
DataFrame replaced = df.replace(1, 100);
// replaced.rows[0][0] is 100

// Replace multiple values
DataFrame multiReplaced = df.replace({'A': {2: 200, 3: 300}});
// multiReplaced.rows[1][0] is 200
// multiReplaced.rows[2][0] is 300

// Replace values in-place
df.replaceInPlace('y', 'Y');
// df.rows[1][1] is 'Y'

// Replace using regex
DataFrame regexReplaced = df.replace('z', 'Z', regex: true);
// regexReplaced.rows[2][1] is 'Z'
```

### 6. Renaming Columns

Rename columns in the DataFrame.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x'},
  {'A': 2, 'B': 'y'},
]);

// Rename specific columns
DataFrame renamed = df.rename({'A': 'Alpha', 'B': 'Beta'});
// renamed.columns is ['Alpha', 'Beta']

// Rename columns using a function
DataFrame funcRenamed = df.rename((name) => 'Col_$name');
// funcRenamed.columns is ['Col_A', 'Col_B']
```

### 7. Dropping Columns/Rows

Remove columns or rows from the DataFrame.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x', 'C': true},
  {'A': 2, 'B': 'y', 'C': false},
  {'A': 3, 'B': 'z', 'C': true},
]);

// Drop columns
DataFrame droppedCols = df.drop(['B', 'C'], axis: 'columns');
// droppedCols.columns is ['A']

// Drop rows by index
DataFrame droppedRows = df.drop([0, 2]);
// droppedRows has 1 row: {'A': 2, 'B': 'y', 'C': false}

// Drop rows by condition
DataFrame filteredRows = df.where((row) => row[0] > 1);
// filteredRows has 2 rows (where A > 1)
```

### 8. Shuffling Data

Randomly reorder the rows of the DataFrame.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x'},
  {'A': 2, 'B': 'y'},
  {'A': 3, 'B': 'z'},
  {'A': 4, 'B': 'w'},
]);

// Shuffle all rows
DataFrame shuffled = df.shuffle();
// Rows are in random order

// Shuffle with a specific random seed for reproducibility
DataFrame seededShuffle = df.shuffle(seed: 42);
// Rows are shuffled consistently with the same seed
```

### 9. Exporting Data

Export the DataFrame to various formats.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x'},
  {'A': 2, 'B': 'y'},
]);

// Export to CSV
String csv = df.toCSV();
// csv is "A,B\n1,x\n2,y"

// Export to CSV with custom delimiter
String csvTab = df.toCSV(delimiter: '\t');
// csvTab is "A\tB\n1\tx\n2\ty"

// Export to JSON
String json = df.toJSON();
// json is '[{"A":1,"B":"x"},{"A":2,"B":"y"}]'

// Export to a map of columns
Map<String, List<dynamic>> map = df.toMap();
// map is {'A': [1, 2], 'B': ['x', 'y']}

// Export to a list of row maps
List<Map<dynamic, dynamic>> rows = df.toRows();
// rows is [{'A': 1, 'B': 'x'}, {'A': 2, 'B': 'y'}]
```

## Advanced Features

### 1. Filtering Data

Filter rows based on conditions.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 'x', 'C': true},
  {'A': 2, 'B': 'y', 'C': false},
  {'A': 3, 'B': 'z', 'C': true},
  {'A': 4, 'B': 'w', 'C': false},
]);

// Filter rows where column A > 2
DataFrame filtered = df.where((row) {
  return row[df.columns.indexOf('A')] > 2;
});
// filtered has 2 rows: rows 2 and 3

// Filter rows where column C is true
DataFrame boolFiltered = df.where((row) {
  return row[df.columns.indexOf('C')] == true;
});
// boolFiltered has 2 rows: rows 0 and 2

// Multiple conditions
DataFrame multiFiltered = df.where((row) {
  final a = row[df.columns.indexOf('A')];
  final c = row[df.columns.indexOf('C')];
  return a > 1 && c == true;
});
// multiFiltered has 1 row: row 2
```

### 2. Sorting Data

Sort the DataFrame by one or more columns.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 3, 'B': 'x'},
  {'A': 1, 'B': 'z'},
  {'A': 2, 'B': 'y'},
]);

// Sort by a single column (ascending)
DataFrame sorted = df.sort('A');
// sorted rows are in order of A: 1, 2, 3

// Sort by a single column (descending)
DataFrame sortedDesc = df.sort('A', ascending: false);
// sortedDesc rows are in order of A: 3, 2, 1

// Sort by multiple columns
DataFrame multiSorted = df.sortMultiple([
  {'column': 'B', 'ascending': true},
  {'column': 'A', 'ascending': false},
]);
// multiSorted rows are sorted first by B, then by A
```

### 3. Applying Functions

Apply functions to DataFrame elements, rows, or columns.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 10},
  {'A': 2, 'B': 20},
]);

// Apply a function to each element
DataFrame applied = df.applyMap((value, row, col) {
  return value * 2;
});
// applied.rows is [[2, 20], [4, 40]]

// Apply a function to each column
DataFrame colApplied = df.apply((series) {
  return series.map((value) => value + 1).toList();
});
// colApplied.rows is [[2, 11], [3, 21]]

// Apply a function to specific columns
DataFrame specificColApplied = df.applyToColumns(['A'], (value) {
  return value * 10;
});
// specificColApplied.rows is [[10, 10], [20, 20]]
```

### 4. Correlation and Covariance

Calculate correlation and covariance between numeric columns.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 10, 'C': 100},
  {'A': 2, 'B': 20, 'C': 50},
  {'A': 3, 'B': 30, 'C': 0},
]);

// Calculate correlation matrix
DataFrame corr = df.corr();
// corr contains correlation coefficients between all numeric columns

// Calculate covariance matrix
DataFrame cov = df.cov();
// cov contains covariance values between all numeric columns

// Calculate correlation between two specific columns
double corrAB = df.corrBetween('A', 'B'); // 1.0 (perfect correlation)
double corrAC = df.corrBetween('A', 'C'); // -1.0 (perfect negative correlation)
```

### 5. Time Series Operations

Work with time series data.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'Date': DateTime(2023, 1, 1), 'Value': 10},
  {'Date': DateTime(2023, 1, 2), 'Value': 20},
  {'Date': DateTime(2023, 1, 5), 'Value': 30},
]);

// Resample time series data (e.g., fill missing dates)
DataFrame resampled = df.resample(
  dateColumn: 'Date',
  rule: 'day',
  method: 'ffill'
);
// resampled has rows for all days from Jan 1 to Jan 5

// Rolling window calculations
DataFrame rolling = df.rolling(
  window: 2,
  columns: ['Value'],
  function: 'mean'
);
// rolling.rows[1][1] is 15 (mean of 10 and 20)
// rolling.rows[2][1] is 25 (mean of 20 and 30)
```

## Performance Considerations

- For large datasets, consider using `formatData: false` during DataFrame creation to avoid overhead of data cleaning.
- When performing multiple operations on a DataFrame, chain them efficiently to minimize intermediate copies.
- Use `applyMap` with caution on large DataFrames as it processes each element individually.
- For better performance with large datasets, consider using typed data structures when possible.

## Conclusion

The DartFrame library provides a comprehensive set of tools for data manipulation and analysis in Dart. With its intuitive API and powerful features, it enables efficient data processing for a wide range of applications, from simple data transformations to complex statistical analyses.

For more examples and detailed API documentation, refer to the API reference or explore the example projects in the repository.