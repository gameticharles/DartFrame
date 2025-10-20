part of 'data_frame.dart';

extension DataFrameFunctions on DataFrame {
  /// Selects a subset of columns from the DataFrame by their names.
  ///
  /// Creates a new DataFrame containing only the specified columns, in the order they are listed.
  ///
  /// Parameters:
  /// - `columnNames`: A `List<String>` of column names to select.
  ///
  /// Returns:
  /// A new `DataFrame` with the selected columns.
  ///
  /// Throws:
  /// - `ArgumentError` if any of the specified column names do not exist in the DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Name': 'Alice', 'Age': 30, 'City': 'New York'},
  ///   {'Name': 'Bob', 'Age': 25, 'City': 'Los Angeles'},
  /// ]);
  ///
  /// // Select 'Name' and 'City' columns
  /// var selectedDf = df.select(['Name', 'City']);
  /// print(selectedDf);
  /// // Output:
  /// //       Name         City
  /// // 0    Alice     New York
  /// // 1      Bob  Los Angeles
  /// ```
  DataFrame select(List<String> columnNames) {
    final List<int> indices = [];
    for (String name in columnNames) {
      int index = _columns.indexOf(name);
      if (index == -1) {
        throw ArgumentError('Column "$name" not found in DataFrame.');
      }
      indices.add(index);
    }

    // Create new data by selecting columns for each row
    final selectedData = _data.map((row) {
      return indices.map((index) => row[index]).toList();
    }).toList();

    return DataFrame._(List<String>.from(columnNames), selectedData,
        index: index);
  }

  /// Selects a subset of columns from the DataFrame by their integer indices.
  ///
  /// Creates a new DataFrame containing only the columns at the specified indices,
  /// in the order they are listed.
  ///
  /// Parameters:
  /// - `columnIndices`: A `List<int>` of column indices to select.
  ///
  /// Returns:
  /// A new `DataFrame` with the selected columns.
  ///
  /// Throws:
  /// - `RangeError` if any index is out of bounds.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Name': 'Alice', 'Age': 30, 'City': 'New York'},
  ///   {'Name': 'Bob', 'Age': 25, 'City': 'Los Angeles'},
  /// ]);
  ///
  /// // Select columns at index 0 ('Name') and 2 ('City')
  /// var selectedDf = df.selectByIndex([0, 2]);
  /// print(selectedDf);
  /// // Output:
  /// //       Name         City
  /// // 0    Alice     New York
  /// // 1      Bob  Los Angeles
  /// ```
  DataFrame selectByIndex(List<int> columnIndices) {
    final selectedColumnNames = columnIndices.map((index) {
      if (index < 0 || index >= _columns.length) {
        throw RangeError.index(index, _columns, 'Column index out of bounds');
      }
      return _columns[index];
    }).toList();

    final selectedData = _data.map((row) {
      return columnIndices.map((index) => row[index]).toList();
    }).toList();
    return DataFrame._(selectedColumnNames, selectedData, index: index);
  }

  /// Selects a subset of rows from the DataFrame by their integer indices.
  ///
  /// Creates a new DataFrame containing only the rows at the specified indices,
  /// in the order they are listed. The original column structure is preserved.
  ///
  /// Parameters:
  /// - `rowIndices`: A `List<int>` of row indices to select.
  ///
  /// Returns:
  /// A new `DataFrame` with the selected rows.
  ///
  /// Throws:
  /// - `RangeError` if any index is out of bounds.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Name': 'Alice', 'Age': 30},
  ///   {'Name': 'Bob', 'Age': 25},
  ///   {'Name': 'Charlie', 'Age': 35},
  /// ], index: ['r1', 'r2', 'r3']);
  ///
  /// // Select rows at index 0 and 2
  /// var selectedRowsDf = df.selectRowsByIndex([0, 2]);
  /// print(selectedRowsDf);
  /// // Output:
  /// //         Name  Age
  /// // r1     Alice   30
  /// // r3   Charlie   35
  /// ```
  DataFrame selectRowsByIndex(List<int> rowIndices) {
    final selectedData = rowIndices.map((idx) {
      if (idx < 0 || idx >= _data.length) {
        throw RangeError.index(idx, _data, 'Row index out of bounds');
      }
      return List<dynamic>.from(_data[idx]); // Create a copy of the row
    }).toList();
    final selectedIndex = rowIndices.map((idx) => index[idx]).toList();
    return DataFrame._(List<dynamic>.from(_columns), selectedData,
        index: selectedIndex);
  }

  /// Filters rows from the DataFrame based on a predicate function.
  ///
  /// The `condition` function takes a `Map<dynamic, dynamic>` representing a row
  /// (where keys are column names and values are cell values) and should return `true`
  /// to keep the row, or `false` to discard it.
  ///
  /// Returns:
  /// A new `DataFrame` containing only the rows for which the `condition` evaluated to `true`.
  /// The original DataFrame is not modified.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Name': 'Alice', 'Age': 30, 'City': 'New York'},
  ///   {'Name': 'Bob', 'Age': 25, 'City': 'Los Angeles'},
  ///   {'Name': 'Charlie', 'Age': 35, 'City': 'New York'},
  /// ]);
  ///
  /// // Filter for people older than 28
  /// var olderDf = df.filter((row) => (row['Age'] as int) > 28);
  /// print(olderDf);
  /// // Output:
  /// //         Name  Age      City
  /// // 0      Alice   30  New York
  /// // 2    Charlie   35  New York
  ///
  /// // Filter for people living in New York
  /// var nyDf = df.filter((row) => row['City'] == 'New York');
  /// print(nyDf);
  /// // Output:
  /// //         Name  Age      City
  /// // 0      Alice   30  New York
  /// // 2    Charlie   35  New York
  /// ```
  DataFrame filter(bool Function(Map<dynamic, dynamic> row) condition) {
    final List<List<dynamic>> filteredData = [];
    final List<dynamic> filteredIndex = [];

    for (int i = 0; i < _data.length; i++) {
      final rowList = _data[i];
      final rowMap = Map<dynamic, dynamic>.fromIterables(_columns, rowList);
      if (condition(rowMap)) {
        filteredData.add(List<dynamic>.from(rowList)); // Add a copy
        filteredIndex.add(index[i]);
      }
    }
    return DataFrame._(List<dynamic>.from(_columns), filteredData,
        index: filteredIndex);
  }

  /// Sorts the DataFrame by the values in one or more specified columns.
  ///
  /// This method modifies the DataFrame in-place.
  ///
  /// Parameters:
  /// - `column`: A `String` representing the name of the column to sort by.
  ///   (Note: Sorting by multiple columns is not yet implemented in this version.)
  /// - `ascending`: A `bool` indicating the sort order.
  ///   If `true` (default), sorts in ascending order.
  ///   If `false`, sorts in descending order.
  ///
  /// Throws:
  /// - `ArgumentError` if the specified `column` does not exist.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Name': 'Bob', 'Age': 25},
  ///   {'Name': 'Alice', 'Age': 30},
  ///   {'Name': 'Charlie', 'Age': 22},
  /// ]);
  ///
  /// // Sort by Age in ascending order
  /// df.sort('Age');
  /// print(df);
  /// // Output:
  /// //         Name  Age
  /// // 2    Charlie   22
  /// // 0        Bob   25
  /// // 1      Alice   30
  ///
  /// // Sort by Name in descending order
  /// df.sort('Name', ascending: false);
  /// print(df);
  /// // Output:
  /// //         Name  Age
  /// // 2    Charlie   22
  /// // 0        Bob   25
  /// // 1      Alice   30
  /// ```
  void sort(String column, {bool ascending = true}) {
    final columnIndex = _columns.indexOf(column);
    if (columnIndex == -1) {
      throw ArgumentError('Column "$column" does not exist.');
    }

    // Pair data with original index to maintain stability for index
    var indexedData = _data
        .asMap()
        .entries
        .map((entry) => MapEntry(entry.key, entry.value))
        .toList();

    indexedData.sort((aPair, bPair) {
      final aValue = aPair.value[columnIndex];
      final bValue = bPair.value[columnIndex];

      if (aValue == null && bValue == null) return 0;
      if (aValue == null) {
        return ascending
            ? -1
            : 1; // Nulls first in ascending, last in descending
      }
      if (bValue == null) {
        return ascending
            ? 1
            : -1; // Nulls first in ascending, last in descending
      }

      int comparison;
      if (aValue is Comparable && bValue is Comparable) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }
      return ascending ? comparison : -comparison;
    });

    // Update data and index according to sorted order
    _data = indexedData.map((pair) => pair.value).toList();
    index = indexedData.map((pair) => index[pair.key]).toList();
  }

  /// Returns the first `n` rows of the DataFrame as a new DataFrame.
  ///
  /// If `n` is greater than the number of rows, all rows are returned.
  ///
  /// Parameters:
  /// - `n`: The number of rows to select from the beginning. Must be non-negative.
  ///
  /// Returns:
  /// A new `DataFrame` containing the first `n` rows.
  ///
  /// Throws:
  /// - `ArgumentError` if `n` is negative.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1}, {'A': 2}, {'A': 3}, {'A': 4}, {'A': 5}
  /// ]);
  ///
  /// var firstThree = df.head(3);
  /// print(firstThree);
  /// // Output:
  /// //    A
  /// // 0  1
  /// // 1  2
  /// // 2  3
  /// ```
  DataFrame head([int n=5]) {
    if (n < 0) {
      throw ArgumentError('Number of rows for head must be non-negative.');
    }
    final count = n > _data.length ? _data.length : n;
    final headData =
        _data.take(count).map((row) => List<dynamic>.from(row)).toList();
    final headIndex = index.take(count).toList();
    return DataFrame._(List<dynamic>.from(_columns), headData,
        index: headIndex);
  }

  /// Returns the last `n` rows of the DataFrame as a new DataFrame.
  ///
  /// If `n` is greater than the number of rows, all rows are returned.
  ///
  /// Parameters:
  /// - `n`: The number of rows to select from the end. Must be non-negative.
  ///
  /// Returns:
  /// A new `DataFrame` containing the last `n` rows.
  ///
  /// Throws:
  /// - `ArgumentError` if `n` is negative.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1}, {'A': 2}, {'A': 3}, {'A': 4}, {'A': 5}
  /// ]);
  ///
  /// var lastTwo = df.tail(2);
  /// print(lastTwo);
  /// // Output:
  /// //    A
  /// // 3  4
  /// // 4  5
  /// ```
  DataFrame tail(int n) {
    if (n < 0) {
      throw ArgumentError('Number of rows for tail must be non-negative.');
    }
    final count = n > _data.length ? _data.length : n;
    final startIndex = _data.length - count;
    final tailData =
        _data.skip(startIndex).map((row) => List<dynamic>.from(row)).toList();
    final tailIndex = index.skip(startIndex).toList();
    return DataFrame._(List<dynamic>.from(_columns), tailData,
        index: tailIndex);
  }

  /// Returns a DataFrame of the same shape with boolean values indicating
  /// where data is missing.
  ///
  /// A value is considered missing if it is `null` or if it matches the
  /// DataFrame's `replaceMissingValueWith` property (if set).
  ///
  /// Returns:
  /// A `DataFrame` where each cell contains `true` if the corresponding cell
  /// in the original DataFrame is missing, and `false` otherwise.
  /// The resulting DataFrame retains the same index and column labels.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': null, 'C': 'ok'},
  ///   {'A': null, 'B': 2, 'C': 'fine'},
  /// ], replaceMissingValueWith: 'N/A');
  /// df.updateCell('C', 1, 'N/A'); // Mark 'fine' as missing using placeholder
  ///
  /// var isMissingDf = df.isna();
  /// print(isMissingDf);
  /// // Output:
  /// //        A      B      C
  /// // 0  false   true  false
  /// // 1   true  false   true
  /// ```
  DataFrame isna() {
    List<List<dynamic>> newData = [];

    for (int i = 0; i < _data.length; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < _columns.length; j++) {
        bool isMissing = _data[i][j] == null ||
            (replaceMissingValueWith != null &&
                _data[i][j] == replaceMissingValueWith);
        row.add(isMissing);
      }
      newData.add(row);
    }

    return DataFrame(
      newData,
      columns: List<dynamic>.from(_columns), // Ensure columns are copied
      index: List<dynamic>.from(index), // Ensure index is copied
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: _missingDataIndicator,
    );
  }

  /// Returns a DataFrame of the same shape with boolean values indicating
  /// where data is **not** missing.
  ///
  /// A value is considered not missing if it is not `null` and does not match
  /// the DataFrame's `replaceMissingValueWith` property (if set).
  ///
  /// Returns:
  /// A `DataFrame` where each cell contains `true` if the corresponding cell
  /// in the original DataFrame is not missing, and `false` otherwise.
  /// The resulting DataFrame retains the same index and column labels.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': null, 'C': 'ok'},
  ///   {'A': null, 'B': 2, 'C': 'fine'},
  /// ], replaceMissingValueWith: 'N/A');
  /// df.updateCell('C', 1, 'N/A'); // Mark 'fine' as missing
  ///
  /// var isNotMissingDf = df.notna();
  /// print(isNotMissingDf);
  /// // Output:
  /// //        A      B      C
  /// // 0   true  false   true
  /// // 1  false   true  false
  /// ```
  DataFrame notna() {
    List<List<dynamic>> newData = [];

    for (int i = 0; i < _data.length; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < _columns.length; j++) {
        bool isNotMissing = _data[i][j] != null &&
            (replaceMissingValueWith == null ||
                _data[i][j] != replaceMissingValueWith);
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
        final nullCount =
            subsetValues.where((v) => v == replaceMissingValueWith).length;

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
        final nullCount =
            columnData.where((v) => v == replaceMissingValueWith).length;

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

  /// Replaces occurrences of `oldValue` with `newValue` in all cells of the DataFrame.
  ///
  /// This method modifies the DataFrame **in-place**.
  ///
  /// Parameters:
  /// - `oldValue`: The `dynamic` value to be replaced.
  /// - `newValue`: The `dynamic` value to replace `oldValue` with.
  /// - `matchCase`: A `bool` indicating whether the replacement should be case-sensitive
  ///   when `oldValue` and cell values are strings. Defaults to `true`.
  ///   If `false`, string comparison is case-insensitive.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 'apple', 'B': 10},
  ///   {'A': 'Apple', 'B': 20},
  ///   {'A': 'banana', 'B': 10},
  /// ]);
  ///
  /// // Case-sensitive replacement
  /// df.replaceInPlace('apple', 'orange');
  /// print(df);
  /// // Output:
  /// //         A   B
  /// // 0  orange  10
  /// // 1   Apple  20
  /// // 2  banana  10
  ///
  /// // Case-insensitive replacement
  /// df.replaceInPlace('apple', 'apricot', matchCase: false);
  /// print(df);
  /// // Output:
  /// //         A   B
  /// // 0  orange  10 // Not 'apricot' because 'orange' != 'apple' (case-insensitive)
  /// // 1 apricot  20 // 'Apple' becomes 'apricot'
  /// // 2  banana  10
  ///
  /// // Replace numeric value
  /// df.replaceInPlace(10, 100);
  /// print(df);
  /// // Output:
  /// //         A    B
  /// // 0  orange  100
  /// // 1 apricot   20
  /// // 2  banana  100
  /// ```
  void replaceInPlace(dynamic oldValue, dynamic newValue,
      {bool matchCase = true}) {
    for (var row in _data) {
      for (var i = 0; i < row.length; i++) {
        if (row[i] == oldValue) {
          row[i] = newValue;
        } else if (!matchCase &&
            row[i] is String &&
            oldValue is String &&
            (row[i] as String).toLowerCase() == oldValue.toLowerCase()) {
          row[i] = newValue;
        }
      }
    }
  }

  /// Replaces occurrences of `oldValue` with `newValue` in the DataFrame.
  ///
  /// Creates a new DataFrame with the replacements applied. The original DataFrame is not modified.
  ///
  /// Parameters:
  /// - `oldValue`: The `dynamic` value to be replaced.
  /// - `newValue`: The `dynamic` value to replace `oldValue` with.
  /// - `columns`: An optional `List<String>` of column names to apply the replacement to.
  ///   If `null` (default), replacement is performed across all columns.
  /// - `regex`: A `bool` indicating whether `oldValue` (if it's a String) should be
  ///   interpreted as a regular expression. Defaults to `false`.
  /// - `matchCase`: A `bool` for case-sensitive replacement. Defaults to `true`.
  ///   If `regex` is `true`, this controls the `caseSensitive` property of the `RegExp`.
  ///   If `regex` is `false` and `oldValue` is a String, this controls direct string comparison.
  ///
  /// Returns:
  /// A new `DataFrame` with the replacements applied.
  ///
  /// Throws:
  /// - `ArgumentError` if a specified column in `columns` does not exist.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Product': 'Apple A', 'Category': 'Fruit'},
  ///   {'Product': 'Banana B', 'Category': 'Fruit'},
  ///   {'Product': 'Carrot C', 'Category': 'Vegetable'},
  /// ]);
  ///
  /// // Replace 'Fruit' with 'F' in 'Category' column
  /// var dfReplaced = df.replace('Fruit', 'F', columns: ['Category']);
  /// print(dfReplaced);
  ///
  /// // Replace using regex (e.g., remove trailing letter) in 'Product'
  /// var dfRegex = df.replace(r'\s[A-Z]$', '', columns: ['Product'], regex: true);
  /// print(dfRegex);
  /// ```
  DataFrame replace(dynamic oldValue, dynamic newValue,
      {List<String>? columns, bool regex = false, bool matchCase = true}) {
    final columnsToReplace = columns?.map((c) => c.toString()).toList() ??
        _columns.map((c) => c.toString()).toList();
    final List<int> columnIndices = [];

    for (String colName in columnsToReplace) {
      int colIdx = _columns.indexOf(colName);
      if (colIdx == -1) {
        throw ArgumentError('Column $colName does not exist');
      }
      columnIndices.add(colIdx);
    }

    final newData = _data.map((row) => List<dynamic>.from(row)).toList();
    final newIndex = List<dynamic>.from(index);

    RegExp? pattern;
    if (regex && oldValue is String) {
      pattern = RegExp(oldValue, caseSensitive: matchCase);
    }

    for (var i = 0; i < newData.length; i++) {
      for (var colIdx in columnIndices) {
        final currentValue = newData[i][colIdx];

        if (currentValue == null && oldValue == null) {
          // Replacing null with something
          newData[i][colIdx] = newValue;
          continue;
        }
        if (currentValue == null) {
          continue; // Don't attempt replacement if cell is null and oldValue isn't
        }

        if (pattern != null && currentValue is String) {
          // Regex replacement
          newData[i][colIdx] =
              currentValue.replaceAll(pattern, newValue.toString());
        } else {
          // Direct replacement
          if (currentValue == oldValue) {
            newData[i][colIdx] = newValue;
          } else if (!matchCase &&
              currentValue is String &&
              oldValue is String &&
              currentValue.toLowerCase() == oldValue.toLowerCase()) {
            newData[i][colIdx] = newValue;
          }
        }
      }
    }
    return DataFrame._(List<dynamic>.from(_columns), newData, index: newIndex);
  }

  /// Casts columns of the DataFrame to specified data types.
  ///
  /// Creates a new DataFrame with columns converted to the target types.
  /// The original DataFrame is not modified.
  ///
  /// Parameters:
  /// - `types`: A `Map<String, String>` where keys are column names and values are
  ///   the target data type names. Supported type names are:
  ///   - `'int'`: Converts to `int`.
  ///   - `'double'`: Converts to `double`.
  ///   - `'string'`: Converts to `String`.
  ///   - `'bool'`: Converts to `bool`. For strings, "true" (case-insensitive) becomes `true`,
  ///     others (like "false", "0", non-empty strings) might become `false` or throw
  ///     depending on underlying parsing. For numbers, 0 becomes `false`, others `true`.
  ///
  /// Returns:
  /// A new `DataFrame` with the specified columns cast to new types.
  ///
  /// Throws:
  /// - `ArgumentError` if a specified column name does not exist.
  /// - `ArgumentError` if an unsupported `typeName` is provided.
  /// - `FormatException` or `TypeError` may occur during parsing if a value cannot be
  ///   converted to the target type (e.g., parsing "abc" as `int`).
  ///   In such cases, the original value is currently kept in the cell.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': '10', 'B': '20.5', 'C': 'true', 'D': 'text'},
  ///   {'A': '12', 'B': '30.0', 'C': 'FALSE', 'D': 'data'},
  /// ]);
  ///
  /// var typedDf = df.astype({
  ///   'A': 'int',
  ///   'B': 'double',
  ///   'C': 'bool',
  ///   'D': 'string' // No change, but can be explicit
  /// });
  /// print(typedDf.rows[0]); // Example: [10, 20.5, true, text]
  /// print(typedDf.rows[1][2].runtimeType); // Example: bool
  /// ```
  DataFrame astype(Map<String, String> types) {
    final newData = _data.map((row) => List<dynamic>.from(row)).toList();
    final newIndex = List<dynamic>.from(index);

    types.forEach((colName, typeName) {
      final colIdx = _columns.indexOf(colName);
      if (colIdx == -1) {
        throw ArgumentError('Column $colName does not exist');
      }

      for (var i = 0; i < newData.length; i++) {
        final value = newData[i][colIdx];
        if (value == null || value == replaceMissingValueWith) {
          // Skip missing values
          newData[i][colIdx] =
              replaceMissingValueWith; // Ensure missing remains consistent
          continue;
        }

        try {
          switch (typeName.toLowerCase()) {
            case 'int':
              if (value is String) {
                newData[i][colIdx] = int.tryParse(value) ?? value;
              } else if (value is num) {
                newData[i][colIdx] = value.toInt();
              } else {
                newData[i][colIdx] = int.tryParse(value.toString()) ?? value;
              }
              break;
            case 'double':
              if (value is String) {
                newData[i][colIdx] = double.tryParse(value) ?? value;
              } else if (value is num) {
                newData[i][colIdx] = value.toDouble();
              } else {
                newData[i][colIdx] = double.tryParse(value.toString()) ?? value;
              }
              break;
            case 'string':
              newData[i][colIdx] = value.toString();
              break;
            case 'bool':
              if (value is bool) {
                newData[i][colIdx] = value;
              } else if (value is String) {
                if (value.toLowerCase() == 'true') {
                  newData[i][colIdx] = true;
                } else if (value.toLowerCase() == 'false') {
                  newData[i][colIdx] = false;
                } else {
                  newData[i][colIdx] =
                      value; // Keep original if not 'true'/'false'
                }
              } else if (value is num) {
                newData[i][colIdx] = value != 0;
              } else {
                newData[i][colIdx] = value; // Keep original if not convertible
              }
              break;
            default:
              throw ArgumentError(
                  'Unsupported type: $typeName for column $colName. Supported types: int, double, string, bool.');
          }
        } catch (e) {
          // If conversion fails, keep the original value.
          // Consider logging the error: print('Failed to convert value "$value" in column "$colName" to $typeName: $e');
        }
      }
    });

    return DataFrame._(List<dynamic>.from(_columns), newData, index: newIndex);
  }

  /// Rounds numeric values in specified columns to a given number of decimal places.
  ///
  /// Creates a new DataFrame with rounded values. The original DataFrame is not modified.
  /// Only affects cells containing `double` values. Other types are left unchanged.
  ///
  /// Parameters:
  /// - `decimals`: The number of decimal places to round to.
  /// - `columns`: An optional `List<String>` of column names to apply rounding to.
  ///   If `null` (default), attempts to round all numeric columns.
  ///
  /// Returns:
  /// A new `DataFrame` with numeric values in the specified columns rounded.
  ///
  /// Throws:
  /// - `ArgumentError` if a specified column in `columns` does not exist.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1.2345, 2.3456, 3.4567],
  ///   'B': [10.0, 20.55, 30.123],
  ///   'C': ['text', 100, 200.789] // Mixed type column
  /// });
  ///
  /// // Round all possible numeric columns to 2 decimal places
  /// var dfRoundedAll = df.round(2);
  /// print(dfRoundedAll);
  ///
  /// // Round only column 'B' to 1 decimal place
  /// var dfRoundedB = df.round(1, columns: ['B']);
  /// print(dfRoundedB);
  /// ```
  DataFrame round(int decimals, {List<String>? columns}) {
    final columnsToRound = columns?.map((c) => c.toString()).toList() ??
        _columns.map((c) => c.toString()).toList();
    final List<int> columnIndices = [];
    for (String colName in columnsToRound) {
      int colIdx = _columns.indexOf(colName);
      if (colIdx == -1) {
        // If a specific column to round doesn't exist, it's an error.
        // If columns is null, we iterate all existing columns, so this won't be hit.
        if (columns != null) {
          throw ArgumentError('Column $colName does not exist');
        }
        continue;
      }
      columnIndices.add(colIdx);
    }

    final newData = _data.map((row) => List<dynamic>.from(row)).toList();
    final newIndex = List<dynamic>.from(index);

    for (var i = 0; i < newData.length; i++) {
      for (var colIdx in columnIndices) {
        // Ensure colIdx is valid for the current row structure,
        // though it should be if derived from _columns.
        if (colIdx < newData[i].length) {
          final value = newData[i][colIdx];
          if (value is double) {
            final factor = pow(10, decimals);
            newData[i][colIdx] = (value * factor).round() / factor;
          } else if (value is int) {
            // No rounding needed for int, but ensure it's copied correctly
            newData[i][colIdx] = value
                .toDouble(); // Consistent type for potentially rounded columns
          }
          // Non-numeric values are left as is
        }
      }
    }
    return DataFrame._(List<dynamic>.from(_columns), newData, index: newIndex);
  }

  /// **DEPRECATED**: Computes rolling window calculations on a specified column.
  ///
  /// **⚠️ DEPRECATION NOTICE**: This method is deprecated and will be removed in a future version.
  /// Use `rollingWindow()` instead for more comprehensive rolling operations that work across
  /// all columns simultaneously and provide a richer API.
  ///
  /// **Migration Guide**:
  /// ```dart
  /// // OLD (deprecated):
  /// var result = df.rolling('column', 3, 'mean');
  ///
  /// // NEW (recommended):
  /// var result = df.rollingWindow(3).mean()['column'];
  /// // or for all columns:
  /// var resultDf = df.rollingWindow(3).mean();
  /// ```
  ///
  /// This method calculates a statistic (e.g., mean, sum) over a sliding window
  /// of a fixed size along a numeric column.
  ///
  /// **Limitations compared to `rollingWindow()`**:
  /// - Only works on a single column at a time
  /// - Limited set of statistical functions
  /// - No support for correlation, covariance, or custom functions
  /// - Less efficient for multiple operations
  ///
  /// Parameters:
  /// - `column`: The `String` name of the column to perform rolling calculations on.
  ///   This column must contain numeric data.
  /// - `window`: An `int` specifying the size of the rolling window (number of observations).
  /// - `function`: A `String` indicating the aggregation function to apply to each window.
  ///   Supported functions:
  ///   - `'mean'`: Calculates the average of the values in the window.
  ///   - `'sum'`: Calculates the sum of the values in the window.
  ///   - `'min'`: Finds the minimum value in the window.
  ///   - `'max'`: Finds the maximum value in the window.
  ///   - `'std'`: Calculates the standard deviation of the values in the window.
  /// - `minPeriods`: An optional `int`. The minimum number of observations in a window
  ///   required to have a value; otherwise, the result is `null`. Defaults to `window` size.
  /// - `center`: A `bool`. If `true`, the window is centered on the current observation.
  ///   If `false` (default), the window is trailing (uses the current and previous observations).
  ///
  /// Returns:
  /// A `Series` containing the results of the rolling calculation. The Series will have
  /// the same index as the original DataFrame. The name of the Series typically indicates
  /// the operation performed (e.g., "Rolling mean of ColumnName (window=W)").
  ///
  /// Throws:
  /// - `ArgumentError` if `column` does not exist or is not numeric.
  /// - `ArgumentError` if `function` is not one of the supported types.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'Values': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  /// });
  ///
  /// // DEPRECATED: Rolling mean with window size 3
  /// var rollingMean = df.rolling('Values', 3, 'mean');
  /// print(rollingMean);
  /// // Output:
  /// // Series(name: Rolling mean of Values (window=3), index: [0, ..., 9], data: [null, null, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0])
  ///
  /// // RECOMMENDED: Use rollingWindow() instead
  /// var rollingMeanNew = df.rollingWindow(3).mean()['Values'];
  /// print(rollingMeanNew);
  /// ```
  @Deprecated(
      'Use rollingWindow() instead for comprehensive rolling operations. '
      'This method will be removed in a future version.')
  Series rolling(String column, int window, String function,
      {int? minPeriods, bool center = false}) {
    final colIdx = _columns.indexOf(column);
    if (colIdx == -1) {
      throw ArgumentError('Column "$column" does not exist.');
    }

    final columnData = _data.map((row) => row[colIdx]).toList();

    // Attempt to convert all data to num for processing, handle non-convertibles as null
    final List<num?> numData = columnData.map((e) {
      if (e is num) return e;
      if (e is String) return num.tryParse(e);
      return null; // Non-numeric or non-parsable string becomes null
    }).toList();

    if (window <= 0) {
      throw ArgumentError("Window size must be positive.");
    }
    final minObs = minPeriods ?? window;
    if (minObs <= 0) {
      throw ArgumentError("minPeriods must be positive.");
    }

    final result = List<num?>.filled(numData.length, null);

    for (var i = 0; i < numData.length; i++) {
      int start, end;

      if (center) {
        start = i -
            (window - 1) ~/
                2; // Adjust for centering: (window-1)~/2 for left, window~/2 for right
        end = i + window ~/ 2 + 1; // +1 because sublist end is exclusive
      } else {
        // Trailing window
        start = i - window + 1;
        end = i + 1; // Current element is the end of the window
      }

      // Clamp window boundaries to data boundaries
      final actualStart = max(0, start);
      final actualEnd = min(numData.length, end);

      if (actualEnd <= actualStart) {
        // Window is empty or invalid
        result[i] = null;
        continue;
      }

      final windowDataWithNulls = numData.sublist(actualStart, actualEnd);
      final List<num> windowData =
          windowDataWithNulls.whereType<num>().toList();

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
          if (windowData.length < 2) {
            // Std dev requires at least 2 points
            result[i] =
                null; // Or 0.0, depending on desired behavior for single point
            break;
          }
          final mean = windowData.reduce((a, b) => a + b) / windowData.length;
          // Sample standard deviation (N-1 denominator) is more common
          final variance =
              windowData.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
                  (windowData.length - 1);
          result[i] = sqrt(variance);
          break;
        default:
          throw ArgumentError(
              'Unsupported function: "$function". Supported: mean, sum, min, max, std.');
      }
    }

    return Series(result,
        name: 'Rolling $function of $column (window=$window)',
        index: List.from(index));
  }

  /// Renames columns in the DataFrame based on a provided mapping.
  ///
  /// This method modifies the DataFrame **in-place**.
  ///
  /// Parameters:
  /// - `columnMap`: A `Map<String, String>` where keys are current column names
  ///   and values are the new column names. Columns not present in the map
  ///   will retain their original names.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'colA': 1, 'colB': 2},
  ///   {'colA': 3, 'colB': 4}
  /// ]);
  /// print('Before rename: ${df.columns}'); // Output: [colA, colB]
  ///
  /// df.rename({'colA': 'Alpha', 'colB': 'Beta'});
  /// print('After rename: ${df.columns}'); // Output: [Alpha, Beta]
  ///
  /// df.rename({'Alpha': 'A'}); // Rename only one column
  /// print('After partial rename: ${df.columns}'); // Output: [A, Beta]
  /// ```
  void rename(Map<String, String> columnMap) {
    final newColumnNames =
        List<dynamic>.from(_columns); // Create a mutable copy
    bool changed = false;
    for (int i = 0; i < newColumnNames.length; i++) {
      String currentName = newColumnNames[i].toString();
      if (columnMap.containsKey(currentName)) {
        newColumnNames[i] = columnMap[currentName]!;
        changed = true;
      }
    }
    if (changed) {
      _columns = newColumnNames;
    }
  }

  /// Drops one or more specified columns from the DataFrame.
  ///
  /// This method modifies the DataFrame **in-place**.
  ///
  /// Parameters:
  /// - `columnsToDrop`: A `String` or a `List<String>` of column names to be dropped.
  ///
  /// Throws:
  /// - `ArgumentError` if any of the specified column names do not exist in the DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': 2, 'C': 3},
  ///   {'A': 4, 'B': 5, 'C': 6}
  /// ]);
  ///
  /// // Drop a single column
  /// df.drop('B');
  /// print(df.columns); // Output: [A, C]
  ///
  /// // Drop multiple columns
  /// var df2 = DataFrame.fromRows([{'X':1, 'Y':2, 'Z':3}]);
  /// df2.drop(['X', 'Z']);
  /// print(df2.columns); // Output: [Y]
  /// ```
  void drop(dynamic columnsToDrop) {
    List<String> colsList;
    if (columnsToDrop is String) {
      colsList = [columnsToDrop];
    } else if (columnsToDrop is List<String>) {
      colsList = columnsToDrop;
    } else {
      throw ArgumentError('columnsToDrop must be a String or List<String>');
    }

    List<int> indicesToDrop = [];
    for (String columnName in colsList) {
      int columnIndex = _columns.indexOf(columnName);
      if (columnIndex == -1) {
        throw ArgumentError('Column "$columnName" does not exist.');
      }
      indicesToDrop.add(columnIndex);
    }

    // Sort indices in descending order to avoid issues when removing by index
    indicesToDrop.sort((a, b) => b.compareTo(a));

    for (int colIdx in indicesToDrop) {
      _columns.removeAt(colIdx);
      for (var row in _data) {
        row.removeAt(colIdx);
      }
    }
  }

  /// Groups the DataFrame by the unique values in one or more specified columns.
  ///
  /// Returns a `Map` where keys are the unique group values (or a list of values if
  /// grouping by multiple columns) and values are new `DataFrame` objects, each
  /// containing the rows belonging to that group.
  ///
  /// Parameters:
  /// - `by`: A `String` (single column name) or a `List<String>` (multiple column names)
  ///   to group by.
  ///
  /// Returns:
  /// A `Map<dynamic, DataFrame>` where keys represent the unique group(s) and
  /// values are the corresponding DataFrames. If grouping by multiple columns,
  /// the key will be a `List<dynamic>` of the group values.
  ///
  /// Throws:
  /// - `ArgumentError` if any column name in `by` does not exist.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Category': 'A', 'Value': 10},
  ///   {'Category': 'B', 'Value': 20},
  ///   {'Category': 'A', 'Value': 15},
  ///   {'Category': 'B', 'Value': 25},
  /// ]);
  ///
  /// var grouped = df.groupBy('Category');
  /// grouped.forEach((key, groupDf) {
  ///   print('Category: $key');
  ///   print(groupDf);
  /// });
  /// // Output:
  /// // Category: A
  /// //   Category  Value
  /// // 0        A     10
  /// // 2        A     15
  /// // Category: B
  /// //   Category  Value
  /// // 1        B     20
  /// // 3        B     25
  ///
  /// // Group by multiple columns (conceptual)
  /// // var dfMulti = DataFrame.fromRows([
  /// //   {'Key1': 'X', 'Key2': 'M', 'Value': 1},
  /// //   {'Key1': 'Y', 'Key2': 'N', 'Value': 2},
  /// //   {'Key1': 'X', 'Key2': 'M', 'Value': 3},
  /// // ]);
  /// // var groupedMulti = dfMulti.groupBy(['Key1', 'Key2']);
  /// // groupedMulti.forEach((key, groupDf) { // key is a List, e.g., ['X', 'M']
  /// //   print('Group: $key, DataFrame: $groupDf');
  /// // });
  /// ```
  Map<dynamic, DataFrame> groupBy(dynamic by) {
    List<String> groupColumnNames;
    if (by is String) {
      groupColumnNames = [by];
    } else if (by is List<String>) {
      groupColumnNames = by;
    } else {
      throw ArgumentError('`by` must be a String or List<String>');
    }

    final List<int> groupColumnIndices = [];
    for (String colName in groupColumnNames) {
      int colIdx = _columns.indexOf(colName);
      if (colIdx == -1) {
        throw ArgumentError('Column "$colName" for groupBy does not exist.');
      }
      groupColumnIndices.add(colIdx);
    }

    final Map<dynamic, List<List<dynamic>>> groupsData = {};
    final Map<dynamic, List<dynamic>> groupsIndex = {};

    for (int i = 0; i < _data.length; i++) {
      final row = _data[i];
      dynamic groupKey;
      if (groupColumnIndices.length == 1) {
        groupKey = row[groupColumnIndices.first];
      } else {
        groupKey = groupColumnIndices.map((idx) => row[idx]).toList();
      }

      groupsData.putIfAbsent(groupKey, () => []);
      groupsData[groupKey]!.add(List<dynamic>.from(row));
      groupsIndex.putIfAbsent(groupKey, () => []);
      groupsIndex[groupKey]!.add(index[i]);
    }

    final Map<dynamic, DataFrame> result = {};
    groupsData.forEach((key, dataList) {
      result[key] = DataFrame._(
          List<dynamic>.from(_columns), // Preserve original column order
          dataList,
          index: groupsIndex[key]!,
          allowFlexibleColumns: allowFlexibleColumns,
          replaceMissingValueWith: replaceMissingValueWith,
          missingDataIndicator: _missingDataIndicator);
    });

    return result;
  }

  /// Groups the DataFrame by specified columns and then applies aggregation functions.
  ///
  /// This is a powerful method for summarizing data. It first groups rows based on unique
  /// combinations of values in the `by` columns. Then, for each group, it applies
  /// specified aggregation functions to other columns.
  ///
  /// Parameters:
  /// - `by`: A `String` (single column name) or `List<String>` (multiple column names)
  ///   to group the DataFrame by.
  /// - `agg`: A `Map<String, dynamic>` specifying the aggregations.
  ///   - Keys are the names of the columns to aggregate.
  ///   - Values are either:
  ///     - A `String` representing a built-in aggregation function:
  ///       `'mean'`, `'sum'`, `'min'`, `'max'`, `'count'`, `'std'` (standard deviation).
  ///     - A custom aggregation function `(List<dynamic> values) => dynamic` that takes
  ///       a list of values from a group's column and returns a single aggregated value.
  ///
  /// Returns:
  /// A new `DataFrame` where rows are the unique groups from `by` columns, and
  /// other columns are the results of the aggregations. Aggregated column names
  /// will be in the format `originalColumnName_aggregationFunctionName`.
  ///
  /// Throws:
  /// - `ArgumentError` if any column in `by` or `agg.keys` does not exist.
  /// - `ArgumentError` if an unsupported built-in aggregation function string is provided.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Category': 'A', 'Type': 'X', 'Sales': 100, 'Quantity': 5},
  ///   {'Category': 'B', 'Type': 'Y', 'Sales': 150, 'Quantity': 8},
  ///   {'Category': 'A', 'Type': 'X', 'Sales': 120, 'Quantity': 6},
  ///   {'Category': 'B', 'Type': 'X', 'Sales': 200, 'Quantity': 10},
  ///   {'Category': 'A', 'Type': 'Y', 'Sales': 80,  'Quantity': 4},
  /// ]);
  ///
  /// // Group by 'Category' and calculate sum of 'Sales' and mean of 'Quantity'
  /// var aggDf = df.groupByAgg('Category', {
  ///   'Sales': 'sum',
  ///   'Quantity': 'mean',
  /// });
  /// print(aggDf);
  /// // Output (order of rows A, B might vary):
  /// //   Category  Sales_sum  Quantity_mean
  /// // 0        A        300            5.0
  /// // 1        B        350            9.0
  ///
  /// // Group by 'Category' and 'Type', count 'Sales'
  /// var multiGroupDf = df.groupByAgg(['Category', 'Type'], {'Sales': 'count'});
  /// print(multiGroupDf);
  /// // Output (example, order might vary):
  /// //   Category Type  Sales_count
  /// // 0        A    X            2
  /// // 1        B    Y            1
  /// // 2        B    X            1
  /// // 3        A    Y            1
  ///
  /// // Group by 'Category' and use a custom aggregation for 'Sales' (e.g., range)
  /// var customAggDf = df.groupByAgg('Category', {
  ///  'Sales': (List<dynamic> values) {
  ///    if (values.isEmpty) return null;
  ///    var nums = values.whereType<num>().toList();
  ///    if (nums.isEmpty) return null;
  ///    return nums.reduce(max) - nums.reduce(min);
  ///  }
  /// });
  /// print(customAggDf);
  /// // Output (example):
  /// // Category  Sales_custom
  /// // 0        A            40  // (120 - 80 for A)
  /// // 1        B            50  // (200 - 150 for B)
  /// ```
  DataFrame groupByAgg(dynamic by, Map<String, dynamic> agg) {
    final List<String> groupColumns = by is String
        ? [by]
        : (by is List<String>
            ? by
            : throw ArgumentError('`by` must be a String or List<String>'));

    for (var col in groupColumns) {
      if (!hasColumn(col)) {
        throw ArgumentError('Grouping column "$col" does not exist.');
      }
    }
    for (var col in agg.keys) {
      if (!hasColumn(col)) {
        throw ArgumentError('Aggregation column "$col" does not exist.');
      }
    }

    final List<int> groupIndices =
        groupColumns.map((col) => _columns.indexOf(col)).toList();
    final Map<List<dynamic>, List<List<dynamic>>> groupsData = {};

    for (var row in _data) {
      final groupKey = groupIndices.map((idx) => row[idx]).toList();
      // Use a string representation of the list as map key if lists are not directly usable
      // Or implement a custom ListKey class with hashCode and ==
      // For simplicity, this example might have issues if groupKey lists are modified or contain unhashable items.
      // A robust solution uses an immutable key or a custom hashable key object.
      // Dart lists are hashable if their elements are.
      groupsData.putIfAbsent(groupKey, () => []).add(row);
    }

    final List<dynamic> resultColumns = List<dynamic>.from(groupColumns);
    final List<String> aggregatedColNames = [];
    agg.forEach((col, func) {
      final funcName =
          func is Function ? 'custom' : func.toString().toLowerCase();
      aggregatedColNames.add('${col}_$funcName');
    });
    resultColumns.addAll(aggregatedColNames);

    final List<List<dynamic>> resultData = [];
    final List<dynamic> resultIndex =
        []; // To store the first original index of each group for the new DataFrame

    groupsData.forEach((groupKey, groupRows) {
      final List<dynamic> newRow = List<dynamic>.from(groupKey);
      // Find the first original index for this group
      // This is a simplification; a more robust approach might involve more complex index handling
      if (groupRows.isNotEmpty) {
        // Find first row in _data that matches this groupKey to get its original index
        int originalRowIdx = _data.indexWhere((dataRow) {
          List<dynamic> keyFromDataRow =
              groupIndices.map((idx) => dataRow[idx]).toList();
          if (keyFromDataRow.length != groupKey.length) return false;
          for (int k = 0; k < groupKey.length; ++k) {
            if (keyFromDataRow[k] != groupKey[k]) return false;
          }
          return true;
        });
        if (originalRowIdx != -1) {
          resultIndex.add(index[originalRowIdx]);
        } else {
          resultIndex.add(resultIndex
              .length); // Fallback to sequential if somehow not found
        }
      }

      agg.forEach((colToAgg, funcOrFuncName) {
        final colIdx = _columns.indexOf(colToAgg);
        final List<dynamic> valuesForAgg =
            groupRows.map((row) => row[colIdx]).toList();

        if (funcOrFuncName is Function) {
          newRow.add(funcOrFuncName(valuesForAgg));
        } else if (funcOrFuncName is String) {
          final aggFuncName = funcOrFuncName.toLowerCase();
          switch (aggFuncName) {
            case 'mean':
              final numValues = valuesForAgg.whereType<num>().toList();
              newRow.add(numValues.isEmpty
                  ? null
                  : numValues.reduce((a, b) => a + b) / numValues.length);
              break;
            case 'sum':
              final numValues = valuesForAgg.whereType<num>().toList();
              newRow.add(
                  numValues.isEmpty ? null : numValues.reduce((a, b) => a + b));
              break;
            case 'min':
              final numValues = valuesForAgg.whereType<num>().toList();
              newRow.add(numValues.isEmpty ? null : numValues.reduce(min));
              break;
            case 'max':
              final numValues = valuesForAgg.whereType<num>().toList();
              newRow.add(numValues.isEmpty ? null : numValues.reduce(max));
              break;
            case 'count':
              newRow.add(valuesForAgg
                  .where((v) => v != null && v != replaceMissingValueWith)
                  .length);
              break;
            case 'std':
              final numValues = valuesForAgg.whereType<num>().toList();
              if (numValues.length < 2) {
                newRow.add(null);
              } else {
                final mean =
                    numValues.reduce((a, b) => a + b) / numValues.length;
                final variance = numValues
                        .map((x) => pow(x - mean, 2))
                        .reduce((a, b) => a + b) /
                    (numValues.length - 1); // Sample std dev
                newRow.add(sqrt(variance));
              }
              break;
            default:
              throw ArgumentError(
                  'Unsupported aggregation function string: "$aggFuncName" for column "$colToAgg".');
          }
        } else {
          throw ArgumentError(
              'Aggregation for column "$colToAgg" must be a recognized String or a Function.');
        }
      });
      resultData.add(newRow);
    });

    // Create new index for the resulting DataFrame. If groupsData was empty, resultIndex will be too.
    // If resultIndex is empty but resultData is not (should not happen), generate default.
    List<dynamic> finalResultIndex = resultData.isNotEmpty ? resultIndex : [];
    if (resultData.isNotEmpty && finalResultIndex.isEmpty) {
      finalResultIndex = List.generate(resultData.length, (i) => i);
    }

    return DataFrame._(resultColumns, resultData, index: finalResultIndex);
  }

  /// Computes the frequency of each unique value in a specified column.
  ///
  /// This method delegates to the `valueCounts` method of the `Series` representing
  /// the target column.
  ///
  /// Parameters:
  /// - `column`: The `String` name of the column for which to count unique value frequencies.
  /// - `normalize`: A `bool`. If `true`, returns relative frequencies (proportions)
  ///   instead of absolute counts. Defaults to `false`.
  /// - `sort`: A `bool`. If `true` (default), sorts the resulting Series by frequency.
  /// - `ascending`: A `bool`. If `true` (and `sort` is `true`), sorts in ascending
  ///   order of frequency. Defaults to `false` (descending).
  /// - `dropna`: A `bool`. If `true` (default), does not include counts of missing values
  ///   (null or `replaceMissingValueWith`) in the result. If `false`, includes their count.
  ///
  /// Returns:
  /// A `Series` where the index contains the unique values from the specified column,
  /// and the values are their corresponding counts or proportions. The Series is named
  /// after the original column.
  ///
  /// Throws:
  /// - `ArgumentError` if the specified `column` does not exist in the DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'Letters': ['A', 'B', 'A', 'C', 'B', 'A', null],
  ///   'Numbers': [1, 2, 1, 3, 2, 1, 4]
  /// }, replaceMissingValueWith: null);
  ///
  /// // Get value counts for 'Letters' column
  /// var counts = df.valueCounts('Letters');
  /// print(counts);
  /// // Output (order might vary if sort=false):
  /// // Series(name: Letters, index: [A, B, C], data: [3, 2, 1])
  ///
  /// // Get normalized frequencies, including NA
  /// var proportions = df.valueCounts('Letters', normalize: true, dropna: false);
  /// print(proportions);
  /// // Output (order might vary):
  /// // Series(name: Letters, index: [A, B, C, null], data: [0.428..., 0.285..., 0.142..., 0.142...])
  /// ```
  Series valueCounts(
    String column, {
    bool normalize = false,
    bool sort = true,
    bool ascending = false,
    bool dropna = true,
  }) {
    if (!hasColumn(column)) {
      throw ArgumentError('Column "$column" does not exist.');
    }
    // Delegate to the Series' value_counts method
    return this[column].valueCounts(
      normalize: normalize,
      sort: sort,
      ascending: ascending,
      dropna: dropna,
    );
  }

  /// Generates a summary of the DataFrame's structure.
  ///
  /// This method creates a new DataFrame that provides insights into each column, including:
  /// - Column Name
  /// - Data Type(s) present (as a Map of Type to count, excluding missing values)
  /// - Whether the column contains mixed data types (boolean)
  /// - Count of missing values (values equal to `replaceMissingValueWith` or `null`)
  ///
  /// Returns:
  /// A new `DataFrame` where each row describes a column from the original DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'ID': 1, 'Name': 'Alice', 'Score': 90.5, 'Active': true},
  ///   {'ID': 2, 'Name': 'Bob', 'Score': null, 'Active': false},
  ///   {'ID': 3, 'Name': 'Charlie', 'Score': 85, 'Active': null},
  /// ], replaceMissingValueWith: null); // Explicitly using null for missing
  /// df.updateCell('Name', 1, null); // Add another missing value
  ///
  /// var dfStructure = df.structure();
  /// print(dfStructure);
  /// // Output (Data Type map might show types like _GrowableList, etc.):
  /// //     Column Name          Data Type  Mixed Types  Missing Count
  /// // 0            ID         {int: 3}        false              0
  /// // 1          Name    {String: 2, Null: 1}  true              1 // Or just {String: 2} if nulls handled by missingCount
  /// // 2         Score  {double: 1, int: 1, Null: 1} true           1
  /// // 3        Active      {bool: 2, Null: 1}  true              1
  /// ```
  DataFrame structure() {
    var summaryData = <List<dynamic>>[];

    for (var columnNameDyn in _columns) {
      String columnName = columnNameDyn.toString();
      var columnSeries = this[columnName]; // Access Series via operator[]
      var typeAnalysis = _analyzeColumnTypes(columnSeries);

      int missingCount = 0;
      for (var val in columnSeries.data) {
        if (val == null ||
            (replaceMissingValueWith != null &&
                val == replaceMissingValueWith)) {
          missingCount++;
        }
      }
      // The typeAnalysis already excludes missing values based on `replaceMissingValueWith`
      // So, we just sum its counts for non-missing types.
      // bool isMixed = typeAnalysis.keys.length > 1;
      // Let's define mixed more carefully: more than one non-null type.
      int nonNullTypeCount =
          typeAnalysis.keys.where((type) => type != Null).length;
      bool isMixed = nonNullTypeCount > 1;

      var row = [
        columnName,
        typeAnalysis
            .toString(), // String representation of the map for simplicity
        isMixed,
        missingCount,
      ];
      summaryData.add(row);
    }

    var summaryColumnNames = [
      'Column Name',
      'Data Type(s)', // Changed from 'Data Type'
      'Mixed Types',
      'Missing Count'
    ];
    // Create a new DataFrame for the summary.
    // Explicitly set index for the summary DataFrame.
    var summaryIndex = List.generate(summaryData.length, (i) => i);
    return DataFrame(summaryData,
        columns: summaryColumnNames, index: summaryIndex);
  }

  /// Analyzes and counts the occurrences of different data types within a `Series`.
  ///
  /// This private helper method is used by `structure()` to determine the types present in a column.
  /// It ignores values that match the DataFrame's `replaceMissingValueWith` property.
  ///
  /// Parameters:
  /// - `columnData`: The `Series` representing the column to analyze.
  ///
  /// Returns:
  /// A `Map<Type, int>` where keys are the runtime types found in the column
  /// (excluding missing values as defined by `replaceMissingValueWith`),
  /// and values are the counts of each type.
  Map<Type, int> _analyzeColumnTypes(Series columnData) {
    var typeCounts = <Type, int>{};
    for (var value in columnData.data) {
      // Consider value as non-missing if it's not the placeholder AND not null
      bool isConsideredMissing = (value == null) ||
          (replaceMissingValueWith != null && value == replaceMissingValueWith);

      if (!isConsideredMissing) {
        var valueType = value.runtimeType;
        typeCounts[valueType] = (typeCounts[valueType] ?? 0) + 1;
      }
    }
    return typeCounts;
  }

  /// Generates descriptive statistics for numerical columns in the DataFrame.
  ///
  /// For each column containing numerical data, this method calculates:
  /// - `count`: Number of non-null numeric values.
  /// - `mean`: Average of the values.
  /// - `std`: Standard deviation of the values.
  /// - `min`: Minimum value.
  /// - `25%`: The first quartile (25th percentile).
  /// - `50%`: The median (50th percentile).
  /// - `75%`: The third quartile (75th percentile).
  /// - `max`: Maximum value.
  ///
  /// Returns:
  /// A `Map<String, Map<String, num>>` where outer keys are the numerical column names,
  /// and inner keys are the statistic names (e.g., 'mean', 'std').
  /// If a column is non-numeric or empty after filtering for numbers, it's excluded.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'Age': [25, 30, 22, 35, 28, null], // Includes a null
  ///   'Salary': [50000, 60000, 45000, 75000, 55000, 62000.5],
  ///   'Name': ['A', 'B', 'C', 'D', 'E', 'F'] // Non-numeric
  /// });
  ///
  /// var stats = df.describe();
  /// stats.forEach((column, description) {
  ///   print('Statistics for column: $column');
  ///   description.forEach((statName, value) {
  ///     print('  $statName: ${value.toStringAsFixed(2)}');
  ///   });
  /// });
  /// // Output might show stats for 'Age' (count 5) and 'Salary' (count 6).
  /// ```
  Map<String, Map<String, num>> describe() {
    Map<String, Map<String, num>> description = {};

    for (var i = 0; i < _columns.length; i++) {
      var columnName = _columns[i].toString();
      var columnData = _data.map((row) => row[i]);

      // Filter out nulls and ensure values are numeric
      var numericData = columnData
          .where((v) => v != null && v != replaceMissingValueWith && v is num)
          .cast<num>() // Cast to num after filtering
          .toList();

      if (numericData.isEmpty) {
        continue; // Skip non-numeric or empty numeric columns
      }

      num count = numericData.length;
      num sum = numericData.fold(0, (prev, element) => prev + element);
      num mean = (count > 0) ? sum / count : 0;

      num std = 0;
      if (count > 1) {
        num sumOfSquares = numericData.fold(
            0, (prev, element) => prev + pow(element - mean, 2));
        num variance = sumOfSquares / (count - 1); // Sample standard deviation
        std = sqrt(variance);
      }

      var sortedData = List<num>.from(numericData)
        ..sort(); // Create a mutable copy for sorting
      num min = sortedData.first;
      num max = sortedData.last;

      // Percentile calculation helper
      num percentile(List<num> sortedList, double p) {
        if (sortedList.isEmpty) return 0; // Or throw, or return NaN
        if (sortedList.length == 1) return sortedList.first;
        double pos = (sortedList.length - 1) * p;
        int intPos = pos.floor();
        double diff = pos - intPos;
        if (intPos + 1 < sortedList.length) {
          return sortedList[intPos] * (1 - diff) +
              sortedList[intPos + 1] * diff;
        } else {
          return sortedList[intPos];
        }
      }

      num q1 = percentile(sortedData, 0.25);
      num median = percentile(sortedData, 0.50);
      num q3 = percentile(sortedData, 0.75);

      description[columnName] = {
        'count': count,
        'mean': mean,
        'std': std,
        'min': min,
        '25%': q1,
        '50%': median, // Median
        '75%': q3,
        'max': max,
      };
    }
    return description;
  }

  /// Adds a new row to the end of the DataFrame.
  ///
  /// This method modifies the DataFrame **in-place**.
  ///
  /// Parameters:
  /// - `newRow`: A `List<dynamic>` representing the row to be added.
  ///   The length of `newRow` must match the number of columns in the DataFrame.
  ///   If the DataFrame is empty and has no columns defined, the columns will be
  ///   named "Column1", "Column2", etc., based on the length of `newRow`.
  ///
  /// Throws:
  /// - `ArgumentError` if the DataFrame has columns and `newRow` length does not match
  ///   the number of columns.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromNames(['Name', 'Age']);
  /// df.addRow(['Alice', 30]);
  /// df.addRow(['Bob', 25]);
  /// print(df);
  /// // Output:
  /// //       Name  Age
  /// // 0    Alice   30
  /// // 1      Bob   25
  ///
  /// var emptyDf = DataFrame.empty();
  /// emptyDf.addRow([10, 'X']);
  /// print(emptyDf);
  /// // Output:
  /// //   Column1 Column2
  /// // 0      10       X
  /// ```
  void addRow(List<dynamic> newRow) {
    if (_columns.isEmpty && _data.isEmpty) {
      // If DataFrame is completely empty, define columns based on newRow length
      _columns = List.generate(newRow.length, (index) => 'Column${index + 1}');
    } else if (newRow.length != _columns.length) {
      throw ArgumentError(
          'New row length (${newRow.length}) must match number of columns (${_columns.length}).');
    }
    _data.add(List<dynamic>.from(newRow)); // Add a copy
    // Add a new index label. If the current index is a default integer index, continue it.
    if (index.isEmpty ||
        (index.isNotEmpty &&
            index.last is int &&
            index.last == index.length - 1 &&
            _data.length > index.length)) {
      index.add(_data.length - 1);
    } else {
      index.add(
          'Index${_data.length - 1}'); // Or some other placeholder/strategy for non-default index
    }
  }

  /// Adds a new column to the DataFrame.
  ///
  /// This method modifies the DataFrame **in-place**.
  ///
  /// Parameters:
  /// - `name`: The `dynamic` name for the new column. Typically a `String`.
  /// - `defaultValue`: The value to populate the new column with.
  ///   - If `defaultValue` is a `List`, its length must match the number of rows
  ///     in the DataFrame. Each element of the list will be used for the corresponding row.
  ///   - If `defaultValue` is not a list (e.g., a single value like `int`, `String`, `null`),
  ///     all cells in the new column will be filled with this value.
  ///
  /// Throws:
  /// - `ArgumentError` if a column with the given `name` already exists.
  /// - `ArgumentError` if `defaultValue` is a `List` and its length does not match
  ///   the number of rows in the DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([{'A': 1}, {'A': 2}]);
  ///
  /// // Add a column with a single default value
  /// df.addColumn('B', defaultValue: 0);
  /// print(df);
  /// // Output:
  /// //    A  B
  /// // 0  1  0
  /// // 1  2  0
  ///
  /// // Add a column with values from a list
  /// df.addColumn('C', defaultValue: [10, 20]);
  /// print(df);
  /// // Output:
  /// //    A  B   C
  /// // 0  1  0  10
  /// // 1  2  0  20
  /// ```
  void addColumn(dynamic name, {dynamic defaultValue}) {
    String colName = name.toString();
    if (_columns.any((c) => c.toString() == colName)) {
      throw ArgumentError("Column '$colName' already exists.");
    }

    _columns.add(name); // Add new column name

    if (defaultValue is List) {
      if (defaultValue.length != _data.length && _data.isNotEmpty) {
        // Allow adding to empty DF
        throw ArgumentError(
            'Length of defaultValue list (${defaultValue.length}) must match number of rows (${_data.length}).');
      }
      if (_data.isEmpty) {
        // If DF is empty, create rows based on defaultValue list
        for (int i = 0; i < defaultValue.length; ++i) {
          List<dynamic> newRow = List.filled(
              _columns.length, replaceMissingValueWith,
              growable: true);
          newRow[_columns.length - 1] = defaultValue[i];
          _data.add(newRow);
          // Also add index if it's empty
          if (index.length < _data.length) {
            index.add(i);
          }
        }
      } else {
        for (int i = 0; i < _data.length; i++) {
          _data[i].add(defaultValue[i]);
        }
      }
    } else {
      // Single default value
      if (_data.isEmpty && defaultValue != null) {
        // Cannot determine number of rows if DF is empty and defaultValue is not a list
        // Or, decide to not add any rows, just the column.
        // For now, let's assume if data is empty, column is added but no rows.
        // This behavior might need refinement based on desired pandas parity.
      } else {
        for (var row in _data) {
          row.add(defaultValue);
        }
      }
    }
  }

  /// Updates a specific cell value in the DataFrame, identified by its row index and column (name or index).
  ///
  /// This method modifies the DataFrame **in-place**.
  ///
  /// Parameters:
  /// - `rowIndex`: The integer-based positional index of the row to update (0 to `rowCount - 1`).
  /// - `column`: The column to update. Can be either:
  ///   - A `String` representing the column name.
  ///   - An `int` representing the column's positional index.
  /// - `value`: The new `dynamic` value to set for the cell.
  ///
  /// Throws:
  /// - `ArgumentError` if `rowIndex` is out of range.
  /// - `ArgumentError` if `column` (as an integer index) is out of range.
  /// - `ArgumentError` if `column` (as a String name) does not exist.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Name': 'Alice', 'Age': 30},
  ///   {'Name': 'Bob', 'Age': 25}
  /// ]);
  ///
  /// // Update Alice's age using column name
  /// df.updateColumn(0, 'Age', 31);
  ///
  /// // Update Bob's name using column index (Name is at index 0)
  /// df.updateColumn(1, 0, 'Robert');
  ///
  /// print(df);
  /// // Output:
  /// //        Name  Age
  /// // 0    Alice   31
  /// // 1   Robert   25
  /// ```
  void updateColumn(int rowIndex, dynamic column, dynamic value) {
    if (rowIndex < 0 || rowIndex >= _data.length) {
      throw ArgumentError(
          'Row index out of range: $rowIndex. DataFrame has ${_data.length} rows.');
    }

    int columnIndex;
    if (column is int) {
      if (column < 0 || column >= _columns.length) {
        throw ArgumentError(
            'Column index out of range: $column. DataFrame has ${_columns.length} columns.');
      }
      columnIndex = column;
    } else if (column is String) {
      columnIndex = _columns.indexOf(column);
      if (columnIndex == -1) {
        throw ArgumentError(
            'Column "$column" does not exist. Available columns: $_columns');
      }
    } else {
      throw ArgumentError(
          'Column identifier must be an int (index) or String (name).');
    }

    // Ensure the row has enough elements (should generally be true if columns are managed correctly)
    if (_data[rowIndex].length <= columnIndex) {
      // This case should ideally not be hit if DataFrame structure is consistent.
      // If it can happen due to flexible columns, pad with replaceMissingValueWith.
      while (_data[rowIndex].length <= columnIndex) {
        _data[rowIndex].add(replaceMissingValueWith);
      }
    }
    _data[rowIndex][columnIndex] = value;
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

  /// Creates a new DataFrame with rows randomly shuffled.
  ///
  /// This method does not modify the original DataFrame.
  ///
  /// Parameters:
  /// - `seed`: An optional `int` value used to initialize the random number generator.
  ///   Providing a seed ensures that the shuffle order is the same across different
  ///   runs, making the shuffle deterministic and reproducible. If `null` (default),
  ///   the shuffle order is random and non-reproducible.
  ///
  /// Returns:
  /// A new `DataFrame` with its rows shuffled. The index is also shuffled along with the data.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'ID': [1, 2, 3, 4],
  ///   'Letter': ['A', 'B', 'C', 'D']
  /// }, index: ['r1', 'r2', 'r3', 'r4']);
  ///
  /// print('Original DataFrame:');
  /// print(df);
  ///
  /// // Shuffle randomly
  /// var shuffledDf = df.shuffle();
  /// print('\nRandomly Shuffled DataFrame:');
  /// print(shuffledDf); // Order will vary
  ///
  /// // Shuffle with a seed for reproducible results
  /// var seededShuffle1 = df.shuffle(seed: 42);
  /// print('\nShuffled DataFrame (seed 42):');
  /// print(seededShuffle1);
  ///
  /// var seededShuffle2 = df.shuffle(seed: 42); // Same seed
  /// print('\nShuffled DataFrame (seed 42, again):');
  /// print(seededShuffle2); // Will have the same order as seededShuffle1
  /// ```
  DataFrame shuffle({int? seed}) {
    if (_data.isEmpty) {
      return copy(); // Return a copy of the empty DataFrame
    }

    // Pair data and index to shuffle them together
    final List<MapEntry<List<dynamic>, dynamic>> pairedDataAndIndex = [];
    for (int i = 0; i < _data.length; i++) {
      pairedDataAndIndex.add(MapEntry(List<dynamic>.from(_data[i]), index[i]));
    }

    var random = seed != null ? Random(seed) : Random();
    pairedDataAndIndex.shuffle(random);

    final List<List<dynamic>> shuffledData =
        pairedDataAndIndex.map((e) => e.key).toList();
    final List<dynamic> shuffledIndex =
        pairedDataAndIndex.map((e) => e.value).toList();

    return DataFrame._(List<dynamic>.from(_columns), shuffledData,
        index: shuffledIndex,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator);
  }

  /// Returns `true` if the DataFrame has no rows.
  ///
  /// This is equivalent to checking if `rowCount` is 0.
  ///
  /// Returns:
  /// A `bool` indicating whether the DataFrame is empty.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.empty();
  /// print(df.isEmpty); // Output: true
  ///
  /// df.addRow([1, 2]);
  /// print(df.isEmpty); // Output: false
  /// ```
  bool get isEmpty => _data.isEmpty;

  /// Returns `true` if the DataFrame has at least one row.
  ///
  /// This is equivalent to checking if `rowCount` is greater than 0.
  ///
  /// Returns:
  /// A `bool` indicating whether the DataFrame is not empty.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([{'A':1}]);
  /// print(df.isNotEmpty); // Output: true
  ///
  /// var emptyDf = DataFrame.empty();
  /// print(emptyDf.isNotEmpty); // Output: false
  /// ```
  bool get isNotEmpty => _data.isNotEmpty;

  /// Creates a deep copy of the DataFrame.
  ///
  /// The new DataFrame will have its own independent copies of the column list,
  /// data rows (and the lists within them), and the index list.
  /// Modifications to the copied DataFrame will not affect the original, and vice-versa.
  /// Properties like `allowFlexibleColumns` and `replaceMissingValueWith` are also copied.
  ///
  /// Returns:
  /// A new `DataFrame` that is a deep copy of the original.
  ///
  /// Example:
  /// ```dart
  /// var df1 = DataFrame.fromMap({'A': [1, 2]});
  /// var df2 = df1.copy();
  ///
  /// df2.updateCell('A', 0, 100); // Modify the copy
  /// df2.addColumn('B', defaultValue: 99);
  ///
  /// print('Original DataFrame:');
  /// print(df1); // df1 remains unchanged
  /// // Output:
  /// // Original DataFrame:
  /// //    A
  /// // 0  1
  /// // 1  2
  ///
  /// print('\nCopied and Modified DataFrame:');
  /// print(df2);
  /// // Output:
  /// // Copied and Modified DataFrame:
  /// //      A   B
  /// // 0  100  99
  /// // 1    2  99
  /// ```
  DataFrame copy() {
    final List<dynamic> copiedColumns = List<dynamic>.from(_columns);
    final List<List<dynamic>> copiedData =
        _data.map((row) => List<dynamic>.from(row)).toList();
    final List<dynamic> copiedIndex = List<dynamic>.from(index);

    return DataFrame._(
      copiedColumns,
      copiedData,
      index: copiedIndex,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator:
          List<dynamic>.from(_missingDataIndicator), // Also copy this
    );
  }

  /// Returns a `Map` indicating the data type of each column.
  ///
  /// For each column, it determines the predominant non-null runtime `Type` of its values.
  /// If a column is empty or contains only null/missing values, its type might be reported as `dynamic`
  /// or `Null`.
  ///
  /// Returns:
  /// A `Map<String, Type>` where keys are column names (as `String`) and
  /// values are the inferred `Type` of each column.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'Integers': [1, 2, 3],
  ///   'Doubles': [1.0, 2.5, 3.14],
  ///   'Strings': ['a', 'b', 'c'],
  ///   'Booleans': [true, false, true],
  ///   'Mixed': [1, 'hello', true, null],
  ///   'AllNull': [null, null, null]
  /// }, replaceMissingValueWith: null);
  ///
  /// Map<String, Type> columnTypes = df.dtypes;
  /// columnTypes.forEach((col, type) {
  ///   print('$col: $type');
  /// });
  /// // Output:
  /// // Integers: int
  /// // Doubles: double
  /// // Strings: String
  /// // Booleans: bool
  /// // Mixed: int (or String, or bool, depending on first non-null, or if more sophisticated logic is used)
  /// // AllNull: Null (or dynamic if no non-null values to infer from)
  /// ```
  Map<String, Type> get dtypes {
    Map<String, Type> types = {};

    for (var i = 0; i < _columns.length; i++) {
      var columnName = _columns[i].toString();
      var columnData = _data.map((row) {
        // Ensure row is long enough, can happen with flexible columns
        return (i < row.length) ? row[i] : replaceMissingValueWith;
      }).toList();

      // Count occurrences of each non-missing type
      Map<Type, int> typeCounts = {};
      for (var value in columnData) {
        bool isConsideredMissing = (value == null) ||
            (replaceMissingValueWith != null &&
                value == replaceMissingValueWith);
        if (!isConsideredMissing) {
          Type valueType = value.runtimeType;
          typeCounts[valueType] = (typeCounts[valueType] ?? 0) + 1;
        }
      }

      // Find the most common non-missing type
      Type mostCommonType =
          dynamic; // Default to dynamic if no non-missing values or all are different
      int maxCount = 0;
      if (typeCounts.isNotEmpty) {
        typeCounts.forEach((type, count) {
          if (count > maxCount) {
            maxCount = count;
            mostCommonType = type;
          }
        });
      } else {
        // Column is all null/missing or empty
        final firstValue = columnData.isNotEmpty ? columnData.first : null;
        if (firstValue == null ||
            (replaceMissingValueWith != null &&
                firstValue == replaceMissingValueWith)) {
          mostCommonType = Null; // Or keep as dynamic
        }
      }
      types[columnName] = mostCommonType;
    }
    return types;
  }

  /// Checks if the DataFrame contains a column with the specified name.
  ///
  /// Parameters:
  /// - `columnName`: The `String` name of the column to check for.
  ///
  /// Returns:
  /// `true` if a column with `columnName` exists, `false` otherwise.
  /// Comparison is direct equality on column labels.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromNames(['A', 'B']);
  /// print(df.hasColumn('A')); // Output: true
  /// print(df.hasColumn('C')); // Output: false
  /// ```
  bool hasColumn(String columnName) => _columns.contains(columnName);

  /// Returns a new DataFrame containing only the unique rows from the original DataFrame.
  ///
  /// The order of rows in the returned DataFrame is based on their first appearance
  /// in the original DataFrame. The index of the first appearance is preserved.
  ///
  /// Returns:
  /// A new `DataFrame` with duplicate rows removed.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'A': 1, 'B': 'x'},
  ///   {'A': 2, 'B': 'y'},
  ///   {'A': 1, 'B': 'x'}, // Duplicate of the first row
  ///   {'A': 3, 'B': 'z'},
  /// ], index: ['r1', 'r2', 'r3', 'r4']);
  ///
  /// var uniqueDf = df.unique();
  /// print(uniqueDf);
  /// // Output:
  /// //     A  B
  /// // r1  1  x
  /// // r2  2  y
  /// // r4  3  z
  /// ```
  DataFrame unique() {
    final Set<String> seenRows =
        {}; // Use string representation of rows to track seen ones
    final List<List<dynamic>> uniqueData = [];
    final List<dynamic> uniqueIndex = [];

    for (int i = 0; i < _data.length; i++) {
      final row = _data[i];
      // Convert row to a string representation for checking uniqueness.
      // This is a simple way; for more complex objects or precise equality,
      // a custom hashing or deep equality check might be needed.
      final rowStr = row.join('||'); // Using a unique separator
      if (seenRows.add(rowStr)) {
        uniqueData.add(List<dynamic>.from(row));
        uniqueIndex.add(index[i]);
      }
    }
    return DataFrame._(List<dynamic>.from(_columns), uniqueData,
        index: uniqueIndex,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator);
  }

  /// Returns a new DataFrame with the index reset to the default integer index (0 to N-1).
  ///
  /// The original index is discarded. This is useful after filtering or sorting operations
  /// if a clean, sequential index is desired.
  ///
  /// Returns:
  /// A new `DataFrame` with a default integer index. The data and columns remain the same.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [10, 20, 30]}, index: ['x', 'y', 'z']);
  /// print('Original DataFrame:\n$df');
  ///
  /// var dfReset = df.resetIndex();
  /// print('\nDataFrame with reset index:\n$dfReset');
  /// // Output:
  /// // DataFrame with reset index:
  /// //    A
  /// // 0 10
  /// // 1 20
  /// // 2 30
  /// ```
  DataFrame resetIndex() {
    // Create a new default integer index
    final newIndex = List.generate(rowCount, (i) => i);
    // Return a new DataFrame with the new index but same data and columns
    return DataFrame._(
      List<dynamic>.from(_columns),
      _data.map((row) => List<dynamic>.from(row)).toList(), // Deep copy data
      index: newIndex,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
      missingDataIndicator: _missingDataIndicator,
    );
  }

  /// Converts the DataFrame into a `List` of `Map<dynamic, dynamic>`.
  ///
  /// Each map in the list represents a row from the DataFrame, where keys are
  /// the column labels and values are the corresponding cell values for that row.
  ///
  /// Returns:
  /// A `List<Map<dynamic, dynamic>>` representing the DataFrame's data.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'Name': ['Alice', 'Bob'],
  ///   'Age': [30, 25]
  /// });
  ///
  /// List<Map<dynamic, dynamic>> listOfMaps = df.toListOfMaps();
  /// print(listOfMaps);
  /// // Output:
  /// // [
  /// //   {Name: Alice, Age: 30},
  /// //   {Name: Bob, Age: 25}
  /// // ]
  /// ```
  List<Map<dynamic, dynamic>> toListOfMaps() {
    return _data.map((row) {
      final map = <dynamic, dynamic>{};
      for (var i = 0; i < _columns.length; i++) {
        // Ensure row is long enough before accessing by index
        if (i < row.length) {
          map[_columns[i]] = row[i];
        } else {
          map[_columns[i]] =
              replaceMissingValueWith; // Or null, if preferred for short rows
        }
      }
      return map;
    }).toList();
  }

  /// Converts the DataFrame into a `Map` of `Series`.
  ///
  /// Each key in the map is a column name from the DataFrame, and the corresponding
  /// value is a `Series` containing the data for that column. The index of each
  /// `Series` will be the same as the DataFrame's index.
  ///
  /// Returns:
  /// A `Map<dynamic, Series>` where keys are column labels and values are `Series`
  /// representing each column.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6]
  /// }, index: ['x', 'y', 'z']);
  ///
  /// Map<dynamic, Series> mapOfSeries = df.toMap();
  /// print(mapOfSeries['A']);
  /// // Output: Series(name: A, index: [x, y, z], data: [1, 2, 3])
  /// print(mapOfSeries['B']);
  /// // Output: Series(name: B, index: [x, y, z], data: [4, 5, 6])
  /// ```
  Map<dynamic, Series> toMap() {
    final map = <dynamic, Series>{};
    for (var i = 0; i < _columns.length; i++) {
      final columnData = _data.map((row) {
        return (i < row.length) ? row[i] : replaceMissingValueWith;
      }).toList();
      map[_columns[i]] = Series(columnData,
          name: _columns[i].toString(), index: List.from(index));
    }
    return map;
  }

  /// Randomly samples `n` rows from the DataFrame.
  ///
  /// Creates a new DataFrame containing a random selection of rows.
  ///
  /// Parameters:
  /// - `n`: The `int` number of rows to sample.
  /// - `seed`: An optional `int` to seed the random number generator for reproducible sampling.
  ///   If `null` (default), the sample will be different each time.
  /// - `replace`: A `bool`. If `true`, sampling is done with replacement (a row can be
  ///   selected multiple times). If `false` (default), sampling is done without replacement
  ///   (each row can be selected at most once).
  ///
  /// Returns:
  /// A new `DataFrame` containing the sampled rows.
  ///
  /// Throws:
  /// - `ArgumentError` if `n` is non-positive.
  /// - `ArgumentError` if `replace` is `false` and `n` is greater than the number of rows
  ///   in the DataFrame.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2, 3, 4, 5, 6]});
  ///
  /// // Sample 3 rows without replacement
  /// var sampleDf = df.sample(3);
  /// print(sampleDf.rowCount); // Output: 3
  ///
  /// // Sample 5 rows with replacement (could have duplicates)
  /// var sampleReplaceDf = df.sample(5, replace: true, seed: 1);
  /// print(sampleReplaceDf);
  ///
  /// // Attempt to sample more rows than available without replacement
  /// try {
  ///   df.sample(10, replace: false);
  /// } catch (e) {
  ///   print(e); // Catches ArgumentError
  /// }
  /// ```
  DataFrame sample(int n, {int? seed, bool replace = false}) {
    if (n <= 0) {
      throw ArgumentError('Sample size (n) must be positive.');
    }
    if (_data.isEmpty) {
      return DataFrame._(List.from(_columns), [], index: []);
    }

    if (!replace && n > _data.length) {
      throw ArgumentError(
          'Sample size (n=$n) cannot exceed DataFrame length (${_data.length}) when sampling without replacement.');
    }

    final random = seed != null ? Random(seed) : Random();
    final List<int> sampledIndices = [];
    final List<List<dynamic>> sampledData = [];
    final List<dynamic> sampledIndex = [];

    if (replace) {
      for (int i = 0; i < n; i++) {
        sampledIndices.add(random.nextInt(_data.length));
      }
    } else {
      final List<int> availableIndices = List.generate(_data.length, (i) => i);
      for (int i = 0; i < n; i++) {
        final randomIndexIntoAvailable =
            random.nextInt(availableIndices.length);
        sampledIndices.add(availableIndices.removeAt(randomIndexIntoAvailable));
      }
    }

    for (int originalIdx in sampledIndices) {
      sampledData.add(List<dynamic>.from(_data[originalIdx]));
      sampledIndex.add(index[originalIdx]);
    }
    return DataFrame._(List<dynamic>.from(_columns), sampledData,
        index: sampledIndex,
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator);
  }

  /// Applies a function to each element in a specified column.
  ///
  /// Creates a new DataFrame with the transformed column. The original DataFrame is not modified.
  ///
  /// Parameters:
  /// - `columnName`: The `String` name of the column to apply the function to.
  /// - `func`: A function `(dynamic value) => dynamic` that takes a cell value
  ///   from the specified column and returns the transformed value.
  ///
  /// Returns:
  /// A new `DataFrame` with the same structure, but with the values in the
  /// specified column transformed by `func`.
  ///
  /// Throws:
  /// - `ArgumentError` if `columnName` does not exist.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2, 3], 'B': [10, 20, 30]});
  ///
  /// // Double the values in column 'A'
  /// var dfApplied = df.applyToColumn('A', (x) => (x as int) * 2);
  /// print(dfApplied);
  /// // Output:
  /// //    A   B
  /// // 0  2  10
  /// // 1  4  20
  /// // 2  6  30
  /// ```
  DataFrame applyToColumn(
      String columnName, dynamic Function(dynamic value) func) {
    final columnIndex = _columns.indexOf(columnName);
    if (columnIndex == -1) {
      throw ArgumentError('Column "$columnName" does not exist.');
    }

    final newData = _data.map((row) {
      final newRow = List<dynamic>.from(row);
      // Ensure row is long enough before applying function
      if (columnIndex < newRow.length) {
        newRow[columnIndex] = func(newRow[columnIndex]);
      }
      return newRow;
    }).toList();

    return DataFrame._(List<dynamic>.from(_columns), newData,
        index: List<dynamic>.from(index),
        allowFlexibleColumns: allowFlexibleColumns,
        replaceMissingValueWith: replaceMissingValueWith,
        missingDataIndicator: _missingDataIndicator);
  }

  /// Applies a function to each row of the DataFrame.
  ///
  /// The provided function `func` takes a `Map<dynamic, dynamic>` representing a row
  /// (where keys are column names) and should return a single value.
  ///
  /// Returns:
  /// A `Series` containing the results of applying `func` to each row.
  /// The Series will have the same index as the DataFrame.
  /// Its name will be 'apply_result' by default.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [10, 20, 30],
  ///   'C': [100, 200, 300]
  /// });
  ///
  /// // Calculate sum of 'A' and 'B' for each row
  /// var rowSums = df.applyToRows((row) => (row['A'] as int) + (row['B'] as int));
  /// print(rowSums);
  /// // Output: Series(name: apply_result, index: [0, 1, 2], data: [11, 22, 33])
  ///
  /// // Create a new string from columns 'A' and 'C'
  /// var combinedStrings = df.applyToRows((row) => "A:${row['A']}-C:${row['C']}");
  /// print(combinedStrings);
  /// // Output: Series(name: apply_result, index: [0, 1, 2], data: [A:1-C:100, A:2-C:200, A:3-C:300])
  /// ```
  Series applyToRows(dynamic Function(Map<dynamic, dynamic> rowMap) func) {
    final List<dynamic> results = [];
    for (var rowData in _data) {
      final rowMap = Map<dynamic, dynamic>.fromIterables(_columns, rowData);
      results.add(func(rowMap));
    }
    return Series(results,
        name: 'apply_result', index: List<dynamic>.from(index));
  }

  /// Private helper method to perform a cross join.
  ///
  /// A cross join returns the Cartesian product of rows from two DataFrames.
  ///
  /// Parameters:
  /// - `other`: The `DataFrame` to cross join with.
  /// - `suffixes`: A `List<String>` of suffixes to apply to overlapping column names.
  ///
  /// Returns:
  /// A new `DataFrame` representing the cross product. The index of the new
  /// DataFrame is a compound key created by joining the original indices.
  DataFrame _crossJoin(DataFrame other, List<String> suffixes) {
    final List<dynamic> newColumns = List.from(columns);
    // final newColumns = [];

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
      // Skip join columns that have the same name in both DataFrames
      if (rightCols.contains(colName) && leftCols.contains(colName)) {
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
        // Skip join columns that have the same name in both DataFrames
        if (rightCols.contains(colName) && leftCols.contains(colName)) {
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
        if (rightIdx != -1 && leftIdx != -1) {
          result[leftIdx] = row[rightIdx];
        }
      }

      // Add right columns (skipping join columns if they have the same name)
      for (var i = 0; i < otherColumns.length; i++) {
        final colName = otherColumns[i];
        // Skip join columns that have the same name in both DataFrames
        if (rightCols.contains(colName) && leftCols.contains(colName)) {
          continue;
        }

        result.add(row[i]);
      }
    }

    return result;
  }

  /// Joins this DataFrame with another DataFrame (`other`) based on specified keys
  /// and join type.
  ///
  /// This method provides functionality similar to SQL JOIN operations.
  ///
  /// Parameters:
  /// - `other`: The `DataFrame` to join with.
  /// - `how`: A `String` specifying the type of join. Defaults to `'inner'`.
  ///   Supported types:
  ///   - `'inner'`: Returns rows where the join key(s) exist in both DataFrames.
  ///   - `'left'`: Returns all rows from the left DataFrame (this), and matched rows
  ///     from the right DataFrame. Unmatched right columns get missing values.
  ///   - `'right'`: Returns all rows from the right DataFrame (`other`), and matched rows
  ///     from the left. Unmatched left columns get missing values.
  ///   - `'outer'`: Returns all rows from both DataFrames. Unmatched columns on either
  ///     side get missing values.
  ///   - `'cross'`: Returns the Cartesian product of rows from both DataFrames.
  ///     Join keys (`on`, `leftOn`, `rightOn`) are ignored for cross join.
  /// - `on`: A `String` or `List<String>` of column names to join on. These columns
  ///   must exist in both DataFrames. If `null`, `leftOn` and `rightOn` must be used.
  /// - `leftOn`: A `String` or `List<String>` of column names from the left DataFrame
  ///   (this) to use as join keys. Used with `rightOn`.
  /// - `rightOn`: A `String` or `List<String>` of column names from the right DataFrame
  ///   (`other`) to use as join keys. Used with `leftOn`.
  /// - `suffixes`: A `List<String>` of length 2, providing suffixes to append to
  ///   overlapping column names (non-join-key columns that have the same name in
  ///   both DataFrames). Defaults to `['_x', '_y']`. The first suffix is for the
  ///   left DataFrame's column, the second for the right.
  /// - `indicator`: If `true`, adds a column named `'_merge'` to the output DataFrame,
  ///   indicating the source of each row: `'left_only'`, `'right_only'`, or `'both'`.
  ///   If a `String` is provided, it's used as the name for this indicator column.
  ///   Defaults to `false`.
  ///
  /// Returns:
  /// A new `DataFrame` resulting from the join operation. The index of the
  /// resulting DataFrame depends on the join type and original indices.
  /// (Note: Index handling in this implementation is simplified, often taking the
  /// left DataFrame's index or resetting for complex cases).
  ///
  /// Throws:
  /// - `ArgumentError` for invalid parameters (e.g., missing join keys, mismatched key list lengths,
  ///   non-existent columns, unsupported join type).
  ///
  /// Example:
  /// ```dart
  /// var leftDf = DataFrame.fromMap({
  ///   'key': ['K0', 'K1', 'K2', 'K3'],
  ///   'A': ['A0', 'A1', 'A2', 'A3'],
  ///   'B': ['B0', 'B1', 'B2', 'B3']
  /// });
  /// var rightDf = DataFrame.fromMap({
  ///   'key': ['K0', 'K1', 'K4', 'K5'],
  ///   'C': ['C0', 'C1', 'C4', 'C5'],
  ///   'D': ['D0', 'D1', 'D4', 'D5']
  /// });
  ///
  /// // Inner join on 'key'
  /// print(leftDf.join(rightDf, on: 'key', how: 'inner'));
  /// // Output:
  /// //   key   A   B   C   D
  /// // 0  K0  A0  B0  C0  D0
  /// // 1  K1  A1  B1  C1  D1
  ///
  /// // Left join on 'key'
  /// print(leftDf.join(rightDf, on: 'key', how: 'left'));
  /// // Output:
  /// //   key   A   B     C     D
  /// // 0  K0  A0  B0    C0    D0
  /// // 1  K1  A1  B1    C1    D1
  /// // 2  K2  A2  B2  null  null
  /// // 3  K3  A3  B3  null  null
  ///
  /// // Outer join with indicator
  /// print(leftDf.join(rightDf, on: 'key', how: 'outer', indicator: true));
  ///
  /// // Cross join
  /// var df1 = DataFrame.fromMap({'col1': [1,2]});
  /// var df2 = DataFrame.fromMap({'col2': ['a','b']});
  /// print(df1.join(df2, how: 'cross'));
  /// // Output:
  /// //   col1 col2
  /// // 0    1    a
  /// // 1    1    b
  /// // 2    2    a
  /// // 3    2    b
  /// ```
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
        throw ArgumentError(
            "Cannot use 'on' simultaneously with 'leftOn' or 'rightOn'.");
      }
      leftCols = on is String ? [on] : List<String>.from(on);
      rightCols = on is String ? [on] : List<String>.from(on);
    } else {
      if (leftOn == null || rightOn == null) {
        throw ArgumentError(
            "Either 'on' or both 'leftOn' and 'rightOn' must be specified.");
      }
      leftCols = leftOn is String ? [leftOn] : List<String>.from(leftOn);
      rightCols = rightOn is String ? [rightOn] : List<String>.from(rightOn);
    }

    // Handle different join types
    if (how == 'cross') {
      if (on != null || leftOn != null || rightOn != null) {
        print(
            "Warning: 'on', 'leftOn', and 'rightOn' are ignored for cross join.");
      }
      return _crossJoin(other,
          suffixes); // Indicator logic might be added to _crossJoin or handled here
    }

    if (leftCols.length != rightCols.length) {
      throw ArgumentError(
          'leftOn/on and rightOn/on column lists must have the same number of columns');
    }

    // Validate columns
    for (var col in leftCols) {
      if (!hasColumn(col)) {
        throw ArgumentError(
            'Left column $col does not exist in left DataFrame');
      }
    }

    for (var col in rightCols) {
      if (!other.hasColumn(col)) {
        throw ArgumentError(
            'Right column $col does not exist in right DataFrame');
      }
    }

    // Extract column indices
    final leftIndices = leftCols.map((col) => _columns.indexOf(col)).toList();
    final rightIndices =
        rightCols.map((col) => other._columns.indexOf(col)).toList();

    // Create new column names (avoiding duplicates)
    final newColumns = <dynamic>[];

    // Add left columns (with suffixes for conflicting non-join columns)
    for (var col in _columns) {
      if (other._columns.contains(col) && 
          !(rightCols.contains(col) && leftCols.contains(col))) {
        // Add suffix for duplicate non-join columns
        newColumns.add('$col${suffixes[0]}');
      } else {
        newColumns.add(col);
      }
    }

    // Add right columns (with suffixes for duplicates, skip join columns if same name)
    for (var col in other._columns) {
      // Skip join columns that have the same name in both DataFrames
      if (rightCols.contains(col) && leftCols.contains(col)) {
        continue;
      }
      
      if (_columns.contains(col)) {
        // Add suffix for duplicate non-join columns
        newColumns.add('$col${suffixes[1]}');
      } else {
        newColumns.add(col);
      }
    }

    // Build maps for faster lookups using string keys for proper equality comparison
    final rightMap = <String, List<List<dynamic>>>{};
    for (var rightRow in other._data) {
      final keyValues = rightIndices.map((idx) => rightRow[idx]).toList();
      // Skip rows with null values in join keys (nulls don't match in joins)
      if (keyValues.any((v) => v == null)) {
        continue;
      }
      final keyString = keyValues.map((v) => v.toString()).join('|');
      rightMap.putIfAbsent(keyString, () => []);
      rightMap[keyString]!.add(rightRow);
    }

    final newData = <List<dynamic>>[];

    // Perform the join based on the specified type
    final List<String> mergeIndicatorValues = [];

    switch (how) {
      case 'inner':
        for (var leftRow in _data) {
          final keyValues = leftIndices.map((idx) => leftRow[idx]).toList();
          // Skip rows with null values in join keys (nulls don't match in joins)
          if (keyValues.any((v) => v == null)) {
            continue;
          }
          final keyString = keyValues.map((v) => v.toString()).join('|');
          if (rightMap.containsKey(keyString)) {
            for (var rightRow in rightMap[keyString]!) {
              newData.add(_joinRows(
                  other, leftRow, rightRow, leftCols, rightCols, suffixes));
              if (indicator != false) mergeIndicatorValues.add('both');
            }
          }
        }
        break;

      case 'left':
        for (var leftRow in _data) {
          final keyValues = leftIndices.map((idx) => leftRow[idx]).toList();
          // Handle null values in join keys
          if (keyValues.any((v) => v == null)) {
            // Left rows with null keys are kept but don't match anything
            newData.add(_joinRowsWithNull(
                leftRow, true, leftCols, rightCols, other._columns, suffixes));
            if (indicator != false) mergeIndicatorValues.add('left_only');
            continue;
          }
          final keyString = keyValues.map((v) => v.toString()).join('|');
          if (rightMap.containsKey(keyString)) {
            for (var rightRow in rightMap[keyString]!) {
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
        final leftMap = <String, List<List<dynamic>>>{};
        for (var leftRow in _data) {
          final keyValues = leftIndices.map((idx) => leftRow[idx]).toList();
          // Skip rows with null values in join keys
          if (keyValues.any((v) => v == null)) {
            continue;
          }
          final keyString = keyValues.map((v) => v.toString()).join('|');
          leftMap.putIfAbsent(keyString, () => []);
          leftMap[keyString]!.add(leftRow);
        }

        for (var rightRow in other._data) {
          final keyValues = rightIndices.map((idx) => rightRow[idx]).toList();
          // Handle null values in join keys
          if (keyValues.any((v) => v == null)) {
            // Right rows with null keys are kept but don't match anything
            newData.add(_joinRowsWithNull(
                rightRow, false, leftCols, rightCols, _columns, suffixes));
            if (indicator != false) mergeIndicatorValues.add('right_only');
            continue;
          }
          final keyString = keyValues.map((v) => v.toString()).join('|');
          if (leftMap.containsKey(keyString)) {
            for (var leftRow in leftMap[keyString]!) {
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
        final Set<String> processedRightKeys =
            {}; // To track right keys already matched

        for (var leftRow in _data) {
          final keyValues = leftIndices.map((idx) => leftRow[idx]).toList();
          // Handle null values in join keys
          if (keyValues.any((v) => v == null)) {
            // Left rows with null keys are kept but don't match anything
            newData.add(_joinRowsWithNull(
                leftRow, true, leftCols, rightCols, other._columns, suffixes));
            if (indicator != false) mergeIndicatorValues.add('left_only');
            continue;
          }
          final keyString = keyValues.map((v) => v.toString()).join('|');
          bool matched = false;
          if (rightMap.containsKey(keyString)) {
            for (var rightRow in rightMap[keyString]!) {
              newData.add(_joinRows(
                  other, leftRow, rightRow, leftCols, rightCols, suffixes));
              if (indicator != false) mergeIndicatorValues.add('both');
              matched = true;
            }
            processedRightKeys.add(keyString);
          }
          if (!matched) {
            newData.add(_joinRowsWithNull(
                leftRow, true, leftCols, rightCols, other._columns, suffixes));
            if (indicator != false) mergeIndicatorValues.add('left_only');
          }
        }

        // Add remaining right-only rows (including those with null keys)
        for (var rightRow in other._data) {
          final keyValues = rightIndices.map((idx) => rightRow[idx]).toList();
          if (keyValues.any((v) => v == null)) {
            // Right rows with null keys are kept but don't match anything
            newData.add(_joinRowsWithNull(
                rightRow, false, leftCols, rightCols, _columns, suffixes));
            if (indicator != false) mergeIndicatorValues.add('right_only');
          }
        }
        
        // Add remaining right-only rows with valid keys
        rightMap.forEach((keyString, rightRows) {
          if (!processedRightKeys.contains(keyString)) {
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
      if (resultDf.hasColumn(indicatorColName)) {
        // Add suffix if indicator column name conflicts
        int suffixNum = 1;
        String baseName = indicatorColName;
        while (resultDf.hasColumn(indicatorColName)) {
          indicatorColName = '${baseName}_$suffixNum';
          suffixNum++;
        }
      }
      resultDf.addColumn(indicatorColName, defaultValue: mergeIndicatorValues);
    }

    return resultDf;
  }

  /// Computes the pairwise correlation of numerical columns in the DataFrame.
  ///
  /// This method calculates the Pearson correlation coefficient between all pairs
  /// of numerical columns. Non-numeric columns are ignored.
  ///
  /// Returns:
  /// A new `DataFrame` representing the correlation matrix. The index and columns
  /// of this matrix are the names of the numerical columns from the original DataFrame.
  /// Each cell `(i, j)` in the matrix contains the correlation coefficient between
  /// column `i` and column `j`.
  ///
  /// Throws:
  /// - `StateError` if no numeric columns are found in the DataFrame.
  ///
  /// Note:
  /// - The Pearson correlation coefficient ranges from -1 to +1.
  /// - A value of +1 implies a perfect positive linear correlation.
  /// - A value of -1 implies a perfect negative linear correlation.
  /// - A value of 0 implies no linear correlation.
  /// - If a column has no variance (all values are the same), correlation with it will be 0 or NaN.
  /// - `double.nan` is returned if correlation cannot be computed (e.g., due to insufficient data or zero variance).
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [5, 4, 3, 2, 1],
  ///   'C': [2, 4, 5, 4, 2],
  ///   'D': ['x', 'y', 'z', 'p', 'q'] // Non-numeric
  /// });
  ///
  /// var corrMatrix = df.corr();
  /// print(corrMatrix);
  /// // Output (example, exact floating point values might vary slightly):
  /// //          A         B         C
  /// // A   1.000000 -1.000000  0.000000
  /// // B  -1.000000  1.000000  0.000000
  /// // C   0.000000  0.000000  1.000000
  /// ```
  DataFrame corr() {
    final List<String> numericColumnNames = [];
    final List<int> numericIndices = [];

    for (var i = 0; i < _columns.length; i++) {
      // Check if the column is likely numeric by inspecting its first non-null value's type
      // This is a heuristic; a more robust way would be to have dtype info per column.
      dynamic firstNonNullValue;
      for (var row in _data) {
        if (row[i] != null && row[i] != replaceMissingValueWith) {
          firstNonNullValue = row[i];
          break;
        }
      }
      if (firstNonNullValue is num) {
        numericColumnNames.add(_columns[i].toString());
        numericIndices.add(i);
      }
    }

    if (numericColumnNames.isEmpty) {
      throw StateError('No numeric columns found for correlation calculation.');
    }

    final List<List<dynamic>> correlationData = [];
    final List<dynamic> correlationIndex =
        List<dynamic>.from(numericColumnNames);

    for (var i = 0; i < numericIndices.length; i++) {
      final List<dynamic> rowData = [];
      final colIndex1 = numericIndices[i];
      final col1Data =
          _data.map((row) => row[colIndex1]).whereType<num>().toList();

      for (var j = 0; j < numericIndices.length; j++) {
        final colIndex2 = numericIndices[j];
        final col2Data =
            _data.map((row) => row[colIndex2]).whereType<num>().toList();

        final correlation = _calculateCorrelation(col1Data, col2Data);
        rowData.add(correlation);
      }
      correlationData.add(rowData);
    }
    return DataFrame._(List<dynamic>.from(numericColumnNames), correlationData,
        index: correlationIndex);
  }

  /// Private helper to calculate Pearson correlation coefficient between two lists of numbers.
  ///
  /// Parameters:
  /// - `x`: The first `List<num>`.
  /// - `y`: The second `List<num>`.
  ///
  /// Returns:
  /// The Pearson correlation coefficient as a `double`. Returns `double.nan` if
  /// correlation cannot be computed (e.g., lists are different lengths, empty, or have zero variance).
  double _calculateCorrelation(List<num> x, List<num> y) {
    if (x.length != y.length || x.isEmpty) {
      return double
          .nan; // Cannot compute correlation if lengths differ or lists are empty
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
      throw ArgumentError(
          'Column $colName contains no valid numeric data for binning');
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
        binEdges = List.generate(bins + 1, (i) => min + i * (max - min) / bins);
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
        throw ArgumentError('labels must have length equal to bins.length - 1');
      }
      binLabels = labels;
    } else {
      binLabels = [];
      for (var i = 0; i < binEdges.length - 1; i++) {
        // For right=false, all left brackets are '[' regardless of includeLowest
        final leftBracket =
            right ? ((i == 0 && includeLowest) ? '[' : '(') : '[';

        // For right=false, all right brackets are ')' except the last one which is ']'
        final rightBracket =
            (i == binEdges.length - 2) ? ']' : (right ? ']' : ')');

        // Format with specified decimal places
        final formattedLeft = binEdges[i].toStringAsFixed(decimalPlaces);
        final formattedRight = binEdges[i + 1].toStringAsFixed(decimalPlaces);

        binLabels
            .add('$leftBracket$formattedLeft, $formattedRight$rightBracket');
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
          inLeftBoundary =
              (j == 0 && includeLowest) ? value >= leftEdge : value > leftEdge;
          inRightBoundary = value <= rightEdge;
        } else {
          // For right=false: [left, right) or [left, right] for the last bin
          inLeftBoundary = value >= leftEdge;
          inRightBoundary = (j == binEdges.length - 2)
              ? value <= rightEdge
              : value < rightEdge;
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
        dynamic firstNonNull = seriesData.firstWhere(
            (val) => val != replaceMissingValueWith,
            orElse: () => null);
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
      for (var val in originalSeries.data) {
        if (val == replaceMissingValueWith) {
          hasNa = true;
        } else {
          if (uniqueValues.add(val)) {
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
        categories
            .add(replaceMissingValueWith); // Add a placeholder for NA category
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
          while (resultDf.hasColumn(tempName)) {
            tempName = '${newColName}_$suffix';
            suffix++;
          }
          newColName = tempName;
        }

        List<int> dummyValues = [];
        for (var val in originalSeries.data) {
          if (category == replaceMissingValueWith) {
            // This is the NA dummy column
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

/// Extension providing interpolation methods for DataFrame.
///
/// This extension adds various interpolation methods to fill missing values
/// in DataFrame columns using different mathematical approaches.
extension DataFrameInterpolation on DataFrame {
  /// Interpolates missing values in the DataFrame using the specified method.
  ///
  /// This method fills missing values (null or replaceMissingValueWith)
  /// using various interpolation techniques applied column-wise or row-wise.
  ///
  /// Parameters:
  ///   - `method`: The interpolation method to use. Options:
  ///     - 'linear': Linear interpolation between adjacent non-missing values
  ///     - 'polynomial': Polynomial interpolation (requires `order` parameter)
  ///     - 'spline': Cubic spline interpolation
  ///   - `axis`: The axis along which to interpolate:
  ///     - 0: Interpolate along rows (column-wise interpolation)
  ///     - 1: Interpolate along columns (row-wise interpolation)
  ///   - `limit`: Maximum number of consecutive missing values to interpolate.
  ///     If null, interpolates all missing values.
  ///   - `limitDirection`: Direction to apply the limit:
  ///     - 'forward': Apply limit in forward direction
  ///     - 'backward': Apply limit in backward direction
  ///     - 'both': Apply limit in both directions
  ///   - `order`: Polynomial order for polynomial interpolation (default: 2)
  ///   - `columns`: List of column names to interpolate. If null, interpolates all numeric columns.
  ///
  /// Returns:
  ///   A new DataFrame with interpolated values. The original DataFrame is unchanged.
  ///
  /// Throws:
  ///   - `ArgumentError` if method is not supported or axis is invalid
  ///   - `StateError` if there are insufficient non-missing values for interpolation
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1.0, null, 3.0, null, 5.0],
  ///   'B': [10.0, 20.0, null, 40.0, 50.0]
  /// });
  ///
  /// // Linear interpolation along columns (axis=0)
  /// var interpolated = df.interpolate(method: 'linear');
  /// // Result: A column becomes [1.0, 2.0, 3.0, 4.0, 5.0]
  /// //         B column becomes [10.0, 20.0, 30.0, 40.0, 50.0]
  ///
  /// // With limit
  /// var limited = df.interpolate(method: 'linear', limit: 1);
  /// ```
  DataFrame interpolate({
    String method = 'linear',
    int axis = 0,
    int? limit,
    String limitDirection = 'forward',
    int order = 2,
    List<String>? columns,
  }) {
    if (!['linear', 'polynomial', 'spline'].contains(method)) {
      throw ArgumentError(
          "method must be one of 'linear', 'polynomial', 'spline'");
    }

    if (axis != 0 && axis != 1) {
      throw ArgumentError("axis must be 0 (columns) or 1 (rows)");
    }

    if (!['forward', 'backward', 'both'].contains(limitDirection)) {
      throw ArgumentError(
          "limitDirection must be one of 'forward', 'backward', 'both'");
    }

    if (method == 'polynomial' && order < 1) {
      throw ArgumentError(
          "order must be at least 1 for polynomial interpolation");
    }

    // Create a copy of the DataFrame
    Map<String, List<dynamic>> dataMap = {};
    for (var entry in toMap().entries) {
      dataMap[entry.key.toString()] = entry.value.data;
    }
    DataFrame result = DataFrame.fromMap(dataMap);

    if (axis == 0) {
      // Interpolate along columns (column-wise)
      List<String> columnsToInterpolate = columns ??
          _columns
              .where((col) => _isNumericColumn(col.toString()))
              .map((col) => col.toString())
              .toList();

      for (String colName in columnsToInterpolate) {
        if (hasColumn(colName)) {
          Series column = result[colName];
          try {
            Series interpolatedColumn = column.interpolate(
              method: method,
              limit: limit,
              limitDirection: limitDirection,
              order: order,
            );
            result.addColumn(colName, defaultValue: interpolatedColumn.data);
          } catch (e) {
            // Skip columns that can't be interpolated (e.g., insufficient data)
            continue;
          }
        }
      }
    } else {
      // Interpolate along rows (row-wise)
      for (int rowIndex = 0; rowIndex < shape.rows; rowIndex++) {
        List<dynamic> rowData = [];
        List<String> columnNames = [];

        // Get numeric columns for this row
        for (var col in _columns) {
          String colName = col.toString();
          if (columns == null || columns.contains(colName)) {
            if (_isNumericColumn(colName)) {
              rowData.add(result[colName].data[rowIndex]);
              columnNames.add(colName);
            }
          }
        }

        if (rowData.isNotEmpty) {
          // Create a temporary series for this row
          Series rowSeries = Series(rowData, name: 'row_$rowIndex');

          try {
            Series interpolatedRow = rowSeries.interpolate(
              method: method,
              limit: limit,
              limitDirection: limitDirection,
              order: order,
            );

            // Update the result DataFrame with interpolated values
            for (int i = 0; i < columnNames.length; i++) {
              result[columnNames[i]].data[rowIndex] = interpolatedRow.data[i];
            }
          } catch (e) {
            // Skip rows that can't be interpolated
            continue;
          }
        }
      }
    }

    return result;
  }

  /// Checks if a column contains primarily numeric data.
  bool _isNumericColumn(String columnName) {
    if (!hasColumn(columnName)) return false;

    Series column = this[columnName];
    int numericCount = 0;
    int totalNonMissing = 0;

    for (var value in column.data) {
      if (!_isValueMissing(value)) {
        totalNonMissing++;
        if (value is num) {
          numericCount++;
        }
      }
    }

    // Consider a column numeric if at least 80% of non-missing values are numeric
    return totalNonMissing > 0 && (numericCount / totalNonMissing) >= 0.8;
  }

  /// Helper method to check if a value is missing.
  bool _isValueMissing(dynamic value) {
    return value == null ||
        (replaceMissingValueWith != null && value == replaceMissingValueWith);
  }

  /// Enhanced fillna method with limit and direction parameters for DataFrame.
  ///
  /// This method provides advanced missing value filling capabilities with
  /// limit controls and directional constraints.
  ///
  /// Parameters:
  ///   - `value`: The value to use for filling missing entries, or a Map for column-specific values.
  ///   - `method`: The method to use for filling ('ffill' or 'bfill').
  ///   - `limit`: Maximum number of consecutive missing values to fill.
  ///   - `limitDirection`: Direction to apply the limit ('forward', 'backward', 'both').
  ///   - `columns`: List of column names to fill. If null, fills all columns.
  ///
  /// Returns:
  ///   A new DataFrame with missing values filled according to the specified parameters.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1.0, null, null, 4.0],
  ///   'B': [null, 2.0, null, null]
  /// });
  ///
  /// // Fill with limit
  /// var filled = df.fillnaAdvanced(method: 'ffill', limit: 1);
  /// ```
  DataFrame fillnaAdvanced({
    dynamic value,
    String? method,
    int? limit,
    String limitDirection = 'forward',
    List<String>? columns,
  }) {
    if (method != null && !['ffill', 'bfill'].contains(method)) {
      throw ArgumentError("method must be either 'ffill' or 'bfill'");
    }

    if (!['forward', 'backward', 'both'].contains(limitDirection)) {
      throw ArgumentError(
          "limitDirection must be one of 'forward', 'backward', 'both'");
    }

    // Create a copy of the DataFrame
    Map<String, List<dynamic>> dataMap = {};
    for (var entry in toMap().entries) {
      dataMap[entry.key.toString()] = entry.value.data;
    }
    DataFrame result = DataFrame.fromMap(dataMap);

    List<String> columnsToFill =
        columns ?? _columns.map((col) => col.toString()).toList();

    for (String colName in columnsToFill) {
      if (hasColumn(colName)) {
        Series column = result[colName];

        // Determine the fill value for this column
        dynamic columnFillValue = value;
        if (value is Map<String, dynamic> && value.containsKey(colName)) {
          columnFillValue = value[colName];
        } else if (value is Map<String, dynamic>) {
          continue; // Skip columns not specified in the map
        }

        Series filledColumn;
        if (method != null) {
          filledColumn = column.fillna(
            method: method,
            limit: limit,
            limitDirection: limitDirection,
          );
        } else if (columnFillValue != null) {
          filledColumn = column.fillna(
            value: columnFillValue,
            limit: limit,
            limitDirection: limitDirection,
          );
        } else {
          continue; // Skip if no value or method specified
        }

        result.addColumn(colName, defaultValue: filledColumn.data);
      }
    }

    return result;
  }

  /// Forward fill missing values in DataFrame columns.
  ///
  /// Parameters:
  ///   - `limit`: Maximum number of consecutive missing values to fill.
  ///   - `limitDirection`: Direction to apply the limit.
  ///   - `columns`: List of column names to fill. If null, fills all columns.
  ///
  /// Returns:
  ///   A new DataFrame with forward-filled values.
  DataFrame ffillDataFrame({
    int? limit,
    String limitDirection = 'forward',
    List<String>? columns,
  }) {
    return fillnaAdvanced(
      method: 'ffill',
      limit: limit,
      limitDirection: limitDirection,
      columns: columns,
    );
  }

  /// Backward fill missing values in DataFrame columns.
  ///
  /// Parameters:
  ///   - `limit`: Maximum number of consecutive missing values to fill.
  ///   - `limitDirection`: Direction to apply the limit.
  ///   - `columns`: List of column names to fill. If null, fills all columns.
  ///
  /// Returns:
  ///   A new DataFrame with backward-filled values.
  DataFrame bfillDataFrame({
    int? limit,
    String limitDirection = 'forward',
    List<String>? columns,
  }) {
    return fillnaAdvanced(
      method: 'bfill',
      limit: limit,
      limitDirection: limitDirection,
      columns: columns,
    );
  }
}

/// Extension providing missing data analysis tools for DataFrame.
///
/// This extension adds comprehensive methods for analyzing missing data patterns,
/// providing insights into data quality and completeness.
extension DataFrameMissingDataAnalysis on DataFrame {
  /// Returns a DataFrame showing missing data patterns.
  ///
  /// This method creates a boolean DataFrame where True indicates missing values
  /// and False indicates non-missing values, making it easy to visualize
  /// missing data patterns.
  ///
  /// Returns:
  ///   A DataFrame with the same shape as the original, containing boolean values
  ///   indicating missing data locations.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, null, 3],
  ///   'B': [null, 2, 3],
  ///   'C': [1, 2, null]
  /// });
  ///
  /// var missingPattern = df.missingDataPattern();
  /// // Returns DataFrame with True/False values showing missing patterns
  /// ```
  DataFrame missingDataPattern() {
    Map<String, List<dynamic>> patternData = {};

    for (var col in _columns) {
      String colName = col.toString();
      Series column = this[colName];
      List<bool> missingPattern =
          column.data.map((value) => _isValueMissing(value)).toList();
      patternData[colName] = missingPattern;
    }

    return DataFrame.fromMap(patternData);
  }

  /// Returns summary statistics about missing data in the DataFrame.
  ///
  /// This method provides comprehensive statistics about missing values
  /// including counts, percentages, and patterns.
  ///
  /// Returns:
  ///   A DataFrame containing missing data statistics for each column.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, null, 3, null],
  ///   'B': [null, 2, 3, 4],
  ///   'C': [1, 2, 3, 4]
  /// });
  ///
  /// var summary = df.missingDataSummary();
  /// // Returns DataFrame with columns: missing_count, missing_percentage, non_missing_count
  /// ```
  DataFrame missingDataSummary() {
    List<String> columnNames = [];
    List<int> missingCounts = [];
    List<double> missingPercentages = [];
    List<int> nonMissingCounts = [];
    List<int> totalCounts = [];

    for (var col in _columns) {
      String colName = col.toString();
      Series column = this[colName];

      int missingCount = 0;
      int nonMissingCount = 0;

      for (var value in column.data) {
        if (_isValueMissing(value)) {
          missingCount++;
        } else {
          nonMissingCount++;
        }
      }

      int total = missingCount + nonMissingCount;
      double missingPercentage = total > 0 ? (missingCount / total) * 100 : 0.0;

      columnNames.add(colName);
      missingCounts.add(missingCount);
      missingPercentages.add(missingPercentage);
      nonMissingCounts.add(nonMissingCount);
      totalCounts.add(total);
    }

    return DataFrame.fromMap({
      'column': columnNames,
      'missing_count': missingCounts,
      'missing_percentage': missingPercentages,
      'non_missing_count': nonMissingCounts,
      'total_count': totalCounts,
    });
  }

  /// Identifies rows with missing data and their patterns.
  ///
  /// This method analyzes which rows contain missing values and groups
  /// them by their missing data patterns.
  ///
  /// Parameters:
  ///   - `includeComplete`: If true, includes rows with no missing values.
  ///
  /// Returns:
  ///   A Map where keys are missing data patterns (as strings) and values
  ///   are lists of row indices that match each pattern.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, null, 3, null],
  ///   'B': [null, 2, null, 4],
  ///   'C': [1, null, 3, 4]
  /// });
  ///
  /// var patterns = df.missingDataRowPatterns();
  /// // Returns: {'A_missing,B_missing': [0], 'A_missing,C_missing': [1], ...}
  /// ```
  Map<String, List<int>> missingDataRowPatterns(
      {bool includeComplete = false}) {
    Map<String, List<int>> patterns = {};

    for (int rowIndex = 0; rowIndex < shape.rows; rowIndex++) {
      List<String> missingColumns = [];

      for (var col in _columns) {
        String colName = col.toString();
        Series column = this[colName];

        if (_isValueMissing(column.data[rowIndex])) {
          missingColumns.add('${colName}_missing');
        }
      }

      String pattern =
          missingColumns.isEmpty ? 'complete' : missingColumns.join(',');

      if (includeComplete || pattern != 'complete') {
        if (!patterns.containsKey(pattern)) {
          patterns[pattern] = [];
        }
        patterns[pattern]!.add(rowIndex);
      }
    }

    return patterns;
  }

  /// Returns the completeness ratio for each column.
  ///
  /// This method calculates what percentage of each column contains
  /// non-missing values.
  ///
  /// Returns:
  ///   A Series containing completeness ratios (0.0 to 1.0) for each column.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, null, 3, 4],  // 75% complete
  ///   'B': [1, 2, 3, 4],     // 100% complete
  ///   'C': [null, null, null, null]  // 0% complete
  /// });
  ///
  /// var completeness = df.columnCompleteness();
  /// // Returns Series: A: 0.75, B: 1.0, C: 0.0
  /// ```
  Series columnCompleteness() {
    List<String> columnNames = [];
    List<double> completenessRatios = [];

    for (var col in _columns) {
      String colName = col.toString();
      Series column = this[colName];

      int nonMissingCount = 0;
      int totalCount = column.data.length;

      for (var value in column.data) {
        if (!_isValueMissing(value)) {
          nonMissingCount++;
        }
      }

      double completeness = totalCount > 0 ? nonMissingCount / totalCount : 0.0;

      columnNames.add(colName);
      completenessRatios.add(completeness);
    }

    return Series(completenessRatios, name: 'completeness', index: columnNames);
  }

  /// Identifies columns that have missing values.
  ///
  /// Parameters:
  ///   - `threshold`: Minimum percentage of missing values to include a column (0.0 to 1.0).
  ///
  /// Returns:
  ///   A list of column names that have missing values above the threshold.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, null, 3, 4],
  ///   'B': [1, 2, 3, 4],
  ///   'C': [null, null, 3, 4]
  /// });
  ///
  /// var columnsWithMissing = df.columnsWithMissingData(threshold: 0.1);
  /// // Returns: ['A', 'C'] (columns with >10% missing values)
  /// ```
  List<String> columnsWithMissingData({double threshold = 0.0}) {
    if (threshold < 0.0 || threshold > 1.0) {
      throw ArgumentError('threshold must be between 0.0 and 1.0');
    }

    List<String> columnsWithMissing = [];

    for (var col in _columns) {
      String colName = col.toString();
      Series column = this[colName];

      int missingCount = 0;
      int totalCount = column.data.length;

      for (var value in column.data) {
        if (_isValueMissing(value)) {
          missingCount++;
        }
      }

      double missingRatio = totalCount > 0 ? missingCount / totalCount : 0.0;

      if (missingRatio > threshold) {
        columnsWithMissing.add(colName);
      }
    }

    return columnsWithMissing;
  }

  /// Creates a visualization-friendly summary of missing data patterns.
  ///
  /// This method generates a compact representation of missing data patterns
  /// that can be used for creating visualizations or reports.
  ///
  /// Returns:
  ///   A Map containing various missing data metrics and patterns.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, null, 3],
  ///   'B': [null, 2, 3],
  ///   'C': [1, 2, null]
  /// });
  ///
  /// var vizData = df.missingDataVisualizationSummary();
  /// // Returns comprehensive missing data analysis for visualization
  /// ```
  Map<String, dynamic> missingDataVisualizationSummary() {
    // Get basic statistics
    DataFrame summary = missingDataSummary();
    Series completeness = columnCompleteness();
    Map<String, List<int>> rowPatterns =
        missingDataRowPatterns(includeComplete: true);

    // Calculate overall statistics
    int totalCells = shape.rows * shape.columns;
    int totalMissingCells = 0;

    for (var col in _columns) {
      String colName = col.toString();
      Series column = this[colName];
      for (var value in column.data) {
        if (_isValueMissing(value)) {
          totalMissingCells++;
        }
      }
    }

    double overallMissingPercentage =
        totalCells > 0 ? (totalMissingCells / totalCells) * 100 : 0.0;

    // Find most and least complete columns
    String mostCompleteColumn = '';
    String leastCompleteColumn = '';
    double maxCompleteness = -1.0;
    double minCompleteness = 2.0;

    for (int i = 0; i < completeness.data.length; i++) {
      double comp = completeness.data[i] as double;
      String colName = completeness.index[i].toString();

      if (comp > maxCompleteness) {
        maxCompleteness = comp;
        mostCompleteColumn = colName;
      }

      if (comp < minCompleteness) {
        minCompleteness = comp;
        leastCompleteColumn = colName;
      }
    }

    return {
      'total_cells': totalCells,
      'total_missing_cells': totalMissingCells,
      'overall_missing_percentage': overallMissingPercentage,
      'columns_with_missing': columnsWithMissingData(),
      'most_complete_column': mostCompleteColumn,
      'least_complete_column': leastCompleteColumn,
      'max_completeness': maxCompleteness,
      'min_completeness': minCompleteness,
      'unique_missing_patterns': rowPatterns.keys.length,
      'row_patterns': rowPatterns,
      'column_summary': summary.toMap(),
      'column_completeness': completeness.toList(),
    };
  }
}
