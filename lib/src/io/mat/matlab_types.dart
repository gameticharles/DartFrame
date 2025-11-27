// MATLAB type definitions - no HDF5 imports needed

/// MATLAB data class types as stored in HDF5 attributes
enum MatlabClass {
  /// Double-precision floating point (64-bit)
  double,

  /// Single-precision floating point (32-bit)
  single,

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

  /// Character array (string)
  char,

  /// String array (variable-length)
  string,

  /// Logical (boolean) array
  logical,

  /// Cell array
  cell,

  /// Structure
  struct,

  /// Function handle (not fully supported)
  functionHandle,

  /// Object (MATLAB class instance, limited support)
  object,

  /// Sparse matrix
  sparse,

  /// Unknown/unsupported type
  unknown;

  /// Parse MATLAB class from string attribute value
  static MatlabClass fromString(String value) {
    switch (value.toLowerCase()) {
      case 'double':
        return MatlabClass.double;
      case 'single':
        return MatlabClass.single;
      case 'int8':
        return MatlabClass.int8;
      case 'uint8':
        return MatlabClass.uint8;
      case 'int16':
        return MatlabClass.int16;
      case 'uint16':
        return MatlabClass.uint16;
      case 'int32':
        return MatlabClass.int32;
      case 'uint32':
        return MatlabClass.uint32;
      case 'int64':
        return MatlabClass.int64;
      case 'uint64':
        return MatlabClass.uint64;
      case 'char':
        return MatlabClass.char;
      case 'string':
        return MatlabClass.string;
      case 'logical':
        return MatlabClass.logical;
      case 'cell':
        return MatlabClass.cell;
      case 'struct':
        return MatlabClass.struct;
      case 'function_handle':
        return MatlabClass.functionHandle;
      case 'sparse':
        return MatlabClass.sparse;
      default:
        return MatlabClass.unknown;
    }
  }

  /// Convert to MATLAB class string (for writing)
  String toMatlabString() {
    switch (this) {
      case MatlabClass.double:
        return 'double';
      case MatlabClass.single:
        return 'single';
      case MatlabClass.int8:
        return 'int8';
      case MatlabClass.uint8:
        return 'uint8';
      case MatlabClass.int16:
        return 'int16';
      case MatlabClass.uint16:
        return 'uint16';
      case MatlabClass.int32:
        return 'int32';
      case MatlabClass.uint32:
        return 'uint32';
      case MatlabClass.int64:
        return 'int64';
      case MatlabClass.uint64:
        return 'uint64';
      case MatlabClass.char:
        return 'char';
      case MatlabClass.string:
        return 'string';
      case MatlabClass.logical:
        return 'logical';
      case MatlabClass.cell:
        return 'cell';
      case MatlabClass.struct:
        return 'struct';
      case MatlabClass.functionHandle:
        return 'function_handle';
      case MatlabClass.sparse:
        return 'sparse';
      default:
        return 'unknown';
    }
  }

  /// Check if this is a numeric type
  bool get isNumeric =>
      this == MatlabClass.double ||
      this == MatlabClass.single ||
      this == MatlabClass.int8 ||
      this == MatlabClass.uint8 ||
      this == MatlabClass.int16 ||
      this == MatlabClass.uint16 ||
      this == MatlabClass.int32 ||
      this == MatlabClass.uint32 ||
      this == MatlabClass.int64 ||
      this == MatlabClass.uint64;

  /// Check if this is a string/character type
  bool get isString => this == MatlabClass.char || this == MatlabClass.string;

  /// Check if this is a complex structure type
  bool get isComplex => this == MatlabClass.cell || this == MatlabClass.struct;
}

/// MATLAB attribute name constants
class MatlabAttributes {
  /// MATLAB class type attribute
  static const String matlabClass = 'MATLAB_class';

  /// Structure field names attribute
  static const String matlabFields = 'MATLAB_fields';

  /// Sparse matrix indicator attribute
  static const String matlabSparse = 'MATLAB_sparse';

  /// Global variable flag attribute
  static const String matlabGlobal = 'MATLAB_global';

  /// Integer decode information
  static const String matlabIntDecode = 'MATLAB_int_decode';

  /// Empty array indicator
  static const String matlabEmpty = 'MATLAB_empty';

  /// Object classname (for MATLAB objects)
  static const String className = 'CLASSNAME';

  /// Internal reference path
  static const String h5Path = 'H5PATH';
}

/// MATLAB special dataset/group names
class MatlabSpecialNames {
  /// Object references group
  static const String refs = '#refs#';

  /// Subsystem group (optional)
  static const String subsystem = '#subsystem#';

  /// Reference object name prefix
  static const String refsPrefix = '#Refs#';

  /// Check if a name is a special MATLAB internal name
  static bool isSpecialName(String name) {
    return name.startsWith('#');
  }

  /// Check if a name is the refs group
  static bool isRefsGroup(String name) {
    return name == refs;
  }

  /// Generate a reference object name
  static String generateRefName(int index) {
    return '$refsPrefix${index.toString().padLeft(4, '0')}';
  }
}

/// Maps MATLAB types to Dart types
class MatlabTypeMappings {
  /// Get expected Dart type for a MATLAB class
  static Type getDartType(MatlabClass matlabClass) {
    switch (matlabClass) {
      case MatlabClass.double:
      case MatlabClass.single:
        return double;

      case MatlabClass.int8:
      case MatlabClass.int16:
      case MatlabClass.int32:
      case MatlabClass.int64:
      case MatlabClass.uint8:
      case MatlabClass.uint16:
      case MatlabClass.uint32:
      case MatlabClass.uint64:
        return int;

      case MatlabClass.logical:
        return bool;

      case MatlabClass.char:
      case MatlabClass.string:
        return String;

      case MatlabClass.cell:
        return List;

      case MatlabClass.struct:
        return Map;

      default:
        return dynamic;
    }
  }

  /// Get description of MATLAB type
  static String getDescription(MatlabClass matlabClass) {
    switch (matlabClass) {
      case MatlabClass.double:
        return 'Double-precision floating point (64-bit)';
      case MatlabClass.single:
        return 'Single-precision floating point (32-bit)';
      case MatlabClass.int8:
        return '8-bit signed integer';
      case MatlabClass.uint8:
        return '8-bit unsigned integer';
      case MatlabClass.int16:
        return '16-bit signed integer';
      case MatlabClass.uint16:
        return '16-bit unsigned integer';
      case MatlabClass.int32:
        return '32-bit signed integer';
      case MatlabClass.uint32:
        return '32-bit unsigned integer';
      case MatlabClass.int64:
        return '64-bit signed integer';
      case MatlabClass.uint64:
        return '64-bit unsigned integer';
      case MatlabClass.char:
        return 'Character array (string)';
      case MatlabClass.string:
        return 'String array (variable-length)';
      case MatlabClass.logical:
        return 'Logical (boolean) array';
      case MatlabClass.cell:
        return 'Cell array (heterogeneous)';
      case MatlabClass.struct:
        return 'Structure (named fields)';
      case MatlabClass.functionHandle:
        return 'Function handle (not supported)';
      case MatlabClass.object:
        return 'MATLAB object (limited support)';
      case MatlabClass.sparse:
        return 'Sparse matrix';
      default:
        return 'Unknown type';
    }
  }
}

/// Information about a MATLAB variable
class MatlabVariableInfo {
  /// Variable name
  final String name;

  /// MATLAB class type
  final MatlabClass matlabClass;

  /// Shape/dimensions
  final List<int> shape;

  /// Whether it's sparse
  final bool isSparse;

  /// Whether it's global
  final bool isGlobal;

  /// Whether it's empty
  final bool isEmpty;

  /// Structure field names (if struct)
  final List<String>? fields;

  /// Class name (if object)
  final String? className;

  MatlabVariableInfo({
    required this.name,
    required this.matlabClass,
    required this.shape,
    this.isSparse = false,
    this.isGlobal = false,
    this.isEmpty = false,
    this.fields,
    this.className,
  });

  /// Get size (total number of elements)
  int get size => shape.fold(1, (a, b) => a * b);

  /// Get number of dimensions
  int get ndim => shape.length;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('MatlabVariable("$name", ');
    buffer.write('class=${matlabClass.toMatlabString()}, ');
    buffer.write('shape=${shape.toString()}');
    if (isSparse) buffer.write(', sparse');
    if (isGlobal) buffer.write(', global');
    if (isEmpty) buffer.write(', empty');
    if (fields != null) buffer.write(', fields=$fields');
    if (className != null) buffer.write(', class=$className');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Exception for unsupported MATLAB types
class UnsupportedMatlabTypeError extends Error {
  final MatlabClass matlabClass;
  final String? message;

  UnsupportedMatlabTypeError(this.matlabClass, [this.message]);

  @override
  String toString() {
    final msg = message ?? 'MATLAB type not supported';
    return 'UnsupportedMatlabTypeError: ${matlabClass.toMatlabString()} - $msg';
  }
}

/// Exception for MATLAB file format errors
class MatlabFileFormatError extends Error {
  final String message;

  MatlabFileFormatError(this.message);

  @override
  String toString() => 'MatlabFileFormatError: $message';
}
