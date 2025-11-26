// ignore_for_file: unused_field

import 'byte_writer.dart';
import 'object_header.dart';
import 'symbol_table_writer.dart';
import 'btree_v1_writer.dart';
import 'btree_v2_writer.dart';
import 'hdf5_error.dart';

/// Represents a group in an HDF5 file for writing purposes
///
/// A group is a container that can hold datasets and other groups,
/// forming a hierarchical structure similar to a file system.
///
/// This class tracks all information needed to write a group to an HDF5 file:
/// - Group metadata (name, path, attributes)
/// - Child objects (subgroups and datasets)
/// - File addresses for cross-referencing
///
/// Example:
/// ```dart
/// final group = GroupData(
///   name: 'experiments',
///   fullPath: '/experiments',
/// );
/// group.addDataset('trial1', datasetAddress);
/// group.addSubgroup('results', subgroupAddress);
/// ```
class GroupData {
  /// Name of this group (without path)
  final String name;

  /// Full path to this group (e.g., '/experiments/trial1')
  final String fullPath;

  /// Attributes attached to this group
  final Map<String, dynamic> attributes;

  /// Subgroups contained in this group (name -> GroupData)
  final Map<String, GroupData> subgroups;

  /// Datasets contained in this group (name -> dataset address)
  final Map<String, int> datasets;

  /// Address of this group's object header in the file
  int? objectHeaderAddress;

  /// Address of the symbol table B-tree
  int? btreeAddress;

  /// Address of the local heap (for old-style groups)
  int? localHeapAddress;

  /// Address of the fractal heap (for new-style groups)
  int? fractalHeapAddress;

  /// Address of the B-tree v2 (for new-style groups)
  int? btreeV2Address;

  GroupData({
    required this.name,
    required this.fullPath,
    Map<String, dynamic>? attributes,
  })  : attributes = attributes ?? {},
        subgroups = {},
        datasets = {};

  /// Add a dataset to this group
  ///
  /// Parameters:
  /// - [name]: Name of the dataset
  /// - [address]: Address of the dataset's object header
  ///
  /// Throws [ArgumentError] if a child with this name already exists
  void addDataset(String name, int address) {
    _validateChildName(name);
    if (datasets.containsKey(name) || subgroups.containsKey(name)) {
      throw ArgumentError(
        'Child "$name" already exists in group "$fullPath"',
      );
    }
    datasets[name] = address;
  }

  /// Add a subgroup to this group
  ///
  /// Parameters:
  /// - [name]: Name of the subgroup
  /// - [subgroup]: The GroupData object for the subgroup
  ///
  /// Throws [ArgumentError] if a child with this name already exists
  void addSubgroup(String name, GroupData subgroup) {
    _validateChildName(name);
    if (datasets.containsKey(name) || subgroups.containsKey(name)) {
      throw ArgumentError(
        'Child "$name" already exists in group "$fullPath"',
      );
    }
    subgroups[name] = subgroup;
  }

  /// Get all child names (datasets and subgroups)
  List<String> get children {
    return [...datasets.keys, ...subgroups.keys];
  }

  /// Get the total number of children
  int get childCount => datasets.length + subgroups.length;

  /// Check if this group has any children
  bool get isEmpty => childCount == 0;

  /// Get the address of a child object (dataset or subgroup)
  ///
  /// Returns null if the child doesn't exist
  int? getChildAddress(String name) {
    if (datasets.containsKey(name)) {
      return datasets[name];
    }
    if (subgroups.containsKey(name)) {
      return subgroups[name]!.objectHeaderAddress;
    }
    return null;
  }

  /// Validate a child name
  void _validateChildName(String name) {
    if (name.isEmpty) {
      throw ArgumentError('Child name cannot be empty');
    }
    if (name.contains('/')) {
      throw ArgumentError('Child name cannot contain "/"');
    }
    if (name == '.' || name == '..') {
      throw ArgumentError('Child name cannot be "." or ".."');
    }
  }

  /// Parse a path and return the components
  ///
  /// Example: '/experiments/trial1/data' -> ['experiments', 'trial1', 'data']
  static List<String> parsePath(String path) {
    if (path.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }
    if (!path.startsWith('/')) {
      throw ArgumentError('Path must start with "/"');
    }

    // Remove leading slash and split
    final parts =
        path.substring(1).split('/').where((p) => p.isNotEmpty).toList();

    // Validate each part
    for (final part in parts) {
      if (part == '.' || part == '..') {
        throw ArgumentError('Path cannot contain "." or ".."');
      }
      if (part.contains('//')) {
        throw ArgumentError('Path cannot contain consecutive slashes');
      }
    }

    return parts;
  }

  /// Validate a full path
  ///
  /// Throws [ArgumentError] if the path is invalid
  static void validatePath(String path) {
    if (path.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }
    if (!path.startsWith('/')) {
      throw ArgumentError('Path must start with "/"');
    }
    if (path.length > 1 && path.endsWith('/')) {
      throw ArgumentError('Path cannot end with "/"');
    }
    if (path.contains('//')) {
      throw ArgumentError('Path cannot contain consecutive slashes');
    }

    // Parse to validate components
    parsePath(path);
  }

  @override
  String toString() {
    return 'GroupData(name: $name, path: $fullPath, '
        'children: $childCount, attributes: ${attributes.length})';
  }
}

/// Writer for HDF5 group structures
///
/// This class handles writing group object headers and associated structures
/// (symbol tables, B-trees, heaps) to create hierarchical group structures
/// in HDF5 files.
///
/// Supports both old-style (HDF5 < 1.8) and new-style (HDF5 1.8+) groups:
/// - Old-style: B-tree V1 + Local Heap + Symbol Table Nodes
/// - New-style: B-tree V2 + Fractal Heap + Link Info
///
/// Example:
/// ```dart
/// final writer = GroupWriter(formatVersion: 0);
/// final address = await writer.writeGroup(
///   byteWriter,
///   groupData,
/// );
/// ```
class GroupWriter {
  /// HDF5 format version (0, 1, or 2)
  final int formatVersion;

  /// Symbol table writer for old-style groups
  final SymbolTableWriter _symbolTableWriter;

  /// B-tree V1 writer for old-style groups
  final BTreeV1Writer? _btreeV1Writer;

  /// B-tree V2 writer for new-style groups
  final BTreeV2Writer? _btreeV2Writer;

  GroupWriter({
    this.formatVersion = 0,
  })  : _symbolTableWriter = SymbolTableWriter(
          format:
              formatVersion >= 2 ? SymbolTableFormat.v2 : SymbolTableFormat.v1,
        ),
        _btreeV1Writer = null, // Will be created when needed
        _btreeV2Writer = null; // Will be created when needed

  /// Write a group to the file
  ///
  /// This method writes:
  /// 1. Object header with symbol table or link info message
  /// 2. Symbol table entries for all children
  /// 3. B-tree index (v1 or v2 based on format version)
  /// 4. Heap (local or fractal based on format version)
  ///
  /// Parameters:
  /// - [writer]: The ByteWriter to write to
  /// - [group]: The GroupData containing group information
  ///
  /// Returns the address of the group's object header
  ///
  /// Throws:
  /// - [ArgumentError] if the group has no children
  /// - [Hdf5Error] if writing fails
  Future<int> writeGroup(
    ByteWriter writer,
    GroupData group,
  ) async {
    if (group.isEmpty) {
      throw ArgumentError('Cannot write empty group "${group.fullPath}"');
    }

    // Step 1: Reserve space for object header (we'll write it later)
    final objectHeaderAddress = writer.position;
    group.objectHeaderAddress = objectHeaderAddress;

    // Estimate object header size and reserve space
    final estimatedHeaderSize = _estimateObjectHeaderSize(group);
    final headerPlaceholder = List<int>.filled(estimatedHeaderSize, 0);
    writer.writeBytes(headerPlaceholder);

    // Step 2: Write symbol table structures
    final symbolTableData = await _writeSymbolTable(writer, group);

    // Update group with addresses from symbol table
    group.btreeAddress = symbolTableData['btreeAddress'] as int;
    if (symbolTableData.containsKey('localHeapAddress')) {
      group.localHeapAddress = symbolTableData['localHeapAddress'] as int;
    }
    if (symbolTableData.containsKey('fractalHeapAddress')) {
      group.fractalHeapAddress = symbolTableData['fractalHeapAddress'] as int;
    }
    if (symbolTableData.containsKey('btreeV2Address')) {
      group.btreeV2Address = symbolTableData['btreeV2Address'] as int;
    }

    // Step 3: Write the actual object header with correct addresses
    final objectHeader = _createObjectHeader(group);
    final headerBytes = objectHeader.write();

    // Write the header at the reserved position
    writer.writeAt(objectHeaderAddress, headerBytes);

    return objectHeaderAddress;
  }

  /// Write symbol table structures for the group
  ///
  /// Returns a map containing addresses of written structures
  Future<Map<String, dynamic>> _writeSymbolTable(
    ByteWriter writer,
    GroupData group,
  ) async {
    // Create symbol table entries for all children
    final entries = <SymbolTableEntry>[];

    // Add datasets
    for (final entry in group.datasets.entries) {
      entries.add(SymbolTableEntry(
        name: entry.key,
        objectHeaderAddress: entry.value,
      ));
    }

    // Add subgroups
    for (final entry in group.subgroups.entries) {
      final subgroup = entry.value;
      if (subgroup.objectHeaderAddress == null) {
        throw Hdf5Error(
          operation: 'write group',
          message: 'Subgroup "${entry.key}" has no object header address',
        );
      }
      entries.add(SymbolTableEntry(
        name: entry.key,
        objectHeaderAddress: subgroup.objectHeaderAddress!,
      ));
    }

    // Write symbol table
    final startAddress = writer.position;
    final result = _symbolTableWriter.write(
      entries: entries,
      startAddress: startAddress,
    );

    // Write the bytes
    final bytes = result['bytes'] as List<int>;
    writer.writeBytes(bytes);

    return result;
  }

  /// Create object header for the group
  ObjectHeader _createObjectHeader(GroupData group) {
    final messages = <HeaderMessage>[];

    // Add symbol table message (old-style) or link info message (new-style)
    if (formatVersion < 2) {
      // Old-style: symbol table message
      final symbolTableMessage = _symbolTableWriter.createSymbolTableMessage(
        btreeAddress: group.btreeAddress!,
        localHeapAddress: group.localHeapAddress!,
      );
      messages.add(HeaderMessage.forWriting(
        type: MessageType.symbolTable,
        data: symbolTableMessage,
      ));
    } else {
      // New-style: link info message
      final linkInfoMessage = _createLinkInfoMessage(group);
      messages.add(HeaderMessage.forWriting(
        type: MessageType.linkInfo,
        data: linkInfoMessage,
      ));
    }

    // Add attribute messages
    // TO DO: Implement attribute writing when needed
    // for (final entry in group.attributes.entries) {
    //   ...
    // }

    return ObjectHeader(version: 1, messages: messages);
  }

  /// Create link info message for new-style groups
  List<int> _createLinkInfoMessage(GroupData group) {
    final writer = ByteWriter();

    // Version: 0
    writer.writeUint8(0);

    // Flags: 0x01 (creation order tracked)
    writer.writeUint8(0x01);

    // Maximum creation index (optional, present if flag 0x01 is set)
    writer.writeUint64(group.childCount);

    // Fractal heap address
    writer.writeUint64(group.fractalHeapAddress ?? 0xFFFFFFFFFFFFFFFF);

    // B-tree v2 address for name index
    writer.writeUint64(group.btreeV2Address ?? 0xFFFFFFFFFFFFFFFF);

    // B-tree v2 address for creation order index (optional)
    // Not present if flag 0x02 is not set

    return writer.bytes;
  }

  /// Estimate the size of the object header
  int _estimateObjectHeaderSize(GroupData group) {
    // Object header prefix: 16 bytes (version 1)
    // Symbol table message: 2 (type) + 2 (size) + 1 (flags) + 3 (reserved) + 16 (data) = 24 bytes
    // Or link info message: similar size
    // Attributes: variable (skip for now)

    // Conservative estimate: 100 bytes
    return 100;
  }
}
