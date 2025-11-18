/// Transformation operations for DataCube.
library;

import 'datacube.dart';
import '../ndarray/ndarray.dart';

/// Extension providing transformation operations on DataCube.
extension DataCubeTransformations on DataCube {
  /// Transposes the DataCube by swapping two axes.
  ///
  /// Default transposes axes 1 and 2 (rows and columns within each sheet).
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.generate(3, 4, 5, (d, r, c) => d * 100 + r * 10 + c);
  /// var transposed = cube.transpose();  // Shape becomes [3, 5, 4]
  /// ```
  DataCube transpose({int axis1 = 1, int axis2 = 2}) {
    if (axis1 < 0 || axis1 > 2 || axis2 < 0 || axis2 > 2) {
      throw ArgumentError('Axes must be 0, 1, or 2');
    }

    if (axis1 == axis2) {
      return copy();
    }

    // Create permutation array
    final perm = [0, 1, 2];
    final temp = perm[axis1];
    perm[axis1] = perm[axis2];
    perm[axis2] = temp;

    return permute(perm);
  }

  /// Permutes (reorders) the axes of the DataCube.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(3, 4, 5);  // [depth, rows, cols]
  /// var permuted = cube.permute([2, 0, 1]);  // [cols, depth, rows] = [5, 3, 4]
  /// ```
  DataCube permute(List<int> axes) {
    if (axes.length != 3) {
      throw ArgumentError('Must provide exactly 3 axes for DataCube');
    }

    // Validate axes
    final sorted = List<int>.from(axes)..sort();
    if (sorted[0] != 0 || sorted[1] != 1 || sorted[2] != 2) {
      throw ArgumentError('Axes must be a permutation of [0, 1, 2]');
    }

    // Calculate new shape
    final newShape = [
      shape[axes[0]],
      shape[axes[1]],
      shape[axes[2]],
    ];

    // Generate permuted data
    final newData = NDArray.generate(newShape, (newIndices) {
      final oldIndices = [0, 0, 0];
      oldIndices[axes[0]] = newIndices[0];
      oldIndices[axes[1]] = newIndices[1];
      oldIndices[axes[2]] = newIndices[2];
      return data.getValue(oldIndices);
    });

    return DataCube.fromNDArray(newData);
  }

  /// Reshapes the DataCube to new dimensions.
  ///
  /// The total size must remain the same.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(2, 3, 4);  // Size = 24
  /// var reshaped = cube.reshapeCube(3, 2, 4);  // Still size = 24
  /// ```
  DataCube reshapeCube(int newDepth, int newRows, int newCols) {
    final newSize = newDepth * newRows * newCols;
    if (newSize != size) {
      throw ArgumentError(
          'Cannot reshape DataCube of size $size to [$newDepth, $newRows, $newCols] (size $newSize)');
    }

    final reshaped = data.reshape([newDepth, newRows, newCols]);
    return DataCube.fromNDArray(reshaped);
  }

  /// Squeezes the DataCube by removing dimensions of size 1.
  ///
  /// Returns an NDArray if any dimension is removed.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(1, 4, 5);
  /// var squeezed = cube.squeeze();  // Returns 2D NDArray [4, 5]
  /// ```
  dynamic squeeze() {
    final newShape = <int>[];
    for (int i = 0; i < 3; i++) {
      if (shape[i] != 1) {
        newShape.add(shape[i]);
      }
    }

    if (newShape.length == 3) {
      // Still 3D, return DataCube
      return this;
    }

    // Return NDArray with reduced dimensions
    final flatData = data.toFlatList();
    return NDArray.fromFlat(flatData, newShape);
  }

  /// Expands dimensions by adding axes of size 1.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(3, 4, 5);
  /// var expanded = cube.expandDims(axis: 0);  // Shape becomes [1, 3, 4, 5]
  /// ```
  NDArray expandDims({required int axis}) {
    if (axis < 0 || axis > 3) {
      throw ArgumentError('Axis must be between 0 and 3');
    }

    final newShape = <int>[];
    for (int i = 0; i <= 3; i++) {
      if (i == axis) {
        newShape.add(1);
      }
      if (i < 3) {
        newShape.add(shape[i]);
      }
    }

    final flatData = data.toFlatList();
    return NDArray.fromFlat(flatData, newShape);
  }

  /// Swaps depth and rows axes.
  ///
  /// Equivalent to transpose(axis1: 0, axis2: 1).
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(3, 4, 5);  // [depth, rows, cols]
  /// var swapped = cube.swapDepthRows();   // [4, 3, 5] [rows, depth, cols]
  /// ```
  DataCube swapDepthRows() {
    return transpose(axis1: 0, axis2: 1);
  }

  /// Swaps depth and columns axes.
  ///
  /// Equivalent to transpose(axis1: 0, axis2: 2).
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(3, 4, 5);  // [depth, rows, cols]
  /// var swapped = cube.swapDepthCols();   // [5, 4, 3] [cols, rows, depth]
  /// ```
  DataCube swapDepthCols() {
    return transpose(axis1: 0, axis2: 2);
  }

  /// Swaps rows and columns axes (standard matrix transpose within each sheet).
  ///
  /// Equivalent to transpose(axis1: 1, axis2: 2).
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(3, 4, 5);  // [depth, rows, cols]
  /// var swapped = cube.swapRowsCols();    // [3, 5, 4] [depth, cols, rows]
  /// ```
  DataCube swapRowsCols() {
    return transpose(axis1: 1, axis2: 2);
  }

  /// Flattens the DataCube to a 1D NDArray.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(2, 3, 4);
  /// var flat = cube.flatten();  // 1D NDArray with 24 elements
  /// ```
  NDArray flatten() {
    return data.reshape([size]);
  }

  /// Repeats the DataCube along the depth axis.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(2, 3, 4);
  /// var repeated = cube.repeatDepth(3);  // Shape becomes [6, 3, 4]
  /// ```
  DataCube repeatDepth(int times) {
    if (times <= 0) {
      throw ArgumentError('Repeat times must be positive');
    }

    final newDepth = depth * times;
    final newData = NDArray.generate([newDepth, rows, columns], (indices) {
      final originalDepth = indices[0] % depth;
      return data.getValue([originalDepth, indices[1], indices[2]]);
    });

    return DataCube.fromNDArray(newData);
  }

  /// Tiles the DataCube by repeating it along each axis.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(2, 3, 4);
  /// var tiled = cube.tile(depthReps: 2, rowReps: 1, colReps: 3);
  /// // Shape becomes [4, 3, 12]
  /// ```
  DataCube tile({int depthReps = 1, int rowReps = 1, int colReps = 1}) {
    if (depthReps <= 0 || rowReps <= 0 || colReps <= 0) {
      throw ArgumentError('All repetitions must be positive');
    }

    final newShape = [depth * depthReps, rows * rowReps, columns * colReps];

    final newData = NDArray.generate(newShape, (indices) {
      final origD = indices[0] % depth;
      final origR = indices[1] % rows;
      final origC = indices[2] % columns;
      return data.getValue([origD, origR, origC]);
    });

    return DataCube.fromNDArray(newData);
  }

  /// Reverses the order along the specified axis.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.generate(3, 4, 5, (d, r, c) => d);
  /// var reversed = cube.reverse(axis: 0);  // Depth order reversed
  /// ```
  DataCube reverse({required int axis}) {
    if (axis < 0 || axis > 2) {
      throw ArgumentError('Axis must be 0, 1, or 2');
    }

    final newData = NDArray.generate(shape.toList(), (indices) {
      final reversedIndices = List<int>.from(indices);
      reversedIndices[axis] = shape[axis] - 1 - indices[axis];
      return data.getValue(reversedIndices);
    });

    return DataCube.fromNDArray(newData);
  }

  /// Rolls (shifts) elements along the specified axis.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.generate(3, 4, 5, (d, r, c) => d);
  /// var rolled = cube.roll(shift: 1, axis: 0);  // Shift depth by 1
  /// ```
  DataCube roll({required int shift, required int axis}) {
    if (axis < 0 || axis > 2) {
      throw ArgumentError('Axis must be 0, 1, or 2');
    }

    final axisSize = shape[axis];
    final normalizedShift = shift % axisSize;

    if (normalizedShift == 0) {
      return copy();
    }

    final newData = NDArray.generate(shape.toList(), (indices) {
      final shiftedIndices = List<int>.from(indices);
      shiftedIndices[axis] =
          (indices[axis] - normalizedShift + axisSize) % axisSize;
      return data.getValue(shiftedIndices);
    });

    return DataCube.fromNDArray(newData);
  }
}
