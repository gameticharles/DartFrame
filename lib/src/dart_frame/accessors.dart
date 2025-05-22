part of '../../dartframe.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first

class DataFrameILocAccessor {
  final DataFrame _df;

  DataFrameILocAccessor(this._df);

  // Modified operator [] to handle both single value and list with row,col
  dynamic operator [](dynamic selector) {
    if (selector is List) {
      // Handle case where selector is a list [row, column]
      if (selector.length == 2) {
        return call(selector[0], selector[1]);
      }
      // If it's just a list of row indices, pass it through
      return call(selector);
    }
    return call(selector);
  }

  // Keep existing call method for df.iloc(...) syntax
  dynamic call(dynamic rowSelector, [dynamic colSelector]) {
    if (rowSelector is int) {
      // Single row selection
      if (rowSelector < 0 || rowSelector >= _df.rowCount) {
        throw RangeError.index(rowSelector, _df.rows, 'Row index out of bounds');
      }

      if (colSelector == null) {
        // df.iloc[rowIndex] -> Series representing the row
        List<dynamic> rowData = _df.rows[rowSelector];
        return Series(
          List.from(rowData), // Copy data
          name: _df.index.isNotEmpty && rowSelector < _df.index.length 
                ? _df.index[rowSelector] 
                : rowSelector.toString(),
          index: List.from(_df.columns), // Copy column names for series index
        );
      } else if (colSelector is int) {
        // df.iloc[rowIndex, colIndex] -> Single value
        if (colSelector < 0 || colSelector >= _df.columnCount) {
          throw RangeError.index(colSelector, _df.columns, 'Column index out of bounds');
        }
        return _df.rows[rowSelector][colSelector];
      } else if (colSelector is List<int>) {
        // df.iloc[rowIndex, [colIndex1, colIndex2]] -> Series
        List<dynamic> selectedData = [];
        List<dynamic> selectedColumnNames = [];
        for (int colIdx in colSelector) {
          if (colIdx < 0 || colIdx >= _df.columnCount) {
            throw RangeError.index(colIdx, _df.columns, 'Column index out of bounds');
          }
          selectedData.add(_df.rows[rowSelector][colIdx]);
          selectedColumnNames.add(_df.columns[colIdx]);
        }
        return Series(
          selectedData,
          name: _df.index.isNotEmpty && rowSelector < _df.index.length 
                ? _df.index[rowSelector] 
                : rowSelector.toString(),
          index: selectedColumnNames,
        );
      } else {
        throw ArgumentError('Invalid column selector type: ${colSelector.runtimeType}');
      }
    } else if (rowSelector is List<int>) {
      // Multiple row selection
      for (int rIdx in rowSelector) {
        if (rIdx < 0 || rIdx >= _df.rowCount) {
          throw RangeError.index(rIdx, _df.rows, 'Row index out of bounds');
        }
      }

      List<List<dynamic>> selectedRowsData = rowSelector.map((rIdx) => List<dynamic>.from(_df.rows[rIdx])).toList();
      List<dynamic> selectedRowIndex = rowSelector.map((rIdx) => _df.index.isNotEmpty && rIdx < _df.index.length ? _df.index[rIdx] : rIdx).toList();


      if (colSelector == null) {
        // df.iloc[[rowIndex1, rowIndex2]] -> DataFrame with all columns
        return DataFrame(
          List<List<dynamic>>.from(selectedRowsData), // Deep copy
          columns: List.from(_df.columns), // Copy
          index: selectedRowIndex,
        );
      } else if (colSelector is int) {
        // df.iloc[[rowIndex1, rowIndex2], colIndex] -> Series
        if (colSelector < 0 || colSelector >= _df.columnCount) {
          throw RangeError.index(colSelector, _df.columns, 'Column index out of bounds');
        }
        List<dynamic> columnData = rowSelector.map((rIdx) => _df.rows[rIdx][colSelector]).toList();
        return Series(
          columnData,
          name: _df.columns[colSelector].toString(),
          index: selectedRowIndex,
        );
      } else if (colSelector is List<int>) {
        // df.iloc[[rowIndex1, rowIndex2], [colIndex1, colIndex2]] -> DataFrame
        List<dynamic> selectedDfColumns = [];
        for (int cIdx in colSelector) {
          if (cIdx < 0 || cIdx >= _df.columnCount) {
            throw RangeError.index(cIdx, _df.columns, 'Column index out of bounds');
          }
          selectedDfColumns.add(_df.columns[cIdx]);
        }

        List<List<dynamic>> resultData = [];
        for (int rIdx in rowSelector) {
          List<dynamic> newRow = [];
          for (int cIdx in colSelector) {
            newRow.add(_df.rows[rIdx][cIdx]);
          }
          resultData.add(newRow);
        }
        return DataFrame(
          resultData,
          columns: selectedDfColumns,
          index: selectedRowIndex,
        );
      } else {
        throw ArgumentError('Invalid column selector type: ${colSelector.runtimeType}');
      }
    } else {
      throw ArgumentError('Invalid row selector type: ${rowSelector.runtimeType}');
    }
  }
}

class DataFrameLocAccessor {
  final DataFrame _df;

  DataFrameLocAccessor(this._df);

  // Modified operator [] to handle both single value and list with row,col
  dynamic operator [](dynamic selector) {
    if (selector is List) {
      // Handle case where selector is a list [row, column]
      if (selector.length == 2) {
        return call(selector[0], selector[1]);
      }
      // If it's just a list of row labels, pass it through
      return call(selector);
    }
    return call(selector);
  }

  // Keep existing call method for df.loc(...) syntax
  dynamic call(dynamic rowSelector, [dynamic colSelector]) {
    // Helper to convert single label or list of labels to integer indices
    List<int> getIntRowIndices(dynamic selector) {
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

    List<int> getIntColIndices(dynamic selector) {
      if (selector is List) {
        return selector.map((label) {
          final idx = _df.columns.indexOf(label);
          if (idx == -1) throw ArgumentError('Column label not found: $label');
          return idx;
        }).toList();
      } else {
        final idx = _df.columns.indexOf(selector);
        if (idx == -1) throw ArgumentError('Column label not found: $selector');
        return [idx];
      }
    }
    
    bool isSingleRow = rowSelector is! List;

    if (isSingleRow) {
      List<int> intRowIdxList = getIntRowIndices(rowSelector);
      if (intRowIdxList.isEmpty) throw ArgumentError('Row label not found: $rowSelector'); // Should be caught by getIntRowIndices
      int intRowIdx = intRowIdxList.first;

      if (colSelector == null) {
        // df.loc[rowLabel] -> Series
        List<dynamic> rowData = _df.rows[intRowIdx];
        return Series(
          List.from(rowData),
          name: rowSelector.toString(),
          index: List.from(_df.columns),
        );
      } else if (colSelector is List<String> || colSelector is List<dynamic>) { // Assuming List<dynamic> contains labels
        // df.loc[rowLabel, [colLabel1, colLabel2]] -> Series
        List<int> intColIdxs = getIntColIndices(colSelector as List);
        List<dynamic> selectedData = intColIdxs.map((cIdx) => _df.rows[intRowIdx][cIdx]).toList();
        List<dynamic> selectedColumnNames = intColIdxs.map((cIdx) => _df.columns[cIdx]).toList();
        return Series(
          selectedData,
          name: rowSelector.toString(),
          index: selectedColumnNames,
        );
      } else { // Single column label
        // df.loc[rowLabel, colLabel] -> Single value
        List<int> intColIdxList = getIntColIndices(colSelector);
         if (intColIdxList.isEmpty) throw ArgumentError('Column label not found: $colSelector');
        int intColIdx = intColIdxList.first;
        return _df.rows[intRowIdx][intColIdx];
      }
    } else if (rowSelector is List) { // Multiple row labels
      List<int> intRowIdxs = getIntRowIndices(rowSelector);
      List<dynamic> selectedRowIndexLabels = intRowIdxs.map((idx) => _df.index[idx]).toList();

      if (colSelector == null) {
        // df.loc[[rowLabel1, rowLabel2]] -> DataFrame
        List<List<dynamic>> selectedData = intRowIdxs.map((rIdx) => List<dynamic>.from(_df.rows[rIdx])).toList();
        return DataFrame(
          selectedData,
          columns: List.from(_df.columns),
          index: selectedRowIndexLabels,
        );
      } else if (colSelector is List<String> || colSelector is List<dynamic>) {
        // df.loc[[rowLabel1, rowLabel2], [colLabel1, colLabel2]] -> DataFrame
        List<int> intColIdxs = getIntColIndices(colSelector as List);
        List<dynamic> selectedDfColumns = intColIdxs.map((cIdx) => _df.columns[cIdx]).toList();
        
        List<List<dynamic>> resultData = [];
        for (int rIdx in intRowIdxs) {
          List<dynamic> newRow = [];
          for (int cIdx in intColIdxs) {
            newRow.add(_df.rows[rIdx][cIdx]);
          }
          resultData.add(newRow);
        }
        return DataFrame(
          resultData,
          columns: selectedDfColumns,
          index: selectedRowIndexLabels,
        );
      } else { // Single column label
        // df.loc[[rowLabel1, rowLabel2], colLabel] -> Series
        List<int> intColIdxList = getIntColIndices(colSelector);
        if (intColIdxList.isEmpty) throw ArgumentError('Column label not found: $colSelector');
        int intColIdx = intColIdxList.first;
        
        List<dynamic> columnData = intRowIdxs.map((rIdx) => _df.rows[rIdx][intColIdx]).toList();
        return Series(
          columnData,
          name: colSelector.toString(),
          index: selectedRowIndexLabels,
        );
      }
    } else {
      throw ArgumentError('Invalid row selector type: ${rowSelector.runtimeType}');
    }
  }
}
