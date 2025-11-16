part of 'data_frame.dart';

/// Extension providing data manipulation operations for DataFrame.
extension DataFrameOperations on DataFrame {
  /// Trim values at input thresholds.
  ///
  /// Assigns values outside boundary to boundary values. This is useful for
  /// limiting extreme values in your data.
  ///
  /// Parameters:
  /// - `lower`: Minimum threshold value. Values below this will be set to this value.
  /// - `upper`: Maximum threshold value. Values above this will be set to this value.
  /// - `axis`: Not used, kept for pandas compatibility.
  ///
  /// At least one of `lower` or `upper` must be specified.
  ///
  /// Returns:
  /// A new DataFrame with clipped values.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 10],
  ///   [2, 20],
  ///   [3, 30],
  ///   [4, 40],
  ///   [5, 50],
  /// ], columns: ['A', 'B']);
  ///
  /// // Clip values between 2 and 4
  /// var clipped = df.clip(lower: 2, upper: 4);
  /// // A: [2, 2, 3, 4, 4]
  /// // B: [10, 20, 30, 40, 50] (non-numeric, unchanged)
  ///
  /// // Clip only lower bound
  /// var clippedLower = df.clip(lower: 3);
  /// // A: [3, 3, 3, 4, 5]
  ///
  /// // Clip only upper bound
  /// var clippedUpper = df.clip(upper: 3);
  /// // A: [1, 2, 3, 3, 3]
  /// ```
  DataFrame clip({num? lower, num? upper, int axis = 0}) {
    if (lower == null && upper == null) {
      throw ArgumentError('Must specify at least one of lower or upper');
    }

    if (lower != null && upper != null && lower > upper) {
      throw ArgumentError('lower must be less than or equal to upper');
    }

    List<List<dynamic>> clippedData = [];

    for (int i = 0; i < rowCount; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < columnCount; j++) {
        var value = _data[i][j];

        // Only clip numeric values
        if (value is num) {
          if (lower != null && value < lower) {
            row.add(lower);
          } else if (upper != null && value > upper) {
            row.add(upper);
          } else {
            row.add(value);
          }
        } else {
          // Non-numeric values remain unchanged
          row.add(value);
        }
      }
      clippedData.add(row);
    }

    return DataFrame(
      clippedData,
      columns: columns.cast<String>(),
      index: index,
    );
  }

  /// Compute absolute value of numeric columns.
  ///
  /// Returns a DataFrame with absolute values for all numeric columns.
  /// Non-numeric columns remain unchanged.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [-1, -10],
  ///   [2, -20],
  ///   [-3, 30],
  /// ], columns: ['A', 'B']);
  ///
  /// var result = df.abs();
  /// // A: [1, 2, 3]
  /// // B: [10, 20, 30]
  /// ```
  DataFrame abs() {
    List<List<dynamic>> absData = [];

    for (int i = 0; i < rowCount; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < columnCount; j++) {
        var value = _data[i][j];

        if (value is num) {
          row.add(value.abs());
        } else {
          row.add(value);
        }
      }
      absData.add(row);
    }

    return DataFrame(
      absData,
      columns: columns.cast<String>(),
      index: index,
    );
  }

  /// Calculate the percentage change between consecutive rows.
  ///
  /// Computes the percentage change from the immediately previous row by default.
  ///
  /// Parameters:
  /// - `periods`: Periods to shift for calculating percent change (default: 1)
  /// - `axis`: 0 for rows (default), 1 for columns
  ///
  /// Returns:
  /// A new DataFrame with percentage changes.
  ///
  /// Formula: (current - previous) / previous
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [100, 200],
  ///   [110, 220],
  ///   [121, 242],
  /// ], columns: ['A', 'B']);
  ///
  /// var pct = df.pctChange();
  /// // A: [null, 0.1, 0.1]  (10% increase each time)
  /// // B: [null, 0.1, 0.1]
  /// ```
  DataFrame pctChange({int periods = 1, int axis = 0}) {
    if (periods <= 0) {
      throw ArgumentError('periods must be positive');
    }

    if (axis != 0) {
      throw ArgumentError('Only axis=0 (rows) is currently supported');
    }

    List<List<dynamic>> pctData = [];

    for (int i = 0; i < rowCount; i++) {
      List<dynamic> row = [];

      for (int j = 0; j < columnCount; j++) {
        if (i < periods) {
          // Not enough previous data
          row.add(null);
        } else {
          var current = _data[i][j];
          var previous = _data[i - periods][j];

          if (current is num && previous is num && previous != 0) {
            row.add((current - previous) / previous);
          } else {
            row.add(null);
          }
        }
      }
      pctData.add(row);
    }

    return DataFrame(
      pctData,
      columns: columns.cast<String>(),
      index: index,
    );
  }

  /// Calculate the first discrete difference.
  ///
  /// Computes the difference between consecutive rows.
  ///
  /// Parameters:
  /// - `periods`: Periods to shift for calculating difference (default: 1)
  /// - `axis`: 0 for rows (default), 1 for columns
  ///
  /// Returns:
  /// A new DataFrame with differences.
  ///
  /// Formula: current - previous
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 10],
  ///   [3, 15],
  ///   [6, 25],
  /// ], columns: ['A', 'B']);
  ///
  /// var diff = df.diff();
  /// // A: [null, 2, 3]
  /// // B: [null, 5, 10]
  /// ```
  DataFrame diff({int periods = 1, int axis = 0}) {
    if (periods <= 0) {
      throw ArgumentError('periods must be positive');
    }

    if (axis != 0) {
      throw ArgumentError('Only axis=0 (rows) is currently supported');
    }

    List<List<dynamic>> diffData = [];

    for (int i = 0; i < rowCount; i++) {
      List<dynamic> row = [];

      for (int j = 0; j < columnCount; j++) {
        if (i < periods) {
          // Not enough previous data
          row.add(null);
        } else {
          var current = _data[i][j];
          var previous = _data[i - periods][j];

          if (current is num && previous is num) {
            row.add(current - previous);
          } else {
            row.add(null);
          }
        }
      }
      diffData.add(row);
    }

    return DataFrame(
      diffData,
      columns: columns.cast<String>(),
      index: index,
    );
  }

  /// Return index of maximum value for each column.
  ///
  /// Returns a Series with the index label of the maximum value for each column.
  ///
  /// Parameters:
  /// - `axis`: 0 for columns (default), 1 for rows
  /// - `skipna`: Exclude NA/null values (default: true)
  ///
  /// Returns:
  /// A Series with index labels of maximum values.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 10],
  ///   [3, 5],
  ///   [2, 15],
  /// ], columns: ['A', 'B'], index: ['x', 'y', 'z']);
  ///
  /// var idxmax = df.idxmax();
  /// // A: 'y' (value 3 at index y)
  /// // B: 'z' (value 15 at index z)
  /// ```
  Series idxmax({int axis = 0, bool skipna = true}) {
    if (axis != 0) {
      throw ArgumentError('Only axis=0 (columns) is currently supported');
    }

    List<dynamic> maxIndices = [];
    List<String> resultIndex = [];

    for (int j = 0; j < columnCount; j++) {
      var colName = columns[j].toString();
      resultIndex.add(colName);

      num? maxValue;
      dynamic maxIndex;

      for (int i = 0; i < rowCount; i++) {
        var value = _data[i][j];

        if (value == null && skipna) {
          continue;
        }

        if (value is num) {
          if (maxValue == null || value > maxValue) {
            maxValue = value;
            maxIndex = index[i];
          }
        }
      }

      maxIndices.add(maxIndex);
    }

    return Series(maxIndices, name: 'idxmax', index: resultIndex);
  }

  /// Return index of minimum value for each column.
  ///
  /// Returns a Series with the index label of the minimum value for each column.
  ///
  /// Parameters:
  /// - `axis`: 0 for columns (default), 1 for rows
  /// - `skipna`: Exclude NA/null values (default: true)
  ///
  /// Returns:
  /// A Series with index labels of minimum values.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 10],
  ///   [3, 5],
  ///   [2, 15],
  /// ], columns: ['A', 'B'], index: ['x', 'y', 'z']);
  ///
  /// var idxmin = df.idxmin();
  /// // A: 'x' (value 1 at index x)
  /// // B: 'y' (value 5 at index y)
  /// ```
  Series idxmin({int axis = 0, bool skipna = true}) {
    if (axis != 0) {
      throw ArgumentError('Only axis=0 (columns) is currently supported');
    }

    List<dynamic> minIndices = [];
    List<String> resultIndex = [];

    for (int j = 0; j < columnCount; j++) {
      var colName = columns[j].toString();
      resultIndex.add(colName);

      num? minValue;
      dynamic minIndex;

      for (int i = 0; i < rowCount; i++) {
        var value = _data[i][j];

        if (value == null && skipna) {
          continue;
        }

        if (value is num) {
          if (minValue == null || value < minValue) {
            minValue = value;
            minIndex = index[i];
          }
        }
      }

      minIndices.add(minIndex);
    }

    return Series(minIndices, name: 'idxmin', index: resultIndex);
  }

  /// Quantile-based discretization function.
  ///
  /// Discretize variables into equal-sized buckets based on rank or sample quantiles.
  /// Applies qcut to specified columns.
  ///
  /// Parameters:
  /// - `columns`: Column name (String) or list of column names to discretize
  /// - `q`: Number of quantiles (int) or array of quantiles (List<num>)
  /// - `labels`: Labels for the resulting bins. If false, returns integer indicators.
  ///   If null, labels are constructed from bin edges.
  /// - `precision`: Precision for bin labels (default: 3)
  /// - `duplicates`: How to handle duplicate bin edges: 'raise' or 'drop' (default: 'raise')
  ///
  /// Returns:
  /// A new DataFrame with specified columns discretized into quantile-based bins.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 100],
  ///   [2, 200],
  ///   [3, 300],
  ///   [4, 400],
  ///   [5, 500],
  /// ], columns: ['A', 'B']);
  ///
  /// // Discretize column A into quartiles
  /// var result = df.qcut('A', 4);
  ///
  /// // Discretize multiple columns
  /// var result = df.qcut(['A', 'B'], 3);
  ///
  /// // With custom labels
  /// var result = df.qcut('A', 3, labels: ['Low', 'Medium', 'High']);
  /// ```
  DataFrame qcut(
    dynamic columns,
    dynamic q, {
    dynamic labels,
    int precision = 3,
    String duplicates = 'raise',
  }) {
    // Normalize columns to list
    List<String> targetColumns;
    if (columns is String) {
      targetColumns = [columns];
    } else if (columns is List) {
      targetColumns = columns.cast<String>();
    } else {
      throw ArgumentError('columns must be String or List<String>');
    }

    // Validate columns exist
    for (var col in targetColumns) {
      if (!this.columns.contains(col)) {
        throw ArgumentError('Column "$col" not found in DataFrame');
      }
    }

    // Create a copy of the data
    List<List<dynamic>> newData = [];
    for (var row in _data) {
      newData.add(List.from(row));
    }

    // Apply qcut to each target column
    for (var colName in targetColumns) {
      int colIdx = this.columns.indexOf(colName);

      // Extract column data
      List<dynamic> colData = [];
      for (int i = 0; i < rowCount; i++) {
        colData.add(_data[i][colIdx]);
      }

      // Create a properly typed Series (not Series<dynamic>)
      Series series = Series(colData, name: colName, index: index);

      // Apply qcut
      var qcutSeries = series.qcut(
        q,
        labels: labels,
        precision: precision,
        duplicates: duplicates,
      );

      // Replace column data
      for (int i = 0; i < rowCount; i++) {
        newData[i][colIdx] = qcutSeries.data[i];
      }
    }

    return DataFrame(
      newData,
      columns: this.columns.cast<String>(),
      index: index,
    );
  }
}
