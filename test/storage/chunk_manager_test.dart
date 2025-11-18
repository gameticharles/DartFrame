import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  group('Chunk', () {
    test('creates chunk with metadata', () {
      final chunk = Chunk(
        data: [1.0, 2.0, 3.0, 4.0],
        shape: [2, 2],
        index: [0, 0],
        sizeBytes: 32,
      );

      expect(chunk.data.length, equals(4));
      expect(chunk.shape, equals([2, 2]));
      expect(chunk.index, equals([0, 0]));
      expect(chunk.sizeBytes, equals(32));
    });

    test('generates correct key', () {
      final chunk = Chunk(
        data: [1.0],
        shape: [1],
        index: [0, 1, 2],
        sizeBytes: 8,
      );

      expect(chunk.key, equals('0,1,2'));
    });

    test('touch updates last access time', () {
      final chunk = Chunk(
        data: [1.0],
        shape: [1],
        index: [0],
        sizeBytes: 8,
      );

      final firstAccess = chunk.lastAccess;
      Future.delayed(Duration(milliseconds: 10), () {
        chunk.touch();
        expect(chunk.lastAccess.isAfter(firstAccess), isTrue);
      });
    });
  });

  group('ChunkManager', () {
    late ChunkManager manager;

    setUp(() {
      manager = ChunkManager(
        maxMemoryBytes: 1000,
        maxCachedChunks: 3,
      );
    });

    test('initializes with correct settings', () {
      expect(manager.maxMemoryBytes, equals(1000));
      expect(manager.maxCachedChunks, equals(3));
      expect(manager.cacheSize, equals(0));
      expect(manager.memoryUsage, equals(0));
    });

    test('getChunk returns null for uncached chunk', () {
      final chunk = manager.getChunk([0, 0]);
      expect(chunk, isNull);
    });

    test('putChunk adds chunk to cache', () {
      final chunk = Chunk(
        data: [1.0, 2.0, 3.0, 4.0],
        shape: [2, 2],
        index: [0, 0],
        sizeBytes: 32,
      );

      manager.putChunk(chunk);

      expect(manager.cacheSize, equals(1));
      expect(manager.memoryUsage, equals(32));
      expect(manager.contains([0, 0]), isTrue);
    });

    test('getChunk returns cached chunk', () {
      final chunk = Chunk(
        data: [1.0, 2.0, 3.0, 4.0],
        shape: [2, 2],
        index: [0, 0],
        sizeBytes: 32,
      );

      manager.putChunk(chunk);

      final retrieved = manager.getChunk([0, 0]);
      expect(retrieved, isNotNull);
      expect(retrieved!.data, equals([1.0, 2.0, 3.0, 4.0]));
    });

    test('evicts LRU chunk when cache is full', () {
      // Add 3 chunks (max capacity)
      for (int i = 0; i < 3; i++) {
        final chunk = Chunk(
          data: List.filled(10, i.toDouble()),
          shape: [10],
          index: [i],
          sizeBytes: 80,
        );
        manager.putChunk(chunk);
      }

      expect(manager.cacheSize, equals(3));
      expect(manager.memoryUsage, equals(240));

      // Add 4th chunk, should evict first chunk
      final chunk4 = Chunk(
        data: List.filled(10, 3.0),
        shape: [10],
        index: [3],
        sizeBytes: 80,
      );
      manager.putChunk(chunk4);

      expect(manager.cacheSize, equals(3));
      expect(manager.contains([0]), isFalse); // First chunk evicted
      expect(manager.contains([3]), isTrue); // New chunk added
    });

    test('evicts chunk when memory limit exceeded', () {
      final manager = ChunkManager(
        maxMemoryBytes: 200,
        maxCachedChunks: 10,
      );

      // Add chunks until memory limit
      for (int i = 0; i < 3; i++) {
        final chunk = Chunk(
          data: List.filled(10, i.toDouble()),
          shape: [10],
          index: [i],
          sizeBytes: 80,
        );
        manager.putChunk(chunk);
      }

      expect(manager.cacheSize, lessThanOrEqualTo(3));
      expect(manager.memoryUsage, lessThanOrEqualTo(200));
    });

    test('evictChunk removes specific chunk', () {
      final chunk = Chunk(
        data: [1.0, 2.0],
        shape: [2],
        index: [0, 0],
        sizeBytes: 16,
      );

      manager.putChunk(chunk);
      expect(manager.contains([0, 0]), isTrue);

      manager.evictChunk([0, 0]);
      expect(manager.contains([0, 0]), isFalse);
      expect(manager.cacheSize, equals(0));
      expect(manager.memoryUsage, equals(0));
    });

    test('clearCache removes all chunks', () {
      for (int i = 0; i < 3; i++) {
        final chunk = Chunk(
          data: [i.toDouble()],
          shape: [1],
          index: [i],
          sizeBytes: 8,
        );
        manager.putChunk(chunk);
      }

      expect(manager.cacheSize, equals(3));

      manager.clearCache();

      expect(manager.cacheSize, equals(0));
      expect(manager.memoryUsage, equals(0));
    });

    test('tracks cache statistics', () {
      final chunk = Chunk(
        data: [1.0],
        shape: [1],
        index: [0],
        sizeBytes: 8,
      );

      manager.putChunk(chunk);

      // Hit
      manager.getChunk([0]);
      expect(manager.stats.hits, equals(1));
      expect(manager.stats.misses, equals(0));

      // Miss
      manager.getChunk([1]);
      expect(manager.stats.hits, equals(1));
      expect(manager.stats.misses, equals(1));

      expect(manager.hitRate, equals(0.5));
    });

    test('resetStats clears statistics', () {
      final chunk = Chunk(
        data: [1.0],
        shape: [1],
        index: [0],
        sizeBytes: 8,
      );

      manager.putChunk(chunk);
      manager.getChunk([0]); // Hit
      manager.getChunk([1]); // Miss

      expect(manager.stats.hits, equals(1));
      expect(manager.stats.misses, equals(1));

      manager.resetStats();

      expect(manager.stats.hits, equals(0));
      expect(manager.stats.misses, equals(0));
    });

    test('getCachedIndices returns all cached chunk indices', () {
      for (int i = 0; i < 3; i++) {
        final chunk = Chunk(
          data: [i.toDouble()],
          shape: [1],
          index: [i, i],
          sizeBytes: 8,
        );
        manager.putChunk(chunk);
      }

      final indices = manager.getCachedIndices();
      expect(indices.length, equals(3));

      // Check that indices contain the expected values
      expect(indices.any((idx) => idx[0] == 0 && idx[1] == 0), isTrue);
      expect(indices.any((idx) => idx[0] == 1 && idx[1] == 1), isTrue);
      expect(indices.any((idx) => idx[0] == 2 && idx[1] == 2), isTrue);
    });

    test('prefetch loads multiple chunks', () async {
      int loadCount = 0;

      Future<Chunk> loader(List<int> index) async {
        loadCount++;
        return Chunk(
          data: [index[0].toDouble()],
          shape: [1],
          index: index,
          sizeBytes: 8,
        );
      }

      await manager.prefetch([
        [0],
        [1],
        [2]
      ], loader);

      expect(loadCount, equals(3));
      expect(manager.cacheSize, equals(3));
      expect(manager.contains([0]), isTrue);
      expect(manager.contains([1]), isTrue);
      expect(manager.contains([2]), isTrue);
    });

    test('prefetch skips already cached chunks', () async {
      // Pre-cache one chunk
      final chunk = Chunk(
        data: [0.0],
        shape: [1],
        index: [0],
        sizeBytes: 8,
      );
      manager.putChunk(chunk);

      int loadCount = 0;

      Future<Chunk> loader(List<int> index) async {
        loadCount++;
        return Chunk(
          data: [index[0].toDouble()],
          shape: [1],
          index: index,
          sizeBytes: 8,
        );
      }

      await manager.prefetch([
        [0],
        [1],
        [2]
      ], loader);

      // Should only load 2 new chunks (1 was already cached)
      expect(loadCount, equals(2));
      expect(manager.cacheSize, equals(3));
    });
  });

  group('ChunkCacheStats', () {
    test('calculates memory usage percent', () {
      final stats = ChunkCacheStats(
        hits: 10,
        misses: 5,
        evictions: 2,
        hitRate: 0.667,
        cacheSize: 5,
        memoryUsage: 500,
        maxMemory: 1000,
      );

      expect(stats.memoryUsagePercent, equals(0.5));
    });

    test('toString provides readable output', () {
      final stats = ChunkCacheStats(
        hits: 10,
        misses: 5,
        evictions: 2,
        hitRate: 0.667,
        cacheSize: 5,
        memoryUsage: 1024 * 1024, // 1MB
        maxMemory: 10 * 1024 * 1024, // 10MB
      );

      final str = stats.toString();
      expect(str, contains('hits: 10'));
      expect(str, contains('misses: 5'));
      expect(str, contains('evictions: 2'));
      expect(str, contains('66.7%'));
      expect(str, contains('1.0MB'));
      expect(str, contains('10.0MB'));
    });
  });
}
