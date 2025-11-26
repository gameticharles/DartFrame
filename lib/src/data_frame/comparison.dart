part of 'data_frame.dart';

/// Extension for DataFrame comparison operations
extension DataFrameComparison on DataFrame {
  /// Test whether two DataFrames contain the same elements.
  ///
  /// This method allows two DataFrames to be compared element-wise.
  /// NaNs in the same location are considered equal.
  ///
  /// Parameters:
  ///   - `other`: The DataFrame to compare with
  ///
  /// Returns:
  ///   true if all elements are equal, false otherwise
  ///
  /// Example:
  /// ```dart
  /// var df1 = DataFrame.fromMap({'A': [1, 2], 'B': [3, 4]});
  /// var df2 = DataFrame.fromMap({'A': [1, 2], 'B': [3, 4]});
  /// var df3 = DataFrame.fromMap({'A': [1, 2], 'B': [3, 5]});
  ///
  /// print(df1.equals(df2)); // true
  /// print(df1.equals(df3)); // false
  /// ```
  bool equals(DataFrame other) {
    // Check shape
    if (rowCount != other.rowCount || columnCount != other.columnCount) {
      return false;
    }

    // Check columns
    if (_columns.length != other._columns.length) {
      return false;
    }

    for (int i = 0; i < _columns.length; i++) {
      if (_columns[i] != other._columns[i]) {
        return false;
      }
    }

    // Check index
    if (index.length != other.index.length) {
      return false;
    }

    for (int i = 0; i < index.length; i++) {
      if (index[i] != other.index[i]) {
        return false;
      }
    }

    // Check data
    for (int i = 0; i < rowCount; i++) {
      for (int j = 0; j < columnCount; j++) {
        final val1 = _data[i][j];
        final val2 = other._data[i][j];

        // Handle NaN comparison
        if (val1 is double && val1.isNaN && val2 is double && val2.isNaN) {
          continue;
        }

        if (val1 != val2) {
          return false;
        }
      }
    }

    return true;
  }

  /// Compare to another DataFrame and show differences.
  ///
  /// Parameters:
  ///   - `other`: DataFrame to compare with
  ///   - `keepShape`: If true, keep all rows and columns (default: false)
  ///   - `keepEqual`: If true, keep matching values (default: false)
  ///
  /// Returns:
  ///   DataFrame showing differences
  ///
  /// Example:
  /// ```dart
  /// var df1 = DataFrame.fromMap({'A': [1, 2, 3], 'B': [4, 5, 6]});
  /// var df2 = DataFrame.fromMap({'A': [1, 2, 9], 'B': [4, 8, 6]});
  ///
  /// var diff = df1.compare(df2);
  /// // Shows only the differing values
  /// ```
  DataFrame compare(
    DataFrame other, {
    bool keepShape = false,
    bool keepEqual = false,
  }) {
    if (rowCount != other.rowCount || columnCount != other.columnCount) {
      throw ArgumentError('Can only compare DataFrames of the same shape');
    }

    if (!_columns.every((col) => other._columns.contains(col))) {
      throw ArgumentError('DataFrames must have the same columns');
    }

    final resultData = <String, List<dynamic>>{};
    final resultIndex = <dynamic>[];

    // Create columns for comparison (self and other)
    for (final col in _columns) {
      resultData['${col}_self'] = [];
      resultData['${col}_other'] = [];
    }

    // Compare row by row
    for (int i = 0; i < rowCount; i++) {
      bool rowHasDiff = false;

      for (int j = 0; j < columnCount; j++) {
        final val1 = _data[i][j];
        final val2 = other._data[i][j];

        if (val1 != val2) {
          rowHasDiff = true;
          break;
        }
      }

      if (keepShape || rowHasDiff || keepEqual) {
        resultIndex.add(index[i]);

        for (int j = 0; j < columnCount; j++) {
          final colName = _columns[j].toString();
          final val1 = _data[i][j];
          final val2 = other._data[i][j];

          // Always add data for all columns when including a row
          resultData['${colName}_self']!.add(val1);
          resultData['${colName}_other']!.add(val2);
        }
      }
    }

    return DataFrame.fromMap(resultData, index: resultIndex);
  }

  /// Element-wise equality comparison.
  ///
  /// Returns a DataFrame of booleans showing whether each element
  /// is equal to the corresponding element in other.
  ///
  /// Parameters:
  ///   - `other`: DataFrame, Series, or scalar to compare with
  ///
  /// Returns:
  ///   DataFrame of booleans
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2, 3], 'B': [4, 5, 6]});
  /// var result = df.eq(2);
  /// // Returns DataFrame with true where values equal 2
  /// ```
  DataFrame eq(dynamic other) {
    return _elementwiseComparison(other, (a, b) => a == b);
  }

  /// Element-wise not-equal comparison.
  DataFrame ne(dynamic other) {
    return _elementwiseComparison(other, (a, b) => a != b);
  }

  /// Element-wise less-than comparison.
  DataFrame lt(dynamic other) {
    return _elementwiseComparison(other, (a, b) {
      if (a is Comparable && b is Comparable) {
        try {
          return a.compareTo(b) < 0;
        } catch (e) {
          return false;
        }
      }
      return false;
    });
  }

  /// Element-wise greater-than comparison.
  DataFrame gt(dynamic other) {
    return _elementwiseComparison(other, (a, b) {
      if (a is Comparable && b is Comparable) {
        try {
          return a.compareTo(b) > 0;
        } catch (e) {
          return false;
        }
      }
      return false;
    });
  }

  /// Element-wise less-than-or-equal comparison.
  DataFrame le(dynamic other) {
    return _elementwiseComparison(other, (a, b) {
      if (a is Comparable && b is Comparable) {
        try {
          return a.compareTo(b) <= 0;
        } catch (e) {
          return false;
        }
      }
      return false;
    });
  }

  /// Element-wise greater-than-or-equal comparison.
  DataFrame ge(dynamic other) {
    return _elementwiseComparison(other, (a, b) {
      if (a is Comparable && b is Comparable) {
        try {
          return a.compareTo(b) >= 0;
        } catch (e) {
          return false;
        }
      }
      return false;
    });
  }

  /// Internal method for element-wise comparison
  DataFrame _elementwiseComparison(
    dynamic other,
    bool Function(dynamic, dynamic) comparator,
  ) {
    final resultData = <List<dynamic>>[];

    if (other is DataFrame) {
      if (rowCount != other.rowCount || columnCount != other.columnCount) {
        throw ArgumentError('DataFrames must have the same shape');
      }

      for (int i = 0; i < rowCount; i++) {
        final row = <dynamic>[];
        for (int j = 0; j < columnCount; j++) {
          row.add(comparator(_data[i][j], other._data[i][j]));
        }
        resultData.add(row);
      }
    } else if (other is Series) {
      if (other.length != rowCount) {
        throw ArgumentError('Series length must match DataFrame row count');
      }

      for (int i = 0; i < rowCount; i++) {
        final row = <dynamic>[];
        for (int j = 0; j < columnCount; j++) {
          row.add(comparator(_data[i][j], other.data[i]));
        }
        resultData.add(row);
      }
    } else {
      // Scalar comparison
      for (int i = 0; i < rowCount; i++) {
        final row = <dynamic>[];
        for (int j = 0; j < columnCount; j++) {
          row.add(comparator(_data[i][j], other));
        }
        resultData.add(row);
      }
    }

    return DataFrame(
      resultData,
      columns: _columns,
      index: index,
      allowFlexibleColumns: allowFlexibleColumns,
    );
  }
}
