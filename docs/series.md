# Series Class Documentation

The `Series` class in DartFrame represents a one-dimensional labeled array, similar to a column in a spreadsheet or a single vector of data. It's a fundamental building block for `DataFrame`.

## Table of Contents
- [Series Class Documentation](#series-class-documentation)
  - [Table of Contents](#table-of-contents)
  - [Creating a Series](#creating-a-series)
    - [1. Constructor (`Series()`)](#1-constructor-series)
    - [2. Generating DateTime Series (`dateRange()`)](#2-generating-datetime-series-daterange)
  - [Accessing and Modifying Data](#accessing-and-modifying-data)
    - [1. Data (`series.data`)](#1-data-seriesdata)
    - [2. Name (`series.name`)](#2-name-seriesname)
    - [3. Length (`series.length`)](#3-length-serieslength)
    - [4. Index (`series.index`)](#4-index-seriesindex)
    - [5. Element-wise Access and Modification (`[]`, `[]=`)](#5-element-wise-access-and-modification---)
  - [Operations](#operations)
    - [Arithmetic Operations](#arithmetic-operations)
      - [Addition (`+`)](#addition-)
      - [Subtraction (`-`)](#subtraction--)
      - [Multiplication (`*`)](#multiplication--)
      - [Division (`/`)](#division--)
      - [Integer Division (`~/`)](#integer-division--)
      - [Modulo (`%`)](#modulo-)
    - [Bitwise Operations](#bitwise-operations)
      - [XOR (`^`)](#xor-)
      - [AND (`&`)](#and-)
      - [OR (`|`)](#or-)
    - [String Operations (`series.str.*`)](#string-operations-seriesstr)
      - [`str.len()`](#strlen)
      - [`str.lower()`, `str.upper()`](#strlower-strupper)
      - [`str.strip()`](#strstrip)
      - [`str.startswith(pattern)`, `str.endswith(pattern)`](#strstartswithpattern-strendswithpattern)
      - [`str.contains(pattern)`](#strcontainspattern)
      - [`str.replace(pattern, replacement)`](#strreplacepattern-replacement)
    - [DateTime Conversions](#datetime-conversions)
      - [`series.toDatetime()`](#seriestodatetime)
  - [Statistical Methods](#statistical-methods)
    - [1. `nunique()`](#1-nunique)
    - [2. `valueCounts()`](#2-valuecounts)
    - [3. Basic Statistics (`count()`, `sum()`, `mean()`, etc.)](#3-basic-statistics-count-sum-mean-etc)
  - [Missing Data Handling](#missing-data-handling)
    - [1. `isna()`](#1-isna)
    - [2. `notna()`](#2-notna)
  - [Other Operations](#other-operations)
    - [1. `concatenate()`](#1-concatenate)
  - [Conversion to DataFrame](#conversion-to-dataframe)
    - [1. `toDataFrame()`](#1-todataframe)
  - [String Representation (`toString()`)](#string-representation-tostring)

## Creating a Series

### 1. Constructor (`Series()`)
You can create a `Series` by providing a list of data and a name for the series.

**Syntax:**
```dart
Series(List<dynamic> data, {required String name, List<dynamic>? index});
```
**Parameters:**
- `data`: A `List` containing the data points of the series.
- `name`: A `String` that gives a name to the Series (e.g., 'Age', 'Price').
- `index`: (Optional) A `List` to use as the index for the Series. If not provided, a default integer index (0, 1, 2, ...) will be generated.

**Example:**
```dart
// Series with integer data and default index
var numericSeries = Series([10, 20, 30, 40], name: 'Counts');
print(numericSeries);

// Series with string data and custom index
var stringSeries = Series(['apple', 'banana', 'cherry'], name: 'Fruits', index: ['a', 'b', 'c']);
print(stringSeries);
```

### 2. Generating DateTime Series (`dateRange()`)
A top-level function `dateRange()` can be used to create a `Series` of `DateTime` objects.

**Syntax:**
```dart
Series dateRange({
  DateTime? start,
  DateTime? end,
  int? periods,
  String freq = 'D', // Currently only 'D' (daily) is supported
  bool normalize = false,
  String name = 'dateRange',
})
```
**Parameters:**
- Requires exactly two of `start`, `end`, or `periods`.
- `freq`: Frequency string. Only 'D' for daily is currently supported.
- `normalize`: If `true`, sets the time part of start/end to midnight.

**Example:**
```dart
// Create a Series of 3 daily dates starting from 2023-01-01
final dailyDates = dateRange(start: DateTime(2023, 1, 1), periods: 3);
// dailyDates.data is [DateTime(2023,1,1), DateTime(2023,1,2), DateTime(2023,1,3)]

// Create a Series from start to end date
final specificRange = dateRange(start: DateTime(2023,2,27), end: DateTime(2023,3,2));
// specificRange.data includes dates from Feb 27 to Mar 2, 2023
```
- **Error Handling**: Throws `ArgumentError` for invalid parameter combinations (e.g., only one of start/end/periods, negative periods, unsupported `freq`).
- **Edge Cases**: `periods = 0` results in an empty Series. If `start` is after `end` with positive `periods`, it throws an error.

## Accessing and Modifying Data

### 1. Data (`series.data`)
Access or assign the underlying `List<dynamic>` of the Series.
- **Get data:** `series.data`
- **Modify data:** `series.data[index] = newValue;` or `series.data = newList;`
  (Note: If the Series is part of a DataFrame, direct modification might not update the DataFrame. Use DataFrame methods.)

### 2. Name (`series.name`)
Access or change the name of the Series.
- **Get name:** `series.name`
- **Set name:** `series.name = 'NewName';`

### 3. Length (`series.length`)
Get the number of elements in the Series.
- **Get length:** `series.length`

### 4. Index (`series.index`)
Access or assign the index labels of the Series.
- **Get index:** `series.index` (returns `List<dynamic>?`)
- **Set index:** `series.index = ['x', 'y', 'z'];` (Length must match data length)

### 5. Element-wise Access and Modification (`[]`, `[]=`)
The `[]` operator can be used for accessing elements, and `[]=` for modifying them.
This supports single index, list of indices, or boolean Series for indexing.

**Example:**
```dart
var s = Series([10, 20, 30], name: 'MyData', index: ['x', 'y', 'z']);

// Access data using default list index if Series index is not used for direct access
print(s.data[0]); // Output: 10

// Modify data using default list index
s.data[1] = 25;
// Series content for 'y' is now 25

// More advanced indexing (if supported by operator overloads not shown in base Series)
// s[booleanSeries] = newValue; // Example from example.dart
```
*(Note: The base `Series` in `series.dart` might not have direct `[]` and `[]=` for element access/modification using its custom `index`. Access is primarily via `series.data[list_index]` or through DataFrame context. The `test/series_operations_test.dart` implies these operators are available, likely via extensions or the `Series` class in `lib/src/series/operations.dart`)*

## Operations

### Arithmetic Operations
Series arithmetic operations are element-wise and support index alignment. If indexes don't align, the result will have a union of indexes, and non-overlapping positions will receive a missing value (default `null`, or the DataFrame's `replaceMissingValueWith` if the Series is part of one). Division by zero also results in a missing value.

**Common Setup for Examples:**
```dart
var s1 = Series([1, 2, 3], name: 's1', index: ['a', 'b', 'c']);
var s2 = Series([10, 20, 30], name: 's2', index: ['a', 'b', 'c']);
var s3 = Series([100, 200], name: 's3', index: ['b', 'd']); // Overlapping index with s1
var sMiss = Series([1, null, 5], name: 'sMiss', index: ['a', 'b', 'c']); // Contains a missing value
```

#### Addition (`+`)
```dart
var resultSameIdx = s1 + s2; // resultSameIdx.data: [11, 22, 33], index: ['a', 'b', 'c']
var resultDiffIdx = s1 + s3; // resultDiffIdx.data: [null, 102, null, null], index: ['a', 'b', 'c', 'd'] (null for 'a','c','d')
var resultWithMiss = s1 + sMiss; // resultWithMiss.data: [2, null, 8], index: ['a', 'b', 'c']
```

#### Subtraction (`-`)
```dart
var result = s1 - s2; // result.data: [-9, -18, -27]
```

#### Multiplication (`*`)
```dart
var result = s1 * s2; // result.data: [10, 40, 90]
```

#### Division (`/`)
```dart
var sDen = Series([2, 0, 3], name: 'den', index: ['a', 'b', 'c']);
var result = s1 / sDen; // result.data: [0.5, null, 1.0] (null due to division by zero at 'b')
```

#### Integer Division (`~/`)
```dart
var result = Series([10, 21], name: 'num') ~/ Series([3, 5], name: 'den'); // result.data: [3, 4]
```

#### Modulo (`%`)
```dart
var result = Series([10, 21], name: 'num') % Series([3, 5], name: 'den'); // result.data: [1, 1]
```

### Bitwise Operations
Similar to arithmetic operations, bitwise operations are element-wise and handle index alignment and missing values. Assume integer inputs for these operations.

#### XOR (`^`)
```dart
var sBit1 = Series([1, 3], name: 'sBit1', index: ['a', 'b']); // 01, 11
var sBit2 = Series([3, 2], name: 'sBit2', index: ['a', 'b']); // 11, 10
var result = sBit1 ^ sBit2; // result.data: [2, 1] (1^3=2, 3^2=1)
```

#### AND (`&`)
```dart
var result = sBit1 & sBit2; // result.data: [1, 2] (1&3=1, 3&2=2)
```

#### OR (`|`)
```dart
var result = sBit1 | sBit2; // result.data: [3, 3] (1|3=3, 3|2=3)
```

### String Operations (`series.str.*`)
The `str` accessor provides a way to apply string functions element-wise. Non-string elements or missing values in the original Series typically result in a missing value in the output Series.

**Setup for String Examples:**
```dart
var s = Series([' Hello', 'World ', null, ' DartFrame ', 123], name: 'myStrings');
// Assume defaultMissingRep is null for standalone Series `s`.
// If s was from a DataFrame with replaceMissingValueWith: 'NA', then 'NA' would be used.
```

#### `str.len()`
Returns a Series of integers representing the length of each string.
```dart
var lengths = s.str.len(); // lengths.data: [6, 6, null, 11, null]
```

#### `str.lower()`, `str.upper()`
Converts strings to lowercase or uppercase.
```dart
var lowercased = s.str.lower(); // lowercased.data: [' hello', 'world ', null, ' dartframe ', null]
var uppercased = s.str.upper(); // uppercased.data: [' HELLO', 'WORLD ', null, ' DARTFRAME ', null]
```

#### `str.strip()`
Removes leading and trailing whitespace.
```dart
var stripped = s.str.strip(); // stripped.data: ['Hello', 'World', null, 'DartFrame', null]
```

#### `str.startswith(pattern)`, `str.endswith(pattern)`
Checks if strings start or end with a pattern. Returns a boolean Series.
```dart
var startsWithH = s.str.startswith(' H'); // startsWithH.data: [true, false, null, false, null]
var endsWithSpace = s.str.endswith(' '); // endsWithSpace.data: [false, true, null, true, null]
```

#### `str.contains(pattern)`
Checks if strings contain a pattern. Returns a boolean Series.
```dart
var containsWorld = s.str.contains('World'); // containsWorld.data: [false, true, null, false, null]
```

#### `str.replace(pattern, replacement)`
Replaces occurrences of `pattern` (String or RegExp) with `replacement`.
```dart
var replaced = s.str.replace(' ', '_'); // Replaces all spaces
// replaced.data: ['_Hello', 'World_', null, '_DartFrame_', null]
var replacedRegex = s.str.replace(RegExp(r'\\s+'), '-'); // Replace blocks of whitespace with a dash
// replacedRegex.data: ['-Hello', 'World-', null, '-DartFrame-', null]
```

### DateTime Conversions

#### `series.toDatetime()`
Converts Series elements to `DateTime` objects.
**Syntax**: `series.toDatetime({String errors = 'raise', String? format, bool inferDatetimeFormat = false})`
- `errors`: How to handle parsing errors:
    - `'raise'` (default): Throws `FormatException`.
    - `'coerce'`: Sets unparseable values to the Series' missing value representation.
    - `'ignore'`: Keeps original unparseable values.
- `format`: A specific `DateFormat` string (e.g., `'yyyy/MM/dd HH:mm'`).
- `inferDatetimeFormat`: If `true` and `format` is `null`, tries to infer format from common patterns.

**Examples:**
```dart
// ISO 8601 strings
final sIso = Series(['2023-10-26T10:30:00', '2023-10-27'], name: 'iso_dt');
final rIso = sIso.toDatetime();
// rIso.data: [DateTime(2023,10,26,10,30), DateTime(2023,10,27)]

// Using a specific format
final sFmt = Series(['2023/10/26 10:45'], name: 'custom_fmt');
final rFmt = sFmt.toDatetime(format: 'yyyy/MM/dd HH:mm');
// rFmt.data.first is DateTime(2023,10,26,10,45)

// Inferring format
final sInfer = Series(['10/26/2023'], name: 'us_date'); // US date format
final rInfer = sInfer.toDatetime(inferDatetimeFormat: true);
// rInfer.data.first is DateTime(2023,10,26)

// Numeric timestamps (milliseconds since epoch)
final ts = DateTime(2023,1,1).millisecondsSinceEpoch;
final sNum = Series([ts, ts + 100000.0], name: 'num_ts');
final rNum = sNum.toDatetime();
// rNum.data contains DateTime objects

// Error handling
final sErr = Series(['bad-date', '2023-01-01'], name: 'err_dt');
final rCoerce = sErr.toDatetime(errors: 'coerce'); // 'bad-date' becomes missing value
// rCoerce.data: [null, DateTime(2023,1,1)] (assuming null is missing rep)
```
- Handles existing `DateTime` objects, `null` values, and custom missing value placeholders from DataFrame context.

## Statistical Methods

### 1. `nunique()`
Counts the number of distinct non-missing values in the Series.
```dart
var s = Series([1, 2, 2, 3, null, 1], name: 'mySeries');
// s.nunique() is 3 (distinct values are 1, 2, 3; null is ignored)

var df = DataFrame.empty(replaceMissingValueWith: -1);
var sCustomMissing = Series([1, -1, 2, -1], name: 'custom');
sCustomMissing.setParent(df, 'custom');
// sCustomMissing.nunique() is 2 (distinct are 1, 2; -1 is ignored)
```
- Handles empty Series (returns 0) and Series with only missing values (returns 0).

### 2. `valueCounts()`
Returns a Series containing counts (or proportions) of unique values.
**Syntax**: `series.valueCounts({bool normalize = false, bool sort = true, bool ascending = false, bool dropna = true})`
- `normalize`: If `true`, returns proportions.
- `sort`: If `true` (default), sorts by frequency.
- `ascending`: If `true`, sorts in ascending frequency.
- `dropna`: If `true` (default), excludes missing values. If `false`, includes count of missing values.
```dart
var s = Series(['a', 'b', 'a', null, 'a'], name: 'letters');
var counts = s.valueCounts(); // counts.data: [3, 1], index: ['a', 'b']
var countsWithNa = s.valueCounts(dropna: false); // Includes count for null
// countsWithNa might be: data: [3,1,1], index: ['a','b',null] (order depends on sort)
var proportions = s.valueCounts(normalize: true); // data: [0.75, 0.25] for 'a', 'b'
```

### 3. Basic Statistics (`count()`, `sum()`, `mean()`, etc.)
These methods perform calculations ignoring missing values (either default `null` or custom from DataFrame context).
```dart
var s = Series([1, 2, null, 4, 5, null], name: 'statsTest');
// s.count() is 4
// s.sum() is 12
// s.mean() is 3.0

var df = DataFrame.empty(replaceMissingValueWith: -1);
var sCustom = Series([-1, 1, 2, -1, 3], name: 'customStats');
sCustom.setParent(df, 'customStats');
// sCustom.count() is 3
// sCustom.sum() is 6
// sCustom.mean() is 2.0
```
*(Other methods like `std()`, `min()`, `max()`, `median()`, `quantile()` would also follow this pattern of ignoring missing values.)*

## Missing Data Handling

### 1. `isna()`
Returns a boolean Series indicating `true` for elements that are missing values.
```dart
final s = Series([1, null, 3, null], name: 's_nulls');
final result = s.isna(); // result.data is [false, true, false, true]

// With custom missing value from DataFrame
final df = DataFrame.empty(replaceMissingValueWith: -999);
final sCustom = Series([1, -999, 3], name: 's_custom');
sCustom.setParent(df, 's_custom');
final resultCustom = sCustom.isna(); // resultCustom.data is [false, true, false]
```
- Works for default `null` and custom missing values defined in a parent DataFrame.
- Handles various data types and empty Series correctly.

### 2. `notna()`
Returns a boolean Series indicating `true` for elements that are NOT missing values (inverse of `isna()`).
```dart
final s = Series([1, null, 3, null], name: 's_nulls');
final result = s.notna(); // result.data is [true, false, true, false]
```
- Also respects custom missing values from DataFrame context.

## Other Operations

### 1. `concatenate()`
*(This method might be an extension or part of DataFrame operations rather than a direct Series method in some implementations. The example code implies its existence.)*
Concatenates another Series to this one.
**Syntax (conceptual):** `series1.concatenate(Series series2, {int axis = 0})`
```dart
Series s1 = Series([1, 2], name: 'A');
Series s2 = Series([3, 4], name: 'A');
// Series sVertical = s1.concatenate(s2); // sVertical.data is [1, 2, 3, 4]
```

## Conversion to DataFrame

### 1. `toDataFrame()`
Converts the Series into a DataFrame with a single column named after the Series.
```dart
var s = Series([10, 20, 30], name: 'MyColumn');
DataFrame df = s.toDataFrame();
// df has one column 'MyColumn' with data [10, 20, 30]
```

## String Representation (`toString()`)
Provides a formatted string representation of the Series, including its index, data, name, length, and data type.
```dart
var s = Series([true, false], name: 'Booleans', index: ['chk1', 'chk2']);
print(s.toString());
/* Output:
      Booleans
chk1  true
chk2  false

Length: 2
Type: bool
*/
```
