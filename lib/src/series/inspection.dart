part of 'series.dart';

/// Extension for Series inspection methods
extension SeriesInspection on Series {
  /// Generate descriptive statistics (pandas-style).
  ///
  /// Descriptive statistics include those that summarize the central tendency,
  /// dispersion and shape of a dataset's distribution, excluding NaN values.
  ///
  /// This method returns a Series (pandas-style), unlike the existing describe()
  /// which returns a Map.
  ///
  /// Parameters:
  ///   - `percentiles`: List of percentiles to include (default: [0.25, 0.5, 0.75])
  ///
  /// Returns:
  ///   A Series with descriptive statistics
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], name: 'data');
  /// var stats = s.describeSeries();
  /// print(stats);
  /// // Output:
  /// // count    10.0
  /// // mean      5.5
  /// // std       3.03
  /// // min       1.0
  /// // 25%       3.25
  /// // 50%       5.5
  /// // 75%       7.75
  /// // max      10.0
  /// ```
  Series describeSeries({List<double>? percentiles}) {
    percentiles ??= [0.25, 0.5, 0.75];

    final stats = <dynamic>[];
    final statNames = <String>[];

    statNames.add('count');
    stats.add(count().toDouble());

    statNames.add('mean');
    stats.add(mean());

    statNames.add('std');
    stats.add(std());

    statNames.add('min');
    stats.add(this.min());

    for (final p in percentiles) {
      statNames.add('${(p * 100).toStringAsFixed(0)}%');
      stats.add(quantile(p));
    }

    statNames.add('max');
    stats.add(this.max());

    return Series(stats, name: name, index: statNames);
  }

  /// Print a concise summary of the Series.
  ///
  /// This method prints information about the Series including:
  /// - The Series name
  /// - The length
  /// - The data type
  /// - Non-null count
  /// - Memory usage
  ///
  /// Parameters:
  ///   - `memoryUsage`: Whether to display memory usage (default: true)
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, null, 4, 5], name: 'data');
  /// s.info();
  /// // Output:
  /// // <class 'Series'>
  /// // Name: data
  /// // Length: 5
  /// // Non-Null Count: 4
  /// // Dtype: int
  /// // Memory usage: 40 bytes
  /// ```
  void info({bool memoryUsage = true}) {
    final buffer = StringBuffer();

    buffer.writeln('<class \'Series\'>');
    buffer.writeln('Name: $name');
    buffer.writeln('Length: $length');
    buffer.writeln('Non-Null Count: ${count()}');
    buffer.writeln('Dtype: ${dtype.toString().split('.').last}');

    if (memoryUsage) {
      final memBytes = this.memoryUsage();
      buffer.writeln('Memory usage: ${_formatBytes(memBytes)}');
    }

    print(buffer.toString());
  }

  /// Return the memory usage of the Series in bytes.
  ///
  /// Parameters:
  ///   - `deep`: Whether to introspect the data deeply (default: false)
  ///
  /// Returns:
  ///   Memory usage in bytes
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// var mem = s.memoryUsage();
  /// print('Memory: $mem bytes');
  /// ```
  int memoryUsage({bool deep = false}) {
    int totalBytes = 0;

    for (final item in data) {
      if (item == null) {
        totalBytes += 8; // Pointer size
      } else if (item is int) {
        totalBytes += 8;
      } else if (item is double) {
        totalBytes += 8;
      } else if (item is bool) {
        totalBytes += 1;
      } else if (item is String) {
        totalBytes += deep ? item.length * 2 : 8; // UTF-16 or pointer
      } else if (item is DateTime) {
        totalBytes += 8;
      } else {
        totalBytes += 8; // Default pointer size
      }
    }

    return totalBytes;
  }

  /// Check if the Series contains any NaN values.
  ///
  /// Returns:
  ///   true if there are any missing values, false otherwise
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, 2, 3], name: 'data');
  /// print(s1.hasnans); // false
  ///
  /// var s2 = Series([1, null, 3], name: 'data');
  /// print(s2.hasnans); // true
  /// ```
  bool get hasnans {
    for (final value in data) {
      if (_isMissing(value)) {
        return true;
      }
    }
    return false;
  }

  /// Return the index of the first non-NA value.
  ///
  /// Returns:
  ///   The index label of the first non-NA value, or null if all values are NA
  ///
  /// Example:
  /// ```dart
  /// var s = Series([null, null, 3, 4], name: 'data', index: ['a', 'b', 'c', 'd']);
  /// print(s.firstValidIndex()); // 'c'
  /// ```
  dynamic firstValidIndex() {
    for (int i = 0; i < data.length; i++) {
      if (!_isMissing(data[i])) {
        return index[i];
      }
    }
    return null;
  }

  /// Return the index of the last non-NA value.
  ///
  /// Returns:
  ///   The index label of the last non-NA value, or null if all values are NA
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, null, null], name: 'data', index: ['a', 'b', 'c', 'd']);
  /// print(s.lastValidIndex()); // 'b'
  /// ```
  dynamic lastValidIndex() {
    for (int i = data.length - 1; i >= 0; i--) {
      if (!_isMissing(data[i])) {
        return index[i];
      }
    }
    return null;
  }

  /// Format bytes to human-readable string
  String _formatBytes(num bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
