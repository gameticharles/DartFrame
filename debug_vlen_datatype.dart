import 'dart:typed_data';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/io/hdf5/datatype.dart';

void main() async {
  // Variable-length string datatype from "description" attribute
  // Bytes: 19 01 01 00 10 00 00 00 10 00 00 00 01 00 00 00 00 00 08 00
  final datatypeBytes = Uint8List.fromList([
    0x19,
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
    0x00
  ]);

  print('Variable-length datatype bytes:');
  for (int i = 0; i < datatypeBytes.length; i += 8) {
    final chunk =
        datatypeBytes.sublist(i, (i + 8).clamp(0, datatypeBytes.length));
    final hex = chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    print('  $i: $hex');
  }

  print('\nManual parsing:');
  final reader = ByteReader.fromBytes(datatypeBytes);

  final classAndVersion = await reader.readUint8();
  final classId = classAndVersion & 0x0F;
  final version = (classAndVersion >> 4) & 0x0F;
  print('Class: $classId (9=vlen), Version: $version');

  final classBitField1 = await reader.readUint8();
  final classBitField2 = await reader.readUint8();
  final classBitField3 = await reader.readUint8();
  print(
      'Bit fields: 0x${classBitField1.toRadixString(16)} 0x${classBitField2.toRadixString(16)} 0x${classBitField3.toRadixString(16)}');

  // For version 1, size comes here
  final size = await reader.readUint32();
  print('Size: $size');

  print('\nRemaining bytes (base type):');
  final remaining = datatypeBytes.sublist(reader.position);
  print(
      '  ${remaining.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

  // Parse base type
  print('\nBase type:');
  final baseClassAndVersion = remaining[0];
  final baseClassId = baseClassAndVersion & 0x0F;
  final baseVersion = (baseClassAndVersion >> 4) & 0x0F;
  print('  Class: $baseClassId (3=string), Version: $baseVersion');

  // Try parsing with Hdf5Datatype.read
  print('\nParsing with Hdf5Datatype.read():');
  reader.seek(0);
  try {
    final datatype = await Hdf5Datatype.read(reader);
    print('Success!');
    print('  Datatype class: ${datatype.dataclass}');
    print('  Size: ${datatype.size}');
    print('  Base type: ${datatype.baseType}');
    if (datatype.baseType != null) {
      print('  Base type class: ${datatype.baseType!.dataclass}');
      print('  Base type is string: ${datatype.baseType!.isString}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
