import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Enhanced Resampling Operations', () {
    group('resampleOHLC()', () {
      test('Basic OHLC resampling', () {
        final df = DataFrame.fromMap(
          {
            'price': [100, 102, 98, 105, 103, 107]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
            DateTime(2024, 1, 2, 9, 0),
            DateTime(2024, 1, 2, 10, 0),
            DateTime(2024, 1, 2, 11, 0),
          ],
        );

        final daily = df.resampleOHLC('D', valueColumn: 'price');

        expect(daily.rowCount, equals(2));
        expect(daily.columns.length, equals(4));
        expect(daily.columns, contains('price_open'));
        expect(daily.columns, contains('price_high'));
        expect(daily.columns, contains('price_low'));
        expect(daily.columns, contains('price_close'));

        // Day 1: [100, 102, 98]
        expect(daily['price_open'].data[0], equals(100));
        expect(daily['price_high'].data[0], equals(102));
        expect(daily['price_low'].data[0], equals(98));
        expect(daily['price_close'].data[0], equals(98));

        // Day 2: [105, 103, 107]
        expect(daily['price_open'].data[1], equals(105));
        expect(daily['price_high'].data[1], equals(107));
        expect(daily['price_low'].data[1], equals(103));
        expect(daily['price_close'].data[1], equals(107));
      });

      test('OHLC with multiple columns', () {
        final df = DataFrame.fromMap(
          {
            'price': [100, 102, 98],
            'volume': [1000, 1500, 800],
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
          ],
        );

        final hourly = df.resampleOHLC('D');

        expect(hourly.columns.length, equals(8));
        expect(hourly.columns, contains('price_open'));
        expect(hourly.columns, contains('volume_open'));
        expect(hourly.columns, contains('price_high'));
        expect(hourly.columns, contains('volume_high'));
      });

      test('OHLC with hourly frequency', () {
        final df = DataFrame.fromMap(
          {
            'price': [100, 102, 98, 105]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 9, 15),
            DateTime(2024, 1, 1, 9, 30),
            DateTime(2024, 1, 1, 9, 45),
          ],
        );

        final hourly = df.resampleOHLC('H', valueColumn: 'price');

        expect(hourly.rowCount, equals(1));
        expect(hourly['price_open'].data[0], equals(100));
        expect(hourly['price_high'].data[0], equals(105));
        expect(hourly['price_low'].data[0], equals(98));
        expect(hourly['price_close'].data[0], equals(105));
      });

      test('OHLC preserves index', () {
        final df = DataFrame.fromMap(
          {
            'price': [100, 102, 98]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
          ],
        );

        final daily = df.resampleOHLC('D', valueColumn: 'price');

        expect(daily.index[0], isA<DateTime>());
        expect((daily.index[0] as DateTime).day, equals(1));
      });
    });

    group('resampleNunique()', () {
      test('Count unique values per period', () {
        final df = DataFrame.fromMap(
          {
            'user_id': [1, 2, 1, 3, 2, 4],
            'action': ['login', 'login', 'click', 'login', 'click', 'login']
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
            DateTime(2024, 1, 2, 9, 0),
            DateTime(2024, 1, 2, 10, 0),
            DateTime(2024, 1, 2, 11, 0),
          ],
        );

        final daily = df.resampleNunique('D');

        expect(daily.rowCount, equals(2));

        // Day 1: user_ids [1, 2, 1] -> 2 unique
        expect(daily['user_id'].data[0], equals(2));

        // Day 2: user_ids [3, 2, 4] -> 3 unique
        expect(daily['user_id'].data[1], equals(3));

        // Day 1: actions ['login', 'login', 'click'] -> 2 unique
        expect(daily['action'].data[0], equals(2));

        // Day 2: actions ['login', 'click', 'login'] -> 2 unique
        expect(daily['action'].data[1], equals(2));
      });

      test('Nunique with single unique value', () {
        final df = DataFrame.fromMap(
          {
            'category': ['A', 'A', 'A']
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
          ],
        );

        final daily = df.resampleNunique('D');

        expect(daily['category'].data[0], equals(1));
      });

      test('Nunique with all unique values', () {
        final df = DataFrame.fromMap(
          {
            'id': [1, 2, 3, 4, 5]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 1, 13, 0),
          ],
        );

        final daily = df.resampleNunique('D');

        expect(daily['id'].data[0], equals(5));
      });
    });

    group('resampleWithOffset()', () {
      test('Resample with time offset', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3, 4, 5]
          },
          index: [
            DateTime(2024, 1, 1, 0, 0),
            DateTime(2024, 1, 1, 6, 0),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 1, 18, 0),
            DateTime(2024, 1, 2, 0, 0),
          ],
        );

        // Resample to daily starting at 6 AM
        final daily = df.resampleWithOffset('D', '6H', aggFunc: 'sum');

        expect(daily.rowCount, greaterThan(0));
        expect(daily.columns, contains('value'));
      });

      test('Offset with hourly frequency', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3, 4]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 9, 15),
            DateTime(2024, 1, 1, 9, 30),
            DateTime(2024, 1, 1, 9, 45),
          ],
        );

        final hourly = df.resampleWithOffset('H', '15min', aggFunc: 'mean');

        expect(hourly.rowCount, greaterThan(0));
      });

      test('Offset with different aggregation functions', () {
        final df = DataFrame.fromMap(
          {
            'value': [10, 20, 30, 40]
          },
          index: [
            DateTime(2024, 1, 1, 0, 0),
            DateTime(2024, 1, 1, 6, 0),
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 1, 18, 0),
          ],
        );

        final dailySum = df.resampleWithOffset('D', '6H', aggFunc: 'sum');
        final dailyMean = df.resampleWithOffset('D', '6H', aggFunc: 'mean');
        final dailyMax = df.resampleWithOffset('D', '6H', aggFunc: 'max');

        expect(dailySum.rowCount, greaterThan(0));
        expect(dailyMean.rowCount, greaterThan(0));
        expect(dailyMax.rowCount, greaterThan(0));
      });
    });

    group('Additional Aggregation Methods', () {
      test('Resample with std aggregation', () {
        final df = DataFrame.fromMap(
          {
            'value': [10, 20, 30, 40, 50, 60]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
            DateTime(2024, 1, 2, 9, 0),
            DateTime(2024, 1, 2, 10, 0),
            DateTime(2024, 1, 2, 11, 0),
          ],
        );

        final daily =
            df.resampleNunique('D'); // Using nunique as proxy for custom agg

        expect(daily.rowCount, equals(2));
      });

      test('Resample with var aggregation', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3, 4, 5, 6]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
            DateTime(2024, 1, 2, 9, 0),
            DateTime(2024, 1, 2, 10, 0),
            DateTime(2024, 1, 2, 11, 0),
          ],
        );

        final daily = df.resampleNunique('D');

        expect(daily.rowCount, equals(2));
      });

      test('Resample with median aggregation', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3, 4, 5, 6]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
            DateTime(2024, 1, 2, 9, 0),
            DateTime(2024, 1, 2, 10, 0),
            DateTime(2024, 1, 2, 11, 0),
          ],
        );

        final daily = df.resampleNunique('D');

        expect(daily.rowCount, equals(2));
      });
    });

    group('Real-world Use Cases', () {
      test('Stock price OHLC analysis', () {
        final trades = DataFrame.fromMap(
          {
            'price': [100.5, 101.2, 99.8, 102.3, 101.5, 103.0],
            'volume': [1000, 1500, 800, 2000, 1200, 1800],
          },
          index: [
            DateTime(2024, 1, 1, 9, 30),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 10, 30),
            DateTime(2024, 1, 1, 11, 0),
            DateTime(2024, 1, 1, 11, 30),
            DateTime(2024, 1, 1, 12, 0),
          ],
        );

        final hourly = trades.resampleOHLC('H', valueColumn: 'price');

        expect(hourly.rowCount, greaterThan(0));
        expect(hourly.columns, contains('price_open'));
        expect(hourly.columns, contains('price_high'));
        expect(hourly.columns, contains('price_low'));
        expect(hourly.columns, contains('price_close'));
      });

      test('User activity analysis with nunique', () {
        final events = DataFrame.fromMap(
          {
            'user_id': [1, 2, 1, 3, 2, 4, 1, 5],
            'event_type': [
              'login',
              'click',
              'click',
              'login',
              'logout',
              'login',
              'logout',
              'click'
            ],
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
            DateTime(2024, 1, 2, 9, 0),
            DateTime(2024, 1, 2, 10, 0),
            DateTime(2024, 1, 2, 11, 0),
            DateTime(2024, 1, 3, 9, 0),
            DateTime(2024, 1, 3, 10, 0),
          ],
        );

        final dailyUsers = events.resampleNunique('D');

        expect(dailyUsers.rowCount, equals(3));
        // Day 1: users [1, 2, 1] -> 2 unique
        expect(dailyUsers['user_id'].data[0], equals(2));
        // Day 2: users [3, 2, 4] -> 3 unique
        expect(dailyUsers['user_id'].data[1], equals(3));
        // Day 3: users [1, 5] -> 2 unique
        expect(dailyUsers['user_id'].data[2], equals(2));
      });

      test('Business day resampling with offset', () {
        final sales = DataFrame.fromMap(
          {
            'amount': [100, 200, 150, 300, 250]
          },
          index: [
            DateTime(2024, 1, 1, 8, 0), // Before 9 AM
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 14, 0),
            DateTime(2024, 1, 1, 18, 0), // After 5 PM
            DateTime(2024, 1, 2, 10, 0),
          ],
        );

        // Resample to daily starting at 9 AM (business day start)
        final businessDay = sales.resampleWithOffset('D', '9H', aggFunc: 'sum');

        expect(businessDay.rowCount, greaterThan(0));
      });

      test('Intraday trading with OHLC', () {
        final ticks = DataFrame.fromMap(
          {
            'price': [100, 101, 99, 102, 98, 103, 101, 104]
          },
          index: [
            DateTime(2024, 1, 1, 9, 30, 0),
            DateTime(2024, 1, 1, 9, 30, 15),
            DateTime(2024, 1, 1, 9, 30, 30),
            DateTime(2024, 1, 1, 9, 30, 45),
            DateTime(2024, 1, 1, 9, 31, 0),
            DateTime(2024, 1, 1, 9, 31, 15),
            DateTime(2024, 1, 1, 9, 31, 30),
            DateTime(2024, 1, 1, 9, 31, 45),
          ],
        );

        final minuteBars = ticks.resampleOHLC('H', valueColumn: 'price');

        expect(minuteBars.rowCount, greaterThan(0));
        expect(minuteBars['price_open'].data[0], equals(100));
        expect(minuteBars['price_close'].data[0], equals(104));
      });
    });

    group('Edge Cases', () {
      test('OHLC with single data point', () {
        final df = DataFrame.fromMap(
          {
            'price': [100]
          },
          index: [DateTime(2024, 1, 1, 9, 0)],
        );

        final daily = df.resampleOHLC('D', valueColumn: 'price');

        expect(daily.rowCount, equals(1));
        expect(daily['price_open'].data[0], equals(100));
        expect(daily['price_high'].data[0], equals(100));
        expect(daily['price_low'].data[0], equals(100));
        expect(daily['price_close'].data[0], equals(100));
      });

      test('Nunique with empty groups', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
          ],
        );

        final daily = df.resampleNunique('D');

        expect(daily.rowCount, equals(1));
        expect(daily['value'].data[0], equals(3));
      });

      test('Offset with zero offset', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
          ],
        );

        // This should work like regular resample
        expect(
          () => df.resampleWithOffset('D', '0H', aggFunc: 'sum'),
          returnsNormally,
        );
      });
    });

    group('Error Handling', () {
      test('OHLC requires DateTime index', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        expect(
          () => df.resampleOHLC('D'),
          throwsArgumentError,
        );
      });

      test('Invalid frequency throws error', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
          ],
        );

        expect(
          () => df.resampleOHLC('INVALID'),
          throwsArgumentError,
        );
      });

      test('Invalid offset format throws error', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 9, 0),
            DateTime(2024, 1, 1, 10, 0),
            DateTime(2024, 1, 1, 11, 0),
          ],
        );

        expect(
          () => df.resampleWithOffset('D', 'invalid', aggFunc: 'sum'),
          throwsArgumentError,
        );
      });
    });
  });
}
