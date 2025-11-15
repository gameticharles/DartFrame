import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('CSV I/O Tests', () {
    final testData = DataFrame.fromMap({
      'name': ['Alice', 'Bob', 'Charlie'],
      'age': [25, 30, 35],
      'salary': [50000.0, 60000.0, 75000.0],
    });

    tearDown(() {
      // Clean up test files
      final files = [
        'test_output.csv',
        'test_output_custom.csv',
      ];
      for (final file in files) {
        final f = File(file);
        if (f.existsSync()) f.deleteSync();
      }
    });

    test('Write and read CSV', () async {
      await FileWriter.writeCsv(testData, 'test_output.csv');
      expect(File('test_output.csv').existsSync(), isTrue);

      final df = await FileReader.readCsv('test_output.csv');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(3));
      expect(df.columns, containsAll(['name', 'age', 'salary']));
    });

    test('Write CSV with custom delimiter', () async {
      await FileWriter.writeCsv(
        testData,
        'test_output_custom.csv',
        fieldDelimiter: ';',
      );

      final df = await FileReader.readCsv(
        'test_output_custom.csv',
        fieldDelimiter: ';',
      );
      expect(df.shape.rows, equals(3));
      expect(df.columns, containsAll(['name', 'age', 'salary']));
    });

    test('Write CSV with index', () async {
      await FileWriter.writeCsv(
        testData,
        'test_output.csv',
        includeIndex: true,
      );

      final df = await FileReader.readCsv('test_output.csv');
      expect(df.columns.contains('index'), isTrue);
    });
  });

  group('Excel I/O Tests', () {
    final testData = DataFrame.fromMap({
      'product': ['Widget', 'Gadget', 'Doohickey'],
      'quantity': [10, 20, 15],
      'price': [9.99, 19.99, 14.99],
    });

    tearDown(() {
      // Clean up test files
      final files = [
        'test_output.xlsx',
        'test_output_custom.xlsx',
      ];
      for (final file in files) {
        final f = File(file);
        if (f.existsSync()) f.deleteSync();
      }
    });

    test('Write and read Excel', () async {
      await FileWriter.writeExcel(testData, 'test_output.xlsx');
      expect(File('test_output.xlsx').existsSync(), isTrue);

      final df = await FileReader.readExcel('test_output.xlsx');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(3));
      expect(df.columns, containsAll(['product', 'quantity', 'price']));
    });

    test('Write Excel with custom sheet name', () async {
      await FileWriter.writeExcel(
        testData,
        'test_output_custom.xlsx',
        sheetName: 'Products',
      );

      final sheets =
          await FileReader.listExcelSheets('test_output_custom.xlsx');
      expect(sheets, contains('Products'));

      final df = await FileReader.readExcel(
        'test_output_custom.xlsx',
        sheetName: 'Products',
      );
      expect(df.shape.rows, equals(3));
    });

    test('Write Excel with index', () async {
      await FileWriter.writeExcel(
        testData,
        'test_output.xlsx',
        includeIndex: true,
      );

      final df = await FileReader.readExcel('test_output.xlsx');
      expect(df.columns.contains('index'), isTrue);
    });
  });

  group('Excel Multi-Sheet Tests', () {
    final sheet1Data = DataFrame.fromMap({
      'name': ['Alice', 'Bob'],
      'age': [25, 30],
    });

    final sheet2Data = DataFrame.fromMap({
      'product': ['Widget', 'Gadget'],
      'price': [9.99, 19.99],
    });

    tearDown(() {
      final files = ['test_multisheet.xlsx'];
      for (final file in files) {
        final f = File(file);
        if (f.existsSync()) f.deleteSync();
      }
    });

    test('Write and read multiple sheets', () async {
      final sheets = {
        'People': sheet1Data,
        'Products': sheet2Data,
      };

      await FileWriter.writeExcelSheets(sheets, 'test_multisheet.xlsx');
      expect(File('test_multisheet.xlsx').existsSync(), isTrue);

      final readSheets =
          await FileReader.readAllExcelSheets('test_multisheet.xlsx');
      expect(readSheets.length, equals(2));
      expect(readSheets.keys, containsAll(['People', 'Products']));
      expect(readSheets['People']!.shape.rows, equals(2));
      expect(readSheets['Products']!.shape.rows, equals(2));
    });

    test('Read all sheets returns correct data', () async {
      final sheets = {
        'Sheet1': sheet1Data,
        'Sheet2': sheet2Data,
      };

      await FileWriter.writeExcelSheets(sheets, 'test_multisheet.xlsx');

      final readSheets =
          await FileReader.readAllExcelSheets('test_multisheet.xlsx');

      // Verify Sheet1
      expect(readSheets['Sheet1']!.columns, containsAll(['name', 'age']));
      expect(readSheets['Sheet1']!['name']![0], equals('Alice'));

      // Verify Sheet2
      expect(readSheets['Sheet2']!.columns, containsAll(['product', 'price']));
      expect(readSheets['Sheet2']!['product']![0], equals('Widget'));
    });

    test('List sheets after multi-sheet write', () async {
      final sheets = {
        'Sales': sheet1Data,
        'Inventory': sheet2Data,
        'Summary': sheet1Data,
      };

      await FileWriter.writeExcelSheets(sheets, 'test_multisheet.xlsx');

      final sheetNames =
          await FileReader.listExcelSheets('test_multisheet.xlsx');
      expect(sheetNames.length, equals(3));
      expect(sheetNames, containsAll(['Sales', 'Inventory', 'Summary']));
    });

    test('Read specific sheet from multi-sheet file', () async {
      final sheets = {
        'First': sheet1Data,
        'Second': sheet2Data,
      };

      await FileWriter.writeExcelSheets(sheets, 'test_multisheet.xlsx');

      final df = await FileReader.readExcel(
        'test_multisheet.xlsx',
        sheetName: 'Second',
      );

      expect(df.columns, containsAll(['product', 'price']));
      expect(df.shape.rows, equals(2));
    });
  });

  group('Generic FileReader/FileWriter Tests', () {
    final testData = DataFrame.fromMap({
      'x': [1, 2, 3],
      'y': [4, 5, 6],
    });

    tearDown(() {
      final files = ['test_auto.csv', 'test_auto.xlsx'];
      for (final file in files) {
        final f = File(file);
        if (f.existsSync()) f.deleteSync();
      }
    });

    test('Auto-detect CSV format', () async {
      await FileWriter.write(testData, 'test_auto.csv');
      final df = await FileReader.read('test_auto.csv');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(2));
    });

    test('Auto-detect Excel format', () async {
      await FileWriter.write(testData, 'test_auto.xlsx');
      final df = await FileReader.read('test_auto.xlsx');
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(2));
    });
  });
}
