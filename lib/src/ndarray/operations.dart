/// NDArray operations including element-wise, broadcasting, and aggregations.
library;

import 'dart:math' as math;
import 'ndarray.dart';
import '../core/shape.dart';

/// Extension providing mathematical and statistical operations on NDArray.
extension NDArrayOperations on NDArray {
  // ============================================================================
  // Element-wise Arithmetic Operations
  // ============================================================================

  /// Element-wise addition.
  NDArray operator +(dynamic other) {
    if (other is num) {
      return map((x) => x + other);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a + b);
    }
    throw ArgumentError('Cannot add ${other.runtimeType} to NDArray');
  }

  /// Element-wise subtraction.
  NDArray operator -(dynamic other) {
    if (other is num) {
      return map((x) => x - other);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a - b);
    }
    throw ArgumentError('Cannot subtract ${other.runtimeType} from NDArray');
  }

  /// Element-wise multiplication.
  NDArray operator *(dynamic other) {
    if (other is num) {
      return map((x) => x * other);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a * b);
    }
    throw ArgumentError('Cannot multiply NDArray by ${other.runtimeType}');
  }

  /// Element-wise division.
  NDArray operator /(dynamic other) {
    if (other is num) {
      return map((x) => x / other);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a / b);
    }
    throw ArgumentError('Cannot divide NDArray by ${other.runtimeType}');
  }

  /// Element-wise negation.
  NDArray operator -() {
    return map((x) => -x);
  }

  /// Element-wise power.
  NDArray pow(dynamic exponent) {
    if (exponent is num) {
      return map((x) => math.pow(x, exponent));
    } else if (exponent is NDArray) {
      return _elementWise(exponent, (a, b) => math.pow(a, b));
    }
    throw ArgumentError('Invalid exponent type: ${exponent.runtimeType}');
  }

  /// Element-wise square root.
  NDArray sqrt() => map((x) => math.sqrt(x));

  /// Element-wise absolute value.
  NDArray abs() => map((x) => (x as num).abs());

  /// Element-wise exponential.
  NDArray exp() => map((x) => math.exp(x));

  /// Element-wise natural logarithm.
  NDArray log() => map((x) => math.log(x));

  // ============================================================================
  // Comparison Operations
  // ============================================================================

  /// Element-wise equality comparison.
  NDArray eq(dynamic other) {
    if (other is num) {
      return map((x) => x == other ? 1 : 0);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a == b ? 1 : 0);
    }
    throw ArgumentError('Cannot compare with ${other.runtimeType}');
  }

  /// Element-wise greater than comparison.
  NDArray gt(dynamic other) {
    if (other is num) {
      return map((x) => x > other ? 1 : 0);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a > b ? 1 : 0);
    }
    throw ArgumentError('Cannot compare with ${other.runtimeType}');
  }

  /// Element-wise less than comparison.
  NDArray lt(dynamic other) {
    if (other is num) {
      return map((x) => x < other ? 1 : 0);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a < b ? 1 : 0);
    }
    throw ArgumentError('Cannot compare with ${other.runtimeType}');
  }

  /// Element-wise greater than or equal comparison.
  NDArray gte(dynamic other) {
    if (other is num) {
      return map((x) => x >= other ? 1 : 0);
    } else if (other is NDArray) {
      return _elementWise(other, (a, b) => a >= b ? 1 : 0);
    }
    throw ArgumentError('Cannot compare with ${other.runtimeType}');
  }

  /// Element-wise less than or equal comparison.
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

  /// Sum along a specific axis (deprecated - use sum(axis: axis) instead).
  @Deprecated('Use sum(axis: axis) instead')
  NDArray sumAxis(int axis) {
    return sum(axis: axis) as NDArray;
  }

  /// Mean (average) of all elements or along a specific axis.
  ///
  /// If [axis] is null, returns the mean of all elements as a scalar.
  /// If [axis] is specified, returns an NDArray with the mean computed along that axis.
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

  /// Mean along a specific axis (deprecated - use mean(axis: axis) instead).
  @Deprecated('Use mean(axis: axis) instead')
  NDArray meanAxis(int axis) {
    return mean(axis: axis) as NDArray;
  }

  /// Maximum value of all elements or along a specific axis.
  ///
  /// If [axis] is null, returns the maximum value as a scalar.
  /// If [axis] is specified, returns an NDArray with the maximum computed along that axis.
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
        if (maxVal == null || numVal > maxVal!) {
          maxVal = numVal;
        }
      }
      return maxVal ?? double.nan;
    });
  }

  /// Maximum along a specific axis (deprecated - use max(axis: axis) instead).
  @Deprecated('Use max(axis: axis) instead')
  NDArray maxAxis(int axis) {
    return max(axis: axis) as NDArray;
  }

  /// Minimum value of all elements or along a specific axis.
  ///
  /// If [axis] is null, returns the minimum value as a scalar.
  /// If [axis] is specified, returns an NDArray with the minimum computed along that axis.
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
        if (minVal == null || numVal < minVal!) {
          minVal = numVal;
        }
      }
      return minVal ?? double.nan;
    });
  }

  /// Minimum along a specific axis (deprecated - use min(axis: axis) instead).
  @Deprecated('Use min(axis: axis) instead')
  NDArray minAxis(int axis) {
    return min(axis: axis) as NDArray;
  }

  /// Standard deviation of all elements or along a specific axis.
  ///
  /// If [axis] is null, returns the standard deviation of all elements as a scalar.
  /// If [axis] is specified, returns an NDArray with the standard deviation computed along that axis.
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

  /// Variance.
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
