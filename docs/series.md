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
      - [`str.split(pattern, n)`](#strsplitpattern-n)
      - [`str.match(regex)`](#strmatchregex)
    - [DateTime Accessor (`series.dt.*`)](#datetime-accessor-seriesdt)
      - [`dt.year`, `dt.month`, `dt.day`](#dtyear-dtmonth-dtday)
      - [`dt.hour`, `dt.minute`, `dt.second`](#dthour-dtminute-dtsecond)
      - [`dt.millisecond`, `dt.microsecond`](#dtmillisecond-dtmicrosecond)
      - [`dt.weekday`](#dtweekday)
      - [`dt.dayofyear`](#dtdayofyear)
      - [`dt.date`](#dtdate)
    - [DateTime Conversions](#datetime-conversions)
      - [`series.toDatetime()`](#seriestodatetime)
  - [Statistical Methods](#statistical-methods)
    - [1. `nunique()`](#1-nunique)
    - [2. `valueCounts()`](#2-valuecounts)
    - [3. `unique()`](#3-unique)
    - [3. Basic Statistics (`count()`, `sum()`, `mean()`, etc.)](#3-basic-statistics-count-sum-mean-etc)
  - [Missing Data Handling](#missing-data-handling)
    - [1. `isna()`](#1-isna)
    - [2. `notna()`](#2-notna)
    - [3. `fillna()`](#3-fillna)
  - [Sorting and Ordering](#sorting-and-ordering)
    - [1. `sort_values()`](#1-sort_values)
    - [2. `sort_index()`](#2-sort_index)
  - [Function Application](#function-application)
    - [1. `apply()`](#1-apply)
  - [Membership Checking](#membership-checking)
    - [1. `isin()`](#1-isin)
  - [Reshaping and Indexing](#reshaping-and-indexing)
    - [1. `reset_index()`](#1-reset_index)
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

##### `str.split(pattern, n)`
Splits each string by the given `pattern` (String).
- `n` (optional `int`): Maximum number of splits. If provided, the last element in the list will contain the rest of the string.
- Returns a Series of `List<String>`. Non-strings/missing values result in the Series' missing value representation.
```dart
var s = Series(['a-b-c', 'x-y-z', null], name: 'to_split');
var split1 = s.str.split('-'); 
// split1.data: [['a','b','c'], ['x','y','z'], null]
var split2 = s.str.split('-', n: 1); 
// split2.data: [['a','b-c-d'], ['x','y-z'], null]
```

##### `str.match(regex)`
For each string, finds the first match of the `RegExp` pattern.
- If the regex has a capture group, returns the first captured group. Otherwise, returns the full match.
- If no match, results in the Series' missing value representation. Non-strings/missing values also result in the missing value representation.
```dart
var s = Series(['item_123', 'product_45', 'no_match', null], name: 'matches');
var matchedDigits = s.str.match(RegExp(r'\d+')); // Match digits
// matchedDigits.data: ['123', '45', null, null]
var capturedGroup = s.str.match(RegExp(r'item_(\d+)')); // Capture digits after 'item_'
// capturedGroup.data: ['123', null, null, null]
```

### DateTime Accessor (`series.dt.*`)
The `dt` accessor provides access to datetime-like properties of Series data, assuming the Series contains `DateTime` objects. If an element is not a `DateTime` object or is a missing value, accessing these properties will result in the Series' missing value representation for that element.

**Setup for DateTime Examples:**
```dart
var dtSeries = Series([
  DateTime(2023, 10, 26, 14, 30, 15), 
  DateTime(2024, 3, 1, 8, 5, 0), 
  null, // Missing value
  'not-a-date' // Invalid type
], name: 'myDateTimes');
// Assume 'null' is the missing representation for dtSeries
```

#### `dt.year`, `dt.month`, `dt.day`
Extract the year, month (1-12), or day of the month (1-31).
```dart
var years = dtSeries.dt.year;     // years.data: [2023, 2024, null, null]
var months = dtSeries.dt.month;   // months.data: [10, 3, null, null]
var days = dtSeries.dt.day;       // days.data: [26, 1, null, null]
```

#### `dt.hour`, `dt.minute`, `dt.second`
Extract the hour (0-23), minute (0-59), or second (0-59).
```dart
var hours = dtSeries.dt.hour;     // hours.data: [14, 8, null, null]
var minutes = dtSeries.dt.minute; // minutes.data: [30, 5, null, null]
var seconds = dtSeries.dt.second; // seconds.data: [15, 0, null, null]
```

#### `dt.millisecond`, `dt.microsecond`
Extract the millisecond (0-999) or microsecond (0-999) component.
```dart
// Assuming dtSeries had millisecond/microsecond precision
var millis = dtSeries.dt.millisecond; // e.g., [ms1, ms2, null, null]
var micros = dtSeries.dt.microsecond; // e.g., [us1, us2, null, null]
```

#### `dt.weekday`
Returns the day of the week (Monday=1, ..., Sunday=7).
```dart
var weekdays = dtSeries.dt.weekday; // e.g., [4 (Thursday), 5 (Friday), null, null]
```

#### `dt.dayofyear`
Returns the ordinal day of the year (1-366).
```dart
var doy = dtSeries.dt.dayofyear; // e.g., [299, 61, null, null] (for non-leap year)
```

#### `dt.date`
Returns a Series of `DateTime` objects with the time component set to midnight (00:00:00.000000).
```dart
var datesOnly = dtSeries.dt.date;
// datesOnly.data: [DateTime(2023,10,26), DateTime(2024,3,1), null, null]
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
- `dropna`: If `true` (default), excludes missing values. If `false`, includes count of missing values. Missing values are represented by `_missingRepresentation` (or `null`) in the resulting index.

**Example:**
```dart
var s = Series(['a', 'b', 'a', 'c', 'a', 'b', null], name: 'letters');
print(s.valueCounts());
// Output (order may vary for counts if not explicitly sorted by value):
// letters_value_counts:
// a       3
// b       2
// c       1
// Length: 3
// Type: int

print(s.valueCounts(normalize: true, ascending: true));
// Output (sorted by frequency ascending):
// letters_value_counts:
// c       0.1666...
// b       0.3333...
// a       0.5
// Length: 3
// Type: double

print(s.valueCounts(dropna: false));
// Output (includes null count):
// letters_value_counts:
// a       3
// b       2
// null    1  (or your DataFrame's missing value marker)
// c       1
// Length: 4
// Type: int
```

### 3. `unique()`
Returns a list of unique values in the Series, preserving the order of their first appearance. Missing values (including `null` and the specific DataFrame's `replaceMissingValueWith` marker) are treated as distinct values and will be included if present.

**Syntax:** `List<dynamic> unique()`

**Returns:** A `List<dynamic>` containing the unique values.

**Example:**
```dart
var s = Series([2, 1, 3, 2, null, 1, null, 'a'], name: 'items');
print(s.unique()); // Output: [2, 1, 3, null, 'a']

var sEmpty = Series<int>([], name: 'empty');
print(sEmpty.unique()); // Output: []
```

### 4. Basic Statistics (`count()`, `sum()`, `mean()`, etc.)
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
A value is considered missing if it is `null` or matches the parent DataFrame's `replaceMissingValueWith` marker (if any), as determined by the internal `_isMissing` helper.
**Example:**
```dart
var s = Series([1, null, 3], name: 'data_with_null');
print(s.isna());
// Output:
// data_with_null_isna:
// 0       false
// 1       true
// 2       false
// Length: 3
// Type: bool
```
- Handles various data types and empty Series correctly.

### 2. `notna()`
Returns a boolean Series indicating `true` for elements that are NOT missing values (inverse of `isna()`).
**Example:**
```dart
var s = Series([1, null, 3], name: 'data_with_null');
print(s.notna());
// Output:
// data_with_null_notna:
// 0       true
// 1       false
// 2       true
// Length: 3
// Type: bool
```

### 3. `fillna()`
Fills missing values in the Series using a specified value or method.
- Missing values are identified if they are `null` or equal to `_parentDataFrame?.replaceMissingValueWith`.
- The original Series is not modified.

**Syntax:** `Series fillna({dynamic value, String? method})`
- `value` (optional `dynamic`): The value to use for filling missing entries.
- `method` (optional `String?`): The method to use for filling.
    - `'ffill'`: Propagate last valid observation forward.
    - `'bfill'`: Use next valid observation to fill gap.
- If both `value` and `method` are provided, `method` takes precedence.

**Returns:** A new `Series` with missing values filled.

**Example:**
```dart
var s = Series([1.0, null, 3.0, null, 5.0], name: 'data');
print(s.fillna(value: 0.0));
// Output: data: [1.0, 0.0, 3.0, 0.0, 5.0]

print(s.fillna(method: 'ffill'));
// Output: data: [1.0, 1.0, 3.0, 3.0, 5.0]

print(s.fillna(method: 'bfill'));
// Output: data: [1.0, 3.0, 3.0, 5.0, 5.0]
```

## Sorting and Ordering

### 1. `sort_values()`
Returns a new `Series` with its data sorted. The original `Series` remains unchanged. The index of the new `Series` is adjusted to correspond to the sorted data.

**Syntax:** `Series sort_values({bool ascending = true, String naPosition = 'last'})`
- `ascending` (default `true`): If `true`, sorts in ascending order. Otherwise, sorts in descending order.
- `naPosition` (default `'last'`): Determines the placement of missing values.
    - `'first'`: Missing values are placed at the beginning.
    - `'last'`: Missing values are placed at the end.

**Returns:** A new `Series` with sorted values and a correspondingly sorted index.

**Example:**
```dart
var s = Series([30, 10, null, 20], name: 'values', index: ['a', 'b', 'c', 'd']);
print(s.sort_values());
// Output:
// values:
// b       10
// d       20
// a       30
// c       null
// Length: 4
// Type: int

print(s.sort_values(ascending: false, naPosition: 'first'));
// Output:
// values:
// c       null
// a       30
// d       20
// b       10
// Length: 4
// Type: int
```

### 2. `sort_index()`
Returns a new `Series` sorted by its index labels. The original `Series` remains unchanged.

**Syntax:** `Series sort_index({bool ascending = true})`
- `ascending` (default `true`): If `true`, sorts the index in ascending order. Otherwise, sorts in descending order.

**Returns:** A new `Series` with data and index reordered based on the sorted index labels.

**Example:**
```dart
var s = Series([10, 20, 5], name: 'data', index: ['c', 'a', 'b']);
print(s.sort_index());
// Output:
// data:
// a       20
// b       5
// c       10
// Length: 3
// Type: int
```

## Function Application

### 1. `apply()`
Applies a user-defined function to each element in the Series. The provided function is responsible for handling any missing values.

**Syntax:** `Series apply(Function(dynamic) func)`
- `func`: A function that takes a single `dynamic` argument (an element from the Series) and returns a `dynamic` transformed value.

**Returns:** A new `Series` with the transformed data, preserving the original `name` and `index` (copied). The original `Series` is not modified.

**Example:**
```dart
var s = Series([1, 2, 3, 4], name: 'numbers');
var sSquared = s.apply((x) => x * x);
// sSquared.data: [1, 4, 9, 16]

var sStringify = s.apply((x) => x == null ? 'missing' : 'Item $x');
// For s = Series([1, null], name:'items'), sStringify.data: ['Item 1', 'missing']
```

## Membership Checking

### 1. `isin()`
Checks whether each element in the Series is contained in a given iterable of `values`.

**Syntax:** `Series isin(Iterable<dynamic> values)`
- `values`: An `Iterable<dynamic>` of values to check for. For performance, if `values` is large, it is recommended to pass a `Set`.

**Returns:** A boolean `Series` showing whether each element in the Series matches an element in `values`. Missing values in the Series result in `false` unless the missing value representation itself is in `values`. The new Series name is suffixed with `_isin`.

**Example:**
```dart
var s = Series([1, 2, 3, null, 4, 1], name: 'data');
var checkValues = [1, 4, null];
var result = s.isin(checkValues);
// result.data: [true, false, false, true, true, true]
// result.name: 'data_isin'
```

## Reshaping and Indexing

### 1. `reset_index()`
Returns a new `Series` or `DataFrame` with a reset index.

**Syntax:** `dynamic reset_index({dynamic level, bool drop = false, String? name, bool inplace = false})`
- `level` (Currently ignored): For `MultiIndex`.
- `drop` (default `false`):
    - If `true`, the current index is discarded, and a new `Series` is returned with a default integer index.
    - If `false`, the current index is converted into a column in a new `DataFrame`. The original Series data becomes another column.
- `name` (optional `String?`): If `drop` is `false`, this is the name for the new column containing the original index values. Defaults to `'index'`.
- `inplace` (Currently ignored): Always returns a new object.

**Returns:** A `Series` if `drop` is `true`, or a `DataFrame` if `drop` is `false`.

**Example:**
```dart
var s = Series([10, 20, 30], name: 'myValues', index: ['x', 'y', 'z']);

// Case 1: drop = true
var sReset = s.reset_index(drop: true);
// sReset is a Series with data [10, 20, 30] and default index [0, 1, 2]

// Case 2: drop = false
var dfFromSeries = s.reset_index(drop: false, name: 'original_index');
// dfFromSeries is a DataFrame:
//   original_index  myValues
// 0              x        10
// 1              y        20
// 2              z        30
```

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
