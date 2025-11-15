import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('MultiIndex', () {
    group('Construction', () {
      test('fromArrays creates MultiIndex', () {
        final idx = MultiIndex.fromArrays([
          ['A', 'A', 'B', 'B'],
          [1, 2, 1, 2]
        ], names: [
          'letter',
          'number'
        ]);

        expect(idx.nlevels, equals(2));
        expect(idx.length, equals(4));
        expect(idx.names, equals(['letter', 'number']));
      });

      test('fromTuples creates MultiIndex', () {
        final idx = MultiIndex.fromTuples([
          ['A', 1],
          ['A', 2],
          ['B', 1],
          ['B', 2]
        ], names: [
          'letter',
          'number'
        ]);

        expect(idx.nlevels, equals(2));
        expect(idx.length, equals(4));
      });

      test('fromProduct creates Cartesian product', () {
        final idx = MultiIndex.fromProduct([
          ['A', 'B'],
          [1, 2]
        ], names: [
          'letter',
          'number'
        ]);

        expect(idx.length, equals(4));
        expect(idx[0], equals(['A', 1]));
        expect(idx[1], equals(['A', 2]));
        expect(idx[2], equals(['B', 1]));
        expect(idx[3], equals(['B', 2]));
      });
    });

    group('Access', () {
      late MultiIndex idx;

      setUp(() {
        idx = MultiIndex.fromArrays([
          ['A', 'A', 'B', 'B'],
          [1, 2, 1, 2]
        ], names: [
          'letter',
          'number'
        ]);
      });

      test('Access by index', () {
        expect(idx[0], equals(['A', 1]));
        expect(idx[1], equals(['A', 2]));
        expect(idx[2], equals(['B', 1]));
        expect(idx[3], equals(['B', 2]));
      });

      test('getLevelValues returns values for level', () {
        final letters = idx.getLevelValues(0);
        expect(letters, equals(['A', 'A', 'B', 'B']));

        final numbers = idx.getLevelValues(1);
        expect(numbers, equals([1, 2, 1, 2]));
      });

      test('getLevelValues by name', () {
        final letters = idx.getLevelValues('letter');
        expect(letters, equals(['A', 'A', 'B', 'B']));

        final numbers = idx.getLevelValues('number');
        expect(numbers, equals([1, 2, 1, 2]));
      });

      test('Out of bounds throws error', () {
        expect(() => idx[10], throwsRangeError);
      });
    });

    group('Operations', () {
      late MultiIndex idx;

      setUp(() {
        idx = MultiIndex.fromArrays([
          ['A', 'A', 'B', 'B'],
          [1, 2, 1, 2]
        ], names: [
          'letter',
          'number'
        ]);
      });

      test('setNames changes names', () {
        final newIdx = idx.setNames(['L', 'N']);

        expect(newIdx.names, equals(['L', 'N']));
        expect(idx.names, equals(['letter', 'number'])); // Original unchanged
      });

      test('dropLevel removes a level', () {
        final newIdx = idx.dropLevel(0);

        expect(newIdx.nlevels, equals(1));
        expect(newIdx.length, equals(4));
        expect(newIdx.getLevelValues(0), equals([1, 2, 1, 2]));
      });

      test('dropLevel by name', () {
        final newIdx = idx.dropLevel('letter');

        expect(newIdx.nlevels, equals(1));
        expect(newIdx.getLevelValues(0), equals([1, 2, 1, 2]));
      });

      test('Cannot drop last level', () {
        final singleLevel = idx.dropLevel(0);
        expect(() => singleLevel.dropLevel(0), throwsArgumentError);
      });

      test('swapLevel swaps two levels', () {
        final newIdx = idx.swapLevel(0, 1);

        expect(newIdx[0], equals([1, 'A']));
        expect(newIdx[1], equals([2, 'A']));
        expect(newIdx[2], equals([1, 'B']));
        expect(newIdx[3], equals([2, 'B']));
      });

      test('swapLevel by name', () {
        final newIdx = idx.swapLevel('letter', 'number');

        expect(newIdx[0], equals([1, 'A']));
        expect(newIdx.names, equals(['number', 'letter']));
      });

      test('reorderLevels reorders levels', () {
        final newIdx = idx.reorderLevels([1, 0]);

        expect(newIdx[0], equals([1, 'A']));
        expect(newIdx.names, equals(['number', 'letter']));
      });

      test('reorderLevels by name', () {
        final newIdx = idx.reorderLevels(['number', 'letter']);

        expect(newIdx[0], equals([1, 'A']));
      });
    });

    group('Set Operations', () {
      test('union combines unique values', () {
        final idx1 = MultiIndex.fromTuples([
          ['A', 1],
          ['A', 2],
          ['B', 1]
        ]);

        final idx2 = MultiIndex.fromTuples([
          ['B', 1],
          ['B', 2],
          ['C', 1]
        ]);

        final result = idx1.union(idx2);

        expect(result.length, equals(5));
        expect(result.contains(['A', 1]), isTrue);
        expect(result.contains(['A', 2]), isTrue);
        expect(result.contains(['B', 1]), isTrue);
        expect(result.contains(['B', 2]), isTrue);
        expect(result.contains(['C', 1]), isTrue);
      });

      test('intersection finds common values', () {
        final idx1 = MultiIndex.fromTuples([
          ['A', 1],
          ['A', 2],
          ['B', 1]
        ]);

        final idx2 = MultiIndex.fromTuples([
          ['A', 2],
          ['B', 1],
          ['C', 1]
        ]);

        final result = idx1.intersection(idx2);

        expect(result.length, equals(2));
        expect(result.contains(['A', 2]), isTrue);
        expect(result.contains(['B', 1]), isTrue);
      });

      test('difference finds unique to first', () {
        final idx1 = MultiIndex.fromTuples([
          ['A', 1],
          ['A', 2],
          ['B', 1]
        ]);

        final idx2 = MultiIndex.fromTuples([
          ['A', 2],
          ['B', 1]
        ]);

        final result = idx1.difference(idx2);

        expect(result.length, equals(1));
        expect(result.contains(['A', 1]), isTrue);
      });
    });

    group('Utilities', () {
      test('unique returns unique tuples', () {
        final idx = MultiIndex.fromArrays([
          ['A', 'A', 'B', 'A'],
          [1, 2, 1, 1]
        ]);

        final unique = idx.unique;

        expect(unique.length, equals(3));
      });

      test('contains checks for value', () {
        final idx = MultiIndex.fromArrays([
          ['A', 'A', 'B'],
          [1, 2, 1]
        ]);

        expect(idx.contains(['A', 1]), isTrue);
        expect(idx.contains(['A', 2]), isTrue);
        expect(idx.contains(['C', 1]), isFalse);
      });

      test('indexOf finds position', () {
        final idx = MultiIndex.fromArrays([
          ['A', 'A', 'B'],
          [1, 2, 1]
        ]);

        expect(idx.indexOf(['A', 1]), equals(0));
        expect(idx.indexOf(['B', 1]), equals(2));
        expect(idx.indexOf(['C', 1]), equals(-1));
      });

      test('toList converts to list of tuples', () {
        final idx = MultiIndex.fromArrays([
          ['A', 'B'],
          [1, 2]
        ]);

        final list = idx.toList();

        expect(
            list,
            equals([
              ['A', 1],
              ['B', 2]
            ]));
      });
    });

    group('Edge Cases', () {
      test('Empty arrays throw error', () {
        expect(
          () => MultiIndex.fromArrays([]),
          throwsArgumentError,
        );
      });

      test('Mismatched array lengths throw error', () {
        expect(
          () => MultiIndex.fromArrays([
            ['A', 'B'],
            [1, 2, 3]
          ]),
          throwsArgumentError,
        );
      });

      test('Single level MultiIndex', () {
        final idx = MultiIndex.fromArrays([
          ['A', 'B', 'C']
        ]);

        expect(idx.nlevels, equals(1));
        expect(idx.length, equals(3));
      });

      test('Three level MultiIndex', () {
        final idx = MultiIndex.fromArrays([
          ['A', 'A', 'B', 'B'],
          [1, 2, 1, 2],
          ['x', 'y', 'x', 'y']
        ]);

        expect(idx.nlevels, equals(3));
        expect(idx[0], equals(['A', 1, 'x']));
      });
    });
  });
}
