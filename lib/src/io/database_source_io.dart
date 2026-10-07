import 'dart:async';
import '../data_frame/data_frame.dart';
import 'data_source.dart';
import 'database.dart';

/// Database data source for native platforms (Desktop, Mobile, Server).
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
    return uri.toString().split('?')[0];
  }
}
