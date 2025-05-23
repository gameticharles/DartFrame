# DataFrame Class Documentation

The `DataFrame` class in DartFrame provides a 2-dimensional labeled data structure similar to those found in other data analysis libraries. It allows for columns of potentially different types and offers a variety of methods for data manipulation and analysis.

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
    - [Understanding `formatData`, `missingDataIndicator`, and `replaceMissingValueWith`](#understanding-formatdata-missingdataindicator-and-replacemissingvaluewith)
  - [Accessing Data](#accessing-data)
    - [1. Accessing Columns (`df['columnName']`, `df[columnIndex]`)](#1-accessing-columns-dfcolumnname-dfcolumnindex)
    - [2. Accessing Rows (`df.rows`, `df.rows[rowIndex]`)](#2-accessing-rows-dfrows-dfrowsrowindex)
    - [3. Accessing Single Elements](#3-accessing-single-elements)
    - [4. Position-Based Selection (`df.iloc[]`)](#4-position-based-selection-dfiloc)
    - [5. Label-Based Selection (`df.loc[]`)](#5-label-based-selection-dfloc)
    - [6. DataFrame Properties (Shape, Index, Columns)](#6-dataframe-properties-shape-index-columns)
  - [Modifying Data](#modifying-data)
    - [1. Setting Columns (`df['newCol'] = ...`, `df.columns = ...`)](#1-setting-columns-dfnewcol---dfcolumns--)
    - [2. Adding Rows (`df.addRow()`)](#2-adding-rows-dfaddrow)
    - [3. Updating Cell Values (`df.updateCell()`)](#3-updating-cell-values-dfupdatecell)
  - [Handling Missing Data](#handling-missing-data)
    - [1. Identifying Missing Data (`isna()`, `notna()`)](#1-identifying-missing-data-isna-notna)
    - [2. Filling Missing Data (`fillna()`)](#2-filling-missing-data-fillna)
    - [3. Dropping Missing Data (`dropna()`)](#3-dropping-missing-data-dropna)
  - [Common Operations](#common-operations)
    - [1. Descriptive Statistics (`describe()`)](#1-descriptive-statistics-describe)
    - [2. Viewing Data (`head()`, `tail()`, `limit()`)](#2-viewing-data-head-tail-limit)
    - [3. Grouping Data (`groupBy()`)](#3-grouping-data-groupby)
    - [4. Value Counts (`valueCounts()`)](#4-value-counts-valuecounts)
    - [5. Replacing Values (`replace()`, `replaceInPlace()`)](#5-replacing-values-replace-replaceinplace)
    - [6. Renaming Columns (`rename()`)](#6-renaming-columns-rename)
    - [7. Dropping Columns/Rows (`drop()`)](#7-dropping-columnsrows-drop)
    - [8. Shuffling Data (`shuffle()`)](#8-shuffling-data-shuffle)
    - [9. Exporting to JSON (`toJSON()`)](#9-exporting-to-json-tojson)
    - [10. Exporting to CSV (`toCSV()`)](#10-exporting-to-csv-tocsv)
  - [Combining DataFrames](#combining-dataframes)
    - [1. Joining DataFrames (`join()`)](#1-joining-dataframes-join)
    - [2. Concatenating DataFrames (`concatenate()`)](#2-concatenating-dataframes-concatenate)
  - [Reshaping and Pivoting](#reshaping-and-pivoting)
    - [1. Pivot Table (`pivotTable()`)](#1-pivot-table-pivottable)
    - [2. Strict Pivot (`pivot()`)](#2-strict-pivot-pivot)
    - [3. Crosstabulation (`crosstab()`)](#3-crosstabulation-crosstab)
  - [Transformations](#transformations)
    - [1. Binning / Discretization (`bin()`)](#1-binning--discretization-bin)
    - [2. One-Hot Encoding (`getDummies()`)](#2-one-hot-encoding-getdummies)

## Creating a DataFrame

There are several ways to create a `DataFrame`:

### 1. Constructor (`DataFrame()`)
You can create a `DataFrame` directly by providing data as a list of lists, along with optional column names and index.

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
**Parameters:** (See "Understanding `formatData`, `missingDataIndicator`, and `replaceMissingValueWith`" for more details on these parameters)
- `data`: A list of rows, where each row is a list of values.
- `columns`: (Optional) A list of column names. If not provided and `data` is not null, columns will be auto-named (e.g., 'Column1', 'Column2').
- `index`: (Optional) A list to use as the index for the DataFrame. If not provided, a default integer index will be generated.
- `allowFlexibleColumns`: (Optional) If `true`, allows operations that might change the number of columns. Defaults to `false`.
- `replaceMissingValueWith`: (Optional) A value to replace any missing data.
- `missingDataIndicator`: (Optional) A list of values to be treated as missing data.
- `formatData`: (Optional) If `true`, attempts to clean data types and handle missing values. Defaults to `false`.

**Example:**
```dart
// Basic instantiation
final dfInstance = DataFrame([]); // Creates an empty DataFrame
expect(dfInstance, isNotNull);

// Initialize with data, columns, and index
final df = DataFrame([
  [1, 2, 3.0], [4, 5, 6], [7, 'hi', 9]
], index: ['RowA', 'RowB', 'RowC'], columns: ['col_int', 'col_str', 'col_float']);
print(df);

// Handling missing data during construction
var dfMissing = DataFrame(
  [[1, 'NA', 3.0], [null, 5, ''], [7, 'missing', 9]],
  columns: ['A', 'B', 'C'],
  missingDataIndicator: ['NA', 'missing', 'N/A'], // These strings will be treated as missing
  replaceMissingValueWith: -1, // Replace them with -1
  formatData: true, // Enable processing of missingDataIndicator and nulls/empty strings
);
// dfMissing.rows[0][1] will be -1 (from 'NA')
// dfMissing.rows[1][0] will be -1 (from null)
// dfMissing.rows[1][2] will be -1 (from '')
// dfMissing.rows[2][1] will be -1 (from 'missing')
```

### 2. `DataFrame.empty()`
Creates an empty `DataFrame`, optionally with predefined column names.

**Syntax:**
```dart
DataFrame.empty({ List<dynamic>? columns, ... })
```
**Example:**
```dart
final emptyDf = DataFrame.empty(columns: ['Name', 'Age']);
expect(emptyDf.rows, isEmpty);
expect(emptyDf.columns, equals(['Name', 'Age']));
```

### 3. `DataFrame.fromCSV()`
Constructs a `DataFrame` from a CSV string.

**Syntax:**
```dart
factory DataFrame.fromCSV({
  String? csv,
  String delimiter = ',',
  String? inputFilePath, // Not shown in tests, but part of signature
  bool hasHeader = true,
  // ... other parameters like formatData, missingDataIndicator, replaceMissingValueWith
})
```
**Example:**
```dart
final csvSimple = 'colA,colB\\n1,apple\\n2,banana';
final dfSimpleCsv = await DataFrame.fromCSV(csv: csvSimple);
// dfSimpleCsv.rows[0] is ['1', 'apple'] (strings by default)

final csvNoHeader = '1;x\\n2;y';
final dfNoHeader = await DataFrame.fromCSV(csv: csvNoHeader, delimiter: ';', hasHeader: false);
// dfNoHeader.columns is ['Column 0', 'Column 1']

final csvWithMissing = 'val,cat\\n10,A\\n,B\\n30,NA';
final dfFormattedCsv = await DataFrame.fromCSV(
  csv: csvWithMissing,
  formatData: true,
  missingDataIndicator: ['NA'], // 'NA' strings become missing
  replaceMissingValueWith: -1   // Missing values (including empty fields) become -1
);
// dfFormattedCsv.rows[0] is [10, 'A']
// dfFormattedCsv.rows[1] is [-1, 'B'] (empty string for 'val' became -1)
// dfFormattedCsv.rows[2] is [30, -1] ('NA' for 'cat' became -1)
```

### 4. `DataFrame.fromJson()`
Constructs a `DataFrame` from a JSON string (list of objects).

**Syntax:**
```dart
factory DataFrame.fromJson({
  String? jsonString,
  String? inputFilePath, // Not shown in tests, but part of signature
  // ... other parameters like formatData, replaceMissingValueWith
})
```
**Example:**
```dart
final jsonBasic = '[{"colA": 1, "colB": "apple"}, {"colA": 2, "colB": "banana"}]';
final dfBasicJson = await DataFrame.fromJson(jsonString: jsonBasic);
// dfBasicJson.rows[0] is [1, "apple"]

final jsonWithNull = '[{"val": 10, "cat": "A"}, {"val": null, "cat": "B"}]';
final dfFormattedJson = await DataFrame.fromJson(
  jsonString: jsonWithNull,
  formatData: true,
  replaceMissingValueWith: "MISSING"
);
// dfFormattedJson.rows[1] is ["MISSING", 'B'] (JSON null became "MISSING")
```

### 5. `DataFrame.fromMap()`
Constructs a `DataFrame` from a map of column names to lists of column data.

**Syntax:**
```dart
factory DataFrame.fromMap(Map<String, List<dynamic>> map, { ... })
```
**Example:**
```dart
final mapData = {'col1': [1, 2, 3], 'col2': ['a', 'b', 'c']};
final dfFromMap = DataFrame.fromMap(mapData);
// dfFromMap.columns is ['col1', 'col2']
// dfFromMap.rows[0] is [1, 'a']

final mapWithNull = {'A': [1, null], 'B': ['x', 'y']};
final dfMapMissing = DataFrame.fromMap(
  mapWithNull,
  replaceMissingValueWith: -999,
  formatData: true
);
// dfMapMissing.rows[1][0] is -999
```

### 6. `DataFrame.fromRows()`
(Although not directly in the test files, this is a common constructor shown in examples)
Constructs a `DataFrame` from a list of maps, where each map represents a row.

**Syntax:**
```dart
factory DataFrame.fromRows(List<Map<dynamic, dynamic>> rows, { ... })
```
**Example:**
```dart
final dfFromRows = DataFrame.fromRows([
  {'ID': 1, 'Category': 'A', 'Value': 100},
  {'ID': 2, 'Category': 'B', 'Value': 200},
]);
// dfFromRows.columns will be ['ID', 'Category', 'Value']
```

### Understanding `formatData`, `missingDataIndicator`, and `replaceMissingValueWith`
These parameters in DataFrame constructors (especially `DataFrame()`, `fromCSV`, `fromJson`, `fromMap`) control how raw input data is cleaned and standardized:
- `formatData: true`: Enables the data cleaning process. This includes attempting to convert strings to numbers, booleans, or DateTimes, and importantly, processing missing values.
- `missingDataIndicator: List<dynamic>`: A list of values (e.g., `['NA', 'N/A', 'missing', -1]`) that should be treated as missing when encountered in the input data.
- `replaceMissingValueWith: dynamic`: The actual value that will be stored in the DataFrame to represent any missing data. This applies to:
    - Values explicitly matching `missingDataIndicator`.
    - `null` values in the input (e.g., from JSON, or Dart `null` in lists for `fromMap` or direct constructor).
    - Empty strings (`''`) in the input (e.g., from CSV, or direct constructor).
  If `replaceMissingValueWith` is not provided, these missing inputs default to Dart `null`.

**Example (`_cleanData` behavior):**
```dart
// Default behavior: missing values become null
var dfDef = DataFrame.empty(missingDataIndicator: ['NA']);
// dfDef.cleanData('NA') results in null
// dfDef.cleanData(null) results in null
// dfDef.cleanData('') results in null

// Custom placeholder: missing values become 'MISSING_PLACEHOLDER'
var dfCustom = DataFrame.empty(missingDataIndicator: ['NA'], replaceMissingValueWith: 'MISSING_PLACEHOLDER');
// dfCustom.cleanData('NA') results in 'MISSING_PLACEHOLDER'
```

## Accessing Data

### 1. Accessing Columns (`df['columnName']`, `df[columnIndex]`)
You can access a DataFrame column as a `Series` using its name (String) or integer position (int).
**Example:**
```dart
final df = DataFrame.fromMap({'col1': [1,2], 'col2': ['a','b']});
Series seriesByName = df['col1']; // Access by name
// seriesByName.data is [1, 2]

Series seriesByIndex = df[0];    // Access by index
// seriesByIndex.data is [1, 2]

// Attempting to access a non-existent column throws ArgumentError
expect(() => df['badColumn'], throwsA(isA<ArgumentError>()));
```

### 2. Accessing Rows (`df.rows`, `df.rows[rowIndex]`)
- `df.rows`: Returns a `List<List<dynamic>>` of all row data.
- `df.rows[rowIndex]`: Access a specific row by its integer position.

### 3. Accessing Single Elements
Use `df['columnNameOrIndex'][rowIndex]` or `df.iloc[rowPos][colPos]` or `df.loc[rowLabel][colLabel]`.

### 4. Position-Based Selection (`df.iloc[]`)
`iloc` allows selection by integer position (0-indexed).
- `df.iloc[rowIndex]`: Selects a single row by its integer position, returns a `Series`.
  ```dart
  var df = DataFrame([[1,'a'],[2,'b']], columns:['c1','c2'], index:['r1','r2']);
  var secondRow = df.iloc[1]; // secondRow.data is [2, 'b'], name 'r2', index ['c1','c2']
  ```
- `df.iloc[rowIndex][colIndex]`: Selects a single element.
  ```dart
  var value = df.iloc[0][1]; // value is 'a'
  ```
- `df.iloc[rowIndex][[colIndex1, colIndex2]]`: Selects specific columns from a single row, returns a `Series`.
  ```dart
  var series = df.iloc[0][[1, 0]]; // From 1st row, cols at index 1 then 0. series.data is ['a', 1]
  ```
- `df.iloc[[rowIndex1, rowIndex2]]`: Selects multiple rows, returns a new `DataFrame`.
  ```dart
  var newDf = df.iloc[[1, 0]]; // Selects 2nd then 1st row.
  ```
- `df.iloc[[rowIndex1, rowIndex2]][colIndex]`: Selects a single column's data for multiple rows, returns a `Series`.
  ```dart
  var series = df.iloc[[0, 1]][0]; // From 1st and 2nd rows, 1st column. series.data is [1, 2]
  ```
- `df.iloc[[rowIndex1, rowIndex2]][[colIndex1, colIndex2]]`: Selects a sub-DataFrame.
  ```dart
  var subDf = df.iloc[[0,1]][[1]]; // 1st and 2nd rows, 2nd column.
  ```
- **Error Handling**: Accessing out-of-bounds integer positions throws `RangeError`.

### 5. Label-Based Selection (`df.loc[]`)
`loc` allows selection by index and column labels.
- `df.loc[rowLabel]`: Selects a single row by its label, returns a `Series`.
  ```dart
  var dfStrIdx = DataFrame([[1,'a'],[2,'b']], columns:['cA','cB'], index:['rX','rY']);
  var rowX = dfStrIdx.loc['rX']; // rowX.data is [1,'a']
  ```
- `df.loc[rowLabel][colLabel]`: Selects a single element by labels.
  ```dart
  var value = dfStrIdx.loc['rX']['cB']; // value is 'a'
  ```
- `df.loc[rowLabel][[colLabel1, colLabel2]]`: Selects specific columns from a single row by labels, returns a `Series`.
- `df.loc[[rowLabel1, rowLabel2]]`: Selects multiple rows by labels, returns a new `DataFrame`.
- `df.loc[[rowLabel1, rowLabel2]][colLabel]`: Selects a single column's data for multiple rows by labels, returns a `Series`.
- `df.loc[[rowLabel1, rowLabel2]][[colLabel1, colLabel2]]`: Selects a sub-DataFrame by labels.
- **Error Handling**: Accessing non-existent labels throws `ArgumentError`.

### 6. DataFrame Properties (Shape, Index, Columns)
- `df.shape`: Returns `({int rows, int columns})`.
- `df.index`: Returns `List<dynamic>` of row index labels.
- `df.columns`: Returns `List<dynamic>` of column names.

## Modifying Data

### 1. Setting Columns (`df['newCol'] = ...`, `df.columns = ...`)
- **Assigning a List to a new or existing column**:
  ```dart
  final df = DataFrame.empty(columns:['A']); // Start with one column to establish row count for this example
  df['A'] = [10, 20]; // If df was empty before, this sets 2 rows for column A.
  df['B'] = [30, 40]; // Adds or updates column B
  // df.rows would be [[10,30], [20,40]]
  ```
- **Adding the first column to an empty DataFrame**:
  ```dart
  final df = DataFrame.empty();
  df['col1'] = [1, 2, 3];
  // df.columns is ['col1'], df.rows is [[1],[2],[3]]
  ```
- **Setting all column names**: `df.columns = ['New1', 'New2'];` (Length must match existing column count unless `allowFlexibleColumns` is true).

### 2. Adding Rows (`df.addRow()`)
Adds a new row to the DataFrame. If the DataFrame is empty, columns will be auto-named based on the first row added.
```dart
final df = DataFrame.empty();
df.addRow([1, 'apple']); // Columns become 'Column1', 'Column2'. Rows: [[1, 'apple']]
df.addRow([2, 'banana']); // Rows: [[1, 'apple'], [2, 'banana']]
```

### 3. Updating Cell Values (`df.updateCell()`)
```dart
df.updateCell('columnName', rowIndex, newValue);
// Or using accessors for more complex updates.
```

## Handling Missing Data
Missing data is typically represented by `null` or a custom value set in `DataFrame.replaceMissingValueWith`.

### 1. Identifying Missing Data (`isna()`, `notna()`)
- `df.isna()`: Returns a DataFrame of booleans indicating `true` where data is missing.
  ```dart
  final df = DataFrame.fromRows([{'A':1,'C':null}], replaceMissingValueWith:null);
  final result = df.isna(); // result.rows is [[false,true]] (assuming columns A, C)
  ```
- `df.notna()`: Returns a DataFrame of booleans indicating `true` where data is present.
  ```dart
  final result = df.notna(); // result.rows is [[true,false]]
  ```
- These methods correctly identify missing values based on the DataFrame's `replaceMissingValueWith` context (e.g., `null`, a number like `-99`, or a string like `'MISSING'`).

### 2. Filling Missing Data (`fillna()`)
Replaces missing values with a specified value.
**Syntax**: `df.fillna(dynamic value, {List<dynamic>? subset})`
```dart
var df = DataFrame([[1, null],[null, 4]], columns:['A','B'], replaceMissingValueWith: null);
var dfFilled = df.fillna(0); // Replaces all nulls with 0
// dfFilled.rows is [[1,0],[0,4]]

var dfFilledSubset = df.fillna(-1, subset: ['A']); // Only fill nulls in column 'A'
// dfFilledSubset.rows is [[1,null],[-1,4]]
```

### 3. Dropping Missing Data (`dropna()`)
Removes rows or columns containing missing values.
**Syntax**: `df.dropna({int axis = 0, String how = 'any', List<String>? subset})`
- `axis`: 0 to drop rows (default), 1 to drop columns.
- `how`: `'any'` to drop if any missing value is present, `'all'` to drop if all values are missing.
- `subset`: List of columns to consider when dropping rows.
```dart
var df = DataFrame([[1,null,3],[4,5,6],[null,null,null]], columns:['A','B','C'], replaceMissingValueWith:null);
var dfDroppedAnyRow = df.dropna(how:'any', axis:0); // Keeps only row [4,5,6]
var dfDroppedAllRow = df.dropna(how:'all', axis:0); // Keeps rows [1,null,3] and [4,5,6]

var dfDroppedAnyCol = df.dropna(how:'any', axis:1); // Keeps columns 'A', 'C' if B had all nulls
```

## Common Operations

### 1. Descriptive Statistics (`describe()`)
Generates statistics like count, mean, std, min, max for numeric columns. Correctly ignores missing values.
```dart
final df = DataFrame([[1.0, null],[2.0,20.0],[null,30.0]], columns:['N1','N2'], replaceMissingValueWith:null);
var desc = df.describe();
// desc['N1']!['count'] would be 2
// desc['N2']!['mean'] would be 25.0
```
*(Existing content for `head`, `tail`, `limit`, `groupBy`, `valueCounts`, `replace`, `rename`, `drop`, `shuffle`, `toJSON`, `toCSV` can be kept and augmented if specific test insights apply)*

## Combining DataFrames

### 1. Joining DataFrames (`join()`)
Performs database-style joins (inner, left, right, outer, cross) between two DataFrames.
**Syntax**: `df.join(DataFrame other, {String how = 'inner', dynamic on, dynamic leftOn, dynamic rightOn, List<String> suffixes = const ['_x', '_y'], dynamic indicator = false})`
- `how`: Type of join.
- `on`: Column name(s) to join on (must exist in both).
- `leftOn`/`rightOn`: Column names to join on if key names differ.
- `suffixes`: Appended to overlapping non-key column names.
- `indicator`: If `true` or a string, adds a column (`_merge` or custom name) indicating merge source.

**Examples:**
```dart
final df1 = DataFrame.fromRows([{'key':'K0','A':'A0'},{'key':'K1','A':'A1'}]);
final df2 = DataFrame.fromRows([{'key':'K0','C':'C0'},{'key':'K2','C':'C2'}]);

// Inner Join
final innerJoined = df1.join(df2, on: 'key', how: 'inner');
// innerJoined.rows is [{'key':'K0', 'A':'A0', 'C':'C0'}] (as map for clarity)

// Left Join with indicator
final leftJoined = df1.join(df2, on: 'key', how: 'left', indicator: true);
// leftJoined has rows for K0 (both) and K1 (left_only)

// Outer Join with different keys and suffixes for overlapping data columns
final dfX = DataFrame.fromRows([{'id':1,'val':'X1'}]);
final dfY = DataFrame.fromRows([{'id':1,'val':'Y1'}]);
final outerSuffixed = dfX.join(dfY, on:'id', how:'outer', suffixes:['_dfX','_dfY']);
// outerSuffixed.columns includes 'val_dfX', 'val_dfY'
```
- **Error Handling**: Throws `ArgumentError` for invalid key parameter combinations or non-existent keys.
- **Missing Values in Keys**: `null` values in join keys do not match other `null` values.

### 2. Concatenating DataFrames (`concatenate()`)
Appends DataFrames along rows (`axis: 0`) or columns (`axis: 1`).
**Syntax**: `df.concatenate(List<DataFrame> others, {int axis = 0, String join = 'outer', bool ignoreIndex = false})`
- `axis`: 0 for row-wise, 1 for column-wise.
- `join`: `'outer'` (union of other axis labels, fill with null) or `'inner'` (intersection).
- `ignoreIndex`: If `true`, resets index (axis 0) or column names to default integers (axis 1).

**Examples:**
```dart
final dfA1 = DataFrame.fromRows([{'c1':1,'c2':'a'}]);
final dfA2 = DataFrame.fromRows([{'c1':3,'c2':'c'}]);
final dfB1 = DataFrame.fromRows([{'c1':10,'c3':'x'}]);

// Row-wise (axis 0), outer join (default)
final rowConcatOuter = dfA1.concatenate([dfB1]);
// rowConcatOuter.columns is ['c1','c2','c3']
// result has 2 rows, with nulls for non-matching columns

// Column-wise (axis 1), inner join, different row counts
final dfR1 = DataFrame.fromRows([{'A':1},{'A':3}]); // 2 rows
final dfR3Short = DataFrame.fromRows([{'E':9}]);   // 1 row
final colConcatInner = dfR1.concatenate([dfR3Short], axis:1, join:'inner');
// colConcatInner.rowCount is 1 (min rows)
// result is [{'A':1, 'E':9}] (as map)

// Column-wise with duplicate column names
final dfR5DupCol = DataFrame.fromRows([{'A':10}]);
final colConcatDup = dfR1.concatenate([dfR5DupCol], axis:1, ignoreIndex:false);
// colConcatDup.columns could be ['A', 'A_1']
```
- **Edge Cases**: Handles empty DataFrames, duplicate column names (for axis 1), and different join strategies.

## Reshaping and Pivoting

### 1. Pivot Table (`pivotTable()`)
Creates a spreadsheet-style pivot table. Allows aggregation of values.
**Syntax**: `df.pivotTable({required String index, required String columns, required String values, String aggFunc = 'mean', dynamic fillValue})`
- `aggFunc`: `'mean'`, `'sum'`, `'count'`, `'min'`, `'max'`.
- `fillValue`: For missing cells after pivoting.
```dart
final df = DataFrame.fromRows([
  {'A':'foo','B':'one','C':1},{'A':'foo','B':'one','C':2},
  {'A':'foo','B':'two','C':3}
]);
final pivoted = df.pivotTable(index:'A',columns:'B',values:'C',aggFunc:'sum');
// pivoted.row({'A':'foo'})['one'] is 3
// pivoted.row({'A':'foo'})['two'] is 3
```
- Can aggregate non-numeric data with 'min'/'max' (lexicographical).

### 2. Strict Pivot (`pivot()`)
Reshapes DataFrame based on column values without aggregation. Requires unique index/column pairs.
**Syntax**: `df.pivot({required String index, required String columns, String? values})`
- If `values` is omitted, it's inferred from remaining columns.
```dart
final df = DataFrame.fromRows([{'A':'foo','B':'one','C':10}]);
final p = df.pivot(index:'A',columns:'B',values:'C');
// p.row({'A':'foo'})['one'] is 10

// Throws error if (index, columns) pair is not unique:
final dfDup = DataFrame.fromRows([{'A':'foo','B':'one','C':10},{'A':'foo','B':'one','C':20}]);
// expect(()=>dfDup.pivot(index:'A',columns:'B',values:'C'), throwsArgumentError);
```

### 3. Crosstabulation (`crosstab()`)
Computes a frequency table of two (or more) factors.
**Syntax**: `df.crosstab({required String index, required String column, String? values, String aggfunc = 'count', dynamic normalize = false, bool margins = false, String margins_name = 'All'})`
- `aggfunc`: If `values` provided, how to aggregate them.
- `normalize`: `true`/'all' (by grand total), 'index' (across rows), 'columns' (down columns).
- `margins`: Add row/column subtotals.
```dart
final df = DataFrame.fromRows([{'A':'foo','B':'one','C':10},{'A':'foo','B':'one','C':20}]);
final ct = df.crosstab(index:'A',column:'B'); // Counts: row 'foo', col 'one' is 2
final ctSum = df.crosstab(index:'A',column:'B',values:'C',aggfunc:'sum'); // Sums: row 'foo', col 'one' is 30
```

## Transformations

### 1. Binning / Discretization (`bin()`)
Segments data into discrete intervals (bins).
**Syntax**: `df.bin(dynamic column, dynamic bins, {String? newColumn, List<String>? labels, bool right = true, bool includeLowest = false, String duplicates = 'raise', int decimalPlaces = 2})`
- `bins`: Integer (number of bins) or `List<num>` (bin edges).
- `right`: If `true`, bins are `(left, right]`. If `false`, `[left, right)`.
- `includeLowest`: If `true`, first interval is left-inclusive.
- `labels`: Custom names for bins.
- `duplicates`: `'raise'` or `'drop'` for non-unique bin edges.
```dart
final dfBin = DataFrame.fromRows([{'val':1},{'val':5},{'val':10}]);
final binned = dfBin.bin('val', [0,5,10], newColumn:'val_bin');
// Example: row with val=1 gets bin '(0.00, 5.00]'
// row with val=5 gets bin '(0.00, 5.00]' (if right=true)
// row with val=10 gets bin '(5.00, 10.00]'
```

### 2. One-Hot Encoding (`getDummies()`)
Converts categorical variable(s) into dummy/indicator variables.
**Syntax**: `df.getDummies(List<String>? columns, {String? prefix, dynamic prefixSep = '_', bool dummyNA = false, bool dropFirst = false})`
- `columns`: List of column names to encode. If `null`, attempts to encode string columns.
- `prefix`: Prefix for new dummy column names.
- `prefixSep`: Separator between prefix and category value.
- `dummyNA`: If `true`, adds a column for missing values.
- `dropFirst`: If `true`, removes the first category level to avoid multicollinearity.
```dart
final dfCat = DataFrame.fromRows([{'ID':1,'Cat':'A'},{'ID':2,'Cat':'B'},{'ID':3,'Cat':null}]);
final dummied = dfCat.getDummies(['Cat'], prefix:'Type', dummyNA:true, dropFirst:true);
// Columns might be: ID, Type_B, Type_na (if 'A' was first category and dropped)
// Original 'Cat' column is removed.
```
- Handles numeric categories by converting them to strings for column names.
- Handles potential column name conflicts by appending suffixes.
- New dummy columns are of integer type (0 or 1).
