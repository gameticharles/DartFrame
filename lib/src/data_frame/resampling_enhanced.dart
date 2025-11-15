part of 'data_frame.dart';

/// Enhanced resampling operations for DataFrame
extension DataFrameResamplingEnhanced on DataFrame {
  /// Resample with OHLC (Open, High, Low, Close) aggregation.
  ///
  /// This is commonly used for financial time series data.
  ///
  /// Parameters:
  /// - `frequency`: Target frequency string ('D', 'H', 'M', 'Y')
  /// - `dateColumn`: Name of the column containing DateTime values
  /// - `valueColumn`: Name of the column to aggregate (if null, applies to all numeric columns)
  /// - `closed`: Which side of bin interval is closed ('left' or 'right')
  /// - `label`: Which bin edge label to use ('left' or 'right')
  ///
  /// Returns:
  /// DataFrame with OHLC columns
  ///
  /// Example:
  /// ```dart
  /// var prices = DataFrame.fromMap(
  ///   {'price': [100, 102, 98, 105, 103, 107]},
  ///   index: [
  ///     DateTime(2024, 1, 1, 9, 0),
  ///     DateTime(2024, 1, 1, 10, 0),
  ///     DateTime(2024, 1, 1, 11, 0),
  ///     DateTime(2024, 1, 2, 9, 0),
  ///     DateTime(2024, 1, 2, 10, 0),
  ///     DateTime(2024, 1, 2, 11, 0),
  ///   ],
  /// );
  ///
  /// // Resample to daily OHLC
  /// var daily = prices.resampleOHLC('D', valueColumn: 'price');
  /// // Returns: open, high, low, close columns
  /// ```
  DataFrame resampleOHLC(
    String frequency, {
    String? dateColumn,
    String? valueColumn,
    String closed = 'left',
    String label = 'left',
  }) {
    if (!FrequencyUtils.isValidFrequency(frequency)) {
      throw ArgumentError('Invalid frequency: $frequency');
    }

    // Find the date column
    String? actualDateColumn = dateColumn;
    if (actualDateColumn == null) {
      // Try to find a DateTime column automatically
      if (index.isNotEmpty && index.first is DateTime) {
        // Use index as date column
        actualDateColumn = '__index__';
      } else {
        for (final col in columns) {
          final series = this[col];
          if (series.data.isNotEmpty && series.data.first is DateTime) {
            actualDateColumn = col;
            break;
          }
        }
      }
    }

    if (actualDateColumn == null) {
      throw ArgumentError('No date column found');
    }

    // Get date values
    final dateTimes = <DateTime>[];
    if (actualDateColumn == '__index__') {
      dateTimes.addAll(index.cast<DateTime>());
    } else {
      final dateSeriesData = this[actualDateColumn].data;
      for (var value in dateSeriesData) {
        if (value is DateTime) {
          dateTimes.add(value);
        }
      }
    }

    if (dateTimes.isEmpty) {
      throw ArgumentError('No valid DateTime values found');
    }

    // Create target frequency index
    final sortedDates = List<DateTime>.from(dateTimes)..sort();
    final targetIndex = TimeSeriesIndex.dateRange(
      start: sortedDates.first,
      end: sortedDates.last,
      frequency: frequency,
    );

    // Determine which columns to process
    final columnsToProcess = <String>[];
    if (valueColumn != null) {
      if (!columns.contains(valueColumn)) {
        throw ArgumentError('Column "$valueColumn" not found');
      }
      columnsToProcess.add(valueColumn);
    } else {
      // Process all numeric columns
      for (final col in columns) {
        if (col != actualDateColumn) {
          final series = this[col];
          if (series.data.isNotEmpty && series.data.first is num) {
            columnsToProcess.add(col);
          }
        }
      }
    }

    // Group data by time periods
    final groups = <DateTime, List<int>>{};
    for (int i = 0; i < dateTimes.length; i++) {
      final binDate =
          _findBinForDate(dateTimes[i], targetIndex.timestamps, closed);
      if (binDate != null) {
        groups.putIfAbsent(binDate, () => []).add(i);
      }
    }

    // Build OHLC data
    final resultData = <List<dynamic>>[];
    final resultIndex = <DateTime>[];
    final resultColumns = <String>[];

    // Create column names
    for (final col in columnsToProcess) {
      resultColumns
          .addAll(['${col}_open', '${col}_high', '${col}_low', '${col}_close']);
    }

    for (final binDate in targetIndex.timestamps) {
      final rowIndices = groups[binDate] ?? [];

      if (rowIndices.isNotEmpty) {
        final row = <dynamic>[];

        for (final col in columnsToProcess) {
          final values = rowIndices
              .map((idx) => this[col].data[idx])
              .whereType<num>()
              .cast<num>()
              .toList();

          if (values.isNotEmpty) {
            row.add(values.first); // Open
            row.add(values.reduce((a, b) => a > b ? a : b)); // High
            row.add(values.reduce((a, b) => a < b ? a : b)); // Low
            row.add(values.last); // Close
          } else {
            row.addAll([null, null, null, null]);
          }
        }

        resultData.add(row);
        resultIndex.add(binDate);
      }
    }

    return DataFrame(
      resultData,
      columns: resultColumns,
      index: resultIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Resample with nunique (number of unique values) aggregation.
  ///
  /// Parameters:
  /// - `frequency`: Target frequency string
  /// - `dateColumn`: Name of the column containing DateTime values
  /// - `closed`: Which side of bin interval is closed ('left' or 'right')
  /// - `label`: Which bin edge label to use ('left' or 'right')
  ///
  /// Returns:
  /// DataFrame with count of unique values per period
  ///
  /// Example:
  /// ```dart
  /// var events = DataFrame.fromMap(
  ///   {
  ///     'user_id': [1, 2, 1, 3, 2, 4],
  ///     'action': ['login', 'login', 'click', 'login', 'click', 'login']
  ///   },
  ///   index: [
  ///     DateTime(2024, 1, 1, 9, 0),
  ///     DateTime(2024, 1, 1, 10, 0),
  ///     DateTime(2024, 1, 1, 11, 0),
  ///     DateTime(2024, 1, 2, 9, 0),
  ///     DateTime(2024, 1, 2, 10, 0),
  ///     DateTime(2024, 1, 2, 11, 0),
  ///   ],
  /// );
  ///
  /// // Count unique users per day
  /// var daily = events.resampleNunique('D');
  /// ```
  DataFrame resampleNunique(
    String frequency, {
    String? dateColumn,
    String closed = 'left',
    String label = 'left',
  }) {
    return _resampleWithAggregation(
      frequency,
      'nunique',
      dateColumn: dateColumn,
      closed: closed,
      label: label,
    );
  }

  /// Resample with offset applied to the time bins.
  ///
  /// Parameters:
  /// - `frequency`: Target frequency string
  /// - `offset`: Time offset to apply (e.g., '30min', '1H', '15D')
  /// - `aggFunc`: Aggregation function to apply
  /// - `dateColumn`: Name of the column containing DateTime values
  /// - `closed`: Which side of bin interval is closed ('left' or 'right')
  /// - `label`: Which bin edge label to use ('left' or 'right')
  ///
  /// Returns:
  /// DataFrame with offset resampling
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [1, 2, 3, 4, 5]},
  ///   index: [
  ///     DateTime(2024, 1, 1, 0, 0),
  ///     DateTime(2024, 1, 1, 6, 0),
  ///     DateTime(2024, 1, 1, 12, 0),
  ///     DateTime(2024, 1, 1, 18, 0),
  ///     DateTime(2024, 1, 2, 0, 0),
  ///   ],
  /// );
  ///
  /// // Resample to daily starting at 6 AM
  /// var daily = df.resampleWithOffset('D', offset: '6H', aggFunc: 'mean');
  /// ```
  DataFrame resampleWithOffset(
    String frequency,
    String offset, {
    String aggFunc = 'mean',
    String? dateColumn,
    String closed = 'left',
    String label = 'left',
  }) {
    if (!FrequencyUtils.isValidFrequency(frequency)) {
      throw ArgumentError('Invalid frequency: $frequency');
    }

    // Parse offset
    final offsetDuration = _parseOffset(offset);

    // Find the date column
    String? actualDateColumn = dateColumn;
    if (actualDateColumn == null) {
      if (index.isNotEmpty && index.first is DateTime) {
        actualDateColumn = '__index__';
      } else {
        for (final col in columns) {
          final series = this[col];
          if (series.data.isNotEmpty && series.data.first is DateTime) {
            actualDateColumn = col;
            break;
          }
        }
      }
    }

    if (actualDateColumn == null) {
      throw ArgumentError('No date column found');
    }

    // Get date values
    final dateTimes = <DateTime>[];
    if (actualDateColumn == '__index__') {
      dateTimes.addAll(index.cast<DateTime>());
    } else {
      final dateSeriesData = this[actualDateColumn].data;
      for (var value in dateSeriesData) {
        if (value is DateTime) {
          dateTimes.add(value);
        }
      }
    }

    if (dateTimes.isEmpty) {
      throw ArgumentError('No valid DateTime values found');
    }

    // Apply offset to start date
    final sortedDates = List<DateTime>.from(dateTimes)..sort();
    final offsetStart = sortedDates.first.add(offsetDuration);
    final offsetEnd = sortedDates.last.add(offsetDuration);

    // Create target frequency index with offset
    final targetIndex = TimeSeriesIndex.dateRange(
      start: offsetStart,
      end: offsetEnd,
      frequency: frequency,
    );

    // Group data by time periods (with offset)
    final groups = <DateTime, List<int>>{};
    for (int i = 0; i < dateTimes.length; i++) {
      final offsetDate = dateTimes[i].add(offsetDuration);
      final binDate =
          _findBinForDate(offsetDate, targetIndex.timestamps, closed);
      if (binDate != null) {
        groups.putIfAbsent(binDate, () => []).add(i);
      }
    }

    // Apply aggregation
    final resultData = <List<dynamic>>[];
    final resultIndex = <DateTime>[];

    for (final binDate in targetIndex.timestamps) {
      final rowIndices = groups[binDate] ?? [];

      if (rowIndices.isNotEmpty) {
        final row = <dynamic>[];

        for (final col in columns) {
          if (col == actualDateColumn) {
            // Subtract offset for the result
            row.add(binDate.subtract(offsetDuration));
          } else {
            final values = rowIndices
                .map((idx) => this[col].data[idx])
                .where((val) => val != null && val != replaceMissingValueWith)
                .toList();

            final aggregatedValue = _applyAggregationMethod(values, aggFunc);
            row.add(aggregatedValue);
          }
        }

        resultData.add(row);
        resultIndex.add(binDate.subtract(offsetDuration));
      }
    }

    return DataFrame(
      resultData,
      columns: columns,
      index: resultIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Internal method for resampling with custom aggregation
  DataFrame _resampleWithAggregation(
    String frequency,
    String aggFunc, {
    String? dateColumn,
    String closed = 'left',
    String label = 'left',
  }) {
    if (!FrequencyUtils.isValidFrequency(frequency)) {
      throw ArgumentError('Invalid frequency: $frequency');
    }

    // Find the date column
    String? actualDateColumn = dateColumn;
    if (actualDateColumn == null) {
      if (index.isNotEmpty && index.first is DateTime) {
        actualDateColumn = '__index__';
      } else {
        for (final col in columns) {
          final series = this[col];
          if (series.data.isNotEmpty && series.data.first is DateTime) {
            actualDateColumn = col;
            break;
          }
        }
      }
    }

    if (actualDateColumn == null) {
      throw ArgumentError('No date column found');
    }

    // Get date values
    final dateTimes = <DateTime>[];
    if (actualDateColumn == '__index__') {
      dateTimes.addAll(index.cast<DateTime>());
    } else {
      final dateSeriesData = this[actualDateColumn].data;
      for (var value in dateSeriesData) {
        if (value is DateTime) {
          dateTimes.add(value);
        }
      }
    }

    if (dateTimes.isEmpty) {
      throw ArgumentError('No valid DateTime values found');
    }

    // Create target frequency index
    final sortedDates = List<DateTime>.from(dateTimes)..sort();
    final targetIndex = TimeSeriesIndex.dateRange(
      start: sortedDates.first,
      end: sortedDates.last,
      frequency: frequency,
    );

    // Group data by time periods
    final groups = <DateTime, List<int>>{};
    for (int i = 0; i < dateTimes.length; i++) {
      final binDate =
          _findBinForDate(dateTimes[i], targetIndex.timestamps, closed);
      if (binDate != null) {
        groups.putIfAbsent(binDate, () => []).add(i);
      }
    }

    // Apply aggregation
    final resultData = <List<dynamic>>[];
    final resultIndex = <DateTime>[];

    for (final binDate in targetIndex.timestamps) {
      final rowIndices = groups[binDate] ?? [];

      if (rowIndices.isNotEmpty) {
        final row = <dynamic>[];

        for (final col in columns) {
          if (col == actualDateColumn && actualDateColumn != '__index__') {
            row.add(binDate);
          } else {
            final values = rowIndices
                .map((idx) => this[col].data[idx])
                .where((val) => val != null && val != replaceMissingValueWith)
                .toList();

            final aggregatedValue = _applyAggregationMethod(values, aggFunc);
            row.add(aggregatedValue);
          }
        }

        resultData.add(row);
        resultIndex.add(binDate);
      }
    }

    return DataFrame(
      resultData,
      columns: columns,
      index: resultIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Find bin for a date
  DateTime? _findBinForDate(DateTime date, List<DateTime> bins, String closed) {
    for (int i = 0; i < bins.length; i++) {
      final binStart = bins[i];
      final binEnd = i < bins.length - 1
          ? bins[i + 1]
          : binStart.add(const Duration(days: 365)); // Far future for last bin

      bool inBin = false;
      if (closed == 'left') {
        // Include binStart, exclude binEnd
        inBin = (date.isAtSameMomentAs(binStart) || date.isAfter(binStart)) &&
            date.isBefore(binEnd);
      } else {
        // Exclude binStart, include binEnd
        inBin = date.isAfter(binStart) &&
            (date.isAtSameMomentAs(binEnd) || date.isBefore(binEnd));
      }

      if (inBin) {
        return binStart;
      }
    }

    return null;
  }

  /// Apply aggregation method to values
  dynamic _applyAggregationMethod(List<dynamic> values, String aggFunc) {
    if (values.isEmpty) {
      return replaceMissingValueWith;
    }

    switch (aggFunc.toLowerCase()) {
      case 'mean':
        final numValues = values.whereType<num>().toList();
        if (numValues.isEmpty) return replaceMissingValueWith;
        return numValues.reduce((a, b) => a + b) / numValues.length;

      case 'sum':
        final numValues = values.whereType<num>().toList();
        if (numValues.isEmpty) return replaceMissingValueWith;
        return numValues.reduce((a, b) => a + b);

      case 'min':
        final numValues = values.whereType<num>().toList();
        if (numValues.isEmpty) return replaceMissingValueWith;
        return numValues.reduce((a, b) => a < b ? a : b);

      case 'max':
        final numValues = values.whereType<num>().toList();
        if (numValues.isEmpty) return replaceMissingValueWith;
        return numValues.reduce((a, b) => a > b ? a : b);

      case 'count':
        return values.length;

      case 'first':
        return values.first;

      case 'last':
        return values.last;

      case 'nunique':
        return values.toSet().length;

      case 'std':
        final numValues = values.whereType<num>().toList();
        if (numValues.isEmpty || numValues.length < 2) {
          return replaceMissingValueWith;
        }
        final mean = numValues.reduce((a, b) => a + b) / numValues.length;
        final variance = numValues
                .map((x) => (x - mean) * (x - mean))
                .reduce((a, b) => a + b) /
            (numValues.length - 1);
        return sqrt(variance);

      case 'var':
        final numValues = values.whereType<num>().toList();
        if (numValues.isEmpty || numValues.length < 2) {
          return replaceMissingValueWith;
        }
        final mean = numValues.reduce((a, b) => a + b) / numValues.length;
        return numValues
                .map((x) => (x - mean) * (x - mean))
                .reduce((a, b) => a + b) /
            (numValues.length - 1);

      case 'median':
        final numValues = values.whereType<num>().toList()..sort();
        if (numValues.isEmpty) return replaceMissingValueWith;
        final mid = numValues.length ~/ 2;
        if (numValues.length % 2 == 0) {
          return (numValues[mid - 1] + numValues[mid]) / 2;
        } else {
          return numValues[mid];
        }

      default:
        throw ArgumentError('Unsupported aggregation function: $aggFunc');
    }
  }

  /// Parse offset string like '30min', '1H', '15D'
  Duration _parseOffset(String offset) {
    final match = RegExp(r'(\d+)(min|H|D|W|M|Y)').firstMatch(offset);
    if (match == null) {
      throw ArgumentError(
          'Invalid offset format. Use format like "30min", "1H", "15D"');
    }

    final value = int.parse(match.group(1)!);
    final unit = match.group(2)!;

    switch (unit) {
      case 'min':
        return Duration(minutes: value);
      case 'H':
        return Duration(hours: value);
      case 'D':
        return Duration(days: value);
      case 'W':
        return Duration(days: value * 7);
      case 'M':
        return Duration(days: value * 30); // Approximate
      case 'Y':
        return Duration(days: value * 365); // Approximate
      default:
        throw ArgumentError('Unsupported offset unit: $unit');
    }
  }
}
