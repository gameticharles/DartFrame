import 'dart:io';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    // Read the local heap at 0x0b20
    reader.seek(0x0b20);

    print('Local heap structure:');
    final signature = await reader.readBytes(4);
    print('Signature: ${String.fromCharCodes(signature)}');

    final version = await reader.readUint8();
    await reader.readBytes(3); // reserved
    print('Version: $version');

    final dataSegmentSize = await reader.readUint64();
    print('Data segment size: $dataSegmentSize');

    final offsetToHeadOfFreeList = await reader.readUint64();
    print('Offset to head of free list: $offsetToHeadOfFreeList');

    final addressOfDataSegment = await reader.readUint64();
    print(
        'Address of data segment: 0x${addressOfDataSegment.toRadixString(16)}');

    // Read data segment
    print('\nData segment at 0x${addressOfDataSegment.toRadixString(16)}:');
    reader.seek(addressOfDataSegment);

    final dataBytes = await reader.readBytes(dataSegmentSize.clamp(0, 256));
    for (int i = 0; i < dataBytes.length && i < 128; i += 16) {
      final chunk = dataBytes.sublist(i, (i + 16).clamp(0, dataBytes.length));
      final hex =
          chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      final ascii = chunk
          .map((b) => (b >= 32 && b < 127) ? String.fromCharCode(b) : '.')
          .join('');
      print('  ${i.toRadixString(16).padLeft(4, '0')}: $hex  $ascii');
    }
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack: $stackTrace');
  } finally {
    await raf.close();
  }
}
