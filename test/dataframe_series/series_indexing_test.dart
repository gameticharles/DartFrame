import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Series Indexing and Accessing', () {
    // Tests for [] (operator get)
    group('Series.operator [] (get)', () {
      test('get by integer position', () {
        final s = Series([10, 20, 30], name: 'data');
        expect(s[0], equals(10));
        expect(s[1], equals(20));
        expect(s[2], equals(30));
        expect(() => s[3],
            throwsRangeError); // Or specific IndexError if implemented
        expect(() => s[-1], throwsRangeError);
      });

      test('get by boolean list', () {
        final s =
            Series([10, 20, 30, 40], name: 'data', index: ['a', 'b', 'c', 'd']);
        final result = s[[true, false, true, false]];
        expect(result, isA<Series>());
        expect(result.data, equals([10, 30]));
        expect(result.name, equals('data'));
        // Indexing with boolean list should ideally preserve original matching indices
        // Current Series[List<bool>] creates a new default index for the result.
        // This might be an area for future enhancement if index preservation is desired.
        // For now, testing current behavior (new default index).
        expect(result.index, equals([0, 1]));
      });

      test('get by boolean Series', () {
        final s =
            Series([10, 20, 30, 40], name: 'data', index: ['a', 'b', 'c', 'd']);
        final boolSeries = Series([false, true, false, true], name: 'filter');
        final result = s[boolSeries];

        expect(result, isA<Series>());
        expect(result.data, equals([20, 40]));
        // As above, current boolean Series indexing likely results in a new default index.
        expect(result.index, equals([0, 1]));
      });

      test('get with boolean list of incorrect length', () {
        final s = Series([10, 20, 30], name: 'data');
        // The current implementation of `operator[]` for List<bool> iterates up to `indices.length`.
        // If `indices.length` is shorter than `data.length`, it only processes a subset.
        // If `indices.length` is longer, it might cause issues if it tries to access `data[i]` out of bounds.
        // Let's assume the current implementation correctly handles boolean lists matching data length.
        // A specific error for mismatched length might be desirable.
        // For now, testing that it doesn't crash with a common scenario.
        expect(() => s[[true, false]], returnsNormally); // Processes first two
        // This behavior is a bit lenient. Pandas would raise IndexError for mismatched boolean mask length.
      });
    });

    // Tests for []= (operator set)
    group('Series.operator []= (set)', () {
      test('set by single integer position with single value', () {
        final s = Series([1, 2, 3], name: 'data');
        s[1] = 99;
        expect(s.data, equals([1, 99, 3]));
      });

      test('set by single integer position, out of bounds', () {
        final s = Series([1, 2, 3], name: 'data');
        expect(() => s[3] = 99, throwsRangeError);
      });

      test('set by list of integer positions with single value (broadcast)',
          () {
        // This specific feature (broadcasting single value to multiple int indices)
        // is not explicitly in the current Series []= signature for List<int>.
        // `s[[0,2]] = 100;` would require `value` to be a list of same length as indices.
        // The current implementation for List<int> indices expects value to be a List.
        // So, this test is for a potential future enhancement or clarification of behavior.
        // For now, this would throw an ArgumentError "Value must be a list..."
        final s = Series([1, 2, 3, 4], name: 'data_broadcast_int_idx');
        expect(() => s[[0, 2]] = 100, throwsArgumentError);
      });

      test('set by list of integer positions with list of values', () {
        final s = Series([1, 2, 3, 4], name: 'data');
        s[[0, 2]] = [100, 300];
        expect(s.data, equals([100, 2, 300, 4]));
      });

      test('set by list of integer positions with mismatched value list length',
          () {
        final s = Series([1, 2, 3, 4], name: 'data');
        expect(() => s[[0, 2]] = [100], throwsArgumentError);
      });

      test('set by boolean list with single value (broadcast)', () {
        final s = Series([10, 20, 30, 40], name: 'data');
        s[[true, false, true, false]] = 99;
        expect(s.data, equals([99, 20, 99, 40]));
      });

      test('set by boolean Series with single value (broadcast)', () {
        final s = Series([10, 20, 30, 40], name: 'data');
        final boolS = Series([false, true, false, true], name: 'filter');
        s[boolS] = 88;
        expect(s.data, equals([10, 88, 30, 88]));
      });

      test('set by boolean list with list of values', () {
        // This requires the value list to match the number of `true` elements in boolean mask.
        // Current implementation might not support this directly; it expects value list length
        // to match the boolean mask length. Let's test the current expectation.
        final s = Series([10, 20, 30, 40], name: 'data_bool_list_val');
        // s[[true, false, true, false]] = [100, 300]; // This would require more advanced logic.
        // Current impl for List<bool> indices expects `value` to be a List of same length as the boolean list.
        // Or a single num for broadcasting.
        // So this specific permutation is not directly supported by the current code structure.
        // `value.length != indices.length` check for List<bool> indices is against `indices.length`
        // not `number of true values in indices`.
        // Let's test what is supported:
        expect(() => s[[true, false, true, false]] = [100, 300],
            throwsArgumentError); // Mismatched lengths

        // Test setting with a list that matches the length of the boolean mask, only 'true' positions get updated
        // This is closer to what the current code handles for List<bool> + List value.
        final s2 = Series([1, 2, 3, 4], name: 's2');
        s2[[true, false, true, false]] = [
          99,
          0,
          88,
          0
        ]; // Value list matches mask length
        expect(s2.data, equals([99, 2, 88, 4])); // Only 99 and 88 applied
      });

      test('set with parent DataFrame updates parent', () {
        var df = DataFrame.fromMap({
          'colA': [1, 2, 3],
          'colB': [4, 5, 6]
        });
        Series s = df['colA'];
        s.setParent(df, 'colA'); // Manually link for test

        s[0] = 100;
        expect(s.data[0], 100);
        expect(df['colA'].data[0], 100); // Check DataFrame is updated

        s[[1, 2]] = [200, 300];
        expect(s.data[1], 200);
        expect(s.data[2], 300);
        expect(df['colA'].data[1], 200);
        expect(df['colA'].data[2], 300);

        s[[true, false, true]] = 55; // Broadcast
        expect(s.data[0], 55);
        expect(s.data[2], 55);
        expect(df['colA'].data[0], 55);
        expect(df['colA'].data[2], 55);
      });
    });

    // Tests for at()
    group('Series.at()', () {
      test('at with existing label', () {
        final s = Series([10, 20, 30], name: 'data', index: ['a', 'b', 'c']);
        expect(s.at('a'), equals(10));
        expect(s.at('c'), equals(30));
      });

      test('at with non-existing label', () {
        final s = Series([10, 20], name: 'data', index: ['a', 'b']);
        expect(() => s.at('x'), throwsArgumentError);
      });

      test('at with default integer index (treated as labels)', () {
        final s = Series([10, 20, 30], name: 'data'); // Index is [0, 1, 2]
        expect(s.at(0), equals(10));
        expect(s.at(1), equals(20));
        expect(() => s.at(3), throwsArgumentError); // Label 3 not found
      });

      test('at on empty series', () {
        final s = Series([], name: 'empty_at', index: []);
        expect(() => s.at('a'), throwsArgumentError);
      });
    });
  });
}
