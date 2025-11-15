import 'dart:async';
import 'package:csv/csv.dart';
import '../data_frame/data_frame.dart';
import '../file_helper/file_io.dart';
import 'writers.dart';

/// Writer for CSV (Comma-Separated Values) files using the csv package.
///
/// This class provides functionality to write DataFrames to CSV files with
/// customizable formatting options. It uses the csv package's ListToCsvConverter
/// for proper CSV encoding and escaping.
///
/// ## Features
/// - Custom field delimiters (comma, semicolon, tab, etc.)
/// - Custom text delimiters for quoted fields
/// - Optional header row
/// - Optional row index column
/// - Custom line endings (LF, CRLF)
/// - Proper escaping of special characters
///
/// ## Example
/// ```dart
/// // Basic CSV writing
/// await CsvFileWriter().write(df, 'output.csv');
///
/// // With custom options
/// await CsvFileWriter().write(df, 'output.csv', options: {
///   'fieldDelimiter': ';',
///   'includeHeader': true,
///   'includeIndex': true,
///   'eol': '\r\n',
/// });
/// ```
///
/// ## Options
/// - `fieldDelimiter` (String): Field separator character (default: ',')
/// - `textDelimiter` (String): Text quote character (default: '"')
/// - `textEndDelimiter` (String?): Ending text delimiter (default: same as textDelimiter)
/// - `eol` (String?): Line ending character (default: '\n')
/// - `includeHeader` (bool): Include header row (default: true)
/// - `includeIndex` (bool): Include row index column (default: false)
///
/// See also:
/// - [CsvReader] for reading CSV files
/// - [FileWriter.writeCsv] for a convenient wrapper method
class CsvFileWriter implements DataWriter {
  @override
  Future<void> write(DataFrame df, String path,
      {Map<String, dynamic>? options}) async {
    try {
      final content = _dataFrameToCsvContent(df, options);
      final fileIO = FileIO();
      await fileIO.saveToFile(path, content);
    } catch (e) {
      throw CsvWriteError('Failed to write CSV file: $e');
    }
  }

  /// Converts a DataFrame to CSV content string.
  ///
  /// This internal method handles the conversion of DataFrame data to CSV format
  /// using the csv package's ListToCsvConverter. It processes options, builds
  /// the row structure, and applies proper CSV encoding.
  ///
  /// Throws [CsvWriteError] if conversion fails.
  String _dataFrameToCsvContent(DataFrame df, Map<String, dynamic>? options) {
    try {
      // Parse options
      final fieldDelimiter = options?['fieldDelimiter'] as String? ?? ',';
      final textDelimiter = options?['textDelimiter'] as String? ?? '"';
      final textEndDelimiter = options?['textEndDelimiter'] as String?;
      final eol = options?['eol'] as String?;
      final includeHeader = options?['includeHeader'] as bool? ?? true;
      final includeIndex = options?['includeIndex'] as bool? ?? false;

      // Configure CSV converter
      final converter = ListToCsvConverter(
        fieldDelimiter: fieldDelimiter,
        textDelimiter: textDelimiter,
        textEndDelimiter: textEndDelimiter ?? textDelimiter,
        eol: eol ?? '\n',
      );

      final rows = <List<dynamic>>[];
      final columns = df.columns;

      // Add header row
      if (includeHeader) {
        final headerRow = <dynamic>[];
        if (includeIndex) {
          headerRow.add('index');
        }
        headerRow.addAll(columns);
        rows.add(headerRow);
      }

      // Add data rows
      for (int i = 0; i < df.shape.rows; i++) {
        final row = <dynamic>[];
        if (includeIndex) {
          row.add(i);
        }
        for (final col in columns) {
          row.add(df[col]![i]);
        }
        rows.add(row);
      }

      return converter.convert(rows);
    } catch (e) {
      throw CsvWriteError('Failed to convert DataFrame to CSV: $e');
    }
  }
}

/// Exception thrown when CSV writing or conversion fails.
///
/// This error is thrown when:
/// - The CSV file cannot be written to disk
/// - DataFrame conversion to CSV format fails
/// - Invalid options are provided
/// - File system errors occur during writing
///
/// Example:
/// ```dart
/// try {
///   await CsvFileWriter().write(df, 'output.csv');
/// } on CsvWriteError catch (e) {
///   print('Failed to write CSV: $e');
/// }
/// ```
class CsvWriteError extends Error {
  final String message;
  CsvWriteError(this.message);

  @override
  String toString() => 'CsvWriteError: $message';
}
