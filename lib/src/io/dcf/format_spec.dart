/// DartCube File (.dcf) Format Specification
///
/// A native binary format optimized for DartFrame with:
/// - Efficient chunked storage
/// - Built-in compression
/// - Fast random access
/// - Hierarchical groups
/// - Rich metadata
library;

/// DCF File Format Version
const int DCF_VERSION = 1;

/// Magic number for DCF files: "DCF\0"
const List<int> DCF_MAGIC = [0x44, 0x43, 0x46, 0x00];

/// Header size in bytes
const int DCF_HEADER_SIZE = 512;

/// DCF File Layout:
/// ```
/// [Header - 512 bytes]
///   - Magic: "DCF\0" (4 bytes)
///   - Version: uint16 (2 bytes)
///   - Flags: uint32 (4 bytes)
///   - Root offset: uint64 (8 bytes)
///   - Metadata offset: uint64 (8 bytes)
///   - Index offset: uint64 (8 bytes)
///   - Data offset: uint64 (8 bytes)
///   - File size: uint64 (8 bytes)
///   - Checksum: uint32 (4 bytes)
///   - Reserved: (462 bytes)
///
/// [Metadata Section]
///   - JSON metadata
///   - Schema definitions
///   - Compression info
///   - Custom attributes
///
/// [Group Tree]
///   - Hierarchical structure
///   - Group metadata
///   - Dataset references
///
/// [Dataset Index]
///   - Dataset metadata
///   - Chunk offset table
///   - Chunk size table
///   - Compression info per chunk
///
/// [Data Chunks]
///   - Compressed/uncompressed chunks
///   - Independent compression per chunk
///   - Aligned for fast access
/// ```

/// DCF File Header
class DCFHeader {
  /// Magic number
  final List<int> magic;

  /// Format version
  final int version;

  /// File flags
  final int flags;

  /// Offset to root group
  final int rootOffset;

  /// Offset to metadata section
  final int metadataOffset;

  /// Offset to dataset index
  final int indexOffset;

  /// Offset to data section
  final int dataOffset;

  /// Total file size
  final int fileSize;

  /// Header checksum (CRC32)
  final int checksum;

  DCFHeader({
    required this.magic,
    required this.version,
    required this.flags,
    required this.rootOffset,
    required this.metadataOffset,
    required this.indexOffset,
    required this.dataOffset,
    required this.fileSize,
    required this.checksum,
  });

  /// Create default header
  factory DCFHeader.create() {
    return DCFHeader(
      magic: DCF_MAGIC,
      version: DCF_VERSION,
      flags: 0,
      rootOffset: DCF_HEADER_SIZE,
      metadataOffset: 0,
      indexOffset: 0,
      dataOffset: 0,
      fileSize: DCF_HEADER_SIZE,
      checksum: 0,
    );
  }

  /// Serialize header to bytes
  List<int> toBytes() {
    final bytes = <int>[];

    // Magic (4 bytes)
    bytes.addAll(magic);

    // Version (2 bytes)
    bytes.addAll(_uint16ToBytes(version));

    // Flags (4 bytes)
    bytes.addAll(_uint32ToBytes(flags));

    // Offsets (8 bytes each)
    bytes.addAll(_uint64ToBytes(rootOffset));
    bytes.addAll(_uint64ToBytes(metadataOffset));
    bytes.addAll(_uint64ToBytes(indexOffset));
    bytes.addAll(_uint64ToBytes(dataOffset));
    bytes.addAll(_uint64ToBytes(fileSize));

    // Checksum (4 bytes)
    bytes.addAll(_uint32ToBytes(checksum));

    // Padding to 512 bytes
    while (bytes.length < DCF_HEADER_SIZE) {
      bytes.add(0);
    }

    return bytes;
  }

  /// Deserialize header from bytes
  factory DCFHeader.fromBytes(List<int> bytes) {
    if (bytes.length < DCF_HEADER_SIZE) {
      throw FormatException('Invalid DCF header: too short');
    }

    int offset = 0;

    // Magic
    final magic = bytes.sublist(offset, offset + 4);
    offset += 4;

    if (!_listEquals(magic, DCF_MAGIC)) {
      throw FormatException('Invalid DCF magic number');
    }

    // Version
    final version = _bytesToUint16(bytes.sublist(offset, offset + 2));
    offset += 2;

    // Flags
    final flags = _bytesToUint32(bytes.sublist(offset, offset + 4));
    offset += 4;

    // Offsets
    final rootOffset = _bytesToUint64(bytes.sublist(offset, offset + 8));
    offset += 8;

    final metadataOffset = _bytesToUint64(bytes.sublist(offset, offset + 8));
    offset += 8;

    final indexOffset = _bytesToUint64(bytes.sublist(offset, offset + 8));
    offset += 8;

    final dataOffset = _bytesToUint64(bytes.sublist(offset, offset + 8));
    offset += 8;

    final fileSize = _bytesToUint64(bytes.sublist(offset, offset + 8));
    offset += 8;

    // Checksum
    final checksum = _bytesToUint32(bytes.sublist(offset, offset + 4));

    return DCFHeader(
      magic: magic,
      version: version,
      flags: flags,
      rootOffset: rootOffset,
      metadataOffset: metadataOffset,
      indexOffset: indexOffset,
      dataOffset: dataOffset,
      fileSize: fileSize,
      checksum: checksum,
    );
  }

  /// Validate header
  bool validate() {
    return _listEquals(magic, DCF_MAGIC) && version == DCF_VERSION;
  }
}

/// Dataset metadata
class DCFDatasetMetadata {
  /// Dataset name
  final String name;

  /// Dataset path
  final String path;

  /// Data shape
  final List<int> shape;

  /// Data type
  final String dtype;

  /// Chunk shape
  final List<int>? chunkShape;

  /// Compression codec
  final String? compression;

  /// Compression level
  final int? compressionLevel;

  /// Custom attributes
  final Map<String, dynamic> attributes;

  /// Offset to first chunk
  final int dataOffset;

  /// Number of chunks
  final int numChunks;

  DCFDatasetMetadata({
    required this.name,
    required this.path,
    required this.shape,
    required this.dtype,
    this.chunkShape,
    this.compression,
    this.compressionLevel,
    this.attributes = const {},
    required this.dataOffset,
    required this.numChunks,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'shape': shape,
      'dtype': dtype,
      if (chunkShape != null) 'chunk_shape': chunkShape,
      if (compression != null) 'compression': compression,
      if (compressionLevel != null) 'compression_level': compressionLevel,
      'attributes': attributes,
      'data_offset': dataOffset,
      'num_chunks': numChunks,
    };
  }

  /// Create from JSON
  factory DCFDatasetMetadata.fromJson(Map<String, dynamic> json) {
    return DCFDatasetMetadata(
      name: json['name'] as String,
      path: json['path'] as String,
      shape: (json['shape'] as List).cast<int>(),
      dtype: json['dtype'] as String,
      chunkShape: json['chunk_shape'] != null
          ? (json['chunk_shape'] as List).cast<int>()
          : null,
      compression: json['compression'] as String?,
      compressionLevel: json['compression_level'] as int?,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      dataOffset: json['data_offset'] as int,
      numChunks: json['num_chunks'] as int,
    );
  }
}

/// Chunk metadata
class DCFChunkMetadata {
  /// Chunk index
  final List<int> index;

  /// Offset in file
  final int offset;

  /// Compressed size
  final int compressedSize;

  /// Uncompressed size
  final int uncompressedSize;

  /// Checksum
  final int checksum;

  DCFChunkMetadata({
    required this.index,
    required this.offset,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.checksum,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'offset': offset,
      'compressed_size': compressedSize,
      'uncompressed_size': uncompressedSize,
      'checksum': checksum,
    };
  }

  /// Create from JSON
  factory DCFChunkMetadata.fromJson(Map<String, dynamic> json) {
    return DCFChunkMetadata(
      index: (json['index'] as List).cast<int>(),
      offset: json['offset'] as int,
      compressedSize: json['compressed_size'] as int,
      uncompressedSize: json['uncompressed_size'] as int,
      checksum: json['checksum'] as int,
    );
  }
}

/// Compression codecs
enum CompressionCodec {
  none,
  gzip,
  zlib,
  lz4,
}

/// Helper functions for byte conversion

List<int> _uint16ToBytes(int value) {
  return [value & 0xFF, (value >> 8) & 0xFF];
}

int _bytesToUint16(List<int> bytes) {
  return bytes[0] | (bytes[1] << 8);
}

List<int> _uint32ToBytes(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}

int _bytesToUint32(List<int> bytes) {
  return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
}

List<int> _uint64ToBytes(int value) {
  final bytes = <int>[];
  for (int i = 0; i < 8; i++) {
    bytes.add((value >> (i * 8)) & 0xFF);
  }
  return bytes;
}

int _bytesToUint64(List<int> bytes) {
  int result = 0;
  for (int i = 0; i < 8; i++) {
    result |= (bytes[i] << (i * 8));
  }
  return result;
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Calculate CRC32 checksum
int calculateCRC32(List<int> data) {
  // Simplified CRC32 implementation
  // For production, use a proper CRC32 library
  int crc = 0xFFFFFFFF;
  for (var byte in data) {
    crc ^= byte;
    for (int i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc = crc >> 1;
      }
    }
  }
  return ~crc & 0xFFFFFFFF;
}
