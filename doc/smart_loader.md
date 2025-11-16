# SmartLoader - Universal Data Loading System

## Overview

SmartLoader is a powerful, extensible data loading system for DartFrame that provides a unified interface for loading and saving DataFrames from various sources. It automatically detects the source type from URIs and delegates to appropriate handlers.

## Features

- **Automatic Source Detection**: Detects data source from URI scheme
- **Multiple Formats**: CSV, JSON, Excel, HDF5, Parquet, and more
- **Built-in Datasets**: Access to popular scientific datasets (MNIST, Iris, Titanic, etc.)
- **Database Support**: SQLite, PostgreSQL, MySQL
- **HTTP/HTTPS**: Load data directly from web URLs
- **Extensible**: Plugin architecture for custom data sources
- **Pandas-like API**: Familiar `DataFrame.read()` and `df.write()` methods

## Quick Start

```dart
import 'package:dartframe/dartframe.dart';

// Load from local file
final df = await DataFrame.read('data.csv');

// Load from URL
final df = await DataFrame.read('https://example.com/data.json');

// Load scientific dataset
final iris = await DataFrame.read('dataset://iris');

// Write to file
await df.write('output.csv');
```

## Supported URI Schemes

### File System (`file://` or plain paths)

Load data from local files with automatic format detection.

```dart
// Plain path
final df = await DataFrame.read('data.csv');

// File URI
final df = await DataFrame.read('file:///path/to/data.json');

// With options
final df = await DataFrame.read('data.csv', options: {
  'fieldDelimiter': ';',
  'hasHeader': true,
  'skipRows': 1,
});
```

**Supported Formats:**
- CSV (`.csv`)
- JSON (`.json`)
- Excel (`.xlsx`, `.xls`)
- HDF5 (`.h5`, `.hdf5`)
- Parquet (`.parquet`, `.pq`)

### HTTP/HTTPS (`http://`, `https://`)

Load data from web URLs with automatic format detection.

```dart
// Load CSV from URL
final df = await DataFrame.read(
  'https://raw.githubusercontent.com/mwaskom/seaborn-data/master/iris.csv'
);

// Load JSON from API
final df = await DataFrame.read(
  'https://api.example.com/data.json',
  options: {'orient': 'records'},
);

// With authentication
final df = await DataFrame.read(
  'https://api.example.com/data.csv',
  options: {
    'headers': {
      'Authorization': 'Bearer YOUR_TOKEN',
    },
    'timeout': 30,
  },
);
```

**Options:**
- `headers`: Map of HTTP headers
- `timeout`: Request timeout in seconds (default: 30)
- `followRedirects`: Whether to follow redirects (default: true)

### Scientific Datasets (`dataset://`)

Access popular machine learning and scientific datasets.

```dart
// Load Iris dataset
final iris = await DataFrame.read('dataset://iris');

// Load MNIST training data
final mnist = await DataFrame.read('dataset://mnist/train');

// Load Titanic dataset
final titanic = await DataFrame.read('dataset://titanic/train');

// List available datasets
final datasets = ScientificDatasets.listDatasetsWithDescriptions();
datasets.forEach((name, desc) {
  print('$name: $desc');
});

// Get dataset info
final info = ScientificDatasets.getInfo('iris');
print(info);
```

**Available Datasets:**

| Dataset | Description | Subsets | Features | Samples |
|---------|-------------|---------|----------|---------|
| `mnist` | Handwritten digits (0-9) | train, test | 784 | 60k/10k |
| `iris` | Iris flower classification | - | 4 | 150 |
| `titanic` | Passenger survival | train, test | 11 | 891/418 |
| `wine` | Wine quality | red, white | 11 | 1599/4898 |
| `diabetes` | Diabetes regression | - | 10 | 442 |
| `breast_cancer` | Breast cancer diagnostic | - | 30 | 569 |
| `california_housing` | Housing prices | - | 8 | 20640 |
| `boston` | Boston housing prices | - | 13 | 506 |

### Databases (`sqlite://`, `postgresql://`, `mysql://`)

Load and save data from SQL databases.

```dart
// SQLite - load table
final df = await DataFrame.read('sqlite://path/to/db.sqlite?table=users');

// SQLite - custom query
final df = await DataFrame.read(
  'sqlite://path/to/db.sqlite?query=SELECT * FROM users WHERE age > 18'
);

// PostgreSQL
final df = await DataFrame.read(
  'postgresql://user:password@localhost:5432/mydb?table=customers'
);

// MySQL
final df = await DataFrame.read(
  'mysql://user:password@localhost/mydb?table=orders'
);

// Write to database
await df.write('sqlite://output.db?table=employees', options: {
  'ifExists': 'replace',  // 'fail', 'replace', or 'append'
  'index': false,
  'chunkSize': 1000,
});
```

**URI Format:**
```
scheme://[user:password@]host[:port]/database?table=name
scheme://[user:password@]host[:port]/database?query=SELECT...
```

**Write Options:**
- `ifExists`: Behavior if table exists ('fail', 'replace', 'append')
- `index`: Whether to write row index (default: false)
- `chunkSize`: Rows per batch insert (default: 1000)

## Writing Data

### Instance Method

```dart
final df = DataFrame.fromMap({
  'name': ['Alice', 'Bob', 'Charlie'],
  'age': [25, 30, 35],
});

// Write to CSV
await df.write('output.csv');

// Write to JSON
await df.write('output.json', options: {
  'orient': 'records',
});

// Write to Excel
await df.write('output.xlsx', options: {
  'sheetName': 'Data',
});

// Write to database
await df.write('sqlite://db.sqlite?table=users', options: {
  'ifExists': 'replace',
});
```

### Static Method

```dart
await DataFrame.write(df, 'output.csv');
```

## Common Options

### CSV Options

```dart
final df = await DataFrame.read('data.csv', options: {
  'fieldDelimiter': ';',      // Field separator (default: ',')
  'textDelimiter': '"',        // Text quote character (default: '"')
  'hasHeader': true,           // First row is header (default: true)
  'skipRows': 1,               // Skip N rows (default: 0)
  'maxRows': 100,              // Max rows to read (default: all)
  'columnNames': ['a', 'b'],   // Custom column names
});
```

### JSON Options

```dart
final df = await DataFrame.read('data.json', options: {
  'orient': 'records',  // 'records', 'columns', 'index', 'values'
  'columns': ['a', 'b'], // For 'values' orientation
});
```

### Excel Options

```dart
final df = await DataFrame.read('data.xlsx', options: {
  'sheetName': 'Sheet1',       // Sheet to read (default: first)
  'hasHeader': true,           // First row is header (default: true)
  'skipRows': 1,               // Skip N rows (default: 0)
  'maxRows': 100,              // Max rows to read (default: all)
  'columnNames': ['a', 'b'],   // Custom column names
});
```

### HDF5 Options

```dart
final df = await DataFrame.read('data.h5', options: {
  'dataset': '/mydata',  // Dataset path (default: '/data')
  'debug': true,         // Enable debug output
});
```

## Inspecting Data Sources

Get metadata about a data source without loading all data:

```dart
// Inspect local file
final info = await DataFrame.inspect('data.csv');
print('Size: ${info['size']} bytes');
print('Format: ${info['format']}');
print('Modified: ${info['modified']}');

// Inspect HTTP resource
final info = await DataFrame.inspect('https://example.com/data.csv');
print('Status: ${info['statusCode']}');
print('Content-Type: ${info['contentType']}');

// List available datasets
final info = await DataFrame.inspect('dataset://');
print('Datasets: ${info['available_datasets']}');

// Inspect specific dataset
final info = await DataFrame.inspect('dataset://iris');
print('Features: ${info['features']}');
print('Samples: ${info['samples']}');
```

## Custom Data Sources

Create and register custom data sources for specialized needs:

```dart
// 1. Implement DataSource interface
class S3DataSource extends DataSource {
  @override
  String get scheme => 's3';

  @override
  bool canHandle(Uri uri) => uri.scheme == 's3';

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    // Parse S3 bucket and key
    final bucket = uri.host;
    final key = uri.path.substring(1);
    
    // Download from S3 using AWS SDK
    final content = await downloadFromS3(bucket, key, options);
    
    // Parse content based on format
    return parseContent(content, options);
  }

  @override
  Future<void> write(DataFrame df, Uri uri, Map<String, dynamic> options) async {
    // Serialize and upload to S3
    final content = serializeDataFrame(df, options);
    await uploadToS3(uri.host, uri.path.substring(1), content, options);
  }

  @override
  Future<Map<String, dynamic>> inspect(Uri uri) async {
    return {
      'bucket': uri.host,
      'key': uri.path.substring(1),
      'scheme': 's3',
    };
  }
}

// 2. Register the data source
DataSourceRegistry.register(S3DataSource());

// 3. Use it
final df = await DataFrame.read('s3://my-bucket/data.csv', options: {
  'region': 'us-east-1',
  'accessKey': 'YOUR_KEY',
  'secretKey': 'YOUR_SECRET',
});
```

### Example: Google Cloud Storage

```dart
class GCSDataSource extends DataSource {
  @override
  String get scheme => 'gs';

  @override
  bool canHandle(Uri uri) => uri.scheme == 'gs';

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    // Implement GCS download logic
    throw UnimplementedError();
  }

  @override
  Future<void> write(DataFrame df, Uri uri, Map<String, dynamic> options) async {
    // Implement GCS upload logic
    throw UnimplementedError();
  }
}

DataSourceRegistry.register(GCSDataSource());
final df = await DataFrame.read('gs://bucket/data.csv');
```

### Example: Azure Blob Storage

```dart
class AzureBlobDataSource extends DataSource {
  @override
  String get scheme => 'azure';

  @override
  bool canHandle(Uri uri) => uri.scheme == 'azure';

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    // Implement Azure Blob download logic
    throw UnimplementedError();
  }

  @override
  Future<void> write(DataFrame df, Uri uri, Map<String, dynamic> options) async {
    // Implement Azure Blob upload logic
    throw UnimplementedError();
  }
}

DataSourceRegistry.register(AzureBlobDataSource());
final df = await DataFrame.read('azure://container/data.csv');
```

## Advanced Usage

### Chaining Operations

```dart
// Load, transform, and save
final df = await DataFrame.read('dataset://iris')
  .then((df) => df.dropna())
  .then((df) => df.select(['sepal_length', 'sepal_width', 'species']))
  .then((df) => df.where((row) => row['sepal_length'] > 5.0));

await df.write('filtered_iris.csv');
```

### Batch Processing

```dart
// Process multiple files
final files = ['data1.csv', 'data2.csv', 'data3.csv'];
final dataframes = await Future.wait(
  files.map((file) => DataFrame.read(file))
);

// Concatenate
final combined = DataFrame.concat(dataframes);
await combined.write('combined.csv');
```

### Error Handling

```dart
try {
  final df = await DataFrame.read('data.csv');
} on DataSourceError catch (e) {
  print('Failed to load data: ${e.message}');
  if (e.cause != null) {
    print('Caused by: ${e.cause}');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

## Performance Tips

1. **Use chunking for large files:**
   ```dart
   final df = await DataFrame.read('large.csv', options: {
     'maxRows': 10000,  // Process in chunks
   });
   ```

2. **Specify columns to reduce memory:**
   ```dart
   final df = await DataFrame.read('data.csv', options: {
     'columnNames': ['id', 'name'],  // Only load these columns
   });
   ```

3. **Use appropriate formats:**
   - Parquet for large datasets (columnar, compressed)
   - HDF5 for scientific data (hierarchical, efficient)
   - CSV for simple, human-readable data

4. **Database batch writes:**
   ```dart
   await df.write('sqlite://db.sqlite?table=data', options: {
     'chunkSize': 5000,  // Larger chunks for better performance
   });
   ```

## Comparison with Pandas

| Pandas | DartFrame |
|--------|-----------|
| `pd.read_csv('data.csv')` | `await DataFrame.read('data.csv')` |
| `pd.read_json('data.json')` | `await DataFrame.read('data.json')` |
| `pd.read_excel('data.xlsx')` | `await DataFrame.read('data.xlsx')` |
| `pd.read_sql('SELECT...', conn)` | `await DataFrame.read('sqlite://db?query=SELECT...')` |
| `df.to_csv('out.csv')` | `await df.write('out.csv')` |
| `df.to_json('out.json')` | `await df.write('out.json')` |
| `df.to_excel('out.xlsx')` | `await df.write('out.xlsx')` |
| `df.to_sql('table', conn)` | `await df.write('sqlite://db?table=table')` |

## Best Practices

1. **Always use try-catch for I/O operations:**
   ```dart
   try {
     final df = await DataFrame.read('data.csv');
   } catch (e) {
     // Handle error
   }
   ```

2. **Inspect before loading large files:**
   ```dart
   final info = await DataFrame.inspect('large.csv');
   if (info['size'] > 1000000000) {  // 1GB
     print('Warning: Large file detected');
   }
   ```

3. **Use appropriate URI schemes:**
   - Use `file://` for absolute paths
   - Use plain paths for relative paths
   - Use full URIs for remote resources

4. **Validate data after loading:**
   ```dart
   final df = await DataFrame.read('data.csv');
   assert(df.shape.rows > 0, 'Empty DataFrame');
   assert(df.columns.contains('id'), 'Missing id column');
   ```

5. **Clean up resources:**
   ```dart
   final source = HttpDataSource();
   try {
     final df = await source.read(uri, {});
   } finally {
     source.close();  // Close HTTP client
   }
   ```

## Troubleshooting

### Common Issues

**Issue: "Unsupported URI scheme"**
- Solution: Check that the URI scheme is registered or use a supported scheme

**Issue: "File not found"**
- Solution: Verify the file path is correct and the file exists

**Issue: "Failed to download"**
- Solution: Check internet connection and URL validity

**Issue: "Dataset not found"**
- Solution: Use `ScientificDatasets.listDatasets()` to see available datasets

**Issue: "Database connection failed"**
- Solution: Verify connection string format and credentials

## Future Enhancements

Planned features for future releases:

- [ ] Cloud storage support (S3, GCS, Azure)
- [ ] Streaming for large files
- [ ] Parallel loading
- [ ] Caching layer
- [ ] More scientific datasets
- [ ] Data validation schemas
- [ ] Automatic type inference improvements
- [ ] Compression support (gzip, bzip2, xz)

## See Also

- [DataFrame Documentation](dataframe.md)
- [CSV/Excel I/O](csv_excel_io.md)
- [HDF5 Documentation](hdf5.md)
- [Database Features](../DATABASE_FEATURES_SUMMARY.md)
