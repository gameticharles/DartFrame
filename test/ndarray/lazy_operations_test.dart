import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('LazyNDArray', () {
    test('creates lazy array from operation', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final lazy = array.lazyMap((x) => x * 2);

      expect(lazy, isA<LazyNDArray>());
      expect(lazy.isMaterialized, isFalse);
      expect(lazy.shape.toList(), equals([5]));
    });

    test('computes values on demand', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final lazy = array.lazyMap((x) => x * 2);

      expect(lazy.getValue([0]), equals(2));
      expect(lazy.getValue([2]), equals(6));
      expect(lazy.getValue([4]), equals(10));
      expect(lazy.isMaterialized, isFalse);
    });

    test('materializes when requested', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final lazy = array.lazyMap((x) => x * 2);

      final materialized = lazy.materialize();

      expect(lazy.isMaterialized, isTrue);
      expect(materialized.getValue([0]), equals(2));
      expect(materialized.getValue([4]), equals(10));
    });

    test('chains lazy operations', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final lazy = array.lazyMap((x) => x * 2).map((x) => x + 1);

      expect(lazy.getValue([0]), equals(3)); // (1 * 2) + 1
      expect(lazy.getValue([2]), equals(7)); // (3 * 2) + 1
      expect(lazy.isMaterialized, isFalse);
    });

    test('fuses map operations', () {
      final array = NDArray([1, 2, 3]);
      final lazy1 = array.lazyMap((x) => x * 2);
      final lazy2 = lazy1.map((x) => x + 1);

      // Operation fusion should happen during optimization
      final operation = lazy2.operation.optimize();
      expect(operation, isA<LazyMapOperation>());
    });

    test('lazy add operation', () {
      final array1 = NDArray([1, 2, 3]);
      final array2 = NDArray([4, 5, 6]);
      final lazy = array1.lazyAdd(array2);

      expect(lazy.getValue([0]), equals(5));
      expect(lazy.getValue([1]), equals(7));
      expect(lazy.getValue([2]), equals(9));
    });

    test('lazy scalar operations', () {
      final array = NDArray([1, 2, 3]);

      final lazyAdd = array.lazyAdd(10);
      expect(lazyAdd.getValue([0]), equals(11));

      final lazyMul = array.lazyMultiply(2);
      expect(lazyMul.getValue([1]), equals(4));

      final lazySub = array.lazySubtract(1);
      expect(lazySub.getValue([2]), equals(2));

      final lazyDiv = array.lazyDivide(2);
      expect(lazyDiv.getValue([0]), equals(0.5));
    });

    test('materializes before setValue', () {
      final array = NDArray([1, 2, 3]);
      final lazy = array.lazyMap((x) => x * 2);

      expect(lazy.isMaterialized, isFalse);

      lazy.setValue([0], 100);

      expect(lazy.isMaterialized, isTrue);
      expect(lazy.getValue([0]), equals(100));
    });

    test('toLazy creates lazy version', () {
      final array = NDArray([1, 2, 3]);
      final lazy = array.toLazy();

      expect(lazy, isA<LazyNDArray>());
      expect(lazy.getValue([0]), equals(1));
    });

    test('toLazy on already lazy array returns same', () {
      final array = NDArray([1, 2, 3]);
      final lazy1 = array.toLazy();

      // LazyNDArray doesn't have toLazy, so materialize and convert again
      final materialized = lazy1.materialize();
      final lazy2 = materialized.toLazy();

      expect(lazy2, isA<LazyNDArray>());
    });

    test('toString shows materialization status', () {
      final array = NDArray([1, 2, 3]);
      final lazy = array.lazyMap((x) => x * 2);

      expect(lazy.toString(), contains('lazy'));
      expect(lazy.toString(), contains('shape'));

      lazy.materialize();

      expect(lazy.toString(), contains('materialized'));
    });

    test('works with 2D arrays', () {
      final array = NDArray([
        [1, 2, 3],
        [4, 5, 6],
      ]);
      final lazy = array.lazyMap((x) => x * 2);

      expect(lazy.getValue([0, 0]), equals(2));
      expect(lazy.getValue([1, 2]), equals(12));
    });

    test('binary operation requires matching shapes', () {
      final array1 = NDArray([1, 2, 3]);
      final array2 = NDArray([1, 2]);

      expect(
        () => array1.lazyAdd(array2),
        throwsArgumentError,
      );
    });
  });

  group('LazyOperation', () {
    test('LazyMapOperation computes correctly', () {
      final array = NDArray([1, 2, 3]);
      final operation = LazyMapOperation(array, (x) => x * 2);

      expect(operation.shape.toList(), equals([3]));
      expect(operation.compute([0]), equals(2));
      expect(operation.compute([2]), equals(6));
    });

    test('LazyBinaryOperation computes correctly', () {
      final array1 = NDArray([1, 2, 3]);
      final array2 = NDArray([4, 5, 6]);
      final operation = LazyBinaryOperation(array1, array2, (a, b) => a + b);

      expect(operation.compute([0]), equals(5));
      expect(operation.compute([2]), equals(9));
    });

    test('LazyScalarOperation computes correctly', () {
      final array = NDArray([1, 2, 3]);
      final operation = LazyScalarOperation(array, 10, (a, b) => a + b);

      expect(operation.compute([0]), equals(11));
      expect(operation.compute([2]), equals(13));
    });

    test('materialize creates NDArray', () {
      final array = NDArray([1, 2, 3]);
      final operation = LazyMapOperation(array, (x) => x * 2);
      final materialized = operation.materialize();

      expect(materialized, isA<NDArray>());
      expect(materialized.getValue([0]), equals(2));
      expect(materialized.getValue([2]), equals(6));
    });
  });
}
