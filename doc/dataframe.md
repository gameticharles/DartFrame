


          
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
// dfMissing.rows[0][1] will be -1 (due to 'NA')
// dfMissing.rows[1][0] will be -1 (due to null)
// dfMissing.rows[1][2] will be -1 (due to empty string)
// dfMissing.rows[2][1] will be -1 (due to 'missing')

// If formatData is true and replaceMissingValueWith is not specified, missing values become null.
final dfMissingToNull = DataFrame(
  [[1, 'NA', 3.0]],
  columns: ['A', 'B', 'C'],
  missingDataIndicator: ['NA'],
  formatData: true,
);
// dfMissingToNull.rows[0][1] will be null
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
// dfFormattedCsv.rows will be:
// [ [10, 'A'], 
//   [-1, 'B'],  // Empty string for 'val' becomes -1
//   [30, -1]    // 'NA' for 'cat' becomes -1
// ]

// If formatData is true and replaceMissingValueWith is not specified, missing values become null.
final csvToNull = 'val,cat\n10,A\n,B\n30,NA';
final dfCsvToNull = await DataFrame.fromCSV(
  csv: csvToNull,
  formatData: true,
  missingDataIndicator: ['NA'],
);
// dfCsvToNull.rows[1][0] will be null
// dfCsvToNull.rows[2][1] will be null
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
  replaceMissingValueWith: "JSON_NULL", // JSON null values will be replaced by "JSON_NULL"
  formatData: true
);
// dfJsonMissing.rows[0][1] will be "JSON_NULL"
// dfJsonMissing.rows[1][0] will be "JSON_NULL"

// If formatData is true and replaceMissingValueWith is not specified, JSON nulls become Dart null.
final dfJsonToNull = await DataFrame.fromJson(
  jsonString: jsonWithNull,
  formatData: true
);
// dfJsonToNull.rows[0][1] will be null
// dfJsonToNull.rows[1][0] will be null
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

// If formatData is true and replaceMissingValueWith is not specified, nulls in lists become Dart null.
final mapToNull = {'A': [1, null], 'B': ['x', 'y']};
final dfMapToNull = DataFrame.fromMap(
  mapToNull,
  formatData: true
);
// dfMapToNull.rows[1][0] will be null
```

### 6. `DataFrame.fromRows()`

Constructs a DataFrame from a list of maps, where each map represents a row.
The keys of the maps become the column names. If `columns` is specified, only those columns will be included.

**Syntax:**
```dart
DataFrame.fromRows(
  List<Map<dynamic, dynamic>> rows, {
  List<dynamic>? columns, // Optional: specify column order and subset
  List<dynamic> index = const [],
  bool allowFlexibleColumns = false,
  dynamic replaceMissingValueWith,
  List<dynamic> missingDataIndicator = const [],
  bool formatData = false,
})
```

**Example:**
```dart
// Basic usage
final dfFromRows = DataFrame.fromRows([
  {'ID': 1, 'Category': 'A', 'Value': 100},
  {'ID': 2, 'Category': 'B', 'Value': 200},
  {'ID': 3, 'Category': 'A', 'Value': 300},
]);
// dfFromRows.columns will be ['ID', 'Category', 'Value'] based on the keys in the first map.
// dfFromRows.rows will be:
// [ [1, 'A', 100],
//   [2, 'B', 200],
//   [3, 'A', 300] ]

// Specifying columns (order and subset)
final dfFromRowsWithCols = DataFrame.fromRows(
  [
    {'Name': 'Alice', 'Age': 30, 'City': 'New York'},
    {'Name': 'Bob', 'Age': 24, 'City': 'Paris'},
    {'Name': 'Charlie', 'Age': 35, 'City': 'London', 'Occupation': 'Engineer'},
  ],
  columns: ['Name', 'City', 'Age'], // Selects and orders columns
);
// dfFromRowsWithCols.columns will be ['Name', 'City', 'Age']
// dfFromRowsWithCols.rows will be:
// [ ['Alice', 'New York', 30],
//   ['Bob', 'Paris', 24],
//   ['Charlie', 'London', 35] ] // Occupation is ignored

// Handling missing data (similar to other constructors)
final dfFromRowsMissing = DataFrame.fromRows(
  [
    {'A': 1, 'B': 'NA'},
    {'A': null, 'B': 'Data'},
  ],
  missingDataIndicator: ['NA'],
  replaceMissingValueWith: -1,
  formatData: true,
);
// dfFromRowsMissing.rows will be:
// [ [1, -1],    // 'NA' becomes -1
//   [-1, 'Data'] // null becomes -1
// ]
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
// Selects 1st row, columns at index 1 then 0.
var series = df.iloc(0, [1, 0]); 
// series.data is ['a', 1], name 'r1', index ['c2','c1']

// Select multiple rows (by position), returns a new DataFrame
// Selects 2nd row then 1st row.
var newDf = df.iloc[[1, 0]]; 
// newDf.rows are [[2,'b'], [1,'a']]
// newDf.index is ['r2', 'r1']
// newDf.columns is ['c1','c2']

// Select a single column (by position) from multiple rows, returns a Series
// Selects column at index 0 from rows at index 0 and 1.
var series2 = df.iloc([0, 1], 0); 
// series2.data is [1, 2], name 'c1', index ['r1','r2']

// Select a sub-DataFrame with multiple rows and columns (by position)
// Selects rows at index 0,1 and columns at index 1,0.
var subDf = df.iloc([0, 1], [1, 0]); 
// subDf.rows are [['a',1], ['b',2]]
// subDf.columns is ['c2','c1']
// subDf.index is ['r1','r2']

// Error handling for out-of-bounds access
expect(() => df.iloc[10], throwsA(isA<RangeError>())); // Row index out of bounds
expect(() => df.iloc(0, 10), throwsA(isA<RangeError>())); // Column index out of bounds
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
// Selects row 'rX', columns 'cB' then 'cA'.
var series = dfStrIdx.loc('rX', ['cB', 'cA']); 
// series.data is ['a', 1], name 'rX', index ['cB','cA']

// Select multiple rows by labels, returns a new DataFrame
// Selects row 'rY' then 'rX'.
var newDf = dfStrIdx.loc[['rY', 'rX']]; 
// newDf.rows are [[2,'b'], [1,'a']]
// newDf.index is ['rY', 'rX']

// Select a single column (by label) from multiple rows, returns a Series
// Selects column 'cA' from rows 'rX' and 'rY'.
var series2 = dfStrIdx.loc(['rX', 'rY'], 'cA'); 
// series2.data is [1, 2], name 'cA', index ['rX','rY']

// Select a sub-DataFrame with multiple rows and columns by labels
// Selects rows 'rY','rX' and columns 'cB','cA'.
var subDf = dfStrIdx.loc(['rY', 'rX'], ['cB', 'cA']); 
// subDf.rows are [['b',2], ['a',1]]
// subDf.columns is ['cB','cA']
// subDf.index is ['rY','rX']

// Using integer labels for index and columns
var dfIntIdx = DataFrame(
  [[10, 20], [30, 40]],
  columns: [100, 200], // Integer column labels
  index: [10, 20],     // Integer row labels
);
var valInt = dfIntIdx.loc(10, 200); // valInt is 20

// Error handling for label-not-found
expect(() => dfStrIdx.loc['nonExistentRow'], throwsA(isA<ArgumentError>()));
expect(() => dfStrIdx.loc('rX', 'nonExistentCol'), throwsA(isA<ArgumentError>()));
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
// df.columns = ['New1', 'New2']; // Length must match existing column count unless allowFlexibleColumns is true

// Setting a column with a Series
var dfTarget = DataFrame.fromMap({'A': [1, 2, 3]}, index: ['x', 'y', 'z']);

// 1. Series with identical index
final seriesSameIndex = Series([10, 20, 30], name: 'B', index: ['x', 'y', 'z']);
dfTarget['B_same'] = seriesSameIndex;
// dfTarget['B_same'].data is [10, 20, 30]
// dfTarget['B_same'].index is ['x', 'y', 'z']

// 2. Series with a subset of DataFrame's index
final seriesSubsetIndex = Series([10, 20], name: 'B', index: ['x', 'y']);
var dfTargetL = DataFrame.fromMap({'A': [1,2,3,4]}, index: ['w','x','y','z']);
dfTargetL['B_subset'] = seriesSubsetIndex;
// dfTargetL['B_subset'].data is [null, 10, 20, null] (or df.replaceMissingValueWith)

// 3. Series with a superset of DataFrame's index
final seriesSupersetIndex = Series([10,20,30,40], name:'B', index:['w','x','y','z']);
var dfTargetS = DataFrame.fromMap({'A': [1,2]}, index: ['x','y']);
dfTargetS['B_superset'] = seriesSupersetIndex;
// dfTargetS['B_superset'].data is [20, 30] (only matching 'x', 'y' are set)

// 4. Series with default integer index (assigns by row order)
final seriesDefaultIndex = Series([100, 200, 300], name: 'C');
dfTarget['C_default'] = seriesDefaultIndex;
// dfTarget['C_default'].data is [100, 200, 300]
// dfTarget['C_default'].index is ['x', 'y', 'z'] (takes DataFrame's index)

// 5. Series with length mismatch (shorter Series, default index)
final seriesShort = Series([50, 60], name: 'D'); // Length 2
dfTarget['D_short'] = seriesShort;
// dfTarget['D_short'].data is [50, 60, null] (or df.replaceMissingValueWith)

// 6. Series with length mismatch (longer Series, default index)
final seriesLong = Series([5,6,7,8], name:'E'); // Length 4
var dfTargetShort = DataFrame.fromMap({'A': [1,2]}, index:['x','y']);
dfTargetShort['E_long'] = seriesLong;
// dfTargetShort['E_long'].data is [5,6] (Series is truncated)

// Modifying an extracted Series updates the DataFrame
var dfData = {'colA': [1, 2, 3], 'colB': [4, 5, 6]};
var dfForMod = DataFrame.fromMap(dfData);
Series sA = dfForMod['colA'];
sA[0] = 100; // Modify the series
// dfForMod['colA'].data[0] is now 100
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
// customMissing.data is [false, true, false] (since -99 is the missing marker for dfCustomMissing)

// For a Series not attached to a DataFrame, or a DataFrame with default missing (null):
final s = Series([1, null, 3, null, 5], name: 's_nulls');
// s.isna().data is [false, true, false, true, false]
// s.notna().data is [true, false, true, false, true]

// If a Series is extracted from a DataFrame with a custom missing value,
// isna() and notna() on the Series will use that custom missing value.
final dfCtx = DataFrame.fromRows([
  {'colA': 1}, {'colA': -999}, {'colA': 3},
], replaceMissingValueWith: -999);
final seriesFromDf = dfCtx['colA'];
// seriesFromDf.isna().data is [false, true, false]
// seriesFromDf.notna().data is [true, false, true]
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

// Filling missing values when a custom replaceMissingValueWith is used
final dfCustomFill = DataFrame([
    [1, 'NA', 3],
    ['missing', 5, 'NA']
  ], 
  columns: ['A', 'B', 'C'],
  missingDataIndicator: ['NA', 'missing'], 
  replaceMissingValueWith: -100, // 'NA' and 'missing' become -100
  formatData: true
);
// dfCustomFill.rows[0][1] is -100
// dfCustomFill.rows[1][0] is -100

// Now, fill these -100 values with 99
DataFrame filledCustom = dfCustomFill.fillna(99);
// filledCustom.rows[0][1] is 99
// filledCustom.rows[1][0] is 99
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

// Dropping rows with a custom replaceMissingValueWith
final dfDropCustom = DataFrame([
    [1, 'X', 3],
    [4, 5, 6],
    ['X', 'X', 'X'], // This row will be dropped if how='all'
    [7, 8, 'X']      // This row will be dropped if how='any'
  ], 
  columns: ['A', 'B', 'C'],
  replaceMissingValueWith: 'X', // 'X' is treated as missing
  formatData: true
);

DataFrame droppedAnyCustom = dfDropCustom.dropna(how: 'any');
// droppedAnyCustom.rowCount is 1 (only row [4,5,6] remains)

DataFrame droppedAllCustom = dfDropCustom.dropna(how: 'all');
// droppedAllCustom.rowCount is 3 (row ['X','X','X'] is dropped)

// Dropping columns with a custom replaceMissingValueWith
final dfDropCustomCols = DataFrame([
    [1, 'X', 3],
    [4, 'X', 6],
    [7, 'X', 9]
  ], 
  columns: ['A', 'B', 'C'], // Column 'B' consists only of 'X' (missing)
  replaceMissingValueWith: 'X',
  formatData: true
);
DataFrame droppedAnyCustomCols = dfDropCustomCols.dropna(axis: 1, how: 'any');
// droppedAnyCustomCols.columns is ['A', 'C'] (column 'B' is dropped)

DataFrame droppedAllCustomCols = dfDropCustomCols.dropna(axis: 1, how: 'all');
// droppedAllCustomCols.columns is ['A', 'C'] (column 'B' is dropped as all its values are 'X')
```

**Note on Statistical Methods:**
Most statistical methods (like `sum()`, `mean()`, `median()`, `std()`, `variance()`, `describe()`, `count()`) automatically exclude missing data (whether it's `null` or a custom value defined by `replaceMissingValueWith` on the DataFrame or Series parent).

**Example:**
```dart
// Series with nulls
var sNull = Series([1, 2, null, 4, 5, null], name: 'test');
// sNull.count() is 4
// sNull.sum() is 12 
// sNull.mean() is 3.0

// Series with custom missing value from DataFrame context
var dfStats = DataFrame.empty(replaceMissingValueWith: -1);
var sCustomMissing = Series([-1, 1, 2, -1, 3], name: 'test_custom');
sCustomMissing.setParent(dfStats, 'test_custom'); // Link series to DataFrame for context

// sCustomMissing.count() is 3 (ignores -1)
// sCustomMissing.sum() is 6
// sCustomMissing.mean() is 2.0

// DataFrame describe with missing values
var dfDesc = DataFrame([
  [1.0, null, 10],
  [2.0, 20.0, null],
  [null, 30.0, 30],
  [4.0, 40.0, 40],
], columns: ['N1', 'N2', 'N3'], formatData: true); // formatData ensures nulls

var desc = dfDesc.describe();
// desc['N1']!['count'] is 3
// desc['N2']!['count'] is 3
// desc['N3']!['count'] is 3
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

// Create bins with equal width (3 bins)
// For data 5, 15, 25, 35, 45. Min:5, Max:45. Range:40. Step: ~13.33
// Edges might be ~ [5, 18.33, 31.66, 45]
// Bins (right=true, includeLowest=true by default for integer bins):
// [5, 18.33], (18.33, 31.66], (31.66, 45]
DataFrame binned = df.bin(
  column: 'Value',
  bins: 3, // Number of bins
  newColumn: 'Value_Bin_Num', // Name of the new column
  includeLowest: true,
);
// binned.column('Value_Bin_Num').data might be:
// ['[5.00, 18.33]', '[5.00, 18.33]', '(18.33, 31.67]', '(31.67, 45.00]', '(31.67, 45.00]'] (approx)

// Create bins with custom boundaries (binEdges)
DataFrame customBinned = df.bin(
  column: 'Value',
  bins: [0, 10, 30, 50], // Explicit bin edges
  newColumn: 'Value_Bin_Edges',
  labels: ['Group1', 'Group2', 'Group3'], // Custom labels for bins
  includeLowest: true, // First bin will be [0,10]
);
// customBinned.column('Value_Bin_Edges').data:
// ['Group1', 'Group2', 'Group2', 'Group3', 'Group3']
// (5 is in [0,10], 15&25 in (10,30], 35&45 in (30,50])

// Binning with right=false (intervals are [edge, next_edge) )
DataFrame binnedRightFalse = df.bin(
  column: 'Value',
  bins: [0, 15, 30, 45], // Edges
  newColumn: 'Value_Bin_RF',
  right: false, // Intervals are [0,15), [15,30), [30,45] (last includes right if max value)
  includeLowest: true, // Ensures 45 is included if it's the max
);
// For values [5, 15, 25, 35, 45]
// 5 is in [0,15)
// 15 is in [15,30)
// 25 is in [15,30)
// 35 is in [30,45)
// 45 is in [30,45] (if it's the max and includeLowest=true or right=false makes last interval inclusive)
// Check exact output based on test: reshapes_test.dart `bin with int bins, right=false`
// For data 1..10, bins [1,4,7,10], right=false:
// [1,2,3] -> '[1.00, 4.00)'
// [4,5,6] -> '[4.00, 7.00)'
// [7,8,9,10] -> '[7.00, 10.00]'

// Handling duplicate bin edges
// final dfDup = DataFrame.fromRows([{'value': i} for i in List.generate(10, (i) => i + 1)]);
// dfDup.bin('value', [1, 5, 5, 10], newColumn: 'dup_bin', duplicates: 'drop');
// Effective bins: (1,5], (5,10] (assuming includeLowest=false, right=true for list bins)
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
// dfWithNull.getDummies(['Category'], dummyNA: true).column('Category_na').data is [0, 1]

// Auto-detection of columns (columns = null)
// Encodes columns of string type by default.
final dfMixedTypes = DataFrame.fromRows([
  {'ID': 1, 'ColStr': 'x', 'ColInt': 10},
  {'ID': 2, 'ColStr': 'y', 'ColInt': 20},
]);
DataFrame autoEncoded = dfMixedTypes.getDummies(null);
// Result contains: 'ID', 'ColInt', 'ColStr_x', 'ColStr_y'

// dropFirst=true with dummyNA=true
// Categories for dfSimple.Category (nulls present): A, B, C, (na)
// If sorted: A, B, C, na. 'A' would be dropped.
final dfSimple = DataFrame.fromRows([
  {'Category': 'A'}, {'Category': 'B'}, {'Category': 'C'}, {'Category': null}
]);
DataFrame encodedDropNAD = dfSimple.getDummies(
  ['Category'], 
  dropFirst: true, 
  dummyNA: true
);
// Columns: Category_B, Category_C, Category_na

// Column with only one unique value and dropFirst=true
final dfOneUnique = DataFrame.fromRows([{'Cat': 'A'}, {'Cat': 'A'}]);
DataFrame oneUniqueDrop = dfOneUnique.getDummies(['Cat'], dropFirst: true);
// Result has no dummy columns for 'Cat' (Cat_A is dropped)

// Column with only missing values
final dfOnlyNa = DataFrame.fromRows([{'Col': null}, {'Col': null}], columns: ['Col']);
dfOnlyNa.replaceMissingValueWith = null; 

DataFrame onlyNaNoDummy = dfOnlyNa.getDummies(['Col'], dummyNA: false);
// Result has no dummy columns for 'Col'

DataFrame onlyNaWithDummy = dfOnlyNa.getDummies(['Col'], dummyNA: true);
// Result has 'Col_na' with data [1, 1]

DataFrame onlyNaWithDummyDropFirst = dfOnlyNa.getDummies(
  ['Col'], 
  dummyNA: true, 
  dropFirst: true
);
// Result has no dummy columns for 'Col' (Col_na is dropped)
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
//foo| 1.5 | 3.0  (mean of C for foo-one: (1+2)/2=1.5)
//bar| 4.0 | 5.5  (mean of C for bar-two: (5+6)/2=5.5)

// With 'sum' aggregation
DataFrame pivotedSum = df.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'sum');
// foo/one cell contains 3 (1+2)
// bar/two cell contains 11 (5+6)

// With 'count' aggregation
DataFrame pivotedCount = df.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'count');
// foo/one cell contains 2 (two entries for foo-one)

// With 'min' and 'max' aggregation
DataFrame pivotedMin = df.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'min');
// foo/one cell contains 1
DataFrame pivotedMax = df.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'max');
// foo/one cell contains 2

// With fill_value for missing combinations
final dfSparse = DataFrame.fromRows([
  {'A': 'foo', 'B': 'one', 'C': 1},
  {'A': 'bar', 'B': 'two', 'C': 2},
]);
DataFrame pivotedFill = dfSparse.pivotTable(index: 'A', columns: 'B', values: 'C', fillValue: 0);
// Result:
// A | one | two
//---|-----|----
//foo| 1   | 0  (filled)
//bar| 0   | 2  (filled)

// Pivoting non-numeric values (e.g., using 'min' or 'max')
final dfNonNumeric = DataFrame.fromRows([
  {'A': 'group1', 'B': 'cat1', 'C': 'apple'},
  {'A': 'group1', 'B': 'cat1', 'C': 'banana'},
]);
DataFrame pivotedStrMin = dfNonNumeric.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'min');
// group1/cat1 cell contains 'apple'
DataFrame pivotedStrMax = dfNonNumeric.pivotTable(index: 'A', columns: 'B', values: 'C', aggFunc: 'max');
// group1/cat1 cell contains 'banana'
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
// Result (order of rows might vary depending on internal sorting):
// A | one | two
//---|-----|----
//bar| 30  | 40
//foo| 10  | 20

// Pivot throws error on duplicate index/column pairs
final dfDuplicate = DataFrame.fromRows([
  {'A': 'foo', 'B': 'one', 'C': 10},
  {'A': 'foo', 'B': 'one', 'C': 20}, // Duplicate index 'foo', column 'one'
]);
expect(
  () => dfDuplicate.pivot(index: 'A', columns: 'B', values: 'C'),
  throwsArgumentError, // Due to duplicate entries for ('foo', 'one')
);

// Pivot with implicit value column (if only one column remains after specifying index and columns)
final dfImplicitVal = DataFrame.fromRows([
  {'idx': 'r1', 'col': 'cA', 'val': 100},
  {'idx': 'r1', 'col': 'cB', 'val': 200},
]);
DataFrame pivotedImplicit = dfImplicitVal.pivot(index: 'idx', columns: 'col'); 
// 'val' is automatically used as the values column.
// Result:
// idx | cA  | cB
//----|-----|----
// r1 | 100 | 200

// If multiple columns remain, the first one found is used (a warning might be logged).
final dfMultiVal = DataFrame.fromRows([
  {'idx': 'r1', 'col': 'cA', 'val1': 1, 'val2': 10},
  {'idx': 'r1', 'col': 'cB', 'val1': 2, 'val2': 20},
]);
DataFrame pivotedMultiVal = dfMultiVal.pivot(index: 'idx', columns: 'col');
// 'val1' will likely be chosen as the value column.

// Throws error if no value column can be inferred (all columns used for index/columns)
final dfNoVal = DataFrame.fromRows([
  {'idx': 'r1', 'col': 'cA'},
]);
expect(
  () => dfNoVal.pivot(index: 'idx', columns: 'col'),
  throwsArgumentError,
);
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
// bar |  0  |  1  (assuming default fill for missing combinations is 0)
// foo |  2  |  1
// Note: The actual output might have columns ['A', 'one', 'two'] and rows sorted by 'A'.

// With values and aggregation function (e.g., sum)
final dfValues = DataFrame.fromRows([
  {'A': 'foo', 'B': 'one', 'C': 10},
  {'A': 'foo', 'B': 'one', 'C': 20}, // sum for (foo,one) is 30
  {'A': 'foo', 'B': 'two', 'C': 30},
  {'A': 'bar', 'B': 'one', 'C': 40},
]);
DataFrame crosstabSum = DataFrame.crosstab(dfValues['A'], dfValues['B'], values: dfValues['C'], aggFunc: 'sum');
// Result:
// A   | one | two
//-----|-----|----
// bar | 40  | 0 (or null, then filled to 0)
// foo | 30  | 30

// With margins
DataFrame crosstabMargins = DataFrame.crosstab(df['A'], df['B'], margins: true, marginsName: 'Total');
// Result will include a 'Total' row and 'Total' column with sums.
//      B  one  two  Total
// A
// foo      2    1      3
// bar      1    2      3 (Using df from the initial crosstab example)
// baz      1    0      1 (If 'baz' was present with 'one':1)
// Total    4    3      7 (Example sums)

// With normalization (proportions of the grand total)
DataFrame crosstabNormAll = DataFrame.crosstab(df['A'], df['B'], normalize: true); // or normalize: 'all'
// Values are proportions, e.g., foo/one cell is 2 / total_count

// Normalize by index (row proportions)
DataFrame crosstabNormIndex = DataFrame.crosstab(df['A'], df['B'], normalize: 'index');
// foo/one cell is 2 / (2+1) = 0.666... (proportion within 'foo' row)

// Normalize by columns (column proportions)
DataFrame crosstabNormCols = DataFrame.crosstab(df['A'], df['B'], normalize: 'columns');
// foo/one cell is 2 / (2+1) = 0.666... (proportion within 'one' column, assuming 'bar' contributes 1 to 'one')

// Combining values, aggFunc, normalize, and margins
// Example: Proportion of sum of 'C' within each 'A' category, with totals
// DataFrame crosstabCombo = DataFrame.crosstab(
//   dfValues['A'], 
//   dfValues['B'], 
//   values: dfValues['C'], 
//   aggFunc: 'sum',
//   normalize: 'index', 
//   margins: true
// );
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
// Result has 3 rows (K0, K1, K2) and columns ['key', 'A', 'B', 'C', 'D']
// Example: innerJoin.rows[0] is ['K0', 'A0', 'B0', 'C0', 'D0']

// Left join
DataFrame leftJoin = df1.join(df2, on: 'key', how: 'left');
// Result has 4 rows (K0, K1, K2, K3). Row for K3 will have nulls for C and D.
// Example: leftJoin.row({'key':'K3'}) is {'key': 'K3', 'A': 'A3', 'B': 'B3', 'C': null, 'D': null}

// Right join
DataFrame rightJoin = df1.join(df2, on: 'key', how: 'right');
// Result has 4 rows (K0, K1, K2, K4). Row for K4 will have nulls for A and B.
// Example: rightJoin.row({'key':'K4'}) is {'key': 'K4', 'A': null, 'B': null, 'C': 'C3', 'D': 'D3'}

// Outer join
DataFrame outerJoin = df1.join(df2, on: 'key', how: 'outer');
// Result has 5 rows (K0, K1, K2, K3, K4).
// Example: outerJoin.row({'key':'K3'}) is {'key': 'K3', 'A': 'A3', 'B': 'B3', 'C': null, 'D': null}
// Example: outerJoin.row({'key':'K4'}) is {'key': 'K4', 'A': null, 'B': null, 'C': 'C3', 'D': 'D3'}

// Join on multiple columns
final df1Multi = DataFrame.fromRows([
  {'key1': 'K0', 'key2': 'X0', 'A': 'A0'},
  {'key1': 'K1', 'key2': 'X1', 'A': 'A1'},
]);
final df3 = DataFrame.fromRows([
  {'key1': 'K0', 'key2': 'X0', 'E': 'E0'},
  {'key1': 'K1', 'key2': 'X1', 'E': 'E1'},
]);
DataFrame multiKeyJoin = df1Multi.join(df3, on: ['key1', 'key2'], how: 'inner');
// Result has 2 rows and columns ['key1', 'key2', 'A', 'E']

// Using suffixes for overlapping column names (excluding join keys)
final dfX = DataFrame.fromRows([{'id': 1, 'val': 'X1'}, {'id': 2, 'val': 'X2'}]);
final dfY = DataFrame.fromRows([{'id': 1, 'val': 'Y1'}, {'id': 3, 'val': 'Y3'}]);
DataFrame suffixedJoin = dfX.join(dfY, on: 'id', how: 'left', suffixes: ['_dfX', '_dfY']);
// suffixedJoin.columns is ['id', 'val_dfX', 'val_dfY']
// suffixedJoin.rows are:
// [ [1, 'X1', 'Y1'],
//   [2, 'X2', null] ]

// Using indicator to add a column specifying the source of each row
DataFrame indicatedJoin = df1.join(df2, on: 'key', how: 'outer', indicator: true);
// New column '_merge' will have values like 'left_only', 'right_only', 'both'
// Example: indicatedJoin.row({'key':'K3'})['_merge'] is 'left_only'
// Example: indicatedJoin.row({'key':'K4'})['_merge'] is 'right_only'
// Example: indicatedJoin.row({'key':'K0'})['_merge'] is 'both'
// Custom indicator column name:
DataFrame customIndicatedJoin = df1.join(df2, on: 'key', how: 'left', indicator: 'source_info');
// New column 'source_info' indicates merge status.
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

// Vertical concatenation (axis = 0, default)
// Stacks DataFrames on top of each other.
DataFrame verticalConcat = df1.concatenate([df2]); // Equivalent to DataFrame.concatenate([df1, df2])
// Result has 4 rows and columns ['A', 'B']

// With different columns and 'outer' join (default)
final dfA1 = DataFrame.fromRows([{'col1': 1, 'col2': 'a'}]);
final dfB1 = DataFrame.fromRows([{'col1': 10, 'col3': 'x'}]);
DataFrame outerVertical = dfA1.concatenate([dfB1], join: 'outer');
// outerVertical.columns is ['col1', 'col2', 'col3']
// outerVertical.rows are:
// [ [1, 'a', null],
//   [10, null, 'x'] ]

// With different columns and 'inner' join
DataFrame innerVertical = dfA1.concatenate([dfB1], join: 'inner');
// innerVertical.columns is ['col1'] (only common columns)
// innerVertical.rows are:
// [ [1],
//   [10] ]

// Horizontal concatenation (axis = 1)
// Stacks DataFrames side-by-side.
final dfR1 = DataFrame.fromRows([{'A': 1, 'B': 2}, {'A': 3, 'B': 4}]); // 2 rows
final dfR2 = DataFrame.fromRows([{'C': 5, 'D': 6}, {'C': 7, 'D': 8}]); // 2 rows
DataFrame horizontalConcat = dfR1.concatenate([dfR2], axis: 1);
// horizontalConcat.columns is ['A', 'B', 'C', 'D']
// horizontalConcat.rows are:
// [ [1, 2, 5, 6],
//   [3, 4, 7, 8] ]

// Horizontal concatenation with different row counts and 'outer' join (default)
final dfR3Short = DataFrame.fromRows([{'E': 9}]); // 1 row
DataFrame outerHorizontal = dfR1.concatenate([dfR3Short], axis: 1, join: 'outer');
// outerHorizontal.rowCount is 2 (max of row counts)
// outerHorizontal.columns is ['A', 'B', 'E']
// outerHorizontal.rows are:
// [ [1, 2, 9],
//   [3, 4, null] ] // dfR3Short is padded with null

// Horizontal concatenation with different row counts and 'inner' join
DataFrame innerHorizontal = dfR1.concatenate([dfR3Short], axis: 1, join: 'inner');
// innerHorizontal.rowCount is 1 (min of row counts)
// innerHorizontal.columns is ['A', 'B', 'E']
// innerHorizontal.rows are:
// [ [1, 2, 9] ]

// Ignoring index during concatenation (results in default integer index/columns)
DataFrame concatIgnoreIndex = dfA1.concatenate([dfB1], ignoreIndex: true);
// Row index will be [0, 1]
DataFrame horizontalConcatIgnoreIndex = dfR1.concatenate([dfR2], axis: 1, ignoreIndex: true);
// Column names will be [0, 1, 2, 3]
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

// Using a boolean Series for filtering (Boolean Indexing)
// This is a very common and powerful way to filter DataFrames.
final dfToFilter = DataFrame.fromMap({
  'A': [10, 20, 30, 40],
  'B': [11, 22, 33, 44],
}, index: ['w', 'x', 'y', 'z']);

// 1. Boolean Series with an aligned index
final boolSeriesAligned = Series([true, false, true, false], index: ['w', 'x', 'y', 'z']);
DataFrame resultAligned = dfToFilter[boolSeriesAligned];
// resultAligned.rows are [[10, 11], [30, 33]]
// resultAligned.index is ['w', 'y']

// 2. Boolean Series with a partially aligned index (subset of DataFrame's index)
// The boolean Series is aligned to the DataFrame's index, missing values treated as false.
final boolSeriesSubset = Series([true, false], index: ['x', 'y']); // Covers 'x' and 'y'
DataFrame resultSubset = dfToFilter[boolSeriesSubset];
// Filter becomes effectively [F(w), T(x), F(y), F(z)]
// resultSubset.rows is [[20, 22]]
// resultSubset.index is ['x']

// 3. Boolean Series with a partially aligned index (superset of DataFrame's index)
// Extra indices in the boolean Series are ignored.
final boolSeriesSuperset = Series([true, false, true, false, true, false], 
                                index: ['v', 'w', 'x', 'y', 'z', 'a']);
DataFrame resultSuperset = dfToFilter[boolSeriesSuperset];
// Filter effectively becomes [F(w), T(x), F(y), T(z)] based on dfToFilter.index
// resultSuperset.rows are [[20, 22], [40, 44]]
// resultSuperset.index is ['x', 'z']

// 4. Boolean Series with default integer index (length must match DataFrame)
final boolSeriesDefault = Series([false, true, true, false]); // Length 4, matches dfToFilter
DataFrame resultDefault = dfToFilter[boolSeriesDefault];
// Applies row-wise based on length.
// resultDefault.rows are [[20, 22], [30, 33]]
// resultDefault.index is ['x', 'y']

// 5. Length mismatch with default index raises an error
final boolSeriesShort = Series([true, false]);
// expect(() => dfToFilter[boolSeriesShort], throwsA(isA<ArgumentError>()));
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

### 3. Column-wise Operations with Series

When you extract a column from a DataFrame, you get a `Series`. You can then perform element-wise arithmetic or logical operations between this Series and another Series, or a scalar value. Index alignment is a key feature when operating between two Series.

**Example: Arithmetic Operations**
```dart
final df = DataFrame.fromMap({
  'A': [1, 2, 3, 4],
  'B': [10, 20, 30, 40],
}, index: ['w', 'x', 'y', 'z']);

Series colA = df['A']; // Data: [1,2,3,4], Index: ['w','x','y','z']

// 1. Operation with a Series having an identical index
Series seriesSameIndex = Series([5, 50, 500, 5000], index: ['w', 'x', 'y', 'z']);
Series resultAligned = colA + seriesSameIndex;
// resultAligned.data is [6, 52, 503, 5004]
// resultAligned.index is ['w', 'x', 'y', 'z']

// 2. Operation with a Series having a default integer index
// If the DataFrame column's Series has a non-default index and the other Series has a 
// default (null) index, the operation uses the DataFrame column's index and applies 
// element-wise if lengths match.
// (Note: The exact behavior of Series arithmetic with misaligned or default indexes 
// should be confirmed from Series documentation. The test cases suggest that if one
// Series has an index and the other doesn't (default), the result takes the non-default index.)

// Example based on Series test logic:
Series seriesDefaultIdx = Series([10, 10, 10, 10]); // No specific index, length matches colA
// To ensure this works as expected with colA's index, the Series implementation
// would typically align based on colA's index if seriesDefaultIdx has a null index.
// Let's assume seriesDefaultIdx is explicitly created to align for this example:
Series seriesDefaultIdxAligned = Series([10, 10, 10, 10], index: ['w', 'x', 'y', 'z']);
Series resultDefault = colA + seriesDefaultIdxAligned;
// resultDefault.data is [11, 12, 13, 14]
// resultDefault.index is ['w', 'x', 'y', 'z']

// 3. Operation with a scalar
Series resultScalar = colA * 2;
// resultScalar.data is [2, 4, 6, 8]
// resultScalar.index is ['w', 'x', 'y', 'z']
```
**Note:** For detailed behavior of Series operations, especially regarding complex index alignments (e.g., partial overlaps, different lengths with non-default indexes), refer to the `Series` class documentation.

### 4. Applying Functions
### 4. Applying Functions

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

### 5. Correlation and Covariance

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

### 6. Time Series Operations

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

---

## General Usage Examples (from README)

This section provides a collection of common usage examples, originally from the main README, to illustrate practical applications of DataFrame operations.

### Creating a DataFrame (from README)

#### From CSV

```dart
var csvData = """
Name,Age,City
Alice,30,New York
Bob,25,Los Angeles
Charlie,35,Chicago
""";

var df = DataFrame.fromCSV(csv: csvData);
print(df.head(3));
// Output:
// DataFrame with 3 rows and 3 columns
// Index | Name    | Age | City
// ----- | ------- | --- | ---------
// 0     | Alice   | 30  | New York
// 1     | Bob     | 25  | Los Angeles
// 2     | Charlie | 35  | Chicago
```

#### From JSON

```dart
var jsonData = '''
[
  {"Name": "Alice", "Age": 30, "City": "New York"},
  {"Name": "Bob", "Age": 25, "City": "Los Angeles"},
  {"Name": "Charlie", "Age": 35, "City": "Chicago"}
]
''';

var df = DataFrame.fromJson(jsonString: jsonData);
print(df.describe()); // Example of an operation on the new DataFrame
// Output might be:
//         Name        Age       City
// count    3.0        3.0        3.0
// mean     NaN   30.00000        NaN
// std      NaN    5.00000        NaN
// min      NaN       25.0        NaN
// 25%      NaN       27.5        NaN
// 50%      NaN       30.0        NaN
// 75%      NaN       32.5        NaN
// max      NaN       35.0        NaN
```

#### Directly from Lists

```dart
var df = DataFrame(
  [
    [1, 'A'],
    [2, 'B'],
    [3, 'C'],
  ],
  columns: ['ID', 'Value'],
);
print(df);
// Output:
// DataFrame with 3 rows and 2 columns
// Index | ID | Value
// ----- | -- | -----
// 0     | 1  | A
// 1     | 2  | B
// 2     | 3  | C
```

### Data Exploration (from README)

```dart
// Assuming 'df' is a DataFrame, for example, the one created from CSV:
// var df = DataFrame.fromCSV(csv: csvData); 

// print('Columns: ${df.columns}');
// Output: Columns: [Name, Age, City]

// print('Shape: ${df.shape}');
// Output: Shape: {rows: 3, columns: 3}

// print('Head:\n${df.head(2)}'); // First 2 rows
// Output:
// Head:
// DataFrame with 2 rows and 3 columns
// Index | Name  | Age | City
// ----- | ----- | --- | --------
// 0     | Alice | 30  | New York
// 1     | Bob   | 25  | Los Angeles

// print('Tail:\n${df.tail(2)}'); // Last 2 rows
// Output:
// Tail:
// DataFrame with 2 rows and 3 columns
// Index | Name    | Age | City
// ----- | ------- | --- | ---------
// 1     | Bob     | 25  | Los Angeles
// 2     | Charlie | 35  | Chicago

// print('Summary:\n${df.describe()}');
// (Output similar to the fromJson example's describe output)
```

### Data Cleaning (from README)

```dart
// Assuming 'df' is a DataFrame. Let's create one for these examples:
var dfToClean = DataFrame.fromMap({
    'Name': ['Alice', 'Bob', null, 'David'],
    'Age': [30, 25, 30, 22],
    'City': ['New York', '<NA>', 'Chicago', 'Boston'],
    'ExtraCol': [1,2,3,4]
});
// print('Original dfToClean:\n$dfToClean');

// Replace null values in 'Name' column with "Unknown"
// Note: fillna typically returns a new DataFrame. For inplace, specific methods might exist or re-assignment.
// The original README example `df.fillna('Unknown')` implies a global fill.
// Let's demonstrate filling a specific column then a global fill.
var dfFilledName = dfToClean.fillna({'Name': 'Unknown'});
// print('After filling Name NAs:\n$dfFilledName');

var dfFilledAll = dfToClean.fillna('MISSING'); // Global fill
// print('After global fill:\n$dfFilledAll');


// Replace placeholder values with null
// The Series.replace method is more suitable for this.
// Let's assume we want to replace '<NA>' in 'City' with actual null.
var citySeries = dfToClean['City'];
var cityCleaned = citySeries.replace('<NA>', null); // Creates a new Series
dfToClean['City'] = cityCleaned; // Assign the cleaned Series back
// print('After replacing <NA> in City:\n$dfToClean');


// Rename column 'Name' to 'FullName'
var dfRenamed = dfToClean.rename({'Name': 'FullName'});
// print('After renaming Name to FullName:\n$dfRenamed');
// dfToClean.columns still has 'Name' unless re-assigned: dfToClean = dfRenamed;

// Drop the "ExtraCol" column
var dfDropped = dfToClean.drop(['ExtraCol']); // Returns a new DataFrame
// print('After dropping ExtraCol:\n$dfDropped');
```

### Analysis (from README)

```dart
// Assuming 'df' is the DataFrame created from CSV example:
var dfForAnalysis = DataFrame.fromCSV(csv: """
Name,Age,City
Alice,30,New York
Bob,25,Los Angeles
Charlie,35,Chicago
Diana,30,New York
""");

// Group by City and calculate mean age
var grouped = dfForAnalysis.groupBy(['City']); // Group by 'City'
DataFrame meanAgeByCity = grouped.mean(); // Calculate mean for numeric columns per group
// print('Mean Age by City:\n$meanAgeByCity');
// Output example:
// Mean Age by City:
// City        | Age
// ----------- | ---
// Chicago     | 35.0
// Los Angeles | 25.0
// New York    | 30.0


// Frequency counts for 'City'
Series cityCounts = dfForAnalysis['City'].valueCounts();
// print('City Counts:\n$cityCounts');
// Output:
// City_value_counts:
// New York    2
// Los Angeles 1
// Chicago     1
// Length: 3
// Type: int
```

### Data Transformation (from README)

```dart
// Assuming 'df' is the DataFrame from the CSV example used in Analysis:
var dfForTransform = DataFrame.fromCSV(csv: """
Name,Age,City
Alice,30,New York
Bob,25,Los Angeles
Charlie,35,Chicago
Diana,17,New York 
""");

// Add a calculated column 'IsAdult'
// Ensure 'Age' column is numeric. fromCSV initially reads as String.
var ageSeriesNum = dfForTransform['Age'].toNumeric(errors: 'coerce');
dfForTransform['Age'] = ageSeriesNum; // Update with numeric Series

dfForTransform['IsAdult'] = ageSeriesNum.apply((age) => age != null && age > 18);
// print('DataFrame with IsAdult column:\n$dfForTransform');
// Output:
// Index | Name    | Age | City      | IsAdult
// ----- | ------- | --- | --------- | -------
// 0     | Alice   | 30  | New York  | true
// 1     | Bob     | 25  | Los Angeles | true
// 2     | Charlie | 35  | Chicago   | true
// 3     | Diana   | 17  | New York  | false


// Filter rows where City is 'New York'
// Using the boolean indexing method:
Series cityFilter = dfForTransform['City'].apply((city) => city == 'New York');
DataFrame filteredNY = dfForTransform[cityFilter];
// print('Filtered DataFrame (City is New York):\n$filteredNY');
// Output:
// Index | Name  | Age | City     | IsAdult
// ----- | ----- | --- | -------- | -------
// 0     | Alice | 30  | New York | true
// 3     | Diana | 17  | New York | false
```

### Concatenation (from README)

```dart
var df1 = DataFrame([[1, 2], [3, 4]], columns: ['A', 'B']);
var df2 = DataFrame([[5, 6], [7, 8]], columns: ['A', 'B']); // Changed C,D to A,B for vertical example

// Horizontal concatenation (axis = 1)
// To avoid column name clashes in horizontal concat, ensure unique names or use suffixes
var df2Horiz = DataFrame([[5, 6], [7, 8]], columns: ['C', 'D']);
var horizontal = df1.concatenate([df2Horiz], axis: 1);
// print('Horizontally concatenated DataFrame:\n$horizontal');
// Output:
//    A  B  C  D
// 0  1  2  5  6
// 1  3  4  7  8

// Vertical concatenation (axis = 0, default)
var vertical = df1.concatenate([df2]); // df2 has same columns A,B for this example
// print('Vertically concatenated DataFrame:\n$vertical');
// Output:
//    A  B
// 0  1  2
// 1  3  4
// 0  5  6  (Index might be reset or duplicated depending on implementation,
// 1  7  8   use ignoreIndex: true for clean 0..N-1 index)

var verticalCleanIndex = df1.concatenate([df2], ignoreIndex: true);
// print('Vertically concatenated DataFrame with clean index:\n$verticalCleanIndex');
// Output:
//    A  B
// 0  1  2
// 1  3  4
// 2  5  6
// 3  7  8
```