import 'dart:async';
import 'dart:convert';
import '../data_frame/data_frame.dart';
import '../file_helper/file_io.dart';
import 'readers.dart';

/// Reader for JSON files with support for multiple orientations.
///
/// This class provides functionality to read JSON files and convert them into
/// DataFrames. It supports various JSON formats (orientations) similar to pandas.
///
/// ## Supported Orientations
/// - **records**: List of objects (one per row)
///   ```json
///   [{"col1": val1, "col2": val2}, {"col1": val3, "col2": val4}]
///   ```
/// - **index**: Object with index keys and row objects
///   ```json
///   {"0": {"col1": val1, "col2": val2}, "1": {"col1": val3, "col2": val4}}
///   ```
/// - **columns**: Object with column keys and value arrays
///   ```json
///   {"col1": [val1, val3], "col2": [val2, val4]}
///   ```
/// - **values**: 2D array of values only (requires column names)
///   ```json
///   [[val1, val2], [val3, val4]]
///   ```
///
/// ## Example
/// ```dart
/// // Read records format (default)
/// final df = await JsonReader().read('data.json');
///
/// // Read with specific orientation
/// final df = await JsonReader().read('data.json', options: {
///   'orient': 'columns',
/// });
///
/// // Read values format with column names
/// final df = await JsonReader().read('data.json', options: {
///   'orient': 'values',
///   'columns': ['col1', 'col2', 'col3'],
/// });
/// ```
///
/// ## Options
/// - `orient` (String): JSON orientation format (default: 'records')
///   - 'records': List of row objects
///   - 'index': Object with index keys
///   - 'columns': Object with column arrays
///   - 'values': 2D array of values
/// - `columns` (`List<String>?`): Column names for 'values' orientation
///
/// See also:
/// - [JsonWriter] for writing JSON files
/// - [FileReader.read] for auto-detecting file format
class JsonReader implements DataReader {
  @override
  Future<DataFrame> read(String path, {Map<String, dynamic>? options}) async {
    try {
      final fileIO = FileIO();
      final content = await fileIO.readFromFile(path);

      return parseJsonContent(content, options);
    } catch (e) {
      throw JsonReadError('Failed to read JSON file: $e');
    }
  }

  /// Parses JSON content string into a DataFrame.
  ///
  /// This method handles the conversion of JSON data to DataFrame
  /// based on the specified orientation.
  ///
  /// Throws [JsonReadError] if parsing fails.
  DataFrame parseJsonContent(String content, Map<String, dynamic>? options) {
    try {
      final orient = options?['orient'] as String? ?? 'records';
      final dynamic jsonData = json.decode(content);

      switch (orient) {
        case 'records':
          return _fromRecordsFormat(jsonData);
        case 'index':
          return _fromIndexFormat(jsonData);
        case 'columns':
          return _fromColumnsFormat(jsonData);
        case 'values':
          final columns = options?['columns'] as List<String>?;
          return _fromValuesFormat(jsonData, columns);
        default:
          throw JsonReadError('Unsupported orientation: $orient');
      }
    } catch (e) {
      if (e is JsonReadError) rethrow;
      throw JsonReadError('Failed to parse JSON content: $e');
    }
  }

  /// Converts records format to DataFrame.
  ///
  /// Expected format: [{"col1": val1, "col2": val2}, ...]
  DataFrame _fromRecordsFormat(dynamic jsonData) {
    if (jsonData is! List) {
      throw JsonReadError(
          'Records format expects a List, got ${jsonData.runtimeType}');
    }

    if (jsonData.isEmpty) {
      return DataFrame.fromMap({});
    }

    final columns = <String, List<dynamic>>{};

    for (final record in jsonData) {
      if (record is! Map) {
        throw JsonReadError(
            'Each record must be a Map, got ${record.runtimeType}');
      }

      for (final entry in record.entries) {
        final key = entry.key.toString();
        columns.putIfAbsent(key, () => []);
        columns[key]!.add(entry.value);
      }
    }

    // Ensure all columns have the same length
    final maxLength =
        columns.values.map((v) => v.length).reduce((a, b) => a > b ? a : b);
    for (final col in columns.keys) {
      while (columns[col]!.length < maxLength) {
        columns[col]!.add(null);
      }
    }

    return DataFrame.fromMap(columns);
  }

  /// Converts index format to DataFrame.
  ///
  /// Expected format: {"0": {"col1": val1, "col2": val2}, "1": {...}}
  DataFrame _fromIndexFormat(dynamic jsonData) {
    if (jsonData is! Map) {
      throw JsonReadError(
          'Index format expects a Map, got ${jsonData.runtimeType}');
    }

    if (jsonData.isEmpty) {
      return DataFrame.fromMap({});
    }

    final columns = <String, List<dynamic>>{};
    final sortedKeys = jsonData.keys.toList()..sort();

    for (final indexKey in sortedKeys) {
      final row = jsonData[indexKey];
      if (row is! Map) {
        throw JsonReadError('Each row must be a Map, got ${row.runtimeType}');
      }

      for (final entry in row.entries) {
        final key = entry.key.toString();
        columns.putIfAbsent(key, () => []);
        columns[key]!.add(entry.value);
      }
    }

    return DataFrame.fromMap(columns);
  }

  /// Converts columns format to DataFrame.
  ///
  /// Expected format: {"col1": [val1, val2, ...], "col2": [...]}
  DataFrame _fromColumnsFormat(dynamic jsonData) {
    if (jsonData is! Map) {
      throw JsonReadError(
          'Columns format expects a Map, got ${jsonData.runtimeType}');
    }

    if (jsonData.isEmpty) {
      return DataFrame.fromMap({});
    }

    final columns = <String, List<dynamic>>{};

    for (final entry in jsonData.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is! List) {
        throw JsonReadError(
            'Column "$key" must be a List, got ${value.runtimeType}');
      }

      columns[key] = List<dynamic>.from(value);
    }

    return DataFrame.fromMap(columns);
  }

  /// Converts values format to DataFrame.
  ///
  /// Expected format: [[val1, val2], [val3, val4], ...]
  /// Requires column names to be provided in options.
  DataFrame _fromValuesFormat(dynamic jsonData, List<String>? columnNames) {
    if (jsonData is! List) {
      throw JsonReadError(
          'Values format expects a List, got ${jsonData.runtimeType}');
    }

    if (jsonData.isEmpty) {
      return DataFrame.fromMap({});
    }

    // Determine number of columns from first row
    final firstRow = jsonData[0];
    if (firstRow is! List) {
      throw JsonReadError(
          'Each row must be a List, got ${firstRow.runtimeType}');
    }

    final numCols = firstRow.length;

    // Generate or validate column names
    final cols = columnNames ?? List.generate(numCols, (i) => 'col_$i');

    if (cols.length != numCols) {
      throw JsonReadError(
          'Number of column names (${cols.length}) does not match number of columns ($numCols)');
    }

    // Build column data
    final columns = <String, List<dynamic>>{};
    for (final col in cols) {
      columns[col] = [];
    }

    // Fill data
    for (final row in jsonData) {
      if (row is! List) {
        throw JsonReadError('Each row must be a List, got ${row.runtimeType}');
      }

      for (int i = 0; i < cols.length; i++) {
        final value = i < row.length ? row[i] : null;
        columns[cols[i]]!.add(value);
      }
    }

    return DataFrame.fromMap(columns);
  }
}

/// Exception thrown when JSON reading fails.
///
/// This error is thrown when:
/// - The JSON file cannot be read from disk
/// - The JSON content is invalid or malformed
/// - The JSON structure is not compatible with DataFrame
/// - The feature is not yet implemented
///
/// Example:
/// ```dart
/// try {
///   final df = await JsonReader().read('data.json');
/// } on JsonReadError catch (e) {
///   print('Failed to read JSON: $e');
/// }
/// ```
class JsonReadError extends Error {
  final String message;
  JsonReadError(this.message);

  @override
  String toString() => 'JsonReadError: $message';
}
