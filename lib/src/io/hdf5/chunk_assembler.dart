import 'byte_reader.dart';
import 'btree_v1.dart';
import 'chunk_calculator.dart';
import 'datatype.dart';
import 'filter.dart';
import 'hdf5_error.dart';
import 'global_heap.dart';

/// Assembles chunks into a complete dataset array
class ChunkAssembler<T> {
  final ChunkCalculator calculator;
  final BTreeV1 btree;
  final Hdf5Datatype<T> datatype;
  final FilterPipeline? filterPipeline;
  final int hdf5Offset;
  final String? filePath;
  final String? objectPath;

  ChunkAssembler({
    required this.calculator,
    required this.btree,
    required this.datatype,
    this.filterPipeline,
    this.hdf5Offset = 0,
    this.filePath,
    this.objectPath,
  });

  /// Reads and assembles all chunks into a complete dataset
  Future<List<T>> assembleDataset(ByteReader reader) async {
    final datasetDims = calculator.datasetDimensions;
    final totalElements = datasetDims.reduce((a, b) => a * b);

    hdf5DebugLog(
        'Assembling chunked dataset: dims=$datasetDims, total=$totalElements elements');

    // Initialize result array
    final result =
        List<T>.filled(totalElements, _getDefaultValue(), growable: false);

    // Get number of chunks in each dimension
    final numChunks = calculator.getNumChunks();
    hdf5DebugLog('Number of chunks per dimension: $numChunks');

    // Iterate through all chunks
    await _iterateChunks(numChunks, 0, <int>[], reader, result);

    return result;
  }

  /// Recursively iterates through all chunk indices
  Future<void> _iterateChunks(
    List<int> numChunks,
    int dimension,
    List<int> currentIndices,
    ByteReader reader,
    List<T> result,
  ) async {
    if (dimension == numChunks.length) {
      // We have a complete set of chunk indices, read this chunk
      await _readAndPlaceChunk(currentIndices, reader, result);
      return;
    }

    // Iterate through this dimension
    for (int i = 0; i < numChunks[dimension]; i++) {
      final newIndices = [...currentIndices, i];
      await _iterateChunks(
          numChunks, dimension + 1, newIndices, reader, result);
    }
  }

  /// Reads a single chunk and places it in the result array
  Future<void> _readAndPlaceChunk(
    List<int> chunkIndices,
    ByteReader reader,
    List<T> result,
  ) async {
    hdf5DebugLog('Reading chunk at indices: $chunkIndices');

    // Find chunk info in B-tree
    final chunkInfo = await btree.findChunkInfo(
      chunkIndices,
      calculator.chunkDimensions,
      datatype.size,
    );

    if (chunkInfo == null) {
      // Chunk not found - this might be a sparse dataset
      // Fill with default values (already done in initialization)
      hdf5DebugLog('Chunk not found (sparse dataset), using default values');
      return;
    }

    // Read chunk data
    final chunkData = await _readChunk(reader, chunkInfo, chunkIndices);

    // Place chunk data in result array
    _placeChunkInResult(chunkIndices, chunkData, result);
  }

  /// Reads a single chunk from the file
  Future<List<T>> _readChunk(
    ByteReader reader,
    ChunkInfo chunkInfo,
    List<int> chunkIndices,
  ) async {
    // Adjust chunk address by HDF5 offset
    final adjustedAddress = chunkInfo.address + hdf5Offset;
    reader.seek(adjustedAddress);

    // Get actual chunk size (may be smaller at boundaries)
    final actualSize = calculator.getActualChunkSize(chunkIndices);
    final elementCount = actualSize.reduce((a, b) => a * b);

    hdf5DebugLog(
      'Reading chunk at address 0x${adjustedAddress.toRadixString(16)} (raw=0x${chunkInfo.address.toRadixString(16)} + offset=0x${hdf5Offset.toRadixString(16)}), '
      'size=$actualSize, elements=$elementCount, compressedSize=${chunkInfo.size}',
    );

    // If there's a filter pipeline, we need to read the raw compressed data first
    if (filterPipeline != null && filterPipeline!.isNotEmpty) {
      return await _readCompressedChunk(reader, chunkInfo, elementCount);
    }

    // Read uncompressed elements directly
    final chunkData = <T>[];
    for (int i = 0; i < elementCount; i++) {
      chunkData.add(await _readElement(reader));
    }

    return chunkData;
  }

  /// Reads and decompresses a compressed chunk
  Future<List<T>> _readCompressedChunk(
    ByteReader reader,
    ChunkInfo chunkInfo,
    int elementCount,
  ) async {
    // Read all the compressed data
    // The size in the B-tree is the compressed size
    final compressedData = await reader.readBytes(chunkInfo.size);

    hdf5DebugLog(
      'Read ${chunkInfo.size} bytes of compressed data, '
      'applying filter pipeline: $filterPipeline',
    );

    // Apply filter pipeline to decompress
    final decompressedData = await filterPipeline!.decode(
      compressedData,
      filePath: filePath,
      objectPath: objectPath,
    );

    hdf5DebugLog('Decompressed to ${decompressedData.length} bytes');

    // Create a ByteReader from decompressed data
    final decompressedReader = ByteReader.fromBytes(decompressedData);

    // Read elements from decompressed data
    final chunkData = <T>[];
    for (int i = 0; i < elementCount; i++) {
      chunkData.add(await _readElement(decompressedReader));
    }

    return chunkData;
  }

  /// Reads a single element from the reader based on datatype
  Future<T> _readElement(ByteReader reader) async {
    // Handle string datatypes (class 3)
    if (datatype.isString && datatype.stringInfo != null) {
      final stringInfo = datatype.stringInfo!;

      if (stringInfo.isVariableLength) {
        // Read vlen string reference
        final vlenBytes = await reader.readBytes(16);
        final vlenRef = VlenReference.fromBytes(vlenBytes);

        try {
          final heap = await GlobalHeap.read(
            reader,
            vlenRef.heapAddress + hdf5Offset,
            filePath: filePath,
          );
          final data = heap.readData(vlenRef.objectIndex);
          return stringInfo.decodeString(data) as T;
        } catch (e) {
          hdf5DebugLog('Failed to read vlen string in chunk: $e');
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

    // Handle time datatypes (class 2)
    if (datatype.isTime) {
      int timestamp;

      if (datatype.size == 4) {
        timestamp = await reader.readInt32();
      } else if (datatype.size == 8) {
        timestamp = await reader.readInt64();
      } else {
        throw UnsupportedDatatypeError(
          filePath: filePath,
          objectPath: objectPath,
          datatypeInfo: 'Time datatype with size=${datatype.size} bytes',
        );
      }

      // Convert to DateTime
      DateTime dateTime;
      if (timestamp > 1e10) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }

      return dateTime as T;
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
          final heap = await GlobalHeap.read(
            reader,
            vlenRef.heapAddress + hdf5Offset,
            filePath: filePath,
          );
          final data = heap.readData(vlenRef.objectIndex);
          return stringInfo.decodeString(data);
        } catch (e) {
          hdf5DebugLog('Failed to read vlen string in compound field: $e');
          return '[vlen string error]';
        }
      }
      final bytes = await reader.readBytes(fieldType.size);
      return stringInfo.decodeString(bytes);
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

  /// Places chunk data into the result array at the correct position
  void _placeChunkInResult(
    List<int> chunkIndices,
    List<T> chunkData,
    List<T> result,
  ) {
    final datasetDims = calculator.datasetDimensions;
    final chunkOffset = calculator.getChunkOffset(chunkIndices);
    final actualSize = calculator.getActualChunkSize(chunkIndices);

    hdf5DebugLog(
      'Placing chunk at offset=$chunkOffset, actualSize=$actualSize',
    );

    // Iterate through chunk elements and place them in result
    _placeChunkRecursive(
      chunkData,
      0,
      <int>[],
      chunkOffset,
      actualSize,
      datasetDims,
      result,
    );
  }

  /// Recursively places chunk elements in the result array
  void _placeChunkRecursive(
    List<T> chunkData,
    int dimension,
    List<int> chunkCoords,
    List<int> datasetOffset,
    List<int> actualSize,
    List<int> datasetDims,
    List<T> result,
  ) {
    if (dimension == actualSize.length) {
      // Calculate linear index in chunk
      int chunkLinearIndex = 0;
      int multiplier = 1;
      for (int i = actualSize.length - 1; i >= 0; i--) {
        chunkLinearIndex += chunkCoords[i] * multiplier;
        multiplier *= actualSize[i];
      }

      // Calculate linear index in dataset
      int datasetLinearIndex = 0;
      multiplier = 1;
      for (int i = datasetDims.length - 1; i >= 0; i--) {
        final datasetCoord = datasetOffset[i] + chunkCoords[i];
        datasetLinearIndex += datasetCoord * multiplier;
        multiplier *= datasetDims[i];
      }

      // Place element
      result[datasetLinearIndex] = chunkData[chunkLinearIndex];
      return;
    }

    // Iterate through this dimension
    for (int i = 0; i < actualSize[dimension]; i++) {
      final newCoords = [...chunkCoords, i];
      _placeChunkRecursive(
        chunkData,
        dimension + 1,
        newCoords,
        datasetOffset,
        actualSize,
        datasetDims,
        result,
      );
    }
  }

  /// Gets a default value for the datatype
  T _getDefaultValue() {
    // Return appropriate default based on datatype
    if (datatype.isString) {
      return '' as T;
    } else if (datatype.isCompound) {
      return <String, dynamic>{} as T;
    } else if (datatype.classId == 0 || datatype.classId == 1) {
      // Integer types
      return 0 as T;
    } else if (datatype.classId == 2) {
      // Float types
      return 0.0 as T;
    } else {
      // Default to 0
      return 0 as T;
    }
  }
}
