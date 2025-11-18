import 'package:test/test.dart';
import 'package:dartframe/src/datacube/datacube.dart';
import 'package:dartframe/src/data_frame/data_frame.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';
import 'package:dartframe/src/core/slice_spec.dart';
import 'package:dartframe/src/core/scalar.dart';

void main() {
  group('DataCube Construction', () {
    test('from DataFrames', () {
      final df1 = DataFrame([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final df2 = DataFrame([
        [7, 8, 9],
        [10, 11, 12]
      ]);

      final cube = DataCube.fromDataFrames([df1, df2]);

      expect(cube.depth, 2);
      expect(cube.rows, 2);
      expect(cube.columns, 3);
      expect(cube.getValue([0, 0, 0]), 1);
      expect(cube.getValue([1, 1, 2]), 12);
    });

    test('from DataFrames - mismatched shapes throws', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6, 7]
      ]);

      expect(
        () => DataCube.fromDataFrames([df1, df2]),
        throwsArgumentError,
      );
    });

    test('from DataFrames - empty list throws', () {
      expect(
        () => DataCube.fromDataFrames([]),
        throwsArgumentError,
      );
    });

    test('from NDArray', () {
      final array = NDArray([
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ]
      ]);

      final cube = DataCube.fromNDArray(array);

      expect(cube.depth, 2);
      expect(cube.rows, 2);
      expect(cube.columns, 2);
      expect(cube.getValue([0, 0, 0]), 1);
      expect(cube.getValue([1, 1, 1]), 8);
    });

    test('from NDArray - non-3D throws', () {
      final array = NDArray([
        [1, 2],
        [3, 4]
      ]);

      expect(
        () => DataCube.fromNDArray(array),
        throwsArgumentError,
      );
    });

    test('empty', () {
      final cube = DataCube.empty(3, 4, 5);

      expect(cube.depth, 3);
      expect(cube.rows, 4);
      expect(cube.columns, 5);
      expect(cube.getValue([0, 0, 0]), 0);
    });

    test('empty with fill value', () {
      final cube = DataCube.empty(2, 3, 4, fillValue: 42);

      expect(cube.getValue([0, 0, 0]), 42);
      expect(cube.getValue([1, 2, 3]), 42);
    });

    test('zeros', () {
      final cube = DataCube.zeros(2, 3, 4);

      expect(cube.getValue([0, 0, 0]), 0);
      expect(cube.getValue([1, 2, 3]), 0);
    });

    test('ones', () {
      final cube = DataCube.ones(2, 3, 4);

      expect(cube.getValue([0, 0, 0]), 1);
      expect(cube.getValue([1, 2, 3]), 1);
    });

    test('generate', () {
      final cube = DataCube.generate(2, 3, 4, (d, r, c) {
        return d * 100 + r * 10 + c;
      });

      expect(cube.getValue([0, 0, 0]), 0);
      expect(cube.getValue([0, 2, 3]), 23);
      expect(cube.getValue([1, 1, 2]), 112);
    });
  });

  group('DataCube Properties', () {
    late DataCube cube;

    setUp(() {
      cube = DataCube.zeros(3, 4, 5);
    });

    test('shape', () {
      expect(cube.shape.toList(), [3, 4, 5]);
    });

    test('ndim', () {
      expect(cube.ndim, 3);
    });

    test('size', () {
      expect(cube.size, 60);
    });

    test('depth', () {
      expect(cube.depth, 3);
    });

    test('rows', () {
      expect(cube.rows, 4);
    });

    test('columns', () {
      expect(cube.columns, 5);
    });
  });

  group('DataCube Access', () {
    late DataCube cube;

    setUp(() {
      cube = DataCube.generate(2, 3, 4, (d, r, c) {
        return d * 100 + r * 10 + c;
      });
    });

    test('getValue', () {
      expect(cube.getValue([0, 0, 0]), 0);
      expect(cube.getValue([0, 2, 3]), 23);
      expect(cube.getValue([1, 1, 2]), 112);
    });

    test('setValue', () {
      cube.setValue([0, 0, 0], 999);
      expect(cube.getValue([0, 0, 0]), 999);

      cube.setValue([1, 2, 3], 888);
      expect(cube.getValue([1, 2, 3]), 888);
    });

    test('getValue with wrong indices throws', () {
      expect(() => cube.getValue([0, 0]), throwsArgumentError);
      expect(() => cube.getValue([0, 0, 0, 0]), throwsArgumentError);
    });
  });

  group('DataFrame Operations', () {
    late DataCube cube;

    setUp(() {
      final df1 = DataFrame([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final df2 = DataFrame([
        [7, 8, 9],
        [10, 11, 12]
      ]);
      cube = DataCube.fromDataFrames([df1, df2]);
    });

    test('getFrame', () {
      final frame0 = cube.getFrame(0);
      expect(frame0.iloc(0, 0), 1);
      expect(frame0.iloc(1, 2), 6);

      final frame1 = cube.getFrame(1);
      expect(frame1.iloc(0, 0), 7);
      expect(frame1.iloc(1, 2), 12);
    });

    test('getFrame with [] operator', () {
      final frame = cube[0];
      expect(frame.iloc(0, 0), 1);
      expect(frame.iloc(1, 2), 6);
    });

    test('getFrame out of range throws', () {
      expect(() => cube.getFrame(5), throwsRangeError);
      expect(() => cube.getFrame(-1), throwsRangeError);
    });

    test('setFrame', () {
      final newFrame = DataFrame([
        [99, 98, 97],
        [96, 95, 94]
      ]);

      cube.setFrame(0, newFrame);

      expect(cube.getValue([0, 0, 0]), 99);
      expect(cube.getValue([0, 1, 2]), 94);
    });

    test('setFrame with []= operator', () {
      final newFrame = DataFrame([
        [99, 98, 97],
        [96, 95, 94]
      ]);

      cube[1] = newFrame;

      expect(cube.getValue([1, 0, 0]), 99);
      expect(cube.getValue([1, 1, 2]), 94);
    });

    test('setFrame with wrong shape throws', () {
      final wrongFrame = DataFrame([
        [1, 2]
      ]);

      expect(() => cube.setFrame(0, wrongFrame), throwsArgumentError);
    });

    test('toDataFrames', () {
      final frames = cube.toDataFrames();

      expect(frames.length, 2);
      expect(frames[0].iloc(0, 0), 1);
      expect(frames[1].iloc(1, 2), 12);
    });

    test('frames iterable', () {
      final frameList = cube.frames.toList();

      expect(frameList.length, 2);
      expect(frameList[0].iloc(0, 0), 1);
      expect(frameList[1].iloc(1, 2), 12);
    });

    test('streamFrames', () async {
      final frames = <DataFrame>[];
      await for (var frame in cube.streamFrames()) {
        frames.add(frame);
      }

      expect(frames.length, 2);
      expect(frames[0].iloc(0, 0), 1);
      expect(frames[1].iloc(1, 2), 12);
    });
  });

  group('DataCube Slicing', () {
    late DataCube cube;

    setUp(() {
      cube = DataCube.generate(3, 4, 5, (d, r, c) {
        return d * 100 + r * 10 + c;
      });
    });

    test('slice to scalar', () {
      final result = cube.slice([0, 0, 0]);
      expect(result, isA<Scalar>());
      expect((result as Scalar).value, 0);
    });

    test('slice to 2D NDArray', () {
      final result = cube.slice([0, Slice.all(), Slice.all()]);
      expect(result, isA<NDArray>());
      final arr = result as NDArray;
      expect(arr.shape.toList(), [4, 5]);
      expect(arr.getValue([0, 0]), 0);
      expect(arr.getValue([3, 4]), 34);
    });

    test('slice to DataCube', () {
      final result = cube.slice([Slice.range(0, 2), Slice.all(), Slice.all()]);
      expect(result, isA<DataCube>());
      final subCube = result as DataCube;
      expect(subCube.depth, 2);
      expect(subCube.rows, 4);
      expect(subCube.columns, 5);
    });

    test('slice with partial specs', () {
      final result = cube.slice([0]);
      expect(result, isA<NDArray>());
      final arr = result as NDArray;
      expect(arr.ndim, 2);
    });
  });

  group('DataCube Copy', () {
    test('copy creates independent instance', () {
      final cube = DataCube.zeros(2, 3, 4);
      cube.setValue([0, 0, 0], 42);

      final copied = cube.copy();

      expect(copied.getValue([0, 0, 0]), 42);

      // Modify original
      cube.setValue([0, 0, 0], 99);

      // Copy should be unchanged
      expect(copied.getValue([0, 0, 0]), 42);
    });

    test('copy preserves attributes', () {
      final cube = DataCube.zeros(2, 3, 4);
      cube.attrs['name'] = 'test';

      final copied = cube.copy();

      expect(copied.attrs['name'], 'test');

      // Modify original
      cube.attrs['name'] = 'changed';

      // Copy should be unchanged
      expect(copied.attrs['name'], 'test');
    });
  });

  group('DataCube String Representation', () {
    test('toString', () {
      final cube = DataCube.zeros(2, 3, 4);
      expect(cube.toString(), 'DataCube(depth: 2, rows: 3, columns: 4)');
    });

    test('summary', () {
      final cube = DataCube.zeros(2, 2, 2);
      final summary = cube.summary();

      expect(summary, contains('DataCube Summary'));
      expect(summary, contains('Shape: [2, 2, 2]'));
      expect(summary, contains('Total elements: 8'));
      expect(summary, contains('Number of frames: 2'));
    });
  });

  group('DataCube Attributes', () {
    test('attributes are accessible', () {
      final cube = DataCube.zeros(2, 3, 4);
      cube.attrs['name'] = 'test';
      cube.attrs['version'] = 1;

      expect(cube.attrs['name'], 'test');
      expect(cube.attrs['version'], 1);
    });
  });

  group('DataCube Data Access', () {
    test('underlying NDArray is accessible', () {
      final cube = DataCube.zeros(2, 3, 4);
      final data = cube.data;

      expect(data, isA<NDArray>());
      expect(data.shape.toList(), [2, 3, 4]);
    });
  });
}
