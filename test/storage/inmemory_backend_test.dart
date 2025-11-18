import 'package:test/test.dart';
import 'package:dartframe/src/core/shape.dart';
import 'package:dartframe/src/core/slice_spec.dart';
import 'package:dartframe/src/storage/inmemory_backend.dart';

void main() {
  group('InMemoryBackend - Construction', () {
    test('creates from flat data', () {
      var backend = InMemoryBackend([1, 2, 3, 4, 5, 6], Shape([2, 3]));
      expect(backend.shape, equals(Shape([2, 3])));
      expect(backend.size, equals(6));
      expect(backend.ndim, equals(2));
    });

    test('creates filled backend', () {
      var backend = InMemoryBackend.filled(Shape([2, 3]), 42);
      expect(backend.getValue([0, 0]), equals(42));
      expect(backend.getValue([1, 2]), equals(42));
    });

    test('creates zeros backend', () {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      expect(backend.getValue([0, 0]), equals(0));
      expect(backend.getValue([1, 2]), equals(0));
    });

    test('creates ones backend', () {
      var backend = InMemoryBackend.ones(Shape([2, 3]));
      expect(backend.getValue([0, 0]), equals(1));
      expect(backend.getValue([1, 2]), equals(1));
    });

    test('creates from generator', () {
      var backend = InMemoryBackend.generate(
        Shape([2, 3]),
        (indices) => indices[0] * 3 + indices[1],
      );
      expect(backend.getValue([0, 0]), equals(0));
      expect(backend.getValue([0, 1]), equals(1));
      expect(backend.getValue([1, 0]), equals(3));
      expect(backend.getValue([1, 2]), equals(5));
    });

    test('throws on size mismatch', () {
      expect(
        () => InMemoryBackend([1, 2, 3], Shape([2, 3])),
        throwsArgumentError,
      );
    });
  });

  group('InMemoryBackend - getValue/setValue', () {
    test('gets values correctly', () {
      var backend = InMemoryBackend([1, 2, 3, 4, 5, 6], Shape([2, 3]));
      expect(backend.getValue([0, 0]), equals(1));
      expect(backend.getValue([0, 1]), equals(2));
      expect(backend.getValue([0, 2]), equals(3));
      expect(backend.getValue([1, 0]), equals(4));
      expect(backend.getValue([1, 1]), equals(5));
      expect(backend.getValue([1, 2]), equals(6));
    });

    test('sets values correctly', () {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      backend.setValue([0, 1], 42);
      backend.setValue([1, 2], 99);

      expect(backend.getValue([0, 1]), equals(42));
      expect(backend.getValue([1, 2]), equals(99));
      expect(backend.getValue([0, 0]), equals(0));
    });

    test('works with 3D arrays', () {
      var backend = InMemoryBackend.generate(
        Shape([2, 3, 4]),
        (indices) => indices[0] * 12 + indices[1] * 4 + indices[2],
      );

      expect(backend.getValue([0, 0, 0]), equals(0));
      expect(backend.getValue([0, 1, 2]), equals(6));
      expect(backend.getValue([1, 2, 3]), equals(23));
    });

    test('throws on invalid indices', () {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      expect(() => backend.getValue([2, 0]), throwsRangeError);
      expect(() => backend.getValue([0, 3]), throwsRangeError);
      expect(() => backend.getValue([-1, 0]), throwsRangeError);
    });
  });

  group('InMemoryBackend - Slicing', () {
    test('slices 2D array', () {
      var backend = InMemoryBackend([1, 2, 3, 4, 5, 6], Shape([2, 3]));
      var sliced = backend.getSlice([
        SliceSpec(0, 1),
        SliceSpec.all(),
      ]);

      expect(sliced.shape, equals(Shape([1, 3])));
      expect(sliced.getValue([0, 0]), equals(1));
      expect(sliced.getValue([0, 1]), equals(2));
      expect(sliced.getValue([0, 2]), equals(3));
    });

    test('slices with step', () {
      var backend = InMemoryBackend(
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        Shape([10]),
      );
      var sliced = backend.getSlice([SliceSpec(0, 10, step: 2)]);

      expect(sliced.shape, equals(Shape([5])));
      expect(sliced.getFlatData(), equals([0, 2, 4, 6, 8]));
    });

    test('slices with single index reduces dimension', () {
      var backend = InMemoryBackend([1, 2, 3, 4, 5, 6], Shape([2, 3]));
      var sliced = backend.getSlice([
        SliceSpec.single(0),
        SliceSpec.all(),
      ]);

      expect(sliced.shape, equals(Shape([3])));
      expect(sliced.getFlatData(), equals([1, 2, 3]));
    });

    test('slices 3D array', () {
      var backend = InMemoryBackend.generate(
        Shape([2, 3, 4]),
        (indices) => indices[0] * 12 + indices[1] * 4 + indices[2],
      );

      var sliced = backend.getSlice([
        SliceSpec.single(0),
        SliceSpec.all(),
        SliceSpec(0, 2),
      ]);

      expect(sliced.shape, equals(Shape([3, 2])));
    });

    test('throws on wrong number of slices', () {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      expect(
        () => backend.getSlice([SliceSpec.all()]),
        throwsArgumentError,
      );
    });
  });

  group('InMemoryBackend - Memory Management', () {
    test('load is no-op', () async {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      await backend.load();
      expect(backend.isInMemory, isTrue);
    });

    test('unload is no-op', () async {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      await backend.unload();
      expect(backend.isInMemory, isTrue);
    });

    test('reports memory usage', () {
      var backend = InMemoryBackend.zeros(Shape([100, 100]));
      expect(backend.memoryUsage, greaterThan(0));
    });

    test('isInMemory is always true', () {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      expect(backend.isInMemory, isTrue);
    });
  });

  group('InMemoryBackend - Data Access', () {
    test('getFlatData returns data', () {
      var backend = InMemoryBackend([1, 2, 3, 4], Shape([2, 2]));
      var data = backend.getFlatData();
      expect(data, equals([1, 2, 3, 4]));
    });

    test('getFlatData with copy', () {
      var backend = InMemoryBackend([1, 2, 3, 4], Shape([2, 2]));
      var data = backend.getFlatData(copy: true);
      data[0] = 999;

      expect(backend.getValue([0, 0]), equals(1));
    });

    test('getFlatData without copy shares reference', () {
      var backend = InMemoryBackend([1, 2, 3, 4], Shape([2, 2]));
      var data = backend.getFlatData(copy: false);
      data[0] = 999;

      expect(backend.getValue([0, 0]), equals(999));
    });
  });

  group('InMemoryBackend - Clone', () {
    test('clones backend', () {
      var backend = InMemoryBackend([1, 2, 3, 4], Shape([2, 2]));
      var cloned = backend.clone();

      expect(cloned.shape, equals(backend.shape));
      expect(cloned.getFlatData(), equals(backend.getFlatData()));
    });

    test('clone is independent', () {
      var backend = InMemoryBackend([1, 2, 3, 4], Shape([2, 2]));
      var cloned = backend.clone();

      cloned.setValue([0, 0], 999);
      expect(backend.getValue([0, 0]), equals(1));
      expect(cloned.getValue([0, 0]), equals(999));
    });
  });

  group('InMemoryBackend - Statistics', () {
    test('tracks getValue calls', () {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      backend.getValue([0, 0]);
      backend.getValue([1, 2]);

      expect(backend.stats.getCount, equals(2));
    });

    test('tracks setValue calls', () {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      backend.setValue([0, 0], 1);
      backend.setValue([1, 2], 2);

      expect(backend.stats.setCount, equals(2));
    });

    test('resets statistics', () {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      backend.getValue([0, 0]);
      backend.setValue([1, 2], 1);

      backend.resetStats();
      expect(backend.stats.getCount, equals(0));
      expect(backend.stats.setCount, equals(0));
    });
  });

  group('InMemoryBackend - String Representation', () {
    test('toString includes shape and size', () {
      var backend = InMemoryBackend.zeros(Shape([2, 3]));
      var str = backend.toString();
      expect(str, contains('InMemoryBackend'));
      expect(str, contains('shape'));
      expect(str, contains('size'));
    });
  });
}
