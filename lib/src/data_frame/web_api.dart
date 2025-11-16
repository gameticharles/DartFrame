part of 'data_frame.dart';

/// Extension providing web and API methods for DataFrame.
///
/// Includes methods for HTML and XML export/import.
extension DataFrameWebAPI on DataFrame {
  /// Export DataFrame to HTML table format.
  ///
  /// Parameters:
  /// - `classes`: CSS classes to add to the table (default: 'dataframe')
  /// - `tableId`: ID attribute for the table (optional)
  /// - `border`: Border width (default: 1)
  /// - `index`: Include index column (default: true)
  /// - `header`: Include header row (default: true)
  /// - `escape`: Escape HTML special characters (default: true)
  /// - `bold`: Bold header row (default: true)
  /// - `justify`: Text alignment ('left', 'center', 'right', default: 'left')
  /// - `maxRows`: Maximum rows to display (default: null = all rows)
  /// - `maxCols`: Maximum columns to display (default: null = all columns)
  /// - `showDimensions`: Show dimensions below table (default: true)
  /// - `notebook`: Use Jupyter notebook styling (default: false)
  ///
  /// Returns an HTML table string.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 25, 50000],
  ///   ['Bob', 30, 60000],
  /// ], columns: ['Name', 'Age', 'Salary']);
  ///
  /// var html = df.toHtml(
  ///   classes: 'table table-striped',
  ///   tableId: 'employees',
  /// );
  /// ```
  String toHtml({
    String classes = 'dataframe',
    String? tableId,
    int border = 1,
    bool index = true,
    bool header = true,
    bool escape = true,
    bool bold = true,
    String justify = 'left',
    int? maxRows,
    int? maxCols,
    bool showDimensions = true,
    bool notebook = false,
  }) {
    final buffer = StringBuffer();

    // Add notebook styling if requested
    if (notebook) {
      buffer.writeln('<style>');
      buffer.writeln('.dataframe {');
      buffer.writeln('  border-collapse: collapse;');
      buffer.writeln('  border: 1px solid #ddd;');
      buffer.writeln('}');
      buffer.writeln('.dataframe th {');
      buffer.writeln('  background-color: #f2f2f2;');
      buffer.writeln('  padding: 8px;');
      buffer.writeln('  text-align: $justify;');
      buffer.writeln('}');
      buffer.writeln('.dataframe td {');
      buffer.writeln('  padding: 8px;');
      buffer.writeln('  text-align: $justify;');
      buffer.writeln('  border: 1px solid #ddd;');
      buffer.writeln('}');
      buffer.writeln('</style>');
    }

    // Start table
    final tableAttrs = <String>[];
    if (classes.isNotEmpty) tableAttrs.add('class="$classes"');
    if (tableId != null) tableAttrs.add('id="$tableId"');
    tableAttrs.add('border="$border"');

    buffer.writeln('<table ${tableAttrs.join(' ')}>');

    // Determine which rows and columns to display
    final displayRows = maxRows == null || rowCount <= maxRows
        ? List.generate(rowCount, (i) => i)
        : [
            ...List.generate(maxRows ~/ 2, (i) => i),
            -1, // Marker for ellipsis
            ...List.generate(maxRows ~/ 2, (i) => rowCount - (maxRows ~/ 2) + i)
          ];

    final displayCols = maxCols == null || columns.length <= maxCols
        ? columns
        : [
            ...columns.sublist(0, maxCols ~/ 2),
            '...', // Marker for ellipsis
            ...columns.sublist(columns.length - (maxCols ~/ 2))
          ];

    // Header row
    if (header) {
      buffer.writeln('  <thead>');
      buffer.writeln('    <tr style="text-align: $justify;">');

      if (index) {
        final thStyle = bold ? ' style="font-weight: bold;"' : '';
        buffer.writeln('      <th$thStyle></th>');
      }

      for (var col in displayCols) {
        final thStyle = bold ? ' style="font-weight: bold;"' : '';
        final colText = escape ? _escapeHtml(col.toString()) : col.toString();
        buffer.writeln('      <th$thStyle>$colText</th>');
      }

      buffer.writeln('    </tr>');
      buffer.writeln('  </thead>');
    }

    // Body rows
    buffer.writeln('  <tbody>');

    for (var i in displayRows) {
      if (i == -1) {
        // Ellipsis row
        buffer.writeln('    <tr>');
        if (index) {
          buffer.writeln('      <td>...</td>');
        }
        for (var _ in displayCols) {
          buffer.writeln('      <td>...</td>');
        }
        buffer.writeln('    </tr>');
        continue;
      }

      buffer.writeln('    <tr>');

      if (index) {
        final idxText = escape
            ? _escapeHtml(this.index[i].toString())
            : this.index[i].toString();
        buffer.writeln('      <td>$idxText</td>');
      }

      for (var col in displayCols) {
        if (col == '...') {
          buffer.writeln('      <td>...</td>');
        } else {
          final value = this[col][i];
          final cellText = value == null
              ? ''
              : (escape ? _escapeHtml(value.toString()) : value.toString());
          buffer.writeln('      <td>$cellText</td>');
        }
      }

      buffer.writeln('    </tr>');
    }

    buffer.writeln('  </tbody>');
    buffer.writeln('</table>');

    // Show dimensions
    if (showDimensions) {
      buffer.writeln('<p>$rowCount rows × ${columns.length} columns</p>');
    }

    return buffer.toString();
  }

  /// Export DataFrame to XML format.
  ///
  /// Parameters:
  /// - `rootName`: Name of the root XML element (default: 'data')
  /// - `rowName`: Name for each row element (default: 'row')
  /// - `index`: Include index as attribute (default: true)
  /// - `indexName`: Name for index attribute (default: 'index')
  /// - `encoding`: XML encoding declaration (default: 'UTF-8')
  /// - `xmlDeclaration`: Include XML declaration (default: true)
  /// - `pretty`: Pretty print with indentation (default: true)
  /// - `attrCols`: Columns to export as attributes instead of elements (default: [])
  ///
  /// Returns an XML string.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 25],
  ///   ['Bob', 30],
  /// ], columns: ['Name', 'Age']);
  ///
  /// var xml = df.toXml(
  ///   rootName: 'employees',
  ///   rowName: 'employee',
  /// );
  /// ```
  String toXml({
    String rootName = 'data',
    String rowName = 'row',
    bool index = true,
    String indexName = 'index',
    String encoding = 'UTF-8',
    bool xmlDeclaration = true,
    bool pretty = true,
    List<String> attrCols = const [],
  }) {
    final buffer = StringBuffer();
    final indent = pretty ? '  ' : '';
    final newline = pretty ? '\n' : '';

    // XML declaration
    if (xmlDeclaration) {
      if (pretty) {
        buffer.writeln('<?xml version="1.0" encoding="$encoding"?>');
      } else {
        buffer.write('<?xml version="1.0" encoding="$encoding"?>');
      }
    }

    // Root element
    buffer.write('<$rootName>$newline');

    // Data rows
    for (var i = 0; i < rowCount; i++) {
      final attrs = <String>[];

      // Add index as attribute if requested
      if (index) {
        attrs.add('$indexName="${_escapeXml(this.index[i].toString())}"');
      }

      // Add attribute columns
      for (var col in attrCols) {
        if (columns.contains(col)) {
          final value = this[col][i];
          if (value != null) {
            attrs.add('$col="${_escapeXml(value.toString())}"');
          }
        }
      }

      final attrStr = attrs.isEmpty ? '' : ' ${attrs.join(' ')}';
      buffer.write('$indent<$rowName$attrStr>$newline');

      // Add element columns (non-attribute columns)
      for (var col in columns) {
        if (!attrCols.contains(col)) {
          final value = this[col][i];
          final valueStr = value == null ? '' : _escapeXml(value.toString());
          final colIndent = pretty ? indent * 2 : '';
          buffer.write('$colIndent<$col>$valueStr</$col>$newline');
        }
      }

      buffer.write('$indent</$rowName>$newline');
    }

    // Close root element
    buffer.write('</$rootName>');

    return buffer.toString();
  }

  /// Export DataFrame to a complete HTML report with styling.
  ///
  /// Creates a full HTML page with CSS styling, title, and optional summary.
  ///
  /// Parameters:
  /// - `title`: Page title (default: 'DataFrame Report')
  /// - `description`: Optional description text
  /// - `includeStats`: Include summary statistics (default: true)
  /// - `theme`: Color theme ('light', 'dark', 'blue', default: 'light')
  /// - `responsive`: Make table responsive (default: true)
  /// - `sortable`: Add JavaScript sorting (default: false)
  /// - `filterable`: Add JavaScript filtering (default: false)
  ///
  /// Example:
  /// ```dart
  /// var html = df.toHtmlReport(
  ///   title: 'Sales Report',
  ///   includeStats: true,
  ///   sortable: true,
  /// );
  /// ```
  String toHtmlReport({
    String title = 'DataFrame Report',
    String? description,
    bool includeStats = true,
    String theme = 'light',
    bool responsive = true,
    bool sortable = false,
    bool filterable = false,
  }) {
    final buffer = StringBuffer();

    // HTML header
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln(
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>$title</title>');

    // CSS styling
    buffer.writeln('  <style>');
    buffer.writeln(_getThemeCSS(theme, responsive));
    buffer.writeln('  </style>');

    // JavaScript for interactivity
    if (sortable || filterable) {
      buffer.writeln('  <script>');
      if (sortable) buffer.writeln(_getSortableJS());
      if (filterable) buffer.writeln(_getFilterableJS());
      buffer.writeln('  </script>');
    }

    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="container">');
    buffer.writeln('    <h1>$title</h1>');

    if (description != null) {
      buffer.writeln('    <p class="description">$description</p>');
    }

    // Summary statistics
    if (includeStats) {
      buffer.writeln('    <div class="stats">');
      buffer.writeln('      <h2>Summary</h2>');
      buffer
          .writeln('      <p>Rows: $rowCount | Columns: ${columns.length}</p>');
      buffer.writeln('    </div>');
    }

    // Filter input
    if (filterable) {
      buffer.writeln('    <div class="filter-container">');
      buffer.writeln(
          '      <input type="text" id="filterInput" placeholder="Filter table..." onkeyup="filterTable()">');
      buffer.writeln('    </div>');
    }

    // Main table
    buffer.writeln(toHtml(
      classes: sortable ? 'dataframe sortable' : 'dataframe',
      tableId: 'mainTable',
      notebook: false,
      showDimensions: false,
    ));

    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// Export DataFrame to RSS feed format.
  ///
  /// Parameters:
  /// - `title`: Feed title
  /// - `link`: Feed URL
  /// - `description`: Feed description
  /// - `titleCol`: Column to use for item titles
  /// - `descCol`: Column to use for item descriptions
  /// - `linkCol`: Column to use for item links (optional)
  /// - `dateCol`: Column to use for publication dates (optional)
  ///
  /// Example:
  /// ```dart
  /// var rss = df.toRss(
  ///   title: 'News Feed',
  ///   link: 'https://example.com',
  ///   description: 'Latest news',
  ///   titleCol: 'headline',
  ///   descCol: 'summary',
  /// );
  /// ```
  String toRss({
    required String title,
    required String link,
    required String description,
    required String titleCol,
    required String descCol,
    String? linkCol,
    String? dateCol,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<rss version="2.0">');
    buffer.writeln('  <channel>');
    buffer.writeln('    <title>${_escapeXml(title)}</title>');
    buffer.writeln('    <link>${_escapeXml(link)}</link>');
    buffer.writeln('    <description>${_escapeXml(description)}</description>');

    for (var i = 0; i < rowCount; i++) {
      buffer.writeln('    <item>');
      buffer.writeln(
          '      <title>${_escapeXml(this[titleCol][i]?.toString() ?? '')}</title>');
      buffer.writeln(
          '      <description>${_escapeXml(this[descCol][i]?.toString() ?? '')}</description>');

      if (linkCol != null && columns.contains(linkCol)) {
        buffer.writeln(
            '      <link>${_escapeXml(this[linkCol][i]?.toString() ?? '')}</link>');
      }

      if (dateCol != null && columns.contains(dateCol)) {
        buffer.writeln(
            '      <pubDate>${this[dateCol][i]?.toString() ?? ''}</pubDate>');
      }

      buffer.writeln('    </item>');
    }

    buffer.writeln('  </channel>');
    buffer.writeln('</rss>');

    return buffer.toString();
  }

  /// Export DataFrame to Atom feed format.
  ///
  /// Parameters:
  /// - `title`: Feed title
  /// - `id`: Feed ID (usually a URL)
  /// - `titleCol`: Column to use for entry titles
  /// - `contentCol`: Column to use for entry content
  /// - `linkCol`: Column to use for entry links (optional)
  /// - `dateCol`: Column to use for updated dates (optional)
  ///
  /// Example:
  /// ```dart
  /// var atom = df.toAtom(
  ///   title: 'Blog Posts',
  ///   id: 'https://example.com/feed',
  ///   titleCol: 'title',
  ///   contentCol: 'body',
  /// );
  /// ```
  String toAtom({
    required String title,
    required String id,
    required String titleCol,
    required String contentCol,
    String? linkCol,
    String? dateCol,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<feed xmlns="http://www.w3.org/2005/Atom">');
    buffer.writeln('  <title>${_escapeXml(title)}</title>');
    buffer.writeln('  <id>${_escapeXml(id)}</id>');
    buffer.writeln('  <updated>${DateTime.now().toIso8601String()}</updated>');

    for (var i = 0; i < rowCount; i++) {
      buffer.writeln('  <entry>');
      buffer.writeln(
          '    <title>${_escapeXml(this[titleCol][i]?.toString() ?? '')}</title>');
      buffer.writeln(
          '    <content type="html">${_escapeXml(this[contentCol][i]?.toString() ?? '')}</content>');

      if (linkCol != null && columns.contains(linkCol)) {
        buffer.writeln(
            '    <link href="${_escapeXml(this[linkCol][i]?.toString() ?? '')}"/>');
      }

      if (dateCol != null && columns.contains(dateCol)) {
        buffer.writeln(
            '    <updated>${this[dateCol][i]?.toString() ?? ''}</updated>');
      }

      buffer.writeln('  </entry>');
    }

    buffer.writeln('</feed>');

    return buffer.toString();
  }

  // Helper methods for HTML report generation

  String _getThemeCSS(String theme, bool responsive) {
    final baseCSS = '''
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      margin: 0;
      padding: 20px;
      ${_getThemeColors(theme)}
    }
    .container {
      max-width: ${responsive ? '100%' : '1200px'};
      margin: 0 auto;
      ${responsive ? 'overflow-x: auto;' : ''}
    }
    h1 {
      color: var(--heading-color);
      margin-bottom: 10px;
    }
    h2 {
      color: var(--heading-color);
      font-size: 1.2em;
      margin-top: 20px;
    }
    .description {
      color: var(--text-secondary);
      margin-bottom: 20px;
    }
    .stats {
      background: var(--stats-bg);
      padding: 15px;
      border-radius: 5px;
      margin-bottom: 20px;
    }
    .filter-container {
      margin-bottom: 15px;
    }
    #filterInput {
      width: 100%;
      max-width: 400px;
      padding: 10px;
      border: 1px solid var(--border-color);
      border-radius: 4px;
      font-size: 14px;
    }
    table.dataframe {
      border-collapse: collapse;
      width: 100%;
      margin: 20px 0;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    table.dataframe th {
      background: var(--header-bg);
      color: var(--header-text);
      padding: 12px;
      text-align: left;
      font-weight: 600;
      border-bottom: 2px solid var(--border-color);
      ${responsive ? 'position: sticky; top: 0;' : ''}
    }
    table.dataframe.sortable th {
      cursor: pointer;
      user-select: none;
    }
    table.dataframe.sortable th:hover {
      background: var(--header-hover);
    }
    table.dataframe td {
      padding: 10px 12px;
      border-bottom: 1px solid var(--border-color);
    }
    table.dataframe tr:hover {
      background: var(--row-hover);
    }
    table.dataframe tr:nth-child(even) {
      background: var(--row-even);
    }
    ''';

    return baseCSS;
  }

  String _getThemeColors(String theme) {
    switch (theme) {
      case 'dark':
        return '''
        --bg-color: #1e1e1e;
        --text-color: #e0e0e0;
        --text-secondary: #b0b0b0;
        --heading-color: #ffffff;
        --header-bg: #2d2d2d;
        --header-text: #ffffff;
        --header-hover: #3d3d3d;
        --border-color: #404040;
        --row-hover: #2a2a2a;
        --row-even: #252525;
        --stats-bg: #2d2d2d;
        background-color: var(--bg-color);
        color: var(--text-color);
        ''';
      case 'blue':
        return '''
        --bg-color: #f0f4f8;
        --text-color: #2d3748;
        --text-secondary: #718096;
        --heading-color: #1a365d;
        --header-bg: #2c5282;
        --header-text: #ffffff;
        --header-hover: #2a4365;
        --border-color: #cbd5e0;
        --row-hover: #e6f2ff;
        --row-even: #f7fafc;
        --stats-bg: #ebf8ff;
        background-color: var(--bg-color);
        color: var(--text-color);
        ''';
      default: // light
        return '''
        --bg-color: #ffffff;
        --text-color: #333333;
        --text-secondary: #666666;
        --heading-color: #1a1a1a;
        --header-bg: #f8f9fa;
        --header-text: #333333;
        --header-hover: #e9ecef;
        --border-color: #dee2e6;
        --row-hover: #f8f9fa;
        --row-even: #ffffff;
        --stats-bg: #f8f9fa;
        background-color: var(--bg-color);
        color: var(--text-color);
        ''';
    }
  }

  String _getSortableJS() {
    return '''
    function sortTable(table, column, asc = true) {
      const tbody = table.querySelector('tbody');
      const rows = Array.from(tbody.querySelectorAll('tr'));
      
      rows.sort((a, b) => {
        const aVal = a.cells[column].textContent.trim();
        const bVal = b.cells[column].textContent.trim();
        
        const aNum = parseFloat(aVal);
        const bNum = parseFloat(bVal);
        
        if (!isNaN(aNum) && !isNaN(bNum)) {
          return asc ? aNum - bNum : bNum - aNum;
        }
        
        return asc ? aVal.localeCompare(bVal) : bVal.localeCompare(aVal);
      });
      
      rows.forEach(row => tbody.appendChild(row));
    }
    
    document.addEventListener('DOMContentLoaded', function() {
      const table = document.querySelector('table.sortable');
      if (!table) return;
      
      const headers = table.querySelectorAll('th');
      const sortStates = new Array(headers.length).fill(null);
      
      headers.forEach((header, index) => {
        header.addEventListener('click', () => {
          sortStates[index] = sortStates[index] === true ? false : true;
          sortTable(table, index, sortStates[index]);
          
          headers.forEach(h => h.textContent = h.textContent.replace(/ [▲▼]/g, ''));
          header.textContent += sortStates[index] ? ' ▲' : ' ▼';
        });
      });
    });
    ''';
  }

  String _getFilterableJS() {
    return '''
    function filterTable() {
      const input = document.getElementById('filterInput');
      const filter = input.value.toLowerCase();
      const table = document.getElementById('mainTable');
      const rows = table.getElementsByTagName('tr');
      
      for (let i = 1; i < rows.length; i++) {
        const row = rows[i];
        const cells = row.getElementsByTagName('td');
        let found = false;
        
        for (let j = 0; j < cells.length; j++) {
          const cell = cells[j];
          if (cell.textContent.toLowerCase().indexOf(filter) > -1) {
            found = true;
            break;
          }
        }
        
        row.style.display = found ? '' : 'none';
      }
    }
    ''';
  }

  /// Internal static method for reading HTML tables.
  ///
  /// This is called by DataFrame.readHtml() static method.
  /// Now uses enhanced HtmlTableParser for better parsing.
  static List<DataFrame> _readHtmlStatic(
    String html, {
    dynamic match,
    int header = 0,
    int? indexCol,
    List<int>? skiprows,
    Map<String, String> attrs = const {},
    bool parseNumbers = true,
  }) {
    // Use enhanced parser if available
    return HtmlTableParser.parse(
      html,
      match: match,
      attrs: attrs,
      header: header,
      skiprows: skiprows,
      parseNumbers: parseNumbers,
    );
  }

  /// Legacy simple HTML parser (kept for compatibility).
  static List<DataFrame> _readHtmlSimple(
    String html, {
    dynamic match,
    int header = 0,
    int? indexCol,
    List<int>? skiprows,
    Map<String, String> attrs = const {},
    bool parseNumbers = true,
  }) {
    final tables = <DataFrame>[];

    // Simple HTML table parser (basic implementation)
    // Extract tables using regex
    final tablePattern = RegExp(
      r'<table[^>]*>(.*?)</table>',
      caseSensitive: false,
      dotAll: true,
    );

    final tableMatches = tablePattern.allMatches(html);

    for (var tableMatch in tableMatches) {
      final tableHtml = tableMatch.group(1)!;

      // Extract rows
      final rowPattern = RegExp(
        r'<tr[^>]*>(.*?)</tr>',
        caseSensitive: false,
        dotAll: true,
      );

      final rows = <List<String>>[];
      final rowMatches = rowPattern.allMatches(tableHtml);

      for (var rowMatch in rowMatches) {
        final rowHtml = rowMatch.group(1)!;

        // Extract cells (th or td)
        final cellPattern = RegExp(
          r'<t[hd][^>]*>(.*?)</t[hd]>',
          caseSensitive: false,
          dotAll: true,
        );

        final cells = <String>[];
        final cellMatches = cellPattern.allMatches(rowHtml);

        for (var cellMatch in cellMatches) {
          var cellText = cellMatch.group(1)!.trim();
          // Remove HTML tags
          cellText = cellText.replaceAll(RegExp(r'<[^>]+>'), '');
          // Decode HTML entities
          cellText = _decodeHtmlEntities(cellText);
          cells.add(cellText);
        }

        if (cells.isNotEmpty) {
          rows.add(cells);
        }
      }

      if (rows.isEmpty) continue;

      // Extract header
      List<String>? columnNames;
      var dataStartRow = 0;

      if (header >= 0 && header < rows.length) {
        columnNames = rows[header];
        dataStartRow = header + 1;
      }

      // Extract data rows
      final dataRows = <List<dynamic>>[];
      for (var i = dataStartRow; i < rows.length; i++) {
        if (skiprows != null && skiprows.contains(i)) continue;

        final row = rows[i];
        final parsedRow = <dynamic>[];

        for (var cell in row) {
          if (parseNumbers) {
            final numValue = num.tryParse(cell);
            parsedRow.add(numValue ?? cell);
          } else {
            parsedRow.add(cell);
          }
        }

        dataRows.add(parsedRow);
      }

      if (dataRows.isEmpty) continue;

      // Create DataFrame
      final df = DataFrame(
        dataRows,
        columns:
            columnNames ?? List.generate(dataRows[0].length, (i) => 'Column$i'),
      );

      tables.add(df);
    }

    return tables;
  }

  /// Internal static method for reading XML data.
  ///
  /// This is called by DataFrame.readXml() static method.
  /// Now uses enhanced XmlParser for better parsing.
  static DataFrame _readXmlStatic(
    String xml, {
    String? xpath,
    String rowName = 'row',
    bool parseNumbers = true,
    String attrPrefix = '@',
  }) {
    // Use enhanced parser
    return XmlParser.parse(
      xml,
      rowName: rowName,
      parseNumbers: parseNumbers,
      attrPrefix: attrPrefix,
    );
  }

  /// Legacy simple XML parser (kept for compatibility).
  static DataFrame _readXmlSimple(
    String xml, {
    String? xpath,
    String rowName = 'row',
    bool parseNumbers = true,
    String attrPrefix = '@',
  }) {
    final rows = <Map<String, dynamic>>[];

    // Simple XML parser (basic implementation)
    // Extract row elements
    final rowPattern = RegExp(
      '<$rowName[^>]*>(.*?)</$rowName>',
      caseSensitive: false,
      dotAll: true,
    );

    final rowMatches = rowPattern.allMatches(xml);

    for (var rowMatch in rowMatches) {
      final rowXml = rowMatch.group(0)!;
      final rowContent = rowMatch.group(1)!;
      final rowData = <String, dynamic>{};

      // Extract attributes from row element
      final attrPattern = RegExp(r'(\w+)="([^"]*)"');
      final attrMatches = attrPattern.allMatches(rowXml);

      for (var attrMatch in attrMatches) {
        final attrName = attrMatch.group(1)!;
        var attrValue = attrMatch.group(2)!;
        attrValue = _decodeXmlEntities(attrValue);

        // Keep attributes as strings (don't parse numbers for attributes)
        rowData['$attrPrefix$attrName'] = attrValue;
      }

      // Extract child elements
      final elemPattern = RegExp(
        r'<(\w+)>([^<]*)</\1>',
        caseSensitive: false,
      );

      final elemMatches = elemPattern.allMatches(rowContent);

      for (var elemMatch in elemMatches) {
        final elemName = elemMatch.group(1)!;
        var elemValue = elemMatch.group(2)!.trim();
        elemValue = _decodeXmlEntities(elemValue);

        if (parseNumbers) {
          final numValue = num.tryParse(elemValue);
          rowData[elemName] = numValue ?? elemValue;
        } else {
          rowData[elemName] = elemValue;
        }
      }

      if (rowData.isNotEmpty) {
        rows.add(rowData);
      }
    }

    if (rows.isEmpty) {
      return DataFrame([], columns: []);
    }

    // Get all unique column names
    final allColumns = <String>{};
    for (var row in rows) {
      allColumns.addAll(row.keys);
    }

    final columnList = allColumns.toList()..sort();

    // Build data matrix
    final dataRows = <List<dynamic>>[];
    for (var row in rows) {
      final dataRow = <dynamic>[];
      for (var col in columnList) {
        dataRow.add(row[col]);
      }
      dataRows.add(dataRow);
    }

    return DataFrame(dataRows, columns: columnList);
  }

  // Helper methods

  String _escapeHtml(String text) {
    return DataFrameWebAPI._escapeHtmlStatic(text);
  }

  String _escapeXml(String text) {
    return DataFrameWebAPI._escapeXmlStatic(text);
  }

  static String _escapeHtmlStatic(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _escapeXmlStatic(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  static String _decodeXmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}

/// Enhanced HTML reading with advanced features.
class HtmlTableParser {
  /// Parse HTML with support for colspan, rowspan, and complex tables.
  ///
  /// Parameters:
  /// - `html`: HTML string to parse
  /// - `match`: String, RegExp, or CSS selector to match tables
  /// - `attrs`: HTML attributes to match (e.g., {'class': 'data'})
  /// - `header`: Row number to use as header
  /// - `skiprows`: Rows to skip
  /// - `thousands`: Thousands separator (e.g., ',')
  /// - `decimal`: Decimal separator (e.g., '.')
  /// - `naValues`: List of strings to treat as null
  /// - `parseNumbers`: Parse numeric values
  /// - `parseDates`: Parse date values
  /// - `converters`: Custom converters per column
  ///
  /// Returns list of DataFrames.
  static List<DataFrame> parse(
    String html, {
    dynamic match,
    Map<String, String> attrs = const {},
    int header = 0,
    List<int>? skiprows,
    String thousands = ',',
    String decimal = '.',
    List<String> naValues = const ['', 'NA', 'N/A', 'null', 'NULL'],
    bool parseNumbers = true,
    bool parseDates = false,
    Map<String, Function>? converters,
  }) {
    final tables = <DataFrame>[];

    // Extract tables
    final tablePattern = RegExp(
      r'<table[^>]*>(.*?)</table>',
      caseSensitive: false,
      dotAll: true,
    );

    final tableMatches = tablePattern.allMatches(html);

    for (var tableMatch in tableMatches) {
      final tableHtml = tableMatch.group(0)!;
      final tableContent = tableMatch.group(1)!;

      // Check if table matches criteria
      if (match != null) {
        if (match is String && !tableHtml.contains(match)) continue;
        if (match is RegExp && !match.hasMatch(tableHtml)) continue;
      }

      if (attrs.isNotEmpty) {
        var matchesAttrs = true;
        for (var entry in attrs.entries) {
          final attrPattern = RegExp('${entry.key}=["\']${entry.value}["\']',
              caseSensitive: false);
          if (!attrPattern.hasMatch(tableHtml)) {
            matchesAttrs = false;
            break;
          }
        }
        if (!matchesAttrs) continue;
      }

      // Parse table with colspan/rowspan support
      final df = _parseTableWithSpans(
        tableContent,
        header: header,
        skiprows: skiprows,
        thousands: thousands,
        decimal: decimal,
        naValues: naValues,
        parseNumbers: parseNumbers,
        parseDates: parseDates,
        converters: converters,
      );

      if (df != null) tables.add(df);
    }

    return tables;
  }

  static DataFrame? _parseTableWithSpans(
    String tableHtml, {
    required int header,
    List<int>? skiprows,
    required String thousands,
    required String decimal,
    required List<String> naValues,
    required bool parseNumbers,
    required bool parseDates,
    Map<String, Function>? converters,
  }) {
    // Extract rows
    final rowPattern = RegExp(
      r'<tr[^>]*>(.*?)</tr>',
      caseSensitive: false,
      dotAll: true,
    );

    final rawRows = <List<_CellData>>[];
    final rowMatches = rowPattern.allMatches(tableHtml);

    for (var rowMatch in rowMatches) {
      final rowHtml = rowMatch.group(1)!;

      // Extract cells with attributes
      final cellPattern = RegExp(
        r'<(th|td)([^>]*)>(.*?)</\1>',
        caseSensitive: false,
        dotAll: true,
      );

      final cells = <_CellData>[];
      final cellMatches = cellPattern.allMatches(rowHtml);

      for (var cellMatch in cellMatches) {
        final attrs = cellMatch.group(2)!;
        var content = cellMatch.group(3)!.trim();

        // Remove HTML tags
        content = content.replaceAll(RegExp(r'<[^>]+>'), '');
        content = DataFrameWebAPI._decodeHtmlEntities(content);

        // Extract colspan and rowspan (simplified pattern)
        final colspanMatch =
            RegExp(r'colspan\s*=\s*(\d+)', caseSensitive: false)
                .firstMatch(attrs);
        final rowspanMatch =
            RegExp(r'rowspan\s*=\s*(\d+)', caseSensitive: false)
                .firstMatch(attrs);

        final colspan =
            colspanMatch != null ? int.parse(colspanMatch.group(1)!) : 1;
        final rowspan =
            rowspanMatch != null ? int.parse(rowspanMatch.group(1)!) : 1;

        cells.add(_CellData(content, colspan, rowspan));
      }

      if (cells.isNotEmpty) {
        rawRows.add(cells);
      }
    }

    if (rawRows.isEmpty) return null;

    // Expand cells with colspan/rowspan
    final expandedRows = _expandSpans(rawRows);

    // Extract header
    List<String>? columnNames;
    var dataStartRow = 0;

    if (header >= 0 && header < expandedRows.length) {
      columnNames = expandedRows[header];
      dataStartRow = header + 1;
    }

    // Extract data rows
    final dataRows = <List<dynamic>>[];
    for (var i = dataStartRow; i < expandedRows.length; i++) {
      if (skiprows != null && skiprows.contains(i)) continue;

      final row = expandedRows[i];
      final parsedRow = <dynamic>[];

      for (var j = 0; j < row.length; j++) {
        var cell = row[j];

        // Check for NA values
        if (naValues.contains(cell)) {
          parsedRow.add(null);
          continue;
        }

        // Apply custom converter if available
        if (converters != null &&
            columnNames != null &&
            j < columnNames.length) {
          final colName = columnNames[j];
          if (converters.containsKey(colName)) {
            parsedRow.add(converters[colName]!(cell));
            continue;
          }
        }

        // Parse numbers
        if (parseNumbers) {
          final cleaned =
              cell.replaceAll(thousands, '').replaceAll(decimal, '.');
          // Remove currency symbols and percentage
          final numStr = cleaned.replaceAll(RegExp(r'[$€£¥%,\s]'), '');
          final numValue = num.tryParse(numStr);
          if (numValue != null) {
            parsedRow.add(numValue);
            continue;
          }
        }

        // Parse dates (basic implementation)
        if (parseDates) {
          final dateValue = DateTime.tryParse(cell);
          if (dateValue != null) {
            parsedRow.add(dateValue);
            continue;
          }
        }

        parsedRow.add(cell);
      }

      dataRows.add(parsedRow);
    }

    if (dataRows.isEmpty) return null;

    // Create DataFrame
    return DataFrame(
      dataRows,
      columns:
          columnNames ?? List.generate(dataRows[0].length, (i) => 'Column$i'),
    );
  }

  static List<List<String>> _expandSpans(List<List<_CellData>> rawRows) {
    if (rawRows.isEmpty) return [];

    // Calculate maximum columns needed
    var maxCols = 0;
    for (var row in rawRows) {
      var cols = 0;
      for (var cell in row) {
        cols += cell.colspan;
      }
      if (cols > maxCols) maxCols = cols;
    }

    // Create expanded grid
    final grid = List.generate(
      rawRows.length,
      (_) => List<String?>.filled(maxCols, null),
    );

    // Fill grid with cell data
    for (var i = 0; i < rawRows.length; i++) {
      var colIndex = 0;

      for (var cell in rawRows[i]) {
        // Find next available column
        while (colIndex < maxCols && grid[i][colIndex] != null) {
          colIndex++;
        }

        if (colIndex >= maxCols) break;

        // Fill cell and spans
        for (var r = 0; r < cell.rowspan && (i + r) < rawRows.length; r++) {
          for (var c = 0; c < cell.colspan && (colIndex + c) < maxCols; c++) {
            grid[i + r][colIndex + c] = cell.content;
          }
        }

        colIndex += cell.colspan;
      }
    }

    // Convert to List<List<String>>
    return grid.map((row) => row.map((cell) => cell ?? '').toList()).toList();
  }
}

class _CellData {
  final String content;
  final int colspan;
  final int rowspan;

  _CellData(this.content, this.colspan, this.rowspan);
}

/// Enhanced XML reading with nested structure support.
class XmlParser {
  /// Parse XML with support for nested structures.
  ///
  /// Parameters:
  /// - `xml`: XML string to parse
  /// - `rowName`: Name of row elements
  /// - `parseNumbers`: Parse numeric values
  /// - `attrPrefix`: Prefix for attribute columns
  /// - `flattenNested`: Flatten nested elements (default: true)
  /// - `nestedSeparator`: Separator for nested keys (default: '.')
  ///
  /// Returns a DataFrame.
  static DataFrame parse(
    String xml, {
    String rowName = 'row',
    bool parseNumbers = true,
    String attrPrefix = '@',
    bool flattenNested = true,
    String nestedSeparator = '.',
  }) {
    final rows = <Map<String, dynamic>>[];

    // Extract row elements
    final rowPattern = RegExp(
      '<$rowName[^>]*>(.*?)</$rowName>',
      caseSensitive: false,
      dotAll: true,
    );

    final rowMatches = rowPattern.allMatches(xml);

    for (var rowMatch in rowMatches) {
      final rowXml = rowMatch.group(0)!;
      final rowContent = rowMatch.group(1)!;
      final rowData = <String, dynamic>{};

      // Extract attributes
      final attrPattern = RegExp(r'(\w+)="([^"]*)"');
      final attrMatches = attrPattern.allMatches(rowXml);

      for (var attrMatch in attrMatches) {
        final attrName = attrMatch.group(1)!;
        var attrValue = attrMatch.group(2)!;
        attrValue = DataFrameWebAPI._decodeXmlEntities(attrValue);
        rowData['$attrPrefix$attrName'] = attrValue;
      }

      // Extract child elements (including nested)
      if (flattenNested) {
        _extractNestedElements(
            rowContent, rowData, '', nestedSeparator, parseNumbers);
      } else {
        _extractSimpleElements(rowContent, rowData, parseNumbers);
      }

      if (rowData.isNotEmpty) {
        rows.add(rowData);
      }
    }

    if (rows.isEmpty) {
      return DataFrame([], columns: []);
    }

    // Get all unique column names
    final allColumns = <String>{};
    for (var row in rows) {
      allColumns.addAll(row.keys);
    }

    final columnList = allColumns.toList()..sort();

    // Build data matrix
    final dataRows = <List<dynamic>>[];
    for (var row in rows) {
      final dataRow = <dynamic>[];
      for (var col in columnList) {
        dataRow.add(row[col]);
      }
      dataRows.add(dataRow);
    }

    return DataFrame(dataRows, columns: columnList);
  }

  static void _extractNestedElements(
    String xml,
    Map<String, dynamic> data,
    String prefix,
    String separator,
    bool parseNumbers,
  ) {
    // Match both simple and nested elements
    final elemPattern = RegExp(
      r'<(\w+)>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    );

    final matches = elemPattern.allMatches(xml);

    for (var match in matches) {
      final elemName = match.group(1)!;
      final elemContent = match.group(2)!.trim();

      final fullKey = prefix.isEmpty ? elemName : '$prefix$separator$elemName';

      // Check if content has nested elements
      if (elemPattern.hasMatch(elemContent)) {
        // Recursively extract nested elements
        _extractNestedElements(
            elemContent, data, fullKey, separator, parseNumbers);
      } else {
        // Leaf element
        var value = DataFrameWebAPI._decodeXmlEntities(elemContent);

        if (parseNumbers) {
          final numValue = num.tryParse(value);
          data[fullKey] = numValue ?? value;
        } else {
          data[fullKey] = value;
        }
      }
    }
  }

  static void _extractSimpleElements(
    String xml,
    Map<String, dynamic> data,
    bool parseNumbers,
  ) {
    final elemPattern = RegExp(
      r'<(\w+)>([^<]*)</\1>',
      caseSensitive: false,
    );

    final matches = elemPattern.allMatches(xml);

    for (var match in matches) {
      final elemName = match.group(1)!;
      var elemValue = match.group(2)!.trim();
      elemValue = DataFrameWebAPI._decodeXmlEntities(elemValue);

      if (parseNumbers) {
        final numValue = num.tryParse(elemValue);
        data[elemName] = numValue ?? elemValue;
      } else {
        data[elemName] = elemValue;
      }
    }
  }
}
