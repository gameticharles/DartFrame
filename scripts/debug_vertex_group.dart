import 'dart:io';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/io/hdf5/superblock.dart';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

void main() async {
  print('🔬 Debugging /vertex group\n');

  final file = File('example/data/processdata.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    // Read superblock
    final superblock = await Superblock.read(reader, filePath: file.path);
    final hdf5Offset = superblock.hdf5StartOffset;

    print('HDF5 offset: $hdf5Offset\n');

    // Get vertex address
    final hdf5File = await Hdf5File.open('example/data/processdata.h5');
    final rootGroup = await hdf5File.group('/');
    final vertexRawAddress = rootGroup.getChildAddress('vertex');

    if (vertexRawAddress == null) {
      print('❌ Could not find vertex address');
      await hdf5File.close();
      return;
    }

    final vertexAddress = vertexRawAddress + hdf5Offset;
    print('Vertex raw address: 0x${vertexRawAddress.toRadixString(16)}');
    print('Vertex adjusted address: 0x${vertexAddress.toRadixString(16)}\n');

    // Read object header
    reader.seek(vertexAddress);

    final version = await reader.readUint8();
    print('Object header version: $version');

    await reader.readBytes(1); // reserved
    final totalMessages = await reader.readUint16();
    print('Total messages: $totalMessages');

    await reader.readUint32(); // ref count
    final headerSize = await reader.readUint32();
    print('Header size: $headerSize');

    if (version == 1) {
      await reader.readBytes(4); // reserved
    }

    print('\nMessages:');
    for (int i = 0; i < totalMessages; i++) {
      print('\n--- Message $i ---');
      final msgType = await reader.readUint16();
      final msgSize = await reader.readUint16();
      final msgFlags = await reader.readUint8();
      await reader.readBytes(3); // reserved

      print('Type: 0x${msgType.toRadixString(16)} ($msgType)');
      print('Size: $msgSize bytes');
      print('Flags: $msgFlags');

      // Read message data
      final msgData = await reader.readBytes(msgSize);

      // Check if it's a known message type
      String msgTypeName;
      switch (msgType) {
        case 0x0000:
          msgTypeName = 'NIL';
          break;
        case 0x0001:
          msgTypeName = 'Dataspace';
          break;
        case 0x0002:
          msgTypeName = 'Link Info';
          break;
        case 0x0003:
          msgTypeName = 'Datatype';
          break;
        case 0x0005:
          msgTypeName = 'Fill Value';
          break;
        case 0x0008:
          msgTypeName = 'Data Layout';
          break;
        case 0x000A:
          msgTypeName = 'Group Info';
          break;
        case 0x000B:
          msgTypeName = 'Filter Pipeline';
          break;
        case 0x000C:
          msgTypeName = 'Attribute';
          break;
        case 0x0010:
          msgTypeName = 'Header Continuation';
          break;
        case 0x0011:
          msgTypeName = 'Symbol Table';
          break;
        case 0x0016:
          msgTypeName = 'Link';
          break;
        default:
          msgTypeName = 'UNKNOWN';
      }

      print('Message type name: $msgTypeName');

      if (msgTypeName == 'UNKNOWN') {
        print(
            'Raw data (first 32 bytes): ${msgData.take(32).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      }

      // Padding
      final padding = (8 - (msgSize % 8)) % 8;
      if (padding > 0) {
        await reader.readBytes(padding);
      }
    }

    await hdf5File.close();
  } finally {
    await raf.close();
  }
}
