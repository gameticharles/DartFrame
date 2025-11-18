import 'dart:io';
import 'dart:typed_data';
import 'dart:math' show min;

/// Simple HDF5 file inspector to debug write issues
Future<void> main(List<String> args) async {
  final filePath =
      args.isNotEmpty ? args[0] : 'example/data/test_simple_output.h5';

  print('Inspecting: $filePath\n');

  final file = File(filePath);
  final bytes = await file.readAsBytes();

  print('File size: ${bytes.length} bytes\n');

  // Check superblock
  print('═' * 60);
  print('SUPERBLOCK (0-95)');
  print('═' * 60);
  printHex(bytes, 0, 96);

  // Root group address is at offset 64
  final rootGroupAddr = readUint64(bytes, 64);
  print(
      '\nRoot group object header address: 0x${rootGroupAddr.toRadixString(16)} ($rootGroupAddr)');

  // Check root group object header
  if (rootGroupAddr < bytes.length) {
    print('\n═' * 60);
    print('ROOT GROUP OBJECT HEADER ($rootGroupAddr-)');
    print('═' * 60);
    printHex(bytes, rootGroupAddr, min(rootGroupAddr + 100, bytes.length));

    // Parse object header
    final version = bytes[rootGroupAddr];
    print('\nObject header version: $version');

    if (version == 1) {
      final numMessages = readUint16(bytes, rootGroupAddr + 2);
      final headerSize = readUint32(bytes, rootGroupAddr + 8);
      print('Number of messages: $numMessages');
      print('Header size: $headerSize bytes');

      // Read first message
      var msgOffset = rootGroupAddr + 16;
      print('\nFirst message at offset $msgOffset:');
      final msgType = readUint16(bytes, msgOffset);
      final msgSize = readUint16(bytes, msgOffset + 2);
      final msgFlags = bytes[msgOffset + 4];
      print(
          '  Type: 0x${msgType.toRadixString(16)} (${_messageTypeName(msgType)})');
      print('  Size: $msgSize bytes');
      print('  Flags: 0x${msgFlags.toRadixString(16)}');

      // If it's a symbol table message, read the addresses
      if (msgType == 0x0011) {
        final btreeAddr = readUint64(bytes, msgOffset + 8);
        final heapAddr = readUint64(bytes, msgOffset + 16);
        print(
            '  B-tree address: 0x${btreeAddr.toRadixString(16)} ($btreeAddr)');
        print(
            '  Local heap address: 0x${heapAddr.toRadixString(16)} ($heapAddr)');

        // Check if B-tree exists
        if (btreeAddr > 0 && btreeAddr < bytes.length) {
          print('\n═' * 60);
          print('B-TREE ($btreeAddr-)');
          print('═' * 60);
          printHex(bytes, btreeAddr, min(btreeAddr + 64, bytes.length));

          // Check signature
          final sig =
              String.fromCharCodes(bytes.sublist(btreeAddr, btreeAddr + 4));
          print('\nSignature: "$sig"');

          // Parse B-tree to find symbol table node address
          if (sig == 'TREE') {
            final nodeType = bytes[btreeAddr + 4];
            final nodeLevel = bytes[btreeAddr + 5];
            final entriesUsed = readUint16(bytes, btreeAddr + 6);
            print('Node type: $nodeType');
            print('Node level: $nodeLevel');
            print('Entries used: $entriesUsed');

            // For a leaf node (level 0), the structure is:
            // 0-3: signature, 4: type, 5: level, 6-7: entries used
            // 8-15: left sibling, 16-23: right sibling
            // 24-31: key 0, 32-39: child pointer, 40-47: key 1
            if (nodeLevel == 0 && entriesUsed > 0) {
              final symbolTableNodeAddr = readUint64(bytes, btreeAddr + 32);
              print(
                  'Symbol table node address: 0x${symbolTableNodeAddr.toRadixString(16)} ($symbolTableNodeAddr)');

              // Check symbol table node
              if (symbolTableNodeAddr > 0 &&
                  symbolTableNodeAddr < bytes.length) {
                print('\n═' * 60);
                print('SYMBOL TABLE NODE ($symbolTableNodeAddr-)');
                print('═' * 60);
                printHex(bytes, symbolTableNodeAddr,
                    min(symbolTableNodeAddr + 100, bytes.length));

                final nodeSig = String.fromCharCodes(bytes.sublist(
                    symbolTableNodeAddr, symbolTableNodeAddr + 4));
                print('\nSignature: "$nodeSig"');

                if (nodeSig == 'SNOD') {
                  final version = bytes[symbolTableNodeAddr + 4];
                  final numSymbols = readUint16(bytes, symbolTableNodeAddr + 6);
                  print('Version: $version');
                  print('Number of symbols: $numSymbols');

                  // Read first symbol table entry (starts at offset 8)
                  if (numSymbols > 0) {
                    final entryOffset = symbolTableNodeAddr + 8;
                    final linkNameOffset = readUint64(bytes, entryOffset);
                    final objectHeaderAddr = readUint64(bytes, entryOffset + 8);
                    print('\nFirst entry:');
                    print('  Link name offset in heap: $linkNameOffset');
                    print(
                        '  Object header address: 0x${objectHeaderAddr.toRadixString(16)} ($objectHeaderAddr)');

                    // Check if object header exists
                    if (objectHeaderAddr > 0 &&
                        objectHeaderAddr < bytes.length) {
                      print('  ✓ Object header exists');
                    } else {
                      print('  ❌ Object header address is invalid!');
                    }
                  }
                }
              }
            }
          }
        } else {
          print('\n⚠️  B-tree address is invalid or zero!');
        }

        // Check if local heap exists
        if (heapAddr > 0 && heapAddr < bytes.length) {
          print('\n═' * 60);
          print('LOCAL HEAP ($heapAddr-)');
          print('═' * 60);
          printHex(bytes, heapAddr, min(heapAddr + 64, bytes.length));

          // Check signature
          final sig =
              String.fromCharCodes(bytes.sublist(heapAddr, heapAddr + 4));
          print('\nSignature: "$sig"');
        } else {
          print('\n⚠️  Local heap address is invalid or zero!');
        }
      }
    }
  }
}

String _messageTypeName(int type) {
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

void printHex(Uint8List bytes, int start, int end) {
  for (int i = start; i < end; i += 16) {
    final offset = i.toRadixString(16).padLeft(4, '0');
    final hexPart = <String>[];
    final asciiPart = <String>[];

    for (int j = 0; j < 16 && i + j < end; j++) {
      final byte = bytes[i + j];
      hexPart.add(byte.toRadixString(16).padLeft(2, '0'));
      asciiPart.add(byte >= 32 && byte < 127 ? String.fromCharCode(byte) : '.');
    }

    print('$offset: ${hexPart.join(' ').padRight(48)} ${asciiPart.join('')}');
  }
}

int readUint16(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

int readUint32(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

int readUint64(Uint8List bytes, int offset) {
  int low = readUint32(bytes, offset);
  int high = readUint32(bytes, offset + 4);
  return low + (high << 32);
}
