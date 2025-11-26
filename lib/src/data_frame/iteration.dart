part of 'data_frame.dart';

/// Extension for DataFrame iteration methods
extension DataFrameIteration on DataFrame {
  /// Iterate over DataFrame rows as (index, Series) pairs.
  ///
  /// Yields:
  ///   Iterable of MapEntry where key is the index and value is a Series
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  /// });
  ///
  /// for (var row in df.iterrows()) {
  ///   print('Index: ${row.key}');
  ///   print('Data: ${row.value}');
  /// }
  /// ```
  Iterable<MapEntry<dynamic, Series>> iterrows() sync* {
    for (int i = 0; i < rowCount; i++) {
      final rowData = <dynamic>[];
      for (int j = 0; j < columnCount; j++) {
        rowData.add(_data[i][j]);
      }

      final series = Series(
        rowData,
        name: index[i].toString(),
        index: List.from(_columns),
      );

      yield MapEntry(index[i], series);
    }
  }

  /// Iterate over DataFrame rows as named tuples.
  ///
  /// Returns an iterable of DataFrameRow objects with named fields.
  ///
  /// Parameters:
  ///   - `indexName`: Name for the index field (default: 'Index')
  ///   - `name`: Name for the tuple (default: 'Row')
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  /// });
  ///
  /// for (var row in df.itertuples()) {
  ///   print('Index: ${row.index}');
  ///   print('A: ${row['A']}');
  ///   print('B: ${row['B']}');
  /// }
  /// ```
  Iterable<DataFrameRow> itertuples({
    String indexName = 'Index',
    String name = 'Row',
  }) sync* {
    for (int i = 0; i < rowCount; i++) {
      final rowData = <String, dynamic>{};
      rowData[indexName] = index[i];

      for (int j = 0; j < columnCount; j++) {
        rowData[_columns[j].toString()] = _data[i][j];
      }

      yield DataFrameRow(rowData, name: name);
    }
  }

  /// Iterate over (column name, Series) pairs.
  ///
  /// Yields:
  ///   Iterable of MapEntry where key is column name and value is a Series
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, 5, 6],
  /// });
  ///
  /// for (var item in df.items()) {
  ///   print('Column: ${item.key}');
  ///   print('Data: ${item.value}');
  /// }
  /// ```
  Iterable<MapEntry<String, Series>> items() sync* {
    for (final col in _columns) {
      yield MapEntry(col.toString(), column(col));
    }
  }

  /// Get the column names (alias for columns).
  ///
  /// Returns:
  ///   List of column names
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2], 'B': [3, 4]});
  /// print(df.keys()); // ['A', 'B']
  /// ```
  List<dynamic> keys() {
    return List.from(_columns);
  }

  /// Return a list representation of the DataFrame.
  ///
  /// Returns:
  ///   List of lists representing the data
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2], 'B': [3, 4]});
  /// var values = df.values;
  /// // [[1, 3], [2, 4]]
  /// ```
  List<List<dynamic>> get values {
    return _data.map((row) => List<dynamic>.from(row)).toList();
  }
}

/// Represents a row from a DataFrame with named field access.
class DataFrameRow {
  final Map<String, dynamic> _data;
  final String name;

  DataFrameRow(this._data, {this.name = 'Row'});

  /// Access field by name
  dynamic operator [](String key) {
    if (!_data.containsKey(key)) {
      throw ArgumentError('Field $key does not exist');
    }
    return _data[key];
  }

  /// Get the index value
  dynamic get index => _data['Index'];

  /// Get all field names
  List<String> get fields => _data.keys.toList();

  /// Convert to Map
  Map<String, dynamic> toMap() => Map.from(_data);

  /// Convert to List (excluding index)
  List<dynamic> toList() {
    return _data.entries
        .where((e) => e.key != 'Index')
        .map((e) => e.value)
        .toList();
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('$name(');

    final entries = _data.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      buffer.write('${entries[i].key}=${entries[i].value}');
      if (i < entries.length - 1) {
        buffer.write(', ');
      }
    }

    buffer.write(')');
    return buffer.toString();
  }
}
