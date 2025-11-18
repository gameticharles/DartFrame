import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame DartData Integration', () {
    test('DataFrame implements DartData interface', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
      ], columns: [
        'A',
        'B',
        'C'
      ]);

      // Test basic properties
      expect(df.ndim, equals(2));
      expect(df.size, equals(9));
      expect(df.shape.ndim, equals(2));
      expect(df.shape[0], equals(3)); // rows
      expect(df.shape[1], equals(3)); // columns
      expect(df.isHomogeneous, isFalse);
      expect(df.dtype, equals(dynamic));
    });

    test('DataFrame columnTypes returns correct types', () {
      final df = DataFrame.fromMap({
        'id': [1, 2, 3],
        'name': ['Alice', 'Bob', 'Charlie'],
        'score': [95.5, 87.3, 92.1],
      });

      final types = df.columnTypes;
      expect(types['id'], equals(int));
      expect(types['name'], equals(String));
      expect(types['score'], equals(double));
    });

    test('DataFrame getValue and setValue work', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
      ]);

      expect(df.getValue([0, 1]), equals(2));
      expect(df.getValue([1, 2]), equals(6));

      df.setValue([0, 1], 99);
      expect(df.getValue([0, 1]), equals(99));
    });

    test('DataFrame slice returns Scalar for single element', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
      ]);

      final result = df.slice([0, 1]);
      expect(result, isA<Scalar>());
      expect((result as Scalar).value, equals(2));
    });

    test('DataFrame slice returns Series for single row', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
      ]);

      final result = df.slice([0, Slice.all()]);
      expect(result, isA<Series>());
      final series = result as Series;
      expect(series.data, equals([1, 2, 3]));
    });

    test('DataFrame slice returns DataFrame for range', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
      ]);

      final result = df.slice([Slice.range(0, 2), Slice.all()]);
      expect(result, isA<DataFrame>());
      final subDf = result as DataFrame;
      expect(subDf.rowCount, equals(2));
      expect(subDf.columnCount, equals(3));
    });

    test('DataFrame attrs work', () {
      final df = DataFrame([
        [1, 2],
        [3, 4]
      ]);

      df.attrs['units'] = 'celsius';
      df.attrs['description'] = 'Temperature data';
      df.attrs['created'] = DateTime(2024, 1, 1);

      expect(df.attrs['units'], equals('celsius'));
      expect(df.attrs['description'], equals('Temperature data'));
      expect(df.attrs.length, equals(3));
    });
  });

  group('Series DartData Integration', () {
    test('Series implements DartData interface', () {
      final series = Series([1, 2, 3, 4, 5], name: 'numbers');

      expect(series.ndim, equals(1));
      expect(series.size, equals(5));
      expect(series.shape.ndim, equals(1));
      expect(series.shape[0], equals(5));
      expect(series.isHomogeneous, isTrue);
      expect(series.dtype, equals(int));
    });

    test('Series with mixed types is not homogeneous', () {
      final series = Series([1, 'a', 2.5], name: 'mixed');

      expect(series.isHomogeneous, isFalse);
      expect(series.dtype, equals(int)); // First element type
    });

    test('Series getValue and setValue work', () {
      final series = Series([10, 20, 30, 40], name: 'values');

      expect(series.getValue([0]), equals(10));
      expect(series.getValue([2]), equals(30));

      series.setValue([1], 99);
      expect(series.getValue([1]), equals(99));
    });

    test('Series slice returns Scalar for single element', () {
      final series = Series([10, 20, 30, 40], name: 'values');

      final result = series.slice([2]);
      expect(result, isA<Scalar>());
      expect((result as Scalar).value, equals(30));
    });

    test('Series slice returns Series for range', () {
      final series = Series([10, 20, 30, 40, 50], name: 'values');

      final result = series.slice([Slice.range(1, 4)]);
      expect(result, isA<Series>());
      final subSeries = result as Series;
      expect(subSeries.data, equals([20, 30, 40]));
      expect(subSeries.name, equals('values'));
    });

    test('Series attrs work', () {
      final series = Series([1, 2, 3], name: 'temperature');

      series.attrs['units'] = 'celsius';
      series.attrs['sensor_id'] = 'TEMP_001';

      expect(series.attrs['units'], equals('celsius'));
      expect(series.attrs['sensor_id'], equals('TEMP_001'));
      expect(series.attrs.length, equals(2));
    });

    test('Series isEmpty and isNotEmpty work', () {
      final empty = Series([], name: 'empty');
      final notEmpty = Series([1, 2, 3], name: 'data');

      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
      expect(notEmpty.isEmpty, isFalse);
      expect(notEmpty.isNotEmpty, isTrue);
    });
  });

  group('DartData Polymorphism', () {
    test('Can treat DataFrame and Series as DartData', () {
      final List<DartData> dataStructures = [
        DataFrame([
          [1, 2],
          [3, 4]
        ]),
        Series([1, 2, 3], name: 'test'),
      ];

      expect(dataStructures[0].ndim, equals(2));
      expect(dataStructures[1].ndim, equals(1));

      expect(dataStructures[0].size, equals(4));
      expect(dataStructures[1].size, equals(3));
    });

    test('Can use DartData methods polymorphically', () {
      DartData df = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      DartData series = Series([10, 20, 30], name: 'values');

      expect(df.getValue([0, 1]), equals(2));
      expect(series.getValue([1]), equals(20));

      df.attrs['source'] = 'test';
      series.attrs['source'] = 'test';

      expect(df.attrs['source'], equals('test'));
      expect(series.attrs['source'], equals('test'));
    });
  });
}
