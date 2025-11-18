import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('Functional Programming Tests', () {
    group('apply()', () {
      test('applies function to columns (axis=0)', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.apply((col) => (col as Series).sum(), axis: 0);
        expect(result, isA<Series>());
        expect(result.data, [6, 15]); // Sum of each column
      });

      test('applies function to rows (axis=1)', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.apply((row) => (row as Series).sum(), axis: 1);
        expect(result, isA<Series>());
        expect(result.data, [5, 7, 9]); // Sum of each row
      });

      test('works with axis as string', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.apply((col) {
          final s = col as Series;
          return s.sum() / s.length;
        }, axis: 'index');
        expect(result, isA<Series>());
        expect(result.data, [2.0, 5.0]); // Mean of each column
      });
    });

    group('applymap()', () {
      test('applies function to each element', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.applymap((x) => x * 2);
        expect(result['A'].data, [2, 4, 6]);
        expect(result['B'].data, [8, 10, 12]);
      });

      test('converts types', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.applymap((x) => 'Value: $x');
        expect(result['A'].data, ['Value: 1', 'Value: 2', 'Value: 3']);
        expect(result['B'].data, ['Value: 4', 'Value: 5', 'Value: 6']);
      });

      test('handles null values with naAction=ignore', () {
        final df = DataFrame.fromMap({
          'A': [1, null, 3],
          'B': [4, 5, null],
        });

        final result = df.applymap((x) => x * 2, naAction: 'ignore');
        expect(result['A'].data[0], 2);
        expect(result['A'].data[1], isNull);
        expect(result['A'].data[2], 6);
      });

      test('processes null values without naAction', () {
        final df = DataFrame.fromMap({
          'A': [1, null, 3],
          'B': [4, 5, null],
        });

        final result = df.applymap((x) => x ?? 0);
        expect(result['A'].data, [1, 0, 3]);
        expect(result['B'].data, [4, 5, 0]);
      });
    });

    group('agg()', () {
      test('aggregates with single function', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.agg((col) => (col as Series).sum());
        expect(result, isA<Series>());
        expect(result.data, [6, 15]);
      });

      test('aggregates with multiple functions', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.agg([
          (col) => (col as Series).sum(),
          (col) => (col as Series).max(),
        ]);

        expect(result, isA<DataFrame>());
        expect(result.rowCount, 2);
        expect(result.columnCount, 2);
      });

      test('aggregates with different functions per column', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.agg({
          'A': (col) => (col as Series).sum(),
          'B': (col) => (col as Series).min(),
        });

        expect(result, isA<Series>());
        expect(result.data[0], 6); // Sum of A
        expect(result.data[1], 4); // Min of B
      });

      test('throws on non-existent column', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
        });

        expect(
          () => df.agg({'B': (col) => (col as Series).sum()}),
          throwsArgumentError,
        );
      });
    });

    group('transform()', () {
      test('transforms columns', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.transform((col) {
          return Series(
            col.data.map((x) => x * 2).toList(),
            name: col.name,
          );
        });

        expect(result, isA<DataFrame>());
        expect(result['A'].data, [2, 4, 6]);
        expect(result['B'].data, [8, 10, 12]);
      });

      test('transforms rows', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.transform(
          (row) {
            final sum = row.sum();
            return Series(
              row.data.map((x) => x / sum).toList(),
              name: row.name,
            );
          },
          axis: 1,
        );

        expect(result, isA<DataFrame>());

        // Each row should sum to 1 (normalized)
        for (int i = 0; i < result.rowCount; i++) {
          final rowSum =
              result.rows[i].fold<num>(0, (sum, val) => sum + (val as num));
          expect(rowSum, closeTo(1.0, 0.0001));
        }
      });

      test('returns same shape as input', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
          'C': [7, 8, 9],
        });

        final result = df.transform((col) {
          return Series(
            col.data.map((x) => x * 2).toList(),
            name: col.name,
          );
        });

        expect(result.shape.rows, df.shape.rows);
        expect(result.shape.columns, df.shape.columns);
      });

      test('throws if function returns wrong type', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
        });

        expect(
          () => df.transform((col) => 42), // Returns int instead of Series/List
          throwsArgumentError,
        );
      });
    });

    group('pipe()', () {
      test('chains single operation', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df.pipe((df) => df.applymap((x) => x * 2));

        expect(result, isA<DataFrame>());
        expect(result['A'].data, [2, 4, 6]);
      });

      test('chains multiple operations', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df
            .pipe((df) => df.applymap((x) => x * 2))
            .pipe((df) => df.applymap((x) => x + 1));

        expect(result, isA<DataFrame>());
        expect(result['A'].data, [3, 5, 7]); // (1*2)+1, (2*2)+1, (3*2)+1
      });

      test('works with custom functions', () {
        DataFrame addColumn(DataFrame df, String name, List values) {
          final newDf = df.copy();
          newDf[name] = values;
          return newDf;
        }

        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
        });

        final result = df.pipe((df) => addColumn(df, 'B', [4, 5, 6]));

        expect(result.columnCount, 2);
        expect(result['B'].data, [4, 5, 6]);
      });

      test('can return non-DataFrame', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result =
            df.pipe((df) => df.apply((col) => (col as Series).sum(), axis: 0));

        expect(result, isA<Series>());
      });
    });

    group('Integration Tests', () {
      test('applymap with agg', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df
            .applymap((x) => x * x) // Square all values
            .agg((col) => (col as Series).sum()); // Sum each column

        expect(result.data, [14, 77]); // 1+4+9=14, 16+25+36=77
      });

      test('pipe with transform', () {
        final df = DataFrame.fromMap({
          'A': [1, 2, 3],
          'B': [4, 5, 6],
        });

        final result = df
            .pipe((df) => df.applymap((x) => x * 2))
            .pipe((df) => df.transform((col) => Series(
                  col.data.map((x) => x + 10).toList(),
                  name: col.name,
                )));

        expect(result['A'].data, [12, 14, 16]); // (1*2)+10, (2*2)+10, (3*2)+10
      });
    });
  });
}
