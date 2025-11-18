import 'dart:math';
import 'package:dartframe/dartframe.dart';

class BenchmarkResult {
  final String name;
  final double avgMs;

  BenchmarkResult(this.name, this.avgMs);

  @override
  String toString() {
    return '${name.padRight(50)} | ${avgMs.toStringAsFixed(2).padLeft(10)}ms';
  }
}

BenchmarkResult benchmark(Function func, String name, {int iterations = 5}) {
  final times = <double>[];

  for (var i = 0; i < iterations; i++) {
    final stopwatch = Stopwatch()..start();
    func();
    stopwatch.stop();
    times.add(stopwatch.elapsedMicroseconds / 1000);
  }

  final avgTime = times.reduce((a, b) => a + b) / times.length;
  return BenchmarkResult(name, avgTime);
}

void main() {
  print('=' * 80);
  print('DartFrame Performance Benchmark');
  print('=' * 80);
  print('');

  // NDArray Benchmarks
  print('NDArray Operations:');
  print('-' * 80);

  print(benchmark(() => NDArray.zeros([100, 100]), 'Array Creation (100x100)'));
  print(benchmark(
      () => NDArray.zeros([1000, 1000]), 'Array Creation (1000x1000)'));
  print(benchmark(() {
    final arr = NDArray.generate([100, 100], (i) => Random().nextDouble());
    arr.sum();
  }, 'Array Sum (100x100)'));
  print(benchmark(() {
    final arr = NDArray.generate([1000, 1000], (i) => Random().nextDouble());
    arr.sum();
  }, 'Array Sum (1000x1000)'));

  print('');
  print('DataFrame Operations:');
  print('-' * 80);

  print(benchmark(() {
    final data = List.generate(
        100, (i) => List.generate(10, (j) => Random().nextDouble()));
    DataFrame(data);
  }, 'DataFrame Creation (100x10)'));

  print(benchmark(() {
    final data = List.generate(
        10000, (i) => List.generate(10, (j) => Random().nextDouble()));
    DataFrame(data);
  }, 'DataFrame Creation (10000x10)'));

  print(benchmark(() {
    final data = List.generate(
        10000, (i) => List.generate(10, (j) => Random().nextDouble()));
    final df = DataFrame(data);
    df['Column1'];
  }, 'Column Access (10000 rows)'));

  print(benchmark(() {
    final data = List.generate(
        10000, (i) => List.generate(10, (j) => Random().nextDouble()));
    final df = DataFrame(data);
    df.iloc(0, 0);
  }, 'Value Access (10000 rows)'));

  print(benchmark(() {
    final data = List.generate(
        1000, (i) => List.generate(10, (j) => Random().nextDouble()));
    final df = DataFrame(data);
    df.head();
  }, 'Head Operation (1000 rows)'));

  print(benchmark(() {
    final data = List.generate(
        1000, (i) => List.generate(10, (j) => Random().nextDouble()));
    final df = DataFrame(data);
    df.describe();
  }, 'Describe Operation (1000 rows)'));

  print(benchmark(() {
    DataFrame.fromMap({
      'col1': List.generate(1000, (i) => i),
      'col2': List.generate(1000, (i) => Random().nextDouble()),
    });
  }, 'DataFrame.fromMap (1000 rows)'));

  print(benchmark(() {
    final df = DataFrame.fromMap({
      'col1': List.generate(1000, (i) => i),
      'col2': List.generate(1000, (i) => Random().nextDouble()),
    });
    df.toMap();
  }, 'DataFrame.toMap (1000 rows)'));

  print('');
  print('=' * 80);
  print('Benchmark Complete!');
  print('=' * 80);
}
