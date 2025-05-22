part of '../../dartframe.dart';

/// A `Series` class represents a one-dimensional array with a label.
///
/// The `Series` class is designed to hold a sequence of data of any type `T`,
/// where `T` can be anything from `int`, `double`, `String`, to custom objects.
/// Each `Series` object is associated with a name, typically representing the
/// column name when part of a DataFrame.
///
/// The class allows for future extensions where methods for common data
/// manipulations and analyses can be added, making it a fundamental building
/// block for handling tabular data.
///
/// Example usage:
/// ```dart
/// var numericSeries = Series<int>([1, 2, 3, 4], name: 'Numbers');
/// print(numericSeries); // Outputs: Numbers: [1, 2, 3, 4]
///
/// var stringSeries = Series<String>(['a', 'b', 'c'], name: 'Letters');
/// print(stringSeries); // Outputs: Letters: [a, b, c]
/// ```
class Series {
  /// The data of the series.
  ///
  /// This list holds the actual data points of the series. The generic type `T`
  /// allows the series to hold any type of data.
  List<dynamic> data;

  /// The name of the series.
  ///
  /// Typically represents the column name in a DataFrame and is used to
  /// identify the series.
  String name;

  // Add these fields to the Series class
  DataFrame? _parentDataFrame;
  String? _columnName;
  List<dynamic>? index;

  /// Sets the parent DataFrame reference
  void setParent(DataFrame parent, String columnName) {
    _parentDataFrame = parent;
    _columnName = columnName;
  }

  /// Constructs a `Series` object with the given [data] and [name].
  ///
  /// The [data] parameter is a list containing the data points of the series,
  /// and the [name] parameter is a string representing the series' name.
  ///
  /// Parameters:
  /// - `data`: The data points of the series.
  /// - `name`: The name of the series. This parameter is required.
  /// - `index`: Optional list to use as index for the Series
  Series(this.data, {required this.name, this.index});

  /// Returns a string representation of the series.
  ///
  /// This method overrides the `toString` method to provide a meaningful
  /// string representation of the series in a tabular format.
  @override
  String toString({int columnSpacing = 2}) {
    if (data.isEmpty) {
      return 'Empty Series: $name';
    }

    // Calculate column width for values
    int maxValueWidth = 0;
    for (var value in data) {
      int valueWidth = value.toString().length;
      if (valueWidth > maxValueWidth) {
        maxValueWidth = valueWidth;
      }
    }

    // Calculate name width
    int nameWidth = name.length;

    // Calculate the maximum width needed for row headers/index
    int indexWidth = 0;
    List<dynamic> indexList = index ?? List.generate(data.length, (i) => i);

    for (var idx in indexList) {
      int headerWidth = idx.toString().length;
      if (headerWidth > indexWidth) {
        indexWidth = headerWidth;
      }
    }

    // Ensure index width is at least as wide as the word "index"
    indexWidth = max(indexWidth, 5);

    // Use the maximum of value width and name width for column width
    int columnWidth = max(maxValueWidth, nameWidth);

    // Add spacing
    columnWidth += columnSpacing;
    indexWidth += columnSpacing;

    // Construct the table string
    StringBuffer buffer = StringBuffer();

    // Add header
    buffer.write(' '.padRight(indexWidth));
    buffer.writeln(name.padRight(columnWidth));

    // Add data rows
    for (int i = 0; i < data.length; i++) {
      buffer.write(indexList[i].toString().padRight(indexWidth));
      buffer.writeln(data[i].toString().padRight(columnWidth));
    }

    // Add series information
    buffer.writeln();
    buffer.writeln('Length: ${data.length}');
    buffer
        .writeln('Type: ${data.isEmpty ? 'unknown' : data.first.runtimeType}');

    return buffer.toString();
  }

  /// Length of the data in the series
  int get length => data.length;

  /// Returns the predominant data type of the Series.
  ///
  /// This getter determines the most common type among non-missing values in the Series.
  /// If the Series is empty or contains only missing values, it returns `dynamic`.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3], name: 'numbers');
  /// print(s.dtype); // Outputs: int
  ///
  /// var mixed = Series([1, 'a', true], name: 'mixed');
  /// print(mixed.dtype); // Outputs the most common type or dynamic
  /// ```
  Type get dtype {
    if (data.isEmpty) return dynamic;
    
    // Count occurrences of each type
    Map<Type, int> typeCounts = {};
    dynamic missingValue = _parentDataFrame?.replaceMissingValueWith;
    
    for (var value in data) {
      if (value != null && value != missingValue) {
        Type valueType = value.runtimeType;
        typeCounts[valueType] = (typeCounts[valueType] ?? 0) + 1;
      }
    }
    
    if (typeCounts.isEmpty) return dynamic;
    
    // Find the most common type
    Type mostCommonType = dynamic;
    int maxCount = 0;
    
    typeCounts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonType = type;
      }
    });
    
    return mostCommonType;
  }

// Return the Series as a data frame
  DataFrame toDataFrame() => DataFrame.fromMap({name: data});

  /// Accessor for string-specific operations on Series data.
  StringSeriesAccessor get str {
    return StringSeriesAccessor(this);
  }

  /// Returns the number of unique non-missing values in the Series.
  int nunique() {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;
    final Set<dynamic> uniqueValues = {};
    for (var value in data) {
      if (value != missingRep) {
        uniqueValues.add(value);
      }
    }
    return uniqueValues.length;
  }

  /// Returns a Series containing counts of unique values.
  ///
  /// The resulting Series will have unique values from this Series as its index,
  /// and the counts of these values as its data.
  ///
  /// Parameters:
  ///   - `normalize`: If `true`, return relative frequencies (proportions) instead of counts.
  ///   - `sort`: If `true` (default), sort the resulting Series by frequency.
  ///   - `ascending`: If `true` (and `sort` is `true`), sort in ascending order of frequency. Default is `false` (descending).
  ///   - `dropna`: If `true` (default), do not include counts of missing values in the result.
  ///             If `false`, include the count of missing values.
  Series valueCounts({
    bool normalize = false,
    bool sort = true,
    bool ascending = false,
    bool dropna = true,
  }) {
    dynamic missingRep = _parentDataFrame?.replaceMissingValueWith;
    final Map<dynamic, int> counts = {};

    for (var value in data) {
      if (value == missingRep) {
        if (!dropna) {
          counts[missingRep] = (counts[missingRep] ?? 0) + 1;
        }
      } else {
        counts[value] = (counts[value] ?? 0) + 1;
      }
    }
    
    List<MapEntry<dynamic, int>> sortedCounts = counts.entries.toList();

    if (sort) {
      sortedCounts.sort((a, b) {
        int comparison = a.value.compareTo(b.value);
        return ascending ? comparison : -comparison;
      });
    }

    List<dynamic> resultIndex = [];
    List<dynamic> resultData = [];

    for (var entry in sortedCounts) {
      resultIndex.add(entry.key);
      resultData.add(entry.value);
    }

    if (normalize) {
      num sumOfCounts = resultData.whereType<num>().fold(0, (sum, val) => sum + val);
      if (sumOfCounts != 0) {
        resultData = resultData.map((count) => count is num ? count / sumOfCounts : missingRep).toList();
      } else {
         resultData = resultData.map((_) => 0.0).toList();
      }
    }
    
    return Series(
      resultData,
      name: '${name}_value_counts',
      index: resultIndex,
    );
  }

  /// Returns a boolean Series indicating if each value is missing.
  ///
  /// A value is considered missing if it is equal to the parent DataFrame's
  /// `replaceMissingValueWith` property (or `null` if no parent DataFrame).
  Series isna() {
    final missingValue = _parentDataFrame?.replaceMissingValueWith;
    final boolList = data.map((e) => e == missingValue).toList();
    return Series(boolList, name: '${name}_isna', index: index);
  }

  /// Returns a boolean Series indicating if each value is not missing.
  ///
  /// This is the inverse of `isna()`. A value is considered not missing if it is
  /// not equal to the parent DataFrame's `replaceMissingValueWith` property
  /// (or `null` if no parent DataFrame).
  Series notna() {
    final missingValue = _parentDataFrame?.replaceMissingValueWith;
    final boolList = data.map((e) => e != missingValue).toList();
    return Series(boolList, name: '${name}_notna', index: index);
  }

  /// Convert Series to numeric.
  ///
  /// Attempts to convert elements of the Series to numeric types (`int` or `double`).
  ///
  /// Parameters:
  ///   - `errors` (String, default `'raise'`):
  ///     - If `'raise'`, then invalid parsing will raise an exception.
  ///     - If `'coerce'`, then invalid parsing will be set as the Series' missing value representation.
  ///     - If `'ignore'`, then invalid parsing will return the input.
  ///   - `downcast` (String?, default `null`):
  ///     - If `null`, data is kept as `int` or `double` as parsed.
  ///     - If `'integer'`, attempt to downcast to `int` if possible (i.e., number has no fractional part).
  ///     - If `'float'`, data is cast to `double`.
  ///
  /// Returns:
  /// A new `Series` with numeric data. The name of the series is preserved.
  ///
  /// Throws:
  ///   - `FormatException` if `errors == 'raise'` and a value cannot be parsed.
  ///   - `ArgumentError` if `errors` or `downcast` has an invalid value.
  Series toNumeric({String errors = 'raise', String? downcast}) {
    if (!['raise', 'coerce', 'ignore'].contains(errors)) {
      throw ArgumentError("errors must be one of 'raise', 'coerce', 'ignore'");
    }
    if (downcast != null && !['integer', 'float'].contains(downcast)) {
      throw ArgumentError("downcast must be one of 'integer', 'float', or null");
    }

    final missingValue = _parentDataFrame?.replaceMissingValueWith;
    List<dynamic> newData = [];

    for (int i = 0; i < data.length; i++) {
      dynamic originalVal = data[i];
      num? numVal;
      bool conversionError = false;

      if (originalVal is num) {
        numVal = originalVal;
      } else if (originalVal is String) {
        numVal = num.tryParse(originalVal);
        if (numVal == null) {
          conversionError = true;
        }
      } else if (originalVal == missingValue) { // Handle existing missing values
        newData.add(missingValue);
        continue;
      }
      else {
        conversionError = true; // Not a num or String, cannot parse
      }

      if (conversionError) {
        if (errors == 'raise') {
          throw FormatException(
              "Unable to parse value '$originalVal' to numeric at index $i");
        } else if (errors == 'coerce') {
          newData.add(missingValue);
        } else { // errors == 'ignore'
          newData.add(originalVal);
        }
      } else if (numVal != null) {
        // Successfully parsed or already numeric
        if (downcast == 'integer') {
          if (numVal.truncate() == numVal) {
            newData.add(numVal.toInt());
          } else {
            // Cannot be downcast to integer without loss
            if (errors == 'raise') {
              throw FormatException(
                  "Cannot downcast value '$originalVal' (parsed as $numVal) to integer without loss at index $i");
            } else if (errors == 'coerce') {
              newData.add(missingValue);
            } else { // errors == 'ignore'
              newData.add(numVal); // Keep as float if cannot downcast
            }
          }
        } else if (downcast == 'float') {
          newData.add(numVal.toDouble());
        } else { // downcast == null
          newData.add(numVal); // Keep as parsed (int or double)
        }
      } else { 
        if (errors == 'raise' && originalVal != missingValue) { 
           throw FormatException("Unknown error parsing value '$originalVal' to numeric at index $i");
        } else if (errors == 'coerce' || originalVal == missingValue) {
          newData.add(missingValue);
        } else { // errors == 'ignore'
          newData.add(originalVal);
        }
      }
    }
    return Series(newData, name: name, index: List.from(index ?? []));
  }

  /// Convert Series to datetime.
  ///
  /// Attempts to convert elements of the Series to `DateTime` objects.
  ///
  /// Parameters:
  ///   - `errors` (String, default `'raise'`):
  ///     - If `'raise'`, then invalid parsing will raise an exception.
  ///     - If `'coerce'`, then invalid parsing will be set as `null`.
  ///     - If `'ignore'`, then invalid parsing will return the input.
  ///   - `format` (String?, default `null`):
  ///     The specific format string to use for parsing dates (e.g., 'yyyy-MM-dd HH:mm:ss').
  ///     If `null`, parsing behavior is determined by `inferDatetimeFormat`.
  ///   - `inferDatetimeFormat` (bool, default `false`):
  ///     If `true` and `format` is `null`, attempt to infer the format of common date strings.
  ///     Starts with `DateTime.tryParse()` (for ISO 8601) and then tries a list of common formats.
  ///     If `false` and `format` is `null`, only `DateTime.tryParse()` is used.
  ///
  /// Returns:
  /// A new `Series` with `DateTime?` data. The name of the series is preserved.
  ///
  /// Throws:
  ///   - `FormatException` if `errors == 'raise'` and a value cannot be parsed.
  ///   - `ArgumentError` if `errors` has an invalid value.
  Series toDatetime({String errors = 'raise', String? format, bool inferDatetimeFormat = false}) {
    if (!['raise', 'coerce', 'ignore'].contains(errors)) {
      throw ArgumentError("errors must be one of 'raise', 'coerce', 'ignore'");
    }

    final missingValueRep = _parentDataFrame?.replaceMissingValueWith;
    List<dynamic> newData = [];

    // Common date formats for inference
    final List<DateFormat> commonDateFormats = inferDatetimeFormat ? [
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('yyyy-MM-ddTHH:mm:ss'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('MM/dd/yyyy HH:mm:ss'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd/MM/yyyy HH:mm:ss'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('yyyy.MM.dd HH:mm:ss'),
      DateFormat('yyyy.MM.dd'),
      DateFormat('MM-dd-yyyy HH:mm:ss'),
      DateFormat('MM-dd-yyyy'),
    ] : [];

    for (int i = 0; i < data.length; i++) {
      dynamic originalVal = data[i];
      DateTime? dtVal;
      bool conversionError = false;

      if (originalVal is DateTime) {
        dtVal = originalVal;
      } else if (originalVal == missingValueRep || originalVal == null) {
        // Keep missing values as they are
        newData.add(originalVal);
        continue;
      } else if (originalVal is num) {
        // Handle numeric timestamps (milliseconds since epoch)
        try {
          dtVal = DateTime.fromMillisecondsSinceEpoch(originalVal.toInt());
        } catch (e) {
          conversionError = true;
        }
      } else if (originalVal is String) {
        if (format != null) {
          try {
            dtVal = DateFormat(format).parseStrict(originalVal);
          } catch (e) {
            conversionError = true;
          }
        } else {
          // Try DateTime.tryParse first
          try {
            dtVal = DateTime.tryParse(originalVal);
          } catch (e) {
            dtVal = null;
          }
          
          // If tryParse failed and we're inferring formats, try common formats
          if (dtVal == null && inferDatetimeFormat) {
            for (var dfmt in commonDateFormats) {
              try {
                dtVal = dfmt.parseStrict(originalVal);
                break; // Found a format that works
              } catch (e) {
                // Try next format
              }
            }
            if (dtVal == null) conversionError = true; // None of the inferred formats worked
          } else if (dtVal == null && !inferDatetimeFormat) {
            conversionError = true; // DateTime.tryParse failed and not inferring
          }
        }
      } else { // Not DateTime, String, or the defined missing value
        conversionError = true; 
      }

      if (conversionError) {
        if (errors == 'raise') {
          throw FormatException("Unable to parse value '$originalVal' to DateTime at index $i");
        } else if (errors == 'coerce') {
          newData.add(missingValueRep); // Use the DataFrame's missing value representation or null
        } else { // errors == 'ignore'
          newData.add(originalVal);
        }
      } else {
        newData.add(dtVal);
      }
    }
    return Series(newData, name: name, index: index);
  }
}

