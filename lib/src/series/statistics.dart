part of 'series.dart';

/// Extension providing advanced statistical operations for Series.
///
/// This extension adds comprehensive statistical methods including descriptive
/// statistics, skewness, kurtosis, and rolling window operations to the
/// Series class, enhancing its analytical capabilities.
extension SeriesStatistics on Series {
  /// Count of non-null values in the Series.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from count.
  ///
  /// Returns:
  /// The number of non-missing values in the Series.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, null, 4, 5], name: 'data');
  /// print(s.count()); // 4
  /// ```
  int count({bool skipna = true}) {
    if (!skipna) {
      return data.length;
    }

    int count = 0;
    for (dynamic value in data) {
      if (!_isMissing(value)) {
        count++;
      }
    }
    return count;
  }

  /// Calculates the mean (average) of the Series.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The mean value, or NaN if no valid numeric data exists.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.mean()); // 3.0
  /// ```
  double mean({bool skipna = true}) {
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
    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return double.nan;
    }

    double sum = numericValues.reduce((a, b) => a + b).toDouble();
    return sum / numericValues.length;
  }

  /// Calculates the minimum value of the Series.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The minimum value, or the missing value representation if no valid data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.min()); // 1
  /// ```
  dynamic min({bool skipna = true}) {
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
    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return _missingRepresentation;
    }

    return numericValues.reduce((a, b) => a < b ? a : b);
  }

  /// Calculates the maximum value of the Series.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The maximum value, or the missing value representation if no valid data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.max()); // 5
  /// ```
  dynamic max({bool skipna = true}) {
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
    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return _missingRepresentation;
    }

    return numericValues.reduce((a, b) => a > b ? a : b);
  }

  /// Calculates the sum of values in the Series.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The sum of all values, or the missing value representation if no valid data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.sum()); // 15
  /// ```
  dynamic sum({bool skipna = true}) {
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
    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return _missingRepresentation;
    }

    return numericValues.reduce((a, b) => a + b);
  }

  /// Return cumulative maximum over the Series.
  ///
  /// Parameters:
  /// - `skipna`: Whether to exclude NA/null values. If an entire row/column is NA, the result will be NA.
  ///
  /// Returns:
  /// A new Series containing the cumulative maximum.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 3, 2, 5, 4], name: 'numbers');
  /// var cummax_s = s.cummax();
  /// print(cummax_s); // Output: numbers (Cumulative Max): [1, 3, 3, 5, 5]
  /// ```
  Series cummax({bool skipna = true}) {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;
    if (data.isEmpty) return Series([], name: "$name (Cumulative Max)");

    List<dynamic> result = List<dynamic>.filled(data.length, missingRep);
    num? currentMax;

    if (skipna) {
      for (int i = 0; i < data.length; i++) {
        final val = data[i];
        if (val != missingRep && val is num) {
          if (currentMax == null || val > currentMax) {
            currentMax = val;
          }
          result[i] = currentMax;
        } else if (val == missingRep) {
          result[i] = missingRep;
        } else {
          result[i] = missingRep;
        }
      }
    } else {
      bool encounteredMissing = false;
      for (int i = 0; i < data.length; i++) {
        final val = data[i];
        if (encounteredMissing) {
          result[i] = missingRep;
          continue;
        }
        if (val == missingRep) {
          result[i] = missingRep;
          encounteredMissing = true;
        } else if (val is num) {
          if (currentMax == null || val > currentMax) {
            currentMax = val;
          }
          result[i] = currentMax;
        } else {
          result[i] = missingRep;
          encounteredMissing = true;
        }
      }
    }
    return Series(result, name: "$name (Cumulative Max)");
  }

  /// Return cumulative minimum over the Series.
  ///
  /// Parameters:
  /// - `skipna`: Whether to exclude NA/null values. If an entire row/column is NA, the result will be NA.
  ///
  /// Returns:
  /// A new Series containing the cumulative minimum.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([5, 3, 2, 5, 4], name: 'numbers');
  /// var cummin_s = s.cummin();
  /// print(cummin_s); // Output: numbers (Cumulative Min): [5, 3, 2, 2, 2]
  /// ```
  Series cummin({bool skipna = true}) {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;
    if (data.isEmpty) return Series([], name: "$name (Cumulative Min)");

    List<dynamic> result = List<dynamic>.filled(data.length, missingRep);
    num? currentMin;

    if (skipna) {
      for (int i = 0; i < data.length; i++) {
        final val = data[i];
        if (val != missingRep && val is num) {
          if (currentMin == null || val < currentMin) {
            currentMin = val;
          }
          result[i] = currentMin;
        } else if (val == missingRep) {
          result[i] = missingRep;
        } else {
          result[i] = missingRep;
        }
      }
    } else {
      bool encounteredMissing = false;
      for (int i = 0; i < data.length; i++) {
        final val = data[i];
        if (encounteredMissing) {
          result[i] = missingRep;
          continue;
        }
        if (val == missingRep) {
          result[i] = missingRep;
          encounteredMissing = true;
        } else if (val is num) {
          if (currentMin == null || val < currentMin) {
            currentMin = val;
          }
          result[i] = currentMin;
        } else {
          result[i] = missingRep;
          encounteredMissing = true;
        }
      }
    }
    return Series(result, name: "$name (Cumulative Min)");
  }

  /// Return cumulative product over the Series.
  ///
  /// Parameters:
  /// - `skipna`: Whether to exclude NA/null values. If an entire row/column is NA, the result will be NA.
  ///
  /// Returns:
  /// A new Series containing the cumulative product.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4], name: 'numbers');
  /// var cumprod_s = s.cumprod();
  /// print(cumprod_s); // Output: numbers (Cumulative Product): [1, 2, 6, 24]
  /// ```
  Series cumprod({bool skipna = true}) {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;
    if (data.isEmpty) return Series([], name: "$name (Cumulative Product)");

    List<dynamic> result = List<dynamic>.filled(data.length, missingRep);
    num? currentProd;

    if (skipna) {
      for (int i = 0; i < data.length; i++) {
        final val = data[i];
        if (val != missingRep && val is num) {
          if (currentProd == null) {
            currentProd = val;
          } else {
            currentProd = currentProd * val;
          }
          result[i] = currentProd;
        } else if (val == missingRep) {
          result[i] = missingRep;
        } else {
          result[i] = missingRep;
        }
      }
    } else {
      bool encounteredMissing = false;
      for (int i = 0; i < data.length; i++) {
        final val = data[i];
        if (encounteredMissing) {
          result[i] = missingRep;
          continue;
        }
        if (val == missingRep) {
          result[i] = missingRep;
          encounteredMissing = true;
        } else if (val is num) {
          if (currentProd == null) {
            currentProd = val;
          } else {
            currentProd = currentProd * val;
          }
          result[i] = currentProd;
        } else {
          result[i] = missingRep;
          encounteredMissing = true;
        }
      }
    }
    return Series(result, name: "$name (Cumulative Product)");
  }

  /// Returns a new Series with the absolute value of each element.
  ///
  /// This method applies the absolute value function to each numeric element
  /// in the series. Non-numeric elements will cause an exception.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([-1, 2, -3, 4], name: 'numbers');
  /// var abs_s = s.abs();
  /// print(abs_s); // Output: numbers (Absolute): [1, 2, 3, 4]
  /// ```
  Series abs() {
    if (data.isEmpty) {
      return Series([], name: "$name (Absolute)");
    }

    List<dynamic> absValues = [];
    for (var value in data) {
      if (value is num) {
        absValues.add(value.abs());
      } else {
        throw Exception(
            "Cannot calculate absolute value of non-numeric data: $value");
      }
    }

    return Series(absValues, name: "$name (Absolute)");
  }

  /// Calculate the product of values in the series.
  ///
  /// Returns the product of all values in the series.
  num prod() {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;
    final numericData = data
        .whereType<num>()
        .where((element) => element != missingRep)
        .toList();
    if (numericData.isEmpty) {
      return 1; // Product of empty set is 1
    }
    return numericData.reduce((value, element) => value * element);
  }

  /// Generates descriptive statistics for the Series.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculations.
  ///
  /// Returns:
  /// A Map containing various statistical measures.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.describe()); // {count: 5, mean: 3.0, std: 1.58, min: 1, ...}
  /// ```
  Map<String, dynamic> describe({bool skipna = true}) {
    if (data.isEmpty) {
      return {
        'count': 0,
        'mean': double.nan,
        'std': double.nan,
        'min': _missingRepresentation,
        '25%': _missingRepresentation,
        '50%': _missingRepresentation,
        '75%': _missingRepresentation,
        'max': _missingRepresentation,
      };
    }

    return {
      'count': count(skipna: skipna),
      'mean': mean(skipna: skipna),
      'std': std(skipna: skipna),
      'min': min(skipna: skipna),
      '25%': quantile(0.25, skipna: skipna),
      '50%': quantile(0.50, skipna: skipna),
      '75%': quantile(0.75, skipna: skipna),
      'max': max(skipna: skipna),
    };
  }

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
    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

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
      throw Exception('Percentile must be between 0 and 1');
    }

    List<dynamic> validData = [];

    for (dynamic value in data) {
      if (skipna && _isMissing(value)) {
        continue;
      }
      validData.add(value);
    }

    if (validData.isEmpty) {
      throw Exception(
          'Cannot calculate quantile of an empty series or series with all missing values');
    }

    // Filter numeric values only
    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      throw Exception(
          'Cannot calculate quantile of an empty series or series with all missing values');
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
    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

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
    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

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
    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

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
    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

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

  /// Return cumulative sum over the Series.
  ///
  /// Parameters:
  /// - `skipna`: Whether to exclude NA/null values. If an entire row/column is NA, the result will be NA.
  ///
  /// Returns:
  /// A new Series containing the cumulative sum.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'numbers');
  /// var cumsum_s = s.cumsum();
  /// print(cumsum_s); // Output: numbers (Cumulative Sum): [1, 3, 6, 10, 15]
  /// ```
  Series cumsum({bool skipna = true}) {
    if (data.isEmpty) return Series([], name: "$name (Cumulative Sum)");

    List<dynamic> result = [];
    num? currentSum;

    if (skipna) {
      for (int i = 0; i < data.length; i++) {
        final val = data[i];
        if (!_isMissing(val) && val is num) {
          if (currentSum == null) {
            currentSum = val;
          } else {
            currentSum = currentSum + val;
          }
          result.add(currentSum);
        } else {
          result.add(_missingRepresentation);
        }
      }
    } else {
      bool encounteredMissing = false;
      for (int i = 0; i < data.length; i++) {
        final val = data[i];
        if (encounteredMissing) {
          result.add(_missingRepresentation);
          continue;
        }
        if (_isMissing(val)) {
          result.add(_missingRepresentation);
          encounteredMissing = true;
        } else if (val is num) {
          if (currentSum == null) {
            currentSum = val;
          } else {
            currentSum = currentSum + val;
          }
          result.add(currentSum);
        } else {
          result.add(_missingRepresentation);
          encounteredMissing = true;
        }
      }
    }
    return Series(result, name: "$name (Cumulative Sum)");
  }

  /// Count number of unique values in the Series.
  ///
  /// Parameters:
  /// - `dropna`: If true (default), excludes missing values from count.
  ///
  /// Returns:
  /// The number of unique values.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 2, 3, 3, 3], name: 'data');
  /// print(s.nunique()); // 3
  /// ```
  int nunique({bool dropna = true}) {
    Set<dynamic> uniqueValues = {};

    for (dynamic value in data) {
      if (dropna && _isMissing(value)) {
        continue;
      }
      uniqueValues.add(value);
    }

    return uniqueValues.length;
  }

  /// Return a Series containing counts of unique values.
  ///
  /// Parameters:
  /// - `normalize`: If true, return proportions instead of counts.
  /// - `sort`: If true, sort by frequency (descending).
  /// - `ascending`: If true and sort=true, sort in ascending order.
  /// - `dropna`: If true (default), exclude missing values.
  ///
  /// Returns:
  /// A new Series with unique values as index and their counts as values.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 2, 3, 3, 3], name: 'data');
  /// print(s.valueCounts()); // Series with counts
  /// ```
  Series valueCounts({
    bool normalize = false,
    bool sort = true,
    bool ascending = false,
    bool dropna = true,
  }) {
    Map<dynamic, int> counts = {};

    for (dynamic value in data) {
      if (dropna && _isMissing(value)) {
        continue;
      }
      counts[value] = (counts[value] ?? 0) + 1;
    }

    List<MapEntry<dynamic, int>> entries = counts.entries.toList();

    if (sort) {
      entries.sort((a, b) =>
          ascending ? a.value.compareTo(b.value) : b.value.compareTo(a.value));
    }

    List<dynamic> values = [];
    List<dynamic> indices = [];

    int total = counts.values.fold(0, (sum, count) => sum + count);

    for (var entry in entries) {
      indices.add(entry.key);
      if (normalize) {
        values.add(entry.value / total);
      } else {
        values.add(entry.value);
      }
    }

    return Series(values, name: name, index: indices);
  }

  /// Calculate percentile using 0-100 scale.
  ///
  /// Parameters:
  /// - `percentile`: The percentile to compute (between 0 and 100).
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The percentile value, or the missing value representation if no valid data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.percentile(50)); // 3.0 (median)
  /// print(s.percentile(25)); // 2.0 (first quartile)
  /// ```
  dynamic percentile(double percentile, {bool skipna = true}) {
    if (percentile < 0 || percentile > 100) {
      throw ArgumentError('Percentile must be between 0 and 100');
    }
    return quantile(percentile / 100.0, skipna: skipna);
  }

  /// Calculate the interquartile range (IQR).
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The IQR (Q3 - Q1), or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.iqr()); // 2.0 (Q3 - Q1)
  /// ```
  double iqr({bool skipna = true}) {
    var q1 = quantile(0.25, skipna: skipna);
    var q3 = quantile(0.75, skipna: skipna);

    if (q1 == _missingRepresentation || q3 == _missingRepresentation) {
      return double.nan;
    }

    if (q1 is num && q3 is num) {
      return (q3 - q1).toDouble();
    }

    return double.nan;
  }

  /// Calculate the standard error of the mean.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  /// - `ddof`: Delta degrees of freedom (default 1).
  ///
  /// Returns:
  /// The standard error of the mean, or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.sem()); // Standard error of mean
  /// ```
  double sem({bool skipna = true, int ddof = 1}) {
    var stdDev = std(skipna: skipna, ddof: ddof);
    var n = count(skipna: skipna);

    if (stdDev.isNaN || n <= 0) {
      return double.nan;
    }

    return stdDev / sqrt(n);
  }

  /// Calculate the mean absolute deviation.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The mean absolute deviation, or NaN if no valid data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.mad()); // Mean absolute deviation
  /// ```
  double mad({bool skipna = true}) {
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

    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return double.nan;
    }

    double meanValue =
        numericValues.reduce((a, b) => a + b) / numericValues.length;

    double sumAbsDeviations = numericValues
        .map((value) => (value - meanValue).abs())
        .reduce((a, b) => a + b);

    return sumAbsDeviations / numericValues.length;
  }

  /// Calculate the range (max - min).
  ///
  /// Parameters:
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The range, or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.range()); // 4.0 (5 - 1)
  /// ```
  double range({bool skipna = true}) {
    var minVal = min(skipna: skipna);
    var maxVal = max(skipna: skipna);

    if (minVal == _missingRepresentation || maxVal == _missingRepresentation) {
      return double.nan;
    }

    if (minVal is num && maxVal is num) {
      return (maxVal - minVal).toDouble();
    }

    return double.nan;
  }

  /// Calculate Pearson correlation coefficient with another Series.
  ///
  /// Parameters:
  /// - `other`: Another Series to calculate correlation with.
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The correlation coefficient, or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, 2, 3, 4, 5], name: 'x');
  /// var s2 = Series([2, 4, 6, 8, 10], name: 'y');
  /// print(s1.corr(s2)); // 1.0 (perfect positive correlation)
  /// ```
  double corr(Series other, {bool skipna = true}) {
    if (length != other.length) {
      throw ArgumentError('Series must have the same length');
    }

    List<num> validData1 = [];
    List<num> validData2 = [];

    for (int i = 0; i < length; i++) {
      dynamic value1 = data[i];
      dynamic value2 = other.data[i];

      if (skipna && (_isMissing(value1) || other._isMissing(value2))) {
        continue;
      }

      if (value1 is num && value2 is num) {
        validData1.add(value1);
        validData2.add(value2);
      }
    }

    if (validData1.length < 2) {
      return double.nan;
    }

    return _calculatePearsonCorrelation(validData1, validData2);
  }

  /// Calculate covariance with another Series.
  ///
  /// Parameters:
  /// - `other`: Another Series to calculate covariance with.
  /// - `skipna`: If true (default), excludes missing values from calculation.
  /// - `ddof`: Delta degrees of freedom (default 1).
  ///
  /// Returns:
  /// The covariance, or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, 2, 3, 4, 5], name: 'x');
  /// var s2 = Series([2, 4, 6, 8, 10], name: 'y');
  /// print(s1.cov(s2)); // Covariance value
  /// ```
  double cov(Series other, {bool skipna = true, int ddof = 1}) {
    if (length != other.length) {
      throw ArgumentError('Series must have the same length');
    }

    List<num> validData1 = [];
    List<num> validData2 = [];

    for (int i = 0; i < length; i++) {
      dynamic value1 = data[i];
      dynamic value2 = other.data[i];

      if (skipna && (_isMissing(value1) || other._isMissing(value2))) {
        continue;
      }

      if (value1 is num && value2 is num) {
        validData1.add(value1);
        validData2.add(value2);
      }
    }

    if (validData1.length <= ddof) {
      return double.nan;
    }

    return _calculateCovariance(validData1, validData2);
  }

  /// Calculate autocorrelation (correlation with lagged self).
  ///
  /// Parameters:
  /// - `lag`: The lag to use for autocorrelation (default 1).
  /// - `skipna`: If true (default), excludes missing values from calculation.
  ///
  /// Returns:
  /// The autocorrelation coefficient, or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// print(s.autocorr()); // Autocorrelation with lag 1
  /// ```
  double autocorr({int lag = 1, bool skipna = true}) {
    if (lag < 0) {
      throw ArgumentError('Lag must be non-negative');
    }

    if (lag >= length) {
      return double.nan;
    }

    List<num> originalData = [];
    List<num> laggedData = [];

    for (int i = lag; i < length; i++) {
      dynamic originalValue = data[i];
      dynamic laggedValue = data[i - lag];

      if (skipna && (_isMissing(originalValue) || _isMissing(laggedValue))) {
        continue;
      }

      if (originalValue is num && laggedValue is num) {
        originalData.add(originalValue);
        laggedData.add(laggedValue);
      }
    }

    if (originalData.length < 2) {
      return double.nan;
    }

    return _calculatePearsonCorrelation(originalData, laggedData);
  }

  /// Rank values in the Series.
  ///
  /// Parameters:
  /// - `method`: How to rank tied values ('average', 'min', 'max', 'first', 'dense').
  /// - `ascending`: If true (default), rank in ascending order.
  /// - `skipna`: If true (default), exclude missing values from ranking.
  ///
  /// Returns:
  /// A new Series with ranks.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([3, 1, 4, 1, 5], name: 'data');
  /// print(s.rank()); // Ranks: [3.0, 1.5, 4.0, 1.5, 5.0]
  /// ```
  Series rank({
    String method = 'average',
    bool ascending = true,
    bool skipna = true,
  }) {
    List<double> ranks = List.filled(length, double.nan);

    // Create list of (value, original_index) pairs for non-missing values
    List<MapEntry<num, int>> validEntries = [];

    for (int i = 0; i < length; i++) {
      dynamic value = data[i];
      if (!skipna || !_isMissing(value)) {
        if (value is num) {
          validEntries.add(MapEntry(value, i));
        }
      }
    }

    if (validEntries.isEmpty) {
      return Series(ranks, name: "$name (Ranked)");
    }

    // Sort by value
    validEntries.sort(
        (a, b) => ascending ? a.key.compareTo(b.key) : b.key.compareTo(a.key));

    // Assign ranks
    for (int i = 0; i < validEntries.length; i++) {
      int originalIndex = validEntries[i].value;

      if (method == 'first') {
        ranks[originalIndex] = (i + 1).toDouble();
      } else {
        // Find tied values
        num currentValue = validEntries[i].key;
        int tieStart = i;
        int tieEnd = i;

        while (tieEnd + 1 < validEntries.length &&
            validEntries[tieEnd + 1].key == currentValue) {
          tieEnd++;
        }

        double rankValue;
        switch (method) {
          case 'average':
            rankValue = (tieStart + tieEnd + 2) / 2.0;
            break;
          case 'min':
            rankValue = (tieStart + 1).toDouble();
            break;
          case 'max':
            rankValue = (tieEnd + 1).toDouble();
            break;
          case 'dense':
            // Count unique values up to this point
            Set<num> uniqueValues = {};
            for (int j = 0; j <= i; j++) {
              uniqueValues.add(validEntries[j].key);
            }
            rankValue = uniqueValues.length.toDouble();
            break;
          default:
            rankValue = (tieStart + tieEnd + 2) / 2.0;
        }

        // Assign rank to all tied values
        for (int j = tieStart; j <= tieEnd; j++) {
          ranks[validEntries[j].value] = rankValue;
        }

        i = tieEnd; // Skip to end of tied group
      }
    }

    return Series(ranks, name: "$name (Ranked)");
  }

  /// Calculate percentage change between consecutive values.
  ///
  /// Parameters:
  /// - `periods`: Number of periods to shift for calculating change (default 1).
  /// - `skipna`: If true (default), exclude missing values.
  ///
  /// Returns:
  /// A new Series with percentage changes.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([100, 110, 121, 133.1], name: 'data');
  /// print(s.pctChange()); // [NaN, 0.1, 0.1, 0.1] (10% increases)
  /// ```
  Series pctChange({int periods = 1, bool skipna = true}) {
    if (periods <= 0) {
      throw ArgumentError('Periods must be positive');
    }

    List<dynamic> result = List.filled(length, _missingRepresentation);

    for (int i = periods; i < length; i++) {
      dynamic currentValue = data[i];
      dynamic previousValue = data[i - periods];

      if (skipna && (_isMissing(currentValue) || _isMissing(previousValue))) {
        result[i] = _missingRepresentation;
        continue;
      }

      if (currentValue is num && previousValue is num) {
        if (previousValue == 0) {
          result[i] = double.infinity;
        } else {
          result[i] = (currentValue - previousValue) / previousValue;
        }
      } else {
        result[i] = _missingRepresentation;
      }
    }

    return Series(result, name: "$name (Pct Change)");
  }

  /// Calculate difference between consecutive values.
  ///
  /// Parameters:
  /// - `periods`: Number of periods to shift for calculating difference (default 1).
  /// - `skipna`: If true (default), exclude missing values.
  ///
  /// Returns:
  /// A new Series with differences.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 3, 6, 10, 15], name: 'data');
  /// print(s.diff()); // [NaN, 2, 3, 4, 5]
  /// ```
  Series diff({int periods = 1, bool skipna = true}) {
    if (periods <= 0) {
      throw ArgumentError('Periods must be positive');
    }

    List<dynamic> result = List.filled(length, _missingRepresentation);

    for (int i = periods; i < length; i++) {
      dynamic currentValue = data[i];
      dynamic previousValue = data[i - periods];

      if (skipna && (_isMissing(currentValue) || _isMissing(previousValue))) {
        result[i] = _missingRepresentation;
        continue;
      }

      if (currentValue is num && previousValue is num) {
        result[i] = currentValue - previousValue;
      } else {
        result[i] = _missingRepresentation;
      }
    }

    return Series(result, name: "$name (Diff)");
  }

  /// Calculate trimmed mean (mean after removing outliers).
  ///
  /// Parameters:
  /// - `proportiontocut`: Proportion of values to cut from each tail (0.0 to 0.5).
  /// - `skipna`: If true (default), exclude missing values.
  ///
  /// Returns:
  /// The trimmed mean, or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 100], name: 'data');
  /// print(s.trimmedMean(0.2)); // Mean after removing 20% from each tail
  /// ```
  double trimmedMean(double proportiontocut, {bool skipna = true}) {
    if (proportiontocut < 0 || proportiontocut >= 0.5) {
      throw ArgumentError('proportiontocut must be between 0 and 0.5');
    }

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

    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return double.nan;
    }

    numericValues.sort();

    int n = numericValues.length;
    int cutCount = (n * proportiontocut).floor();

    if (cutCount * 2 >= n) {
      return double.nan;
    }

    List<num> trimmedValues = numericValues.sublist(cutCount, n - cutCount);

    if (trimmedValues.isEmpty) {
      return double.nan;
    }

    return trimmedValues.reduce((a, b) => a + b) / trimmedValues.length;
  }

  /// Calculate Winsorized mean (mean after capping outliers).
  ///
  /// Parameters:
  /// - `limits`: Tuple of proportions to Winsorize from each tail (0.0 to 0.5).
  /// - `skipna`: If true (default), exclude missing values.
  ///
  /// Returns:
  /// The Winsorized mean, or NaN if insufficient data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 100], name: 'data');
  /// print(s.winsorizedMean(0.2)); // Mean after capping 20% from each tail
  /// ```
  double winsorizedMean(double limits, {bool skipna = true}) {
    if (limits < 0 || limits >= 0.5) {
      throw ArgumentError('limits must be between 0 and 0.5');
    }

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

    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return double.nan;
    }

    List<num> sortedValues = List.from(numericValues)..sort();

    int n = sortedValues.length;
    int cutCount = (n * limits).floor();

    if (cutCount >= n ~/ 2) {
      return double.nan;
    }

    // Winsorize by replacing extreme values with boundary values
    List<num> winsorizedValues = List.from(numericValues);
    num lowerBound = sortedValues[cutCount];
    num upperBound = sortedValues[n - 1 - cutCount];

    for (int i = 0; i < winsorizedValues.length; i++) {
      if (winsorizedValues[i] < lowerBound) {
        winsorizedValues[i] = lowerBound;
      } else if (winsorizedValues[i] > upperBound) {
        winsorizedValues[i] = upperBound;
      }
    }

    return winsorizedValues.reduce((a, b) => a + b) / winsorizedValues.length;
  }

  /// Calculate Shannon entropy.
  ///
  /// Parameters:
  /// - `base`: Base of logarithm (default e for natural log).
  /// - `skipna`: If true (default), exclude missing values.
  ///
  /// Returns:
  /// The entropy value, or NaN if no valid data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 1, 2, 2, 3, 3], name: 'data');
  /// print(s.entropy()); // Shannon entropy
  /// ```
  double entropy({double base = e, bool skipna = true}) {
    if (base <= 0 || base == 1) {
      throw ArgumentError('Base must be positive and not equal to 1');
    }

    Map<dynamic, int> counts = {};
    int total = 0;

    for (dynamic value in data) {
      if (skipna && _isMissing(value)) {
        continue;
      }
      counts[value] = (counts[value] ?? 0) + 1;
      total++;
    }

    if (total == 0) {
      return double.nan;
    }

    double entropy = 0.0;
    for (int count in counts.values) {
      double probability = count / total;
      if (probability > 0) {
        entropy -= probability * (log(probability) / log(base));
      }
    }

    return entropy;
  }

  /// Calculate geometric mean.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), exclude missing values.
  ///
  /// Returns:
  /// The geometric mean, or NaN if no valid positive data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 4, 8], name: 'data');
  /// print(s.geometricMean()); // 2.828... (4th root of 64)
  /// ```
  double geometricMean({bool skipna = true}) {
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

    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return double.nan;
    }

    // Check for non-positive values
    for (num value in numericValues) {
      if (value <= 0) {
        return double.nan;
      }
    }

    double logSum =
        numericValues.map((value) => log(value)).reduce((a, b) => a + b);
    return exp(logSum / numericValues.length);
  }

  /// Calculate harmonic mean.
  ///
  /// Parameters:
  /// - `skipna`: If true (default), exclude missing values.
  ///
  /// Returns:
  /// The harmonic mean, or NaN if no valid positive data.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 4], name: 'data');
  /// print(s.harmonicMean()); // 1.714... (3 / (1/1 + 1/2 + 1/4))
  /// ```
  double harmonicMean({bool skipna = true}) {
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

    List<num> numericValues = validData.whereType<num>().cast<num>().toList();

    if (numericValues.isEmpty) {
      return double.nan;
    }

    // Check for non-positive values
    for (num value in numericValues) {
      if (value <= 0) {
        return double.nan;
      }
    }

    double reciprocalSum =
        numericValues.map((value) => 1.0 / value).reduce((a, b) => a + b);
    return numericValues.length / reciprocalSum;
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
  /// - `func`: A function that takes a `List<num>` and returns a dynamic value
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
