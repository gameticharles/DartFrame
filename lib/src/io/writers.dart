import 'dart:async';
import '../data_frame/data_frame.dart';
import 'csv_writer.dart';
import 'excel_writer.dart';
import 'parquet_writer.dart';
import 'json_writer.dart';

/// Abstract base class for data writers.
///
/// This interface defines the contract that all file format writers must implement.
/// Each writer is responsible for converting a DataFrame to a specific file format
/// and writing it to disk.
///
/// Implementations include:
/// - [CsvFileWriter] for CSV files
/// - [ExcelFileWriter] for Excel files
/// - [JsonWriter] for JSON files
/// - [ParquetWriter] for Parquet files (basic implementation)
abstract class DataWriter {
  /// Writes a DataFrame to the specified path.
  ///
  /// ## Parameters
  /// - `df`: The DataFrame to write
  /// - `path`: Path where the file will be saved
  /// - `options`: Format-specific options for writing
  ///
  /// ## Returns
  /// A Future that completes when the file has been written.
  ///
  /// Throws format-specific errors if writing fails.
  Future<void> write(DataFrame df, String path,
      {Map<String, dynamic>? options});
}

// Format-specific writers are now in separate files:
// - parquet_writer.dart - Parquet file writer (placeholder)
// - excel_writer.dart - Excel file writer using excel package
// - csv_writer.dart - CSV file writer using csv package
// - json_writer.dart - JSON file writer with multiple orientations

/// Generic file writer that automatically detects and handles multiple file formats.
///
/// FileWriter provides a unified interface for writing DataFrames to various file
/// formats. It automatically detects the file format based on the file extension
/// and uses the appropriate writer implementation.
///
/// ## Supported Formats
/// - **CSV** (.csv): Comma-separated values using [CsvFileWriter]
/// - **Excel** (.xlsx, .xls): Excel workbooks using [ExcelFileWriter]
/// - **JSON** (.json): JSON format using [JsonWriter]
/// - **Parquet** (.parquet, .pq): Parquet columnar format (basic implementation)
///
/// ## Features
/// - Automatic format detection by file extension
/// - Format-specific options support
/// - Convenient wrapper methods for each format
/// - Multi-sheet Excel support
/// - Multiple JSON orientations
///
/// ## Example
/// ```dart
/// // Auto-detect format
/// await FileWriter.write(df, 'output.csv');
///
/// // Format-specific methods
/// await FileWriter.writeCsv(df, 'output.csv',
///   fieldDelimiter: ';',
///   includeHeader: true,
/// );
///
/// await FileWriter.writeExcel(df, 'output.xlsx',
///   sheetName: 'MyData',
///   includeIndex: true,
/// );
///
/// // Write multiple Excel sheets
/// await FileWriter.writeExcelSheets({
///   'Sales': salesDf,
///   'Inventory': inventoryDf,
/// }, 'report.xlsx');
///
/// await FileWriter.writeJson(df, 'output.json',
///   orient: 'records',
///   indent: 2,
/// );
/// ```
///
/// See also:
/// - [FileReader] for reading DataFrames from files
/// - [CsvFileWriter], [ExcelFileWriter], [JsonWriter] for format-specific writers
class FileWriter {
  static final Map<String, DataWriter> _writers = {
    '.parquet': ParquetWriter(),
    '.pq': ParquetWriter(),
    '.xlsx': ExcelFileWriter(),
    '.xls': ExcelFileWriter(),
    '.csv': CsvFileWriter(),
    '.json': JsonWriter(),
  };

  /// Writes a DataFrame to a file, automatically detecting format by extension.
  ///
  /// This is the most convenient method for writing files when you don't need
  /// format-specific options. The file format is determined by the file extension.
  ///
  /// ## Supported Extensions
  /// - .csv → CSV writer
  /// - .xlsx, .xls → Excel writer
  /// - .json → JSON writer
  /// - .parquet, .pq → Parquet writer
  ///
  /// ## Parameters
  /// - `df`: The DataFrame to write
  /// - `path`: Path where the file will be saved
  /// - `options`: Optional format-specific options
  ///
  /// ## Example
  /// ```dart
  /// // Write CSV
  /// await FileWriter.write(df, 'output.csv');
  ///
  /// // Write Excel
  /// await FileWriter.write(df, 'output.xlsx');
  ///
  /// // Write with options
  /// await FileWriter.write(df, 'output.csv', options: {
  ///   'fieldDelimiter': ';',
  ///   'includeHeader': true,
  /// });
  /// ```
  ///
  /// Throws [UnsupportedWriteFormatError] if the file extension is not recognized.
  /// Throws format-specific errors if writing fails.
  static Future<void> write(DataFrame df, String path,
      {Map<String, dynamic>? options}) async {
    final extension = _getFileExtension(path).toLowerCase();
    final writer = _writers[extension];

    if (writer == null) {
      throw UnsupportedWriteFormatError(
          'Unsupported file format for writing: $extension');
    }

    await writer.write(df, path, options: options);
  }

  /// Writes a DataFrame to a Parquet file.
  ///
  /// **Note:** This is a basic implementation. For production use with real
  /// Parquet files, integrate a proper Parquet library.
  ///
  /// ## Parameters
  /// - `df`: The DataFrame to write
  /// - `path`: Path where the file will be saved
  /// - `compression`: Compression method (default: 'none')
  /// - `includeIndex`: Include row index column (default: false)
  /// - `options`: Additional writing options
  ///
  /// Throws [ParquetWriteError] if writing fails.
  static Future<void> writeParquet(DataFrame df, String path,
      {String compression = 'none',
      bool includeIndex = false,
      Map<String, dynamic>? options}) async {
    final mergedOptions = <String, dynamic>{
      'compression': compression,
      'include_index': includeIndex,
      ...?options,
    };

    await ParquetWriter().write(df, path, options: mergedOptions);
  }

  /// Writes a DataFrame to an Excel file (.xlsx).
  ///
  /// Creates an Excel workbook with a single sheet containing the DataFrame data.
  /// Data types are preserved (numbers, dates, booleans).
  ///
  /// ## Parameters
  /// - `df`: The DataFrame to write
  /// - `path`: Path where the Excel file will be saved
  /// - `sheetName`: Name of the sheet to create (default: 'Sheet1')
  /// - `includeHeader`: Include header row (default: true)
  /// - `includeIndex`: Include row index column (default: false)
  /// - `options`: Additional writing options
  ///
  /// ## Example
  /// ```dart
  /// // Basic write
  /// await FileWriter.writeExcel(df, 'output.xlsx');
  ///
  /// // With custom sheet name
  /// await FileWriter.writeExcel(df, 'output.xlsx',
  ///   sheetName: 'MyData',
  /// );
  ///
  /// // With index column
  /// await FileWriter.writeExcel(df, 'output.xlsx',
  ///   sheetName: 'Results',
  ///   includeIndex: true,
  /// );
  /// ```
  ///
  /// Throws [ExcelWriteError] if writing fails.
  ///
  /// See also:
  /// - [writeExcelSheets] for writing multiple sheets
  static Future<void> writeExcel(DataFrame df, String path,
      {String sheetName = 'Sheet1',
      bool includeHeader = true,
      bool includeIndex = false,
      Map<String, dynamic>? options}) async {
    final mergedOptions = <String, dynamic>{
      'sheetName': sheetName,
      'includeHeader': includeHeader,
      'includeIndex': includeIndex,
      ...?options,
    };

    await ExcelFileWriter().write(df, path, options: mergedOptions);
  }

  /// Writes multiple DataFrames to different sheets in a single Excel file
  ///
  /// Takes a Map where keys are sheet names and values are DataFrames.
  /// This allows creating an Excel workbook with multiple sheets in one operation.
  ///
  /// Example:
  /// ```dart
  /// final sheets = {
  ///   'Sales': salesDf,
  ///   'Inventory': inventoryDf,
  ///   'Summary': summaryDf,
  /// };
  /// await FileWriter.writeExcelSheets(sheets, 'report.xlsx');
  /// ```
  static Future<void> writeExcelSheets(
    Map<String, DataFrame> sheets,
    String path, {
    bool includeHeader = true,
    bool includeIndex = false,
    Map<String, dynamic>? options,
  }) async {
    await ExcelFileWriter.writeMultipleSheets(
      sheets,
      path,
      includeHeader: includeHeader,
      includeIndex: includeIndex,
      options: options,
    );
  }

  /// Writes a DataFrame to a CSV (Comma-Separated Values) file.
  ///
  /// Provides full control over CSV formatting with customizable delimiters,
  /// text qualifiers, and output options.
  ///
  /// ## Parameters
  /// - `df`: The DataFrame to write
  /// - `path`: Path where the CSV file will be saved
  /// - `fieldDelimiter`: Field separator character (default: ',')
  /// - `textDelimiter`: Text quote character (default: '"')
  /// - `textEndDelimiter`: Ending text delimiter (default: same as textDelimiter)
  /// - `eol`: Line ending character (default: '\n')
  /// - `includeHeader`: Include header row (default: true)
  /// - `includeIndex`: Include row index column (default: false)
  /// - `options`: Additional writing options
  ///
  /// ## Example
  /// ```dart
  /// // Basic CSV writing
  /// await FileWriter.writeCsv(df, 'output.csv');
  ///
  /// // Semicolon-separated
  /// await FileWriter.writeCsv(df, 'output.csv',
  ///   fieldDelimiter: ';',
  /// );
  ///
  /// // Tab-separated with Windows line endings
  /// await FileWriter.writeCsv(df, 'output.tsv',
  ///   fieldDelimiter: '\t',
  ///   eol: '\r\n',
  /// );
  ///
  /// // With index column
  /// await FileWriter.writeCsv(df, 'output.csv',
  ///   includeIndex: true,
  /// );
  ///
  /// // Without header
  /// await FileWriter.writeCsv(df, 'output.csv',
  ///   includeHeader: false,
  /// );
  /// ```
  ///
  /// Throws [CsvWriteError] if writing fails.
  static Future<void> writeCsv(DataFrame df, String path,
      {String fieldDelimiter = ',',
      String textDelimiter = '"',
      String? textEndDelimiter,
      String? eol,
      bool includeHeader = true,
      bool includeIndex = false,
      Map<String, dynamic>? options}) async {
    final mergedOptions = <String, dynamic>{
      'fieldDelimiter': fieldDelimiter,
      'textDelimiter': textDelimiter,
      if (textEndDelimiter != null) 'textEndDelimiter': textEndDelimiter,
      if (eol != null) 'eol': eol,
      'includeHeader': includeHeader,
      'includeIndex': includeIndex,
      ...?options,
    };

    await CsvFileWriter().write(df, path, options: mergedOptions);
  }

  /// Writes a DataFrame to a JSON file with customizable format.
  ///
  /// Supports multiple JSON orientations similar to pandas, allowing you to
  /// choose the most appropriate format for your use case.
  ///
  /// ## Parameters
  /// - `df`: The DataFrame to write
  /// - `path`: Path where the JSON file will be saved
  /// - `orient`: JSON orientation format (default: 'records')
  ///   - 'records': List of objects (one per row)
  ///   - 'index': Object with index keys and row objects
  ///   - 'columns': Object with column keys and value arrays
  ///   - 'values': 2D array of values only
  /// - `includeIndex`: Include row index in output (default: false)
  /// - `indent`: Number of spaces for indentation (default: no indentation)
  /// - `options`: Additional writing options
  ///
  /// ## Example
  /// ```dart
  /// // Records format (default)
  /// await FileWriter.writeJson(df, 'output.json');
  /// // [{"col1": val1, "col2": val2}, ...]
  ///
  /// // Columns format
  /// await FileWriter.writeJson(df, 'output.json',
  ///   orient: 'columns',
  /// );
  /// // {"col1": [val1, val2, ...], "col2": [...]}
  ///
  /// // Pretty-printed with indentation
  /// await FileWriter.writeJson(df, 'output.json',
  ///   orient: 'records',
  ///   indent: 2,
  /// );
  ///
  /// // Values only (2D array)
  /// await FileWriter.writeJson(df, 'output.json',
  ///   orient: 'values',
  /// );
  /// // [[val1, val2, ...], [val3, val4, ...]]
  /// ```
  ///
  /// Throws [JsonWriteError] if writing fails.
  static Future<void> writeJson(DataFrame df, String path,
      {String orient = 'records',
      bool includeIndex = false,
      int? indent,
      Map<String, dynamic>? options}) async {
    final mergedOptions = <String, dynamic>{
      'orient': orient,
      'include_index': includeIndex,
      if (indent != null) 'indent': indent,
      ...?options,
    };

    await JsonWriter().write(df, path, options: mergedOptions);
  }

  static String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot);
  }
}

// All format-specific write errors are now in their respective writer files:
// - ParquetWriteError in parquet_writer.dart
// - ExcelWriteError in excel_writer.dart
// - CsvWriteError in csv_writer.dart
// - JsonWriteError in json_writer.dart

/// Exception thrown when file format is not supported for writing
class UnsupportedWriteFormatError extends Error {
  final String message;
  UnsupportedWriteFormatError(this.message);

  @override
  String toString() => 'UnsupportedWriteFormatError: $message';
}
