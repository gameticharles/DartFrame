// ignore_for_file: unnecessary_type_check

part of 'data_frame.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first

class DataFrameILocAccessor {
  final DataFrame _df;

  DataFrameILocAccessor(this._df);

  /// Accesses rows of the DataFrame by integer position.
  ///
  /// Allows selection of a single row or multiple rows.
  ///
  /// Parameters:
  /// - `rowSelector`: An `int` for a single row, or a `List<int>` for multiple rows.
  ///
  /// Returns:
  /// - A `Series` if a single row is selected. The Series' name will be the row's original index label (or the integer position if no index exists), and its index will be the DataFrame's column labels.
  /// - A `DataFrame` if multiple rows are selected. The new DataFrame will retain the original column labels and selected rows' index labels (or integer positions if no index exists).
  ///
  /// Examples:
  /// ```dart
  /// var df = DataFrame([
  ///   {'colA': 1, 'colB': 2},
  ///   {'colA': 3, 'colB': 4},
  /// ], columns: ['colA', 'colB'], index: ['row1', 'row2']);
  ///
  /// // Select a single row (returns a Series)
  /// var row = df.iloc[0];
  /// print(row);
  /// // Output:
  /// // Series(name: row1, index: [colA, colB], data: [1, 2])
  ///
  /// // Select multiple rows (returns a DataFrame)
  /// var rows = df.iloc[[0, 1]];
  /// print(rows);
  /// // Output:
  /// // DataFrame(columns: [colA, colB], index: [row1, row2], data:
  /// // [[1, 2],
  /// //  [3, 4]])
  /// ```
  dynamic operator [](dynamic rowSelector) {
    if (rowSelector is int) {
      // Single row selection
      if (rowSelector < 0 || rowSelector >= _df._data.length) {
        throw RangeError.index(
            rowSelector, _df._data, 'Row index out of bounds');
      }

      // Return a Series representing the row
      return Series(
        List.from(_df._data[rowSelector]), // Copy data
        name: _df.index.isNotEmpty && rowSelector < _df.index.length
            ? _df.index[rowSelector]
            : rowSelector.toString(),
        index: List.from(_df._columns), // Copy column names for series index
      );
    } else if (rowSelector is List<int>) {
      // Multiple row selection
      for (int rIdx in rowSelector) {
        if (rIdx < 0 || rIdx >= _df._data.length) {
          throw RangeError.index(rIdx, _df._data, 'Row index out of bounds');
        }
      }

      List<List<dynamic>> selectedRowsData = rowSelector
          .map((rIdx) => List<dynamic>.from(_df._data[rIdx]))
          .toList();
      List<dynamic> selectedRowIndex = rowSelector
          .map((rIdx) => _df.index.isNotEmpty && rIdx < _df.index.length
              ? _df.index[rIdx]
              : rIdx)
          .toList();

      // Return a DataFrame with selected rows
      return DataFrame(
        selectedRowsData, // Deep copy
        columns: List.from(_df._columns), // Copy
        index: selectedRowIndex,
      );
    } else {
      throw ArgumentError(
          'Invalid row selector type: ${rowSelector.runtimeType}');
    }
  }

  /// Accesses a selection of rows and columns from the DataFrame by integer position.
  ///
  /// This method allows for more complex selections, including:
  /// - A single row (returns a `Series`).
  /// - Multiple rows (returns a `DataFrame`).
  /// - A single value at a specific row and column intersection.
  /// - A `Series` representing a single row with selected columns.
  /// - A `Series` representing a single column with selected rows.
  /// - A `DataFrame` representing a sub-selection of rows and columns.
  ///
  /// Parameters:
  /// - `rowSelector`: An `int` for a single row, or a `List<int>` for multiple rows.
  /// - `colSelector` (optional): An `int` for a single column, a `List<int>` for multiple columns. If omitted, all columns are selected for the given `rowSelector`.
  ///
  /// Returns:
  /// - A single value if `rowSelector` and `colSelector` are both single `int`s.
  /// - A `Series` if `rowSelector` is an `int` and `colSelector` is a `List<int>` (selects multiple columns for a single row).
  /// - A `Series` if `rowSelector` is a `List<int>` and `colSelector` is an `int` (selects a single column for multiple rows).
  /// - A `DataFrame` if `rowSelector` and `colSelector` are both `List<int>` (selects multiple rows and columns).
  /// - A `Series` if `rowSelector` is an `int` and `colSelector` is `null` (equivalent to `df.iloc[rowIndex]`).
  /// - A `DataFrame` if `rowSelector` is a `List<int>` and `colSelector` is `null` (equivalent to `df.iloc[[rowIndices]]`).
  ///
  /// Examples:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9],
  /// ], columns: ['A', 'B', 'C'], index: ['X', 'Y', 'Z']);
  ///
  /// // Select a single value
  /// var value = df.iloc(0, 1); // Returns 2
  /// print(value);
  ///
  /// // Select a single row (returns a Series)
  /// var row = df.iloc(0);
  /// print(row);
  /// // Output:
  /// // Series(name: X, index: [A, B, C], data: [1, 2, 3])
  ///
  /// // Select multiple rows for all columns (returns a DataFrame)
  /// var rowsDf = df.iloc([0, 2]);
  /// print(rowsDf);
  /// // Output:
  /// // DataFrame(columns: [A, B, C], index: [X, Z], data:
  /// // [[1, 2, 3],
  /// //  [7, 8, 9]])
  ///
  /// // Select a single row with specific columns (returns a Series)
  /// var rowWithCols = df.iloc(0, [0, 2]);
  /// print(rowWithCols);
  /// // Output:
  /// // Series(name: X, index: [A, C], data: [1, 3])
  ///
  /// // Select multiple rows for a single column (returns a Series)
  /// var colForRows = df.iloc([0, 2], 1);
  /// print(colForRows);
  /// // Output:
  /// // Series(name: B, index: [X, Z], data: [2, 8])
  ///
  /// // Select multiple rows and multiple columns (returns a DataFrame)
  /// var subDf = df.iloc([0, 2], [0, 2]);
  /// print(subDf);
  /// // Output:
  /// // DataFrame(columns: [A, C], index: [X, Z], data:
  /// // [[1, 3],
  /// //  [7, 9]])
  /// ```
  dynamic call(dynamic rowSelector, [dynamic colSelector]) {
    if (colSelector == null) {
      // Just use the [] operator if no column selector
      return this[rowSelector];
    }

    if (rowSelector is int) {
      // Single row selection
      if (rowSelector < 0 || rowSelector >= _df._data.length) {
        throw RangeError.index(
            rowSelector, _df._data, 'Row index out of bounds');
      }

      if (colSelector is int) {
        // df.iloc(rowIndex, colIndex) -> Single value
        if (colSelector < 0 || colSelector >= _df._columns.length) {
          throw RangeError.index(
              colSelector, _df._columns, 'Column index out of bounds');
        }
        return _df._data[rowSelector][colSelector];
      } else if (colSelector is List<int>) {
        // df.iloc(rowIndex, [colIndex1, colIndex2]) -> Series
        List<dynamic> selectedData = [];
        List<dynamic> selectedColumnNames = [];
        for (int colIdx in colSelector) {
          if (colIdx < 0 || colIdx >= _df._columns.length) {
            throw RangeError.index(
                colIdx, _df._columns, 'Column index out of bounds');
          }
          selectedData.add(_df._data[rowSelector][colIdx]);
          selectedColumnNames.add(_df._columns[colIdx]);
        }
        return Series(
          selectedData,
          name: _df.index.isNotEmpty && rowSelector < _df.index.length
              ? _df.index[rowSelector]
              : rowSelector.toString(),
          index: selectedColumnNames,
        );
      } else {
        throw ArgumentError(
            'Invalid column selector type: ${colSelector.runtimeType}');
      }
    } else if (rowSelector is List<int>) {
      // Multiple row selection
      for (int rIdx in rowSelector) {
        if (rIdx < 0 || rIdx >= _df._data.length) {
          throw RangeError.index(rIdx, _df._data, 'Row index out of bounds');
        }
      }

      rowSelector.map((rIdx) => List<dynamic>.from(_df._data[rIdx])).toList();
      List<dynamic> selectedRowIndex = rowSelector
          .map((rIdx) => _df.index.isNotEmpty && rIdx < _df.index.length
              ? _df.index[rIdx]
              : rIdx)
          .toList();

      if (colSelector is int) {
        // df.iloc([rowIndex1, rowIndex2], colIndex) -> Series
        if (colSelector < 0 || colSelector >= _df._columns.length) {
          throw RangeError.index(
              colSelector, _df._columns, 'Column index out of bounds');
        }
        List<dynamic> columnData =
            rowSelector.map((rIdx) => _df._data[rIdx][colSelector]).toList();
        return Series(
          columnData,
          name: _df._columns[colSelector].toString(),
          index: selectedRowIndex,
        );
      } else if (colSelector is List<int>) {
        // df.iloc([rowIndex1, rowIndex2], [colIndex1, colIndex2]) -> DataFrame
        List<dynamic> selectedDfColumns = [];
        for (int cIdx in colSelector) {
          if (cIdx < 0 || cIdx >= _df._columns.length) {
            throw RangeError.index(
                cIdx, _df._columns, 'Column index out of bounds');
          }
          selectedDfColumns.add(_df._columns[cIdx]);
        }

        List<List<dynamic>> resultData = [];
        for (int rIdx in rowSelector) {
          List<dynamic> newRow = [];
          for (int cIdx in colSelector) {
            newRow.add(_df._data[rIdx][cIdx]);
          }
          resultData.add(newRow);
        }
        return DataFrame(
          resultData,
          columns: selectedDfColumns,
          index: selectedRowIndex,
        );
      } else {
        throw ArgumentError(
            'Invalid column selector type: ${colSelector.runtimeType}');
      }
    } else {
      throw ArgumentError(
          'Invalid row selector type: ${rowSelector.runtimeType}');
    }
  }
}

class DataFrameLocAccessor {
  final DataFrame _df;

  DataFrameLocAccessor(this._df);

  /// Accesses rows of the DataFrame by label.
  ///
  /// Allows selection of a single row or multiple rows using their index labels.
  ///
  /// Parameters:
  /// - `rowSelector`: A single row label, or a `List` of row labels.
  ///
  /// Returns:
  /// - A `Series` if a single row label is provided. The Series' name will be the row label, and its index will be the DataFrame's column labels.
  /// - A `DataFrame` if a `List` of row labels is provided. The new DataFrame will retain the original column labels and the selected rows' index labels.
  ///
  /// Throws:
  /// - `ArgumentError` if any of the provided row labels are not found in the DataFrame's index.
  ///
  /// Examples:
  /// ```dart
  /// var df = DataFrame([
  ///   {'colA': 1, 'colB': 2},
  ///   {'colA': 3, 'colB': 4},
  /// ], columns: ['colA', 'colB'], index: ['row1', 'row2']);
  ///
  /// // Select a single row by label (returns a Series)
  /// var row = df.loc['row1'];
  /// print(row);
  /// // Output:
  /// // Series(name: row1, index: [colA, colB], data: [1, 2])
  ///
  /// // Select multiple rows by label (returns a DataFrame)
  /// var rows = df.loc[['row1', 'row2']];
  /// print(rows);
  /// // Output:
  /// // DataFrame(columns: [colA, colB], index: [row1, row2], data:
  /// // [[1, 2],
  /// //  [3, 4]])
  /// ```
  dynamic operator [](dynamic rowSelector) {
    if (rowSelector is List) {
      // Handle list of row labels
      List<int> intRowIdxs = _getIntRowIndices(rowSelector);
      List<dynamic> selectedRowIndexLabels =
          intRowIdxs.map((idx) => _df.index[idx]).toList();

      // Return a DataFrame with selected rows
      List<List<dynamic>> selectedData = intRowIdxs
          .map((rIdx) => List<dynamic>.from(_df._data[rIdx]))
          .toList();
      return DataFrame(
        selectedData,
        columns: List.from(_df._columns),
        index: selectedRowIndexLabels,
      );
    } else {
      // Single row label
      List<int> intRowIdxList = _getIntRowIndices(rowSelector);
      if (intRowIdxList.isEmpty) {
        throw ArgumentError('Row label not found: $rowSelector');
      }
      int intRowIdx = intRowIdxList.first;

      // Return a Series representing the row
      List<dynamic> rowData = _df._data[intRowIdx];
      return Series(
        List.from(rowData),
        name: rowSelector.toString(),
        index: List.from(_df._columns),
      );
    }
  }

  /// Accesses a selection of rows and columns from the DataFrame by label.
  ///
  /// This method allows for more complex selections based on row and column labels, including:
  /// - A single row (returns a `Series`).
  /// - Multiple rows (returns a `DataFrame`).
  /// - A single value at a specific row and column label intersection.
  /// - A `Series` representing a single row with selected column labels.
  /// - A `Series` representing a single column with selected row labels.
  /// - A `DataFrame` representing a sub-selection of rows and columns by their labels.
  ///
  /// Parameters:
  /// - `rowSelector`: A single row label, or a `List` of row labels.
  /// - `colSelector` (optional): A single column label, or a `List` of column labels. If omitted, all columns are selected for the given `rowSelector`.
  ///
  /// Returns:
  /// - A single value if `rowSelector` and `colSelector` are both single labels.
  /// - A `Series` if `rowSelector` is a single label and `colSelector` is a `List` of labels (selects multiple columns for a single row).
  /// - A `Series` if `rowSelector` is a `List` of labels and `colSelector` is a single label (selects a single column for multiple rows).
  /// - A `DataFrame` if `rowSelector` and `colSelector` are both `List`s of labels (selects multiple rows and columns).
  /// - A `Series` if `rowSelector` is a single label and `colSelector` is `null` (equivalent to `df.loc[rowLabel]`).
  /// - A `DataFrame` if `rowSelector` is a `List` of labels and `colSelector` is `null` (equivalent to `df.loc[[rowLabels]]`).
  ///
  /// Throws:
  /// - `ArgumentError` if any of the provided row or column labels are not found.
  ///
  /// Examples:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9],
  /// ], columns: ['A', 'B', 'C'], index: ['X', 'Y', 'Z']);
  ///
  /// // Select a single value by labels
  /// var value = df.loc('X', 'B'); // Returns 2
  /// print(value);
  ///
  /// // Select a single row by label (returns a Series)
  /// var row = df.loc('X');
  /// print(row);
  /// // Output:
  /// // Series(name: X, index: [A, B, C], data: [1, 2, 3])
  ///
  /// // Select multiple rows for all columns by labels (returns a DataFrame)
  /// var rowsDf = df.loc(['X', 'Z']);
  /// print(rowsDf);
  /// // Output:
  /// // DataFrame(columns: [A, B, C], index: [X, Z], data:
  /// // [[1, 2, 3],
  /// //  [7, 8, 9]])
  ///
  /// // Select a single row with specific column labels (returns a Series)
  /// var rowWithCols = df.loc('X', ['A', 'C']);
  /// print(rowWithCols);
  /// // Output:
  /// // Series(name: X, index: [A, C], data: [1, 3])
  ///
  /// // Select multiple rows for a single column label (returns a Series)
  /// var colForRows = df.loc(['X', 'Z'], 'B');
  /// print(colForRows);
  /// // Output:
  /// // Series(name: B, index: [X, Z], data: [2, 8])
  ///
  /// // Select multiple rows and multiple column labels (returns a DataFrame)
  /// var subDf = df.loc(['X', 'Z'], ['A', 'C']);
  /// print(subDf);
  /// // Output:
  /// // DataFrame(columns: [A, C], index: [X, Z], data:
  /// // [[1, 3],
  /// //  [7, 9]])
  /// ```
  dynamic call(dynamic rowSelector, [dynamic colSelector]) {
    if (colSelector == null) {
      // Just use the [] operator if no column selector
      return this[rowSelector];
    }

    bool isSingleRow = rowSelector is! List;

    if (isSingleRow) {
      List<int> intRowIdxList = _getIntRowIndices(rowSelector);
      if (intRowIdxList.isEmpty) {
        throw ArgumentError('Row label not found: $rowSelector');
      }
      int intRowIdx = intRowIdxList.first;

      if (colSelector is List) {
        // df.loc(rowLabel, [colLabel1, colLabel2]) -> Series
        List<int> intColIdxs = _getIntColIndices(colSelector);
        List<dynamic> selectedData =
            intColIdxs.map((cIdx) => _df._data[intRowIdx][cIdx]).toList();
        List<dynamic> selectedColumnNames =
            intColIdxs.map((cIdx) => _df._columns[cIdx]).toList();
        return Series(
          selectedData,
          name: rowSelector.toString(),
          index: selectedColumnNames,
        );
      } else {
        // df.loc(rowLabel, colLabel) -> Single value
        List<int> intColIdxList = _getIntColIndices(colSelector);
        if (intColIdxList.isEmpty) {
          throw ArgumentError('Column label not found: $colSelector');
        }
        int intColIdx = intColIdxList.first;
        return _df._data[intRowIdx][intColIdx];
      }
    } else if (rowSelector is List) {
      // Multiple row labels
      List<int> intRowIdxs = _getIntRowIndices(rowSelector);
      List<dynamic> selectedRowIndexLabels =
          intRowIdxs.map((idx) => _df.index[idx]).toList();

      if (colSelector is List) {
        // df.loc([rowLabel1, rowLabel2], [colLabel1, colLabel2]) -> DataFrame
        List<int> intColIdxs = _getIntColIndices(colSelector);
        List<dynamic> selectedDfColumns =
            intColIdxs.map((cIdx) => _df._columns[cIdx]).toList();

        List<List<dynamic>> resultData = [];
        for (int rIdx in intRowIdxs) {
          List<dynamic> newRow = [];
          for (int cIdx in intColIdxs) {
            newRow.add(_df._data[rIdx][cIdx]);
          }
          resultData.add(newRow);
        }
        return DataFrame(
          resultData,
          columns: selectedDfColumns,
          index: selectedRowIndexLabels,
        );
      } else {
        // df.loc([rowLabel1, rowLabel2], colLabel) -> Series
        List<int> intColIdxList = _getIntColIndices(colSelector);
        if (intColIdxList.isEmpty) {
          throw ArgumentError('Column label not found: $colSelector');
        }
        int intColIdx = intColIdxList.first;

        List<dynamic> columnData =
            intRowIdxs.map((rIdx) => _df._data[rIdx][intColIdx]).toList();
        return Series(
          columnData,
          name: colSelector.toString(),
          index: selectedRowIndexLabels,
        );
      }
    } else {
      throw ArgumentError(
          'Invalid row selector type: ${rowSelector.runtimeType}');
    }
  }

  /// Converts a single row label or a list of row labels into their corresponding integer indices.
  ///
  /// This helper method is used internally by `loc` to translate human-readable labels
  /// into the integer-based indices required for accessing data within the DataFrame's
  /// underlying storage.
  ///
  /// Parameters:
  /// - `selector`: A single row label (e.g., a `String`, `int`, or any other type used in the DataFrame's index)
  ///   or a `List` of such labels.
  ///
  /// Returns:
  /// - A `List<int>` containing the integer indices corresponding to the provided `selector`.
  ///   If `selector` is a single label, the list will contain one index.
  ///
  /// Throws:
  /// - `ArgumentError` if any of the provided labels are not found in the DataFrame's index.
  List<int> _getIntRowIndices(dynamic selector) {
    if (selector is List) {
      return selector.map((label) {
        final idx = _df.index.indexOf(label);
        if (idx == -1) throw ArgumentError('Row label not found: $label');
        return idx;
      }).toList();
    } else {
      final idx = _df.index.indexOf(selector);
      if (idx == -1) throw ArgumentError('Row label not found: $selector');
      return [idx];
    }
  }

  /// Converts a single column label or a list of column labels into their corresponding integer indices.
  ///
  /// This helper method is used internally by `loc` to translate human-readable column labels
  /// into the integer-based indices required for accessing data within the DataFrame's
  /// underlying storage.
  ///
  /// Parameters:
  /// - `selector`: A single column label (e.g., a `String` or any other type used in the DataFrame's columns)
  ///   or a `List` of such labels.
  ///
  /// Returns:
  /// - A `List<int>` containing the integer indices corresponding to the provided `selector`.
  ///   If `selector` is a single label, the list will contain one index.
  ///
  /// Throws:
  /// - `ArgumentError` if any of the provided labels are not found in the DataFrame's columns.
  List<int> _getIntColIndices(dynamic selector) {
    if (selector is List) {
      return selector.map((label) {
        final idx = _df._columns.indexOf(label);
        if (idx == -1) throw ArgumentError('Column label not found: $label');
        return idx;
      }).toList();
    } else {
      final idx = _df._columns.indexOf(selector);
      if (idx == -1) throw ArgumentError('Column label not found: $selector');
      return [idx];
    }
  }
}
