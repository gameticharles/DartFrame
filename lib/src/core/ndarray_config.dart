import '../storage/storage_backend.dart';
import '../storage/inmemory_backend.dart';
import '../storage/chunked_backend.dart';
import 'shape.dart';

/// Global configuration for NDArray and DataCube behavior
///
/// Controls memory management, performance, and default behaviors.
///
/// Example:
/// ```dart
/// // Configure memory limits
/// NDArrayConfig.maxMemoryBytes = 2 * 1024 * 1024 * 1024; // 2 GB
///
/// // Configure chunking
/// NDArrayConfig.defaultChunkSize = 10000;
/// NDArrayConfig.maxCachedChunks = 20;
///
/// // Configure behavior
/// NDArrayConfig.lazyByDefault = true;
/// NDArrayConfig.autoSelectBackend = true;
/// ```
class NDArrayConfig {
  // ============ Memory Management ============

  /// Maximum memory to use for arrays (bytes)
  ///
  /// Default: 1 GB
  static int maxMemoryBytes = 1024 * 1024 * 1024;

  /// Default chunk size for chunked operations
  ///
  /// Default: 1000 elements per chunk
  static int defaultChunkSize = 1000;

  /// Maximum number of chunks to cache
  ///
  /// Default: 10 chunks
  static int maxCachedChunks = 10;

  /// Target chunk size in bytes for auto-chunking
  ///
  /// Default: 1 MB
  static int targetChunkBytes = 1024 * 1024;

  /// Bytes per element estimate (for memory calculations)
  ///
  /// Default: 8 bytes (size of double)
  static int bytesPerElement = 8;

  // ============ Backend Selection ============

  /// Automatically select backend based on data size
  ///
  /// Default: true
  static bool autoSelectBackend = true;

  /// Threshold for switching to chunked backend (bytes)
  ///
  /// Arrays larger than this use ChunkedBackend instead of InMemoryBackend.
  /// Default: 100 MB
  static int chunkedThreshold = 100 * 1024 * 1024;

  /// Threshold for lazy loading (bytes)
  ///
  /// Arrays larger than this use lazy loading.
  /// Default: 500 MB
  static int lazyThreshold = 500 * 1024 * 1024;

  // ============ Performance ============

  /// Number of worker isolates for parallel operations
  ///
  /// Default: 4
  static int defaultWorkers = 4;

  /// Enable lazy evaluation by default
  ///
  /// Default: true
  static bool lazyByDefault = true;

  /// Enable copy-on-write optimization
  ///
  /// Default: true
  static bool copyOnWrite = true;

  /// Enable automatic broadcasting in operations
  ///
  /// Default: true
  static bool autoBroadcast = true;

  // ============ Compression ============

  /// Enable compression for file backends
  ///
  /// Default: false (disabled for compatibility)
  static bool compressFiles = false;

  /// Default compression level (1-9)
  ///
  /// Default: 6 (balanced)
  static int compressionLevel = 6;

  // ============ Behavior ============

  /// Strict type checking
  ///
  /// If true, type mismatches throw errors.
  /// If false, attempts automatic conversion.
  /// Default: false
  static bool strictTypes = false;

  /// Default fill value for empty arrays
  ///
  /// Default: null
  static dynamic defaultFillValue;

  /// Enable statistics tracking
  ///
  /// Default: false (for performance)
  static bool enableStats = false;

  // ============ Backend Selection Logic ============

  /// Auto-select appropriate backend based on data size
  ///
  /// Example:
  /// ```dart
  /// var backend = NDArrayConfig.selectBackend(
  ///   Shape([1000, 1000]),
  ///   initialData: data,
  /// );
  /// ```
  static StorageBackend selectBackend(
    Shape shape, {
    List<dynamic>? initialData,
  }) {
    if (!autoSelectBackend) {
      // Default to InMemory if auto-selection is disabled
      if (initialData != null) {
        return InMemoryBackend(initialData, shape);
      }
      return InMemoryBackend.zeros(shape);
    }

    int estimatedBytes = shape.size * bytesPerElement;

    // Small data: InMemory
    if (estimatedBytes < chunkedThreshold) {
      if (initialData != null) {
        return InMemoryBackend(initialData, shape);
      }
      return InMemoryBackend.zeros(shape);
    }

    // Large data: Chunked
    if (estimatedBytes < lazyThreshold) {
      return ChunkedBackend.auto(
        shape: shape,
        targetChunkBytes: targetChunkBytes,
        bytesPerElement: bytesPerElement,
        maxCachedChunks: maxCachedChunks,
        initialData: initialData,
      );
    }

    // Very large data: Chunked with smaller cache
    return ChunkedBackend.auto(
      shape: shape,
      targetChunkBytes: targetChunkBytes,
      bytesPerElement: bytesPerElement,
      maxCachedChunks: maxCachedChunks ~/ 2,
      initialData: initialData,
    );
  }

  /// Reset all configuration to defaults
  static void resetToDefaults() {
    maxMemoryBytes = 1024 * 1024 * 1024;
    defaultChunkSize = 1000;
    maxCachedChunks = 10;
    targetChunkBytes = 1024 * 1024;
    bytesPerElement = 8;
    autoSelectBackend = true;
    chunkedThreshold = 100 * 1024 * 1024;
    lazyThreshold = 500 * 1024 * 1024;
    defaultWorkers = 4;
    lazyByDefault = true;
    copyOnWrite = true;
    autoBroadcast = true;
    compressFiles = false;
    compressionLevel = 6;
    strictTypes = false;
    defaultFillValue = null;
    enableStats = false;
  }

  /// Get current configuration as map
  static Map<String, dynamic> toMap() {
    return {
      'maxMemoryBytes': maxMemoryBytes,
      'defaultChunkSize': defaultChunkSize,
      'maxCachedChunks': maxCachedChunks,
      'targetChunkBytes': targetChunkBytes,
      'bytesPerElement': bytesPerElement,
      'autoSelectBackend': autoSelectBackend,
      'chunkedThreshold': chunkedThreshold,
      'lazyThreshold': lazyThreshold,
      'defaultWorkers': defaultWorkers,
      'lazyByDefault': lazyByDefault,
      'copyOnWrite': copyOnWrite,
      'autoBroadcast': autoBroadcast,
      'compressFiles': compressFiles,
      'compressionLevel': compressionLevel,
      'strictTypes': strictTypes,
      'defaultFillValue': defaultFillValue,
      'enableStats': enableStats,
    };
  }

  /// Load configuration from map
  static void fromMap(Map<String, dynamic> config) {
    if (config.containsKey('maxMemoryBytes')) {
      maxMemoryBytes = config['maxMemoryBytes'];
    }
    if (config.containsKey('defaultChunkSize')) {
      defaultChunkSize = config['defaultChunkSize'];
    }
    if (config.containsKey('maxCachedChunks')) {
      maxCachedChunks = config['maxCachedChunks'];
    }
    if (config.containsKey('targetChunkBytes')) {
      targetChunkBytes = config['targetChunkBytes'];
    }
    if (config.containsKey('bytesPerElement')) {
      bytesPerElement = config['bytesPerElement'];
    }
    if (config.containsKey('autoSelectBackend')) {
      autoSelectBackend = config['autoSelectBackend'];
    }
    if (config.containsKey('chunkedThreshold')) {
      chunkedThreshold = config['chunkedThreshold'];
    }
    if (config.containsKey('lazyThreshold')) {
      lazyThreshold = config['lazyThreshold'];
    }
    if (config.containsKey('defaultWorkers')) {
      defaultWorkers = config['defaultWorkers'];
    }
    if (config.containsKey('lazyByDefault')) {
      lazyByDefault = config['lazyByDefault'];
    }
    if (config.containsKey('copyOnWrite')) {
      copyOnWrite = config['copyOnWrite'];
    }
    if (config.containsKey('autoBroadcast')) {
      autoBroadcast = config['autoBroadcast'];
    }
    if (config.containsKey('compressFiles')) {
      compressFiles = config['compressFiles'];
    }
    if (config.containsKey('compressionLevel')) {
      compressionLevel = config['compressionLevel'];
    }
    if (config.containsKey('strictTypes')) {
      strictTypes = config['strictTypes'];
    }
    if (config.containsKey('defaultFillValue')) {
      defaultFillValue = config['defaultFillValue'];
    }
    if (config.containsKey('enableStats')) {
      enableStats = config['enableStats'];
    }
  }
}
