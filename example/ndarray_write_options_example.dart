import 'package:dartframe/dartframe.dart';

/// Example demonstrating NDArray.toHDF5() with WriteOptions
///
/// This example shows how to use the enhanced NDArray.toHDF5() method
/// with WriteOptions to control storage layout, compression, and other
/// advanced features.
Future<void> main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║     NDArray.toHDF5() with WriteOptions Examples           ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');

  // Example 1: Basic write with default options
  await example1BasicWrite();

  // Example 2: Write with custom attributes
  await example2WithAttributes();

  // Example 3: Write with contiguous layout (explicit)
  await example3ContiguousLayout();

  // Example 4: Legacy parameter compatibility
  await example4LegacyParameters();

  // Example 5: Multiple arrays with different options
  await example5MultipleArrays();

  print('\n✅ All examples completed successfully!');
}

/// Example 1: Basic write with default options
Future<void> example1BasicWrite() async {
  print('═' * 60);
  print('Example 1: Basic Write with Default Options');
  print('═' * 60);

  final array = NDArray.generate([10, 20], (i) => i[0] * 20 + i[1]);

  await array.toHDF5(
    'example_basic.h5',
    dataset: '/data',
    options: const WriteOptions(
      layout: StorageLayout.contiguous,
    ),
  );

  print('✓ Written array with shape [10, 20] to example_basic.h5');
  print('  Layout: Contiguous (default)');
  print('  Compression: None (default)\n');
}

/// Example 2: Write with custom attributes
Future<void> example2WithAttributes() async {
  print('═' * 60);
  print('Example 2: Write with Custom Attributes');
  print('═' * 60);

  final array = NDArray.generate([5, 5], (i) => (i[0] + i[1]).toDouble());

  // Add attributes to the array
  array.attrs['units'] = 'meters';
  array.attrs['description'] = 'Sample measurements';

  await array.toHDF5(
    'example_attributes.h5',
    dataset: '/measurements',
    options: const WriteOptions(
      attributes: {
        'version': 1,
        'created_by': 'dartframe',
      },
    ),
  );

  print('✓ Written array with shape [5, 5] to example_attributes.h5');
  print('  Attributes from array: units, description');
  print('  Attributes from options: version, created_by\n');
}

/// Example 3: Write with contiguous layout (explicit)
Future<void> example3ContiguousLayout() async {
  print('═' * 60);
  print('Example 3: Contiguous Layout (Explicit)');
  print('═' * 60);

  final array = NDArray.generate([100, 100], (i) => i[0] * 100 + i[1]);

  await array.toHDF5(
    'example_contiguous.h5',
    dataset: '/large_data',
    options: const WriteOptions(
      layout: StorageLayout.contiguous,
      formatVersion: 0,
    ),
  );

  print('✓ Written large array with shape [100, 100]');
  print('  Layout: Contiguous (all data in one block)');
  print('  Format: HDF5 version 0\n');
}

/// Example 4: Legacy parameter compatibility
Future<void> example4LegacyParameters() async {
  print('═' * 60);
  print('Example 4: Legacy Parameter Compatibility');
  print('═' * 60);

  final array = NDArray([1.0, 2.0, 3.0, 4.0, 5.0]);

  // Old-style parameters still work
  await array.toHDF5(
    'example_legacy.h5',
    dataset: '/vector',
    attributes: {
      'units': 'seconds',
      'type': 'time_series',
    },
  );

  print('✓ Written using legacy parameters (backward compatible)');
  print('  Dataset: /vector');
  print('  Attributes: units, type\n');
}

/// Example 5: Multiple arrays with different options
Future<void> example5MultipleArrays() async {
  print('═' * 60);
  print('Example 5: Multiple Arrays with Different Options');
  print('═' * 60);

  // Array 1: Small vector
  final vector = NDArray([1.0, 2.0, 3.0]);
  await vector.toHDF5(
    'example_multi.h5',
    dataset: '/vector',
    options: const WriteOptions(
      attributes: {'type': 'vector'},
    ),
  );
  print('✓ Written vector [3]');

  // Array 2: Matrix
  final matrix = NDArray.generate([10, 10], (i) => i[0] * 10 + i[1]);
  await matrix.toHDF5(
    'example_matrix.h5',
    dataset: '/matrix',
    options: const WriteOptions(
      attributes: {'type': 'matrix', 'size': '10x10'},
    ),
  );
  print('✓ Written matrix [10, 10]');

  // Array 3: 3D cube
  final cube = NDArray.generate([5, 5, 5], (i) => i[0] * 25 + i[1] * 5 + i[2]);
  await cube.toHDF5(
    'example_cube.h5',
    dataset: '/cube',
    options: const WriteOptions(
      attributes: {'type': 'cube', 'dimensions': '5x5x5'},
    ),
  );
  print('✓ Written cube [5, 5, 5]\n');
}
