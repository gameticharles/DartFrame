import 'byte_writer.dart';

/// Entry for a chunk in the B-tree v2 index
class BTreeV2ChunkEntry {
  final List<int> chunkCoordinates; // Scaled chunk coordinates
  final int chunkAddress;
  final int chunkSize;
  final int filterMask;

  BTreeV2ChunkEntry({
    required this.chunkCoordinates,
    required this.chunkAddress,
    required this.chunkSize,
    this.filterMask = 0,
  });

  /// Compare entries for sorting (lexicographic order of coordinates)
  int compareTo(BTreeV2ChunkEntry other) {
    final minLen = chunkCoordinates.length < other.chunkCoordinates.length
        ? chunkCoordinates.length
        : other.chunkCoordinates.length;
    for (int i = 0; i < minLen; i++) {
      if (chunkCoordinates[i] < other.chunkCoordinates[i]) return -1;
      if (chunkCoordinates[i] > other.chunkCoordinates[i]) return 1;
    }
    return chunkCoordinates.length.compareTo(other.chunkCoordinates.length);
  }
}

/// Node in a B-tree v2 structure
abstract class BTreeV2Node {
  List<BTreeV2ChunkEntry> get records;
  int get numRecords => records.length;
}

/// Leaf node in a B-tree v2
class BTreeV2LeafNode extends BTreeV2Node {
  @override
  final List<BTreeV2ChunkEntry> records;

  BTreeV2LeafNode(this.records);
}

/// Internal node in a B-tree v2
class BTreeV2InternalNode extends BTreeV2Node {
  @override
  final List<BTreeV2ChunkEntry> records;
  final List<BTreeV2Node> children;

  BTreeV2InternalNode(this.records, this.children);
}

/// Writer for B-tree version 2 structures
///
/// B-tree v2 is used in HDF5 format version 1.8+ for:
/// - Chunked dataset indexing
/// - Group object indexing
/// - Attribute indexing
///
/// This implementation focuses on chunked dataset indexing.
class BTreeV2Writer {
  final int dimensionality;
  final int nodeSize;
  final int offsetSize;
  final int splitPercent;
  final int mergePercent;

  /// Calculate record size for chunk entries
  /// Record format: chunk_size (4) + filter_mask (4) + coordinates (8 * dim) + address (offsetSize)
  int get recordSize => 8 + (8 * dimensionality) + offsetSize;

  /// Maximum number of records per node based on node size
  int get maxRecordsPerNode {
    // Node overhead: signature(4) + version(1) + type(1) + checksum(4) = 10 bytes
    // For internal nodes, add child pointers: (maxRecords + 1) * offsetSize
    // For leaf nodes, just records
    // Conservative estimate for leaf nodes:
    final overhead = 10;
    return (nodeSize - overhead) ~/ recordSize;
  }

  BTreeV2Writer({
    required this.dimensionality,
    this.nodeSize = 4096,
    this.offsetSize = 8,
    this.splitPercent = 100,
    this.mergePercent = 40,
  });

  /// Write a B-tree v2 index for chunked dataset
  ///
  /// Creates a B-tree v2 structure for looking up chunks by their coordinates.
  /// Implements proper tree building with leaf and internal nodes.
  ///
  /// Parameters:
  /// - [writer]: The ByteWriter to write to
  /// - [entries]: List of chunk entries to index
  ///
  /// Returns the address of the B-tree header
  Future<int> writeChunkIndex(
    ByteWriter writer,
    List<BTreeV2ChunkEntry> entries,
  ) async {
    if (entries.isEmpty) {
      throw ArgumentError('Cannot create B-tree with no entries');
    }

    // Sort entries by coordinates for proper B-tree ordering
    entries.sort((a, b) => a.compareTo(b));

    // Build the tree structure
    final root = _buildTree(entries);

    // Calculate tree depth
    final depth = _calculateDepth(root);

    // Write the tree nodes and collect addresses
    final nodeAddresses = <BTreeV2Node, int>{};
    final rootAddress = await _writeNodes(writer, root, nodeAddresses);

    // Write the B-tree header
    final headerAddress = writer.position;
    _writeHeader(
      writer,
      depth: depth,
      rootNodeAddress: rootAddress,
      numRecordsInRoot: root.numRecords,
      totalNumRecords: entries.length,
    );

    return headerAddress;
  }

  /// Build the B-tree structure from sorted entries
  BTreeV2Node _buildTree(List<BTreeV2ChunkEntry> entries) {
    // If entries fit in a single node, create a leaf
    if (entries.length <= maxRecordsPerNode) {
      return BTreeV2LeafNode(entries);
    }

    // Otherwise, split into multiple leaf nodes and create internal nodes
    return _buildInternalTree(entries);
  }

  /// Build internal tree structure with multiple levels
  BTreeV2Node _buildInternalTree(List<BTreeV2ChunkEntry> entries) {
    // Create leaf nodes
    final leafNodes = <BTreeV2LeafNode>[];
    for (int i = 0; i < entries.length; i += maxRecordsPerNode) {
      final end = (i + maxRecordsPerNode < entries.length)
          ? i + maxRecordsPerNode
          : entries.length;
      leafNodes.add(BTreeV2LeafNode(entries.sublist(i, end)));
    }

    // Build internal nodes recursively
    return _buildInternalLevel(leafNodes);
  }

  /// Build an internal level from child nodes
  BTreeV2Node _buildInternalLevel(List<BTreeV2Node> childNodes) {
    // If all children fit under one internal node, create it
    if (childNodes.length <= maxRecordsPerNode + 1) {
      // Internal node has N records and N+1 children
      // Records are the maximum keys from each child (except the last)
      final records = <BTreeV2ChunkEntry>[];
      for (int i = 0; i < childNodes.length - 1; i++) {
        records.add(childNodes[i].records.last);
      }
      return BTreeV2InternalNode(records, childNodes);
    }

    // Otherwise, split into multiple internal nodes and recurse
    final internalNodes = <BTreeV2InternalNode>[];
    final childrenPerNode = maxRecordsPerNode + 1;

    for (int i = 0; i < childNodes.length; i += childrenPerNode) {
      final end = (i + childrenPerNode < childNodes.length)
          ? i + childrenPerNode
          : childNodes.length;
      final children = childNodes.sublist(i, end);

      final records = <BTreeV2ChunkEntry>[];
      for (int j = 0; j < children.length - 1; j++) {
        records.add(children[j].records.last);
      }

      internalNodes.add(BTreeV2InternalNode(records, children));
    }

    return _buildInternalLevel(internalNodes);
  }

  /// Calculate the depth of the tree
  int _calculateDepth(BTreeV2Node node) {
    if (node is BTreeV2LeafNode) {
      return 0;
    } else if (node is BTreeV2InternalNode) {
      return 1 + _calculateDepth(node.children.first);
    }
    return 0;
  }

  /// Write all nodes in the tree and return the root address
  Future<int> _writeNodes(
    ByteWriter writer,
    BTreeV2Node node,
    Map<BTreeV2Node, int> nodeAddresses,
  ) async {
    // Write children first (post-order traversal)
    if (node is BTreeV2InternalNode) {
      for (final child in node.children) {
        await _writeNodes(writer, child, nodeAddresses);
      }
    }

    // Write this node
    final nodeAddress = writer.position;
    nodeAddresses[node] = nodeAddress;

    if (node is BTreeV2LeafNode) {
      _writeLeafNode(writer, node);
    } else if (node is BTreeV2InternalNode) {
      _writeInternalNode(writer, node, nodeAddresses);
    }

    return nodeAddress;
  }

  /// Write the B-tree v2 header (BTHD)
  void _writeHeader(
    ByteWriter writer, {
    required int depth,
    required int rootNodeAddress,
    required int numRecordsInRoot,
    required int totalNumRecords,
  }) {
    final headerStart = writer.position;

    // Signature
    writer.writeString('BTHD', nullTerminate: false);

    // Version
    writer.writeUint8(0);

    // Type: 1 = chunked dataset index
    writer.writeUint8(1);

    // Node size
    writer.writeUint32(nodeSize);

    // Record size
    writer.writeUint16(recordSize);

    // Depth
    writer.writeUint16(depth);

    // Split percent
    writer.writeUint8(splitPercent);

    // Merge percent
    writer.writeUint8(mergePercent);

    // Root node address
    writer.writeUint64(rootNodeAddress);

    // Number of records in root
    writer.writeUint16(numRecordsInRoot);

    // Total number of records
    writer.writeUint64(totalNumRecords);

    // Calculate and write checksum
    final headerBytes = writer.bytes.sublist(headerStart);
    final checksum = _calculateChecksum(headerBytes);
    writer.writeUint32(checksum);
  }

  /// Write a leaf node (BTLF)
  void _writeLeafNode(ByteWriter writer, BTreeV2LeafNode node) {
    final nodeStart = writer.position;

    // Signature
    writer.writeString('BTLF', nullTerminate: false);

    // Version
    writer.writeUint8(0);

    // Type: 1 = chunked dataset index
    writer.writeUint8(1);

    // Write records
    for (final record in node.records) {
      _writeChunkRecord(writer, record);
    }

    // Pad to node size if needed
    final bytesWritten = writer.position - nodeStart;
    final paddingNeeded = nodeSize - bytesWritten - 4; // -4 for checksum
    if (paddingNeeded > 0) {
      writer.writeBytes(List<int>.filled(paddingNeeded, 0));
    }

    // Calculate and write checksum
    final nodeBytes = writer.bytes.sublist(nodeStart);
    final checksum = _calculateChecksum(nodeBytes);
    writer.writeUint32(checksum);
  }

  /// Write an internal node (BTIN)
  void _writeInternalNode(
    ByteWriter writer,
    BTreeV2InternalNode node,
    Map<BTreeV2Node, int> nodeAddresses,
  ) {
    final nodeStart = writer.position;

    // Signature
    writer.writeString('BTIN', nullTerminate: false);

    // Version
    writer.writeUint8(0);

    // Type: 1 = chunked dataset index
    writer.writeUint8(1);

    // Write records (N records for N+1 children)
    for (final record in node.records) {
      _writeChunkRecord(writer, record);
    }

    // Write child pointers (N+1 pointers)
    for (final child in node.children) {
      final childAddress = nodeAddresses[child] ?? 0;
      _writeOffset(writer, childAddress);
    }

    // Pad to node size if needed
    final bytesWritten = writer.position - nodeStart;
    final paddingNeeded = nodeSize - bytesWritten - 4; // -4 for checksum
    if (paddingNeeded > 0) {
      writer.writeBytes(List<int>.filled(paddingNeeded, 0));
    }

    // Calculate and write checksum
    final nodeBytes = writer.bytes.sublist(nodeStart);
    final checksum = _calculateChecksum(nodeBytes);
    writer.writeUint32(checksum);
  }

  /// Write a chunk record
  void _writeChunkRecord(ByteWriter writer, BTreeV2ChunkEntry entry) {
    // Chunk size (4 bytes)
    writer.writeUint32(entry.chunkSize);

    // Filter mask (4 bytes)
    writer.writeUint32(entry.filterMask);

    // Chunk coordinates (8 bytes each, scaled)
    for (final coord in entry.chunkCoordinates) {
      writer.writeUint64(coord);
    }

    // Chunk address
    _writeOffset(writer, entry.chunkAddress);
  }

  /// Write an offset value based on the offset size
  void _writeOffset(ByteWriter writer, int value) {
    switch (offsetSize) {
      case 2:
        writer.writeUint16(value);
        break;
      case 4:
        writer.writeUint32(value);
        break;
      case 8:
        writer.writeUint64(value);
        break;
      default:
        throw ArgumentError('Unsupported offset size: $offsetSize');
    }
  }

  /// Calculate Jenkins lookup3 hash (used for HDF5 checksums)
  ///
  /// This is a simplified version of the lookup3 hash algorithm.
  /// HDF5 uses this for B-tree v2 node checksums.
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
}
