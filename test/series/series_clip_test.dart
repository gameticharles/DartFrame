import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Series clip()', () {
    test('clips values with both lower and upper bounds', () {
      var s = Series([1, 2, 3, 4, 5], name: 'values');
      var result = s.clip(lower: 2, upper: 4);

      expect(result.data, equals([2, 2, 3, 4, 4]));
      expect(result.name, equals('values_clipped'));
    });

    test('clips values with only lower bound', () {
      var s = Series([1, 2, 3, 4, 5], name: 'values');
      var result = s.clip(lower: 3);

      expect(result.data, equals([3, 3, 3, 4, 5]));
    });

    test('clips values with only upper bound', () {
      var s = Series([1, 2, 3, 4, 5], name: 'values');
      var result = s.clip(upper: 3);

      expect(result.data, equals([1, 2, 3, 3, 3]));
    });

    test('clips decimal values', () {
      var s = Series([1.5, 2.5, 3.5, 4.5, 5.5], name: 'decimals');
      var result = s.clip(lower: 2.0, upper: 4.0);

      expect(result.data, equals([2.0, 2.5, 3.5, 4.0, 4.0]));
    });

    test('throws error when neither lower nor upper specified', () {
      var s = Series([1, 2, 3], name: 'values');

      expect(
        () => s.clip(),
        throwsArgumentError,
      );
    });

    test('throws error when lower > upper', () {
      var s = Series([1, 2, 3], name: 'values');

      expect(
        () => s.clip(lower: 5, upper: 2),
        throwsArgumentError,
      );
    });

    test('handles negative values', () {
      var s = Series([-5, -3, -1, 1, 3, 5], name: 'values');
      var result = s.clip(lower: -2, upper: 2);

      expect(result.data, equals([-2, -2, -1, 1, 2, 2]));
    });

    test('handles null values', () {
      var s = Series([1, null, 3, 4, null], name: 'values');
      var result = s.clip(lower: 2, upper: 3);

      expect(result.data[0], equals(2));
      expect(result.data[1], isNull);
      expect(result.data[2], equals(3));
      expect(result.data[3], equals(3));
      expect(result.data[4], isNull);
    });

    test('handles mixed numeric and non-numeric values', () {
      var s = Series([1, 'text', 3, 4, 'more'], name: 'mixed');
      var result = s.clip(lower: 2, upper: 3);

      expect(result.data[0], equals(2));
      expect(result.data[1], equals('text'));
      expect(result.data[2], equals(3));
      expect(result.data[3], equals(3));
      expect(result.data[4], equals('more'));
    });

    test('preserves index', () {
      var s = Series([1, 2, 3], name: 'values', index: ['a', 'b', 'c']);
      var result = s.clip(lower: 2);

      expect(result.index, equals(['a', 'b', 'c']));
    });

    test('works with single value', () {
      var s = Series([5], name: 'single');
      var result = s.clip(lower: 3, upper: 7);

      expect(result.data, equals([5]));
    });

    test('clips all values when outside range', () {
      var s = Series([1, 2, 3, 4, 5], name: 'values');
      var result = s.clip(lower: 10, upper: 20);

      expect(result.data, equals([10, 10, 10, 10, 10]));
    });

    test('handles empty Series', () {
      var s = Series([], name: 'empty');
      var result = s.clip(lower: 0, upper: 10);

      expect(result.data, isEmpty);
    });

    test('handles all null values', () {
      var s = Series([null, null, null], name: 'nulls');
      var result = s.clip(lower: 0, upper: 10);

      expect(result.data, equals([null, null, null]));
    });

    test('clips with zero bounds', () {
      var s = Series([-2, -1, 0, 1, 2], name: 'values');
      var result = s.clip(lower: 0, upper: 0);

      expect(result.data, equals([0, 0, 0, 0, 0]));
    });

    test('clips large values', () {
      var s = Series([100, 200, 300, 400, 500], name: 'large');
      var result = s.clip(lower: 150, upper: 350);

      expect(result.data, equals([150, 200, 300, 350, 350]));
    });

    test('can be chained with other operations', () {
      var s = Series([-5, -3, 1, 3, 5], name: 'values');
      var result = s.clip(lower: -2, upper: 2).abs();

      expect(result.data, equals([2, 2, 1, 2, 2]));
    });

    test('works with integer bounds on float values', () {
      var s = Series([1.5, 2.5, 3.5], name: 'floats');
      var result = s.clip(lower: 2, upper: 3);

      expect(result.data, equals([2, 2.5, 3]));
    });

    test('works with float bounds on integer values', () {
      var s = Series([1, 2, 3, 4, 5], name: 'ints');
      var result = s.clip(lower: 2.5, upper: 4.5);

      expect(result.data, equals([2.5, 2.5, 3, 4, 4.5]));
    });
  });
}
