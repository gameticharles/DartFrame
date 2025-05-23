part of '../../dartframe.dart';

extension DataFrameFunctions on DataFrame {
  /// Selects columns from the DataFrame by their names.
  ///
  /// Returns a new DataFrame containing only the selected columns.
  DataFrame select(List<String> columnNames) {
    final indices = columnNames.map((name) => _columns.indexOf(name)).toList();
    final selectedData = indices.map((index) => _data[index]).toList();
    return DataFrame._(columnNames, selectedData);
  }

  /// Selects columns from the DataFrame by their indices.
  ///
  /// Returns a new DataFrame containing only the selected columns.
  DataFrame selectByIndex(List<int> columnIndices) {
    final selectedColumnNames =
        columnIndices.map((index) => _columns[index]).toList();
    final selectedData = _data
        .map((row) => columnIndices.map((index) => row[index]).toList())
        .toList();
    return DataFrame._(selectedColumnNames, selectedData);
  }

  /// Selects rows from the DataFrame by their indices.
  ///
  /// Returns a new DataFrame containing only the selected rows.
  DataFrame selectRowsByIndex(List<int> rowIndices) {
    final selectedData = rowIndices.map((index) => _data[index]).toList();
    return DataFrame._(_columns, selectedData);
  }

  /// Filters rows from the DataFrame based on a condition.
  ///
  /// The condition is specified as a function that takes a map representing a row
  /// and returns a boolean indicating whether to keep the row.
  DataFrame filter(bool Function(Map<dynamic, dynamic>) condition) {
    final filteredData = _data
        .map((row) {
          final rowMap = Map.fromIterables(_columns, row);
          return condition(rowMap) ? row : null;
        })
        .where((row) => row != null)
        .toList();
    return DataFrame._(_columns, filteredData);
  }

  /// Sorts the DataFrame based on a column.
  ///
  /// By default, the sorting is done in ascending order.
  void sort(String column, {bool ascending = true}) {
    final columnIndex = _columns.indexOf(column);
    if (columnIndex == -1) throw ArgumentError('Column does not exist.');
    _data.sort((a, b) {
      final aValue = a[columnIndex];
      final bValue = b[columnIndex];
      if (aValue == null || bValue == null) {
        return 0; // Could handle nulls differently depending on requirements
      }
      return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });
  }

  /// Returns the first `n` rows of the DataFrame.
  DataFrame head(int n) {
    final headData = _data.take(n).toList();
    return DataFrame._(_columns, headData);
  }

  /// Returns the last `n` rows of the DataFrame.
  DataFrame tail(int n) {
    final tailData = _data.skip(_data.length - n).toList();
    return DataFrame._(_columns, tailData);
  }

  /// Returns a DataFrame of the same shape with boolean values indicating whether each element is missing.
  ///
  /// A value is considered missing if it is null or matches the DataFrame's replaceMissingValueWith value.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': null},
  ///   {'A': null, 'B': 'x'},
  /// ]);
  /// var result = df.isna();
  /// // result contains:
  /// // A     B
  /// // false true
  /// // true  false
  /// ```
  DataFrame isna() {
    List<List<dynamic>> newData = [];
    
    for (int i = 0; i < _data.length; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < _columns.length; j++) {
        // Check if the value is null or matches the replaceMissingValueWith
        bool isMissing = _data[i][j] == null || _data[i][j] == replaceMissingValueWith;
        row.add(isMissing);
      }
      newData.add(row);
    }
    
    return DataFrame(
      newData,
      columns: _columns,
      index: index,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Returns a DataFrame of the same shape with boolean values indicating whether each element is not missing.
  ///
  /// A value is considered not missing if it is not null and doesn't match the DataFrame's replaceMissingValueWith value.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': null},
  ///   {'A': null, 'B': 'x'},
  /// ]);
  /// var result = df.notna();
  /// // result contains:
  /// // A     B
  /// // true  false
  /// // false true
  /// ```
  DataFrame notna() {
    List<List<dynamic>> newData = [];
    
    for (int i = 0; i < _data.length; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < _columns.length; j++) {
        // Check if the value is not null and doesn't match the replaceMissingValueWith
        bool isNotMissing = _data[i][j] != null && _data[i][j] != replaceMissingValueWith;
        row.add(isNotMissing);
      }
      newData.add(row);
    }
    
    return DataFrame(
      newData,
      columns: _columns,
      index: index,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Fills missing values in the DataFrame with the specified value or strategy.
  ///
  /// Parameters:
  ///   - `value`: The value to use for filling missing values. Can be a constant value
  ///     or a strategy string ('mean', 'median', 'mode', 'forward', 'backward').
  ///   - `columns`: Optional list of column names to fill. If null, fills all columns.
  DataFrame fillna(dynamic value, {List<String>? columns}) {
    final columnsToFill = columns ?? _columns.map((c) => c.toString()).toList();
    final columnIndices =
        columnsToFill.map((col) => _columns.indexOf(col)).toList();

    // Check if any specified column doesn't exist
    if (columnIndices.contains(-1)) {
      final missingCol = columnsToFill[columnIndices.indexOf(-1)];
      throw ArgumentError('Column $missingCol does not exist');
    }

    // Create a copy of the data
    final newData = _data.map((row) => List<dynamic>.from(row)).toList();

    // Apply fill strategy for each column
    for (var colIdx in columnIndices) {
      final columnData = _data.map((row) => row[colIdx]).toList();

      // Determine fill value based on strategy
      dynamic fillValue = value;

      // Only process as a strategy if it's one of the known strategy strings
      if (value is String &&
          ['mean', 'median', 'mode', 'forward', 'backward']
              .contains(value.toLowerCase())) {
        switch (value.toLowerCase()) {
          case 'mean':
            final numValues = columnData.whereType<num>().toList();
            if (numValues.isEmpty) continue;
            fillValue = numValues.reduce((a, b) => a + b) / numValues.length;
            break;

          case 'median':
            final numValues = columnData.whereType<num>().toList()..sort();
            if (numValues.isEmpty) continue;
            final middle = numValues.length ~/ 2;
            fillValue = numValues.length.isOdd
                ? numValues[middle]
                : (numValues[middle - 1] + numValues[middle]) / 2;
            break;

          case 'mode':
            final valueCount = <dynamic, int>{};
            for (var val in columnData.where((v) => v != null)) {
              valueCount[val] = (valueCount[val] ?? 0) + 1;
            }
            if (valueCount.isEmpty) continue;

            int maxCount = 0;
            dynamic mostCommon;
            valueCount.forEach((val, count) {
              if (count > maxCount) {
                maxCount = count;
                mostCommon = val;
              }
            });
            fillValue = mostCommon;
            break;

          case 'forward':
            // Forward fill (propagate last valid observation forward)
            dynamic lastValid;
            for (var i = 0; i < newData.length; i++) {
              if (newData[i][colIdx] != null) {
                lastValid = newData[i][colIdx];
              } else if (lastValid != null) {
                newData[i][colIdx] = lastValid;
              }
            }
            continue; // Skip the regular fill below

          case 'backward':
            // Backward fill (propagate next valid observation backward)
            dynamic nextValid;
            for (var i = newData.length - 1; i >= 0; i--) {
              if (newData[i][colIdx] != null) {
                nextValid = newData[i][colIdx];
              } else if (nextValid != null) {
                newData[i][colIdx] = nextValid;
              }
            }
            continue; // Skip the regular fill below
        }
      }

      // Apply the fill value
      for (var i = 0; i < newData.length; i++) {
        // Replace values that match the DataFrame's current missing value representation
        if (newData[i][colIdx] == replaceMissingValueWith) {
          newData[i][colIdx] = fillValue;
        }
      }
    }

    return DataFrame._(_columns, newData);
  }

  /// Removes rows or columns with missing values.
  ///
  /// Parameters:
  ///   - `axis`: 0 to drop rows, 1 to drop columns
  ///   - `how`: 'any' to drop if any value is missing, 'all' to drop only if all values are missing
  ///   - `subset`: Optional list of column names to consider when dropping rows
  DataFrame dropna({int axis = 0, String how = 'any', List<String>? subset}) {
    if (axis == 0) {
      // Drop rows with missing values
      final subsetIndices = subset != null
          ? subset.map((col) => _columns.indexOf(col)).toList()
          : List.generate(_columns.length, (i) => i);

      // Check if any specified column doesn't exist
      if (subsetIndices.contains(-1)) {
        final missingCol = subset![subsetIndices.indexOf(-1)];
        throw ArgumentError('Column $missingCol does not exist');
      }

      final newData = <List<dynamic>>[];

      for (var row in _data) {
        final subsetValues = subsetIndices.map((i) => row[i]).toList();
        // Check against the DataFrame's current missing value representation
        final nullCount = subsetValues.where((v) => v == replaceMissingValueWith).length;

        bool shouldKeep = how == 'any'
            ? nullCount == 0 // Keep if no nulls for 'any'
            : nullCount <
                subsetValues.length; // Keep if not all nulls for 'all'

        if (shouldKeep) {
          newData.add(List<dynamic>.from(row));
        }
      }

      return DataFrame._(_columns, newData);
    } else {
      // Drop columns with missing values
      final newColumns = <dynamic>[];
      final newData = List.generate(_data.length, (_) => <dynamic>[]);

      for (var colIdx = 0; colIdx < _columns.length; colIdx++) {
        final columnData = _data.map((row) => row[colIdx]).toList();
        // Check against the DataFrame's current missing value representation
        final nullCount = columnData.where((v) => v == replaceMissingValueWith).length;

        bool shouldKeep = how == 'any'
            ? nullCount == 0 // Keep if no nulls for 'any'
            : nullCount < columnData.length; // Keep if not all nulls for 'all'

        if (shouldKeep) {
          newColumns.add(_columns[colIdx]);
          for (var rowIdx = 0; rowIdx < _data.length; rowIdx++) {
            newData[rowIdx].add(_data[rowIdx][colIdx]);
          }
        }
      }

      return DataFrame._(newColumns, newData);
    }
  }

  /// Replaces occurrences of old value with new value in all columns of the DataFrame.
  ///
  /// - If [matchCase] is true, replacements are case-sensitive.
  ///
  /// Note: This method modifies the DataFrame in place.
  void replaceInPlace(dynamic oldValue, dynamic newValue,
      {bool matchCase = true}) {
    for (var row in _data) {
      for (var i = 0; i < row.length; i++) {
        if (matchCase) {
          if (row[i] == oldValue) {
            row[i] = newValue;
          }
        } else {
          if (row[i].toString().toLowerCase() ==
              oldValue.toString().toLowerCase()) {
            row[i] = newValue;
          }
        }
      }
    }
  }

  /// Replaces values throughout the DataFrame.
  ///
  /// Parameters:
  ///   - `oldValue`: The value to replace
  ///   - `newValue`: The replacement value
  ///   - `columns`: Optional list of column names to apply replacement
  ///   - `regex`: Whether to interpret oldValue as a regular expression
  ///   - `matchCase`: Whether replacements are case-sensitive (only used when regex is false)
  ///
  /// Returns a new DataFrame with replacements applied.
  DataFrame replace(dynamic oldValue, dynamic newValue,
      {List<String>? columns, bool regex = false, bool matchCase = true}) {
    final columnsToReplace =
        columns ?? _columns.map((c) => c.toString()).toList();
    final columnIndices =
        columnsToReplace.map((col) => _columns.indexOf(col)).toList();

    // Check if any specified column doesn't exist
    if (columnIndices.contains(-1)) {
      final missingCol = columnsToReplace[columnIndices.indexOf(-1)];
      throw ArgumentError('Column $missingCol does not exist');
    }

    // Create a copy of the data
    final newData = _data.map((row) => List<dynamic>.from(row)).toList();

    RegExp? pattern;
    if (regex && oldValue is String) {
      pattern = RegExp(oldValue, caseSensitive: matchCase);
    }

    // Apply replacement
    for (var i = 0; i < newData.length; i++) {
      for (var colIdx in columnIndices) {
        final value = newData[i][colIdx];

        if (value == null) continue;

        if (regex && value is String && pattern != null) {
          newData[i][colIdx] = value.replaceAll(pattern, newValue.toString());
        } else if (matchCase) {
          if (value == oldValue) {
            newData[i][colIdx] = newValue;
          }
        } else {
          if (value.toString().toLowerCase() ==
              oldValue.toString().toLowerCase()) {
            newData[i][colIdx] = newValue;
          }
        }
      }
    }

    return DataFrame._(_columns, newData);
  }

  /// Converts column data types.
  ///
  /// Parameters:
  ///   - `columns`: Map of column names to target types ('int', 'double', 'string', 'bool')
  DataFrame astype(Map<String, String> columns) {
    final newData = _data.map((row) => List<dynamic>.from(row)).toList();

    columns.forEach((colName, typeName) {
      final colIdx = _columns.indexOf(colName);
      if (colIdx == -1) {
        throw ArgumentError('Column $colName does not exist');
      }

      for (var i = 0; i < newData.length; i++) {
        final value = newData[i][colIdx];
        if (value == null) continue;

        try {
          switch (typeName.toLowerCase()) {
            case 'int':
              newData[i][colIdx] = int.parse(value.toString());
              break;

            case 'double':
              newData[i][colIdx] = double.parse(value.toString());
              break;

            case 'string':
              newData[i][colIdx] = value.toString();
              break;

            case 'bool':
              if (value is bool) {
                newData[i][colIdx] = value;
              } else if (value is num) {
                newData[i][colIdx] = value != 0;
              } else if (value is String) {
                newData[i][colIdx] = value.toLowerCase() == 'true';
              }
              break;

            default:
              throw ArgumentError('Unsupported type: $typeName');
          }
        } catch (e) {
          // If conversion fails, keep the original value
          // Alternatively, could set to null or throw an exception
        }
      }
    });

    return DataFrame._(_columns, newData);
  }

  /// Rounds numeric values to specified precision.
  ///
  /// Parameters:
  ///   - `decimals`: Number of decimal places to round to
  ///   - `columns`: Optional list of column names to round
  DataFrame round(int decimals, {List<String>? columns}) {
    final columnsToRound =
        columns ?? _columns.map((c) => c.toString()).toList();
    final columnIndices =
        columnsToRound.map((col) => _columns.indexOf(col)).toList();

    // Check if any specified column doesn't exist
    if (columnIndices.contains(-1)) {
      final missingCol = columnsToRound[columnIndices.indexOf(-1)];
      throw ArgumentError('Column $missingCol does not exist');
    }

    // Create a copy of the data
    final newData = _data.map((row) => List<dynamic>.from(row)).toList();

    // Apply rounding
    for (var i = 0; i < newData.length; i++) {
      for (var colIdx in columnIndices) {
        final value = newData[i][colIdx];

        if (value is double) {
          final factor = pow(10, decimals);
          newData[i][colIdx] = (value * factor).round() / factor;
        }
      }
    }

    return DataFrame._(_columns, newData);
  }

  /// Computes rolling window calculations.
  ///
  /// Parameters:
  ///   - `column`: Column name to compute rolling calculations on
  ///   - `window`: Size of the rolling window
  ///   - `function`: Function to apply ('mean', 'sum', 'min', 'max', 'std')
  ///   - `minPeriods`: Minimum number of observations required to have a value
  ///   - `center`: Whether to set the labels at the center of the window
  Series rolling(String column, int window, String function,
      {int? minPeriods, bool center = false}) {
    final colIdx = _columns.indexOf(column);
    if (colIdx == -1) {
      throw ArgumentError('Column $column does not exist');
    }

    final columnData = _data.map((row) => row[colIdx]).toList();
    final numData = columnData.whereType<num>().toList();

    if (numData.length != columnData.length) {
      throw ArgumentError(
          'Column must contain only numeric values for rolling calculations');
    }

    final minObs = minPeriods ?? window;
    final result = List<num?>.filled(numData.length, null);

    for (var i = 0; i < numData.length; i++) {
      int start, end;

      if (center) {
        start = i - window ~/ 2;
        end = start + window;
      } else {
        start = i - window + 1;
        end = i + 1;
      }

      if (start < 0) start = 0;
      if (end > numData.length) end = numData.length;

      final windowData = numData.sublist(start, end);

      if (windowData.length < minObs) {
        result[i] = null;
        continue;
      }

      switch (function.toLowerCase()) {
        case 'mean':
          final sum = windowData.reduce((a, b) => a + b);
          result[i] = sum / windowData.length;
          break;

        case 'sum':
          result[i] = windowData.reduce((a, b) => a + b);
          break;

        case 'min':
          result[i] = windowData.reduce((a, b) => a < b ? a : b);
          break;

        case 'max':
          result[i] = windowData.reduce((a, b) => a > b ? a : b);
          break;

        case 'std':
          final mean = windowData.reduce((a, b) => a + b) / windowData.length;
          final variance =
              windowData.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
                  windowData.length;
          result[i] = sqrt(variance);
          break;

        default:
          throw ArgumentError('Unsupported function: $function');
      }
    }

    return Series(result,
        name: 'Rolling $function of $column (window=$window)');
  }

  /// Renames columns in the DataFrame according to the provided mapping.
  void rename(Map<String, String> columnMap) {
    _columns.asMap().forEach((index, name) {
      if (columnMap.containsKey(name)) {
        _columns[index] = columnMap[name];
      }
    });
  }

  /// Drops a specified column from the DataFrame.
  void drop(String column) {
    int columnIndex = _columns.indexOf(column);
    if (columnIndex == -1) {
      throw ArgumentError('Column $column does not exist.');
    }
    _columns.removeAt(columnIndex);
    for (var row in _data) {
      row.removeAt(columnIndex);
    }
  }

  /// Groups the DataFrame by a specified column.
  ///
  /// Returns a map where keys are unique values from the specified column,
  /// and values are DataFrames containing rows corresponding to the key.
  Map<dynamic, DataFrame> groupBy(String column) {
    int columnIndex = _columns.indexOf(column);
    if (columnIndex == -1) {
      throw ArgumentError('Column $column does not exist.');
    }

    Map<dynamic, List<List<dynamic>>> groups = {};
    for (var row in _data) {
      var key = row[columnIndex];
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(row);
    }

    Map<dynamic, DataFrame> result = {};
    groups.forEach((key, value) {
      result[key] = DataFrame._(_columns, value);
    });

    return result;
  }

  /// Enhanced groupby with multiple aggregation functions.
  ///
  /// Parameters:
  ///   - `by`: Column name or list of column names to group by
  ///   - `agg`: Map of column names to aggregation functions ('mean', 'sum', 'min', 'max', 'count', 'std')
  ///            or a custom function that takes a list of values and returns a single value
  ///
  /// Returns a new DataFrame with the grouped and aggregated data.
  DataFrame groupByAgg(dynamic by, Map<String, dynamic> agg) {
    // Convert single column to list
    final List<String> groupColumns = by is String ? [by] : by;

    // Validate group columns
    for (var col in groupColumns) {
      if (!hasColumn(col)) {
        throw ArgumentError('Column $col does not exist');
      }
    }

    // Validate aggregation columns
    for (var col in agg.keys) {
      if (!hasColumn(col)) {
        throw ArgumentError('Column $col does not exist');
      }
    }

    // Extract group column indices
    final groupIndices =
        groupColumns.map((col) => _columns.indexOf(col)).toList();

    // Group the data
    final groups = <List<dynamic>, List<List<dynamic>>>{};

    for (var row in _data) {
      final groupKey = groupIndices.map((idx) => row[idx]).toList();
      groups.putIfAbsent(groupKey, () => []);
      groups[groupKey]!.add(row);
    }

    // Prepare result columns
    final resultColumns = <dynamic>[...groupColumns];
    final aggColumnNames = <String>[];

    // Create column names for aggregated results
    agg.forEach((col, func) {
      final funcName = func is Function ? 'custom' : func.toString();
      aggColumnNames.add('${col}_$funcName');
    });

    resultColumns.addAll(aggColumnNames);

    // Perform aggregation
    final resultData = <List<dynamic>>[];

    groups.forEach((groupKey, rows) {
      final resultRow = <dynamic>[...groupKey];

      // Apply aggregation functions
      agg.forEach((col, func) {
        final colIdx = _columns.indexOf(col);
        final values = rows.map((row) => row[colIdx]).toList();

        if (func is Function) {
          // Custom function
          resultRow.add(func(values));
        } else {
          // Built-in aggregation function
          final aggFunc = func.toString().toLowerCase();
          switch (aggFunc) {
            case 'mean':
              final numValues = values.whereType<num>().toList();
              if (numValues.isEmpty) {
                resultRow.add(null);
              } else {
                resultRow
                    .add(numValues.reduce((a, b) => a + b) / numValues.length);
              }
              break;

            case 'sum':
              final numValues = values.whereType<num>().toList();
              if (numValues.isEmpty) {
                resultRow.add(null);
              } else {
                resultRow.add(numValues.reduce((a, b) => a + b));
              }
              break;

            case 'min':
              final numValues = values.whereType<num>().toList();
              if (numValues.isEmpty) {
                resultRow.add(null);
              } else {
                resultRow.add(numValues.reduce((a, b) => a < b ? a : b));
              }
              break;

            case 'max':
              final numValues = values.whereType<num>().toList();
              if (numValues.isEmpty) {
                resultRow.add(null);
              } else {
                resultRow.add(numValues.reduce((a, b) => a > b ? a : b));
              }
              break;

            case 'count':
              resultRow.add(values.where((v) => v != null).length);
              break;

            case 'std':
              final numValues = values.whereType<num>().toList();
              if (numValues.length <= 1) {
                resultRow.add(null);
              } else {
                final mean =
                    numValues.reduce((a, b) => a + b) / numValues.length;
                final variance = numValues
                        .map((x) => pow(x - mean, 2))
                        .reduce((a, b) => a + b) /
                    numValues.length;
                resultRow.add(sqrt(variance));
              }
              break;

            default:
              throw ArgumentError('Unsupported aggregation function: $aggFunc');
          }
        }
      });

      resultData.add(resultRow);
    });

    return DataFrame._(resultColumns, resultData);
  }

  /// Returns the frequency of each unique value in a specified column.
  ///
  /// Parameters:
  ///   - `column`: The name of the column to count unique values from.
  ///   - `normalize`: If `true`, return relative frequencies (proportions) instead of counts.
  ///   - `sort`: If `true` (default), sort the resulting Series by frequency.
  ///   - `ascending`: If `true` (and `sort` is `true`), sort in ascending order of frequency. Default is `false` (descending).
  ///   - `dropna`: If `true` (default), do not include counts of missing values in the result.
  ///             If `false`, include the count of missing values.
  ///
  /// Returns a Series containing counts (or proportions) of unique values.
  Series valueCounts(
    String column, {
    bool normalize = false,
    bool sort = true,
    bool ascending = false,
    bool dropna = true,
  }) {
    if (!hasColumn(column)) {
      throw ArgumentError('Column $column does not exist.');
    }
    // Delegate to the Series' value_counts method
    return this[column].valueCounts(
      normalize: normalize,
      sort: sort,
      ascending: ascending,
      dropna: dropna,
    );
  }

  /// Summarizes the structure of the DataFrame.
  DataFrame structure() {
    var summaryData = <List<dynamic>>[];

    for (var column in _columns) {
      var columnData = this[column];
      var columnType = _analyzeColumnTypes(columnData); // Uses Series.data directly
      
      // Count missing values based on replaceMissingValueWith
      int missingCount = 0;
      for (var val in columnData.data) {
        if (val == replaceMissingValueWith) {
          missingCount++;
        }
      }

      var row = [
        column,
        columnType, // This is a Map<Type, int>
        columnType.keys.length > 1, // Check if more than one type was found (excluding nulls)
        missingCount, // Use the new missing count
      ];
      summaryData.add(row);
    }

    var columnNames = ['Column Name', 'Data Type', 'Mixed Types', 'Missing Count'];

    return DataFrame(columns: columnNames, summaryData);
  }

  /// Analyzes the data types within a column, ignoring missing values.
  Map<Type, int> _analyzeColumnTypes(Series columnData) {
    var typeCounts = <Type, int>{};
    for (var value in columnData.data) {
      // Consider value as non-missing if it's not the placeholder
      if (value != replaceMissingValueWith) {
        var valueType = value.runtimeType;
        typeCounts[valueType] = (typeCounts[valueType] ?? 0) + 1;
      }
    }
    return typeCounts;
  }

  // _countNullValues is removed as its logic is integrated into structure()

  /// Provides a summary of numerical columns in the DataFrame.
  ///
  /// Calculates count, mean, standard deviation, minimum, quartiles, and maximum values
  /// for each numerical column.
  Map<String, Map<String, num>> describe() {
    Map<String, Map<String, num>> description = {};

    for (var i = 0; i < _columns.length; i++) {
      var columnName = _columns[i];
      var columnData = _data.map((row) => row[i]);

      var numericData = columnData.whereType<num>().toList();
      if (numericData.isEmpty) {
        // Not a numerical column, skip
        continue;
      }

      num count = numericData.length;
      num sum = numericData.fold(0, (prev, element) => prev + element);
      num mean = sum / count;

      num sumOfSquares =
          numericData.fold(0, (prev, element) => prev + pow(element - mean, 2));
      num variance = sumOfSquares / count;
      num std = sqrt(variance);

      var sortedData = numericData..sort();
      num min = sortedData.first;
      num max = sortedData.last;
      num q1 = sortedData[(count * 0.25).floor()];
      num median = sortedData[(count * 0.5).floor()];
      num q3 = sortedData[(count * 0.75).floor()];

      description[columnName] = {
        'count': count,
        'mean': mean,
        'std': std,
        'min': min,
        '25%': q1,
        '50%': median,
        '75%': q3,
        'max': max,
      };
    }

    return description;
  }

  /// Add a row to the DataFrame
  void addRow(List<dynamic> newRow) {
    if (_columns.isEmpty) {
      // DataFrame is empty, add columns first or adjust row length
      // Create columns based on the first row
      _columns = List.generate(newRow.length, (index) => 'Column${index + 1}');
    } else {
      // Ensure new row length matches existing column count
      if (newRow.length != _columns.length) {
        // Handle mismatch (e.g., adjust row or throw exception)
        throw ArgumentError('New row length must match number of columns.');
      }
    }
    _data = _data.isEmpty ? newRow : [_data, newRow];
  }

  /// Add a column to the DataFrame
  void addColumn(dynamic name, {dynamic defaultValue}) {
    if (_columns.contains(name)) {
      throw ArgumentError("Column '$name' already exists");
    }
    _columns = _columns.isEmpty ? [name] : [..._columns, name];

    // Check if defaultValue is a list
    bool isDefaultValueList = defaultValue is List;

    for (int i = 0; i < _data.length; i++) {
      var row = _data[i];

      if (isDefaultValueList) {
        // If defaultValue is a list, use the corresponding value if available
        if (i < defaultValue.length) {
          row.add(defaultValue[i]);
        } else {
          // If index exceeds defaultValue list length, use null
          row.add(null);
        }
      } else {
        // If defaultValue is not a list, use the same value for all rows
        row.add(defaultValue);
      }
    }
  }

  /// Updates a specific value in a column at the given index.
  ///
  /// Parameters:
  ///   - `index`: The row index to update
  ///   - `column`: The column to update (can be either a column name as String or a column index as int)
  ///   - `value`: The new value to set
  void updateColumn(int index, dynamic column, dynamic value) {
    if (index < 0 || index >= _data.length) {
      throw ArgumentError('Index out of range: $index');
    }

    int columnIndex;

    // Handle column parameter as either index or name
    if (column is int) {
      // Column is provided as an index
      if (column < 0 || column >= _columns.length) {
        throw ArgumentError('Column index out of range: $column');
      }
      columnIndex = column;
    } else {
      // Column is provided as a name (String or other type)
      columnIndex =
          _columns.indexWhere((col) => col.toString() == column.toString());
      if (columnIndex == -1) {
        throw ArgumentError('Column $column does not exist');
      }
    }

    // Ensure the row exists and has enough elements
    if (_data[index].length <= columnIndex) {
      // Extend the row if needed
      while (_data[index].length <= columnIndex) {
        _data[index].add(null);
      }
    }

    // Update the value
    _data[index][columnIndex] = value;
  }

  /// Concatenates this DataFrame with a list of other DataFrames along the specified axis.
  ///
  /// Parameters:
  /// - `others`: A list of DataFrames to concatenate with the current DataFrame.
  /// - `axis`: The axis to concatenate along. 0 for row-wise (stacking), 1 for column-wise (side-by-side).
  ///           Default is 0.
  /// - `join`: How to handle columns/indices on the other axis. 'outer' for union, 'inner' for intersection.
  ///           Default is 'outer'.
  /// - `ignore_index`: If `true`, the resulting index will be a new default integer index (0, 1, ..., n-1).
  ///                   Applies to `axis = 0`. For `axis = 1`, it would reset column names to default integers,
  ///                   which is less common and might be handled differently or ignored. Default is `false`.
  DataFrame concatenate(List<DataFrame> others, {int axis = 0, String join = 'outer', bool ignoreIndex = false}) {
    if (others.isEmpty) {
      return copy(); // Concatenating with nothing returns a copy of itself.
    }

    List<DataFrame> allDfs = [this, ...others];

    if (axis == 0) { // Row-wise concatenation
      List<dynamic> finalColumns;
      List<List<dynamic>> finalData = [];

      if (join == 'outer') {
        final Set<dynamic> allColumnSet = {};
        for (var df in allDfs) {
          allColumnSet.addAll(df.columns);
        }
        // Maintain order of first appearance for columns
        finalColumns = <dynamic>[];
        for(var df in allDfs){
            for(var col in df.columns){
                if(!finalColumns.contains(col)){
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
          commonColumns = commonColumns.intersection(Set.from(allDfs[i].columns));
        }
        if (commonColumns.isEmpty && allDfs.any((df) => df.columns.isNotEmpty)) {
             // If intersection is empty but some DFs had columns, result is empty columns
             finalColumns = [];
        } else {
            finalColumns = commonColumns.toList();
        }


        for (var df in allDfs) {
          final colIndicesToKeep = finalColumns.map((col) => df.columns.indexOf(col)).toList();
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

    } else if (axis == 1) { // Column-wise concatenation
      // This implementation for axis=1 is basic and assumes row alignment by index position.
      // A more robust implementation would require a proper Index object for alignment.
      
      List<dynamic> finalCombinedColumns = [];
      for(var df in allDfs){
        finalCombinedColumns.addAll(df.columns); // Simple concatenation of column names
      }
      // Handle duplicate column names if not ignoring index for columns
      if(!ignoreIndex) {
          final Map<dynamic, int> colCounts = {};
          List<dynamic> tempCols = List.from(finalCombinedColumns);
          finalCombinedColumns.clear();
          for(var colName in tempCols){
              int count = colCounts.putIfAbsent(colName, () => 0);
              colCounts[colName] = count + 1;
              if(count > 0){
                  finalCombinedColumns.add("${colName}_$count");
              } else {
                  finalCombinedColumns.add(colName);
              }
          }
      }


      List<List<dynamic>> finalData = [];
      int maxRows = 0;
      for (var df in allDfs) {
        if (df.rowCount > maxRows) {
          maxRows = df.rowCount;
        }
      }

      for (int i = 0; i < maxRows; i++) {
        List<dynamic> newRow = [];
        for (var df in allDfs) {
          if (i < df.rowCount) {
            newRow.addAll(df.rows[i]);
          } else {
            // Fill with missing values for columns of this df
            newRow.addAll(List.filled(df.columnCount, replaceMissingValueWith));
          }
        }
        finalData.add(newRow);
      }
      
      if (ignoreIndex) { // Reset column names to default integer sequence
          var finalColumns = List.generate(finalCombinedColumns.length, (i) => i);
           return DataFrame._(finalColumns, finalData);
      } else {
          return DataFrame._(finalCombinedColumns, finalData);
      }

    } else {
      throw ArgumentError('axis must be 0 (row-wise) or 1 (column-wise).');
    }
  }

  /// Remove the first row from the DataFrame
  void removeFirstRow() {
    if (_data.isNotEmpty) {
      _data.removeAt(0);
    }
  }

  /// Remove the last row from the DataFrame
  void removeLastRow() {
    if (_data.isNotEmpty) {
      _data.removeLast();
    }
  }

  /// Remove a row at the specified index from the DataFrame
  void removeRowAt(int index) {
    if (index >= 0 && index < _data.length) {
      _data.removeAt(index);
    } else {
      throw ArgumentError('Index out of range.');
    }
  }

  /// Limit the DataFrame to a specified number of rows starting from a given index
  DataFrame limit(int limit, {int startIndex = 0}) {
    if (startIndex < 0 || startIndex >= _data.length) {
      throw ArgumentError('Invalid start index.');
    }

    final endIndex = startIndex + limit;
    final limitedData = _data.sublist(
        startIndex, endIndex < _data.length ? endIndex : _data.length);

    return DataFrame._(_columns, limitedData);
  }

  /// Count the number of zeros in a specified column
  int countZeros(String columnName) {
    int columnIndex = _columns.indexOf(columnName);
    if (columnIndex == -1) {
      throw ArgumentError('Column $columnName does not exist.');
    }

    int count = 0;
    for (var row in _data) {
      if (row[columnIndex] == 0) {
        count++;
      }
    }
    return count;
  }

  /// Count the number of null values in a specified column
  int countNulls(String columnName) {
    int columnIndex = _columns.indexOf(columnName);
    if (columnIndex == -1) {
      throw ArgumentError('Column $columnName does not exist.');
    }

    int count = 0;
    for (var row in _data) {
      // Check against the DataFrame's current missing value representation
      if (row[columnIndex] == replaceMissingValueWith) {
        count++;
      }
    }
    return count;
  }

  // @override
  // noSuchMethod(Invocation invocation) {
  //   String columnName = invocation.memberName.toString();
  //   if (invocation.isGetter && _columns.contains(columnName.substring(2))) { // Important Changes!
  //     return this[columnName.substring(2)];
  //   }
  //   super.noSuchMethod(invocation);
  // }

  /// Shuffles the rows of the DataFrame.
  ///
  /// This method randomly shuffles the rows of the DataFrame in place. If a seed is provided,
  /// the shuffle is deterministic, allowing for reproducible shuffles. Without a seed,
  /// the shuffle order is random and different each time the method is called.
  ///
  /// Parameters:
  ///   - `seed` (optional): An integer value used to initialize the random number generator.
  ///     Providing a seed guarantees the shuffle order is the same across different runs
  ///     of the program. If omitted, the shuffle order is random and non-reproducible.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame(
  ///   data: [
  ///     [1, 'A'],
  ///     [2, 'B'],
  ///     [3, 'C'],
  ///     [4, 'D'],
  ///   ],
  ///   columns: ['ID', 'Letter'],
  /// );
  ///
  /// print('Before shuffle:');
  /// print(df);
  ///
  /// // Shuffle without a seed
  /// var newDf = df.shuffle();
  /// print('After random shuffle:');
  /// print(newDf);
  ///
  /// // Shuffle with a seed for reproducibility
  /// newDf = df.shuffle(seed: 123);
  /// print('After shuffle with seed:');
  /// print(newDf);
  /// ```
  DataFrame shuffle({int? seed}) {
    final data = _data.toList();
    var random = seed != null ? Random(seed) : Random();
    for (int i = data.length - 1; i > 0; i--) {
      int n = random.nextInt(i + 1);
      var temp = data[i];
      data[i] = data[n];
      data[n] = temp;
    }

    return DataFrame._(_columns, data);
  }

  /// Returns true if the DataFrame has no rows.
  bool get isEmpty => _data.isEmpty;

  /// Returns true if the DataFrame has at least one row.
  bool get isNotEmpty => _data.isNotEmpty;

  /// Creates a deep copy of the DataFrame.
  ///
  /// Returns a new DataFrame with the same columns and data.
  DataFrame copy() {
    // Create deep copies of the data to ensure independence
    final dataCopy = _data.map((row) => List<dynamic>.from(row)).toList();
    return DataFrame._(List<dynamic>.from(_columns), dataCopy);
  }

  /// Returns a list of column data types.
  ///
  /// For each column, determines the predominant data type.
  Map<String, Type> get dtypes {
    Map<String, Type> types = {};

    for (var i = 0; i < _columns.length; i++) {
      var columnName = _columns[i];
      var columnData = _data.map((row) => row[i]).toList();

      // Count occurrences of each type
      Map<Type, int> typeCounts = {};
      for (var value in columnData) {
        if (value != null) {
          Type valueType = value.runtimeType;
          typeCounts[valueType] = (typeCounts[valueType] ?? 0) + 1;
        }
      }

      // Find the most common type
      Type? mostCommonType;
      int maxCount = 0;
      typeCounts.forEach((type, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonType = type;
        }
      });

      types[columnName] = mostCommonType ?? dynamic;
    }

    return types;
  }

  /// Checks if the DataFrame contains a specific column.
  bool hasColumn(String columnName) => _columns.contains(columnName);

  /// Returns a new DataFrame with only unique rows.
  DataFrame unique() {
    final uniqueRows = <List<dynamic>>{};
    for (var row in _data) {
      uniqueRows.add(List<dynamic>.from(row));
    }
    return DataFrame._(_columns, uniqueRows.toList());
  }

  /// Resets the index of the DataFrame.
  ///
  /// This is useful after filtering operations to ensure row indices are sequential.
  DataFrame resetIndex() {
    // Simply return a copy since we don't maintain explicit indices
    return copy();
  }

  /// Converts the DataFrame to a list of maps.
  ///
  /// Each map represents a row with column names as keys.
  List<Map<dynamic, dynamic>> toListOfMaps() {
    return _data.map((row) {
      final map = <dynamic, dynamic>{};
      for (var i = 0; i < _columns.length; i++) {
        map[_columns[i]] = row[i];
      }
      return map;
    }).toList();
  }

  /// Converts the DataFrame to a map of Series.
  ///
  /// Each key is a column name and each value is a Series containing the column data.
  Map<dynamic, Series> toMap() {
    final map = <dynamic, Series>{};
    for (var i = 0; i < _columns.length; i++) {
      final columnData = _data.map((row) => row[i]).toList();
      map[_columns[i]] = Series(columnData, name: columns[i].toString());
    }
    return map;
  }

  /// Samples n rows from the DataFrame randomly.
  ///
  /// Parameters:
  ///   - `n`: Number of rows to sample
  ///   - `seed`: Optional seed for reproducible sampling
  ///   - `replace`: Whether to sample with replacement
  DataFrame sample(int n, {int? seed, bool replace = false}) {
    if (n <= 0) {
      throw ArgumentError('Sample size must be positive');
    }

    if (!replace && n > _data.length) {
      throw ArgumentError(
          'Sample size cannot exceed DataFrame length when sampling without replacement');
    }

    final random = seed != null ? Random(seed) : Random();
    final indices = <int>[];

    if (replace) {
      // Sampling with replacement
      for (int i = 0; i < n; i++) {
        indices.add(random.nextInt(_data.length));
      }
    } else {
      // Sampling without replacement
      final availableIndices = List.generate(_data.length, (i) => i);
      for (int i = 0; i < n; i++) {
        final randomIndex = random.nextInt(availableIndices.length);
        indices.add(availableIndices[randomIndex]);
        availableIndices.removeAt(randomIndex);
      }
    }

    return selectRowsByIndex(indices);
  }

  /// Applies a function to each element in the specified column.
  ///
  /// Returns a new DataFrame with the transformed column.
  DataFrame applyToColumn(String columnName, dynamic Function(dynamic) func) {
    final columnIndex = _columns.indexOf(columnName);
    if (columnIndex == -1) {
      throw ArgumentError('Column $columnName does not exist');
    }

    final newData = _data.map((row) {
      final newRow = List<dynamic>.from(row);
      newRow[columnIndex] = func(row[columnIndex]);
      return newRow;
    }).toList();

    return DataFrame._(List<dynamic>.from(_columns), newData);
  }

  /// Applies a function to each row of the DataFrame.
  ///
  /// The function should take a Map representing a row and return a value.
  /// Returns a Series containing the results.
  Series applyToRows(dynamic Function(Map<dynamic, dynamic>) func) {
    final results = _data.map((row) {
      final rowMap = Map.fromIterables(_columns, row);
      return func(rowMap);
    }).toList();

    return Series(results, name: 'apply_result');
  }

  /// Performs SQL-like join operations between DataFrames.
  ///
  /// Parameters:
  ///   - `other`: The DataFrame to join with.
  ///   - `how`: Type of join ('inner', 'left', 'right', 'outer', 'cross'). Default is 'inner'.
  ///   - `on`: Column name(s) to join on. Must be present in both DataFrames.
  ///           If specified, `leftOn` and `rightOn` must be null.
  ///   - `leftOn`: Column(s) from the left DataFrame to use as keys.
  ///   - `rightOn`: Column(s) from the right DataFrame to use as keys.
  ///   - `suffixes`: Suffixes to apply to overlapping column names (default: ['_x', '_y']).
  ///   - `indicator`: If `true`, adds a column to the output DataFrame called '_merge'
  ///                  with information on the source of each row ('left_only', 'right_only', 'both').
  ///                  If a String is provided, it is used as the name for the indicator column.
  DataFrame join(
    DataFrame other, {
    String how = 'inner',
    dynamic on,
    dynamic leftOn,
    dynamic rightOn,
    List<String> suffixes = const ['_x', '_y'],
    dynamic indicator = false,
  }) {
    List<String> leftCols;
    List<String> rightCols;

    if (on != null) {
      if (leftOn != null || rightOn != null) {
        throw ArgumentError("Cannot use 'on' simultaneously with 'leftOn' or 'rightOn'.");
      }
      leftCols = on is String ? [on] : List<String>.from(on);
      rightCols = on is String ? [on] : List<String>.from(on);
    } else {
      if (leftOn == null || rightOn == null) {
        throw ArgumentError("Either 'on' or both 'leftOn' and 'rightOn' must be specified.");
      }
      leftCols = leftOn is String ? [leftOn] : List<String>.from(leftOn);
      rightCols = rightOn is String ? [rightOn] : List<String>.from(rightOn);
    }
    
    // Handle different join types
    if (how == 'cross') {
      if (on != null || leftOn != null || rightOn != null) {
        print("Warning: 'on', 'leftOn', and 'rightOn' are ignored for cross join.");
      }
      return _crossJoin(other, suffixes); // Indicator logic might be added to _crossJoin or handled here
    }


    if (leftCols.length != rightCols.length) {
      throw ArgumentError(
          'leftOn/on and rightOn/on column lists must have the same number of columns');
    }

    // Validate columns
    for (var col in leftCols) {
      if (!hasColumn(col)) {
        throw ArgumentError('Left column $col does not exist in left DataFrame');
      }
    }

    for (var col in rightCols) {
      if (!other.hasColumn(col)) {
        throw ArgumentError('Right column $col does not exist in right DataFrame');
      }
    }

    // Extract column indices
    final leftIndices = leftCols.map((col) => _columns.indexOf(col)).toList();
    final rightIndices =
        rightCols.map((col) => other._columns.indexOf(col)).toList();

    // Create new column names (avoiding duplicates)
    final newColumns = <dynamic>[];

    // Add left columns
    for (var col in _columns) {
      newColumns.add(col);
    }

    // Add right columns (with suffixes for duplicates)
    for (var col in other._columns) {
      if (!rightCols.contains(col) || leftCols != rightCols) {
        if (_columns.contains(col) && !leftCols.contains(col)) {
          newColumns.add('$col${suffixes[1]}');
        } else {
          newColumns.add(col);
        }
      }
    }

    // Build maps for faster lookups
    final rightMap = <List<dynamic>, List<List<dynamic>>>{};
    for (var rightRow in other._data) {
      final key = rightIndices.map((idx) => rightRow[idx]).toList();
      rightMap.putIfAbsent(key, () => []);
      rightMap[key]!.add(rightRow);
    }

    final newData = <List<dynamic>>[];

    // Perform the join based on the specified type
    final List<String> mergeIndicatorValues = [];

    switch (how) {
      case 'inner':
        for (var leftRow in _data) {
          final key = leftIndices.map((idx) => leftRow[idx]).toList();
          if (rightMap.containsKey(key)) {
            for (var rightRow in rightMap[key]!) {
              newData.add(_joinRows(
                  other, leftRow, rightRow, leftCols, rightCols, suffixes));
              if (indicator != false) mergeIndicatorValues.add('both');
            }
          }
        }
        break;

      case 'left':
        for (var leftRow in _data) {
          final key = leftIndices.map((idx) => leftRow[idx]).toList();
          if (rightMap.containsKey(key)) {
            for (var rightRow in rightMap[key]!) {
              newData.add(_joinRows(
                  other, leftRow, rightRow, leftCols, rightCols, suffixes));
               if (indicator != false) mergeIndicatorValues.add('both');
            }
          } else {
            newData.add(_joinRowsWithNull(
                leftRow, true, leftCols, rightCols, other._columns, suffixes));
            if (indicator != false) mergeIndicatorValues.add('left_only');
          }
        }
        break;

      case 'right':
        final leftMap = <List<dynamic>, List<List<dynamic>>>{};
         for (var leftRow in _data) {
           final key = leftIndices.map((idx) => leftRow[idx]).toList();
           leftMap.putIfAbsent(key, () => []);
           leftMap[key]!.add(leftRow);
         }

        for (var rightRow in other._data) {
          final key = rightIndices.map((idx) => rightRow[idx]).toList();
          if (leftMap.containsKey(key)) {
            for (var leftRow in leftMap[key]!) {
              newData.add(_joinRows(
                  other, leftRow, rightRow, leftCols, rightCols, suffixes));
              if (indicator != false) mergeIndicatorValues.add('both');
            }
          } else {
            newData.add(_joinRowsWithNull(
                rightRow, false, leftCols, rightCols, _columns, suffixes));
             if (indicator != false) mergeIndicatorValues.add('right_only');
          }
        }
        break;

      case 'outer':
        final Set<List<dynamic>> processedRightKeys = {}; // To track right keys already matched

        for (var leftRow in _data) {
          final key = leftIndices.map((idx) => leftRow[idx]).toList();
          bool matched = false;
          if (rightMap.containsKey(key)) {
            for (var rightRow in rightMap[key]!) {
              newData.add(_joinRows(
                  other, leftRow, rightRow, leftCols, rightCols, suffixes));
              if (indicator != false) mergeIndicatorValues.add('both');
              matched = true;
            }
            processedRightKeys.add(key); 
          }
          if (!matched) {
            newData.add(_joinRowsWithNull(
                leftRow, true, leftCols, rightCols, other._columns, suffixes));
            if (indicator != false) mergeIndicatorValues.add('left_only');
          }
        }

        // Add remaining right-only rows
        rightMap.forEach((key, rightRows) {
          bool keyAlreadyProcessed = processedRightKeys.any((prk) {
              if (prk.length != key.length) return false;
              for(int i=0; i < prk.length; ++i) {
                if(prk[i] != key[i]) return false;
              }
              return true;
          });

          if (!keyAlreadyProcessed) {
            for (var rightRow in rightRows) {
              newData.add(_joinRowsWithNull(
                  rightRow, false, leftCols, rightCols, _columns, suffixes));
              if (indicator != false) mergeIndicatorValues.add('right_only');
            }
          }
        });
        break;

      default:
        throw ArgumentError(
            'Invalid join type. Supported types are: inner, left, right, outer, cross');
    }
    
    DataFrame resultDf = DataFrame._(newColumns, newData);

    if (indicator != false) {
      String indicatorColName = indicator is String ? indicator : '_merge';
      if (resultDf.hasColumn(indicatorColName)){
         // Add suffix if indicator column name conflicts
         int suffixNum = 1;
         String baseName = indicatorColName;
         while(resultDf.hasColumn(indicatorColName)){
           indicatorColName = '${baseName}_$suffixNum';
           suffixNum++;
         }
      }
      resultDf.addColumn(indicatorColName, defaultValue: mergeIndicatorValues);
    }

    return resultDf;
  }

  /// Helper method for cross join
  DataFrame _crossJoin(DataFrame other, List<String> suffixes) {
    final newColumns = <dynamic>[];

    // Add left columns
    for (var col in _columns) {
      newColumns.add(col);
    }

    // Add right columns (with suffixes for duplicates)
    for (var col in other._columns) {
      if (_columns.contains(col)) {
        newColumns.add('$col${suffixes[1]}');
      } else {
        newColumns.add(col);
      }
    }

    final newData = <List<dynamic>>[];

    // Cartesian product of rows
    for (var leftRow in _data) {
      for (var rightRow in other._data) {
        final newRow = <dynamic>[...leftRow];

        // Add right columns (handling duplicates)
        for (var i = 0; i < other._columns.length; i++) {
          newRow.add(rightRow[i]);
        }

        newData.add(newRow);
      }
    }

    return DataFrame._(newColumns, newData);
  }

  /// Helper method to join two rows
  List<dynamic> _joinRows(
      DataFrame other,
      List<dynamic> leftRow,
      List<dynamic> rightRow,
      List<String> leftCols,
      List<String> rightCols,
      List<String> suffixes) {
    final result = <dynamic>[...leftRow];

    // Add right columns (skipping join columns if they have the same name)
    for (var i = 0; i < rightRow.length; i++) {
      final colName = other.columns[i];
      if (rightCols.contains(colName) && leftCols == rightCols) {
        // Skip join columns with the same name
        continue;
      }

      result.add(rightRow[i]);
    }

    return result;
  }

  /// Helper method to join a row with nulls for the other side
  List<dynamic> _joinRowsWithNull(
      List<dynamic> row,
      bool isLeft,
      List<String> leftCols,
      List<String> rightCols,
      List<dynamic> otherColumns,
      List<String> suffixes) {
    final result = <dynamic>[];

    if (isLeft) {
      // Left row with nulls for right
      result.addAll(row);

      // Add nulls for right columns (skipping join columns if they have the same name)
      for (var i = 0; i < otherColumns.length; i++) {
        final colName = otherColumns[i];
        if (rightCols.contains(colName) && leftCols == rightCols) {
          // Skip join columns with the same name
          continue;
        }

        result.add(null);
      }
    } else {
      // Right row with nulls for left
      // Add nulls for left columns
      for (var i = 0; i < _columns.length; i++) {
        result.add(null);
      }

      // Replace nulls with values for join columns
      for (var i = 0; i < rightCols.length; i++) {
        final rightIdx = otherColumns.indexOf(rightCols[i]);
        final leftIdx = _columns.indexOf(leftCols[i]);
        result[leftIdx] = row[rightIdx];
      }

      // Add right columns (skipping join columns if they have the same name)
      for (var i = 0; i < otherColumns.length; i++) {
        final colName = otherColumns[i];
        if (rightCols.contains(colName) && leftCols == rightCols) {
          // Skip join columns with the same name
          continue;
        }

        result.add(row[i]);
      }
    }

    return result;
  }

  /// Computes correlation between numeric columns.
  ///
  /// Returns a DataFrame with correlation coefficients.
  DataFrame corr() {
    // Get numeric columns
    final numericColumns = <String>[];
    final numericIndices = <int>[];

    for (var i = 0; i < _columns.length; i++) {
      var columnData = _data.map((row) => row[i]).toList();
      if (columnData.whereType<num>().isNotEmpty) {
        numericColumns.add(_columns[i].toString());
        numericIndices.add(i);
      }
    }

    if (numericColumns.isEmpty) {
      throw StateError('No numeric columns found for correlation calculation');
    }

    // Create correlation matrix
    final correlationData = <List<dynamic>>[];

    for (var i = 0; i < numericIndices.length; i++) {
      final rowData = <dynamic>[];
      final colIndex1 = numericIndices[i];
      final col1Data =
          _data.map((row) => row[colIndex1]).whereType<num>().toList();

      for (var j = 0; j < numericIndices.length; j++) {
        final colIndex2 = numericIndices[j];
        final col2Data =
            _data.map((row) => row[colIndex2]).whereType<num>().toList();

        // Calculate Pearson correlation
        final correlation = _calculateCorrelation(col1Data, col2Data);
        rowData.add(correlation);
      }

      correlationData.add(rowData);
    }

    return DataFrame._(numericColumns, correlationData);
  }

  /// Calculates Pearson correlation coefficient between two numeric lists
  double _calculateCorrelation(List<num> x, List<num> y) {
    if (x.length != y.length || x.isEmpty) {
      return double.nan;
    }

    final n = x.length;

    // Calculate means
    final xMean = x.reduce((a, b) => a + b) / n;
    final yMean = y.reduce((a, b) => a + b) / n;

    // Calculate covariance and variances
    double covariance = 0;
    double xVariance = 0;
    double yVariance = 0;

    for (var i = 0; i < n; i++) {
      final xDiff = x[i] - xMean;
      final yDiff = y[i] - yMean;

      covariance += xDiff * yDiff;
      xVariance += xDiff * xDiff;
      yVariance += yDiff * yDiff;
    }

    if (xVariance == 0 || yVariance == 0) {
      return 0; // No variation in at least one variable
    }

    return covariance / (sqrt(xVariance) * sqrt(yVariance));
  }

  /// Bins a numeric column into discrete intervals.
  ///
  /// Parameters:
  ///   - `column`: The name of the column to bin
  ///   - `bins`: Either an integer specifying the number of bins, or a list of bin edges
  ///   - `newColumn`: Name for the new column containing bin labels
  ///   - `labels`: Optional custom labels for the bins
  ///   - `right`: Whether the intervals include the right boundary (default: true)
  ///   - `includeLowest`: Whether the first interval should include the lowest value (default: false)
  ///   - `duplicates`: How to handle duplicate bin edges ('raise' or 'drop')
  ///   - `decimalPlaces`: Number of decimal places to use in bin labels (default: 2)
  DataFrame bin(dynamic column, dynamic bins,
      {String? newColumn,
      List<String>? labels,
      bool right = true,
      bool includeLowest = false,
      String duplicates = 'raise',
      int decimalPlaces = 2}) {
    final colName = column.toString();
    final targetColName = newColumn ?? '${colName}_bin';
    
    // Validate column exists
    final colIdx = _columns.indexOf(colName);
    if (colIdx == -1) {
      throw ArgumentError('Column $colName does not exist');
    }
    
    // Extract numeric data from the column
    final numericData = <num>[];
    final rowIndices = <int>[];
    
    for (var i = 0; i < _data.length; i++) {
    final value = _data[i][colIdx];
    if (value is num) {
        // Skip NaN values
        if (value is double && value.isNaN) {
          continue;
        }
        numericData.add(value);
        rowIndices.add(i);
      }
    }
    
    if (numericData.isEmpty) {
      throw ArgumentError('Column $colName contains no valid numeric data for binning');
    }
    
    // Determine bin edges
    List<num> binEdges;
    
    if (bins is int) {
      // Create evenly spaced bins
      final min = numericData.reduce((a, b) => a < b ? a : b);
      final max = numericData.reduce((a, b) => a > b ? a : b);
      
      // Handle case where all values are the same
      if (min == max) {
        // Create small range around the single value
        final delta = min.abs() * 0.001;
        binEdges = List.generate(
            bins + 1, (i) => min - delta + i * (2 * delta / bins));
      } else {
        binEdges = List.generate(
            bins + 1, (i) => min + i * (max - min) / bins);
      }
    } else if (bins is List<num>) {
      binEdges = List<num>.from(bins);
      
      // Check for duplicates
      final uniqueEdges = binEdges.toSet().toList()..sort();
      if (uniqueEdges.length < binEdges.length) {
        if (duplicates == 'raise') {
          throw ArgumentError('Bin edges must be unique');
        } else if (duplicates == 'drop') {
          binEdges = uniqueEdges;
        }
      }
    } else {
      throw ArgumentError('bins must be an integer or a list of numbers');
    }
    
    // Sort bin edges
    binEdges.sort();
    
    // Generate bin labels
    List<String> binLabels;
    
    if (labels != null) {
      if (labels.length != binEdges.length - 1) {
        throw ArgumentError(
            'labels must have length equal to bins.length - 1');
      }
      binLabels = labels;
    } else {
      binLabels = [];
      for (var i = 0; i < binEdges.length - 1; i++) {
        // For right=false, all left brackets are '[' regardless of includeLowest
        final leftBracket = right ? 
            ((i == 0 && includeLowest) ? '[' : '(') : 
            '[';
        
        // For right=false, all right brackets are ')' except the last one which is ']'
        final rightBracket = (i == binEdges.length - 2) ? ']' : (right ? ']' : ')');
        
        // Format with specified decimal places
        final formattedLeft = binEdges[i].toStringAsFixed(decimalPlaces);
        final formattedRight = binEdges[i + 1].toStringAsFixed(decimalPlaces);
        
        binLabels.add('$leftBracket$formattedLeft, $formattedRight$rightBracket');
      }
    }
    
    // Assign data to bins
    final binIndices = List<int?>.filled(numericData.length, null);
    
    for (var i = 0; i < numericData.length; i++) {
      final value = numericData[i];
      
      for (var j = 0; j < binEdges.length - 1; j++) {
        final leftEdge = binEdges[j];
        final rightEdge = binEdges[j + 1];
        
        bool inLeftBoundary;
        bool inRightBoundary;
        
        if (right) {
          // For right=true: (left, right] or [left, right] if includeLowest and first bin
          inLeftBoundary = (j == 0 && includeLowest) ? 
              value >= leftEdge : 
              value > leftEdge;
          inRightBoundary = value <= rightEdge;
        } else {
          // For right=false: [left, right) or [left, right] for the last bin
          inLeftBoundary = value >= leftEdge;
          inRightBoundary = (j == binEdges.length - 2) ? 
              value <= rightEdge : 
              value < rightEdge;
        }
        
        if (inLeftBoundary && inRightBoundary) {
          binIndices[i] = j;
          break;
        }
      }
    }
    
    // Create new DataFrame with bin column
    final newData = _data.map((row) => List<dynamic>.from(row)).toList();
    final newColumns = List<dynamic>.from(_columns);
    
    if (!newColumns.contains(targetColName)) {
      newColumns.add(targetColName);
      for (var row in newData) {
        row.add(null);
      }
    }
    
    final targetColIdx = newColumns.indexOf(targetColName);
    
    for (var i = 0; i < rowIndices.length; i++) {
      final rowIdx = rowIndices[i];
      final binIdx = binIndices[i];
      newData[rowIdx][targetColIdx] = binIdx != null ? binLabels[binIdx] : null;
    }
    
    return DataFrame._(newColumns, newData);
  }

  /// Converts the DataFrame to a CSV string.
  ///
  /// Parameters:
  ///   - `delimiter`: Character to use as delimiter (default: ',')
  ///   - `includeHeader`: Whether to include column names as header
  String toCsv({String delimiter = ',', bool includeHeader = true}) {
    final buffer = StringBuffer();

    // Add header
    if (includeHeader) {
      buffer.writeln(_columns.join(delimiter));
    }

    // Add data rows
    for (var row in _data) {
      final formattedRow = row.map((cell) {
        if (cell == null) return '';

        // Quote strings containing the delimiter
        final cellStr = cell.toString();
        if (cellStr.contains(delimiter) ||
            cellStr.contains('"') ||
            cellStr.contains('\n')) {
          return '"${cellStr.replaceAll('"', '""')}"';
        }
        return cellStr;
      }).join(delimiter);

      buffer.writeln(formattedRow);
    }

    return buffer.toString();
  }

  /// Creates a pivot table from the DataFrame, allowing aggregation.
  ///
  /// Parameters:
  ///   - `index`: Column name to use for the new DataFrame's index.
  ///   - `columns`: Column name to use for the new DataFrame's columns.
  ///   - `values`: Column name to aggregate.
  ///   - `aggFunc`: Aggregation function to apply. Supported: 'mean', 'sum', 'count', 'min', 'max'. Default is 'mean'.
  ///   - `fill_value`: Value to replace missing cells in the pivot table after aggregation.
  DataFrame pivotTable({required String index, required String columns, required String values,
      String aggFunc = 'mean', dynamic fillValue}) {
    if (!hasColumn(index) || !hasColumn(columns) || !hasColumn(values)) {
      throw ArgumentError('Index, columns, or values column not found in DataFrame');
    }

    // Get unique values for index and columns
    final indexValues = this[index].unique().data;
    final columnValues = this[columns].unique().data;

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
                  aggResult = values.reduce((a,b) => (a as Comparable).compareTo(b as Comparable) < 0 ? a : b);
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
                  aggResult = values.reduce((a,b) => (a as Comparable).compareTo(b as Comparable) > 0 ? a : b);
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
        for (int j = 1; j < pivotData[i].length; j++) { // Start from j=1 to skip the index column
          if (pivotData[i][j] == null) {
            pivotData[i][j] = fillValue;
          }
        }
      }
    }

    return DataFrame._(newColumns, pivotData);
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
  DataFrame pivot({required String index, required String columns, String? values}) {
    if (!hasColumn(index) || !hasColumn(columns)) {
      throw ArgumentError('Index or columns column not found in DataFrame.');
    }
    String valueCol = values ?? '';

    if (values != null) {
        if(!hasColumn(values)) {
             throw ArgumentError('Values column $values not found in DataFrame.');
        }
    } else {
        List<String> remainingCols = _columns.map((c) => c.toString()).where((c) => c != index && c != columns).toList();
        if (remainingCols.isEmpty) {
            throw ArgumentError('No values columns found to pivot. Specify `values` or ensure other columns exist.');
        }
        if (remainingCols.length > 1) {
            print('Warning: Multiple value columns found and `values` parameter is null. Using first remaining column: ${remainingCols.first}');
            valueCol = remainingCols.first;
        } else {
            valueCol = remainingCols.first;
        }
    }


    final indexValues = this[index].unique().data..sort((a, b) => (a as Comparable).compareTo(b as Comparable));
    final columnValues = this[columns].unique().data..sort((a, b) => (a as Comparable).compareTo(b as Comparable));

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
    for(var row in _data) {
        dataMap.putIfAbsent(row[indexIdx], () => {})[row[columnsIdx]] = row[valuesIdx];
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

  /// Computes cumulative calculations for a column.
  ///
  /// Parameters:
  ///   - `column`: Column name to compute cumulative calculations on
  ///   - `function`: Function to apply ('sum', 'prod', 'min', 'max')
  ///   - `newColumn`: Optional name for the new column with results
  DataFrame cumulative(String column, String function, {String? newColumn}) {
    final colIdx = _columns.indexOf(column);
    if (colIdx == -1) {
      throw ArgumentError('Column $column does not exist');
    }

    final columnData = _data.map((row) => row[colIdx]).toList();
    final numData = columnData.whereType<num>().toList();

    if (numData.length != columnData.length) {
      throw ArgumentError(
          'Column must contain only numeric values for cumulative calculations');
    }

    final resultColumnName = newColumn ?? '${column}_cum$function';
    final newData = _data.map((row) => List<dynamic>.from(row)).toList();
    final newColumns = List<dynamic>.from(_columns)..add(resultColumnName);

    // Calculate cumulative values
    final cumulativeValues = <num>[];

    switch (function.toLowerCase()) {
      case 'sum':
        num runningSum = 0;
        for (var i = 0; i < numData.length; i++) {
          runningSum += numData[i];
          cumulativeValues.add(runningSum);
        }
        break;

      case 'prod':
        num runningProduct = 1;
        for (var i = 0; i < numData.length; i++) {
          runningProduct *= numData[i];
          cumulativeValues.add(runningProduct);
        }
        break;

      case 'min':
        num runningMin = numData[0];
        cumulativeValues.add(runningMin);
        for (var i = 1; i < numData.length; i++) {
          runningMin = min(runningMin, numData[i]);
          cumulativeValues.add(runningMin);
        }
        break;

      case 'max':
        num runningMax = numData[0];
        cumulativeValues.add(runningMax);
        for (var i = 1; i < numData.length; i++) {
          runningMax = max(runningMax, numData[i]);
          cumulativeValues.add(runningMax);
        }
        break;

      default:
        throw ArgumentError(
            'Unsupported function: $function. Supported functions are: sum, prod, min, max');
    }

    // Add cumulative values to the data
    for (var i = 0; i < newData.length; i++) {
      newData[i].add(cumulativeValues[i]);
    }

    return DataFrame._(newColumns, newData);
  }

  /// Computes quantiles over a column.
  ///
  /// Parameters:
  ///   - `column`: Column name to compute quantiles on
  ///   - `q`: Quantile or list of quantiles to compute (between 0 and 1)
  Series quantile(String column, dynamic q) {
    final colIdx = _columns.indexOf(column);
    if (colIdx == -1) {
      throw ArgumentError('Column $column does not exist');
    }

    final columnData = _data.map((row) => row[colIdx]).toList();
    final numData = columnData.whereType<num>().toList()..sort();

    if (numData.isEmpty) {
      throw ArgumentError(
          'Column must contain numeric values for quantile calculation');
    }

    List<double> quantiles;
    if (q is num) {
      quantiles = [q.toDouble()];
    } else if (q is List) {
      quantiles = q
          .map((val) =>
              val is num ? val.toDouble() : double.parse(val.toString()))
          .toList();
    } else {
      throw ArgumentError('q must be a number or a list of numbers');
    }

    // Validate quantiles
    for (var quantile in quantiles) {
      if (quantile < 0 || quantile > 1) {
        throw ArgumentError('Quantiles must be between 0 and 1');
      }
    }

    // Calculate quantiles
    final results = <num>[];
    for (var quantile in quantiles) {
      final position = (numData.length - 1) * quantile;
      final positionIndex = position.floor();
      final remainder = position - positionIndex;

      if (positionIndex < numData.length - 1) {
        final lower = numData[positionIndex];
        final upper = numData[positionIndex + 1];
        results.add(lower + remainder * (upper - lower));
      } else {
        results.add(numData[positionIndex]);
      }
    }

    // If only one quantile was requested, return a single value
    if (results.length == 1) {
      return Series([results.first], name: 'Quantile $q of $column');
    }

    // Otherwise, return a Series with quantiles as values
    return Series(results, name: 'Quantiles of $column');
  }

  /// Computes numerical rank along a column.
  ///
  /// Parameters:
  ///   - `column`: Column name to compute ranks on
  ///   - `method`: Method to use for handling ties ('average', 'min', 'max', 'first')
  ///   - `ascending`: Whether to rank in ascending order
  ///   - `pct`: Whether to return percentage ranks
  ///   - `newColumn`: Optional name for the new column with ranks
  DataFrame rank(String column,
      {String method = 'average',
      bool ascending = true,
      bool pct = false,
      String? newColumn}) {
    final colIdx = _columns.indexOf(column);
    if (colIdx == -1) {
      throw ArgumentError('Column $column does not exist');
    }

    final columnData = _data.map((row) => row[colIdx]).toList();

    // Create a list of (value, index) pairs for sorting
    final indexedValues = columnData
        .asMap()
        .entries
        .map((entry) => MapEntry(entry.key, entry.value))
        .toList();

    // Sort by value
    indexedValues.sort((a, b) {
      if (a.value == null && b.value == null) return 0;
      if (a.value == null) return ascending ? -1 : 1;
      if (b.value == null) return ascending ? 1 : -1;

      final comparison =
          Comparable.compare(a.value as Comparable, b.value as Comparable);
      return ascending ? comparison : -comparison;
    });

    // Assign ranks
    final ranks = List<num?>.filled(columnData.length, null);

    int i = 0;
    while (i < indexedValues.length) {
      if (indexedValues[i].value == null) {
        ranks[indexedValues[i].key] = null;
        i++;
        continue;
      }

      // Find all elements with the same value
      int j = i + 1;
      while (j < indexedValues.length &&
          indexedValues[j].value == indexedValues[i].value) {
        j++;
      }

      // Assign ranks based on the method
      final tieCount = j - i;

      if (tieCount == 1 || method == 'first') {
        // No ties or 'first' method
        ranks[indexedValues[i].key] = i + 1;
      } else {
        // Handle ties
        switch (method) {
          case 'average':
            final avgRank = (i + j - 1) / 2 + 1;
            for (var k = i; k < j; k++) {
              ranks[indexedValues[k].key] = avgRank;
            }
            break;

          case 'min':
            for (var k = i; k < j; k++) {
              ranks[indexedValues[k].key] = i + 1;
            }
            break;

          case 'max':
            for (var k = i; k < j; k++) {
              ranks[indexedValues[k].key] = j;
            }
            break;

          default:
            throw ArgumentError(
                'Unsupported method: $method. Supported methods are: average, min, max, first');
        }
      }

      i = j;
    }

    // Convert to percentage ranks if requested
    if (pct) {
      final maxRank = columnData.length;
      for (var i = 0; i < ranks.length; i++) {
        if (ranks[i] != null) {
          ranks[i] = ranks[i]! / maxRank;
        }
      }
    }

    // Create new DataFrame with ranks
    final resultColumnName = newColumn ?? '${column}_rank';
    final newData = _data
        .asMap()
        .map((i, row) {
          final newRow = List<dynamic>.from(row);
          newRow.add(ranks[i]);
          return MapEntry(i, newRow);
        })
        .values
        .toList();

    final newColumns = List<dynamic>.from(_columns)..add(resultColumnName);

    return DataFrame._(newColumns, newData);
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
  DataFrame crosstab({ 
      required String index, 
      required String column,
      String? values, 
      String aggfunc = 'count',
      dynamic normalize = false,
      bool margins = false,
      String marginsName = 'All'
  }) {
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
    final rowValues = this[index].unique().data;
    final columnValues = this[column].unique().data;

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
                cellValue = cellValues.fold<num>(0, (prev, val) => prev + (val as num));
              } else {
                cellValue = null;
              }
              break;

            case 'mean':
              if (cellValues.every((v) => v is num)) {
                final sum = cellValues.fold<num>(0, (prev, val) => prev + (val as num));
                cellValue = sum / cellValues.length;
              } else {
                cellValue = null;
              }
              break;

            case 'min':
              if (cellValues.every((v) => v is num)) {
                cellValue = cellValues.cast<num>().reduce((a, b) => a < b ? a : b);
              } else if (cellValues.isNotEmpty) {
                cellValue = cellValues.reduce((a, b) => a.toString().compareTo(b.toString()) < 0 ? a : b);
              } else {
                cellValue = null;
              }
              break;

            case 'max':
              if (cellValues.every((v) => v is num)) {
                cellValue = cellValues.cast<num>().reduce((a, b) => a > b ? a : b);
              } else if (cellValues.isNotEmpty) {
                cellValue = cellValues.reduce((a, b) => a.toString().compareTo(b.toString()) > 0 ? a : b);
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

  /// Transform each element of a list-like column to a row.
  ///
  /// Parameters:
  ///   - `column`: Column name containing lists to explode
  ///   - `preserveIndex`: Whether to preserve the original index
  DataFrame explode(String column, {bool preserveIndex = false}) {
    final colIdx = _columns.indexOf(column);
    if (colIdx == -1) {
      throw ArgumentError('Column $column does not exist');
    }

    final newData = <List<dynamic>>[];

    for (var i = 0; i < _data.length; i++) {
      final row = _data[i];
      final value = row[colIdx];

      if (value == null) {
        // Keep null values as is
        newData.add(List<dynamic>.from(row));
        continue;
      }

      if (value is! List && value is! Iterable) {
        // Non-list values are kept as is
        newData.add(List<dynamic>.from(row));
        continue;
      }

      final listValue = value is Iterable ? value.toList() : value as List;

      if (listValue.isEmpty) {
        // Empty lists result in a row with null in the exploded column
        final newRow = List<dynamic>.from(row);
        newRow[colIdx] = null;
        newData.add(newRow);
      } else {
        // Create a new row for each element in the list
        for (var element in listValue) {
          final newRow = List<dynamic>.from(row);
          newRow[colIdx] = element;
          newData.add(newRow);
        }
      }
    }

    return DataFrame._(_columns, newData);
  }

  /// Convert categorical variable(s) into dummy/indicator variables.
  ///
  /// Parameters:
  ///   - `columns`: List of column names to encode. If null or empty,
  ///                columns with string dtype will be converted.
  ///   - `prefix`: String to append DataFrame column name if Suffix is not None.
  ///               If a list or map is provided, it must match the length of `columns`.
  ///               (Currently, only String prefix is supported, applied to all columns).
  ///   - `prefix_sep`: Separator to use between prefix and category value. Default is '_'.
  ///   - `dummy_na`: Add a column to indicate NaNs, if `false` NaNs are ignored. Default is `false`.
  ///   - `drop_first`: Whether to get k-1 dummies out of k categorical levels by removing the first level.
  ///                   Default is `false`.
  ///
  /// Returns:
  /// DataFrame with original categorical columns replaced by dummy variables.
  DataFrame getDummies(List<String>? columns,
      {String? prefix,
      dynamic prefixSep = '_',
      bool dummyNA = false,
      bool dropFirst = false}) {
    DataFrame resultDf = copy(); // Start with a copy of the original DataFrame
    List<String> columnsToEncode = [];
    List<String> originalColumnsToDrop = [];

    String sep = prefixSep is String ? prefixSep : prefixSep.toString();

    if (columns == null || columns.isEmpty) {
      // Heuristically identify string columns for dummification
      for (var colNameDyn in this.columns) {
        String colName = colNameDyn.toString();
        // Check the type of the first few non-null elements, or use Series.dtype if available
        // For simplicity, we'll rely on a basic check of the first non-null element's type.
        // A more robust Series.dtype would be better here.
        final seriesData = this[colName].data;
        dynamic firstNonNull = seriesData.firstWhere((val) => val != replaceMissingValueWith, orElse: () => null);
        if (firstNonNull is String) {
          columnsToEncode.add(colName);
        }
        // A more advanced heuristic could check if a column is not purely numeric/boolean
        // and has a limited number of unique values.
      }
    } else {
      for (var colName in columns) {
        if (!hasColumn(colName)) {
          throw ArgumentError('Column $colName not found in DataFrame.');
        }
        columnsToEncode.add(colName);
      }
    }

    if (columnsToEncode.isEmpty) {
      return resultDf; // No columns to encode
    }
    
    for (var colName in columnsToEncode) {
      Series originalSeries = this[colName];
      List<dynamic> categories = [];
      Set<dynamic> uniqueValues = {};
      
      bool hasNa = false;
      for(var val in originalSeries.data) {
        if (val == replaceMissingValueWith) {
          hasNa = true;
        } else {
          if(uniqueValues.add(val)){
            categories.add(val);
          }
        }
      }
      // Sort categories to ensure consistent column order
      categories.sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return -1;
        if (b == null) return 1;
        if (a is Comparable && b is Comparable) return a.compareTo(b);
        return a.toString().compareTo(b.toString());
      });


      if (dummyNA && hasNa) {
        categories.add(replaceMissingValueWith); // Add a placeholder for NA category
      }

      if (dropFirst && categories.isNotEmpty) {
        categories.removeAt(0);
      }

      for (var category in categories) {
        String categoryStr;
        String currentPrefix;

        if (prefix is String) {
          currentPrefix = prefix;
        } else {
          currentPrefix = colName;
        }
        
        if (category == replaceMissingValueWith) {
            categoryStr = 'na'; // Consistent string for NA category
        } else {
            categoryStr = category.toString();
        }


        String newColName = '$currentPrefix$sep$categoryStr';
        // Ensure new column name is unique if it already exists
        if (resultDf.hasColumn(newColName)) {
            int suffix = 1;
            String tempName = newColName;
            while(resultDf.hasColumn(tempName)){
                tempName = '${newColName}_$suffix';
                suffix++;
            }
            newColName = tempName;
        }


        List<int> dummyValues = [];
        for (var val in originalSeries.data) {
          if (category == replaceMissingValueWith) { // This is the NA dummy column
            dummyValues.add(val == replaceMissingValueWith ? 1 : 0);
          } else {
            dummyValues.add(val == category ? 1 : 0);
          }
        }
        resultDf.addColumn(newColName, defaultValue: dummyValues);
      }
      originalColumnsToDrop.add(colName);
    }

    for (var colNameToDrop in originalColumnsToDrop) {
      resultDf.drop(colNameToDrop);
    }

    return resultDf;
  }
}