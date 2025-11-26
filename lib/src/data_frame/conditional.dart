part of 'data_frame.dart';

/// Extension for DataFrame conditional operations
extension DataFrameConditional on DataFrame {
  /// Replace values where condition is False.
  ///
  /// Parameters:
  ///   - `cond`: Where cond is True, keep the original value. Where False, replace with
  ///     corresponding value from other. Can be a DataFrame, Series, or scalar value.
  ///   - `other`: Value to use where cond is False (default: null)
  ///   - `inplace`: Whether to perform operation in place (default: false)
  ///
  /// Returns:
  ///   DataFrame with replaced values (or null if inplace=true)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4],
  ///   'B': [5, 6, 7, 8],
  /// });
  ///
  /// // Replace values less than 3 with 0
  /// var result = df.where(df > 3, other: 0);
  /// // A: [0, 0, 3, 4], B: [5, 6, 7, 8]
  ///
  /// // Using a condition DataFrame
  /// var cond = DataFrame.fromMap({
  ///   'A': [true, false, true, false],
  ///   'B': [false, true, false, true],
  /// });
  /// var result2 = df.where(cond, other: -1);
  /// ```
  DataFrame? where(
    dynamic cond, {
    dynamic other,
    bool inplace = false,
  }) {
    return _conditionalReplace(cond,
        other: other, inplace: inplace, keepWhenTrue: true);
  }

  /// Replace values where condition is True.
  ///
  /// This is the inverse of where(). Where cond is True, replace with other.
  /// Where False, keep the original value.
  ///
  /// Parameters:
  ///   - `cond`: Where cond is True, replace with other. Where False, keep original.
  ///   - `other`: Value to use where cond is True (default: null)
  ///   - `inplace`: Whether to perform operation in place (default: false)
  ///
  /// Returns:
  ///   DataFrame with replaced values (or null if inplace=true)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4],
  ///   'B': [5, 6, 7, 8],
  /// });
  ///
  /// // Replace values greater than 3 with 0
  /// var result = df.mask(df > 3, other: 0);
  /// // A: [1, 2, 3, 0], B: [0, 0, 0, 0]
  /// ```
  DataFrame? mask(
    dynamic cond, {
    dynamic other,
    bool inplace = false,
  }) {
    return _conditionalReplace(cond,
        other: other, inplace: inplace, keepWhenTrue: false);
  }

  /// Internal method for conditional replacement
  DataFrame? _conditionalReplace(
    dynamic cond, {
    dynamic other,
    bool inplace = false,
    bool keepWhenTrue = true,
  }) {
    DataFrame condDf;

    // Convert condition to DataFrame of booleans
    if (cond is DataFrame) {
      condDf = cond;
    } else if (cond is Series) {
      // Broadcast Series to all columns
      condDf = DataFrame.fromMap(
          {for (final col in _columns) col.toString(): cond.data},
          index: index);
    } else if (cond is bool) {
      // Scalar boolean - apply to all values
      condDf = DataFrame.fromMap({
        for (final col in _columns) col.toString(): List.filled(rowCount, cond)
      }, index: index);
    } else {
      throw ArgumentError('cond must be a DataFrame, Series, or bool');
    }

    // Validate dimensions
    if (condDf.rowCount != rowCount || condDf.columnCount != columnCount) {
      throw ArgumentError(
          'Condition DataFrame must have same shape as original DataFrame');
    }

    // Prepare replacement values
    DataFrame otherDf;
    if (other is DataFrame) {
      otherDf = other;
    } else if (other is Series) {
      otherDf = DataFrame.fromMap(
          {for (final col in _columns) col.toString(): other.data},
          index: index);
    } else {
      // Scalar value - broadcast to all positions
      otherDf = DataFrame.fromMap({
        for (final col in _columns) col.toString(): List.filled(rowCount, other)
      }, index: index);
    }

    // Perform replacement
    final newData = <List<dynamic>>[];

    for (int i = 0; i < rowCount; i++) {
      final newRow = <dynamic>[];
      for (int j = 0; j < columnCount; j++) {
        final condValue = condDf._data[i][j];
        final shouldKeep = keepWhenTrue ? condValue == true : condValue != true;

        if (shouldKeep) {
          newRow.add(_data[i][j]);
        } else {
          newRow.add(otherDf._data[i][j]);
        }
      }
      newData.add(newRow);
    }

    if (inplace) {
      _data = newData;
      return null;
    } else {
      return DataFrame(
        newData,
        columns: _columns,
        index: index,
        allowFlexibleColumns: allowFlexibleColumns,
      );
    }
  }

  /// Assign new columns to a DataFrame.
  ///
  /// Returns a new DataFrame with new columns added. Existing columns that are
  /// re-assigned will be overwritten.
  ///
  /// Parameters:
  ///   - `assignments`: Map of column names to values. Values can be:
  ///     - A List of values
  ///     - A Series
  ///     - A scalar value (will be broadcast)
  ///     - A function that takes the DataFrame and returns values
  ///
  /// Returns:
  ///   A new DataFrame with the assigned columns
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  /// });
  ///
  /// // Assign new columns
  /// var result = df.assign({
  ///   'C': [7, 8, 9],
  ///   'D': (df) => df['A'] + df['B'],  // Computed column
  ///   'E': 10,  // Scalar broadcast
  /// });
  ///
  /// // Chain assignments
  /// var result2 = df
  ///   .assign({'C': [7, 8, 9]})
  ///   .assign({'D': (df) => df['A'] + df['C']});
  /// ```
  DataFrame assign(Map<String, dynamic> assignments) {
    // Start with a copy of the current DataFrame
    var result = copy();

    for (final entry in assignments.entries) {
      final colName = entry.key;
      final value = entry.value;

      List<dynamic> colData;

      if (value is Function) {
        // Function that takes DataFrame and returns values
        final computed = value(result);

        if (computed is Series) {
          colData = computed.data;
        } else if (computed is List) {
          colData = computed;
        } else {
          // Scalar value from function
          colData = List.filled(rowCount, computed);
        }
      } else if (value is Series) {
        colData = value.data;
      } else if (value is List) {
        colData = value;
      } else {
        // Scalar value - broadcast to all rows
        colData = List.filled(rowCount, value);
      }

      // Validate length
      if (colData.length != rowCount) {
        throw ArgumentError(
            'Length of values (${colData.length}) does not match length of index ($rowCount)');
      }

      // Assign the column
      result[colName] = colData;
    }

    return result;
  }

  /// Insert column into DataFrame at specified location.
  ///
  /// Parameters:
  ///   - `loc`: Insertion index (0 to columnCount)
  ///   - `column`: Name of column to insert
  ///   - `value`: Values to insert (List, Series, or scalar)
  ///   - `allowDuplicates`: Whether to allow duplicate column names (default: false)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'C': [7, 8, 9],
  /// });
  ///
  /// df.insert(1, 'B', [4, 5, 6]);
  /// // Columns are now: ['A', 'B', 'C']
  /// ```
  void insert(
    int loc,
    String column, {
    required dynamic value,
    bool allowDuplicates = false,
  }) {
    if (loc < 0 || loc > columnCount) {
      throw RangeError('loc must be between 0 and $columnCount');
    }

    if (!allowDuplicates && _columns.contains(column)) {
      throw ArgumentError('Column $column already exists');
    }

    List<dynamic> colData;

    if (value is Series) {
      colData = value.data;
    } else if (value is List) {
      colData = value;
    } else {
      // Scalar - broadcast
      colData = List.filled(rowCount, value);
    }

    if (colData.length != rowCount) {
      throw ArgumentError(
          'Length of values (${colData.length}) does not match length of index ($rowCount)');
    }

    // Insert column name
    _columns.insert(loc, column);

    // Insert data into each row
    for (int i = 0; i < rowCount; i++) {
      _data[i].insert(loc, colData[i]);
    }
  }

  /// Return item and drop from DataFrame.
  ///
  /// Parameters:
  ///   - `item`: Column name to pop
  ///
  /// Returns:
  ///   Series with the popped column data
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  ///   'C': [7, 8, 9],
  /// });
  ///
  /// var popped = df.pop('B');
  /// // df now has columns ['A', 'C']
  /// // popped is Series with data [4, 5, 6]
  /// ```
  Series pop(String item) {
    if (!_columns.contains(item)) {
      throw ArgumentError('Column $item does not exist');
    }

    final colIndex = _columns.indexOf(item);
    final colData = <dynamic>[];

    // Extract column data
    for (int i = 0; i < rowCount; i++) {
      colData.add(_data[i][colIndex]);
    }

    // Remove column
    _columns.removeAt(colIndex);

    // Remove data from each row
    for (int i = 0; i < rowCount; i++) {
      _data[i].removeAt(colIndex);
    }

    return Series(colData, name: item, index: index);
  }
}
