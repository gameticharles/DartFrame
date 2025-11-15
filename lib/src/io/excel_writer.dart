import 'dart:async';
import 'package:excel/excel.dart' as excel_pkg;
import '../data_frame/data_frame.dart';
import '../file_helper/file_io.dart';
import 'writers.dart';

/// Writer for Excel files (.xlsx) using the excel package.
///
/// This class provides comprehensive functionality to write DataFrames to Excel
/// files. It supports writing single sheets or creating workbooks with multiple
/// sheets, with proper type conversion and formatting.
///
/// ## Features
/// - Write to .xlsx file format
/// - Create single-sheet or multi-sheet workbooks
/// - Custom sheet names
/// - Optional header row
/// - Optional row index column
/// - Automatic type conversion (preserves numbers, dates, booleans)
/// - Clean output (removes unused default sheets)
///
/// ## Type Conversion
/// The writer automatically converts Dart types to Excel cell types:
/// - int → IntCellValue
/// - double → DoubleCellValue
/// - bool → BoolCellValue
/// - DateTime → DateTimeCellValue
/// - String → TextCellValue
/// - null → Empty cell
///
/// ## Example
/// ```dart
/// // Write single sheet
/// await ExcelFileWriter().write(df, 'output.xlsx');
///
/// // With custom options
/// await ExcelFileWriter().write(df, 'output.xlsx', options: {
///   'sheetName': 'MyData',
///   'includeHeader': true,
///   'includeIndex': true,
/// });
///
/// // Write multiple sheets
/// final sheets = {
///   'Sales': salesDf,
///   'Inventory': inventoryDf,
///   'Summary': summaryDf,
/// };
/// await ExcelFileWriter.writeMultipleSheets(sheets, 'report.xlsx');
/// ```
///
/// ## Options
/// - `sheetName` (String): Name of sheet to create (default: 'Sheet1')
/// - `includeHeader` (bool): Include header row (default: true)
/// - `includeIndex` (bool): Include row index column (default: false)
///
/// See also:
/// - [ExcelFileReader] for reading Excel files
/// - [FileWriter.writeExcel] for a convenient wrapper method
/// - [FileWriter.writeExcelSheets] for writing multiple sheets
class ExcelFileWriter implements DataWriter {
  @override
  Future<void> write(DataFrame df, String path,
      {Map<String, dynamic>? options}) async {
    try {
      final bytes = _dataFrameToExcelBytes(df, options);
      final fileIO = FileIO();
      await fileIO.writeBytesToFile(path, bytes);
    } catch (e) {
      throw ExcelWriteError('Failed to write Excel file: $e');
    }
  }

  /// Converts a DataFrame to Excel file bytes.
  ///
  /// This internal method handles the conversion of DataFrame data to Excel
  /// format. It creates a workbook, adds a sheet, writes headers and data,
  /// and encodes everything to bytes.
  ///
  /// Throws [ExcelWriteError] if conversion fails.
  List<int> _dataFrameToExcelBytes(
      DataFrame df, Map<String, dynamic>? options) {
    try {
      // Parse options
      final sheetName = options?['sheetName'] as String? ?? 'Sheet1';
      final includeHeader = options?['includeHeader'] as bool? ?? true;
      final includeIndex = options?['includeIndex'] as bool? ?? false;

      // Create Excel workbook
      final excel = excel_pkg.Excel.createExcel();

      // Remove default sheet if it exists
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Create new sheet
      final sheet = excel[sheetName];

      final columns = df.columns;
      int rowIndex = 0;

      // Add header row
      if (includeHeader) {
        int colIndex = 0;
        if (includeIndex) {
          sheet
              .cell(excel_pkg.CellIndex.indexByColumnRow(
                  columnIndex: colIndex++, rowIndex: rowIndex))
              .value = excel_pkg.TextCellValue('index');
        }
        for (final col in columns) {
          sheet
              .cell(excel_pkg.CellIndex.indexByColumnRow(
                  columnIndex: colIndex++, rowIndex: rowIndex))
              .value = excel_pkg.TextCellValue(col);
        }
        rowIndex++;
      }

      // Add data rows
      for (int i = 0; i < df.shape.rows; i++) {
        int colIndex = 0;
        if (includeIndex) {
          sheet
              .cell(excel_pkg.CellIndex.indexByColumnRow(
                  columnIndex: colIndex++, rowIndex: rowIndex))
              .value = excel_pkg.IntCellValue(i);
        }
        for (final col in columns) {
          final value = df[col]![i];
          sheet
              .cell(excel_pkg.CellIndex.indexByColumnRow(
                  columnIndex: colIndex++, rowIndex: rowIndex))
              .value = _convertToCellValue(value);
        }
        rowIndex++;
      }

      // Encode to bytes
      return excel.encode()!;
    } catch (e) {
      throw ExcelWriteError('Failed to convert DataFrame to Excel: $e');
    }
  }

  /// Writes multiple DataFrames to different sheets in a single Excel file.
  ///
  /// This method creates an Excel workbook with multiple sheets, where each
  /// DataFrame becomes a separate sheet. This is useful for creating comprehensive
  /// reports or organizing related data in a single file.
  ///
  /// ## Parameters
  /// - `sheets`: Map where keys are sheet names and values are DataFrames
  /// - `path`: Path where the Excel file will be saved
  /// - `includeHeader`: Include header row in each sheet (default: true)
  /// - `includeIndex`: Include row index column in each sheet (default: false)
  /// - `options`: Additional options (currently unused)
  ///
  /// ## Features
  /// - Creates one sheet per DataFrame
  /// - Automatically removes unused default "Sheet1"
  /// - Applies same formatting options to all sheets
  /// - Preserves data types (numbers, dates, booleans)
  /// - Single write operation for efficiency
  ///
  /// ## Example
  /// ```dart
  /// // Create multiple DataFrames
  /// final salesDf = DataFrame.fromMap({...});
  /// final inventoryDf = DataFrame.fromMap({...});
  /// final summaryDf = DataFrame.fromMap({...});
  ///
  /// // Write all sheets at once
  /// final sheets = {
  ///   'Sales': salesDf,
  ///   'Inventory': inventoryDf,
  ///   'Summary': summaryDf,
  /// };
  ///
  /// await ExcelFileWriter.writeMultipleSheets(sheets, 'report.xlsx');
  ///
  /// // With options
  /// await ExcelFileWriter.writeMultipleSheets(
  ///   sheets,
  ///   'report.xlsx',
  ///   includeHeader: true,
  ///   includeIndex: true,
  /// );
  /// ```
  ///
  /// ## Error Handling
  /// Throws [ExcelWriteError] if:
  /// - The sheets Map is empty
  /// - File cannot be written to disk
  /// - DataFrame conversion fails
  ///
  /// See also:
  /// - [write] for writing a single sheet
  /// - [FileWriter.writeExcelSheets] for a convenient wrapper method
  static Future<void> writeMultipleSheets(
    Map<String, DataFrame> sheets,
    String path, {
    bool includeHeader = true,
    bool includeIndex = false,
    Map<String, dynamic>? options,
  }) async {
    try {
      if (sheets.isEmpty) {
        throw ExcelWriteError('No sheets provided to write');
      }

      // Create Excel workbook
      final excel = excel_pkg.Excel.createExcel();

      final writer = ExcelFileWriter();

      // Write each DataFrame to its own sheet
      for (final entry in sheets.entries) {
        final sheetName = entry.key;
        final df = entry.value;

        final sheet = excel[sheetName];
        final columns = df.columns;
        int rowIndex = 0;

        // Add header row
        if (includeHeader) {
          int colIndex = 0;
          if (includeIndex) {
            sheet
                .cell(excel_pkg.CellIndex.indexByColumnRow(
                    columnIndex: colIndex++, rowIndex: rowIndex))
                .value = excel_pkg.TextCellValue('index');
          }
          for (final col in columns) {
            sheet
                .cell(excel_pkg.CellIndex.indexByColumnRow(
                    columnIndex: colIndex++, rowIndex: rowIndex))
                .value = excel_pkg.TextCellValue(col);
          }
          rowIndex++;
        }

        // Add data rows
        for (int i = 0; i < df.shape.rows; i++) {
          int colIndex = 0;
          if (includeIndex) {
            sheet
                .cell(excel_pkg.CellIndex.indexByColumnRow(
                    columnIndex: colIndex++, rowIndex: rowIndex))
                .value = excel_pkg.IntCellValue(i);
          }
          for (final col in columns) {
            final value = df[col]![i];
            sheet
                .cell(excel_pkg.CellIndex.indexByColumnRow(
                    columnIndex: colIndex++, rowIndex: rowIndex))
                .value = writer._convertToCellValue(value);
          }
          rowIndex++;
        }
      }

      // Remove default Sheet1 if it exists and wasn't used
      if (excel.tables.containsKey('Sheet1') && !sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Write to file
      final fileIO = FileIO();
      final bytes = excel.encode()!;
      await fileIO.writeBytesToFile(path, bytes);
    } catch (e) {
      if (e is ExcelWriteError) rethrow;
      throw ExcelWriteError('Failed to write multiple sheets: $e');
    }
  }

  /// Converts a Dart value to the appropriate Excel cell value type.
  ///
  /// This method handles type conversion from Dart types to Excel cell types:
  /// - int → IntCellValue
  /// - double → DoubleCellValue
  /// - num → DoubleCellValue
  /// - bool → BoolCellValue
  /// - DateTime → DateTimeCellValue
  /// - Other types → TextCellValue (via toString())
  ///
  /// Returns null for null values.
  excel_pkg.CellValue? _convertToCellValue(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is int) {
      return excel_pkg.IntCellValue(value);
    } else if (value is double) {
      return excel_pkg.DoubleCellValue(value);
    } else if (value is num) {
      return excel_pkg.DoubleCellValue(value.toDouble());
    } else if (value is bool) {
      return excel_pkg.BoolCellValue(value);
    } else if (value is DateTime) {
      return excel_pkg.DateTimeCellValue.fromDateTime(value);
    } else {
      return excel_pkg.TextCellValue(value.toString());
    }
  }
}

/// Exception thrown when Excel writing or conversion fails.
///
/// This error is thrown when:
/// - The Excel file cannot be written to disk
/// - DataFrame conversion to Excel format fails
/// - No sheets are provided for multi-sheet write
/// - Invalid options are provided
/// - File system errors occur during writing
///
/// Example:
/// ```dart
/// try {
///   await ExcelFileWriter().write(df, 'output.xlsx');
/// } on ExcelWriteError catch (e) {
///   print('Failed to write Excel: $e');
/// }
/// ```
class ExcelWriteError extends Error {
  final String message;
  ExcelWriteError(this.message);

  @override
  String toString() => 'ExcelWriteError: $message';
}
