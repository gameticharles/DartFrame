import '../core/shape.dart';
import '../core/slice_spec.dart';

/// Abstract storage backend for N-dimensional arrays
///
/// Provides a common interface for different storage strategies:
/// - InMemory: Fast, for small-medium data
/// - Chunked: LRU cache, for large data
/// - File: Lazy loading, for very large data
/// - Compressed: Trade CPU for space
/// - Virtual: Computed on-demand
///
/// This abstraction allows NDArray and DataCube to work with
/// different storage backends transparently.
abstract class StorageBackend {
  /// Shape of the stored data
  Shape get shape;

  /// Get value at multi-dimensional indices
  ///
  /// Example:
  /// ```dart
  /// var value = backend.getValue([1, 2, 3]);
  /// ```
  dynamic getValue(List<int> indices);

  /// Set value at multi-dimensional indices
  ///
  /// Example:
  /// ```dart
  /// backend.setValue([1, 2, 3], 42);
  /// ```
  void setValue(List<int> indices, dynamic value);

  /// Get a slice of the data
  ///
  /// Returns a new backend representing the sliced data.
  /// The slice may be a view (no data copying) or a new backend.
  ///
  /// Example:
  /// ```dart
  /// var sliced = backend.getSlice([
  ///   SliceSpec(0, 10),
  ///   SliceSpec.all(),
  ///   SliceSpec.single(5),
  /// ]);
  /// ```
  StorageBackend getSlice(List<SliceSpec> slices);

  /// Load data into memory (if not already loaded)
  ///
  /// For lazy backends, this forces data loading.
  /// For in-memory backends, this is a no-op.
  ///
  /// Example:
  /// ```dart
  /// await backend.load();
  /// ```
  Future<void> load();

  /// Unload data from memory
  ///
  /// For backends with caching, this clears the cache.
  /// For in-memory backends, this may be a no-op.
  ///
  /// Example:
  /// ```dart
  /// await backend.unload();
  /// ```
  Future<void> unload();

  /// Get flat data array
  ///
  /// Returns the underlying data as a flat list.
  /// If `copy` is true, returns a copy; otherwise may return a view.
  ///
  /// Example:
  /// ```dart
  /// var data = backend.getFlatData(copy: true);
  /// ```
  List<dynamic> getFlatData({bool copy = false});

  /// Memory usage in bytes (estimate)
  ///
  /// Returns the approximate memory used by this backend.
  int get memoryUsage;

  /// Check if data is currently in memory
  ///
  /// Returns true if data is loaded, false if lazy/on-disk.
  bool get isInMemory;

  /// Total number of elements
  int get size => shape.size;

  /// Number of dimensions
  int get ndim => shape.ndim;

  /// Clone this backend
  ///
  /// Creates a deep copy of the backend and its data.
  StorageBackend clone();

  /// Dispose resources
  ///
  /// Clean up any resources (files, memory, etc.)
  Future<void> dispose() async {
    await unload();
  }
}

/// Backend statistics for monitoring
class BackendStats {
  /// Number of getValue calls
  int getCount = 0;

  /// Number of setValue calls
  int setCount = 0;

  /// Number of cache hits (for cached backends)
  int cacheHits = 0;

  /// Number of cache misses (for cached backends)
  int cacheMisses = 0;

  /// Total bytes read
  int bytesRead = 0;

  /// Total bytes written
  int bytesWritten = 0;

  /// Reset all statistics
  void reset() {
    getCount = 0;
    setCount = 0;
    cacheHits = 0;
    cacheMisses = 0;
    bytesRead = 0;
    bytesWritten = 0;
  }

  /// Cache hit rate (0.0 to 1.0)
  double get cacheHitRate {
    int total = cacheHits + cacheMisses;
    return total == 0 ? 0.0 : cacheHits / total;
  }

  @override
  String toString() {
    return 'BackendStats('
        'gets: $getCount, '
        'sets: $setCount, '
        'cache: ${(cacheHitRate * 100).toStringAsFixed(1)}%, '
        'read: ${_formatBytes(bytesRead)}, '
        'written: ${_formatBytes(bytesWritten)}'
        ')';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Mixin for backends that support statistics tracking
mixin BackendStatsMixin on StorageBackend {
  final BackendStats _stats = BackendStats();

  /// Get backend statistics
  BackendStats get stats => _stats;

  /// Reset statistics
  void resetStats() => _stats.reset();

  /// Track a getValue call
  void trackGet() => _stats.getCount++;

  /// Track a setValue call
  void trackSet() => _stats.setCount++;

  /// Track a cache hit
  void trackCacheHit() => _stats.cacheHits++;

  /// Track a cache miss
  void trackCacheMiss() => _stats.cacheMisses++;

  /// Track bytes read
  void trackBytesRead(int bytes) => _stats.bytesRead += bytes;

  /// Track bytes written
  void trackBytesWritten(int bytes) => _stats.bytesWritten += bytes;
}
