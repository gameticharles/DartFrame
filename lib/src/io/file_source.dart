import 'dart:async';
import 'package:dartframe/dartframe.dart';

import '../data_frame/data_frame.dart';
import 'data_source.dart';
import 'readers.dart';
import 'writers.dart';

/// File system data source for loading data from local files.
///
/// Handles file:// URIs and plain file paths, automatically detecting
/// the file format based on extension and delegating to appropriate readers.
///
/// ## Features
/// - Automatic format detection
/// - Support for all FileReader formats (CSV, JSON, Excel, HDF5, Parquet)
/// - File existence checking
/// - Metadata inspection
///
/// ## Example
/// ```dart
/// // Register the source
/// DataSourceRegistry.register(FileDataSource());
///
/// // Use through SmartLoader
/// final df = await DataFrame.read('file:///path/to/data.csv');
/// final df2 = await DataFrame.read('/path/to/data.json');
/// final df3 = await DataFrame.read('data.xlsx');
/// ```
class FileDataSource extends DataSource {
  @override
  String get scheme => 'file';

  @override
  bool canHandle(Uri uri) {
    // Handle file:// URIs, empty schemes, and Windows drive letters (e.g., c:)
    return uri.scheme == 'file' ||
        uri.scheme == '' ||
        uri.scheme.isEmpty ||
        (uri.scheme.length == 1 && RegExp(r'[a-zA-Z]').hasMatch(uri.scheme));
  }

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    try {
      final path = _uriToPath(uri);

      // Check if file exists
      if (!await FileIO().fileExists(path)) {
        throw DataSourceError('File not found: $path');
      }

      // Use FileReader to handle the file
      return await FileReader.read(path, options: options);
    } catch (e) {
      if (e is DataSourceError) rethrow;
      throw DataSourceError('Failed to read from file source: $uri', e);
    }
  }

  @override
  Future<void> write(
      DataFrame df, Uri uri, Map<String, dynamic> options) async {
    try {
      final path = _uriToPath(uri);
      final format = options['format'] as String? ?? _detectFormat(path);

      // Use FileWriter to handle the file
      switch (format.toLowerCase()) {
        case 'csv':
          await FileWriter.writeCsv(df, path, options: options);
          break;
        case 'json':
          await FileWriter.writeJson(df, path, options: options);
          break;
        case 'excel':
        case 'xlsx':
          await FileWriter.writeExcel(df, path, options: options);
          break;
        case 'parquet':
          await FileWriter.writeParquet(df, path, options: options);
          break;
        default:
          throw DataSourceError('Unsupported write format: $format');
      }
    } catch (e) {
      if (e is DataSourceError) rethrow;
      throw DataSourceError('Failed to write to file source: $uri', e);
    }
  }

  @override
  Future<Map<String, dynamic>> inspect(Uri uri) async {
    try {
      final path = _uriToPath(uri);
      final file = FileIO();

      if (!await file.fileExists(path)) {
        throw DataSourceError('File not found: $path');
      }

      final stat = file.getFileStatsSync(path);
      final extension = _getFileExtension(path);

      return {
        'path': path,
        'size': stat!.size,
        'modified': stat.modified.toIso8601String(),
        'extension': extension,
        'format': _detectFormat(path),
        'exists': true,
      };
    } catch (e) {
      if (e is DataSourceError) rethrow;
      throw DataSourceError('Failed to inspect file source: $uri', e);
    }
  }

  /// Converts URI to file path
  String _uriToPath(Uri uri) {
    if (uri.scheme == 'file') {
      return uri.toFilePath();
    }
    // Handle Windows drive letters (e.g., c:/path)
    if (uri.scheme.length == 1 && RegExp(r'[a-zA-Z]').hasMatch(uri.scheme)) {
      return '${uri.scheme}:${uri.path}';
    }
    // Handle plain paths
    return uri.path.isNotEmpty ? uri.path : uri.toString();
  }

  /// Detects format from file extension
  String _detectFormat(String path) {
    final ext = _getFileExtension(path).toLowerCase();
    switch (ext) {
      case '.csv':
        return 'csv';
      case '.json':
        return 'json';
      case '.xlsx':
      case '.xls':
        return 'excel';
      case '.h5':
      case '.hdf5':
        return 'hdf5';
      case '.parquet':
      case '.pq':
        return 'parquet';
      default:
        return 'unknown';
    }
  }

  /// Gets file extension from path
  String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot);
  }
}
