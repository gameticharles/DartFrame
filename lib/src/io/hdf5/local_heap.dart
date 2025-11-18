import 'dart:typed_data';
import 'byte_reader.dart';
import 'byte_writer.dart';
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

/// Writer for HDF5 local heap
///
/// The local heap writer manages allocation and writing of variable-length
/// data for HDF5 version 1 groups. It stores object names and other small
/// variable-length data with null terminators.
///
/// The local heap supports:
/// - String data with automatic null termination
/// - Free space list management
/// - Multiple heap blocks when size exceeds 64KB
///
/// Example usage:
/// ```dart
/// final heapWriter = LocalHeapWriter();
///
/// // Allocate strings in the heap
/// final offset1 = heapWriter.allocate(utf8.encode('dataset1'));
/// final offset2 = heapWriter.allocate(utf8.encode('group1'));
///
/// // Write the heap to a file at a specific address
/// final bytes = heapWriter.write(1024);
/// ```
class LocalHeapWriter {
  final List<int> _data = [];
  final Map<int, int> _allocations = {}; // offset -> size
  final List<_FreeSpaceBlock> _freeList = [];
  final Endian _endian;
  final int _maxBlockSize;

  /// Create a new local heap writer
  ///
  /// Parameters:
  /// - [endian]: Byte order (default: little-endian)
  /// - [maxBlockSize]: Maximum size for a single heap block (default: 64KB)
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = LocalHeapWriter();
  /// ```
  LocalHeapWriter({
    Endian endian = Endian.little,
    int maxBlockSize = 65536, // 64KB default
  })  : _endian = endian,
        _maxBlockSize = maxBlockSize;

  /// Allocate space for data in the local heap
  ///
  /// This method stores the data with a null terminator and returns the
  /// offset where the data is stored. The offset can be used to reference
  /// the data from symbol table entries or other structures.
  ///
  /// For string data, a null terminator (0x00) is automatically added.
  ///
  /// Parameters:
  /// - [data]: The data bytes to store in the heap
  /// - [addNullTerminator]: Whether to add a null terminator (default: true)
  ///
  /// Returns the offset in the heap where the data is stored.
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = LocalHeapWriter();
  /// final nameData = utf8.encode('dataset_name');
  /// final offset = heapWriter.allocate(nameData);
  /// ```
  int allocate(List<int> data, {bool addNullTerminator = true}) {
    final dataSize = data.length + (addNullTerminator ? 1 : 0);

    // Try to find a suitable free space block
    int? offset = _findFreeSpace(dataSize);

    if (offset == null) {
      // No suitable free space, allocate at the end
      offset = _data.length;
      _data.addAll(data);
      if (addNullTerminator) {
        _data.add(0); // null terminator
      }
    } else {
      // Use free space
      _useFreeSpace(offset, data, addNullTerminator);
    }

    _allocations[offset] = dataSize;
    return offset;
  }

  /// Find a suitable free space block for the given size
  ///
  /// Returns the offset of a suitable free space block, or null if none found.
  int? _findFreeSpace(int size) {
    for (int i = 0; i < _freeList.length; i++) {
      final block = _freeList[i];
      if (block.size >= size) {
        return block.offset;
      }
    }
    return null;
  }

  /// Use a free space block for allocation
  void _useFreeSpace(int offset, List<int> data, bool addNullTerminator) {
    // Find and remove the free space block
    final blockIndex = _freeList.indexWhere((block) => block.offset == offset);
    if (blockIndex == -1) return;

    final block = _freeList.removeAt(blockIndex);
    final dataSize = data.length + (addNullTerminator ? 1 : 0);

    // Write data to the free space
    for (int i = 0; i < data.length; i++) {
      _data[offset + i] = data[i];
    }
    if (addNullTerminator) {
      _data[offset + data.length] = 0;
    }

    // If there's remaining space, add it back to the free list
    if (block.size > dataSize) {
      final remainingOffset = offset + dataSize;
      final remainingSize = block.size - dataSize;
      _freeList.add(_FreeSpaceBlock(remainingOffset, remainingSize));
    }
  }

  /// Free allocated space at the given offset
  ///
  /// This marks the space as free and adds it to the free space list.
  /// Adjacent free blocks are merged automatically.
  ///
  /// Parameters:
  /// - [offset]: The offset of the allocation to free
  void free(int offset) {
    final size = _allocations.remove(offset);
    if (size == null) return;

    // Add to free list
    _freeList.add(_FreeSpaceBlock(offset, size));

    // Merge adjacent free blocks
    _mergeFreeBlocks();
  }

  /// Merge adjacent free space blocks
  void _mergeFreeBlocks() {
    if (_freeList.length <= 1) return;

    // Sort by offset
    _freeList.sort((a, b) => a.offset.compareTo(b.offset));

    // Merge adjacent blocks
    final merged = <_FreeSpaceBlock>[];
    _FreeSpaceBlock? current;

    for (final block in _freeList) {
      if (current == null) {
        current = block;
      } else if (current.offset + current.size == block.offset) {
        // Adjacent blocks, merge them
        current = _FreeSpaceBlock(current.offset, current.size + block.size);
      } else {
        merged.add(current);
        current = block;
      }
    }

    if (current != null) {
      merged.add(current);
    }

    _freeList.clear();
    _freeList.addAll(merged);
  }

  /// Get the current size of the heap data segment
  int get dataSegmentSize => _data.length;

  /// Get the number of allocations
  int get allocationCount => _allocations.length;

  /// Get the total free space available
  int get totalFreeSpace {
    return _freeList.fold(0, (sum, block) => sum + block.size);
  }

  /// Check if the heap needs to be split into multiple blocks
  bool get needsMultipleBlocks => _data.length > _maxBlockSize;

  /// Get the number of blocks needed for the current data
  int get blockCount {
    if (_data.isEmpty) return 1;
    return (_data.length / _maxBlockSize).ceil();
  }

  /// Write the local heap
  ///
  /// This method writes the complete local heap in HDF5 format:
  /// - Heap header with "HEAP" signature
  /// - Free space list
  /// - Data segment
  ///
  /// For heaps larger than maxBlockSize, multiple blocks are created.
  ///
  /// Parameters:
  /// - [address]: The file address where this heap will be written
  ///
  /// Returns the bytes for the complete local heap.
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = LocalHeapWriter();
  /// heapWriter.allocate(utf8.encode('name1'));
  /// heapWriter.allocate(utf8.encode('name2'));
  ///
  /// final heapBytes = heapWriter.write(2048);
  /// // Write heapBytes to file at address 2048
  /// ```
  List<int> write(int address) {
    final writer = ByteWriter(endian: _endian);

    // Calculate data segment address (after header)
    // Header is 32 bytes for version 0 (4+1+3+8+8+8)
    final dataSegmentAddress = address + 32;

    // Write heap header
    _writeHeader(writer, dataSegmentAddress);

    // Write data segment
    writer.writeBytes(_data);

    return writer.bytes;
  }

  /// Write the local heap header
  ///
  /// Format (version 0):
  /// - 4 bytes: Signature "HEAP"
  /// - 1 byte: Version (0)
  /// - 3 bytes: Reserved (zeros)
  /// - 8 bytes: Data segment size
  /// - 8 bytes: Offset to head of free list (0 if no free space)
  /// - 8 bytes: Address of data segment
  void _writeHeader(ByteWriter writer, int dataSegmentAddress) {
    // Write signature "HEAP"
    writer.writeBytes([0x48, 0x45, 0x41, 0x50]); // "HEAP" in ASCII

    // Write version (0)
    writer.writeUint8(0);

    // Write reserved bytes (3 bytes of zeros)
    writer.writeUint8(0);
    writer.writeUint8(0);
    writer.writeUint8(0);

    // Write data segment size (8 bytes)
    writer.writeUint64(_data.length);

    // Write offset to head of free list (8 bytes)
    // For simplicity, we set this to 0 (no free list in written heap)
    // The free list is only used during construction
    writer.writeUint64(0);

    // Write address of data segment (8 bytes)
    writer.writeUint64(dataSegmentAddress);
  }

  /// Write multiple heap blocks if the data exceeds maxBlockSize
  ///
  /// This method splits the heap data into multiple blocks and writes
  /// each block with its own header. This is used when the heap size
  /// exceeds the maximum block size (typically 64KB).
  ///
  /// Parameters:
  /// - [startAddress]: The file address where the first block will be written
  ///
  /// Returns a list of byte arrays, one for each block.
  ///
  /// Example:
  /// ```dart
  /// final heapWriter = LocalHeapWriter();
  /// // ... allocate lots of data ...
  ///
  /// if (heapWriter.needsMultipleBlocks) {
  ///   final blocks = heapWriter.writeMultipleBlocks(2048);
  ///   // Write each block to file sequentially
  /// }
  /// ```
  List<List<int>> writeMultipleBlocks(int startAddress) {
    final blocks = <List<int>>[];
    int currentAddress = startAddress;
    int dataOffset = 0;

    while (dataOffset < _data.length) {
      final blockSize = (_data.length - dataOffset).clamp(0, _maxBlockSize);
      final blockData = _data.sublist(dataOffset, dataOffset + blockSize);

      final writer = ByteWriter(endian: _endian);
      final dataSegmentAddress = currentAddress + 32;

      // Write block header
      _writeBlockHeader(writer, blockData.length, dataSegmentAddress);

      // Write block data
      writer.writeBytes(blockData);

      blocks.add(writer.bytes);

      dataOffset += blockSize;
      currentAddress += writer.bytes.length;
    }

    return blocks;
  }

  /// Write a heap block header
  void _writeBlockHeader(
      ByteWriter writer, int blockDataSize, int dataSegmentAddress) {
    // Write signature "HEAP"
    writer.writeBytes([0x48, 0x45, 0x41, 0x50]); // "HEAP" in ASCII

    // Write version (0)
    writer.writeUint8(0);

    // Write reserved bytes (3 bytes of zeros)
    writer.writeUint8(0);
    writer.writeUint8(0);
    writer.writeUint8(0);

    // Write data segment size (8 bytes)
    writer.writeUint64(blockDataSize);

    // Write offset to head of free list (8 bytes)
    writer.writeUint64(0);

    // Write address of data segment (8 bytes)
    writer.writeUint64(dataSegmentAddress);
  }

  /// Clear all allocated data
  ///
  /// This resets the heap writer to its initial state, removing all
  /// allocated data and free space blocks.
  void clear() {
    _data.clear();
    _allocations.clear();
    _freeList.clear();
  }

  @override
  String toString() =>
      'LocalHeapWriter(size=$dataSegmentSize, allocations=$allocationCount, freeSpace=$totalFreeSpace)';
}

/// Represents a free space block in the local heap
class _FreeSpaceBlock {
  final int offset;
  final int size;

  _FreeSpaceBlock(this.offset, this.size);

  @override
  String toString() => 'FreeSpaceBlock(offset=$offset, size=$size)';
}
