import 'package:test/test.dart';
import 'package:dartframe/src/datacube/datacube.dart';
import 'package:dartframe/src/datacube/transformations.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';

void main() {
  group('DataCube Transpose', () {
    test('transpose default (rows and columns)', () {
      final cube =
          DataCube.generate(2, 3, 4, (d, r, c) => d * 100 + r * 10 + c);

      final transposed = cube.transpose();

      expect(transposed.depth, 2);
      expect(transposed.rows, 4);
      expect(transposed.columns, 3);
      expect(transposed.getValue([0, 0, 0]), 0);
      expect(transposed.getValue([0, 2, 1]), 12);
    });

    test('transpose depth and rows', () {
      final cube = DataCube.zeros(2, 3, 4);

      final transposed = cube.transpose(axis1: 0, axis2: 1);

      expect(transposed.depth, 3);
      expect(transposed.rows, 2);
      expect(transposed.columns, 4);
    });

    test('transpose same axis returns copy', () {
      final cube = DataCube.zeros(2, 3, 4);

      final transposed = cube.transpose(axis1: 1, axis2: 1);

      expect(transposed.shape.toList(), cube.shape.toList());
    });
  });

  group('DataCube Permute', () {
    test('permute axes', () {
      final cube = DataCube.zeros(2, 3, 4);

      final permuted = cube.permute([2, 0, 1]);

      expect(permuted.depth, 4);
      expect(permuted.rows, 2);
      expect(permuted.columns, 3);
    });

    test('permute invalid axes throws', () {
      final cube = DataCube.zeros(2, 3, 4);

      expect(() => cube.permute([0, 1]), throwsArgumentError);
      expect(() => cube.permute([0, 0, 1]), throwsArgumentError);
    });
  });

  group('DataCube Reshape', () {
    test('reshape to valid dimensions', () {
      final cube = DataCube.zeros(2, 3, 4); // Size = 24

      final reshaped = cube.reshapeCube(3, 2, 4); // Size = 24

      expect(reshaped.depth, 3);
      expect(reshaped.rows, 2);
      expect(reshaped.columns, 4);
    });

    test('reshape invalid size throws', () {
      final cube = DataCube.zeros(2, 3, 4);

      expect(() => cube.reshapeCube(2, 2, 2), throwsArgumentError);
    });
  });

  group('DataCube Squeeze', () {
    test('squeeze removes size-1 dimensions', () {
      final cube = DataCube.zeros(1, 4, 5);

      final squeezed = cube.squeeze();

      expect(squeezed, isA<NDArray>());
      final arr = squeezed as NDArray;
      expect(arr.shape.toList(), [4, 5]);
    });

    test('squeeze no size-1 dimensions returns same', () {
      final cube = DataCube.zeros(2, 3, 4);

      final squeezed = cube.squeeze();

      expect(squeezed, isA<DataCube>());
    });
  });

  group('DataCube Expand Dims', () {
    test('expand dims at axis 0', () {
      final cube = DataCube.zeros(2, 3, 4);

      final expanded = cube.expandDims(axis: 0);

      expect(expanded.shape.toList(), [1, 2, 3, 4]);
    });

    test('expand dims at axis 3', () {
      final cube = DataCube.zeros(2, 3, 4);

      final expanded = cube.expandDims(axis: 3);

      expect(expanded.shape.toList(), [2, 3, 4, 1]);
    });
  });

  group('DataCube Swap Operations', () {
    test('swapDepthRows', () {
      final cube = DataCube.zeros(2, 3, 4);

      final swapped = cube.swapDepthRows();

      expect(swapped.depth, 3);
      expect(swapped.rows, 2);
      expect(swapped.columns, 4);
    });

    test('swapDepthCols', () {
      final cube = DataCube.zeros(2, 3, 4);

      final swapped = cube.swapDepthCols();

      expect(swapped.depth, 4);
      expect(swapped.rows, 3);
      expect(swapped.columns, 2);
    });

    test('swapRowsCols', () {
      final cube = DataCube.zeros(2, 3, 4);

      final swapped = cube.swapRowsCols();

      expect(swapped.depth, 2);
      expect(swapped.rows, 4);
      expect(swapped.columns, 3);
    });
  });

  group('DataCube Flatten', () {
    test('flatten to 1D', () {
      final cube = DataCube.zeros(2, 3, 4);

      final flat = cube.flatten();

      expect(flat.ndim, 1);
      expect(flat.size, 24);
    });
  });

  group('DataCube Repeat and Tile', () {
    test('repeatDepth', () {
      final cube = DataCube.zeros(2, 3, 4);

      final repeated = cube.repeatDepth(3);

      expect(repeated.depth, 6);
      expect(repeated.rows, 3);
      expect(repeated.columns, 4);
    });

    test('tile', () {
      final cube = DataCube.zeros(2, 3, 4);

      final tiled = cube.tile(depthReps: 2, rowReps: 1, colReps: 3);

      expect(tiled.depth, 4);
      expect(tiled.rows, 3);
      expect(tiled.columns, 12);
    });
  });

  group('DataCube Reverse and Roll', () {
    test('reverse depth', () {
      final cube = DataCube.generate(3, 2, 2, (d, r, c) => d);

      final reversed = cube.reverse(axis: 0);

      expect(reversed.getValue([0, 0, 0]), 2);
      expect(reversed.getValue([2, 0, 0]), 0);
    });

    test('roll depth', () {
      final cube = DataCube.generate(3, 2, 2, (d, r, c) => d);

      final rolled = cube.roll(shift: 1, axis: 0);

      expect(rolled.getValue([0, 0, 0]), 2);
      expect(rolled.getValue([1, 0, 0]), 0);
    });

    test('roll with zero shift returns copy', () {
      final cube = DataCube.zeros(2, 3, 4);

      final rolled = cube.roll(shift: 0, axis: 0);

      expect(rolled.shape.toList(), cube.shape.toList());
    });
  });
}
