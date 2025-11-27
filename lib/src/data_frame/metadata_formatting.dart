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
