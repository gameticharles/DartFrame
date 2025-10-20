import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Shape Class Tests', () {
    group('2D Shape (DataFrame compatibility)', () {
      test('creates 2D shape with fromRowsColumns constructor', () {
        var shape = Shape.fromRowsColumns(10, 5);
        expect(shape.rows, equals(10));
        expect(shape.columns, equals(5));
        expect(shape.ndim, equals(2));
        expect(shape.isMatrix, isTrue);
        expect(shape.isVector, isFalse);
        expect(shape.isTensor, isFalse);
      });

      test('supports indexed access for 2D shape', () {
        var shape = Shape.fromRowsColumns(10, 5);
        expect(shape[0], equals(10)); // rows
        expect(shape[1], equals(5));  // columns
      });

      test('DataFrame shape property works with new Shape class', () {
        var df = DataFrame([
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9]
        ], columns: ['A', 'B', 'C']);
        
        // Test backward compatibility
        expect(df.shape.rows, equals(3));
        expect(df.shape.columns, equals(3));
        
        // Test new indexed access
        expect(df.shape[0], equals(3)); // rows
        expect(df.shape[1], equals(3)); // columns
        
        // Test utility methods
        expect(df.shape.size, equals(9));
        expect(df.shape.isSquare, isTrue);
        expect(df.shape.isMatrix, isTrue);
        expect(df.shape.isEmpty, isFalse);
      });
    });

    group('Multi-dimensional Shape', () {
      test('creates 1D shape (vector)', () {
        var shape = Shape([100]);
        expect(shape[0], equals(100));
        expect(shape.ndim, equals(1));
        expect(shape.isVector, isTrue);
        expect(shape.isMatrix, isFalse);
        expect(shape.isTensor, isFalse);
        expect(shape.size, equals(100));
      });

      test('creates 3D shape (tensor)', () {
        var shape = Shape([10, 5, 3]);
        expect(shape[0], equals(10));
        expect(shape[1], equals(5));
        expect(shape[2], equals(3));
        expect(shape.ndim, equals(3));
        expect(shape.isVector, isFalse);
        expect(shape.isMatrix, isFalse);
        expect(shape.isTensor, isTrue);
        expect(shape.size, equals(150)); // 10 * 5 * 3
      });

      test('creates 4D shape', () {
        var shape = Shape([2, 3, 4, 5]);
        expect(shape.ndim, equals(4));
        expect(shape.size, equals(120)); // 2 * 3 * 4 * 5
        expect(shape.isTensor, isTrue);
      });

      test('supports hypercube detection', () {
        var cube3D = Shape([5, 5, 5]);
        var nonCube3D = Shape([5, 4, 5]);
        
        expect(cube3D.isHypercube, isTrue);
        expect(nonCube3D.isHypercube, isFalse);
      });
    });

    group('Shape operations', () {
      test('addDimension works correctly', () {
        var shape2D = Shape([10, 5]);
        
        // Add dimension at beginning
        var shape3D_start = shape2D.addDimension(3);
        expect(shape3D_start.toList(), equals([3, 10, 5]));
        
        // Add dimension at end
        var shape3D_end = shape2D.addDimension(3, axis: 2);
        expect(shape3D_end.toList(), equals([10, 5, 3]));
        
        // Add dimension in middle
        var shape3D_middle = shape2D.addDimension(3, axis: 1);
        expect(shape3D_middle.toList(), equals([10, 3, 5]));
      });

      test('removeDimension works correctly', () {
        var shape3D = Shape([10, 5, 3]);
        
        var shape2D_remove_first = shape3D.removeDimension(0);
        expect(shape2D_remove_first.toList(), equals([5, 3]));
        
        var shape2D_remove_last = shape3D.removeDimension(2);
        expect(shape2D_remove_last.toList(), equals([10, 5]));
      });

      test('transpose works correctly', () {
        var shape3D = Shape([10, 5, 3]);
        
        // Transpose to [3, 10, 5]
        var transposed = shape3D.transpose([2, 0, 1]);
        expect(transposed.toList(), equals([3, 10, 5]));
        
        // Reverse order
        var reversed = shape3D.transpose([2, 1, 0]);
        expect(reversed.toList(), equals([3, 5, 10]));
      });
    });

    group('Error handling', () {
      test('throws error for empty dimensions', () {
        expect(() => Shape([]), throwsArgumentError);
      });

      test('throws error for negative dimensions', () {
        expect(() => Shape([10, -5]), throwsArgumentError);
      });

      test('throws error for out of bounds access', () {
        var shape = Shape([10, 5]);
        expect(() => shape[2], throwsRangeError);
        expect(() => shape[-1], throwsRangeError);
      });

      test('throws error when accessing rows/columns on 1D shape', () {
        var shape1D = Shape([100]);
        expect(() => shape1D.columns, throwsStateError);
      });

      test('throws error when accessing columns on 1D shape', () {
        var shape1D = Shape([100]);
        expect(() => shape1D.columns, throwsStateError);
      });

      test('throws error for invalid transpose axes', () {
        var shape = Shape([10, 5, 3]);
        
        // Wrong number of axes
        expect(() => shape.transpose([0, 1]), throwsArgumentError);
        
        // Duplicate axes
        expect(() => shape.transpose([0, 0, 1]), throwsArgumentError);
        
        // Out of bounds axes
        expect(() => shape.transpose([0, 1, 3]), throwsArgumentError);
      });
    });

    group('Utility methods', () {
      test('toList returns correct dimensions', () {
        var shape = Shape([10, 5, 3]);
        expect(shape.toList(), equals([10, 5, 3]));
      });

      test('toString formats correctly', () {
        var shape2D = Shape.fromRowsColumns(10, 5);
        var shape3D = Shape([10, 5, 3]);
        
        expect(shape2D.toString(), equals('Shape(rows: 10, columns: 5)'));
        expect(shape3D.toString(), equals('Shape(10×5×3)'));
      });

      test('equality works correctly', () {
        var shape1 = Shape([10, 5, 3]);
        var shape2 = Shape([10, 5, 3]);
        var shape3 = Shape([10, 5, 4]);
        
        expect(shape1, equals(shape2));
        expect(shape1, isNot(equals(shape3)));
      });

      test('isEmpty and isNotEmpty work correctly', () {
        var emptyShape = Shape([10, 0, 5]);
        var nonEmptyShape = Shape([10, 5, 3]);
        
        expect(emptyShape.isEmpty, isTrue);
        expect(emptyShape.isNotEmpty, isFalse);
        expect(nonEmptyShape.isEmpty, isFalse);
        expect(nonEmptyShape.isNotEmpty, isTrue);
      });
    });
  });
}