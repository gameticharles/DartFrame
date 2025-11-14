import 'dart:io';
import 'dart:typed_data';
import 'package:dartframe/dartframe.dart';

/// Debug vlen reading in detail
void main() async {
  print('=== Detailed VLen Debugging ===\n');

  final raf = await File('test_vlen.h5').open();
  final reader = ByteReader(raf);

  // Read the global heap
  final heap = await GlobalHeap.read(reader, 0x850);

  print('Expected strings: Hello, World, Variable, Length, Strings!');
  print('Heap objects:');
  print('  Object 1: ${String.fromCharCodes(heap.readData(1))}');
  print('  Object 2: ${String.fromCharCodes(heap.readData(2))}');
  print('  Object 3: ${String.fromCharCodes(heap.readData(3))}');
  print('  Object 4: ${String.fromCharCodes(heap.readData(4))}');
  print('  Object 5: ${String.fromCharCodes(heap.readData(5))}');
  print('');

  // Read vlen references from dataset
  reader.seek(0x800);
  print('VLen references in dataset:');
  for (int i = 0; i < 5; i++) {
    final bytes = await reader.readBytes(16);
    print(
        '  Element $i bytes (hex): ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    // Parse manually
    final buffer = ByteData.view(Uint8List.fromList(bytes).buffer);
    final length = buffer.getUint32(0, Endian.little);
    final addr1 = buffer.getUint32(4, Endian.little);
    final addr2 = buffer.getUint32(8, Endian.little);
    final index = buffer.getUint32(12, Endian.little);

    print(
        '    length=$length, addr1=0x${addr1.toRadixString(16)}, addr2=0x${addr2.toRadixString(16)}, index=$index');
    print('    String: ${String.fromCharCodes(heap.readData(index))}');
  }

  await raf.close();
}
