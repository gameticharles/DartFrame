import 'dart:convert';
import 'package:dartframe/src/io/hdf5/global_heap.dart';

/// Demonstration of GlobalHeapWriter functionality
///
/// This example shows how to:
/// 1. Create a GlobalHeapWriter
/// 2. Allocate variable-length data in the heap
/// 3. Write the heap collection
/// 4. Create references to heap objects
void main() {
  print('=== Global Heap Writer Demo ===\n');

  // Create a new global heap writer
  final heapWriter = GlobalHeapWriter();
  print('Created GlobalHeapWriter');

  // Allocate some variable-length strings in the heap
  final string1 = 'Hello, HDF5!';
  final string2 = 'This is a variable-length string';
  final string3 = 'Another string with UTF-8: 你好世界';

  final id1 = heapWriter.allocate(utf8.encode(string1));
  final id2 = heapWriter.allocate(utf8.encode(string2));
  final id3 = heapWriter.allocate(utf8.encode(string3));

  print('Allocated 3 strings in heap:');
  print('  ID $id1: "$string1"');
  print('  ID $id2: "$string2"');
  print('  ID $id3: "$string3"');
  print('');

  // Show heap statistics
  print('Heap statistics:');
  print('  Object count: ${heapWriter.objectCount}');
  print('  Total data size: ${heapWriter.totalDataSize} bytes');
  print('  Collection size: ${heapWriter.calculateCollectionSize()} bytes');
  print('');

  // Write the heap collection at a hypothetical address
  final heapAddress = 2048;
  final collectionBytes = heapWriter.writeCollection(heapAddress);
  print('Wrote heap collection:');
  print('  Address: 0x${heapAddress.toRadixString(16)}');
  print('  Size: ${collectionBytes.length} bytes');
  print('');

  // Create references to the heap objects
  print('Creating references to heap objects:');
  for (final id in [id1, id2, id3]) {
    final reference = heapWriter.createReference(id, heapAddress);
    print('  Object $id: ${reference.length} bytes reference');
    print(
        '    Hex: ${reference.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  }
  print('');

  // Demonstrate the heap collection structure
  print('Heap collection structure:');
  print('  Header (16 bytes):');
  print('    - Signature: "GCOL" (4 bytes)');
  print('    - Version: 1 (1 byte)');
  print('    - Reserved: 0 (3 bytes)');
  print(
      '    - Collection size: ${heapWriter.calculateCollectionSize()} (8 bytes)');
  print('  Objects (${heapWriter.objectCount} objects):');
  print('    - Each object has 16-byte header + data (aligned to 8 bytes)');
  print('  End marker (16 bytes):');
  print('    - Index: 0, Size: 0');
  print('');

  print('=== Demo Complete ===');
}
