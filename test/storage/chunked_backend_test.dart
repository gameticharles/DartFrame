import 'package:test/test.dart';
import 'package:dartframe/src/core/shape.dart';
import 'package:dartframe/src/core/slice_spec.dart';
import 'package:dartframe/src/storage/chunked_backend.dart';

void main() {
  group('ChunkedBackend - Construction', () {
    test('creates with explicit chunk shape', () {
      var backend = ChunkedBackend(
        shape: Shape([100, 100]),
        chunkShape: [10, 10],
        maxCachedChunks: 5,
      );

      expect(backend.shape, equals(Shape([100, 100])));
      expect(backend.chunkShape, equals([10, 10]));
      expect(backend.maxCachedChunks, equals(5));
    });

    test('creates with auto chunk shape', () {
      var backend = ChunkedBackend.auto(
        shape: Shape([1000, 1000]),
        targetChunkBytes: 8000, // 1000 elements * 8 bytes
      );

      expect(backend.shape, equals(Shape([1000, 1000])));
      expect(backend.chunkShape.length, equals(2));
    });

    test('creates with initial data', () {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      expect(backend.isInMemory, isTrue);
    });

    test('throws on mismatched chunk shape dimensions', () {
      expect(
        () => ChunkedBackend(
          shape: Shape([10, 10]),
          chunkShape: [5],
        ),
        throwsArgumentError,
      );
    });

    test('throws on mismatched initial data size', () {
      expect(
        () => ChunkedBackend(
          shape: Shape([10, 10]),
          chunkShape: [5, 5],
          initialData: [1, 2, 3],
        ),
        throwsArgumentError,
      );
    });
  });

  group('ChunkedBackend - getValue/setValue', () {
    test('gets and sets values with initial data', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      var value = await backend.getValue([2, 3]);
      expect(value, equals(23));

      backend.setValue([2, 3], 999);
      value = await backend.getValue([2, 3]);
      expect(value, equals(999));
    });

    test('caches chunks on access', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        maxCachedChunks: 2,
        initialData: data,
      );

      await backend.getValue([0, 0]); // Load chunk [0,0]
      expect(backend.cachedChunkCount, equals(1));

      await backend.getValue([5, 5]); // Load chunk [1,1]
      expect(backend.cachedChunkCount, equals(2));
    });

    test('evicts LRU chunks when cache is full', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        maxCachedChunks: 2,
        initialData: data,
      );

      await backend.getValue([0, 0]); // Chunk [0,0]
      await backend.getValue([5, 5]); // Chunk [1,1]
      await backend.getValue([0, 5]); // Chunk [0,1] - evicts [0,0]

      expect(backend.cachedChunkCount, equals(2));
    });
  });

  group('ChunkedBackend - Statistics', () {
    test('tracks cache hits and misses', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
        enablePrefetching: false, // Disable for predictable cache behavior
      );

      await backend.getValue([0, 0]); // Miss
      await backend.getValue([0, 1]); // Hit (same chunk)
      await backend.getValue([5, 5]); // Miss (different chunk)

      expect(backend.stats.cacheMisses, equals(2));
      expect(backend.stats.cacheHits, equals(1));
    });

    test('tracks getValue calls', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      await backend.getValue([0, 0]);
      await backend.getValue([1, 1]);

      expect(backend.stats.getCount, equals(2));
    });

    test('tracks setValue calls', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      // Load chunks first
      await backend.getValue([0, 0]);
      await backend.getValue([1, 1]);

      backend.setValue([0, 0], 1);
      backend.setValue([1, 1], 2);

      expect(backend.stats.setCount, equals(2));
    });
  });

  group('ChunkedBackend - Memory Management', () {
    test('load loads all data', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      expect(backend.isInMemory, isTrue);
      await backend.load();
      expect(backend.isInMemory, isTrue);
    });

    test('unload clears cache and data', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      await backend.getValue([0, 0]); // Load a chunk
      expect(backend.cachedChunkCount, greaterThan(0));

      await backend.unload();
      expect(backend.cachedChunkCount, equals(0));
      expect(backend.isInMemory, isFalse);
    });

    test('clearCache clears only cache', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      await backend.getValue([0, 0]);
      expect(backend.cachedChunkCount, greaterThan(0));

      backend.clearCache();
      expect(backend.cachedChunkCount, equals(0));
      expect(backend.isInMemory, isTrue); // All data still present
    });

    test('reports memory usage', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      expect(backend.memoryUsage, greaterThan(0));
    });
  });

  group('ChunkedBackend - Data Access', () {
    test('getFlatData returns all data', () {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      var flatData = backend.getFlatData();
      expect(flatData.length, equals(100));
      expect(flatData[0], equals(0));
      expect(flatData[99], equals(99));
    });

    test('getFlatData throws when not loaded', () {
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
      );

      expect(() => backend.getFlatData(), throwsStateError);
    });

    test('getFlatData with copy', () {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      var flatData = backend.getFlatData(copy: true);
      flatData[0] = 999;

      expect(backend.getFlatData()[0], equals(0));
    });
  });

  group('ChunkedBackend - Clone', () {
    test('clones backend', () {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      var cloned = backend.clone();

      expect(cloned.shape, equals(backend.shape));
      expect(cloned.chunkShape, equals(backend.chunkShape));
      expect(cloned.maxCachedChunks, equals(backend.maxCachedChunks));
    });

    test('clone is independent', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      var cloned = backend.clone();

      // Load chunk first
      await backend.getValue([0, 0]);
      backend.setValue([0, 0], 999);
      expect(await cloned.getValue([0, 0]), equals(0));
    });
  });

  group('ChunkedBackend - String Representation', () {
    test('toString includes shape and cache info', () {
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        maxCachedChunks: 5,
      );

      var str = backend.toString();
      expect(str, contains('ChunkedBackend'));
      expect(str, contains('shape'));
      expect(str, contains('cached'));
    });
  });

  group('ChunkedBackend - Edge Cases', () {
    test('handles 1D arrays', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([100]),
        chunkShape: [10],
        initialData: data,
      );

      var value = await backend.getValue([25]);
      expect(value, equals(25));
    });

    test('handles 3D arrays', () async {
      var data = List.generate(1000, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10, 10]),
        chunkShape: [5, 5, 5],
        initialData: data,
      );

      var value = await backend.getValue([2, 3, 4]);
      expect(value, equals(234));
    });

    test('handles chunk shape equal to array shape', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [10, 10],
        initialData: data,
      );

      var value = await backend.getValue([5, 5]);
      expect(value, equals(55));
    });

    test('handles chunk shape of 1', () async {
      var data = List.generate(100, (i) => i);
      var backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [1, 1],
        maxCachedChunks: 5,
        initialData: data,
      );

      var value = await backend.getValue([5, 5]);
      expect(value, equals(55));
    });
  });
}
