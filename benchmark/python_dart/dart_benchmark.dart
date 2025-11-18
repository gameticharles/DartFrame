import 'dart:math';
import 'package:dartframe/dartframe.dart';

/// Benchmark result
class BenchmarkResult {
  final String name;
  final double avgMs;
  final double minMs;
  final double maxMs;

  BenchmarkResult(this.name, this.avgMs, this.minMs, this.maxMs);

  @override
  String toString() {
    return '${name.padRight(50)} | Avg: ${avgMs.toStringAsFixed(2).padLeft(8)}ms | Min: ${minMs.toStringAsFixed(2).padLeft(8)}ms | Max: ${maxMs.toStringAsFixed(2).padLeft(8)}ms';
  }
}

/// Run benchmark and return timing results
BenchmarkResult benchmark(Function func, String name, {int iterations = 5}) {
  final times = <double>[];

  for (var i = 0; i < iterations; i++) {
    final stopwatch = Stopwatch()..start();
    func();
    stopwatch.stop();
    times.add(stopwatch.elapsedMicroseconds / 1000); // Convert to milliseconds
  }

  final avgTime = times.reduce((a, b) => a + b) / times.length;
  final minTime = times.reduce(min);
  final maxTime = times.reduce(max);

  return BenchmarkResult(name, avgTime, minTime, maxTime);
}

// ============ NDArray Benchmarks ============

void ndarrayCreationSmall() {
  NDArray.zeros([100, 100]);
}

void ndarrayCreationMedium() {
  NDArray.zeros([1000, 1000]);
}

void ndarrayCreationLarge() {
  NDArray.zeros([5000, 5000]);
}

void ndarraySumSmall() {
  final arr = NDArray.generate([100, 100], (indices) => Random().nextDouble());
  arr.sum();
}

void ndarraySumMedium() {
  final arr =
      NDArray.generate([1000, 1000], (indices) => Random().nextDouble());
  arr.sum();
}

void ndarraySumLarge() {
  final arr =
      NDArray.generate([5000, 5000], (indices) => Random().nextDouble());
  arr.sum();
}

void ndarrayMean() {
  final arr =
      NDArray.generate([1000, 1000], (indices) => Random().nextDouble());
  arr.mean();
}

void ndarrayStd() {
  final arr =
      NDArray.generate([1000, 1000], (indices) => Random().nextDouble());
  arr.std();
}

void ndarraySlicing() {
  final arr =
      NDArray.generate([1000, 1000], (indices) => Random().nextDouble());
  arr.slice([Slice.range(100, 200), Slice.range(200, 300)]);
}

// ============ DataFrame Benchmarks ============

void dataframeCreationSmall() {
  final data = List.generate(
      100, (i) => List.generate(10, (j) => Random().nextDouble()));
  DataFrame(data);
}

void dataframeCreationMedium() {
  final data = List.generate(
      10000, (i) => List.generate(10, (j) => Random().nextDouble()));
  DataFrame(data);
}

void dataframeCreationLarge() {
  final data = List.generate(
      100000, (i) => List.generate(10, (j) => Random().nextDouble()));
  DataFrame(data);
}

void dataframeColumnAccess() {
  final data = List.generate(
      10000, (i) => List.generate(10, (j) => Random().nextDouble()));
  final df = DataFrame(data);
  final col = df['Column1'];
  // Just access the column
  col.data.length;
}

void dataframeRowAccess() {
  final data = List.generate(
      10000, (i) => List.generate(10, (j) => Random().nextDouble()));
  final df = DataFrame(data);
  df.iloc[0];
}

void dataframeValueAccess() {
  final data = List.generate(
      10000, (i) => List.generate(10, (j) => Random().nextDouble()));
  final df = DataFrame(data);
  df.iloc(0, 0);
}

void dataframeGroupBy() {
  final categories = ['A', 'B', 'C'];
  final data = List.generate(10000, (i) {
    return {
      'category': categories[Random().nextInt(3)],
      'value': Random().nextDouble()
    };
  });
  final df = DataFrame.fromRows(data);
  df.groupBy(['category']);
}

void dataframeFiltering() {
  final data = List.generate(
      10000, (i) => List.generate(10, (j) => Random().nextDouble()));
  final df = DataFrame(data);
  df[df['Column1'] > 0.5];
}

void dataframeSorting() {
  final data = List.generate(
      10000, (i) => List.generate(10, (j) => Random().nextDouble()));
  final df = DataFrame(data);
  df.sort('Column1');
}

void dataframeMerge() {
  final df1 = DataFrame.fromMap({
    'key': List.generate(1000, (i) => i),
    'value1': List.generate(1000, (i) => Random().nextDouble())
  });
  final df2 = DataFrame.fromMap({
    'key': List.generate(1000, (i) => i),
    'value2': List.generate(1000, (i) => Random().nextDouble())
  });
  df1.merge(df2, on: 'key');
}

void dataframeRollingWindow() {
  final df = DataFrame.fromMap(
      {'value': List.generate(10000, (i) => Random().nextDouble())});
  df.rollingWindow(100).mean();
}

void dataframeStringOperations() {
  final s = Series(
      List.generate(3000, (i) => ['hello', 'world', 'dart'][i % 3]),
      name: 'text');
  s.str.upper();
}

void dataframeCategorical() {
  final s =
      Series(List.generate(3000, (i) => ['A', 'B', 'C'][i % 3]), name: 'cat');
  s.astype('category');
  s.valueCounts();
}

// ============ Main Benchmark Runner ============

void main() {
  print('=' * 100);
  print('DartFrame Performance Benchmark');
  print('=' * 100);
  print('');

  // NDArray Benchmarks
  print('NDArray Operations:');
  print('-' * 100);

  final ndarrayBenchmarks = [
    (ndarrayCreationSmall, 'Array Creation (100x100)'),
    (ndarrayCreationMedium, 'Array Creation (1000x1000)'),
    (ndarrayCreationLarge, 'Array Creation (5000x5000)'),
    (ndarraySumSmall, 'Array Sum (100x100)'),
    (ndarraySumMedium, 'Array Sum (1000x1000)'),
    (ndarraySumLarge, 'Array Sum (5000x5000)'),
    (ndarrayMean, 'Array Mean (1000x1000)'),
    (ndarrayStd, 'Array Std (1000x1000)'),
    (ndarraySlicing, 'Array Slicing (1000x1000)'),
  ];

  for (final item in ndarrayBenchmarks) {
    final result = benchmark(item.$1, item.$2);
    print(result);
  }

  print('');
  print('DataFrame Operations:');
  print('-' * 100);

  final dataframeBenchmarks = [
    (dataframeCreationSmall, 'DataFrame Creation (100x10)'),
    (dataframeCreationMedium, 'DataFrame Creation (10000x10)'),
    (dataframeCreationLarge, 'DataFrame Creation (100000x10)'),
    (dataframeColumnAccess, 'Column Access (10000 rows)'),
    (dataframeRowAccess, 'Row Access (10000 rows)'),
    (dataframeValueAccess, 'Value Access (10000 rows)'),
    (dataframeGroupBy, 'GroupBy (10000 rows)'),
    (dataframeFiltering, 'Filtering (10000 rows)'),
    (dataframeSorting, 'Sorting (10000 rows)'),
    (dataframeMerge, 'Merge (1000 rows each)'),
    (dataframeRollingWindow, 'Rolling Window (10000 rows)'),
    (dataframeStringOperations, 'String Operations (3000 items)'),
    (dataframeCategorical, 'Categorical Operations (3000 items)'),
  ];

  for (final item in dataframeBenchmarks) {
    final result = benchmark(item.$1, item.$2);
    print(result);
  }

  print('');
  print('=' * 100);
  print('Benchmark Complete!');
  print('=' * 100);
}
