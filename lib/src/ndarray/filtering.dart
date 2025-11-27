/// Filtering and selection operations for NDArray
library;

import 'ndarray.dart';

/// Extension for filtering NDArray
extension NDArrayFiltering on NDArray {
  /// Filter elements where condition is true.
  ///
  /// Returns a 1D array containing only elements that satisfy the condition.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 5, 3], [7, 2, 9]]);
  ///
  /// // Filter values > 4
  /// var filtered = arr.where((x) => x > 4);
  /// print(filtered.toFlatList()); // [5, 7, 9]
  ///
  /// // Filter even numbers
  /// var evens = arr.where((x) => x % 2 == 0);
  /// print(evens.toFlatList()); // [2]
  ///
  /// // Complex filter
  /// var result = arr.where((x) => x >= 3 && x <= 7);
  /// print(result.toFlatList()); // [5, 3, 7]
  /// ```
  NDArray where(bool Function(dynamic) condition) {
    final matching = <dynamic>[];
    for (int i = 0; i < shape.size; i++) {
      final indices = shape.fromFlatIndex(i);
      final value = getValue(indices);
      if (condition(value)) {
        matching.add(value);
      }
    }
    return NDArray(matching);
  }

  /// Get indices where condition is true.
  ///
  /// Returns a list of multi-dimensional indices for all matching elements.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 5, 3], [7, 2, 9]]);
  ///
  /// // Find indices of values  > 5
  /// var indices = arr.whereIndices((x) => x > 5);
  /// // [[0, 2], [1, 0], [1,2]] for values  7 and 9
  ///
  /// // Use indices to access elements
  /// for (var idx in indices) {
  ///   print('Value at $idx: ${arr.getValue(idx)}');
  /// }
  /// ```
  List<List<int>> whereIndices(bool Function(dynamic) condition) {
    final indices = <List<int>>[];
    for (int i = 0; i < shape.size; i++) {
      final idx = shape.fromFlatIndex(i);
      final value = getValue(idx);
      if (condition(value)) {
        indices.add(idx);
      }
    }
    return indices;
  }

  /// Select elements at specific indices.
  ///
  /// Returns a 1D array with elements at the given multi-dimensional indices.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
  ///
  /// // Select specific elements
  /// var selected = arr.select([[0, 0], [1, 1], [0, 2]]);
  /// print(selected.toFlatList()); // [1, 5, 3]
  ///
  /// // Combine with whereIndices
  /// var highIndices = arr.whereIndices((x) => x > 3);
  /// var highValues = arr.select(highIndices);
  /// // [4, 5, 6]
  /// ```
  NDArray select(List<List<int>> indices) {
    final selected = <dynamic>[];
    for (final idx in indices) {
      selected.add(getValue(idx));
    }
    return NDArray(selected);
  }

  /// Filter elements within a value range
  NDArray filterRange(dynamic min, dynamic max) {
    return where((value) {
      if (value == null) return false;
      if (value is! Comparable) return false;
      return value.compareTo(min) >= 0 && value.compareTo(max) <= 0;
    });
  }

  /// Filter by multiple conditions
  NDArray filterMulti(
    List<bool Function(dynamic)> conditions, {
    String logic = 'and',
  }) {
    if (conditions.isEmpty) return this;
    return where((value) {
      if (logic == 'and') {
        return conditions.every((condition) => condition(value));
      } else if (logic == 'or') {
        return conditions.any((condition) => condition(value));
      } else {
        throw ArgumentError('Logic must be "and" or "or"');
      }
    });
  }

  /// Count elements where condition is true
  int countWhere(bool Function(dynamic) condition) {
    int count = 0;
    for (int i = 0; i < shape.size; i++) {
      final indices = shape.fromFlatIndex(i);
      if (condition(getValue(indices))) count++;
    }
    return count;
  }

  /// Check if any element satisfies condition
  bool any(bool Function(dynamic) condition) {
    for (int i = 0; i < shape.size; i++) {
      if (condition(getValue(shape.fromFlatIndex(i)))) return true;
    }
    return false;
  }

  /// Check if all elements satisfy condition
  bool all(bool Function(dynamic) condition) {
    for (int i = 0; i < shape.size; i++) {
      if (!condition(getValue(shape.fromFlatIndex(i)))) return false;
    }
    return true;
  }

  /// Replace values where condition is true
  NDArray replaceWhere(bool Function(dynamic) condition, dynamic newValue) {
    final data = <dynamic>[];
    for (int i = 0; i < shape.size; i++) {
      final indices = shape.fromFlatIndex(i);
      final value = getValue(indices);
      data.add(condition(value) ? newValue : value);
    }
    return NDArray.fromFlat(data, shape.toList());
  }

  /// Find first index where condition is true
  List<int>? findFirst(bool Function(dynamic) condition) {
    for (int i = 0; i < shape.size; i++) {
      final indices = shape.fromFlatIndex(i);
      if (condition(getValue(indices))) return indices;
    }
    return null;
  }

  /// Find last index where condition is true
  List<int>? findLast(bool Function(dynamic) condition) {
    for (int i = shape.size - 1; i >= 0; i--) {
      final indices = shape.fromFlatIndex(i);
      if (condition(getValue(indices))) return indices;
    }
    return null;
  }
}

/// Advanced indexing operations
extension AdvancedIndexing on NDArray {
  /// Index with array of indices along an axis.
  ///
  /// Select specific positions along an axis using an index array.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6], [7, 8, 9]]);
  ///
  /// // Select rows 0 and 2
  /// var rows = arr.indexWith([0, 2], axis: 0);
  /// print(rows.toNestedList()); // [[1, 2, 3], [7, 8, 9]]
  ///
  /// // Select columns 1 and 2
  /// var cols = arr.indexWith([1, 2], axis: 1);
  /// print(cols.toNestedList()); // [[2, 3], [5, 6], [8, 9]]
  ///
  /// // Reorder and duplicate
  /// var reordered = arr.indexWith([2, 1, 0, 0], axis: 0);
  /// // Rows in order: 2, 1, 0, 0 (last row duplicated)
  /// ```
  NDArray indexWith(List<int> indices, {int axis = 0}) {
    if (axis < 0 || axis >= ndim) {
      throw ArgumentError('Axis $axis out of range for $ndim dimensions');
    }

    if (ndim == 1) {
      final data = indices.map((i) => getValue([i])).toList();
      return NDArray(data);
    }

    final newShape = List<int>.from(shape.toList());
    newShape[axis] = indices.length;
    final data = <dynamic>[];
    _indexRecursive([], 0, axis, indices, data);
    return NDArray.fromFlat(data, newShape);
  }

  void _indexRecursive(
    List<int> currentIndices,
    int dim,
    int targetAxis,
    List<int> indices,
    List<dynamic> output,
  ) {
    if (dim == ndim) {
      output.add(getValue(currentIndices));
      return;
    }
    if (dim == targetAxis) {
      for (final idx in indices) {
        _indexRecursive(
            [...currentIndices, idx], dim + 1, targetAxis, indices, output);
      }
    } else {
      for (int i = 0; i < shape[dim]; i++) {
        _indexRecursive(
            [...currentIndices, i], dim + 1, targetAxis, indices, output);
      }
    }
  }

  /// Take elements along an axis
  NDArray take(List<int> indices, {int axis = 0}) =>
      indexWith(indices, axis: axis);

  /// Apply boolean mask to select elements.
  ///
  /// Returns a 1D array with elements where mask is true.
  /// Mask must have the same shape as the array.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 5, 3], [7, 2, 9]]);
  ///
  /// // Create boolean mask
  /// var mask = arr.createMask((x) => x > 4);
  /// var result = arr.mask(mask);
  /// print(result.toFlatList()); // [5, 7, 9]
  ///
  /// // Manual mask
  /// var customMask = NDArray.fromFlat(
  ///   [1, 0, 1, 0, 1, 0].map((x) => x == 1).toList(),
  ///   [2, 3]
  /// );
  /// var filtered = arr.mask(customMask);
  /// ```
  NDArray mask(NDArray boolMask) {
    if (shape.toList().toString() != boolMask.shape.toList().toString()) {
      throw ArgumentError('Mask shape must match array shape');
    }
    final selected = <dynamic>[];
    for (int i = 0; i < shape.size; i++) {
      final indices = shape.fromFlatIndex(i);
      if (boolMask.getValue(indices) == true) {
        selected.add(getValue(indices));
      }
    }
    return NDArray(selected);
  }

  /// Create boolean mask from condition
  NDArray createMask(bool Function(dynamic) condition) {
    final maskData = <dynamic>[];
    for (int i = 0; i < shape.size; i++) {
      final indices = shape.fromFlatIndex(i);
      maskData.add(condition(getValue(indices)));
    }
    return NDArray.fromFlat(maskData, shape.toList());
  }

  /// Put values at specific flat indices.
  ///
  /// Sets the same value at multiple flat (1D) indices.
  /// Modifies the array in-place.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray.zeros([2, 3]); // [[0, 0, 0], [0, 0, 0]]
  ///
  /// // Set values at flat indices 0, 2, 4
  /// arr.put([0, 2, 4], 99);
  /// print(arr.toNestedList()); // [[99, 0, 99], [0, 99, 0]]
  ///
  /// // Flat index ordering is row-major
  /// // Index 0 = [0,0], Index 1 = [0,1], Index 2 = [0,2]
  /// // Index 3 = [1,0], Index 4 = [1,1], Index 5 = [1,2]
  /// ```
  void put(List<int> flatIndices, dynamic value) {
    for (final flatIdx in flatIndices) {
      if (flatIdx < 0 || flatIdx >= shape.size) {
        throw RangeError('Index $flatIdx out of range [0, ${shape.size})');
      }
      setValue(shape.fromFlatIndex(flatIdx), value);
    }
  }

  /// Put values at multi-dimensional indices
  void putAt(List<List<int>> indices, dynamic value) {
    for (final idx in indices) {
      setValue(idx, value);
    }
  }

  /// Put different values at flat indices
  void putValues(List<int> flatIndices, List<dynamic> values) {
    if (flatIndices.length != values.length) {
      throw ArgumentError('Indices and values must have same length');
    }
    for (int i = 0; i < flatIndices.length; i++) {
      final flatIdx = flatIndices[i];
      if (flatIdx < 0 || flatIdx >= shape.size) {
        throw RangeError('Index $flatIdx out of range [0, ${shape.size})');
      }
      setValue(shape.fromFlatIndex(flatIdx), values[i]);
    }
  }
}
