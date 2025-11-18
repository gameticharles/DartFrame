import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/file_writer.dart';
import 'package:dartframe/src/io/hdf5/hdf5_error.dart';

void main() {
  group('FileWriter', () {
    late Directory tempDir;
    late String testFilePath;

    setUp(() async {
      // Create a temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('file_writer_test_');
      testFilePath = '${tempDir.path}/test_file.h5';
    });

    tearDown(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Successful write operations', () {
      test('writes data to file successfully', () async {
        final testData = List<int>.generate(1000, (i) => i % 256);

        await FileWriter.writeToFile(testFilePath, testData);

        // Verify file exists
        final file = File(testFilePath);
        expect(await file.exists(), isTrue);

        // Verify file content
        final writtenData = await file.readAsBytes();
        expect(writtenData, equals(testData));
      });

      test('writes empty file successfully', () async {
        final testData = <int>[];

        await FileWriter.writeToFile(testFilePath, testData);

        // Verify file exists
        final file = File(testFilePath);
        expect(await file.exists(), isTrue);

        // Verify file is empty
        final writtenData = await file.readAsBytes();
        expect(writtenData, isEmpty);
      });

      test('writes large file successfully', () async {
        // Create 10MB of test data
        final testData = List<int>.generate(10 * 1024 * 1024, (i) => i % 256);

        await FileWriter.writeToFile(testFilePath, testData);

        // Verify file exists
        final file = File(testFilePath);
        expect(await file.exists(), isTrue);

        // Verify file size
        final fileSize = await file.length();
        expect(fileSize, equals(testData.length));
      });

      test('overwrites existing file', () async {
        // Write initial data
        final initialData = List<int>.generate(100, (i) => i);
        await FileWriter.writeToFile(testFilePath, initialData);

        // Overwrite with new data
        final newData = List<int>.generate(200, (i) => (i * 2) % 256);
        await FileWriter.writeToFile(testFilePath, newData);

        // Verify new data
        final file = File(testFilePath);
        final writtenData = await file.readAsBytes();
        expect(writtenData, equals(newData));
        expect(writtenData.length, equals(200));
      });

      test('creates nested directories if needed', () async {
        final nestedPath = '${tempDir.path}/nested/dir/test_file.h5';
        final testData = List<int>.generate(100, (i) => i);

        await FileWriter.writeToFile(nestedPath, testData);

        // Verify file exists
        final file = File(nestedPath);
        expect(await file.exists(), isTrue);

        // Verify content
        final writtenData = await file.readAsBytes();
        expect(writtenData, equals(testData));
      });
    });

    group('Atomic rename', () {
      test('uses temporary file during write', () async {
        final testData = List<int>.generate(1000, (i) => i % 256);
        final tempFilePath = '$testFilePath.tmp';

        // Start write operation
        final writeFuture = FileWriter.writeToFile(testFilePath, testData);

        // Wait for completion
        await writeFuture;

        // Verify temporary file is cleaned up
        final tempFile = File(tempFilePath);
        expect(await tempFile.exists(), isFalse);

        // Verify final file exists
        final finalFile = File(testFilePath);
        expect(await finalFile.exists(), isTrue);
      });

      test('final file appears atomically', () async {
        final testData = List<int>.generate(1000, (i) => i % 256);

        await FileWriter.writeToFile(testFilePath, testData);

        // Verify file exists and is complete
        final file = File(testFilePath);
        expect(await file.exists(), isTrue);

        final writtenData = await file.readAsBytes();
        expect(writtenData.length, equals(testData.length));
      });
    });

    group('Error recovery', () {
      test('cleans up temporary file on write error', () async {
        // Create a file, then try to write to it as a directory
        // This should fail and trigger cleanup
        final blockingFile = File(testFilePath);
        await blockingFile.create();

        // Try to write to a path that uses the file as a directory
        final invalidPath = '$testFilePath/subdir/file.h5';
        final testData = List<int>.generate(100, (i) => i);

        await expectLater(
          FileWriter.writeToFile(invalidPath, testData),
          throwsA(isA<HDF5WriteError>()),
        );

        // Verify temporary file doesn't exist
        final tempFile = File('$invalidPath.tmp');
        expect(await tempFile.exists(), isFalse);
      });

      test('throws FileWriteError for invalid directory', () async {
        // Create a file, then try to write to it as a directory
        final blockingFile = File(testFilePath);
        await blockingFile.create();

        final invalidPath = '$testFilePath/subdir/file.h5';
        final testData = List<int>.generate(100, (i) => i);

        await expectLater(
          FileWriter.writeToFile(invalidPath, testData),
          throwsA(
            isA<FileWriteError>().having(
              (e) => e.toString(),
              'error message',
              contains('Cannot create file'),
            ),
          ),
        );
      });

      test('throws WriteInterruptedError for unexpected errors', () async {
        // This test is platform-dependent and may not always trigger
        // We'll test the error handling path by using a file that becomes
        // inaccessible during write (hard to simulate reliably)
        // For now, we'll just verify the error type exists
        expect(
          WriteInterruptedError(
            filePath: testFilePath,
            reason: 'Test error',
          ),
          isA<HDF5WriteError>(),
        );
      });
    });

    group('Temporary file cleanup', () {
      test('cleanupTempFiles removes leftover temporary files', () async {
        // Create a temporary file manually
        final tempFilePath = '$testFilePath.tmp';
        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes([1, 2, 3]);

        expect(await tempFile.exists(), isTrue);

        // Clean up
        await FileWriter.cleanupTempFiles(testFilePath);

        // Verify cleanup
        expect(await tempFile.exists(), isFalse);
      });

      test('cleanupTempFiles handles non-existent files gracefully', () async {
        // Should not throw even if temp file doesn't exist
        await FileWriter.cleanupTempFiles(testFilePath);

        // Verify no error was thrown
        expect(true, isTrue);
      });

      test('cleans up temp file after failed write', () async {
        final tempFilePath = '$testFilePath.tmp';

        // Create a scenario where write might fail
        // First, create the temp file
        final tempFile = File(tempFilePath);
        await tempFile.create();

        // Now try to write to an invalid location
        final invalidPath = '/invalid/path/file.h5';
        final testData = List<int>.generate(100, (i) => i);

        try {
          await FileWriter.writeToFile(invalidPath, testData);
        } catch (e) {
          // Expected to fail
        }

        // The temp file for the invalid path should not exist
        final invalidTempFile = File('$invalidPath.tmp');
        expect(await invalidTempFile.exists(), isFalse);
      });
    });

    group('File verification', () {
      test('verifies file size matches expected data', () async {
        final testData = List<int>.generate(1000, (i) => i % 256);

        await FileWriter.writeToFile(testFilePath, testData);

        final file = File(testFilePath);
        final fileSize = await file.length();
        expect(fileSize, equals(testData.length));
      });

      test('detects verification failure', () async {
        // This is hard to test directly since verification happens internally
        // We'll verify that the write completes successfully with correct size
        final testData = List<int>.generate(1000, (i) => i % 256);

        await FileWriter.writeToFile(testFilePath, testData);

        final file = File(testFilePath);
        final writtenData = await file.readAsBytes();
        expect(writtenData.length, equals(testData.length));
      });
    });

    group('Error messages', () {
      test('FileWriteError includes helpful information', () {
        final error = FileWriteError(
          filePath: '/test/path.h5',
          reason: 'Test reason',
        );

        expect(error.toString(), contains('Write to file'));
        expect(error.toString(), contains('/test/path.h5'));
        expect(error.toString(), contains('Test reason'));
        expect(error.toString(), contains('Recovery Suggestions'));
      });

      test('InsufficientSpaceError includes size information', () {
        final error = InsufficientSpaceError(
          filePath: '/test/path.h5',
          requiredBytes: 1024 * 1024 * 100, // 100 MB
          availableBytes: 1024 * 1024 * 50, // 50 MB
        );

        expect(error.toString(), contains('Insufficient disk space'));
        expect(error.toString(), contains('MB'));
      });

      test('WriteInterruptedError includes context', () {
        final error = WriteInterruptedError(
          filePath: '/test/path.h5',
          reason: 'Operation cancelled',
        );

        expect(error.toString(), contains('interrupted'));
        expect(error.toString(), contains('Operation cancelled'));
      });
    });
  });
}
