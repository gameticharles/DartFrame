/// Represents a MATLAB object (custom class instance)
///
/// MATLAB objects are stored in v7.3 files as structures with a class name.
/// Since we can't reconstruct the actual MATLAB class methods in Dart,
/// we provide read-only access to the object's properties.
class MatlabObject {
  /// Name of the MATLAB class
  final String className;

  /// Object properties (fields) as key-value pairs
  final Map<String, dynamic> properties;

  MatlabObject({
    required this.className,
    required this.properties,
  });

  /// Get a property value
  dynamic operator [](String property) => properties[property];

  /// Check if property exists
  bool hasProperty(String property) => properties.containsKey(property);

  /// Get all property names
  List<String> get propertyNames => properties.keys.toList();

  @override
  String toString() {
    final propList = properties.keys.take(5).join(', ');
    final more = properties.length > 5 ? '...' : '';
    return 'MatlabObject<$className>($propList$more)';
  }

  /// Convert to a detailed string representation
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('MATLAB Object: $className');
    buffer.writeln('Properties:');
    for (final entry in properties.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    return buffer.toString();
  }

  /// Convert to Map (loses class information)
  Map<String, dynamic> toMap() => Map.unmodifiable(properties);
}

/// Represents a MATLAB datetime value
///
/// MATLAB datetime is stored as a floating-point number representing
/// days since January 0, 0000 (MATLAB's epoch)
class MatlabDateTime {
  /// The Dart DateTime representation
  final DateTime dateTime;

  /// Optional timezone
  final String? timezone;

  /// Optional format string
  final String? format;

  MatlabDateTime({
    required this.dateTime,
    this.timezone,
    this.format,
  });

  /// Create from MATLAB serial date number
  ///
  /// MATLAB's epoch is January 0, 0000 (actually December 31, -0001 in proleptic Gregorian)
  /// This is different from Unix epoch (January 1, 1970)
  static MatlabDateTime fromSerial(
    double serial, {
    String? timezone,
    String? format,
  }) {
    // MATLAB epoch: January 1, 0000 (but 0000 doesn't exist, so it's Dec 31, -0001)
    // We'll use a reference date and calculate offset
    // MATLAB datenum(1970,1,1) = 719529 (Unix epoch in MATLAB serial)

    const unixEpochSerialDate = 719529;
    final daysSinceUnixEpoch = serial - unixEpochSerialDate;

    final milliseconds = (daysSinceUnixEpoch * 24 * 60 * 60 * 1000).round();
    final dt = DateTime.fromMillisecondsSinceEpoch(milliseconds,
        isUtc: timezone == null);

    return MatlabDateTime(
      dateTime: dt,
      timezone: timezone,
      format: format,
    );
  }

  /// Create a list of MatlabDateTime from serial date numbers
  static List<MatlabDateTime> fromSerialList(
    List<double> serials, {
    String? timezone,
    String? format,
  }) {
    return serials
        .map((s) => fromSerial(s, timezone: timezone, format: format))
        .toList();
  }

  @override
  String toString() {
    if (timezone != null) {
      return '${dateTime.toIso8601String()} ($timezone)';
    }
    return dateTime.toIso8601String();
  }
}

/// Represents a MATLAB duration value
///
/// MATLAB duration is stored as a floating-point number representing days
class MatlabDuration {
  /// The Dart Duration representation
  final Duration duration;

  /// Optional format (e.g., 'hh:mm:ss')
  final String? format;

  MatlabDuration({
    required this.duration,
    this.format,
  });

  /// Create from MATLAB duration value (days)
  static MatlabDuration fromDays(double days, {String? format}) {
    final microseconds = (days * 24 * 60 * 60 * 1000000).round();
    return MatlabDuration(
      duration: Duration(microseconds: microseconds),
      format: format,
    );
  }

  /// Create a list of MatlabDuration from day values
  static List<MatlabDuration> fromDaysList(
    List<double> days, {
    String? format,
  }) {
    return days.map((d) => fromDays(d, format: format)).toList();
  }

  /// Get duration in hours
  double get inHours => duration.inMicroseconds / (60 * 60 * 1000000);

  /// Get duration in days
  double get inDays => duration.inMicroseconds / (24 * 60 * 60 * 1000000);

  @override
  String toString() {
    if (format != null) {
      // Custom format - would need parsing
      return duration.toString();
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours}h ${minutes}m ${seconds}s';
  }
}

/// Represents a MATLAB categorical array
///
/// Categorical arrays store data as indices into a list of categories
class CategoricalArray {
  /// Numeric codes (indices into categories)
  final List<int> codes;

  /// Category labels
  final List<String> categories;

  /// Whether the categories are ordered
  final bool isOrdinal;

  /// Optional category names for missing values
  final List<String>? undefinedCategories;

  CategoricalArray({
    required this.codes,
    required this.categories,
    this.isOrdinal = false,
    this.undefinedCategories,
  });

  /// Get the categorical values as strings
  List<String> get values {
    return codes.map((code) {
      if (code < 0 || code >= categories.length) {
        return '<undefined>';
      }
      return categories[code];
    }).toList();
  }

  /// Get value at index
  String operator [](int index) {
    final code = codes[index];
    if (code < 0 || code >= categories.length) {
      return '<undefined>';
    }
    return categories[code];
  }

  /// Get unique categories
  List<String> get uniqueCategories => categories;

  /// Get category count
  int get categoryCount => categories.length;

  /// Get array length
  int get length => codes.length;

  /// Convert to list of strings
  List<String> toList() => values;

  @override
  String toString() {
    final preview = values.take(5).join(', ');
    final more = length > 5 ? '...' : '';
    final ordinal = isOrdinal ? ' (ordinal)' : '';
    return 'Categorical[$length]$ordinal: $preview$more';
  }

  /// Get detailed statistics
  Map<String, dynamic> get statistics {
    final counts = <String, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }

    return {
      'length': length,
      'categories': categoryCount,
      'ordinal': isOrdinal,
      'value_counts': counts,
    };
  }
}
