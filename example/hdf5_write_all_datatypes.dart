import 'package:dartframe/dartframe.dart';

/// Example: Writing all supported datatypes
///
/// This example demonstrates writing HDF5 files with all supported numeric
/// datatypes, showing how DartFrame handles different data types and ensures
/// compatibility with Python, MATLAB, and R.
Future<void> main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║     Writing All Supported Datatypes Example               ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');

  // Example 1: Integer datatypes
  print('Example 1: Integer Datatypes\n');

  // int8 (-128 to 127)
  final int8Data = NDArray([-128, -64, 0, 64, 127]);
  print('int8: $int8Data');

  // int16 (-32768 to 32767)
  final int16Data = NDArray([-32768, -16384, 0, 16384, 32767]);
  print('int16: $int16Data');

  // int32 (-2^31 to 2^31-1)
  final int32Data = NDArray([-2147483648, -1000000, 0, 1000000, 2147483647]);
  print('int32: $int32Data');

  // int64 (large integers)
  final int64Data = NDArray([
    -9223372036854775808,
    -1000000000000,
    0,
    1000000000000,
    9223372036854775807
  ]);
  print('int64: $int64Data');
  print('');

  print('Writing integer datatypes...');
  await HDF5WriterUtils.writeMultiple('datatypes_integers.h5', {
    '/int8': int8Data,
    '/int16': int16Data,
    '/int32': int32Data,
    '/int64': int64Data,
  });
  print('✓ Written to datatypes_integers.h5\n');

  // Example 2: Unsigned integer datatypes
  print('Example 2: Unsigned Integer Datatypes\n');

  // uint8 (0 to 255)
  final uint8Data = NDArray([0, 64, 128, 192, 255]);
  print('uint8: $uint8Data');

  // uint16 (0 to 65535)
  final uint16Data = NDArray([0, 16384, 32768, 49152, 65535]);
  print('uint16: $uint16Data');

  // uint32 (0 to 2^32-1)
  final uint32Data = NDArray([0, 1000000, 2000000, 3000000, 4294967295]);
  print('uint32: $uint32Data');

  // uint64 (0 to 2^64-1) - Note: max value limited by Dart int
  final uint64Data = NDArray(
      [0, 1000000000000, 2000000000000, 3000000000000, 9223372036854775807]);
  print('uint64: $uint64Data');
  print('');

  print('Writing unsigned integer datatypes...');
  await HDF5WriterUtils.writeMultiple('datatypes_unsigned.h5', {
    '/uint8': uint8Data,
    '/uint16': uint16Data,
    '/uint32': uint32Data,
    '/uint64': uint64Data,
  });
  print('✓ Written to datatypes_unsigned.h5\n');

  // Example 3: Floating-point datatypes
  print('Example 3: Floating-Point Datatypes\n');

  // float32 (single precision)
  final float32Data = NDArray([
    -3.14159,
    -1.0,
    0.0,
    1.0,
    3.14159,
  ]);
  print('float32: $float32Data');

  // float64 (double precision)
  final float64Data = NDArray([
    -3.141592653589793,
    -1.0,
    0.0,
    1.0,
    3.141592653589793,
  ]);
  print('float64: $float64Data');
  print('');

  print('Writing floating-point datatypes...');
  await HDF5WriterUtils.writeMultiple('datatypes_floats.h5', {
    '/float32': float32Data,
    '/float64': float64Data,
  });
  print('✓ Written to datatypes_floats.h5\n');

  // Example 4: Multi-dimensional arrays with different types
  print('Example 4: Multi-dimensional Arrays\n');

  // 2D int32 array
  final int32Matrix = NDArray.generate([10, 10], (i) => i[0] * 10 + i[1]);
  print('int32 matrix: ${int32Matrix.shape}');

  // 2D float64 array
  final float64Matrix =
      NDArray.generate([10, 10], (i) => (i[0] * 10 + i[1]) * 0.1);
  print('float64 matrix: ${float64Matrix.shape}');

  // 3D uint8 array (like an image)
  final uint8Cube = NDArray.generate([8, 8, 3], (i) => (i[0] * 8 + i[1]) % 256);
  print('uint8 cube: ${uint8Cube.shape}');
  print('');

  print('Writing multi-dimensional arrays...');
  await HDF5WriterUtils.writeMultiple('datatypes_multidim.h5', {
    '/int32_matrix': int32Matrix,
    '/float64_matrix': float64Matrix,
    '/uint8_cube': uint8Cube,
  });
  print('✓ Written to datatypes_multidim.h5\n');

  // Example 5: Mixed datatypes in one file
  print('Example 5: Mixed Datatypes in One File\n');

  print('Writing all datatypes to one file...');
  await HDF5WriterUtils.writeMultiple(
    'datatypes_all.h5',
    {
      '/integers/int8': int8Data,
      '/integers/int16': int16Data,
      '/integers/int32': int32Data,
      '/integers/int64': int64Data,
      '/unsigned/uint8': uint8Data,
      '/unsigned/uint16': uint16Data,
      '/unsigned/uint32': uint32Data,
      '/unsigned/uint64': uint64Data,
      '/floats/float32': float32Data,
      '/floats/float64': float64Data,
      '/arrays/int32_matrix': int32Matrix,
      '/arrays/float64_matrix': float64Matrix,
      '/arrays/uint8_cube': uint8Cube,
    },
    defaultOptions: WriteOptions(
      attributes: {
        'description': 'All supported datatypes',
        'created': '2024-01-15',
      },
    ),
  );
  print('✓ Written to datatypes_all.h5');
  print('');
  print('File structure:');
  print('  /integers/');
  print('    ├── int8, int16, int32, int64');
  print('  /unsigned/');
  print('    ├── uint8, uint16, uint32, uint64');
  print('  /floats/');
  print('    ├── float32, float64');
  print('  /arrays/');
  print('    ├── int32_matrix, float64_matrix, uint8_cube');
  print('');

  // Example 6: Datatype precision demonstration
  print('Example 6: Datatype Precision\n');

  // Show precision differences
  final precisionTest = NDArray([
    1.0 / 3.0, // 0.333...
    1.0 / 7.0, // 0.142857...
    3.141592653589793, // pi
  ]);

  print('Original values (float64):');
  final precisionList = precisionTest.toFlatList();
  print('  ${precisionList[0]}');
  print('  ${precisionList[1]}');
  print('  ${precisionList[2]}');
  print('');

  await precisionTest.toHDF5(
    'datatypes_precision.h5',
    dataset: '/float64',
    options: WriteOptions(
      attributes: {
        'datatype': 'float64',
        'precision': 'double precision (64-bit)',
      },
    ),
  );
  print('✓ Written to datatypes_precision.h5\n');

  // Example 7: Special values
  print('Example 7: Special Values\n');

  final specialValues = NDArray([
    double.infinity,
    double.negativeInfinity,
    double.nan,
    0.0,
    -0.0,
    double.maxFinite,
    double.minPositive,
  ]);

  print('Special values:');
  final specialList = specialValues.toFlatList();
  print('  Infinity: ${specialList[0]}');
  print('  -Infinity: ${specialList[1]}');
  print('  NaN: ${specialList[2]}');
  print('  Zero: ${specialList[3]}');
  print('  -Zero: ${specialList[4]}');
  print('  Max finite: ${specialList[5]}');
  print('  Min positive: ${specialList[6]}');
  print('');

  await specialValues.toHDF5(
    'datatypes_special.h5',
    dataset: '/special_values',
    options: WriteOptions(
      attributes: {
        'description': 'IEEE 754 special values',
      },
    ),
  );
  print('✓ Written to datatypes_special.h5\n');

  // Example 8: String datatypes
  print('Example 8: String Datatypes\n');

  // Note: NDArray doesn't directly support string arrays in the same way
  // Strings are typically handled through DataFrames with compound types
  // For demonstration, we'll show how strings work in DataFrames

  final stringData = DataFrame([
    ['Alice', 'Engineer', 'New York'],
    ['Bob', 'Designer', 'San Francisco'],
    ['Charlie', 'Manager', 'Boston'],
  ], columns: [
    'name',
    'role',
    'city'
  ]);

  print('String DataFrame:');
  print(stringData);
  print('');

  await stringData.toHDF5(
    'datatypes_strings.h5',
    dataset: '/employees',
    options: WriteOptions(
      attributes: {
        'description': 'String datatype example',
        'encoding': 'UTF-8',
      },
    ),
  );
  print('✓ Written to datatypes_strings.h5\n');

  // Example 9: Boolean datatypes
  print('Example 9: Boolean Datatypes\n');

  // Booleans are stored as uint8 (0 or 1) in HDF5
  final boolData = DataFrame([
    [true, false, true],
    [false, true, false],
    [true, true, false],
  ], columns: [
    'flag1',
    'flag2',
    'flag3'
  ]);

  print('Boolean DataFrame:');
  print(boolData);
  print('');

  await boolData.toHDF5(
    'datatypes_booleans.h5',
    dataset: '/flags',
    options: WriteOptions(
      attributes: {
        'description': 'Boolean datatype example',
        'note': 'Stored as uint8 (0=false, 1=true)',
      },
    ),
  );
  print('✓ Written to datatypes_booleans.h5\n');

  // Example 10: Compound datatypes (mixed types)
  print('Example 10: Compound Datatypes\n');

  final compoundData = DataFrame([
    [1, 'Alice', 25.5, true, 75000],
    [2, 'Bob', 30.0, false, 85000],
    [3, 'Charlie', 35.5, true, 95000],
  ], columns: [
    'id',
    'name',
    'age',
    'active',
    'salary'
  ]);

  print('Compound DataFrame (mixed types):');
  print(compoundData);
  print('');
  print('Column types: int, string, double, bool, int');
  print('');

  await compoundData.toHDF5(
    'datatypes_compound.h5',
    dataset: '/records',
    options: WriteOptions(
      dfStrategy: DataFrameStorageStrategy.compound,
      attributes: {
        'description': 'Compound datatype with mixed field types',
        'fields':
            'id(int), name(string), age(double), active(bool), salary(int)',
      },
    ),
  );
  print('✓ Written to datatypes_compound.h5\n');

  // Example 11: All datatypes in one file
  print('Example 11: Complete Datatype Collection\n');

  print('Writing comprehensive datatype collection...');
  await HDF5WriterUtils.writeMultiple(
    'datatypes_complete.h5',
    {
      // Numeric types
      '/numeric/int8': int8Data,
      '/numeric/int16': int16Data,
      '/numeric/int32': int32Data,
      '/numeric/int64': int64Data,
      '/numeric/uint8': uint8Data,
      '/numeric/uint16': uint16Data,
      '/numeric/uint32': uint32Data,
      '/numeric/uint64': uint64Data,
      '/numeric/float32': float32Data,
      '/numeric/float64': float64Data,
      // Complex types via DataFrames
      '/complex/strings': stringData,
      '/complex/booleans': boolData,
      '/complex/compound': compoundData,
      // Special values
      '/special/precision': precisionTest,
      '/special/ieee754': specialValues,
    },
    defaultOptions: WriteOptions(
      attributes: {
        'description': 'Complete collection of all supported datatypes',
        'datatypes':
            '11 types: int8/16/32/64, uint8/16/32/64, float32/64, string, boolean, compound',
        'created': '2024-01-15',
      },
    ),
  );
  print('✓ Written to datatypes_complete.h5');
  print('');
  print('File structure:');
  print('  /numeric/');
  print('    ├── int8, int16, int32, int64');
  print('    ├── uint8, uint16, uint32, uint64');
  print('    └── float32, float64');
  print('  /complex/');
  print('    ├── strings (DataFrame with string columns)');
  print('    ├── booleans (DataFrame with boolean columns)');
  print('    └── compound (DataFrame with mixed types)');
  print('  /special/');
  print('    ├── precision (high-precision floats)');
  print('    └── ieee754 (special float values)');
  print('');

  // Python usage examples
  print('═' * 60);
  print('Python Usage Examples:\n');
  print('# Read and check datatypes');
  print("import h5py");
  print("import numpy as np");
  print('');
  print("with h5py.File('datatypes_all.h5', 'r') as f:");
  print("    # Check integer types");
  print("    int8 = f['/integers/int8'][:]");
  print("    print(f'int8 dtype: {int8.dtype}')  # int8");
  print("    ");
  print("    int32 = f['/integers/int32'][:]");
  print("    print(f'int32 dtype: {int32.dtype}')  # int32");
  print("    ");
  print("    # Check float types");
  print("    float64 = f['/floats/float64'][:]");
  print("    print(f'float64 dtype: {float64.dtype}')  # float64");
  print("    ");
  print("    # Check array shapes");
  print("    matrix = f['/arrays/int32_matrix'][:]");
  print("    print(f'Matrix shape: {matrix.shape}')  # (10, 10)");
  print('');
  print('# Verify special values');
  print("with h5py.File('datatypes_special.h5', 'r') as f:");
  print("    special = f['/special_values'][:]");
  print("    print(f'Infinity: {np.isinf(special[0])}')");
  print("    print(f'NaN: {np.isnan(special[2])}')");
  print('');
  print('# Compare precision');
  print("with h5py.File('datatypes_precision.h5', 'r') as f:");
  print("    data = f['/float64'][:]");
  print("    print(f'1/3 = {data[0]:.17f}')");
  print("    print(f'pi = {data[2]:.17f}')");
  print('');
  print('# Read string DataFrame');
  print("import pandas as pd");
  print("strings_df = pd.read_hdf('datatypes_strings.h5', '/employees')");
  print("print(strings_df)");
  print("print(strings_df.dtypes)");
  print('');
  print('# Read boolean DataFrame');
  print("bool_df = pd.read_hdf('datatypes_booleans.h5', '/flags')");
  print("print(bool_df)");
  print("print(bool_df.dtypes)");
  print('');
  print('# Read compound DataFrame');
  print("compound_df = pd.read_hdf('datatypes_compound.h5', '/records')");
  print("print(compound_df)");
  print("print(compound_df.dtypes)");
  print('');
  print('# Read complete collection');
  print("with h5py.File('datatypes_complete.h5', 'r') as f:");
  print("    print('Available groups:')");
  print("    for group in f.keys():");
  print("        print(f'  /{group}/')");
  print("        for dataset in f[group].keys():");
  print("            shape = f[f'/{group}/{dataset}'].shape");
  print("            dtype = f[f'/{group}/{dataset}'].dtype");
  print("            print(f'    {dataset}: {shape} {dtype}')");
  print('');

  print('═' * 60);
  print('MATLAB Usage Examples:\n');
  print("% Read integer data");
  print("int32_data = h5read('datatypes_integers.h5', '/int32');");
  print("disp(class(int32_data));  % int32");
  print('');
  print("% Read float data");
  print("float64_data = h5read('datatypes_floats.h5', '/float64');");
  print("disp(class(float64_data));  % double");
  print('');
  print("% Read matrix");
  print("matrix = h5read('datatypes_multidim.h5', '/int32_matrix');");
  print("disp(size(matrix));  % [10 10]");
  print('');

  print('═' * 60);
  print('R Usage Examples:\n');
  print("library(rhdf5)");
  print('');
  print("# Read integer data");
  print("int32_data <- h5read('datatypes_integers.h5', '/int32')");
  print("class(int32_data)  # integer");
  print('');
  print("# Read float data");
  print("float64_data <- h5read('datatypes_floats.h5', '/float64')");
  print("class(float64_data)  # numeric");
  print('');
  print("# Read matrix");
  print("matrix <- h5read('datatypes_multidim.h5', '/int32_matrix')");
  print("dim(matrix)  # 10 10");
  print('');

  print('═' * 60);
  print('Complete Datatype Summary:\n');
  print('1. Signed Integers (4 types):');
  print('   int8:  -128 to 127');
  print('   int16: -32,768 to 32,767');
  print('   int32: -2,147,483,648 to 2,147,483,647');
  print('   int64: -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807');
  print('');
  print('2. Unsigned Integers (4 types):');
  print('   uint8:  0 to 255');
  print('   uint16: 0 to 65,535');
  print('   uint32: 0 to 4,294,967,295');
  print('   uint64: 0 to 18,446,744,073,709,551,615 (limited by Dart int)');
  print('');
  print('3. Floating-Point (2 types):');
  print('   float32: ~7 decimal digits precision');
  print('   float64: ~15-17 decimal digits precision');
  print('');
  print('4. String (1 type):');
  print('   Fixed-length and variable-length strings (UTF-8)');
  print('');
  print('5. Boolean (1 type):');
  print('   Stored as uint8 enum (0=false, 1=true)');
  print('');
  print('6. Compound (1 type):');
  print('   Structured data with multiple fields of different types');
  print('');
  print('Total: 13 datatype categories demonstrated');
  print('  - 10 numeric types (int8/16/32/64, uint8/16/32/64, float32/64)');
  print('  - 1 string type');
  print('  - 1 boolean type');
  print('  - 1 compound type');
  print('');
  print('✓ All 13 datatype examples completed successfully!');
}
