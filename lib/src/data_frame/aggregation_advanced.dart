part of 'data_frame.dart';

/// Extension for advanced DataFrame aggregation operations
extension DataFrameAggregationAdvanced on DataFrame {
  /// Aggregate using one or more operations over the specified axis (enhanced).
  ///
  /// Parameters:
  ///   - `func`: Function(s) to use for aggregating the data
  ///     Can be a single function, list of functions, or map of column->function(s)
  ///
  /// Returns:
  ///   Aggregated result (Series or DataFrame depending on input)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  /// });
  ///
  /// // Different functions per column
  /// var result = df.aggEnhanced({
  ///   'A': ['sum', 'mean'],
  ///   'B': ['min', 'max'],
  /// });
  ///
  /// // Multiple functions for all columns
  /// var result2 = df.aggEnhanced(['sum', 'mean', 'std']);
  /// ```
  dynamic aggEnhanced(dynamic func) {
    if (func is Map<String, dynamic>) {
      // Different functions per column
      final results = <String, Map<String, dynamic>>{};

      // Apply functions to each column
      for (final entry in func.entries) {
        final colName = entry.key;
        if (!_columns.contains(colName)) continue;

        final series = column(colName);
        final funcs = entry.value is List ? entry.value : [entry.value];

        for (final f in funcs) {
          final funcName = f is String ? f : 'custom';
          if (!results.containsKey(funcName)) {
            results[funcName] = {};
          }
          results[funcName]![colName] = _applyAggFunc(series, f);
        }
      }

      // Convert to DataFrame format
      final dfData = <String, List<dynamic>>{};
      final indexNames = results.keys.toList();

      for (final entry in func.entries) {
        final colName = entry.key;
        final colData = <dynamic>[];

        for (final funcName in indexNames) {
          colData.add(results[funcName]![colName]);
        }

        dfData[colName] = colData;
      }

      return DataFrame.fromMap(dfData, index: indexNames);
    } else if (func is List) {
      // Multiple functions for all columns
      final results = <String, List<dynamic>>{};

      for (final col in _columns) {
        final series = column(col);
        final colResults = <dynamic>[];

        for (final f in func) {
          colResults.add(_applyAggFunc(series, f));
        }

        results[col.toString()] = colResults;
      }

      final funcNames = func.map((f) => f is String ? f : 'custom').toList();
      return DataFrame.fromMap(results, index: funcNames);
    } else {
      // Single function for all columns
      final results = <dynamic>[];
      for (final col in _columns) {
        final series = column(col);
        results.add(_applyAggFunc(series, func));
      }

      return Series(results, name: 'result', index: _columns);
    }
  }

  /// Apply aggregation function to a series
  dynamic _applyAggFunc(Series series, dynamic func) {
    if (func is String) {
      switch (func.toLowerCase()) {
        case 'sum':
          return series.sum();
        case 'mean':
          return series.mean();
        case 'median':
          return series.median();
        case 'min':
          return series.min();
        case 'max':
          return series.max();
        case 'std':
          return series.std();
        case 'var':
          return series.variance();
        case 'count':
          return series.count();
        case 'prod':
        case 'product':
          return series.prod();
        case 'sem':
          return _sem(series);
        case 'mad':
          return _mad(series);
        case 'nunique':
          return series.nunique();
        default:
          throw ArgumentError('Unknown aggregation function: $func');
      }
    } else if (func is Function) {
      return func(series);
    } else {
      throw ArgumentError('func must be a String or Function');
    }
  }

  /// Return the product of the values over the requested axis.
  ///
  /// Parameters:
  ///   - `axis`: Axis along which to compute product (0 for columns, 1 for rows)
  ///   - `skipna`: Exclude NA/null values
  ///   - `numeric_only`: Include only numeric columns
  ///
  /// Returns:
  ///   Series with product of values
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  /// });
  /// var products = df.prod();
  /// // A: 6, B: 120
  /// ```
  Series prod({int axis = 0, bool skipna = true, bool numericOnly = true}) {
    if (axis != 0) {
      throw UnimplementedError('prod along rows (axis=1) not yet implemented');
    }

    final results = <dynamic>[];
    final resultIndex = <dynamic>[];

    for (final col in _columns) {
      final series = column(col);

      // Skip non-numeric columns if numeric_only is true
      if (numericOnly &&
          series.dtype != int &&
          series.dtype != double &&
          series.dtype != num) {
        continue;
      }

      resultIndex.add(col);
      results.add(series.prod());
    }

    return Series(results, name: 'prod', index: resultIndex);
  }

  /// Return the standard error of the mean over requested axis.
  ///
  /// Parameters:
  ///   - `axis`: Axis along which to compute SEM
  ///   - `skipna`: Exclude NA/null values
  ///   - `ddof`: Delta degrees of freedom (default: 1)
  ///
  /// Returns:
  ///   Series with standard error of mean
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50],
  /// });
  /// var sem = df.sem();
  /// ```
  Series sem({int axis = 0, bool skipna = true, int ddof = 1}) {
    if (axis != 0) {
      throw UnimplementedError('sem along rows (axis=1) not yet implemented');
    }

    final results = <dynamic>[];

    for (final col in _columns) {
      final series = column(col);
      results.add(_sem(series, ddof: ddof));
    }

    return Series(results, name: 'sem', index: _columns);
  }

  /// Calculate standard error of mean for a series
  double _sem(Series series, {int ddof = 1}) {
    final n = series.count();
    if (n == 0) return double.nan;

    final std = series.std(ddof: ddof);
    return std / sqrt(n);
  }

  /// Return the mean absolute deviation over requested axis.
  ///
  /// Parameters:
  ///   - `axis`: Axis along which to compute MAD
  ///   - `skipna`: Exclude NA/null values
  ///
  /// Returns:
  ///   Series with mean absolute deviation
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50],
  /// });
  /// var mad = df.mad();
  /// ```
  Series mad({int axis = 0, bool skipna = true}) {
    if (axis != 0) {
      throw UnimplementedError('mad along rows (axis=1) not yet implemented');
    }

    final results = <dynamic>[];

    for (final col in _columns) {
      final series = column(col);
      results.add(_mad(series));
    }

    return Series(results, name: 'mad', index: _columns);
  }

  /// Calculate mean absolute deviation for a series
  double _mad(Series series) {
    final mean = series.mean();
    if (mean.isNaN) return double.nan;

    final deviations = <num>[];
    for (final value in series.data) {
      if (value != null && value is num) {
        deviations.add((value - mean).abs());
      }
    }

    if (deviations.isEmpty) return double.nan;

    return deviations.reduce((a, b) => a + b) / deviations.length;
  }

  /// Count unique values per column.
  ///
  /// Parameters:
  ///   - `axis`: Axis along which to count (0 for columns, 1 for rows)
  ///   - `dropna`: Don't include NaN in the counts
  ///
  /// Returns:
  ///   Series with count of unique values per column
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 1, 2, 3, 3],
  ///   'B': ['a', 'a', 'b', 'c', 'c'],
  /// });
  /// var unique = df.nunique();
  /// // A: 3, B: 3
  /// ```
  Series nunique({int axis = 0, bool dropna = true}) {
    if (axis != 0) {
      throw UnimplementedError(
          'nunique along rows (axis=1) not yet implemented');
    }

    final results = <dynamic>[];

    for (final col in _columns) {
      final series = column(col);
      results.add(series.nunique());
    }

    return Series(results, name: 'nunique', index: _columns);
  }

  /// Return a Series containing counts of unique rows in the DataFrame.
  ///
  /// Parameters:
  ///   - `subset`: Columns to use for identifying unique rows
  ///   - `normalize`: Return proportions rather than frequencies
  ///   - `sort`: Sort by frequencies
  ///   - `ascending`: Sort ascending vs descending
  ///   - `dropna`: Don't include counts of rows with NA values
  ///
  /// Returns:
  ///   Series with counts of unique rows
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 1, 2, 2],
  ///   'B': ['a', 'a', 'b', 'b'],
  /// });
  /// var counts = df.valueCounts();
  /// ```
  Series valueCountsDataFrame({
    List<String>? subset,
    bool normalize = false,
    bool sort = true,
    bool ascending = false,
    bool dropna = true,
  }) {
    final columnsToUse = subset ?? _columns.map((c) => c.toString()).toList();
    final rowCounts = <String, int>{};

    for (int i = 0; i < rowCount; i++) {
      // Check if row has NA values
      bool hasNA = false;
      final rowValues = <dynamic>[];

      for (final col in columnsToUse) {
        final colIndex = _columns.indexOf(col);
        if (colIndex == -1) continue;

        final value = _data[i][colIndex];
        if (_isNA(value)) {
          hasNA = true;
          if (dropna) break;
        }
        rowValues.add(value);
      }

      if (dropna && hasNA) continue;

      // Create a string key for the row
      final key = rowValues.join('|');
      rowCounts[key] = (rowCounts[key] ?? 0) + 1;
    }

    // Convert to lists
    var entries = rowCounts.entries.toList();

    if (sort) {
      entries.sort((a, b) {
        final cmp = a.value.compareTo(b.value);
        return ascending ? cmp : -cmp;
      });
    }

    final counts = entries.map((e) => e.value).toList();
    final indices = entries.map((e) => e.key).toList();

    if (normalize) {
      final total = counts.fold<num>(0, (sum, val) => sum + val);
      final normalized = counts.map((c) => c / total).toList();
      return Series(normalized, name: 'proportion', index: indices);
    }

    return Series(counts, name: 'count', index: indices);
  }

  /// Check if value is NA
  bool _isNA(dynamic value) {
    if (value == null) return true;
    if (replaceMissingValueWith != null && value == replaceMissingValueWith) {
      return true;
    }
    return false;
  }
}
