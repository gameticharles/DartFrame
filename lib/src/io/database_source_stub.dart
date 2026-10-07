import 'dart:async';
import '../data_frame/data_frame.dart';
import 'data_source.dart';

/// Database data source stub for Web environments where native SQL drivers are unavailable.
class DatabaseDataSource extends DataSource {
  @override
  String get scheme => 'database';

  @override
  bool canHandle(Uri uri) {
    return ['sqlite', 'postgresql', 'postgres', 'mysql'].contains(uri.scheme);
  }

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    throw UnsupportedError(
      'Database connections (${uri.scheme}://) are not supported on the Web platform. '
      'Consider fetching data via an HTTP REST API or backend service instead.',
    );
  }

  @override
  Future<void> write(
      DataFrame df, Uri uri, Map<String, dynamic> options) async {
    throw UnsupportedError(
      'Database connections (${uri.scheme}://) are not supported on the Web platform.',
    );
  }
}
