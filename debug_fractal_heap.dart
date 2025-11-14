import 'lib/src/io/hdf5/hdf5_file.dart';
import 'lib/src/io/hdf5/hdf5_error.dart';

void main() async {
  setHdf5DebugMode(true);

  print('Debugging fractal heap parsing in test_links.h5\n');

  final file = await Hdf5File.open('test_links.h5');

  try {
    print('\nRoot group info:');
    print('  Address: 0x${file.root.address.toRadixString(16)}');
    print('  Children: ${file.root.children}');
    print('  Link messages: ${file.root.header.findLinks().length}');

    print('\nAll messages in header:');
    for (final msg in file.root.header.messages) {
      print(
          '  Type: 0x${msg.type.toRadixString(16).padLeft(4, '0')}, Size: ${msg.size}, Data: ${msg.data != null ? msg.data.runtimeType : 'null'}');
    }

    // Check LinkInfo message
    final linkInfoMsg = file.root.header.messages.firstWhere(
      (m) => m.type == 0x0002,
      orElse: () => throw Exception('No LinkInfo message found'),
    );

    print('\nLinkInfo message found:');
    if (linkInfoMsg.data != null) {
      final linkInfo = linkInfoMsg.data as dynamic;
      print(
          '  Fractal heap address: 0x${linkInfo.fractalHeapAddress.toRadixString(16)}');
      print(
          '  V2 B-tree address: 0x${linkInfo.v2BtreeAddress.toRadixString(16)}');
      print('  Maximum creation index: ${linkInfo.maximumCreationIndex}');
    }

    // Check for symbol table message
    final symbolTableMsgs =
        file.root.header.messages.where((m) => m.type == 0x0011).toList();
    print('\nSymbol table messages: ${symbolTableMsgs.length}');
    if (symbolTableMsgs.isNotEmpty && symbolTableMsgs.first.data != null) {
      final symTable = symbolTableMsgs.first.data as dynamic;
      print('  B-tree address: 0x${symTable.btreeAddress.toRadixString(16)}');
      print(
          '  Local heap address: 0x${symTable.localHeapAddress.toRadixString(16)}');
    }
  } finally {
    await file.close();
  }
}
