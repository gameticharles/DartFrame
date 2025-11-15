part of 'data_frame.dart';

extension DataFrameFunctionalProgramming on DataFrame {
  /// Apply a function along an axis of the DataFrame.
  ///
  /// Parameters:
  /// - `func`: Function to apply to each column/row
  /// - `axis`: 0 or 'index' for columns, 1 or 'columns' for rows
  /// - `resultType`: 'expand', 'reduce', 'broadcast', or null (auto-detect)
  ///
  /// Returns:
  /// DataFrame or Series depending on the function and result_type
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2, 3], 'B': [4, 5, 6]});
  ///
  /// // Apply to columns (axis=0)
  /// var colSums = df.apply((col) => col.sum(), axis: 0);
  /// // Returns Series with sum of each column
  ///
  /// // Apply to rows (axis=1)
  /// var rowSums = df.apply((row) => row.sum(), axis: 1);
  /// // Returns Series with sum of each row
  /// ```
  dynamic apply(
    dynamic Function(dynamic) func, {
    dynamic axis = 0,
    String? resultType,
  }) {
    final axisInt = axis is String ? (axis == 'index' ? 0 : 1) : axis as int;

    if (axisInt == 0) {
      // Apply to each column
      final results = <dynamic, dynamic>{};

      for (var colName in columns) {
        final series = this[colName];
        results[colName] = func(series);
      }

      // Determine result type
      if (resultType == 'expand' ||
          (resultType == null && results.values.first is List)) {
        // Return DataFrame
        return DataFrame.fromMap(
            results.map((k, v) => MapEntry(k.toString(), v is List ? v : [v])));
      } else {
        // Return Series
        return Series(
          results.values.toList(),
          name: 'apply_result',
          index: results.keys.toList(),
        );
      }
    } else {
      // Apply to each row
      final results = <dynamic>[];

      for (int i = 0; i < rows.length; i++) {
        final rowData = rows[i];
        final rowSeries = Series(rowData,
            name: index[i].toString(),
            index: columns.map((c) => c.toString()).toList());
        results.add(func(rowSeries));
      }

      if (resultType == 'expand' ||
          (resultType == null && results.first is List)) {
        // Return DataFrame
        final expandedData = results.map((r) => r is List ? r : [r]).toList();
        return DataFrame(expandedData, index: index);
      } else {
        // Return Series
        return Series(results, name: 'apply_result', index: index);
      }
    }
  }

  /// Apply a function element-wise to the DataFrame.
  ///
  /// Parameters:
  /// - `func`: Function to apply to each element
  /// - `naAction`: 'ignore' to skip null values, null to include them
  ///
  /// Returns:
  /// DataFrame with the function applied to each element
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2, 3], 'B': [4, 5, 6]});
  ///
  /// // Square each element
  /// var squared = df.applymap((x) => x * x);
  /// // Returns DataFrame with all values squared
  ///
  /// // Convert to strings
  /// var strings = df.applymap((x) => 'Value: $x');
  /// ```
  DataFrame applymap(
    dynamic Function(dynamic) func, {
    String? naAction,
  }) {
    final newData = <List<dynamic>>[];

    for (var row in rows) {
      final newRow = <dynamic>[];
      for (var value in row) {
        if (naAction == 'ignore' && _isMissingValue(value)) {
          newRow.add(value);
        } else {
          newRow.add(func(value));
        }
      }
      newData.add(newRow);
    }

    return DataFrame(
      newData,
      columns: columns,
      index: index,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Aggregate using one or more operations.
  ///
  /// Parameters:
  /// - `func`: Function, list of functions, or dict of column -> function(s)
  /// - `axis`: 0 for columns, 1 for rows
  ///
  /// Returns:
  /// Series or DataFrame with aggregated values
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2, 3], 'B': [4, 5, 6]});
  ///
  /// // Single function
  /// var sums = df.agg((col) => col.sum());
  /// // Returns Series with sum of each column
  ///
  /// // Multiple functions
  /// var stats = df.agg([
  ///   (col) => col.sum(),
  ///   (col) => col.mean(),
  ///   (col) => col.max(),
  /// ]);
  /// // Returns DataFrame with multiple aggregations
  ///
  /// // Different functions per column
  /// var mixed = df.agg({
  ///   'A': (col) => col.sum(),
  ///   'B': (col) => col.mean(),
  /// });
  /// ```
  dynamic agg(
    dynamic func, {
    int axis = 0,
  }) {
    if (func is dynamic Function(dynamic)) {
      // Single function
      return apply(func, axis: axis);
    } else if (func is List) {
      // Multiple functions
      final results = <String, List<dynamic>>{};

      for (var colName in columns) {
        final series = this[colName];
        final colResults = <dynamic>[];

        for (var f in func) {
          colResults.add(f(series));
        }

        results[colName.toString()] = colResults;
      }

      return DataFrame.fromMap(results);
    } else if (func is Map) {
      // Different functions per column
      final results = <String, dynamic>{};

      func.forEach((colName, colFunc) {
        if (!columns.contains(colName)) {
          throw ArgumentError('Column "$colName" not found');
        }

        final series = this[colName];

        if (colFunc is List) {
          // Multiple functions for this column
          results[colName.toString()] = colFunc.map((f) => f(series)).toList();
        } else {
          // Single function for this column
          results[colName.toString()] = colFunc(series);
        }
      });

      // Check if all results are single values or lists
      final allSingle = results.values.every((v) => v is! List);

      if (allSingle) {
        return Series(
          results.values.toList(),
          name: 'agg_result',
          index: results.keys.toList(),
        );
      } else {
        // Convert to DataFrame
        final maxLen = results.values
            .map((v) => v is List ? v.length : 1)
            .reduce((a, b) => a > b ? a : b);

        final dfData = <String, List<dynamic>>{};
        results.forEach((k, v) {
          dfData[k] = v is List ? v : List.filled(maxLen, v);
        });

        return DataFrame.fromMap(dfData);
      }
    } else {
      throw ArgumentError('func must be a Function, List, or Map');
    }
  }

  /// Transform values using a function.
  ///
  /// Parameters:
  /// - `func`: Function to transform values
  /// - `axis`: 0 for columns, 1 for rows
  ///
  /// Returns:
  /// DataFrame with transformed values (same shape as input)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2, 3], 'B': [4, 5, 6]});
  ///
  /// // Normalize each column
  /// var normalized = df.transform((col) {
  ///   var mean = col.mean();
  ///   var std = col.std();
  ///   return col.data.map((x) => (x - mean) / std).toList();
  /// });
  /// ```
  DataFrame transform(
    dynamic Function(Series) func, {
    int axis = 0,
  }) {
    if (axis == 0) {
      // Transform each column
      final newData = <String, List<dynamic>>{};

      for (var colName in columns) {
        final series = this[colName];
        final result = func(series);

        if (result is Series) {
          newData[colName.toString()] = result.data;
        } else if (result is List) {
          newData[colName.toString()] = result;
        } else {
          throw ArgumentError('Transform function must return Series or List');
        }
      }

      return DataFrame.fromMap(newData, index: index);
    } else {
      // Transform each row
      final newData = <List<dynamic>>[];

      for (int i = 0; i < rows.length; i++) {
        final rowData = rows[i];
        final rowSeries = Series(rowData,
            name: index[i].toString(),
            index: columns.map((c) => c.toString()).toList());
        final result = func(rowSeries);

        if (result is Series) {
          newData.add(result.data);
        } else if (result is List) {
          newData.add(result);
        } else {
          throw ArgumentError('Transform function must return Series or List');
        }
      }

      return DataFrame(newData, columns: columns, index: index);
    }
  }

  /// Apply chainable functions to the DataFrame.
  ///
  /// Parameters:
  /// - `func`: Function that takes a DataFrame and returns a DataFrame
  /// - `args`: Additional positional arguments to pass to func
  /// - `kwargs`: Additional keyword arguments to pass to func
  ///
  /// Returns:
  /// Result of applying func to the DataFrame
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2, 3], 'B': [4, 5, 6]});
  ///
  /// // Chain operations
  /// var result = df
  ///   .pipe((df) => df.applymap((x) => x * 2))
  ///   .pipe((df) => df.apply((col) => col.sum(), axis: 0));
  ///
  /// // With custom function
  /// DataFrame addColumn(DataFrame df, String name, List values) {
  ///   df[name] = values;
  ///   return df;
  /// }
  ///
  /// var result2 = df.pipe((df) => addColumn(df, 'C', [7, 8, 9]));
  /// ```
  dynamic pipe(dynamic Function(DataFrame) func) {
    return func(this);
  }
}
