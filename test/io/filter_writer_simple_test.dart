import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/filter.dart';

void main() {
  group('Filter Writer - Basic Functionality', () {
    test('GzipFilter compresses data', () {
      final filter = GzipFilter(compressionLevel: 6);
      final data = List.generate(1000, (i) => i % 256);

      final compressed = filter.encode(data);

      expect(compressed, isNotEmpty);
      expect(compressed.length, lessThan(data.length));
      print(
          'Original: ${data.length} bytes, Compressed: ${compressed.length} bytes');
    });

    test('LzfFilter compresses data', () {
      final filter = LzfFilter();
      final data = List.generate(1000, (i) => i % 256);

      final compressed = filter.encode(data);

      expect(compressed, isNotEmpty);
      print(
          'Original: ${data.length} bytes, LZF Compressed: ${compressed.length} bytes');
    });

    test('FilterPipeline writes message', () {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 6),
      ]);

      final message = pipeline.writeMessage();

      expect(message, isNotEmpty);
      expect(message[0], equals(2)); // Version 2
      expect(message[1], equals(1)); // 1 filter
      print('Pipeline message: ${message.length} bytes');
    });

    test('FilterPipeline applies filters', () {
      final pipeline = FilterPipeline(filters: [
        GzipFilter(compressionLevel: 9),
      ]);

      final data = List.generate(1000, (i) => i % 10);
      final encoded = pipeline.apply(data);

      expect(encoded, isNotEmpty);
      expect(encoded.length, lessThan(data.length));
      print(
          'Pipeline: Original ${data.length} bytes -> Encoded ${encoded.length} bytes');
    });
  });
}
