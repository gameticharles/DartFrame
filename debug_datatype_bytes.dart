import 'dart:io';
import 'dart:typed_data';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/io/hdf5/superblock.dart';
import 'package:dartframe/src/io/hdf5/group.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    final superblock = await Superblock.read(reader, filePath: file.path);
    final rootAddress =
        superblock.rootGroupObjectHeaderAddress + superblock.hdf5StartOffset;
    final rootGroup = await Group.read(reader, rootAddress,
        hdf5Offset: superblock.hdf5StartOffset, filePath: file.path);

    final dataAddress = rootGroup.getChildAddress('data');
    final adjustedAddress = dataAddress! + superblock.hdf5StartOffset;

    // Navigate to the attribute message
    reader.seek(0x3b0);

    final type = await reader.readUint16();
    final size = await reader.readUint16();
    final flags = await reader.readUint8();
    await reader.readBytes(3); // reserved

    // Read the message data
    final messageData = await reader.readBytes(size);
    final messageReader = ByteReader.fromBytes(Uint8List.fromList(messageData));

    // Parse attribute header
    final version = await messageReader.readUint8();
    await messageReader.readUint8(); // reserved
    final nameSize = await messageReader.readUint16();
    final datatypeSize = await messageReader.readUint16();
    final dataspaceSize = await messageReader.readUint16();

    print('Attribute version: $version');
    print('Name size: $nameSize');
    print('Datatype size: $datatypeSize');
    print('Dataspace size: $dataspaceSize');

    // Read name
    final nameBytes = await messageReader.readBytes(nameSize);
    final nullIndex = nameBytes.indexOf(0);
    final name = String.fromCharCodes(
      nullIndex >= 0 ? nameBytes.sublist(0, nullIndex) : nameBytes,
    );
    print('Name: "$name"');

    // Calculate padding after name
    int bytesRead = 7 + nameSize;
    int padding = (8 - (bytesRead % 8)) % 8;
    print('Padding after name: $padding bytes');
    if (padding > 0) {
      await messageReader.readBytes(padding);
    }

    // Read datatype bytes
    print('\nDatatype bytes ($datatypeSize bytes):');
    final datatypeBytes = await messageReader.readBytes(datatypeSize);
    for (int i = 0; i < datatypeBytes.length; i += 16) {
      final chunk =
          datatypeBytes.sublist(i, (i + 16).clamp(0, datatypeBytes.length));
      final hex =
          chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      print('  ${i.toRadixString(16).padLeft(4, '0')}: $hex');
    }

    // Parse datatype manually
    print('\nParsing datatype:');
    final datatypeReader =
        ByteReader.fromBytes(Uint8List.fromList(datatypeBytes));
    final classAndVersion = await datatypeReader.readUint8();
    final classId = classAndVersion & 0x0F;
    final dtVersion = (classAndVersion >> 4) & 0x0F;
    print('Class ID: $classId');
    print('Version: $dtVersion');

    final classBitField = await datatypeReader.readUint8();
    final classBitField2 = await datatypeReader.readUint8();
    final classBitField3 = await datatypeReader.readUint8();
    print(
        'Class bit fields: 0x${classBitField.toRadixString(16)} 0x${classBitField2.toRadixString(16)} 0x${classBitField3.toRadixString(16)}');

    final dtSize = await datatypeReader.readUint32();
    print('Datatype size: $dtSize');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await raf.close();
  }
}
