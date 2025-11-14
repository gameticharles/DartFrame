import 'dart:typed_data';
import 'byte_reader.dart';
import 'object_header.dart';
import 'datatype.dart';
export 'datatype.dart' show OpaqueData;
import 'dataspace.dart';
import 'filter.dart';
import 'attribute.dart';
import 'hdf5_error.dart';
import 'btree_v1.dart';
import 'chunk_calculator.dart';
import 'chunk_assembler.dart';
import 'global_heap.dart';

/// HDF5 dataset containing typed array data
class Dataset<T> {
  final int address;
  final ObjectHeader header;
  final Hdf5Datatype<T> datatype;
  final Hdf5Dataspace dataspace;
  final DataLayout layout;
  final FilterPipeline? filterPipeline;
  final String? filePath;
  final String? objectPath;
  final int offsetSize;
  final int hdf5Offset;

  // Cache for global heaps to avoid re-reading
  final Map<int, GlobalHeap> _heapCache = {};

  Dataset({
    required this.address,
    required this.header,
    required this.datatype,
    required this.dataspace,
    required this.layout,
    this.filterPipeline,
    this.filePath,
    this.objectPath,
    this.offsetSize = 8,
    this.hdf5Offset = 0,
  });

  static Future<Dataset> read(ByteReader reader, int address,
      {String? filePath,
      String? objectPath,
      int offsetSize = 8,
      int hdf5Offset = 0}) async {
    hdf5DebugLog('Reading dataset at address 0x${address.toRadixString(16)}');
    final header = await ObjectHeader.read(reader, address,
        filePath: filePath, hdf5Offset: hdf5Offset);

    final datatype = header.findDatatype();
    final dataspace = header.findDataspace();
    final layout = header.findDataLayout();
    final filterPipeline = header.findFilterPipeline();

    if (datatype == null || dataspace == null || layout == null) {
      final missing = <String>[];
      if (datatype == null) missing.add('datatype');
      if (dataspace == null) missing.add('dataspace');
      if (layout == null) missing.add('layout');

      throw CorruptedFileError(
        filePath: filePath,
        objectPath: objectPath,
        reason: 'Invalid dataset: missing required messages',
        details: 'Missing: ${missing.join(", ")}',
      );
    }

    if (filterPipeline != null && filterPipeline.isNotEmpty) {
      hdf5DebugLog('Dataset has filter pipeline: $filterPipeline');
    }

    return Dataset(
      address: address,
      header: header,
      datatype: datatype,
      dataspace: dataspace,
      layout: layout,
      filterPipeline: filterPipeline,
      filePath: filePath,
      objectPath: objectPath,
      offsetSize: offsetSize,
      hdf5Offset: hdf5Offset,
    );
  }

  /// Get or create a global heap from cache
  Future<GlobalHeap> _getGlobalHeap(ByteReader reader, int heapAddress) async {
    if (_heapCache.containsKey(heapAddress)) {
      return _heapCache[heapAddress]!;
    }

    // Save current position before reading heap
    final savedPosition = reader.position;

    final heap = await GlobalHeap.read(reader, heapAddress, filePath: filePath);
    _heapCache[heapAddress] = heap;

    // Restore position after reading heap
    reader.seek(savedPosition);

    return heap;
  }

  Future<List<T>> readData(ByteReader reader) async {
    hdf5DebugLog('Reading dataset data, layout: ${layout.runtimeType}');

    try {
      if (layout is ContiguousLayout) {
        return await _readContiguous(reader, layout as ContiguousLayout);
      } else if (layout is CompactLayout) {
        return await _readCompact(reader, layout as CompactLayout);
      } else if (layout is ChunkedLayout) {
        return await _readChunked(reader, layout as ChunkedLayout);
      }
      throw UnsupportedFeatureError(
        filePath: filePath,
        objectPath: objectPath,
        feature: 'Data layout: ${layout.runtimeType}',
      );
    } catch (e) {
      if (e is Hdf5Error) rethrow;
      throw DataReadError(
        filePath: filePath,
        objectPath: objectPath,
        reason: 'Failed to read dataset data',
        originalError: e,
      );
    }
  }

  Future<List<T>> _readContiguous(
    ByteReader reader,
    ContiguousLayout layout,
  ) async {
    reader.seek(layout.address);
    final totalElements = dataspace.totalElements;
    final result = <T>[];

    for (int i = 0; i < totalElements; i++) {
      result.add(await _readElement(reader));
    }

    return result;
  }

  Future<List<T>> _readCompact(
    ByteReader reader,
    CompactLayout layout,
  ) async {
    // Create a temporary ByteReader from the compact data
    final compactData = Uint8List.fromList(layout.data);
    final tempReader = ByteReader.fromBytes(compactData);

    final totalElements = dataspace.totalElements;
    final result = <T>[];

    for (int i = 0; i < totalElements; i++) {
      result.add(await _readElement(tempReader));
    }

    return result;
  }

  Future<List<T>> _readChunked(
    ByteReader reader,
    ChunkedLayout layout,
  ) async {
    hdf5DebugLog(
        'Reading chunked dataset: btree=0x${layout.address.toRadixString(16)}, '
        'chunkDims=${layout.chunkDimensions}, datasetDims=${dataspace.dimensions}');

    // Create chunk calculator
    final calculator = ChunkCalculator(
      datasetDimensions: dataspace.dimensions,
      chunkDimensions: layout.chunkDimensions,
    );

    // Create B-tree for chunk lookup
    // Note: The B-tree always stores coordinates with an extra dimension for the element size
    // This is true even without filters
    final btreeDimensionality = layout.chunkDimensions.length + 1;

    final btree = BTreeV1(
      address: layout.address,
      reader: reader,
      dimensionality: btreeDimensionality,
      offsetSize: offsetSize,
      filePath: filePath,
      objectPath: objectPath,
    );

    hdf5DebugLog(
      'B-tree dimensionality: $btreeDimensionality, chunk dims: ${layout.chunkDimensions}',
    );

    // Create chunk assembler
    final assembler = ChunkAssembler<T>(
      calculator: calculator,
      btree: btree,
      datatype: datatype,
      filterPipeline: filterPipeline,
      hdf5Offset: hdf5Offset,
      filePath: filePath,
      objectPath: objectPath,
    );

    // Assemble and return dataset
    return await assembler.assembleDataset(reader);
  }

  Future<T> _readElement(ByteReader reader) async {
    // Handle string datatypes (class 3)
    if (datatype.isString && datatype.stringInfo != null) {
      final stringInfo = datatype.stringInfo!;

      if (stringInfo.isVariableLength) {
        // Variable-length strings are stored as a global heap reference
        // Read the vlen reference (16 bytes)
        final vlenBytes = await reader.readBytes(16);
        final vlenRef = VlenReference.fromBytes(vlenBytes);

        hdf5DebugLog(
            'Reading vlen string: $vlenRef at position 0x${reader.position.toRadixString(16)}');

        // Read from global heap (with caching)
        try {
          final heap =
              await _getGlobalHeap(reader, vlenRef.heapAddress + hdf5Offset);
          final data = heap.readData(vlenRef.objectIndex);

          // Decode the string
          return stringInfo.decodeString(data) as T;
        } catch (e) {
          hdf5DebugLog('Failed to read vlen string from global heap: $e');
          throw DataReadError(
            filePath: filePath,
            objectPath: objectPath,
            reason: 'Failed to read variable-length string',
            originalError: e,
          );
        }
      } else {
        // Fixed-length string
        final bytes = await reader.readBytes(datatype.size);
        return stringInfo.decodeString(bytes) as T;
      }
    }

    // Handle enum datatypes (class 8)
    if (datatype.isEnum &&
        datatype.enumInfo != null &&
        datatype.baseType != null) {
      final enumInfo = datatype.enumInfo!;
      final baseType = datatype.baseType!;

      // Read the underlying integer value
      int value;
      switch (baseType.size) {
        case 1:
          value = await reader.readUint8();
          break;
        case 2:
          value = await reader.readUint16();
          break;
        case 4:
          value = await reader.readUint32();
          break;
        case 8:
          value = (await reader.readUint64()).toInt();
          break;
        default:
          throw UnsupportedDatatypeError(
            filePath: filePath,
            objectPath: objectPath,
            datatypeInfo: 'Enum with base type size=${baseType.size}',
          );
      }

      // Return just the integer value
      return value as T;
    }

    // Handle array datatypes (class 10)
    if (datatype.isArray &&
        datatype.arrayInfo != null &&
        datatype.baseType != null) {
      final arrayInfo = datatype.arrayInfo!;
      final baseType = datatype.baseType!;
      final totalElements = arrayInfo.totalElements;

      final result = <dynamic>[];
      for (int i = 0; i < totalElements; i++) {
        // Create a temporary dataset with the base type to read each element
        final tempDatatype = baseType;
        final element = await _readElementWithType(reader, tempDatatype);
        result.add(element);
      }

      return result as T;
    }

    // Handle reference datatypes (class 7)
    if (datatype.isReference && datatype.referenceInfo != null) {
      // Read the reference as raw bytes
      // Object references are typically 8 bytes (address)
      // Region references are larger (address + region info)
      final refBytes = await reader.readBytes(datatype.size);

      // Return a map with reference info
      return {
        'type': datatype.referenceInfo!.type.name,
        'data': refBytes,
      } as T;
    }

    // Handle opaque datatypes (class 5)
    if (datatype.isOpaque) {
      final bytes = await reader.readBytes(datatype.size);
      return OpaqueData(data: Uint8List.fromList(bytes), tag: datatype.tag)
          as T;
    }

    // Handle bitfield datatypes (class 4)
    if (datatype.isBitfield) {
      // Read bitfield as raw bytes
      final bytes = await reader.readBytes(datatype.size);
      return Uint8List.fromList(bytes) as T;
    }

    // Handle time datatypes (class 2)
    if (datatype.isTime) {
      // Time is typically stored as Unix timestamp (seconds since epoch)
      // Can be integer or floating-point, typically 4 or 8 bytes
      int timestamp;

      if (datatype.size == 4) {
        // 32-bit timestamp (seconds)
        timestamp = await reader.readInt32();
      } else if (datatype.size == 8) {
        // 64-bit timestamp (seconds or milliseconds)
        timestamp = await reader.readInt64();
      } else {
        throw UnsupportedDatatypeError(
          filePath: filePath,
          objectPath: objectPath,
          datatypeInfo: 'Time datatype with size=${datatype.size} bytes',
        );
      }

      // Convert Unix timestamp to DateTime
      // If timestamp is very large, it might be in milliseconds
      DateTime dateTime;
      if (timestamp > 1e10) {
        // Likely milliseconds since epoch
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        // Seconds since epoch
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }

      return dateTime as T;
    }

    // Handle variable-length datatypes (class 9)
    if (datatype.isVariableLength && datatype.baseType != null) {
      // Read the vlen reference (16 bytes)
      final vlenBytes = await reader.readBytes(16);
      final vlenRef = VlenReference.fromBytes(vlenBytes);

      hdf5DebugLog('Reading vlen data: $vlenRef');

      // Read from global heap (with caching)
      try {
        final heap =
            await _getGlobalHeap(reader, vlenRef.heapAddress + hdf5Offset);
        final data = heap.readData(vlenRef.objectIndex);

        final baseType = datatype.baseType!;

        // Special case: vlen(uint8) is typically a string
        if (baseType.classId == 0 && baseType.size == 1) {
          // Treat as UTF-8 string
          return String.fromCharCodes(data) as T;
        }

        // Create a temporary reader for the vlen data
        final vlenReader = ByteReader.fromBytes(data);

        // Read elements based on base type
        final result = <dynamic>[];

        // The length field is the number of elements, not bytes
        final numElements = vlenRef.length;

        for (int i = 0; i < numElements; i++) {
          final element = await _readElementWithType(vlenReader, baseType);
          result.add(element);
        }

        return result as T;
      } catch (e) {
        hdf5DebugLog('Failed to read vlen data from global heap: $e');
        throw DataReadError(
          filePath: filePath,
          objectPath: objectPath,
          reason: 'Failed to read variable-length data',
          originalError: e,
        );
      }
    }

    // Handle compound datatypes (class 6)
    if (datatype.isCompound && datatype.compoundInfo != null) {
      final compoundInfo = datatype.compoundInfo!;
      final startPos = reader.position;
      final result = <String, dynamic>{};

      for (final field in compoundInfo.fields) {
        // Seek to field offset
        reader.seek(startPos + field.offset);

        // Read field value based on its datatype
        final value = await _readFieldValue(reader, field.datatype);
        result[field.name] = value;
      }

      // Move reader to end of compound structure
      reader.seek(startPos + datatype.size);

      return result as T;
    }

    // Match by classId and size for numeric types
    // Class 0: Fixed-point (integer)
    // Class 1: Floating-point
    if (datatype.classId == 0 && datatype.size == 1) {
      // int8
      return await reader.readInt8() as T;
    } else if (datatype.classId == 0 && datatype.size == 2) {
      // int16
      return await reader.readInt16() as T;
    } else if (datatype.classId == 0 && datatype.size == 4) {
      // int32
      return await reader.readInt32() as T;
    } else if (datatype.classId == 0 && datatype.size == 8) {
      // int64
      return await reader.readInt64() as T;
    } else if (datatype.classId == 1 && datatype.size == 4) {
      // float32
      return await reader.readFloat32() as T;
    } else if (datatype.classId == 1 && datatype.size == 8) {
      // float64
      return await reader.readFloat64() as T;
    } else {
      throw UnsupportedDatatypeError(
        filePath: filePath,
        objectPath: objectPath,
        datatypeInfo: 'class=${datatype.classId}, size=${datatype.size} bytes',
      );
    }
  }

  /// Read an element with a specific datatype (helper for array types)
  Future<dynamic> _readElementWithType(
      ByteReader reader, Hdf5Datatype elementType) async {
    // Handle string types
    if (elementType.isString && elementType.stringInfo != null) {
      final stringInfo = elementType.stringInfo!;
      if (stringInfo.isVariableLength) {
        // Read vlen string reference
        final vlenBytes = await reader.readBytes(16);
        final vlenRef = VlenReference.fromBytes(vlenBytes);

        try {
          final heap =
              await _getGlobalHeap(reader, vlenRef.heapAddress + hdf5Offset);
          final data = heap.readData(vlenRef.objectIndex);
          return stringInfo.decodeString(data);
        } catch (e) {
          hdf5DebugLog('Failed to read vlen string in array: $e');
          return '[vlen string error]';
        }
      }
      final bytes = await reader.readBytes(elementType.size);
      return stringInfo.decodeString(bytes);
    }

    // Handle enum types
    if (elementType.isEnum &&
        elementType.enumInfo != null &&
        elementType.baseType != null) {
      final enumInfo = elementType.enumInfo!;
      final baseType = elementType.baseType!;

      int value;
      switch (baseType.size) {
        case 1:
          value = await reader.readUint8();
          break;
        case 2:
          value = await reader.readUint16();
          break;
        case 4:
          value = await reader.readUint32();
          break;
        case 8:
          value = (await reader.readUint64()).toInt();
          break;
        default:
          throw UnsupportedDatatypeError(
            filePath: filePath,
            objectPath: objectPath,
            datatypeInfo: 'Enum with base type size=${baseType.size}',
          );
      }

      return {
        'value': value,
        'name': enumInfo.getNameByValue(value) ?? 'UNKNOWN',
      };
    }

    // Handle numeric types
    if (elementType.classId == 0 && elementType.size == 1) {
      return await reader.readInt8();
    } else if (elementType.classId == 0 && elementType.size == 2) {
      return await reader.readInt16();
    } else if (elementType.classId == 0 && elementType.size == 4) {
      return await reader.readInt32();
    } else if (elementType.classId == 0 && elementType.size == 8) {
      return await reader.readInt64();
    } else if (elementType.classId == 1 && elementType.size == 4) {
      return await reader.readFloat32();
    } else if (elementType.classId == 1 && elementType.size == 8) {
      return await reader.readFloat64();
    }

    throw UnsupportedDatatypeError(
      filePath: filePath,
      objectPath: objectPath,
      datatypeInfo:
          'Element type: class=${elementType.classId}, size=${elementType.size} bytes',
    );
  }

  /// Read a field value from a compound datatype
  Future<dynamic> _readFieldValue(
      ByteReader reader, Hdf5Datatype fieldType) async {
    // Handle string fields
    if (fieldType.isString && fieldType.stringInfo != null) {
      final stringInfo = fieldType.stringInfo!;
      if (stringInfo.isVariableLength) {
        // Read vlen string reference
        final vlenBytes = await reader.readBytes(16);
        final vlenRef = VlenReference.fromBytes(vlenBytes);

        try {
          final heap =
              await _getGlobalHeap(reader, vlenRef.heapAddress + hdf5Offset);
          final data = heap.readData(vlenRef.objectIndex);
          return stringInfo.decodeString(data);
        } catch (e) {
          hdf5DebugLog('Failed to read vlen string in compound: $e');
          return '[vlen string error]';
        }
      }
      final bytes = await reader.readBytes(fieldType.size);
      return stringInfo.decodeString(bytes);
    }

    // Handle array fields
    if (fieldType.isArray &&
        fieldType.arrayInfo != null &&
        fieldType.baseType != null) {
      final arrayInfo = fieldType.arrayInfo!;
      final baseType = fieldType.baseType!;
      final totalElements = arrayInfo.totalElements;

      // Calculate element size from field size if base type size is 0
      int elementSize = baseType.size;
      if (elementSize == 0 && totalElements > 0) {
        elementSize = fieldType.size ~/ totalElements;
      }

      // Determine if we should try float first (heuristic for broken base type parsing)
      bool tryFloatFirst = false;
      if (baseType.classId == 0 && (elementSize == 4 || elementSize == 8)) {
        // Peek at first value to guess type
        final testPos = reader.position;
        if (elementSize == 4) {
          final testFloat = await reader.readFloat32();
          reader.seek(testPos);
          final testInt = await reader.readInt32();
          reader.seek(testPos);

          // If the float value is reasonable and different from the int value,
          // and the float has a fractional part, it's likely a float
          if (testFloat.isFinite &&
              testFloat.abs() < 1e6 &&
              testFloat.abs() > 1e-6 &&
              (testFloat - testFloat.truncate()).abs() > 1e-6) {
            tryFloatFirst = true;
          }
        }
      }

      final result = <dynamic>[];
      for (int i = 0; i < totalElements; i++) {
        // Read each element based on the base type
        dynamic element;

        // Use float if we determined it's likely a float
        if (tryFloatFirst || baseType.classId == 1) {
          // Float types
          switch (elementSize) {
            case 4:
              element = await reader.readFloat32();
              break;
            case 8:
              element = await reader.readFloat64();
              break;
            default:
              throw UnsupportedDatatypeError(
                filePath: filePath,
                objectPath: objectPath,
                datatypeInfo: 'Array with float base type size=$elementSize',
              );
          }
        } else if (baseType.classId == 0) {
          // Integer types
          switch (elementSize) {
            case 1:
              element = await reader.readInt8();
              break;
            case 2:
              element = await reader.readInt16();
              break;
            case 4:
              element = await reader.readInt32();
              break;
            case 8:
              element = await reader.readInt64();
              break;
            default:
              throw UnsupportedDatatypeError(
                filePath: filePath,
                objectPath: objectPath,
                datatypeInfo: 'Array with integer base type size=$elementSize',
              );
          }
        } else if (baseType.classId == 3) {
          // String types
          final bytes = await reader.readBytes(elementSize);
          if (baseType.stringInfo != null) {
            element = baseType.stringInfo!.decodeString(bytes);
          } else {
            element = String.fromCharCodes(bytes.where((b) => b != 0));
          }
        } else {
          throw UnsupportedDatatypeError(
            filePath: filePath,
            objectPath: objectPath,
            datatypeInfo:
                'Array with unsupported base type class=${baseType.classId}',
          );
        }
        result.add(element);
      }

      return result;
    }

    // Handle enum fields
    if (fieldType.isEnum &&
        fieldType.enumInfo != null &&
        fieldType.baseType != null) {
      final enumInfo = fieldType.enumInfo!;
      final baseType = fieldType.baseType!;

      int value;
      switch (baseType.size) {
        case 1:
          value = await reader.readUint8();
          break;
        case 2:
          value = await reader.readUint16();
          break;
        case 4:
          value = await reader.readUint32();
          break;
        case 8:
          value = (await reader.readUint64()).toInt();
          break;
        default:
          throw UnsupportedDatatypeError(
            filePath: filePath,
            objectPath: objectPath,
            datatypeInfo: 'Enum with base type size=${baseType.size}',
          );
      }

      // Return just the integer value for enum fields in compounds
      return value;
    }

    // Handle numeric fields
    // Class 0: Fixed-point (integer)
    // Class 1: Floating-point
    if (fieldType.classId == 0 && fieldType.size == 1) {
      return await reader.readInt8();
    } else if (fieldType.classId == 0 && fieldType.size == 2) {
      return await reader.readInt16();
    } else if (fieldType.classId == 0 && fieldType.size == 4) {
      return await reader.readInt32();
    } else if (fieldType.classId == 0 && fieldType.size == 8) {
      return await reader.readInt64();
    } else if (fieldType.classId == 1 && fieldType.size == 4) {
      return await reader.readFloat32();
    } else if (fieldType.classId == 1 && fieldType.size == 8) {
      return await reader.readFloat64();
    }

    throw UnsupportedDatatypeError(
      filePath: filePath,
      objectPath: objectPath,
      datatypeInfo:
          'Field type: class=${fieldType.classId}, size=${fieldType.size} bytes',
    );
  }

  List<int> get shape => dataspace.dimensions;

  /// List all attribute names for this dataset
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

  /// Get all attributes for this dataset
  List<Hdf5Attribute> get attributes => header.findAttributes();

  /// Inspect dataset metadata without reading data
  ///
  /// Returns a map containing:
  /// - `shape`: List of dimensions
  /// - `dtype`: Data type name
  /// - `size`: Total number of elements
  /// - `storage`: Storage layout type ('contiguous', 'chunked', or 'compact')
  /// - `compression`: Compression info (if compressed)
  /// - `chunkDimensions`: Chunk dimensions (if chunked)
  /// - `attributes`: Map of attribute names to values
  ///
  /// Example:
  /// ```dart
  /// final info = dataset.inspect();
  /// print('Shape: ${info['shape']}');
  /// print('Storage: ${info['storage']}');
  /// if (info['compression'] != null) {
  ///   print('Compressed with: ${info['compression']}');
  /// }
  /// ```
  Map<String, dynamic> inspect() {
    final info = <String, dynamic>{
      'shape': dataspace.dimensions,
      'dtype': _getDtypeName(),
      'size': dataspace.totalElements,
      'storage': _getStorageType(),
    };

    // Add chunking info if chunked
    if (layout is ChunkedLayout) {
      final chunkedLayout = layout as ChunkedLayout;
      info['chunkDimensions'] = chunkedLayout.chunkDimensions;
    }

    // Add compression info if present
    if (filterPipeline != null && filterPipeline!.isNotEmpty) {
      info['compression'] = _getCompressionInfo();
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

  String _getDtypeName() {
    if (datatype.isString) {
      final stringInfo = datatype.stringInfo!;
      if (stringInfo.isVariableLength) {
        return 'string (variable-length)';
      } else {
        return 'string (fixed-length, ${datatype.size} bytes)';
      }
    }

    if (datatype.isCompound) {
      final compoundInfo = datatype.compoundInfo!;
      final fieldNames = compoundInfo.fields.map((f) => f.name).join(', ');
      return 'compound {$fieldNames}';
    }

    // Numeric types
    if (datatype.classId == 0) {
      // Integer
      final signed = datatype.size == 1 ? 'int' : 'int';
      return '$signed${datatype.size * 8}';
    } else if (datatype.classId == 1) {
      // Float
      return 'float${datatype.size * 8}';
    }

    return 'unknown (class=${datatype.classId}, size=${datatype.size})';
  }

  String _getStorageType() {
    if (layout is ContiguousLayout) {
      return 'contiguous';
    } else if (layout is ChunkedLayout) {
      return 'chunked';
    } else if (layout is CompactLayout) {
      return 'compact';
    }
    return 'unknown';
  }

  Map<String, dynamic> _getCompressionInfo() {
    final filters = <Map<String, dynamic>>[];

    for (final filter in filterPipeline!.filters) {
      final filterInfo = <String, dynamic>{
        'name': filter.name,
        'id': filter.id,
      };

      // Add filter-specific details if available
      if (filter.clientData.isNotEmpty) {
        filterInfo['clientData'] = filter.clientData;
      }

      filters.add(filterInfo);
    }

    return {
      'filters': filters,
      'count': filters.length,
    };
  }

  /// Reads a slice of the dataset
  ///
  /// Parameters:
  /// - [start]: Starting indices for each dimension (inclusive)
  /// - [end]: Ending indices for each dimension (exclusive)
  /// - [step]: Step size for each dimension (default: 1 for all)
  ///
  /// Returns a list containing the sliced data.
  ///
  /// Example:
  /// ```dart
  /// // Read rows 10-20 from a 2D dataset
  /// final slice = await dataset.readSlice(
  ///   reader,
  ///   start: [10, 0],
  ///   end: [20, null], // null means to the end
  /// );
  /// ```
  Future<List<T>> readSlice(
    ByteReader reader, {
    required List<int?> start,
    required List<int?> end,
    List<int>? step,
  }) async {
    // Validate and normalize slice parameters
    final dims = dataspace.dimensions;
    if (start.length != dims.length || end.length != dims.length) {
      throw ArgumentError(
          'Slice dimensions must match dataset dimensions (${dims.length})');
    }

    final normalizedStart = <int>[];
    final normalizedEnd = <int>[];
    final normalizedStep = step ?? List.filled(dims.length, 1);

    for (int i = 0; i < dims.length; i++) {
      normalizedStart.add(start[i] ?? 0);
      normalizedEnd.add(end[i] ?? dims[i]);

      if (normalizedStart[i] < 0 || normalizedStart[i] >= dims[i]) {
        throw RangeError('Start index $i out of range: ${normalizedStart[i]}');
      }
      if (normalizedEnd[i] < 0 || normalizedEnd[i] > dims[i]) {
        throw RangeError('End index $i out of range: ${normalizedEnd[i]}');
      }
      if (normalizedStart[i] >= normalizedEnd[i]) {
        throw ArgumentError(
            'Start must be less than end for dimension $i: ${normalizedStart[i]} >= ${normalizedEnd[i]}');
      }
    }

    // For now, read the entire dataset and slice it
    // TODO: Optimize for chunked datasets to only read necessary chunks
    final allData = await readData(reader);

    return _sliceData(allData, normalizedStart, normalizedEnd, normalizedStep);
  }

  /// Slices data from a flat list based on multidimensional indices
  List<T> _sliceData(
    List<T> data,
    List<int> start,
    List<int> end,
    List<int> step,
  ) {
    final dims = dataspace.dimensions;
    final result = <T>[];

    // Calculate strides for each dimension
    final strides = <int>[];
    int stride = 1;
    for (int i = dims.length - 1; i >= 0; i--) {
      strides.insert(0, stride);
      stride *= dims[i];
    }

    // Generate indices for the slice
    _generateSliceIndices(
      dims,
      start,
      end,
      step,
      strides,
      0,
      0,
      data,
      result,
    );

    return result;
  }

  void _generateSliceIndices(
    List<int> dims,
    List<int> start,
    List<int> end,
    List<int> step,
    List<int> strides,
    int dimIndex,
    int currentOffset,
    List<T> data,
    List<T> result,
  ) {
    if (dimIndex == dims.length) {
      result.add(data[currentOffset]);
      return;
    }

    for (int i = start[dimIndex]; i < end[dimIndex]; i += step[dimIndex]) {
      final offset = currentOffset + i * strides[dimIndex];
      _generateSliceIndices(
        dims,
        start,
        end,
        step,
        strides,
        dimIndex + 1,
        offset,
        data,
        result,
      );
    }
  }

  /// Read dataset as boolean array
  ///
  /// Converts uint8 values to boolean (0 = false, non-zero = true).
  /// Only works if the dataset has integer type with size 1.
  ///
  /// Example:
  /// ```dart
  /// final boolArray = await dataset.readAsBoolean(reader);
  /// print('First value: ${boolArray[0]}');
  /// ```
  Future<List<bool>> readAsBoolean(ByteReader reader) async {
    if (!datatype.isBoolean) {
      throw UnsupportedFeatureError(
        filePath: filePath,
        objectPath: objectPath,
        feature: 'Reading as boolean',
        details: 'Dataset must have integer type with size 1 (uint8/int8)',
      );
    }

    final data = await readData(reader);
    return data.map((value) => (value as int) != 0).toList();
  }

  /// Read dataset as DateTime array
  ///
  /// Converts integer timestamps to DateTime objects.
  /// Supports both seconds and milliseconds since Unix epoch (1970-01-01).
  /// Automatically detects the unit based on the magnitude of values.
  ///
  /// Parameters:
  /// - [reader]: ByteReader for file access
  /// - [unit]: Optional unit specification ('seconds', 'milliseconds', 'auto')
  ///           Default is 'auto' which auto-detects based on value magnitude
  ///
  /// Example:
  /// ```dart
  /// final dates = await dataset.readAsDateTime(reader);
  /// print('First date: ${dates[0]}');
  ///
  /// // Force interpretation as seconds
  /// final datesSeconds = await dataset.readAsDateTime(reader, unit: 'seconds');
  /// ```
  Future<List<DateTime>> readAsDateTime(
    ByteReader reader, {
    String unit = 'auto',
  }) async {
    // Check if datatype is integer
    if (datatype.classId != 0) {
      throw UnsupportedFeatureError(
        filePath: filePath,
        objectPath: objectPath,
        feature: 'Reading as DateTime',
        details: 'Dataset must have integer type (int32 or int64)',
      );
    }

    final data = await readData(reader);
    final result = <DateTime>[];

    for (final value in data) {
      if (value is! int) {
        throw DataReadError(
          filePath: filePath,
          objectPath: objectPath,
          reason: 'Expected integer timestamp, got ${value.runtimeType}',
        );
      }

      DateTime dateTime;
      if (unit == 'seconds') {
        // Force seconds interpretation
        dateTime = DateTime.fromMillisecondsSinceEpoch(value * 1000);
      } else if (unit == 'milliseconds') {
        // Force milliseconds interpretation
        dateTime = DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        // Auto-detect: if value > 1e10, likely milliseconds
        if (value > 1e10) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(value);
        } else {
          dateTime = DateTime.fromMillisecondsSinceEpoch(value * 1000);
        }
      }

      result.add(dateTime);
    }

    return result;
  }

  /// Creates an iterator for reading the dataset in chunks
  ///
  /// This is useful for processing large datasets that don't fit in memory.
  /// The iterator yields chunks of data based on the specified chunk size.
  ///
  /// Parameters:
  /// - [reader]: ByteReader for file access
  /// - [chunkSize]: Number of elements to read per iteration
  ///
  /// Returns a stream of data chunks.
  ///
  /// Example:
  /// ```dart
  /// await for (final chunk in dataset.readChunked(reader, chunkSize: 1000)) {
  ///   // Process chunk
  ///   print('Processing ${chunk.length} elements');
  /// }
  /// ```
  Stream<List<T>> readChunked(ByteReader reader,
      {int chunkSize = 1000}) async* {
    final totalElements = dataspace.totalElements;
    final dims = dataspace.dimensions;

    // For 1D datasets, we can read in simple chunks
    if (dims.length == 1) {
      for (int offset = 0; offset < totalElements; offset += chunkSize) {
        final end = (offset + chunkSize < totalElements)
            ? offset + chunkSize
            : totalElements;

        final chunk = await readSlice(
          reader,
          start: [offset],
          end: [end],
        );
        yield chunk;
      }
    } else {
      // For multi-dimensional datasets, read row by row
      // This is a simple implementation; could be optimized further
      final rowSize = dims.last;
      final numRows = totalElements ~/ rowSize;

      for (int row = 0; row < numRows; row += chunkSize ~/ rowSize) {
        final endRow = (row + chunkSize ~/ rowSize < numRows)
            ? row + chunkSize ~/ rowSize
            : numRows;

        // Calculate start and end for all dimensions
        final start = List<int?>.filled(dims.length, 0);
        final end = List<int?>.filled(dims.length, null);

        // Set the first dimension to the row range
        start[0] = row;
        end[0] = endRow;

        final chunk = await readSlice(reader, start: start, end: end);
        yield chunk;
      }
    }
  }

  @override
  String toString() => 'Dataset(shape=$shape, dtype=${datatype.toString()})';
}
