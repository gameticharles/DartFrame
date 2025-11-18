import 'package:test/test.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';
import 'package:dartframe/src/core/ndarray_config.dart';
import 'package:dartframe/src/storage/inmemory_backend.dart';
import 'package:dartframe/src/storage/chunked_backend.dart';

void main() {
  group('NDArray with NDArrayConfig Integration', () {
    setUp(() {
      // Reset config before each test
      NDArrayConfig.resetToDefaults();
    });

    test('Small arrays use InMemoryBackend by default', () {
      final arr = NDArray.zeros([10, 10]);
      expect(arr.backend, isA<InMemoryBackend>());
    });

    test('Large arrays use ChunkedBackend when auto-select is enabled', () {
      // Configure to use chunked backend for smaller arrays
      NDArrayConfig.chunkedThreshold = 100; // 100 bytes
      NDArrayConfig.bytesPerElement = 8;

      // Create array larger than threshold (200 elements * 8 bytes = 1600 bytes)
      final arr = NDArray.zeros([200]);
      expect(arr.backend, isA<ChunkedBackend>());

      // Note: ChunkedBackend with initialData works synchronously for basic operations
      // because data is pre-loaded in _allData
    });

    test('Auto-select can be disabled', () {
      NDArrayConfig.autoSelectBackend = false;
      NDArrayConfig.chunkedThreshold = 100;

      // Even large arrays should use InMemory when auto-select is off
      final arr = NDArray.zeros([200]);
      expect(arr.backend, isA<InMemoryBackend>());
    });

    test('fromFlat respects config', () {
      NDArrayConfig.chunkedThreshold = 100;
      NDArrayConfig.bytesPerElement = 8;

      final data = List.generate(200, (i) => i);
      final arr = NDArray.fromFlat(data, [200]);
      expect(arr.backend, isA<ChunkedBackend>());

      // Verify data is accessible synchronously
      expect(arr.getValue([0]), 0);
      expect(arr.getValue([50]), 50);
      expect(arr.getValue([199]), 199);
    });

    test('reshape respects config', () {
      NDArrayConfig.chunkedThreshold = 100;
      NDArrayConfig.bytesPerElement = 8;

      final arr = NDArray.zeros([10, 10]);
      final reshaped = arr.reshape([100]);

      // Should use chunked backend after reshape
      expect(reshaped.backend, isA<ChunkedBackend>());

      // Verify data is accessible
      expect(reshaped.getValue([0]), 0);
      expect(reshaped.getValue([50]), 0);
    });

    test('copyOnWrite config affects reshape', () {
      NDArrayConfig.copyOnWrite = false;
      final arr = NDArray.fromFlat([1, 2, 3, 4], [2, 2]);
      final reshaped = arr.reshape([4]);

      // Verify data is correct
      expect(reshaped.getValue([0]), 1);
      expect(reshaped.getValue([1]), 2);
      expect(reshaped.getValue([2]), 3);
      expect(reshaped.getValue([3]), 4);
    });

    test('filled factory uses config', () {
      NDArrayConfig.chunkedThreshold = 100;
      NDArrayConfig.bytesPerElement = 8;

      final arr = NDArray.filled([200], 42);
      expect(arr.backend, isA<ChunkedBackend>());
      // ChunkedBackend now works synchronously with pre-loaded data
      expect(arr.getValue([0]), 42);
      expect(arr.getValue([100]), 42);
      expect(arr.getValue([199]), 42);
    });

    test('ones factory uses config', () {
      NDArrayConfig.chunkedThreshold = 100;
      NDArrayConfig.bytesPerElement = 8;

      final arr = NDArray.ones([200]);
      expect(arr.backend, isA<ChunkedBackend>());
      // ChunkedBackend now works synchronously with pre-loaded data
      expect(arr.getValue([0]), 1);
      expect(arr.getValue([100]), 1);
      expect(arr.getValue([199]), 1);
    });

    test('generate factory uses config', () {
      NDArrayConfig.chunkedThreshold = 100;
      NDArrayConfig.bytesPerElement = 8;

      final arr = NDArray.generate([200], (indices) => indices[0] * 2);
      expect(arr.backend, isA<ChunkedBackend>());
      // ChunkedBackend now works synchronously with pre-loaded data
      expect(arr.getValue([0]), 0);
      expect(arr.getValue([5]), 10);
      expect(arr.getValue([10]), 20);
      expect(arr.getValue([100]), 200);
    });

    test('map operation uses config', () {
      // Use InMemoryBackend for this test to avoid async issues
      NDArrayConfig.autoSelectBackend = true;
      NDArrayConfig.chunkedThreshold = 10000; // Keep it in memory

      final arr = NDArray.fromFlat(List.generate(20, (i) => i), [20]);
      final mapped = arr.map((x) => x * 2);

      expect(mapped.backend, isA<InMemoryBackend>());
      expect(mapped.getValue([0]), 0);
      expect(mapped.getValue([5]), 10);
      expect(mapped.getValue([10]), 20);
    });

    test('config can be saved and loaded', () {
      NDArrayConfig.maxMemoryBytes = 2 * 1024 * 1024 * 1024;
      NDArrayConfig.defaultChunkSize = 5000;
      NDArrayConfig.autoSelectBackend = false;

      final config = NDArrayConfig.toMap();

      NDArrayConfig.resetToDefaults();
      expect(NDArrayConfig.maxMemoryBytes, 1024 * 1024 * 1024);
      expect(NDArrayConfig.defaultChunkSize, 1000);
      expect(NDArrayConfig.autoSelectBackend, true);

      NDArrayConfig.fromMap(config);
      expect(NDArrayConfig.maxMemoryBytes, 2 * 1024 * 1024 * 1024);
      expect(NDArrayConfig.defaultChunkSize, 5000);
      expect(NDArrayConfig.autoSelectBackend, false);
    });
  });
}
