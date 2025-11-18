import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';
import 'package:dartframe/src/io/hdf5/hdf5_writer.dart';
import 'package:dartframe/src/io/hdf5/hdf5_error.dart';

/// Integration test to verify FileWriter is properly integrated with HDF5Writer
void main() {
  group('HDF5 Writer with FileWriter Integration', () {
    late Directory tempDir;
    late String testFilePath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hdf5_integration_');
      testFilePath = '${tempDir.path}/test_data.h5';
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('writes HDF5 file atomically using FileWriter', () async {
      // Create test data
      final array = NDArray.generate([10, 5], (indices) {
        return indices[0] * 5 + indices[1];
      });

      // Write using HDF5Writer (which uses FileWriter internally)
      await array.toHDF5(
        testFilePath,
        dataset: '/data',
        attributes: {'units': 'meters', 'description': 'Test data'},
      );

      // Verify file exists
      final file = File(testFilePath);
      expect(await file.exists(), isTrue);

      // Verify no temporary file exists (FileWriter cleaned it up)
      final tempFile = File('$testFilePath.tmp');
      expect(await tempFile.exists(), isFalse);

      // Verify file has content
      final fileSize = await file.length();
      expect(fileSize, greaterThan(0));
    });

    test('cleans up temporary file on write error', () async {
      // Create a blocking file to trigger an error
      final blockingFile = File(testFilePath);
      await blockingFile.create();

      // Try to write to a path that uses the file as a directory
      final invalidPath = '$testFilePath/subdir/file.h5';
      final array = NDArray.generate([5, 5], (indices) => 1.0);

      // This should fail with FileWriteError
      await expectLater(
        array.toHDF5(invalidPath),
        throwsA(isA<FileWriteError>()),
      );

      // Verify temporary file doesn't exist (FileWriter cleaned it up)
      final tempFile = File('$invalidPath.tmp');
      expect(await tempFile.exists(), isFalse);
    });

    test('atomic write ensures complete file or nothing', () async {
      final array = NDArray.generate([100, 100], (indices) {
        return indices[0] + indices[1] * 0.1;
      });

      // Write the file
      await array.toHDF5(testFilePath);

      // File should exist and be complete
      final file = File(testFilePath);
      expect(await file.exists(), isTrue);

      // File should have substantial size
      final fileSize = await file.length();
      expect(fileSize, greaterThan(1000)); // Should be at least 1KB

      // No temporary file should remain
      final tempFile = File('$testFilePath.tmp');
      expect(await tempFile.exists(), isFalse);
    });

    test('overwrites existing file atomically', () async {
      // Write initial file
      final array1 = NDArray.generate([5, 5], (indices) => 1.0);
      await array1.toHDF5(testFilePath);

      final initialSize = await File(testFilePath).length();

      // Overwrite with larger file
      final array2 = NDArray.generate([50, 50], (indices) => 2.0);
      await array2.toHDF5(testFilePath);

      // Verify file was overwritten
      final file = File(testFilePath);
      expect(await file.exists(), isTrue);

      final newSize = await file.length();
      expect(newSize, greaterThan(initialSize));

      // No temporary file should remain
      final tempFile = File('$testFilePath.tmp');
      expect(await tempFile.exists(), isFalse);
    });

    test('FileWriter integration preserves error handling', () async {
      // Test that HDF5WriteError types are preserved through FileWriter
      final array = NDArray.generate([5, 5], (indices) => 1.0);

      // Invalid dataset name should throw InvalidDatasetNameError
      await expectLater(
        array.toHDF5(testFilePath, dataset: 'invalid'),
        throwsA(isA<InvalidDatasetNameError>()),
      );

      // File should not exist after error
      final file = File(testFilePath);
      expect(await file.exists(), isFalse);

      // No temporary file should exist
      final tempFile = File('$testFilePath.tmp');
      expect(await tempFile.exists(), isFalse);
    });
  });
}
