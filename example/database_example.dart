import 'package:dartframe/dartframe.dart';

void main() async {
  print('=== DartFrame Database Operations Examples ===\n');

  // Example 1: Basic SQL Query
  print('1. Basic SQL Query (read_sql_query):');
  print('=' * 50);
  try {
    final df = await DatabaseReader.readSqlQuery(
      'SELECT * FROM users WHERE age > ?',
      'sqlite://path/to/database.db',
      parameters: [18],
    );
    print('Query result:');
    print(df);
  } catch (e) {
    print('Note: This is a mock example. In production, use actual database.');
  }
  print('');

  // Example 2: Read Entire Table
  print('2. Read Entire Table (read_sql_table):');
  print('=' * 50);
  try {
    final df = await DatabaseReader.readSqlTable(
      'products',
      'postgresql://user:pass@localhost:5432/mydb',
      columns: ['id', 'name', 'price'],
      whereClause: 'price > 100',
      limit: 10,
    );
    print('Table data:');
    print(df);
  } catch (e) {
    print('Note: This is a mock example.');
  }
  print('');

  // Example 3: Write DataFrame to Database
  print('3. Write DataFrame to Database (to_sql):');
  print('=' * 50);
  final df = DataFrame([
    [1, 'Alice', 25, 50000.0],
    [2, 'Bob', 30, 60000.0],
    [3, 'Charlie', 35, 70000.0],
  ], columns: [
    'id',
    'name',
    'age',
    'salary'
  ]);

  print('DataFrame to write:');
  print(df);
  print('');

  try {
    await df.toSql(
      'employees',
      'sqlite://path/to/database.db',
      ifExists: 'replace', // Options: 'fail', 'replace', 'append'
      chunkSize: 1000, // Batch insert 1000 rows at a time
    );
    print('✓ Data written to database successfully');
  } catch (e) {
    print('Note: This is a mock example.');
  }
  print('');

  // Example 4: Connection Pooling
  print('4. Connection Pooling:');
  print('=' * 50);
  final pool = ConnectionPool(
    'postgresql://user:pass@localhost:5432/mydb',
    maxConnections: 5,
  );

  try {
    // Get connection from pool
    final conn = await pool.getConnection();
    print('✓ Got connection from pool');
    print('Active connections: ${pool.activeConnectionCount}');

    // Use connection
    final result = await conn.query('SELECT * FROM users LIMIT 5');
    print('Query executed: ${result.shape.columns} rows returned');

    // Return connection to pool
    await pool.releaseConnection(conn);
    print('✓ Connection returned to pool');
    print('Available connections: ${pool.availableConnectionCount}');
  } catch (e) {
    print('Note: This is a mock example.');
  } finally {
    await pool.close();
    print('✓ Pool closed');
  }
  print('');

  // Example 5: Transactions
  print('5. Database Transactions:');
  print('=' * 50);
  final connection = DatabaseReader.createConnection(
    'sqlite://path/to/database.db',
  );

  try {
    // Begin transaction
    final transaction = await connection.beginTransaction();
    print('✓ Transaction started');

    try {
      // Execute multiple operations
      await transaction.execute(
        'INSERT INTO accounts (name, balance) VALUES (?, ?)',
        parameters: ['Alice', 1000],
      );
      print('✓ Inserted Alice');

      await transaction.execute(
        'UPDATE accounts SET balance = balance - ? WHERE name = ?',
        parameters: [100, 'Alice'],
      );
      print('✓ Updated Alice balance');

      await transaction.execute(
        'UPDATE accounts SET balance = balance + ? WHERE name = ?',
        parameters: [100, 'Bob'],
      );
      print('✓ Updated Bob balance');

      // Commit transaction
      await transaction.commit();
      print('✓ Transaction committed successfully');
    } catch (e) {
      // Rollback on error
      await transaction.rollback();
      print('✗ Transaction rolled back due to error: $e');
    }
  } catch (e) {
    print('Note: This is a mock example.');
  } finally {
    await connection.close();
  }
  print('');

  // Example 6: Batch Inserts
  print('6. Batch Inserts:');
  print('=' * 50);
  final batchConnection = DatabaseReader.createConnection(
    'mysql://user:pass@localhost:3306/mydb',
  );

  try {
    final sql = 'INSERT INTO logs (timestamp, message, level) VALUES (?, ?, ?)';
    final batches = [
      [DateTime.now(), 'Application started', 'INFO'],
      [DateTime.now(), 'User logged in', 'INFO'],
      [DateTime.now(), 'Error occurred', 'ERROR'],
      [DateTime.now(), 'Warning detected', 'WARN'],
      [DateTime.now(), 'Debug message', 'DEBUG'],
    ];

    final results = await batchConnection.executeBatch(sql, batches);
    print('✓ Batch insert completed');
    print('Rows affected: ${results.reduce((a, b) => a + b)}');
  } catch (e) {
    print('Note: This is a mock example.');
  } finally {
    await batchConnection.close();
  }
  print('');

  // Example 7: Parameterized Queries
  print('7. Parameterized Queries (SQL Injection Prevention):');
  print('=' * 50);
  try {
    // Safe parameterized query
    final safeQuery = await DatabaseReader.readSqlQuery(
      'SELECT * FROM users WHERE username = ? AND age > ?',
      'sqlite://path/to/database.db',
      parameters: ['john_doe', 18],
    );
    print('✓ Safe parameterized query executed');
    print('Result: ${safeQuery.shape}');
  } catch (e) {
    print('Note: This is a mock example.');
  }
  print('');

  // Example 8: Custom Data Types
  print('8. Custom Data Types in to_sql:');
  print('=' * 50);
  final customDf = DataFrame([
    [1, 'Product A', 99.99, true, DateTime.now()],
    [2, 'Product B', 149.99, false, DateTime.now()],
  ], columns: [
    'id',
    'name',
    'price',
    'in_stock',
    'created_at'
  ]);

  try {
    await customDf.toSql(
      'products',
      'postgresql://user:pass@localhost:5432/mydb',
      ifExists: 'replace',
      dtype: {
        'id': 'SERIAL PRIMARY KEY',
        'name': 'VARCHAR(255)',
        'price': 'DECIMAL(10,2)',
        'in_stock': 'BOOLEAN',
        'created_at': 'TIMESTAMP',
      },
    );
    print('✓ Table created with custom data types');
  } catch (e) {
    print('Note: This is a mock example.');
  }
  print('');

  // Example 9: Multiple Database Types
  print('9. Working with Multiple Database Types:');
  print('=' * 50);

  // SQLite
  print('SQLite:');
  final sqliteConn = SQLiteConnection('sqlite://local.db');
  print('  Database type: ${sqliteConn.databaseType}');

  // PostgreSQL
  print('PostgreSQL:');
  final pgConn =
      PostgreSQLConnection('postgresql://user:pass@localhost:5432/mydb');
  print('  Database type: ${pgConn.databaseType}');

  // MySQL
  print('MySQL:');
  final mysqlConn = MySQLConnection('mysql://user:pass@localhost:3306/mydb');
  print('  Database type: ${mysqlConn.databaseType}');

  await sqliteConn.close();
  await pgConn.close();
  await mysqlConn.close();
  print('');

  // Example 10: Error Handling
  print('10. Error Handling:');
  print('=' * 50);
  try {
    // Attempt to write to existing table with ifExists='fail'
    await df.toSql(
      'existing_table',
      'sqlite://path/to/database.db',
      ifExists: 'fail',
    );
  } catch (e) {
    if (e is DatabaseQueryError) {
      print('✓ Caught DatabaseQueryError: ${e.message}');
    }
  }

  try {
    // Invalid connection string
    //final invalidConn = DatabaseReader.createConnection('invalid://connection');
  } catch (e) {
    if (e is UnsupportedDatabaseError) {
      print('✓ Caught UnsupportedDatabaseError: ${e.message}');
    }
  }
  print('');

  print('=== Database Operations Examples Complete ===');
  print('');
  print('Key Features Demonstrated:');
  print('✓ read_sql_query() - Execute SQL queries');
  print('✓ read_sql_table() - Read entire tables');
  print('✓ to_sql() - Write DataFrames to database');
  print('✓ Connection pooling - Efficient connection management');
  print('✓ Transactions - ACID compliance');
  print('✓ Batch inserts - High-performance bulk operations');
  print('✓ Parameterized queries - SQL injection prevention');
  print('✓ Multiple database support - SQLite, PostgreSQL, MySQL');
  print('✓ Custom data types - Fine-grained schema control');
  print('✓ Error handling - Comprehensive exception management');
}
