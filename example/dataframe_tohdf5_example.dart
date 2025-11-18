/// Example demonstrating DataFrame.toHDF5() extension method
///
/// This example shows how to write DataFrames to HDF5 files using both
/// compound datatype and column-wise storage strategies.
library;

import 'package:dartframe/dartframe.dart';

Future<void> main() async {
  print('DataFrame.toHDF5() Extension Method Example\n');
  print('=' * 60);

  // Create a sample DataFrame
  final df = DataFrame([
    [1, 'Alice', 25.5, true],
    [2, 'Bob', 30.0, false],
    [3, 'Charlie', 35.2, true],
    [4, 'Diana', 28.7, false],
  ], columns: [
    'id',
    'name',
    'age',
    'active'
  ]);

  print('\nOriginal DataFrame:');
  print(df);

  // Example 1: Write using compound datatype strategy (default)
  print('\n1. Writing DataFrame using compound datatype strategy...');
  await df.toHDF5(
    'dataframe_compound.h5',
    dataset: '/users',
  );
  print('   ✓ Written to dataframe_compound.h5');

  // Example 2: Write using column-wise storage strategy (numeric-only)
  print('\n2. Writing numeric DataFrame using column-wise storage strategy...');
  final numericDf = DataFrame([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0],
    [7.0, 8.0, 9.0],
  ], columns: [
    'x',
    'y',
    'z'
  ]);

  await numericDf.toHDF5(
    'dataframe_columnwise.h5',
    dataset: '/measurements',
    options: const WriteOptions(
      dfStrategy: DataFrameStorageStrategy.columnwise,
    ),
  );
  print('   ✓ Written to dataframe_columnwise.h5');
  print(
      '   Note: Column-wise strategy works best with numeric-only DataFrames');

  // Example 3: Write with custom options
  print('\n3. Writing DataFrame with custom options...');
  await df.toHDF5(
    'dataframe_custom.h5',
    dataset: '/data/users',
    options: const WriteOptions(
      dfStrategy: DataFrameStorageStrategy.compound,
      createIntermediateGroups: true,
      attributes: {
        'description': 'User data',
        'version': '1.0',
        'created': '2024-01-01',
      },
    ),
  );
  print('   ✓ Written to dataframe_custom.h5');

  // Example 4: Write DataFrame with mixed types (compound strategy handles this well)
  print('\n4. Writing DataFrame with mixed types...');
  final mixedDf = DataFrame([
    [1, 'Product A', 19.99, true],
    [2, 'Product B', 29.99, false],
    [3, 'Product C', 39.99, true],
  ], columns: [
    'id',
    'name',
    'price',
    'in_stock'
  ]);

  await mixedDf.toHDF5(
    'dataframe_mixed.h5',
    dataset: '/products',
  );
  print('   ✓ Written to dataframe_mixed.h5');
  print(
      '   Note: Compound strategy (default) handles mixed types including strings');

  print('\n${'=' * 60}');
  print('\nAll examples completed successfully!');
  print('\nYou can read these files using:');
  print('  - Python: pandas.read_hdf("dataframe_compound.h5", "/users")');
  print('  - Python: h5py.File("dataframe_compound.h5", "r")["/users"]');
  print('  - MATLAB: h5read("dataframe_compound.h5", "/users")');
  print('  - R: rhdf5::h5read("dataframe_compound.h5", "/users")');
}
