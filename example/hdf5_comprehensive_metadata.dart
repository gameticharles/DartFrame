import 'package:dartframe/dartframe.dart';

/// Example demonstrating comprehensive HDF5 metadata inspection
///
/// This example shows how to access and display detailed HDF5 metadata including:
///
/// **File-Level Information:**
/// - Total datasets, groups, and nesting depth
/// - Compression and chunking statistics
/// - Dataset type distribution
///
/// **Datatype Information (all newly added fields):**
/// - `dataclass` - The HDF5 datatype class (integer, float, string, compound, etc.)
/// - `typeName` - Human-readable type name
/// - `size` - Size in bytes
/// - `endian` - Byte order (little/big endian)
/// - `filePosition` - Position in file where datatype was read (for debugging)
///
/// **String-Specific Fields:**
/// - `stringInfo.paddingType` - How strings are padded (null-terminate, null-pad, space-pad)
/// - `stringInfo.characterSet` - Character encoding (ASCII, UTF-8)
/// - `stringInfo.isVariableLength` - Whether string length is variable
///
/// **Compound Type Fields:**
/// - `compoundInfo.fields` - List of all fields in the compound type
/// - For each field: name, offset, and nested datatype
///
/// **Array Type Fields:**
/// - `arrayInfo.dimensions` - Array dimensions
/// - `arrayInfo.totalElements` - Total number of elements
/// - `baseType` - The element datatype
///
/// **Enum Type Fields:**
/// - `enumInfo.members` - List of enum members
/// - For each member: name and integer value
///
/// **Reference Type Fields:**
/// - `referenceInfo.type` - Reference type (object or region)
///
/// **Opaque Type Fields:**
/// - `tag` - Opaque type identifier string
///
/// **Storage Information:**
/// - Layout type (contiguous, chunked, compact)
/// - Chunk dimensions and sizes
/// - Compression type and settings
///
/// **Attributes:**
/// - All attributes with their names, types, and values
///
/// This demonstrates all the internal HDF5 structure fields that were recently
/// added to FractalHeap, BTreeV2, and Hdf5Datatype classes.
Future<void> main() async {
  final file = await Hdf5File.open('example/data/hdf5_test.h5');

  try {
    print('=== HDF5 Comprehensive Metadata Inspection ===\n');

    // 1. File Overview
    print('File Overview:');
    print('=' * 60);
    final stats = await file.getSummaryStats();
    print('Total Datasets: ${stats['totalDatasets']}');
    final totalGroups = stats['totalGroups'] as int;
    print(
        'Total Groups: $totalGroups${totalGroups == 0 ? ' (root only)' : ''}');
    print('Max Depth: ${stats['maxDepth']}');
    print('Compressed: ${stats['compressedDatasets']}');
    print('Chunked: ${stats['chunkedDatasets']}');

    print('\nDatasets by Type:');
    final datasetsByType = stats['datasetsByType'] as Map<String, int>;
    for (final entry in datasetsByType.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
    print('');

    // 2. Detailed Dataset Inspection
    print('\nDetailed Dataset Information:');
    print('=' * 60);

    final structure = await file.listRecursive();
    for (final entry in structure.entries) {
      if (entry.value['type'] == 'dataset') {
        final path = entry.key;
        print('\n📊 Dataset: $path');
        print('   ${'─' * 55}');

        try {
          final dataset = await file.dataset(path);
          final datatype = dataset.datatype;

          // Basic info
          final info = dataset.inspect();
          print('   Shape: ${dataset.dataspace.dimensions}');
          print('   Total Elements: ${dataset.dataspace.totalElements}');
          print('   Storage: ${info['storage']}');

          // Datatype details
          print('\n   Datatype Information:');
          print('   ├─ Class: ${datatype.dataclass}');
          print('   ├─ Type Name: ${datatype.typeName}');
          print('   ├─ Size: ${datatype.size} bytes');
          print('   ├─ Endianness: ${datatype.endian}');
          if (datatype.filePosition != null) {
            print(
                '   └─ File Position: 0x${datatype.filePosition!.toRadixString(16)}');
          }

          // String-specific info
          if (datatype.isString && datatype.stringInfo != null) {
            final strInfo = datatype.stringInfo!;
            print('\n   String Properties:');
            print('   ├─ Padding: ${strInfo.paddingType}');
            print('   ├─ Character Set: ${strInfo.characterSet}');
            print('   └─ Variable Length: ${strInfo.isVariableLength}');
          }

          // Compound-specific info
          if (datatype.isCompound && datatype.compoundInfo != null) {
            final compInfo = datatype.compoundInfo!;
            print(
                '\n   Compound Structure (${compInfo.fields.length} fields):');
            for (var i = 0; i < compInfo.fields.length; i++) {
              final field = compInfo.fields[i];
              final prefix = i == compInfo.fields.length - 1 ? '└─' : '├─';
              print('   $prefix ${field.name}: ${field.datatype.typeName}');
              print(
                  '   ${i == compInfo.fields.length - 1 ? '  ' : '│ '} (offset: ${field.offset}, size: ${field.datatype.size})');
            }
          }

          // Array-specific info
          if (datatype.isArray && datatype.arrayInfo != null) {
            final arrInfo = datatype.arrayInfo!;
            print('\n   Array Properties:');
            print('   ├─ Dimensions: ${arrInfo.dimensions}');
            print('   ├─ Total Elements: ${arrInfo.totalElements}');
            print('   └─ Base Type: ${datatype.baseType?.typeName}');
          }

          // Enum-specific info
          if (datatype.isEnum && datatype.enumInfo != null) {
            final enumInfo = datatype.enumInfo!;
            print('\n   Enum Values (${enumInfo.members.length} members):');
            for (var i = 0; i < enumInfo.members.length; i++) {
              final member = enumInfo.members[i];
              final prefix = i == enumInfo.members.length - 1 ? '└─' : '├─';
              print('   $prefix ${member.name} = ${member.value}');
            }
          }

          // Reference-specific info
          if (datatype.isReference && datatype.referenceInfo != null) {
            final refInfo = datatype.referenceInfo!;
            print('\n   Reference Type: ${refInfo.type}');
          }

          // Opaque-specific info
          if (datatype.isOpaque) {
            print('\n   Opaque Data');
            if (datatype.tag != null) {
              print('   └─ Tag: ${datatype.tag}');
            }
          }

          // Storage details
          if (info.containsKey('chunkDimensions')) {
            final chunkDims = info['chunkDimensions'] as List<int>;
            print('\n   Chunking:');
            print('   ├─ Chunk Dimensions: $chunkDims');
            final chunkSize =
                chunkDims.fold<int>(1, (a, b) => a * b) * datatype.size;
            print('   └─ Chunk Size: ${_formatBytes(chunkSize)}');
          }

          if (info.containsKey('compression')) {
            print('\n   Compression:');
            print('   └─ Type: ${info['compression']}');
          }

          // Attributes
          if (dataset.attributes.isNotEmpty) {
            print('\n   Attributes (${dataset.attributes.length}):');
            for (var i = 0; i < dataset.attributes.length; i++) {
              final attr = dataset.attributes[i];
              final prefix = i == dataset.attributes.length - 1 ? '└─' : '├─';
              print('   $prefix ${attr.name}: ${attr.datatype.typeName}');
              print(
                  '   ${i == dataset.attributes.length - 1 ? '  ' : '│ '} Value: ${attr.value}');
            }
          }
        } catch (e) {
          print('   ⚠️  Error: $e');
        }
      }
    }

    // 3. Group Information
    print('\n\nGroup Information:');
    print('=' * 60);

    final rootAttrs = file.root.attributes;
    print('\n📁 Root Group (/)');
    print('   Children: ${file.root.children.length}');
    if (file.root.children.isNotEmpty) {
      print('   ├─ ${file.root.children.join('\n   ├─ ')}');
    }

    if (rootAttrs.isNotEmpty) {
      print('\n   Attributes:');
      for (var i = 0; i < rootAttrs.length; i++) {
        final attr = rootAttrs[i];
        final prefix = i == rootAttrs.length - 1 ? '└─' : '├─';
        print('   $prefix ${attr.name}: ${attr.value}');
      }
    }

    // 3.5 Internal Structures (FractalHeap, BTreeV2)
    print('\n\nInternal HDF5 Structures (Root Group):');
    print('=' * 60);

    print('\n⚙️  Groups use internal structures for link storage:');
    print('   • FractalHeap - Stores variable-length link data (HDF5 1.8+)');
    print('   • BTreeV2 - Indexes links by name for fast lookup (HDF5 1.8+)');
    print('   • SymbolTable - Used in older HDF5 files (pre-1.8)');
    print('\n   To inspect these structures in detail, see:');
    print('   example/hdf5_internal_structures_debug.dart');

    // 4. Summary
    print('\n\nSummary:');
    print('=' * 60);
    print('✓ File contains ${stats['totalDatasets']} datasets');
    if (totalGroups == 0) {
      print('✓ All datasets are in the root group (no nested groups)');
    } else {
      print('✓ Organized in ${totalGroups + 1} groups (including root)');
    }
    print('✓ Maximum nesting depth: ${stats['maxDepth']}');

    final hasCompression = stats['compressedDatasets'] as int > 0;
    final hasChunking = stats['chunkedDatasets'] as int > 0;

    if (hasCompression) {
      print('✓ Uses compression for efficient storage');
    }
    if (hasChunking) {
      print('✓ Uses chunking for optimized access');
    }

    print('\n=== Inspection Complete ===');
  } finally {
    await file.close();
  }
}

/// Helper function to format bytes in human-readable format
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Additional Notes on Internal HDF5 Structures:
///
/// **FractalHeap Fields** (used for variable-length data storage):
/// - idWrapped, directBlocksChecksummed - Configuration flags
/// - maxSizeOfManagedObjects - Size limit for managed objects
/// - numManagedObjectsInHeap, numHugeObjectsInHeap, numTinyObjectsInHeap - Object counts
/// - nextHugeObjectId - Next ID for huge objects
/// - sizeOfHugeObjectsInHeap, sizeOfTinyObjectsInHeap - Size tracking
/// - amountOfFreeSpaceInManagedBlocks - Free space available
/// - amountOfManagedSpaceInHeap - Total managed space
/// - amountOfAllocatedManagedSpaceInHeap - Allocated space
/// - offsetOfDirectBlockAllocationIterator - Allocation position
/// - btreeAddressOfHugeObjects - B-tree for huge objects
/// - addressOfManagedBlockFreeSpaceManager - Free space manager
///
/// **BTreeV2 Fields** (used for indexing):
/// - splitPercent - Node split threshold percentage
/// - mergePercent - Node merge threshold percentage
/// - totalNumRecords - Total records in entire tree
/// - nodeSize, recordSize - Size information
/// - depth - Tree depth
/// - rootNodeAddress - Root node location
///
/// These fields are primarily useful for:
/// - Debugging HDF5 file structure issues
/// - Understanding storage efficiency
/// - Implementing advanced HDF5 features
/// - Performance analysis and optimization
