import 'dart:convert';

/// HDF5-style metadata attributes for data structures
///
/// Provides a flexible key-value store for metadata that can be:
/// - Attached to any DartData structure
/// - Serialized to/from JSON
/// - Used for documentation and provenance
///
/// Example:
/// ```dart
/// var attrs = Attributes();
/// attrs['units'] = 'celsius';
/// attrs['description'] = 'Temperature measurements';
/// attrs['created'] = DateTime.now();
/// attrs['sensor_id'] = 'TEMP_001';
///
/// print(attrs['units']);  // 'celsius'
/// print(attrs.keys);      // ['units', 'description', 'created', 'sensor_id']
/// ```
class Attributes {
  final Map<String, dynamic> _attrs = {};

  /// Create empty attributes
  Attributes();

  /// Create attributes from JSON map
  ///
  /// Example:
  /// ```dart
  /// var attrs = Attributes.fromJson({
  ///   'units': 'celsius',
  ///   'description': 'Temperature data',
  /// });
  /// ```
  factory Attributes.fromJson(Map<String, dynamic> json) {
    var attrs = Attributes();
    attrs._attrs.addAll(json);
    return attrs;
  }

  /// Get attribute value
  ///
  /// Returns null if attribute doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// var value = attrs['units'];
  /// ```
  dynamic operator [](String key) => _attrs[key];

  /// Set attribute value
  ///
  /// Example:
  /// ```dart
  /// attrs['units'] = 'celsius';
  /// ```
  void operator []=(String key, dynamic value) {
    _validateAttributeValue(value);
    _attrs[key] = value;
  }

  /// Get all attribute keys
  List<String> get keys => _attrs.keys.toList();

  /// Get all attribute values
  List<dynamic> get values => _attrs.values.toList();

  /// Check if attribute exists
  ///
  /// Example:
  /// ```dart
  /// if (attrs.contains('units')) {
  ///   print('Units: ${attrs['units']}');
  /// }
  /// ```
  bool contains(String key) => _attrs.containsKey(key);

  /// Get attribute with type checking and default value
  ///
  /// Example:
  /// ```dart
  /// var units = attrs.get<String>('units', defaultValue: 'unknown');
  /// var count = attrs.get<int>('count', defaultValue: 0);
  /// ```
  T get<T>(String key, {T? defaultValue}) {
    if (!_attrs.containsKey(key)) {
      if (defaultValue != null) return defaultValue;
      throw ArgumentError('Attribute "$key" not found');
    }

    var value = _attrs[key];
    if (value is! T) {
      throw TypeError();
    }
    return value;
  }

  /// Remove an attribute
  ///
  /// Returns the removed value, or null if it didn't exist.
  ///
  /// Example:
  /// ```dart
  /// var oldValue = attrs.remove('units');
  /// ```
  dynamic remove(String key) => _attrs.remove(key);

  /// Clear all attributes
  void clear() => _attrs.clear();

  /// Number of attributes
  int get length => _attrs.length;

  /// Check if attributes are empty
  bool get isEmpty => _attrs.isEmpty;

  /// Check if attributes are not empty
  bool get isNotEmpty => _attrs.isNotEmpty;

  /// Convert to JSON map
  ///
  /// Example:
  /// ```dart
  /// var json = attrs.toJson();
  /// var jsonString = jsonEncode(json);
  /// ```
  Map<String, dynamic> toJson() => Map.from(_attrs);

  /// Convert to JSON string
  ///
  /// Example:
  /// ```dart
  /// var jsonString = attrs.toJsonString();
  /// ```
  String toJsonString({bool pretty = false}) {
    if (pretty) {
      var encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(_attrs);
    }
    return jsonEncode(_attrs);
  }

  /// Validate attribute value
  ///
  /// Ensures values are JSON-serializable.
  void _validateAttributeValue(dynamic value) {
    if (value == null) return;

    // Allow basic JSON types
    if (value is num || value is String || value is bool) return;

    // Allow DateTime (will be converted to ISO string)
    if (value is DateTime) return;

    // Allow lists and maps of valid types
    if (value is List) {
      for (var item in value) {
        _validateAttributeValue(item);
      }
      return;
    }

    if (value is Map) {
      for (var item in value.values) {
        _validateAttributeValue(item);
      }
      return;
    }

    throw ArgumentError('Attribute value must be JSON-serializable. '
        'Got: ${value.runtimeType}');
  }

  // ============ Common Metadata Properties ============

  /// Description of the data
  String? get description => _attrs['description'];
  set description(String? value) => _attrs['description'] = value;

  /// Units of measurement
  String? get units => _attrs['units'];
  set units(String? value) => _attrs['units'] = value;

  /// Creation timestamp
  DateTime? get created => _attrs['created'];
  set created(DateTime? value) => _attrs['created'] = value;

  /// Last modified timestamp
  DateTime? get modified => _attrs['modified'];
  set modified(DateTime? value) => _attrs['modified'] = value;

  /// Data source
  String? get source => _attrs['source'];
  set source(String? value) => _attrs['source'] = value;

  /// Author/creator
  String? get author => _attrs['author'];
  set author(String? value) => _attrs['author'] = value;

  /// Version
  String? get version => _attrs['version'];
  set version(String? value) => _attrs['version'] = value;

  @override
  String toString() {
    if (_attrs.isEmpty) {
      return 'Attributes(empty)';
    }
    return 'Attributes(${_attrs.length} items: ${keys.take(3).join(', ')}${keys.length > 3 ? '...' : ''})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attributes &&
          runtimeType == other.runtimeType &&
          _mapsEqual(_attrs, other._attrs);

  @override
  int get hashCode {
    // Create consistent hashCode from keys and values
    int hash = 0;
    for (var key in _attrs.keys) {
      hash ^= key.hashCode;
      hash ^= _attrs[key].hashCode;
    }
    return hash;
  }

  /// Helper to compare maps
  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
