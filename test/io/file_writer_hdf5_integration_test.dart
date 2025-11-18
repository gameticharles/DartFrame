import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/src/data_frame/data_frame.dart';
import 'package:dartframe/src/io/writers.dart';

/// Test FileWriter integration with HDF5
void main() {
  group('FileWriter HDF5 Integration', () {
    late Directory tempDir;
    late String testFilePath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('filewriter_hdf5_');
      testFilePath = '${tempDir.path}/test_data.h5';
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('FileWriter.write auto-detects .h5 extension', () async {
      final df = DataFrame.fromMap({
        'data': [1.0, 2.0, 3.0],
      });

      await FileWriter.write(df, testFilePath);

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);
    });

    test('FileWriter.write auto-detects .hdf5 extension', () async {
      final df = DataFrame.fromMap({
        'data': [1.0, 2.0, 3.0],
      });

      final hdf5Path = '${tempDir.path}/test_data.hdf5';
      await FileWriter.write(df, hdf5Path);

      final file = File(hdf5Path);
      expect(await file.exists(), isTrue);
    });

    test('FileWriter.writeHDF5 convenience method works', () async {
      final df = DataFrame.fromMap({
        'temperature': [20.5, 21.0, 19.8],
        'humidity': [65, 68, 62],
      });

      await FileWriter.writeHDF5(
        df,
        testFilePath,
        dataset: '/measurements',
        attributes: {'units': 'celsius'},
      );

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);
    });

    test('FileWriter.write with HDF5 options', () async {
      final df = DataFrame.fromMap({
        'x': [1, 2, 3],
        'y': [4, 5, 6],
      });

      await FileWriter.write(df, testFilePath, options: {
        'dataset': '/data',
        'attributes': {'source': 'test'},
      });

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);
    });
  });
}
