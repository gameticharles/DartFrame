import 'dart:io';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/io/hdf5/superblock.dart';
import 'package:dartframe/src/io/hdf5/object_header.dart';

void main() async {
  final file = File('example/data/test_attributes.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    print('Reading superblock...');
    final superblock = await Superblock.read(reader, filePath: file.path);
    print('Superblock version: ${superblock.version}');
    print('Offset size: ${superblock.offsetSize}');
    print('Length size: ${superblock.lengthSize}');
    print(
        'Root group address: 0x${superblock.rootGroupObjectHeaderAddress.toRadixString(16)}');
    print('HDF5 start offset: ${superblock.hdf5StartOffset}');

    final rootAddress =
        superblock.rootGroupObjectHeaderAddress + superblock.hdf5StartOffset;
    print(
        '\nReading root group at address: 0x${rootAddress.toRadixString(16)}');

    reader.seek(rootAddress);
    print('Current position: 0x${reader.position.toRadixString(16)}');

    // Read first few bytes to see what we have
    final firstBytes = await reader.readBytes(16);
    print(
        'First 16 bytes: ${firstBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    // Reset and try to read object header
    reader.seek(rootAddress);
    print('\nAttempting to read object header...');
    final header =
        await ObjectHeader.read(reader, rootAddress, filePath: file.path);
    print('Object header read successfully!');
    print('Number of messages: ${header.messages.length}');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await raf.close();
  }
}
