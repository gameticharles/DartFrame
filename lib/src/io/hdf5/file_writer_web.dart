import '../../file_helper/file_io.dart';

/// Handles file writing operations for Web environments using FileIO abstraction.
class FileWriter {
  /// Write bytes to a file
  static Future<void> writeToFile(String path, List<int> data) async {
    final fileIO = FileIO();
    await fileIO.writeBytesToFile(path, data);
  }

  /// Clean up temporary files (no-op on Web)
  static Future<void> cleanupTempFiles(String path) async {
    // No-op on Web
  }
}
