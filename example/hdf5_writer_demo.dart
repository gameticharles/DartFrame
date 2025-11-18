// ignore_for_file: unused_element

import 'package:dartframe/dartframe.dart';

/// Comprehensive HDF5 Writer Demonstration
///
/// This example demonstrates all the capabilities of the HDF5 writer:
/// - Writing 1D, 2D, 3D arrays
/// - Adding attributes
/// - Writing DataCubes
/// - Using the utility class
/// - Reading back with the HDF5 reader
Future<void> main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║           HDF5 Writer Comprehensive Demo                  ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');

  // Demo 1: Simple 1D Array
  await demo1DArray();

  // Demo 2: 2D Matrix
  await demo2DMatrix();

  // Demo 3: 3D Cube
  await demo3DCube();

  // Demo 4: DataCube
  await demoDataCube();

  // Demo 5: Attributes
  await demoAttributes();

  // Demo 6: Utility Class
  await demoUtilityClass();

  print('\n╔═══════════════════════════════════════════════════════════╗');
  print('║                    Demo Complete!                          ║');
  print('╚═══════════════════════════════════════════════════════════╝');
}

/// Demo 1: Writing a simple 1D array
Future<void> demo1DArray() async {
  print('═' * 60);
  print('DEMO 1: Simple 1D Array');
  print('═' * 60);

  // Create a 1D array
  final array = NDArray.fromFlat(
    [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
    [10],
  );

  print('Created 1D array: ${array.shape}');
  print('Data: ${array.toFlatList()}');

  // Write to HDF5
  final filePath = 'example/data/demo_1d.h5';
  await array.toHDF5(filePath, dataset: '/vector');

  print('✓ Written to $filePath');

  // Read back and verify
  final file = await Hdf5File.open(filePath);
  try {
    final dataset = await file.dataset('/vector');
    print('✓ Read back successfully');
    print('  Shape: ${dataset.dataspace.dimensions}');
    print('  Type: ${dataset.datatype.typeName}');
  } finally {
    await file.close();
  }

  print('');
}

/// Demo 2: Writing a 2D matrix
Future<void> demo2DMatrix() async {
  print('═' * 60);
  print('DEMO 2: 2D Matrix');
  print('═' * 60);

  // Create a 2D matrix
  final array = NDArray.generate([4, 5], (indices) {
    return (indices[0] * 5 + indices[1]).toDouble();
  });

  print('Created 2D matrix: ${array.shape}');
  print('Sample values:');
  for (int i = 0; i < 2; i++) {
    final row = <double>[];
    for (int j = 0; j < 5; j++) {
      row.add(array.getValue([i, j]));
    }
    print('  Row $i: $row');
  }

  // Write to HDF5
  final filePath = 'example/data/demo_2d.h5';
  await array.toHDF5(filePath, dataset: '/matrix');

  print('✓ Written to $filePath');

  // Read back and verify
  final file = await Hdf5File.open(filePath);
  try {
    final dataset = await file.dataset('/matrix');
    print('✓ Read back successfully');
    print('  Shape: ${dataset.dataspace.dimensions}');
    print('  Type: ${dataset.datatype.typeName}');
  } finally {
    await file.close();
  }

  print('');
}

/// Demo 3: Writing a 3D array
Future<void> demo3DCube() async {
  print('═' * 60);
  print('DEMO 3: 3D Array');
  print('═' * 60);

  // Create a 3D array
  final array = NDArray.generate([3, 4, 5], (indices) {
    return (indices[0] * 20 + indices[1] * 5 + indices[2]).toDouble();
  });

  print('Created 3D array: ${array.shape}');
  print(
      'Total elements: ${array.shape.toList().fold<int>(1, (a, b) => a * b)}');

  // Write to HDF5
  final filePath = 'example/data/demo_3d.h5';
  await array.toHDF5(filePath, dataset: '/cube');

  print('✓ Written to $filePath');

  // Read back and verify
  final file = await Hdf5File.open(filePath);
  try {
    final dataset = await file.dataset('/cube');
    final data = await file.readDataset('/cube');
    print('✓ Read back successfully');
    print('  Shape: ${dataset.dataspace.dimensions}');
    print('  Elements: ${dataset.dataspace.totalElements}');
    print('  First value: ${_getFirstValue(data)}');
  } finally {
    await file.close();
  }

  print('');
}

/// Demo 4: Writing a DataCube
Future<void> demoDataCube() async {
  print('═' * 60);
  print('DEMO 4: DataCube');
  print('═' * 60);

  // Create a DataCube
  final cube = DataCube.zeros(5, 6, 7);

  // Fill with data
  for (int i = 0; i < 5; i++) {
    for (int j = 0; j < 6; j++) {
      for (int k = 0; k < 7; k++) {
        cube.setValue([i, j, k], (i + j + k).toDouble());
      }
    }
  }

  print('Created DataCube: 5×6×7');
  print('Total elements: ${5 * 6 * 7}');

  // Write to HDF5
  final filePath = 'example/data/demo_datacube.h5';
  await cube.toHDF5(filePath, dataset: '/datacube');

  print('✓ Written to $filePath');

  // Read back and verify
  final file = await Hdf5File.open(filePath);
  try {
    final dataset = await file.dataset('/datacube');
    print('✓ Read back successfully');
    print('  Shape: ${dataset.dataspace.dimensions}');
    print('  Type: ${dataset.datatype.typeName}');
  } finally {
    await file.close();
  }

  print('');
}

/// Demo 5: Writing arrays with attributes
Future<void> demoAttributes() async {
  print('═' * 60);
  print('DEMO 5: Attributes');
  print('═' * 60);

  // Create an array with attributes
  final array = NDArray.generate([10, 10], (indices) {
    return (indices[0] + indices[1]).toDouble();
  });

  // Add attributes
  array.attrs['units'] = 'meters';
  array.attrs['description'] = 'Sample measurement data';
  array.attrs['sensor_id'] = 'SENSOR_001';

  print('Created array with attributes:');
  print('  units: ${array.attrs['units']}');
  print('  description: ${array.attrs['description']}');
  print('  sensor_id: ${array.attrs['sensor_id']}');

  // Write to HDF5
  final filePath = 'example/data/demo_attributes.h5';
  await array.toHDF5(filePath, dataset: '/measurements');

  print('✓ Written to $filePath');

  // Read back and verify attributes
  final file = await Hdf5File.open(filePath);
  try {
    final dataset = await file.dataset('/measurements');
    print('✓ Read back successfully');
    print('  Attributes found: ${dataset.attributes.length}');
    for (final attr in dataset.attributes) {
      print('    ${attr.name}: ${attr.value}');
    }
  } finally {
    await file.close();
  }

  print('');
}

/// Demo 6: Using the utility class
Future<void> demoUtilityClass() async {
  print('═' * 60);
  print('DEMO 6: HDF5WriterUtils');
  print('═' * 60);

  // Create test data
  final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
  final cube = DataCube.zeros(2, 2, 2);

  print('Using HDF5WriterUtils for writing...');

  // Write NDArray
  await HDF5WriterUtils.writeNDArray(
    'example/data/demo_utils_array.h5',
    array,
    dataset: '/data',
    attributes: {'source': 'utility_class'},
  );
  print('✓ Written NDArray using utility class');

  // Write DataCube
  await HDF5WriterUtils.writeDataCube(
    'example/data/demo_utils_cube.h5',
    cube,
    dataset: '/cube',
    attributes: {'source': 'utility_class'},
  );
  print('✓ Written DataCube using utility class');

  // Verify
  final file1 = await Hdf5File.open('example/data/demo_utils_array.h5');
  try {
    final dataset = await file1.dataset('/data');
    print('✓ Array file verified: ${dataset.dataspace.dimensions}');
  } finally {
    await file1.close();
  }

  final file2 = await Hdf5File.open('example/data/demo_utils_cube.h5');
  try {
    final dataset = await file2.dataset('/cube');
    print('✓ Cube file verified: ${dataset.dataspace.dimensions}');
  } finally {
    await file2.close();
  }

  print('');
}

/// Helper to compare data
bool _compareData(List<double> expected, dynamic actual) {
  final flatActual = _flattenData(actual);
  if (expected.length != flatActual.length) return false;

  for (int i = 0; i < expected.length; i++) {
    if ((expected[i] - flatActual[i]).abs() > 1e-10) return false;
  }

  return true;
}

/// Helper to flatten nested list data
List<num> _flattenData(dynamic data) {
  final result = <num>[];

  void flatten(dynamic item) {
    if (item is num) {
      result.add(item);
    } else if (item is List) {
      for (final element in item) {
        flatten(element);
      }
    }
  }

  flatten(data);
  return result;
}

/// Helper to get first value from nested data
dynamic _getFirstValue(dynamic data) {
  while (data is List && data.isNotEmpty) {
    data = data[0];
  }
  return data;
}
