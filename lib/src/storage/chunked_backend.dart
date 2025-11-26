/// Chunked storage backend with advanced memory management
// ignore_for_file: unused_element

library;

import '../core/shape.dart';
import '../core/slice_spec.dart';
import 'storage_backend.dart';
import 'inmemory_backend.dart';
import 'chunk_manager.dart';
import '../utils/memory.dart';

/// Chunked storage backend with LRU caching and advanced memory management
///
/// Divides data into chunks and caches them in memory using LRU eviction.
/// Best for large datasets that don't fit entirely in RAM.
///
/// ## Operating Modes
///
/// **Synchronous Mode (with initialData):**
/// - Data is pre-loaded in memory via `initialData` parameter
/// - All operations (getValue, setValue, etc.) work synchronously
/// - Chunks are extracted from pre-loaded data on demand
/// - Compatible with all NDArray operations
/// - Recommended for most use cases
///
/// **Async Mode (with dataProvider):**
/// - Data is loaded lazily via `dataProvider` function
/// - Requires calling `await load()` before synchronous operations
/// - Not fully supported in current StorageBackend interface
/// - Future: Will be supported via AsyncStorageBackend interface
///
/// Features:
/// - Automatic chunking
/// - LRU cache with ChunkManager
/// - Memory pressure awareness
/// - Access pattern detection
/// - Automatic prefetching
/// - Configurable cache size
/// - Statistics tracking
///
/// Example (Synchronous Mode):
/// ```dart
/// var data = List.generate(1000000, (i) => i.toDouble());
/// var backend = ChunkedBackend(
///   shape: Shape([1000, 1000]),
///   chunkShape: [100, 100],
///   initialData: data,
///   maxMemoryBytes: 100 * 1024 * 1024,
/// );
/// var value = backend.getValue([0, 0]); // Works synchronously
/// ```
class ChunkedBackend extends StorageBackend with BackendStatsMixin {
  @override
  final Shape shape;

  /// Shape of each chunk
  final List<int> chunkShape;

  /// Chunk manager for advanced caching
  final ChunkManager chunkManager;

  /// Data provider function
  final Future<List<double>> Function(List<int> chunkIndex)? dataProvider;

  /// Enable prefetching
  final bool enablePrefetching;

  /// Prefetch distance (number of chunks ahead)
  final int prefetchDistance;

  /// Number of chunks along each dimension
  late final List<int> _numChunks;

  /// Size of each chunk
  late final int _chunkSize;

  /// All data (if loaded entirely)
  List<dynamic>? _allData;

  /// Last accessed chunk index (for prefetching)
  List<int>? _lastChunkIndex;

  /// Access pattern tracking
  final List<List<int>> _accessHistory = [];
  static const int _maxHistorySize = 10;

  /// Create chunked backend
  ///
  /// Parameters:
  /// - `shape`: Shape of the full array
  /// - `chunkShape`: Shape of each chunk
  /// - `maxMemoryBytes`: Maximum memory for cache (default: 100MB)
  /// - `maxCachedChunks`: Maximum chunks to keep in cache (default: 50)
  /// - `dataProvider`: Function to load chunks on demand (optional)
  /// - `enablePrefetching`: Enable automatic prefetching (default: true)
  /// - `prefetchDistance`: Number of chunks to prefetch ahead (default: 3)
  /// - `initialData`: Pre-loaded data (optional)
  ///
  /// Example:
  /// ```dart
  /// var backend = ChunkedBackend(
  ///   shape: Shape([1000, 1000]),
  ///   chunkShape: [100, 100],
  ///   maxMemoryBytes: 100 * 1024 * 1024,
  /// );
  /// ```
  ChunkedBackend({
    required this.shape,
    required this.chunkShape,
    int maxMemoryBytes = 100 * 1024 * 1024,
    int maxCachedChunks = 50,
    this.dataProvider,
    this.enablePrefetching = true,
    this.prefetchDistance = 3,
    List<dynamic>? initialData,
  }) : chunkManager = ChunkManager(
          maxMemoryBytes: maxMemoryBytes,
          maxCachedChunks: maxCachedChunks,
        ) {
    if (chunkShape.length != shape.ndim) {
      throw ArgumentError(
          'Chunk shape dimensions (${chunkShape.length}) must match '
          'array dimensions (${shape.ndim})');
    }

    // Calculate number of chunks along each dimension
    _numChunks = [];
    for (int i = 0; i < shape.ndim; i++) {
      _numChunks.add((shape[i] + chunkShape[i] - 1) ~/ chunkShape[i]);
    }

    // Calculate chunk size
    _chunkSize = chunkShape.reduce((a, b) => a * b);

    // Store initial data if provided
    if (initialData != null) {
      if (initialData.length != shape.size) {
        throw ArgumentError(
            'Initial data length (${initialData.length}) must match '
            'shape size (${shape.size})');
      }
      _allData = List.from(initialData);
    }

    // Register with memory monitor
    MemoryMonitor.registerBackend(this);
  }

  /// Create chunked backend with auto-calculated chunk shape
  ///
  /// Automatically determines optimal chunk shape based on target chunk size.
  ///
  /// Example:
  /// ```dart
  /// var backend = ChunkedBackend.auto(
  ///   shape: Shape([1000, 1000]),
  ///   targetChunkBytes: 1024 * 1024, // 1 MB chunks
  /// );
  /// ```
  factory ChunkedBackend.auto({
    required Shape shape,
    int targetChunkBytes = 1024 * 1024, // 1 MB default
    int bytesPerElement = 8,
    int maxMemoryBytes = 100 * 1024 * 1024,
    int maxCachedChunks = 50,
    Future<List<double>> Function(List<int> chunkIndex)? dataProvider,
    bool enablePrefetching = true,
    List<dynamic>? initialData,
  }) {
    int targetElements = targetChunkBytes ~/ bytesPerElement;
    List<int> chunkShape = _calculateOptimalChunkShape(shape, targetElements);

    return ChunkedBackend(
      shape: shape,
      chunkShape: chunkShape,
      maxMemoryBytes: maxMemoryBytes,
      maxCachedChunks: maxCachedChunks,
      dataProvider: dataProvider,
      enablePrefetching: enablePrefetching,
      initialData: initialData,
    );
  }

  /// Calculate optimal chunk shape
  static List<int> _calculateOptimalChunkShape(
      Shape shape, int targetElements) {
    List<int> chunkShape = List.from(shape.toList());
    int currentSize = shape.size;

    // Reduce dimensions from first to last until we're under target
    for (int dim = 0; dim < shape.ndim && currentSize > targetElements; dim++) {
      int reduction = (currentSize / targetElements).ceil();
      chunkShape[dim] =
          (chunkShape[dim] / reduction).ceil().clamp(1, shape[dim]);
      currentSize = chunkShape.reduce((a, b) => a * b);
    }

    return chunkShape;
  }

  /// Get chunk index for given data indices
  List<int> _getChunkIndex(List<int> indices) {
    List<int> chunkIndex = [];
    for (int i = 0; i < indices.length; i++) {
      chunkIndex.add(indices[i] ~/ chunkShape[i]);
    }
    return chunkIndex;
  }

  /// Get local indices within a chunk
  List<int> _getLocalIndices(List<int> indices, List<int> chunkIndex) {
    List<int> localIndices = [];
    for (int i = 0; i < indices.length; i++) {
      localIndices.add(indices[i] - chunkIndex[i] * chunkShape[i]);
    }
    return localIndices;
  }

  /// Load a chunk into cache
  Future<Chunk> _loadChunk(List<int> chunkIndex) async {
    // Try to get from cache
    final cached = chunkManager.getChunk(chunkIndex);
    if (cached != null) {
      trackCacheHit();
      return cached;
    }

    trackCacheMiss();

    // Check memory pressure before loading
    MemoryMonitor.checkMemoryPressure();

    // Load chunk data
    List<double> chunkData;
    if (_allData != null) {
      chunkData = _extractChunkFromAllData(chunkIndex);
    } else if (dataProvider != null) {
      chunkData = await dataProvider!(chunkIndex);
    } else {
      // Create empty chunk
      chunkData = List.filled(_chunkSize, 0.0);
    }

    // Create chunk
    final chunk = Chunk(
      data: chunkData,
      shape: chunkShape,
      index: chunkIndex,
      sizeBytes: chunkData.length * 8,
    );

    // Add to cache
    chunkManager.putChunk(chunk);

    return chunk;
  }

  /// Extract chunk from all data
  List<double> _extractChunkFromAllData(List<int> chunkIndex) {
    List<double> chunkData = [];

    // Calculate start indices for this chunk
    List<int> startIndices = [];
    for (int i = 0; i < shape.ndim; i++) {
      startIndices.add(chunkIndex[i] * chunkShape[i]);
    }

    // Extract data for this chunk
    _extractChunkData(startIndices, [], 0, chunkData);

    return chunkData;
  }

  /// Recursively extract chunk data
  void _extractChunkData(
    List<int> startIndices,
    List<int> currentOffsets,
    int dim,
    List<double> output,
  ) {
    if (dim == shape.ndim) {
      List<int> globalIndices = [];
      for (int i = 0; i < shape.ndim; i++) {
        globalIndices.add(startIndices[i] + currentOffsets[i]);
      }

      // Check if within bounds
      bool inBounds = true;
      for (int i = 0; i < shape.ndim; i++) {
        if (globalIndices[i] >= shape[i]) {
          inBounds = false;
          break;
        }
      }

      if (inBounds) {
        int flatIndex = shape.toFlatIndex(globalIndices);
        final value = _allData![flatIndex];
        output.add((value as num).toDouble());
      } else {
        output.add(0.0); // Padding for out-of-bounds
      }
      return;
    }

    for (int i = 0; i < chunkShape[dim]; i++) {
      _extractChunkData(
        startIndices,
        [...currentOffsets, i],
        dim + 1,
        output,
      );
    }
  }

  /// Track access pattern
  void _trackAccess(List<int> chunkIndex) {
    _lastChunkIndex = chunkIndex;
    _accessHistory.add(List.from(chunkIndex));

    // Keep history limited
    if (_accessHistory.length > _maxHistorySize) {
      _accessHistory.removeAt(0);
    }
  }

  /// Prefetch next chunks based on access pattern
  void _prefetchNextChunks(List<int> currentChunk) {
    if (_lastChunkIndex == null) return;

    // Detect access pattern
    final pattern = _detectAccessPattern();

    // Generate prefetch indices
    final prefetchIndices = _generatePrefetchIndices(currentChunk, pattern);

    // Prefetch asynchronously (don't await)
    _prefetchChunks(prefetchIndices);
  }

  /// Detect access pattern from history
  AccessPattern _detectAccessPattern() {
    if (_accessHistory.length < 2) {
      return AccessPattern.random;
    }

    // Check if sequential along any dimension
    for (int dim = 0; dim < shape.ndim; dim++) {
      bool sequential = true;
      for (int i = 1; i < _accessHistory.length; i++) {
        final diff = _accessHistory[i][dim] - _accessHistory[i - 1][dim];
        if (diff != 1 && diff != 0) {
          sequential = false;
          break;
        }
      }
      if (sequential) {
        return AccessPattern.sequential;
      }
    }

    return AccessPattern.random;
  }

  /// Generate prefetch indices based on pattern
  List<List<int>> _generatePrefetchIndices(
    List<int> currentChunk,
    AccessPattern pattern,
  ) {
    final indices = <List<int>>[];

    if (pattern == AccessPattern.sequential) {
      // Prefetch along the sequential dimension
      for (int i = 1; i <= prefetchDistance; i++) {
        final nextChunk = List<int>.from(currentChunk);

        // Try each dimension
        for (int dim = 0; dim < shape.ndim; dim++) {
          nextChunk[dim] += i;

          // Check bounds
          if (nextChunk[dim] < _numChunks[dim]) {
            indices.add(List.from(nextChunk));
          }

          nextChunk[dim] = currentChunk[dim]; // Reset
        }
      }
    }

    return indices;
  }

  /// Prefetch chunks asynchronously
  Future<void> _prefetchChunks(List<List<int>> indices) async {
    if (indices.isEmpty) return;

    await chunkManager.prefetch(indices, (index) async {
      return await _loadChunk(index);
    });
  }

  @override
  dynamic getValue(List<int> indices) {
    trackGet();

    var chunkIndex = _getChunkIndex(indices);
    var localIndices = _getLocalIndices(indices, chunkIndex);

    // Synchronous path when data is pre-loaded
    if (_allData != null) {
      // Try cache first
      var cached = chunkManager.getChunk(chunkIndex);
      List<double> chunkData;

      if (cached != null) {
        trackCacheHit();
        chunkData = cached.data;
      } else {
        trackCacheMiss();
        // Extract from _allData synchronously
        chunkData = _extractChunkFromAllData(chunkIndex);
        final chunk = Chunk(
          data: chunkData,
          shape: chunkShape,
          index: chunkIndex,
          sizeBytes: chunkData.length * 8,
        );
        chunkManager.putChunk(chunk);
      }

      // Calculate flat index within chunk
      int localFlatIndex = 0;
      int stride = 1;
      for (int i = localIndices.length - 1; i >= 0; i--) {
        localFlatIndex += localIndices[i] * stride;
        stride *= chunkShape[i];
      }

      return chunkData[localFlatIndex.clamp(0, chunkData.length - 1)];
    }

    // Async path for lazy loading - not supported in synchronous interface
    throw StateError(
        'ChunkedBackend with lazy loading (dataProvider) requires async operations. '
        'Use ChunkedBackend with initialData for synchronous access, or implement '
        'AsyncStorageBackend for lazy loading support.');
  }

  @override
  void setValue(List<int> indices, dynamic value) {
    trackSet();

    var chunkIndex = _getChunkIndex(indices);
    var localIndices = _getLocalIndices(indices, chunkIndex);

    // Load chunk synchronously (will use cached if available)
    final cached = chunkManager.getChunk(chunkIndex);

    List<double> chunkData;
    if (cached != null) {
      chunkData = cached.data;
    } else if (_allData != null) {
      chunkData = _extractChunkFromAllData(chunkIndex);
      final chunk = Chunk(
        data: chunkData,
        shape: chunkShape,
        index: chunkIndex,
        sizeBytes: chunkData.length * 8,
      );
      chunkManager.putChunk(chunk);
    } else {
      throw StateError('Cannot set value without data loaded or cached');
    }

    // Calculate flat index within chunk
    int localFlatIndex = 0;
    int stride = 1;
    for (int i = localIndices.length - 1; i >= 0; i--) {
      localFlatIndex += localIndices[i] * stride;
      stride *= chunkShape[i];
    }

    chunkData[localFlatIndex] = (value as num).toDouble();

    // Update all data if present
    if (_allData != null) {
      int globalFlatIndex = shape.toFlatIndex(indices);
      _allData![globalFlatIndex] = value;
    }
  }

  @override
  StorageBackend getSlice(List<SliceSpec> slices) {
    // For simplicity, load all data and slice
    // A more sophisticated implementation would slice chunks
    if (_allData == null) {
      throw UnsupportedError(
          'Slicing not supported for chunked backend without all data loaded');
    }

    // Delegate to InMemoryBackend for slicing
    var inMemory = InMemoryBackend(_allData!, shape);
    return inMemory.getSlice(slices);
  }

  @override
  Future<void> load() async {
    if (_allData != null) return;

    // Load all chunks
    _allData = List.filled(shape.size, null);

    for (int i = 0; i < _totalChunks; i++) {
      var chunkIndex = _flatIndexToChunkIndex(i);
      var chunk = await _loadChunk(chunkIndex);

      // Copy chunk data to all data
      _copyChunkToAllData(chunkIndex, chunk.data);
    }
  }

  int get _totalChunks => _numChunks.reduce((a, b) => a * b);

  List<int> _flatIndexToChunkIndex(int flatIndex) {
    List<int> chunkIndex = [];
    int remaining = flatIndex;

    for (int i = _numChunks.length - 1; i >= 0; i--) {
      int stride = 1;
      for (int j = i + 1; j < _numChunks.length; j++) {
        stride *= _numChunks[j];
      }
      chunkIndex.insert(0, remaining ~/ stride);
      remaining %= stride;
    }

    return chunkIndex;
  }

  void _copyChunkToAllData(List<int> chunkIndex, List<double> chunk) {
    List<int> startIndices = [];
    for (int i = 0; i < shape.ndim; i++) {
      startIndices.add(chunkIndex[i] * chunkShape[i]);
    }

    int chunkIdx = 0;
    _copyChunkDataRecursive(startIndices, [], 0, chunk, chunkIdx);
  }

  void _copyChunkDataRecursive(
    List<int> startIndices,
    List<int> currentOffsets,
    int dim,
    List<double> chunk,
    int chunkIdx,
  ) {
    if (dim == shape.ndim) {
      List<int> globalIndices = [];
      for (int i = 0; i < shape.ndim; i++) {
        globalIndices.add(startIndices[i] + currentOffsets[i]);
      }

      bool inBounds = true;
      for (int i = 0; i < shape.ndim; i++) {
        if (globalIndices[i] >= shape[i]) {
          inBounds = false;
          break;
        }
      }

      if (inBounds && chunkIdx < chunk.length) {
        int flatIndex = shape.toFlatIndex(globalIndices);
        _allData![flatIndex] = chunk[chunkIdx];
      }
      return;
    }

    for (int i = 0; i < chunkShape[dim]; i++) {
      _copyChunkDataRecursive(
        startIndices,
        [...currentOffsets, i],
        dim + 1,
        chunk,
        chunkIdx++,
      );
    }
  }

  @override
  Future<void> unload() async {
    chunkManager.clearCache();
    _allData = null;
    MemoryMonitor.unregisterBackend(this);
  }

  @override
  List<dynamic> getFlatData({bool copy = false}) {
    if (_allData == null) {
      throw StateError('Data not loaded. Call load() first.');
    }
    return copy ? List.from(_allData!) : _allData!;
  }

  @override
  int get memoryUsage {
    int allDataSize = _allData?.length ?? 0;
    return chunkManager.memoryUsage +
        (allDataSize * 8) +
        1000; // Cache + data + overhead
  }

  @override
  bool get isInMemory => _allData != null;

  /// Number of chunks currently in cache
  int get cachedChunkCount => chunkManager.cacheSize;

  /// Maximum number of chunks that can be cached
  int get maxCachedChunks => chunkManager.maxCachedChunks;

  /// Get cache statistics
  ChunkCacheStats get cacheStats => chunkManager.stats;

  /// Get access pattern
  AccessPattern get accessPattern => _detectAccessPattern();

  /// Clear the cache
  void clearCache() {
    chunkManager.clearCache();
  }

  @override
  ChunkedBackend clone() {
    return ChunkedBackend(
      shape: shape,
      chunkShape: chunkShape,
      maxMemoryBytes: chunkManager.maxMemoryBytes,
      maxCachedChunks: chunkManager.maxCachedChunks,
      dataProvider: dataProvider,
      enablePrefetching: enablePrefetching,
      prefetchDistance: prefetchDistance,
      initialData: _allData != null ? List.from(_allData!) : null,
    );
  }

  @override
  String toString() {
    return 'ChunkedBackend('
        'shape: $shape, '
        'chunkShape: $chunkShape, '
        'cached: $cachedChunkCount/${chunkManager.maxCachedChunks}, '
        'hitRate: ${(chunkManager.hitRate * 100).toStringAsFixed(1)}%, '
        'memory: ${_formatBytes(memoryUsage)}, '
        'pattern: $accessPattern'
        ')';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Access pattern types
enum AccessPattern {
  sequential,
  random,
  strided,
}
