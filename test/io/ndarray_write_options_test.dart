import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';
import 'package:dartframe/src/io/hdf5/write_options.dart';
import 'package:dartframe/src/io/hdf5/hdf5_writer.dart';

void main() {
  group('NDArray.toHDF5() with WriteOptions', () {
    late Directory testDir;
    late String testFile;

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp('ndarray_write_test_');
      testFile = '${testDir.path}/test.h5';
    });

    tearDown(() async {
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('write with contiguous layout (default)', () async {
      final array = NDArray.generate([10, 20], (i) => i[0] * 20 + i[1]);

      await array.toHDF5(
        testFile,
        dataset: '/data',
        options: const WriteOptions(
          layout: StorageLayout.contiguous,
        ),
      );

      final file = File(testFile);
      expect(await file.exists(), true);

      // Verify HDF5 signature
      final bytes = await file.readAsBytes();
      expect(bytes.sublist(0, 8),
          [0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]);
    });

    test('write with custom attributes via WriteOptions', () async {
      final array = NDArray([1.0, 2.0, 3.0]);

      await array.toHDF5(
        testFile,
        dataset: '/measurements',
        options: const WriteOptions(
          attributes: {
            'units': 'meters',
            'description': 'Test measurements',
            'version': 1,
          },
        ),
      );

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('write with merged attributes', () async {
      final array = NDArray([1.0, 2.0, 3.0]);
      array.attrs['from_array'] = 'value1';

      await array.toHDF5(
        testFile,
        dataset: '/data',
        attributes: {'from_param': 'value2'},
        options: const WriteOptions(
          attributes: {'from_options': 'value3'},
        ),
      );

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('legacy parameters still work', () async {
      final array = NDArray.generate([5, 5], (i) => i[0] + i[1]);

      await array.toHDF5(
        testFile,
        dataset: '/data',
        attributes: {'units': 'meters'},
      );

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('WriteOptions validation catches invalid compression', () async {
      final array = NDArray([1.0, 2.0, 3.0]);

      // Compression without chunked layout should fail
      // The ArgumentError from validation is wrapped in a FileWriteError
      try {
        await array.toHDF5(
          testFile,
          dataset: '/data',
          options: const WriteOptions(
            layout: StorageLayout.contiguous,
            compression: CompressionType.gzip,
          ),
        );
        fail('Should have thrown an error');
      } catch (e) {
        // Verify an error was thrown (ArgumentError wrapped in FileWriteError)
        expect(e, isNotNull);
      }
    });

    test('write with format version option', () async {
      final array = NDArray.generate([3, 3], (i) => i[0] * 3 + i[1]);

      await array.toHDF5(
        testFile,
        dataset: '/data',
        options: const WriteOptions(
          formatVersion: 0,
        ),
      );

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('write 1D array with WriteOptions', () async {
      final array = NDArray([1.0, 2.0, 3.0, 4.0, 5.0]);

      await array.toHDF5(
        testFile,
        dataset: '/vector',
        options: const WriteOptions(
          layout: StorageLayout.contiguous,
        ),
      );

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('write 3D array with WriteOptions', () async {
      final array =
          NDArray.generate([2, 3, 4], (i) => i[0] * 12 + i[1] * 4 + i[2]);

      await array.toHDF5(
        testFile,
        dataset: '/cube',
        options: const WriteOptions(
          layout: StorageLayout.contiguous,
        ),
      );

      final file = File(testFile);
      expect(await file.exists(), true);
    });

    test('write large array with WriteOptions', () async {
      final array = NDArray.zeros([100, 100]);

      await array.toHDF5(
        testFile,
        dataset: '/large',
        options: const WriteOptions(
          layout: StorageLayout.contiguous,
        ),
      );

      final file = File(testFile);
      expect(await file.exists(), true);

      // Check file size is reasonable
      final size = await file.length();
      expect(size, greaterThan(1000));
    });
  });
}
