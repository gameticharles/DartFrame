/// Streaming and chunked processing for NDArray.
library;

import 'dart:async';
import 'ndarray.dart';
import '../core/slice_spec.dart';

/// Extension providing streaming and chunked processing capabilities.
extension Streaming on NDArray {
  /// Streams slices along a specific axis.
  ///
  /// This is useful for processing large arrays that don't fit in memory
  /// or for pipeline-style processing.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray.zeros([1000, 100, 100]);
  /// await for (var slice in arr.streamAlongAxis(0, chunkSize: 10)) {
  ///   // Process 10 slices at a time
  ///   print(slice.shape); // [10, 100, 100]
  /// }
  /// ```
  Stream<NDArray> streamAlongAxis(int axis, {int chunkSize = 1}) {
    if (axis < 0 || axis >= ndim) {
      throw ArgumentError('Axis $axis out of bounds for ${ndim}D array');
    }

    if (chunkSize <= 0) {
      throw ArgumentError('Chunk size must be positive');
    }

    return Stream.fromIterable(_generateChunks(axis, chunkSize));
  }

  /// Generates chunks along an axis.
  Iterable<NDArray> _generateChunks(int axis, int chunkSize) sync* {
    final axisSize = shape[axis];

    for (int start = 0; start < axisSize; start += chunkSize) {
      final end = (start + chunkSize < axisSize) ? start + chunkSize : axisSize;

      // Build slice specification
      final slices = <dynamic>[];
      for (int i = 0; i < ndim; i++) {
        if (i == axis) {
          slices.add(Slice.range(start, end));
        } else {
          slices.add(Slice.all());
        }
      }

      yield slice(slices) as NDArray;
    }
  }

  /// Processes the array in chunks along an axis.
  ///
  /// This method divides the array along the specified axis into chunks,
  /// processes each chunk with the processor function, and combines results
  /// with the combiner function.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9]
  /// ]);
  ///
  /// // Sum each row chunk
  /// var result = await arr.processChunked<num>(
  ///   axis: 0,
  ///   chunkSize: 2,
  ///   processor: (chunk) => chunk.sum(),
  ///   combiner: (results) => results.reduce((a, b) => a + b),
  /// );
  /// print(result); // 45
  /// ```
  Future<R> processChunked<R>({
    required int axis,
    required int chunkSize,
    required dynamic Function(NDArray chunk) processor,
    required R Function(List<dynamic> results) combiner,
  }) async {
    final results = <dynamic>[];

    await for (var chunk in streamAlongAxis(axis, chunkSize: chunkSize)) {
      results.add(processor(chunk));
    }

    return combiner(results);
  }

  /// Processes the array in chunks with a map-reduce pattern.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray.generate([1000, 100], (indices) => indices[0] + indices[1]);
  ///
  /// // Calculate sum using map-reduce
  /// var sum = await arr.mapReduce<num, num>(
  ///   axis: 0,
  ///   chunkSize: 100,
  ///   mapper: (chunk) => chunk.sum(),
  ///   reducer: (a, b) => a + b,
  ///   initialValue: 0,
  /// );
  /// ```
  Future<R> mapReduce<T, R>({
    required int axis,
    required int chunkSize,
    required T Function(NDArray chunk) mapper,
    required R Function(R accumulator, T value) reducer,
    required R initialValue,
  }) async {
    R accumulator = initialValue;

    await for (var chunk in streamAlongAxis(axis, chunkSize: chunkSize)) {
      final mapped = mapper(chunk);
      accumulator = reducer(accumulator, mapped);
    }

    return accumulator;
  }

  /// Applies a function to each chunk and collects results.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9]
  /// ]);
  ///
  /// var means = await arr.mapChunks(
  ///   axis: 0,
  ///   chunkSize: 1,
  ///   mapper: (chunk) => chunk.mean(),
  /// );
  /// print(means); // [2.0, 5.0, 8.0]
  /// ```
  Future<List<T>> mapChunks<T>({
    required int axis,
    required int chunkSize,
    required T Function(NDArray chunk) mapper,
  }) async {
    final results = <T>[];

    await for (var chunk in streamAlongAxis(axis, chunkSize: chunkSize)) {
      results.add(mapper(chunk));
    }

    return results;
  }

  /// Filters chunks based on a predicate.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9]
  /// ]);
  ///
  /// // Keep only rows where sum > 10
  /// var filtered = await arr.filterChunks(
  ///   axis: 0,
  ///   chunkSize: 1,
  ///   predicate: (chunk) => chunk.sum() > 10,
  /// );
  /// ```
  Future<List<NDArray>> filterChunks({
    required int axis,
    required int chunkSize,
    required bool Function(NDArray chunk) predicate,
  }) async {
    final results = <NDArray>[];

    await for (var chunk in streamAlongAxis(axis, chunkSize: chunkSize)) {
      if (predicate(chunk)) {
        results.add(chunk);
      }
    }

    return results;
  }

  /// Processes chunks in batches for better performance.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray.zeros([1000, 100]);
  ///
  /// await arr.batchProcess(
  ///   axis: 0,
  ///   chunkSize: 10,
  ///   batchSize: 5,
  ///   processor: (batch) {
  ///     // Process 5 chunks at once
  ///     for (var chunk in batch) {
  ///       // Do something with chunk
  ///     }
  ///   },
  /// );
  /// ```
  Future<void> batchProcess({
    required int axis,
    required int chunkSize,
    required int batchSize,
    required void Function(List<NDArray> batch) processor,
  }) async {
    final batch = <NDArray>[];

    await for (var chunk in streamAlongAxis(axis, chunkSize: chunkSize)) {
      batch.add(chunk);

      if (batch.length >= batchSize) {
        processor(batch);
        batch.clear();
      }
    }

    // Process remaining chunks
    if (batch.isNotEmpty) {
      processor(batch);
    }
  }

  /// Iterates through the array with a sliding window.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([1, 2, 3, 4, 5]);
  ///
  /// await for (var window in arr.slidingWindow(axis: 0, windowSize: 3)) {
  ///   print(window.toFlatList()); // [1,2,3], [2,3,4], [3,4,5]
  /// }
  /// ```
  Stream<NDArray> slidingWindow({
    required int axis,
    required int windowSize,
    int step = 1,
  }) {
    if (axis < 0 || axis >= ndim) {
      throw ArgumentError('Axis $axis out of bounds for ${ndim}D array');
    }

    if (windowSize <= 0 || windowSize > shape[axis]) {
      throw ArgumentError('Invalid window size: $windowSize');
    }

    if (step <= 0) {
      throw ArgumentError('Step must be positive');
    }

    return Stream.fromIterable(_generateWindows(axis, windowSize, step));
  }

  /// Generates sliding windows.
  Iterable<NDArray> _generateWindows(int axis, int windowSize, int step) sync* {
    final axisSize = shape[axis];

    for (int start = 0; start <= axisSize - windowSize; start += step) {
      final end = start + windowSize;

      // Build slice specification
      final slices = <dynamic>[];
      for (int i = 0; i < ndim; i++) {
        if (i == axis) {
          slices.add(Slice.range(start, end));
        } else {
          slices.add(Slice.all());
        }
      }

      yield slice(slices) as NDArray;
    }
  }

  /// Applies a rolling aggregation along an axis.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([1, 2, 3, 4, 5]);
  ///
  /// var rollingMean = await arr.rollingAggregate(
  ///   axis: 0,
  ///   windowSize: 3,
  ///   aggregator: (window) => window.mean(),
  /// );
  /// print(rollingMean); // [2.0, 3.0, 4.0]
  /// ```
  Future<List<T>> rollingAggregate<T>({
    required int axis,
    required int windowSize,
    required T Function(NDArray window) aggregator,
    int step = 1,
  }) async {
    final results = <T>[];

    await for (var window in slidingWindow(
      axis: axis,
      windowSize: windowSize,
      step: step,
    )) {
      results.add(aggregator(window));
    }

    return results;
  }
}
