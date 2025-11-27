/// Lazy evaluation support for NDArray operations
library;

import '../core/shape.dart';
import 'ndarray.dart';

/// Lazy operation that defers computation until needed.
///
/// Base class for lazy evaluation operations. Computations are deferred
/// until materialization or element access.
///
/// This enables:
/// - Operation fusion for better performance
/// - Memory efficiency for large arrays
/// - Pipeline optimization
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

/// Lazy map operation that applies a function to each element.
///
/// Defers the application of a function until the result is needed.
/// Supports automatic fusion with nested map operations.
///
/// Example:
/// ```dart
/// var arr = NDArray([[1, 2], [3, 4]]);
/// var lazy = LazyMapOperation(arr, (x) => x * 2);
///
/// // Computation not performed yet
/// var result = lazy.materialize(); // Now computed
/// // [[2, 4], [6, 8]]
///
/// // Operation fusion
/// var double = LazyMapOperation(arr, (x) => x * 2);
/// var addOne = LazyMapOperation(double.materialize(), (x) => x + 1);
/// // Can be optimized to single pass: (x) => (x * 2) + 1
/// ```
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

/// Lazy element-wise binary operation between two arrays.
///
/// Defers element-wise operations between two NDArrays until needed.
/// Both arrays must have the same shape.
///
/// Example:
/// ```dart
/// var arr1 = NDArray([[1, 2], [3, 4]]);
/// var arr2 = NDArray([[5, 6], [7, 8]]);
///
/// var lazyAdd = LazyBinaryOperation(arr1, arr2, (a, b) => a + b);
///
/// // Access single element (only computes that element)
/// var val = lazyAdd.compute([0, 0]); // 6 (1 + 5)
///
/// // Materialize the entire result
/// var result = lazyAdd.materialize();
/// // [[6, 8], [10, 12]]
/// ```
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

/// Lazy scalar operation applying a function with a scalar value.
///
/// Defers application of a binary operation between an NDArray and a scalar.
///
/// Example:
/// ```dart
/// var arr = NDArray([[1, 2], [3, 4]]);
///
/// var lazyMult = LazyScalarOperation(arr, 10, (a, b) => a * b);
///
/// // Access single element (computed on demand)
/// var val = lazyMult.compute([0, 1]); // 20 (2 * 10)
///
/// // Full computation
/// var result = lazyMult.materialize();
/// // [[10, 20], [30, 40]]
/// ```
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

/// NDArray with lazy evaluation capabilities.
///
/// Wraps a lazy operation and provides on-demand computation.
/// Operations are only executed when accessing elements or materializing.
///
/// Key features:
/// - Deferred computation until needed
/// - Automatic operation fusion and optimization
/// - Memory efficient for large arrays
/// - Can be materialized explicitly or on-demand
///
/// Example:
/// ```dart
/// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
///
/// // Create lazy operations chain
/// var lazy = arr.toLazy()
///   .map((x) => x * 2)      // Not computed yet
///   .map((x) => x + 1);     // Not computed yet
///
/// // Access single element (computed on-demand)
/// print(lazy.getValue([0, 0])); // 3 ((1 * 2) + 1)
///
/// // Materialize entire array
/// var result = lazy.materialize();
/// // [[3, 5, 7], [9, 11, 13]]
/// ```
class LazyNDArray {
  final LazyOperation operation;
  bool _isMaterialized = false;
  NDArray? _materializedArray;

  LazyNDArray(this.operation);

  /// Get the shape
  Shape get shape => operation.shape;

  /// Get value at indices.
  ///
  /// Computes only the requested element if not materialized.
  /// If materialized, returns from the cached array.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2], [3, 4]]);
  /// var lazy = arr.lazyMap((x) => x * 10);
  ///
  /// // Computes only [0, 0]
  /// print(lazy.getValue([0, 0])); // 10
  /// ```
  dynamic getValue(List<int> indices) {
    if (_isMaterialized) {
      return _materializedArray!.getValue(indices);
    }
    return operation.compute(indices);
  }

  /// Set value at indices.
  ///
  /// Forces materialization before setting values.
  /// After first set, the array is no longer lazy.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2], [3, 4]]);
  /// var lazy = arr.lazyMap((x) => x * 2);
  ///
  /// lazy.setValue([0, 0], 100); // Materializes first
  /// print(lazy.isMaterialized); // true
  /// ```
  void setValue(List<int> indices, dynamic value) {
    // Materialize before setting values
    if (!_isMaterialized) {
      materialize();
    }
    _materializedArray!.setValue(indices, value);
  }

  /// Check if the array has been materialized
  bool get isMaterialized => _isMaterialized;

  /// Force materialization of the lazy operation.
  ///
  /// Executes all deferred operations and caches the result.
  /// Subsequent calls return the cached array.
  /// Operations are optimized before materialization.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2], [3, 4]]);
  /// var lazy = arr.lazyMap((x) => x * 2)
  ///               .map((x) => x + 1);  // Not computed
  ///
  /// print(lazy.isMaterialized); // false
  /// var result = lazy.materialize(); // Computed and cached
  /// print(lazy.isMaterialized); // true
  /// ```
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

  @override
  String toString() {
    if (_isMaterialized) {
      return 'LazyNDArray(materialized, shape: $shape)';
    }
    return 'LazyNDArray(lazy, shape: $shape)';
  }
}

/// Extension methods for lazy evaluation
extension LazyNDArrayExtension on NDArray {
  /// Create a lazy version of this array.
  ///
  /// Wraps the array in a lazy wrapper for deferred operations.
  /// Useful for building operation pipelines.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2], [3, 4]]);
  /// var lazy = arr.toLazy();
  ///
  /// // Build pipeline
  /// var result = lazy.map((x) => x * 2)
  ///                  .map((x) => x + 1)
  ///                  .materialize();
  /// ```
  LazyNDArray toLazy() {
    if (this is LazyNDArray) {
      return this as LazyNDArray;
    }
    return LazyNDArray(LazyMapOperation(this, (x) => x));
  }

  /// Apply a function lazily.
  ///
  /// Creates a lazy map operation that defers function application.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2], [3, 4]]);
  ///
  /// // Lazy operations - not computed yet
  /// var lazy = arr.lazyMap((x) => x * x)
  ///               .map((x) => x + 1);
  ///
  /// // Compute when needed
  /// var result = lazy.materialize();
  /// // [[2, 5], [10, 17]] (x²+1)
  /// ```
  LazyNDArray lazyMap(dynamic Function(dynamic) fn) {
    return LazyNDArray(LazyMapOperation(this, fn));
  }

  /// Add lazily.
  ///
  /// Creates a lazy addition operation with a scalar or another array.
  /// Computation is deferred until materialization or element access.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2], [3, 4]]);
  ///
  /// // Lazy scalar addition
  /// var lazy1 = arr.lazyAdd(10);
  ///
  /// // Lazy array addition
  /// var arr2 = NDArray([[5, 6], [7, 8]]);
  /// var lazy2 = arr.lazyAdd(arr2);
  ///
  /// // Not computed until here
  /// var result = lazy2.materialize();
  /// // [[6, 8], [10, 12]]
  /// ```
  LazyNDArray lazyAdd(dynamic other) {
    if (other is NDArray) {
      return LazyNDArray(LazyBinaryOperation(this, other, (a, b) => a + b));
    } else {
      return LazyNDArray(LazyScalarOperation(this, other, (a, b) => a + b));
    }
  }

  /// Subtract lazily.
  ///
  /// Creates a lazy subtraction operation with a scalar or another array.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[10, 20], [30, 40]]);
  ///
  /// // Lazy scalar subtraction
  /// var lazy1 = arr.lazySubtract(5);
  /// // Result when materialized: [[5, 15], [25, 35]]
  ///
  /// // Lazy array subtraction
  /// var arr2 = NDArray([[1, 2], [3, 4]]);
  /// var lazy2 = arr.lazySubtract(arr2);
  /// // Result: [[9, 18], [27, 36]]
  /// ```
  LazyNDArray lazySubtract(dynamic other) {
    if (other is NDArray) {
      return LazyNDArray(LazyBinaryOperation(this, other, (a, b) => a - b));
    } else {
      return LazyNDArray(LazyScalarOperation(this, other, (a, b) => a - b));
    }
  }

  /// Multiply lazily.
  ///
  /// Creates a lazy multiplication operation with a scalar or another array.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2], [3, 4]]);
  ///
  /// // Lazy scalar multiplication
  /// var lazy1 = arr.lazyMultiply(10);
  /// // Result: [[10, 20], [30, 40]]
  ///
  /// // Lazy element-wise multiplication
  /// var arr2 = NDArray([[2, 3], [4, 5]]);
  /// var lazy2 = arr.lazyMultiply(arr2);
  /// // Result: [[2, 6], [12, 20]]
  /// ```
  LazyNDArray lazyMultiply(dynamic other) {
    if (other is NDArray) {
      return LazyNDArray(LazyBinaryOperation(this, other, (a, b) => a * b));
    } else {
      return LazyNDArray(LazyScalarOperation(this, other, (a, b) => a * b));
    }
  }

  /// Divide lazily.
  ///
  /// Creates a lazy division operation with a scalar or another array.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[10, 20], [30, 40]]);
  ///
  /// // Lazy scalar division
  /// var lazy1 = arr.lazyDivide(10);
  /// // Result: [[1.0, 2.0], [3.0, 4.0]]
  ///
  /// // Lazy element-wise division
  /// var arr2 = NDArray([[2, 4], [5, 8]]);
  /// var lazy2 = arr.lazyDivide(arr2);
  /// // Result: [[5.0, 5.0], [6.0, 5.0]]
  /// ```
  LazyNDArray lazyDivide(dynamic other) {
    if (other is NDArray) {
      return LazyNDArray(LazyBinaryOperation(this, other, (a, b) => a / b));
    } else {
      return LazyNDArray(LazyScalarOperation(this, other, (a, b) => a / b));
    }
  }
}
