import 'dart:io';
import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  // Cleanup helper
  Future<void> cleanup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        // File might be locked, wait and retry
        await Future.delayed(Duration(milliseconds: 100));
        try {
          await file.delete();
        } catch (_) {
          // Ignore if still can't delete
        }
      }
    }
  }

  group('Format Converter - NDArray', () {
    final testArray = NDArray([
      [1, 2, 3],
      [4, 5, 6],
    ]);

    tearDown(() async {
      await cleanup('test_convert.dcf');
      await cleanup('test_convert.json');
      await cleanup('test_convert.csv');
      await cleanup('test_convert.bin');
    });

    test('convert to DCF', () async {
      await testArray.exportTo('test_convert.dcf', DataFormat.dcf);

      expect(File('test_convert.dcf').existsSync(), isTrue);

      final loaded = await NDArrayDCF.fromDCF('test_convert.dcf');
      expect(loaded.shape.toList(), equals([2, 3]));
    });

    test('convert to JSON', () async {
      await testArray.toJSON('test_convert.json');

      expect(File('test_convert.json').existsSync(), isTrue);

      final loaded = await FormatConverter.readNDArray(
        'test_convert.json',
        DataFormat.json,
      );
      expect(loaded.shape.toList(), equals([2, 3]));
      expect(loaded.getValue([0, 0]), equals(1));
      expect(loaded.getValue([1, 2]), equals(6));
    });

    test('convert to CSV', () async {
      await testArray.toCSV('test_convert.csv');

      expect(File('test_convert.csv').existsSync(), isTrue);

      final content = await File('test_convert.csv').readAsString();
      expect(content, contains('1'));
      expect(content, contains('6'));
    });

    test('convert to binary', () async {
      await testArray.toBinary('test_convert.bin');

      expect(File('test_convert.bin').existsSync(), isTrue);
      expect(File('test_convert.bin').lengthSync(), greaterThan(0));
    });

    test('convert with compression', () async {
      await testArray.exportTo(
        'test_convert.dcf',
        DataFormat.dcf,
        compression: CompressionCodec.gzip,
      );

      final loaded = await NDArrayDCF.fromDCF('test_convert.dcf');
      expect(loaded.shape.toList(), equals([2, 3]));
    });

    test('convert with attributes', () async {
      testArray.attrs['units'] = 'meters';
      testArray.attrs['description'] = 'Test data';

      await testArray.toJSON('test_convert.json');

      final loaded = await FormatConverter.readNDArray(
        'test_convert.json',
        DataFormat.json,
      );

      // Note: Attributes are in JSON but not automatically loaded
      // This is expected behavior
      expect(loaded.shape.toList(), equals([2, 3]));
    });
  });

  group('Format Converter - DataCube', () {
    final testCube = DataCube.generate(2, 3, 4, (d, r, c) => d + r + c);

    tearDown(() async {
      await cleanup('test_cube.dcf');
      await cleanup('test_cube.json');
      await cleanup('test_cube.bin');
    });

    test('convert DataCube to DCF', () async {
      await testCube.exportTo('test_cube.dcf', DataFormat.dcf);

      expect(File('test_cube.dcf').existsSync(), isTrue);

      final loaded = await DataCubeDCF.fromDCF('test_cube.dcf');
      expect(loaded.depth, equals(2));
      expect(loaded.rows, equals(3));
      expect(loaded.columns, equals(4));
    });

    test('convert DataCube to JSON', () async {
      await testCube.toJSON('test_cube.json');

      expect(File('test_cube.json').existsSync(), isTrue);

      final loaded = await FormatConverter.readDataCube(
        'test_cube.json',
        DataFormat.json,
      );
      expect(loaded.depth, equals(2));
      expect(loaded.rows, equals(3));
      expect(loaded.columns, equals(4));
    });

    test('convert DataCube to binary', () async {
      await testCube.toBinary('test_cube.bin');

      expect(File('test_cube.bin').existsSync(), isTrue);
    });

    test('convert DataCube with compression', () async {
      await testCube.exportTo(
        'test_cube.dcf',
        DataFormat.dcf,
        compression: CompressionCodec.gzip,
      );

      final loaded = await DataCubeDCF.fromDCF('test_cube.dcf');
      expect(loaded.depth, equals(2));
    });
  });

  group('Format Converter - Batch Operations', () {
    tearDown(() async {
      await cleanup('test1.dcf');
      await cleanup('test2.dcf');
      await cleanup('output/test1.json');
      await cleanup('output/test2.json');

      final dir = Directory('output');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('batch convert files', () async {
      // Create source files
      final array1 = NDArray([1, 2, 3]);
      final array2 = NDArray([4, 5, 6]);

      await array1.toDCF('test1.dcf');
      await array2.toDCF('test2.dcf');

      // Create output directory
      await Directory('output').create();

      // Batch convert
      await FormatConverter.convertBatch(
        ['test1.dcf', 'test2.dcf'],
        'output',
        DataFormat.dcf,
        ConversionOptions(targetFormat: DataFormat.json),
      );

      expect(File('output/test1.json').existsSync(), isTrue);
      expect(File('output/test2.json').existsSync(), isTrue);
    });
  });

  group('Format Converter - Edge Cases', () {
    tearDown(() async {
      await cleanup('test_edge.dcf');
      await cleanup('test_edge.json');
      await cleanup('test_edge.csv');
    });

    test('convert 1D array', () async {
      final array = NDArray([1, 2, 3, 4, 5]);

      await array.exportTo('test_edge.dcf', DataFormat.dcf);
      final loaded = await NDArrayDCF.fromDCF('test_edge.dcf');

      expect(loaded.shape.toList(), equals([5]));
    });

    test('convert 3D array', () async {
      final array = NDArray.zeros([2, 3, 4]);

      await array.exportTo('test_edge.dcf', DataFormat.dcf);
      final loaded = await NDArrayDCF.fromDCF('test_edge.dcf');

      expect(loaded.shape.toList(), equals([2, 3, 4]));
    });

    test('CSV requires 2D array', () async {
      final array = NDArray([1, 2, 3]);

      expect(
        () => array.toCSV('test_edge.csv'),
        throwsArgumentError,
      );
    });

    test('DataCube requires 3D data', () async {
      final array = NDArray([
        [1, 2],
        [3, 4],
      ]);

      await array.toJSON('test_edge.json');

      expect(
        () => FormatConverter.readDataCube('test_edge.json', DataFormat.json),
        throwsArgumentError,
      );
    });
  });

  group('Format Converter - Round-trip', () {
    tearDown(() async {
      await cleanup('test_roundtrip.dcf');
      await cleanup('test_roundtrip.json');
    });

    test('DCF round-trip', () async {
      final original = NDArray.generate([10, 10], (i) => i[0] * 10 + i[1]);

      await original.exportTo('test_roundtrip.dcf', DataFormat.dcf);
      final loaded = await NDArrayDCF.fromDCF('test_roundtrip.dcf');

      expect(loaded.shape.toList(), equals(original.shape.toList()));

      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
          expect(loaded.getValue([i, j]), equals(original.getValue([i, j])));
        }
      }
    });

    test('JSON round-trip', () async {
      final original = NDArray([
        [1, 2, 3],
        [4, 5, 6],
      ]);

      await original.toJSON('test_roundtrip.json');
      final loaded = await FormatConverter.readNDArray(
        'test_roundtrip.json',
        DataFormat.json,
      );

      expect(loaded.shape.toList(), equals(original.shape.toList()));
      expect(loaded.getValue([0, 0]), equals(1));
      expect(loaded.getValue([1, 2]), equals(6));
    });
  });
}
