import 'dart:convert';
import 'dart:typed_data';
import 'byte_reader.dart';
import 'byte_writer.dart';
import 'datatype.dart';
import 'dataspace.dart';
import 'local_heap.dart';
import 'global_heap.dart';
import 'hdf5_error.dart';

/// HDF5 attribute containing metadata
///
/// This class handles both reading and writing of HDF5 attribute messages.
/// Attributes are small metadata values attached to datasets or groups.
class Hdf5Attribute {
  final String name;
  final Hdf5Datatype datatype;
  final Hdf5Dataspace dataspace;
  final dynamic value;

  Hdf5Attribute({
    required this.name,
    required this.datatype,
    required this.dataspace,
    required this.value,
  });

  /// Create a simple scalar attribute from a value
  ///
  /// This is a convenience constructor for creating attributes for writing.
  ///
  /// Example:
  /// ```dart
  /// // String attribute
  /// final attr1 = Hdf5Attribute.scalar('units', 'meters');
  ///
  /// // Integer attribute
  /// final attr2 = Hdf5Attribute.scalar('count', 42);
  ///
  /// // Float attribute
  /// final attr3 = Hdf5Attribute.scalar('temperature', 23.5);
  /// ```
  factory Hdf5Attribute.scalar(String name, dynamic value,
      {Endian endian = Endian.little}) {
    if (name.isEmpty) {
      throw ArgumentError('Attribute name cannot be empty');
    }

    // Determine datatype based on value type
    final Hdf5Datatype datatype;

    if (value is String) {
      final stringBytes = utf8.encode(value);
      datatype = Hdf5Datatype<String>(
        dataclass: Hdf5DatatypeClass.string,
        size: stringBytes.length + 1, // +1 for null terminator
        endian: endian,
        stringInfo: StringInfo(
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.utf8,
          isVariableLength: false,
        ),
      );
    } else if (value is int) {
      datatype = Hdf5Datatype.int64;
    } else if (value is double) {
      datatype = Hdf5Datatype.float64;
    } else {
      throw UnsupportedError(
        'Unsupported attribute value type: ${value.runtimeType}. '
        'Supported types: String, int, double',
      );
    }

    // Create scalar dataspace
    final dataspace = Hdf5Dataspace(
      version: 1,
      dimensionality: 0, // Scalar has 0 dimensions
      dimensions: [],
      maxDimensions: [],
    );

    return Hdf5Attribute(
      name: name,
      datatype: datatype,
      dataspace: dataspace,
      value: value,
    );
  }

  /// Parse attribute from attribute message data
  static Future<Hdf5Attribute> read(
    ByteReader reader,
    int messageSize, {
    ByteReader? fileReader,
    String? filePath,
    String? objectPath,
  }) async {
    // Read version
    final version = await reader.readUint8();

    if (version != 1 && version != 2 && version != 3) {
      throw UnsupportedVersionError(
        filePath: filePath,
        component: 'attribute message',
        version: version,
      );
    }

    // Read flags and name/datatype/dataspace sizes
    int nameSize;
    int datatypeSize;
    int dataspaceSize;

    if (version == 1) {
      await reader.readUint8(); // reserved
      nameSize = await reader.readUint16();
      datatypeSize = await reader.readUint16();
      dataspaceSize = await reader.readUint16();
    } else {
      // Version 2 and 3
      await reader.readUint8(); // flags
      nameSize = await reader.readUint16();
      datatypeSize = await reader.readUint16();
      dataspaceSize = await reader.readUint16();

      if (version == 3) {
        await reader.readUint8(); // encoding
      }
    }

    hdf5DebugLog('Attribute: version=$version, nameSize=$nameSize, '
        'datatypeSize=$datatypeSize, dataspaceSize=$dataspaceSize');

    // Track bytes read for alignment
    // Version 1: 1 (version) + 1 (reserved) + 2 (nameSize) + 2 (datatypeSize) + 2 (dataspaceSize) = 8 bytes
    // Version 2: 1 (version) + 1 (flags) + 2 (nameSize) + 2 (datatypeSize) + 2 (dataspaceSize) = 8 bytes
    // Version 3: 1 (version) + 1 (flags) + 2 (nameSize) + 2 (datatypeSize) + 2 (dataspaceSize) + 1 (encoding) = 9 bytes
    int bytesRead = version == 3 ? 9 : 8;

    // Read attribute name (null-terminated)
    final nameBytes = await reader.readBytes(nameSize);
    bytesRead += nameSize;
    final nullIndex = nameBytes.indexOf(0);
    final name = String.fromCharCodes(
      nullIndex >= 0 ? nameBytes.sublist(0, nullIndex) : nameBytes,
    );

    // Align to 8-byte boundary after name
    int padding = (8 - (bytesRead % 8)) % 8;
    if (padding > 0) {
      await reader.readBytes(padding);
      bytesRead += padding;
    }

    // Read datatype
    final datatypeBytes = await reader.readBytes(datatypeSize);
    bytesRead += datatypeSize;
    final datatypeReader =
        ByteReader.fromBytes(Uint8List.fromList(datatypeBytes));
    final datatype = await Hdf5Datatype.read(datatypeReader);

    // Align to 8-byte boundary after datatype
    padding = (8 - (bytesRead % 8)) % 8;
    if (padding > 0) {
      await reader.readBytes(padding);
      bytesRead += padding;
    }

    // Read dataspace
    final dataspaceBytes = await reader.readBytes(dataspaceSize);
    bytesRead += dataspaceSize;
    final dataspaceReader =
        ByteReader.fromBytes(Uint8List.fromList(dataspaceBytes));
    final dataspace = await Hdf5Dataspace.read(dataspaceReader);

    // Align to 8-byte boundary after dataspace
    padding = (8 - (bytesRead % 8)) % 8;
    if (padding > 0) {
      await reader.readBytes(padding);
      bytesRead += padding;
    }

    // Read attribute data
    final value = await _readAttributeData(
      reader,
      datatype,
      dataspace,
      fileReader: fileReader,
      filePath: filePath,
      objectPath: objectPath,
    );

    hdf5DebugLog('Attribute parsed: name=$name, value=$value');

    return Hdf5Attribute(
      name: name,
      datatype: datatype,
      dataspace: dataspace,
      value: value,
    );
  }

  /// Read attribute data based on datatype and dataspace
  static Future<dynamic> _readAttributeData(
    ByteReader reader,
    Hdf5Datatype datatype,
    Hdf5Dataspace dataspace, {
    ByteReader? fileReader,
    String? filePath,
    String? objectPath,
  }) async {
    final totalElements = dataspace.totalElements;

    // Handle scalar (single value)
    if (totalElements == 1) {
      return await _readSingleValue(
        reader,
        datatype,
        fileReader: fileReader,
        filePath: filePath,
        objectPath: objectPath,
      );
    }

    // Handle array
    final values = <dynamic>[];
    for (int i = 0; i < totalElements; i++) {
      values.add(await _readSingleValue(
        reader,
        datatype,
        fileReader: fileReader,
        filePath: filePath,
        objectPath: objectPath,
      ));
    }
    return values;
  }

  /// Read a single value based on datatype
  static Future<dynamic> _readSingleValue(
    ByteReader reader,
    Hdf5Datatype datatype, {
    ByteReader? fileReader,
    String? filePath,
    String? objectPath,
  }) async {
    // Handle variable-length datatypes (like vlen strings)
    hdf5DebugLog(
        'Checking datatype: classId=${datatype.classId}, hasBaseType=${datatype.baseType != null}');
    if (datatype.classId == 9 && datatype.baseType != null) {
      // For attributes, vlen data structure is:
      // - 4 bytes: length
      // - 4 bytes: heap ID (heap address)
      // - 4 bytes: reserved (always 0)
      // - 4 bytes: index (1-based index into heap entries)
      final length = await reader.readUint32();
      final heapId = await reader.readUint32();
      await reader.readUint32(); // reserved
      final index = await reader.readUint32();

      hdf5DebugLog(
          'Vlen baseType: classId=${datatype.baseType!.classId}, size=${datatype.baseType!.size}, isString=${datatype.baseType!.isString}');
      // Vlen strings have a 1-byte integer base type (character)
      final isVlenString = datatype.baseType!.isString ||
          (datatype.baseType!.classId == 0 && datatype.baseType!.size == 1);
      if (isVlenString) {
        // Read string from local heap using index
        hdf5DebugLog(
            'Attempting to read vlen string: fileReader=${fileReader != null}, index=$index');
        if (fileReader != null) {
          try {
            final savedPos = fileReader.position;

            // Read the local heap header
            final heap =
                await LocalHeap.read(fileReader, heapId, filePath: filePath);

            // Navigate to the indexed entry
            // Each entry is: 8 bytes length + data (padded to 8 bytes)
            hdf5DebugLog(
                'Heap data segment at 0x${heap.dataSegmentAddress.toRadixString(16)}');
            fileReader.seek(heap.dataSegmentAddress);

            // Skip to the desired index (1-based, so index 1 = first entry)
            // Each entry is: 8 bytes length + data (padded to 8) + 8 bytes separator
            for (int i = 1; i < index; i++) {
              final entryLength = await fileReader.readUint64();
              final dataPadding = (8 - (entryLength % 8)) % 8;
              await fileReader.readBytes(entryLength + dataPadding);
              await fileReader.readUint64(); // Skip separator
            }

            // Read the target entry
            final entryLength = await fileReader.readUint64();
            hdf5DebugLog(
                'Reading vlen string: index=$index, entryLength=$entryLength, position=0x${fileReader.position.toRadixString(16)}');
            final stringBytes = await fileReader.readBytes(entryLength);

            fileReader.seek(savedPos);

            // Decode as string
            if (datatype.baseType!.stringInfo != null) {
              final stringInfo = datatype.baseType!.stringInfo!;
              return stringInfo.decodeString(stringBytes);
            } else {
              // For character arrays, just decode as UTF-8
              return String.fromCharCodes(stringBytes.where((b) => b != 0));
            }
          } catch (e) {
            hdf5DebugLog('Failed to read vlen string from heap: $e');
            // Fall back to returning the heap info
            return '[heap:0x${heapId.toRadixString(16)}, index:$index, len:$length]';
          }
        } else {
          return '[heap:0x${heapId.toRadixString(16)}, index:$index, len:$length]';
        }
      } else {
        // For other vlen types, return heap info for now
        return '[heap:0x${heapId.toRadixString(16)}, index:$index, len:$length]';
      }
    }

    // Handle string datatypes
    if (datatype.isString && datatype.stringInfo != null) {
      final stringInfo = datatype.stringInfo!;

      if (stringInfo.isVariableLength) {
        throw UnsupportedFeatureError(
          filePath: filePath,
          objectPath: objectPath,
          feature: 'Variable-length strings in attributes (non-vlen type)',
          details:
              'Variable-length string support requires global heap implementation',
        );
      }

      final bytes = await reader.readBytes(datatype.size);
      return stringInfo.decodeString(bytes);
    }

    // Handle compound datatypes
    if (datatype.isCompound && datatype.compoundInfo != null) {
      final compoundInfo = datatype.compoundInfo!;
      final startPos = reader.position;
      final result = <String, dynamic>{};

      for (final field in compoundInfo.fields) {
        reader.seek(startPos + field.offset);
        final value = await _readSingleValue(
          reader,
          field.datatype,
          filePath: filePath,
          objectPath: objectPath,
        );
        result[field.name] = value;
      }

      reader.seek(startPos + datatype.size);
      return result;
    }

    // Handle numeric types
    switch (datatype.classId) {
      case 0: // Integer
        switch (datatype.size) {
          case 1:
            return await reader.readInt8();
          case 2:
            return await reader.readInt16();
          case 4:
            return await reader.readInt32();
          case 8:
            return await reader.readInt64();
        }
        break;
      case 1: // Float
        switch (datatype.size) {
          case 4:
            return await reader.readFloat32();
          case 8:
            return await reader.readFloat64();
        }
        break;
    }

    throw UnsupportedDatatypeError(
      filePath: filePath,
      objectPath: objectPath,
      datatypeInfo: 'class=${datatype.classId}, size=${datatype.size} bytes',
    );
  }

  /// Get value as specific type (for scalar attributes)
  T getValue<T>() {
    if (value is T) {
      return value as T;
    }
    throw TypeError();
  }

  /// Get value as array (for array attributes)
  List<T> getArray<T>() {
    if (value is List) {
      return (value as List).cast<T>();
    }
    throw TypeError();
  }

  /// Check if attribute is scalar
  bool get isScalar => dataspace.totalElements == 1;

  /// Check if attribute is array
  bool get isArray => dataspace.totalElements > 1;

  /// Write this attribute as an HDF5 message
  ///
  /// Returns the message bytes following HDF5 attribute message format version 1:
  /// - Version (1 byte): 1
  /// - Reserved (1 byte): 0
  /// - Name size (2 bytes): length of name including null terminator
  /// - Datatype size (2 bytes): size of datatype message
  /// - Dataspace size (2 bytes): size of dataspace message
  /// - Name (variable): null-terminated attribute name, aligned to 8 bytes
  /// - Datatype (variable): datatype message
  /// - Dataspace (variable): dataspace message
  /// - Data (variable): attribute value
  ///
  /// Parameters:
  /// - [endian]: Byte order (default: little-endian)
  /// - [globalHeapWriter]: Optional global heap writer for variable-length data
  /// - [globalHeapAddress]: Address where the global heap will be written (required if globalHeapWriter is provided)
  ///
  /// Examples:
  /// ```dart
  /// // String attribute
  /// final attr1 = Hdf5Attribute.scalar('units', 'meters');
  /// final bytes1 = attr1.write();
  ///
  /// // Integer attribute
  /// final attr2 = Hdf5Attribute.scalar('count', 42);
  /// final bytes2 = attr2.write();
  ///
  /// // Float attribute
  /// final attr3 = Hdf5Attribute.scalar('temperature', 23.5);
  /// final bytes3 = attr3.write();
  ///
  /// // With explicit endianness
  /// final attr4 = Hdf5Attribute.scalar('value', 100, endian: Endian.big);
  /// final bytes4 = attr4.write(endian: Endian.big);
  ///
  /// // With global heap for variable-length strings
  /// final heapWriter = GlobalHeapWriter();
  /// final attr5 = Hdf5Attribute.scalar('description', 'A very long variable-length string...');
  /// final bytes5 = attr5.write(globalHeapWriter: heapWriter, globalHeapAddress: 2048);
  /// ```
  List<int> write({
    Endian endian = Endian.little,
    GlobalHeapWriter? globalHeapWriter,
    int? globalHeapAddress,
  }) {
    final writer = ByteWriter(endian: endian);

    // Encode attribute name (null-terminated)
    final nameBytes = utf8.encode(name);
    final nameWithNull = [...nameBytes, 0];

    // Generate datatype message
    List<int> datatypeMessage;
    if (datatype.dataclass == Hdf5DatatypeClass.string) {
      datatypeMessage = _writeStringDatatype(datatype, endian: endian);
    } else {
      datatypeMessage = datatype.write(endian: endian);
    }

    // Generate dataspace message
    final dataspaceMessage = _writeDataspace(endian: endian);

    // Encode data
    final data = _encodeValue(
      value,
      datatype,
      endian: endian,
      globalHeapWriter: globalHeapWriter,
      globalHeapAddress: globalHeapAddress,
    );

    // Write attribute message header
    writer.writeUint8(1); // Version 1
    writer.writeUint8(0); // Reserved

    // Write sizes
    writer.writeUint16(nameWithNull.length); // Name size
    writer.writeUint16(datatypeMessage.length); // Datatype size
    writer.writeUint16(dataspaceMessage.length); // Dataspace size

    // Write name (null-terminated, aligned to 8 bytes)
    writer.writeBytes(nameWithNull);
    writer.alignTo(8);

    // Write datatype message
    writer.writeBytes(datatypeMessage);

    // Write dataspace message
    writer.writeBytes(dataspaceMessage);

    // Write data
    writer.writeBytes(data);

    return writer.bytes;
  }

  /// Write a string datatype message
  List<int> _writeStringDatatype(Hdf5Datatype datatype,
      {required Endian endian}) {
    final writer = ByteWriter(endian: endian);

    // Class and version: class=3 (string), version=1
    final classAndVersion = (1 << 4) | 3; // version 1, class 3
    writer.writeUint8(classAndVersion);

    // Class bit field 1: padding type and character set
    final paddingType =
        datatype.stringInfo?.paddingType == StringPaddingType.nullTerminate
            ? 0
            : datatype.stringInfo?.paddingType == StringPaddingType.nullPad
                ? 1
                : 2;
    final characterSet =
        datatype.stringInfo?.characterSet == CharacterSet.utf8 ? 1 : 0;
    final classBitField1 = paddingType | (characterSet << 4);
    writer.writeUint8(classBitField1);

    // Class bit field 2 & 3: reserved
    writer.writeUint8(0);
    writer.writeUint8(0);

    // Size in bytes
    writer.writeUint32(datatype.size);

    return writer.bytes;
  }

  /// Write the dataspace message
  List<int> _writeDataspace({required Endian endian}) {
    if (dataspace.dimensionality == 0) {
      // Scalar dataspace
      final writer = ByteWriter(endian: endian);
      writer.writeUint8(1); // Version 1
      writer.writeUint8(0); // Dimensionality (0 for scalar)
      writer.writeUint8(0); // Flags
      writer.writeUint8(0); // Reserved
      writer.writeUint32(0); // Reserved 4 bytes
      return writer.bytes;
    } else {
      // Use dataspace's write method
      return dataspace.write(endian: endian);
    }
  }

  /// Encode value to bytes based on datatype
  ///
  /// Parameters:
  /// - [value]: The value to encode
  /// - [datatype]: The HDF5 datatype
  /// - [endian]: Byte order
  /// - [globalHeapWriter]: Optional global heap writer for variable-length data
  /// - [globalHeapAddress]: Address where the global heap will be written
  ///
  /// For variable-length strings or large attributes, if globalHeapWriter is provided,
  /// the data will be allocated in the global heap and a reference will be returned.
  List<int> _encodeValue(
    dynamic value,
    Hdf5Datatype datatype, {
    required Endian endian,
    GlobalHeapWriter? globalHeapWriter,
    int? globalHeapAddress,
  }) {
    final writer = ByteWriter(endian: endian);

    if (value is String) {
      // Check if this should use global heap (variable-length or large strings)
      final stringBytes = utf8.encode(value);
      final useGlobalHeap = globalHeapWriter != null &&
          globalHeapAddress != null &&
          (datatype.stringInfo?.isVariableLength == true ||
              stringBytes.length > 255);

      if (useGlobalHeap) {
        // Allocate in global heap and write reference
        final heapId = globalHeapWriter.allocate(stringBytes);
        final reference =
            globalHeapWriter.createReference(heapId, globalHeapAddress);
        writer.writeBytes(reference);
      } else {
        // Write as fixed-length string with null terminator
        writer.writeBytes([...stringBytes, 0]);
      }
    } else if (value is int) {
      writer.writeInt64(value);
    } else if (value is double) {
      writer.writeFloat64(value);
    } else {
      throw UnsupportedError('Unsupported value type: ${value.runtimeType}');
    }

    return writer.bytes;
  }

  @override
  String toString() {
    final valueStr = value is List && (value as List).length > 10
        ? '[${(value as List).take(10).join(", ")}...]'
        : value.toString();
    return 'Hdf5Attribute(name=$name, value=$valueStr)';
  }
}
