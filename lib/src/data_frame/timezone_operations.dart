part of 'data_frame.dart';

/// Timezone operations for DataFrame
extension DataFrameTimezoneOperations on DataFrame {
  /// Localize timezone-naive DateTimeIndex to timezone-aware.
  ///
  /// Parameters:
  /// - `tz`: Timezone name (e.g., 'UTC', 'America/New_York', 'Europe/London')
  /// - `ambiguous`: How to handle ambiguous times ('raise', 'infer', 'NaT')
  /// - `nonexistent`: How to handle nonexistent times ('raise', 'shift_forward', 'shift_backward', 'NaT')
  ///
  /// Returns:
  /// DataFrame with timezone-aware index
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [1, 2, 3]},
  ///   index: [
  ///     DateTime(2024, 1, 1, 12, 0),
  ///     DateTime(2024, 1, 2, 12, 0),
  ///     DateTime(2024, 1, 3, 12, 0),
  ///   ],
  /// );
  ///
  /// // Localize to UTC
  /// var dfUtc = df.tzLocalize('UTC');
  ///
  /// // Localize to New York time
  /// var dfNy = df.tzLocalize('America/New_York');
  /// ```
  DataFrame tzLocalize(
    String tz, {
    String ambiguous = 'raise',
    String nonexistent = 'raise',
  }) {
    if (index.isEmpty || index.first is! DateTime) {
      throw ArgumentError('tzLocalize requires a DateTime index');
    }

    final newIndex = <DateTime>[];

    for (var idx in index) {
      if (idx is DateTime) {
        if (idx.isUtc) {
          throw ArgumentError(
              'Cannot localize timezone-aware datetime. Use tzConvert instead.');
        }

        // Convert to timezone-aware DateTime
        final tzAware = _localizeDateTime(idx, tz, ambiguous, nonexistent);
        newIndex.add(tzAware);
      } else {
        throw ArgumentError('All index values must be DateTime for tzLocalize');
      }
    }

    return DataFrame(
      _data.map((row) => List.from(row)).toList(),
      columns: columns,
      index: newIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Convert timezone-aware DateTimeIndex to another timezone.
  ///
  /// Parameters:
  /// - `tz`: Target timezone name (e.g., 'UTC', 'America/New_York', 'Europe/London')
  ///
  /// Returns:
  /// DataFrame with index converted to target timezone
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [1, 2, 3]},
  ///   index: [
  ///     DateTime.utc(2024, 1, 1, 12, 0),
  ///     DateTime.utc(2024, 1, 2, 12, 0),
  ///     DateTime.utc(2024, 1, 3, 12, 0),
  ///   ],
  /// );
  ///
  /// // Convert from UTC to New York time
  /// var dfNy = df.tzConvert('America/New_York');
  ///
  /// // Convert to Tokyo time
  /// var dfTokyo = df.tzConvert('Asia/Tokyo');
  /// ```
  DataFrame tzConvert(String tz) {
    if (index.isEmpty || index.first is! DateTime) {
      throw ArgumentError('tzConvert requires a DateTime index');
    }

    final newIndex = <DateTime>[];

    for (var idx in index) {
      if (idx is DateTime) {
        if (!idx.isUtc) {
          throw ArgumentError(
              'Cannot convert timezone-naive datetime. Use tzLocalize first.');
        }

        // Convert to target timezone
        final converted = _convertDateTime(idx, tz);
        newIndex.add(converted);
      } else {
        throw ArgumentError('All index values must be DateTime for tzConvert');
      }
    }

    return DataFrame(
      _data.map((row) => List.from(row)).toList(),
      columns: columns,
      index: newIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Remove timezone information from timezone-aware DateTimeIndex.
  ///
  /// Returns:
  /// DataFrame with timezone-naive index
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap(
  ///   {'value': [1, 2, 3]},
  ///   index: [
  ///     DateTime.utc(2024, 1, 1, 12, 0),
  ///     DateTime.utc(2024, 1, 2, 12, 0),
  ///     DateTime.utc(2024, 1, 3, 12, 0),
  ///   ],
  /// );
  ///
  /// // Remove timezone info
  /// var dfNaive = df.tzNaive();
  /// ```
  DataFrame tzNaive() {
    if (index.isEmpty || index.first is! DateTime) {
      throw ArgumentError('tzNaive requires a DateTime index');
    }

    final newIndex = <DateTime>[];

    for (var idx in index) {
      if (idx is DateTime) {
        // Convert to local time without timezone
        final naive = DateTime(
          idx.year,
          idx.month,
          idx.day,
          idx.hour,
          idx.minute,
          idx.second,
          idx.millisecond,
          idx.microsecond,
        );
        newIndex.add(naive);
      } else {
        throw ArgumentError('All index values must be DateTime for tzNaive');
      }
    }

    return DataFrame(
      _data.map((row) => List.from(row)).toList(),
      columns: columns,
      index: newIndex,
      replaceMissingValueWith: replaceMissingValueWith,
    );
  }

  /// Localize a DateTime to a specific timezone.
  ///
  /// Note: Dart's DateTime doesn't have full timezone support built-in.
  /// This is a simplified implementation that works with UTC offsets.
  /// For full timezone support, consider using the 'timezone' package.
  DateTime _localizeDateTime(
    DateTime dt,
    String tz,
    String ambiguous,
    String nonexistent,
  ) {
    // Handle UTC specially
    if (tz.toUpperCase() == 'UTC') {
      return DateTime.utc(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
        dt.millisecond,
        dt.microsecond,
      );
    }

    // For other timezones, we need the timezone package
    // This is a simplified implementation
    final offset = _getTimezoneOffset(tz);

    return DateTime.utc(
      dt.year,
      dt.month,
      dt.day,
      dt.hour - offset.inHours,
      dt.minute - (offset.inMinutes % 60),
      dt.second,
      dt.millisecond,
      dt.microsecond,
    );
  }

  /// Convert a DateTime from one timezone to another.
  DateTime _convertDateTime(DateTime dt, String tz) {
    if (!dt.isUtc) {
      throw ArgumentError('DateTime must be UTC for conversion');
    }

    // Handle UTC specially
    if (tz.toUpperCase() == 'UTC') {
      return dt;
    }

    // For other timezones, apply offset
    final offset = _getTimezoneOffset(tz);

    return dt.add(offset);
  }

  /// Get timezone offset for common timezones.
  ///
  /// Note: This is a simplified implementation. For production use,
  /// consider using the 'timezone' package which has full IANA timezone database.
  Duration _getTimezoneOffset(String tz) {
    // Common timezone offsets (simplified, doesn't handle DST)
    final offsets = <String, Duration>{
      'UTC': Duration.zero,
      'GMT': Duration.zero,
      'EST': Duration(hours: -5),
      'EDT': Duration(hours: -4),
      'CST': Duration(hours: -6),
      'CDT': Duration(hours: -5),
      'MST': Duration(hours: -7),
      'MDT': Duration(hours: -6),
      'PST': Duration(hours: -8),
      'PDT': Duration(hours: -7),
      'America/New_York': Duration(hours: -5),
      'America/Chicago': Duration(hours: -6),
      'America/Denver': Duration(hours: -7),
      'America/Los_Angeles': Duration(hours: -8),
      'Europe/London': Duration.zero,
      'Europe/Paris': Duration(hours: 1),
      'Europe/Berlin': Duration(hours: 1),
      'Asia/Tokyo': Duration(hours: 9),
      'Asia/Shanghai': Duration(hours: 8),
      'Asia/Hong_Kong': Duration(hours: 8),
      'Asia/Singapore': Duration(hours: 8),
      'Asia/Dubai': Duration(hours: 4),
      'Australia/Sydney': Duration(hours: 10),
      'Pacific/Auckland': Duration(hours: 12),
    };

    if (offsets.containsKey(tz)) {
      return offsets[tz]!;
    }

    // Try to parse as offset string like '+05:30' or '-08:00'
    final offsetMatch = RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(tz);
    if (offsetMatch != null) {
      final sign = offsetMatch.group(1) == '+' ? 1 : -1;
      final hours = int.parse(offsetMatch.group(2)!);
      final minutes = int.parse(offsetMatch.group(3)!);
      return Duration(hours: sign * hours, minutes: sign * minutes);
    }

    throw ArgumentError(
        'Unknown timezone: $tz. Use UTC, common timezone names, or offset format (+HH:MM)');
  }
}

/// Helper class for timezone-aware operations
class TimezoneInfo {
  final String name;
  final Duration offset;
  final bool isDst;

  TimezoneInfo({
    required this.name,
    required this.offset,
    this.isDst = false,
  });

  @override
  String toString() => 'TimezoneInfo($name, offset: $offset, DST: $isDst)';
}
