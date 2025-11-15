import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('Categorical Enhancements Tests', () {
    group('cat.reorderCategories()', () {
      test('reorders categories', () {
        final s = Series(['a', 'b', 'c', 'a'], name: 'data');
        s.astype('category');

        final original = s.cat!.categories;
        expect(original, ['a', 'b', 'c']);

        s.cat!.reorderCategories(['c', 'b', 'a']);
        expect(s.cat!.categories, ['c', 'b', 'a']);
        expect(s.data, ['a', 'b', 'c', 'a']); // Data unchanged
      });

      test('throws if missing categories', () {
        final s = Series(['a', 'b', 'c'], name: 'data');
        s.astype('category');

        expect(
          () => s.cat!.reorderCategories(['a', 'b']),
          throwsArgumentError,
        );
      });

      test('can set ordered flag', () {
        final s = Series(['a', 'b', 'c'], name: 'data');
        s.astype('category');

        expect(s.cat!.ordered, false);
        s.cat!.reorderCategories(['a', 'b', 'c'], ordered: true);
        expect(s.cat!.ordered, true);
      });

      test('works with inplace=false', () {
        final s = Series(['a', 'b', 'c'], name: 'data');
        s.astype('category');

        final s2 = s.cat!.reorderCategories(['c', 'b', 'a'], inplace: false);
        expect(s.cat!.categories, ['a', 'b', 'c']); // Original unchanged
        expect(s2.cat!.categories, ['c', 'b', 'a']); // New series changed
      });
    });

    group('cat.addCategories()', () {
      test('adds new categories', () {
        final s = Series(['a', 'b'], name: 'data');
        s.astype('category');

        expect(s.cat!.categories, ['a', 'b']);
        s.cat!.addCategories(['c', 'd']);
        expect(s.cat!.categories, ['a', 'b', 'c', 'd']);
      });

      test('ignores duplicate categories', () {
        final s = Series(['a', 'b'], name: 'data');
        s.astype('category');

        s.cat!.addCategories(['b', 'c']);
        expect(s.cat!.categories, ['a', 'b', 'c']);
      });

      test('works with inplace=false', () {
        final s = Series(['a', 'b'], name: 'data');
        s.astype('category');

        final s2 = s.cat!.addCategories(['c'], inplace: false);
        expect(s.cat!.categories, ['a', 'b']); // Original unchanged
        expect(s2.cat!.categories, ['a', 'b', 'c']); // New series changed
      });
    });

    group('cat.removeCategories()', () {
      test('removes unused categories', () {
        final s = Series(['a', 'b'], name: 'data');
        s.astype('category', categories: ['a', 'b', 'c', 'd']);

        expect(s.cat!.categories, ['a', 'b', 'c', 'd']);
        s.cat!.removeCategories(['c', 'd']);
        expect(s.cat!.categories, ['a', 'b']);
      });

      test('throws if removing used category', () {
        final s = Series(['a', 'b', 'c'], name: 'data');
        s.astype('category');

        expect(
          () => s.cat!.removeCategories(['b']),
          throwsArgumentError,
        );
      });

      test('works with inplace=false', () {
        final s = Series(['a', 'b'], name: 'data');
        s.astype('category', categories: ['a', 'b', 'c']);

        final s2 = s.cat!.removeCategories(['c'], inplace: false);
        expect(s.cat!.categories, ['a', 'b', 'c']); // Original unchanged
        expect(s2.cat!.categories, ['a', 'b']); // New series changed
      });
    });

    group('cat.renameCategories()', () {
      test('renames categories', () {
        final s = Series(['a', 'b', 'c'], name: 'data');
        s.astype('category');

        s.cat!.renameCategories({'a': 'A', 'b': 'B'});
        expect(s.cat!.categories, ['A', 'B', 'c']);
        expect(s.data, ['A', 'B', 'c']);
      });

      test('works with inplace=false', () {
        final s = Series(['a', 'b'], name: 'data');
        s.astype('category');

        final s2 = s.cat!.renameCategories({'a': 'A'}, inplace: false);
        expect(s.cat!.categories, ['a', 'b']); // Original unchanged
        expect(s2.cat!.categories, ['A', 'b']); // New series changed
      });
    });

    group('cat.setCategories()', () {
      test('sets new categories (recode mode)', () {
        final s = Series(['a', 'b', 'c'], name: 'data');
        s.astype('category');

        s.cat!.setCategories(['a', 'b', 'd']);
        expect(s.cat!.categories, ['a', 'b', 'd']);
        expect(s.data[0], 'a');
        expect(s.data[1], 'b');
        expect(s.data[2], isNull); // 'c' not in new categories
      });

      test('sets new categories (rename mode)', () {
        final s = Series(['a', 'b', 'c'], name: 'data');
        s.astype('category');

        s.cat!.setCategories(['x', 'y', 'z'], rename: true);
        expect(s.cat!.categories, ['x', 'y', 'z']);
        expect(s.data, ['x', 'y', 'z']); // Values renamed
      });

      test('throws in rename mode if length mismatch', () {
        final s = Series(['a', 'b', 'c'], name: 'data');
        s.astype('category');

        expect(
          () => s.cat!.setCategories(['x', 'y'], rename: true),
          throwsArgumentError,
        );
      });

      test('can set ordered flag', () {
        final s = Series(['a', 'b'], name: 'data');
        s.astype('category');

        s.cat!.setCategories(['a', 'b'], ordered: true);
        expect(s.cat!.ordered, true);
      });

      test('works with inplace=false', () {
        final s = Series(['a', 'b', 'c'], name: 'data');
        s.astype('category');

        final s2 = s.cat!.setCategories(['a', 'b'], inplace: false);
        expect(s.cat!.categories, ['a', 'b', 'c']); // Original unchanged
        expect(s2.cat!.categories, ['a', 'b']); // New series changed
      });
    });

    group('cat.asOrdered() / asUnordered()', () {
      test('converts to ordered', () {
        final s = Series(['low', 'high', 'medium'], name: 'priority');
        s.astype('category');

        expect(s.cat!.ordered, false);
        s.cat!.asOrdered();
        expect(s.cat!.ordered, true);
      });

      test('converts to unordered', () {
        final s = Series(['low', 'high', 'medium'], name: 'priority');
        s.astype('category', ordered: true);

        expect(s.cat!.ordered, true);
        s.cat!.asUnordered();
        expect(s.cat!.ordered, false);
      });

      test('works with inplace=false', () {
        final s = Series(['a', 'b'], name: 'data');
        s.astype('category');

        final s2 = s.cat!.asOrdered(inplace: false);
        expect(s.cat!.ordered, false); // Original unchanged
        expect(s2.cat!.ordered, true); // New series changed
      });
    });

    group('cat.min() / max()', () {
      test('returns min for ordered categorical', () {
        final s = Series(['medium', 'high', 'low', 'high'], name: 'priority');
        s.astype('category',
            categories: ['low', 'medium', 'high'], ordered: true);

        expect(s.cat!.min(), 'low');
      });

      test('returns max for ordered categorical', () {
        final s = Series(['medium', 'high', 'low', 'high'], name: 'priority');
        s.astype('category',
            categories: ['low', 'medium', 'high'], ordered: true);

        expect(s.cat!.max(), 'high');
      });

      test('throws for unordered categorical', () {
        final s = Series(['a', 'b', 'c'], name: 'data');
        s.astype('category');

        expect(() => s.cat!.min(), throwsStateError);
        expect(() => s.cat!.max(), throwsStateError);
      });

      test('handles all null values', () {
        final s = Series([null, null], name: 'data');
        s.astype('category', categories: ['a', 'b'], ordered: true);

        expect(s.cat!.min(), isNull);
        expect(s.cat!.max(), isNull);
      });
    });

    group('cat.memoryUsage()', () {
      test('calculates memory usage', () {
        final values = ['A', 'B', 'A', 'C', 'A', 'B'];
        final repeated = <String>[];
        for (int i = 0; i < 100; i++) {
          repeated.addAll(values);
        }
        final s = Series(repeated, name: 'data');
        s.astype('category');

        final usage = s.cat!.memoryUsage();

        expect(usage['codes'], isA<int>());
        expect(usage['categories'], isA<int>());
        expect(usage['total'], isA<int>());
        expect(usage['object_equivalent'], isA<int>());
        expect(usage['savings'], isA<int>());
        expect(usage['savings_percent'], isA<String>());

        // Categorical should save memory for repeated values
        expect(usage['savings'], greaterThan(0));
      });

      test('shows savings percentage', () {
        final values = ['A', 'B', 'A', 'B'];
        final repeated = <String>[];
        for (int i = 0; i < 50; i++) {
          repeated.addAll(values);
        }
        final s = Series(repeated, name: 'data');
        s.astype('category');

        final usage = s.cat!.memoryUsage();
        final savingsPercent = double.parse(usage['savings_percent']);

        // Should have significant savings with repeated values
        expect(savingsPercent, greaterThan(0));
      });

      test('works with numeric categories', () {
        final s = Series([1, 2, 1, 2, 1, 2], name: 'data');
        s.astype('category');

        final usage = s.cat!.memoryUsage();
        expect(usage['total'], isA<int>());
      });
    });

    group('Integration Tests', () {
      test('chaining operations', () {
        final s = Series(['a', 'b', 'c', 'a', 'b'], name: 'data');
        s.astype('category');

        s.cat!.addCategories(['d']);
        s.cat!.reorderCategories(['d', 'c', 'b', 'a']);
        s.cat!.asOrdered();

        expect(s.cat!.categories, ['d', 'c', 'b', 'a']);
        expect(s.cat!.ordered, true);
      });

      test('ordered categorical comparison', () {
        final s = Series(['low', 'high', 'medium', 'low'], name: 'priority');
        s.astype('category',
            categories: ['low', 'medium', 'high'], ordered: true);

        expect(s.cat!.min(), 'low');
        expect(s.cat!.max(), 'high');
        expect(s.cat!.ordered, true);
      });

      test('memory efficiency with large dataset', () {
        // Create a large dataset with few unique values
        final values = <String>[];
        for (int i = 0; i < 1000; i++) {
          values.add(['A', 'B', 'C', 'D', 'E'][i % 5]);
        }

        final s = Series(values, name: 'data');
        s.astype('category');

        final usage = s.cat!.memoryUsage();
        final savingsPercent = double.parse(usage['savings_percent']);

        // Should have very significant savings
        expect(savingsPercent, greaterThan(50));
      });
    });
  });
}
