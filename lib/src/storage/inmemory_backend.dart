import '../core/shape.dart';
import '../core/slice_spec.dart';
import 'storage_backend.dart';

/// In-memory storage backend
///
/// Stores data in a flat array in memory for fast access.
/// Best for small to medium datasets that fit comfortably in RAM.
///
/// Features:
/// - Fast access (O(1) for getValue/setValue)
/// - No I/O overhead
/// - Simple and reliable
/// - Statistics tracking
///
/// Example:
/// ```dart
/// var backend = InMemoryBackend([1, 2, 3, 4, 5, 6], Shape([2, 3]));
/// print(backend.getValue([0, 1]));  // 2
/// backend.setValue([1, 2], 99);
/// ```
class InMemoryBackend extends StorageBackend with BackendStatsMixin {
  @override
  final Shape shape;

  /// Flat data array (row-major order)
  final List<dynamic> _data;

  /// Create in-memory backend from flat data
  ///
  /// Parameters:
  /// - `data`: Flat array of data (row-major order)
  /// - `shape`: Shape of the N-dimensional array
  ///
  /// Example:
  /// ```dart
  /// var backend = InMemoryBackend(
  ///   [1, 2, 3, 4, 5, 6],
  ///   Shape([2, 3]),
  /// );
  /// ```
  InMemoryBackend(List<dynamic> data, this.shape) : _data = List.from(data) {
    if (data.length != shape.size) {
      throw ArgumentError(
          'Data length (${data.length}) must match shape size (${shape.size})');
    }
  }

  /// Create in-memory backend with initial value
  ///
  /// Example:
  /// ```dart
  /// var backend = InMemoryBackend.filled(Shape([2, 3]), 0);
  /// ```
  factory InMemoryBackend.filled(Shape shape, dynamic fillValue) {
    return InMemoryBackend(
      List.filled(shape.size, fillValue),
      shape,
    );
  }

  /// Create in-memory backend with zeros
  ///
  /// Example:
  /// ```dart
  /// var backend = InMemoryBackend.zeros(Shape([2, 3]));
  /// ```
  factory InMemoryBackend.zeros(Shape shape) {
    return InMemoryBackend.filled(shape, 0);
  }

  /// Create in-memory backend with ones
  ///
  /// Example:
  /// ```dart
  /// var backend = InMemoryBackend.ones(Shape([2, 3]));
  /// ```
  factory InMemoryBackend.ones(Shape shape) {
    return InMemoryBackend.filled(shape, 1);
  }

  /// Create in-memory backend from generator function
  ///
  /// Example:
  /// ```dart
  /// var backend = InMemoryBackend.generate(
  ///   Shape([2, 3]),
  ///   (indices) => indices[0] * 3 + indices[1],
  /// );
  /// ```
  factory InMemoryBackend.generate(
    Shape shape,
    dynamic Function(List<int> indices) generator,
  ) {
    List<dynamic> data = [];
    for (int i = 0; i < shape.size; i++) {
      var indices = shape.fromFlatIndex(i);
      data.add(generator(indices));
    }
    return InMemoryBackend(data, shape);
  }

  @override
  dynamic getValue(List<int> indices) {
    trackGet();
    int flatIndex = shape.toFlatIndex(indices);
    return _data[flatIndex];
  }

  @override
  void setValue(List<int> indices, dynamic value) {
    trackSet();
    int flatIndex = shape.toFlatIndex(indices);
    _data[flatIndex] = value;
  }

  @override
  StorageBackend getSlice(List<SliceSpec> slices) {
    if (slices.length != shape.ndim) {
      throw ArgumentError('Number of slices (${slices.length}) must match '
          'number of dimensions (${shape.ndim})');
    }

    // Calculate new shape
    List<int> newDims = [];
    for (int i = 0; i < slices.length; i++) {
      if (!slices[i].isSingleIndex) {
        newDims.add(slices[i].length(shape[i]));
      }
    }

    // If all single indices, return a 1-element backend
    if (newDims.isEmpty) {
      var indices = slices.map((s) => s.start!).toList();
      return InMemoryBackend([getValue(indices)], Shape([1]));
    }

    Shape newShape = Shape(newDims);

    // Extract sliced data
    List<dynamic> newData = [];
    _extractSlicedData(slices, [], 0, newData);

    return InMemoryBackend(newData, newShape);
  }

  /// Recursively extract sliced data
  void _extractSlicedData(
    List<SliceSpec> slices,
    List<int> currentIndices,
    int dim,
    List<dynamic> output,
  ) {
    if (dim == shape.ndim) {
      output.add(getValue(currentIndices));
      return;
    }

    var slice = slices[dim];
    var indices = slice.indices(shape[dim]);

    for (var index in indices) {
      _extractSlicedData(
        slices,
        [...currentIndices, index],
        dim + 1,
        output,
      );
    }
  }

  @override
  Future<void> load() async {
    // Already in memory, no-op
  }

  @override
  Future<void> unload() async {
    // Cannot unload in-memory data
  }

  @override
  List<dynamic> getFlatData({bool copy = false}) {
    return copy ? List.from(_data) : _data;
  }

  @override
  int get memoryUsage {
    // Rough estimate: 8 bytes per element + overhead
    return _data.length * 8 + 100; // 100 bytes overhead
  }

  @override
  bool get isInMemory => true;

  @override
  InMemoryBackend clone() {
    return InMemoryBackend(List.from(_data), shape);
  }

  @override
  String toString() {
    return 'InMemoryBackend(shape: $shape, size: ${_data.length}, '
        'memory: ${_formatBytes(memoryUsage)})';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
