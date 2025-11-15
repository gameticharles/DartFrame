import 'package:dartframe/src/io/hdf5/hdf5_file.dart';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/file_helper/file_io.dart';

/// Example demonstrating inspection of internal HDF5 structures
///
/// This example shows how to access FractalHeap and BTreeV2 structures
/// that are used internally by HDF5 for storing group links.
///
/// **FractalHeap** - Used for storing variable-length data (like link names)
/// **BTreeV2** - Used for indexing links by name for fast lookup
///
/// These structures contain all the fields we recently added.
Future<void> main() async {
  // Open an HDF5 file (use one with groups/links for best results)
  final file = await Hdf5File.open('example/data/hdf5_test.h5');

  try {
    print('=== HDF5 Internal Structures Inspection ===\n');

    // We need to access the internal ByteReader
    // This requires accessing private fields, so we'll use reflection or
    // create a helper method

    // For now, let's demonstrate with a direct file access
    final fileIO = FileIO();
    final raf = await fileIO.openRandomAccess('example/data/hdf5_test.h5');
    final reader = ByteReader(raf);

    try {
      // Inspect root group internal structures
      print('Root Group Internal Structures:');
      print('=' * 60);

      final internal = await file.root.inspectInternalStructures(reader);

      if (internal.isEmpty) {
        print(
            'No internal structures found (old-style group or simple structure)');
      }

      // Display LinkInfo
      if (internal.containsKey('linkInfo')) {
        final linkInfo = internal['linkInfo'] as Map<String, dynamic>;
        print('\n📋 Link Info Message:');
        print('   Version: ${linkInfo['version']}');
        print('   Maximum Creation Index: ${linkInfo['maximumCreationIndex']}');
        print('   Fractal Heap Address: ${linkInfo['fractalHeapAddress']}');
        print('   V2 B-Tree Address: ${linkInfo['v2BtreeAddress']}');
      }

      // Display FractalHeap
      if (internal.containsKey('fractalHeap')) {
        final heap = internal['fractalHeap'] as Map<String, dynamic>;
        print('\n🗂️  Fractal Heap Structure:');
        print('   ${'─' * 55}');
        print('   Address: ${heap['address']}');
        print('   Version: ${heap['version']}');

        print('\n   Configuration:');
        print('   ├─ Heap ID Length: ${heap['heapIdLength']} bytes');
        print('   ├─ Max Heap Size: ${heap['maxHeapSize']}');
        print('   ├─ Starting Block Size: ${heap['startingBlockSize']} bytes');
        print(
            '   ├─ Max Direct Block Size: ${heap['maxDirectBlockSize']} bytes');
        print('   ├─ Table Width: ${heap['tableWidth']}');
        print('   ├─ Starting Num Rows: ${heap['startingNumRows']}');
        print('   └─ Current Num Rows: ${heap['currentNumRows']}');

        print('\n   Flags:');
        print('   ├─ ID Wrapped: ${heap['idWrapped']}');
        print(
            '   └─ Direct Blocks Checksummed: ${heap['directBlocksChecksummed']}');

        print('\n   Object Counts:');
        print('   ├─ Managed Objects: ${heap['numManagedObjectsInHeap']}');
        print('   ├─ Huge Objects: ${heap['numHugeObjectsInHeap']}');
        print('   └─ Tiny Objects: ${heap['numTinyObjectsInHeap']}');

        print('\n   Size Tracking:');
        print(
            '   ├─ Max Size of Managed Objects: ${heap['maxSizeOfManagedObjects']} bytes');
        print(
            '   ├─ Size of Huge Objects: ${heap['sizeOfHugeObjectsInHeap']} bytes');
        print(
            '   └─ Size of Tiny Objects: ${heap['sizeOfTinyObjectsInHeap']} bytes');

        print('\n   Space Management:');
        print(
            '   ├─ Free Space in Managed Blocks: ${heap['amountOfFreeSpaceInManagedBlocks']} bytes');
        print(
            '   ├─ Total Managed Space: ${heap['amountOfManagedSpaceInHeap']} bytes');
        print(
            '   └─ Allocated Managed Space: ${heap['amountOfAllocatedManagedSpaceInHeap']} bytes');

        print('\n   Advanced:');
        print('   ├─ Next Huge Object ID: ${heap['nextHugeObjectId']}');
        print(
            '   ├─ Direct Block Allocation Iterator: ${heap['offsetOfDirectBlockAllocationIterator']}');
        print(
            '   ├─ B-Tree for Huge Objects: ${heap['btreeAddressOfHugeObjects']}');
        print(
            '   ├─ Free Space Manager: ${heap['addressOfManagedBlockFreeSpaceManager']}');
        print('   └─ Root Block Address: ${heap['rootBlockAddress']}');
      }

      // Display BTreeV2
      if (internal.containsKey('btreeV2')) {
        final btree = internal['btreeV2'] as Map<String, dynamic>;
        print('\n🌳 B-Tree V2 Structure:');
        print('   ${'─' * 55}');
        print('   Address: ${btree['address']}');
        print('   Version: ${btree['version']}');
        print('   Type: ${btree['type']}');

        print('\n   Structure:');
        print('   ├─ Node Size: ${btree['nodeSize']} bytes');
        print('   ├─ Record Size: ${btree['recordSize']} bytes');
        print('   ├─ Depth: ${btree['depth']}');
        print('   ├─ Root Node Address: ${btree['rootNodeAddress']}');
        print('   └─ Records in Root: ${btree['numRecordsInRoot']}');

        print('\n   Split/Merge Thresholds:');
        print('   ├─ Split Percent: ${btree['splitPercent']}%');
        print('   └─ Merge Percent: ${btree['mergePercent']}%');

        print('\n   Statistics:');
        print('   └─ Total Records: ${btree['totalNumRecords']}');
      }

      // Display SymbolTable (old-style)
      if (internal.containsKey('symbolTable')) {
        final symbolTable = internal['symbolTable'] as Map<String, dynamic>;
        print('\n📊 Symbol Table (Old-Style Group):');
        print('   ${'─' * 55}');
        print('   B-Tree Address: ${symbolTable['btreeAddress']}');
        print('   Local Heap Address: ${symbolTable['localHeapAddress']}');
      }

      // Check for errors
      if (internal.containsKey('fractalHeapError')) {
        print('\n⚠️  Fractal Heap Error: ${internal['fractalHeapError']}');
      }
      if (internal.containsKey('btreeV2Error')) {
        print('\n⚠️  B-Tree V2 Error: ${internal['btreeV2Error']}');
      }

      print('\n\n=== Summary ===');
      print('This file uses:');
      if (internal.containsKey('fractalHeap')) {
        print('✓ FractalHeap for variable-length link storage (HDF5 1.8+)');
        print(
            '  All ${internal['fractalHeap']!['numManagedObjectsInHeap']} managed objects tracked');
      }
      if (internal.containsKey('btreeV2')) {
        print('✓ BTreeV2 for fast link name indexing (HDF5 1.8+)');
        print(
            '  ${internal['btreeV2']!['totalNumRecords']} total records indexed');
      }
      if (internal.containsKey('symbolTable')) {
        print('✓ SymbolTable (old HDF5 format, pre-1.8)');
        print('  Uses B-Tree V1 and local heap for link storage');
      }
      if (internal.isEmpty) {
        print('✓ Simple group structure (no advanced indexing needed)');
      }

      print('\nNote: Most test files use the old SymbolTable format.');
      print(
          'To see FractalHeap and BTreeV2, create a file with HDF5 1.8+ tools.');
    } finally {
      await raf.close();
    }
  } finally {
    await file.close();
  }
}
