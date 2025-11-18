import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/src/data_frame/data_frame.dart';
import 'package:dartframe/src/io/hdf5_writer.dart';
import 'package:dartframe/src/io/hdf5/hdf5_writer.dart' show HDF5WriterUtils;
import 'package:dartframe/src/io/hdf5/hdf5_error.dart';

/// Test HDF5Writer implementation of DataWriter interface
void main() {
  group('HDF5Writer DataWriter Implementation', () {
    late Directory tempDir;
    late String testFilePath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hdf5_writer_test_');
      testFilePath = '${tempDir.path}/test_data.h5';
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('implements DataWriter interface', () {
      final writer = HDF5Writer();
      expect(writer, isA<HDF5Writer>());
    });

    test('writes DataFrame to HDF5 file', () async {
      final df = DataFrame.fromMap({
        'col1': [1, 2, 3, 4, 5],
        'col2': [10.5, 20.5, 30.5, 40.5, 50.5],
      });

      final writer = HDF5Writer();
      await writer.write(df, testFilePath);

      // Verify file exists
      final file = File(testFilePath);
      expect(await file.exists(), isTrue);

      // Verify file has content
      final fileSize = await file.length();
      expect(fileSize, greaterThan(0));
    });

    test('writes DataFrame with custom dataset path', () async {
      final df = DataFrame.fromMap({
        'temperature': [20.5, 21.0, 19.8],
        'humidity': [65, 68, 62],
      });

      final writer = HDF5Writer();
      await writer.write(df, testFilePath, options: {
        'dataset': '/measurements',
      });

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);
    });

    test('writes DataFrame with attributes', () async {
      final df = DataFrame.fromMap({
        'data': [1.0, 2.0, 3.0],
      });

      final writer = HDF5Writer();
      await writer.write(df, testFilePath, options: {
        'dataset': '/data',
        'attributes': {
          'units': 'meters',
          'description': 'Test measurements',
          'version': 1,
        },
      });

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);
    });

    test('writeDataFrame static method works', () async {
      final df = DataFrame.fromMap({
        'x': [1, 2, 3],
        'y': [4, 5, 6],
      });

      await HDF5Writer.writeDataFrame(
        df,
        testFilePath,
        dataset: '/data',
        attributes: {'source': 'test'},
      );

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);
    });

    test('handles invalid dataset name', () async {
      final df = DataFrame.fromMap({
        'data': [1, 2, 3],
      });

      final writer = HDF5Writer();
      await expectLater(
        writer.write(df, testFilePath, options: {
          'dataset': 'invalid_name', // Should start with /
        }),
        throwsA(isA<InvalidDatasetNameError>()),
      );
    });

    test('handles write errors gracefully', () async {
      final df = DataFrame.fromMap({
        'data': [1, 2, 3],
      });

      // Create a blocking file
      final blockingFile = File(testFilePath);
      await blockingFile.create();

      // Try to write to a path that uses the file as a directory
      final invalidPath = '$testFilePath/subdir/file.h5';

      final writer = HDF5Writer();
      await expectLater(
        writer.write(df, invalidPath),
        throwsA(isA<FileWriteError>()),
      );
    });

    test('debug mode can be enabled', () async {
      final df = DataFrame.fromMap({
        'data': [1, 2, 3],
      });

      final writer = HDF5Writer();
      await writer.write(df, testFilePath, options: {
        'debug': true,
      });

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);
    });

    test('setDebugMode static method works', () {
      // Should not throw
      HDF5Writer.setDebugMode(true);
      HDF5Writer.setDebugMode(false);
      expect(true, isTrue);
    });

    test('converts DataFrame with multiple columns correctly', () async {
      final df = DataFrame.fromMap({
        'a': [1, 2, 3],
        'b': [4, 5, 6],
        'c': [7, 8, 9],
      });

      final writer = HDF5Writer();
      await writer.write(df, testFilePath);

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);

      // File should contain data for 3 rows x 3 columns
      final fileSize = await file.length();
      expect(fileSize, greaterThan(100)); // Should have substantial content
    });

    test('handles single column DataFrame', () async {
      final df = DataFrame.fromMap({
        'single': [1.0, 2.0, 3.0, 4.0, 5.0],
      });

      final writer = HDF5Writer();
      await writer.write(df, testFilePath);

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);
    });

    test('handles empty DataFrame', () async {
      final df = DataFrame.fromMap({
        'col1': <int>[],
        'col2': <double>[],
      });

      final writer = HDF5Writer();

      // Empty DataFrames should fail validation
      await expectLater(
        writer.write(df, testFilePath),
        throwsA(isA<DataValidationError>()),
      );
    });

    test('writeMultiple throws for multiple datasets', () async {
      final df1 = DataFrame.fromMap({
        'a': [1, 2, 3]
      });
      final df2 = DataFrame.fromMap({
        'b': [4, 5, 6]
      });

      await expectLater(
        HDF5WriterUtils.writeMultiple(testFilePath, {
          '/dataset1': df1,
          '/dataset2': df2,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('writeMultiple works with single dataset', () async {
      final df = DataFrame.fromMap({
        'data': [1, 2, 3]
      });

      await HDF5WriterUtils.writeMultiple(testFilePath, {
        '/data': df,
      });

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);
    });

    test('writeMultiple handles empty map', () async {
      // Should throw ArgumentError for empty map
      await expectLater(
        HDF5WriterUtils.writeMultiple(testFilePath, {}),
        throwsA(isA<ArgumentError>()),
      );

      final file = File(testFilePath);
      expect(await file.exists(), isFalse);
    });
  });
}
