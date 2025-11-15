part of 'data_frame.dart';

/// Advanced slicing operations for DataFrame
extension DataFrameAdvancedSlicing on DataFrame {
  /// Slice DataFrame with step parameter.
  ///
  /// Parameters:
  /// - `start`: Starting index (inclusive)
  /// - `end`: Ending index (exclusive)
  /// - `step`: Step size (default: 1)
  /// - `axis`: 0 for rows, 1 for columns
  ///
  /// Returns:
  /// Sliced DataFrame
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  ///   'B': [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
  /// });
  ///
  /// // Every other row
  /// var result = df.slice(start: 0, end: 10, step: 2);
  /// // Returns rows 0, 2, 4, 6, 8
  ///
  /// // Every third row starting from 1
  /// var result = df.slice(start: 1, end: 10, step: 3);
  /// // Returns rows 1, 4, 7
  ///
  /// // Reverse order
  /// var result = df.slice(start: 9, end: -1, step: -1);
  /// // Returns rows in reverse
  /// ```
  DataFrame slice({
    int? start,
    int? end,
    int step = 1,
    int axis = 0,
  }) {
    if (step == 0) {
      throw ArgumentError('Step cannot be zero');
    }

    if (axis == 0) {
      // Slice rows
      final actualStart = start ?? (step > 0 ? 0 : rowCount - 1);
      final actualEnd = end ?? (step > 0 ? rowCount : -1);

      final indices = <int>[];
      if (step > 0) {
        for (int i = actualStart; i < actualEnd && i < rowCount; i += step) {
          if (i >= 0) {
            indices.add(i);
          }
        }
      } else {
        for (int i = actualStart; i > actualEnd && i >= 0; i += step) {
          if (i < rowCount) {
            indices.add(i);
          }
        }
      }

      return take(indices, axis: 0);
    } else if (axis == 1) {
      // Slice columns
      final actualStart = start ?? (step > 0 ? 0 : columns.length - 1);
      final actualEnd = end ?? (step > 0 ? columns.length : -1);

      final indices = <int>[];
      if (step > 0) {
        for (int i = actualStart;
            i < actualEnd && i < columns.length;
            i += step) {
          if (i >= 0) {
            indices.add(i);
          }
        }
      } else {
        for (int i = actualStart; i > actualEnd && i >= 0; i += step) {
          if (i < columns.length) {
            indices.add(i);
          }
        }
      }

      return take(indices, axis: 1);
    } else {
      throw ArgumentError('axis must be 0 (rows) or 1 (columns)');
    }
  }

  /// Slice DataFrame by label range.
  ///
  /// Parameters:
  /// - `start`: Starting label (inclusive)
  /// - `end`: Ending label (inclusive)
  /// - `axis`: 0 for rows, 1 for columns
  ///
  /// Returns:
  /// Sliced DataFrame
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [10, 20, 30, 40, 50]},
  ///   index: ['a', 'b', 'c', 'd', 'e']
  /// );
  ///
  /// // Slice from 'b' to 'd' (inclusive)
  /// var result = df.sliceByLabel(start: 'b', end: 'd');
  /// // Returns rows with index 'b', 'c', 'd'
  /// ```
  DataFrame sliceByLabel({
    dynamic start,
    dynamic end,
    int axis = 0,
  }) {
    if (axis == 0) {
      // Slice rows by index labels
      int? startIdx;
      int? endIdx;

      // Find start index
      if (start != null) {
        startIdx = index.indexOf(start);
        if (startIdx == -1) {
          throw ArgumentError('Start label "$start" not found in index');
        }
      } else {
        startIdx = 0;
      }

      // Find end index
      if (end != null) {
        endIdx = index.indexOf(end);
        if (endIdx == -1) {
          throw ArgumentError('End label "$end" not found in index');
        }
      } else {
        endIdx = rowCount - 1;
      }

      // Generate indices (inclusive on both ends)
      final indices = <int>[];
      for (int i = startIdx; i <= endIdx; i++) {
        indices.add(i);
      }

      return take(indices, axis: 0);
    } else if (axis == 1) {
      // Slice columns by column labels
      int? startIdx;
      int? endIdx;

      // Find start index
      if (start != null) {
        startIdx = columns.indexOf(start);
        if (startIdx == -1) {
          throw ArgumentError('Start label "$start" not found in columns');
        }
      } else {
        startIdx = 0;
      }

      // Find end index
      if (end != null) {
        endIdx = columns.indexOf(end);
        if (endIdx == -1) {
          throw ArgumentError('End label "$end" not found in columns');
        }
      } else {
        endIdx = columns.length - 1;
      }

      // Generate indices (inclusive on both ends)
      final indices = <int>[];
      for (int i = startIdx; i <= endIdx; i++) {
        indices.add(i);
      }

      return take(indices, axis: 1);
    } else {
      throw ArgumentError('axis must be 0 (rows) or 1 (columns)');
    }
  }

  /// Slice DataFrame by position range with step.
  ///
  /// This is a convenience method that combines position-based slicing with step.
  ///
  /// Parameters:
  /// - `rowSlice`: Row slice specification [start, end, step]
  /// - `colSlice`: Column slice specification [start, end, step]
  ///
  /// Returns:
  /// Sliced DataFrame
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50],
  ///   'C': [100, 200, 300, 400, 500]
  /// });
  ///
  /// // Every other row, first two columns
  /// var result = df.sliceByPosition(
  ///   rowSlice: [0, 5, 2],  // start, end, step
  ///   colSlice: [0, 2, 1]   // start, end, step
  /// );
  /// ```
  DataFrame sliceByPosition({
    List<int>? rowSlice,
    List<int>? colSlice,
  }) {
    var result = this;

    // Apply row slice
    if (rowSlice != null) {
      final start = rowSlice.isNotEmpty ? rowSlice[0] : null;
      final end = rowSlice.length > 1 ? rowSlice[1] : null;
      final step = rowSlice.length > 2 ? rowSlice[2] : 1;

      result = result.slice(start: start, end: end, step: step, axis: 0);
    }

    // Apply column slice
    if (colSlice != null) {
      final start = colSlice.isNotEmpty ? colSlice[0] : null;
      final end = colSlice.length > 1 ? colSlice[1] : null;
      final step = colSlice.length > 2 ? colSlice[2] : 1;

      result = result.slice(start: start, end: end, step: step, axis: 1);
    }

    return result;
  }

  /// Slice DataFrame by label range with step.
  ///
  /// Parameters:
  /// - `rowStart`: Starting row label (inclusive)
  /// - `rowEnd`: Ending row label (inclusive)
  /// - `rowStep`: Row step size
  /// - `colStart`: Starting column label (inclusive)
  /// - `colEnd`: Ending column label (inclusive)
  /// - `colStep`: Column step size
  ///
  /// Returns:
  /// Sliced DataFrame
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {
  ///     'A': [1, 2, 3, 4, 5],
  ///     'B': [10, 20, 30, 40, 50],
  ///     'C': [100, 200, 300, 400, 500]
  ///   },
  ///   index: ['a', 'b', 'c', 'd', 'e']
  /// );
  ///
  /// // Slice from 'a' to 'd', every other row
  /// var result = df.sliceByLabelWithStep(
  ///   rowStart: 'a',
  ///   rowEnd: 'd',
  ///   rowStep: 2
  /// );
  /// ```
  DataFrame sliceByLabelWithStep({
    dynamic rowStart,
    dynamic rowEnd,
    int rowStep = 1,
    dynamic colStart,
    dynamic colEnd,
    int colStep = 1,
  }) {
    var result = this;

    // Apply row slice
    if (rowStart != null || rowEnd != null) {
      result = result.sliceByLabel(start: rowStart, end: rowEnd, axis: 0);

      // Apply step if not 1
      if (rowStep != 1) {
        result = result.slice(
            start: 0, end: result.rowCount, step: rowStep, axis: 0);
      }
    }

    // Apply column slice
    if (colStart != null || colEnd != null) {
      result = result.sliceByLabel(start: colStart, end: colEnd, axis: 1);

      // Apply step if not 1
      if (colStep != 1) {
        result = result.slice(
            start: 0, end: result.columns.length, step: colStep, axis: 1);
      }
    }

    return result;
  }

  /// Get every nth row.
  ///
  /// Convenience method for common slicing pattern.
  ///
  /// Parameters:
  /// - `n`: Step size
  /// - `offset`: Starting offset (default: 0)
  ///
  /// Returns:
  /// DataFrame with every nth row
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  /// });
  ///
  /// // Every 3rd row
  /// var result = df.everyNthRow(3);
  /// // Returns rows 0, 3, 6, 9
  ///
  /// // Every 3rd row starting from index 1
  /// var result = df.everyNthRow(3, offset: 1);
  /// // Returns rows 1, 4, 7
  /// ```
  DataFrame everyNthRow(int n, {int offset = 0}) {
    if (n <= 0) {
      throw ArgumentError('n must be positive');
    }

    return slice(start: offset, end: rowCount, step: n, axis: 0);
  }

  /// Get every nth column.
  ///
  /// Convenience method for common slicing pattern.
  ///
  /// Parameters:
  /// - `n`: Step size
  /// - `offset`: Starting offset (default: 0)
  ///
  /// Returns:
  /// DataFrame with every nth column
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1], 'B': [2], 'C': [3], 'D': [4], 'E': [5]
  /// });
  ///
  /// // Every 2nd column
  /// var result = df.everyNthColumn(2);
  /// // Returns columns A, C, E
  /// ```
  DataFrame everyNthColumn(int n, {int offset = 0}) {
    if (n <= 0) {
      throw ArgumentError('n must be positive');
    }

    return slice(start: offset, end: columns.length, step: n, axis: 1);
  }

  /// Reverse the order of rows.
  ///
  /// Returns:
  /// DataFrame with rows in reverse order
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5]
  /// });
  ///
  /// var reversed = df.reverseRows();
  /// // Returns rows in order: 5, 4, 3, 2, 1
  /// ```
  DataFrame reverseRows() {
    return slice(start: rowCount - 1, end: -1, step: -1, axis: 0);
  }

  /// Reverse the order of columns.
  ///
  /// Returns:
  /// DataFrame with columns in reverse order
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1], 'B': [2], 'C': [3]
  /// });
  ///
  /// var reversed = df.reverseColumns();
  /// // Returns columns in order: C, B, A
  /// ```
  DataFrame reverseColumns() {
    return slice(start: columns.length - 1, end: -1, step: -1, axis: 1);
  }
}
