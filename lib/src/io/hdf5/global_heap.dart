import 'dart:typed_data';
import 'byte_reader.dart';
import 'byte_writer.dart';
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

/// Writer for HDF5 global heap collections
///
/// The global heap writer manages allocation and writing of variable-length
/// data objects. It maintains a collection of objects with unique IDs and
/// writes them in the HDF5 global heap collection format.
///
/// Example usage:
/// ```dart
/// final heapWriter = GlobalHeapWriter();
///
/// // Allocate objects in the heap
/// final id1 = heapWriter.allocate(utf8.encode('Hello'));
/// final id2 = heapWriter.allocate(utf8.encode('World'));
///
/// // Write the collection to a file at a specific address
/// final bytes = heapWriter.writeCollection(1024);
/// ```
class GlobalHeapWriter {
  final Map<int, List<int>> _objects = {};
  int _nextId = 1;
  final Endian _endian;

  /// Create a new global heap writer
  ///
  /// Parameters:
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = GlobalHeapWriter();
  /// ```
  GlobalHeapWriter({Endian endian = Endian.little}) : _endian = endian;

  /// Allocate space for data in the global heap
  ///
  /// This method stores the data and returns a unique heap ID that can be
  /// used to reference the data from datasets or attributes.
  ///
  /// Parameters:
  /// - [data]: The data bytes to store in the heap
  ///
  /// Returns the heap object ID (index) for this data.
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = GlobalHeapWriter();
  /// final stringData = utf8.encode('Variable-length string');
  /// final heapId = heapWriter.allocate(stringData);
  /// ```
  int allocate(List<int> data) {
    final id = _nextId++;
    _objects[id] = List<int>.from(data);
    return id;
  }

  /// Get the number of objects currently allocated
  int get objectCount => _objects.length;

  /// Get the total size of all object data (not including headers)
  int get totalDataSize {
    return _objects.values.fold(0, (sum, data) => sum + data.length);
  }

  /// Calculate the total collection size including header and all objects
  ///
  /// The collection size includes:
  /// - 16 bytes for the collection header
  /// - For each object: 16 bytes header + data size (aligned to 8 bytes)
  /// - 16 bytes for the end marker
  int calculateCollectionSize() {
    int size = 16; // Collection header

    // Add size for each object (header + data, aligned to 8 bytes)
    for (final data in _objects.values) {
      final objectSize = 16 + data.length; // Header + data
      final alignedSize = (objectSize + 7) & ~7; // Round up to multiple of 8
      size += alignedSize;
    }

    // Add size for end marker
    size += 16;

    return size;
  }

  /// Write the global heap collection
  ///
  /// This method writes the complete global heap collection in HDF5 format:
  /// - Collection header with "GCOL" signature
  /// - All allocated objects with their headers
  /// - End marker
  ///
  /// Parameters:
  /// - [address]: The file address where this collection will be written
  ///
  /// Returns the bytes for the complete global heap collection.
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = GlobalHeapWriter();
  /// heapWriter.allocate(utf8.encode('Data 1'));
  /// heapWriter.allocate(utf8.encode('Data 2'));
  ///
  /// final collectionBytes = heapWriter.writeCollection(2048);
  /// // Write collectionBytes to file at address 2048
  /// ```
  List<int> writeCollection(int address) {
    final writer = ByteWriter(endian: _endian);

    // Calculate total collection size
    final collectionSize = calculateCollectionSize();

    // Write collection header
    _writeCollectionHeader(writer, collectionSize);

    // Write all objects
    for (final entry in _objects.entries) {
      _writeObject(writer, entry.key, entry.value);
    }

    // Write end marker (index 0, reference count 0, size 0)
    _writeEndMarker(writer);

    return writer.bytes;
  }

  /// Write the global heap collection header
  ///
  /// Format:
  /// - 4 bytes: Signature "GCOL"
  /// - 1 byte: Version (1)
  /// - 3 bytes: Reserved (zeros)
  /// - 8 bytes: Collection size
  void _writeCollectionHeader(ByteWriter writer, int collectionSize) {
    // Write signature "GCOL"
    writer.writeBytes([0x47, 0x43, 0x4F, 0x4C]); // "GCOL" in ASCII

    // Write version (1)
    writer.writeUint8(1);

    // Write reserved bytes (3 bytes of zeros)
    writer.writeUint8(0);
    writer.writeUint8(0);
    writer.writeUint8(0);

    // Write collection size (8 bytes)
    writer.writeUint64(collectionSize);
  }

  /// Write a single global heap object
  ///
  /// Format:
  /// - 2 bytes: Heap object index
  /// - 2 bytes: Reference count (set to 1)
  /// - 4 bytes: Reserved (zeros)
  /// - 8 bytes: Object size
  /// - N bytes: Object data
  /// - Padding to align to 8-byte boundary
  void _writeObject(ByteWriter writer, int index, List<int> data) {
    // Write heap object index (2 bytes)
    writer.writeUint16(index);

    // Write reference count (2 bytes) - set to 1
    writer.writeUint16(1);

    // Write reserved bytes (4 bytes of zeros)
    writer.writeUint32(0);

    // Write object size (8 bytes)
    writer.writeUint64(data.length);

    // Write object data
    writer.writeBytes(data);

    // Align to 8-byte boundary
    writer.alignTo(8);
  }

  /// Write the end marker for the global heap collection
  ///
  /// The end marker is a special object with index 0 and size 0
  /// that indicates the end of the object list.
  void _writeEndMarker(ByteWriter writer) {
    // Write heap object index 0 (2 bytes)
    writer.writeUint16(0);

    // Write reference count 0 (2 bytes)
    writer.writeUint16(0);

    // Write reserved bytes (4 bytes of zeros)
    writer.writeUint32(0);

    // Write object size 0 (8 bytes)
    writer.writeUint64(0);
  }

  /// Create a variable-length reference to an object in this heap
  ///
  /// This creates a 16-byte reference structure that can be embedded in
  /// datasets or attributes to point to variable-length data in the heap.
  ///
  /// Parameters:
  /// - [objectId]: The heap object ID returned by allocate()
  /// - [heapAddress]: The file address where this heap collection is written
  ///
  /// Returns a 16-byte reference structure.
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = GlobalHeapWriter();
  /// final objectId = heapWriter.allocate(utf8.encode('Data'));
  /// final heapAddress = 2048;
  ///
  /// // Write heap collection at address 2048
  /// final collectionBytes = heapWriter.writeCollection(heapAddress);
  ///
  /// // Create reference to the object
  /// final reference = heapWriter.createReference(objectId, heapAddress);
  /// // Use reference in dataset or attribute
  /// ```
  List<int> createReference(int objectId, int heapAddress) {
    if (!_objects.containsKey(objectId)) {
      throw ArgumentError('Object ID $objectId not found in heap');
    }

    final data = _objects[objectId]!;
    final writer = ByteWriter(endian: _endian);

    // Write length (4 bytes)
    writer.writeUint32(data.length);

    // Write heap address as two 32-bit values (8 bytes total)
    final heapAddrLow = heapAddress & 0xFFFFFFFF;
    final heapAddrHigh = (heapAddress >> 32) & 0xFFFFFFFF;
    writer.writeUint32(heapAddrLow);
    writer.writeUint32(heapAddrHigh);

    // Write object index (4 bytes)
    writer.writeUint32(objectId);

    return writer.bytes;
  }

  /// Clear all allocated objects
  ///
  /// This resets the heap writer to its initial state, removing all
  /// allocated objects and resetting the ID counter.
  void clear() {
    _objects.clear();
    _nextId = 1;
  }

  @override
  String toString() =>
      'GlobalHeapWriter(objects=${_objects.length}, totalSize=${calculateCollectionSize()})';
}
