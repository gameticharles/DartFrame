import 'package:test/test.dart';
import 'package:dartframe/src/core/slice_spec.dart';

void main() {
  group('SliceSpec - Construction', () {
    test('creates basic slice', () {
      var slice = SliceSpec(0, 10);
      expect(slice.start, equals(0));
      expect(slice.stop, equals(10));
      expect(slice.step, equals(1));
      expect(slice.isSingleIndex, isFalse);
    });

    test('creates slice with step', () {
      var slice = SliceSpec(0, 10, step: 2);
      expect(slice.start, equals(0));
      expect(slice.stop, equals(10));
      expect(slice.step, equals(2));
    });

    test('creates slice with null start', () {
      var slice = SliceSpec(null, 10);
      expect(slice.start, isNull);
      expect(slice.stop, equals(10));
    });

    test('creates slice with null stop', () {
      var slice = SliceSpec(5, null);
      expect(slice.start, equals(5));
      expect(slice.stop, isNull);
    });

    test('creates all slice', () {
      var slice = SliceSpec.all();
      expect(slice.start, isNull);
      expect(slice.stop, isNull);
      expect(slice.step, equals(1));
      expect(slice.isSingleIndex, isFalse);
    });

    test('creates single index slice', () {
      var slice = SliceSpec.single(5);
      expect(slice.start, equals(5));
      expect(slice.stop, equals(6));
      expect(slice.step, equals(1));
      expect(slice.isSingleIndex, isTrue);
    });

    test('throws on zero step', () {
      expect(() => SliceSpec(0, 10, step: 0), throwsArgumentError);
    });
  });

  group('SliceSpec - Resolve', () {
    test('resolves basic slice', () {
      var slice = SliceSpec(2, 8);
      var (start, stop, step) = slice.resolve(10);
      expect(start, equals(2));
      expect(stop, equals(8));
      expect(step, equals(1));
    });

    test('resolves null start', () {
      var slice = SliceSpec(null, 5);
      var (start, stop, step) = slice.resolve(10);
      expect(start, equals(0));
      expect(stop, equals(5));
    });

    test('resolves null stop', () {
      var slice = SliceSpec(5, null);
      var (start, stop, step) = slice.resolve(10);
      expect(start, equals(5));
      expect(stop, equals(10));
    });

    test('resolves all slice', () {
      var slice = SliceSpec.all();
      var (start, stop, step) = slice.resolve(10);
      expect(start, equals(0));
      expect(stop, equals(10));
      expect(step, equals(1));
    });

    test('resolves negative start', () {
      var slice = SliceSpec(-3, null);
      var (start, stop, step) = slice.resolve(10);
      expect(start, equals(7));
      expect(stop, equals(10));
    });

    test('resolves negative stop', () {
      var slice = SliceSpec(null, -2);
      var (start, stop, step) = slice.resolve(10);
      expect(start, equals(0));
      expect(stop, equals(8));
    });

    test('resolves negative step', () {
      var slice = SliceSpec(null, null, step: -1);
      var (start, stop, step) = slice.resolve(10);
      expect(start, equals(9));
      expect(stop, equals(-1));
      expect(step, equals(-1));
    });

    test('clamps out of bounds start', () {
      var slice = SliceSpec(20, null);
      var (start, stop, step) = slice.resolve(10);
      expect(start, equals(10));
    });

    test('clamps out of bounds stop', () {
      var slice = SliceSpec(null, 20);
      var (start, stop, step) = slice.resolve(10);
      expect(stop, equals(10));
    });
  });

  group('SliceSpec - Length', () {
    test('calculates length for basic slice', () {
      var slice = SliceSpec(0, 10);
      expect(slice.length(10), equals(10));
    });

    test('calculates length with step', () {
      var slice = SliceSpec(0, 10, step: 2);
      expect(slice.length(10), equals(5));
    });

    test('calculates length for partial slice', () {
      var slice = SliceSpec(2, 8);
      expect(slice.length(10), equals(6));
    });

    test('calculates length for single index', () {
      var slice = SliceSpec.single(5);
      expect(slice.length(10), equals(1));
    });

    test('calculates length for negative step', () {
      var slice = SliceSpec(9, 0, step: -1);
      expect(slice.length(10), equals(9));
    });

    test('returns 0 for empty slice', () {
      var slice = SliceSpec(5, 5);
      expect(slice.length(10), equals(0));
    });

    test('returns 0 for reversed empty slice', () {
      var slice = SliceSpec(5, 10, step: -1);
      expect(slice.length(10), equals(0));
    });
  });

  group('SliceSpec - Indices', () {
    test('returns indices for basic slice', () {
      var slice = SliceSpec(0, 5);
      expect(slice.indices(10), equals([0, 1, 2, 3, 4]));
    });

    test('returns indices with step', () {
      var slice = SliceSpec(0, 10, step: 2);
      expect(slice.indices(10), equals([0, 2, 4, 6, 8]));
    });

    test('returns indices for partial slice', () {
      var slice = SliceSpec(2, 7);
      expect(slice.indices(10), equals([2, 3, 4, 5, 6]));
    });

    test('returns indices for negative step', () {
      var slice = SliceSpec(9, 4, step: -1);
      expect(slice.indices(10), equals([9, 8, 7, 6, 5]));
    });

    test('returns single index', () {
      var slice = SliceSpec.single(5);
      expect(slice.indices(10), equals([5]));
    });

    test('returns all indices', () {
      var slice = SliceSpec.all();
      expect(slice.indices(5), equals([0, 1, 2, 3, 4]));
    });

    test('returns empty list for empty slice', () {
      var slice = SliceSpec(5, 5);
      expect(slice.indices(10), isEmpty);
    });
  });

  group('Slice - Helper Methods', () {
    test('all creates all slice', () {
      var slice = Slice.all();
      expect(slice.start, isNull);
      expect(slice.stop, isNull);
      expect(slice.step, equals(1));
    });

    test('range creates range slice', () {
      var slice = Slice.range(0, 10, step: 2);
      expect(slice.start, equals(0));
      expect(slice.stop, equals(10));
      expect(slice.step, equals(2));
    });

    test('from creates open-ended slice', () {
      var slice = Slice.from(5);
      expect(slice.start, equals(5));
      expect(slice.stop, isNull);
    });

    test('to creates slice to end', () {
      var slice = Slice.to(10);
      expect(slice.start, isNull);
      expect(slice.stop, equals(10));
    });

    test('single creates single index', () {
      var slice = Slice.single(5);
      expect(slice.isSingleIndex, isTrue);
      expect(slice.start, equals(5));
    });

    test('every creates step slice', () {
      var slice = Slice.every(2);
      expect(slice.step, equals(2));
      expect(slice.start, isNull);
      expect(slice.stop, isNull);
    });

    test('last creates negative start slice', () {
      var slice = Slice.last(5);
      expect(slice.start, equals(-5));
      expect(slice.stop, isNull);
    });

    test('first creates slice to n', () {
      var slice = Slice.first(5);
      expect(slice.start, isNull);
      expect(slice.stop, equals(5));
    });

    test('reverse creates reverse slice', () {
      var slice = Slice.reverse();
      expect(slice.step, equals(-1));
      var indices = slice.indices(5);
      expect(indices, equals([4, 3, 2, 1, 0]));
    });
  });

  group('SliceSpec - String Representation', () {
    test('toString for basic slice', () {
      var slice = SliceSpec(0, 10);
      expect(slice.toString(), equals('0:10'));
    });

    test('toString for slice with step', () {
      var slice = SliceSpec(0, 10, step: 2);
      expect(slice.toString(), equals('0:10:2'));
    });

    test('toString for null start', () {
      var slice = SliceSpec(null, 10);
      expect(slice.toString(), equals(':10'));
    });

    test('toString for null stop', () {
      var slice = SliceSpec(5, null);
      expect(slice.toString(), equals('5:'));
    });

    test('toString for all slice', () {
      var slice = SliceSpec.all();
      expect(slice.toString(), equals(':'));
    });

    test('toString for single index', () {
      var slice = SliceSpec.single(5);
      expect(slice.toString(), equals('5'));
    });

    test('toString for negative step', () {
      var slice = SliceSpec(null, null, step: -1);
      expect(slice.toString(), equals('::-1'));
    });
  });

  group('SliceSpec - Equality', () {
    test('equal slices are equal', () {
      var slice1 = SliceSpec(0, 10, step: 2);
      var slice2 = SliceSpec(0, 10, step: 2);
      expect(slice1 == slice2, isTrue);
    });

    test('different slices are not equal', () {
      var slice1 = SliceSpec(0, 10);
      var slice2 = SliceSpec(0, 11);
      expect(slice1 == slice2, isFalse);
    });

    test('single index vs range are not equal', () {
      var slice1 = SliceSpec.single(5);
      var slice2 = SliceSpec(5, 6);
      expect(slice1 == slice2, isFalse);
    });

    test('hashCode is consistent', () {
      var slice1 = SliceSpec(0, 10, step: 2);
      var slice2 = SliceSpec(0, 10, step: 2);
      expect(slice1.hashCode, equals(slice2.hashCode));
    });
  });

  group('SliceSpec - Edge Cases', () {
    test('handles step larger than range', () {
      var slice = SliceSpec(0, 5, step: 10);
      expect(slice.indices(10), equals([0]));
    });

    test('handles negative indices beyond bounds', () {
      var slice = SliceSpec(-20, null);
      var (start, stop, step) = slice.resolve(10);
      expect(start, equals(0));
    });

    test('handles very large positive indices', () {
      var slice = SliceSpec(100, 200);
      var (start, stop, step) = slice.resolve(10);
      expect(start, equals(10));
      expect(stop, equals(10));
    });

    test('handles negative step with positive indices', () {
      var slice = SliceSpec(8, 2, step: -2);
      expect(slice.indices(10), equals([8, 6, 4]));
    });

    test('throws on invalid dimension size', () {
      var slice = SliceSpec(0, 10);
      expect(() => slice.resolve(-1), throwsArgumentError);
    });
  });

  group('SliceExtension', () {
    test('int.toSlice creates single index', () {
      var slice = 5.toSlice();
      expect(slice.isSingleIndex, isTrue);
      expect(slice.start, equals(5));
    });
  });
}
