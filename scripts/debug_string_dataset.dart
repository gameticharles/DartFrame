import 'dart:io';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'package:dartframe/src/io/hdf5/object_header.dart';

void main() async {
  print('🔬 Debugging string dataset issue\n');

  final file = File('example/data/hdf5_test.h5');
  final raf = await file.open();
  final reader = ByteReader(raf);

  try {
    final hdf5File = await Hdf5File.open('example/data/hdf5_test.h5');

    try {
      // Get the arrays group
      final arraysGroup = await hdf5File.group('/arrays');

      // Try to get the problematic dataset address
      final address = arraysGroup.getChildAddress('1D String');
      print('1D String address: 0x${address?.toRadixString(16)}');

      if (address != null) {
        // Try to read the object header directly
        print('\nReading object header...');
        try {
          final header =
              await ObjectHeader.read(reader, address, filePath: file.path);
          print('✓ Object header read successfully');
          print('  Messages: ${header.messages.length}');

          final datatype = header.findDatatype();
          print('  Datatype: $datatype');

          final dataspace = header.findDataspace();
          print('  Dataspace: ${dataspace?.dimensions}');

          final layout = header.findDataLayout();
          print('  Layout: ${layout?.runtimeType}');
        } catch (e, stack) {
          print('✗ Error reading object header: $e');
          print('Stack trace:\n$stack');
        }
      }
    } finally {
      await hdf5File.close();
    }
  } finally {
    await raf.close();
  }
}
