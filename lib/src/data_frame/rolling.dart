part of 'data_frame.dart';

/// **PREFERRED**: Class providing comprehensive rolling window operations for DataFrame.
///
/// This class is returned by the `rollingWindow()` method and provides extensive
/// pandas-like statistical operations that can be applied over a rolling window across
/// all DataFrame columns simultaneously.
///
/// **Key Features**:
/// - **Multi-column operations**: Processes all numeric columns at once
/// - **Comprehensive statistics**: Basic (mean, sum, min, max, std, variance) and advanced (median, quantile, skew, kurtosis)
/// - **Correlation analysis**: Rolling correlation and covariance between DataFrames
/// - **Custom functions**: Apply user-defined functions via `apply()`
/// - **Flexible windowing**: Support for centered windows, minimum periods, and different window types
/// - **Pandas compatibility**: API designed to match pandas rolling operations
///
/// **Comparison with deprecated `rolling()` method**:
/// ```dart
/// // OLD (deprecated, single column):
/// var result = df.rolling('column', 3, 'mean');
///
/// // NEW (recommended, all columns):
/// var result = df.rollingWindow(3).mean();
/// var singleColumn = result['column']; // Extract specific column if needed
/// ```
class RollingDataFrame {
  final DataFrame _df;
  final int window;
  final int? minPeriods;
  final bool center;
  final String winType;

  /// Creates a RollingDataFrame instance.
  ///
  /// Parameters:
  /// - `_df`: The DataFrame to apply rolling operations to
  /// - `window`: Size of the rolling window
  /// - `minPeriods`: Minimum number of observations required to have a value
  /// - `center`: Whether to center the window around the current observation
  /// - `winType`: Type of window ('boxcar' for uniform weighting)
  RollingDataFrame(this._df, this.window,
      {this.minPeriods, this.center = false, this.winType = 'boxcar'});

  /// Calculates the rolling mean for each numeric column.
  ///
  /// Returns:
  /// A new DataFrame with rolling mean values. The first (window-1) values
  /// will be the missing value representation unless minPeriods is specified.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9]
  /// ], columns: ['A', 'B', 'C']);
  /// var rollingMean = df.rolling(2).mean();
  /// print(rollingMean);
  /// ```
  DataFrame mean() {
    return _applyRollingOperation((List<num> windowData) {
      if (windowData.isEmpty) return _df.replaceMissingValueWith;
      return windowData.reduce((a, b) => a + b) / windowData.length;
    });
  }

  /// Calculates the rolling sum for each numeric column.
  ///
  /// Returns:
  /// A new DataFrame with rolling sum values.
  DataFrame sum() {
    return _applyRollingOperation((List<num> windowData) {
      if (windowData.isEmpty) return _df.replaceMissingValueWith;
      return windowData.reduce((a, b) => a + b);
    });
  }

  /// Calculates the rolling standard deviation for each numeric column.
  ///
  /// Returns:
  /// A new DataFrame with rolling standard deviation values.
  DataFrame std() {
    return _applyRollingOperation((List<num> windowData) {
      if (windowData.length < 2) return _df.replaceMissingValueWith;

      double mean = windowData.reduce((a, b) => a + b) / windowData.length;
      double sumSquaredDiffs = windowData
          .map((value) => (value - mean) * (value - mean))
          .reduce((a, b) => a + b);
      double variance = sumSquaredDiffs / (windowData.length - 1);
      return sqrt(variance);
    });
  }

  /// Calculates the rolling variance for each numeric column.
  ///
  /// Returns:
  /// A new DataFrame with rolling variance values.
  DataFrame variance() {
    return _applyRollingOperation((List<num> windowData) {
      if (windowData.length < 2) return _df.replaceMissingValueWith;

      double mean = windowData.reduce((a, b) => a + b) / windowData.length;
      double sumSquaredDiffs = windowData
          .map((value) => (value - mean) * (value - mean))
          .reduce((a, b) => a + b);
      return sumSquaredDiffs / (windowData.length - 1);
    });
  }

  /// Calculates the rolling minimum for each numeric column.
  ///
  /// Returns:
  /// A new DataFrame with rolling minimum values.
  DataFrame min() {
    return _applyRollingOperation((List<num> windowData) {
      if (windowData.isEmpty) return _df.replaceMissingValueWith;
      return windowData.reduce((a, b) => a < b ? a : b);
    });
  }

  /// Calculates the rolling maximum for each numeric column.
  ///
  /// Returns:
  /// A new DataFrame with rolling maximum values.
  DataFrame max() {
    return _applyRollingOperation((List<num> windowData) {
      if (windowData.isEmpty) return _df.replaceMissingValueWith;
      return windowData.reduce((a, b) => a > b ? a : b);
    });
  }

  /// Calculates the rolling median for each numeric column.
  ///
  /// Returns:
  /// A new DataFrame with rolling median values.
  DataFrame median() {
    return _applyRollingOperation((List<num> windowData) {
      if (windowData.isEmpty) return _df.replaceMissingValueWith;

      List<num> sortedData = List.from(windowData)..sort();
      int length = sortedData.length;

      if (length % 2 == 0) {
        return (sortedData[length ~/ 2 - 1] + sortedData[length ~/ 2]) / 2.0;
      } else {
        return sortedData[length ~/ 2];
      }
    });
  }

  /// Calculates the rolling quantile for each numeric column.
  ///
  /// Parameters:
  /// - `q`: The quantile to compute (between 0 and 1)
  ///
  /// Returns:
  /// A new DataFrame with rolling quantile values.
  DataFrame quantile(double q) {
    if (q < 0 || q > 1) {
      throw ArgumentError('Quantile must be between 0 and 1');
    }

    return _applyRollingOperation((List<num> windowData) {
      if (windowData.isEmpty) return _df.replaceMissingValueWith;

      List<num> sortedData = List.from(windowData)..sort();
      int length = sortedData.length;

      if (length == 1) return sortedData[0];

      double index = q * (length - 1);
      int lowerIndex = index.floor();
      int upperIndex = index.ceil();

      if (lowerIndex == upperIndex) {
        return sortedData[lowerIndex];
      } else {
        double weight = index - lowerIndex;
        return sortedData[lowerIndex] * (1 - weight) +
            sortedData[upperIndex] * weight;
      }
    });
  }

  /// Calculates the rolling correlation between columns.
  ///
  /// Parameters:
  /// - `other`: Another DataFrame or Series to calculate correlation with.
  ///   If null, calculates pairwise correlations between all columns.
  /// - `pairwise`: If true, calculates pairwise correlations between all columns.
  ///
  /// Returns:
  /// A DataFrame with rolling correlation values.
  DataFrame corr({DataFrame? other, bool pairwise = false}) {
    if (other != null) {
      return _applyRollingCorrelation(other);
    } else if (pairwise) {
      return _applyPairwiseRollingCorrelation();
    } else {
      throw ArgumentError(
          'Either provide other DataFrame or set pairwise=true');
    }
  }

  /// Calculates the rolling covariance between columns.
  ///
  /// Parameters:
  /// - `other`: Another DataFrame or Series to calculate covariance with.
  ///   If null, calculates pairwise covariances between all columns.
  /// - `pairwise`: If true, calculates pairwise covariances between all columns.
  ///
  /// Returns:
  /// A DataFrame with rolling covariance values.
  DataFrame cov({DataFrame? other, bool pairwise = false}) {
    if (other != null) {
      return _applyRollingCovariance(other);
    } else if (pairwise) {
      return _applyPairwiseRollingCovariance();
    } else {
      throw ArgumentError(
          'Either provide other DataFrame or set pairwise=true');
    }
  }

  /// Calculates the rolling skewness for each numeric column.
  ///
  /// Returns:
  /// A new DataFrame with rolling skewness values.
  DataFrame skew() {
    return _applyRollingOperation((List<num> windowData) {
      if (windowData.length < 3) return _df.replaceMissingValueWith;

      double mean = windowData.reduce((a, b) => a + b) / windowData.length;

      double sumSquaredDiffs = windowData
          .map((value) => (value - mean) * (value - mean))
          .reduce((a, b) => a + b);

      double variance = sumSquaredDiffs / (windowData.length - 1);
      double stdDev = sqrt(variance);

      if (stdDev == 0) return _df.replaceMissingValueWith;

      double sumCubedDiffs = windowData
          .map((value) => pow((value - mean) / stdDev, 3).toDouble())
          .reduce((a, b) => a + b);

      int n = windowData.length;
      return (n / ((n - 1) * (n - 2))) * sumCubedDiffs;
    });
  }

  /// Calculates the rolling kurtosis for each numeric column.
  ///
  /// Parameters:
  /// - `fisher`: If true (default), returns Fisher's definition (excess kurtosis).
  ///
  /// Returns:
  /// A new DataFrame with rolling kurtosis values.
  DataFrame kurt({bool fisher = true}) {
    return _applyRollingOperation((List<num> windowData) {
      if (windowData.length < 4) return _df.replaceMissingValueWith;

      double mean = windowData.reduce((a, b) => a + b) / windowData.length;

      double sumSquaredDiffs = windowData
          .map((value) => (value - mean) * (value - mean))
          .reduce((a, b) => a + b);

      double variance = sumSquaredDiffs / (windowData.length - 1);
      double stdDev = sqrt(variance);

      if (stdDev == 0) return _df.replaceMissingValueWith;

      double sumFourthPowers = windowData
          .map((value) => pow((value - mean) / stdDev, 4).toDouble())
          .reduce((a, b) => a + b);

      int n = windowData.length;
      double kurtosisValue =
          (n * (n + 1) / ((n - 1) * (n - 2) * (n - 3))) * sumFourthPowers;

      if (fisher) {
        double correction = 3.0 * (n - 1) * (n - 1) / ((n - 2) * (n - 3));
        return kurtosisValue - correction;
      } else {
        return kurtosisValue;
      }
    });
  }

  /// Applies a custom aggregation function over the rolling window.
  ///
  /// Parameters:
  /// - `func`: A function that takes a `List<num>` and returns a dynamic value
  ///
  /// Returns:
  /// A new DataFrame with the results of applying the function to each window.
  DataFrame apply(dynamic Function(List<num>) func) {
    return _applyRollingOperation(func);
  }

  /// Internal method to apply rolling operations across all columns.
  DataFrame _applyRollingOperation(dynamic Function(List<num>) operation) {
    List<List<dynamic>> resultData = [];
    int effectiveMinPeriods = minPeriods ?? window;

    for (int rowIndex = 0; rowIndex < _df._data.length; rowIndex++) {
      List<dynamic> resultRow = [];

      for (int colIndex = 0; colIndex < _df._columns.length; colIndex++) {
        // Determine window bounds
        int startIndex, endIndex;

        if (center) {
          int halfWindow = window ~/ 2;
          startIndex = (rowIndex - halfWindow).clamp(0, _df._data.length);
          endIndex = (rowIndex + halfWindow + 1).clamp(0, _df._data.length);
        } else {
          startIndex = (rowIndex - window + 1).clamp(0, _df._data.length);
          endIndex = rowIndex + 1;
        }

        // Check if we have enough periods
        int actualWindow = endIndex - startIndex;
        if (actualWindow < effectiveMinPeriods) {
          resultRow.add(_df.replaceMissingValueWith);
          continue;
        }

        // Collect window data for this column
        List<num> windowData = [];
        for (int i = startIndex; i < endIndex; i++) {
          dynamic value = _df._data[i][colIndex];
          if (!_df._isMissingValue(value) && value is num) {
            windowData.add(value);
          }
        }

        // Apply the operation
        dynamic result = operation(windowData);
        resultRow.add(result);
      }

      resultData.add(resultRow);
    }

    return DataFrame(
      resultData,
      columns: _df._columns.toList(),
      index: _df.index.toList(),
      replaceMissingValueWith: _df.replaceMissingValueWith,
      missingDataIndicator: _df._missingDataIndicator,
    );
  }

  /// Internal method to apply rolling correlation with another DataFrame.
  DataFrame _applyRollingCorrelation(DataFrame other) {
    if (_df._data.length != other._data.length) {
      throw ArgumentError('DataFrames must have the same number of rows');
    }

    List<List<dynamic>> resultData = [];
    int effectiveMinPeriods = minPeriods ?? window;

    for (int rowIndex = 0; rowIndex < _df._data.length; rowIndex++) {
      List<dynamic> resultRow = [];

      for (int colIndex = 0; colIndex < _df._columns.length; colIndex++) {
        if (colIndex >= other._columns.length) {
          resultRow.add(_df.replaceMissingValueWith);
          continue;
        }

        // Determine window bounds
        int startIndex = (rowIndex - window + 1).clamp(0, _df._data.length);
        int endIndex = rowIndex + 1;

        if (endIndex - startIndex < effectiveMinPeriods) {
          resultRow.add(_df.replaceMissingValueWith);
          continue;
        }

        // Collect paired window data
        List<num> windowData1 = [];
        List<num> windowData2 = [];

        for (int i = startIndex; i < endIndex; i++) {
          dynamic value1 = _df._data[i][colIndex];
          dynamic value2 = other._data[i][colIndex];

          if (!_isMissingValue(value1) &&
              !_isMissingValue(value2) &&
              value1 is num &&
              value2 is num) {
            windowData1.add(value1);
            windowData2.add(value2);
          }
        }

        if (windowData1.length < 2) {
          resultRow.add(_df.replaceMissingValueWith);
        } else {
          double correlation =
              _calculatePearsonCorrelation(windowData1, windowData2);
          resultRow.add(correlation);
        }
      }

      resultData.add(resultRow);
    }

    return DataFrame(
      resultData,
      columns: _df._columns.toList(),
      index: _df.index.toList(),
      replaceMissingValueWith: _df.replaceMissingValueWith,
      missingDataIndicator: _df._missingDataIndicator,
    );
  }

  /// Internal method to apply pairwise rolling correlation.
  DataFrame _applyPairwiseRollingCorrelation() {
    // Get numeric columns only
    List<String> numericColumns = [];
    List<int> numericColumnIndices = [];

    for (int colIndex = 0; colIndex < _df._columns.length; colIndex++) {
      String columnName = _df._columns[colIndex].toString();

      bool hasNumericValues = false;
      for (int rowIndex = 0; rowIndex < _df._data.length; rowIndex++) {
        dynamic value = _df._data[rowIndex][colIndex];
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

    // Create correlation matrix for each time point
    List<List<dynamic>> resultData = [];
    int effectiveMinPeriods = minPeriods ?? window;

    for (int rowIndex = 0; rowIndex < _df._data.length; rowIndex++) {
      List<dynamic> resultRow = [];

      for (int i = 0; i < numericColumns.length; i++) {
        for (int j = 0; j < numericColumns.length; j++) {
          if (i == j) {
            resultRow.add(1.0);
          } else {
            int startIndex = (rowIndex - window + 1).clamp(0, _df._data.length);
            int endIndex = rowIndex + 1;

            if (endIndex - startIndex < effectiveMinPeriods) {
              resultRow.add(_df.replaceMissingValueWith);
            } else {
              double correlation = _calculateRollingCorrelationBetweenColumns(
                  numericColumnIndices[i],
                  numericColumnIndices[j],
                  startIndex,
                  endIndex);
              resultRow.add(correlation);
            }
          }
        }
      }

      resultData.add(resultRow);
    }

    // Create column names for the flattened correlation matrix
    List<String> resultColumns = [];
    for (int i = 0; i < numericColumns.length; i++) {
      for (int j = 0; j < numericColumns.length; j++) {
        resultColumns.add('${numericColumns[i]}_${numericColumns[j]}');
      }
    }

    return DataFrame(
      resultData,
      columns: resultColumns,
      index: _df.index.toList(),
      replaceMissingValueWith: _df.replaceMissingValueWith,
      missingDataIndicator: _df._missingDataIndicator,
    );
  }

  /// Internal method to apply rolling covariance with another DataFrame.
  DataFrame _applyRollingCovariance(DataFrame other) {
    if (_df._data.length != other._data.length) {
      throw ArgumentError('DataFrames must have the same number of rows');
    }

    List<List<dynamic>> resultData = [];
    int effectiveMinPeriods = minPeriods ?? window;

    for (int rowIndex = 0; rowIndex < _df._data.length; rowIndex++) {
      List<dynamic> resultRow = [];

      for (int colIndex = 0; colIndex < _df._columns.length; colIndex++) {
        if (colIndex >= other._columns.length) {
          resultRow.add(_df.replaceMissingValueWith);
          continue;
        }

        int startIndex = (rowIndex - window + 1).clamp(0, _df._data.length);
        int endIndex = rowIndex + 1;

        if (endIndex - startIndex < effectiveMinPeriods) {
          resultRow.add(_df.replaceMissingValueWith);
          continue;
        }

        List<num> windowData1 = [];
        List<num> windowData2 = [];

        for (int i = startIndex; i < endIndex; i++) {
          dynamic value1 = _df._data[i][colIndex];
          dynamic value2 = other._data[i][colIndex];

          if (!_isMissingValue(value1) &&
              !_isMissingValue(value2) &&
              value1 is num &&
              value2 is num) {
            windowData1.add(value1);
            windowData2.add(value2);
          }
        }

        if (windowData1.length < 2) {
          resultRow.add(_df.replaceMissingValueWith);
        } else {
          double covariance = _calculateCovariance(windowData1, windowData2);
          resultRow.add(covariance);
        }
      }

      resultData.add(resultRow);
    }

    return DataFrame(
      resultData,
      columns: _df._columns.toList(),
      index: _df.index.toList(),
      replaceMissingValueWith: _df.replaceMissingValueWith,
      missingDataIndicator: _df._missingDataIndicator,
    );
  }

  /// Internal method to apply pairwise rolling covariance.
  DataFrame _applyPairwiseRollingCovariance() {
    // Similar to pairwise correlation but calculating covariance
    List<String> numericColumns = [];
    List<int> numericColumnIndices = [];

    for (int colIndex = 0; colIndex < _df._columns.length; colIndex++) {
      String columnName = _df._columns[colIndex].toString();

      bool hasNumericValues = false;
      for (int rowIndex = 0; rowIndex < _df._data.length; rowIndex++) {
        dynamic value = _df._data[rowIndex][colIndex];
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

    List<List<dynamic>> resultData = [];
    int effectiveMinPeriods = minPeriods ?? window;

    for (int rowIndex = 0; rowIndex < _df._data.length; rowIndex++) {
      List<dynamic> resultRow = [];

      for (int i = 0; i < numericColumns.length; i++) {
        for (int j = 0; j < numericColumns.length; j++) {
          int startIndex = (rowIndex - window + 1).clamp(0, _df._data.length);
          int endIndex = rowIndex + 1;

          if (endIndex - startIndex < effectiveMinPeriods) {
            resultRow.add(_df.replaceMissingValueWith);
          } else {
            double covariance = _calculateRollingCovarianceBetweenColumns(
                numericColumnIndices[i],
                numericColumnIndices[j],
                startIndex,
                endIndex);
            resultRow.add(covariance);
          }
        }
      }

      resultData.add(resultRow);
    }

    List<String> resultColumns = [];
    for (int i = 0; i < numericColumns.length; i++) {
      for (int j = 0; j < numericColumns.length; j++) {
        resultColumns.add('${numericColumns[i]}_${numericColumns[j]}');
      }
    }

    return DataFrame(
      resultData,
      columns: resultColumns,
      index: _df.index.toList(),
      replaceMissingValueWith: _df.replaceMissingValueWith,
      missingDataIndicator: _df._missingDataIndicator,
    );
  }

  /// Helper method to calculate Pearson correlation coefficient.
  double _calculatePearsonCorrelation(List<num> x, List<num> y) {
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

  /// Helper method to calculate covariance.
  double _calculateCovariance(List<num> x, List<num> y) {
    if (x.length != y.length || x.length < 2) {
      return double.nan;
    }

    double meanX =
        x.map((e) => e.toDouble()).reduce((a, b) => a + b) / x.length;
    double meanY =
        y.map((e) => e.toDouble()).reduce((a, b) => a + b) / y.length;

    double sumProducts = 0;
    for (int i = 0; i < x.length; i++) {
      sumProducts += (x[i] - meanX) * (y[i] - meanY);
    }

    return sumProducts / (x.length - 1);
  }

  /// Helper method to calculate rolling correlation between two columns.
  double _calculateRollingCorrelationBetweenColumns(
      int colIndex1, int colIndex2, int startIndex, int endIndex) {
    List<num> values1 = [];
    List<num> values2 = [];

    for (int rowIndex = startIndex; rowIndex < endIndex; rowIndex++) {
      dynamic val1 = _df._data[rowIndex][colIndex1];
      dynamic val2 = _df._data[rowIndex][colIndex2];

      if (!_isMissingValue(val1) &&
          !_isMissingValue(val2) &&
          val1 is num &&
          val2 is num) {
        values1.add(val1);
        values2.add(val2);
      }
    }

    return _calculatePearsonCorrelation(values1, values2);
  }

  /// Helper method to calculate rolling covariance between two columns.
  double _calculateRollingCovarianceBetweenColumns(
      int colIndex1, int colIndex2, int startIndex, int endIndex) {
    List<num> values1 = [];
    List<num> values2 = [];

    for (int rowIndex = startIndex; rowIndex < endIndex; rowIndex++) {
      dynamic val1 = _df._data[rowIndex][colIndex1];
      dynamic val2 = _df._data[rowIndex][colIndex2];

      if (!_isMissingValue(val1) &&
          !_isMissingValue(val2) &&
          val1 is num &&
          val2 is num) {
        values1.add(val1);
        values2.add(val2);
      }
    }

    return _calculateCovariance(values1, values2);
  }

  /// Helper method to check if a value is considered missing.
  bool _isMissingValue(dynamic value) {
    return value == null ||
        (_df.replaceMissingValueWith != null &&
            value == _df.replaceMissingValueWith) ||
        _df._missingDataIndicator.contains(value);
  }
}

/// Extension to add rolling window functionality to DataFrame.
extension DataFrameRolling on DataFrame {
  /// **RECOMMENDED**: Creates a rolling window object for the DataFrame.
  ///
  /// This is the **preferred method** for rolling window operations in DartFrame.
  /// It provides comprehensive pandas-like functionality for rolling calculations
  /// across all numeric columns simultaneously.
  ///
  /// **Advantages over the deprecated `rolling()` method**:
  /// - ✅ Works on all columns at once (more efficient)
  /// - ✅ Comprehensive statistical functions (mean, sum, std, variance, median, quantile, skew, kurtosis)
  /// - ✅ Advanced operations (correlation, covariance, custom functions)
  /// - ✅ Better pandas compatibility
  /// - ✅ More flexible parameter options
  ///
  /// Rolling window operations allow you to perform calculations over a
  /// sliding window of data points across all numeric columns.
  ///
  /// Parameters:
  /// - `window`: The size of the rolling window (number of observations)
  /// - `minPeriods`: Minimum number of observations required to have a value.
  ///   If null, defaults to window size.
  /// - `center`: Whether to center the window around the current observation.
  ///   If false (default), uses trailing window.
  /// - `winType`: Type of window ('boxcar' for uniform weighting)
  ///
  /// Returns:
  /// A `RollingDataFrame` object that provides rolling statistical methods:
  /// - Basic: `mean()`, `sum()`, `min()`, `max()`, `std()`, `variance()`
  /// - Advanced: `median()`, `quantile()`, `skew()`, `kurt()`
  /// - Correlation: `corr()`, `cov()`
  /// - Custom: `apply()`
  ///
  /// Throws:
  /// - `ArgumentError` if window size is not positive
  /// - `ArgumentError` if window size is larger than DataFrame length
  /// - `ArgumentError` if minPeriods is not positive
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9],
  ///   [10, 11, 12]
  /// ], columns: ['A', 'B', 'C']);
  ///
  /// // Basic rolling operations
  /// var rolling = df.rollingWindow(3);
  /// var meanResult = rolling.mean();     // Rolling mean for all columns
  /// var sumResult = rolling.sum();       // Rolling sum for all columns
  /// var stdResult = rolling.std();       // Rolling standard deviation
  ///
  /// // Advanced operations
  /// var medianResult = rolling.median(); // Rolling median
  /// var q75Result = rolling.quantile(0.75); // 75th percentile
  ///
  /// // Custom function
  /// var rangeResult = rolling.apply((window) =>
  ///   window.reduce((a, b) => a > b ? a : b) -
  ///   window.reduce((a, b) => a < b ? a : b)
  /// );
  ///
  /// // Correlation between DataFrames
  /// var df2 = DataFrame([[2, 4, 6], [8, 10, 12]], columns: ['A', 'B', 'C']);
  /// var corrResult = rolling.corr(other: df2);
  ///
  /// print(meanResult);
  /// ```
  RollingDataFrame rollingWindow(int window,
      {int? minPeriods, bool center = false, String winType = 'boxcar'}) {
    if (window <= 0) {
      throw ArgumentError('Window size must be positive');
    }
    if (window > _data.length) {
      throw ArgumentError('Window size cannot be larger than DataFrame length');
    }
    if (minPeriods != null && minPeriods <= 0) {
      throw ArgumentError('minPeriods must be positive');
    }

    return RollingDataFrame(this, window,
        minPeriods: minPeriods, center: center, winType: winType);
  }
}
