import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/data_layout_message_writer.dart';

void main() {
  // NOTE: This test file originally contained tests for:
  // - DatatypeMessageWriter (not yet implemented)
  // - DataspaceMessageWriter (not yet implemented)
  // - AttributeMessageWriter (not yet implemented)
  //
  // Those tests have been temporarily removed until the classes are created.
  // Only DataLayoutMessageWriter tests remain as that class exists.

  group('DataLayoutMessageWriter', () {
    late DataLayoutMessageWriter writer;

    setUp(() {
      writer = DataLayoutMessageWriter();
    });

    test('writeContiguous generates correct message structure', () {
      final message = writer.writeContiguous(
        dataAddress: 1024,
        dataSize: 8000,
      );

      // Verify message length: 1 + 1 + 8 + 8 = 18 bytes
      expect(message.length, equals(18));

      // Verify version
      expect(message[0], equals(3));

      // Verify layout class (1 = contiguous)
      expect(message[1], equals(1));

      // Verify data address
      final address = ByteData.sublistView(Uint8List.fromList(message), 2, 10)
          .getUint64(0, Endian.little);
      expect(address, equals(1024));

      // Verify data size
      final size = ByteData.sublistView(Uint8List.fromList(message), 10, 18)
          .getUint64(0, Endian.little);
      expect(size, equals(8000));
    });

    test('writeContiguous with big-endian generates correct byte order', () {
      final message = writer.writeContiguous(
        dataAddress: 2048,
        dataSize: 16000,
        endian: Endian.big,
      );

      // Verify message length
      expect(message.length, equals(18));

      // Verify data address in big-endian
      final address = ByteData.sublistView(Uint8List.fromList(message), 2, 10)
          .getUint64(0, Endian.big);
      expect(address, equals(2048));

      // Verify data size in big-endian
      final size = ByteData.sublistView(Uint8List.fromList(message), 10, 18)
          .getUint64(0, Endian.big);
      expect(size, equals(16000));
    });

    test('writeContiguous handles zero address', () {
      final message = writer.writeContiguous(
        dataAddress: 0,
        dataSize: 1000,
      );

      expect(message.length, equals(18));

      final address = ByteData.sublistView(Uint8List.fromList(message), 2, 10)
          .getUint64(0, Endian.little);
      expect(address, equals(0));
    });

    test('writeContiguous handles zero size', () {
      final message = writer.writeContiguous(
        dataAddress: 1024,
        dataSize: 0,
      );

      expect(message.length, equals(18));

      final size = ByteData.sublistView(Uint8List.fromList(message), 10, 18)
          .getUint64(0, Endian.little);
      expect(size, equals(0));
    });

    test('writeContiguous throws for negative address', () {
      expect(
        () => writer.writeContiguous(
          dataAddress: -1,
          dataSize: 1000,
        ),
        throwsArgumentError,
      );
    });

    test('writeContiguous throws for negative size', () {
      expect(
        () => writer.writeContiguous(
          dataAddress: 1024,
          dataSize: -1,
        ),
        throwsArgumentError,
      );
    });

    test('writeContiguous handles large values', () {
      final message = writer.writeContiguous(
        dataAddress: 0x7FFFFFFFFFFFFFFF,
        dataSize: 0x7FFFFFFFFFFFFFFF,
      );

      expect(message.length, equals(18));

      final address = ByteData.sublistView(Uint8List.fromList(message), 2, 10)
          .getUint64(0, Endian.little);
      expect(address, equals(0x7FFFFFFFFFFFFFFF));

      final size = ByteData.sublistView(Uint8List.fromList(message), 10, 18)
          .getUint64(0, Endian.little);
      expect(size, equals(0x7FFFFFFFFFFFFFFF));
    });
  });
}
