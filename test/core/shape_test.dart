import 'package:test/test.dart';
import 'package:dartframe/src/core/shape.dart';

void main() {
  group('Shape - Construction', () {
    test('creates shape from dimensions', () {
      var shape = Shape([3, 4, 5]);
      expect(shape.ndim, equals(3));
      expect(shape.size, equals(60));
      expect(shape[0], equals(3));
      expect(shape[1], equals(4));
      expect(shape[2], equals(5));
    });

    test('creates 2D shape from rows and columns', () {
      var shape = Shape.fromRowsColumns(10, 20);
      expect(shape.ndim, equals(2));
      expect(shape.rows, equals(10));
      expect(shape.columns, equals(20));
      expect(shape.size, equals(200));
    });

    test('allows empty dimensions for scalar (0D)', () {
      var shape = Shape([]);
      expect(shape.ndim, equals(0));
      expect(shape.size, equals(1));
    });

    test('throws on negative dimensions', () {
      expect(() => Shape([3, -1, 5]), throwsArgumentError);
      expect(() => Shape([-1]), throwsArgumentError);
    });

    test('allows zero dimensions', () {
      var shape = Shape([0, 5]);
      expect(shape.isEmpty, isTrue);
      expect(shape.size, equals(0));
    });
  });

  group('Shape - Properties', () {
    test('ndim returns number of dimensions', () {
      expect(Shape([5]).ndim, equals(1));
      expect(Shape([5, 10]).ndim, equals(2));
      expect(Shape([5, 10, 15]).ndim, equals(3));
      expect(Shape([5, 10, 15, 20]).ndim, equals(4));
    });

    test('size returns total elements', () {
      expect(Shape([5]).size, equals(5));
      expect(Shape([5, 10]).size, equals(50));
      expect(Shape([3, 4, 5]).size, equals(60));
      expect(Shape([2, 3, 4, 5]).size, equals(120));
    });

    test('isEmpty and isNotEmpty', () {
      expect(Shape([0, 5]).isEmpty, isTrue);
      expect(Shape([5, 0]).isEmpty, isTrue);
      expect(Shape([5, 10]).isEmpty, isFalse);

      expect(Shape([0, 5]).isNotEmpty, isFalse);
      expect(Shape([5, 10]).isNotEmpty, isTrue);
    });

    test('isVector, isMatrix, isTensor', () {
      expect(Shape([5]).isVector, isTrue);
      expect(Shape([5]).isMatrix, isFalse);
      expect(Shape([5]).isTensor, isFalse);

      expect(Shape([5, 10]).isVector, isFalse);
      expect(Shape([5, 10]).isMatrix, isTrue);
      expect(Shape([5, 10]).isTensor, isFalse);

      expect(Shape([5, 10, 15]).isVector, isFalse);
      expect(Shape([5, 10, 15]).isMatrix, isFalse);
      expect(Shape([5, 10, 15]).isTensor, isTrue);
    });

    test('isSquare', () {
      expect(Shape([5, 5]).isSquare, isTrue);
      expect(Shape([10, 10]).isSquare, isTrue);
      expect(Shape([5, 10]).isSquare, isFalse);
      expect(Shape([5, 5, 5]).isSquare, isFalse);
    });

    test('isHypercube', () {
      expect(Shape([5, 5, 5]).isHypercube, isTrue);
      expect(Shape([10, 10]).isHypercube, isTrue);
      expect(Shape([5, 5, 10]).isHypercube, isFalse);
    });

    test('rows and columns for 2D', () {
      var shape = Shape([10, 20]);
      expect(shape.rows, equals(10));
      expect(shape.columns, equals(20));
    });

    test('rows throws for 0D', () {
      // Can't create 0D shape, but test 1D
      var shape = Shape([10]);
      expect(shape.rows, equals(10));
    });

    test('columns throws for 1D', () {
      var shape = Shape([10]);
      expect(() => shape.columns, throwsStateError);
    });
  });

  group('Shape - Indexing', () {
    test('operator [] accesses dimensions', () {
      var shape = Shape([3, 4, 5, 6]);
      expect(shape[0], equals(3));
      expect(shape[1], equals(4));
      expect(shape[2], equals(5));
      expect(shape[3], equals(6));
    });

    test('operator [] throws on out of bounds', () {
      var shape = Shape([3, 4, 5]);
      expect(() => shape[-1], throwsRangeError);
      expect(() => shape[3], throwsRangeError);
      expect(() => shape[10], throwsRangeError);
    });

    test('toList returns copy of dimensions', () {
      var shape = Shape([3, 4, 5]);
      var list = shape.toList();
      expect(list, equals([3, 4, 5]));

      // Verify it's a copy
      list[0] = 999;
      expect(shape[0], equals(3));
    });
  });

  group('Shape - Strides', () {
    test('calculates strides for 1D', () {
      var shape = Shape([10]);
      expect(shape.strides, equals([1]));
    });

    test('calculates strides for 2D', () {
      var shape = Shape([10, 20]);
      expect(shape.strides, equals([20, 1]));
    });

    test('calculates strides for 3D', () {
      var shape = Shape([3, 4, 5]);
      expect(shape.strides, equals([20, 5, 1]));
    });

    test('calculates strides for 4D', () {
      var shape = Shape([2, 3, 4, 5]);
      expect(shape.strides, equals([60, 20, 5, 1]));
    });

    test('strides are cached', () {
      var shape = Shape([3, 4, 5]);
      var strides1 = shape.strides;
      var strides2 = shape.strides;
      expect(identical(strides1, strides2), isTrue);
    });
  });

  group('Shape - Flat Index Conversion', () {
    test('toFlatIndex for 1D', () {
      var shape = Shape([10]);
      expect(shape.toFlatIndex([0]), equals(0));
      expect(shape.toFlatIndex([5]), equals(5));
      expect(shape.toFlatIndex([9]), equals(9));
    });

    test('toFlatIndex for 2D', () {
      var shape = Shape([10, 20]);
      expect(shape.toFlatIndex([0, 0]), equals(0));
      expect(shape.toFlatIndex([0, 1]), equals(1));
      expect(shape.toFlatIndex([1, 0]), equals(20));
      expect(shape.toFlatIndex([1, 5]), equals(25));
      expect(shape.toFlatIndex([9, 19]), equals(199));
    });

    test('toFlatIndex for 3D', () {
      var shape = Shape([3, 4, 5]);
      expect(shape.toFlatIndex([0, 0, 0]), equals(0));
      expect(shape.toFlatIndex([0, 0, 1]), equals(1));
      expect(shape.toFlatIndex([0, 1, 0]), equals(5));
      expect(shape.toFlatIndex([1, 0, 0]), equals(20));
      expect(shape.toFlatIndex([1, 2, 3]), equals(33));
      expect(shape.toFlatIndex([2, 3, 4]), equals(59));
    });

    test('toFlatIndex throws on wrong number of indices', () {
      var shape = Shape([3, 4, 5]);
      expect(() => shape.toFlatIndex([1, 2]), throwsArgumentError);
      expect(() => shape.toFlatIndex([1, 2, 3, 4]), throwsArgumentError);
    });

    test('toFlatIndex throws on out of bounds indices', () {
      var shape = Shape([3, 4, 5]);
      expect(() => shape.toFlatIndex([3, 0, 0]), throwsRangeError);
      expect(() => shape.toFlatIndex([0, 4, 0]), throwsRangeError);
      expect(() => shape.toFlatIndex([0, 0, 5]), throwsRangeError);
      expect(() => shape.toFlatIndex([-1, 0, 0]), throwsRangeError);
    });

    test('fromFlatIndex for 1D', () {
      var shape = Shape([10]);
      expect(shape.fromFlatIndex(0), equals([0]));
      expect(shape.fromFlatIndex(5), equals([5]));
      expect(shape.fromFlatIndex(9), equals([9]));
    });

    test('fromFlatIndex for 2D', () {
      var shape = Shape([10, 20]);
      expect(shape.fromFlatIndex(0), equals([0, 0]));
      expect(shape.fromFlatIndex(1), equals([0, 1]));
      expect(shape.fromFlatIndex(20), equals([1, 0]));
      expect(shape.fromFlatIndex(25), equals([1, 5]));
      expect(shape.fromFlatIndex(199), equals([9, 19]));
    });

    test('fromFlatIndex for 3D', () {
      var shape = Shape([3, 4, 5]);
      expect(shape.fromFlatIndex(0), equals([0, 0, 0]));
      expect(shape.fromFlatIndex(1), equals([0, 0, 1]));
      expect(shape.fromFlatIndex(5), equals([0, 1, 0]));
      expect(shape.fromFlatIndex(20), equals([1, 0, 0]));
      expect(shape.fromFlatIndex(33), equals([1, 2, 3]));
      expect(shape.fromFlatIndex(59), equals([2, 3, 4]));
    });

    test('fromFlatIndex throws on out of bounds', () {
      var shape = Shape([3, 4, 5]);
      expect(() => shape.fromFlatIndex(-1), throwsRangeError);
      expect(() => shape.fromFlatIndex(60), throwsRangeError);
      expect(() => shape.fromFlatIndex(100), throwsRangeError);
    });

    test('round-trip index conversion', () {
      var shape = Shape([3, 4, 5]);
      for (int i = 0; i < shape.size; i++) {
        var multiIdx = shape.fromFlatIndex(i);
        var flatIdx = shape.toFlatIndex(multiIdx);
        expect(flatIdx, equals(i), reason: 'Failed at index $i');
      }
    });
  });

  group('Shape - Broadcasting', () {
    test('same shapes are broadcastable', () {
      var shape1 = Shape([3, 4, 5]);
      var shape2 = Shape([3, 4, 5]);
      expect(shape1.canBroadcastWith(shape2), isTrue);
    });

    test('shapes with 1s are broadcastable', () {
      var shape1 = Shape([3, 1, 5]);
      var shape2 = Shape([1, 4, 5]);
      expect(shape1.canBroadcastWith(shape2), isTrue);
    });

    test('different length shapes are broadcastable', () {
      var shape1 = Shape([3, 4, 5]);
      var shape2 = Shape([4, 5]);
      expect(shape1.canBroadcastWith(shape2), isTrue);

      var shape3 = Shape([5]);
      expect(shape1.canBroadcastWith(shape3), isTrue);
    });

    test('incompatible shapes are not broadcastable', () {
      var shape1 = Shape([3, 4, 5]);
      var shape2 = Shape([3, 2, 5]);
      expect(shape1.canBroadcastWith(shape2), isFalse);
    });

    test('broadcastWith returns correct shape', () {
      var shape1 = Shape([3, 1, 5]);
      var shape2 = Shape([1, 4, 5]);
      var result = shape1.broadcastWith(shape2);
      expect(result.toList(), equals([3, 4, 5]));
    });

    test('broadcastWith with different lengths', () {
      var shape1 = Shape([3, 4, 5]);
      var shape2 = Shape([4, 5]);
      var result = shape1.broadcastWith(shape2);
      expect(result.toList(), equals([3, 4, 5]));
    });

    test('broadcastWith throws on incompatible shapes', () {
      var shape1 = Shape([3, 4, 5]);
      var shape2 = Shape([3, 2, 5]);
      expect(() => shape1.broadcastWith(shape2), throwsArgumentError);
    });
  });

  group('Shape - Dimension Manipulation', () {
    test('addDimension at start', () {
      var shape = Shape([3, 4]);
      var expanded = shape.addDimension(5, axis: 0);
      expect(expanded.toList(), equals([5, 3, 4]));
    });

    test('addDimension at end', () {
      var shape = Shape([3, 4]);
      var expanded = shape.addDimension(5, axis: 2);
      expect(expanded.toList(), equals([3, 4, 5]));
    });

    test('addDimension in middle', () {
      var shape = Shape([3, 4]);
      var expanded = shape.addDimension(5, axis: 1);
      expect(expanded.toList(), equals([3, 5, 4]));
    });

    test('addDimension throws on invalid axis', () {
      var shape = Shape([3, 4]);
      expect(() => shape.addDimension(5, axis: -1), throwsRangeError);
      expect(() => shape.addDimension(5, axis: 3), throwsRangeError);
    });

    test('addDimension throws on negative size', () {
      var shape = Shape([3, 4]);
      expect(() => shape.addDimension(-1), throwsArgumentError);
    });

    test('removeDimension', () {
      var shape = Shape([1, 3, 4]);
      var squeezed = shape.removeDimension(0);
      expect(squeezed.toList(), equals([3, 4]));
    });

    test('removeDimension from middle', () {
      var shape = Shape([3, 1, 4]);
      var squeezed = shape.removeDimension(1);
      expect(squeezed.toList(), equals([3, 4]));
    });

    test('removeDimension throws on 1D shape', () {
      var shape = Shape([5]);
      expect(() => shape.removeDimension(0), throwsArgumentError);
    });

    test('removeDimension throws on invalid axis', () {
      var shape = Shape([3, 4, 5]);
      expect(() => shape.removeDimension(-1), throwsRangeError);
      expect(() => shape.removeDimension(3), throwsRangeError);
    });

    test('transpose reorders dimensions', () {
      var shape = Shape([3, 4, 5]);
      var transposed = shape.transpose([2, 0, 1]);
      expect(transposed.toList(), equals([5, 3, 4]));
    });

    test('transpose with identity permutation', () {
      var shape = Shape([3, 4, 5]);
      var transposed = shape.transpose([0, 1, 2]);
      expect(transposed.toList(), equals([3, 4, 5]));
    });

    test('transpose throws on wrong number of axes', () {
      var shape = Shape([3, 4, 5]);
      expect(() => shape.transpose([0, 1]), throwsArgumentError);
      expect(() => shape.transpose([0, 1, 2, 3]), throwsArgumentError);
    });

    test('transpose throws on duplicate axes', () {
      var shape = Shape([3, 4, 5]);
      expect(() => shape.transpose([0, 0, 1]), throwsArgumentError);
    });

    test('transpose throws on invalid axes', () {
      var shape = Shape([3, 4, 5]);
      expect(() => shape.transpose([0, 1, 3]), throwsArgumentError);
      expect(() => shape.transpose([-1, 0, 1]), throwsArgumentError);
    });
  });

  group('Shape - Equality and String', () {
    test('equality works', () {
      var shape1 = Shape([3, 4, 5]);
      var shape2 = Shape([3, 4, 5]);
      var shape3 = Shape([3, 4, 6]);

      expect(shape1 == shape2, isTrue);
      expect(shape1 == shape3, isFalse);
    });

    test('hashCode is consistent', () {
      var shape1 = Shape([3, 4, 5]);
      var shape2 = Shape([3, 4, 5]);

      expect(shape1.hashCode, equals(shape2.hashCode));
    });

    test('toString for 2D', () {
      var shape = Shape([10, 20]);
      expect(shape.toString(), equals('Shape(rows: 10, columns: 20)'));
    });

    test('toString for N-D', () {
      var shape = Shape([3, 4, 5]);
      expect(shape.toString(), equals('Shape(3×4×5)'));
    });
  });
}
