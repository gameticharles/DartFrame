import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Series Emptiness', () {
    test('isEmpty returns boolean Series', () {
      var s = Series([1, null, 3], name: 'test');
      var isEmpty = s.isEmpty;

      expect(isEmpty, isA<Series>());
      expect(isEmpty.dtype, equals(bool));
      expect(isEmpty.data, equals([false, true, false]));
    });

    test('isNotEmpty returns boolean Series', () {
      var s = Series([1, null, 3], name: 'test');
      var isNotEmpty = s.isNotEmpty;

      expect(isNotEmpty, isA<Series>());
      expect(isNotEmpty.dtype, equals(bool));
      expect(isNotEmpty.data, equals([true, false, true]));
    });

    test('isEmpty on empty Series (no data)', () {
      var s = Series([], name: 'empty');
      // Even if no data, it should return an empty boolean Series
      var isEmpty = s.isEmpty;
      expect(isEmpty, isA<Series>());
      expect(isEmpty.length, equals(0));
    });

    test('Legacy boolean check via length', () {
      // Verify that we can still check if a series has no elements using length
      var s = Series([], name: 'empty');
      expect(s.length == 0, isTrue);
      expect(s.data.isEmpty, isTrue);

      var s2 = Series([1], name: 'not_empty');
      expect(s2.length == 0, isFalse);
      expect(s2.data.isEmpty, isFalse);
    });
  });
}
