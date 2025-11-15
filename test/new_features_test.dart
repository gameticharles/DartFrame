import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('New Features Tests', () {
    group('DataFrame.duplicated()', () {
      test('identifies duplicates with keep=first', () {
        final df = DataFrame.fromRows([
          {'A': 1, 'B': 'x'},
          {'A': 2, 'B': 'y'},
          {'A': 1, 'B': 'x'}, // duplicate
          {'A': 3, 'B': 'z'},
          {'A': 1, 'B': 'x'}, // duplicate
        ]);

        final dups = df.duplicated();
        expect(dups.data, [false, false, true, false, true]);
      });

      test('identifies duplicates with keep=last', () {
        final df = DataFrame.fromRows([
          {'A': 1, 'B': 'x'},
          {'A': 2, 'B': 'y'},
          {'A': 1, 'B': 'x'},
        ]);

        final dups = df.duplicated(keep: 'last');
        expect(dups.data, [true, false, false]);
      });

      test('identifies all duplicates with keep=false', () {
        final df = DataFrame.fromRows([
          {'A': 1, 'B': 'x'},
          {'A': 2, 'B': 'y'},
          {'A': 1, 'B': 'x'},
        ]);

        final dups = df.duplicated(keep: false);
        expect(dups.data, [true, false, true]);
      });

      test('works with subset parameter', () {
        final df = DataFrame.fromRows([
          {'A': 1, 'B': 'x', 'C': 10},
          {'A': 1, 'B': 'y', 'C': 20},
          {'A': 2, 'B': 'x', 'C': 30},
        ]);

        final dups = df.duplicated(subset: ['A']);
        expect(dups.data, [false, true, false]);
      });
    });

    group('DataFrame.dropDuplicates()', () {
      test('removes duplicate rows', () {
        final df = DataFrame.fromRows([
          {'A': 1, 'B': 'x'},
          {'A': 2, 'B': 'y'},
          {'A': 1, 'B': 'x'}, // duplicate
          {'A': 3, 'B': 'z'},
        ]);

        final unique = df.dropDuplicates();
        expect(unique.rowCount, 3);
        expect(unique['A'].data, [1, 2, 3]);
      });

      test('keeps last occurrence with keep=last', () {
        final df = DataFrame.fromRows([
          {'A': 1, 'B': 'x'},
          {'A': 1, 'B': 'y'},
        ]);

        final unique = df.dropDuplicates(subset: ['A'], keep: 'last');
        expect(unique.rowCount, 1);
        expect(unique['B'].data, ['y']);
      });
    });

    group('DataFrame.nlargest()', () {
      test('returns n largest values', () {
        final df = DataFrame.fromRows([
          {'Name': 'Alice', 'Score': 95},
          {'Name': 'Bob', 'Score': 87},
          {'Name': 'Charlie', 'Score': 92},
          {'Name': 'David', 'Score': 88},
        ]);

        final top2 = df.nlargest(2, 'Score');
        expect(top2.rowCount, 2);
        expect(top2['Score'].data, [95, 92]);
        expect(top2['Name'].data, ['Alice', 'Charlie']);
      });

      test('works with multiple columns', () {
        final df = DataFrame.fromRows([
          {'A': 1, 'B': 10},
          {'A': 2, 'B': 5},
          {'A': 1, 'B': 20},
        ]);

        final result = df.nlargest(2, ['A', 'B']);
        expect(result.rowCount, 2);
      });
    });

    group('DataFrame.nsmallest()', () {
      test('returns n smallest values', () {
        final df = DataFrame.fromRows([
          {'Name': 'Alice', 'Score': 95},
          {'Name': 'Bob', 'Score': 87},
          {'Name': 'Charlie', 'Score': 92},
        ]);

        final bottom2 = df.nsmallest(2, 'Score');
        expect(bottom2.rowCount, 2);
        expect(bottom2['Score'].data, [87, 92]);
      });
    });

    group('Series.idxmin()', () {
      test('returns index of minimum value', () {
        final s = Series([5, 2, 8, 1, 9], name: 'values');
        expect(s.idxmin(), 3);
      });

      test('throws on empty series', () {
        final s = Series([], name: 'empty');
        expect(() => s.idxmin(), throwsException);
      });
    });

    group('Series.nlargest()', () {
      test('returns n largest values', () {
        final s = Series([5, 2, 8, 1, 9, 3], name: 'values');
        final top3 = s.nlargest(3);
        expect(top3.data, [9, 8, 5]);
      });

      test('maintains original indices', () {
        final s = Series([5, 2, 8, 1, 9, 3],
            name: 'values', index: ['a', 'b', 'c', 'd', 'e', 'f']);
        final top3 = s.nlargest(3);
        expect(top3.index, ['e', 'c', 'a']);
      });
    });

    group('Series.nsmallest()', () {
      test('returns n smallest values', () {
        final s = Series([5, 2, 8, 1, 9, 3], name: 'values');
        final bottom3 = s.nsmallest(3);
        expect(bottom3.data, [1, 2, 3]);
      });
    });

    group('Existing Features - Verification', () {
      test('Series.abs() works', () {
        final s = Series([-5, 3, -2, 0, 7], name: 'values');
        final absS = s.abs();
        expect(absS.data, [5, 3, 2, 0, 7]);
      });

      test('Series.pctChange() works', () {
        final s = Series([100, 110, 121], name: 'price');
        final pct = s.pctChange();
        expect(pct.data[0], isNull); // First value is null
        expect(pct.data[1], closeTo(0.1, 0.001)); // 10% increase
        expect(pct.data[2], closeTo(0.1, 0.001)); // 10% increase
      });

      test('Series.diff() works', () {
        final s = Series([1, 3, 6, 10, 15], name: 'cumsum');
        final diffS = s.diff();
        expect(diffS.data[0], isNull); // First value is null
        expect(diffS.data[1], 2);
        expect(diffS.data[2], 3);
        expect(diffS.data[3], 4);
        expect(diffS.data[4], 5);
      });
    });
  });
}
