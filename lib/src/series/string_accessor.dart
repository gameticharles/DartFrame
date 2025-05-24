part of '../../dartframe.dart';

class StringSeriesAccessor {
  final Series _series;

  StringSeriesAccessor(this._series);

  // No longer need _getMissingRep() here, will use _series._missingRepresentation directly.
  Series _applyStringOperation(
      dynamic Function(String) operation, String newNameSuffix,
      {dynamic defaultValueIfError}) {
    final missingRep = _series._missingRepresentation; // Use Series' helper
    List<dynamic> resultData = [];

    for (var value in _series.data) {
      if (_series._isMissing(value)) {
        // Use Series' helper
        resultData.add(missingRep);
      } else if (value is String) {
        try {
          resultData.add(operation(value));
        } catch (e) {
          resultData.add(defaultValueIfError ?? missingRep);
        }
      } else {
        // Not a string and not identified as missing by _isMissing (e.g. a number)
        resultData.add(missingRep);
      }
    }
    return Series(resultData,
        name: '${_series.name}$newNameSuffix', index: _series.index);
  }

  Series _applyStringBoolOperation(
      bool Function(String) operation, String newNameSuffix) {
    final missingRep = _series._missingRepresentation; // Use Series' helper
    List<dynamic> resultData = [];

    for (var value in _series.data) {
      if (_series._isMissing(value)) {
        // Use Series' helper
        resultData.add(missingRep);
      } else if (value is String) {
        try {
          resultData.add(operation(value));
        } catch (e) {
          resultData.add(missingRep);
        }
      } else {
        // Not a string and not identified as missing
        resultData.add(missingRep);
      }
    }
    return Series(resultData,
        name: '${_series.name}$newNameSuffix', index: _series.index);
  }

  /// Returns a new Series of `int`s representing the length of each string.
  ///
  /// For elements that are not strings or are missing (as defined by the
  /// Series' context, i.e., `null` or `_parentDataFrame.replaceMissingValueWith`),
  /// the result in the new Series will be the Series' missing value representation.
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['apple', 'banana', null, 'kiwi'], name: 'fruits');
  /// print(s.str.len());
  /// // Output:
  /// // fruits_len:
  /// // 0       5
  /// // 1       6
  /// // 2       null (or df missing rep)
  /// // 3       4
  /// // Length: 4
  /// // Type: int
  /// ```
  Series len() {
    return _applyStringOperation((s) => s.length, '_len');
  }

  /// Returns a new Series with all strings converted to lowercase.
  ///
  /// For elements that are not strings or are missing,
  /// the result will be the Series' missing value representation.
  /// Example: `series.str.lower()`
  Series lower() {
    return _applyStringOperation((s) => s.toLowerCase(), '_lower');
  }

  /// Returns a new Series with all strings converted to uppercase.
  ///
  /// For elements that are not strings or are missing,
  /// the result will be the Series' missing value representation.
  /// Example: `series.str.upper()`
  Series upper() {
    return _applyStringOperation((s) => s.toUpperCase(), '_upper');
  }

  /// Returns a new Series with leading/trailing whitespace removed from each string.
  ///
  /// For elements that are not strings or are missing,
  /// the result will be the Series' missing value representation.
  /// Example: `series.str.strip()`
  Series strip() {
    return _applyStringOperation((s) => s.trim(), '_strip');
  }

  /// Returns a new Series of bools indicating if each string starts with the given `pattern`.
  ///
  /// For elements that are not strings or are missing,
  /// the result will be the Series' missing value representation.
  /// Example: `series.str.startswith('A')`
  Series startswith(String pattern) {
    return _applyStringBoolOperation(
        (s) => s.startsWith(pattern), '_startswith_$pattern');
  }

  /// Returns a new Series of bools indicating if each string ends with the given `pattern`.
  ///
  /// For elements that are not strings or are missing,
  /// the result will be the Series' missing value representation.
  /// Example: `series.str.endswith('.com')`
  Series endswith(String pattern) {
    return _applyStringBoolOperation(
        (s) => s.endsWith(pattern), '_endswith_$pattern');
  }

  /// Returns a new Series of bools indicating if each string contains the given `pattern`.
  ///
  /// For elements that are not strings or are missing,
  /// the result will be the Series' missing value representation.
  /// Example: `series.str.contains('substring')`
  Series contains(String pattern) {
    return _applyStringBoolOperation(
        (s) => s.contains(pattern), '_contains_$pattern');
  }

  /// Returns a new Series where occurrences of `from` (String or RegExp) in each string are replaced with `to`.
  ///
  /// For elements that are not strings or are missing,
  /// the result will be the Series' missing value representation.
  /// Example: `series.str.replace('old', 'new')`
  Series replace(Pattern from, String to) {
    String fromPatternString = from is RegExp ? from.pattern : from.toString();
    // Sanitize fromPatternString for name to avoid issues with special characters if any
    String sanitizedFromName =
        fromPatternString.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    return _applyStringOperation((s) => s.replaceAll(from, to),
        '_replace_${sanitizedFromName}_with_$to');
  }

  /// Returns a new Series where each string is split by the given pattern.
  ///
  /// For elements that are not strings or are missing,
  /// the result will be the Series' missing value representation.
  ///
  /// Parameters:
  /// - pattern: The pattern to split on (String or RegExp)
  /// - n: Maximum number of splits to perform (optional)
  ///
  /// Example: `series.str.split('-')`
  Series split(Pattern pattern, {int? n}) {
    String patternString =
        pattern is RegExp ? pattern.pattern : pattern.toString();
    String sanitizedPatternName =
        patternString.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    return _applyStringOperation((s) {
      if (n != null) {
        return s.split(pattern).take(n + 1).toList();
      } else {
        return s.split(pattern);
      }
    }, '_split_$sanitizedPatternName');
  }

  /// Returns a new Series with the first match of the given regex pattern.
  ///
  /// For elements that are not strings or are missing,
  /// the result will be the Series' missing value representation.
  /// If no match is found, returns the missing value representation.
  /// If the regex has capture groups, returns the first group; otherwise returns the full match.
  ///
  /// Parameters:
  /// - pattern: The regex pattern to match (String or RegExp)
  ///
  /// Example: `series.str.match(r'\\d+')`
  Series match(Pattern pattern) {
    RegExp regex = pattern is RegExp ? pattern : RegExp(pattern.toString());
    String patternString = regex.pattern;
    String sanitizedPatternName =
        patternString.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    return _applyStringOperation((s) {
      final match = regex.firstMatch(s);
      if (match == null) {
        throw Exception(
            'No match found'); // This will be caught and return missing rep
      }

      // If there are capture groups, return the first group
      if (match.groupCount > 0) {
        return match.group(1) ?? match.group(0)!;
      }

      // Otherwise return the full match
      return match.group(0)!;
    }, '_match_$sanitizedPatternName');
  }
}
