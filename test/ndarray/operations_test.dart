import 'package:test/test.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';
import 'package:dartframe/src/ndarray/operations.dart';
import 'dart:math' as math;

void main() {
  group('Element-wise Arithmetic', () {
    test('addition with scalar', () {
      final arr = NDArray([1, 2, 3, 4]);
      final result = arr + 10;
      expect(result.getValue([0]), 11);
      expect(result.getValue([3]), 14);
    });

    test('addition with array', () {
      final a = NDArray([1, 2, 3]);
      final b = NDArray([10, 20, 30]);
      final result = a + b;
      expect(result.getValue([0]), 11);
      expect(result.getValue([2]), 33);
    });

    test('subtraction with scalar', () {
      final arr = NDArray([10, 20, 30]);
      final result = arr - 5;
      expect(result.getValue([0]), 5);
      expect(result.getValue([2]), 25);
    });

    test('subtraction with array', () {
      final a = NDArray([10, 20, 30]);
      final b = NDArray([1, 2, 3]);
      final result = a - b;
      expect(result.getValue([0]), 9);
      expect(result.getValue([2]), 27);
    });

    test('multiplication with scalar', () {
      final arr = NDArray([1, 2, 3]);
      final result = arr * 10;
      expect(result.getValue([0]), 10);
      expect(result.getValue([2]), 30);
    });

    test('multiplication with array', () {
      final a = NDArray([2, 3, 4]);
      final b = NDArray([10, 10, 10]);
      final result = a * b;
      expect(result.getValue([0]), 20);
      expect(result.getValue([2]), 40);
    });

    test('division with scalar', () {
      final arr = NDArray([10, 20, 30]);
      final result = arr / 10;
      expect(result.getValue([0]), 1);
      expect(result.getValue([2]), 3);
    });

    test('division with array', () {
      final a = NDArray([10, 20, 30]);
      final b = NDArray([2, 4, 5]);
      final result = a / b;
      expect(result.getValue([0]), 5);
      expect(result.getValue([1]), 5);
      expect(result.getValue([2]), 6);
    });

    test('negation', () {
      final arr = NDArray([1, -2, 3]);
      final result = -arr;
      expect(result.getValue([0]), -1);
      expect(result.getValue([1]), 2);
      expect(result.getValue([2]), -3);
    });

    test('power with scalar', () {
      final arr = NDArray([2, 3, 4]);
      final result = arr.pow(2);
      expect(result.getValue([0]), 4);
      expect(result.getValue([1]), 9);
      expect(result.getValue([2]), 16);
    });

    test('square root', () {
      final arr = NDArray([4, 9, 16]);
      final result = arr.sqrt();
      expect(result.getValue([0]), 2);
      expect(result.getValue([1]), 3);
      expect(result.getValue([2]), 4);
    });

    test('absolute value', () {
      final arr = NDArray([-1, 2, -3]);
      final result = arr.abs();
      expect(result.getValue([0]), 1);
      expect(result.getValue([1]), 2);
      expect(result.getValue([2]), 3);
    });

    test('exponential', () {
      final arr = NDArray([0, 1, 2]);
      final result = arr.exp();
      expect(result.getValue([0]), closeTo(1, 0.0001));
      expect(result.getValue([1]), closeTo(math.e, 0.0001));
      expect(result.getValue([2]), closeTo(math.e * math.e, 0.0001));
    });

    test('natural logarithm', () {
      final arr = NDArray([1, math.e, math.e * math.e]);
      final result = arr.log();
      expect(result.getValue([0]), closeTo(0, 0.0001));
      expect(result.getValue([1]), closeTo(1, 0.0001));
      expect(result.getValue([2]), closeTo(2, 0.0001));
    });
  });

  group('Comparison Operations', () {
    test('equality', () {
      final arr = NDArray([1, 2, 3]);
      final result = arr.eq(2);
      expect(result.getValue([0]), 0);
      expect(result.getValue([1]), 1);
      expect(result.getValue([2]), 0);
    });

    test('greater than', () {
      final arr = NDArray([1, 2, 3]);
      final result = arr.gt(2);
      expect(result.getValue([0]), 0);
      expect(result.getValue([1]), 0);
      expect(result.getValue([2]), 1);
    });

    test('less than', () {
      final arr = NDArray([1, 2, 3]);
      final result = arr.lt(2);
      expect(result.getValue([0]), 1);
      expect(result.getValue([1]), 0);
      expect(result.getValue([2]), 0);
    });

    test('greater than or equal', () {
      final arr = NDArray([1, 2, 3]);
      final result = arr.gte(2);
      expect(result.getValue([0]), 0);
      expect(result.getValue([1]), 1);
      expect(result.getValue([2]), 1);
    });

    test('less than or equal', () {
      final arr = NDArray([1, 2, 3]);
      final result = arr.lte(2);
      expect(result.getValue([0]), 1);
      expect(result.getValue([1]), 1);
      expect(result.getValue([2]), 0);
    });
  });

  group('Aggregation Operations', () {
    test('sum without axis', () {
      final arr = NDArray([1, 2, 3, 4]);
      expect(arr.sum(), 10);
    });

    test('sum 2D without axis', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      expect(arr.sum(), 21);
    });

    test('mean without axis', () {
      final arr = NDArray([1, 2, 3, 4]);
      expect(arr.mean(), 2.5);
    });

    test('mean 2D without axis', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      expect(arr.mean(), 3.5);
    });

    test('max without axis', () {
      final arr = NDArray([1, 5, 3, 2]);
      expect(arr.max(), 5);
    });

    test('min without axis', () {
      final arr = NDArray([1, 5, 3, 2]);
      expect(arr.min(), 1);
    });

    test('std without axis', () {
      final arr = NDArray([2, 4, 4, 4, 5, 5, 7, 9]);
      expect(arr.std(), closeTo(2.0, 0.1));
    });

    test('product', () {
      final arr = NDArray([2, 3, 4]);
      expect(arr.prod(), 24);
    });

    test('variance', () {
      final arr = NDArray([2, 4, 4, 4, 5, 5, 7, 9]);
      expect(arr.variance(), closeTo(4.0, 0.1));
    });
  });

  group('Axis-Aware Aggregations', () {
    group('sum with axis', () {
      test('sum along axis 0 (2D)', () {
        final arr = NDArray([
          [1, 2, 3],
          [4, 5, 6]
        ]);
        final result = arr.sum(axis: 0) as NDArray;
        expect(result.shape.toList(), [3]);
        expect(result.getValue([0]), 5);
        expect(result.getValue([1]), 7);
        expect(result.getValue([2]), 9);
      });

      test('sum along axis 1 (2D)', () {
        final arr = NDArray([
          [1, 2, 3],
          [4, 5, 6]
        ]);
        final result = arr.sum(axis: 1) as NDArray;
        expect(result.shape.toList(), [2]);
        expect(result.getValue([0]), 6);
        expect(result.getValue([1]), 15);
      });

      test('sum along axis 0 (3D)', () {
        final arr = NDArray([
          [
            [1, 2],
            [3, 4]
          ],
          [
            [5, 6],
            [7, 8]
          ]
        ]);
        final result = arr.sum(axis: 0) as NDArray;
        expect(result.shape.toList(), [2, 2]);
        expect(result.getValue([0, 0]), 6);
        expect(result.getValue([0, 1]), 8);
        expect(result.getValue([1, 0]), 10);
        expect(result.getValue([1, 1]), 12);
      });

      test('sum along axis 1 (3D)', () {
        final arr = NDArray([
          [
            [1, 2],
            [3, 4]
          ],
          [
            [5, 6],
            [7, 8]
          ]
        ]);
        final result = arr.sum(axis: 1) as NDArray;
        expect(result.shape.toList(), [2, 2]);
        expect(result.getValue([0, 0]), 4);
        expect(result.getValue([0, 1]), 6);
        expect(result.getValue([1, 0]), 12);
        expect(result.getValue([1, 1]), 14);
      });

      test('sum along axis 2 (3D)', () {
        final arr = NDArray([
          [
            [1, 2],
            [3, 4]
          ],
          [
            [5, 6],
            [7, 8]
          ]
        ]);
        final result = arr.sum(axis: 2) as NDArray;
        expect(result.shape.toList(), [2, 2]);
        expect(result.getValue([0, 0]), 3);
        expect(result.getValue([0, 1]), 7);
        expect(result.getValue([1, 0]), 11);
        expect(result.getValue([1, 1]), 15);
      });
    });

    group('mean with axis', () {
      test('mean along axis 0 (2D)', () {
        final arr = NDArray([
          [2, 4, 6],
          [8, 10, 12]
        ]);
        final result = arr.mean(axis: 0) as NDArray;
        expect(result.shape.toList(), [3]);
        expect(result.getValue([0]), 5);
        expect(result.getValue([1]), 7);
        expect(result.getValue([2]), 9);
      });

      test('mean along axis 1 (2D)', () {
        final arr = NDArray([
          [2, 4, 6],
          [8, 10, 12]
        ]);
        final result = arr.mean(axis: 1) as NDArray;
        expect(result.shape.toList(), [2]);
        expect(result.getValue([0]), 4);
        expect(result.getValue([1]), 10);
      });
    });

    group('max with axis', () {
      test('max along axis 0 (2D)', () {
        final arr = NDArray([
          [1, 5, 3],
          [4, 2, 6]
        ]);
        final result = arr.max(axis: 0) as NDArray;
        expect(result.shape.toList(), [3]);
        expect(result.getValue([0]), 4);
        expect(result.getValue([1]), 5);
        expect(result.getValue([2]), 6);
      });

      test('max along axis 1 (2D)', () {
        final arr = NDArray([
          [1, 5, 3],
          [4, 2, 6]
        ]);
        final result = arr.max(axis: 1) as NDArray;
        expect(result.shape.toList(), [2]);
        expect(result.getValue([0]), 5);
        expect(result.getValue([1]), 6);
      });
    });

    group('min with axis', () {
      test('min along axis 0 (2D)', () {
        final arr = NDArray([
          [1, 5, 3],
          [4, 2, 6]
        ]);
        final result = arr.min(axis: 0) as NDArray;
        expect(result.shape.toList(), [3]);
        expect(result.getValue([0]), 1);
        expect(result.getValue([1]), 2);
        expect(result.getValue([2]), 3);
      });

      test('min along axis 1 (2D)', () {
        final arr = NDArray([
          [1, 5, 3],
          [4, 2, 6]
        ]);
        final result = arr.min(axis: 1) as NDArray;
        expect(result.shape.toList(), [2]);
        expect(result.getValue([0]), 1);
        expect(result.getValue([1]), 2);
      });
    });

    group('std with axis', () {
      test('std along axis 0 (2D)', () {
        final arr = NDArray([
          [1, 2, 3],
          [4, 5, 6]
        ]);
        final result = arr.std(axis: 0) as NDArray;
        expect(result.shape.toList(), [3]);
        // std([1,4]) = sqrt(((1-2.5)^2 + (4-2.5)^2)/2) = sqrt(4.5/2) = 1.5
        expect(result.getValue([0]), closeTo(1.5, 0.01));
        expect(result.getValue([1]), closeTo(1.5, 0.01));
        expect(result.getValue([2]), closeTo(1.5, 0.01));
      });

      test('std along axis 1 (2D)', () {
        final arr = NDArray([
          [2, 4, 6],
          [1, 1, 1]
        ]);
        final result = arr.std(axis: 1) as NDArray;
        expect(result.shape.toList(), [2]);
        // std([2,4,6]) = sqrt(((2-4)^2 + (4-4)^2 + (6-4)^2)/3) = sqrt(8/3) ≈ 1.633
        expect(result.getValue([0]), closeTo(1.633, 0.01));
        // std([1,1,1]) = 0
        expect(result.getValue([1]), closeTo(0, 0.01));
      });
    });

    group('error conditions', () {
      test('invalid axis throws error', () {
        final arr = NDArray([
          [1, 2, 3],
          [4, 5, 6]
        ]);
        expect(() => arr.sum(axis: 2), throwsArgumentError);
        expect(() => arr.sum(axis: -1), throwsArgumentError);
        expect(() => arr.mean(axis: 5), throwsArgumentError);
        expect(() => arr.max(axis: -2), throwsArgumentError);
        expect(() => arr.min(axis: 10), throwsArgumentError);
        expect(() => arr.std(axis: 3), throwsArgumentError);
      });
    });

    group('backward compatibility', () {
      test('sumAxis still works', () {
        final arr = NDArray([
          [1, 2, 3],
          [4, 5, 6]
        ]);
        final result = arr.sum(axis: 0);
        expect(result.shape.toList(), [3]);
        expect(result.getValue([0]), 5);
      });

      test('meanAxis still works', () {
        final arr = NDArray([
          [2, 4, 6],
          [8, 10, 12]
        ]);
        final result = arr.mean(axis: 0);
        expect(result.shape.toList(), [3]);
        expect(result.getValue([0]), 5);
      });

      test('maxAxis still works', () {
        final arr = NDArray([
          [1, 5, 3],
          [4, 2, 6]
        ]);
        final result = arr.max(axis: 0);
        expect(result.shape.toList(), [3]);
        expect(result.getValue([0]), 4);
      });

      test('minAxis still works', () {
        final arr = NDArray([
          [1, 5, 3],
          [4, 2, 6]
        ]);
        final result = arr.min(axis: 0);
        expect(result.shape.toList(), [3]);
        expect(result.getValue([0]), 1);
      });
    });

    group('result shape verification', () {
      test('1D array with axis 0 returns scalar-like NDArray', () {
        final arr = NDArray([1, 2, 3, 4]);
        final result = arr.sum(axis: 0) as NDArray;
        expect(result.shape.toList(), [1]);
        expect(result.getValue([0]), 10);
      });

      test('3D array axis reduction produces correct shape', () {
        final arr = NDArray.zeros([3, 4, 5]);

        final result0 = arr.sum(axis: 0) as NDArray;
        expect(result0.shape.toList(), [4, 5]);

        final result1 = arr.sum(axis: 1) as NDArray;
        expect(result1.shape.toList(), [3, 5]);

        final result2 = arr.sum(axis: 2) as NDArray;
        expect(result2.shape.toList(), [3, 4]);
      });
    });
  });

  group('Axis Operations', () {
    test('sum along axis 0', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final result = arr.sum(axis: 0);
      expect(result.shape.toList(), [3]);
      expect(result.getValue([0]), 5);
      expect(result.getValue([1]), 7);
      expect(result.getValue([2]), 9);
    });

    test('sum along axis 1', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final result = arr.sum(axis: 1);
      expect(result.shape.toList(), [2]);
      expect(result.getValue([0]), 6);
      expect(result.getValue([1]), 15);
    });

    test('mean along axis 0', () {
      final arr = NDArray([
        [2, 4, 6],
        [8, 10, 12]
      ]);
      final result = arr.mean(axis: 0);
      expect(result.shape.toList(), [3]);
      expect(result.getValue([0]), 5);
      expect(result.getValue([1]), 7);
      expect(result.getValue([2]), 9);
    });

    test('max along axis', () {
      final arr = NDArray([
        [1, 5, 3],
        [4, 2, 6]
      ]);
      final result = arr.max(axis: 0);
      expect(result.shape.toList(), [3]);
      expect(result.getValue([0]), 4);
      expect(result.getValue([1]), 5);
      expect(result.getValue([2]), 6);
    });

    test('min along axis', () {
      final arr = NDArray([
        [1, 5, 3],
        [4, 2, 6]
      ]);
      final result = arr.min(axis: 0);
      expect(result.shape.toList(), [3]);
      expect(result.getValue([0]), 1);
      expect(result.getValue([1]), 2);
      expect(result.getValue([2]), 3);
    });

    test('sum along axis for 3D', () {
      final arr = NDArray([
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ]
      ]);
      final result = arr.sum(axis: 0);
      expect(result.shape.toList(), [2, 2]);
      expect(result.getValue([0, 0]), 6);
      expect(result.getValue([1, 1]), 12);
    });
  });

  group('Broadcasting', () {
    test('broadcast 1D to 2D', () {
      final a = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final b = NDArray([10, 20, 30]);
      final result = a + b;
      expect(result.shape.toList(), [2, 3]);
      expect(result.getValue([0, 0]), 11);
      expect(result.getValue([0, 2]), 33);
      expect(result.getValue([1, 0]), 14);
      expect(result.getValue([1, 2]), 36);
    });

    test('broadcast scalar dimension', () {
      final a = NDArray([
        [1, 2, 3]
      ]);
      final b = NDArray([
        [10],
        [20]
      ]);
      final result = a + b;
      expect(result.shape.toList(), [2, 3]);
      expect(result.getValue([0, 0]), 11);
      expect(result.getValue([1, 2]), 23);
    });

    test('incompatible shapes throw error', () {
      final a = NDArray([
        [1, 2, 3]
      ]);
      final b = NDArray([
        [1, 2]
      ]);
      expect(() => a + b, throwsArgumentError);
    });
  });

  group('Complex Operations', () {
    test('chained operations', () {
      final arr = NDArray([1, 2, 3, 4]);
      final result = (arr * 2 + 10) / 2;
      // (1*2+10)/2 = 12/2 = 6
      // (4*2+10)/2 = 18/2 = 9
      expect(result.getValue([0]), 6);
      expect(result.getValue([3]), 9);
    });

    test('combined aggregations', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final rowSums = arr.sum(axis: 1);
      expect(rowSums.sum(), 21);
    });

    test('normalize array', () {
      final arr = NDArray([1, 2, 3, 4]);
      final m = arr.mean();
      final s = arr.std();
      final normalized = (arr - m) / s;
      expect(normalized.mean(), closeTo(0, 0.0001));
    });
  });
}
