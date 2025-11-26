part of 'data_frame.dart';

/// Extension for DataFrame metadata and formatting enhancements
extension DataFrameMetadataFormatting on DataFrame {
  /// Dictionary of global attributes for storing metadata.
  Map<String, dynamic> get attrs {
    return _DataFrameAttrs._getAttrs(this);
  }

  /// Get flags for this DataFrame.
  Map<String, dynamic> get flags {
    return _DataFrameFlags._getFlags(this);
  }

  /// Return new DataFrame with updated flags.
  DataFrame setFlags({bool? allowsDuplicateLabels}) {
    final newDf = copy();
    if (allowsDuplicateLabels != null) {
      _DataFrameFlags._setFlag(
          newDf, 'allows_duplicate_labels', allowsDuplicateLabels);
    }
    return newDf;
  }

  /// Enhanced string representation with formatting options.
  String toStringEnhanced({
    int? maxRows,
    int? maxCols,
    int maxColWidth = 20,
    Map<String, String Function(dynamic)>? formatters,
    bool showIndex = true,
    bool showDtype = false,
  }) {
    final buffer = StringBuffer();
    final dfLength = rowCount;
    final dfColumns = columns;
    final dfIndex = index;

    // Determine which rows and columns to display
    final displayRows = maxRows != null && dfLength > maxRows
        ? [
            ...List.generate(maxRows ~/ 2, (i) => i),
            -1,
            ...List.generate(
                maxRows ~/ 2, (i) => dfLength - (maxRows ~/ 2) + i),
          ]
        : List.generate(dfLength, (i) => i);

    final displayCols = maxCols != null && dfColumns.length > maxCols
        ? [
            ...List.generate(maxCols ~/ 2, (i) => i),
            -1,
            ...List.generate(
                maxCols ~/ 2, (i) => dfColumns.length - (maxCols ~/ 2) + i),
          ]
        : List.generate(dfColumns.length, (i) => i);

    // Calculate column widths
    final colWidths = <int>[];
    if (showIndex) {
      final indexWidth = dfIndex
          .map((idx) => idx.toString().length)
          .fold(0, (max, len) => len > max ? len : max)
          .clamp(0, maxColWidth);
      colWidths.add(indexWidth);
    }

    for (final colIdx in displayCols) {
      if (colIdx == -1) {
        colWidths.add(3);
        continue;
      }
      final col = dfColumns[colIdx];
      final colName = col.toString();
      var width = colName.length;

      for (final rowIdx in displayRows) {
        if (rowIdx == -1) continue;
        final value = this[col][rowIdx];
        final formatted = formatters?.containsKey(colName) == true
            ? formatters![colName]!(value)
            : value.toString();
        width = width > formatted.length ? width : formatted.length;
      }

      colWidths.add(width.clamp(0, maxColWidth));
    }

    // Header row
    if (showIndex) {
      buffer.write(''.padRight(colWidths[0]));
      buffer.write('  ');
    }

    var colWidthIdx = showIndex ? 1 : 0;
    for (final colIdx in displayCols) {
      if (colIdx == -1) {
        buffer.write('...');
      } else {
        final colName = dfColumns[colIdx].toString();
        buffer.write(colName.padRight(colWidths[colWidthIdx]));
      }
      buffer.write('  ');
      colWidthIdx++;
    }
    buffer.writeln();

    // Data rows
    for (final rowIdx in displayRows) {
      if (rowIdx == -1) {
        if (showIndex) {
          buffer.write('...'.padRight(colWidths[0]));
          buffer.write('  ');
        }
        colWidthIdx = showIndex ? 1 : 0;
        for (final _ in displayCols) {
          buffer.write('...'.padRight(colWidths[colWidthIdx]));
          buffer.write('  ');
          colWidthIdx++;
        }
        buffer.writeln();
        continue;
      }

      if (showIndex) {
        buffer.write(dfIndex[rowIdx].toString().padRight(colWidths[0]));
        buffer.write('  ');
      }

      colWidthIdx = showIndex ? 1 : 0;
      for (final colIdx in displayCols) {
        if (colIdx == -1) {
          buffer.write('...'.padRight(colWidths[colWidthIdx]));
        } else {
          final col = dfColumns[colIdx];
          final value = this[col][rowIdx];
          final colName = col.toString();
          final formatted = formatters?.containsKey(colName) == true
              ? formatters![colName]!(value)
              : value.toString();
          buffer.write(formatted.padRight(colWidths[colWidthIdx]));
        }
        buffer.write('  ');
        colWidthIdx++;
      }
      buffer.writeln();
    }

    // Data types footer
    if (showDtype) {
      buffer.writeln();
      buffer.writeln('dtypes:');
      for (final col in dfColumns) {
        final dtype = _inferColumnType(col);
        buffer.writeln('  $col: $dtype');
      }
    }

    return buffer.toString();
  }

  String _inferColumnType(dynamic col) {
    final series = column(col);
    if (series.isEmpty) return 'empty';

    final firstNonNull =
        series.data.firstWhere((v) => v != null, orElse: () => null);
    if (firstNonNull == null) return 'null';

    if (firstNonNull is int) return 'int';
    if (firstNonNull is double) return 'double';
    if (firstNonNull is num) return 'num';
    if (firstNonNull is String) return 'string';
    if (firstNonNull is bool) return 'bool';
    if (firstNonNull is DateTime) return 'datetime';
    return 'object';
  }

  /// Squeeze 1-dimensional axis objects into scalars.
  dynamic squeeze() {
    final dfLength = rowCount;
    final dfColumns = columns;

    if (dfLength == 1 && dfColumns.length == 1) {
      return this[dfColumns[0]][0];
    } else if (dfColumns.length == 1) {
      return column(dfColumns[0]);
    } else if (dfLength == 1) {
      final data = <dynamic>[];
      for (final col in dfColumns) {
        data.add(this[col][0]);
      }
      return Series(data,
          name: 'row_0', index: dfColumns.map((c) => c.toString()).toList());
    }
    return this;
  }
}

class _DataFrameAttrs {
  static final Map<int, Map<String, dynamic>> _storage = {};

  static Map<String, dynamic> _getAttrs(DataFrame df) {
    final key = df.hashCode;
    if (!_storage.containsKey(key)) {
      _storage[key] = {};
    }
    return _storage[key]!;
  }
}

class _DataFrameFlags {
  static final Map<int, Map<String, dynamic>> _storage = {};

  static Map<String, dynamic> _getFlags(DataFrame df) {
    final key = df.hashCode;
    if (!_storage.containsKey(key)) {
      _storage[key] = {
        'allows_duplicate_labels': true,
      };
    }
    return _storage[key]!;
  }

  static void _setFlag(DataFrame df, String flag, dynamic value) {
    final key = df.hashCode;
    if (!_storage.containsKey(key)) {
      _storage[key] = {
        'allows_duplicate_labels': true,
      };
    }
    _storage[key]![flag] = value;
  }
}
