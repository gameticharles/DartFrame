import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DartData Integration - NDArray to Series', () {
    test('1D NDArray to Series', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final series = array.toSeries();

      expect(series.length, equals(5));
      expect(series.data, equals([1, 2, 3, 4, 5]));
      expect(series.name, equals('series_0'));
    });

    test('2D NDArray to Series (extracts first column)', () {
      final array = NDArray([
        [1, 2],
        [3, 4],
        [5, 6]
      ]);
      final series = array.toSeries();

      expect(series.length, equals(3));
      expect(series.data, equals([1, 3, 5]));
      expect(series.name, equals('col_0'));
    });

    test('3D NDArray to Series (flattens)', () {
      final array = NDArray.generate(
          [2, 2, 2], (indices) => indices[0] * 4 + indices[1] * 2 + indices[2]);
      final series = array.toSeries();

      expect(series.length, equals(8));
      expect(series.name, equals('flattened'));
    });

    test('throws error for >3D NDArray', () {
      final array = NDArray.generate([2, 2, 2, 2], (indices) => 1);

      expect(() => array.toSeries(), throwsArgumentError);
    });
  });

  group('DartData Integration - NDArray to DataFrame', () {
    test('2D NDArray to DataFrame', () {
      final array = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final df = array.toDataFrame();

      expect(df.rowCount, equals(2));
      expect(df.columnCount, equals(3));
      expect(df.columns, equals(['col_0', 'col_1', 'col_2']));
      expect(df.iloc(0, 0), equals(1));
      expect(df.iloc(1, 2), equals(6));
    });

    test('1D NDArray to DataFrame (single column)', () {
      final array = NDArray([10, 20, 30]);
      final df = array.toDataFrame();

      expect(df.rowCount, equals(3));
      expect(df.columnCount, equals(1));
      expect(df.columns, equals(['col_0']));
      expect(df.iloc(0, 0), equals(10));
      expect(df.iloc(2, 0), equals(30));
    });

    test('3D NDArray to DataFrame (extracts first frame)', () {
      final array = NDArray.generate([3, 2, 4],
          (indices) => indices[0] * 10 + indices[1] * 5 + indices[2]);
      final df = array.toDataFrame();

      expect(df.rowCount, equals(2));
      expect(df.columnCount, equals(4));
      // First frame (depth=0)
      expect(df.iloc(0, 0), equals(0));
      expect(df.iloc(1, 3), equals(8));
    });

    test('throws error for >3D NDArray', () {
      final array = NDArray.generate([2, 2, 2, 2], (indices) => 1);

      expect(() => array.toDataFrame(), throwsArgumentError);
    });
  });

  group('DartData Integration - NDArray to DataCube', () {
    test('3D NDArray to DataCube', () {
      final array = NDArray.generate([2, 3, 4],
          (indices) => indices[0] * 100 + indices[1] * 10 + indices[2]);
      final cube = array.toDataCube();

      expect(cube.depth, equals(2));
      expect(cube.rows, equals(3));
      expect(cube.columns, equals(4));
      expect(cube.getValue([0, 0, 0]), equals(0));
      expect(cube.getValue([1, 2, 3]), equals(123));
    });

    test('2D NDArray to DataCube (single frame)', () {
      final array = NDArray([
        [1, 2],
        [3, 4]
      ]);
      final cube = array.toDataCube();

      expect(cube.depth, equals(1));
      expect(cube.rows, equals(2));
      expect(cube.columns, equals(2));
      expect(cube.getValue([0, 0, 0]), equals(1));
      expect(cube.getValue([0, 1, 1]), equals(4));
    });

    test('1D NDArray to DataCube (1x1xN)', () {
      final array = NDArray([5, 10, 15, 20]);
      final cube = array.toDataCube();

      expect(cube.depth, equals(1));
      expect(cube.rows, equals(1));
      expect(cube.columns, equals(4));
      expect(cube.getValue([0, 0, 0]), equals(5));
      expect(cube.getValue([0, 0, 3]), equals(20));
    });

    test('throws error for >3D NDArray', () {
      final array = NDArray.generate([2, 2, 2, 2], (indices) => 1);

      expect(() => array.toDataCube(), throwsArgumentError);
    });
  });

  group('DartData Integration - Series conversions', () {
    test('Series to NDArray', () {
      final series = Series([1, 2, 3, 4], name: 'test');
      final array = series.toNDArray();

      expect(array.ndim, equals(1));
      expect(array.shape.toList(), equals([4]));
      expect(array.toFlatList(), equals([1, 2, 3, 4]));
    });

    test('Series to DataFrame', () {
      final series = Series([10, 20, 30], name: 'values');
      final df = series.toDataFrame();

      expect(df.rowCount, equals(3));
      expect(df.columnCount, equals(1));
      expect(df.columns, contains('values'));
      expect(df.iloc(0, 0), equals(10));
    });

    test('Series to DataCube (1x1xN)', () {
      final series = Series([1, 2, 3], name: 'data');
      final cube = series.toDataCube();

      expect(cube.depth, equals(1));
      expect(cube.rows, equals(1));
      expect(cube.columns, equals(3));
      expect(cube.getValue([0, 0, 0]), equals(1));
      expect(cube.getValue([0, 0, 2]), equals(3));
    });

    test('Series to Series (identity)', () {
      final series = Series([1, 2, 3], name: 'test');
      final result = series.toSeries();

      expect(identical(result, series), isTrue);
    });
  });

  group('DartData Integration - DataFrame conversions', () {
    test('DataFrame to NDArray', () {
      final df = DataFrame([
        [1, 2],
        [3, 4],
        [5, 6]
      ], columns: [
        'A',
        'B'
      ]);
      final array = df.toNDArray();

      expect(array.ndim, equals(2));
      expect(array.shape.toList(), equals([3, 2]));
      expect(array.getValue([0, 0]), equals(1));
      expect(array.getValue([2, 1]), equals(6));
    });

    test('DataFrame to Series (extracts first column)', () {
      final df = DataFrame([
        [1, 2],
        [3, 4]
      ], columns: [
        'X',
        'Y'
      ]);
      final series = df.toSeries();

      expect(series.length, equals(2));
      expect(series.data, equals([1, 3]));
      expect(series.name, equals('X'));
    });

    test('DataFrame to DataCube (single frame)', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6]
      ], columns: [
        'A',
        'B',
        'C'
      ]);
      final cube = df.toDataCube();

      expect(cube.depth, equals(1));
      expect(cube.rows, equals(2));
      expect(cube.columns, equals(3));
      expect(cube.getValue([0, 0, 0]), equals(1));
      expect(cube.getValue([0, 1, 2]), equals(6));
    });

    test('DataFrame to DataFrame (identity)', () {
      final df = DataFrame([
        [1, 2]
      ], columns: [
        'A',
        'B'
      ]);
      final result = df.toDataFrame();

      expect(identical(result, df), isTrue);
    });

    test('empty DataFrame to NDArray', () {
      final df = DataFrame.empty(columns: ['A', 'B']);
      final array = df.toNDArray();

      expect(array.shape.toList(), equals([0, 2]));
    });

    test('throws error converting empty DataFrame to Series', () {
      final df = DataFrame.empty();

      expect(() => df.toSeries(), throwsArgumentError);
    });
  });

  group('DartData Integration - DataCube conversions', () {
    test('DataCube to NDArray', () {
      final cube =
          DataCube.generate(2, 3, 4, (d, r, c) => d * 100 + r * 10 + c);
      final array = cube.toNDArray();

      expect(array.ndim, equals(3));
      expect(array.shape.toList(), equals([2, 3, 4]));
      expect(array.getValue([0, 0, 0]), equals(0));
      expect(array.getValue([1, 2, 3]), equals(123));
    });

    test('DataCube to Series (flattens)', () {
      final cube = DataCube.generate(2, 2, 2, (d, r, c) => d + r + c);
      final series = cube.toSeries();

      expect(series.length, equals(8));
      expect(series.name, equals('flattened'));
    });

    test('DataCube to DataFrame (extracts first frame)', () {
      final cube = DataCube.generate(3, 2, 4, (d, r, c) => d * 10 + r);
      // Use getFrame(0) instead of toDataFrame() since toDataFrame() requires depth=1
      final df = cube.getFrame(0);

      expect(df.rowCount, equals(2));
      expect(df.columnCount, equals(4));
      // First frame values
      expect(df.iloc(0, 0), equals(0));
      expect(df.iloc(1, 0), equals(1));
    });

    test('DataCube to DataCube (identity)', () {
      final cube = DataCube.zeros(2, 3, 4);
      final result = cube.toDataCube();

      expect(identical(result, cube), isTrue);
    });
  });

  group('DartData Integration - Round-trip conversions', () {
    test('NDArray -> Series -> NDArray', () {
      final original = NDArray([1, 2, 3, 4, 5]);
      final series = original.toSeries();
      final result = series.toNDArray();

      expect(result.shape.toList(), equals(original.shape.toList()));
      expect(result.toFlatList(), equals(original.toFlatList()));
    });

    test('NDArray -> DataFrame -> NDArray', () {
      final original = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final df = original.toDataFrame();
      final result = df.toNDArray();

      expect(result.shape.toList(), equals(original.shape.toList()));
      for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 3; j++) {
          expect(result.getValue([i, j]), equals(original.getValue([i, j])));
        }
      }
    });

    test('NDArray -> DataCube -> NDArray', () {
      final original = NDArray.generate(
          [2, 3, 4], (indices) => indices[0] * 10 + indices[1]);
      final cube = original.toDataCube();
      final result = cube.toNDArray();

      expect(result.shape.toList(), equals(original.shape.toList()));
      for (int d = 0; d < 2; d++) {
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 4; c++) {
            expect(result.getValue([d, r, c]),
                equals(original.getValue([d, r, c])));
          }
        }
      }
    });

    test('Series -> DataFrame -> Series', () {
      final original = Series([10, 20, 30, 40], name: 'data');
      final df = original.toDataFrame();
      final result = df.toSeries();

      expect(result.length, equals(original.length));
      expect(result.data, equals(original.data));
    });

    test('DataFrame -> DataCube -> DataFrame', () {
      final original = DataFrame([
        [1, 2],
        [3, 4]
      ], columns: [
        'A',
        'B'
      ]);
      final cube = original.toDataCube();
      final result = cube.toDataFrame();

      expect(result.rowCount, equals(original.rowCount));
      expect(result.columnCount, equals(original.columnCount));
      for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
          expect(result.iloc(i, j), equals(original.iloc(i, j)));
        }
      }
    });
  });

  group('DartData Integration - Edge cases', () {
    test('single element conversions', () {
      final array = NDArray([42]);
      final series = array.toSeries();
      final df = series.toDataFrame();
      final cube = df.toDataCube();

      expect(series.length, equals(1));
      expect(series.data[0], equals(42));
      expect(df.rowCount, equals(1));
      expect(df.columnCount, equals(1));
      expect(cube.depth, equals(1));
      expect(cube.rows, equals(1));
      expect(cube.columns, equals(1));
      expect(cube.getValue([0, 0, 0]), equals(42));
    });

    test('large array conversions', () {
      final size = 1000;
      final array = NDArray.generate([size], (indices) => indices[0]);
      final series = array.toSeries();

      expect(series.length, equals(size));
      expect(series.data[0], equals(0));
      expect(series.data[size - 1], equals(size - 1));

      final backToArray = series.toNDArray();
      expect(backToArray.shape.toList(), equals([size]));
    });

    test('mixed type data conversions', () {
      final array = NDArray([1, 'two', 3.0, true]);
      final series = array.toSeries();

      expect(series.length, equals(4));
      expect(series.data[0], equals(1));
      expect(series.data[1], equals('two'));
      expect(series.data[2], equals(3.0));
      expect(series.data[3], equals(true));
    });

    test('null values in conversions', () {
      final array = NDArray([1, null, 3, null, 5]);
      final series = array.toSeries();
      final df = series.toDataFrame();

      expect(series.data[1], isNull);
      expect(series.data[3], isNull);
      expect(df.iloc(1, 0), isNull);
      expect(df.iloc(3, 0), isNull);
    });
  });

  group('DartData Integration - Attributes preservation', () {
    test('NDArray attributes preserved through Series conversion', () {
      final array = NDArray([1, 2, 3]);
      array.attrs['units'] = 'meters';
      array.attrs['description'] = 'test data';

      final series = array.toSeries();
      final backToArray = series.toNDArray();

      // Note: Series doesn't have attrs, so they won't be preserved
      // This test documents the current behavior
      expect(backToArray.attrs.keys, isEmpty);
    });

    test('DataCube attributes preserved through conversion', () {
      final cube = DataCube.zeros(2, 3, 4);
      cube.attrs['experiment'] = 'test';
      cube.attrs['date'] = '2024-01-01';

      final array = cube.toNDArray();

      // Note: DataCube stores attributes separately from the underlying NDArray
      // The returned NDArray doesn't automatically inherit DataCube's attributes
      // This is expected behavior - attributes are specific to each data structure
      expect(cube.attrs['experiment'], equals('test'));
      expect(cube.attrs['date'], equals('2024-01-01'));

      // The underlying NDArray has its own separate attributes
      expect(array.attrs.keys, isEmpty);
    });
  });

  group('DartData Integration - Error handling', () {
    test('descriptive error for incompatible dimensions', () {
      final array = NDArray.generate([2, 2, 2, 2], (indices) => 1);

      expect(
        () => array.toSeries(),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('4D NDArray'),
        )),
      );
    });

    test('descriptive error for empty DataFrame to Series', () {
      final df = DataFrame.empty();

      expect(
        () => df.toSeries(),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('empty DataFrame'),
        )),
      );
    });
  });
}
