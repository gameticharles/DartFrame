import 'dart:async';
import '../data_frame/data_frame.dart';
import 'data_source.dart';
import 'file_source.dart';
import 'http_source.dart';
import 'scientific_datasets.dart';
import 'database.dart';

/// Smart loader that automatically detects and handles various data sources.
///
/// SmartLoader provides a unified interface for loading data from multiple
/// sources including files, HTTP URLs, databases, cloud storage, and
/// scientific datasets. It automatically detects the source type from the URI
/// and delegates to the appropriate handler.
///
/// ## Supported URI Schemes
/// - **file://** or plain paths: Local files (CSV, JSON, Excel, HDF5, Parquet)
/// - **http://** and **https://**: Web resources
/// - **dataset://**: Scientific datasets (MNIST, Iris, Titanic, etc.)
/// - **sqlite://**: SQLite databases
/// - **postgresql://**: PostgreSQL databases
/// - **mysql://**: MySQL databases
/// - Custom schemes via DataSourceRegistry
///
/// ## Features
/// - Automatic source detection from URI
/// - Extensible plugin architecture
/// - Format auto-detection
/// - Unified options interface
/// - Error handling and validation
///
/// ## Example
/// ```dart
/// // Load from various sources
/// final df1 = await SmartLoader.read('data.csv');
/// final df2 = await SmartLoader.read('https://example.com/data.json');
/// final df3 = await SmartLoader.read('dataset://iris');
/// final df4 = await SmartLoader.read('sqlite://path/to/db.sqlite?table=users');
///
/// // With options
/// final df5 = await SmartLoader.read(
///   'https://api.example.com/data.csv',
///   options: {
///     'headers': {'Authorization': 'Bearer token'},
///     'fieldDelimiter': ';',
///   },
/// );
///
/// // Write data
/// await SmartLoader.write(df, 'output.csv');
/// await SmartLoader.write(df, 'file:///path/to/output.json');
/// ```
///
/// See also:
/// - [DataSourceRegistry] for registering custom sources
/// - [DataSource] for implementing custom sources
class SmartLoader {
  static bool _initialized = false;

  /// Initializes the SmartLoader with default data sources.
  ///
  /// This is called automatically on first use, but can be called manually
  /// to ensure initialization happens at a specific time.
  static void initialize() {
    if (_initialized) return;

    // Register built-in data sources
    DataSourceRegistry.register(FileDataSource());
    DataSourceRegistry.register(HttpDataSource());
    DataSourceRegistry.register(ScientificDataSource());
    DataSourceRegistry.register(DatabaseDataSource());

    _initialized = true;
  }

  /// Reads data from a URI and returns a DataFrame.
  ///
  /// Automatically detects the source type from the URI scheme and delegates
  /// to the appropriate data source handler.
  ///
  /// ## Parameters
  /// - `uri`: URI string or path to the data source
  /// - `options`: Source-specific and format-specific options
  ///
  /// ## Common Options
  /// - `format`: Force a specific format (csv, json, excel, etc.)
  /// - `hasHeader`: Whether the data has a header row (default: true)
  /// - `fieldDelimiter`: Field delimiter for CSV (default: ',')
  /// - `orient`: JSON orientation (records, columns, index, values)
  /// - `headers`: HTTP headers for web requests
  /// - `timeout`: Timeout in seconds for network requests
  ///
  /// ## Examples
  /// ```dart
  /// // Local file
  /// final df = await SmartLoader.read('data.csv');
  ///
  /// // HTTP URL
  /// final df = await SmartLoader.read('https://example.com/data.json');
  ///
  /// // Scientific dataset
  /// final df = await SmartLoader.read('dataset://mnist/train');
  ///
  /// // Database
  /// final df = await SmartLoader.read(
  ///   'postgresql://user:pass@host/db?table=users'
  /// );
  ///
  /// // With options
  /// final df = await SmartLoader.read('data.csv', options: {
  ///   'fieldDelimiter': ';',
  ///   'skipRows': 1,
  /// });
  /// ```
  ///
  /// Throws [DataSourceError] if the source cannot be read or is not supported.
  static Future<DataFrame> read(
    String uri, {
    Map<String, dynamic>? options,
  }) async {
    initialize();

    try {
      final parsedUri = Uri.parse(uri);

      // Try registered data sources first
      final source = DataSourceRegistry.findByUri(parsedUri);
      if (source != null) {
        return await source.read(parsedUri, options ?? {});
      }

      // Fallback to built-in loaders based on scheme
      final scheme = parsedUri.scheme.toLowerCase();

      // Handle Windows drive letters (e.g., c:)
      if (scheme.length == 1 && RegExp(r'[a-z]').hasMatch(scheme)) {
        return await _loadFile(parsedUri, options);
      }

      switch (scheme) {
        case 'http':
        case 'https':
          return await _loadHttp(parsedUri, options);
        case 'file':
        case '':
          return await _loadFile(parsedUri, options);
        case 'dataset':
          return await _loadDataset(parsedUri, options);
        case 'sqlite':
        case 'postgresql':
        case 'postgres':
        case 'mysql':
          return await _loadDatabase(parsedUri, options);
        default:
          throw DataSourceError(
            'Unsupported URI scheme: ${parsedUri.scheme}. '
            'Supported schemes: file, http, https, dataset, sqlite, postgresql, mysql',
          );
      }
    } catch (e) {
      if (e is DataSourceError) rethrow;
      throw DataSourceError('Failed to read from URI: $uri', e);
    }
  }

  /// Writes a DataFrame to a URI.
  ///
  /// Automatically detects the destination type from the URI scheme and
  /// delegates to the appropriate data source handler.
  ///
  /// ## Parameters
  /// - `df`: DataFrame to write
  /// - `uri`: URI string or path to the destination
  /// - `options`: Source-specific and format-specific options
  ///
  /// ## Common Options
  /// - `format`: Force a specific format (csv, json, excel, etc.)
  /// - `index`: Whether to write the index (default: false)
  /// - `header`: Whether to write column headers (default: true)
  /// - `orient`: JSON orientation (records, columns, index, values)
  /// - `ifExists`: Database behavior (fail, replace, append)
  ///
  /// ## Examples
  /// ```dart
  /// // Local file
  /// await SmartLoader.write(df, 'output.csv');
  ///
  /// // With format specification
  /// await SmartLoader.write(df, 'output.xlsx', options: {
  ///   'sheetName': 'Data',
  /// });
  ///
  /// // JSON with orientation
  /// await SmartLoader.write(df, 'output.json', options: {
  ///   'orient': 'records',
  /// });
  ///
  /// // Database
  /// await SmartLoader.write(df, 'sqlite://db.sqlite?table=users', options: {
  ///   'ifExists': 'replace',
  /// });
  /// ```
  ///
  /// Throws [DataSourceError] if the destination cannot be written or is not supported.
  static Future<void> write(
    DataFrame df,
    String uri, {
    Map<String, dynamic>? options,
  }) async {
    initialize();

    try {
      final parsedUri = Uri.parse(uri);

      // Try registered data sources first
      final source = DataSourceRegistry.findByUri(parsedUri);
      if (source != null) {
        return await source.write(df, parsedUri, options ?? {});
      }

      // Fallback to built-in writers based on scheme
      final scheme = parsedUri.scheme.toLowerCase();

      // Handle Windows drive letters (e.g., c:)
      if (scheme.length == 1 && RegExp(r'[a-z]').hasMatch(scheme)) {
        return await _writeFile(df, parsedUri, options);
      }

      switch (scheme) {
        case 'file':
        case '':
          return await _writeFile(df, parsedUri, options);
        case 'sqlite':
        case 'postgresql':
        case 'postgres':
        case 'mysql':
          return await _writeDatabase(df, parsedUri, options);
        default:
          throw DataSourceError(
            'Unsupported URI scheme for writing: ${parsedUri.scheme}',
          );
      }
    } catch (e) {
      if (e is DataSourceError) rethrow;
      throw DataSourceError('Failed to write to URI: $uri', e);
    }
  }

  /// Inspects a data source without loading all data.
  ///
  /// Returns metadata about the source such as size, format, columns, etc.
  ///
  /// ## Example
  /// ```dart
  /// final info = await SmartLoader.inspect('data.csv');
  /// print('Size: ${info['size']} bytes');
  /// print('Format: ${info['format']}');
  ///
  /// final datasets = await SmartLoader.inspect('dataset://');
  /// print('Available datasets: ${datasets['available_datasets']}');
  /// ```
  static Future<Map<String, dynamic>> inspect(String uri) async {
    initialize();

    try {
      final parsedUri = Uri.parse(uri);

      // Try registered data sources first
      final source = DataSourceRegistry.findByUri(parsedUri);
      if (source != null) {
        final result = await source.inspect(parsedUri);
        if (result != null) return result;
      }

      // Fallback inspection
      return {'uri': uri, 'scheme': parsedUri.scheme};
    } catch (e) {
      throw DataSourceError('Failed to inspect URI: $uri', e);
    }
  }

  // Internal loaders

  static Future<DataFrame> _loadHttp(
    Uri uri,
    Map<String, dynamic>? options,
  ) async {
    final source = HttpDataSource();
    return await source.read(uri, options ?? {});
  }

  static Future<DataFrame> _loadFile(
    Uri uri,
    Map<String, dynamic>? options,
  ) async {
    final source = FileDataSource();
    return await source.read(uri, options ?? {});
  }

  static Future<DataFrame> _loadDataset(
    Uri uri,
    Map<String, dynamic>? options,
  ) async {
    final source = ScientificDataSource();
    return await source.read(uri, options ?? {});
  }

  static Future<DataFrame> _loadDatabase(
    Uri uri,
    Map<String, dynamic>? options,
  ) async {
    final source = DatabaseDataSource();
    return await source.read(uri, options ?? {});
  }

  static Future<void> _writeFile(
    DataFrame df,
    Uri uri,
    Map<String, dynamic>? options,
  ) async {
    final source = FileDataSource();
    return await source.write(df, uri, options ?? {});
  }

  static Future<void> _writeDatabase(
    DataFrame df,
    Uri uri,
    Map<String, dynamic>? options,
  ) async {
    final source = DatabaseDataSource();
    return await source.write(df, uri, options ?? {});
  }
}

/// Database data source for SQL databases.
///
/// Handles sqlite://, postgresql://, and mysql:// URI schemes.
///
/// ## URI Format
/// ```
/// scheme://[user:password@]host[:port]/database[?table=name&query=sql]
/// ```
///
/// ## Examples
/// ```dart
/// // SQLite
/// final df = await DataFrame.read('sqlite://path/to/db.sqlite?table=users');
///
/// // PostgreSQL
/// final df = await DataFrame.read(
///   'postgresql://user:pass@localhost:5432/mydb?table=customers'
/// );
///
/// // MySQL with custom query
/// final df = await DataFrame.read(
///   'mysql://user:pass@localhost/mydb?query=SELECT * FROM orders WHERE status="active"'
/// );
/// ```
class DatabaseDataSource extends DataSource {
  @override
  String get scheme => 'database';

  @override
  bool canHandle(Uri uri) {
    return ['sqlite', 'postgresql', 'postgres', 'mysql'].contains(uri.scheme);
  }

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    try {
      final connectionString = _buildConnectionString(uri);
      final table = uri.queryParameters['table'];
      final query = uri.queryParameters['query'];

      if (query != null) {
        return await DatabaseReader.readSqlQuery(query, connectionString);
      } else if (table != null) {
        return await DatabaseReader.readSqlTable(table, connectionString);
      } else {
        throw DataSourceError(
          'Either "table" or "query" parameter is required in database URI',
        );
      }
    } catch (e) {
      if (e is DataSourceError) rethrow;
      throw DataSourceError('Failed to read from database: $uri', e);
    }
  }

  @override
  Future<void> write(
      DataFrame df, Uri uri, Map<String, dynamic> options) async {
    try {
      final connectionString = _buildConnectionString(uri);
      final table = uri.queryParameters['table'];

      if (table == null) {
        throw DataSourceError('Table name is required for database write');
      }

      final ifExists = options['ifExists'] as String? ?? 'fail';
      final index = options['index'] as bool? ?? false;

      await df.toSql(
        table,
        connectionString,
        ifExists: ifExists,
        index: index,
      );
    } catch (e) {
      if (e is DataSourceError) rethrow;
      throw DataSourceError('Failed to write to database: $uri', e);
    }
  }

  String _buildConnectionString(Uri uri) {
    // Reconstruct connection string from URI
    return uri.toString().split('?')[0];
  }
}
