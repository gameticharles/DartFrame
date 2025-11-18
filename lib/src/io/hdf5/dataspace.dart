import 'dart:typed_data';
import 'byte_reader.dart';
import 'byte_writer.dart';

/// HDF5 dataspace representing array dimensions
///
/// This class handles both reading and writing of HDF5 dataspace messages.
/// A dataspace defines the dimensionality and size of a dataset.
class Hdf5Dataspace {
  final int version;
  final int dimensionality;
  final List<int> dimensions;
  final List<int> maxDimensions;

  Hdf5Dataspace({
    required this.version,
    required this.dimensionality,
    required this.dimensions,
    required this.maxDimensions,
  });

  /// Create a simple dataspace from dimensions
  ///
  /// This is a convenience constructor for creating dataspaces for writing.
  ///
  /// Example:
  /// ```dart
  /// // 1D array with 1000 elements
  /// final space1d = Hdf5Dataspace.simple([1000]);
  ///
  /// // 2D array with 100 rows and 200 columns
  /// final space2d = Hdf5Dataspace.simple([100, 200]);
  /// ```
  factory Hdf5Dataspace.simple(List<int> dimensions,
      {List<int>? maxDimensions}) {
    if (dimensions.isEmpty) {
      throw ArgumentError('Dimensions list cannot be empty');
    }

    if (dimensions.any((d) => d <= 0)) {
      throw ArgumentError('All dimensions must be positive');
    }

    if (maxDimensions != null && maxDimensions.length != dimensions.length) {
      throw ArgumentError('maxDimensions length must match dimensions length');
    }

    return Hdf5Dataspace(
      version: 1,
      dimensionality: dimensions.length,
      dimensions: dimensions,
      maxDimensions: maxDimensions ?? dimensions,
    );
  }

  static Future<Hdf5Dataspace> read(ByteReader reader) async {
    final version = await reader.readUint8();

    if (version == 0 || version == 1) {
      // Version 0 and 1 have the same format
      return await _readVersion1(reader);
    } else if (version == 2) {
      return await _readVersion2(reader);
    } else {
      throw Exception('Unsupported dataspace version: $version');
    }
  }

  static Future<Hdf5Dataspace> _readVersion1(ByteReader reader) async {
    final dimensionality = await reader.readUint8();
    final flags = await reader.readUint8();
    await reader.readUint8(); // reserved

    // Skip 4 bytes of padding/reserved
    await reader.readBytes(4);

    final dimensions = <int>[];
    final maxDimensions = <int>[];

    for (int i = 0; i < dimensionality; i++) {
      dimensions.add((await reader.readUint64()).toInt());
    }

    if ((flags & 0x1) != 0) {
      for (int i = 0; i < dimensionality; i++) {
        maxDimensions.add((await reader.readUint64()).toInt());
      }
    } else {
      maxDimensions.addAll(dimensions);
    }

    return Hdf5Dataspace(
      version: 1,
      dimensionality: dimensionality,
      dimensions: dimensions,
      maxDimensions: maxDimensions,
    );
  }

  static Future<Hdf5Dataspace> _readVersion2(ByteReader reader) async {
    final dimensionality = await reader.readUint8();
    final flags = await reader.readUint8();
    final type = await reader.readUint8();

    final dimensions = <int>[];
    final maxDimensions = <int>[];

    // Type 0 = scalar, 1 = simple, 2 = null
    if (type == 1) {
      // Simple dataspace
      for (int i = 0; i < dimensionality; i++) {
        dimensions.add((await reader.readUint64()).toInt());
      }

      if ((flags & 0x1) != 0) {
        for (int i = 0; i < dimensionality; i++) {
          maxDimensions.add((await reader.readUint64()).toInt());
        }
      } else {
        maxDimensions.addAll(dimensions);
      }
    } else if (type == 0) {
      // Scalar dataspace
      dimensions.add(1);
      maxDimensions.add(1);
    }

    return Hdf5Dataspace(
      version: 2,
      dimensionality: dimensionality,
      dimensions: dimensions,
      maxDimensions: maxDimensions,
    );
  }

  int get totalElements {
    int total = 1;
    for (var dim in dimensions) {
      total *= dim;
    }
    return total;
  }

  /// Write this dataspace as an HDF5 message
  ///
  /// Returns the message bytes following HDF5 dataspace message format version 1:
  /// - Version (1 byte): 1
  /// - Dimensionality (1 byte): number of dimensions
  /// - Flags (1 byte): 0 (no max dimensions) or 1 (max dimensions present)
  /// - Reserved (1 byte): 0
  /// - Reserved (4 bytes): 0
  /// - Dimension sizes (8 bytes each): size of each dimension
  /// - Max dimension sizes (8 bytes each, if present): maximum size of each dimension
  ///
  /// Parameters:
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Examples:
  /// ```dart
  /// // 1D array with 1000 elements
  /// final space1d = Hdf5Dataspace.simple([1000]);
  /// final bytes1d = space1d.write();
  ///
  /// // 2D array with 100 rows and 200 columns
  /// final space2d = Hdf5Dataspace.simple([100, 200]);
  /// final bytes2d = space2d.write();
  ///
  /// // 3D array with 10x20x30 elements
  /// final space3d = Hdf5Dataspace.simple([10, 20, 30]);
  /// final bytes3d = space3d.write();
  ///
  /// // With maximum dimensions (for extensible datasets)
  /// final spaceExt = Hdf5Dataspace.simple([100], maxDimensions: [1000]);
  /// final bytesExt = spaceExt.write();
  /// ```
  List<int> write({Endian endian = Endian.little}) {
    final writer = ByteWriter(endian: endian);

    // Version 1
    writer.writeUint8(1);

    // Dimensionality (number of dimensions)
    writer.writeUint8(dimensionality);

    // Flags: bit 0 = 1 if max dimensions differ from dimensions
    final hasMaxDimensions = !_listsEqual(dimensions, maxDimensions);
    final flags = hasMaxDimensions ? 0x01 : 0x00;
    writer.writeUint8(flags);

    // Reserved byte
    writer.writeUint8(0);

    // Reserved 4 bytes (for version 1)
    writer.writeUint32(0);

    // Write dimension sizes (8 bytes each)
    for (final dim in dimensions) {
      writer.writeUint64(dim);
    }

    // Write max dimension sizes if they differ from dimensions
    if (hasMaxDimensions) {
      for (final maxDim in maxDimensions) {
        writer.writeUint64(maxDim);
      }
    }

    return writer.bytes;
  }

  /// Check if two lists are equal
  bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'Hdf5Dataspace(dims=$dimensions)';
}
