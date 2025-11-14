import 'dart:io';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    // Check units attribute
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

    // The vlen structure starts at position 48
    // After 12 bytes of vlen structure (4 length + 8 heap address),
    // check if the string is there
    print('\nBytes after vlen structure (position 60):');
    final afterVlen = messageData.sublist(60);
    final str = String.fromCharCodes(
        afterVlen.where((b) => b >= 32 && b < 127).take(20));
    print('  ASCII: $str');
  } catch (e) {
    print('Error: $e');
  } finally {
    await raf.close();
  }
}
