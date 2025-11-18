import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

// Helper function to filter DataFrame by column value
DataFrame filterByValue(DataFrame df, String column, dynamic value) {
  List<List<dynamic>> filteredData = [];
  List<dynamic> filteredIndex = [];

  for (int i = 0; i < df.rowCount; i++) {
    if (df[column].toList()[i] == value) {
      filteredData.add(df.rows[i]);
      filteredIndex.add(df.index[i]);
    }
  }

  return DataFrame(filteredData,
      columns: df.columns.cast<String>(), index: filteredIndex);
}

void main() {
  group('GroupBy Enhanced Operations', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame([
        ['A', 1, 100, 10.0],
        ['B', 2, 200, 20.0],
        ['A', 3, 150, 15.0],
        ['B', 4, 250, 25.0],
        ['A', 5, 120, 12.0],
        ['C', 6, 300, 30.0],
      ], columns: [
        'group',
        'value',
        'amount',
        'price'
      ]);
    });

    group('transform()', () {
      test('transforms values within groups', () {
        var result = df.groupBy2(['group']).transform((group) {
          // Return a copy of the group
          return group.copy();
        });

        expect(result.rowCount, equals(6));
        expect(result.columns, equals(df.columns));
      });

      test('maintains original row count', () {
        var result = df.groupBy2(['group']).transform((group) => group);
        expect(result.rowCount, equals(df.rowCount));
      });

      test('throws error if transform changes row count', () {
        expect(
          () => df.groupBy2(['group']).transform((group) => group.head(1)),
          throwsArgumentError,
        );
      });
    });

    group('filter()', () {
      test('filters groups by condition', () {
        var result =
            df.groupBy2(['group']).filter((group) => group.rowCount > 1);

        expect(result.rowCount, equals(5)); // A and B groups only
        expect(result['group'].unique().length, equals(2));
      });

      test('filters by group sum', () {
        var result = df.groupBy2(['group']).filter((group) {
          var values = group['value'].toList();
          num sum = 0;
          for (var v in values) {
            if (v is num) sum += v;
          }
          return sum > 5;
        });

        expect(result['group'].unique().contains('A'), isTrue);
        expect(result['group'].unique().contains('B'), isTrue);
      });

      test('returns empty DataFrame when no groups match', () {
        var result =
            df.groupBy2(['group']).filter((group) => group.rowCount > 10);

        expect(result.rowCount, equals(0));
        expect(result.columns, equals(df.columns));
      });
    });

    group('pipe()', () {
      test('chains operations', () {
        var filtered = df
            .groupBy2(['group']).pipe((gb) => gb.filter((g) => g.rowCount > 1));

        var result = filtered.groupBy2(['group']).sum();

        expect(result.rowCount, equals(2)); // A and B groups
      });

      test('allows custom transformations', () {
        var result = df.groupBy2(['group']).pipe((gb) {
          return gb.apply((group) => group.head(2));
        });

        expect(result.rowCount, lessThanOrEqualTo(6));
      });
    });

    group('nth()', () {
      test('gets first row from each group', () {
        var result = df.groupBy2(['group']).nth(0);

        expect(result.rowCount, equals(3)); // A, B, C
        expect(result['value'].toList(), containsAll([1, 2, 6]));
      });

      test('gets second row from each group', () {
        var result = df.groupBy2(['group']).nth(1);

        expect(result.rowCount, equals(2)); // Only A and B have 2+ rows
        expect(result['value'].toList(), containsAll([3, 4]));
      });

      test('gets last row with negative index', () {
        var result = df.groupBy2(['group']).nth(-1);

        expect(result.rowCount, equals(3));
        expect(result['value'].toList(), containsAll([5, 4, 6]));
      });

      test('handles dropna parameter', () {
        var result = df.groupBy2(['group']).nth(5, dropna: false);

        expect(result.rowCount, equals(3)); // All groups, even with nulls
      });
    });

    group('head() and tail()', () {
      test('head() gets first n rows from each group', () {
        var result = df.groupBy2(['group']).head(2);

        expect(result.rowCount, equals(5)); // 2 from A, 2 from B, 1 from C
      });

      test('tail() gets last n rows from each group', () {
        var result = df.groupBy2(['group']).tail(2);

        expect(result.rowCount, equals(5)); // 2 from A, 2 from B, 1 from C
      });

      test('head() with default parameter', () {
        var result = df.groupBy2(['group']).head();

        expect(result.rowCount, equals(6)); // All rows (less than 5 per group)
      });
    });

    group('Cumulative Operations', () {
      test('cumsum() computes cumulative sum', () {
        var result = df.groupBy2(['group']).cumsum(['value']);

        expect(result.rowCount, equals(6));

        // Check group A cumsum: 1, 4, 9
        var groupARows = [];
        for (int i = 0; i < result.rowCount; i++) {
          if (result['group'].toList()[i] == 'A') {
            groupARows.add(result['value'].toList()[i]);
          }
        }
        expect(groupARows, equals([1, 4, 9]));
      });

      test('cumprod() computes cumulative product', () {
        var result = df.groupBy2(['group']).cumprod(['value']);

        // Check group A cumprod: 1, 3, 15
        var groupA = filterByValue(result, 'group', 'A');
        expect(groupA['value'].toList(), equals([1, 3, 15]));
      });

      test('cummax() computes cumulative maximum', () {
        var result = df.groupBy2(['group']).cummax(['value']);

        // Check group A cummax: 1, 3, 5
        var groupA = filterByValue(result, 'group', 'A');
        expect(groupA['value'].toList(), equals([1, 3, 5]));
      });

      test('cummin() computes cumulative minimum', () {
        var result = df.groupBy2(['group']).cummin(['value']);

        // Check group A cummin: 1, 1, 1
        var groupA = filterByValue(result, 'group', 'A');
        expect(groupA['value'].toList(), equals([1, 1, 1]));
      });

      test('cumulative operations on all numeric columns', () {
        var result = df.groupBy2(['group']).cumsum();

        expect(result.columns.contains('value'), isTrue);
        expect(result.columns.contains('amount'), isTrue);
        expect(result.columns.contains('price'), isTrue);
      });

      test('cumulative operations handle null values', () {
        var dfWithNull = DataFrame([
          ['A', 1, 100],
          ['A', null, 200],
          ['A', 3, 150],
        ], columns: [
          'group',
          'value',
          'amount'
        ]);

        var result = dfWithNull.groupBy2(['group']).cumsum(['value']);

        expect(result['value'].toList()[1], isNull);
      });
    });

    group('Aggregation Operations', () {
      test('agg() with single function', () {
        var result = df.groupBy2(['group']).agg('sum');

        expect(result.rowCount, equals(3));
        expect(result.columns.contains('value'), isTrue);
        expect(result.columns.contains('amount'), isTrue);
      });

      test('agg() with multiple functions', () {
        var result = df.groupBy2(['group']).agg(['sum', 'mean', 'count']);

        expect(result.rowCount, equals(3));
        expect(result.columns.contains('value_sum'), isTrue);
        expect(result.columns.contains('value_mean'), isTrue);
        expect(result.columns.contains('value_count'), isTrue);
      });

      test('agg() with column-specific functions', () {
        var result = df.groupBy2(['group']).agg({
          'value': ['sum', 'mean'],
          'amount': 'max',
        });

        expect(result.rowCount, equals(3));
        expect(result.columns.contains('value_sum'), isTrue);
        expect(result.columns.contains('value_mean'), isTrue);
        expect(result.columns.contains('amount_max'), isTrue);
      });

      test('agg() with named aggregations', () {
        var result = df.groupBy2(['group']).agg({
          'total_value': NamedAgg('value', 'sum'),
          'avg_amount': NamedAgg('amount', 'mean'),
          'max_price': NamedAgg('price', 'max'),
        });

        expect(result.rowCount, equals(3));
        expect(result.columns.contains('total_value'), isTrue);
        expect(result.columns.contains('avg_amount'), isTrue);
        expect(result.columns.contains('max_price'), isTrue);
      });

      test('sum() convenience method', () {
        var result = df.groupBy2(['group']).sum();

        expect(result.rowCount, equals(3));
        var groupA = filterByValue(result, 'group', 'A');
        expect(groupA['value'].toList().first, equals(9)); // 1+3+5
      });

      test('mean() convenience method', () {
        var result = df.groupBy2(['group']).mean();

        expect(result.rowCount, equals(3));
        var groupA = filterByValue(result, 'group', 'A');
        expect(groupA['value'].toList().first, equals(3.0)); // (1+3+5)/3
      });

      test('count() convenience method', () {
        var result = df.groupBy2(['group']).count();

        expect(result.rowCount, equals(3));
      });

      test('min() convenience method', () {
        var result = df.groupBy2(['group']).min();

        var groupA = filterByValue(result, 'group', 'A');
        expect(groupA['value'].toList().first, equals(1));
      });

      test('max() convenience method', () {
        var result = df.groupBy2(['group']).max();

        var groupA = filterByValue(result, 'group', 'A');
        expect(groupA['value'].toList().first, equals(5));
      });

      test('std() convenience method', () {
        var result = df.groupBy2(['group']).std();

        expect(result.rowCount, equals(3));
        expect(result.columns.contains('value'), isTrue);
      });

      test('first() convenience method', () {
        var result = df.groupBy2(['group']).first();

        var groupA = filterByValue(result, 'group', 'A');
        expect(groupA['value'].toList().first, equals(1));
      });

      test('last() convenience method', () {
        var result = df.groupBy2(['group']).last();

        var groupA = filterByValue(result, 'group', 'A');
        expect(groupA['value'].toList().first, equals(5));
      });
    });

    group('Utility Methods', () {
      test('ngroups returns number of groups', () {
        var gb = df.groupBy2(['group']);
        expect(gb.ngroups, equals(3));
      });

      test('size() returns group sizes', () {
        var result = df.groupBy2(['group']).size();

        expect(result.rowCount, equals(3));
        expect(result.columns.contains('size'), isTrue);

        var groupA = filterByValue(result, 'group', 'A');
        expect(groupA['size'].toList().first, equals(3));
      });

      test('groups property returns grouped DataFrames', () {
        var gb = df.groupBy2(['group']);
        var groups = gb.groups;

        expect(groups.length, equals(3));
        expect(groups.keys, containsAll(['A', 'B', 'C']));
      });
    });

    group('Multiple Group Columns', () {
      test('groups by multiple columns', () {
        var df2 = DataFrame([
          ['A', 'X', 1],
          ['A', 'Y', 2],
          ['B', 'X', 3],
          ['B', 'Y', 4],
          ['A', 'X', 5],
        ], columns: [
          'group1',
          'group2',
          'value'
        ]);

        var gb = df2.groupBy2(['group1', 'group2']);
        print('Number of groups: ${gb.ngroups}');
        print('Group keys: ${gb.groups.keys}');

        var result = gb.sum();

        print('Result:\n$result');
        print('Row count: ${result.rowCount}');

        expect(result.rowCount, equals(4));
      });

      test('nth() with multiple group columns', () {
        var df2 = DataFrame([
          ['A', 'X', 1],
          ['A', 'X', 2],
          ['A', 'Y', 3],
          ['B', 'X', 4],
        ], columns: [
          'group1',
          'group2',
          'value'
        ]);

        var result = df2.groupBy2(['group1', 'group2']).nth(0);

        expect(result.rowCount, equals(3));
      });
    });

    group('Edge Cases', () {
      test('handles empty DataFrame', () {
        var emptyDf = DataFrame.empty(columns: ['group', 'value']);
        var result = emptyDf.groupBy2(['group']).sum();

        expect(result.rowCount, equals(0));
      });

      test('handles single group', () {
        var singleGroup = DataFrame([
          ['A', 1],
          ['A', 2],
          ['A', 3],
        ], columns: [
          'group',
          'value'
        ]);

        var result = singleGroup.groupBy2(['group']).sum();

        expect(result.rowCount, equals(1));
        expect(result['value'].toList().first, equals(6));
      });

      test('throws error for non-existent column', () {
        expect(
          () => df.groupBy2(['nonexistent']),
          throwsArgumentError,
        );
      });

      test('handles all null values in group', () {
        var dfWithNulls = DataFrame([
          ['A', null],
          ['A', null],
          ['B', 1],
        ], columns: [
          'group',
          'value'
        ]);

        var result = dfWithNulls.groupBy2(['group']).sum();

        expect(result.rowCount, equals(2));
      });
    });

    group('Integration Tests', () {
      test('complex pipeline with multiple operations', () {
        var filtered = df.groupBy2(['group']).filter((g) => g.rowCount > 1);

        var transformed =
            filtered.groupBy2(['group']).transform((g) => g.copy());

        var result = transformed.groupBy2(['group']).head(2);

        expect(result.rowCount, greaterThan(0));
      });

      test('cumulative operations followed by aggregation', () {
        var cumsum = df.groupBy2(['group']).cumsum(['value']);
        var result = cumsum.groupBy2(['group']).max();

        expect(result.rowCount, equals(3));
      });

      test('filter then aggregate', () {
        var result = df.groupBy2(['group']).filter((g) {
          var values = g['value'].toList();
          num sum = 0;
          for (var v in values) {
            if (v is num) sum += v;
          }
          return sum > 5;
        }).groupBy2(['group']).agg(['sum', 'mean']);

        expect(result.rowCount, greaterThan(0));
      });
    });

    group('Performance Tests', () {
      test('handles large groups efficiently', () {
        var largeDf = DataFrame(
          List.generate(1000, (i) => ['Group${i % 10}', i, i * 2]),
          columns: ['group', 'value', 'amount'],
        );

        var stopwatch = Stopwatch()..start();
        var result = largeDf.groupBy2(['group']).sum();
        stopwatch.stop();

        expect(result.rowCount, equals(10));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('cumulative operations are efficient', () {
        var largeDf = DataFrame(
          List.generate(1000, (i) => ['Group${i % 5}', i]),
          columns: ['group', 'value'],
        );

        var stopwatch = Stopwatch()..start();
        var result = largeDf.groupBy2(['group']).cumsum();
        stopwatch.stop();

        expect(result.rowCount, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
