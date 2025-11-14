import 'dart:typed_data';

import 'byte_reader.dart';
import 'datatype.dart';
import 'dataspace.dart';
import 'filter.dart';
import 'attribute.dart';
import 'hdf5_error.dart';

const msgTypeNil = 0x0000;
const msgTypeDataspace = 0x0001;
const msgTypeLinkInfo = 0x0002;
const msgTypeDatatype = 0x0003;
const msgTypeFillValue = 0x0005;
const msgTypeFilterPipeline = 0x000B;
const msgTypeDataLayout = 0x0008;
const msgTypeGroupInfo = 0x000A;
const msgTypeAttribute = 0x000C;
const msgTypeHeaderContinuation = 0x0010;
const msgTypeSymbolTable = 0x0011;
const msgTypeLink = 0x0016;

/// Link types
enum LinkType {
  hard, // Hard link (direct object reference)
  soft, // Soft link (symbolic link by path)
  external, // External link (link to object in another file)
}

/// Represents an HDF5 link message
class LinkMessage {
  final int version;
  final LinkType linkType;
  final String linkName;
  final int? objectHeaderAddress; // For hard links
  final String? targetPath; // For soft links
  final String? externalFilePath; // For external links
  final String? externalObjectPath; // For external links

  LinkMessage({
    required this.version,
    required this.linkType,
    required this.linkName,
    this.objectHeaderAddress,
    this.targetPath,
    this.externalFilePath,
    this.externalObjectPath,
  });

  bool get isHardLink => linkType == LinkType.hard;
  bool get isSoftLink => linkType == LinkType.soft;
  bool get isExternalLink => linkType == LinkType.external;

  @override
  String toString() {
    switch (linkType) {
      case LinkType.hard:
        return 'HardLink($linkName -> 0x${objectHeaderAddress?.toRadixString(16)})';
      case LinkType.soft:
        return 'SoftLink($linkName -> $targetPath)';
      case LinkType.external:
        return 'ExternalLink($linkName -> $externalFilePath:$externalObjectPath)';
    }
  }
}

/// Object type enumeration
enum Hdf5ObjectType {
  dataset,
  group,
  unknown,
}

/// HDF5 object header containing metadata messages
class ObjectHeader {
  final int version;
  final List<ObjectHeaderMessage> messages;

  ObjectHeader({required this.version, required this.messages});

  static Future<ObjectHeader> read(ByteReader reader, int address,
      {String? filePath, int hdf5Offset = 0}) async {
    hdf5DebugLog(
        'Reading object header at address 0x${address.toRadixString(16)}');
    reader.seek(address);

    final version = await reader.readUint8();
    if (version != 1 && version != 2) {
      throw UnsupportedVersionError(
        filePath: filePath,
        component: 'object header',
        version: version,
      );
    }

    await reader.readBytes(1); // reserved
    final totalHeaderMessages = await reader.readUint16();
    await reader.readUint32(); // objectReferenceCount (unused)
    final objectHeaderSize = await reader.readUint32();

    // Skip 4 bytes of reserved/alignment for version 1
    if (version == 1) {
      await reader.readBytes(4);
    }

    // Calculate the end position of the object header
    // Header prefix is 16 bytes (version 1)
    final headerEnd = address + 16 + objectHeaderSize;

    final messages = <ObjectHeaderMessage>[];
    int messageCount = 0;

    // Read messages until we reach the end of the header or message count
    final continuationBlocks = <_ContinuationBlock>[];

    while (messageCount < totalHeaderMessages && reader.position < headerEnd) {
      // Check if we have enough space for a message header (8 bytes minimum)
      if (reader.position + 8 > headerEnd) {
        hdf5DebugLog(
            'Reached end of object header at position 0x${reader.position.toRadixString(16)}');
        break;
      }

      final msg =
          await ObjectHeaderMessage.read(reader, version, filePath: filePath);

      // Handle continuation blocks
      if (msg.type == msgTypeHeaderContinuation && msg.data != null) {
        continuationBlocks.add(msg.data as _ContinuationBlock);
      } else if (msg.type != msgTypeNil) {
        // Don't add NIL messages, but continue reading
        messages.add(msg);
      }
      messageCount++;
    }

    // Seek to the end of the object header to ensure we're at the right position
    reader.seek(headerEnd);

    // Read continuation blocks
    for (final continuation in continuationBlocks) {
      // Add HDF5 offset to continuation block address
      final adjustedOffset = continuation.offset + hdf5Offset;
      hdf5DebugLog(
          'Reading continuation block at 0x${continuation.offset.toRadixString(16)} '
          '(adjusted: 0x${adjustedOffset.toRadixString(16)}), size: ${continuation.length}');
      reader.seek(adjustedOffset);
      final continuationEnd = adjustedOffset + continuation.length;

      while (reader.position < continuationEnd) {
        // Check if we have enough space for a message header
        if (reader.position + 8 > continuationEnd) {
          break;
        }

        final msg =
            await ObjectHeaderMessage.read(reader, version, filePath: filePath);

        // Handle nested continuation blocks
        if (msg.type == msgTypeHeaderContinuation && msg.data != null) {
          continuationBlocks.add(msg.data as _ContinuationBlock);
        } else if (msg.type != msgTypeNil) {
          messages.add(msg);
        }
      }
    }

    return ObjectHeader(version: version, messages: messages);
  }

  Hdf5Datatype? findDatatype() {
    final msg = messages.firstWhere(
      (m) => m.type == msgTypeDatatype,
      orElse: () => ObjectHeaderMessage(type: 0, size: 0, flags: 0),
    );
    if (msg.data == null) return null;
    return msg.data as Hdf5Datatype;
  }

  Hdf5Dataspace? findDataspace() {
    final msg = messages.firstWhere(
      (m) => m.type == msgTypeDataspace,
      orElse: () => ObjectHeaderMessage(type: 0, size: 0, flags: 0),
    );
    if (msg.data == null) return null;
    return msg.data as Hdf5Dataspace;
  }

  DataLayout? findDataLayout() {
    final msg = messages.firstWhere(
      (m) => m.type == msgTypeDataLayout,
      orElse: () => ObjectHeaderMessage(type: 0, size: 0, flags: 0),
    );
    if (msg.data == null) return null;
    return msg.data as DataLayout;
  }

  FilterPipeline? findFilterPipeline() {
    final msg = messages.firstWhere(
      (m) => m.type == msgTypeFilterPipeline,
      orElse: () => ObjectHeaderMessage(type: 0, size: 0, flags: 0),
    );
    if (msg.data == null) return null;
    return msg.data as FilterPipeline;
  }

  SymbolTableMessage? findSymbolTable() {
    final msg = messages.firstWhere(
      (m) => m.type == msgTypeSymbolTable,
      orElse: () => ObjectHeaderMessage(type: 0, size: 0, flags: 0),
    );
    if (msg.data == null) return null;
    return msg.data as SymbolTableMessage;
  }

  /// Find all attribute messages in the object header
  ///
  /// Filters out null attributes (those with unsupported datatypes)
  List<Hdf5Attribute> findAttributes() {
    return messages
        .where((m) => m.type == msgTypeAttribute && m.data != null)
        .map((m) => m.data as Hdf5Attribute)
        .toList();
  }

  /// Find all link messages in the object header
  ///
  /// Returns a list of LinkMessage objects representing hard, soft, or external links
  List<LinkMessage> findLinks() {
    return messages
        .where((m) => m.type == msgTypeLink && m.data != null)
        .map((m) => m.data as LinkMessage)
        .toList();
  }

  /// Find the local heap address from the symbol table message
  int? findLocalHeapAddress() {
    final symbolTableMsg = messages.firstWhere(
      (m) => m.type == msgTypeSymbolTable && m.data != null,
      orElse: () => ObjectHeaderMessage(type: 0, size: 0, flags: 0),
    );
    if (symbolTableMsg.data == null) return null;
    return (symbolTableMsg.data as SymbolTableMessage).localHeapAddress;
  }

  /// Determines the type of this HDF5 object
  ///
  /// A dataset must have:
  /// - Datatype message
  /// - Dataspace message
  /// - Data layout message
  ///
  /// A group typically has:
  /// - Symbol table message (old-style), OR
  /// - Link info message (new-style)
  ///
  /// Returns the object type or unknown if it cannot be determined
  Hdf5ObjectType determineObjectType() {
    final hasDatatype = messages.any((m) => m.type == msgTypeDatatype);
    final hasDataspace = messages.any((m) => m.type == msgTypeDataspace);
    final hasDataLayout = messages.any((m) => m.type == msgTypeDataLayout);

    final hasSymbolTable = messages.any((m) => m.type == msgTypeSymbolTable);
    final hasLinkInfo = messages.any((m) => m.type == msgTypeLinkInfo);
    final hasGroupInfo = messages.any((m) => m.type == msgTypeGroupInfo);

    // Dataset: must have datatype, dataspace, and layout
    if (hasDatatype && hasDataspace && hasDataLayout) {
      return Hdf5ObjectType.dataset;
    }

    // Group: has symbol table or link info
    if (hasSymbolTable || hasLinkInfo || hasGroupInfo) {
      return Hdf5ObjectType.group;
    }

    // If it has datatype or dataspace but not all three, it might be a partial dataset
    // or a corrupted object - mark as unknown
    if (hasDatatype || hasDataspace || hasDataLayout) {
      return Hdf5ObjectType.unknown;
    }

    // Default to unknown
    return Hdf5ObjectType.unknown;
  }

  /// Returns a human-readable description of the object type
  String getObjectTypeDescription() {
    final type = determineObjectType();
    switch (type) {
      case Hdf5ObjectType.dataset:
        return 'Dataset';
      case Hdf5ObjectType.group:
        return 'Group';
      case Hdf5ObjectType.unknown:
        final messageTypes = messages
            .map((m) => '0x${m.type.toRadixString(16).padLeft(4, '0')}')
            .join(', ');
        return 'Unknown (messages: $messageTypes)';
    }
  }
}

/// Individual message within an object header
class ObjectHeaderMessage {
  final int type;
  final int size;
  final int flags;
  final dynamic data;

  ObjectHeaderMessage({
    required this.type,
    required this.size,
    required this.flags,
    this.data,
  });

  static Future<ObjectHeaderMessage> read(ByteReader reader, int ohVersion,
      {String? filePath}) async {
    final type = await reader.readUint16();
    final size = await reader.readUint16();
    final flags = await reader.readUint8();
    await reader.readBytes(3); // reserved

    // Read all message data into a buffer first
    // This is important for compound datatypes which need recursive parsing
    final messageData = await reader.readBytes(size);
    final messageReader = ByteReader.fromBytes(Uint8List.fromList(messageData));

    dynamic data;

    if (type == msgTypeDatatype) {
      data = await _readDatatype(messageReader);
    } else if (type == msgTypeDataspace) {
      data = await Hdf5Dataspace.read(messageReader);
    } else if (type == msgTypeLinkInfo) {
      data = await _readLinkInfo(messageReader);
    } else if (type == msgTypeDataLayout) {
      data = await _readDataLayout(messageReader);
    } else if (type == msgTypeFilterPipeline) {
      data = await FilterPipeline.read(messageReader, size);
    } else if (type == msgTypeAttribute) {
      try {
        data = await Hdf5Attribute.read(
          messageReader,
          size,
          fileReader: reader,
          filePath: filePath,
        );
      } catch (e) {
        // Skip attributes with unsupported datatypes
        hdf5DebugLog('Skipping attribute with unsupported datatype: $e');
        data = null;
      }
    } else if (type == msgTypeSymbolTable) {
      data = await _readSymbolTable(messageReader);
    } else if (type == msgTypeHeaderContinuation) {
      data = await _readContinuation(messageReader);
    } else if (type == msgTypeLink) {
      try {
        data = await _readLinkMessage(messageReader);
      } catch (e) {
        hdf5DebugLog('Skipping link message due to error: $e');
        data = null;
      }
    }

    // Align to 8-byte boundary
    // totalRead is just the message size since we already read it into a buffer
    final padding = (8 - (size % 8)) % 8;
    if (padding > 0) {
      await reader.readBytes(padding);
    }

    return ObjectHeaderMessage(
      type: type,
      size: size,
      flags: flags,
      data: data,
    );
  }

  static Future<Hdf5Datatype> _readDatatype(ByteReader reader) async {
    // Delegate to the refactored Hdf5Datatype.read method
    return await Hdf5Datatype.read(reader);
  }

  static Future<LinkInfo> _readLinkInfo(ByteReader reader) async {
    final version = await reader.readUint8();
    final flags = await reader.readUint8();
    await reader.readBytes(2); // reserved

    int maximumCreationIndex = 0;
    if ((flags & 0x1) != 0) {
      maximumCreationIndex = (await reader.readUint64()).toInt();
    }

    final fractalHeapAddress =
        (flags & 0x2) != 0 ? (await reader.readUint64()).toInt() : 0;
    final v2BtreeAddress =
        (flags & 0x4) != 0 ? (await reader.readUint64()).toInt() : 0;

    return LinkInfo(
      version: version,
      maximumCreationIndex: maximumCreationIndex,
      fractalHeapAddress: fractalHeapAddress,
      v2BtreeAddress: v2BtreeAddress,
    );
  }

  static Future<DataLayout> _readDataLayout(ByteReader reader) async {
    final version = await reader.readUint8();

    hdf5DebugLog('Reading data layout version $version');

    if (version == 3) {
      // Version 3 layout
      final layoutClass = await reader.readUint8();

      if (layoutClass == 0) {
        // Compact storage - data stored in message
        final size = await reader.readUint16();
        final data = await reader.readBytes(size);
        return CompactLayout(data: data);
      } else if (layoutClass == 1) {
        // Contiguous storage
        final address = await reader.readUint64();
        final size = await reader.readUint64();
        return ContiguousLayout(address: address.toInt(), size: size.toInt());
      } else if (layoutClass == 2) {
        // Chunked storage
        final dimensionality = await reader.readUint8();
        final address = await reader.readUint64();

        final dimensions = <int>[];
        for (int i = 0; i < dimensionality; i++) {
          dimensions.add(await reader.readUint32());
        }

        // In version 3, the last dimension is the element size, not a chunk dimension
        // We need to remove it to get the actual chunk dimensions
        final chunkDims = dimensions.length > 1
            ? dimensions.sublist(0, dimensions.length - 1)
            : dimensions;

        hdf5DebugLog('Chunked layout v3: dimensionality=$dimensionality, '
            'raw dimensions=$dimensions, chunk dimensions=$chunkDims');

        return ChunkedLayout(
            address: address.toInt(), chunkDimensions: chunkDims);
      }
    } else if (version == 2) {
      // Version 2 layout (different structure than version 1)
      final layoutClass = await reader.readUint8();

      if (layoutClass == 0) {
        // Compact storage
        final size = await reader.readUint16();
        final data = await reader.readBytes(size);
        return CompactLayout(data: data);
      } else if (layoutClass == 1) {
        // Contiguous storage
        await reader.readBytes(6); // reserved
        final address = await reader.readUint64();
        final size = await reader.readUint64();
        return ContiguousLayout(address: address.toInt(), size: size.toInt());
      } else if (layoutClass == 2) {
        // Chunked storage (version 2)
        await reader.readBytes(6); // reserved
        final address = await reader.readUint64();
        final dimensionality = await reader.readUint8();
        await reader.readBytes(3); // reserved

        final dimensions = <int>[];
        for (int i = 0; i < dimensionality; i++) {
          dimensions.add(await reader.readUint32());
        }

        // In version 2, dimensions don't include element size
        return ChunkedLayout(
            address: address.toInt(), chunkDimensions: dimensions);
      } else if (layoutClass == 3) {
        // In version 2, class 3 appears to be a variant of contiguous layout
        // used by MATLAB that stores dimensions instead of total size
        await reader.readBytes(6); // reserved
        final address = await reader.readUint64();

        // Read dimensions (appears to be 2 uint32 values for 2D data)
        if (reader.remainingBytes >= 12) {
          final dim1 = await reader.readUint32();
          final dim2 = await reader.readUint32();
          final elementSize = await reader.readUint32();

          // Calculate total size
          final totalSize = dim1 * dim2 * elementSize;

          hdf5DebugLog('Layout v2 class 3 (MATLAB variant): '
              'address=0x${address.toRadixString(16)}, '
              'dims=[$dim1, $dim2], elementSize=$elementSize, totalSize=$totalSize');

          return ContiguousLayout(address: address.toInt(), size: totalSize);
        } else {
          // Not enough data, might be actual virtual layout
          throw UnsupportedFeatureError(
            feature: 'Virtual dataset layout',
            details:
                'Virtual dataset layout (class 3) requires HDF5 1.10+ support',
          );
        }
      } else if (layoutClass == 4) {
        // Single Chunk layout (version 2)
        if (reader.remainingBytes < 8) {
          hdf5DebugLog('Single chunk layout v2: insufficient data');
          return ContiguousLayout(address: 0, size: 0);
        }

        await reader.readUint8(); // flags
        await reader.readBytes(3); // reserved
        await reader.readBytes(4); // reserved

        final dimensionality = await reader.readUint8();
        await reader.readBytes(3); // reserved

        if (reader.remainingBytes < (dimensionality * 4 + 8)) {
          hdf5DebugLog(
              'Single chunk layout v2: insufficient data for dimensions');
          return ContiguousLayout(address: 0, size: 0);
        }

        final dimensions = <int>[];
        for (int i = 0; i < dimensionality; i++) {
          dimensions.add(await reader.readUint32());
        }

        final address = await reader.readUint64();

        int totalSize = 1;
        for (int i = 0; i < dimensions.length; i++) {
          totalSize *= dimensions[i];
        }

        hdf5DebugLog(
            'Single chunk layout v2: address=0x${address.toRadixString(16)}, '
            'dimensions=$dimensions, totalSize=$totalSize');

        return ContiguousLayout(address: address.toInt(), size: totalSize);
      } else {
        throw InvalidMessageError(
          messageType: 'data layout',
          reason: 'Unsupported layout class: $layoutClass',
          details: 'Version: $version',
        );
      }
    } else if (version == 1) {
      // Version 1 layout
      final layoutClass = await reader.readUint8();
      await reader.readBytes(6); // reserved

      if (layoutClass == 0) {
        // Compact storage
        final size = await reader.readUint16();
        final data = await reader.readBytes(size);
        return CompactLayout(data: data);
      } else if (layoutClass == 1) {
        // Contiguous storage
        final address = await reader.readUint64();
        final size = await reader.readUint64();
        return ContiguousLayout(address: address.toInt(), size: size.toInt());
      } else if (layoutClass == 2) {
        // Chunked storage (version 1)
        final dimensionality = await reader.readUint8();
        await reader.readBytes(3); // reserved

        final dimensions = <int>[];
        for (int i = 0; i < dimensionality; i++) {
          dimensions.add(await reader.readUint32());
        }

        final address = await reader.readUint64();

        // Note: In version 1, the last dimension is the element size, not a chunk dimension
        // We need to remove it to get the actual chunk dimensions
        final chunkDims = dimensions.sublist(0, dimensions.length - 1);

        return ChunkedLayout(
            address: address.toInt(), chunkDimensions: chunkDims);
      } else if (layoutClass == 3) {
        // Virtual layout - not yet supported
        throw UnsupportedFeatureError(
          feature: 'Virtual dataset layout',
          details:
              'Virtual dataset layout (class 3) requires HDF5 1.10+ support',
        );
      } else if (layoutClass == 4) {
        // Single Chunk layout (HDF5 1.10+)
        // This is similar to contiguous but with filtering support

        // Check if we have enough data to read the full structure
        if (reader.remainingBytes < 8) {
          // Not enough data for full single chunk layout
          // This might be a different version or corrupted
          hdf5DebugLog(
              'Single chunk layout: insufficient data, treating as contiguous with unknown size');
          return ContiguousLayout(address: 0, size: 0);
        }

        await reader.readUint8(); // flags
        await reader.readBytes(3); // reserved

        // Read dimension sizes
        final dimensionality = await reader.readUint8();
        await reader.readBytes(3); // reserved

        // Check if we have enough data for dimensions
        if (reader.remainingBytes < (dimensionality * 4 + 8)) {
          hdf5DebugLog('Single chunk layout: insufficient data for dimensions');
          return ContiguousLayout(address: 0, size: 0);
        }

        final dimensions = <int>[];
        for (int i = 0; i < dimensionality; i++) {
          dimensions.add(await reader.readUint32());
        }

        final address = await reader.readUint64();

        // Calculate total size from dimensions and element size
        // The last dimension is the element size
        int totalSize = 1;
        for (int i = 0; i < dimensions.length; i++) {
          totalSize *= dimensions[i];
        }

        hdf5DebugLog(
            'Single chunk layout: address=0x${address.toRadixString(16)}, '
            'dimensions=$dimensions, totalSize=$totalSize');

        // Treat as contiguous for reading purposes
        return ContiguousLayout(address: address.toInt(), size: totalSize);
      } else {
        throw InvalidMessageError(
          messageType: 'data layout',
          reason: 'Unsupported layout class: $layoutClass',
          details: 'Version: $version',
        );
      }
    }

    throw UnsupportedVersionError(
      component: 'data layout',
      version: version,
    );
  }

  static Future<SymbolTableMessage> _readSymbolTable(ByteReader reader) async {
    final btreeAddress = await reader.readUint64();
    final localHeapAddress = await reader.readUint64();

    return SymbolTableMessage(
      btreeAddress: btreeAddress,
      localHeapAddress: localHeapAddress,
    );
  }

  static Future<LinkMessage> _readLinkMessage(ByteReader reader) async {
    final version = await reader.readUint8();
    if (version != 1) {
      throw UnsupportedVersionError(
        component: 'link message',
        version: version,
      );
    }

    final flags = await reader.readUint8();
    final linkType = (flags & 0x03); // Bits 0-1 contain link type

    // Bit 2: link name character set (0=ASCII, 1=UTF-8)
    // final linkNameCharSet = (flags >> 2) & 0x01;

    // Bit 3: creation order field present
    final hasCreationOrder = (flags >> 3) & 0x01;

    // Bit 4: link type field present
    // final hasLinkType = (flags >> 4) & 0x01;

    // Bit 5: link name encoding (0=ASCII, 1=UTF-8)
    // final linkNameEncoding = (flags >> 5) & 0x01;

    // Read creation order if present
    if (hasCreationOrder == 1) {
      await reader.readUint64(); // creation order
    }

    // Read link type if present (for version 1, it's in flags)
    LinkType type;
    if (linkType == 0) {
      type = LinkType.hard;
    } else if (linkType == 1) {
      type = LinkType.soft;
    } else if (linkType == 64 || linkType == 2) {
      // External link can be encoded as 64 or 2
      type = LinkType.external;
    } else {
      throw InvalidMessageError(
        messageType: 'link',
        reason: 'Unknown link type: $linkType',
      );
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
      // Hard link: read object header address
      objectHeaderAddress = (await reader.readUint64()).toInt();
    } else if (type == LinkType.soft) {
      // Soft link: read target path length and path
      final targetPathLength = await reader.readUint16();
      final targetPathBytes = await reader.readBytes(targetPathLength);
      targetPath = String.fromCharCodes(targetPathBytes);
    } else if (type == LinkType.external) {
      // External link: read external file path and object path
      final externalInfoLength = await reader.readUint16();
      final externalInfoBytes = await reader.readBytes(externalInfoLength);

      // External info contains: file path (null-terminated) + object path (null-terminated)
      int nullIndex = externalInfoBytes.indexOf(0);
      if (nullIndex >= 0) {
        externalFilePath =
            String.fromCharCodes(externalInfoBytes.sublist(0, nullIndex));
        if (nullIndex + 1 < externalInfoBytes.length) {
          final objectPathBytes = externalInfoBytes.sublist(nullIndex + 1);
          final objectPathEnd = objectPathBytes.indexOf(0);
          if (objectPathEnd >= 0) {
            externalObjectPath =
                String.fromCharCodes(objectPathBytes.sublist(0, objectPathEnd));
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
  }
}

/// Link information for group navigation
class LinkInfo {
  final int version;
  final int maximumCreationIndex;
  final int fractalHeapAddress;
  final int v2BtreeAddress;

  LinkInfo({
    required this.version,
    required this.maximumCreationIndex,
    required this.fractalHeapAddress,
    required this.v2BtreeAddress,
  });
}

/// Base class for data layout types
abstract class DataLayout {
  int get address;
}

/// Contiguous data layout
class ContiguousLayout extends DataLayout {
  @override
  final int address;
  final int size;

  ContiguousLayout({required this.address, required this.size});
}

/// Chunked data layout
class ChunkedLayout extends DataLayout {
  @override
  final int address;
  final List<int> chunkDimensions;

  ChunkedLayout({required this.address, required this.chunkDimensions});
}

/// Compact data layout (data stored in message)
class CompactLayout extends DataLayout {
  @override
  int get address => 0; // No address for compact storage
  final List<int> data;

  CompactLayout({required this.data});
}

/// Symbol table message for old-style group storage
class SymbolTableMessage {
  final int btreeAddress;
  final int localHeapAddress;

  SymbolTableMessage({
    required this.btreeAddress,
    required this.localHeapAddress,
  });
}

/// Object header continuation block
class _ContinuationBlock {
  final int offset;
  final int length;

  _ContinuationBlock({required this.offset, required this.length});
}

/// Read continuation block message
Future<_ContinuationBlock> _readContinuation(ByteReader reader) async {
  final offset = await reader.readUint64();
  final length = await reader.readUint64();

  hdf5DebugLog(
      'Continuation block: offset=0x${offset.toRadixString(16)}, length=$length');

  return _ContinuationBlock(offset: offset, length: length);
}
