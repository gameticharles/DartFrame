part of '../../dartframe.dart';

extension DataFrameOperations on DataFrame {
  // Operator [] overridden to access column by index or name
  // Modified operator[] to return a Series
  /// Returns a [Series] for the specified column,
  /// accessed by index or name.
  ///
  /// If [key] is an integer, returns the Series for the column at that index.
  /// If [key] is a String, returns the Series for the column with that name.
  ///
  /// Throws an [IndexError] if the index is out of range.
  /// Throws an [ArgumentError] if the name does not match a column.
  /// Returns a [Series] for the specified column,
  /// accessed by index or name.
  ///
  /// If [key] is an integer, returns the Series for the column at that index.
  /// If [key] is a String, returns the Series for the column with that name.
  ///
  /// Throws an [IndexError] if the index is out of range.
  /// Throws an [ArgumentError] if the name does not match a column.
  Series operator [](dynamic key) {
    if (key is int) {
      if (key < 0 || key >= _columns.length) {
        throw IndexError.withLength(
          key,
          _columns.length,
          indexable: _columns,
          name: 'Index out of range',
          message: null,
        );
      }
      var series =
          Series(rows.map((row) => row[key]).toList(), name: _columns[key]);
      series._setParent(this, _columns[key].toString());
      return series;
    } else if (key is String) {
      int columnIndex = _columns.indexOf(key);
      if (columnIndex == -1) {
        throw ArgumentError.value(key, 'columnName', 'Column does not exist');
      }
      var series =
          Series(rows.map((row) => row[columnIndex]).toList(), name: key);
      series._setParent(this, key);
      return series;
    } else {
      throw ArgumentError('Key must be an int or String');
    }
  }

  // ... existing code ...

  /// Updates a single cell in the DataFrame
  void updateCell(String columnName, int rowIndex, dynamic value) {
    int columnIndex = _columns.indexOf(columnName);
    if (columnIndex == -1) {
      throw ArgumentError('Column $columnName does not exist');
    }

    if (rowIndex < 0 || rowIndex >= _data.length) {
      throw RangeError('Row index out of range');
    }

    _data[rowIndex][columnIndex] = value;
  }

  /// Overrides the index assignment operator `[]` to allow updating a row or column in the DataFrame.
  ///
  /// If the key is an integer, it updates the row at the specified index. The length of the data must match the number of columns.
  ///
  /// If the key is a string, it updates the column with the specified name. If the column already exists, it updates the existing column. If the column does not exist, it adds a new column. The length of the data must match the number of rows.
  ///
  /// Throws a `RangeError` if the index is out of range.
  /// Throws an `ArgumentError` if the length of the data does not match the number of columns or rows.
  /// Throws an `ArgumentError` if the key is not an integer or string.
  void operator []=(dynamic key, dynamic newData) {
    // Convert Series to List if needed
    List<dynamic> data = newData is Series ? newData.data : newData;

    // Check if the key is an index (row update)
    if (key is int) {
      // Check if the row index is valid
      if (key < 0 || key >= _data.length) {
        throw RangeError('Row index out of range');
      }

      // Check if the length of the data matches the number of columns
      if (data.length != _columns.length) {
        throw ArgumentError(
            'Length of data must match the number of columns (${_columns.length})');
      }

      // Update the row at the specified index
      _data[key] = List<dynamic>.from(data);
    }
    // Check if the key is a column label (column update)
    else if (key is String) {
      int columnIndex = _columns.indexOf(key);

      // If the column exists, update it
      if (columnIndex != -1) {
        // Check if the length of the data matches the number of rows
        if (data.length != _data.length) {
          throw ArgumentError(
              'Length of data must match the number of rows (${_data.length})');
        }

        // Update existing column
        for (int i = 0; i < _data.length; i++) {
          _data[i][columnIndex] = data[i];
        }
      }
      // If the column doesn't exist, add a new one
      else {
        // Handle empty DataFrame case
        if (_data.isEmpty) {
          // Initialize with empty rows for the first column
          _data = List.generate(data.length, (_) => []);
          _columns.add(key);

          // Add the new column data
          for (int i = 0; i < data.length; i++) {
            _data[i].add(data[i]);
          }
        } else {
          // Check if the length of the data matches the number of rows
          if (data.length != _data.length) {
            throw ArgumentError(
                'Length of data must match the number of rows (${_data.length})');
          }

          // Add the new column
          addColumn(key, defaultValue: data);
        }
      }
    }
    // Handle unsupported key types
    else if (key is List || key is Series) {
      throw ArgumentError('List and Series keys are not yet supported');
    } else {
      throw ArgumentError(
          'Key must be an integer (for row) or string (for column)');
    }
  }
}
