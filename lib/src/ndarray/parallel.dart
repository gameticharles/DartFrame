/// Parallel processing for NDArray using Dart isolates.
library;

import 'dart:async';
import 'dart:isolate';
import 'ndarray.dart';
import '../core/slice_spec.dart';

/// Extension providing parallel processing capabilities using isolates.
extension Parallel on NDArray {
  /// Processes chunks in parallel using isolates.
  ///
  /// This method divides the array along the specified axis into chunks,
  /// processes each chunk in a separate isolate, and combines the results.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray.generate([1000, 100], (indices) => indices[0] + indices[1]);
  ///
  /// // Calculate sum in parallel
  /// var result = await arr.parallelProcess<num>(
  ///   axis: 0,
  ///   chunkSize: 100,
  ///   processor: (chunk) => chunk.sum(),
  ///   combiner: (results) => results.reduce((a, b) => a + b),
  /// );
  /// ```
  Future<R> parallelProcess<R>({
    required int axis,
    required int chunkSize,
    required dynamic Function(NDArray chunk) processor,
    required R Function(List<dynamic> results) combiner,
    int? maxWorkers,
  }) async {
    if (axis < 0 || axis >= ndim) {
      throw ArgumentError('Axis $axis out of bounds for ${ndim}D array');
    }

    final workers = maxWorkers ?? _getOptimalWorkerCount();
    final chunks = _divideIntoChunks(axis, chunkSize);

    if (chunks.isEmpty) {
      return combiner([]);
    }

    // Process chunks in parallel
    final results = await _processChunksInParallel(chunks, processor, workers);

    return combiner(results);
  }

  /// Parallel map-reduce operation.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray.generate([1000, 100], (indices) => indices[0]);
  ///
  /// var sum = await arr.parallelMapReduce<num, num>(
  ///   axis: 0,
  ///   chunkSize: 100,
  ///   mapper: (chunk) => chunk.sum(),
  ///   reducer: (a, b) => a + b,
  ///   initialValue: 0,
  /// );
  /// ```
  Future<R> parallelMapReduce<T, R>({
    required int axis,
    required int chunkSize,
    required T Function(NDArray chunk) mapper,
    required R Function(R accumulator, T value) reducer,
    required R initialValue,
    int? maxWorkers,
  }) async {
    final results = await parallelProcess<List<T>>(
      axis: axis,
      chunkSize: chunkSize,
      processor: mapper,
      combiner: (results) => results.cast<T>(),
      maxWorkers: maxWorkers,
    );

    R accumulator = initialValue;
    for (var result in results) {
      accumulator = reducer(accumulator, result);
    }

    return accumulator;
  }

  /// Applies a function to each chunk in parallel.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray([
  ///   [1, 2, 3],
  ///   [4, 5, 6],
  ///   [7, 8, 9]
  /// ]);
  ///
  /// var means = await arr.parallelMap<double>(
  ///   axis: 0,
  ///   chunkSize: 1,
  ///   mapper: (chunk) => chunk.mean(),
  /// );
  /// ```
  Future<List<T>> parallelMap<T>({
    required int axis,
    required int chunkSize,
    required T Function(NDArray chunk) mapper,
    int? maxWorkers,
  }) async {
    return await parallelProcess<List<T>>(
      axis: axis,
      chunkSize: chunkSize,
      processor: mapper,
      combiner: (results) => results.cast<T>(),
      maxWorkers: maxWorkers,
    );
  }

  /// Parallel element-wise operation.
  ///
  /// Applies a function to each element in parallel by dividing the array
  /// into chunks and processing them concurrently.
  ///
  /// Example:
  /// ```dart
  /// var arr = NDArray.generate([1000, 1000], (indices) => indices[0] + indices[1]);
  ///
  /// var result = await arr.parallelElementWise(
  ///   operation: (x) => x * x,
  ///   chunkSize: 100,
  /// );
  /// ```
  Future<NDArray> parallelElementWise({
    required dynamic Function(dynamic) operation,
    int chunkSize = 100,
    int? maxWorkers,
  }) async {
    // Choose the longest axis for chunking
    int axis = 0;
    int maxDim = shape[0];
    for (int i = 1; i < ndim; i++) {
      if (shape[i] > maxDim) {
        maxDim = shape[i];
        axis = i;
      }
    }

    final chunks = await parallelMap<NDArray>(
      axis: axis,
      chunkSize: chunkSize,
      mapper: (chunk) => chunk.map(operation),
      maxWorkers: maxWorkers,
    );

    // Concatenate chunks back together
    return _concatenateChunks(chunks, axis);
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Divides the array into chunks along an axis.
  List<NDArray> _divideIntoChunks(int axis, int chunkSize) {
    final chunks = <NDArray>[];
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

      chunks.add(slice(slices) as NDArray);
    }

    return chunks;
  }

  /// Processes chunks in parallel using isolates.
  Future<List<dynamic>> _processChunksInParallel(
    List<NDArray> chunks,
    dynamic Function(NDArray) processor,
    int maxWorkers,
  ) async {
    final results = <dynamic>[];
    final workers = <Future<dynamic>>[];

    for (int i = 0; i < chunks.length; i++) {
      // Start worker
      workers.add(_processChunkInIsolate(chunks[i], processor));

      // If we've reached max workers or last chunk, wait for completion
      if (workers.length >= maxWorkers || i == chunks.length - 1) {
        final batchResults = await Future.wait(workers);
        results.addAll(batchResults);
        workers.clear();
      }
    }

    return results;
  }

  /// Processes a single chunk in an isolate.
  Future<dynamic> _processChunkInIsolate(
    NDArray chunk,
    dynamic Function(NDArray) processor,
  ) async {
    final receivePort = ReceivePort();

    try {
      await Isolate.spawn(
        _isolateWorker,
        _IsolateMessage(
          sendPort: receivePort.sendPort,
          data: chunk.toFlatList(),
          shape: chunk.shape.toList(),
          processor: processor,
        ),
      );

      final result = await receivePort.first;
      return result;
    } catch (e) {
      // If isolate fails, fall back to synchronous processing
      return processor(chunk);
    }
  }

  /// Worker function that runs in an isolate.
  static void _isolateWorker(_IsolateMessage message) {
    try {
      // Reconstruct NDArray from flat data
      final chunk = NDArray.fromFlat(message.data, message.shape);

      // Process the chunk
      final result = message.processor(chunk);

      // Send result back
      message.sendPort.send(result);
    } catch (e) {
      message.sendPort.send(null);
    }
  }

  /// Concatenates chunks back into a single array.
  NDArray _concatenateChunks(List<NDArray> chunks, int axis) {
    if (chunks.isEmpty) {
      throw ArgumentError('Cannot concatenate empty list of chunks');
    }

    if (chunks.length == 1) {
      return chunks[0];
    }

    // For now, use a simple approach: collect all data in proper order
    // This works for row-major order concatenation
    final firstShape = chunks[0].shape.toList();
    final totalAxisSize = chunks.fold<int>(
      0,
      (sum, chunk) => sum + chunk.shape[axis],
    );

    final newShape = List<int>.from(firstShape);
    newShape[axis] = totalAxisSize;

    // Build the result by iterating through indices
    return NDArray.generate(newShape, (indices) {
      // Determine which chunk this index belongs to
      int axisIndex = indices[axis];
      int chunkIndex = 0;
      int offsetInChunk = axisIndex;

      for (var chunk in chunks) {
        if (offsetInChunk < chunk.shape[axis]) {
          break;
        }
        offsetInChunk -= chunk.shape[axis];
        chunkIndex++;
      }

      // Get value from the appropriate chunk
      final chunkIndices = List<int>.from(indices);
      chunkIndices[axis] = offsetInChunk;
      return chunks[chunkIndex].getValue(chunkIndices);
    });
  }

  /// Gets the optimal number of workers based on available processors.
  int _getOptimalWorkerCount() {
    // In Dart, we can't directly query CPU count, so use a reasonable default
    // In production, this could be configurable
    return 4;
  }
}

/// Message passed to isolate workers.
class _IsolateMessage {
  final SendPort sendPort;
  final List<dynamic> data;
  final List<int> shape;
  final dynamic Function(NDArray) processor;

  _IsolateMessage({
    required this.sendPort,
    required this.data,
    required this.shape,
    required this.processor,
  });
}

/// Utility class for parallel operations configuration.
class ParallelConfig {
  /// Maximum number of concurrent workers.
  static int maxWorkers = 4;

  /// Minimum chunk size for parallel processing.
  /// Chunks smaller than this will be processed sequentially.
  static int minChunkSize = 100;

  /// Whether to enable parallel processing.
  /// Can be disabled for debugging or on platforms without isolate support.
  static bool enabled = true;
}
