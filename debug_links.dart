import 'lib/src/io/hdf5/hdf5_file.dart';
import 'lib/src/io/hdf5/hdf5_error.dart';

void main() async {
  setHdf5DebugMode(true);

  print('Debugging link messages in test_links.h5\n');

  final file = await Hdf5File.open('test_links.h5');

  try {
    print('\nRoot group info:');
    print('  Address: 0x${file.root.address.toRadixString(16)}');
    print('  Header messages: ${file.root.header.messages.length}');

    for (final msg in file.root.header.messages) {
      print(
          '  Message type: 0x${msg.type.toRadixString(16).padLeft(4, '0')}, size: ${msg.size}');
    }

    print('\nLink messages found: ${file.root.header.findLinks().length}');
    for (final link in file.root.header.findLinks()) {
      print('  $link');
    }

    print('\nChildren from _childAddresses: ${file.root.children}');
  } finally {
    await file.close();
  }
}
