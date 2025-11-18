import 'package:dartframe/src/io/hdf5/attribute.dart';
import 'package:dartframe/src/io/hdf5/global_heap.dart';

/// Demonstration of Hdf5Attribute with GlobalHeap integration
///
/// This example shows how to:
/// 1. Create attributes with variable-length strings
/// 2. Write attributes using global heap for large strings
/// 3. Compare with and without global heap
void main() {
  print('=== Attribute with Global Heap Demo ===\n');

  // Create a simple string attribute
  final shortAttr = Hdf5Attribute.scalar('units', 'meters');
  print('Short string attribute:');
  print('  Name: ${shortAttr.name}');
  print('  Value: ${shortAttr.value}');

  // Write without global heap (fixed-length)
  final shortBytes = shortAttr.write();
  print('  Size without global heap: ${shortBytes.length} bytes');
  print('');

  // Create a long string attribute
  final longString = 'This is a very long description that would be '
      'inefficient to store as a fixed-length string. It contains '
      'detailed information about the dataset, including methodology, '
      'data sources, and processing steps. Using variable-length strings '
      'with global heap storage is much more efficient for such cases.';

  final longAttr = Hdf5Attribute.scalar('description', longString);
  print('Long string attribute:');
  print('  Name: ${longAttr.name}');
  print('  Value length: ${longString.length} characters');

  // Write without global heap (fixed-length)
  final longBytesNoHeap = longAttr.write();
  print('  Size without global heap: ${longBytesNoHeap.length} bytes');

  // Write with global heap (variable-length)
  final heapWriter = GlobalHeapWriter();
  final heapAddress = 8192;
  final longBytesWithHeap = longAttr.write(
    globalHeapWriter: heapWriter,
    globalHeapAddress: heapAddress,
  );
  print('  Size with global heap: ${longBytesWithHeap.length} bytes');
  print(
      '  Space saved in attribute: ${longBytesNoHeap.length - longBytesWithHeap.length} bytes');
  print('');

  // Show global heap statistics
  print('Global heap statistics:');
  print('  Objects allocated: ${heapWriter.objectCount}');
  print('  Total data size: ${heapWriter.totalDataSize} bytes');
  print('  Collection size: ${heapWriter.calculateCollectionSize()} bytes');
  print('');

  // Write the heap collection
  final collectionBytes = heapWriter.writeCollection(heapAddress);
  print('Global heap collection:');
  print('  Address: 0x${heapAddress.toRadixString(16)}');
  print('  Size: ${collectionBytes.length} bytes');
  print('');

  // Total storage comparison
  final totalWithoutHeap = longBytesNoHeap.length;
  final totalWithHeap = longBytesWithHeap.length + collectionBytes.length;
  print('Total storage comparison:');
  print('  Without global heap: $totalWithoutHeap bytes');
  print('  With global heap: $totalWithHeap bytes');
  print(
      '    (${longBytesWithHeap.length} attribute + ${collectionBytes.length} heap)');
  print('  Difference: ${totalWithoutHeap - totalWithHeap} bytes');
  print('');

  // Multiple attributes sharing the same heap
  print('Multiple attributes sharing global heap:');
  final heapWriter2 = GlobalHeapWriter();
  final attrs = [
    Hdf5Attribute.scalar('title', 'Experimental Data Set'),
    Hdf5Attribute.scalar('author', 'Dr. Jane Smith'),
    Hdf5Attribute.scalar('institution', 'University of Science'),
    Hdf5Attribute.scalar('notes', longString),
  ];

  int totalAttrSize = 0;
  for (final attr in attrs) {
    final attrBytes = attr.write(
      globalHeapWriter: heapWriter2,
      globalHeapAddress: heapAddress,
    );
    totalAttrSize += attrBytes.length;
    print('  ${attr.name}: ${attrBytes.length} bytes');
  }

  final sharedHeapSize = heapWriter2.calculateCollectionSize();
  print('  Shared heap collection: $sharedHeapSize bytes');
  print('  Total: ${totalAttrSize + sharedHeapSize} bytes');
  print('  Objects in heap: ${heapWriter2.objectCount}');
  print('');

  print('=== Demo Complete ===');
}
