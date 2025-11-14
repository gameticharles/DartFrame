import 'dart:io';
import 'dart:typed_data';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

void main() async {
  print('🔬 Debugging RangeError in detail\n');

  final hdf5File = await Hdf5File.open('example/data/hdf5_test.h5');

  try {
    final arraysGroup = await hdf5File.group('/arrays');
    final address = arraysGroup.getChildAddress('1D String');

    print('Address: 0x${address?.toRadixString(16)}');

    if (address != null) {
      final file = File('example/data/hdf5_test.h5');
      final raf = await file.open();
      final reader = ByteReader(raf);

      try {
        reader.seek(address);

        // Read object header manually with detailed logging
        print('\nReading object header version...');
        final version = await reader.readUint8();
        print('Version: $version');

        await reader.readBytes(1); // reserved
        final totalHeaderMessages = await reader.readUint16();
        print('Total messages: $totalHeaderMessages');

        await reader.readUint32(); // objectReferenceCount
        final objectHeaderSize = await reader.readUint32();
        print('Object header size: $objectHeaderSize');

        if (version == 1) {
          await reader.readBytes(4); // reserved/alignment
        }

        final headerEnd = address + 16 + objectHeaderSize;
        print('Header end: 0x${headerEnd.toRadixString(16)}');

        // Read messages
        for (int i = 0;
            i < totalHeaderMessages && reader.position < headerEnd;
            i++) {
          print(
              '\n--- Message $i at position 0x${reader.position.toRadixString(16)} ---');

          final msgType = await reader.readUint16();
          final msgSize = await reader.readUint16();
          final msgFlags = await reader.readUint8();
          await reader.readBytes(3); // reserved

          print(
              'Type: 0x${msgType.toRadixString(16)}, Size: $msgSize, Flags: $msgFlags');

          if (msgType == 0x0008) {
            // Data layout
            print('This is a DATA LAYOUT message');
            print('Message size: $msgSize bytes');
            print('Current position: 0x${reader.position.toRadixString(16)}');

            // Read the message data
            final messageData = await reader.readBytes(msgSize);
            print('Message data length: ${messageData.length}');
            print(
                'Message data (hex): ${messageData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

            // Try to parse it
            final msgReader =
                ByteReader.fromBytes(Uint8List.fromList(messageData));
            final layoutVersion = await msgReader.readUint8();
            print('Layout version: $layoutVersion');

            if (layoutVersion == 1 || layoutVersion == 2) {
              final layoutClass = await msgReader.readUint8();
              print('Layout class: $layoutClass');
              print('Remaining bytes in message: ${msgReader.remainingBytes}');
            }
          } else {
            // Skip other messages
            await reader.readBytes(msgSize);
          }

          // Align to 8-byte boundary
          final padding = (8 - (msgSize % 8)) % 8;
          if (padding > 0) {
            await reader.readBytes(padding);
          }
        }
      } finally {
        await raf.close();
      }
    }
  } finally {
    await hdf5File.close();
  }
}
