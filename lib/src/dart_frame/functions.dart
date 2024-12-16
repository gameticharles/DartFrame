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

  /// Replaces occurrences of old value with new value in all columns of the DataFrame.
  ///
  /// - If [matchCase] is true, replacements are case-sensitive.
  void replace(dynamic oldValue, dynamic newValue, {bool matchCase = true}) {
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

  /// Fills missing values in the DataFrame with the specified value.
  void fillna(dynamic value) {
    for (var i = 0; i < _data.length; i++) {
      for (var j = 0; j < _data[i].length; j++) {
        if (_data[i][j] == null) {
          _data[i][j] = value;
        }
      }
    }
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
  // DataFrame structure() {
  //   var summaryData = <List<dynamic>>[];

  //   for (var column in _columns) {
  //     var columnData = this[column];
  //     var typeCounts = _analyzeColumnTypes(columnData);
  //     var columnType = typeCounts.keys.length == 1
  //         ? typeCounts.keys.first.toString() // Single type
  //         : 'Mixed'; // Default to 'Mixed' if multiple types
  //     var hasMixedTypes = _hasMixedTypes(typeCounts);

  //     var row = [
  //       column,
  //       columnType,
  //       _countNullValues(columnData),
  //       hasMixedTypes
  //     ];
  //     summaryData.add(row);
  //   }

  //   var columnNames = ['Column Name', 'Data Type', 'Null Count', 'Mixed Types'];

  //   return DataFrame(columns: columnNames, data: summaryData);
  // }

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

    return DataFrame(columns: columnNames, data: summaryData);
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

    for (var row in _data) {
      if (defaultValue.length == _data.length) {
        row.add(defaultValue[_data.indexOf(row)]);
      } else if (defaultValue.length != _data.length) {
        // the add the all the elements of the default value to the row
        // and the remaining becomes null
        row.add(defaultValue[_data.indexOf(row) < _data.length
            ? _data.indexOf(row)
            : defaultValue]);
      } else {
        if (defaultValue == null) {
          row.add(null);
        } else {
          row.add(defaultValue);
        }
      }
    }
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
}
