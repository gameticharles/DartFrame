import 'dart:async';
import 'dart:convert';
import '../data_frame/data_frame.dart';
import '../file_helper/file_io.dart';

/// Abstract base class for data writers
abstract class DataWriter {
  /// Writes a DataFrame to the specified path
  Future<void> write(DataFrame df, String path, {Map<String, dynamic>? options});
}

/// Writer for Parquet files
class ParquetWriter implements DataWriter {
  @override
  Future<void> write(DataFrame df, String path, {Map<String, dynamic>? options}) async {
    try {
      final content = _dataFrameToParquetLikeContent(df, options);
      final fileIO = FileIO();
      fileIO.saveToFile(path, content);
    } catch (e) {
      throw ParquetWriteError('Failed to write Parquet file: $e');
    }
  }

  String _dataFrameToParquetLikeContent(DataFrame df, Map<String, dynamic>? options) {
    // This is a simplified implementation
    // In practice, you'd use a proper Parquet writing library
    final compression = options?['compression'] as String? ?? 'none';
    final includeIndex = options?['include_index'] as bool? ?? false;
    
    final buffer = StringBuffer();
    final columns = df.columns;
    
    // Write header
    if (includeIndex) {
      buffer.write('index,');
    }
    buffer.writeln(columns.join(','));
    
    // Write data
    for (int i = 0; i < df.shape.rows; i++) {
      if (includeIndex) {
        buffer.write('$i,');
      }
      
      final row = columns.map((col) {
        final value = df[col]![i];
        return _formatValue(value);
      }).join(',');
      
      buffer.writeln(row);
    }
    
    String content = buffer.toString();
    
    // Apply compression if specified
    if (compression != 'none') {
      content = _applyCompression(content, compression);
    }
    
    return content;
  }
}

/// Writer for Excel files
class ExcelWriter implements DataWriter {
  @override
  Future<void> write(DataFrame df, String path, {Map<String, dynamic>? options}) async {
    try {
      final content = _dataFrameToExcelLikeContent(df, options);
      final fileIO = FileIO();
      fileIO.saveToFile(path, content);
    } catch (e) {
      throw ExcelWriteError('Failed to write Excel file: $e');
    }
  }

  String _dataFrameToExcelLikeContent(DataFrame df, Map<String, dynamic>? options) {
    // final sheetName = options?['sheet_name'] as String? ?? 'Sheet1'; // For future use
    final includeIndex = options?['include_index'] as bool? ?? false;
    final dateFormat = options?['date_format'] as String? ?? 'yyyy-MM-dd';
    
    final buffer = StringBuffer();
    final columns = df.columns;
    
    // Write header
    if (includeIndex) {
      buffer.write('Index,');
    }
    buffer.writeln(columns.map((col) => _escapeExcelValue(col.toString())).join(','));
    
    // Write data
    for (int i = 0; i < df.shape.rows; i++) {
      if (includeIndex) {
        buffer.write('$i,');
      }
      
      final row = columns.map((col) {
        final value = df[col]![i];
        return _escapeExcelValue(_formatExcelValue(value, dateFormat));
      }).join(',');
      
      buffer.writeln(row);
    }
    
    return buffer.toString();
  }

  String _escapeExcelValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatExcelValue(dynamic value, String dateFormat) {
    if (value == null) return '';
    if (value is DateTime) {
      // Simple date formatting - in practice would use intl package
      return value.toIso8601String().split('T')[0];
    }
    return value.toString();
  }
}

/// Writer for CSV files
class CsvWriter implements DataWriter {
  @override
  Future<void> write(DataFrame df, String path, {Map<String, dynamic>? options}) async {
    try {
      final content = _dataFrameToCsvContent(df, options);
      final fileIO = FileIO();
      fileIO.saveToFile(path, content);
    } catch (e) {
      throw CsvWriteError('Failed to write CSV file: $e');
    }
  }

  String _dataFrameToCsvContent(DataFrame df, Map<String, dynamic>? options) {
    final separator = options?['separator'] as String? ?? ',';
    final includeIndex = options?['include_index'] as bool? ?? false;
    final includeHeader = options?['include_header'] as bool? ?? true;
    final quoteChar = options?['quote_char'] as String? ?? '"';
    final escapeChar = options?['escape_char'] as String? ?? '"';
    final lineTerminator = options?['line_terminator'] as String? ?? '\n';
    
    final buffer = StringBuffer();
    final columns = df.columns;
    
    // Write header
    if (includeHeader) {
      if (includeIndex) {
        buffer.write('index$separator');
      }
      buffer.write(columns.map((col) => _escapeCsvValue(col, separator, quoteChar, escapeChar)).join(separator));
      buffer.write(lineTerminator);
    }
    
    // Write data
    for (int i = 0; i < df.shape.rows; i++) {
      if (includeIndex) {
        buffer.write('$i$separator');
      }
      
      final row = columns.map((col) {
        final value = df[col]![i];
        return _escapeCsvValue(_formatValue(value), separator, quoteChar, escapeChar);
      }).join(separator);
      
      buffer.write(row);
      buffer.write(lineTerminator);
    }
    
    return buffer.toString();
  }

  String _escapeCsvValue(String value, String separator, String quoteChar, String escapeChar) {
    if (value.contains(separator) || value.contains(quoteChar) || value.contains('\n') || value.contains('\r')) {
      final escaped = value.replaceAll(quoteChar, escapeChar + quoteChar);
      return '$quoteChar$escaped$quoteChar';
    }
    return value;
  }
}

/// Writer for JSON files
class JsonWriter implements DataWriter {
  @override
  Future<void> write(DataFrame df, String path, {Map<String, dynamic>? options}) async {
    try {
      final content = _dataFrameToJsonContent(df, options);
      final fileIO = FileIO();
      fileIO.saveToFile(path, content);
    } catch (e) {
      throw JsonWriteError('Failed to write JSON file: $e');
    }
  }

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
    
    final encoder = indent != null 
        ? JsonEncoder.withIndent(' ' * indent)
        : JsonEncoder();
    
    return encoder.convert(jsonData);
  }

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

  Map<String, List<dynamic>> _toColumnsFormat(DataFrame df) {
    final result = <String, List<dynamic>>{};
    final columns = df.columns;
    
    for (final col in columns) {
      result[col] = df[col]!;
    }
    
    return result;
  }

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

/// Generic file writer that can handle multiple formats
class FileWriter {
  static final Map<String, DataWriter> _writers = {
    '.parquet': ParquetWriter(),
    '.pq': ParquetWriter(),
    '.xlsx': ExcelWriter(),
    '.xls': ExcelWriter(),
    '.csv': CsvWriter(),
    '.json': JsonWriter(),
  };

  /// Writes a DataFrame to a file, automatically detecting format by extension
  static Future<void> write(DataFrame df, String path, {Map<String, dynamic>? options}) async {
    final extension = _getFileExtension(path).toLowerCase();
    final writer = _writers[extension];
    
    if (writer == null) {
      throw UnsupportedWriteFormatError('Unsupported file format for writing: $extension');
    }
    
    await writer.write(df, path, options: options);
  }

  /// Writes a DataFrame to a Parquet file
  static Future<void> writeParquet(DataFrame df, String path, {
    String compression = 'none',
    bool includeIndex = false,
    Map<String, dynamic>? options
  }) async {
    final mergedOptions = <String, dynamic>{
      'compression': compression,
      'include_index': includeIndex,
      ...?options,
    };
    
    await ParquetWriter().write(df, path, options: mergedOptions);
  }

  /// Writes a DataFrame to an Excel file
  static Future<void> writeExcel(DataFrame df, String path, {
    String sheetName = 'Sheet1',
    bool includeIndex = false,
    String dateFormat = 'yyyy-MM-dd',
    Map<String, dynamic>? options
  }) async {
    final mergedOptions = <String, dynamic>{
      'sheet_name': sheetName,
      'include_index': includeIndex,
      'date_format': dateFormat,
      ...?options,
    };
    
    await ExcelWriter().write(df, path, options: mergedOptions);
  }

  /// Writes a DataFrame to a CSV file
  static Future<void> writeCsv(DataFrame df, String path, {
    String separator = ',',
    bool includeIndex = false,
    bool includeHeader = true,
    String quoteChar = '"',
    String escapeChar = '"',
    String lineTerminator = '\n',
    Map<String, dynamic>? options
  }) async {
    final mergedOptions = <String, dynamic>{
      'separator': separator,
      'include_index': includeIndex,
      'include_header': includeHeader,
      'quote_char': quoteChar,
      'escape_char': escapeChar,
      'line_terminator': lineTerminator,
      ...?options,
    };
    
    await CsvWriter().write(df, path, options: mergedOptions);
  }

  /// Writes a DataFrame to a JSON file
  static Future<void> writeJson(DataFrame df, String path, {
    String orient = 'records',
    bool includeIndex = false,
    int? indent,
    Map<String, dynamic>? options
  }) async {
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

/// Compression utilities
class CompressionUtils {
  /// Applies compression to content
  static String compress(String content, String method) {
    switch (method.toLowerCase()) {
      case 'gzip':
        return _gzipCompress(content);
      case 'deflate':
        return _deflateCompress(content);
      default:
        return content;
    }
  }

  static String _gzipCompress(String content) {
    // Mock implementation - would use dart:io gzip in practice
    return content; // Placeholder
  }

  static String _deflateCompress(String content) {
    // Mock implementation - would use dart:io deflate in practice
    return content; // Placeholder
  }
}

/// Utility function to format values for output
String _formatValue(dynamic value) {
  if (value == null) return '';
  if (value is DateTime) {
    return value.toIso8601String();
  }
  return value.toString();
}

/// Utility function to apply compression
String _applyCompression(String content, String compression) {
  return CompressionUtils.compress(content, compression);
}

/// Exception thrown when Parquet writing fails
class ParquetWriteError extends Error {
  final String message;
  ParquetWriteError(this.message);
  
  @override
  String toString() => 'ParquetWriteError: $message';
}

/// Exception thrown when Excel writing fails
class ExcelWriteError extends Error {
  final String message;
  ExcelWriteError(this.message);
  
  @override
  String toString() => 'ExcelWriteError: $message';
}

/// Exception thrown when CSV writing fails
class CsvWriteError extends Error {
  final String message;
  CsvWriteError(this.message);
  
  @override
  String toString() => 'CsvWriteError: $message';
}

/// Exception thrown when JSON writing fails
class JsonWriteError extends Error {
  final String message;
  JsonWriteError(this.message);
  
  @override
  String toString() => 'JsonWriteError: $message';
}

/// Exception thrown when file format is not supported for writing
class UnsupportedWriteFormatError extends Error {
  final String message;
  UnsupportedWriteFormatError(this.message);
  
  @override
  String toString() => 'UnsupportedWriteFormatError: $message';
}