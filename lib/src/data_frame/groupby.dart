part of 'data_frame.dart';

/// A class representing a grouped DataFrame for split-apply-combine operations.
///
/// This class provides pandas-like groupby functionality with support for:
/// - Multiple aggregation functions
/// - Transform operations
/// - Filter operations
/// - Cumulative operations
/// - Named aggregations
/// - Method chaining with pipe()
///
/// Example:
/// ```dart
/// var df = DataFrame([
///   ['A', 1, 100],
///   ['B', 2, 200],
///   ['A', 3, 150],
/// ], columns: ['group', 'value', 'amount']);
///
/// // Basic aggregation
/// var grouped = df.groupBy2(['group']).sum();
///
/// // Transform
/// var normalized = df.groupBy2(['group']).transform((group) {
///   var mean = group['value'].mean();
///   return group.withColumn('centered', group['value'].apply((v) => v - mean));
/// });
///
/// // Filter groups
/// var filtered = df.groupBy2(['group']).filter((group) => group.rowCount > 1);
/// ```
class GroupBy {
  final DataFrame _df;
  final List<String> _groupColumns;
  Map<dynamic, DataFrame>? _groups;

  /// Creates a GroupBy object.
  ///
  /// Parameters:
  /// - `_df`: The DataFrame to group
  /// - `_groupColumns`: List of column names to group by
  GroupBy(this._df, this._groupColumns) {
    // Validate group columns exist
    for (var col in _groupColumns) {
      if (!_df.columns.contains(col)) {
        throw ArgumentError('Column "$col" not found in DataFrame');
      }
    }
  }

  /// Lazily compute and cache the groups.
  Map<dynamic, DataFrame> get groups {
    _groups ??= _df
        .groupBy(_groupColumns.length == 1 ? _groupColumns[0] : _groupColumns);
    return _groups!;
  }

  /// Helper method to concatenate DataFrames.
  DataFrame _concatDataFrames(List<DataFrame> dfs) {
    if (dfs.isEmpty) {
      return DataFrame.empty(columns: _df.columns);
    }
    if (dfs.length == 1) {
      return dfs.first;
    }
    return dfs.first.concatenate(dfs.skip(1).toList());
  }

  /// Apply a function to each group and combine the results.
  ///
  /// Example:
  /// ```dart
  /// var result = df.groupBy2(['category']).apply((group) =>
  ///   group.head(2)  // Get first 2 rows of each group
  /// );
  /// ```
  DataFrame apply(DataFrame Function(DataFrame) func) {
    List<DataFrame> results = [];
    for (var group in groups.values) {
      results.add(func(group));
    }
    return _concatDataFrames(results);
  }

  /// Transform values within each group.
  ///
  /// Unlike apply(), transform() must return a DataFrame with the same shape
  /// as the input group. The results are aligned with the original DataFrame.
  ///
  /// Example:
  /// ```dart
  /// // Normalize values within each group
  /// var normalized = df.groupBy2(['category']).transform((group) {
  ///   var mean = group['value'].mean();
  ///   var std = group['value'].std();
  ///   // Create new column with normalized values
  ///   var normalizedValues = group['value'].apply((v) => (v - mean) / std).toList();
  ///   var result = group.copy();
  ///   // Add normalized column
  ///   return result;
  /// });
  /// ```
  DataFrame transform(DataFrame Function(DataFrame) func) {
    Map<dynamic, DataFrame> transformed = {};
    for (var entry in groups.entries) {
      var result = func(entry.value);
      if (result.rowCount != entry.value.rowCount) {
        throw ArgumentError(
            'Transform function must return DataFrame with same number of rows. '
            'Expected ${entry.value.rowCount}, got ${result.rowCount}');
      }
      transformed[entry.key] = result;
    }

    // Combine results maintaining original order
    List<DataFrame> orderedResults = [];
    for (var key in groups.keys) {
      orderedResults.add(transformed[key]!);
    }
    return _concatDataFrames(orderedResults);
  }

  /// Filter groups based on a condition.
  ///
  /// Only groups where the function returns true are included in the result.
  ///
  /// Example:
  /// ```dart
  /// // Keep only groups with more than 2 rows
  /// var filtered = df.groupBy2(['category']).filter((group) =>
  ///   group.rowCount > 2
  /// );
  ///
  /// // Keep groups where sum of values > 100
  /// var filtered = df.groupBy2(['category']).filter((group) =>
  ///   group['value'].sum() > 100
  /// );
  /// ```
  DataFrame filter(bool Function(DataFrame) func) {
    List<DataFrame> results = [];
    for (var group in groups.values) {
      if (func(group)) {
        results.add(group);
      }
    }
    return _concatDataFrames(results);
  }

  /// Apply a chainable function to the GroupBy object.
  ///
  /// This enables method chaining and custom operations.
  ///
  /// Example:
  /// ```dart
  /// var result = df.groupBy2(['category'])
  ///   .pipe((gb) => gb.filter((g) => g.rowCount > 1))
  ///   .sum();
  /// ```
  T pipe<T>(T Function(GroupBy) func) {
    return func(this);
  }

  /// Get the nth row from each group.
  ///
  /// Parameters:
  /// - `n`: The index of the row to select (0-based). Negative indices count from the end.
  /// - `dropna`: If true, groups with fewer than n+1 rows are excluded.
  ///
  /// Example:
  /// ```dart
  /// // Get first row of each group
  /// var first = df.groupBy2(['category']).nth(0);
  ///
  /// // Get last row of each group
  /// var last = df.groupBy2(['category']).nth(-1);
  ///
  /// // Get second row of each group
  /// var second = df.groupBy2(['category']).nth(1);
  /// ```
  DataFrame nth(int n, {bool dropna = true}) {
    List<DataFrame> results = [];
    for (var group in groups.values) {
      int index = n;
      if (index < 0) {
        index = group.rowCount + index;
      }

      if (index >= 0 && index < group.rowCount) {
        results.add(group.iloc([index]));
      } else if (!dropna) {
        // Add empty row with same structure
        var emptyRow = List.filled(group.columnCount, null);
        results
            .add(DataFrame([emptyRow], columns: group.columns.cast<String>()));
      }
    }
    return _concatDataFrames(results);
  }

  /// Get the first n rows from each group.
  ///
  /// Example:
  /// ```dart
  /// // Get first 3 rows of each group
  /// var top3 = df.groupBy2(['category']).head(3);
  /// ```
  DataFrame head([int n = 5]) {
    List<DataFrame> results = [];
    for (var group in groups.values) {
      results.add(group.head(n));
    }
    return _concatDataFrames(results);
  }

  /// Get the last n rows from each group.
  ///
  /// Example:
  /// ```dart
  /// // Get last 3 rows of each group
  /// var bottom3 = df.groupBy2(['category']).tail(3);
  /// ```
  DataFrame tail([int n = 5]) {
    List<DataFrame> results = [];
    for (var group in groups.values) {
      results.add(group.tail(n));
    }
    return _concatDataFrames(results);
  }

  /// Cumulative sum within each group.
  ///
  /// Parameters:
  /// - `columns`: Optional list of columns to compute cumsum for. If null, applies to all numeric columns.
  ///
  /// Example:
  /// ```dart
  /// var cumsum = df.groupBy2(['category']).cumsum();
  /// var cumsum = df.groupBy2(['category']).cumsum(['value', 'amount']);
  /// ```
  DataFrame cumsum([List<String>? columns]) {
    return _cumulativeOp('cumsum', columns);
  }

  /// Cumulative product within each group.
  ///
  /// Example:
  /// ```dart
  /// var cumprod = df.groupBy2(['category']).cumprod();
  /// ```
  DataFrame cumprod([List<String>? columns]) {
    return _cumulativeOp('cumprod', columns);
  }

  /// Cumulative maximum within each group.
  ///
  /// Example:
  /// ```dart
  /// var cummax = df.groupBy2(['category']).cummax();
  /// ```
  DataFrame cummax([List<String>? columns]) {
    return _cumulativeOp('cummax', columns);
  }

  /// Cumulative minimum within each group.
  ///
  /// Example:
  /// ```dart
  /// var cummin = df.groupBy2(['category']).cummin();
  /// ```
  DataFrame cummin([List<String>? columns]) {
    return _cumulativeOp('cummin', columns);
  }

  /// Internal method to perform cumulative operations.
  DataFrame _cumulativeOp(String op, List<String>? columns) {
    List<DataFrame> results = [];

    for (var group in groups.values) {
      var targetCols = columns ??
          group.columns
              .where((col) =>
                  !_groupColumns.contains(col) && _isNumericColumn(group, col))
              .toList()
              .cast<String>();

      var result = group.copy();

      for (var col in targetCols) {
        if (!group.columns.contains(col)) {
          throw ArgumentError('Column "$col" not found in group');
        }

        var values = group[col].toList();
        var cumValues = _computeCumulative(values, op);

        // Replace column values with cumulative values
        var colIndex = result.columns.indexOf(col);
        for (int i = 0; i < result.rowCount; i++) {
          result._data[i][colIndex] = cumValues[i];
        }
      }

      results.add(result);
    }

    return _concatDataFrames(results);
  }

  /// Compute cumulative operation on a list of values.
  List<dynamic> _computeCumulative(List<dynamic> values, String op) {
    List<dynamic> result = [];
    dynamic cumValue;

    for (int i = 0; i < values.length; i++) {
      var value = values[i];

      if (value == null) {
        result.add(null);
        continue;
      }

      if (i == 0) {
        cumValue = value;
      } else {
        switch (op) {
          case 'cumsum':
            cumValue = cumValue + value;
            break;
          case 'cumprod':
            cumValue = cumValue * value;
            break;
          case 'cummax':
            cumValue = cumValue > value ? cumValue : value;
            break;
          case 'cummin':
            cumValue = cumValue < value ? cumValue : value;
            break;
        }
      }

      result.add(cumValue);
    }

    return result;
  }

  /// Check if a column contains numeric data.
  bool _isNumericColumn(DataFrame df, String col) {
    var values = df[col].toList();
    return values.any((v) => v is num);
  }

  /// Aggregate using one or more operations.
  ///
  /// Parameters:
  /// - `agg`: Can be:
  ///   - A `String`: single aggregation function name ('sum', 'mean', 'count', etc.)
  ///   - A `List<String>`: multiple aggregation functions
  ///   - A `Map<String, dynamic>`: column-specific aggregations
  ///
  /// Example:
  /// ```dart
  /// // Single aggregation
  /// var result = df.groupBy2(['category']).agg('sum');
  ///
  /// // Multiple aggregations
  /// var result = df.groupBy2(['category']).agg(['sum', 'mean', 'count']);
  ///
  /// // Column-specific aggregations
  /// var result = df.groupBy2(['category']).agg({
  ///   'value': ['sum', 'mean'],
  ///   'amount': 'max',
  ///   'count': 'count'
  /// });
  ///
  /// // Named aggregations
  /// var result = df.groupBy2(['category']).agg({
  ///   'total_value': NamedAgg('value', 'sum'),
  ///   'avg_amount': NamedAgg('amount', 'mean'),
  /// });
  /// ```
  DataFrame agg(dynamic agg) {
    if (agg is String) {
      return _aggSingle(agg);
    } else if (agg is List<String>) {
      return _aggMultiple(agg);
    } else if (agg is Map<String, dynamic>) {
      return _aggMap(agg);
    } else {
      throw ArgumentError(
          'agg must be String, List<String>, or Map<String, dynamic>');
    }
  }

  /// Aggregate with a single function.
  DataFrame _aggSingle(String func) {
    List<List<dynamic>> resultData = [];
    List<dynamic> resultIndex = [];

    for (var entry in groups.entries) {
      var group = entry.value;
      var row = List<dynamic>.from(
          _groupColumns.map((col) => group[col].toList().first));

      for (var col in group.columns) {
        if (!_groupColumns.contains(col)) {
          row.add(_applyAggFunc(group[col].toList(), func));
        }
      }

      resultData.add(row);
      resultIndex.add(entry.key);
    }

    var resultColumns = List<String>.from(_groupColumns);
    resultColumns.addAll(_df.columns
        .where((col) => !_groupColumns.contains(col))
        .cast<String>());

    return DataFrame(resultData, columns: resultColumns, index: resultIndex);
  }

  /// Aggregate with multiple functions.
  DataFrame _aggMultiple(List<String> funcs) {
    List<List<dynamic>> resultData = [];
    List<dynamic> resultIndex = [];
    List<String> resultColumns = List<String>.from(_groupColumns);

    // Build column names
    for (var col in _df.columns) {
      if (!_groupColumns.contains(col)) {
        for (var func in funcs) {
          resultColumns.add('${col}_$func');
        }
      }
    }

    for (var entry in groups.entries) {
      var group = entry.value;
      var row = List<dynamic>.from(
          _groupColumns.map((col) => group[col].toList().first));

      for (var col in group.columns) {
        if (!_groupColumns.contains(col)) {
          for (var func in funcs) {
            row.add(_applyAggFunc(group[col].toList(), func));
          }
        }
      }

      resultData.add(row);
      resultIndex.add(entry.key);
    }

    return DataFrame(resultData, columns: resultColumns, index: resultIndex);
  }

  /// Aggregate with column-specific functions.
  DataFrame _aggMap(Map<String, dynamic> aggMap) {
    List<List<dynamic>> resultData = [];
    List<dynamic> resultIndex = [];
    List<String> resultColumns = List<String>.from(_groupColumns);

    // Check if using named aggregations
    bool hasNamedAgg = aggMap.values.any((v) => v is NamedAgg);

    if (hasNamedAgg) {
      // Named aggregations
      for (var entry in aggMap.entries) {
        resultColumns.add(entry.key);
      }

      for (var entry in groups.entries) {
        var group = entry.value;
        var row = List<dynamic>.from(
            _groupColumns.map((col) => group[col].toList().first));

        for (var aggEntry in aggMap.entries) {
          var namedAgg = aggEntry.value as NamedAgg;
          row.add(
              _applyAggFunc(group[namedAgg.column].toList(), namedAgg.func));
        }

        resultData.add(row);
        resultIndex.add(entry.key);
      }
    } else {
      // Standard column-specific aggregations
      for (var entry in aggMap.entries) {
        var col = entry.key;
        var funcs = entry.value is List ? entry.value : [entry.value];

        for (var func in funcs) {
          resultColumns.add('${col}_$func');
        }
      }

      for (var entry in groups.entries) {
        var group = entry.value;
        var row = List<dynamic>.from(
            _groupColumns.map((col) => group[col].toList().first));

        for (var aggEntry in aggMap.entries) {
          var col = aggEntry.key;
          var funcs =
              aggEntry.value is List ? aggEntry.value : [aggEntry.value];

          for (var func in funcs) {
            row.add(_applyAggFunc(group[col].toList(), func));
          }
        }

        resultData.add(row);
        resultIndex.add(entry.key);
      }
    }

    return DataFrame(resultData, columns: resultColumns, index: resultIndex);
  }

  /// Apply an aggregation function to a list of values.
  dynamic _applyAggFunc(List<dynamic> values, String func) {
    var numericValues =
        values.whereType<num>().map((v) => v as num).toList();

    switch (func) {
      case 'sum':
        return numericValues.isEmpty
            ? 0
            : numericValues.reduce((a, b) => a + b);
      case 'mean':
        return numericValues.isEmpty
            ? null
            : numericValues.reduce((a, b) => a + b) / numericValues.length;
      case 'count':
        return values.length;
      case 'min':
        return numericValues.isEmpty
            ? null
            : numericValues.reduce((a, b) => a < b ? a : b);
      case 'max':
        return numericValues.isEmpty
            ? null
            : numericValues.reduce((a, b) => a > b ? a : b);
      case 'std':
        if (numericValues.isEmpty) return null;
        var mean = numericValues.reduce((a, b) => a + b) / numericValues.length;
        var variance = numericValues
                .map((v) => (v - mean) * (v - mean))
                .reduce((a, b) => a + b) /
            numericValues.length;
        return sqrt(variance);
      case 'var':
        if (numericValues.isEmpty) return null;
        var mean = numericValues.reduce((a, b) => a + b) / numericValues.length;
        return numericValues
                .map((v) => (v - mean) * (v - mean))
                .reduce((a, b) => a + b) /
            numericValues.length;
      case 'first':
        return values.isEmpty ? null : values.first;
      case 'last':
        return values.isEmpty ? null : values.last;
      default:
        throw ArgumentError('Unknown aggregation function: $func');
    }
  }

  /// Convenience method for sum aggregation.
  DataFrame sum() => agg('sum');

  /// Convenience method for mean aggregation.
  DataFrame mean() => agg('mean');

  /// Convenience method for count aggregation.
  DataFrame count() => agg('count');

  /// Convenience method for min aggregation.
  DataFrame min() => agg('min');

  /// Convenience method for max aggregation.
  DataFrame max() => agg('max');

  /// Convenience method for std aggregation.
  DataFrame std() => agg('std');

  /// Convenience method for var aggregation.
  DataFrame var_() => agg('var');

  /// Convenience method for first aggregation.
  DataFrame first() => agg('first');

  /// Convenience method for last aggregation.
  DataFrame last() => agg('last');

  /// Get the number of groups.
  int get ngroups => groups.length;

  /// Get the size of each group.
  DataFrame size() {
    List<List<dynamic>> resultData = [];
    List<dynamic> resultIndex = [];

    for (var entry in groups.entries) {
      var row = List<dynamic>.from(
          _groupColumns.map((col) => entry.value[col].toList().first));
      row.add(entry.value.rowCount);

      resultData.add(row);
      resultIndex.add(entry.key);
    }

    var resultColumns = List<String>.from(_groupColumns);
    resultColumns.add('size');

    return DataFrame(resultData, columns: resultColumns, index: resultIndex);
  }
}

/// A class for named aggregations in groupby operations.
///
/// Example:
/// ```dart
/// var result = df.groupBy2(['category']).agg({
///   'total_sales': NamedAgg('amount', 'sum'),
///   'avg_price': NamedAgg('price', 'mean'),
/// });
/// ```
class NamedAgg {
  final String column;
  final String func;

  NamedAgg(this.column, this.func);
}
