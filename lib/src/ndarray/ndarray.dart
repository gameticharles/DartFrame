/// N-dimensional array implementation.
library;

import '../core/dart_data.dart';
import '../core/shape.dart';
import '../core/attributes.dart';
import '../core/slice_spec.dart';
import '../core/scalar.dart';
import '../storage/storage_backend.dart';
import '../core/ndarray_config.dart';
import '../data_cube/datacube.dart';

/// N-dimensional array with flexible storage backends.
///
/// NDArray provides a comprehensive multi-dimensional array implementation
/// supporting various data types, storage backends, and operations.
///
/// Key Features:
/// - Multiple constructors for different creation patterns
/// - Flexible slicing and indexing
/// - Element-wise operations
/// - Broadcasting support
/// - Multiple storage backends (in-memory, memory-mapped, etc.)
///
/// Example:
/// ```dart
/// // Create from nested lists
/// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
/// print(arr.shape); // Shape: [2, 3]
///
/// // Create with specific shape
/// var zeros = NDArray.zeros([3, 4]);
/// var ones = NDArray.ones([2, 2, 2]);
///
/// // Generate with function
/// var arr2 = NDArray.generate([3, 3], (indices) => indices[0] * 10 + indices[1]);
/// ```
class NDArray extends DartData {
  final StorageBackend _backend;
  final Attributes _attrs;

  /// Creates an NDArray from nested lists.
  ///
  /// The shape is automatically inferred from the nesting structure.
  /// All rows at each level must have the same length.
  ///
  /// Example:
  /// ```dart
  /// // 1D array
  /// var arr1d = NDArray([1, 2, 3, 4]);
  /// print(arr1d.shape); // Shape: [4]
  ///
  /// // 2D array
  /// var arr2d = NDArray([[1, 2], [3, 4], [5, 6]]);
  /// print(arr2d.shape); // Shape: [3, 2]
  ///
  /// // 3D array
  /// var arr3d = NDArray([
  ///   [[1, 2], [3, 4]],
  ///   [[5, 6], [7, 8]]
  /// ]);
  /// print(arr3d.shape); // Shape: [2, 2, 2]
  /// ```
  factory NDArray(List<dynamic> data) {
    final shape = _inferShape(data);
    final flatData = _flatten(data);
    final backend = NDArrayConfig.selectBackend(shape, initialData: flatData);
    return NDArray._internal(backend, Attributes());
  }

  /// Creates an NDArray with explicit shape and flat data.
  ///
  /// The data is provided as a flat 1D list which is reshaped according
  /// to the specified shape. The data length must match the product of
  /// shape dimensions.
  ///
  /// Example:
  /// ```dart
  /// // Create 2x3 array from flat data
  /// var arr = NDArray.fromFlat([1, 2, 3, 4, 5, 6], [2, 3]);
  /// print(arr.toNestedList()); // [[1, 2, 3], [4, 5, 6]]
  ///
  /// // Create 3D array
  /// var arr3d = NDArray.fromFlat(
  ///   [1, 2, 3, 4, 5, 6, 7, 8],
  ///   [2, 2, 2]
  /// );
  /// print(arr3d.shape); // Shape: [2, 2, 2]
  /// ```
  ///
  /// Throws [ArgumentError] if data length doesn't match shape.
  factory NDArray.fromFlat(List<dynamic> data, List<int> shape) {
    final expectedSize = shape.reduce((a, b) => a * b);
    if (data.length != expectedSize) {
      throw ArgumentError(
          'Data length ${data.length} does not match shape $shape (expected $expectedSize)');
    }
    final shapeObj = Shape(shape);
    final backend = NDArrayConfig.selectBackend(shapeObj, initialData: data);
    return NDArray._internal(backend, Attributes());
  }

  /// Creates an NDArray filled with zeros.
  ///
  /// All elements are initialized to 0.
  ///
  /// Example:
  /// ```dart
  /// // 1D array of zeros
  /// var arr1d = NDArray.zeros([5]);
  /// print(arr1d.toFlatList()); // [0, 0, 0, 0, 0]
  ///
  /// // 2D array of zeros
  /// var arr2d = NDArray.zeros([2, 3]);
  /// print(arr2d.toNestedList()); // [[0, 0, 0], [0, 0, 0]]
  ///
  /// // 3D array of zeros
  /// var arr3d = NDArray.zeros([2, 2, 2]);
  /// print(arr3d.shape); // Shape: [2, 2, 2]
  /// ```
  factory NDArray.zeros(List<int> shape) {
    final shapeObj = Shape(shape);
    // Generate data first, then select backend
    final data = List.filled(shapeObj.size, 0);
    final backend = NDArrayConfig.selectBackend(shapeObj, initialData: data);
    return NDArray._internal(backend, Attributes());
  }

  /// Creates an NDArray filled with ones.
  ///
  /// All elements are initialized to 1.
  ///
  /// Example:
  /// ```dart
  /// // 1D array of ones
  /// var arr1d = NDArray.ones([5]);
  /// print(arr1d.toFlatList()); // [1, 1, 1, 1, 1]
  ///
  /// // 2D array of ones
  /// var arr2d = NDArray.ones([2, 3]);
  /// print(arr2d.toNestedList()); // [[1, 1, 1], [1, 1, 1]]
  ///
  /// // Use in calculations
  /// var base = NDArray.ones([3, 3]);
  /// var scaled = base * 5; // All elements become 5
  /// ```
  factory NDArray.ones(List<int> shape) {
    final shapeObj = Shape(shape);
    // Generate data first, then select backend
    final data = List.filled(shapeObj.size, 1);
    final backend = NDArrayConfig.selectBackend(shapeObj, initialData: data);
    return NDArray._internal(backend, Attributes());
  }

  /// Creates an NDArray filled with a specific value.
  ///
  /// All elements are initialized to the provided [fillValue].
  ///
  /// Example:
  /// ```dart
  /// // Fill with number
  /// var arr = NDArray.filled([2, 3], 42);
  /// print(arr.toNestedList()); // [[42, 42, 42], [42, 42, 42]]
  ///
  /// // Fill with string
  /// var strArr = NDArray.filled([3], 'hello');
  /// print(strArr.toFlatList()); // ['hello', 'hello', 'hello']
  ///
  /// // Fill with floating point
  /// var floatArr = NDArray.filled([2, 2], 3.14);
  /// ```
  factory NDArray.filled(List<int> shape, dynamic fillValue) {
    final shapeObj = Shape(shape);
    // Generate data first, then select backend
    final data = List.filled(shapeObj.size, fillValue);
    final backend = NDArrayConfig.selectBackend(shapeObj, initialData: data);
    return NDArray._internal(backend, Attributes());
  }

  /// Creates an NDArray with values generated by a function.
  ///
  /// The [generator] function receives indices as a list and returns the
  /// value for that position. This enables creating arrays with patterns,
  /// coordinates, or computed values.
  ///
  /// Example:
  /// ```dart
  /// // Create identity-like pattern
  /// var arr = NDArray.generate([3, 3], (indices) {
  ///   return indices[0] == indices[1] ? 1 : 0;
  /// });
  /// // [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
  ///
  /// // Generate with coordinates
  /// var coords = NDArray.generate([2, 3], (i) => i[0] * 10 + i[1]);
  /// // [[0, 1, 2], [10, 11, 12]]
  ///
  /// // Create distance matrix
  /// var dist = NDArray.generate([5], (i) => i[0] * 0.5);
  /// // [0.0, 0.5, 1.0, 1.5, 2.0]
  /// ```
  factory NDArray.generate(
      List<int> shape, dynamic Function(List<int>) generator) {
    final shapeObj = Shape(shape);
    // Generate data first, then select backend
    final data = List.generate(shapeObj.size, (i) {
      final indices = shapeObj.fromFlatIndex(i);
      return generator(indices);
    });
    final backend = NDArrayConfig.selectBackend(shapeObj, initialData: data);
    return NDArray._internal(backend, Attributes());
  }

  /// Creates an NDArray with a custom storage backend.
  ///
  /// Allows specifying a custom storage backend for advanced use cases
  /// such as memory-mapped storage or distributed arrays.
  ///
  /// Example:
  /// ```dart
  /// // Use with custom backend (advanced)
  /// var backend = CustomStorageBackend(shape: Shape([100, 100]));
  /// var arr = NDArray.withBackend([100, 100], backend);
  /// ```
  factory NDArray.withBackend(List<int> shape, StorageBackend backend) {
    return NDArray._internal(backend, Attributes());
  }

  /// Internal constructor.
  NDArray._internal(this._backend, this._attrs);

  @override
  Shape get shape => _backend.shape;

  @override
  int get ndim => shape.ndim;

  @override
  int get size => shape.size;

  @override
  Attributes get attrs => _attrs;

  /// Gets the storage backend.
  StorageBackend get backend => _backend;

  /// Gets a value at the specified indices.
  ///
  /// The indices must match the number of dimensions and be within bounds.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
  /// print(arr.getValue([0, 0])); // 1
  /// print(arr.getValue([1, 2])); // 6
  ///
  /// // 3D array
  /// var arr3d = NDArray([[[1, 2], [3, 4]], [[5, 6], [7, 8]]]);
  /// print(arr3d.getValue([1, 0, 1])); // 6
  /// ```
  @override
  dynamic getValue(List<int> indices) {
    return _backend.getValue(indices);
  }

  /// Sets a value at the specified indices.
  ///
  /// The indices must match the number of dimensions and be within bounds.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray.zeros([2, 3]);
  /// arr.setValue([0, 0], 10);
  /// arr.setValue([1, 2], 20);
  /// print(arr.toNestedList()); // [[10, 0, 0], [0, 0, 20]]
  ///
  /// // Modify 3D array
  /// var arr3d = NDArray.zeros([2, 2, 2]);
  /// arr3d.setValue([0, 1, 1], 99);
  /// ```
  @override
  void setValue(List<int> indices, dynamic value) {
    _backend.setValue(indices, value);
  }

  /// Gets a slice of the array.
  ///
  /// Supports various slicing formats:
  /// - Single index: reduces dimensionality
  /// - Slice.range(start, end): gets a range
  /// - Slice.all(): gets entire dimension
  /// - Slice with step: Slice.step(start, end, step)
  ///
  /// Returns different types based on result dimensionality:
  /// - 0D: Scalar
  /// - 1D: Series (currently NDArray)
  /// - 2D: DataFrame (currently NDArray)
  /// - 3D: DataCube
  /// - N-D: NDArray
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6], [7, 8, 9]]);
  ///
  /// // Single index - reduces dimension
  /// var row = arr.slice([0]); // [1, 2, 3]
  ///
  /// // Range slice
  /// var subArr = arr.slice([Slice.range(0, 2), Slice.all()]);
  /// // [[1, 2, 3], [4, 5, 6]]
  ///
  /// // Multiple slices
  /// var corner = arr.slice([Slice.range(0, 2), Slice.range(0, 2)]);
  /// // [[1, 2], [4, 5]]
  ///
  /// // With step
  /// var stepped = arr.slice([Slice.all(), Slice.step(0, 3, 2)]);
  /// // [[1, 3], [4, 6], [7, 9]]
  /// ```
  @override
  DartData slice(List<dynamic> sliceSpec) {
    // Normalize slices to SliceSpec
    final slices = _normalizeSlices(sliceSpec);

    // Pad with Slice.all() for missing dimensions
    while (slices.length < shape.ndim) {
      slices.add(Slice.all());
    }

    // Calculate result shape
    final resultShape = _calculateResultShape(slices);

    // Create result based on dimensionality
    return _createResult(slices, resultShape);
  }

  /// Convenient slicing syntax using square brackets.
  ///
  /// Supports various slicing formats:
  /// - Single index: `array[0]` - returns lower-dimensional result
  /// - SliceSpec: `array[Slice.range(0, 10)]` - returns range
  /// - Multiple dimensions: Use `slice()` method with list
  ///
  /// Example:
  /// ```dart
  /// var array = NDArray.generate([5, 4, 3], (i) => i[0] * 100 + i[1] * 10 + i[2]);
  /// var frame = array[0];  // Get first 2D slice (DataFrame or NDArray)
  /// var scalar = array.slice([0, 0, 0]);  // Get single element (Scalar)
  /// ```
  DartData operator [](dynamic indexOrSlice) {
    return slice([indexOrSlice]);
  }

  /// Normalizes various slice formats to SliceSpec.
  List<SliceSpec> _normalizeSlices(List<dynamic> sliceSpec) {
    final slices = <SliceSpec>[];
    for (var s in sliceSpec) {
      if (s is SliceSpec) {
        slices.add(s);
      } else if (s is int) {
        slices.add(Slice.single(s));
      } else if (s == null) {
        slices.add(Slice.all());
      } else {
        throw ArgumentError('Invalid slice specification: $s');
      }
    }
    return slices;
  }

  /// Calculates the resulting shape after slicing.
  Shape _calculateResultShape(List<SliceSpec> slices) {
    final resultDims = <int>[];

    for (int i = 0; i < slices.length; i++) {
      if (!slices[i].isSingleIndex) {
        final dimSize = shape[i];
        final (start, stop, step) = slices[i].resolve(dimSize);
        final length = ((stop - start) / step).ceil().clamp(0, dimSize);
        resultDims.add(length);
      }
    }

    return Shape(resultDims);
  }

  /// Creates the appropriate result type based on dimensionality.
  DartData _createResult(List<SliceSpec> slices, Shape resultShape) {
    // Check if all slices are single indices (result should be scalar)
    final allSingle = slices.every((s) => s.isSingleIndex);

    if (allSingle) {
      // All single indices -> return Scalar
      final indices = slices.map((s) => s.start!).toList();
      return Scalar(getValue(indices));
    }

    // Get sliced backend
    final slicedBackend = _backend.getSlice(slices);

    // Create result based on dimensionality
    switch (resultShape.ndim) {
      case 0:
        // Should not happen if allSingle check works, but handle it
        return Scalar(slicedBackend.getValue([]));

      case 1:
        // 1D -> Series
        return _createSeries(slicedBackend);

      case 2:
        // 2D -> DataFrame
        return _createDataFrame(slicedBackend);

      case 3:
        // 3D -> DataCube
        return _createDataCube(slicedBackend);

      default:
        // N-D -> NDArray
        final result = NDArray._internal(slicedBackend, Attributes());
        // Copy attributes
        for (var key in attrs.keys) {
          result.attrs[key] = attrs[key];
        }
        return result;
    }
  }

  /// Creates a Series from a 1D sliced backend.
  DartData _createSeries(StorageBackend backend) {
    // For now, return as NDArray since Series doesn't implement DartData yet
    // This will be updated when Series is enhanced in task 31
    final result = NDArray._internal(backend, Attributes());
    for (var key in attrs.keys) {
      result.attrs[key] = attrs[key];
    }
    return result;
  }

  /// Creates a DataFrame from a 2D sliced backend.
  DartData _createDataFrame(StorageBackend backend) {
    // For now, return as NDArray since DataFrame doesn't implement DartData yet
    // This will be updated when DataFrame is enhanced in task 32
    final result = NDArray._internal(backend, Attributes());
    for (var key in attrs.keys) {
      result.attrs[key] = attrs[key];
    }
    return result;
  }

  /// Creates a DataCube from a 3D sliced backend.
  DartData _createDataCube(StorageBackend backend) {
    // DataCube already implements DartData, so we can create it directly
    final ndarray = NDArray._internal(backend, Attributes());
    // Copy attributes to the NDArray
    for (var key in attrs.keys) {
      ndarray.attrs[key] = attrs[key];
    }
    // Import DataCube at the top if not already imported
    return DataCube.fromNDArray(ndarray);
  }

  /// Reshapes the array to a new shape.
  ///
  /// The total number of elements must remain the same.
  /// Elements are arranged in row-major (C-style) order.
  ///
  /// Example:
  /// ```dart
  /// // Reshape 1D to 2D
  /// var arr = NDArray([1, 2, 3, 4, 5, 6]);
  /// var reshaped = arr.reshape([2, 3]);
  /// print(reshaped.toNestedList()); // [[1, 2, 3], [4, 5, 6]]
  ///
  /// // Reshape 2D to 3D
  /// var arr2d = NDArray.generate([4, 3], (i) => i[0] * 10 + i[1]);
  /// var arr3d = arr2d.reshape([2, 2, 3]);
  /// print(arr3d.shape); // Shape: [2, 2, 3]
  ///
  /// // Flatten to 1D
  /// var flat = arr2d.reshape([12]);
  /// ```
  ///
  /// Throws [ArgumentError] if the new shape has different total size.
  NDArray reshape(List<int> newShape) {
    final newShapeObj = Shape(newShape);
    if (newShapeObj.size != size) {
      throw ArgumentError(
          'Cannot reshape array of size $size into shape $newShape (size ${newShapeObj.size})');
    }

    // Get flat data and create new backend using config
    final flatData = _backend.getFlatData(copy: NDArrayConfig.copyOnWrite);
    final newBackend =
        NDArrayConfig.selectBackend(newShapeObj, initialData: flatData);

    final result = NDArray._internal(newBackend, Attributes());
    // Copy attributes
    for (var key in attrs.keys) {
      result.attrs[key] = attrs[key];
    }
    return result;
  }

  /// Maps a function over all elements.
  ///
  /// Applies the function to each element and returns a new NDArray
  /// with the results. The shape is preserved.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
  ///
  /// // Square all elements
  /// var squared = arr.map((x) => x * x);
  /// print(squared.toNestedList()); // [[1, 4, 9], [16, 25, 36]]
  ///
  /// // Convert to strings
  /// var strings = arr.map((x) => 'value_$x');
  ///
  /// // Apply mathematical function
  /// var transformed = arr.map((x) => x * 2 + 1);
  /// // [[3, 5, 7], [9, 11, 13]]
  /// ```
  NDArray map(dynamic Function(dynamic) fn) {
    // Generate mapped data first, then select backend
    final data = List.generate(size, (i) {
      final indices = shape.fromFlatIndex(i);
      final value = getValue(indices);
      return fn(value);
    });
    final newBackend = NDArrayConfig.selectBackend(shape, initialData: data);
    final result = NDArray._internal(newBackend, Attributes());
    // Copy attributes
    for (var key in attrs.keys) {
      result.attrs[key] = attrs[key];
    }
    return result;
  }

  /// Filters elements based on a predicate.
  ///
  /// Returns a 1D array containing only elements that satisfy the predicate.
  /// The original shape is not preserved.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
  ///
  /// // Filter values greater than 3
  /// var filtered = arr.where((x) => x > 3);
  /// print(filtered.toFlatList()); // [4, 5, 6]
  ///
  /// // Filter even numbers
  /// var evens = arr.where((x) => x % 2 == 0);
  /// print(evens.toFlatList()); // [2, 4, 6]
  ///
  /// // Filter with complex condition
  /// var result = arr.where((x) => x > 2 && x < 5);
  /// print(result.toFlatList()); // [3, 4]
  /// ```
  NDArray where(bool Function(dynamic) predicate) {
    final results = <dynamic>[];

    void iterate(List<int> indices, int dim) {
      if (dim == ndim) {
        final value = getValue(indices);
        if (predicate(value)) {
          results.add(value);
        }
        return;
      }

      for (int i = 0; i < shape[dim]; i++) {
        iterate([...indices, i], dim + 1);
      }
    }

    iterate([], 0);
    return NDArray.fromFlat(results, [results.length]);
  }

  /// Creates a deep copy of this array.
  ///
  /// Creates an independent copy with its own data and attributes.
  /// Modifications to the copy do not affect the original.
  ///
  /// Example:
  /// ```dart
  /// var original = NDArray([[1, 2], [3, 4]]);
  /// var copied = original.copy();
  ///
  /// // Modify copy
  /// copied.setValue([0, 0], 99);
  ///
  /// print(original.getValue([0, 0])); // 1 (unchanged)
  /// print(copied.getValue([0, 0]));   // 99
  /// ```
  NDArray copy() {
    final newBackend = _backend.clone();
    final newAttrs = Attributes.fromJson(attrs.toJson());
    return NDArray._internal(newBackend, newAttrs);
  }

  /// Converts the array to nested lists.
  ///
  /// Returns the array data as nested Dart lists matching the original shape.
  /// Useful for serialization or display.
  ///
  /// Example:
  /// ```dart
  /// // 2D array
  /// var arr = NDArray.generate([2, 3], (i) => i[0] * 10 + i[1]);
  /// print(arr.toNestedList()); // [[0, 1, 2], [10, 11, 12]]
  ///
  /// // 3D array
  /// var arr3d = NDArray.zeros([2, 2, 2]);
  /// var nested = arr3d.toNestedList();
  /// // [[[0, 0], [0, 0]], [[0, 0], [0, 0]]]
  ///
  /// // 1D array
  /// var arr1d = NDArray([1, 2, 3]);
  /// print(arr1d.toNestedList()); // [1, 2, 3]
  /// ```
  List<dynamic> toNestedList() {
    if (ndim == 0) {
      return getValue([]);
    }

    if (ndim == 1) {
      return List.generate(shape[0], (i) => getValue([i]));
    }

    // Recursive construction for higher dimensions
    List<dynamic> buildNested(List<int> indices, int dim) {
      if (dim == ndim - 1) {
        return List.generate(shape[dim], (i) => getValue([...indices, i]));
      }

      return List.generate(
          shape[dim], (i) => buildNested([...indices, i], dim + 1));
    }

    return buildNested([], 0);
  }

  /// Gets the flat data as a list.
  ///
  /// Returns a 1D list containing all elements in row-major order.
  ///
  /// If [copy] is true (default), returns a new list. If false, may return
  /// a reference to internal data (modify with caution).
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([[1, 2, 3], [4, 5, 6]]);
  /// print(arr.toFlatList()); // [1, 2, 3, 4, 5, 6]
  ///
  /// // Get reference (no copy)
  /// var ref = arr.toFlatList(copy: false);
  ///
  /// // 3D array flattened
  /// var arr3d = NDArray([[[1, 2], [3, 4]], [[5, 6], [7, 8]]]);
  /// print(arr3d.toFlatList()); // [1, 2, 3, 4, 5, 6, 7, 8]
  /// ```
  List<dynamic> toFlatList({bool copy = true}) {
    return _backend.getFlatData(copy: copy);
  }

  @override
  String toString() {
    if (size == 0) {
      return 'NDArray(shape: $shape, empty)';
    }

    if (size <= 10) {
      return 'NDArray(shape: $shape, data: ${toNestedList()})';
    }

    return 'NDArray(shape: $shape, size: $size)';
  }

  // Helper methods

  /// Infers shape from nested lists.
  static Shape _inferShape(List<dynamic> data) {
    final dims = <int>[];
    dynamic current = data;

    while (current is List) {
      if (current.isEmpty) break;
      dims.add(current.length);
      current = current[0];
    }

    return Shape(dims);
  }

  /// Flattens nested lists into a 1D list.
  static List<dynamic> _flatten(List<dynamic> data) {
    final result = <dynamic>[];

    void flattenRecursive(dynamic item) {
      if (item is List) {
        for (var element in item) {
          flattenRecursive(element);
        }
      } else {
        result.add(item);
      }
    }

    flattenRecursive(data);
    return result;
  }
}
