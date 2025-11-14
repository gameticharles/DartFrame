import 'dart:io';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    // Read from 0xb38 (where we found the data)
    reader.seek(0xb38);

    print('Heap data entries:');
    for (int i = 0; i < 5; i++) {
      final pos = reader.position;
      final field1 = await reader.readUint64();
      final field2 = await reader.readUint64();

      print('\nEntry at 0x${pos.toRadixString(16)}:');
      print('  Field 1: $field1 (0x${field1.toRadixString(16)})');
      print('  Field 2: $field2 (0x${field2.toRadixString(16)})');

      // Try to read as string if field1 looks like a length
      if (field1 > 0 && field1 < 1000) {
        final stringBytes = await reader.readBytes(field1.clamp(0, 100));
        final str = String.fromCharCodes(
            stringBytes.where((b) => b != 0 && b >= 32 && b < 127));
        print('  As string: "$str"');

        // Align to 8 bytes
        final padding = (8 - (field1 % 8)) % 8;
        if (padding > 0) {
          await reader.readBytes(padding);
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await raf.close();
  }
}
