import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/filter.dart';

void main() {
  group('Filter Round-Trip Tests', () {
    test('GzipFilter round-trip (encode then decode)', () async {
      final originalData = List.generate(1000, (i) => i % 256);

      // Encode
      final encoder = GzipFilter(compressionLevel: 6);
      final compressed = encoder.encode(originalData);

      expect(compressed.length, lessThan(originalData.length));
      print('Gzip: ${originalData.length} → ${compressed.length} bytes');

      // Decode
      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      // Verify round-trip
      expect(decompressed, equals(originalData));
      print('Gzip round-trip: ✓ Data matches');
    });

    test('LzfFilter round-trip (encode then decode)', () async {
      final originalData = List.generate(1000, (i) => i % 256);

      // Encode
      final encoder = LzfFilter();
      final compressed = encoder.encode(originalData);

      expect(compressed.length, lessThanOrEqualTo(originalData.length));
      print('LZF: ${originalData.length} → ${compressed.length} bytes');

      // Decode
      final decoder = LzfFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      // Verify round-trip
      expect(decompressed, equals(originalData));
      print('LZF round-trip: ✓ Data matches');
    });

    test('GzipFilter round-trip with highly repetitive data', () async {
      final originalData = List.filled(10000, 42);

      // Encode
      final encoder = GzipFilter(compressionLevel: 9);
      final compressed = encoder.encode(originalData);

      // Should compress very well
      expect(compressed.length, lessThan(originalData.length * 0.1));
      print(
          'Gzip (repetitive): ${originalData.length} → ${compressed.length} bytes (${(compressed.length / originalData.length * 100).toStringAsFixed(1)}%)');

      // Decode
      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      // Verify round-trip
      expect(decompressed, equals(originalData));
      print('Gzip (repetitive) round-trip: ✓ Data matches');
    });

    test('LzfFilter round-trip with random-like data', () async {
      // Create pseudo-random data (harder to compress)
      final originalData = List.generate(1000, (i) => (i * 7919) % 256);

      // Encode
      final encoder = LzfFilter();
      final compressed = encoder.encode(originalData);

      print(
          'LZF (random): ${originalData.length} → ${compressed.length} bytes');

      // Decode
      final decoder = LzfFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      // Verify round-trip
      expect(decompressed, equals(originalData));
      print('LZF (random) round-trip: ✓ Data matches');
    });

    test('FilterPipeline round-trip with single filter', () async {
      final originalData = List.generate(1000, (i) => i % 100);

      // Encode with pipeline
      final encodePipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);
      final compressed = encodePipeline.apply(originalData);

      print(
          'Pipeline (single): ${originalData.length} → ${compressed.length} bytes');

      // Decode with pipeline
      final decodePipeline = FilterPipeline(filters: [
        GzipFilter.forReading(flags: 0, clientData: []),
      ]);
      final decompressed =
          await decodePipeline.decode(Uint8List.fromList(compressed));

      // Verify round-trip
      expect(decompressed, equals(originalData));
      print('Pipeline round-trip: ✓ Data matches');
    });

    test('Empty data round-trip', () async {
      final originalData = <int>[];

      // Gzip
      final gzipEncoder = GzipFilter();
      final gzipCompressed = gzipEncoder.encode(originalData);
      final gzipDecoder = GzipFilter.forReading(flags: 0, clientData: []);
      final gzipDecompressed =
          await gzipDecoder.decode(Uint8List.fromList(gzipCompressed));
      expect(gzipDecompressed, isEmpty);

      // LZF
      final lzfEncoder = LzfFilter();
      final lzfCompressed = lzfEncoder.encode(originalData);
      final lzfDecoder = LzfFilter.forReading(flags: 0, clientData: []);
      final lzfDecompressed =
          await lzfDecoder.decode(Uint8List.fromList(lzfCompressed));
      expect(lzfDecompressed, isEmpty);

      print('Empty data round-trip: ✓ Both filters handle empty data');
    });

    test('Single byte round-trip', () async {
      final originalData = [42];

      // Gzip
      final gzipEncoder = GzipFilter();
      final gzipCompressed = gzipEncoder.encode(originalData);
      final gzipDecoder = GzipFilter.forReading(flags: 0, clientData: []);
      final gzipDecompressed =
          await gzipDecoder.decode(Uint8List.fromList(gzipCompressed));
      expect(gzipDecompressed, equals(originalData));

      // LZF
      final lzfEncoder = LzfFilter();
      final lzfCompressed = lzfEncoder.encode(originalData);
      final lzfDecoder = LzfFilter.forReading(flags: 0, clientData: []);
      final lzfDecompressed =
          await lzfDecoder.decode(Uint8List.fromList(lzfCompressed));
      expect(lzfDecompressed, equals(originalData));

      print('Single byte round-trip: ✓ Both filters handle single byte');
    });

    test('Large data round-trip', () async {
      final originalData = List.generate(100000, (i) => i % 256);

      // Encode
      final encoder = GzipFilter(compressionLevel: 6);
      final compressed = encoder.encode(originalData);

      print('Large data: ${originalData.length} → ${compressed.length} bytes');

      // Decode
      final decoder = GzipFilter.forReading(flags: 0, clientData: []);
      final decompressed = await decoder.decode(Uint8List.fromList(compressed));

      // Verify round-trip
      expect(decompressed, equals(originalData));
      print('Large data round-trip: ✓ Data matches');
    });
  });
}
