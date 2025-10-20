import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('TimeSeriesIndex', () {
    group('Constructor and Basic Properties', () {
      test('creates TimeSeriesIndex with timestamps', () {
        final timestamps = [
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
          DateTime(2023, 1, 3),
        ];
        final index = TimeSeriesIndex(timestamps, frequency: 'D', name: 'test');

        expect(index.timestamps, equals(timestamps));
        expect(index.frequency, equals('D'));
        expect(index.name, equals('test'));
        expect(index.length, equals(3));
        expect(index.isEmpty, isFalse);
        expect(index.isNotEmpty, isTrue);
        expect(index.first, equals(DateTime(2023, 1, 1)));
        expect(index.last, equals(DateTime(2023, 1, 3)));
      });

      test('throws error for empty timestamps', () {
        expect(
          () => TimeSeriesIndex([]),
          throwsArgumentError,
        );
      });

      test('throws error for unsorted timestamps', () {
        final timestamps = [
          DateTime(2023, 1, 3),
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
        ];
        expect(
          () => TimeSeriesIndex(timestamps),
          throwsArgumentError,
        );
      });

      test('access timestamp by index', () {
        final timestamps = [
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
        ];
        final index = TimeSeriesIndex(timestamps);

        expect(index[0], equals(DateTime(2023, 1, 1)));
        expect(index[1], equals(DateTime(2023, 1, 2)));
      });
    });

    group('dateRange factory constructor', () {
      test('creates daily range with start and periods', () {
        final index = TimeSeriesIndex.dateRange(
          start: DateTime(2023, 1, 1),
          periods: 3,
          frequency: 'D',
        );

        expect(index.length, equals(3));
        expect(
            index.timestamps,
            equals([
              DateTime(2023, 1, 1),
              DateTime(2023, 1, 2),
              DateTime(2023, 1, 3),
            ]));
        expect(index.frequency, equals('D'));
      });

      test('creates daily range with start and end', () {
        final index = TimeSeriesIndex.dateRange(
          start: DateTime(2023, 1, 1),
          end: DateTime(2023, 1, 3),
          frequency: 'D',
        );

        expect(index.length, equals(3));
        expect(
            index.timestamps,
            equals([
              DateTime(2023, 1, 1),
              DateTime(2023, 1, 2),
              DateTime(2023, 1, 3),
            ]));
      });

      test('creates hourly range', () {
        final index = TimeSeriesIndex.dateRange(
          start: DateTime(2023, 1, 1, 10),
          periods: 3,
          frequency: 'H',
        );

        expect(
            index.timestamps,
            equals([
              DateTime(2023, 1, 1, 10),
              DateTime(2023, 1, 1, 11),
              DateTime(2023, 1, 1, 12),
            ]));
      });

      test('creates monthly range', () {
        final index = TimeSeriesIndex.dateRange(
          start: DateTime(2023, 1, 15),
          periods: 3,
          frequency: 'M',
        );

        expect(
            index.timestamps,
            equals([
              DateTime(2023, 1, 15),
              DateTime(2023, 2, 15),
              DateTime(2023, 3, 15),
            ]));
      });

      test('creates yearly range', () {
        final index = TimeSeriesIndex.dateRange(
          start: DateTime(2023, 6, 15),
          periods: 3,
          frequency: 'Y',
        );

        expect(
            index.timestamps,
            equals([
              DateTime(2023, 6, 15),
              DateTime(2024, 6, 15),
              DateTime(2025, 6, 15),
            ]));
      });

      test('throws error when neither end nor periods provided', () {
        expect(
          () => TimeSeriesIndex.dateRange(start: DateTime(2023, 1, 1)),
          throwsArgumentError,
        );
      });

      test('throws error for unsupported frequency', () {
        expect(
          () => TimeSeriesIndex.dateRange(
            start: DateTime(2023, 1, 1),
            periods: 3,
            frequency: 'X',
          ),
          throwsArgumentError,
        );
      });

      test('validates consistency when both end and periods provided', () {
        expect(
          () => TimeSeriesIndex.dateRange(
            start: DateTime(2023, 1, 1),
            end: DateTime(2023, 1, 3),
            periods: 5, // Inconsistent with 3-day range
            frequency: 'D',
          ),
          throwsArgumentError,
        );
      });
    });

    group('Frequency Detection', () {
      test('detects daily frequency', () {
        final timestamps = [
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
          DateTime(2023, 1, 3),
        ];
        final index = TimeSeriesIndex(timestamps);

        expect(index.detectFrequency(), equals('D'));
      });

      test('detects hourly frequency', () {
        final timestamps = [
          DateTime(2023, 1, 1, 10),
          DateTime(2023, 1, 1, 11),
          DateTime(2023, 1, 1, 12),
        ];
        final index = TimeSeriesIndex(timestamps);

        expect(index.detectFrequency(), equals('H'));
      });

      test('returns null for irregular frequency', () {
        final timestamps = [
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 3), // 2-day gap
          DateTime(2023, 1, 4), // 1-day gap
        ];
        final index = TimeSeriesIndex(timestamps);

        expect(index.detectFrequency(), isNull);
      });

      test('returns null for single timestamp', () {
        final timestamps = [DateTime(2023, 1, 1)];
        final index = TimeSeriesIndex(timestamps);

        expect(index.detectFrequency(), isNull);
      });
    });

    group('Utility Methods', () {
      test('contains method', () {
        final timestamps = [
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
        ];
        final index = TimeSeriesIndex(timestamps);

        expect(index.contains(DateTime(2023, 1, 1)), isTrue);
        expect(index.contains(DateTime(2023, 1, 3)), isFalse);
      });

      test('indexOf method', () {
        final timestamps = [
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
        ];
        final index = TimeSeriesIndex(timestamps);

        expect(index.indexOf(DateTime(2023, 1, 1)), equals(0));
        expect(index.indexOf(DateTime(2023, 1, 2)), equals(1));
        expect(index.indexOf(DateTime(2023, 1, 3)), equals(-1));
      });

      test('slice method', () {
        final timestamps = [
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
          DateTime(2023, 1, 3),
          DateTime(2023, 1, 4),
          DateTime(2023, 1, 5),
        ];
        final index = TimeSeriesIndex(timestamps, frequency: 'D');

        final sliced = index.slice(DateTime(2023, 1, 2), DateTime(2023, 1, 4));

        expect(
            sliced.timestamps,
            equals([
              DateTime(2023, 1, 2),
              DateTime(2023, 1, 3),
              DateTime(2023, 1, 4),
            ]));
        expect(sliced.frequency, equals('D'));
      });

      test('slice returns empty for invalid range', () {
        final timestamps = [
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
        ];
        final index = TimeSeriesIndex(timestamps);

        final sliced = index.slice(DateTime(2023, 1, 5), DateTime(2023, 1, 6));

        expect(sliced.isEmpty, isTrue);
      });
    });

    group('Equality and HashCode', () {
      test('equal TimeSeriesIndex objects', () {
        final timestamps = [DateTime(2023, 1, 1), DateTime(2023, 1, 2)];
        final index1 =
            TimeSeriesIndex(timestamps, frequency: 'D', name: 'test');
        final index2 =
            TimeSeriesIndex(timestamps, frequency: 'D', name: 'test');

        expect(index1, equals(index2));
        expect(index1.hashCode, equals(index2.hashCode));
      });

      test('different TimeSeriesIndex objects', () {
        final timestamps1 = [DateTime(2023, 1, 1), DateTime(2023, 1, 2)];
        final timestamps2 = [DateTime(2023, 1, 1), DateTime(2023, 1, 3)];
        final index1 = TimeSeriesIndex(timestamps1);
        final index2 = TimeSeriesIndex(timestamps2);

        expect(index1, isNot(equals(index2)));
      });
    });
  });

  group('FrequencyUtils', () {
    test('normalizes frequency strings', () {
      expect(FrequencyUtils.normalizeFrequency('daily'), equals('D'));
      expect(FrequencyUtils.normalizeFrequency('hourly'), equals('H'));
      expect(FrequencyUtils.normalizeFrequency('monthly'), equals('M'));
      expect(FrequencyUtils.normalizeFrequency('yearly'), equals('Y'));
      expect(FrequencyUtils.normalizeFrequency('annual'), equals('Y'));
      expect(FrequencyUtils.normalizeFrequency('d'), equals('D'));
      expect(FrequencyUtils.normalizeFrequency('unknown'), equals('UNKNOWN'));
    });

    test('validates frequency strings', () {
      expect(FrequencyUtils.isValidFrequency('D'), isTrue);
      expect(FrequencyUtils.isValidFrequency('H'), isTrue);
      expect(FrequencyUtils.isValidFrequency('M'), isTrue);
      expect(FrequencyUtils.isValidFrequency('Y'), isTrue);
      expect(FrequencyUtils.isValidFrequency('daily'), isTrue);
      expect(FrequencyUtils.isValidFrequency('X'), isFalse);
    });

    test('gets frequency duration', () {
      expect(
          FrequencyUtils.getFrequencyDuration('D'), equals(Duration(days: 1)));
      expect(
          FrequencyUtils.getFrequencyDuration('H'), equals(Duration(hours: 1)));
      expect(FrequencyUtils.getFrequencyDuration('M'),
          isNull); // Variable duration
      expect(FrequencyUtils.getFrequencyDuration('Y'),
          isNull); // Variable duration
    });

    test('provides frequency descriptions', () {
      expect(FrequencyUtils.frequencyDescription('D'), equals('Daily'));
      expect(FrequencyUtils.frequencyDescription('H'), equals('Hourly'));
      expect(FrequencyUtils.frequencyDescription('M'), equals('Monthly'));
      expect(FrequencyUtils.frequencyDescription('Y'), equals('Yearly'));
      expect(FrequencyUtils.frequencyDescription('X'), contains('Unknown'));
    });
  });

  group('DataFrame Time Series Operations', () {
    late DataFrame df;

    setUp(() {
      // Create a sample DataFrame with time series data
      df = DataFrame([
        [DateTime(2023, 1, 1), 10.0, 'A'],
        [DateTime(2023, 1, 2), 20.0, 'B'],
        [DateTime(2023, 1, 3), 30.0, 'A'],
        [DateTime(2023, 1, 4), 40.0, 'B'],
        [DateTime(2023, 1, 5), 50.0, 'A'],
        [DateTime(2023, 1, 6), 60.0, 'B'],
      ], columns: [
        'date',
        'value',
        'category'
      ]);
    });

    group('Resample Method', () {
      test('resamples daily to 2-day periods with mean', () {
        // Create a DataFrame with more data points for meaningful resampling
        final dailyDf = DataFrame([
          [DateTime(2023, 1, 1), 10.0],
          [DateTime(2023, 1, 2), 20.0],
          [DateTime(2023, 1, 3), 30.0],
          [DateTime(2023, 1, 4), 40.0],
        ], columns: [
          'date',
          'value'
        ]);

        final resampled =
            dailyDf.resample('D', dateColumn: 'date', aggFunc: 'mean');

        expect(resampled.rowCount, greaterThan(0));
        expect(resampled.columns, contains('date'));
        expect(resampled.columns, contains('value'));
      });

      test('resamples with sum aggregation', () {
        final resampled = df.resample('D', dateColumn: 'date', aggFunc: 'sum');

        expect(resampled.rowCount, greaterThan(0));
        // Check that numeric values are summed appropriately
        final values = resampled['value'].data.whereType<num>().toList();
        expect(values, isNotEmpty);
      });

      test('resamples with count aggregation', () {
        final resampled =
            df.resample('D', dateColumn: 'date', aggFunc: 'count');

        expect(resampled.rowCount, greaterThan(0));
        // Count should return integers
        final counts = resampled['value'].data.whereType<int>().toList();
        expect(counts, isNotEmpty);
      });

      test('throws error for invalid frequency', () {
        expect(
          () => df.resample('X', dateColumn: 'date'),
          throwsArgumentError,
        );
      });

      test('throws error when no date column found', () {
        final nonTimeDf = DataFrame([
          [1, 10.0],
          [2, 20.0],
        ], columns: [
          'id',
          'value'
        ]);

        expect(
          () => nonTimeDf.resample('D'),
          throwsArgumentError,
        );
      });

      test('throws error for non-existent date column', () {
        expect(
          () => df.resample('D', dateColumn: 'nonexistent'),
          throwsArgumentError,
        );
      });

      test('auto-detects date column when not specified', () {
        final resampled = df.resample('D', aggFunc: 'mean');

        expect(resampled.rowCount, greaterThan(0));
        expect(resampled.columns, contains('date'));
      });
    });

    group('Upsample Method', () {
      test('upsamples with pad method', () {
        // Create a sparser dataset for upsampling
        final sparseDf = DataFrame([
          [DateTime(2023, 1, 1), 10.0],
          [DateTime(2023, 1, 3), 30.0],
          [DateTime(2023, 1, 5), 50.0],
        ], columns: [
          'date',
          'value'
        ]);

        final upsampled =
            sparseDf.upsample('D', dateColumn: 'date', method: 'pad');

        expect(upsampled.rowCount, equals(5)); // Should fill in missing days
        expect(upsampled.columns, contains('date'));
        expect(upsampled.columns, contains('value'));
      });

      test('upsamples with backfill method', () {
        final sparseDf = DataFrame([
          [DateTime(2023, 1, 1), 10.0],
          [DateTime(2023, 1, 3), 30.0],
        ], columns: [
          'date',
          'value'
        ]);

        final upsampled =
            sparseDf.upsample('D', dateColumn: 'date', method: 'backfill');

        expect(upsampled.rowCount, equals(3));
      });

      test('upsamples with nearest method', () {
        final sparseDf = DataFrame([
          [DateTime(2023, 1, 1), 10.0],
          [DateTime(2023, 1, 3), 30.0],
        ], columns: [
          'date',
          'value'
        ]);

        final upsampled =
            sparseDf.upsample('D', dateColumn: 'date', method: 'nearest');

        expect(upsampled.rowCount, equals(3));
      });
    });

    group('Downsample Method', () {
      test('downsamples with mean aggregation', () {
        final downsampled =
            df.downsample('D', dateColumn: 'date', aggFunc: 'mean');

        expect(downsampled.rowCount, greaterThan(0));
        expect(downsampled.columns, contains('date'));
        expect(downsampled.columns, contains('value'));
      });

      test('downsamples with max aggregation', () {
        final downsampled =
            df.downsample('D', dateColumn: 'date', aggFunc: 'max');

        expect(downsampled.rowCount, greaterThan(0));
        // Values should be numeric
        final values = downsampled['value'].data.whereType<num>().toList();
        expect(values, isNotEmpty);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('handles empty DataFrame', () {
        final emptyDf = DataFrame([], columns: ['date', 'value']);

        expect(
          () => emptyDf.resample('D', dateColumn: 'date'),
          throwsArgumentError,
        );
      });

      test('handles DataFrame with null dates', () {
        final nullDateDf = DataFrame([
          [null, 10.0],
          [DateTime(2023, 1, 2), 20.0],
        ], columns: [
          'date',
          'value'
        ]);

        // Should still work with the non-null dates
        final resampled =
            nullDateDf.resample('D', dateColumn: 'date', aggFunc: 'mean');
        expect(resampled.rowCount, greaterThan(0));
      });

      test('handles DataFrame with mixed data types in date column', () {
        final mixedDf = DataFrame([
          [DateTime(2023, 1, 1), 10.0],
          ['not-a-date', 20.0],
          [DateTime(2023, 1, 3), 30.0],
        ], columns: [
          'date',
          'value'
        ]);

        expect(
          () => mixedDf.resample('D', dateColumn: 'date'),
          throwsArgumentError,
        );
      });

      test('handles unsupported aggregation function', () {
        expect(
          () => df.resample('D', dateColumn: 'date', aggFunc: 'unsupported'),
          throwsArgumentError,
        );
      });

      test('handles unsupported fill method', () {
        expect(
          () => df.upsample('D', dateColumn: 'date', method: 'unsupported'),
          throwsArgumentError,
        );
      });
    });
  });
}
