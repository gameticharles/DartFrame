import 'package:test/test.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';
import 'package:dartframe/src/core/shape.dart';
import 'package:dartframe/src/core/slice_spec.dart';
import 'package:dartframe/src/core/scalar.dart';
import 'package:dartframe/src/storage/inmemory_backend.dart';

void main() {
  group('NDArray Construction', () {
    test('from nested lists - 1D', () {
      final arr = NDArray([1, 2, 3, 4]);
      expect(arr.shape.toList(), [4]);
      expect(arr.ndim, 1);
      expect(arr.size, 4);
      expect(arr.getValue([0]), 1);
      expect(arr.getValue([3]), 4);
    });

    test('from nested lists - 2D', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      expect(arr.shape.toList(), [2, 3]);
      expect(arr.ndim, 2);
      expect(arr.size, 6);
      expect(arr.getValue([0, 0]), 1);
      expect(arr.getValue([1, 2]), 6);
    });

    test('from nested lists - 3D', () {
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
      expect(arr.shape.toList(), [2, 2, 2]);
      expect(arr.ndim, 3);
      expect(arr.size, 8);
      expect(arr.getValue([0, 0, 0]), 1);
      expect(arr.getValue([1, 1, 1]), 8);
    });

    test('from flat data', () {
      final arr = NDArray.fromFlat([1, 2, 3, 4, 5, 6], [2, 3]);
      expect(arr.shape.toList(), [2, 3]);
      expect(arr.getValue([0, 0]), 1);
      expect(arr.getValue([1, 2]), 6);
    });

    test('from flat data - mismatched size throws', () {
      expect(() => NDArray.fromFlat([1, 2, 3], [2, 3]), throwsArgumentError);
    });

    test('zeros', () {
      final arr = NDArray.zeros([2, 3]);
      expect(arr.shape.toList(), [2, 3]);
      expect(arr.getValue([0, 0]), 0);
      expect(arr.getValue([1, 2]), 0);
    });

    test('ones', () {
      final arr = NDArray.ones([2, 3]);
      expect(arr.shape.toList(), [2, 3]);
      expect(arr.getValue([0, 0]), 1);
      expect(arr.getValue([1, 2]), 1);
    });

    test('filled', () {
      final arr = NDArray.filled([2, 3], 42);
      expect(arr.shape.toList(), [2, 3]);
      expect(arr.getValue([0, 0]), 42);
      expect(arr.getValue([1, 2]), 42);
    });

    test('generate', () {
      final arr = NDArray.generate([2, 3], (indices) {
        return indices[0] * 10 + indices[1];
      });
      expect(arr.getValue([0, 0]), 0);
      expect(arr.getValue([0, 2]), 2);
      expect(arr.getValue([1, 0]), 10);
      expect(arr.getValue([1, 2]), 12);
    });

    test('with custom backend', () {
      final backend = InMemoryBackend.zeros(Shape([2, 3]));
      final arr = NDArray.withBackend([2, 3], backend);
      expect(arr.shape.toList(), [2, 3]);
      expect(arr.backend, backend);
    });
  });

  group('NDArray Access', () {
    late NDArray arr;

    setUp(() {
      arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
    });

    test('getValue', () {
      expect(arr.getValue([0, 0]), 1);
      expect(arr.getValue([0, 1]), 2);
      expect(arr.getValue([1, 0]), 4);
      expect(arr.getValue([1, 2]), 6);
    });

    test('setValue', () {
      arr.setValue([0, 0], 99);
      expect(arr.getValue([0, 0]), 99);

      arr.setValue([1, 2], 88);
      expect(arr.getValue([1, 2]), 88);
    });
  });

  group('NDArray Slicing', () {
    late NDArray arr;

    setUp(() {
      arr = NDArray([
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ]
      ]);
    });

    test('slice to scalar', () {
      final result =
          arr.slice([Slice.single(0), Slice.single(0), Slice.single(0)]);
      expect(result, isA<Scalar>());
      expect((result as Scalar).value, 1);
    });

    test('slice to 1D', () {
      final result = arr.slice([Slice.single(0), Slice.single(0), Slice.all()]);
      expect(result, isA<NDArray>());
      final ndResult = result as NDArray;
      expect(ndResult.shape.toList(), [2]);
      expect(ndResult.getValue([0]), 1);
      expect(ndResult.getValue([1]), 2);
    });

    test('slice to 2D', () {
      final result = arr.slice([Slice.single(0), Slice.all(), Slice.all()]);
      expect(result, isA<NDArray>());
      final ndResult = result as NDArray;
      expect(ndResult.shape.toList(), [2, 2]);
      expect(ndResult.getValue([0, 0]), 1);
      expect(ndResult.getValue([1, 1]), 4);
    });

    test('slice with range', () {
      final result =
          arr.slice([Slice.range(0, 2), Slice.single(0), Slice.single(0)]);
      expect(result, isA<NDArray>());
      final ndResult = result as NDArray;
      expect(ndResult.shape.toList(), [2]);
      expect(ndResult.getValue([0]), 1);
      expect(ndResult.getValue([1]), 5);
    });
  });

  group('NDArray Reshape', () {
    test('reshape 1D to 2D', () {
      final arr = NDArray([1, 2, 3, 4, 5, 6]);
      final reshaped = arr.reshape([2, 3]);
      expect(reshaped.shape.toList(), [2, 3]);
      expect(reshaped.getValue([0, 0]), 1);
      expect(reshaped.getValue([1, 2]), 6);
    });

    test('reshape 2D to 1D', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final reshaped = arr.reshape([6]);
      expect(reshaped.shape.toList(), [6]);
      expect(reshaped.getValue([0]), 1);
      expect(reshaped.getValue([5]), 6);
    });

    test('reshape 2D to 3D', () {
      final arr = NDArray.fromFlat([1, 2, 3, 4, 5, 6, 7, 8], [2, 4]);
      final reshaped = arr.reshape([2, 2, 2]);
      expect(reshaped.shape.toList(), [2, 2, 2]);
      expect(reshaped.getValue([0, 0, 0]), 1);
      expect(reshaped.getValue([1, 1, 1]), 8);
    });

    test('reshape with incompatible size throws', () {
      final arr = NDArray([1, 2, 3, 4]);
      expect(() => arr.reshape([2, 3]), throwsArgumentError);
    });

    test('reshape preserves attributes', () {
      final arr = NDArray([1, 2, 3, 4]);
      arr.attrs['test'] = 'value';
      final reshaped = arr.reshape([2, 2]);
      expect(reshaped.attrs['test'], 'value');
    });
  });

  group('NDArray Operations', () {
    test('map', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final mapped = arr.map((x) => x * 2);
      expect(mapped.getValue([0, 0]), 2);
      expect(mapped.getValue([1, 2]), 12);
    });

    test('where', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final filtered = arr.where((x) => x > 3);
      expect(filtered.shape.toList(), [3]);
      expect(filtered.getValue([0]), 4);
      expect(filtered.getValue([1]), 5);
      expect(filtered.getValue([2]), 6);
    });

    test('copy', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      arr.attrs['test'] = 'value';

      final copied = arr.copy();
      expect(copied.getValue([0, 0]), 1);
      expect(copied.attrs['test'], 'value');

      // Modify original
      arr.setValue([0, 0], 99);
      arr.attrs['test'] = 'changed';

      // Copy should be unchanged
      expect(copied.getValue([0, 0]), 1);
      expect(copied.attrs['test'], 'value');
    });
  });

  group('NDArray Conversion', () {
    test('toNestedList - 1D', () {
      final arr = NDArray([1, 2, 3, 4]);
      expect(arr.toNestedList(), [1, 2, 3, 4]);
    });

    test('toNestedList - 2D', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      expect(arr.toNestedList(), [
        [1, 2, 3],
        [4, 5, 6]
      ]);
    });

    test('toNestedList - 3D', () {
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
      expect(arr.toNestedList(), [
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ]
      ]);
    });

    test('toFlatList', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      expect(arr.toFlatList(), [1, 2, 3, 4, 5, 6]);
    });

    test('toFlatList with copy=false', () {
      final arr = NDArray([1, 2, 3, 4]);
      final flat = arr.toFlatList(copy: false);
      expect(flat, [1, 2, 3, 4]);
    });
  });

  group('NDArray Attributes', () {
    test('attributes are accessible', () {
      final arr = NDArray([1, 2, 3]);
      arr.attrs['name'] = 'test';
      arr.attrs['version'] = 1;

      expect(arr.attrs['name'], 'test');
      expect(arr.attrs['version'], 1);
    });

    test('slice preserves attributes', () {
      final arr = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      arr.attrs['test'] = 'value';

      final sliced = arr.slice([Slice.single(0), Slice.all()]) as NDArray;
      expect(sliced.attrs['test'], 'value');
    });
  });

  group('NDArray toString', () {
    test('small array shows data', () {
      final arr = NDArray([1, 2, 3]);
      expect(arr.toString(), contains('data'));
    });

    test('large array shows size', () {
      final arr = NDArray.zeros([100, 100]);
      expect(arr.toString(), contains('size'));
    });

    test('empty array', () {
      final arr = NDArray.zeros([0]);
      expect(arr.toString(), contains('empty'));
    });
  });

  group('Backend Selection', () {
    test('uses InMemory backend', () {
      final arr = NDArray.zeros([10, 10]);
      expect(arr.backend, isA<InMemoryBackend>());
    });
  });
}
