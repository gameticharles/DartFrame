import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame Constructors and Missing Value Handling', () {
    test('DataFrame() default constructor with formatData', () {
      var df = DataFrame(
        [
          [1, 'NA', 3.0],
          [null, 5, ''],
          [7, 'missing', 9]
        ],
        columns: ['A', 'B', 'C'],
        missingDataIndicator: ['NA', 'missing', 'N/A'],
        formatData: true,
      );
      // Default replaceMissingValueWith is null
      expect(df.rows[0][1], isNull, reason: "NA should be null");
      expect(df.rows[1][0], isNull, reason: "Actual null should be null");
      expect(df.rows[1][2], isNull, reason: "Empty string should be null");
      expect(df.rows[2][1], isNull, reason: "'missing' should be null");
    });

    test('DataFrame() with specific replaceMissingValueWith and formatData',
        () {
      var df = DataFrame(
        [
          [1, 'NA', 3.0],
          [null, 5, ''],
        ],
        columns: ['A', 'B', 'C'],
        missingDataIndicator: ['NA'],
        replaceMissingValueWith: -1, // Specific placeholder
        formatData: true,
      );
      expect(df.rows[0][1], equals(-1), reason: "NA should be -1");
      expect(df.rows[1][0], equals(-1), reason: "Actual null should be -1");
      expect(df.rows[1][2], equals(-1), reason: "Empty string should be -1");
      expect(df.rows[0][0], equals(1)); // Non-missing value
    });

    test('DataFrame.fromCSV with default missing handling (null)', () async {
      var csvData = 'col1,col2,col3\n1,NA,test\n4,,6\n,8,N/A';
      var df = await DataFrame.fromCSV(
        csv: csvData,
        missingDataIndicator: ['NA', 'N/A'],
        formatData: true, // formatData enables _cleanData
      );
      // Default replaceMissingValueWith is null
      expect(df.columns, equals(['col1', 'col2', 'col3']));
      expect(df.rows[0][1], isNull, reason: "NA should be null");
      expect(df.rows[1][1], isNull,
          reason: "Empty string from CSV should be null");
      expect(df.rows[2][0], isNull,
          reason: "Empty string at start of line from CSV should be null");
      expect(df.rows[2][2], isNull, reason: "N/A should be null");
      expect(df.rows[0][0], equals(1)); // Parsed as int
      expect(df.rows[0][2], equals('test'));
    });

    test('DataFrame.fromCSV with specific replaceMissingValueWith', () async {
      var csvData = 'A,B\n1,NA\n,empty';
      var df = await DataFrame.fromCSV(
        csv: csvData,
        missingDataIndicator: ['NA', 'empty'],
        replaceMissingValueWith: 'MISSING',
        formatData: true,
      );
      expect(df.rows[0][1], equals('MISSING'));
      expect(df.rows[1][0], equals('MISSING'));
      expect(df.rows[1][1], equals('MISSING'));
      expect(df.rows[0][0], equals(1));
    });

    test('DataFrame.fromJson with null values (default to null)', () async {
      var jsonData = '[{"X": 1, "Y": null}, {"X": null, "Y": "bar"}]';
      var df = await DataFrame.fromJson(
        jsonString: jsonData,
        formatData: true, // formatData enables _cleanData
      );
      // Default replaceMissingValueWith is null
      expect(df.rows[0][1], isNull);
      expect(df.rows[1][0], isNull);
      expect(df.rows[0][0], equals(1));
      expect(df.rows[1][1], equals('bar'));
    });

    test('DataFrame.fromJson with specific replaceMissingValueWith', () async {
      var jsonData = '[{"X": 1, "Y": null}]';
      var df = await DataFrame.fromJson(
        jsonString: jsonData,
        replaceMissingValueWith: "JSON_NULL",
        formatData: true,
      );
      expect(df.rows[0][1], equals('JSON_NULL'));
      expect(df.rows[0][0], equals(1));
    });

    test('DataFrame.fromMap with null values and formatData', () {
      var mapData = {
        'colA': [1, null, 3],
        'colB': ['x', 'y', null],
      };
      var df = DataFrame.fromMap(
        mapData,
        formatData: true, // formatData enables _cleanData
      );
      // Default replaceMissingValueWith is null
      expect(df.rows[1][0], isNull);
      expect(df.rows[2][1], isNull);
      expect(df.rows[0][0], equals(1));
    });

    test(
        'DataFrame.fromMap with specific replaceMissingValueWith and formatData',
        () {
      var mapData = {
        'colA': [1, null],
        'colB': ['x', 'y'],
      };
      var df = DataFrame.fromMap(
        mapData,
        replaceMissingValueWith: -999,
        formatData: true,
      );
      expect(df.rows[1][0], equals(-999));
      expect(df.rows[0][0], equals(1));
    });

    test('_cleanData behavior direct check', () {
      // Scenario 1: Default (replaceMissingValueWith = null)
      var df1 = DataFrame.empty(missingDataIndicator: ['NA']);
      expect(df1.cleanData('NA'), isNull);
      expect(df1.cleanData(null), isNull);
      expect(df1.cleanData(''), isNull);
      expect(df1.cleanData('valid'), equals('valid'));

      // Scenario 2: Specific replaceMissingValueWith
      var df2 = DataFrame.empty(
          missingDataIndicator: ['NA'], replaceMissingValueWith: 'MISSING');
      expect(df2.cleanData('NA'), equals('MISSING'));
      expect(df2.cleanData(null), equals('MISSING'));
      expect(df2.cleanData(''), equals('MISSING'));
      expect(df2.cleanData('valid'), equals('valid'));

      // Scenario 3: Specific numeric replaceMissingValueWith
      var df3 = DataFrame.empty(
          missingDataIndicator: ['NA'], replaceMissingValueWith: -1.0);
      expect(df3.cleanData('NA'), equals(-1.0));
      expect(df3.cleanData(null), equals(-1.0));
      expect(df3.cleanData(''), equals(-1.0));
      expect(df3.cleanData(123), equals(123)); // Should not replace valid data
    });
  });

  group('fillna() with missing value standardization', () {
    test('fillna() with default missing (null)', () {
      var df = DataFrame([
        [1, null, 3],
        [null, 5, null]
      ], columns: [
        'A',
        'B',
        'C'
      ], formatData: true); // formatData ensures nulls

      var dfFilled = df.fillna(0);
      expect(dfFilled.rows[0][1], equals(0));
      expect(dfFilled.rows[1][0], equals(0));
      expect(dfFilled.rows[1][2], equals(0));
      expect(dfFilled.rows[0][0], equals(1)); // Unchanged
    });

    test('fillna() with specific replaceMissingValueWith', () {
      var df = DataFrame([
        [1, 'NA', 3],
        ['missing', 5, 'NA']
      ], columns: [
        'A',
        'B',
        'C'
      ], missingDataIndicator: [
        'NA',
        'missing'
      ], replaceMissingValueWith: -100, formatData: true);

      // df.rows should now have -100 where 'NA' or 'missing' was
      expect(df.rows[0][1], equals(-100));
      expect(df.rows[1][0], equals(-100));

      var dfFilled = df.fillna(99); // Fill -100 with 99
      expect(dfFilled.rows[0][1], equals(99));
      expect(dfFilled.rows[1][0], equals(99));
      expect(dfFilled.rows[1][2], equals(99));
      expect(dfFilled.rows[0][0], equals(1)); // Unchanged
    });
  });

  group('dropna() with missing value standardization', () {
    test('dropna() with default missing (null), axis=0 (rows)', () {
      var df = DataFrame([
        [1, null, 3],
        [4, 5, 6],
        [null, null, null],
        [7, 8, null]
      ], columns: [
        'A',
        'B',
        'C'
      ], formatData: true);

      var dfDroppedAny = df.dropna(how: 'any');
      expect(dfDroppedAny.rowCount, equals(1));
      expect(dfDroppedAny.rows[0], equals([4, 5, 6]));

      var dfDroppedAll = df.dropna(how: 'all');
      expect(dfDroppedAll.rowCount, equals(3));
      expect(dfDroppedAll.rows[0], equals([1, null, 3]));
      expect(dfDroppedAll.rows[1], equals([4, 5, 6]));
      expect(dfDroppedAll.rows[2], equals([7, 8, null]));
    });

    test('dropna() with specific replaceMissingValueWith, axis=0 (rows)', () {
      var df = DataFrame([
        [1, 'X', 3],
        [4, 5, 6],
        ['X', 'X', 'X'],
        [7, 8, 'X']
      ], columns: [
        'A',
        'B',
        'C'
      ], replaceMissingValueWith: 'X', formatData: true);
      // Note: formatData:true will convert 'X' to 'X' (no change) if it's not a special parsing case
      // but the key is that 'X' is now the missing value marker for dropna.

      var dfDroppedAny = df.dropna(how: 'any');
      expect(dfDroppedAny.rowCount, equals(1));
      expect(dfDroppedAny.rows[0], equals([4, 5, 6]));

      var dfDroppedAll = df.dropna(how: 'all');
      expect(dfDroppedAll.rowCount, equals(3));
    });

    test('dropna() with default missing (null), axis=1 (columns)', () {
      var df = DataFrame([
        [1, null, 3],
        [4, null, 6],
        [7, null, 9]
      ], columns: [
        'A',
        'B',
        'C'
      ], formatData: true);

      var dfDroppedAny = df.dropna(axis: 1, how: 'any');
      expect(dfDroppedAny.columnCount, equals(2));
      expect(dfDroppedAny.columns, equals(['A', 'C']));
      expect(dfDroppedAny.rows[0], equals([1, 3]));

      var dfAllNullCol = DataFrame([
        [1, null, null],
        [4, 5, null],
        [7, 8, null]
      ], columns: [
        'X',
        'Y',
        'Z'
      ], formatData: true);
      var dfDroppedAll = dfAllNullCol.dropna(axis: 1, how: 'all');
      expect(dfDroppedAll.columnCount, equals(2));
      expect(dfDroppedAll.columns, equals(['X', 'Y']));
    });
  });

  group('Statistical methods with missing values', () {
    test('Series methods ignore missing values (null)', () {
      var s = Series([1, 2, null, 4, 5, null], name: 'test');
      // Assuming Series uses null as its internal missing representation
      expect(s.count(), equals(4));
      expect(s.sum(), equals(12)); // 1+2+4+5
      expect(s.mean(), equals(3.0)); // 12 / 4
    });

    test('Series methods ignore specific replaceMissingValueWith', () {
      var df = DataFrame.empty(
          replaceMissingValueWith: -1); // Parent DataFrame sets context
      var s = Series([-1, 1, 2, -1, 3], name: 'test_specific');
      s.setParent(df, 'test_specific'); // Link series to DataFrame

      expect(s.count(), equals(3)); // Should count 1, 2, 3
      expect(s.sum(), equals(6)); // 1+2+3
      expect(s.mean(), equals(2.0)); // 6 / 3
    });

    test('DataFrame.describe() with missing values (null)', () {
      var df = DataFrame([
        [1.0, null, 10],
        [2.0, 20.0, null],
        [null, 30.0, 30],
        [4.0, 40.0, 40],
      ], columns: [
        'N1',
        'N2',
        'N3'
      ], formatData: true);

      var desc = df.describe();
      expect(desc['N1']!.at('count'), equals(3));
      expect(desc['N1']!.at('mean'), closeTo((1 + 2 + 4) / 3, 0.001));

      expect(desc['N2']!.at('count'), equals(3));
      expect(desc['N2']!.at('mean'), closeTo((20 + 30 + 40) / 3, 0.001));

      expect(desc['N3']!.at('count'), equals(3));
      expect(desc['N3']!.at('mean'), closeTo((10 + 30 + 40) / 3, 0.001));
    });
  });
}
