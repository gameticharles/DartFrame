/// Data type system for DartFrame.
///
/// Provides nullable types, extension types, and custom dtype registration.
library;

/// Base class for all DartFrame data types.
abstract class DType {
  /// Name of the data type.
  String get name;

  /// Whether this type is nullable.
  bool get nullable;

  /// Size in bytes (null for variable-size types).
  int? get itemSize;

  /// Dart type that this DType represents.
  Type get dartType;

  /// Convert a value to this type.
  dynamic convert(dynamic value);

  /// Check if a value is valid for this type.
  bool isValid(dynamic value);

  /// Check if a value is null/missing.
  bool isNull(dynamic value);

  /// Get the null/missing value for this type.
  dynamic get nullValue;

  /// String representation.
  @override
  String toString() => name;

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      other is DType && other.name == name && other.nullable == nullable;

  @override
  int get hashCode => Object.hash(name, nullable);
}

/// Nullable integer types.
class Int8DType extends DType {
  final bool _nullable;

  Int8DType({bool nullable = true}) : _nullable = nullable;

  @override
  String get name => _nullable ? 'Int8' : 'int8';

  @override
  bool get nullable => _nullable;

  @override
  int get itemSize => 1;

  @override
  Type get dartType => int;

  @override
  dynamic convert(dynamic value) {
    if (value == null) {
      if (!_nullable) {
        throw ArgumentError('Cannot convert null to non-nullable Int8');
      }
      return null;
    }
    if (value is int) {
      if (value < -128 || value > 127) {
        throw RangeError('Value $value out of range for Int8 (-128 to 127)');
      }
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        throw FormatException('Cannot parse "$value" as Int8');
      }
      return convert(parsed);
    }
    if (value is double) return convert(value.toInt());
    throw ArgumentError('Cannot convert ${value.runtimeType} to Int8');
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return _nullable;
    if (value is! int) return false;
    return value >= -128 && value <= 127;
  }

  @override
  bool isNull(dynamic value) => value == null;

  @override
  dynamic get nullValue => null;
}

class Int16DType extends DType {
  final bool _nullable;

  Int16DType({bool nullable = true}) : _nullable = nullable;

  @override
  String get name => _nullable ? 'Int16' : 'int16';

  @override
  bool get nullable => _nullable;

  @override
  int get itemSize => 2;

  @override
  Type get dartType => int;

  @override
  dynamic convert(dynamic value) {
    if (value == null) {
      if (!_nullable) {
        throw ArgumentError('Cannot convert null to non-nullable Int16');
      }
      return null;
    }
    if (value is int) {
      if (value < -32768 || value > 32767) {
        throw RangeError(
            'Value $value out of range for Int16 (-32768 to 32767)');
      }
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        throw FormatException('Cannot parse "$value" as Int16');
      }
      return convert(parsed);
    }
    if (value is double) return convert(value.toInt());
    throw ArgumentError('Cannot convert ${value.runtimeType} to Int16');
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return _nullable;
    if (value is! int) return false;
    return value >= -32768 && value <= 32767;
  }

  @override
  bool isNull(dynamic value) => value == null;

  @override
  dynamic get nullValue => null;
}

class Int32DType extends DType {
  final bool _nullable;

  Int32DType({bool nullable = true}) : _nullable = nullable;

  @override
  String get name => _nullable ? 'Int32' : 'int32';

  @override
  bool get nullable => _nullable;

  @override
  int get itemSize => 4;

  @override
  Type get dartType => int;

  @override
  dynamic convert(dynamic value) {
    if (value == null) {
      if (!_nullable) {
        throw ArgumentError('Cannot convert null to non-nullable Int32');
      }
      return null;
    }
    if (value is int) {
      if (value < -2147483648 || value > 2147483647) {
        throw RangeError('Value $value out of range for Int32');
      }
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        throw FormatException('Cannot parse "$value" as Int32');
      }
      return convert(parsed);
    }
    if (value is double) return convert(value.toInt());
    throw ArgumentError('Cannot convert ${value.runtimeType} to Int32');
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return _nullable;
    if (value is! int) return false;
    return value >= -2147483648 && value <= 2147483647;
  }

  @override
  bool isNull(dynamic value) => value == null;

  @override
  dynamic get nullValue => null;
}

class Int64DType extends DType {
  final bool _nullable;

  Int64DType({bool nullable = true}) : _nullable = nullable;

  @override
  String get name => _nullable ? 'Int64' : 'int64';

  @override
  bool get nullable => _nullable;

  @override
  int get itemSize => 8;

  @override
  Type get dartType => int;

  @override
  dynamic convert(dynamic value) {
    if (value == null) {
      if (!_nullable) {
        throw ArgumentError('Cannot convert null to non-nullable Int64');
      }
      return null;
    }
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        throw FormatException('Cannot parse "$value" as Int64');
      }
      return parsed;
    }
    if (value is double) return value.toInt();
    throw ArgumentError('Cannot convert ${value.runtimeType} to Int64');
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return _nullable;
    return value is int;
  }

  @override
  bool isNull(dynamic value) => value == null;

  @override
  dynamic get nullValue => null;
}

/// Nullable boolean type.
class BooleanDType extends DType {
  final bool _nullable;

  BooleanDType({bool nullable = true}) : _nullable = nullable;

  @override
  String get name => _nullable ? 'Boolean' : 'boolean';

  @override
  bool get nullable => _nullable;

  @override
  int get itemSize => 1;

  @override
  Type get dartType => bool;

  @override
  dynamic convert(dynamic value) {
    if (value == null) {
      if (!_nullable) {
        throw ArgumentError('Cannot convert null to non-nullable Boolean');
      }
      return null;
    }
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 't') {
        return true;
      }
      if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'f') {
        return false;
      }
      if (_nullable && (lower == '' || lower == 'null' || lower == 'na')) {
        return null;
      }
      throw FormatException('Cannot parse "$value" as Boolean');
    }
    throw ArgumentError('Cannot convert ${value.runtimeType} to Boolean');
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return _nullable;
    return value is bool;
  }

  @override
  bool isNull(dynamic value) => value == null;

  @override
  dynamic get nullValue => null;
}

/// Nullable string type.
class StringDType extends DType {
  final bool _nullable;
  final int? _maxLength;

  StringDType({bool nullable = true, int? maxLength})
      : _nullable = nullable,
        _maxLength = maxLength;

  @override
  String get name {
    if (_maxLength != null) {
      return _nullable ? 'String($_maxLength)' : 'string($_maxLength)';
    }
    return _nullable ? 'String' : 'string';
  }

  @override
  bool get nullable => _nullable;

  @override
  int? get itemSize => _maxLength;

  @override
  Type get dartType => String;

  @override
  dynamic convert(dynamic value) {
    if (value == null) {
      if (!_nullable) {
        throw ArgumentError('Cannot convert null to non-nullable String');
      }
      return null;
    }
    final str = value.toString();
    if (_maxLength != null && str.length > _maxLength) {
      throw ArgumentError(
          'String length ${str.length} exceeds maximum $_maxLength');
    }
    return str;
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return _nullable;
    if (value is! String) return false;
    if (_maxLength != null && value.length > _maxLength) return false;
    return true;
  }

  @override
  bool isNull(dynamic value) => value == null;

  @override
  dynamic get nullValue => null;
}

/// Float types.
class Float32DType extends DType {
  final bool _nullable;

  Float32DType({bool nullable = true}) : _nullable = nullable;

  @override
  String get name => _nullable ? 'Float32' : 'float32';

  @override
  bool get nullable => _nullable;

  @override
  int get itemSize => 4;

  @override
  Type get dartType => double;

  @override
  dynamic convert(dynamic value) {
    if (value == null) {
      if (!_nullable) {
        throw ArgumentError('Cannot convert null to non-nullable Float32');
      }
      return null;
    }
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null) {
        throw FormatException('Cannot parse "$value" as Float32');
      }
      return parsed;
    }
    throw ArgumentError('Cannot convert ${value.runtimeType} to Float32');
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return _nullable;
    return value is double || value is int;
  }

  @override
  bool isNull(dynamic value) =>
      value == null || (value is double && value.isNaN);

  @override
  dynamic get nullValue => null;
}

class Float64DType extends DType {
  final bool _nullable;

  Float64DType({bool nullable = true}) : _nullable = nullable;

  @override
  String get name => _nullable ? 'Float64' : 'float64';

  @override
  bool get nullable => _nullable;

  @override
  int get itemSize => 8;

  @override
  Type get dartType => double;

  @override
  dynamic convert(dynamic value) {
    if (value == null) {
      if (!_nullable) {
        throw ArgumentError('Cannot convert null to non-nullable Float64');
      }
      return null;
    }
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null) {
        throw FormatException('Cannot parse "$value" as Float64');
      }
      return parsed;
    }
    throw ArgumentError('Cannot convert ${value.runtimeType} to Float64');
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return _nullable;
    return value is double || value is int;
  }

  @override
  bool isNull(dynamic value) =>
      value == null || (value is double && value.isNaN);

  @override
  dynamic get nullValue => null;
}

/// Object type (any type).
class ObjectDType extends DType {
  @override
  String get name => 'object';

  @override
  bool get nullable => true;

  @override
  int? get itemSize => null;

  @override
  Type get dartType => Object;

  @override
  dynamic convert(dynamic value) => value;

  @override
  bool isValid(dynamic value) => true;

  @override
  bool isNull(dynamic value) => value == null;

  @override
  dynamic get nullValue => null;
}

/// DateTime type.
class DateTimeDType extends DType {
  final bool _nullable;

  DateTimeDType({bool nullable = true}) : _nullable = nullable;

  @override
  String get name => _nullable ? 'DateTime' : 'datetime';

  @override
  bool get nullable => _nullable;

  @override
  int? get itemSize => null;

  @override
  Type get dartType => DateTime;

  @override
  dynamic convert(dynamic value) {
    if (value == null) {
      if (!_nullable) {
        throw ArgumentError('Cannot convert null to non-nullable DateTime');
      }
      return null;
    }
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        throw FormatException('Cannot parse "$value" as DateTime');
      }
      return parsed;
    }
    if (value is int) {
      // Assume milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    throw ArgumentError('Cannot convert ${value.runtimeType} to DateTime');
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return _nullable;
    return value is DateTime;
  }

  @override
  bool isNull(dynamic value) => value == null;

  @override
  dynamic get nullValue => null;
}

/// Extension type base class.
abstract class ExtensionDType extends DType {
  /// Create a new instance of this extension type.
  ExtensionDType();

  /// Validate the extension type configuration.
  void validate() {}
}

/// Registry for custom data types.
class DTypeRegistry {
  static final DTypeRegistry _instance = DTypeRegistry._internal();
  factory DTypeRegistry() => _instance;
  DTypeRegistry._internal();

  final Map<String, DType Function()> _registry = {};

  /// Register a custom data type.
  void register(String name, DType Function() constructor) {
    if (_registry.containsKey(name)) {
      throw ArgumentError('DType "$name" is already registered');
    }
    _registry[name] = constructor;
  }

  /// Unregister a custom data type.
  void unregister(String name) {
    _registry.remove(name);
  }

  /// Get a data type by name.
  DType? get(String name) {
    // Check built-in types first
    switch (name.toLowerCase()) {
      case 'int8':
        return Int8DType();
      case 'int16':
        return Int16DType();
      case 'int32':
        return Int32DType();
      case 'int64':
      case 'int':
        return Int64DType();
      case 'float32':
        return Float32DType();
      case 'float64':
      case 'float':
      case 'double':
        return Float64DType();
      case 'boolean':
      case 'bool':
        return BooleanDType();
      case 'string':
      case 'str':
        return StringDType();
      case 'datetime':
        return DateTimeDType();
      case 'object':
        return ObjectDType();
    }

    // Check custom types
    final constructor = _registry[name];
    if (constructor != null) {
      return constructor();
    }

    return null;
  }

  /// Check if a type is registered.
  bool has(String name) => get(name) != null;

  /// List all registered type names.
  List<String> get registeredTypes => _registry.keys.toList();

  /// Clear all custom registrations (built-in types remain).
  void clear() {
    _registry.clear();
  }
}

/// Convenience functions for creating dtypes.
class DTypes {
  static Int8DType int8({bool nullable = true}) =>
      Int8DType(nullable: nullable);
  static Int16DType int16({bool nullable = true}) =>
      Int16DType(nullable: nullable);
  static Int32DType int32({bool nullable = true}) =>
      Int32DType(nullable: nullable);
  static Int64DType int64({bool nullable = true}) =>
      Int64DType(nullable: nullable);
  static Float32DType float32({bool nullable = true}) =>
      Float32DType(nullable: nullable);
  static Float64DType float64({bool nullable = true}) =>
      Float64DType(nullable: nullable);
  static BooleanDType boolean({bool nullable = true}) =>
      BooleanDType(nullable: nullable);
  static StringDType string({bool nullable = true, int? maxLength}) =>
      StringDType(nullable: nullable, maxLength: maxLength);
  static DateTimeDType datetime({bool nullable = true}) =>
      DateTimeDType(nullable: nullable);
  static ObjectDType object() => ObjectDType();

  /// Get the registry instance.
  static DTypeRegistry get registry => DTypeRegistry();
}
