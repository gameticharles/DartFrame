import 'dart_data.dart';
import 'shape.dart';
import 'attributes.dart';

/// Scalar - 0-dimensional data structure
///
/// Represents a single value with DartData interface compatibility.
/// This is the result of indexing operations that reduce to a single element.
///
/// Example:
/// ```dart
/// var scalar = Scalar(42);
/// print(scalar.value);  // 42
/// print(scalar.ndim);   // 0
/// print(scalar.size);   // 1
///
/// // With metadata
/// var temp = Scalar(23.5);
/// temp.attrs['units'] = 'celsius';
/// temp.attrs['sensor'] = 'TEMP_001';
/// ```
class Scalar<T> with DartDataMixin implements DartData {
  /// The scalar value
  final T value;

  /// Metadata attributes
  @override
  final Attributes attrs = Attributes();

  /// Create a scalar with a value
  ///
  /// Example:
  /// ```dart
  /// var intScalar = Scalar<int>(42);
  /// var doubleScalar = Scalar<double>(3.14);
  /// var stringScalar = Scalar<String>('hello');
  /// var dynamicScalar = Scalar(42);  // Type inferred
  /// ```
  Scalar(this.value);

  /// Create a scalar with metadata
  ///
  /// Example:
  /// ```dart
  /// var scalar = Scalar.withAttrs(
  ///   23.5,
  ///   {'units': 'celsius', 'sensor': 'TEMP_001'},
  /// );
  /// ```
  factory Scalar.withAttrs(T value, Map<String, dynamic> attributes) {
    var scalar = Scalar(value);
    for (var entry in attributes.entries) {
      scalar.attrs[entry.key] = entry.value;
    }
    return scalar;
  }

  @override
  Shape get shape => Shape([]);

  @override
  int get ndim => 0;

  @override
  int get size => 1;

  @override
  Type get dtype => T;

  @override
  dynamic getValue(List<int> indices) {
    if (indices.isNotEmpty) {
      throw ArgumentError(
          'Scalar is 0-dimensional, expected 0 indices, got ${indices.length}');
    }
    return value;
  }

  @override
  void setValue(List<int> indices, dynamic value) {
    throw UnsupportedError('Cannot set value on immutable Scalar');
  }

  @override
  DartData slice(List<dynamic> sliceSpec) {
    if (sliceSpec.isNotEmpty) {
      throw ArgumentError('Cannot slice 0-dimensional Scalar');
    }
    return this;
  }

  /// Convert to the underlying value type
  ///
  /// Example:
  /// ```dart
  /// var scalar = Scalar(42);
  /// int value = scalar.toValue();
  /// ```
  T toValue() => value;

  /// Implicit conversion to value (for convenience)
  ///
  /// Example:
  /// ```dart
  /// var scalar = Scalar(42);
  /// int x = scalar.value;  // Direct access
  /// ```
  T call() => value;

  @override
  String toString() {
    if (attrs.isEmpty) {
      return 'Scalar($value)';
    }
    return 'Scalar($value, attrs: ${attrs.length})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Scalar &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  // ============ Arithmetic Operations (for numeric scalars) ============

  /// Add two scalars
  ///
  /// Example:
  /// ```dart
  /// var a = Scalar(5);
  /// var b = Scalar(3);
  /// var c = a + b;  // Scalar(8)
  /// ```
  Scalar<num> operator +(Object other) {
    if (value is! num) {
      throw UnsupportedError('Addition only supported for numeric scalars');
    }

    if (other is Scalar) {
      if (other.value is! num) {
        throw TypeError();
      }
      return Scalar<num>((value as num) + (other.value as num));
    } else if (other is num) {
      return Scalar<num>((value as num) + other);
    }

    throw ArgumentError('Cannot add Scalar and ${other.runtimeType}');
  }

  /// Subtract two scalars
  Scalar<num> operator -(Object other) {
    if (value is! num) {
      throw UnsupportedError('Subtraction only supported for numeric scalars');
    }

    if (other is Scalar) {
      if (other.value is! num) {
        throw TypeError();
      }
      return Scalar<num>((value as num) - (other.value as num));
    } else if (other is num) {
      return Scalar<num>((value as num) - other);
    }

    throw ArgumentError('Cannot subtract ${other.runtimeType} from Scalar');
  }

  /// Multiply two scalars
  Scalar<num> operator *(Object other) {
    if (value is! num) {
      throw UnsupportedError(
          'Multiplication only supported for numeric scalars');
    }

    if (other is Scalar) {
      if (other.value is! num) {
        throw TypeError();
      }
      return Scalar<num>((value as num) * (other.value as num));
    } else if (other is num) {
      return Scalar<num>((value as num) * other);
    }

    throw ArgumentError('Cannot multiply Scalar and ${other.runtimeType}');
  }

  /// Divide two scalars
  Scalar<num> operator /(Object other) {
    if (value is! num) {
      throw UnsupportedError('Division only supported for numeric scalars');
    }

    if (other is Scalar) {
      if (other.value is! num) {
        throw TypeError();
      }
      return Scalar<num>((value as num) / (other.value as num));
    } else if (other is num) {
      return Scalar<num>((value as num) / other);
    }

    throw ArgumentError('Cannot divide Scalar by ${other.runtimeType}');
  }

  /// Negate scalar
  Scalar<num> operator -() {
    if (value is! num) {
      throw UnsupportedError('Negation only supported for numeric scalars');
    }
    return Scalar<num>(-(value as num));
  }

  // ============ Comparison Operations ============

  /// Less than
  bool operator <(Object other) {
    if (value is! Comparable) {
      throw UnsupportedError(
          'Comparison not supported for ${value.runtimeType}');
    }

    if (other is Scalar) {
      return (value as Comparable).compareTo(other.value) < 0;
    } else {
      return (value as Comparable).compareTo(other) < 0;
    }
  }

  /// Less than or equal
  bool operator <=(Object other) {
    if (value is! Comparable) {
      throw UnsupportedError(
          'Comparison not supported for ${value.runtimeType}');
    }

    if (other is Scalar) {
      return (value as Comparable).compareTo(other.value) <= 0;
    } else {
      return (value as Comparable).compareTo(other) <= 0;
    }
  }

  /// Greater than
  bool operator >(Object other) {
    if (value is! Comparable) {
      throw UnsupportedError(
          'Comparison not supported for ${value.runtimeType}');
    }

    if (other is Scalar) {
      return (value as Comparable).compareTo(other.value) > 0;
    } else {
      return (value as Comparable).compareTo(other) > 0;
    }
  }

  /// Greater than or equal
  bool operator >=(Object other) {
    if (value is! Comparable) {
      throw UnsupportedError(
          'Comparison not supported for ${value.runtimeType}');
    }

    if (other is Scalar) {
      return (value as Comparable).compareTo(other.value) >= 0;
    } else {
      return (value as Comparable).compareTo(other) >= 0;
    }
  }
}
