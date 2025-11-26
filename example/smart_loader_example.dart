import 'package:dartframe/dartframe.dart';

/// Comprehensive examples of SmartLoader functionality.
///
/// This example demonstrates:
/// 1. Loading from various sources (files, HTTP, datasets, databases)
/// 2. Writing to various destinations
/// 3. Using the DataFrame.read() convenience method
/// 4. Working with scientific datasets
/// 5. Custom data source registration
/// 6. Inspecting data sources

Future<void> main() async {
  print('=== SmartLoader Examples ===\n');

  // Example 1: Loading from local files
  await example1LocalFiles();

  // Example 2: Loading from HTTP URLs
  await example2HttpUrls();

  // Example 3: Loading scientific datasets
  await example3ScientificDatasets();

  // Example 4: Loading from databases
  await example4Databases();

  // Example 5: Writing data
  await example5Writing();

  // Example 6: Inspecting data sources
  await example6Inspection();

  // Example 7: Custom data sources
  await example7CustomSources();
}

/// Example 1: Loading from local files
Future<void> example1LocalFiles() async {
  print('--- Example 1: Local Files ---');

  try {
    // Load CSV file
    final df1 = await DataFrame.read('data.csv');
    print('Loaded CSV: ${df1.shape}');

    // Load JSON file
    final df2 = await DataFrame.read('data.json');
    print('Loaded JSON: ${df2.shape}');

    // Load Excel file
    final df3 = await DataFrame.read('data.xlsx', options: {
      'sheetName': 'Sheet1',
    });
    print('Loaded Excel: ${df3.shape}');

    // Load with file:// URI
    final df4 = await DataFrame.read('file:///path/to/data.csv');
    print('Loaded with file URI: ${df4.shape}');

    // Load with options
    final df5 = await DataFrame.read('data.csv', options: {
      'fieldDelimiter': ';',
      'hasHeader': true,
      'skipRows': 1,
      'maxRows': 100,
    });
    print('Loaded CSV with options: ${df5.shape}');
  } catch (e) {
    print('Note: Files not found (expected in example): $e');
  }

  print('');
}

/// Example 2: Loading from HTTP URLs
Future<void> example2HttpUrls() async {
  print('--- Example 2: HTTP URLs ---');

  try {
    // Load CSV from URL
    final df1 = await DataFrame.read(
      'https://raw.githubusercontent.com/mwaskom/seaborn-data/master/iris.csv',
    );
    print('Loaded Iris from URL: ${df1.shape}');
    print('Columns: ${df1.columns}');
    print('First 3 rows:');
    print(df1.head(3));

    // Load JSON from API
    final df2 = await DataFrame.read(
      'https://jsonplaceholder.typicode.com/users',
      options: {'orient': 'records'},
    );
    print('\nLoaded users from API: ${df2.shape}');

    // Load with custom headers
    final df3 = await DataFrame.read(
      'https://api.example.com/data.csv',
      options: {
        'headers': {
          'Authorization': 'Bearer YOUR_TOKEN',
          'Accept': 'text/csv',
        },
        'timeout': 30,
      },
    );
    print('Loaded with auth: ${df3.shape}');
  } catch (e) {
    print('HTTP load example (may fail without internet): $e');
  }

  print('');
}

/// Example 3: Loading scientific datasets
Future<void> example3ScientificDatasets() async {
  print('--- Example 3: Scientific Datasets ---');

  try {
    // List available datasets
    print('Available datasets:');
    final datasets = ScientificDatasets.listDatasetsWithDescriptions();
    datasets.forEach((name, desc) {
      print('  - $name: $desc');
    });

    // Load Iris dataset
    print('\nLoading Iris dataset...');
    final iris = await DataFrame.read('dataset://iris');
    print('Iris shape: ${iris.shape}');
    print('Columns: ${iris.columns}');
    print('First 5 rows:');
    print(iris.head(5));

    // Load MNIST training data
    print('\nLoading MNIST training data...');
    final mnistTrain = await DataFrame.read('dataset://mnist/train');
    print('MNIST train shape: ${mnistTrain.shape}');

    // Load MNIST test data
    final mnistTest = await DataFrame.read('dataset://mnist/test');
    print('MNIST test shape: ${mnistTest.shape}');

    // Load Titanic dataset
    print('\nLoading Titanic dataset...');
    final titanic = await DataFrame.read('dataset://titanic/train');
    print('Titanic shape: ${titanic.shape}');
    print('Columns: ${titanic.columns}');

    // Get dataset info
    final irisInfo = ScientificDatasets.getInfo('iris');
    print('\nIris dataset info:');
    print(irisInfo);

    // Load California Housing
    print('\nLoading California Housing dataset...');
    final housing = await DataFrame.read('dataset://california_housing');
    print('Housing shape: ${housing.shape}');
    print('First 3 rows:');
    print(housing.head(3));
  } catch (e) {
    print('Dataset load example (requires internet): $e');
  }

  print('');
}

/// Example 4: Loading from databases
Future<void> example4Databases() async {
  print('--- Example 4: Databases ---');

  try {
    // SQLite - load entire table
    final df1 = await DataFrame.read('sqlite://path/to/db.sqlite?table=users');
    print('Loaded from SQLite table: ${df1.shape}');

    // SQLite - custom query
    final df2 = await DataFrame.read(
      'sqlite://path/to/db.sqlite?query=SELECT * FROM users WHERE age > 18',
    );
    print('Loaded from SQLite query: ${df2.shape}');

    // PostgreSQL
    final df3 = await DataFrame.read(
      'postgresql://user:password@localhost:5432/mydb?table=customers',
    );
    print('Loaded from PostgreSQL: ${df3.shape}');

    // MySQL
    final df4 = await DataFrame.read(
      'mysql://user:password@localhost/mydb?table=orders',
    );
    print('Loaded from MySQL: ${df4.shape}');

    // With query parameters
    final df5 = await DataFrame.read(
      'postgresql://user:pass@host/db?query=SELECT id, name, email FROM users WHERE status="active" LIMIT 100',
    );
    print('Loaded with custom query: ${df5.shape}');
  } catch (e) {
    print('Database example (requires database setup): $e');
  }

  print('');
}

/// Example 5: Writing data
Future<void> example5Writing() async {
  print('--- Example 5: Writing Data ---');

  // Create sample DataFrame
  final df = DataFrame.fromMap({
    'id': [1, 2, 3, 4, 5],
    'name': ['Alice', 'Bob', 'Charlie', 'David', 'Eve'],
    'age': [25, 30, 35, 40, 45],
    'salary': [50000.0, 60000.0, 70000.0, 80000.0, 90000.0],
  });

  print('Sample DataFrame:');
  print(df);

  try {
    // Write to CSV
    await df.write('output.csv');
    print('\nWrote to output.csv');

    // Write to CSV with options
    await df.write('output_semicolon.csv', options: {
      'fieldDelimiter': ';',
      'header': true,
    });
    print('Wrote to output_semicolon.csv with semicolon delimiter');

    // Write to JSON
    await df.write('output.json', options: {
      'orient': 'records',
    });
    print('Wrote to output.json (records format)');

    // Write to JSON (columns format)
    await df.write('output_columns.json', options: {
      'orient': 'columns',
    });
    print('Wrote to output_columns.json (columns format)');

    // Write to Excel
    await df.write('output.xlsx', options: {
      'sheetName': 'Data',
    });
    print('Wrote to output.xlsx');

    // Write to database
    await df.write('sqlite://output.db?table=employees', options: {
      'ifExists': 'replace',
      'index': false,
    });
    print('Wrote to SQLite database');

    // Write to PostgreSQL
    await df.write(
      'postgresql://user:pass@localhost/mydb?table=employees',
      options: {
        'ifExists': 'append',
        'chunkSize': 1000,
      },
    );
    print('Wrote to PostgreSQL database');
  } catch (e) {
    print('Write example: $e');
  }

  print('');
}

/// Example 6: Inspecting data sources
Future<void> example6Inspection() async {
  print('--- Example 6: Inspecting Data Sources ---');

  try {
    // Inspect local file
    final fileInfo = await DataFrame.inspect('data.csv');
    print('File info:');
    print('  Path: ${fileInfo['path']}');
    print('  Size: ${fileInfo['size']} bytes');
    print('  Format: ${fileInfo['format']}');
    print('  Modified: ${fileInfo['modified']}');

    // Inspect HTTP resource
    final httpInfo = await DataFrame.inspect(
      'https://raw.githubusercontent.com/mwaskom/seaborn-data/master/iris.csv',
    );
    print('\nHTTP resource info:');
    print('  Status: ${httpInfo['statusCode']}');
    print('  Content-Type: ${httpInfo['contentType']}');
    print('  Content-Length: ${httpInfo['contentLength']}');

    // List available datasets
    final datasetsInfo = await DataFrame.inspect('dataset://');
    print('\nAvailable datasets:');
    final datasets = datasetsInfo['available_datasets'] as Map;
    datasets.forEach((name, desc) {
      print('  - $name: $desc');
    });

    // Inspect specific dataset
    final irisInfo = await DataFrame.inspect('dataset://iris');
    print('\nIris dataset info:');
    print('  Name: ${irisInfo['name']}');
    print('  Description: ${irisInfo['description']}');
    print('  Features: ${irisInfo['features']}');
    print('  Samples: ${irisInfo['samples']}');
  } catch (e) {
    print('Inspection example: $e');
  }

  print('');
}

/// Example 7: Custom data sources
Future<void> example7CustomSources() async {
  print('--- Example 7: Custom Data Sources ---');

  // Register a custom data source
  DataSourceRegistry.register(CustomS3DataSource());
  print('Registered custom S3 data source');

  try {
    // Use custom data source
    final df = await DataFrame.read('s3://my-bucket/data.csv', options: {
      'region': 'us-east-1',
      'accessKey': 'YOUR_ACCESS_KEY',
      'secretKey': 'YOUR_SECRET_KEY',
    });
    print('Loaded from S3: ${df.shape}');
  } catch (e) {
    print('Custom source example (requires S3 setup): $e');
  }

  // List registered schemes
  print('\nRegistered URI schemes:');
  for (final scheme in DataSourceRegistry.listSchemes()) {
    print('  - $scheme://');
  }

  print('');
}

/// Example custom data source for S3
class CustomS3DataSource extends DataSource {
  @override
  String get scheme => 's3';

  @override
  bool canHandle(Uri uri) => uri.scheme == 's3';

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    // In a real implementation, this would:
    // 1. Parse S3 bucket and key from URI
    // 2. Use AWS SDK to download the file
    // 3. Detect format and parse content
    // 4. Return DataFrame

    throw UnimplementedError('S3 data source not fully implemented');
  }

  @override
  Future<void> write(
      DataFrame df, Uri uri, Map<String, dynamic> options) async {
    // In a real implementation, this would:
    // 1. Serialize DataFrame to appropriate format
    // 2. Upload to S3 using AWS SDK

    throw UnimplementedError('S3 write not fully implemented');
  }

  @override
  Future<Map<String, dynamic>> inspect(Uri uri) async {
    // Return S3 object metadata
    return {
      'bucket': uri.host,
      'key': uri.path,
      'scheme': 's3',
    };
  }
}
