import 'dart:io';
import 'hdf5_error.dart';

/// Handles safe file writing operations with atomic guarantees on native platforms.
class FileWriter {
  /// Write bytes to a file with atomic guarantees
  static Future<void> writeToFile(String path, List<int> data) async {
    // Generate temporary file path
    final tempPath = '$path.tmp';
    File? tempFile;

    try {
      // Create temporary file
      tempFile = File(tempPath);

      // Check if we have write permissions by attempting to create the file
      try {
        await tempFile.create(recursive: true);
      } on FileSystemException catch (e) {
        throw FileWriteError(
          filePath: path,
          reason: 'Cannot create file - check directory permissions',
          originalError: e,
          stackTrace: StackTrace.current,
        );
      }

      // Check available disk space (if possible)
      final requiredSpace = data.length;

      // Write data to temporary file
      try {
        await tempFile.writeAsBytes(data, flush: true);
      } on FileSystemException catch (e) {
        if (_isSpaceError(e)) {
          throw InsufficientSpaceError(
            filePath: path,
            requiredBytes: requiredSpace,
          );
        }
        throw FileWriteError(
          filePath: path,
          reason: 'Failed to write data to temporary file',
          originalError: e,
          stackTrace: StackTrace.current,
        );
      }

      // Verify the file was written correctly
      final written = await _verifyWrite(tempFile, data);
      if (!written) {
        throw FileWriteError(
          filePath: path,
          reason:
              'File write verification failed - data size mismatch. Expected ${data.length} bytes',
        );
      }

      // Atomic rename to target path
      try {
        // If target file exists, delete it first (Windows requirement)
        final targetFile = File(path);
        if (await targetFile.exists()) {
          await targetFile.delete();
        }

        await tempFile.rename(path);
      } on FileSystemException catch (e) {
        throw FileWriteError(
          filePath: path,
          reason: 'Failed to rename temporary file to target path',
          originalError: e,
          stackTrace: StackTrace.current,
        );
      }
    } catch (e) {
      // Clean up temporary file on any error
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (cleanupError) {
          hdf5DebugLog('Failed to clean up temporary file: $cleanupError');
        }
      }

      // Re-throw the original error
      if (e is HDF5WriteError) {
        rethrow;
      } else {
        throw WriteInterruptedError(
          filePath: path,
          reason: 'Write operation was interrupted',
          originalError: e,
          stackTrace: StackTrace.current,
        );
      }
    }
  }

  /// Verify that the file was written correctly
  static Future<bool> _verifyWrite(File file, List<int> expectedData) async {
    try {
      final fileSize = await file.length();
      return fileSize == expectedData.length;
    } catch (e) {
      hdf5DebugLog('File verification failed: $e');
      return false;
    }
  }

  /// Check if a FileSystemException is related to insufficient disk space
  static bool _isSpaceError(FileSystemException e) {
    final message = e.message.toLowerCase();
    return message.contains('space') ||
        message.contains('disk full') ||
        message.contains('no space') ||
        message.contains('quota');
  }

  /// Clean up temporary files for a given path
  static Future<void> cleanupTempFiles(String path) async {
    final tempPath = '$path.tmp';
    final tempFile = File(tempPath);

    if (await tempFile.exists()) {
      try {
        await tempFile.delete();
        hdf5DebugLog('Cleaned up temporary file: $tempPath');
      } catch (e) {
        hdf5DebugLog('Failed to clean up temporary file: $e');
      }
    }
  }
}
