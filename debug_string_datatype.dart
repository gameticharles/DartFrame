import 'dart:typed_data';

import 'package:dartframe/dartframe.dart';

void main() async {
  final fileIO = FileIO();
  final filePath = 'example/data/test_attributes.h5';
  final raf = await fileIO.openRandomAccess(filePath);
  final reader = ByteReader(raf);

  try {
    final superblock = await Superblock.read(reader, filePath: filePath);
    final rootAddress =
        superblock.rootGroupObjectHeaderAddress + superblock.hdf5StartOffset;
    final rootGroup = await Group.read(reader, rootAddress,
        hdf5Offset: superblock.hdf5StartOffset, filePath: filePath);

    final dataAddress = rootGroup.getChildAddress('data');
    final adjustedAddress = dataAddress! + superblock.hdf5StartOffset;

    // From the continuation block, let's find a string attribute
    // The "units" attribute is at the beginning, let's look for "description"
    // which should be the second attribute

    // Navigate to continuation block (from debug output, it's at 0x430)
    reader.seek(0x430);

    print('Reading continuation block messages:');

    // Skip first attribute message (units)
    // Message header: 8 bytes
    // Message data: 64 bytes (from earlier debug)
    // Padding: 0 bytes (64 % 8 == 0)
    reader.seek(0x430 + 8 + 64);

    print('\nReading second attribute message (description):');
    final type = await reader.readUint16();
    final size = await reader.readUint16();
    print('Type: 0x${type.toRadixString(16).padLeft(4, '0')}');
    print('Size: $size');

    await reader.readUint8(); // flags
    await reader.readBytes(3); // reserved

    final messageData = await reader.readBytes(size);
    print('\nMessage data (first 64 bytes):');
    for (int i = 0; i < messageData.length && i < 64; i += 16) {
      final chunk =
          messageData.sublist(i, (i + 16).clamp(0, messageData.length));
      final hex =
          chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      print('  ${i.toRadixString(16).padLeft(4, '0')}: $hex');
    }

    // Parse attribute
    final messageReader = ByteReader.fromBytes(Uint8List.fromList(messageData));
    final version = await messageReader.readUint8();
    await messageReader.readUint8(); // reserved
    final nameSize = await messageReader.readUint16();
    final datatypeSize = await messageReader.readUint16();
    final dataspaceSize = await messageReader.readUint16();

    print('\nAttribute header:');
    print('Version: $version');
    print('Name size: $nameSize');
    print('Datatype size: $datatypeSize');
    print('Dataspace size: $dataspaceSize');

    // Read name
    final nameBytes = await messageReader.readBytes(nameSize);
    final name = String.fromCharCodes(nameBytes.where((b) => b != 0));
    print('Name: "$name"');

    // Align after name
    int bytesRead = 7 + nameSize;
    int padding = (8 - (bytesRead % 8)) % 8;
    if (padding > 0) {
      await messageReader.readBytes(padding);
    }

    // Read datatype
    print('\nDatatype bytes ($datatypeSize bytes):');
    final datatypeBytes = await messageReader.readBytes(datatypeSize);
    for (int i = 0; i < datatypeBytes.length; i += 16) {
      final chunk =
          datatypeBytes.sublist(i, (i + 16).clamp(0, datatypeBytes.length));
      final hex =
          chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      print('  ${i.toRadixString(16).padLeft(4, '0')}: $hex');
    }

    // Parse datatype
    final datatypeReader =
        ByteReader.fromBytes(Uint8List.fromList(datatypeBytes));
    final classAndVersion = await datatypeReader.readUint8();
    final classId = classAndVersion & 0x0F;
    final dtVersion = (classAndVersion >> 4) & 0x0F;
    print('\nDatatype class: $classId (3=string)');
    print('Datatype version: $dtVersion');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await raf.close();
  }
}
