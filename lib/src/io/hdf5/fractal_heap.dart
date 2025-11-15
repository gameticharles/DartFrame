import 'dart:typed_data';
import 'byte_reader.dart';
import 'hdf5_error.dart';

/// Fractal heap for storing variable-length data (used for links in HDF5 1.8+)
class FractalHeap {
  final int address;
  final int version;
  final int heapIdLength;
  final int maxHeapSize;
  final int startingBlockSize;
  final int maxDirectBlockSize;
  final int tableWidth;
  final int startingNumRows;
  final int rootBlockAddress;
  final int currentNumRows;

  // Flags
  final bool idWrapped;
  final bool directBlocksChecksummed;

  // Object management
  final int maxSizeOfManagedObjects;
  final int numManagedObjectsInHeap;
  final int numHugeObjectsInHeap;
  final int numTinyObjectsInHeap;

  // Huge object tracking
  final int nextHugeObjectId;
  final int sizeOfHugeObjectsInHeap;

  // Tiny object tracking
  final int sizeOfTinyObjectsInHeap;

  // Space management
  final int amountOfFreeSpaceInManagedBlocks;
  final int amountOfManagedSpaceInHeap;
  final int amountOfAllocatedManagedSpaceInHeap;
  final int offsetOfDirectBlockAllocationIterator;

  // Addresses for advanced features
  final int btreeAddressOfHugeObjects;
  final int addressOfManagedBlockFreeSpaceManager;

  // Cached data
  final Map<int, List<int>> _objectCache = {};

  FractalHeap({
    required this.address,
    required this.version,
    required this.heapIdLength,
    required this.maxHeapSize,
    required this.startingBlockSize,
    required this.maxDirectBlockSize,
    required this.tableWidth,
    required this.startingNumRows,
    required this.rootBlockAddress,
    required this.currentNumRows,
    required this.idWrapped,
    required this.directBlocksChecksummed,
    required this.maxSizeOfManagedObjects,
    required this.numManagedObjectsInHeap,
    required this.numHugeObjectsInHeap,
    required this.numTinyObjectsInHeap,
    required this.nextHugeObjectId,
    required this.sizeOfHugeObjectsInHeap,
    required this.sizeOfTinyObjectsInHeap,
    required this.amountOfFreeSpaceInManagedBlocks,
    required this.amountOfManagedSpaceInHeap,
    required this.amountOfAllocatedManagedSpaceInHeap,
    required this.offsetOfDirectBlockAllocationIterator,
    required this.btreeAddressOfHugeObjects,
    required this.addressOfManagedBlockFreeSpaceManager,
  });

  /// Reads a fractal heap header
  static Future<FractalHeap> read(ByteReader reader, int address) async {
    hdf5DebugLog(
        'Reading fractal heap at address 0x${address.toRadixString(16)}');
    reader.seek(address);

    // Read signature
    final sig = await reader.readBytes(4);
    final sigStr = String.fromCharCodes(sig);
    if (sigStr != 'FRHP') {
      throw InvalidSignatureError(
        structureType: 'fractal heap',
        expected: 'FRHP',
        actual: sigStr,
        address: address,
      );
    }

    final version = await reader.readUint8();
    if (version != 0) {
      throw UnsupportedVersionError(
        component: 'fractal heap',
        version: version,
      );
    }

    final heapIdLength = await reader.readUint16();
    final ioFilterEncodedLength = await reader.readUint16();
    final flags = await reader.readUint8();

    // Decode flags
    final idWrapped = (flags & 0x01) != 0;
    final directBlocksChecksummed = (flags & 0x02) != 0;

    final maxSizeOfManagedObjects = await reader.readUint32();
    final nextHugeObjectId = await reader.readUint64();
    final btreeAddressOfHugeObjects = await reader.readUint64();
    final amountOfFreeSpaceInManagedBlocks = await reader.readUint64();
    final addressOfManagedBlockFreeSpaceManager = await reader.readUint64();
    final amountOfManagedSpaceInHeap = await reader.readUint64();
    final amountOfAllocatedManagedSpaceInHeap = await reader.readUint64();
    final offsetOfDirectBlockAllocationIterator = await reader.readUint64();
    final numManagedObjectsInHeap = await reader.readUint64();
    final sizeOfHugeObjectsInHeap = await reader.readUint64();
    final numHugeObjectsInHeap = await reader.readUint64();
    final sizeOfTinyObjectsInHeap = await reader.readUint64();
    final numTinyObjectsInHeap = await reader.readUint64();

    final tableWidth = await reader.readUint16();
    final startingBlockSize = await reader.readUint64();
    final maxDirectBlockSize = await reader.readUint64();
    final maxHeapSize = await reader.readUint16();
    final startingNumRows = await reader.readUint16();
    final rootBlockAddress = await reader.readUint64();
    final currentNumRows = await reader.readUint16();

    // Skip size of filtered root direct block (if present)
    if (ioFilterEncodedLength > 0) {
      await reader.readUint64();
    }

    // Skip I/O filter information (if present)
    if (ioFilterEncodedLength > 0) {
      await reader.readBytes(ioFilterEncodedLength);
    }

    // Skip checksum
    await reader.readUint32();

    hdf5DebugLog('Fractal heap: version=$version, heapIdLength=$heapIdLength, '
        'tableWidth=$tableWidth, startingBlockSize=$startingBlockSize, '
        'rootBlockAddress=0x${rootBlockAddress.toRadixString(16)}');

    return FractalHeap(
      address: address,
      version: version,
      heapIdLength: heapIdLength,
      maxHeapSize: maxHeapSize,
      startingBlockSize: startingBlockSize.toInt(),
      maxDirectBlockSize: maxDirectBlockSize.toInt(),
      tableWidth: tableWidth,
      startingNumRows: startingNumRows,
      rootBlockAddress: rootBlockAddress.toInt(),
      currentNumRows: currentNumRows,
      idWrapped: idWrapped,
      directBlocksChecksummed: directBlocksChecksummed,
      maxSizeOfManagedObjects: maxSizeOfManagedObjects,
      numManagedObjectsInHeap: numManagedObjectsInHeap.toInt(),
      numHugeObjectsInHeap: numHugeObjectsInHeap.toInt(),
      numTinyObjectsInHeap: numTinyObjectsInHeap.toInt(),
      nextHugeObjectId: nextHugeObjectId.toInt(),
      sizeOfHugeObjectsInHeap: sizeOfHugeObjectsInHeap.toInt(),
      sizeOfTinyObjectsInHeap: sizeOfTinyObjectsInHeap.toInt(),
      amountOfFreeSpaceInManagedBlocks:
          amountOfFreeSpaceInManagedBlocks.toInt(),
      amountOfManagedSpaceInHeap: amountOfManagedSpaceInHeap.toInt(),
      amountOfAllocatedManagedSpaceInHeap:
          amountOfAllocatedManagedSpaceInHeap.toInt(),
      offsetOfDirectBlockAllocationIterator:
          offsetOfDirectBlockAllocationIterator.toInt(),
      btreeAddressOfHugeObjects: btreeAddressOfHugeObjects.toInt(),
      addressOfManagedBlockFreeSpaceManager:
          addressOfManagedBlockFreeSpaceManager.toInt(),
    );
  }

  /// Reads an object from the heap using its heap ID
  Future<List<int>> readObject(ByteReader reader, List<int> heapId) async {
    if (heapId.length < heapIdLength) {
      throw CorruptedFileError(
        reason: 'Invalid heap ID length',
        details: 'Expected $heapIdLength bytes, got ${heapId.length}',
      );
    }

    // Parse heap ID
    // Format: version (1 byte) + type (1 byte) + offset/address (variable)
    final idVersion = heapId[0];
    final idType = heapId[1];

    if (idVersion != 0) {
      throw UnsupportedVersionError(
        component: 'fractal heap ID',
        version: idVersion,
      );
    }

    // Type 0: Managed object in direct block
    if (idType == 0) {
      return await _readManagedObject(reader, heapId);
    }
    // Type 1: Huge object
    else if (idType == 1) {
      throw UnsupportedFeatureError(
        feature: 'Huge objects in fractal heap',
        details: 'Heap ID type: $idType',
      );
    }
    // Type 2: Tiny object
    else if (idType == 2) {
      return _readTinyObject(heapId);
    } else {
      throw CorruptedFileError(
        reason: 'Unknown heap ID type: $idType',
      );
    }
  }

  /// Reads a managed object from a direct block
  Future<List<int>> _readManagedObject(
      ByteReader reader, List<int> heapId) async {
    // Extract offset from heap ID (bytes 2-9 for 8-byte offset)
    final buffer = ByteData.view(Uint8List.fromList(heapId).buffer);
    final offset = buffer.getUint64(2, Endian.little);
    final length = heapId.length > 10 ? buffer.getUint16(10, Endian.little) : 0;

    hdf5DebugLog('Reading managed object at offset $offset, length $length');

    // Check cache
    if (_objectCache.containsKey(offset)) {
      return _objectCache[offset]!;
    }

    // Read from direct block
    final blockAddress = rootBlockAddress;
    if (blockAddress == 0 || blockAddress == 0xFFFFFFFFFFFFFFFF) {
      throw CorruptedFileError(
        reason: 'Invalid root block address',
        details: 'Address: 0x${blockAddress.toRadixString(16)}',
      );
    }

    // Read direct block header
    reader.seek(blockAddress);
    final blockSig = await reader.readBytes(4);
    final blockSigStr = String.fromCharCodes(blockSig);

    if (blockSigStr != 'FHDB') {
      throw InvalidSignatureError(
        structureType: 'fractal heap direct block',
        expected: 'FHDB',
        actual: blockSigStr,
        address: blockAddress,
      );
    }

    final blockVersion = await reader.readUint8();
    final heapHeaderAddress = await reader.readUint64();

    // Block offset is the size of objects already allocated
    final blockOffset = await reader.readUint64();

    // Skip checksum
    await reader.readUint32();

    hdf5DebugLog('Direct block: version=$blockVersion, '
        'heapHeaderAddress=0x${heapHeaderAddress.toRadixString(16)}, '
        'blockOffset=$blockOffset');

    // Calculate object position in block
    // The offset in the heap ID is relative to the start of the heap data
    final objectPosition =
        blockAddress + 21 + offset.toInt(); // 21 = header size

    reader.seek(objectPosition);

    // If length is specified in heap ID, use it; otherwise read until null or reasonable limit
    if (length > 0) {
      final data = await reader.readBytes(length);
      _objectCache[offset.toInt()] = data;
      return data;
    } else {
      // Read variable-length object (common for link names)
      final data = <int>[];
      int maxLength = 10000; // Safety limit
      while (data.length < maxLength) {
        final byte = await reader.readUint8();
        if (byte == 0) break;
        data.add(byte);
      }
      _objectCache[offset.toInt()] = data;
      return data;
    }
  }

  /// Reads a tiny object (stored directly in heap ID)
  List<int> _readTinyObject(List<int> heapId) {
    // Tiny objects are stored directly in the heap ID after the type byte
    // Format: version (1) + type (1) + length (1) + data (variable)
    if (heapId.length < 3) {
      throw CorruptedFileError(
        reason: 'Invalid tiny object heap ID',
        details: 'Length: ${heapId.length}',
      );
    }

    final length = heapId[2];
    if (heapId.length < 3 + length) {
      throw CorruptedFileError(
        reason: 'Tiny object heap ID too short',
        details: 'Expected ${3 + length} bytes, got ${heapId.length}',
      );
    }

    return heapId.sublist(3, 3 + length);
  }
}
