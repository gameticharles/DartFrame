import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Enhanced Web & API Functions', () {
    group('toHtmlReport()', () {
      test('generates complete HTML report', () {
        var df = DataFrame([
          ['Alice', 25],
          ['Bob', 30],
        ], columns: [
          'Name',
          'Age'
        ]);

        var report = df.toHtmlReport(
          title: 'Test Report',
          description: 'Sample data',
        );

        expect(report, contains('<!DOCTYPE html>'));
        expect(report, contains('<title>Test Report</title>'));
        expect(report, contains('Sample data'));
        expect(report, contains('Alice'));
      });

      test('includes summary statistics', () {
        var df = DataFrame([
          [1, 2],
          [3, 4],
        ], columns: [
          'A',
          'B'
        ]);

        var report = df.toHtmlReport(includeStats: true);

        expect(report, contains('Summary'));
        expect(report, contains('Rows: 2'));
        expect(report, contains('Columns: 2'));
      });

      test('adds sortable JavaScript', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var report = df.toHtmlReport(sortable: true);

        expect(report, contains('sortTable'));
        expect(report, contains('class="dataframe sortable"'));
      });

      test('adds filterable JavaScript', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var report = df.toHtmlReport(filterable: true);

        expect(report, contains('filterTable'));
        expect(report, contains('filterInput'));
      });

      test('applies dark theme', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var report = df.toHtmlReport(theme: 'dark');

        expect(report, contains('#1e1e1e')); // Dark background color
      });

      test('applies blue theme', () {
        var df = DataFrame([
          [1, 2],
        ], columns: [
          'A',
          'B'
        ]);

        var report = df.toHtmlReport(theme: 'blue');

        expect(report, contains('#f0f4f8')); // Blue theme color
      });
    });

    group('toRss()', () {
      test('generates RSS feed', () {
        var df = DataFrame([
          ['Article 1', 'Content 1'],
          ['Article 2', 'Content 2'],
        ], columns: [
          'Title',
          'Description'
        ]);

        var rss = df.toRss(
          title: 'News Feed',
          link: 'https://example.com',
          description: 'Latest news',
          titleCol: 'Title',
          descCol: 'Description',
        );

        expect(rss, contains('<?xml version'));
        expect(rss, contains('<rss version="2.0">'));
        expect(rss, contains('<title>News Feed</title>'));
        expect(rss, contains('<item>'));
        expect(rss, contains('Article 1'));
      });

      test('includes optional link column', () {
        var df = DataFrame([
          ['Article 1', 'Content 1', 'https://example.com/1'],
        ], columns: [
          'Title',
          'Description',
          'Link'
        ]);

        var rss = df.toRss(
          title: 'Feed',
          link: 'https://example.com',
          description: 'Feed',
          titleCol: 'Title',
          descCol: 'Description',
          linkCol: 'Link',
        );

        expect(rss, contains('<link>https://example.com/1</link>'));
      });

      test('includes optional date column', () {
        var df = DataFrame([
          ['Article 1', 'Content 1', '2024-01-01'],
        ], columns: [
          'Title',
          'Description',
          'Date'
        ]);

        var rss = df.toRss(
          title: 'Feed',
          link: 'https://example.com',
          description: 'Feed',
          titleCol: 'Title',
          descCol: 'Description',
          dateCol: 'Date',
        );

        expect(rss, contains('<pubDate>2024-01-01</pubDate>'));
      });
    });

    group('toAtom()', () {
      test('generates Atom feed', () {
        var df = DataFrame([
          ['Post 1', 'Body 1'],
          ['Post 2', 'Body 2'],
        ], columns: [
          'Title',
          'Content'
        ]);

        var atom = df.toAtom(
          title: 'Blog',
          id: 'https://example.com/feed',
          titleCol: 'Title',
          contentCol: 'Content',
        );

        expect(atom, contains('<?xml version'));
        expect(atom, contains('<feed xmlns="http://www.w3.org/2005/Atom">'));
        expect(atom, contains('<title>Blog</title>'));
        expect(atom, contains('<entry>'));
        expect(atom, contains('Post 1'));
      });

      test('includes optional link', () {
        var df = DataFrame([
          ['Post 1', 'Body 1', 'https://example.com/post1'],
        ], columns: [
          'Title',
          'Content',
          'Link'
        ]);

        var atom = df.toAtom(
          title: 'Blog',
          id: 'https://example.com/feed',
          titleCol: 'Title',
          contentCol: 'Content',
          linkCol: 'Link',
        );

        expect(atom, contains('<link href="https://example.com/post1"/>'));
      });
    });

    group('HtmlTableParser - Advanced Features', () {
      test('parses table with colspan', () {
        var html = '''
        <table>
          <tr><th colspan="2">Header</th><th>C</th></tr>
          <tr><td>A1</td><td>B1</td><td>C1</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html);

        expect(dfs.length, equals(1));
        expect(dfs[0].columns.length, equals(3));
      });

      test('parses table with rowspan', () {
        var html = '''
        <table>
          <tr><th>A</th><th>B</th></tr>
          <tr><td rowspan="2">A1</td><td>B1</td></tr>
          <tr><td>B2</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html);

        expect(dfs.length, equals(1));
        expect(dfs[0].rowCount, equals(2));
      });

      test('parses numbers with thousands separator', () {
        var html = '''
        <table>
          <tr><th>Value</th></tr>
          <tr><td>1,000</td></tr>
          <tr><td>2,500.50</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html);

        expect(dfs[0]['Value'][0], equals(1000));
        expect(dfs[0]['Value'][1], equals(2500.50));
      });

      test('parses currency values', () {
        var html = '''
        <table>
          <tr><th>Price</th></tr>
          <tr><td>\$100</td></tr>
          <tr><td>€50.00</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html);

        expect(dfs[0]['Price'][0], equals(100));
        expect(dfs[0]['Price'][1], equals(50.00));
      });

      test('parses percentage values', () {
        var html = '''
        <table>
          <tr><th>Rate</th></tr>
          <tr><td>50%</td></tr>
          <tr><td>75.5%</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html);

        expect(dfs[0]['Rate'][0], equals(50));
        expect(dfs[0]['Rate'][1], equals(75.5));
      });

      test('matches table by attributes', () {
        var html = '''
        <table class="data">
          <tr><th>A</th></tr>
          <tr><td>1</td></tr>
        </table>
        <table class="other">
          <tr><th>B</th></tr>
          <tr><td>2</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html, attrs: {'class': 'data'});

        expect(dfs.length, equals(1));
        expect(dfs[0].columns[0], equals('A'));
      });

      test('matches table by string', () {
        var html = '''
        <table id="main">
          <tr><th>A</th></tr>
          <tr><td>1</td></tr>
        </table>
        <table id="other">
          <tr><th>B</th></tr>
          <tr><td>2</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html, match: 'id="main"');

        expect(dfs.length, equals(1));
        expect(dfs[0].columns[0], equals('A'));
      });
    });

    group('XmlParser - Nested Structures', () {
      test('parses nested XML elements', () {
        var xml = '''
        <data>
          <row>
            <Person>
              <Name>Alice</Name>
              <Age>25</Age>
            </Person>
          </row>
        </data>
        ''';

        var df = DataFrame.readXml(xml);

        expect(df.columns.contains('Person.Name'), isTrue);
        expect(df.columns.contains('Person.Age'), isTrue);
        expect(df['Person.Name'][0], equals('Alice'));
        expect(df['Person.Age'][0], equals(25));
      });

      test('parses deeply nested XML', () {
        var xml = '''
        <data>
          <row>
            <Company>
              <Employee>
                <Name>Alice</Name>
              </Employee>
            </Company>
          </row>
        </data>
        ''';

        var df = DataFrame.readXml(xml);

        expect(df.columns.contains('Company.Employee.Name'), isTrue);
        expect(df['Company.Employee.Name'][0], equals('Alice'));
      });

      test('uses custom nested separator', () {
        var xml = '''
        <data>
          <row>
            <Person>
              <Name>Alice</Name>
            </Person>
          </row>
        </data>
        ''';

        var df = XmlParser.parse(xml, nestedSeparator: '_');

        expect(df.columns.contains('Person_Name'), isTrue);
      });

      test('can disable nested flattening', () {
        var xml = '''
        <data>
          <row>
            <Name>Alice</Name>
            <Age>25</Age>
          </row>
        </data>
        ''';

        var df = XmlParser.parse(xml, flattenNested: false);

        expect(df.columns.contains('Name'), isTrue);
        expect(df.columns.contains('Age'), isTrue);
      });
    });

    group('Integration Tests', () {
      test('HTML report with all features', () {
        var df = DataFrame([
          ['Product A', 100, 1500.50],
          ['Product B', 200, 2500.75],
          ['Product C', 150, 1800.25],
        ], columns: [
          'Product',
          'Quantity',
          'Revenue'
        ]);

        var report = df.toHtmlReport(
          title: 'Sales Report',
          description: 'Q1 2024 Sales Data',
          includeStats: true,
          theme: 'blue',
          sortable: true,
          filterable: true,
        );

        expect(report, contains('Sales Report'));
        expect(report, contains('Q1 2024'));
        expect(report, contains('sortTable'));
        expect(report, contains('filterTable'));
        expect(report, contains('Product A'));
      });

      test('RSS feed from DataFrame', () {
        var df = DataFrame([
          [
            'Breaking News',
            'Important update',
            'https://example.com/1',
            '2024-01-01'
          ],
          ['Tech Update', 'New release', 'https://example.com/2', '2024-01-02'],
        ], columns: [
          'Title',
          'Description',
          'Link',
          'Date'
        ]);

        var rss = df.toRss(
          title: 'News Feed',
          link: 'https://example.com',
          description: 'Latest updates',
          titleCol: 'Title',
          descCol: 'Description',
          linkCol: 'Link',
          dateCol: 'Date',
        );

        expect(rss, contains('Breaking News'));
        expect(rss, contains('Tech Update'));
        expect(rss, contains('https://example.com/1'));
      });

      test('complex HTML table parsing', () {
        var html = '''
        <table class="financial-data">
          <thead>
            <tr><th>Company</th><th>Revenue</th><th>Growth</th></tr>
          </thead>
          <tbody>
            <tr><td>Company A</td><td>\$1,000,000</td><td>15.5%</td></tr>
            <tr><td>Company B</td><td>\$2,500,000</td><td>22.3%</td></tr>
          </tbody>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html, attrs: {'class': 'financial-data'});

        expect(dfs.length, equals(1));
        expect(dfs[0]['Revenue'][0], equals(1000000));
        expect(dfs[0]['Growth'][0], equals(15.5));
      });
    });

    group('Edge Cases', () {
      test('empty DataFrame to RSS', () {
        var df = DataFrame([], columns: ['Title', 'Description']);

        var rss = df.toRss(
          title: 'Feed',
          link: 'https://example.com',
          description: 'Feed',
          titleCol: 'Title',
          descCol: 'Description',
        );

        expect(rss, contains('<rss version="2.0">'));
        expect(rss, contains('</channel>'));
      });

      test('HTML with malformed numbers', () {
        var html = '''
        <table>
          <tr><th>Value</th></tr>
          <tr><td>not a number</td></tr>
          <tr><td>123abc</td></tr>
        </table>
        ''';

        var dfs = DataFrame.readHtml(html);

        expect(dfs[0]['Value'][0], equals('not a number'));
        expect(dfs[0]['Value'][1], equals('123abc'));
      });

      test('XML with empty elements', () {
        var xml = '''
        <data>
          <row>
            <Name>Alice</Name>
            <Age></Age>
          </row>
        </data>
        ''';

        var df = DataFrame.readXml(xml);

        expect(df['Name'][0], equals('Alice'));
        expect(df['Age'][0], equals(''));
      });
    });
  });
}
