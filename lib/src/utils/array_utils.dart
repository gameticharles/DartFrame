/// Utility functions for array creation, random generation, and conversion.
library;

import 'dart:math' show Random, sqrt, log, pi, cos, sin;
import '../ndarray/ndarray.dart';
import '../core/shape.dart';

/// Utility class providing static methods for array creation and manipulation.
///
/// This class offers convenient functions for creating NDArrays with various
/// patterns, generating random data, and converting between different formats.
/// All methods are static and follow NumPy-like conventions.
class ArrayUtils {
  // Private constructor to prevent instantiation
  ArrayUtils._();

  /// Creates an NDArray filled with zeros.
  ///
  /// Parameters:
  /// - [shape]: The shape of the array as a list of dimensions
  ///
  /// Returns an NDArray of the specified shape filled with 0.0 values.
  ///
  /// Example:
  /// ```dart
  /// var arr = ArrayUtils.zeros([2, 3]);
  /// // Creates a 2x3 array: [[0, 0, 0], [0, 0, 0]]
  /// ```
  ///
  /// Throws [ArgumentError] if shape contains non-positive dimensions.
  static NDArray zeros(List<int> shape) {
    _validateShape(shape);
    return NDArray.zeros(shape);
  }

  /// Creates an NDArray filled with ones.
  ///
  /// Parameters:
  /// - [shape]: The shape of the array as a list of dimensions
  ///
  /// Returns an NDArray of the specified shape filled with 1.0 values.
  ///
  /// Example:
  /// ```dart
  /// var arr = ArrayUtils.ones([2, 3]);
  /// // Creates a 2x3 array: [[1, 1, 1], [1, 1, 1]]
  /// ```
  ///
  /// Throws [ArgumentError] if shape contains non-positive dimensions.
  static NDArray ones(List<int> shape) {
    _validateShape(shape);
    return NDArray.ones(shape);
  }

  /// Creates an NDArray filled with a specific value.
  ///
  /// Parameters:
  /// - [shape]: The shape of the array as a list of dimensions
  /// - [value]: The value to fill the array with
  ///
  /// Returns an NDArray of the specified shape filled with the given value.
  ///
  /// Example:
  /// ```dart
  /// var arr = ArrayUtils.full([2, 3], 5);
  /// // Creates a 2x3 array: [[5, 5, 5], [5, 5, 5]]
  /// ```
  ///
  /// Throws [ArgumentError] if shape contains non-positive dimensions.
  static NDArray full(List<int> shape, dynamic value) {
    _validateShape(shape);
    return NDArray.filled(shape, value);
  }

  /// Creates a 2D identity matrix.
  ///
  /// Parameters:
  /// - [n]: Number of rows
  /// - [m]: Number of columns (optional, defaults to n for square matrix)
  ///
  /// Returns an NDArray with ones on the diagonal and zeros elsewhere.
  ///
  /// Example:
  /// ```dart
  /// var arr = ArrayUtils.eye(3);
  /// // Creates: [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
  ///
  /// var arr2 = ArrayUtils.eye(3, m: 4);
  /// // Creates: [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0]]
  /// ```
  ///
  /// Throws [ArgumentError] if n or m are non-positive.
  static NDArray eye(int n, {int? m}) {
    if (n <= 0) {
      throw ArgumentError('n must be positive, got: $n');
    }
    final cols = m ?? n;
    if (cols <= 0) {
      throw ArgumentError('m must be positive, got: $cols');
    }

    return NDArray.generate([n, cols], (indices) {
      return indices[0] == indices[1] ? 1 : 0;
    });
  }

  /// Creates a 1D array with evenly spaced values.
  ///
  /// Parameters:
  /// - [start]: Starting value (inclusive)
  /// - [stop]: Ending value (exclusive)
  /// - [step]: Spacing between values (default: 1)
  ///
  /// Returns a 1D NDArray containing values from start to stop with the given step.
  ///
  /// Example:
  /// ```dart
  /// var arr = ArrayUtils.arange(0, 10, step: 2);
  /// // Creates: [0, 2, 4, 6, 8]
  ///
  /// var arr2 = ArrayUtils.arange(1.0, 2.0, step: 0.25);
  /// // Creates: [1.0, 1.25, 1.5, 1.75]
  /// ```
  ///
  /// Throws [ArgumentError] if step is zero or has wrong sign.
  static NDArray arange(num start, num stop, {num step = 1}) {
    if (step == 0) {
      throw ArgumentError('step cannot be zero');
    }
    if ((stop - start) * step < 0) {
      throw ArgumentError(
          'step has wrong sign: start=$start, stop=$stop, step=$step');
    }

    final numElements = ((stop - start) / step).ceil();
    if (numElements <= 0) {
      return NDArray.fromFlat([], [0]);
    }

    final data = List<num>.generate(numElements, (i) => start + i * step);
    return NDArray.fromFlat(data, [data.length]);
  }

  /// Creates a 1D array with evenly spaced values over a specified interval.
  ///
  /// Parameters:
  /// - [start]: Starting value (inclusive)
  /// - [stop]: Ending value (inclusive)
  /// - [num]: Number of samples to generate
  ///
  /// Returns a 1D NDArray containing num evenly spaced values from start to stop.
  ///
  /// Example:
  /// ```dart
  /// var arr = ArrayUtils.linspace(0, 1, 5);
  /// // Creates: [0.0, 0.25, 0.5, 0.75, 1.0]
  /// ```
  ///
  /// Throws [ArgumentError] if num is less than 2.
  static NDArray linspace(num start, num stop, int num) {
    if (num < 2) {
      throw ArgumentError('num must be at least 2, got: $num');
    }

    final step = (stop - start) / (num - 1);
    final data = List<double>.generate(num, (i) {
      if (i == num - 1) {
        return stop.toDouble(); // Ensure exact end value
      }
      return (start + i * step).toDouble();
    });

    return NDArray.fromFlat(data, [data.length]);
  }

  /// Creates an NDArray filled with random values between 0 and 1.
  ///
  /// Parameters:
  /// - [shape]: The shape of the array as a list of dimensions
  /// - [seed]: Optional seed for reproducible random generation
  ///
  /// Returns an NDArray of the specified shape filled with random values
  /// uniformly distributed between 0.0 (inclusive) and 1.0 (exclusive).
  ///
  /// Example:
  /// ```dart
  /// var arr = ArrayUtils.random([2, 3]);
  /// // Creates a 2x3 array with random values
  ///
  /// var arr2 = ArrayUtils.random([2, 3], seed: 42);
  /// // Creates a reproducible random array
  /// ```
  ///
  /// Throws [ArgumentError] if shape contains non-positive dimensions.
  static NDArray random(List<int> shape, {int? seed}) {
    _validateShape(shape);
    final rng = Random(seed);

    return NDArray.generate(shape, (_) => rng.nextDouble());
  }

  /// Creates an NDArray filled with normally distributed random values.
  ///
  /// Uses the Box-Muller transform to generate values from a normal distribution.
  ///
  /// Parameters:
  /// - [shape]: The shape of the array as a list of dimensions
  /// - [mean]: Mean of the normal distribution (default: 0.0)
  /// - [std]: Standard deviation of the normal distribution (default: 1.0)
  /// - [seed]: Optional seed for reproducible random generation
  ///
  /// Returns an NDArray of the specified shape filled with normally distributed
  /// random values.
  ///
  /// Example:
  /// ```dart
  /// var arr = ArrayUtils.randomNormal([2, 3]);
  /// // Creates a 2x3 array with standard normal distribution (mean=0, std=1)
  ///
  /// var arr2 = ArrayUtils.randomNormal([2, 3], mean: 5.0, std: 2.0);
  /// // Creates a 2x3 array with normal distribution (mean=5, std=2)
  /// ```
  ///
  /// Throws [ArgumentError] if shape contains non-positive dimensions or std <= 0.
  static NDArray randomNormal(List<int> shape,
      {double mean = 0.0, double std = 1.0, int? seed}) {
    _validateShape(shape);
    if (std <= 0) {
      throw ArgumentError('std must be positive, got: $std');
    }

    final rng = Random(seed);
    final shapeObj = Shape(shape);
    final totalSize = shapeObj.size;

    // Generate pairs of normal random values using Box-Muller transform
    final data = <double>[];
    for (int i = 0; i < totalSize; i += 2) {
      final pair = _boxMullerTransform(rng);
      data.add(pair[0] * std + mean);
      if (i + 1 < totalSize) {
        data.add(pair[1] * std + mean);
      }
    }

    return NDArray.fromFlat(data.take(totalSize).toList(), shape);
  }

  /// Creates an NDArray from a nested list.
  ///
  /// Parameters:
  /// - [data]: Nested list containing the array data
  ///
  /// Returns an NDArray constructed from the nested list with automatic shape inference.
  ///
  /// Example:
  /// ```dart
  /// var arr = ArrayUtils.fromList([[1, 2, 3], [4, 5, 6]]);
  /// // Creates a 2x3 array
  /// ```
  ///
  /// Throws [ArgumentError] if data is empty or has inconsistent dimensions.
  static NDArray fromList(List<dynamic> data) {
    if (data.isEmpty) {
      throw ArgumentError('Cannot create NDArray from empty list');
    }
    return NDArray(data);
  }

  /// Converts an NDArray to a nested list.
  ///
  /// Parameters:
  /// - [array]: The NDArray to convert
  ///
  /// Returns a nested list representation of the array data.
  ///
  /// Example:
  /// ```dart
  /// var arr = ArrayUtils.zeros([2, 3]);
  /// var list = ArrayUtils.toList(arr);
  /// // Returns: [[0, 0, 0], [0, 0, 0]]
  /// ```
  static List<dynamic> toList(NDArray array) {
    return array.toNestedList();
  }

  // Private helper methods

  /// Validates that a shape contains only positive dimensions.
  static void _validateShape(List<int> shape) {
    if (shape.isEmpty) {
      throw ArgumentError('Shape cannot be empty');
    }
    for (int i = 0; i < shape.length; i++) {
      if (shape[i] <= 0) {
        throw ArgumentError(
            'All dimensions must be positive, got ${shape[i]} at index $i');
      }
    }
  }

  /// Box-Muller transform to generate two independent standard normal random values.
  ///
  /// Returns a list of two doubles from a standard normal distribution (mean=0, std=1).
  static List<double> _boxMullerTransform(Random rng) {
    // Generate two uniform random values in (0, 1)
    double u1, u2;
    do {
      u1 = rng.nextDouble();
    } while (u1 == 0.0); // Ensure u1 is not zero for log

    u2 = rng.nextDouble();

    // Apply Box-Muller transform
    final r = sqrt(-2.0 * log(u1));
    final theta = 2.0 * pi * u2;

    return [r * cos(theta), r * sin(theta)];
  }
}
