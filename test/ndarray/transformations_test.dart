import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('NDArray Transformations', () {
    group('transpose', () {
      test('transpose 2D array without axes (reverse)', () {
        final arr = NDArray([
          [1, 2, 3],
          [4, 5, 6]
        ]); // shape: [2, 3]
        final transposed = arr.transpose();

        expect(transposed.shape.toList(), [3, 2]);
        expect(transposed.getValue([0, 0]), 1);
        expect(transposed.getValue([0, 1]), 4);
        expect(transposed.getValue([1, 0]), 2);
        expect(transposed.getValue([1, 1]), 5);
        expect(transposed.getValue([2, 0]), 3);
        expect(transposed.getValue([2, 1]), 6);
      });

      test('transpose 3D array without axes', () {
        final arr = NDArray([
          [
            [1, 2],
            [3, 4]
          ],
          [
            [5, 6],
            [7, 8]
          ]
        ]); // shape: [2, 2, 2]
        final transposed = arr.transpose();

        expect(transposed.shape.toList(), [2, 2, 2]);
        expect(transposed.getValue([0, 0, 0]), 1);
        expect(transposed.getValue([1, 0, 0]), 2);
        expect(transposed.getValue([0, 1, 0]), 3);
      });

      test('transpose with custom axes', () {
        final arr = NDArray([
          [
            [1, 2],
            [3, 4]
          ],
          [
            [5, 6],
            [7, 8]
          ]
        ]); // shape: [2, 2, 2]
        final transposed = arr.transpose(axes: [2, 0, 1]);

        expect(transposed.shape.toList(), [2, 2, 2]);
        expect(transposed.getValue([0, 0, 0]), 1);
        expect(transposed.getValue([0, 1, 0]), 5);
        expect(transposed.getValue([1, 0, 0]), 2);
      });

      test('transpose throws on invalid axes length', () {
        final arr = NDArray([
          [1, 2],
          [3, 4]
        ]);
        expect(() => arr.transpose(axes: [0]), throwsArgumentError);
      });

      test('transpose throws on duplicate axes', () {
        final arr = NDArray([
          [1, 2],
          [3, 4]
        ]);
        expect(() => arr.transpose(axes: [0, 0]), throwsArgumentError);
      });

      test('transpose throws on out of bounds axis', () {
        final arr = NDArray([
          [1, 2],
          [3, 4]
        ]);
        expect(() => arr.transpose(axes: [0, 5]), throwsArgumentError);
      });

      test('transpose throws on negative axis', () {
        final arr = NDArray([
          [1, 2],
          [3, 4]
        ]);
        expect(() => arr.transpose(axes: [-1, 1]), throwsArgumentError);
      });

      test('transpose 1D array', () {
        final arr = NDArray([1, 2, 3, 4]);
        final transposed = arr.transpose();

        expect(transposed.shape.toList(), [4]);
        expect(transposed.toFlatList(), [1, 2, 3, 4]);
      });

      test('transpose 4D array without axes', () {
        final arr = NDArray([
          [
            [
              [1, 2],
              [3, 4]
            ]
          ]
        ]); // shape: [1, 1, 2, 2]
        final transposed = arr.transpose();

        expect(transposed.shape.toList(), [2, 2, 1, 1]);
        expect(transposed.getValue([0, 0, 0, 0]), 1);
        expect(transposed.getValue([1, 0, 0, 0]), 2);
        expect(transposed.getValue([0, 1, 0, 0]), 3);
        expect(transposed.getValue([1, 1, 0, 0]), 4);
      });
    });

    group('flatten', () {
      test('flatten 1D array', () {
        final arr = NDArray([1, 2, 3, 4, 5]);
        final flat = arr.flatten();

        expect(flat.shape.toList(), [5]);
        expect(flat.toFlatList(), [1, 2, 3, 4, 5]);
      });

      test('flatten 2D array', () {
        final arr = NDArray([
          [1, 2, 3],
          [4, 5, 6]
        ]);
        final flat = arr.flatten();

        expect(flat.shape.toList(), [6]);
        expect(flat.toFlatList(), [1, 2, 3, 4, 5, 6]);
      });

      test('flatten 3D array', () {
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
        final flat = arr.flatten();

        expect(flat.shape.toList(), [8]);
        expect(flat.toFlatList(), [1, 2, 3, 4, 5, 6, 7, 8]);
      });

      test('flatten 4D array (N-D test)', () {
        final arr = NDArray([
          [
            [
              [1, 2],
              [3, 4]
            ],
            [
              [5, 6],
              [7, 8]
            ]
          ],
          [
            [
              [9, 10],
              [11, 12]
            ],
            [
              [13, 14],
              [15, 16]
            ]
          ]
        ]); // shape: [2, 2, 2, 2]
        final flat = arr.flatten();

        expect(flat.shape.toList(), [16]);
        expect(flat.toFlatList(),
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
      });
    });

    group('asType', () {
      test('convert int to float', () {
        final arr = NDArray([1, 2, 3]);
        final floatArr = arr.asType(DTypes.float64());

        expect(floatArr.getValue([0]), 1.0);
        expect(floatArr.getValue([1]), 2.0);
        expect(floatArr.getValue([2]), 3.0);
      });

      test('convert int to string', () {
        final arr = NDArray([1, 2, 3]);
        final strArr = arr.asType(DTypes.string());

        expect(strArr.getValue([0]), '1');
        expect(strArr.getValue([1]), '2');
        expect(strArr.getValue([2]), '3');
      });

      test('convert float to int', () {
        final arr = NDArray([1.5, 2.7, 3.2]);
        final intArr = arr.asType(DTypes.int64());

        expect(intArr.getValue([0]), 1);
        expect(intArr.getValue([1]), 2);
        expect(intArr.getValue([2]), 3);
      });

      test('convert string to int', () {
        final arr = NDArray(['10', '20', '30']);
        final intArr = arr.asType(DTypes.int64());

        expect(intArr.getValue([0]), 10);
        expect(intArr.getValue([1]), 20);
        expect(intArr.getValue([2]), 30);
      });

      test('convert double to string', () {
        final arr = NDArray([1.5, 2.7, 3.14159]);
        final strArr = arr.asType(DTypes.string());

        expect(strArr.getValue([0]), '1.5');
        expect(strArr.getValue([1]), '2.7');
        expect(strArr.getValue([2]), '3.14159');
      });

      test('convert string to double', () {
        final arr = NDArray(['1.5', '2.7', '3.14']);
        final floatArr = arr.asType(DTypes.float64());

        expect(floatArr.getValue([0]), 1.5);
        expect(floatArr.getValue([1]), 2.7);
        expect(floatArr.getValue([2]), 3.14);
      });

      test('asType on 2D array', () {
        final arr = NDArray([
          [1, 2],
          [3, 4]
        ]);
        final floatArr = arr.asType(DTypes.float64());

        expect(floatArr.getValue([0, 0]), 1.0);
        expect(floatArr.getValue([0, 1]), 2.0);
        expect(floatArr.getValue([1, 0]), 3.0);
        expect(floatArr.getValue([1, 1]), 4.0);
      });

      test('asType throws on invalid conversion', () {
        final arr = NDArray(['abc', 'def']);
        expect(() => arr.asType(DTypes.int64()), throwsFormatException);
      });
    });
  });
}
