/// Filtering and selection operations for NDArray
library;

import 'ndarray.dart';

/// Extension for filtering NDArray
extension NDArrayFiltering on NDArray {
  /// Filter elements where condition is true
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

  /// Get indices where condition is true
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

  /// Select elements at specific indices
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
  /// Index with array of indices along an axis
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

  /// Apply boolean mask to select elements
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

  /// Put values at specific flat indices
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
