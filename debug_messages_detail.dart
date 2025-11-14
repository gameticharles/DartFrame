import 'dart:io';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/io/hdf5/superblock.dart';
import 'package:dartframe/src/io/hdf5/group.dart';
import 'package:dartframe/src/io/hdf5/object_header.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    final superblock = await Superblock.read(reader, filePath: file.path);
    final rootAddress =
        superblock.rootGroupObjectHeaderAddress + superblock.hdf5StartOffset;
    final rootGroup = await Group.read(reader, rootAddress,
        hdf5Offset: superblock.hdf5StartOffset, filePath: file.path);

    final dataAddress = rootGroup.getChildAddress('data');
    final adjustedAddress = dataAddress! + superblock.hdf5StartOffset;

    final header =
        await ObjectHeader.read(reader, adjustedAddress, filePath: file.path);

    print('Object header messages:');
    for (int i = 0; i < header.messages.length; i++) {
      final msg = header.messages[i];
      print('Message $i:');
      print('  Type: 0x${msg.type.toRadixString(16).padLeft(4, '0')}');
      print('  Size: ${msg.size}');
      print('  Flags: 0x${msg.flags.toRadixString(16)}');
      print('  Data: ${msg.data?.runtimeType}');
    }

    // Check for attribute messages specifically
    const msgTypeAttribute = 0x000c;
    final attrMessages =
        header.messages.where((m) => m.type == msgTypeAttribute).toList();
    print('\nAttribute messages found: ${attrMessages.length}');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await raf.close();
  }
}
