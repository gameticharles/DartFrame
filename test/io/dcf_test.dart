import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';
import 'package:dartframe/src/datacube/datacube.dart';
import 'package:dartframe/src/io/dcf/dcf_writer.dart';
import 'package:dartframe/src/io/dcf/dcf_reader.dart';
import 'package:dartframe/src/io/dcf/format_spec.dart';

void main() {
  // Cleanup helper
  Future<void> cleanup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  group('DCF Format Specification', () {
    test('header creation and serialization', () {
      final header = DCFHeader.create();

      expect(header.magic, equals(DCF_MAGIC));
      expect(header.version, equals(DCF_VERSION));

      final bytes = header.toBytes();
      expect(bytes.length, equals(DCF_HEADER_SIZE));

      final parsed = DCFHeader.fromBytes(bytes);
      expect(parsed.magic, equals(header.magic));
      expect(parsed.version, equals(header.version));
    });

    test('header validation', () {
      final header = DCFHeader.create();
      expect(header.validate(), isTrue);

      final invalid = DCFHeader(
        magic: [0x00, 0x00, 0x00, 0x00],
        version: 1,
        flags: 0,
        rootOffset: 0,
        metadataOffset: 0,
        indexOffset: 0,
        dataOffset: 0,
        fileSize: 0,
        checksum: 0,
      );
      expect(invalid.validate(), isFalse);
    });

    test('CRC32 checksum', () {
      final data = [1, 2, 3, 4, 5];
      final checksum = calculateCRC32(data);
      expect(checksum, isA<int>());
      expect(checksum, isNot(equals(0)));
    });
  });

  group('DCF Writer', () {
    final testFile = 'test_dcf_write.dcf';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('write and read 1D array', () async {
      final original = NDArray([1, 2, 3, 4, 5]);

      await original.toDCF(testFile);

      final loaded = await NDArrayDCF.fromDCF(testFile);

      expect(loaded.shape.toList(), equals([5]));
      expect(loaded.toFlatList(), equals([1, 2, 3, 4, 5]));
    });

    test('write and read 2D array', () async {
      final original = NDArray([
        [1, 2, 3],
        [4, 5, 6],
      ]);

      await original.toDCF(testFile);

      final loaded = await NDArrayDCF.fromDCF(testFile);

      expect(loaded.shape.toList(), equals([2, 3]));
      expect(loaded.getValue([0, 0]), equals(1));
      expect(loaded.getValue([1, 2]), equals(6));
    });

    test('write and read 3D array', () async {
      final original = NDArray.zeros([3, 4, 5]);
      original.setValue([1, 2, 3], 42.0);

      await original.toDCF(testFile);

      final loaded = await NDArrayDCF.fromDCF(testFile);

      expect(loaded.shape.toList(), equals([3, 4, 5]));
      expect(loaded.getValue([1, 2, 3]), equals(42.0));
    });

    test('write and read with attributes', () async {
      final original = NDArray([1, 2, 3, 4, 5]);
      original.attrs['units'] = 'meters';
      original.attrs['description'] = 'Test data';

      await original.toDCF(testFile);

      final loaded = await NDArrayDCF.fromDCF(testFile);

      expect(loaded.attrs['units'], equals('meters'));
      expect(loaded.attrs['description'], equals('Test data'));
    });

    test('write with compression', () async {
      final original = NDArray.generate([100, 100], (i) => i[0] + i[1]);

      await original.toDCF(
        testFile,
        codec: CompressionCodec.gzip,
        compressionLevel: 6,
      );

      final loaded = await NDArrayDCF.fromDCF(testFile);

      expect(loaded.shape.toList(), equals([100, 100]));
      expect(loaded.getValue([50, 50]), equals(100));
    });

    test('write with custom chunk shape', () async {
      final original = NDArray.zeros([100, 100]);

      await original.toDCF(
        testFile,
        chunkShape: [10, 10],
      );

      final loaded = await NDArrayDCF.fromDCF(testFile);

      expect(loaded.shape.toList(), equals([100, 100]));
    });
  });

  group('DCF Reader', () {
    final testFile = 'test_dcf_read.dcf';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('list datasets', () async {
      final writer = DCFWriter(testFile);
      await writer.open();

      await writer.writeDataset('/data1', NDArray([1, 2, 3]));
      await writer.writeDataset('/data2', NDArray([4, 5, 6]));

      await writer.close();

      final datasets = await DCFUtil.listDatasets(testFile);

      expect(datasets, contains('/data1'));
      expect(datasets, contains('/data2'));
    });

    test('get dataset info', () async {
      final original = NDArray([1, 2, 3, 4, 5]);
      await original.toDCF(testFile);

      final info = await DCFUtil.getDatasetInfo(testFile, '/data');

      expect(info, isNotNull);
      expect(info!.shape, equals([5]));
      expect(info.dtype, equals('float64'));
    });

    test('read specific dataset', () async {
      final writer = DCFWriter(testFile);
      await writer.open();

      await writer.writeDataset('/measurements', NDArray([1, 2, 3]));
      await writer.writeDataset('/calibration', NDArray([4, 5, 6]));

      await writer.close();

      final data = await NDArrayDCF.fromDCF(testFile, dataset: '/calibration');

      expect(data.toFlatList(), equals([4, 5, 6]));
    });
  });

  group('DataCube DCF', () {
    final testFile = 'test_dcf_cube.dcf';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('write and read DataCube', () async {
      final original = DataCube.zeros(3, 4, 5);
      original.data.setValue([1, 2, 3], 42.0);
      original.attrs['units'] = 'celsius';

      await original.toDCF(testFile);

      final loaded = await DataCubeDCF.fromDCF(testFile);

      expect(loaded.depth, equals(3));
      expect(loaded.rows, equals(4));
      expect(loaded.columns, equals(5));
      expect(loaded.data.getValue([1, 2, 3]), equals(42.0));
      expect(loaded.attrs['units'], equals('celsius'));
    });

    test('DataCube with compression', () async {
      final original = DataCube.generate(10, 20, 30, (d, r, c) => d + r + c);

      await original.toDCF(
        testFile,
        codec: CompressionCodec.gzip,
      );

      final loaded = await DataCubeDCF.fromDCF(testFile);

      expect(loaded.depth, equals(10));
      expect(loaded.rows, equals(20));
      expect(loaded.columns, equals(30));
      expect(loaded.data.getValue([5, 10, 15]), equals(30));
    });
  });

  group('Round-trip Tests', () {
    final testFile = 'test_dcf_roundtrip.dcf';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('NDArray round-trip preserves data', () async {
      final original = NDArray.generate([50, 50], (i) => i[0] * 50 + i[1]);
      original.attrs['test'] = 'value';

      await original.toDCF(testFile);
      final loaded = await NDArrayDCF.fromDCF(testFile);

      expect(loaded.shape.toList(), equals(original.shape.toList()));

      for (int i = 0; i < 50; i++) {
        for (int j = 0; j < 50; j++) {
          expect(loaded.getValue([i, j]), equals(original.getValue([i, j])));
        }
      }

      expect(loaded.attrs['test'], equals('value'));
    });

    test('DataCube round-trip preserves data', () async {
      final original =
          DataCube.generate(5, 10, 15, (d, r, c) => d * 100 + r * 10 + c);
      original.attrs['experiment'] = 'test123';

      await original.toDCF(testFile);
      final loaded = await DataCubeDCF.fromDCF(testFile);

      expect(loaded.depth, equals(original.depth));
      expect(loaded.rows, equals(original.rows));
      expect(loaded.columns, equals(original.columns));

      for (int d = 0; d < 5; d++) {
        for (int r = 0; r < 10; r++) {
          for (int c = 0; c < 15; c++) {
            expect(
              loaded.data.getValue([d, r, c]),
              equals(original.data.getValue([d, r, c])),
            );
          }
        }
      }

      expect(loaded.attrs['experiment'], equals('test123'));
    });

    test('compressed round-trip preserves data', () async {
      final original = NDArray.generate([100, 100], (i) => i[0] + i[1]);

      await original.toDCF(testFile, codec: CompressionCodec.gzip);
      final loaded = await NDArrayDCF.fromDCF(testFile);

      expect(loaded.shape.toList(), equals(original.shape.toList()));

      for (int i = 0; i < 100; i++) {
        for (int j = 0; j < 100; j++) {
          expect(loaded.getValue([i, j]), equals(original.getValue([i, j])));
        }
      }
    });
  });

  group('Edge Cases', () {
    final testFile = 'test_dcf_edge.dcf';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('empty array', () async {
      // Skip empty array test - NDArray doesn't support truly empty arrays
      // The shape [0] would require 0 elements, but NDArray needs at least shape info
    }, skip: 'NDArray does not support empty arrays');

    test('single element', () async {
      final original = NDArray([42]);

      await original.toDCF(testFile);
      final loaded = await NDArrayDCF.fromDCF(testFile);

      expect(loaded.shape.toList(), equals([1]));
      expect(loaded.getValue([0]), equals(42));
    });

    test('large array', () async {
      // Create array with a specific value
      final original = NDArray.generate(
          [100, 100], (i) => (i[0] == 50 && i[1] == 50) ? 123.456 : 0.0);

      await original.toDCF(testFile, codec: CompressionCodec.gzip);
      final loaded = await NDArrayDCF.fromDCF(testFile);

      expect(loaded.shape.toList(), equals([100, 100]));
      expect(loaded.getValue([50, 50]), equals(123.456));
      expect(loaded.getValue([0, 0]), equals(0.0));
    });
  });
}
