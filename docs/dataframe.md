# DataFrame Class Documentation

The `DataFrame` class in DartFrame provides a 2-dimensional labeled data structure similar to those found in other data analysis libraries. It allows for columns of potentially different types and offers a variety of methods for data manipulation and analysis.

## Creating a DataFrame

There are several ways to create a `DataFrame`:

### 1. Constructor

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

**Parameters:**

- `data`: A list of rows, where each row is a list of values.
- `columns`: (Optional) A list of column names. If not provided and `data` is not null, columns will be auto-named (e.g., 'Column1', 'Column2').
- `index`: (Optional) A list to use as the index for the DataFrame. If not provided, a default integer index will be generated.
- `allowFlexibleColumns`: (Optional) If `true`, allows operations that might change the number of columns (e.g., setting `columns` with a different length). Defaults to `false`.
- `replaceMissingValueWith`: (Optional) A value to replace any missing data indicated by `missingDataIndicator` or null/empty strings.
- `missingDataIndicator`: (Optional) A list of values to be treated as missing data.
- `formatData`: (Optional) If `true`, attempts to clean and convert data to appropriate types (numeric, boolean, DateTime) during initialization. Defaults to `false`.

**Example:**

```dart
// Initialize with data, columns, and index
final df = DataFrame([
  [1, 2, 3.0],
  [4, 5, 6],
  [7, 'hi', 9]
], index: [
  'RowA',
  'RowB',
  'RowC'
], columns: [
  'col_int',
  'col_str',
  'col_float'
]);
print(df);

// Initialize with only data (auto-generated columns and index)
final df2 = DataFrame([
  [10, 'apple'],
  [20, 'banana'],
]);
print(df2);
```

### 2. `DataFrame.empty()`

Creates an empty `DataFrame`.

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
print(emptyDf);
```

### 3. `DataFrame.fromCSV()`

Constructs a `DataFrame` from a CSV string or a file.

**Syntax:**

```dart
factory DataFrame.fromCSV({
  String? csv,
  String delimiter = ',',
  String? inputFilePath,
  bool hasHeader = true,
  bool hasRowIndex = false, // Note: hasRowIndex functionality might still be under development
  bool allowFlexibleColumns = false,
  dynamic replaceMissingValueWith,
  bool formatData = false,
  List missingDataIndicator = const [],
})
```

**Parameters:**

- `csv`: The CSV data as a string.
- `delimiter`: The character used to separate values in the CSV. Defaults to `,`.
- `inputFilePath`: Path to the CSV file.
- `hasHeader`: If `true`, the first row of the CSV is treated as column names. Defaults to `true`.
- `hasRowIndex`: (Currently may not be fully implemented) If `true`, the first column is treated as the row index.
- `allowFlexibleColumns`, `replaceMissingValueWith`, `formatData`, `missingDataIndicator`: Same as the main constructor.

**Example:**

```dart
var csvData = 'Name,Age,City\nAlice,30,New York\nBob,25,Los Angeles';
var dfFromCsv = DataFrame.fromCSV(csv: csvData);
print(dfFromCsv);

// Example with formatting and missing value handling
var csvWithMissing = 'ID,Value\n1,100\n2,NA\n3,200';
var dfFormatted = DataFrame.fromCSV(
  csv: csvWithMissing,
  formatData: true,
  missingDataIndicator: ['NA'],
  replaceMissingValueWith: null,
);
print(dfFormatted);
```

### 4. `DataFrame.fromJson()`

Constructs a `DataFrame` from a JSON string or file. The JSON is expected to be a list of objects with consistent keys.

**Syntax:**

```dart
factory DataFrame.fromJson({
  String? jsonString,
  String? inputFilePath,
  bool allowFlexibleColumns = false,
  dynamic replaceMissingValueWith,
  bool formatData = false,
  List missingDataIndicator = const [],
})
```

**Parameters:**

- `jsonString`: The JSON data as a string.
- `inputFilePath`: Path to the JSON file.
- `allowFlexibleColumns`, `replaceMissingValueWith`, `formatData`, `missingDataIndicator`: Same as the main constructor.

**Example:**

```dart
var jsonData = '[{"Name": "Alice", "Age": 30, "City": "New York"}, '
               '{"Name": "Bob", "Age": 25, "City": "Los Angeles"}]';
var dfFromJson = DataFrame.fromJson(jsonString: jsonData);
print(dfFromJson);
```

### 5. `DataFrame.fromMap()`

Constructs a `DataFrame` from a map where keys are column names and values are lists representing column data. All lists must have the same length.

**Syntax:**

```dart
factory DataFrame.fromMap(
  Map<String, List<dynamic>> map, {
  bool allowFlexibleColumns = false,
  dynamic replaceMissingValueWith,
  List missingDataIndicator = const [],
})
```

**Parameters:**

- `map`: A map where keys are column names (String) and values are lists of column data.
- `allowFlexibleColumns`, `replaceMissingValueWith`, `missingDataIndicator`: Same as the main constructor.

**Example:**

```dart
Map<String, List<dynamic>> mapData = {
  'A': [1, 2, 3],
  'B': ['x', 'y', 'z'],
};
var dfFromMap = DataFrame.fromMap(mapData);
print(dfFromMap);
```

## Accessing Data

### 1. Columns

- **Get column names:** `df.columns`
- **Access a column by name:** `df['columnName']` or `df.columnName` (if the column name is a valid Dart identifier)
- **Access a column by index:** `df[columnIndex]`

**Example:**

```dart
final df = DataFrame([
  [1, 'apple', 10.0],
  [2, 'banana', 20.0],
], columns: ['ID', 'Fruit', 'Price']);

print(df.columns); // Output: [ID, Fruit, Price]
print(df['Fruit']); // Output: Series(Fruit): [apple, banana]
print(df.Price);    // Output: Series(Price): [10.0, 20.0] (if Price is a valid identifier)
print(df[0]);       // Output: Series(ID): [1, 2]
```

### 2. Rows

- **Get all rows (data):** `df.rows` (returns a `List<List<dynamic>>`)
- **Access a specific row by index:** `df.rows[rowIndex]` (returns a `List<dynamic>`)
- **Access a specific element:** `df['columnName'][rowIndex]` or `df[columnIndex][rowIndex]`

**Example:**

```dart
final df = DataFrame([
  [1, 'apple', 10.0],
  [2, 'banana', 20.0],
], columns: ['ID', 'Fruit', 'Price'], index: ['item1', 'item2']);

print(df.rows);
// Output: [[1, apple, 10.0], [2, banana, 20.0]]

print(df.rows[0]); // Output: [1, apple, 10.0]
print(df['Fruit'][1]); // Output: banana
print(df[2][0]);       // Output: 10.0
```

### 3. Shape

Returns the dimensions of the DataFrame (number of rows, number of columns).

**Syntax:**

`df.shape` (returns a record `({int rows, int columns})`)

**Example:**

```dart
final df = DataFrame([
  [1, 2, 3],
  [4, 5, 6]
], columns: ['A', 'B', 'C']);
print(df.shape); // Output: (rows: 2, columns: 3)
```

### 4. Indexing

The `DataFrame` has an index that labels the rows.

- **Get index:** `df.index`
- **Set index during construction:** Use the `index` parameter in the constructor.

**Example:**

```dart
final df = DataFrame([
  [10, 20],
  [30, 40]
], columns: ['X', 'Y'], index: ['row1', 'row2']);
print(df.index); // Output: [row1, row2]
print(df);
/*
      X   Y
row1  10  20
row2  30  40
*/
```

## Modifying Data

### 1. Setting Columns

You can add new columns or modify existing ones.

- **Set/Update a column by name:** `df['newColumnName'] = [value1, value2, ...];`
- **Set/Update a column by index:** `df[columnIndex] = [value1, value2, ...];`
- **Set all column names:** `df.columns = ['NewCol1', 'NewCol2', ...];` (Length must match existing number of columns unless `allowFlexibleColumns` is true).

**Example:**

```dart
final df = DataFrame([
  [1, 'a'],
  [2, 'b']
], columns: ['Num', 'Char']);

// Add a new column
df['Bool'] = [true, false];
print(df);

// Update an existing column by name
df['Num'] = [10, 20];
print(df);

// Update an existing column by index
df[1] = ['x', 'y']; // Updates 'Char' column
print(df);

// Modify a specific element
df['Num'][0] = 100;
print(df);
```

### 2. Cleaning Data (`_cleanData` method - internal)

The `_cleanData` method is used internally when `formatData: true` is passed to a constructor. It attempts to:
- Convert string representations of numbers to `num`.
- Convert string "true" or "false" (case-insensitive) to `bool`.
- Parse strings into `DateTime` objects if they match common date formats.
- Convert string representations of lists (e.g., "[1,2,3]") into `List` objects.
- Replace values specified in `missingDataIndicator` or empty strings/nulls with `replaceMissingValueWith`.

This is typically handled at DataFrame creation. For post-creation cleaning, you might use `replace` or manual column updates.

## Common Operations

### 1. `describe()`

Generates descriptive statistics for numeric columns (count, mean, std, min, max, etc.) and summary information for non-numeric columns.

**Syntax:**

`df.describe()`

**Example:**

```dart
final df = DataFrame([
  [1, 10.0, 'x'],
  [2, 20.0, 'y'],
  [3, 15.0, 'x'],
  [null, 25.0, 'z']
], columns: ['ID', 'Value', 'Category'], formatData: true);
print(df.describe());
```

### 2. `head()`

Returns the first `n` rows of the DataFrame.

**Syntax:**

`df.head(int n = 5)`

**Example:**

```dart
print(df.head(2)); // Shows the first 2 rows
```

### 3. `tail()`

Returns the last `n` rows of the DataFrame.

**Syntax:**

`df.tail(int n = 5)`

**Example:**

```dart
print(df.tail(2)); // Shows the last 2 rows
```

### 4. `limit()`

Returns a specified number of rows starting from a given index.

**Syntax:**

`df.limit(int count, {int startIndex = 0})`

**Example:**

```dart
final df = DataFrame.fromMap({
  'A': List.generate(10, (i) => i)
});
print(df.limit(3, startIndex: 2)); // Shows 3 rows starting from index 2
```

### 5. `groupBy()`

Groups DataFrame using a mapper or by a column name.

**Syntax:**

`df.groupBy(dynamic columnOrMapper)`

**Example:**

```dart
final df = DataFrame([
  ['A', 10, 'X'],
  ['B', 20, 'Y'],
  ['A', 30, 'X'],
  ['B', 40, 'Y'],
  ['C', 50, 'Z']
], columns: ['Group', 'Value', 'Type']);

var groupedByGroup = df.groupBy('Group');
groupedByGroup.forEach((key, dataFrame) {
  print('Group: $key');
  print(dataFrame);
});

// Example: Calculate mean of 'Value' for each 'Group'
groupedByGroup.forEach((key, value) {
  print('$key Mean Value: ${value['Value'].mean()}');
});
```

### 6. `valueCounts()`

Returns a Series containing counts of unique values in a specified column.

**Syntax:**

`df.valueCounts(dynamic columnName)`

**Example:**

```dart
final df = DataFrame([
  ['A'], ['B'], ['A'], ['C'], ['A'], ['B']
], columns: ['Category']);
print(df.valueCounts('Category'));
/*
Expected output (Series):
Category
A    3
B    2
C    1
*/
```

### 7. `fillna()`

Fills missing (null) values in the DataFrame with a specified value. This operation returns a new DataFrame.

**Syntax:**

`df.fillna(dynamic value, {List<dynamic>? subset})`
- `value`: The value to fill missing entries with.
- `subset`: (Optional) A list of column names to apply the fill operation to. If null, applies to all columns.

**Example:**

```dart
var dfWithMissing = DataFrame([
  [1, null, 'apple'],
  [null, 20, 'banana'],
  [3, 30, null]
], columns: ['A', 'B', 'C'], replaceMissingValueWith: null); // Ensure nulls are present

print('Original:');
print(dfWithMissing);

var dfFilled = dfWithMissing.fillna(0);
print('\nFilled with 0:');
print(dfFilled);

var dfFilledSubset = dfWithMissing.fillna('N/A', subset: ['C']);
print('\nFilled "N/A" in column C:');
print(dfFilledSubset);
```

### 8. `replace()` and `replaceInPlace()`

Replaces occurrences of a value with another value.
- `replace()`: Returns a new DataFrame with replacements.
- `replaceInPlace()`: Modifies the DataFrame directly.

**Syntax:**

`df.replace(dynamic oldValue, dynamic newValue, {List<dynamic>? subset})`
`df.replaceInPlace(dynamic oldValue, dynamic newValue, {List<dynamic>? subset})`
- `subset`: (Optional) List of column names to perform replacement on.

**Example:**

```dart
var df = DataFrame([
  [1, 10, 'x'],
  [2, 20, 'y'],
  [1, 30, 'x']
], columns: ['ID', 'Value', 'Code']);

var dfReplaced = df.replace('x', 'alpha');
print('After replace (new DataFrame):');
print(dfReplaced);

df.replaceInPlace(1, 100, subset: ['ID']);
print('\nAfter replaceInPlace on ID column:');
print(df);
```

### 9. `rename()`

Renames columns. This operation modifies the DataFrame in place.

**Syntax:**

`df.rename(Map<dynamic, dynamic> newNames)`
- `newNames`: A map where keys are old column names (or indices) and values are new column names.

**Example:**

```dart
var df = DataFrame([
  [1, 'a'],
  [2, 'b']
], columns: ['OldName1', 'OldName2']);
print('Before rename:');
print(df.columns); // [OldName1, OldName2]

df.rename({'OldName1': 'New_ID', 'OldName2': 'New_Char'});
print('\nAfter rename:');
print(df.columns); // [New_ID, New_Char]
```

### 10. `drop()`

Removes specified columns from the DataFrame. This operation modifies the DataFrame in place.

**Syntax:**

`df.drop(dynamic columnNameOrIndex, {int axis = 1})`
- `columnNameOrIndex`: The name or index of the column to drop.
- `axis`: 1 for columns (currently only column dropping is robustly supported).

**Example:**

```dart
var df = DataFrame([
  [1, 'a', true],
  [2, 'b', false]
], columns: ['Num', 'Char', 'Bool']);
print('Before drop:');
print(df.columns); // [Num, Char, Bool]

df.drop('Char');
print('\nAfter dropping "Char":');
print(df.columns); // [Num, Bool]

df.drop(1); // Drops the column now at index 1 (which is 'Bool')
print('\nAfter dropping column at index 1:');
print(df.columns); // [Num]
```

### 11. `shuffle()`

Randomly shuffles the rows of the DataFrame. Returns a new DataFrame.

**Syntax:**

`df.shuffle({int? seed})`
- `seed`: (Optional) An integer seed for the random number generator to ensure reproducibility.

**Example:**

```dart
final df = DataFrame.fromMap({
  'ID': [1, 2, 3, 4, 5],
  'Value': ['A', 'B', 'C', 'D', 'E']
});
print('Original DataFrame:');
print(df);

var shuffledDf = df.shuffle();
print('\nShuffled DataFrame (random):');
print(shuffledDf);

var shuffledDfWithSeed = df.shuffle(seed: 42);
print('\nShuffled DataFrame (with seed 42):');
print(shuffledDfWithSeed);
```

### 12. `toJSON()`

Exports the DataFrame data as a list of maps, suitable for JSON encoding.

**Syntax:**

`List<Map<String, dynamic>> df.toJSON()`

**Example:**

```dart
// import 'dart:convert'; // Required for jsonEncode

final df = DataFrame([
  ['Alice', 30],
  ['Bob', 25]
], columns: ['Name', 'Age']);

List<Map<String, dynamic>> jsonData = df.toJSON();
print(jsonData);
// Output: [{Name: Alice, Age: 30}, {Name: Bob, Age: 25}]

// String jsonString = jsonEncode(jsonData); // To get a JSON string
// print(jsonString);
// Output: [{"Name":"Alice","Age":30},{"Name":"Bob","Age":25}]
```

This documentation provides an overview of the `DataFrame` class. For more detailed information or specific use cases, refer to the source code and examples within the DartFrame project.
