import 'dart:async';
import 'package:csv/csv.dart';
import '../data_frame/data_frame.dart';
import '../file_helper/file_io.dart';
import 'readers.dart';

/// Reader for CSV (Comma-Separated Values) files using the csv package.
///
/// This class provides functionality to read CSV files and convert them into
/// DataFrames. It supports various CSV formats with customizable delimiters,
/// text qualifiers, and parsing options.
///
/// ## Features
/// - Custom field delimiters (comma, semicolon, tab, etc.)
/// - Custom text delimiters for quoted fields
/// - Header row detection and custom column names
/// - Skip rows functionality
/// - Limit maximum rows to read
/// - Automatic type inference
///
/// ## Example
/// ```dart
/// // Basic CSV reading
/// final df = await CsvReader().read('data.csv');
///
/// // With custom options
/// final df = await CsvReader().read('data.csv', options: {
///   'fieldDelimiter': ';',
///   'hasHeader': true,
///   'skipRows': 1,
///   'maxRows': 100,
/// });
/// ```
///
/// ## Options
/// - `fieldDelimiter` (String): Field separator character (default: ',')
/// - `textDelimiter` (String): Text quote character (default: '"')
/// - `textEndDelimiter` (String?): Ending text delimiter (default: same as textDelimiter)
/// - `eol` (String?): Line ending character (default: '\n')
/// - `hasHeader` (bool): Whether first row is header (default: true)
/// - `skipRows` (int): Number of rows to skip (default: 0)
/// - `maxRows` (int?): Maximum rows to read (default: all)
/// - `columnNames` (`List<String>?`): Custom column names when no header
///
/// See also:
/// - `[CsvFileWriter]` for writing CSV files
/// - `[FileReader.readCsv]` for a convenient wrapper method
class CsvReader implements DataReader {
  @override
  Future<DataFrame> read(String path, {Map<String, dynamic>? options}) async {
    try {
      final fileIO = FileIO();
      final content = await fileIO.readFromFile(path);

      return parseCsvContent(content, options);
    } catch (e) {
      throw CsvReadError('Failed to read CSV file: $e');
    }
  }

  /// Parses CSV content string into a DataFrame.
  ///
  /// This method handles the actual CSV parsing logic using the
  /// csv package's CsvToListConverter. It processes options, extracts headers,
  /// and builds the DataFrame structure.
  ///
  /// Throws [CsvReadError] if parsing fails.
  DataFrame parseCsvContent(String content, Map<String, dynamic>? options) {
    try {
      // Parse options
      final fieldDelimiter = options?['fieldDelimiter'] as String? ?? ',';
      final textDelimiter = options?['textDelimiter'] as String? ?? '"';
      final textEndDelimiter = options?['textEndDelimiter'] as String?;
      final eol = options?['eol'] as String?;
      final hasHeader = options?['hasHeader'] as bool? ?? true;
      final skipRows = options?['skipRows'] as int? ?? 0;
      final maxRows = options?['maxRows'] as int?;
      final columnNames = options?['columnNames'] as List<String>?;

      // Configure CSV converter
      // Note: eol must be explicitly set for proper parsing
      final converter = CsvToListConverter(
        fieldDelimiter: fieldDelimiter,
        textDelimiter: textDelimiter,
        textEndDelimiter: textEndDelimiter,
        eol: eol ?? '\n',
      );

      // Parse CSV
      final rows = converter.convert(content);

      if (rows.isEmpty) {
        throw CsvReadError('Empty CSV file');
      }

      // Skip rows if specified
      final dataRows = rows.skip(skipRows).toList();
      if (dataRows.isEmpty) {
        throw CsvReadError('No data after skipping rows');
      }

      // Extract headers
      List<String> headers;
      int dataStartIndex;

      if (hasHeader) {
        headers = dataRows[0].map((e) => e.toString()).toList();
        dataStartIndex = 1;
      } else if (columnNames != null) {
        headers = columnNames;
        dataStartIndex = 0;
      } else {
        // Generate column names
        final numCols = dataRows[0].length;
        headers = List.generate(numCols, (i) => 'col_$i');
        dataStartIndex = 0;
      }

      // Limit rows if specified
      final processRows = maxRows != null
          ? dataRows.skip(dataStartIndex).take(maxRows).toList()
          : dataRows.skip(dataStartIndex).toList();

      // Build column data
      final data = <String, List<dynamic>>{};
      for (final header in headers) {
        data[header] = <dynamic>[];
      }

      // Fill data
      for (final row in processRows) {
        for (int i = 0; i < headers.length; i++) {
          final value = i < row.length ? row[i] : null;
          data[headers[i]]!.add(value);
        }
      }

      return DataFrame.fromMap(data);
    } catch (e) {
      throw CsvReadError('Failed to parse CSV content: $e');
    }
  }
}

/// Exception thrown when CSV reading or parsing fails.
///
/// This error is thrown when:
/// - The CSV file cannot be read from disk
/// - The CSV content is empty or invalid
/// - Parsing fails due to malformed CSV data
/// - No data remains after skipping rows
///
/// Example:
/// ```dart
/// try {
///   final df = await CsvReader().read('data.csv');
/// } on CsvReadError catch (e) {
///   print('Failed to read CSV: $e');
/// }
/// ```
class CsvReadError extends Error {
  final String message;
  CsvReadError(this.message);

  @override
  String toString() => 'CsvReadError: $message';
}
