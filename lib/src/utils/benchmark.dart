/// Benchmarking utilities for DartFrame performance testing
library;

/// Benchmark result
class BenchmarkResult {
  final String name;
  final Duration totalTime;
  final Duration averageTime;
  final Duration minTime;
  final Duration maxTime;
  final int iterations;
  final double operationsPerSecond;

  const BenchmarkResult({
    required this.name,
    required this.totalTime,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.iterations,
    required this.operationsPerSecond,
  });

  @override
  String toString() {
    return '''
Benchmark: $name
  Iterations: $iterations
  Total Time: ${totalTime.inMilliseconds}ms
  Average Time: ${averageTime.inMicroseconds}μs
  Min Time: ${minTime.inMicroseconds}μs
  Max Time: ${maxTime.inMicroseconds}μs
  Operations/sec: ${operationsPerSecond.toStringAsFixed(2)}
''';
  }
}

/// Benchmark a function
Future<BenchmarkResult> benchmark(
  String name,
  Future<void> Function() operation, {
  int iterations = 10,
  int warmupIterations = 2,
}) async {
  // Warmup
  for (int i = 0; i < warmupIterations; i++) {
    await operation();
  }

  // Benchmark
  final times = <Duration>[];
  final startTotal = DateTime.now();

  for (int i = 0; i < iterations; i++) {
    final start = DateTime.now();
    await operation();
    final end = DateTime.now();
    times.add(end.difference(start));
  }

  final endTotal = DateTime.now();
  final totalTime = endTotal.difference(startTotal);

  // Calculate statistics
  times.sort((a, b) => a.compareTo(b));
  final minTime = times.first;
  final maxTime = times.last;
  final avgMicros =
      times.fold<int>(0, (sum, t) => sum + t.inMicroseconds) ~/ iterations;
  final averageTime = Duration(microseconds: avgMicros);
  final opsPerSec = 1000000 / avgMicros;

  return BenchmarkResult(
    name: name,
    totalTime: totalTime,
    averageTime: averageTime,
    minTime: minTime,
    maxTime: maxTime,
    iterations: iterations,
    operationsPerSecond: opsPerSec,
  );
}

/// Benchmark a synchronous function
BenchmarkResult benchmarkSync(
  String name,
  void Function() operation, {
  int iterations = 10,
  int warmupIterations = 2,
}) {
  // Warmup
  for (int i = 0; i < warmupIterations; i++) {
    operation();
  }

  // Benchmark
  final times = <Duration>[];
  final startTotal = DateTime.now();

  for (int i = 0; i < iterations; i++) {
    final start = DateTime.now();
    operation();
    final end = DateTime.now();
    times.add(end.difference(start));
  }

  final endTotal = DateTime.now();
  final totalTime = endTotal.difference(startTotal);

  // Calculate statistics
  times.sort((a, b) => a.compareTo(b));
  final minTime = times.first;
  final maxTime = times.last;
  final avgMicros =
      times.fold<int>(0, (sum, t) => sum + t.inMicroseconds) ~/ iterations;
  final averageTime = Duration(microseconds: avgMicros);
  final opsPerSec = 1000000 / avgMicros;

  return BenchmarkResult(
    name: name,
    totalTime: totalTime,
    averageTime: averageTime,
    minTime: minTime,
    maxTime: maxTime,
    iterations: iterations,
    operationsPerSecond: opsPerSec,
  );
}

/// Compare multiple benchmarks
class BenchmarkComparison {
  final List<BenchmarkResult> results;

  BenchmarkComparison(this.results);

  /// Get the fastest result
  BenchmarkResult get fastest {
    return results.reduce((a, b) =>
        a.averageTime.inMicroseconds < b.averageTime.inMicroseconds ? a : b);
  }

  /// Get the slowest result
  BenchmarkResult get slowest {
    return results.reduce((a, b) =>
        a.averageTime.inMicroseconds > b.averageTime.inMicroseconds ? a : b);
  }

  /// Get speedup factor relative to baseline (first result)
  Map<String, double> getSpeedups() {
    if (results.isEmpty) return {};

    final baseline = results.first.averageTime.inMicroseconds;
    final speedups = <String, double>{};

    for (final result in results) {
      speedups[result.name] = baseline / result.averageTime.inMicroseconds;
    }

    return speedups;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Benchmark Comparison:');
    buffer.writeln('=' * 60);

    for (final result in results) {
      buffer.writeln(result);
    }

    buffer.writeln('Summary:');
    buffer.writeln(
        '  Fastest: ${fastest.name} (${fastest.averageTime.inMicroseconds}μs)');
    buffer.writeln(
        '  Slowest: ${slowest.name} (${slowest.averageTime.inMicroseconds}μs)');

    final speedups = getSpeedups();
    buffer.writeln('\nSpeedups (relative to ${results.first.name}):');
    speedups.forEach((name, speedup) {
      buffer.writeln('  $name: ${speedup.toStringAsFixed(2)}x');
    });

    return buffer.toString();
  }
}
