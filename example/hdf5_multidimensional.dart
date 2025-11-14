import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Example demonstrating reading multi-dimensional (3D+) HDF5 datasets
void main() async {
  print('=== HDF5 Multi-dimensional Dataset Example ===\n');

  // First, create test data if needed
  print('Creating test data...');
  final result = await Process.run('python', [
    'scripts/create_multidim_test_data.py',
  ]);

  if (result.exitCode != 0) {
    print('Error creating test data: ${result.stderr}');
    print('Make sure Python 3 and h5py are installed');
    return;
  }

  print(result.stdout);
  print('');

  // Example 1: Read 3D dataset
  print('--- Example 1: Reading 3D Dataset ---');
  final df3d = await FileReader.readHDF5(
    'test_data/test_3d.h5',
    dataset: '/volume',
  );

  print('Shape information:');
  print('  Shape string: ${df3d['_shape'][0]}');
  print('  Dimensions: ${df3d['_ndim'][0]}');

  // Parse the shape
  final shapeStr = df3d['_shape'][0] as String;
  final shape3d = shapeStr.split('x').map(int.parse).toList();
  print('  Parsed shape: $shape3d');
  print('');

  final data3d = df3d['data'].data; // Get the underlying list from Series
  print('Flattened data (first 10 elements): ${data3d.take(10).toList()}');
  print('Total elements: ${data3d.length}');
  print('');

  // Example 2: Read 4D dataset
  print('--- Example 2: Reading 4D Dataset ---');
  final df4d = await FileReader.readHDF5(
    'test_data/test_4d.h5',
    dataset: '/tensor',
  );

  final shape4dStr = df4d['_shape'][0] as String;
  final shape4d = shape4dStr.split('x').map(int.parse).toList();
  print('Original shape: $shape4d');
  print('Total elements: ${df4d['data'].length}');
  print('');

  // Example 3: Reshape 3D data
  print('--- Example 3: Reshaping 3D Data ---');
  print(
      'Reshaping from flat array to ${shape3d[0]}x${shape3d[1]}x${shape3d[2]}...');

  final reshaped = reshape3D(data3d, shape3d);
  print(
      'Reshaped dimensions: ${reshaped.length} x ${reshaped[0].length} x ${reshaped[0][0].length}');
  print('');
  print('Sample slice [0][0]: ${reshaped[0][0]}');
  print('Sample slice [1][2]: ${reshaped[1][2]}');
  print('');

  // Example 4: Mixed dimensionality file
  print('--- Example 4: Mixed Dimensionality File ---');

  final dfVector = await FileReader.readHDF5(
    'test_data/test_mixed_dims.h5',
    dataset: '/vector',
  );
  print('1D vector: ${dfVector['data'].data.take(5).toList()}...');

  final dfMatrix = await FileReader.readHDF5(
    'test_data/test_mixed_dims.h5',
    dataset: '/matrix',
  );
  print('2D matrix columns: ${dfMatrix.columns}');

  final dfCube = await FileReader.readHDF5(
    'test_data/test_mixed_dims.h5',
    dataset: '/cube',
  );
  final cubeShapeStr = dfCube['_shape'][0] as String;
  final cubeShape = cubeShapeStr.split('x').map(int.parse).toList();
  print('3D cube shape: $cubeShape');
  print('');

  print('=== Examples Complete ===');
}

/// Helper function to reshape flat data into 3D structure
List<List<List<dynamic>>> reshape3D(List<dynamic> flat, List<int> shape) {
  if (shape.length != 3) {
    throw ArgumentError('Shape must have exactly 3 dimensions');
  }

  final result = <List<List<dynamic>>>[];
  int idx = 0;

  for (int i = 0; i < shape[0]; i++) {
    final plane = <List<dynamic>>[];
    for (int j = 0; j < shape[1]; j++) {
      final row = <dynamic>[];
      for (int k = 0; k < shape[2]; k++) {
        row.add(flat[idx++]);
      }
      plane.add(row);
    }
    result.add(plane);
  }

  return result;
}

/// Helper function to reshape flat data into 4D structure
List<List<List<List<dynamic>>>> reshape4D(List<dynamic> flat, List<int> shape) {
  if (shape.length != 4) {
    throw ArgumentError('Shape must have exactly 4 dimensions');
  }

  final result = <List<List<List<dynamic>>>>[];
  int idx = 0;

  for (int i = 0; i < shape[0]; i++) {
    final volume = <List<List<dynamic>>>[];
    for (int j = 0; j < shape[1]; j++) {
      final plane = <List<dynamic>>[];
      for (int k = 0; k < shape[2]; k++) {
        final row = <dynamic>[];
        for (int l = 0; l < shape[3]; l++) {
          row.add(flat[idx++]);
        }
        plane.add(row);
      }
      volume.add(plane);
    }
    result.add(volume);
  }

  return result;
}
