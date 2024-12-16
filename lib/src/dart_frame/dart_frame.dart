part of '../../dartframe.dart';

/// A class representing a DataFrame, which is a 2-dimensional labeled data structure
/// with columns of potentially different types.
class DataFrame {
  List<dynamic> _columns = List.empty(growable: true);
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
      _data = _data.map((row) => row.map(_cleanData).toList()).toList();
    }
  }

  /// Constructs a DataFrame with the provided column names and data.
  ///
  /// - The [columns] parameter specifies the names of the columns in the DataFrame.
  ///
  /// - The [data] parameter specifies the actual data in the DataFrame, organized as a
  /// list of rows, where each row is represented as a list of values corresponding to
  /// the columns.
  ///
  /// Example:
  /// ```dart
  /// var columnNames = ['Name', 'Age', 'City'];
  /// var data = [
  ///   ['Alice', 30, 'New York'],
  ///   ['Bob', 25, 'Los Angeles'],
  ///   ['Charlie', 35, 'Chicago'],
  /// ];
  /// var df = DataFrame(columns: columnNames, data: data);
  /// ```
  DataFrame(
      {List<dynamic> columns = const [],
      List<List<dynamic>> data = const [],
      this.allowFlexibleColumns = false,
      this.replaceMissingValueWith,
      List<dynamic> missingDataIndicator = const [],
      bool formatData = false})
      : _missingDataIndicator = missingDataIndicator,
        _data = data,
        _columns = columns.isEmpty && data.isNotEmpty
            ? List.generate(data[0].length, (index) => 'Column${index + 1}')
            : columns {
    // ... validation based on allowFlexibleColumns ...
    if (formatData) {
      // Clean and convert data
      _data = data.map((row) => row.map(_cleanData).toList()).toList();
    }
  }

  dynamic _cleanData(dynamic value) {
    List<String> commonDateFormats = [
      'yyyy-MM-dd',
      'MM/dd/yyyy',
      'dd-MMM-yyyy'
    ]; // Customize as needed

    if (value == null || value == '' || _missingDataIndicator.contains(value)) {
      return replaceMissingValueWith; // Handle null values explicitly
    }

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
  /// var df = DataFrame.fromCSV(csv: csvData, delimiter: ',', hasHeader: true);
  /// ```
  factory DataFrame.fromCSV({
    String? csv,
    String delimiter = ',',
    String? inputFilePath,
    bool hasHeader = true,
    bool allowFlexibleColumns = false,
    dynamic replaceMissingValueWith,
    bool formatData = false,
    List missingDataIndicator = const [],
  }) {
    if (csv == null && inputFilePath != null) {
      // Read file
      fileIO.readFromFile(inputFilePath).then((data) {
        csv = data;
      });
    } else if (csv == null) {
      throw ArgumentError('Either csv or inputFilePath must be provided.');
    }

    List<List> rows = csv!
        .trim()
        .split('\n')
        .map((row) => row.split(delimiter).map((value) => value).toList())
        .toList();

    // Extract column names from the first line
    final columnNames =
        hasHeader ? rows[0] : List.generate(rows[0].length, (i) => 'Column $i');

    return DataFrame._(
      columnNames,
      rows.sublist(1),
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
  /// var df = DataFrame.fromJson(jsonString: jsonData);
  /// ```
  factory DataFrame.fromJson({
    String? jsonString,
    String? inputFilePath,
    bool allowFlexibleColumns = false,
    dynamic replaceMissingValueWith,
    bool formatData = false,
    List missingDataIndicator = const [],
  }) {
    if (jsonString == null && inputFilePath != null) {
      // Read file
      fileIO.readFromFile(inputFilePath).then((data) {
        jsonString = data;
      });
    } else if (jsonString == null) {
      throw ArgumentError(
          'Either jsonString or inputFilePath must be provided.');
    }

    final jsonData = jsonDecode(jsonString!) as List;

    // Extract column names from the first object
    final columnNames = jsonData[0].keys.toList();

    // Extract data from all objects
    final data = jsonData
        .map((obj) => columnNames.map((name) => obj[name]).toList())
        .toList();

    return DataFrame._(
      columnNames,
      data,
      replaceMissingValueWith: replaceMissingValueWith,
      allowFlexibleColumns: allowFlexibleColumns,
      formatData: formatData,
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
      columns: columns,
      data: data,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: missingDataIndicator,
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

    // Construct the table string
    StringBuffer buffer = StringBuffer();

    // Add index header
    buffer.write(' '.padRight(_data.length.toString().length +
        columnSpacing)); // Space for the index column

    // Add column headers (rest of the header is same as before)
    for (var i = 0; i < _columns.length; i++) {
      buffer.write(
          _columns[i].toString().padRight(columnWidths[i] + columnSpacing));
    }
    buffer.writeln();

    // Add data rows
    var indexWidth = _data.length.toString().length;
    for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
      var row = _data[rowIndex];

      // Add row index
      buffer.write(rowIndex.toString().padRight(indexWidth + columnSpacing));

      // Add row data
      for (var i = 0; i < row.length; i++) {
        buffer
            .write(row[i].toString().padRight(columnWidths[i] + columnSpacing));
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
