part of 'series.dart';

/// Extension for Series conditional operations
extension SeriesConditional on Series {
  /// Replace values where condition is False.
  ///
  /// Parameters:
  ///   - `cond`: Where cond is True, keep the original value. Where False, replace with other.
  ///     Can be a Series of booleans, a boolean, or a function.
  ///   - `other`: Value to use where cond is False (default: null)
  ///   - `inplace`: Whether to perform operation in place (default: false)
  ///
  /// Returns:
  ///   Series with replaced values (or null if inplace=true)
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  ///
  /// // Replace values less than 3 with 0
  /// var result = s.where(s > 3, other: 0);
  /// // [0, 0, 0, 4, 5]
  ///
  /// // Using a function
  /// var result2 = s.where((x) => x > 3, other: -1);
  /// ```
  Series? where(
    dynamic cond, {
    dynamic other,
    bool inplace = false,
  }) {
    return _conditionalReplace(cond,
        other: other, inplace: inplace, keepWhenTrue: true);
  }

  /// Replace values where condition is True.
  ///
  /// This is the inverse of where(). Where cond is True, replace with other.
  /// Where False, keep the original value.
  ///
  /// Parameters:
  ///   - `cond`: Where cond is True, replace with other. Where False, keep original.
  ///   - `other`: Value to use where cond is True (default: null)
  ///   - `inplace`: Whether to perform operation in place (default: false)
  ///
  /// Returns:
  ///   Series with replaced values (or null if inplace=true)
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  ///
  /// // Replace values greater than 3 with 0
  /// var result = s.mask(s > 3, other: 0);
  /// // [1, 2, 3, 0, 0]
  /// ```
  Series? mask(
    dynamic cond, {
    dynamic other,
    bool inplace = false,
  }) {
    return _conditionalReplace(cond,
        other: other, inplace: inplace, keepWhenTrue: false);
  }

  /// Internal method for conditional replacement
  Series? _conditionalReplace(
    dynamic cond, {
    dynamic other,
    bool inplace = false,
    bool keepWhenTrue = true,
  }) {
    List<bool> condList;

    // Convert condition to list of booleans
    if (cond is Series) {
      if (cond.length != length) {
        throw ArgumentError('Length of cond must match length of Series');
      }
      condList = cond.data.map((e) => e == true).toList();
    } else if (cond is List<bool>) {
      if (cond.length != length) {
        throw ArgumentError('Length of cond must match length of Series');
      }
      condList = cond;
    } else if (cond is bool) {
      condList = List.filled(length, cond);
    } else if (cond is Function) {
      condList = data.map((e) => cond(e) == true).toList();
    } else {
      throw ArgumentError(
          'cond must be a Series, List<bool>, bool, or Function');
    }

    // Prepare replacement values
    List<dynamic> otherList;
    if (other is Series) {
      if (other.length != length) {
        throw ArgumentError('Length of other must match length of Series');
      }
      otherList = other.data;
    } else if (other is List) {
      if (other.length != length) {
        throw ArgumentError('Length of other must match length of Series');
      }
      otherList = other;
    } else {
      // Scalar value - broadcast
      otherList = List.filled(length, other);
    }

    // Perform replacement
    final newData = <dynamic>[];
    for (int i = 0; i < length; i++) {
      final shouldKeep = keepWhenTrue ? condList[i] : !condList[i];
      newData.add(shouldKeep ? data[i] : otherList[i]);
    }

    if (inplace) {
      data = newData;
      return null;
    } else {
      return Series(newData, name: name, index: List.from(index));
    }
  }

  /// Return boolean Series for values between bounds.
  ///
  /// Parameters:
  ///   - `left`: Left boundary
  ///   - `right`: Right boundary
  ///   - `inclusive`: Include boundaries ('both', 'neither', 'left', 'right')
  ///
  /// Returns:
  ///   Boolean Series indicating which values are between bounds
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3, 4, 5], name: 'data');
  /// var result = s.between(2, 4);
  /// // [false, true, true, true, false]
  ///
  /// var result2 = s.between(2, 4, inclusive: 'neither');
  /// // [false, false, true, false, false]
  /// ```
  Series between(
    dynamic left,
    dynamic right, {
    String inclusive = 'both',
  }) {
    if (!['both', 'neither', 'left', 'right'].contains(inclusive)) {
      throw ArgumentError(
          'inclusive must be one of: both, neither, left, right');
    }

    final boolData = <bool>[];

    for (final value in data) {
      if (_isMissing(value)) {
        boolData.add(false);
        continue;
      }

      bool result;

      if (inclusive == 'both') {
        result = _compare(value, left) >= 0 && _compare(value, right) <= 0;
      } else if (inclusive == 'neither') {
        result = _compare(value, left) > 0 && _compare(value, right) < 0;
      } else if (inclusive == 'left') {
        result = _compare(value, left) >= 0 && _compare(value, right) < 0;
      } else {
        // inclusive == 'right'
        result = _compare(value, left) > 0 && _compare(value, right) <= 0;
      }

      boolData.add(result);
    }

    return Series(boolData, name: '${name}_between', index: List.from(index));
  }

  /// Compare two values
  int _compare(dynamic a, dynamic b) {
    if (a is Comparable && b is Comparable) {
      try {
        return a.compareTo(b);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  /// Update values from another Series.
  ///
  /// Modify Series in place using values from another Series.
  /// Uses non-NA values from other to update corresponding values in this Series.
  ///
  /// Parameters:
  ///   - `other`: Series to update from
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, 2, 3, 4], name: 'data', index: ['a', 'b', 'c', 'd']);
  /// var s2 = Series([null, 20, null, 40], name: 'updates', index: ['a', 'b', 'c', 'd']);
  ///
  /// s1.update(s2);
  /// // s1 is now [1, 20, 3, 40]
  /// ```
  void update(Series other) {
    // Create index map for other Series
    final otherIndexMap = <dynamic, int>{};
    for (int i = 0; i < other.index.length; i++) {
      otherIndexMap[other.index[i]] = i;
    }

    // Update values where indices match and other has non-NA value
    for (int i = 0; i < index.length; i++) {
      final idx = index[i];
      if (otherIndexMap.containsKey(idx)) {
        final otherValue = other.data[otherIndexMap[idx]!];
        if (!_isMissing(otherValue)) {
          data[i] = otherValue;
        }
      }
    }
  }

  /// Combine with another Series using a function.
  ///
  /// Parameters:
  ///   - `other`: Series to combine with
  ///   - `func`: Function to combine values (takes two arguments)
  ///   - `fillValue`: Value to use for missing values before combining
  ///
  /// Returns:
  ///   Combined Series
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, 2, 3], name: 'A', index: ['a', 'b', 'c']);
  /// var s2 = Series([4, 5, 6], name: 'B', index: ['b', 'c', 'd']);
  ///
  /// var result = s1.combine(s2, (a, b) => a + b, fillValue: 0);
  /// // Index: ['a', 'b', 'c', 'd']
  /// // Values: [1, 7, 9, 6]
  /// ```
  Series combine(
    Series other,
    dynamic Function(dynamic, dynamic) func, {
    dynamic fillValue,
  }) {
    // Align the two Series
    final aligned = align(other, join: 'outer', fillValue: fillValue);
    final left = aligned[0];
    final right = aligned[1];

    // Combine values
    final combinedData = <dynamic>[];
    for (int i = 0; i < left.length; i++) {
      combinedData.add(func(left.data[i], right.data[i]));
    }

    return Series(combinedData, name: name, index: left.index);
  }

  /// Update null elements with value from another Series.
  ///
  /// Parameters:
  ///   - `other`: Series to combine with
  ///
  /// Returns:
  ///   Combined Series
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series([1, null, 3], name: 'A', index: ['a', 'b', 'c']);
  /// var s2 = Series([10, 20, 30], name: 'B', index: ['a', 'b', 'c']);
  ///
  /// var result = s1.combineFirst(s2);
  /// // [1, 20, 3]
  /// ```
  Series combineFirst(Series other) {
    return combine(
      other,
      (a, b) => _isMissing(a) ? b : a,
    );
  }
}
