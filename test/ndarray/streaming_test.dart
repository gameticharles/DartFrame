import 'package:test/test.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';
import 'package:dartframe/src/ndarray/streaming.dart';
import 'package:dartframe/src/ndarray/operations.dart';

void main() {
  group('Stream Along Axis', () {
    test('stream 2D array along axis 0', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final chunks = <NDArray>[];
      await for (var chunk in arr.streamAlongAxis(0, chunkSize: 1)) {
        chunks.add(chunk);
      }

      expect(chunks.length, 3);
      expect(chunks[0].shape.toList(), [1, 3]);
      expect(chunks[0].getValue([0, 0]), 1);
      expect(chunks[2].getValue([0, 2]), 9);
    });

    test('stream with chunk size > 1', () async {
      final arr = NDArray([
        [1, 2],
        [3, 4],
        [5, 6],
        [7, 8]
      ]);

      final chunks = <NDArray>[];
      await for (var chunk in arr.streamAlongAxis(0, chunkSize: 2)) {
        chunks.add(chunk);
      }

      expect(chunks.length, 2);
      expect(chunks[0].shape.toList(), [2, 2]);
      expect(chunks[0].getValue([0, 0]), 1);
      expect(chunks[0].getValue([1, 1]), 4);
      expect(chunks[1].getValue([0, 0]), 5);
    });

    test('stream along axis 1', () async {
      final arr = NDArray([
        [1, 2, 3, 4],
        [5, 6, 7, 8]
      ]);

      final chunks = <NDArray>[];
      await for (var chunk in arr.streamAlongAxis(1, chunkSize: 2)) {
        chunks.add(chunk);
      }

      expect(chunks.length, 2);
      expect(chunks[0].shape.toList(), [2, 2]);
      expect(chunks[0].getValue([0, 0]), 1);
      expect(chunks[1].getValue([0, 0]), 3);
    });

    test('stream 3D array', () async {
      final arr = NDArray([
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ],
        [
          [9, 10],
          [11, 12]
        ]
      ]);

      final chunks = <NDArray>[];
      await for (var chunk in arr.streamAlongAxis(0, chunkSize: 1)) {
        chunks.add(chunk);
      }

      expect(chunks.length, 3);
      expect(chunks[0].shape.toList(), [1, 2, 2]);
    });

    test('invalid axis throws', () {
      final arr = NDArray([1, 2, 3]);
      expect(
        () => arr.streamAlongAxis(5),
        throwsArgumentError,
      );
    });

    test('invalid chunk size throws', () {
      final arr = NDArray([1, 2, 3]);
      expect(
        () => arr.streamAlongAxis(0, chunkSize: 0),
        throwsArgumentError,
      );
    });
  });

  group('Process Chunked', () {
    test('sum chunks', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final result = await arr.processChunked<num>(
        axis: 0,
        chunkSize: 1,
        processor: (chunk) => chunk.sum(),
        combiner: (results) => results.reduce((a, b) => a + b),
      );

      expect(result, 45);
    });

    test('collect means', () async {
      final arr = NDArray([
        [2, 4, 6],
        [8, 10, 12]
      ]);

      final result = await arr.processChunked<List<double>>(
        axis: 0,
        chunkSize: 1,
        processor: (chunk) => chunk.mean(),
        combiner: (results) => results.cast<double>(),
      );

      expect(result.length, 2);
      expect(result[0], 4.0);
      expect(result[1], 10.0);
    });
  });

  group('Map Reduce', () {
    test('sum with map reduce', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final result = await arr.mapReduce<num, num>(
        axis: 0,
        chunkSize: 1,
        mapper: (chunk) => chunk.sum(),
        reducer: (acc, val) => acc + val,
        initialValue: 0,
      );

      expect(result, 45);
    });

    test('max with map reduce', () async {
      final arr = NDArray([
        [1, 5, 3],
        [4, 2, 6],
        [7, 8, 1]
      ]);

      final result = await arr.mapReduce<num, num>(
        axis: 0,
        chunkSize: 1,
        mapper: (chunk) => chunk.max(),
        reducer: (acc, val) => acc > val ? acc : val,
        initialValue: double.negativeInfinity,
      );

      expect(result, 8);
    });

    test('count elements > threshold', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final result = await arr.mapReduce<int, int>(
        axis: 0,
        chunkSize: 1,
        mapper: (chunk) => chunk.where((x) => x > 5).size,
        reducer: (acc, val) => acc + val,
        initialValue: 0,
      );

      expect(result, 4); // 6, 7, 8, 9
    });
  });

  group('Map Chunks', () {
    test('map to means', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final means = await arr.mapChunks<double>(
        axis: 0,
        chunkSize: 1,
        mapper: (chunk) => chunk.mean(),
      );

      expect(means.length, 3);
      expect(means[0], 2.0);
      expect(means[1], 5.0);
      expect(means[2], 8.0);
    });

    test('map to sums', () async {
      final arr = NDArray([
        [1, 2],
        [3, 4],
        [5, 6]
      ]);

      final sums = await arr.mapChunks<num>(
        axis: 0,
        chunkSize: 1,
        mapper: (chunk) => chunk.sum(),
      );

      expect(sums, [3, 7, 11]);
    });
  });

  group('Filter Chunks', () {
    test('filter by sum', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final filtered = await arr.filterChunks(
        axis: 0,
        chunkSize: 1,
        predicate: (chunk) => chunk.sum() > 10,
      );

      expect(filtered.length, 2);
      expect(filtered[0].getValue([0, 0]), 4);
      expect(filtered[1].getValue([0, 0]), 7);
    });

    test('filter by mean', () async {
      final arr = NDArray([
        [1, 1, 1],
        [5, 5, 5],
        [2, 2, 2]
      ]);

      final filtered = await arr.filterChunks(
        axis: 0,
        chunkSize: 1,
        predicate: (chunk) => chunk.mean() > 3,
      );

      expect(filtered.length, 1);
      expect(filtered[0].getValue([0, 0]), 5);
    });
  });

  group('Batch Process', () {
    test('process in batches', () async {
      final arr = NDArray([
        [1, 2],
        [3, 4],
        [5, 6],
        [7, 8],
        [9, 10]
      ]);

      final batchSizes = <int>[];
      await arr.batchProcess(
        axis: 0,
        chunkSize: 1,
        batchSize: 2,
        processor: (batch) {
          batchSizes.add(batch.length);
        },
      );

      expect(batchSizes, [2, 2, 1]); // 2 full batches + 1 remainder
    });

    test('process all in one batch', () async {
      final arr = NDArray([
        [1, 2],
        [3, 4]
      ]);

      var processedCount = 0;
      await arr.batchProcess(
        axis: 0,
        chunkSize: 1,
        batchSize: 10,
        processor: (batch) {
          processedCount++;
          expect(batch.length, 2);
        },
      );

      expect(processedCount, 1);
    });
  });

  group('Sliding Window', () {
    test('sliding window size 3', () async {
      final arr = NDArray([1, 2, 3, 4, 5]);

      final windows = <NDArray>[];
      await for (var window in arr.slidingWindow(axis: 0, windowSize: 3)) {
        windows.add(window);
      }

      expect(windows.length, 3);
      expect(windows[0].toFlatList(), [1, 2, 3]);
      expect(windows[1].toFlatList(), [2, 3, 4]);
      expect(windows[2].toFlatList(), [3, 4, 5]);
    });

    test('sliding window with step', () async {
      final arr = NDArray([1, 2, 3, 4, 5, 6]);

      final windows = <NDArray>[];
      await for (var window
          in arr.slidingWindow(axis: 0, windowSize: 2, step: 2)) {
        windows.add(window);
      }

      expect(windows.length, 3);
      expect(windows[0].toFlatList(), [1, 2]);
      expect(windows[1].toFlatList(), [3, 4]);
      expect(windows[2].toFlatList(), [5, 6]);
    });

    test('sliding window 2D', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final windows = <NDArray>[];
      await for (var window in arr.slidingWindow(axis: 0, windowSize: 2)) {
        windows.add(window);
      }

      expect(windows.length, 2);
      expect(windows[0].shape.toList(), [2, 3]);
      expect(windows[0].getValue([0, 0]), 1);
      expect(windows[1].getValue([0, 0]), 4);
    });

    test('invalid window size throws', () {
      final arr = NDArray([1, 2, 3]);
      expect(
        () => arr.slidingWindow(axis: 0, windowSize: 10),
        throwsArgumentError,
      );
    });
  });

  group('Rolling Aggregate', () {
    test('rolling mean', () async {
      final arr = NDArray([1, 2, 3, 4, 5]);

      final means = await arr.rollingAggregate<double>(
        axis: 0,
        windowSize: 3,
        aggregator: (window) => window.mean(),
      );

      expect(means.length, 3);
      expect(means[0], 2.0); // (1+2+3)/3
      expect(means[1], 3.0); // (2+3+4)/3
      expect(means[2], 4.0); // (3+4+5)/3
    });

    test('rolling sum', () async {
      final arr = NDArray([1, 2, 3, 4, 5]);

      final sums = await arr.rollingAggregate<num>(
        axis: 0,
        windowSize: 2,
        aggregator: (window) => window.sum(),
      );

      expect(sums, [3, 5, 7, 9]); // 1+2, 2+3, 3+4, 4+5
    });

    test('rolling max', () async {
      final arr = NDArray([1, 5, 3, 7, 2]);

      final maxes = await arr.rollingAggregate<num>(
        axis: 0,
        windowSize: 3,
        aggregator: (window) => window.max(),
      );

      expect(maxes, [5, 7, 7]);
    });

    test('rolling with step', () async {
      final arr = NDArray([1, 2, 3, 4, 5, 6]);

      final sums = await arr.rollingAggregate<num>(
        axis: 0,
        windowSize: 2,
        aggregator: (window) => window.sum(),
        step: 2,
      );

      expect(sums, [3, 7, 11]); // 1+2, 3+4, 5+6
    });
  });

  group('Complex Streaming Scenarios', () {
    test('pipeline processing', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      // Filter rows where sum > 10, then sum the filtered results
      final filtered = await arr.filterChunks(
        axis: 0,
        chunkSize: 1,
        predicate: (chunk) => chunk.sum() > 10,
      );

      num total = 0;
      for (var chunk in filtered) {
        total += chunk.sum();
      }

      expect(total, 39); // 15 + 24
    });

    test('streaming with transformation', () async {
      final arr = NDArray([
        [1, 2],
        [3, 4],
        [5, 6]
      ]);

      final transformed = <num>[];
      await for (var chunk in arr.streamAlongAxis(0, chunkSize: 1)) {
        final doubled = chunk * 2;
        transformed.add(doubled.sum());
      }

      expect(transformed, [6, 14, 22]);
    });
  });
}
