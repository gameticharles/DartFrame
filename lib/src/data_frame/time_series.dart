part of 'data_frame.dart';

/// Time series operations for DataFrame
extension DataFrameTimeSeries on DataFrame {
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
        'No date column specified and no DateTime column found automatically'
      );
    }

    if (!columns.contains(actualDateColumn)) {
      throw ArgumentError('Date column "$actualDateColumn" not found in DataFrame');
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
          'Date column "$actualDateColumn" contains non-DateTime values'
        );
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

