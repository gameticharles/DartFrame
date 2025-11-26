part of 'data_frame.dart';

/// Extension for advanced DataFrame missing data handling
extension DataFrameMissingDataAdvanced on DataFrame {
  /// Remove rows or columns with missing values (enhanced version).
  ///
  /// Parameters:
  ///   - `axis`: Axis along which to drop (0 for rows, 1 for columns)
  ///   - `how`: Determine if row/column is removed ('any' or 'all')
  ///   - `thresh`: Minimum number of non-NA values required
  ///   - `subset`: Labels along other axis to consider
  ///   - `inplace`: Whether to modify DataFrame in place
  ///
  /// Returns:
  ///   DataFrame with NA entries dropped (or null if inplace=true)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, null, 3, null],
  ///   'B': [4, 5, null, 7],
  ///   'C': [8, 9, 10, 11],
  /// });
  ///
  /// // Drop rows with any NA
  /// var cleaned = df.dropnaEnhanced();
  ///
  /// // Drop rows with all NA
  /// var cleaned2 = df.dropnaEnhanced(how: 'all');
  ///
  /// // Drop rows with less than 2 non-NA values
  /// var cleaned3 = df.dropnaEnhanced(thresh: 2);
  ///
  /// // Drop rows with NA in specific columns
  /// var cleaned4 = df.dropnaEnhanced(subset: ['A', 'B']);
  /// ```
  DataFrame? dropnaEnhanced({
    int axis = 0,
    String how = 'any',
    int? thresh,
    List<String>? subset,
    bool inplace = false,
  }) {
    if (how != 'any' && how != 'all') {
      throw ArgumentError("how must be 'any' or 'all'");
    }

    if (axis == 0) {
      // Drop rows
      final columnsToCheck =
          subset ?? _columns.map((c) => c.toString()).toList();
      final colIndices = <int>[];

      for (final col in columnsToCheck) {
        final idx = _columns.indexOf(col);
        if (idx != -1) {
          colIndices.add(idx);
        }
      }

      final rowsToKeep = <int>[];

      for (int i = 0; i < rowCount; i++) {
        int nonNaCount = 0;
        int naCount = 0;

        for (final colIdx in colIndices) {
          final value = _data[i][colIdx];
          if (_isMissingValueHelper(value)) {
            naCount++;
          } else {
            nonNaCount++;
          }
        }

        bool keepRow = false;

        if (thresh != null) {
          keepRow = nonNaCount >= thresh;
        } else if (how == 'any') {
          keepRow = naCount == 0;
        } else {
          // how == 'all'
          keepRow = nonNaCount > 0;
        }

        if (keepRow) {
          rowsToKeep.add(i);
        }
      }

      final newData = rowsToKeep.map((i) => List.from(_data[i])).toList();
      final newIndex = rowsToKeep.map((i) => index[i]).toList();

      if (inplace) {
        _data.clear();
        _data.addAll(newData);
        index.clear();
        index.addAll(newIndex);
        return null;
      } else {
        return DataFrame(
          newData,
          columns: _columns,
          index: newIndex,
          allowFlexibleColumns: allowFlexibleColumns,
        );
      }
    } else {
      // Drop columns
      final columnsToKeep = <String>[];

      for (int j = 0; j < columnCount; j++) {
        int nonNaCount = 0;
        int naCount = 0;

        for (int i = 0; i < rowCount; i++) {
          final value = _data[i][j];
          if (_isMissingValueHelper(value)) {
            naCount++;
          } else {
            nonNaCount++;
          }
        }

        bool keepCol = false;

        if (thresh != null) {
          keepCol = nonNaCount >= thresh;
        } else if (how == 'any') {
          keepCol = naCount == 0;
        } else {
          // how == 'all'
          keepCol = nonNaCount > 0;
        }

        if (keepCol) {
          columnsToKeep.add(_columns[j].toString());
        }
      }

      final newData = <String, List<dynamic>>{};
      for (final col in columnsToKeep) {
        newData[col] = column(col).data;
      }

      if (inplace) {
        final temp = DataFrame.fromMap(newData, index: index);
        _columns.clear();
        _columns.addAll(temp._columns);
        _data.clear();
        _data.addAll(temp._data);
        return null;
      } else {
        return DataFrame.fromMap(newData, index: index);
      }
    }
  }

  /// Fill NA/NaN values using the specified method (enhanced version).
  ///
  /// Parameters:
  ///   - `value`: Value to use to fill holes
  ///   - `method`: Method to use for filling ('ffill', 'bfill', 'pad', 'backfill')
  ///   - `axis`: Axis along which to fill (0 for rows, 1 for columns)
  ///   - `limit`: Maximum number of consecutive NaN values to fill
  ///   - `limitDirection`: Direction to apply limit ('forward', 'backward', 'both')
  ///   - `other`: DataFrame to use for filling (DataFrame-to-DataFrame filling)
  ///
  /// Returns:
  ///   DataFrame with filled values
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, null, 3],
  ///   'B': [4, 5, null],
  /// });
  ///
  /// // Fill with value
  /// var filled1 = df.fillnaEnhanced(value: 0);
  ///
  /// // Forward fill with limit
  /// var filled2 = df.fillnaEnhanced(method: 'ffill', limit: 1);
  ///
  /// // Fill from another DataFrame
  /// var other = DataFrame.fromMap({
  ///   'A': [10, 20, 30],
  ///   'B': [40, 50, 60],
  /// });
  /// var filled3 = df.fillnaEnhanced(other: other);
  /// ```
  DataFrame fillnaEnhanced({
    dynamic value,
    String? method,
    int axis = 0,
    int? limit,
    String limitDirection = 'forward',
    DataFrame? other,
  }) {
    if (other != null) {
      // DataFrame-to-DataFrame filling
      final newData = <List<dynamic>>[];

      for (int i = 0; i < rowCount; i++) {
        final newRow = <dynamic>[];
        for (int j = 0; j < columnCount; j++) {
          final val = _data[i][j];
          if (_isMissingValueHelper(val)) {
            // Try to get value from other DataFrame
            if (i < other.rowCount && j < other.columnCount) {
              newRow.add(other._data[i][j]);
            } else {
              newRow.add(val);
            }
          } else {
            newRow.add(val);
          }
        }
        newData.add(newRow);
      }

      return DataFrame(
        newData,
        columns: _columns,
        index: index,
        allowFlexibleColumns: allowFlexibleColumns,
      );
    }

    if (axis == 0) {
      // Fill along rows (for each column)
      final newData = <String, List<dynamic>>{};

      for (final col in _columns) {
        final series = column(col);
        final filled = series.fillna(
          value: value,
          method: method,
          limit: limit,
          limitDirection: limitDirection,
        );
        newData[col.toString()] = filled.data;
      }

      return DataFrame.fromMap(newData, index: index);
    } else {
      // Fill along columns (for each row)
      final newData = <List<dynamic>>[];

      for (int i = 0; i < rowCount; i++) {
        final rowData = <dynamic>[];
        for (int j = 0; j < columnCount; j++) {
          rowData.add(_data[i][j]);
        }

        final rowSeries = Series(rowData, name: index[i].toString());
        final filled = rowSeries.fillna(
          value: value,
          method: method,
          limit: limit,
          limitDirection: limitDirection,
        );

        newData.add(filled.data);
      }

      return DataFrame(
        newData,
        columns: _columns,
        index: index,
        allowFlexibleColumns: allowFlexibleColumns,
      );
    }
  }

  /// Helper to check if a value is considered missing
  bool _isMissingValueHelper(dynamic value) {
    if (value == null) return true;
    if (replaceMissingValueWith != null && value == replaceMissingValueWith) {
      return true;
    }
    return false;
  }
}
