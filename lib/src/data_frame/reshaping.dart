part of 'data_frame.dart';

/// Extension providing advanced data reshaping operations for DataFrame.
///
/// This extension adds pandas-like reshaping functionality including:
/// - Stack and unstack operations for hierarchical indexing
/// - Enhanced melt operations with more flexibility
/// - Additional pivot operations
extension DataFrameReshaping on DataFrame {
  /// Stacks the prescribed level(s) from columns to index.
  ///
  /// Returns a reshaped DataFrame with a multi-level index created by
  /// "stacking" the columns. This is the inverse of unstack.
  ///
  /// Parameters:
  /// - `level`: Level(s) to stack from the columns into the index.
  ///   Can be an int (column index) or String (column name).
  ///   Defaults to -1 (last level).
  /// - `dropna`: Whether to drop rows in the resulting DataFrame/Series
  ///   with missing values. Defaults to true.
  ///
  /// Returns:
  /// A DataFrame with stacked data structure.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2],
  ///   'B': [3, 4],
  ///   'C': [5, 6]
  /// });
  ///
  /// var stacked = df.stack();
  /// // Creates a long-format DataFrame with column names as a new index level
  /// ```
  DataFrame stack({dynamic level = -1, bool dropna = true}) {
    // Get the level to stack
    int stackLevel;
    if (level is int) {
      stackLevel = level < 0 ? _columns.length + level : level;
    } else if (level is String) {
      stackLevel = _columns.indexOf(level);
      if (stackLevel == -1) {
        throw ArgumentError('Column "$level" not found');
      }
    } else {
      throw ArgumentError('Level must be int or String');
    }

    if (stackLevel < 0 || stackLevel >= _columns.length) {
      throw ArgumentError('Level $stackLevel is out of bounds');
    }

    // Create new data structure
    final List<List<dynamic>> newData = [];
    final List<dynamic> newIndex = [];

    // For each row, create multiple rows (one for each column being stacked)
    for (int rowIdx = 0; rowIdx < _data.length; rowIdx++) {
      final originalRow = _data[rowIdx];
      final originalIndex = index[rowIdx];

      for (int colIdx = 0; colIdx < _columns.length; colIdx++) {
        final value = originalRow[colIdx];

        // Skip null values if dropna is true
        if (dropna && (value == null || value == replaceMissingValueWith)) {
          continue;
        }

        // Create new row with original index + column name as multi-level index
        // and the value as the data
        newData.add([originalIndex, _columns[colIdx], value]);
        newIndex.add('${originalIndex}_${_columns[colIdx]}');
      }
    }

    return DataFrame._(
      ['level_0', 'level_1', 'value'],
      newData,
      index: newIndex,
    );
  }

  /// Unstacks the prescribed level(s) from index to columns.
  ///
  /// This is the inverse of stack. It pivots a level of the (multi-level) index
  /// labels to columns.
  ///
  /// Parameters:
  /// - `level`: Level(s) to unstack from the index into columns.
  ///   Defaults to -1 (last level).
  /// - `fillValue`: Value to use when a combination is missing.
  ///
  /// Returns:
  /// A DataFrame with unstacked data structure.
  ///
  /// Example:
  /// ```dart
  /// // Assuming df is a stacked DataFrame
  /// var unstacked = df.unstack();
  /// // Converts back to wide format
  /// ```
  DataFrame unstack({dynamic level = -1, dynamic fillValue}) {
    // This is a simplified implementation
    // In a full implementation, this would handle multi-level indices

    // For now, we'll implement a basic version that works with the stack output
    if (_columns.length != 3 ||
        _columns[0].toString() != 'level_0' ||
        _columns[1].toString() != 'level_1' ||
        _columns[2].toString() != 'value') {
      throw ArgumentError(
          'Unstack currently only works with DataFrames created by stack(). '
          'Expected columns: [level_0, level_1, value]');
    }

    // Get unique values for index and columns
    final indexValues = this['level_0'].unique();
    final columnValues = this['level_1'].unique();

    // Create new column structure
    final newColumns = <dynamic>['index', ...columnValues];
    final newData = <List<dynamic>>[];

    // Create lookup map
    final Map<String, dynamic> valueMap = {};
    for (int i = 0; i < _data.length; i++) {
      final row = _data[i];
      final key = '${row[0]}_${row[1]}';
      valueMap[key] = row[2];
    }

    // Build unstacked data
    for (final indexVal in indexValues) {
      final newRow = <dynamic>[indexVal];
      for (final colVal in columnValues) {
        final key = '${indexVal}_$colVal';
        final value = valueMap[key] ?? fillValue;
        newRow.add(value);
      }
      newData.add(newRow);
    }

    return DataFrame._(newColumns, newData);
  }

  /// Enhanced melt operation with additional flexibility.
  ///
  /// This extends the existing melt functionality with additional options
  /// for more pandas-like behavior.
  ///
  /// Parameters:
  /// - `idVars`: Column(s) to use as identifier variables.
  /// - `valueVars`: Column(s) to unpivot. If not specified, uses all columns
  ///   that are not set as id_vars.
  /// - `varName`: Name to use for the variable column. Defaults to 'variable'.
  /// - `valueName`: Name to use for the value column. Defaults to 'value'.
  /// - `colLevel`: If columns are a MultiIndex then use this level to melt.
  /// - `ignoreIndex`: If True, ignore the original index. If False, the original
  ///   index is retained. Defaults to True.
  ///
  /// Returns:
  /// A DataFrame in long format.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  ///   'C': [7, 8, 9],
  ///   'D': [10, 11, 12]
  /// });
  ///
  /// var melted = df.meltEnhanced(
  ///   idVars: ['A'],
  ///   valueVars: ['B', 'C'],
  ///   varName: 'metric',
  ///   valueName: 'measurement'
  /// );
  /// ```
  DataFrame meltEnhanced({
    List<String>? idVars,
    List<String>? valueVars,
    String varName = 'variable',
    String valueName = 'value',
    int? colLevel,
    bool ignoreIndex = true,
  }) {
    // Use existing melt implementation as base, but with enhanced features
    final actualIdVars = idVars ?? <String>[];

    // Validate input columns
    for (var col in actualIdVars) {
      if (!hasColumn(col)) {
        throw ArgumentError('ID variable column "$col" does not exist');
      }
    }

    // Determine value variables if not specified
    final actualValueVars = valueVars ??
        _columns
            .where((col) => !actualIdVars.contains(col.toString()))
            .map((col) => col.toString())
            .toList();

    for (var col in actualValueVars) {
      if (!hasColumn(col)) {
        throw ArgumentError('Value variable column "$col" does not exist');
      }
    }

    // Create new columns for melted DataFrame
    final newColumns = <dynamic>[...actualIdVars, varName, valueName];
    final newData = <List<dynamic>>[];
    final newIndex = <dynamic>[];

    // Get indices for faster access
    final idIndices = actualIdVars.map((col) => _columns.indexOf(col)).toList();
    final valueIndices =
        actualValueVars.map((col) => _columns.indexOf(col)).toList();

    // Melt the DataFrame
    for (int rowIdx = 0; rowIdx < _data.length; rowIdx++) {
      final row = _data[rowIdx];
      final originalIndex = index[rowIdx];

      // Extract id values
      final idValues = idIndices.map((idx) => row[idx]).toList();

      // Create a new row for each value variable
      for (var i = 0; i < valueIndices.length; i++) {
        final valueIdx = valueIndices[i];
        final variable = actualValueVars[i];
        final value = row[valueIdx];

        final newRow = [...idValues, variable, value];
        newData.add(newRow);

        // Handle index
        if (ignoreIndex) {
          newIndex.add(newIndex.length);
        } else {
          newIndex.add('${originalIndex}_$i');
        }
      }
    }

    return DataFrame._(
      newColumns,
      newData,
      index: ignoreIndex ? List.generate(newData.length, (i) => i) : newIndex,
    );
  }

  /// Creates a wide-format DataFrame from a long-format one.
  ///
  /// This is essentially the inverse of melt, providing a more intuitive
  /// interface for common reshaping operations.
  ///
  /// Parameters:
  /// - `index`: Column to use as the new index.
  /// - `columns`: Column whose values will become the new column names.
  /// - `values`: Column whose values will populate the new DataFrame.
  /// - `aggFunc`: Function to aggregate duplicate entries. If null and
  ///   duplicates exist, will raise an error.
  /// - `fillValue`: Value to use for missing combinations.
  /// - `margins`: Add row/column margins (totals). Defaults to false.
  /// - `marginsName`: Name of the row/column for margins. Defaults to 'All'.
  ///
  /// Returns:
  /// A DataFrame in wide format.
  ///
  /// Example:
  /// ```dart
  /// var longDf = DataFrame.fromRows([
  ///   {'id': 1, 'variable': 'A', 'value': 10},
  ///   {'id': 1, 'variable': 'B', 'value': 20},
  ///   {'id': 2, 'variable': 'A', 'value': 30},
  ///   {'id': 2, 'variable': 'B', 'value': 40},
  /// ]);
  ///
  /// var wide = longDf.widen(
  ///   index: 'id',
  ///   columns: 'variable',
  ///   values: 'value'
  /// );
  /// ```
  DataFrame widen({
    required String index,
    required String columns,
    required String values,
    String? aggFunc,
    dynamic fillValue,
    bool margins = false,
    String marginsName = 'All',
  }) {
    // Validate columns exist
    if (!hasColumn(index) || !hasColumn(columns) || !hasColumn(values)) {
      throw ArgumentError('One or more specified columns do not exist');
    }

    if (aggFunc != null) {
      // Use pivot table for aggregation
      return pivotTable(
        index: index,
        columns: columns,
        values: values,
        aggFunc: aggFunc,
        fillValue: fillValue,
      );
    } else {
      // Use regular pivot for no aggregation
      return pivot(
        index: index,
        columns: columns,
        values: values,
      );
    }
  }

  /// Enhanced pivot table with support for multiple index and column levels.
  ///
  /// Creates a spreadsheet-style pivot table as a DataFrame with advanced
  /// aggregation capabilities and support for multiple grouping levels.
  ///
  /// Parameters:
  /// - `index`: Column name(s) to use for the new DataFrame's index.
  ///   Can be a String or List&lt;String&gt; for multiple levels.
  /// - `columns`: Column name(s) to use for the new DataFrame's columns.
  ///   Can be a String or List&lt;String&gt; for multiple levels.
  /// - `values`: Column name(s) to aggregate. Can be String or List&lt;String&gt;.
  /// - `aggFunc`: Aggregation function(s) to apply. Can be String, Function,
  ///   or Map&lt;String, dynamic&gt; for different functions per column.
  /// - `fillValue`: Value to replace missing entries.
  /// - `margins`: Add row/column margins (totals). Defaults to false.
  /// - `marginsName`: Name for the margins row/column. Defaults to 'All'.
  /// - `observed`: Only show observed values for categorical groupers.
  /// - `sort`: Sort the result by index and columns. Defaults to true.
  ///
  /// Returns:
  /// A DataFrame representing the pivot table.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 'foo', 'B': 'one', 'C': 'small', 'D': 1, 'E': 2},
  ///   {'A': 'foo', 'B': 'one', 'C': 'large', 'D': 2, 'E': 4},
  ///   {'A': 'foo', 'B': 'two', 'C': 'small', 'D': 3, 'E': 6},
  ///   {'A': 'bar', 'B': 'one', 'C': 'large', 'D': 4, 'E': 8},
  /// ]);
  ///
  /// var pivot = df.pivotTableEnhanced(
  ///   index: ['A', 'B'],
  ///   columns: 'C',
  ///   values: ['D', 'E'],
  ///   aggFunc: 'mean',
  ///   margins: true
  /// );
  /// ```
  DataFrame pivotTableEnhanced({
    required dynamic index,
    required dynamic columns,
    required dynamic values,
    dynamic aggFunc = 'mean',
    dynamic fillValue,
    bool margins = false,
    String marginsName = 'All',
    bool observed = false,
    bool sort = true,
  }) {
    // Normalize inputs to lists
    final List<String> indexCols = _normalizeColumnInput(index);
    final List<String> columnCols = _normalizeColumnInput(columns);
    final List<String> valueCols = _normalizeColumnInput(values);

    // Validate all columns exist
    for (final col in [...indexCols, ...columnCols, ...valueCols]) {
      if (!hasColumn(col)) {
        throw ArgumentError('Column "$col" does not exist');
      }
    }

    // For now, use the existing pivotTable for single-level operations
    // This is a simplified implementation - a full version would handle
    // multi-level indices and columns
    if (indexCols.length == 1 &&
        columnCols.length == 1 &&
        valueCols.length == 1) {
      var result = pivotTable(
        index: indexCols.first,
        columns: columnCols.first,
        values: valueCols.first,
        aggFunc: aggFunc.toString(),
        fillValue: fillValue,
      );

      // Add margins if requested
      if (margins) {
        result = _addMargins(result, marginsName, aggFunc.toString());
      }

      return result;
    }

    // For multi-level operations, we'd need more complex logic
    // This is a placeholder for the full implementation
    throw UnimplementedError(
        'Multi-level pivot tables are not yet implemented. '
        'Use single column names for index, columns, and values.');
  }

  /// Transpose the DataFrame.
  ///
  /// Reflects the DataFrame over its main diagonal by writing rows as columns
  /// and vice-versa. The original column names become the new index, and the
  /// original index values become the new column names.
  ///
  /// Parameters:
  /// - `copy`: Whether to copy the underlying data. Defaults to true.
  ///
  /// Returns:
  /// A transposed DataFrame where rows and columns are swapped.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6]
  /// });
  /// // Original:
  /// //    A  B
  /// // 0  1  4
  /// // 1  2  5
  /// // 2  3  6
  ///
  /// var transposed = df.transpose();
  /// // Transposed:
  /// //    0  1  2
  /// // A  1  2  3
  /// // B  4  5  6
  /// ```
  DataFrame transpose({bool copy = true}) {
    if (_data.isEmpty) {
      return DataFrame._([], []);
    }

    // New columns are the original index values (converted to strings)
    final newColumns = <dynamic>[
      for (int i = 0; i < index.length; i++) index[i].toString()
    ];

    // New data: each original column becomes a row
    final newData = <List<dynamic>>[];
    final newIndex = <dynamic>[];

    // Each original column becomes a row in the transposed DataFrame
    for (int colIdx = 0; colIdx < _columns.length; colIdx++) {
      final newRow = <dynamic>[];

      // Add values from this column across all original rows
      for (int rowIdx = 0; rowIdx < _data.length; rowIdx++) {
        final value = _data[rowIdx][colIdx];
        newRow.add(copy ? _copyValue(value) : value);
      }

      newData.add(newRow);
      // Original column names become the new index
      newIndex.add(_columns[colIdx]);
    }

    return DataFrame._(newColumns, newData, index: newIndex);
  }

  /// Helper method to create a deep copy of a value if needed.
  dynamic _copyValue(dynamic value) {
    if (value is List) {
      return List.from(value);
    } else if (value is Map) {
      return Map.from(value);
    } else {
      // For primitive types (int, double, String, bool, null),
      // assignment creates a copy
      return value;
    }
  }

  // Helper methods

  /// Normalizes column input to a list of strings.
  List<String> _normalizeColumnInput(dynamic input) {
    if (input is String) {
      return [input];
    } else if (input is List<String>) {
      return input;
    } else if (input is List) {
      return input.map((e) => e.toString()).toList();
    } else {
      return [input.toString()];
    }
  }

  /// Adds margin totals to a pivot table.
  DataFrame _addMargins(DataFrame df, String marginsName, String aggFunc) {
    // This is a simplified implementation
    // A full implementation would calculate proper margins based on the aggregation function

    final newData = df._data.map((row) => List<dynamic>.from(row)).toList();
    final newColumns = List<dynamic>.from(df._columns);

    // Add row margins (totals for each row)
    for (int i = 0; i < newData.length; i++) {
      final rowValues = newData[i].skip(1).whereType<num>().toList();
      if (rowValues.isNotEmpty) {
        final total = _calculateMarginValue(rowValues, aggFunc);
        newData[i].add(total);
      } else {
        newData[i].add(null);
      }
    }
    newColumns.add(marginsName);

    // Add column margins (totals for each column)
    final marginRow = <dynamic>[marginsName];
    for (int colIdx = 1; colIdx < newColumns.length - 1; colIdx++) {
      final colValues =
          newData.map((row) => row[colIdx]).whereType<num>().toList();
      if (colValues.isNotEmpty) {
        final total = _calculateMarginValue(colValues, aggFunc);
        marginRow.add(total);
      } else {
        marginRow.add(null);
      }
    }

    // Grand total
    final allValues = newData
        .expand((row) => row.skip(1).take(row.length - 2))
        .whereType<num>()
        .toList();
    if (allValues.isNotEmpty) {
      final grandTotal = _calculateMarginValue(allValues, aggFunc);
      marginRow.add(grandTotal);
    } else {
      marginRow.add(null);
    }

    newData.add(marginRow);

    return DataFrame._(newColumns, newData);
  }

  /// Calculates margin values based on aggregation function.
  dynamic _calculateMarginValue(List<num> values, String aggFunc) {
    if (values.isEmpty) return null;

    switch (aggFunc.toLowerCase()) {
      case 'sum':
        return values.reduce((a, b) => a + b);
      case 'mean':
        return values.reduce((a, b) => a + b) / values.length;
      case 'count':
        return values.length;
      case 'min':
        return values.reduce((a, b) => a < b ? a : b);
      case 'max':
        return values.reduce((a, b) => a > b ? a : b);
      default:
        return values.reduce((a, b) => a + b); // Default to sum
    }
  }


}

/// Extension providing enhanced merge and join operations for DataFrame.
///
/// This extension adds advanced merge functionality with support for multiple
/// key columns, different join strategies, and enhanced suffix handling.
extension DataFrameMerging on DataFrame {
  /// Enhanced merge operation with pandas-like functionality.
  ///
  /// Merges DataFrame objects with a database-style join operation with
  /// enhanced features for handling complex merge scenarios.
  ///
  /// Parameters:
  /// - `right`: DataFrame to merge with.
  /// - `how`: Type of merge to be performed. Options:
  ///   - 'left': Use only keys from left frame (SQL: left outer join)
  ///   - 'right': Use only keys from right frame (SQL: right outer join)
  ///   - 'outer': Use union of keys from both frames (SQL: full outer join)
  ///   - 'inner': Use intersection of keys from both frames (SQL: inner join)
  ///   - 'cross': Creates the cartesian product from both frames
  /// - `on`: Column or index level names to join on. Must be found in both DataFrames.
  /// - `leftOn`: Column or index level names to join on in the left DataFrame.
  /// - `rightOn`: Column or index level names to join on in the right DataFrame.
  /// - `leftIndex`: Use the index from the left DataFrame as the join key(s).
  /// - `rightIndex`: Use the index from the right DataFrame as the join key(s).
  /// - `sort`: Sort the join keys lexicographically in the result DataFrame.
  /// - `suffixes`: Suffix to apply to overlapping column names in the left and right side.
  /// - `copy`: If False, avoid copy if possible.
  /// - `indicator`: If True, adds a column to output DataFrame called "_merge"
  ///   with information on the source of each row.
  /// - `validate`: If specified, checks if merge is of specified type.
  ///
  /// Returns:
  /// A merged DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var left = DataFrame.fromMap({
  ///   'key1': ['K0', 'K0', 'K1', 'K2'],
  ///   'key2': ['K0', 'K1', 'K0', 'K1'],
  ///   'A': ['A0', 'A1', 'A2', 'A3'],
  ///   'B': ['B0', 'B1', 'B2', 'B3']
  /// });
  ///
  /// var right = DataFrame.fromMap({
  ///   'key1': ['K0', 'K1', 'K1', 'K2'],
  ///   'key2': ['K0', 'K0', 'K0', 'K0'],
  ///   'C': ['C0', 'C1', 'C2', 'C3'],
  ///   'D': ['D0', 'D1', 'D2', 'D3']
  /// });
  ///
  /// var merged = left.merge(
  ///   right,
  ///   on: ['key1', 'key2'],
  ///   how: 'inner'
  /// );
  /// ```
  DataFrame merge(
    DataFrame right, {
    String how = 'inner',
    dynamic on,
    dynamic leftOn,
    dynamic rightOn,
    bool leftIndex = false,
    bool rightIndex = false,
    bool sort = false,
    List<String> suffixes = const ['_x', '_y'],
    bool copy = true,
    dynamic indicator = false,
    String? validate,
  }) {
    // Handle index-based joins
    if (leftIndex || rightIndex) {
      throw UnimplementedError('Index-based joins are not yet implemented. '
          'Use column-based joins with on, leftOn, or rightOn parameters.');
    }

    // Determine join keys
    List<String> leftKeys;
    List<String> rightKeys;

    if (on != null) {
      if (leftOn != null || rightOn != null) {
        throw ArgumentError(
            'Cannot specify both "on" and "leftOn"/"rightOn" parameters');
      }
      leftKeys = _normalizeColumnInput(on);
      rightKeys = _normalizeColumnInput(on);
    } else if (leftOn != null && rightOn != null) {
      leftKeys = _normalizeColumnInput(leftOn);
      rightKeys = _normalizeColumnInput(rightOn);
    } else {
      throw ArgumentError(
          'Must specify either "on" or both "leftOn" and "rightOn" parameters');
    }

    if (leftKeys.length != rightKeys.length) {
      throw ArgumentError('Length of left_on and right_on must be equal');
    }

    // Validate merge type
    if (validate != null) {
      _validateMerge(leftKeys, rightKeys, right, validate);
    }

    // Perform the merge using core join functionality
    // Perform the merge using existing join functionality
    var result = join(
      right,
      how: how,
      leftOn: leftKeys.length == 1 ? leftKeys.first : leftKeys,
      rightOn: rightKeys.length == 1 ? rightKeys.first : rightKeys,
      suffixes: suffixes,
      indicator: indicator,
    );

    // Sort if requested
    if (sort && leftKeys.isNotEmpty) {
      result.sort(leftKeys.first);
    }

    return result;
  }

   /// Concatenates this DataFrame with one or more other DataFrames along a specified axis.
  ///
  /// This method allows for combining DataFrames either row-wise (stacking vertically)
  /// or column-wise (joining horizontally).
  ///
  /// Parameters:
  /// - `others`: A `List<DataFrame>` to concatenate with the current DataFrame.
  /// - `axis`: An `int` specifying the axis to concatenate along.
  ///   - `0` (default): Row-wise concatenation. Stacks DataFrames vertically.
  ///     Column alignment depends on the `join` parameter.
  ///   - `1`: Column-wise concatenation. Joins DataFrames horizontally.
  ///     Row alignment is based on matching index labels. If `ignoreIndex` is `true`
  ///     for `axis = 1`, alignment is positional, and the resulting index is reset.
  /// - `join`: A `String` indicating how to handle columns/indices on the other axis.
  ///   - `'outer'` (default): Union of columns/indices. Missing values are filled with
  ///     the DataFrame's `replaceMissingValueWith`.
  ///   - `'inner'`: Intersection of columns/indices. Only common columns/indices are kept.
  /// - `ignoreIndex`: A `bool`.
  ///   - If `true` and `axis = 0`: The resulting DataFrame's index will be a new
  ///     default integer index (0, 1, ..., n-1).
  ///   - If `true` and `axis = 1`: The resulting DataFrame's column names will be reset
  ///     to default integer labels (0, 1, ...). Original row indices are attempted to be aligned;
  ///     if alignment is complex or `join` is 'outer' with differing indices, a default integer
  ///     index might result for rows as well.
  ///   Defaults to `false`.
  ///
  /// Returns:
  /// A new `DataFrame` resulting from the concatenation.
  ///
  /// Throws:
  /// - `ArgumentError` if `axis` is not 0 or 1, or if `join` is not 'outer' or 'inner'.
  ///
  /// Example (Row-wise, axis = 0):
  /// ```dart
  /// var df1 = DataFrame.fromMap({'A': [1, 2], 'B': [3, 4]});
  /// var df2 = DataFrame.fromMap({'A': [5, 6], 'B': [7, 8]});
  /// var df3 = DataFrame.fromMap({'B': [9,10], 'C': [11,12]}); // Different columns
  ///
  /// // Outer join (default)
  /// print(df1.concatenate([df2, df3]));
  /// // Output:
  /// //    A  B     C
  /// // 0  1  3  null
  /// // 1  2  4  null
  /// // 2  5  7  null
  /// // 3  6  8  null
  /// // 4 null 9    11
  /// // 5 null 10   12
  ///
  /// // Inner join
  /// print(df1.concatenate([df3], join: 'inner'));
  /// // Output:
  /// //    B
  /// // 0  3
  /// // 1  4
  /// // 2  9
  /// // 3 10
  ///
  /// // Outer join, ignore index
  /// print(df1.concatenate([df2], ignoreIndex: true));
  /// // Output:
  /// //    A  B
  /// // 0  1  3
  /// // 1  2  4
  /// // 2  5  7
  /// // 3  6  8
  /// ```
  /// Example (Column-wise, axis = 1):
  /// ```dart
  /// var dfA = DataFrame.fromMap({'A': [1, 2], 'B': [3, 4]}, index: ['r1', 'r2']);
  /// var dfB = DataFrame.fromMap({'C': [5, 6], 'D': [7, 8]}, index: ['r1', 'r2']); // Same index
  /// var dfC = DataFrame.fromMap({'E': [9,10]}, index: ['r1', 'r3']); // Different index
  ///
  /// print(dfA.concatenate([dfB], axis: 1));
  /// // Output:
  /// //     A  B  C  D
  /// // r1  1  3  5  7
  /// // r2  2  4  6  8
  ///
  /// print(dfA.concatenate([dfC], axis: 1, join: 'outer')); // Outer join aligns on index
  /// // Output:
  /// //      A    B    E
  /// // r1  1.0  3.0  9.0
  /// // r2  2.0  4.0  NaN // or replaceMissingValueWith
  /// // r3  NaN  NaN 10.0
  ///
  /// print(dfA.concatenate([dfC], axis: 1, join: 'inner'));
  /// // Output:
  /// //     A  B  E
  /// // r1  1  3  9
  /// ```
  DataFrame concatenate(List<DataFrame> others,
      {int axis = 0, String join = 'outer', bool ignoreIndex = false}) {
    if (others.isEmpty) {
      return copy(); // Concatenating with nothing returns a copy of itself.
    }

    List<DataFrame> allDfs = [this, ...others];

    if (axis == 0) {
      // Row-wise concatenation
      List<dynamic> finalColumns;
      List<List<dynamic>> finalData = [];

      if (join == 'outer') {
        final Set<dynamic> allColumnSet = {};
        for (var df in allDfs) {
          allColumnSet.addAll(df.columns);
        }
        // Maintain order of first appearance for columns
        finalColumns = <dynamic>[];
        for (var df in allDfs) {
          for (var col in df.columns) {
            if (!finalColumns.contains(col)) {
              finalColumns.add(col);
            }
          }
        }

        for (var df in allDfs) {
          for (var row in df.rows) {
            final newRow = <dynamic>[];
            final dfRowMap = Map.fromIterables(df.columns, row);
            for (var colName in finalColumns) {
              newRow.add(dfRowMap[colName] ?? replaceMissingValueWith);
            }
            finalData.add(newRow);
          }
        }
      } else if (join == 'inner') {
        if (allDfs.isEmpty) return DataFrame([]);
        Set<dynamic> commonColumns = Set.from(allDfs.first.columns);
        for (int i = 1; i < allDfs.length; i++) {
          commonColumns =
              commonColumns.intersection(Set.from(allDfs[i].columns));
        }
        if (commonColumns.isEmpty &&
            allDfs.any((df) => df.columns.isNotEmpty)) {
          // If intersection is empty but some DFs had columns, result is empty columns
          finalColumns = [];
        } else {
          finalColumns = commonColumns.toList();
        }

        for (var df in allDfs) {
          final colIndicesToKeep =
              finalColumns.map((col) => df.columns.indexOf(col)).toList();
          for (var row in df.rows) {
            final newRow = colIndicesToKeep.map((idx) => row[idx]).toList();
            finalData.add(newRow);
          }
        }
      } else {
        throw ArgumentError("join must be 'outer' or 'inner'.");
      }

      // ignore_index for axis 0 resets the row index, which is implicit in our current list-of-lists data model.
      // If a dedicated index object existed, it would be reset here if ignore_index is true.
      // For now, the data is simply concatenated, and default integer indexing applies.
      return DataFrame._(finalColumns, finalData);
    } else if (axis == 1) {
      // Column-wise concatenation
      // This implementation for axis=1 is basic and assumes row alignment by index position.
      // A more robust implementation would require a proper Index object for alignment.

      List<dynamic> finalCombinedColumns = [];
      for (var df in allDfs) {
        finalCombinedColumns
            .addAll(df.columns); // Simple concatenation of column names
      }
      // Handle duplicate column names if not ignoring index for columns
      if (!ignoreIndex) {
        final Map<dynamic, int> colCounts = {};
        List<dynamic> tempCols = List.from(finalCombinedColumns);
        finalCombinedColumns.clear();
        for (var colName in tempCols) {
          int count = colCounts.putIfAbsent(colName, () => 0);
          colCounts[colName] = count + 1;
          if (count > 0) {
            finalCombinedColumns.add("${colName}_$count");
          } else {
            finalCombinedColumns.add(colName);
          }
        }
      }

      List<List<dynamic>> finalData = [];
      int targetRows;
      
      if (join == 'outer') {
        // Outer join: use maximum number of rows
        targetRows = 0;
        for (var df in allDfs) {
          if (df.rowCount > targetRows) {
            targetRows = df.rowCount;
          }
        }
      } else if (join == 'inner') {
        // Inner join: use minimum number of rows
        targetRows = allDfs.isEmpty ? 0 : allDfs.first.rowCount;
        for (var df in allDfs) {
          if (df.rowCount < targetRows) {
            targetRows = df.rowCount;
          }
        }
      } else {
        throw ArgumentError("join must be 'outer' or 'inner'.");
      }

      for (int i = 0; i < targetRows; i++) {
        List<dynamic> newRow = [];
        for (var df in allDfs) {
          if (i < df.rowCount) {
            newRow.addAll(df.rows[i]);
          } else {
            // Fill with missing values for columns of this df (only for outer join)
            newRow.addAll(List.filled(df.columnCount, replaceMissingValueWith));
          }
        }
        finalData.add(newRow);
      }

      if (ignoreIndex) {
        // Reset column names to default integer sequence
        var finalColumns = List.generate(finalCombinedColumns.length, (i) => i);
        return DataFrame._(finalColumns, finalData);
      } else {
        return DataFrame._(finalCombinedColumns, finalData);
      }
    } else {
      throw ArgumentError('axis must be 0 (row-wise) or 1 (column-wise).');
    }
  }


  /// Concatenate DataFrames along a particular axis with optional set logic
  /// along the other axes.
  ///
  /// Can also add a layer of hierarchical indexing on the concatenation axis,
  /// which may be useful if the labels are the same (or overlapping) on
  /// the passed axis number.
  ///
  /// Parameters:
  /// - `others`: List of DataFrames to concatenate.
  /// - `axis`: The axis to concatenate along. 0 for rows, 1 for columns.
  /// - `join`: How to handle indexes on other axis(es). 'outer' or 'inner'.
  /// - `ignoreIndex`: If True, do not use the index values along the concatenation axis.
  /// - `keys`: If passed, construct hierarchical index using the passed keys.
  /// - `levels`: Specific levels (unique values) to use for constructing a MultiIndex.
  /// - `names`: Names for the levels in the resulting hierarchical index.
  /// - `verifyIntegrity`: Check whether the new concatenated axis contains duplicates.
  /// - `sort`: Sort non-concatenation axis if it is not already aligned.
  /// - `copy`: If False, do not copy data unnecessarily.
  ///
  /// Returns:
  /// A concatenated DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var df1 = DataFrame.fromMap({'A': [1, 2], 'B': [3, 4]});
  /// var df2 = DataFrame.fromMap({'A': [5, 6], 'B': [7, 8]});
  /// var df3 = DataFrame.fromMap({'C': [9, 10], 'D': [11, 12]});
  ///
  /// var concatenated = df1.concat([df2, df3], axis: 0);
  /// ```
  DataFrame concat(
    List<DataFrame> others, {
    int axis = 0,
    String join = 'outer',
    bool ignoreIndex = false,
    List<String>? keys,
    List<List<dynamic>>? levels,
    List<String>? names,
    bool verifyIntegrity = false,
    bool sort = false,
    bool copy = true,
  }) {
    // Use existing concatenate method as base
    return concatenate(
      others,
      axis: axis,
      join: join,
      ignoreIndex: ignoreIndex,
    );
  }

  
  /// Compute a cross-tabulation of two factors.
  ///
  /// Parameters:
  ///   - `index`: Row name to use for the rows
  ///   - `column`: Column name to use for the columns
  ///   - `values`: Optional column name to aggregate
  ///   - `aggfunc`: Aggregation function to use ('count', 'sum', 'mean', 'min', 'max')
  ///   - `normalize`: If true or 'all', normalize all values. If 'index', normalize across rows.
  ///                  If 'columns', normalize across columns.
  ///   - `margins`: Add row/column margins (subtotals)
  ///   - `marginsName`: Name of the row/column that will contain the totals
  DataFrame crosstab(
      {required String index,
      required String column,
      String? values,
      String aggfunc = 'count',
      dynamic normalize = false,
      bool margins = false,
      String marginsName = 'All'}) {
    if (!hasColumn(index)) {
      throw ArgumentError('Row column $index does not exist');
    }

    if (!hasColumn(column)) {
      throw ArgumentError('Column column $column does not exist');
    }

    if (values != null && !hasColumn(values)) {
      throw ArgumentError('Values column $values does not exist');
    }

    // Get unique values for rows and columns
    final rowValues = this[index].unique();
    final columnValues = this[column].unique();

    // Create new column names
    final newColumns = <dynamic>[index, ...columnValues];

    // Get indices for faster access
    final rowIdx = _columns.indexOf(index);
    final colIdx = _columns.indexOf(column);
    final valIdx = values != null ? _columns.indexOf(values) : -1;

    // Group data by row and column values
    final grouped = <dynamic, Map<dynamic, List<dynamic>>>{};

    for (var dataRow in _data) {
      final rowValue = dataRow[rowIdx];
      final colValue = dataRow[colIdx];

      if (rowValue == null || colValue == null) continue;

      grouped.putIfAbsent(rowValue, () => {});
      grouped[rowValue]!.putIfAbsent(colValue, () => []);

      if (values != null) {
        grouped[rowValue]![colValue]!.add(dataRow[valIdx]);
      } else {
        grouped[rowValue]![colValue]!.add(1); // For counting
      }
    }

    // Create cross-tabulation data
    final crossTabData = <List<dynamic>>[];
    final rowSums = <dynamic, dynamic>{};
    final colSums = <dynamic, dynamic>{};
    var grandTotal = 0.0;

    // First pass: calculate the raw values and totals
    for (var rowValue in rowValues) {
      final rowData = <dynamic>[rowValue];
      var rowSum = 0.0;

      for (var colValue in columnValues) {
        final cellValues = grouped[rowValue]?[colValue] ?? [];
        dynamic cellValue;

        if (cellValues.isEmpty) {
          cellValue = 0; // Default value for empty cells
        } else {
          // Apply aggregation function
          switch (aggfunc.toLowerCase()) {
            case 'count':
              cellValue = cellValues.length;
              break;

            case 'sum':
              if (cellValues.every((v) => v is num)) {
                cellValue =
                    cellValues.fold<num>(0, (prev, val) => prev + (val as num));
              } else {
                cellValue = null;
              }
              break;

            case 'mean':
              if (cellValues.every((v) => v is num)) {
                final sum =
                    cellValues.fold<num>(0, (prev, val) => prev + (val as num));
                cellValue = sum / cellValues.length;
              } else {
                cellValue = null;
              }
              break;

            case 'min':
              if (cellValues.every((v) => v is num)) {
                cellValue =
                    cellValues.cast<num>().reduce((a, b) => a < b ? a : b);
              } else if (cellValues.isNotEmpty) {
                cellValue = cellValues.reduce(
                    (a, b) => a.toString().compareTo(b.toString()) < 0 ? a : b);
              } else {
                cellValue = null;
              }
              break;

            case 'max':
              if (cellValues.every((v) => v is num)) {
                cellValue =
                    cellValues.cast<num>().reduce((a, b) => a > b ? a : b);
              } else if (cellValues.isNotEmpty) {
                cellValue = cellValues.reduce(
                    (a, b) => a.toString().compareTo(b.toString()) > 0 ? a : b);
              } else {
                cellValue = null;
              }
              break;

            default:
              throw ArgumentError('Unsupported aggregation function: $aggfunc');
          }
        }

        rowData.add(cellValue);

        // Update row and column sums
        if (cellValue is num) {
          rowSum += cellValue;
          colSums[colValue] = (colSums[colValue] ?? 0.0) + cellValue;
          grandTotal += cellValue;
        }
      }

      rowSums[rowValue] = rowSum;
      crossTabData.add(rowData);
    }

    // Store the raw data before normalization for margin calculations
    crossTabData.map((row) => List<dynamic>.from(row)).toList();
    final rawRowSums = Map<dynamic, dynamic>.from(rowSums);
    final rawColSums = Map<dynamic, dynamic>.from(colSums);
    final rawGrandTotal = grandTotal;

    // Apply normalization if requested
    if (normalize != false) {
      String normType = normalize is bool ? 'all' : normalize.toString();

      for (var i = 0; i < crossTabData.length; i++) {
        final rowValue = crossTabData[i][0];

        for (var j = 1; j < crossTabData[i].length; j++) {
          if (crossTabData[i][j] is num) {
            double divisor = 1.0;

            switch (normType) {
              case 'all':
                divisor = rawGrandTotal;
                break;
              case 'index':
                divisor = rawRowSums[rowValue] ?? 1.0;
                break;
              case 'columns':
                final colValue = newColumns[j];
                divisor = rawColSums[colValue] ?? 1.0;
                break;
            }

            if (divisor != 0) {
              crossTabData[i][j] = (crossTabData[i][j] as num) / divisor;
            } else {
              crossTabData[i][j] = 0.0;
            }
          }
        }
      }
    }

    // Add margins if requested
    if (margins) {
      // Add row totals column
      newColumns.add(marginsName);

      for (var i = 0; i < crossTabData.length; i++) {
        if (normalize == 'index') {
          // For index normalization, row sum should be 1.0
          crossTabData[i].add(1.0);
        } else if (normalize == 'columns') {
          // For column normalization, calculate the sum of normalized values
          double sum = 0.0;
          for (var j = 1; j < crossTabData[i].length; j++) {
            if (crossTabData[i][j] is num) {
              sum += crossTabData[i][j];
            }
          }
          crossTabData[i].add(sum);
        } else if (normalize == true || normalize == 'all') {
          // For all normalization, calculate the sum of normalized values
          double sum = 0.0;
          for (var j = 1; j < crossTabData[i].length; j++) {
            if (crossTabData[i][j] is num) {
              sum += crossTabData[i][j];
            }
          }
          crossTabData[i].add(sum);
        } else {
          // For no normalization, use the raw row sum
          crossTabData[i].add(rawRowSums[crossTabData[i][0]] ?? 0.0);
        }
      }

      // Add column totals row
      final totalRow = <dynamic>[marginsName];

      for (var j = 1; j < newColumns.length; j++) {
        if (j == newColumns.length - 1) {
          // Last column is the grand total
          if (normalize == 'index') {
            // For index normalization, sum of row sums (each 1.0)
            totalRow.add(crossTabData.length.toDouble());
          } else if (normalize == 'columns') {
            // For column normalization, sum of column sums (each 1.0)
            totalRow.add(columnValues.length.toDouble());
          } else if (normalize == true || normalize == 'all') {
            // For all normalization, sum should be 1.0
            totalRow.add(1.0);
          } else {
            // For no normalization, use the raw grand total
            totalRow.add(rawGrandTotal);
          }
        } else {
          final colValue = newColumns[j];

          if (normalize == 'index') {
            // For index normalization, calculate the sum of normalized values
            double sum = 0.0;
            for (var i = 0; i < crossTabData.length; i++) {
              if (crossTabData[i][j] is num) {
                sum += crossTabData[i][j];
              }
            }
            totalRow.add(sum);
          } else if (normalize == 'columns') {
            // For column normalization, column sum should be 1.0
            totalRow.add(1.0);
          } else if (normalize == true || normalize == 'all') {
            // For all normalization, calculate the sum of normalized values
            double sum = 0.0;
            for (var i = 0; i < crossTabData.length; i++) {
              if (crossTabData[i][j] is num) {
                sum += crossTabData[i][j];
              }
            }
            totalRow.add(sum);
          } else {
            // For no normalization, use the raw column sum
            totalRow.add(rawColSums[colValue] ?? 0.0);
          }
        }
      }

      crossTabData.add(totalRow);
    }

    return DataFrame._(newColumns, crossTabData);
  }

  
  /// Reshapes the DataFrame based on column values.
  ///
  /// This function is used for strict reshaping without aggregation.
  /// If there are duplicate entries for an `index` and `columns` pair,
  /// it will raise an `ArgumentError`.
  ///
  /// Parameters:
  ///   - `index`: Column name to use as the new DataFrame's index.
  ///   - `columns`: Column name whose unique values will form the new DataFrame's columns.
  ///   - `values`: Column name whose values will populate the new DataFrame.
  ///             If null, and there are multiple remaining columns, this might be ambiguous
  ///             or require hierarchical columns (currently requires `values` to be specified).
  ///
  /// Returns a new, reshaped DataFrame.
  DataFrame pivot(
      {required String index, required String columns, String? values}) {
    if (!hasColumn(index) || !hasColumn(columns)) {
      throw ArgumentError('Index or columns column not found in DataFrame.');
    }
    String valueCol = values ?? '';

    if (values != null) {
      if (!hasColumn(values)) {
        throw ArgumentError('Values column $values not found in DataFrame.');
      }
    } else {
      List<String> remainingCols = _columns
          .map((c) => c.toString())
          .where((c) => c != index && c != columns)
          .toList();
      if (remainingCols.isEmpty) {
        throw ArgumentError(
            'No values columns found to pivot. Specify `values` or ensure other columns exist.');
      }
      if (remainingCols.length > 1) {
        print(
            'Warning: Multiple value columns found and `values` parameter is null. Using first remaining column: ${remainingCols.first}');
        valueCol = remainingCols.first;
      } else {
        valueCol = remainingCols.first;
      }
    }

    final indexValues = this[index].unique()
      ..sort((a, b) => (a as Comparable).compareTo(b as Comparable));
    final columnValues = this[columns].unique()
      ..sort((a, b) => (a as Comparable).compareTo(b as Comparable));

    final newColumns = <dynamic>[index, ...columnValues];
    final pivotData = <List<dynamic>>[];

    final indexIdx = _columns.indexOf(index);
    final columnsIdx = _columns.indexOf(columns);
    final valuesIdx = _columns.indexOf(valueCol);

    // Check for duplicates
    final Set<String> uniqueIndexColumnPairs = {};
    for (var row in _data) {
      String pairKey = "${row[indexIdx]}_${row[columnsIdx]}";
      if (uniqueIndexColumnPairs.contains(pairKey)) {
        throw ArgumentError(
            "Index contains duplicate entries for index '${row[indexIdx]}' and columns '${row[columnsIdx]}', cannot reshape without aggregation. Use pivot_table instead.");
      }
      uniqueIndexColumnPairs.add(pairKey);
    }

    // Create a map for quick lookup: {indexValue: {columnValue: value}}
    final Map<dynamic, Map<dynamic, dynamic>> dataMap = {};
    for (var row in _data) {
      dataMap.putIfAbsent(row[indexIdx], () => {})[row[columnsIdx]] =
          row[valuesIdx];
    }

    for (var indexVal in indexValues) {
      final rowData = <dynamic>[indexVal];
      for (var columnVal in columnValues) {
        rowData.add(dataMap[indexVal]?[columnVal]); // Will add null if no value
      }
      pivotData.add(rowData);
    }

    return DataFrame._(newColumns, pivotData);
  }

  /// Converts the DataFrame from wide to long format.
  ///
  /// Parameters:
  ///   - `idVars`: Columns to use as identifier variables
  ///   - `valueVars`: Columns to unpivot
  ///   - `varName`: Name for the variable column
  ///   - `valueName`: Name for the value column
  DataFrame melt(
      {required List<String> idVars,
      List<String>? valueVars,
      String varName = 'variable',
      String valueName = 'value'}) {
    // Validate input columns
    for (var col in idVars) {
      if (!hasColumn(col)) {
        throw ArgumentError('Column $col does not exist');
      }
    }

    // Determine value variables if not specified
    final actualValueVars = valueVars ??
        _columns
            .where((col) => !idVars.contains(col))
            .map((col) => col.toString())
            .toList();

    for (var col in actualValueVars) {
      if (!hasColumn(col)) {
        throw ArgumentError('Column $col does not exist');
      }
    }

    // Create new columns for melted DataFrame
    final newColumns = <dynamic>[...idVars, varName, valueName];
    final newData = <List<dynamic>>[];

    // Get indices for faster access
    final idIndices = idVars.map((col) => _columns.indexOf(col)).toList();
    final valueIndices =
        actualValueVars.map((col) => _columns.indexOf(col)).toList();

    // Melt the DataFrame
    for (var row in _data) {
      // Extract id values
      final idValues = idIndices.map((idx) => row[idx]).toList();

      // Create a new row for each value variable
      for (var i = 0; i < valueIndices.length; i++) {
        final valueIdx = valueIndices[i];
        final variable = actualValueVars[i];
        final value = row[valueIdx];

        final newRow = [...idValues, variable, value];
        newData.add(newRow);
      }
    }

    return DataFrame._(newColumns, newData);
  }

  /// Creates a pivot table from the DataFrame, allowing aggregation.
  ///
  /// Parameters:
  ///   - `index`: Column name to use for the new DataFrame's index.
  ///   - `columns`: Column name to use for the new DataFrame's columns.
  ///   - `values`: Column name to aggregate.
  ///   - `aggFunc`: Aggregation function to apply. Supported: 'mean', 'sum', 'count', 'min', 'max'. Default is 'mean'.
  ///   - `fill_value`: Value to replace missing cells in the pivot table after aggregation.
  DataFrame pivotTable(
      {required String index,
      required String columns,
      required String values,
      String aggFunc = 'mean',
      dynamic fillValue}) {
    if (!hasColumn(index) || !hasColumn(columns) || !hasColumn(values)) {
      throw ArgumentError(
          'Index, columns, or values column not found in DataFrame');
    }

    // Get unique values for index and columns
    final indexValues = this[index].unique();
    final columnValues = this[columns].unique();

    // Create new column names
    final newColumns = <dynamic>[index, ...columnValues];

    // Group data by index and columns
    final grouped = <dynamic, Map<dynamic, List<dynamic>>>{};

    final indexIdx = _columns.indexOf(index);
    final columnsIdx = _columns.indexOf(columns);
    final valuesIdx = _columns.indexOf(values);

    for (var row in _data) {
      final indexVal = row[indexIdx];
      final columnVal = row[columnsIdx];
      final value = row[valuesIdx];

      if (value == null) continue;

      grouped.putIfAbsent(indexVal, () => {});
      grouped[indexVal]!.putIfAbsent(columnVal, () => []);
      grouped[indexVal]![columnVal]!.add(value);
    }

    // Apply aggregation function and create pivot table
    final pivotData = <List<dynamic>>[];

    for (var indexVal in indexValues) {
      final rowData = <dynamic>[indexVal];

      for (var columnVal in columnValues) {
        final values = grouped[indexVal]?[columnVal] ?? [];

        dynamic aggResult;
        if (values.isEmpty) {
          aggResult = null;
        } else {
          // Apply aggregation function
          switch (aggFunc.toLowerCase()) {
            case 'mean':
              if (values.every((v) => v is num)) {
                final sum =
                    values.fold<num>(0, (prev, val) => prev + (val as num));
                aggResult = sum / values.length;
              } else {
                aggResult = null;
              }
              break;
            case 'sum':
              if (values.every((v) => v is num)) {
                final sum =
                    values.fold<num>(0, (prev, val) => prev + (val as num));
                aggResult = sum;
              } else {
                aggResult = null;
              }
              break;
            case 'count':
              aggResult = values.length;
              break;
            case 'min':
              if (values.every((v) => v is num)) {
                aggResult = values.cast<num>().reduce(min);
              } else {
                // Attempt to find min for non-numeric comparable types
                try {
                  aggResult = values.reduce((a, b) =>
                      (a as Comparable).compareTo(b as Comparable) < 0 ? a : b);
                } catch (e) {
                  aggResult = null;
                }
              }
              break;
            case 'max':
              if (values.every((v) => v is num)) {
                aggResult = values.cast<num>().reduce(max);
              } else {
                try {
                  aggResult = values.reduce((a, b) =>
                      (a as Comparable).compareTo(b as Comparable) > 0 ? a : b);
                } catch (e) {
                  aggResult = null;
                }
              }
              break;
            default:
              throw ArgumentError('Unsupported aggregation function: $aggFunc');
          }
        }
        rowData.add(aggResult);
      }
      pivotData.add(rowData);
    }

    // Apply fill_value
    if (fillValue != null) {
      for (int i = 0; i < pivotData.length; i++) {
        for (int j = 1; j < pivotData[i].length; j++) {
          // Start from j=1 to skip the index column
          if (pivotData[i][j] == null) {
            pivotData[i][j] = fillValue;
          }
        }
      }
    }

    return DataFrame._(newColumns, pivotData);
  }

  /// Merge DataFrame objects by performing a database-style join operation
  /// by columns or indexes.
  ///
  /// If joining columns on columns, the DataFrame indexes will be ignored.
  /// Otherwise if joining indexes on indexes or indexes on a column or columns,
  /// the index will be passed on.
  ///
  /// Parameters:
  /// - `other`: DataFrame to join with.
  /// - `on`: Column or index level names to join on.
  /// - `how`: How to handle the operation of the two objects.
  /// - `lsuffix`: Suffix to use from left frame's overlapping columns.
  /// - `rsuffix`: Suffix to use from right frame's overlapping columns.
  /// - `sort`: Order result DataFrame lexicographically by the join key.
  ///
  /// Returns:
  /// A joined DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var left = DataFrame.fromMap({
  ///   'A': ['A0', 'A1', 'A2'],
  ///   'B': ['B0', 'B1', 'B2']
  /// }, index: ['K0', 'K1', 'K2']);
  ///
  /// var right = DataFrame.fromMap({
  ///   'C': ['C0', 'C2', 'C3'],
  ///   'D': ['D0', 'D2', 'D3']
  /// }, index: ['K0', 'K2', 'K3']);
  ///
  /// var joined = left.joinEnhanced(right, how: 'outer');
  /// ```
  DataFrame joinEnhanced(
    DataFrame other, {
    dynamic on,
    String how = 'left',
    String? lsuffix,
    String? rsuffix,
    bool sort = false,
  }) {
    // Determine suffixes
    final suffixes = [
      lsuffix ?? '_x',
      rsuffix ?? '_y',
    ];

    // Use existing join method
    var result = join(
      other,
      on: on,
      how: how,
      suffixes: suffixes,
    );

    // Sort if requested
    if (sort && on != null) {
      final sortKey = on is String ? on : (on as List).first.toString();
      if (result.hasColumn(sortKey)) {
        result.sort(sortKey);
      }
    }

    return result;
  }

  /// Perform an asof merge.
  ///
  /// This is similar to a left-join except that we match on nearest key
  /// rather than equal keys. Both DataFrames must be sorted by the key.
  ///
  /// Parameters:
  /// - `right`: DataFrame to merge with.
  /// - `on`: Column name to join on. Must be found in both DataFrames.
  /// - `leftOn`: Column name to join on in left DataFrame.
  /// - `rightOn`: Column name to join on in right DataFrame.
  /// - `by`: Match on these columns before performing merge operation.
  /// - `leftBy`: Match on these columns before performing merge operation in left DataFrame.
  /// - `rightBy`: Match on these columns before performing merge operation in right DataFrame.
  /// - `suffixes`: Suffix to apply to overlapping column names.
  /// - `tolerance`: Select asof tolerance within this range.
  /// - `allowExactMatches`: If True, allow matching with the same 'on' value.
  /// - `direction`: Whether to search for prior, subsequent, or closest matches.
  ///
  /// Returns:
  /// A merged DataFrame.
  ///
  /// Note: This is a simplified implementation. A full asof merge would require
  /// more sophisticated nearest-neighbor matching logic.
  DataFrame mergeAsof(
    DataFrame right, {
    String? on,
    String? leftOn,
    String? rightOn,
    dynamic by,
    dynamic leftBy,
    dynamic rightBy,
    List<String> suffixes = const ['_x', '_y'],
    dynamic tolerance,
    bool allowExactMatches = true,
    String direction = 'backward',
  }) {
    throw UnimplementedError('Asof merge is not yet implemented. '
        'This requires sophisticated nearest-neighbor matching logic.');
  }

  // Helper methods

  /// Validates merge operation based on specified validation type.
  void _validateMerge(
    List<String> leftKeys,
    List<String> rightKeys,
    DataFrame right,
    String validate,
  ) {
    switch (validate.toLowerCase()) {
      case 'one_to_one':
      case '1:1':
        _validateOneToOne(leftKeys, rightKeys, right);
        break;
      case 'one_to_many':
      case '1:m':
        _validateOneToMany(leftKeys);
        break;
      case 'many_to_one':
      case 'm:1':
        _validateManyToOne(rightKeys, right);
        break;
      case 'many_to_many':
      case 'm:m':
        // No validation needed for many-to-many
        break;
      default:
        throw ArgumentError('Invalid validation type: $validate');
    }
  }

  /// Validates one-to-one merge.
  void _validateOneToOne(
    List<String> leftKeys,
    List<String> rightKeys,
    DataFrame right,
  ) {
    // Check for duplicates in left keys
    final leftKeyValues = <String, int>{};
    for (final row in _data) {
      final keyStr = leftKeys.map((key) {
        final idx = _columns.indexOf(key);
        return row[idx].toString();
      }).join('|');

      leftKeyValues[keyStr] = (leftKeyValues[keyStr] ?? 0) + 1;
      if (leftKeyValues[keyStr]! > 1) {
        throw ArgumentError('Merge keys are not unique in left DataFrame');
      }
    }

    // Check for duplicates in right keys
    final rightKeyValues = <String, int>{};
    for (final row in right._data) {
      final keyStr = rightKeys.map((key) {
        final idx = right._columns.indexOf(key);
        return row[idx].toString();
      }).join('|');

      rightKeyValues[keyStr] = (rightKeyValues[keyStr] ?? 0) + 1;
      if (rightKeyValues[keyStr]! > 1) {
        throw ArgumentError('Merge keys are not unique in right DataFrame');
      }
    }
  }

  /// Validates one-to-many merge.
  void _validateOneToMany(List<String> leftKeys) {
    final leftKeyValues = <String, int>{};
    for (final row in _data) {
      final keyStr = leftKeys.map((key) {
        final idx = _columns.indexOf(key);
        return row[idx].toString();
      }).join('|');

      leftKeyValues[keyStr] = (leftKeyValues[keyStr] ?? 0) + 1;
      if (leftKeyValues[keyStr]! > 1) {
        throw ArgumentError('Merge keys are not unique in left DataFrame');
      }
    }
  }

  /// Validates many-to-one merge.
  void _validateManyToOne(List<String> rightKeys, DataFrame right) {
    final rightKeyValues = <String, int>{};
    for (final row in right._data) {
      final keyStr = rightKeys.map((key) {
        final idx = right._columns.indexOf(key);
        return row[idx].toString();
      }).join('|');

      rightKeyValues[keyStr] = (rightKeyValues[keyStr] ?? 0) + 1;
      if (rightKeyValues[keyStr]! > 1) {
        throw ArgumentError('Merge keys are not unique in right DataFrame');
      }
    }
  }
}
