import 'dart:io';
import 'hdf5_error.dart';

/// Handles safe file writing operations with atomic guarantees
///
/// This class implements a temporary file strategy to ensure that write
/// operations are atomic - either the file is completely written or no
/// partial file is left behind.
///
/// The write process:
/// 1. Write data to a temporary file (.tmp extension)
/// 2. Verify the written data
/// 3. Atomically rename the temporary file to the target path
/// 4. Clean up temporary files on error
///
/// Example usage:
/// ```dart
/// final writer = FileWriter();
/// await writer.writeToFile('/path/to/file.h5', fileBytes);
/// ```
class FileWriter {
  /// Write bytes to a file with atomic guarantees
  ///
  /// Parameters:
  /// - [path]: The target file path
  /// - [data]: The bytes to write
  ///
  /// Throws:
  /// - [FileWriteError] if the write operation fails
  /// - [InsufficientSpaceError] if there is not enough disk space
  /// - [WriteInterruptedError] if the write is interrupted
  ///
  /// The method ensures atomicity by:
  /// 1. Writing to a temporary file first
  /// 2. Verifying the write was successful
  /// 3. Atomically renaming to the target path
  /// 4. Cleaning up on any error
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
      // Note: Dart doesn't have a built-in way to check disk space
      // We'll attempt the write and catch space-related errors
      final requiredSpace = data.length;

      // Write data to temporary file
      try {
        await tempFile.writeAsBytes(data, flush: true);
      } on FileSystemException catch (e) {
        // Check if this is a space-related error
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
          // Log cleanup error but don't throw - original error is more important
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
  ///
  /// Returns true if the file size matches the expected data length
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
  ///
  /// This is a heuristic check based on error messages since Dart doesn't
  /// provide specific error codes for disk space issues
  static bool _isSpaceError(FileSystemException e) {
    final message = e.message.toLowerCase();
    return message.contains('space') ||
        message.contains('disk full') ||
        message.contains('no space') ||
        message.contains('quota');
  }

  /// Clean up temporary files for a given path
  ///
  /// This is a utility method to clean up any leftover temporary files
  /// from previous failed write attempts
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
