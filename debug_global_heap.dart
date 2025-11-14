import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Debug global heap contents
void main() async {
  print('=== Debugging Global Heap Contents ===\n');

  final raf = await File('test_vlen.h5').open();
  final reader = ByteReader(raf);

  // Read the global heap at address 0x850
  final heap = await GlobalHeap.read(reader, 0x850);

  print('Heap address: 0x${heap.address.toRadixString(16)}');
  print('Heap version: ${heap.version}');
  print('Collection size: ${heap.collectionSize}');
  print('Number of objects: ${heap.objects.length}\n');

  // Print all objects
  for (final entry in heap.objects.entries) {
    final index = entry.key;
    final obj = entry.value;
    print('Object $index:');
    print('  Size: ${obj.size} bytes');
    print('  Data (as string): ${String.fromCharCodes(obj.data)}');
    print(
        '  Data (hex): ${obj.data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    print('');
  }

  await raf.close();
}
