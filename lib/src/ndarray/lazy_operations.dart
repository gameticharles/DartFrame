/// Lazy evaluation support for NDArray operations
library;

import '../core/shape.dart';
import 'ndarray.dart';

/// Lazy operation that defers computation until needed
abstract class LazyOperation {
  /// Shape of the result
  Shape get shape;

  /// Compute value at specific indices
  dynamic compute(List<int> indices);

  /// Materialize the entire operation into an NDArray
  NDArray materialize();

  /// Optimize the operation (e.g., fusion)
  LazyOperation optimize() => this;
}

/// Lazy map operation
class LazyMapOperation extends LazyOperation {
  final NDArray source;
  final dynamic Function(dynamic) function;

  LazyMapOperation(this.source, this.function);

  @override
  Shape get shape => source.shape;

  @override
  dynamic compute(List<int> indices) {
    return function(source.getValue(indices));
  }

  @override
  NDArray materialize() {
    return source.map(function);
  }

  @override
  LazyOperation optimize() {
    // If source is also a lazy map, fuse the operations
    if (source is LazyNDArray) {
      final lazySource = source as LazyNDArray;
      if (lazySource.operation is LazyMapOperation) {
        final innerMap = lazySource.operation as LazyMapOperation;
        // Fuse: f(g(x)) = (f ∘ g)(x)
        return LazyMapOperation(
          innerMap.source,
          (x) => function(innerMap.function(x)),
        );
      }
    }
    return this;
  }
}

/// Lazy element-wise binary operation
class LazyBinaryOperation extends LazyOperation {
  final NDArray left;
  final NDArray right;
  final dynamic Function(dynamic, dynamic) operation;

  LazyBinaryOperation(this.left, this.right, this.operation) {
    if (left.shape.toList().toString() != right.shape.toList().toString()) {
      throw ArgumentError('Shapes must match for binary operations');
    }
  }

  @override
  Shape get shape => left.shape;

  @override
  dynamic compute(List<int> indices) {
    return operation(left.getValue(indices), right.getValue(indices));
  }

  @override
  NDArray materialize() {
    final data = <dynamic>[];
    for (int i = 0; i < shape.size; i++) {
      final indices = shape.fromFlatIndex(i);
      data.add(compute(indices));
    }
    return NDArray.fromFlat(data, shape.toList());
  }
}

/// Lazy scalar operation
class LazyScalarOperation extends LazyOperation {
  final NDArray source;
  final dynamic scalar;
  final dynamic Function(dynamic, dynamic) operation;

  LazyScalarOperation(this.source, this.scalar, this.operation);

  @override
  Shape get shape => source.shape;

  @override
  dynamic compute(List<int> indices) {
    return operation(source.getValue(indices), scalar);
  }

  @override
  NDArray materialize() {
    final data = <dynamic>[];
    for (int i = 0; i < shape.size; i++) {
      final indices = shape.fromFlatIndex(i);
      data.add(compute(indices));
    }
    return NDArray.fromFlat(data, shape.toList());
  }
}

/// NDArray with lazy evaluation
class LazyNDArray {
  final LazyOperation operation;
  bool _isMaterialized = false;
  NDArray? _materializedArray;

  LazyNDArray(this.operation);

  /// Get the shape
  Shape get shape => operation.shape;

  /// Get value at indices
  dynamic getValue(List<int> indices) {
    if (_isMaterialized) {
      return _materializedArray!.getValue(indices);
    }
    return operation.compute(indices);
  }

  /// Set value at indices
  void setValue(List<int> indices, dynamic value) {
    // Materialize before setting values
    if (!_isMaterialized) {
      materialize();
    }
    _materializedArray!.setValue(indices, value);
  }

  /// Check if the array has been materialized
  bool get isMaterialized => _isMaterialized;

  /// Force materialization of the lazy operation
  NDArray materialize() {
    if (!_isMaterialized) {
      _materializedArray = operation.optimize().materialize();
      _isMaterialized = true;
    }
    return _materializedArray!;
  }

  /// Create a new lazy map operation
  LazyNDArray map(dynamic Function(dynamic) fn) {
    if (_isMaterialized) {
      return _materializedArray!.lazyMap(fn);
    }
    // Need to wrap this LazyNDArray as an NDArray for the operation
    final materialized = materialize();
    return LazyNDArray(LazyMapOperation(materialized, fn));
  }

  String toString() {
    if (_isMaterialized) {
      return 'LazyNDArray(materialized, shape: $shape)';
    }
    return 'LazyNDArray(lazy, shape: $shape)';
  }
}

/// Extension methods for lazy evaluation
extension LazyNDArrayExtension on NDArray {
  /// Create a lazy version of this array
  LazyNDArray toLazy() {
    if (this is LazyNDArray) {
      return this as LazyNDArray;
    }
    return LazyNDArray(LazyMapOperation(this, (x) => x));
  }

  /// Apply a function lazily
  LazyNDArray lazyMap(dynamic Function(dynamic) fn) {
    return LazyNDArray(LazyMapOperation(this, fn));
  }

  /// Add lazily
  LazyNDArray lazyAdd(dynamic other) {
    if (other is NDArray) {
      return LazyNDArray(LazyBinaryOperation(this, other, (a, b) => a + b));
    } else {
      return LazyNDArray(LazyScalarOperation(this, other, (a, b) => a + b));
    }
  }

  /// Subtract lazily
  LazyNDArray lazySubtract(dynamic other) {
    if (other is NDArray) {
      return LazyNDArray(LazyBinaryOperation(this, other, (a, b) => a - b));
    } else {
      return LazyNDArray(LazyScalarOperation(this, other, (a, b) => a - b));
    }
  }

  /// Multiply lazily
  LazyNDArray lazyMultiply(dynamic other) {
    if (other is NDArray) {
      return LazyNDArray(LazyBinaryOperation(this, other, (a, b) => a * b));
    } else {
      return LazyNDArray(LazyScalarOperation(this, other, (a, b) => a * b));
    }
  }

  /// Divide lazily
  LazyNDArray lazyDivide(dynamic other) {
    if (other is NDArray) {
      return LazyNDArray(LazyBinaryOperation(this, other, (a, b) => a / b));
    } else {
      return LazyNDArray(LazyScalarOperation(this, other, (a, b) => a / b));
    }
  }
}
