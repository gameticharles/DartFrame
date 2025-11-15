import 'dart:typed_data';
import 'package:dartframe/dartframe.dart';

void main() async {
  final fileIO = FileIO();
  final filePath = 'example/data/test_attributes.h5';
  final raf = await fileIO.openRandomAccess(filePath);
  final reader = ByteReader(raf);

  try {
    // Go to "units" attribute in main object header
    // From earlier debug, it's at 0x3b0
    reader.seek(0x3b0);

    await reader.readUint16(); // type
    final size = await reader.readUint16();
    await reader.readBytes(4); // flags + reserved

    final messageData = await reader.readBytes(size);
    print('Units attribute message ($size bytes):');
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

    // Parse to find the data section
    final mr = ByteReader.fromBytes(Uint8List.fromList(messageData));
    await mr.readUint8(); // version
    await mr.readUint8(); // reserved
    final nameSize = await mr.readUint16();
    final datatypeSize = await mr.readUint16();
    final dataspaceSize = await mr.readUint16();

    await mr.readBytes(nameSize); // name

    // Padding
    int bytesRead = 8 + nameSize;
    int padding = (8 - (bytesRead % 8)) % 8;
    if (padding > 0) {
      await mr.readBytes(padding);
    }

    await mr.readBytes(datatypeSize); // datatype

    // Padding
    bytesRead += datatypeSize;
    padding = (8 - (bytesRead % 8)) % 8;
    if (padding > 0) {
      await mr.readBytes(padding);
    }

    await mr.readBytes(dataspaceSize); // dataspace

    // Padding
    bytesRead += dataspaceSize;
    padding = (8 - (bytesRead % 8)) % 8;
    if (padding > 0) {
      await mr.readBytes(padding);
    }

    print('\nAttribute data starts at position ${mr.position}:');
    final remaining = messageData.sublist(mr.position);
    print(
        '  ${remaining.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    print(
        '  ASCII: ${remaining.map((b) => (b >= 32 && b < 127) ? String.fromCharCode(b) : '.').join('')}');

    // Try to interpret as vlen structure
    final vlenReader = ByteReader.fromBytes(Uint8List.fromList(remaining));
    final length = await vlenReader.readUint32();
    print('\nVlen length field: $length (0x${length.toRadixString(16)})');

    if (length < 100) {
      final stringBytes = await vlenReader.readBytes(length);
      final str = String.fromCharCodes(stringBytes.where((b) => b != 0));
      print('String data: "$str"');
    }
  } catch (e, stackTrace) {
    print('Error: $e');
  } finally {
    await raf.close();
  }
}
