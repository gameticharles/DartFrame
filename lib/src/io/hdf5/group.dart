import 'dart:typed_data';
import 'byte_reader.dart';
import 'object_header.dart';
import 'attribute.dart';
import 'hdf5_error.dart';
import 'fractal_heap.dart';
import 'btree_v2.dart';

/// Symbol table entry for group navigation
class SymbolTableEntry {
  final int linkNameOffset;
  final int objectHeaderAddress;

  SymbolTableEntry({
    required this.linkNameOffset,
    required this.objectHeaderAddress,
  });

  static Future<SymbolTableEntry> read(ByteReader reader) async {
    return SymbolTableEntry(
      linkNameOffset: await reader.readUint64(),
      objectHeaderAddress: await reader.readUint64(),
    );
  }
}

/// HDF5 group containing datasets and other groups
class Group {
  final int address;
  final ObjectHeader header;
  final Map<String, int> _childAddresses = {};
  final Map<String, LinkMessage> _linkMessages = {}; // Store link messages
  int? _heapDataSegmentAddress;
  int _hdf5Offset = 0; // Store the HDF5 offset for address calculations
  String? _filePath; // Store file path for error reporting

  Group({required this.address, required this.header});

  static Future<Group> read(ByteReader reader, int address,
      {int hdf5Offset = 0, String? filePath}) async {
    hdf5DebugLog('Reading group at address 0x${address.toRadixString(16)}');
    final header = await ObjectHeader.read(reader, address,
        filePath: filePath, hdf5Offset: hdf5Offset);
    final group = Group(address: address, header: header);
    group._hdf5Offset = hdf5Offset;
    group._filePath = filePath;

    // Parse link messages (new-style links)
    final linkMessages = header.findLinks();
    for (final link in linkMessages) {
      group._linkMessages[link.linkName] = link;
      if (link.isHardLink && link.objectHeaderAddress != null) {
        // Store hard link addresses directly
        group._childAddresses[link.linkName] = link.objectHeaderAddress!;
      }
      // Soft and external links are resolved on-demand
    }

    // Try new-style link info first
    final linkInfoMsg = header.messages.firstWhere(
      (m) => m.type == MessageType.linkInfo,
      orElse: () =>
          ObjectHeaderMessage(type: MessageType.nil, size: 0, flags: 0),
    );

    if (linkInfoMsg.data != null) {
      await group._loadChildrenFromLinkInfo(
          reader, linkInfoMsg.data as LinkInfo);
    }

    // Try old-style symbol table
    final symbolTableMsg = header.findSymbolTable();
    if (symbolTableMsg != null) {
      await group._loadChildrenFromSymbolTable(reader, symbolTableMsg);
    }

    return group;
  }

  Future<void> _loadChildrenFromLinkInfo(
      ByteReader reader, LinkInfo linkInfo) async {
    if (linkInfo.fractalHeapAddress != 0) {
      try {
        // Adjust fractal heap address by HDF5 offset
        final adjustedHeapAddress = linkInfo.fractalHeapAddress + _hdf5Offset;

        hdf5DebugLog(
            'Loading links from fractal heap at 0x${adjustedHeapAddress.toRadixString(16)}');

        // Read fractal heap
        final heap = await FractalHeap.read(reader, adjustedHeapAddress);

        // If there's a B-tree for name indexing, use it
        if (linkInfo.v2BtreeAddress != 0) {
          final adjustedBtreeAddress = linkInfo.v2BtreeAddress + _hdf5Offset;
          await _loadLinksFromBTree(reader, heap, adjustedBtreeAddress);
        } else {
          // Try to read links directly from heap (less common)
          hdf5DebugLog(
              'No B-tree index, links stored directly in fractal heap');
        }
      } catch (e) {
        hdf5DebugLog('Failed to load links from fractal heap: $e');
        // Fall back to old-style loading if fractal heap fails
      }
    }
  }

  Future<void> _loadLinksFromBTree(
      ByteReader reader, FractalHeap heap, int btreeAddress) async {
    try {
      hdf5DebugLog('Reading V2 B-tree at 0x${btreeAddress.toRadixString(16)}');
      final btree = await BTreeV2.read(reader, btreeAddress);
      final records = await btree.readAllRecords(reader);

      hdf5DebugLog('Found ${records.length} link records in B-tree');

      for (final record in records) {
        try {
          // Read link message from fractal heap
          final linkData = await heap.readObject(reader, record.heapId);

          // Parse link message from the data
          final linkMessage = await _parseLinkMessageFromData(linkData);

          if (linkMessage != null) {
            _linkMessages[linkMessage.linkName] = linkMessage;
            if (linkMessage.isHardLink &&
                linkMessage.objectHeaderAddress != null) {
              _childAddresses[linkMessage.linkName] =
                  linkMessage.objectHeaderAddress!;
            }
            hdf5DebugLog(
                'Loaded link: ${linkMessage.linkName} (${linkMessage.linkType})');
          }
        } catch (e) {
          hdf5DebugLog('Failed to read link from heap: $e');
        }
      }
    } catch (e) {
      hdf5DebugLog('Failed to read B-tree: $e');
    }
  }

  Future<LinkMessage?> _parseLinkMessageFromData(List<int> data) async {
    if (data.isEmpty) return null;

    try {
      final reader = ByteReader.fromBytes(Uint8List.fromList(data));

      final version = await reader.readUint8();
      if (version != 1) {
        hdf5DebugLog('Unsupported link message version: $version');
        return null;
      }

      final flags = await reader.readUint8();
      final linkType = (flags & 0x03);

      // Read creation order if present
      if ((flags >> 3) & 0x01 == 1) {
        await reader.readUint64();
      }

      // Determine link type
      LinkType type;
      if (linkType == 0) {
        type = LinkType.hard;
      } else if (linkType == 1) {
        type = LinkType.soft;
      } else if (linkType == 64 || linkType == 2) {
        type = LinkType.external;
      } else {
        hdf5DebugLog('Unknown link type: $linkType');
        return null;
      }

      // Read link name length
      final linkNameLength = await reader.readUint16();

      // Read link name
      final linkNameBytes = await reader.readBytes(linkNameLength);
      final linkName = String.fromCharCodes(linkNameBytes);

      // Read link information based on type
      int? objectHeaderAddress;
      String? targetPath;
      String? externalFilePath;
      String? externalObjectPath;

      if (type == LinkType.hard) {
        objectHeaderAddress = (await reader.readUint64()).toInt();
      } else if (type == LinkType.soft) {
        final targetPathLength = await reader.readUint16();
        final targetPathBytes = await reader.readBytes(targetPathLength);
        targetPath = String.fromCharCodes(targetPathBytes);
      } else if (type == LinkType.external) {
        final externalInfoLength = await reader.readUint16();
        final externalInfoBytes = await reader.readBytes(externalInfoLength);

        int nullIndex = externalInfoBytes.indexOf(0);
        if (nullIndex >= 0) {
          externalFilePath =
              String.fromCharCodes(externalInfoBytes.sublist(0, nullIndex));
          if (nullIndex + 1 < externalInfoBytes.length) {
            final objectPathBytes = externalInfoBytes.sublist(nullIndex + 1);
            final objectPathEnd = objectPathBytes.indexOf(0);
            if (objectPathEnd >= 0) {
              externalObjectPath = String.fromCharCodes(
                  objectPathBytes.sublist(0, objectPathEnd));
            } else {
              externalObjectPath = String.fromCharCodes(objectPathBytes);
            }
          }
        }
      }

      return LinkMessage(
        version: version,
        linkType: type,
        linkName: linkName,
        objectHeaderAddress: objectHeaderAddress,
        targetPath: targetPath,
        externalFilePath: externalFilePath,
        externalObjectPath: externalObjectPath,
      );
    } catch (e) {
      hdf5DebugLog('Failed to parse link message: $e');
      return null;
    }
  }

  Future<void> _loadChildrenFromSymbolTable(
      ByteReader reader, SymbolTableMessage symbolTable) async {
    // Adjust heap address by HDF5 offset
    final adjustedHeapAddress =
        symbolTable.localHeapAddress.toInt() + _hdf5Offset;

    // Read heap header once to get data segment address
    _heapDataSegmentAddress =
        await _getHeapDataSegmentAddress(reader, adjustedHeapAddress);

    // Adjust B-tree address by HDF5 offset
    final adjustedBtreeAddress = symbolTable.btreeAddress.toInt() + _hdf5Offset;

    // Read B-tree to get symbol table nodes
    await _readBTree(reader, adjustedBtreeAddress);
  }

  Future<int> _getHeapDataSegmentAddress(
      ByteReader reader, int heapAddress) async {
    final savedPos = reader.position;
    reader.seek(heapAddress);

    // Check signature
    final sig = await reader.readBytes(4);
    final sigStr = String.fromCharCodes(sig);
    if (sigStr != 'HEAP') {
      throw InvalidSignatureError(
        filePath: _filePath,
        structureType: 'local heap',
        expected: 'HEAP',
        actual: sigStr,
        address: heapAddress,
      );
    }

    await reader.readUint8(); // version
    await reader.readBytes(3); // reserved
    await reader.readUint64(); // dataSegmentSize
    await reader.readUint64(); // offsetToHeadFreeList
    final addressOfDataSegment = await reader.readUint64();

    reader.seek(savedPos);
    // Also adjust the data segment address by HDF5 offset
    return addressOfDataSegment.toInt() + _hdf5Offset;
  }

  Future<void> _readBTree(ByteReader reader, int btreeAddress) async {
    final savedPos = reader.position;
    reader.seek(btreeAddress);

    // Read B-tree node signature
    final sig = await reader.readBytes(4);
    final sigStr = String.fromCharCodes(sig);

    if (sigStr != 'TREE') {
      throw InvalidSignatureError(
        filePath: _filePath,
        structureType: 'B-tree',
        expected: 'TREE',
        actual: sigStr,
        address: btreeAddress,
      );
    }

    await reader.readUint8(); // nodeType
    final nodeLevel = await reader.readUint8();
    final entriesUsed = await reader.readUint16();

    // Skip left and right sibling addresses
    await reader.readUint64();
    await reader.readUint64();

    // For leaf nodes (level 0), read keys and child pointers
    for (int i = 0; i < entriesUsed; i++) {
      await reader.readUint64(); // key
      final childPointer =
          await reader.readUint64(); // Symbol table node address

      // Read symbol table node - adjust address by HDF5 offset
      if (nodeLevel == 0) {
        final adjustedChildPointer = childPointer.toInt() + _hdf5Offset;
        await _readSymbolTableNode(reader, adjustedChildPointer);
      }
    }

    reader.seek(savedPos);
  }

  Future<void> _readSymbolTableNode(ByteReader reader, int nodeAddress) async {
    final savedPos = reader.position;
    reader.seek(nodeAddress);

    // Read symbol table node signature
    final sig = await reader.readBytes(4);
    final sigStr = String.fromCharCodes(sig);

    if (sigStr != 'SNOD') {
      throw InvalidSignatureError(
        filePath: _filePath,
        structureType: 'symbol table node',
        expected: 'SNOD',
        actual: sigStr,
        address: nodeAddress,
      );
    }

    await reader.readUint8(); // version
    await reader.readUint8(); // reserved
    final numSymbols = await reader.readUint16();

    // Read symbol table entries
    for (int i = 0; i < numSymbols; i++) {
      final linkNameOffset = await reader.readUint64();
      final objectHeaderAddress = await reader.readUint64();
      await reader.readUint32(); // cacheType
      await reader.readBytes(4); // reserved
      await reader.readBytes(16); // scratch space

      // Read name from heap
      if (linkNameOffset > 0 && objectHeaderAddress > 0) {
        final name = await _readNameFromHeap(reader, linkNameOffset.toInt());
        // Store the raw address (without offset) since it will be adjusted when used
        _childAddresses[name] = objectHeaderAddress.toInt();
      }
    }

    reader.seek(savedPos);
  }

  Future<String> _readNameFromHeap(ByteReader reader, int nameOffset) async {
    if (_heapDataSegmentAddress == null) {
      throw CorruptedFileError(
        filePath: _filePath,
        reason: 'Heap data segment address not initialized',
        details: 'This may indicate a corrupted group structure',
      );
    }

    final savedPos = reader.position;

    // Read name from data segment
    reader.seek(_heapDataSegmentAddress! + nameOffset);
    final buffer = <int>[];

    int maxLength = 1000; // Safety limit
    while (buffer.length < maxLength) {
      final byte = await reader.readUint8();
      if (byte == 0) break;
      buffer.add(byte);
    }

    reader.seek(savedPos);
    return String.fromCharCodes(buffer);
  }

  List<String> get children {
    // Combine children from addresses and link messages
    final allChildren = <String>{};
    allChildren.addAll(_childAddresses.keys);
    allChildren.addAll(_linkMessages.keys);
    return allChildren.toList();
  }

  int? getChildAddress(String name) => _childAddresses[name];

  /// Gets the link message for a child, if it exists
  LinkMessage? getLinkMessage(String name) => _linkMessages[name];

  /// Checks if a child is a soft link
  bool isSoftLink(String name) {
    final link = _linkMessages[name];
    return link != null && link.isSoftLink;
  }

  /// Checks if a child is an external link
  bool isExternalLink(String name) {
    final link = _linkMessages[name];
    return link != null && link.isExternalLink;
  }

  /// Checks if a child is a hard link
  bool isHardLink(String name) {
    final link = _linkMessages[name];
    return link != null && link.isHardLink;
  }

  /// Gets information about a link
  ///
  /// Returns a map containing:
  /// - `type`: 'hard', 'soft', or 'external'
  /// - `target`: target path for soft links
  /// - `externalFile`: external file path for external links
  /// - `externalPath`: external object path for external links
  /// - `address`: object header address for hard links
  Map<String, dynamic>? getLinkInfo(String name) {
    final link = _linkMessages[name];
    if (link == null) return null;

    final info = <String, dynamic>{
      'type': link.linkType.toString().split('.').last,
    };

    if (link.isSoftLink) {
      info['target'] = link.targetPath;
    } else if (link.isExternalLink) {
      info['externalFile'] = link.externalFilePath;
      info['externalPath'] = link.externalObjectPath;
    } else if (link.isHardLink) {
      info['address'] = link.objectHeaderAddress;
    }

    return info;
  }

  /// List all attribute names for this group
  List<String> listAttributes() {
    return header.findAttributes().map((attr) => attr.name).toList();
  }

  /// Get attribute by name
  /// Returns null if attribute not found
  Hdf5Attribute? getAttribute(String name) {
    try {
      return header.findAttributes().firstWhere((attr) => attr.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get all attributes for this group
  List<Hdf5Attribute> get attributes => header.findAttributes();

  /// Inspect group metadata without reading child data
  ///
  /// Returns a map containing:
  /// - `childCount`: Number of children (datasets and groups)
  /// - `children`: List of child names
  /// - `links`: Map of link names to link information (if any links exist)
  /// - `attributes`: Map of attribute names to values
  ///
  /// Example:
  /// ```dart
  /// final info = group.inspect();
  /// print('Children: ${info['childCount']}');
  /// print('Names: ${info['children']}');
  /// ```
  Map<String, dynamic> inspect() {
    final allChildren = children;
    final info = <String, dynamic>{
      'childCount': allChildren.length,
      'children': allChildren,
    };

    // Add link information if any links exist
    if (_linkMessages.isNotEmpty) {
      final links = <String, dynamic>{};
      for (final entry in _linkMessages.entries) {
        links[entry.key] = getLinkInfo(entry.key);
      }
      info['links'] = links;
    }

    // Add attributes
    final attrs = <String, dynamic>{};
    for (final attr in attributes) {
      attrs[attr.name] = attr.value;
    }
    if (attrs.isNotEmpty) {
      info['attributes'] = attrs;
    }

    return info;
  }

  /// Inspect internal HDF5 structures used by this group (for debugging)
  ///
  /// Returns a map containing internal structure information:
  /// - `linkInfo`: LinkInfo message data (if present)
  /// - `fractalHeap`: FractalHeap information (if used for links)
  /// - `btreeV2`: B-Tree V2 information (if used for indexing)
  /// - `symbolTable`: Symbol table information (for old-style groups)
  ///
  /// This is primarily useful for debugging, understanding HDF5 file structure,
  /// or implementing advanced HDF5 features.
  ///
  /// Example:
  /// ```dart
  /// final internal = await group.inspectInternalStructures(reader);
  /// if (internal.containsKey('fractalHeap')) {
  ///   print('Fractal Heap: ${internal['fractalHeap']}');
  /// }
  /// ```
  Future<Map<String, dynamic>> inspectInternalStructures(
      ByteReader reader) async {
    final info = <String, dynamic>{};

    // Check for LinkInfo (new-style groups)
    final linkInfoMsg = header.messages.firstWhere(
      (m) => m.type == MessageType.linkInfo,
      orElse: () =>
          ObjectHeaderMessage(type: MessageType.nil, size: 0, flags: 0),
    );

    if (linkInfoMsg.data != null) {
      final linkInfo = linkInfoMsg.data as LinkInfo;
      info['linkInfo'] = {
        'version': linkInfo.version,
        'maximumCreationIndex': linkInfo.maximumCreationIndex,
        'fractalHeapAddress':
            '0x${linkInfo.fractalHeapAddress.toRadixString(16)}',
        'v2BtreeAddress': '0x${linkInfo.v2BtreeAddress.toRadixString(16)}',
      };

      // Read FractalHeap if present
      if (linkInfo.fractalHeapAddress != 0) {
        try {
          final adjustedHeapAddress = linkInfo.fractalHeapAddress + _hdf5Offset;
          final heap = await FractalHeap.read(reader, adjustedHeapAddress);
          info['fractalHeap'] = {
            'address': '0x${heap.address.toRadixString(16)}',
            'version': heap.version,
            'heapIdLength': heap.heapIdLength,
            'maxHeapSize': heap.maxHeapSize,
            'startingBlockSize': heap.startingBlockSize,
            'maxDirectBlockSize': heap.maxDirectBlockSize,
            'tableWidth': heap.tableWidth,
            'startingNumRows': heap.startingNumRows,
            'currentNumRows': heap.currentNumRows,
            'rootBlockAddress': '0x${heap.rootBlockAddress.toRadixString(16)}',
            // Flags
            'idWrapped': heap.idWrapped,
            'directBlocksChecksummed': heap.directBlocksChecksummed,
            // Object counts
            'numManagedObjectsInHeap': heap.numManagedObjectsInHeap,
            'numHugeObjectsInHeap': heap.numHugeObjectsInHeap,
            'numTinyObjectsInHeap': heap.numTinyObjectsInHeap,
            // Size tracking
            'maxSizeOfManagedObjects': heap.maxSizeOfManagedObjects,
            'sizeOfHugeObjectsInHeap': heap.sizeOfHugeObjectsInHeap,
            'sizeOfTinyObjectsInHeap': heap.sizeOfTinyObjectsInHeap,
            // Space management
            'amountOfFreeSpaceInManagedBlocks':
                heap.amountOfFreeSpaceInManagedBlocks,
            'amountOfManagedSpaceInHeap': heap.amountOfManagedSpaceInHeap,
            'amountOfAllocatedManagedSpaceInHeap':
                heap.amountOfAllocatedManagedSpaceInHeap,
            // Advanced
            'nextHugeObjectId': heap.nextHugeObjectId,
            'offsetOfDirectBlockAllocationIterator':
                heap.offsetOfDirectBlockAllocationIterator,
            'btreeAddressOfHugeObjects':
                '0x${heap.btreeAddressOfHugeObjects.toRadixString(16)}',
            'addressOfManagedBlockFreeSpaceManager':
                '0x${heap.addressOfManagedBlockFreeSpaceManager.toRadixString(16)}',
          };
        } catch (e) {
          info['fractalHeapError'] = e.toString();
        }
      }

      // Read BTreeV2 if present
      if (linkInfo.v2BtreeAddress != 0) {
        try {
          final adjustedBtreeAddress = linkInfo.v2BtreeAddress + _hdf5Offset;
          final btree = await BTreeV2.read(reader, adjustedBtreeAddress);
          info['btreeV2'] = {
            'address': '0x${btree.address.toRadixString(16)}',
            'version': btree.version,
            'type': btree.type,
            'nodeSize': btree.nodeSize,
            'recordSize': btree.recordSize,
            'depth': btree.depth,
            'rootNodeAddress': '0x${btree.rootNodeAddress.toRadixString(16)}',
            'numRecordsInRoot': btree.numRecordsInRoot,
            // Split/merge thresholds
            'splitPercent': btree.splitPercent,
            'mergePercent': btree.mergePercent,
            // Total records
            'totalNumRecords': btree.totalNumRecords,
          };
        } catch (e) {
          info['btreeV2Error'] = e.toString();
        }
      }
    }

    // Check for SymbolTable (old-style groups)
    final symbolTableMsg = header.messages.firstWhere(
      (m) => m.type == MessageType.symbolTable,
      orElse: () =>
          ObjectHeaderMessage(type: MessageType.nil, size: 0, flags: 0),
    );

    if (symbolTableMsg.data != null) {
      final symbolTable = symbolTableMsg.data as SymbolTableMessage;
      info['symbolTable'] = {
        'btreeAddress': '0x${symbolTable.btreeAddress.toRadixString(16)}',
        'localHeapAddress':
            '0x${symbolTable.localHeapAddress.toRadixString(16)}',
      };
    }

    return info;
  }
}
