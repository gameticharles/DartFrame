part of 'data_frame.dart';

/// Extension for DataFrame missing data helper methods
extension DataFrameMissingDataHelpers on DataFrame {
  /// Count missing values in each column.
  ///
  /// Returns:
  ///   Series with count of missing values per column
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, null, 3, null],
  ///   'B': [4, 5, null, 7],
  /// });
  ///
  /// var counts = df.isnaCounts();
  /// // A: 2, B: 1
  /// ```
  Series isnaCounts() {
    final counts = <dynamic>[];

    for (final col in _columns) {
      final series = column(col);
      int count = 0;
      for (final value in series.data) {
        if (_isMissingValueHelper(value)) {
          count++;
        }
      }
      counts.add(count);
    }

    return Series(counts, name: 'missing_count', index: _columns);
  }

  /// Get percentage of missing values in each column.
  ///
  /// Returns:
  ///   Series with percentage of missing values per column
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, null, 3, null],
  ///   'B': [4, 5, null, 7],
  /// });
  ///
  /// var pct = df.isnaPercentage();
  /// // A: 50.0, B: 25.0
  /// ```
  Series isnaPercentage() {
    final percentages = <dynamic>[];

    for (final col in _columns) {
      final series = column(col);
      int count = 0;
      for (final value in series.data) {
        if (_isMissingValueHelper(value)) {
          count++;
        }
      }
      final pct = series.length > 0 ? (count / series.length) * 100 : 0.0;
      percentages.add(pct);
    }

    return Series(percentages, name: 'missing_percentage', index: _columns);
  }

  /// Check if any value is missing in each column.
  ///
  /// Returns:
  ///   Series of booleans indicating if column has any missing values
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'A': [1, 2, 3],
  ///   'B': [4, null, 6],
  /// });
  ///
  /// var hasNa = df.hasna();
  /// // A: false, B: true
  /// ```
  Series hasna() {
    final hasNaList = <dynamic>[];

    for (final col in _columns) {
      final series = column(col);
      bool hasMissing = false;
      for (final value in series.data) {
        if (_isMissingValueHelper(value)) {
          hasMissing = true;
          break;
        }
      }
      hasNaList.add(hasMissing);
    }

    return Series(hasNaList, name: 'has_missing', index: _columns);
  }

  /// Helper to check if a value is considered missing
  bool _isMissingValueHelper(dynamic value) {
    if (value == null) return true;
    if (replaceMissingValueWith != null && value == replaceMissingValueWith) {
      return true;
    }
    return false;
  }
}
