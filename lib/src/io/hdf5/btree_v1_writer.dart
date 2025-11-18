import 'byte_writer.dart';

/// Entry for a chunk in the B-tree v1 index
class BTreeV1ChunkEntry {
  final int chunkSize;
  final int filterMask;
  final List<int> chunkCoordinates; // Scaled coordinates
  final int chunkAddress;

  BTreeV1ChunkEntry({
    required this.chunkSize,
    required this.filterMask,
    required this.chunkCoordinates,
    required this.chunkAddress,
  });
}

/// Entry for a symbol table in the B-tree v1 index
class SymbolTableIndexEntry {
  final int nameHash;
  final int symbolTableNodeAddress;

  SymbolTableIndexEntry({
    required this.nameHash,
    required this.symbolTableNodeAddress,
  });
}

/// Internal representation of a B-tree node during construction
class _BTreeNode {
  final List<BTreeV1ChunkEntry>? entries; // For leaf nodes
  final List<_BTreeNode>? children; // For internal nodes
  final int level;
  final bool isLeaf;

  _BTreeNode({
    this.entries,
    this.children,
    required this.level,
    required this.isLeaf,
  }) {
    assert(isLeaf ? entries != null : children != null);
  }
}

/// Internal representation of a symbol table B-tree node during construction
class _SymbolTableBTreeNode {
  final List<SymbolTableIndexEntry>? entries; // For leaf nodes
  final List<_SymbolTableBTreeNode>? children; // For internal nodes
  final int level;
  final bool isLeaf;

  _SymbolTableBTreeNode({
    this.entries,
    this.children,
    required this.level,
    required this.isLeaf,
  }) {
    assert(isLeaf ? entries != null : children != null);
  }
}

/// Writer for B-tree version 1 structures
///
/// B-tree v1 is used for:
/// - Symbol table indexing (group objects)
/// - Chunked dataset indexing
///
/// This writer creates B-tree structures for efficient lookup of chunks
/// in chunked datasets.
class BTreeV1Writer {
  final int dimensionality;
  final int offsetSize;

  /// Maximum number of entries per node (typical value for HDF5)
  static const int maxEntriesPerNode = 16;

  BTreeV1Writer({
    required this.dimensionality,
    this.offsetSize = 8,
  });

  /// Write a B-tree index for chunked dataset
  ///
  /// Creates a B-tree v1 structure for looking up chunks by their coordinates.
  /// Implements proper B-tree splitting for large datasets with multiple nodes.
  ///
  /// Parameters:
  /// - [writer]: The ByteWriter to write to
  /// - [entries]: List of chunk entries to index
  ///
  /// Returns the address of the B-tree root node
  int writeChunkIndex(
    ByteWriter writer,
    List<BTreeV1ChunkEntry> entries,
  ) {
    if (entries.isEmpty) {
      throw ArgumentError('Cannot create B-tree with no entries');
    }

    // Sort entries by coordinates for proper B-tree ordering
    entries.sort(
        (a, b) => _compareCoordinates(a.chunkCoordinates, b.chunkCoordinates));

    // Build B-tree structure
    if (entries.length <= maxEntriesPerNode) {
      // Simple case: single leaf node
      final btreeAddress = writer.position;
      _writeLeafNode(writer, entries);
      return btreeAddress;
    } else {
      // Complex case: multiple nodes with internal nodes
      return _buildMultiLevelTree(writer, entries);
    }
  }

  /// Build a multi-level B-tree for large datasets
  int _buildMultiLevelTree(
    ByteWriter writer,
    List<BTreeV1ChunkEntry> entries,
  ) {
    // Split entries into leaf nodes
    final leafNodes = <_BTreeNode>[];
    for (int i = 0; i < entries.length; i += maxEntriesPerNode) {
      final end = (i + maxEntriesPerNode < entries.length)
          ? i + maxEntriesPerNode
          : entries.length;
      final nodeEntries = entries.sublist(i, end);
      leafNodes.add(_BTreeNode(
        entries: nodeEntries,
        level: 0,
        isLeaf: true,
      ));
    }

    // Build internal nodes level by level, tracking all nodes
    final allLevels = <List<_BTreeNode>>[leafNodes];
    var currentLevel = leafNodes;
    var level = 0;

    while (currentLevel.length > 1) {
      level++;
      final nextLevel = <_BTreeNode>[];

      for (int i = 0; i < currentLevel.length; i += maxEntriesPerNode) {
        final end = (i + maxEntriesPerNode < currentLevel.length)
            ? i + maxEntriesPerNode
            : currentLevel.length;
        final children = currentLevel.sublist(i, end);

        nextLevel.add(_BTreeNode(
          children: children,
          level: level,
          isLeaf: false,
        ));
      }

      allLevels.add(nextLevel);
      currentLevel = nextLevel;
    }

    // Write all nodes (bottom-up, left-to-right)
    final nodeAddresses = <_BTreeNode, int>{};

    // Write all levels
    for (final levelNodes in allLevels) {
      for (final node in levelNodes) {
        nodeAddresses[node] = writer.position;
        if (node.isLeaf) {
          _writeLeafNode(writer, node.entries!);
        } else {
          _writeInternalNode(writer, node, nodeAddresses);
        }
      }
    }

    // Return address of root node (first node in last level)
    return nodeAddresses[allLevels.last.first]!;
  }

  /// Write an internal (non-leaf) node
  void _writeInternalNode(
    ByteWriter writer,
    _BTreeNode node,
    Map<_BTreeNode, int> nodeAddresses,
  ) {
    // Write node signature
    writer.writeString('TREE', nullTerminate: false);

    // Node type: 1 = chunked raw data B-tree
    writer.writeUint8(1);

    // Node level
    writer.writeUint8(node.level);

    // Number of entries used
    writer.writeUint16(node.children!.length);

    // Left sibling address (undefined for now)
    _writeOffset(writer, 0xFFFFFFFFFFFFFFFF);

    // Right sibling address (undefined for now)
    _writeOffset(writer, 0xFFFFFFFFFFFFFFFF);

    // Write keys and child pointers
    for (int i = 0; i < node.children!.length; i++) {
      final child = node.children![i];

      // Key: first chunk coordinates from this child's subtree
      final key = child.isLeaf
          ? child.entries!.first.chunkCoordinates
          : child.children!.first.entries!.first.chunkCoordinates;

      for (final coord in key) {
        writer.writeUint64(coord);
      }

      // Child pointer
      _writeOffset(writer, nodeAddresses[child]!);
    }

    // Write final key (max key)
    final lastChild = node.children!.last;
    final lastKey = lastChild.isLeaf
        ? lastChild.entries!.last.chunkCoordinates
        : lastChild.children!.last.entries!.last.chunkCoordinates;

    for (final coord in lastKey) {
      writer.writeUint64(coord);
    }
  }

  /// Write a leaf node containing chunk entries
  void _writeLeafNode(
    ByteWriter writer,
    List<BTreeV1ChunkEntry> entries,
  ) {
    // Write node signature
    writer.writeString('TREE', nullTerminate: false);

    // Node type: 1 = chunked raw data B-tree
    writer.writeUint8(1);

    // Node level: 0 = leaf node
    writer.writeUint8(0);

    // Number of entries used
    writer.writeUint16(entries.length);

    // Left sibling address (undefined for single node)
    _writeOffset(writer, 0xFFFFFFFFFFFFFFFF);

    // Right sibling address (undefined for single node)
    _writeOffset(writer, 0xFFFFFFFFFFFFFFFF);

    // Write entries
    for (final entry in entries) {
      _writeChunkEntry(writer, entry);
    }
  }

  /// Write a single chunk entry
  void _writeChunkEntry(
    ByteWriter writer,
    BTreeV1ChunkEntry entry,
  ) {
    // Chunk size (4 bytes)
    writer.writeUint32(entry.chunkSize);

    // Filter mask (4 bytes)
    writer.writeUint32(entry.filterMask);

    // Chunk coordinates (8 bytes each)
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

  /// Compare two coordinate lists lexicographically
  int _compareCoordinates(List<int> a, List<int> b) {
    final minLen = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < minLen; i++) {
      if (a[i] < b[i]) return -1;
      if (a[i] > b[i]) return 1;
    }
    return a.length.compareTo(b.length);
  }

  /// Write a B-tree index for symbol table (group objects)
  ///
  /// Creates a B-tree v1 structure for looking up symbol table nodes by name hash.
  /// Supports large groups with 100+ objects through proper B-tree splitting.
  ///
  /// Parameters:
  /// - [writer]: The ByteWriter to write to
  /// - [entries]: List of symbol table entries to index
  /// - [symbolTableNodeAddresses]: Map of entry index to symbol table node address
  ///
  /// Returns the address of the B-tree root node
  int writeSymbolTableIndex(
    ByteWriter writer,
    List<SymbolTableIndexEntry> entries,
  ) {
    if (entries.isEmpty) {
      throw ArgumentError('Cannot create B-tree with no entries');
    }

    // Sort entries by name hash for proper B-tree ordering
    entries.sort((a, b) => a.nameHash.compareTo(b.nameHash));

    // Build B-tree structure
    if (entries.length <= maxEntriesPerNode) {
      // Simple case: single leaf node
      final btreeAddress = writer.position;
      _writeSymbolTableLeafNode(writer, entries);
      return btreeAddress;
    } else {
      // Complex case: multiple nodes with internal nodes
      return _buildSymbolTableMultiLevelTree(writer, entries);
    }
  }

  /// Build a multi-level B-tree for large symbol tables
  int _buildSymbolTableMultiLevelTree(
    ByteWriter writer,
    List<SymbolTableIndexEntry> entries,
  ) {
    // Split entries into leaf nodes
    final leafNodes = <_SymbolTableBTreeNode>[];
    for (int i = 0; i < entries.length; i += maxEntriesPerNode) {
      final end = (i + maxEntriesPerNode < entries.length)
          ? i + maxEntriesPerNode
          : entries.length;
      final nodeEntries = entries.sublist(i, end);
      leafNodes.add(_SymbolTableBTreeNode(
        entries: nodeEntries,
        level: 0,
        isLeaf: true,
      ));
    }

    // Build internal nodes level by level, tracking all nodes
    final allLevels = <List<_SymbolTableBTreeNode>>[leafNodes];
    var currentLevel = leafNodes;
    var level = 0;

    while (currentLevel.length > 1) {
      level++;
      final nextLevel = <_SymbolTableBTreeNode>[];

      for (int i = 0; i < currentLevel.length; i += maxEntriesPerNode) {
        final end = (i + maxEntriesPerNode < currentLevel.length)
            ? i + maxEntriesPerNode
            : currentLevel.length;
        final children = currentLevel.sublist(i, end);

        nextLevel.add(_SymbolTableBTreeNode(
          children: children,
          level: level,
          isLeaf: false,
        ));
      }

      allLevels.add(nextLevel);
      currentLevel = nextLevel;
    }

    // Write all nodes (bottom-up, left-to-right)
    final nodeAddresses = <_SymbolTableBTreeNode, int>{};

    // Write all levels
    for (final levelNodes in allLevels) {
      for (final node in levelNodes) {
        nodeAddresses[node] = writer.position;
        if (node.isLeaf) {
          _writeSymbolTableLeafNode(writer, node.entries!);
        } else {
          _writeSymbolTableInternalNode(writer, node, nodeAddresses);
        }
      }
    }

    // Return address of root node (first node in last level)
    return nodeAddresses[allLevels.last.first]!;
  }

  /// Write a symbol table leaf node
  void _writeSymbolTableLeafNode(
    ByteWriter writer,
    List<SymbolTableIndexEntry> entries,
  ) {
    // Write node signature
    writer.writeString('TREE', nullTerminate: false);

    // Node type: 0 = group/symbol table B-tree
    writer.writeUint8(0);

    // Node level: 0 = leaf node
    writer.writeUint8(0);

    // Number of entries used
    writer.writeUint16(entries.length);

    // Left sibling address (undefined for now)
    _writeOffset(writer, 0xFFFFFFFFFFFFFFFF);

    // Right sibling address (undefined for now)
    _writeOffset(writer, 0xFFFFFFFFFFFFFFFF);

    // Write keys and child pointers
    for (final entry in entries) {
      // Key: name hash
      writer.writeUint64(entry.nameHash);

      // Child pointer: symbol table node address
      _writeOffset(writer, entry.symbolTableNodeAddress);
    }

    // Write final key (max hash value)
    writer.writeUint64(entries.last.nameHash);
  }

  /// Write a symbol table internal node
  void _writeSymbolTableInternalNode(
    ByteWriter writer,
    _SymbolTableBTreeNode node,
    Map<_SymbolTableBTreeNode, int> nodeAddresses,
  ) {
    // Write node signature
    writer.writeString('TREE', nullTerminate: false);

    // Node type: 0 = group/symbol table B-tree
    writer.writeUint8(0);

    // Node level
    writer.writeUint8(node.level);

    // Number of entries used
    writer.writeUint16(node.children!.length);

    // Left sibling address (undefined for now)
    _writeOffset(writer, 0xFFFFFFFFFFFFFFFF);

    // Right sibling address (undefined for now)
    _writeOffset(writer, 0xFFFFFFFFFFFFFFFF);

    // Write keys and child pointers
    for (int i = 0; i < node.children!.length; i++) {
      final child = node.children![i];

      // Key: minimum hash from this child's subtree
      final key = child.isLeaf
          ? child.entries!.first.nameHash
          : child.children!.first.entries!.first.nameHash;

      writer.writeUint64(key);

      // Child pointer
      _writeOffset(writer, nodeAddresses[child]!);
    }

    // Write final key (max hash)
    final lastChild = node.children!.last;
    final lastKey = lastChild.isLeaf
        ? lastChild.entries!.last.nameHash
        : lastChild.children!.last.entries!.last.nameHash;

    writer.writeUint64(lastKey);
  }

  /// Calculate hash for a symbol name (used for B-tree indexing)
  ///
  /// Uses the same hash algorithm as HDF5 for compatibility
  static int calculateNameHash(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = ((hash << 4) + name.codeUnitAt(i)) & 0xFFFFFFFFFFFFFFFF;
      final g = hash & 0xF000000000000000;
      if (g != 0) {
        hash ^= g >> 56;
        hash ^= g;
      }
    }
    return hash;
  }
}
