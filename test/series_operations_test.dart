// ignore_for_file: unused_local_variable

import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  // Helper to get the missing value representation for standalone series for testing
  // For these tests, we'll assume 'null' is the missing rep if not tied to a DF
  // or if the DF's replaceMissingValueWith is null.
  //dynamic getMissingRep(Series s) => s.hashCode; // Placeholder, will be replaced by actual logic

  group('Series Arithmetic & Bitwise Operations with Index Alignment', () {
    // Series for testing
    var s1 = Series([1, 2, 3, 4], name: 's1', index: ['a', 'b', 'c', 'd']);
    var s2 = Series([10, 20, 30, 40], name: 's2', index: ['a', 'b', 'c', 'd']);
    
    // Identical default index
    var sDef1 = Series([1, 2, 3], name: 's_def_1'); // index [0,1,2]
    var sDef2 = Series([4, 5, 6], name: 's_def_2'); // index [0,1,2]

    // Different, overlapping indexes
    var s3 = Series([1, 2, 300], name: 's3', index: ['a', 'b', 'e']); // Overlaps 'a', 'b' with s1/s2
    var s4 = Series([10, 400, 50], name: 's4', index: ['b', 'f', 'g']); // Overlaps 'b' with s1/s2/s3

    // Completely different indexes
    var s5 = Series([100, 200], name: 's5', index: ['x', 'y']);

    // Series with missing values (null as placeholder)
    var sMiss1 = Series([1, null, 3, null], name: 's_miss_1', index: ['a', 'b', 'c', 'd']);
    var sMiss2 = Series([null, 10, null, 20], name: 's_miss_2', index: ['a', 'b', 'c', 'd']);
    
    // Series linked to a DataFrame with a specific missing value placeholder
    var dfSpecificMissing = DataFrame.empty(replaceMissingValueWith: -999);
    var sSpecMiss1 = Series([-999, 1, 2, -999], name: 's_spec_miss_1', index: ['a', 'b', 'c', 'd']);
    sSpecMiss1.setParent(dfSpecificMissing, 's_spec_miss_1');
    var sSpecMiss2 = Series([10, -999, -999, 30], name: 's_spec_miss_2', index: ['a', 'b', 'c', 'd']);
    sSpecMiss2.setParent(dfSpecificMissing, 's_spec_miss_2');
    
    final defaultMissingRep = null; // For standalone series or df with replaceMissingValueWith = null
    final specificMissingRep = -999;


    group('Operator +', () {
      test('identical indexes', () {
        var result = s1 + s2;
        expect(result.data, equals([11, 22, 33, 44]));
        expect(result.index, equals(['a', 'b', 'c', 'd']));
        expect(result.name, equals('(s1 + s2)'));
      });
      
      test('identical default indexes', () {
        var result = sDef1 + sDef2;
        expect(result.data, equals([5, 7, 9]));
        expect(result.index, equals([0, 1, 2]));
         expect(result.name, equals('(s_def_1 + s_def_2)'));
      });

      test('different, overlapping indexes', () {
        // s1: [1,2,3,4] index: [a,b,c,d]
        // s3: [1,2,300] index: [a,b,e]
        // union index: [a,b,c,d,e]
        var result = s1 + s3;
        expect(result.index, equals(['a', 'b', 'c', 'd', 'e']));
        expect(result.data, equals([1+1, 2+2, defaultMissingRep, defaultMissingRep, defaultMissingRep]));
        expect(result.name, equals('(s1 + s3)'));
      });

      test('completely different indexes', () {
        // s1: [1,2,3,4] index: [a,b,c,d]
        // s5: [100,200] index: [x,y]
        // union index: [a,b,c,d,x,y]
        var result = s1 + s5;
        expect(result.index, equals(['a', 'b', 'c', 'd', 'x', 'y']));
        expect(result.data, equals([defaultMissingRep, defaultMissingRep, defaultMissingRep, defaultMissingRep, defaultMissingRep, defaultMissingRep]));
      });

      test('with missing values (null)', () {
        // s_miss_1: [1, null, 3, null] index: [a,b,c,d]
        // s1:       [1,    2, 3,   4] index: [a,b,c,d]
        var result = sMiss1 + s1;
        expect(result.data, equals([2, defaultMissingRep, 6, defaultMissingRep]));
        expect(result.index, equals(['a', 'b', 'c', 'd']));
      });
      
      test('with specific missing values', () {
        // s_spec_miss_1: [-999,    1,   2, -999]
        // s_spec_miss_2: [  10, -999, -999,  30]
        var result = sSpecMiss1 + sSpecMiss2; // Both belong to df_specific_missing
        expect(result.data, equals([specificMissingRep, specificMissingRep, specificMissingRep, specificMissingRep]));
        expect(result.index, equals(['a', 'b', 'c', 'd']));
      });
    });

    group('Operator -', () {
      test('identical indexes', () {
        var result = s1 - s2;
        expect(result.data, equals([-9, -18, -27, -36]));
        expect(result.index, equals(['a', 'b', 'c', 'd']));
        expect(result.name, equals('(s1 - s2)'));
      });

      test('different, overlapping indexes', () {
        // s1: [1,2,3,4] index: [a,b,c,d]
        // s3: [1,2,300] index: [a,b,e]
        var result = s1 - s3;
        expect(result.index, equals(['a', 'b', 'c', 'd', 'e']));
        expect(result.data, equals([1-1, 2-2, defaultMissingRep, defaultMissingRep, defaultMissingRep]));
      });
       test('with missing values (null)', () {
        var result = sMiss1 - s1; // s_miss_1: [1, null, 3, null]
        expect(result.data, equals([0, defaultMissingRep, 0, defaultMissingRep]));
      });
    });
    
    group('Operator *', () {
      test('identical indexes', () {
        var result = s1 * s2;
        expect(result.data, equals([10, 40, 90, 160]));
        expect(result.index, equals(['a', 'b', 'c', 'd']));
        expect(result.name, equals('(s1 * s2)'));
      });

      test('different, overlapping indexes', () {
        // s1: [1,2,3,4] index: [a,b,c,d]
        // s3: [1,2,300] index: [a,b,e]
        var result = s1 * s3;
        expect(result.index, equals(['a', 'b', 'c', 'd', 'e']));
        expect(result.data, equals([1*1, 2*2, defaultMissingRep, defaultMissingRep, defaultMissingRep]));
      });
      test('with specific missing values', () {
        // s_spec_miss_1: [-999, 1, 2, -999]
        // s_spec_miss_2: [10, -999, -999, 30]
        var sB = Series([10, 2, 3, 30], name: 's_b', index: ['a','b','c','d']);
        sB.setParent(dfSpecificMissing, 's_b');

        var result1 = sSpecMiss1 * sB; 
        // s_spec_miss_1[a] is missing (-999) -> result[a] = -999
        // s_spec_miss_1[b] is 1, s_b[b] is 2 -> result[b] = 2
        // s_spec_miss_1[c] is 2, s_b[c] is 3 -> result[c] = 6
        // s_spec_miss_1[d] is missing (-999) -> result[d] = -999
        expect(result1.data, equals([specificMissingRep, 1*2, 2*3, specificMissingRep]));
      });
    });

    group('Operator /', () {
      test('identical indexes', () {
        var result = Series([10, 20, 30], name: 'num') / Series([2, 5, 0], name: 'den');
        expect(result.data, equals([5.0, 4.0, defaultMissingRep])); // Division by zero
        expect(result.index, equals([0,1,2]));
        expect(result.name, equals('(num / den)'));
      });

      test('different indexes with division by zero', () {
        var sNum = Series([10,20,5], name: 's_num', index: ['a','b','c']);
        var sDen = Series([2,0,2], name: 's_den', index: ['b','c','d']);
        // union index: [a,b,c,d]
        // a: num=miss, den=miss -> miss
        // b: num=20, den=2 -> 10
        // c: num=5, den=0 -> miss (div by zero)
        // d: num=miss, den=miss -> miss
        var result = sNum / sDen;
        expect(result.index, equals(['a','b','c','d']));
        expect(result.data, equals([defaultMissingRep, 20/2, defaultMissingRep, defaultMissingRep]));
      });
    });

    group('Operator ~/', () {
      test('identical indexes', () {
        var result = Series([10, 21, 30], name: 'num') ~/ Series([3, 5, 0], name: 'den');
        expect(result.data, equals([3, 4, defaultMissingRep])); // Division by zero
        expect(result.index, equals([0,1,2]));
      });
    });
    
    group('Operator %', () {
      test('identical indexes', () {
        var result = Series([10, 21, 30], name: 'num') % Series([3, 5, 0], name: 'den');
        expect(result.data, equals([1, 1, defaultMissingRep])); // Modulo by zero
      });
    });

    // Bitwise operators
    // For simplicity, assuming integer inputs for bitwise ops where they make most sense
    var sBit1 = Series([1, 2, 3], name: 's_bit1', index: ['a', 'b', 'c']); // 01, 10, 11
    var sBit2 = Series([3, 1, 0], name: 's_bit2', index: ['a', 'b', 'c']); // 11, 01, 00
    var sBit3Overlap = Series([2], name: 's_bit3', index: ['c']); // 10 at 'c'

    group('Operator ^ (XOR)', () {
      test('identical indexes', () {
        var result = sBit1 ^ sBit2;
        expect(result.data, equals([1^3, 2^1, 3^0])); // [2,3,3]
      });
      test('different indexes', () {
        // s_bit1 : [1,2,3] @ [a,b,c]
        // s_bit3_overlap: [2] @ [c]
        // union: [a,b,c]
        // a: s_bit1[a] ^ miss -> miss
        // b: s_bit1[b] ^ miss -> miss
        // c: s_bit1[c] ^ s_bit3_overlap[c] = 3 ^ 2 = 1
        var result = sBit1 ^ sBit3Overlap;
        expect(result.data, equals([defaultMissingRep, defaultMissingRep, 3^2]));
        expect(result.index, equals(['a','b','c']));
      });
    });
    
    group('Operator & (AND)', () {
      test('identical indexes', () {
        var result = sBit1 & sBit2;
        expect(result.data, equals([1&3, 2&1, 3&0])); // [1,0,0]
      });
    });

    group('Operator | (OR)', () {
      test('identical indexes', () {
        var result = sBit1 | sBit2;
        expect(result.data, equals([1|3, 2|1, 3|0])); // [3,3,3]
      });
    });
  });
}
