part of '../../dartframe.dart';

/// A class representing a DataFrame, which is a 2-dimensional labeled data structure
/// with columns of potentially different types.
class DataFrame {
  List<dynamic> _columns = List.empty(growable: true);
  List<dynamic> index = List.empty(growable: true);
  List<dynamic> _data = List.empty(growable: true);
  final bool allowFlexibleColumns;
  dynamic replaceMissingValueWith;
  List<dynamic> _missingDataIndicator = List.empty(growable: true);

  /// Constructs a DataFrame with provided column names and data.
  ///
  /// Throws an ArgumentError if the number of column names does not match the number
  /// of data columns or if any data column has a different length.
  DataFrame._(
    this._columns,
    this._data, {
    this.index = const [],
    this.allowFlexibleColumns = false,
    this.replaceMissingValueWith,
    bool formatData = false,
    List<dynamic> missingDataIndicator = const [],
  }) : _missingDataIndicator = missingDataIndicator {
    // Validate data structure (e.g., all columns have the same length)
    // if (_columns.length != _data[0].length) {
    //   throw ArgumentError(
    //       'Number of column names must match number of data columns.');
    // }
    for (var i = 1; i < _data.length; i++) {
      if (_data[i].length != _data[0].length) {
        throw ArgumentError('All data columns must have the same length.');
      }
    }

    if (formatData) {
      // Clean and convert data
      _data = _data.map((row) => row.map(cleanData).toList()).toList();
    }

    // If index was entered, check that it's given for all rows or throw error (pd)
    if (index.isNotEmpty) {
      if (index.length != _data.length) {
        throw Exception('Index must match number of rows entered');
      }
    }
    // 3.b. If index was not entered, auto-generate
    if (index.isEmpty) {
      index = List.generate(_data.length, (i) => i);
    }
  }

  /// Creates an empty DataFrame.
  ///
  /// This constructor is provided for convenience to create an empty DataFrame
  /// without having to pass any arguments.
  ///
  /// Example:
  /// ```dart
  /// final df = DataFrame.empty();
  /// ```
  DataFrame.empty({
    List<dynamic>? columns,
    this.allowFlexibleColumns = false,
    this.replaceMissingValueWith,
    List<dynamic> missingDataIndicator = const [],
  })  : _missingDataIndicator = missingDataIndicator,
        _data = [],
        _columns = columns ?? [],
        index = [];

  /// Constructs a DataFrame with the provided column names and data.
  ///
  /// - The [columns] parameter specifies the names of the columns in the DataFrame.
  ///
  /// - The [data] parameter specifies the actual data in the DataFrame, organized as a
  /// list of rows, where each row is represented as a list of values corresponding to
  /// the columns.
  ///
  /// - The [index]: Optional list to use as index for the DataFrame
  ///
  /// Example:
  /// ```dart
  /// // Initialize with positional data parameter and named parameters
  /// final df = DataFrame(data:[
  ///   [1, 2, 3.0],
  ///   [4, 5, 6],
  ///   [7, 'hi', 9]
  /// ], rowHeader: [
  ///   'Dog',
  ///   'Dog',
  ///   'Catty'
  /// ], columns: [
  ///   'a',
  ///   'b',
  ///   'c'
  /// ]);
  ///
  /// // Initialize with only data
  /// final df2 = DataFrame(data: [
  ///   [1, 2, 3.0],
  ///   [4, 5, 6],
  ///   [7, 'hi', 9]
  /// ]);
  ///
  /// // Initialize empty DataFrame
  /// final df3 = DataFrame([]);
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
  /// 1. Handles missing data by checking if the value:
  ///    - Is in the list of missing data indicators
  ///    - Is null
  ///    - Is an empty string
  ///    If any of these conditions are met, returns [replaceMissingValueWith].
  ///
  /// 2. Attempts type conversion in the following order:
  ///    - Numeric conversion: Tries to parse strings as numbers
  ///    - Boolean conversion: Converts "true"/"false" strings to boolean values
  ///    - Date/time parsing: Attempts to parse strings as dates using common formats
  ///    - List conversion: Tries to parse strings that look like lists
  ///
  /// 3. Returns the original value if no conversion is applicable.
  ///
  /// Example:
  /// ```dart
  /// // Numeric conversion
  /// cleanData("123") // Returns 123 (as num)
  ///
  /// // Boolean conversion
  /// cleanData("true") // Returns true (as bool)
  ///
  /// // Missing value handling
  /// cleanData(null) // Returns replaceMissingValueWith
  /// cleanData("") // Returns replaceMissingValueWith
  /// cleanData("NA") // Returns replaceMissingValueWith if "NA" is in missingDataIndicator
  ///
  /// // No conversion applicable
  /// cleanData("hello") // Returns "hello" (unchanged)
  /// ```
  ///
  /// @param value The value to clean and potentially convert
  /// @return The cleaned/converted value, or [replaceMissingValueWith] if the value is missing
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

  /// Constructs a DataFrame from a CSV string.
  ///
  /// The CSV string can be provided directly or by specifying an input file path.
  /// The delimiter can be customized, and it's assumed that the CSV has a header row.
  ///
  /// Example:
  /// ```dart
  /// var csvData = 'Name,Age,City\nAlice,30,New York\nBob,25,Los Angeles\nCharlie,35,Chicago';
  /// var df = await DataFrame.fromCSV(csv: csvData, delimiter: ',', hasHeader: true);
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

  /// Constructs a DataFrame from a JSON string.
  ///
  /// The JSON string can be provided directly or by specifying an input file path.
  /// The JSON object is expected to be a list of objects with consistent keys.
  ///
  /// Example:
  /// ```dart
  /// var jsonData = '[{"Name": "Alice", "Age": 30, "City": "New York"}, '
  ///                '{"Name": "Bob", "Age": 25, "City": "Los Angeles"}, '
  ///                '{"Name": "Charlie", "Age": 35, "City": "Chicago"}]';
  /// var df = await DataFrame.fromJson(jsonString: jsonData);
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

  /// Creates an empty DataFrame with the specified column names.
  ///
  /// This factory constructor creates a DataFrame with no rows but with the specified columns.
  /// Useful for creating template DataFrames that will be populated later.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromNames(['Name', 'Age', 'City']);
  /// // Creates an empty DataFrame with columns 'Name', 'Age', and 'City'
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

  /// Constructs a DataFrame from a map where keys are column names and values
  /// are lists representing column data.
  ///
  /// The [map] parameter is a map where keys represent column names and values
  /// represent column data as lists. All lists in the map must have the same
  /// length.
  ///
  /// Throws an [ArgumentError] if the lists in the map have different lengths.
  ///
  /// Example:
  /// ```dart
  /// Map<String, List<dynamic>> map = {
  ///   'A': [1, 2, 3],
  ///   'B': ['a', 'b', 'c'],
  ///   'C': [true, false, true],
  /// };
  ///
  /// // Create a DataFrame from the map
  /// DataFrame df = DataFrame.fromMap(map);
  /// print(df);
  /// ```
  factory DataFrame.fromMap(
    Map<String, List<dynamic>> map, {
    bool allowFlexibleColumns = false,
    dynamic replaceMissingValueWith,
    List missingDataIndicator = const [],
    List index = const [],
    bool formatData = false,
  }) {
    // Extract column names and data from the map
    List<String> columns = map.keys.toList();
    List<List<dynamic>> data = [];

    // Check if all lists have the same length
    int length = -1;
    for (var columnData in map.values) {
      if (length == -1) {
        length = columnData.length;
      } else if (columnData.length != length) {
        throw ArgumentError('All lists must have the same length');
      }
    }

    // Populate the DataFrame with the provided data
    for (int i = 0; i < length; i++) {
      List<dynamic> rowData = [];
      for (var columnData in map.values) {
        rowData.add(columnData[i]);
      }
      data.add(rowData);
    }

    return DataFrame(
      data,
      columns: columns,
      index: index,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: missingDataIndicator,
      formatData: formatData,
    );
  }

  /// Constructs a DataFrame from a list of maps, where each map represents a row.
  ///
  /// The keys of the maps are used as column names, and the values are used as cell values.
  /// All maps should have the same keys, or at least contain all the keys that will be used as columns.
  ///
  /// Example:
  /// ```dart
  /// final df = DataFrame.fromRows([
  ///   {'Name': 'Alice', 'Age': 30, 'City': 'New York'},
  ///   {'Name': 'Bob', 'Age': 25, 'City': 'Los Angeles'},
  ///   {'Name': 'Charlie', 'Age': 35, 'City': 'Chicago'},
  /// ]);
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
        columns: columns,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
      );
    }

    // Extract all unique keys from all maps to use as columns
    Set<dynamic> allKeys = {};
    for (var row in rows) {
      allKeys.addAll(row.keys);
    }

    // Use provided columns or all keys from the maps
    List<dynamic> finalColumns = columns ?? allKeys.toList();

    // Create data rows
    List<List<dynamic>> data = [];
    for (var row in rows) {
      List<dynamic> rowData = [];
      for (var col in finalColumns) {
        rowData.add(row.containsKey(col) ? row[col] : replaceMissingValueWith);
      }
      data.add(rowData);
    }

    return DataFrame(
      data,
      columns: finalColumns,
      index: index,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: missingDataIndicator,
      formatData: formatData,
    );
  }

  // Export the data as JSON
  ///
  /// Example usage:
  ///```dart
  /// String jsonString = jsonEncode(df.toJSON());
  /// print(jsonString);
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
  int get rowCount => _data.length;

  /// Returns the number of columns in the DataFrame.
  int get columnCount => _columns.length;

  /// Returns the shape/dimension of the DataFrame as a list `[rows, columns]`.
  List<int> get dimension => [rowCount, columnCount];

  /// Returns the column names of the DataFrame.
  List<dynamic> get columns => _columns;

  /// Set the columns names
  set columns(List<dynamic> columns) {
    if (columns.length != _columns.length) {
      if (allowFlexibleColumns == true) {
        // Handling mismatched lengths:
        if (columns.length > _columns.length) {
          // More columns provided: Replace old columns
          _columns = columns;
          for (var row in _data) {
            // Add nulls or a default value for newly added columns
            row.addAll(List.generate((columns.length - row.length).toInt(),
                (_) => replaceMissingValueWith));
          }
        } else if (columns.length < _columns.length) {
          // Fewer columns provided: Consider these options:
          _columns = columns
              .followedBy(_columns.getRange(columns.length, _columns.length))
              .toList();
        }
      } else {
        // Option 2: Throw an error if flexible columns are not allowed
        throw ArgumentError('Number of columns must match existing data.');
      }
    } else {
      _columns = columns;
    }
  }

  /// Returns the data of the DataFrame.
  List<dynamic> get rows => _data;

  /// Returns the shape of the DataFrame as a tuple (number of rows, number of columns).
  ({int rows, int columns}) get shape =>
      (rows: _data.length, columns: _columns.length);

  /// Returns a Series object for the specified column name.
  ///
  /// This method provides a convenient way to access a column as a Series.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': 'x'},
  ///   {'A': 2, 'B': 'y'},
  /// ]);
  /// var colA = df.column('A');
  /// print(colA.data); // [1, 2]
  /// ```
  Series column(String name) {
    if (!_columns.contains(name)) {
      throw ArgumentError('Column "$name" not found in DataFrame');
    }
    return this[name];
  }

  /// Returns a Map representation of the row that matches the given criteria.
  ///
  /// Parameters:
  ///   - `criteria`: A Map where keys are column names and values are the values to match.
  ///
  /// Returns:
  ///   A Map with column names as keys and row values as values.
  ///
  /// Throws:
  ///   - `StateError` if no row matches the criteria or if multiple rows match.
  Map<String, dynamic> row(Map<String, dynamic> criteria) {
    // Find rows that match all criteria
    List<int> matchingIndices = [];

    for (int i = 0; i < _data.length; i++) {
      bool matches = true;

      for (var entry in criteria.entries) {
        final colName = entry.key;
        final value = entry.value;

        if (!_columns.contains(colName)) {
          throw ArgumentError('Column "$colName" not found in DataFrame');
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
      throw StateError('No row matches the given criteria');
    }

    // Create a Map representation of the first matching row
    final rowIndex = matchingIndices[0];
    Map<String, dynamic> result = {};

    for (int i = 0; i < _columns.length; i++) {
      result[_columns[i]] = _data[rowIndex][i];
    }

    return result;
  }

  // Operator [] overridden to access column by index or name
  // Modified operator[] to return a Series
  /// Returns a [Series] for the specified column,
  /// accessed by index or name.
  ///
  /// If [key] is an integer, returns the Series for the column at that index.
  /// If [key] is a String, returns the Series for the column with that name.
  ///
  /// Throws an [IndexError] if the index is out of range.
  /// Throws an [ArgumentError] if the name does not match a column.
  /// Returns a [Series] for the specified column,
  /// accessed by index or name.
  ///
  /// If [key] is an integer, returns the Series for the column at that index.
  /// If [key] is a String, returns the Series for the column with that name.
  ///
  /// Throws an [IndexError] if the index is out of range.
  /// Throws an [ArgumentError] if the name does not match a column.
  dynamic operator [](dynamic key) {
    // Handle boolean Series for filtering (pandas-like indexing)
    if (key is Series &&
        key.data.every((element) => element is bool || element == null)) {
      // Create a new DataFrame with only the rows where the Series value is true
      List<List<dynamic>> filteredData = [];
      List<dynamic> filteredIndex = [];

      // Ensure the Series length matches the DataFrame row count
      if (key.length != rowCount) {
        throw ArgumentError(
            'Boolean Series length must match DataFrame row count');
      }

      // Filter rows based on boolean values
      for (int i = 0; i < rowCount; i++) {
        if (key.data[i] == true) {
          filteredData.add(List<dynamic>.from(_data[i]));
          filteredIndex.add(index[i]);
        }
      }

      // Return a new DataFrame with the filtered data
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
      var series = Series(rows.map((row) => row[key]).toList(),
          name: _columns[key], index: index);
      series.setParent(this, _columns[key].toString());
      return series;
    } else if (key is String) {
      int columnIndex = _columns.indexOf(key);
      if (columnIndex == -1) {
        throw ArgumentError.value(key, 'columnName', 'Column does not exist');
      }
      var series = Series(rows.map((row) => row[columnIndex]).toList(),
          name: key, index: index);
      series.setParent(this, key);
      return series;
    } else {
      throw ArgumentError('Key must be an int or String');
    }
  }

  /// Updates a single cell in the DataFrame
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

  /// Overrides the index assignment operator `[]` to allow updating a row or column in the DataFrame.
  ///
  /// If the key is an integer, it updates the row at the specified index. The length of the data must match the number of columns.
  ///
  /// If the key is a string, it updates the column with the specified name. If the column already exists, it updates the existing column. If the column does not exist, it adds a new column. The length of the data must match the number of rows.
  ///
  /// Throws a `RangeError` if the index is out of range.
  /// Throws an `ArgumentError` if the length of the data does not match the number of columns or rows.
  /// Throws an `ArgumentError` if the key is not an integer or string.
  void operator []=(dynamic key, dynamic newData) {
    // Handle Series with index alignment
    if (newData is Series) {
      // If the Series has a custom index, we need to align it with the DataFrame's index
      if (newData.index.isNotEmpty && !_isDefaultNumericIndex(newData.index)) {
        // For existing column, align by index
        if (key is String && _columns.contains(key)) {
          int columnIndex = _columns.indexOf(key);

          // Create a map from Series index to values for quick lookup
          Map<dynamic, dynamic> indexToValue = {};
          for (int i = 0; i < newData.index.length; i++) {
            indexToValue[newData.index[i]] = newData.data[i];
          }

          // Update values based on matching indices
          for (int i = 0; i < index.length; i++) {
            if (indexToValue.containsKey(index[i])) {
              _data[i][columnIndex] = indexToValue[index[i]];
            }
          }

          return; // Early return as we've handled the assignment
        }
      }
    }

    // Convert Series to List if needed
    List<dynamic> data = newData is Series ? newData.data : newData;

    // Check if the key is an index (row update)
    if (key is int) {
      // Check if the row index is valid
      if (key < 0 || key >= _data.length) {
        throw RangeError('Row index out of range');
      }

      // Check if the length of the data matches the number of columns
      if (data.length != _columns.length) {
        throw ArgumentError(
            'Length of data must match the number of columns (${_columns.length})');
      }

      // Update the row at the specified index - create a new growable list
      _data[key] = List<dynamic>.from(data);
    }
    // Check if the key is a column label (column update)
    else if (key is String) {
      int columnIndex = _columns.indexOf(key);

      // If the column exists, update it
      if (columnIndex != -1) {
        // If data is longer than the DataFrame, expand the DataFrame
        if (data.length > _data.length) {
          // Calculate how many new rows we need to add
          int additionalRows = data.length - _data.length;

          // Add new rows with null values for all existing columns
          for (int i = 0; i < additionalRows; i++) {
            // Create a new growable list with nulls for each column
            List<dynamic> newRow =
                List<dynamic>.filled(_columns.length, null, growable: true);
            _data.add(newRow);

            // Also extend the index
            if (index.isNotEmpty) {
              // If the last index is numeric, continue the sequence
              if (index.last is int) {
                index.add(index.last + 1);
              } else {
                // Otherwise just use the row number
                index.add(_data.length - 1);
              }
            }
          }
        }

        // Update the column with the data
        for (int i = 0; i < _data.length; i++) {
          // If we have data for this row, use it; otherwise use null
          _data[i][columnIndex] = i < data.length ? data[i] : null;
        }
      }
      // If the column doesn't exist, add a new one
      else {
        // Handle empty DataFrame case
        if (_data.isEmpty) {
          // Initialize with empty rows for the first column
          _data = List.generate(data.length, (_) => <dynamic>[]);
          _columns.add(key);

          // Add the new column data
          for (int i = 0; i < data.length; i++) {
            _data[i].add(data[i]);
          }

          // Initialize index if empty
          if (index.isEmpty) {
            index = List.generate(data.length, (i) => i);
          }
        } else {
          // If data is longer than the DataFrame, expand the DataFrame
          if (data.length > _data.length) {
            // Calculate how many new rows we need to add
            int additionalRows = data.length - _data.length;

            // Add new rows with null values for all existing columns
            for (int i = 0; i < additionalRows; i++) {
              // Create a new growable list with nulls for each column
              List<dynamic> newRow =
                  List<dynamic>.filled(_columns.length, null, growable: true);
              _data.add(newRow);

              // Also extend the index
              if (index.isNotEmpty) {
                // If the last index is numeric, continue the sequence
                if (index.last is int) {
                  index.add(index.last + 1);
                } else {
                  // Otherwise just use the row number
                  index.add(_data.length - 1);
                }
              }
            }
          }

          // Add the new column
          _columns.add(key);

          // Add the new column data to each row
          for (int i = 0; i < _data.length; i++) {
            _data[i].add(i < data.length ? data[i] : null);
          }
        }
      }
    }
    // Handle unsupported key types
    else if (key is List || key is Series) {
      throw ArgumentError('List and Series keys are not yet supported');
    } else {
      throw ArgumentError(
          'Key must be an integer (for row) or string (for column)');
    }
  }

  // Helper method to check if an index is the default numeric index
  bool _isDefaultNumericIndex(List<dynamic> idx) {
    if (idx.isEmpty) return true;

    for (int i = 0; i < idx.length; i++) {
      if (idx[i] != i) return false;
    }
    return true;
  }

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName != Symbol('[]') &&
        _columns.contains(invocation.memberName.toString())) {
      return this[invocation.memberName.toString()];
    }
    super.noSuchMethod(invocation);
  }

  @override
  String toString({int columnSpacing = 2}) {
    // Calculate column widths
    List<int> columnWidths = [];

    for (var i = 0; i < _columns.length; i++) {
      int maxColumnWidth = _columns[i].toString().length;
      for (var row in _data) {
        int cellWidth = row[i].toString().length;
        if (cellWidth > maxColumnWidth) {
          maxColumnWidth = cellWidth;
        }
      }
      columnWidths.add(maxColumnWidth);
    }

    // Calculate the maximum width needed for row headers
    int rowHeaderWidth = 0;
    for (var header in index) {
      int headerWidth = header.toString().length;
      if (headerWidth > rowHeaderWidth) {
        rowHeaderWidth = headerWidth;
      }
    }

    // Ensure row header width is at least as wide as the row index
    rowHeaderWidth = max(rowHeaderWidth, _data.length.toString().length);

    // Add spacing to row header width
    rowHeaderWidth += columnSpacing;

    // Construct the table string
    StringBuffer buffer = StringBuffer();

    // Add index header (empty space for row header column)
    buffer.write(' '.padRight(rowHeaderWidth));

    // Add column headers
    for (var i = 0; i < _columns.length; i++) {
      buffer.write(
          _columns[i].toString().padRight(columnWidths[i] + columnSpacing));
    }

    buffer.writeln();

    // Add data rows
    for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
      var row = _data[rowIndex];

      // Add row header with proper padding
      buffer.write(index[rowIndex].toString().padRight(rowHeaderWidth));

      // Add row data
      for (var i = 0; i < row.length; i++) {
        buffer
            .write(row[i].toString().padRight(columnWidths[i] + columnSpacing));
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Access parts of the DataFrame by integer position.
  DataFrameILocAccessor get iloc => DataFrameILocAccessor(this);

  /// Access parts of the DataFrame by label.
  DataFrameLocAccessor get loc => DataFrameLocAccessor(this);
}
