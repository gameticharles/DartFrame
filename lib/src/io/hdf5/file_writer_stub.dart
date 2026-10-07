/// Stub FileWriter for platform-independent compilation
class FileWriter {
  static Future<void> writeToFile(String path, List<int> data) async {
    throw UnsupportedError('FileWriter is not supported on this platform');
  }

  static Future<void> cleanupTempFiles(String path) async {}
}
