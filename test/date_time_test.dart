import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Series.to_datetime()', () {
    // Default missing representation for Series not attached to a DataFrame
    final dynamic defaultMissingRep = null; 

    group('Basic String Conversions:', () {
      test('ISO 8601 strings (yyyy-MM-ddTHH:mm:ss)', () {
        final s = Series(['2023-10-26T10:30:00', '2024-01-15T23:15:45'], name: 'iso_datetime');
        final result = s.toDatetime();
        expect(result.data, equals([DateTime(2023, 10, 26, 10, 30, 0), DateTime(2024, 1, 15, 23, 15, 45)]));
        expect(result.dtype, equals(DateTime));
      });

      test('ISO 8601 strings (yyyy-MM-dd, time defaults to midnight)', () {
        final s = Series(['2023-10-26', '2024-01-15'], name: 'iso_date');
        final result = s.toDatetime();
        expect(result.data, equals([DateTime(2023, 10, 26), DateTime(2024, 1, 15)]));
      });
      
      test('ISO 8601 strings with Z (UTC)', () {
        final s = Series(['2023-10-26T10:30:00Z', '2024-01-15T00:00:00Z'], name: 'iso_utc');
        final result = s.toDatetime();
        expect(result.data, equals([
            DateTime.utc(2023, 10, 26, 10, 30, 0), 
            DateTime.utc(2024, 1, 15, 0, 0, 0)
        ]));
      });

      test('infer_datetime_format=true for "yyyy-MM-dd HH:mm:ss"', () {
        final s = Series(['2023-10-26 14:30:00'], name: 'custom_space');
        final result = s.toDatetime(inferDatetimeFormat: true);
        expect(result.data, equals([DateTime(2023, 10, 26, 14, 30, 0)]));
      });
      
      test('infer_datetime_format=true for "MM/dd/yyyy"', () {
        final s = Series(['10/26/2023', '01/15/2024'], name: 'us_date');
        final result = s.toDatetime(inferDatetimeFormat: true);
        expect(result.data, equals([DateTime(2023, 10, 26), DateTime(2024, 1, 15)]));
      });
      
      test('infer_datetime_format=true for "dd/MM/yyyy"', () {
        final s = Series(['26/10/2023', '15/01/2024'], name: 'eu_date');
        final result = s.toDatetime(inferDatetimeFormat: true);
        expect(result.data, equals([DateTime(2023, 10, 26), DateTime(2024, 1, 15)]));
      });
      
      test('String with only date part (gets midnight)', () {
        final s = Series(['2023-03-15'], name: 'date_only');
        final result = s.toDatetime();
        expect(result.data.first, equals(DateTime(2023, 3, 15, 0, 0, 0)));
      });

      // DateTime.tryParse does not support time-only strings without a date.
      // So this would rely on infer_datetime_format with a custom format or specific handling.
      // For now, we expect it to fail or be coerced.
      test('String with only time part (unsupported by default, handled by errors)', () {
        final s = Series(['10:30:00'], name: 'time_only');
        expect(() => s.toDatetime(errors: 'raise'), throwsA(isA<FormatException>()));
        final resultCoerce = s.toDatetime(errors: 'coerce');
        expect(resultCoerce.data.first, equals(defaultMissingRep));
      });
    });

    group('`format` Parameter:', () {
      test('Correct format "yyyy/MM/dd HH:mm"', () {
        final s = Series(['2023/10/26 10:45', '2024/01/15 05:15'], name: 'custom_format');
        final result = s.toDatetime(format: 'yyyy/MM/dd HH:mm');
        expect(result.data, equals([DateTime(2023, 10, 26, 10, 45), DateTime(2024, 1, 15, 5, 15)]));
      });

      test('Non-matching format string with errors="raise"', () {
        final s = Series(['2023-10-26'], name: 'wrong_format');
        expect(() => s.toDatetime(format: 'yyyy/MM/dd', errors: 'raise'), throwsA(isA<FormatException>()));
      });
      
      test('Non-matching format string with errors="coerce"', () {
        final s = Series(['2023-10-26'], name: 'wrong_format_coerce');
        final result = s.toDatetime(format: 'yyyy/MM/dd', errors: 'coerce');
        expect(result.data.first, equals(defaultMissingRep));
      });
    });
    
    group('`infer_datetime_format` true vs. false:', () {
      test('Infer succeeds where default tryParse fails', () {
        //final s = Series(['26-Oct-2023'], name: 'custom_infer'); // DateTime.tryParse fails
        // Add a format that DateFormat can handle if intl is available and used by infer_datetime_format
        // For this test, we'll assume our infer_datetime_format list doesn't include this.
        // A more robust test would mock or ensure specific formats for infer_datetime_format.
        // For now, let's use a format that *is* in the common list.
        final s2 = Series(['26/10/2023'], name: 'infer_eu_date');
        final resultInferTrue = s2.toDatetime(inferDatetimeFormat: true);
        expect(resultInferTrue.data.first, equals(DateTime(2023, 10, 26)));

        // Without infer_datetime_format, and no explicit format, DateTime.tryParse would be used.
        // '26/10/2023' is NOT parsable by DateTime.tryParse directly.
        expect(() => s2.toDatetime(inferDatetimeFormat: false, errors: 'raise'), throwsA(isA<FormatException>()));
      });
    });

    group('Numeric Timestamps (Milliseconds Since Epoch):', () {
      test('Integer timestamps', () {
        final ts1 = DateTime(2023, 1, 1, 10, 0, 0).millisecondsSinceEpoch;
        final ts2 = DateTime(2023, 1, 1, 12, 30, 0).millisecondsSinceEpoch;
        final s = Series([ts1, ts2], name: 'int_ts');
        final result = s.toDatetime();
        expect(result.data, equals([DateTime.fromMillisecondsSinceEpoch(ts1), DateTime.fromMillisecondsSinceEpoch(ts2)]));
      });

      test('Double timestamps (converted to int)', () {
        final ts1Double = DateTime(2023, 5, 10, 8, 0, 0).millisecondsSinceEpoch.toDouble();
        final ts1Int = ts1Double.toInt();
        final s = Series([ts1Double, 1678886400000.0], name: 'double_ts'); // 2023-03-15T12:00:00.000Z
        final result = s.toDatetime();
        expect(result.data, equals([
            DateTime.fromMillisecondsSinceEpoch(ts1Int), 
            DateTime.fromMillisecondsSinceEpoch(1678886400000)
        ]));
      });
    });
    
    group('`errors` Parameter Behavior:', () {
      final sInvalid = Series(['2023-13-01', 'not-a-date', 12345, '2023-01-01'], name: 'invalid_dates');
      final sValid = Series(['2022-01-01'], name: 'valid_date');

      test("errors = 'raise' (default)", () {
        expect(() => sInvalid.toDatetime(), throwsA(isA<FormatException>()));
        expect(sValid.toDatetime().data.first, equals(DateTime(2022,1,1))); // Ensure valid still works
      });

      test("errors = 'coerce'", () {
        final result = sInvalid.toDatetime(errors: 'coerce');
        expect(result.data, equals([DateTime(2024,01,01), defaultMissingRep, DateTime.fromMillisecondsSinceEpoch(12345), DateTime(2023,1,1)]));
      });
      
      test("errors = 'coerce' with custom missing value", () {
        final df = DataFrame.fromRows([{'dates': 'invalid'}], replaceMissingValueWith: 'NaT');
        final sInDf = Series(['2023-10-26', 'bad-date'], name: 'dates_in_df');
        sInDf.setParent(df, 'dates');
        
        final result = sInDf.toDatetime(errors: 'coerce');
        expect(result.data, equals([DateTime(2023,10,26), 'NaT']));
      });

      test("errors = 'ignore'", () {
        final result = sInvalid.toDatetime(errors: 'ignore');
        expect(result.data, equals([DateTime(2024,01,01), 'not-a-date', DateTime.fromMillisecondsSinceEpoch(12345), DateTime(2023,1,1)]));
        expect(result.data[0] is String, isFalse);
        expect(result.data[1] is String, isTrue);
        expect(result.data[2] is DateTime, isTrue);
        expect(result.data[3] is DateTime, isTrue);
      });

      test('Invalid "errors" value throws ArgumentError', () {
        expect(() => sInvalid.toDatetime(errors: 'unknown_policy'), throwsArgumentError);
      });
    });
    
    group('Handling of Existing DateTime Objects:', () {
      test('Series with DateTime objects preserved', () {
        final dt1 = DateTime(2023,1,1);
        final dt2 = DateTime(2024,2,2);
        final s = Series([dt1, '2023-03-03', dt2], name: 'existing_dt');
        final result = s.toDatetime();
        expect(result.data, equals([dt1, DateTime(2023,3,3), dt2]));
        expect(result.data.every((e) => e is DateTime), isTrue);
      });
    });

    group('Handling of Missing Values in Input:', () {
      test('Series with nulls (default missing)', () {
        final s = Series([null, '2023-01-01', null], name: 'input_nulls');
        final result = s.toDatetime(errors: 'coerce'); // errors shouldn't affect already null values
        expect(result.data, equals([null, DateTime(2023,1,1), null]));
      });
      
      test('Series with custom missing value', () {
        final df = DataFrame.fromRows(
            [{'dates': 'NODATE'}, {'dates': '2023-01-01'}], 
            replaceMissingValueWith: 'NODATE');
        final s = df['dates'];
        final result = s.toDatetime(errors: 'coerce');
        expect(result.data, equals(['NODATE', DateTime(2023,1,1)]));
      });
    });

    group('Result Properties:', () {
      test('Name and Index are preserved', () {
        final originalIndex = [10,20];
        final s = Series(['2023-01-01', '2023-01-02'], name: 'test_name_dt', index: originalIndex);
        final result = s.toDatetime();
        expect(result.name, equals('test_name_dt'));
        expect(result.index, equals(originalIndex));
      });

      test('dtype is DateTime for successful conversions', () {
        final s = Series(['2023-01-01', '2023-01-02'], name: 'all_dt_str');
        final result = s.toDatetime();
        expect(result.data.every((e) => e is DateTime), isTrue);
      });
    });
  });

  group('dateRange() top-level function', () {
    group('Parameter Combinations:', () {
      test('start and periods specified', () {
        final result = dateRange(start: DateTime(2023, 1, 1), periods: 3);
        expect(result.data, equals([
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
          DateTime(2023, 1, 3),
        ]));
        expect(result.length, equals(3));
      });

      test('end and periods specified', () {
        final result = dateRange(end: DateTime(2023, 1, 3), periods: 3);
        expect(result.data, equals([
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
          DateTime(2023, 1, 3),
        ]));
        expect(result.length, equals(3));
      });

      test('start and end specified', () {
        final result = dateRange(start: DateTime(2023, 1, 1), end: DateTime(2023, 1, 3));
        expect(result.data, equals([
          DateTime(2023, 1, 1),
          DateTime(2023, 1, 2),
          DateTime(2023, 1, 3),
        ]));
        expect(result.length, equals(3));
      });

      test('Error: only start specified', () {
        expect(() => dateRange(start: DateTime(2023,1,1)), throwsArgumentError);
      });

      test('Error: only end specified', () {
        expect(() => dateRange(end: DateTime(2023,1,1)), throwsArgumentError);
      });

      test('Error: only periods specified', () {
        expect(() => dateRange(periods: 3), throwsArgumentError);
      });

      test('Error: all three specified (inconsistent periods)', () {
        expect(() => dateRange(start: DateTime(2023,1,1), end: DateTime(2023,1,5), periods: 3), throwsArgumentError);
      });

       test('Error: all three specified (start after end, positive periods)', () {
        expect(() => dateRange(start: DateTime(2023,1,5), end: DateTime(2023,1,1), periods: 3), throwsArgumentError);
      });

      test('All three specified (consistent)', () {
        final result = dateRange(start: DateTime(2023,1,1), end: DateTime(2023,1,3), periods: 3);
        expect(result.data, equals([
          DateTime(2023,1,1), DateTime(2023,1,2), DateTime(2023,1,3)
        ]));
      });
    });

    group('freq="D" (Daily Frequency):', () {
       test('Verify daily increment with start and periods', () {
        final result = dateRange(start: DateTime(2023,2,27), periods: 4);
        expect(result.data, equals([
          DateTime(2023,2,27), DateTime(2023,2,28), DateTime(2023,3,1), DateTime(2023,3,2)
        ]));
      });
      test('Verify daily increment with end and periods', () {
        final result = dateRange(end: DateTime(2023,3,2), periods: 4);
         expect(result.data, equals([
          DateTime(2023,2,27), DateTime(2023,2,28), DateTime(2023,3,1), DateTime(2023,3,2)
        ]));
      });
       test('Verify daily increment with start and end crossing month', () {
        final result = dateRange(start: DateTime(2023,2,27), end: DateTime(2023,3,2));
         expect(result.data, equals([
          DateTime(2023,2,27), DateTime(2023,2,28), DateTime(2023,3,1), DateTime(2023,3,2)
        ]));
      });
    });

    group('normalize Parameter:', () {
      test('normalize = true with start and end', () {
        final result = dateRange(
          start: DateTime(2023, 1, 1, 10, 30),
          end: DateTime(2023, 1, 2, 15, 45),
          normalize: true
        );
        expect(result.data, equals([
          DateTime(2023, 1, 1), DateTime(2023, 1, 2)
        ]));
      });
      test('normalize = true with start and periods', () {
        final result = dateRange(
          start: DateTime(2023, 1, 1, 10, 30),
          periods: 2,
          normalize: true
        );
        expect(result.data, equals([
          DateTime(2023, 1, 1), DateTime(2023, 1, 2)
        ]));
      });
      test('normalize = false (default) preserves time in first element if start has time', () {
        final startDt = DateTime(2023, 1, 1, 10, 30);
        final result = dateRange(start: startDt, periods: 2, normalize: false);
        expect(result.data, equals([
          startDt, startDt.add(const Duration(days:1))
        ]));
      });
    });

    group('name Parameter:', () {
      test('Custom name provided', () {
        final result = dateRange(start: DateTime(2023,1,1), periods: 1, name: 'MyDateRange');
        expect(result.name, equals('MyDateRange'));
      });
      test('Default name used when not provided', () {
        final result = dateRange(start: DateTime(2023,1,1), periods: 1);
        expect(result.name, equals('dateRange'));
      });
    });
    
    group('periods Parameter Edge Cases:', () {
      test('periods = 0 with start', () {
        final result = dateRange(start: DateTime(2023,1,1), periods: 0);
        expect(result.data, isEmpty);
      });
      test('periods = 0 with end', () {
        final result = dateRange(end: DateTime(2023,1,1), periods: 0);
        expect(result.data, isEmpty);
      });
       test('periods = 0 with start and end (consistent)', () {
        final result = dateRange(start: DateTime(2023,1,1), end: DateTime(2022,12,31), periods: 0); // start after end, but periods=0
        expect(result.data, isEmpty);
      });
      test('periods = 1 with start', () {
        final result = dateRange(start: DateTime(2023,1,1), periods: 1);
        expect(result.data, equals([DateTime(2023,1,1)]));
      });
      test('periods = 1 with end', () {
        final result = dateRange(end: DateTime(2023,1,1), periods: 1);
        expect(result.data, equals([DateTime(2023,1,1)]));
      });
      test('periods < 0 throws ArgumentError', () {
        expect(() => dateRange(start: DateTime(2023,1,1), periods: -1), throwsArgumentError);
      });
    });

    group('start and end Edge Cases:', () {
      test('start after end, no periods (empty or error)', () {
        // Current implementation produces empty list for start > end if periods is null
        final result = dateRange(start: DateTime(2023,1,5), end: DateTime(2023,1,1));
        expect(result.data, isEmpty); 
      });
      test('start after end, with positive periods throws ArgumentError', () {
         expect(() => dateRange(start: DateTime(2023,1,5), end: DateTime(2023,1,1), periods: 2), throwsArgumentError);
      });
      test('start equal to end, no periods', () {
        final result = dateRange(start: DateTime(2023,1,1), end: DateTime(2023,1,1));
        expect(result.data, equals([DateTime(2023,1,1)]));
      });
      test('start equal to end, periods = 1', () {
        final result = dateRange(start: DateTime(2023,1,1), end: DateTime(2023,1,1), periods: 1);
        expect(result.data, equals([DateTime(2023,1,1)]));
      });
       test('start equal to end, periods = 0', () {
        final result = dateRange(start: DateTime(2023,1,1), end: DateTime(2023,1,1), periods: 0);
        expect(result.data, isEmpty);
      });
    });

    group('Result Properties:', () {
      test('Output is a Series', () {
        expect(dateRange(start: DateTime(2023,1,1), periods: 1), isA<Series>());
      });
      test('Series.data is List<DateTime>', () {
        final result = dateRange(start: DateTime(2023,1,1), periods: 3);
        expect(result.data, isA<List<DateTime>>());
        expect(result.data.every((d) => d is DateTime), isTrue);
      });
      test('Series.index is default integer index', () {
        final result = dateRange(start: DateTime(2023,1,1), periods: 3);
        expect(result.index, isNull); // Default index is null for Series
      });
    });
    
    group('Unsupported freq:', () {
      test('freq = "H" throws ArgumentError', () {
        expect(() => dateRange(start: DateTime(2023,1,1), periods: 1, freq: 'H'), throwsArgumentError);
      });
    });
  });
}

