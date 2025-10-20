import 'dart:convert';

import 'package:intl/intl.dart';
import 'dart:math';

import '../../dartframe.dart';
import '../utils/time_series.dart';

part 'accessors.dart';
part 'functions.dart';
part 'operations.dart';
part 'statistics.dart';
part 'rolling.dart';
part 'reshaping.dart';
part 'time_series.dart';

/// A class representing the shape of multi-dimensional data structures.
///
/// This class supports both named access for 2D structures (rows, columns)
/// and indexed access for any number of dimensions, providing pandas-like
/// behavior and future-proofing for 3D+ data structures.
class Shape {
  /// The dimensions of the data structure as an immutable list.
  final List<int> _dimensions;

  /// Creates a Shape instance from a list of dimensions.
  ///
  /// Parameters:
  /// - `dimensions`: A list of integers representing the size of each dimension
  ///
  /// Example:
  /// ```dart
  /// var shape2D = Shape([10, 5]);     // 10 rows, 5 columns
  /// var shape3D = Shape([10, 5, 3]);  // 10x5x3 tensor
  /// ```
  Shape(List<int> dimensions) : _dimensions = List.unmodifiable(dimensions) {
    if (dimensions.isEmpty) {
      throw ArgumentError('Shape must have at least one dimension');
    }
    if (dimensions.any((dim) => dim < 0)) {
      throw ArgumentError('All dimensions must be non-negative');
    }
  }

  /// Creates a 2D Shape instance with the specified rows and columns.
  ///
  /// This is a convenience constructor for the common 2D case.
  ///
  /// Parameters:
  /// - `rows`: The number of rows
  /// - `columns`: The number of columns
  Shape.fromRowsColumns(int rows, int columns) : this([rows, columns]);

  /// The number of rows (first dimension) for 2D+ structures.
  ///
  /// Throws [StateError] if this is not at least a 2D shape.
  int get rows {
    if (_dimensions.length < 1) {
      throw StateError('Shape must have at least 1 dimension to access rows');
    }
    return _dimensions[0];
  }

  /// The number of columns (second dimension) for 2D+ structures.
  ///
  /// Throws [StateError] if this is not at least a 2D shape.
  int get columns {
    if (_dimensions.length < 2) {
      throw StateError(
          'Shape must have at least 2 dimensions to access columns');
    }
    return _dimensions[1];
  }

  /// The number of dimensions in this shape.
  int get ndim => _dimensions.length;

  /// Provides indexed access to shape dimensions.
  ///
  /// This enables pandas-like syntax for accessing any dimension.
  ///
  /// Parameters:
  /// - `index`: The dimension index (0-based)
  ///
  /// Returns:
  /// The size of the dimension at the specified index.
  ///
  /// Throws:
  /// - `RangeError` if index is out of bounds.
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([10, 5, 3]);
  /// print(shape[0]); // Output: 10 (first dimension)
  /// print(shape[1]); // Output: 5  (second dimension)
  /// print(shape[2]); // Output: 3  (third dimension)
  /// ```
  int operator [](int index) {
    if (index < 0 || index >= _dimensions.length) {
      throw RangeError(
          'Shape index $index is out of bounds for ${_dimensions.length}D shape');
    }
    return _dimensions[index];
  }

  /// Returns a list representation of all dimensions.
  ///
  /// This can be useful for destructuring or when you need the shape
  /// as a standard Dart list.
  ///
  /// Returns:
  /// A list containing all dimension sizes.
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([10, 5, 3]);
  /// var dims = shape.toList(); // [10, 5, 3]
  /// ```
  List<int> toList() => List.from(_dimensions);

  /// Returns the total number of elements across all dimensions.
  ///
  /// This is the product of all dimension sizes.
  ///
  /// Returns:
  /// The total number of elements.
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([10, 5, 3]);
  /// print(shape.size); // Output: 150 (10 * 5 * 3)
  /// ```
  int get size => _dimensions.reduce((a, b) => a * b);

  /// Checks if any dimension has size 0 (empty structure).
  ///
  /// Returns:
  /// `true` if any dimension is 0, `false` otherwise.
  bool get isEmpty => _dimensions.any((dim) => dim == 0);

  /// Checks if all dimensions have size > 0 (non-empty structure).
  ///
  /// Returns:
  /// `true` if all dimensions are > 0, `false` otherwise.
  bool get isNotEmpty => !isEmpty;

  /// Checks if this is a 2D square shape (rows == columns).
  ///
  /// Returns:
  /// `true` if this is 2D and rows equals columns, `false` otherwise.
  bool get isSquare =>
      _dimensions.length == 2 && _dimensions[0] == _dimensions[1];

  /// Checks if this is a 1D shape (vector).
  bool get isVector => _dimensions.length == 1;

  /// Checks if this is a 2D shape (matrix/DataFrame).
  bool get isMatrix => _dimensions.length == 2;

  /// Checks if this is a 3D+ shape (tensor).
  bool get isTensor => _dimensions.length >= 3;

  /// Checks if all dimensions have the same size (hypercube).
  bool get isHypercube => _dimensions.every((dim) => dim == _dimensions[0]);

  /// Returns a new Shape with an additional dimension of the specified size.
  ///
  /// This is useful for expanding dimensions (e.g., adding a batch dimension).
  ///
  /// Parameters:
  /// - `size`: The size of the new dimension
  /// - `axis`: The position to insert the new dimension (default: 0)
  ///
  /// Returns:
  /// A new Shape with the added dimension.
  ///
  /// Example:
  /// ```dart
  /// var shape2D = Shape([10, 5]);
  /// var shape3D = shape2D.addDimension(3); // Shape([3, 10, 5])
  /// var shape3D_end = shape2D.addDimension(3, axis: 2); // Shape([10, 5, 3])
  /// ```
  Shape addDimension(int size, {int axis = 0}) {
    if (size < 0) {
      throw ArgumentError('Dimension size must be non-negative');
    }
    if (axis < 0 || axis > _dimensions.length) {
      throw RangeError('Axis $axis is out of bounds for insertion');
    }

    var newDimensions = List<int>.from(_dimensions);
    newDimensions.insert(axis, size);
    return Shape(newDimensions);
  }

  /// Returns a new Shape with the specified dimension removed.
  ///
  /// Parameters:
  /// - `axis`: The dimension to remove
  ///
  /// Returns:
  /// A new Shape with the dimension removed.
  ///
  /// Throws:
  /// - `ArgumentError` if trying to remove the last dimension
  /// - `RangeError` if axis is out of bounds
  Shape removeDimension(int axis) {
    if (_dimensions.length <= 1) {
      throw ArgumentError('Cannot remove dimension from 1D shape');
    }
    if (axis < 0 || axis >= _dimensions.length) {
      throw RangeError('Axis $axis is out of bounds');
    }

    var newDimensions = List<int>.from(_dimensions);
    newDimensions.removeAt(axis);
    return Shape(newDimensions);
  }

  /// Returns a new Shape with dimensions reordered according to the given axes.
  ///
  /// Parameters:
  /// - `axes`: The new order of axes
  ///
  /// Returns:
  /// A new Shape with reordered dimensions.
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([10, 5, 3]);
  /// var transposed = shape.transpose([2, 0, 1]); // Shape([3, 10, 5])
  /// ```
  Shape transpose(List<int> axes) {
    if (axes.length != _dimensions.length) {
      throw ArgumentError('Number of axes must match number of dimensions');
    }
    if (Set.from(axes).length != axes.length) {
      throw ArgumentError('Axes must be unique');
    }
    if (axes.any((axis) => axis < 0 || axis >= _dimensions.length)) {
      throw ArgumentError('All axes must be valid dimension indices');
    }

    return Shape(axes.map((axis) => _dimensions[axis]).toList());
  }

  @override
  String toString() {
    if (_dimensions.length == 2) {
      return 'Shape(rows: ${_dimensions[0]}, columns: ${_dimensions[1]})';
    }
    return 'Shape(${_dimensions.join('×')})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shape &&
          runtimeType == other.runtimeType &&
          _listEquals(_dimensions, other._dimensions);

  @override
  int get hashCode => _dimensions.fold(0, (hash, dim) => hash ^ dim.hashCode);

  /// Helper method to compare two lists for equality.
  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// Helper function to check for default integer index (e.g., [0, 1, 2, ...])
bool _isDefaultIntegerIndex(List<dynamic> idxList, int expectedLength) {
  if (idxList.length != expectedLength) {
    return false;
  }
  if (expectedLength == 0) {
    // An empty list is a valid default index for 0 items.
    return true;
  }
  for (int i = 0; i < expectedLength; i++) {
    if (idxList[i] != i) {
      return false;
    }
  }
  return true;
}

/// A `DataFrame` is a two-dimensional, size-mutable, potentially heterogeneous
/// tabular data structure with labeled axes (rows and columns).
///
/// It is similar to a spreadsheet or SQL table, or a dictionary of Series objects.
/// DataFrames are generally the most commonly used pandas-like objects.
///
/// ## Key Features:
/// - **Tabular Data:** Organizes data in rows and columns.
/// - **Labeled Axes:** Both rows (index) and columns have labels.
/// - **Heterogeneous Data:** Columns can hold data of different types (e.g., integers, strings, booleans).
/// - **Mutability:** DataFrames can be modified (e.g., adding or removing columns, updating values).
/// - **Missing Data Handling:** Provides mechanisms to represent and handle missing data.
/// - **Powerful Operations:** Supports a wide range of operations for data manipulation, cleaning, analysis, and exploration.
///
/// ## Construction:
/// DataFrames can be created from various sources, including:
/// - Lists of lists or lists of maps.
/// - CSV files.
/// - JSON data.
/// - Maps of lists.
///
/// ## Accessing Data:
/// - **`iloc`:** Access data by integer-based position.
/// - **`loc`:** Access data by labels.
/// - **`[]` operator:** Select columns by name or boolean Series for filtering.
///
/// ## Rolling Operations:
/// DartFrame provides two methods for rolling window operations:
/// 
/// ### **Recommended: `rollingWindow()`** ✅
/// Use `df.rollingWindow(window)` for comprehensive pandas-like rolling operations:
/// ```dart
/// var rolling = df.rollingWindow(3);
/// var meanResult = rolling.mean();     // All columns
/// var corrResult = rolling.corr();     // Correlation matrix
/// var customResult = rolling.apply((window) => window.reduce((a, b) => a + b));
/// ```
/// 
/// ### **Deprecated: `rolling()`** ⚠️
/// The `df.rolling(column, window, function)` method is deprecated and will be removed.
/// It only works on single columns and has limited functionality.
/// 
/// **Migration Guide:**
/// ```dart
/// // OLD (deprecated):
/// var result = df.rolling('column', 3, 'mean');
/// 
/// // NEW (recommended):
/// var result = df.rollingWindow(3).mean()['column'];
/// ```
///
/// ## Example:
/// ```dart
/// // Creating a DataFrame from a list of maps
/// var df = DataFrame.fromRows([
///   {'Name': 'Alice', 'Age': 30, 'City': 'New York'},
///   {'Name': 'Bob', 'Age': 25, 'City': 'Los Angeles'},
/// ]);
///
/// print(df);
/// // Output:
/// //        Name  Age         City
/// // 0    Alice   30     New York
/// // 1      Bob   25  Los Angeles
///
/// // Accessing a column
/// print(df['Age']);
/// // Output:
/// // Series(name: Age, index: [0, 1], data: [30, 25])
///
/// // Accessing a row by integer position
/// print(df.iloc[0]);
/// // Output:
/// // Series(name: 0, index: [Name, Age, City], data: [Alice, 30, New York])
/// ```
class DataFrame {
  List<dynamic> _columns = List.empty(growable: true);
  List<dynamic> index = List.empty(growable: true);
  List<dynamic> _data = List.empty(growable: true);
  final bool allowFlexibleColumns;
  dynamic replaceMissingValueWith;
  List<dynamic> _missingDataIndicator = List.empty(growable: true);

  /// Internal constructor for creating a DataFrame.
  ///
  /// This constructor is used by other factory constructors and internal methods.
  /// It assumes that the provided data is already in the correct format or controlled by `formatData`.
  ///
  /// Parameters:
  /// - `_columns`: A `List<dynamic>` of column labels.
  /// - `_data`: A `List<dynamic>` (representing `List<List<dynamic>>`) of data rows.
  /// - `index`: An optional `List<dynamic>` of row labels. If empty or not provided,
  ///   a default integer index (0, 1, 2, ...) is generated based on the number of rows in `_data`.
  /// - `allowFlexibleColumns`: A `bool` indicating whether the number of columns can change
  ///   dynamically (e.g., when assigning new columns). Defaults to `false`.
  /// - `replaceMissingValueWith`: A `dynamic` value to replace missing data indicators found during
  ///   data cleaning (if `formatData` is true) or used as a fill value in certain operations.
  /// - `formatData`: A `bool` indicating whether to apply the `cleanData` method to each cell
  ///   in `_data`. Defaults to `false`.
  /// - `missingDataIndicator`: A `List<dynamic>` of values that should be treated as missing
  ///   when `formatData` is true.
  ///
  /// Throws:
  /// - `ArgumentError` if `_data` is not empty and its rows have inconsistent lengths.
  /// - `ArgumentError` if `_data` is not empty, `_columns` is not empty, and their lengths
  ///   (number of columns vs. length of a data row) do not match.
  /// - `Exception` if a provided `index` is not empty and its length does not match the
  ///   number of rows in `_data`.
  DataFrame._(
    this._columns,
    this._data, {
    this.index = const [],
    this.allowFlexibleColumns = false,
    this.replaceMissingValueWith,
    bool formatData = false,
    List<dynamic> missingDataIndicator = const [],
  }) : _missingDataIndicator = missingDataIndicator {
    if (_data.isNotEmpty) {
      final firstRowLength = _data[0].length;
      for (var i = 1; i < _data.length; i++) {
        if (_data[i].length != firstRowLength) {
          throw ArgumentError(
              'All data rows must have the same length. Row $i has length ${_data[i].length}, expected $firstRowLength.');
        }
      }
      if (_columns.isNotEmpty && _columns.length != firstRowLength) {
        throw ArgumentError(
            'Number of column names (${_columns.length}) must match number of data columns ($firstRowLength).');
      }
    } else if (_columns.isNotEmpty) {
      // If data is empty but columns are provided, this is valid (empty DF with columns).
    }

    if (formatData) {
      // Clean and convert data
      _data = _data.map((row) => row.map(cleanData).toList()).toList();
    }

    // If index was entered, check that it's given for all rows or throw error
    if (index.isNotEmpty) {
      if (index.length != _data.length) {
        throw Exception(
            'Index length (${index.length}) must match number of data rows (${_data.length}).');
      }
    } else {
      // If index was not entered or was empty, auto-generate
      index = List.generate(_data.length, (i) => i);
    }
  }

  /// Creates an empty DataFrame.
  ///
  /// Optionally, column labels can be specified.
  ///
  /// Parameters:
  /// - `columns`: An optional `List<dynamic>` of column labels for the empty DataFrame.
  ///   If `null` or empty, the DataFrame will have no columns defined initially.
  /// - `allowFlexibleColumns`: A `bool` indicating whether columns can be added later
  ///   (e.g., by assignment). Defaults to `false`.
  /// - `replaceMissingValueWith`: A `dynamic` value to use for missing entries if data is added
  ///   or when operations might introduce missing values.
  /// - `missingDataIndicator`: A `List<dynamic>` of values to consider as missing if data
  ///   cleaning is performed.
  ///
  /// Returns:
  /// A new, empty `DataFrame`.
  ///
  /// Example:
  /// ```dart
  /// // Create a completely empty DataFrame
  /// final dfEmpty = DataFrame.empty();
  /// print(dfEmpty.shape); // Output: (rows: 0, columns: 0)
  ///
  /// // Create an empty DataFrame with specified columns
  /// final dfWithCols = DataFrame.empty(columns: ['Name', 'Age']);
  /// print(dfWithCols.columns); // Output: [Name, Age]
  /// print(dfWithCols.shape);   // Output: (rows: 0, columns: 2)
  /// ```
  DataFrame.empty({
    List<dynamic>? columns,
    this.allowFlexibleColumns = false,
    this.replaceMissingValueWith,
    List<dynamic> missingDataIndicator = const [],
    this.index = const [],
  })  : _missingDataIndicator = missingDataIndicator,
        _data = [],
        _columns = columns ?? [];

  /// Constructs a DataFrame from a list of lists (rows).
  ///
  /// Parameters:
  /// - `data`: A `List<List<dynamic>>?` where each inner list represents a row.
  ///   If `null` or empty, an empty DataFrame is created (or one with only columns if `columns` is provided).
  /// - `columns`: An optional `List<dynamic>` of column labels. Defaults to an empty list.
  ///   If `data` is provided and not empty, and `columns` is empty, default column names
  ///   (e.g., "Column1", "Column2") are generated based on the length of the first data row.
  /// - `index`: An optional `List<dynamic>` of row labels. Defaults to an empty list.
  ///   If `data` is provided and not empty, and `index` is empty, a default integer index
  ///   (0, 1, 2, ...) is generated based on the number of data rows.
  /// - `allowFlexibleColumns`: A `bool` indicating whether the number of columns can be changed
  ///   dynamically. Defaults to `false`.
  /// - `replaceMissingValueWith`: A `dynamic` value to replace missing data indicators or for padding.
  /// - `missingDataIndicator`: A `List<dynamic>` of values that should be treated as missing
  ///   if `formatData` is true.
  /// - `formatData`: A `bool` indicating whether to apply `cleanData` to each cell in `data`.
  ///   Defaults to `false`.
  ///
  /// Returns:
  /// A new `DataFrame`.
  ///
  /// Throws:
  /// - `ArgumentError` if `data` is not empty and its rows have inconsistent lengths.
  /// - `ArgumentError` if `data` is not empty, `columns` is not empty, and their lengths
  ///   (number of columns vs. length of a data row) do not match.
  /// - `Exception` if `index` is not empty and its length does not match the number of rows in `data`.
  ///
  /// Example:
  /// ```dart
  /// // DataFrame with data and specified columns and index
  /// final df1 = DataFrame(
  ///   [
  ///     [1, 'Alice', 100.0],
  ///     [2, 'Bob', 200.0],
  ///   ],
  ///   columns: ['ID', 'Name', 'Score'],
  ///   index: ['rowA', 'rowB'],
  /// );
  /// print(df1);
  /// // Output:
  /// //       ID   Name  Score
  /// // rowA   1  Alice  100.0
  /// // rowB   2    Bob  200.0
  ///
  /// // DataFrame with data only (default columns and index)
  /// final df2 = DataFrame([
  ///   [10, 20],
  ///   [30, 40],
  /// ]);
  /// print(df2);
  /// // Output:
  /// //   Column1  Column2
  /// // 0       10       20
  /// // 1       30       40
  ///
  /// // Empty DataFrame by passing null or empty list for data
  /// final df3 = DataFrame(null, columns: ['X', 'Y']); // or DataFrame([], columns: ['X', 'Y'])
  /// print(df3.columns); // Output: [X, Y]
  /// print(df3.rowCount);  // Output: 0
  /// ```
  DataFrame(List<List<dynamic>>? data,
      {List<dynamic> columns = const [],
      List<dynamic> index = const [],
      this.allowFlexibleColumns = false,
      this.replaceMissingValueWith,
      List<dynamic> missingDataIndicator = const [],
      bool formatData = false})
      : _missingDataIndicator = missingDataIndicator,
        _data = data ?? [],
        _columns = columns.isEmpty && data != null && data.isNotEmpty
            ? List.generate(data[0].length, (index) => 'Column${index + 1}')
            : List<dynamic>.from(columns),
        index =
            (index.isNotEmpty && data != null && index.length != data.length)
                ? throw Exception('Index must match number of rows entered')
                : (index.isNotEmpty)
                    ? index
                    : (data != null && data.isNotEmpty)
                        ? List.generate(data.length, (i) => i)
                        : [] {
    // ... validation based on allowFlexibleColumns ...
    if (formatData && data != null) {
      // Clean and convert data
      _data = data.map((row) => row.map(cleanData).toList()).toList();
    }
  }

  /// Cleans and converts data values based on their content.
  ///
  /// This method performs several operations:
  /// Cleans and converts a single data value based on its content and type.
  ///
  /// This method is typically used internally when `formatData` is enabled in constructors
  /// or when data is being processed.
  ///
  /// **Processing Steps:**
  /// 1. **Missing Data Check:**
  ///    - If `value` is `null`.
  ///    - If `value` is an empty string (`''`).
  ///    - If `value` is present in the DataFrame's `_missingDataIndicator` list.
  ///    If any of these conditions are true, `replaceMissingValueWith` (a DataFrame property) is returned.
  ///
  /// 2. **Type Conversion (if `value` is a `String` and not missing):**
  ///    - **Numeric:** Tries to parse the string into a `num` (integer or double) using `num.tryParse()`.
  ///    - **Boolean:** Converts "true" or "false" (case-insensitive) into a `bool`.
  ///    - **Date/Time:** Attempts to parse the string as a `DateTime` object using a predefined list
  ///      of common formats (`yyyy-MM-dd`, `MM/dd/yyyy`, `dd-MMM-yyyy`). `DateFormat.parseStrict()` is used.
  ///    - **List:** If the string starts with `[` and ends with `]`:
  ///        - Tries to decode it as a JSON list using `jsonDecode()`.
  ///        - As a fallback, removes the brackets and splits by comma.
  ///
  /// 3. **Default:** If none of the above apply, the original `value` is returned.
  ///
  /// Parameters:
  /// - `value`: The `dynamic` data value to clean and potentially convert.
  ///
  /// Returns:
  /// The cleaned or converted value. If `value` is identified as missing,
  /// `replaceMissingValueWith` is returned. Otherwise, it could be a `num`, `bool`,
  /// `DateTime`, `List`, or the original `String` or other type.
  ///
  /// Example (assuming `replaceMissingValueWith` is `null` and `_missingDataIndicator` includes 'N/A'):
  /// ```dart
  /// // For a DataFrame instance `df`:
  /// print(df.cleanData('123'));        // Output: 123 (num)
  /// print(df.cleanData('true'));       // Output: true (bool)
  /// print(df.cleanData('2024-03-15'));  // Output: DateTime object for March 15, 2024
  /// print(df.cleanData('[1, "a"]'));    // Output: [1, a] (List)
  /// print(df.cleanData(''));            // Output: null (if replaceMissingValueWith is null)
  /// print(df.cleanData('N/A'));        // Output: null (if replaceMissingValueWith is null)
  /// print(df.cleanData('Text'));       // Output: "Text" (String)
  /// ```
  dynamic cleanData(dynamic value) {
    List<String> commonDateFormats = [
      'yyyy-MM-dd',
      'MM/dd/yyyy',
      'dd-MMM-yyyy'
    ]; // Customize as needed

    // Check for missing data
    // 1. If value is in _missingDataIndicator
    // 2. If value is null
    // 3. If value is an empty string
    if (_missingDataIndicator.contains(value) || value == null || value == '') {
      // If replaceMissingValueWith is set, use it. Otherwise, use null.
      return replaceMissingValueWith;
    }

    // If not missing, proceed with type conversion
    // 1. Attempt Numeric Conversion
    if (value is String) {
      var numResult = num.tryParse(value);
      if (numResult != null) {
        return numResult;
      }
    }

    // 2. Attempt Boolean Conversion
    if (value is String) {
      var lowerValue = value.toLowerCase();
      if (lowerValue == 'true') {
        return true;
      } else if (lowerValue == 'false') {
        return false;
      }
    }

    // 3. Date/Time Parsing
    if (value is String) {
      for (var format in commonDateFormats) {
        try {
          return DateFormat(format).parseStrict(value);
        } catch (e) {
          null;
        }
      }
    }

    // 4. Attempt List Conversion
    if (value is String && value.startsWith('[') && value.endsWith(']')) {
      try {
        // Attempt parsing as JSON
        var decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded; // Return if successfully decoded as a list
        }
      } catch (e) {
        print('Error parsing list: $value');
      }

      // Fallback: Attempt to split as a comma-separated list
      try {
        return value
            .substring(1, value.length - 1)
            .split(','); // Remove brackets, split by comma
      } catch (e) {
        print('Error parsing as comma-separated list: $value');
      }
    }

    // Default: Return the original value
    return value;
  }

  /// Constructs a DataFrame from a CSV (Comma Separated Values) string or file.
  ///
  /// Parameters:
  /// - `csv`: An optional `String` containing the CSV data. If `null`, `inputFilePath` must be provided.
  /// - `delimiter`: The `String` used to separate values in each row. Defaults to `,`.
  /// - `inputFilePath`: An optional `String` path to a CSV file. If `csv` is `null`, this path is used to read the data.
  /// - `hasHeader`: A `bool` indicating if the first row of the CSV is a header row containing column names. Defaults to `true`.
  ///   If `false`, generic column names (e.g., "Column 0", "Column 1") are generated.
  /// - `hasRowIndex`: A `bool` indicating if the first column of the CSV should be used as the DataFrame's index.
  ///   Defaults to `false`. (Currently, if `true`, the first column name from the header becomes 'Row Index', and data is shifted).
  ///   *Note: Full implementation of using a CSV column as a primary index is pending.*
  /// - `allowFlexibleColumns`: A `bool` controlling if columns can be added/removed later. Defaults to `false`.
  /// - `replaceMissingValueWith`: A `dynamic` value to use for missing entries identified during parsing or formatting.
  /// - `formatData`: A `bool` that, if `true`, applies `cleanData` to each parsed value. Defaults to `false`.
  /// - `missingDataIndicator`: A `List` of strings/values to be treated as missing during parsing if `formatData` is true.
  ///
  /// Returns:
  /// A `Future<DataFrame>` that completes with the newly created DataFrame.
  ///
  /// Throws:
  /// - `ArgumentError` if both `csv` and `inputFilePath` are `null`.
  /// - File I/O errors if `inputFilePath` is provided but cannot be read.
  ///
  /// Example:
  /// ```dart
  /// // From a CSV string with a header
  /// String csvData = "Name,Age,City\nAlice,30,New York\nBob,24,San Francisco";
  /// DataFrame df1 = await DataFrame.fromCSV(csv: csvData);
  /// print(df1);
  /// // Output:
  /// //       Name  Age          City
  /// // 0    Alice   30      New York
  /// // 1      Bob   24 San Francisco
  ///
  /// // From a CSV string without a header
  /// String csvDataNoHeader = "apple,1.0\nbanana,0.5";
  /// DataFrame df2 = await DataFrame.fromCSV(csv: csvDataNoHeader, hasHeader: false);
  /// print(df2);
  /// // Output:
  /// //   Column 0  Column 1
  /// // 0    apple       1.0
  /// // 1   banana       0.5
  ///
  /// // Reading from a file (conceptual - requires actual file 'data.csv')
  /// // File 'data.csv':
  /// // ID,Product,Price
  /// // 1,Laptop,1200
  /// // 2,Mouse,25
  /// // DataFrame dfFromFile = await DataFrame.fromCSV(inputFilePath: 'data.csv');
  /// // print(dfFromFile);
  /// ```
  static Future<DataFrame> fromCSV({
    String? csv,
    String delimiter = ',',
    String? inputFilePath,
    bool hasHeader = true,
    bool hasRowIndex = false,
    bool allowFlexibleColumns = false,
    dynamic replaceMissingValueWith,
    bool formatData = false,
    List missingDataIndicator = const [],
  }) async {
    String? csvContent = csv;
    if (csvContent == null && inputFilePath != null) {
      // Read file
      FileIO fileIO = FileIO();
      csvContent = await fileIO.readFromFile(inputFilePath);
    } else if (csvContent == null) {
      throw ArgumentError('Either csv or inputFilePath must be provided.');
    }

    List<List> rows = csvContent
        .trim()
        .split('\n')
        .map((row) => row.split(delimiter).map((value) => value).toList())
        .toList();

    // Extract column names from the first line
    final columnNames =
        hasHeader ? rows[0] : List.generate(rows[0].length, (i) => 'Column $i');

    if (hasRowIndex) {
      columnNames.insert(0, 'Row Index');
    }

    return DataFrame._(
      columnNames,
      hasHeader
          ? rows.sublist(1)
          : rows, // Only skip first row if hasHeader is true
      //rowHeader: hasRowIndex ? rows[0] : List.generate(rows[0].length, (i) => i),
      index: [], // todo: Not implemented yet
      replaceMissingValueWith: replaceMissingValueWith,
      allowFlexibleColumns: allowFlexibleColumns,
      formatData: formatData,
      missingDataIndicator: missingDataIndicator,
    );
  }

  /// Constructs a DataFrame from a JSON string or file.
  ///
  /// The JSON structure is expected to be a list of objects (maps), where each object
  /// represents a row, and object keys represent column names.
  /// All objects in the list should ideally have a consistent set of keys;
  /// the column names are derived from the keys of the first object in the list.
  ///
  /// Parameters:
  /// - `jsonString`: An optional `String` containing the JSON data. If `null`, `inputFilePath` must be provided.
  /// - `inputFilePath`: An optional `String` path to a JSON file. If `jsonString` is `null`, this path is used.
  /// - `allowFlexibleColumns`: A `bool` controlling if columns can be added/removed later. Defaults to `false`.
  /// - `replaceMissingValueWith`: A `dynamic` value for missing entries.
  /// - `formatData`: A `bool` that, if `true`, applies `cleanData` to each parsed value. Defaults to `false`.
  /// - `missingDataIndicator`: A `List` of values to treat as missing if `formatData` is true.
  ///
  /// Returns:
  /// A `Future<DataFrame>` that completes with the newly created DataFrame.
  ///
  /// Throws:
  /// - `ArgumentError` if both `jsonString` and `inputFilePath` are `null`.
  /// - `FormatException` if the JSON content is invalid or not a list of maps.
  /// - File I/O errors if `inputFilePath` is provided but cannot be read.
  ///
  /// Example:
  /// ```dart
  /// // From a JSON string
  /// String jsonData = '''
  /// [
  ///   {"id": 1, "product": "Laptop", "price": 1200.00},
  ///   {"id": 2, "product": "Mouse", "price": 25.50, "inStock": true},
  ///   {"id": 3, "product": "Keyboard", "price": 75.00}
  /// ]
  /// ''';
  /// DataFrame df1 = await DataFrame.fromJson(jsonString: jsonData);
  /// print(df1);
  /// // Output (note: 'inStock' column might have nulls for rows where it's not present):
  /// //   id  product   price  inStock
  /// // 0   1   Laptop  1200.0     null
  /// // 1   2    Mouse   25.50     true
  /// // 2   3 Keyboard   75.00     null
  ///
  /// // Reading from a file (conceptual - requires actual file 'data.json')
  /// // DataFrame dfFromFile = await DataFrame.fromJson(inputFilePath: 'data.json');
  /// // print(dfFromFile);
  /// ```
  static Future<DataFrame> fromJson({
    String? jsonString,
    String? inputFilePath,
    bool allowFlexibleColumns = false,
    dynamic replaceMissingValueWith,
    bool formatData = false,
    List missingDataIndicator = const [],
  }) async {
    String? jsonContent = jsonString;
    if (jsonContent == null && inputFilePath != null) {
      // Read file
      FileIO fileIO = FileIO();
      jsonContent = await fileIO.readFromFile(inputFilePath);
    } else if (jsonContent == null) {
      throw ArgumentError(
          'Either jsonString or inputFilePath must be provided.');
    }

    final jsonData = jsonDecode(jsonContent) as List;

    // Extract column names from the first object
    final columnNames = jsonData[0].keys.toList();

    // Extract data from all objects
    final data = jsonData
        .map((obj) => columnNames.map((name) => obj[name]).toList())
        .toList();

    return DataFrame._(
      columnNames,
      data,
      index: [], // Not applicable for JSON
      replaceMissingValueWith: replaceMissingValueWith,
      allowFlexibleColumns: allowFlexibleColumns,
      formatData: formatData,
      missingDataIndicator: missingDataIndicator,
    );
  }

  /// Creates an empty DataFrame with specified column names.
  ///
  /// This constructor is useful for initializing a DataFrame structure before populating it with data.
  /// No data rows are created.
  ///
  /// Parameters:
  /// - `columns`: A `List<dynamic>` of column labels.
  /// - `allowFlexibleColumns`: A `bool` indicating if columns can be added/removed later. Defaults to `false`.
  /// - `replaceMissingValueWith`: A `dynamic` value to use for missing entries if data is added.
  /// - `missingDataIndicator`: A `List<dynamic>` of values to consider as missing if data cleaning is performed.
  ///
  /// Returns:
  /// A new `DataFrame` with the specified columns and zero rows.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromNames(['ID', 'Name', 'Category']);
  /// print(df.columns); // Output: [ID, Name, Category]
  /// print(df.rowCount);  // Output: 0
  ///
  /// // You can then add data, for example, by assigning Series to columns:
  /// // df['ID'] = Series([1, 2, 3]);
  /// // df['Name'] = Series(['Apple', 'Banana', 'Cherry']);
  /// // df['Category'] = Series(['Fruit', 'Fruit', 'Fruit']);
  /// // print(df);
  /// // Output:
  /// //   ID    Name Category
  /// // 0  1   Apple    Fruit
  /// // 1  2  Banana    Fruit
  /// // 2  3  Cherry    Fruit
  /// ```
  factory DataFrame.fromNames(
    List<dynamic> columns, {
    bool allowFlexibleColumns = false,
    dynamic replaceMissingValueWith,
    List missingDataIndicator = const [],
  }) {
    return DataFrame(
      [], // Empty data
      columns: columns,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: missingDataIndicator,
    );
  }

  /// Constructs a DataFrame from a `Map` where keys are column names (as `String`)
  /// and values are `List<dynamic>` representing the data for each column.
  ///
  /// All lists in the map must have the same length, as this length determines
  /// the number of rows in the DataFrame.
  ///
  /// Parameters:
  /// - `map`: A `Map<String, List<dynamic>>` where keys are column names and values are lists of column data.
  ///   If the map is empty, an empty DataFrame is created.
  /// - `allowFlexibleColumns`: A `bool` controlling column flexibility. Defaults to `false`.
  /// - `replaceMissingValueWith`: A `dynamic` value for missing data.
  /// - `missingDataIndicator`: A `List` of values to treat as missing if `formatData` is true.
  /// - `index`: An optional `List<dynamic>` for row labels. If not provided or empty,
  ///   a default integer index (0, 1, 2, ...) is generated based on the length of the column lists.
  /// - `formatData`: A `bool` to trigger `cleanData` on values. Defaults to `false`.
  ///
  /// Returns:
  /// A new `DataFrame`.
  ///
  /// Throws:
  /// - `ArgumentError` if the lists in the `map` have different lengths.
  /// - `Exception` if `index` is provided and its length does not match the length of the column lists.
  ///
  /// Example:
  /// ```dart
  /// Map<String, List<dynamic>> dataMap = {
  ///   'ColA': [1, 2, 3, 4],
  ///   'ColB': ['P', 'Q', 'R', 'S'],
  ///   'ColC': [true, false, true, false]
  /// };
  /// DataFrame df = DataFrame.fromMap(dataMap, index: ['r1', 'r2', 'r3', 'r4']);
  /// print(df);
  /// // Output:
  /// //    ColA ColB  ColC
  /// // r1    1    P  true
  /// // r2    2    Q false
  /// // r3    3    R  true
  /// // r4    4    S false
  ///
  /// // Example with empty map:
  /// DataFrame emptyDf = DataFrame.fromMap({});
  /// print(emptyDf.shape); // Output: (rows: 0, columns: 0)
  /// ```
  factory DataFrame.fromMap(
    Map<String, List<dynamic>> map, {
    bool allowFlexibleColumns = false,
    dynamic replaceMissingValueWith,
    List missingDataIndicator = const [],
    List index = const [],
    bool formatData = false,
  }) {
    if (map.isEmpty) {
      return DataFrame.empty(
          columns: [], // No columns from an empty map
          index:
              index, // Keep provided index if any, though it might be for 0 rows
          allowFlexibleColumns: allowFlexibleColumns,
          replaceMissingValueWith: replaceMissingValueWith,
          missingDataIndicator: missingDataIndicator);
    }

    List<String> columns = map.keys.toList();
    List<List<dynamic>> data = [];

    int? length; // Use nullable int for length, determined by the first column
    for (var columnName in columns) {
      var columnData = map[columnName]!; // map[columnName] is List<dynamic>?
      if (length == null) {
        length = columnData.length;
      } else if (columnData.length != length) {
        throw ArgumentError(
            'All lists in the map must have the same length. Column "$columnName" has length ${columnData.length}, expected $length.');
      }
    }
    // If map was not empty but all lists were (e.g. {'A': [], 'B': []}), length is 0.
    // If map was {'A': [1,2], 'B': [3,4]}, length is 2.
    length ??= 0;

    // Populate the DataFrame data by transposing the map structure
    for (int i = 0; i < length; i++) {
      List<dynamic> rowData = [];
      for (var columnName in columns) {
        rowData.add(map[columnName]![i]);
      }
      data.add(rowData);
    }

    return DataFrame(
      data,
      columns: columns,
      index: index, // Pass the original index list
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: missingDataIndicator,
      formatData: formatData,
    );
  }

  /// Constructs a DataFrame from a list of maps, where each map represents a row.
  ///
  /// The keys of the maps are used as column names.
  /// - If `columns` parameter is provided, only those keys will be included as columns, in the specified order.
  ///   Keys in the maps not listed in `columns` will be ignored. Columns specified but not in any map
  ///   will result in `replaceMissingValueWith` for those cells.
  /// - If `columns` parameter is `null` (default), all unique keys found across all maps in `rows`
  ///   will be used as column names. The order of these inferred columns is not guaranteed.
  ///
  /// Parameters:
  /// - `rows`: A `List<Map<dynamic, dynamic>>` where each map represents a row.
  ///   Map keys are typically `String` for column names.
  /// - `columns`: An optional `List<dynamic>` to specify column names and their order.
  ///   If `null`, column names are inferred from all unique keys in `rows`.
  /// - `index`: An optional `List<dynamic>` for row labels. Defaults to a default integer index (0, 1, 2, ...).
  /// - `allowFlexibleColumns`: A `bool` controlling column flexibility. Defaults to `false`.
  /// - `replaceMissingValueWith`: A `dynamic` value to use for missing entries (e.g., if a map lacks a key
  ///   that's part of the `finalColumns`).
  /// - `missingDataIndicator`: A `List` of values to treat as missing if `formatData` is true.
  /// - `formatData`: A `bool` to trigger `cleanData` on values. Defaults to `false`.
  ///
  /// Returns:
  /// A new `DataFrame`.
  ///
  /// Example:
  /// ```dart
  /// List<Map<dynamic, dynamic>> rowData = [
  ///   {'ID': 1, 'Name': 'Alice', 'Score': 95.5},
  ///   {'ID': 2, 'Name': 'Bob', 'Age': 28}, // 'Score' is missing, 'Age' is extra here
  ///   {'ID': 3, 'Name': 'Charlie', 'Score': 88.0, 'City': 'Paris'},
  /// ];
  ///
  /// // Infer columns from data (order might vary)
  /// DataFrame df1 = DataFrame.fromRows(rowData);
  /// print(df1);
  /// // Example Output (actual column order for inferred columns can vary):
  /// //   ID    Name  Score  Age   City
  /// // 0   1   Alice   95.5 null   null
  /// // 1   2     Bob   null   28   null
  /// // 2   3 Charlie   88.0 null  Paris
  ///
  /// // Specify columns to ensure order and selection
  /// DataFrame df2 = DataFrame.fromRows(rowData, columns: ['Name', 'ID', 'Score']);
  /// print(df2);
  /// // Output:
  /// //       Name  ID  Score
  /// // 0    Alice   1   95.5
  /// // 1      Bob   2   null  // Score is null as it was missing for Bob
  /// // 2  Charlie   3   88.0
  ///
  /// // Example with empty rows list:
  /// DataFrame emptyDf = DataFrame.fromRows([], columns: ['A', 'B']);
  /// print(emptyDf.columns); // Output: [A, B]
  /// print(emptyDf.rowCount);  // Output: 0
  /// ```
  factory DataFrame.fromRows(
    List<Map<dynamic, dynamic>> rows, {
    List<dynamic>? columns,
    List<dynamic> index = const [],
    bool allowFlexibleColumns = false,
    dynamic replaceMissingValueWith,
    List missingDataIndicator = const [],
    bool formatData = false,
  }) {
    if (rows.isEmpty) {
      return DataFrame.empty(
        columns:
            columns, // Use provided columns if any, otherwise it's an empty list
        index: index,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: missingDataIndicator, // Pass this along
      );
    }

    List<dynamic> finalColumns;
    if (columns != null) {
      finalColumns = List<dynamic>.from(columns);
    } else {
      // Infer columns from all unique keys in the rows.
      // Using a Set preserves insertion order for unique keys if Dart version supports it,
      // otherwise, order is not guaranteed. For strict order, consider LinkedHashSet.
      var columnSet = <dynamic>{};
      for (var rowMap in rows) {
        columnSet.addAll(rowMap.keys);
      }
      finalColumns = columnSet.toList();
    }

    List<List<dynamic>> data = [];
    for (var rowMap in rows) {
      List<dynamic> rowData = [];
      for (var colName in finalColumns) {
        rowData.add(rowMap.containsKey(colName)
            ? rowMap[colName]
            : replaceMissingValueWith);
      }
      data.add(rowData);
    }

    return DataFrame(
      data,
      columns: finalColumns,
      index: index, // Pass the original index list
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: missingDataIndicator,
      formatData: formatData,
    );
  }

  /// Converts the DataFrame to a list of maps (JSON-like structure).
  ///
  /// Each map in the list represents a row, with column names (as `String`) as keys.
  ///
  /// Returns:
  /// A `List<Map<String, dynamic>>` representing the DataFrame.
  /// This format is directly compatible with `jsonEncode()` from `dart:convert`.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 30],
  ///   ['Bob', 25],
  /// ], columns: ['Name', 'Age']);
  ///
  /// List<Map<String, dynamic>> jsonList = df.toJSON();
  /// print(jsonList);
  /// // Output:
  /// // [
  /// //   {'Name': 'Alice', 'Age': 30},
  /// //   {'Name': 'Bob', 'Age': 25}
  /// // ]
  ///
  /// String jsonString = jsonEncode(jsonList); // To get the actual JSON string
  /// print(jsonString);
  /// // Output: [{"Name":"Alice","Age":30},{"Name":"Bob","Age":25}]
  /// ```
  List<Map<String, dynamic>> toJSON() {
    return rows.map<Map<String, dynamic>>((row) {
      var rowMap = <String, dynamic>{};
      for (int i = 0; i < _columns.length; i++) {
        rowMap[_columns[i].toString()] = row[i];
      }
      return rowMap;
    }).toList();
  }

  /// Export the data to matrix
  ///
  ///Example:
  ///```dart
  ///df = DataFrame(
  ///  columns: ['A', 'B', 'C', 'D'],
  ///  data: [
  ///    [1, 2.5, 3, 4],
  ///    [2, 3.5, 4, 5],
  ///    [3, 4.5, 5, 6],
  ///    [4, 5.5, 6, 7],
  ///  ],
  ///);
  ///
  /// // Matrix: 4x4
  /// // ┌ 1 2.5 3 4 ┐
  /// // │ 2 3.5 4 5 │
  /// // │ 3 4.5 5 6 │
  /// // └ 4 5.5 6 7 ┘
  ///```
  //Matrix toMatrix() => Matrix(rows);

  /// Returns the number of rows in the DataFrame.
  ///
  /// Returns:
  /// An `int` representing the count of rows.
  int get rowCount => _data.length;

  /// Returns the number of columns in the DataFrame.
  ///
  /// Returns:
  /// An `int` representing the count of columns.
  int get columnCount => _columns.length;

  /// Returns the dimensions of the DataFrame as a list `[rowCount, columnCount]`.
  ///
  /// Returns:
  /// A `List<int>` where the first element is the number of rows and the second is the number of columns.
  List<int> get dimension => [rowCount, columnCount];

  /// Returns the list of column labels of the DataFrame.
  ///
  /// Returns:
  /// A `List<dynamic>` containing the column labels. The list is a copy, so
  /// modifying it will not affect the DataFrame's columns. To modify columns,
  /// use the `columns` setter.
  List<dynamic> get columns => List<dynamic>.from(_columns);

  /// Sets the column labels of the DataFrame.
  ///
  /// Parameters:
  /// - `newColumns`: A `List<dynamic>` of new column labels.
  ///
  /// Behavior:
  /// - If `allowFlexibleColumns` is `true`:
  ///   - If `newColumns` has more labels than current columns:
  ///     The DataFrame's columns are replaced with `newColumns`.
  ///     Data rows are extended with `replaceMissingValueWith` for the new columns.
  ///   - If `newColumns` has fewer labels than current columns:
  ///     Only the initial set of column labels are replaced by `newColumns`.
  ///     The remaining original column labels (and their data) are kept.
  ///     The DataFrame's data effectively determines the number of columns if it's wider
  ///     than `newColumns`. Consider explicitly selecting or dropping columns for truncation.
  /// - If `allowFlexibleColumns` is `false`:
  ///   - `newColumns` must have the same length as the current number of columns.
  ///     The existing column labels are replaced by `newColumns`.
  ///
  /// Throws:
  /// - `ArgumentError` if `allowFlexibleColumns` is `false` and the length of `newColumns`
  ///   does not match the current number of columns in `_data` (if data exists) or `_columns`.
  set columns(List<dynamic> newColumns) {
    int currentDataColumnCount =
        _data.isNotEmpty ? _data[0].length : _columns.length;

    if (newColumns.length != currentDataColumnCount && !allowFlexibleColumns) {
      throw ArgumentError(
          'Number of new column names (${newColumns.length}) must match existing number of data columns ($currentDataColumnCount) when allowFlexibleColumns is false.');
    }

    if (allowFlexibleColumns) {
      if (newColumns.length > currentDataColumnCount) {
        // More new columns than existing data columns
        _columns = List.from(newColumns);
        // Extend data rows if data exists
        if (_data.isNotEmpty) {
          for (var row in _data) {
            row.addAll(List.generate(newColumns.length - currentDataColumnCount,
                (_) => replaceMissingValueWith));
          }
        }
      } else if (newColumns.length < currentDataColumnCount) {
        // Fewer new columns than existing data columns: replace initial, keep rest of data columns
        _columns = List.from(newColumns);
        // Add back the names for the data columns that were not replaced
        if (currentDataColumnCount > newColumns.length) {
          _columns.addAll(List.generate(
              currentDataColumnCount - newColumns.length,
              (i) => 'Column${newColumns.length + i + 1}'));
        }
        // Data itself is not truncated here, only column labels are adjusted.
        // Effective columns are determined by data width if wider than newColumns.
      } else {
        // Same number of columns
        _columns = List.from(newColumns);
      }
    } else {
      // Not allowFlexibleColumns, lengths must match (already checked)
      _columns = List.from(newColumns);
    }
  }

  /// Returns the data of the DataFrame as a list of lists (rows).
  ///
  /// Each inner list represents a row. This is a direct view of the internal data.
  /// Modifying the returned list or its inner lists will modify the DataFrame.
  ///
  /// Returns:
  /// A `List<dynamic>` (effectively `List<List<dynamic>>`) representing the rows of the DataFrame.
  List<dynamic> get rows => _data;

  /// Returns the shape of the DataFrame as a Shape object.
  ///
  /// This provides both named access (rows, columns) and indexed access [0], [1]
  /// for pandas-like behavior.
  ///
  /// Returns:
  /// A Shape object with rows and columns properties and indexed access support.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([[1,2],[3,4]]);
  /// print(df.shape.rows);    // Output: 2
  /// print(df.shape.columns); // Output: 2
  /// print(df.shape[0]);      // Output: 2 (rows)
  /// print(df.shape[1]);      // Output: 2 (columns)
  /// print(df.shape.size);    // Output: 4 (total elements)
  /// ```
  Shape get shape => Shape.fromRowsColumns(_data.length, _columns.length);

  /// Returns a `Series` representing the column specified by `key`.
  ///
  /// This method is a convenience wrapper around the `operator []` for column access.
  ///
  /// Parameters:
  /// - `key`: An `int` (column index) or `String` (column name).
  ///
  /// Returns:
  /// A `Series` containing the data of the specified column. The Series' index
  /// will be the same as the DataFrame's index.
  ///
  /// Throws:
  /// - `IndexError` if `key` is an integer index out of bounds.
  /// - `ArgumentError` if `key` is a String name not found in columns, or if `key` is of an invalid type.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 10, 'B': 'x'},
  ///   {'A': 20, 'B': 'y'},
  /// ]);
  /// Series colA = df.column('A');
  /// print(colA);
  /// // Output: Series(name: A, index: [0, 1], data: [10, 20])
  ///
  /// Series colBByIndex = df.column(1); // Accesses column 'B'
  /// print(colBByIndex);
  /// // Output: Series(name: B, index: [0, 1], data: [x, y])
  /// ```
  Series column(dynamic key) {
    // The operator[] already handles String and int keys for column access,
    // and throws appropriate errors if the key is invalid or not found.
    // It will also correctly return a Series.
    if (key is int || key is String) {
      return this[key]
          as Series; // Cast is safe due to operator[] behavior for these types
    } else {
      throw ArgumentError(
          'Column key must be an int (index) or String (name). Invalid key: $key');
    }
  }

  /// Retrieves a single row from the DataFrame that matches all specified criteria.
  ///
  /// The criteria are provided as a map where keys are column names (String)
  /// and values are the exact values to match in those columns.
  ///
  /// Parameters:
  /// - `criteria`: A `Map<String, dynamic>` specifying the column-value pairs for matching.
  ///
  /// Returns:
  /// A `Map<String, dynamic>` representing the first row that matches all criteria.
  /// Keys in the returned map are column names, and values are the corresponding
  /// cell values from the matched row.
  ///
  /// Throws:
  /// - `ArgumentError` if a column name provided in `criteria` does not exist in the DataFrame.
  /// - `StateError` if no row matches all the given criteria.
  ///   (Note: The current implementation returns the *first* matching row if multiple exist;
  ///   it does not throw an error for multiple matches.)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'ID': 1, 'Name': 'Alice', 'Age': 30},
  ///   {'ID': 2, 'Name': 'Bob',   'Age': 25},
  ///   {'ID': 3, 'Name': 'Alice', 'Age': 35}, // Another Alice
  /// ]);
  ///
  /// // Get the row where Name is 'Bob'
  /// Map<String, dynamic> bobRow = df.row({'Name': 'Bob'});
  /// print(bobRow); // Output: {ID: 2, Name: Bob, Age: 25}
  ///
  /// // Get the row where Name is 'Alice' and Age is 35
  /// Map<String, dynamic> alice35Row = df.row({'Name': 'Alice', 'Age': 35});
  /// print(alice35Row); // Output: {ID: 3, Name: Alice, Age: 35}
  ///
  /// // Attempt to find a non-existent row
  /// try {
  ///   df.row({'Name': 'Charlie'});
  /// } catch (e) {
  ///   print(e); // Output: StateError: No row matches the given criteria
  /// }
  /// ```
  Map<String, dynamic> row(Map<String, dynamic> criteria) {
    // Find rows that match all criteria
    List<int> matchingIndices = [];

    for (int i = 0; i < _data.length; i++) {
      bool matches = true;

      for (var entry in criteria.entries) {
        final colName = entry.key;
        final value = entry.value;

        if (!_columns.contains(colName)) {
          throw ArgumentError(
              'Column "$colName" not found in DataFrame. Available columns: $_columns');
        }

        final colIndex = _columns.indexOf(colName);
        if (_data[i][colIndex] != value) {
          matches = false;
          break;
        }
      }

      if (matches) {
        matchingIndices.add(i);
      }
    }

    if (matchingIndices.isEmpty) {
      throw StateError('No row matches the given criteria: $criteria');
    }

    // Create a Map representation of the first matching row
    final rowIndex = matchingIndices[0];
    Map<String, dynamic> result = {};

    for (int i = 0; i < _columns.length; i++) {
      result[_columns[i].toString()] =
          _data[rowIndex][i]; // Ensure key is String
    }

    return result;
  }

  /// Accesses DataFrame content by column key or boolean Series filter.
  ///
  /// This operator has two main modes:
  /// 1. **Column Selection:**
  ///    - If `key` is an `int` (column index) or `String` (column name),
  ///      it returns the corresponding column as a `Series`.
  ///      The Series will have the DataFrame's index as its index.
  ///
  /// 2. **Boolean Filtering (Row Selection):**
  ///    - If `key` is a `Series` of boolean values, it filters the DataFrame rows.
  ///      - The boolean Series (`key`) is aligned with the DataFrame's index.
  ///        - If `key` has a default integer index and the DataFrame has a non-default index,
  ///          their lengths must match. `key` is applied row-wise.
  ///        - If `key`'s index matches the DataFrame's index, it's used directly.
  ///        - If both have default integer indices but different lengths, an `ArgumentError` is thrown.
  ///        - Otherwise, `key` is reindexed to match the DataFrame's index, with non-matching
  ///          indices resulting in `false` for filtering (or `replaceMissingValueWith` if it's a boolean).
  ///      - Rows where the aligned boolean Series value is `true` are included in the result.
  ///      - Returns a new `DataFrame` containing the filtered rows.
  ///
  /// Parameters:
  /// - `key`:
  ///   - An `int` for column selection by index.
  ///   - A `String` for column selection by name.
  ///   - A `Series` of booleans for row filtering.
  ///
  /// Returns:
  /// - A `Series` if selecting a column by name or integer index.
  /// - A `DataFrame` if filtering with a boolean Series.
  ///
  /// Throws:
  /// - `IndexError` if `key` is an integer index out of bounds for column selection.
  /// - `ArgumentError`:
  ///   - If `key` is a String name not found in columns.
  ///   - If a boolean `Series` used for filtering has mismatched length/index under certain conditions
  ///     (e.g., both default indexed but different lengths).
  ///   - If `key` is not an `int`, `String`, or boolean `Series`.
  ///
  /// Examples:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': 10, 'C': true},
  ///   {'A': 2, 'B': 20, 'C': false},
  ///   {'A': 3, 'B': 30, 'C': true},
  /// ], index: ['x', 'y', 'z']);
  ///
  /// // Column selection by name
  /// Series colA = df['A'];
  /// print(colA);
  /// // Output: Series(name: A, index: [x, y, z], data: [1, 2, 3])
  ///
  /// // Column selection by index
  /// Series colB_byIndex = df[1]; // Accesses column 'B'
  /// print(colB_byIndex);
  /// // Output: Series(name: B, index: [x, y, z], data: [10, 20, 30])
  ///
  /// // Boolean filtering with an aligned boolean Series
  /// Series filterCondition = Series([true, false, true], index: ['x', 'y', 'z']);
  /// DataFrame filteredDf = df[filterCondition];
  /// print(filteredDf);
  /// // Output:
  /// //   A   B     C
  /// // x  1  10  true
  /// // z  3  30  true
  ///
  /// // Boolean filtering with a condition derived from a column
  /// DataFrame filteredByB = df[df['B'] > 15]; // df['B'] > 15 returns a boolean Series
  /// print(filteredByB);
  /// // Output:
  /// //   A   B      C
  /// // y  2  20  false
  /// // z  3  30   true
  /// ```
  dynamic operator [](dynamic key) {
    // Handle boolean Series for filtering (pandas-like indexing)
    if (key is Series &&
        key.data.every((element) => element is bool || element == null)) {
      Series booleanFilter;

      bool keyHasDefaultIndex = _isDefaultIntegerIndex(key.index, key.length);
      bool dfHasDefaultIndex = _isDefaultIntegerIndex(index, rowCount);

      // Case 1: Boolean Series has default index, DataFrame has non-default index
      if (keyHasDefaultIndex && !dfHasDefaultIndex) {
        if (key.length != rowCount) {
          throw ArgumentError(
              'Boolean Series with default index (length ${key.length}) must match DataFrame row count ($rowCount) when DataFrame has a non-default index.');
        }
        // If lengths match, use the boolean series directly, it will be applied row-wise.
        booleanFilter = key;
      }
      // Case 2: Boolean Series has non-default index, OR both have default indices
      else {
        // Subcase 2.1: Indices are identical (implies lengths also match if truly identical)
        if (listEqual([key.index, index])) {
          if (key.length != rowCount) {
            // This should ideally not happen if indices are truly equal
            throw ArgumentError(
                'Boolean Series has matching index but mismatched length (${key.length} vs $rowCount). This indicates an inconsistency.');
          }
          booleanFilter = key;
        }
        // Subcase 2.2: Both have default indices but lengths differ (error)
        else if (keyHasDefaultIndex &&
            dfHasDefaultIndex &&
            key.length != rowCount) {
          throw ArgumentError(
              'Boolean Series (length ${key.length}) and DataFrame (length $rowCount) both have default indices but lengths do not match.');
        }
        // Subcase 2.3: Indices differ and require alignment
        else {
          List<bool?> alignedValues =
              List.filled(rowCount, false, growable: false);
          for (int i = 0; i < rowCount; i++) {
            var dfIndexValue = index[i];
            int seriesIndexPos = key.index.indexOf(dfIndexValue);
            if (seriesIndexPos != -1) {
              alignedValues[i] = key.data[seriesIndexPos] as bool?;
            } else {
              // Value from df.index not found in key.index, treat as false
              alignedValues[i] = false;
            }
          }
          booleanFilter =
              Series(alignedValues, index: List.from(index), name: key.name);
        }
      }

      List<List<dynamic>> filteredData = [];
      List<dynamic> filteredIndex = [];
      for (int i = 0; i < rowCount; i++) {
        // booleanFilter.data should now be correctly aligned or directly usable.
        // Nulls in booleanFilter.data are treated as false by `== true`.
        if (i < booleanFilter.length && booleanFilter.data[i] == true) {
          filteredData.add(List<dynamic>.from(_data[i]));
          filteredIndex.add(index[i]);
        }
      }

      return DataFrame._(
        List<dynamic>.from(_columns),
        filteredData,
        index: filteredIndex,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    }

    if (key is int) {
      if (key < 0 || key >= _columns.length) {
        throw IndexError.withLength(
          key,
          _columns.length,
          indexable: _columns,
          name: 'Index out of range',
          message: null,
        );
      }
      var series = Series<dynamic>(rows.map((row) => row[key]).toList(),
          name: _columns[key], index: index);
      series.setParent(this, _columns[key].toString());
      return series;
    } else if (key is String) {
      int columnIndex = _columns.indexOf(key);
      if (columnIndex == -1) {
        throw ArgumentError.value(key, 'columnName', 'Column does not exist');
      }
      var series = Series<dynamic>(rows.map((row) => row[columnIndex]).toList(),
          name: key, index: index);
      series.setParent(this, key);
      return series;
    } else {
      throw ArgumentError('Key must be an int or String');
    }
  }

  /// Updates the value of a single cell in the DataFrame, identified by column name and row position (integer index).
  ///
  /// Parameters:
  /// - `columnName`: The `String` name of the column where the cell is located.
  /// - `rowIndex`: The integer-based positional index of the row (0 to `rowCount - 1`).
  ///   This refers to the actual position in the underlying data, not the label-based `index` of the DataFrame.
  /// - `value`: The `dynamic` new value to set for the cell.
  ///
  /// Throws:
  /// - `ArgumentError` if `columnName` does not exist in the DataFrame.
  /// - `RangeError` if `rowIndex` is out of bounds (less than 0 or greater than or equal to `rowCount`).
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 30],
  ///   ['Bob', 25],
  /// ], columns: ['Name', 'Age']);
  ///
  /// print("Before update:\n$df");
  /// // Output:
  /// // Before update:
  /// //        Name  Age
  /// // 0    Alice   30
  /// // 1      Bob   25
  ///
  /// df.updateCell('Age', 0, 31); // Update Alice's age (row at index 0)
  /// df.updateCell('Name', 1, 'Robert'); // Update Bob's name (row at index 1)
  /// print("\nAfter update:\n$df");
  /// // Output:
  /// // After update:
  /// //         Name  Age
  /// // 0     Alice   31
  /// // 1    Robert   25
  /// ```
  void updateCell(String columnName, int rowIndex, dynamic value) {
    int columnIndex = _columns.indexOf(columnName);
    if (columnIndex == -1) {
      throw ArgumentError('Column $columnName does not exist');
    }

    if (rowIndex < 0 || rowIndex >= _data.length) {
      throw RangeError('Row index out of range');
    }

    _data[rowIndex][columnIndex] = value;
  }

  /// Updates or adds a column, or updates a row in the DataFrame using index assignment.
  ///
  /// **Column Assignment (if `key` is a `String` representing the column name):**
  /// - **With a `Series` (`newData`):**
  ///   - If `newData.index` is non-default numeric (i.e., label-based), values from `newData` are aligned
  ///     with the DataFrame's `index`. Rows in the DataFrame whose index labels are not found in
  ///     `newData.index` will receive `replaceMissingValueWith` in the target column.
  ///   - If `newData.index` is default numeric (0, 1, 2, ...), or if `newData` is a `List`,
  ///     values are assigned row by row based on position.
  ///     - If `newData` is shorter than the DataFrame's row count, remaining cells in the column get `replaceMissingValueWith`.
  ///     - If `newData` is longer, its values are effectively truncated to fit the DataFrame's row count.
  /// - **With a `List` (`newData`):** Values are assigned row by row, similar to a default-indexed Series.
  /// - **With a single `dynamic` value (`newData`):** The entire target column is filled with this value.
  /// - **New Column Creation:** If the column `key` does not exist:
  ///   - It's added to the DataFrame.
  ///   - If the DataFrame was empty:
  ///     - Its `index` might be derived from `newData.index` if `newData` is a Series with a non-default index.
  ///     - Otherwise, new rows are created with a default integer index matching the length of `newData`.
  ///   - Existing rows are padded with `replaceMissingValueWith` for this new column before assignment (if applicable).
  ///
  /// **Row Assignment (if `key` is an `int` representing the row's positional index):**
  /// - `newData` must be a `List` or a `Series`.
  /// - The length of `newData` (or `newData.data` if it's a Series) must exactly match the number of columns
  ///   in the DataFrame.
  /// - The row at the specified integer position `key` (0 to `rowCount - 1`) is replaced with the values from `newData`.
  ///
  /// Parameters:
  /// - `key`: A `String` (column name) or an `int` (row position).
  /// - `newData`: The data to assign, which can be a `Series`, `List`, or a single `dynamic` value.
  ///
  /// Throws:
  /// - `ArgumentError`:
  ///   - If `key` is not a `String` or `int`.
  ///   - For row assignment, if `newData`'s length doesn't match the DataFrame's column count.
  ///   - For column assignment with a new, empty DataFrame and `newData` being a single value (length ambiguity).
  /// - `RangeError`: For row assignment, if `key` (integer) is out of bounds.
  ///
  /// Example (Column Assignment):
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': 10},
  ///   {'A': 2, 'B': 20},
  /// ], index: ['x', 'y']);
  ///
  /// // Assign a List to an existing column 'B'
  /// df['B'] = [100, 200];
  ///
  /// // Assign a Series to a new column 'C' (aligned by DataFrame's index 'x', 'y')
  /// df['C'] = Series([true, false], index: ['y', 'x']); // Note index order for alignment
  ///
  /// // Assign a single value to a new column 'D'
  /// df['D'] = 99;
  /// print(df);
  /// // Output:
  /// //   A    B      C   D
  /// // x  1  200  false  99  // B[x]=200, C[x] used false from Series index 'x'
  /// // y  2  100   true  99  // B[y]=100, C[y] used true from Series index 'y'
  ///
  /// // Add a new column 'E' to an empty DataFrame
  /// var emptyDf = DataFrame.empty(columns: ['Existing']);
  /// emptyDf['E'] = [10, 20, 30]; // Creates rows and sets 'E'
  /// print(emptyDf);
  /// // Output:
  /// //   Existing   E
  /// // 0     null  10
  /// // 1     null  20
  /// // 2     null  30
  /// ```
  /// Example (Row Assignment):
  /// ```dart
  /// var df = DataFrame([[1,2],[3,4]], columns: ['X', 'Y']);
  /// df[0] = [10, 20]; // Update first row (at position 0)
  /// print(df);
  /// // Output:
  /// //    X   Y
  /// // 0  10  20
  /// // 1   3   4
  /// ```
  void operator []=(dynamic key, dynamic newData) {
    if (key is String) {
      List<dynamic> valuesToSet;
      List<dynamic>? seriesIndex = newData is Series ? newData.index : null;
      List<dynamic> seriesData = newData is Series
          ? newData.data
          : (newData is List ? newData : [newData]);

      // Determine if the Series has a non-default index that needs alignment
      bool alignByIndex = seriesIndex != null &&
          seriesIndex.isNotEmpty &&
          !_isDefaultNumericIndex(seriesIndex);

      int columnIndex = _columns.indexOf(key);
      bool newColumn = columnIndex == -1;

      if (newColumn) {
        // Add new column
        _columns.add(key);
        columnIndex = _columns.length - 1;
        // Ensure all existing rows have a placeholder for the new column
        for (int i = 0; i < _data.length; i++) {
          _data[i]
              .add(replaceMissingValueWith); // Initialize with missing value
        }
      }

      // If DataFrame is empty and we are adding a new column
      if (_data.isEmpty && newColumn) {
        int numRowsToCreate = seriesData.length;
        if (alignByIndex) {
          // If aligning by a new series index, df index should become that.
          index = List.from(seriesIndex);
          numRowsToCreate = seriesIndex.length;
        } else {
          index = List.generate(numRowsToCreate, (i) => i);
        }

        _data = List.generate(
            numRowsToCreate,
            (i) => List.filled(_columns.length, replaceMissingValueWith,
                growable: true));
      }

      // Prepare valuesToSet based on alignment strategy
      if (alignByIndex) {
        valuesToSet =
            List.filled(index.length, replaceMissingValueWith, growable: true);
        Map<dynamic, dynamic> seriesMap = {};
        for (int i = 0; i < seriesIndex.length; i++) {
          seriesMap[seriesIndex[i]] = seriesData[i];
        }
        for (int i = 0; i < index.length; i++) {
          if (seriesMap.containsKey(index[i])) {
            valuesToSet[i] = seriesMap[index[i]];
          }
        }
      } else {
        // Direct assignment or length adjustment for default-indexed Series or List
        valuesToSet =
            List.filled(index.length, replaceMissingValueWith, growable: true);
        for (int i = 0; i < index.length; i++) {
          if (i < seriesData.length) {
            valuesToSet[i] = seriesData[i];
          } else {
            break; // Stop if series data is shorter
          }
        }
      }

      // Set the data for the column
      for (int i = 0; i < _data.length; i++) {
        if (newColumn && _data[i].length <= columnIndex) {
          // Should have been handled by init
          _data[i].addAll(List.filled(
              (columnIndex + 1 - _data[i].length).toInt(),
              replaceMissingValueWith));
        }
        _data[i][columnIndex] = valuesToSet[i];
      }
    } else if (key is int) {
      // Row assignment (assuming newData is a List matching column count)
      if (key < 0 || key >= _data.length) {
        throw RangeError('Row index out of range');
      }
      List<dynamic> rowData = newData is Series ? newData.data : newData;
      if (rowData.length != _columns.length) {
        throw ArgumentError(
            'Length of data must match the number of columns (${_columns.length})');
      }
      _data[key] = List<dynamic>.from(rowData);
    } else {
      throw ArgumentError(
          'Key must be an integer (for row) or string (for column)');
    }
  } // Helper method to check if an index is the default numeric index

  /// Helper method to check if a given list `idx` represents a default numeric index
  /// (i.e., 0, 1, 2, ... up to `idx.length - 1`).
  ///
  /// Parameters:
  /// - `idx`: The `List<dynamic>` to check.
  ///
  /// Returns:
  /// `true` if `idx` is a default numeric index, `false` otherwise.
  /// An empty list is considered a default numeric index.
  bool _isDefaultNumericIndex(List<dynamic> idx) {
    if (idx.isEmpty) return true; // An empty index can be considered default

    for (int i = 0; i < idx.length; i++) {
      if (idx[i] != i) return false;
    }
    return true;
  }

  /// Handles invocations of methods or properties not explicitly defined for the DataFrame.
  ///
  /// This is primarily used to allow accessing columns as if they were properties of the DataFrame,
  /// e.g., `df.myColumnName` can be used as a shorthand for `df['myColumnName']` to retrieve a column Series.
  ///
  /// Parameters:
  /// - `invocation`: The `Invocation` object representing the method call or property access.
  ///
  /// Returns:
  /// - A `Series` if `invocation.memberName` corresponds to an existing column name and
  ///   it's accessed as a getter (property-like access).
  /// - Otherwise, it calls `super.noSuchMethod(invocation)` which typically throws a `NoSuchMethodError`.
  ///
  /// Note:
  /// If a column name conflicts with an actual DataFrame method or property name,
  /// the explicit method/property will take precedence.
  @override
  noSuchMethod(Invocation invocation) {
    // Convert symbol to string, removing 'Symbol("' and '")'
    String memberNameStr = invocation.memberName.toString();
    memberNameStr = memberNameStr.substring(8, memberNameStr.length - 2);

    // Check if it's a getter for a column name
    if (invocation.isGetter && _columns.contains(memberNameStr)) {
      return this[memberNameStr];
    }
    // To maintain some backward compatibility or catch accidental method calls on column names:
    // This part is debatable. If a column name is 'sort', df.sort() would be ambiguous.
    // Current dartframe behavior seems to allow df.columnName even if it's not a getter.
    if (!invocation.isAccessor && _columns.contains(memberNameStr)) {
      // This could be an attempt to call a column as a function.
      // For now, assume it means to access the column as a Series.
      return this[memberNameStr];
    }
    super.noSuchMethod(invocation);
  }

  /// Returns a string representation of the DataFrame, formatted as a table.
  ///
  /// The output includes row indices and column headers, with cell values aligned.
  ///
  /// Parameters:
  /// - `columnSpacing`: The number of spaces to put between columns. Defaults to `2`.
  ///
  /// Returns:
  /// A `String` representing the formatted DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 30, 'New York'],
  ///   ['Bob', 25, 'Los Angeles'],
  ///   ['Charlie', 35, 'Chicago'],
  /// ], columns: ['Name', 'Age', 'City'], index: ['P1', 'P2', 'P3']);
  /// print(df.toString());
  /// // Output:
  /// //     Name     Age          City
  /// // P1  Alice    30      New York
  /// // P2    Bob    25   Los Angeles
  /// // P3  Charlie  35       Chicago
  ///
  /// var emptyDf = DataFrame.empty(columns: ['A', 'B']);
  /// print(emptyDf);
  /// // Output:
  /// //        A  B
  /// // ... (0 rows) ...
  ///
  /// var completelyEmptyDf = DataFrame.empty();
  /// print(completelyEmptyDf);
  /// // Output:
  /// // Empty DataFrame
  /// // Dimensions: [0, 0]
  /// // Index: []
  /// // Columns: []
  /// ```
  @override
  String toString({int columnSpacing = 2}) {
    if (_data.isEmpty && _columns.isEmpty) {
      return "Empty DataFrame\nDimensions: [0, 0]\nIndex: []\nColumns: []";
    }
    if (_data.isEmpty && _columns.isNotEmpty) {
      StringBuffer buffer = StringBuffer();
      // Determine a nominal width for the index column header for alignment
      int rowIndexHeaderWidth = index.fold(
          0,
          (max, val) =>
              val.toString().length > max ? val.toString().length : max);
      rowIndexHeaderWidth = max(rowIndexHeaderWidth,
          " ".length); // Minimum width for the index column header itself

      buffer.write(' '.padRight(rowIndexHeaderWidth +
          columnSpacing)); // Space for index column name (blank for empty data)

      for (var colName in _columns) {
        buffer.write(colName
            .toString()
            .padRight(colName.toString().length + columnSpacing));
      }
      buffer.writeln();
      buffer.writeln("... (0 rows) ...");
      return buffer.toString();
    }

    // Calculate column widths based on data and column headers
    List<int> columnWidths = [];
    for (var i = 0; i < _columns.length; i++) {
      int maxColumnWidth = _columns[i].toString().length;
      for (var row in _data) {
        if (i < row.length) {
          // Ensure row has this column
          int cellWidth = (row[i]?.toString() ?? 'null').length;
          if (cellWidth > maxColumnWidth) {
            maxColumnWidth = cellWidth;
          }
        } else {
          // Row is shorter than columns list (can happen with flexible columns)
          int nullWidth = 'null'.length;
          if (nullWidth > maxColumnWidth) maxColumnWidth = nullWidth;
        }
      }
      columnWidths.add(maxColumnWidth);
    }

    // Calculate the maximum width needed for row index labels
    int rowIndexLabelWidth = 0;
    if (index.isNotEmpty) {
      for (var label in index) {
        int labelWidth = (label?.toString() ?? 'null').length;
        if (labelWidth > rowIndexLabelWidth) {
          rowIndexLabelWidth = labelWidth;
        }
      }
    } else if (_data.isNotEmpty) {
      // Default integer index "0", "1", ...
      rowIndexLabelWidth = (_data.length - 1).toString().length;
    }
    rowIndexLabelWidth =
        max(rowIndexLabelWidth, " ".length); // Min width for index col header

    StringBuffer buffer = StringBuffer();

    // Add column headers: Index column header (blank) + data column headers
    buffer.write(' '.padRight(rowIndexLabelWidth + columnSpacing));
    for (var i = 0; i < _columns.length; i++) {
      buffer.write(
          _columns[i].toString().padRight(columnWidths[i] + columnSpacing));
    }
    buffer.writeln();

    // Add data rows
    for (int r = 0; r < _data.length; r++) {
      var row = _data[r];

      // Add row index label
      var indexLabelStr = (r < index.length)
          ? (index[r]?.toString() ?? 'null')
          : r.toString(); // Fallback if index list is somehow shorter
      buffer.write(indexLabelStr.padRight(rowIndexLabelWidth + columnSpacing));

      // Add cell data for the row
      for (var c = 0; c < _columns.length; c++) {
        String cellValueStr;
        if (c < row.length && row[c] != null) {
          cellValueStr = row[c].toString();
        } else if (c < row.length && row[c] == null) {
          cellValueStr = 'null';
        } else {
          // Cell doesn't exist (row shorter than _columns list)
          cellValueStr = 'null';
        }
        buffer.write(cellValueStr.padRight(columnWidths[c] + columnSpacing));
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Provides access to DataFrame selection by integer position (like `iloc` in pandas).
  ///
  /// See [DataFrameILocAccessor] for detailed documentation on how to use `.iloc`.
  /// It allows selection of rows, columns, and individual cells by their integer positions.
  ///
  /// Returns:
  /// A `DataFrameILocAccessor` instance associated with this DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([[1,2],[3,4]], columns: ['A', 'B']);
  ///
  /// // Select the first row as a Series
  /// print(df.iloc[0]);
  /// // Output: Series(name: 0, index: [A, B], data: [1, 2])
  ///
  /// // Select the value at the first row, second column
  /// print(df.iloc(0, 1));
  /// // Output: 2
  ///
  /// // Select a sub-DataFrame
  /// print(df.iloc([0], [1]));
  /// // Output:
  /// //    B
  /// // 0  2
  /// ```
  DataFrameILocAccessor get iloc => DataFrameILocAccessor(this);

  /// Provides access to DataFrame selection by labels (like `loc` in pandas).
  ///
  /// See [DataFrameLocAccessor] for detailed documentation on how to use `.loc`.
  /// It allows selection of rows, columns, and individual cells using their labels
  /// (from the DataFrame's `index` and `columns` lists).
  ///
  /// Returns:
  /// A `DataFrameLocAccessor` instance associated with this DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([[1,2],[3,4]], columns: ['A', 'B'], index: ['r1', 'r2']);
  ///
  /// // Select row 'r1' as a Series
  /// print(df.loc['r1']);
  /// // Output: Series(name: r1, index: [A, B], data: [1, 2])
  ///
  /// // Select the value at row 'r1', column 'B'
  /// print(df.loc('r1', 'B'));
  /// // Output: 2
  ///
  /// // Select a sub-DataFrame using labels
  /// print(df.loc(['r1'], ['B']));
  /// // Output:
  /// //     B
  /// // r1  2
  /// ```
  DataFrameLocAccessor get loc => DataFrameLocAccessor(this);
}
