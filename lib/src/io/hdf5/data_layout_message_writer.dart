import 'dart:typed_data';
import 'byte_writer.dart';

/// Writer for HDF5 data layout messages
///
/// This class generates HDF5 data layout messages following the HDF5 format
/// specification version 3. Currently supports contiguous storage layout only.
class DataLayoutMessageWriter {
  /// Write a contiguous data layout message
  ///
  /// Returns the message bytes following HDF5 data layout message format version 3:
  /// - Version (1 byte): 3
  /// - Layout class (1 byte): 1 (contiguous)
  /// - Data address (8 bytes): address where data is stored
  /// - Data size (8 bytes): size of data in bytes
  ///
  /// Parameters:
  /// - [dataAddress]: The file offset where the raw data is stored
  /// - [dataSize]: The total size of the raw data in bytes
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// // Contiguous layout for data at offset 1024, size 8000 bytes
  /// final msg = writer.writeContiguous(
  ///   dataAddress: 1024,
  ///   dataSize: 8000,
  /// );
  /// ```
  List<int> writeContiguous({
    required int dataAddress,
    required int dataSize,
    Endian endian = Endian.little,
  }) {
    if (dataAddress < 0) {
      throw ArgumentError('dataAddress must be non-negative');
    }

    if (dataSize < 0) {
      throw ArgumentError('dataSize must be non-negative');
    }

    final writer = ByteWriter(endian: endian);

    // Version 3
    writer.writeUint8(3);

    // Layout class: 1 = contiguous
    writer.writeUint8(1);

    // Data address (8 bytes)
    writer.writeUint64(dataAddress);

    // Data size (8 bytes)
    writer.writeUint64(dataSize);

    return writer.bytes;
  }
}
