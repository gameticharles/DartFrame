/// Performance profiling system for tracking operation timings and statistics.
library;

/// A performance profiling system for tracking operation execution times and statistics.
///
/// The [Profiler] class provides static methods to start and stop timing operations,
/// accumulate statistics, and generate reports. It can be enabled or disabled globally
/// to control profiling overhead.
///
/// Example:
/// ```dart
/// Profiler.start('myOperation');
/// // ... perform operation ...
/// Profiler.stop('myOperation');
///
/// final report = Profiler.getReport();
/// print(report);
/// ```
class Profiler {
  static final Map<String, _ActiveOperation> _activeOperations = {};
  static final Map<String, ProfileEntry> _entries = {};
  static bool enabled = true;

  /// Start timing an operation with the given [name].
  ///
  /// Throws [StateError] if an operation with the same name is already active.
  static void start(String name) {
    if (!enabled) return;

    if (_activeOperations.containsKey(name)) {
      throw StateError('Operation "$name" is already started');
    }

    _activeOperations[name] = _ActiveOperation(Stopwatch()..start());
  }

  /// Stop timing an operation with the given [name] and record its statistics.
  ///
  /// Throws [StateError] if the operation was not started.
  static void stop(String name) {
    if (!enabled) return;

    final active = _activeOperations.remove(name);
    if (active == null) {
      throw StateError('Operation "$name" was not started');
    }

    active.stopwatch.stop();
    final elapsed = active.stopwatch.elapsed;

    final entry = _entries.putIfAbsent(name, () => ProfileEntry(name));
    entry.update(elapsed);
  }

  /// Get a report of all profiled operations.
  ///
  /// Returns a [ProfileReport] containing statistics for all completed operations.
  static ProfileReport getReport() {
    return ProfileReport(Map.from(_entries));
  }

  /// Reset all profiling data, clearing all entries and active operations.
  static void reset() {
    _activeOperations.clear();
    _entries.clear();
  }
}

/// Internal class to track active operations.
class _ActiveOperation {
  final Stopwatch stopwatch;

  _ActiveOperation(this.stopwatch);
}

/// Statistics for a single profiled operation.
class ProfileEntry {
  /// The name of the operation.
  final String name;

  /// Number of times this operation has been executed.
  int count = 0;

  /// Total time spent in this operation across all executions.
  Duration totalTime = Duration.zero;

  /// Minimum execution time observed.
  Duration minTime = const Duration(days: 365);

  /// Maximum execution time observed.
  Duration maxTime = Duration.zero;

  /// Number of memory allocations (placeholder for future implementation).
  int memoryAllocations = 0;

  ProfileEntry(this.name);

  /// Average execution time per operation.
  Duration get avgTime => count > 0 ? totalTime ~/ count : Duration.zero;

  /// Update statistics with a new execution time.
  void update(Duration elapsed) {
    count++;
    totalTime += elapsed;
    if (elapsed < minTime) minTime = elapsed;
    if (elapsed > maxTime) maxTime = elapsed;
  }

  @override
  String toString() {
    return '$name: count=$count, total=${_formatDuration(totalTime)}, '
        'avg=${_formatDuration(avgTime)}, '
        'min=${_formatDuration(minTime)}, '
        'max=${_formatDuration(maxTime)}';
  }

  /// Convert to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
      'totalTime': totalTime.inMicroseconds,
      'avgTime': avgTime.inMicroseconds,
      'minTime': minTime.inMicroseconds,
      'maxTime': maxTime.inMicroseconds,
      'memoryAllocations': memoryAllocations,
    };
  }

  static String _formatDuration(Duration d) {
    if (d.inMilliseconds < 1) {
      return '${d.inMicroseconds}μs';
    } else if (d.inSeconds < 1) {
      return '${d.inMilliseconds}ms';
    } else {
      return '${d.inSeconds}.${(d.inMilliseconds % 1000).toString().padLeft(3, '0')}s';
    }
  }
}

/// A report containing profiling statistics for multiple operations.
class ProfileReport {
  /// Map of operation names to their statistics.
  final Map<String, ProfileEntry> entries;

  ProfileReport(this.entries);

  /// Create a copy of this report.
  ProfileReport copy() {
    return ProfileReport(Map.from(entries));
  }

  /// Print a summary of all profiled operations to stdout.
  void printSummary() {
    print(toString());
  }

  @override
  String toString() {
    if (entries.isEmpty) {
      return 'ProfileReport: No operations profiled';
    }

    final buffer = StringBuffer();
    buffer.writeln('ProfileReport:');
    buffer.writeln('=' * 80);

    // Sort by total time descending
    final sortedEntries = entries.values.toList()
      ..sort((a, b) => b.totalTime.compareTo(a.totalTime));

    for (final entry in sortedEntries) {
      buffer.writeln(entry.toString());
    }

    buffer.writeln('=' * 80);
    buffer.writeln('Total operations: ${entries.length}');

    return buffer.toString();
  }

  /// Convert to a JSON string.
  String toJson() {
    final data = {
      'operations': entries.values.map((e) => e.toJson()).toList(),
      'totalOperations': entries.length,
    };

    // Simple JSON encoding (for production, use dart:convert)
    return _encodeJson(data);
  }

  static String _encodeJson(dynamic obj) {
    if (obj == null) return 'null';
    if (obj is String) return '"$obj"';
    if (obj is num || obj is bool) return obj.toString();
    if (obj is List) {
      final items = obj.map(_encodeJson).join(',');
      return '[$items]';
    }
    if (obj is Map) {
      final items = obj.entries
          .map((e) => '"${e.key}":${_encodeJson(e.value)}')
          .join(',');
      return '{$items}';
    }
    return obj.toString();
  }
}
