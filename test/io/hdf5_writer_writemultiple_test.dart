import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

/// Integration tests for HDF5WriterUtils.writeMultiple()
void main() {
  group('HDF5WriterUtils.writeMultiple()', () {
    final testFile = 'test/fixtures/writemultiple_test_output.h5';

    tearDown(() async {
      // Clean up test file
      final file = File(testFile);
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('throws ArgumentError for empty datasets map', () async {
      await expectLater(
        HDF5WriterUtils.writeMultiple(testFile, {}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('writes single NDArray dataset', () async {
      final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);

      await HDF5WriterUtils.writeMultiple(testFile, {
        '/data': array,
      });

      // Verify file exists
      final file = File(testFile);
      expect(await file.exists(), isTrue);

      // Verify file can be read
      final hdf5File = await Hdf5File.open(testFile);
      try {
        final dataset = await hdf5File.dataset('/data');
        expect(dataset.dataspace.dimensions, equals([2, 2]));
      } finally {
        await hdf5File.close();
      }
    });

    test('writes multiple NDArray datasets', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);
      final array2 = NDArray.fromFlat([4.0, 5.0, 6.0], [3]);
      final array3 = NDArray.fromFlat([7.0, 8.0, 9.0, 10.0], [2, 2]);

      await HDF5WriterUtils.writeMultiple(testFile, {
        '/data1': array1,
        '/data2': array2,
        '/matrix': array3,
      });

      // Verify file exists
      final file = File(testFile);
      expect(await file.exists(), isTrue);

      // Verify all datasets can be read
      final hdf5File = await Hdf5File.open(testFile);
      try {
        final dataset1 = await hdf5File.dataset('/data1');
        expect(dataset1.dataspace.dimensions, equals([3]));

        final dataset2 = await hdf5File.dataset('/data2');
        expect(dataset2.dataspace.dimensions, equals([3]));

        final dataset3 = await hdf5File.dataset('/matrix');
        expect(dataset3.dataspace.dimensions, equals([2, 2]));
      } finally {
        await hdf5File.close();
      }
    });

    test('writes datasets with nested groups', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);

      await HDF5WriterUtils.writeMultiple(testFile, {
        '/group1/data': array1,
        '/group2/data': array2,
      });

      // Verify file exists
      final file = File(testFile);
      expect(await file.exists(), isTrue);

      // Verify datasets can be read
      final hdf5File = await Hdf5File.open(testFile);
      try {
        final dataset1 = await hdf5File.dataset('/group1/data');
        expect(dataset1.dataspace.dimensions, equals([2]));

        final dataset2 = await hdf5File.dataset('/group2/data');
        expect(dataset2.dataspace.dimensions, equals([2]));
      } finally {
        await hdf5File.close();
      }
    }, skip: 'Nested groups not fully supported yet');

    test('writes mixed data types (NDArray and DataCube)', () async {
      final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);
      final cube = DataCube.zeros(2, 2, 2);

      await HDF5WriterUtils.writeMultiple(testFile, {
        '/array': array,
        '/cube': cube,
      });

      // Verify file exists
      final file = File(testFile);
      expect(await file.exists(), isTrue);

      // Verify datasets can be read
      final hdf5File = await Hdf5File.open(testFile);
      try {
        final dataset1 = await hdf5File.dataset('/array');
        expect(dataset1.dataspace.dimensions, equals([3]));

        final dataset2 = await hdf5File.dataset('/cube');
        expect(dataset2.dataspace.dimensions, equals([2, 2, 2]));
      } finally {
        await hdf5File.close();
      }
    });

    test('writes mixed NDArray and DataFrame', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
      final array2 = NDArray.fromFlat([5.0, 6.0, 7.0], [3]);
      final df = DataFrame.fromMap({
        'x': [10, 20, 30],
        'y': [1.5, 2.5, 3.5],
      });

      await HDF5WriterUtils.writeMultiple(testFile, {
        '/arrays/matrix': array1,
        '/arrays/vector': array2,
        '/tables/data': df,
      });

      // Verify file exists
      final file = File(testFile);
      expect(await file.exists(), isTrue);

      // Verify all datasets can be read
      final hdf5File = await Hdf5File.open(testFile);
      try {
        final dataset1 = await hdf5File.dataset('/arrays/matrix');
        expect(dataset1.dataspace.dimensions, equals([2, 2]));

        final dataset2 = await hdf5File.dataset('/arrays/vector');
        expect(dataset2.dataspace.dimensions, equals([3]));

        final dataset3 = await hdf5File.dataset('/tables/data');
        expect(dataset3.dataspace.dimensions, equals([3]));
      } finally {
        await hdf5File.close();
      }
    }, skip: 'Nested groups not fully supported yet');

    test('writes deeply nested group structures', () async {
      final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
      final array2 = NDArray.fromFlat([3.0, 4.0], [2]);
      final array3 = NDArray.fromFlat([5.0, 6.0], [2]);

      await HDF5WriterUtils.writeMultiple(testFile, {
        '/level1/level2/level3/data1': array1,
        '/level1/level2/data2': array2,
        '/level1/data3': array3,
      });

      // Verify file exists
      final file = File(testFile);
      expect(await file.exists(), isTrue);

      // Verify all datasets can be read
      final hdf5File = await Hdf5File.open(testFile);
      try {
        final dataset1 = await hdf5File.dataset('/level1/level2/level3/data1');
        expect(dataset1.dataspace.dimensions, equals([2]));

        final dataset2 = await hdf5File.dataset('/level1/level2/data2');
        expect(dataset2.dataspace.dimensions, equals([2]));

        final dataset3 = await hdf5File.dataset('/level1/data3');
        expect(dataset3.dataspace.dimensions, equals([2]));
      } finally {
        await hdf5File.close();
      }
    }, skip: 'Nested groups not fully supported yet');

    test('writes multiple datasets with compression and chunking', () async {
      final array1 =
          NDArray.fromFlat(List.generate(200, (i) => i.toDouble()), [200]);
      final array2 =
          NDArray.fromFlat(List.generate(100, (i) => i * 2.0), [10, 10]);
      final array3 = NDArray.fromFlat(List.generate(50, (i) => i * 3.0), [50]);

      await HDF5WriterUtils.writeMultiple(
        testFile,
        {
          '/compressed/gzip': array1,
          '/compressed/lzf': array2,
          '/uncompressed': array3,
        },
        perDatasetOptions: {
          '/compressed/gzip': WriteOptions(
            layout: StorageLayout.chunked,
            chunkDimensions: [100],
            compression: CompressionType.gzip,
            compressionLevel: 9,
          ),
          '/compressed/lzf': WriteOptions(
            layout: StorageLayout.chunked,
            chunkDimensions: [5, 5],
            compression: CompressionType.lzf,
          ),
        },
      );

      // Verify file exists
      final file = File(testFile);
      expect(await file.exists(), isTrue);

      // Verify all datasets can be read and have correct data
      final hdf5File = await Hdf5File.open(testFile);
      try {
        final reader = await ByteReader.open(testFile);

        final dataset1 = await hdf5File.dataset('/compressed/gzip');
        expect(dataset1.dataspace.dimensions, equals([200]));
        final data1 = await dataset1.readData(reader);
        expect(data1.length, equals(200));

        final dataset2 = await hdf5File.dataset('/compressed/lzf');
        expect(dataset2.dataspace.dimensions, equals([10, 10]));
        final data2 = await dataset2.readData(reader);
        expect(data2.length, equals(100));

        final dataset3 = await hdf5File.dataset('/uncompressed');
        expect(dataset3.dataspace.dimensions, equals([50]));
        final data3 = await dataset3.readData(reader);
        expect(data3.length, equals(50));
      } finally {
        await hdf5File.close();
      }
    }, skip: 'Nested groups not fully supported yet');

    test('writes DataFrame with compound strategy', () async {
      final df = DataFrame.fromMap({
        'a': [1, 2, 3],
        'b': [4.0, 5.0, 6.0],
      });

      await HDF5WriterUtils.writeMultiple(testFile, {
        '/dataframe': df,
      });

      // Verify file exists
      final file = File(testFile);
      expect(await file.exists(), isTrue);

      // Verify dataset can be read
      final hdf5File = await Hdf5File.open(testFile);
      try {
        final dataset = await hdf5File.dataset('/dataframe');
        expect(dataset.dataspace.dimensions, equals([3]));
      } finally {
        await hdf5File.close();
      }
    });

    test('throws for unsupported data type', () async {
      await expectLater(
        HDF5WriterUtils.writeMultiple(testFile, {
          '/invalid': 'not a valid type',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('writes with default options', () async {
      final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);

      await HDF5WriterUtils.writeMultiple(
        testFile,
        {'/data': array},
      );

      final file = File(testFile);
      expect(await file.exists(), isTrue);
    });

    test('writes with per-dataset options', () async {
      final array1 =
          NDArray.fromFlat(List.generate(100, (i) => i.toDouble()), [100]);
      final array2 = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);

      await HDF5WriterUtils.writeMultiple(
        testFile,
        {
          '/compressed': array1,
          '/uncompressed': array2,
        },
        perDatasetOptions: {
          '/compressed': WriteOptions(
            layout: StorageLayout.chunked,
            chunkDimensions: [50],
            compression: CompressionType.gzip,
            compressionLevel: 6,
          ),
        },
      );

      final file = File(testFile);
      expect(await file.exists(), isTrue);

      // Verify both datasets can be read
      final hdf5File = await Hdf5File.open(testFile);
      try {
        final dataset1 = await hdf5File.dataset('/compressed');
        expect(dataset1.dataspace.dimensions, equals([100]));

        final dataset2 = await hdf5File.dataset('/uncompressed');
        expect(dataset2.dataspace.dimensions, equals([3]));
      } finally {
        await hdf5File.close();
      }
    });
  });
}
