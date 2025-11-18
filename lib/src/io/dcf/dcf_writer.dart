/// DartCube File (.dcf) Writer
///
/// High-performance native format for DartFrame with:
/// - Chunked storage for large arrays
/// - Built-in compression
/// - Fast random access
/// - Hierarchical organization
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../ndarray/ndarray.dart';
import '../../datacube/datacube.dart';
import '../../file_helper/file_io.dart';
import 'format_spec.dart';

/// DartCube File writer
class DCFWriter {
  final String _path;
  final FileIO _fileIO = FileIO();

  DCFHeader? _header;
  final Map<String, DCFDatasetMetadata> _datasets = {};
  final Map<String, Map<String, dynamic>> _groups = {};
  final List<int> _buffer = [];

  bool _isOpen = false;
  int _currentOffset = DCF_HEADER_SIZE;

  DCFWriter(this._path);

  /// Open file for writing
  Future<void> open() async {
    if (_isOpen) {
      throw StateError('File already open');
    }

    _header = DCFHeader.create();
    _isOpen = true;
    _currentOffset = DCF_HEADER_SIZE;
  }

  /// Write NDArray dataset
  Future<void> writeDataset(
    String path,
    NDArray data, {
    List<int>? chunkShape,
    CompressionCodec codec = CompressionCodec.none,
    int compressionLevel = 6,
    Map<String, dynamic>? attributes,
  }) async {
    if (!_isOpen) {
      throw StateError('File not open');
    }

    // Validate path
    if (!path.startsWith('/')) {
      throw ArgumentError('Dataset path must start with /');
    }

    // Get dataset name
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final name = parts.last;

    // Determine chunk shape
    final effectiveChunkShape =
        chunkShape ?? _defaultChunkShape(data.shape.toList());

    // Calculate number of chunks
    final numChunks =
        _calculateNumChunks(data.shape.toList(), effectiveChunkShape);

    // Create dataset metadata
    final metadata = DCFDatasetMetadata(
      name: name,
      path: path,
      shape: data.shape.toList(),
      dtype: 'float64',
      chunkShape: effectiveChunkShape,
      compression: codec.name,
      compressionLevel: compressionLevel,
      attributes: attributes ?? data.attrs.toJson(),
      dataOffset: _currentOffset,
      numChunks: numChunks,
    );

    _datasets[path] = metadata;

    // Write chunks
    await _writeChunks(data, effectiveChunkShape, codec, compressionLevel);
  }

  /// Write DataCube dataset
  Future<void> writeDataCube(
    String path,
    DataCube cube, {
    List<int>? chunkShape,
    CompressionCodec codec = CompressionCodec.none,
    int compressionLevel = 6,
    Map<String, dynamic>? attributes,
  }) async {
    // Merge cube attributes with provided attributes
    final mergedAttrs = <String, dynamic>{};
    mergedAttrs.addAll(cube.attrs.toJson());
    if (attributes != null) {
      mergedAttrs.addAll(attributes);
    }

    await writeDataset(
      path,
      cube.data,
      chunkShape: chunkShape,
      codec: codec,
      compressionLevel: compressionLevel,
      attributes: mergedAttrs,
    );
  }

  /// Create a group
  void createGroup(String path, {Map<String, dynamic>? attributes}) {
    if (!_isOpen) {
      throw StateError('File not open');
    }

    if (!path.startsWith('/')) {
      throw ArgumentError('Group path must start with /');
    }

    _groups[path] = attributes ?? {};
  }

  /// Close file and write all metadata
  Future<void> close() async {
    if (!_isOpen) {
      return;
    }

    // Write metadata section
    final metadataOffset = _currentOffset;
    final metadataJson = {
      'version': DCF_VERSION,
      'created': DateTime.now().toIso8601String(),
      'groups': _groups,
      'datasets': _datasets.map((k, v) => MapEntry(k, v.toJson())),
    };

    final metadataBytes = utf8.encode(jsonEncode(metadataJson));
    _buffer.addAll(_uint32ToBytes(metadataBytes.length));
    _buffer.addAll(metadataBytes);
    _currentOffset += 4 + metadataBytes.length;

    // Update header
    _header = DCFHeader(
      magic: DCF_MAGIC,
      version: DCF_VERSION,
      flags: 0,
      rootOffset: DCF_HEADER_SIZE,
      metadataOffset: metadataOffset,
      indexOffset: 0,
      dataOffset: DCF_HEADER_SIZE,
      fileSize: _currentOffset,
      checksum: calculateCRC32(_buffer),
    );

    // Write header + buffer to file
    final fileBytes = <int>[];
    fileBytes.addAll(_header!.toBytes());
    fileBytes.addAll(_buffer);

    await _fileIO.writeBytesToFile(_path, fileBytes);

    _isOpen = false;
    _buffer.clear();
    _datasets.clear();
    _groups.clear();
  }

  /// Write data chunks
  Future<void> _writeChunks(
    NDArray data,
    List<int> chunkShape,
    CompressionCodec codec,
    int compressionLevel,
  ) async {
    final shape = data.shape.toList();
    final flatData = data.toFlatList();

    // Calculate chunk grid
    final chunkGrid = <int>[];
    for (int i = 0; i < shape.length; i++) {
      chunkGrid.add((shape[i] + chunkShape[i] - 1) ~/ chunkShape[i]);
    }

    // Iterate through chunks
    final chunkIndices = _generateChunkIndices(chunkGrid);

    for (var chunkIndex in chunkIndices) {
      // Extract chunk data
      final chunkData = _extractChunk(flatData, shape, chunkShape, chunkIndex);

      // Compress if needed
      final compressedData = _compressData(chunkData, codec, compressionLevel);

      // Write chunk
      _buffer.addAll(_uint32ToBytes(compressedData.length));
      _buffer.addAll(compressedData);
      _currentOffset += 4 + compressedData.length;
    }
  }

  /// Extract chunk from flat data
  List<double> _extractChunk(
    List<dynamic> flatData,
    List<int> shape,
    List<int> chunkShape,
    List<int> chunkIndex,
  ) {
    final chunk = <double>[];

    // Calculate chunk start and end
    final start = <int>[];
    final end = <int>[];

    for (int i = 0; i < shape.length; i++) {
      start.add(chunkIndex[i] * chunkShape[i]);
      end.add((start[i] + chunkShape[i]).clamp(0, shape[i]));
    }

    // Extract data
    if (shape.length == 1) {
      for (int i = start[0]; i < end[0]; i++) {
        chunk.add((flatData[i] as num).toDouble());
      }
    } else if (shape.length == 2) {
      for (int i = start[0]; i < end[0]; i++) {
        for (int j = start[1]; j < end[1]; j++) {
          final idx = i * shape[1] + j;
          chunk.add((flatData[idx] as num).toDouble());
        }
      }
    } else if (shape.length == 3) {
      for (int i = start[0]; i < end[0]; i++) {
        for (int j = start[1]; j < end[1]; j++) {
          for (int k = start[2]; k < end[2]; k++) {
            final idx = (i * shape[1] + j) * shape[2] + k;
            chunk.add((flatData[idx] as num).toDouble());
          }
        }
      }
    } else {
      // General N-D case
      _extractChunkND(flatData, shape, start, end, chunk, 0, 0);
    }

    return chunk;
  }

  /// Extract chunk for N-dimensional arrays
  void _extractChunkND(
    List<dynamic> flatData,
    List<int> shape,
    List<int> start,
    List<int> end,
    List<double> chunk,
    int dim,
    int offset,
  ) {
    if (dim == shape.length - 1) {
      for (int i = start[dim]; i < end[dim]; i++) {
        chunk.add((flatData[offset + i] as num).toDouble());
      }
    } else {
      final stride = shape.sublist(dim + 1).reduce((a, b) => a * b);
      for (int i = start[dim]; i < end[dim]; i++) {
        _extractChunkND(
            flatData, shape, start, end, chunk, dim + 1, offset + i * stride);
      }
    }
  }

  /// Compress data
  List<int> _compressData(
    List<double> data,
    CompressionCodec codec,
    int level,
  ) {
    // Convert doubles to bytes
    final bytes = <int>[];
    for (var value in data) {
      final buffer = ByteData(8);
      buffer.setFloat64(0, value, Endian.little);
      for (int i = 0; i < 8; i++) {
        bytes.add(buffer.getUint8(i));
      }
    }

    // Apply compression
    switch (codec) {
      case CompressionCodec.none:
        return bytes;
      case CompressionCodec.gzip:
        return gzip.encode(bytes);
      case CompressionCodec.zlib:
        return zlib.encode(bytes);
      case CompressionCodec.lz4:
        // LZ4 not available in dart:io, return uncompressed
        return bytes;
    }
  }

  /// Generate chunk indices
  List<List<int>> _generateChunkIndices(List<int> chunkGrid) {
    final indices = <List<int>>[];

    void generate(List<int> current, int dim) {
      if (dim == chunkGrid.length) {
        indices.add(List.from(current));
        return;
      }

      for (int i = 0; i < chunkGrid[dim]; i++) {
        current.add(i);
        generate(current, dim + 1);
        current.removeLast();
      }
    }

    generate([], 0);
    return indices;
  }

  /// Calculate number of chunks
  int _calculateNumChunks(List<int> shape, List<int> chunkShape) {
    int total = 1;
    for (int i = 0; i < shape.length; i++) {
      total *= (shape[i] + chunkShape[i] - 1) ~/ chunkShape[i];
    }
    return total;
  }

  /// Default chunk shape
  List<int> _defaultChunkShape(List<int> shape) {
    // Aim for ~1MB chunks
    const targetSize = 1024 * 1024; // 1MB
    const elementSize = 8; // float64

    final totalElements = shape.reduce((a, b) => a * b);
    final chunkElements = targetSize ~/ elementSize;

    if (totalElements <= chunkElements) {
      return shape;
    }

    // Scale down proportionally
    final scale = (chunkElements / totalElements).clamp(0.1, 1.0);
    return shape.map((s) => (s * scale).ceil().clamp(1, s)).toList();
  }

  List<int> _uint32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }
}

/// Extension for NDArray
extension NDArrayDCFWriter on NDArray {
  /// Write to DCF file
  Future<void> toDCF(
    String path, {
    String dataset = '/data',
    List<int>? chunkShape,
    CompressionCodec codec = CompressionCodec.none,
    int compressionLevel = 6,
  }) async {
    final writer = DCFWriter(path);
    await writer.open();
    await writer.writeDataset(
      dataset,
      this,
      chunkShape: chunkShape,
      codec: codec,
      compressionLevel: compressionLevel,
    );
    await writer.close();
  }
}

/// Extension for DataCube
extension DataCubeDCFWriter on DataCube {
  /// Write to DCF file
  Future<void> toDCF(
    String path, {
    String dataset = '/data',
    List<int>? chunkShape,
    CompressionCodec codec = CompressionCodec.none,
    int compressionLevel = 6,
  }) async {
    final writer = DCFWriter(path);
    await writer.open();
    await writer.writeDataCube(
      dataset,
      this,
      chunkShape: chunkShape,
      codec: codec,
      compressionLevel: compressionLevel,
    );
    await writer.close();
  }
}
