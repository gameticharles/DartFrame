import 'dart:math' as math;

/// Represents a time series index with timestamps and frequency information.
///
/// This class provides functionality similar to pandas' DatetimeIndex,
/// allowing for time-based indexing and operations on time series data.
class TimeSeriesIndex {
  final List<DateTime> _timestamps;
  final String? _frequency;
  final String? _name;

  /// Creates a TimeSeriesIndex with the given timestamps and optional frequency.
  ///
  /// Parameters:
  /// - `timestamps`: List of DateTime objects representing the time index
  /// - `frequency`: Optional frequency string (e.g., 'D', 'H', 'M', 'Y')
  /// - `name`: Optional name for the index
  TimeSeriesIndex(
    this._timestamps, {
    String? frequency,
    String? name,
  })  : _frequency = frequency,
        _name = name {
    if (_timestamps.isEmpty) {
      throw ArgumentError('TimeSeriesIndex cannot be empty');
    }

    // Validate that timestamps are sorted
    for (int i = 1; i < _timestamps.length; i++) {
      if (_timestamps[i].isBefore(_timestamps[i - 1])) {
        throw ArgumentError('Timestamps must be in ascending order');
      }
    }
  }

  /// Private constructor for creating empty TimeSeriesIndex
  TimeSeriesIndex._empty({
    String? frequency,
    String? name,
  })  : _timestamps = [],
        _frequency = frequency,
        _name = name;

  /// Creates a TimeSeriesIndex from a date range.
  ///
  /// Parameters:
  /// - `start`: Start date
  /// - `end`: End date (optional if periods is provided)
  /// - `periods`: Number of periods (optional if end is provided)
  /// - `frequency`: Frequency string ('D', 'H', 'M', 'Y')
  /// - `name`: Optional name for the index
  factory TimeSeriesIndex.dateRange({
    required DateTime start,
    DateTime? end,
    int? periods,
    String frequency = 'D',
    String? name,
  }) {
    if (end == null && periods == null) {
      throw ArgumentError('Either end or periods must be provided');
    }

    if (end != null && periods != null) {
      // Validate consistency
      final expectedPeriods = _calculatePeriods(start, end, frequency);
      if (expectedPeriods != periods) {
        throw ArgumentError(
            'Inconsistent parameters: expected $expectedPeriods periods but got $periods');
      }
    }

    final timestamps = <DateTime>[];
    final actualPeriods = periods ?? _calculatePeriods(start, end!, frequency);

    for (int i = 0; i < actualPeriods; i++) {
      timestamps.add(_addFrequency(start, i, frequency));
    }

    return TimeSeriesIndex(
      timestamps,
      frequency: frequency,
      name: name,
    );
  }

  /// The timestamps in this index
  List<DateTime> get timestamps => List.unmodifiable(_timestamps);

  /// The frequency of this index
  String? get frequency => _frequency;

  /// The name of this index
  String? get name => _name;

  /// The number of timestamps in this index
  int get length => _timestamps.length;

  /// Whether this index is empty
  bool get isEmpty => _timestamps.isEmpty;

  /// Whether this index is not empty
  bool get isNotEmpty => _timestamps.isNotEmpty;

  /// The first timestamp in this index
  DateTime get first {
    if (_timestamps.isEmpty) {
      throw StateError('Cannot get first element of empty TimeSeriesIndex');
    }
    return _timestamps.first;
  }

  /// The last timestamp in this index
  DateTime get last {
    if (_timestamps.isEmpty) {
      throw StateError('Cannot get last element of empty TimeSeriesIndex');
    }
    return _timestamps.last;
  }

  /// Access timestamp by index
  DateTime operator [](int index) => _timestamps[index];

  /// Detects the frequency of the time series based on the timestamps.
  ///
  /// Returns a frequency string if a consistent pattern is detected,
  /// or null if no consistent frequency is found.
  String? detectFrequency() {
    if (_timestamps.length < 2) {
      return null;
    }

    final differences = <Duration>[];
    for (int i = 1; i < _timestamps.length; i++) {
      differences.add(_timestamps[i].difference(_timestamps[i - 1]));
    }

    // Check if all differences are the same
    final firstDiff = differences.first;
    if (differences.every((diff) => diff == firstDiff)) {
      return _durationToFrequency(firstDiff);
    }

    return null;
  }

  /// Converts this TimeSeriesIndex to a different frequency.
  ///
  /// Parameters:
  /// - `newFrequency`: Target frequency string
  /// - `method`: Resampling method ('nearest', 'pad', 'backfill')
  TimeSeriesIndex asFreq(String newFrequency, {String method = 'nearest'}) {
    if (_frequency == newFrequency) {
      return this;
    }

    final newStart = first;
    final newEnd = last;
    final newPeriods = _calculatePeriods(newStart, newEnd, newFrequency);

    final newTimestamps = <DateTime>[];
    for (int i = 0; i < newPeriods; i++) {
      newTimestamps.add(_addFrequency(newStart, i, newFrequency));
    }

    return TimeSeriesIndex(
      newTimestamps,
      frequency: newFrequency,
      name: _name,
    );
  }

  /// Checks if this index contains the given timestamp
  bool contains(DateTime timestamp) {
    return _timestamps.contains(timestamp);
  }

  /// Finds the index of the given timestamp
  int indexOf(DateTime timestamp) {
    return _timestamps.indexOf(timestamp);
  }

  /// Returns a subset of this index between start and end dates
  TimeSeriesIndex slice(DateTime start, DateTime end) {
    final startIndex = _timestamps.indexWhere((ts) => !ts.isBefore(start));
    final endIndex = _timestamps.lastIndexWhere((ts) => !ts.isAfter(end));

    if (startIndex == -1 || endIndex == -1 || startIndex > endIndex) {
      // Return an empty TimeSeriesIndex by creating one with a single dummy timestamp
      // and then returning an empty slice
      return TimeSeriesIndex._empty(frequency: _frequency, name: _name);
    }

    return TimeSeriesIndex(
      _timestamps.sublist(startIndex, endIndex + 1),
      frequency: _frequency,
      name: _name,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('TimeSeriesIndex(');

    final displayCount = math.min(10, _timestamps.length);
    for (int i = 0; i < displayCount; i++) {
      buffer.writeln('  ${_timestamps[i]}');
    }

    if (_timestamps.length > displayCount) {
      buffer.writeln('  ... (${_timestamps.length - displayCount} more)');
    }

    buffer.write(')');
    if (_frequency != null) {
      buffer.write(' freq=$_frequency');
    }
    if (_name != null) {
      buffer.write(' name=$_name');
    }

    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimeSeriesIndex) return false;

    return _listEquals(_timestamps, other._timestamps) &&
        _frequency == other._frequency &&
        _name == other._name;
  }

  @override
  int get hashCode {
    return Object.hash(
      _timestamps.fold<int>(0, (hash, ts) => hash ^ ts.hashCode),
      _frequency?.hashCode ?? 0,
      _name?.hashCode ?? 0,
    );
  }

  /// Helper method to check if two lists of DateTime are equal
  bool _listEquals(List<DateTime> a, List<DateTime> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Calculates the number of periods between start and end for a given frequency
  static int _calculatePeriods(DateTime start, DateTime end, String frequency) {
    switch (frequency.toUpperCase()) {
      case 'D':
        return end.difference(start).inDays + 1;
      case 'H':
        return end.difference(start).inHours + 1;
      case 'M':
        // Monthly calculation is more complex
        int months = (end.year - start.year) * 12 + (end.month - start.month);
        if (end.day >= start.day) months++;
        return months;
      case 'Y':
        return end.year - start.year + 1;
      default:
        throw ArgumentError('Unsupported frequency: $frequency');
    }
  }

  /// Adds frequency intervals to a start date
  static DateTime _addFrequency(DateTime start, int periods, String frequency) {
    switch (frequency.toUpperCase()) {
      case 'D':
        return start.add(Duration(days: periods));
      case 'H':
        return start.add(Duration(hours: periods));
      case 'M':
        return DateTime(start.year, start.month + periods, start.day);
      case 'Y':
        return DateTime(start.year + periods, start.month, start.day);
      default:
        throw ArgumentError('Unsupported frequency: $frequency');
    }
  }

  /// Converts a Duration to a frequency string
  static String? _durationToFrequency(Duration duration) {
    if (duration.inDays == 1 && duration.inHours == 24) {
      return 'D';
    } else if (duration.inHours == 1 && duration.inMinutes == 60) {
      return 'H';
    }
    // For monthly and yearly frequencies, we'd need more sophisticated logic
    return null;
  }
}

/// Frequency utilities for time series operations
class FrequencyUtils {
  /// Common frequency aliases
  static const Map<String, String> frequencyAliases = {
    'daily': 'D',
    'hourly': 'H',
    'monthly': 'M',
    'yearly': 'Y',
    'annual': 'Y',
  };

  /// Normalizes a frequency string to its canonical form
  static String normalizeFrequency(String frequency) {
    final normalized = frequency.toLowerCase();
    return frequencyAliases[normalized] ?? frequency.toUpperCase();
  }

  /// Validates if a frequency string is supported
  static bool isValidFrequency(String frequency) {
    final normalized = normalizeFrequency(frequency);
    return ['D', 'H', 'M', 'Y'].contains(normalized);
  }

  /// Gets the duration for a single period of the given frequency
  static Duration? getFrequencyDuration(String frequency) {
    switch (normalizeFrequency(frequency)) {
      case 'D':
        return const Duration(days: 1);
      case 'H':
        return const Duration(hours: 1);
      case 'M':
      case 'Y':
        // Monthly and yearly durations are variable, return null
        return null;
      default:
        return null;
    }
  }

  /// Converts frequency to a human-readable description
  static String frequencyDescription(String frequency) {
    switch (normalizeFrequency(frequency)) {
      case 'D':
        return 'Daily';
      case 'H':
        return 'Hourly';
      case 'M':
        return 'Monthly';
      case 'Y':
        return 'Yearly';
      default:
        return 'Unknown frequency: $frequency';
    }
  }
}
