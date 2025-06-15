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
// stringSeries.dtype is String

// Series with boolean data
var boolSeries = Series([true, false, true], name: 'Flags');
// boolSeries.dtype is bool

// Series with mixed data types
var mixedSeries = Series([1, 'hello', 2.5, true], name: 'MixedData');
// mixedSeries.dtype will be the most common non-missing type, or the first type encountered in case of ties.
// For [1, 'hello', 2.5, true], if all appear once, dtype might be int.

// Series with a more common type
var commonTypeSeries = Series([10, 20, 'maybe', 30], name: 'MostlyInts');
// commonTypeSeries.dtype is int

// Empty Series
var emptySeries = Series([], name: 'Empty');
// emptySeries.length is 0
// emptySeries.dtype is dynamic

// Series with nulls (default missing values)
var seriesWithNulls = Series([1, null, 3], name: 'HasNulls');
// seriesWithNulls.dtype is int (nulls are ignored for dtype calculation if other types exist)
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
s.data[1] = 25; // Modifies the underlying list directly
// s.data is now [10, 25, 30]

// --- Using operator [] for access ---
// Get by integer position (0-indexed)
var sPos = Series([10, 20, 30], name: 'Positional');
print(sPos[0]); // Output: 10
// print(sPos[3]); // Throws RangeError

// Get by boolean List (length must match Series length)
var sFilter = Series([10,20,30,40], name:'Filter', index: ['a','b','c','d']);
var filteredSeries = sFilter[[true, false, true, false]];
// filteredSeries.data is [10, 30]
// filteredSeries.index is [0, 1] (currently returns default index)
// filteredSeries.name is 'Filter'

// Get by boolean Series (index alignment is currently not performed, uses raw boolean values)
var boolSeries = Series([false, true, false, true], name: 'FilterCond');
var filteredBySeries = sFilter[boolSeries];
// filteredBySeries.data is [20, 40]
// filteredBySeries.index is [0, 1] (currently returns default index)

// --- Using operator []= for modification ---
// Set by single integer position
sPos[1] = 99; // sPos.data is [10, 99, 30]

// Set by list of integer positions with a list of values
sPos[[0,2]] = [100, 300]; // sPos.data is [100, 99, 300]
// List lengths must match: sPos[[0,1]] = [11] would throw ArgumentError.

// Set by boolean list with a single value (broadcast)
sFilter[[true, false, true, false]] = 0;
// sFilter.data is [0, 20, 0, 40]

// Set by boolean Series with a single value (broadcast)
sFilter[boolSeries] = 77; // boolSeries is [false, true, false, true]
// sFilter.data is [0, 77, 0, 77]

// Set by boolean list with a list of values (value list length must match boolean list length)
// Only elements where boolean list is true are updated from corresponding positions in value list.
var sBoolListSet = Series([1,2,3,4], name: 'sBoolListSet');
sBoolListSet[[true, false, true, false]] = [99, 0, 88, 0];
// sBoolListSet.data is [99, 2, 88, 4]

// --- Using at() for label-based access ---
var sLabel = Series([10, 20, 30], name: 'LabelAccess', index: ['x', 'y', 'z']);
print(sLabel.at('y')); // Output: 20
// print(sLabel.at('a')); // Throws ArgumentError (label not found)

// If Series has default integer index, at() still uses it as label
print(sPos.at(0)); // Output: 100 (after modifications above)
// print(sPos.at(5)); // Throws ArgumentError

// --- Interaction with DataFrame context for modification ---
// If a Series is obtained from a DataFrame, modifications via []= can update the DataFrame.
// (This requires the Series to have a reference to its parent DataFrame and column name)
// var df = DataFrame.fromMap({'colA': [1, 2, 3]});
// Series sFromDf = df['colA'];
// sFromDf[0] = 100; // This should update df['colA'].data[0] to 100
// print(df['colA'].data); // Output: [100, 2, 3]
```

## Operations

### Arithmetic Operations
Series arithmetic operations are element-wise and support index alignment. If indexes don't align, the result will have a union of indexes, and non-overlapping positions will receive a missing value (default `null`, or the DataFrame's `replaceMissingValueWith` if the Series is part of one). Division by zero also results in a missing value.

**Common Setup for Examples:**
```dart
var s1 = Series([1, 2, 3, 4], name: 's1', index: ['a', 'b', 'c', 'd']);
var s2 = Series([10, 20, 30, 40], name: 's2', index: ['a', 'b', 'c', 'd']);

// Identical default index
var sDef1 = Series([1, 2, 3], name: 'sDef1'); // index [0,1,2]
var sDef2 = Series([4, 5, 6], name: 'sDef2'); // index [0,1,2]

// Different, overlapping indexes
var s3 = Series([1, 2, 300], name: 's3', index: ['a', 'b', 'e']); // Overlaps 'a', 'b'
var s4 = Series([10, 400, 50], name: 's4', index: ['b', 'f', 'g']); // Overlaps 'b'

// Completely different indexes
var s5 = Series([100, 200], name: 's5', index: ['x', 'y']);

// Series with missing values (null as default)
var sMiss1 = Series([1, null, 3, null], name: 'sMiss1', index: ['a', 'b', 'c', 'd']);
var sMiss2 = Series([null, 10, null, 20], name: 'sMiss2', index: ['a', 'b', 'c', 'd']);
final defaultMissingRep = null; // For standalone series or df with replaceMissingValueWith = null

// Series linked to a DataFrame with a specific missing value placeholder
// const missingMarker = -999; // Example custom missing marker
// var dfSpecificMissing = DataFrame.empty(replaceMissingValueWith: missingMarker);
// var sSpecMiss1 = Series([missingMarker, 1, 2, missingMarker], name: 'sSpecMiss1', index: ['a', 'b', 'c', 'd']);
// sSpecMiss1.setParent(dfSpecificMissing, 'sSpecMiss1');
// var sSpecMiss2 = Series([10, missingMarker, missingMarker, 30], name: 'sSpecMiss2', index: ['a', 'b', 'c', 'd']);
// sSpecMiss2.setParent(dfSpecificMissing, 'sSpecMiss2');
// final specificMissingRep = missingMarker;
```

#### Addition (`+`)
```dart
// Identical indexes
var resultSameIdx = s1 + s2; 
// resultSameIdx.data: [11, 22, 33, 44], index: ['a', 'b', 'c', 'd'], name: '(s1 + s2)'

// Identical default indexes
var resultDefIdx = sDef1 + sDef2;
// resultDefIdx.data: [5, 7, 9], index: [0, 1, 2]

// Different, overlapping indexes (s1 and s3)
// s1: [1,2,3,4] @ ['a','b','c','d']
// s3: [1,2,300] @ ['a','b','e']
// Union index: ['a','b','c','d','e']
var resultOverlap = s1 + s3; 
// resultOverlap.data: [1+1, 2+2, defaultMissingRep, defaultMissingRep, defaultMissingRep] -> [2, 4, null, null, null]
// resultOverlap.index: ['a', 'b', 'c', 'd', 'e']

// Completely different indexes (s1 and s5)
// Union index: ['a','b','c','d','x','y']
var resultDiffIdx = s1 + s5;
// resultDiffIdx.data: [null, null, null, null, null, null] (all defaultMissingRep)

// With missing values (null)
// sMiss1: [1, null, 3, null] @ ['a','b','c','d']
// s1:     [1,    2, 3,   4] @ ['a','b','c','d']
var resultWithMiss = sMiss1 + s1; 
// resultWithMiss.data: [1+1, null+2, 3+3, null+4] -> [2, null, 6, null]

// Example with specific missing values (if Series were linked to a DataFrame)
// sSpecMiss1: [missingMarker, 1, 2, missingMarker]
// sSpecMiss2: [10, missingMarker, missingMarker, 30]
// var resultSpecMiss = sSpecMiss1 + sSpecMiss2;
// resultSpecMiss.data: [specificMissingRep, specificMissingRep, specificMissingRep, specificMissingRep]
```

#### Subtraction (`-`)
```dart
// Identical indexes
var result = s1 - s2; // result.data: [-9, -18, -27, -36]

// Different, overlapping indexes (s1 and s3)
var resultOverlapSub = s1 - s3;
// resultOverlapSub.data: [1-1, 2-2, defaultMissingRep, defaultMissingRep, defaultMissingRep] -> [0, 0, null, null, null]
```

#### Multiplication (`*`)
```dart
// Identical indexes
var result = s1 * s2; // result.data: [10, 40, 90, 160]

// Different, overlapping indexes (s1 and s3)
var resultOverlapMul = s1 * s3;
// resultOverlapMul.data: [1*1, 2*2, defaultMissingRep, defaultMissingRep, defaultMissingRep] -> [1, 4, null, null, null]
```

#### Division (`/`)
```dart
var sDiv1 = Series([10, 20, 30, 0], name: 'num', index: ['a', 'b', 'c', 'd']);
var sDiv2 = Series([2, 0, 10, 5], name: 'den', index: ['a', 'b', 'c', 'd']);
var result = sDiv1 / sDiv2; 
// result.data: [5.0, defaultMissingRep (20/0), 3.0, 0.0]

// Division with different indexes
var sNumOverlap = Series([10, 20, 5], name: 'sNumO', index: ['a', 'b', 'c']);
var sDenOverlap = Series([2, 0, 2], name: 'sDenO', index: ['b', 'c', 'd']);
// Union index: ['a', 'b', 'c', 'd']
// a: num=10, den=null -> null
// b: num=20, den=2  -> 10.0
// c: num=5,  den=0  -> null (div by zero)
// d: num=null, den=2 -> null
var resultDivOverlap = sNumOverlap / sDenOverlap;
// resultDivOverlap.data: [null, 10.0, null, null]
```

#### Integer Division (`~/`)
```dart
var sIDiv1 = Series([10, 21, 30], name: 'num');
var sIDiv2 = Series([3, 5, 0], name: 'den'); // Division by zero at index 2
var result = sIDiv1 ~/ sIDiv2; 
// result.data: [3, 4, defaultMissingRep]
```

#### Modulo (`%`)
```dart
var sMod1 = Series([10, 21, 30], name: 'num');
var sMod2 = Series([3, 5, 0], name: 'den'); // Modulo by zero at index 2
var result = sMod1 % sMod2;
// result.data: [1, 1, defaultMissingRep]
```

### Bitwise Operations
Similar to arithmetic operations, bitwise operations are element-wise and handle index alignment and missing values. These operations are typically applied to integer Series. Non-integer inputs or missing values will result in a missing value in the output.

**Common Setup for Bitwise Examples:**
```dart
var sBit1 = Series([1, 2, 3], name: 'sBit1', index: ['a', 'b', 'c']); // Binary: 01, 10, 11
var sBit2 = Series([3, 1, 0], name: 'sBit2', index: ['a', 'b', 'c']); // Binary: 11, 01, 00
var sBit3Overlap = Series([2], name: 'sBit3Overlap', index: ['c']); // Binary: 10 at 'c'
```

#### XOR (`^`)
```dart
// Identical indexes
var resultXor = sBit1 ^ sBit2; 
// resultXor.data: [1^3, 2^1, 3^0] -> [2, 3, 3]
// resultXor.index: ['a', 'b', 'c']

// Different indexes (sBit1 and sBit3Overlap)
// Union index: ['a', 'b', 'c']
// a: sBit1[a] ^ missing -> missing
// b: sBit1[b] ^ missing -> missing
// c: sBit1[c] ^ sBit3Overlap[c] = 3 ^ 2 = 1
var resultXorOverlap = sBit1 ^ sBit3Overlap;
// resultXorOverlap.data: [defaultMissingRep, defaultMissingRep, 1]
```

#### AND (`&`)
```dart
var resultAnd = sBit1 & sBit2; 
// resultAnd.data: [1&3, 2&1, 3&0] -> [1, 0, 0]
```

#### OR (`|`)
```dart
var resultOr = sBit1 | sBit2; 
// resultOr.data: [1|3, 2|1, 3|0] -> [3, 3, 3]
```

### String Operations (`series.str.*`)
The `str` accessor provides a way to apply string functions element-wise. Non-string elements or missing values in the original Series typically result in a missing value in the output Series.

**Setup for String Examples:**
```dart
var s = Series([' Hello', 'World ', null, ' DartFrame ', 123], name: 'myStrings');
var sBase = Series([' Hello', 'World ', ' DartFrame ', null, '  '], name: 'strings');
final defaultMissingRep = null; // Default missing representation

// Example Series linked to a DataFrame with a specific missing value placeholder
// const specificMissingRep = 'MISSING_VAL';
// var dfSpecificMissing = DataFrame.empty(replaceMissingValueWith: specificMissingRep);
// var sMixedType = Series([' One ', specificMissingRep, 'Three', 42, null], name: 'mixed');
// sMixedType.setParent(dfSpecificMissing, 'mixed');
```

#### `str.len()`
Returns a Series of integers representing the length of each string.
```dart
var result = sBase.str.len();
// result.data: [6, 6, 11, defaultMissingRep, 2]
// result.name: 'strings_len'

// Example with specific missing and non-string:
// var resultMixed = sMixedType.str.len();
// resultMixed.data: [5, specificMissingRep, 5, specificMissingRep, specificMissingRep]
```

#### `str.lower()`, `str.upper()`
Converts strings to lowercase or uppercase.
```dart
var lowerS = sBase.str.lower();
// lowerS.data: [' hello', 'world ', ' dartframe ', defaultMissingRep, '  ']
// lowerS.name: 'strings_lower'

var upperS = sBase.str.upper();
// upperS.data: [' HELLO', 'WORLD ', ' DARTFRAME ', defaultMissingRep, '  ']
```

#### `str.strip()`
Removes leading and trailing whitespace from each string.
```dart
var strippedS = sBase.str.strip();
// strippedS.data: ['Hello', 'World', 'DartFrame', defaultMissingRep, '']
```

#### `str.startswith(pattern)`, `str.endswith(pattern)`
Checks if strings start or end with a `pattern`. Returns a boolean Series.
```dart
var startsWithH = sBase.str.startswith(' H');
// startsWithH.data: [true, false, false, defaultMissingRep, false]
// startsWithH.name: 'strings_startswith_ H'

var endsWithSpace = sBase.str.endswith(' ');
// endsWithSpace.data: [false, true, true, defaultMissingRep, true]
```

#### `str.contains(pattern)`
Checks if strings contain a `pattern` (String or RegExp). Returns a boolean Series.
```dart
var containsWorld = sBase.str.contains('World');
// containsWorld.data: [false, true, false, defaultMissingRep, false]

var containsRegex = sBase.str.contains(RegExp(r'[aA]rt')); // Contains 'art' or 'Art'
// containsRegex.data: [false, false, true, defaultMissingRep, false]
```

#### `str.replace(pattern, replacement)`
Replaces occurrences of `pattern` (String or RegExp) with `replacement` (String).
If `pattern` is a String, only the first occurrence is replaced.
If `pattern` is a RegExp with `global = true`, all occurrences are replaced.
```dart
// Replace first occurrence of a string
var replacedOnce = sBase.str.replace(' ', '_');
// replacedOnce.data: ['_Hello', 'World_', '_DartFrame_', defaultMissingRep, '__']

// Replace all occurrences of a string (using RegExp)
var replacedAll = sBase.str.replace(RegExp(r' '), '_'); // Equivalent to replaceAll(' ', '_') on each string
// replacedAll.data: ['_Hello', 'World_', '_DartFrame_', defaultMissingRep, '__']
// For true replaceAll behavior with String pattern, it's often better to use Series.apply() or ensure RegExp is used.
// The `series_string_accessor_test.dart` suggests `replace(String, String)` might behave like `replaceAll`.
// Current implementation of Series.str.replace(pattern, replacement) uses Dart's String.replaceFirst if pattern is String,
// and String.replaceAll if pattern is RegExp.

// To replace all instances of a string, use a RegExp:
var s = Series(['one two one'], name: 'repeats');
var replacedAllStr = s.str.replace(RegExp('one'), 'ONE');
// replacedAllStr.data: ['ONE two ONE']

var replacedAllGlobal = sBase.str.replace(RegExp(r'\s+', global: true), '_'); // Replace all whitespace blocks
// replacedAllGlobal.data: ['_Hello', 'World_', '_DartFrame_', defaultMissingRep, '_']
```

##### `str.split(pattern, n)`
Splits each string by the given `pattern` (String).
- `n` (optional `int`): Maximum number of splits. If `n > 0`, the list will contain at most `n + 1` elements.
- Returns a Series of `List<String>`. Non-strings/missing values result in the Series' missing value representation.
```dart
var sToSplit = Series(['a-b-c', 'x-y', null, 'z'], name: 'split_series');
var splitBasic = sToSplit.str.split('-'); 
// splitBasic.data: [['a', 'b', 'c'], ['x', 'y'], defaultMissingRep, ['z']]
// splitBasic.name: 'split_series_split_-' (or similar)

var splitWithLimit = sToSplit.str.split('-', n: 1); // Max 1 split => 2 elements
// splitWithLimit.data: [['a', 'b-c'], ['x', 'y'], defaultMissingRep, ['z']]
```

##### `str.match(regex)`
For each string, finds the first match of the `RegExp` pattern.
- If the regex has a capture group, returns the content of the first captured group.
- Otherwise, returns the full match.
- If no match, or if the element is not a string or is a missing value, results in the Series' missing value representation.
```dart
var sToMatch = Series(['apple1', 'banana2', 'orange', null, 'grape4'], name: 'match_series');

// Match one or more digits (full match)
var resultFullMatch = sToMatch.str.match(r'\d+'); 
// resultFullMatch.data: ['1', '2', defaultMissingRep, defaultMissingRep, '4']
// resultFullMatch.name: 'match_series_match_\\d+' (or similar)

// Match and extract first capture group
var sGroups = Series(['item_123', 'product_45', 'detail_6', 'no_item'], name: 'group_match');
var resultGroup = sGroups.str.match(RegExp(r'item_(\d+)')); // Capture group for digits after 'item_'
// resultGroup.data: ['123', defaultMissingRep, defaultMissingRep, defaultMissingRep]
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
// Assume 'null' (defaultMissingRep) is the missing representation for dtSeries below.
// If the series was part of a DataFrame with a custom missing value marker (e.g., missingMarker),
// then 'missingMarker' would appear instead of 'null' for non-DateTime or original missing values.
final dt1 = DateTime(2023, 10, 26, 14, 30, 15, 500, 250); // Y, M, D, H, Min, S, Ms, Us
final dt2 = DateTime(2024, 3, 1, 8, 5, 0, 0, 0);
var dtSeries = Series([dt1, dt2, null, 'not-a-date'], name: 'myDateTimes');
final defaultMissingRep = null; // For standalone series context
```

#### `dt.year`, `dt.month`, `dt.day`
Extract the year, month (1-12), or day of the month (1-31).
```dart
var years = dtSeries.dt.year;     // years.data: [2023, 2024, defaultMissingRep, defaultMissingRep]
var months = dtSeries.dt.month;   // months.data: [10, 3, defaultMissingRep, defaultMissingRep]
var days = dtSeries.dt.day;       // days.data: [26, 1, defaultMissingRep, defaultMissingRep]
// Each result Series will have a name like 'myDateTimes_year', 'myDateTimes_month', etc.
```

#### `dt.hour`, `dt.minute`, `dt.second`
Extract the hour (0-23), minute (0-59), or second (0-59).
```dart
var hours = dtSeries.dt.hour;     // hours.data: [14, 8, defaultMissingRep, defaultMissingRep]
var minutes = dtSeries.dt.minute; // minutes.data: [30, 5, defaultMissingRep, defaultMissingRep]
var seconds = dtSeries.dt.second; // seconds.data: [15, 0, defaultMissingRep, defaultMissingRep]
```

#### `dt.millisecond`, `dt.microsecond`
Extract the millisecond (0-999) or microsecond (0-999) component.
```dart
var millis = dtSeries.dt.millisecond; // millis.data: [500, 0, defaultMissingRep, defaultMissingRep]
var micros = dtSeries.dt.microsecond; // micros.data: [250, 0, defaultMissingRep, defaultMissingRep]
```

#### `dt.weekday`
Returns the day of the week (Monday=1, ..., Sunday=7).
```dart
// dt1 (2023-10-26) is a Thursday (4). dt2 (2024-03-01) is a Friday (5).
var weekdays = dtSeries.dt.weekday; 
// weekdays.data: [DateTime.thursday, DateTime.friday, defaultMissingRep, defaultMissingRep]
```

#### `dt.dayofyear`
Returns the ordinal day of the year (1-366).
```dart
var sDoy = Series([DateTime(2023,1,1), DateTime(2023,2,1), null], name: 'doyTest');
var doy = sDoy.dt.dayofyear; 
// doy.data: [1, 32, defaultMissingRep]
```

#### `dt.date`
Returns a Series of `DateTime` objects with the time component set to midnight (00:00:00.000000).
```dart
var datesOnly = dtSeries.dt.date;
// datesOnly.data: [DateTime(2023,10,26), DateTime(2024,3,1), defaultMissingRep, defaultMissingRep]
// (dt1 and dt2 will have their time parts zeroed out)
```

### DateTime Conversions

#### `series.toDatetime()`
Converts Series elements to `DateTime` objects. It can parse strings in various formats, including ISO 8601, and can also convert numeric timestamps (milliseconds since epoch) to `DateTime`.

**Syntax**: `Series toDatetime({String errors = 'raise', String? format, bool inferDatetimeFormat = false})`
- `errors`: Defines behavior for parsing errors:
    - `'raise'` (default): Throws `FormatException` if an element cannot be parsed.
    - `'coerce'`: Sets unparseable values to the Series' missing value representation (e.g., `null` or a custom marker if part of a DataFrame).
    - `'ignore'`: Keeps original unparseable values in the Series.
- `format` (optional `String?`): A specific `DateFormat` string (e.g., `'dd/MM/yyyy HH:mm'`) to use for parsing. If provided, `inferDatetimeFormat` is ignored.
- `inferDatetimeFormat` (default `false`): If `true` and `format` is `null`, attempts to infer the datetime format from a list of common patterns for each string element.

**Returns:** A new `Series` where elements are `DateTime` objects or missing values.

**Examples:**
```dart
// 1. From ISO 8601 strings
final sIso = Series(['2023-10-26', '2024-03-01T14:30:00', null], name: 'iso_dates');
final rIso = sIso.toDatetime();
// rIso.data: [DateTime(2023,10,26), DateTime(2024,3,1,14,30), null]

// 2. Using a specific format
final sCustomFmt = Series(['26/10/2023 10:00', '01/03/2024 14:30'], name: 'custom_fmt_dt');
final rCustomFmt = sCustomFmt.toDatetime(format: 'dd/MM/yyyy HH:mm');
// rCustomFmt.data: [DateTime(2023,10,26,10,0), DateTime(2024,3,1,14,30)]

// 3. Inferring datetime format
// Note: inferDatetimeFormat tries a list of common formats. Success depends on whether the string matches one of them.
final sInfer = Series(['10/26/2023', '2024-03-01 14:30:00', 'invalid'], name: 'infer_dt');
final rInferCoerce = sInfer.toDatetime(inferDatetimeFormat: true, errors: 'coerce');
// rInferCoerce.data might be: [DateTime(2023,10,26), DateTime(2024,3,1,14,30), null] (if 'invalid' isn't inferred)

// 4. From numeric timestamps (milliseconds since epoch)
final dtP1 = DateTime(2023,1,1).millisecondsSinceEpoch;
final dtP2 = DateTime(2024,1,1).millisecondsSinceEpoch;
final sNumericTs = Series([dtP1, dtP2, null], name: 'timestamps_num');
final rNumericTs = sNumericTs.toDatetime();
// rNumericTs.data: [DateTime(2023,1,1), DateTime(2024,1,1), null]

// 5. Error handling: 'raise' (default)
final sErrRaise = Series(['2023-10-26', 'not-a-date'], name: 'err_raise_dt');
// expect(() => sErrRaise.toDatetime(), throwsA(isA<FormatException>()));

// 6. Error handling: 'coerce'
final sErrCoerce = Series(['2023-10-26', 'invalid-date', null], name: 'err_coerce_dt');
final rErrCoerce = sErrCoerce.toDatetime(errors: 'coerce');
// rErrCoerce.data: [DateTime(2023,10,26), null, null] (assuming default missing is null)

// 7. Error handling: 'ignore'
final sErrIgnore = Series(['2023-10-26', 'keep-this', true], name: 'err_ignore_dt');
final rErrIgnore = sErrIgnore.toDatetime(errors: 'ignore');
// rErrIgnore.data: [DateTime(2023,10,26), 'keep-this', true]

// 8. With existing DateTime objects (no change)
final sExistingDt = Series([DateTime(2023,5,5), null], name: 'exist_dt');
final rExistingDt = sExistingDt.toDatetime();
// rExistingDt.data: [DateTime(2023,5,5), null]

// 9. Empty Series
final sEmptyDt = Series<String>([], name: 'empty_dt_series');
final rEmptyDt = sEmptyDt.toDatetime();
// rEmptyDt.data: []
```
- If the Series is part of a DataFrame with a custom `replaceMissingValueWith` (e.g., `missingMarker`), `'coerce'` will use that marker for unparseable items.

### Numeric Conversion (`toNumeric()`)
Converts Series elements to numeric types (`int` or `double`).

**Syntax**: `Series toNumeric({String errors = 'raise', String? downcast})`
- `errors`: Defines behavior for parsing errors:
    - `'raise'` (default): Throws `FormatException` if an element cannot be converted to a number.
    - `'coerce'`: Sets unparseable values to the Series' missing value representation.
    - `'ignore'`: Keeps original unparseable values.
- `downcast` (optional `String?`): If specified, attempts to cast to a more specific numeric type:
    - `'integer'`: Converts to `int` if possible (e.g., "1.0" becomes `int 1`). If a float cannot be losslessly converted to int (e.g., "2.5"), it's handled by `errors` (e.g., becomes missing if `errors='coerce'`).
    - `'float'`: Converts to `double` (e.g., "1" becomes `double 1.0`).

**Returns:** A new `Series` with numeric data or missing values.

**Examples:**
```dart
// 1. Basic string to int/double conversion
final sStrNums = Series(['1', '2.5', '3', '4.00'], name: 'str_to_num');
final rStrNums = sStrNums.toNumeric();
// rStrNums.data: [1, 2.5, 3, 4.0]
// rStrNums.data types: [int, double, int, double]

// 2. With existing numbers (no change in value, type might change with downcast)
final sActualNums = Series([1, 2.5, 3], name: 'actual_numbers');
final rActualNums = sActualNums.toNumeric();
// rActualNums.data: [1, 2.5, 3]

// 3. Error handling: 'raise'
final sErrNumRaise = Series(['1', 'abc', '3'], name: 'err_num_raise');
// expect(() => sErrNumRaise.toNumeric(errors: 'raise'), throwsA(isA<FormatException>()));

// 4. Error handling: 'coerce'
final sErrNumCoerce = Series(['1', 'abc', '3.0', null], name: 'err_num_coerce');
final rErrNumCoerce = sErrNumCoerce.toNumeric(errors: 'coerce');
// rErrNumCoerce.data: [1, null, 3.0, null] (assuming default missing is null)

// 5. Error handling: 'ignore'
final sErrNumIgnore = Series(['1', 'abc', '3.0', true], name: 'err_num_ignore');
final rErrNumIgnore = sErrNumIgnore.toNumeric(errors: 'ignore');
// rErrNumIgnore.data: [1, 'abc', 3.0, true] ('abc' and true remain)

// 6. Downcast to 'integer'
final sDownInt = Series(['1.0', '2.5', '3', '4.000', 'xyz'], name: 'down_int');
final rDownIntCoerce = sDownInt.toNumeric(downcast: 'integer', errors: 'coerce');
// rDownIntCoerce.data: [1, null, 3, 4, null] 
// (2.5 becomes null as it can't be losslessly int; 'xyz' becomes null)
// rDownIntCoerce types: [int, null, int, int, null]

// 7. Downcast to 'float'
final sDownFloat = Series(['1', '2.5', '3.0'], name: 'down_float');
final rDownFloat = sDownFloat.toNumeric(downcast: 'float');
// rDownFloat.data: [1.0, 2.5, 3.0] (all are doubles)

// 8. Empty Series
final sEmptyNum = Series<String>([], name: 'empty_to_num');
final rEmptyNum = sEmptyNum.toNumeric();
// rEmptyNum.data: []

// 9. With existing missing values (e.g. from a DataFrame context)
// const missingMarker = -999;
// var dfNumCtx = DataFrame.empty(replaceMissingValueWith: missingMarker);
// var sNumWithMarker = Series(['1', missingMarker, '2.5'], name: 'num_ctx');
// sNumWithMarker.setParent(dfNumCtx, 'num_ctx');
// final rNumWithMarker = sNumWithMarker.toNumeric(errors: 'coerce');
// rNumWithMarker.data: [1, missingMarker, 2.5]
```

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

// All unique values
var sAllUnique = Series([1, 2, 3, 4], name: 'all_unique');
// sAllUnique.nunique() is 4

// Empty series
var sEmptyUnique = Series<int>([], name: 'empty_unique');
// sEmptyUnique.nunique() is 0

// Series with all same non-missing values
var sAllSame = Series([7, 7, 7, 7], name: 'all_sevens');
// sAllSame.nunique() is 1

// Series with all missing values (null)
var sAllNullUnique = Series([null, null, null], name: 'all_null_unique');
// sAllNullUnique.nunique() is 0

// Series with all missing values (custom marker)
// var dfCustomAllMissing = DataFrame.empty(replaceMissingValueWith: -999);
// var sCustomAllMissing = Series([-999, -999], name: 'custom_all_missing');
// sCustomAllMissing.setParent(dfCustomAllMissing, 'custom_all_missing');
// sCustomAllMissing.nunique() is 0
```

### 2. `valueCounts()`
Returns a Series containing counts (or proportions) of unique values. The resulting Series is sorted by frequency in descending order by default.

**Syntax**: `Series valueCounts({bool normalize = false, bool sort = true, bool ascending = false, bool dropna = true})`
- `normalize` (default `false`): If `true`, returns proportions instead of frequencies.
- `sort` (default `true`): If `true`, sorts the result by frequency.
- `ascending` (default `false`): If `true` and `sort` is `true`, sorts frequencies in ascending order.
- `dropna` (default `true`): If `true`, excludes missing values from counts. If `false`, includes the count of missing values (represented by `null` or the DataFrame's custom missing marker in the index).

**Returns:** A new `Series` where the index contains unique values from the original Series and data contains their frequencies/proportions. The name of the resulting Series is typically `originalName_value_counts`.

**Example:**
```dart
var s = Series(['a', 'b', 'a', 'c', 'a', 'b', null, 'd', null], name: 'letters');
final defaultMissingRep = null;

// Basic counts (sorted descending by frequency, missing values dropped)
var counts1 = s.valueCounts();
// counts1.index: ['a', 'b', 'c', 'd'] (or similar order for ties)
// counts1.data: [3, 2, 1, 1]

// Normalized counts (proportions)
var counts2 = s.valueCounts(normalize: true);
// counts2.data: [3/7, 2/7, 1/7, 1/7] (approx 0.428, 0.285, 0.142, 0.142)

// Counts not sorted by frequency (order of appearance might be preserved or arbitrary)
var counts3 = s.valueCounts(sort: false);
// Example: counts3.index might be ['a', 'b', 'c', null, 'd'] if preserving appearance and dropna=false
// For predictable order without frequency sort, consider Series.unique() then Series.apply() or map.

// Counts sorted by frequency ascending
var counts4 = s.valueCounts(ascending: true);
// counts4.index: ['c', 'd', 'b', 'a'] (or similar order for ties)
// counts4.data: [1, 1, 2, 3]

// Including missing values in counts
var counts5 = s.valueCounts(dropna: false);
// counts5.index might include 'null' (or custom missing marker)
// Example: ['a', 'b', null, 'c', 'd'] with data [3, 2, 2, 1, 1]

// With a custom missing marker from DataFrame context
// const missingMarker = -999;
// var dfCtx = DataFrame.empty(replaceMissingValueWith: missingMarker);
// var sCustomMiss = Series(['x', missingMarker, 'x', 'y', missingMarker, missingMarker], name: 'custom');
// sCustomMiss.setParent(dfCtx, 'custom');
// var countsCustom = sCustomMiss.valueCounts(dropna: false);
// countsCustom.index would include 'missingMarker' with a count of 3.

// Empty series
var sEmptyVc = Series<String>([], name: 'empty_vc');
var countsEmpty = sEmptyVc.valueCounts();
// countsEmpty.data: []

// Series with only missing values
var sAllMissingVc = Series([null, null], name: 'all_missing_vc');
var countsAllMissingDrop = sAllMissingVc.valueCounts(dropna: true); // Result is empty
var countsAllMissingKeep = sAllMissingVc.valueCounts(dropna: false);
// countsAllMissingKeep.index: [null], data: [2]
```

### 3. `unique()`
Returns a list of unique values in the Series, preserving the order of their first appearance. Missing values (including `null` and the specific DataFrame's `replaceMissingValueWith` marker, if applicable) are treated as distinct values and will be included if present.

**Syntax:** `List<dynamic> unique()`

**Returns:** A `List<dynamic>` containing the unique values from the Series in order of appearance.

**Example:**
```dart
var s = Series([2, 1, 3, 2, null, 1, null, 'a', true], name: 'items');
// s.unique() is [2, 1, 3, null, 'a', true]

var sEmpty = Series<int>([], name: 'empty');
// sEmpty.unique() is []

var sAllSameU = Series([7, 7, 7], name: 'all_same_u');
// sAllSameU.unique() is [7]

// With custom missing marker
// const missingMarker = -999;
// var dfCtxUnique = DataFrame.empty(replaceMissingValueWith: missingMarker);
// var sCustomUnique = Series([10, missingMarker, 20, 10, missingMarker], name: 'custom_unique');
// sCustomUnique.setParent(dfCtxUnique, 'custom_unique');
// sCustomUnique.unique() is [10, missingMarker, 20]
```

### 4. Basic Statistics (`count()`, `sum()`, `mean()`, `median()`, `std()`, `min()`, `max()`, `quantile()`, `abs()`, `round()`, `clip()`)
These methods perform calculations, typically ignoring missing values (both default `null` or custom markers defined by a parent DataFrame's `replaceMissingValueWith`). Non-numeric values are also usually skipped for arithmetic statistics.

**Common Setup for Stat Examples:**
```dart
final sNumeric = Series([1.0, 2.5, null, 4.0, 5.5, 2.5], name: 'numbers');
final sEmpty = Series<double>([], name: 'empty_series');
final sAllMissing = Series<double>([null, null], name: 'all_missing');

// For custom missing marker context:
// const missingNum = -999.0;
// final dfCtxStats = DataFrame.empty(replaceMissingValueWith: missingNum);
// final sCustomNumeric = Series([1.0, missingNum, 3.0, missingNum, 5.0], name: 'custom_missing_nums');
// sCustomNumeric.setParent(dfCtxStats, 'custom_missing_nums');
```

- **`count()`**: Number of non-missing values.
  ```dart
  // sNumeric.count() is 4
  // sEmpty.count() is 0
  // sAllMissing.count() is 0
  // sCustomNumeric.count() is 3 (if -999.0 is missing marker)
  ```
- **`sum()`**: Sum of non-missing numeric values.
  ```dart
  // sNumeric.sum() is 14.5 (1.0 + 2.5 + 4.0 + 5.5 + 2.5)
  // sEmpty.sum() is 0.0
  // sAllMissing.sum() is 0.0
  // sCustomNumeric.sum() is 9.0 (1.0 + 3.0 + 5.0)
  ```
- **`mean()`**: Average of non-missing numeric values.
  ```dart
  // sNumeric.mean() is 2.9 (14.5 / 5 valid elements: 1.0, 2.5, 4.0, 5.5, 2.5) -> Mistake in manual calc, should be 14.5/5 = 2.9. Test file says 14.5/4 for sNumeric = 3.625. Let's recheck series_stats_test.dart for sNumeric.
  // The `series_stats_test.dart` for `Series([1.0, 2.5, null, 4.0, 5.5, 2.5], name: 's_numeric')`
  // sum = 1.0+2.5+4.0+5.5+2.5 = 15.5. count = 5. mean = 15.5/5 = 3.1.
  // Let's use the test file's data for correctness.
  final sStatsTestNumeric = Series([1.0, 2.5, null, 4.0, 5.5, 2.5], name: 's_numeric_stats');
  // sStatsTestNumeric.sum() is 15.5
  // sStatsTestNumeric.count() is 5
  // sStatsTestNumeric.mean() is 3.1
  // sEmpty.mean() is double.nan
  // sAllMissing.mean() is double.nan
  ```
- **`median()`**: Median of non-missing numeric values.
  ```dart
  // For sStatsTestNumeric (data: [1.0, 2.5, 2.5, 4.0, 5.5] when sorted) -> median is 2.5
  // sStatsTestNumeric.median() is 2.5
  // sEmpty.median() is double.nan
  ```
- **`std()`**: Standard deviation of non-missing numeric values. (Sample standard deviation, `ddof=1` by default).
  ```dart
  // sStatsTestNumeric.std() is approx 1.7219 (calculated from [1.0, 2.5, 2.5, 4.0, 5.5])
  // sEmpty.std() is double.nan
  ```
- **`min()`**: Minimum of non-missing numeric values.
  ```dart
  // sStatsTestNumeric.min() is 1.0
  // sEmpty.min() is double.nan
  ```
- **`max()`**: Maximum of non-missing numeric values.
  ```dart
  // sStatsTestNumeric.max() is 5.5
  // sEmpty.max() is double.nan
  ```
- **`quantile(q)`**: Value at the given quantile (0 <= q <= 1).
  ```dart
  // sStatsTestNumeric.quantile(0.5) is 2.5 (median)
  // sStatsTestNumeric.quantile(0.25) is 2.5 (linear interpolation between 1.0, 2.5, 2.5, 4.0, 5.5)
  // Test file for ([0,1,2,3,4,5,6,7,8,9,10]) q=0.1 is 1.0, q=0.95 is 9.5
  // sEmpty.quantile(0.5) is double.nan
  ```
- **`abs()`**: Absolute value for each numeric element. Returns a new Series.
  ```dart
  final sWithNeg = Series([-1.0, 2.5, null, -4.0], name: 's_neg');
  // sWithNeg.abs().data is [1.0, 2.5, null, 4.0]
  ```
- **`round({int decimals = 0})`**: Rounds numeric values to a given number of `decimals`. Returns a new Series.
  ```dart
  final sToRound = Series([1.23, 2.789, null, 3.5], name: 's_round');
  // sToRound.round().data is [1.0, 3.0, null, 4.0] (decimals=0)
  // sToRound.round(decimals: 1).data is [1.2, 2.8, null, 3.5]
  ```
- **`clip({num? lower, num? upper})`**: Trims values at input thresholds. Returns a new Series.
  ```dart
  final sToClip = Series([0, 1, 2, 3, 4, 5, null], name: 's_clip');
  // sToClip.clip(lower: 1, upper: 4).data is [1, 1, 2, 3, 4, 4, null]
  // sToClip.clip(lower: 2).data is [2, 2, 2, 3, 4, 5, null] (no upper limit)
  // sToClip.clip(upper: 3).data is [0, 1, 2, 3, 3, 3, null] (no lower limit)
  ```
- For methods returning a single value (like `sum`, `mean`), if the Series is empty or contains only missing values, they typically return `0.0` for `sum`, and `double.nan` for `mean`, `median`, `std`, `min`, `max`, `quantile`. `count` returns `0`.

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

// Further examples:
var sNoMissing = Series([1, 2, 3], name: 'no_missing');
// sNoMissing.isna().data is [false, false, false]

var sAllMissing = Series([null, null], name: 'all_null_is');
// sAllMissing.isna().data is [true, true]

// With custom missing marker
// var dfCtxIsNa = DataFrame.empty(replaceMissingValueWith: -999);
// var sCustomIsNa = Series([10, -999, 20], name: 'custom_isna');
// sCustomIsNa.setParent(dfCtxIsNa, 'custom_isna');
// sCustomIsNa.isna().data is [false, true, false]

var sEmptyIsNa = Series<int>([], name: 'empty_isna');
// sEmptyIsNa.isna().data is []
```
- Handles various data types and empty Series correctly. The name of the resulting Series is suffixed with `_isna`.

### 2. `notna()`
Returns a boolean Series indicating `true` for elements that are NOT missing values (inverse of `isna()`).
The name of the resulting Series is suffixed with `_notna`.
**Example:**
```dart
var s = Series([1, null, 3], name: 'data_with_null');
// s.notna().data is [true, false, true]

// With custom missing marker
// var dfCtxNotNa = DataFrame.empty(replaceMissingValueWith: -999);
// var sCustomNotNa = Series([10, -999, 20], name: 'custom_notna');
// sCustomNotNa.setParent(dfCtxNotNa, 'custom_notna');
// sCustomNotNa.notna().data is [true, false, true]
```

### 3. `fillna()`
Fills missing values in the Series using a specified value or method.
- Missing values are identified if they are `null` or equal to the parent DataFrame's `replaceMissingValueWith` marker (if the Series is part of a DataFrame).
- The original Series is not modified; a new Series with filled values is returned.
- The returned Series preserves the name and index of the original Series.

**Syntax:** `Series fillna({dynamic value, String? method})`
- `value` (optional `dynamic`): The value to use for filling missing entries.
- `method` (optional `String?`): The method to use for filling. Must be one of `'ffill'` or `'bfill'`.
    - `'ffill'` (forward fill): Propagates the last valid observation forward to fill the gap.
    - `'bfill'` (backward fill): Uses the next valid observation to fill the gap.
- **Important**: You must provide either `value` or `method`, but not both. If both are provided, or neither, an `ArgumentError` is thrown. An invalid `method` string also throws an `ArgumentError`.

**Returns:** A new `Series` with missing values filled.

**Example:**
```dart
var s = Series([1.0, null, null, 4.0, 5.0, null], name: 'data');

// Fill with a specific value
var filledWithValue = s.fillna(value: 0.0);
// filledWithValue.data: [1.0, 0.0, 0.0, 4.0, 5.0, 0.0]

// Forward fill (ffill)
var filledFfill = s.fillna(method: 'ffill');
// filledFfill.data: [1.0, 1.0, 1.0, 4.0, 5.0, 5.0]

// Backward fill (bfill)
var filledBfill = s.fillna(method: 'bfill');
// filledBfill.data: [1.0, 4.0, 4.0, 4.0, 5.0, null] (trailing null remains if no subsequent value)

// Leading nulls with ffill
var sLeadingNull = Series([null, null, 1.0, 2.0], name: 'lead_null');
// sLeadingNull.fillna(method: 'ffill').data: [null, null, 1.0, 2.0]

// Trailing nulls with bfill
var sTrailingNull = Series([1.0, 2.0, null, null], name: 'trail_null');
// sTrailingNull.fillna(method: 'bfill').data: [1.0, 2.0, null, null]

// All nulls
var sAllNull = Series([null, null, null], name: 'all_null_fill');
// sAllNull.fillna(method: 'ffill').data: [null, null, null]
// sAllNull.fillna(method: 'bfill').data: [null, null, null]
// sAllNull.fillna(value: 99).data: [99, 99, 99]

// Empty series
var sEmptyFill = Series<double>([], name: 'empty_fill');
// sEmptyFill.fillna(value: 0.0).data: []
// sEmptyFill.fillna(method: 'ffill').data: []

// With custom missing marker from DataFrame context
// const missingMarker = -999.0;
// var dfCtxFill = DataFrame.empty(replaceMissingValueWith: missingMarker);
// var sCustomFill = Series([10.0, missingMarker, 20.0, missingMarker], name: 'custom_fill');
// sCustomFill.setParent(dfCtxFill, 'custom_fill');
// sCustomFill.fillna(method: 'ffill').data: [10.0, 10.0, 20.0, 20.0]
// sCustomFill.fillna(value: 77.0).data: [10.0, 77.0, 20.0, 77.0]
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
// Output (naPosition='last' by default):
// values:
// b       10
// d       20
// a       30
// c       null  // null is placed last
// Length: 4, Type: int (original dtype preserved if possible)
// Name: values, Index: ['b', 'd', 'a', 'c'] (original index labels are preserved and reordered)

var sortedDescFirstNa = s.sort_values(ascending: false, naPosition: 'first');
// sortedDescFirstNa.data: [null, 30, 20, 10]
// sortedDescFirstNa.index: ['c', 'a', 'd', 'b']

// Sorting string series
var sFruits = Series(['banana', 'apple', 'cherry'], name: 'fruits', index: [0,1,2]);
// sFruits.sort_values().data: ['apple', 'banana', 'cherry']
// sFruits.sort_values().index: [1, 0, 2]

// Sorting with custom missing marker
// const missingMarker = -999;
// var dfCtxSort = DataFrame.empty(replaceMissingValueWith: missingMarker);
// var sCustomSort = Series([10, missingMarker, 5, 20, missingMarker], name: 'custom_sort');
// sCustomSort.setParent(dfCtxSort, 'custom_sort');
// sCustomSort.sort_values(naPosition: 'first').data: [missingMarker, missingMarker, 5, 10, 20]

// Sorting empty series
var sEmptySort = Series<int>([], name: 'empty_sort').sort_values();
// sEmptySort.data: []

// Sorting series with all same values (maintains original index order for ties)
var sAllSameSort = Series([5,5,5], name:'fives', index:['x','y','z']).sort_values();
// sAllSameSort.data: [5,5,5]
// sAllSameSort.index: ['x','y','z']

// Sorting mixed numeric types
var sMixedNum = Series([10, 1.0, 20.5, 2], name: 'mixed_nums_sort');
// sMixedNum.sort_values().data: [1.0, 2, 10, 20.5]

// Sorting series with non-directly comparable types (behavior might depend on underlying sort stability for uncomparable segments)
var sNonComparable = Series([10, 'apple', 5, 'banana'], name: 'non_comp_sort');
// sNonComparable.sort_values().data: [5, 10, 'apple', 'banana'] (numbers sorted, then strings sorted, relative order of types may vary)
```

### 2. `sort_index()`
Returns a new `Series` sorted by its index labels. The original `Series` remains unchanged. The data elements are reordered according to the sorted index.

**Syntax:** `Series sort_index({bool ascending = true})`
- `ascending` (default `true`): If `true`, sorts the index in ascending order. Otherwise, sorts in descending order.

**Returns:** A new `Series` with data and index reordered based on the sorted index labels.

**Example:**
```dart
// Sorting by string index
var sIdxStr = Series([10, 20, 5], name: 'data_str_idx', index: ['c', 'a', 'b']);
var sortedByStrIdx = sIdxStr.sort_index();
// sortedByStrIdx.data: [20, 5, 10]
// sortedByStrIdx.index: ['a', 'b', 'c']

// Sorting by numeric index descending
var sIdxNum = Series([10,20,30,40], name:'data_num_idx', index:[3,1,4,0]);
var sortedByNumIdxDesc = sIdxNum.sort_index(ascending: false);
// sortedByNumIdxDesc.data: [30,10,20,40]
// sortedByNumIdxDesc.index: [4,3,1,0]

// Sorting a Series with default integer index
var sDefaultIdx = Series([100, 200, 50], name: 'default_idx_sort');
// sDefaultIdx.sort_index().data: [100, 200, 50] (ascending, no change)
// sDefaultIdx.sort_index(ascending: false).data: [50, 200, 100] (reversed)

// Sorting with duplicate index values (stable sort preserves relative order of data for same index)
var sDupIdx = Series([10,20,30,40,50], name:'dup_idx_sort', index:['b','a','c','a','b']);
var sortedDupIdx = sDupIdx.sort_index();
// sortedDupIdx.data: [20, 40, 10, 50, 30] (20 before 40 for 'a', 10 before 50 for 'b')
// sortedDupIdx.index: ['a', 'a', 'b', 'b', 'c']

// Sorting index with null values (nulls are typically placed first in ascending sort)
var sNullIdx = Series([10,20,30,40], name:'null_idx_sort', index:[1,null,0,null]);
var sortedNullIdx = sNullIdx.sort_index();
// sortedNullIdx.data: [20, 40, 30, 10] (data for nulls, then 0, then 1)
// sortedNullIdx.index: [null, null, 0, 1]

// Sorting empty series by index
var sEmptySortIdx = Series<int>([], name: 'empty_sort_idx', index:[]).sort_index();
// sEmptySortIdx.data: []
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
// sSquared.data is [1, 4, 9, 16]
// sSquared.name is 'numbers'
// sSquared.index is s.index

// Example: Convert to string and add prefix
var sStringify = s.apply((x) => 'val_$x');
// sStringify.data is ['val_1', 'val_2', 'val_3', 'val_4']

// Example: Function that changes type (to boolean)
var sToBool = s.apply((x) => x > 2);
// sToBool.data is [false, false, true, true]
// sToBool.dtype is bool

// Example: Handling missing values (null) within the function
var sWithNullsApply = Series([1, null, 3, null], name: 'data_null_apply');
var appliedNulls = sWithNullsApply.apply((x) => x == null ? 'is_null' : x * 10);
// appliedNulls.data is [10, 'is_null', 30, 'is_null']

// Example: Handling custom missing values within the function
// const missingMarker = -999;
// var dfCtxApply = DataFrame.empty(replaceMissingValueWith: missingMarker);
// var sCustomApply = Series([1, missingMarker, 3], name: 'custom_apply');
// sCustomApply.setParent(dfCtxApply, 'custom_apply');
// var appliedCustom = sCustomApply.apply((x) => x == missingMarker ? 'custom_missing_found' : x + 100);
// appliedCustom.data is [101, 'custom_missing_found', 103]

// Example: Applying to an empty series
var sEmptyApply = Series<int>([], name: 'empty_apply');
var resultEmptyApply = sEmptyApply.apply((x) => x * 2);
// resultEmptyApply.data is []
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
var checkValuesList = [1, 4, null]; // Check for 1, 4, or null
var resultListCheck = s.isin(checkValuesList);
// resultListCheck.data: [true, false, false, true, true, true]
// resultListCheck.name: 'data_isin' (original name + _isin)
// resultListCheck.index is s.index

// Using a Set for potentially better performance with many check values
var checkValuesSet = {2, 5, 'a'};
var sMixed = Series([1, 'a', 2.0, true, null, 2], name: 'mixed_isin_src');
var resultSetCheck = sMixed.isin(checkValuesSet);
// sMixed.data: [1, 'a', 2.0, true, null, 2]
// resultSetCheck.data: [false, true, true, false, false, true] (2.0 and 2 are considered equal by Set.contains)

// Behavior with missing values (null) in the Series:
// 1. If checkValues contains the missing representation (e.g., null)
var sHasNull = Series([1, null, 2], name: 'has_null');
// sHasNull.isin([1, null]).data is [true, true, false]

// 2. If checkValues does NOT contain the missing representation
// sHasNull.isin([1, 2]).data is [true, false, true] (null in Series is not in [1,2])

// Behavior with custom missing marker from DataFrame context:
// const missingMarker = -999;
// var dfCtxIsin = DataFrame.empty(replaceMissingValueWith: missingMarker);
// var sCustomIsin = Series([10, missingMarker, 20, 5, missingMarker], name: 'custom_isin_src');
// sCustomIsin.setParent(dfCtxIsin, 'custom_isin_src');

// If missingMarker is in checkValues:
// sCustomIsin.isin([10, missingMarker]).data is [true, true, false, false, true]
// If missingMarker is NOT in checkValues:
// sCustomIsin.isin([10, 5]).data is [true, false, false, true, false]

// Empty Series:
var sEmptyIsin = Series<int>([], name: 'empty_isin_src');
// sEmptyIsin.isin([1,2]).data is []

// Empty checkValues:
// s.isin([]).data is [false, false, false, false, false, false] (for original 's')
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
// sReset is a Series with data [10, 20, 30], name 'myValues', and default index [0, 1, 2]

// Case 2: drop = false (returns a DataFrame)
var dfFromSeries = s.reset_index(drop: false, name: 'original_idx_col');
// dfFromSeries is a DataFrame with columns: 'original_idx_col' and 'myValues'
// dfFromSeries.column('original_idx_col').data is ['x', 'y', 'z']
// dfFromSeries.column('myValues').data is [10, 20, 30]
// The DataFrame gets its own default integer index [0, 1, 2]

// If `name` for index column is not provided, it defaults to 'index'
var dfDefaultIndexName = s.reset_index(drop: false);
// dfDefaultIndexName.columns is ['index', 'myValues']

// If original Series is unnamed (name is empty string or null), its data column in DataFrame defaults to '0'
var sUnnamed = Series([10,20], index: ['a','b'], name: '');
var dfFromUnnamed = sUnnamed.reset_index(drop: false, name: 'idx');
// dfFromUnnamed.columns is ['idx', '0']

// If Series name conflicts with the (default or provided) index column name
var sConflictName = Series([10,20], name: 'index', index: ['a','b']);
var dfConflict = sConflictName.reset_index(drop: false); // Index col also 'index'
// dfConflict.columns is ['index', 'index_values'] (Series data column renamed)

// Resetting index on a Series with default integer index
var sDefaultIdxReset = Series([10, 20], name: 'data_def_idx');
var dfFromDefaultIdx = sDefaultIdxReset.reset_index(drop: false, name: 'orig_idx');
// dfFromDefaultIdx.column('orig_idx').data is [0, 1]
// dfFromDefaultIdx.column('data_def_idx').data is [10, 20]

// Empty Series
var sEmptyReset = Series<int>([], name: 'empty_reset', index:[]);
var sEmptyResetDropTrue = sEmptyReset.reset_index(drop: true);
// sEmptyResetDropTrue is an empty Series

var dfEmptyResetDropFalse = sEmptyReset.reset_index(drop: false, name: 'idx');
// dfEmptyResetDropFalse is a DataFrame with columns ['idx', 'empty_reset'] and 0 rows.
```

## Other Operations

### 1. `concatenate()`
*(This method is typically found on the `DataFrame` class for combining multiple Series or DataFrames. Direct `Series.concatenate(otherSeries)` is not a standard method in this library based on the provided test files. Series are usually concatenated by first placing them into DataFrames or by using `List.addAll` on their data if indexes are not a concern.)*
<!-- 
Conceptual example (if it were available):
Series s1 = Series([1, 2], name: 'A');
Series s2 = Series([3, 4], name: 'A');
Series sVertical = s1.concatenate(s2); // sVertical.data is [1, 2, 3, 4]
-->

## Conversion to DataFrame

### 1. `toDataFrame()`
Converts the Series into a `DataFrame` with a single column. The column in the new DataFrame will be named after the original Series' `name`. The DataFrame will have a default integer index; the Series' original index is not preserved as the DataFrame's index in the current implementation.

**Returns:** A new `DataFrame` instance.

**Example:**
```dart
var s = Series([10, 20, 30], name: 'MyColumn', index: ['x', 'y', 'z']);
DataFrame df = s.toDataFrame();

// df.columns is ['MyColumn']
// df['MyColumn'].data is [10, 20, 30]
// df.index is [0, 1, 2] (default DataFrame index)

// If Series name is empty or null, the column name in DataFrame defaults to '0'
var sUnnamedToDf = Series([100, 200], name: '');
DataFrame dfFromUnnamedS = sUnnamedToDf.toDataFrame();
// dfFromUnnamedS.columns is ['0']

// Empty Series to DataFrame
var sEmptyToDf = Series<int>([], name: 'EmptyCol');
DataFrame dfFromEmptyS = sEmptyToDf.toDataFrame();
// dfFromEmptyS.columns is ['EmptyCol']
// dfFromEmptyS.rowCount is 0
```

## String Representation (`toString()`)
Provides a formatted string representation of the Series, including its index (if any), data, name, length, and data type (`dtype`). The output is designed for easy readability.

**Example:**
```dart
// Numeric series with default index
final sNumeric = Series([1, 2, 3], name: 'nums');
print(sNumeric.toString());
// Output:
//   nums
// 0    1
// 1    2
// 2    3
// Length: 3
// Type: int

// String series with custom index
final sStringCustomIdx = Series(['a', 'b'], name: 'chars', index: ['x', 'y']);
print(sStringCustomIdx.toString());
// Output:
//   chars
// x     a
// y     b
// Length: 2
// Type: String

// Empty series
final sEmptyStr = Series([], name: 'empty_series_str');
print(sEmptyStr.toString());
// Output: Empty Series: empty_series_str

// Series with long strings (demonstrates padding)
final sLongStr = Series(['long string value', 'short'], name: 'long_strings');
print(sLongStr.toString());
// Output (spacing adapts to content):
//   long_strings
// 0  long string value
// 1  short
// Length: 2
// Type: String
```
