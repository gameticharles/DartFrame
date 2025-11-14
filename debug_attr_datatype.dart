import 'dart:typed_data';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/io/hdf5/datatype.dart';

void main() async {
  // The datatype bytes for the "units" attribute
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

  print('Datatype bytes:');
  for (int i = 0; i < datatypeBytes.length; i += 8) {
    final chunk =
        datatypeBytes.sublist(i, (i + 8).clamp(0, datatypeBytes.length));
    final hex = chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    print('  $i: $hex');
  }

  final reader = ByteReader.fromBytes(datatypeBytes);

  print('\nManual parsing:');
  final classAndVersion = await reader.readUint8();
  final classId = classAndVersion & 0x0F;
  final version = (classAndVersion >> 4) & 0x0F;
  print('Class ID: $classId (0=int, 1=float, 3=string)');
  print('Version: $version');

  // Reset and parse with Hdf5Datatype
  reader.seek(0);
  print('\nParsing with Hdf5Datatype.read():');
  try {
    final datatype = await Hdf5Datatype.read(reader);
    print('Datatype class: ${datatype.dataclass}');
    print('Datatype size: ${datatype.size}');
    print('Is string: ${datatype.isString}');
    print('Is float: ${datatype.classId == 1}');
  } catch (e) {
    print('Error: $e');
  }
}
