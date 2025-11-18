import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Timezone Operations', () {
    group('tzLocalize()', () {
      test('Localize to UTC', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 2, 12, 0),
            DateTime(2024, 1, 3, 12, 0),
          ],
        );

        final dfUtc = df.tzLocalize('UTC');

        expect(dfUtc.index[0], isA<DateTime>());
        expect((dfUtc.index[0] as DateTime).isUtc, isTrue);
        expect(dfUtc['value'].data, equals([1, 2, 3]));
      });

      test('Localize to timezone with offset', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 2, 12, 0),
            DateTime(2024, 1, 3, 12, 0),
          ],
        );

        final dfNy = df.tzLocalize('America/New_York');

        expect(dfNy.index[0], isA<DateTime>());
        expect((dfNy.index[0] as DateTime).isUtc, isTrue);
      });

      test('Throws error for already timezone-aware index', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime.utc(2024, 1, 1, 12, 0),
            DateTime.utc(2024, 1, 2, 12, 0),
            DateTime.utc(2024, 1, 3, 12, 0),
          ],
        );

        expect(
          () => df.tzLocalize('UTC'),
          throwsArgumentError,
        );
      });

      test('Requires DateTime index', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        expect(
          () => df.tzLocalize('UTC'),
          throwsArgumentError,
        );
      });
    });

    group('tzConvert()', () {
      test('Convert from UTC to another timezone', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime.utc(2024, 1, 1, 12, 0),
            DateTime.utc(2024, 1, 2, 12, 0),
            DateTime.utc(2024, 1, 3, 12, 0),
          ],
        );

        final dfNy = df.tzConvert('America/New_York');

        expect(dfNy.index[0], isA<DateTime>());
        expect(dfNy['value'].data, equals([1, 2, 3]));
      });

      test('Convert to UTC', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime.utc(2024, 1, 1, 12, 0),
            DateTime.utc(2024, 1, 2, 12, 0),
            DateTime.utc(2024, 1, 3, 12, 0),
          ],
        );

        final dfUtc = df.tzConvert('UTC');

        expect(dfUtc.index[0], equals(df.index[0]));
      });

      test('Throws error for timezone-naive index', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 2, 12, 0),
            DateTime(2024, 1, 3, 12, 0),
          ],
        );

        expect(
          () => df.tzConvert('America/New_York'),
          throwsArgumentError,
        );
      });

      test('Requires DateTime index', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        expect(
          () => df.tzConvert('UTC'),
          throwsArgumentError,
        );
      });
    });

    group('tzNaive()', () {
      test('Remove timezone information', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime.utc(2024, 1, 1, 12, 0),
            DateTime.utc(2024, 1, 2, 12, 0),
            DateTime.utc(2024, 1, 3, 12, 0),
          ],
        );

        final dfNaive = df.tzNaive();

        expect(dfNaive.index[0], isA<DateTime>());
        expect((dfNaive.index[0] as DateTime).isUtc, isFalse);
        expect((dfNaive.index[0] as DateTime).year, equals(2024));
        expect((dfNaive.index[0] as DateTime).month, equals(1));
        expect((dfNaive.index[0] as DateTime).day, equals(1));
      });

      test('Preserves date and time values', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime.utc(2024, 1, 1, 12, 30, 45),
            DateTime.utc(2024, 1, 2, 14, 15, 30),
            DateTime.utc(2024, 1, 3, 16, 45, 15),
          ],
        );

        final dfNaive = df.tzNaive();

        final dt = dfNaive.index[0] as DateTime;
        expect(dt.hour, equals(12));
        expect(dt.minute, equals(30));
        expect(dt.second, equals(45));
      });

      test('Requires DateTime index', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        expect(
          () => df.tzNaive(),
          throwsArgumentError,
        );
      });
    });

    group('Timezone offset parsing', () {
      test('Parse positive offset', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 2, 12, 0),
            DateTime(2024, 1, 3, 12, 0),
          ],
        );

        final dfTz = df.tzLocalize('+05:30');

        expect(dfTz.index[0], isA<DateTime>());
      });

      test('Parse negative offset', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 2, 12, 0),
            DateTime(2024, 1, 3, 12, 0),
          ],
        );

        final dfTz = df.tzLocalize('-08:00');

        expect(dfTz.index[0], isA<DateTime>());
      });

      test('Throw error for invalid timezone', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 2, 12, 0),
            DateTime(2024, 1, 3, 12, 0),
          ],
        );

        expect(
          () => df.tzLocalize('Invalid/Timezone'),
          throwsArgumentError,
        );
      });
    });

    group('Common timezone names', () {
      test('Support common US timezones', () {
        final df = DataFrame.fromMap(
          {
            'value': [1]
          },
          index: [DateTime(2024, 1, 1, 12, 0)],
        );

        expect(() => df.tzLocalize('America/New_York'), returnsNormally);
        expect(() => df.tzLocalize('America/Chicago'), returnsNormally);
        expect(() => df.tzLocalize('America/Denver'), returnsNormally);
        expect(() => df.tzLocalize('America/Los_Angeles'), returnsNormally);
      });

      test('Support common European timezones', () {
        final df = DataFrame.fromMap(
          {
            'value': [1]
          },
          index: [DateTime(2024, 1, 1, 12, 0)],
        );

        expect(() => df.tzLocalize('Europe/London'), returnsNormally);
        expect(() => df.tzLocalize('Europe/Paris'), returnsNormally);
        expect(() => df.tzLocalize('Europe/Berlin'), returnsNormally);
      });

      test('Support common Asian timezones', () {
        final df = DataFrame.fromMap(
          {
            'value': [1]
          },
          index: [DateTime(2024, 1, 1, 12, 0)],
        );

        expect(() => df.tzLocalize('Asia/Tokyo'), returnsNormally);
        expect(() => df.tzLocalize('Asia/Shanghai'), returnsNormally);
        expect(() => df.tzLocalize('Asia/Singapore'), returnsNormally);
      });
    });

    group('Real-world Use Cases', () {
      test('Convert trading data from UTC to local time', () {
        final trades = DataFrame.fromMap(
          {
            'price': [100, 101, 102]
          },
          index: [
            DateTime.utc(2024, 1, 1, 14, 30),
            DateTime.utc(2024, 1, 1, 15, 0),
            DateTime.utc(2024, 1, 1, 15, 30),
          ],
        );

        final nyTrades = trades.tzConvert('America/New_York');

        expect(nyTrades.rowCount, equals(3));
        expect(nyTrades['price'].data, equals([100, 101, 102]));
      });

      test('Localize and convert timezone', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime(2024, 1, 1, 12, 0),
            DateTime(2024, 1, 2, 12, 0),
            DateTime(2024, 1, 3, 12, 0),
          ],
        );

        // First localize to UTC
        final dfUtc = df.tzLocalize('UTC');

        // Then convert to another timezone
        final dfNy = dfUtc.tzConvert('America/New_York');

        expect(dfNy.rowCount, equals(3));
        expect(dfNy['value'].data, equals([1, 2, 3]));
      });

      test('Remove timezone for local processing', () {
        final df = DataFrame.fromMap(
          {
            'value': [1, 2, 3]
          },
          index: [
            DateTime.utc(2024, 1, 1, 12, 0),
            DateTime.utc(2024, 1, 2, 12, 0),
            DateTime.utc(2024, 1, 3, 12, 0),
          ],
        );

        final dfNaive = df.tzNaive();

        expect((dfNaive.index[0] as DateTime).isUtc, isFalse);
        expect(dfNaive['value'].data, equals([1, 2, 3]));
      });
    });
  });
}
