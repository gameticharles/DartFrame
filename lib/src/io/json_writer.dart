import 'dart:async';
import 'dart:convert';
import '../data_frame/data_frame.dart';
import '../file_helper/file_io.dart';
import 'writers.dart';

/// Writer for JSON files with multiple output formats.
///
/// This class provides functionality to write DataFrames to JSON files with
/// various orientations (records, index, columns, values) similar to pandas.
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
/// - **values**: 2D array of values only
///   ```json
///   [[val1, val2], [val3, val4]]
///   ```
///
/// ## Example
/// ```dart
/// // Records format (default)
/// await JsonWriter().write(df, 'output.json');
/// // [{"col1": val1, "col2": val2}, ...]
///
/// // Columns format
/// await JsonWriter().write(df, 'output.json', options: {
///   'orient': 'columns',
/// });
/// // {"col1": [val1, val2, ...], "col2": [...]}
///
/// // With indentation (pretty-print)
/// await JsonWriter().write(df, 'output.json', options: {
///   'orient': 'records',
///   'indent': 2,
/// });
///
/// // Index format with row index
/// await JsonWriter().write(df, 'output.json', options: {
///   'orient': 'index',
/// });
/// ```
///
/// ## Options
/// - `orient` (String): JSON orientation format (default: 'records')
/// - `include_index` (bool): Include row index in output (default: false)
/// - `indent` (int?): Number of spaces for indentation (default: no indentation)
///
/// See also:
/// - [FileWriter.writeJson] for a convenient wrapper method
/// - [JsonReader] for reading JSON files (when implemented)
class JsonWriter implements DataWriter {
  @override
  Future<void> write(DataFrame df, String path,
      {Map<String, dynamic>? options}) async {
    try {
      final content = _dataFrameToJsonContent(df, options);
      final fileIO = FileIO();
      await fileIO.saveToFile(path, content);
    } catch (e) {
      throw JsonWriteError('Failed to write JSON file: $e');
    }
  }

  /// Converts a DataFrame to JSON content string.
  ///
  /// This internal method handles the conversion of DataFrame data to JSON format
  /// based on the specified orientation. It supports multiple output formats
  /// and optional pretty-printing.
  ///
  /// Throws [JsonWriteError] if conversion fails.
  String _dataFrameToJsonContent(DataFrame df, Map<String, dynamic>? options) {
    final orient = options?['orient'] as String? ?? 'records';
    final includeIndex = options?['include_index'] as bool? ?? false;
    final indent = options?['indent'] as int?;

    dynamic jsonData;

    switch (orient) {
      case 'records':
        jsonData = _toRecordsFormat(df, includeIndex);
        break;
      case 'index':
        jsonData = _toIndexFormat(df);
        break;
      case 'columns':
        jsonData = _toColumnsFormat(df);
        break;
      case 'values':
        jsonData = _toValuesFormat(df);
        break;
      default:
        jsonData = _toRecordsFormat(df, includeIndex);
    }

    final encoder =
        indent != null ? JsonEncoder.withIndent(' ' * indent) : JsonEncoder();

    return encoder.convert(jsonData);
  }

  /// Converts DataFrame to records format (list of objects).
  ///
  /// Each row becomes an object with column names as keys.
  /// Example: [{"col1": val1, "col2": val2}, ...]
  List<Map<String, dynamic>> _toRecordsFormat(DataFrame df, bool includeIndex) {
    final records = <Map<String, dynamic>>[];
    final columns = df.columns;

    for (int i = 0; i < df.shape.rows; i++) {
      final record = <String, dynamic>{};

      if (includeIndex) {
        record['index'] = i;
      }

      for (final col in columns) {
        record[col] = df[col]![i];
      }

      records.add(record);
    }

    return records;
  }

  /// Converts DataFrame to index format (object with index keys).
  ///
  /// Each row index becomes a key with row data as value.
  /// Example: {"0": {"col1": val1, "col2": val2}, "1": {...}}
  Map<String, Map<String, dynamic>> _toIndexFormat(DataFrame df) {
    final result = <String, Map<String, dynamic>>{};
    final columns = df.columns;

    for (int i = 0; i < df.shape.rows; i++) {
      final row = <String, dynamic>{};
      for (final col in columns) {
        row[col] = df[col]![i];
      }
      result[i.toString()] = row;
    }

    return result;
  }

  /// Converts DataFrame to columns format (object with column keys).
  ///
  /// Each column becomes a key with array of values.
  /// Example: {"col1": [val1, val2, ...], "col2": [...]}
  Map<String, List<dynamic>> _toColumnsFormat(DataFrame df) {
    final result = <String, List<dynamic>>{};
    final columns = df.columns;

    for (final col in columns) {
      result[col] = df[col]!.toList();
    }

    return result;
  }

  /// Converts DataFrame to values format (2D array).
  ///
  /// Returns only the values as a 2D array, no column names or indices.
  /// Example: [[val1, val2], [val3, val4], ...]
  List<List<dynamic>> _toValuesFormat(DataFrame df) {
    final result = <List<dynamic>>[];
    final columns = df.columns;

    for (int i = 0; i < df.shape.rows; i++) {
      final row = columns.map((col) => df[col]![i]).toList();
      result.add(row);
    }

    return result;
  }
}

/// Exception thrown when JSON writing fails.
///
/// This error is thrown when:
/// - The JSON file cannot be written to disk
/// - DataFrame conversion to JSON format fails
/// - Invalid orientation is specified
/// - File system errors occur during writing
///
/// Example:
/// ```dart
/// try {
///   await JsonWriter().write(df, 'output.json');
/// } on JsonWriteError catch (e) {
///   print('Failed to write JSON: $e');
/// }
/// ```
class JsonWriteError extends Error {
  final String message;
  JsonWriteError(this.message);

  @override
  String toString() => 'JsonWriteError: $message';
}
