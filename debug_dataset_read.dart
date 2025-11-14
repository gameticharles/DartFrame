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
    print('Reading superblock...');
    final superblock = await Superblock.read(reader, filePath: file.path);

    final rootAddress =
        superblock.rootGroupObjectHeaderAddress + superblock.hdf5StartOffset;
    print('Reading root group at address: 0x${rootAddress.toRadixString(16)}');

    final rootGroup = await Group.read(reader, rootAddress,
        hdf5Offset: superblock.hdf5StartOffset, filePath: file.path);

    print('Root group children: ${rootGroup.children}');

    // Get the address of the 'data' dataset
    final dataAddress = rootGroup.getChildAddress('data');
    if (dataAddress == null) {
      print('Error: data dataset not found');
      return;
    }

    print('\nData dataset address: 0x${dataAddress.toRadixString(16)}');
    final adjustedAddress = dataAddress + superblock.hdf5StartOffset;
    print('Adjusted address: 0x${adjustedAddress.toRadixString(16)}');

    // Read bytes at that location
    reader.seek(adjustedAddress);
    print('Current position: 0x${reader.position.toRadixString(16)}');

    final firstBytes = await reader.readBytes(32);
    print(
        'First 32 bytes: ${firstBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    // Reset and try to read object header
    reader.seek(adjustedAddress);
    print('\nAttempting to read object header...');
    final header =
        await ObjectHeader.read(reader, adjustedAddress, filePath: file.path);
    print('Object header read successfully!');
    print('Number of messages: ${header.messages.length}');

    // Try to find attributes
    final attributes = header.findAttributes();
    print('Number of attributes: ${attributes.length}');
    for (final attr in attributes) {
      print('  - ${attr.name}: ${attr.value}');
    }
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await raf.close();
  }
}
