import 'dart:math' show sqrt;
import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('ArrayUtils - Creation Methods', () {
    test('zeros creates array filled with zeros', () {
      final arr = ArrayUtils.zeros([2, 3]);
      expect(arr.shape.toList(), equals([2, 3]));
      expect(
          arr.toNestedList(),
          equals([
            [0, 0, 0],
            [0, 0, 0]
          ]));
    });

    test('zeros creates 1D array', () {
      final arr = ArrayUtils.zeros([5]);
      expect(arr.shape.toList(), equals([5]));
      expect(arr.toNestedList(), equals([0, 0, 0, 0, 0]));
    });

    test('zeros creates 3D array', () {
      final arr = ArrayUtils.zeros([2, 2, 2]);
      expect(arr.shape.toList(), equals([2, 2, 2]));
      expect(arr.shape.size, equals(8));
    });

    test('ones creates array filled with ones', () {
      final arr = ArrayUtils.ones([2, 3]);
      expect(arr.shape.toList(), equals([2, 3]));
      expect(
          arr.toNestedList(),
          equals([
            [1, 1, 1],
            [1, 1, 1]
          ]));
    });

    test('ones creates 1D array', () {
      final arr = ArrayUtils.ones([4]);
      expect(arr.shape.toList(), equals([4]));
      expect(arr.toNestedList(), equals([1, 1, 1, 1]));
    });

    test('full creates array filled with specific value', () {
      final arr = ArrayUtils.full([2, 3], 5);
      expect(arr.shape.toList(), equals([2, 3]));
      expect(
          arr.toNestedList(),
          equals([
            [5, 5, 5],
            [5, 5, 5]
          ]));
    });

    test('full creates array with double value', () {
      final arr = ArrayUtils.full([2, 2], 3.14);
      expect(arr.shape.toList(), equals([2, 2]));
      expect(
          arr.toNestedList(),
          equals([
            [3.14, 3.14],
            [3.14, 3.14]
          ]));
    });

    test('eye creates square identity matrix', () {
      final arr = ArrayUtils.eye(3);
      expect(arr.shape.toList(), equals([3, 3]));
      expect(
          arr.toNestedList(),
          equals([
            [1, 0, 0],
            [0, 1, 0],
            [0, 0, 1]
          ]));
    });

    test('eye creates rectangular identity matrix', () {
      final arr = ArrayUtils.eye(3, m: 4);
      expect(arr.shape.toList(), equals([3, 4]));
      expect(
          arr.toNestedList(),
          equals([
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0]
          ]));
    });

    test('eye creates tall rectangular matrix', () {
      final arr = ArrayUtils.eye(4, m: 2);
      expect(arr.shape.toList(), equals([4, 2]));
      expect(
          arr.toNestedList(),
          equals([
            [1, 0],
            [0, 1],
            [0, 0],
            [0, 0]
          ]));
    });
  });

  group('ArrayUtils - Sequence Generation', () {
    test('arange creates integer sequence', () {
      final arr = ArrayUtils.arange(0, 5);
      expect(arr.shape.toList(), equals([5]));
      expect(arr.toNestedList(), equals([0, 1, 2, 3, 4]));
    });

    test('arange creates sequence with step', () {
      final arr = ArrayUtils.arange(0, 10, step: 2);
      expect(arr.shape.toList(), equals([5]));
      expect(arr.toNestedList(), equals([0, 2, 4, 6, 8]));
    });

    test('arange creates float sequence', () {
      final arr = ArrayUtils.arange(1.0, 2.0, step: 0.25);
      expect(arr.shape.toList(), equals([4]));
      expect(arr.toNestedList(), equals([1.0, 1.25, 1.5, 1.75]));
    });

    test('arange creates negative sequence', () {
      final arr = ArrayUtils.arange(5, 0, step: -1);
      expect(arr.shape.toList(), equals([5]));
      expect(arr.toNestedList(), equals([5, 4, 3, 2, 1]));
    });

    test('arange with non-integer step', () {
      final arr = ArrayUtils.arange(0, 1, step: 0.3);
      expect(arr.shape.toList(), equals([4]));
      final values = arr.toNestedList() as List;
      expect(values.length, equals(4));
      expect(values[0], closeTo(0.0, 0.001));
      expect(values[1], closeTo(0.3, 0.001));
      expect(values[2], closeTo(0.6, 0.001));
      expect(values[3], closeTo(0.9, 0.001));
    });

    test('linspace creates evenly spaced values', () {
      final arr = ArrayUtils.linspace(0, 1, 5);
      expect(arr.shape.toList(), equals([5]));
      expect(arr.toNestedList(), equals([0.0, 0.25, 0.5, 0.75, 1.0]));
    });

    test('linspace includes both endpoints', () {
      final arr = ArrayUtils.linspace(0, 10, 11);
      final values = arr.toNestedList() as List;
      expect(values.first, equals(0.0));
      expect(values.last, equals(10.0));
    });

    test('linspace with negative range', () {
      final arr = ArrayUtils.linspace(-5, 5, 11);
      final values = arr.toNestedList() as List;
      expect(values.first, equals(-5.0));
      expect(values.last, equals(5.0));
      expect(values[5], closeTo(0.0, 0.001));
    });
  });

  group('ArrayUtils - Random Generation', () {
    test('random creates array with values between 0 and 1', () {
      final arr = ArrayUtils.random([10]);
      final values = arr.toNestedList() as List;

      for (var val in values) {
        expect(val, greaterThanOrEqualTo(0.0));
        expect(val, lessThan(1.0));
      }
    });

    test('random with seed produces reproducible results', () {
      final arr1 = ArrayUtils.random([5, 5], seed: 42);
      final arr2 = ArrayUtils.random([5, 5], seed: 42);

      expect(arr1.toNestedList(), equals(arr2.toNestedList()));
    });

    test('random with different seeds produces different results', () {
      final arr1 = ArrayUtils.random([5, 5], seed: 42);
      final arr2 = ArrayUtils.random([5, 5], seed: 123);

      expect(arr1.toNestedList(), isNot(equals(arr2.toNestedList())));
    });

    test('random creates 2D array', () {
      final arr = ArrayUtils.random([3, 4]);
      expect(arr.shape.toList(), equals([3, 4]));
      expect(arr.shape.size, equals(12));
    });

    test('randomNormal creates normally distributed values', () {
      final arr = ArrayUtils.randomNormal([1000], seed: 42);
      final values = (arr.toNestedList() as List).cast<num>();

      // Calculate mean and std
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
              values.length;
      final std = sqrt(variance);

      // Should be close to standard normal (mean=0, std=1)
      expect(mean, closeTo(0.0, 0.1));
      expect(std, closeTo(1.0, 0.1));
    });

    test('randomNormal with custom mean and std', () {
      final arr =
          ArrayUtils.randomNormal([1000], mean: 5.0, std: 2.0, seed: 42);
      final values = (arr.toNestedList() as List).cast<num>();

      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
              values.length;
      final std = sqrt(variance);

      expect(mean, closeTo(5.0, 0.2));
      expect(std, closeTo(2.0, 0.2));
    });

    test('randomNormal with seed produces reproducible results', () {
      final arr1 = ArrayUtils.randomNormal([5, 5], seed: 42);
      final arr2 = ArrayUtils.randomNormal([5, 5], seed: 42);

      expect(arr1.toNestedList(), equals(arr2.toNestedList()));
    });

    test('randomNormal creates 2D array', () {
      final arr = ArrayUtils.randomNormal([3, 4]);
      expect(arr.shape.toList(), equals([3, 4]));
      expect(arr.shape.size, equals(12));
    });
  });

  group('ArrayUtils - Conversion', () {
    test('fromList creates 1D array', () {
      final arr = ArrayUtils.fromList([1, 2, 3, 4, 5]);
      expect(arr.shape.toList(), equals([5]));
      expect(arr.toNestedList(), equals([1, 2, 3, 4, 5]));
    });

    test('fromList creates 2D array', () {
      final arr = ArrayUtils.fromList([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      expect(arr.shape.toList(), equals([2, 3]));
      expect(
          arr.toNestedList(),
          equals([
            [1, 2, 3],
            [4, 5, 6]
          ]));
    });

    test('fromList creates 3D array', () {
      final arr = ArrayUtils.fromList([
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ]
      ]);
      expect(arr.shape.toList(), equals([2, 2, 2]));
    });

    test('toList converts 1D array', () {
      final arr = ArrayUtils.ones([5]);
      final list = ArrayUtils.toList(arr);
      expect(list, equals([1, 1, 1, 1, 1]));
    });

    test('toList converts 2D array', () {
      final arr = ArrayUtils.zeros([2, 3]);
      final list = ArrayUtils.toList(arr);
      expect(
          list,
          equals([
            [0, 0, 0],
            [0, 0, 0]
          ]));
    });

    test('fromList to toList round-trip preserves data', () {
      final original = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
      ];
      final arr = ArrayUtils.fromList(original);
      final result = ArrayUtils.toList(arr);
      expect(result, equals(original));
    });

    test('round-trip with 3D array', () {
      final original = [
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ]
      ];
      final arr = ArrayUtils.fromList(original);
      final result = ArrayUtils.toList(arr);
      expect(result, equals(original));
    });

    test('round-trip with float values', () {
      final original = [
        [1.5, 2.5],
        [3.5, 4.5]
      ];
      final arr = ArrayUtils.fromList(original);
      final result = ArrayUtils.toList(arr);
      expect(result, equals(original));
    });
  });

  group('ArrayUtils - Error Conditions', () {
    test('zeros throws on empty shape', () {
      expect(() => ArrayUtils.zeros([]), throwsArgumentError);
    });

    test('zeros throws on negative dimension', () {
      expect(() => ArrayUtils.zeros([2, -3]), throwsArgumentError);
    });

    test('zeros throws on zero dimension', () {
      expect(() => ArrayUtils.zeros([2, 0, 3]), throwsArgumentError);
    });

    test('ones throws on invalid shape', () {
      expect(() => ArrayUtils.ones([0]), throwsArgumentError);
    });

    test('full throws on invalid shape', () {
      expect(() => ArrayUtils.full([-1, 2], 5), throwsArgumentError);
    });

    test('eye throws on non-positive n', () {
      expect(() => ArrayUtils.eye(0), throwsArgumentError);
      expect(() => ArrayUtils.eye(-1), throwsArgumentError);
    });

    test('eye throws on non-positive m', () {
      expect(() => ArrayUtils.eye(3, m: 0), throwsArgumentError);
      expect(() => ArrayUtils.eye(3, m: -2), throwsArgumentError);
    });

    test('arange throws on zero step', () {
      expect(() => ArrayUtils.arange(0, 10, step: 0), throwsArgumentError);
    });

    test('arange throws on wrong sign step', () {
      expect(() => ArrayUtils.arange(0, 10, step: -1), throwsArgumentError);
      expect(() => ArrayUtils.arange(10, 0, step: 1), throwsArgumentError);
    });

    test('linspace throws on num less than 2', () {
      expect(() => ArrayUtils.linspace(0, 1, 1), throwsArgumentError);
      expect(() => ArrayUtils.linspace(0, 1, 0), throwsArgumentError);
    });

    test('random throws on invalid shape', () {
      expect(() => ArrayUtils.random([0]), throwsArgumentError);
      expect(() => ArrayUtils.random([2, -1]), throwsArgumentError);
    });

    test('randomNormal throws on invalid shape', () {
      expect(() => ArrayUtils.randomNormal([]), throwsArgumentError);
      expect(() => ArrayUtils.randomNormal([2, 0]), throwsArgumentError);
    });

    test('randomNormal throws on non-positive std', () {
      expect(() => ArrayUtils.randomNormal([5], std: 0), throwsArgumentError);
      expect(() => ArrayUtils.randomNormal([5], std: -1), throwsArgumentError);
    });

    test('fromList throws on empty list', () {
      expect(() => ArrayUtils.fromList([]), throwsArgumentError);
    });
  });

  group('ArrayUtils - Edge Cases', () {
    test('creates single element array', () {
      final arr = ArrayUtils.zeros([1]);
      expect(arr.shape.toList(), equals([1]));
      expect(arr.toNestedList(), equals([0]));
    });

    test('creates 1x1 matrix', () {
      final arr = ArrayUtils.ones([1, 1]);
      expect(arr.shape.toList(), equals([1, 1]));
      expect(
          arr.toNestedList(),
          equals([
            [1]
          ]));
    });

    test('eye with n=1', () {
      final arr = ArrayUtils.eye(1);
      expect(
          arr.toNestedList(),
          equals([
            [1]
          ]));
    });

    test('arange with single element', () {
      final arr = ArrayUtils.arange(0, 1);
      expect(arr.toNestedList(), equals([0]));
    });

    test('linspace with 2 elements', () {
      final arr = ArrayUtils.linspace(0, 10, 2);
      expect(arr.toNestedList(), equals([0.0, 10.0]));
    });

    test('random with single element', () {
      final arr = ArrayUtils.random([1], seed: 42);
      expect(arr.shape.size, equals(1));
    });

    test('randomNormal with odd number of elements', () {
      final arr = ArrayUtils.randomNormal([7], seed: 42);
      expect(arr.shape.size, equals(7));
    });

    test('large array creation', () {
      final arr = ArrayUtils.zeros([100, 100]);
      expect(arr.shape.size, equals(10000));
    });
  });
}
