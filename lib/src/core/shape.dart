import 'dart:math' as math;

/// Enhanced Shape class with N-dimensional support
///
/// Represents the shape of multi-dimensional data structures with support for:
/// - N-dimensional shapes (1D, 2D, 3D, 4D, ...)
/// - Strides calculation for efficient flat indexing
/// - Broadcasting compatibility checking
/// - Index conversion (multi-dimensional ↔ flat)
///
/// This class is used by NDArray, DataCube, and can enhance DataFrame/Series.
class Shape {
  final List<int> _dimensions;
  List<int>? _strides;

  /// Create shape from dimensions
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([3, 4, 5]);  // 3D shape
  /// print(shape.ndim);  // 3
  /// print(shape.size);  // 60
  ///
  /// var scalar = Shape([]);  // 0D shape (scalar)
  /// print(scalar.ndim);  // 0
  /// print(scalar.size);  // 1
  /// ```
  Shape(List<int> dimensions) : _dimensions = List.unmodifiable(dimensions) {
    if (dimensions.any((dim) => dim < 0)) {
      throw ArgumentError('All dimensions must be non-negative');
    }
  }

  /// Create 2D shape (for backward compatibility with DataFrame)
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape.fromRowsColumns(10, 20);
  /// print(shape.rows);     // 10
  /// print(shape.columns);  // 20
  /// ```
  Shape.fromRowsColumns(int rows, int columns) : this([rows, columns]);

  /// Number of dimensions
  int get ndim => _dimensions.length;

  /// Total number of elements (product of all dimensions)
  int get size => _dimensions.isEmpty ? 1 : _dimensions.reduce((a, b) => a * b);

  /// Get dimension at index
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([3, 4, 5]);
  /// print(shape[0]);  // 3
  /// print(shape[1]);  // 4
  /// print(shape[2]);  // 5
  /// ```
  int operator [](int index) {
    if (index < 0 || index >= _dimensions.length) {
      throw RangeError(
          'Index $index out of bounds for ${_dimensions.length}D shape');
    }
    return _dimensions[index];
  }

  /// Get all dimensions as list
  List<int> toList() => List.from(_dimensions);

  /// Strides for row-major indexing
  ///
  /// Strides define how many elements to skip in the flat array
  /// to move one step along each dimension.
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([3, 4, 5]);
  /// print(shape.strides);  // [20, 5, 1]
  /// // Moving 1 step in dim 0 skips 20 elements
  /// // Moving 1 step in dim 1 skips 5 elements
  /// // Moving 1 step in dim 2 skips 1 element
  /// ```
  List<int> get strides {
    _strides ??= _calculateStrides();
    return _strides!;
  }

  List<int> _calculateStrides() {
    List<int> result = List.filled(ndim, 1);
    for (int i = ndim - 2; i >= 0; i--) {
      result[i] = result[i + 1] * _dimensions[i + 1];
    }
    return result;
  }

  /// Convert multi-dimensional indices to flat index
  ///
  /// Uses row-major (C-style) ordering.
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([3, 4, 5]);
  /// var flatIndex = shape.toFlatIndex([1, 2, 3]);
  /// // flatIndex = 1*20 + 2*5 + 3*1 = 33
  /// ```
  int toFlatIndex(List<int> indices) {
    if (indices.length != ndim) {
      throw ArgumentError('Expected $ndim indices, got ${indices.length}');
    }

    int flatIndex = 0;
    List<int> str = strides;

    for (int i = 0; i < ndim; i++) {
      if (indices[i] < 0 || indices[i] >= _dimensions[i]) {
        throw RangeError(
            'Index ${indices[i]} out of bounds for dimension $i (size ${_dimensions[i]})');
      }
      flatIndex += indices[i] * str[i];
    }

    return flatIndex;
  }

  /// Convert flat index to multi-dimensional indices
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([3, 4, 5]);
  /// var indices = shape.fromFlatIndex(33);
  /// print(indices);  // [1, 2, 3]
  /// ```
  List<int> fromFlatIndex(int flatIndex) {
    if (flatIndex < 0 || flatIndex >= size) {
      throw RangeError('Flat index $flatIndex out of bounds (size $size)');
    }

    List<int> indices = List.filled(ndim, 0);
    int remaining = flatIndex;

    for (int i = 0; i < ndim; i++) {
      indices[i] = remaining ~/ strides[i];
      remaining %= strides[i];
    }

    return indices;
  }

  /// Check if two shapes are broadcastable
  ///
  /// Two shapes are broadcastable if:
  /// - They have the same number of dimensions, OR
  /// - One can be prepended with 1s to match, AND
  /// - For each dimension pair, either:
  ///   - The dimensions are equal, OR
  ///   - One of them is 1
  ///
  /// Example:
  /// ```dart
  /// var shape1 = Shape([3, 1, 5]);
  /// var shape2 = Shape([1, 4, 5]);
  /// print(shape1.canBroadcastWith(shape2));  // true
  /// // Result would be [3, 4, 5]
  ///
  /// var shape3 = Shape([3, 2, 5]);
  /// var shape4 = Shape([3, 4, 5]);
  /// print(shape3.canBroadcastWith(shape4));  // false
  /// // 2 and 4 are incompatible
  /// ```
  bool canBroadcastWith(Shape other) {
    int maxDim = math.max(ndim, other.ndim);

    for (int i = 0; i < maxDim; i++) {
      int dim1 = i < ndim ? _dimensions[ndim - 1 - i] : 1;
      int dim2 = i < other.ndim ? other._dimensions[other.ndim - 1 - i] : 1;

      if (dim1 != dim2 && dim1 != 1 && dim2 != 1) {
        return false;
      }
    }

    return true;
  }

  /// Get broadcast shape with another shape
  ///
  /// Returns the resulting shape after broadcasting.
  ///
  /// Example:
  /// ```dart
  /// var shape1 = Shape([3, 1, 5]);
  /// var shape2 = Shape([1, 4, 5]);
  /// var result = shape1.broadcastWith(shape2);
  /// print(result);  // Shape([3, 4, 5])
  /// ```
  Shape broadcastWith(Shape other) {
    if (!canBroadcastWith(other)) {
      throw ArgumentError('Shapes $this and $other are not broadcastable');
    }

    int maxDim = math.max(ndim, other.ndim);
    List<int> resultDims = List.filled(maxDim, 0);

    for (int i = 0; i < maxDim; i++) {
      int dim1 = i < ndim ? _dimensions[ndim - 1 - i] : 1;
      int dim2 = i < other.ndim ? other._dimensions[other.ndim - 1 - i] : 1;
      resultDims[maxDim - 1 - i] = math.max(dim1, dim2);
    }

    return Shape(resultDims);
  }

  /// Add a dimension at the specified axis
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([3, 4]);
  /// var expanded = shape.addDimension(5, axis: 0);
  /// print(expanded);  // Shape([5, 3, 4])
  /// ```
  Shape addDimension(int size, {int axis = 0}) {
    if (size < 0) {
      throw ArgumentError('Dimension size must be non-negative');
    }
    if (axis < 0 || axis > ndim) {
      throw RangeError('Axis $axis is out of bounds for insertion');
    }

    var newDimensions = List<int>.from(_dimensions);
    newDimensions.insert(axis, size);
    return Shape(newDimensions);
  }

  /// Remove a dimension at the specified axis
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([1, 3, 4]);
  /// var squeezed = shape.removeDimension(0);
  /// print(squeezed);  // Shape([3, 4])
  /// ```
  Shape removeDimension(int axis) {
    if (ndim <= 1) {
      throw ArgumentError('Cannot remove dimension from 1D shape');
    }
    if (axis < 0 || axis >= ndim) {
      throw RangeError('Axis $axis is out of bounds');
    }

    var newDimensions = List<int>.from(_dimensions);
    newDimensions.removeAt(axis);
    return Shape(newDimensions);
  }

  /// Transpose (reorder) dimensions
  ///
  /// Example:
  /// ```dart
  /// var shape = Shape([3, 4, 5]);
  /// var transposed = shape.transpose([2, 0, 1]);
  /// print(transposed);  // Shape([5, 3, 4])
  /// ```
  Shape transpose(List<int> axes) {
    if (axes.length != ndim) {
      throw ArgumentError('Number of axes must match number of dimensions');
    }
    if (Set.from(axes).length != axes.length) {
      throw ArgumentError('Axes must be unique');
    }
    if (axes.any((axis) => axis < 0 || axis >= ndim)) {
      throw ArgumentError('All axes must be valid dimension indices');
    }

    return Shape(axes.map((axis) => _dimensions[axis]).toList());
  }

  // ============ Backward Compatibility Properties ============

  /// The number of rows (first dimension) for 2D+ structures
  ///
  /// Throws [StateError] if this is not at least a 2D shape.
  int get rows {
    if (_dimensions.isEmpty) {
      throw StateError('Shape must have at least 1 dimension to access rows');
    }
    return _dimensions[0];
  }

  /// The number of columns (second dimension) for 2D+ structures
  ///
  /// Throws [StateError] if this is not at least a 2D shape.
  int get columns {
    if (_dimensions.length < 2) {
      throw StateError(
          'Shape must have at least 2 dimensions to access columns');
    }
    return _dimensions[1];
  }

  /// Checks if any dimension has size 0 (empty structure)
  bool get isEmpty => _dimensions.any((dim) => dim == 0);

  /// Checks if all dimensions have size > 0 (non-empty structure)
  bool get isNotEmpty => !isEmpty;

  /// Checks if this is a 2D square shape (rows == columns)
  bool get isSquare =>
      _dimensions.length == 2 && _dimensions[0] == _dimensions[1];

  /// Checks if this is a 1D shape (vector)
  bool get isVector => _dimensions.length == 1;

  /// Checks if this is a 2D shape (matrix/DataFrame)
  bool get isMatrix => _dimensions.length == 2;

  /// Checks if this is a 3D+ shape (tensor)
  bool get isTensor => _dimensions.length >= 3;

  /// Checks if all dimensions have the same size (hypercube)
  bool get isHypercube => _dimensions.every((dim) => dim == _dimensions[0]);

  @override
  String toString() {
    if (_dimensions.length == 2) {
      return 'Shape(rows: ${_dimensions[0]}, columns: ${_dimensions[1]})';
    }
    return 'Shape(${_dimensions.join('×')})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shape &&
          runtimeType == other.runtimeType &&
          _listEquals(_dimensions, other._dimensions);

  @override
  int get hashCode => _dimensions.fold(0, (hash, dim) => hash ^ dim.hashCode);

  /// Helper method to compare two lists for equality
  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
