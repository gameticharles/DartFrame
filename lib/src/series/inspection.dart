part of 'series.dart';

/// Extension providing inspection and information methods for Series.
extension SeriesInspection on Series {
  /// Prints a concise summary of the Series.
  ///
  /// This method prints information about the Series including
  /// the index, length, name, dtype, and memory usage.
  ///
  /// Parameters:
  /// - `verbose`: Whether to print the full summary. (Currently unused, kept for API consistency)
  /// - `showCounts`: Whether to show the non-null counts.
  ///
  /// Example:
  /// ```dart
  /// series.info();
  /// ```
  void info({bool? verbose, bool showCounts = true}) {
    print('<Series: $name>');
    print('Length: $length');
    print('Dtype: $dtype');

    if (showCounts) {
      int nonNullCount = count();
      print('Non-Null Count: $nonNullCount');
    }

    print('Memory Usage: ${_formatBytes(memoryUsage())}');
  }

  /// Returns the memory usage of the Series in bytes.
  ///
  /// The memory usage is calculated based on the estimated size of objects
  /// in memory. This is an approximation.
  ///
  /// Returns:
  /// The estimated memory usage in bytes.
  int memoryUsage({bool deep = false}) {
    int usage = 0;

    // Index memory (approximate)
    // Assuming index is a List, and we estimate per item
    // If index is not loaded or is a range, this might be different,
    // but Series usually has a materialized index list.
    usage +=
        index.length * 8; // Assume 8 bytes per index item overhead/reference

    for (var item in data) {
      usage += _estimateSize(item);
    }

    return usage;
  }

  /// Internal helper to estimate size of an object in bytes.
  /// Duplicated from DataFrame inspection for now to avoid circular deps or complex refactoring.
  int _estimateSize(dynamic value) {
    if (value == null) return 0;
    if (value is int) return 8;
    if (value is double) return 8;
    if (value is bool) return 1;
    if (value is String) return value.length * 2; // UTF-16 approximation
    return 16; // Generic object overhead approximation
  }

  /// Internal helper to format bytes.
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
