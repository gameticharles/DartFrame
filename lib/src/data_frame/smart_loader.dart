part of 'data_frame.dart';

/// Extension to add smart loading capabilities to DataFrame.
///
/// This extension adds the `write` instance method and static `read` method
/// to DataFrame, providing a pandas-like API for loading and saving data.
///
/// ## Example
/// ```dart
/// // Load from various sources
/// final df1 = await DataFrame.read('data.csv');
/// final df2 = await DataFrame.read('https://example.com/data.json');
/// final df3 = await DataFrame.read('dataset://iris');
///
/// // Write to various destinations
/// await df.write('output.csv');
/// await df.write('output.json', options: {'orient': 'records'});
/// ```
extension DataFrameSmartLoader on DataFrame {
  /// Reads data from a URI and returns a DataFrame.
  ///
  /// This static method provides a pandas-like API for loading data from
  /// various sources with automatic source detection.
  ///
  /// ## Supported Sources
  /// - Local files: `'data.csv'`, `'file:///path/to/data.json'`
  /// - HTTP/HTTPS: `'https://example.com/data.csv'`
  /// - Scientific datasets: `'dataset://iris'`, `'dataset://mnist/train'`
  /// - Databases: `'sqlite://db.sqlite?table=users'`
  ///
  /// ## Parameters
  /// - `uri`: URI string or path to the data source
  /// - `options`: Source-specific and format-specific options
  ///
  /// ## Example
  /// ```dart
  /// // Local file
  /// final df = await DataFrame.read('data.csv');
  ///
  /// // HTTP URL
  /// final df = await DataFrame.read('https://example.com/data.json');
  ///
  /// // Scientific dataset
  /// final df = await DataFrame.read('dataset://iris');
  ///
  /// // Database
  /// final df = await DataFrame.read('sqlite://db.sqlite?table=users');
  ///
  /// // With options
  /// final df = await DataFrame.read('data.csv', options: {
  ///   'fieldDelimiter': ';',
  ///   'skipRows': 1,
  /// });
  /// ```
  static Future<DataFrame> read(
    String uri, {
    Map<String, dynamic>? options,
  }) async {
    return await SmartLoader.read(uri, options: options);
  }

  /// Writes this DataFrame to a URI.
  ///
  /// This instance method writes the current DataFrame to the specified
  /// destination with automatic format detection.
  ///
  /// ## Parameters
  /// - `uri`: URI string or path to the destination
  /// - `options`: Destination-specific and format-specific options
  ///
  /// ## Example
  /// ```dart
  /// final df = DataFrame.fromMap({'a': [1, 2], 'b': [3, 4]});
  ///
  /// // Write to CSV
  /// await df.write('output.csv');
  ///
  /// // Write to JSON with options
  /// await df.write('output.json', options: {
  ///   'orient': 'records',
  /// });
  ///
  /// // Write to database
  /// await df.write('sqlite://db.sqlite?table=users', options: {
  ///   'ifExists': 'replace',
  /// });
  /// ```
  Future<void> write(String uri, {Map<String, dynamic>? options}) async {
    return await SmartLoader.write(this, uri, options: options);
  }

  /// Inspects a data source without loading all data.
  ///
  /// Returns metadata about the source such as size, format, columns, etc.
  ///
  /// ## Example
  /// ```dart
  /// final info = await DataFrame.inspect('data.csv');
  /// print('Size: ${info['size']} bytes');
  /// print('Format: ${info['format']}');
  /// ```
  static Future<Map<String, dynamic>> inspect(String uri) async {
    return await SmartLoader.inspect(uri);
  }
}
