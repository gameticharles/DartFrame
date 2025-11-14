import 'dart:io';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    reader.seek(0xb20);

    print('Heap header bytes:');
    for (int i = 0; i < 40; i += 8) {
      reader.seek(0xb20 + i);
      final bytes = await reader.readBytes(8);
      final hex =
          bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      final ascii = bytes
          .map((b) => (b >= 32 && b < 127) ? String.fromCharCode(b) : '.')
          .join('');
      print('  0x${(0xb20 + i).toRadixString(16)}: $hex  $ascii');
    }

    print('\nHeap header structure:');
    reader.seek(0xb20);
    final sig = await reader.readBytes(4);
    print('Signature: ${String.fromCharCodes(sig)}');
    final version = await reader.readUint8();
    print('Version: $version');
    await reader.readBytes(3);
    final dataSize = await reader.readUint64();
    print('Data size: $dataSize');
    final freeList = await reader.readUint64();
    print('Free list: $freeList');
    final dataAddr = await reader.readUint64();
    print('Data address: $dataAddr');

    print(
        '\nCurrent position after header: 0x${reader.position.toRadixString(16)}');
    print('Expected data start: 0xb38');
  } catch (e) {
    print('Error: $e');
  } finally {
    await raf.close();
  }
}
