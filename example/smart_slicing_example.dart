/// Example demonstrating smart slicing in NDArray.
///
/// Smart slicing automatically returns the appropriate type based on
/// the dimensionality of the result:
/// - 0D (all single indices) -> Scalar
/// - 1D -> NDArray with shape [n] (will be Series when task 31 is complete)
/// - 2D -> NDArray with shape [rows, cols] (will be DataFrame when task 32 is complete)
/// - 3D -> DataCube
/// - 4D+ -> NDArray
library;

import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Smart Slicing Examples ===\n');

  // Create a 3D array
  final array3d = NDArray.generate([3, 4, 5], (indices) {
    return indices[0] * 100 + indices[1] * 10 + indices[2];
  });

  print('Original 3D array shape: ${array3d.shape.toList()}');
  print('Original ndim: ${array3d.ndim}\n');

  // Example 1: Slice to Scalar (0D)
  print('--- Example 1: Slice to Scalar (0D) ---');
  final scalar = array3d.slice([0, 0, 0]);
  print('Type: ${scalar.runtimeType}');
  print('Value: ${(scalar as Scalar).value}');
  print('Expected: 0 (0*100 + 0*10 + 0)\n');

  // Example 2: Slice to 1D (will be Series in future)
  print('--- Example 2: Slice to 1D ---');
  final array1d = array3d.slice([0, 0, Slice.all()]);
  print('Type: ${array1d.runtimeType}');
  print('Shape: ${array1d.shape.toList()}');
  print('ndim: ${array1d.ndim}');
  print('First 3 values: ${[
    array1d.getValue([0]),
    array1d.getValue([1]),
    array1d.getValue([2])
  ]}');
  print('Expected: [0, 1, 2]\n');

  // Example 3: Slice to 2D (will be DataFrame in future)
  print('--- Example 3: Slice to 2D ---');
  final array2d = array3d.slice([0, Slice.all(), Slice.all()]);
  print('Type: ${array2d.runtimeType}');
  print('Shape: ${array2d.shape.toList()}');
  print('ndim: ${array2d.ndim}');
  print('Corner values:');
  print('  [0,0] = ${array2d.getValue([0, 0])} (expected: 0)');
  print('  [0,4] = ${array2d.getValue([0, 4])} (expected: 4)');
  print('  [3,0] = ${array2d.getValue([3, 0])} (expected: 30)');
  print('  [3,4] = ${array2d.getValue([3, 4])} (expected: 34)\n');

  // Example 4: Slice to 3D (DataCube)
  print('--- Example 4: Slice to 3D (DataCube) ---');
  final array3dSliced =
      array3d.slice([Slice.range(0, 2), Slice.all(), Slice.all()]);
  print('Type: ${array3dSliced.runtimeType}');
  print('Shape: ${array3dSliced.shape.toList()}');
  print('ndim: ${array3dSliced.ndim}');
  print('Sample value [1,2,3] = ${array3dSliced.getValue([1, 2, 3])}');
  print('Expected: 123 (1*100 + 2*10 + 3)\n');

  // Example 5: Using operator []
  print('--- Example 5: Using operator [] ---');
  final sliceWithOperator = array3d[1];
  print('Type: ${sliceWithOperator.runtimeType}');
  print('Shape: ${sliceWithOperator.shape.toList()}');
  print('ndim: ${sliceWithOperator.ndim}');
  print('Sample value [2,3] = ${sliceWithOperator.getValue([2, 3])}');
  print('Expected: 123 (1*100 + 2*10 + 3)\n');

  // Example 6: Range slicing with step
  print('--- Example 6: Range slicing with step ---');
  final array1dWithStep = NDArray([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  final stepped = array1dWithStep[Slice.range(0, 10, step: 2)] as NDArray;
  print('Original: ${array1dWithStep.toFlatList()}');
  print('Sliced with step=2: ${stepped.toFlatList()}');
  print('Expected: [0, 2, 4, 6, 8]\n');

  // Example 7: 4D array stays as NDArray
  print('--- Example 7: 4D array stays as NDArray ---');
  final array4d = NDArray.generate([2, 3, 4, 5], (indices) {
    return indices[0] * 1000 + indices[1] * 100 + indices[2] * 10 + indices[3];
  });
  final array4dSliced =
      array4d.slice([Slice.all(), Slice.all(), Slice.all(), Slice.all()]);
  print('Type: ${array4dSliced.runtimeType}');
  print('Shape: ${array4dSliced.shape.toList()}');
  print('ndim: ${array4dSliced.ndim}');
  print('Sample value [1,2,3,4] = ${array4dSliced.getValue([1, 2, 3, 4])}');
  print('Expected: 1234 (1*1000 + 2*100 + 3*10 + 4)\n');

  print('=== Smart Slicing Complete ===');
  print('\nNote: Currently 1D returns NDArray and 2D returns NDArray.');
  print(
      'These will return Series and DataFrame respectively when tasks 31 and 32 are complete.');
}
