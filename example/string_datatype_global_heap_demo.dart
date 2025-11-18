import 'package:dartframe/src/io/hdf5/datatype_writer.dart';
import 'package:dartframe/src/io/hdf5/global_heap.dart';

/// Demonstration of StringDatatypeWriter with GlobalHeap integration
///
/// This example shows how to:
/// 1. Create variable-length string datatype writers
/// 2. Encode strings for global heap storage
/// 3. Integrate with GlobalHeapWriter
void main() {
  print('=== String Datatype Writer with Global Heap Demo ===\n');

  // Create a variable-length string writer
  final vlenStringWriter = StringDatatypeWriter.variableLength();
  print('Created variable-length string writer:');
  print(
      '  Size: ${vlenStringWriter.getSize()} (0xFFFFFFFF for variable-length)');
  print('  Is variable-length: ${vlenStringWriter.isVariableLength}');
  print('');

  // Create a global heap writer
  final heapWriter = GlobalHeapWriter();
  print('Created GlobalHeapWriter');
  print('');

  // Encode some variable-length strings
  final strings = [
    'Short string',
    'A much longer variable-length string that would be inefficient as fixed-length',
    'UTF-8 string: 你好世界 🌍',
  ];

  print('Encoding and allocating strings in global heap:');
  final heapIds = <int>[];
  for (final str in strings) {
    // Encode the string for global heap storage
    final encodedData = vlenStringWriter.encodeForGlobalHeap(str);
    print('  String: "$str"');
    print('    Encoded size: ${encodedData.length} bytes');

    // Allocate in global heap
    final heapId = heapWriter.allocate(encodedData);
    heapIds.add(heapId);
    print('    Heap ID: $heapId');
    print('');
  }

  // Write the datatype message
  final datatypeMessage = vlenStringWriter.writeMessage();
  print('Variable-length string datatype message:');
  print('  Size: ${datatypeMessage.length} bytes');
  print(
      '  Hex: ${datatypeMessage.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  print('');

  // Write the heap collection
  final heapAddress = 4096;
  final collectionBytes = heapWriter.writeCollection(heapAddress);
  print('Global heap collection:');
  print('  Address: 0x${heapAddress.toRadixString(16)}');
  print('  Size: ${collectionBytes.length} bytes');
  print('  Objects: ${heapWriter.objectCount}');
  print('');

  // Create references for each string
  print('Variable-length string references (for dataset/attribute):');
  for (int i = 0; i < heapIds.length; i++) {
    final reference = heapWriter.createReference(heapIds[i], heapAddress);
    print('  String $i (ID ${heapIds[i]}):');
    print(
        '    Reference: ${reference.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    print(
        '    Length: ${reference[0] | (reference[1] << 8) | (reference[2] << 16) | (reference[3] << 24)} bytes');
  }
  print('');

  // Compare with fixed-length string
  print('Comparison with fixed-length string:');
  final fixedStringWriter = StringDatatypeWriter.fixedLength(length: 100);
  final fixedEncoded = fixedStringWriter.encodeString(strings[1]);
  print('  Variable-length: ${strings[1].length} bytes (in heap)');
  print('  Fixed-length (100): ${fixedEncoded.length} bytes (in dataset)');
  print(
      '  Space saved: ${fixedEncoded.length - strings[1].length} bytes per string');
  print('');

  print('=== Demo Complete ===');
}
