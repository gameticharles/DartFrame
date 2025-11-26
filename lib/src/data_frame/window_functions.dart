part of 'data_frame.dart';

/// A class representing exponentially weighted window operations on a DataFrame.
///
/// Provides exponentially weighted moving statistics with pandas-like functionality.
///
/// Example:
/// ```dart
/// var df = DataFrame([
///   [1.0, 10.0],
///   [2.0, 20.0],
///   [3.0, 30.0],
/// ], columns: ['A', 'B']);
///
/// // Exponentially weighted mean with span of 2
/// var ewm = df.ewm(span: 2).mean();
/// ```
class ExponentialWeightedWindow {
  final DataFrame _df;
  final double? _alpha;
  final int? _span;
  final double? _halflife;
  final double? _com;
  final bool _adjustWeights;
  final bool _ignoreNA;

  /// Creates an ExponentialWeightedWindow.
  ///
  /// Parameters:
  /// - `alpha`: Smoothing factor (0 < alpha <= 1)
  /// - `span`: Specify decay in terms of span (span >= 1)
  /// - `halflife`: Specify decay in terms of half-life
  /// - `com`: Specify decay in terms of center of mass (com >= 0)
  /// - `adjustWeights`: Divide by decaying adjustment factor to account for imbalance
  /// - `ignoreNA`: Ignore missing values when calculating weights
  ExponentialWeightedWindow(
    this._df, {
    double? alpha,
    int? span,
    double? halflife,
    double? com,
    bool adjustWeights = true,
    bool ignoreNA = false,
  })  : _alpha = alpha,
        _span = span,
        _halflife = halflife,
        _com = com,
        _adjustWeights = adjustWeights,
        _ignoreNA = ignoreNA {
    // Validate that exactly one parameter is specified
    int paramCount =
        [alpha, span, halflife, com].where((p) => p != null).length;
    if (paramCount != 1) {
      throw ArgumentError(
          'Must specify exactly one of: alpha, span, halflife, or com');
    }
  }

  /// Calculate the alpha value from the specified parameter.
  double get _effectiveAlpha {
    if (_alpha != null) {
      if (_alpha <= 0 || _alpha > 1) {
        throw ArgumentError('alpha must be between 0 and 1');
      }
      return _alpha;
    } else if (_span != null) {
      if (_span < 1) {
        throw ArgumentError('span must be >= 1');
      }
      return 2.0 / (_span + 1);
    } else if (_halflife != null) {
      if (_halflife <= 0) {
        throw ArgumentError('halflife must be > 0');
      }
      return 1 - exp(-log(2) / _halflife);
    } else if (_com != null) {
      if (_com < 0) {
        throw ArgumentError('com must be >= 0');
      }
      return 1.0 / (1.0 + _com);
    }
    throw StateError('No smoothing parameter specified');
  }

  /// Exponentially weighted moving average.
  ///
  /// Example:
  /// ```dart
  /// var ewmMean = df.ewm(span: 3).mean();
  /// ```
  DataFrame mean() {
    return _applyEWM((values) => _ewmMean(values));
  }

  /// Exponentially weighted moving standard deviation.
  ///
  /// Example:
  /// ```dart
  /// var ewmStd = df.ewm(span: 3).std();
  /// ```
  DataFrame std() {
    return _applyEWM((values) => _ewmStd(values));
  }

  /// Exponentially weighted moving variance.
  ///
  /// Example:
  /// ```dart
  /// var ewmVar = df.ewm(span: 3).var_();
  /// ```
  DataFrame var_() {
    return _applyEWM((values) => _ewmVar(values));
  }

  /// Exponentially weighted moving correlation.
  ///
  /// Calculates pairwise correlation between columns.
  ///
  /// Parameters:
  /// - `other`: Optional DataFrame to compute correlation with. If null, computes pairwise correlation.
  /// - `pairwise`: If true, compute pairwise correlations between all columns.
  ///
  /// Example:
  /// ```dart
  /// // Pairwise correlation
  /// var ewmCorr = df.ewm(span: 3).corr();
  ///
  /// // Correlation with another DataFrame
  /// var ewmCorr = df.ewm(span: 3).corr(other: df2);
  /// ```
  DataFrame corr({DataFrame? other, bool pairwise = true}) {
    if (other != null) {
      return _ewmCorrWithOther(other);
    }

    if (!pairwise) {
      throw ArgumentError('Non-pairwise correlation not yet supported');
    }

    return _ewmCorrPairwise();
  }

  /// Exponentially weighted moving covariance.
  ///
  /// Calculates pairwise covariance between columns.
  ///
  /// Parameters:
  /// - `other`: Optional DataFrame to compute covariance with. If null, computes pairwise covariance.
  /// - `pairwise`: If true, compute pairwise covariances between all columns.
  ///
  /// Example:
  /// ```dart
  /// // Pairwise covariance
  /// var ewmCov = df.ewm(span: 3).cov();
  ///
  /// // Covariance with another DataFrame
  /// var ewmCov = df.ewm(span: 3).cov(other: df2);
  /// ```
  DataFrame cov({DataFrame? other, bool pairwise = true}) {
    if (other != null) {
      return _ewmCovWithOther(other);
    }

    if (!pairwise) {
      throw ArgumentError('Non-pairwise covariance not yet supported');
    }

    return _ewmCovPairwise();
  }

  /// Apply EWM operation to all numeric columns.
  DataFrame _applyEWM(List<double?> Function(List<num?>) operation) {
    List<List<dynamic>> resultData = [];

    for (int i = 0; i < _df.rowCount; i++) {
      resultData.add(List.filled(_df.columnCount, null));
    }

    for (int colIdx = 0; colIdx < _df.columnCount; colIdx++) {
      var colName = _df.columns[colIdx];
      List<dynamic> values = _df[colName].toList();

      // Check if column is numeric
      if (values.any((v) => v is num)) {
        List<num?> numericValues = <num?>[];
        for (var v in values) {
          numericValues.add(v is num ? v : null);
        }
        var ewmValues = operation(numericValues);

        for (int rowIdx = 0; rowIdx < ewmValues.length; rowIdx++) {
          resultData[rowIdx][colIdx] = ewmValues[rowIdx];
        }
      } else {
        // Non-numeric columns remain null
        for (int rowIdx = 0; rowIdx < _df.rowCount; rowIdx++) {
          resultData[rowIdx][colIdx] = null;
        }
      }
    }

    return DataFrame(resultData,
        columns: _df.columns.cast<String>(), index: _df.index);
  }

  /// Calculate exponentially weighted mean.
  List<double?> _ewmMean(List<num?> values) {
    List<double?> result = [];
    double alpha = _effectiveAlpha;
    double? ewm;
    double weightSum = 0.0;

    for (int i = 0; i < values.length; i++) {
      var value = values[i];

      if (value == null && _ignoreNA) {
        result.add(ewm);
        continue;
      }

      if (value == null) {
        result.add(null);
        ewm = null;
        weightSum = 0.0;
        continue;
      }

      if (ewm == null) {
        ewm = value.toDouble();
        weightSum = 1.0;
      } else {
        ewm = alpha * value.toDouble() + (1 - alpha) * ewm;
        if (_adjustWeights) {
          weightSum = weightSum * (1 - alpha) + 1;
        }
      }

      result.add(ewm);
    }

    return result;
  }

  /// Calculate exponentially weighted variance.
  List<double?> _ewmVar(List<num?> values) {
    List<double?> means = _ewmMean(values);
    List<double?> result = [];
    double alpha = _effectiveAlpha;
    double? ewmVar;

    for (int i = 0; i < values.length; i++) {
      var value = values[i];
      var mean = means[i];

      if (value == null || mean == null) {
        result.add(null);
        ewmVar = null;
        continue;
      }

      double diff = value.toDouble() - mean;

      if (ewmVar == null) {
        ewmVar = 0.0;
      } else {
        ewmVar = (1 - alpha) * ewmVar + alpha * diff * diff;
      }

      result.add(ewmVar);
    }

    return result;
  }

  /// Calculate exponentially weighted standard deviation.
  List<double?> _ewmStd(List<num?> values) {
    var variances = _ewmVar(values);
    return variances.map((v) => v == null ? null : sqrt(v)).toList();
  }

  /// Calculate pairwise EWM correlation.
  DataFrame _ewmCorrPairwise() {
    // Get numeric columns
    List<String> numericCols = [];
    for (var col in _df.columns) {
      var values = _df[col].toList();
      if (values.any((v) => v is num)) {
        numericCols.add(col.toString());
      }
    }

    if (numericCols.isEmpty) {
      return DataFrame.empty(columns: ['']);
    }

    // Calculate EWM covariance matrix
    var covMatrix = _ewmCovPairwise();

    // Convert covariance to correlation
    List<List<dynamic>> corrData = [];

    for (int i = 0; i < numericCols.length; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < numericCols.length; j++) {
        if (i == j) {
          row.add(1.0);
        } else {
          var cov = covMatrix[numericCols[j]].toList()[i];
          var stdI = sqrt(covMatrix[numericCols[i]].toList()[i]);
          var stdJ = sqrt(covMatrix[numericCols[j]].toList()[j]);

          if (cov == null || stdI == 0 || stdJ == 0) {
            row.add(null);
          } else {
            row.add(cov / (stdI * stdJ));
          }
        }
      }
      corrData.add(row);
    }

    return DataFrame(corrData, columns: numericCols, index: numericCols);
  }

  /// Calculate pairwise EWM covariance.
  DataFrame _ewmCovPairwise() {
    // Get numeric columns
    List<String> numericCols = [];
    Map<String, List<num?>> numericData = {};

    for (var col in _df.columns) {
      List<dynamic> values = _df[col].toList();
      if (values.any((v) => v is num)) {
        numericCols.add(col.toString());
        List<num?> numericValues = <num?>[];
        for (var v in values) {
          numericValues.add(v is num ? v : null);
        }
        numericData[col.toString()] = numericValues;
      }
    }

    if (numericCols.isEmpty) {
      return DataFrame.empty(columns: ['']);
    }

    // Calculate EWM means for each column
    Map<String, List<double?>> ewmMeans = {};
    for (var col in numericCols) {
      ewmMeans[col] = _ewmMean(numericData[col]!);
    }

    // Calculate pairwise covariances
    List<List<dynamic>> covData = [];
    double alpha = _effectiveAlpha;

    for (int i = 0; i < numericCols.length; i++) {
      List<dynamic> row = [];
      var colI = numericCols[i];
      var valuesI = numericData[colI]!;
      var meansI = ewmMeans[colI]!;

      for (int j = 0; j < numericCols.length; j++) {
        var colJ = numericCols[j];
        var valuesJ = numericData[colJ]!;
        var meansJ = ewmMeans[colJ]!;

        // Calculate EWM covariance between columns i and j
        double? ewmCov;

        for (int k = 0; k < valuesI.length; k++) {
          var vi = valuesI[k];
          var vj = valuesJ[k];
          var mi = meansI[k];
          var mj = meansJ[k];

          if (vi == null || vj == null || mi == null || mj == null) {
            continue;
          }

          double diffI = vi.toDouble() - mi;
          double diffJ = vj.toDouble() - mj;

          if (ewmCov == null) {
            ewmCov = 0.0;
          } else {
            ewmCov = (1 - alpha) * ewmCov + alpha * diffI * diffJ;
          }
        }

        row.add(ewmCov);
      }
      covData.add(row);
    }

    return DataFrame(covData, columns: numericCols, index: numericCols);
  }

  /// Calculate EWM correlation with another DataFrame.
  DataFrame _ewmCorrWithOther(DataFrame other) {
    var cov = _ewmCovWithOther(other);

    // Get standard deviations
    var thisStd = std();
    var otherStd = other
        .ewm(
          alpha: _alpha,
          span: _span,
          halflife: _halflife,
          com: _com,
          adjustWeights: _adjustWeights,
          ignoreNA: _ignoreNA,
        )
        .std();

    // Convert covariance to correlation
    List<List<dynamic>> corrData = [];

    for (int i = 0; i < cov.rowCount; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < cov.columnCount; j++) {
        var covVal = cov.rows[i][j];
        var stdThis = thisStd.rows[i][j];
        var stdOther = otherStd.rows[i][j];

        if (covVal == null ||
            stdThis == null ||
            stdOther == null ||
            stdThis == 0 ||
            stdOther == 0) {
          row.add(null);
        } else {
          row.add(covVal / (stdThis * stdOther));
        }
      }
      corrData.add(row);
    }

    return DataFrame(corrData,
        columns: cov.columns.cast<String>(), index: cov.index);
  }

  /// Calculate EWM covariance with another DataFrame.
  DataFrame _ewmCovWithOther(DataFrame other) {
    if (_df.rowCount != other.rowCount) {
      throw ArgumentError('DataFrames must have the same number of rows');
    }

    // Calculate EWM means
    var thisMeans = mean();
    var otherMeans = other
        .ewm(
          alpha: _alpha,
          span: _span,
          halflife: _halflife,
          com: _com,
          adjustWeights: _adjustWeights,
          ignoreNA: _ignoreNA,
        )
        .mean();

    List<List<dynamic>> covData = [];

    for (int i = 0; i < _df.rowCount; i++) {
      List<dynamic> row = [];

      for (int j = 0; j < _df.columnCount; j++) {
        var thisVal = _df.rows[i][j];
        var thisMean = thisMeans.rows[i][j];

        for (int k = 0; k < other.columnCount; k++) {
          var otherVal = other.rows[i][k];
          var otherMean = otherMeans.rows[i][k];

          if (thisVal == null ||
              otherVal == null ||
              thisMean == null ||
              otherMean == null) {
            row.add(null);
            continue;
          }

          double diffThis =
              (thisVal as num).toDouble() - (thisMean as num).toDouble();
          double diffOther =
              (otherVal as num).toDouble() - (otherMean as num).toDouble();

          // Simple covariance calculation
          row.add(diffThis * diffOther);
        }
      }
      covData.add(row);
    }

    // Create column names
    List<String> colNames = [];
    for (var thisCol in _df.columns) {
      for (var otherCol in other.columns) {
        colNames.add('${thisCol}_$otherCol');
      }
    }

    return DataFrame(covData, columns: colNames, index: _df.index);
  }
}

/// A class representing expanding window operations on a DataFrame.
///
/// Provides cumulative statistics over an expanding window.
///
/// Example:
/// ```dart
/// var df = DataFrame([
///   [1.0, 10.0],
///   [2.0, 20.0],
///   [3.0, 30.0],
/// ], columns: ['A', 'B']);
///
/// // Expanding mean
/// var expandingMean = df.expanding().mean();
/// ```
class ExpandingWindow {
  final DataFrame _df;
  final int _minPeriods;

  /// Creates an ExpandingWindow.
  ///
  /// Parameters:
  /// - `minPeriods`: Minimum number of observations required (default: 1)
  ExpandingWindow(this._df, {int minPeriods = 1}) : _minPeriods = minPeriods {
    if (minPeriods < 1) {
      throw ArgumentError('minPeriods must be >= 1');
    }
  }

  /// Expanding mean.
  ///
  /// Example:
  /// ```dart
  /// var result = df.expanding().mean();
  /// ```
  DataFrame mean() {
    return _applyExpanding((values) => _expandingMean(values));
  }

  /// Expanding sum.
  ///
  /// Example:
  /// ```dart
  /// var result = df.expanding().sum();
  /// ```
  DataFrame sum() {
    return _applyExpanding((values) => _expandingSum(values));
  }

  /// Expanding standard deviation.
  ///
  /// Example:
  /// ```dart
  /// var result = df.expanding().std();
  /// ```
  DataFrame std() {
    return _applyExpanding((values) => _expandingStd(values));
  }

  /// Expanding minimum.
  ///
  /// Example:
  /// ```dart
  /// var result = df.expanding().min();
  /// ```
  DataFrame min() {
    return _applyExpanding((values) => _expandingMin(values));
  }

  /// Expanding maximum.
  ///
  /// Example:
  /// ```dart
  /// var result = df.expanding().max();
  /// ```
  DataFrame max() {
    return _applyExpanding((values) => _expandingMax(values));
  }

  /// Apply expanding operation to all numeric columns.
  DataFrame _applyExpanding(List<double?> Function(List<num?>) operation) {
    List<List<dynamic>> resultData = [];

    for (int i = 0; i < _df.rowCount; i++) {
      resultData.add(List.filled(_df.columnCount, null));
    }

    for (int colIdx = 0; colIdx < _df.columnCount; colIdx++) {
      var colName = _df.columns[colIdx];
      List<dynamic> values = _df[colName].toList();

      // Check if column is numeric
      if (values.any((v) => v is num)) {
        List<num?> numericValues = <num?>[];
        for (var v in values) {
          numericValues.add(v is num ? v : null);
        }
        var expandingValues = operation(numericValues);

        for (int rowIdx = 0; rowIdx < expandingValues.length; rowIdx++) {
          resultData[rowIdx][colIdx] = expandingValues[rowIdx];
        }
      } else {
        // Non-numeric columns remain null
        for (int rowIdx = 0; rowIdx < _df.rowCount; rowIdx++) {
          resultData[rowIdx][colIdx] = null;
        }
      }
    }

    return DataFrame(resultData,
        columns: _df.columns.cast<String>(), index: _df.index);
  }

  /// Calculate expanding mean.
  List<double?> _expandingMean(List<num?> values) {
    List<double?> result = [];
    double sum = 0.0;
    int count = 0;

    for (var value in values) {
      if (value != null) {
        sum += value;
        count++;
      }

      if (count >= _minPeriods) {
        result.add(sum / count);
      } else {
        result.add(null);
      }
    }

    return result;
  }

  /// Calculate expanding sum.
  List<double?> _expandingSum(List<num?> values) {
    List<double?> result = [];
    double sum = 0.0;
    int count = 0;

    for (var value in values) {
      if (value != null) {
        sum += value;
        count++;
      }

      if (count >= _minPeriods) {
        result.add(sum);
      } else {
        result.add(null);
      }
    }

    return result;
  }

  /// Calculate expanding standard deviation.
  List<double?> _expandingStd(List<num?> values) {
    List<double?> result = [];
    List<double> validValues = [];

    for (var value in values) {
      if (value != null) {
        validValues.add(value.toDouble());
      }

      if (validValues.length >= _minPeriods) {
        double mean = validValues.reduce((a, b) => a + b) / validValues.length;
        double variance = validValues
                .map((v) => (v - mean) * (v - mean))
                .reduce((a, b) => a + b) /
            validValues.length;
        result.add(sqrt(variance));
      } else {
        result.add(null);
      }
    }

    return result;
  }

  /// Calculate expanding minimum.
  List<double?> _expandingMin(List<num?> values) {
    List<double?> result = [];
    double? currentMin;
    int count = 0;

    for (var value in values) {
      if (value != null) {
        count++;
        if (currentMin == null || value < currentMin) {
          currentMin = value.toDouble();
        }
      }

      if (count >= _minPeriods) {
        result.add(currentMin);
      } else {
        result.add(null);
      }
    }

    return result;
  }

  /// Calculate expanding maximum.
  List<double?> _expandingMax(List<num?> values) {
    List<double?> result = [];
    double? currentMax;
    int count = 0;

    for (var value in values) {
      if (value != null) {
        count++;
        if (currentMax == null || value > currentMax) {
          currentMax = value.toDouble();
        }
      }

      if (count >= _minPeriods) {
        result.add(currentMax);
      } else {
        result.add(null);
      }
    }

    return result;
  }
}

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

/// Extension to add window function methods to DataFrame.
extension DataFrameWindowFunctions on DataFrame {
  /// Create an exponentially weighted window.
  ///
  /// Parameters:
  /// - `alpha`: Smoothing factor (0 < alpha <= 1)
  /// - `span`: Specify decay in terms of span (span >= 1)
  /// - `halflife`: Specify decay in terms of half-life
  /// - `com`: Specify decay in terms of center of mass (com >= 0)
  /// - `adjustWeights`: Divide by decaying adjustment factor (default: true)
  /// - `ignoreNA`: Ignore missing values when calculating weights (default: false)
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50],
  /// });
  ///
  /// var ewm = df.ewm(
  ///   span: 3,
  ///   adjustWeights: true,
  ///   ignoreNA: true,
  /// );
  /// var mean = ewm.mean();
  /// ```
  ExponentialWeightedWindow ewm({
    double? alpha,
    int? span,
    double? halflife,
    double? com,
    bool adjustWeights = true,
    bool ignoreNA = false,
  }) {
    return ExponentialWeightedWindow(
      this,
      alpha: alpha,
      span: span,
      halflife: halflife,
      com: com,
      adjustWeights: adjustWeights,
      ignoreNA: ignoreNA,
    );
  }

  /// Create an expanding window.
  ///
  /// Parameters:
  /// - `minPeriods`: Minimum number of observations required (default: 1)
  ///
  /// Example:
  /// ```dart
  /// var expanding = df.expanding(minPeriods: 2);
  /// var expandingMean = expanding.mean();
  /// ```
  ExpandingWindow expanding({int minPeriods = 1}) {
    return ExpandingWindow(this, minPeriods: minPeriods);
  }

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

  /// Compute numerical rank along columns with various tie-breaking methods (SQL-style window function).
  ///
  /// Similar to SQL's RANK() window function. This is an enhanced version that supports
  /// multiple columns and additional ranking methods.
  ///
  /// Parameters:
  /// - `columns`: List of column names to rank. If null, ranks all numeric columns.
  /// - `method`: How to rank the group of records that have the same value:
  ///   - 'average': average rank of the group
  ///   - 'min': lowest rank in the group
  ///   - 'max': highest rank in the group
  ///   - 'first': ranks assigned in order they appear in the array
  ///   - 'dense': like 'min', but rank always increases by 1 between groups
  /// - `ascending`: Whether to rank in ascending order (true) or descending (false)
  /// - `pct`: Whether to return percentile ranks (0 to 1) instead of integer ranks
  ///
  /// Returns a new DataFrame with ranked values.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1.0, 100],
  ///   [2.0, 100],
  ///   [3.0, 200],
  ///   [4.0, 300],
  /// ], columns: ['A', 'B']);
  ///
  /// // Rank column B with average method
  /// var ranked = df.rankWindow(columns: ['B'], method: 'average');
  /// // Result: B column becomes [1.5, 1.5, 3.0, 4.0]
  ///
  /// // Dense rank
  /// var denseRanked = df.rankWindow(columns: ['B'], method: 'dense');
  /// // Result: B column becomes [1.0, 1.0, 2.0, 3.0]
  /// ```
  DataFrame rankWindow({
    List<String>? columns,
    String method = 'average',
    bool ascending = true,
    bool pct = false,
  }) {
    final validMethods = ['average', 'min', 'max', 'first', 'dense'];
    if (!validMethods.contains(method)) {
      throw ArgumentError(
          'Invalid method: $method. Must be one of $validMethods');
    }

    final columnsToRank = columns ?? this.columns;
    final newData = <String, List<dynamic>>{};

    // Copy all columns
    for (var col in this.columns) {
      newData[col] = this[col].toList();
    }

    // Rank specified columns
    for (var col in columnsToRank) {
      if (!this.columns.contains(col)) {
        throw ArgumentError('Column $col not found in DataFrame');
      }

      final values = this[col].toList();
      final ranks = _computeRanks(values, method, ascending);

      if (pct) {
        // Convert to percentile ranks (0 to 1)
        final maxRank = ranks.reduce((a, b) => a > b ? a : b);
        newData[col] = ranks.map((r) => r / maxRank).toList();
      } else {
        newData[col] = ranks;
      }
    }

    return DataFrame.fromMap(newData, index: index);
  }

  /// Compute dense rank - like rank with method='min' but rank always increases by 1.
  ///
  /// Similar to SQL's DENSE_RANK() window function.
  ///
  /// Parameters:
  /// - `columns`: List of column names to rank. If null, ranks all numeric columns.
  /// - `ascending`: Whether to rank in ascending order (true) or descending (false)
  ///
  /// Returns a new DataFrame with dense ranked values.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [100],
  ///   [100],
  ///   [200],
  ///   [300],
  /// ], columns: ['A']);
  ///
  /// var ranked = df.denseRank(columns: ['A']);
  /// // Result: [1, 1, 2, 3]
  /// ```
  DataFrame denseRank({
    List<String>? columns,
    bool ascending = true,
  }) {
    return rankWindow(columns: columns, method: 'dense', ascending: ascending);
  }

  /// Assign a unique sequential integer to each row, starting from 1.
  ///
  /// Similar to SQL's ROW_NUMBER() window function.
  ///
  /// Parameters:
  /// - `columnName`: Name of the new column to add with row numbers (default: 'row_number')
  ///
  /// Returns a new DataFrame with an additional row number column.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 100],
  ///   ['Bob', 200],
  ///   ['Charlie', 150],
  /// ], columns: ['Name', 'Score']);
  ///
  /// var numbered = df.rowNumber();
  /// // Adds 'row_number' column: [1, 2, 3]
  /// ```
  DataFrame rowNumber({String columnName = 'row_number'}) {
    final newData = <String, List<dynamic>>{};

    // Copy all existing columns
    for (var col in columns) {
      newData[col] = this[col].toList();
    }

    // Add row number column
    newData[columnName] = List.generate(rowCount, (i) => i + 1);

    return DataFrame.fromMap(newData, index: index);
  }

  /// Compute the relative rank (percentile) of each value in columns.
  ///
  /// Similar to SQL's PERCENT_RANK() window function.
  /// Formula: (rank - 1) / (n - 1) where n is the number of rows.
  ///
  /// Parameters:
  /// - `columns`: List of column names to compute percent rank. If null, uses all numeric columns.
  /// - `ascending`: Whether to rank in ascending order (true) or descending (false)
  ///
  /// Returns a new DataFrame with percent rank values (0 to 1).
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [100],
  ///   [200],
  ///   [300],
  ///   [400],
  /// ], columns: ['Score']);
  ///
  /// var pctRank = df.percentRank(columns: ['Score']);
  /// // Result: [0.0, 0.333, 0.667, 1.0]
  /// ```
  DataFrame percentRank({
    List<String>? columns,
    bool ascending = true,
  }) {
    final columnsToRank = columns ?? this.columns;
    final newData = <String, List<dynamic>>{};

    // Copy all columns
    for (var col in this.columns) {
      newData[col] = this[col].toList();
    }

    final n = rowCount;
    if (n <= 1) {
      // If only one row, percent rank is 0
      for (var col in columnsToRank) {
        newData[col] = List.filled(n, 0.0);
      }
      return DataFrame.fromMap(newData, index: index);
    }

    // Compute percent rank for specified columns
    for (var col in columnsToRank) {
      if (!this.columns.contains(col)) {
        throw ArgumentError('Column $col not found in DataFrame');
      }

      final values = this[col].toList();
      final ranks = _computeRanks(values, 'min', ascending);

      // Convert to percent rank: (rank - 1) / (n - 1)
      newData[col] = ranks.map((r) => (r - 1) / (n - 1)).toList();
    }

    return DataFrame.fromMap(newData, index: index);
  }

  /// Compute the cumulative distribution of values in columns.
  ///
  /// Similar to SQL's CUME_DIST() window function.
  /// Formula: (number of rows with value <= current value) / (total number of rows)
  ///
  /// Parameters:
  /// - `columns`: List of column names to compute cumulative distribution. If null, uses all numeric columns.
  /// - `ascending`: Whether to compute in ascending order (true) or descending (false)
  ///
  /// Returns a new DataFrame with cumulative distribution values (0 to 1).
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [100],
  ///   [200],
  ///   [200],
  ///   [300],
  /// ], columns: ['Score']);
  ///
  /// var cumeDist = df.cumulativeDistribution(columns: ['Score']);
  /// // Result: [0.25, 0.75, 0.75, 1.0]
  /// ```
  DataFrame cumulativeDistribution({
    List<String>? columns,
    bool ascending = true,
  }) {
    final columnsToCompute = columns ?? this.columns;
    final newData = <String, List<dynamic>>{};

    // Copy all columns
    for (var col in this.columns) {
      newData[col] = this[col].toList();
    }

    final n = rowCount;
    if (n == 0) {
      return DataFrame.fromMap(newData, index: index);
    }

    // Compute cumulative distribution for specified columns
    for (var col in columnsToCompute) {
      if (!this.columns.contains(col)) {
        throw ArgumentError('Column $col not found in DataFrame');
      }

      final values = this[col].toList();
      final cumeDist = <double>[];

      for (var i = 0; i < n; i++) {
        final currentValue = values[i];
        var count = 0;

        // Count how many values are <= current value (or >= for descending)
        for (var j = 0; j < n; j++) {
          final compareValue = values[j];
          if (_isMissing(currentValue) || _isMissing(compareValue)) {
            continue;
          }

          final current = _toDouble(currentValue);
          final compare = _toDouble(compareValue);

          if (ascending) {
            if (compare <= current) count++;
          } else {
            if (compare >= current) count++;
          }
        }

        cumeDist.add(count / n);
      }

      newData[col] = cumeDist;
    }

    return DataFrame.fromMap(newData, index: index);
  }

  /// Helper method to compute ranks for a list of values.
  List<double> _computeRanks(
      List<dynamic> values, String method, bool ascending) {
    final n = values.length;
    final ranks = List<double>.filled(n, 0.0);

    // Create list of (index, value) pairs
    final indexed = <MapEntry<int, dynamic>>[];
    for (var i = 0; i < n; i++) {
      indexed.add(MapEntry(i, values[i]));
    }

    // Sort by value
    indexed.sort((a, b) {
      final aVal = a.value;
      final bVal = b.value;

      // Handle missing values - put them at the end
      if (_isMissing(aVal) && _isMissing(bVal)) return 0;
      if (_isMissing(aVal)) return 1;
      if (_isMissing(bVal)) return -1;

      final aNum = _toDouble(aVal);
      final bNum = _toDouble(bVal);

      return ascending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
    });

    // Assign ranks based on method
    if (method == 'first') {
      // Ranks assigned in order they appear
      for (var i = 0; i < n; i++) {
        ranks[indexed[i].key] = (i + 1).toDouble();
      }
    } else if (method == 'dense') {
      // Dense ranking - no gaps in rank sequence
      var currentRank = 1.0;
      ranks[indexed[0].key] = currentRank;

      for (var i = 1; i < n; i++) {
        final prevVal = indexed[i - 1].value;
        final currVal = indexed[i].value;

        if (!_valuesEqual(prevVal, currVal)) {
          currentRank++;
        }
        ranks[indexed[i].key] = currentRank;
      }
    } else {
      // For 'average', 'min', 'max' methods
      var i = 0;
      while (i < n) {
        // Find group of equal values
        var j = i;
        while (j < n && _valuesEqual(indexed[i].value, indexed[j].value)) {
          j++;
        }

        // Assign rank to group
        double rankValue;
        if (method == 'average') {
          // Average rank of the group
          final sumRanks = (i + 1 + j).toDouble() * (j - i) / 2;
          rankValue = sumRanks / (j - i);
        } else if (method == 'min') {
          // Minimum rank in the group
          rankValue = (i + 1).toDouble();
        } else {
          // method == 'max'
          // Maximum rank in the group
          rankValue = j.toDouble();
        }

        // Assign rank to all members of the group
        for (var k = i; k < j; k++) {
          ranks[indexed[k].key] = rankValue;
        }

        i = j;
      }
    }

    return ranks;
  }

  /// Helper to check if two values are equal for ranking purposes.
  bool _valuesEqual(dynamic a, dynamic b) {
    if (_isMissing(a) && _isMissing(b)) return true;
    if (_isMissing(a) || _isMissing(b)) return false;

    final aNum = _toDouble(a);
    final bNum = _toDouble(b);

    return (aNum - bNum).abs() < 1e-10;
  }

  /// Helper to check if a value is missing.
  bool _isMissing(dynamic value) {
    return value == null ||
        value == '' ||
        (value is double && value.isNaN) ||
        value == replaceMissingValueWith;
  }

  /// Helper to convert value to double.
  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? double.nan;
    return double.nan;
  }
}
