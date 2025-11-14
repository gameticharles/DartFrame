import 'dart:async';
import '../data_frame/data_frame.dart';
import '../file_helper/file_io.dart';
import 'hdf5_reader.dart';

/// Abstract base class for data readers
abstract class DataReader {
  /// Reads data from the specified path and returns a DataFrame
  Future<DataFrame> read(String path, {Map<String, dynamic>? options});
}

/// Reader for Parquet files
class ParquetReader implements DataReader {
  @override
  Future<DataFrame> read(String path, {Map<String, dynamic>? options}) async {
    try {
      final fileIO = FileIO();
      final content = await fileIO.readFromFile(path);

      // For now, we'll implement a basic Parquet-like reader
      // In a real implementation, this would use a proper Parquet library
      return _parseParquetLikeContent(content, options);
    } catch (e) {
      throw ParquetReadError('Failed to read Parquet file: $e');
    }
  }

  DataFrame _parseParquetLikeContent(
      String content, Map<String, dynamic>? options) {
    // This is a simplified implementation
    // In practice, you'd use a proper Parquet parsing library
    try {
      final lines =
          content.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        throw ParquetReadError('Empty file content');
      }

      // Assume first line contains column names
      final headers = lines[0].split(',').map((h) => h.trim()).toList();
      final data = <String, List<dynamic>>{};

      // Initialize columns
      for (final header in headers) {
        data[header] = <dynamic>[];
      }

      // Parse data rows
      for (int i = 1; i < lines.length; i++) {
        final values = lines[i].split(',');
        for (int j = 0; j < headers.length && j < values.length; j++) {
          final value = values[j].trim();
          data[headers[j]]!.add(_parseValue(value));
        }
      }

      return DataFrame.fromMap(data);
    } catch (e) {
      throw ParquetReadError('Failed to parse Parquet content: $e');
    }
  }

  dynamic _parseValue(String value) {
    if (value.isEmpty || value.toLowerCase() == 'null') return null;

    // Try to parse as number
    final numValue = num.tryParse(value);
    if (numValue != null) return numValue;

    // Try to parse as boolean
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    // Return as string
    return value;
  }
}

/// Reader for Excel files
class ExcelReader implements DataReader {
  @override
  Future<DataFrame> read(String path, {Map<String, dynamic>? options}) async {
    try {
      final fileIO = FileIO();
      final content = await fileIO.readFromFile(path);

      return _parseExcelLikeContent(content, options);
    } catch (e) {
      throw ExcelReadError('Failed to read Excel file: $e');
    }
  }

  DataFrame _parseExcelLikeContent(
      String content, Map<String, dynamic>? options) {
    // This is a simplified implementation for Excel-like CSV content
    // In practice, you'd use a proper Excel parsing library like excel package
    try {
      // final sheetName = options?['sheet_name'] as String?; // For future use
      final skipRows = options?['skiprows'] as int? ?? 0;
      final nRows = options?['nrows'] as int?;

      final lines =
          content.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        throw ExcelReadError('Empty file content');
      }

      // Skip specified rows
      final dataLines = lines.skip(skipRows).toList();
      if (dataLines.isEmpty) {
        throw ExcelReadError('No data after skipping rows');
      }

      // Limit rows if specified
      final processLines =
          nRows != null ? dataLines.take(nRows + 1).toList() : dataLines;

      // Parse headers
      final headers = _parseExcelRow(processLines[0]);
      final data = <String, List<dynamic>>{};

      // Initialize columns
      for (final header in headers) {
        data[header] = <dynamic>[];
      }

      // Parse data rows
      for (int i = 1; i < processLines.length; i++) {
        final values = _parseExcelRow(processLines[i]);
        for (int j = 0; j < headers.length; j++) {
          final value = j < values.length ? values[j] : null;
          data[headers[j]]!.add(_parseExcelValue(value));
        }
      }

      return DataFrame.fromMap(data);
    } catch (e) {
      throw ExcelReadError('Failed to parse Excel content: $e');
    }
  }

  List<String> _parseExcelRow(String row) {
    // Simple CSV-like parsing - in practice would handle Excel-specific formatting
    final values = <String>[];
    final chars = row.split('');
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        values.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    values.add(current.trim());
    return values;
  }

  dynamic _parseExcelValue(String? value) {
    if (value == null || value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }

    // Remove quotes if present
    String cleanValue = value;
    if (cleanValue.startsWith('"') && cleanValue.endsWith('"')) {
      cleanValue = cleanValue.substring(1, cleanValue.length - 1);
    }

    // Try to parse as number
    final numValue = num.tryParse(cleanValue);
    if (numValue != null) return numValue;

    // Try to parse as boolean
    if (cleanValue.toLowerCase() == 'true') return true;
    if (cleanValue.toLowerCase() == 'false') return false;

    // Try to parse as DateTime
    final dateValue = DateTime.tryParse(cleanValue);
    if (dateValue != null) return dateValue;

    // Return as string
    return cleanValue;
  }
}

/// Generic file reader that can handle multiple formats
class FileReader {
  static final Map<String, DataReader> _readers = {
    '.parquet': ParquetReader(),
    '.pq': ParquetReader(),
    '.xlsx': ExcelReader(),
    '.xls': ExcelReader(),
    '.csv': ExcelReader(), // CSV can be handled by Excel reader
    '.h5': HDF5Reader(),
    '.hdf5': HDF5Reader(),
  };

  /// Reads a file and returns a DataFrame, automatically detecting format by extension
  static Future<DataFrame> read(String path,
      {Map<String, dynamic>? options}) async {
    final extension = _getFileExtension(path).toLowerCase();
    final reader = _readers[extension];

    if (reader == null) {
      throw UnsupportedFormatError('Unsupported file format: $extension');
    }

    return reader.read(path, options: options);
  }

  /// Reads a Parquet file
  static Future<DataFrame> readParquet(String path,
      {Map<String, dynamic>? options}) async {
    return ParquetReader().read(path, options: options);
  }

  /// Reads an Excel file
  static Future<DataFrame> readExcel(String path,
      {String? sheetName,
      int? skipRows,
      int? nRows,
      Map<String, dynamic>? options}) async {
    final mergedOptions = <String, dynamic>{
      if (sheetName != null) 'sheet_name': sheetName,
      if (skipRows != null) 'skiprows': skipRows,
      if (nRows != null) 'nrows': nRows,
      ...?options,
    };

    return ExcelReader().read(path, options: mergedOptions);
  }

  /// Reads an HDF5 file
  static Future<DataFrame> readHDF5(String path,
      {String? dataset, Map<String, dynamic>? options}) async {
    final mergedOptions = <String, dynamic>{
      if (dataset != null) 'dataset': dataset,
      ...?options,
    };

    return HDF5Reader().read(path, options: mergedOptions);
  }

  /// Inspects an HDF5 file structure
  static Future<Map<String, dynamic>> inspectHDF5(String path) async {
    return HDF5Reader.inspect(path);
  }

  /// Lists datasets in an HDF5 file
  static Future<List<String>> listHDF5Datasets(String path) async {
    return HDF5Reader.listDatasets(path);
  }

  static String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot);
  }
}

/// Exception thrown when Parquet reading fails
class ParquetReadError extends Error {
  final String message;
  ParquetReadError(this.message);

  @override
  String toString() => 'ParquetReadError: $message';
}

/// Exception thrown when Excel reading fails
class ExcelReadError extends Error {
  final String message;
  ExcelReadError(this.message);

  @override
  String toString() => 'ExcelReadError: $message';
}

/// Exception thrown when file format is not supported
class UnsupportedFormatError extends Error {
  final String message;
  UnsupportedFormatError(this.message);

  @override
  String toString() => 'UnsupportedFormatError: $message';
}
