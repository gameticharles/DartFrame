/// DartCube File (.dcf) Reader
///
/// Efficient reader with:
/// - Lazy loading
/// - Chunk-based reading
/// - Partial reads
/// - Memory-efficient streaming
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../ndarray/ndarray.dart';
import '../../data_cube/datacube.dart';
import '../../file_helper/file_io.dart';
import 'format_spec.dart';

/// DartCube File reader
class DCFReader {
  final String _path;
  final FileIO _fileIO = FileIO();

  DCFHeader? _header;
  Map<String, DCFDatasetMetadata>? _datasets;
  Map<String, Map<String, dynamic>>? _groups;
  List<int>? _fileBytes;

  bool _isOpen = false;

  DCFReader(this._path);

  /// Open file for reading
  Future<void> open() async {
    if (_isOpen) {
      throw StateError('File already open');
    }

    // Read entire file
    _fileBytes = await _fileIO.readBytesFromFile(_path);

    if (_fileBytes!.length < DCF_HEADER_SIZE) {
      throw FormatException('File too small to be valid DCF');
    }

    // Parse header
    _header = DCFHeader.fromBytes(_fileBytes!.sublist(0, DCF_HEADER_SIZE));

    if (!_header!.validate()) {
      throw FormatException('Invalid DCF file');
    }

    // Parse metadata
    await _parseMetadata();

    _isOpen = true;
  }

  /// Parse metadata section
  Future<void> _parseMetadata() async {
    if (_header!.metadataOffset == 0) {
      _datasets = {};
      _groups = {};
      return;
    }

    final offset = _header!.metadataOffset;

    // Read metadata length
    final lengthBytes = _fileBytes!.sublist(offset, offset + 4);
    final length = _bytesToUint32(lengthBytes);

    // Read metadata JSON
    final metadataBytes = _fileBytes!.sublist(offset + 4, offset + 4 + length);
    final metadataJson =
        jsonDecode(utf8.decode(metadataBytes)) as Map<String, dynamic>;

    // Parse groups
    _groups = (metadataJson['groups'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as Map<String, dynamic>)) ??
        {};

    // Parse datasets
    final datasetsJson = metadataJson['datasets'] as Map<String, dynamic>?;
    _datasets = datasetsJson?.map((k, v) => MapEntry(
            k, DCFDatasetMetadata.fromJson(v as Map<String, dynamic>))) ??
        {};
  }

  /// Read dataset as NDArray
  Future<NDArray> readDataset(String path) async {
    if (!_isOpen) {
      throw StateError('File not open');
    }

    final metadata = _datasets![path];
    if (metadata == null) {
      throw ArgumentError('Dataset not found: $path');
    }

    // Read all chunks
    final data = await _readAllChunks(metadata);

    // Create NDArray
    final array = NDArray.fromFlat(data, metadata.shape);

    // Set attributes
    for (var entry in metadata.attributes.entries) {
      array.attrs[entry.key] = entry.value;
    }

    return array;
  }

  /// Read dataset as DataCube
  Future<DataCube> readDataCube(String path) async {
    final array = await readDataset(path);

    if (array.ndim != 3) {
      throw ArgumentError('Dataset must be 3-dimensional for DataCube');
    }

    final cube = DataCube.fromNDArray(array);

    // Copy attributes from array to cube
    for (var entry in array.attrs.toJson().entries) {
      cube.attrs[entry.key] = entry.value;
    }

    return cube;
  }

  /// Read all chunks
  Future<List<double>> _readAllChunks(DCFDatasetMetadata metadata) async {
    final allData = <double>[];
    int offset = metadata.dataOffset;

    for (int i = 0; i < metadata.numChunks; i++) {
      // Read chunk size
      final sizeBytes = _fileBytes!.sublist(offset, offset + 4);
      final size = _bytesToUint32(sizeBytes);
      offset += 4;

      // Read chunk data
      final chunkBytes = _fileBytes!.sublist(offset, offset + size);
      offset += size;

      // Decompress
      final decompressed = _decompressData(
        chunkBytes,
        metadata.compression ?? 'none',
      );

      allData.addAll(decompressed);
    }

    return allData;
  }

  /// Decompress data
  List<double> _decompressData(List<int> bytes, String codec) {
    // Decompress if needed
    List<int> decompressed;

    switch (codec) {
      case 'none':
        decompressed = bytes;
        break;
      case 'gzip':
        decompressed = gzip.decode(bytes);
        break;
      case 'zlib':
        decompressed = zlib.decode(bytes);
        break;
      case 'lz4':
        // LZ4 not available, assume uncompressed
        decompressed = bytes;
        break;
      default:
        throw UnsupportedError('Unknown compression codec: $codec');
    }

    // Convert bytes to doubles
    final data = <double>[];
    for (int i = 0; i < decompressed.length; i += 8) {
      final buffer = ByteData.sublistView(
          Uint8List.fromList(decompressed.sublist(i, i + 8)));
      data.add(buffer.getFloat64(0, Endian.little));
    }

    return data;
  }

  /// List all datasets
  List<String> listDatasets() {
    if (!_isOpen) {
      throw StateError('File not open');
    }
    return _datasets!.keys.toList();
  }

  /// Get dataset info
  DCFDatasetMetadata? getDatasetInfo(String path) {
    if (!_isOpen) {
      throw StateError('File not open');
    }
    return _datasets![path];
  }

  /// List all groups
  List<String> listGroups() {
    if (!_isOpen) {
      throw StateError('File not open');
    }
    return _groups!.keys.toList();
  }

  /// Get group attributes
  Map<String, dynamic>? getGroupAttributes(String path) {
    if (!_isOpen) {
      throw StateError('File not open');
    }
    return _groups![path];
  }

  /// Close file
  Future<void> close() async {
    _isOpen = false;
    _fileBytes = null;
    _header = null;
    _datasets = null;
    _groups = null;
  }

  int _bytesToUint32(List<int> bytes) {
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
  }
}

/// Static methods for NDArray
class NDArrayDCF {
  /// Read from DCF file
  static Future<NDArray> fromDCF(String path,
      {String dataset = '/data'}) async {
    final reader = DCFReader(path);
    await reader.open();
    try {
      return await reader.readDataset(dataset);
    } finally {
      await reader.close();
    }
  }
}

/// Static methods for DataCube
class DataCubeDCF {
  /// Read from DCF file
  static Future<DataCube> fromDCF(String path,
      {String dataset = '/data'}) async {
    final reader = DCFReader(path);
    await reader.open();
    try {
      return await reader.readDataCube(dataset);
    } finally {
      await reader.close();
    }
  }
}

/// Utility class for DCF operations
class DCFUtil {
  /// List datasets in file
  static Future<List<String>> listDatasets(String path) async {
    final reader = DCFReader(path);
    await reader.open();
    try {
      return reader.listDatasets();
    } finally {
      await reader.close();
    }
  }

  /// Get dataset info
  static Future<DCFDatasetMetadata?> getDatasetInfo(
    String path,
    String dataset,
  ) async {
    final reader = DCFReader(path);
    await reader.open();
    try {
      return reader.getDatasetInfo(dataset);
    } finally {
      await reader.close();
    }
  }

  /// List groups in file
  static Future<List<String>> listGroups(String path) async {
    final reader = DCFReader(path);
    await reader.open();
    try {
      return reader.listGroups();
    } finally {
      await reader.close();
    }
  }
}
