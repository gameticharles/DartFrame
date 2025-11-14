import 'dart:typed_data';
import 'byte_reader.dart';
import 'hdf5_error.dart';

/// Local heap for storing variable-length data
class LocalHeap {
  final int address;
  final int version;
  final int dataSegmentSize;
  final int dataSegmentAddress;
  final ByteReader _reader;

  LocalHeap._({
    required this.address,
    required this.version,
    required this.dataSegmentSize,
    required this.dataSegmentAddress,
    required ByteReader reader,
  }) : _reader = reader;

  /// Read a local heap from the file
  static Future<LocalHeap> read(ByteReader reader, int address,
      {String? filePath}) async {
    hdf5DebugLog(
        'Reading local heap at address 0x${address.toRadixString(16)}');
    reader.seek(address);

    // Read signature
    final signature = await reader.readBytes(4);
    final signatureStr = String.fromCharCodes(signature);
    // HEAP is the old format, GCOL is the new format (Global Collection)
    if (signatureStr != 'HEAP' && signatureStr != 'GCOL') {
      throw CorruptedFileError(
        filePath: filePath,
        reason: 'Invalid local heap signature',
        details: 'Expected "HEAP" or "GCOL", got "$signatureStr"',
      );
    }

    // Read version
    final version = await reader.readUint8();
    if (version != 0 && version != 1) {
      throw UnsupportedVersionError(
        filePath: filePath,
        component: 'local heap',
        version: version,
      );
    }

    // Reserved bytes
    await reader.readBytes(3);

    // Read heap metadata
    final dataSegmentSize = await reader.readUint64();
    await reader.readUint64(); // offsetToHeadOfFreeList (unused)

    // For GCOL format (version 1), there's no data address field
    // The data starts immediately after the free list offset (24 bytes from start)
    // For HEAP format (version 0), there's a data address field
    final int actualDataSegmentAddress;
    if (signatureStr == 'GCOL' && version == 1) {
      // Data starts at current position (24 bytes from heap start)
      actualDataSegmentAddress = address + 24;
    } else {
      // Read data address field
      final dataSegmentAddress = await reader.readUint64();
      actualDataSegmentAddress = dataSegmentAddress;
    }

    hdf5DebugLog('Local heap: dataSegmentSize=$dataSegmentSize, '
        'dataSegmentAddress=0x${actualDataSegmentAddress.toRadixString(16)}');

    return LocalHeap._(
      address: address,
      version: version,
      dataSegmentSize: dataSegmentSize,
      dataSegmentAddress: actualDataSegmentAddress,
      reader: reader,
    );
  }

  /// Read data from the heap at the given offset
  Future<Uint8List> readData(int offset, int length) async {
    final absoluteAddress = dataSegmentAddress + offset;
    hdf5DebugLog('Reading $length bytes from heap at offset $offset '
        '(absolute address: 0x${absoluteAddress.toRadixString(16)})');

    _reader.seek(absoluteAddress);
    return Uint8List.fromList(await _reader.readBytes(length));
  }

  /// Read a null-terminated string from the heap at the given offset
  Future<String> readString(int offset) async {
    final absoluteAddress = dataSegmentAddress + offset;
    _reader.seek(absoluteAddress);

    // Read bytes until we hit a null terminator
    final bytes = <int>[];
    while (true) {
      final byte = await _reader.readUint8();
      if (byte == 0) break;
      bytes.add(byte);
      if (bytes.length > 10000) {
        // Safety check to prevent infinite loops
        throw Exception('String too long or missing null terminator');
      }
    }

    return String.fromCharCodes(bytes);
  }
}
