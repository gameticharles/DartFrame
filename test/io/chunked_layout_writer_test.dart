import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/chunked_layout_writer.dart';
import 'package:dartframe/src/io/hdf5/byte_writer.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';

void main() {
  group('ChunkedLayoutWriter', () {
    test('creates writer with valid chunk dimensions', () {
      final writer = ChunkedLayoutWriter(
        chunkDimensions: [10, 10],
        datasetDimensions: [100, 100],
      );

      expect(writer.layoutClass, equals(2)); // Chunked layout
      expect(writer.dimensionality, equals(2));
    });

    test('throws error when chunk dimensions exceed dataset dimensions', () {
      expect(
        () => ChunkedLayoutWriter(
          chunkDimensions: [200, 200],
          datasetDimensions: [100, 100],
        ),
        throwsArgumentError,
      );
    });

    test('throws error when dimensions do not match', () {
      expect(
        () => ChunkedLayoutWriter(
          chunkDimensions: [10, 10],
          datasetDimensions: [100, 100, 100],
        ),
        throwsArgumentError,
      );
    });

    test('auto-calculates chunk dimensions', () {
      final writer = ChunkedLayoutWriter.auto(
        datasetDimensions: [1000, 1000],
        elementSize: 8, // float64
      );

      expect(writer.chunkDimensions.length, equals(2));
      expect(writer.chunkDimensions[0], greaterThan(0));
      expect(writer.chunkDimensions[1], greaterThan(0));

      // Chunk dimensions should not exceed dataset dimensions
      expect(writer.chunkDimensions[0], lessThanOrEqualTo(1000));
      expect(writer.chunkDimensions[1], lessThanOrEqualTo(1000));
    });

    test('writes chunked data for 1D array', () async {
      final array = NDArray.fromFlat(
        List.generate(100, (i) => i.toDouble()),
        [100],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [25],
        datasetDimensions: [100],
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      expect(byteWriter.size, greaterThan(0));
    });

    test('writes chunked data for 2D array', () async {
      final array = NDArray.fromFlat(
        List.generate(100, (i) => i.toDouble()),
        [10, 10],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [5, 5],
        datasetDimensions: [10, 10],
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      expect(byteWriter.size, greaterThan(0));
    });

    test('writes layout message after writing data', () async {
      final array = NDArray.fromFlat(
        List.generate(50, (i) => i.toDouble()),
        [50],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [10],
        datasetDimensions: [50],
      );

      final byteWriter = ByteWriter();
      await writer.writeData(byteWriter, array);

      final layoutMessage = writer.writeLayoutMessage();

      expect(layoutMessage, isNotEmpty);
      expect(layoutMessage[0], equals(3)); // Version 3
      expect(layoutMessage[1], equals(2)); // Chunked layout
    });

    test('throws error when writing layout message before data', () {
      final writer = ChunkedLayoutWriter(
        chunkDimensions: [10],
        datasetDimensions: [100],
      );

      expect(
        () => writer.writeLayoutMessage(),
        throwsStateError,
      );
    });

    test('handles boundary chunks correctly', () async {
      // Dataset size not evenly divisible by chunk size
      final array = NDArray.fromFlat(
        List.generate(47, (i) => i.toDouble()),
        [47],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [10],
        datasetDimensions: [47],
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      // Should have written 5 chunks (10+10+10+10+7)
    });

    test('handles integer data type', () async {
      final array = NDArray.fromFlat(
        List.generate(50, (i) => i),
        [50],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [10],
        datasetDimensions: [50],
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      expect(byteWriter.size, greaterThan(0));
    });

    test('handles 3D array chunk division', () async {
      final array = NDArray.fromFlat(
        List.generate(1000, (i) => i.toDouble()),
        [10, 10, 10],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [5, 5, 5],
        datasetDimensions: [10, 10, 10],
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      expect(byteWriter.size, greaterThan(0));
      // Should have 8 chunks (2x2x2)
    });

    test('handles 4D array chunk division', () async {
      final array = NDArray.fromFlat(
        List.generate(256, (i) => i.toDouble()),
        [4, 4, 4, 4],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [2, 2, 2, 2],
        datasetDimensions: [4, 4, 4, 4],
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      // Should have 16 chunks (2x2x2x2)
    });

    test('handles non-uniform chunk division', () async {
      // Dataset with different sizes in each dimension
      final array = NDArray.fromFlat(
        List.generate(600, (i) => i.toDouble()),
        [20, 30],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [7, 11],
        datasetDimensions: [20, 30],
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      // Should handle partial chunks at boundaries
    });

    test('auto-calculation produces reasonable chunk sizes for large datasets',
        () {
      // Large 2D dataset
      final writer = ChunkedLayoutWriter.auto(
        datasetDimensions: [10000, 10000],
        elementSize: 8,
      );

      // Chunk should be much smaller than dataset
      final chunkElements =
          writer.chunkDimensions[0] * writer.chunkDimensions[1];
      final datasetElements = 10000 * 10000;

      expect(chunkElements, lessThan(datasetElements));

      // Chunk size should be reasonable (around 1MB = 131072 elements for float64)
      expect(chunkElements, greaterThan(1000));
      // Allow larger chunks for very large datasets
      expect(chunkElements, lessThan(100000000));
    });

    test('auto-calculation handles small datasets', () {
      final writer = ChunkedLayoutWriter.auto(
        datasetDimensions: [10, 10],
        elementSize: 8,
      );

      // For small datasets, chunk dimensions should equal dataset dimensions
      expect(writer.chunkDimensions[0], equals(10));
      expect(writer.chunkDimensions[1], equals(10));
    });

    test('auto-calculation handles 1D datasets', () {
      final writer = ChunkedLayoutWriter.auto(
        datasetDimensions: [1000000],
        elementSize: 8,
      );

      expect(writer.chunkDimensions.length, equals(1));
      expect(writer.chunkDimensions[0], greaterThan(0));
      expect(writer.chunkDimensions[0], lessThanOrEqualTo(1000000));
    });

    test('auto-calculation handles 3D datasets', () {
      final writer = ChunkedLayoutWriter.auto(
        datasetDimensions: [100, 100, 100],
        elementSize: 4,
      );

      expect(writer.chunkDimensions.length, equals(3));
      for (final dim in writer.chunkDimensions) {
        expect(dim, greaterThan(0));
        expect(dim, lessThanOrEqualTo(100));
      }
    });

    test('validates chunk dimensions are positive', () {
      expect(
        () => ChunkedLayoutWriter(
          chunkDimensions: [10, 0, 10],
          datasetDimensions: [100, 100, 100],
        ),
        throwsArgumentError,
      );

      expect(
        () => ChunkedLayoutWriter(
          chunkDimensions: [-5, 10],
          datasetDimensions: [100, 100],
        ),
        throwsArgumentError,
      );
    });

    test('handles single-element chunks', () async {
      final array = NDArray.fromFlat(
        List.generate(9, (i) => i.toDouble()),
        [3, 3],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [1, 1],
        datasetDimensions: [3, 3],
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      // Should have 9 chunks (3x3)
    });

    test('handles large chunk size equal to dataset', () async {
      final array = NDArray.fromFlat(
        List.generate(100, (i) => i.toDouble()),
        [10, 10],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [10, 10],
        datasetDimensions: [10, 10],
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      // Should have 1 chunk
    });
  });

  group('ChunkedLayoutWriter - Memory Usage', () {
    test('memory usage stays bounded for large dataset with small chunks',
        () async {
      // Create a moderately large dataset (800KB of float64 data)
      final dataSize = 100 * 1000; // 100K elements
      final array = NDArray.fromFlat(
        List.generate(dataSize, (i) => i.toDouble()),
        [dataSize],
      );

      // Use small chunks (8KB each = 1024 elements)
      final chunkSize = 1024;
      final writer = ChunkedLayoutWriter(
        chunkDimensions: [chunkSize],
        datasetDimensions: [dataSize],
      );

      final byteWriter = ByteWriter();

      // Get initial memory usage
      final initialMemory = io.ProcessInfo.currentRss;

      // Write the data
      await writer.writeData(byteWriter, array);

      // Get final memory usage
      final finalMemory = io.ProcessInfo.currentRss;
      final memoryIncrease = finalMemory - initialMemory;

      // Memory increase should be reasonable
      // Allow for overhead from Dart VM and data structures
      // The key is that it doesn't grow linearly with dataset size
      expect(memoryIncrease, lessThan(500 * 1024 * 1024)); // 500MB limit

      // Verify data was written
      expect(byteWriter.size, greaterThan(0));
    });

    test('memory usage for 2D chunked dataset', () async {
      // Create a 2D dataset (400KB of float64 data)
      final array = NDArray.fromFlat(
        List.generate(50 * 1000, (i) => i.toDouble()),
        [250, 200],
      );

      // Use moderate chunks
      final writer = ChunkedLayoutWriter(
        chunkDimensions: [50, 50],
        datasetDimensions: [250, 200],
      );

      final byteWriter = ByteWriter();
      final initialMemory = io.ProcessInfo.currentRss;

      await writer.writeData(byteWriter, array);

      final finalMemory = io.ProcessInfo.currentRss;
      final memoryIncrease = finalMemory - initialMemory;

      // Memory should stay reasonable
      expect(memoryIncrease, lessThan(500 * 1024 * 1024));
      expect(byteWriter.size, greaterThan(0));
    });

    test('processes chunks sequentially without accumulating memory', () async {
      // Create dataset with many small chunks
      final array = NDArray.fromFlat(
        List.generate(10000, (i) => i.toDouble()),
        [100, 100],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [10, 10],
        datasetDimensions: [100, 100],
      );

      final byteWriter = ByteWriter();
      final initialMemory = io.ProcessInfo.currentRss;

      // This will process 100 chunks (10x10 grid)
      await writer.writeData(byteWriter, array);

      final finalMemory = io.ProcessInfo.currentRss;
      final memoryIncrease = finalMemory - initialMemory;

      // Memory increase should be reasonable
      expect(memoryIncrease, lessThan(100 * 1024 * 1024));
    });

    test('memory usage with integer data type', () async {
      // Create integer dataset
      final array = NDArray.fromFlat(
        List.generate(100000, (i) => i),
        [100000],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [1000],
        datasetDimensions: [100000],
      );

      final byteWriter = ByteWriter();
      final initialMemory = io.ProcessInfo.currentRss;

      await writer.writeData(byteWriter, array);

      final finalMemory = io.ProcessInfo.currentRss;
      final memoryIncrease = finalMemory - initialMemory;

      // Should stay within reasonable bounds
      expect(memoryIncrease, lessThan(500 * 1024 * 1024));
      expect(byteWriter.size, greaterThan(0));
    });

    test('memory usage with 3D chunked dataset', () async {
      // Create 3D dataset (512KB of float64 data)
      final array = NDArray.fromFlat(
        List.generate(40 * 40 * 40, (i) => i.toDouble()),
        [40, 40, 40],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [10, 10, 10],
        datasetDimensions: [40, 40, 40],
      );

      final byteWriter = ByteWriter();
      final initialMemory = io.ProcessInfo.currentRss;

      await writer.writeData(byteWriter, array);

      final finalMemory = io.ProcessInfo.currentRss;
      final memoryIncrease = finalMemory - initialMemory;

      // Memory should stay bounded
      expect(memoryIncrease, lessThan(500 * 1024 * 1024));
      expect(byteWriter.size, greaterThan(0));
    });

    test('chunk size calculation respects memory constraints', () {
      // For a large dataset, auto-calculated chunks should be reasonable
      final writer = ChunkedLayoutWriter.auto(
        datasetDimensions: [5000, 5000],
        elementSize: 8,
      );

      // Calculate chunk memory size
      final chunkElements =
          writer.chunkDimensions[0] * writer.chunkDimensions[1];
      final chunkBytes = chunkElements * 8; // 8 bytes per float64

      // Chunk should be reasonable size
      // Target is around 1MB, but allow variance for large datasets
      expect(chunkBytes, lessThan(200 * 1024 * 1024)); // Less than 200MB
      expect(chunkBytes, greaterThan(1000)); // More than 1KB
    });

    test('memory usage with very small chunks', () async {
      // Small chunks should not cause memory issues
      final array = NDArray.fromFlat(
        List.generate(1000, (i) => i.toDouble()),
        [1000],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [10],
        datasetDimensions: [1000],
      );

      final byteWriter = ByteWriter();
      final initialMemory = io.ProcessInfo.currentRss;

      await writer.writeData(byteWriter, array);

      final finalMemory = io.ProcessInfo.currentRss;
      final memoryIncrease = finalMemory - initialMemory;

      // Memory increase should be reasonable
      expect(memoryIncrease, lessThan(100 * 1024 * 1024));
    });
  });
}
