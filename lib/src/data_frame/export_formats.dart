part of 'data_frame.dart';

/// Extension providing export format methods for DataFrame.
///
/// Includes methods for exporting to LaTeX, Markdown, formatted strings, and record arrays.
extension DataFrameExportFormats on DataFrame {
  /// Export DataFrame to LaTeX table format.
  ///
  /// Parameters:
  /// - `caption`: Table caption (optional)
  /// - `label`: LaTeX label for referencing (optional)
  /// - `position`: Table position specifier (default: 'h')
  /// - `columnFormat`: Column format string (default: auto-generated)
  /// - `index`: Include index column (default: true)
  /// - `header`: Include header row (default: true)
  /// - `escape`: Escape special LaTeX characters (default: true)
  /// - `bold`: Bold header row (default: true)
  /// - `longtable`: Use longtable environment for multi-page tables (default: false)
  ///
  /// Returns a LaTeX table string.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 25, 50000],
  ///   ['Bob', 30, 60000],
  /// ], columns: ['Name', 'Age', 'Salary']);
  ///
  /// var latex = df.toLatex(
  ///   caption: 'Employee Data',
  ///   label: 'tab:employees',
  /// );
  /// ```
  String toLatex({
    String? caption,
    String? label,
    String position = 'h',
    String? columnFormat,
    bool index = true,
    bool header = true,
    bool escape = true,
    bool bold = true,
    bool longtable = false,
  }) {
    final buffer = StringBuffer();

    // Start table environment
    if (longtable) {
      buffer.writeln(
          '\\begin{longtable}{${columnFormat ?? _generateColumnFormat(index)}}');
      if (caption != null) {
        buffer.writeln('\\caption{$caption}');
        if (label != null) {
          buffer.writeln('\\label{$label}');
        }
        buffer.writeln('\\\\');
      }
    } else {
      buffer.writeln('\\begin{table}[$position]');
      if (caption != null) {
        buffer.writeln('\\caption{$caption}');
      }
      if (label != null) {
        buffer.writeln('\\label{$label}');
      }
      buffer.writeln('\\centering');
      buffer.writeln(
          '\\begin{tabular}{${columnFormat ?? _generateColumnFormat(index)}}');
    }

    buffer.writeln('\\hline');

    // Header row
    if (header) {
      final headerCells = <String>[];
      if (index) {
        headerCells.add(bold ? '\\textbf{}' : '');
      }
      for (var col in columns) {
        final cell = escape ? _escapeLatex(col) : col;
        headerCells.add(bold ? '\\textbf{$cell}' : cell);
      }
      buffer.writeln('${headerCells.join(' & ')} \\\\');
      buffer.writeln('\\hline');
    }

    // Data rows
    for (var i = 0; i < rowCount; i++) {
      final rowCells = <String>[];
      if (index) {
        final idxValue = this.index[i].toString();
        rowCells.add(escape ? _escapeLatex(idxValue) : idxValue);
      }
      for (var col in columns) {
        final value = this[col][i];
        final cell = value?.toString() ?? '';
        rowCells.add(escape ? _escapeLatex(cell) : cell);
      }
      buffer.writeln('${rowCells.join(' & ')} \\\\');
    }

    buffer.writeln('\\hline');

    // End table environment
    if (longtable) {
      buffer.writeln('\\end{longtable}');
    } else {
      buffer.writeln('\\end{tabular}');
      buffer.writeln('\\end{table}');
    }

    return buffer.toString();
  }

  /// Export DataFrame to Markdown table format.
  ///
  /// Parameters:
  /// - `index`: Include index column (default: true)
  /// - `tablefmt`: Table format style (default: 'pipe')
  ///   - 'pipe': GitHub-flavored markdown (default)
  ///   - 'grid': Grid-style table
  ///   - 'simple': Simple format without borders
  /// - `align`: Column alignment ('left', 'center', 'right', or list per column)
  /// - `floatfmt`: Format string for floating point numbers (e.g., '.2f')
  /// - `maxColWidth`: Maximum column width (default: null = no limit)
  ///
  /// Returns a Markdown table string.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 25, 50000.50],
  ///   ['Bob', 30, 60000.75],
  /// ], columns: ['Name', 'Age', 'Salary']);
  ///
  /// var markdown = df.toMarkdown(floatfmt: '.2f');
  /// ```
  String toMarkdown({
    bool index = true,
    String tablefmt = 'pipe',
    dynamic align = 'left',
    String? floatfmt,
    int? maxColWidth,
  }) {
    switch (tablefmt) {
      case 'pipe':
        return _toMarkdownPipe(index, align, floatfmt, maxColWidth);
      case 'grid':
        return _toMarkdownGrid(index, align, floatfmt, maxColWidth);
      case 'simple':
        return _toMarkdownSimple(index, align, floatfmt, maxColWidth);
      default:
        throw ArgumentError('Unknown tablefmt: $tablefmt');
    }
  }

  /// Export DataFrame to formatted string representation.
  ///
  /// Parameters:
  /// - `maxRows`: Maximum number of rows to display (default: 60)
  /// - `maxCols`: Maximum number of columns to display (default: 20)
  /// - `maxColWidth`: Maximum column width (default: 50)
  /// - `index`: Include index column (default: true)
  /// - `header`: Include header row (default: true)
  /// - `lineWidth`: Maximum line width (default: 80)
  /// - `floatFormat`: Format string for floating point numbers
  /// - `sparsify`: Sparsify MultiIndex display (default: true)
  ///
  /// Returns a formatted string representation.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 25, 50000],
  ///   ['Bob', 30, 60000],
  /// ], columns: ['Name', 'Age', 'Salary']);
  ///
  /// print(df.toStringFormatted(maxColWidth: 20));
  /// ```
  String toStringFormatted({
    int maxRows = 60,
    int maxCols = 20,
    int maxColWidth = 50,
    bool index = true,
    bool header = true,
    int lineWidth = 80,
    String? floatFormat,
    bool sparsify = true,
  }) {
    final buffer = StringBuffer();

    // Determine which rows and columns to display
    final displayRows = rowCount <= maxRows
        ? List.generate(rowCount, (i) => i)
        : [
            ...List.generate(maxRows ~/ 2, (i) => i),
            -1, // Marker for ellipsis
            ...List.generate(maxRows ~/ 2, (i) => rowCount - (maxRows ~/ 2) + i)
          ];

    final displayCols = columns.length <= maxCols
        ? columns
        : [
            ...columns.sublist(0, maxCols ~/ 2),
            '...', // Marker for ellipsis
            ...columns.sublist(columns.length - (maxCols ~/ 2))
          ];

    // Calculate column widths
    final colWidths = <String, int>{};
    if (index) {
      colWidths['__index__'] = _calculateColumnWidth(
        this.index.map((e) => e.toString()).toList(),
        'Index',
        maxColWidth,
      );
    }

    for (var col in displayCols) {
      if (col == '...') {
        colWidths[col] = 3;
        continue;
      }
      final values = displayRows
          .where((i) => i != -1)
          .map((i) => _formatValue(this[col][i], floatFormat))
          .toList();
      colWidths[col] = _calculateColumnWidth(values, col, maxColWidth);
    }

    // Header row
    if (header) {
      final headerParts = <String>[];
      if (index) {
        headerParts.add(''.padRight(colWidths['__index__']!));
      }
      for (var col in displayCols) {
        headerParts.add(col.padRight(colWidths[col]!));
      }
      buffer.writeln(headerParts.join('  '));

      // Separator line
      final separatorParts = <String>[];
      if (index) {
        separatorParts.add('-' * colWidths['__index__']!);
      }
      for (var col in displayCols) {
        separatorParts.add('-' * colWidths[col]!);
      }
      buffer.writeln(separatorParts.join('  '));
    }

    // Data rows
    for (var i in displayRows) {
      if (i == -1) {
        // Ellipsis row
        final ellipsisParts = <String>[];
        if (index) {
          ellipsisParts.add('...'.padRight(colWidths['__index__']!));
        }
        for (var col in displayCols) {
          ellipsisParts.add('...'.padRight(colWidths[col]!));
        }
        buffer.writeln(ellipsisParts.join('  '));
        continue;
      }

      final rowParts = <String>[];
      if (index) {
        rowParts
            .add(this.index[i].toString().padRight(colWidths['__index__']!));
      }
      for (var col in displayCols) {
        if (col == '...') {
          rowParts.add('...'.padRight(colWidths[col]!));
        } else {
          final value = _formatValue(this[col][i], floatFormat);
          rowParts.add(value.padRight(colWidths[col]!));
        }
      }
      buffer.writeln(rowParts.join('  '));
    }

    // Footer with shape info
    buffer.writeln();
    buffer.writeln('[${rowCount} rows x ${columns.length} columns]');

    return buffer.toString();
  }

  /// Convert DataFrame to list of record maps.
  ///
  /// Each row is converted to a Map with column names as keys.
  ///
  /// Parameters:
  /// - `index`: Include index in records (default: false)
  /// - `indexName`: Name for index column if included (default: 'index')
  /// - `intoType`: Convert to specific type ('dict', 'list', 'series')
  ///
  /// Returns a list of maps representing each row.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   ['Alice', 25],
  ///   ['Bob', 30],
  /// ], columns: ['Name', 'Age']);
  ///
  /// var records = df.toRecords();
  /// // [{'Name': 'Alice', 'Age': 25}, {'Name': 'Bob', 'Age': 30}]
  /// ```
  List<Map<String, dynamic>> toRecords({
    bool index = false,
    String indexName = 'index',
  }) {
    final records = <Map<String, dynamic>>[];

    for (var i = 0; i < rowCount; i++) {
      final record = <String, dynamic>{};

      if (index) {
        record[indexName] = this.index[i];
      }

      for (var col in columns) {
        record[col] = this[col][i];
      }

      records.add(record);
    }

    return records;
  }

  // Helper methods

  String _generateColumnFormat(bool includeIndex) {
    final numCols = columns.length + (includeIndex ? 1 : 0);
    return 'l' * numCols;
  }

  String _escapeLatex(String text) {
    return text
        .replaceAll('\\', '\\textbackslash{}')
        .replaceAll('&', '\\&')
        .replaceAll('%', '\\%')
        .replaceAll('\$', '\\\$')
        .replaceAll('#', '\\#')
        .replaceAll('_', '\\_')
        .replaceAll('{', '\\{')
        .replaceAll('}', '\\}')
        .replaceAll('~', '\\textasciitilde{}')
        .replaceAll('^', '\\textasciicircum{}');
  }

  String _toMarkdownPipe(
      bool index, dynamic align, String? floatfmt, int? maxColWidth) {
    final buffer = StringBuffer();

    // Determine alignment
    final alignments = _parseAlignment(align, columns.length + (index ? 1 : 0));

    // Header row
    final headerCells = <String>[];
    if (index) {
      headerCells.add('');
    }
    headerCells.addAll(columns.map((c) => c.toString()));
    buffer.writeln('| ${headerCells.join(' | ')} |');

    // Separator row with alignment
    final separators = <String>[];
    for (var i = 0; i < headerCells.length; i++) {
      final al = alignments[i];
      if (al == 'center') {
        separators.add(':---:');
      } else if (al == 'right') {
        separators.add('---:');
      } else {
        separators.add(':---');
      }
    }
    buffer.writeln('| ${separators.join(' | ')} |');

    // Data rows
    for (var i = 0; i < rowCount; i++) {
      final rowCells = <String>[];
      if (index) {
        rowCells.add(this.index[i].toString());
      }
      for (var col in columns) {
        final value = _formatValue(this[col][i], floatfmt);
        final truncated = maxColWidth != null && value.length > maxColWidth
            ? '${value.substring(0, maxColWidth - 3)}...'
            : value;
        rowCells.add(truncated);
      }
      buffer.writeln('| ${rowCells.join(' | ')} |');
    }

    return buffer.toString();
  }

  String _toMarkdownGrid(
      bool index, dynamic align, String? floatfmt, int? maxColWidth) {
    // Simplified grid format
    return _toMarkdownPipe(index, align, floatfmt, maxColWidth);
  }

  String _toMarkdownSimple(
      bool index, dynamic align, String? floatfmt, int? maxColWidth) {
    final buffer = StringBuffer();

    // Header row
    final headerCells = <String>[];
    if (index) {
      headerCells.add('');
    }
    headerCells.addAll(columns.map((c) => c.toString()));
    buffer.writeln(headerCells.join('  '));

    // Separator
    buffer.writeln(headerCells.map((c) => '-' * (c.length + 2)).join(''));

    // Data rows
    for (var i = 0; i < rowCount; i++) {
      final rowCells = <String>[];
      if (index) {
        rowCells.add(this.index[i].toString());
      }
      for (var col in columns) {
        final value = _formatValue(this[col][i], floatfmt);
        rowCells.add(value);
      }
      buffer.writeln(rowCells.join('  '));
    }

    return buffer.toString();
  }

  List<String> _parseAlignment(dynamic align, int numCols) {
    if (align is String) {
      return List.filled(numCols, align);
    } else if (align is List) {
      return align.map((a) => a.toString()).toList();
    }
    return List.filled(numCols, 'left');
  }

  String _formatValue(dynamic value, String? floatfmt) {
    if (value == null) {
      return '';
    }
    if (value is double && floatfmt != null) {
      // Parse format string like '.2f'
      final match = RegExp(r'\.(\d+)f').firstMatch(floatfmt);
      if (match != null) {
        final decimals = int.parse(match.group(1)!);
        return value.toStringAsFixed(decimals);
      }
    }
    return value.toString();
  }

  int _calculateColumnWidth(List<String> values, String header, int maxWidth) {
    var width = header.length;
    for (var value in values) {
      if (value.length > width) {
        width = value.length;
      }
    }
    return width > maxWidth ? maxWidth : width;
  }
}
