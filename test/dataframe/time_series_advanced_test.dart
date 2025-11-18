import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Advanced Time Series Operations', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame.fromMap({
        'A': [1, 2, 3, 4, 5],
        'B': [10, 20, 30, 40, 50],
        'C': [100, 200, 300, 400, 500],
      });
    });

    group('shift()', () {
      test('Shift down by 1 period', () {
        final shifted = df.shift(1);

        expect(shifted.rowCount, equals(5));
        expect(shifted['A'].data[0], isNull);
        expect(shifted['A'].data[1], equals(1));
        expect(shifted['A'].data[2], equals(2));
        expect(shifted['A'].data[3], equals(3));
        expect(shifted['A'].data[4], equals(4));
      });

      test('Shift down by 2 periods', () {
        final shifted = df.shift(2);

        expect(shifted['A'].data[0], isNull);
        expect(shifted['A'].data[1], isNull);
        expect(shifted['A'].data[2], equals(1));
        expect(shifted['A'].data[3], equals(2));
        expect(shifted['A'].data[4], equals(3));
      });

      test('Shift up by 1 period (negative)', () {
        final shifted = df.shift(-1);

        expect(shifted['A'].data[0], equals(2));
        expect(shifted['A'].data[1], equals(3));
        expect(shifted['A'].data[2], equals(4));
        expect(shifted['A'].data[3], equals(5));
        expect(shifted['A'].data[4], isNull);
      });

      test('Shift up by 2 periods', () {
        final shifted = df.shift(-2);

        expect(shifted['A'].data[0], equals(3));
        expect(shifted['A'].data[1], equals(4));
        expect(shifted['A'].data[2], equals(5));
        expect(shifted['A'].data[3], isNull);
        expect(shifted['A'].data[4], isNull);
      });

      test('Shift by 0 returns copy', () {
        final shifted = df.shift(0);

        expect(shifted.rowCount, equals(df.rowCount));
        expect(shifted['A'].data, equals(df['A'].data));
      });

      test('Shift with custom fill value', () {
        final shifted = df.shift(1, fillValue: -999);

        expect(shifted['A'].data[0], equals(-999));
        expect(shifted['A'].data[1], equals(1));
      });

      test('Shift preserves all columns', () {
        final shifted = df.shift(1);

        expect(shifted.columns, equals(df.columns));
        expect(shifted['B'].data[1], equals(10));
        expect(shifted['C'].data[1], equals(100));
      });
    });

    group('lag()', () {
      test('Lag by 1 period', () {
        final lagged = df.lag(1);

        expect(lagged['A'].data[0], isNull);
        expect(lagged['A'].data[1], equals(1));
        expect(lagged['A'].data[2], equals(2));
      });

      test('Lag by 2 periods', () {
        final lagged = df.lag(2);

        expect(lagged['A'].data[0], isNull);
        expect(lagged['A'].data[1], isNull);
        expect(lagged['A'].data[2], equals(1));
      });

      test('Lag with custom fill value', () {
        final lagged = df.lag(1, fillValue: 0);

        expect(lagged['A'].data[0], equals(0));
        expect(lagged['A'].data[1], equals(1));
      });
    });

    group('lead()', () {
      test('Lead by 1 period', () {
        final led = df.lead(1);

        expect(led['A'].data[0], equals(2));
        expect(led['A'].data[1], equals(3));
        expect(led['A'].data[2], equals(4));
        expect(led['A'].data[3], equals(5));
        expect(led['A'].data[4], isNull);
      });

      test('Lead by 2 periods', () {
        final led = df.lead(2);

        expect(led['A'].data[0], equals(3));
        expect(led['A'].data[1], equals(4));
        expect(led['A'].data[2], equals(5));
        expect(led['A'].data[3], isNull);
        expect(led['A'].data[4], isNull);
      });

      test('Lead with custom fill value', () {
        final led = df.lead(1, fillValue: 999);

        expect(led['A'].data[4], equals(999));
      });
    });

    group('tshift()', () {
      test('Shift time index forward', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 2),
            DateTime(2024, 1, 3),
          ],
        );

        final shifted = dfTime.tshift(1, freq: 'D');

        expect(shifted.index[0], equals(DateTime(2024, 1, 2)));
        expect(shifted.index[1], equals(DateTime(2024, 1, 3)));
        expect(shifted.index[2], equals(DateTime(2024, 1, 4)));
        expect(shifted['value'].data, equals([1, 2, 3]));
      });

      test('Shift time index backward', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 5),
            DateTime(2024, 1, 6),
            DateTime(2024, 1, 7),
          ],
        );

        final shifted = dfTime.tshift(-2, freq: 'D');

        expect(shifted.index[0], equals(DateTime(2024, 1, 3)));
        expect(shifted.index[1], equals(DateTime(2024, 1, 4)));
        expect(shifted.index[2], equals(DateTime(2024, 1, 5)));
      });

      test('Shift by hours', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
            DateTime(2024, 1, 1, 12, 0),
          ],
        );

        final shifted = dfTime.tshift(2, freq: 'H');

        expect(shifted.index[0], equals(DateTime(2024, 1, 1, 12, 0)));
        expect(shifted.index[1], equals(DateTime(2024, 1, 1, 13, 0)));
        expect(shifted.index[2], equals(DateTime(2024, 1, 1, 14, 0)));
      });

      test('Requires DateTime index', () {
        expect(
          () => df.tshift(1, freq: 'D'),
          throwsArgumentError,
        );
      });

      test('Requires freq parameter', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 2),
            DateTime(2024, 1, 3),
          ],
        );

        expect(
          () => dfTime.tshift(1),
          throwsArgumentError,
        );
      });
    });

    group('asfreq()', () {
      test('Convert to daily frequency with forward fill', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 3),
            DateTime(2024, 1, 5),
          ],
        );

        final daily = dfTime.asfreq('D', method: 'pad');

        expect(daily.rowCount, equals(5));
        expect(daily['value'].data[0], equals(1));
        expect(daily['value'].data[1], equals(1)); // Forward filled
        expect(daily['value'].data[2], equals(2));
        expect(daily['value'].data[3], equals(2)); // Forward filled
        expect(daily['value'].data[4], equals(3));
      });

      test('Convert to daily frequency with backward fill', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 3),
            DateTime(2024, 1, 5),
          ],
        );

        final daily = dfTime.asfreq('D', method: 'backfill');

        expect(daily.rowCount, equals(5));
        expect(daily['value'].data[0], equals(1));
        expect(daily['value'].data[1], equals(2)); // Backward filled
        expect(daily['value'].data[2], equals(2));
        expect(daily['value'].data[3], equals(3)); // Backward filled
        expect(daily['value'].data[4], equals(3));
      });

      test('Requires DateTime index', () {
        expect(
          () => df.asfreq('D'),
          throwsArgumentError,
        );
      });
    });

    group('atTime()', () {
      test('Select rows at specific time', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3, 4]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 2, 9, 0),
            DateTime(2024, 1, 2, 15, 0),
          ],
        );

        final morning = dfTime.atTime('09:00:00');

        expect(morning.rowCount, equals(2));
        expect(morning['value'].data, equals([1, 3]));
      });

      test('Select rows at time with minutes', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 9, 30),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 2, 9, 30),
          ],
        );

        final result = dfTime.atTime('09:30:00');

        expect(result.rowCount, equals(2));
        expect(result['value'].data, equals([1, 3]));
      });

      test('Returns empty DataFrame when no matches', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 2, 15, 0),
          ],
        );

        final result = dfTime.atTime('18:00:00');

        expect(result.rowCount, equals(0));
      });

      test('Requires DateTime index', () {
        expect(
          () => df.atTime('09:00:00'),
          throwsArgumentError,
        );
      });
    });

    group('betweenTime()', () {
      test('Select rows between times', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3, 4, 5]
          },
          index: [
            DateTime(2024, 1, 1, 8, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 1, 14, 0),
            DateTime(2024, 1, 1, 16, 0),
          ],
        );

        final business = dfTime.betweenTime('09:00:00', '15:00:00');

        expect(business.rowCount, equals(3));
        expect(business['value'].data, equals([2, 3, 4]));
      });

      test('Exclude start time', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 1, 15, 0),
          ],
        );

        final result = dfTime.betweenTime(
          '09:00:00',
          '15:00:00',
          includeStart: false,
        );

        expect(result.rowCount, equals(2));
        expect(result['value'].data, equals([2, 3]));
      });

      test('Exclude end time', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 1, 15, 0),
          ],
        );

        final result = dfTime.betweenTime(
          '09:00:00',
          '15:00:00',
          includeEnd: false,
        );

        expect(result.rowCount, equals(2));
        expect(result['value'].data, equals([1, 2]));
      });

      test('Requires DateTime index', () {
        expect(
          () => df.betweenTime('09:00:00', '17:00:00'),
          throwsArgumentError,
        );
      });
    });

    group('first()', () {
      test('Select first n days', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3, 4, 5]
          },
          index: [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 5),
            DateTime(2024, 1, 10),
            DateTime(2024, 1, 15),
            DateTime(2024, 1, 20),
          ],
        );

        final firstWeek = dfTime.first('7D');

        expect(firstWeek.rowCount, equals(2));
        expect(firstWeek['value'].data, equals([1, 2]));
      });

      test('Select first n hours', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3, 4]
          },
          index: [
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 1, 14, 0),
            DateTime(2024, 1, 1, 16, 0),
          ],
        );

        final firstThreeHours = dfTime.first('3H');

        expect(firstThreeHours.rowCount, equals(2));
        expect(firstThreeHours['value'].data, equals([1, 2]));
      });

      test('Requires DateTime index', () {
        expect(
          () => df.first('7D'),
          throwsArgumentError,
        );
      });
    });

    group('last()', () {
      test('Select last n days', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3, 4, 5]
          },
          index: [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 5),
            DateTime(2024, 1, 10),
            DateTime(2024, 1, 15),
            DateTime(2024, 1, 20),
          ],
        );

        final lastWeek = dfTime.last('7D');

        expect(lastWeek.rowCount, equals(2));
        expect(lastWeek['value'].data, equals([4, 5]));
      });

      test('Select last n hours', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [1, 2, 3, 4]
          },
          index: [
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 1, 14, 0),
            DateTime(2024, 1, 1, 16, 0),
          ],
        );

        final lastThreeHours = dfTime.last('3H');

        expect(lastThreeHours.rowCount, equals(2));
        expect(lastThreeHours['value'].data, equals([3, 4]));
      });

      test('Requires DateTime index', () {
        expect(
          () => df.last('7D'),
          throwsArgumentError,
        );
      });
    });

    group('Real-world Use Cases', () {
      test('Calculate moving average with lag', () {
        final sales = DataFrame.fromMap({
          'sales': [100, 150, 120, 180, 200],
        });

        sales['prev_sales'] = sales.lag(1)['sales'].data;
        sales['next_sales'] = sales.lead(1)['sales'].data;

        expect(sales['prev_sales'].data[0], isNull);
        expect(sales['prev_sales'].data[1], equals(100));
        expect(sales['next_sales'].data[3], equals(200));
        expect(sales['next_sales'].data[4], isNull);
      });

      test('Time-based filtering for business hours', () {
        final transactions = DataFrame.fromMap(
          {
            'amount': [100, 200, 300, 400, 500]
          },
          index: [
            DateTime(2024, 1, 1, 8, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 14, 0),
            DateTime(2024, 1, 1, 18, 0),
            DateTime(2024, 1, 1, 20, 0),
          ],
        );

        final businessHours = transactions.betweenTime('09:00:00', '17:00:00');

        expect(businessHours.rowCount, equals(2));
        expect(businessHours['amount'].data, equals([200, 300]));
      });

      test('Resample and shift for forecasting', () {
        final dfTime = DataFrame.fromMap(
          {
            'value': [10, 20, 30]
          },
          index: [
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 2),
            DateTime(2024, 1, 3),
          ],
        );

        final shifted = dfTime.tshift(1, freq: 'D');

        // Shifted index is one day ahead
        expect(shifted.index[0], equals(DateTime(2024, 1, 2)));
        expect(shifted['value'].data[0], equals(10));
      });
    });
  });
}
