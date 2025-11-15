/// MultiIndex implementation for hierarchical indexing
library;

import 'dart:collection';

/// A multi-level or hierarchical index object.
///
/// Provides pandas-like MultiIndex functionality for DataFrames and Series.
class MultiIndex {
  final List<List<dynamic>> _levels;
  final List<List<int>> _codes;
  final List<String>? _names;

  /// Creates a MultiIndex from levels and codes.
  ///
  /// Parameters:
  /// - `levels`: List of arrays containing the values for each level
  /// - `codes`: List of arrays containing the indices into levels
  /// - `names`: Optional names for each level
  ///
  /// Example:
  /// ```dart
  /// var idx = MultiIndex.fromArrays([
  ///   ['A', 'A', 'B', 'B'],
  ///   [1, 2, 1, 2]
  /// ], names: ['letter', 'number']);
  /// ```
  MultiIndex._(this._levels, this._codes, this._names) {
    _validate();
  }

  /// Create MultiIndex from arrays (Cartesian product).
  factory MultiIndex.fromArrays(
    List<List<dynamic>> arrays, {
    List<String>? names,
  }) {
    if (arrays.isEmpty) {
      throw ArgumentError('Must provide at least one array');
    }

    final length = arrays.first.length;
    if (!arrays.every((arr) => arr.length == length)) {
      throw ArgumentError('All arrays must have the same length');
    }

    final levels = <List<dynamic>>[];
    final codes = <List<int>>[];

    for (var array in arrays) {
      final uniqueValues = LinkedHashSet<dynamic>.from(array).toList();
      levels.add(uniqueValues);

      final levelCodes = <int>[];
      for (var value in array) {
        levelCodes.add(uniqueValues.indexOf(value));
      }
      codes.add(levelCodes);
    }

    return MultiIndex._(levels, codes, names);
  }

  /// Create MultiIndex from tuples.
  factory MultiIndex.fromTuples(
    List<List<dynamic>> tuples, {
    List<String>? names,
  }) {
    if (tuples.isEmpty) {
      throw ArgumentError('Must provide at least one tuple');
    }

    final nlevels = tuples.first.length;
    if (!tuples.every((t) => t.length == nlevels)) {
      throw ArgumentError('All tuples must have the same length');
    }

    final arrays = <List<dynamic>>[];
    for (int i = 0; i < nlevels; i++) {
      arrays.add(tuples.map((t) => t[i]).toList());
    }

    return MultiIndex.fromArrays(arrays, names: names);
  }

  /// Create MultiIndex from product of iterables.
  factory MultiIndex.fromProduct(
    List<List<dynamic>> iterables, {
    List<String>? names,
  }) {
    if (iterables.isEmpty) {
      throw ArgumentError('Must provide at least one iterable');
    }

    // Generate Cartesian product
    final product = _cartesianProduct(iterables);
    return MultiIndex.fromTuples(product, names: names);
  }

  /// Number of levels in the MultiIndex.
  int get nlevels => _levels.length;

  /// Number of elements in the MultiIndex.
  int get length => _codes.isEmpty ? 0 : _codes.first.length;

  /// Names of the levels.
  List<String>? get names => _names;

  /// Get the levels.
  List<List<dynamic>> get levels => _levels.map((l) => List.from(l)).toList();

  /// Get the codes.
  List<List<int>> get codes => _codes.map((c) => List<int>.from(c)).toList();

  /// Get values at a specific position.
  List<dynamic> operator [](int index) {
    if (index < 0 || index >= length) {
      throw RangeError('Index $index out of range [0, $length)');
    }

    return List.generate(
      nlevels,
      (level) => _levels[level][_codes[level][index]],
    );
  }

  /// Get values for a specific level.
  ///
  /// Parameters:
  /// - `level`: Level number or name
  ///
  /// Returns:
  /// List of values for that level
  List<dynamic> getLevelValues(dynamic level) {
    final levelIndex = _getLevelIndex(level);
    return _codes[levelIndex].map((code) => _levels[levelIndex][code]).toList();
  }

  /// Set names for the levels.
  MultiIndex setNames(List<String> names) {
    if (names.length != nlevels) {
      throw ArgumentError(
          'Length of names (${names.length}) must match number of levels ($nlevels)');
    }
    return MultiIndex._(_levels, _codes, names);
  }

  /// Drop a level from the MultiIndex.
  ///
  /// Parameters:
  /// - `level`: Level to drop (number or name)
  ///
  /// Returns:
  /// New MultiIndex with level removed
  MultiIndex dropLevel(dynamic level) {
    if (nlevels <= 1) {
      throw ArgumentError('Cannot drop level from single-level index');
    }

    final levelIndex = _getLevelIndex(level);

    final newLevels = <List<dynamic>>[];
    final newCodes = <List<int>>[];
    final newNames = _names != null ? <String>[] : null;

    for (int i = 0; i < nlevels; i++) {
      if (i != levelIndex) {
        newLevels.add(_levels[i]);
        newCodes.add(_codes[i]);
        if (newNames != null && _names != null) {
          newNames.add(_names[i]);
        }
      }
    }

    return MultiIndex._(newLevels, newCodes, newNames);
  }

  /// Swap two levels in the MultiIndex.
  ///
  /// Parameters:
  /// - `i`: First level (number or name)
  /// - `j`: Second level (number or name)
  ///
  /// Returns:
  /// New MultiIndex with levels swapped
  MultiIndex swapLevel(dynamic i, dynamic j) {
    final iIndex = _getLevelIndex(i);
    final jIndex = _getLevelIndex(j);

    if (iIndex == jIndex) {
      return this;
    }

    final newLevels = List<List<dynamic>>.from(_levels);
    final newCodes = List<List<int>>.from(_codes);
    final newNames = _names != null ? List<String>.from(_names) : null;

    // Swap
    final tempLevel = newLevels[iIndex];
    newLevels[iIndex] = newLevels[jIndex];
    newLevels[jIndex] = tempLevel;

    final tempCode = newCodes[iIndex];
    newCodes[iIndex] = newCodes[jIndex];
    newCodes[jIndex] = tempCode;

    if (newNames != null) {
      final tempName = newNames[iIndex];
      newNames[iIndex] = newNames[jIndex];
      newNames[jIndex] = tempName;
    }

    return MultiIndex._(newLevels, newCodes, newNames);
  }

  /// Reorder levels in the MultiIndex.
  ///
  /// Parameters:
  /// - `order`: New order of levels (list of indices or names)
  ///
  /// Returns:
  /// New MultiIndex with reordered levels
  MultiIndex reorderLevels(List<dynamic> order) {
    if (order.length != nlevels) {
      throw ArgumentError(
          'Length of order (${order.length}) must match number of levels ($nlevels)');
    }

    final indices = order.map((o) => _getLevelIndex(o)).toList();

    // Check for duplicates
    if (indices.toSet().length != indices.length) {
      throw ArgumentError('Order contains duplicate levels');
    }

    final newLevels = indices.map((i) => _levels[i]).toList();
    final newCodes = indices.map((i) => _codes[i]).toList();
    final newNames =
        _names != null ? indices.map((i) => _names[i]).toList() : null;

    return MultiIndex._(newLevels, newCodes, newNames);
  }

  /// Get unique values in the MultiIndex.
  List<List<dynamic>> get unique {
    final seen = <String>{};
    final result = <List<dynamic>>[];

    for (int i = 0; i < length; i++) {
      final tuple = this[i];
      final key = tuple.toString();
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(tuple);
      }
    }

    return result;
  }

  /// Check if MultiIndex contains a value.
  bool contains(List<dynamic> value) {
    if (value.length != nlevels) {
      return false;
    }

    for (int i = 0; i < length; i++) {
      if (_tupleEquals(this[i], value)) {
        return true;
      }
    }

    return false;
  }

  /// Get the position of a value in the MultiIndex.
  int indexOf(List<dynamic> value) {
    if (value.length != nlevels) {
      return -1;
    }

    for (int i = 0; i < length; i++) {
      if (_tupleEquals(this[i], value)) {
        return i;
      }
    }

    return -1;
  }

  /// Convert to list of tuples.
  List<List<dynamic>> toList() {
    return List.generate(length, (i) => this[i]);
  }

  /// Validate the MultiIndex structure.
  void _validate() {
    if (_levels.isEmpty) {
      throw ArgumentError('Must have at least one level');
    }

    if (_levels.length != _codes.length) {
      throw ArgumentError('Number of levels must match number of code arrays');
    }

    if (_names != null && _names.length != _levels.length) {
      throw ArgumentError('Number of names must match number of levels');
    }

    final length = _codes.first.length;
    if (!_codes.every((c) => c.length == length)) {
      throw ArgumentError('All code arrays must have the same length');
    }

    // Validate codes
    for (int i = 0; i < _levels.length; i++) {
      for (var code in _codes[i]) {
        if (code < 0 || code >= _levels[i].length) {
          throw ArgumentError(
              'Code $code out of range for level $i with ${_levels[i].length} values');
        }
      }
    }
  }

  /// Get level index from number or name.
  int _getLevelIndex(dynamic level) {
    if (level is int) {
      if (level < 0 || level >= nlevels) {
        throw RangeError('Level $level out of range [0, $nlevels)');
      }
      return level;
    } else if (level is String) {
      if (_names == null) {
        throw ArgumentError('Index does not have names');
      }
      final index = _names.indexOf(level);
      if (index == -1) {
        throw ArgumentError('Level name "$level" not found');
      }
      return index;
    } else {
      throw ArgumentError('Level must be int or String');
    }
  }

  /// Check if two tuples are equal.
  bool _tupleEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Generate Cartesian product of iterables.
  static List<List<dynamic>> _cartesianProduct(List<List<dynamic>> iterables) {
    if (iterables.isEmpty) return [];
    if (iterables.length == 1) {
      return iterables.first.map((e) => [e]).toList();
    }

    final result = <List<dynamic>>[];
    final first = iterables.first;
    final rest = _cartesianProduct(iterables.sublist(1));

    for (var item in first) {
      for (var tuple in rest) {
        result.add([item, ...tuple]);
      }
    }

    return result;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('MultiIndex(');

    if (_names != null) {
      buffer.writeln('  names: $_names');
    }

    final displayCount = length < 10 ? length : 10;
    for (int i = 0; i < displayCount; i++) {
      buffer.writeln('  $i: ${this[i]}');
    }

    if (length > displayCount) {
      buffer.writeln('  ... (${length - displayCount} more)');
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MultiIndex) return false;

    if (nlevels != other.nlevels || length != other.length) return false;

    for (int i = 0; i < length; i++) {
      if (!_tupleEquals(this[i], other[i])) return false;
    }

    return true;
  }

  @override
  int get hashCode {
    var hash = 0;
    for (int i = 0; i < length; i++) {
      hash ^= this[i].hashCode;
    }
    return hash;
  }
}

/// Index set operations
extension IndexSetOperations on MultiIndex {
  /// Union of two MultiIndex objects.
  MultiIndex union(MultiIndex other) {
    if (nlevels != other.nlevels) {
      throw ArgumentError(
          'Cannot union MultiIndex with different number of levels');
    }

    final combined = <List<dynamic>>[];
    final seen = <String>{};

    // Add all from this
    for (int i = 0; i < length; i++) {
      final tuple = this[i];
      final key = tuple.toString();
      if (!seen.contains(key)) {
        seen.add(key);
        combined.add(tuple);
      }
    }

    // Add unique from other
    for (int i = 0; i < other.length; i++) {
      final tuple = other[i];
      final key = tuple.toString();
      if (!seen.contains(key)) {
        seen.add(key);
        combined.add(tuple);
      }
    }

    return MultiIndex.fromTuples(combined, names: names);
  }

  /// Intersection of two MultiIndex objects.
  MultiIndex intersection(MultiIndex other) {
    if (nlevels != other.nlevels) {
      throw ArgumentError(
          'Cannot intersect MultiIndex with different number of levels');
    }

    final result = <List<dynamic>>[];
    final otherSet = <String>{};

    // Build set from other
    for (int i = 0; i < other.length; i++) {
      otherSet.add(other[i].toString());
    }

    // Find common elements
    final seen = <String>{};
    for (int i = 0; i < length; i++) {
      final tuple = this[i];
      final key = tuple.toString();
      if (otherSet.contains(key) && !seen.contains(key)) {
        seen.add(key);
        result.add(tuple);
      }
    }

    return MultiIndex.fromTuples(result, names: names);
  }

  /// Difference of two MultiIndex objects.
  MultiIndex difference(MultiIndex other) {
    if (nlevels != other.nlevels) {
      throw ArgumentError(
          'Cannot compute difference of MultiIndex with different number of levels');
    }

    final result = <List<dynamic>>[];
    final otherSet = <String>{};

    // Build set from other
    for (int i = 0; i < other.length; i++) {
      otherSet.add(other[i].toString());
    }

    // Find elements in this but not in other
    final seen = <String>{};
    for (int i = 0; i < length; i++) {
      final tuple = this[i];
      final key = tuple.toString();
      if (!otherSet.contains(key) && !seen.contains(key)) {
        seen.add(key);
        result.add(tuple);
      }
    }

    return MultiIndex.fromTuples(result, names: names);
  }
}
