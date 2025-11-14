import 'dart:io';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    // Jump to the dataset object header
    reader.seek(0x320);

    print('Reading object header at 0x320');
    final version = await reader.readUint8();
    print('Version: $version');

    await reader.readBytes(1); // reserved
    final totalHeaderMessages = await reader.readUint16();
    print('Total messages: $totalHeaderMessages');

    final objectReferenceCount = await reader.readUint32();
    print('Reference count: $objectReferenceCount');

    final objectHeaderSize = await reader.readUint32();
    print('Header size: $objectHeaderSize');
    print(
        'Expected end position: 0x${(0x320 + 16 + objectHeaderSize).toRadixString(16)}');

    if (version == 1) {
      await reader.readBytes(4); // reserved/alignment
    }

    print('\nReading messages:');
    for (int i = 0; i < totalHeaderMessages; i++) {
      final msgStart = reader.position;
      print('\nMessage $i at position 0x${msgStart.toRadixString(16)}:');

      final type = await reader.readUint16();
      final size = await reader.readUint16();
      final flags = await reader.readUint8();
      await reader.readBytes(3); // reserved

      print('  Type: 0x${type.toRadixString(16).padLeft(4, '0')}');
      print('  Size: $size');
      print('  Flags: 0x${flags.toRadixString(16)}');

      // Skip message data
      if (size > 0) {
        await reader.readBytes(size);
      }

      // Calculate and skip padding
      final padding = (8 - (size % 8)) % 8;
      if (padding > 0) {
        print('  Padding: $padding bytes');
        await reader.readBytes(padding);
      }

      final msgEnd = reader.position;
      print('  Message consumed ${msgEnd - msgStart} bytes');
    }

    print('\nFinal position: 0x${reader.position.toRadixString(16)}');
  } catch (e, stackTrace) {
    print('Error at position 0x${reader.position.toRadixString(16)}: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await raf.close();
  }
}
