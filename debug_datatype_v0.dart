import 'dart:typed_data';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  // Datatype bytes from the attribute
  final datatypeBytes = Uint8List.fromList([
    0x01,
    0x01,
    0x00,
    0x10,
    0x00,
    0x00,
    0x00,
    0x10,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x08,
    0x00,
    0x00
  ]);

  print('Datatype bytes (${datatypeBytes.length} bytes):');
  for (int i = 0; i < datatypeBytes.length; i += 8) {
    final chunk =
        datatypeBytes.sublist(i, (i + 8).clamp(0, datatypeBytes.length));
    final hex = chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    print('  ${i.toString().padLeft(2)}: $hex');
  }

  final reader = ByteReader.fromBytes(datatypeBytes);

  print('\nParsing as version 0/1 floating-point:');
  final classAndVersion = await reader.readUint8();
  final classId = classAndVersion & 0x0F;
  final version = (classAndVersion >> 4) & 0x0F;
  print('Class ID: $classId (${classId == 1 ? "floating-point" : "unknown"})');
  print('Version: $version');

  final classBitField1 = await reader.readUint8();
  final classBitField2 = await reader.readUint8();
  final classBitField3 = await reader.readUint8();
  print(
      'Class bit fields: 0x${classBitField1.toRadixString(16)} 0x${classBitField2.toRadixString(16)} 0x${classBitField3.toRadixString(16)}');

  // For version 0/1 floating-point, the next fields are:
  // - bit offset (2 bytes)
  // - bit precision (2 bytes)
  // - exponent location (1 byte)
  // - exponent size (1 byte)
  // - mantissa location (1 byte)
  // - mantissa size (1 byte)
  // - exponent bias (4 bytes)
  // THEN the size (4 bytes)

  print('\nReading floating-point properties:');
  final bitOffset = await reader.readUint16();
  final bitPrecision = await reader.readUint16();
  print('Bit offset: $bitOffset');
  print('Bit precision: $bitPrecision');

  final exponentLocation = await reader.readUint8();
  final exponentSize = await reader.readUint8();
  final mantissaLocation = await reader.readUint8();
  final mantissaSize = await reader.readUint8();
  print('Exponent location: $exponentLocation, size: $exponentSize');
  print('Mantissa location: $mantissaLocation, size: $mantissaSize');

  final exponentBias = await reader.readUint32();
  print('Exponent bias: $exponentBias');

  print('\nRemaining bytes: ${datatypeBytes.length - reader.position}');
  if (reader.position < datatypeBytes.length) {
    final remaining = datatypeBytes.sublist(reader.position);
    print(
        'Remaining: ${remaining.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  }
}
