part of 'data_frame.dart';

/// Extension for DataFrame alignment and reindexing methods
extension DataFrameAlignment on DataFrame {
  /// Conform DataFrame to new index with optional filling logic.
  ///
  /// Places NA/NaN in locations having no value in the previous index.
  /// A new object is produced unless the new index is equivalent to the current one.
  ///
  /// Parameters:
  ///   - `index`: New labels for the index (rows)
  ///   - `columns`: New labels for the columns
  ///   - `method`: Method to use for filling holes in reindexed DataFrame
  ///     - null: don't fill gaps
  ///     - 'ffill'/'pad': propagate last valid observation forward
  ///     - 'bfill'/'backfill': use next valid observation to fill gap
  ///   - `fillValue`: Value to use for missing values
  ///   - `limit`: Maximum number of consecutive elements to forward/backward fill
  ///
  /// Returns:
  ///   DataFrame with changed index
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  /// }, index: ['a', 'b', 'c']);
  ///
  /// var reindexed = df.reindex(index: ['a', 'b', 'c', 'd']);
  /// // Row 'd' will have null values
  ///
  /// var filled = df.reindex(index: ['a', 'b', 'c', 'd'], fillValue: 0);
  /// // Row 'd' will have 0 values
  /// ```
  DataFrame reindex({
    List<dynamic>? index,
    List<dynamic>? columns,
    String? method,
    dynamic fillValue,
    int? limit,
  }) {
    if (index == null && columns == null) {
      return copy();
    }

    DataFrame result = this;

    // Reindex rows
    if (index != null) {
      result = _reindexRows(result, index,
          method: method, fillValue: fillValue, limit: limit);
    }

    // Reindex columns
    if (columns != null) {
      result = _reindexColumns(result, columns, fillValue: fillValue);
    }

    return result;
  }

  /// Reindex rows of a DataFrame
  DataFrame _reindexRows(
    DataFrame df,
    List<dynamic> newIndex, {
    String? method,
    dynamic fillValue,
    int? limit,
  }) {
    final newData = <List<dynamic>>[];
    final oldIndexMap = <dynamic, int>{};

    // Create index lookup map
    for (int i = 0; i < df.index.length; i++) {
      oldIndexMap[df.index[i]] = i;
    }

    // Build new data
    for (final idx in newIndex) {
      if (oldIndexMap.containsKey(idx)) {
        // Index exists in old DataFrame
        newData.add(List.from(df._data[oldIndexMap[idx]!]));
      } else {
        // Index doesn't exist - fill with fillValue or null
        final row = List<dynamic>.filled(
          df.columnCount,
          fillValue ?? replaceMissingValueWith,
        );
        newData.add(row);
      }
    }

    var result = DataFrame(
      newData,
      columns: df._columns,
      index: newIndex,
      allowFlexibleColumns: df.allowFlexibleColumns,
    );

    // Apply fill method if specified
    if (method != null) {
      if (method == 'ffill' || method == 'pad') {
        result = result.ffillDataFrame(limit: limit);
      } else if (method == 'bfill' || method == 'backfill') {
        result = result.bfillDataFrame(limit: limit);
      }
    }

    return result;
  }

  /// Reindex columns of a DataFrame
  DataFrame _reindexColumns(
    DataFrame df,
    List<dynamic> newColumns, {
    dynamic fillValue,
  }) {
    final newData = <String, List<dynamic>>{};

    for (final col in newColumns) {
      if (df._columns.contains(col)) {
        newData[col.toString()] = df.column(col).data;
      } else {
        // Column doesn't exist - fill with fillValue or null
        newData[col.toString()] = List<dynamic>.filled(
          df.rowCount,
          fillValue ?? replaceMissingValueWith,
        );
      }
    }

    return DataFrame.fromMap(newData, index: df.index);
  }

  /// Align two DataFrames on their axes with specified join method.
  ///
  /// Parameters:
  ///   - `other`: DataFrame to align with
  ///   - `join`: Type of alignment to perform
  ///     - 'outer': Union of indices (default)
  ///     - 'inner': Intersection of indices
  ///     - 'left': Use calling DataFrame's index
  ///     - 'right': Use other DataFrame's index
  ///   - `axis`: Axis to align on (0 for rows, 1 for columns, null for both)
  ///   - `fillValue`: Value to use for missing values
  ///
  /// Returns:
  ///   A tuple of (aligned_left, aligned_right) DataFrames
  ///
  /// Example:
  /// ```dart
  /// var df1 = DataFrame.fromMap({
  ///   'A': [1, 2],
  ///   'B': [3, 4],
  /// }, index: ['a', 'b']);
  ///
  /// var df2 = DataFrame.fromMap({
  ///   'A': [5, 6],
  ///   'C': [7, 8],
  /// }, index: ['b', 'c']);
  ///
  /// var aligned = df1.align(df2, join: 'outer');
  /// // Both DataFrames will have index ['a', 'b', 'c'] and columns ['A', 'B', 'C']
  /// ```
  List<DataFrame> align(
    DataFrame other, {
    String join = 'outer',
    int? axis,
    dynamic fillValue,
  }) {
    if (axis == null) {
      // Align both axes
      final rowAligned = _alignAxis(this, other, 0, join, fillValue);
      final fullyAligned =
          _alignAxis(rowAligned[0], rowAligned[1], 1, join, fillValue);
      return fullyAligned;
    } else {
      return _alignAxis(this, other, axis, join, fillValue);
    }
  }

  /// Align two DataFrames on a specific axis
  List<DataFrame> _alignAxis(
    DataFrame left,
    DataFrame right,
    int axis,
    String join,
    dynamic fillValue,
  ) {
    if (axis == 0) {
      // Align rows (index)
      final newIndex = _computeAlignedIndex(left.index, right.index, join);
      return [
        left.reindex(index: newIndex, fillValue: fillValue),
        right.reindex(index: newIndex, fillValue: fillValue),
      ];
    } else {
      // Align columns
      final newColumns =
          _computeAlignedIndex(left._columns, right._columns, join);
      return [
        left.reindex(columns: newColumns, fillValue: fillValue),
        right.reindex(columns: newColumns, fillValue: fillValue),
      ];
    }
  }

  /// Compute aligned index based on join type
  List<dynamic> _computeAlignedIndex(
    List<dynamic> leftIndex,
    List<dynamic> rightIndex,
    String join,
  ) {
    switch (join) {
      case 'outer':
        // Union of indices
        final combined = <dynamic>{...leftIndex, ...rightIndex};
        return combined.toList();

      case 'inner':
        // Intersection of indices
        final leftSet = leftIndex.toSet();
        final rightSet = rightIndex.toSet();
        return leftSet.intersection(rightSet).toList();

      case 'left':
        return List.from(leftIndex);

      case 'right':
        return List.from(rightIndex);

      default:
        throw ArgumentError(
            'Invalid join type: $join. Must be one of: outer, inner, left, right');
    }
  }

  /// Set the name of the axis for the index or columns.
  ///
  /// Parameters:
  ///   - `mapper`: New name(s) for the axis
  ///   - `axis`: Axis to set name for (0 for index, 1 for columns)
  ///   - `inplace`: Whether to modify the DataFrame in place
  ///
  /// Returns:
  ///   DataFrame with updated axis name (or null if inplace=true)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  /// });
  /// var result = df.setAxis(['X', 'Y'], axis: 1);
  /// print(result.columns); // ['X', 'Y']
  /// ```
  DataFrame? setAxis(
    List<dynamic> mapper, {
    int axis = 0,
    bool inplace = false,
  }) {
    if (axis == 0) {
      // Set index
      if (mapper.length != rowCount) {
        throw ArgumentError(
            'Length mismatch: Expected axis has $rowCount elements, '
            'new values have ${mapper.length} elements');
      }

      if (inplace) {
        index = List.from(mapper);
        return null;
      } else {
        final newDf = copy();
        newDf.index = List.from(mapper);
        return newDf;
      }
    } else if (axis == 1) {
      // Set columns
      if (mapper.length != columnCount) {
        throw ArgumentError(
            'Length mismatch: Expected axis has $columnCount elements, '
            'new values have ${mapper.length} elements');
      }

      if (inplace) {
        _columns = List.from(mapper);
        return null;
      } else {
        final newDf = copy();
        newDf._columns = List.from(mapper);
        return newDf;
      }
    } else {
      throw ArgumentError('axis must be 0 (index) or 1 (columns)');
    }
  }

  /// Return an object with matching indices as other object.
  ///
  /// Conform the object to the same index on all axes. Optional filling logic for
  /// locations having no value in the previous index.
  ///
  /// Parameters:
  ///   - `other`: Object to use for reindexing
  ///   - `method`: Method to use for filling holes
  ///   - `fillValue`: Value to use for missing values
  ///   - `limit`: Maximum number of consecutive fills
  ///
  /// Returns:
  ///   DataFrame with same indices as other
  ///
  /// Example:
  /// ```dart
  /// var df1 = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  /// }, index: ['a', 'b', 'c']);
  ///
  /// var df2 = DataFrame.fromMap({
  ///   'X': [10, 20],
  ///   'Y': [30, 40],
  /// }, index: ['a', 'b']);
  ///
  /// var result = df1.reindexLike(df2);
  /// // result will have index ['a', 'b'] and columns ['A', 'B']
  /// ```
  DataFrame reindexLike(
    DataFrame other, {
    String? method,
    dynamic fillValue,
    int? limit,
  }) {
    return reindex(
      index: other.index,
      columns: other._columns,
      method: method,
      fillValue: fillValue,
      limit: limit,
    );
  }
}
