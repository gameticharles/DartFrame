import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Series.str Accessor', () {
    // Base Series with string data and a null for general testing
    var sBase = Series([' Hello', 'World ', ' DartFrame ', null, '  '], name: 'strings', index: ['a', 'b', 'c', 'd', 'e']);
    final defaultMissingRep = null; // Assuming default missing for s_base

    // Series linked to a DataFrame with a specific missing value placeholder
    var dfSpecificMissing = DataFrame.empty(replaceMissingValueWith: 'MISSING_VAL');
    var sMixedType = Series([' One ', 'MISSING_VAL', 'Three', 42, null], name: 'mixed', index: ['x', 'y', 'z', 'w', 'v']);
    sMixedType.setParent(dfSpecificMissing, 'mixed');
    final specificMissingRep = 'MISSING_VAL';

    group('str.len()', () {
      test('on string series', () {
        var result = sBase.str.len();
        expect(result.data, equals([6, 6, 11, defaultMissingRep, 2]));
        expect(result.index, equals(sBase.index));
        expect(result.name, equals('strings_len'));
      });

      test('on mixed type series with specific missing', () {
        var result = sMixedType.str.len();
        // ' One ' -> 5
        // 'MISSING_VAL' (is missing) -> specificMissingRep
        // 'Three' -> 5
        // 42 (not string) -> specificMissingRep
        // null (original null, becomes specificMissingRep) -> specificMissingRep
        expect(result.data, equals([5, specificMissingRep, 5, specificMissingRep, specificMissingRep]));
        expect(result.index, equals(sMixedType.index));
        expect(result.name, equals('mixed_len'));
      });
    });

    group('str.lower()', () {
      test('on string series', () {
        var result = sBase.str.lower();
        expect(result.data, equals([' hello', 'world ', ' dartframe ', defaultMissingRep, '  ']));
        expect(result.name, equals('strings_lower'));
      });

      test('on mixed type series', () {
        var result = sMixedType.str.lower();
        expect(result.data, equals([' one ', specificMissingRep, 'three', specificMissingRep, specificMissingRep]));
        expect(result.name, equals('mixed_lower'));
      });
    });

    group('str.upper()', () {
      test('on string series', () {
        var result = sBase.str.upper();
        expect(result.data, equals([' HELLO', 'WORLD ', ' DARTFRAME ', defaultMissingRep, '  ']));
      });

      test('on mixed type series', () {
        var result = sMixedType.str.upper();
        expect(result.data, equals([' ONE ', specificMissingRep, 'THREE', specificMissingRep, specificMissingRep]));
      });
    });

    group('str.strip()', () {
      test('on string series', () {
        var result = sBase.str.strip();
        expect(result.data, equals(['Hello', 'World', 'DartFrame', defaultMissingRep, '']));
      });
      test('on mixed type series', () {
        var result = sMixedType.str.strip();
        expect(result.data, equals(['One', specificMissingRep, 'Three', specificMissingRep, specificMissingRep]));
      });
    });

    group('str.startswith()', () {
      test('on string series', () {
        var result = sBase.str.startswith(' H');
        expect(result.data, equals([true, false, false, defaultMissingRep, false]));
        expect(result.name, equals('strings_startswith_ H'));
      });
      test('on mixed type series', () {
        var result = sMixedType.str.startswith(' O');
        expect(result.data, equals([true, specificMissingRep, false, specificMissingRep, specificMissingRep]));
      });
    });

    group('str.endswith()', () {
      test('on string series', () {
        var result = sBase.str.endswith(' ');
        expect(result.data, equals([false, true, true, defaultMissingRep, true]));
      });
       test('on mixed type series', () {
        var result = sMixedType.str.endswith('e');
        expect(result.data, equals([false, specificMissingRep, true, specificMissingRep, specificMissingRep]));
      });
    });

    group('str.contains()', () {
      test('on string series', () {
        var result = sBase.str.contains('World');
        expect(result.data, equals([false, true, false, defaultMissingRep, false]));
      });
       test('on mixed type series', () {
        var result = sMixedType.str.contains('ne');
        expect(result.data, equals([true, specificMissingRep, false, specificMissingRep, specificMissingRep]));
      });
    });
    
    group('str.replace()', () {
      test('on string series with String pattern', () {
        var result = sBase.str.replace(' ', '_'); // Replace first occurrence
        expect(result.data, equals(['_Hello', 'World_', '_DartFrame_', defaultMissingRep, '__']));
        expect(result.name, contains('strings_replace_')); // Name can be complex due to pattern
      });

      test('on string series with RegExp pattern', () {
        var result = sBase.str.replace(RegExp(r'\s+'), '_'); // Replace all whitespace blocks
        expect(result.data, equals(['_Hello', 'World_', '_DartFrame_', defaultMissingRep, '_']));
      });
      
      test('on mixed type series', () {
        var result = sMixedType.str.replace('One', 'Two');
        expect(result.data, equals([' Two ', specificMissingRep, 'Three', specificMissingRep, specificMissingRep]));
      });

      test('replace with non-string in mixed series', () {
        var s = Series(['apple', 123, 'banana'], name: 'mix');
        var result = s.str.replace('a','@');
        expect(result.data, equals(['@pple', null, 'b@n@n@']));
      });
    });
  });
}
