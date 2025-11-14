import 'dart:io';
import 'dart:typed_data';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    // Go to continuation block
    reader.seek(0x578);

    print('Reading messages in continuation block:');

    for (int i = 0; i < 10; i++) {
      final pos = reader.position;
      print('\n--- Message $i at 0x${pos.toRadixString(16)} ---');

      final type = await reader.readUint16();
      final size = await reader.readUint16();
      final flags = await reader.readUint8();
      await reader.readBytes(3);

      print('Type: 0x${type.toRadixString(16).padLeft(4, '0')}');
      print('Size: $size');

      if (type == 0x000c) {
        // Attribute
        final messageData = await reader.readBytes(size);
        final mr = ByteReader.fromBytes(Uint8List.fromList(messageData));

        final version = await mr.readUint8();
        await mr.readUint8();
        final nameSize = await mr.readUint16();
        final datatypeSize = await mr.readUint16();
        await mr.readUint16(); // dataspace size

        final nameBytes = await mr.readBytes(nameSize);
        final name = String.fromCharCodes(nameBytes.where((b) => b != 0));

        print('Attribute: $name');

        // Align
        int bytesRead = 7 + nameSize;
        int padding = (8 - (bytesRead % 8)) % 8;
        if (padding > 0) {
          await mr.readBytes(padding);
        }

        // Read datatype
        final datatypeBytes = await mr.readBytes(datatypeSize);
        final classAndVersion = datatypeBytes[0];
        final classId = classAndVersion & 0x0F;
        final dtVersion = (classAndVersion >> 4) & 0x0F;

        print('  Datatype class: $classId, version: $dtVersion');
        print(
            '  Datatype bytes: ${datatypeBytes.sublist(0, datatypeSize.clamp(0, 16)).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      } else {
        await reader.readBytes(size);
      }

      // Padding
      final padding = (8 - (size % 8)) % 8;
      if (padding > 0) {
        await reader.readBytes(padding);
      }

      if (reader.position >= 0x578 + 512) {
        print('\nReached end of continuation block');
        break;
      }
    }
  } catch (e, stackTrace) {
    print('Error: $e');
  } finally {
    await raf.close();
  }
}
