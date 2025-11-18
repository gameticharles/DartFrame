import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('NDArray Filtering', () {
    test('where filters elements', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final filtered = array.where((x) => x > 2);

      expect(filtered.shape.toList(), equals([3]));
      expect(filtered.getValue([0]), equals(3));
      expect(filtered.getValue([2]), equals(5));
    });

    test('whereIndices returns matching indices', () {
      final array = NDArray([
        [1, 2],
        [3, 4]
      ]);
      final indices = array.whereIndices((x) => x > 2);

      expect(indices.length, equals(2));
      // Check that indices contain the expected values
      expect(indices.any((idx) => idx[0] == 1 && idx[1] == 0), isTrue);
      expect(indices.any((idx) => idx[0] == 1 && idx[1] == 1), isTrue);
    });

    test('select picks elements at indices', () {
      final array = NDArray([
        [1, 2],
        [3, 4]
      ]);
      final selected = array.select([
        [0, 0],
        [1, 1]
      ]);

      expect(selected.shape.toList(), equals([2]));
      expect(selected.getValue([0]), equals(1));
      expect(selected.getValue([1]), equals(4));
    });

    test('filterRange filters by value range', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final filtered = array.filterRange(2, 4);

      expect(filtered.shape.toList(), equals([3]));
      expect(filtered.getValue([0]), equals(2));
      expect(filtered.getValue([2]), equals(4));
    });

    test('filterMulti with AND logic', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final filtered = array.filterMulti([
        (x) => x > 1,
        (x) => x < 5,
      ], logic: 'and');

      expect(filtered.shape.toList(), equals([3]));
      expect(filtered.getValue([0]), equals(2));
    });

    test('filterMulti with OR logic', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final filtered = array.filterMulti([
        (x) => x == 1,
        (x) => x == 5,
      ], logic: 'or');

      expect(filtered.shape.toList(), equals([2]));
      expect(filtered.getValue([0]), equals(1));
      expect(filtered.getValue([1]), equals(5));
    });

    test('countWhere counts matching elements', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final count = array.countWhere((x) => x > 2);

      expect(count, equals(3));
    });

    test('any returns true if any element matches', () {
      final array = NDArray([1, 2, 3]);
      expect(array.any((x) => x > 2), isTrue);
      expect(array.any((x) => x > 10), isFalse);
    });

    test('all returns true if all elements match', () {
      final array = NDArray([1, 2, 3]);
      expect(array.all((x) => x > 0), isTrue);
      expect(array.all((x) => x > 2), isFalse);
    });

    test('replaceWhere replaces matching values', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final replaced = array.replaceWhere((x) => x > 3, 0);

      expect(replaced.getValue([0]), equals(1));
      expect(replaced.getValue([3]), equals(0));
      expect(replaced.getValue([4]), equals(0));
    });

    test('findFirst returns first matching index', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final index = array.findFirst((x) => x > 3);

      expect(index, equals([3]));
    });

    test('findFirst returns null if no match', () {
      final array = NDArray([1, 2, 3]);
      final index = array.findFirst((x) => x > 10);

      expect(index, isNull);
    });

    test('findLast returns last matching index', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final index = array.findLast((x) => x > 3);

      expect(index, equals([4]));
    });
  });

  group('Advanced Indexing', () {
    test('indexWith selects along axis', () {
      final array = NDArray([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      final indexed = array.indexWith([0, 2], axis: 1);

      expect(indexed.shape.toList(), equals([2, 2]));
      expect(indexed.getValue([0, 0]), equals(1));
      expect(indexed.getValue([0, 1]), equals(3));
      expect(indexed.getValue([1, 0]), equals(4));
      expect(indexed.getValue([1, 1]), equals(6));
    });

    test('indexWith works with 1D arrays', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final indexed = array.indexWith([0, 2, 4]);

      expect(indexed.shape.toList(), equals([3]));
      expect(indexed.getValue([0]), equals(1));
      expect(indexed.getValue([1]), equals(3));
      expect(indexed.getValue([2]), equals(5));
    });

    test('take is alias for indexWith', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final taken = array.take([1, 3]);

      expect(taken.shape.toList(), equals([2]));
      expect(taken.getValue([0]), equals(2));
      expect(taken.getValue([1]), equals(4));
    });

    test('indexWith throws on invalid axis', () {
      final array = NDArray([1, 2, 3]);
      expect(
        () => array.indexWith([0], axis: 5),
        throwsArgumentError,
      );
    });
  });

  group('Boolean Masks', () {
    test('mask filters by boolean array', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final mask = NDArray([true, false, true, false, true]);
      final masked = array.mask(mask);

      expect(masked.shape.toList(), equals([3]));
      expect(masked.getValue([0]), equals(1));
      expect(masked.getValue([1]), equals(3));
      expect(masked.getValue([2]), equals(5));
    });

    test('mask throws on shape mismatch', () {
      final array = NDArray([1, 2, 3]);
      final mask = NDArray([true, false]);

      expect(
        () => array.mask(mask),
        throwsArgumentError,
      );
    });

    test('createMask generates boolean mask', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      final mask = array.createMask((x) => x > 2);

      expect(mask.shape.toList(), equals([5]));
      expect(mask.getValue([0]), equals(false));
      expect(mask.getValue([2]), equals(true));
      expect(mask.getValue([4]), equals(true));
    });

    test('mask works with 2D arrays', () {
      final array = NDArray([
        [1, 2],
        [3, 4]
      ]);
      final mask = NDArray([
        [true, false],
        [false, true]
      ]);
      final masked = array.mask(mask);

      expect(masked.shape.toList(), equals([2]));
      expect(masked.getValue([0]), equals(1));
      expect(masked.getValue([1]), equals(4));
    });
  });

  group('Put Operations', () {
    test('put sets values at flat indices', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      array.put([0, 2, 4], 0);

      expect(array.getValue([0]), equals(0));
      expect(array.getValue([1]), equals(2));
      expect(array.getValue([2]), equals(0));
      expect(array.getValue([4]), equals(0));
    });

    test('put throws on invalid index', () {
      final array = NDArray([1, 2, 3]);

      expect(
        () => array.put([10], 0),
        throwsRangeError,
      );
    });

    test('putAt sets values at multi-dimensional indices', () {
      final array = NDArray([
        [1, 2],
        [3, 4]
      ]);
      array.putAt([
        [0, 0],
        [1, 1]
      ], 0);

      expect(array.getValue([0, 0]), equals(0));
      expect(array.getValue([0, 1]), equals(2));
      expect(array.getValue([1, 1]), equals(0));
    });

    test('putValues sets different values at indices', () {
      final array = NDArray([1, 2, 3, 4, 5]);
      array.putValues([0, 2, 4], [10, 20, 30]);

      expect(array.getValue([0]), equals(10));
      expect(array.getValue([2]), equals(20));
      expect(array.getValue([4]), equals(30));
    });

    test('putValues throws on length mismatch', () {
      final array = NDArray([1, 2, 3]);

      expect(
        () => array.putValues([0, 1], [10]),
        throwsArgumentError,
      );
    });
  });
}
