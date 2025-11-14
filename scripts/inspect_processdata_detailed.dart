import 'dart:io';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/io/hdf5/object_header.dart';

void main() async {
  print('═' * 80);
  print('🔬 Detailed Inspection: example/data/processdata.h5');
  print('═' * 80);

  final file = File('example/data/processdata.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    final hdf5File = await Hdf5File.open('example/data/processdata.h5');

    try {
      final rootChildren = hdf5File.list('/');
      print('\n📁 Root contains ${rootChildren.length} objects:');
      print('   ${rootChildren.join(", ")}\n');

      final rootGroup = await hdf5File.group('/');

      for (final child in rootChildren) {
        print('─' * 80);
        print('🔍 Object: /$child');
        print('─' * 80);

        final address = rootGroup.getChildAddress(child);
        if (address == null) {
          print('❌ Could not get address for $child');
          continue;
        }

        print('📍 Address: 0x${address.toRadixString(16)}');

        try {
          // Read object header
          final header =
              await ObjectHeader.read(reader, address, filePath: file.path);

          print('📋 Object Header:');
          print('   Version: ${header.version}');
          print('   Messages: ${header.messages.length}');

          // Determine object type
          final objType = header.determineObjectType();
          print('   Type: ${header.getObjectTypeDescription()}');

          // List message types
          final msgTypes = <String>[];
          for (final msg in header.messages) {
            final typeName = _getMessageTypeName(msg.type);
            msgTypes.add('$typeName (0x${msg.type.toRadixString(16)})');
          }
          print('   Message types:');
          for (final mt in msgTypes) {
            print('      - $mt');
          }

          // Get datatype
          final datatype = header.findDatatype();
          if (datatype != null) {
            print('\n🔤 Datatype:');
            print('   Class: ${datatype.dataclass} (${datatype.classId})');
            print('   Size: ${datatype.size} bytes');
            print('   Type name: ${datatype.typeName}');
            print('   Details: $datatype');
          } else {
            print('\n🔤 Datatype: NOT FOUND');
          }

          // Get dataspace
          final dataspace = header.findDataspace();
          if (dataspace != null) {
            print('\n📐 Dataspace:');
            print('   Dimensions: ${dataspace.dimensions}');
            print('   Total elements: ${dataspace.totalElements}');
          } else {
            print('\n📐 Dataspace: NOT FOUND');
          }

          // Get layout
          print('\n📦 Data Layout:');
          try {
            final layout = header.findDataLayout();
            if (layout != null) {
              print('   Type: ${layout.runtimeType}');
              if (layout is ContiguousLayout) {
                print('   Address: 0x${layout.address.toRadixString(16)}');
                print('   Size: ${layout.size} bytes');
              } else if (layout is ChunkedLayout) {
                print('   Address: 0x${layout.address.toRadixString(16)}');
                print('   Chunk dimensions: ${layout.chunkDimensions}');
              } else if (layout is CompactLayout) {
                print('   Data size: ${layout.data.length} bytes');
              }
            } else {
              print('   NOT FOUND');
            }
          } catch (e) {
            print('   ❌ Error reading layout: $e');
          }

          // Get attributes
          final attrs = header.findAttributes();
          if (attrs.isNotEmpty) {
            print('\n🏷️  Attributes (${attrs.length}):');
            for (final attr in attrs) {
              print('   - ${attr.name}: ${attr.value}');
            }
          }

          // Try to read data if it's a dataset
          if (objType == Hdf5ObjectType.dataset) {
            print('\n📖 Attempting to read data...');
            try {
              final data = await hdf5File.readDataset('/$child');
              print('   ✅ Success! Read ${data.length} elements');
              if (data.isNotEmpty && data.length <= 10) {
                print('   Data: $data');
              } else if (data.isNotEmpty) {
                print('   First 3: ${data.take(3).toList()}');
              }
            } catch (e) {
              print('   ❌ Failed: ${e.toString().split('\n').first}');
            }
          }

          print('');
        } catch (e, stack) {
          print('❌ Error reading object header: $e');
          print('Stack trace: $stack');
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

String _getMessageTypeName(int type) {
  switch (type) {
    case 0x0000:
      return 'NIL';
    case 0x0001:
      return 'Dataspace';
    case 0x0002:
      return 'Link Info';
    case 0x0003:
      return 'Datatype';
    case 0x0005:
      return 'Fill Value';
    case 0x0008:
      return 'Data Layout';
    case 0x000A:
      return 'Group Info';
    case 0x000B:
      return 'Filter Pipeline';
    case 0x000C:
      return 'Attribute';
    case 0x0010:
      return 'Header Continuation';
    case 0x0011:
      return 'Symbol Table';
    case 0x0016:
      return 'Link';
    default:
      return 'Unknown';
  }
}
