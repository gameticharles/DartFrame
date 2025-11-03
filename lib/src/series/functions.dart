part of 'series.dart';

extension SeriesFunctions on Series {
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

  // upper(), lower(), containsPattern(), replace() are moved to StringSeriesAccessor

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
      return Series([], name: name, index: index);
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
      return Series([], name: name, index: index);
    }

    // Ensure n is not larger than the data length
    n = n > data.length ? data.length : n;

    // Get the last n elements
    int startIndex = data.length - n;
    List<dynamic> tailData = data.sublist(startIndex);

    return Series(tailData, name: name);
  }

  /// Quantile-based discretization function.
  ///
  /// Discretize variable into equal-sized buckets based on rank or based on sample quantiles.
  ///
  /// Parameters:
  /// - q: Number of quantiles (int) or array of quantiles (`List<num>`, e.g., `[0, .25, .5, .75, 1.]` for quartiles).
  /// - labels: Used as labels for the resulting bins. Must be of the same length as the
  ///   number of bins. If false, returns only integer indicators of the bins.
  ///   If null (default), labels are constructed from the bin edges.
  /// - precision: The precision to store and display the bin labels. Default is 3.
  /// - duplicates: If bin edges are not unique, raise an ArgumentError ('raise') or drop non-uniques ('drop'). Default is 'raise'.
  ///
  /// Returns:
  /// A new Series with each original data point assigned to a quantile-based bin.
  ///
  /// Throws:
  /// - ArgumentError if data is not numeric, if q is invalid, if labels length mismatches,
  ///   or if duplicate bin edges are found and duplicates is 'raise'.
  Series qcut(
    dynamic q, {
    dynamic labels,
    int precision = 3,
    String duplicates = 'raise',
    // bool retbins = false, // Deferred for now
  }) {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;

    // 1. Initial Validation & Data Prep
    if (data.any((d) => d != missingRep && d is! num)) {
      throw ArgumentError('Series data must be numeric for qcut.');
    }

    final List<num> numericData =
        data.where((d) => d != missingRep && d is num).cast<num>().toList();

    if (numericData.isEmpty) {
      throw ArgumentError('No valid numeric data to perform quantile cut.');
    }
    numericData.sort();

    // 2. Determine Quantile Points
    List<double> quantilePoints;
    if (q is int) {
      if (q <= 0) {
        throw ArgumentError('Number of quantiles (q) must be positive.');
      }
      quantilePoints = List.generate(q + 1, (i) => i / q);
    } else if (q is List<num>) {
      if (q.isEmpty || q.any((p) => p < 0 || p > 1)) {
        throw ArgumentError('Quantiles in list q must be between 0 and 1.');
      }
      quantilePoints = q.map((p) => p.toDouble()).toList()..sort();
      // Ensure 0.0 and 1.0 are included for full range coverage if user provides list
      if (!quantilePoints.contains(0.0)) quantilePoints.insert(0, 0.0);
      if (!quantilePoints.contains(1.0)) quantilePoints.add(1.0);
      quantilePoints = quantilePoints.toSet().toList()
        ..sort(); // Unique and sorted
    } else {
      throw ArgumentError('q must be an int or a List<num>.');
    }

    // 3. Calculate Bin Edges
    List<num> binEdges = [];
    for (double point in quantilePoints) {
      final pos = (numericData.length - 1) * point;
      final int lowerIdx = pos.floor();
      final int upperIdx = pos.ceil();
      if (lowerIdx < 0) {
        // Should not happen with point >= 0
        binEdges.add(numericData.first);
      } else if (upperIdx >= numericData.length) {
        // Should not happen with point <= 1
        binEdges.add(numericData.last);
      } else {
        final num lower = numericData[lowerIdx];
        final num upper = numericData[upperIdx];
        binEdges.add(lower + (upper - lower) * (pos - lowerIdx));
      }
    }

    // Ensure first and last edges are min and max of data to cover all points
    binEdges[0] = numericData.first;
    binEdges[binEdges.length - 1] = numericData.last;

    // 4. Handle Duplicates in Bin Edges
    if (duplicates == 'raise') {
      for (int i = 0; i < binEdges.length - 1; i++) {
        if (binEdges[i] == binEdges[i + 1] && binEdges[i] != numericData.last) {
          // Allow last edge to be same if all remaining data points are identical to max
          throw ArgumentError(
              'Bin edges are not unique: $binEdges. Try duplicates="drop".');
        }
      }
    } else if (duplicates == 'drop') {
      binEdges = binEdges.toSet().toList()..sort((a, b) => a.compareTo(b));
    } else {
      throw ArgumentError('duplicates parameter must be "raise" or "drop".');
    }
    if (binEdges.length < 2) {
      throw ArgumentError(
          'Cannot cut with less than 2 unique bin edges. Data might be too uniform or q too low.');
    }

    // 5. Binning Logic (include_lowest=true, right=true implicitly by how edges are defined and used)
    List<dynamic> binnedData = List.filled(data.length, missingRep);
    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      if (value == missingRep || value is! num) {
        continue; // Already filled with missingRep
      }

      // Find bin index
      int binIdx = -1;
      // First bin: [edge_0, edge_1]
      if (value >= binEdges[0] && value <= binEdges[1]) {
        binIdx = 0;
      }
      // Subsequent bins: (edge_j, edge_j+1]
      else {
        for (int j = 1; j < binEdges.length - 1; j++) {
          if (value > binEdges[j] && value <= binEdges[j + 1]) {
            binIdx = j;
            break;
          }
        }
      }

      // If value is exactly the first edge and not caught by first bin (e.g., if include_lowest was false)
      // For qcut, the first bin is always inclusive of the minimum.
      if (binIdx == -1 && value == binEdges[0]) {
        binIdx = 0;
      }

      if (binIdx != -1) {
        binnedData[i] = binIdx; // Store integer code first
      }
    }

    // 6. Label Generation
    List<dynamic> finalLabels;
    int numberOfBins = binEdges.length - 1;

    if (labels == false) {
      // Return integer codes directly (already in binnedData)
      finalLabels = binnedData;
    } else {
      List<String> stringLabels;
      if (labels is List) {
        if (labels.length != numberOfBins) {
          throw ArgumentError(
              'Labels length must match the number of bins ($numberOfBins).');
        }
        stringLabels = labels.map((e) => e.toString()).toList();
      } else {
        // Default label generation
        stringLabels = List.generate(numberOfBins, (i) {
          String formatNum(num n) {
            if (n.isNaN) return 'NaN';
            if (n.isInfinite) return n.isNegative ? '-Infinity' : 'Infinity';
            num valToFormat = n;
            // Attempt to show integer if it's .0 after precision
            String str = valToFormat.toStringAsFixed(precision);
            if (RegExp(r'\.0+$').hasMatch(str)) {
              str = valToFormat.toInt().toString();
            }
            return str;
          }

          String leftEdge = formatNum(binEdges[i]);
          String rightEdge = formatNum(binEdges[i + 1]);
          // First bin is inclusive on left: [min, edge_1]
          // Others are (edge_i, edge_i+1]
          return (i == 0)
              ? '[$leftEdge, $rightEdge]'
              : '($leftEdge, $rightEdge]';
        });
      }
      // Map integer codes to actual labels
      for (int i = 0; i < binnedData.length; ++i) {
        if (binnedData[i] != missingRep && binnedData[i] is int) {
          int idx = binnedData[i] as int;
          if (idx >= 0 && idx < stringLabels.length) {
            binnedData[i] = stringLabels[idx];
          } else {
            binnedData[i] =
                missingRep; // Should not happen if binning logic is correct
          }
        }
      }
      finalLabels = binnedData;
    }

    return Series(finalLabels, name: '${name}_qcut', index: index);
  }

  /// Convert Series to a numeric type.
  ///
  /// Parameters:
  /// - errors: Specifies how to handle non-convertible values.
  ///   - 'raise' (default): Throw an exception if a value cannot be converted.
  ///   - 'coerce': Replace non-convertible values with the Series' missing value representation.
  ///   - 'ignore': Keep non-convertible values as they are.
  ///
  /// Returns a new Series with numeric values where possible.
  /// The dtype of the returned Series will be num if all values are successfully
  /// converted or coerced to missing. If errors == 'ignore' and some values
  /// remain non-numeric, the Series will have a mixed dtype.
  Series toNumeric({String errors = 'raise'}) {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;
    List<dynamic> newData = [];

    for (int i = 0; i < data.length; i++) {
      var element = data[i];
      num? numericValue;

      if (element is num) {
        numericValue = element;
      } else if (element is String) {
        numericValue = num.tryParse(element);
      } else if (element is bool) {
        numericValue = element ? 1 : 0;
      }

      if (numericValue != null) {
        newData.add(numericValue);
      } else {
        // Conversion failed or type not directly convertible
        if (errors == 'raise') {
          throw FormatException(
              "Unable to parse string \"${element.toString()}\" to a number at index $i for Series '$name'.");
        } else if (errors == 'coerce') {
          newData.add(missingRep);
        } else if (errors == 'ignore') {
          newData.add(element); // Keep original element
        } else {
          throw ArgumentError(
              "Invalid value for errors: $errors. Must be 'raise', 'coerce', or 'ignore'.");
        }
      }
    }
    return Series(newData, name: name, index: index);
  }

  /// Convert Series to datetime objects.
  ///
  /// Parameters:
  /// - errors: Specifies how to handle parsing errors.
  ///   - 'raise' (default): Throw an exception if a value cannot be converted.
  ///   - 'coerce': Replace non-convertible values with the Series' missing value representation.
  ///   - 'ignore': Keep non-convertible values as they are.
  /// - format: The strftime to parse time, e.g., "%d/%m/%Y". See DateFormat from package:intl.
  ///             If null, DateTime.tryParse will be used, and inferDatetimeFormat may take effect.
  /// - inferDatetimeFormat: If true and format is null, attempt to infer the format of common
  ///                            datetime strings. This is slower if formats are inconsistent. Default is false.
  ///
  /// Returns a new Series with DateTime objects where possible.
  /// If errors == 'ignore', the Series may contain mixed types.
  /// If errors == 'coerce', unparseable values become the missing value representation.
  Series toDatetime({
    String errors = 'raise',
    String? format,
    bool inferDatetimeFormat = false,
  }) {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;
    List<dynamic> newData = [];

    List<DateFormat> commonFormats = [];
    if (format == null && inferDatetimeFormat) {
      // Define a list of common DateFormats to try
      commonFormats = [
        DateFormat('yyyy-MM-dd HH:mm:ss'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('MM/dd/yyyy HH:mm:ss'),
        DateFormat('MM/dd/yyyy'),
        DateFormat('dd/MM/yyyy HH:mm:ss'),
        DateFormat('dd/MM/yyyy'),
        DateFormat('yyyy-MM-ddTHH:mm:ss'), // ISO8601 with T
        // Add more formats as needed, e.g., with milliseconds or Z for UTC
        DateFormat("yyyy-MM-ddTHH:mm:ss'Z'"), // ISO8601 UTC
        DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'"),
        DateFormat("yyyy-MM-ddTHH:mm:ss.SSS"),
      ];
    }

    for (int i = 0; i < data.length; i++) {
      var element = data[i];
      DateTime? dtValue;
      if (element is DateTime) {
        dtValue = element;
      } else if (element is String) {
        if (format != null) {
          try {
            dtValue = DateFormat(format).parseStrict(element);
          } catch (e) {
            // Parsing failed
          }
        } else {
          dtValue =
              DateTime.tryParse(element); // Handles ISO 8601 and some others
          if (dtValue == null && inferDatetimeFormat) {
            for (var fmt in commonFormats) {
              try {
                dtValue = fmt.parseStrict(element);
                break; // Found a format that works
              } catch (e) {
                // Try next format
              }
            }
          }
        }
      } else if (element is int) {
        // Assume milliseconds since epoch for integers
        dtValue = DateTime.fromMillisecondsSinceEpoch(element);
      } else if (element is double) {
        // Assume milliseconds since epoch for doubles, convert to int
        dtValue = DateTime.fromMillisecondsSinceEpoch(element.toInt());
      }

      if (dtValue != null) {
        newData.add(dtValue);
      } else {
        if (element == missingRep) {
          // Preserve already missing values
          newData.add(missingRep);
        } else if (errors == 'raise') {
          throw FormatException(
              "Unable to parse \"${element.toString()}\" to DateTime at index $i for Series '$name'.");
        } else if (errors == 'coerce') {
          newData.add(missingRep);
        } else if (errors == 'ignore') {
          newData.add(element); // Keep original element
        } else {
          throw ArgumentError(
              "Invalid value for errors: $errors. Must be 'raise', 'coerce', or 'ignore'.");
        }
      }
    }
    return Series(newData, name: name, index: index);
  }
}

/// Creates a Series of DateTime objects with a specified range.
///
/// This function creates a Series containing DateTime objects at regular intervals.
/// Similar to pandas' date_range function, it requires exactly two of the three
/// parameters: start, end, or periods.
///
/// Parameters:
///   - `start`: The starting date (inclusive). Required if `end` and `periods` are not both specified.
///   - `end`: The ending date (inclusive). Required if `start` and `periods` are not both specified.
///   - `periods`: The number of periods to generate. Required if `start` and `end` are not both specified.
///   - `freq`: The frequency of dates. Currently only supports 'D' for daily.
///   - `normalize`: If true, normalize the start and end dates to midnight.
///   - `name`: The name of the resulting Series.
///
/// Returns:
///   A Series containing DateTime objects.
///
/// Throws:
///   - ArgumentError if not exactly two of start, end, or periods are specified.
///   - ArgumentError if periods is negative.
///   - ArgumentError if start is after end with a positive periods value.
///   - ArgumentError if freq is not supported.
Series dateRange({
  DateTime? start,
  DateTime? end,
  int? periods,
  String freq = 'D',
  bool normalize = false,
  String name = 'dateRange',
}) {
  // Validate parameters
  int specifiedParams = 0;
  if (start != null) specifiedParams++;
  if (end != null) specifiedParams++;
  if (periods != null) specifiedParams++;

  // Special case: allow all three parameters if they're consistent or if periods is 0
  bool allThreeConsistent = false;
  if (specifiedParams == 3) {
    // If periods is 0, we'll return an empty series regardless of start/end
    if (periods == 0) {
      return Series([], name: name);
    }

    // Check if the parameters are consistent
    if (start != null && end != null && periods != null) {
      // Calculate the expected number of days between start and end
      int daysBetween = end.difference(start).inDays;
      // For inclusive range (start to end), we need daysBetween + 1 periods
      if (daysBetween + 1 == periods) {
        allThreeConsistent = true;
      }
    }
  }

  if (specifiedParams != 2 && !allThreeConsistent) {
    throw ArgumentError(
        'Exactly two of start, end, or periods must be specified.');
  }

  if (periods != null && periods < 0) {
    throw ArgumentError('periods cannot be negative.');
  }

  // Handle empty series cases
  if (periods == 0) {
    return Series([], name: name);
  }

  // Normalize dates if requested
  if (normalize) {
    start = start != null ? DateTime(start.year, start.month, start.day) : null;
    end = end != null ? DateTime(end.year, end.month, end.day) : null;
  }

  // Calculate missing parameter
  if (start == null) {
    // Calculate start from end and periods
    if (end != null && periods != null) {
      start = end.subtract(Duration(days: periods - 1));
    }
  } else if (end == null) {
    // Calculate end from start and periods
    if (periods != null) {
      end = start.add(Duration(days: periods - 1));
    }
  } else if (periods == null) {
    // Calculate periods from start and end
    // For inclusive range, we need daysBetween + 1
    periods = end.difference(start).inDays + 1;

    // Handle case where start is after end
    if (periods <= 0) {
      return Series([], name: name);
    }
  }

  // Validate parameters after calculation
  if (start != null &&
      end != null &&
      periods != null &&
      start.isAfter(end) &&
      periods > 0) {
    throw ArgumentError(
        'start cannot be after end with a positive periods value.');
  }

  // Only daily frequency is supported for now
  if (freq != 'D') {
    throw ArgumentError('Only daily frequency ("D") is currently supported.');
  }

  // Generate the date range
  List<DateTime> dates = [];
  if (periods != null && start != null) {
    for (int i = 0; i < periods; i++) {
      dates.add(start.add(Duration(days: i)));
    }
  }

  return Series(dates, name: name);
}
