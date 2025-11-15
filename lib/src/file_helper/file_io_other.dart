import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'file_io.dart';

class FileIO implements FileIOBase {
  Future<void> _saveToFileDesktop(String path, String data) async {
    var file = File(path);
    await file.writeAsString(data);
  }

  Future<String> _readFromFileDesktop(String path) async {
    var file = File(path);
    if (await file.exists()) {
      var contents = await file.readAsString();
      return contents;
    } else {
      throw Exception('File does not exist');
    }
  }

  Stream<String> _readFromFileDesktopAsStream(String path) async* {
    var file = File(path);
    if (await file.exists()) {
      var lines =
          file.openRead().transform(utf8.decoder).transform(LineSplitter());
      await for (var line in lines) {
        yield line;
      }
    } else {
      throw Exception('File does not exist');
    }
  }

  IOSink _writeToFileDesktopAsStream(String path) {
    var file = File(path);
    var sink = file.openWrite();
    return sink;
  }

  @override
  IOSink writeFileAsStream(dynamic path) {
    return _writeToFileDesktopAsStream(path);
  }

  @override
  Stream<String> readFileAsStream(String path) {
    return _readFromFileDesktopAsStream(path);
  }

  @override
  Future<void> saveToFile(String path, String data) async {
    await _saveToFileDesktop(path, data);
  }

  @override
  Future<String> readFromFile(dynamic path) async {
    return await _readFromFileDesktop(path);
  }

  @override
  Future<List<int>> readBytesFromFile(dynamic path) async {
    var file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    } else {
      throw Exception('File does not exist: $path');
    }
  }

  @override
  Future<void> writeBytesToFile(String path, List<int> bytes) async {
    var file = File(path);
    await file.writeAsBytes(bytes);
  }

  @override
  Future<bool> fileExists(String path) async {
    var file = File(path);
    return await file.exists();
  }

  @override
  bool fileExistsSync(String path) {
    var file = File(path);
    return file.existsSync();
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      var file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      // Return false if deletion fails
      return false;
    }
  }

  @override
  Future<RandomAccessFileBase> openRandomAccess(dynamic path) async {
    var file = File(path);
    var raf = await file.open();
    return _RandomAccessFileWrapper(raf);
  }

  @override
  String getParentPath(String path) {
    var file = File(path);
    return file.parent.path;
  }

  @override
  String resolvePath(String basePath, String relativePath) {
    // Use dart:io's path resolution
    var baseDir = File(basePath).parent;
    var resolved = File('${baseDir.path}/$relativePath');
    return resolved.path;
  }
}

/// Wrapper for dart:io RandomAccessFile to implement RandomAccessFileBase
class _RandomAccessFileWrapper implements RandomAccessFileBase {
  final RandomAccessFile _raf;
  int _position = 0;

  _RandomAccessFileWrapper(this._raf);

  @override
  int get position => _position;

  @override
  Future<void> setPosition(int position) async {
    await _raf.setPosition(position);
    _position = position;
  }

  @override
  Future<List<int>> read(int bytes) async {
    final data = await _raf.read(bytes);
    _position += data.length;
    return data;
  }

  @override
  Future<int> length() async {
    return await _raf.length();
  }

  @override
  Future<void> close() async {
    await _raf.close();
  }
}
