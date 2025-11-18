import 'package:dartframe/dartframe.dart';

/// Example: Comprehensive DataFrame to HDF5 writing
///
/// This example demonstrates various ways to write DataFrames to HDF5 files,
/// including both storage strategies (compound and column-wise), mixed datatypes,
/// and interoperability with pandas.
Future<void> main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║     Comprehensive DataFrame to HDF5 Example               ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');

  // Example 1: Simple DataFrame with compound strategy
  print('Example 1: Simple DataFrame (Compound Strategy)\n');

  final users = DataFrame([
    [1, 'Alice', 25, 75000.0],
    [2, 'Bob', 30, 85000.0],
    [3, 'Charlie', 35, 95000.0],
    [4, 'Diana', 28, 80000.0],
  ], columns: [
    'id',
    'name',
    'age',
    'salary'
  ]);

  print('DataFrame:');
  print(users);
  print('');

  print('Writing with compound datatype strategy (default)...');
  await users.toHDF5(
    'dataframe_users_compound.h5',
    dataset: '/users',
    options: WriteOptions(
      dfStrategy: DataFrameStorageStrategy.compound,
      attributes: {
        'description': 'Employee database',
        'created': '2024-01-15',
        'department': 'Engineering',
      },
    ),
  );
  print('✓ Written to dataframe_users_compound.h5\n');

  // Example 2: Numeric DataFrame with column-wise strategy
  print('Example 2: Numeric DataFrame (Column-wise Strategy)\n');

  final measurements = DataFrame([
    [1.0, 2.5, 3.7, 4.2],
    [1.5, 2.8, 3.9, 4.5],
    [1.2, 2.6, 3.8, 4.3],
    [1.8, 2.9, 4.0, 4.6],
  ], columns: [
    'sensor1',
    'sensor2',
    'sensor3',
    'sensor4'
  ]);

  print('DataFrame:');
  print(measurements);
  print('');

  print('Writing with column-wise strategy...');
  await measurements.toHDF5(
    'dataframe_measurements_columnwise.h5',
    dataset: '/measurements',
    options: WriteOptions(
      dfStrategy: DataFrameStorageStrategy.columnwise,
      attributes: {
        'units': 'volts',
        'sample_rate': 100,
      },
    ),
  );
  print('✓ Written to dataframe_measurements_columnwise.h5');
  print('✓ Each column stored as separate dataset\n');

  // Example 3: Large DataFrame with compression
  print('Example 3: Large DataFrame with Compression\n');

  // Create a large DataFrame
  final largeData = <List<dynamic>>[];
  for (int i = 0; i < 1000; i++) {
    largeData.add([
      i,
      i * 1.5,
      i * 2.0,
      i * 2.5,
      i * 3.0,
    ]);
  }
  final largeDf = DataFrame(largeData, columns: ['a', 'b', 'c', 'd', 'e']);

  print('DataFrame shape: ${largeDf.shape}');
  print('');

  print('Writing with compression...');
  await largeDf.toHDF5(
    'dataframe_large_compressed.h5',
    dataset: '/data',
    options: WriteOptions(
      dfStrategy: DataFrameStorageStrategy.compound,
      layout: StorageLayout.chunked,
      compression: CompressionType.gzip,
      compressionLevel: 6,
      attributes: {
        'rows': largeDf.shape[0],
        'columns': largeDf.shape[1],
      },
    ),
  );
  print('✓ Written to dataframe_large_compressed.h5\n');

  // Example 4: DataFrame with mixed types
  print('Example 4: DataFrame with Mixed Types\n');

  final products = DataFrame([
    [101, 'Laptop', 999.99, true, 50],
    [102, 'Mouse', 29.99, true, 200],
    [103, 'Keyboard', 79.99, false, 0],
    [104, 'Monitor', 299.99, true, 75],
  ], columns: [
    'id',
    'name',
    'price',
    'in_stock',
    'quantity'
  ]);

  print('DataFrame:');
  print(products);
  print('');

  print('Writing mixed-type DataFrame...');
  await products.toHDF5(
    'dataframe_products.h5',
    dataset: '/products',
    options: WriteOptions(
      dfStrategy: DataFrameStorageStrategy.compound,
      attributes: {
        'store': 'Electronics Store',
        'last_updated': '2024-01-15',
      },
    ),
  );
  print('✓ Written to dataframe_products.h5\n');

  // Example 5: Multiple DataFrames in one file
  print('Example 5: Multiple DataFrames in One File\n');

  final customers = DataFrame([
    [1, 'Alice', 'alice@example.com'],
    [2, 'Bob', 'bob@example.com'],
  ], columns: [
    'id',
    'name',
    'email'
  ]);

  final orders = DataFrame([
    [1001, 1, 150.0],
    [1002, 2, 200.0],
    [1003, 1, 75.0],
  ], columns: [
    'order_id',
    'customer_id',
    'amount'
  ]);

  print('Writing multiple DataFrames...');
  await HDF5WriterUtils.writeMultiple('dataframe_database.h5', {
    '/customers': customers,
    '/orders': orders,
  });
  print('✓ Written to dataframe_database.h5');
  print('  /customers (2 rows)');
  print('  /orders (3 rows)\n');

  // Example 6: Time series data
  print('Example 6: Time Series Data\n');

  final timeSeries = DataFrame([
    ['2024-01-01', 100.5, 1000],
    ['2024-01-02', 102.3, 1100],
    ['2024-01-03', 98.7, 950],
    ['2024-01-04', 105.2, 1200],
    ['2024-01-05', 103.8, 1050],
  ], columns: [
    'date',
    'price',
    'volume'
  ]);

  print('DataFrame:');
  print(timeSeries);
  print('');

  print('Writing time series data...');
  await timeSeries.toHDF5(
    'dataframe_timeseries.h5',
    dataset: '/stock_data',
    options: WriteOptions(
      dfStrategy: DataFrameStorageStrategy.compound,
      attributes: {
        'symbol': 'AAPL',
        'start_date': '2024-01-01',
        'end_date': '2024-01-05',
        'frequency': 'daily',
      },
    ),
  );
  print('✓ Written to dataframe_timeseries.h5\n');

  // Python usage examples
  print('═' * 60);
  print('Python Usage Examples:\n');
  print('# Example 1: Read with pandas');
  print("import pandas as pd");
  print("df = pd.read_hdf('dataframe_users_compound.h5', '/users')");
  print("print(df)");
  print("print(df.dtypes)");
  print('');
  print('# Example 2: Read with h5py');
  print("import h5py");
  print("with h5py.File('dataframe_users_compound.h5', 'r') as f:");
  print("    data = f['/users'][:]");
  print("    attrs = dict(f['/users'].attrs)");
  print("    print(f'Description: {attrs[\"description\"]}')");
  print('');
  print('# Example 3: Read column-wise DataFrame');
  print("with h5py.File('dataframe_measurements_columnwise.h5', 'r') as f:");
  print("    # Access individual columns");
  print("    sensor1 = f['/measurements/sensor1'][:]");
  print("    sensor2 = f['/measurements/sensor2'][:]");
  print("    print(f'Sensor 1: {sensor1}')");
  print('');
  print('# Example 4: Read multiple DataFrames');
  print("with h5py.File('dataframe_database.h5', 'r') as f:");
  print("    customers = pd.DataFrame(f['/customers'][:])");
  print("    orders = pd.DataFrame(f['/orders'][:])");
  print("    print('Customers:', len(customers))");
  print("    print('Orders:', len(orders))");
  print('');
  print('# Example 5: Read with compression');
  print("df = pd.read_hdf('dataframe_large_compressed.h5', '/data')");
  print("print(f'Shape: {df.shape}')");
  print("print(f'Memory usage: {df.memory_usage().sum() / 1024:.2f} KB')");
  print('');

  print('═' * 60);
  print('Storage Strategy Comparison:\n');
  print('Compound Strategy (default):');
  print('  ✓ Best for mixed datatypes (numeric + strings)');
  print('  ✓ Compatible with pandas read_hdf()');
  print('  ✓ Row-oriented access');
  print('  ✓ Preserves column order and types');
  print('');
  print('Column-wise Strategy:');
  print('  ✓ Best for numeric-only DataFrames');
  print('  ✓ Efficient column access');
  print('  ✓ Better for large DataFrames');
  print('  ⚠ Limited string support currently');
  print('');

  print('═' * 60);
  print('✓ All examples completed successfully!');
}
