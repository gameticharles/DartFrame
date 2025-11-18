import 'dart:typed_data';
import 'dart:io' show GZipCodec;
import 'package:archive/archive.dart';
import 'byte_reader.dart';
import 'byte_writer.dart';
import 'hdf5_error.dart';

/// HDF5 filter identifiers
class FilterId {
  static const int deflate = 1; // gzip/deflate compression
  static const int shuffle = 2; // Shuffle filter
  static const int fletcher32 = 3; // Fletcher32 checksum
  static const int szip = 4; // SZIP compression
  static const int nbit = 5; // N-bit packing
  static const int scaleOffset = 6; // Scale-offset filter
  static const int lzf = 32000; // LZF compression (custom filter)
}

/// Base class for HDF5 filters
///
/// This class provides the interface for both encoding (writing) and decoding (reading)
/// HDF5 filter data. Each concrete implementation handles a specific compression or
/// transformation algorithm (gzip, lzf, shuffle, etc.).
///
/// Filters are applied to chunk data to reduce file size or improve data organization.
/// The filter pipeline message (type 0x000B) describes which filters were applied.
///
/// Example usage:
/// ```dart
/// // For writing (encoding)
/// final filter = GzipFilter(compressionLevel: 6);
/// final compressed = filter.encode(rawData);
///
/// // For reading (decoding)
/// final decompressed = await filter.decode(compressedData);
/// ```
abstract class Filter {
  final int id;
  final int flags;
  final String name;
  final List<int> clientData;

  Filter({
    required this.id,
    required this.flags,
    required this.name,
    required this.clientData,
  });

  /// Apply the filter to decompress/decode data (for reading)
  ///
  /// Parameters:
  /// - [data]: The compressed/encoded data to decode
  /// - [filePath]: Optional file path for error messages
  /// - [objectPath]: Optional object path for error messages
  ///
  /// Returns the decoded data.
  Future<Uint8List> decode(Uint8List data,
      {String? filePath, String? objectPath});

  /// Apply the filter to compress/encode data (for writing)
  ///
  /// Parameters:
  /// - [data]: The raw data to encode
  ///
  /// Returns the encoded data. If encoding fails or produces larger output,
  /// implementations may return the original data unchanged.
  List<int> encode(List<int> data);

  /// Check if this filter is mandatory
  bool get isMandatory => (flags & 0x01) == 0;

  /// Check if this filter is optional
  bool get isOptional => (flags & 0x01) != 0;

  @override
  String toString() => '$name (id=$id, flags=$flags)';
}

/// Gzip/Deflate compression filter
///
/// This filter uses the DEFLATE compression algorithm (RFC 1951) to compress
/// and decompress chunk data. It's the most commonly used compression filter
/// in HDF5 files.
///
/// Filter ID: 1 (H5Z_FILTER_DEFLATE)
///
/// The compression level can be set from 1 (fastest) to 9 (best compression).
/// Level 6 is a good balance between speed and compression ratio.
///
/// Example usage:
/// ```dart
/// // For writing with compression level 6
/// final filter = GzipFilter(compressionLevel: 6);
/// final compressed = filter.encode(rawData);
///
/// // For reading (compression level not needed)
/// final filter = GzipFilter.forReading(flags: 0, clientData: []);
/// final decompressed = await filter.decode(compressedData);
/// ```
class GzipFilter extends Filter {
  /// Compression level (1-9) - only used for encoding
  ///
  /// - 1: Fastest compression, larger output
  /// - 6: Balanced (default)
  /// - 9: Best compression, slower
  final int compressionLevel;

  /// Create a gzip filter for writing
  ///
  /// Parameters:
  /// - [compressionLevel]: Compression level from 1 to 9 (default: 6)
  ///
  /// Throws [ArgumentError] if compression level is not in range 1-9.
  GzipFilter({this.compressionLevel = 6})
      : super(
          id: FilterId.deflate,
          flags: 0,
          name: 'deflate',
          clientData: [],
        ) {
    if (compressionLevel < 1 || compressionLevel > 9) {
      throw ArgumentError(
        'Compression level must be between 1 and 9, got $compressionLevel',
      );
    }
  }

  /// Create a gzip filter for reading
  ///
  /// Used when parsing filter pipeline from HDF5 file.
  GzipFilter.forReading({
    required super.flags,
    required super.clientData,
  })  : compressionLevel = 6, // Default, not used for reading
        super(
          id: FilterId.deflate,
          name: 'deflate',
        );

  @override
  Future<Uint8List> decode(Uint8List data,
      {String? filePath, String? objectPath}) async {
    try {
      hdf5DebugLog(
        'Deflate filter: decompressing ${data.length} bytes',
      );
      // Use the archive package to decompress gzip/deflate data
      // HDF5 uses raw deflate format (no gzip/zlib header)
      final decoder = ZLibDecoder();
      final inflated = decoder.decodeBytes(data);
      hdf5DebugLog(
        'Deflate filter: decompressed to ${inflated.length} bytes',
      );
      return Uint8List.fromList(inflated);
    } catch (e) {
      if (e is DecompressionError) rethrow;
      throw DecompressionError(
        filePath: filePath,
        objectPath: objectPath,
        compressionType: 'deflate/gzip',
        originalError: e,
      );
    }
  }

  @override
  List<int> encode(List<int> data) {
    try {
      // Use dart:io GZipCodec to compress
      final codec = GZipCodec(level: compressionLevel);
      final compressed = codec.encode(data);
      return compressed;
    } catch (e) {
      // If compression fails, return original data
      return data;
    }
  }
}

/// Legacy alias for backward compatibility
typedef DeflateFilter = GzipFilter;

/// LZF compression filter
///
/// This filter uses the LZF compression algorithm, which is a very fast
/// compression algorithm with moderate compression ratios. It's faster than
/// gzip but typically produces larger output.
///
/// Filter ID: 32000 (H5Z_FILTER_LZF - custom filter)
///
/// LZF is particularly useful when write speed is more important than
/// achieving maximum compression.
///
/// Example usage:
/// ```dart
/// // For writing
/// final filter = LzfFilter();
/// final compressed = filter.encode(rawData);
///
/// // For reading
/// final filter = LzfFilter.forReading(flags: 0, clientData: []);
/// final decompressed = await filter.decode(compressedData);
/// ```
class LzfFilter extends Filter {
  /// Create an LZF filter for writing
  LzfFilter()
      : super(
          id: FilterId.lzf,
          flags: 0,
          name: 'lzf',
          clientData: [],
        );

  /// Create an LZF filter for reading
  ///
  /// Used when parsing filter pipeline from HDF5 file.
  LzfFilter.forReading({
    required super.flags,
    required super.clientData,
  }) : super(
          id: FilterId.lzf,
          name: 'lzf',
        );

  @override
  Future<Uint8List> decode(Uint8List data,
      {String? filePath, String? objectPath}) async {
    try {
      return _lzfDecompress(data);
    } catch (e) {
      if (e is DecompressionError) rethrow;
      throw DecompressionError(
        filePath: filePath,
        objectPath: objectPath,
        compressionType: 'lzf',
        originalError: e,
      );
    }
  }

  @override
  List<int> encode(List<int> data) {
    try {
      return _lzfCompress(data);
    } catch (e) {
      // If compression fails, return original data
      return data;
    }
  }

  /// LZF decompression implementation
  ///
  /// Based on the LZF algorithm specification.
  /// Reads compressed data and expands it back to original form.
  Uint8List _lzfDecompress(Uint8List input) {
    final output = <int>[];
    int inPos = 0;

    while (inPos < input.length) {
      final ctrl = input[inPos++];

      if (ctrl < 32) {
        // Literal run: copy (ctrl + 1) bytes
        final literalLength = ctrl + 1;

        if (inPos + literalLength > input.length) {
          throw Exception('LZF: Unexpected end of input during literal run');
        }

        for (int i = 0; i < literalLength; i++) {
          output.add(input[inPos++]);
        }
      } else {
        // Back reference: copy from earlier in output
        int length = ctrl >> 5;
        int reference = output.length - ((ctrl & 0x1f) << 8) - 1;

        if (inPos >= input.length) {
          throw Exception('LZF: Unexpected end of input during back reference');
        }

        reference -= input[inPos++];

        if (length == 7) {
          // Extended length
          if (inPos >= input.length) {
            throw Exception(
                'LZF: Unexpected end of input during extended length');
          }
          length += input[inPos++];
        }

        length += 2; // Minimum match length is 3

        if (reference < 0 || reference >= output.length) {
          throw Exception(
              'LZF: Invalid back reference: $reference (output length: ${output.length})');
        }

        // Copy bytes from back reference
        for (int i = 0; i < length; i++) {
          output.add(output[reference + i]);
        }
      }
    }

    return Uint8List.fromList(output);
  }

  /// LZF compression implementation
  ///
  /// Based on the LZF algorithm specification.
  /// This is a pure Dart implementation of the LZF compression algorithm.
  ///
  /// The algorithm works by:
  /// 1. Finding repeated sequences in the data
  /// 2. Replacing them with back-references to earlier occurrences
  /// 3. Encoding literals (non-repeated data) directly
  ///
  /// Format:
  /// - Literal run: ctrl byte (0-31) + (ctrl+1) literal bytes
  /// - Back reference: ctrl byte (32-255) + offset byte(s) + length encoding
  List<int> _lzfCompress(List<int> input) {
    if (input.isEmpty) {
      return input;
    }

    final output = <int>[];
    final hashTable =
        List<int>.filled(8192, -1); // Hash table for finding matches

    int inPos = 0;
    int literalStart = 0;

    while (inPos < input.length) {
      // Try to find a match
      if (inPos + 3 <= input.length) {
        // Calculate hash of current 3-byte sequence
        final hash = _hash(input, inPos);
        final matchPos = hashTable[hash];

        // Update hash table
        hashTable[hash] = inPos;

        // Check if we have a valid match
        if (matchPos >= 0 &&
            inPos - matchPos < 8192 && // Within reference distance
            inPos + 2 < input.length &&
            matchPos + 2 < input.length &&
            input[matchPos] == input[inPos] &&
            input[matchPos + 1] == input[inPos + 1] &&
            input[matchPos + 2] == input[inPos + 2]) {
          // Found a match! First, output any pending literals
          if (inPos > literalStart) {
            _outputLiterals(output, input, literalStart, inPos);
          }

          // Calculate match length
          int matchLength = 3;
          while (inPos + matchLength < input.length &&
              matchPos + matchLength < input.length &&
              input[matchPos + matchLength] == input[inPos + matchLength] &&
              matchLength < 264) {
            // Max match length
            matchLength++;
          }

          // Output back reference
          _outputBackReference(output, inPos - matchPos, matchLength);

          // Update hash table for matched positions
          for (int i = 1;
              i < matchLength && inPos + i + 2 < input.length;
              i++) {
            hashTable[_hash(input, inPos + i)] = inPos + i;
          }

          inPos += matchLength;
          literalStart = inPos;
        } else {
          inPos++;
        }
      } else {
        inPos++;
      }
    }

    // Output any remaining literals
    if (literalStart < input.length) {
      _outputLiterals(output, input, literalStart, input.length);
    }

    return output;
  }

  /// Calculate hash for 3-byte sequence (shared by compress/decompress)
  int _hash(List<int> data, int pos) {
    if (pos + 2 >= data.length) {
      return 0;
    }
    return ((data[pos] << 16) | (data[pos + 1] << 8) | data[pos + 2]) % 8192;
  }

  /// Output literal bytes during compression
  void _outputLiterals(List<int> output, List<int> input, int start, int end) {
    int remaining = end - start;
    int pos = start;

    while (remaining > 0) {
      final chunkSize = remaining > 32 ? 32 : remaining;

      // Control byte: 0-31 for literal run
      output.add(chunkSize - 1);

      // Literal bytes
      for (int i = 0; i < chunkSize; i++) {
        output.add(input[pos++]);
      }

      remaining -= chunkSize;
    }
  }

  /// Output back reference during compression
  void _outputBackReference(List<int> output, int offset, int length) {
    // Encode offset and length
    // Control byte format: [length-2 in bits 5-7][offset high 5 bits in bits 0-4]

    offset--; // Offset is 1-based in encoding

    if (length < 9) {
      // Short match: length encoded in control byte
      final ctrl = ((length - 2) << 5) | ((offset >> 8) & 0x1F);
      output.add(ctrl);
      output.add(offset & 0xFF);
    } else {
      // Long match: length encoded separately
      final ctrl = (7 << 5) | ((offset >> 8) & 0x1F);
      output.add(ctrl);
      output.add(offset & 0xFF);
      output.add(length - 9); // Extended length
    }
  }
}

/// Shuffle filter for numeric data
///
/// The shuffle filter rearranges bytes to improve compression by grouping
/// similar bytes together. This is particularly effective for numeric data.
///
/// Filter ID: 2 (H5Z_FILTER_SHUFFLE)
///
/// Note: Currently only supports decoding (reading). Encoding (writing) is
/// not yet implemented.
class ShuffleFilter extends Filter {
  /// Create a shuffle filter for reading
  ShuffleFilter.forReading({
    required super.flags,
    required super.clientData,
  }) : super(
          id: FilterId.shuffle,
          name: 'shuffle',
        );

  @override
  Future<Uint8List> decode(Uint8List data,
      {String? filePath, String? objectPath}) async {
    try {
      // Get element size from client data (first value)
      if (clientData.isEmpty) {
        throw Exception('Shuffle filter requires element size in client data');
      }

      final elementSize = clientData[0];
      return _shuffleUnshuffle(data, elementSize);
    } catch (e) {
      if (e is DecompressionError) rethrow;
      throw DecompressionError(
        filePath: filePath,
        objectPath: objectPath,
        compressionType: 'shuffle',
        originalError: e,
      );
    }
  }

  @override
  List<int> encode(List<int> data) {
    // TO DO: Implement shuffle encoding for writing
    throw UnimplementedError('Shuffle filter encoding not yet implemented');
  }

  /// Unshuffle data that was shuffled by HDF5
  /// The shuffle filter rearranges bytes to improve compression
  Uint8List _shuffleUnshuffle(Uint8List input, int elementSize) {
    if (elementSize <= 1) {
      // No shuffling needed for single-byte elements
      return input;
    }

    final numElements = input.length ~/ elementSize;
    if (input.length % elementSize != 0) {
      throw Exception('Shuffle: data length not divisible by element size');
    }

    final output = Uint8List(input.length);

    // Unshuffle: reverse the byte-plane organization
    // Shuffled data has all first bytes, then all second bytes, etc.
    // We need to interleave them back
    for (int i = 0; i < numElements; i++) {
      for (int j = 0; j < elementSize; j++) {
        output[i * elementSize + j] = input[j * numElements + i];
      }
    }

    return output;
  }
}

/// Fletcher32 checksum filter
///
/// The Fletcher32 filter computes a checksum for data integrity verification.
///
/// Filter ID: 3 (H5Z_FILTER_FLETCHER32)
///
/// Note: Currently only supports decoding (reading). Encoding (writing) is
/// not yet implemented. Checksum verification is also not yet implemented.
class Fletcher32Filter extends Filter {
  /// Create a Fletcher32 filter for reading
  Fletcher32Filter.forReading({
    required super.flags,
    required super.clientData,
  }) : super(
          id: FilterId.fletcher32,
          name: 'fletcher32',
        );

  @override
  Future<Uint8List> decode(Uint8List data,
      {String? filePath, String? objectPath}) async {
    // Fletcher32 is a checksum filter - just verify and return data
    // For now, we'll skip verification and just return the data
    // TO DO: Implement checksum verification
    return data;
  }

  @override
  List<int> encode(List<int> data) {
    // TO DO: Implement Fletcher32 checksum encoding
    throw UnimplementedError('Fletcher32 filter encoding not yet implemented');
  }
}

/// Generic unsupported filter
///
/// Represents a filter that is not yet implemented or recognized.
class UnsupportedFilter extends Filter {
  UnsupportedFilter({
    required super.id,
    required super.flags,
    required super.clientData,
  }) : super(
          name: 'unsupported',
        );

  @override
  Future<Uint8List> decode(Uint8List data,
      {String? filePath, String? objectPath}) async {
    throw UnsupportedFeatureError(
      filePath: filePath,
      objectPath: objectPath,
      feature: 'Filter ID $id',
      details: 'This filter is not supported',
    );
  }

  @override
  List<int> encode(List<int> data) {
    throw UnsupportedError('Filter ID $id is not supported for encoding');
  }
}

/// Filter pipeline containing multiple filters
///
/// A filter pipeline applies a sequence of filters to chunk data for both
/// reading (decoding) and writing (encoding). Filters are applied in order
/// when encoding, and in reverse order when decoding.
///
/// The pipeline message format (type 0x000B) describes which filters were
/// applied to the dataset chunks.
///
/// Example usage:
/// ```dart
/// // For writing (encoding)
/// final pipeline = FilterPipeline(filters: [
///   GzipFilter(compressionLevel: 6),
/// ]);
/// final encoded = pipeline.apply(rawData);
/// final message = pipeline.writeMessage();
///
/// // For reading (decoding)
/// final pipeline = await FilterPipeline.read(reader, messageSize);
/// final decoded = await pipeline.decode(compressedData);
/// ```
class FilterPipeline {
  final List<Filter> filters;

  /// Create a filter pipeline
  ///
  /// Parameters:
  /// - [filters]: List of filters to apply
  FilterPipeline({required this.filters});

  /// Parse filter pipeline message from object header
  static Future<FilterPipeline> read(ByteReader reader, int messageSize) async {
    final version = await reader.readUint8();
    final numFilters = await reader.readUint8();

    if (version != 1 && version != 2) {
      throw UnsupportedVersionError(
        component: 'filter pipeline',
        version: version,
      );
    }

    // Skip reserved bytes
    if (version == 1) {
      await reader.readBytes(6); // 6 reserved bytes in version 1
    } else {
      await reader.readBytes(2); // 2 reserved bytes in version 2
    }

    final filters = <Filter>[];

    for (int i = 0; i < numFilters; i++) {
      final filterId = await reader.readUint16();

      int nameLength = 0;
      int flags = 0;
      int numClientDataValues = 0;

      if (version == 1) {
        nameLength = await reader.readUint16();
        flags = await reader.readUint16();
        numClientDataValues = await reader.readUint16();
      } else {
        // Version 2
        final nameLengthOrFlags = await reader.readUint16();
        if (filterId < 256) {
          // Predefined filter
          flags = nameLengthOrFlags;
          nameLength = 0;
        } else {
          // Custom filter
          nameLength = nameLengthOrFlags;
          flags = await reader.readUint16();
        }
        numClientDataValues = await reader.readUint16();
      }

      // Read filter name if present
      String? filterName;
      if (nameLength > 0) {
        final nameBytes = await reader.readBytes(nameLength);
        filterName = String.fromCharCodes(nameBytes.where((b) => b != 0));

        // Align to 8-byte boundary after name
        final padding = (8 - (nameLength % 8)) % 8;
        if (padding > 0) {
          await reader.readBytes(padding);
        }
      }

      // Read client data values
      final clientData = <int>[];
      for (int j = 0; j < numClientDataValues; j++) {
        clientData.add(await reader.readUint32());
      }

      // Align to 8-byte boundary after client data if needed
      if (numClientDataValues % 2 != 0) {
        await reader.readBytes(4);
      }

      // Create appropriate filter instance
      final filter = _createFilter(filterId, flags, clientData, filterName);
      filters.add(filter);
    }

    return FilterPipeline(filters: filters);
  }

  /// Create a filter instance based on filter ID (for reading)
  static Filter _createFilter(
      int filterId, int flags, List<int> clientData, String? name) {
    switch (filterId) {
      case FilterId.deflate:
        return GzipFilter.forReading(flags: flags, clientData: clientData);
      case FilterId.shuffle:
        return ShuffleFilter.forReading(flags: flags, clientData: clientData);
      case FilterId.fletcher32:
        return Fletcher32Filter.forReading(
            flags: flags, clientData: clientData);
      case FilterId.lzf:
        return LzfFilter.forReading(flags: flags, clientData: clientData);
      default:
        return UnsupportedFilter(
            id: filterId, flags: flags, clientData: clientData);
    }
  }

  /// Apply all filters in order to encode data (for writing)
  ///
  /// Filters are applied in the order they appear in the list.
  /// For reading, use decode() which applies filters in reverse order.
  ///
  /// Parameters:
  /// - [data]: The raw data to encode
  ///
  /// Returns the encoded data after applying all filters.
  ///
  /// Example:
  /// ```dart
  /// final pipeline = FilterPipeline(filters: [
  ///   GzipFilter(compressionLevel: 6),
  /// ]);
  /// final encoded = pipeline.apply(rawData);
  /// ```
  List<int> apply(List<int> data) {
    var result = data;

    // Apply filters in order (first filter first)
    for (final filter in filters) {
      result = filter.encode(result);
    }

    return result;
  }

  /// Write the filter pipeline message (type 0x000B) for writing
  ///
  /// This message is included in the object header to describe which filters
  /// were applied to the dataset chunks.
  ///
  /// Message format (version 2):
  /// - Version (1 byte): 2
  /// - Number of filters (1 byte)
  /// - Reserved (2 bytes)
  /// - For each filter:
  ///   - Filter ID (2 bytes)
  ///   - Name length or flags (2 bytes)
  ///   - Number of client data values (2 bytes)
  ///   - Filter name (variable, if custom filter)
  ///   - Client data values (4 bytes each)
  ///
  /// Returns the message bytes ready to be included in an object header.
  ///
  /// Example:
  /// ```dart
  /// final pipeline = FilterPipeline(filters: [
  ///   GzipFilter(compressionLevel: 6),
  /// ]);
  /// final message = pipeline.writeMessage();
  /// // Include message in object header with type 0x000B
  /// ```
  List<int> writeMessage({Endian endian = Endian.little}) {
    final writer = ByteWriter(endian: endian);

    // Version 2 (more compact than version 1)
    writer.writeUint8(2);

    // Number of filters
    writer.writeUint8(filters.length);

    // Reserved (2 bytes)
    writer.writeUint16(0);

    // Write each filter
    for (final filter in filters) {
      _writeFilter(writer, filter);
    }

    return writer.bytes;
  }

  /// Write a single filter description
  void _writeFilter(ByteWriter writer, Filter filter) {
    // Filter ID (2 bytes)
    writer.writeUint16(filter.id);

    // For version 2:
    // - Predefined filters (ID < 256): next 2 bytes are flags
    // - Custom filters (ID >= 256): next 2 bytes are name length
    if (filter.id < 256) {
      // Predefined filter: write flags
      writer.writeUint16(filter.flags);
    } else {
      // Custom filter: write name length
      final nameBytes = filter.name.codeUnits;
      writer.writeUint16(nameBytes.length);

      // Write flags
      writer.writeUint16(filter.flags);

      // Write name
      writer.writeBytes(nameBytes);

      // Align to 8-byte boundary
      writer.alignTo(8);
    }

    // Number of client data values (2 bytes)
    writer.writeUint16(filter.clientData.length);

    // Write client data values (4 bytes each)
    for (final value in filter.clientData) {
      writer.writeUint32(value);
    }

    // Align to 8-byte boundary if odd number of values
    if (filter.clientData.length % 2 != 0) {
      writer.writeUint32(0); // Padding
    }
  }

  /// Apply all filters in reverse order to decode data
  Future<Uint8List> decode(Uint8List data,
      {String? filePath, String? objectPath}) async {
    var result = data;

    // Apply filters in reverse order (last filter first)
    for (int i = filters.length - 1; i >= 0; i--) {
      final filter = filters[i];

      // Skip optional filters that fail
      try {
        result = await filter.decode(result,
            filePath: filePath, objectPath: objectPath);
      } catch (e) {
        if (filter.isOptional) {
          // Skip optional filter if it fails
          continue;
        } else {
          // Rethrow for mandatory filters
          rethrow;
        }
      }
    }

    return result;
  }

  /// Check if pipeline has any filters
  bool get isEmpty => filters.isEmpty;

  /// Check if pipeline has filters
  bool get isNotEmpty => filters.isNotEmpty;

  /// Get number of filters
  int get length => filters.length;

  @override
  String toString() => 'FilterPipeline(${filters.join(", ")})';
}
