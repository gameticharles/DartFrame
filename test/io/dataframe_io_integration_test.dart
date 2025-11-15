import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame I/O Integration Tests', () {
    late DataFrame testDf;
    final testDir = Directory('test_output');

    setUp(() {
      // Create test DataFrame
      testDf = DataFrame.fromMap({
        'id': [1, 2, 3],
        'name': ['Alice', 'Bob', 'Charlie'],
        'score': [95.5, 87.3, 92.1],
        'active': [true, false, true],
      });

      // Create test directory
      if (!testDir.existsSync()) {
        testDir.createSync(recursive: true);
      }
    });

    tearDown(() {
      // Clean up test files
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    });

    test('CSV round-trip', () async {
      final path = '${testDir.path}/test.csv';

      // Write
      await testDf.toCSV(path: path);
      expect(File(path).existsSync(), isTrue);

      // Read
      final df = await DataFrame.fromCSV(path: path);
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(4));
      expect(df.columns, containsAll(['id', 'name', 'score', 'active']));
    });

    test('Excel round-trip', () async {
      final path = '${testDir.path}/test.xlsx';

      // Write
      await testDf.toExcel(path: path, sheetName: 'TestData');
      expect(File(path).existsSync(), isTrue);

      // Read
      final df = await DataFrame.fromExcel(path: path);
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(4));
      expect(df.columns, containsAll(['id', 'name', 'score', 'active']));
    });

    test('JSON round-trip', () async {
      final path = '${testDir.path}/test.json';

      // Write
      await testDf.toJSON(path: path, orient: 'records', indent: 2);
      expect(File(path).existsSync(), isTrue);

      // Read
      final df = await DataFrame.fromJson(path: path, orient: 'records');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(4));
      expect(df.columns, containsAll(['id', 'name', 'score', 'active']));
    });

    test('CSV with custom delimiter', () async {
      final path = '${testDir.path}/test_semicolon.csv';

      // Write with semicolon delimiter
      await testDf.toCSV(path: path, fieldDelimiter: ';');
      expect(File(path).existsSync(), isTrue);

      // Read with semicolon delimiter
      final df = await DataFrame.fromCSV(path: path, fieldDelimiter: ';');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(4));
    });

    test('Excel with index column', () async {
      final path = '${testDir.path}/test_with_index.xlsx';

      // Write with index
      await testDf.toExcel(path: path, includeIndex: true);
      expect(File(path).existsSync(), isTrue);

      // Read (index will be read as a regular column)
      final df = await DataFrame.fromExcel(path: path);
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(5)); // 4 data columns + 1 index column
    });

    test('JSON columns orientation', () async {
      final path = '${testDir.path}/test_columns.json';

      // Write in columns format
      await testDf.toJSON(path: path, orient: 'columns');
      expect(File(path).existsSync(), isTrue);

      // Read columns format
      final df = await DataFrame.fromJson(path: path, orient: 'columns');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(4));
    });

    test('JSON in-memory conversion', () {
      // Test records format (default)
      final recordsJson = testDf.toJSON();
      expect(recordsJson, isA<List<Map<String, dynamic>>>());
      expect(recordsJson.length, equals(3));
      expect(recordsJson[0]['name'], equals('Alice'));

      // Test columns format
      final columnsJson = testDf.toJSON(orient: 'columns');
      expect(columnsJson, isA<Map<String, List<dynamic>>>());
      expect(columnsJson['name'], equals(['Alice', 'Bob', 'Charlie']));

      // Test values format
      final valuesJson = testDf.toJSON(orient: 'values');
      expect(valuesJson, isA<List<List<dynamic>>>());
      expect(valuesJson.length, equals(3));
      expect(valuesJson[0].length, equals(4));
    });

    test('Parquet round-trip (basic)', () async {
      final path = '${testDir.path}/test.parquet';

      // Write
      await testDf.toParquet(path: path);
      expect(File(path).existsSync(), isTrue);

      // Read
      final df = await DataFrame.fromParquet(path: path);
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(4));
    });
  });
}
