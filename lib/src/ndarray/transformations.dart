/// NDArray transformation operations including transpose, flatten, and type conversion.
library;

import 'ndarray.dart';
import '../core/dtype.dart';

/// Extension providing transformation operations on NDArray.
extension NDArrayTransformations on NDArray {
  /// Transposes the array by reversing or permuting axes.
  ///
  /// If `[axes]` is null, reverses all axes (e.g., `[2,3,4] → [4,3,2]`).
  /// If `[axes]` is provided, permutes axes according to the specified order.
  ///
  /// Example:
  /// ```dart
  /// final arr = NDArray([[[1, 2], [3, 4]], [[5, 6], [7, 8]]]); // shape: [2, 2, 2]
  /// final transposed = arr.transpose(); // shape: [2, 2, 2] with axes reversed
  /// final permuted = arr.transpose(axes: [2, 0, 1]); // shape: [2, 2, 2] with custom order
  /// ```
  NDArray transpose({List<int>? axes}) {
    // Validate axes parameter if provided
    if (axes != null) {
      if (axes.length != ndim) {
        throw ArgumentError(
            'axes length ${axes.length} does not match array dimensions $ndim');
      }

      // Check for duplicates and out of bounds
      final seen = <int>{};
      for (final axis in axes) {
        if (axis < 0 || axis >= ndim) {
          throw ArgumentError('axis $axis is out of bounds for ${ndim}D array');
        }
        if (seen.contains(axis)) {
          throw ArgumentError('repeated axis $axis in axes parameter');
        }
        seen.add(axis);
      }
    }

    // Default: reverse all axes
    final axesOrder = axes ?? List.generate(ndim, (i) => ndim - 1 - i);

    // Calculate new shape
    final newShape = axesOrder.map((axis) => shape[axis]).toList();

    // Generate transposed array
    return NDArray.generate(newShape, (newIndices) {
      // Map new indices back to original indices
      final originalIndices = List<int>.filled(ndim, 0);
      for (int i = 0; i < ndim; i++) {
        originalIndices[axesOrder[i]] = newIndices[i];
      }
      return getValue(originalIndices);
    });
  }

  /// Flattens the array to 1D in row-major (C-style) order.
  ///
  /// Returns a new 1D NDArray containing all elements in row-major order.
  ///
  /// Example:
  /// ```dart
  /// final arr = NDArray([[1, 2, 3], [4, 5, 6]]); // shape: [2, 3]
  /// final flat = arr.flatten(); // shape: [6], data: [1, 2, 3, 4, 5, 6]
  /// ```
  NDArray flatten() {
    final flatData = toFlatList(copy: true);
    return NDArray.fromFlat(flatData, [size]);
  }

  /// Converts the array to a different data type.
  ///
  /// Applies the DType conversion to all elements in the array.
  ///
  /// Example:
  /// ```dart
  /// final arr = NDArray([1, 2, 3]); // int array
  /// final floatArr = arr.asType(DTypes.float64()); // convert to float
  /// final strArr = arr.asType(DTypes.string()); // convert to string
  /// ```
  NDArray asType(DType dtype) {
    return map((value) {
      try {
        return dtype.convert(value);
      } catch (e) {
        throw FormatException(
            'Cannot convert value $value to ${dtype.name}: $e');
      }
    });
  }
}
