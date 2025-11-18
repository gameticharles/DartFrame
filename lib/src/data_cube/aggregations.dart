/// Aggregation operations for DataCube.
library;

import '../data_frame/data_frame.dart';
import 'datacube.dart';
import '../ndarray/ndarray.dart';
import '../ndarray/operations.dart';

/// Extension providing aggregation operations on DataCube.
///
/// Aggregations can be performed along different axes:
/// - Axis 0 (depth): Aggregate across sheets
/// - Axis 1 (rows): Aggregate across rows within each sheet
/// - Axis 2 (columns): Aggregate across columns within each sheet
extension DataCubeAggregations on DataCube {
  /// Aggregates along the depth axis (across sheets).
  ///
  /// Returns a DataFrame with the aggregated values.
  ///
  /// Supported operations: 'sum', 'mean', 'max', 'min'
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.generate(3, 4, 5, (d, r, c) => d + r + c);
  /// var result = cube.aggregateDepth('sum');
  /// // Result is a 4x5 DataFrame with sums across depth
  /// ```
  DataFrame aggregateDepth(String operation) {
    return _aggregate(0, operation);
  }

  /// Aggregates along the rows axis.
  ///
  /// Returns a DataFrame with the aggregated values.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.generate(3, 4, 5, (d, r, c) => d + r + c);
  /// var result = cube.aggregateRows('mean');
  /// // Result is a 3x5 DataFrame with means across rows
  /// ```
  DataFrame aggregateRows(String operation) {
    return _aggregate(1, operation);
  }

  /// Aggregates along the columns axis.
  ///
  /// Returns a DataFrame with the aggregated values.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.generate(3, 4, 5, (d, r, c) => d + r + c);
  /// var result = cube.aggregateColumns('max');
  /// // Result is a 3x4 DataFrame with maxes across columns
  /// ```
  DataFrame aggregateColumns(String operation) {
    return _aggregate(2, operation);
  }

  /// Sums values along the specified axis.
  ///
  /// If axis is null, returns the sum of all elements as a 1x1 DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.ones(3, 4, 5);
  /// var depthSum = cube.sum(axis: 0);  // 4x5 DataFrame
  /// var totalSum = cube.sum();          // 1x1 DataFrame with value 60
  /// ```
  DataFrame sum({int? axis}) {
    if (axis == null) {
      final total = data.sum();
      return DataFrame([
        [total]
      ]);
    }
    return _aggregate(axis, 'sum');
  }

  /// Calculates mean values along the specified axis.
  ///
  /// If axis is null, returns the mean of all elements as a 1x1 DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.ones(3, 4, 5);
  /// var depthMean = cube.mean(axis: 0);  // 4x5 DataFrame
  /// var totalMean = cube.mean();          // 1x1 DataFrame with value 1.0
  /// ```
  DataFrame mean({int? axis}) {
    if (axis == null) {
      final avg = data.mean();
      return DataFrame([
        [avg]
      ]);
    }
    return _aggregate(axis, 'mean');
  }

  /// Finds maximum values along the specified axis.
  ///
  /// If axis is null, returns the maximum of all elements as a 1x1 DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.generate(3, 4, 5, (d, r, c) => d * 100 + r * 10 + c);
  /// var depthMax = cube.max(axis: 0);  // 4x5 DataFrame
  /// var totalMax = cube.max();          // 1x1 DataFrame
  /// ```
  DataFrame max({int? axis}) {
    if (axis == null) {
      final maximum = data.max();
      return DataFrame([
        [maximum]
      ]);
    }
    return _aggregate(axis, 'max');
  }

  /// Finds minimum values along the specified axis.
  ///
  /// If axis is null, returns the minimum of all elements as a 1x1 DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.generate(3, 4, 5, (d, r, c) => d * 100 + r * 10 + c);
  /// var depthMin = cube.min(axis: 0);  // 4x5 DataFrame
  /// var totalMin = cube.min();          // 1x1 DataFrame
  /// ```
  DataFrame min({int? axis}) {
    if (axis == null) {
      final minimum = data.min();
      return DataFrame([
        [minimum]
      ]);
    }
    return _aggregate(axis, 'min');
  }

  /// Standard deviation along the specified axis.
  ///
  /// If axis is null, returns the std of all elements as a 1x1 DataFrame.
  DataFrame std({int? axis}) {
    if (axis == null) {
      final stdDev = data.std();
      return DataFrame([
        [stdDev]
      ]);
    }
    return _aggregate(axis, 'std');
  }

  /// Variance along the specified axis.
  ///
  /// If axis is null, returns the variance of all elements as a 1x1 DataFrame.
  DataFrame variance({int? axis}) {
    if (axis == null) {
      final var_ = data.variance();
      return DataFrame([
        [var_]
      ]);
    }
    return _aggregate(axis, 'variance');
  }

  /// Product of values along the specified axis.
  ///
  /// If axis is null, returns the product of all elements as a 1x1 DataFrame.
  DataFrame prod({int? axis}) {
    if (axis == null) {
      final product = data.prod();
      return DataFrame([
        [product]
      ]);
    }
    return _aggregate(axis, 'prod');
  }

  // Helper method to perform aggregation
  DataFrame _aggregate(int axis, String operation) {
    if (axis < 0 || axis > 2) {
      throw ArgumentError('Axis must be 0 (depth), 1 (rows), or 2 (columns)');
    }

    NDArray result;
    switch (operation.toLowerCase()) {
      case 'sum':
        result = data.sum(axis: axis);
        break;
      case 'mean':
        result = data.mean(axis: axis);
        break;
      case 'max':
        result = data.max(axis: axis);
        break;
      case 'min':
        result = data.min(axis: axis);
        break;
      case 'std':
        result = _stdAxis(axis);
        break;
      case 'variance':
        result = _varianceAxis(axis);
        break;
      case 'prod':
        result = _prodAxis(axis);
        break;
      default:
        throw ArgumentError('Unknown operation: $operation');
    }

    // Convert NDArray to DataFrame
    return _ndarrayToDataFrame(result);
  }

  /// Calculates standard deviation along an axis.
  NDArray _stdAxis(int axis) {
    // Calculate mean along axis
    final meanResult = data.mean(axis: axis);

    // Calculate squared differences
    final squaredDiffs = NDArray.generate(data.shape.toList(), (indices) {
      final value = data.getValue(indices);
      final meanIndices = <int>[];
      for (int i = 0; i < data.ndim; i++) {
        if (i != axis) {
          meanIndices.add(indices[i]);
        }
      }
      final meanValue = meanResult.getValue(meanIndices);
      final diff = (value as num) - (meanValue as num);
      return diff * diff;
    });

    // Sum squared differences and divide by count
    final sumSquaredDiffs = squaredDiffs.sum(axis: axis);
    final count = data.shape[axis];

    return sumSquaredDiffs.map((x) => (x as num) / count).sqrt();
  }

  /// Calculates variance along an axis.
  NDArray _varianceAxis(int axis) {
    final meanResult = data.mean(axis: axis);

    final squaredDiffs = NDArray.generate(data.shape.toList(), (indices) {
      final value = data.getValue(indices);
      final meanIndices = <int>[];
      for (int i = 0; i < data.ndim; i++) {
        if (i != axis) {
          meanIndices.add(indices[i]);
        }
      }
      final meanValue = meanResult.getValue(meanIndices);
      final diff = (value as num) - (meanValue as num);
      return diff * diff;
    });

    final sumSquaredDiffs = squaredDiffs.sum(axis: axis);
    final count = data.shape[axis];

    return sumSquaredDiffs.map((x) => (x as num) / count);
  }

  /// Calculates product along an axis.
  NDArray _prodAxis(int axis) {
    final resultShape = <int>[];
    for (int i = 0; i < data.ndim; i++) {
      if (i != axis) {
        resultShape.add(data.shape[i]);
      }
    }

    return NDArray.generate(resultShape, (indices) {
      num product = 1;
      for (int i = 0; i < data.shape[axis]; i++) {
        final fullIndices = <int>[];
        int resultIdx = 0;
        for (int dim = 0; dim < data.ndim; dim++) {
          if (dim == axis) {
            fullIndices.add(i);
          } else {
            fullIndices.add(indices[resultIdx]);
            resultIdx++;
          }
        }
        product *= data.getValue(fullIndices) as num;
      }
      return product;
    });
  }

  /// Converts a 2D NDArray to DataFrame.
  DataFrame _ndarrayToDataFrame(NDArray array) {
    if (array.ndim != 2) {
      throw ArgumentError('Can only convert 2D NDArray to DataFrame');
    }

    final rows = array.shape[0];
    final cols = array.shape[1];
    final data = <List<dynamic>>[];

    for (int r = 0; r < rows; r++) {
      final row = <dynamic>[];
      for (int c = 0; c < cols; c++) {
        row.add(array.getValue([r, c]));
      }
      data.add(row);
    }

    return DataFrame(data);
  }
}
