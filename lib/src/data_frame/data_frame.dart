import 'dart:convert';

import 'package:intl/intl.dart';
import 'dart:math';

import '../../dartframe.dart';

part 'accessors.dart';
part 'functions.dart';
part 'operations.dart';
part 'statistics.dart';
part 'reshaping.dart';
part 'time_series.dart';
part 'timezone_operations.dart';
part 'resampling.dart';
part 'sampling_enhanced.dart';
part 'duplicate_functions.dart';
part 'functional_programming.dart';
part 'expression_evaluation.dart';
part 'multi_index_integration.dart';
part 'advanced_slicing.dart';
part 'groupby.dart';
part 'window_functions.dart';
part 'export_formats.dart';
part 'web_api.dart';
part 'smart_loader.dart';
part 'inspection.dart';
part 'alignment.dart';
part 'conditional.dart';
part 'comparison.dart';
part 'iteration.dart';
part 'missing_data.dart';
part 'missing_data_advanced.dart';
part 'sorting_enhanced.dart';
part 'aggregation_advanced.dart';
part 'merging_advanced.dart';
part 'timeseries_advanced.dart';
part 'metadata_formatting.dart';

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
class DataFrame implements DartData {
  List<dynamic> _columns = List.empty(growable: true);
  List<dynamic> index = List.empty(growable: true);
  List<dynamic> _data = List.empty(growable: true);
  final bool allowFlexibleColumns;
  dynamic replaceMissingValueWith;
  List<dynamic> _missingDataIndicator = List.empty(growable: true);
  Attributes? _attrs;

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

  /// Constructs a DataFrame from a CSV (Comma Separated Values) file or string.
  ///
  /// This method uses the new `[FileReader]` infrastructure for robust CSV parsing.
  /// Supports both file paths and direct CSV string content.
  ///
  /// Parameters:
  /// - `path`: Path to the CSV file to read (optional if `csv` is provided).
  /// - `csv`: CSV string content to parse (optional if `path` is provided).
  /// - `fieldDelimiter`: Field separator character (default: ',').
  /// - `textDelimiter`: Text quote character (default: '"').
  /// - `hasHeader`: Whether first row is header (default: true).
  /// - `skipRows`: Number of rows to skip (default: 0).
  /// - `maxRows`: Maximum rows to read (default: all).
  /// - `columnNames`: Custom column names when no header.
  /// - `formatData`: Apply data cleaning and type conversion (default: false).
  /// - `missingDataIndicator`: List of values to treat as missing when formatData is true.
  /// - `replaceMissingValueWith`: Value to use for missing data.
  /// - `allowFlexibleColumns`: Allow dynamic column changes (default: false).
  /// - `options`: Additional CSV parsing options.
  ///
  /// Returns:
  /// A `Future<DataFrame>` that completes with the newly created DataFrame.
  ///
  /// Throws:
  /// - `ArgumentError` if both `path` and `csv` are null.
  ///
  /// Example:
  /// ```dart
  /// // Read CSV file with header
  /// final df = await DataFrame.fromCSV(path: 'data.csv');
  ///
  /// // Parse CSV string with data formatting
  /// String csvData = "Name,Age,City\nAlice,30,New York\nBob,24,San Francisco";
  /// final df = await DataFrame.fromCSV(
  ///   csv: csvData,
  ///   formatData: true,
  ///   missingDataIndicator: ['NA', 'N/A'],
  ///   replaceMissingValueWith: null,
  /// );
  ///
  /// // Read semicolon-separated file
  /// final df = await DataFrame.fromCSV(
  ///   path: 'data.csv',
  ///   fieldDelimiter: ';',
  /// );
  ///
  /// // Parse CSV string without header
  /// String csvDataNoHeader = "apple,1.0\nbanana,0.5";
  /// final df = await DataFrame.fromCSV(
  ///   csv: csvDataNoHeader,
  ///   hasHeader: false,
  ///   columnNames: ['item', 'price'],
  /// );
  /// ```
  ///
  /// See also:
  /// - [FileReader.readCsv] for more CSV reading options
  /// - [toCSV] for writing DataFrames to CSV files
  static Future<DataFrame> fromCSV({
    String? path,
    String? csv,
    String delimiter = ',',
    String textDelimiter = '"',
    bool hasHeader = true,
    int? skipRows,
    int? maxRows,
    List<String>? columnNames,
    bool formatData = false,
    List<dynamic> missingDataIndicator = const [],
    dynamic replaceMissingValueWith,
    bool allowFlexibleColumns = false,
    Map<String, dynamic>? options,
  }) async {
    if (path == null && csv == null) {
      throw ArgumentError('Either path or csv must be provided.');
    }

    DataFrame df;

    // If CSV string is provided, write to temp file and read it
    if (csv != null) {
      final tempFile = FileIO();
      final tempPath = '.temp_csv_${DateTime.now().millisecondsSinceEpoch}.csv';
      try {
        await tempFile.saveToFile(tempPath, csv);
        df = await FileReader.readCsv(
          tempPath,
          fieldDelimiter: delimiter,
          textDelimiter: textDelimiter,
          hasHeader: hasHeader,
          skipRows: skipRows,
          maxRows: maxRows,
          columnNames: columnNames,
          options: options,
        );
      } finally {
        // Clean up temp file
        try {
          await tempFile.deleteFile(tempPath);
        } catch (_) {
          // Ignore cleanup errors
        }
      }
    } else {
      // Otherwise read from file path
      df = await FileReader.readCsv(
        path!,
        fieldDelimiter: delimiter,
        textDelimiter: textDelimiter,
        hasHeader: hasHeader,
        skipRows: skipRows,
        maxRows: maxRows,
        columnNames: columnNames,
        options: options,
      );
    }

    // Apply DataFrame-specific post-processing if needed
    if (formatData ||
        missingDataIndicator.isNotEmpty ||
        replaceMissingValueWith != null ||
        allowFlexibleColumns) {
      // Create a new DataFrame with the specified options
      return DataFrame._(
        df._columns,
        df._data,
        index: df.index,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        formatData: formatData,
        missingDataIndicator: missingDataIndicator,
      );
    }

    return df;
  }

  /// Constructs a DataFrame from a JSON file or string.
  ///
  /// This method uses the new [FileReader] infrastructure for robust JSON parsing
  /// with support for multiple orientations. Supports both file paths and direct JSON string content.
  ///
  /// Parameters:
  /// - `path`: Path to the JSON file to read (optional if `jsonString` is provided).
  /// - `jsonString`: JSON string content to parse (optional if `path` is provided).
  /// - `orient`: JSON orientation format (default: 'records').
  ///   - 'records': List of objects `[{"col1": val1}, ...]`
  ///   - 'index': Object with index keys `{"0": {"col1": val1}, ...}`
  ///   - 'columns': Object with column arrays `{"col1": [val1, val2], ...}`
  ///   - 'values': 2D array `[[val1, val2], ...]`
  /// - `columns`: Column names for 'values' orientation.
  /// - `formatData`: Apply data cleaning and type conversion (default: false).
  /// - `missingDataIndicator`: List of values to treat as missing when formatData is true.
  /// - `replaceMissingValueWith`: Value to use for missing data.
  /// - `allowFlexibleColumns`: Allow dynamic column changes (default: false).
  /// - `options`: Additional JSON parsing options.
  ///
  /// Returns:
  /// A `Future<DataFrame>` that completes with the newly created DataFrame.
  ///
  /// Throws:
  /// - `ArgumentError` if both `path` and `jsonString` are null.
  ///
  /// Example:
  /// ```dart
  /// // Read from file (records format - default)
  /// final df = await DataFrame.fromJson(path: 'data.json');
  ///
  /// // Parse JSON string with data formatting
  /// String jsonData = '''
  /// [
  ///   {"id": 1, "product": "Laptop", "price": 1200.00},
  ///   {"id": 2, "product": "Mouse", "price": 25.50, "inStock": true},
  ///   {"id": 3, "product": "Keyboard", "price": 75.00}
  /// ]
  /// ''';
  /// final df = await DataFrame.fromJson(
  ///   jsonString: jsonData,
  ///   formatData: true,
  ///   missingDataIndicator: ['NA', 'N/A'],
  ///   replaceMissingValueWith: null,
  /// );
  ///
  /// // Read columns format from file
  /// final df = await DataFrame.fromJson(
  ///   path: 'data.json',
  ///   orient: 'columns',
  /// );
  ///
  /// // Parse values format with column names
  /// final df = await DataFrame.fromJson(
  ///   jsonString: '[[1, 2], [3, 4]]',
  ///   orient: 'values',
  ///   columns: ['col1', 'col2'],
  /// );
  /// ```
  ///
  /// See also:
  /// - [FileReader.readJson] for more JSON reading options
  /// - [toJSON] for converting DataFrames to JSON format
  static Future<DataFrame> fromJson({
    String? path,
    String? jsonString,
    String orient = 'records',
    List<String>? columns,
    bool formatData = false,
    List<dynamic> missingDataIndicator = const [],
    dynamic replaceMissingValueWith,
    bool allowFlexibleColumns = false,
    Map<String, dynamic>? options,
  }) async {
    if (path == null && jsonString == null) {
      throw ArgumentError('Either path or jsonString must be provided.');
    }

    DataFrame df;

    // If JSON string is provided, write to temp file and read it
    if (jsonString != null) {
      final tempFile = FileIO();
      final tempPath =
          '.temp_json_${DateTime.now().millisecondsSinceEpoch}.json';
      try {
        await tempFile.saveToFile(tempPath, jsonString);
        df = await FileReader.readJson(
          tempPath,
          orient: orient,
          columns: columns,
          options: options,
        );
      } finally {
        // Clean up temp file
        try {
          await tempFile.deleteFile(tempPath);
        } catch (_) {
          // Ignore cleanup errors
        }
      }
    } else {
      // Otherwise read from file path
      df = await FileReader.readJson(
        path!,
        orient: orient,
        columns: columns,
        options: options,
      );
    }

    // Apply DataFrame-specific post-processing if needed
    if (formatData ||
        missingDataIndicator.isNotEmpty ||
        replaceMissingValueWith != null ||
        allowFlexibleColumns) {
      // Create a new DataFrame with the specified options
      return DataFrame._(
        df._columns,
        df._data,
        index: df.index,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        formatData: formatData,
        missingDataIndicator: missingDataIndicator,
      );
    }

    return df;
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

  /// Reads data from a URI and returns a DataFrame.
  ///
  /// This static method provides a pandas-like API for loading data from
  /// various sources with automatic source detection.
  ///
  /// ## Supported Sources
  /// - Local files: `'data.csv'`, `'file:///path/to/data.json'`
  /// - HTTP/HTTPS: `'https://example.com/data.csv'`
  /// - Scientific datasets: `'dataset://iris'`, `'dataset://mnist/train'`
  /// - Databases: `'sqlite://db.sqlite?table=users'`
  ///
  /// ## Parameters
  /// - `uri`: URI string or path to the data source
  /// - `options`: Source-specific and format-specific options
  ///
  /// ## Example
  /// ```dart
  /// // Local file
  /// final df = await DataFrame.read('data.csv');
  ///
  /// // HTTP URL
  /// final df = await DataFrame.read('https://example.com/data.json');
  ///
  /// // Scientific dataset
  /// final df = await DataFrame.read('dataset://iris');
  ///
  /// // Database
  /// final df = await DataFrame.read('sqlite://db.sqlite?table=users');
  ///
  /// // With options
  /// final df = await DataFrame.read('data.csv', options: {
  ///   'fieldDelimiter': ';',
  ///   'skipRows': 1,
  /// });
  /// ```
  static Future<DataFrame> read(
    String uri, {
    Map<String, dynamic>? options,
  }) async {
    return await SmartLoader.read(uri, options: options);
  }

  /// Inspects a data source without loading all data.
  ///
  /// Returns metadata about the source such as size, format, columns, etc.
  ///
  /// ## Example
  /// ```dart
  /// final info = await DataFrame.inspect('data.csv');
  /// print('Size: ${info['size']} bytes');
  /// print('Format: ${info['format']}');
  /// ```
  static Future<Map<String, dynamic>> inspect(String uri) async {
    return await SmartLoader.inspect(uri);
  }

  /// Converts the DataFrame to JSON format or writes it to a JSON file.
  ///
  /// This method has two modes of operation:
  /// 1. **In-memory conversion** (when `path` is null): Returns a JSON-compatible structure
  /// 2. **File writing** (when `path` is provided): Writes JSON to a file
  ///
  /// Parameters:
  /// - `path`: Optional path where the JSON file will be saved. If null, returns in-memory structure.
  /// - `orient`: JSON orientation format (default: 'records').
  ///   - 'records': List of objects `[{"col1": val1}, ...]`
  ///   - 'index': Object with index keys `{"0": {"col1": val1}, ...}`
  ///   - 'columns': Object with column arrays `{"col1": [val1, val2], ...}`
  ///   - 'values': 2D array `[[val1, val2], ...]`
  /// - `includeIndex`: Include row index in output (default: false).
  /// - `indent`: Number of spaces for indentation when writing to file (default: no indentation).
  /// - `options`: Additional JSON options.
  ///
  /// Returns:
  /// - When `path` is null: A `List<Map<String, dynamic>>` (for 'records' orient) or appropriate structure
  /// - When `path` is provided: A `Future<void>` that completes when the file has been written
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 30],
  ///   ['Bob', 25],
  /// ], columns: ['Name', 'Age']);
  ///
  /// // In-memory conversion (records format - default)
  /// List<Map<String, dynamic>> jsonList = df.toJSON();
  /// print(jsonList);
  /// // Output: [{'Name': 'Alice', 'Age': 30}, {'Name': 'Bob', 'Age': 25}]
  ///
  /// // Convert to JSON string
  /// String jsonString = jsonEncode(df.toJSON());
  /// // Output: [{"Name":"Alice","Age":30},{"Name":"Bob","Age":25}]
  ///
  /// // Write to file (records format)
  /// await df.toJSON(path: 'output.json');
  ///
  /// // Write with columns format and pretty-printing
  /// await df.toJSON(
  ///   path: 'output.json',
  ///   orient: 'columns',
  ///   indent: 2,
  /// );
  ///
  /// // In-memory with different orientation
  /// var columnsData = df.toJSON(orient: 'columns');
  /// // Returns: {"Name": ["Alice", "Bob"], "Age": [30, 25]}
  /// ```
  ///
  /// See also:
  /// - [FileWriter.writeJson] for more JSON writing options
  /// - [fromJson] for reading JSON files
  dynamic toJSON({
    String? path,
    String orient = 'records',
    bool includeIndex = false,
    int? indent,
    Map<String, dynamic>? options,
  }) {
    // If path is provided, write to file
    if (path != null) {
      return FileWriter.writeJson(
        this,
        path,
        orient: orient,
        includeIndex: includeIndex,
        indent: indent,
        options: options,
      );
    }

    // Otherwise, return in-memory structure based on orientation
    switch (orient) {
      case 'records':
        return rows.map<Map<String, dynamic>>((row) {
          var rowMap = <String, dynamic>{};
          if (includeIndex) {
            rowMap['index'] = rows.indexOf(row);
          }
          for (int i = 0; i < _columns.length; i++) {
            rowMap[_columns[i].toString()] = row[i];
          }
          return rowMap;
        }).toList();

      case 'index':
        var result = <String, Map<String, dynamic>>{};
        for (int i = 0; i < rows.length; i++) {
          var rowMap = <String, dynamic>{};
          for (int j = 0; j < _columns.length; j++) {
            rowMap[_columns[j].toString()] = rows[i][j];
          }
          result[i.toString()] = rowMap;
        }
        return result;

      case 'columns':
        var result = <String, List<dynamic>>{};
        for (var col in _columns) {
          result[col.toString()] = this[col].toList();
        }
        return result;

      case 'values':
        return rows.map((row) => List<dynamic>.from(row)).toList();

      default:
        // Default to records format
        return rows.map<Map<String, dynamic>>((row) {
          var rowMap = <String, dynamic>{};
          for (int i = 0; i < _columns.length; i++) {
            rowMap[_columns[i].toString()] = row[i];
          }
          return rowMap;
        }).toList();
    }
  }

  /// Constructs a DataFrame from an Excel file.
  ///
  /// This method uses the new [FileReader] infrastructure for robust Excel parsing.
  ///
  /// Parameters:
  /// - `path`: Path to the Excel file (.xlsx, .xls).
  /// - `sheetName`: Name of sheet to read (default: first sheet).
  /// - `hasHeader`: Whether first row is header (default: true).
  /// - `skipRows`: Number of rows to skip (default: 0).
  /// - `maxRows`: Maximum rows to read (default: all).
  /// - `columnNames`: Custom column names when no header.
  /// - `options`: Additional Excel parsing options.
  ///
  /// Returns:
  /// A `Future<DataFrame>` that completes with the newly created DataFrame.
  ///
  /// Example:
  /// ```dart
  /// // Read first sheet
  /// final df = await DataFrame.fromExcel(path: 'data.xlsx');
  ///
  /// // Read specific sheet
  /// final df = await DataFrame.fromExcel(
  ///   path: 'data.xlsx',
  ///   sheetName: 'Sales',
  ///   skipRows: 1,
  /// );
  /// ```
  ///
  /// See also:
  /// - [FileReader.readExcel] for more Excel reading options
  /// - [FileReader.readAllExcelSheets] for reading all sheets
  /// - [toExcel] for writing DataFrames to Excel files
  static Future<DataFrame> fromExcel({
    required String path,
    String? sheetName,
    bool hasHeader = true,
    int? skipRows,
    int? maxRows,
    List<String>? columnNames,
    Map<String, dynamic>? options,
  }) async {
    return FileReader.readExcel(
      path,
      sheetName: sheetName,
      hasHeader: hasHeader,
      skipRows: skipRows,
      maxRows: maxRows,
      columnNames: columnNames,
      options: options,
    );
  }

  /// Constructs a DataFrame from an HDF5 file.
  ///
  /// This method uses the new [FileReader] infrastructure for HDF5 parsing.
  ///
  /// Parameters:
  /// - `path`: Path to the HDF5 file (.h5, .hdf5).
  /// - `dataset`: Path to dataset within the file (default: '/data').
  /// - `options`: Additional HDF5 parsing options.
  ///
  /// Returns:
  /// A `Future<DataFrame>` that completes with the newly created DataFrame.
  ///
  /// Example:
  /// ```dart
  /// // Read default dataset
  /// final df = await DataFrame.fromHDF5(path: 'data.h5');
  ///
  /// // Read specific dataset
  /// final df = await DataFrame.fromHDF5(
  ///   path: 'data.h5',
  ///   dataset: '/measurements/temperature',
  /// );
  /// ```
  ///
  /// See also:
  /// - [FileReader.readHDF5] for more HDF5 reading options
  /// - [FileReader.inspectHDF5] for examining file structure
  static Future<DataFrame> fromHDF5({
    required String path,
    String? dataset,
    Map<String, dynamic>? options,
  }) async {
    return FileReader.readHDF5(
      path,
      dataset: dataset,
      options: options,
    );
  }

  /// Constructs a DataFrame from a Parquet file.
  ///
  /// This method uses the new [FileReader] infrastructure for Parquet parsing.
  ///
  /// **Note:** This is a basic implementation. For production use with real
  /// Parquet files, integrate a proper Parquet library.
  ///
  /// Parameters:
  /// - `path`: Path to the Parquet file (.parquet, .pq).
  /// - `options`: Additional Parquet parsing options.
  ///
  /// Returns:
  /// A `Future<DataFrame>` that completes with the newly created DataFrame.
  ///
  /// Example:
  /// ```dart
  /// final df = await DataFrame.fromParquet(path: 'data.parquet');
  /// ```
  ///
  /// See also:
  /// - [FileReader.readParquet] for more Parquet reading options
  /// - [toParquet] for writing DataFrames to Parquet files
  static Future<DataFrame> fromParquet({
    required String path,
    Map<String, dynamic>? options,
  }) async {
    return FileReader.readParquet(path, options: options);
  }

  /// Read HTML tables from a string.
  ///
  /// This is a convenience method that delegates to the web_api extension.
  /// See [DataFrameWebAPI.readHtml] for full documentation.
  static List<DataFrame> readHtml(
    String html, {
    dynamic match,
    int header = 0,
    int? indexCol,
    List<int>? skiprows,
    Map<String, String> attrs = const {},
    bool parseNumbers = true,
  }) {
    // This will be implemented in the web_api extension
    // We need to create a dummy DataFrame to access the extension method
    return DataFrameWebAPI._readHtmlStatic(
      html,
      match: match,
      header: header,
      indexCol: indexCol,
      skiprows: skiprows,
      attrs: attrs,
      parseNumbers: parseNumbers,
    );
  }

  /// Read XML data into DataFrame.
  ///
  /// This is a convenience method that delegates to the web_api extension.
  /// See [DataFrameWebAPI.readXml] for full documentation.
  static DataFrame readXml(
    String xml, {
    String? xpath,
    String rowName = 'row',
    bool parseNumbers = true,
    String attrPrefix = '@',
  }) {
    // This will be implemented in the web_api extension
    return DataFrameWebAPI._readXmlStatic(
      xml,
      xpath: xpath,
      rowName: rowName,
      parseNumbers: parseNumbers,
      attrPrefix: attrPrefix,
    );
  }

  /// Writes the DataFrame to a CSV file.
  ///
  /// This method uses the new [FileWriter] infrastructure for robust CSV writing.
  ///
  /// Parameters:
  /// - `path`: Path where the CSV file will be saved.
  /// - `fieldDelimiter`: Field separator character (default: ',').
  /// - `textDelimiter`: Text quote character (default: '"').
  /// - `includeHeader`: Include header row (default: true).
  /// - `includeIndex`: Include row index column (default: false).
  /// - `eol`: Line ending character (default: '\n').
  /// - `options`: Additional CSV writing options.
  ///
  /// Returns:
  /// A `Future<void>` that completes when the file has been written.
  ///
  /// Example:
  /// ```dart
  /// // Write CSV file
  /// await df.toCSV(path: 'output.csv');
  ///
  /// // Write semicolon-separated file
  /// await df.toCSV(
  ///   path: 'output.csv',
  ///   fieldDelimiter: ';',
  /// );
  ///
  /// // Write with index column
  /// await df.toCSV(
  ///   path: 'output.csv',
  ///   includeIndex: true,
  /// );
  /// ```
  ///
  /// See also:
  /// - [FileWriter.writeCsv] for more CSV writing options
  /// - [fromCSV] for reading CSV files
  Future<void> toCSV({
    required String path,
    String fieldDelimiter = ',',
    String textDelimiter = '"',
    bool includeHeader = true,
    bool includeIndex = false,
    String? eol,
    Map<String, dynamic>? options,
  }) async {
    return FileWriter.writeCsv(
      this,
      path,
      fieldDelimiter: fieldDelimiter,
      textDelimiter: textDelimiter,
      includeHeader: includeHeader,
      includeIndex: includeIndex,
      eol: eol,
      options: options,
    );
  }

  /// Writes the DataFrame to an Excel file.
  ///
  /// This method uses the new [FileWriter] infrastructure for robust Excel writing.
  ///
  /// Parameters:
  /// - `path`: Path where the Excel file will be saved.
  /// - `sheetName`: Name of the sheet to create (default: 'Sheet1').
  /// - `includeHeader`: Include header row (default: true).
  /// - `includeIndex`: Include row index column (default: false).
  /// - `options`: Additional Excel writing options.
  ///
  /// Returns:
  /// A `Future<void>` that completes when the file has been written.
  ///
  /// Example:
  /// ```dart
  /// // Write Excel file
  /// await df.toExcel(path: 'output.xlsx');
  ///
  /// // Write with custom sheet name
  /// await df.toExcel(
  ///   path: 'output.xlsx',
  ///   sheetName: 'MyData',
  /// );
  ///
  /// // Write with index column
  /// await df.toExcel(
  ///   path: 'output.xlsx',
  ///   includeIndex: true,
  /// );
  /// ```
  ///
  /// See also:
  /// - [FileWriter.writeExcel] for more Excel writing options
  /// - [FileWriter.writeExcelSheets] for writing multiple sheets
  /// - [fromExcel] for reading Excel files
  Future<void> toExcel({
    required String path,
    String sheetName = 'Sheet1',
    bool includeHeader = true,
    bool includeIndex = false,
    Map<String, dynamic>? options,
  }) async {
    return FileWriter.writeExcel(
      this,
      path,
      sheetName: sheetName,
      includeHeader: includeHeader,
      includeIndex: includeIndex,
      options: options,
    );
  }

  /// Writes the DataFrame to a Parquet file.
  ///
  /// This method uses the new [FileWriter] infrastructure for Parquet writing.
  ///
  /// **Note:** This is a basic implementation. For production use with real
  /// Parquet files, integrate a proper Parquet library.
  ///
  /// Parameters:
  /// - `path`: Path where the Parquet file will be saved.
  /// - `compression`: Compression method (default: 'none').
  /// - `includeIndex`: Include row index column (default: false).
  /// - `options`: Additional Parquet writing options.
  ///
  /// Returns:
  /// A `Future<void>` that completes when the file has been written.
  ///
  /// Example:
  /// ```dart
  /// // Write Parquet file
  /// await df.toParquet(path: 'output.parquet');
  ///
  /// // Write with compression
  /// await df.toParquet(
  ///   path: 'output.parquet',
  ///   compression: 'gzip',
  /// );
  /// ```
  ///
  /// See also:
  /// - [FileWriter.writeParquet] for more Parquet writing options
  /// - [fromParquet] for reading Parquet files
  Future<void> toParquet({
    required String path,
    String compression = 'none',
    bool includeIndex = false,
    Map<String, dynamic>? options,
  }) async {
    return FileWriter.writeParquet(
      this,
      path,
      compression: compression,
      includeIndex: includeIndex,
      options: options,
    );
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
  /// This provides both named access (rows, columns) and indexed access `[0], [1]`
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
  @override
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
      Series series = Series(rows.map((row) => row[key]).toList(),
          name: _columns[key].toString(), index: index);
      series.setParent(this, _columns[key].toString());
      return series;
    } else if (key is String) {
      int columnIndex = _columns.indexOf(key);
      if (columnIndex == -1) {
        throw ArgumentError.value(key, 'columnName', 'Column does not exist');
      }
      Series series = Series(rows.map((row) => row[columnIndex]).toList(),
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
  String toString({
    int maxRows = 60,
    int maxCols = 20,
    int maxColWidth = 20,
    int columnSpacing = 2,
    bool showIndex = true,
    bool showDtype = false,
    Map<String, String Function(dynamic)>? formatters,
  }) {
    final buffer = StringBuffer();
    final dfLength = rowCount;
    final dfColumns = columns;
    final dfIndex = index;

    if (rowCount == 0 && dfColumns.isEmpty) {
      buffer.writeln('Empty DataFrame');
      buffer.writeln('Dimensions: [0, 0]');
      buffer.writeln('Index: []');
      buffer.writeln('Columns: []');
      return buffer.toString();
    }

    // Determine which rows and columns to display
    final displayRows = dfLength > maxRows
        ? [
            ...List.generate(maxRows ~/ 2, (i) => i),
            -1,
            ...List.generate(
                maxRows ~/ 2, (i) => dfLength - (maxRows ~/ 2) + i),
          ]
        : List.generate(dfLength, (i) => i);

    final displayCols = dfColumns.length > maxCols
        ? [
            ...List.generate(maxCols ~/ 2, (i) => i),
            -1,
            ...List.generate(
                maxCols ~/ 2, (i) => dfColumns.length - (maxCols ~/ 2) + i),
          ]
        : List.generate(dfColumns.length, (i) => i);

    // Calculate column widths
    final colWidths = <int>[];
    if (showIndex) {
      final indexWidth = dfIndex
          .map((idx) => idx.toString().length)
          .fold(0, (max, len) => len > max ? len : max)
          .clamp(0, maxColWidth);
      colWidths.add(indexWidth + columnSpacing);
    }

    for (final colIdx in displayCols) {
      if (colIdx == -1) {
        colWidths.add(3 + columnSpacing);
        continue;
      }
      final col = dfColumns[colIdx];
      final colName = col.toString();
      var width = colName.length;

      for (final rowIdx in displayRows) {
        if (rowIdx == -1) continue;
        final value = this[col][rowIdx];
        final formatted = formatters?.containsKey(colName) == true
            ? formatters![colName]!(value)
            : value.toString();
        width = width > formatted.length ? width : formatted.length;
      }

      colWidths.add(width.clamp(0, maxColWidth) + columnSpacing);
    }

    // Header row
    if (showIndex) {
      buffer.write(''.padRight(colWidths[0]));
    }

    var colWidthIdx = showIndex ? 1 : 0;
    for (final colIdx in displayCols) {
      if (colIdx == -1) {
        buffer.write('...'.padRight(colWidths[colWidthIdx]));
      } else {
        final colName = dfColumns[colIdx].toString();
        buffer.write(colName.padRight(colWidths[colWidthIdx]));
      }
      colWidthIdx++;
    }
    buffer.writeln();

    // Data rows
    for (final rowIdx in displayRows) {
      if (rowIdx == -1) {
        if (showIndex) {
          buffer.write('...'.padRight(colWidths[0]));
        }
        colWidthIdx = showIndex ? 1 : 0;
        for (final _ in displayCols) {
          buffer.write('...'.padRight(colWidths[colWidthIdx]));
          colWidthIdx++;
        }
        buffer.writeln();
        continue;
      }

      if (showIndex) {
        buffer.write(dfIndex[rowIdx].toString().padRight(colWidths[0]));
      }

      colWidthIdx = showIndex ? 1 : 0;
      for (final colIdx in displayCols) {
        if (colIdx == -1) {
          buffer.write('...'.padRight(colWidths[colWidthIdx]));
        } else {
          final col = dfColumns[colIdx];
          final value = this[col][rowIdx];
          final colName = col.toString();
          final formatted = formatters?.containsKey(colName) == true
              ? formatters![colName]!(value)
              : value.toString();
          buffer.write(formatted.padRight(colWidths[colWidthIdx]));
        }
        colWidthIdx++;
      }
      buffer.writeln();
    }

    // Let's show it if truncated OR showDtype is true.
    if (showDtype || dfLength > maxRows || dfColumns.length > maxCols) {
      buffer.writeln('\n[$rowCount rows x ${columns.length} columns]');
    }

    // Data types footer
    if (showDtype) {
      buffer.writeln('dtypes:');
      for (final col in dfColumns) {
        final dtype = _inferColumnType(col);
        buffer.writeln('  $col: $dtype');
      }
    }

    return buffer.toString();
  }

  String _inferColumnType(dynamic col) {
    final series = column(col);
    if (series.isEmpty) return 'empty';

    final firstNonNull =
        series.data.firstWhere((v) => v != null, orElse: () => null);
    if (firstNonNull == null) return 'null';
    if (firstNonNull is int) return 'int';
    if (firstNonNull is double) return 'double';
    if (firstNonNull is num) return 'num';
    if (firstNonNull is String) return 'string';
    if (firstNonNull is bool) return 'bool';
    if (firstNonNull is DateTime) return 'datetime';
    return 'object';
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

  // ============ DartData Interface Implementation ============

  /// Number of dimensions (always 2 for DataFrame)
  @override
  int get ndim => 2;

  /// Total number of elements (rows × columns)
  @override
  int get size => rowCount * columnCount;

  /// Metadata attributes (HDF5-style)
  @override
  Attributes get attrs {
    _attrs ??= Attributes();
    return _attrs!;
  }

  /// Data type - DataFrame is heterogeneous, returns dynamic
  @override
  Type get dtype => dynamic;

  /// DataFrame is always heterogeneous
  @override
  bool get isHomogeneous => false;

  /// Get type information for each column
  @override
  Map<String, Type> get columnTypes {
    final types = <String, Type>{};

    for (var col in columns) {
      final colName = col.toString();

      if (rowCount == 0) {
        types[colName] = dynamic;
        continue;
      }

      // Find first non-null value to infer type
      Type? inferredType;
      final series = this[col];

      for (var value in series.data) {
        if (value != null && value != replaceMissingValueWith) {
          inferredType = value.runtimeType;
          break;
        }
      }

      types[colName] = inferredType ?? dynamic;
    }

    return types;
  }

  /// Get value at multi-dimensional indices `[row, column]`
  @override
  dynamic getValue(List<int> indices) {
    if (indices.length != 2) {
      throw ArgumentError(
          'DataFrame requires exactly 2 indices [row, column], got ${indices.length}');
    }

    final row = indices[0];
    final col = indices[1];

    if (row < 0 || row >= rowCount) {
      throw RangeError('Row index $row out of range [0, $rowCount)');
    }

    if (col < 0 || col >= columnCount) {
      throw RangeError('Column index $col out of range [0, $columnCount)');
    }

    return iloc(row, col);
  }

  /// Set value at multi-dimensional indices [row, column]
  @override
  void setValue(List<int> indices, dynamic value) {
    if (indices.length != 2) {
      throw ArgumentError(
          'DataFrame requires exactly 2 indices [row, column], got ${indices.length}');
    }

    final row = indices[0];
    final col = indices[1];

    if (row < 0 || row >= rowCount) {
      throw RangeError('Row index $row out of range [0, $rowCount)');
    }

    if (col < 0 || col >= columnCount) {
      throw RangeError('Column index $col out of range [0, $columnCount)');
    }

    _data[row][col] = value;
  }

  /// Slice the DataFrame using DartData-style slicing
  @override
  DartData slice(List<dynamic> sliceSpec) {
    if (sliceSpec.isEmpty || sliceSpec.length > 2) {
      throw ArgumentError(
          'DataFrame slice requires 1 or 2 specifications, got ${sliceSpec.length}');
    }

    // Normalize slice specifications
    final rowSpec = sliceSpec.isNotEmpty ? sliceSpec[0] : Slice.all();
    final colSpec = sliceSpec.length > 1 ? sliceSpec[1] : Slice.all();

    // Convert to SliceSpec objects
    final rowSlice = _normalizeSliceSpec(rowSpec, rowCount);
    final colSlice = _normalizeSliceSpec(colSpec, columnCount);

    // Check if both are single indices (returns Scalar)
    if (rowSlice.isSingleIndex && colSlice.isSingleIndex) {
      return Scalar(getValue([rowSlice.start!, colSlice.start!]));
    }

    // Get row and column indices
    final rowIndices = _resolveSliceIndices(rowSlice, rowCount);
    final colIndices = _resolveSliceIndices(colSlice, columnCount);

    // Single row or single column returns Series
    if (rowIndices.length == 1 && colIndices.length > 1) {
      // Single row -> Series
      final rowData =
          colIndices.map((c) => getValue([rowIndices[0], c])).toList();
      final colNames = colIndices.map((c) => columns[c]).toList();
      return Series(rowData,
          name: index[rowIndices[0]].toString(), index: colNames);
    }

    if (colIndices.length == 1 && rowIndices.length > 1) {
      // Single column -> Series
      final colData =
          rowIndices.map((r) => getValue([r, colIndices[0]])).toList();
      final rowLabels = rowIndices.map((r) => index[r]).toList();
      return Series(colData,
          name: columns[colIndices[0]].toString(), index: rowLabels);
    }

    // Multiple rows and columns -> DataFrame
    final newData = rowIndices.map((r) {
      return colIndices.map((c) => getValue([r, c])).toList();
    }).toList();

    final newColumns = colIndices.map((c) => columns[c]).toList();
    final newIndex = rowIndices.map((r) => index[r]).toList();

    return DataFrame(
      newData,
      columns: newColumns,
      index: newIndex,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Normalize a slice specification to SliceSpec
  SliceSpec _normalizeSliceSpec(dynamic spec, int dimSize) {
    if (spec is SliceSpec) {
      return spec;
    } else if (spec is int) {
      // Handle negative indices
      final idx = spec < 0 ? dimSize + spec : spec;
      return Slice.single(idx);
    } else if (spec == null) {
      return Slice.all();
    } else {
      throw ArgumentError('Invalid slice specification: $spec');
    }
  }

  /// Resolve a SliceSpec to actual indices
  List<int> _resolveSliceIndices(SliceSpec spec, int dimSize) {
    if (spec.isSingleIndex) {
      return [spec.start!];
    }

    final (start, stop, step) = spec.resolve(dimSize);
    final indices = <int>[];

    if (step > 0) {
      for (int i = start; i < stop; i += step) {
        if (i >= 0 && i < dimSize) {
          indices.add(i);
        }
      }
    } else {
      for (int i = start; i > stop; i += step) {
        if (i >= 0 && i < dimSize) {
          indices.add(i);
        }
      }
    }

    return indices;
  }
}
