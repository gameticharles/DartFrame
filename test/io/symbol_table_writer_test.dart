import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/symbol_table_writer.dart';

void main() {
  group('SymbolTableWriter - V1 Format', () {
    late SymbolTableWriter writer;

    setUp(() {
      writer = SymbolTableWriter(format: SymbolTableFormat.v1);
    });

    group('B-tree node generation', () {
      test('generates valid B-tree signature', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;

        // Check B-tree signature 'TREE'
        expect(bytes[0], equals(0x54)); // 'T'
        expect(bytes[1], equals(0x52)); // 'R'
        expect(bytes[2], equals(0x45)); // 'E'
        expect(bytes[3], equals(0x45)); // 'E'
      });

      test('sets correct node type for group B-tree', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;

        // Node type should be 0 for group B-tree
        expect(bytes[4], equals(0));
      });

      test('sets correct node level for leaf node', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;

        // Node level should be 0 for leaf node
        expect(bytes[5], equals(0));
      });

      test('sets correct number of entries', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;

        // Entries used should be 1 (little-endian)
        expect(bytes[6], equals(1));
        expect(bytes[7], equals(0));
      });

      test('sets undefined sibling addresses', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;

        // Left sibling address (8 bytes starting at offset 8)
        for (int i = 8; i < 16; i++) {
          expect(bytes[i], equals(0xFF));
        }

        // Right sibling address (8 bytes starting at offset 16)
        for (int i = 16; i < 24; i++) {
          expect(bytes[i], equals(0xFF));
        }
      });

      test('includes symbol table node after B-tree', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;

        // Symbol table node signature 'SNOD' should be at offset 48
        expect(bytes[48], equals(0x53)); // 'S'
        expect(bytes[49], equals(0x4E)); // 'N'
        expect(bytes[50], equals(0x4F)); // 'O'
        expect(bytes[51], equals(0x44)); // 'D'
      });
    });

    group('Local heap creation', () {
      test('generates valid local heap signature', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;

        // Local heap starts after B-tree (48 bytes) and symbol table node (48 bytes)
        final heapOffset = 48 + 48;

        // Check local heap signature 'HEAP'
        expect(bytes[heapOffset], equals(0x48)); // 'H'
        expect(bytes[heapOffset + 1], equals(0x45)); // 'E'
        expect(bytes[heapOffset + 2], equals(0x41)); // 'A'
        expect(bytes[heapOffset + 3], equals(0x50)); // 'P'
      });

      test('sets correct version', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;
        final heapOffset = 48 + 48;

        // Version should be 0
        expect(bytes[heapOffset + 4], equals(0));
      });

      test('stores dataset name in data segment', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;

        // Data segment starts after B-tree (48) + symbol table node (48) + heap header (32)
        final dataOffset = 48 + 48 + 32;

        // Check dataset name '/data'
        expect(bytes[dataOffset], equals(0x2F)); // '/'
        expect(bytes[dataOffset + 1], equals(0x64)); // 'd'
        expect(bytes[dataOffset + 2], equals(0x61)); // 'a'
        expect(bytes[dataOffset + 3], equals(0x74)); // 't'
        expect(bytes[dataOffset + 4], equals(0x61)); // 'a'
        expect(bytes[dataOffset + 5], equals(0)); // null terminator
      });

      test('calculates correct data segment size', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;
        final heapOffset = 48 + 48;

        // Data segment size is at offset 8 in heap header (8 bytes, little-endian)
        // '/data' = 5 bytes + 1 null terminator = 6 bytes
        expect(bytes[heapOffset + 8], equals(6));
        for (int i = 1; i < 8; i++) {
          expect(bytes[heapOffset + 8 + i], equals(0));
        }
      });
    });

    group('Dataset name encoding', () {
      test('encodes simple dataset name', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;
        final dataOffset = 48 + 48 + 32;

        // Verify '/data' encoding
        final expectedBytes = [0x2F, 0x64, 0x61, 0x74, 0x61, 0x00];
        for (int i = 0; i < expectedBytes.length; i++) {
          expect(bytes[dataOffset + i], equals(expectedBytes[i]));
        }
      });

      test('encodes dataset name with path', () {
        final entries = [
          SymbolTableEntry(name: '/group/dataset', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;
        final dataOffset = 48 + 48 + 32;

        // Verify '/group/dataset' encoding
        final name = '/group/dataset';
        for (int i = 0; i < name.length; i++) {
          expect(bytes[dataOffset + i], equals(name.codeUnitAt(i)));
        }
        expect(bytes[dataOffset + name.length], equals(0)); // null terminator
      });

      test('handles UTF-8 characters in dataset name', () {
        final entries = [
          SymbolTableEntry(name: '/données', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;
        final dataOffset = 48 + 48 + 32;

        // Verify UTF-8 encoding (é is encoded as 0xC3 0xA9)
        expect(bytes[dataOffset], equals(0x2F)); // '/'
        expect(bytes[dataOffset + 1], equals(0x64)); // 'd'
        expect(bytes[dataOffset + 2], equals(0x6F)); // 'o'
        expect(bytes[dataOffset + 3], equals(0x6E)); // 'n'
        expect(bytes[dataOffset + 4], equals(0x6E)); // 'n'
        expect(bytes[dataOffset + 5], equals(0xC3)); // é (first byte)
        expect(bytes[dataOffset + 6], equals(0xA9)); // é (second byte)
        expect(bytes[dataOffset + 7], equals(0x65)); // 'e'
        expect(bytes[dataOffset + 8], equals(0x73)); // 's'
        expect(bytes[dataOffset + 9], equals(0)); // null terminator
      });
    });

    group('Address references', () {
      test('returns correct B-tree address', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x500,
        );

        expect(result['btreeAddress'], equals(0x500));
      });

      test('returns correct local heap address', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x500,
        );

        // Local heap starts after B-tree (48 bytes) and symbol table node (48 bytes)
        expect(result['localHeapAddress'], equals(0x500 + 48 + 48));
      });

      test('stores dataset header address in symbol table entry', () {
        final datasetHeaderAddress = 0x12345678;
        final entries = [
          SymbolTableEntry(
              name: '/data', objectHeaderAddress: datasetHeaderAddress),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;

        // Symbol table entry starts at offset 56 (48 B-tree + 8 SNOD header)
        // Object header address is at offset 8 in the entry
        final addressOffset = 56 + 8;

        // Verify address (little-endian)
        expect(bytes[addressOffset], equals(0x78));
        expect(bytes[addressOffset + 1], equals(0x56));
        expect(bytes[addressOffset + 2], equals(0x34));
        expect(bytes[addressOffset + 3], equals(0x12));
        for (int i = 4; i < 8; i++) {
          expect(bytes[addressOffset + i], equals(0));
        }
      });

      test('symbol table node points to correct dataset', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0xABCDEF00),
        ];

        final result = writer.write(
          entries: entries,
          startAddress: 0x100,
        );

        final bytes = result['bytes'] as List<int>;

        // Symbol table entry object header address
        final addressOffset = 56 + 8;

        // Verify the address matches what we passed in
        final address = bytes[addressOffset] |
            (bytes[addressOffset + 1] << 8) |
            (bytes[addressOffset + 2] << 16) |
            (bytes[addressOffset + 3] << 24) |
            (bytes[addressOffset + 4] << 32) |
            (bytes[addressOffset + 5] << 40) |
            (bytes[addressOffset + 6] << 48) |
            (bytes[addressOffset + 7] << 56);

        expect(address, equals(0xABCDEF00));
      });
    });

    group('Size calculation', () {
      test('calculates correct size for simple dataset name', () {
        final entries = [
          SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
        ];

        final size = writer.calculateSize(entries);

        // B-tree: 48 bytes
        // Symbol table node: 48 bytes (8 header + 40 entry)
        // Local heap header: 32 bytes
        // Data segment: 6 bytes ('/data' + null)
        expect(size, equals(48 + 48 + 32 + 6));
      });

      test('calculates correct size for longer dataset name', () {
        final name = '/group/subgroup/dataset';
        final entries = [
          SymbolTableEntry(name: name, objectHeaderAddress: 0x1000),
        ];

        final size = writer.calculateSize(entries);

        // B-tree: 48 bytes
        // Symbol table node: 48 bytes
        // Local heap header: 32 bytes
        // Data segment: name.length + 1 (null terminator)
        expect(size, equals(48 + 48 + 32 + name.length + 1));
      });

      test('calculates correct size for UTF-8 dataset name', () {
        final name = '/données';
        final entries = [
          SymbolTableEntry(name: name, objectHeaderAddress: 0x1000),
        ];

        final size = writer.calculateSize(entries);

        // UTF-8 encoding of 'données' is 9 bytes (é = 2 bytes)
        // B-tree: 48 bytes
        // Symbol table node: 48 bytes
        // Local heap header: 32 bytes
        // Data segment: 9 + 1 (null terminator) = 10 bytes
        expect(size, equals(48 + 48 + 32 + 10));
      });

      test('calculates correct size for multiple entries', () {
        final entries = [
          SymbolTableEntry(name: '/data1', objectHeaderAddress: 0x1000),
          SymbolTableEntry(name: '/data2', objectHeaderAddress: 0x2000),
        ];

        final size = writer.calculateSize(entries);

        // B-tree: 24 + (2+1)*8 + 2*8 = 24 + 24 + 16 = 64 bytes
        // Symbol table node: 8 + 40*2 = 88 bytes
        // Local heap header: 32 bytes
        // Data segment: 7 + 7 = 14 bytes ('/data1\0' + '/data2\0')
        expect(size, equals(64 + 88 + 32 + 14));
      });
    });

    group('Symbol table message', () {
      test('creates correct symbol table message', () {
        final message = writer.createSymbolTableMessage(
          btreeAddress: 0x1000,
          localHeapAddress: 0x2000,
        );

        expect(message.length, equals(16));

        // B-tree address (little-endian)
        expect(message[0], equals(0x00));
        expect(message[1], equals(0x10));
        expect(message[2], equals(0x00));
        expect(message[3], equals(0x00));

        // Local heap address (little-endian)
        expect(message[8], equals(0x00));
        expect(message[9], equals(0x20));
        expect(message[10], equals(0x00));
        expect(message[11], equals(0x00));
      });
    });
  });

  group('SymbolTableWriter - V2 Format', () {
    late SymbolTableWriter writer;

    setUp(() {
      writer = SymbolTableWriter(format: SymbolTableFormat.v2);
    });

    test('generates fractal heap signature', () {
      final entries = [
        SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
      ];

      final result = writer.write(
        entries: entries,
        startAddress: 0x100,
      );

      final bytes = result['bytes'] as List<int>;

      // Check fractal heap signature 'FRHP'
      expect(bytes[0], equals(0x46)); // 'F'
      expect(bytes[1], equals(0x52)); // 'R'
      expect(bytes[2], equals(0x48)); // 'H'
      expect(bytes[3], equals(0x50)); // 'P'
    });

    test('generates B-tree V2 signature', () {
      final entries = [
        SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
      ];

      final result = writer.write(
        entries: entries,
        startAddress: 0x100,
      );

      final bytes = result['bytes'] as List<int>;

      // Find B-tree V2 signature 'BTHD' (after fractal heap)
      bool foundBTHD = false;
      for (int i = 0; i < bytes.length - 3; i++) {
        if (bytes[i] == 0x42 &&
            bytes[i + 1] == 0x54 &&
            bytes[i + 2] == 0x48 &&
            bytes[i + 3] == 0x44) {
          foundBTHD = true;
          break;
        }
      }

      expect(foundBTHD, isTrue);
    });

    test('returns correct addresses', () {
      final entries = [
        SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
      ];

      final result = writer.write(
        entries: entries,
        startAddress: 0x500,
      );

      expect(result['fractalHeapAddress'], equals(0x500));
      expect(result['btreeAddress'], isNotNull);
      expect(result['btreeAddress'], greaterThan(0x500));
    });
  });
}
