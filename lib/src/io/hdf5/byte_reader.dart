import 'dart:typed_data';
import '../../file_helper/file_io.dart';

/// Efficient byte reader for HDF5 files with random access support
class ByteReader {
  final RandomAccessFileBase? _file;
  final Uint8List? _bytes;
  final Endian endian;
  int _position = 0;

  ByteReader(RandomAccessFileBase file, {this.endian = Endian.little})
      : _file = file,
        _bytes = null;

  ByteReader.fromBytes(Uint8List bytes, {this.endian = Endian.little})
      : _file = null,
        _bytes = bytes;

  /// Creates a ByteReader from a file path
  ///
  /// This is a convenience factory that opens the file using FileIO
  /// and creates a ByteReader from it.
  ///
  /// Example:
  /// ```dart
  /// final reader = await ByteReader.open('data.h5');
  /// // ... use reader
  /// ```
  static Future<ByteReader> open(String filePath,
      {Endian endian = Endian.little}) async {
    final fileIO = FileIO();
    final raf = await fileIO.openRandomAccess(filePath);
    return ByteReader(raf, endian: endian);
  }

  Future<Uint8List> _readRaw(int length) async {
    if (_file != null) {
      await _file.setPosition(_position);
      _position += length;
      return Uint8List.fromList(await _file.read(length));
    } else if (_bytes != null) {
      final result = _bytes.sublist(_position, _position + length);
      _position += length;
      return result;
    }
    throw Exception('ByteReader not initialized');
  }

  Future<int> readUint8() async {
    final bytes = await _readRaw(1);
    return bytes[0] & 0xFF;
  }

  Future<int> readUint16() async {
    final bytes = await _readRaw(2);
    return ByteData.sublistView(bytes).getUint16(0, endian);
  }

  Future<int> readUint32() async {
    final bytes = await _readRaw(4);
    return ByteData.sublistView(bytes).getUint32(0, endian);
  }

  Future<int> readUint64() async {
    final bytes = await _readRaw(8);
    return ByteData.sublistView(bytes).getUint64(0, endian);
  }

  Future<int> readInt8() async {
    final bytes = await _readRaw(1);
    return ByteData.sublistView(bytes).getInt8(0);
  }

  Future<int> readInt16() async {
    final bytes = await _readRaw(2);
    return ByteData.sublistView(bytes).getInt16(0, endian);
  }

  Future<int> readInt32() async {
    final bytes = await _readRaw(4);
    return ByteData.sublistView(bytes).getInt32(0, endian);
  }

  Future<int> readInt64() async {
    final bytes = await _readRaw(8);
    return ByteData.sublistView(bytes).getInt64(0, endian);
  }

  Future<double> readFloat32() async {
    final bytes = await _readRaw(4);
    return ByteData.sublistView(bytes).getFloat32(0, endian);
  }

  Future<double> readFloat64() async {
    final bytes = await _readRaw(8);
    return ByteData.sublistView(bytes).getFloat64(0, endian);
  }

  Future<Uint8List> readBytes(int length) async {
    return await _readRaw(length);
  }

  void seek(int position) {
    _position = position;
  }

  int get position => _position;

  int get length {
    if (_bytes != null) {
      return _bytes.length;
    }
    // For file-based readers, we don't know the length without seeking to end
    // Return a large value to avoid issues
    return 0x7FFFFFFF;
  }

  int get remainingBytes {
    if (_bytes != null) {
      return _bytes.length - _position;
    }
    // For file-based readers, assume unlimited
    return 0x7FFFFFFF;
  }
}
