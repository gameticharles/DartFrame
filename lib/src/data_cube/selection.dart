/// Selection and filtering operations for DataCube
library;

import '../data_frame/data_frame.dart';
import 'datacube.dart';

/// Extension for DataCube selection
extension DataCubeSelection on DataCube {
  /// Select frames where condition is true
  ///
  /// Returns a new DataCube containing only frames that satisfy the condition.
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(10, 5, 3, (d, r, c) => d + r + c);
  /// final selected = cube.selectFrames((frame) => frame.rowCount > 3);
  /// ```
  DataCube selectFrames(bool Function(DataFrame) condition) {
    final selectedFrames = <DataFrame>[];

    for (int d = 0; d < depth; d++) {
      final frame = getFrame(d);
      if (condition(frame)) {
        selectedFrames.add(frame);
      }
    }

    if (selectedFrames.isEmpty) {
      throw StateError('No frames match the condition');
    }

    return DataCube.fromDataFrames(selectedFrames);
  }

  /// Filter values across all frames
  ///
  /// Applies a condition to all values and replaces non-matching values with null.
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(5, 3, 3, (d, r, c) => d + r + c);
  /// final filtered = cube.filterValues((x) => x > 3);
  /// ```
  DataCube filterValues(bool Function(dynamic) condition) {
    final newFrames = <DataFrame>[];

    for (int d = 0; d < depth; d++) {
      final frame = getFrame(d);
      final filteredData = <String, List<dynamic>>{};

      for (final column in frame.columns.cast<String>()) {
        final series = frame[column];
        final filteredColumn = series.data.map((value) {
          return condition(value) ? value : null;
        }).toList();
        filteredData[column] = filteredColumn;
      }

      newFrames.add(DataFrame.fromMap(filteredData, index: frame.index));
    }

    return DataCube.fromDataFrames(newFrames);
  }

  /// Select frames by indices
  ///
  /// Returns a new DataCube with frames at the specified indices.
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(10, 5, 3, (d, r, c) => d);
  /// final selected = cube.selectByIndices([0, 2, 4]);
  /// ```
  DataCube selectByIndices(List<int> frameIndices) {
    final selectedFrames = <DataFrame>[];

    for (final idx in frameIndices) {
      if (idx < 0 || idx >= depth) {
        throw RangeError('Frame index $idx out of range [0, $depth)');
      }
      selectedFrames.add(getFrame(idx));
    }

    return DataCube.fromDataFrames(selectedFrames);
  }

  /// Select frames where a column meets a condition
  ///
  /// Returns frames where at least one value in the specified column
  /// satisfies the condition.
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(10, 5, 3, (d, r, c) => d + r + c);
  /// final selected = cube.whereColumn('col_0', (x) => x > 5);
  /// ```
  DataCube whereColumn(String column, bool Function(dynamic) condition) {
    return selectFrames((frame) {
      if (!frame.columns.contains(column)) {
        return false;
      }
      final series = frame[column];
      return series.data.any((value) => condition(value));
    });
  }

  /// Select frames within a depth range
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(10, 5, 3, (d, r, c) => d);
  /// final selected = cube.selectDepthRange(2, 5);
  /// // Selects frames 2, 3, 4, 5
  /// ```
  DataCube selectDepthRange(int start, int end) {
    if (start < 0 || end >= depth || start > end) {
      throw RangeError('Invalid range [$start, $end] for depth $depth');
    }

    final indices = List.generate(end - start + 1, (i) => start + i);
    return selectByIndices(indices);
  }

  /// Count frames where condition is true
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(10, 5, 3, (d, r, c) => d);
  /// final count = cube.countFrames((frame) => frame.rowCount == 5);
  /// ```
  int countFrames(bool Function(DataFrame) condition) {
    int count = 0;
    for (int d = 0; d < depth; d++) {
      if (condition(getFrame(d))) {
        count++;
      }
    }
    return count;
  }

  /// Check if any frame satisfies condition
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(10, 5, 3, (d, r, c) => d);
  /// final hasLarge = cube.anyFrame((frame) => frame.rowCount > 10);
  /// ```
  bool anyFrame(bool Function(DataFrame) condition) {
    for (int d = 0; d < depth; d++) {
      if (condition(getFrame(d))) {
        return true;
      }
    }
    return false;
  }

  /// Check if all frames satisfy condition
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(10, 5, 3, (d, r, c) => d);
  /// final allSame = cube.allFrames((frame) => frame.rowCount == 5);
  /// ```
  bool allFrames(bool Function(DataFrame) condition) {
    for (int d = 0; d < depth; d++) {
      if (!condition(getFrame(d))) {
        return false;
      }
    }
    return true;
  }

  /// Find first frame index where condition is true
  ///
  /// Returns null if no frame satisfies the condition.
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(10, 5, 3, (d, r, c) => d);
  /// final index = cube.findFirstFrame((frame) => frame.rowCount > 3);
  /// ```
  int? findFirstFrame(bool Function(DataFrame) condition) {
    for (int d = 0; d < depth; d++) {
      if (condition(getFrame(d))) {
        return d;
      }
    }
    return null;
  }

  /// Find last frame index where condition is true
  ///
  /// Returns null if no frame satisfies the condition.
  int? findLastFrame(bool Function(DataFrame) condition) {
    for (int d = depth - 1; d >= 0; d--) {
      if (condition(getFrame(d))) {
        return d;
      }
    }
    return null;
  }

  /// Select rows across all frames where condition is true
  ///
  /// Returns a new DataCube with only the rows that satisfy the condition.
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(5, 10, 3, (d, r, c) => r);
  /// final selected = cube.selectRows((row) => row['col_0'] > 5);
  /// ```
  DataCube selectRows(bool Function(Map<String, dynamic>) condition) {
    final newFrames = <DataFrame>[];

    for (int d = 0; d < depth; d++) {
      final frame = getFrame(d);
      final selectedRows = <Map<String, dynamic>>[];

      for (int r = 0; r < frame.rowCount; r++) {
        final row = <String, dynamic>{};
        for (final column in frame.columns.cast<String>()) {
          row[column] = frame[column].data[r];
        }
        if (condition(row)) {
          selectedRows.add(row);
        }
      }

      if (selectedRows.isNotEmpty) {
        final data = <String, List<dynamic>>{};
        for (final column in frame.columns.cast<String>()) {
          data[column] = selectedRows.map((row) => row[column]).toList();
        }
        newFrames.add(DataFrame.fromMap(data));
      }
    }

    if (newFrames.isEmpty) {
      throw StateError('No rows match the condition');
    }

    return DataCube.fromDataFrames(newFrames);
  }

  /// Select columns across all frames
  ///
  /// Returns a new DataCube with only the specified columns.
  ///
  /// Example:
  /// ```dart
  /// final cube = DataCube.generate(5, 10, 5, (d, r, c) => c);
  /// final selected = cube.selectColumns(['col_0', 'col_2']);
  /// ```
  DataCube selectColumns(List<String> columnNames) {
    final newFrames = <DataFrame>[];

    for (int d = 0; d < depth; d++) {
      final frame = getFrame(d);
      final data = <String, List<dynamic>>{};

      for (final column in columnNames) {
        if (!frame.columns.contains(column)) {
          throw ArgumentError('Column $column not found in frame $d');
        }
        data[column] = frame[column].data;
      }

      newFrames.add(DataFrame.fromMap(data, index: frame.index));
    }

    return DataCube.fromDataFrames(newFrames);
  }
}
