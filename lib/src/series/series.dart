part of '../../dartframe.dart';
part 'date_time_accessor.dart';

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

  // Helper to get the representation of missing values for this Series.
  // If part of a DataFrame with a custom marker, uses that. Otherwise, defaults to null.
  dynamic get _missingRepresentation => _parentDataFrame?.replaceMissingValueWith;

  // Helper to check if a value is considered missing for this Series.
  // A value is missing if it's null OR if it matches the DataFrame's specific missing value marker (if any).
  bool _isMissing(dynamic value) {
    final missingRep = _missingRepresentation;
    // If missingRep is itself null, then only actual nulls are missing by this rule.
    // If missingRep is non-null, then values matching it OR actual nulls are missing.
    if (missingRep != null) {
      return value == null || value == missingRep;
    }
    return value == null;
  }

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
    // dynamic missingValue = _parentDataFrame?.replaceMissingValueWith; // Replaced by _isMissing
    
    for (var value in data) {
      // if (value != null && value != missingValue) { // Old logic
      if (!_isMissing(value)) { // New logic
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

  /// Accessor for datetime-like properties of Series data.
  ///
  /// Provides access to methods for extracting components of DateTime objects
  /// within the Series, such as year, month, day, etc.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([DateTime(2023, 1, 15), DateTime(2024, 6, 20)], name: 'dates');
  /// var years = s.dt.year; // Series: [2023, 2024]
  /// print(years);
  /// ```
  SeriesDateTimeAccessor get dt {
    return SeriesDateTimeAccessor(this);
  }

  /// Returns the number of unique non-missing values in the Series.
  ///
  /// Missing values (null or the DataFrame's `replaceMissingValueWith` marker)
  /// are not counted.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 1, null, 3, 2], name: 'numbers');
  /// print(s.nunique()); // Outputs: 3 (1, 2, 3 are unique non-missing)
  ///
  /// var s2 = Series([null, null], name: 'all_missing');
  /// print(s2.nunique()); // Outputs: 0
  /// ```
  int nunique() {
    // dynamic missingRep = _parentDataFrame?.replaceMissingValueWith; // Replaced by _isMissing
    final Set<dynamic> uniqueValues = {};
    for (var value in data) {
      // if (value != missingRep) { // Old logic
      if (!_isMissing(value)) { // New logic
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
  ///             If `false`, include the count of missing values. Missing values are
  ///             represented by `_missingRepresentation` (or `null`) in the resulting index.
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['a', 'b', 'a', 'c', 'a', 'b', null], name: 'letters');
  /// print(s.valueCounts());
  /// // Output (order may vary for counts if not explicitly sorted by value):
  /// // letters_value_counts:
  /// // a       3
  /// // b       2
  /// // c       1
  /// // Length: 3
  /// // Type: int
  ///
  /// print(s.valueCounts(normalize: true, ascending: true));
  /// // Output (sorted by frequency ascending):
  /// // letters_value_counts:
  /// // c       0.1666...
  /// // b       0.3333...
  /// // a       0.5
  /// // Length: 3
  /// // Type: double
  ///
  /// print(s.valueCounts(dropna: false));
  /// // Output (includes null count):
  /// // letters_value_counts:
  /// // a       3
  /// // b       2
  /// // null    1  (or your DataFrame's missing value marker)
  /// // c       1
  /// // Length: 4
  /// // Type: int
  /// ```
  Series valueCounts({
    bool normalize = false,
    bool sort = true,
    bool ascending = false,
    bool dropna = true,
  }) {
    // dynamic missingRep = _parentDataFrame?.replaceMissingValueWith; // Replaced by _isMissing & _missingRepresentation
    final Map<dynamic, int> counts = {};
    final currentMissingRep = _missingRepresentation;

    for (var value in data) {
      if (_isMissing(value)) {
        if (!dropna) {
          // Use the canonical missing representation for the key if it's missing
          final key = currentMissingRep ?? value; // If currentMissingRep is null, use the actual null value as key
          counts[key] = (counts[key] ?? 0) + 1;
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
        // Ensure that when mapping, if a count corresponds to a missingRep, it's handled.
        // This part might need care if missingRep itself is a key in resultData and is not a num.
        // The current logic seems okay as it only divides `num` counts.
        resultData = resultData.map((count) {
          if (count is num) return count / sumOfCounts;
          return _missingRepresentation; // if count was for a missing value and it's not num
        }).toList();
      } else {
         resultData = resultData.map((_) => 0.0).toList(); // All counts are zero or non-numeric
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
  /// `replaceMissingValueWith` property (or `null` if no parent DataFrame),
  /// as determined by the internal `_isMissing` helper.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, null, 3], name: 'data_with_null');
  /// print(s.isna());
  /// // Output:
  /// // data_with_null_isna:
  /// // 0       false
  /// // 1       true
  /// // 2       false
  /// // Length: 3
  /// // Type: bool
  /// ```
  Series isna() {
    // final missingValue = _parentDataFrame?.replaceMissingValueWith; // Replaced by _isMissing
    final boolList = data.map((e) => _isMissing(e)).toList();
    return Series(boolList, name: '${name}_isna', index: index?.toList());
  }

  /// Returns a boolean Series indicating if each value is not missing.
  ///
  /// This is the inverse of `isna()`. A value is considered not missing if it is
  /// not equal to the parent DataFrame's `replaceMissingValueWith` property
  /// (or `null` if no parent DataFrame), as determined by the internal
  /// `_isMissing` helper.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, null, 3], name: 'data_with_null');
  /// print(s.notna());
  /// // Output:
  /// // data_with_null_notna:
  /// // 0       true
  /// // 1       false
  /// // 2       true
  /// // Length: 3
  /// // Type: bool
  /// ```
  Series notna() {
    // final missingValue = _parentDataFrame?.replaceMissingValueWith; // Replaced by _isMissing
    final boolList = data.map((e) => !_isMissing(e)).toList();
    return Series(boolList, name: '${name}_notna', index: index?.toList());
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

    final currentMissingRep = _missingRepresentation;
    List<dynamic> newData = [];

    for (int i = 0; i < data.length; i++) {
      dynamic originalVal = data[i];
      num? numVal;
      bool conversionError = false;

      if (_isMissing(originalVal) && originalVal != null && originalVal == currentMissingRep) { 
        // If it's the specific missing marker (and not null itself being the marker)
        // and we want to coerce, it becomes currentMissingRep.
        // If errors='ignore', it remains originalVal.
        // If errors='raise', this path shouldn't be hit for missing values typically.
        // This logic is mainly for 'coerce'.
        if (errors == 'coerce') {
          newData.add(currentMissingRep);
          continue;
        } else if (errors == 'ignore') {
          newData.add(originalVal);
          continue;
        }
        // If 'raise', existing missing values don't cause format exception unless they are strings.
      }


      if (originalVal is num) {
        numVal = originalVal;
      } else if (originalVal is String) {
        numVal = num.tryParse(originalVal);
        if (numVal == null) {
          conversionError = true;
        }
      } else if (originalVal == null) { // Already handled by _isMissing if null is the marker
        conversionError = true; // Or treat as missing based on 'errors'
      }
      else { // Other non-string, non-num types
        conversionError = true;
      }

      if (conversionError) {
        if (errors == 'raise') {
          // Only raise if it's not already a recognized missing value that we're trying to coerce/ignore
          if (!_isMissing(originalVal) || (originalVal is String && num.tryParse(originalVal) == null)) {
             throw FormatException("Unable to parse value '$originalVal' to numeric at index $i");
          } else { // It's a missing value we couldn't parse (e.g. a non-string missing marker)
             newData.add(currentMissingRep); // Coerce implicitly if it was a non-string missing marker
          }
        } else if (errors == 'coerce') {
          newData.add(currentMissingRep);
        } else { // errors == 'ignore'
          newData.add(originalVal);
        }
      } else if (numVal != null) {
        if (downcast == 'integer') {
          if (numVal.truncate() == numVal) {
            newData.add(numVal.toInt());
          } else {
            if (errors == 'raise') {
              throw FormatException("Cannot downcast value '$originalVal' (parsed as $numVal) to integer without loss at index $i");
            } else if (errors == 'coerce') {
              newData.add(currentMissingRep);
            } else { // errors == 'ignore'
              newData.add(numVal); 
            }
          }
        } else if (downcast == 'float') {
          newData.add(numVal.toDouble());
        } else { 
          newData.add(numVal); 
        }
      } else { // Should not be reached if logic is correct, but as a fallback:
        if (errors == 'raise' && !_isMissing(originalVal)) {
           throw FormatException("Unknown error parsing value '$originalVal' to numeric at index $i");
        } else if (errors == 'coerce' || _isMissing(originalVal)) {
          newData.add(currentMissingRep);
        } else { // errors == 'ignore'
          newData.add(originalVal);
        }
      }
    }
    return Series(newData, name: name, index: index?.toList());
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

    final currentMissingRep = _missingRepresentation;
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

      if (_isMissing(originalVal)) {
        if (errors == 'coerce') {
          newData.add(currentMissingRep);
        } else if (errors == 'ignore') {
          newData.add(originalVal);
        } else { // errors == 'raise', existing missing values are not an error unless unparseable string
          if (originalVal is String) { // If missing rep is a string that's not a date
             throw FormatException("Unable to parse value '$originalVal' to DateTime at index $i");
          }
          newData.add(currentMissingRep); // Default for non-string missing markers
        }
        continue;
      }
      
      if (originalVal is DateTime) {
        dtVal = originalVal;
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
          newData.add(currentMissingRep);
        } else { // errors == 'ignore'
          newData.add(originalVal);
        }
      } else {
        newData.add(dtVal);
      }
    }
    return Series(newData, name: name, index: index?.toList());
  }

    /// Access elements by position or label using boolean indexing.
  ///
  /// Returns a new series containing only the elements for which the boolean condition is true.
  dynamic operator [](dynamic indices) {
    List<dynamic> selectedData = [];
    if (indices is List<bool>) {
      for (int i = 0; i < indices.length; i++) {
        if (indices[i]) {
          selectedData.add(data[i]);
        }
      }
    } else {
      // Handle single index
      return data[indices];
    }
    return Series(selectedData, name: name);
  }

  /// Sets the value for provided index or indices
  ///
  /// This method assigns the value or values to the Series as specified
  /// by the indices.
  ///
  /// Parameters:
  /// - indices: Represents which elements to modify. Can be a single index,
  ///   or potentially a list of indices for multiple assignments.
  /// - value: The value to assign. If multiple indices are provided, 'value'
  ///   should be an iterable such as a list or another Series.
  void operator []=(dynamic indices, dynamic value) {
    if (indices is int) {
      // Single Index Assignment
      if (indices < 0 || indices >= data.length) {
        throw IndexError.withLength(
          indices,
          data.length,
          indexable: this,
          name: 'Index out of range',
          message: null,
        );
      }
      data[indices] = value;

      // Update parent DataFrame if this Series is linked to one
      if (_parentDataFrame != null && _columnName != null) {
        _parentDataFrame!.updateCell(_columnName!, indices, value);
      }
    } else if (indices is List<int>) {
      // Multiple Index Assignment
      if (value is! List || value.length != indices.length) {
        throw ArgumentError(
            "Value must be a list of the same length as the indices.");
      }
      for (int i = 0; i < indices.length; i++) {
        data[indices[i]] = value[i];

        // Update parent DataFrame if this Series is linked to one
        if (_parentDataFrame != null && _columnName != null) {
          _parentDataFrame!.updateCell(_columnName!, indices[i], value[i]);
        }
      }
    } else if (indices is List<bool> ||
        (indices is Series && indices.data is List<bool>)) {
      var dd = indices is Series ? indices.data : indices;
      if (value is List) {
        if (value.length != indices.length) {
          throw ArgumentError(
              "Value must be a list of the same length as the indices.");
        }
        for (int i = 0; i < indices.length; i++) {
          if (dd[i]) {
            data[i] = value[i];

            // Update parent DataFrame if this Series is linked to one
            if (_parentDataFrame != null && _columnName != null) {
              _parentDataFrame!.updateCell(_columnName!, i, value[i]);
            }
          }
        }
      } else if (value is num) {
        for (int i = 0; i < indices.length; i++) {
          if (dd[i]) {
            data[i] = value;

            // Update parent DataFrame if this Series is linked to one
            if (_parentDataFrame != null && _columnName != null) {
              _parentDataFrame!.updateCell(_columnName!, i, value);
            }
          }
        }
      }
    } else {
      throw ArgumentError("Unsupported indices type.");
    }
  }

  /// Access a value by label
  dynamic at(dynamic label) {
    final idx = index?.indexOf(label) ?? -1;
    if (idx == -1) {
      throw ArgumentError('Label not found: $label');
    }
    return data[idx];
  }

  /// Sorts the Series by its values.
  ///
  /// Returns a new `Series` with its data sorted.
  ///
  /// The original `Series` remains unchanged. The index of the new `Series` is
  /// adjusted to correspond to the sorted data. If the original `Series` had a
  /// custom index, those index labels are permuted along with the data. If it
  /// had a default integer index, the new `Series` will also have a default
  /// integer index that reflects the new order of the data values (i.e., the
  /// index labels in the output will be the original positions of the sorted values).
  ///
  /// Missing values (null or `_parentDataFrame.replaceMissingValueWith`) are handled
  /// according to the `naPosition` parameter.
  ///
  /// @param ascending If `true` (default), sorts in ascending order. Otherwise, sorts in descending order.
  /// @param naPosition Determines the placement of missing values.
  ///   - `'first'`: Missing values are placed at the beginning.
  ///   - `'last'` (default): Missing values are placed at the end.
  /// @returns A new `Series` with sorted values and a correspondingly sorted index.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([30, 10, null, 20], name: 'values', index: ['a', 'b', 'c', 'd']);
  /// print(s.sort_values());
  /// // Output:
  /// // values:
  /// // b       10
  /// // d       20
  /// // a       30
  /// // c       null
  /// // Length: 4
  /// // Type: int
  ///
  /// print(s.sort_values(ascending: false, naPosition: 'first'));
  /// // Output:
  /// // values:
  /// // c       null
  /// // a       30
  /// // d       20
  /// // b       10
  /// // Length: 4
  /// // Type: int
  /// ```
  Series sort_values({
    bool ascending = true,
    String naPosition = 'last',
  }) {
    if (naPosition != 'first' && naPosition != 'last') {
      throw ArgumentError("naPosition must be either 'first' or 'last'");
    }

    // final missingValue = _parentDataFrame?.replaceMissingValueWith; // Replaced by _isMissing
    List<dynamic> currentData = List.from(data);
    List<dynamic> currentIndex = index != null ? List.from(index!) : List.generate(currentData.length, (i) => i);

    // Create a list of pairs: [value, original_index_in_currentIndex]
    // We use original_index_in_currentIndex to retrieve the correct index label later
    List<List<dynamic>> pairedList = [];
    for (int i = 0; i < currentData.length; i++) {
      pairedList.add([currentData[i], i]);
    }

    // Separate NaNs and valid values
    List<List<dynamic>> nanValues = [];
    List<List<dynamic>> validValues = [];

    for (var pair in pairedList) {
      // if (pair[0] == missingValue || pair[0] == null) { // Old logic
      if (_isMissing(pair[0])) { // New logic
        nanValues.add(pair);
      } else {
        validValues.add(pair);
      }
    }

    // Sort valid values
    validValues.sort((a, b) {
      // Ensure comparable types or handle type differences gracefully
      if (a[0] is Comparable && b[0] is Comparable) {
        try {
          int comparisonResult = (a[0] as Comparable).compareTo(b[0] as Comparable);
          return ascending ? comparisonResult : -comparisonResult;
        } catch (e) {
          // Fallback for non-comparable types within Comparable or type mismatch
          // This might happen if types are mixed and not directly comparable
          // For simplicity, treat as equal or maintain original order by returning 0
          // A more sophisticated approach might involve type-specific comparison logic
          return 0;
        }
      } else if (a[0] == null && b[0] == null) {
        return 0; // Both are null or missing
      } else if (a[0] == null) {
        return naPosition == 'first' ? -1 : 1; // Consistent with how NaNs are handled separately
      } else if (b[0] == null) {
        return naPosition == 'first' ? 1 : -1;
      }
      // If types are not comparable and not null, maintain original order relative to each other
      return 0;
    });

    // Combine sorted valid values and NaNs based on naPosition
    List<List<dynamic>> sortedPairedList;
    if (naPosition == 'first') {
      sortedPairedList = [...nanValues, ...validValues];
    } else { // naPosition == 'last'
      sortedPairedList = [...validValues, ...nanValues];
    }

    // Extract sorted data and sorted index
    List<dynamic> sortedData = sortedPairedList.map((pair) => pair[0]).toList();
    List<dynamic> sortedIndex;

    // If original series had an index, use the sorted original index values
    // Otherwise, the new index will be the default integer index (implicit)
    if (index != null) {
      sortedIndex = sortedPairedList.map((pair) => currentIndex[pair[1] as int]).toList();
    } else {
      // If there was no original index, the new series also won't have an explicit one.
      // The Series constructor will generate a default one if index is null.
      sortedIndex = List.generate(sortedData.length, (i) => i); // or pass null to Series constructor for default
    }
    
    // Create a new Series with the sorted data and index
    // Pass null for index if the original series didn't have one and we want default indexing.
    // However, the logic above creates a default 0..N-1 index if original was null.
    // To strictly adhere to "if the original series does not have an index, 
    // the new series should also not have an explicit index",
    // we should pass null if this.index was null.
    return Series(
      sortedData,
      name: name, // Preserve the original name
      index: this.index == null ? null : sortedIndex,
    );
  }

  /// Sorts the Series by its index labels.
  ///
  /// Returns a new `Series` sorted by its index labels.
  ///
  /// The original `Series` remains unchanged. Both the data and the index of the
  /// new `Series` are reordered according to the sorted index labels.
  /// If the `Series` has a default integer index, sorting by this index effectively
  /// sorts the data by its original position (if `ascending` is true) or reverses it
  /// (if `ascending` is false and the default index was `0, 1, ..., N-1`).
  ///
  /// @param ascending If `true` (default), sorts the index in ascending order.
  ///   Otherwise, sorts in descending order.
  /// @returns A new `Series` with data and index reordered based on the sorted index labels.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([10, 20, 5], name: 'data', index: ['c', 'a', 'b']);
  /// print(s.sort_index());
  /// // Output:
  /// // data:
  /// // a       20
  /// // b       5
  /// // c       10
  /// // Length: 3
  /// // Type: int
  ///
  /// var sDefaultIndex = Series([100, 200, 50], name: 'default_idx');
  /// print(sDefaultIndex.sort_index(ascending: false));
  /// // Output:
  /// // default_idx:
  /// // 2       50
  /// // 1       200
  /// // 0       100
  /// // Length: 3
  /// // Type: int
  /// ```
  Series sort_index({
    bool ascending = true,
  }) {
    // Use the existing index or generate a default one if null
    List<dynamic> currentIndexLabels = index != null ? List.from(index!) : List.generate(data.length, (i) => i);

    // Create a list of pairs: [index_label, original_data_position]
    List<List<dynamic>> pairedList = [];
    for (int i = 0; i < currentIndexLabels.length; i++) {
      pairedList.add([currentIndexLabels[i], i]); // Store original position (which is also data index)
    }

    // Sort the paired list based on index labels
    // The `_parentDataFrame?.replaceMissingValueWith` is not directly used here for index values,
    // as index sorting typically relies on the inherent comparability of index labels.
    // If index labels could be missing values that need special handling like in `sort_values`,
    // that logic would be added here, but typically index labels are expected to be non-null and comparable.
    pairedList.sort((a, b) {
      dynamic labelA = a[0];
      dynamic labelB = b[0];

      if (labelA is Comparable && labelB is Comparable) {
        try {
          int comparisonResult = labelA.compareTo(labelB);
          return ascending ? comparisonResult : -comparisonResult;
        } catch (e) {
          // Fallback for non-comparable types or type mismatch within Comparable
          // Treat as equal or maintain original order by returning 0
          return 0;
        }
      } else if (labelA == null && labelB == null) {
        return 0; // Both are null
      } else if (labelA == null) {
        return -1; // Nulls first by default, or handle as per a naPosition-like param if added
      } else if (labelB == null) {
        return 1;  // Nulls first by default
      }
      // If types are not comparable and not null, maintain original order
      return 0;
    });

    // Extract the new sorted index labels and the corresponding sorted data
    List<dynamic> sortedIndex = pairedList.map((pair) => pair[0]).toList();
    List<dynamic> sortedData = pairedList.map((pair) => data[pair[1] as int]).toList();

    return Series(
      sortedData,
      name: name, // Preserve the original name
      index: sortedIndex, // Use the newly sorted index labels
    );
  }

  /// Resets the index of the Series.
  ///
  /// Depending on the `drop` parameter, this method either returns a new `Series`
  /// with a default integer index, or a `DataFrame` where the original index
  /// becomes a column.
  ///
  /// Parameters:
  ///   - `level` (dynamic, default `null`): Specifies which levels to remove from the index
  ///     if the Series has a MultiIndex. *Currently ignored in this implementation.*
  ///   - `drop` (bool, default `false`): If `true`, the original index is discarded, and a
  ///     new `Series` with a default integer index is returned. If `false`, the original
  ///     index is converted into a column in a new `DataFrame`.
  ///   - `name` (String?, default `null`): The name to use for the column if the index is
  ///     inserted into a DataFrame (i.e., when `drop` is `false`). If `null`,
  ///     the column name will be 'index'.
  ///   - `inplace` (bool, default `false`): If `true`, modify the Series in place.
  ///     *Currently ignored; the method always returns a new object.*
  ///
  /// Returns a new `Series` or `DataFrame` with a reset index.
  ///
  /// - If `drop` is `true`, the current index is discarded, and a new `Series`
  ///   is returned with a default integer index (`0, 1, ..., N-1`). The data
  ///   and name of the Series are preserved.
  /// - If `drop` is `false` (default), the current index is converted into a
  ///   column in a new `DataFrame`. The original Series data becomes another
  ///   column in this DataFrame. The new DataFrame will have a default
  ///   integer index.
  ///
  /// The original `Series` remains unchanged.
  ///
  /// @param level (Currently ignored) For `MultiIndex`, specifies which levels to remove.
  /// @param drop If `true`, the index is dropped and a `Series` with a default
  ///   integer index is returned. If `false` (default), the index becomes a column
  ///   in a new `DataFrame`.
  /// @param name If `drop` is `false`, this is the name used for the new column
  ///   containing the original index values. Defaults to `'index'` if `null`.
  /// @param inplace (Currently ignored) If `true`, performs the operation in place.
  ///   This implementation always returns a new object.
  /// @returns A `Series` if `drop` is `true`, or a `DataFrame` if `drop` is `false`.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([10, 20, 30], name: 'myValues', index: ['x', 'y', 'z']);
  ///
  /// // Case 1: drop = true
  /// var sReset = s.reset_index(drop: true);
  /// print(sReset);
  /// // Output:
  /// // myValues:
  /// // 0       10
  /// // 1       20
  /// // 2       30
  /// // Length: 3
  /// // Type: int
  ///
  /// // Case 2: drop = false
  /// var dfFromSeries = s.reset_index(drop: false, name: 'original_index');
  /// print(dfFromSeries);
  /// // Output:
  /// //        original_index  myValues
  /// // 0                x        10
  /// // 1                y        20
  /// // 2                z        30
  /// ```
  dynamic reset_index({
    dynamic level, // Ignored for now
    bool drop = false,
    String? name,
    bool inplace = false, // Ignored for now
  }) {
    if (drop) {
      // Return a new Series with a default integer index
      return Series(
        List.from(data), // Ensure a copy of data
        name: this.name,
        index: null, // This will lead to a default integer index
      );
    } else {
      // Return a DataFrame
      List<dynamic> indexColumnData =
          this.index != null ? List.from(this.index!) : List.generate(data.length, (i) => i);

      String indexColumnName = name ?? 'index';
      
      // Determine the name for the original Series' data column
      // Pandas uses '0' for an unnamed Series when it becomes a column.
      // If this.name is null or empty, use '0'. Otherwise, use this.name.
      String seriesDataColumnName = (this.name.isNotEmpty) ? this.name : '0';

      // Ensure unique column names if indexColumnName happens to be the same as seriesDataColumnName
      if (indexColumnName == seriesDataColumnName) {
          // This case is less likely if seriesDataColumnName defaults to '0' and index to 'index'
          // but good to handle. Pandas appends suffixes like '_level_0', '_values'
          // For simplicity, let's adjust one if they are identical and default.
          if (indexColumnName == 'index' && seriesDataColumnName == 'index') {
              seriesDataColumnName = '${this.name}_values'; // Or some other distinguishing name
          } else {
            // Or throw an error, or apply a more general renaming strategy.
            // For now, simple adjustment if default names clash.
            // If user explicitly sets `name` to be same as `this.name`, it's a bit trickier.
            // Let's assume for now they won't be identical, or one will be adjusted by default logic.
          }
      }


      Map<String, List<dynamic>> dfData = {
        indexColumnName: indexColumnData,
        seriesDataColumnName: List.from(data), // Ensure a copy of data
      };

      return DataFrame.fromMap(dfData);
    }
  }

  /// Fills missing values in the Series.
  ///
  /// Missing values are identified if they are equal to
  /// `_parentDataFrame?.replaceMissingValueWith` or if they are `null`.
  ///
  /// Parameters:
  ///   - `value` (dynamic, optional): The value to use for filling missing entries.
  ///   - `method` (String?, optional): The method to use for filling holes in reindexed Series.
  ///     Can be 'ffill' (propagate last valid observation forward) or
  ///     'bfill' (use next valid observation to fill gap).
  ///
  /// Returns:
  ///   A new `Series` with missing values filled. The original `Series` is not modified.
  ///   If both `value` and `method` are provided, `method` takes precedence.
  ///   If neither `value` nor `method` is provided, a new `Series` identical to the
  ///   original is returned. If both `value` and `method` are provided, `method` takes precedence.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1.0, null, 3.0, null, 5.0], name: 'data');
  /// print(s.fillna(value: 0.0));
  /// // Output:
  /// // data:
  /// // 0       1.0
  /// // 1       0.0
  /// // 2       3.0
  /// // 3       0.0
  /// // 4       5.0
  /// // Length: 5
  /// // Type: double
  ///
  /// print(s.fillna(method: 'ffill'));
  /// // Output:
  /// // data:
  /// // 0       1.0
  /// // 1       1.0
  /// // 2       3.0
  /// // 3       3.0
  /// // 4       5.0
  /// // Length: 5
  /// // Type: double
  ///
  /// print(s.fillna(method: 'bfill'));
  /// // Output:
  /// // data:
  /// // 0       1.0
  /// // 1       3.0
  /// // 2       3.0
  /// // 3       5.0
  /// // 4       5.0
  /// // Length: 5
  /// // Type: double
  /// ```
  Series fillna({
    dynamic value,
    String? method,
  }) {
    List<dynamic> newData = List.from(data);
    final List<dynamic>? newIndex = index != null ? List.from(index!) : null;
    // final dynamic missingIndicator = _parentDataFrame?.replaceMissingValueWith; // Replaced by _isMissing

    // bool isMissing(dynamic val) { // Replaced by _isMissing helper
    //   if (missingIndicator != null) {
    //     return val == missingIndicator || val == null;
    //   }
    //   return val == null;
    // }

    if (method != null && method != 'ffill' && method != 'bfill') {
      throw ArgumentError("method must be either 'ffill' or 'bfill'");
    }

    if (method == 'ffill') {
      dynamic lastValidObservation = const Object(); 
      for (int i = 0; i < newData.length; i++) {
        if (!_isMissing(newData[i])) {
          lastValidObservation = newData[i];
        } else {
          if (lastValidObservation != const Object()) {
            newData[i] = lastValidObservation;
          }
        }
      }
    } else if (method == 'bfill') {
      dynamic nextValidObservation = const Object(); 
      for (int i = newData.length - 1; i >= 0; i--) {
        if (!_isMissing(newData[i])) {
          nextValidObservation = newData[i];
        } else {
          if (nextValidObservation != const Object()) {
            newData[i] = nextValidObservation;
          }
        }
      }
    } else if (value != null) { // `value` is the fill value, not the element from series
      for (int i = 0; i < newData.length; i++) {
        if (_isMissing(newData[i])) {
          newData[i] = value;
        }
      }
    }
    return Series(newData, name: this.name, index: newIndex);
  }

  /// Applies a function to each element in the Series.
  ///
  /// This method iterates over the data in the Series, applies the provided
  /// function `func` to each element, and returns a new `Series` containing
  /// the transformed values.
  ///
  /// The provided `func` is responsible for handling any missing values
  /// (e.g., `null` or `_parentDataFrame?.replaceMissingValueWith`)
  /// as it sees fit.
  ///
  /// Parameters:
  ///   - `func`: A function that takes a single dynamic argument (an element
  ///     from the Series) and returns a dynamic transformed value.
  ///
  /// Returns:
  ///   A new `Series` with the transformed data, preserving the original
  ///   `name` and `index` (copied). The original `Series` is not modified.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4], name: 'numbers');
  /// var sSquared = s.apply((x) => x * x);
  /// print(sSquared);
  /// // Output:
  /// // numbers:
  /// // 0       1
  /// // 1       4
  /// // 2       9
  /// // 3       16
  /// // Length: 4
  /// // Type: int
  ///
  /// var sStringify = s.apply((x) => 'Item $x');
  /// print(sStringify);
  /// // Output:
  /// // numbers:
  /// // 0       Item 1
  /// // 1       Item 2
  /// // 2       Item 3
  /// // 3       Item 4
  /// // Length: 4
  /// // Type: String
  /// ```
  Series apply(Function(dynamic) func) {
    List<dynamic> newData = [];
    for (int i = 0; i < data.length; i++) {
      newData.add(func(data[i]));
    }

    return Series(
      newData,
      name: this.name,
      index: this.index != null ? List.from(this.index!) : null,
    );
  }

  /// Checks whether each element in the Series is contained in `values`.
  ///
  /// Returns a boolean `Series` showing whether each element in the Series
  /// matches an element in the passed sequence of `values` exactly.
  ///
  /// Missing values (`_parentDataFrame?.replaceMissingValueWith` or `null`)
  /// in the Series data will result in `false` in the output boolean Series,
  /// unless the `values` iterable explicitly contains that missing value
  /// representation (e.g., `null` or the specific missing value marker).
  ///
  /// Parameters:
  ///   - `values`: An `Iterable<dynamic>` of values to check for. For performance,
  ///     if `values` is large, it is recommended to pass a `Set`.
  ///
  /// Returns:
  ///   A new `Series` of boolean values, with the same index as the original.
  ///   The name of the new Series will be the original name suffixed with `_isin`
  ///   (e.g., `originalName_isin`). The original `Series` is not modified.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, null, 4, 1], name: 'data');
  /// var checkValues = [1, 4, null];
  /// var result = s.isin(checkValues);
  /// print(result);
  /// // Output:
  /// // data_isin:
  /// // 0       true
  /// // 1       false
  /// // 2       false
  /// // 3       true  (null from series is in checkValues)
  /// // 4       true
  /// // 5       true
  /// // Length: 6
  /// // Type: bool
  /// ```
  Series isin(Iterable<dynamic> values) {
    // Convert `values` to a Set for efficient lookup, if it's not already.
    // This is a common optimization.
    final Set<dynamic> valueSet = values is Set<dynamic> ? values : values.toSet();
    
    List<bool> boolData = [];
    for (int i = 0; i < data.length; i++) {
      boolData.add(valueSet.contains(data[i]));
    }

    return Series(
      boolData,
      name: '${this.name}_isin',
      index: this.index != null ? List.from(this.index!) : null,
    );
  }

  /// Returns a list of unique values in the Series.
  ///
  /// The unique values are returned in the order of their first appearance
  /// in the Series. Missing values (including `null` and the specific
  /// `_parentDataFrame?.replaceMissingValueWith` marker) are treated as
  /// distinct values and will be included in the result if present.
  ///
  /// Returns:
  ///   A `List<dynamic>` containing the unique values from the Series,
  ///   preserving the order of their first appearance.
  ///
  /// Example:
  /// ```dart
  /// var s = Series([2, 1, 3, 2, null, 1, null, 'a'], name: 'items');
  /// print(s.unique()); // Output: [2, 1, 3, null, 'a']
  ///
  /// var sEmpty = Series<int>([], name: 'empty');
  /// print(sEmpty.unique()); // Output: []
  /// ```
  List<dynamic> unique() {
    List<dynamic> uniqueValues = [];
    Set<dynamic> seenValues = {}; // Using a Set for efficient lookup of seen values

    for (var value in data) {
      if (!seenValues.contains(value)) {
        uniqueValues.add(value);
        seenValues.add(value);
      }
    }
    return uniqueValues;
  }
}

