import 'package:dartframe/dartframe.dart';

Future<void> inspectDataset(Hdf5File file, String path,
    {bool detailed = false}) async {
  print('\n📊 Dataset: $path');

  try {
    final ds = await file.dataset(path);
    print('  ✓ Successfully opened');
    print('  📐 Shape: ${ds.shape}');
    print('  🔤 Datatype: ${ds.datatype}');
    print('  📦 Layout: ${ds.layout.runtimeType}');

    if (ds.layout is ChunkedLayout) {
      final chunked = ds.layout as ChunkedLayout;
      print('  🧩 Chunk dimensions: ${chunked.chunkDimensions}');
      print('  📍 Chunk address: 0x${chunked.address.toRadixString(16)}');
    } else if (ds.layout is ContiguousLayout) {
      final contiguous = ds.layout as ContiguousLayout;
      print('  📍 Data address: 0x${contiguous.address.toRadixString(16)}');
      print('  📏 Data size: ${contiguous.size} bytes');
    }

    if (ds.filterPipeline != null && ds.filterPipeline!.isNotEmpty) {
      print('  🔧 Filters: ${ds.filterPipeline}');
    }

    // Show attributes
    final attrs = ds.attributes;
    if (attrs.isNotEmpty) {
      print('  🏷️  Attributes (${attrs.length}):');
      for (final attr in attrs) {
        print('     - ${attr.name}: ${attr.value}');
      }
    }

    // Try to read data
    if (detailed) {
      try {
        print('  📖 Attempting to read data...');
        final data = await file.readDataset(path);
        print('  ✅ Read successful: ${data.length} elements');

        if (data.isNotEmpty) {
          if (data.length <= 5) {
            print('  📄 Data: $data');
          } else {
            print('  📄 First 3 elements: ${data.take(3).toList()}');
            print(
                '  📄 Last 3 elements: ${data.skip(data.length - 3).toList()}');
          }
        }
      } catch (e) {
        print('  ❌ Read failed: ${e.toString().split('\n').first}');
      }
    }
  } catch (e) {
    print('  ❌ Failed to open: ${e.toString().split('\n').first}');

    // Try to get more details by reading the object header directly
    try {
      final group = await file.group('/');
      final address = group.getChildAddress(path.substring(1));

      if (address != null) {
        print('  🔍 Object address: 0x${address.toRadixString(16)}');

        final fileIO = FileIO();
        final raf =
            await fileIO.openRandomAccess('example/data/processdata.h5');
        final reader = ByteReader(raf);

        try {
          final header = await ObjectHeader.read(reader, address,
              filePath: 'example/data/processdata.h5');

          print('  📋 Object header messages: ${header.messages.length}');

          final datatype = header.findDatatype();
          if (datatype != null) {
            print('  🔤 Datatype found: $datatype');
          }

          final dataspace = header.findDataspace();
          if (dataspace != null) {
            print('  📐 Dataspace found: ${dataspace.dimensions}');
          }

          final layout = header.findDataLayout();
          if (layout != null) {
            print('  📦 Layout found: ${layout.runtimeType}');
          }
        } finally {
          await raf.close();
        }
      }
    } catch (e2) {
      print(
          '  🔍 Additional details unavailable: ${e2.toString().split('\n').first}');
    }
  }
}

Future<void> inspectObject(Hdf5File file, String path) async {
  try {
    final objType = await file.getObjectType(path);

    if (objType == 'dataset') {
      await inspectDataset(file, path, detailed: true);
    } else if (objType == 'group') {
      print('\n📁 Group: $path');
      final group = await file.group(path);
      print('  Children: ${group.children.join(", ")}');

      // Show attributes
      final attrs = group.header.findAttributes();
      if (attrs.isNotEmpty) {
        print('  🏷️  Attributes (${attrs.length}):');
        for (final attr in attrs) {
          print('     - ${attr.name}: ${attr.value}');
        }
      }
    } else {
      print('\n❓ Unknown object: $path');
      print('  Type: $objType');
    }
  } catch (e) {
    print('\n❌ Error accessing $path: ${e.toString().split('\n').first}');
  }
}

void main() async {
  print('═' * 80);
  print('🔬 Detailed Inspection: example/data/processdata.h5');
  print('═' * 80);

  try {
    final file = await Hdf5File.open('example/data/processdata.h5');

    try {
      // Get root children
      final rootChildren = file.list('/');
      print('\n📁 Root level objects: ${rootChildren.length}');
      print('   ${rootChildren.join(", ")}');

      // Inspect each object
      for (final child in rootChildren) {
        await inspectObject(file, '/$child');
      }

      print('\n${'═' * 80}');
      print('✅ Inspection complete');
      print('═' * 80);
    } finally {
      await file.close();
    }
  } catch (e) {
    print('\n❌ Error opening file: $e');
  }
}
