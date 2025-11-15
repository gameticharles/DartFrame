import 'dart:typed_data';
import '../../file_helper/file_io.dart';
import 'superblock.dart';
import 'byte_reader.dart';
import 'group.dart';
import 'dataset.dart';
import 'object_header.dart';
import 'hdf5_error.dart';
import 'metadata_cache.dart';

/// HDF5 file reader with pure Dart implementation
class Hdf5File {
  final String _filePath;
  late final RandomAccessFileBase _raf;
  late final Superblock _superblock;
  late final Group _rootGroup;
  late final MetadataCache _cache;
  final Map<String, Hdf5File> _externalFiles = {}; // Cache for external files

  // Static FileIO instance - shared across all Hdf5File instances
  static final FileIO _fileIO = FileIO();

  Hdf5File._(this._filePath);

  /// Opens an HDF5 file for reading
  ///
  /// Opens the specified HDF5 file and reads its superblock and root group.
  /// The file must exist and be a valid HDF5 file.
  ///
  /// Parameters:
  /// - [pathOrData]: On desktop, pass the file path as a String.
  ///                 On web, pass HTMLInputElement or Uint8List containing the file data.
  /// - [fileName]: Optional file name for error messages (used mainly on web, defaults to pathOrData if String)
  ///
  /// Returns a [Hdf5File] instance that can be used to read datasets and groups.
  ///
  /// Throws:
  /// - [FileAccessError] if the file doesn't exist or cannot be opened
  /// - [UnsupportedVersionError] if the HDF5 version is not supported
  /// - [CorruptedFileError] if the file is corrupted or invalid
  ///
  /// Example (desktop):
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// // ... use the file
  /// await file.close();
  /// ```
  ///
  /// Example (web with file input):
  /// ```dart
  /// final inputElement = document.querySelector('#fileInput') as HTMLInputElement;
  /// final file = await Hdf5File.open(inputElement, fileName: 'data.h5');
  /// // ... use the file
  /// await file.close();
  /// ```
  ///
  /// Example (web with bytes):
  /// ```dart
  /// final bytes = Uint8List(...);
  /// final file = await Hdf5File.open(bytes, fileName: 'data.h5');
  /// // ... use the file
  /// await file.close();
  /// ```
  static Future<Hdf5File> open(
    dynamic pathOrData, {
    String? fileName,
  }) async {
    // Determine the file name for logging and error messages
    final String effectiveFileName;
    final bool isFilePath = pathOrData is String;

    if (fileName != null) {
      effectiveFileName = fileName;
    } else if (isFilePath) {
      effectiveFileName = pathOrData;
    } else {
      effectiveFileName = 'uploaded_file.h5';
    }

    hdf5DebugLog('Opening HDF5 file: $effectiveFileName');

    // Check if file exists (only for file paths on desktop)
    if (isFilePath && !await _fileIO.fileExists(pathOrData)) {
      throw FileAccessError(
        filePath: effectiveFileName,
        reason: 'File not found',
      );
    }

    final hdf5File = Hdf5File._(effectiveFileName);
    try {
      await hdf5File._initialize(pathOrData);
    } catch (e) {
      if (e is Hdf5Error) {
        rethrow;
      }
      throw FileAccessError(
        filePath: effectiveFileName,
        reason: 'Failed to open file',
        originalError: e,
      );
    }
    return hdf5File;
  }

  Future<void> _initialize(dynamic pathOrUploadInput) async {
    _raf = await _fileIO.openRandomAccess(pathOrUploadInput);
    final reader = ByteReader(_raf);

    // Initialize metadata cache
    _cache = MetadataCache();

    try {
      _superblock = await Superblock.read(reader, filePath: _filePath);
      _cache.cacheSuperblock(_superblock);

      // Adjust addresses by HDF5 start offset (e.g., 512 for MATLAB files)
      int rootAddress = _superblock.rootGroupObjectHeaderAddress +
          _superblock.hdf5StartOffset;

      hdf5DebugLog(
          'Reading root group at address 0x${rootAddress.toRadixString(16)}');
      _rootGroup = await Group.read(reader, rootAddress,
          hdf5Offset: _superblock.hdf5StartOffset, filePath: _filePath);
      _cache.cacheRootGroup(_rootGroup);
    } catch (e) {
      await _raf.close();
      rethrow;
    }
  }

  /// Closes the HDF5 file and releases system resources
  ///
  /// Always call this method when you're done with the file to ensure
  /// proper cleanup of file handles and resources.
  /// Also closes any external files that were opened through external links.
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// try {
  ///   // ... use the file
  /// } finally {
  ///   await file.close();
  /// }
  /// ```
  Future<void> close() async {
    // Close all external files
    for (final extFile in _externalFiles.values) {
      await extFile.close();
    }
    _externalFiles.clear();

    // Close main file
    await _raf.close();
  }

  /// Gets the root group of the HDF5 file
  ///
  /// The root group contains all top-level datasets and groups in the file.
  /// You can access its children using the [Group.children] property.
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// print('Root children: ${file.root.children}');
  /// ```
  Group get root => _rootGroup;

  /// Gets the superblock containing file metadata
  ///
  /// The superblock contains important file-level information including:
  /// - HDF5 version information
  /// - Offset and length sizes
  /// - File addresses and structure
  /// - Version numbers for various components
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// print('HDF5 Version: ${file.superblock.version}');
  /// print('Offset Size: ${file.superblock.offsetSize} bytes');
  /// ```
  Superblock get superblock => _superblock;

  /// Gets a dataset by its path in the HDF5 file
  ///
  /// Navigates through the file hierarchy to find and return the specified dataset.
  /// The path should start with '/' and use '/' as a separator for nested groups.
  /// Automatically resolves soft links during navigation.
  ///
  /// Parameters:
  /// - [path]: Full path to the dataset (e.g., '/data' or '/group/dataset')
  ///
  /// Returns a [Dataset] object containing metadata and data access methods.
  ///
  /// Throws:
  /// - [DatasetNotFoundError] if the dataset doesn't exist
  /// - [GroupNotFoundError] if a parent group in the path doesn't exist
  /// - [NotADatasetError] if the path points to a group instead of a dataset
  /// - [CircularLinkError] if a circular soft link is detected
  /// - [UnsupportedFeatureError] if an external link is encountered
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final dataset = await file.dataset('/measurements');
  /// print('Shape: ${dataset.dataspace.dimensions}');
  /// print('Dtype: ${dataset.datatype}');
  /// ```
  Future<Dataset> dataset(String path) async {
    hdf5DebugLog('Accessing dataset: $path');
    final filePath = _filePath;

    if (path == '/') {
      throw NotADatasetError(
        filePath: filePath,
        objectPath: path,
        actualType: 'root group',
      );
    }

    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    var currentGroup = _rootGroup;
    final visitedLinks = <String>{}; // For circular link detection

    // Navigate to parent group
    for (int i = 0; i < parts.length - 1; i++) {
      hdf5DebugLog('Navigating through group: ${parts[i]}');
      final result = await _resolveChild(
        currentGroup,
        parts[i],
        '/${parts.sublist(0, i).join('/')}',
        visitedLinks,
      );
      currentGroup = result;
    }

    final datasetName = parts.last;
    final datasetAddress = await _resolveChildAddress(
      currentGroup,
      datasetName,
      path,
      visitedLinks,
    );

    if (datasetAddress == null) {
      throw DatasetNotFoundError(
        filePath: filePath,
        datasetPath: path,
        details: 'Available children: ${currentGroup.children.join(", ")}',
      );
    }

    // Adjust address by HDF5 start offset
    final adjustedAddress = datasetAddress + _superblock.hdf5StartOffset;

    // Check if this is actually a dataset
    final reader = ByteReader(_raf);
    final header = await ObjectHeader.read(reader, adjustedAddress,
        filePath: filePath, hdf5Offset: _superblock.hdf5StartOffset);
    final objectType = header.determineObjectType();

    if (objectType == Hdf5ObjectType.group) {
      throw NotADatasetError(
        filePath: filePath,
        objectPath: path,
        actualType: 'group',
      );
    } else if (objectType == Hdf5ObjectType.unknown) {
      throw NotADatasetError(
        filePath: filePath,
        objectPath: path,
        actualType: 'unknown (${header.getObjectTypeDescription()})',
      );
    }

    hdf5DebugLog(
        'Reading dataset at address 0x${adjustedAddress.toRadixString(16)}');
    return await Dataset.read(reader, adjustedAddress,
        filePath: filePath,
        objectPath: path,
        offsetSize: _superblock.offsetSize,
        hdf5Offset: _superblock.hdf5StartOffset);
  }

  /// Resolves a child in a group, following soft links if necessary
  ///
  /// Returns the Group object for the child
  Future<Group> _resolveChild(
    Group currentGroup,
    String childName,
    String currentPath,
    Set<String> visitedLinks,
  ) async {
    final filePath = _filePath;
    final fullPath =
        currentPath == '/' ? '/$childName' : '$currentPath/$childName';

    // Check for circular links
    if (visitedLinks.contains(fullPath)) {
      throw CircularLinkError(
        filePath: filePath,
        linkPath: fullPath,
        visitedPaths: visitedLinks.toList(),
      );
    }

    // Check if this is a soft link
    final link = currentGroup.getLinkMessage(childName);
    if (link != null && link.isSoftLink) {
      visitedLinks.add(fullPath);
      hdf5DebugLog('Following soft link: $childName -> ${link.targetPath}');

      // Resolve the soft link target
      final targetPath = link.targetPath!;
      return await _resolveSoftLinkToGroup(targetPath, visitedLinks);
    }

    // Check if this is an external link
    if (link != null && link.isExternalLink) {
      visitedLinks.add(fullPath);
      hdf5DebugLog(
          'Following external link: $childName -> ${link.externalFilePath}:${link.externalObjectPath}');

      // Open external file and navigate to target
      return await _resolveExternalLink(
        link.externalFilePath!,
        link.externalObjectPath!,
        currentPath,
        visitedLinks,
      );
    }

    // Regular hard link or direct child
    final childAddress = currentGroup.getChildAddress(childName);
    if (childAddress == null) {
      throw GroupNotFoundError(
        filePath: filePath,
        groupPath: childName,
        parentPath: currentPath,
      );
    }

    final adjustedAddress = childAddress + _superblock.hdf5StartOffset;

    // Check cache first
    final cachedGroup = _cache.getGroup(adjustedAddress);
    if (cachedGroup != null) {
      hdf5DebugLog(
          'Using cached group at address 0x${adjustedAddress.toRadixString(16)}');
      return cachedGroup;
    }

    final group = await Group.read(ByteReader(_raf), adjustedAddress,
        hdf5Offset: _superblock.hdf5StartOffset, filePath: filePath);
    _cache.cacheGroup(adjustedAddress, group);
    return group;
  }

  /// Resolves a soft link target path to a group
  Future<Group> _resolveSoftLinkToGroup(
    String targetPath,
    Set<String> visitedLinks, {
    String? currentPath,
  }) async {
    // Parse the target path
    if (targetPath.startsWith('/')) {
      // Absolute path
      return await group(targetPath);
    } else {
      // Relative path - resolve relative to current location
      if (currentPath == null) {
        throw UnsupportedFeatureError(
          filePath: _filePath,
          feature: 'Relative soft links without context',
          details: 'Relative path: $targetPath',
        );
      }

      // Resolve relative path
      final resolvedPath = _resolveRelativePath(currentPath, targetPath);
      hdf5DebugLog('Resolved relative path: $targetPath -> $resolvedPath');
      return await group(resolvedPath);
    }
  }

  /// Resolves a relative path against a base path
  String _resolveRelativePath(String basePath, String relativePath) {
    // Split paths into components
    final baseComponents =
        basePath.split('/').where((p) => p.isNotEmpty).toList();
    final relativeComponents = relativePath.split('/');

    // Start with base path components
    final result = List<String>.from(baseComponents);

    // Process relative path components
    for (final component in relativeComponents) {
      if (component == '.' || component.isEmpty) {
        // Current directory - do nothing
        continue;
      } else if (component == '..') {
        // Parent directory - go up one level
        if (result.isNotEmpty) {
          result.removeLast();
        }
      } else {
        // Regular component - add to path
        result.add(component);
      }
    }

    // Reconstruct absolute path
    return '/${result.join('/')}';
  }

  /// Resolves a child address, following soft links if necessary
  Future<int?> _resolveChildAddress(
    Group currentGroup,
    String childName,
    String currentPath,
    Set<String> visitedLinks,
  ) async {
    final fullPath = currentPath;

    // Check for circular links
    if (visitedLinks.contains(fullPath)) {
      throw CircularLinkError(
        filePath: _filePath,
        linkPath: fullPath,
        visitedPaths: visitedLinks.toList(),
      );
    }

    // Check if this is a soft link
    final link = currentGroup.getLinkMessage(childName);
    if (link != null && link.isSoftLink) {
      visitedLinks.add(fullPath);
      hdf5DebugLog('Following soft link: $childName -> ${link.targetPath}');

      // Resolve the soft link target to get the final address
      final targetPath = link.targetPath!;
      if (targetPath.startsWith('/')) {
        // Absolute path - navigate to it
        final targetParts =
            targetPath.split('/').where((p) => p.isNotEmpty).toList();
        var targetGroup = _rootGroup;

        // Navigate to parent group
        for (int i = 0; i < targetParts.length - 1; i++) {
          targetGroup = await _resolveChild(
            targetGroup,
            targetParts[i],
            '/${targetParts.sublist(0, i).join('/')}',
            visitedLinks,
          );
        }

        // Get the final object address
        return targetGroup.getChildAddress(targetParts.last);
      } else {
        throw UnsupportedFeatureError(
          filePath: _filePath,
          feature: 'Relative soft links',
          details: 'Relative path: $targetPath',
        );
      }
    }

    // Check if this is an external link
    if (link != null && link.isExternalLink) {
      visitedLinks.add(fullPath);
      hdf5DebugLog(
          'Following external link for dataset: $childName -> ${link.externalFilePath}:${link.externalObjectPath}');

      // For datasets in external files, we need to get the address from the external file
      // This is more complex, so for now we'll throw an error with a better message
      throw UnsupportedFeatureError(
        filePath: _filePath,
        feature: 'External links to datasets',
        details:
            'External link to ${link.externalFilePath}:${link.externalObjectPath}. '
            'Use group() to navigate to external groups, then access datasets.',
      );
    }

    // Regular hard link or direct child
    return currentGroup.getChildAddress(childName);
  }

  /// Resolves an external link by opening the external file
  Future<Group> _resolveExternalLink(
    String externalFilePath,
    String externalObjectPath,
    String currentPath,
    Set<String> visitedLinks,
  ) async {
    // Resolve external file path relative to current file
    final resolvedPath = _fileIO.resolvePath(_filePath, externalFilePath);

    // Check if file exists
    if (!await _fileIO.fileExists(resolvedPath)) {
      // Try the path as-is (might be absolute)
      if (!await _fileIO.fileExists(externalFilePath)) {
        throw FileAccessError(
          filePath: externalFilePath,
          reason: 'External file not found',
        );
      }
    }

    // Use the resolved path or original if it exists
    final finalPath = await _fileIO.fileExists(resolvedPath)
        ? resolvedPath
        : externalFilePath;

    // Check if we already have this file open
    if (!_externalFiles.containsKey(finalPath)) {
      hdf5DebugLog('Opening external file: $finalPath');
      _externalFiles[finalPath] = await Hdf5File.open(finalPath);
    }

    final extFile = _externalFiles[finalPath]!;

    // Navigate to the target object in the external file
    return await extFile.group(externalObjectPath);
  }

  /// Reads a dataset and returns its data as a list
  ///
  /// This is a convenience method that combines [dataset] and [Dataset.readData].
  /// It reads the entire dataset into memory as a list.
  ///
  /// Parameters:
  /// - [path]: Full path to the dataset (e.g., '/data' or '/group/dataset')
  ///
  /// Returns the dataset's data as a list. The structure depends on the dataset:
  /// - 1D datasets return a flat list
  /// - 2D datasets return a list of lists (rows)
  /// - Compound datasets return a list of maps
  ///
  /// Throws:
  /// - [DatasetNotFoundError] if the dataset doesn't exist
  /// - [UnsupportedFeatureError] if the dataset uses unsupported features
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final data = await file.readDataset('/measurements');
  /// print('First value: ${data[0]}');
  /// ```
  Future<List<dynamic>> readDataset(String path) async {
    final ds = await dataset(path);
    return await ds.readData(ByteReader(_raf));
  }

  /// Gets a group by its path in the HDF5 file
  ///
  /// Navigates through the file hierarchy to find and return the specified group.
  /// Groups are containers that can hold datasets and other groups.
  /// Automatically resolves soft links during navigation.
  ///
  /// Parameters:
  /// - [path]: Full path to the group (e.g., '/experiment' or '/data/subset')
  ///   Use '/' to get the root group
  ///
  /// Returns a [Group] object containing the group's children and attributes.
  ///
  /// Throws:
  /// - [GroupNotFoundError] if the group doesn't exist
  /// - [CircularLinkError] if a circular soft link is detected
  /// - [UnsupportedFeatureError] if an external link is encountered
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final group = await file.group('/experiment');
  /// print('Children: ${group.children}');
  /// final attrs = group.header.findAttributes();
  /// print('Attributes: ${attrs.length}');
  /// ```
  Future<Group> group(String path) async {
    hdf5DebugLog('Accessing group: $path');

    if (path == '/') return _rootGroup;

    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    var currentGroup = _rootGroup;
    final visitedLinks = <String>{}; // For circular link detection

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      hdf5DebugLog('Navigating to group: $part');
      currentGroup = await _resolveChild(
        currentGroup,
        part,
        i > 0 ? '/${parts.sublist(0, i).join('/')}' : '/',
        visitedLinks,
      );
    }

    return currentGroup;
  }

  /// Lists the children (datasets and groups) at the specified path
  ///
  /// Currently only supports listing the root group ('/').
  /// For other paths, use [group] to get the group and access its children.
  ///
  /// Parameters:
  /// - [path]: Path to list (currently only '/' is supported)
  ///
  /// Returns a list of child names (without paths).
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final children = file.list('/');
  /// print('Root contains: $children');
  /// ```
  List<String> list(String path) {
    if (path == '/') return _rootGroup.children;
    throw UnimplementedError(
        'Listing subgroups requires loading the target group');
  }

  /// Determines the type of object at the given path
  ///
  /// Checks whether the specified path points to a dataset, group, or unknown object.
  /// This is useful for traversing the file structure without knowing the types in advance.
  ///
  /// Parameters:
  /// - [path]: Full path to the object (e.g., '/data' or '/experiment')
  ///
  /// Returns one of:
  /// - `'dataset'`: The path points to a dataset
  /// - `'group'`: The path points to a group
  /// - `'unknown'`: The object type cannot be determined
  ///
  /// Throws:
  /// - [PathNotFoundError] if the path doesn't exist
  /// - [GroupNotFoundError] if a parent group in the path doesn't exist
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final type = await file.getObjectType('/data');
  /// if (type == 'dataset') {
  ///   final data = await file.readDataset('/data');
  /// }
  /// ```
  Future<String> getObjectType(String path) async {
    hdf5DebugLog('Getting object type for: $path');
    final filePath = _filePath;

    if (path == '/') return 'group';

    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    var currentGroup = _rootGroup;

    // Navigate to parent group
    for (int i = 0; i < parts.length - 1; i++) {
      final childAddress = currentGroup.getChildAddress(parts[i]);
      if (childAddress == null) {
        throw GroupNotFoundError(
          filePath: filePath,
          groupPath: parts[i],
          parentPath: i > 0 ? '/${parts.sublist(0, i).join('/')}' : '/',
        );
      }
      final adjustedAddress = childAddress + _superblock.hdf5StartOffset;

      // Check cache first
      final cachedGroup = _cache.getGroup(adjustedAddress);
      if (cachedGroup != null) {
        currentGroup = cachedGroup;
      } else {
        currentGroup = await Group.read(ByteReader(_raf), adjustedAddress,
            hdf5Offset: _superblock.hdf5StartOffset, filePath: filePath);
        _cache.cacheGroup(adjustedAddress, currentGroup);
      }
    }

    final objectName = parts.last;
    final objectAddress = currentGroup.getChildAddress(objectName);

    if (objectAddress == null) {
      throw PathNotFoundError(
        filePath: filePath,
        objectPath: path,
        details: 'Available children: ${currentGroup.children.join(", ")}',
      );
    }

    final adjustedAddress = objectAddress + _superblock.hdf5StartOffset;
    final reader = ByteReader(_raf);
    final header = await ObjectHeader.read(reader, adjustedAddress,
        filePath: filePath, hdf5Offset: _superblock.hdf5StartOffset);
    final objectType = header.determineObjectType();

    switch (objectType) {
      case Hdf5ObjectType.dataset:
        return 'dataset';
      case Hdf5ObjectType.group:
        return 'group';
      case Hdf5ObjectType.unknown:
        return 'unknown';
    }
  }

  /// Gets basic file information from the superblock
  ///
  /// Returns metadata about the HDF5 file format and structure.
  ///
  /// The returned map contains:
  /// - `version`: HDF5 superblock version
  /// - `offsetSize`: Size of offsets in bytes (typically 8)
  /// - `lengthSize`: Size of lengths in bytes (typically 8)
  /// - `rootChildren`: List of top-level objects in the file
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// print('HDF5 version: ${file.info['version']}');
  /// print('Root children: ${file.info['rootChildren']}');
  /// ```
  Map<String, dynamic> get info => {
        'version': _superblock.version,
        'offsetSize': _superblock.offsetSize,
        'lengthSize': _superblock.lengthSize,
        'rootChildren': _rootGroup.children,
      };

  /// Recursively lists all groups and datasets in the file
  ///
  /// Returns a hierarchical structure representation with metadata for each object.
  /// This method traverses the entire file structure without reading dataset data.
  ///
  /// Returns a map where keys are paths and values contain:
  /// - `type`: 'dataset' or 'group'
  /// - `shape`: List of dimensions (datasets only)
  /// - `dtype`: Data type name (datasets only)
  /// - `size`: Total number of elements (datasets only)
  /// - `storage`: Storage layout type (datasets only)
  /// - `compression`: Compression info if compressed (datasets only)
  /// - `chunkDimensions`: Chunk dimensions if chunked (datasets only)
  /// - `childCount`: Number of children (groups only)
  /// - `children`: List of child names (groups only)
  /// - `attributes`: Map of attribute names to values
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final structure = await file.listRecursive();
  /// for (final entry in structure.entries) {
  ///   print('${entry.key}: ${entry.value['type']}');
  /// }
  /// ```
  Future<Map<String, Map<String, dynamic>>> listRecursive() async {
    final structure = <String, Map<String, dynamic>>{};
    await _listRecursiveHelper('/', _rootGroup, structure);
    return structure;
  }

  Future<void> _listRecursiveHelper(
    String path,
    Group group,
    Map<String, Map<String, dynamic>> structure,
  ) async {
    for (final childName in group.children) {
      final childPath = path == '/' ? '/$childName' : '$path/$childName';

      try {
        final objectType = await getObjectType(childPath);

        if (objectType == 'dataset') {
          final ds = await dataset(childPath);
          structure[childPath] = ds.inspect();
          structure[childPath]!['type'] = 'dataset';
        } else if (objectType == 'group') {
          final grp = await this.group(childPath);
          structure[childPath] = grp.inspect();
          structure[childPath]!['type'] = 'group';

          // Recursively process children
          await _listRecursiveHelper(childPath, grp, structure);
        }
      } catch (e) {
        // If we can't read an object, note it in the structure
        structure[childPath] = {
          'type': 'error',
          'error': e.toString(),
        };
      }
    }
  }

  /// Prints a tree-like visualization of the file structure
  ///
  /// Generates a hierarchical tree representation showing all groups and datasets
  /// with their metadata. This provides a quick overview of the file contents.
  ///
  /// Parameters:
  /// - [showAttributes]: Whether to display attributes (default: true)
  /// - [showSizes]: Whether to display dataset sizes (default: true)
  ///
  /// Example output:
  /// ```
  /// /
  /// ├── data (dataset)
  /// │   Shape: [100, 50]
  /// │   Type: float64
  /// │   Storage: chunked [10, 10]
  /// │   Compression: gzip (level 4)
  /// │   Attributes: units=meters
  /// └── experiment (group)
  ///     ├── measurements (dataset)
  ///     │   Shape: [1000]
  ///     │   Type: int32
  ///     └── metadata (group)
  /// ```
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// await file.printTree();
  /// ```
  Future<void> printTree({
    bool showAttributes = true,
    bool showSizes = true,
  }) async {
    final structure = await listRecursive();
    print('/');
    _printTreeHelper(
      structure,
      '/',
      '',
      showAttributes: showAttributes,
      showSizes: showSizes,
    );
  }

  void _printTreeHelper(
    Map<String, Map<String, dynamic>> structure,
    String currentPath,
    String prefix, {
    required bool showAttributes,
    required bool showSizes,
  }) {
    // Get children at current level
    final children = structure.keys.where((path) {
      if (currentPath == '/') {
        return path.split('/').where((p) => p.isNotEmpty).length == 1;
      }
      final parentPath = path.substring(0, path.lastIndexOf('/'));
      return parentPath == currentPath;
    }).toList()
      ..sort();

    for (int i = 0; i < children.length; i++) {
      final childPath = children[i];
      final isLast = i == children.length - 1;
      final info = structure[childPath]!;
      final childName = childPath.split('/').last;

      // Print the item
      final connector = isLast ? '└── ' : '├── ';
      final typeLabel = info['type'] == 'dataset' ? 'dataset' : 'group';
      print('$prefix$connector$childName ($typeLabel)');

      // Print details
      final detailPrefix = isLast ? '    ' : '│   ';
      if (info['type'] == 'dataset') {
        _printDatasetDetails(
          info,
          '$prefix$detailPrefix',
          showAttributes: showAttributes,
          showSizes: showSizes,
        );
      } else if (info['type'] == 'group') {
        _printGroupDetails(
          info,
          '$prefix$detailPrefix',
          showAttributes: showAttributes,
        );
      }

      // Recursively print children for groups
      if (info['type'] == 'group') {
        _printTreeHelper(
          structure,
          childPath,
          '$prefix$detailPrefix',
          showAttributes: showAttributes,
          showSizes: showSizes,
        );
      }
    }
  }

  void _printDatasetDetails(
    Map<String, dynamic> info,
    String prefix, {
    required bool showAttributes,
    required bool showSizes,
  }) {
    // Shape
    final shape = info['shape'] as List;
    print('${prefix}Shape: [${shape.join(', ')}]');

    // Data type
    print('${prefix}Type: ${info['dtype']}');

    // Size
    if (showSizes) {
      print('${prefix}Size: ${info['size']} elements');
    }

    // Storage
    final storage = info['storage'];
    if (storage == 'chunked' && info.containsKey('chunkDimensions')) {
      final chunkDims = info['chunkDimensions'] as List;
      print('${prefix}Storage: chunked [${chunkDims.join(', ')}]');
    } else {
      print('${prefix}Storage: $storage');
    }

    // Compression
    if (info.containsKey('compression')) {
      final compression = info['compression'] as Map<String, dynamic>;
      final filters = compression['filters'] as List;
      for (final filter in filters) {
        final filterMap = filter as Map<String, dynamic>;
        final name = filterMap['name'];
        if (filterMap.containsKey('level')) {
          print('${prefix}Compression: $name (level ${filterMap['level']})');
        } else {
          print('${prefix}Compression: $name');
        }
      }
    }

    // Attributes
    if (showAttributes && info.containsKey('attributes')) {
      final attrs = info['attributes'] as Map<String, dynamic>;
      if (attrs.isNotEmpty) {
        final attrStrs = attrs.entries.map((e) => '${e.key}=${e.value}');
        print('${prefix}Attributes: ${attrStrs.join(', ')}');
      }
    }
  }

  void _printGroupDetails(
    Map<String, dynamic> info,
    String prefix, {
    required bool showAttributes,
  }) {
    // Child count
    print('${prefix}Children: ${info['childCount']}');

    // Attributes
    if (showAttributes && info.containsKey('attributes')) {
      final attrs = info['attributes'] as Map<String, dynamic>;
      if (attrs.isNotEmpty) {
        final attrStrs = attrs.entries.map((e) => '${e.key}=${e.value}');
        print('${prefix}Attributes: ${attrStrs.join(', ')}');
      }
    }
  }

  /// Gets summary statistics about the file structure
  ///
  /// Returns a map containing:
  /// - `totalDatasets`: Total number of datasets
  /// - `totalGroups`: Total number of groups
  /// - `totalObjects`: Total number of objects (datasets + groups)
  /// - `maxDepth`: Maximum nesting depth
  /// - `datasetsByType`: Count of datasets by data type
  /// - `compressedDatasets`: Number of compressed datasets
  /// - `chunkedDatasets`: Number of chunked datasets
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final stats = await file.getSummaryStats();
  /// print('Total datasets: ${stats['totalDatasets']}');
  /// print('Compressed: ${stats['compressedDatasets']}');
  /// ```
  Future<Map<String, dynamic>> getSummaryStats() async {
    final structure = await listRecursive();

    int datasetCount = 0;
    int groupCount = 0;
    int compressedCount = 0;
    int chunkedCount = 0;
    int maxDepth = 0;
    final datasetsByType = <String, int>{};

    for (final entry in structure.entries) {
      final path = entry.key;
      final info = entry.value;

      // Calculate depth
      final depth = path.split('/').where((p) => p.isNotEmpty).length;
      if (depth > maxDepth) maxDepth = depth;

      if (info['type'] == 'dataset') {
        datasetCount++;

        // Count by type
        final dtype = info['dtype'] as String;
        datasetsByType[dtype] = (datasetsByType[dtype] ?? 0) + 1;

        // Count compressed
        if (info.containsKey('compression')) {
          compressedCount++;
        }

        // Count chunked
        if (info['storage'] == 'chunked') {
          chunkedCount++;
        }
      } else if (info['type'] == 'group') {
        groupCount++;
      }
    }

    return {
      'totalDatasets': datasetCount,
      'totalGroups': groupCount,
      'totalObjects': datasetCount + groupCount,
      'maxDepth': maxDepth,
      'datasetsByType': datasetsByType,
      'compressedDatasets': compressedCount,
      'chunkedDatasets': chunkedCount,
    };
  }

  /// Prints the file structure with datasets, groups, and their attributes
  ///
  /// This method recursively traverses the HDF5 file structure and prints
  /// information about each dataset and group, including their attributes.
  ///
  /// Example output:
  /// ```
  /// File structure:
  ///
  /// /data:
  ///   Type: Dataset
  ///   Shape: (10, 10)
  ///   Dtype: float64
  ///   Attributes (8):
  ///     units: meters (type: str)
  ///     version: 1.0 (type: float64)
  /// ```
  Future<void> printStructure() async {
    print('File structure:\n');
    final structure = await getStructure();

    for (final entry in structure.entries) {
      final path = entry.key;
      final info = entry.value;

      print('$path:');
      print('  Type: ${info['type'] == 'dataset' ? 'Dataset' : 'Group'}');

      if (info['type'] == 'dataset') {
        final shape = info['shape'] as List;
        print('  Shape: (${shape.join(', ')})');
        print('  Dtype: ${info['dtype']}');
      }

      final attributes = info['attributes'] as Map<String, dynamic>;
      if (attributes.isNotEmpty) {
        print('  Attributes (${attributes.length}):');
        for (final attrEntry in attributes.entries) {
          final attrName = attrEntry.key;
          final attrInfo = attrEntry.value as Map<String, dynamic>;
          final valueStr = _formatValue(attrInfo['value']);
          final typeName = attrInfo['type'];
          print('    $attrName: $valueStr (type: $typeName)');
        }
      }

      print('');
    }
  }

  /// Gets the file structure as a map
  ///
  /// Returns a structured representation of the HDF5 file including all
  /// datasets, groups, and their attributes. The structure can be easily
  /// converted to JSON or used programmatically.
  ///
  /// Returns a map where keys are paths and values contain:
  /// - `type`: 'dataset' or 'group'
  /// - `shape`: List of dimensions (datasets only)
  /// - `dtype`: Data type name (datasets only)
  /// - `attributes`: Map of attribute names to their info
  ///
  /// Example:
  /// ```dart
  /// final structure = await file.getStructure();
  /// print(structure['/data']['shape']); // [10, 10]
  /// print(structure['/data']['attributes']['units']['value']); // 'meters'
  /// ```
  Future<Map<String, dynamic>> getStructure() async {
    final structure = <String, dynamic>{};
    await _buildStructureRecursive('/', _rootGroup, structure);
    return structure;
  }

  Future<void> _buildStructureRecursive(
      String path, Group group, Map<String, dynamic> structure) async {
    for (final childName in group.children) {
      final childPath = path == '/' ? '/$childName' : '$path/$childName';
      final objectType = await getObjectType(childPath);

      if (objectType == 'dataset') {
        structure[childPath] = await _getDatasetStructure(childPath);
      } else if (objectType == 'group') {
        structure[childPath] = await _getGroupStructure(childPath);
        // Recursively process children of this group
        final childGroup = await this.group(childPath);
        await _buildStructureRecursive(childPath, childGroup, structure);
      }
    }
  }

  Future<Map<String, dynamic>> _getDatasetStructure(String path) async {
    final ds = await dataset(path);

    final info = <String, dynamic>{
      'type': 'dataset',
      'shape': ds.dataspace.dimensions,
      'dtype': _getDtypeName(ds.datatype),
      'attributes': <String, dynamic>{},
    };

    // Add attributes
    final attributes = ds.header.findAttributes();
    for (final attr in attributes) {
      info['attributes'][attr.name] = {
        'value': attr.value,
        'type': _getTypeName(attr.value),
      };
    }

    return info;
  }

  Future<Map<String, dynamic>> _getGroupStructure(String path) async {
    final grp = await group(path);

    final info = <String, dynamic>{
      'type': 'group',
      'attributes': <String, dynamic>{},
    };

    // Add attributes
    final attributes = grp.header.findAttributes();
    for (final attr in attributes) {
      info['attributes'][attr.name] = {
        'value': attr.value,
        'type': _getTypeName(attr.value),
      };
    }

    return info;
  }

  String _getDtypeName(dynamic datatype) {
    if (datatype.classId == 0) {
      // Integer
      return datatype.size == 4 ? 'int32' : 'int${datatype.size * 8}';
    } else if (datatype.classId == 1) {
      // Float
      return datatype.size == 8 ? 'float64' : 'float32';
    }
    return 'unknown';
  }

  String _getTypeName(dynamic value) {
    if (value is String) return 'str';
    if (value is int) return 'int32';
    if (value is double) return 'float64';
    if (value is List) return 'ndarray';
    return 'unknown';
  }

  String _formatValue(dynamic value) {
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is List) {
      if (value.every((e) => e is int)) {
        return '[${value.join(' ')}]';
      } else if (value.every((e) => e is double)) {
        return '[${value.map((e) => e.toStringAsFixed(1).padLeft(5)).join(' ')}]';
      }
      return value.toString();
    }
    return value.toString();
  }

  /// Gets metadata cache statistics
  ///
  /// Returns information about cached metadata including:
  /// - Number of cached groups
  /// - Number of cached datatypes
  /// - Number of cached dataspaces
  /// - Total cache entries
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final stats = file.cacheStats;
  /// print('Cached groups: ${stats['groups']}');
  /// print('Total entries: ${stats['totalEntries']}');
  /// ```
  Map<String, dynamic> get cacheStats => _cache.stats;

  /// Clears all metadata caches
  ///
  /// This can be useful to free memory after processing large files
  /// or when you want to force re-reading of metadata.
  ///
  /// Note: This does not clear B-tree node caches in datasets.
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// // ... process data
  /// file.clearCache();
  /// ```
  void clearCache() {
    _cache.clear();
  }

  /// Reads a slice of a dataset
  ///
  /// This method allows reading a subset of a dataset without loading
  /// the entire dataset into memory. Useful for large datasets.
  ///
  /// Parameters:
  /// - [path]: Full path to the dataset
  /// - [start]: Starting indices for each dimension (inclusive)
  /// - [end]: Ending indices for each dimension (exclusive, null means to the end)
  /// - [step]: Step size for each dimension (default: 1 for all)
  ///
  /// Returns a list containing the sliced data.
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// // Read rows 10-20, columns 5-15 from a 2D dataset
  /// final slice = await file.readDatasetSlice(
  ///   '/data',
  ///   start: [10, 5],
  ///   end: [20, 15],
  /// );
  /// ```
  Future<List<dynamic>> readDatasetSlice(
    String path, {
    required List<int?> start,
    required List<int?> end,
    List<int>? step,
  }) async {
    final ds = await dataset(path);
    return await ds.readSlice(
      ByteReader(_raf),
      start: start,
      end: end,
      step: step,
    );
  }

  /// Creates a stream for reading a dataset in chunks
  ///
  /// This is useful for processing large datasets that don't fit in memory.
  /// The stream yields chunks of data that can be processed incrementally.
  ///
  /// Parameters:
  /// - [path]: Full path to the dataset
  /// - [chunkSize]: Number of elements to read per iteration (default: 1000)
  ///
  /// Returns a stream of data chunks.
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('large_data.h5');
  /// await for (final chunk in file.readDatasetChunked('/data', chunkSize: 10000)) {
  ///   // Process each chunk
  ///   print('Processing ${chunk.length} elements');
  ///   // ... do something with chunk
  /// }
  /// ```
  Stream<List<dynamic>> readDatasetChunked(
    String path, {
    int chunkSize = 1000,
  }) async* {
    final ds = await dataset(path);
    await for (final chunk
        in ds.readChunked(ByteReader(_raf), chunkSize: chunkSize)) {
      yield chunk;
    }
  }

  /// Resolves an object reference to get the referenced object's path
  ///
  /// Object references in HDF5 are stored as addresses. This method
  /// converts a reference address to the path of the referenced object.
  ///
  /// Parameters:
  /// - [referenceData]: The raw reference data (typically 8 bytes containing an address)
  ///
  /// Returns information about the referenced object including:
  /// - `address`: The object's address in the file
  /// - `type`: The object type ('dataset', 'group', or 'unknown')
  ///
  /// Throws:
  /// - [UnsupportedFeatureError] if the reference format is not supported
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final refData = ...; // Reference data from a dataset
  /// final refInfo = await file.resolveObjectReference(refData);
  /// print('Referenced object at address: 0x${refInfo['address'].toRadixString(16)}');
  /// print('Object type: ${refInfo['type']}');
  /// ```
  Future<Map<String, dynamic>> resolveObjectReference(
      List<int> referenceData) async {
    if (referenceData.length < 8) {
      throw UnsupportedFeatureError(
        filePath: _filePath,
        feature: 'Object reference resolution',
        details: 'Reference data too short: ${referenceData.length} bytes',
      );
    }

    // Object references are typically stored as 8-byte addresses
    // Read the address from the reference data
    final buffer = ByteData.view(Uint8List.fromList(referenceData).buffer);
    final address = buffer.getUint64(0, Endian.little);

    // Adjust address by HDF5 start offset
    final adjustedAddress = address + _superblock.hdf5StartOffset;

    // Read the object header to determine type
    final reader = ByteReader(_raf);
    final header = await ObjectHeader.read(reader, adjustedAddress,
        filePath: _filePath, hdf5Offset: _superblock.hdf5StartOffset);
    final objectType = header.determineObjectType();

    String typeString;
    switch (objectType) {
      case Hdf5ObjectType.dataset:
        typeString = 'dataset';
        break;
      case Hdf5ObjectType.group:
        typeString = 'group';
        break;
      case Hdf5ObjectType.unknown:
        typeString = 'unknown';
        break;
    }

    return {
      'address': adjustedAddress,
      'type': typeString,
    };
  }

  /// Resolves a region reference to get information about the referenced region
  ///
  /// Region references in HDF5 point to a specific region within a dataset.
  /// This method extracts information about the referenced dataset and region.
  ///
  /// Parameters:
  /// - [referenceData]: The raw region reference data
  ///
  /// Returns information about the referenced region including:
  /// - `address`: The dataset's address in the file
  /// - `type`: Always 'region'
  /// - `regionInfo`: Information about the selected region (if available)
  ///
  /// Note: Full region reference support requires additional implementation
  /// for parsing region selection information.
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final refData = ...; // Region reference data from a dataset
  /// final refInfo = await file.resolveRegionReference(refData);
  /// print('Referenced dataset at address: 0x${refInfo['address'].toRadixString(16)}');
  /// ```
  Future<Map<String, dynamic>> resolveRegionReference(
      List<int> referenceData) async {
    if (referenceData.length < 8) {
      throw UnsupportedFeatureError(
        filePath: _filePath,
        feature: 'Region reference resolution',
        details: 'Reference data too short: ${referenceData.length} bytes',
      );
    }

    // Region references contain:
    // - Object address (8 bytes)
    // - Region selection information (variable length)
    final buffer = ByteData.view(Uint8List.fromList(referenceData).buffer);
    final address = buffer.getUint64(0, Endian.little);

    // Adjust address by HDF5 start offset
    final adjustedAddress = address + _superblock.hdf5StartOffset;

    // TO DO: Parse region selection information from remaining bytes
    // This would include hyperslab selection, point selection, etc.

    return {
      'address': adjustedAddress,
      'type': 'region',
      'regionInfo': 'Region selection parsing not yet implemented',
    };
  }

  /// Reads the object referenced by an object reference
  ///
  /// This is a convenience method that resolves an object reference
  /// and returns the referenced object (dataset or group).
  ///
  /// Parameters:
  /// - [referenceData]: The raw reference data
  ///
  /// Returns the referenced object (Dataset or Group).
  ///
  /// Throws:
  /// - [UnsupportedFeatureError] if the reference cannot be resolved
  ///
  /// Example:
  /// ```dart
  /// final file = await Hdf5File.open('data.h5');
  /// final refData = ...; // Reference data from a dataset
  /// final obj = await file.readObjectReference(refData);
  /// if (obj is Dataset) {
  ///   final data = await obj.readData(ByteReader(file._raf));
  ///   print('Referenced dataset data: $data');
  /// }
  /// ```
  Future<dynamic> readObjectReference(List<int> referenceData) async {
    final refInfo = await resolveObjectReference(referenceData);
    final address = refInfo['address'] as int;
    final type = refInfo['type'] as String;

    final reader = ByteReader(_raf);

    if (type == 'dataset') {
      return await Dataset.read(reader, address,
          filePath: _filePath,
          offsetSize: _superblock.offsetSize,
          hdf5Offset: _superblock.hdf5StartOffset);
    } else if (type == 'group') {
      return await Group.read(reader, address,
          hdf5Offset: _superblock.hdf5StartOffset, filePath: _filePath);
    } else {
      throw UnsupportedFeatureError(
        filePath: _filePath,
        feature: 'Reading referenced object of type: $type',
      );
    }
  }
}
