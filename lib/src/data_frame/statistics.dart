part of 'data_frame.dart';

/// Extension providing advanced statistical operations for DataFrame.
///
/// This extension adds comprehensive statistical methods including descriptive
/// statistics, correlation analysis, and rolling window operations to the
/// DataFrame class, enhancing its analytical capabilities.
extension DataFrameStatistics on DataFrame {
  /// Generates descriptive statistics.
  ///
  /// Descriptive statistics include those that summarize the central tendency,
  /// dispersion and shape of a dataset's distribution, excluding NaN values.
  ///
  /// Analyzes numeric columns only by default.
  ///
  /// Parameters:
  /// - `percentiles`: The percentiles to include in the output. All should fall between 0 and 1.
  ///   The default is [.25, .5, .75], which returns the 25th, 50th, and 75th percentiles.
  ///
  /// Returns:
  /// A DataFrame containing the summary statistics.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9]
  /// ], columns: ['A', 'B', 'C']);
  /// print(df.describe());
  /// ```
  DataFrame describe({List<double>? percentiles}) {
    List<String> numericColumns = [];
    Map<String, Map<String, dynamic>> columnStats = {};

    // Identify numeric columns and collect stats
    for (var colName in columns) {
      Series series = this[colName];

      // Check if column has any numeric values
      bool hasNumeric = series.data.any((e) => e != null && e is num);

      if (hasNumeric) {
        numericColumns.add(colName.toString());
        columnStats[colName.toString()] = series.describe();
      }
    }

    if (numericColumns.isEmpty) {
      // Return empty DataFrame if no numeric columns
      return DataFrame.fromRows([]);
    }

    // Prepare the result DataFrame
    // The index will be the keys from the stats map (count, mean, std, min, 25%, 50%, 75%, max)
    // We assume all numeric series return the same keys from describe()
    List<String> statKeys = [
      'count',
      'mean',
      'std',
      'min',
      '25%',
      '50%',
      '75%',
      'max'
    ];

    // If custom percentiles were supported in Series.describe, we would handle them here.
    // For now, Series.describe is fixed.

    List<List<dynamic>> data = [];
    for (var key in statKeys) {
      List<dynamic> row = [];
      for (var colName in numericColumns) {
        row.add(columnStats[colName]?[key]);
      }
      data.add(row);
    }

    return DataFrame(
      data,
      index: statKeys,
      columns: numericColumns,
    );
  }

  /// Calculates the median value for each numeric column.
  ///
  /// The median is the middle value in a sorted list of numbers. For columns
  /// with an even number of values, it returns the average of the two middle values.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// A Series containing the median values for each numeric column.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9]
  /// ], columns: ['A', 'B', 'C']);
  /// print(df.median()); // Series with median values for each column
  /// ```
  Series median({bool skipna = true}) {
    List<dynamic> medianValues = [];
    List<dynamic> resultIndex = [];

    for (int colIndex = 0; colIndex < _columns.length; colIndex++) {
      String columnName = _columns[colIndex].toString();
      resultIndex.add(columnName);

      List<dynamic> columnData = [];
      for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
        dynamic value = _data[rowIndex][colIndex];
        if (skipna && _isMissingValue(value)) {
          continue;
        }
        columnData.add(value);
      }

      if (columnData.isEmpty) {
        medianValues.add(replaceMissingValueWith);
        continue;
      }

      // Filter numeric values only
      List<num> numericValues =
          columnData.whereType<num>().cast<num>().toList();

      if (numericValues.isEmpty) {
        medianValues.add(replaceMissingValueWith);
        continue;
      }

      numericValues.sort();
      int length = numericValues.length;

      if (length % 2 == 0) {
        // Even number of elements - average of middle two
        double median =
            (numericValues[length ~/ 2 - 1] + numericValues[length ~/ 2]) / 2.0;
        medianValues.add(median);
      } else {
        // Odd number of elements - middle element
        medianValues.add(numericValues[length ~/ 2]);
      }
    }

    return Series(medianValues, name: 'median', index: resultIndex);
  }

  /// Calculates the mode (most frequently occurring value) for each column.
  ///
  /// Parameters:
  /// - `dropna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// A Series containing the mode values for each column. If multiple modes exist,
  /// returns the first one encountered.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 'a', 1],
  ///   [2, 'b', 1],
  ///   [1, 'a', 2]
  /// ], columns: ['A', 'B', 'C']);
  /// print(df.mode()); // Series with mode values for each column
  /// ```
  Series mode({bool dropna = true}) {
    List<dynamic> modeValues = [];
    List<dynamic> resultIndex = [];

    for (int colIndex = 0; colIndex < _columns.length; colIndex++) {
      String columnName = _columns[colIndex].toString();
      resultIndex.add(columnName);

      Map<dynamic, int> valueCounts = {};

      for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
        dynamic value = _data[rowIndex][colIndex];
        if (dropna && _isMissingValue(value)) {
          continue;
        }
        valueCounts[value] = (valueCounts[value] ?? 0) + 1;
      }

      if (valueCounts.isEmpty) {
        modeValues.add(replaceMissingValueWith);
        continue;
      }

      // Find the value with maximum count
      dynamic modeValue = replaceMissingValueWith;
      int maxCount = 0;

      valueCounts.forEach((value, count) {
        if (count > maxCount) {
          maxCount = count;
          modeValue = value;
        }
      });

      modeValues.add(modeValue);
    }

    return Series(modeValues, name: 'mode', index: resultIndex);
  }

  /// Calculates the quantile for each numeric column.
  ///
  /// Parameters:
  /// - `q`: The quantile to compute (between 0 and 1).
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// A Series containing the quantile values for each numeric column.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9]
  /// ], columns: ['A', 'B', 'C']);
  /// print(df.quantileStats(0.5)); // 50th percentile (median) for each column
  /// ```
  Series quantileStats(double q, {bool skipna = true}) {
    if (q < 0 || q > 1) {
      throw ArgumentError('Quantile must be between 0 and 1');
    }

    List<dynamic> quantileValues = [];
    List<dynamic> resultIndex = [];

    for (int colIndex = 0; colIndex < _columns.length; colIndex++) {
      String columnName = _columns[colIndex].toString();
      resultIndex.add(columnName);

      List<dynamic> columnData = [];
      for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
        dynamic value = _data[rowIndex][colIndex];
        if (skipna && _isMissingValue(value)) {
          continue;
        }
        columnData.add(value);
      }

      if (columnData.isEmpty) {
        quantileValues.add(replaceMissingValueWith);
        continue;
      }

      // Filter numeric values only
      List<num> numericValues =
          columnData.whereType<num>().cast<num>().toList();

      if (numericValues.isEmpty) {
        quantileValues.add(replaceMissingValueWith);
        continue;
      }

      numericValues.sort();
      int length = numericValues.length;

      if (length == 1) {
        quantileValues.add(numericValues[0]);
        continue;
      }

      double index = q * (length - 1);
      int lowerIndex = index.floor();
      int upperIndex = index.ceil();

      if (lowerIndex == upperIndex) {
        quantileValues.add(numericValues[lowerIndex]);
      } else {
        double weight = index - lowerIndex;
        double interpolatedValue = numericValues[lowerIndex] * (1 - weight) +
            numericValues[upperIndex] * weight;
        quantileValues.add(interpolatedValue);
      }
    }

    return Series(quantileValues, name: 'quantile_$q', index: resultIndex);
  }

  /// Calculates the standard deviation for each numeric column with advanced options.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  /// - `ddof`: Delta degrees of freedom (default 1 for sample standard deviation).
  ///
  /// Returns:
  /// A Series containing the standard deviation values for each numeric column.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9]
  /// ], columns: ['A', 'B', 'C']);
  /// print(df.std()); // Standard deviation for each column
  /// ```
  Series std({bool skipna = true, int ddof = 1}) {
    List<dynamic> stdValues = [];
    List<dynamic> resultIndex = [];

    for (int colIndex = 0; colIndex < _columns.length; colIndex++) {
      String columnName = _columns[colIndex].toString();
      resultIndex.add(columnName);

      List<dynamic> columnData = [];
      for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
        dynamic value = _data[rowIndex][colIndex];
        if (skipna && _isMissingValue(value)) {
          continue;
        }
        columnData.add(value);
      }

      if (columnData.isEmpty) {
        stdValues.add(replaceMissingValueWith);
        continue;
      }

      // Filter numeric values only
      List<num> numericValues =
          columnData.whereType<num>().cast<num>().toList();

      if (numericValues.isEmpty || numericValues.length <= ddof) {
        stdValues.add(replaceMissingValueWith);
        continue;
      }

      // Calculate mean
      double mean =
          numericValues.reduce((a, b) => a + b) / numericValues.length;

      // Calculate variance
      double sumSquaredDiffs = numericValues
          .map((value) => (value - mean) * (value - mean))
          .reduce((a, b) => a + b);

      double variance = sumSquaredDiffs / (numericValues.length - ddof);
      double standardDeviation = sqrt(variance);

      stdValues.add(standardDeviation);
    }

    return Series(stdValues, name: 'std', index: resultIndex);
  }

  /// Calculates the variance for each numeric column.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  /// - `ddof`: Delta degrees of freedom (default 1 for sample variance).
  ///
  /// Returns:
  /// A Series containing the variance values for each numeric column.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9]
  /// ], columns: ['A', 'B', 'C']);
  /// print(df.var()); // Variance for each column
  /// ```
  Series variance({bool skipna = true, int ddof = 1}) {
    List<dynamic> varValues = [];
    List<dynamic> resultIndex = [];

    for (int colIndex = 0; colIndex < _columns.length; colIndex++) {
      String columnName = _columns[colIndex].toString();
      resultIndex.add(columnName);

      List<dynamic> columnData = [];
      for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
        dynamic value = _data[rowIndex][colIndex];
        if (skipna && _isMissingValue(value)) {
          continue;
        }
        columnData.add(value);
      }

      if (columnData.isEmpty) {
        varValues.add(replaceMissingValueWith);
        continue;
      }

      // Filter numeric values only
      List<num> numericValues =
          columnData.whereType<num>().cast<num>().toList();

      if (numericValues.isEmpty || numericValues.length <= ddof) {
        varValues.add(replaceMissingValueWith);
        continue;
      }

      // Calculate mean
      double mean =
          numericValues.reduce((a, b) => a + b) / numericValues.length;

      // Calculate variance
      double sumSquaredDiffs = numericValues
          .map((value) => (value - mean) * (value - mean))
          .reduce((a, b) => a + b);

      double variance = sumSquaredDiffs / (numericValues.length - ddof);

      varValues.add(variance);
    }

    return Series(varValues, name: 'var', index: resultIndex);
  }

  /// Calculates the correlation matrix for numeric columns with advanced options.
  ///
  /// Correlation measures the linear relationship between variables.
  /// Values range from -1 (perfect negative correlation) to 1 (perfect positive correlation).
  ///
  /// Parameters:
  /// - `method`: The correlation method to use. Supported values:
  ///   - 'pearson': Pearson correlation coefficient (default)
  ///   - 'spearman': Spearman rank correlation coefficient
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// A DataFrame containing the correlation matrix.
  ///
  /// Example 1:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [2, 4, 6],
  ///   [3, 6, 9]
  /// ], columns: ['A', 'B', 'C']);
  /// print(df.corr()); // Correlation matrix
  /// ```
  ///
  /// Example 2:
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
  DataFrame corr({String method = 'pearson', bool skipna = true}) {
    if (method != 'pearson' && method != 'spearman') {
      throw ArgumentError('Method must be either "pearson" or "spearman"');
    }

    // Get numeric columns only
    List<String> numericColumns = [];
    List<int> numericColumnIndices = [];

    for (int colIndex = 0; colIndex < _columns.length; colIndex++) {
      String columnName = _columns[colIndex].toString();

      // Check if column has any numeric values
      bool hasNumericValues = false;
      for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
        dynamic value = _data[rowIndex][colIndex];
        if (!_isMissingValue(value) && value is num) {
          hasNumericValues = true;
          break;
        }
      }

      if (hasNumericValues) {
        numericColumns.add(columnName);
        numericColumnIndices.add(colIndex);
      }
    }

    if (numericColumns.isEmpty) {
      throw ArgumentError(
          'No numeric columns found for correlation calculation');
    }

    // Create correlation matrix
    List<List<dynamic>> correlationMatrix = [];

    for (int i = 0; i < numericColumns.length; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < numericColumns.length; j++) {
        if (i == j) {
          row.add(1.0); // Perfect correlation with itself
        } else {
          double correlation = _calculateCorrelation(
              numericColumnIndices[i], numericColumnIndices[j], method, skipna);
          row.add(correlation);
        }
      }
      correlationMatrix.add(row);
    }

    return DataFrame(
      correlationMatrix,
      columns: numericColumns,
      index: numericColumns,
    );
  }

  /// Calculates the covariance matrix for numeric columns.
  ///
  /// Covariance measures how much two variables change together.
  /// Positive covariance indicates variables tend to move in the same direction.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  /// - `ddof`: Delta degrees of freedom (default 1).
  ///
  /// Returns:
  /// A DataFrame containing the covariance matrix.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [2, 4, 6],
  ///   [3, 6, 9]
  /// ], columns: ['A', 'B', 'C']);
  /// print(df.cov()); // Covariance matrix
  /// ```
  DataFrame cov({bool skipna = true, int ddof = 1}) {
    // Get numeric columns only
    List<String> numericColumns = [];
    List<int> numericColumnIndices = [];

    for (int colIndex = 0; colIndex < _columns.length; colIndex++) {
      String columnName = _columns[colIndex].toString();

      // Check if column has any numeric values
      bool hasNumericValues = false;
      for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
        dynamic value = _data[rowIndex][colIndex];
        if (!_isMissingValue(value) && value is num) {
          hasNumericValues = true;
          break;
        }
      }

      if (hasNumericValues) {
        numericColumns.add(columnName);
        numericColumnIndices.add(colIndex);
      }
    }

    if (numericColumns.isEmpty) {
      throw ArgumentError(
          'No numeric columns found for covariance calculation');
    }

    // Create covariance matrix
    List<List<dynamic>> covarianceMatrix = [];

    for (int i = 0; i < numericColumns.length; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < numericColumns.length; j++) {
        double covariance = _calculateCovariance(
            numericColumnIndices[i], numericColumnIndices[j], skipna, ddof);
        row.add(covariance);
      }
      covarianceMatrix.add(row);
    }

    return DataFrame(
      covarianceMatrix,
      columns: numericColumns,
      index: numericColumns,
    );
  }

  /// Helper method to calculate correlation between two columns.
  double _calculateCorrelation(
      int colIndex1, int colIndex2, String method, bool skipna) {
    List<num> values1 = [];
    List<num> values2 = [];

    // Collect paired valid values
    for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
      dynamic val1 = _data[rowIndex][colIndex1];
      dynamic val2 = _data[rowIndex][colIndex2];

      if (skipna && (_isMissingValue(val1) || _isMissingValue(val2))) {
        continue;
      }

      if (val1 is num && val2 is num) {
        values1.add(val1);
        values2.add(val2);
      }
    }

    if (values1.length < 2) {
      return double.nan;
    }

    if (method == 'pearson') {
      return _pearsonCorrelation(values1, values2);
    } else if (method == 'spearman') {
      return _spearmanCorrelation(values1, values2);
    }

    return double.nan;
  }

  /// Helper method to calculate covariance between two columns.
  double _calculateCovariance(
      int colIndex1, int colIndex2, bool skipna, int ddof) {
    List<num> values1 = [];
    List<num> values2 = [];

    // Collect paired valid values
    for (int rowIndex = 0; rowIndex < _data.length; rowIndex++) {
      dynamic val1 = _data[rowIndex][colIndex1];
      dynamic val2 = _data[rowIndex][colIndex2];

      if (skipna && (_isMissingValue(val1) || _isMissingValue(val2))) {
        continue;
      }

      if (val1 is num && val2 is num) {
        values1.add(val1);
        values2.add(val2);
      }
    }

    if (values1.length <= ddof) {
      return double.nan;
    }

    // Calculate means
    double mean1 = values1.reduce((a, b) => a + b) / values1.length;
    double mean2 = values2.reduce((a, b) => a + b) / values2.length;

    // Calculate covariance
    double sumProducts = 0;
    for (int i = 0; i < values1.length; i++) {
      sumProducts += (values1[i] - mean1) * (values2[i] - mean2);
    }

    return sumProducts / (values1.length - ddof);
  }

  /// Calculates Pearson correlation coefficient.
  double _pearsonCorrelation(List<num> x, List<num> y) {
    if (x.length != y.length || x.length < 2) {
      return double.nan;
    }

    double meanX =
        x.map((e) => e.toDouble()).reduce((a, b) => a + b) / x.length;
    double meanY =
        y.map((e) => e.toDouble()).reduce((a, b) => a + b) / y.length;

    double numerator = 0;
    double sumSquaredX = 0;
    double sumSquaredY = 0;

    for (int i = 0; i < x.length; i++) {
      double diffX = x[i] - meanX;
      double diffY = y[i] - meanY;

      numerator += diffX * diffY;
      sumSquaredX += diffX * diffX;
      sumSquaredY += diffY * diffY;
    }

    double denominator = sqrt(sumSquaredX * sumSquaredY);

    if (denominator == 0) {
      return double.nan;
    }

    return numerator / denominator;
  }

  /// Calculates Spearman rank correlation coefficient.
  double _spearmanCorrelation(List<num> x, List<num> y) {
    if (x.length != y.length || x.length < 2) {
      return double.nan;
    }

    // Convert to ranks
    List<double> ranksX = _calculateRanks(x);
    List<double> ranksY = _calculateRanks(y);

    // Calculate Pearson correlation on ranks
    return _pearsonCorrelation(ranksX.cast<num>(), ranksY.cast<num>());
  }

  /// Helper method to calculate ranks for Spearman correlation.
  List<double> _calculateRanks(List<num> values) {
    List<MapEntry<num, int>> indexed = [];
    for (int i = 0; i < values.length; i++) {
      indexed.add(MapEntry(values[i], i));
    }

    // Sort by value
    indexed.sort((a, b) => a.key.compareTo(b.key));

    List<double> ranks = List.filled(values.length, 0.0);

    // Assign ranks, handling ties by averaging
    int i = 0;
    while (i < indexed.length) {
      int j = i;
      // Find the end of tied values
      while (j < indexed.length && indexed[j].key == indexed[i].key) {
        j++;
      }

      // Calculate average rank for tied values
      double avgRank = (i + j - 1) / 2.0 + 1; // +1 because ranks start at 1

      // Assign average rank to all tied values
      for (int k = i; k < j; k++) {
        ranks[indexed[k].value] = avgRank;
      }

      i = j;
    }

    return ranks;
  }

  /// Returns the n largest values ordered by columns.
  ///
  /// Parameters:
  /// - `n`: Number of rows to return.
  /// - `columns`: Column name(s) to order by. Can be a String or `List<String>`.
  /// - `keep`: When there are duplicate values:
  ///   - 'first' (default): Prioritize the first occurrence.
  ///   - 'last': Prioritize the last occurrence.
  ///   - 'all': Keep all ties (may return more than n rows).
  ///
  /// Returns:
  /// A new DataFrame with the n largest values.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Name': 'Alice', 'Score': 95},
  ///   {'Name': 'Bob', 'Score': 87},
  ///   {'Name': 'Charlie', 'Score': 92},
  ///   {'Name': 'David', 'Score': 88},
  /// ]);
  ///
  /// var top3 = df.nlargest(3, 'Score');
  /// // Returns rows for Alice (95), Charlie (92), David (88)
  /// ```
  DataFrame nlargest(int n, dynamic columns, {String keep = 'first'}) {
    if (n <= 0) {
      return DataFrame.fromRows([], columns: this.columns);
    }

    final List<String> sortColumns =
        columns is String ? [columns] : columns as List<String>;

    // Validate columns exist
    for (var col in sortColumns) {
      if (!this.columns.contains(col)) {
        throw ArgumentError('Column "$col" not found in DataFrame');
      }
    }

    // Create list of (index, row) pairs
    final indexedRows =
        List.generate(rows.length, (i) => {'idx': i, 'row': rows[i]});

    // Sort by specified columns in descending order
    indexedRows.sort((a, b) {
      for (var col in sortColumns) {
        final colIdx = this.columns.indexOf(col);
        final aVal = a['row'][colIdx];
        final bVal = b['row'][colIdx];

        // Handle null/missing values
        if (aVal == null && bVal == null) continue;
        if (aVal == null) return 1;
        if (bVal == null) return -1;

        // Compare values (descending order)
        if (aVal is Comparable && bVal is Comparable) {
          final cmp = (bVal).compareTo(aVal);
          if (cmp != 0) return cmp;
        }
      }

      // If all columns are equal, use original index for stability
      if (keep == 'first') {
        return (a['idx'] as int).compareTo(b['idx'] as int);
      } else if (keep == 'last') {
        return (b['idx'] as int).compareTo(a['idx'] as int);
      }
      return 0;
    });

    // Take top n rows
    final resultCount =
        keep == 'all' ? indexedRows.length : min(n, indexedRows.length);
    final resultData = <List<dynamic>>[];
    final resultIndex = <dynamic>[];

    for (int i = 0; i < resultCount; i++) {
      if (keep != 'all' && i >= n) break;
      final idx = indexedRows[i]['idx'] as int;
      resultData.add(List<dynamic>.from(rows[idx]));
      resultIndex.add(index[idx]);
    }

    return DataFrame.fromRows(
      List.generate(resultData.length, (i) {
        return Map.fromIterables(this.columns, resultData[i]);
      }),
      index: resultIndex,
    );
  }

  /// Returns the n smallest values ordered by columns.
  ///
  /// Parameters:
  /// - `n`: Number of rows to return.
  /// - `columns`: Column name(s) to order by. Can be a String or `List<String>`.
  /// - `keep`: When there are duplicate values:
  ///   - 'first' (default): Prioritize the first occurrence.
  ///   - 'last': Prioritize the last occurrence.
  ///   - 'all': Keep all ties (may return more than n rows).
  ///
  /// Returns:
  /// A new DataFrame with the n smallest values.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromRows([
  ///   {'Name': 'Alice', 'Score': 95},
  ///   {'Name': 'Bob', 'Score': 87},
  ///   {'Name': 'Charlie', 'Score': 92},
  ///   {'Name': 'David', 'Score': 88},
  /// ]);
  ///
  /// var bottom2 = df.nsmallest(2, 'Score');
  /// // Returns rows for Bob (87), David (88)
  /// ```
  DataFrame nsmallest(int n, dynamic columns, {String keep = 'first'}) {
    if (n <= 0) {
      return DataFrame.fromRows([], columns: this.columns);
    }

    final List<String> sortColumns =
        columns is String ? [columns] : columns as List<String>;

    // Validate columns exist
    for (var col in sortColumns) {
      if (!this.columns.contains(col)) {
        throw ArgumentError('Column "$col" not found in DataFrame');
      }
    }

    // Create list of (index, row) pairs
    final indexedRows =
        List.generate(rows.length, (i) => {'idx': i, 'row': rows[i]});

    // Sort by specified columns in ascending order
    indexedRows.sort((a, b) {
      for (var col in sortColumns) {
        final colIdx = this.columns.indexOf(col);
        final aVal = a['row'][colIdx];
        final bVal = b['row'][colIdx];

        // Handle null/missing values
        if (aVal == null && bVal == null) continue;
        if (aVal == null) return 1;
        if (bVal == null) return -1;

        // Compare values (ascending order)
        if (aVal is Comparable && bVal is Comparable) {
          final cmp = (aVal).compareTo(bVal);
          if (cmp != 0) return cmp;
        }
      }

      // If all columns are equal, use original index for stability
      if (keep == 'first') {
        return (a['idx'] as int).compareTo(b['idx'] as int);
      } else if (keep == 'last') {
        return (b['idx'] as int).compareTo(a['idx'] as int);
      }
      return 0;
    });

    // Take top n rows
    final resultCount =
        keep == 'all' ? indexedRows.length : min(n, indexedRows.length);
    final resultData = <List<dynamic>>[];
    final resultIndex = <dynamic>[];

    for (int i = 0; i < resultCount; i++) {
      if (keep != 'all' && i >= n) break;
      final idx = indexedRows[i]['idx'] as int;
      resultData.add(List<dynamic>.from(rows[idx]));
      resultIndex.add(index[idx]);
    }

    return DataFrame.fromRows(
      List.generate(resultData.length, (i) {
        return Map.fromIterables(this.columns, resultData[i]);
      }),
      index: resultIndex,
    );
  }

  /// Helper method to check if a value is considered missing.
  bool _isMissingValue(dynamic value) {
    return value == null ||
        (replaceMissingValueWith != null && value == replaceMissingValueWith) ||
        _missingDataIndicator.contains(value);
  }
}
