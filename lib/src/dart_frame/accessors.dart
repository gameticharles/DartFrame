// ignore_for_file: unnecessary_type_check

part of '../../dartframe.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first

class DataFrameILocAccessor {
  final DataFrame _df;

  DataFrameILocAccessor(this._df);

  // Support for df.iloc[rowIndex] syntax
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

  // Support for df.iloc(rowIndex, colIndex) syntax
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

  // Support for df.loc[rowLabel] syntax
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

  // Support for df.loc(rowLabel, colLabel) syntax
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

  // Helper to convert single label or list of labels to integer indices
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
