import 'dart:io';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    reader.seek(0xb38);

    print('Heap entries with 3-field structure:');
    for (int i = 0; i < 5; i++) {
      final pos = reader.position;
      final field1 = await reader.readUint64();
      final field2 = await reader.readUint64();
      final field3 = await reader.readUint64();

      print('\nEntry $i at 0x${pos.toRadixString(16)}:');
      print('  Field 1: $field1');
      print('  Field 2: $field2');
      print('  Field 3: $field3');

      // Try to interpret field1 as length and field2 as data
      if (field1 > 0 && field1 < 100) {
        reader.seek(pos + 8);
        final stringBytes = await reader.readBytes(field1.clamp(0, 50));
        final str = String.fromCharCodes(
            stringBytes.where((b) => b != 0 && b >= 32 && b < 127));
        print('  As string (field1=length): "$str"');
        reader.seek(pos + 24); // Move to next entry
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await raf.close();
  }
}
