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

    // Navigate to the attribute message manually
    // From debug output: Message 4 at position 0x3b0, Type: 0x000c, Size: 64
    reader.seek(0x3b0);

    print('Reading attribute message at 0x3b0');
    final type = await reader.readUint16();
    final size = await reader.readUint16();
    final flags = await reader.readUint8();
    await reader.readBytes(3); // reserved

    print('Type: 0x${type.toRadixString(16).padLeft(4, '0')}');
    print('Size: $size');
    print('Flags: 0x${flags.toRadixString(16)}');

    // Read the message data
    final messageData = await reader.readBytes(size);
    print('\nMessage data (first 64 bytes):');
    for (int i = 0; i < messageData.length && i < 64; i += 16) {
      final chunk =
          messageData.sublist(i, (i + 16).clamp(0, messageData.length));
      final hex =
          chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      final ascii = chunk
          .map((b) => (b >= 32 && b < 127) ? String.fromCharCode(b) : '.')
          .join('');
      print('${i.toRadixString(16).padLeft(4, '0')}: $hex  $ascii');
    }

    // Try to parse the attribute
    print('\nAttempting to parse attribute...');
    final messageReader = ByteReader.fromBytes(Uint8List.fromList(messageData));

    final version = await messageReader.readUint8();
    print('Attribute version: $version');

    if (version == 1) {
      await messageReader.readUint8(); // reserved
      final nameSize = await messageReader.readUint16();
      final datatypeSize = await messageReader.readUint16();
      final dataspaceSize = await messageReader.readUint16();

      print('Name size: $nameSize');
      print('Datatype size: $datatypeSize');
      print('Dataspace size: $dataspaceSize');

      // Read name
      final nameBytes = await messageReader.readBytes(nameSize);
      final nullIndex = nameBytes.indexOf(0);
      final name = String.fromCharCodes(
        nullIndex >= 0 ? nameBytes.sublist(0, nullIndex) : nameBytes,
      );
      print('Attribute name: "$name"');
    }
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await raf.close();
  }
}
