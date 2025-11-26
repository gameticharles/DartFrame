part of 'series.dart';

/// Extension for Series comparison operations
extension SeriesComparison on Series {
  /// Test whether two Series contain the same elements.
  ///
  /// NaNs in the same location are considered equal.
  ///
  /// Parameters:
  ///   - `other`: The Series to compare with
  ///
  /// Returns:
  ///   true if all elements are equal, false otherwise
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, 2, 3], name: 'data');
  /// var s2 = Series([1, 2, 3], name: 'data');
  /// var s3 = Series([1, 2, 4], name: 'data');
  ///
  /// print(s1.equals(s2)); // true
  /// print(s1.equals(s3)); // false
  /// ```
  bool equals(Series other) {
    // Check length
    if (length != other.length) {
      return false;
    }

    // Check index
    if (index.length != other.index.length) {
      return false;
    }

    for (int i = 0; i < index.length; i++) {
      if (index[i] != other.index[i]) {
        return false;
      }
    }

    // Check data
    for (int i = 0; i < length; i++) {
      final val1 = data[i];
      final val2 = other.data[i];

      // Handle NaN comparison
      if (val1 is double && val1.isNaN && val2 is double && val2.isNaN) {
        continue;
      }

      if (val1 != val2) {
        return false;
      }
    }

    return true;
  }

  /// Compare to another Series and show differences.
  ///
  /// Parameters:
  ///   - `other`: Series to compare with
  ///   - `keepShape`: If true, keep all positions (default: false)
  ///   - `keepEqual`: If true, keep matching values (default: false)
  ///
  /// Returns:
  ///   DataFrame showing differences with 'self' and 'other' columns
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, 2, 3, 4], name: 'data');
  /// var s2 = Series([1, 2, 9, 4], name: 'data');
  ///
  /// var diff = s1.compare(s2);
  /// // Shows only the differing values at index 2
  /// ```
  DataFrame compare(
    Series other, {
    bool keepShape = false,
    bool keepEqual = false,
  }) {
    if (length != other.length) {
      throw ArgumentError('Can only compare Series of the same length');
    }

    final selfData = <dynamic>[];
    final otherData = <dynamic>[];
    final resultIndex = <dynamic>[];

    for (int i = 0; i < length; i++) {
      final val1 = data[i];
      final val2 = other.data[i];

      if (keepShape || val1 != val2 || keepEqual) {
        resultIndex.add(index[i]);
        selfData.add(val1);
        otherData.add(val2);
      }
    }

    return DataFrame.fromMap({
      'self': selfData,
      'other': otherData,
    }, index: resultIndex);
  }
}
