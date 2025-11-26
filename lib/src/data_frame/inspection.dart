part of 'data_frame.dart';

/// Extension for DataFrame inspection methods
extension DataFrameInspection on DataFrame {
  /// Print a concise summary of the DataFrame.
  ///
  /// This method prints information about the DataFrame including:
  /// - The DataFrame type
  /// - The index range
  /// - Column names and their data types
  /// - Non-null counts for each column
  /// - Memory usage
  ///
  /// Parameters:
  ///   - `verbose`: Whether to print the full summary (default: true)
  ///   - `maxCols`: Maximum number of columns to display (default: null, shows all)
  ///   - `memoryUsage`: Whether to display memory usage (default: true)
  ///   - `nullCounts`: Whether to display null counts (default: true)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, null, 4],
  ///   'B': ['a', 'b', 'c', 'd'],
  ///   'C': [1.1, 2.2, 3.3, 4.4],
  /// });
  /// df.info();
  /// // Output:
  /// // <class 'DataFrame'>
  /// // RangeIndex: 4 entries, 0 to 3
  /// // Data columns (total 3 columns):
  /// //  #   Column  Non-Null Count  Dtype
  /// // ---  ------  --------------  -----
  /// //  0   A       3 non-null      int
  /// //  1   B       4 non-null      String
  /// //  2   C       4 non-null      double
  /// // dtypes: int(1), String(1), double(1)
  /// // memory usage: 128 bytes
  /// ```
  void info({
    bool verbose = true,
    int? maxCols,
    bool memoryUsage = true,
    bool nullCounts = true,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('<class \'DataFrame\'>');

    // Index information
    if (index.isEmpty || _isDefaultIntegerIndex(index, rowCount)) {
      buffer.writeln('RangeIndex: $rowCount entries, 0 to ${rowCount - 1}');
    } else {
      buffer
          .writeln('Index: $rowCount entries, ${index.first} to ${index.last}');
    }

    // Column information
    final colsToShow = maxCols ?? columnCount;
    final actualColsToShow = min(colsToShow, columnCount);

    buffer.writeln('Data columns (total $columnCount columns):');

    if (verbose && nullCounts) {
      buffer.writeln(' #   Column  Non-Null Count  Dtype');
      buffer.writeln('---  ------  --------------  -----');

      for (int i = 0; i < actualColsToShow; i++) {
        final colName = _columns[i].toString();
        final series = column(colName);
        final nonNullCount = series.count();
        final dtype = _inferColumnDtype(colName);

        buffer.writeln(
            ' ${i.toString().padLeft(2)}   ${colName.padRight(6)}  $nonNullCount non-null${' ' * (6 - nonNullCount.toString().length)}  $dtype');
      }

      if (actualColsToShow < columnCount) {
        buffer.writeln('... ${columnCount - actualColsToShow} more columns');
      }
    }

    // Dtype summary
    final dtypeCounts = <String, int>{};
    for (final col in _columns) {
      final dtype = _inferColumnDtype(col);
      dtypeCounts[dtype] = (dtypeCounts[dtype] ?? 0) + 1;
    }

    final dtypeStr =
        dtypeCounts.entries.map((e) => '${e.key}(${e.value})').join(', ');
    buffer.writeln('dtypes: $dtypeStr');

    // Memory usage
    if (memoryUsage) {
      final memBytes = this.memoryUsageDetailed(deep: false).sum();
      buffer.writeln('memory usage: ${_formatBytes(memBytes)}');
    }

    print(buffer.toString());
  }

  /// Generate descriptive statistics for numeric columns (pandas-style).
  ///
  /// Descriptive statistics include those that summarize the central tendency,
  /// dispersion and shape of a dataset's distribution, excluding NaN values.
  ///
  /// This method returns a DataFrame (pandas-style), unlike the existing describe()
  /// which returns a Map.
  ///
  /// Parameters:
  ///   - `percentiles`: List of percentiles to include (default: [0.25, 0.5, 0.75])
  ///   - `include`: List of data types to include (default: null, includes numeric)
  ///   - `exclude`: List of data types to exclude (default: null)
  ///
  /// Returns:
  ///   A DataFrame with descriptive statistics
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50],
  ///   'C': ['a', 'b', 'c', 'd', 'e'],
  /// });
  /// var stats = df.describeDataFrame();
  /// print(stats);
  /// // Output:
  /// //        A     B
  /// // count  5.0   5.0
  /// // mean   3.0  30.0
  /// // std    1.58 15.81
  /// // min    1.0  10.0
  /// // 25%    2.0  20.0
  /// // 50%    3.0  30.0
  /// // 75%    4.0  40.0
  /// // max    5.0  50.0
  /// ```
  DataFrame describeDataFrame({
    List<double>? percentiles,
    List<String>? include,
    List<String>? exclude,
  }) {
    percentiles ??= [0.25, 0.5, 0.75];

    // Get numeric columns
    final numericCols = selectDtypes(
        include: include ?? ['num', 'int', 'double'], exclude: exclude);

    if (numericCols.columnCount == 0) {
      return DataFrame.empty(columns: ['count', 'mean', 'std', 'min', 'max']);
    }

    final stats = <String, List<dynamic>>{};
    final statNames = ['count', 'mean', 'std', 'min'];

    // Add percentile names
    for (final p in percentiles) {
      statNames.add('${(p * 100).toStringAsFixed(0)}%');
    }
    statNames.add('max');

    for (final colName in numericCols._columns) {
      final series = numericCols.column(colName);
      final colStats = <dynamic>[];

      colStats.add(series.count().toDouble());
      colStats.add(series.mean());
      colStats.add(series.std());
      colStats.add(series.min());

      for (final p in percentiles) {
        colStats.add(series.quantile(p));
      }

      colStats.add(series.max());

      stats[colName.toString()] = colStats;
    }

    return DataFrame.fromMap(stats, index: statNames);
  }

  /// Return the memory usage of each column in bytes.
  ///
  /// Parameters:
  ///   - `index`: Whether to include memory usage of the index (default: true)
  ///   - `deep`: Whether to introspect the data deeply (default: false)
  ///
  /// Returns:
  ///   A Series with memory usage in bytes for each column
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4],
  ///   'B': ['a', 'b', 'c', 'd'],
  /// });
  /// var mem = df.memoryUsageDetailed();
  /// print(mem);
  /// // Output:
  /// // Index    32
  /// // A        32
  /// // B        64
  /// // dtype: int
  /// ```
  Series memoryUsageDetailed({bool index = true, bool deep = false}) {
    final memData = <dynamic>[];
    final memIndex = <dynamic>[];

    // Index memory
    if (index) {
      memIndex.add('Index');
      memData.add(_estimateMemory(this.index, deep: deep));
    }

    // Column memory
    for (final colName in _columns) {
      memIndex.add(colName);
      final series = column(colName);
      memData.add(_estimateMemory(series.data, deep: deep));
    }

    return Series(memData, name: 'memory_usage', index: memIndex);
  }

  /// Select columns based on their data type.
  ///
  /// Parameters:
  ///   - `include`: List of data types to include (e.g., ['num', 'String'])
  ///   - `exclude`: List of data types to exclude
  ///
  /// Returns:
  ///   A new DataFrame with only the selected columns
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': ['a', 'b', 'c'],
  ///   'C': [1.1, 2.2, 3.3],
  /// });
  /// var numericDf = df.selectDtypes(include: ['num']);
  /// print(numericDf.columns); // ['A', 'C']
  /// ```
  DataFrame selectDtypes({List<String>? include, List<String>? exclude}) {
    if (include == null && exclude == null) {
      throw ArgumentError('Must specify at least one of include or exclude');
    }

    final selectedCols = <String>[];

    for (final colName in _columns) {
      final dtype = _inferColumnDtype(colName);

      bool shouldInclude = true;

      if (include != null) {
        shouldInclude = include.any((type) => _matchesDtype(dtype, type));
      }

      if (exclude != null && shouldInclude) {
        shouldInclude = !exclude.any((type) => _matchesDtype(dtype, type));
      }

      if (shouldInclude) {
        selectedCols.add(colName.toString());
      }
    }

    if (selectedCols.isEmpty) {
      return DataFrame.empty(index: index);
    }

    final newData = <String, List<dynamic>>{};
    for (final col in selectedCols) {
      newData[col] = column(col).data;
    }

    return DataFrame.fromMap(newData, index: index);
  }

  /// Infer the data type of a column
  String _inferColumnDtype(dynamic colName) {
    final series = column(colName);
    final dtype = series.dtype;

    if (dtype == int) return 'int';
    if (dtype == double) return 'double';
    if (dtype == num) return 'num';
    if (dtype == String) return 'String';
    if (dtype == bool) return 'bool';
    if (dtype == DateTime) return 'DateTime';

    return 'object';
  }

  /// Check if a dtype matches a type specification
  bool _matchesDtype(String dtype, String typeSpec) {
    if (dtype == typeSpec) return true;

    // Handle numeric types
    if (typeSpec == 'num' &&
        (dtype == 'int' || dtype == 'double' || dtype == 'num')) {
      return true;
    }

    if (typeSpec == 'number' &&
        (dtype == 'int' || dtype == 'double' || dtype == 'num')) {
      return true;
    }

    return false;
  }

  /// Estimate memory usage of a list
  int _estimateMemory(List<dynamic> data, {bool deep = false}) {
    if (data.isEmpty) return 0;

    int totalBytes = 0;

    for (final item in data) {
      if (item == null) {
        totalBytes += 8; // Pointer size
      } else if (item is int) {
        totalBytes += 8;
      } else if (item is double) {
        totalBytes += 8;
      } else if (item is bool) {
        totalBytes += 1;
      } else if (item is String) {
        totalBytes += deep ? item.length * 2 : 8; // UTF-16 or pointer
      } else if (item is DateTime) {
        totalBytes += 8;
      } else {
        totalBytes += 8; // Default pointer size
      }
    }

    return totalBytes;
  }

  /// Format bytes to human-readable string
  String _formatBytes(num bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Return the data types of the columns as a Series.
  ///
  /// Returns:
  ///   Series with column names as index and dtypes as values
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [1.1, 2.2, 3.3],
  ///   'C': ['a', 'b', 'c'],
  /// });
  /// var types = df.dtypesSeries;
  /// // A: int, B: double, C: String
  /// ```
  Series get dtypesSeries {
    final types = <String>[];
    for (final col in _columns) {
      types.add(_inferColumnDtype(col));
    }
    return Series(types, name: 'dtype', index: _columns);
  }

  /// Attempt to infer better dtypes for object columns.
  ///
  /// This method will attempt to convert object dtype columns to more specific types.
  ///
  /// Returns:
  ///   DataFrame with inferred types
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': ['1', '2', '3'],
  ///   'B': ['1.1', '2.2', '3.3'],
  /// });
  /// var inferred = df.inferObjects();
  /// // A will be converted to int, B to double
  /// ```
  DataFrame inferObjects() {
    final newData = <String, List<dynamic>>{};

    for (final col in _columns) {
      final series = column(col);
      final colName = col.toString();

      // Try to infer better type
      if (_inferColumnDtype(col) == 'String' ||
          _inferColumnDtype(col) == 'object') {
        // Try numeric conversion
        try {
          final numericSeries = series.toNumeric(errors: 'coerce');
          // Check if conversion was successful (not all null)
          final nonNullCount = numericSeries.data
              .where((e) => e != null && e != replaceMissingValueWith)
              .length;
          if (nonNullCount > 0) {
            newData[colName] = numericSeries.data;
            continue;
          }
        } catch (e) {
          // Numeric conversion failed, try datetime
        }

        // Try datetime conversion
        try {
          final datetimeSeries =
              series.toDatetime(errors: 'coerce', inferDatetimeFormat: true);
          final nonNullCount = datetimeSeries.data
              .where((e) => e != null && e != replaceMissingValueWith)
              .length;
          if (nonNullCount > 0) {
            newData[colName] = datetimeSeries.data;
            continue;
          }
        } catch (e) {
          // Datetime conversion failed
        }
      }

      // Keep original if no conversion worked
      newData[colName] = series.data;
    }

    return DataFrame.fromMap(newData, index: index);
  }

  /// Convert columns to the best possible dtypes.
  ///
  /// This method will convert columns to more specific nullable dtypes where possible.
  ///
  /// Parameters:
  ///   - `inferObjects`: Whether to infer object dtypes (default: true)
  ///   - `convertString`: Whether to convert to string dtype (default: true)
  ///   - `convertInteger`: Whether to convert to nullable integer (default: true)
  ///   - `convertBoolean`: Whether to convert to nullable boolean (default: true)
  ///
  /// Returns:
  ///   DataFrame with converted types
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': ['1', '2', '3'],
  ///   'B': [1.0, 2.0, 3.0],
  ///   'C': ['true', 'false', 'true'],
  /// });
  /// var converted = df.convertDtypes();
  /// ```
  DataFrame convertDtypes({
    bool inferObjects = true,
    bool convertString = true,
    bool convertInteger = true,
    bool convertBoolean = true,
  }) {
    var result = this;

    if (inferObjects) {
      result = result.inferObjects();
    }

    final newData = <String, List<dynamic>>{};

    for (final col in result._columns) {
      final series = result.column(col);
      final colName = col.toString();
      final dtype = result._inferColumnDtype(col);

      // Convert floats to integers if they have no fractional part
      if (convertInteger && dtype == 'double') {
        bool allIntegers = true;
        for (final value in series.data) {
          if (value != null && value != replaceMissingValueWith) {
            if (value is num && value.toDouble() != value.toInt().toDouble()) {
              allIntegers = false;
              break;
            }
          }
        }

        if (allIntegers) {
          newData[colName] = series.data.map((e) {
            if (e == null || e == replaceMissingValueWith) return e;
            if (e is num) return e.toInt();
            return e;
          }).toList();
          continue;
        }
      }

      // Convert string booleans to boolean
      if (convertBoolean && dtype == 'String') {
        bool allBooleans = true;
        for (final value in series.data) {
          if (value != null && value != replaceMissingValueWith) {
            if (value is String) {
              final lower = value.toLowerCase();
              if (lower != 'true' &&
                  lower != 'false' &&
                  lower != '1' &&
                  lower != '0') {
                allBooleans = false;
                break;
              }
            } else {
              allBooleans = false;
              break;
            }
          }
        }

        if (allBooleans) {
          newData[colName] = series.data.map((e) {
            if (e == null || e == replaceMissingValueWith) return e;
            if (e is String) {
              final lower = e.toLowerCase();
              return lower == 'true' || lower == '1';
            }
            return e;
          }).toList();
          continue;
        }
      }

      // Keep original
      newData[colName] = series.data;
    }

    return DataFrame.fromMap(newData, index: result.index);
  }
}
