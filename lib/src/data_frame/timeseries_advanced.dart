part of 'data_frame.dart';

/// Extension for advanced DataFrame time series operations
extension DataFrameTimeSeriesAdvanced on DataFrame {
  /// Infer the most likely frequency given the input index.
  ///
  /// Returns:
  ///   String representing the inferred frequency or null if cannot infer
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'value': [1, 2, 3, 4],
  /// }, index: [
  ///   DateTime(2023, 1, 1),
  ///   DateTime(2023, 1, 2),
  ///   DateTime(2023, 1, 3),
  ///   DateTime(2023, 1, 4),
  /// ]);
  ///
  /// var freq = df.inferFreq();
  /// print(freq); // 'D' for daily
  /// ```
  String? inferFreq() {
    if (index.length < 2) return null;

    // Check if index contains DateTime objects
    final datetimeIndices = index.whereType<DateTime>().toList();
    if (datetimeIndices.length < 2) return null;

    // Calculate differences between consecutive dates
    final differences = <Duration>[];
    for (int i = 1; i < datetimeIndices.length; i++) {
      differences.add(datetimeIndices[i].difference(datetimeIndices[i - 1]));
    }

    // Check if all differences are the same
    final firstDiff = differences.first;
    final allSame = differences.every((diff) => diff == firstDiff);

    if (!allSame) return null;

    // Infer frequency based on the difference
    final days = firstDiff.inDays;
    final hours = firstDiff.inHours;
    final minutes = firstDiff.inMinutes;
    final seconds = firstDiff.inSeconds;

    if (days == 1) return 'D'; // Daily
    if (days == 7) return 'W'; // Weekly
    if (days >= 28 && days <= 31) return 'M'; // Monthly (approximate)
    if (days >= 365 && days <= 366) return 'Y'; // Yearly
    if (hours == 1) return 'H'; // Hourly
    if (minutes == 1) return 'T'; // Minutely
    if (seconds == 1) return 'S'; // Secondly

    return null; // Cannot infer
  }

  /// Convert DatetimeIndex to PeriodIndex.
  ///
  /// Parameters:
  ///   - `freq`: Frequency to convert to ('D', 'M', 'Y', etc.)
  ///
  /// Returns:
  ///   DataFrame with PeriodIndex
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'value': [1, 2, 3],
  /// }, index: [
  ///   DateTime(2023, 1, 15),
  ///   DateTime(2023, 2, 15),
  ///   DateTime(2023, 3, 15),
  /// ]);
  ///
  /// var periods = df.toPeriod('M');
  /// ```
  DataFrame toPeriod(String freq) {
    final newIndex = <String>[];

    for (final idx in index) {
      if (idx is DateTime) {
        String period;
        switch (freq.toUpperCase()) {
          case 'D':
            period =
                '${idx.year}-${idx.month.toString().padLeft(2, '0')}-${idx.day.toString().padLeft(2, '0')}';
            break;
          case 'M':
            period = '${idx.year}-${idx.month.toString().padLeft(2, '0')}';
            break;
          case 'Y':
            period = '${idx.year}';
            break;
          case 'Q':
            final quarter = ((idx.month - 1) ~/ 3) + 1;
            period = '${idx.year}Q$quarter';
            break;
          case 'H':
            period =
                '${idx.year}-${idx.month.toString().padLeft(2, '0')}-${idx.day.toString().padLeft(2, '0')} ${idx.hour.toString().padLeft(2, '0')}';
            break;
          default:
            period = idx.toString();
        }
        newIndex.add(period);
      } else {
        newIndex.add(idx.toString());
      }
    }

    // Create new DataFrame with updated index
    final newData = <String, List<dynamic>>{};
    for (final col in _columns) {
      newData[col.toString()] = column(col).data;
    }
    return DataFrame.fromMap(newData, index: newIndex);
  }

  /// Convert PeriodIndex to DatetimeIndex.
  ///
  /// Parameters:
  ///   - `freq`: Frequency of the periods
  ///   - `how`: How to convert ('start', 'end')
  ///
  /// Returns:
  ///   DataFrame with DatetimeIndex
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'value': [1, 2, 3],
  /// }, index: ['2023-01', '2023-02', '2023-03']);
  ///
  /// var timestamps = df.toTimestamp('M', how: 'start');
  /// ```
  DataFrame toTimestamp(String freq, {String how = 'start'}) {
    final newIndex = <DateTime>[];

    for (final idx in index) {
      final idxStr = idx.toString();
      DateTime? dateTime;

      try {
        switch (freq.toUpperCase()) {
          case 'D':
            dateTime = DateTime.parse(idxStr);
            break;
          case 'M':
            final parts = idxStr.split('-');
            if (parts.length >= 2) {
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              dateTime = how == 'start'
                  ? DateTime(year, month, 1)
                  : DateTime(year, month + 1, 0); // Last day of month
            }
            break;
          case 'Y':
            final year = int.parse(idxStr);
            dateTime =
                how == 'start' ? DateTime(year, 1, 1) : DateTime(year, 12, 31);
            break;
          case 'Q':
            final match = RegExp(r'(\d{4})Q(\d)').firstMatch(idxStr);
            if (match != null) {
              final year = int.parse(match.group(1)!);
              final quarter = int.parse(match.group(2)!);
              final month = (quarter - 1) * 3 + 1;
              dateTime = how == 'start'
                  ? DateTime(year, month, 1)
                  : DateTime(year, month + 2, 0); // Last day of quarter
            }
            break;
        }
      } catch (e) {
        // If parsing fails, use current time
        dateTime = DateTime.now();
      }

      newIndex.add(dateTime ?? DateTime.now());
    }

    // Create new DataFrame with updated index
    final newData = <String, List<dynamic>>{};
    for (final col in _columns) {
      newData[col.toString()] = column(col).data;
    }
    return DataFrame.fromMap(newData, index: newIndex);
  }

  /// Normalize DatetimeIndex to midnight.
  ///
  /// Returns:
  ///   DataFrame with normalized DatetimeIndex
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'value': [1, 2, 3],
  /// }, index: [
  ///   DateTime(2023, 1, 1, 14, 30),
  ///   DateTime(2023, 1, 2, 9, 15),
  ///   DateTime(2023, 1, 3, 18, 45),
  /// ]);
  ///
  /// var normalized = df.normalize();
  /// ```
  DataFrame normalize() {
    final newIndex = <dynamic>[];

    for (final idx in index) {
      if (idx is DateTime) {
        newIndex.add(DateTime(idx.year, idx.month, idx.day));
      } else {
        newIndex.add(idx);
      }
    }

    // Create new DataFrame with updated index
    final newData = <String, List<dynamic>>{};
    for (final col in _columns) {
      newData[col.toString()] = column(col).data;
    }
    return DataFrame.fromMap(newData, index: newIndex);
  }
}
