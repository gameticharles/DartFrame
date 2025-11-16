part of 'series.dart';

extension SeriesAdditionalFunctions<T> on Series<T> {
  /// Calculate the cumulative sum of values in the series.
  ///
  /// Parameters:
  /// - `skipna`: Whether to exclude NA/null values. If an entire row/column is NA, the result will be NA.
  ///
  /// Returns:

  /// Find the index location of the maximum value in the series.
  ///
  /// Returns the index of the maximum value in the series.
  /// Throws if the series is empty or contains only missing values.
  int idxmax() {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;
    num? maxValue;
    int maxIndex = -1;

    for (int i = 0; i < data.length; i++) {
      final val = data[i];
      if (val != missingRep && val is num) {
        if (maxValue == null || val > maxValue) {
          maxValue = val;
          maxIndex = i;
        }
      }
    }

    if (maxIndex == -1) {
      throw Exception(
          "Cannot find idxmax of an empty series or series with all missing/non-numeric values.");
    }
    return maxIndex;
  }

  /// Find the index location of the minimum value in the series.
  ///
  /// Returns the index of the minimum value in the series.
  /// Throws if the series is empty or contains only missing values.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([5, 2, 8, 1, 9], name: 'values');
  /// print(s.idxmin()); // Output: 3 (index of value 1)
  /// ```
  int idxmin() {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;
    num? minValue;
    int minIndex = -1;

    for (int i = 0; i < data.length; i++) {
      final val = data[i];
      if (val != missingRep && val is num) {
        if (minValue == null || val < minValue) {
          minValue = val;
          minIndex = i;
        }
      }
    }

    if (minIndex == -1) {
      throw Exception(
          "Cannot find idxmin of an empty series or series with all missing/non-numeric values.");
    }
    return minIndex;
  }

  /// Returns the absolute value of each element in the series.
  ///
  /// For numeric values, returns the absolute value.
  /// For non-numeric values or missing values, returns the original value.
  ///
  /// Returns:
  /// A new Series with absolute values.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([-5, 3, -2, 0, 7], name: 'values');
  /// var abs_s = s.abs();
  /// print(abs_s.data); // Output: [5, 3, 2, 0, 7]
  /// ```
  Series abs() {
    final absData = data.map((value) {
      if (_isMissing(value)) {
        return value;
      }
      if (value is num) {
        return value.abs();
      }
      return value; // Non-numeric values remain unchanged
    }).toList();

    return Series(absData, name: '${name}_abs', index: index.toList());
  }

  /// Trim values at input thresholds.
  ///
  /// Assigns values outside boundary to boundary values. This is useful for
  /// limiting extreme values in your data.
  ///
  /// Parameters:
  /// - `lower`: Minimum threshold value. Values below this will be set to this value.
  /// - `upper`: Maximum threshold value. Values above this will be set to this value.
  ///
  /// At least one of `lower` or `upper` must be specified.
  ///
  /// Returns:
  /// A new Series with clipped values.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'values');
  ///
  /// // Clip values between 2 and 4
  /// var clipped = s.clip(lower: 2, upper: 4);
  /// print(clipped.data); // Output: [2, 2, 3, 4, 4]
  ///
  /// // Clip only lower bound
  /// var clippedLower = s.clip(lower: 3);
  /// print(clippedLower.data); // Output: [3, 3, 3, 4, 5]
  ///
  /// // Clip only upper bound
  /// var clippedUpper = s.clip(upper: 3);
  /// print(clippedUpper.data); // Output: [1, 2, 3, 3, 3]
  /// ```
  Series clip({num? lower, num? upper}) {
    if (lower == null && upper == null) {
      throw ArgumentError('Must specify at least one of lower or upper');
    }

    if (lower != null && upper != null && lower > upper) {
      throw ArgumentError('lower must be less than or equal to upper');
    }

    final clippedData = data.map((value) {
      if (_isMissing(value)) {
        return value;
      }

      if (value is num) {
        if (lower != null && value < lower) {
          return lower;
        } else if (upper != null && value > upper) {
          return upper;
        } else {
          return value;
        }
      }

      return value; // Non-numeric values remain unchanged
    }).toList();

    return Series(clippedData, name: '${name}_clipped', index: index.toList());
  }

  /// Calculate the percentage change between consecutive elements.
  ///
  /// Computes the percentage change from the immediately previous row by default.
  /// This is useful for comparing the change in a time series.
  ///
  /// Parameters:
  /// - `periods`: Periods to shift for calculating percent change (default: 1).
  /// - `fillMethod`: How to handle NAs before computing percent change.
  ///   - null (default): Don't fill NAs
  ///   - 'ffill' or 'pad': Forward fill
  ///   - 'bfill' or 'backfill': Backward fill
  ///
  /// Returns:
  /// A new Series with percentage changes.
  ///
  /// Formula: (current - previous) / previous
  ///
  /// Example:
  /// ```dart
  /// var s = Series([100, 110, 121, 133.1], name: 'price');
  /// var pct = s.pctChange();
  /// print(pct.data); // Output: [null, 0.1, 0.1, 0.1] (10% increase each time)
  ///
  /// var s2 = Series([90, 100, 110, 121], name: 'values');
  /// var pct2 = s2.pctChange(periods: 2);
  /// // Compares each value with the value 2 positions before
  /// ```
  Series pctChange({int periods = 1, String? fillMethod}) {
    if (periods <= 0) {
      throw ArgumentError('periods must be positive');
    }

    // Apply fill method if specified
    Series workingSeries = this;
    if (fillMethod != null) {
      if (fillMethod == 'ffill' || fillMethod == 'pad') {
        workingSeries = ffill();
      } else if (fillMethod == 'bfill' || fillMethod == 'backfill') {
        workingSeries = bfill();
      } else {
        throw ArgumentError(
            'fillMethod must be null, "ffill", "pad", "bfill", or "backfill"');
      }
    }

    final resultData = <dynamic>[];
    final missingRep = _missingRepresentation;

    for (int i = 0; i < workingSeries.data.length; i++) {
      if (i < periods) {
        // Not enough previous values
        resultData.add(missingRep);
        continue;
      }

      final current = workingSeries.data[i];
      final previous = workingSeries.data[i - periods];

      // Check if either value is missing
      if (_isMissing(current) || _isMissing(previous)) {
        resultData.add(missingRep);
        continue;
      }

      // Check if both are numeric
      if (current is num && previous is num) {
        if (previous == 0) {
          // Division by zero
          resultData.add(missingRep);
        } else {
          final pctChange = (current - previous) / previous;
          resultData.add(pctChange);
        }
      } else {
        // Non-numeric values
        resultData.add(missingRep);
      }
    }

    return Series(resultData,
        name: '${name}_pct_change', index: index.toList());
  }

  /// Calculate the first discrete difference of the series.
  ///
  /// Computes the difference between consecutive elements.
  ///
  /// Parameters:
  /// - `periods`: Periods to shift for calculating difference (default: 1).
  ///
  /// Returns:
  /// A new Series with differences.
  ///
  /// Formula: current - previous
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 3, 6, 10, 15], name: 'cumsum');
  /// var diff = s.diff();
  /// print(diff.data); // Output: [null, 2, 3, 4, 5]
  ///
  /// var diff2 = s.diff(periods: 2);
  /// print(diff2.data); // Output: [null, null, 5, 7, 9]
  /// ```
  Series diff({int periods = 1}) {
    if (periods <= 0) {
      throw ArgumentError('periods must be positive');
    }

    final resultData = <dynamic>[];
    final missingRep = _missingRepresentation;

    for (int i = 0; i < data.length; i++) {
      if (i < periods) {
        // Not enough previous values
        resultData.add(missingRep);
        continue;
      }

      final current = data[i];
      final previous = data[i - periods];

      // Check if either value is missing
      if (_isMissing(current) || _isMissing(previous)) {
        resultData.add(missingRep);
        continue;
      }

      // Check if both are numeric
      if (current is num && previous is num) {
        resultData.add(current - previous);
      } else {
        // Non-numeric values
        resultData.add(missingRep);
      }
    }

    return Series(resultData, name: '${name}_diff', index: index.toList());
  }

  /// Returns the n largest values from the Series.
  ///
  /// Parameters:
  /// - `n`: Number of values to return.
  /// - `keep`: When there are duplicate values:
  ///   - 'first' (default): Prioritize the first occurrence.
  ///   - 'last': Prioritize the last occurrence.
  ///   - 'all': Keep all ties (may return more than n values).
  ///
  /// Returns:
  /// A new Series with the n largest values, maintaining original indices.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([5, 2, 8, 1, 9, 3], name: 'values');
  /// var top3 = s.nlargest(3);
  /// print(top3.data); // Output: [9, 8, 5]
  /// print(top3.index); // Output: [4, 2, 0] (original indices)
  /// ```
  Series nlargest(int n, {String keep = 'first'}) {
    if (n <= 0) {
      return Series([], name: name, index: []);
    }

    // Create list of (index, value) pairs for numeric values only
    final indexedValues = <Map<String, dynamic>>[];
    for (int i = 0; i < data.length; i++) {
      final val = data[i];
      if (!_isMissing(val) && val is num) {
        indexedValues.add({'idx': i, 'val': val, 'origIdx': index[i]});
      }
    }

    // Sort in descending order
    indexedValues.sort((a, b) {
      final cmp = (b['val'] as num).compareTo(a['val'] as num);
      if (cmp != 0) return cmp;

      // Handle ties based on keep parameter
      if (keep == 'first') {
        return (a['idx'] as int).compareTo(b['idx'] as int);
      } else if (keep == 'last') {
        return (b['idx'] as int).compareTo(a['idx'] as int);
      }
      return 0;
    });

    // Take top n
    final resultCount =
        keep == 'all' ? indexedValues.length : min(n, indexedValues.length);
    final resultData = <dynamic>[];
    final resultIndex = <dynamic>[];

    for (int i = 0; i < resultCount; i++) {
      if (keep != 'all' && i >= n) break;
      resultData.add(indexedValues[i]['val']);
      resultIndex.add(indexedValues[i]['origIdx']);
    }

    return Series(resultData, name: name, index: resultIndex);
  }

  /// Returns the n smallest values from the Series.
  ///
  /// Parameters:
  /// - `n`: Number of values to return.
  /// - `keep`: When there are duplicate values:
  ///   - 'first' (default): Prioritize the first occurrence.
  ///   - 'last': Prioritize the last occurrence.
  ///   - 'all': Keep all ties (may return more than n values).
  ///
  /// Returns:
  /// A new Series with the n smallest values, maintaining original indices.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([5, 2, 8, 1, 9, 3], name: 'values');
  /// var bottom3 = s.nsmallest(3);
  /// print(bottom3.data); // Output: [1, 2, 3]
  /// print(bottom3.index); // Output: [3, 1, 5] (original indices)
  /// ```
  Series nsmallest(int n, {String keep = 'first'}) {
    if (n <= 0) {
      return Series([], name: name, index: []);
    }

    // Create list of (index, value) pairs for numeric values only
    final indexedValues = <Map<String, dynamic>>[];
    for (int i = 0; i < data.length; i++) {
      final val = data[i];
      if (!_isMissing(val) && val is num) {
        indexedValues.add({'idx': i, 'val': val, 'origIdx': index[i]});
      }
    }

    // Sort in ascending order
    indexedValues.sort((a, b) {
      final cmp = (a['val'] as num).compareTo(b['val'] as num);
      if (cmp != 0) return cmp;

      // Handle ties based on keep parameter
      if (keep == 'first') {
        return (a['idx'] as int).compareTo(b['idx'] as int);
      } else if (keep == 'last') {
        return (b['idx'] as int).compareTo(a['idx'] as int);
      }
      return 0;
    });

    // Take top n
    final resultCount =
        keep == 'all' ? indexedValues.length : min(n, indexedValues.length);
    final resultData = <dynamic>[];
    final resultIndex = <dynamic>[];

    for (int i = 0; i < resultCount; i++) {
      if (keep != 'all' && i >= n) break;
      resultData.add(indexedValues[i]['val']);
      resultIndex.add(indexedValues[i]['origIdx']);
    }

    return Series(resultData, name: name, index: resultIndex);
  }
}
