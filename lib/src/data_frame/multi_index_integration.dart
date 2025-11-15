part of 'data_frame.dart';

/// Extension to integrate MultiIndex with DataFrame
extension DataFrameMultiIndexSupport on DataFrame {
  /// Set a MultiIndex on the DataFrame.
  ///
  /// Parameters:
  /// - `multiIndex`: The MultiIndex to set
  ///
  /// Returns:
  /// New DataFrame with MultiIndex
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'value': [1, 2, 3, 4]
  /// });
  ///
  /// var idx = MultiIndex.fromArrays([
  ///   ['A', 'A', 'B', 'B'],
  ///   [1, 2, 1, 2]
  /// ], names: ['letter', 'number']);
  ///
  /// var dfIndexed = df.setMultiIndex(idx);
  /// ```
  DataFrame setMultiIndex(MultiIndex multiIndex) {
    if (multiIndex.length != rowCount) {
      throw ArgumentError(
          'MultiIndex length (${multiIndex.length}) must match DataFrame length ($rowCount)');
    }

    return DataFrame._(
      List.from(_columns),
      _data.map((row) => List.from(row)).toList(),
      index: multiIndex.toList(),
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: _missingDataIndicator,
    );
  }

  /// Create a MultiIndex from DataFrame columns.
  ///
  /// Parameters:
  /// - `columns`: List of column names to use for the MultiIndex
  /// - `drop`: Whether to drop the columns after setting as index
  ///
  /// Returns:
  /// New DataFrame with MultiIndex created from columns
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'letter': ['A', 'A', 'B', 'B'],
  ///   'number': [1, 2, 1, 2],
  ///   'value': [10, 20, 30, 40]
  /// });
  ///
  /// var dfIndexed = df.setIndexFromColumns(['letter', 'number']);
  /// // Now has MultiIndex from letter and number columns
  /// ```
  DataFrame setIndexFromColumns(List<String> columns, {bool drop = true}) {
    // Validate columns exist
    for (var col in columns) {
      if (!this.columns.contains(col)) {
        throw ArgumentError('Column "$col" not found');
      }
    }

    // Extract arrays for MultiIndex
    final arrays = <List<dynamic>>[];
    for (var col in columns) {
      arrays.add(this[col].data);
    }

    // Create MultiIndex
    final multiIndex = MultiIndex.fromArrays(arrays, names: columns);

    // Create new DataFrame
    if (drop) {
      // Remove the index columns
      final remainingColumns =
          this.columns.where((c) => !columns.contains(c)).toList();
      final newData = <List<dynamic>>[];

      for (var row in _data) {
        final newRow = <dynamic>[];
        for (int i = 0; i < this.columns.length; i++) {
          if (!columns.contains(this.columns[i])) {
            newRow.add(row[i]);
          }
        }
        newData.add(newRow);
      }

      return DataFrame._(
        remainingColumns,
        newData,
        index: multiIndex.toList(),
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    } else {
      // Keep the columns
      return DataFrame._(
        List.from(this.columns),
        _data.map((row) => List.from(row)).toList(),
        index: multiIndex.toList(),
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    }
  }

  /// Reset the MultiIndex to default integer index.
  ///
  /// Parameters:
  /// - `drop`: Whether to drop the index or add it as columns
  ///
  /// Returns:
  /// New DataFrame with reset index
  ///
  /// Example:
  /// ```dart
  /// var dfIndexed = df.setIndexFromColumns(['letter', 'number']);
  /// var dfReset = dfIndexed.resetMultiIndex();
  /// // Index is now [0, 1, 2, 3] and letter/number are columns again
  /// ```
  DataFrame resetMultiIndex({bool drop = false}) {
    if (drop) {
      // Just reset to integer index
      return DataFrame._(
        List.from(_columns),
        _data.map((row) => List.from(row)).toList(),
        index: List.generate(rowCount, (i) => i),
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    } else {
      // Add index as columns
      final newColumns = <dynamic>[];
      final newData = <List<dynamic>>[];

      // Determine index structure
      if (index.isNotEmpty && index.first is List) {
        // MultiIndex - add each level as a column
        final firstIndex = index.first as List;
        final nlevels = firstIndex.length;

        // Add index level columns
        for (int level = 0; level < nlevels; level++) {
          newColumns.add('level_$level');
        }
      } else {
        // Single index
        newColumns.add('index');
      }

      // Add existing columns
      newColumns.addAll(_columns);

      // Build new data
      for (int i = 0; i < rowCount; i++) {
        final newRow = <dynamic>[];

        // Add index values
        if (index[i] is List) {
          newRow.addAll(index[i] as List);
        } else {
          newRow.add(index[i]);
        }

        // Add existing data
        newRow.addAll(_data[i]);

        newData.add(newRow);
      }

      return DataFrame._(
        newColumns,
        newData,
        index: List.generate(rowCount, (i) => i),
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    }
  }

  /// Check if DataFrame has a MultiIndex.
  bool get hasMultiIndex {
    return index.isNotEmpty && index.first is List;
  }

  /// Get the number of index levels.
  int get indexLevels {
    if (index.isEmpty) return 0;
    if (index.first is List) {
      return (index.first as List).length;
    }
    return 1;
  }

  /// Select rows by MultiIndex values.
  ///
  /// Parameters:
  /// - `values`: Tuple or partial tuple to match
  ///
  /// Returns:
  /// DataFrame with matching rows
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'value': [10, 20, 30, 40]
  /// });
  ///
  /// var idx = MultiIndex.fromArrays([
  ///   ['A', 'A', 'B', 'B'],
  ///   [1, 2, 1, 2]
  /// ]);
  ///
  /// var dfIndexed = df.setMultiIndex(idx);
  ///
  /// // Select all rows where first level is 'A'
  /// var dfA = dfIndexed.selectByMultiIndex(['A']);
  ///
  /// // Select specific tuple
  /// var dfA1 = dfIndexed.selectByMultiIndex(['A', 1]);
  /// ```
  DataFrame selectByMultiIndex(List<dynamic> values) {
    if (!hasMultiIndex) {
      throw StateError('DataFrame does not have a MultiIndex');
    }

    final selectedData = <List<dynamic>>[];
    final selectedIndex = <dynamic>[];

    for (int i = 0; i < rowCount; i++) {
      final indexTuple = index[i] as List;

      // Check if matches (partial match allowed)
      bool matches = true;
      for (int j = 0; j < values.length && j < indexTuple.length; j++) {
        if (indexTuple[j] != values[j]) {
          matches = false;
          break;
        }
      }

      if (matches) {
        selectedData.add(List.from(_data[i]));
        selectedIndex.add(index[i]);
      }
    }

    return DataFrame._(
      List.from(_columns),
      selectedData,
      index: selectedIndex,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: _missingDataIndicator,
    );
  }

  /// Group by index levels.
  ///
  /// Parameters:
  /// - `level`: Level number or list of level numbers to group by
  ///
  /// Returns:
  /// Map of group keys to DataFrames
  ///
  /// Example:
  /// ```dart
  /// var dfIndexed = df.setIndexFromColumns(['letter', 'number']);
  ///
  /// // Group by first level
  /// var groups = dfIndexed.groupByIndexLevel(0);
  /// // Returns: {'A': DataFrame, 'B': DataFrame}
  /// ```
  Map<dynamic, DataFrame> groupByIndexLevel(dynamic level) {
    if (!hasMultiIndex) {
      throw StateError('DataFrame does not have a MultiIndex');
    }

    final groups = <dynamic, List<int>>{};

    // Determine which level(s) to group by
    final levels = level is List ? level : [level];

    for (int i = 0; i < rowCount; i++) {
      final indexTuple = index[i] as List;

      // Extract key from specified levels
      final key = levels.length == 1
          ? indexTuple[levels[0]]
          : levels.map((l) => indexTuple[l]).toList();

      groups.putIfAbsent(key, () => []).add(i);
    }

    // Build DataFrames for each group
    final result = <dynamic, DataFrame>{};

    for (var entry in groups.entries) {
      final groupData = <List<dynamic>>[];
      final groupIndex = <dynamic>[];

      for (var i in entry.value) {
        groupData.add(List.from(_data[i]));
        groupIndex.add(index[i]);
      }

      result[entry.key] = DataFrame._(
        List.from(_columns),
        groupData,
        index: groupIndex,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    }

    return result;
  }
}

/// Extension to integrate DatetimeIndex with DataFrame
extension DataFrameDatetimeIndexSupport on DataFrame {
  /// Set a DatetimeIndex on the DataFrame.
  ///
  /// Parameters:
  /// - `datetimeIndex`: The DatetimeIndex to set
  ///
  /// Returns:
  /// New DataFrame with DatetimeIndex
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'value': [1, 2, 3, 4, 5]
  /// });
  ///
  /// var idx = DatetimeIndex.dateRange(
  ///   start: DateTime(2024, 1, 1),
  ///   periods: 5,
  ///   frequency: 'D',
  /// );
  ///
  /// var dfIndexed = df.setDatetimeIndex(idx);
  /// ```
  DataFrame setDatetimeIndex(DatetimeIndex datetimeIndex) {
    if (datetimeIndex.length != rowCount) {
      throw ArgumentError(
          'DatetimeIndex length (${datetimeIndex.length}) must match DataFrame length ($rowCount)');
    }

    return DataFrame._(
      List.from(_columns),
      _data.map((row) => List.from(row)).toList(),
      index: datetimeIndex.values,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: _missingDataIndicator,
    );
  }

  /// Create a DatetimeIndex from a DataFrame column.
  ///
  /// Parameters:
  /// - `column`: Column name containing datetime values
  /// - `drop`: Whether to drop the column after setting as index
  ///
  /// Returns:
  /// New DataFrame with DatetimeIndex
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'date': [
  ///     DateTime(2024, 1, 1),
  ///     DateTime(2024, 1, 2),
  ///     DateTime(2024, 1, 3)
  ///   ],
  ///   'value': [10, 20, 30]
  /// });
  ///
  /// var dfIndexed = df.setDatetimeIndexFromColumn('date');
  /// ```
  DataFrame setDatetimeIndexFromColumn(String column, {bool drop = true}) {
    if (!columns.contains(column)) {
      throw ArgumentError('Column "$column" not found');
    }

    final series = this[column];
    final timestamps = <DateTime>[];

    for (var value in series.data) {
      if (value is DateTime) {
        timestamps.add(value);
      } else {
        throw ArgumentError('Column "$column" must contain DateTime values');
      }
    }

    final datetimeIndex = DatetimeIndex(timestamps);

    if (drop) {
      // Remove the datetime column
      final remainingColumns = columns.where((c) => c != column).toList();
      final newData = <List<dynamic>>[];

      final colIndex = columns.indexOf(column);
      for (var row in _data) {
        final newRow = <dynamic>[];
        for (int i = 0; i < row.length; i++) {
          if (i != colIndex) {
            newRow.add(row[i]);
          }
        }
        newData.add(newRow);
      }

      return DataFrame._(
        remainingColumns,
        newData,
        index: datetimeIndex.values,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    } else {
      return DataFrame._(
        List.from(columns),
        _data.map((row) => List.from(row)).toList(),
        index: datetimeIndex.values,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator,
      );
    }
  }

  /// Check if DataFrame has a DatetimeIndex.
  bool get hasDatetimeIndex {
    return index.isNotEmpty && index.first is DateTime;
  }
}
