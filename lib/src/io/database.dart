import 'dart:async';
import 'dart:collection';
import 'package:postgres/postgres.dart' as pg;
import 'package:sqlite3/sqlite3.dart' as sqlite;
import '../data_frame/data_frame.dart';

/// Abstract base class for database connections
abstract class DatabaseConnection {
  /// Executes a SQL query and returns a DataFrame
  Future<DataFrame> query(String sql, {List<dynamic>? parameters});

  /// Executes a SQL command (INSERT, UPDATE, DELETE) and returns affected rows
  Future<int> execute(String sql, {List<dynamic>? parameters});

  /// Executes multiple SQL commands in a batch
  Future<List<int>> executeBatch(
      String sql, List<List<dynamic>> parametersList);

  /// Begins a database transaction
  Future<DatabaseTransaction> beginTransaction();

  /// Closes the database connection
  Future<void> close();

  /// Tests if the connection is still active
  Future<bool> isConnected();

  /// Gets the database type (sqlite, postgresql, mysql)
  String get databaseType;
}

/// Represents a database transaction
abstract class DatabaseTransaction {
  /// Executes a SQL query within the transaction
  Future<DataFrame> query(String sql, {List<dynamic>? parameters});

  /// Executes a SQL command within the transaction
  Future<int> execute(String sql, {List<dynamic>? parameters});

  /// Commits the transaction
  Future<void> commit();

  /// Rolls back the transaction
  Future<void> rollback();
}

/// Connection pool for managing database connections
class ConnectionPool {
  final String _connectionString;
  final int _maxConnections;
  final Queue<DatabaseConnection> _availableConnections = Queue();
  final Set<DatabaseConnection> _activeConnections = {};
  bool _isClosed = false;

  ConnectionPool(this._connectionString, {int maxConnections = 5})
      : _maxConnections = maxConnections;

  /// Gets a connection from the pool
  Future<DatabaseConnection> getConnection() async {
    if (_isClosed) {
      throw DatabaseConnectionError('Connection pool is closed');
    }

    // Return available connection if exists
    if (_availableConnections.isNotEmpty) {
      final conn = _availableConnections.removeFirst();
      _activeConnections.add(conn);
      return conn;
    }

    // Create new connection if under limit
    if (_activeConnections.length < _maxConnections) {
      final conn = DatabaseReader.createConnection(_connectionString);
      _activeConnections.add(conn);
      return conn;
    }

    // Wait for a connection to become available
    await Future.delayed(Duration(milliseconds: 100));
    return getConnection();
  }

  /// Returns a connection to the pool
  Future<void> releaseConnection(DatabaseConnection connection) async {
    if (_activeConnections.contains(connection)) {
      _activeConnections.remove(connection);
      if (!_isClosed) {
        _availableConnections.add(connection);
      } else {
        await connection.close();
      }
    }
  }

  /// Closes all connections in the pool
  Future<void> close() async {
    _isClosed = true;

    // Close all available connections
    while (_availableConnections.isNotEmpty) {
      final conn = _availableConnections.removeFirst();
      await conn.close();
    }

    // Close all active connections
    for (final conn in _activeConnections) {
      await conn.close();
    }
    _activeConnections.clear();
  }

  /// Gets the number of active connections
  int get activeConnectionCount => _activeConnections.length;

  /// Gets the number of available connections
  int get availableConnectionCount => _availableConnections.length;
}

/// SQLite database connection implementation using sqlite3 package
class SQLiteConnection implements DatabaseConnection {
  final String _connectionString;
  sqlite.Database? _db;
  bool _isConnected = false;

  SQLiteConnection(this._connectionString);

  @override
  String get databaseType => 'sqlite';

  /// Gets the connection string (useful for debugging)
  String get connectionString => _connectionString;

  /// Connects to the SQLite database
  Future<void> connect() async {
    try {
      if (_connectionString.isEmpty) {
        throw DatabaseConnectionError('Connection string cannot be empty');
      }

      final uri = Uri.parse(_connectionString);
      if (uri.scheme != 'sqlite') {
        throw DatabaseConnectionError(
            'Invalid SQLite connection string: $_connectionString');
      }

      // Extract path from URI
      // For sqlite://example/data/file.db, the host is 'example' and path is '/data/file.db'
      // We need to reconstruct the full path
      String path;

      if (uri.host.isNotEmpty) {
        // URI like sqlite://example/data/file.db
        // host='example', path='/data/file.db'
        path = uri.host + uri.path;
      } else {
        // URI like sqlite:///absolute/path or sqlite://C:/path
        path = uri.path;
        if (path.startsWith('/') && !path.startsWith('//')) {
          // Check if it's a Windows absolute path like /C:/
          if (path.length > 3 && path[2] == ':') {
            path = path.substring(1); // Remove leading slash for C:/path
          } else {
            // It's a Unix absolute path, keep as is
          }
        }
      }

      _db = sqlite.sqlite3.open(path);
      _isConnected = true;
    } catch (e) {
      throw DatabaseConnectionError('Failed to connect to SQLite: $e');
    }
  }

  @override
  Future<DataFrame> query(String sql, {List<dynamic>? parameters}) async {
    if (!_isConnected || _db == null) {
      await connect();
    }

    try {
      final result = _db!.select(sql, parameters ?? []);
      return _sqliteResultToDataFrame(result);
    } catch (e) {
      throw DatabaseQueryError('SQLite query failed: $e');
    }
  }

  @override
  Future<int> execute(String sql, {List<dynamic>? parameters}) async {
    if (!_isConnected || _db == null) {
      await connect();
    }

    try {
      _db!.execute(sql, parameters ?? []);
      return _db!.lastInsertRowId;
    } catch (e) {
      throw DatabaseQueryError('SQLite execute failed: $e');
    }
  }

  @override
  Future<List<int>> executeBatch(
      String sql, List<List<dynamic>> parametersList) async {
    if (!_isConnected || _db == null) {
      await connect();
    }

    try {
      final results = <int>[];
      for (var params in parametersList) {
        _db!.execute(sql, params);
        results.add(_db!.lastInsertRowId);
      }
      return results;
    } catch (e) {
      throw DatabaseQueryError('SQLite batch execute failed: $e');
    }
  }

  @override
  Future<DatabaseTransaction> beginTransaction() async {
    throw UnimplementedError('Transactions not yet implemented for SQLite');
  }

  @override
  Future<void> close() async {
    if (_db != null) {
      _db!.close();
      _db = null;
    }
    _isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    return _isConnected && _db != null;
  }

  DataFrame _sqliteResultToDataFrame(sqlite.ResultSet result) {
    final columns = result.columnNames;
    final data = <String, List<dynamic>>{};

    for (final col in columns) {
      data[col] = [];
    }

    for (final row in result) {
      for (int i = 0; i < columns.length; i++) {
        data[columns[i]]!.add(row[i]);
      }
    }

    return DataFrame.fromMap(data);
  }
}

/// PostgreSQL database connection implementation using postgres package
class PostgreSQLConnection implements DatabaseConnection {
  final String _connectionString;
  pg.Connection? _connection;
  bool _isConnected = false;

  PostgreSQLConnection(this._connectionString);

  @override
  String get databaseType => 'postgresql';

  String get connectionString => _connectionString;

  Future<void> connect() async {
    try {
      if (_connectionString.isEmpty) {
        throw DatabaseConnectionError('Connection string cannot be empty');
      }

      final uri = Uri.parse(_connectionString);
      if (!['postgresql', 'postgres'].contains(uri.scheme)) {
        throw DatabaseConnectionError(
            'Invalid PostgreSQL connection string: $_connectionString');
      }

      // Parse connection details
      final userInfo = uri.userInfo.split(':');
      final username = userInfo.isNotEmpty ? userInfo[0] : 'postgres';
      final password = userInfo.length > 1 ? userInfo[1] : '';
      final database =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'postgres';

      _connection = await pg.Connection.open(
        pg.Endpoint(
          host: uri.host.isEmpty ? 'localhost' : uri.host,
          port: uri.port == 0 ? 5432 : uri.port,
          database: database,
          username: username,
          password: password,
        ),
        settings: pg.ConnectionSettings(
          sslMode: pg.SslMode.disable,
        ),
      );
      _isConnected = true;
    } catch (e) {
      throw DatabaseConnectionError('Failed to connect to PostgreSQL: $e');
    }
  }

  @override
  Future<DataFrame> query(String sql, {List<dynamic>? parameters}) async {
    if (!_isConnected || _connection == null) {
      await connect();
    }

    try {
      final result = await _connection!.execute(sql);
      return _postgresResultToDataFrame(result);
    } catch (e) {
      throw DatabaseQueryError('PostgreSQL query failed: $e');
    }
  }

  @override
  Future<int> execute(String sql, {List<dynamic>? parameters}) async {
    if (!_isConnected || _connection == null) {
      await connect();
    }

    try {
      final result = await _connection!.execute(sql);
      return result.affectedRows;
    } catch (e) {
      throw DatabaseQueryError('PostgreSQL execute failed: $e');
    }
  }

  @override
  Future<List<int>> executeBatch(
      String sql, List<List<dynamic>> parametersList) async {
    if (!_isConnected || _connection == null) {
      await connect();
    }

    try {
      final results = <int>[];
      for (var _ in parametersList) {
        final result = await _connection!.execute(sql);
        results.add(result.affectedRows);
      }
      return results;
    } catch (e) {
      throw DatabaseQueryError('PostgreSQL batch execute failed: $e');
    }
  }

  @override
  Future<DatabaseTransaction> beginTransaction() async {
    throw UnimplementedError('Transactions not yet implemented for PostgreSQL');
  }

  @override
  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
    _isConnected = false;
  }

  @override
  Future<bool> isConnected() async {
    return _isConnected && _connection != null;
  }

  DataFrame _postgresResultToDataFrame(pg.Result result) {
    // Get column names from schema
    final columns = <String>[];
    for (final column in result.schema.columns) {
      columns.add(column.columnName ?? 'column_${columns.length}');
    }

    final data = <String, List<dynamic>>{};

    for (final col in columns) {
      data[col] = [];
    }

    for (final row in result) {
      for (int i = 0; i < columns.length; i++) {
        data[columns[i]]!.add(row[i]);
      }
    }

    return DataFrame.fromMap(data);
  }
}

// /// MySQL database connection implementation using mysql_client package
// class MySQLConnection implements DatabaseConnection {
//   final String _connectionString;
//   mysql.MySQLConnection? _connection;
//   bool _isConnected = false;

//   MySQLConnection(this._connectionString);

//   @override
//   String get databaseType => 'mysql';

//   String get connectionString => _connectionString;

//   Future<void> connect() async {
//     try {
//       if (_connectionString.isEmpty) {
//         throw DatabaseConnectionError('Connection string cannot be empty');
//       }

//       final uri = Uri.parse(_connectionString);
//       if (uri.scheme != 'mysql') {
//         throw DatabaseConnectionError(
//             'Invalid MySQL connection string: $_connectionString');
//       }

//       // Parse connection details
//       final userInfo = uri.userInfo.split(':');
//       final username = userInfo.isNotEmpty ? userInfo[0] : 'root';
//       final password = userInfo.length > 1 ? userInfo[1] : '';
//       final database =
//           uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'mysql';

//       _connection = await mysql.MySQLConnection.createConnection(
//         host: uri.host.isEmpty ? 'localhost' : uri.host,
//         port: uri.port == 0 ? 3306 : uri.port,
//         userName: username,
//         password: password,
//         databaseName: database,
//       );

//       await _connection!.connect();
//       _isConnected = true;
//     } catch (e) {
//       throw DatabaseConnectionError('Failed to connect to MySQL: $e');
//     }
//   }

//   @override
//   Future<DataFrame> query(String sql, {List<dynamic>? parameters}) async {
//     if (!_isConnected || _connection == null) {
//       await connect();
//     }

//     try {
//       final result = await _connection!.execute(sql);
//       return _mysqlResultToDataFrame(result);
//     } catch (e) {
//       throw DatabaseQueryError('MySQL query failed: $e');
//     }
//   }

//   @override
//   Future<int> execute(String sql, {List<dynamic>? parameters}) async {
//     if (!_isConnected || _connection == null) {
//       await connect();
//     }

//     try {
//       final result = await _connection!.execute(sql);
//       return result.affectedRows.toInt();
//     } catch (e) {
//       throw DatabaseQueryError('MySQL execute failed: $e');
//     }
//   }

//   @override
//   Future<List<int>> executeBatch(
//       String sql, List<List<dynamic>> parametersList) async {
//     if (!_isConnected || _connection == null) {
//       await connect();
//     }

//     try {
//       final results = <int>[];
//       for (var _ in parametersList) {
//         final result = await _connection!.execute(sql);
//         results.add(result.affectedRows.toInt());
//       }
//       return results;
//     } catch (e) {
//       throw DatabaseQueryError('MySQL batch execute failed: $e');
//     }
//   }

//   @override
//   Future<DatabaseTransaction> beginTransaction() async {
//     throw UnimplementedError('Transactions not yet implemented for MySQL');
//   }

//   @override
//   Future<void> close() async {
//     if (_connection != null) {
//       await _connection!.close();
//       _connection = null;
//     }
//     _isConnected = false;
//   }

//   @override
//   Future<bool> isConnected() async {
//     return _isConnected && _connection != null;
//   }

//   DataFrame _mysqlResultToDataFrame(mysql.IResultSet result) {
//     final columns = result.cols.map((col) => col.name).toList();
//     final data = <String, List<dynamic>>{};

//     for (final col in columns) {
//       data[col] = [];
//     }

//     for (final row in result.rows) {
//       for (int i = 0; i < columns.length; i++) {
//         data[columns[i]]!.add(row.colAt(i));
//       }
//     }

//     return DataFrame.fromMap(data);
//   }
// }

/// Database reader and writer utility class
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
      // case 'mysql':
      //   return MySQLConnection(connectionString);
      default:
        throw UnsupportedDatabaseError(
            'Unsupported database type: ${uri.scheme}');
    }
  }

  /// Reads SQL query results into a DataFrame (pandas-like read_sql_query)
  static Future<DataFrame> readSqlQuery(String sql, String connectionString,
      {List<dynamic>? parameters}) async {
    final connection = createConnection(connectionString);
    try {
      return await connection.query(sql, parameters: parameters);
    } finally {
      await connection.close();
    }
  }

  /// Reads an entire SQL table into a DataFrame (pandas-like read_sql_table)
  static Future<DataFrame> readSqlTable(
      String tableName, String connectionString,
      {List<String>? columns,
      String? whereClause,
      int? limit,
      int? offset}) async {
    final columnList = columns?.join(', ') ?? '*';
    String sql = 'SELECT $columnList FROM $tableName';

    if (whereClause != null) {
      sql += ' WHERE $whereClause';
    }

    if (limit != null) {
      sql += ' LIMIT $limit';
    }

    if (offset != null) {
      sql += ' OFFSET $offset';
    }

    return readSqlQuery(sql, connectionString);
  }

  /// Convenience alias for readSqlQuery
  static Future<DataFrame> readSql(String sql, String connectionString,
      {List<dynamic>? parameters}) {
    return readSqlQuery(sql, connectionString, parameters: parameters);
  }

  /// Convenience alias for readSqlTable
  static Future<DataFrame> readTable(String tableName, String connectionString,
      {List<String>? columns, String? whereClause, int? limit}) {
    return readSqlTable(tableName, connectionString,
        columns: columns, whereClause: whereClause, limit: limit);
  }
}

/// Extension to add database write capabilities to DataFrame
extension DataFrameDatabase on DataFrame {
  /// Writes DataFrame to SQL database table (pandas-like to_sql)
  Future<void> toSql(
    String tableName,
    String connectionString, {
    String ifExists = 'fail',
    bool index = false,
    String? indexLabel,
    int? chunkSize,
    Map<String, String>? dtype,
  }) async {
    if (!['fail', 'replace', 'append'].contains(ifExists)) {
      throw ArgumentError('ifExists must be one of: fail, replace, append');
    }

    final connection = DatabaseReader.createConnection(connectionString);
    try {
      // Check if table exists
      final tableExists = await _tableExists(connection, tableName);

      if (tableExists) {
        if (ifExists == 'fail') {
          throw DatabaseQueryError('Table $tableName already exists');
        } else if (ifExists == 'replace') {
          await connection.execute('DROP TABLE IF EXISTS $tableName');
          await _createTable(connection, tableName, dtype);
        }
      } else {
        await _createTable(connection, tableName, dtype);
      }

      // Insert data
      await _insertData(connection, tableName, index, indexLabel, chunkSize);
    } finally {
      await connection.close();
    }
  }

  Future<bool> _tableExists(
      DatabaseConnection connection, String tableName) async {
    try {
      String sql;
      switch (connection.databaseType) {
        case 'sqlite':
          sql =
              "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'";
          break;
        case 'postgresql':
          sql = "SELECT tablename FROM pg_tables WHERE tablename='$tableName'";
          break;
        case 'mysql':
          sql = "SHOW TABLES LIKE '$tableName'";
          break;
        default:
          return false;
      }

      final result = await connection.query(sql);
      return result.shape.rows > 0;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createTable(DatabaseConnection connection, String tableName,
      Map<String, String>? dtype) async {
    final columnDefs = <String>[];

    for (final column in columns) {
      String sqlType;
      if (dtype != null && dtype.containsKey(column)) {
        sqlType = dtype[column]!;
      } else {
        sqlType = _inferSqlType(this[column].toList(), connection.databaseType);
      }
      columnDefs.add('$column $sqlType');
    }

    final sql = 'CREATE TABLE $tableName (${columnDefs.join(', ')})';
    await connection.execute(sql);
  }

  String _inferSqlType(List<dynamic> values, String dbType) {
    if (values.isEmpty) return 'TEXT';

    final sample = values.firstWhere((v) => v != null, orElse: () => null);
    if (sample == null) return 'TEXT';

    if (sample is int) {
      return dbType == 'postgresql' ? 'INTEGER' : 'INT';
    } else if (sample is double) {
      return dbType == 'postgresql' ? 'DOUBLE PRECISION' : 'REAL';
    } else if (sample is bool) {
      return dbType == 'mysql' ? 'TINYINT(1)' : 'BOOLEAN';
    } else if (sample is DateTime) {
      return 'TIMESTAMP';
    } else {
      return 'TEXT';
    }
  }

  Future<void> _insertData(DatabaseConnection connection, String tableName,
      bool includeIndex, String? indexLabel, int? chunkSize) async {
    final cols = <String>[];
    if (includeIndex) {
      cols.add(indexLabel ?? 'index');
    }
    cols.addAll(columns.cast<String>());

    final placeholders = List.generate(cols.length, (i) => '?').join(', ');
    final sql =
        'INSERT INTO $tableName (${cols.join(', ')}) VALUES ($placeholders)';

    final batchSize = chunkSize ?? 1000;
    final rowCount = shape.rows;

    for (int start = 0; start < rowCount; start += batchSize) {
      final end = (start + batchSize < rowCount) ? start + batchSize : rowCount;
      final batch = <List<dynamic>>[];

      for (int i = start; i < end; i++) {
        final row = <dynamic>[];
        if (includeIndex) {
          row.add(index[i]);
        }
        for (final col in columns) {
          row.add(this[col][i]);
        }
        batch.add(row);
      }

      await connection.executeBatch(sql, batch);
    }
  }
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

/// Exception thrown when database transaction fails
class DatabaseTransactionError extends Error {
  final String message;
  DatabaseTransactionError(this.message);

  @override
  String toString() => 'DatabaseTransactionError: $message';
}

/// Exception thrown when database type is not supported
class UnsupportedDatabaseError extends Error {
  final String message;
  UnsupportedDatabaseError(this.message);

  @override
  String toString() => 'UnsupportedDatabaseError: $message';
}
