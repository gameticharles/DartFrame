import 'byte_writer.dart';
import 'object_header.dart';
import 'superblock.dart';
import 'symbol_table_writer.dart';
import 'dataspace.dart';
import 'data_layout_message_writer.dart';
import 'attribute.dart';
import 'datatype.dart';
import 'data_writer.dart';
import 'hdf5_error.dart';
import 'write_options.dart';
import 'heap_manager.dart';
import 'group_writer.dart';
import '../../ndarray/ndarray.dart';

/// Coordinator class for building complete HDF5 files
///
/// This class orchestrates all HDF5 writer components to create valid HDF5 files
/// that are compatible with standard tools like h5py, MATLAB, and R.
///
/// The builder manages:
/// - Address tracking for cross-references between file structures
/// - Write process flow (superblock, root group, dataset, data)
/// - Address updates after file construction
///
/// Example usage:
/// ```dart
/// final builder = HDF5FileBuilder();
/// final bytes = await builder.build(
///   array: myArray,
///   datasetPath: '/data',
///   attributes: {'units': 'meters', 'description': 'Sample data'},
/// );
/// ```
class HDF5FileBuilder {
  final ByteWriter _writer;
  final Map<String, int> _addresses;
  final SymbolTableWriter _symbolTableWriter;
  final DataLayoutMessageWriter _dataLayoutWriter;
  final DataWriter _dataWriter;
  final HeapManager _heapManager;
  final GroupWriter _groupWriter;

  // Multi-dataset support
  final Map<String, GroupData> _groups;
  final Map<String, _DatasetInfo> _datasets;
  GroupData? _rootGroup;

  HDF5FileBuilder({int formatVersion = 0})
      : _writer = ByteWriter(),
        _addresses = {},
        _symbolTableWriter = SymbolTableWriter(),
        _dataLayoutWriter = DataLayoutMessageWriter(),
        _dataWriter = DataWriter(),
        _heapManager = HeapManager(formatVersion: formatVersion),
        _groupWriter = GroupWriter(formatVersion: formatVersion),
        _groups = {},
        _datasets = {};

  /// Build a complete HDF5 file from an NDArray
  ///
  /// Parameters:
  /// - [array]: The NDArray to write
  /// - [datasetPath]: The dataset path in the HDF5 file (default: '/data')
  /// - [attributes]: Optional metadata attributes for the dataset
  /// - [options]: Write options including validation settings
  ///
  /// Returns the complete HDF5 file as a byte list
  ///
  /// Throws:
  /// - [InvalidDatasetNameError] if the dataset path is invalid
  /// - [UnsupportedWriteDatatypeError] if the array datatype is not supported
  /// - [DataValidationError] if the array data is invalid
  /// - [AttributeValidationError] if any attributes are invalid
  /// - [CorruptedFileError] if validation is enabled and fails
  Future<List<int>> build({
    required NDArray array,
    String datasetPath = '/data',
    Map<String, dynamic>? attributes,
    WriteOptions? options,
  }) async {
    options ??= const WriteOptions();
    // Validate inputs
    _validateDatasetPath(datasetPath);
    _validateDataType(array);
    _validateAttributes(attributes);

    // Clear any previous state
    _writer.clear();
    _addresses.clear();

    // Step 1: Write superblock with placeholder addresses
    final superblockAddress = _writer.position;
    _addresses['superblock'] = superblockAddress;
    final superblock = Superblock.create(
      rootGroupAddress: 0, // Placeholder
      endOfFileAddress: 0, // Placeholder
    );
    superblock.writeTo(_writer);

    // Step 2: Write root group object header (with placeholder symbol table)
    final rootGroupAddress = _writeRootGroup();
    _addresses['rootGroup'] = rootGroupAddress;

    // Step 3: Write dataset object header
    final datasetName =
        datasetPath.startsWith('/') ? datasetPath.substring(1) : datasetPath;
    final datasetAddress = _writeDataset(array, datasetPath, attributes);
    _addresses['dataset'] = datasetAddress;

    // Step 4: Write dataset raw data
    final dataAddress = await _writeDataValues(array);
    _addresses['data'] = dataAddress;

    // Step 5: Write symbol table structures (B-tree, symbol table node, local heap)
    // This must be done AFTER all other data is written
    _updateRootGroupSymbolTable(datasetName, datasetAddress);

    // Step 6: Update superblock with actual addresses
    final endOfFileAddress = _writer.position;
    _addresses['endOfFile'] = endOfFileAddress;
    Superblock.updateRootGroupAddress(_writer, rootGroupAddress);
    Superblock.updateEndOfFileAddress(_writer, endOfFileAddress);

    // Step 7: Validate file if requested
    if (options.validateOnWrite) {
      validateFile();
    }

    return _writer.bytes;
  }

  /// Write the root group object header and symbol table
  ///
  /// Returns the address of the root group object header
  int _writeRootGroup() {
    // Create a minimal root group header with a symbol table message
    // The symbol table will be written after we know the dataset address
    // We'll write a placeholder and come back to update it

    final symbolTableMessageData = _symbolTableWriter.createSymbolTableMessage(
      btreeAddress: 0, // Placeholder
      localHeapAddress: 0, // Placeholder
    );

    final messages = [
      HeaderMessage.forWriting(
        type: MessageType.symbolTable,
        data: symbolTableMessageData,
      ),
    ];

    final headerAddress = _writer.position;
    final header = ObjectHeader(version: 1, messages: messages);
    header.writeTo(_writer);

    return headerAddress;
  }

  /// Write the dataset object header with messages
  ///
  /// Returns the address of the dataset object header
  int _writeDataset(
    NDArray array,
    String datasetPath,
    Map<String, dynamic>? attributes,
  ) {
    // Calculate where the data will be written
    // We need to estimate the size of the dataset header first
    final datatype = _inferDatatype(array);
    final datatypeMessage = datatype.write();
    final dataspace = Hdf5Dataspace.simple(array.shape.toList());
    final dataspaceMessage = dataspace.write();

    // Placeholder for data layout - we'll calculate the actual address
    final dataSize = _calculateDataSize(array);

    // Build attribute messages if provided
    final attributeMessages = <HeaderMessage>[];
    if (attributes != null && attributes.isNotEmpty) {
      for (final entry in attributes.entries) {
        final attribute = Hdf5Attribute.scalar(entry.key, entry.value);
        final attrData = attribute.write();
        attributeMessages.add(HeaderMessage.forWriting(
          type: MessageType.attribute,
          data: attrData,
        ));
      }
    }

    // Estimate header size to calculate data address
    final messages = [
      HeaderMessage.forWriting(
          type: MessageType.datatype, data: datatypeMessage),
      HeaderMessage.forWriting(
          type: MessageType.dataspace, data: dataspaceMessage),
      HeaderMessage.forWriting(
        type: MessageType.dataLayout,
        data: [
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
        ], // Placeholder
      ),
      ...attributeMessages,
    ];

    final tempHeader = ObjectHeader(version: 1, messages: messages);
    final estimatedHeaderSize = tempHeader.calculateSize();
    final dataAddress = (_writer.position + estimatedHeaderSize).toInt();

    // Now create the actual data layout message with the correct address
    final dataLayoutMessage = _dataLayoutWriter.writeContiguous(
      dataAddress: dataAddress,
      dataSize: dataSize,
    );

    // Replace the placeholder data layout message
    messages[2] = HeaderMessage.forWriting(
      type: MessageType.dataLayout,
      data: dataLayoutMessage,
    );

    // Write the dataset object header
    final datasetHeaderAddress = _writer.position;
    final header = ObjectHeader(version: 1, messages: messages);
    header.writeTo(_writer);

    return datasetHeaderAddress;
  }

  /// Update the root group's symbol table with dataset information
  void _updateRootGroupSymbolTable(String datasetName, int datasetAddress) {
    // Calculate where the symbol table should be written
    final symbolTableAddress = _writer.position;

    // Create symbol table entry
    final entries = [
      SymbolTableEntry(
        name: datasetName,
        objectHeaderAddress: datasetAddress,
      ),
    ];

    // Write symbol table structures
    final symbolTableData = _symbolTableWriter.write(
      entries: entries,
      startAddress: symbolTableAddress,
    );

    final btreeAddress = symbolTableData['btreeAddress'] as int;
    final localHeapAddress = symbolTableData['localHeapAddress'] as int;
    final bytes = symbolTableData['bytes'] as List<int>;

    // Write the symbol table bytes
    _writer.writeBytes(bytes);

    // Store the B-tree address for the superblock update
    _addresses['btree'] = btreeAddress;
    _addresses['localHeap'] = localHeapAddress;

    // Now update the root group header with the correct addresses
    // The root group header is at position after superblock (96 bytes)
    final rootGroupHeaderPosition = Superblock.superblockSize;

    // Create the updated symbol table message
    final symbolTableMessage = _symbolTableWriter.createSymbolTableMessage(
      btreeAddress: btreeAddress,
      localHeapAddress: localHeapAddress,
    );

    // Rebuild the root group header with correct addresses
    final messages = [
      HeaderMessage.forWriting(
        type: MessageType.symbolTable,
        data: symbolTableMessage,
      ),
    ];

    final header = ObjectHeader(version: 1, messages: messages);
    final headerBytes = header.write();

    // Update the root group header in place
    _writer.writeAt(rootGroupHeaderPosition, headerBytes);

    // CRITICAL FIX: Update the superblock's root group symbol table entry
    // The superblock has a symbol table entry at offset 56 that needs to point
    // to the B-tree address (not the root group object header)
    _updateSuperblockSymbolTableEntry(btreeAddress);
  }

  /// Update the superblock's root group symbol table entry
  ///
  /// The superblock contains a symbol table entry for the root group at offset 56.
  /// This entry has two fields:
  /// - Link name offset in local heap (offset 56): should be 0 for root
  /// - Object header address (offset 64): should point to root group object header
  ///
  /// However, for the file to be readable, we also need to ensure the symbol table
  /// message in the root group object header points to the correct B-tree and heap.
  void _updateSuperblockSymbolTableEntry(int btreeAddress) {
    // The superblock's symbol table entry starts at offset 56
    // For version 0 superblocks:
    // - Offset 56: Link name offset (8 bytes) - should be 0 for root
    // - Offset 64: Object header address (8 bytes) - root group header address
    // - Offset 72: Cache type (4 bytes)
    // - Offset 76: Reserved (4 bytes)
    // - Offset 80: Scratch pad (16 bytes)

    // The link name offset should be 0 for the root group (it has no name)
    // This is already set correctly in the superblock creation
    // The object header address is already set correctly
    // So we don't need to update the superblock symbol table entry itself

    // The key is that the root group object header's symbol table message
    // must point to the correct B-tree and local heap, which we've already done above
  }

  /// Write the raw data values from the NDArray
  ///
  /// Returns the address where the data was written
  Future<int> _writeDataValues(NDArray array) async {
    return await _dataWriter.writeData(_writer, array);
  }

  /// Calculate the total size of the data in bytes
  int _calculateDataSize(NDArray array) {
    return _dataWriter.calculateDataSize(array);
  }

  /// Infer HDF5 datatype from NDArray
  Hdf5Datatype _inferDatatype(NDArray array) {
    // Check the type of the first element to infer the datatype
    final firstValue = array.getValue(List.filled(array.ndim, 0));

    if (firstValue is double) {
      return Hdf5Datatype.float64;
    } else if (firstValue is int) {
      return Hdf5Datatype.int64;
    } else {
      throw UnsupportedError(
        'Unsupported data type: ${firstValue.runtimeType}',
      );
    }
  }

  /// Validate attributes before writing
  void _validateAttributes(Map<String, dynamic>? attributes) {
    if (attributes == null || attributes.isEmpty) {
      return;
    }

    for (final entry in attributes.entries) {
      final name = entry.key;
      final value = entry.value;

      // Check attribute name
      if (name.isEmpty) {
        throw AttributeValidationError(
          attributeName: name,
          reason: 'Attribute name cannot be empty',
        );
      }

      // Check attribute name length (HDF5 has practical limits)
      if (name.length > 255) {
        throw AttributeValidationError(
          attributeName: name,
          reason: 'Attribute name too long (max 255 characters)',
        );
      }

      // Check attribute value type
      if (value == null) {
        throw AttributeValidationError(
          attributeName: name,
          reason: 'Attribute value cannot be null',
        );
      }

      // Check for supported types
      if (value is! String &&
          value is! int &&
          value is! double &&
          value is! bool) {
        throw AttributeValidationError(
          attributeName: name,
          reason: 'Unsupported attribute type: ${value.runtimeType}. '
              'Supported types: String, int, double, bool',
        );
      }

      // Check string length (practical limit for attributes)
      if (value is String && value.length > 65535) {
        throw AttributeValidationError(
          attributeName: name,
          reason: 'String attribute too long (max 65535 characters)',
        );
      }
    }
  }

  /// Validate dataset path
  void _validateDatasetPath(String path) {
    // Check if path is empty
    if (path.isEmpty) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Dataset name cannot be empty',
      );
    }

    // Check if path starts with /
    if (!path.startsWith('/')) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Dataset path must start with "/"',
      );
    }

    // Check for invalid characters
    final validPattern = RegExp(r'^/[a-zA-Z0-9_/]*$');
    if (!validPattern.hasMatch(path)) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Dataset name contains invalid characters. '
            'Use only alphanumeric characters, underscores, and forward slashes',
      );
    }

    // Check for consecutive slashes
    if (path.contains('//')) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Dataset path cannot contain consecutive slashes',
      );
    }

    // Check if path ends with /
    if (path.length > 1 && path.endsWith('/')) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Dataset path cannot end with "/"',
      );
    }

    // For now, only support simple paths (no nested groups)
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason:
            'Nested groups not yet supported. Use simple paths like "/data"',
      );
    }

    // Check for reserved names
    final reservedNames = ['', '.', '..'];
    if (parts.any((part) => reservedNames.contains(part))) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Dataset name contains reserved names',
      );
    }
  }

  /// Validate data type
  void _validateDataType(NDArray array) {
    // Check if array is empty
    final dimensions = array.shape.toList();
    if (dimensions.any((dim) => dim == 0)) {
      throw DataValidationError(
        reason: 'Array has zero-size dimension',
        details: 'Array shape: ${array.shape}',
      );
    }

    // Check if array has valid dimensions
    if (dimensions.any((dim) => dim < 0)) {
      throw DataValidationError(
        reason: 'Array has negative dimension',
        details: 'Array shape: ${array.shape}',
      );
    }

    // Try to infer datatype - this will throw if unsupported
    try {
      _inferDatatype(array);
    } on UnsupportedError catch (e) {
      // Convert UnsupportedError to our custom error type
      throw UnsupportedWriteDatatypeError(
        datatypeInfo: e.message ?? 'Unknown type',
        supportedTypes: ['float64 (double)', 'int64 (int)'],
      );
    }
  }

  /// Get tracked address by name
  int? getAddress(String name) => _addresses[name];

  /// Get all tracked addresses
  Map<String, int> get addresses => Map.unmodifiable(_addresses);

  // ========== Multi-dataset API ==========

  /// Add a dataset to the file
  ///
  /// Parameters:
  /// - [path]: Full path to the dataset (e.g., '/data' or '/group1/data')
  /// - [array]: The NDArray to write
  /// - [options]: Write options (compression, chunking, etc.)
  ///
  /// Throws:
  /// - [InvalidDatasetNameError] if path is invalid
  /// - [GroupPathConflictError] if path conflicts with existing objects
  /// - [UnsupportedWriteDatatypeError] if the array datatype is not supported
  /// - [DataValidationError] if array data is invalid
  Future<void> addDataset(
    String path,
    NDArray array, {
    WriteOptions? options,
  }) async {
    options ??= const WriteOptions();

    // Validate array data
    _validateDataType(array);

    // Validate options with dataset dimensions
    options.validate(datasetDimensions: array.shape.toList());

    // Validate and parse path
    _validateDatasetPath(path);
    final parts = _parsePath(path);
    if (parts.isEmpty) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Dataset path cannot be empty after parsing',
      );
    }

    final datasetName = parts.last;
    final groupPath = parts.length > 1
        ? '/${parts.sublist(0, parts.length - 1).join('/')}'
        : '/';

    // Get or create parent group
    final parentGroup = _getOrCreateGroup(
      groupPath,
      createIntermediate: options.createIntermediateGroups,
    );

    // Check for conflicts with existing datasets
    if (_datasets.containsKey(path)) {
      throw GroupPathConflictError(
        conflictingPath: path,
        existingType: 'dataset',
        attemptedType: 'dataset',
      );
    }

    // Check for conflicts with existing groups
    if (parentGroup.subgroups.containsKey(datasetName)) {
      throw GroupPathConflictError(
        conflictingPath: path,
        existingType: 'group',
        attemptedType: 'dataset',
      );
    }

    // Store dataset info for later writing
    final datasetInfo = _DatasetInfo(
      path: path,
      name: datasetName,
      array: array,
      options: options,
      parentGroup: parentGroup,
    );
    _datasets[path] = datasetInfo;

    // Register dataset with parent group (with placeholder address)
    // The actual address will be set when we write the dataset
    parentGroup.datasets[datasetName] = 0; // Placeholder
  }

  /// Create a group in the file
  ///
  /// Parameters:
  /// - [path]: Full path to the group (e.g., '/group1' or '/group1/subgroup')
  /// - [attributes]: Optional attributes to attach to the group
  ///
  /// Throws:
  /// - [InvalidDatasetNameError] if path is invalid
  /// - [GroupPathConflictError] if path conflicts with existing objects
  /// - [AttributeValidationError] if attributes are invalid
  Future<void> createGroup(
    String path, {
    Map<String, dynamic>? attributes,
  }) async {
    // Validate attributes
    _validateAttributes(attributes);

    // Validate path (reuse dataset path validation logic)
    _validateGroupPath(path);

    _getOrCreateGroup(path, attributes: attributes, createIntermediate: true);
  }

  /// Validate group path
  void _validateGroupPath(String path) {
    // Check if path is empty
    if (path.isEmpty) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Group path cannot be empty',
      );
    }

    // Check if path starts with /
    if (!path.startsWith('/')) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Group path must start with "/"',
      );
    }

    // Check for invalid characters
    final validPattern = RegExp(r'^/[a-zA-Z0-9_/]*$');
    if (!validPattern.hasMatch(path)) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Group path contains invalid characters. '
            'Use only alphanumeric characters, underscores, and forward slashes',
      );
    }

    // Check for consecutive slashes
    if (path.contains('//')) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Group path cannot contain consecutive slashes',
      );
    }

    // Check if path ends with / (except for root)
    if (path.length > 1 && path.endsWith('/')) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Group path cannot end with "/"',
      );
    }

    // Check for reserved names
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final reservedNames = ['', '.', '..'];
    if (parts.any((part) => reservedNames.contains(part))) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Group path contains reserved names',
      );
    }
  }

  /// Finalize and write the complete HDF5 file
  ///
  /// This method writes all groups and datasets that have been added,
  /// along with all necessary HDF5 structures.
  ///
  /// Parameters:
  /// - [options]: Optional write options including validation settings
  ///
  /// Returns the complete HDF5 file as a byte list.
  ///
  /// Throws:
  /// - [Hdf5Error] if no datasets have been added
  /// - [Hdf5Error] if writing fails
  /// - [CorruptedFileError] if validation is enabled and fails
  Future<List<int>> finalize({WriteOptions? options}) async {
    options ??= const WriteOptions();
    if (_datasets.isEmpty) {
      throw Hdf5Error(
        operation: 'finalize',
        message: 'No datasets have been added to the file',
      );
    }

    // Clear any previous state
    _writer.clear();
    _addresses.clear();

    // Step 1: Write superblock with placeholder addresses
    final superblockAddress = _writer.position;
    _addresses['superblock'] = superblockAddress;
    final superblock = Superblock.create(
      rootGroupAddress: 0, // Placeholder
      endOfFileAddress: 0, // Placeholder
    );
    superblock.writeTo(_writer);

    // Step 2: Write root group and all subgroups
    await _writeGroupHierarchy();

    // Step 3: Write all datasets
    await _writeAllDatasets();

    // Step 4: Write heaps
    final heapAddresses = _heapManager.writeAll(_writer);
    _addresses.addAll(heapAddresses);

    // Step 5: Update superblock with actual addresses
    final endOfFileAddress = _writer.position;
    _addresses['endOfFile'] = endOfFileAddress;

    Superblock.updateRootGroupAddress(
        _writer, _rootGroup!.objectHeaderAddress!);
    Superblock.updateEndOfFileAddress(_writer, endOfFileAddress);

    // Step 6: Validate file if requested
    if (options.validateOnWrite) {
      validateFile();
    }

    return _writer.bytes;
  }

  // ========== Path Parsing and Group Management ==========

  /// Parse a path into components
  ///
  /// Example: '/group1/group2/data' -> ['group1', 'group2', 'data']
  ///
  /// Throws [InvalidDatasetNameError] if the path is invalid
  List<String> _parsePath(String path) {
    if (path.isEmpty) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Path cannot be empty',
      );
    }
    if (!path.startsWith('/')) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Path must start with "/"',
      );
    }
    if (path.length > 1 && path.endsWith('/')) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Path cannot end with "/"',
      );
    }
    if (path.contains('//')) {
      throw InvalidDatasetNameError(
        datasetName: path,
        reason: 'Path cannot contain consecutive slashes',
      );
    }

    // Remove leading slash and split
    final parts =
        path.substring(1).split('/').where((p) => p.isNotEmpty).toList();

    // Validate each part
    for (final part in parts) {
      if (part == '.' || part == '..') {
        throw InvalidDatasetNameError(
          datasetName: path,
          reason: 'Path cannot contain "." or ".."',
        );
      }
      // Check for invalid characters
      final validPattern = RegExp(r'^[a-zA-Z0-9_]+$');
      if (!validPattern.hasMatch(part)) {
        throw InvalidDatasetNameError(
          datasetName: path,
          reason: 'Path component "$part" contains invalid characters. '
              'Use only alphanumeric characters and underscores',
        );
      }
    }

    return parts;
  }

  /// Get or create a group at the specified path
  ///
  /// Parameters:
  /// - [path]: Full path to the group
  /// - [attributes]: Optional attributes for the group
  /// - [createIntermediate]: Whether to create intermediate groups
  ///
  /// Returns the GroupData for the specified path.
  ///
  /// Throws [GroupPathConflictError] if the path conflicts with existing objects
  /// or [InvalidDatasetNameError] if intermediate groups don't exist and createIntermediate is false.
  GroupData _getOrCreateGroup(
    String path, {
    Map<String, dynamic>? attributes,
    bool createIntermediate = true,
  }) {
    // Handle root group
    if (path == '/') {
      if (_rootGroup == null) {
        _rootGroup = GroupData(
          name: '',
          fullPath: '/',
          attributes: attributes,
        );
        _groups['/'] = _rootGroup!;
      }
      return _rootGroup!;
    }

    // Check if group already exists
    if (_groups.containsKey(path)) {
      final group = _groups[path]!;
      // Merge attributes if provided
      if (attributes != null) {
        group.attributes.addAll(attributes);
      }
      return group;
    }

    // Parse path
    final parts = _parsePath(path);

    // Ensure root group exists
    _getOrCreateGroup('/');

    // Create intermediate groups if needed
    String currentPath = '';
    GroupData? parentGroup = _rootGroup;

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      currentPath += '/$part';

      if (_groups.containsKey(currentPath)) {
        parentGroup = _groups[currentPath];
      } else {
        // Check if a dataset exists with this name
        if (_datasets.containsKey(currentPath)) {
          throw GroupPathConflictError(
            conflictingPath: currentPath,
            existingType: 'dataset',
            attemptedType: 'group',
          );
        }

        // Check if parent has a dataset with this name
        if (parentGroup!.datasets.containsKey(part)) {
          throw GroupPathConflictError(
            conflictingPath: currentPath,
            existingType: 'dataset',
            attemptedType: 'group',
          );
        }

        if (!createIntermediate && i < parts.length - 1) {
          throw InvalidDatasetNameError(
            datasetName: currentPath,
            reason: 'Intermediate group "$currentPath" does not exist. '
                'Set createIntermediateGroups to true to create it automatically.',
          );
        }

        // Create new group
        final isTargetGroup = (i == parts.length - 1);
        final newGroup = GroupData(
          name: part,
          fullPath: currentPath,
          attributes: isTargetGroup ? attributes : null,
        );

        _groups[currentPath] = newGroup;
        parentGroup.addSubgroup(part, newGroup);
        parentGroup = newGroup;
      }
    }

    return _groups[path]!;
  }

  // ========== Writing Methods ==========

  /// Write the group hierarchy (root and all subgroups)
  Future<void> _writeGroupHierarchy() async {
    // Ensure root group exists
    if (_rootGroup == null) {
      _rootGroup = GroupData(name: '', fullPath: '/');
      _groups['/'] = _rootGroup!;
    }

    // Write groups in depth-first order (children before parents)
    await _writeGroupRecursive(_rootGroup!);
  }

  /// Recursively write a group and its children
  Future<void> _writeGroupRecursive(GroupData group) async {
    // Write all subgroups first (depth-first)
    for (final subgroup in group.subgroups.values) {
      await _writeGroupRecursive(subgroup);
    }

    // Now write this group
    // For root group, we need to handle it specially
    if (group.fullPath == '/') {
      // Write root group object header with placeholder symbol table
      final rootGroupAddress = _writeRootGroupHeader();
      group.objectHeaderAddress = rootGroupAddress;
      _addresses['rootGroup'] = rootGroupAddress;
    } else {
      // Write non-root group
      // Only skip if truly empty (no datasets and no subgroups)
      if (group.datasets.isEmpty && group.subgroups.isEmpty) {
        return;
      }

      final groupAddress = await _groupWriter.writeGroup(_writer, group);
      group.objectHeaderAddress = groupAddress;
      _addresses['group_${group.fullPath}'] = groupAddress;
    }
  }

  /// Write root group object header with placeholder symbol table
  int _writeRootGroupHeader() {
    final symbolTableMessageData = _symbolTableWriter.createSymbolTableMessage(
      btreeAddress: 0, // Placeholder
      localHeapAddress: 0, // Placeholder
    );

    final messages = [
      HeaderMessage.forWriting(
        type: MessageType.symbolTable,
        data: symbolTableMessageData,
      ),
    ];

    final headerAddress = _writer.position;
    final header = ObjectHeader(version: 1, messages: messages);
    header.writeTo(_writer);

    return headerAddress;
  }

  /// Write all datasets
  Future<void> _writeAllDatasets() async {
    for (final datasetInfo in _datasets.values) {
      await _writeDatasetWithData(datasetInfo);
    }

    // Update root group symbol table with all children
    _updateRootGroupSymbolTableMulti();
  }

  /// Write a dataset and its data
  Future<void> _writeDatasetWithData(_DatasetInfo datasetInfo) async {
    // Write dataset object header
    final datasetAddress = _writeDataset(
      datasetInfo.array,
      datasetInfo.path,
      datasetInfo.options.attributes,
    );

    // Write dataset raw data
    await _writeDataValues(datasetInfo.array);

    // Update parent group with actual dataset address
    datasetInfo.parentGroup.datasets[datasetInfo.name] = datasetAddress;

    _addresses['dataset_${datasetInfo.path}'] = datasetAddress;
  }

  /// Update the root group's symbol table with all children (multi-dataset version)
  void _updateRootGroupSymbolTableMulti() {
    if (_rootGroup == null || _rootGroup!.isEmpty) {
      return;
    }

    // Calculate where the symbol table should be written
    final symbolTableAddress = _writer.position;

    // Create symbol table entries for all children
    final entries = <SymbolTableEntry>[];

    // Add datasets
    for (final entry in _rootGroup!.datasets.entries) {
      entries.add(SymbolTableEntry(
        name: entry.key,
        objectHeaderAddress: entry.value,
      ));
    }

    // Add subgroups
    for (final entry in _rootGroup!.subgroups.entries) {
      final subgroup = entry.value;
      if (subgroup.objectHeaderAddress != null) {
        entries.add(SymbolTableEntry(
          name: entry.key,
          objectHeaderAddress: subgroup.objectHeaderAddress!,
        ));
      }
    }

    if (entries.isEmpty) {
      return;
    }

    // Write symbol table structures
    final symbolTableData = _symbolTableWriter.write(
      entries: entries,
      startAddress: symbolTableAddress,
    );

    final btreeAddress = symbolTableData['btreeAddress'] as int;
    final localHeapAddress = symbolTableData['localHeapAddress'] as int;
    final bytes = symbolTableData['bytes'] as List<int>;

    // Write the symbol table bytes
    _writer.writeBytes(bytes);

    // Store addresses
    _addresses['btree'] = btreeAddress;
    _addresses['localHeap'] = localHeapAddress;

    // Update the root group header with the correct addresses
    final rootGroupHeaderPosition = Superblock.superblockSize;

    // Create the updated symbol table message
    final symbolTableMessage = _symbolTableWriter.createSymbolTableMessage(
      btreeAddress: btreeAddress,
      localHeapAddress: localHeapAddress,
    );

    // Rebuild the root group header with correct addresses
    final messages = [
      HeaderMessage.forWriting(
        type: MessageType.symbolTable,
        data: symbolTableMessage,
      ),
    ];

    final header = ObjectHeader(version: 1, messages: messages);
    final headerBytes = header.write();

    // Update the root group header in place
    _writer.writeAt(rootGroupHeaderPosition, headerBytes);
  }

  // ========== Validation Methods ==========

  /// Validate the written HDF5 file
  ///
  /// This method performs comprehensive validation of the written file to ensure
  /// it conforms to the HDF5 specification and can be read by standard tools.
  ///
  /// Validation checks include:
  /// - Superblock signature verification
  /// - Object header checksum validation (when applicable)
  /// - B-tree structure validity
  /// - Address reference validation
  ///
  /// Throws [CorruptedFileError] if validation fails
  void validateFile() {
    try {
      _validateSuperblockSignature();
      _validateAddressReferences();
      _validateBTreeStructure();
      // Note: Object header checksums are not used in version 1 format
      // B-tree v2 checksums would be validated if we were using format version 2
    } catch (e) {
      throw CorruptedFileError(
        reason: 'File validation failed',
        details: e.toString(),
      );
    }
  }

  /// Verify the superblock signature is correct
  ///
  /// The HDF5 signature must be present at the beginning of the file:
  /// [0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]
  ///
  /// Throws [InvalidHdf5SignatureError] if signature is invalid
  void _validateSuperblockSignature() {
    final bytes = _writer.bytes;
    if (bytes.length < 8) {
      throw InvalidHdf5SignatureError(
        details: 'File too small to contain superblock signature',
      );
    }

    final expectedSignature = Superblock.signature;
    for (int i = 0; i < expectedSignature.length; i++) {
      if (bytes[i] != expectedSignature[i]) {
        throw InvalidHdf5SignatureError(
          details:
              'Invalid signature byte at position $i: expected ${expectedSignature[i]}, got ${bytes[i]}',
        );
      }
    }
  }

  /// Verify all address references point to valid file locations
  ///
  /// This checks that:
  /// - All addresses are within file bounds
  /// - No addresses point to undefined locations (0xFFFFFFFFFFFFFFFF)
  /// - Critical addresses (root group, data) are set
  ///
  /// Throws [CorruptedFileError] if address validation fails
  void _validateAddressReferences() {
    final fileSize = _writer.bytes.length;

    // Check critical addresses exist
    if (!_addresses.containsKey('rootGroup')) {
      throw CorruptedFileError(
        reason: 'Missing root group address',
        details: 'Root group address was not set during file construction',
      );
    }

    if (!_addresses.containsKey('endOfFile')) {
      throw CorruptedFileError(
        reason: 'Missing end-of-file address',
        details: 'End-of-file address was not set during file construction',
      );
    }

    // Validate all tracked addresses
    for (final entry in _addresses.entries) {
      final name = entry.key;
      final address = entry.value;

      // Check for undefined address marker
      if (address == Superblock.undefinedAddress) {
        throw CorruptedFileError(
          reason: 'Undefined address reference',
          details:
              'Address "$name" points to undefined location (0xFFFFFFFFFFFFFFFF)',
        );
      }

      // Check address is within file bounds
      if (address < 0 || address > fileSize) {
        throw CorruptedFileError(
          reason: 'Address out of bounds',
          details:
              'Address "$name" ($address) is outside file bounds (0-$fileSize)',
        );
      }
    }

    // Validate end-of-file address matches actual file size
    final eofAddress = _addresses['endOfFile']!;
    if (eofAddress != fileSize) {
      throw CorruptedFileError(
        reason: 'End-of-file address mismatch',
        details:
            'End-of-file address ($eofAddress) does not match actual file size ($fileSize)',
      );
    }
  }

  /// Verify B-tree structure validity
  ///
  /// This performs basic validation of B-tree structures:
  /// - B-tree address is set and valid
  /// - B-tree signature is present at the expected location
  ///
  /// Note: Full B-tree validation (node structure, checksums) would require
  /// reading and parsing the entire tree, which is beyond the scope of basic
  /// validation. This method performs lightweight checks only.
  ///
  /// Throws [CorruptedFileError] if B-tree validation fails
  void _validateBTreeStructure() {
    // Check if B-tree address exists
    if (!_addresses.containsKey('btree')) {
      // B-tree is optional if there are no datasets
      if (_datasets.isEmpty) {
        return;
      }
      throw CorruptedFileError(
        reason: 'Missing B-tree address',
        details: 'B-tree address was not set but datasets exist',
      );
    }

    final btreeAddress = _addresses['btree']!;
    final bytes = _writer.bytes;

    // Verify B-tree signature at the expected location
    // B-tree v1 signature is "TREE" (0x54, 0x52, 0x45, 0x45)
    if (btreeAddress + 4 > bytes.length) {
      throw CorruptedFileError(
        reason: 'B-tree address out of bounds',
        details:
            'B-tree address ($btreeAddress) points beyond file end (${bytes.length})',
      );
    }

    final expectedSignature = [0x54, 0x52, 0x45, 0x45]; // "TREE"
    for (int i = 0; i < expectedSignature.length; i++) {
      final byteIndex = btreeAddress + i;
      if (bytes[byteIndex] != expectedSignature[i]) {
        throw CorruptedFileError(
          reason: 'Invalid B-tree signature',
          details:
              'Expected B-tree signature at address $btreeAddress, but found invalid bytes',
        );
      }
    }
  }
}

/// Internal class to track dataset information
class _DatasetInfo {
  final String path;
  final String name;
  final NDArray array;
  final WriteOptions options;
  final GroupData parentGroup;

  _DatasetInfo({
    required this.path,
    required this.name,
    required this.array,
    required this.options,
    required this.parentGroup,
  });
}
