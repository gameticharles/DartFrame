import 'dart:typed_data';
import 'byte_reader.dart';
import 'hdf5_error.dart';

/// Global heap for storing variable-length data
///
/// The global heap is used to store variable-length data such as:
/// - Variable-length strings
/// - Variable-length arrays
/// - Variable-length compound fields
///
/// Each global heap collection contains multiple objects that can be
/// referenced by their heap ID.
class GlobalHeap {
  final int address;
  final int version;
  final int collectionSize;
  final Map<int, GlobalHeapObject> objects = {};
  final ByteReader _reader;

  GlobalHeap._({
    required this.address,
    required this.version,
    required this.collectionSize,
    required ByteReader reader,
  }) : _reader = reader;

  /// Read a global heap collection from the file
  ///
  /// Parameters:
  /// - [reader]: ByteReader for file access
  /// - [address]: Address of the global heap collection
  /// - [filePath]: Optional file path for error reporting
  ///
  /// Returns a GlobalHeap instance.
  static Future<GlobalHeap> read(
    ByteReader reader,
    int address, {
    String? filePath,
  }) async {
    hdf5DebugLog(
        'Reading global heap at address 0x${address.toRadixString(16)}');

    reader.seek(address);

    // Read signature (4 bytes) - should be "GCOL"
    final signature = await reader.readBytes(4);
    final signatureStr = String.fromCharCodes(signature);
    if (signatureStr != 'GCOL') {
      throw CorruptedFileError(
        filePath: filePath,
        reason: 'Invalid global heap signature',
        details: 'Expected "GCOL", got "$signatureStr"',
      );
    }

    // Read version (1 byte)
    final version = await reader.readUint8();
    if (version != 1) {
      throw UnsupportedVersionError(
        filePath: filePath,
        component: 'global heap',
        version: version,
      );
    }

    // Reserved bytes (3 bytes)
    await reader.readBytes(3);

    // Collection size (8 bytes) - size of entire collection including header
    final collectionSize = (await reader.readUint64()).toInt();

    hdf5DebugLog('Global heap: version=$version, size=$collectionSize');

    final heap = GlobalHeap._(
      address: address,
      version: version,
      collectionSize: collectionSize,
      reader: reader,
    );

    // Read all objects in the collection
    await heap._readObjects(filePath);

    return heap;
  }

  /// Read all objects in the global heap collection
  Future<void> _readObjects(String? filePath) async {
    // Objects start at offset 16 (after header)
    final objectsStart = address + 16;
    int currentPos = objectsStart;
    final collectionEnd = address + collectionSize;

    while (currentPos < collectionEnd - 16) {
      // Need at least 16 bytes for object header
      _reader.seek(currentPos);

      // Read object header
      // Heap object index (2 bytes)
      final heapObjectIndex = await _reader.readUint16();

      // Reference count (2 bytes) - not used for reading
      await _reader.readUint16();

      // Reserved (4 bytes)
      await _reader.readBytes(4);

      // Object size (8 bytes)
      final objectSize = (await _reader.readUint64()).toInt();

      hdf5DebugLog(
          'Global heap object: index=$heapObjectIndex, size=$objectSize');

      // Check for end marker (index 0, size 0)
      if (heapObjectIndex == 0 && objectSize == 0) {
        hdf5DebugLog('Reached end of global heap objects');
        break;
      }

      // Read object data
      final objectData = await _reader.readBytes(objectSize);

      // Store object
      objects[heapObjectIndex] = GlobalHeapObject(
        index: heapObjectIndex,
        size: objectSize,
        data: Uint8List.fromList(objectData),
      );

      // Move to next object (16 byte header + data, aligned to 8 bytes)
      final totalSize = 16 + objectSize;
      final alignedSize = (totalSize + 7) & ~7; // Round up to multiple of 8
      currentPos += alignedSize;
    }

    hdf5DebugLog('Loaded ${objects.length} objects from global heap');
  }

  /// Get an object from the global heap by its index
  ///
  /// Parameters:
  /// - [index]: The heap object index
  ///
  /// Returns the GlobalHeapObject if found, null otherwise.
  GlobalHeapObject? getObject(int index) {
    return objects[index];
  }

  /// Read data from a global heap object
  ///
  /// Parameters:
  /// - [index]: The heap object index
  ///
  /// Returns the object data as Uint8List.
  ///
  /// Throws [Hdf5Error] if the object is not found.
  Uint8List readData(int index) {
    final obj = objects[index];
    if (obj == null) {
      throw DataReadError(
        reason: 'Global heap object not found',
        details: 'Heap object index $index not found in collection',
      );
    }
    return obj.data;
  }

  @override
  String toString() =>
      'GlobalHeap(address=0x${address.toRadixString(16)}, objects=${objects.length})';
}

/// A single object stored in a global heap collection
class GlobalHeapObject {
  final int index;
  final int size;
  final Uint8List data;

  GlobalHeapObject({
    required this.index,
    required this.size,
    required this.data,
  });

  @override
  String toString() => 'GlobalHeapObject(index=$index, size=$size bytes)';
}

/// Variable-length data reference
///
/// This structure is used to reference data stored in the global heap.
/// It's typically 16 bytes:
/// - 4 bytes: length of the data
/// - 4 bytes: global heap collection address (lower 32 bits)
/// - 4 bytes: global heap collection address (upper 32 bits)
/// - 4 bytes: object index within the collection
class VlenReference {
  final int length;
  final int heapAddress;
  final int objectIndex;

  VlenReference({
    required this.length,
    required this.heapAddress,
    required this.objectIndex,
  });

  /// Parse a variable-length reference from bytes
  ///
  /// The reference format (HDF5 spec III.H):
  /// - 4 bytes: length of sequence
  /// - 4 bytes: global heap collection address (lower 32 bits)
  /// - 4 bytes: global heap collection address (upper 32 bits)
  /// - 4 bytes: object index within collection
  ///
  /// Note: In practice, for files < 4GB, the upper 32 bits are often 0
  static VlenReference fromBytes(List<int> bytes) {
    if (bytes.length < 16) {
      throw ArgumentError(
          'VlenReference requires at least 16 bytes, got ${bytes.length}');
    }

    final buffer = ByteData.view(Uint8List.fromList(bytes).buffer);

    // Read length (4 bytes)
    final length = buffer.getUint32(0, Endian.little);

    // Read heap address as two 32-bit values
    final heapAddrLow = buffer.getUint32(4, Endian.little);
    final heapAddrHigh = buffer.getUint32(8, Endian.little);
    final heapAddress = heapAddrLow | (heapAddrHigh << 32);

    // Read object index (4 bytes)
    final objectIndex = buffer.getUint32(12, Endian.little);

    return VlenReference(
      length: length,
      heapAddress: heapAddress,
      objectIndex: objectIndex,
    );
  }

  @override
  String toString() =>
      'VlenReference(length=$length, heap=0x${heapAddress.toRadixString(16)}, index=$objectIndex)';
}
