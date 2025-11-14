import 'byte_reader.dart';
import 'hdf5_error.dart';

/// Information about a chunk location and size
class ChunkInfo {
  final int address;
  final int size;
  final int filterMask;

  ChunkInfo({
    required this.address,
    required this.size,
    required this.filterMask,
  });
}

/// Cached B-tree node data
class _BTreeNode {
  final int nodeType;
  final int nodeLevel;
  final int entriesUsed;
  final List<List<int>> keys;
  final List<int> childAddresses;
  final List<ChunkInfo>? leafChunks; // For leaf nodes

  _BTreeNode({
    required this.nodeType,
    required this.nodeLevel,
    required this.entriesUsed,
    required this.keys,
    required this.childAddresses,
    this.leafChunks,
  });
}

/// B-tree version 1 for chunk indexing
/// Used to locate chunks in chunked datasets
class BTreeV1 {
  final int address;
  final ByteReader reader;
  final int dimensionality;
  final int offsetSize;
  final String? filePath;
  final String? objectPath;

  // Cache for B-tree nodes to minimize file seeks
  final Map<int, _BTreeNode> _nodeCache = {};

  BTreeV1({
    required this.address,
    required this.reader,
    required this.dimensionality,
    required this.offsetSize,
    this.filePath,
    this.objectPath,
  });

  /// Finds the chunk information given its chunk indices
  /// Chunk indices are the position of the chunk in the dataset (e.g., [0], [1], [2] for 1D)
  /// The B-tree stores scaled coordinates (chunk_index * chunk_size)
  /// Returns null if the chunk is not found
  Future<ChunkInfo?> findChunkInfo(List<int> chunkIndices,
      List<int> chunkDimensions, int elementSize) async {
    // Calculate scaled coordinates for B-tree lookup
    // The B-tree stores: chunk_index * chunk_size (NOT * element_size)
    final scaledCoords = <int>[];
    for (int i = 0; i < chunkIndices.length; i++) {
      scaledCoords.add(chunkIndices[i] * chunkDimensions[i]);
    }

    // The B-tree always has an extra dimension for element size
    // Add a zero coordinate for the element size dimension
    scaledCoords.add(0);

    hdf5DebugLog(
        'Finding chunk at indices: $chunkIndices, scaled coords: $scaledCoords, btree dims: $dimensionality');
    return await _traverseNode(address, scaledCoords);
  }

  /// Finds the address of a chunk given its chunk indices (legacy method)
  /// Chunk indices are the position of the chunk in the dataset (e.g., [0], [1], [2] for 1D)
  /// The B-tree stores scaled coordinates (chunk_index * chunk_size * element_size)
  /// Returns null if the chunk is not found
  Future<int?> findChunkAddress(List<int> chunkIndices,
      List<int> chunkDimensions, int elementSize) async {
    final chunkInfo =
        await findChunkInfo(chunkIndices, chunkDimensions, elementSize);
    return chunkInfo?.address;
  }

  /// Recursively traverses the B-tree to find a chunk
  Future<ChunkInfo?> _traverseNode(
      int nodeAddress, List<int> chunkCoords) async {
    // Check cache first
    if (_nodeCache.containsKey(nodeAddress)) {
      final cachedNode = _nodeCache[nodeAddress]!;
      hdf5DebugLog(
          'Using cached B-tree node at 0x${nodeAddress.toRadixString(16)}');

      if (cachedNode.nodeLevel == 0) {
        // Leaf node - search in cached chunks
        return _searchCachedLeafNode(cachedNode, chunkCoords);
      } else {
        // Internal node - traverse to child
        return await _searchCachedInternalNode(cachedNode, chunkCoords);
      }
    }

    // Not in cache, read from file
    reader.seek(nodeAddress);

    // Read node signature
    final signature = String.fromCharCodes(await reader.readBytes(4));
    if (signature != 'TREE') {
      throw CorruptedFileError(
        filePath: filePath,
        objectPath: objectPath,
        reason: 'Invalid B-tree node signature',
        details:
            'Expected "TREE", got "$signature" at address 0x${nodeAddress.toRadixString(16)}',
      );
    }

    // Read node type
    final nodeType = await reader.readUint8();
    final nodeLevel = await reader.readUint8();

    // Read number of entries
    final entriesUsed = await reader.readUint16();

    // Read left and right sibling addresses using the file's offset size
    final leftSiblingAddress = await _readOffset();
    final rightSiblingAddress = await _readOffset();

    hdf5DebugLog(
      'B-tree node: type=$nodeType, level=$nodeLevel, entries=$entriesUsed, '
      'left=0x${leftSiblingAddress.toRadixString(16)}, '
      'right=0x${rightSiblingAddress.toRadixString(16)}',
    );

    if (nodeType != 1) {
      throw UnsupportedFeatureError(
        filePath: filePath,
        objectPath: objectPath,
        feature: 'B-tree node type $nodeType',
        details: 'Only chunked raw data B-trees (type 1) are supported',
      );
    }

    // Read entries based on node level
    if (nodeLevel == 0) {
      // Leaf node - contains chunk keys and addresses
      return await _searchLeafNode(entriesUsed, chunkCoords, nodeAddress);
    } else {
      // Internal node - contains keys and child pointers
      return await _searchInternalNode(
          entriesUsed, nodeLevel, chunkCoords, nodeAddress);
    }
  }

  /// Searches a leaf node for the chunk
  Future<ChunkInfo?> _searchLeafNode(
      int entriesUsed, List<int> chunkCoords, int nodeAddress) async {
    final keys = <List<int>>[];
    final chunks = <ChunkInfo>[];

    for (int i = 0; i < entriesUsed; i++) {
      // Read key (chunk size + filter mask + chunk coordinates)
      final chunkSize = await reader.readUint32();
      final filterMask = await reader.readUint32();

      // Read chunk coordinates (scaled)
      final keyCoords = <int>[];
      for (int d = 0; d < dimensionality; d++) {
        keyCoords.add((await reader.readUint64()).toInt());
      }

      // Read chunk address using the file's offset size
      final chunkAddress = await _readOffset();

      hdf5DebugLog(
        'Leaf entry $i: coords=$keyCoords, address=0x${chunkAddress.toRadixString(16)}, '
        'size=$chunkSize, filterMask=$filterMask',
      );

      keys.add(keyCoords);
      chunks.add(ChunkInfo(
        address: chunkAddress,
        size: chunkSize,
        filterMask: filterMask,
      ));
    }

    // Cache the leaf node
    _nodeCache[nodeAddress] = _BTreeNode(
      nodeType: 1,
      nodeLevel: 0,
      entriesUsed: entriesUsed,
      keys: keys,
      childAddresses: [],
      leafChunks: chunks,
    );

    // Search for matching chunk
    for (int i = 0; i < keys.length; i++) {
      if (_coordsMatch(keys[i], chunkCoords)) {
        hdf5DebugLog(
            'Found matching chunk at address 0x${chunks[i].address.toRadixString(16)}, size=${chunks[i].size}');
        return chunks[i];
      }
    }

    return null;
  }

  /// Searches a cached leaf node for the chunk
  ChunkInfo? _searchCachedLeafNode(_BTreeNode node, List<int> chunkCoords) {
    for (int i = 0; i < node.keys.length; i++) {
      if (_coordsMatch(node.keys[i], chunkCoords)) {
        final chunk = node.leafChunks![i];
        hdf5DebugLog(
            'Found matching chunk in cache at address 0x${chunk.address.toRadixString(16)}, size=${chunk.size}');
        return chunk;
      }
    }
    return null;
  }

  /// Searches an internal node and recursively traverses to children
  Future<ChunkInfo?> _searchInternalNode(
    int entriesUsed,
    int nodeLevel,
    List<int> chunkCoords,
    int nodeAddress,
  ) async {
    // Read all keys and child pointers
    final keys = <List<int>>[];
    final childAddresses = <int>[];

    for (int i = 0; i < entriesUsed; i++) {
      // Read key (chunk size + chunk coordinates)
      await reader.readUint32(); // chunkSize
      await reader.readUint32(); // filterMask

      // Read chunk coordinates
      final keyCoords = <int>[];
      for (int d = 0; d < dimensionality; d++) {
        keyCoords.add((await reader.readUint64()).toInt());
      }

      keys.add(keyCoords);

      // Read child address using the file's offset size
      final childAddress = await _readOffset();
      childAddresses.add(childAddress);

      hdf5DebugLog(
        'Internal entry $i: coords=$keyCoords, child=0x${childAddress.toRadixString(16)}',
      );
    }

    // Cache the internal node
    _nodeCache[nodeAddress] = _BTreeNode(
      nodeType: 1,
      nodeLevel: nodeLevel,
      entriesUsed: entriesUsed,
      keys: keys,
      childAddresses: childAddresses,
    );

    // Find the appropriate child to traverse
    return await _findAndTraverseChild(keys, childAddresses, chunkCoords);
  }

  /// Searches a cached internal node and traverses to child
  Future<ChunkInfo?> _searchCachedInternalNode(
      _BTreeNode node, List<int> chunkCoords) async {
    return await _findAndTraverseChild(
        node.keys, node.childAddresses, chunkCoords);
  }

  /// Finds the appropriate child and traverses to it
  Future<ChunkInfo?> _findAndTraverseChild(
    List<List<int>> keys,
    List<int> childAddresses,
    List<int> chunkCoords,
  ) async {
    // Keys in internal nodes represent the minimum key in each subtree
    int childIndex = 0;
    for (int i = 0; i < keys.length; i++) {
      if (_coordsLessThanOrEqual(chunkCoords, keys[i])) {
        childIndex = i;
        break;
      }
      childIndex = i + 1;
    }

    // Ensure we don't go out of bounds
    if (childIndex >= childAddresses.length) {
      childIndex = childAddresses.length - 1;
    }

    hdf5DebugLog(
        'Traversing to child $childIndex at address 0x${childAddresses[childIndex].toRadixString(16)}');

    // Recursively traverse the child
    return await _traverseNode(childAddresses[childIndex], chunkCoords);
  }

  /// Checks if two coordinate lists match
  bool _coordsMatch(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Checks if coordinates a <= b (lexicographic comparison)
  bool _coordsLessThanOrEqual(List<int> a, List<int> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] < b[i]) return true;
      if (a[i] > b[i]) return false;
    }
    return true; // Equal
  }

  /// Reads an offset value based on the file's offset size
  Future<int> _readOffset() async {
    switch (offsetSize) {
      case 2:
        return await reader.readUint16();
      case 4:
        return await reader.readUint32();
      case 8:
        return (await reader.readUint64()).toInt();
      default:
        throw UnsupportedFeatureError(
          filePath: filePath,
          objectPath: objectPath,
          feature: 'Offset size $offsetSize',
          details: 'Only offset sizes 2, 4, and 8 are supported',
        );
    }
  }

  /// Clears the B-tree node cache
  void clearCache() {
    _nodeCache.clear();
  }

  /// Gets the number of cached nodes
  int get cachedNodeCount => _nodeCache.length;
}
