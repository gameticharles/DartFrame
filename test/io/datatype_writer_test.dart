import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DatatypeHint', () {
    test('has all required numeric types', () {
      expect(DatatypeHint.int8, isNotNull);
      expect(DatatypeHint.uint8, isNotNull);
      expect(DatatypeHint.int16, isNotNull);
      expect(DatatypeHint.uint16, isNotNull);
      expect(DatatypeHint.int32, isNotNull);
      expect(DatatypeHint.uint32, isNotNull);
      expect(DatatypeHint.int64, isNotNull);
      expect(DatatypeHint.uint64, isNotNull);
      expect(DatatypeHint.float32, isNotNull);
      expect(DatatypeHint.float64, isNotNull);
    });

    test('has string types', () {
      expect(DatatypeHint.fixedString, isNotNull);
      expect(DatatypeHint.variableString, isNotNull);
    });

    test('has boolean type', () {
      expect(DatatypeHint.boolean, isNotNull);
    });

    test('has compound type', () {
      expect(DatatypeHint.compound, isNotNull);
    });
  });

  group('DatatypeWriter abstract class', () {
    test('defines required interface methods', () {
      // This test verifies that the abstract class has the correct interface
      // We can't instantiate it directly, but we can verify it exists
      expect(DatatypeWriter, isNotNull);
    });
  });

  group('DatatypeWriterFactory', () {
    test('create method detects double type', () {
      final writer = DatatypeWriterFactory.create(3.14);
      expect(writer, isA<NumericDatatypeWriter>());
      expect(writer.datatypeClass, Hdf5DatatypeClass.float);
      expect(writer.getSize(), 8);
    });

    test('create method detects int type', () {
      final writer = DatatypeWriterFactory.create(42);
      expect(writer, isA<NumericDatatypeWriter>());
      expect(writer.datatypeClass, Hdf5DatatypeClass.integer);
      expect(writer.getSize(), 8);
    });

    test('create method detects string type', () {
      // Should create variable-length string writer
      final writer = DatatypeWriterFactory.create("hello");
      expect(writer, isA<StringDatatypeWriter>());
      expect(writer.datatypeClass, Hdf5DatatypeClass.string);
      expect(writer.getSize(), -1); // Variable-length
    });

    test('create method detects bool type', () {
      final writer = DatatypeWriterFactory.create(true);
      expect(writer, isA<BooleanDatatypeWriter>());
      expect(writer.datatypeClass, Hdf5DatatypeClass.enumType);
      expect(writer.getSize(), 1);
    });

    test('create method detects Map type for compound', () {
      final writer = DatatypeWriterFactory.create({'field': 42});
      expect(writer, isA<CompoundDatatypeWriter>());
      expect(writer.datatypeClass, Hdf5DatatypeClass.compound);
      expect(writer.getSize(), greaterThan(0));
    });

    test('create method rejects unsupported types', () {
      // Should throw UnsupportedError for unsupported types
      expect(
        () => DatatypeWriterFactory.create([1, 2, 3]),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('create method accepts hint parameter for int32', () {
      final writer = DatatypeWriterFactory.create(42, hint: DatatypeHint.int32);
      expect(writer, isA<NumericDatatypeWriter>());
      expect(writer.datatypeClass, Hdf5DatatypeClass.integer);
      expect(writer.getSize(), 4);
    });

    test('create method accepts endian parameter', () {
      final writer = DatatypeWriterFactory.create(
        3.14,
        endian: Endian.big,
      );
      expect(writer, isA<NumericDatatypeWriter>());
      expect(writer.endian, Endian.big);
    });

    test('fromDatatype method exists', () {
      // Should throw UnimplementedError since not yet implemented
      expect(
        () => DatatypeWriterFactory.fromDatatype(Hdf5Datatype.float64),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('NumericDatatypeWriter', () {
    group('Integer types - basic functionality', () {
      test('int8 writer creates correct message', () {
        final writer = NumericDatatypeWriter.int8();
        expect(writer.datatypeClass, Hdf5DatatypeClass.integer);
        expect(writer.getSize(), 1);
        expect(writer.endian, Endian.little);

        final message = writer.writeMessage();
        expect(message, isNotEmpty);
        // Class and version byte: version 1, class 0 (integer)
        expect(message[0], 0x10);
        // Class bit field 1: little-endian (bit 0=0), signed (bit 3=1)
        expect(message[1] & 0x09, 0x08);
      });

      test('uint8 writer creates correct message', () {
        final writer = NumericDatatypeWriter.uint8();
        expect(writer.datatypeClass, Hdf5DatatypeClass.integer);
        expect(writer.getSize(), 1);

        final message = writer.writeMessage();
        // Class bit field 1: little-endian (bit 0=0), unsigned (bit 3=0)
        expect(message[1] & 0x09, 0x00);
      });

      test('int16 writer creates correct message', () {
        final writer = NumericDatatypeWriter.int16();
        expect(writer.getSize(), 2);

        final message = writer.writeMessage();
        expect(message[0], 0x10); // version 1, class 0
      });

      test('uint16 writer creates correct message', () {
        final writer = NumericDatatypeWriter.uint16();
        expect(writer.getSize(), 2);
      });

      test('int32 writer creates correct message', () {
        final writer = NumericDatatypeWriter.int32();
        expect(writer.getSize(), 4);
      });

      test('uint32 writer creates correct message', () {
        final writer = NumericDatatypeWriter.uint32();
        expect(writer.getSize(), 4);
      });

      test('int64 writer creates correct message', () {
        final writer = NumericDatatypeWriter.int64();
        expect(writer.getSize(), 8);
      });

      test('uint64 writer creates correct message', () {
        final writer = NumericDatatypeWriter.uint64();
        expect(writer.getSize(), 8);
      });

      test('integer writer with big-endian', () {
        final writer = NumericDatatypeWriter.int32(endian: Endian.big);
        expect(writer.endian, Endian.big);

        final message = writer.writeMessage();
        // Class bit field 1: big-endian (bit 0=1), signed (bit 3=1)
        expect(message[1] & 0x09, 0x09);
      });
    });

    group('Integer types - message format verification', () {
      test('int8 message format matches HDF5 specification', () {
        final writer = NumericDatatypeWriter.int8();
        final message = writer.writeMessage();

        expect(message.length, 12);
        expect(message[0], 0x10); // version 1, class 0
        expect(message[1], 0x08); // little-endian, signed
        expect(message[2], 0x00); // reserved
        expect(message[3], 0x00); // reserved

        // Size field (bytes 4-7): 1 byte, little-endian
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 1);

        // Bit precision field (bytes 10-11): 8 bits
        final bitPrecision =
            ByteData.sublistView(Uint8List.fromList(message), 10, 12)
                .getUint16(0, Endian.little);
        expect(bitPrecision, 8);
      });

      test('uint16 message format matches HDF5 specification', () {
        final writer = NumericDatatypeWriter.uint16();
        final message = writer.writeMessage();

        expect(message.length, 12);
        expect(message[0], 0x10); // version 1, class 0
        expect(message[1], 0x00); // little-endian, unsigned

        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 2);

        final bitPrecision =
            ByteData.sublistView(Uint8List.fromList(message), 10, 12)
                .getUint16(0, Endian.little);
        expect(bitPrecision, 16);
      });

      test('int32 message format matches HDF5 specification', () {
        final writer = NumericDatatypeWriter.int32();
        final message = writer.writeMessage();

        expect(message.length, 12);
        expect(message[0], 0x10);
        expect(message[1], 0x08); // signed

        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 4);

        final bitPrecision =
            ByteData.sublistView(Uint8List.fromList(message), 10, 12)
                .getUint16(0, Endian.little);
        expect(bitPrecision, 32);
      });

      test('uint64 message format matches HDF5 specification', () {
        final writer = NumericDatatypeWriter.uint64();
        final message = writer.writeMessage();

        expect(message.length, 12);
        expect(message[0], 0x10);
        expect(message[1], 0x00); // unsigned

        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 8);

        final bitPrecision =
            ByteData.sublistView(Uint8List.fromList(message), 10, 12)
                .getUint16(0, Endian.little);
        expect(bitPrecision, 64);
      });

      test('int32 big-endian message format matches HDF5 specification', () {
        final writer = NumericDatatypeWriter.int32(endian: Endian.big);
        final message = writer.writeMessage();

        expect(message.length, 12);
        expect(message[0], 0x10);
        expect(message[1], 0x09); // big-endian, signed

        // Size field should be in big-endian
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.big);
        expect(size, 4);
      });
    });

    group('Floating-point types - basic functionality', () {
      test('float32 writer creates correct message', () {
        final writer = NumericDatatypeWriter.float32();
        expect(writer.datatypeClass, Hdf5DatatypeClass.float);
        expect(writer.getSize(), 4);
        expect(writer.endian, Endian.little);

        final message = writer.writeMessage();
        expect(message, isNotEmpty);
        // Class and version byte: version 1, class 1 (float)
        expect(message[0], 0x11);
        // Class bit field 1: little-endian (bit 0=0), mantissa norm (bits 4-7=2)
        expect(message[1] & 0xF1, 0x20);
      });

      test('float64 writer creates correct message', () {
        final writer = NumericDatatypeWriter.float64();
        expect(writer.datatypeClass, Hdf5DatatypeClass.float);
        expect(writer.getSize(), 8);

        final message = writer.writeMessage();
        expect(message[0], 0x11); // version 1, class 1
      });

      test('float writer with big-endian', () {
        final writer = NumericDatatypeWriter.float64(endian: Endian.big);
        expect(writer.endian, Endian.big);

        final message = writer.writeMessage();
        // Class bit field 1: big-endian (bit 0=1), mantissa norm (bits 4-7=2)
        expect(message[1] & 0xF1, 0x21);
      });
    });

    group('Floating-point types - message format verification', () {
      test('float32 message format matches HDF5 specification', () {
        final writer = NumericDatatypeWriter.float32();
        final message = writer.writeMessage();

        expect(message.length, 20);
        expect(message[0], 0x11); // version 1, class 1
        expect(message[1], 0x20); // little-endian, mantissa norm=2

        // Size field (bytes 4-7): 4 bytes
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 4);

        // Bit precision (bytes 10-11): 32 bits
        final bitPrecision =
            ByteData.sublistView(Uint8List.fromList(message), 10, 12)
                .getUint16(0, Endian.little);
        expect(bitPrecision, 32);

        // IEEE 754 single precision parameters
        expect(message[12], 23); // exponent location
        expect(message[13], 8); // exponent size
        expect(message[14], 0); // mantissa location
        expect(message[15], 23); // mantissa size

        // Exponent bias (bytes 16-19): 127
        final expBias =
            ByteData.sublistView(Uint8List.fromList(message), 16, 20)
                .getUint32(0, Endian.little);
        expect(expBias, 127);
      });

      test('float64 message format matches HDF5 specification', () {
        final writer = NumericDatatypeWriter.float64();
        final message = writer.writeMessage();

        expect(message.length, 20);
        expect(message[0], 0x11); // version 1, class 1
        expect(message[1], 0x20); // little-endian, mantissa norm=2

        // Size field: 8 bytes
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 8);

        // Bit precision: 64 bits
        final bitPrecision =
            ByteData.sublistView(Uint8List.fromList(message), 10, 12)
                .getUint16(0, Endian.little);
        expect(bitPrecision, 64);

        // IEEE 754 double precision parameters
        expect(message[12], 52); // exponent location
        expect(message[13], 11); // exponent size
        expect(message[14], 0); // mantissa location
        expect(message[15], 52); // mantissa size

        // Exponent bias: 1023
        final expBias =
            ByteData.sublistView(Uint8List.fromList(message), 16, 20)
                .getUint32(0, Endian.little);
        expect(expBias, 1023);
      });

      test('float32 big-endian message format matches HDF5 specification', () {
        final writer = NumericDatatypeWriter.float32(endian: Endian.big);
        final message = writer.writeMessage();

        expect(message.length, 20);
        expect(message[0], 0x11);
        expect(message[1], 0x21); // big-endian, mantissa norm=2

        // Size field should be in big-endian
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.big);
        expect(size, 4);
      });
    });

    group('Edge cases and comprehensive type coverage', () {
      test('all integer types have correct sizes', () {
        expect(NumericDatatypeWriter.int8().getSize(), 1);
        expect(NumericDatatypeWriter.uint8().getSize(), 1);
        expect(NumericDatatypeWriter.int16().getSize(), 2);
        expect(NumericDatatypeWriter.uint16().getSize(), 2);
        expect(NumericDatatypeWriter.int32().getSize(), 4);
        expect(NumericDatatypeWriter.uint32().getSize(), 4);
        expect(NumericDatatypeWriter.int64().getSize(), 8);
        expect(NumericDatatypeWriter.uint64().getSize(), 8);
      });

      test('all float types have correct sizes', () {
        expect(NumericDatatypeWriter.float32().getSize(), 4);
        expect(NumericDatatypeWriter.float64().getSize(), 8);
      });

      test('all integer types have correct datatype class', () {
        expect(NumericDatatypeWriter.int8().datatypeClass,
            Hdf5DatatypeClass.integer);
        expect(NumericDatatypeWriter.uint8().datatypeClass,
            Hdf5DatatypeClass.integer);
        expect(NumericDatatypeWriter.int16().datatypeClass,
            Hdf5DatatypeClass.integer);
        expect(NumericDatatypeWriter.uint16().datatypeClass,
            Hdf5DatatypeClass.integer);
        expect(NumericDatatypeWriter.int32().datatypeClass,
            Hdf5DatatypeClass.integer);
        expect(NumericDatatypeWriter.uint32().datatypeClass,
            Hdf5DatatypeClass.integer);
        expect(NumericDatatypeWriter.int64().datatypeClass,
            Hdf5DatatypeClass.integer);
        expect(NumericDatatypeWriter.uint64().datatypeClass,
            Hdf5DatatypeClass.integer);
      });

      test('all float types have correct datatype class', () {
        expect(NumericDatatypeWriter.float32().datatypeClass,
            Hdf5DatatypeClass.float);
        expect(NumericDatatypeWriter.float64().datatypeClass,
            Hdf5DatatypeClass.float);
      });

      test('signed integers have sign bit set', () {
        final int8Msg = NumericDatatypeWriter.int8().writeMessage();
        final int16Msg = NumericDatatypeWriter.int16().writeMessage();
        final int32Msg = NumericDatatypeWriter.int32().writeMessage();
        final int64Msg = NumericDatatypeWriter.int64().writeMessage();

        // Bit 3 should be set for signed integers
        expect(int8Msg[1] & 0x08, 0x08);
        expect(int16Msg[1] & 0x08, 0x08);
        expect(int32Msg[1] & 0x08, 0x08);
        expect(int64Msg[1] & 0x08, 0x08);
      });

      test('unsigned integers have sign bit clear', () {
        final uint8Msg = NumericDatatypeWriter.uint8().writeMessage();
        final uint16Msg = NumericDatatypeWriter.uint16().writeMessage();
        final uint32Msg = NumericDatatypeWriter.uint32().writeMessage();
        final uint64Msg = NumericDatatypeWriter.uint64().writeMessage();

        // Bit 3 should be clear for unsigned integers
        expect(uint8Msg[1] & 0x08, 0x00);
        expect(uint16Msg[1] & 0x08, 0x00);
        expect(uint32Msg[1] & 0x08, 0x00);
        expect(uint64Msg[1] & 0x08, 0x00);
      });

      test('all integer types have zero bit offset', () {
        final types = [
          NumericDatatypeWriter.int8(),
          NumericDatatypeWriter.uint8(),
          NumericDatatypeWriter.int16(),
          NumericDatatypeWriter.uint16(),
          NumericDatatypeWriter.int32(),
          NumericDatatypeWriter.uint32(),
          NumericDatatypeWriter.int64(),
          NumericDatatypeWriter.uint64(),
        ];

        for (final writer in types) {
          final message = writer.writeMessage();
          // Bit offset at bytes 8-9
          final bitOffset =
              ByteData.sublistView(Uint8List.fromList(message), 8, 10)
                  .getUint16(0, Endian.little);
          expect(bitOffset, 0);
        }
      });

      test('all float types have zero bit offset', () {
        final types = [
          NumericDatatypeWriter.float32(),
          NumericDatatypeWriter.float64(),
        ];

        for (final writer in types) {
          final message = writer.writeMessage();
          // Bit offset at bytes 8-9
          final bitOffset =
              ByteData.sublistView(Uint8List.fromList(message), 8, 10)
                  .getUint16(0, Endian.little);
          expect(bitOffset, 0);
        }
      });

      test('bit precision matches size for all integer types', () {
        final types = [
          (NumericDatatypeWriter.int8(), 8),
          (NumericDatatypeWriter.uint8(), 8),
          (NumericDatatypeWriter.int16(), 16),
          (NumericDatatypeWriter.uint16(), 16),
          (NumericDatatypeWriter.int32(), 32),
          (NumericDatatypeWriter.uint32(), 32),
          (NumericDatatypeWriter.int64(), 64),
          (NumericDatatypeWriter.uint64(), 64),
        ];

        for (final (writer, expectedBits) in types) {
          final message = writer.writeMessage();
          final bitPrecision =
              ByteData.sublistView(Uint8List.fromList(message), 10, 12)
                  .getUint16(0, Endian.little);
          expect(bitPrecision, expectedBits);
        }
      });

      test('bit precision matches size for all float types', () {
        final types = [
          (NumericDatatypeWriter.float32(), 32),
          (NumericDatatypeWriter.float64(), 64),
        ];

        for (final (writer, expectedBits) in types) {
          final message = writer.writeMessage();
          final bitPrecision =
              ByteData.sublistView(Uint8List.fromList(message), 10, 12)
                  .getUint16(0, Endian.little);
          expect(bitPrecision, expectedBits);
        }
      });

      test('sign location is correct for float types', () {
        final float32Msg = NumericDatatypeWriter.float32().writeMessage();
        final float64Msg = NumericDatatypeWriter.float64().writeMessage();

        // Sign location in class bit field 2 (byte 2)
        expect(float32Msg[2], 31); // bit 31 for float32
        expect(float64Msg[2], 63); // bit 63 for float64
      });

      test('multiple writers can be created independently', () {
        final writer1 = NumericDatatypeWriter.int32();
        final writer2 = NumericDatatypeWriter.float64();
        final writer3 = NumericDatatypeWriter.uint16();

        expect(writer1.getSize(), 4);
        expect(writer2.getSize(), 8);
        expect(writer3.getSize(), 2);

        expect(writer1.datatypeClass, Hdf5DatatypeClass.integer);
        expect(writer2.datatypeClass, Hdf5DatatypeClass.float);
        expect(writer3.datatypeClass, Hdf5DatatypeClass.integer);
      });

      test('messages are consistent across multiple calls', () {
        final writer = NumericDatatypeWriter.int32();
        final message1 = writer.writeMessage();
        final message2 = writer.writeMessage();

        expect(message1, equals(message2));
      });

      test('different endianness produces different messages', () {
        final writerLE = NumericDatatypeWriter.int32(endian: Endian.little);
        final writerBE = NumericDatatypeWriter.int32(endian: Endian.big);

        final messageLE = writerLE.writeMessage();
        final messageBE = writerBE.writeMessage();

        // Messages should differ in byte order bit and size field encoding
        expect(messageLE, isNot(equals(messageBE)));
        expect(messageLE[1] & 0x01, 0x00); // little-endian
        expect(messageBE[1] & 0x01, 0x01); // big-endian
      });
    });

    group('Message format validation', () {
      test('int64 message has correct structure', () {
        final writer = NumericDatatypeWriter.int64();
        final message = writer.writeMessage();

        // Expected message length for version 1 integer:
        // 1 (class+version) + 3 (bit fields) + 4 (size) + 2 (bit offset) + 2 (bit precision) = 12 bytes
        expect(message.length, 12);
      });

      test('float64 message has correct structure', () {
        final writer = NumericDatatypeWriter.float64();
        final message = writer.writeMessage();

        // Expected message length for version 1 float:
        // 1 (class+version) + 3 (bit fields) + 4 (size) + 2 (bit offset) + 2 (bit precision)
        // + 1 (exp loc) + 1 (exp size) + 1 (mant loc) + 1 (mant size) + 4 (exp bias) = 20 bytes
        expect(message.length, 20);
      });

      test('all integer messages have correct length', () {
        final types = [
          NumericDatatypeWriter.int8(),
          NumericDatatypeWriter.uint8(),
          NumericDatatypeWriter.int16(),
          NumericDatatypeWriter.uint16(),
          NumericDatatypeWriter.int32(),
          NumericDatatypeWriter.uint32(),
          NumericDatatypeWriter.int64(),
          NumericDatatypeWriter.uint64(),
        ];

        for (final writer in types) {
          final message = writer.writeMessage();
          expect(message.length, 12);
        }
      });

      test('all float messages have correct length', () {
        final types = [
          NumericDatatypeWriter.float32(),
          NumericDatatypeWriter.float64(),
        ];

        for (final writer in types) {
          final message = writer.writeMessage();
          expect(message.length, 20);
        }
      });
    });
  });

  group('BooleanDatatypeWriter', () {
    group('Basic functionality', () {
      test('creates writer with correct properties', () {
        final writer = BooleanDatatypeWriter();
        expect(writer.datatypeClass, Hdf5DatatypeClass.enumType);
        expect(writer.getSize(), 1);
        expect(writer.endian, Endian.little);
      });

      test('creates writer with big-endian', () {
        final writer = BooleanDatatypeWriter(endian: Endian.big);
        expect(writer.endian, Endian.big);
      });

      test('encodeValue returns correct integer values', () {
        final writer = BooleanDatatypeWriter();
        expect(writer.encodeValue(false), 0);
        expect(writer.encodeValue(true), 1);
      });

      test('decodeValue returns correct boolean values', () {
        final writer = BooleanDatatypeWriter();
        expect(writer.decodeValue(0), false);
        expect(writer.decodeValue(1), true);
        expect(writer.decodeValue(42), true); // Non-zero is true
      });
    });

    group('Message format verification', () {
      test('boolean message format matches HDF5 specification', () {
        final writer = BooleanDatatypeWriter();
        final message = writer.writeMessage();

        expect(message, isNotEmpty);

        // Class and version byte: version 1, class 8 (enum)
        expect(message[0], 0x18);

        // Class bit field 1: number of members (low byte) = 2
        expect(message[1], 2);

        // Class bit field 2: number of members (high byte) = 0
        expect(message[2], 0);

        // Class bit field 3: reserved
        expect(message[3], 0);

        // Size field (bytes 4-7): 1 byte
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 1);
      });

      test('boolean message contains base type (uint8)', () {
        final writer = BooleanDatatypeWriter();
        final message = writer.writeMessage();

        // After the enum header (8 bytes), there should be a uint8 datatype message
        // Base type starts at byte 8
        expect(message[8], 0x10); // version 1, class 0 (integer)
        expect(message[8 + 1] & 0x08, 0x00); // unsigned
      });

      test('boolean message contains FALSE and TRUE members', () {
        final writer = BooleanDatatypeWriter();
        final message = writer.writeMessage();

        // After enum header (8 bytes) and base type (12 bytes), members start at byte 20
        // Member 1: "FALSE\0" followed by value 0
        final falseNameStart = 20;
        expect(
            String.fromCharCodes(
                message.sublist(falseNameStart, falseNameStart + 5)),
            'FALSE');
        expect(message[falseNameStart + 5], 0); // null terminator

        // Value 0 comes after name (6 bytes for "FALSE\0")
        expect(message[falseNameStart + 6], 0);

        // Member 2: "TRUE\0" followed by value 1
        final trueNameStart =
            falseNameStart + 7; // 6 bytes for name + 1 byte for value
        expect(
            String.fromCharCodes(
                message.sublist(trueNameStart, trueNameStart + 4)),
            'TRUE');
        expect(message[trueNameStart + 4], 0); // null terminator

        // Value 1 comes after name (5 bytes for "TRUE\0")
        expect(message[trueNameStart + 5], 1);
      });

      test('boolean message with big-endian', () {
        final writer = BooleanDatatypeWriter(endian: Endian.big);
        final message = writer.writeMessage();

        // Size field should be in big-endian
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.big);
        expect(size, 1);
      });
    });

    group('Consistency and edge cases', () {
      test('messages are consistent across multiple calls', () {
        final writer = BooleanDatatypeWriter();
        final message1 = writer.writeMessage();
        final message2 = writer.writeMessage();

        expect(message1, equals(message2));
      });

      test('encode/decode round-trip', () {
        final writer = BooleanDatatypeWriter();

        final encodedFalse = writer.encodeValue(false);
        final encodedTrue = writer.encodeValue(true);

        expect(writer.decodeValue(encodedFalse), false);
        expect(writer.decodeValue(encodedTrue), true);
      });
    });
  });

  group('CompoundDatatypeWriter', () {
    group('Basic functionality', () {
      test('creates writer from fields', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
          'y': NumericDatatypeWriter.float64(),
        });

        expect(writer.datatypeClass, Hdf5DatatypeClass.compound);
        expect(writer.getSize(), greaterThan(0));
        expect(writer.endian, Endian.little);
      });

      test('creates writer from map', () {
        final writer = CompoundDatatypeWriter.fromMap({
          'id': 42,
          'value': 3.14,
        });

        expect(writer.datatypeClass, Hdf5DatatypeClass.compound);
        expect(writer.getSize(), greaterThan(0));
      });

      test('rejects empty field map', () {
        expect(
          () => CompoundDatatypeWriter.fromFields({}),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('provides field names', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
          'y': NumericDatatypeWriter.float64(),
          'z': NumericDatatypeWriter.int32(),
        });

        final fieldNames = writer.fieldNames;
        expect(fieldNames, contains('x'));
        expect(fieldNames, contains('y'));
        expect(fieldNames, contains('z'));
        expect(fieldNames.length, 3);
      });

      test('provides field writers', () {
        final xWriter = NumericDatatypeWriter.float64();
        final yWriter = NumericDatatypeWriter.int32();

        final writer = CompoundDatatypeWriter.fromFields({
          'x': xWriter,
          'y': yWriter,
        });

        expect(writer.getFieldWriter('x'), isNotNull);
        expect(writer.getFieldWriter('y'), isNotNull);
        expect(writer.getFieldWriter('z'), isNull);
      });

      test('provides field offsets', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
          'y': NumericDatatypeWriter.float64(),
        });

        final xOffset = writer.getFieldOffset('x');
        final yOffset = writer.getFieldOffset('y');

        expect(xOffset, isNotNull);
        expect(yOffset, isNotNull);
        expect(yOffset!, greaterThan(xOffset!));
      });
    });

    group('Field combinations', () {
      test('handles numeric-only fields', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'a': NumericDatatypeWriter.int8(),
          'b': NumericDatatypeWriter.int16(),
          'c': NumericDatatypeWriter.int32(),
          'd': NumericDatatypeWriter.int64(),
        });

        expect(writer.getSize(), greaterThan(0));
        expect(writer.fieldNames.length, 4);
      });

      test('handles mixed numeric types', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'int_field': NumericDatatypeWriter.int32(),
          'float_field': NumericDatatypeWriter.float64(),
          'byte_field': NumericDatatypeWriter.uint8(),
        });

        expect(writer.getSize(), greaterThan(0));
        expect(writer.fieldNames.length, 3);
      });

      test('handles string fields', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'id': NumericDatatypeWriter.int32(),
          'name': StringDatatypeWriter.fixedLength(length: 20),
        });

        expect(writer.getSize(), greaterThan(0));
        expect(writer.fieldNames.length, 2);
      });

      test('handles boolean fields', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'id': NumericDatatypeWriter.int32(),
          'active': BooleanDatatypeWriter(),
        });

        expect(writer.getSize(), greaterThan(0));
        expect(writer.fieldNames.length, 2);
      });

      test('handles all field types together', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'id': NumericDatatypeWriter.int32(),
          'value': NumericDatatypeWriter.float64(),
          'name': StringDatatypeWriter.fixedLength(length: 10),
          'active': BooleanDatatypeWriter(),
        });

        expect(writer.getSize(), greaterThan(0));
        expect(writer.fieldNames.length, 4);
      });
    });

    group('Nested compound types', () {
      test('creates nested compound type', () {
        final innerWriter = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
          'y': NumericDatatypeWriter.float64(),
        });

        final outerWriter = CompoundDatatypeWriter.fromFields({
          'id': NumericDatatypeWriter.int32(),
          'position': innerWriter,
        });

        expect(outerWriter.getSize(), greaterThan(0));
        expect(outerWriter.fieldNames.length, 2);
      });

      test('handles deeply nested compound types', () {
        final level3 = CompoundDatatypeWriter.fromFields({
          'value': NumericDatatypeWriter.float64(),
        });

        final level2 = CompoundDatatypeWriter.fromFields({
          'data': level3,
        });

        final level1 = CompoundDatatypeWriter.fromFields({
          'nested': level2,
        });

        expect(level1.getSize(), greaterThan(0));
      });
    });

    group('Message format verification', () {
      test('compound message format matches HDF5 specification', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
          'y': NumericDatatypeWriter.float64(),
        });

        final message = writer.writeMessage();

        expect(message, isNotEmpty);

        // Class and version byte: version 1, class 6 (compound)
        expect(message[0], 0x16);

        // Class bit field 1: number of members (low byte) = 2
        expect(message[1], 2);

        // Class bit field 2: number of members (high byte) = 0
        expect(message[2], 0);

        // Class bit field 3: reserved
        expect(message[3], 0);

        // Size field (bytes 4-7): total compound size
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, writer.getSize());
      });

      test('compound message contains field names', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
          'y': NumericDatatypeWriter.float64(),
        });

        final message = writer.writeMessage();
        final messageStr = String.fromCharCodes(message);

        // Field names should be present in the message
        expect(messageStr.contains('x'), true);
        expect(messageStr.contains('y'), true);
      });

      test('compound message with single field', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'value': NumericDatatypeWriter.int32(),
        });

        final message = writer.writeMessage();

        // Number of members should be 1
        expect(message[1], 1);
        expect(message[2], 0);
      });

      test('compound message with many fields', () {
        final fields = <String, DatatypeWriter>{};
        for (int i = 0; i < 10; i++) {
          fields['field$i'] = NumericDatatypeWriter.int32();
        }

        final writer = CompoundDatatypeWriter.fromFields(fields);
        final message = writer.writeMessage();

        // Number of members should be 10
        expect(message[1], 10);
        expect(message[2], 0);
      });
    });

    group('Value encoding', () {
      test('encodes simple numeric values', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
          'y': NumericDatatypeWriter.float64(),
        });

        final encoded = writer.encodeValues({
          'x': 1.0,
          'y': 2.0,
        });

        expect(encoded, isNotEmpty);
        expect(encoded.length, writer.getSize());
      });

      test('encodes mixed type values', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'id': NumericDatatypeWriter.int32(),
          'value': NumericDatatypeWriter.float64(),
        });

        final encoded = writer.encodeValues({
          'id': 42,
          'value': 3.14,
        });

        expect(encoded, isNotEmpty);
        expect(encoded.length, writer.getSize());
      });

      test('encodes string values', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'id': NumericDatatypeWriter.int32(),
          'name': StringDatatypeWriter.fixedLength(length: 10),
        });

        final encoded = writer.encodeValues({
          'id': 1,
          'name': 'test',
        });

        expect(encoded, isNotEmpty);
        expect(encoded.length, writer.getSize());
      });

      test('encodes boolean values', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'id': NumericDatatypeWriter.int32(),
          'active': BooleanDatatypeWriter(),
        });

        final encoded = writer.encodeValues({
          'id': 1,
          'active': true,
        });

        expect(encoded, isNotEmpty);
        expect(encoded.length, writer.getSize());
      });

      test('throws error for missing field value', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
          'y': NumericDatatypeWriter.float64(),
        });

        expect(
          () => writer.encodeValues({'x': 1.0}),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('encodes nested compound values', () {
        final innerWriter = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
          'y': NumericDatatypeWriter.float64(),
        });

        final outerWriter = CompoundDatatypeWriter.fromFields({
          'id': NumericDatatypeWriter.int32(),
          'position': innerWriter,
        });

        final encoded = outerWriter.encodeValues({
          'id': 1,
          'position': {'x': 1.0, 'y': 2.0},
        });

        expect(encoded, isNotEmpty);
        expect(encoded.length, outerWriter.getSize());
      });
    });

    group('Consistency and edge cases', () {
      test('messages are consistent across multiple calls', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
          'y': NumericDatatypeWriter.float64(),
        });

        final message1 = writer.writeMessage();
        final message2 = writer.writeMessage();

        expect(message1, equals(message2));
      });

      test('field order is preserved', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'a': NumericDatatypeWriter.int32(),
          'b': NumericDatatypeWriter.int32(),
          'c': NumericDatatypeWriter.int32(),
        });

        final fieldNames = writer.fieldNames;
        expect(fieldNames[0], 'a');
        expect(fieldNames[1], 'b');
        expect(fieldNames[2], 'c');
      });

      test('different field combinations produce different messages', () {
        final writer1 = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.float64(),
        });

        final writer2 = CompoundDatatypeWriter.fromFields({
          'x': NumericDatatypeWriter.int32(),
        });

        final message1 = writer1.writeMessage();
        final message2 = writer2.writeMessage();

        expect(message1, isNot(equals(message2)));
      });

      test('calculates correct total size', () {
        final writer = CompoundDatatypeWriter.fromFields({
          'a': NumericDatatypeWriter.int8(), // 1 byte
          'b': NumericDatatypeWriter.int16(), // 2 bytes (+ padding)
          'c': NumericDatatypeWriter.int32(), // 4 bytes (+ padding)
          'd': NumericDatatypeWriter.int64(), // 8 bytes (+ padding)
        });

        // Size should account for alignment
        expect(writer.getSize(), greaterThanOrEqualTo(1 + 2 + 4 + 8));
      });
    });
  });
}
