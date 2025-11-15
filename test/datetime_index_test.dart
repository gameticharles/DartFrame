import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DatetimeIndex', () {
    group('Construction', () {
      test('Create from list of timestamps', () {
        final idx = DatetimeIndex([
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 2),
          DateTime(2024, 1, 3),
        ], name: 'dates');

        expect(idx.length, equals(3));
        expect(idx.name, equals('dates'));
      });

      test('dateRange with end date', () {
        final idx = DatetimeIndex.dateRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 5),
          frequency: 'D',
        );

        expect(idx.length, equals(5));
        expect(idx[0], equals(DateTime(2024, 1, 1)));
        expect(idx[4], equals(DateTime(2024, 1, 5)));
      });

      test('dateRange with periods', () {
        final idx = DatetimeIndex.dateRange(
          start: DateTime(2024, 1, 1),
          periods: 10,
          frequency: 'D',
        );

        expect(idx.length, equals(10));
      });

      test('dateRange with hourly frequency', () {
        final idx = DatetimeIndex.dateRange(
          start: DateTime(2024, 1, 1, 0, 0),
          periods: 24,
          frequency: 'H',
        );

        expect(idx.length, equals(24));
        expect(idx[1], equals(DateTime(2024, 1, 1, 1, 0)));
      });
    });

    group('Timezone Operations', () {
      test('tzLocalize makes timezone-aware', () {
        final idx = DatetimeIndex([
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 2),
        ]);

        final tzIdx = idx.tzLocalize('UTC');

        expect(tzIdx.isTimezoneAware, isTrue);
        expect(tzIdx.timezone, equals('UTC'));
      });

      test('tzConvert changes timezone', () {
        final idx = DatetimeIndex([
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 2),
        ], timezone: 'UTC');

        final nyIdx = idx.tzConvert('America/New_York');

        expect(nyIdx.timezone, equals('America/New_York'));
      });

      test('tzNaive removes timezone', () {
        final idx = DatetimeIndex([
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 2),
        ], timezone: 'UTC');

        final naiveIdx = idx.tzNaive();

        expect(naiveIdx.isTimezoneAware, isFalse);
      });

      test('Cannot localize timezone-aware index', () {
        final idx = DatetimeIndex([
          DateTime(2024, 1, 1),
        ], timezone: 'UTC');

        expect(() => idx.tzLocalize('America/New_York'), throwsStateError);
      });

      test('Cannot convert timezone-naive index', () {
        final idx = DatetimeIndex([
          DateTime(2024, 1, 1),
        ]);

        expect(() => idx.tzConvert('America/New_York'), throwsStateError);
      });
    });

    group('Date Components', () {
      late DatetimeIndex idx;

      setUp(() {
        idx = DatetimeIndex([
          DateTime(2024, 1, 15, 10, 30, 45),
          DateTime(2024, 2, 20, 14, 45, 30),
          DateTime(2024, 3, 25, 18, 15, 15),
        ]);
      });

      test('year property', () {
        expect(idx.year, equals([2024, 2024, 2024]));
      });

      test('month property', () {
        expect(idx.month, equals([1, 2, 3]));
      });

      test('day property', () {
        expect(idx.day, equals([15, 20, 25]));
      });

      test('hour property', () {
        expect(idx.hour, equals([10, 14, 18]));
      });

      test('minute property', () {
        expect(idx.minute, equals([30, 45, 15]));
      });

      test('second property', () {
        expect(idx.second, equals([45, 30, 15]));
      });

      test('dayOfWeek property', () {
        // 2024-01-15 is Monday (1)
        expect(idx.dayOfWeek[0], equals(1));
      });

      test('dayOfYear property', () {
        expect(idx.dayOfYear[0], equals(15)); // Jan 15
        expect(idx.dayOfYear[1], equals(51)); // Feb 20 (31 + 20)
      });
    });

    group('Access', () {
      test('Access by index', () {
        final idx = DatetimeIndex([
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 2),
          DateTime(2024, 1, 3),
        ]);

        expect(idx[0], equals(DateTime(2024, 1, 1)));
        expect(idx[1], equals(DateTime(2024, 1, 2)));
        expect(idx[2], equals(DateTime(2024, 1, 3)));
      });

      test('values returns all timestamps', () {
        final idx = DatetimeIndex([
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 2),
        ]);

        final values = idx.values;
        expect(values.length, equals(2));
        expect(values[0], equals(DateTime(2024, 1, 1)));
      });
    });
  });

  group('TimedeltaIndex', () {
    test('Create from durations', () {
      final idx = TimedeltaIndex([
        Duration(days: 1),
        Duration(hours: 12),
        Duration(minutes: 30),
      ], name: 'deltas');

      expect(idx.length, equals(3));
      expect(idx.name, equals('deltas'));
    });

    test('Access by index', () {
      final idx = TimedeltaIndex([
        Duration(days: 1),
        Duration(hours: 12),
      ]);

      expect(idx[0], equals(Duration(days: 1)));
      expect(idx[1], equals(Duration(hours: 12)));
    });

    test('totalSeconds property', () {
      final idx = TimedeltaIndex([
        Duration(days: 1),
        Duration(hours: 1),
      ]);

      expect(idx.totalSeconds, equals([86400, 3600]));
    });

    test('days property', () {
      final idx = TimedeltaIndex([
        Duration(days: 5),
        Duration(days: 10),
      ]);

      expect(idx.days, equals([5, 10]));
    });

    test('hours component', () {
      final idx = TimedeltaIndex([
        Duration(hours: 25), // 1 day + 1 hour
        Duration(hours: 50), // 2 days + 2 hours
      ]);

      expect(idx.hours, equals([1, 2]));
    });

    test('minutes component', () {
      final idx = TimedeltaIndex([
        Duration(minutes: 90), // 1 hour + 30 minutes
        Duration(minutes: 150), // 2 hours + 30 minutes
      ]);

      expect(idx.minutes, equals([30, 30]));
    });
  });

  group('PeriodIndex', () {
    test('Create from periods', () {
      final idx = PeriodIndex.periodRange(
        start: DateTime(2024, 1, 1),
        periods: 12,
        frequency: 'M',
        name: 'months',
      );

      expect(idx.length, equals(12));
      expect(idx.frequency, equals('M'));
      expect(idx.name, equals('months'));
    });

    test('periodRange with end date', () {
      final idx = PeriodIndex.periodRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 12, 31),
        frequency: 'M',
      );

      expect(idx.length, equals(12));
    });

    test('Access by index', () {
      final idx = PeriodIndex.periodRange(
        start: DateTime(2024, 1, 1),
        periods: 3,
        frequency: 'M',
      );

      expect(idx[0], isA<Period>());
      expect(idx[1], isA<Period>());
      expect(idx[2], isA<Period>());
    });

    test('toTimestamp converts to DatetimeIndex', () {
      final idx = PeriodIndex.periodRange(
        start: DateTime(2024, 1, 1),
        periods: 3,
        frequency: 'M',
      );

      final dtIdx = idx.toTimestamp();

      expect(dtIdx, isA<DatetimeIndex>());
      expect(dtIdx.length, equals(3));
    });

    test('toTimestamp with end', () {
      final idx = PeriodIndex.periodRange(
        start: DateTime(2024, 1, 1),
        periods: 2,
        frequency: 'M',
      );

      final dtIdx = idx.toTimestamp(how: 'end');

      expect(dtIdx, isA<DatetimeIndex>());
    });
  });

  group('Period', () {
    test('Daily period has correct start and end', () {
      final period = Period(DateTime(2024, 1, 15), 'D');

      expect(period.startTime, equals(DateTime(2024, 1, 15, 0, 0, 0)));
      expect(period.endTime, equals(DateTime(2024, 1, 15, 23, 59, 59)));
    });

    test('Monthly period has correct start and end', () {
      final period = Period(DateTime(2024, 1, 15), 'M');

      expect(period.startTime, equals(DateTime(2024, 1, 1)));
      // End of January
      expect(period.endTime.month, equals(1));
      expect(period.endTime.day, equals(31));
    });

    test('Yearly period has correct start and end', () {
      final period = Period(DateTime(2024, 6, 15), 'Y');

      expect(period.startTime, equals(DateTime(2024, 1, 1)));
      expect(period.endTime, equals(DateTime(2024, 12, 31, 23, 59, 59)));
    });
  });

  group('Edge Cases', () {
    test('Empty DatetimeIndex throws error', () {
      expect(
        () => DatetimeIndex([]),
        throwsArgumentError,
      );
    });

    test('dateRange requires end or periods', () {
      expect(
        () => DatetimeIndex.dateRange(
          start: DateTime(2024, 1, 1),
          frequency: 'D',
        ),
        throwsArgumentError,
      );
    });

    test('Unsupported frequency throws error', () {
      expect(
        () => DatetimeIndex.dateRange(
          start: DateTime(2024, 1, 1),
          periods: 10,
          frequency: 'X',
        ),
        throwsArgumentError,
      );
    });
  });
}
