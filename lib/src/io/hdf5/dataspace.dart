import 'byte_reader.dart';

/// HDF5 dataspace representing array dimensions
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

  @override
  String toString() => 'Hdf5Dataspace(dims=$dimensions)';
}
