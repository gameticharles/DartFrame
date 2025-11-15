import 'dart:async';
import 'package:excel/excel.dart' as excel_pkg;
import '../data_frame/data_frame.dart';
import '../file_helper/file_io.dart';
import 'readers.dart';

/// Reader for Excel files (.xlsx, .xls) using the excel package.
///
/// This class provides comprehensive functionality to read Excel files and
/// convert them into DataFrames. It supports reading individual sheets or
/// entire workbooks with multiple sheets.
///
/// ## Features
/// - Read .xlsx and .xls file formats
/// - Select specific sheet by name or read first sheet
/// - Read all sheets at once into a Map
/// - List all sheet names in a workbook
/// - Header row detection and custom column names
/// - Skip rows functionality
/// - Limit maximum rows to read
/// - Support for multiple Excel cell types (text, numbers, dates, booleans, formulas)
///
/// ## Supported Cell Types
/// - Text (TextCellValue)
/// - Integers (IntCellValue)
/// - Doubles (DoubleCellValue)
/// - Booleans (BoolCellValue)
/// - Dates (DateCellValue, DateTimeCellValue)
/// - Times (TimeCellValue)
/// - Formulas (FormulaCellValue)
///
/// ## Example
/// ```dart
/// // Read first sheet
/// final df = await ExcelFileReader().read('data.xlsx');
///
/// // Read specific sheet
/// final df = await ExcelFileReader().read('data.xlsx', options: {
///   'sheetName': 'Sheet2',
///   'hasHeader': true,
///   'skipRows': 1,
/// });
///
/// // Read all sheets
/// final sheets = await ExcelFileReader.readAllSheets('workbook.xlsx');
/// final salesDf = sheets['Sales'];
/// final inventoryDf = sheets['Inventory'];
///
/// // List sheets
/// final sheetNames = await ExcelFileReader.listSheets('data.xlsx');
/// ```
///
/// ## Options
/// - `sheetName` (String?): Name of sheet to read (default: first sheet)
/// - `hasHeader` (bool): Whether first row is header (default: true)
/// - `skipRows` (int): Number of rows to skip (default: 0)
/// - `maxRows` (int?): Maximum rows to read (default: all)
/// - `columnNames` (`List<String>?`): Custom column names when no header
///
/// See also:
/// - [ExcelFileWriter] for writing Excel files
/// - [FileReader.readExcel] for a convenient wrapper method
/// - [FileReader.readAllExcelSheets] for reading all sheets at once
class ExcelFileReader implements DataReader {
  @override
  Future<DataFrame> read(String path, {Map<String, dynamic>? options}) async {
    try {
      final fileIO = FileIO();
      final bytes = await fileIO.readBytesFromFile(path);
      final excel = excel_pkg.Excel.decodeBytes(bytes);

      return _parseExcelContent(excel, options);
    } catch (e) {
      throw ExcelReadError('Failed to read Excel file: $e');
    }
  }

  /// Parses Excel workbook content into a DataFrame.
  ///
  /// This internal method handles the actual Excel parsing logic. It selects
  /// the appropriate sheet, extracts headers, processes cell values, and builds
  /// the DataFrame structure.
  ///
  /// Throws [ExcelReadError] if parsing fails or sheet is not found.
  DataFrame _parseExcelContent(
      excel_pkg.Excel excel, Map<String, dynamic>? options) {
    try {
      // Parse options
      final sheetName = options?['sheetName'] as String?;
      final hasHeader = options?['hasHeader'] as bool? ?? true;
      final skipRows = options?['skipRows'] as int? ?? 0;
      final maxRows = options?['maxRows'] as int?;
      final columnNames = options?['columnNames'] as List<String>?;

      // Get the sheet to read
      excel_pkg.Sheet? sheet;
      if (sheetName != null) {
        sheet = excel.tables[sheetName];
        if (sheet == null) {
          throw ExcelReadError('Sheet "$sheetName" not found');
        }
      } else {
        // Use first sheet
        if (excel.tables.isEmpty) {
          throw ExcelReadError('No sheets found in Excel file');
        }
        sheet = excel.tables.values.first;
      }

      // Get all rows
      final allRows = sheet.rows;
      if (allRows.isEmpty) {
        throw ExcelReadError('Empty sheet');
      }

      // Skip rows if specified
      final dataRows = allRows.skip(skipRows).toList();
      if (dataRows.isEmpty) {
        throw ExcelReadError('No data after skipping rows');
      }

      // Extract headers
      List<String> headers;
      int dataStartIndex;

      if (hasHeader) {
        headers = dataRows[0]
            .map((cell) => cell?.value?.toString() ?? '')
            .where((h) => h.isNotEmpty)
            .toList();
        dataStartIndex = 1;
      } else if (columnNames != null) {
        headers = columnNames;
        dataStartIndex = 0;
      } else {
        // Generate column names based on first row length
        final numCols = dataRows[0].length;
        headers = List.generate(numCols, (i) => 'col_$i');
        dataStartIndex = 0;
      }

      if (headers.isEmpty) {
        throw ExcelReadError('No valid headers found');
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
          final cell = i < row.length ? row[i] : null;
          final value = _extractCellValue(cell);
          data[headers[i]]!.add(value);
        }
      }

      return DataFrame.fromMap(data);
    } catch (e) {
      if (e is ExcelReadError) rethrow;
      throw ExcelReadError('Failed to parse Excel content: $e');
    }
  }

  /// Extracts the value from an Excel cell and converts it to appropriate Dart type.
  ///
  /// This method handles all Excel cell value types and converts them to
  /// corresponding Dart types:
  /// - TextCellValue → String
  /// - IntCellValue → int
  /// - DoubleCellValue → double
  /// - BoolCellValue → bool
  /// - DateCellValue/DateTimeCellValue → DateTime
  /// - TimeCellValue → String
  /// - FormulaCellValue → String (formula text)
  ///
  /// Returns null for empty cells.
  dynamic _extractCellValue(excel_pkg.Data? cell) {
    if (cell == null) return null;

    final value = cell.value;
    if (value == null) return null;

    // Handle different cell value types
    if (value is excel_pkg.TextCellValue) {
      // TextCellValue.value returns TextSpan, convert to string
      return value.value.toString();
    } else if (value is excel_pkg.IntCellValue) {
      return value.value;
    } else if (value is excel_pkg.DoubleCellValue) {
      return value.value;
    } else if (value is excel_pkg.BoolCellValue) {
      return value.value;
    } else if (value is excel_pkg.DateCellValue) {
      return value.asDateTimeLocal();
    } else if (value is excel_pkg.TimeCellValue) {
      // TimeCellValue doesn't have asDateTimeLocal, convert to string
      return value.toString();
    } else if (value is excel_pkg.DateTimeCellValue) {
      return value.asDateTimeLocal();
    } else if (value is excel_pkg.FormulaCellValue) {
      // Return the formula text
      return value.formula;
    }

    // Fallback to string representation
    return value.toString();
  }

  /// Reads all sheets from an Excel file and returns them as a Map.
  ///
  /// This method reads an entire Excel workbook and returns a Map where keys
  /// are sheet names and values are DataFrames. This is useful when you need
  /// to process multiple sheets from a single workbook.
  ///
  /// ## Parameters
  /// - `path`: Path to the Excel file
  /// - `hasHeader`: Whether first row of each sheet is a header (default: true)
  /// - `skipRows`: Number of rows to skip in each sheet (default: 0)
  /// - `maxRows`: Maximum rows to read from each sheet (default: all)
  /// - `columnNames`: Custom column names for sheets without headers
  /// - `options`: Additional options passed to the parser
  ///
  /// ## Returns
  /// A `Map<String, DataFrame>` where:
  /// - Keys are sheet names
  /// - Values are DataFrames containing the sheet data
  ///
  /// ## Error Handling
  /// If a sheet cannot be read, it will be skipped with a warning printed to
  /// console. The method only throws [ExcelReadError] if no sheets can be read.
  ///
  /// ## Example
  /// ```dart
  /// // Read all sheets
  /// final sheets = await ExcelFileReader.readAllSheets('workbook.xlsx');
  ///
  /// // Access individual sheets
  /// final salesDf = sheets['Sales'];
  /// final inventoryDf = sheets['Inventory'];
  ///
  /// // Process all sheets
  /// for (final entry in sheets.entries) {
  ///   print('Sheet: ${entry.key}');
  ///   print('Rows: ${entry.value.shape.rows}');
  ///   print('Columns: ${entry.value.columns}');
  /// }
  ///
  /// // Get sheet names
  /// print('Available sheets: ${sheets.keys.toList()}');
  /// ```
  ///
  /// See also:
  /// - [read] for reading a single sheet
  /// - [listSheets] for listing sheet names without reading data
  static Future<Map<String, DataFrame>> readAllSheets(
    String path, {
    bool hasHeader = true,
    int? skipRows,
    int? maxRows,
    List<String>? columnNames,
    Map<String, dynamic>? options,
  }) async {
    try {
      final fileIO = FileIO();
      final bytes = await fileIO.readBytesFromFile(path);
      final excel = excel_pkg.Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw ExcelReadError('No sheets found in Excel file');
      }

      final result = <String, DataFrame>{};
      final reader = ExcelFileReader();

      // Prepare options for each sheet
      final sheetOptions = <String, dynamic>{
        'hasHeader': hasHeader,
        if (skipRows != null) 'skipRows': skipRows,
        if (maxRows != null) 'maxRows': maxRows,
        if (columnNames != null) 'columnNames': columnNames,
        ...?options,
      };

      // Read each sheet
      for (final sheetName in excel.tables.keys) {
        final sheetSpecificOptions = <String, dynamic>{
          ...sheetOptions,
          'sheetName': sheetName,
        };

        try {
          final df = reader._parseExcelContent(excel, sheetSpecificOptions);
          result[sheetName] = df;
        } catch (e) {
          // Skip sheets that can't be read, but log the error
          print('Warning: Failed to read sheet "$sheetName": $e');
        }
      }

      if (result.isEmpty) {
        throw ExcelReadError('No sheets could be read from the Excel file');
      }

      return result;
    } catch (e) {
      if (e is ExcelReadError) rethrow;
      throw ExcelReadError('Failed to read all sheets: $e');
    }
  }

  /// Lists all sheet names in an Excel file without reading the data.
  ///
  /// This is a lightweight operation that only reads the workbook structure,
  /// not the actual cell data. Useful for discovering what sheets are available
  /// before deciding which ones to read.
  ///
  /// ## Parameters
  /// - `path`: Path to the Excel file
  ///
  /// ## Returns
  /// A `List<String>` containing all sheet names in the workbook.
  ///
  /// ## Example
  /// ```dart
  /// final sheets = await ExcelFileReader.listSheets('data.xlsx');
  /// print('Available sheets: $sheets');
  ///
  /// // Read specific sheet based on available names
  /// if (sheets.contains('Sales')) {
  ///   final df = await ExcelFileReader().read('data.xlsx',
  ///     options: {'sheetName': 'Sales'});
  /// }
  /// ```
  ///
  /// Throws [ExcelReadError] if the file cannot be read.
  static Future<List<String>> listSheets(String path) async {
    try {
      final fileIO = FileIO();
      final bytes = await fileIO.readBytesFromFile(path);
      final excel = excel_pkg.Excel.decodeBytes(bytes);

      return excel.tables.keys.toList();
    } catch (e) {
      throw ExcelReadError('Failed to list sheets: $e');
    }
  }
}

/// Exception thrown when Excel reading or parsing fails.
///
/// This error is thrown when:
/// - The Excel file cannot be read from disk
/// - The file format is invalid or corrupted
/// - The specified sheet name is not found
/// - A sheet is empty or has no valid data
/// - No data remains after skipping rows
/// - No sheets could be read from the workbook
///
/// Example:
/// ```dart
/// try {
///   final df = await ExcelFileReader().read('data.xlsx',
///     options: {'sheetName': 'NonExistent'});
/// } on ExcelReadError catch (e) {
///   print('Failed to read Excel: $e');
/// }
/// ```
class ExcelReadError extends Error {
  final String message;
  ExcelReadError(this.message);

  @override
  String toString() => 'ExcelReadError: $message';
}
