/// NDArray operations including element-wise, broadcasting, and aggregations.
library;

import 'dart:math' as math;
import 'ndarray.dart';
import '../core/shape.dart';

/// Extension providing mathematical and statistical operations on NDArray.
///
/// This extension adds element-wise operations, broadcasting, comparisons,
/// and aggregations to NDArray.
///
/// Operations support:
/// - Scalar operations: array + 5, array * 2
/// - Array-to-array operations with broadcasting: array1 + array2
/// - Aggregations along axes: sum(axis: 0), mean(axis: 1)
extension NDArrayOperations on NDArray {
  // ============================================================================
  // Element-wise Arithmetic Operations
  // ============================================================================

  /// Element-wise addition.
  ///
  /// Supports:
  /// - Scalar addition: adds a number to all elements
  /// - Array addition: element-wise addition with broadcasting
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2], [3, 4]]);
  ///
  /// // Scalar addition
  /// var result1 = arr + 10;
  /// print(result1.toNestedList()); // [[11, 12], [13, 14]]
  ///
  /// // Array addition
  /// var arr2 = NDArray([[10, 20], [30, 40]]);
  /// var result2 = arr + arr2;
  /// print(result2.toNestedList()); // [[11, 22], [33, 44]]
  ///
  /// // Broadcasting - add row to matrix
  /// var row = NDArray([100, 200]);
  /// var result3 = arr + row; // Broadcasting
  /// ```
  NDArray operator +(dynamic other) {
    if (other is num) {
      return map((x) => x + other);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a + b);
    }
    throw ArgumentError('Cannot add ${other.runtimeType} to NDArray');
  }

  /// Element-wise subtraction.
  ///
  /// Supports:
  /// - Scalar subtraction: subtracts a number from all elements
  /// - Array subtraction: element-wise subtraction with broadcasting
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[10, 20], [30, 40]]);
  ///
  /// // Scalar subtraction
  /// var result1 = arr - 5;
  /// print(result1.toNestedList()); // [[5, 15], [25, 35]]
  ///
  /// // Array subtraction
  /// var arr2 = NDArray([[1, 2], [3, 4]]);
  /// var result2 = arr - arr2;
  /// print(result2.toNestedList()); // [[9, 18], [27, 36]]
  /// ```
  NDArray operator -(dynamic other) {
    if (other is num) {
      return map((x) => x - other);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a - b);
    }
    throw ArgumentError('Cannot subtract ${other.runtimeType} from NDArray');
  }

  /// Element-wise multiplication.
  ///
  /// Supports:
  /// - Scalar multiplication: multiplies all elements by a number
  /// - Array multiplication: element-wise (Hadamard) product with broadcasting
  ///
  /// Note: This is NOT matrix multiplication. Use matmul() for that.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2], [3, 4]]);
  ///
  /// // Scalar multiplication
  /// var result1 = arr * 10;
  /// print(result1.toNestedList()); // [[10, 20], [30, 40]]
  ///
  /// // Element-wise multiplication
  /// var arr2 = NDArray([[2, 3], [4, 5]]);
  /// var result2 = arr * arr2;
  /// print(result2.toNestedList()); // [[2, 6], [12, 20]]
  /// ```
  NDArray operator *(dynamic other) {
    if (other is num) {
      return map((x) => x * other);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a * b);
    }
    throw ArgumentError('Cannot multiply NDArray by ${other.runtimeType}');
  }

  /// Element-wise division.
  ///
  /// Supports:
  /// - Scalar division: divides all elements by a number
  /// - Array division: element-wise division with broadcasting
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[10, 20], [30, 40]]);
  ///
  /// // Scalar division
  /// var result1 = arr / 10;
  /// print(result1.toNestedList()); // [[1.0, 2.0], [3.0, 4.0]]
  ///
  /// // Element-wise division
  /// var arr2 = NDArray([[2, 4], [5, 8]]);
  /// var result2 = arr / arr2;
  /// print(result2.toNestedList()); // [[5.0, 5.0], [6.0, 5.0]]
  /// ```
  NDArray operator /(dynamic other) {
    if (other is num) {
      return map((x) => x / other);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a / b);
    }
    throw ArgumentError('Cannot divide NDArray by ${other.runtimeType}');
  }

  /// Element-wise negation.
  ///
  /// Returns a new array with all elements negated.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, -2], [3, -4]]);
  /// var result = -arr;
  /// print(result.toNestedList()); // [[-1, 2], [-3, 4]]
  /// ```
  NDArray operator -() {
    return map((x) => -x);
  }

  /// Element-wise power operation.
  ///
  /// Raises each element to the specified exponent.
  /// Supports both scalar and array exponents with broadcasting.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[2, 3], [4, 5]]);
  ///
  /// // Scalar exponent
  /// var squared = arr.pow(2);
  /// print(squared.toNestedList()); // [[4, 9], [16, 25]]
  ///
  /// // Array exponent
  /// var exponents = NDArray([[1, 2], [2, 3]]);
  /// var result = arr.pow(exponents);
  /// // [[2^1, 3^2], [4^2, 5^3]] = [[2, 9], [16, 125]]
  /// ```
  NDArray pow(dynamic exponent) {
    if (exponent is num) {
      return map((x) => math.pow(x, exponent));
    } else if (exponent is NDArray) {
      return _elementWise(exponent, (a, b) => math.pow(a, b));
    }
    throw ArgumentError('Invalid exponent type: ${exponent.runtimeType}');
  }

  /// Element-wise square root.
  ///
  /// Returns a new array with the square root of each element.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[4, 9], [16, 25]]);
  /// var result = arr.sqrt();
  /// print(result.toNestedList()); // [[2.0, 3.0], [4.0, 5.0]]
  ///
  /// // Works with decimals
  /// var arr2 = NDArray([0.25, 1.0, 2.25]);
  /// var result2 = arr2.sqrt(); // [0.5, 1.0, 1.5]
  /// ```
  NDArray sqrt() => map((x) => math.sqrt(x));

  /// Element-wise absolute value.
  ///
  /// Returns a new array with the absolute value of each element.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[-5, 3], [-2, -7]]);
  /// var result = arr.abs();
  /// print(result.toNestedList()); // [[5, 3], [2, 7]]
  ///
  /// var arr2 = NDArray([1.5, -2.3, 0, -0.1]);
  /// var result2 = arr2.abs(); // [1.5, 2.3, 0, 0.1]
  /// ```
  NDArray abs() => map((x) => (x as num).abs());

  /// Element-wise exponential (e^x).
  ///
  /// Returns a new array with e raised to the power of each element.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[0, 1], [2, 3]]);
  /// var result = arr.exp();
  /// // [[e^0, e^1], [e^2, e^3]] ≈ [[1.0, 2.718], [7.389, 20.086]]
  ///
  /// // Useful for activation functions
  /// var logits = NDArray([-1.0, 0.0, 1.0]);
  /// var softmaxNumerator = logits.exp();
  /// ```
  NDArray exp() => map((x) => math.exp(x));

  /// Element-wise natural logarithm.
  ///
  /// Returns a new array with the natural log of each element.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2.718], [7.389, 20.086]]);
  /// var result = arr.log();
  /// // [[ln(1), ln(e)], [ln(e^2), ln(e^3)]] ≈ [[0, 1], [2, 3]]
  ///
  /// // Log of powers of 10
  /// var arr2 = NDArray([1, 10, 100]);
  /// var result2 = arr2.log(); // [0, 2.303, 4.605]
  /// ```
  NDArray log() => map((x) => math.log(x));

  // ============================================================================
  // Comparison Operations
  // ============================================================================

  /// Element-wise equality comparison.
  ///
  /// Returns an array of 1s and 0s where 1 indicates equality.
  /// Supports scalar and array comparisons with broadcasting.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [2, 2, 4]]);
  ///
  /// // Compare with scalar
  /// var result1 = arr.eq(2);
  /// print(result1.toNestedList()); // [[0, 1, 0], [1, 1, 0]]
  ///
  /// // Compare with array
  /// var arr2 = NDArray([[1, 2, 3], [4, 2, 4]]);
  /// var result2 = arr.eq(arr2);
  /// print(result2.toNestedList()); // [[1, 1, 1], [0, 1, 1]]
  /// ```
  NDArray eq(dynamic other) {
    if (other is num) {
      return map((x) => x == other ? 1 : 0);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a == b ? 1 : 0);
    }
    throw ArgumentError('Cannot compare with ${other.runtimeType}');
  }

  /// Element-wise greater than comparison.
  ///
  /// Returns an array of 1s and 0s where 1 indicates the condition is true.
  /// Supports scalar and array comparisons with broadcasting.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 5, 3], [7, 2, 9]]);
  ///
  /// // Compare with scalar
  /// var result1 = arr.gt(4);
  /// print(result1.toNestedList()); // [[0, 1, 0], [1, 0, 1]]
  ///
  /// // Compare arrays
  /// var arr2 = NDArray([[2, 3, 4], [5, 6, 7]]);
  /// var result2 = arr.gt(arr2);
  /// print(result2.toNestedList()); // [[0, 1, 0], [1, 0, 1]]
  /// ```
  NDArray gt(dynamic other) {
    if (other is num) {
      return map((x) => x > other ? 1 : 0);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a > b ? 1 : 0);
    }
    throw ArgumentError('Cannot compare with ${other.runtimeType}');
  }

  /// Element-wise less than comparison.
  ///
  /// Returns an array of 1s and 0s where 1 indicates the condition is true.
  /// Supports scalar and array comparisons with broadcasting.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 5, 3], [7, 2, 9]]);
  ///
  /// // Compare with scalar
  /// var result1 = arr.lt(5);
  /// print(result1.toNestedList()); // [[1, 0, 1], [0, 1, 0]]
  ///
  /// // Find elements less than mean
  /// var avgVal = arr.mean();
  /// var belowAvg = arr.lt(avgVal);
  /// ```
  NDArray lt(dynamic other) {
    if (other is num) {
      return map((x) => x < other ? 1 : 0);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a < b ? 1 : 0);
    }
    throw ArgumentError('Cannot compare with ${other.runtimeType}');
  }

  /// Element-wise greater than or equal comparison.
  ///
  /// Returns an array of 1s and 0s where 1 indicates the condition is true.
  /// Supports scalar and array comparisons with broadcasting.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 5, 3], [5, 2, 9]]);
  ///
  /// // Compare with scalar
  /// var result = arr.gte(5);
  /// print(result.toNestedList()); // [[0, 1, 0], [1, 0, 1]]
  /// ```
  NDArray gte(dynamic other) {
    if (other is num) {
      return map((x) => x >= other ? 1 : 0);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a >= b ? 1 : 0);
    }
    throw ArgumentError('Cannot compare with ${other.runtimeType}');
  }

  /// Element-wise less than or equal comparison.
  ///
  /// Returns an array of 1s and 0s where 1 indicates the condition is true.
  /// Supports scalar and array comparisons with broadcasting.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 5, 3], [5, 2, 9]]);
  ///
  /// // Compare with scalar
  /// var result = arr.lte(5);
  /// print(result.toNestedList()); // [[1, 1, 1], [1, 1, 0]]
  /// ```
  NDArray lte(dynamic other) {
    if (other is num) {
      return map((x) => x <= other ? 1 : 0);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a <= b ? 1 : 0);
    }
    throw ArgumentError('Cannot compare with ${other.runtimeType}');
  }

  // ============================================================================
  // Aggregation Operations
  // ============================================================================

  /// Sum of all elements or along a specific axis.
  ///
  /// If [axis] is null, returns the sum of all elements as a scalar.
  /// If [axis] is specified, returns an NDArray with the sum computed along that axis.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
  ///
  /// // Sum all elements
  /// print(arr.sum()); // 21
  ///
  /// // Sum along axis 0 (columns)
  /// var colSum = arr.sum(axis: 0);
  /// print(colSum.toFlatList()); // [5, 7, 9]
  ///
  /// // Sum along axis 1 (rows)
  /// var rowSum = arr.sum(axis: 1);
  /// print(rowSum.toFlatList()); // [6, 15]
  /// ```
  dynamic sum({int? axis}) {
    if (axis == null) {
      num total = 0;
      _iterateAll((value) => total += value as num);
      return total;
    }
    return _reduceAxis(axis, (values) {
      num total = 0;
      for (var v in values) {
        total += v as num;
      }
      return total;
    });
  }

  /// Mean (average) of all elements or along a specific axis.
  ///
  /// If [axis] is null, returns the mean of all elements as a scalar.
  /// If [axis] is specified, returns an NDArray with the mean computed along that axis.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
  ///
  /// // Mean of all elements
  /// print(arr.mean()); // 3.5
  ///
  /// // Mean along axis 0 (columns)
  /// var colMean = arr.mean(axis: 0);
  /// print(colMean.toFlatList()); // [2.5, 3.5, 4.5]
  ///
  /// // Mean along axis 1 (rows)
  /// var rowMean = arr.mean(axis: 1);
  /// print(rowMean.toFlatList()); // [2.0, 5.0]
  /// ```
  dynamic mean({int? axis}) {
    if (axis == null) {
      return (sum() as num) / size;
    }
    return _reduceAxis(axis, (values) {
      num total = 0;
      for (var v in values) {
        total += v as num;
      }
      return total / values.length;
    });
  }

  /// Maximum value of all elements or along a specific axis.
  ///
  /// If [axis] is null, returns the maximum value as a scalar.
  /// If [axis] is specified, returns an NDArray with the maximum computed along that axis.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 9, 3], [4, 2, 8]]);
  ///
  /// // Max of all elements
  /// print(arr.max()); // 9
  ///
  /// // Max along axis 0 (columns)
  /// var colMax = arr.max(axis: 0);
  /// print(colMax.toFlatList()); // [4, 9, 8]
  ///
  /// // Max along axis 1 (rows)
  /// var rowMax = arr.max(axis: 1);
  /// print(rowMax.toFlatList()); // [9, 8]
  /// ```
  dynamic max({int? axis}) {
    if (axis == null) {
      num? maxVal;
      _iterateAll((value) {
        final numVal = value as num;
        if (maxVal == null || numVal > maxVal!) {
          maxVal = numVal;
        }
      });
      return maxVal ?? double.nan;
    }
    return _reduceAxis(axis, (values) {
      num? maxVal;
      for (var v in values) {
        final numVal = v as num;
        if (maxVal == null || numVal > maxVal) {
          maxVal = numVal;
        }
      }
      return maxVal ?? double.nan;
    });
  }

  /// Minimum value of all elements or along a specific axis.
  ///
  /// If [axis] is null, returns the minimum value as a scalar.
  /// If [axis] is specified, returns an NDArray with the minimum computed along that axis.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[5, 2, 9], [3, 7, 1]]);
  ///
  /// // Min of all elements
  /// print(arr.min()); // 1
  ///
  /// // Min along axis 0 (columns)
  /// var colMin = arr.min(axis: 0);
  /// print(colMin.toFlatList()); // [3, 2, 1]
  ///
  /// // Min along axis 1 (rows)
  /// var rowMin = arr.min(axis: 1);
  /// print(rowMin.toFlatList()); // [2, 1]
  /// ```
  dynamic min({int? axis}) {
    if (axis == null) {
      num? minVal;
      _iterateAll((value) {
        final numVal = value as num;
        if (minVal == null || numVal < minVal!) {
          minVal = numVal;
        }
      });
      return minVal ?? double.nan;
    }
    return _reduceAxis(axis, (values) {
      num? minVal;
      for (var v in values) {
        final numVal = v as num;
        if (minVal == null || numVal < minVal) {
          minVal = numVal;
        }
      }
      return minVal ?? double.nan;
    });
  }

  /// Standard deviation of all elements or along a specific axis.
  ///
  /// If [axis] is null, returns the standard deviation of all elements as a scalar.
  /// If [axis] is specified, returns an NDArray with the standard deviation computed along that axis.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
  ///
  /// // Standard deviation of all elements
  /// print(arr.std()); // ≈ 1.707
  ///
  /// // Std along axis 0 (columns)
  /// var colStd = arr.std(axis: 0);
  /// // Each column's std
  ///
  /// // Std along axis 1 (rows)
  /// var rowStd = arr.std(axis: 1);
  /// // Each row's std
  /// ```
  dynamic std({int? axis}) {
    if (axis == null) {
      final m = mean() as double;
      num sumSquaredDiff = 0;
      _iterateAll((value) {
        final diff = (value as num) - m;
        sumSquaredDiff += diff * diff;
      });
      return math.sqrt(sumSquaredDiff / size);
    }
    return _reduceAxis(axis, (values) {
      // Calculate mean of values
      num total = 0;
      for (var v in values) {
        total += v as num;
      }
      final m = total / values.length;

      // Calculate sum of squared differences
      num sumSquaredDiff = 0;
      for (var v in values) {
        final diff = (v as num) - m;
        sumSquaredDiff += diff * diff;
      }

      return math.sqrt(sumSquaredDiff / values.length);
    });
  }

  /// Variance of all elements.
  ///
  /// Computes the variance (average squared deviation from mean).
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
  /// print(arr.variance()); // ≈ 2.917
  ///
  /// // Relationship: variance = std^2
  /// var std = arr.std();
  /// var variance = std * std; // Same as arr.variance()
  /// ```
  double variance() {
    final m = mean();
    num sumSquaredDiff = 0;
    _iterateAll((value) {
      final diff = (value as num) - m;
      sumSquaredDiff += diff * diff;
    });
    return sumSquaredDiff / size;
  }

  /// Product of all elements.
  ///
  /// Multiplies all elements together and returns the result.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2], [3, 4]]);
  /// print(arr.prod()); // 24 (1 * 2 * 3 * 4)
  ///
  /// var arr2 = NDArray([2, 3, 4]);
  /// print(arr2.prod()); // 24
  ///
  /// // Useful for calculating factorials, volumes, etc.
  /// var dimensions = NDArray([5, 10, 3]);
  /// var volume = dimensions.prod(); // 150
  /// ```
  num prod() {
    num product = 1;
    _iterateAll((value) => product *= value as num);
    return product;
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Performs element-wise operation with broadcasting support.
  NDArray _elementWise(NDArray other, dynamic Function(dynamic, dynamic) op) {
    // Check if shapes are compatible for broadcasting
    final broadcastShape = _getBroadcastShape(shape, other.shape);

    return NDArray.generate(broadcastShape.toList(), (indices) {
      final aIndices = _broadcastIndices(indices, shape);
      final bIndices = _broadcastIndices(indices, other.shape);
      return op(getValue(aIndices), other.getValue(bIndices));
    });
  }

  /// Gets the broadcast shape for two shapes.
  Shape _getBroadcastShape(Shape a, Shape b) {
    final maxDim = math.max(a.ndim, b.ndim);
    final result = <int>[];

    for (int i = 0; i < maxDim; i++) {
      final aIdx = a.ndim - 1 - i;
      final bIdx = b.ndim - 1 - i;

      final aDim = aIdx >= 0 ? a[aIdx] : 1;
      final bDim = bIdx >= 0 ? b[bIdx] : 1;

      if (aDim == bDim) {
        result.insert(0, aDim);
      } else if (aDim == 1) {
        result.insert(0, bDim);
      } else if (bDim == 1) {
        result.insert(0, aDim);
      } else {
        throw ArgumentError(
            'Shapes $a and $b are not compatible for broadcasting');
      }
    }

    return Shape(result);
  }

  /// Broadcasts indices from result shape to array shape.
  List<int> _broadcastIndices(List<int> indices, Shape targetShape) {
    final result = <int>[];
    final offset = indices.length - targetShape.ndim;

    for (int i = 0; i < targetShape.ndim; i++) {
      final idx = i + offset;
      if (idx >= 0 && targetShape[i] > 1) {
        result.add(indices[idx]);
      } else {
        result.add(0);
      }
    }

    return result;
  }

  /// Iterates over all elements.
  void _iterateAll(void Function(dynamic) fn) {
    void iterate(List<int> indices, int dim) {
      if (dim == ndim) {
        fn(getValue(indices));
        return;
      }

      for (int i = 0; i < shape[dim]; i++) {
        iterate([...indices, i], dim + 1);
      }
    }

    iterate([], 0);
  }

  /// Reduces along a specific axis.
  NDArray _reduceAxis(int axis, dynamic Function(List<dynamic>) reducer) {
    if (axis < 0 || axis >= ndim) {
      throw ArgumentError('Axis $axis out of bounds for ${ndim}D array');
    }

    // Calculate result shape (remove the reduced axis)
    final resultDims = <int>[];
    for (int i = 0; i < ndim; i++) {
      if (i != axis) {
        resultDims.add(shape[i]);
      }
    }

    // Handle scalar result
    if (resultDims.isEmpty) {
      final values = <dynamic>[];
      for (int i = 0; i < shape[axis]; i++) {
        values.add(getValue([i]));
      }
      return NDArray([reducer(values)]);
    }

    return NDArray.generate(resultDims, (indices) {
      // Collect values along the axis
      final values = <dynamic>[];
      for (int i = 0; i < shape[axis]; i++) {
        final fullIndices = <int>[];
        int resultIdx = 0;
        for (int dim = 0; dim < ndim; dim++) {
          if (dim == axis) {
            fullIndices.add(i);
          } else {
            fullIndices.add(indices[resultIdx]);
            resultIdx++;
          }
        }
        values.add(getValue(fullIndices));
      }
      return reducer(values);
    });
  }
}
