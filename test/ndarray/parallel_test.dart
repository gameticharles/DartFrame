import 'package:test/test.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';
import 'package:dartframe/src/ndarray/parallel.dart';
import 'package:dartframe/src/ndarray/operations.dart';
import 'package:dartframe/src/core/slice_spec.dart';

void main() {
  group('Parallel Process', () {
    test('parallel sum', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final result = await arr.parallelProcess<num>(
        axis: 0,
        chunkSize: 1,
        processor: (chunk) => chunk.sum(),
        combiner: (results) => results.reduce((a, b) => a + b),
      );

      expect(result, 45);
    });

    test('parallel with multiple chunks', () async {
      final arr = NDArray([
        [1, 2],
        [3, 4],
        [5, 6],
        [7, 8]
      ]);

      final result = await arr.parallelProcess<num>(
        axis: 0,
        chunkSize: 2,
        processor: (chunk) => chunk.sum(),
        combiner: (results) => results.reduce((a, b) => a + b),
      );

      expect(result, 36);
    });

    test('parallel with custom worker count', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);

      final result = await arr.parallelProcess<num>(
        axis: 0,
        chunkSize: 1,
        processor: (chunk) => chunk.sum(),
        combiner: (results) => results.reduce((a, b) => a + b),
        maxWorkers: 2,
      );

      expect(result, 21);
    });

    test('parallel collect results', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final result = await arr.parallelProcess<List<num>>(
        axis: 0,
        chunkSize: 1,
        processor: (chunk) => chunk.sum(),
        combiner: (results) => results.cast<num>(),
      );

      expect(result, [6, 15, 24]);
    });
  });

  group('Parallel Map Reduce', () {
    test('sum with map reduce', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final result = await arr.parallelMapReduce<num, num>(
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

      final result = await arr.parallelMapReduce<num, num>(
        axis: 0,
        chunkSize: 1,
        mapper: (chunk) => chunk.max(),
        reducer: (acc, val) => acc > val ? acc : val,
        initialValue: double.negativeInfinity,
      );

      expect(result, 8);
    });

    test('count with map reduce', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final result = await arr.parallelMapReduce<int, int>(
        axis: 0,
        chunkSize: 1,
        mapper: (chunk) => chunk.size,
        reducer: (acc, val) => acc + val,
        initialValue: 0,
      );

      expect(result, 9);
    });
  });

  group('Parallel Map', () {
    test('map to means', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final means = await arr.parallelMap<double>(
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

      final sums = await arr.parallelMap<num>(
        axis: 0,
        chunkSize: 1,
        mapper: (chunk) => chunk.sum(),
      );

      expect(sums, [3, 7, 11]);
    });

    test('map with larger chunks', () async {
      final arr = NDArray([
        [1, 2],
        [3, 4],
        [5, 6],
        [7, 8]
      ]);

      final sums = await arr.parallelMap<num>(
        axis: 0,
        chunkSize: 2,
        mapper: (chunk) => chunk.sum(),
      );

      expect(sums, [10, 26]);
    });
  });

  group('Parallel Element-wise', () {
    test('square all elements', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);

      final result = await arr.parallelElementWise(
        operation: (x) => x * x,
        chunkSize: 1,
      );

      expect(result.getValue([0, 0]), 1);
      expect(result.getValue([0, 2]), 9);
      expect(result.getValue([1, 0]), 16);
      expect(result.getValue([1, 2]), 36);
    });

    test('add constant', () async {
      final arr = NDArray([1, 2, 3, 4]);

      final result = await arr.parallelElementWise(
        operation: (x) => x + 10,
        chunkSize: 2,
      );

      expect(result.toFlatList(), [11, 12, 13, 14]);
    });

    test('complex transformation', () async {
      final arr = NDArray([
        [1, 2],
        [3, 4]
      ]);

      final result = await arr.parallelElementWise(
        operation: (x) => x * 2 + 1,
        chunkSize: 1,
      );

      expect(result.getValue([0, 0]), 3);
      expect(result.getValue([0, 1]), 5);
      expect(result.getValue([1, 0]), 7);
      expect(result.getValue([1, 1]), 9);
    });
  });

  group('Parallel Config', () {
    test('max workers configuration', () {
      final originalMaxWorkers = ParallelConfig.maxWorkers;

      ParallelConfig.maxWorkers = 2;
      expect(ParallelConfig.maxWorkers, 2);

      // Restore
      ParallelConfig.maxWorkers = originalMaxWorkers;
    });

    test('min chunk size configuration', () {
      final originalMinChunkSize = ParallelConfig.minChunkSize;

      ParallelConfig.minChunkSize = 50;
      expect(ParallelConfig.minChunkSize, 50);

      // Restore
      ParallelConfig.minChunkSize = originalMinChunkSize;
    });

    test('enabled flag', () {
      final originalEnabled = ParallelConfig.enabled;

      ParallelConfig.enabled = false;
      expect(ParallelConfig.enabled, false);

      // Restore
      ParallelConfig.enabled = originalEnabled;
    });
  });

  group('Edge Cases', () {
    test('single chunk', () async {
      final arr = NDArray([1, 2, 3]);

      final result = await arr.parallelProcess<num>(
        axis: 0,
        chunkSize: 10,
        processor: (chunk) => chunk.sum(),
        combiner: (results) => results.reduce((a, b) => a + b),
      );

      expect(result, 6);
    });

    test('empty combiner', () async {
      final arr = NDArray([1, 2, 3]);

      final result = await arr.parallelProcess<int>(
        axis: 0,
        chunkSize: 1,
        processor: (chunk) => chunk.size,
        combiner: (results) => results.isEmpty ? 0 : results.length,
      );

      expect(result, 3);
    });

    test('1D array', () async {
      final arr = NDArray([1, 2, 3, 4, 5]);

      final result = await arr.parallelMap<num>(
        axis: 0,
        chunkSize: 2,
        mapper: (chunk) => chunk.sum(),
      );

      expect(result.length, 3); // [1+2, 3+4, 5]
      expect(result[0], 3);
      expect(result[1], 7);
      expect(result[2], 5);
    });

    test('3D array', () async {
      final arr = NDArray([
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ]
      ]);

      final result = await arr.parallelProcess<num>(
        axis: 0,
        chunkSize: 1,
        processor: (chunk) => chunk.sum(),
        combiner: (results) => results.reduce((a, b) => a + b),
      );

      expect(result, 36);
    });
  });

  group('Performance Scenarios', () {
    test('large array processing', () async {
      final arr =
          NDArray.generate([100, 10], (indices) => indices[0] + indices[1]);

      final result = await arr.parallelProcess<num>(
        axis: 0,
        chunkSize: 25,
        processor: (chunk) => chunk.sum(),
        combiner: (results) => results.reduce((a, b) => a + b),
      );

      expect(result, arr.sum());
    });

    test('parallel vs sequential consistency', () async {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ]);

      final parallelResult = await arr.parallelMap<double>(
        axis: 0,
        chunkSize: 1,
        mapper: (chunk) => chunk.mean(),
      );

      final sequentialResult = [
        (arr.slice([0, Slice.all()]) as NDArray).mean(),
        (arr.slice([1, Slice.all()]) as NDArray).mean(),
        (arr.slice([2, Slice.all()]) as NDArray).mean(),
      ];

      expect(parallelResult, sequentialResult);
    });
  });
}
