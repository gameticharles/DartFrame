/// Chunk manager with LRU cache for efficient memory management
library;

import 'dart:collection';

/// A chunk of data with metadata
class Chunk {
  /// Chunk data
  final List<double> data;

  /// Chunk shape
  final List<int> shape;

  /// Chunk index in the array
  final List<int> index;

  /// Size in bytes
  final int sizeBytes;

  /// Last access time
  DateTime lastAccess;

  Chunk({
    required this.data,
    required this.shape,
    required this.index,
    required this.sizeBytes,
  }) : lastAccess = DateTime.now();

  /// Update last access time
  void touch() {
    lastAccess = DateTime.now();
  }

  /// Create chunk key for indexing
  String get key => index.join(',');
}

/// LRU cache for chunks
class ChunkManager {
  /// Maximum memory in bytes
  final int maxMemoryBytes;

  /// Maximum number of cached chunks
  final int maxCachedChunks;

  /// Cached chunks (key -> chunk)
  final Map<String, Chunk> _cache = {};

  /// Access order (LRU tracking)
  final LinkedHashMap<String, DateTime> _accessOrder = LinkedHashMap();

  /// Current memory usage
  int _currentMemoryBytes = 0;

  /// Cache statistics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  ChunkManager({
    required this.maxMemoryBytes,
    required this.maxCachedChunks,
  });

  /// Get chunk from cache or load it
  Chunk? getChunk(List<int> chunkIndex) {
    final key = chunkIndex.join(',');

    if (_cache.containsKey(key)) {
      _hits++;
      final chunk = _cache[key]!;
      chunk.touch();
      _accessOrder.remove(key);
      _accessOrder[key] = chunk.lastAccess;
      return chunk;
    }

    _misses++;
    return null;
  }

  /// Put chunk in cache
  void putChunk(Chunk chunk) {
    final key = chunk.key;

    // If chunk already exists, update it
    if (_cache.containsKey(key)) {
      final oldChunk = _cache[key]!;
      _currentMemoryBytes -= oldChunk.sizeBytes;
      _accessOrder.remove(key);
    }

    // Evict chunks if necessary
    while (_shouldEvict(chunk.sizeBytes)) {
      _evictLRU();
    }

    // Add new chunk
    _cache[key] = chunk;
    _accessOrder[key] = chunk.lastAccess;
    _currentMemoryBytes += chunk.sizeBytes;
  }

  /// Check if we should evict chunks
  bool _shouldEvict(int newChunkSize) {
    if (_cache.isEmpty) return false;

    final wouldExceedMemory =
        _currentMemoryBytes + newChunkSize > maxMemoryBytes;
    final wouldExceedCount = _cache.length >= maxCachedChunks;

    return wouldExceedMemory || wouldExceedCount;
  }

  /// Evict least recently used chunk
  void _evictLRU() {
    if (_cache.isEmpty) return;

    // Get least recently used key (first in LinkedHashMap)
    final lruKey = _accessOrder.keys.first;
    evictChunk(lruKey.split(',').map(int.parse).toList());
  }

  /// Evict specific chunk
  void evictChunk(List<int> chunkIndex) {
    final key = chunkIndex.join(',');

    if (_cache.containsKey(key)) {
      final chunk = _cache[key]!;
      _currentMemoryBytes -= chunk.sizeBytes;
      _cache.remove(key);
      _accessOrder.remove(key);
      _evictions++;
    }
  }

  /// Prefetch multiple chunks
  Future<void> prefetch(
    List<List<int>> chunkIndices,
    Future<Chunk> Function(List<int>) loader,
  ) async {
    for (final index in chunkIndices) {
      final key = index.join(',');
      if (!_cache.containsKey(key)) {
        final chunk = await loader(index);
        putChunk(chunk);
      }
    }
  }

  /// Clear all cached chunks
  void clearCache() {
    _cache.clear();
    _accessOrder.clear();
    _currentMemoryBytes = 0;
  }

  /// Get number of cached chunks
  int get cacheSize => _cache.length;

  /// Get current memory usage in bytes
  int get memoryUsage => _currentMemoryBytes;

  /// Get cache hit rate (0.0 to 1.0)
  double get hitRate {
    final total = _hits + _misses;
    return total == 0 ? 0.0 : _hits / total;
  }

  /// Get cache statistics
  ChunkCacheStats get stats => ChunkCacheStats(
        hits: _hits,
        misses: _misses,
        evictions: _evictions,
        hitRate: hitRate,
        cacheSize: cacheSize,
        memoryUsage: _currentMemoryBytes,
        maxMemory: maxMemoryBytes,
      );

  /// Reset statistics
  void resetStats() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
  }

  /// Check if chunk is cached
  bool contains(List<int> chunkIndex) {
    final key = chunkIndex.join(',');
    return _cache.containsKey(key);
  }

  /// Get all cached chunk indices
  List<List<int>> getCachedIndices() {
    return _cache.keys
        .map((key) => key.split(',').map(int.parse).toList())
        .toList();
  }
}

/// Chunk cache statistics
class ChunkCacheStats {
  final int hits;
  final int misses;
  final int evictions;
  final double hitRate;
  final int cacheSize;
  final int memoryUsage;
  final int maxMemory;

  const ChunkCacheStats({
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.hitRate,
    required this.cacheSize,
    required this.memoryUsage,
    required this.maxMemory,
  });

  double get memoryUsagePercent => memoryUsage / maxMemory;

  @override
  String toString() {
    return 'ChunkCacheStats('
        'hits: $hits, '
        'misses: $misses, '
        'evictions: $evictions, '
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'cacheSize: $cacheSize, '
        'memory: ${(memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB / '
        '${(maxMemory / 1024 / 1024).toStringAsFixed(1)}MB)';
  }
}
