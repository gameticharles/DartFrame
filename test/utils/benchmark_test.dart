import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('Benchmark', () {
    test('benchmarks async function', () async {
      final result = await benchmark(
        'test operation',
        () async {
          await Future.delayed(Duration(milliseconds: 10));
        },
        iterations: 3,
        warmupIterations: 1,
      );

      expect(result.name, equals('test operation'));
      expect(result.iterations, equals(3));
      expect(result.totalTime.inMilliseconds, greaterThan(0));
      expect(result.averageTime.inMilliseconds, greaterThan(0));
      expect(result.operationsPerSecond, greaterThan(0));
    });

    test('benchmarks sync function', () {
      final result = benchmarkSync(
        'sync operation',
        () {
          var sum = 0;
          for (int i = 0; i < 1000; i++) {
            sum += i;
          }
          // Just use sum to avoid warning
          expect(sum, greaterThan(0));
        },
        iterations: 5,
        warmupIterations: 1,
      );

      expect(result.name, equals('sync operation'));
      expect(result.iterations, equals(5));
      expect(result.minTime.inMicroseconds,
          lessThanOrEqualTo(result.maxTime.inMicroseconds));
    });

    test('benchmark result toString', () {
      final result = BenchmarkResult(
        name: 'test',
        totalTime: Duration(milliseconds: 100),
        averageTime: Duration(milliseconds: 10),
        minTime: Duration(milliseconds: 8),
        maxTime: Duration(milliseconds: 12),
        iterations: 10,
        operationsPerSecond: 100.0,
      );

      final str = result.toString();
      expect(str, contains('test'));
      expect(str, contains('10'));
      expect(str, contains('100'));
    });
  });

  group('BenchmarkComparison', () {
    test('identifies fastest and slowest', () {
      final results = [
        BenchmarkResult(
          name: 'slow',
          totalTime: Duration(milliseconds: 100),
          averageTime: Duration(milliseconds: 20),
          minTime: Duration(milliseconds: 18),
          maxTime: Duration(milliseconds: 22),
          iterations: 5,
          operationsPerSecond: 50.0,
        ),
        BenchmarkResult(
          name: 'fast',
          totalTime: Duration(milliseconds: 50),
          averageTime: Duration(milliseconds: 10),
          minTime: Duration(milliseconds: 9),
          maxTime: Duration(milliseconds: 11),
          iterations: 5,
          operationsPerSecond: 100.0,
        ),
      ];

      final comparison = BenchmarkComparison(results);

      expect(comparison.fastest.name, equals('fast'));
      expect(comparison.slowest.name, equals('slow'));
    });

    test('calculates speedups', () {
      final results = [
        BenchmarkResult(
          name: 'baseline',
          totalTime: Duration(milliseconds: 100),
          averageTime: Duration(milliseconds: 20),
          minTime: Duration(milliseconds: 18),
          maxTime: Duration(milliseconds: 22),
          iterations: 5,
          operationsPerSecond: 50.0,
        ),
        BenchmarkResult(
          name: 'optimized',
          totalTime: Duration(milliseconds: 50),
          averageTime: Duration(milliseconds: 10),
          minTime: Duration(milliseconds: 9),
          maxTime: Duration(milliseconds: 11),
          iterations: 5,
          operationsPerSecond: 100.0,
        ),
      ];

      final comparison = BenchmarkComparison(results);
      final speedups = comparison.getSpeedups();

      expect(speedups['baseline'], equals(1.0));
      expect(speedups['optimized'], equals(2.0));
    });

    test('toString provides summary', () {
      final results = [
        BenchmarkResult(
          name: 'test1',
          totalTime: Duration(milliseconds: 100),
          averageTime: Duration(milliseconds: 20),
          minTime: Duration(milliseconds: 18),
          maxTime: Duration(milliseconds: 22),
          iterations: 5,
          operationsPerSecond: 50.0,
        ),
      ];

      final comparison = BenchmarkComparison(results);
      final str = comparison.toString();

      expect(str, contains('Benchmark Comparison'));
      expect(str, contains('test1'));
      expect(str, contains('Fastest'));
    });
  });
}
