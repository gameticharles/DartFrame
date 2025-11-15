import 'dart:async';
import '../data_frame/data_frame.dart';
import 'hdf5_reader.dart';
import 'csv_reader.dart';
import 'excel_reader.dart';
import 'parquet_reader.dart';
import 'json_reader.dart';

/// Abstract base class for data readers.
///
/// This interface defines the contract that all file format readers must implement.
/// Each reader is responsible for reading a specific file format and converting
/// it to a DataFrame.
///
/// Implementations include:
/// - [CsvReader] for CSV files
/// - [ExcelFileReader] for Excel files
/// - [HDF5Reader] for HDF5 files
/// - [ParquetReader] for Parquet files (basic implementation)
abstract class DataReader {
  /// Reads data from the specified path and returns a DataFrame.
  ///
  /// ## Parameters
  /// - `path`: Path to the file to read
  /// - `options`: Format-specific options for parsing
  ///
  /// ## Returns
  /// A Future that completes with a DataFrame containing the file data.
  ///
  /// Throws format-specific errors if reading fails.
  Future<DataFrame> read(String path, {Map<String, dynamic>? options});
}

// Format-specific readers are now in separate files:
// - parquet_reader.dart - Parquet file reader (placeholder)
// - excel_reader.dart - Excel file reader using excel package
// - csv_reader.dart - CSV file reader using csv package
// - json_reader.dart - JSON file reader with multiple orientations
// - hdf5_reader.dart - HDF5 file reader (pure Dart implementation)

/// Generic file reader that automatically detects and handles multiple file formats.
///
/// FileReader provides a unified interface for reading various file formats into
/// DataFrames. It automatically detects the file format based on the file extension
/// and uses the appropriate reader implementation.
///
/// ## Supported Formats
/// - **CSV** (.csv): Comma-separated values using [CsvReader]
/// - **Excel** (.xlsx, .xls): Excel workbooks using [ExcelFileReader]
/// - **JSON** (.json): JSON files with multiple orientations using [JsonReader]
/// - **HDF5** (.h5, .hdf5): HDF5 scientific data format using [HDF5Reader]
/// - **Parquet** (.parquet, .pq): Parquet columnar format (basic implementation)
///
/// ## Features
/// - Automatic format detection by file extension
/// - Format-specific options support
/// - Convenient wrapper methods for each format
/// - Multi-sheet Excel support
/// - HDF5 dataset inspection
///
/// ## Example
/// ```dart
/// // Auto-detect format
/// final df = await FileReader.read('data.csv');
///
/// // Format-specific methods
/// final csvDf = await FileReader.readCsv('data.csv',
///   fieldDelimiter: ';',
///   hasHeader: true,
/// );
///
/// final excelDf = await FileReader.readExcel('data.xlsx',
///   sheetName: 'Sheet1',
///   skipRows: 1,
/// );
///
/// // Read all Excel sheets
/// final sheets = await FileReader.readAllExcelSheets('workbook.xlsx');
///
/// // JSON operations
/// final jsonDf = await FileReader.readJson('data.json',
///   orient: 'records',
/// );
///
/// // HDF5 operations
/// final hdf5Df = await FileReader.readHDF5('data.h5',
///   dataset: '/mydata',
/// );
/// final info = await FileReader.inspectHDF5('data.h5');
/// ```
///
/// See also:
/// - [FileWriter] for writing DataFrames to files
/// - [CsvReader], [ExcelFileReader], [JsonReader], [HDF5Reader] for format-specific readers
class FileReader {
  static final Map<String, DataReader> _readers = {
    '.parquet': ParquetReader(),
    '.pq': ParquetReader(),
    '.xlsx': ExcelFileReader(),
    '.xls': ExcelFileReader(),
    '.csv': CsvReader(),
    '.json': JsonReader(),
    '.h5': HDF5Reader(),
    '.hdf5': HDF5Reader(),
  };

  /// Reads a file and returns a DataFrame, automatically detecting format by extension.
  ///
  /// This is the most convenient method for reading files when you don't need
  /// format-specific options. The file format is determined by the file extension.
  ///
  /// ## Supported Extensions
  /// - .csv → CSV reader
  /// - .xlsx, .xls → Excel reader
  /// - .json → JSON reader
  /// - .h5, .hdf5 → HDF5 reader
  /// - .parquet, .pq → Parquet reader
  ///
  /// ## Parameters
  /// - `path`: Path to the file to read
  /// - `options`: Optional format-specific options
  ///
  /// ## Example
  /// ```dart
  /// // Read CSV
  /// final df1 = await FileReader.read('data.csv');
  ///
  /// // Read Excel (first sheet)
  /// final df2 = await FileReader.read('data.xlsx');
  ///
  /// // Read with options
  /// final df3 = await FileReader.read('data.csv', options: {
  ///   'fieldDelimiter': ';',
  ///   'hasHeader': true,
  /// });
  /// ```
  ///
  /// Throws [UnsupportedFormatError] if the file extension is not recognized.
  /// Throws format-specific errors if reading fails.
  static Future<DataFrame> read(String path,
      {Map<String, dynamic>? options}) async {
    final extension = _getFileExtension(path).toLowerCase();
    final reader = _readers[extension];

    if (reader == null) {
      throw UnsupportedFormatError('Unsupported file format: $extension');
    }

    return reader.read(path, options: options);
  }

  /// Reads a Parquet file into a DataFrame.
  ///
  /// **Note:** This is a basic implementation. For production use with real
  /// Parquet files, integrate a proper Parquet library.
  ///
  /// ## Parameters
  /// - `path`: Path to the Parquet file
  /// - `options`: Optional parsing options
  ///
  /// Throws [ParquetReadError] if reading fails.
  static Future<DataFrame> readParquet(String path,
      {Map<String, dynamic>? options}) async {
    return ParquetReader().read(path, options: options);
  }

  /// Reads an Excel file (.xlsx, .xls) into a DataFrame.
  ///
  /// Reads a single sheet from an Excel workbook. If no sheet name is specified,
  /// reads the first sheet.
  ///
  /// ## Parameters
  /// - `path`: Path to the Excel file
  /// - `sheetName`: Name of sheet to read (default: first sheet)
  /// - `hasHeader`: Whether first row is header (default: true)
  /// - `skipRows`: Number of rows to skip (default: 0)
  /// - `maxRows`: Maximum rows to read (default: all)
  /// - `columnNames`: Custom column names when no header
  /// - `options`: Additional parsing options
  ///
  /// ## Example
  /// ```dart
  /// // Read first sheet
  /// final df = await FileReader.readExcel('data.xlsx');
  ///
  /// // Read specific sheet
  /// final df = await FileReader.readExcel('data.xlsx',
  ///   sheetName: 'Sales',
  ///   skipRows: 1,
  ///   maxRows: 100,
  /// );
  ///
  /// // Without header
  /// final df = await FileReader.readExcel('data.xlsx',
  ///   hasHeader: false,
  ///   columnNames: ['A', 'B', 'C'],
  /// );
  /// ```
  ///
  /// Throws [ExcelReadError] if reading fails or sheet is not found.
  ///
  /// See also:
  /// - [readAllExcelSheets] for reading all sheets at once
  /// - [listExcelSheets] for listing available sheets
  static Future<DataFrame> readExcel(String path,
      {String? sheetName,
      bool hasHeader = true,
      int? skipRows,
      int? maxRows,
      List<String>? columnNames,
      Map<String, dynamic>? options}) async {
    final mergedOptions = <String, dynamic>{
      if (sheetName != null) 'sheetName': sheetName,
      'hasHeader': hasHeader,
      if (skipRows != null) 'skipRows': skipRows,
      if (maxRows != null) 'maxRows': maxRows,
      if (columnNames != null) 'columnNames': columnNames,
      ...?options,
    };

    return ExcelFileReader().read(path, options: mergedOptions);
  }

  /// Reads a CSV (Comma-Separated Values) file into a DataFrame.
  ///
  /// Provides full control over CSV parsing with customizable delimiters,
  /// text qualifiers, and parsing options.
  ///
  /// ## Parameters
  /// - `path`: Path to the CSV file
  /// - `fieldDelimiter`: Field separator character (default: ',')
  /// - `textDelimiter`: Text quote character (default: '"')
  /// - `textEndDelimiter`: Ending text delimiter (default: same as textDelimiter)
  /// - `eol`: Line ending character (default: '\n')
  /// - `hasHeader`: Whether first row is header (default: true)
  /// - `skipRows`: Number of rows to skip (default: 0)
  /// - `maxRows`: Maximum rows to read (default: all)
  /// - `columnNames`: Custom column names when no header
  /// - `options`: Additional parsing options
  ///
  /// ## Example
  /// ```dart
  /// // Basic CSV reading
  /// final df = await FileReader.readCsv('data.csv');
  ///
  /// // Semicolon-separated
  /// final df = await FileReader.readCsv('data.csv',
  ///   fieldDelimiter: ';',
  /// );
  ///
  /// // Tab-separated with custom options
  /// final df = await FileReader.readCsv('data.tsv',
  ///   fieldDelimiter: '\t',
  ///   skipRows: 2,
  ///   maxRows: 1000,
  /// );
  ///
  /// // Without header
  /// final df = await FileReader.readCsv('data.csv',
  ///   hasHeader: false,
  ///   columnNames: ['col1', 'col2', 'col3'],
  /// );
  /// ```
  ///
  /// Throws [CsvReadError] if reading fails.
  static Future<DataFrame> readCsv(String path,
      {String fieldDelimiter = ',',
      String textDelimiter = '"',
      String? textEndDelimiter,
      String? eol,
      bool hasHeader = true,
      int? skipRows,
      int? maxRows,
      List<String>? columnNames,
      Map<String, dynamic>? options}) async {
    final mergedOptions = <String, dynamic>{
      'fieldDelimiter': fieldDelimiter,
      'textDelimiter': textDelimiter,
      if (textEndDelimiter != null) 'textEndDelimiter': textEndDelimiter,
      if (eol != null) 'eol': eol,
      'hasHeader': hasHeader,
      if (skipRows != null) 'skipRows': skipRows,
      if (maxRows != null) 'maxRows': maxRows,
      if (columnNames != null) 'columnNames': columnNames,
      ...?options,
    };

    return CsvReader().read(path, options: mergedOptions);
  }

  /// Reads a JSON file into a DataFrame.
  ///
  /// Supports multiple JSON orientations similar to pandas.
  ///
  /// ## Parameters
  /// - `path`: Path to the JSON file
  /// - `orient`: JSON orientation format (default: 'records')
  ///   - 'records': List of objects `[{"col1": val1}, ...]`
  ///   - 'index': Object with index keys `{"0": {"col1": val1}, ...}`
  ///   - 'columns': Object with column arrays `{"col1": [val1, val2], ...}`
  ///   - 'values': 2D array `[[val1, val2], ...]`
  /// - `columns`: Column names for 'values' orientation
  /// - `options`: Additional parsing options
  ///
  /// ## Example
  /// ```dart
  /// // Read records format (default)
  /// final df = await FileReader.readJson('data.json');
  ///
  /// // Read columns format
  /// final df = await FileReader.readJson('data.json',
  ///   orient: 'columns',
  /// );
  ///
  /// // Read values format with column names
  /// final df = await FileReader.readJson('data.json',
  ///   orient: 'values',
  ///   columns: ['col1', 'col2', 'col3'],
  /// );
  /// ```
  ///
  /// Throws [JsonReadError] if reading fails.
  static Future<DataFrame> readJson(String path,
      {String orient = 'records',
      List<String>? columns,
      Map<String, dynamic>? options}) async {
    final mergedOptions = <String, dynamic>{
      'orient': orient,
      if (columns != null) 'columns': columns,
      ...?options,
    };

    return JsonReader().read(path, options: mergedOptions);
  }

  /// Lists all sheet names in an Excel file without reading the data.
  ///
  /// This is a lightweight operation useful for discovering available sheets
  /// before deciding which ones to read.
  ///
  /// ## Parameters
  /// - `path`: Path to the Excel file
  ///
  /// ## Returns
  /// A List<String> containing all sheet names in the workbook.
  ///
  /// ## Example
  /// ```dart
  /// final sheets = await FileReader.listExcelSheets('data.xlsx');
  /// print('Available sheets: $sheets');
  ///
  /// // Read specific sheet if it exists
  /// if (sheets.contains('Sales')) {
  ///   final df = await FileReader.readExcel('data.xlsx',
  ///     sheetName: 'Sales');
  /// }
  /// ```
  ///
  /// Throws [ExcelReadError] if the file cannot be read.
  static Future<List<String>> listExcelSheets(String path) async {
    return ExcelFileReader.listSheets(path);
  }

  /// Reads all sheets from an Excel file and returns a Map of sheet names to DataFrames
  ///
  /// This is useful when you want to read an entire Excel workbook at once.
  /// Returns a Map where keys are sheet names and values are DataFrames.
  ///
  /// Example:
  /// ```dart
  /// final sheets = await FileReader.readAllExcelSheets('data.xlsx');
  /// print('Available sheets: ${sheets.keys}');
  ///
  /// // Access individual sheets
  /// final salesData = sheets['Sales'];
  /// final inventoryData = sheets['Inventory'];
  ///
  /// // Process all sheets
  /// for (final entry in sheets.entries) {
  ///   print('Sheet: ${entry.key}, Rows: ${entry.value.shape.rows}');
  /// }
  /// ```
  static Future<Map<String, DataFrame>> readAllExcelSheets(
    String path, {
    bool hasHeader = true,
    int? skipRows,
    int? maxRows,
    List<String>? columnNames,
    Map<String, dynamic>? options,
  }) async {
    return ExcelFileReader.readAllSheets(
      path,
      hasHeader: hasHeader,
      skipRows: skipRows,
      maxRows: maxRows,
      columnNames: columnNames,
      options: options,
    );
  }

  /// Reads an HDF5 file into a DataFrame.
  ///
  /// HDF5 is a hierarchical data format commonly used in scientific computing.
  /// This method reads a specific dataset from an HDF5 file.
  ///
  /// ## Parameters
  /// - `path`: Path to the HDF5 file
  /// - `dataset`: Path to dataset within the file (default: '/data')
  /// - `options`: Additional options (e.g., 'debug': true)
  ///
  /// ## Example
  /// ```dart
  /// // Read default dataset
  /// final df = await FileReader.readHDF5('data.h5');
  ///
  /// // Read specific dataset
  /// final df = await FileReader.readHDF5('data.h5',
  ///   dataset: '/measurements/temperature',
  /// );
  ///
  /// // With debug mode
  /// final df = await FileReader.readHDF5('data.h5',
  ///   dataset: '/mydata',
  ///   options: {'debug': true},
  /// );
  /// ```
  ///
  /// Throws HDF5-specific errors if reading fails.
  ///
  /// See also:
  /// - [inspectHDF5] for examining file structure
  /// - [listHDF5Datasets] for listing available datasets
  static Future<DataFrame> readHDF5(String path,
      {String? dataset, Map<String, dynamic>? options}) async {
    final mergedOptions = <String, dynamic>{
      if (dataset != null) 'dataset': dataset,
      ...?options,
    };

    return HDF5Reader().read(path, options: mergedOptions);
  }

  /// Inspects an HDF5 file structure and returns metadata.
  ///
  /// Returns information about the HDF5 file including version, root children,
  /// and available datasets without reading the actual data.
  ///
  /// ## Parameters
  /// - `path`: Path to the HDF5 file
  ///
  /// ## Returns
  /// A Map containing:
  /// - 'version': HDF5 file version
  /// - 'rootChildren': List of top-level objects
  /// - 'datasets': List of available datasets
  ///
  /// ## Example
  /// ```dart
  /// final info = await FileReader.inspectHDF5('data.h5');
  /// print('Version: ${info['version']}');
  /// print('Datasets: ${info['datasets']}');
  /// ```
  static Future<Map<String, dynamic>> inspectHDF5(String path) async {
    return HDF5Reader.inspect(path);
  }

  /// Lists all datasets in an HDF5 file.
  ///
  /// Returns a list of dataset paths available in the HDF5 file without
  /// reading the actual data.
  ///
  /// ## Parameters
  /// - `path`: Path to the HDF5 file
  ///
  /// ## Returns
  /// A List<String> containing dataset paths.
  ///
  /// ## Example
  /// ```dart
  /// final datasets = await FileReader.listHDF5Datasets('data.h5');
  /// print('Available datasets: $datasets');
  ///
  /// // Read first dataset
  /// if (datasets.isNotEmpty) {
  ///   final df = await FileReader.readHDF5('data.h5',
  ///     dataset: datasets.first);
  /// }
  /// ```
  static Future<List<String>> listHDF5Datasets(String path) async {
    return HDF5Reader.listDatasets(path);
  }

  static String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot);
  }
}

// All format-specific read errors are now in their respective reader files:
// - ParquetReadError in parquet_reader.dart
// - ExcelReadError in excel_reader.dart
// - CsvReadError in csv_reader.dart
// - JsonReadError in json_reader.dart (fully implemented)
// - HDF5 errors in hdf5_reader.dart

/// Exception thrown when file format is not supported
class UnsupportedFormatError extends Error {
  final String message;
  UnsupportedFormatError(this.message);

  @override
  String toString() => 'UnsupportedFormatError: $message';
}
