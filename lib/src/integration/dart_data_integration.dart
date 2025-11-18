/// Integration layer for seamless conversions between DartData types.
library;

import '../core/dart_data.dart';
import '../series/series.dart';
import '../data_frame/data_frame.dart';
import '../data_cube/datacube.dart';
import '../ndarray/ndarray.dart';

/// Extension providing conversion methods for DartData types (NDArray, DataCube).
///
/// Enables seamless conversions between Series, DataFrame, DataCube, and NDArray.
///
/// Example:
/// ```dart
/// // NDArray to Series
/// var array1d = NDArray([1, 2, 3, 4, 5]);
/// var series = array1d.toSeries();
///
/// // 2D NDArray to DataFrame
/// var array2d = NDArray([[1, 2], [3, 4], [5, 6]]);
/// var df = array2d.toDataFrame();
///
/// // 3D NDArray to DataCube
/// var array3d = NDArray.generate([2, 3, 4], (indices) => indices[0] * 10 + indices[1]);
/// var cube = array3d.toDataCube();
/// ```
extension DartDataConversion on DartData {
  /// Converts this DartData to a Series.
  ///
  /// Conversion rules:
  /// - 1D NDArray → Series directly
  /// - 2D NDArray → Extract first column as Series
  /// - 3D NDArray → Flatten and convert to Series
  /// - Series → Returns self
  /// - DataFrame → Extract first column as Series
  /// - DataCube → Flatten and convert to Series
  ///
  /// Throws [ArgumentError] if conversion is not possible.
  Series toSeries() {
    if (this is Series) {
      return this as Series;
    }

    if (this is NDArray) {
      final array = this as NDArray;

      if (array.ndim == 1) {
        // 1D array → Series directly
        final data = array.toFlatList();
        return Series(data, name: 'series_0');
      } else if (array.ndim == 2) {
        // 2D array → Extract first column
        final data = <dynamic>[];
        for (int i = 0; i < array.shape[0]; i++) {
          data.add(array.getValue([i, 0]));
        }
        return Series(data, name: 'col_0');
      } else if (array.ndim == 3) {
        // 3D array → Flatten
        final data = array.toFlatList();
        return Series(data, name: 'flattened');
      } else {
        throw ArgumentError('Cannot convert ${array.ndim}D NDArray to Series. '
            'Only 1D, 2D, and 3D arrays are supported.');
      }
    }

    if (this is DataFrame) {
      final df = this as DataFrame;
      if (df.columnCount == 0) {
        throw ArgumentError('Cannot convert empty DataFrame to Series');
      }
      // Extract first column
      return df[df.columns[0]];
    }

    if (this is DataCube) {
      final cube = this as DataCube;
      // Flatten the cube
      final data = cube.flatten().toFlatList();
      return Series(data, name: 'flattened');
    }

    throw ArgumentError('Cannot convert $runtimeType to Series. '
        'Supported types: NDArray (1D, 2D, 3D), Series, DataFrame, DataCube');
  }

  /// Converts this DartData to a DataFrame.
  ///
  /// Conversion rules:
  /// - 2D NDArray → DataFrame directly
  /// - 1D NDArray → Single column DataFrame
  /// - 3D NDArray → Extract first frame (depth=0)
  /// - Series → Single column DataFrame
  /// - DataFrame → Returns self
  /// - DataCube → Extract first frame
  ///
  /// Throws [ArgumentError] if conversion is not possible.
  DataFrame toDataFrame() {
    if (this is DataFrame) {
      return this as DataFrame;
    }

    if (this is NDArray) {
      final array = this as NDArray;

      if (array.ndim == 2) {
        // 2D array → DataFrame directly
        final rows = <List<dynamic>>[];
        for (int i = 0; i < array.shape[0]; i++) {
          final row = <dynamic>[];
          for (int j = 0; j < array.shape[1]; j++) {
            row.add(array.getValue([i, j]));
          }
          rows.add(row);
        }

        // Generate column names
        final columns = List.generate(array.shape[1], (i) => 'col_$i');
        return DataFrame(rows, columns: columns);
      } else if (array.ndim == 1) {
        // 1D array → Single column DataFrame
        final data = array.toFlatList();
        return DataFrame.fromMap({'col_0': data});
      } else if (array.ndim == 3) {
        // 3D array → Extract first frame
        final rows = <List<dynamic>>[];
        for (int i = 0; i < array.shape[1]; i++) {
          final row = <dynamic>[];
          for (int j = 0; j < array.shape[2]; j++) {
            row.add(array.getValue([0, i, j]));
          }
          rows.add(row);
        }

        final columns = List.generate(array.shape[2], (i) => 'col_$i');
        return DataFrame(rows, columns: columns);
      } else {
        throw ArgumentError(
            'Cannot convert ${array.ndim}D NDArray to DataFrame. '
            'Only 1D, 2D, and 3D arrays are supported.');
      }
    }

    if (this is Series) {
      final series = this as Series;
      return DataFrame.fromMap({series.name: series.data});
    }

    if (this is DataCube) {
      final cube = this as DataCube;
      // Extract first frame
      return cube.getFrame(0);
    }

    throw ArgumentError('Cannot convert $runtimeType to DataFrame. '
        'Supported types: NDArray (1D, 2D, 3D), Series, DataFrame, DataCube');
  }

  /// Converts this DartData to a DataCube.
  ///
  /// Conversion rules:
  /// - 3D NDArray → DataCube directly
  /// - 2D NDArray → Single frame DataCube (depth=1)
  /// - 1D NDArray → Reshape to 1x1xN DataCube
  /// - Series → Reshape to 1x1xN DataCube
  /// - DataFrame → Single frame DataCube
  /// - DataCube → Returns self
  ///
  /// Throws [ArgumentError] if conversion is not possible.
  DataCube toDataCube() {
    if (this is DataCube) {
      return this as DataCube;
    }

    if (this is NDArray) {
      final array = this as NDArray;

      if (array.ndim == 3) {
        // 3D array → DataCube directly
        return DataCube.fromNDArray(array);
      } else if (array.ndim == 2) {
        // 2D array → Single frame DataCube
        final reshaped = NDArray.generate([1, array.shape[0], array.shape[1]],
            (indices) => array.getValue([indices[1], indices[2]]));
        return DataCube.fromNDArray(reshaped);
      } else if (array.ndim == 1) {
        // 1D array → Reshape to 1x1xN
        final reshaped = NDArray.generate(
            [1, 1, array.shape[0]], (indices) => array.getValue([indices[2]]));
        return DataCube.fromNDArray(reshaped);
      } else {
        throw ArgumentError(
            'Cannot convert ${array.ndim}D NDArray to DataCube. '
            'Only 1D, 2D, and 3D arrays are supported.');
      }
    }

    if (this is Series) {
      final series = this as Series;
      // Reshape to 1x1xN
      final array = NDArray.generate(
          [1, 1, series.length], (indices) => series.data[indices[2]]);
      return DataCube.fromNDArray(array);
    }

    if (this is DataFrame) {
      final df = this as DataFrame;
      // Single frame DataCube
      return DataCube.fromDataFrames([df]);
    }

    throw ArgumentError('Cannot convert $runtimeType to DataCube. '
        'Supported types: NDArray (1D, 2D, 3D), Series, DataFrame, DataCube');
  }

  /// Converts this DartData to an NDArray.
  ///
  /// Conversion rules:
  /// - NDArray → Returns self
  /// - Series → 1D NDArray
  /// - DataFrame → 2D NDArray
  /// - DataCube → 3D NDArray
  ///
  /// Throws [ArgumentError] if conversion is not possible.
  NDArray toNDArray() {
    if (this is NDArray) {
      return this as NDArray;
    }

    if (this is Series) {
      final series = this as Series;
      return NDArray(series.data);
    }

    if (this is DataFrame) {
      final df = this as DataFrame;

      if (df.rowCount == 0 || df.columnCount == 0) {
        // Empty DataFrame
        return NDArray.zeros([df.rowCount, df.columnCount]);
      }

      // Convert DataFrame to 2D array
      final rows = <List<dynamic>>[];
      for (int i = 0; i < df.rowCount; i++) {
        final row = <dynamic>[];
        for (int j = 0; j < df.columnCount; j++) {
          row.add(df.iloc(i, j));
        }
        rows.add(row);
      }
      return NDArray(rows);
    }

    if (this is DataCube) {
      final cube = this as DataCube;
      return cube.toNDArray();
    }

    throw ArgumentError('Cannot convert $runtimeType to NDArray. '
        'Supported types: NDArray, Series, DataFrame, DataCube');
  }
}

/// Extension providing conversion methods for Series.
///
/// Example:
/// ```dart
/// var series = Series([1, 2, 3, 4], name: 'data');
/// var array = series.toNDArray();
/// var df = series.toDataFrame();
/// var cube = series.toDataCube();
/// ```
extension SeriesConversion on Series {
  /// Converts this Series to an NDArray.
  ///
  /// Returns a 1D NDArray containing the series data.
  NDArray toNDArray() {
    return NDArray(data);
  }

  /// Converts this Series to a DataFrame.
  ///
  /// Returns a single-column DataFrame with the series name as the column name.
  DataFrame toDataFrame() {
    return DataFrame.fromMap({name: data});
  }

  /// Converts this Series to a DataCube.
  ///
  /// Returns a 1x1xN DataCube where N is the length of the series.
  DataCube toDataCube() {
    final array =
        NDArray.generate([1, 1, length], (indices) => data[indices[2]]);
    return DataCube.fromNDArray(array);
  }

  /// Returns this Series (identity operation for consistency).
  Series toSeries() {
    return this;
  }
}

/// Extension providing conversion methods for DataFrame.
///
/// Note: toDataCube() is already provided by DataFrameToDataCube extension.
///
/// Example:
/// ```dart
/// var df = DataFrame([[1, 2], [3, 4]], columns: ['A', 'B']);
/// var array = df.toNDArray();
/// var series = df.toSeries();
/// var cube = df.toDataCube();  // From DataFrameToDataCube extension
/// ```
extension DataFrameConversion on DataFrame {
  /// Converts this DataFrame to an NDArray.
  ///
  /// Returns a 2D NDArray with shape [rows, columns].
  NDArray toNDArray() {
    if (rowCount == 0 || columnCount == 0) {
      return NDArray.zeros([rowCount, columnCount]);
    }

    final rows = <List<dynamic>>[];
    for (int i = 0; i < rowCount; i++) {
      final row = <dynamic>[];
      for (int j = 0; j < columnCount; j++) {
        row.add(iloc(i, j));
      }
      rows.add(row);
    }
    return NDArray(rows);
  }

  /// Converts this DataFrame to a Series.
  ///
  /// Extracts the first column as a Series.
  ///
  /// Throws [ArgumentError] if the DataFrame is empty.
  Series toSeries() {
    if (columnCount == 0) {
      throw ArgumentError('Cannot convert empty DataFrame to Series');
    }
    return this[columns[0]];
  }

  /// Returns this DataFrame (identity operation for consistency).
  DataFrame toDataFrame() {
    return this;
  }

  // Note: toDataCube() is already provided by DataFrameToDataCube extension
  // in lib/src/datacube/dataframe_integration.dart
}
