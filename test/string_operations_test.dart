import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('String Operations Tests', () {
    group('str.extract()', () {
      test('extracts single capture group', () {
        final s = Series(['a1', 'b2', 'c3'], name: 'data');
        final result = s.str.extract(r'([a-z])');
        expect(result, isA<DataFrame>());
        final df = result as DataFrame;
        expect(df.rowCount, 3);
      });

      test('extracts multiple capture groups', () {
        final s = Series(['a1', 'b2', 'c3'], name: 'data');
        final result = s.str.extract(r'([a-z])(\d)');
        expect(result, isA<DataFrame>());
        final df = result as DataFrame;
        expect(df.rowCount, 3);
        expect(df.columnCount, 2);
      });
    });

    group('str.extractall()', () {
      test('extracts all matches', () {
        final s = Series(['a1b2', 'c3d4'], name: 'data');
        final result = s.str.extractall(r'\d');
        expect(result.data[0], ['1', '2']);
        expect(result.data[1], ['3', '4']);
      });
    });

    group('str.findall()', () {
      test('finds all occurrences', () {
        final s = Series(['hello world', 'hi there'], name: 'text');
        final result = s.str.findall(r'\w+');
        expect(result.data[0], ['hello', 'world']);
        expect(result.data[1], ['hi', 'there']);
      });
    });

    group('str.pad()', () {
      test('pads left by default', () {
        final s = Series(['a', 'bb'], name: 'text');
        final result = s.str.pad(5);
        expect(result.data, ['    a', '   bb']);
      });

      test('pads right', () {
        final s = Series(['a', 'bb'], name: 'text');
        final result = s.str.pad(5, side: 'right');
        expect(result.data, ['a    ', 'bb   ']);
      });

      test('pads both sides', () {
        final s = Series(['a'], name: 'text');
        final result = s.str.pad(5, side: 'both');
        expect(result.data[0].length, 5);
      });
    });

    group('str.center()', () {
      test('centers strings', () {
        final s = Series(['a', 'bb'], name: 'text');
        final result = s.str.center(5);
        expect(result.data[0].length, 5);
        expect(result.data[1].length, 5);
      });
    });

    group('str.ljust()', () {
      test('left-justifies strings', () {
        final s = Series(['a', 'bb'], name: 'text');
        final result = s.str.ljust(5);
        expect(result.data, ['a    ', 'bb   ']);
      });
    });

    group('str.rjust()', () {
      test('right-justifies strings', () {
        final s = Series(['a', 'bb'], name: 'text');
        final result = s.str.rjust(5);
        expect(result.data, ['    a', '   bb']);
      });
    });

    group('str.zfill()', () {
      test('pads with zeros', () {
        final s = Series(['1', '22', '333'], name: 'numbers');
        final result = s.str.zfill(5);
        expect(result.data, ['00001', '00022', '00333']);
      });

      test('handles negative numbers', () {
        final s = Series(['-1', '+22'], name: 'numbers');
        final result = s.str.zfill(5);
        expect(result.data, ['-0001', '+0022']);
      });
    });

    group('str.slice()', () {
      test('slices substrings', () {
        final s = Series(['abcdef', '123456'], name: 'text');
        final result = s.str.slice(1, 4);
        expect(result.data, ['bcd', '234']);
      });

      test('handles null stop', () {
        final s = Series(['abcdef'], name: 'text');
        final result = s.str.slice(2, null);
        expect(result.data, ['cdef']);
      });
    });

    group('str.sliceReplace()', () {
      test('replaces slice with value', () {
        final s = Series(['abcdef'], name: 'text');
        final result = s.str.sliceReplace(1, 4, 'XYZ');
        expect(result.data, ['aXYZef']);
      });
    });

    group('str.cat()', () {
      test('concatenates with another Series', () {
        final s1 = Series(['a', 'b'], name: 'first');
        final s2 = Series(['1', '2'], name: 'second');
        final result = s1.str.cat(s2, sep: '-');
        expect(result.data, ['a-1', 'b-2']);
      });

      test('concatenates with string', () {
        final s = Series(['a', 'b'], name: 'text');
        final result = s.str.cat('X', sep: '-');
        expect(result.data, ['a-X', 'b-X']);
      });
    });

    group('str.repeat()', () {
      test('repeats strings', () {
        final s = Series(['a', 'b'], name: 'text');
        final result = s.str.repeat(3);
        expect(result.data, ['aaa', 'bbb']);
      });

      test('repeats with Series', () {
        final s = Series(['a', 'b'], name: 'text');
        final repeats = Series([2, 3], name: 'reps');
        final result = s.str.repeat(repeats);
        expect(result.data, ['aa', 'bbb']);
      });
    });

    group('str.isalnum()', () {
      test('checks alphanumeric', () {
        final s = Series(['abc123', 'abc', '123', 'ab-c'], name: 'text');
        final result = s.str.isalnum();
        expect(result.data, [true, true, true, false]);
      });
    });

    group('str.isalpha()', () {
      test('checks alphabetic', () {
        final s = Series(['abc', 'abc123', '123'], name: 'text');
        final result = s.str.isalpha();
        expect(result.data, [true, false, false]);
      });
    });

    group('str.isdigit()', () {
      test('checks digits', () {
        final s = Series(['123', 'abc', '12a'], name: 'text');
        final result = s.str.isdigit();
        expect(result.data, [true, false, false]);
      });
    });

    group('str.isspace()', () {
      test('checks whitespace', () {
        final s = Series(['   ', 'a b', 'abc'], name: 'text');
        final result = s.str.isspace();
        expect(result.data, [true, false, false]);
      });
    });

    group('str.islower()', () {
      test('checks lowercase', () {
        final s = Series(['abc', 'ABC', 'Abc'], name: 'text');
        final result = s.str.islower();
        expect(result.data, [true, false, false]);
      });
    });

    group('str.isupper()', () {
      test('checks uppercase', () {
        final s = Series(['ABC', 'abc', 'Abc'], name: 'text');
        final result = s.str.isupper();
        expect(result.data, [true, false, false]);
      });
    });

    group('str.istitle()', () {
      test('checks titlecase', () {
        final s =
            Series(['Hello World', 'hello world', 'HELLO WORLD'], name: 'text');
        final result = s.str.istitle();
        expect(result.data, [true, false, false]);
      });
    });

    group('str.isnumeric()', () {
      test('checks numeric', () {
        final s = Series(['123', '12.5', 'abc'], name: 'text');
        final result = s.str.isnumeric();
        expect(result.data, [true, true, false]);
      });
    });

    group('str.isdecimal()', () {
      test('checks decimal', () {
        final s = Series(['123', '12.5', 'abc'], name: 'text');
        final result = s.str.isdecimal();
        expect(result.data, [true, false, false]);
      });
    });

    group('str.get()', () {
      test('gets element from lists', () {
        final s = Series([
          ['a', 'b'],
          ['c', 'd']
        ], name: 'lists');
        final result = s.str.get(0);
        expect(result.data, ['a', 'c']);
      });

      test('handles out of bounds', () {
        final s = Series([
          ['a'],
          ['b', 'c']
        ], name: 'lists');
        final result = s.str.get(1);
        expect(result.data[0], isNull); // First list doesn't have index 1
        expect(result.data[1], 'c');
      });
    });
  });
}
