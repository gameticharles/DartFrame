part of 'series.dart';

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
      if (n != null && n >= 0) {
        List<String> parts = s.split(pattern);
        if (parts.length > n) {
          List<String> result = parts.sublist(0, n);
          result.add(parts
              .sublist(n)
              .join(pattern is RegExp ? pattern.pattern : pattern.toString()));
          return result;
        } else {
          return parts;
        }
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
    // Allow alphanumeric, underscore, and backslash for regex patterns
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

  /// Extract capture groups from regex pattern.
  ///
  /// Returns a DataFrame with columns for each capture group.
  /// If no groups are captured, returns a Series with the full match.
  ///
  /// Parameters:
  /// - `pattern`: Regex pattern with capture groups
  /// - `flags`: Optional regex flags (case-insensitive, multiline, etc.)
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['a1', 'b2', 'c3'], name: 'data');
  /// var extracted = s.str.extract(r'([a-z])(\d)');
  /// // Returns DataFrame with columns [0, 1] containing ['a', '1'], ['b', '2'], ['c', '3']
  /// ```
  dynamic extract(String pattern,
      {bool caseSensitive = true, bool multiLine = false}) {
    final regex =
        RegExp(pattern, caseSensitive: caseSensitive, multiLine: multiLine);
    final missingRep = _series._missingRepresentation;

    // Count capture groups by testing on a sample match
    int groupCount = 0;
    for (var value in _series.data) {
      if (value is String) {
        final match = regex.firstMatch(value);
        if (match != null) {
          groupCount = match.groupCount;
          break;
        }
      }
    }

    if (groupCount == 0) {
      // No capture groups, return Series with full match
      return _applyStringOperation((s) {
        final match = regex.firstMatch(s);
        if (match == null) throw Exception('No match');
        return match.group(0)!;
      }, '_extract');
    }

    // Multiple capture groups, return DataFrame
    final List<List<dynamic>> rows = [];
    final columns = List.generate(groupCount, (i) => i);

    for (var value in _series.data) {
      if (_series._isMissing(value)) {
        rows.add(List.filled(groupCount, missingRep));
      } else if (value is String) {
        final match = regex.firstMatch(value);
        if (match == null) {
          rows.add(List.filled(groupCount, missingRep));
        } else {
          final row = <dynamic>[];
          for (int i = 1; i <= groupCount; i++) {
            row.add(match.group(i) ?? missingRep);
          }
          rows.add(row);
        }
      } else {
        rows.add(List.filled(groupCount, missingRep));
      }
    }

    return DataFrame(rows, columns: columns, index: _series.index);
  }

  /// Extract all matches of pattern.
  ///
  /// Returns a Series where each element is a list of all matches.
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['a1b2', 'c3d4'], name: 'data');
  /// var all = s.str.extractall(r'\d');
  /// // Returns Series with [['1', '2'], ['3', '4']]
  /// ```
  Series extractall(String pattern, {bool caseSensitive = true}) {
    final regex = RegExp(pattern, caseSensitive: caseSensitive);
    return _applyStringOperation((s) {
      final matches = regex.allMatches(s);
      if (matches.isEmpty) throw Exception('No matches');
      return matches.map((m) => m.group(0)!).toList();
    }, '_extractall');
  }

  /// Find all occurrences of pattern.
  ///
  /// Returns a Series where each element is a list of all matches.
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['hello world', 'hi there'], name: 'text');
  /// var words = s.str.findall(r'\w+');
  /// // Returns Series with [['hello', 'world'], ['hi', 'there']]
  /// ```
  Series findall(String pattern, {bool caseSensitive = true}) {
    final regex = RegExp(pattern, caseSensitive: caseSensitive);
    return _applyStringOperation((s) {
      final matches = regex.allMatches(s);
      return matches.map((m) => m.group(0)!).toList();
    }, '_findall');
  }

  /// Pad strings to specified width.
  ///
  /// Parameters:
  /// - `width`: Minimum width of resulting string
  /// - `side`: 'left', 'right', or 'both' (default: 'left')
  /// - `fillchar`: Character to use for padding (default: ' ')
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['a', 'bb', 'ccc'], name: 'text');
  /// var padded = s.str.pad(5);
  /// // Returns ['    a', '   bb', '  ccc']
  /// ```
  Series pad(int width, {String side = 'left', String fillchar = ' '}) {
    if (fillchar.length != 1) {
      throw ArgumentError('fillchar must be a single character');
    }

    return _applyStringOperation((s) {
      if (s.length >= width) return s;
      final padding = fillchar * (width - s.length);

      switch (side) {
        case 'left':
          return padding + s;
        case 'right':
          return s + padding;
        case 'both':
          final leftPad = padding.length ~/ 2;
          final rightPad = padding.length - leftPad;
          return (fillchar * leftPad) + s + (fillchar * rightPad);
        default:
          throw ArgumentError('side must be "left", "right", or "both"');
      }
    }, '_pad');
  }

  /// Center strings in field of given width.
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['a', 'bb'], name: 'text');
  /// var centered = s.str.center(5);
  /// // Returns ['  a  ', ' bb  ']
  /// ```
  Series center(int width, {String fillchar = ' '}) {
    return pad(width, side: 'both', fillchar: fillchar);
  }

  /// Left-justify strings in field of given width.
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['a', 'bb'], name: 'text');
  /// var left = s.str.ljust(5);
  /// // Returns ['a    ', 'bb   ']
  /// ```
  Series ljust(int width, {String fillchar = ' '}) {
    return pad(width, side: 'right', fillchar: fillchar);
  }

  /// Right-justify strings in field of given width.
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['a', 'bb'], name: 'text');
  /// var right = s.str.rjust(5);
  /// // Returns ['    a', '   bb']
  /// ```
  Series rjust(int width, {String fillchar = ' '}) {
    return pad(width, side: 'left', fillchar: fillchar);
  }

  /// Pad strings with zeros on the left.
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['1', '22', '333'], name: 'numbers');
  /// var padded = s.str.zfill(5);
  /// // Returns ['00001', '00022', '00333']
  /// ```
  Series zfill(int width) {
    return _applyStringOperation((s) {
      if (s.length >= width) return s;

      // Handle negative numbers
      if (s.startsWith('-') || s.startsWith('+')) {
        final sign = s[0];
        final rest = s.substring(1);
        final padding = '0' * (width - s.length);
        return sign + padding + rest;
      }

      final padding = '0' * (width - s.length);
      return padding + s;
    }, '_zfill');
  }

  /// Slice substrings from each element.
  ///
  /// Parameters:
  /// - `start`: Start position (inclusive)
  /// - `stop`: End position (exclusive), null for end of string
  /// - `step`: Step size (default: 1)
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['abcdef', '123456'], name: 'text');
  /// var sliced = s.str.slice(1, 4);
  /// // Returns ['bcd', '234']
  /// ```
  Series slice(int? start, int? stop, {int step = 1}) {
    return _applyStringOperation((s) {
      final length = s.length;
      final actualStart = start ?? 0;
      final actualStop = stop ?? length;

      if (step == 1) {
        return s.substring(actualStart < 0 ? length + actualStart : actualStart,
            actualStop < 0 ? length + actualStop : actualStop.clamp(0, length));
      }

      // Handle step != 1
      final result = StringBuffer();
      for (int i = actualStart; i < actualStop && i < length; i += step) {
        if (i >= 0) result.write(s[i]);
      }
      return result.toString();
    }, '_slice');
  }

  /// Replace slice with value.
  ///
  /// Parameters:
  /// - `start`: Start position
  /// - `stop`: End position
  /// - `repl`: Replacement string
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['abcdef'], name: 'text');
  /// var replaced = s.str.sliceReplace(1, 4, 'XYZ');
  /// // Returns ['aXYZef']
  /// ```
  Series sliceReplace(int? start, int? stop, String repl) {
    return _applyStringOperation((s) {
      final length = s.length;
      final actualStart = (start ?? 0).clamp(0, length);
      final actualStop = (stop ?? length).clamp(0, length);

      return s.substring(0, actualStart) + repl + s.substring(actualStop);
    }, '_slice_replace');
  }

  /// Concatenate strings in the Series.
  ///
  /// Parameters:
  /// - `others`: Other Series or strings to concatenate
  /// - `sep`: Separator to use (default: '')
  /// - `na_rep`: String to use for missing values
  ///
  /// Example:
  /// ```dart
  /// var s1 = Series(['a', 'b'], name: 'first');
  /// var s2 = Series(['1', '2'], name: 'second');
  /// var concat = s1.str.cat(s2, sep: '-');
  /// // Returns ['a-1', 'b-2']
  /// ```
  Series cat(dynamic others, {String sep = '', String? naRep}) {
    if (others == null) {
      // Concatenate all strings in the series
      final validStrings = <String>[];

      for (var value in _series.data) {
        if (!_series._isMissing(value) && value is String) {
          validStrings.add(value);
        } else if (naRep != null) {
          validStrings.add(naRep);
        }
      }

      return Series([validStrings.join(sep)], name: '${_series.name}_cat');
    }

    if (others is Series) {
      if (others.length != _series.length) {
        throw ArgumentError('Series must have same length');
      }

      final result = <dynamic>[];
      for (int i = 0; i < _series.length; i++) {
        final val1 = _series.data[i];
        final val2 = others.data[i];

        if (_series._isMissing(val1) || _series._isMissing(val2)) {
          if (naRep != null) {
            final str1 = _series._isMissing(val1) ? naRep : val1.toString();
            final str2 = _series._isMissing(val2) ? naRep : val2.toString();
            result.add(str1 + sep + str2);
          } else {
            result.add(_series._missingRepresentation);
          }
        } else {
          result.add(val1.toString() + sep + val2.toString());
        }
      }

      return Series(result, name: '${_series.name}_cat', index: _series.index);
    }

    if (others is String) {
      return _applyStringOperation((s) => s + sep + others, '_cat');
    }

    throw ArgumentError('others must be Series, String, or null');
  }

  /// Repeat strings.
  ///
  /// Parameters:
  /// - `repeats`: Number of repetitions (can be int or Series of ints)
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['a', 'b'], name: 'text');
  /// var repeated = s.str.repeat(3);
  /// // Returns ['aaa', 'bbb']
  /// ```
  Series repeat(dynamic repeats) {
    if (repeats is int) {
      return _applyStringOperation((s) => s * repeats, '_repeat');
    }

    if (repeats is Series) {
      if (repeats.length != _series.length) {
        throw ArgumentError('repeats Series must have same length');
      }

      final result = <dynamic>[];
      final missingRep = _series._missingRepresentation;

      for (int i = 0; i < _series.length; i++) {
        final val = _series.data[i];
        final rep = repeats.data[i];

        if (_series._isMissing(val) || rep == null || rep is! int) {
          result.add(missingRep);
        } else if (val is String) {
          result.add(val * rep);
        } else {
          result.add(missingRep);
        }
      }

      return Series(result,
          name: '${_series.name}_repeat', index: _series.index);
    }

    throw ArgumentError('repeats must be int or Series');
  }

  /// Check if strings are alphanumeric.
  ///
  /// Example:
  /// ```dart
  /// var s = Series(['abc123', 'abc', '123', 'ab-c'], name: 'text');
  /// var check = s.str.isalnum();
  /// // Returns [true, true, true, false]
  /// ```
  Series isalnum() {
    return _applyStringBoolOperation(
        (s) => s.isNotEmpty && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(s),
        '_isalnum');
  }

  /// Check if strings are alphabetic.
  Series isalpha() {
    return _applyStringBoolOperation(
        (s) => s.isNotEmpty && RegExp(r'^[a-zA-Z]+$').hasMatch(s), '_isalpha');
  }

  /// Check if strings are digits.
  Series isdigit() {
    return _applyStringBoolOperation(
        (s) => s.isNotEmpty && RegExp(r'^\d+$').hasMatch(s), '_isdigit');
  }

  /// Check if strings are whitespace.
  Series isspace() {
    return _applyStringBoolOperation(
        (s) => s.isNotEmpty && RegExp(r'^\s+$').hasMatch(s), '_isspace');
  }

  /// Check if strings are lowercase.
  Series islower() {
    return _applyStringBoolOperation(
        (s) => s.isNotEmpty && s == s.toLowerCase() && s != s.toUpperCase(),
        '_islower');
  }

  /// Check if strings are uppercase.
  Series isupper() {
    return _applyStringBoolOperation(
        (s) => s.isNotEmpty && s == s.toUpperCase() && s != s.toLowerCase(),
        '_isupper');
  }

  /// Check if strings are titlecase.
  Series istitle() {
    return _applyStringBoolOperation((s) {
      if (s.isEmpty) return false;
      final words = s.split(RegExp(r'\s+'));
      for (var word in words) {
        if (word.isEmpty) continue;
        if (word[0] != word[0].toUpperCase()) return false;
        if (word.length > 1 &&
            word.substring(1) != word.substring(1).toLowerCase()) {
          return false;
        }
      }
      return true;
    }, '_istitle');
  }

  /// Check if strings are numeric.
  Series isnumeric() {
    return _applyStringBoolOperation(
        (s) => s.isNotEmpty && double.tryParse(s) != null, '_isnumeric');
  }

  /// Check if strings are decimal.
  Series isdecimal() {
    return _applyStringBoolOperation(
        (s) => s.isNotEmpty && RegExp(r'^\d+$').hasMatch(s), '_isdecimal');
  }

  /// Get element from each list in the Series.
  ///
  /// Assumes each element is a list and extracts the item at the given index.
  ///
  /// Parameters:
  /// - `i`: Index to extract from each list
  ///
  /// Example:
  /// ```dart
  /// var s = Series([['a', 'b'], ['c', 'd']], name: 'lists');
  /// var first = s.str.get(0);
  /// // Returns ['a', 'c']
  /// ```
  Series get(int i) {
    final missingRep = _series._missingRepresentation;
    final result = <dynamic>[];

    for (var value in _series.data) {
      if (_series._isMissing(value)) {
        result.add(missingRep);
      } else if (value is List) {
        if (i < 0 || i >= value.length) {
          result.add(missingRep);
        } else {
          result.add(value[i]);
        }
      } else {
        result.add(missingRep);
      }
    }

    return Series(result, name: '${_series.name}_get', index: _series.index);
  }
}
