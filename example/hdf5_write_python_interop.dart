import 'package:dartframe/dartframe.dart';

/// Example: Interoperability with Python
///
/// This example demonstrates writing HDF5 files in Dart that can be seamlessly
/// read and processed in Python using h5py and pandas. It shows best practices
/// for ensuring compatibility and includes Python code snippets for verification.
Future<void> main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║     HDF5 Interoperability with Python Example             ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');

  // Example 1: Simple array for h5py
  print('Example 1: Simple Array for h5py\n');

  final simpleArray = NDArray.generate([100, 50], (i) => i[0] * 50 + i[1]);
  simpleArray.attrs['units'] = 'meters';
  simpleArray.attrs['description'] = 'Distance measurements';
  simpleArray.attrs['instrument'] = 'Laser Rangefinder';

  await simpleArray.toHDF5(
    'python_simple_array.h5',
    dataset: '/measurements',
  );

  print('✓ Written python_simple_array.h5');
  print('');
  print('Python code to read:');
  print('```python');
  print("import h5py");
  print("import numpy as np");
  print('');
  print("with h5py.File('python_simple_array.h5', 'r') as f:");
  print("    data = f['/measurements'][:]");
  print("    print(f'Shape: {data.shape}')  # (100, 50)");
  print("    print(f'Dtype: {data.dtype}')  # float64");
  print("    ");
  print("    # Read attributes");
  print("    units = f['/measurements'].attrs['units']");
  print("    desc = f['/measurements'].attrs['description']");
  print("    print(f'Units: {units}')");
  print("    print(f'Description: {desc}')");
  print('```');
  print('');

  // Example 2: DataFrame for pandas
  print('Example 2: DataFrame for pandas\n');

  final employees = DataFrame([
    [1, 'Alice', 'Engineering', 75000.0, 3],
    [2, 'Bob', 'Marketing', 65000.0, 2],
    [3, 'Charlie', 'Engineering', 85000.0, 5],
    [4, 'Diana', 'Sales', 70000.0, 4],
    [5, 'Eve', 'Engineering', 90000.0, 7],
  ], columns: [
    'id',
    'name',
    'department',
    'salary',
    'years'
  ]);

  await employees.toHDF5(
    'python_dataframe.h5',
    dataset: '/employees',
    options: WriteOptions(
      attributes: {
        'company': 'Tech Corp',
        'year': 2024,
        'currency': 'USD',
      },
    ),
  );

  print('✓ Written python_dataframe.h5');
  print('');
  print('Python code to read:');
  print('```python');
  print("import pandas as pd");
  print('');
  print("# Read with pandas");
  print("df = pd.read_hdf('python_dataframe.h5', '/employees')");
  print("print(df)");
  print("print(df.dtypes)");
  print("print(f'Shape: {df.shape}')");
  print('');
  print("# Access attributes");
  print("import h5py");
  print("with h5py.File('python_dataframe.h5', 'r') as f:");
  print("    attrs = dict(f['/employees'].attrs)");
  print("    print(f'Company: {attrs[\"company\"]}')");
  print('```');
  print('');

  // Example 3: Compressed data for efficient storage
  print('Example 3: Compressed Data\n');

  final largeData = NDArray.generate([1000, 500], (i) => i[0] * 500 + i[1]);

  await largeData.toHDF5(
    'python_compressed.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [100, 100],
      compression: CompressionType.gzip,
      compressionLevel: 6,
      attributes: {
        'compression': 'gzip',
        'compression_level': 6,
      },
    ),
  );

  print('✓ Written python_compressed.h5');
  print('');
  print('Python code to read:');
  print('```python');
  print("import h5py");
  print('');
  print("with h5py.File('python_compressed.h5', 'r') as f:");
  print("    # h5py automatically decompresses");
  print("    data = f['/data'][:]");
  print("    print(f'Shape: {data.shape}')");
  print("    ");
  print("    # Check compression info");
  print("    dset = f['/data']");
  print("    print(f'Compression: {dset.compression}')  # gzip");
  print("    print(f'Compression opts: {dset.compression_opts}')  # 6");
  print("    print(f'Chunks: {dset.chunks}')  # (100, 100)");
  print('```');
  print('');

  // Example 4: Multiple datasets with hierarchy
  print('Example 4: Multiple Datasets with Hierarchy\n');

  final rawData = NDArray.generate([200, 200], (i) => i[0] + i[1]);
  final processedData =
      NDArray.generate([200, 200], (i) => (i[0] + i[1]) * 1.5);
  final metadata = DataFrame([
    ['2024-01-15', 'Experiment 1', 'Success'],
    ['2024-01-16', 'Experiment 2', 'Success'],
  ], columns: [
    'date',
    'name',
    'status'
  ]);

  await HDF5WriterUtils.writeMultiple('python_hierarchy.h5', {
    '/experiment/raw_data': rawData,
    '/experiment/processed_data': processedData,
    '/experiment/metadata': metadata,
  });

  print('✓ Written python_hierarchy.h5');
  print('');
  print('Python code to read:');
  print('```python');
  print("import h5py");
  print("import pandas as pd");
  print('');
  print("with h5py.File('python_hierarchy.h5', 'r') as f:");
  print("    # List all datasets");
  print("    def print_structure(name, obj):");
  print("        if isinstance(obj, h5py.Dataset):");
  print("            print(f'{name}: {obj.shape}')");
  print("    f.visititems(print_structure)");
  print("    ");
  print("    # Read specific datasets");
  print("    raw = f['/experiment/raw_data'][:]");
  print("    processed = f['/experiment/processed_data'][:]");
  print("    ");
  print("    # Read DataFrame");
  print(
      "    metadata = pd.read_hdf('python_hierarchy.h5', '/experiment/metadata')");
  print("    print(metadata)");
  print('```');
  print('');

  // Example 5: Time series data for pandas
  print('Example 5: Time Series Data\n');

  final dates = <String>[];
  final values = <double>[];
  for (int i = 0; i < 365; i++) {
    dates.add('2024-01-01'); // Simplified for example
    values.add(100.0 + (i * 0.5) + (i % 7) * 2.0);
  }

  final timeSeries = DataFrame([
    for (int i = 0; i < dates.length; i++) [dates[i], values[i]]
  ], columns: [
    'date',
    'value'
  ]);

  await timeSeries.toHDF5(
    'python_timeseries.h5',
    dataset: '/stock_prices',
    options: WriteOptions(
      attributes: {
        'symbol': 'AAPL',
        'frequency': 'daily',
        'start_date': '2024-01-01',
        'end_date': '2024-12-31',
      },
    ),
  );

  print('✓ Written python_timeseries.h5');
  print('');
  print('Python code to read:');
  print('```python');
  print("import pandas as pd");
  print('');
  print("# Read time series");
  print("df = pd.read_hdf('python_timeseries.h5', '/stock_prices')");
  print("print(df.head())");
  print("print(df.tail())");
  print('');
  print("# Convert date column to datetime");
  print("df['date'] = pd.to_datetime(df['date'])");
  print("df.set_index('date', inplace=True)");
  print('');
  print("# Perform time series operations");
  print("print(df.resample('W').mean())  # Weekly average");
  print("print(df.rolling(window=7).mean())  # 7-day moving average");
  print('```');
  print('');

  // Example 6: Scientific data with units
  print('Example 6: Scientific Data with Units\n');

  final temperature = NDArray.generate([50, 50], (i) => 20.0 + i[0] * 0.5);
  temperature.attrs['units'] = 'celsius';
  temperature.attrs['long_name'] = 'Temperature';
  temperature.attrs['standard_name'] = 'air_temperature';

  final pressure = NDArray.generate([50, 50], (i) => 1013.0 + i[1] * 0.2);
  pressure.attrs['units'] = 'hPa';
  pressure.attrs['long_name'] = 'Pressure';
  pressure.attrs['standard_name'] = 'air_pressure';

  await HDF5WriterUtils.writeMultiple('python_scientific.h5', {
    '/temperature': temperature,
    '/pressure': pressure,
  });

  print('✓ Written python_scientific.h5');
  print('');
  print('Python code to read:');
  print('```python');
  print("import h5py");
  print("import numpy as np");
  print("import matplotlib.pyplot as plt");
  print('');
  print("with h5py.File('python_scientific.h5', 'r') as f:");
  print("    # Read temperature");
  print("    temp = f['/temperature'][:]");
  print("    temp_units = f['/temperature'].attrs['units']");
  print("    temp_name = f['/temperature'].attrs['long_name']");
  print("    ");
  print("    # Read pressure");
  print("    pres = f['/pressure'][:]");
  print("    pres_units = f['/pressure'].attrs['units']");
  print("    ");
  print("    # Plot");
  print("    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))");
  print("    ");
  print("    im1 = ax1.imshow(temp, cmap='hot')");
  print("    ax1.set_title(f'{temp_name} ({temp_units})')");
  print("    plt.colorbar(im1, ax=ax1)");
  print("    ");
  print("    im2 = ax2.imshow(pres, cmap='viridis')");
  print("    ax2.set_title(f'Pressure ({pres_units})')");
  print("    plt.colorbar(im2, ax=ax2)");
  print("    ");
  print("    plt.tight_layout()");
  print("    plt.savefig('scientific_data.png')");
  print('```');
  print('');

  // Create a comprehensive test script
  print('═' * 60);
  print('Complete Python Test Script:\n');
  print('Save this as test_dart_hdf5.py:\n');
  print('```python');
  print('#!/usr/bin/env python3');
  print('"""Test script to verify Dart-written HDF5 files"""');
  print('');
  print('import h5py');
  print('import pandas as pd');
  print('import numpy as np');
  print('');
  print('def test_simple_array():');
  print('    """Test simple array reading"""');
  print('    print("Testing simple array...")');
  print('    with h5py.File("python_simple_array.h5", "r") as f:');
  print('        data = f["/measurements"][:]');
  print('        assert data.shape == (100, 50)');
  print('        assert data.dtype == np.float64');
  print('        assert f["/measurements"].attrs["units"] == "meters"');
  print('    print("✓ Simple array test passed")');
  print('');
  print('def test_dataframe():');
  print('    """Test DataFrame reading"""');
  print('    print("Testing DataFrame...")');
  print('    df = pd.read_hdf("python_dataframe.h5", "/employees")');
  print('    assert df.shape[0] == 5');
  print('    assert "name" in df.columns');
  print('    print("✓ DataFrame test passed")');
  print('');
  print('def test_compression():');
  print('    """Test compressed data reading"""');
  print('    print("Testing compression...")');
  print('    with h5py.File("python_compressed.h5", "r") as f:');
  print('        data = f["/data"][:]');
  print('        assert data.shape == (1000, 500)');
  print('        assert f["/data"].compression == "gzip"');
  print('    print("✓ Compression test passed")');
  print('');
  print('def test_hierarchy():');
  print('    """Test hierarchical structure"""');
  print('    print("Testing hierarchy...")');
  print('    with h5py.File("python_hierarchy.h5", "r") as f:');
  print('        assert "/experiment/raw_data" in f');
  print('        assert "/experiment/processed_data" in f');
  print('        assert "/experiment/metadata" in f');
  print('    print("✓ Hierarchy test passed")');
  print('');
  print('def test_timeseries():');
  print('    """Test time series data"""');
  print('    print("Testing time series...")');
  print('    df = pd.read_hdf("python_timeseries.h5", "/stock_prices")');
  print('    assert "date" in df.columns');
  print('    assert "value" in df.columns');
  print('    print("✓ Time series test passed")');
  print('');
  print('def test_scientific():');
  print('    """Test scientific data with units"""');
  print('    print("Testing scientific data...")');
  print('    with h5py.File("python_scientific.h5", "r") as f:');
  print('        temp = f["/temperature"][:]');
  print('        pres = f["/pressure"][:]');
  print('        assert temp.shape == (50, 50)');
  print('        assert pres.shape == (50, 50)');
  print('        assert f["/temperature"].attrs["units"] == "celsius"');
  print('        assert f["/pressure"].attrs["units"] == "hPa"');
  print('    print("✓ Scientific data test passed")');
  print('');
  print('if __name__ == "__main__":');
  print('    print("=" * 60)');
  print('    print("Testing Dart-written HDF5 files with Python")');
  print('    print("=" * 60)');
  print('    print()');
  print('    ');
  print('    test_simple_array()');
  print('    test_dataframe()');
  print('    test_compression()');
  print('    test_hierarchy()');
  print('    test_timeseries()');
  print('    test_scientific()');
  print('    ');
  print('    print()');
  print('    print("=" * 60)');
  print('    print("✓ All tests passed!")');
  print('    print("=" * 60)');
  print('```');
  print('');

  print('═' * 60);
  print('Best Practices for Python Interoperability:\n');
  print('1. Use standard datatypes (float64, int32, etc.)');
  print('2. Add descriptive attributes for metadata');
  print('3. Use meaningful dataset paths (/group/dataset)');
  print('4. Enable compression for large datasets');
  print('5. Use compound strategy for DataFrames with mixed types');
  print('6. Follow CF conventions for scientific data');
  print('7. Test with both h5py and pandas');
  print('');

  print('═' * 60);
  print('✓ All examples completed successfully!');
  print('');
  print('Run the Python test script:');
  print('  python test_dart_hdf5.py');
}
