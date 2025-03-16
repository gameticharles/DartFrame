part of '../../dartframe.dart';

extension SeriesFunctions on Series {
  /// Count of non-null values in the series.
  int count() {
    return data.where((element) => element != null).length;
  }

  /// Mean (average) of the values in the series.
  double mean() {
    if (data.isEmpty) {
      throw Exception("Cannot calculate mean of an empty series.");
    }
    var sum = data.whereType<num>().reduce((value, element) => value + element);
    return sum / data.length;
  }

  /// Standard deviation of the values in the series.
  double std() {
    if (data.isEmpty) {
      throw Exception(
          "Cannot calculate standard deviation of an empty series.");
    }
    var m = mean();
    var variance =
        data.map((x) => pow(x - m, 2)).reduce((a, b) => a + b) / data.length;
    return sqrt(variance);
  }

  /// Minimum value in the series.
  num min() {
    if (data.isEmpty) {
      throw Exception("Cannot find minimum value of an empty series.");
    }
    return data.reduce((a, b) => a < b ? a : b);
  }

  /// Maximum value in the series.
  num max() {
    if (data.isEmpty) {
      throw Exception("Cannot find maximum value of an empty series.");
    }
    return data.reduce((a, b) => a > b ? a : b);
  }

  /// Summary statistics of the series.
  Map<String, num> describe() {
    if (data.isEmpty) {
      throw Exception("Cannot describe an empty series.");
    }
    var statistics = {
      'count': count(),
      'mean': mean(),
      'std': std(),
      'min': min(),
      '25%': quantile(0.25),
      '50%': quantile(0.50),
      '75%': quantile(0.75),
      'max': max(),
    };
    return statistics;
  }

  /// Calculate the sum of values in the series.
  ///
  /// Returns the sum of all values in the series.
  num sum() {
    if (data.every((element) => element == num)) {
      // If T is numeric, perform addition
      return data.reduce((value, element) => value + element);
    } else {
      throw Exception("Sum operation is supported only for numeric types.");
    }
  }

  /// Calculate the product of values in the series.
  ///
  /// Returns the product of all values in the series.
  num prod() {
    if (data.every((element) => element == num)) {
      // If T is numeric, perform multiplication
      return data.reduce((value, element) => value * element);
    } else {
      throw Exception("Product operation is supported only for numeric types.");
    }
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
        throw Exception("Cannot calculate absolute value of non-numeric data: $value");
      }
    }
    
    return Series(absValues, name: "$name (Absolute)");
  }

  /// Creates a copy of the Series.
  ///
  /// Returns a new Series with the same data and name.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3], name: 'numbers');
  /// var s_copy = s.copy();
  /// ```
  Series copy() {
    return Series(List.from(data), name: name);
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
    if (data.isEmpty) {
      return Series([], name: "$name (Cumulative Max)");
    }
    
    List<dynamic> cumulativeMax = [];
    dynamic runningMax;
    
    // Find first non-null value if skipna is true
    int startIdx = 0;
    if (skipna) {
      while (startIdx < data.length && data[startIdx] == null) {
        startIdx++;
      }
      
      if (startIdx >= data.length) {
        // All values are null
        return Series(List.filled(data.length, null), name: "$name (Cumulative Max)");
      }
    }
    
    runningMax = data[startIdx];
    
    for (int i = 0; i < data.length; i++) {
      if (i < startIdx) {
        // Add null for skipped values at the beginning
        cumulativeMax.add(null);
        continue;
      }
      
      var currentValue = data[i];
      
      if (currentValue == null) {
        if (skipna) {
          // Keep previous max if skipping nulls
          cumulativeMax.add(runningMax);
        } else {
          // Result is null if not skipping nulls
          cumulativeMax.add(null);
          runningMax = null;
        }
      } else {
        if (runningMax == null || currentValue > runningMax) {
          runningMax = currentValue;
        }
        cumulativeMax.add(runningMax);
      }
    }
    
    return Series(cumulativeMax, name: "$name (Cumulative Max)");
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
    if (data.isEmpty) {
      return Series([], name: "$name (Cumulative Min)");
    }
    
    List<dynamic> cumulativeMin = [];
    dynamic runningMin;
    
    // Find first non-null value if skipna is true
    int startIdx = 0;
    if (skipna) {
      while (startIdx < data.length && data[startIdx] == null) {
        startIdx++;
      }
      
      if (startIdx >= data.length) {
        // All values are null
        return Series(List.filled(data.length, null), name: "$name (Cumulative Min)");
      }
    }
    
    runningMin = data[startIdx];
    
    for (int i = 0; i < data.length; i++) {
      if (i < startIdx) {
        // Add null for skipped values at the beginning
        cumulativeMin.add(null);
        continue;
      }
      
      var currentValue = data[i];
      
      if (currentValue == null) {
        if (skipna) {
          // Keep previous min if skipping nulls
          cumulativeMin.add(runningMin);
        } else {
          // Result is null if not skipping nulls
          cumulativeMin.add(null);
          runningMin = null;
        }
      } else {
        if (runningMin == null || currentValue < runningMin) {
          runningMin = currentValue;
        }
        cumulativeMin.add(runningMin);
      }
    }
    
    return Series(cumulativeMin, name: "$name (Cumulative Min)");
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
    if (data.isEmpty) {
      return Series([], name: "$name (Cumulative Product)");
    }
    
    List<dynamic> cumulativeProduct = [];
    dynamic runningProduct;
    
    // Find first non-null value if skipna is true
    int startIdx = 0;
    if (skipna) {
      while (startIdx < data.length && data[startIdx] == null) {
        startIdx++;
      }
      
      if (startIdx >= data.length) {
        // All values are null
        return Series(List.filled(data.length, null), name: "$name (Cumulative Product)");
      }
    }
    
    runningProduct = data[startIdx];
    
    for (int i = 0; i < data.length; i++) {
      if (i < startIdx) {
        // Add null for skipped values at the beginning
        cumulativeProduct.add(null);
        continue;
      }
      
      var currentValue = data[i];
      
      if (currentValue == null) {
        if (skipna) {
          // Keep previous product if skipping nulls
          cumulativeProduct.add(runningProduct);
        } else {
          // Result is null if not skipping nulls
          cumulativeProduct.add(null);
          runningProduct = null;
        }
      } else {
        if (runningProduct == null) {
          runningProduct = currentValue;
        } else {
          runningProduct *= currentValue;
        }
        cumulativeProduct.add(runningProduct);
      }
    }
    
    return Series(cumulativeProduct, name: "$name (Cumulative Product)");
  }

  /// Concatenates two Series along the axis specified by 'axis'.
  ///
  /// Parameters:
  /// - name: new name of the series
  /// - other: Another Series object to concatenate with this Series.
  /// - axis (Optional): The axis along which to concatenate.
  ///   * 0 (default): Vertical concatenation (one under the other)
  ///   * 1: Horizontal concatenation (side by side, requires same index/names)
  Series concatenate(Series other, {dynamic name, int axis = 0}) {
    switch (axis) {
      case 0: // Vertical concatenation
        List<dynamic> concatenatedData = List.from(data)..addAll(other.data);
        return Series(concatenatedData,
            name: name ?? "${this.name} - ${other.name}");

      case 1: // Horizontal concatenation (requires compatible structure)
        if (length != other.length) {
          throw Exception(
              'Series must have the same length for horizontal concatenation.');
        }
        // Assuming the 'name' is suitable for the newly joined Series
        return Series(data + other.data,
            name: name ?? "${this.name} - ${other.name}");

      default:
        throw Exception(
            'Invalid axis. Supported axes are 0 (vertical) or 1 (horizontal).');
    }
  }

    /// Calculate the cumulative sum of values in the series.
  ///
  /// Parameters:
  /// - `skipna`: Whether to exclude NA/null values. If an entire row/column is NA, the result will be NA.
  ///
  /// Returns:
  /// A new series containing the cumulative sum of values.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4], name: 'numbers');
  /// var cumsum_s = s.cumsum();
  /// print(cumsum_s); // Output: numbers (Cumulative Sum): [1, 3, 6, 10]
  /// ```
  Series cumsum({bool skipna = true}) {
    if (data.isEmpty) {
      return Series([], name: "$name (Cumulative Sum)");
    }
    
    List<dynamic> cumulativeSum = [];
    dynamic runningSum;
    
    // Find first non-null value if skipna is true
    int startIdx = 0;
    if (skipna) {
      while (startIdx < data.length && data[startIdx] == null) {
        startIdx++;
      }
      
      if (startIdx >= data.length) {
        // All values are null
        return Series(List.filled(data.length, null), name: "$name (Cumulative Sum)");
      }
    }
    
    runningSum = data[startIdx];
    
    for (int i = 0; i < data.length; i++) {
      if (i < startIdx) {
        // Add null for skipped values at the beginning
        cumulativeSum.add(null);
        continue;
      }
      
      var currentValue = data[i];
      
      if (currentValue == null) {
        if (skipna) {
          // Keep previous sum if skipping nulls
          cumulativeSum.add(runningSum);
        } else {
          // Result is null if not skipping nulls
          cumulativeSum.add(null);
          runningSum = null;
        }
      } else {
        if (runningSum == null) {
          runningSum = currentValue;
        } else {
          runningSum += currentValue;
        }
        cumulativeSum.add(runningSum);
      }
    }
    
    return Series(cumulativeSum, name: "$name (Cumulative Sum)");
  }

  /// Find the index location of the maximum value in the series.
  ///
  /// Returns the index of the maximum value in the series.
  int idxmax() {
    num maxValue =
        data.reduce((value, element) => value > element ? value : element);
    return data.indexOf(maxValue);
  }

  /// Quantile (percentile) of the series.
  num quantile(double percentile) {
    if (data.isEmpty) {
      throw Exception("Cannot calculate quantile of an empty series.");
    }
    if (percentile < 0 || percentile > 1) {
      throw Exception("Percentile must be between 0 and 1.");
    }
    var sortedData = List<num>.from(data)..sort();
    var index = (sortedData.length - 1) * percentile;
    var lower = sortedData[index.floor()];
    var upper = sortedData[index.ceil()];
    return lower + (upper - lower) * (index - index.floor());
  }

  /// Applies a function to each element of the series.
  ///
  /// This method allows you to transform or modify the values in a series
  /// using a custom function.
  ///
  /// Parameters:
  /// - `func`: The function to apply to each element. It should take a single
  ///   argument of the same type as the elements in the series and return a
  ///   value of potentially different type.
  ///
  /// Returns:
  /// A new series containing the results of applying `func` to each element
  /// of the original series.
  ///
  /// Example:
  /// ```dart
  /// Series numbers = Series([1, 2, 3, 4], name: 'numbers');
  ///
  /// // Square each element
  /// Series squared_numbers = numbers.apply((number) => number * number);
  /// print(squared_numbers); // Output: numbers: [1, 4, 9, 16]
  ///
  /// // Convert to strings
  /// Series string_numbers = numbers.apply((number) => number.toString());
  /// print(string_numbers); // Output: numbers: [1, 2, 3, 4]
  /// ```
  Series apply(dynamic Function(dynamic) func) {
    return Series(
      data.map(func).toList(),
      name: name,
    );
  }

  /// Apply a function to each element of the series for substituting values.
  ///
  /// Returns a new series with the function applied to each element, replacing values.
  Series map(Function(dynamic) func) {
    List<dynamic> mappedData = data.map(func).toList();
    return Series(mappedData, name: "$name (Mapped)");
  }

  /// Sort the Series elements.
  ///
  /// Returns a new series with elements sorted in ascending order.
  Series sortValues() {
    List<dynamic> sortedData = List.from(data)..sort();
    return Series(sortedData, name: "$name (Sorted)");
  }

  /// Convert strings in the series to uppercase.
  ///
  /// Returns a new StringSeries with strings converted to uppercase.
  Series upper() {
    List<dynamic> stringData =
        data.whereType<String>().map((str) => str.toUpperCase()).toList();
    return Series(stringData, name: "$name (Upper)");
  }

  /// Convert strings in the series to lowercase.
  ///
  /// Returns a new StringSeries with strings converted to lowercase.
  Series lower() {
    List<dynamic> stringData =
        data.whereType<String>().map((str) => str.toLowerCase()).toList();
    return Series(stringData, name: "$name (Lower)");
  }

  /// Check if strings in the series contain a pattern.
  ///
  /// Returns a new Series with boolean values indicating whether each string contains the pattern.
  Series containsPattern(String pattern) {
    List<bool> containsPatternList =
        data.whereType<String>().map((str) => str.contains(pattern)).toList();
    return Series(containsPatternList, name: "$name Contains '$pattern'");
  }

  /// Replace parts of strings in the series with a new substring.
  ///
  /// Returns a new StringSeries with replaced substrings.
  Series replace(String oldSubstring, String newSubstring) {
    List<dynamic> replacedStrings = data
        .whereType<String>()
        .map((str) => str.replaceAll(oldSubstring, newSubstring))
        .toList();
    return Series(replacedStrings, name: "$name (Replaced)");
  }

  /// Returns a new Series containing only the unique values from this Series.
  ///
  /// The order of elements is preserved (first occurrence kept).
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 1, 2], name: 'numbers');
  /// var unique = s.unique();
  /// print(unique); // Output: numbers (Unique): [1, 2, 3]
  /// ```
  Series unique() {
    final uniqueValues = <dynamic>[];
    final seen = <dynamic>{};
    
    for (var value in data) {
      if (!seen.contains(value)) {
        seen.add(value);
        uniqueValues.add(value);
      }
    }
    
    return Series(uniqueValues, name: "$name (Unique)");
  }

  /// Round each numeric value in the Series to the specified number of decimal places.
  ///
  /// Parameters:
  /// - `decimals`: Number of decimal places to round to. Default is 0.
  ///
  /// Returns:
  /// A new Series with rounded values. Non-numeric values are kept as is.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1.234, 2.345, 3.456], name: 'numbers');
  /// var rounded = s.round(2);
  /// print(rounded); // Output: numbers (Rounded): [1.23, 2.35, 3.46]
  /// ```
  Series round([int decimals = 0]) {
    if (data.isEmpty) {
      return Series([], name: "$name (Rounded)");
    }
    
    List<dynamic> roundedValues = [];
    
    for (var value in data) {
      if (value is num) {
        // Calculate the factor based on decimal places
        final factor = pow(10, decimals);
        
        // Round the value
        final rounded = (value * factor).round() / factor;
        
        roundedValues.add(rounded);
      } else {
        // Keep non-numeric values as is
        roundedValues.add(value);
      }
    }
    
    return Series(roundedValues, name: "$name (Rounded)");
  }
  
  /// Return the first n rows of the Series.
  ///
  /// Parameters:
  /// - `n`: Number of rows to return. Default is 5.
  ///
  /// Returns:
  /// A new Series containing the first n rows.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], name: 'numbers');
  /// var first5 = s.head();
  /// print(first5); // Output: numbers: [1, 2, 3, 4, 5]
  /// ```
  Series head([int n = 5]) {
    if (data.isEmpty) {
      return Series([], name: name);
    }
    
    // Ensure n is not larger than the data length
    n = n > data.length ? data.length : n;
    
    // Get the first n elements
    List<dynamic> headData = data.sublist(0, n);
    
    return Series(headData, name: name);
  }
  
  /// Return the last n rows of the Series.
  ///
  /// Parameters:
  /// - `n`: Number of rows to return. Default is 5.
  ///
  /// Returns:
  /// A new Series containing the last n rows.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], name: 'numbers');
  /// var last5 = s.tail();
  /// print(last5); // Output: numbers: [6, 7, 8, 9, 10]
  /// ```
  Series tail([int n = 5]) {
    if (data.isEmpty) {
      return Series([], name: name);
    }
    
    // Ensure n is not larger than the data length
    n = n > data.length ? data.length : n;
    
    // Get the last n elements
    int startIndex = data.length - n;
    List<dynamic> tailData = data.sublist(startIndex);
    
    return Series(tailData, name: name);
  }
}
