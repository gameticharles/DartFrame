import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('JSON I/O Tests', () {
    final testData = DataFrame.fromMap({
      'name': ['Alice', 'Bob', 'Charlie'],
      'age': [25, 30, 35],
      'salary': [50000.0, 60000.0, 75000.0],
    });

    tearDown(() {
      // Clean up test files
      final files = [
        'test_records.json',
        'test_index.json',
        'test_columns.json',
        'test_values.json',
      ];
      for (final file in files) {
        final f = File(file);
        if (f.existsSync()) f.deleteSync();
      }
    });

    test('Write and read JSON in records format', () async {
      await FileWriter.writeJson(testData, 'test_records.json',
          orient: 'records');
      expect(File('test_records.json').existsSync(), isTrue);

      final df = await FileReader.readJson('test_records.json');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(3));
      expect(df.columns, containsAll(['name', 'age', 'salary']));
    });

    test('Write and read JSON in columns format', () async {
      await FileWriter.writeJson(testData, 'test_columns.json',
          orient: 'columns');

      final df =
          await FileReader.readJson('test_columns.json', orient: 'columns');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(3));
      expect(df.columns, containsAll(['name', 'age', 'salary']));
    });

    test('Write and read JSON in index format', () async {
      await FileWriter.writeJson(testData, 'test_index.json', orient: 'index');

      final df = await FileReader.readJson('test_index.json', orient: 'index');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(3));
      expect(df.columns, containsAll(['name', 'age', 'salary']));
    });

    test('Write and read JSON in values format', () async {
      await FileWriter.writeJson(testData, 'test_values.json',
          orient: 'values');

      final df = await FileReader.readJson('test_values.json',
          orient: 'values', columns: ['name', 'age', 'salary']);
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(3));
      expect(df.columns, containsAll(['name', 'age', 'salary']));
    });

    test('Read JSON with pretty printing', () async {
      await FileWriter.writeJson(testData, 'test_records.json',
          orient: 'records', indent: 2);

      final content = await File('test_records.json').readAsString();
      expect(content.contains('\n'), isTrue); // Has newlines from indentation

      final df = await FileReader.readJson('test_records.json');
      expect(df.shape.rows, equals(3));
    });

    test('Auto-detect JSON format', () async {
      await FileWriter.write(testData, 'test_records.json');
      final df = await FileReader.read('test_records.json');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(3));
    });

    test('Handle empty DataFrame', () async {
      final emptyDf = DataFrame.fromMap({});
      await FileWriter.writeJson(emptyDf, 'test_records.json');

      final df = await FileReader.readJson('test_records.json');
      expect(df.shape.rows, equals(0));
    });

    test('Handle null values', () async {
      final dfWithNulls = DataFrame.fromMap({
        'col1': [1, null, 3],
        'col2': ['a', 'b', null],
      });

      await FileWriter.writeJson(dfWithNulls, 'test_records.json');
      final df = await FileReader.readJson('test_records.json');

      expect(df.shape.rows, equals(3));
      expect(df['col1']![1], isNull);
      expect(df['col2']![2], isNull);
    });

    test('Throw error for invalid orientation', () async {
      await FileWriter.writeJson(testData, 'test_records.json');

      expect(
        () => FileReader.readJson('test_records.json', orient: 'invalid'),
        throwsA(isA<JsonReadError>()),
      );
    });

    test('Throw error for values format without columns', () async {
      await FileWriter.writeJson(testData, 'test_values.json',
          orient: 'values');

      // Should work with columns
      final df1 = await FileReader.readJson('test_values.json',
          orient: 'values', columns: ['a', 'b', 'c']);
      expect(df1.shape.columns, equals(3));

      // Should generate column names if not provided
      final df2 =
          await FileReader.readJson('test_values.json', orient: 'values');
      expect(df2.columns, containsAll(['col_0', 'col_1', 'col_2']));
    });
  });
}
