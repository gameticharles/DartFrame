import 'dart:typed_data';
import 'dart:convert';
import 'datatype.dart';
import 'byte_writer.dart';

/// Hint for explicit datatype specification when auto-detection is ambiguous
enum DatatypeHint {
  /// 8-bit signed integer
  int8,

  /// 8-bit unsigned integer
  uint8,

  /// 16-bit signed integer
  int16,

  /// 16-bit unsigned integer
  uint16,

  /// 32-bit signed integer
  int32,

  /// 32-bit unsigned integer
  uint32,

  /// 64-bit signed integer
  int64,

  /// 64-bit unsigned integer
  uint64,

  /// 32-bit floating point (single precision)
  float32,

  /// 64-bit floating point (double precision)
  float64,

  /// Fixed-length string
  fixedString,

  /// Variable-length string
  variableString,

  /// Boolean (stored as 8-bit enum)
  boolean,

  /// Compound datatype (struct-like)
  compound,
}

/// Base abstract class for HDF5 datatype writers
///
/// This class provides the interface for writing HDF5 datatype messages.
/// Each concrete implementation handles a specific HDF5 datatype class
/// (numeric, string, compound, etc.).
///
/// The datatype message format follows the HDF5 specification and includes:
/// - Class and version information
/// - Size and byte order
/// - Type-specific properties
///
/// Example usage:
/// ```dart
/// // Create a float64 writer
/// final writer = NumericDatatypeWriter.float64();
/// final message = writer.writeMessage();
/// final size = writer.getSize();
/// ```
abstract class DatatypeWriter {
  /// Write the datatype message bytes
  ///
  /// Returns the complete datatype message following HDF5 specification.
  /// The message includes class, version, size, and type-specific properties.
  List<int> writeMessage();

  /// Get the size of the datatype in bytes
  ///
  /// Returns the size of a single data element of this type.
  /// For variable-length types, returns -1 (0xFFFFFFFF in HDF5).
  int getSize();

  /// Get the HDF5 datatype class
  ///
  /// Returns the datatype class enum value (integer, float, string, etc.)
  Hdf5DatatypeClass get datatypeClass;

  /// Get the byte order for this datatype
  ///
  /// Returns the endianness (little or big endian).
  /// Default is little-endian for most platforms.
  Endian get endian => Endian.little;
}

/// Factory for creating appropriate DatatypeWriter based on data type
///
/// This factory analyzes data and creates the correct writer implementation.
/// It supports auto-detection of types from Dart values and explicit type
/// specification via DatatypeHint for ambiguous cases.
///
/// Example usage:
/// ```dart
/// // Auto-detect from value
/// final writer1 = DatatypeWriterFactory.create(3.14); // Creates float64 writer
/// final writer2 = DatatypeWriterFactory.create(42);   // Creates int64 writer
///
/// // Explicit type specification
/// final writer3 = DatatypeWriterFactory.create(42, hint: DatatypeHint.int32);
/// final writer4 = DatatypeWriterFactory.create("hello", hint: DatatypeHint.fixedString);
/// ```
class DatatypeWriterFactory {
  /// Create a datatype writer based on the provided data
  ///
  /// Parameters:
  /// - [data]: The data value to analyze for type detection
  /// - [hint]: Optional explicit type hint for ambiguous cases
  /// - [endian]: Optional byte order (default: little-endian)
  ///
  /// Returns a DatatypeWriter instance appropriate for the data type.
  ///
  /// Throws [UnsupportedError] if the data type cannot be handled.
  static DatatypeWriter create(
    dynamic data, {
    DatatypeHint? hint,
    Endian? endian,
  }) {
    // If hint is provided, use it for explicit type specification
    if (hint != null) {
      return _createFromHint(hint, endian: endian);
    }

    // Auto-detect type from data
    return _createFromData(data, endian: endian);
  }

  /// Create writer from explicit hint
  static DatatypeWriter _createFromHint(
    DatatypeHint hint, {
    Endian? endian,
  }) {
    final effectiveEndian = endian ?? Endian.little;

    switch (hint) {
      case DatatypeHint.int8:
        return NumericDatatypeWriter.int8(endian: effectiveEndian);
      case DatatypeHint.uint8:
        return NumericDatatypeWriter.uint8(endian: effectiveEndian);
      case DatatypeHint.int16:
        return NumericDatatypeWriter.int16(endian: effectiveEndian);
      case DatatypeHint.uint16:
        return NumericDatatypeWriter.uint16(endian: effectiveEndian);
      case DatatypeHint.int32:
        return NumericDatatypeWriter.int32(endian: effectiveEndian);
      case DatatypeHint.uint32:
        return NumericDatatypeWriter.uint32(endian: effectiveEndian);
      case DatatypeHint.int64:
        return NumericDatatypeWriter.int64(endian: effectiveEndian);
      case DatatypeHint.uint64:
        return NumericDatatypeWriter.uint64(endian: effectiveEndian);
      case DatatypeHint.float32:
        return NumericDatatypeWriter.float32(endian: effectiveEndian);
      case DatatypeHint.float64:
        return NumericDatatypeWriter.float64(endian: effectiveEndian);
      case DatatypeHint.fixedString:
        // Default fixed-length string: 256 bytes, null-terminated, ASCII
        return StringDatatypeWriter.fixedLength(
          length: 256,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
          endian: effectiveEndian,
        );
      case DatatypeHint.variableString:
        // Variable-length string with ASCII encoding
        return StringDatatypeWriter.variableLength(
          characterSet: CharacterSet.ascii,
          endian: effectiveEndian,
        );
      case DatatypeHint.boolean:
        // Boolean stored as 8-bit enum
        return BooleanDatatypeWriter(endian: effectiveEndian);
      case DatatypeHint.compound:
        // Compound type requires additional data, throw error
        throw ArgumentError(
          'Compound datatype hint requires explicit field specification. '
          'Use CompoundDatatypeWriter.fromFields() instead.',
        );
    }
  }

  /// Create writer from data auto-detection
  static DatatypeWriter _createFromData(
    dynamic data, {
    Endian? endian,
  }) {
    if (data is double) {
      // Default to float64 for Dart double
      return _createFromHint(DatatypeHint.float64, endian: endian);
    } else if (data is int) {
      // Default to int64 for Dart int
      return _createFromHint(DatatypeHint.int64, endian: endian);
    } else if (data is String) {
      // Default to variable-length string
      return _createFromHint(DatatypeHint.variableString, endian: endian);
    } else if (data is bool) {
      // Boolean stored as enum
      return BooleanDatatypeWriter(endian: endian ?? Endian.little);
    } else if (data is Map<String, dynamic>) {
      // Compound type from map - create from field map
      return CompoundDatatypeWriter.fromMap(data, endian: endian);
    } else {
      throw UnsupportedError(
        'Unsupported data type: ${data.runtimeType}. '
        'Supported types: double, int, String, bool, Map (compound)',
      );
    }
  }

  /// Create a writer for a specific Hdf5Datatype
  ///
  /// This method creates a writer that can reproduce the given datatype.
  /// Useful for writing data that matches an existing datatype specification.
  ///
  /// Parameters:
  /// - [datatype]: The HDF5 datatype to create a writer for
  ///
  /// Returns a DatatypeWriter that will produce the same datatype message.
  static DatatypeWriter fromDatatype(Hdf5Datatype datatype) {
    // Placeholder - will be implemented with specific writer classes
    throw UnimplementedError(
      'DatatypeWriter creation from Hdf5Datatype not yet implemented. '
      'This will be supported once specific writer classes are implemented.',
    );
  }
}

/// Writer for numeric HDF5 datatypes (integers and floating-point)
///
/// This class handles writing datatype messages for all standard numeric types:
/// - Integers: int8, int16, int32, int64, uint8, uint16, uint32, uint64
/// - Floating-point: float32, float64
///
/// The writer follows HDF5 datatype message format version 1 and supports
/// both little-endian and big-endian byte orders.
///
/// Example usage:
/// ```dart
/// // Create a float32 writer
/// final writer = NumericDatatypeWriter.float32();
/// final message = writer.writeMessage();
/// final size = writer.getSize(); // Returns 4
///
/// // Create an int16 writer with big-endian
/// final writer2 = NumericDatatypeWriter.int16(endian: Endian.big);
/// ```
class NumericDatatypeWriter extends DatatypeWriter {
  final Hdf5DatatypeClass _dataclass;
  final int _size;
  final Endian _endian;
  final bool _isSigned;

  NumericDatatypeWriter._({
    required Hdf5DatatypeClass dataclass,
    required int size,
    required Endian endian,
    required bool isSigned,
  })  : _dataclass = dataclass,
        _size = size,
        _endian = endian,
        _isSigned = isSigned;

  // Factory methods for integer types

  /// Create a writer for 8-bit signed integer (int8)
  factory NumericDatatypeWriter.int8({Endian endian = Endian.little}) {
    return NumericDatatypeWriter._(
      dataclass: Hdf5DatatypeClass.integer,
      size: 1,
      endian: endian,
      isSigned: true,
    );
  }

  /// Create a writer for 8-bit unsigned integer (uint8)
  factory NumericDatatypeWriter.uint8({Endian endian = Endian.little}) {
    return NumericDatatypeWriter._(
      dataclass: Hdf5DatatypeClass.integer,
      size: 1,
      endian: endian,
      isSigned: false,
    );
  }

  /// Create a writer for 16-bit signed integer (int16)
  factory NumericDatatypeWriter.int16({Endian endian = Endian.little}) {
    return NumericDatatypeWriter._(
      dataclass: Hdf5DatatypeClass.integer,
      size: 2,
      endian: endian,
      isSigned: true,
    );
  }

  /// Create a writer for 16-bit unsigned integer (uint16)
  factory NumericDatatypeWriter.uint16({Endian endian = Endian.little}) {
    return NumericDatatypeWriter._(
      dataclass: Hdf5DatatypeClass.integer,
      size: 2,
      endian: endian,
      isSigned: false,
    );
  }

  /// Create a writer for 32-bit signed integer (int32)
  factory NumericDatatypeWriter.int32({Endian endian = Endian.little}) {
    return NumericDatatypeWriter._(
      dataclass: Hdf5DatatypeClass.integer,
      size: 4,
      endian: endian,
      isSigned: true,
    );
  }

  /// Create a writer for 32-bit unsigned integer (uint32)
  factory NumericDatatypeWriter.uint32({Endian endian = Endian.little}) {
    return NumericDatatypeWriter._(
      dataclass: Hdf5DatatypeClass.integer,
      size: 4,
      endian: endian,
      isSigned: false,
    );
  }

  /// Create a writer for 64-bit signed integer (int64)
  factory NumericDatatypeWriter.int64({Endian endian = Endian.little}) {
    return NumericDatatypeWriter._(
      dataclass: Hdf5DatatypeClass.integer,
      size: 8,
      endian: endian,
      isSigned: true,
    );
  }

  /// Create a writer for 64-bit unsigned integer (uint64)
  factory NumericDatatypeWriter.uint64({Endian endian = Endian.little}) {
    return NumericDatatypeWriter._(
      dataclass: Hdf5DatatypeClass.integer,
      size: 8,
      endian: endian,
      isSigned: false,
    );
  }

  // Factory methods for floating-point types

  /// Create a writer for 32-bit floating-point (float32)
  factory NumericDatatypeWriter.float32({Endian endian = Endian.little}) {
    return NumericDatatypeWriter._(
      dataclass: Hdf5DatatypeClass.float,
      size: 4,
      endian: endian,
      isSigned: true, // Floating-point is always signed
    );
  }

  /// Create a writer for 64-bit floating-point (float64)
  factory NumericDatatypeWriter.float64({Endian endian = Endian.little}) {
    return NumericDatatypeWriter._(
      dataclass: Hdf5DatatypeClass.float,
      size: 8,
      endian: endian,
      isSigned: true, // Floating-point is always signed
    );
  }

  @override
  Hdf5DatatypeClass get datatypeClass => _dataclass;

  @override
  int getSize() => _size;

  @override
  Endian get endian => _endian;

  @override
  List<int> writeMessage() {
    if (_dataclass == Hdf5DatatypeClass.integer) {
      return _writeIntegerMessage();
    } else if (_dataclass == Hdf5DatatypeClass.float) {
      return _writeFloatMessage();
    } else {
      throw UnsupportedError('Unsupported dataclass: $_dataclass');
    }
  }

  /// Write integer datatype message
  ///
  /// Format (HDF5 version 1):
  /// - Class and version (1 byte): class=0 (integer), version=1
  /// - Class bit fields (3 bytes): endianness, padding, sign
  /// - Size (4 bytes): size in bytes
  /// - Bit offset (2 bytes): 0 for standard types
  /// - Bit precision (2 bytes): size * 8
  List<int> _writeIntegerMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=0 (integer), version=1
    final classAndVersion = (1 << 4) | 0; // version 1, class 0
    writer.writeUint8(classAndVersion);

    // Class bit field 1: byte order, padding, and sign
    // Bit 0: 0=little-endian, 1=big-endian
    // Bits 1-2: padding type (0=zero padding)
    // Bit 3: sign (0=unsigned, 1=signed)
    final byteOrderBit = _endian == Endian.little ? 0 : 1;
    final signBit = _isSigned ? (1 << 3) : 0;
    final classBitField1 = byteOrderBit | signBit;
    writer.writeUint8(classBitField1);

    // Class bit field 2: reserved
    writer.writeUint8(0);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes (version 1: size comes first)
    writer.writeUint32(_size);

    // Bit offset (always 0 for standard types)
    writer.writeUint16(0);

    // Bit precision (size * 8 bits)
    writer.writeUint16(_size * 8);

    return writer.bytes;
  }

  /// Write floating-point datatype message
  ///
  /// Format (HDF5 version 1):
  /// - Class and version (1 byte): class=1 (float), version=1
  /// - Class bit fields (3 bytes): endianness, padding, mantissa normalization, sign location
  /// - Size (4 bytes): size in bytes
  /// - Bit offset (2 bytes): 0 for standard types
  /// - Bit precision (2 bytes): size * 8
  /// - Exponent location (1 byte): bit position of exponent
  /// - Exponent size (1 byte): number of bits in exponent
  /// - Mantissa location (1 byte): bit position of mantissa
  /// - Mantissa size (1 byte): number of bits in mantissa
  /// - Exponent bias (4 bytes): bias value for exponent
  List<int> _writeFloatMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=1 (floating point), version=1
    final classAndVersion = (1 << 4) | 1; // version 1, class 1
    writer.writeUint8(classAndVersion);

    // Determine IEEE 754 parameters based on size
    int exponentLocation,
        exponentSize,
        mantissaSize,
        exponentBias,
        signLocation;

    if (_size == 4) {
      // float32 (IEEE 754 single precision)
      exponentLocation = 23;
      exponentSize = 8;
      mantissaSize = 23;
      exponentBias = 127;
      signLocation = 31;
    } else if (_size == 8) {
      // float64 (IEEE 754 double precision)
      exponentLocation = 52;
      exponentSize = 11;
      mantissaSize = 52;
      exponentBias = 1023;
      signLocation = 63;
    } else {
      throw UnsupportedError('Unsupported float size: $_size');
    }

    // Class bit field 1: byte order, padding, and mantissa normalization
    // Bit 0: 0=little-endian, 1=big-endian
    // Bits 1-3: padding type (0=zero padding)
    // Bits 4-7: mantissa normalization (2=implied 1, as in IEEE 754)
    final byteOrderBit = _endian == Endian.little ? 0 : 1;
    final classBitField1 = byteOrderBit | (2 << 4);
    writer.writeUint8(classBitField1);

    // Class bit field 2: sign location
    writer.writeUint8(signLocation);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes (version 1: size comes first)
    writer.writeUint32(_size);

    // Bit offset (always 0 for standard types)
    writer.writeUint16(0);

    // Bit precision (size * 8 bits)
    writer.writeUint16(_size * 8);

    // Exponent location (bit position)
    writer.writeUint8(exponentLocation);

    // Exponent size (number of bits)
    writer.writeUint8(exponentSize);

    // Mantissa location (bit 0)
    writer.writeUint8(0);

    // Mantissa size (number of bits)
    writer.writeUint8(mantissaSize);

    // Exponent bias
    writer.writeUint32(exponentBias);

    return writer.bytes;
  }
}

/// Writer for string HDF5 datatypes (fixed-length and variable-length)
///
/// This class handles writing datatype messages for string types:
/// - Fixed-length strings with configurable padding (null-terminate, null-pad, space-pad)
/// - Variable-length strings (stored in global heap)
/// - ASCII and UTF-8 character sets
///
/// The writer follows HDF5 datatype message format version 1 for string class (3).
///
/// Example usage:
/// ```dart
/// // Create a fixed-length string writer (20 characters, null-terminated, ASCII)
/// final writer1 = StringDatatypeWriter.fixedLength(
///   length: 20,
///   paddingType: StringPaddingType.nullTerminate,
///   characterSet: CharacterSet.ascii,
/// );
///
/// // Create a variable-length string writer (UTF-8)
/// final writer2 = StringDatatypeWriter.variableLength(
///   characterSet: CharacterSet.utf8,
/// );
///
/// // Write the datatype message
/// final message = writer1.writeMessage();
/// final size = writer1.getSize(); // Returns 20 for fixed-length
/// ```
class StringDatatypeWriter extends DatatypeWriter {
  final int _length; // -1 for variable-length
  final StringPaddingType _paddingType;
  final CharacterSet _characterSet;
  final Endian _endian;

  StringDatatypeWriter._({
    required int length,
    required StringPaddingType paddingType,
    required CharacterSet characterSet,
    required Endian endian,
  })  : _length = length,
        _paddingType = paddingType,
        _characterSet = characterSet,
        _endian = endian;

  /// Create a writer for fixed-length strings
  ///
  /// Parameters:
  /// - [length]: The fixed length of the string in bytes
  /// - [paddingType]: How to pad strings shorter than the fixed length
  /// - [characterSet]: Character encoding (ASCII or UTF-8)
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// // 50-character ASCII string, null-terminated
  /// final writer = StringDatatypeWriter.fixedLength(
  ///   length: 50,
  ///   paddingType: StringPaddingType.nullTerminate,
  ///   characterSet: CharacterSet.ascii,
  /// );
  /// ```
  factory StringDatatypeWriter.fixedLength({
    required int length,
    StringPaddingType paddingType = StringPaddingType.nullTerminate,
    CharacterSet characterSet = CharacterSet.ascii,
    Endian endian = Endian.little,
  }) {
    if (length <= 0) {
      throw ArgumentError('Fixed-length string length must be positive');
    }
    return StringDatatypeWriter._(
      length: length,
      paddingType: paddingType,
      characterSet: characterSet,
      endian: endian,
    );
  }

  /// Create a writer for variable-length strings
  ///
  /// Variable-length strings are stored in the global heap with references
  /// in the dataset. The size is encoded as 0xFFFFFFFF (-1) in the datatype.
  ///
  /// Parameters:
  /// - [characterSet]: Character encoding (ASCII or UTF-8)
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// // Variable-length UTF-8 string
  /// final writer = StringDatatypeWriter.variableLength(
  ///   characterSet: CharacterSet.utf8,
  /// );
  /// ```
  factory StringDatatypeWriter.variableLength({
    CharacterSet characterSet = CharacterSet.ascii,
    Endian endian = Endian.little,
  }) {
    return StringDatatypeWriter._(
      length: -1, // Variable-length indicator
      paddingType: StringPaddingType
          .nullTerminate, // Padding type not used for variable-length
      characterSet: characterSet,
      endian: endian,
    );
  }

  @override
  Hdf5DatatypeClass get datatypeClass => Hdf5DatatypeClass.string;

  @override
  int getSize() => _length;

  @override
  Endian get endian => _endian;

  /// Check if this is a variable-length string
  bool get isVariableLength => _length == -1;

  @override
  List<int> writeMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=3 (string), version=1
    final classAndVersion = (1 << 4) | 3; // version 1, class 3
    writer.writeUint8(classAndVersion);

    // Class bit field 1: padding type and character set
    // Bits 0-3: padding type (0=null-terminate, 1=null-pad, 2=space-pad)
    // Bits 4-7: character set (0=ASCII, 1=UTF-8)
    final paddingBits = _paddingTypeToInt(_paddingType);
    final charsetBits = _characterSetToInt(_characterSet) << 4;
    final classBitField1 = paddingBits | charsetBits;
    writer.writeUint8(classBitField1);

    // Class bit field 2: reserved
    writer.writeUint8(0);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes
    // For variable-length strings, use 0xFFFFFFFF
    // For fixed-length strings, use the specified length
    if (isVariableLength) {
      writer.writeUint32(0xFFFFFFFF);
    } else {
      writer.writeUint32(_length);
    }

    return writer.bytes;
  }

  /// Convert StringPaddingType to integer value for HDF5 format
  int _paddingTypeToInt(StringPaddingType type) {
    switch (type) {
      case StringPaddingType.nullTerminate:
        return 0;
      case StringPaddingType.nullPad:
        return 1;
      case StringPaddingType.spacePad:
        return 2;
    }
  }

  /// Convert CharacterSet to integer value for HDF5 format
  int _characterSetToInt(CharacterSet charset) {
    switch (charset) {
      case CharacterSet.ascii:
        return 0;
      case CharacterSet.utf8:
        return 1;
    }
  }

  /// Encode a string value according to this datatype's settings
  ///
  /// For fixed-length strings, pads or truncates to the specified length.
  /// For variable-length strings, returns the encoded bytes without padding.
  ///
  /// Parameters:
  /// - [value]: The string to encode
  ///
  /// Returns the encoded bytes ready to be written to the HDF5 file.
  ///
  /// Example:
  /// ```dart
  /// final writer = StringDatatypeWriter.fixedLength(
  ///   length: 10,
  ///   paddingType: StringPaddingType.nullPad,
  /// );
  /// final encoded = writer.encodeString('hello'); // Returns 10 bytes
  /// ```
  List<int> encodeString(String value) {
    // Encode the string based on character set
    List<int> bytes;
    if (_characterSet == CharacterSet.utf8) {
      bytes = utf8.encode(value);
    } else {
      // ASCII - use code units directly
      bytes = value.codeUnits;
    }

    // For variable-length strings, return as-is
    if (isVariableLength) {
      return bytes;
    }

    // For fixed-length strings, apply padding
    if (bytes.length >= _length) {
      // Truncate if too long
      return bytes.sublist(0, _length);
    } else {
      // Pad if too short
      final padded = List<int>.filled(_length, 0);
      padded.setRange(0, bytes.length, bytes);

      // Apply padding type
      switch (_paddingType) {
        case StringPaddingType.nullTerminate:
          // Null-terminate: add null byte after string, rest is zeros
          if (bytes.length < _length) {
            padded[bytes.length] = 0;
          }
          break;
        case StringPaddingType.nullPad:
          // Null-pad: fill remaining space with null bytes (already done)
          break;
        case StringPaddingType.spacePad:
          // Space-pad: fill remaining space with spaces
          for (int i = bytes.length; i < _length; i++) {
            padded[i] = 0x20; // Space character
          }
          break;
      }

      return padded;
    }
  }

  /// Encode a variable-length string with global heap allocation
  ///
  /// This method is used for variable-length strings that need to be stored
  /// in the global heap. It encodes the string and returns both the encoded
  /// data and metadata needed for heap allocation.
  ///
  /// Parameters:
  /// - [value]: The string to encode
  ///
  /// Returns the encoded bytes that should be allocated in the global heap.
  ///
  /// Throws [UnsupportedError] if this is not a variable-length string writer.
  ///
  /// Example:
  /// ```dart
  /// final writer = StringDatatypeWriter.variableLength();
  /// final data = writer.encodeForGlobalHeap('Variable-length string');
  /// // Allocate data in global heap and get heap ID
  /// ```
  List<int> encodeForGlobalHeap(String value) {
    if (!isVariableLength) {
      throw UnsupportedError(
        'encodeForGlobalHeap() can only be used with variable-length strings',
      );
    }

    // Encode the string based on character set
    if (_characterSet == CharacterSet.utf8) {
      return utf8.encode(value);
    } else {
      // ASCII - use code units directly
      return value.codeUnits;
    }
  }
}

/// Writer for boolean HDF5 datatypes (stored as 8-bit enumeration)
///
/// This class handles writing datatype messages for boolean values.
/// Booleans are stored as 8-bit enumerations with two members:
/// - FALSE = 0
/// - TRUE = 1
///
/// The writer follows HDF5 datatype message format version 1 for enum class (8).
///
/// Example usage:
/// ```dart
/// // Create a boolean writer
/// final writer = BooleanDatatypeWriter();
/// final message = writer.writeMessage();
/// final size = writer.getSize(); // Returns 1
///
/// // Encode boolean values
/// final trueValue = writer.encodeValue(true);   // Returns 1
/// final falseValue = writer.encodeValue(false); // Returns 0
/// ```
class BooleanDatatypeWriter extends DatatypeWriter {
  final Endian _endian;

  /// Create a writer for boolean datatype
  ///
  /// Parameters:
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final writer = BooleanDatatypeWriter();
  /// final message = writer.writeMessage();
  /// ```
  BooleanDatatypeWriter({Endian endian = Endian.little}) : _endian = endian;

  @override
  Hdf5DatatypeClass get datatypeClass => Hdf5DatatypeClass.enumType;

  @override
  int getSize() => 1; // 8-bit enum

  @override
  Endian get endian => _endian;

  @override
  List<int> writeMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=8 (enum), version=1
    final classAndVersion = (1 << 4) | 8; // version 1, class 8
    writer.writeUint8(classAndVersion);

    // Class bit field 1: number of members (low byte) = 2
    writer.writeUint8(2);

    // Class bit field 2: number of members (high byte) = 0
    writer.writeUint8(0);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes (1 byte for boolean stored as uint8)
    writer.writeUint32(1);

    // Write base datatype (uint8)
    // This is an integer datatype message embedded within the enum message
    final baseTypeWriter = NumericDatatypeWriter.uint8(endian: _endian);
    final baseTypeMessage = baseTypeWriter.writeMessage();
    writer.writeBytes(baseTypeMessage);

    // Write enum members
    // Member 1: FALSE = 0
    _writeMember(writer, 'FALSE', 0);

    // Member 2: TRUE = 1
    _writeMember(writer, 'TRUE', 1);

    return writer.bytes;
  }

  /// Write an enum member (name and value)
  void _writeMember(ByteWriter writer, String name, int value) {
    // Write member name as null-terminated string
    final nameBytes = name.codeUnits;
    writer.writeBytes(nameBytes);
    writer.writeUint8(0); // Null terminator

    // Align to base type size (1 byte for uint8)
    // For version 1, we need to align to the base type size
    final nameLength = nameBytes.length + 1; // +1 for null terminator
    final padding = (1 - (nameLength % 1)) % 1; // Always 0 for 1-byte alignment
    if (padding > 0) {
      for (int i = 0; i < padding; i++) {
        writer.writeUint8(0);
      }
    }

    // Write value (1 byte for uint8)
    writer.writeUint8(value);
  }

  /// Encode a boolean value to its integer representation
  ///
  /// Parameters:
  /// - [value]: The boolean value to encode
  ///
  /// Returns 0 for false, 1 for true.
  ///
  /// Example:
  /// ```dart
  /// final writer = BooleanDatatypeWriter();
  /// final encoded = writer.encodeValue(true); // Returns 1
  /// ```
  int encodeValue(bool value) {
    return value ? 1 : 0;
  }

  /// Decode an integer value to boolean
  ///
  /// Parameters:
  /// - [value]: The integer value to decode (0 or 1)
  ///
  /// Returns false for 0, true for any non-zero value.
  ///
  /// Example:
  /// ```dart
  /// final writer = BooleanDatatypeWriter();
  /// final decoded = writer.decodeValue(1); // Returns true
  /// ```
  bool decodeValue(int value) {
    return value != 0;
  }
}

/// Writer for compound HDF5 datatypes (structured data)
///
/// This class handles writing datatype messages for compound types,
/// which are similar to C structs or records with named fields.
/// Each field has a name, offset, and datatype.
///
/// The writer follows HDF5 datatype message format version 1 for compound class (6).
/// It supports:
/// - Multiple fields with different datatypes
/// - Nested compound types
/// - Automatic offset calculation
/// - Proper field alignment
///
/// Example usage:
/// ```dart
/// // Create a compound writer with explicit fields
/// final writer = CompoundDatatypeWriter.fromFields({
///   'x': NumericDatatypeWriter.float64(),
///   'y': NumericDatatypeWriter.float64(),
///   'name': StringDatatypeWriter.fixedLength(length: 20),
/// });
///
/// // Create from a map of sample data
/// final writer2 = CompoundDatatypeWriter.fromMap({
///   'id': 42,
///   'value': 3.14,
///   'label': 'test',
/// });
///
/// final message = writer.writeMessage();
/// final size = writer.getSize(); // Returns total size of compound
/// ```
class CompoundDatatypeWriter extends DatatypeWriter {
  final Map<String, DatatypeWriter> _fields;
  final Map<String, int> _offsets;
  final int _totalSize;
  final Endian _endian;

  CompoundDatatypeWriter._({
    required Map<String, DatatypeWriter> fields,
    required Map<String, int> offsets,
    required int totalSize,
    required Endian endian,
  })  : _fields = fields,
        _offsets = offsets,
        _totalSize = totalSize,
        _endian = endian;

  /// Create a compound writer from a map of field names to datatype writers
  ///
  /// This factory calculates field offsets automatically based on field sizes
  /// and proper alignment requirements.
  ///
  /// Parameters:
  /// - [fields]: Map of field names to their datatype writers
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final writer = CompoundDatatypeWriter.fromFields({
  ///   'x': NumericDatatypeWriter.float64(),
  ///   'y': NumericDatatypeWriter.float64(),
  ///   'id': NumericDatatypeWriter.int32(),
  /// });
  /// ```
  factory CompoundDatatypeWriter.fromFields(
    Map<String, DatatypeWriter> fields, {
    Endian endian = Endian.little,
  }) {
    if (fields.isEmpty) {
      throw ArgumentError('Compound datatype must have at least one field');
    }

    // Calculate offsets and total size
    final offsets = <String, int>{};
    int currentOffset = 0;

    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final fieldWriter = entry.value;
      final fieldSize = fieldWriter.getSize();

      // Align to field size (simple alignment: align to size or 8, whichever is smaller)
      final alignment = fieldSize > 0 && fieldSize < 8 ? fieldSize : 8;
      final padding = (alignment - (currentOffset % alignment)) % alignment;
      currentOffset += padding;

      // Store offset for this field
      offsets[fieldName] = currentOffset;

      // Move to next field
      currentOffset += fieldSize;
    }

    final totalSize = currentOffset;

    return CompoundDatatypeWriter._(
      fields: fields,
      offsets: offsets,
      totalSize: totalSize,
      endian: endian,
    );
  }

  /// Create a compound writer from a map of sample data
  ///
  /// This factory auto-detects datatypes from the provided data values
  /// and creates appropriate field writers.
  ///
  /// Parameters:
  /// - [data]: Map of field names to sample values
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final writer = CompoundDatatypeWriter.fromMap({
  ///   'id': 42,
  ///   'value': 3.14,
  ///   'label': 'test',
  /// });
  /// ```
  factory CompoundDatatypeWriter.fromMap(
    Map<String, dynamic> data, {
    Endian? endian,
  }) {
    final fields = <String, DatatypeWriter>{};

    for (final entry in data.entries) {
      final fieldName = entry.key;
      final fieldValue = entry.value;

      // Create writer for this field based on value type
      fields[fieldName] = DatatypeWriterFactory.create(
        fieldValue,
        endian: endian,
      );
    }

    return CompoundDatatypeWriter.fromFields(fields,
        endian: endian ?? Endian.little);
  }

  @override
  Hdf5DatatypeClass get datatypeClass => Hdf5DatatypeClass.compound;

  @override
  int getSize() => _totalSize;

  @override
  Endian get endian => _endian;

  /// Get the field names in order
  List<String> get fieldNames => _fields.keys.toList();

  /// Get the datatype writer for a specific field
  DatatypeWriter? getFieldWriter(String fieldName) => _fields[fieldName];

  /// Get the offset of a specific field
  int? getFieldOffset(String fieldName) => _offsets[fieldName];

  @override
  List<int> writeMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=6 (compound), version=1
    final classAndVersion = (1 << 4) | 6; // version 1, class 6
    writer.writeUint8(classAndVersion);

    // Class bit field 1: number of members (low byte)
    final numMembers = _fields.length;
    writer.writeUint8(numMembers & 0xFF);

    // Class bit field 2: number of members (high byte)
    writer.writeUint8((numMembers >> 8) & 0xFF);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes (total size of compound)
    writer.writeUint32(_totalSize);

    // Write each member (field)
    for (final fieldName in _fields.keys) {
      final fieldWriter = _fields[fieldName]!;
      final fieldOffset = _offsets[fieldName]!;

      _writeMember(writer, fieldName, fieldOffset, fieldWriter);
    }

    return writer.bytes;
  }

  /// Write a compound member (field)
  void _writeMember(
    ByteWriter writer,
    String name,
    int offset,
    DatatypeWriter fieldWriter,
  ) {
    // Write member name as null-terminated string
    final nameBytes = name.codeUnits;
    writer.writeBytes(nameBytes);
    writer.writeUint8(0); // Null terminator

    // Align to 8-byte boundary (HDF5 spec requirement for version 1)
    final nameLength = nameBytes.length + 1; // +1 for null terminator
    final padding = (8 - (nameLength % 8)) % 8;
    for (int i = 0; i < padding; i++) {
      writer.writeUint8(0);
    }

    // Write member byte offset (4 bytes in version 1)
    writer.writeUint32(offset);

    // Write member dimensionality (1 byte) - 0 for scalar
    writer.writeUint8(0);

    // Reserved bytes (3 bytes)
    writer.writeUint8(0);
    writer.writeUint8(0);
    writer.writeUint8(0);

    // Write member datatype message
    final fieldTypeMessage = fieldWriter.writeMessage();
    writer.writeBytes(fieldTypeMessage);
  }

  /// Encode a map of field values according to this compound datatype
  ///
  /// Parameters:
  /// - [values]: Map of field names to values
  ///
  /// Returns the encoded bytes ready to be written to the HDF5 file.
  ///
  /// Example:
  /// ```dart
  /// final writer = CompoundDatatypeWriter.fromFields({
  ///   'x': NumericDatatypeWriter.float64(),
  ///   'y': NumericDatatypeWriter.float64(),
  /// });
  /// final encoded = writer.encodeValues({'x': 1.0, 'y': 2.0});
  /// ```
  List<int> encodeValues(Map<String, dynamic> values) {
    final buffer = Uint8List(_totalSize);
    final byteData = ByteData.view(buffer.buffer);

    for (final fieldName in _fields.keys) {
      final fieldWriter = _fields[fieldName]!;
      final fieldOffset = _offsets[fieldName]!;
      final fieldValue = values[fieldName];

      if (fieldValue == null) {
        throw ArgumentError('Missing value for field: $fieldName');
      }

      // Encode field value based on its type
      if (fieldWriter is NumericDatatypeWriter) {
        _encodeNumericField(byteData, fieldOffset, fieldValue, fieldWriter);
      } else if (fieldWriter is StringDatatypeWriter) {
        _encodeStringField(buffer, fieldOffset, fieldValue, fieldWriter);
      } else if (fieldWriter is BooleanDatatypeWriter) {
        buffer[fieldOffset] = fieldWriter.encodeValue(fieldValue as bool);
      } else if (fieldWriter is CompoundDatatypeWriter) {
        // Nested compound
        final nestedBytes =
            fieldWriter.encodeValues(fieldValue as Map<String, dynamic>);
        buffer.setRange(
            fieldOffset, fieldOffset + nestedBytes.length, nestedBytes);
      }
    }

    return buffer;
  }

  /// Encode a numeric field value
  void _encodeNumericField(
    ByteData byteData,
    int offset,
    dynamic value,
    NumericDatatypeWriter writer,
  ) {
    final size = writer.getSize();
    final endian = writer.endian == Endian.little ? Endian.little : Endian.big;

    if (writer.datatypeClass == Hdf5DatatypeClass.float) {
      if (size == 4) {
        byteData.setFloat32(offset, (value as num).toDouble(), endian);
      } else if (size == 8) {
        byteData.setFloat64(offset, (value as num).toDouble(), endian);
      }
    } else if (writer.datatypeClass == Hdf5DatatypeClass.integer) {
      final intValue = (value as num).toInt();
      if (size == 1) {
        byteData.setInt8(offset, intValue);
      } else if (size == 2) {
        byteData.setInt16(offset, intValue, endian);
      } else if (size == 4) {
        byteData.setInt32(offset, intValue, endian);
      } else if (size == 8) {
        byteData.setInt64(offset, intValue, endian);
      }
    }
  }

  /// Encode a string field value
  void _encodeStringField(
    Uint8List buffer,
    int offset,
    dynamic value,
    StringDatatypeWriter writer,
  ) {
    final stringValue = value as String;
    final encodedBytes = writer.encodeString(stringValue);
    buffer.setRange(offset, offset + encodedBytes.length, encodedBytes);
  }
}

/// Writer for array HDF5 datatypes (fixed-size multidimensional arrays)
///
/// This class handles writing datatype messages for array types,
/// which represent fixed-size multidimensional arrays of a base type.
/// Arrays are different from datasets - they are used as fields within
/// compound types or as elements of other structures.
///
/// The writer follows HDF5 datatype message format version 2 for array class (10).
///
/// Example usage:
/// ```dart
/// // Create a 3x4 array of float64
/// final writer = ArrayDatatypeWriter(
///   baseType: NumericDatatypeWriter.float64(),
///   dimensions: [3, 4],
/// );
///
/// // Create a 1D array of int32
/// final writer2 = ArrayDatatypeWriter(
///   baseType: NumericDatatypeWriter.int32(),
///   dimensions: [10],
/// );
///
/// final message = writer.writeMessage();
/// final size = writer.getSize(); // Returns base_size * total_elements
/// ```
class ArrayDatatypeWriter extends DatatypeWriter {
  final DatatypeWriter _baseType;
  final List<int> _dimensions;
  final Endian _endian;

  /// Create a writer for array datatype
  ///
  /// Parameters:
  /// - [baseType]: The datatype writer for array elements
  /// - [dimensions]: List of dimension sizes (e.g., [3, 4] for 3x4 array)
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// // 2D array: 5 rows x 10 columns of float64
  /// final writer = ArrayDatatypeWriter(
  ///   baseType: NumericDatatypeWriter.float64(),
  ///   dimensions: [5, 10],
  /// );
  /// ```
  ArrayDatatypeWriter({
    required DatatypeWriter baseType,
    required List<int> dimensions,
    Endian endian = Endian.little,
  })  : _baseType = baseType,
        _dimensions = dimensions,
        _endian = endian {
    if (dimensions.isEmpty) {
      throw ArgumentError('Array must have at least one dimension');
    }
    if (dimensions.any((d) => d <= 0)) {
      throw ArgumentError('All dimensions must be positive');
    }
  }

  @override
  Hdf5DatatypeClass get datatypeClass => Hdf5DatatypeClass.array;

  @override
  int getSize() {
    // Total size is base type size * total number of elements
    final baseSize = _baseType.getSize();
    final totalElements = _dimensions.fold(1, (a, b) => a * b);
    return baseSize * totalElements;
  }

  @override
  Endian get endian => _endian;

  /// Get the base type writer
  DatatypeWriter get baseType => _baseType;

  /// Get the dimensions
  List<int> get dimensions => List.unmodifiable(_dimensions);

  /// Get total number of elements
  int get totalElements => _dimensions.fold(1, (a, b) => a * b);

  @override
  List<int> writeMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=10 (array), version=2
    final classAndVersion = (2 << 4) | 10; // version 2, class 10
    writer.writeUint8(classAndVersion);

    // Class bit field 1: reserved
    writer.writeUint8(0);

    // Class bit field 2: reserved
    writer.writeUint8(0);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes (total array size)
    writer.writeUint32(getSize());

    // Dimensionality (number of dimensions)
    writer.writeUint8(_dimensions.length);

    // Reserved (3 bytes)
    writer.writeUint8(0);
    writer.writeUint8(0);
    writer.writeUint8(0);

    // Dimension sizes (4 bytes each)
    for (final dim in _dimensions) {
      writer.writeUint32(dim);
    }

    // Write base datatype message
    final baseTypeMessage = _baseType.writeMessage();
    writer.writeBytes(baseTypeMessage);

    return writer.bytes;
  }
}

/// Writer for variable-length HDF5 datatypes
///
/// This class handles writing datatype messages for variable-length types,
/// which represent sequences of variable length. The actual data is stored
/// in the global heap with references in the dataset.
///
/// The writer follows HDF5 datatype message format version 1 for vlen class (9).
///
/// Example usage:
/// ```dart
/// // Create a variable-length sequence of int32
/// final writer = VlenDatatypeWriter(
///   baseType: NumericDatatypeWriter.int32(),
/// );
///
/// // Create a variable-length sequence of strings
/// final writer2 = VlenDatatypeWriter(
///   baseType: StringDatatypeWriter.fixedLength(length: 20),
/// );
///
/// final message = writer.writeMessage();
/// ```
class VlenDatatypeWriter extends DatatypeWriter {
  final DatatypeWriter _baseType;
  final VlenType _vlenType;
  final Endian _endian;

  /// Create a writer for variable-length datatype
  ///
  /// Parameters:
  /// - [baseType]: The datatype writer for sequence elements
  /// - [vlenType]: Type of variable-length data (sequence or string)
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final writer = VlenDatatypeWriter(
  ///   baseType: NumericDatatypeWriter.float64(),
  ///   vlenType: VlenType.sequence,
  /// );
  /// ```
  VlenDatatypeWriter({
    required DatatypeWriter baseType,
    VlenType vlenType = VlenType.sequence,
    Endian endian = Endian.little,
  })  : _baseType = baseType,
        _vlenType = vlenType,
        _endian = endian;

  @override
  Hdf5DatatypeClass get datatypeClass => Hdf5DatatypeClass.vlen;

  @override
  int getSize() {
    // Variable-length types use a fixed-size reference structure
    // In HDF5, this is typically 16 bytes (global heap ID)
    return 16;
  }

  @override
  Endian get endian => _endian;

  /// Get the base type writer
  DatatypeWriter get baseType => _baseType;

  /// Get the variable-length type
  VlenType get vlenType => _vlenType;

  @override
  List<int> writeMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=9 (vlen), version=1
    final classAndVersion = (1 << 4) | 9; // version 1, class 9
    writer.writeUint8(classAndVersion);

    // Class bit field 1: type (0=sequence, 1=string)
    final typeBits = _vlenType == VlenType.sequence ? 0 : 1;
    writer.writeUint8(typeBits);

    // Class bit field 2: padding type (for strings)
    writer.writeUint8(0);

    // Class bit field 3: character set (for strings)
    writer.writeUint8(0);

    // Size in bytes (16 bytes for global heap reference)
    writer.writeUint32(16);

    // Write base datatype message
    final baseTypeMessage = _baseType.writeMessage();
    writer.writeBytes(baseTypeMessage);

    return writer.bytes;
  }
}

/// Variable-length type enumeration
enum VlenType {
  sequence, // Variable-length sequence
  string, // Variable-length string
}

/// Writer for enumeration HDF5 datatypes (general enumerations)
///
/// This class handles writing datatype messages for enumeration types,
/// which map named values to integers. This is a general implementation
/// that allows custom enumerations beyond just boolean.
///
/// The writer follows HDF5 datatype message format version 1 for enum class (8).
///
/// Example usage:
/// ```dart
/// // Create a status enumeration
/// final writer = EnumDatatypeWriter(
///   baseType: NumericDatatypeWriter.uint8(),
///   members: {
///     'PENDING': 0,
///     'ACTIVE': 1,
///     'COMPLETE': 2,
///     'FAILED': 3,
///   },
/// );
///
/// final message = writer.writeMessage();
/// final size = writer.getSize(); // Returns base type size (1 byte)
/// ```
class EnumDatatypeWriter extends DatatypeWriter {
  final NumericDatatypeWriter _baseType;
  final Map<String, int> _members;
  final Endian _endian;

  /// Create a writer for enumeration datatype
  ///
  /// Parameters:
  /// - [baseType]: The integer datatype for enum values (must be integer type)
  /// - [members]: Map of member names to their integer values
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final writer = EnumDatatypeWriter(
  ///   baseType: NumericDatatypeWriter.int32(),
  ///   members: {
  ///     'RED': 0,
  ///     'GREEN': 1,
  ///     'BLUE': 2,
  ///   },
  /// );
  /// ```
  EnumDatatypeWriter({
    required NumericDatatypeWriter baseType,
    required Map<String, int> members,
    Endian? endian,
  })  : _baseType = baseType,
        _members = members,
        _endian = endian ?? baseType.endian {
    if (members.isEmpty) {
      throw ArgumentError('Enumeration must have at least one member');
    }
    if (baseType.datatypeClass != Hdf5DatatypeClass.integer) {
      throw ArgumentError('Enum base type must be an integer type');
    }
  }

  @override
  Hdf5DatatypeClass get datatypeClass => Hdf5DatatypeClass.enumType;

  @override
  int getSize() => _baseType.getSize();

  @override
  Endian get endian => _endian;

  /// Get the base type writer
  NumericDatatypeWriter get baseType => _baseType;

  /// Get the enum members
  Map<String, int> get members => Map.unmodifiable(_members);

  @override
  List<int> writeMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=8 (enum), version=1
    final classAndVersion = (1 << 4) | 8; // version 1, class 8
    writer.writeUint8(classAndVersion);

    // Class bit field 1: number of members (low byte)
    final numMembers = _members.length;
    writer.writeUint8(numMembers & 0xFF);

    // Class bit field 2: number of members (high byte)
    writer.writeUint8((numMembers >> 8) & 0xFF);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes (base type size)
    writer.writeUint32(_baseType.getSize());

    // Write base datatype (integer type)
    final baseTypeMessage = _baseType.writeMessage();
    writer.writeBytes(baseTypeMessage);

    // Write enum members
    for (final entry in _members.entries) {
      _writeMember(writer, entry.key, entry.value);
    }

    return writer.bytes;
  }

  /// Write an enum member (name and value)
  void _writeMember(ByteWriter writer, String name, int value) {
    // Write member name as null-terminated string
    final nameBytes = name.codeUnits;
    writer.writeBytes(nameBytes);
    writer.writeUint8(0); // Null terminator

    // Align to base type size
    final nameLength = nameBytes.length + 1; // +1 for null terminator
    final baseSize = _baseType.getSize();
    final padding = (baseSize - (nameLength % baseSize)) % baseSize;
    for (int i = 0; i < padding; i++) {
      writer.writeUint8(0);
    }

    // Write value based on base type size
    switch (baseSize) {
      case 1:
        writer.writeUint8(value);
        break;
      case 2:
        writer.writeUint16(value);
        break;
      case 4:
        writer.writeUint32(value);
        break;
      case 8:
        writer.writeUint64(value);
        break;
      default:
        throw UnsupportedError('Unsupported enum base type size: $baseSize');
    }
  }

  /// Encode a string value to its integer representation
  ///
  /// Parameters:
  /// - [name]: The member name to encode
  ///
  /// Returns the integer value for the member.
  /// Throws [ArgumentError] if the name is not a valid member.
  ///
  /// Example:
  /// ```dart
  /// final writer = EnumDatatypeWriter(
  ///   baseType: NumericDatatypeWriter.uint8(),
  ///   members: {'RED': 0, 'GREEN': 1, 'BLUE': 2},
  /// );
  /// final encoded = writer.encodeValue('GREEN'); // Returns 1
  /// ```
  int encodeValue(String name) {
    if (!_members.containsKey(name)) {
      throw ArgumentError('Unknown enum member: $name');
    }
    return _members[name]!;
  }

  /// Decode an integer value to its string representation
  ///
  /// Parameters:
  /// - [value]: The integer value to decode
  ///
  /// Returns the member name for the value.
  /// Throws [ArgumentError] if the value is not a valid member.
  ///
  /// Example:
  /// ```dart
  /// final writer = EnumDatatypeWriter(
  ///   baseType: NumericDatatypeWriter.uint8(),
  ///   members: {'RED': 0, 'GREEN': 1, 'BLUE': 2},
  /// );
  /// final decoded = writer.decodeValue(1); // Returns 'GREEN'
  /// ```
  String decodeValue(int value) {
    for (final entry in _members.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    throw ArgumentError('Unknown enum value: $value');
  }
}

/// Writer for reference HDF5 datatypes
///
/// This class handles writing datatype messages for reference types,
/// which store references (pointers) to other HDF5 objects or dataset regions.
///
/// The writer follows HDF5 datatype message format version 1 for reference class (7).
///
/// Example usage:
/// ```dart
/// // Create an object reference writer
/// final writer = ReferenceDatatypeWriter(
///   referenceType: ReferenceType.object,
/// );
///
/// // Create a region reference writer
/// final writer2 = ReferenceDatatypeWriter(
///   referenceType: ReferenceType.region,
/// );
///
/// final message = writer.writeMessage();
/// ```
class ReferenceDatatypeWriter extends DatatypeWriter {
  final ReferenceType _referenceType;
  final Endian _endian;

  /// Create a writer for reference datatype
  ///
  /// Parameters:
  /// - [referenceType]: Type of reference (object or region)
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final writer = ReferenceDatatypeWriter(
  ///   referenceType: ReferenceType.object,
  /// );
  /// ```
  ReferenceDatatypeWriter({
    required ReferenceType referenceType,
    Endian endian = Endian.little,
  })  : _referenceType = referenceType,
        _endian = endian;

  @override
  Hdf5DatatypeClass get datatypeClass => Hdf5DatatypeClass.reference;

  @override
  int getSize() {
    // Object references are 8 bytes (address in file)
    // Region references are larger (address + region info)
    return _referenceType == ReferenceType.object ? 8 : 12;
  }

  @override
  Endian get endian => _endian;

  /// Get the reference type
  ReferenceType get referenceType => _referenceType;

  @override
  List<int> writeMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=7 (reference), version=1
    final classAndVersion = (1 << 4) | 7; // version 1, class 7
    writer.writeUint8(classAndVersion);

    // Class bit field 1: reference type (0=object, 1=region)
    final typeBits = _referenceType == ReferenceType.object ? 0 : 1;
    writer.writeUint8(typeBits);

    // Class bit field 2: reserved
    writer.writeUint8(0);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes
    writer.writeUint32(getSize());

    return writer.bytes;
  }
}

/// Writer for opaque HDF5 datatypes
///
/// This class handles writing datatype messages for opaque types,
/// which represent uninterpreted binary data with an optional tag.
/// Opaque types are used when HDF5 doesn't need to understand the data structure.
///
/// The writer follows HDF5 datatype message format version 1 for opaque class (5).
///
/// Example usage:
/// ```dart
/// // Create an opaque writer with a tag
/// final writer = OpaqueDatatypeWriter(
///   size: 128,
///   tag: 'JPEG_IMAGE',
/// );
///
/// // Create an opaque writer without a tag
/// final writer2 = OpaqueDatatypeWriter(
///   size: 64,
/// );
///
/// final message = writer.writeMessage();
/// ```
class OpaqueDatatypeWriter extends DatatypeWriter {
  final int _size;
  final String? _tag;
  final Endian _endian;

  /// Create a writer for opaque datatype
  ///
  /// Parameters:
  /// - [size]: Size of the opaque data in bytes
  /// - [tag]: Optional ASCII tag describing the data (max 255 characters)
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final writer = OpaqueDatatypeWriter(
  ///   size: 256,
  ///   tag: 'CUSTOM_BINARY_FORMAT',
  /// );
  /// ```
  OpaqueDatatypeWriter({
    required int size,
    String? tag,
    Endian endian = Endian.little,
  })  : _size = size,
        _tag = tag,
        _endian = endian {
    if (size <= 0) {
      throw ArgumentError('Opaque size must be positive');
    }
    if (tag != null && tag.length > 255) {
      throw ArgumentError('Opaque tag must be 255 characters or less');
    }
  }

  @override
  Hdf5DatatypeClass get datatypeClass => Hdf5DatatypeClass.opaque;

  @override
  int getSize() => _size;

  @override
  Endian get endian => _endian;

  /// Get the tag
  String? get tag => _tag;

  @override
  List<int> writeMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=5 (opaque), version=1
    final classAndVersion = (1 << 4) | 5; // version 1, class 5
    writer.writeUint8(classAndVersion);

    // Class bit field 1: tag length (0 if no tag)
    final tagLength = _tag?.length ?? 0;
    writer.writeUint8(tagLength);

    // Class bit field 2: reserved
    writer.writeUint8(0);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes
    writer.writeUint32(_size);

    // Write tag if present
    if (_tag != null) {
      final tagBytes = _tag.codeUnits;
      writer.writeBytes(tagBytes);
    }

    return writer.bytes;
  }
}

/// Writer for bitfield HDF5 datatypes
///
/// This class handles writing datatype messages for bitfield types,
/// which represent bit-level data storage. Bitfields are used for
/// packed bit flags and other bit-oriented data.
///
/// The writer follows HDF5 datatype message format version 1 for bitfield class (4).
///
/// Example usage:
/// ```dart
/// // Create an 8-bit bitfield
/// final writer = BitfieldDatatypeWriter(
///   size: 1,
/// );
///
/// // Create a 32-bit bitfield
/// final writer2 = BitfieldDatatypeWriter(
///   size: 4,
/// );
///
/// final message = writer.writeMessage();
/// ```
class BitfieldDatatypeWriter extends DatatypeWriter {
  final int _size;
  final Endian _endian;

  /// Create a writer for bitfield datatype
  ///
  /// Parameters:
  /// - [size]: Size of the bitfield in bytes (1, 2, 4, or 8)
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final writer = BitfieldDatatypeWriter(
  ///   size: 2, // 16-bit bitfield
  /// );
  /// ```
  BitfieldDatatypeWriter({
    required int size,
    Endian endian = Endian.little,
  })  : _size = size,
        _endian = endian {
    if (![1, 2, 4, 8].contains(size)) {
      throw ArgumentError('Bitfield size must be 1, 2, 4, or 8 bytes');
    }
  }

  @override
  Hdf5DatatypeClass get datatypeClass => Hdf5DatatypeClass.bitfield;

  @override
  int getSize() => _size;

  @override
  Endian get endian => _endian;

  @override
  List<int> writeMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=4 (bitfield), version=1
    final classAndVersion = (1 << 4) | 4; // version 1, class 4
    writer.writeUint8(classAndVersion);

    // Class bit field 1: byte order
    // Bit 0: 0=little-endian, 1=big-endian
    final byteOrderBit = _endian == Endian.little ? 0 : 1;
    writer.writeUint8(byteOrderBit);

    // Class bit field 2: reserved
    writer.writeUint8(0);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes
    writer.writeUint32(_size);

    // Bit offset (always 0 for standard bitfields)
    writer.writeUint16(0);

    // Bit precision (size * 8 bits)
    writer.writeUint16(_size * 8);

    return writer.bytes;
  }
}

/// Writer for time HDF5 datatypes
///
/// This class handles writing datatype messages for time types,
/// which represent date/time values. Time datatypes are less commonly
/// used in modern HDF5 files.
///
/// The writer follows HDF5 datatype message format version 1 for time class (2).
///
/// Example usage:
/// ```dart
/// // Create a time writer (typically 8 bytes)
/// final writer = TimeDatatypeWriter(
///   size: 8,
/// );
///
/// final message = writer.writeMessage();
/// ```
class TimeDatatypeWriter extends DatatypeWriter {
  final int _size;
  final Endian _endian;

  /// Create a writer for time datatype
  ///
  /// Parameters:
  /// - [size]: Size of the time value in bytes (typically 4 or 8)
  /// - [endian]: Byte order (default: little-endian)
  ///
  /// Example:
  /// ```dart
  /// final writer = TimeDatatypeWriter(
  ///   size: 8, // 64-bit time value
  /// );
  /// ```
  TimeDatatypeWriter({
    required int size,
    Endian endian = Endian.little,
  })  : _size = size,
        _endian = endian {
    if (size <= 0) {
      throw ArgumentError('Time size must be positive');
    }
  }

  @override
  Hdf5DatatypeClass get datatypeClass => Hdf5DatatypeClass.time;

  @override
  int getSize() => _size;

  @override
  Endian get endian => _endian;

  @override
  List<int> writeMessage() {
    final writer = ByteWriter(endian: _endian);

    // Class and version: class=2 (time), version=1
    final classAndVersion = (1 << 4) | 2; // version 1, class 2
    writer.writeUint8(classAndVersion);

    // Class bit field 1: byte order
    // Bit 0: 0=little-endian, 1=big-endian
    final byteOrderBit = _endian == Endian.little ? 0 : 1;
    writer.writeUint8(byteOrderBit);

    // Class bit field 2: reserved
    writer.writeUint8(0);

    // Class bit field 3: reserved
    writer.writeUint8(0);

    // Size in bytes
    writer.writeUint32(_size);

    // Bit precision (size * 8 bits)
    writer.writeUint16(_size * 8);

    return writer.bytes;
  }
}
