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
        if (newData[i][colIdx] == null) {
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
        final nullCount = subsetValues.where((v) => v == null).length;

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
        final nullCount = columnData.where((v) => v == null).length;

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
  Map<dynamic, int> valueCounts(String column) {
    int columnIndex = _columns.indexOf(column);
    if (columnIndex == -1) {
      throw ArgumentError('Column $column does not exist.');
    }

    Map<dynamic, int> counts = {};
    for (var row in _data) {
      var key = row[columnIndex];
      counts[key] = (counts[key] ?? 0) + 1;
    }

    return counts;
  }

  /// Summarizes the structure of the DataFrame.
  DataFrame structure() {
    var summaryData = <List<dynamic>>[];

    for (var column in _columns) {
      var columnData = this[column];
      var columnType = _analyzeColumnTypes(columnData);

      var row = [
        column,
        columnType,
        columnType.length > 1,
        _countNullValues(columnData),
      ];
      summaryData.add(row);
    }

    var columnNames = ['Column Name', 'Data Type', 'Mixed Types', 'Null Count'];

    return DataFrame(columns: columnNames, summaryData);
  }

  /// Analyzes the data types within a column.
  Map<Type, int> _analyzeColumnTypes(Series columnData) {
    var typeCounts = <Type, int>{};
    for (var value in columnData.data) {
      if (value != null) {
        var valueType = value.runtimeType;
        typeCounts[valueType] = (typeCounts[valueType] ?? 0) + 1;
      }
    }
    return typeCounts;
  }

  /// Counts null values in a column.
  int _countNullValues(Series columnData) {
    // ignore: prefer_void_to_null
    return columnData.data.whereType<Null>().length;
  }

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

  /// Concatenates two DataFrames along the axis specified by 'axis'.
  ///
  /// Parameters:
  /// - other: The DataFrame to concatenate with this DataFrame.
  /// - axis (Optional): The axis along which to concatenate.
  ///   * 0 (default): Concatenates rows (appends DataFrames vertically)
  ///   * 1: Concatenates columns (joins DataFrames side-by-side)
  DataFrame concatenate(DataFrame other, {int axis = 0}) {
    switch (axis) {
      case 0: // Vertical Concatenation
        if (columns.length != other.columns.length) {
          throw Exception(
              'DataFrames must have the same columns for vertical concatenation.');
        }
        var newData = List.from(_data)..addAll(other.rows);
        return DataFrame._(columns, newData);
      case 1: // Horizontal Concatenation
        List<dynamic> newColumns = List.from(columns)..addAll(other.columns);
        List<dynamic> newData = [];

        // Assume rows have the same length and structure
        for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
          newData.add([..._data[rowIndex], ...other._data[rowIndex]]);
        }

        return DataFrame._(newColumns, newData);
      default:
        throw ArgumentError(
            'Invalid axis. Supported axes are 0 (vertical) or 1 (horizontal).');
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
      if (row[columnIndex] == null) {
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

  /// Returns the number of rows in the DataFrame.
  int get rowCount => _data.length;

  /// Returns the number of columns in the DataFrame.
  int get columnCount => _columns.length;

  /// Returns the shape/dimension of the DataFrame as a list `[rows, columns]`.
  List<int> get dimension => [rowCount, columnCount];

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
  ///   - `other`: The DataFrame to join with
  ///   - `how`: Type of join ('inner', 'left', 'right', 'outer', 'cross')
  ///   - `leftOn`: Column(s) from the left DataFrame to join on
  ///   - `rightOn`: Column(s) from the right DataFrame to join on
  ///   - `suffixes`: Suffixes to apply to overlapping column names
  DataFrame join(
    DataFrame other, {
    String how = 'inner',
    dynamic leftOn,
    dynamic rightOn,
    List<String> suffixes = const ['_x', '_y'],
  }) {
    // Handle different join types
    if (how == 'cross') {
      return _crossJoin(other, suffixes);
    }

    // Convert single column to list
    final List<String> leftCols = leftOn is String ? [leftOn] : leftOn;
    final List<String> rightCols = rightOn is String ? [rightOn] : rightOn;

    if (leftCols.length != rightCols.length) {
      throw ArgumentError(
          'left_on and right_on must have the same number of columns');
    }

    // Validate columns
    for (var col in leftCols) {
      if (!hasColumn(col)) {
        throw ArgumentError('Left column $col does not exist');
      }
    }

    for (var col in rightCols) {
      if (!other.hasColumn(col)) {
        throw ArgumentError('Right column $col does not exist');
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
    switch (how) {
      case 'inner':
        for (var leftRow in _data) {
          final key = leftIndices.map((idx) => leftRow[idx]).toList();
          if (rightMap.containsKey(key)) {
            for (var rightRow in rightMap[key]!) {
              newData.add(_joinRows(
                  other, leftRow, rightRow, leftCols, rightCols, suffixes));
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
            }
          } else {
            // Add left row with nulls for right columns
            newData.add(_joinRowsWithNull(
                leftRow, true, leftCols, rightCols, other._columns, suffixes));
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
            }
          } else {
            // Add right row with nulls for left columns
            newData.add(_joinRowsWithNull(
                rightRow, false, leftCols, rightCols, _columns, suffixes));
          }
        }
        break;

      case 'outer':
        // First add all inner and left joins
        final processedRightKeys = <List<dynamic>>{};

        for (var leftRow in _data) {
          final key = leftIndices.map((idx) => leftRow[idx]).toList();
          if (rightMap.containsKey(key)) {
            for (var rightRow in rightMap[key]!) {
              newData.add(_joinRows(
                  other, leftRow, rightRow, leftCols, rightCols, suffixes));
            }
            processedRightKeys.add(key);
          } else {
            // Add left row with nulls for right columns
            newData.add(_joinRowsWithNull(
                leftRow, true, leftCols, rightCols, other._columns, suffixes));
          }
        }

        // Then add right joins that weren't processed
        for (var entry in rightMap.entries) {
          if (!processedRightKeys.contains(entry.key)) {
            for (var rightRow in entry.value) {
              newData.add(_joinRowsWithNull(
                  rightRow, false, leftCols, rightCols, _columns, suffixes));
            }
          }
        }
        break;

      default:
        throw ArgumentError(
            'Invalid join type. Supported types are: inner, left, right, outer, cross');
    }

    return DataFrame._(newColumns, newData);
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

  /// Creates bins from a continuous column.
  ///
  /// Parameters:
  ///   - `column`: The column to bin
  ///   - `bins`: Number of bins or list of bin edges
  ///   - `labels`: Optional labels for the bins
  ///   - `newColumn`: Name for the new column with bin labels
  DataFrame bin(String column, dynamic bins,
      {List<dynamic>? labels, String? newColumn}) {
    final columnIndex = _columns.indexOf(column);
    if (columnIndex == -1) {
      throw ArgumentError('Column $column does not exist');
    }

    final columnData = _data.map((row) => row[columnIndex]).toList();
    final numericData = columnData.whereType<num>().toList();

    if (numericData.length != columnData.length) {
      throw ArgumentError(
          'Column must contain only numeric values for binning');
    }

    // Determine bin edges
    List<num> binEdges;
    if (bins is int) {
      // Create equally spaced bins
      final min = numericData.reduce((a, b) => a < b ? a : b);
      final max = numericData.reduce((a, b) => a > b ? a : b);
      final step = (max - min) / bins;

      binEdges = List.generate(bins + 1, (i) => min + i * step);
    } else if (bins is List<num>) {
      binEdges = bins;
    } else {
      throw ArgumentError(
          'Bins must be an integer or a list of numeric values');
    }

    // Validate labels if provided
    if (labels != null && labels.length != binEdges.length - 1) {
      throw ArgumentError('Number of labels must match number of bins');
    }

    // Assign data to bins
    final binIndices = <int>[];
    for (var value in numericData) {
      int binIndex = -1;
      for (var i = 0; i < binEdges.length - 1; i++) {
        if (value >= binEdges[i] &&
            (i == binEdges.length - 2
                ? value <= binEdges[i + 1]
                : value < binEdges[i + 1])) {
          binIndex = i;
          break;
        }
      }
      binIndices.add(binIndex);
    }

    // Create new column with bin labels
    final binLabels = labels ??
        List.generate(
            binEdges.length - 1, (i) => '${binEdges[i]}-${binEdges[i + 1]}');

    final newColumnName = newColumn ?? '${column}_bins';
    final newData = _data
        .asMap()
        .map((i, row) {
          final newRow = List<dynamic>.from(row);
          final binIndex = binIndices[i];
          newRow.add(binIndex >= 0 ? binLabels[binIndex] : null);
          return MapEntry(i, newRow);
        })
        .values
        .toList();

    final newColumns = List<dynamic>.from(_columns)..add(newColumnName);

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

  /// Creates a pivot table from the DataFrame.
  ///
  /// Parameters:
  ///   - `index`: Column to use as the pivot table index
  ///   - `columns`: Column to use as the pivot table columns
  ///   - `values`: Column to use as the pivot table values
  ///   - `aggFunc`: Aggregation function to apply which includes mean, sum, count, min, max (default: 'mean')
  DataFrame pivot(String index, String columns, String values,
      {String aggFunc = 'mean'}) {
    if (!hasColumn(index) || !hasColumn(columns) || !hasColumn(values)) {
      throw ArgumentError('All specified columns must exist in the DataFrame');
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

        if (values.isEmpty) {
          rowData.add(null);
          continue;
        }

        // Apply aggregation function
        switch (aggFunc) {
          case 'mean':
            if (values.every((v) => v is num)) {
              final sum =
                  values.fold<num>(0, (prev, val) => prev + (val as num));
              rowData.add(sum / values.length);
            } else {
              rowData.add(null);
            }
            break;

          case 'sum':
            if (values.every((v) => v is num)) {
              final sum =
                  values.fold<num>(0, (prev, val) => prev + (val as num));
              rowData.add(sum);
            } else {
              rowData.add(null);
            }
            break;

          case 'count':
            rowData.add(values.length);
            break;

          case 'min':
            if (values.every((v) => v is num)) {
              rowData.add(values.cast<num>().reduce(min));
            } else {
              rowData.add(null);
            }
            break;

          case 'max':
            if (values.every((v) => v is num)) {
              rowData.add(values.cast<num>().reduce(max));
            } else {
              rowData.add(null);
            }
            break;

          default:
            throw ArgumentError('Unsupported aggregation function: $aggFunc');
        }
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
  ///   - `row`: Column name to use for the rows
  ///   - `column`: Column name to use for the columns
  ///   - `values`: Optional column name to aggregate
  ///   - `aggfunc`: Aggregation function to use ('count', 'sum', 'mean', 'min', 'max')
  DataFrame crosstab(String row, String column,
      {String? values, String aggfunc = 'count'}) {
    if (!hasColumn(row)) {
      throw ArgumentError('Row column $row does not exist');
    }

    if (!hasColumn(column)) {
      throw ArgumentError('Column column $column does not exist');
    }

    if (values != null && !hasColumn(values)) {
      throw ArgumentError('Values column $values does not exist');
    }

    // Get unique values for rows and columns
    final rowValues = this[row].unique().data;
    final columnValues = this[column].unique().data;

    // Create new column names
    final newColumns = <dynamic>[row, ...columnValues];

    // Get indices for faster access
    final rowIdx = _columns.indexOf(row);
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

    for (var rowValue in rowValues) {
      final rowData = <dynamic>[rowValue];

      for (var colValue in columnValues) {
        final cellValues = grouped[rowValue]?[colValue] ?? [];

        if (cellValues.isEmpty) {
          rowData.add(0); // Default value for empty cells
          continue;
        }

        // Apply aggregation function
        switch (aggfunc.toLowerCase()) {
          case 'count':
            rowData.add(cellValues.length);
            break;

          case 'sum':
            if (cellValues.every((v) => v is num)) {
              rowData.add(
                  cellValues.fold<num>(0, (prev, val) => prev + (val as num)));
            } else {
              rowData.add(null);
            }
            break;

          case 'mean':
            if (cellValues.every((v) => v is num)) {
              final sum =
                  cellValues.fold<num>(0, (prev, val) => prev + (val as num));
              rowData.add(sum / cellValues.length);
            } else {
              rowData.add(null);
            }
            break;

          case 'min':
            if (cellValues.every((v) => v is num)) {
              rowData.add(cellValues.cast<num>().reduce(min));
            } else {
              rowData.add(null);
            }
            break;

          case 'max':
            if (cellValues.every((v) => v is num)) {
              rowData.add(cellValues.cast<num>().reduce(max));
            } else {
              rowData.add(null);
            }
            break;

          default:
            throw ArgumentError('Unsupported aggregation function: $aggfunc');
        }
      }

      crossTabData.add(rowData);
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
}
