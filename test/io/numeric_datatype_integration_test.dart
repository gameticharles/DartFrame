import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('NumericDatatypeWriter Integration', () {
    test('all numeric types can be created via factory', () {
      // Integer types
      final int8 = DatatypeWriterFactory.create(0, hint: DatatypeHint.int8);
      final uint8 = DatatypeWriterFactory.create(0, hint: DatatypeHint.uint8);
      final int16 = DatatypeWriterFactory.create(0, hint: DatatypeHint.int16);
      final uint16 = DatatypeWriterFactory.create(0, hint: DatatypeHint.uint16);
      final int32 = DatatypeWriterFactory.create(0, hint: DatatypeHint.int32);
      final uint32 = DatatypeWriterFactory.create(0, hint: DatatypeHint.uint32);
      final int64 = DatatypeWriterFactory.create(0, hint: DatatypeHint.int64);
      final uint64 = DatatypeWriterFactory.create(0, hint: DatatypeHint.uint64);

      // Floating-point types
      final float32 =
          DatatypeWriterFactory.create(0.0, hint: DatatypeHint.float32);
      final float64 =
          DatatypeWriterFactory.create(0.0, hint: DatatypeHint.float64);

      // Verify all are NumericDatatypeWriter instances
      expect(int8, isA<NumericDatatypeWriter>());
      expect(uint8, isA<NumericDatatypeWriter>());
      expect(int16, isA<NumericDatatypeWriter>());
      expect(uint16, isA<NumericDatatypeWriter>());
      expect(int32, isA<NumericDatatypeWriter>());
      expect(uint32, isA<NumericDatatypeWriter>());
      expect(int64, isA<NumericDatatypeWriter>());
      expect(uint64, isA<NumericDatatypeWriter>());
      expect(float32, isA<NumericDatatypeWriter>());
      expect(float64, isA<NumericDatatypeWriter>());

      // Verify sizes
      expect(int8.getSize(), 1);
      expect(uint8.getSize(), 1);
      expect(int16.getSize(), 2);
      expect(uint16.getSize(), 2);
      expect(int32.getSize(), 4);
      expect(uint32.getSize(), 4);
      expect(int64.getSize(), 8);
      expect(uint64.getSize(), 8);
      expect(float32.getSize(), 4);
      expect(float64.getSize(), 8);
    });

    test('all numeric types generate valid messages', () {
      final types = [
        DatatypeHint.int8,
        DatatypeHint.uint8,
        DatatypeHint.int16,
        DatatypeHint.uint16,
        DatatypeHint.int32,
        DatatypeHint.uint32,
        DatatypeHint.int64,
        DatatypeHint.uint64,
        DatatypeHint.float32,
        DatatypeHint.float64,
      ];

      for (final hint in types) {
        final writer = DatatypeWriterFactory.create(0, hint: hint);
        final message = writer.writeMessage();

        // All messages should be non-empty
        expect(message, isNotEmpty,
            reason: 'Message for $hint should not be empty');

        // All messages should have at least the header (4 bytes)
        expect(message.length, greaterThanOrEqualTo(4),
            reason: 'Message for $hint should have at least 4 bytes');
      }
    });

    test('endianness is correctly applied', () {
      final littleEndian = NumericDatatypeWriter.int32(endian: Endian.little);
      final bigEndian = NumericDatatypeWriter.int32(endian: Endian.big);

      expect(littleEndian.endian, Endian.little);
      expect(bigEndian.endian, Endian.big);

      final littleMessage = littleEndian.writeMessage();
      final bigMessage = bigEndian.writeMessage();

      // Messages should differ in the endianness bit (bit 0 of byte 1)
      expect(littleMessage[1] & 0x01, 0x00); // little-endian
      expect(bigMessage[1] & 0x01, 0x01); // big-endian
    });

    test('signed vs unsigned integers are correctly distinguished', () {
      final signed = NumericDatatypeWriter.int32();
      final unsigned = NumericDatatypeWriter.uint32();

      final signedMessage = signed.writeMessage();
      final unsignedMessage = unsigned.writeMessage();

      // Messages should differ in the sign bit (bit 3 of byte 1)
      expect(signedMessage[1] & 0x08, 0x08); // signed
      expect(unsignedMessage[1] & 0x08, 0x00); // unsigned
    });
  });
}
