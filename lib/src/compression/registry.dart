/// Compression codec registry
library;

import 'codec.dart';
import 'none_codec.dart';
import 'gzip_codec.dart';
import 'zlib_codec.dart';

/// Global registry for compression codecs
class CompressionRegistry {
  static final Map<String, Codec> _codecs = {};
  static Codec? _defaultCodec;

  /// Initialize registry with built-in codecs
  static void initialize() {
    if (_codecs.isNotEmpty) return; // Already initialized

    register(const NoneCodec());
    register(const GzipCodec());
    register(const ZlibCodec());

    _defaultCodec = const GzipCodec();
  }

  /// Register a codec
  static void register(Codec codec) {
    _codecs[codec.name.toLowerCase()] = codec;
  }

  /// Get codec by name
  static Codec? get(String name) {
    initialize();
    return _codecs[name.toLowerCase()];
  }

  /// Get codec by name, throw if not found
  static Codec getOrThrow(String name) {
    final codec = get(name);
    if (codec == null) {
      throw ArgumentError('Unknown compression codec: $name');
    }
    return codec;
  }

  /// Get default codec
  static Codec getDefault() {
    initialize();
    return _defaultCodec ?? const GzipCodec();
  }

  /// Set default codec
  static void setDefault(Codec codec) {
    initialize();
    _defaultCodec = codec;
  }

  /// Get all registered codecs
  static List<Codec> getAll() {
    initialize();
    return _codecs.values.toList();
  }

  /// Get all available codecs
  static List<Codec> getAvailable() {
    initialize();
    return _codecs.values.where((c) => c.isAvailable).toList();
  }

  /// Check if codec is registered
  static bool has(String name) {
    initialize();
    return _codecs.containsKey(name.toLowerCase());
  }

  /// Get codec names
  static List<String> getNames() {
    initialize();
    return _codecs.keys.toList();
  }

  /// Clear registry (for testing)
  static void clear() {
    _codecs.clear();
    _defaultCodec = null;
  }
}
