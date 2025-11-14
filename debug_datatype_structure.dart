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

  print(
      'Testing different interpretations of version 0 floating-point datatype:\n');

  print('Interpretation 1: Size at bytes 4-7 (current code)');
  var reader = ByteReader.fromBytes(datatypeBytes);
  await reader.readUint8(); // class/version
  await reader.readUint8(); // bitfield1
  await reader.readUint8(); // bitfield2
  await reader.readUint8(); // bitfield3
  var size = await reader.readUint32();
  print('  Size: $size (0x${size.toRadixString(16)})');
  print('  This gives us 268435456 - clearly wrong!\n');

  print('Interpretation 2: Size at bytes 16-19 (after float properties)');
  reader = ByteReader.fromBytes(datatypeBytes);
  await reader.readUint8(); // class/version
  await reader.readUint8(); // bitfield1
  await reader.readUint8(); // bitfield2
  await reader.readUint8(); // bitfield3
  await reader.readUint16(); // bit offset
  await reader.readUint16(); // bit precision
  await reader.readUint8(); // exponent location
  await reader.readUint8(); // exponent size
  await reader.readUint8(); // mantissa location
  await reader.readUint8(); // mantissa size
  await reader.readUint32(); // exponent bias
  size = await reader.readUint32();
  print('  Size: $size (0x${size.toRadixString(16)})');
  print('  This gives us 8 - that could be right for a double!\n');

  print('Let me check what a string datatype looks like...');
  print(
      'For strings, size should be at bytes 4-7 since there are no additional properties.');
  print('So the structure must be version-dependent.');
}
