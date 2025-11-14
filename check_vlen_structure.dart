import 'dart:io';
import 'dart:typed_data';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    // Check multiple attributes to see the pattern
    final attributes = [
      {'name': 'units', 'pos': 0x3b0, 'dataPos': 48},
      {'name': 'description', 'pos': 0x578, 'dataPos': 56},
    ];

    for (final attr in attributes) {
      print('\n${attr['name']} attribute:');
      reader.seek(attr['pos'] as int);

      await reader.readUint16(); // type
      final size = await reader.readUint16();
      await reader.readBytes(4); // flags + reserved

      final messageData = await reader.readBytes(size);
      final dataPos = attr['dataPos'] as int;

      print('  Data at position $dataPos:');
      final dataBytes = messageData.sublist(
          dataPos, (dataPos + 16).clamp(0, messageData.length));
      final hex =
          dataBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      print('    Hex: $hex');

      final dr = ByteReader.fromBytes(Uint8List.fromList(dataBytes));
      final length = await dr.readUint32();
      final next8 = await dr.readUint64();

      print('    Length: $length');
      print('    Next 8 bytes as uint64: 0x${next8.toRadixString(16)}');
      print(
          '    Next 8 bytes as 2x uint32: 0x${(next8 & 0xFFFFFFFF).toRadixString(16)}, 0x${(next8 >> 32).toRadixString(16)}');
    }
  } catch (e, stackTrace) {
    print('Error: $e');
  } finally {
    await raf.close();
  }
}
