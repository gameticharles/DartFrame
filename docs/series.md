# Series Class Documentation

The `Series` class in DartFrame represents a one-dimensional labeled array, similar to a column in a spreadsheet or a single vector of data. It's a fundamental building block for `DataFrame`.

## Creating a Series

You can create a `Series` by providing a list of data and a name for the series.

**Syntax:**

```dart
Series(List<dynamic> data, {required String name, List<dynamic>? index});
```

**Parameters:**

- `data`: A `List` containing the data points of the series. This list can hold dynamic types.
- `name`: A `String` that gives a name to the Series (e.g., 'Age', 'Price'). This is a required parameter.
- `index`: (Optional) A `List` to use as the index for the Series. If not provided, a default integer index (0, 1, 2, ...) will be generated.

**Example:**

```dart
// Series with integer data and default index
var numericSeries = Series([10, 20, 30, 40], name: 'Counts');
print(numericSeries);

// Series with string data and custom index
var stringSeries = Series(
  ['apple', 'banana', 'cherry'],
  name: 'Fruits',
  index: ['a', 'b', 'c'],
);
print(stringSeries);
```

## Accessing and Modifying Data

### 1. Data

You can access the underlying data of a Series directly.

- **Get data:** `series.data` (returns a `List<dynamic>`)
- **Modify data:** `series.data[index] = newValue;` or assign a new list to `series.data`. (Note: If the Series is part of a DataFrame, direct modification of `series.data` might not update the DataFrame. It's generally safer to use DataFrame methods for modifications in that context).

**Example:**

```dart
var s = Series([1, 2, 3], name: 'Numbers');
print(s.data); // Output: [1, 2, 3]

s.data[1] = 200;
print(s.data); // Output: [1, 200, 3]

s.data = [10, 20, 30, 40];
print(s.data); // Output: [10, 20, 30, 40]
```

### 2. Name

The name of the Series can be accessed or changed.

- **Get name:** `series.name`
- **Set name:** `series.name = 'NewName';`

**Example:**

```dart
var s = Series([1, 2, 3], name: 'OldName');
print(s.name); // Output: OldName

s.name = 'NewName';
print(s.name); // Output: NewName
```

### 3. Length

Get the number of elements in the Series.

- **Get length:** `series.length`

**Example:**

```dart
var s = Series([5, 10, 15], name: 'Values');
print(s.length); // Output: 3
```

### 4. Indexing

While `Series` itself in the provided code doesn't have direct `[]` or `[]=` operators for element access/modification like a `List` or `DataFrame` column, you interact with its data through the `.data` property or via its parent `DataFrame` if it's part of one. The `index` property is primarily for labeling.

Accessing elements is done via `series.data[index]`. If the series is part of a DataFrame, you'd typically access/modify elements through the DataFrame: `df['seriesName'][rowIndex]`.

**Example (Standalone Series):**

```dart
var s = Series([10, 20, 30], name: 'MyData', index: ['x', 'y', 'z']);

// Access data using the list index
print(s.data[0]); // Output: 10

// Modify data using the list index
s.data[1] = 25;
print(s);
/*
Output:
      MyData
x     10
y     25
z     30

Length: 3
Type: int
*/
```

The `example/example.dart` shows more advanced indexing and conditional updates when Series is manipulated in the context of a DataFrame or potentially through extension methods not shown in `series.dart` directly (e.g., `numbers[1] = 10;`, `numbers[numbers > 7] = 99;`). These operations often involve operator overloading or specific methods on `Series` that might be part of a larger framework or extensions.

## Operations

### 1. `concatenate()`

Concatenates another Series or a list of Series to the current Series. This is a common operation, though the direct implementation `s1.concatenate(s2)` is shown in `example/example.dart` which suggests it might be an extension method or a method on a more specialized Series class if not directly in `Series` from `series.dart`.

Assuming such a method exists (as implied by examples):

**Syntax (conceptual, based on examples):**

`series1.concatenate(Series series2, {int axis = 0})`
- `series2`: The Series to concatenate.
- `axis`: `0` for vertical concatenation (stacking rows), `1` for horizontal (which would typically result in a DataFrame). For Series, vertical is most common.

**Example (Conceptual, based on `example/example.dart`):**

```dart
Series s1 = Series([1, 2, 3], name: 'A');
Series s2 = Series([4, 5, 6], name: 'A'); // Name might be same for vertical concat

// Conceptual vertical concatenation
// Series sVertical = s1.concatenate(s2); // Assuming s1.data becomes [1,2,3,4,5,6]
// print(sVertical);

// For horizontal concatenation, it typically forms a DataFrame:
// DataFrame dfHorizontal = s1.concatenate(s2, axis: 1); // Results in a DataFrame with columns A and B
// print(dfHorizontal);
```
*Note: The provided `lib/src/series/series.dart` does not explicitly contain a `concatenate` method. This functionality, as seen in `example.dart`, might be implemented as an extension method or within the DataFrame class when handling Series objects.*

## Conversion to DataFrame

### 1. `toDataFrame()`

Converts the Series into a DataFrame. The Series' name becomes the column name in the new DataFrame.

**Syntax:**

`DataFrame series.toDataFrame()`

**Example:**

```dart
var s = Series([10, 20, 30], name: 'MyColumn');
DataFrame df = s.toDataFrame();
print(df);
/*
Output:
  MyColumn
0       10
1       20
2       30
*/
```

## String Representation (`toString()`)

The `toString()` method provides a formatted string representation of the Series, including its index, data, name, length, and data type.

**Example:**

```dart
var s = Series([true, false, true], name: 'Booleans', index: ['chk1', 'chk2', 'chk3']);
print(s.toString());
/*
Output:
      Booleans
chk1  true
chk2  false
chk3  true

Length: 3
Type: bool
*/

var emptySeries = Series([], name: 'Empty');
print(emptySeries.toString());
// Output: Empty Series: Empty
```

This documentation provides an overview of the `Series` class. For advanced operations, especially those involving interactions with DataFrames or specific analytical functions, refer to the `DataFrame` documentation and further examples in the DartFrame project.
