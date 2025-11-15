import 'package:dartframe/dartframe.dart';

void main() async {
  print('═' * 80);
  print('🔬 Detailed Inspection: example/data/processdata.h5');
  print('═' * 80);

  final fileIO = FileIO();
  final filePath = 'example/data/processdata.h5';
  final raf = await fileIO.openRandomAccess(filePath);
  final reader = ByteReader(raf);

  try {
    // Read superblock to get offset
    final superblock = await Superblock.read(reader, filePath: filePath);
    final hdf5Offset = superblock.hdf5StartOffset;

    print('\n📋 File Information:');
    print('   HDF5 start offset: $hdf5Offset bytes');
    print('   Superblock version: ${superblock.version}');
    print('   Offset size: ${superblock.offsetSize} bytes\n');

    final hdf5File = await Hdf5File.open(filePath);

    try {
      final rootChildren = hdf5File.list('/');
      print('📁 Root contains ${rootChildren.length} objects:');
      print('   ${rootChildren.join(", ")}\n');

      final rootGroup = await hdf5File.group('/');

      for (final child in rootChildren) {
        print('─' * 80);
        print('🔍 Object: /$child');
        print('─' * 80);

        final rawAddress = rootGroup.getChildAddress(child);
        if (rawAddress == null) {
          print('❌ Could not get address for $child');
          continue;
        }

        final adjustedAddress = rawAddress + hdf5Offset;
        print('📍 Raw address: 0x${rawAddress.toRadixString(16)}');
        print('📍 Adjusted address: 0x${adjustedAddress.toRadixString(16)}');

        try {
          // Read object header with adjusted address
          final header = await ObjectHeader.read(reader, adjustedAddress,
              filePath: filePath);

          print('\n📋 Object Header:');
          print('   Version: ${header.version}');
          print('   Messages: ${header.messages.length}');
          print('   Type: ${header.getObjectTypeDescription()}');

          // Get datatype
          final datatype = header.findDatatype();
          if (datatype != null) {
            print('\n🔤 Datatype:');
            print('   Class: ${datatype.dataclass} (${datatype.classId})');
            print('   Size: ${datatype.size} bytes');
            print('   Type name: ${datatype.typeName}');
          }

          // Get dataspace
          final dataspace = header.findDataspace();
          if (dataspace != null) {
            print('\n📐 Dataspace:');
            print('   Dimensions: ${dataspace.dimensions}');
            print('   Total elements: ${dataspace.totalElements}');
          }

          // Get layout
          final layout = header.findDataLayout();
          if (layout != null) {
            print('\n📦 Data Layout:');
            print('   Type: ${layout.runtimeType}');
            if (layout is ContiguousLayout) {
              print('   Address: 0x${layout.address.toRadixString(16)}');
              print('   Size: ${layout.size} bytes');
            } else if (layout is ChunkedLayout) {
              print('   Address: 0x${layout.address.toRadixString(16)}');
              print('   Chunk dimensions: ${layout.chunkDimensions}');
            }
          }

          // Get attributes
          final attrs = header.findAttributes();
          if (attrs.isNotEmpty) {
            print('\n🏷️  Attributes (${attrs.length}):');
            for (final attr in attrs.take(5)) {
              print('   - ${attr.name}: ${attr.value}');
            }
            if (attrs.length > 5) {
              print('   ... and ${attrs.length - 5} more');
            }
          }

          // Try to read data using the API
          print('\n📖 Attempting to read data...');
          try {
            final data = await hdf5File.readDataset('/$child');
            print('   ✅ Success! Read ${data.length} elements');
            if (data.isNotEmpty && data.length <= 10) {
              print('   Data: $data');
            } else if (data.isNotEmpty) {
              print('   First 5: ${data.take(5).toList()}');
              print('   Last 5: ${data.skip(data.length - 5).toList()}');
            }
          } catch (e) {
            print('   ❌ Failed: ${e.toString().split('\n').first}');
            if (e.toString().contains('Virtual dataset')) {
              print('   ℹ️  This is a Virtual Dataset (HDF5 1.10+ feature)');
            }
          }

          print('');
        } catch (e) {
          print('\n❌ Error: $e\n');
        }
      }

      print('═' * 80);
      print('✅ Inspection complete');
      print('═' * 80);
    } finally {
      await hdf5File.close();
    }
  } finally {
    await raf.close();
  }
}
