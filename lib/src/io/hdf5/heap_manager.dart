import 'byte_writer.dart';
import 'fractal_heap_writer.dart';

/// Type of heap for allocation
enum HeapType {
  /// Local heap (HDF5 version 1) for small variable-length data
  local,

  /// Global heap for large variable-length data (strings, arrays)
  global,

  /// Fractal heap (HDF5 version 2) for efficient variable-length storage
  fractal,
}

/// Manages coordinated allocation across multiple heap types
///
/// The HeapManager coordinates allocation of variable-length data across
/// local heaps, global heaps, and fractal heaps based on the HDF5 format
/// version and data characteristics.
///
/// Example usage:
/// ```dart
/// final heapManager = HeapManager(formatVersion: 0);
///
/// // Allocate in local heap for object names
/// final nameOffset = heapManager.allocate(
///   HeapType.local,
///   utf8.encode('dataset_name'),
/// );
///
/// // Allocate in global heap for large strings
/// final heapId = heapManager.allocate(
///   HeapType.global,
///   utf8.encode('large string data...'),
/// );
/// ```
class HeapManager {
  /// HDF5 format version
  final int formatVersion;

  /// Local heap writer for version 1 groups
  final LocalHeapWriterInternal _localHeap;

  /// Global heap writer for variable-length data
  final GlobalHeapWriterInternal _globalHeap;

  /// Fractal heap writer for version 2 groups
  final FractalHeapWriter _fractalHeap;

  /// Create a new heap manager
  ///
  /// Parameters:
  /// - [formatVersion]: HDF5 format version (0, 1, or 2)
  HeapManager({
    this.formatVersion = 0,
  })  : _localHeap = LocalHeapWriterInternal(),
        _globalHeap = GlobalHeapWriterInternal(),
        _fractalHeap = FractalHeapWriter();

  /// Allocate data in the specified heap type
  ///
  /// Parameters:
  /// - [type]: The type of heap to allocate in
  /// - [data]: The data bytes to allocate
  ///
  /// Returns:
  /// - For local heap: offset within the heap (int)
  /// - For global heap: heap ID (int)
  /// - For fractal heap: heap ID (`List<int>`)
  ///
  /// The return type is dynamic to accommodate different heap ID formats.
  dynamic allocate(HeapType type, List<int> data) {
    switch (type) {
      case HeapType.local:
        return _localHeap.allocate(data);

      case HeapType.global:
        return _globalHeap.allocate(data);

      case HeapType.fractal:
        return _fractalHeap.allocate(data);
    }
  }

  /// Write all heaps to the byte writer
  ///
  /// This method writes all heap structures that have been allocated.
  /// It should be called after all allocations are complete.
  ///
  /// Parameters:
  /// - [writer]: The ByteWriter to write to
  ///
  /// Returns a map of heap addresses:
  /// - 'localHeapAddress': Address of local heap (if used)
  /// - 'globalHeapAddress': Address of global heap (if used)
  /// - 'fractalHeapAddress': Address of fractal heap (if used)
  Map<String, int> writeAll(ByteWriter writer) {
    final addresses = <String, int>{};

    // Write local heap if it has allocations
    if (_localHeap.hasAllocations) {
      final address = writer.position;
      final bytes = _localHeap.write(address);
      writer.writeBytes(bytes);
      addresses['localHeapAddress'] = address;
    }

    // Write global heap if it has allocations
    if (_globalHeap.hasAllocations) {
      final address = writer.position;
      final bytes = _globalHeap.write(address);
      writer.writeBytes(bytes);
      addresses['globalHeapAddress'] = address;
    }

    // Write fractal heap if it has allocations
    if (_fractalHeap.objectCount > 0) {
      final address = writer.position;
      final bytes = _fractalHeap.write(address);
      writer.writeBytes(bytes);
      addresses['fractalHeapAddress'] = address;
    }

    return addresses;
  }

  /// Get the local heap writer
  LocalHeapWriterInternal get localHeap => _localHeap;

  /// Get the global heap writer
  GlobalHeapWriterInternal get globalHeap => _globalHeap;

  /// Get the fractal heap writer
  FractalHeapWriter get fractalHeap => _fractalHeap;

  /// Clear all heap allocations
  void clear() {
    _localHeap.clear();
    _globalHeap.clear();
    _fractalHeap.clear();
  }
}

/// Writer for HDF5 local heaps
///
/// Local heaps store small variable-length data like object names in
/// symbol tables for HDF5 version 1 groups.
class LocalHeapWriterInternal {
  final List<int> _data = [];
  final Map<int, int> _allocations = {}; // offset -> size

  /// Allocate data in the local heap
  ///
  /// Returns the offset within the heap where the data is stored.
  int allocate(List<int> data) {
    // Add padding at the start if this is the first allocation
    // to avoid offset 0 (reader bug workaround)
    if (_data.isEmpty) {
      _data.addAll(List<int>.filled(8, 0));
    }

    final actualOffset = _data.length;
    _data.addAll(data);
    _data.add(0); // null terminator for strings
    _allocations[actualOffset] = data.length + 1;

    return actualOffset;
  }

  /// Check if the heap has any allocations
  bool get hasAllocations => _data.isNotEmpty;

  /// Get the total size of allocated data
  int get dataSize => _data.length;

  /// Write the local heap
  ///
  /// Parameters:
  /// - [address]: The file address where this heap will be written
  ///
  /// Returns the bytes for the complete local heap.
  List<int> write(int address) {
    final writer = ByteWriter();

    // Calculate data segment address (after 32-byte header)
    final dataSegmentAddress = address + 32;

    // Write signature
    writer.writeString('HEAP', nullTerminate: false);

    // Version: 0
    writer.writeUint8(0);

    // Reserved (3 bytes)
    writer.writeUint8(0);
    writer.writeUint8(0);
    writer.writeUint8(0);

    // Data segment size
    writer.writeUint64(_data.length);

    // Offset to head of free list (0 - no free list)
    writer.writeUint64(0);

    // Data segment address
    writer.writeUint64(dataSegmentAddress);

    // Write data segment
    writer.writeBytes(_data);

    return writer.bytes;
  }

  /// Clear all allocations
  void clear() {
    _data.clear();
    _allocations.clear();
  }
}

/// Writer for HDF5 global heaps
///
/// Global heaps store large variable-length data like strings and
/// variable-length arrays.
class GlobalHeapWriterInternal {
  final Map<int, _GlobalHeapObjectInternal> _objects = {};
  int _nextId = 1;

  /// Allocate data in the global heap
  ///
  /// Returns a heap ID that can be used to reference this data.
  int allocate(List<int> data) {
    final id = _nextId++;
    _objects[id] =
        _GlobalHeapObjectInternal(id: id, data: List<int>.from(data));
    return id;
  }

  /// Check if the heap has any allocations
  bool get hasAllocations => _objects.isNotEmpty;

  /// Get the number of objects in the heap
  int get objectCount => _objects.length;

  /// Write the global heap collection
  ///
  /// Parameters:
  /// - [address]: The file address where this heap will be written
  ///
  /// Returns the bytes for the complete global heap collection.
  List<int> write(int address) {
    final writer = ByteWriter();

    // Calculate collection size
    int collectionSize = 16; // Header size
    for (final obj in _objects.values) {
      collectionSize += 16 + obj.data.length; // Object header + data
    }

    // Write "GCOL" signature
    writer.writeString('GCOL', nullTerminate: false);

    // Version: 1
    writer.writeUint8(1);

    // Reserved (3 bytes)
    writer.writeUint8(0);
    writer.writeUint8(0);
    writer.writeUint8(0);

    // Collection size
    writer.writeUint64(collectionSize);

    // Write all objects
    for (final obj in _objects.values) {
      // Heap object index
      writer.writeUint16(obj.id);

      // Reference count
      writer.writeUint16(0);

      // Reserved
      writer.writeUint32(0);

      // Object size
      writer.writeUint64(obj.data.length);

      // Object data
      writer.writeBytes(obj.data);
    }

    return writer.bytes;
  }

  /// Clear all allocations
  void clear() {
    _objects.clear();
    _nextId = 1;
  }
}

/// Represents an object in the global heap for writing
class _GlobalHeapObjectInternal {
  final int id;
  final List<int> data;

  _GlobalHeapObjectInternal({
    required this.id,
    required this.data,
  });
}
