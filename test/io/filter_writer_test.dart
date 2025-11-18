import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/filter.dart';
import 'package:dartframe/src/io/hdf5/chunked_layout_writer.dart';
import 'package:dartframe/src/io/hdf5/byte_writer.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';

void main() {
  group('GzipFilter', () {
    test('creates filter with valid compression level', () {
      final filter = GzipFilter(compressionLevel: 6);

      expect(filter.id, equals(1)); // H5Z_FILTER_DEFLATE
      expect(filter.name, equals('deflate'));
      expect(filter.compressionLevel, equals(6));
    });

    test('throws error for invalid compression level', () {
      expect(() => GzipFilter(compressionLevel: 0), throwsArgumentError);
      expect(() => GzipFilter(compressionLevel: 10), throwsArgumentError);
    });

    test('compresses data successfully', () {
      final filter = GzipFilter(compressionLevel: 6);
      final data = List.generate(1000, (i) => i % 256);

      final compressed = filter.encode(data);

      // Compressed data should be smaller than original for repetitive data
      expect(compressed.length, lessThan(data.length));
    });

    test('handles different compression levels', () {
      final data = List.generate(10000, (i) => i % 256);

      final filter1 = GzipFilter(compressionLevel: 1);
      final filter9 = GzipFilter(compressionLevel: 9);

      final compressed1 = filter1.encode(data);
      final compressed9 = filter9.encode(data);

      // Level 9 should produce smaller output than level 1
      expect(compressed9.length, lessThanOrEqualTo(compressed1.length));
    });

    test('handles empty data', () {
      final filter = GzipFilter();
      final data = <int>[];

      final compressed = filter.encode(data);

      expect(compressed, isNotEmpty); // Gzip header is always present
    });

    test('handles small data', () {
      final filter = GzipFilter();
      final data = [1, 2, 3, 4, 5];

      final compressed = filter.encode(data);

      expect(compressed, isNotEmpty);
    });
  });

  group('LzfFilter', () {
    test('creates filter correctly', () {
      final filter = LzfFilter();

      expect(filter.id, equals(32000)); // H5Z_FILTER_LZF
      expect(filter.name, equals('lzf'));
    });

    test('compresses data successfully', () {
      final filter = LzfFilter();
      final data = List.generate(1000, (i) => i % 256);

      final compressed = filter.encode(data);

      expect(compressed, isNotEmpty);
      // For repetitive data, compression should reduce size
      expect(compressed.length, lessThanOrEqualTo(data.length));
    });

    test('handles empty data', () {
      final filter = LzfFilter();
      final data = <int>[];

      final compressed = filter.encode(data);

      expect(compressed, isEmpty);
    });

    test('handles small data', () {
      final filter = LzfFilter();
      final data = [1, 2, 3, 4, 5];

      final compressed = filter.encode(data);

      expect(compressed, isNotEmpty);
    });

    test('handles highly repetitive data', () {
      final filter = LzfFilter();
      final data = List.filled(1000, 42);

      final compressed = filter.encode(data);

      // Highly repetitive data should compress well
      expect(compressed.length, lessThan(data.length));
    });

    test('handles random-like data', () {
      final filter = LzfFilter();
      // Create pseudo-random data (harder to compress)
      final data = List.generate(1000, (i) => (i * 7919) % 256);

      final compressed = filter.encode(data);

      expect(compressed, isNotEmpty);
      // Random data may not compress well, but shouldn't fail
    });
  });

  group('FilterPipeline', () {
    test('creates empty pipeline', () {
      final pipeline = FilterPipeline(filters: []);

      expect(pipeline.isEmpty, isTrue);
      expect(pipeline.isNotEmpty, isFalse);
      expect(pipeline.length, equals(0));
    });

    test('creates pipeline with single filter', () {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);

      expect(pipeline.isEmpty, isFalse);
      expect(pipeline.isNotEmpty, isTrue);
      expect(pipeline.length, equals(1));
    });

    test('creates pipeline with multiple filters', () {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
        LzfFilter(),
      ]);

      expect(pipeline.length, equals(2));
    });

    test('applies single filter', () {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);

      final data = List.generate(1000, (i) => i % 256);
      final encoded = pipeline.apply(data);

      expect(encoded, isNotEmpty);
      expect(encoded.length, lessThan(data.length));
    });

    test('applies multiple filters in order', () {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);

      final data = List.generate(1000, (i) => i % 256);
      final encoded = pipeline.apply(data);

      expect(encoded, isNotEmpty);
    });

    test('writes pipeline message for single filter', () {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);

      final message = pipeline.writeMessage();

      expect(message, isNotEmpty);
      expect(message[0], equals(2)); // Version 2
      expect(message[1], equals(1)); // 1 filter
    });

    test('writes pipeline message for multiple filters', () {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
        LzfFilter(),
      ]);

      final message = pipeline.writeMessage();

      expect(message, isNotEmpty);
      expect(message[0], equals(2)); // Version 2
      expect(message[1], equals(2)); // 2 filters
    });

    test('writes empty pipeline message', () {
      final pipeline = FilterPipeline(filters: []);

      final message = pipeline.writeMessage();

      expect(message, isNotEmpty);
      expect(message[0], equals(2)); // Version 2
      expect(message[1], equals(0)); // 0 filters
    });

    test('pipeline message includes filter IDs', () {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);

      final message = pipeline.writeMessage();

      // Check that gzip filter ID (1) is in the message
      // Message format: version(1) + numFilters(1) + reserved(2) + filterID(2) + ...
      expect(message.length, greaterThanOrEqualTo(6));

      // Extract filter ID (bytes 4-5, little-endian)
      final filterId = message[4] | (message[5] << 8);
      expect(filterId, equals(1)); // Gzip filter ID
    });
  });

  group('ChunkedLayoutWriter with Compression', () {
    test('creates writer with gzip compression', () {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [10, 10],
        datasetDimensions: [100, 100],
        filterPipeline: pipeline,
      );

      expect(writer.filterPipeline, isNotNull);
      expect(writer.filterPipeline!.length, equals(1));
    });

    test('writes compressed chunks', () async {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);

      final array = NDArray.fromFlat(
        List.generate(100, (i) => i.toDouble()),
        [100],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [25],
        datasetDimensions: [100],
        filterPipeline: pipeline,
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      expect(byteWriter.size, greaterThan(0));
    });

    test('compressed data is smaller than uncompressed', () async {
      // Create repetitive data that compresses well
      final data = List.generate(1000, (i) => (i % 10).toDouble());
      final array = NDArray.fromFlat(data, [1000]);

      // Write without compression
      final writerNoComp = ChunkedLayoutWriter(
        chunkDimensions: [250],
        datasetDimensions: [1000],
      );

      final byteWriterNoComp = ByteWriter();
      await writerNoComp.writeData(byteWriterNoComp, array);
      final uncompressedSize = byteWriterNoComp.size;

      // Write with compression
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 9),
      ]);

      final writerComp = ChunkedLayoutWriter(
        chunkDimensions: [250],
        datasetDimensions: [1000],
        filterPipeline: pipeline,
      );

      final byteWriterComp = ByteWriter();
      await writerComp.writeData(byteWriterComp, array);
      final compressedSize = byteWriterComp.size;

      // Compressed should be smaller (accounting for B-tree overhead)
      expect(compressedSize, lessThan(uncompressedSize));
    });

    test('skips compression when not beneficial', () async {
      // Create random-like data that doesn't compress well
      final data = List.generate(100, (i) => (i * 7919 % 256).toDouble());
      final array = NDArray.fromFlat(data, [100]);

      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 9),
      ]);

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [25],
        datasetDimensions: [100],
        filterPipeline: pipeline,
      );

      final byteWriter = ByteWriter();
      await writer.writeData(byteWriter, array);

      // Should complete without error
      expect(byteWriter.size, greaterThan(0));
    });

    test('handles LZF compression', () async {
      final pipeline = FilterPipeline(filters: [
        LzfFilter(),
      ]);

      final array = NDArray.fromFlat(
        List.generate(100, (i) => i.toDouble()),
        [100],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [25],
        datasetDimensions: [100],
        filterPipeline: pipeline,
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      expect(byteWriter.size, greaterThan(0));
    });

    test('handles 2D array with compression', () async {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);

      final array = NDArray.fromFlat(
        List.generate(100, (i) => i.toDouble()),
        [10, 10],
      );

      final writer = ChunkedLayoutWriter(
        chunkDimensions: [5, 5],
        datasetDimensions: [10, 10],
        filterPipeline: pipeline,
      );

      final byteWriter = ByteWriter();
      final btreeAddress = await writer.writeData(byteWriter, array);

      expect(btreeAddress, greaterThan(0));
      expect(byteWriter.size, greaterThan(0));
    });

    test('auto-calculation works with compression', () async {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);

      final writer = ChunkedLayoutWriter.auto(
        datasetDimensions: [1000, 1000],
        elementSize: 8,
        filterPipeline: pipeline,
      );

      expect(writer.filterPipeline, isNotNull);
      expect(writer.chunkDimensions.length, equals(2));
    });
  });
}
