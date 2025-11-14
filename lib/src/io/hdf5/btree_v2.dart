import 'byte_reader.dart';
import 'hdf5_error.dart';

/// Version 2 B-tree for indexing (used in HDF5 1.8+)
class BTreeV2 {
  final int address;
  final int version;
  final int type;
  final int nodeSize;
  final int recordSize;
  final int depth;
  final int rootNodeAddress;
  final int numRecordsInRoot;

  BTreeV2({
    required this.address,
    required this.version,
    required this.type,
    required this.nodeSize,
    required this.recordSize,
    required this.depth,
    required this.rootNodeAddress,
    required this.numRecordsInRoot,
  });

  /// Reads a V2 B-tree header
  static Future<BTreeV2> read(ByteReader reader, int address) async {
    hdf5DebugLog('Reading V2 B-tree at address 0x${address.toRadixString(16)}');
    reader.seek(address);

    // Read signature
    final sig = await reader.readBytes(4);
    final sigStr = String.fromCharCodes(sig);
    if (sigStr != 'BTHD') {
      throw InvalidSignatureError(
        structureType: 'V2 B-tree header',
        expected: 'BTHD',
        actual: sigStr,
        address: address,
      );
    }

    final version = await reader.readUint8();
    if (version != 0) {
      throw UnsupportedVersionError(
        component: 'V2 B-tree',
        version: version,
      );
    }

    final type = await reader.readUint8();
    final nodeSize = await reader.readUint32();
    final recordSize = await reader.readUint16();
    final depth = await reader.readUint16();

    final splitPercent = await reader.readUint8();
    final mergePercent = await reader.readUint8();

    final rootNodeAddress = await reader.readUint64();
    final numRecordsInRoot = await reader.readUint16();
    final totalNumRecords = await reader.readUint64();

    // Skip checksum
    await reader.readUint32();

    hdf5DebugLog('V2 B-tree: type=$type, depth=$depth, '
        'rootNodeAddress=0x${rootNodeAddress.toRadixString(16)}, '
        'numRecordsInRoot=$numRecordsInRoot');

    return BTreeV2(
      address: address,
      version: version,
      type: type,
      nodeSize: nodeSize,
      recordSize: recordSize,
      depth: depth,
      rootNodeAddress: rootNodeAddress.toInt(),
      numRecordsInRoot: numRecordsInRoot,
    );
  }

  /// Reads all records from the B-tree
  /// For link name indexing (type 5), returns list of [hash, heapId] pairs
  Future<List<BTreeV2Record>> readAllRecords(ByteReader reader) async {
    final records = <BTreeV2Record>[];

    if (rootNodeAddress == 0 || rootNodeAddress == 0xFFFFFFFFFFFFFFFF) {
      return records;
    }

    await _readNode(reader, rootNodeAddress, depth, records);
    return records;
  }

  /// Recursively reads a B-tree node
  Future<void> _readNode(
    ByteReader reader,
    int nodeAddress,
    int nodeDepth,
    List<BTreeV2Record> records,
  ) async {
    reader.seek(nodeAddress);

    // Read node signature
    final sig = await reader.readBytes(4);
    final sigStr = String.fromCharCodes(sig);

    if (nodeDepth == 0) {
      // Leaf node
      if (sigStr != 'BTLF') {
        throw InvalidSignatureError(
          structureType: 'V2 B-tree leaf node',
          expected: 'BTLF',
          actual: sigStr,
          address: nodeAddress,
        );
      }

      final version = await reader.readUint8();
      final type = await reader.readUint8();

      // Read records
      // For type 5 (link name index), each record is:
      // - Hash (4 bytes)
      // - Heap ID (7 bytes typically)
      final numRecords =
          numRecordsInRoot; // This should be read from node, but using root for now

      for (int i = 0; i < numRecords; i++) {
        final hash = await reader.readUint32();
        final heapId = await reader.readBytes(7); // Typical heap ID length
        records.add(BTreeV2Record(hash: hash, heapId: heapId));
      }
    } else {
      // Internal node
      if (sigStr != 'BTIN') {
        throw InvalidSignatureError(
          structureType: 'V2 B-tree internal node',
          expected: 'BTIN',
          actual: sigStr,
          address: nodeAddress,
        );
      }

      final version = await reader.readUint8();
      final type = await reader.readUint8();

      // Read child pointers and recursively process
      // This is simplified - full implementation would read all records and child pointers
      final numRecords = numRecordsInRoot;

      for (int i = 0; i <= numRecords; i++) {
        final childAddress = await reader.readUint64();
        if (childAddress != 0 && childAddress != 0xFFFFFFFFFFFFFFFF) {
          await _readNode(reader, childAddress.toInt(), nodeDepth - 1, records);
        }
      }
    }
  }
}

/// A record from a V2 B-tree
class BTreeV2Record {
  final int hash;
  final List<int> heapId;

  BTreeV2Record({required this.hash, required this.heapId});
}
