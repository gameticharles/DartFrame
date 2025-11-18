import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/datatype_writer.dart';
import 'package:dartframe/src/io/hdf5/datatype.dart';

void main() {
  group('StringDatatypeWriter', () {
    group('Fixed-length strings', () {
      test('creates correct message for fixed-length ASCII string', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 20,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
        );

        expect(writer.datatypeClass, Hdf5DatatypeClass.string);
        expect(writer.getSize(), 20);
        expect(writer.isVariableLength, false);

        final message = writer.writeMessage();
        expect(message.length, 8); // String datatype message is 8 bytes

        // Verify message structure
        final classAndVersion = message[0];
        expect(classAndVersion & 0x0F, 3); // class = 3 (string)
        expect((classAndVersion >> 4) & 0x0F, 1); // version = 1

        // Class bit field 1: padding type (bits 0-3) and character set (bits 4-7)
        final classBitField1 = message[1];
        expect(classBitField1 & 0x0F, 0); // null-terminate padding
        expect((classBitField1 >> 4) & 0x0F, 0); // ASCII character set

        // Size (bytes 4-7, little-endian)
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 20);
      });

      test('creates correct message for fixed-length UTF-8 string', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 50,
          paddingType: StringPaddingType.nullPad,
          characterSet: CharacterSet.utf8,
        );

        expect(writer.getSize(), 50);

        final message = writer.writeMessage();

        // Class bit field 1: padding type and character set
        final classBitField1 = message[1];
        expect(classBitField1 & 0x0F, 1); // null-pad padding
        expect((classBitField1 >> 4) & 0x0F, 1); // UTF-8 character set

        // Size
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 50);
      });

      test('creates correct message with space-pad padding', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 100,
          paddingType: StringPaddingType.spacePad,
          characterSet: CharacterSet.ascii,
        );

        final message = writer.writeMessage();

        // Class bit field 1: padding type
        final classBitField1 = message[1];
        expect(classBitField1 & 0x0F, 2); // space-pad padding
      });

      test('encodes fixed-length string with null-terminate padding', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 10,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
        );

        final encoded = writer.encodeString('hello');
        expect(encoded.length, 10);
        expect(encoded[0], 'h'.codeUnitAt(0));
        expect(encoded[1], 'e'.codeUnitAt(0));
        expect(encoded[2], 'l'.codeUnitAt(0));
        expect(encoded[3], 'l'.codeUnitAt(0));
        expect(encoded[4], 'o'.codeUnitAt(0));
        expect(encoded[5], 0); // null terminator
        expect(encoded[6], 0); // null padding
        expect(encoded[9], 0); // null padding
      });

      test('encodes fixed-length string with null-pad padding', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 10,
          paddingType: StringPaddingType.nullPad,
          characterSet: CharacterSet.ascii,
        );

        final encoded = writer.encodeString('test');
        expect(encoded.length, 10);
        expect(encoded[0], 't'.codeUnitAt(0));
        expect(encoded[1], 'e'.codeUnitAt(0));
        expect(encoded[2], 's'.codeUnitAt(0));
        expect(encoded[3], 't'.codeUnitAt(0));
        expect(encoded[4], 0); // null padding
        expect(encoded[9], 0); // null padding
      });

      test('encodes fixed-length string with space-pad padding', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 10,
          paddingType: StringPaddingType.spacePad,
          characterSet: CharacterSet.ascii,
        );

        final encoded = writer.encodeString('hi');
        expect(encoded.length, 10);
        expect(encoded[0], 'h'.codeUnitAt(0));
        expect(encoded[1], 'i'.codeUnitAt(0));
        expect(encoded[2], 0x20); // space
        expect(encoded[9], 0x20); // space
      });

      test('truncates string that exceeds fixed length', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 5,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
        );

        final encoded = writer.encodeString('hello world');
        expect(encoded.length, 5);
        expect(String.fromCharCodes(encoded), 'hello');
      });

      test('encodes UTF-8 string correctly', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 20,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.utf8,
        );

        final encoded = writer.encodeString('héllo');
        expect(encoded.length, 20);
        // 'héllo' in UTF-8: h(0x68) é(0xC3 0xA9) l(0x6C) l(0x6C) o(0x6F)
        expect(encoded[0], 0x68); // h
        expect(encoded[1], 0xC3); // é first byte
        expect(encoded[2], 0xA9); // é second byte
        expect(encoded[3], 0x6C); // l
        expect(encoded[4], 0x6C); // l
        expect(encoded[5], 0x6F); // o
        expect(encoded[6], 0); // null terminator
      });

      test('handles empty string', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 10,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
        );

        final encoded = writer.encodeString('');
        expect(encoded.length, 10);
        expect(encoded[0], 0); // null terminator
        expect(encoded.every((b) => b == 0), true); // all null bytes
      });

      test('rejects invalid length', () {
        expect(
          () => StringDatatypeWriter.fixedLength(
            length: 0,
            paddingType: StringPaddingType.nullTerminate,
            characterSet: CharacterSet.ascii,
          ),
          throwsArgumentError,
        );

        expect(
          () => StringDatatypeWriter.fixedLength(
            length: -5,
            paddingType: StringPaddingType.nullTerminate,
            characterSet: CharacterSet.ascii,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Variable-length strings', () {
      test('creates correct message for variable-length ASCII string', () {
        final writer = StringDatatypeWriter.variableLength(
          characterSet: CharacterSet.ascii,
        );

        expect(writer.datatypeClass, Hdf5DatatypeClass.string);
        expect(writer.getSize(), -1); // Variable-length indicator
        expect(writer.isVariableLength, true);

        final message = writer.writeMessage();
        expect(message.length, 8);

        // Verify message structure
        final classAndVersion = message[0];
        expect(classAndVersion & 0x0F, 3); // class = 3 (string)
        expect((classAndVersion >> 4) & 0x0F, 1); // version = 1

        // Class bit field 1: character set
        final classBitField1 = message[1];
        expect((classBitField1 >> 4) & 0x0F, 0); // ASCII character set

        // Size should be 0xFFFFFFFF for variable-length
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 0xFFFFFFFF);
      });

      test('creates correct message for variable-length UTF-8 string', () {
        final writer = StringDatatypeWriter.variableLength(
          characterSet: CharacterSet.utf8,
        );

        expect(writer.getSize(), -1);

        final message = writer.writeMessage();

        // Class bit field 1: character set
        final classBitField1 = message[1];
        expect((classBitField1 >> 4) & 0x0F, 1); // UTF-8 character set

        // Size should be 0xFFFFFFFF
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 0xFFFFFFFF);
      });

      test('encodes variable-length ASCII string without padding', () {
        final writer = StringDatatypeWriter.variableLength(
          characterSet: CharacterSet.ascii,
        );

        final encoded = writer.encodeString('hello world');
        expect(encoded.length, 11); // No padding
        expect(String.fromCharCodes(encoded), 'hello world');
      });

      test('encodes variable-length UTF-8 string', () {
        final writer = StringDatatypeWriter.variableLength(
          characterSet: CharacterSet.utf8,
        );

        final encoded = writer.encodeString('héllo wörld');
        // UTF-8 encoding will be longer than ASCII
        expect(encoded.length, greaterThan(11));
        // Verify it can be decoded back
        expect(String.fromCharCodes(encoded),
            isNot('héllo wörld')); // Raw bytes won't match
      });

      test('encodes empty variable-length string', () {
        final writer = StringDatatypeWriter.variableLength(
          characterSet: CharacterSet.ascii,
        );

        final encoded = writer.encodeString('');
        expect(encoded.length, 0);
      });
    });

    group('Endianness', () {
      test('supports big-endian byte order', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 20,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
          endian: Endian.big,
        );

        expect(writer.endian, Endian.big);

        final message = writer.writeMessage();

        // Size should be in big-endian format
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.big);
        expect(size, 20);
      });

      test('defaults to little-endian', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 20,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
        );

        expect(writer.endian, Endian.little);
      });
    });

    group('Factory integration', () {
      test('factory creates variable-length string writer from hint', () {
        final writer = DatatypeWriterFactory.create(
          'test',
          hint: DatatypeHint.variableString,
        );

        expect(writer, isA<StringDatatypeWriter>());
        expect(writer.getSize(), -1);
      });

      test('factory creates fixed-length string writer from hint', () {
        final writer = DatatypeWriterFactory.create(
          'test',
          hint: DatatypeHint.fixedString,
        );

        expect(writer, isA<StringDatatypeWriter>());
        expect(writer.getSize(), 256); // Default fixed length
      });

      test('factory auto-detects string type', () {
        final writer = DatatypeWriterFactory.create('hello');

        expect(writer, isA<StringDatatypeWriter>());
        expect(writer.getSize(), -1); // Defaults to variable-length
      });
    });

    group('Message format verification', () {
      test('fixed-length message has correct structure', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 30,
          paddingType: StringPaddingType.nullPad,
          characterSet: CharacterSet.utf8,
        );

        final message = writer.writeMessage();

        // Message should be exactly 8 bytes
        expect(message.length, 8);

        // Byte 0: class and version
        expect(message[0], (1 << 4) | 3); // version 1, class 3

        // Byte 1: padding type (bits 0-3) and character set (bits 4-7)
        expect(message[1], 1 | (1 << 4)); // null-pad (1) + UTF-8 (1)

        // Bytes 2-3: reserved
        expect(message[2], 0);
        expect(message[3], 0);

        // Bytes 4-7: size (30 in little-endian)
        expect(message[4], 30);
        expect(message[5], 0);
        expect(message[6], 0);
        expect(message[7], 0);
      });

      test('variable-length message has correct structure', () {
        final writer = StringDatatypeWriter.variableLength(
          characterSet: CharacterSet.ascii,
        );

        final message = writer.writeMessage();

        // Message should be exactly 8 bytes
        expect(message.length, 8);

        // Byte 0: class and version
        expect(message[0], (1 << 4) | 3); // version 1, class 3

        // Byte 1: padding type (bits 0-3) and character set (bits 4-7)
        expect(message[1], 0 | (0 << 4)); // null-terminate (0) + ASCII (0)

        // Bytes 2-3: reserved
        expect(message[2], 0);
        expect(message[3], 0);

        // Bytes 4-7: size (0xFFFFFFFF for variable-length)
        expect(message[4], 0xFF);
        expect(message[5], 0xFF);
        expect(message[6], 0xFF);
        expect(message[7], 0xFF);
      });

      test('all padding types produce different messages', () {
        final nullTerminate = StringDatatypeWriter.fixedLength(
          length: 10,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
        ).writeMessage();

        final nullPad = StringDatatypeWriter.fixedLength(
          length: 10,
          paddingType: StringPaddingType.nullPad,
          characterSet: CharacterSet.ascii,
        ).writeMessage();

        final spacePad = StringDatatypeWriter.fixedLength(
          length: 10,
          paddingType: StringPaddingType.spacePad,
          characterSet: CharacterSet.ascii,
        ).writeMessage();

        // All should differ in byte 1 (padding type)
        expect(nullTerminate[1] & 0x0F, 0);
        expect(nullPad[1] & 0x0F, 1);
        expect(spacePad[1] & 0x0F, 2);
      });

      test('character sets produce different messages', () {
        final ascii = StringDatatypeWriter.fixedLength(
          length: 10,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
        ).writeMessage();

        final utf8 = StringDatatypeWriter.fixedLength(
          length: 10,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.utf8,
        ).writeMessage();

        // Should differ in byte 1 (character set)
        expect((ascii[1] >> 4) & 0x0F, 0);
        expect((utf8[1] >> 4) & 0x0F, 1);
      });
    });

    group('Edge cases', () {
      test('handles very long fixed-length strings', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 10000,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
        );

        expect(writer.getSize(), 10000);

        final message = writer.writeMessage();
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 10000);
      });

      test('handles string with special characters', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 50,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
        );

        final encoded = writer.encodeString('hello\nworld\ttab');
        expect(encoded.length, 50);
        expect(encoded[5], 10); // newline
        expect(encoded[11], 9); // tab
      });

      test('multiple writers can be created independently', () {
        final writer1 = StringDatatypeWriter.fixedLength(
          length: 10,
          paddingType: StringPaddingType.nullTerminate,
          characterSet: CharacterSet.ascii,
        );

        final writer2 = StringDatatypeWriter.variableLength(
          characterSet: CharacterSet.utf8,
        );

        expect(writer1.getSize(), 10);
        expect(writer2.getSize(), -1);
        expect(writer1.writeMessage(), isNot(equals(writer2.writeMessage())));
      });

      test('messages are consistent across multiple calls', () {
        final writer = StringDatatypeWriter.fixedLength(
          length: 20,
          paddingType: StringPaddingType.nullPad,
          characterSet: CharacterSet.utf8,
        );

        final message1 = writer.writeMessage();
        final message2 = writer.writeMessage();

        expect(message1, equals(message2));
      });
    });
  });
}
