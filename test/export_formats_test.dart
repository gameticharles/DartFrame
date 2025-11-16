import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Export Formats', () {
    group('toLatex()', () {
      test('basic LaTeX table', () {
        var df = DataFrame([
          ['Alice', 25],
          ['Bob', 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var latex = df.toLatex();

        expect(latex, contains('\\begin{table}'));
        expect(latex, contains('\\begin{tabular}'));
        expect(latex, contains('\\end{tabular}'));
        expect(latex, contains('\\end{table}'));
        expect(latex, contains('Name'));
        expect(latex, contains('Age'));
        expect(latex, contains('Alice'));
        expect(latex, contains('Bob'));
      });

      test('LaTeX with caption and label', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var latex = df.toLatex(
          caption: 'Test Table',
          label: 'tab:test',
        );

        expect(latex, contains('\\caption{Test Table}'));
        expect(latex, contains('\\label{tab:test}'));
      });

      test('LaTeX without index', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var latex = df.toLatex(index: false);

        expect(latex, contains('A'));
        expect(latex, contains('B'));
        // Should have 2 columns (no index column)
        expect(latex, contains('{ll}'));
      });

      test('LaTeX without header', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var latex = df.toLatex(header: false);

        // Should not have bold header
        expect(latex.contains('\\textbf{A}'), isFalse);
      });

      test('LaTeX with escape', () {
        var df = DataFrame([
          ['A & B', 50],
        ], columns: [
          'Name',
          'Value'
        ]);

        var latex = df.toLatex(escape: true);

        expect(latex, contains('\\&'));
      });

      test('LaTeX without escape', () {
        var df = DataFrame([
          ['A & B', 50],
        ], columns: [
          'Name',
          'Value'
        ]);

        var latex = df.toLatex(escape: false);

        expect(latex, contains('A & B'));
      });

      test('LaTeX longtable format', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var latex = df.toLatex(longtable: true);

        expect(latex, contains('\\begin{longtable}'));
        expect(latex, contains('\\end{longtable}'));
        expect(latex.contains('\\begin{table}'), isFalse);
      });

      test('LaTeX with custom column format', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var latex = df.toLatex(columnFormat: 'lrc');

        expect(latex, contains('{lrc}'));
      });

      test('LaTeX escapes special characters', () {
        var df = DataFrame([
          ['\$100', '50%'],
        ], columns: [
          'Price',
          'Discount'
        ]);

        var latex = df.toLatex(escape: true);

        expect(latex, contains('\\\$'));
        expect(latex, contains('\\%'));
      });
    });

    group('toMarkdown()', () {
      test('basic Markdown table (pipe format)', () {
        var df = DataFrame([
          ['Alice', 25],
          ['Bob', 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var markdown = df.toMarkdown();

        expect(markdown, contains('| Name | Age |'));
        expect(markdown, contains('| Alice | 25 |'));
        expect(markdown, contains('| Bob | 30 |'));
        expect(markdown, contains(':---'));
      });

      test('Markdown without index', () {
        var df = DataFrame([
          ['Alice', 25],
        ], columns: [
          'Name',
          'Age'
        ]);

        var markdown = df.toMarkdown(index: false);

        expect(markdown, contains('| Name | Age |'));
        expect(markdown, contains('| Alice | 25 |'));
      });

      test('Markdown with center alignment', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var markdown = df.toMarkdown(align: 'center');

        expect(markdown, contains(':---:'));
      });

      test('Markdown with right alignment', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var markdown = df.toMarkdown(align: 'right');

        expect(markdown, contains('---:'));
      });

      test('Markdown with float formatting', () {
        var df = DataFrame([
          [1.23456],
        ], columns: [
          'Value'
        ]);

        var markdown = df.toMarkdown(floatfmt: '.2f');

        expect(markdown, contains('1.23'));
        expect(markdown.contains('1.23456'), isFalse);
      });

      test('Markdown with max column width', () {
        var df = DataFrame([
          ['This is a very long string that should be truncated'],
        ], columns: [
          'Text'
        ]);

        var markdown = df.toMarkdown(maxColWidth: 20);

        expect(markdown, contains('...'));
      });

      test('Markdown simple format', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var markdown = df.toMarkdown(tablefmt: 'simple');

        expect(markdown, contains('A'));
        expect(markdown, contains('B'));
        expect(markdown.contains('|'), isFalse);
      });

      test('Markdown with mixed alignment', () {
        var df = DataFrame([
          [1, 2, 3],
        ], columns: [
          'A',
          'B',
          'C'
        ]);

        var markdown = df.toMarkdown(
          align: ['left', 'center', 'right'],
          index: false,
        );

        expect(markdown, contains(':---'));
        expect(markdown, contains(':---:'));
        expect(markdown, contains('---:'));
      });
    });

    group('toStringFormatted()', () {
      test('basic formatted string', () {
        var df = DataFrame([
          ['Alice', 25],
          ['Bob', 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var formatted = df.toStringFormatted();

        expect(formatted, contains('Name'));
        expect(formatted, contains('Age'));
        expect(formatted, contains('Alice'));
        expect(formatted, contains('Bob'));
        expect(formatted, contains('[2 rows x 2 columns]'));
      });

      test('formatted string without index', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var formatted = df.toStringFormatted(index: false);

        expect(formatted, contains('A'));
        expect(formatted, contains('B'));
      });

      test('formatted string without header', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var formatted = df.toStringFormatted(header: false);

        expect(formatted.contains('A'), isFalse);
        expect(formatted.contains('B'), isFalse);
      });

      test('formatted string with max rows', () {
        var df = DataFrame(
          List.generate(100, (i) => [i, i * 2]),
          columns: ['A', 'B'],
        );

        var formatted = df.toStringFormatted(maxRows: 10);

        expect(formatted, contains('...'));
        expect(formatted, contains('[100 rows x 2 columns]'));
      });

      test('formatted string with max columns', () {
        var df = DataFrame([
          List.generate(30, (i) => i),
        ], columns: List.generate(30, (i) => 'Col$i'));

        var formatted = df.toStringFormatted(maxCols: 10);

        expect(formatted, contains('...'));
        expect(formatted, contains('[1 rows x 30 columns]'));
      });

      test('formatted string with float format', () {
        var df = DataFrame([
          [1.23456],
        ], columns: [
          'Value'
        ]);

        var formatted = df.toStringFormatted(floatFormat: '.2f');

        expect(formatted, contains('1.23'));
      });

      test('formatted string with max column width', () {
        var df = DataFrame([
          ['This is a very long string'],
        ], columns: [
          'Text'
        ]);

        var formatted = df.toStringFormatted(maxColWidth: 10);

        expect(formatted, isNotNull);
      });

      test('formatted string with empty DataFrame', () {
        var df = DataFrame([], columns: ['A', 'B']);

        var formatted = df.toStringFormatted();

        expect(formatted, contains('[0 rows x 2 columns]'));
      });
    });

    group('toRecords()', () {
      test('basic records conversion', () {
        var df = DataFrame([
          ['Alice', 25],
          ['Bob', 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var records = df.toRecords();

        expect(records.length, equals(2));
        expect(records[0]['Name'], equals('Alice'));
        expect(records[0]['Age'], equals(25));
        expect(records[1]['Name'], equals('Bob'));
        expect(records[1]['Age'], equals(30));
      });

      test('records with index', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var records = df.toRecords(index: true);

        expect(records[0].containsKey('index'), isTrue);
        expect(records[0]['index'], equals(0));
      });

      test('records with custom index name', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var records = df.toRecords(index: true, indexName: 'id');

        expect(records[0].containsKey('id'), isTrue);
        expect(records[0]['id'], equals(0));
      });

      test('records with null values', () {
        var df = DataFrame([
          ['Alice', null],
          [null, 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var records = df.toRecords();

        expect(records[0]['Age'], isNull);
        expect(records[1]['Name'], isNull);
      });

      test('records with mixed types', () {
        var df = DataFrame([
          ['Alice', 25, 50000.50, true],
        ], columns: [
          'Name',
          'Age',
          'Salary',
          'Active'
        ]);

        var records = df.toRecords();

        expect(records[0]['Name'], isA<String>());
        expect(records[0]['Age'], isA<int>());
        expect(records[0]['Salary'], isA<double>());
        expect(records[0]['Active'], isA<bool>());
      });

      test('records with empty DataFrame', () {
        var df = DataFrame([], columns: ['A', 'B']);

        var records = df.toRecords();

        expect(records.isEmpty, isTrue);
      });

      test('records preserves column order', () {
        var df = DataFrame([
          [1, 2, 3],
        ], columns: [
          'C',
          'A',
          'B'
        ]);

        var records = df.toRecords();

        var keys = records[0].keys.toList();
        expect(keys, equals(['C', 'A', 'B']));
      });
    });

    group('Edge Cases', () {
      test('empty DataFrame to LaTeX', () {
        var df = DataFrame([], columns: ['A', 'B']);

        var latex = df.toLatex();

        expect(latex, contains('\\begin{table}'));
        expect(latex, contains('\\end{table}'));
      });

      test('empty DataFrame to Markdown', () {
        var df = DataFrame([], columns: ['A', 'B']);

        var markdown = df.toMarkdown();

        expect(markdown, contains('A'));
        expect(markdown, contains('B'));
      });

      test('single row DataFrame', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var latex = df.toLatex();
        var markdown = df.toMarkdown();
        var formatted = df.toStringFormatted();
        var records = df.toRecords();

        expect(latex, isNotEmpty);
        expect(markdown, isNotEmpty);
        expect(formatted, isNotEmpty);
        expect(records.length, equals(1));
      });

      test('single column DataFrame', () {
        var df = DataFrame([
          [1],
          [2],
        ], columns: [
          'A'
        ]);

        var latex = df.toLatex();
        var markdown = df.toMarkdown();
        var formatted = df.toStringFormatted();
        var records = df.toRecords();

        expect(latex, contains('A'));
        expect(markdown, contains('A'));
        expect(formatted, contains('A'));
        expect(records[0].keys.length, equals(1));
      });

      test('DataFrame with special characters', () {
        var df = DataFrame([
          ['<html>', '&nbsp;'],
        ], columns: [
          'Tag',
          'Entity'
        ]);

        var latex = df.toLatex(escape: true);
        var markdown = df.toMarkdown();

        expect(latex, isNotEmpty);
        expect(markdown, isNotEmpty);
      });

      test('DataFrame with very long strings', () {
        var longString = 'A' * 1000;
        var df = DataFrame([
          [longString],
        ], columns: [
          'Text'
        ]);

        var markdown = df.toMarkdown(maxColWidth: 50);
        var formatted = df.toStringFormatted(maxColWidth: 50);

        expect(markdown, contains('...'));
        expect(formatted, isNotEmpty);
      });

      test('DataFrame with numeric column names', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          '0',
          '1'
        ]);

        var latex = df.toLatex();
        var markdown = df.toMarkdown();
        var records = df.toRecords();

        expect(latex, contains('0'));
        expect(markdown, contains('0'));
        expect(records[0].containsKey('0'), isTrue);
      });
    });

    group('Integration Tests', () {
      test('export same DataFrame to all formats', () {
        var df = DataFrame([
          ['Alice', 25, 50000.50],
          ['Bob', 30, 60000.75],
          ['Charlie', 35, 55000.25],
        ], columns: [
          'Name',
          'Age',
          'Salary'
        ]);

        var latex = df.toLatex(caption: 'Employee Data');
        var markdown = df.toMarkdown(floatfmt: '.2f');
        var formatted = df.toStringFormatted();
        var records = df.toRecords();

        expect(latex, isNotEmpty);
        expect(markdown, isNotEmpty);
        expect(formatted, isNotEmpty);
        expect(records.length, equals(3));

        // All formats should contain the data
        expect(latex, contains('Alice'));
        expect(markdown, contains('Alice'));
        expect(formatted, contains('Alice'));
        expect(records[0]['Name'], equals('Alice'));
      });

      test('chain export with other operations', () {
        var df = DataFrame([
          ['Alice', 25],
          ['Bob', 30],
          ['Charlie', 35],
        ], columns: [
          'Name',
          'Age'
        ]);

        // Filter and export
        var filtered = df.query('Age > 25');
        var markdown = filtered.toMarkdown();

        expect(markdown, contains('Bob'));
        expect(markdown, contains('Charlie'));
        expect(markdown.contains('Alice'), isFalse);
      });
    });
  });
}
