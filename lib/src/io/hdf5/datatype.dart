import 'dart:typed_data';
import 'dart:convert';

import 'byte_reader.dart';
import 'byte_writer.dart';

/// HDF5 datatype class enumeration
enum Hdf5DatatypeClass {
  integer(0),
  float(1),
  time(2),
  string(3),
  bitfield(4),
  opaque(5),
  compound(6),
  reference(7),
  enumType(8),
  vlen(9),
  array(10);

  final int id;
  const Hdf5DatatypeClass(this.id);

  static Hdf5DatatypeClass fromId(int id) {
    try {
      return values.firstWhere((c) => c.id == id);
    } catch (e) {
      throw Exception('Unknown HDF5 datatype class: $id');
    }
  }

  @override
  String toString() => name;
}

/// Legacy constants for backward compatibility
const int datatypeClassFixedPoint = 0;
const int datatypeClassFloatingPoint = 1;
const int datatypeClassTime = 2;
const int datatypeClassString = 3;
const int datatypeClassBitfield = 4;
const int datatypeClassOpaque = 5;
const int datatypeClassCompound = 6;
const int datatypeClassReference = 7;
const int datatypeClassEnum = 8;
const int datatypeClassVariableLength = 9;
const int datatypeClassArray = 10;

/// String padding types
enum StringPaddingType {
  nullTerminate, // Null-terminated
  nullPad, // Null-padded
  spacePad, // Space-padded
}

/// Character set encoding
enum CharacterSet {
  ascii, // ASCII
  utf8, // UTF-8
}

/// HDF5 datatype representation
class Hdf5Datatype<T> {
  final Hdf5DatatypeClass dataclass;
  final int size; // in bytes (-1 for variable-length)
  final Endian endian;
  final StringInfo? stringInfo;
  final CompoundInfo? compoundInfo;
  final ArrayInfo? arrayInfo;
  final EnumInfo? enumInfo;
  final ReferenceInfo? referenceInfo;
  final String? tag; // Opaque type identifier
  final Hdf5Datatype? baseType; // For array/vlen types
  final int?
      filePosition; // Position in file where this datatype was read (for debugging)

  Hdf5Datatype({
    required this.dataclass,
    required this.size,
    this.endian = Endian.little,
    this.stringInfo,
    this.compoundInfo,
    this.arrayInfo,
    this.enumInfo,
    this.referenceInfo,
    this.tag,
    this.baseType,
    this.filePosition,
  });

  // Predefined atomic types
  static final int8 = Hdf5Datatype<int>(
      dataclass: Hdf5DatatypeClass.integer, size: 1, endian: Endian.little);
  static final uint8 = Hdf5Datatype<int>(
      dataclass: Hdf5DatatypeClass.integer, size: 1, endian: Endian.little);
  static final int16 = Hdf5Datatype<int>(
      dataclass: Hdf5DatatypeClass.integer, size: 2, endian: Endian.little);
  static final uint16 = Hdf5Datatype<int>(
      dataclass: Hdf5DatatypeClass.integer, size: 2, endian: Endian.little);
  static final int32 = Hdf5Datatype<int>(
      dataclass: Hdf5DatatypeClass.integer, size: 4, endian: Endian.little);
  static final uint32 = Hdf5Datatype<int>(
      dataclass: Hdf5DatatypeClass.integer, size: 4, endian: Endian.little);
  static final int64 = Hdf5Datatype<int>(
      dataclass: Hdf5DatatypeClass.integer, size: 8, endian: Endian.little);
  static final uint64 = Hdf5Datatype<int>(
      dataclass: Hdf5DatatypeClass.integer, size: 8, endian: Endian.little);
  static final float32 = Hdf5Datatype<double>(
      dataclass: Hdf5DatatypeClass.float, size: 4, endian: Endian.little);
  static final float64 = Hdf5Datatype<double>(
      dataclass: Hdf5DatatypeClass.float, size: 8, endian: Endian.little);

  Type get dartType => T;

  // Legacy compatibility
  int get classId => dataclass.id;
  bool get isString => dataclass == Hdf5DatatypeClass.string;
  bool get isCompound => dataclass == Hdf5DatatypeClass.compound;
  bool get isVariableLength => dataclass == Hdf5DatatypeClass.vlen;
  bool get isArray => dataclass == Hdf5DatatypeClass.array;
  bool get isEnum => dataclass == Hdf5DatatypeClass.enumType;
  bool get isReference => dataclass == Hdf5DatatypeClass.reference;

  // New type checking methods
  bool get isAtomic => dataclass.id <= 5;
  bool get isComposite => dataclass.id >= 6;
  bool get isOpaque => dataclass == Hdf5DatatypeClass.opaque;
  bool get isBitfield => dataclass == Hdf5DatatypeClass.bitfield;
  bool get isTime => dataclass == Hdf5DatatypeClass.time;

  /// Read datatype from HDF5 file at current position
  static Future<Hdf5Datatype> read(ByteReader reader) async {
    final startPos = reader.position;
    final classAndVersion = await reader.readUint8();
    final classId = classAndVersion & 0x0F;
    final version = (classAndVersion >> 4) & 0x0F;

    // Debug: print position and values for nested types
    // print(
    //     'Reading datatype at pos=$startPos: classAndVersion=0x${classAndVersion.toRadixString(16)}, class=$classId, version=$version');

    // Version 0 is a legacy format that's similar to version 1
    // We'll treat it as version 1 for simplicity
    if (version > 3) {
      throw Exception(
          'Unsupported datatype version: $version at position $startPos. '
          'Only versions 0-3 are supported.');
    }

    final classBitField1 = await reader.readUint8();
    final classBitField2 = await reader.readUint8();
    await reader.readUint8(); // classBitField3 - reserved for future use

    int size;

    // For version 0 with integer or floating-point types,
    // the structure is different - size is 1 byte after type-specific properties
    if (version == 0 && (classId == 0 || classId == 1)) {
      await reader.readUint16(); // bit offset
      await reader.readUint16(); // bit precision

      if (classId == 1) {
        // Additional floating-point properties
        await reader.readUint8(); // exponent location
        await reader.readUint8(); // exponent size
        await reader.readUint8(); // mantissa location
        await reader.readUint8(); // mantissa size
        await reader.readUint32(); // exponent bias
      }

      // For version 0, size is 1 byte
      await reader.readUint8(); // padding/reserved
      size = await reader.readUint8();
    } else if (version == 1 && (classId == 0 || classId == 1)) {
      // For version 1, size comes first, then properties
      size = await reader.readUint32();
      await reader.readUint16(); // bit offset
      await reader.readUint16(); // bit precision

      if (classId == 1) {
        // Additional floating-point properties
        await reader.readUint8(); // exponent location
        await reader.readUint8(); // exponent size
        await reader.readUint8(); // mantissa location
        await reader.readUint8(); // mantissa size
        await reader.readUint32(); // exponent bias
      }
    } else {
      // For other versions/types, size is 4 bytes at standard position
      size = await reader.readUint32();
    }

    final dataclass = Hdf5DatatypeClass.fromId(classId);
    final endian = (classBitField1 & 0x01) != 0 ? Endian.big : Endian.little;

    // Handle string datatypes
    if (classId == 3) {
      final paddingType = _parseStringPaddingType(classBitField1 & 0x0F);
      final characterSet = _parseCharacterSet((classBitField1 >> 4) & 0x0F);

      return Hdf5Datatype<String>(
        dataclass: dataclass,
        size: size,
        endian: endian,
        filePosition: startPos,
        stringInfo: StringInfo(
          paddingType: paddingType,
          characterSet: characterSet,
          isVariableLength: size == 0xFFFFFFFF,
        ),
      );
    }

    // Handle compound datatypes
    if (classId == 6) {
      return await _readCompoundType(
          reader, version, classBitField1, classBitField2, size, endian,
          startPos: startPos);
    }

    // Handle variable-length datatypes
    if (classId == 9) {
      final baseType = await read(reader);
      return Hdf5Datatype(
        dataclass: dataclass,
        size: size,
        endian: endian,
        filePosition: startPos,
        baseType: baseType,
      );
    }

    // Handle array datatypes
    if (classId == 10) {
      return await _readArrayType(reader, version, size, endian,
          startPos: startPos);
    }

    // Handle enum datatypes
    if (classId == 8) {
      return await _readEnumType(
          reader, version, classBitField1, classBitField2, size, endian,
          startPos: startPos);
    }

    // Handle reference datatypes
    if (classId == 7) {
      return await _readReferenceType(reader, classBitField1, size, endian,
          startPos: startPos);
    }

    // Handle opaque datatypes
    if (classId == 5) {
      final tagLength = classBitField1;
      String? tag;
      if (tagLength > 0) {
        final bytes = await reader.readBytes(tagLength);
        tag = String.fromCharCodes(bytes);
      }
      return Hdf5Datatype<Uint8List>(
        dataclass: dataclass,
        size: size,
        endian: endian,
        filePosition: startPos,
        tag: tag,
      );
    }

    // Default for atomic types
    return Hdf5Datatype(
      dataclass: dataclass,
      size: size,
      endian: endian,
      filePosition: startPos,
    );
  }

  static Future<Hdf5Datatype> _readCompoundType(
    ByteReader reader,
    int version,
    int classBitField1,
    int classBitField2,
    int size,
    Endian endian, {
    int? startPos,
  }) async {
    // Number of members encoded differently by version
    int numMembers;
    if (version < 3) {
      // Version 1 and 2: member count in classBitField1 and classBitField2
      numMembers = classBitField1 | (classBitField2 << 8);
    } else {
      // Version 3: separate uint16
      numMembers = await reader.readUint16();
    }

    final fields = <CompoundField>[];

    for (int i = 0; i < numMembers; i++) {
      // Read member name (null-terminated)
      final nameBytes = <int>[];
      int byte;
      do {
        byte = await reader.readUint8();
        if (byte != 0) nameBytes.add(byte);
      } while (byte != 0);

      final name = String.fromCharCodes(nameBytes);

      // Align to 8-byte boundary after name (version 1 and 2 only)
      if (version < 3) {
        final nameLength = nameBytes.length + 1; // +1 for null terminator
        final padding = (8 - (nameLength % 8)) % 8;
        if (padding > 0) {
          await reader.readBytes(padding);
        }
      }

      // Read member byte offset within compound
      final offset = await reader.readUint32();

      // Version 1: read dimensionality info (always present even if 0)
      if (version == 1) {
        await reader.readUint8(); // dimensionality
        await reader.readBytes(3); // reserved
        await reader.readBytes(4); // dimension permutation
        await reader.readBytes(4); // reserved
        await reader.readBytes(16); // dimension sizes (4 dimensions max)
      }

      // Read member datatype (recursive)
      final memberType = await read(reader);

      fields.add(CompoundField(
        name: name,
        offset: offset,
        datatype: memberType,
      ));
    }

    return Hdf5Datatype<Map<String, dynamic>>(
      dataclass: Hdf5DatatypeClass.compound,
      size: size, // Use actual size from message, not calculated
      endian: endian,
      filePosition: startPos,
      compoundInfo: CompoundInfo(fields: fields),
    );
  }

  static Future<Hdf5Datatype> _readArrayType(
    ByteReader reader,
    int version,
    int size,
    Endian endian, {
    int? startPos,
  }) async {
    // Array datatype structure (version 1 and later)
    // Version 1: dimensionality (1 byte), reserved (3 bytes), dimension sizes (4 bytes each), permutation, base type
    // Version 2: dimensionality (1 byte), reserved (3 bytes), dimension sizes (4 bytes each), base type
    // Version 3: dimensionality (1 byte), reserved (3 bytes), dimension sizes (4 bytes each), base type

    if (version == 1) {
      final dimensionality = await reader.readUint8();
      await reader.readBytes(3); // reserved

      // Read dimension sizes
      final dimensions = <int>[];
      for (int i = 0; i < dimensionality; i++) {
        dimensions.add(await reader.readUint32());
      }

      // Skip permutation indices (4 bytes per dimension)
      await reader.readBytes(dimensionality * 4);

      // Read base datatype
      final baseType = await read(reader);

      return Hdf5Datatype(
        dataclass: Hdf5DatatypeClass.array,
        size: size,
        endian: endian,
        filePosition: startPos,
        baseType: baseType,
        arrayInfo: ArrayInfo(dimensions: dimensions),
      );
    } else if (version == 2 || version == 3) {
      final dimensionality = await reader.readUint8();
      await reader.readBytes(3); // reserved

      // Read dimension sizes
      final dimensions = <int>[];
      for (int i = 0; i < dimensionality; i++) {
        dimensions.add(await reader.readUint32());
      }

      // Read base datatype
      final baseType = await read(reader);

      return Hdf5Datatype(
        dataclass: Hdf5DatatypeClass.array,
        size: size,
        endian: endian,
        filePosition: startPos,
        baseType: baseType,
        arrayInfo: ArrayInfo(dimensions: dimensions),
      );
    }

    throw Exception('Unsupported array datatype version: $version');
  }

  static Future<Hdf5Datatype> _readEnumType(
    ByteReader reader,
    int version,
    int classBitField1,
    int classBitField2,
    int size,
    Endian endian, {
    int? startPos,
  }) async {
    // Enum datatype structure:
    // - Number of members (2 bytes)
    // - Base datatype (integer type)
    // - Member names and values

    int numMembers;
    if (version < 3) {
      numMembers = classBitField1 | (classBitField2 << 8);
    } else {
      numMembers = await reader.readUint16();
    }

    // Read base datatype (must be integer)
    final baseType = await read(reader);

    // Read member names and values
    final members = <EnumMember>[];
    for (int i = 0; i < numMembers; i++) {
      // Read member name (null-terminated)
      final nameBytes = <int>[];
      int byte;
      do {
        byte = await reader.readUint8();
        if (byte != 0) nameBytes.add(byte);
      } while (byte != 0);

      final name = String.fromCharCodes(nameBytes);
      print(
          'Enum member $i: name="$name" (${nameBytes.length} bytes), version=$version, baseType.size=${baseType.size}');

      // Align to multiple of base type size
      if (version < 3) {
        final nameLength = nameBytes.length + 1; // +1 for null terminator
        final padding =
            (baseType.size - (nameLength % baseType.size)) % baseType.size;
        print('  Padding: $padding bytes');
        if (padding > 0) {
          await reader.readBytes(padding);
        }
      }

      // Read value based on base type size
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
          throw Exception('Unsupported enum base type size: ${baseType.size}');
      }
      print('  Value: $value');

      members.add(EnumMember(name: name, value: value));
    }

    return Hdf5Datatype(
      dataclass: Hdf5DatatypeClass.enumType,
      size: size,
      endian: endian,
      filePosition: startPos,
      baseType: baseType,
      enumInfo: EnumInfo(members: members),
    );
  }

  static Future<Hdf5Datatype> _readReferenceType(
    ByteReader reader,
    int classBitField1,
    int size,
    Endian endian, {
    int? startPos,
  }) async {
    // Reference datatype structure:
    // classBitField1 contains the reference type
    // 0 = object reference
    // 1 = dataset region reference

    final referenceType = classBitField1 & 0x0F;

    ReferenceType refType;
    if (referenceType == 0) {
      refType = ReferenceType.object;
    } else if (referenceType == 1) {
      refType = ReferenceType.region;
    } else {
      throw Exception('Unknown reference type: $referenceType');
    }

    return Hdf5Datatype(
      dataclass: Hdf5DatatypeClass.reference,
      size: size,
      endian: endian,
      filePosition: startPos,
      referenceInfo: ReferenceInfo(type: refType),
    );
  }

  static StringPaddingType _parseStringPaddingType(int value) {
    switch (value) {
      case 0:
        return StringPaddingType.nullTerminate;
      case 1:
        return StringPaddingType.nullPad;
      case 2:
        return StringPaddingType.spacePad;
      default:
        return StringPaddingType.nullTerminate;
    }
  }

  static CharacterSet _parseCharacterSet(int value) {
    switch (value) {
      case 0:
        return CharacterSet.ascii;
      case 1:
        return CharacterSet.utf8;
      default:
        return CharacterSet.ascii;
    }
  }

  static Hdf5Datatype fromClassIdAndSize(int classId, int size) {
    switch (classId) {
      case 0: // Integers
        switch (size) {
          case 1:
            return int8;
          case 2:
            return int16;
          case 4:
            return int32;
          case 8:
            return int64;
        }
        break;
      case 1: // Floating point
        switch (size) {
          case 4:
            return float32;
          case 8:
            return float64;
        }
        break;
    }
    throw Exception('Unsupported datatype: class=$classId, size=$size');
  }

  /// Check if this is a boolean type (stored as uint8)
  bool get isBoolean => classId == 0 && size == 1;

  /// Get friendly name for this datatype
  String get typeName {
    switch (dataclass) {
      case Hdf5DatatypeClass.integer:
        return size == 8
            ? 'int64'
            : size == 4
                ? 'int32'
                : 'int$size';
      case Hdf5DatatypeClass.float:
        return size == 8 ? 'float64' : 'float32';
      case Hdf5DatatypeClass.string:
        return size == -1 ? 'string(vlen)' : 'string($size)';
      case Hdf5DatatypeClass.opaque:
        return 'opaque${tag != null ? '($tag)' : ''}';
      case Hdf5DatatypeClass.compound:
        return 'compound(${compoundInfo?.fields.length ?? 0} fields)';
      case Hdf5DatatypeClass.array:
        final dims = arrayInfo?.dimensions.join('x') ?? '?';
        final baseTypeName = baseType?.typeName ?? 'unknown';
        return 'array[$dims]($baseTypeName)';
      case Hdf5DatatypeClass.enumType:
        final numMembers = enumInfo?.members.length ?? 0;
        return 'enum($numMembers values)';
      case Hdf5DatatypeClass.reference:
        final refType =
            referenceInfo?.type == ReferenceType.object ? 'object' : 'region';
        return 'reference($refType)';
      case Hdf5DatatypeClass.bitfield:
        return 'bitfield($size bytes)';
      case Hdf5DatatypeClass.time:
        return 'time($size bytes)';
      default:
        return dataclass.name;
    }
  }

  @override
  String toString() {
    if (isString) {
      return 'Hdf5Datatype(String, size=$size, ${stringInfo?.characterSet == CharacterSet.utf8 ? "UTF-8" : "ASCII"})';
    } else if (isCompound) {
      return 'Hdf5Datatype(Compound, size=$size, fields=${compoundInfo?.fields.length})';
    } else if (isArray) {
      return 'Hdf5Datatype(Array, dimensions=${arrayInfo?.dimensions}, baseType=${baseType?.typeName})';
    } else if (isEnum) {
      return 'Hdf5Datatype(Enum, size=$size, members=${enumInfo?.members.length})';
    } else if (isReference) {
      return 'Hdf5Datatype(Reference, type=${referenceInfo?.type})';
    }
    return 'Hdf5Datatype($dataclass, size=$size)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hdf5Datatype &&
          other.dataclass == dataclass &&
          other.size == size &&
          other.endian == endian &&
          other.tag == tag;

  @override
  int get hashCode => Object.hash(dataclass, size, endian, tag);

  /// Write this datatype as an HDF5 message
  ///
  /// Returns the message bytes following HDF5 datatype message format version 1.
  /// Currently supports float64 and int64 types.
  ///
  /// Parameters:
  /// - [endian]: Byte order (default: uses datatype's endian setting)
  ///
  /// Examples:
  /// ```dart
  /// // Write float64 datatype
  /// final float64Type = Hdf5Datatype.float64;
  /// final bytes1 = float64Type.write();
  ///
  /// // Write int64 datatype
  /// final int64Type = Hdf5Datatype.int64;
  /// final bytes2 = int64Type.write();
  ///
  /// // Write with explicit endianness
  /// final bytes3 = float64Type.write(endian: Endian.big);
  /// ```
  ///
  /// Throws [UnsupportedError] for unsupported datatypes.
  List<int> write({Endian? endian}) {
    final effectiveEndian = endian ?? this.endian;

    if (dataclass == Hdf5DatatypeClass.float && size == 8) {
      return _writeFloat64(endian: effectiveEndian);
    } else if (dataclass == Hdf5DatatypeClass.integer && size == 8) {
      return _writeInt64(endian: effectiveEndian);
    } else {
      throw UnsupportedError(
          'Unsupported datatype: $dataclass with size $size. '
          'Currently supported: float64, int64');
    }
  }

  //// Write a float64 (IEEE 754 double precision) datatype message
  ///
  /// Returns the message bytes following HDF5 datatype message format version 1:
  /// - Class and version (1 byte): class=1 (floating point), version=1
  /// - Class bit fields (3 bytes): endianness and padding info
  /// - Size (4 bytes): 8 bytes for float64
  /// - Bit offset (2 bytes): 0
  /// - Bit precision (2 bytes): 64
  /// - Exponent location (1 byte): 52
  /// - Exponent size (1 byte): 11
  /// - Mantissa location (1 byte): 0
  /// - Mantissa size (1 byte): 52
  /// - Exponent bias (4 bytes): 1023
  List<int> _writeFloat64({required Endian endian}) {
    final writer = ByteWriter(endian: endian);

    // Class and version: class=1 (floating point), version=1
    final classAndVersion = (1 << 4) | 1; // version 1, class 1
    writer.writeUint8(classAndVersion);

    // Class bit field 1: byte order and padding
    // Bit 0: 0=little-endian, 1=big-endian
    // Bits 1-3: padding type (0=zero padding)
    // Bits 4-7: mantissa normalization (2=implied 1)
    final classBitField1 = (endian == Endian.little ? 0 : 1) | (2 << 4);
    writer.writeUint8(classBitField1);

    // Class bit field 2: sign location (63 for float64)
    writer.writeUint8(63);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes (version 1: size comes first)
    writer.writeUint32(8);

    // Bit offset (always 0 for standard types)
    writer.writeUint16(0);

    // Bit precision (64 bits for float64)
    writer.writeUint16(64);

    // Exponent location (bit 52)
    writer.writeUint8(52);

    // Exponent size (11 bits)
    writer.writeUint8(11);

    // Mantissa location (bit 0)
    writer.writeUint8(0);

    // Mantissa size (52 bits)
    writer.writeUint8(52);

    // Exponent bias (1023 for IEEE 754 double)
    writer.writeUint32(1023);

    return writer.bytes;
  }

  /// Write an int64 (signed 64-bit integer) datatype message
  ///
  /// Returns the message bytes following HDF5 datatype message format version 1:
  /// - Class and version (1 byte): class=0 (integer), version=1
  /// - Class bit fields (3 bytes): endianness and sign info
  /// - Size (4 bytes): 8 bytes for int64
  /// - Bit offset (2 bytes): 0
  /// - Bit precision (2 bytes): 64
  List<int> _writeInt64({required Endian endian}) {
    final writer = ByteWriter(endian: endian);

    // Class and version: class=0 (integer), version=1
    final classAndVersion = (1 << 4) | 0; // version 1, class 0
    writer.writeUint8(classAndVersion);

    // Class bit field 1: byte order and padding
    // Bit 0: 0=little-endian, 1=big-endian
    // Bits 1-2: padding type (0=zero padding)
    // Bit 3: sign (1=signed)
    final classBitField1 = (endian == Endian.little ? 0 : 1) | (1 << 3);
    writer.writeUint8(classBitField1);

    // Class bit field 2: reserved
    writer.writeUint8(0);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes (version 1: size comes first)
    writer.writeUint32(8);

    // Bit offset (always 0 for standard types)
    writer.writeUint16(0);

    // Bit precision (64 bits for int64)
    writer.writeUint16(64);

    return writer.bytes;
  }
}

/// String-specific datatype information
class StringInfo {
  final StringPaddingType paddingType;
  final CharacterSet characterSet;
  final bool isVariableLength;

  StringInfo({
    required this.paddingType,
    required this.characterSet,
    required this.isVariableLength,
  });

  String decodeString(List<int> bytes) {
    if (bytes.isEmpty) return '';

    // Remove padding based on padding type
    List<int> trimmedBytes = bytes;
    if (paddingType == StringPaddingType.nullTerminate ||
        paddingType == StringPaddingType.nullPad) {
      // Find first null byte and trim
      final nullIndex = bytes.indexOf(0);
      if (nullIndex >= 0) {
        trimmedBytes = bytes.sublist(0, nullIndex);
      }
    } else if (paddingType == StringPaddingType.spacePad) {
      // Trim trailing spaces
      int endIndex = bytes.length;
      while (endIndex > 0 && bytes[endIndex - 1] == 0x20) {
        endIndex--;
      }
      trimmedBytes = bytes.sublist(0, endIndex);
    }

    // Decode based on character set
    if (characterSet == CharacterSet.utf8) {
      return utf8.decode(trimmedBytes, allowMalformed: true);
    } else {
      // ASCII
      return String.fromCharCodes(trimmedBytes);
    }
  }
}

/// Compound datatype field information
class CompoundField {
  final String name;
  final int offset;
  final Hdf5Datatype datatype;

  CompoundField({
    required this.name,
    required this.offset,
    required this.datatype,
  });

  @override
  String toString() =>
      'CompoundField(name=$name, offset=$offset, type=$datatype)';
}

/// Alternative name for compound field (for new API)
typedef Hdf5DatatypeField = CompoundField;

/// Compound datatype information
class CompoundInfo {
  final List<CompoundField> fields;

  CompoundInfo({required this.fields});

  CompoundField? getField(String name) {
    try {
      return fields.firstWhere((f) => f.name == name);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() =>
      'CompoundInfo(fields=[${fields.map((f) => f.name).join(", ")}])';
}

/// Array datatype information
class ArrayInfo {
  final List<int> dimensions;

  ArrayInfo({required this.dimensions});

  /// Total number of elements in the array
  int get totalElements => dimensions.fold(1, (a, b) => a * b);

  @override
  String toString() => 'ArrayInfo(dimensions=[${dimensions.join(", ")}])';
}

/// Enum datatype member
class EnumMember {
  final String name;
  final int value;

  EnumMember({required this.name, required this.value});

  @override
  String toString() => 'EnumMember($name=$value)';
}

/// Enum datatype information
class EnumInfo {
  final List<EnumMember> members;

  EnumInfo({required this.members});

  /// Get member name by value
  String? getNameByValue(int value) {
    try {
      return members.firstWhere((m) => m.value == value).name;
    } catch (e) {
      return null;
    }
  }

  /// Get member value by name
  int? getValueByName(String name) {
    try {
      return members.firstWhere((m) => m.name == name).value;
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() =>
      'EnumInfo(members=[${members.map((m) => '${m.name}=${m.value}').join(", ")}])';
}

/// Reference type enumeration
enum ReferenceType {
  object, // Reference to an object (dataset, group, etc.)
  region, // Reference to a region within a dataset
}

/// Reference datatype information
class ReferenceInfo {
  final ReferenceType type;

  ReferenceInfo({required this.type});

  @override
  String toString() => 'ReferenceInfo(type=$type)';
}

/// Opaque data wrapper with tag information
class OpaqueData {
  final Uint8List data;
  final String? tag;

  OpaqueData({required this.data, this.tag});

  /// Get data as hex string
  String toHexString() {
    return data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  @override
  String toString() =>
      'OpaqueData(${data.length} bytes${tag != null ? ', tag=$tag' : ''})';
}
