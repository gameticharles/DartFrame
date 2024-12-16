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
  /// Returns a new series containing the cumulative sum of values.
  Series cumsum() {
    List<num> cumulativeSum = [];
    num runningSum = data[0];
    cumulativeSum.add(runningSum);
    for (int i = 1; i < data.length; i++) {
      runningSum += data[i];
      cumulativeSum.add(runningSum);
    }
    return Series(cumulativeSum, name: "$name Cumulative Sum");
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
}
