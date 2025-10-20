part of 'series.dart';

/// Extension providing advanced statistical operations for Series.
///
/// This extension adds comprehensive statistical methods including descriptive
/// statistics, skewness, kurtosis, and rolling window operations to the
/// Series class, enhancing its analytical capabilities.
extension SeriesStatistics on Series {
  /// Calculates the median value of the Series.
  ///
  /// The median is the middle value in a sorted list of numbers. For Series
  /// with an even number of values, it returns the average of the two middle values.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The median value, or the missing value representation if no valid data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.median()); // 3.0
  ///
  /// var s2 = Series([1, 2, 3, 4], name: 'even');
  /// print(s2.median()); // 2.5
  /// ```
  dynamic median({bool skipna = true}) {
    List<dynamic> validData = [];

    for (dynamic value in data) {
      if (skipna && _isMissing(value)) {
        continue;
      }
      validData.add(value);
    }

    if (validData.isEmpty) {
      return _missingRepresentation;
    }

    // Filter numeric values only
    List<num> numericValues =
        validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return _missingRepresentation;
    }

    numericValues.sort();
    int length = numericValues.length;

    if (length % 2 == 0) {
      // Even number of elements - average of middle two
      return (numericValues[length ~/ 2 - 1] + numericValues[length ~/ 2]) /
          2.0;
    } else {
      // Odd number of elements - middle element
      return numericValues[length ~/ 2];
    }
  }

  /// Calculates the mode (most frequently occurring value) of the Series.
  ///
  /// Parameters:
  /// - `dropna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The mode value. If multiple modes exist, returns the first one encountered.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 2, 3, 3, 3], name: 'data');
  /// print(s.mode()); // 3
  /// ```
  dynamic mode({bool dropna = true}) {
    Map<dynamic, int> valueCounts = {};

    for (dynamic value in data) {
      if (dropna && _isMissing(value)) {
        continue;
      }
      valueCounts[value] = (valueCounts[value] ?? 0) + 1;
    }

    if (valueCounts.isEmpty) {
      return _missingRepresentation;
    }

    // Find the value with maximum count
    dynamic modeValue = _missingRepresentation;
    int maxCount = 0;

    valueCounts.forEach((value, count) {
      if (count > maxCount) {
        maxCount = count;
        modeValue = value;
      }
    });

    return modeValue;
  }

  /// Calculates the quantile of the Series with enhanced options.
  ///
  /// Parameters:
  /// - `q`: The quantile to compute (between 0 and 1).
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The quantile value, or the missing value representation if no valid data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.quantile(0.5)); // 3.0 (median)
  /// print(s.quantile(0.25)); // 2.0 (first quartile)
  /// ```
  dynamic quantile(double q, {bool skipna = true}) {
    if (q < 0 || q > 1) {
      throw ArgumentError('Quantile must be between 0 and 1');
    }

    List<dynamic> validData = [];

    for (dynamic value in data) {
      if (skipna && _isMissing(value)) {
        continue;
      }
      validData.add(value);
    }

    if (validData.isEmpty) {
      return _missingRepresentation;
    }

    // Filter numeric values only
    List<num> numericValues =
        validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return _missingRepresentation;
    }

    numericValues.sort();
    int length = numericValues.length;

    if (length == 1) {
      return numericValues[0];
    }

    double index = q * (length - 1);
    // Ensure index is within bounds for sortedData
    int lowerIndex = index.floor();
    int upperIndex = index.ceil();

    if (lowerIndex == upperIndex) {
      return numericValues[lowerIndex];
    } else {
      double weight = index - lowerIndex;
      return numericValues[lowerIndex] * (1 - weight) +
          numericValues[upperIndex] * weight;
    }
  }

  /// Calculates the standard deviation of the Series with advanced options.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  /// - `ddof`: Delta degrees of freedom (default 1 for sample standard deviation).
  ///
  /// Returns:
  /// The standard deviation value, or the missing value representation if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.std()); // Standard deviation
  /// ```
  double std({bool skipna = true, int ddof = 1}) {
    List<dynamic> validData = [];

    for (dynamic value in data) {
      if (skipna && _isMissing(value)) {
        continue;
      }
      validData.add(value);
    }

    if (validData.isEmpty) {
      return double.nan;
    }

    // Filter numeric values only
    List<num> numericValues =
        validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty || numericValues.length <= ddof) {
      return double.nan;
    }

    // Calculate mean
    double mean = numericValues.reduce((a, b) => a + b) / numericValues.length;

    // Calculate variance
    double sumSquaredDiffs = numericValues
        .map((value) => (value - mean) * (value - mean))
        .reduce((a, b) => a + b);

    double variance = sumSquaredDiffs / (numericValues.length - ddof);
    return sqrt(variance);
  }

  /// Calculates the variance of the Series.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  /// - `ddof`: Delta degrees of freedom (default 1 for sample variance).
  ///
  /// Returns:
  /// The variance value, or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.variance()); // Variance
  /// ```
  double variance({bool skipna = true, int ddof = 1}) {
    List<dynamic> validData = [];

    for (dynamic value in data) {
      if (skipna && _isMissing(value)) {
        continue;
      }
      validData.add(value);
    }

    if (validData.isEmpty) {
      return double.nan;
    }

    // Filter numeric values only
    List<num> numericValues =
        validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty || numericValues.length <= ddof) {
      return double.nan;
    }

    // Calculate mean
    double mean = numericValues.reduce((a, b) => a + b) / numericValues.length;

    // Calculate variance
    double sumSquaredDiffs = numericValues
        .map((value) => (value - mean) * (value - mean))
        .reduce((a, b) => a + b);

    return sumSquaredDiffs / (numericValues.length - ddof);
  }

  /// Calculates the skewness of the Series.
  ///
  /// Skewness measures the asymmetry of the probability distribution.
  /// - Positive skew: tail extends toward positive values
  /// - Negative skew: tail extends toward negative values
  /// - Zero skew: symmetric distribution
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The skewness value, or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.skew()); // Skewness value
  /// ```
  double skew({bool skipna = true}) {
    List<dynamic> validData = [];

    for (dynamic value in data) {
      if (skipna && _isMissing(value)) {
        continue;
      }
      validData.add(value);
    }

    if (validData.isEmpty) {
      return double.nan;
    }

    // Filter numeric values only
    List<num> numericValues =
        validData.whereType<num>().cast<num>().toList();

    if (numericValues.length < 3) {
      return double.nan;
    }

    // Calculate mean
    double mean = numericValues.reduce((a, b) => a + b) / numericValues.length;

    // Calculate standard deviation
    double sumSquaredDiffs = numericValues
        .map((value) => (value - mean) * (value - mean))
        .reduce((a, b) => a + b);

    double variance = sumSquaredDiffs / (numericValues.length - 1);
    double stdDev = sqrt(variance);

    if (stdDev == 0) {
      return double.nan;
    }

    // Calculate skewness using the third moment
    double sumCubedDiffs = numericValues
        .map((value) => pow((value - mean) / stdDev, 3).toDouble())
        .reduce((a, b) => a + b);

    int n = numericValues.length;
    return (n / ((n - 1) * (n - 2))) * sumCubedDiffs;
  }

  /// Calculates the kurtosis of the Series.
  ///
  /// Kurtosis measures the "tailedness" of the probability distribution.
  /// - High kurtosis: heavy tails, sharp peak
  /// - Low kurtosis: light tails, flat peak
  /// - Normal distribution has kurtosis of 3 (excess kurtosis of 0)
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  /// - `fisher`: If true (default), returns Fisher's definition (excess kurtosis).
  ///   If false, returns Pearson's definition.
  ///
  /// Returns:
  /// The kurtosis value, or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.kurtosis()); // Kurtosis value
  /// ```
  double kurtosis({bool skipna = true, bool fisher = true}) {
    List<dynamic> validData = [];

    for (dynamic value in data) {
      if (skipna && _isMissing(value)) {
        continue;
      }
      validData.add(value);
    }

    if (validData.isEmpty) {
      return double.nan;
    }

    // Filter numeric values only
    List<num> numericValues =
        validData.whereType<num>().cast<num>().toList();

    if (numericValues.length < 4) {
      return double.nan;
    }

    // Calculate mean
    double mean = numericValues.reduce((a, b) => a + b) / numericValues.length;

    // Calculate standard deviation
    double sumSquaredDiffs = numericValues
        .map((value) => (value - mean) * (value - mean))
        .reduce((a, b) => a + b);

    double variance = sumSquaredDiffs / (numericValues.length - 1);
    double stdDev = sqrt(variance);

    if (stdDev == 0) {
      return double.nan;
    }

    // Calculate kurtosis using the fourth moment
    double sumFourthPowers = numericValues
        .map((value) => pow((value - mean) / stdDev, 4).toDouble())
        .reduce((a, b) => a + b);

    int n = numericValues.length;
    double kurtosisValue =
        (n * (n + 1) / ((n - 1) * (n - 2) * (n - 3))) * sumFourthPowers;

    if (fisher) {
      // Fisher's definition (excess kurtosis) - subtract 3
      double correction = 3.0 * (n - 1) * (n - 1) / ((n - 2) * (n - 3));
      return kurtosisValue - correction;
    } else {
      // Pearson's definition
      return kurtosisValue;
    }
  }

  /// Creates a rolling window object for the Series.
  ///
  /// Rolling window operations allow you to perform calculations over a
  /// sliding window of data points.
  ///
  /// Parameters:
  /// - `window`: The size of the rolling window.
  ///
  /// Returns:
  /// A RollingSeries object that provides rolling statistical methods.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// var rolling = s.rolling(3);
  /// print(rolling.mean()); // Rolling mean with window size 3
  /// ```
  RollingSeries rolling(int window) {
    if (window <= 0) {
      throw ArgumentError('Window size must be positive');
    }
    if (window > length) {
      throw ArgumentError('Window size cannot be larger than Series length');
    }
    return RollingSeries(this, window);
  }
}

/// Class providing rolling window operations for Series.
///
/// This class is returned by the `rolling()` method and provides various
/// statistical operations that can be applied over a rolling window.
class RollingSeries {
  final Series _series;
  final int window;

  RollingSeries(this._series, this.window);

  /// Calculates the rolling mean.
  ///
  /// Returns:
  /// A new Series with rolling mean values. The first (window-1) values
  /// will be the missing value representation.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// var rollingMean = s.rolling(3).mean();
  /// print(rollingMean); // [null, null, 2.0, 3.0, 4.0]
  /// ```
  Series mean() {
    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData = [];
        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            windowData.add(value);
          }
        }

        if (windowData.isEmpty) {
          result.add(_series._missingRepresentation);
        } else {
          double mean = windowData.reduce((a, b) => a + b) / windowData.length;
          result.add(mean);
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_mean', index: _series.index.toList());
  }

  /// Calculates the rolling sum.
  ///
  /// Returns:
  /// A new Series with rolling sum values.
  Series sum() {
    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        num sum = 0;
        bool hasValidData = false;

        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            sum += value;
            hasValidData = true;
          }
        }

        result.add(hasValidData ? sum : _series._missingRepresentation);
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_sum', index: _series.index.toList());
  }

  /// Calculates the rolling standard deviation.
  ///
  /// Returns:
  /// A new Series with rolling standard deviation values.
  Series std() {
    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData = [];
        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            windowData.add(value);
          }
        }

        if (windowData.length < 2) {
          result.add(_series._missingRepresentation);
        } else {
          double mean = windowData.reduce((a, b) => a + b) / windowData.length;
          double sumSquaredDiffs = windowData
              .map((value) => (value - mean) * (value - mean))
              .reduce((a, b) => a + b);
          double variance = sumSquaredDiffs / (windowData.length - 1);
          result.add(sqrt(variance));
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_std', index: _series.index.toList());
  }

  /// Calculates the rolling minimum.
  ///
  /// Returns:
  /// A new Series with rolling minimum values.
  Series min() {
    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData = [];
        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            windowData.add(value);
          }
        }

        if (windowData.isEmpty) {
          result.add(_series._missingRepresentation);
        } else {
          result.add(windowData.reduce((a, b) => a < b ? a : b));
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_min', index: _series.index.toList());
  }

  /// Calculates the rolling maximum.
  ///
  /// Returns:
  /// A new Series with rolling maximum values.
  Series max() {
    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData = [];
        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            windowData.add(value);
          }
        }

        if (windowData.isEmpty) {
          result.add(_series._missingRepresentation);
        } else {
          result.add(windowData.reduce((a, b) => a > b ? a : b));
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_max', index: _series.index.toList());
  }

  /// Calculates the rolling variance.
  ///
  /// Returns:
  /// A new Series with rolling variance values.
  Series variance() {
    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData = [];
        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            windowData.add(value);
          }
        }

        if (windowData.length < 2) {
          result.add(_series._missingRepresentation);
        } else {
          double mean = windowData.reduce((a, b) => a + b) / windowData.length;
          double sumSquaredDiffs = windowData
              .map((value) => (value - mean) * (value - mean))
              .reduce((a, b) => a + b);
          double variance = sumSquaredDiffs / (windowData.length - 1);
          result.add(variance);
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_var', index: _series.index.toList());
  }

  /// Calculates the rolling median.
  ///
  /// Returns:
  /// A new Series with rolling median values.
  Series median() {
    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData = [];
        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            windowData.add(value);
          }
        }

        if (windowData.isEmpty) {
          result.add(_series._missingRepresentation);
        } else {
          List<num> sortedData = List.from(windowData)..sort();
          int length = sortedData.length;

          if (length % 2 == 0) {
            result.add(
                (sortedData[length ~/ 2 - 1] + sortedData[length ~/ 2]) / 2.0);
          } else {
            result.add(sortedData[length ~/ 2]);
          }
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_median', index: _series.index.toList());
  }

  /// Calculates the rolling quantile.
  ///
  /// Parameters:
  /// - `q`: The quantile to compute (between 0 and 1)
  ///
  /// Returns:
  /// A new Series with rolling quantile values.
  Series quantile(double q) {
    if (q < 0 || q > 1) {
      throw ArgumentError('Quantile must be between 0 and 1');
    }

    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData = [];
        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            windowData.add(value);
          }
        }

        if (windowData.isEmpty) {
          result.add(_series._missingRepresentation);
        } else {
          List<num> sortedData = List.from(windowData)..sort();
          int length = sortedData.length;

          if (length == 1) {
            result.add(sortedData[0]);
          } else {
            double index = q * (length - 1);
            int lowerIndex = index.floor();
            int upperIndex = index.ceil();

            if (lowerIndex == upperIndex) {
              result.add(sortedData[lowerIndex]);
            } else {
              double weight = index - lowerIndex;
              result.add(sortedData[lowerIndex] * (1 - weight) +
                  sortedData[upperIndex] * weight);
            }
          }
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_quantile_$q',
        index: _series.index.toList());
  }

  /// Calculates the rolling skewness.
  ///
  /// Returns:
  /// A new Series with rolling skewness values.
  Series skew() {
    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData = [];
        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            windowData.add(value);
          }
        }

        if (windowData.length < 3) {
          result.add(_series._missingRepresentation);
        } else {
          double mean = windowData.reduce((a, b) => a + b) / windowData.length;

          double sumSquaredDiffs = windowData
              .map((value) => (value - mean) * (value - mean))
              .reduce((a, b) => a + b);

          double variance = sumSquaredDiffs / (windowData.length - 1);
          double stdDev = sqrt(variance);

          if (stdDev == 0) {
            result.add(_series._missingRepresentation);
          } else {
            double sumCubedDiffs = windowData
                .map((value) => pow((value - mean) / stdDev, 3).toDouble())
                .reduce((a, b) => a + b);

            int n = windowData.length;
            double skewness = (n / ((n - 1) * (n - 2))) * sumCubedDiffs;
            result.add(skewness);
          }
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_skew', index: _series.index.toList());
  }

  /// Calculates the rolling kurtosis.
  ///
  /// Parameters:
  /// - `fisher`: If true (default), returns Fisher's definition (excess kurtosis).
  ///
  /// Returns:
  /// A new Series with rolling kurtosis values.
  Series kurt({bool fisher = true}) {
    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData = [];
        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            windowData.add(value);
          }
        }

        if (windowData.length < 4) {
          result.add(_series._missingRepresentation);
        } else {
          double mean = windowData.reduce((a, b) => a + b) / windowData.length;

          double sumSquaredDiffs = windowData
              .map((value) => (value - mean) * (value - mean))
              .reduce((a, b) => a + b);

          double variance = sumSquaredDiffs / (windowData.length - 1);
          double stdDev = sqrt(variance);

          if (stdDev == 0) {
            result.add(_series._missingRepresentation);
          } else {
            double sumFourthPowers = windowData
                .map((value) => pow((value - mean) / stdDev, 4).toDouble())
                .reduce((a, b) => a + b);

            int n = windowData.length;
            double kurtosisValue =
                (n * (n + 1) / ((n - 1) * (n - 2) * (n - 3))) * sumFourthPowers;

            if (fisher) {
              double correction = 3.0 * (n - 1) * (n - 1) / ((n - 2) * (n - 3));
              result.add(kurtosisValue - correction);
            } else {
              result.add(kurtosisValue);
            }
          }
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_kurt', index: _series.index.toList());
  }

  /// Calculates the rolling correlation with another Series.
  ///
  /// Parameters:
  /// - `other`: Another Series to calculate correlation with
  ///
  /// Returns:
  /// A new Series with rolling correlation values.
  Series corr(Series other) {
    if (_series.length != other.length) {
      throw ArgumentError('Series must have the same length');
    }

    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData1 = [];
        List<num> windowData2 = [];

        for (int j = i - window + 1; j <= i; j++) {
          dynamic value1 = _series.data[j];
          dynamic value2 = other.data[j];

          if (!_series._isMissing(value1) &&
              !other._isMissing(value2) &&
              value1 is num &&
              value2 is num) {
            windowData1.add(value1);
            windowData2.add(value2);
          }
        }

        if (windowData1.length < 2) {
          result.add(_series._missingRepresentation);
        } else {
          double correlation =
              _calculatePearsonCorrelation(windowData1, windowData2);
          result.add(correlation);
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_corr', index: _series.index.toList());
  }

  /// Calculates the rolling covariance with another Series.
  ///
  /// Parameters:
  /// - `other`: Another Series to calculate covariance with
  ///
  /// Returns:
  /// A new Series with rolling covariance values.
  Series cov(Series other) {
    if (_series.length != other.length) {
      throw ArgumentError('Series must have the same length');
    }

    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData1 = [];
        List<num> windowData2 = [];

        for (int j = i - window + 1; j <= i; j++) {
          dynamic value1 = _series.data[j];
          dynamic value2 = other.data[j];

          if (!_series._isMissing(value1) &&
              !other._isMissing(value2) &&
              value1 is num &&
              value2 is num) {
            windowData1.add(value1);
            windowData2.add(value2);
          }
        }

        if (windowData1.length < 2) {
          result.add(_series._missingRepresentation);
        } else {
          double covariance = _calculateCovariance(windowData1, windowData2);
          result.add(covariance);
        }
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_cov', index: _series.index.toList());
  }

  /// Applies a custom aggregation function over the rolling window.
  ///
  /// Parameters:
  /// - `func`: A function that takes a List<num> and returns a dynamic value
  ///
  /// Returns:
  /// A new Series with the results of applying the function to each window.
  Series apply(dynamic Function(List<num>) func) {
    List<dynamic> result = [];

    for (int i = 0; i < _series.length; i++) {
      if (i < window - 1) {
        result.add(_series._missingRepresentation);
      } else {
        List<num> windowData = [];
        for (int j = i - window + 1; j <= i; j++) {
          dynamic value = _series.data[j];
          if (!_series._isMissing(value) && value is num) {
            windowData.add(value);
          }
        }

        dynamic resultValue = func(windowData);
        result.add(resultValue);
      }
    }

    return Series(result,
        name: '${_series.name}_rolling_apply', index: _series.index.toList());
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
}
