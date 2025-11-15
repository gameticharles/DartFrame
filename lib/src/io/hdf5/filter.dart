import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'byte_reader.dart';
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

  /// Apply the filter to decompress/decode data
  Future<Uint8List> decode(Uint8List data,
      {String? filePath, String? objectPath});

  /// Check if this filter is mandatory
  bool get isMandatory => (flags & 0x01) == 0;

  /// Check if this filter is optional
  bool get isOptional => (flags & 0x01) != 0;

  @override
  String toString() => '$name (id=$id, flags=$flags)';
}

/// Deflate (gzip) compression filter
class DeflateFilter extends Filter {
  DeflateFilter({
    required super.flags,
    required super.clientData,
  }) : super(
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
      // We need to use ZLibDecoder with raw=true for raw deflate
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
}

/// LZF compression filter
class LzfFilter extends Filter {
  LzfFilter({
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

  /// LZF decompression implementation
  /// Based on the LZF algorithm specification
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
}

/// Shuffle filter for numeric data
class ShuffleFilter extends Filter {
  ShuffleFilter({
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
class Fletcher32Filter extends Filter {
  Fletcher32Filter({
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
    return data;
  }
}

/// Generic unsupported filter
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
}

/// Filter pipeline containing multiple filters
class FilterPipeline {
  final List<Filter> filters;

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

  /// Create a filter instance based on filter ID
  static Filter _createFilter(
      int filterId, int flags, List<int> clientData, String? name) {
    switch (filterId) {
      case FilterId.deflate:
        return DeflateFilter(flags: flags, clientData: clientData);
      case FilterId.shuffle:
        return ShuffleFilter(flags: flags, clientData: clientData);
      case FilterId.fletcher32:
        return Fletcher32Filter(flags: flags, clientData: clientData);
      case FilterId.lzf:
        return LzfFilter(flags: flags, clientData: clientData);
      default:
        return UnsupportedFilter(
            id: filterId, flags: flags, clientData: clientData);
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
