import 'dart:async';
import 'package:http/http.dart' as http;
import '../data_frame/data_frame.dart';
import 'data_source.dart';
import 'csv_reader.dart';
import 'json_reader.dart';

/// HTTP/HTTPS data source for loading data from web URLs.
///
/// Supports automatic format detection based on URL path extension or
/// Content-Type header. Can handle CSV, JSON, and other formats served
/// over HTTP/HTTPS.
///
/// ## Features
/// - Automatic format detection from URL extension
/// - Content-Type header parsing
/// - Custom headers support
/// - Timeout configuration
/// - Redirect following
/// - Response caching (optional)
///
/// ## Example
/// ```dart
/// // Register the source
/// DataSourceRegistry.register(HttpDataSource());
///
/// // Use through SmartLoader
/// final df = await DataFrame.read('https://example.com/data.csv');
///
/// // With options
/// final df = await DataFrame.read(
///   'https://api.example.com/data.json',
///   options: {
///     'headers': {'Authorization': 'Bearer token'},
///     'timeout': 30,
///   },
/// );
/// ```
class HttpDataSource extends DataSource {
  final http.Client _client;

  HttpDataSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get scheme => 'http';

  @override
  bool canHandle(Uri uri) {
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    try {
      // Extract options
      final headers = options['headers'] as Map<String, String>? ?? {};
      final timeout = options['timeout'] as int? ?? 30;

      // Make HTTP request
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: timeout));

      if (response.statusCode != 200) {
        throw DataSourceError(
          'HTTP request failed with status ${response.statusCode}',
          response.reasonPhrase,
        );
      }

      // Detect format
      final format = detectFormat(uri, response.headers);
      final content = response.body;

      // Parse based on format
      return await _parseContent(content, format, options);
    } catch (e) {
      if (e is DataSourceError) rethrow;
      throw DataSourceError('Failed to read from HTTP source: $uri', e);
    }
  }

  @override
  Future<void> write(
      DataFrame df, Uri uri, Map<String, dynamic> options) async {
    throw UnsupportedError(
        'HTTP write is not supported. Use POST/PUT methods instead.');
  }

  @override
  Future<Map<String, dynamic>> inspect(Uri uri) async {
    try {
      final response = await _client.head(uri).timeout(Duration(seconds: 10));

      return {
        'statusCode': response.statusCode,
        'contentType': response.headers['content-type'],
        'contentLength': response.headers['content-length'],
        'lastModified': response.headers['last-modified'],
        'headers': response.headers,
      };
    } catch (e) {
      throw DataSourceError('Failed to inspect HTTP source: $uri', e);
    }
  }

  /// Detects the data format from URI and response headers
  String detectFormat(Uri uri, Map<String, String> headers) {
    // First try URL extension
    final path = uri.path.toLowerCase();
    if (path.endsWith('.csv')) return 'csv';
    if (path.endsWith('.json')) return 'json';
    if (path.endsWith('.xlsx') || path.endsWith('.xls')) return 'excel';
    if (path.endsWith('.parquet') || path.endsWith('.pq')) return 'parquet';

    // Then try Content-Type header
    final contentType = headers['content-type']?.toLowerCase() ?? '';
    if (contentType.contains('csv')) return 'csv';
    if (contentType.contains('json')) return 'json';
    if (contentType.contains('excel') || contentType.contains('spreadsheet')) {
      return 'excel';
    }

    // Default to CSV
    return 'csv';
  }

  /// Parses content based on detected format
  Future<DataFrame> _parseContent(
    String content,
    String format,
    Map<String, dynamic> options,
  ) async {
    switch (format) {
      case 'csv':
        return CsvReader().parseCsvContent(content, options);
      case 'json':
        return JsonReader().parseJsonContent(content, options);
      default:
        throw DataSourceError('Unsupported format: $format');
    }
  }

  /// Closes the HTTP client
  void close() {
    _client.close();
  }
}
