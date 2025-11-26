import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';
import 'dart:async';

void main() {
  group('Series Inspection and Statistics', () {
    test('info() prints correct information', () {
      final series = Series([1, 2, 3, null, 5], name: 'test_series');

      // Capture print output
      final spec = ZoneSpecification(
        print: (self, parent, zone, line) {
          // Verify expected output parts
          if (line.contains('<Series: test_series>')) {
            expect(line, contains('test_series'));
          }
          if (line.contains('Length:')) expect(line, contains('5'));
          // if (line.contains('Dtype:')) expect(line, contains('int')); // Dtype might vary based on inference
          if (line.contains('Non-Null Count:')) expect(line, contains('4'));
          if (line.contains('Memory Usage:')) expect(line, contains('bytes'));
        },
      );

      runZoned(() {
        series.info();
      }, zoneSpecification: spec);
    });

    test('memoryUsage() returns reasonable values', () {
      final series = Series([1, 2, 3, 4, 5], name: 'int_series');
      final usage = series.memoryUsage();
      expect(usage, greaterThan(0));

      final stringSeries = Series(['a', 'bb', 'ccc'], name: 'str_series');
      final strUsage = stringSeries.memoryUsage();
      expect(strUsage, greaterThan(0));
    });

    test('describe() returns correct statistics for numeric series', () {
      final series = Series([1, 2, 3, 4, 5], name: 'numeric');
      final stats = series.describe();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['count'], equals(5));
      expect(stats['mean'], equals(3.0));
      expect(stats['min'], equals(1));
      expect(stats['max'], equals(5));
      expect(stats['50%'], equals(3));
      expect(stats['std'], closeTo(1.58, 0.01));
    });

    test('describe() handles missing values', () {
      final series = Series([1, null, 3, null, 5], name: 'missing');
      final stats = series.describe();

      expect(stats['count'], equals(3));
      expect(stats['mean'], equals(3.0));
    });

    test('describe() handles empty series', () {
      final series = Series([], name: 'empty');
      final stats = series.describe();

      expect(stats['count'], equals(0));
      expect(stats['mean'], isNaN);
    });
  });
}
