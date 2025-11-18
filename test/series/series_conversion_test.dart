import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  const missingMarker = -999; // For tests involving DataFrame context

  group('Series.toNumeric()', () {
    test('toNumeric basic string to int/double', () {
      final s = Series(['1', '2.5', '3', '4.0'], name: 'str_nums');
      final numericS = s.toNumeric();
      expect(numericS.data, equals([1, 2.5, 3, 4.0]));
      expect(numericS.data.map((e) => e.runtimeType).toList(),
          equals([int, double, int, double]));
    });

    test('toNumeric with actual numbers (no change)', () {
      final s = Series([1, 2.5, 3], name: 'actual_nums');
      final numericS = s.toNumeric();
      expect(numericS.data, equals([1, 2.5, 3]));
    });

    test('toNumeric errors="raise" (default)', () {
      final s = Series(['1', 'abc', '3'], name: 'invalid_str');
      expect(
          () => s.toNumeric(errors: 'raise'), throwsA(isA<FormatException>()));
    });

    test('toNumeric errors="coerce" with null as missing', () {
      final s = Series(['1', 'abc', '3.0', null], name: 'coerce_nulls');
      // Assuming Series without parent DataFrame, missingMarker is null
      final numericS = s.toNumeric(errors: 'coerce');
      expect(numericS.data, equals([1, null, 3.0, null]));
    });

    test('toNumeric errors="coerce" with custom missing marker', () {
      var df = DataFrame.fromMap({
        'col': ['1', 'abc', '3.0', 'xyz']
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col'];
      s.setParent(df, 'col');
      final numericS = s.toNumeric(errors: 'coerce');
      expect(numericS.data, equals([1, missingMarker, 3.0, missingMarker]));
    });

    test('toNumeric errors="ignore"', () {
      final s = Series(['1', 'abc', '3.0', true], name: 'ignore_errors');
      final numericS = s.toNumeric(errors: 'ignore');
      expect(numericS.data,
          equals([1, 'abc', 3.0, true])); // 'abc' and true remain
    });

    test('toNumeric downcast="integer"', () {
      final s = Series(['1.0', '2.5', '3', '4.000'], name: 'downcast_int');
      final numericS = s.toNumeric(downcast: 'integer');
      expect(numericS.data, equals([1, 2.5, 3, 4])); // 2.5 cannot be downcast
      expect(numericS.data.map((e) => e.runtimeType).toList(),
          equals([int, double, int, int]));
    });

    test('toNumeric downcast="integer" with errors="coerce"', () {
      final s = Series(['1.0', '2.5', '3'], name: 'downcast_int_coerce');
      final numericS = s.toNumeric(downcast: 'integer', errors: 'coerce');
      // 2.5 cannot be downcast to int without loss, so it becomes missing (null)
      expect(numericS.data, equals([1, null, 3]));
    });

    test('toNumeric downcast="float"', () {
      final s = Series(['1', '2.5', '3.0'], name: 'downcast_float');
      final numericS = s.toNumeric(downcast: 'float');
      expect(numericS.data, equals([1.0, 2.5, 3.0]));
      expect(numericS.data.every((e) => e is double), isTrue);
    });

    test('toNumeric empty series', () {
      final s = Series([], name: 'empty_numeric');
      final numericS = s.toNumeric();
      expect(numericS.data, isEmpty);
    });

    test('toNumeric with existing missing values (null)', () {
      final s = Series(['1', null, '2.5'], name: 'existing_null');
      final numericS = s.toNumeric(errors: 'coerce');
      expect(numericS.data, equals([1, null, 2.5]));
    });

    test('toNumeric with existing missing values (custom marker)', () {
      var df = DataFrame.fromMap({
        'col': ['1', missingMarker, '2.5']
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col'];
      s.setParent(df, 'col');
      final numericS = s.toNumeric(errors: 'coerce');
      expect(numericS.data, equals([1, missingMarker, 2.5]));
    });
  });

  group('Series.toDatetime()', () {
    final dt1 = DateTime(2023, 10, 26);
    final dt2 = DateTime(2024, 3, 1, 14, 30);

    test('toDatetime basic ISO 8601 strings', () {
      final s = Series(['2023-10-26', '2024-03-01T14:30:00', null],
          name: 'iso_dates');
      final datetimeS = s.toDatetime();
      expect(datetimeS.data, equals([dt1, dt2, null]));
    });

    test('toDatetime with actual DateTime objects (no change)', () {
      final s = Series([dt1, dt2, null], name: 'actual_dates');
      final datetimeS = s.toDatetime();
      expect(datetimeS.data, equals([dt1, dt2, null]));
    });

    test('toDatetime errors="raise" (default)', () {
      final s = Series(['2023-10-26', 'not-a-date'], name: 'invalid_date_str');
      expect(() => s.toDatetime(), throwsA(isA<FormatException>()));
    });

    test('toDatetime errors="coerce" with null as missing', () {
      final s =
          Series(['2023-10-26', 'invalid', null], name: 'coerce_date_nulls');
      final datetimeS = s.toDatetime(errors: 'coerce');
      expect(datetimeS.data, equals([dt1, null, null]));
    });

    test('toDatetime errors="coerce" with custom missing marker', () {
      var df = DataFrame.fromMap({
        'col': ['2023-10-26', 'invalid', 'xyz']
      }, replaceMissingValueWith: missingMarker);
      Series s = df['col'];
      s.setParent(df, 'col');
      final datetimeS = s.toDatetime(errors: 'coerce');
      expect(datetimeS.data, equals([dt1, missingMarker, missingMarker]));
    });

    test('toDatetime errors="ignore"', () {
      final s =
          Series(['2023-10-26', 'invalid', true], name: 'ignore_date_errors');
      final datetimeS = s.toDatetime(errors: 'ignore');
      expect(datetimeS.data, equals([dt1, 'invalid', true]));
    });

    test('toDatetime with specific format', () {
      // final s = Series(['26/10/2023', '01/03/2024 14:30'], name: 'custom_format');
      // final datetimeS = s.toDatetime(format: 'dd/MM/yyyy HH:mm');

      // First entry needs HH:mm too, or parseStrict will fail if format includes time.
      // Let's adjust test or format. For 'dd/MM/yyyy HH:mm', '26/10/2023' is invalid.
      // Test with 'dd/MM/yyyy' for the first, and a separate test for time.
      final sDateOnly =
          Series(['26/10/2023', '01/03/2024'], name: 'custom_date_only');
      final dtDateOnly = sDateOnly.toDatetime(format: 'dd/MM/yyyy');
      expect(dtDateOnly.data,
          equals([DateTime(2023, 10, 26), DateTime(2024, 3, 1)]));

      final sDateTime = Series(['26/10/2023 10:00', '01/03/2024 14:30'],
          name: 'custom_datetime');
      final dtDateTime = sDateTime.toDatetime(format: 'dd/MM/yyyy HH:mm');
      expect(
          dtDateTime.data,
          equals(
              [DateTime(2023, 10, 26, 10, 0), DateTime(2024, 3, 1, 14, 30)]));
    });

    test('toDatetime inferDatetimeFormat=true', () {
      final s = Series(['10/26/2023', '2024-03-01 14:30:00', '01.Mar.2024'],
          name: 'infer_dates');
      // This test depends heavily on the list of common formats used by inferDatetimeFormat.
      // Assuming 'MM/dd/yyyy' and 'yyyy-MM-dd HH:mm:ss' are common. '01.Mar.2024' might not be.
      // The current infer logic tries ISO first, then a specific list.
      final datetimeS =
          s.toDatetime(inferDatetimeFormat: true, errors: 'coerce');
      expect(datetimeS.data[0], equals(DateTime(2023, 10, 26)));
      expect(datetimeS.data[1], equals(DateTime(2024, 3, 1, 14, 30)));
      // For '01.Mar.2024', it would be null (or missingMarker) if not in common formats.
      // The current common formats are:
      // 'yyyy-MM-dd HH:mm:ss', 'yyyy-MM-ddTHH:mm:ss', 'yyyy-MM-dd',
      // 'MM/dd/yyyy HH:mm:ss', 'MM/dd/yyyy', 'dd/MM/yyyy HH:mm:ss', 'dd/MM/yyyy',
      // 'yyyy.MM.dd HH:mm:ss', 'yyyy.MM.dd', 'MM-dd-yyyy HH:mm:ss', 'MM-dd-yyyy'
      // So '01.Mar.2024' is not covered.
      expect(datetimeS.data[2], isNull);
    });

    test('toDatetime with numeric timestamps (milliseconds since epoch)', () {
      final epochTime1 = dt1.millisecondsSinceEpoch;
      final epochTime2 = dt2.millisecondsSinceEpoch;
      final s = Series([epochTime1, epochTime2, null], name: 'timestamps');
      final datetimeS = s.toDatetime();
      expect(datetimeS.data, equals([dt1, dt2, null]));
    });

    test('toDatetime empty series', () {
      final s = Series([], name: 'empty_datetime');
      final datetimeS = s.toDatetime();
      expect(datetimeS.data, isEmpty);
    });
  });
}
