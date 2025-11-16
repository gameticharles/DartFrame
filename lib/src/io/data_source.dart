import 'dart:async';
import '../data_frame/data_frame.dart';

/// Abstract base class for data sources.
///
/// This interface defines the contract for all data source implementations,
/// enabling a plugin-like architecture where new data sources can be registered
/// and used seamlessly through the SmartLoader.
///
/// ## Implementing a Custom Data Source
/// ```dart
/// class MyCustomSource extends DataSource {
///   @override
///   String get scheme => 'custom';
///
///   @override
///   bool canHandle(Uri uri) => uri.scheme == 'custom';
///
///   @override
///   Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
///     // Your implementation
///   }
///
///   @override
///   Future<void> write(DataFrame df, Uri uri, Map<String, dynamic> options) async {
///     // Your implementation
///   }
/// }
///
/// // Register it
/// DataSourceRegistry.register(MyCustomSource());
/// ```
abstract class DataSource {
  /// The URI scheme this data source handles (e.g., 'http', 's3', 'postgresql')
  String get scheme;

  /// Checks if this data source can handle the given URI
  bool canHandle(Uri uri);

  /// Reads data from the source and returns a DataFrame
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options);

  /// Writes a DataFrame to the source
  Future<void> write(DataFrame df, Uri uri, Map<String, dynamic> options);

  /// Optional: Returns metadata about the source without reading all data
  Future<Map<String, dynamic>>? inspect(Uri uri) => null;
}

/// Registry for managing data source implementations.
///
/// This singleton class maintains a registry of all available data sources
/// and provides methods to register new sources and find appropriate handlers
/// for URIs.
///
/// ## Example
/// ```dart
/// // Register a custom source
/// DataSourceRegistry.register(S3DataSource());
///
/// // Find handler for a URI
/// final source = DataSourceRegistry.findByUri(Uri.parse('s3://bucket/data.csv'));
/// if (source != null) {
///   final df = await source.read(uri, {});
/// }
/// ```
class DataSourceRegistry {
  static final Map<String, DataSource> _sources = {};
  static final List<DataSource> _customSources = [];

  /// Registers a new data source
  static void register(DataSource source) {
    _sources[source.scheme] = source;
    if (!_customSources.contains(source)) {
      _customSources.add(source);
    }
  }

  /// Unregisters a data source by scheme
  static void unregister(String scheme) {
    final source = _sources.remove(scheme);
    if (source != null) {
      _customSources.remove(source);
    }
  }

  /// Finds a data source that can handle the given URI
  static DataSource? findByUri(Uri uri) {
    // First check registered sources by scheme
    final source = _sources[uri.scheme];
    if (source != null && source.canHandle(uri)) {
      return source;
    }

    // Then check custom sources
    for (final source in _customSources) {
      if (source.canHandle(uri)) {
        return source;
      }
    }

    return null;
  }

  /// Gets a data source by scheme
  static DataSource? getByScheme(String scheme) {
    return _sources[scheme];
  }

  /// Lists all registered schemes
  static List<String> listSchemes() {
    return _sources.keys.toList();
  }

  /// Clears all registered sources (useful for testing)
  static void clear() {
    _sources.clear();
    _customSources.clear();
  }
}

/// Exception thrown when a data source operation fails
class DataSourceError extends Error {
  final String message;
  final dynamic cause;

  DataSourceError(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'DataSourceError: $message\nCaused by: $cause';
    }
    return 'DataSourceError: $message';
  }
}
