import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('Async DataFrame I/O', () {
    group('DataFrame.fromCSV()', () {
      test('basic CSV string', () async {
        final csvString = 'colA,colB\n1,apple\n2,banana';
        final df = await DataFrame.fromCSV(csv: csvString);
        expect(df.rowCount, equals(2));
        expect(df.columnCount, equals(2));
        expect(df.columns, equals(['colA', 'colB']));
        expect(df.rows[0], equals(['1', 'apple'])); // fromCSV reads as strings initially unless formatData
      });

      test('CSV string with different delimiter and no header', () async {
        final csvString = '1;x\n2;y\n3;z';
        final df = await DataFrame.fromCSV(
          csv: csvString,
          delimiter: ';',
          hasHeader: false,
        );
        expect(df.rowCount, equals(3));
        expect(df.columns, equals(['Column 0', 'Column 1'])); // Auto-generated
        expect(df.rows[0], equals(['1', 'x']));
      });

      test('CSV string with formatData and missing values', () async {
        final csvString = 'val,cat\n10,A\n,B\n30,NA';
        final df = await DataFrame.fromCSV(
          csv: csvString,
          formatData: true,
          missingDataIndicator: ['NA'],
          // replaceMissingValueWith: null (default)
        );
        expect(df.rowCount, equals(3));
        expect(df.rows[0], equals([10, 'A']));
        expect(df.rows[1], equals([null, 'B'])); // Empty string becomes null
        expect(df.rows[2], equals([30, null])); // NA becomes null
      });
       test('CSV string with specific missing value placeholder', () async {
        final csvString = 'val,cat\n10,A\n,B\n30,NA';
        final df = await DataFrame.fromCSV(
          csv: csvString,
          formatData: true,
          missingDataIndicator: ['NA'],
          replaceMissingValueWith: -1
        );
        expect(df.rowCount, equals(3));
        expect(df.rows[0], equals([10, 'A']));
        expect(df.rows[1], equals([-1, 'B'])); 
        expect(df.rows[2], equals([30, -1])); 
      });
    });

    group('DataFrame.fromJson()', () {
      test('basic JSON string', () async {
        final jsonString = '[{"colA": 1, "colB": "apple"}, {"colA": 2, "colB": "banana"}]';
        final df = await DataFrame.fromJson(jsonString: jsonString);
        expect(df.rowCount, equals(2));
        expect(df.columnCount, equals(2));
        expect(df.columns, equals(['colA', 'colB']));
        expect(df.rows[0], equals([1, 'apple']));
      });

      test('JSON string with formatData and null values', () async {
        final jsonString = '[{"val": 10, "cat": "A"}, {"val": null, "cat": "B"}]';
        final df = await DataFrame.fromJson(
          jsonString: jsonString,
          formatData: true,
          // replaceMissingValueWith: null (default)
        );
        expect(df.rowCount, equals(2));
        expect(df.rows[0], equals([10, 'A']));
        expect(df.rows[1], equals([null, 'B'])); // JSON null becomes null
      });

      test('JSON string with specific missing value placeholder', () async {
        final jsonString = '[{"val": 10, "cat": "A"}, {"val": null, "cat": "B"}]';
        final df = await DataFrame.fromJson(
          jsonString: jsonString,
          formatData: true,
          replaceMissingValueWith: "MISSING"
        );
        expect(df.rowCount, equals(2));
        expect(df.rows[0], equals([10, 'A']));
        expect(df.rows[1], equals(["MISSING", 'B']));
      });
    });
  });
}
