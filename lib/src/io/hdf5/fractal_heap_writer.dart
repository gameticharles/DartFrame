import 'dart:typed_data';
import 'byte_writer.dart';

/// Writer for HDF5 fractal heap structures
///
/// The fractal heap writer manages allocation and writing of variable-length
/// data for HDF5 version 2 groups and attributes. It provides efficient storage
/// with better performance than local heaps for large collections.
///
/// The fractal heap supports:
/// - Managed objects in direct blocks
/// - Indirect blocks for large heaps
/// - Configurable block sizes
/// - Checksums for data integrity
///
/// Example usage:
/// ```dart
/// final heapWriter = FractalHeapWriter(
///   startingBlockSize: 4096,
///   maxDirectBlockSize: 65536,
///   tableWidth: 4,
/// );
///
/// // Allocate objects in the heap
/// final heapId1 = heapWriter.allocate(utf8.encode('object1'));
/// final heapId2 = heapWriter.allocate(utf8.encode('object2'));
///
/// // Write the heap to a file at a specific address
/// final bytes = heapWriter.write(1024);
/// ```
class FractalHeapWriter {
  final int startingBlockSize;
  final int maxDirectBlockSize;
  final int tableWidth;
  final Endian _endian;

  // Heap configuration
  final int heapIdLength;
  final int maxSizeOfManagedObjects;

  // Object storage
  final List<_ManagedObject> _objects = [];
  final List<_DirectBlock> _blocks = [];

  // Statistics
  int _nextObjectOffset = 0;

  /// Create a new fractal heap writer
  ///
  /// Parameters:
  /// - [startingBlockSize]: Initial size of direct blocks (default: 4096)
  /// - [maxDirectBlockSize]: Maximum size of direct blocks (default: 65536)
  /// - [tableWidth]: Width of the indirect block table (default: 4)
  /// - [heapIdLength]: Length of heap IDs in bytes (default: 8)
  /// - [maxSizeOfManagedObjects]: Maximum size for managed objects (default: 65536)
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = FractalHeapWriter(
  ///   startingBlockSize: 4096,
  ///   maxDirectBlockSize: 65536,
  /// );
  /// ```
  FractalHeapWriter({
    this.startingBlockSize = 4096,
    this.maxDirectBlockSize = 65536,
    this.tableWidth = 4,
    this.heapIdLength = 8,
    this.maxSizeOfManagedObjects = 65536,
    Endian endian = Endian.little,
  }) : _endian = endian {
    // Validate configuration
    if (startingBlockSize <= 0 ||
        (startingBlockSize & (startingBlockSize - 1)) != 0) {
      throw ArgumentError('startingBlockSize must be a power of 2');
    }
    if (maxDirectBlockSize < startingBlockSize) {
      throw ArgumentError('maxDirectBlockSize must be >= startingBlockSize');
    }
    if (tableWidth <= 0) {
      throw ArgumentError('tableWidth must be positive');
    }
  }

  /// Allocate space for data in the fractal heap
  ///
  /// This method stores the data and returns a heap ID that can be used to
  /// reference the data from groups, attributes, or other structures.
  ///
  /// The heap ID encodes:
  /// - Version (1 byte): Always 0
  /// - Type (1 byte): 0 for managed objects
  /// - Offset (variable): Offset within the heap
  ///
  /// Parameters:
  /// - [data]: The data bytes to store in the heap
  ///
  /// Returns a heap ID (as a list of bytes) for this data.
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = FractalHeapWriter();
  /// final nameData = utf8.encode('object_name');
  /// final heapId = heapWriter.allocate(nameData);
  /// ```
  List<int> allocate(List<int> data) {
    if (data.isEmpty) {
      throw ArgumentError('Cannot allocate empty data');
    }

    if (data.length > maxSizeOfManagedObjects) {
      throw ArgumentError(
        'Data size ${data.length} exceeds maxSizeOfManagedObjects $maxSizeOfManagedObjects',
      );
    }

    // Create managed object
    final obj = _ManagedObject(
      offset: _nextObjectOffset,
      data: List<int>.from(data),
    );

    _objects.add(obj);
    _nextObjectOffset += data.length;

    // Encode heap ID
    return _encodeHeapId(obj.offset, data.length);
  }

  /// Encode a heap ID with block index and offset
  ///
  /// Heap ID format (version 0, type 0 - managed object):
  /// - Byte 0: Version (0)
  /// - Byte 1: Type (0 = managed object)
  /// - Bytes 2-(heapIdLength-1): Offset within heap (variable length)
  ///
  /// For heapIdLength >= 12, additional bytes can encode object length.
  List<int> _encodeHeapId(int offset, int length) {
    final writer = ByteWriter(endian: _endian);

    // Version (1 byte)
    writer.writeUint8(0);

    // Type (1 byte): 0 = managed object in direct block
    writer.writeUint8(0);

    // For standard 8-byte heap ID: use 6 bytes for offset (enough for most cases)
    // For larger heap IDs: use more bytes for offset and optionally length
    if (heapIdLength == 8) {
      // 6 bytes for offset (supports up to 256TB)
      final offsetBytes = ByteData(8);
      offsetBytes.setUint64(0, offset, _endian);
      writer.writeBytes(offsetBytes.buffer.asUint8List().sublist(0, 6));
    } else if (heapIdLength >= 12) {
      // 8 bytes for offset
      writer.writeUint64(offset);
      // 2 bytes for length
      writer.writeUint16(length);
    } else {
      // Variable length offset field
      final offsetFieldSize = heapIdLength - 2;
      final offsetBytes = ByteData(8);
      offsetBytes.setUint64(0, offset, _endian);
      writer.writeBytes(
          offsetBytes.buffer.asUint8List().sublist(0, offsetFieldSize));
    }

    // Pad to heapIdLength if needed
    while (writer.bytes.length < heapIdLength) {
      writer.writeUint8(0);
    }

    return writer.bytes.sublist(0, heapIdLength);
  }

  /// Get the number of objects currently allocated
  int get objectCount => _objects.length;

  /// Get the total size of all object data
  int get totalDataSize {
    return _objects.fold(0, (sum, obj) => sum + obj.data.length);
  }

  /// Calculate the number of direct blocks needed
  int get blockCount {
    if (_objects.isEmpty) return 1;

    int totalSize = totalDataSize;
    int blockSize = startingBlockSize;
    int blocks = 0;

    while (totalSize > 0) {
      blocks++;
      totalSize -= blockSize;
      if (blockSize < maxDirectBlockSize) {
        blockSize *= 2;
      }
    }

    return blocks.clamp(1, 1000); // Safety limit
  }

  /// Check if indirect blocks are needed
  bool get needsIndirectBlocks {
    return totalDataSize > maxDirectBlockSize;
  }

  /// Write the complete fractal heap
  ///
  /// This method writes:
  /// - Fractal heap header ("FRHP")
  /// - Direct blocks with object data ("FHDB")
  /// - Indirect blocks if needed (for large heaps)
  ///
  /// Parameters:
  /// - [address]: The file address where this heap will be written
  ///
  /// Returns the bytes for the complete fractal heap.
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = FractalHeapWriter();
  /// heapWriter.allocate(utf8.encode('name1'));
  /// heapWriter.allocate(utf8.encode('name2'));
  ///
  /// final heapBytes = heapWriter.write(2048);
  /// // Write heapBytes to file at address 2048
  /// ```
  List<int> write(int address) {
    // Organize objects into direct blocks
    _organizeIntoBlocks();

    final writer = ByteWriter(endian: _endian);

    // Calculate addresses
    final headerAddress = address;
    final headerSize = _calculateHeaderSize();

    // Check if we need indirect blocks
    if (needsIndirectBlocks) {
      // Write with indirect block structure
      return _writeWithIndirectBlocks(writer, headerAddress, headerSize);
    } else {
      // Simple case: direct blocks only
      final rootBlockAddress = headerAddress + headerSize;

      // Write header
      _writeHeader(writer, rootBlockAddress);

      // Write direct blocks
      for (int i = 0; i < _blocks.length; i++) {
        final blockAddress = rootBlockAddress + _calculateBlockOffset(i);
        _writeDirectBlock(writer, _blocks[i], headerAddress, blockAddress);
      }

      return writer.bytes;
    }
  }

  /// Write fractal heap with indirect block structure for large heaps
  List<int> _writeWithIndirectBlocks(
    ByteWriter writer,
    int headerAddress,
    int headerSize,
  ) {
    // For large heaps, we need an indirect block structure
    // The indirect block contains pointers to direct blocks

    // Calculate addresses
    final indirectBlockAddress = headerAddress + headerSize;
    final indirectBlockSize = _calculateIndirectBlockSize();
    final firstDirectBlockAddress = indirectBlockAddress + indirectBlockSize;

    // Write header (pointing to indirect block as root)
    _writeHeader(writer, indirectBlockAddress);

    // Write indirect block
    _writeIndirectBlock(writer, headerAddress, firstDirectBlockAddress);

    // Write direct blocks
    int currentAddress = firstDirectBlockAddress;
    for (final block in _blocks) {
      _writeDirectBlock(writer, block, headerAddress, currentAddress);
      currentAddress += _calculateDirectBlockSize(block);
    }

    return writer.bytes;
  }

  /// Calculate the size of an indirect block
  int _calculateIndirectBlockSize() {
    // Indirect block header:
    // signature(4) + version(1) + heapHeaderAddress(8) + blockOffset(8) +
    // numRows(2) + pointers(8 * numPointers) + checksum(4)

    // Number of pointers = tableWidth * numRows
    final numRows = _calculateCurrentRows() + 1;
    final numPointers = tableWidth * numRows;

    return 4 + 1 + 8 + 8 + 2 + (8 * numPointers) + 4;
  }

  /// Write an indirect block ("FHIB")
  void _writeIndirectBlock(
    ByteWriter writer,
    int heapHeaderAddress,
    int firstDirectBlockAddress,
  ) {
    final blockStart = writer.position;

    // Signature "FHIB"
    writer.writeString('FHIB', nullTerminate: false);

    // Version (0)
    writer.writeUint8(0);

    // Heap header address (8 bytes)
    writer.writeUint64(heapHeaderAddress);

    // Block offset (8 bytes) - offset of first block in this indirect block
    writer.writeUint64(0);

    // Number of rows (2 bytes)
    final numRows = _calculateCurrentRows() + 1;
    writer.writeUint16(numRows);

    // Write pointers to direct blocks
    int currentAddress = firstDirectBlockAddress;
    int blockIndex = 0;

    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < tableWidth; col++) {
        if (blockIndex < _blocks.length) {
          // Write pointer to direct block
          writer.writeUint64(currentAddress);
          currentAddress += _calculateDirectBlockSize(_blocks[blockIndex]);
          blockIndex++;
        } else {
          // Write undefined address for unused slots
          writer.writeUint64(0xFFFFFFFFFFFFFFFF);
        }
      }
    }

    // Calculate and write checksum
    final blockBytes = writer.bytes.sublist(blockStart);
    final checksum = _calculateChecksum(blockBytes);
    writer.writeUint32(checksum);
  }

  /// Organize objects into direct blocks
  void _organizeIntoBlocks() {
    _blocks.clear();

    if (_objects.isEmpty) {
      // Create empty block
      _blocks.add(_DirectBlock(
        blockSize: startingBlockSize,
        objects: [],
      ));
      return;
    }

    int currentBlockSize = startingBlockSize;
    List<_ManagedObject> currentBlockObjects = [];
    int currentBlockDataSize = 0;

    for (final obj in _objects) {
      // Check if object fits in current block
      if (currentBlockDataSize + obj.data.length > currentBlockSize) {
        // Finalize current block
        if (currentBlockObjects.isNotEmpty) {
          _blocks.add(_DirectBlock(
            blockSize: currentBlockSize,
            objects: List.from(currentBlockObjects),
          ));
        }

        // Start new block with larger size if possible
        currentBlockObjects = [];
        currentBlockDataSize = 0;
        if (currentBlockSize < maxDirectBlockSize) {
          currentBlockSize *= 2;
        }
      }

      currentBlockObjects.add(obj);
      currentBlockDataSize += obj.data.length;
    }

    // Add final block
    if (currentBlockObjects.isNotEmpty) {
      _blocks.add(_DirectBlock(
        blockSize: currentBlockSize,
        objects: currentBlockObjects,
      ));
    }
  }

  /// Calculate the size of the fractal heap header
  int _calculateHeaderSize() {
    // Base header size (without I/O filters)
    // Signature(4) + version(1) + heapIdLength(2) + ioFilterLength(2) +
    // flags(1) + maxSizeManaged(4) + nextHugeId(8) + btreeHuge(8) +
    // freeSpace(8) + freeSpaceMgr(8) + managedSpace(8) + allocatedSpace(8) +
    // directBlockIter(8) + numManaged(8) + sizeHuge(8) + numHuge(8) +
    // sizeTiny(8) + numTiny(8) + tableWidth(2) + startingBlockSize(8) +
    // maxDirectBlockSize(8) + maxHeapSize(2) + startingNumRows(2) +
    // rootBlockAddress(8) + currentNumRows(2) + checksum(4)
    return 4 +
        1 +
        2 +
        2 +
        1 +
        4 +
        8 +
        8 +
        8 +
        8 +
        8 +
        8 +
        8 +
        8 +
        8 +
        8 +
        8 +
        8 +
        2 +
        8 +
        8 +
        2 +
        2 +
        8 +
        2 +
        4;
  }

  /// Calculate the offset for a block
  int _calculateBlockOffset(int blockIndex) {
    int offset = 0;
    for (int i = 0; i < blockIndex; i++) {
      offset += _calculateDirectBlockSize(_blocks[i]);
    }
    return offset;
  }

  /// Calculate the total size of a direct block including header
  int _calculateDirectBlockSize(_DirectBlock block) {
    // Header: signature(4) + version(1) + heapHeaderAddress(8) + blockOffset(8) + checksum(4) = 25 bytes
    // Plus block data size
    return 25 + block.blockSize;
  }

  /// Write the fractal heap header ("FRHP")
  void _writeHeader(ByteWriter writer, int rootBlockAddress) {
    final headerStart = writer.position;

    // Signature "FRHP"
    writer.writeString('FRHP', nullTerminate: false);

    // Version (0)
    writer.writeUint8(0);

    // Heap ID length (2 bytes)
    writer.writeUint16(heapIdLength);

    // I/O filter encoded length (2 bytes) - 0 for no filters
    writer.writeUint16(0);

    // Flags (1 byte)
    // Bit 0: ID wrapped (0)
    // Bit 1: Direct blocks checksummed (1)
    final flags = 0x02; // Checksums enabled
    writer.writeUint8(flags);

    // Maximum size of managed objects (4 bytes)
    writer.writeUint32(maxSizeOfManagedObjects);

    // Next huge object ID (8 bytes)
    writer.writeUint64(0);

    // B-tree address of huge objects (8 bytes)
    writer.writeUint64(0xFFFFFFFFFFFFFFFF); // Undefined

    // Amount of free space in managed blocks (8 bytes)
    final freeSpace = _calculateFreeSpace();
    writer.writeUint64(freeSpace);

    // Address of managed block free space manager (8 bytes)
    writer.writeUint64(0xFFFFFFFFFFFFFFFF); // Undefined

    // Amount of managed space in heap (8 bytes)
    final managedSpace = _blocks.fold(0, (sum, block) => sum + block.blockSize);
    writer.writeUint64(managedSpace);

    // Amount of allocated managed space in heap (8 bytes)
    writer.writeUint64(totalDataSize);

    // Offset of direct block allocation iterator (8 bytes)
    writer.writeUint64(totalDataSize);

    // Number of managed objects in heap (8 bytes)
    writer.writeUint64(_objects.length);

    // Size of huge objects in heap (8 bytes)
    writer.writeUint64(0);

    // Number of huge objects in heap (8 bytes)
    writer.writeUint64(0);

    // Size of tiny objects in heap (8 bytes)
    writer.writeUint64(0);

    // Number of tiny objects in heap (8 bytes)
    writer.writeUint64(0);

    // Table width (2 bytes)
    writer.writeUint16(tableWidth);

    // Starting block size (8 bytes)
    writer.writeUint64(startingBlockSize);

    // Maximum direct block size (8 bytes)
    writer.writeUint64(maxDirectBlockSize);

    // Maximum heap size (2 bytes) - log2 of max heap size
    final maxHeapSize = 16; // 2^16 = 64KB default
    writer.writeUint16(maxHeapSize);

    // Starting number of rows (2 bytes)
    final startingNumRows = _calculateStartingRows();
    writer.writeUint16(startingNumRows);

    // Root block address (8 bytes)
    writer.writeUint64(rootBlockAddress);

    // Current number of rows (2 bytes)
    final currentNumRows = _calculateCurrentRows();
    writer.writeUint16(currentNumRows);

    // Calculate and write checksum
    final headerBytes = writer.bytes.sublist(headerStart);
    final checksum = _calculateChecksum(headerBytes);
    writer.writeUint32(checksum);
  }

  /// Calculate free space in managed blocks
  int _calculateFreeSpace() {
    int freeSpace = 0;
    for (final block in _blocks) {
      final usedSpace =
          block.objects.fold(0, (sum, obj) => sum + obj.data.length);
      freeSpace += block.blockSize - usedSpace;
    }
    return freeSpace;
  }

  /// Calculate starting number of rows
  int _calculateStartingRows() {
    // Number of rows needed to reach starting block size
    // Row 0 has blocks of size startingBlockSize
    return 0;
  }

  /// Calculate current number of rows
  int _calculateCurrentRows() {
    if (_blocks.isEmpty) return 0;

    // Calculate based on largest block size used
    int maxBlockSize = _blocks.fold(
        0, (max, block) => block.blockSize > max ? block.blockSize : max);
    int rows = 0;
    int size = startingBlockSize;

    while (size < maxBlockSize) {
      rows++;
      size *= 2;
    }

    return rows;
  }

  /// Write a direct block ("FHDB")
  void _writeDirectBlock(
    ByteWriter writer,
    _DirectBlock block,
    int heapHeaderAddress,
    int blockAddress,
  ) {
    final blockStart = writer.position;

    // Signature "FHDB"
    writer.writeString('FHDB', nullTerminate: false);

    // Version (0)
    writer.writeUint8(0);

    // Heap header address (8 bytes)
    writer.writeUint64(heapHeaderAddress);

    // Block offset (8 bytes) - size of objects already allocated
    final blockOffset = block.objects.isEmpty ? 0 : block.objects.first.offset;
    writer.writeUint64(blockOffset);

    // Write object data
    for (final obj in block.objects) {
      writer.writeBytes(obj.data);
    }

    // Pad to block size
    final dataWritten =
        block.objects.fold(0, (sum, obj) => sum + obj.data.length);
    final paddingNeeded = block.blockSize - dataWritten;
    if (paddingNeeded > 0) {
      writer.writeBytes(List<int>.filled(paddingNeeded, 0));
    }

    // Calculate and write checksum
    final blockBytes = writer.bytes.sublist(blockStart);
    final checksum = _calculateChecksum(blockBytes);
    writer.writeUint32(checksum);
  }

  /// Calculate Jenkins lookup3 hash (used for HDF5 checksums)
  ///
  /// This is a simplified version of the lookup3 hash algorithm.
  /// HDF5 uses this for fractal heap checksums.
  int _calculateChecksum(List<int> data) {
    int hash = 0;

    for (int i = 0; i < data.length; i++) {
      hash += data[i];
      hash += (hash << 10);
      hash ^= (hash >> 6);
    }

    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);

    return hash & 0xFFFFFFFF;
  }

  /// Clear all allocated objects
  ///
  /// This resets the heap writer to its initial state, removing all
  /// allocated objects and blocks.
  void clear() {
    _objects.clear();
    _blocks.clear();
    _nextObjectOffset = 0;
  }

  @override
  String toString() =>
      'FractalHeapWriter(objects=$objectCount, blocks=${_blocks.length}, totalSize=$totalDataSize)';
}

/// Represents a managed object in the fractal heap
class _ManagedObject {
  final int offset;
  final List<int> data;

  _ManagedObject({
    required this.offset,
    required this.data,
  });
}

/// Represents a direct block in the fractal heap
class _DirectBlock {
  final int blockSize;
  final List<_ManagedObject> objects;

  _DirectBlock({
    required this.blockSize,
    required this.objects,
  });
}
