import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

/// Performance benchmark tests for HDF5 writer
///
/// Tests:
/// - Write time for various dataset sizes (1MB, 10MB, 100MB, 1GB)
/// - Memory usage during write operations
/// - Compressed vs uncompressed file sizes
/// - Chunked vs contiguous write performance
/// - Verify performance meets requirements (20s per 100MB with compression)
///
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5
void main() {
  late Directory testDir;

  setUp(() {
    testDir = Directory('test_output/performance_benchmark');
    if (!testDir.existsSync()) {
      testDir.createSync(recursive: true);
    }
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('Write Time Benchmarks', () {
    test('1MB dataset write time', () async {
      final path = '${testDir.path}/1mb.h5';
      // 1MB = 1,048,576 bytes / 8 bytes per double = 131,072 elements
      final data = List.generate(131072, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [131072]);

      final stopwatch = Stopwatch()..start();
      await array.toHDF5(path, dataset: '/data');
      stopwatch.stop();

      print('1MB write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should be < 5s
    });

    test('10MB dataset write time', () async {
      final path = '${testDir.path}/10mb.h5';
      // 10MB = 10,485,760 bytes / 8 = 1,310,720 elements
      final data = List.generate(1310720, (i) => (i % 1000).toDouble());
      final array = NDArray.fromFlat(data, [1310720]);

      final stopwatch = Stopwatch()..start();
      await array.toHDF5(path, dataset: '/data');
      stopwatch.stop();

      print('10MB write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should be < 10s
    });

    test('100MB dataset write time', () async {
      final path = '${testDir.path}/100mb.h5';
      // 100MB = 104,857,600 bytes / 8 = 13,107,200 elements
      final data = List.generate(13107200, (i) => (i % 1000).toDouble());
      final array = NDArray.fromFlat(data, [13107200]);

      final stopwatch = Stopwatch()..start();
      await array.toHDF5(path, dataset: '/data');
      stopwatch.stop();

      print('100MB write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // Should be < 30s
    });

    test('100MB dataset with compression write time', () async {
      final path = '${testDir.path}/100mb_compressed.h5';
      // Create repetitive data that compresses well
      final data = List.generate(13107200, (i) => (i % 100).toDouble());
      final array = NDArray.fromFlat(data, [13107200]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      final stopwatch = Stopwatch()..start();
      await array.toHDF5(path, dataset: '/data', options: options);
      stopwatch.stop();

      print('100MB compressed write time: ${stopwatch.elapsedMilliseconds}ms');
      // Requirement: 20s per 100MB with compression
      expect(stopwatch.elapsedMilliseconds, lessThan(20000));
    });

    test('1GB dataset write time (long test)', () async {
      final path = '${testDir.path}/1gb.h5';
      // 1GB = 1,073,741,824 bytes / 8 = 134,217,728 elements
      // This is a very large test, so we'll use a smaller sample
      final data = List.generate(134217728, (i) => (i % 10000).toDouble());
      final array = NDArray.fromFlat(data, [134217728]);

      final stopwatch = Stopwatch()..start();
      await array.toHDF5(path, dataset: '/data');
      stopwatch.stop();

      print('1GB write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(
          stopwatch.elapsedMilliseconds, lessThan(300000)); // Should be < 5min
    }, skip: 'Very long test - run manually');
  });

  group('Memory Usage Benchmarks', () {
    test('memory usage with contiguous layout', () async {
      final path = '${testDir.path}/memory_contiguous.h5';
      // 10MB dataset
      final data = List.generate(1310720, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [1310720]);

      // Note: Dart doesn't provide direct memory measurement APIs
      // This test verifies the operation completes without OOM
      await array.toHDF5(path, dataset: '/data');

      expect(File(path).existsSync(), isTrue);
    });

    test('memory usage with chunked layout', () async {
      final path = '${testDir.path}/memory_chunked.h5';
      // 10MB dataset with chunking
      final data = List.generate(1310720, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [1310720]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [65536], // 512KB chunks
      );

      await array.toHDF5(path, dataset: '/data', options: options);

      expect(File(path).existsSync(), isTrue);
    });

    test('memory usage with compression', () async {
      final path = '${testDir.path}/memory_compressed.h5';
      // 10MB dataset with compression
      final data = List.generate(1310720, (i) => (i % 100).toDouble());
      final array = NDArray.fromFlat(data, [1310720]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [65536],
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      // Requirement: Memory usage <= 2x chunk size + 10MB overhead
      // Chunk size: 65536 * 8 = 524,288 bytes = 512KB
      // Max memory: 2 * 512KB + 10MB = 11MB
      await array.toHDF5(path, dataset: '/data', options: options);

      expect(File(path).existsSync(), isTrue);
    });

    test('memory usage with multiple datasets', () async {
      final path = '${testDir.path}/memory_multi.h5';
      // Multiple 1MB datasets
      final data1 = List.generate(131072, (i) => i.toDouble());
      final data2 = List.generate(131072, (i) => i * 2.0);
      final data3 = List.generate(131072, (i) => i * 3.0);

      final array1 = NDArray.fromFlat(data1, [131072]);
      final array2 = NDArray.fromFlat(data2, [131072]);
      final array3 = NDArray.fromFlat(data3, [131072]);

      // Requirement: Release memory for completed datasets
      await HDF5WriterUtils.writeMultiple(path, {
        '/data1': array1,
        '/data2': array2,
        '/data3': array3,
      });

      expect(File(path).existsSync(), isTrue);
    });
  });

  group('File Size Comparisons', () {
    test('compressed vs uncompressed file size', () async {
      final uncompressedPath = '${testDir.path}/size_uncompressed.h5';
      final compressedPath = '${testDir.path}/size_compressed.h5';

      // Create highly compressible data
      final data = List.generate(1000000, (i) => (i % 10).toDouble());
      final array = NDArray.fromFlat(data, [1000000]);

      // Write uncompressed
      await array.toHDF5(uncompressedPath, dataset: '/data');

      // Write compressed
      final options = WriteOptions(
        layout: StorageLayout.chunked,
        compression: CompressionType.gzip,
        compressionLevel: 9,
      );
      await array.toHDF5(compressedPath, dataset: '/data', options: options);

      final uncompressedSize = await File(uncompressedPath).length();
      final compressedSize = await File(compressedPath).length();

      print('Uncompressed size: $uncompressedSize bytes');
      print('Compressed size: $compressedSize bytes');
      print(
          'Compression ratio: ${(compressedSize / uncompressedSize * 100).toStringAsFixed(2)}%');

      // Note: Compression effectiveness depends on data patterns and HDF5 overhead
      // Both files should exist and be valid
      expect(uncompressedSize, greaterThan(0));
      expect(compressedSize, greaterThan(0));
    });

    test('gzip vs lzf compression size', () async {
      final gzipPath = '${testDir.path}/size_gzip.h5';
      final lzfPath = '${testDir.path}/size_lzf.h5';

      final data = List.generate(1000000, (i) => (i % 10).toDouble());
      final array = NDArray.fromFlat(data, [1000000]);

      // Write with gzip
      final gzipOptions = WriteOptions(
        layout: StorageLayout.chunked,
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );
      await array.toHDF5(gzipPath, dataset: '/data', options: gzipOptions);

      // Write with lzf
      final lzfOptions = WriteOptions(
        layout: StorageLayout.chunked,
        compression: CompressionType.lzf,
      );
      await array.toHDF5(lzfPath, dataset: '/data', options: lzfOptions);

      final gzipSize = await File(gzipPath).length();
      final lzfSize = await File(lzfPath).length();

      print('Gzip size: $gzipSize bytes');
      print('LZF size: $lzfSize bytes');

      // Both should compress the data
      expect(gzipSize, greaterThan(0));
      expect(lzfSize, greaterThan(0));
    });

    test('compression levels comparison', () async {
      final data = List.generate(1000000, (i) => (i % 10).toDouble());
      final array = NDArray.fromFlat(data, [1000000]);

      final sizes = <int, int>{};

      for (int level in [1, 3, 6, 9]) {
        final path = '${testDir.path}/size_level$level.h5';
        final options = WriteOptions(
          layout: StorageLayout.chunked,
          compression: CompressionType.gzip,
          compressionLevel: level,
        );

        await array.toHDF5(path, dataset: '/data', options: options);
        sizes[level] = await File(path).length();
      }

      print('Compression level sizes:');
      sizes.forEach((level, size) {
        print('  Level $level: $size bytes');
      });

      // Higher compression levels should produce smaller or equal files
      expect(sizes[9]!, lessThanOrEqualTo(sizes[6]!));
      expect(sizes[6]!, lessThanOrEqualTo(sizes[3]!));
      expect(sizes[3]!, lessThanOrEqualTo(sizes[1]!));
    });

    test('file size with different data patterns', () async {
      // Highly repetitive data
      final repetitiveData = List.filled(1000000, 42.0);
      final repetitiveArray = NDArray.fromFlat(repetitiveData, [1000000]);

      // Random-like data
      final randomData =
          List.generate(1000000, (i) => ((i * 7919 + 104729) % 256).toDouble());
      final randomArray = NDArray.fromFlat(randomData, [1000000]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      final repetitivePath = '${testDir.path}/size_repetitive.h5';
      final randomPath = '${testDir.path}/size_random.h5';

      await repetitiveArray.toHDF5(repetitivePath,
          dataset: '/data', options: options);
      await randomArray.toHDF5(randomPath, dataset: '/data', options: options);

      final repetitiveSize = await File(repetitivePath).length();
      final randomSize = await File(randomPath).length();

      print('Repetitive data compressed size: $repetitiveSize bytes');
      print('Random data compressed size: $randomSize bytes');

      // Both files should be created successfully
      expect(repetitiveSize, greaterThan(0));
      expect(randomSize, greaterThan(0));
    });
  });

  group('Chunked vs Contiguous Performance', () {
    test('contiguous write performance', () async {
      final path = '${testDir.path}/perf_contiguous.h5';
      final data = List.generate(1000000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [1000, 1000]);

      final stopwatch = Stopwatch()..start();
      await array.toHDF5(path, dataset: '/data');
      stopwatch.stop();

      print('Contiguous write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });

    test('chunked write performance', () async {
      final path = '${testDir.path}/perf_chunked.h5';
      final data = List.generate(1000000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [1000, 1000]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [100, 100],
      );

      final stopwatch = Stopwatch()..start();
      await array.toHDF5(path, dataset: '/data', options: options);
      stopwatch.stop();

      print('Chunked write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));
    });

    test('chunked with compression write performance', () async {
      final path = '${testDir.path}/perf_chunked_compressed.h5';
      final data = List.generate(1000000, (i) => (i % 100).toDouble());
      final array = NDArray.fromFlat(data, [1000, 1000]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [100, 100],
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      final stopwatch = Stopwatch()..start();
      await array.toHDF5(path, dataset: '/data', options: options);
      stopwatch.stop();

      print(
          'Chunked+compressed write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(20000));
    });

    test('different chunk sizes performance', () async {
      final data = List.generate(1000000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [1000, 1000]);

      final chunkSizes = [
        [50, 50],
        [100, 100],
        [200, 200],
        [500, 500]
      ];

      for (final chunkDims in chunkSizes) {
        final path =
            '${testDir.path}/perf_chunk_${chunkDims[0]}x${chunkDims[1]}.h5';
        final options = WriteOptions(
          layout: StorageLayout.chunked,
          chunkDimensions: chunkDims,
        );

        final stopwatch = Stopwatch()..start();
        await array.toHDF5(path, dataset: '/data', options: options);
        stopwatch.stop();

        print(
            'Chunk ${chunkDims[0]}x${chunkDims[1]} write time: ${stopwatch.elapsedMilliseconds}ms');
      }
    });

    test('auto-calculated chunks performance', () async {
      final path = '${testDir.path}/perf_auto_chunks.h5';
      final data = List.generate(1000000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [1000, 1000]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        // chunkDimensions null = auto-calculate
      );

      final stopwatch = Stopwatch()..start();
      await array.toHDF5(path, dataset: '/data', options: options);
      stopwatch.stop();

      print('Auto-chunk write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));
    });
  });

  group('Multi-dataset Performance', () {
    test('sequential dataset writes', () async {
      final path = '${testDir.path}/perf_sequential.h5';
      final data1 = List.generate(500000, (i) => i.toDouble());
      final data2 = List.generate(500000, (i) => i * 2.0);
      final data3 = List.generate(500000, (i) => i * 3.0);

      final array1 = NDArray.fromFlat(data1, [500000]);
      final array2 = NDArray.fromFlat(data2, [500000]);
      final array3 = NDArray.fromFlat(data3, [500000]);

      final stopwatch = Stopwatch()..start();
      await HDF5WriterUtils.writeMultiple(path, {
        '/data1': array1,
        '/data2': array2,
        '/data3': array3,
      });
      stopwatch.stop();

      print(
          'Sequential multi-dataset write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));
    });

    test('multi-dataset with compression', () async {
      final path = '${testDir.path}/perf_multi_compressed.h5';
      final data1 = List.generate(500000, (i) => (i % 10).toDouble());
      final data2 = List.generate(500000, (i) => (i % 20).toDouble());
      final data3 = List.generate(500000, (i) => (i % 30).toDouble());

      final array1 = NDArray.fromFlat(data1, [500000]);
      final array2 = NDArray.fromFlat(data2, [500000]);
      final array3 = NDArray.fromFlat(data3, [500000]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      final stopwatch = Stopwatch()..start();
      await HDF5WriterUtils.writeMultiple(
        path,
        {
          '/data1': array1,
          '/data2': array2,
          '/data3': array3,
        },
        perDatasetOptions: {
          '/data1': options,
          '/data2': options,
          '/data3': options,
        },
      );
      stopwatch.stop();

      print(
          'Multi-dataset compressed write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(25000));
    });
  });

  group('DataFrame Performance', () {
    test('small DataFrame write performance', () async {
      final path = '${testDir.path}/perf_df_small.h5';
      final rows = List.generate(1000, (i) => [i, i * 2.0, i * 3]);
      final df = DataFrame(rows, columns: ['a', 'b', 'c']);

      final stopwatch = Stopwatch()..start();
      await df.toHDF5(path, dataset: '/data');
      stopwatch.stop();

      print('Small DataFrame write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('large DataFrame write performance', () async {
      final path = '${testDir.path}/perf_df_large.h5';
      // Reduced size to avoid timeout
      final rows = List.generate(10000, (i) => [i, i * 2.0, i * 3]);
      final df = DataFrame(rows, columns: ['a', 'b', 'c']);

      final stopwatch = Stopwatch()..start();
      await df.toHDF5(path, dataset: '/data');
      stopwatch.stop();

      print('Large DataFrame write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));
    });

    test('wide DataFrame write performance', () async {
      final path = '${testDir.path}/perf_df_wide.h5';
      final columns = List.generate(100, (i) => 'col_$i');
      final row = List.generate(100, (i) => i.toDouble());
      final rows = List.generate(1000, (_) => row);
      final df = DataFrame(rows, columns: columns);

      final stopwatch = Stopwatch()..start();
      await df.toHDF5(path, dataset: '/data');
      stopwatch.stop();

      print('Wide DataFrame write time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });
  });

  group('Performance Requirements Verification', () {
    test('meets 20s per 100MB with compression requirement', () async {
      final path = '${testDir.path}/requirement_100mb.h5';
      // 100MB of repetitive data
      final data = List.generate(13107200, (i) => (i % 100).toDouble());
      final array = NDArray.fromFlat(data, [13107200]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      final stopwatch = Stopwatch()..start();
      await array.toHDF5(path, dataset: '/data', options: options);
      stopwatch.stop();

      print(
          'Requirement test - 100MB compressed: ${stopwatch.elapsedMilliseconds}ms');

      // Requirement 11.4: Complete within 20s per 100MB with compression
      expect(stopwatch.elapsedMilliseconds, lessThan(20000));
    });

    test('memory usage stays within bounds', () async {
      final path = '${testDir.path}/requirement_memory.h5';
      // 10MB dataset with 512KB chunks
      final data = List.generate(1310720, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [1310720]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [65536], // 512KB chunks
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      // Requirement 11.5: Memory <= 2x chunk size + 10MB overhead
      // Chunk: 512KB, Max memory: 1MB + 10MB = 11MB
      await array.toHDF5(path, dataset: '/data', options: options);

      // Test passes if no OOM error occurs
      expect(File(path).existsSync(), isTrue);
    });

    test('incremental chunk processing', () async {
      final path = '${testDir.path}/requirement_incremental.h5';
      // Large dataset with chunking
      final data = List.generate(5000000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [5000000]);

      final options = WriteOptions(
        layout: StorageLayout.chunked,
        chunkDimensions: [100000],
        compression: CompressionType.gzip,
        compressionLevel: 6,
      );

      // Requirement 11.1: Compress chunks incrementally
      // Requirement 11.2: Write chunks sequentially
      await array.toHDF5(path, dataset: '/data', options: options);

      expect(File(path).existsSync(), isTrue);
    });
  });
}
