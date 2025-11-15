import 'dart:typed_data';
import 'package:dartframe/dartframe.dart';

void main() async {
  print('🔬 Debugging layout parsing for processdata.h5\n');

  final fileIO = FileIO();
  final filePath = 'example/data/processdata.h5';
  final raf = await fileIO.openRandomAccess(filePath);
  final reader = ByteReader(raf);

  try {
    // Read superblock
    final superblock = await Superblock.read(reader, filePath: filePath);
    final hdf5Offset = superblock.hdf5StartOffset;

    print('HDF5 offset: $hdf5Offset\n');

    // Manually read the doping dataset
    final dopingAddress = 0x3d0 + hdf5Offset; // 0x5d0
    print('Reading /doping at address 0x${dopingAddress.toRadixString(16)}\n');

    reader.seek(dopingAddress);

    // Read object header
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

    // Read messages
    for (int i = 0; i < totalMessages; i++) {
      print('\n--- Message $i ---');
      final msgType = await reader.readUint16();
      final msgSize = await reader.readUint16();
      final msgFlags = await reader.readUint8();
      await reader.readBytes(3); // reserved

      print('Type: 0x${msgType.toRadixString(16)} ($msgType)');
      print('Size: $msgSize bytes');
      print('Flags: $msgFlags');

      if (msgType == 0x0008) {
        // Data layout
        print('\n🔍 DATA LAYOUT MESSAGE:');
        final msgData = await reader.readBytes(msgSize);
        print(
            'Raw bytes: ${msgData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        final msgReader = ByteReader.fromBytes(Uint8List.fromList(msgData));
        final layoutVersion = await msgReader.readUint8();
        print('Layout version: $layoutVersion');

        if (layoutVersion == 1 || layoutVersion == 2) {
          final layoutClass = await msgReader.readUint8();
          print('Layout class: $layoutClass');

          if (layoutClass == 1) {
            print('  -> CONTIGUOUS layout');
            await msgReader.readBytes(6); // reserved
            final address = await msgReader.readUint64();
            final size = await msgReader.readUint64();
            print('  Address: 0x${address.toRadixString(16)}');
            print('  Size: $size bytes');
          } else if (layoutClass == 3) {
            print('  -> VIRTUAL layout (unexpected!)');
          }
        } else if (layoutVersion == 3) {
          final layoutClass = await msgReader.readUint8();
          print('Layout class: $layoutClass');

          if (layoutClass == 1) {
            print('  -> CONTIGUOUS layout');
            final address = await msgReader.readUint64();
            final size = await msgReader.readUint64();
            print('  Address: 0x${address.toRadixString(16)}');
            print('  Size: $size bytes');
          }
        }
      } else {
        // Skip other messages
        await reader.readBytes(msgSize);
      }

      // Padding
      final padding = (8 - (msgSize % 8)) % 8;
      if (padding > 0) {
        await reader.readBytes(padding);
      }
    }
  } finally {
    await raf.close();
  }
}
