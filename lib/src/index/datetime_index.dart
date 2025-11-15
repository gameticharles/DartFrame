/// DatetimeIndex implementation with timezone awareness
library;

/// A timezone-aware datetime index.
///
/// Provides pandas-like DatetimeIndex functionality.
class DatetimeIndex {
  final List<DateTime> _timestamps;
  final String? _timezone;
  final String? _name;
  final String? _frequency;

  /// Creates a DatetimeIndex.
  ///
  /// Parameters:
  /// - `timestamps`: List of DateTime objects
  /// - `timezone`: Optional timezone name
  /// - `name`: Optional name for the index
  /// - `frequency`: Optional frequency string
  DatetimeIndex(
    this._timestamps, {
    String? timezone,
    String? name,
    String? frequency,
  })  : _timezone = timezone,
        _name = name,
        _frequency = frequency {
    _validate();
  }

  /// Create DatetimeIndex from date range.
  factory DatetimeIndex.dateRange({
    required DateTime start,
    DateTime? end,
    int? periods,
    String frequency = 'D',
    String? timezone,
    String? name,
  }) {
    if (end == null && periods == null) {
      throw ArgumentError('Either end or periods must be provided');
    }

    final timestamps = <DateTime>[];
    final actualPeriods = periods ?? _calculatePeriods(start, end!, frequency);

    for (int i = 0; i < actualPeriods; i++) {
      timestamps.add(_addFrequency(start, i, frequency));
    }

    return DatetimeIndex(
      timestamps,
      timezone: timezone,
      name: name,
      frequency: frequency,
    );
  }

  /// Number of elements.
  int get length => _timestamps.length;

  /// Timezone name.
  String? get timezone => _timezone;

  /// Index name.
  String? get name => _name;

  /// Frequency string.
  String? get frequency => _frequency;

  /// Get timestamp at index.
  DateTime operator [](int index) => _timestamps[index];

  /// Get all timestamps.
  List<DateTime> get values => List.unmodifiable(_timestamps);

  /// Check if timezone-aware.
  bool get isTimezoneAware => _timezone != null;

  /// Convert to different timezone.
  DatetimeIndex tzConvert(String timezone) {
    if (!isTimezoneAware) {
      throw StateError('Cannot convert timezone-naive DatetimeIndex');
    }

    // For simplicity, we'll keep the same timestamps
    // In a full implementation, this would convert between timezones
    return DatetimeIndex(
      _timestamps,
      timezone: timezone,
      name: _name,
      frequency: _frequency,
    );
  }

  /// Localize timezone-naive to timezone-aware.
  DatetimeIndex tzLocalize(String timezone) {
    if (isTimezoneAware) {
      throw StateError('Cannot localize timezone-aware DatetimeIndex');
    }

    return DatetimeIndex(
      _timestamps,
      timezone: timezone,
      name: _name,
      frequency: _frequency,
    );
  }

  /// Remove timezone information.
  DatetimeIndex tzNaive() {
    return DatetimeIndex(
      _timestamps,
      name: _name,
      frequency: _frequency,
    );
  }

  /// Get year values.
  List<int> get year => _timestamps.map((dt) => dt.year).toList();

  /// Get month values.
  List<int> get month => _timestamps.map((dt) => dt.month).toList();

  /// Get day values.
  List<int> get day => _timestamps.map((dt) => dt.day).toList();

  /// Get hour values.
  List<int> get hour => _timestamps.map((dt) => dt.hour).toList();

  /// Get minute values.
  List<int> get minute => _timestamps.map((dt) => dt.minute).toList();

  /// Get second values.
  List<int> get second => _timestamps.map((dt) => dt.second).toList();

  /// Get day of week (1 = Monday, 7 = Sunday).
  List<int> get dayOfWeek => _timestamps.map((dt) => dt.weekday).toList();

  /// Get day of year.
  List<int> get dayOfYear {
    return _timestamps.map((dt) {
      final firstDay = DateTime(dt.year, 1, 1);
      return dt.difference(firstDay).inDays + 1;
    }).toList();
  }

  /// Validate the index.
  void _validate() {
    if (_timestamps.isEmpty) {
      throw ArgumentError('DatetimeIndex cannot be empty');
    }
  }

  /// Calculate periods between dates.
  static int _calculatePeriods(DateTime start, DateTime end, String frequency) {
    switch (frequency.toUpperCase()) {
      case 'D':
        return end.difference(start).inDays + 1;
      case 'H':
        return end.difference(start).inHours + 1;
      case 'M':
        int months = (end.year - start.year) * 12 + (end.month - start.month);
        if (end.day >= start.day) months++;
        return months;
      case 'Y':
        return end.year - start.year + 1;
      default:
        throw ArgumentError('Unsupported frequency: $frequency');
    }
  }

  /// Add frequency to date.
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

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('DatetimeIndex(');
    if (_name != null) buffer.write('name=$_name, ');
    if (_timezone != null) buffer.write('tz=$_timezone, ');
    if (_frequency != null) buffer.write('freq=$_frequency, ');
    buffer.write('length=$length)');
    return buffer.toString();
  }
}

/// TimedeltaIndex for time differences.
class TimedeltaIndex {
  final List<Duration> _durations;
  final String? _name;

  /// Creates a TimedeltaIndex.
  TimedeltaIndex(this._durations, {String? name}) : _name = name;

  /// Number of elements.
  int get length => _durations.length;

  /// Index name.
  String? get name => _name;

  /// Get duration at index.
  Duration operator [](int index) => _durations[index];

  /// Get all durations.
  List<Duration> get values => List.unmodifiable(_durations);

  /// Get total seconds for each duration.
  List<int> get totalSeconds => _durations.map((d) => d.inSeconds).toList();

  /// Get days component.
  List<int> get days => _durations.map((d) => d.inDays).toList();

  /// Get hours component.
  List<int> get hours => _durations.map((d) => d.inHours % 24).toList();

  /// Get minutes component.
  List<int> get minutes => _durations.map((d) => d.inMinutes % 60).toList();

  /// Get seconds component.
  List<int> get seconds => _durations.map((d) => d.inSeconds % 60).toList();

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('TimedeltaIndex(');
    if (_name != null) buffer.write('name=$_name, ');
    buffer.write('length=$length)');
    return buffer.toString();
  }
}

/// PeriodIndex for time periods.
class PeriodIndex {
  final List<Period> _periods;
  final String _frequency;
  final String? _name;

  /// Creates a PeriodIndex.
  PeriodIndex(this._periods, this._frequency, {String? name}) : _name = name;

  /// Create PeriodIndex from date range.
  factory PeriodIndex.periodRange({
    required DateTime start,
    DateTime? end,
    int? periods,
    required String frequency,
    String? name,
  }) {
    if (end == null && periods == null) {
      throw ArgumentError('Either end or periods must be provided');
    }

    final periodList = <Period>[];
    final actualPeriods =
        periods ?? DatetimeIndex._calculatePeriods(start, end!, frequency);

    for (int i = 0; i < actualPeriods; i++) {
      final date = DatetimeIndex._addFrequency(start, i, frequency);
      periodList.add(Period(date, frequency));
    }

    return PeriodIndex(periodList, frequency, name: name);
  }

  /// Number of elements.
  int get length => _periods.length;

  /// Frequency string.
  String get frequency => _frequency;

  /// Index name.
  String? get name => _name;

  /// Get period at index.
  Period operator [](int index) => _periods[index];

  /// Get all periods.
  List<Period> get values => List.unmodifiable(_periods);

  /// Convert to DatetimeIndex (start of period).
  DatetimeIndex toTimestamp({String how = 'start'}) {
    final timestamps = _periods.map((p) {
      return how == 'start' ? p.startTime : p.endTime;
    }).toList();

    return DatetimeIndex(timestamps, name: _name, frequency: _frequency);
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('PeriodIndex(');
    if (_name != null) buffer.write('name=$_name, ');
    buffer.write('freq=$_frequency, length=$length)');
    return buffer.toString();
  }
}

/// Represents a time period.
class Period {
  final DateTime _date;
  final String _frequency;

  Period(this._date, this._frequency);

  /// Start time of the period.
  DateTime get startTime {
    switch (_frequency.toUpperCase()) {
      case 'D':
        return DateTime(_date.year, _date.month, _date.day);
      case 'M':
        return DateTime(_date.year, _date.month, 1);
      case 'Y':
        return DateTime(_date.year, 1, 1);
      default:
        return _date;
    }
  }

  /// End time of the period.
  DateTime get endTime {
    switch (_frequency.toUpperCase()) {
      case 'D':
        return DateTime(_date.year, _date.month, _date.day, 23, 59, 59);
      case 'M':
        return DateTime(_date.year, _date.month + 1, 0, 23, 59, 59);
      case 'Y':
        return DateTime(_date.year, 12, 31, 23, 59, 59);
      default:
        return _date;
    }
  }

  @override
  String toString() =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}';
}
