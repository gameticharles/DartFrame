import 'dart:async';
import '../data_frame/data_frame.dart';

/// Abstract base class for database connections
abstract class DatabaseConnection {
  /// Executes a SQL query and returns a DataFrame
  Future<DataFrame> query(String sql, {List<dynamic>? parameters});

  /// Closes the database connection
  Future<void> close();

  /// Tests if the connection is still active
  Future<bool> isConnected();
}

/// SQLite database connection implementation
class SQLiteConnection implements DatabaseConnection {
  final String _connectionString;
  bool _isConnected = false;

  SQLiteConnection(this._connectionString);

  /// Gets the connection string (useful for debugging)
  String get connectionString => _connectionString;

  /// Connects to the SQLite database
  Future<void> connect() async {
    try {
      // In a real implementation, this would use the sqflite package
      // For now, we'll simulate the connection using the connection string
      if (_connectionString.isEmpty) {
        throw DatabaseConnectionError('Connection string cannot be empty');
      }

      // Validate SQLite connection string format
      final uri = Uri.parse(_connectionString);
      if (uri.scheme != 'sqlite') {
        throw DatabaseConnectionError(
            'Invalid SQLite connection string: $_connectionString');
      }

      _isConnected = true;
    } catch (e) {
      throw DatabaseConnectionError('Failed to connect to SQLite: $e');
    }
  }

  @override
  Future<DataFrame> query(String sql, {List<dynamic>? parameters}) async {
    if (!_isConnected) {
      await connect();
    }

    try {
      // Simulate SQL query execution
      // In practice, this would use a real SQLite driver
      final result = await _executeSQLiteQuery(sql, parameters);
      return _resultToDataFrame(result);
    } catch (e) {
      throw DatabaseQueryError('SQLite query failed: $e');
    }
  }

  @override
  Future<void> close() async {
    _isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    return _isConnected;
  }

  Future<Map<String, dynamic>> _executeSQLiteQuery(
      String sql, List<dynamic>? parameters) async {
    // This is a mock implementation
    // In practice, you'd use sqflite or similar package
    return {
      'columns': ['id', 'name', 'value'],
      'rows': [
        [1, 'Sample', 100.0],
        [2, 'Data', 200.0],
        [3, 'Row', 300.0],
      ]
    };
  }
}

/// PostgreSQL database connection implementation
class PostgreSQLConnection implements DatabaseConnection {
  final String _connectionString;
  bool _isConnected = false;

  PostgreSQLConnection(this._connectionString);

  /// Gets the connection string (useful for debugging)
  String get connectionString => _connectionString;

  /// Connects to the PostgreSQL database
  Future<void> connect() async {
    try {
      // In a real implementation, this would use the postgres package
      if (_connectionString.isEmpty) {
        throw DatabaseConnectionError('Connection string cannot be empty');
      }

      // Validate PostgreSQL connection string format
      final uri = Uri.parse(_connectionString);
      if (!['postgresql', 'postgres'].contains(uri.scheme)) {
        throw DatabaseConnectionError(
            'Invalid PostgreSQL connection string: $_connectionString');
      }

      // In practice, you would parse the connection string and connect:
      // final host = uri.host;
      // final port = uri.port;
      // final database = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'postgres';

      _isConnected = true;
    } catch (e) {
      throw DatabaseConnectionError('Failed to connect to PostgreSQL: $e');
    }
  }

  @override
  Future<DataFrame> query(String sql, {List<dynamic>? parameters}) async {
    if (!_isConnected) {
      await connect();
    }

    try {
      final result = await _executePostgreSQLQuery(sql, parameters);
      return _resultToDataFrame(result);
    } catch (e) {
      throw DatabaseQueryError('PostgreSQL query failed: $e');
    }
  }

  @override
  Future<void> close() async {
    _isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    return _isConnected;
  }

  Future<Map<String, dynamic>> _executePostgreSQLQuery(
      String sql, List<dynamic>? parameters) async {
    // Mock implementation - would use postgres package in practice
    return {
      'columns': ['id', 'name', 'value', 'created_at'],
      'rows': [
        [1, 'PostgreSQL Sample', 150.0, DateTime.now()],
        [2, 'Database Data', 250.0, DateTime.now()],
        [3, 'Query Result', 350.0, DateTime.now()],
      ]
    };
  }
}

/// MySQL database connection implementation
class MySQLConnection implements DatabaseConnection {
  final String _connectionString;
  bool _isConnected = false;

  MySQLConnection(this._connectionString);

  /// Gets the connection string (useful for debugging)
  String get connectionString => _connectionString;

  /// Connects to the MySQL database
  Future<void> connect() async {
    try {
      // In a real implementation, this would use the mysql1 package
      if (_connectionString.isEmpty) {
        throw DatabaseConnectionError('Connection string cannot be empty');
      }

      // Validate MySQL connection string format
      final uri = Uri.parse(_connectionString);
      if (uri.scheme != 'mysql') {
        throw DatabaseConnectionError(
            'Invalid MySQL connection string: $_connectionString');
      }

      // In practice, you would parse the connection string and connect:
      // final host = uri.host;
      // final port = uri.port;
      // final database = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'mysql';

      _isConnected = true;
    } catch (e) {
      throw DatabaseConnectionError('Failed to connect to MySQL: $e');
    }
  }

  @override
  Future<DataFrame> query(String sql, {List<dynamic>? parameters}) async {
    if (!_isConnected) {
      await connect();
    }

    try {
      final result = await _executeMySQLQuery(sql, parameters);
      return _resultToDataFrame(result);
    } catch (e) {
      throw DatabaseQueryError('MySQL query failed: $e');
    }
  }

  @override
  Future<void> close() async {
    _isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    return _isConnected;
  }

  Future<Map<String, dynamic>> _executeMySQLQuery(
      String sql, List<dynamic>? parameters) async {
    // Mock implementation - would use mysql1 package in practice
    return {
      'columns': ['id', 'name', 'value', 'status'],
      'rows': [
        [1, 'MySQL Sample', 120.0, 'active'],
        [2, 'Database Entry', 220.0, 'inactive'],
        [3, 'Test Record', 320.0, 'active'],
      ]
    };
  }
}

/// Database reader utility class
class DatabaseReader {
  /// Creates a database connection based on the connection string
  static DatabaseConnection createConnection(String connectionString) {
    final uri = Uri.parse(connectionString);

    switch (uri.scheme.toLowerCase()) {
      case 'sqlite':
        return SQLiteConnection(connectionString);
      case 'postgresql':
      case 'postgres':
        return PostgreSQLConnection(connectionString);
      case 'mysql':
        return MySQLConnection(connectionString);
      default:
        throw UnsupportedDatabaseError(
            'Unsupported database type: ${uri.scheme}');
    }
  }

  /// Convenience method to execute a query and return a DataFrame
  static Future<DataFrame> readSql(String sql, String connectionString,
      {List<dynamic>? parameters}) async {
    final connection = createConnection(connectionString);
    try {
      return await connection.query(sql, parameters: parameters);
    } finally {
      await connection.close();
    }
  }

  /// Reads an entire table as a DataFrame
  static Future<DataFrame> readTable(String tableName, String connectionString,
      {List<String>? columns, String? whereClause, int? limit}) async {
    final columnList = columns?.join(', ') ?? '*';
    String sql = 'SELECT $columnList FROM $tableName';

    if (whereClause != null) {
      sql += ' WHERE $whereClause';
    }

    if (limit != null) {
      sql += ' LIMIT $limit';
    }

    return readSql(sql, connectionString);
  }
}

/// Converts database query results to DataFrame
DataFrame _resultToDataFrame(Map<String, dynamic> result) {
  final columns = result['columns'] as List<String>;
  final rows = result['rows'] as List<List<dynamic>>;

  final data = <String, List<dynamic>>{};

  // Initialize columns
  for (final column in columns) {
    data[column] = <dynamic>[];
  }

  // Populate data
  for (final row in rows) {
    for (int i = 0; i < columns.length && i < row.length; i++) {
      data[columns[i]]!.add(row[i]);
    }
  }

  return DataFrame.fromMap(data);
}

/// Exception thrown when database connection fails
class DatabaseConnectionError extends Error {
  final String message;
  DatabaseConnectionError(this.message);

  @override
  String toString() => 'DatabaseConnectionError: $message';
}

/// Exception thrown when database query fails
class DatabaseQueryError extends Error {
  final String message;
  DatabaseQueryError(this.message);

  @override
  String toString() => 'DatabaseQueryError: $message';
}

/// Exception thrown when database type is not supported
class UnsupportedDatabaseError extends Error {
  final String message;
  UnsupportedDatabaseError(this.message);

  @override
  String toString() => 'UnsupportedDatabaseError: $message';
}
