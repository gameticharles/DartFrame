import 'package:test/test.dart';
import 'package:dartframe/src/index/axis_index.dart';

void main() {
  group('AxisIndex - Construction', () {
    test('creates from labels', () {
      var index = AxisIndex(['a', 'b', 'c']);
      expect(index.length, equals(3));
      expect(index.labels, equals(['a', 'b', 'c']));
    });

    test('creates with name', () {
      var index = AxisIndex(['a', 'b', 'c'], name: 'columns');
      expect(index.name, equals('columns'));
    });

    test('creates integer range', () {
      var index = AxisIndex.range(5);
      expect(index.labels, equals([0, 1, 2, 3, 4]));
    });

    test('creates integer range with start', () {
      var index = AxisIndex.range(5, start: 10);
      expect(index.labels, equals([10, 11, 12, 13, 14]));
    });

    test('creates date range', () {
      var index = AxisIndex.dateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 3),
      );
      expect(index.length, equals(3));
      expect(index.isDateTime, isTrue);
    });

    test('throws on duplicate labels', () {
      expect(
        () => AxisIndex(['a', 'b', 'a']),
        throwsArgumentError,
      );
    });
  });

  group('AxisIndex - Position/Label Lookup', () {
    test('gets position for label', () {
      var index = AxisIndex(['a', 'b', 'c']);
      expect(index.getPosition('a'), equals(0));
      expect(index.getPosition('b'), equals(1));
      expect(index.getPosition('c'), equals(2));
    });

    test('returns null for non-existent label', () {
      var index = AxisIndex(['a', 'b', 'c']);
      expect(index.getPosition('d'), isNull);
    });

    test('gets label at position', () {
      var index = AxisIndex(['a', 'b', 'c']);
      expect(index.getLabel(0), equals('a'));
      expect(index.getLabel(1), equals('b'));
      expect(index.getLabel(2), equals('c'));
    });

    test('throws on out of bounds position', () {
      var index = AxisIndex(['a', 'b', 'c']);
      expect(() => index.getLabel(3), throwsRangeError);
      expect(() => index.getLabel(-1), throwsRangeError);
    });

    test('contains checks label existence', () {
      var index = AxisIndex(['a', 'b', 'c']);
      expect(index.contains('a'), isTrue);
      expect(index.contains('b'), isTrue);
      expect(index.contains('d'), isFalse);
    });
  });

  group('AxisIndex - Batch Operations', () {
    test('gets positions for multiple labels', () {
      var index = AxisIndex(['a', 'b', 'c']);
      var positions = index.getPositions(['b', 'c', 'd']);
      expect(positions, equals([1, 2, null]));
    });

    test('gets labels at multiple positions', () {
      var index = AxisIndex(['a', 'b', 'c']);
      var labels = index.getLabels([1, 2]);
      expect(labels, equals(['b', 'c']));
    });

    test('slices index', () {
      var index = AxisIndex(['a', 'b', 'c', 'd']);
      var sliced = index.slice([1, 2]);
      expect(sliced.labels, equals(['b', 'c']));
    });

    test('sliced index preserves name', () {
      var index = AxisIndex(['a', 'b', 'c'], name: 'test');
      var sliced = index.slice([0, 1]);
      expect(sliced.name, equals('test'));
    });
  });

  group('AxisIndex - Properties', () {
    test('length returns number of labels', () {
      var index = AxisIndex(['a', 'b', 'c']);
      expect(index.length, equals(3));
    });

    test('isEmpty and isNotEmpty', () {
      var empty = AxisIndex([]);
      var notEmpty = AxisIndex(['a']);

      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
      expect(notEmpty.isEmpty, isFalse);
      expect(notEmpty.isNotEmpty, isTrue);
    });

    test('isUnique is always true', () {
      var index = AxisIndex(['a', 'b', 'c']);
      expect(index.isUnique, isTrue);
    });

    test('isMonotonicIncreasing', () {
      var increasing = AxisIndex([1, 2, 3, 4]);
      var notIncreasing = AxisIndex([1, 3, 2, 4]);

      expect(increasing.isMonotonicIncreasing, isTrue);
      expect(notIncreasing.isMonotonicIncreasing, isFalse);
    });

    test('isMonotonicDecreasing', () {
      var decreasing = AxisIndex([4, 3, 2, 1]);
      var notDecreasing = AxisIndex([4, 2, 3, 1]);

      expect(decreasing.isMonotonicDecreasing, isTrue);
      expect(notDecreasing.isMonotonicDecreasing, isFalse);
    });

    test('isNumeric', () {
      var numeric = AxisIndex([1, 2, 3]);
      var notNumeric = AxisIndex(['a', 'b', 'c']);

      expect(numeric.isNumeric, isTrue);
      expect(notNumeric.isNumeric, isFalse);
    });

    test('isDateTime', () {
      var dates = AxisIndex([
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
      ]);
      var notDates = AxisIndex(['a', 'b']);

      expect(dates.isDateTime, isTrue);
      expect(notDates.isDateTime, isFalse);
    });

    test('dtype returns type of labels', () {
      var intIndex = AxisIndex([1, 2, 3]);
      var stringIndex = AxisIndex(['a', 'b', 'c']);

      expect(intIndex.dtype, equals(int));
      expect(stringIndex.dtype, equals(String));
    });
  });

  group('AxisIndex - Conversion', () {
    test('toList returns copy of labels', () {
      var index = AxisIndex(['a', 'b', 'c']);
      var list = index.toList();
      expect(list, equals(['a', 'b', 'c']));

      // Verify it's a copy
      list[0] = 'x';
      expect(index.labels[0], equals('a'));
    });
  });

  group('AxisIndex - Equality', () {
    test('equal indices are equal', () {
      var index1 = AxisIndex(['a', 'b', 'c'], name: 'test');
      var index2 = AxisIndex(['a', 'b', 'c'], name: 'test');
      expect(index1 == index2, isTrue);
    });

    test('different indices are not equal', () {
      var index1 = AxisIndex(['a', 'b', 'c']);
      var index2 = AxisIndex(['a', 'b', 'd']);
      expect(index1 == index2, isFalse);
    });

    test('different names make indices not equal', () {
      var index1 = AxisIndex(['a', 'b', 'c'], name: 'test1');
      var index2 = AxisIndex(['a', 'b', 'c'], name: 'test2');
      expect(index1 == index2, isFalse);
    });

    test('hashCode is consistent', () {
      var index1 = AxisIndex(['a', 'b', 'c'], name: 'test');
      var index2 = AxisIndex(['a', 'b', 'c'], name: 'test');
      expect(index1.hashCode, equals(index2.hashCode));
    });
  });

  group('AxisIndex - String Representation', () {
    test('toString without name', () {
      var index = AxisIndex(['a', 'b', 'c']);
      var str = index.toString();
      expect(str, contains('AxisIndex'));
      expect(str, contains('a'));
    });

    test('toString with name', () {
      var index = AxisIndex(['a', 'b', 'c'], name: 'columns');
      var str = index.toString();
      expect(str, contains('columns'));
    });

    test('toString truncates long indices', () {
      var index = AxisIndex(List.generate(10, (i) => i));
      var str = index.toString();
      expect(str, contains('...'));
    });
  });

  group('AxisIndex - Edge Cases', () {
    test('handles empty index', () {
      var index = AxisIndex([]);
      expect(index.length, equals(0));
      expect(index.isEmpty, isTrue);
    });

    test('handles single element', () {
      var index = AxisIndex(['a']);
      expect(index.length, equals(1));
      expect(index.getPosition('a'), equals(0));
    });

    test('handles numeric labels', () {
      var index = AxisIndex([1, 2, 3]);
      expect(index.getPosition(2), equals(1));
    });

    test('handles DateTime labels', () {
      var date = DateTime(2024, 1, 1);
      var index = AxisIndex([date]);
      expect(index.getPosition(date), equals(0));
    });

    test('handles mixed comparable types', () {
      var index = AxisIndex([1, 2.5, 3]);
      expect(index.isNumeric, isTrue);
    });
  });
}
