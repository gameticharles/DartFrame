part of 'data_frame.dart';

/// Time series operations for DataFrame
extension DataFrameTimeSeries on DataFrame {
  /// Shift index by desired number of periods.
  ///
  /// Parameters:
  /// - `periods`: Number of periods to shift (can be positive or negative)
  /// - `freq`: Offset to use from the tseries module or time rule (not implemented yet)
  /// - `axis`: Shift direction (0 for index/rows, 1 for columns)
  /// - `fillValue`: Value to use for newly introduced missing values
  ///
  /// Returns:
  /// DataFrame with shifted data
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3, 4, 5],
  ///   'B': [10, 20, 30, 40, 50]
  /// });
  ///
  /// // Shift down by 1 period
  /// var shifted = df.shift(1);
  /// // First row will be null, data moves down
  ///
  /// // Shift up by 1 period
  /// var shifted = df.shift(-1);
  /// // Last row will be null, data moves up
  /// ```
  DataFrame shift(
    int periods, {
    int axis = 0,
    dynamic fillValue,
  }) {
    if (axis != 0) {
      throw UnimplementedError('Column shifting (axis=1) not yet implemented');
    }

    if (periods == 0) {
      return DataFrame(
        _data.map((row) => List.from(row)).toList(),
        columns: columns,
        index: index,
        replaceMissingValueWith: replaceMissingValueWith,
      );
    }

    final fill = fillValue ?? replaceMissingValueWith;
    final newData = <List<dynamic>>[];

    if (periods > 0) {
      // Shift down (add nulls at the beginning)
      for (int i = 0; i < periods && i < rowCount; i++) {
        newData.add(List.filled(columns.length, fill));
      }
      for (int i = 0; i < rowCount - periods; i++) {
        newData.add(List.from(_data[i]));
      }
    } else {
      // Shift up (add nulls at the end)
      final absPeriods = -periods;
      for (int i = absPeriods; i < rowCount; i++) {
        newData.add(List.from(_data[i]));
      }
      for (int i = 0; i < absPeriods && newData.length < rowCount; i++) {
        newData.add(List.filled(columns.length, fill));
      }
    }

    return DataFrame(
      newData,
      columns: columns,
      index: index,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Lag values by n periods (equivalent to shift(n)).
  ///
  /// Parameters:
  /// - `periods`: Number of periods to lag (default: 1)
  /// - `fillValue`: Value to use for newly introduced missing values
  ///
  /// Returns:
  /// DataFrame with lagged data
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2, 3, 4, 5]});
  /// var lagged = df.lag(1);  // [null, 1, 2, 3, 4]
  /// var lagged2 = df.lag(2); // [null, null, 1, 2, 3]
  /// ```
  DataFrame lag(int periods, {dynamic fillValue}) {
    return shift(periods, fillValue: fillValue);
  }

  /// Lead values by n periods (equivalent to shift(-n)).
  ///
  /// Parameters:
  /// - `periods`: Number of periods to lead (default: 1)
  /// - `fillValue`: Value to use for newly introduced missing values
  ///
  /// Returns:
  /// DataFrame with led data
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({'A': [1, 2, 3, 4, 5]});
  /// var led = df.lead(1);  // [2, 3, 4, 5, null]
  /// var led2 = df.lead(2); // [3, 4, 5, null, null]
  /// ```
  DataFrame lead(int periods, {dynamic fillValue}) {
    return shift(-periods, fillValue: fillValue);
  }

  /// Shift the time index, using the index's frequency if available.
  ///
  /// Parameters:
  /// - `periods`: Number of periods to shift
  /// - `freq`: Frequency string ('D', 'H', 'M', 'Y', etc.)
  ///
  /// Returns:
  /// DataFrame with shifted time index
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [1, 2, 3]},
  ///   index: [
  ///     DateTime(2024, 1, 1),
  ///     DateTime(2024, 1, 2),
  ///     DateTime(2024, 1, 3),
  ///   ],
  /// );
  ///
  /// // Shift index by 1 day
  /// var shifted = df.tshift(1, freq: 'D');
  /// ```
  DataFrame tshift(int periods, {String? freq}) {
    if (freq == null) {
      throw ArgumentError('freq parameter is required for tshift');
    }

    if (!FrequencyUtils.isValidFrequency(freq)) {
      throw ArgumentError('Invalid frequency: $freq');
    }

    // Check if index contains DateTime values
    if (index.isEmpty || index.first is! DateTime) {
      throw ArgumentError('tshift requires a DateTime index');
    }

    final newIndex = <DateTime>[];
    for (var idx in index) {
      if (idx is DateTime) {
        final shifted = FrequencyUtils.addPeriods(idx, periods, freq);
        newIndex.add(shifted);
      } else {
        throw ArgumentError('All index values must be DateTime for tshift');
      }
    }

    return DataFrame(
      _data.map((row) => List.from(row)).toList(),
      columns: columns,
      index: newIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Convert TimeSeries to specified frequency.
  ///
  /// Parameters:
  /// - `freq`: Frequency string to convert to
  /// - `method`: Fill method for missing values ('pad', 'backfill', 'nearest')
  /// - `fillValue`: Value to use for missing values
  ///
  /// Returns:
  /// DataFrame with new frequency
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [1, 2, 3]},
  ///   index: [
  ///     DateTime(2024, 1, 1),
  ///     DateTime(2024, 1, 3),
  ///     DateTime(2024, 1, 5),
  ///   ],
  /// );
  ///
  /// // Convert to daily frequency
  /// var daily = df.asfreq('D', method: 'pad');
  /// ```
  DataFrame asfreq(
    String freq, {
    String method = 'pad',
    dynamic fillValue,
  }) {
    if (!FrequencyUtils.isValidFrequency(freq)) {
      throw ArgumentError('Invalid frequency: $freq');
    }

    // Check if index contains DateTime values
    if (index.isEmpty || index.first is! DateTime) {
      throw ArgumentError('asfreq requires a DateTime index');
    }

    final dateTimes = index.cast<DateTime>();
    final startDate = dateTimes.first;
    final endDate = dateTimes.last;

    // Create new frequency index
    final targetIndex = TimeSeriesIndex.dateRange(
      start: startDate,
      end: endDate,
      frequency: freq,
    );

    final resultData = <List<dynamic>>[];

    for (final targetDate in targetIndex.timestamps) {
      final row = <dynamic>[];

      // Find if this date exists in original index
      final existingIndex = dateTimes.indexWhere(
        (dt) => dt.isAtSameMomentAs(targetDate),
      );

      if (existingIndex >= 0) {
        // Date exists, use original data
        row.addAll(_data[existingIndex]);
      } else {
        // Date doesn't exist, fill using method
        for (int colIdx = 0; colIdx < columns.length; colIdx++) {
          final value = _fillValueForDate(
            targetDate,
            colIdx,
            dateTimes,
            method,
            fillValue,
          );
          row.add(value);
        }
      }

      resultData.add(row);
    }

    return DataFrame(
      resultData,
      columns: columns,
      index: targetIndex.timestamps,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Select values at particular time of day.
  ///
  /// Parameters:
  /// - `time`: Time to select (as TimeOfDay or string 'HH:MM:SS')
  /// - `axis`: Not used (for pandas compatibility)
  ///
  /// Returns:
  /// DataFrame with rows matching the specified time
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [1, 2, 3, 4]},
  ///   index: [
  ///     DateTime(2024, 1, 1, 9, 0),
  ///     DateTime(2024, 1, 1, 12, 0),
  ///     DateTime(2024, 1, 2, 9, 0),
  ///     DateTime(2024, 1, 2, 15, 0),
  ///   ],
  /// );
  ///
  /// // Select all rows at 9:00 AM
  /// var morning = df.atTime('09:00:00');
  /// ```
  DataFrame atTime(String time, {int axis = 0}) {
    if (index.isEmpty || index.first is! DateTime) {
      throw ArgumentError('atTime requires a DateTime index');
    }

    final targetTime = _parseTime(time);
    final filteredData = <List<dynamic>>[];
    final filteredIndex = <DateTime>[];

    for (int i = 0; i < index.length; i++) {
      final dt = index[i] as DateTime;
      if (dt.hour == targetTime.hour &&
          dt.minute == targetTime.minute &&
          dt.second == targetTime.second) {
        filteredData.add(List.from(_data[i]));
        filteredIndex.add(dt);
      }
    }

    return DataFrame(
      filteredData,
      columns: columns,
      index: filteredIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Select values between particular times of day.
  ///
  /// Parameters:
  /// - `startTime`: Start time (as string 'HH:MM:SS')
  /// - `endTime`: End time (as string 'HH:MM:SS')
  /// - `includeStart`: Include start time (default: true)
  /// - `includeEnd`: Include end time (default: true)
  ///
  /// Returns:
  /// DataFrame with rows between the specified times
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [1, 2, 3, 4]},
  ///   index: [
  ///     DateTime(2024, 1, 1, 9, 0),
  ///     DateTime(2024, 1, 1, 12, 0),
  ///     DateTime(2024, 1, 1, 15, 0),
  ///     DateTime(2024, 1, 1, 18, 0),
  ///   ],
  /// );
  ///
  /// // Select rows between 10:00 and 16:00
  /// var business = df.betweenTime('10:00:00', '16:00:00');
  /// ```
  DataFrame betweenTime(
    String startTime,
    String endTime, {
    bool includeStart = true,
    bool includeEnd = true,
  }) {
    if (index.isEmpty || index.first is! DateTime) {
      throw ArgumentError('betweenTime requires a DateTime index');
    }

    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    final filteredData = <List<dynamic>>[];
    final filteredIndex = <DateTime>[];

    for (int i = 0; i < index.length; i++) {
      final dt = index[i] as DateTime;
      final timeInSeconds = dt.hour * 3600 + dt.minute * 60 + dt.second;
      final startInSeconds =
          start.hour * 3600 + start.minute * 60 + start.second;
      final endInSeconds = end.hour * 3600 + end.minute * 60 + end.second;

      bool inRange = false;
      if (includeStart && includeEnd) {
        inRange =
            timeInSeconds >= startInSeconds && timeInSeconds <= endInSeconds;
      } else if (includeStart) {
        inRange =
            timeInSeconds >= startInSeconds && timeInSeconds < endInSeconds;
      } else if (includeEnd) {
        inRange =
            timeInSeconds > startInSeconds && timeInSeconds <= endInSeconds;
      } else {
        inRange =
            timeInSeconds > startInSeconds && timeInSeconds < endInSeconds;
      }

      if (inRange) {
        filteredData.add(List.from(_data[i]));
        filteredIndex.add(dt);
      }
    }

    return DataFrame(
      filteredData,
      columns: columns,
      index: filteredIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Select first n periods of time series data.
  ///
  /// Parameters:
  /// - `offset`: Time offset string (e.g., '3D', '2W', '1M')
  ///
  /// Returns:
  /// DataFrame with first n periods
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [1, 2, 3, 4, 5]},
  ///   index: [
  ///     DateTime(2024, 1, 1),
  ///     DateTime(2024, 1, 5),
  ///     DateTime(2024, 1, 10),
  ///     DateTime(2024, 1, 15),
  ///     DateTime(2024, 1, 20),
  ///   ],
  /// );
  ///
  /// // Select first 7 days
  /// var firstWeek = df.first('7D');
  /// ```
  DataFrame first(String offset) {
    if (index.isEmpty || index.first is! DateTime) {
      throw ArgumentError('first requires a DateTime index');
    }

    final parsed = _parseOffset(offset);
    final startDate = index.first as DateTime;
    final endDate = FrequencyUtils.addPeriods(
      startDate,
      parsed['periods'] as int,
      parsed['freq'] as String,
    );

    final filteredData = <List<dynamic>>[];
    final filteredIndex = <DateTime>[];

    for (int i = 0; i < index.length; i++) {
      final dt = index[i] as DateTime;
      if (dt.isBefore(endDate) || dt.isAtSameMomentAs(endDate)) {
        filteredData.add(List.from(_data[i]));
        filteredIndex.add(dt);
      }
    }

    return DataFrame(
      filteredData,
      columns: columns,
      index: filteredIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Select last n periods of time series data.
  ///
  /// Parameters:
  /// - `offset`: Time offset string (e.g., '3D', '2W', '1M')
  ///
  /// Returns:
  /// DataFrame with last n periods
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [1, 2, 3, 4, 5]},
  ///   index: [
  ///     DateTime(2024, 1, 1),
  ///     DateTime(2024, 1, 5),
  ///     DateTime(2024, 1, 10),
  ///     DateTime(2024, 1, 15),
  ///     DateTime(2024, 1, 20),
  ///   ],
  /// );
  ///
  /// // Select last 7 days
  /// var lastWeek = df.last('7D');
  /// ```
  DataFrame last(String offset) {
    if (index.isEmpty || index.first is! DateTime) {
      throw ArgumentError('last requires a DateTime index');
    }

    final parsed = _parseOffset(offset);
    final endDate = index.last as DateTime;
    final startDate = FrequencyUtils.addPeriods(
      endDate,
      -(parsed['periods'] as int),
      parsed['freq'] as String,
    );

    final filteredData = <List<dynamic>>[];
    final filteredIndex = <DateTime>[];

    for (int i = 0; i < index.length; i++) {
      final dt = index[i] as DateTime;
      if (dt.isAfter(startDate) || dt.isAtSameMomentAs(startDate)) {
        filteredData.add(List.from(_data[i]));
        filteredIndex.add(dt);
      }
    }

    return DataFrame(
      filteredData,
      columns: columns,
      index: filteredIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Parse time string in format 'HH:MM:SS' or 'HH:MM'
  DateTime _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2 || parts.length > 3) {
      throw ArgumentError('Invalid time format. Use HH:MM:SS or HH:MM');
    }

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final second = parts.length == 3 ? int.parse(parts[2]) : 0;

    return DateTime(2000, 1, 1, hour, minute, second);
  }

  /// Parse offset string like '3D', '2W', '1M'
  Map<String, dynamic> _parseOffset(String offset) {
    final match = RegExp(r'(\d+)([HDWMY])').firstMatch(offset);
    if (match == null) {
      throw ArgumentError(
          'Invalid offset format. Use format like "3D", "2W", "1M"');
    }

    return {
      'periods': int.parse(match.group(1)!),
      'freq': match.group(2)!,
    };
  }

  /// Fill value for a specific date using the specified method
  dynamic _fillValueForDate(
    DateTime targetDate,
    int columnIndex,
    List<DateTime> dateTimes,
    String method,
    dynamic fillValue,
  ) {
    final fill = fillValue ?? replaceMissingValueWith;

    switch (method.toLowerCase()) {
      case 'pad':
      case 'ffill':
        // Forward fill - use the last known value before targetDate
        for (int i = dateTimes.length - 1; i >= 0; i--) {
          if (dateTimes[i].isBefore(targetDate) ||
              dateTimes[i].isAtSameMomentAs(targetDate)) {
            return _data[i][columnIndex];
          }
        }
        return fill;

      case 'backfill':
      case 'bfill':
        // Backward fill - use the next known value after targetDate
        for (int i = 0; i < dateTimes.length; i++) {
          if (dateTimes[i].isAfter(targetDate) ||
              dateTimes[i].isAtSameMomentAs(targetDate)) {
            return _data[i][columnIndex];
          }
        }
        return fill;

      case 'nearest':
        // Use the nearest value in time
        int nearestIndex = 0;
        Duration minDifference = (targetDate.difference(dateTimes[0])).abs();

        for (int i = 1; i < dateTimes.length; i++) {
          final difference = (targetDate.difference(dateTimes[i])).abs();
          if (difference < minDifference) {
            minDifference = difference;
            nearestIndex = i;
          }
        }
        return _data[nearestIndex][columnIndex];

      default:
        return fill;
    }
  }

  /// Resample time series data to a different frequency.
  ///
  /// This method provides functionality similar to pandas' resample() method,
  /// allowing you to change the frequency of time series data and apply
  /// aggregation functions.
  ///
  /// Parameters:
  /// - `frequency`: Target frequency string ('D', 'H', 'M', 'Y')
  /// - `dateColumn`: Name of the column containing DateTime values (optional if DataFrame has DateTimeIndex)
  /// - `aggFunc`: Aggregation function to apply ('mean', 'sum', 'min', 'max', 'count', 'first', 'last')
  /// - `label`: Which bin edge label to use ('left' or 'right')
  /// - `closed`: Which side of bin interval is closed ('left' or 'right')
  ///
  /// Returns:
  /// A new DataFrame with resampled data
  ///
  /// Example:
  /// ```dart
  /// // Resample daily data to monthly, taking the mean
  /// var monthlyData = df.resample('M', dateColumn: 'date', aggFunc: 'mean');
  ///
  /// // Resample hourly data to daily, taking the sum
  /// var dailyData = df.resample('D', dateColumn: 'timestamp', aggFunc: 'sum');
  /// ```
  DataFrame resample(
    String frequency, {
    String? dateColumn,
    String aggFunc = 'mean',
    String label = 'left',
    String closed = 'left',
  }) {
    // Validate frequency
    if (!FrequencyUtils.isValidFrequency(frequency)) {
      throw ArgumentError('Invalid frequency: $frequency');
    }

    // Find the date column
    String? actualDateColumn = dateColumn;
    if (actualDateColumn == null) {
      // Try to find a DateTime column automatically
      for (final col in columns) {
        final series = this[col];
        if (series.data.isNotEmpty && series.data.first is DateTime) {
          actualDateColumn = col;
          break;
        }
      }
    }

    if (actualDateColumn == null) {
      throw ArgumentError(
          'No date column specified and no DateTime column found automatically');
    }

    if (!columns.contains(actualDateColumn)) {
      throw ArgumentError(
          'Date column "$actualDateColumn" not found in DataFrame');
    }

    final dateSeriesData = this[actualDateColumn].data;

    // Validate that the date column contains DateTime objects
    final dateTimes = <DateTime>[];
    for (int i = 0; i < dateSeriesData.length; i++) {
      final value = dateSeriesData[i];
      if (value is DateTime) {
        dateTimes.add(value);
      } else if (value != null) {
        throw ArgumentError(
            'Date column "$actualDateColumn" contains non-DateTime values');
      }
    }

    if (dateTimes.isEmpty) {
      throw ArgumentError('No valid DateTime values found in date column');
    }

    // Create time series index from the date column
    final sortedDates = List<DateTime>.from(dateTimes)..sort();
    final timeIndex = TimeSeriesIndex(sortedDates);

    // Determine the resampling range
    final startDate = timeIndex.first;
    final endDate = timeIndex.last;

    // Create the target frequency index
    final targetIndex = TimeSeriesIndex.dateRange(
      start: startDate,
      end: endDate,
      frequency: frequency,
    );

    // Group data by time periods
    final groups = <DateTime, List<int>>{};

    for (int i = 0; i < dateSeriesData.length; i++) {
      final dateValue = dateSeriesData[i];
      if (dateValue is DateTime) {
        final binDate = _findBin(dateValue, targetIndex.timestamps, closed);
        if (binDate != null) {
          groups.putIfAbsent(binDate, () => []).add(i);
        }
      }
    }

    // Apply aggregation function to each group
    final resultData = <List<dynamic>>[];
    final resultIndex = <DateTime>[];

    for (final binDate in targetIndex.timestamps) {
      final rowIndices = groups[binDate] ?? [];

      if (rowIndices.isNotEmpty) {
        final aggregatedRow = <dynamic>[];

        for (final col in columns) {
          if (col == actualDateColumn) {
            // For the date column, use the bin date
            aggregatedRow.add(binDate);
          } else {
            // Apply aggregation function to other columns
            final values = rowIndices
                .map((idx) => this[col].data[idx])
                .where((val) => val != null && val != replaceMissingValueWith)
                .toList();

            final aggregatedValue = _applyAggregation(values, aggFunc);
            aggregatedRow.add(aggregatedValue);
          }
        }

        resultData.add(aggregatedRow);
        resultIndex.add(binDate);
      }
    }

    return DataFrame(
      resultData,
      columns: columns,
      index: resultIndex,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Upsamples the DataFrame to a higher frequency.
  ///
  /// Parameters:
  /// - `frequency`: Target frequency string
  /// - `dateColumn`: Name of the column containing DateTime values
  /// - `method`: Fill method ('pad', 'backfill', 'nearest', 'interpolate')
  ///
  /// Returns:
  /// A new DataFrame with upsampled data
  DataFrame upsample(
    String frequency, {
    String? dateColumn,
    String method = 'pad',
  }) {
    return _resampleWithMethod(frequency, dateColumn, method, isUpsample: true);
  }

  /// Downsamples the DataFrame to a lower frequency.
  ///
  /// Parameters:
  /// - `frequency`: Target frequency string
  /// - `dateColumn`: Name of the column containing DateTime values
  /// - `aggFunc`: Aggregation function to apply
  ///
  /// Returns:
  /// A new DataFrame with downsampled data
  DataFrame downsample(
    String frequency, {
    String? dateColumn,
    String aggFunc = 'mean',
  }) {
    return resample(frequency, dateColumn: dateColumn, aggFunc: aggFunc);
  }

  /// Internal method for resampling with different fill methods
  DataFrame _resampleWithMethod(
    String frequency,
    String? dateColumn,
    String method, {
    bool isUpsample = false,
  }) {
    // Find the date column
    String? actualDateColumn = dateColumn;
    if (actualDateColumn == null) {
      for (final col in columns) {
        final series = this[col];
        if (series.data.isNotEmpty && series.data.first is DateTime) {
          actualDateColumn = col;
          break;
        }
      }
    }

    if (actualDateColumn == null) {
      throw ArgumentError('No date column found');
    }

    final dateSeriesData = this[actualDateColumn].data;
    final dateTimes = dateSeriesData.whereType<DateTime>().toList()..sort();

    if (dateTimes.isEmpty) {
      throw ArgumentError('No valid DateTime values found');
    }

    // Create target frequency index
    final targetIndex = TimeSeriesIndex.dateRange(
      start: dateTimes.first,
      end: dateTimes.last,
      frequency: frequency,
    );

    final resultData = <List<dynamic>>[];

    for (final targetDate in targetIndex.timestamps) {
      final row = <dynamic>[];

      for (final col in columns) {
        if (col == actualDateColumn) {
          row.add(targetDate);
        } else {
          final value = _fillValue(targetDate, col, method);
          row.add(value);
        }
      }

      resultData.add(row);
    }

    return DataFrame(
      resultData,
      columns: columns,
      index: targetIndex.timestamps,
      allowFlexibleColumns: allowFlexibleColumns,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Finds the appropriate bin for a given date
  DateTime? _findBin(DateTime date, List<DateTime> bins, String closed) {
    for (int i = 0; i < bins.length; i++) {
      final binStart = bins[i];
      final binEnd = i < bins.length - 1 ? bins[i + 1] : binStart;

      bool inBin = false;
      if (closed == 'left') {
        inBin = date.isAtSameMomentAs(binStart) ||
            (date.isAfter(binStart) && date.isBefore(binEnd));
      } else {
        inBin = date.isAtSameMomentAs(binEnd) ||
            (date.isAfter(binStart) && date.isBefore(binEnd));
      }

      if (inBin) {
        return binStart;
      }
    }

    return null;
  }

  /// Applies aggregation function to a list of values
  dynamic _applyAggregation(List<dynamic> values, String aggFunc) {
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

      default:
        throw ArgumentError('Unsupported aggregation function: $aggFunc');
    }
  }

  /// Fills a value using the specified method
  dynamic _fillValue(DateTime targetDate, String column, String method) {
    final series = this[column];
    final dateColumn = columns.firstWhere(
      (col) => this[col].data.any((val) => val is DateTime),
      orElse: () => '',
    );

    if (dateColumn.isEmpty) {
      return replaceMissingValueWith;
    }

    final dateSeriesData = this[dateColumn].data;

    switch (method.toLowerCase()) {
      case 'pad':
      case 'ffill':
        // Forward fill - use the last known value before targetDate
        dynamic lastValue = replaceMissingValueWith;
        for (int i = 0; i < dateSeriesData.length; i++) {
          final date = dateSeriesData[i];
          if (date is DateTime && !date.isAfter(targetDate)) {
            lastValue = series.data[i];
          } else {
            break;
          }
        }
        return lastValue;

      case 'backfill':
      case 'bfill':
        // Backward fill - use the next known value after targetDate
        for (int i = 0; i < dateSeriesData.length; i++) {
          final date = dateSeriesData[i];
          if (date is DateTime && !date.isBefore(targetDate)) {
            return series.data[i];
          }
        }
        return replaceMissingValueWith;

      case 'nearest':
        // Use the nearest value in time
        dynamic nearestValue = replaceMissingValueWith;
        Duration? minDifference;

        for (int i = 0; i < dateSeriesData.length; i++) {
          final date = dateSeriesData[i];
          if (date is DateTime) {
            final difference = (targetDate.difference(date)).abs();
            if (minDifference == null || difference < minDifference) {
              minDifference = difference;
              nearestValue = series.data[i];
            }
          }
        }
        return nearestValue;

      default:
        throw ArgumentError('Unsupported fill method: $method');
    }
  }
}
