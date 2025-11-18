/// Slice specification for N-dimensional array slicing
///
/// Represents a slice along a single dimension, similar to Python's slice notation.
/// Supports:
/// - Single index: `5`
/// - Range: `start:stop:step`
/// - Open-ended: `:stop`, `start:`, `:`
/// - Negative indices (from end)
///
/// Example:
/// ```dart
/// // Single index
/// var s1 = SliceSpec.single(5);
///
/// // Range [0:10]
/// var s2 = SliceSpec(0, 10);
///
/// // Range [0:10:2] (every other element)
/// var s3 = SliceSpec(0, 10, step: 2);
///
/// // All elements [:]
/// var s4 = SliceSpec.all();
///
/// // From start to 10 [:10]
/// var s5 = SliceSpec(null, 10);
///
/// // From 5 to end [5:]
/// var s6 = SliceSpec(5, null);
/// ```
class SliceSpec {
  /// Start index (inclusive), null means from beginning
  final int? start;

  /// Stop index (exclusive), null means to end
  final int? stop;

  /// Step size, defaults to 1
  final int step;

  /// Create a slice specification
  ///
  /// Parameters:
  /// - `start`: Starting index (inclusive), null for beginning
  /// - `stop`: Stopping index (exclusive), null for end
  /// - `step`: Step size, must be non-zero, defaults to 1
  ///
  /// Example:
  /// ```dart
  /// var slice = SliceSpec(0, 10, step: 2);  // [0:10:2]
  /// ```
  SliceSpec(this.start, this.stop, {this.step = 1}) : _isSingleIndex = false {
    if (step == 0) {
      throw ArgumentError('Step cannot be zero');
    }
  }

  /// Create a single-index slice (not a range)
  ///
  /// This represents selecting a single element, which reduces dimensionality.
  ///
  /// Example:
  /// ```dart
  /// var slice = SliceSpec.single(5);  // Select element at index 5
  /// ```
  SliceSpec.single(int index)
      : start = index,
        stop = index + 1,
        step = 1,
        _isSingleIndex = true;

  /// Create a slice that selects all elements [:]
  ///
  /// Example:
  /// ```dart
  /// var slice = SliceSpec.all();  // Select all elements
  /// ```
  SliceSpec.all()
      : start = null,
        stop = null,
        step = 1,
        _isSingleIndex = false;

  /// Internal flag to track if this is a single index
  final bool _isSingleIndex;

  /// Check if this is a single index (not a range)
  ///
  /// Single indices reduce dimensionality when slicing.
  bool get isSingleIndex => _isSingleIndex;

  /// Resolve slice against a dimension size
  ///
  /// Converts null values and negative indices to actual indices.
  ///
  /// Returns a tuple of (start, stop, step) with all values resolved.
  ///
  /// Example:
  /// ```dart
  /// var slice = SliceSpec(null, -2);
  /// var (start, stop, step) = slice.resolve(10);
  /// // start = 0, stop = 8, step = 1
  /// ```
  (int start, int stop, int step) resolve(int dimSize) {
    if (dimSize < 0) {
      throw ArgumentError('Dimension size must be non-negative');
    }

    // Resolve start
    int resolvedStart;
    if (start == null) {
      resolvedStart = step > 0 ? 0 : dimSize - 1;
    } else {
      resolvedStart = start!;
      if (resolvedStart < 0) {
        resolvedStart += dimSize;
      }
      // Clamp to valid range
      resolvedStart = resolvedStart.clamp(0, dimSize);
    }

    // Resolve stop
    int resolvedStop;
    if (stop == null) {
      resolvedStop = step > 0 ? dimSize : -1;
    } else {
      resolvedStop = stop!;
      if (resolvedStop < 0) {
        resolvedStop += dimSize;
      }
      // Clamp to valid range
      resolvedStop = resolvedStop.clamp(-1, dimSize);
    }

    return (resolvedStart, resolvedStop, step);
  }

  /// Calculate the number of elements this slice will select
  ///
  /// Example:
  /// ```dart
  /// var slice = SliceSpec(0, 10, step: 2);
  /// print(slice.length(10));  // 5 (indices: 0, 2, 4, 6, 8)
  /// ```
  int length(int dimSize) {
    var (start, stop, step) = resolve(dimSize);

    if (step > 0) {
      if (start >= stop) return 0;
      return ((stop - start - 1) ~/ step) + 1;
    } else {
      if (start <= stop) return 0;
      return ((start - stop - 1) ~/ (-step)) + 1;
    }
  }

  /// Get the actual indices this slice will select
  ///
  /// Example:
  /// ```dart
  /// var slice = SliceSpec(0, 10, step: 3);
  /// print(slice.indices(10));  // [0, 3, 6, 9]
  /// ```
  List<int> indices(int dimSize) {
    var (start, stop, step) = resolve(dimSize);
    List<int> result = [];

    if (step > 0) {
      for (int i = start; i < stop; i += step) {
        result.add(i);
      }
    } else {
      for (int i = start; i > stop; i += step) {
        result.add(i);
      }
    }

    return result;
  }

  @override
  String toString() {
    if (isSingleIndex) {
      return '$start';
    }

    String startStr = start?.toString() ?? '';
    String stopStr = stop?.toString() ?? '';
    String stepStr = step != 1 ? ':$step' : '';

    return '$startStr:$stopStr$stepStr';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SliceSpec &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          stop == other.stop &&
          step == other.step &&
          _isSingleIndex == other._isSingleIndex;

  @override
  int get hashCode =>
      start.hashCode ^ stop.hashCode ^ step.hashCode ^ _isSingleIndex.hashCode;
}

/// Helper class for creating common slice specifications
///
/// Provides convenient static methods for creating slices.
///
/// Example:
/// ```dart
/// // All elements
/// var s1 = Slice.all();
///
/// // Range
/// var s2 = Slice.range(0, 10);
///
/// // From start
/// var s3 = Slice.from(5);
///
/// // To end
/// var s4 = Slice.to(10);
///
/// // Single index
/// var s5 = Slice.single(5);
/// ```
class Slice {
  /// Select all elements [:]
  static SliceSpec all() => SliceSpec.all();

  /// Select a range [start:stop:step]
  ///
  /// Example:
  /// ```dart
  /// var slice = Slice.range(0, 10, step: 2);  // [0:10:2]
  /// ```
  static SliceSpec range(int start, int stop, {int step = 1}) =>
      SliceSpec(start, stop, step: step);

  /// Select from start to end [start:]
  ///
  /// Example:
  /// ```dart
  /// var slice = Slice.from(5);  // [5:]
  /// ```
  static SliceSpec from(int start) => SliceSpec(start, null);

  /// Select from beginning to stop [:stop]
  ///
  /// Example:
  /// ```dart
  /// var slice = Slice.to(10);  // [:10]
  /// ```
  static SliceSpec to(int stop) => SliceSpec(null, stop);

  /// Select a single index
  ///
  /// Example:
  /// ```dart
  /// var slice = Slice.single(5);  // [5]
  /// ```
  static SliceSpec single(int index) => SliceSpec.single(index);

  /// Select every nth element [::step]
  ///
  /// Example:
  /// ```dart
  /// var slice = Slice.every(2);  // [::2] (every other element)
  /// ```
  static SliceSpec every(int step) => SliceSpec(null, null, step: step);

  /// Select last n elements [-n:]
  ///
  /// Example:
  /// ```dart
  /// var slice = Slice.last(5);  // [-5:]
  /// ```
  static SliceSpec last(int n) => SliceSpec(-n, null);

  /// Select first n elements [:n]
  ///
  /// Example:
  /// ```dart
  /// var slice = Slice.first(5);  // [:5]
  /// ```
  static SliceSpec first(int n) => SliceSpec(null, n);

  /// Reverse order [::-1]
  ///
  /// Example:
  /// ```dart
  /// var slice = Slice.reverse();  // [::-1]
  /// ```
  static SliceSpec reverse() => SliceSpec(null, null, step: -1);
}

/// Extension to make slicing more convenient
extension SliceExtension on int {
  /// Convert int to single-index SliceSpec
  ///
  /// Example:
  /// ```dart
  /// var slice = 5.toSlice();  // Same as SliceSpec.single(5)
  /// ```
  SliceSpec toSlice() => SliceSpec.single(this);
}
