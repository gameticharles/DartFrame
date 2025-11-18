import 'package:test/test.dart';
import 'package:dartframe/src/storage/chunked_backend.dart';
import 'package:dartframe/src/core/shape.dart';

void main() {
  group('ChunkedBackend Synchronous Mode', () {
    test('getValue works synchronously with pre-loaded data', () {
      final data = List.generate(100, (i) => i.toDouble());
      final backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      // Should work synchronously
      expect(backend.getValue([0, 0]), 0.0);
      expect(backend.getValue([5, 5]), 55.0);
      expect(backend.getValue([9, 9]), 99.0);
    });

    test('setValue works synchronously with pre-loaded data', () {
      final data = List.generate(100, (i) => i.toDouble());
      final backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      backend.setValue([5, 5], 999.0);
      expect(backend.getValue([5, 5]), 999.0);
    });

    test('getFlatData works with pre-loaded data', () {
      final data = List.generate(100, (i) => i.toDouble());
      final backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      final flatData = backend.getFlatData();
      expect(flatData.length, 100);
      expect(flatData[0], 0.0);
      expect(flatData[99], 99.0);
    });

    test('works with large arrays', () {
      final data = List.generate(10000, (i) => i.toDouble());
      final backend = ChunkedBackend(
        shape: Shape([100, 100]),
        chunkShape: [10, 10],
        initialData: data,
      );

      // Random access should work
      expect(backend.getValue([0, 0]), 0.0);
      expect(backend.getValue([50, 50]), 5050.0);
      expect(backend.getValue([99, 99]), 9999.0);
    });

    test('throws error for lazy loading without data', () {
      final backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        // No initialData, no dataProvider
      );

      expect(
        () => backend.getValue([0, 0]),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('lazy loading'),
        )),
      );
    });

    test('isInMemory returns true with pre-loaded data', () {
      final data = List.generate(100, (i) => i.toDouble());
      final backend = ChunkedBackend(
        shape: Shape([10, 10]),
        chunkShape: [5, 5],
        initialData: data,
      );

      expect(backend.isInMemory, true);
    });

    test('caching works across multiple accesses', () {
      final data = List.generate(1000, (i) => i.toDouble());
      final backend = ChunkedBackend(
        shape: Shape([100, 10]),
        chunkShape: [10, 10],
        initialData: data,
        maxCachedChunks: 5,
      );

      // Access same chunk multiple times
      for (int i = 0; i < 10; i++) {
        expect(backend.getValue([5, 5]), 55.0);
      }

      // Access different chunks
      expect(backend.getValue([15, 5]), 155.0);
      expect(backend.getValue([25, 5]), 255.0);
      expect(backend.getValue([35, 5]), 355.0);
    });

    test('works with 3D arrays', () {
      final data = List.generate(1000, (i) => i.toDouble());
      final backend = ChunkedBackend(
        shape: Shape([10, 10, 10]),
        chunkShape: [5, 5, 5],
        initialData: data,
      );

      expect(backend.getValue([0, 0, 0]), 0.0);
      expect(backend.getValue([5, 5, 5]), 555.0);
      expect(backend.getValue([9, 9, 9]), 999.0);
    });

    test('auto factory creates appropriate chunk sizes', () {
      final data = List.generate(10000, (i) => i.toDouble());
      final backend = ChunkedBackend.auto(
        shape: Shape([100, 100]),
        targetChunkBytes: 1024, // 1KB chunks
        bytesPerElement: 8,
        initialData: data,
      );

      expect(backend.getValue([0, 0]), 0.0);
      expect(backend.getValue([50, 50]), 5050.0);
      expect(backend.isInMemory, true);
    });
  });
}
