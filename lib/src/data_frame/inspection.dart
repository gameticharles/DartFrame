part of 'data_frame.dart';

/// Extension providing inspection and information methods for DataFrame.
extension DataFrameInspection on DataFrame {
  /// Prints a concise summary of the DataFrame.
  ///
  /// This method prints information about a DataFrame including
  /// the index dtype and columns, non-null values and memory usage.
  ///
  /// Parameters:
  /// - `verbose`: Whether to print the full summary. If null, it will be
  ///   determined based on the DataFrame size.
  /// - `showCounts`: Whether to show the non-null counts.
  ///
  /// Example:
  /// ```dart
  /// df.info();
  /// ```
  void info({bool? verbose, bool showCounts = true}) {
    print('<DataFrame>');
    print('RangeIndex: $rowCount entries, 0 to ${rowCount - 1}');
    print('Data columns (total $columnCount columns):');

    // Calculate column widths for formatting
    int maxColNameLength = 10; // Minimum width
    for (var col in columns) {
      maxColNameLength = max(maxColNameLength, col.toString().length);
    }

    // Header
    String header =
        ' #   ${'Column'.padRight(maxColNameLength)}  Non-Null Count  Dtype';
    print(header);
    print('-' * header.length);

    for (int i = 0; i < columns.length; i++) {
      String colName = columns[i].toString().padRight(maxColNameLength);
      String dtype = _inferDtype(i);

      String countStr = '';
      if (showCounts) {
        int count = 0;
        for (var row in _data) {
          if (!_isMissingValue(row[i])) {
            count++;
          }
        }
        countStr = '$count non-null'.padRight(14);
      }

      print(' $i   $colName  $countStr  $dtype');
    }

    print('dtypes: ${_getDtypeCounts()}');
    print('memory usage: ${_formatBytes(memoryUsage())}');
  }

  /// Returns the memory usage of each column in bytes.
  ///
  /// The memory usage is calculated based on the estimated size of objects
  /// in memory. This is an approximation.
  ///
  /// Returns:
  /// A Series containing the memory usage of each column.
  Series memoryUsage({bool deep = false}) {
    List<int> usage = [];

    // Index memory (approximate)
    int indexUsage =
        index.length * 8; // Assume 8 bytes per index item (e.g. int64)

    for (int i = 0; i < columns.length; i++) {
      int colUsage = 0;
      for (var row in _data) {
        dynamic val = row[i];
        colUsage += _estimateSize(val);
      }
      usage.add(colUsage);
    }

    // Add index usage to the result
    List<dynamic> resultIndex = List.from(columns);

    // Add Index memory usage as a separate entry
    usage.add(indexUsage);
    resultIndex.add('Index');

    return Series(usage, index: resultIndex, name: 'memory_usage');
  }

  /// Internal helper to estimate size of an object in bytes.
  int _estimateSize(dynamic value) {
    if (value == null) return 0;
    if (value is int) return 8;
    if (value is double) return 8;
    if (value is bool) return 1;
    if (value is String) return value.length * 2; // UTF-16 approximation
    return 16; // Generic object overhead approximation
  }

  /// Internal helper to infer dtype of a column.
  String _inferDtype(int colIndex) {
    // Check first non-null value
    for (var row in _data) {
      var val = row[colIndex];
      if (!_isMissingValue(val)) {
        if (val is int) return 'int64';
        if (val is double) return 'float64';
        if (val is bool) return 'bool';
        if (val is String) return 'object';
        if (val is DateTime) return 'datetime64';
      }
    }
    return 'object'; // Default/Empty
  }

  /// Internal helper to get counts of dtypes.
  String _getDtypeCounts() {
    Map<String, int> counts = {};
    for (int i = 0; i < columns.length; i++) {
      String dtype = _inferDtype(i);
      counts[dtype] = (counts[dtype] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.key}(${e.value})').join(', ');
  }

  /// Internal helper to format bytes.
  String _formatBytes(dynamic usage) {
    int bytes = 0;
    if (usage is Series) {
      bytes = usage.sum() as int;
    } else if (usage is int) {
      bytes = usage;
    }

    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
