import 'dart:io';
import 'dart:typed_data';
import 'package:dartframe/dartframe.dart';

/// Debug vlen integer reading
void main() async {
  print('=== Debugging VLen Integer Reading ===\n');

  final file = await Hdf5File.open('test_vlen.h5');
  final dataset = await file.dataset('/vlen_ints');

  final raf = await File('test_vlen.h5').open();
  final reader = ByteReader(raf);

  // Get dataset address
  if (dataset.layout is ContiguousLayout) {
    final layout = dataset.layout as ContiguousLayout;
    reader.seek(layout.address);

    print('Reading vlen int references:');
    for (int i = 0; i < 3; i++) {
      final bytes = await reader.readBytes(16);
      final buffer = ByteData.view(Uint8List.fromList(bytes).buffer);

      final length = buffer.getUint32(0, Endian.little);
      final addr = buffer.getUint32(4, Endian.little);
      final index = buffer.getUint32(12, Endian.little);

      print(
          '  Element $i: length=$length, heap=0x${addr.toRadixString(16)}, index=$index');
    }
  }

  // Read the heap
  final heap = await GlobalHeap.read(reader, 0x850);
  print('\nHeap integer objects:');
  print('  Object 15 (${heap.objects[15]!.size} bytes): ${heap.readData(15)}');
  print('  Object 16 (${heap.objects[16]!.size} bytes): ${heap.readData(16)}');
  print('  Object 17 (${heap.objects[17]!.size} bytes): ${heap.readData(17)}');

  await raf.close();
  await file.close();
}
