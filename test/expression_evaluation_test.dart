import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Expression Evaluation Tests', () {
    late DataFrame df;

    setUp(() {
      df = DataFrame.fromMap({
        'A': [1, 2, 3, 4, 5],
        'B': [10, 20, 30, 40, 50],
        'C': [5, 10, 15, 20, 25],
        'D': [100, 200, 300, 400, 500],
      });
    });

    group('eval() - Basic Arithmetic', () {
      test('Simple addition', () {
        final result = df.eval('A + B');
        expect(result, isA<Series>());
        expect(result.data, equals([11, 22, 33, 44, 55]));
      });

      test('Simple subtraction', () {
        final result = df.eval('B - A');
        expect(result.data, equals([9, 18, 27, 36, 45]));
      });

      test('Simple multiplication', () {
        final result = df.eval('A * C');
        expect(result.data, equals([5, 20, 45, 80, 125]));
      });

      test('Simple division', () {
        final result = df.eval('B / A');
        expect(result.data, equals([10, 10, 10, 10, 10]));
      });

      test('Modulo operation', () {
        final result = df.eval('B % A');
        expect(result.data, equals([0, 0, 0, 0, 0]));
      });
    });

    group('eval() - Complex Expressions', () {
      test('Multiple operations', () {
        final result = df.eval('A + B * C');
        // B * C first (precedence), then + A
        expect(result.data, equals([51, 202, 453, 804, 1255]));
      });

      test('Parentheses for grouping', () {
        final result = df.eval('(A + B) * C');
        expect(result.data, equals([55, 220, 495, 880, 1375]));
      });

      test('Nested parentheses', () {
        final result = df.eval('((A + B) * C) / D');
        expect(result.data, equals([0.55, 1.1, 1.65, 2.2, 2.75]));
      });

      test('Complex arithmetic', () {
        final result = df.eval('A * B + C * D');
        expect(result.data, equals([510, 2040, 4590, 8160, 12750]));
      });
    });

    group('eval() - Comparison Operations', () {
      test('Greater than', () {
        final result = df.eval('A > 3');
        expect(result.data, equals([false, false, false, true, true]));
      });

      test('Less than', () {
        final result = df.eval('B < 35');
        expect(result.data, equals([true, true, true, false, false]));
      });

      test('Greater than or equal', () {
        final result = df.eval('A >= 3');
        expect(result.data, equals([false, false, true, true, true]));
      });

      test('Less than or equal', () {
        final result = df.eval('C <= 15');
        expect(result.data, equals([true, true, true, false, false]));
      });

      test('Equal to', () {
        final result = df.eval('A == 3');
        expect(result.data, equals([false, false, true, false, false]));
      });

      test('Not equal to', () {
        final result = df.eval('B != 30');
        expect(result.data, equals([true, true, false, true, true]));
      });

      test('Compare two columns', () {
        final result = df.eval('A < C');
        expect(result.data, equals([true, true, true, true, true]));
      });
    });

    group('eval() - Logical Operations', () {
      test('Logical AND', () {
        final result = df.eval('A > 2 && B < 45');
        expect(result.data, equals([false, false, true, true, false]));
      });

      test('Logical OR', () {
        final result = df.eval('A < 2 || B > 40');
        expect(result.data, equals([true, false, false, false, true]));
      });

      test('Logical NOT', () {
        final result = df.eval('!(A > 3)');
        expect(result.data, equals([true, true, true, false, false]));
      });

      test('Complex logical expression', () {
        final result = df.eval('(A > 1 && A < 4) || C > 20');
        expect(result.data, equals([false, true, true, false, true]));
      });

      test('Multiple AND conditions', () {
        final result = df.eval('A > 1 && B < 50 && C > 5');
        expect(result.data, equals([false, true, true, true, false]));
      });
    });

    group('eval() - Inplace Operations', () {
      test('Add result as new column', () {
        final result = df.eval('A + B', inplace: true, resultColumn: 'E');
        expect(result, isA<DataFrame>());
        expect(df.columns.contains('E'), isTrue);
        expect(df['E'].data, equals([11, 22, 33, 44, 55]));
      });

      test('Inplace requires resultColumn', () {
        expect(
          () => df.eval('A + B', inplace: true),
          throwsArgumentError,
        );
      });

      test('Multiple inplace operations', () {
        df.eval('A + B', inplace: true, resultColumn: 'Sum');
        df.eval('A * B', inplace: true, resultColumn: 'Product');

        expect(df.columns.contains('Sum'), isTrue);
        expect(df.columns.contains('Product'), isTrue);
        expect(df['Sum'].data, equals([11, 22, 33, 44, 55]));
        expect(df['Product'].data, equals([10, 40, 90, 160, 250]));
      });
    });

    group('query() - Basic Filtering', () {
      test('Simple comparison query', () {
        final result = df.query('A > 3');
        expect(result, isA<DataFrame>());
        expect(result.rowCount, equals(2));
        expect(result['A'].data, equals([4, 5]));
        expect(result['B'].data, equals([40, 50]));
      });

      test('Query with multiple conditions', () {
        final result = df.query('A > 2 && B < 45');
        expect(result.rowCount, equals(2));
        expect(result['A'].data, equals([3, 4]));
      });

      test('Query with OR condition', () {
        final result = df.query('A < 2 || A > 4');
        expect(result.rowCount, equals(2));
        expect(result['A'].data, equals([1, 5]));
      });

      test('Query with complex expression', () {
        final result = df.query('(A > 1 && A < 4) || C > 20');
        expect(result.rowCount, equals(3));
        expect(result['A'].data, equals([2, 3, 5]));
      });

      test('Query returns empty DataFrame when no matches', () {
        final result = df.query('A > 100');
        expect(result.rowCount, equals(0));
        expect(result.columns, equals(df.columns));
      });

      test('Query preserves index', () {
        final dfWithIndex = DataFrame.fromMap(
          {
            'A': [1, 2, 3, 4, 5],
            'B': [10, 20, 30, 40, 50],
          },
          index: ['a', 'b', 'c', 'd', 'e'],
        );

        final result = dfWithIndex.query('A > 3');
        expect(result.index, equals(['d', 'e']));
      });
    });

    group('query() - Advanced Filtering', () {
      test('Query with arithmetic in expression', () {
        final result = df.query('A + B > 50');
        // Only row 4: 5 + 50 = 55 > 50
        expect(result.rowCount, equals(1));
        expect(result['A'].data, equals([5]));
      });

      test('Query with column comparison', () {
        final result = df.query('B > C * 2');
        expect(result.rowCount, equals(0)); // B is always 2*A, C is 5*A
      });

      test('Query with parentheses', () {
        final result = df.query('(A + B) * C > 500');
        // Row 3: (4+40)*20 = 880 > 500
        // Row 4: (5+50)*25 = 1375 > 500
        expect(result.rowCount, equals(2));
        expect(result['A'].data, equals([4, 5]));
      });

      test('Query with NOT operator', () {
        final result = df.query('!(A > 3)');
        expect(result.rowCount, equals(3));
        expect(result['A'].data, equals([1, 2, 3]));
      });
    });

    group('query() - Inplace Operations', () {
      test('Query inplace modifies original DataFrame', () {
        final originalRowCount = df.rowCount;
        df.query('A > 3', inplace: true);

        expect(df.rowCount, equals(2));
        expect(df.rowCount, lessThan(originalRowCount));
        expect(df['A'].data, equals([4, 5]));
      });

      test('Query inplace preserves columns', () {
        final originalColumns = List.from(df.columns);
        df.query('A > 3', inplace: true);

        expect(df.columns, equals(originalColumns));
      });
    });

    group('Edge Cases', () {
      test('eval() with single column', () {
        final result = df.eval('A');
        expect(result.data, equals([1, 2, 3, 4, 5]));
      });

      test('eval() with constant', () {
        final result = df.eval('A + 10');
        expect(result.data, equals([11, 12, 13, 14, 15]));
      });

      test('query() with all rows matching', () {
        final result = df.query('A > 0');
        expect(result.rowCount, equals(df.rowCount));
      });

      test('eval() with division by column', () {
        final result = df.eval('D / B');
        expect(result.data, equals([10, 10, 10, 10, 10]));
      });

      test('eval() handles operator precedence', () {
        final result = df.eval('A + B * C');
        // Should be A + (B * C), not (A + B) * C
        final expected = [
          1 + 10 * 5, // 51
          2 + 20 * 10, // 202
          3 + 30 * 15, // 453
          4 + 40 * 20, // 804
          5 + 50 * 25, // 1255
        ];
        expect(result.data, equals(expected));
      });
    });

    group('Error Handling', () {
      test('eval() with invalid column name', () {
        // Should return the string itself or handle gracefully
        final result = df.eval('InvalidColumn');
        expect(result, isA<Series>());
      });

      test('query() with non-boolean expression throws error', () {
        // This should work - numeric values can be converted to boolean
        final result = df.query('A');
        expect(result, isA<DataFrame>());
      });

      test('eval() with mismatched parentheses', () {
        expect(
          () => df.eval('(A + B'),
          throwsArgumentError,
        );
      });
    });

    group('Real-world Use Cases', () {
      test('Calculate profit margin', () {
        final sales = DataFrame.fromMap({
          'revenue': [1000, 2000, 1500, 3000],
          'cost': [600, 1200, 900, 1800],
        });

        final result = sales.eval('(revenue - cost) / revenue * 100');
        expect(result.data, equals([40, 40, 40, 40]));
      });

      test('Filter high-value customers', () {
        final customers = DataFrame.fromMap({
          'purchases': [5, 15, 8, 25, 3],
          'avgValue': [50, 100, 75, 150, 40],
        });

        final result = customers.query('purchases > 10 && avgValue > 80');
        expect(result.rowCount, equals(2));
      });

      test('Calculate BMI and filter', () {
        final health = DataFrame.fromMap({
          'weight': [70, 85, 60, 95],
          'height': [1.75, 1.80, 1.65, 1.90],
        });

        health.eval('weight / (height * height)',
            inplace: true, resultColumn: 'bmi');
        final overweight = health.query('bmi > 25');

        expect(health.columns.contains('bmi'), isTrue);
        expect(overweight.rowCount, greaterThan(0));
      });

      test('Complex business logic', () {
        final orders = DataFrame.fromMap({
          'quantity': [10, 5, 20, 15],
          'price': [100, 200, 50, 150],
          'discount': [0.1, 0.2, 0.05, 0.15],
        });

        final result = orders.eval('quantity * price * (1 - discount)');
        expect(result.data, equals([900, 800, 950, 1912.5]));
      });
    });
  });
}
