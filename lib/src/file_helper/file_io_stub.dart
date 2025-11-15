import 'file_io.dart';

class FileIO implements FileIOBase {
  @override
  Future<void> saveToFile(String path, String data) async {
    throw UnsupportedError('Cannot save a file without dart:io or dart:html.');
  }

  @override
  Future<String> readFromFile(dynamic pathOrUploadInput) {
    throw UnsupportedError('Cannot read a file without dart:io or dart:html.');
  }

  @override
  Stream<String> readFileAsStream(String pathOrUploadInput) {
    throw UnsupportedError('Cannot read a file without dart:io or dart:html.');
  }

  @override
  writeFileAsStream(pathOrData) {
    throw UnsupportedError('Cannot save a file without dart:io or dart:html.');
  }

  @override
  Future<List<int>> readBytesFromFile(dynamic pathOrUploadInput) {
    throw UnsupportedError('Cannot read a file without dart:io or dart:html.');
  }

  @override
  Future<void> writeBytesToFile(String path, List<int> bytes) {
    throw UnsupportedError('Cannot save a file without dart:io or dart:html.');
  }

  @override
  Future<bool> fileExists(String path) {
    throw UnsupportedError(
        'Cannot check file existence without dart:io or dart:html.');
  }

  @override
  Future<bool> deleteFile(String path) {
    throw UnsupportedError(
        'Cannot delete a file without dart:io or dart:html.');
  }
}
