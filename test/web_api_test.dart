import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Web & API Functions', () {
    group('toHtml()', () {
      test('basic HTML table', () {
        var df = DataFrame([
          ['Alice', 25],
          ['Bob', 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var html = df.toHtml();

        expect(html, contains('<table'));
        expect(html, contains('</table>'));
        expect(html, contains('<thead>'));
        expect(html, contains('<tbody>'));
        expect(html, contains('Name'));
        expect(html, contains('Age'));
        expect(html, contains('Alice'));
        expect(html, contains('Bob'));
      });

      test('HTML with custom classes', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var html = df.toHtml(classes: 'table table-striped');

        expect(html, contains('class="table table-striped"'));
      });

      test('HTML with table ID', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var html = df.toHtml(tableId: 'myTable');

        expect(html, contains('id="myTable"'));
      });

      test('HTML without index', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var html = df.toHtml(index: false);

        expect(html, contains('<th'));
        expect(html, contains('A'));
        expect(html, contains('B'));
      });

      test('HTML without header', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var html = df.toHtml(header: false);

        expect(html.contains('<thead>'), isFalse);
      });

      test('HTML with escape', () {
        var df = DataFrame([
          ['<script>', '&nbsp;'],
        ], columns: [
          'Tag',
          'Entity'
        ]);

        var html = df.toHtml(escape: true);

        expect(html, contains('&lt;script&gt;'));
        expect(html, contains('&amp;nbsp;'));
      });

      test('HTML without escape', () {
        var df = DataFrame([
          ['<b>Bold</b>', 'Text'],
        ], columns: [
          'HTML',
          'Plain'
        ]);

        var html = df.toHtml(escape: false);

        expect(html, contains('<b>Bold</b>'));
      });

      test('HTML with notebook styling', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var html = df.toHtml(notebook: true);

        expect(html, contains('<style>'));
        expect(html, contains('.dataframe'));
      });

      test('HTML with dimensions', () {
        var df = DataFrame([
          [1, 2],
          [3, 4],
        ], columns: [
          'A',
          'B'
        ]);

        var html = df.toHtml(showDimensions: true);

        expect(html, contains('2 rows'));
        expect(html, contains('2 columns'));
      });

      test('HTML with max rows truncation', () {
        var df = DataFrame(
          List.generate(10, (i) => [i, i * 2]),
          columns: ['A', 'B'],
        );

        var html = df.toHtml(maxRows: 6);

        expect(html, contains('...'));
      });
    });

    group('toXml()', () {
      test('basic XML output', () {
        var df = DataFrame([
          ['Alice', 25],
          ['Bob', 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var xml = df.toXml();

        expect(xml, contains('<?xml version'));
        expect(xml, contains('<data>'));
        expect(xml, contains('</data>'));
        expect(xml, contains('<row'));
        expect(xml, contains('</row>'));
        expect(xml, contains('<Name>'));
        expect(xml, contains('<Age>'));
      });

      test('XML with custom root name', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var xml = df.toXml(rootName: 'employees');

        expect(xml, contains('<employees>'));
        expect(xml, contains('</employees>'));
      });

      test('XML with custom row name', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var xml = df.toXml(rowName: 'employee');

        expect(xml, contains('<employee'));
        expect(xml, contains('</employee>'));
      });

      test('XML without index', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var xml = df.toXml(index: false);

        expect(xml.contains('index='), isFalse);
      });

      test('XML without declaration', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var xml = df.toXml(xmlDeclaration: false);

        expect(xml.contains('<?xml'), isFalse);
      });

      test('XML with attributes', () {
        var df = DataFrame([
          ['Alice', 25],
        ], columns: [
          'Name',
          'Age'
        ]);

        var xml = df.toXml(attrCols: ['Name']);

        expect(xml, contains('Name="Alice"'));
        expect(xml, contains('<Age>'));
      });

      test('XML escapes special characters', () {
        var df = DataFrame([
          ['A & B', '<tag>'],
        ], columns: [
          'Text',
          'HTML'
        ]);

        var xml = df.toXml();

        expect(xml, contains('&amp;'));
        expect(xml, contains('&lt;'));
        expect(xml, contains('&gt;'));
      });

      test('XML without pretty print', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var xml = df.toXml(pretty: false);

        expect(xml.contains('\n'), isFalse);
      });
    });

    group('readHtml()', () {
      test('read simple HTML table', () {
        var html = '''
        <table>
          <tr><th>Name</th><th>Age</th></tr>
          <tr><td>Alice</td><td>25</td></tr>
          <tr><td>Bob</td><td>30</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html);

        expect(dfs.length, equals(1));
        expect(dfs[0].columns, equals(['Name', 'Age']));
        expect(dfs[0].rowCount, equals(2));
        expect(dfs[0]['Name'][0], equals('Alice'));
        expect(dfs[0]['Age'][0], equals(25));
      });

      test('read HTML table without header', () {
        var html = '''
        <table>
          <tr><td>Alice</td><td>25</td></tr>
          <tr><td>Bob</td><td>30</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html, header: -1);

        expect(dfs.length, equals(1));
        expect(dfs[0].rowCount, equals(2));
      });

      test('read multiple HTML tables', () {
        var html = '''
        <table>
          <tr><th>A</th></tr>
          <tr><td>1</td></tr>
        </table>
        <table>
          <tr><th>B</th></tr>
          <tr><td>2</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html);

        expect(dfs.length, equals(2));
      });

      test('read HTML with numeric parsing', () {
        var html = '''
        <table>
          <tr><th>Value</th></tr>
          <tr><td>123</td></tr>
          <tr><td>45.6</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html, parseNumbers: true);

        expect(dfs[0]['Value'][0], isA<num>());
        expect(dfs[0]['Value'][0], equals(123));
        expect(dfs[0]['Value'][1], equals(45.6));
      });

      test('read HTML without numeric parsing', () {
        var html = '''
        <table>
          <tr><th>Value</th></tr>
          <tr><td>123</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html, parseNumbers: false);

        expect(dfs[0]['Value'][0], isA<String>());
        expect(dfs[0]['Value'][0], equals('123'));
      });

      test('read HTML with HTML entities', () {
        var html = '''
        <table>
          <tr><th>Text</th></tr>
          <tr><td>A &amp; B</td></tr>
          <tr><td>&lt;tag&gt;</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html);

        expect(dfs[0]['Text'][0], equals('A & B'));
        expect(dfs[0]['Text'][1], equals('<tag>'));
      });

      test('read empty HTML returns empty list', () {
        var html = '<div>No tables here</div>';

        var dfs = DataFrame.readHtml(html);

        expect(dfs.isEmpty, isTrue);
      });
    });

    group('readXml()', () {
      test('read simple XML', () {
        var xml = '''
        <data>
          <row>
            <Name>Alice</Name>
            <Age>25</Age>
          </row>
          <row>
            <Name>Bob</Name>
            <Age>30</Age>
          </row>
        </data>
        ''';

        var df = DataFrame.readXml(xml);

        expect(df.columns.contains('Name'), isTrue);
        expect(df.columns.contains('Age'), isTrue);
        expect(df.rowCount, equals(2));
        expect(df['Name'][0], equals('Alice'));
        expect(df['Age'][0], equals(25));
      });

      test('read XML with attributes', () {
        var xml = '''
        <data>
          <row id="1">
            <Name>Alice</Name>
          </row>
          <row id="2">
            <Name>Bob</Name>
          </row>
        </data>
        ''';

        var df = DataFrame.readXml(xml);

        expect(df.columns.contains('@id'), isTrue);
        expect(df['@id'][0], equals('1'));
      });

      test('read XML with custom row name', () {
        var xml = '''
        <employees>
          <employee>
            <Name>Alice</Name>
          </employee>
        </employees>
        ''';

        var df = DataFrame.readXml(xml, rowName: 'employee');

        expect(df.rowCount, equals(1));
        expect(df['Name'][0], equals('Alice'));
      });

      test('read XML with numeric parsing', () {
        var xml = '''
        <data>
          <row>
            <Value>123</Value>
          </row>
        </data>
        ''';

        var df = DataFrame.readXml(xml, parseNumbers: true);

        expect(df['Value'][0], isA<num>());
        expect(df['Value'][0], equals(123));
      });

      test('read XML without numeric parsing', () {
        var xml = '''
        <data>
          <row>
            <Value>123</Value>
          </row>
        </data>
        ''';

        var df = DataFrame.readXml(xml, parseNumbers: false);

        expect(df['Value'][0], isA<String>());
        expect(df['Value'][0], equals('123'));
      });

      test('read XML with XML entities', () {
        var xml = '''
        <data>
          <row>
            <Text>A &amp; B</Text>
            <HTML>&lt;tag&gt;</HTML>
          </row>
        </data>
        ''';

        var df = DataFrame.readXml(xml);

        expect(df['Text'][0], equals('A & B'));
        expect(df['HTML'][0], equals('<tag>'));
      });

      test('read empty XML returns empty DataFrame', () {
        var xml = '<data></data>';

        var df = DataFrame.readXml(xml);

        expect(df.rowCount, equals(0));
      });

      test('read XML with custom attribute prefix', () {
        var xml = '''
        <data>
          <row id="1">
            <Name>Alice</Name>
          </row>
        </data>
        ''';

        var df = DataFrame.readXml(xml, attrPrefix: 'attr_');

        expect(df.columns.contains('attr_id'), isTrue);
      });
    });

    group('Round-trip Tests', () {
      test('HTML round-trip', () {
        var original = DataFrame([
          ['Alice', 25],
          ['Bob', 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var html = original.toHtml(index: false);
        var dfs = DataFrame.readHtml(html);
        var restored = dfs[0];

        expect(restored.columns, equals(original.columns));
        expect(restored.rowCount, equals(original.rowCount));
        expect(restored['Name'][0], equals('Alice'));
      });

      test('XML round-trip', () {
        var original = DataFrame([
          ['Alice', 25],
          ['Bob', 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var xml = original.toXml(index: false);
        var restored = DataFrame.readXml(xml);

        expect(restored.columns.toSet(), equals(original.columns.toSet()));
        expect(restored.rowCount, equals(original.rowCount));
      });
    });

    group('Edge Cases', () {
      test('empty DataFrame to HTML', () {
        var df = DataFrame([], columns: ['A', 'B']);

        var html = df.toHtml();

        expect(html, contains('<table'));
        expect(html, contains('</table>'));
      });

      test('empty DataFrame to XML', () {
        var df = DataFrame([], columns: ['A', 'B']);

        var xml = df.toXml();

        expect(xml, contains('<data>'));
        expect(xml, contains('</data>'));
      });

      test('DataFrame with null values to HTML', () {
        var df = DataFrame([
          ['Alice', null],
          [null, 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var html = df.toHtml();

        expect(html, isNotEmpty);
      });

      test('DataFrame with null values to XML', () {
        var df = DataFrame([
          ['Alice', null],
        ], columns: [
          'Name',
          'Age'
        ]);

        var xml = df.toXml();

        expect(xml, contains('<Name>Alice</Name>'));
        expect(xml, contains('<Age></Age>'));
      });
    });
  });
}
