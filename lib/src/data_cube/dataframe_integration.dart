/// DataFrame integration utilities for DataCube.
library;

import '../data_frame/data_frame.dart';
import 'datacube.dart';
import '../core/shape.dart';

/// Extension methods for DataFrame to DataCube conversion.
extension DataFrameToDataCube on DataFrame {
  /// Converts a single DataFrame to a DataCube with depth 1.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([[1, 2], [3, 4]]);
  /// var cube = df.toDataCube();
  /// print(cube.depth);  // 1
  /// ```
  DataCube toDataCube() {
    return DataCube.fromDataFrames([this]);
  }

  /// Stacks this DataFrame with others to create a DataCube.
  ///
  /// All DataFrames must have the same shape.
  ///
  /// Example:
  /// ```dart
  /// var df1 = DataFrame([[1, 2], [3, 4]]);
  /// var df2 = DataFrame([[5, 6], [7, 8]]);
  /// var df3 = DataFrame([[9, 10], [11, 12]]);
  /// var cube = df1.stackFrames([df2, df3]);
  /// print(cube.depth);  // 3
  /// ```
  DataCube stackFrames(List<DataFrame> others) {
    return DataCube.fromDataFrames([this, ...others]);
  }

  /// Checks if this DataFrame is compatible with another for stacking.
  ///
  /// Two DataFrames are compatible if they have the same shape.
  ///
  /// Example:
  /// ```dart
  /// var df1 = DataFrame([[1, 2], [3, 4]]);
  /// var df2 = DataFrame([[5, 6], [7, 8]]);
  /// var df3 = DataFrame([[1, 2, 3]]);
  ///
  /// print(df1.isCompatibleWith(df2));  // true
  /// print(df1.isCompatibleWith(df3));  // false
  /// ```
  bool isCompatibleWith(DataFrame other) {
    return shape[0] == other.shape[0] && shape[1] == other.shape[1];
  }

  /// Checks if this DataFrame is compatible with a list of DataFrames.
  ///
  /// Returns true if all DataFrames have the same shape.
  bool isCompatibleWithAll(List<DataFrame> others) {
    return others.every((df) => isCompatibleWith(df));
  }
}

/// Utility functions for DataFrame stacking and validation.
class DataFrameStacker {
  /// Stacks multiple DataFrames into a DataCube.
  ///
  /// All DataFrames must have the same shape.
  ///
  /// Example:
  /// ```dart
  /// var frames = [df1, df2, df3];
  /// var cube = DataFrameStacker.stack(frames);
  /// ```
  static DataCube stack(List<DataFrame> frames) {
    return DataCube.fromDataFrames(frames);
  }

  /// Validates that all DataFrames have the same shape.
  ///
  /// Returns true if all frames are compatible, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// var frames = [df1, df2, df3];
  /// if (DataFrameStacker.validateCompatibility(frames)) {
  ///   var cube = DataFrameStacker.stack(frames);
  /// }
  /// ```
  static bool validateCompatibility(List<DataFrame> frames) {
    if (frames.isEmpty) return true;
    if (frames.length == 1) return true;

    final firstShape = frames[0].shape;
    for (int i = 1; i < frames.length; i++) {
      if (frames[i].shape[0] != firstShape[0] ||
          frames[i].shape[1] != firstShape[1]) {
        return false;
      }
    }
    return true;
  }

  /// Gets the common shape of a list of DataFrames.
  ///
  /// Returns null if the DataFrames have different shapes.
  ///
  /// Example:
  /// ```dart
  /// var frames = [df1, df2, df3];
  /// var commonShape = DataFrameStacker.getCommonShape(frames);
  /// if (commonShape != null) {
  ///   print('All frames have shape: ${commonShape.toList()}');
  /// }
  /// ```
  static Shape? getCommonShape(List<DataFrame> frames) {
    if (frames.isEmpty) return null;

    if (!validateCompatibility(frames)) {
      return null;
    }

    return frames[0].shape;
  }

  /// Filters a list of DataFrames to only include those with a specific shape.
  ///
  /// Example:
  /// ```dart
  /// var frames = [df1, df2, df3, df4];
  /// var targetShape = Shape.fromRowsColumns(10, 5);
  /// var filtered = DataFrameStacker.filterByShape(frames, targetShape);
  /// ```
  static List<DataFrame> filterByShape(
      List<DataFrame> frames, Shape targetShape) {
    return frames.where((df) {
      return df.shape[0] == targetShape[0] && df.shape[1] == targetShape[1];
    }).toList();
  }

  /// Groups DataFrames by their shape.
  ///
  /// Returns a map where keys are shape strings and values are lists of DataFrames.
  ///
  /// Example:
  /// ```dart
  /// var frames = [df1, df2, df3, df4];
  /// var grouped = DataFrameStacker.groupByShape(frames);
  /// for (var entry in grouped.entries) {
  ///   print('Shape ${entry.key}: ${entry.value.length} frames');
  /// }
  /// ```
  static Map<String, List<DataFrame>> groupByShape(List<DataFrame> frames) {
    final groups = <String, List<DataFrame>>{};

    for (var frame in frames) {
      final shapeKey = '${frame.shape[0]}x${frame.shape[1]}';
      groups.putIfAbsent(shapeKey, () => []).add(frame);
    }

    return groups;
  }

  /// Attempts to stack DataFrames, returning null if they're incompatible.
  ///
  /// This is a safe version of stack() that doesn't throw exceptions.
  ///
  /// Example:
  /// ```dart
  /// var frames = [df1, df2, df3];
  /// var cube = DataFrameStacker.tryStack(frames);
  /// if (cube != null) {
  ///   print('Successfully created DataCube');
  /// } else {
  ///   print('DataFrames are incompatible');
  /// }
  /// ```
  static DataCube? tryStack(List<DataFrame> frames) {
    if (!validateCompatibility(frames)) {
      return null;
    }

    try {
      return DataCube.fromDataFrames(frames);
    } catch (e) {
      return null;
    }
  }

  /// Pads or truncates DataFrames to a common shape before stacking.
  ///
  /// This allows stacking of DataFrames with different shapes by:
  /// - Truncating larger DataFrames
  /// - Padding smaller DataFrames with a fill value
  ///
  /// Example:
  /// ```dart
  /// var frames = [df1, df2, df3];  // Different shapes
  /// var cube = DataFrameStacker.stackWithPadding(
  ///   frames,
  ///   targetRows: 10,
  ///   targetCols: 5,
  ///   fillValue: 0,
  /// );
  /// ```
  static DataCube stackWithPadding(
    List<DataFrame> frames, {
    required int targetRows,
    required int targetCols,
    dynamic fillValue = 0,
  }) {
    if (frames.isEmpty) {
      throw ArgumentError('Cannot stack empty list of DataFrames');
    }

    // For now, just validate they match the target
    // Full padding implementation would require DataFrame manipulation methods
    final compatible = frames
        .every((df) => df.shape[0] == targetRows && df.shape[1] == targetCols);

    if (!compatible) {
      throw UnimplementedError(
          'DataFrame padding/truncation not yet implemented. '
          'All frames must match target shape [$targetRows, $targetCols]');
    }

    return DataCube.fromDataFrames(frames);
  }
}

/// Extension methods for DataCube to DataFrame conversion.
extension DataCubeToDataFrame on DataCube {
  /// Converts a DataCube with depth 1 to a DataFrame.
  ///
  /// Throws an error if depth is not 1.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(1, 5, 3);
  /// var df = cube.toDataFrame();
  /// ```
  DataFrame toDataFrame() {
    if (depth != 1) {
      throw StateError(
          'Cannot convert DataCube with depth $depth to DataFrame. '
          'Depth must be 1.');
    }

    return getFrame(0);
  }

  /// Attempts to convert to DataFrame, returning null if depth is not 1.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(3, 5, 3);
  /// var df = cube.tryToDataFrame();
  /// if (df != null) {
  ///   print('Converted to DataFrame');
  /// } else {
  ///   print('Cannot convert: depth is ${cube.depth}');
  /// }
  /// ```
  DataFrame? tryToDataFrame() {
    if (depth != 1) {
      return null;
    }

    return getFrame(0);
  }

  /// Unstacks the DataCube into a list of DataFrames.
  ///
  /// This is equivalent to toDataFrames() but with a more descriptive name.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.fromDataFrames([df1, df2, df3]);
  /// var frames = cube.unstack();
  /// print(frames.length);  // 3
  /// ```
  List<DataFrame> unstack() {
    return toDataFrames();
  }
}
