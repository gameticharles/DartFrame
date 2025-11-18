import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  setUp(() {
    // Reset profiler before each test
    Profiler.reset();
    Profiler.enabled = true;
  });

  group('Profiler basic lifecycle', () {
    test('start and stop single operation', () {
      Profiler.start('testOp');

      // Simulate some work
      final sum = List.generate(1000, (i) => i).reduce((a, b) => a + b);
      expect(sum, greaterThan(0));

      Profiler.stop('testOp');

      final report = Profiler.getReport();
      expect(report.entries.containsKey('testOp'), isTrue);
      expect(report.entries['testOp']!.count, equals(1));
      expect(
          report.entries['testOp']!.totalTime.inMicroseconds, greaterThan(0));
    });

    test('stop without start throws StateError', () {
      expect(
        () => Profiler.stop('nonExistent'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('was not started'),
        )),
      );
    });

    test('start twice throws StateError', () {
      Profiler.start('testOp');

      expect(
        () => Profiler.start('testOp'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('already started'),
        )),
      );

      // Clean up
      Profiler.stop('testOp');
    });
  });

  group('Profiler statistics accumulation', () {
    test('accumulates statistics for repeated operations', () {
      // Execute operation multiple times
      for (int i = 0; i < 5; i++) {
        Profiler.start('repeatedOp');

        // Simulate work with varying duration
        final sum =
            List.generate(100 * (i + 1), (j) => j).reduce((a, b) => a + b);
        expect(sum, greaterThan(0));

        Profiler.stop('repeatedOp');
      }

      final report = Profiler.getReport();
      final entry = report.entries['repeatedOp']!;

      expect(entry.count, equals(5));
      expect(entry.totalTime.inMicroseconds, greaterThan(0));
      expect(entry.avgTime.inMicroseconds, greaterThan(0));
      expect(entry.minTime.inMicroseconds, greaterThan(0));
      expect(entry.maxTime.inMicroseconds, greaterThan(0));
      expect(entry.minTime.inMicroseconds,
          lessThanOrEqualTo(entry.avgTime.inMicroseconds));
      expect(entry.avgTime.inMicroseconds,
          lessThanOrEqualTo(entry.maxTime.inMicroseconds));
    });

    test('tracks multiple different operations', () {
      Profiler.start('op1');
      Profiler.stop('op1');

      Profiler.start('op2');
      Profiler.stop('op2');

      Profiler.start('op3');
      Profiler.stop('op3');

      final report = Profiler.getReport();
      expect(report.entries.length, equals(3));
      expect(report.entries.containsKey('op1'), isTrue);
      expect(report.entries.containsKey('op2'), isTrue);
      expect(report.entries.containsKey('op3'), isTrue);
    });
  });

  group('Profiler enabled/disabled toggle', () {
    test('when disabled, start and stop are no-ops', () {
      Profiler.enabled = false;

      // These should not throw or record anything
      Profiler.start('disabledOp');
      Profiler.stop('disabledOp');

      final report = Profiler.getReport();
      expect(report.entries.isEmpty, isTrue);
    });

    test('can toggle enabled state', () {
      expect(Profiler.enabled, isTrue);

      Profiler.enabled = false;
      expect(Profiler.enabled, isFalse);

      Profiler.enabled = true;
      expect(Profiler.enabled, isTrue);
    });

    test('operations work after re-enabling', () {
      Profiler.enabled = false;
      Profiler.start('op1');
      Profiler.stop('op1');

      Profiler.enabled = true;
      Profiler.start('op2');
      Profiler.stop('op2');

      final report = Profiler.getReport();
      expect(report.entries.containsKey('op1'), isFalse);
      expect(report.entries.containsKey('op2'), isTrue);
    });
  });

  group('Profiler getReport', () {
    test('returns correct statistics', () {
      Profiler.start('testOp');

      // Simulate work
      final sum = List.generate(1000, (i) => i).reduce((a, b) => a + b);
      expect(sum, greaterThan(0));

      Profiler.stop('testOp');

      final report = Profiler.getReport();
      final entry = report.entries['testOp']!;

      expect(entry.name, equals('testOp'));
      expect(entry.count, equals(1));
      expect(entry.totalTime, equals(entry.avgTime));
      expect(entry.minTime, equals(entry.maxTime));
    });

    test('returns empty report when no operations profiled', () {
      final report = Profiler.getReport();
      expect(report.entries.isEmpty, isTrue);
    });

    test('report is immutable copy', () {
      Profiler.start('op1');
      Profiler.stop('op1');

      final report1 = Profiler.getReport();

      Profiler.start('op2');
      Profiler.stop('op2');

      final report2 = Profiler.getReport();

      // First report should not be affected by new operations
      expect(report1.entries.length, equals(1));
      expect(report2.entries.length, equals(2));
    });
  });

  group('Profiler reset', () {
    test('clears all data', () {
      Profiler.start('op1');
      Profiler.stop('op1');

      Profiler.start('op2');
      Profiler.stop('op2');

      expect(Profiler.getReport().entries.length, equals(2));

      Profiler.reset();

      final report = Profiler.getReport();
      expect(report.entries.isEmpty, isTrue);
    });

    test('allows fresh profiling after reset', () {
      Profiler.start('op1');
      Profiler.stop('op1');

      Profiler.reset();

      Profiler.start('op1');
      Profiler.stop('op1');

      final report = Profiler.getReport();
      expect(report.entries['op1']!.count, equals(1));
    });
  });

  group('ProfileReport formatting', () {
    test('toString returns formatted string', () {
      Profiler.start('op1');
      Profiler.stop('op1');

      final report = Profiler.getReport();
      final str = report.toString();

      expect(str, contains('ProfileReport'));
      expect(str, contains('op1'));
      expect(str, contains('count=1'));
      expect(str, contains('Total operations: 1'));
    });

    test('toString handles empty report', () {
      final report = Profiler.getReport();
      final str = report.toString();

      expect(str, contains('No operations profiled'));
    });

    test('toJson returns valid JSON string', () {
      Profiler.start('op1');
      Profiler.stop('op1');

      final report = Profiler.getReport();
      final json = report.toJson();

      expect(json, contains('"operations"'));
      expect(json, contains('"totalOperations"'));
      expect(json, contains('"name":"op1"'));
      expect(json, contains('"count":1'));
    });

    test('printSummary does not throw', () {
      Profiler.start('op1');
      Profiler.stop('op1');

      final report = Profiler.getReport();

      // Should not throw
      expect(() => report.printSummary(), returnsNormally);
    });

    test('copy creates independent copy', () {
      Profiler.start('op1');
      Profiler.stop('op1');

      final report1 = Profiler.getReport();
      final report2 = report1.copy();

      expect(report1.entries.length, equals(report2.entries.length));
      expect(report1.entries.keys, equals(report2.entries.keys));

      // Verify it's a copy, not the same reference
      expect(identical(report1.entries, report2.entries), isFalse);
    });
  });

  group('ProfileEntry', () {
    test('toString formats duration correctly', () {
      Profiler.start('op1');

      // Simulate work
      final sum = List.generate(1000, (i) => i).reduce((a, b) => a + b);
      expect(sum, greaterThan(0));

      Profiler.stop('op1');

      final report = Profiler.getReport();
      final entry = report.entries['op1']!;
      final str = entry.toString();

      expect(str, contains('op1'));
      expect(str, contains('count=1'));
      expect(str, matches(RegExp(r'total=\d+'))); // Contains timing info
      expect(str, matches(RegExp(r'avg=\d+'))); // Contains timing info
    });

    test('toJson returns complete data', () {
      Profiler.start('op1');
      Profiler.stop('op1');

      final report = Profiler.getReport();
      final entry = report.entries['op1']!;
      final json = entry.toJson();

      expect(json['name'], equals('op1'));
      expect(json['count'], equals(1));
      expect(json['totalTime'], isA<int>());
      expect(json['avgTime'], isA<int>());
      expect(json['minTime'], isA<int>());
      expect(json['maxTime'], isA<int>());
      expect(json['memoryAllocations'], isA<int>());
    });

    test('avgTime is zero when count is zero', () {
      final entry = ProfileEntry('test');
      expect(entry.avgTime, equals(Duration.zero));
    });
  });
}
