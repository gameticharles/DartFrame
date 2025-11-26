part of 'series.dart';

/// Extension for Series enhancements
extension SeriesEnhancements on Series {
  /// Enhanced map with na_action parameter.
  Series mapEnhanced(
    Function(dynamic) func, {
    String? naAction,
  }) {
    if (naAction == 'ignore') {
      final mappedData = data.map((value) {
        if (value == null) return null;
        return func(value);
      }).toList();
      return Series(mappedData, name: name, index: index);
    } else {
      final mappedData = data.map(func).toList();
      return Series(mappedData, name: name, index: index);
    }
  }

  /// Enhanced replace with regex and method parameters.
  Series replaceEnhanced({
    dynamic toReplace,
    dynamic value,
    bool regex = false,
    String? method,
  }) {
    final newData = <dynamic>[];

    if (regex && toReplace is String) {
      final pattern = RegExp(toReplace);
      for (final item in data) {
        if (item == null) {
          newData.add(null);
        } else if (item is String && pattern.hasMatch(item)) {
          newData.add(value);
        } else {
          newData.add(item);
        }
      }
    } else if (toReplace is List) {
      final valueList =
          value is List ? value : List.filled(toReplace.length, value);
      for (final item in data) {
        final idx = toReplace.indexOf(item);
        if (idx != -1 && idx < valueList.length) {
          newData.add(valueList[idx]);
        } else {
          newData.add(item);
        }
      }
    } else {
      for (final item in data) {
        newData.add(item == toReplace ? value : item);
      }
    }

    Series result = Series(newData, name: name, index: index);

    if (method != null) {
      if (method == 'pad' || method == 'ffill') {
        result = result.ffill();
      } else if (method == 'bfill') {
        result = result.bfill();
      }
    }

    return result;
  }

  /// Repeat elements of Series.
  Series repeatElements(dynamic repeats) {
    final newData = <dynamic>[];
    final newIndex = <dynamic>[];

    if (repeats is int) {
      for (int i = 0; i < length; i++) {
        for (int j = 0; j < repeats; j++) {
          newData.add(data[i]);
          newIndex.add(index[i]);
        }
      }
    } else if (repeats is List<int>) {
      if (repeats.length != length) {
        throw ArgumentError('repeats must have same length as Series');
      }
      for (int i = 0; i < length; i++) {
        for (int j = 0; j < repeats[i]; j++) {
          newData.add(data[i]);
          newIndex.add(index[i]);
        }
      }
    } else {
      throw ArgumentError('repeats must be int or List<int>');
    }

    return Series(newData, name: name, index: newIndex);
  }

  /// Squeeze 1-dimensional axis objects into scalars.
  dynamic squeeze() {
    if (length == 1) {
      return data[0];
    }
    return this;
  }

  /// Enhanced dtype inference with better type detection.
  String get dtypeEnhanced {
    if (isEmpty) return 'empty';

    final firstNonNull = data.firstWhere((v) => v != null, orElse: () => null);
    if (firstNonNull == null) return 'null';

    final nonNullData = data.where((v) => v != null).toList();
    if (nonNullData.isEmpty) return 'null';

    if (nonNullData.every((v) => v is int)) return 'int';
    if (nonNullData.every((v) => v is double)) return 'double';
    if (nonNullData.every((v) => v is num)) return 'num';
    if (nonNullData.every((v) => v is String)) return 'string';
    if (nonNullData.every((v) => v is bool)) return 'bool';
    if (nonNullData.every((v) => v is DateTime)) return 'datetime';
    if (nonNullData.every((v) => v is Duration)) return 'duration';
    if (nonNullData.every((v) => v is List)) return 'list';
    if (nonNullData.every((v) => v is Map)) return 'map';

    return 'object';
  }

  /// Dictionary of global attributes for storing metadata.
  Map<String, dynamic> get attrs {
    return _SeriesAttrs._getAttrs(this);
  }

  /// Get flags for this Series.
  Map<String, dynamic> get flags {
    return _SeriesFlags._getFlags(this);
  }

  /// Return new Series with updated flags.
  Series setFlags({bool? allowsDuplicateLabels}) {
    final newS = Series(List.from(data), name: name, index: List.from(index));
    if (allowsDuplicateLabels != null) {
      _SeriesFlags._setFlag(
          newS, 'allows_duplicate_labels', allowsDuplicateLabels);
    }
    return newS;
  }

  /// Enhanced string representation with formatting options.
  String toStringEnhanced({
    int? maxRows,
    int maxWidth = 20,
    String Function(dynamic)? formatter,
    bool showIndex = true,
    bool showDtype = false,
  }) {
    final buffer = StringBuffer();
    final sLength = length;
    final sIndex = index;
    final sData = data;
    final sName = name;

    final displayRows = maxRows != null && sLength > maxRows
        ? [
            ...List.generate(maxRows ~/ 2, (i) => i),
            -1,
            ...List.generate(maxRows ~/ 2, (i) => sLength - (maxRows ~/ 2) + i),
          ]
        : List.generate(sLength, (i) => i);

    var indexWidth = 0;
    if (showIndex) {
      indexWidth = sIndex
          .map((idx) => idx.toString().length)
          .fold(0, (max, len) => len > max ? len : max)
          .clamp(0, maxWidth);
    }

    var valueWidth = sName.toString().length ?? 5;
    for (final rowIdx in displayRows) {
      if (rowIdx == -1) continue;
      final value = sData[rowIdx];
      final formatted = formatter != null ? formatter(value) : value.toString();
      valueWidth =
          valueWidth > formatted.length ? valueWidth : formatted.length;
    }
    valueWidth = valueWidth.clamp(0, maxWidth);

    if (sName.toString().isNotEmpty) {
      if (showIndex) {
        buffer.write(''.padRight(indexWidth));
        buffer.write('  ');
      }
      buffer.writeln(sName.toString().padRight(valueWidth));
    }

    for (final rowIdx in displayRows) {
      if (rowIdx == -1) {
        if (showIndex) {
          buffer.write('...'.padRight(indexWidth));
          buffer.write('  ');
        }
        buffer.writeln('...');
        continue;
      }

      if (showIndex) {
        buffer.write(sIndex[rowIdx].toString().padRight(indexWidth));
        buffer.write('  ');
      }

      final value = sData[rowIdx];
      final formatted = formatter != null ? formatter(value) : value.toString();
      buffer.writeln(formatted.padRight(valueWidth));
    }

    if (showDtype) {
      buffer.writeln();
      buffer.writeln('dtype: $dtypeEnhanced');
      buffer.writeln('length: $sLength');
    }

    return buffer.toString();
  }
}

class _SeriesAttrs {
  static final Map<int, Map<String, dynamic>> _storage = {};

  static Map<String, dynamic> _getAttrs(Series s) {
    final key = s.hashCode;
    if (!_storage.containsKey(key)) {
      _storage[key] = {};
    }
    return _storage[key]!;
  }
}

class _SeriesFlags {
  static final Map<int, Map<String, dynamic>> _storage = {};

  static Map<String, dynamic> _getFlags(Series s) {
    final key = s.hashCode;
    if (!_storage.containsKey(key)) {
      _storage[key] = {
        'allows_duplicate_labels': true,
      };
    }
    return _storage[key]!;
  }

  static void _setFlag(Series s, String flag, dynamic value) {
    final key = s.hashCode;
    if (!_storage.containsKey(key)) {
      _storage[key] = {
        'allows_duplicate_labels': true,
      };
    }
    _storage[key]![flag] = value;
  }
}
