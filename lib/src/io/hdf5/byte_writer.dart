import 'dart:typed_data';

/// Efficient byte writer for HDF5 files with endianness support
///
/// This class provides low-level byte writing operations for constructing
/// HDF5 files. It supports writing primitive types with configurable
/// endianness, alignment padding, and position tracking.
class ByteWriter {
  final List<int> _buffer;
  final Endian endian;

  ByteWriter({this.endian = Endian.little}) : _buffer = [];

  /// Current write position in the buffer
  int get position => _buffer.length;

  /// Get a copy of the buffer contents
  List<int> get bytes => List<int>.from(_buffer);

  /// Get the buffer as a Uint8List
  Uint8List get uint8List => Uint8List.fromList(_buffer);

  /// Write a single unsigned 8-bit integer
  void writeUint8(int value) {
    _buffer.add(value & 0xFF);
  }

  /// Write an unsigned 16-bit integer
  void writeUint16(int value) {
    final byteData = ByteData(2);
    byteData.setUint16(0, value, endian);
    _buffer.addAll(byteData.buffer.asUint8List());
  }

  /// Write an unsigned 32-bit integer
  void writeUint32(int value) {
    final byteData = ByteData(4);
    byteData.setUint32(0, value, endian);
    _buffer.addAll(byteData.buffer.asUint8List());
  }

  /// Write an unsigned 64-bit integer
  void writeUint64(int value) {
    final byteData = ByteData(8);
    byteData.setUint64(0, value, endian);
    _buffer.addAll(byteData.buffer.asUint8List());
  }

  /// Write a signed 8-bit integer
  void writeInt8(int value) {
    final byteData = ByteData(1);
    byteData.setInt8(0, value);
    _buffer.add(byteData.getUint8(0));
  }

  /// Write a signed 16-bit integer
  void writeInt16(int value) {
    final byteData = ByteData(2);
    byteData.setInt16(0, value, endian);
    _buffer.addAll(byteData.buffer.asUint8List());
  }

  /// Write a signed 32-bit integer
  void writeInt32(int value) {
    final byteData = ByteData(4);
    byteData.setInt32(0, value, endian);
    _buffer.addAll(byteData.buffer.asUint8List());
  }

  /// Write a signed 64-bit integer
  void writeInt64(int value) {
    final byteData = ByteData(8);
    byteData.setInt64(0, value, endian);
    _buffer.addAll(byteData.buffer.asUint8List());
  }

  /// Write a 32-bit floating point number
  void writeFloat32(double value) {
    final byteData = ByteData(4);
    byteData.setFloat32(0, value, endian);
    _buffer.addAll(byteData.buffer.asUint8List());
  }

  /// Write a 64-bit floating point number
  void writeFloat64(double value) {
    final byteData = ByteData(8);
    byteData.setFloat64(0, value, endian);
    _buffer.addAll(byteData.buffer.asUint8List());
  }

  /// Write raw bytes to the buffer
  void writeBytes(List<int> bytes) {
    _buffer.addAll(bytes);
  }

  /// Write a string with optional null termination
  ///
  /// If [nullTerminate] is true, a null byte (0x00) is appended after the string.
  void writeString(String str, {bool nullTerminate = true}) {
    final bytes = str.codeUnits;
    _buffer.addAll(bytes);
    if (nullTerminate) {
      _buffer.add(0);
    }
  }

  /// Align the buffer to the specified boundary by adding padding bytes
  ///
  /// Adds zero bytes until the buffer length is a multiple of [boundary].
  /// For example, alignTo(8) ensures the buffer length is a multiple of 8.
  void alignTo(int boundary) {
    if (boundary <= 0) {
      throw ArgumentError('Boundary must be positive');
    }
    final remainder = _buffer.length % boundary;
    if (remainder != 0) {
      final padding = boundary - remainder;
      _buffer.addAll(List<int>.filled(padding, 0));
    }
  }

  /// Write bytes at a specific position in the buffer
  ///
  /// This allows updating previously written data. The position must be
  /// within the current buffer bounds, and there must be enough space
  /// for the bytes being written.
  void writeAt(int position, List<int> bytes) {
    if (position < 0 || position >= _buffer.length) {
      throw RangeError(
          'Position $position is out of bounds (0-${_buffer.length - 1})');
    }
    if (position + bytes.length > _buffer.length) {
      throw RangeError(
          'Cannot write ${bytes.length} bytes at position $position '
          '(would exceed buffer length ${_buffer.length})');
    }
    for (int i = 0; i < bytes.length; i++) {
      _buffer[position + i] = bytes[i];
    }
  }

  /// Clear the buffer
  void clear() {
    _buffer.clear();
  }

  /// Get the current buffer size in bytes
  int get size => _buffer.length;
}
