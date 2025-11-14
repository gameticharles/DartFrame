import 'dart:io';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/io/hdf5/superblock.dart';

void main() async {
  print('🔬 Checking processdata.h5 superblock\n');

  final file = File('example/data/processdata.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    final superblock = await Superblock.read(reader, filePath: file.path);

    print('📋 Superblock Information:');
    print('   Version: ${superblock.version}');
    print('   Offset size: ${superblock.offsetSize} bytes');
    print('   Length size: ${superblock.lengthSize} bytes');
    print(
        '   Root group address: 0x${superblock.rootGroupObjectHeaderAddress.toRadixString(16)}');
    print('   HDF5 start offset: ${superblock.hdf5StartOffset}');
    print(
        '   Adjusted root address: 0x${(superblock.rootGroupObjectHeaderAddress + superblock.hdf5StartOffset).toRadixString(16)}');

    // Try to read the root group
    print('\n🔍 Attempting to read root group...');
    final rootAddress =
        superblock.rootGroupObjectHeaderAddress + superblock.hdf5StartOffset;
    reader.seek(rootAddress);

    final version = await reader.readUint8();
    print('   Root group object header version: $version');

    if (version == 1 || version == 2) {
      print('   ✅ Valid version');
    } else {
      print('   ❌ Invalid version!');
      print('   This suggests the addresses might need different adjustment');
    }
  } finally {
    await raf.close();
  }
}
