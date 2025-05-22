part of '../../dartframe.dart';

class StringSeriesAccessor {
  final Series _series;

  StringSeriesAccessor(this._series);

  dynamic _getMissingRep() {
    return _series._parentDataFrame?.replaceMissingValueWith ?? null;
  }

  Series _applyStringOperation(
      dynamic Function(String) operation, String newNameSuffix, {dynamic defaultValueIfError}) {
    final missingRep = _getMissingRep();
    List<dynamic> resultData = [];

    for (var value in _series.data) {
      if (value is String) {
        try {
          resultData.add(operation(value));
        } catch (e) {
          resultData.add(defaultValueIfError ?? missingRep);
        }
      } else {
        resultData.add(missingRep);
      }
    }
    return Series(resultData, name: '${_series.name}$newNameSuffix', index: _series.index?.toList());
  }

  Series _applyStringBoolOperation(
      bool Function(String) operation, String newNameSuffix) {
    final missingRep = _getMissingRep();
    List<dynamic> resultData = []; // Will store bools or missingRep

    for (var value in _series.data) {
      if (value is String) {
        try {
          resultData.add(operation(value));
        } catch (e) {
          resultData.add(missingRep); // Error during operation
        }
      } else {
        resultData.add(missingRep); // Not a string or already a missing value
      }
    }
    return Series(resultData, name: '${_series.name}$newNameSuffix', index: _series.index?.toList());
  }

  /// Returns a new Series of ints representing the length of each string.
  /// Non-string elements or nulls result in the Series' missing value representation.
  Series len() {
    return _applyStringOperation((s) => s.length, '_len');
  }

  /// Returns a new Series with all strings converted to lowercase.
  /// Non-strings/nulls remain as the Series' missing value representation.
  Series lower() {
    return _applyStringOperation((s) => s.toLowerCase(), '_lower');
  }

  /// Returns a new Series with all strings converted to uppercase.
  /// Non-strings/nulls remain as the Series' missing value representation.
  Series upper() {
    return _applyStringOperation((s) => s.toUpperCase(), '_upper');
  }

  /// Returns a new Series with leading/trailing whitespace removed from each string.
  /// Non-strings/nulls remain as the Series' missing value representation.
  Series strip() {
    return _applyStringOperation((s) => s.trim(), '_strip');
  }

  /// Returns a new Series of bools indicating if each string starts with the given pattern.
  /// Non-strings/nulls result in the Series' missing value representation.
  Series startswith(String pattern) {
    return _applyStringBoolOperation((s) => s.startsWith(pattern), '_startswith_$pattern');
  }

  /// Returns a new Series of bools indicating if each string ends with the given pattern.
  /// Non-strings/nulls result in the Series' missing value representation.
  Series endswith(String pattern) {
    return _applyStringBoolOperation((s) => s.endsWith(pattern), '_endswith_$pattern');
  }

  /// Returns a new Series of bools indicating if each string contains the given pattern.
  /// Non-strings/nulls result in the Series' missing value representation.
  Series contains(String pattern) {
    return _applyStringBoolOperation((s) => s.contains(pattern), '_contains_$pattern');
  }

  /// Returns a new Series where occurrences of `from` (String or RegExp) in each string are replaced with `to`.
  /// Non-strings/nulls remain as the Series' missing value representation.
  Series replace(Pattern from, String to) {
    String fromPatternString = from is RegExp ? from.pattern : from.toString();
    // Sanitize fromPatternString for name to avoid issues with special characters if any
    String sanitizedFromName = fromPatternString.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    return _applyStringOperation((s) => s.replaceAll(from, to), '_replace_${sanitizedFromName}_with_$to');
  }
}
