part of 'series.dart';

/// Extension for Series iteration methods
extension SeriesIteration on Series {
  /// Iterate over (index, value) pairs.
  ///
  /// Yields:
  ///   Iterable of MapEntry where key is the index and value is the data value
  ///
  /// Example:
  /// ```dart
  /// var s = Series([10, 20, 30], name: 'data', index: ['a', 'b', 'c']);
  ///
  /// for (var item in s.items()) {
  ///   print('Index: ${item.key}, Value: ${item.value}');
  /// }
  /// // Output:
  /// // Index: a, Value: 10
  /// // Index: b, Value: 20
  /// // Index: c, Value: 30
  /// ```
  Iterable<MapEntry<dynamic, dynamic>> items() sync* {
    for (int i = 0; i < length; i++) {
      yield MapEntry(index[i], data[i]);
    }
  }

  /// Get the index (alias for index property).
  ///
  /// Returns:
  ///   List of index labels
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3], name: 'data', index: ['a', 'b', 'c']);
  /// print(s.keys()); // ['a', 'b', 'c']
  /// ```
  List<dynamic> keys() {
    return List.from(index);
  }

  /// Return array representation of the Series.
  ///
  /// Returns:
  ///   List of values
  ///
  /// Example:
  /// ```dart
  /// var s = Series([1, 2, 3], name: 'data');
  /// var values = s.values;
  /// // [1, 2, 3]
  /// ```
  List<dynamic> get values {
    return List.from(data);
  }

  /// Iterate over values.
  ///
  /// Yields:
  ///   Iterable of values
  ///
  /// Example:
  /// ```dart
  /// var s = Series([10, 20, 30], name: 'data');
  ///
  /// for (var value in s.iterValues()) {
  ///   print(value);
  /// }
  /// ```
  Iterable<dynamic> iterValues() sync* {
    for (final value in data) {
      yield value;
    }
  }

  /// Iterate over indices.
  ///
  /// Yields:
  ///   Iterable of index labels
  ///
  /// Example:
  /// ```dart
  /// var s = Series([10, 20, 30], name: 'data', index: ['a', 'b', 'c']);
  ///
  /// for (var idx in s.iterIndex()) {
  ///   print(idx);
  /// }
  /// ```
  Iterable<dynamic> iterIndex() sync* {
    for (final idx in index) {
      yield idx;
    }
  }
}
