import 'dart:io';
import 'dart:typed_data';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    // Go to "description" attribute at 0x578
    reader.seek(0x578);

    print('Reading "description" attribute message:');

    final type = await reader.readUint16();
    final size = await reader.readUint16();
    await reader.readUint8(); // flags
    await reader.readBytes(3); // reserved

    print('Message type: 0x${type.toRadixString(16)}');
    print('Message size: $size');

    final messageData = await reader.readBytes(size);
    print('\nFull message data ($size bytes):');
    for (int i = 0; i < messageData.length; i += 16) {
      final chunk =
          messageData.sublist(i, (i + 16).clamp(0, messageData.length));
      final hex =
          chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      final ascii = chunk
          .map((b) => (b >= 32 && b < 127) ? String.fromCharCode(b) : '.')
          .join('');
      print('  ${i.toRadixString(16).padLeft(4, '0')}: $hex  $ascii');
    }

    // Parse attribute header
    final mr = ByteReader.fromBytes(Uint8List.fromList(messageData));
    final version = await mr.readUint8();
    await mr.readUint8(); // reserved
    final nameSize = await mr.readUint16();
    final datatypeSize = await mr.readUint16();
    final dataspaceSize = await mr.readUint16();

    print('\nAttribute header:');
    print('  Version: $version');
    print('  Name size: $nameSize');
    print('  Datatype size: $datatypeSize');
    print('  Dataspace size: $dataspaceSize');
    print('  Total header: 7 bytes');

    // Read name
    final nameBytes = await mr.readBytes(nameSize);
    final name = String.fromCharCodes(nameBytes.where((b) => b != 0));
    print('  Name: "$name"');
    print('  Position after name: ${mr.position}');

    // Calculate padding
    int bytesRead = 7 + nameSize;
    int padding = (8 - (bytesRead % 8)) % 8;
    print('  Padding after name: $padding bytes');

    if (padding > 0) {
      final paddingBytes = await mr.readBytes(padding);
      print(
          '  Padding bytes: ${paddingBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    }

    print('  Position before datatype: ${mr.position}');

    // Read datatype
    print('\nDatatype ($datatypeSize bytes):');
    final datatypeStart = mr.position;
    final datatypeBytes = await mr.readBytes(datatypeSize);
    for (int i = 0; i < datatypeBytes.length; i += 16) {
      final chunk =
          datatypeBytes.sublist(i, (i + 16).clamp(0, datatypeBytes.length));
      final hex =
          chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      print('  ${(datatypeStart + i).toRadixString(16).padLeft(4, '0')}: $hex');
    }

    final classAndVersion = datatypeBytes[0];
    final classId = classAndVersion & 0x0F;
    final dtVersion = (classAndVersion >> 4) & 0x0F;
    print('  Class: $classId, Version: $dtVersion');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await raf.close();
  }
}
