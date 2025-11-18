import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/byte_writer.dart';

void main() {
  group('ByteWriter - Basic Operations', () {
    test('should initialize with empty buffer', () {
      final writer = ByteWriter();
      expect(writer.position, equals(0));
      expect(writer.size, equals(0));
      expect(writer.bytes, isEmpty);
    });

    test('should track position correctly', () {
      final writer = ByteWriter();
      expect(writer.position, equals(0));

      writer.writeUint8(1);
      expect(writer.position, equals(1));

      writer.writeUint16(2);
      expect(writer.position, equals(3));

      writer.writeUint32(3);
      expect(writer.position, equals(7));

      writer.writeUint64(4);
      expect(writer.position, equals(15));
    });

    test('should clear buffer', () {
      final writer = ByteWriter();
      writer.writeUint32(12345);
      expect(writer.size, equals(4));

      writer.clear();
      expect(writer.size, equals(0));
      expect(writer.position, equals(0));
    });
  });

  group('ByteWriter - Unsigned Integer Writing', () {
    test('should write uint8 correctly', () {
      final writer = ByteWriter();
      writer.writeUint8(0);
      writer.writeUint8(127);
      writer.writeUint8(255);

      expect(writer.bytes, equals([0, 127, 255]));
    });

    test('should write uint16 correctly with little endian', () {
      final writer = ByteWriter(endian: Endian.little);
      writer.writeUint16(0);
      writer.writeUint16(256);
      writer.writeUint16(65535);

      expect(
          writer.bytes,
          equals([
            0, 0, // 0
            0, 1, // 256
            255, 255, // 65535
          ]));
    });

    test('should write uint16 correctly with big endian', () {
      final writer = ByteWriter(endian: Endian.big);
      writer.writeUint16(0);
      writer.writeUint16(256);
      writer.writeUint16(65535);

      expect(
          writer.bytes,
          equals([
            0, 0, // 0
            1, 0, // 256
            255, 255, // 65535
          ]));
    });

    test('should write uint32 correctly with little endian', () {
      final writer = ByteWriter(endian: Endian.little);
      writer.writeUint32(0);
      writer.writeUint32(16909060); // 0x01020304
      writer.writeUint32(4294967295); // max uint32

      expect(
          writer.bytes,
          equals([
            0, 0, 0, 0, // 0
            4, 3, 2, 1, // 16909060
            255, 255, 255, 255, // 4294967295
          ]));
    });

    test('should write uint32 correctly with big endian', () {
      final writer = ByteWriter(endian: Endian.big);
      writer.writeUint32(0);
      writer.writeUint32(16909060); // 0x01020304

      expect(
          writer.bytes,
          equals([
            0, 0, 0, 0, // 0
            1, 2, 3, 4, // 16909060
          ]));
    });

    test('should write uint64 correctly with little endian', () {
      final writer = ByteWriter(endian: Endian.little);
      writer.writeUint64(0);
      writer.writeUint64(72623859790382856); // 0x0102030405060708

      expect(
          writer.bytes,
          equals([
            0, 0, 0, 0, 0, 0, 0, 0, // 0
            8, 7, 6, 5, 4, 3, 2, 1, // 72623859790382856
          ]));
    });

    test('should write uint64 correctly with big endian', () {
      final writer = ByteWriter(endian: Endian.big);
      writer.writeUint64(0);
      writer.writeUint64(72623859790382856); // 0x0102030405060708

      expect(
          writer.bytes,
          equals([
            0, 0, 0, 0, 0, 0, 0, 0, // 0
            1, 2, 3, 4, 5, 6, 7, 8, // 72623859790382856
          ]));
    });
  });

  group('ByteWriter - Signed Integer Writing', () {
    test('should write int8 correctly', () {
      final writer = ByteWriter();
      writer.writeInt8(-128);
      writer.writeInt8(0);
      writer.writeInt8(127);

      expect(writer.bytes, equals([128, 0, 127]));
    });

    test('should write int16 correctly with little endian', () {
      final writer = ByteWriter(endian: Endian.little);
      writer.writeInt16(-32768);
      writer.writeInt16(0);
      writer.writeInt16(32767);

      expect(
          writer.bytes,
          equals([
            0, 128, // -32768
            0, 0, // 0
            255, 127, // 32767
          ]));
    });

    test('should write int32 correctly with little endian', () {
      final writer = ByteWriter(endian: Endian.little);
      writer.writeInt32(-2147483648);
      writer.writeInt32(0);
      writer.writeInt32(2147483647);

      expect(
          writer.bytes,
          equals([
            0, 0, 0, 128, // -2147483648
            0, 0, 0, 0, // 0
            255, 255, 255, 127, // 2147483647
          ]));
    });

    test('should write int64 correctly with little endian', () {
      final writer = ByteWriter(endian: Endian.little);
      writer.writeInt64(-9223372036854775808);
      writer.writeInt64(0);
      writer.writeInt64(9223372036854775807);

      expect(
          writer.bytes,
          equals([
            0, 0, 0, 0, 0, 0, 0, 128, // min int64
            0, 0, 0, 0, 0, 0, 0, 0, // 0
            255, 255, 255, 255, 255, 255, 255, 127, // max int64
          ]));
    });
  });

  group('ByteWriter - Floating Point Writing', () {
    test('should write float32 correctly with little endian', () {
      final writer = ByteWriter(endian: Endian.little);
      writer.writeFloat32(0.0);
      writer.writeFloat32(1.0);
      writer.writeFloat32(-1.0);
      writer.writeFloat32(3.14159);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat32(0, Endian.little), equals(0.0));
      expect(byteData.getFloat32(4, Endian.little), equals(1.0));
      expect(byteData.getFloat32(8, Endian.little), equals(-1.0));
      expect(byteData.getFloat32(12, Endian.little), closeTo(3.14159, 0.00001));
    });

    test('should write float32 correctly with big endian', () {
      final writer = ByteWriter(endian: Endian.big);
      writer.writeFloat32(0.0);
      writer.writeFloat32(1.0);
      writer.writeFloat32(-1.0);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat32(0, Endian.big), equals(0.0));
      expect(byteData.getFloat32(4, Endian.big), equals(1.0));
      expect(byteData.getFloat32(8, Endian.big), equals(-1.0));
    });

    test('should write float64 correctly with little endian', () {
      final writer = ByteWriter(endian: Endian.little);
      writer.writeFloat64(0.0);
      writer.writeFloat64(1.0);
      writer.writeFloat64(-1.0);
      writer.writeFloat64(3.141592653589793);
      writer.writeFloat64(1.7976931348623157e+308); // near max double

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.little), equals(0.0));
      expect(byteData.getFloat64(8, Endian.little), equals(1.0));
      expect(byteData.getFloat64(16, Endian.little), equals(-1.0));
      expect(byteData.getFloat64(24, Endian.little), equals(3.141592653589793));
      expect(byteData.getFloat64(32, Endian.little),
          equals(1.7976931348623157e+308));
    });

    test('should write float64 correctly with big endian', () {
      final writer = ByteWriter(endian: Endian.big);
      writer.writeFloat64(0.0);
      writer.writeFloat64(1.0);
      writer.writeFloat64(-1.0);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.big), equals(0.0));
      expect(byteData.getFloat64(8, Endian.big), equals(1.0));
      expect(byteData.getFloat64(16, Endian.big), equals(-1.0));
    });
  });

  group('ByteWriter - String and Bytes Writing', () {
    test('should write raw bytes', () {
      final writer = ByteWriter();
      writer.writeBytes([1, 2, 3, 4, 5]);

      expect(writer.bytes, equals([1, 2, 3, 4, 5]));
      expect(writer.position, equals(5));
    });

    test('should write string with null termination', () {
      final writer = ByteWriter();
      writer.writeString('Hello', nullTerminate: true);

      expect(writer.bytes, equals([72, 101, 108, 108, 111, 0]));
    });

    test('should write string without null termination', () {
      final writer = ByteWriter();
      writer.writeString('Hello', nullTerminate: false);

      expect(writer.bytes, equals([72, 101, 108, 108, 111]));
    });

    test('should write empty string', () {
      final writer = ByteWriter();
      writer.writeString('', nullTerminate: true);

      expect(writer.bytes, equals([0]));
    });
  });

  group('ByteWriter - Alignment and Padding', () {
    test('should align to 4-byte boundary', () {
      final writer = ByteWriter();
      writer.writeUint8(1);
      expect(writer.position, equals(1));

      writer.alignTo(4);
      expect(writer.position, equals(4));
      expect(writer.bytes, equals([1, 0, 0, 0]));
    });

    test('should align to 8-byte boundary', () {
      final writer = ByteWriter();
      writer.writeUint8(1);
      writer.writeUint8(2);
      writer.writeUint8(3);
      expect(writer.position, equals(3));

      writer.alignTo(8);
      expect(writer.position, equals(8));
      expect(writer.bytes, equals([1, 2, 3, 0, 0, 0, 0, 0]));
    });

    test('should not add padding when already aligned', () {
      final writer = ByteWriter();
      writer.writeUint32(1);
      expect(writer.position, equals(4));

      writer.alignTo(4);
      expect(writer.position, equals(4));
      expect(writer.bytes.length, equals(4));
    });

    test('should handle alignment of empty buffer', () {
      final writer = ByteWriter();
      writer.alignTo(8);
      expect(writer.position, equals(0));
      expect(writer.bytes, isEmpty);
    });

    test('should throw error for invalid boundary', () {
      final writer = ByteWriter();
      expect(() => writer.alignTo(0), throwsArgumentError);
      expect(() => writer.alignTo(-1), throwsArgumentError);
    });
  });

  group('ByteWriter - Write At Position', () {
    test('should write at specific position', () {
      final writer = ByteWriter();
      writer.writeUint32(0);
      writer.writeUint32(0);
      writer.writeUint32(0);

      expect(writer.bytes, equals([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]));

      writer.writeAt(4, [1, 2, 3, 4]);
      expect(writer.bytes, equals([0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0]));
    });

    test('should update bytes at beginning', () {
      final writer = ByteWriter();
      writer.writeBytes([0, 0, 0, 0]);

      writer.writeAt(0, [255, 255]);
      expect(writer.bytes, equals([255, 255, 0, 0]));
    });

    test('should update bytes at end', () {
      final writer = ByteWriter();
      writer.writeBytes([0, 0, 0, 0]);

      writer.writeAt(2, [255, 255]);
      expect(writer.bytes, equals([0, 0, 255, 255]));
    });

    test('should throw error when position is out of bounds', () {
      final writer = ByteWriter();
      writer.writeUint32(0);

      expect(() => writer.writeAt(-1, [1]), throwsRangeError);
      expect(() => writer.writeAt(4, [1]), throwsRangeError);
      expect(() => writer.writeAt(100, [1]), throwsRangeError);
    });

    test('should throw error when write would exceed buffer', () {
      final writer = ByteWriter();
      writer.writeBytes([0, 0, 0, 0]);

      expect(() => writer.writeAt(2, [1, 2, 3]), throwsRangeError);
      expect(() => writer.writeAt(0, [1, 2, 3, 4, 5]), throwsRangeError);
    });
  });

  group('ByteWriter - Endianness Handling', () {
    test('should handle little endian for all types', () {
      final writer = ByteWriter(endian: Endian.little);

      writer.writeUint16(0x0102);
      writer.writeUint32(0x01020304);
      writer.writeUint64(0x0102030405060708);

      expect(
          writer.bytes,
          equals([
            2, 1, // uint16
            4, 3, 2, 1, // uint32
            8, 7, 6, 5, 4, 3, 2, 1, // uint64
          ]));
    });

    test('should handle big endian for all types', () {
      final writer = ByteWriter(endian: Endian.big);

      writer.writeUint16(0x0102);
      writer.writeUint32(0x01020304);
      writer.writeUint64(0x0102030405060708);

      expect(
          writer.bytes,
          equals([
            1, 2, // uint16
            1, 2, 3, 4, // uint32
            1, 2, 3, 4, 5, 6, 7, 8, // uint64
          ]));
    });

    test('should maintain endianness across multiple writes', () {
      final writerLE = ByteWriter(endian: Endian.little);
      final writerBE = ByteWriter(endian: Endian.big);

      for (int i = 0; i < 5; i++) {
        writerLE.writeUint16(0x0102);
        writerBE.writeUint16(0x0102);
      }

      expect(writerLE.bytes, equals([2, 1, 2, 1, 2, 1, 2, 1, 2, 1]));
      expect(writerBE.bytes, equals([1, 2, 1, 2, 1, 2, 1, 2, 1, 2]));
    });
  });

  group('ByteWriter - Complex Scenarios', () {
    test('should handle mixed type writes', () {
      final writer = ByteWriter(endian: Endian.little);

      writer.writeUint8(0xFF);
      writer.writeUint16(0x1234);
      writer.writeUint32(0x12345678);
      writer.writeFloat64(3.14159);
      writer.writeString('HDF5', nullTerminate: true);

      expect(writer.position, greaterThan(0));
      expect(writer.bytes[0], equals(0xFF));
    });

    test('should handle large buffer', () {
      final writer = ByteWriter();

      for (int i = 0; i < 10000; i++) {
        writer.writeUint64(i);
      }

      expect(writer.position, equals(80000));
      expect(writer.size, equals(80000));
    });

    test('should maintain data integrity after multiple operations', () {
      final writer = ByteWriter(endian: Endian.little);

      // Write initial data
      writer.writeUint32(0x12345678);
      writer.writeFloat64(2.71828);
      writer.writeString('test', nullTerminate: true);

      final initialSize = writer.size;

      // Align
      writer.alignTo(8);

      // Write more data
      writer.writeUint64(0xDEADBEEF);

      // Update earlier position
      writer.writeAt(0, [0xAB, 0xCD, 0xEF, 0x01]);

      expect(writer.size, greaterThan(initialSize));
      expect(writer.bytes[0], equals(0xAB));
      expect(writer.bytes[1], equals(0xCD));
    });
  });
}
