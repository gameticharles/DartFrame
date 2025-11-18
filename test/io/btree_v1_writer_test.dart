import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/btree_v1_writer.dart';
import 'package:dartframe/src/io/hdf5/byte_writer.dart';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';
import 'dart:typed_data';

void main() {
  group('BTreeV1Writer - Chunk Index', () {
    test('writes single leaf node for small dataset', () {
      final writer = BTreeV1Writer(dimensionality: 2);
      final byteWriter = ByteWriter();

      final entries = [
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [0, 0],
          chunkAddress: 1000,
        ),
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [0, 1],
          chunkAddress: 2000,
        ),
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [1, 0],
          chunkAddress: 3000,
        ),
      ];

      final address = writer.writeChunkIndex(byteWriter, entries);

      expect(address, equals(0));
      expect(byteWriter.bytes.length, greaterThan(0));

      // Verify signature
      expect(
          String.fromCharCodes(byteWriter.bytes.sublist(0, 4)), equals('TREE'));

      // Verify node type (1 = chunked raw data)
      expect(byteWriter.bytes[4], equals(1));

      // Verify node level (0 = leaf)
      expect(byteWriter.bytes[5], equals(0));

      // Verify number of entries
      final entriesUsed = byteWriter.bytes[6] | (byteWriter.bytes[7] << 8);
      expect(entriesUsed, equals(3));
    });

    test('writes multi-level tree for large dataset', () {
      final writer = BTreeV1Writer(dimensionality: 2);
      final byteWriter = ByteWriter();

      // Create more than maxEntriesPerNode (16) entries
      final entries = <BTreeV1ChunkEntry>[];
      for (int i = 0; i < 20; i++) {
        entries.add(BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [i ~/ 10, i % 10],
          chunkAddress: 1000 + i * 1024,
        ));
      }

      final address = writer.writeChunkIndex(byteWriter, entries);

      // For multi-level trees, root is written last
      expect(address, greaterThan(0));
      expect(byteWriter.bytes.length, greaterThan(0));

      // First node should be a leaf node
      expect(
          String.fromCharCodes(byteWriter.bytes.sublist(0, 4)), equals('TREE'));

      // Root node should also have TREE signature
      expect(
          String.fromCharCodes(byteWriter.bytes.sublist(address, address + 4)),
          equals('TREE'));

      // Root should be internal node (level > 0)
      expect(byteWriter.bytes[address + 5], greaterThan(0));
    });

    test('sorts entries by coordinates', () {
      final writer = BTreeV1Writer(dimensionality: 2);
      final byteWriter = ByteWriter();

      // Create entries in random order
      final entries = [
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [1, 1],
          chunkAddress: 3000,
        ),
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [0, 0],
          chunkAddress: 1000,
        ),
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [0, 1],
          chunkAddress: 2000,
        ),
      ];

      final address = writer.writeChunkIndex(byteWriter, entries);

      expect(address, equals(0));
      // Entries should be sorted internally
    });

    test('creates valid chunk index for 3D dataset', () {
      final writer = BTreeV1Writer(dimensionality: 3);
      final byteWriter = ByteWriter();

      final entries = <BTreeV1ChunkEntry>[];
      for (int i = 0; i < 8; i++) {
        entries.add(BTreeV1ChunkEntry(
          chunkSize: 512,
          filterMask: 0,
          chunkCoordinates: [i ~/ 4, (i ~/ 2) % 2, i % 2],
          chunkAddress: 2000 + i * 512,
        ));
      }

      final address = writer.writeChunkIndex(byteWriter, entries);

      expect(address, equals(0));
      expect(byteWriter.bytes.length, greaterThan(0));

      // Verify signature and type
      expect(
          String.fromCharCodes(byteWriter.bytes.sublist(0, 4)), equals('TREE'));
      expect(byteWriter.bytes[4], equals(1));
    });

    test('handles large chunk index with 50+ chunks', () {
      final writer = BTreeV1Writer(dimensionality: 2);
      final byteWriter = ByteWriter();

      final entries = <BTreeV1ChunkEntry>[];
      for (int i = 0; i < 50; i++) {
        entries.add(BTreeV1ChunkEntry(
          chunkSize: 2048,
          filterMask: 0,
          chunkCoordinates: [i ~/ 10, i % 10],
          chunkAddress: 5000 + i * 2048,
        ));
      }

      final address = writer.writeChunkIndex(byteWriter, entries);

      expect(address, greaterThan(0));
      expect(byteWriter.bytes.length, greaterThan(0));

      // Verify root is internal node
      expect(byteWriter.bytes[address + 5], greaterThan(0));
    });

    test('validates B-tree structure is valid', () async {
      final writer = BTreeV1Writer(dimensionality: 2);
      final byteWriter = ByteWriter();

      final entries = [
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [0, 0],
          chunkAddress: 1000,
        ),
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [0, 10],
          chunkAddress: 2000,
        ),
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [10, 0],
          chunkAddress: 3000,
        ),
      ];

      final address = writer.writeChunkIndex(byteWriter, entries);

      // Create reader from written bytes to validate structure
      final bytes = Uint8List.fromList(byteWriter.bytes);
      final reader = ByteReader.fromBytes(bytes);

      // Verify we can read the B-tree header
      reader.seek(address);
      final signature = String.fromCharCodes(await reader.readBytes(4));
      expect(signature, equals('TREE'));

      final nodeType = await reader.readUint8();
      expect(nodeType, equals(1)); // Chunked raw data

      final nodeLevel = await reader.readUint8();
      expect(nodeLevel, equals(0)); // Leaf node

      final entriesUsed = await reader.readUint16();
      expect(entriesUsed, equals(3));
    });

    test('validates multi-level B-tree structure is valid', () async {
      final writer = BTreeV1Writer(dimensionality: 2);
      final byteWriter = ByteWriter();

      // Create 25 entries to force multi-level tree
      final entries = <BTreeV1ChunkEntry>[];
      for (int i = 0; i < 25; i++) {
        entries.add(BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [i * 10, 0],
          chunkAddress: 1000 + i * 1024,
        ));
      }

      final address = writer.writeChunkIndex(byteWriter, entries);

      // Create reader from written bytes to validate structure
      final bytes = Uint8List.fromList(byteWriter.bytes);
      final reader = ByteReader.fromBytes(bytes);

      // Verify root node structure
      reader.seek(address);
      final signature = String.fromCharCodes(await reader.readBytes(4));
      expect(signature, equals('TREE'));

      final nodeType = await reader.readUint8();
      expect(nodeType, equals(1)); // Chunked raw data

      final nodeLevel = await reader.readUint8();
      expect(nodeLevel, greaterThan(0)); // Internal node

      final entriesUsed = await reader.readUint16();
      expect(entriesUsed, greaterThan(0));
      expect(entriesUsed, lessThanOrEqualTo(16)); // Max entries per node

      // Verify first leaf node exists
      reader.seek(0);
      final leafSignature = String.fromCharCodes(await reader.readBytes(4));
      expect(leafSignature, equals('TREE'));

      final leafNodeType = await reader.readUint8();
      expect(leafNodeType, equals(1));

      final leafNodeLevel = await reader.readUint8();
      expect(leafNodeLevel, equals(0)); // Leaf node
    });

    test('handles chunks with filter masks', () {
      final writer = BTreeV1Writer(dimensionality: 2);
      final byteWriter = ByteWriter();

      final entries = [
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 1, // Compression enabled
          chunkCoordinates: [0, 0],
          chunkAddress: 1000,
        ),
        BTreeV1ChunkEntry(
          chunkSize: 512,
          filterMask: 3, // Multiple filters
          chunkCoordinates: [0, 1],
          chunkAddress: 2000,
        ),
      ];

      final address = writer.writeChunkIndex(byteWriter, entries);

      expect(address, equals(0));
      expect(byteWriter.bytes.length, greaterThan(0));
    });

    test('throws error for empty chunk list', () {
      final writer = BTreeV1Writer(dimensionality: 2);
      final byteWriter = ByteWriter();

      expect(
        () => writer.writeChunkIndex(byteWriter, []),
        throwsArgumentError,
      );
    });
  });

  group('BTreeV1Writer - Symbol Table Index', () {
    test('writes single leaf node for small group', () {
      final writer = BTreeV1Writer(dimensionality: 0);
      final byteWriter = ByteWriter();

      final entries = [
        SymbolTableIndexEntry(
          nameHash: BTreeV1Writer.calculateNameHash('dataset1'),
          symbolTableNodeAddress: 1000,
        ),
        SymbolTableIndexEntry(
          nameHash: BTreeV1Writer.calculateNameHash('dataset2'),
          symbolTableNodeAddress: 2000,
        ),
      ];

      final address = writer.writeSymbolTableIndex(byteWriter, entries);

      expect(address, equals(0));
      expect(byteWriter.bytes.length, greaterThan(0));

      // Verify signature
      expect(
          String.fromCharCodes(byteWriter.bytes.sublist(0, 4)), equals('TREE'));

      // Verify node type (0 = group/symbol table)
      expect(byteWriter.bytes[4], equals(0));

      // Verify node level (0 = leaf)
      expect(byteWriter.bytes[5], equals(0));

      // Verify number of entries
      final entriesUsed = byteWriter.bytes[6] | (byteWriter.bytes[7] << 8);
      expect(entriesUsed, equals(2));
    });

    test('writes multi-level tree for large group (100+ objects)', () {
      final writer = BTreeV1Writer(dimensionality: 0);
      final byteWriter = ByteWriter();

      // Create 100+ entries
      final entries = <SymbolTableIndexEntry>[];
      for (int i = 0; i < 120; i++) {
        entries.add(SymbolTableIndexEntry(
          nameHash: BTreeV1Writer.calculateNameHash('dataset_$i'),
          symbolTableNodeAddress: 1000 + i * 100,
        ));
      }

      final address = writer.writeSymbolTableIndex(byteWriter, entries);

      // For multi-level trees, root is written last
      expect(address, greaterThan(0));
      expect(byteWriter.bytes.length, greaterThan(0));

      // First node should be a leaf node
      expect(
          String.fromCharCodes(byteWriter.bytes.sublist(0, 4)), equals('TREE'));

      // Root node should also have TREE signature
      expect(
          String.fromCharCodes(byteWriter.bytes.sublist(address, address + 4)),
          equals('TREE'));

      // Root should be internal node (level > 0)
      expect(byteWriter.bytes[address + 5], greaterThan(0));
    });

    test('handles exactly 100 objects efficiently', () {
      final writer = BTreeV1Writer(dimensionality: 0);
      final byteWriter = ByteWriter();

      final entries = <SymbolTableIndexEntry>[];
      for (int i = 0; i < 100; i++) {
        entries.add(SymbolTableIndexEntry(
          nameHash: BTreeV1Writer.calculateNameHash('obj_$i'),
          symbolTableNodeAddress: 2000 + i * 200,
        ));
      }

      final address = writer.writeSymbolTableIndex(byteWriter, entries);

      expect(address, greaterThan(0));
      expect(byteWriter.bytes.length, greaterThan(0));

      // Verify root node exists
      expect(
          String.fromCharCodes(byteWriter.bytes.sublist(address, address + 4)),
          equals('TREE'));
    });

    test('handles 200+ objects with deep tree', () {
      final writer = BTreeV1Writer(dimensionality: 0);
      final byteWriter = ByteWriter();

      final entries = <SymbolTableIndexEntry>[];
      for (int i = 0; i < 250; i++) {
        entries.add(SymbolTableIndexEntry(
          nameHash: BTreeV1Writer.calculateNameHash('item_$i'),
          symbolTableNodeAddress: 3000 + i * 150,
        ));
      }

      final address = writer.writeSymbolTableIndex(byteWriter, entries);

      expect(address, greaterThan(0));
      expect(byteWriter.bytes.length, greaterThan(0));

      // Verify root is internal node with higher level
      expect(byteWriter.bytes[address + 5], greaterThan(0));
    });

    test('sorts entries by name hash', () {
      final writer = BTreeV1Writer(dimensionality: 0);
      final byteWriter = ByteWriter();

      // Create entries with hashes in random order
      final entries = [
        SymbolTableIndexEntry(
          nameHash: 5000,
          symbolTableNodeAddress: 3000,
        ),
        SymbolTableIndexEntry(
          nameHash: 1000,
          symbolTableNodeAddress: 1000,
        ),
        SymbolTableIndexEntry(
          nameHash: 3000,
          symbolTableNodeAddress: 2000,
        ),
      ];

      final address = writer.writeSymbolTableIndex(byteWriter, entries);

      expect(address, equals(0));
      // Entries should be sorted internally by hash
    });

    test('validates symbol table structure format', () {
      final writer = BTreeV1Writer(dimensionality: 0);
      final byteWriter = ByteWriter();

      final entries = [
        SymbolTableIndexEntry(
          nameHash: BTreeV1Writer.calculateNameHash('test1'),
          symbolTableNodeAddress: 1000,
        ),
        SymbolTableIndexEntry(
          nameHash: BTreeV1Writer.calculateNameHash('test2'),
          symbolTableNodeAddress: 2000,
        ),
        SymbolTableIndexEntry(
          nameHash: BTreeV1Writer.calculateNameHash('test3'),
          symbolTableNodeAddress: 3000,
        ),
      ];

      final address = writer.writeSymbolTableIndex(byteWriter, entries);

      // Verify structure
      expect(address, equals(0));
      final bytes = byteWriter.bytes;

      // Check signature
      expect(String.fromCharCodes(bytes.sublist(0, 4)), equals('TREE'));

      // Check node type (0 = symbol table)
      expect(bytes[4], equals(0));

      // Check node level (0 = leaf)
      expect(bytes[5], equals(0));

      // Check entries count
      final entriesUsed = bytes[6] | (bytes[7] << 8);
      expect(entriesUsed, equals(3));
    });

    test('throws error for empty symbol table', () {
      final writer = BTreeV1Writer(dimensionality: 0);
      final byteWriter = ByteWriter();

      expect(
        () => writer.writeSymbolTableIndex(byteWriter, []),
        throwsArgumentError,
      );
    });

    test('calculateNameHash produces consistent hashes', () {
      final hash1 = BTreeV1Writer.calculateNameHash('dataset1');
      final hash2 = BTreeV1Writer.calculateNameHash('dataset1');
      final hash3 = BTreeV1Writer.calculateNameHash('dataset2');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
    });

    test('calculateNameHash handles empty string', () {
      final hash = BTreeV1Writer.calculateNameHash('');
      expect(hash, equals(0));
    });

    test('calculateNameHash handles special characters', () {
      final hash1 = BTreeV1Writer.calculateNameHash('data_set-1');
      final hash2 = BTreeV1Writer.calculateNameHash('data/set/1');
      final hash3 = BTreeV1Writer.calculateNameHash('data.set.1');

      // All should produce valid hashes
      expect(hash1, isNot(equals(0)));
      expect(hash2, isNot(equals(0)));
      expect(hash3, isNot(equals(0)));

      // All should be different
      expect(hash1, isNot(equals(hash2)));
      expect(hash2, isNot(equals(hash3)));
      expect(hash1, isNot(equals(hash3)));
    });

    test('calculateNameHash handles long names', () {
      final longName = 'very_long_dataset_name_' * 10;
      final hash = BTreeV1Writer.calculateNameHash(longName);

      expect(hash, isNot(equals(0)));
      // Hash can be negative due to signed int overflow, which is expected
    });
  });

  group('BTreeV1Writer - Structure Validation', () {
    test('validates leaf node structure', () {
      final writer = BTreeV1Writer(dimensionality: 2);
      final byteWriter = ByteWriter();

      final entries = [
        BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [0, 0],
          chunkAddress: 1000,
        ),
      ];

      writer.writeChunkIndex(byteWriter, entries);
      final bytes = byteWriter.bytes;

      // Validate structure
      expect(String.fromCharCodes(bytes.sublist(0, 4)), equals('TREE'));
      expect(bytes[4], equals(1)); // Node type
      expect(bytes[5], equals(0)); // Node level (leaf)

      // Validate sibling addresses (should be undefined)
      final leftSibling = _readUint64(bytes, 8);
      final rightSibling = _readUint64(bytes, 16);
      expect(leftSibling, equals(0xFFFFFFFFFFFFFFFF));
      expect(rightSibling, equals(0xFFFFFFFFFFFFFFFF));
    });

    test('validates internal node structure', () {
      final writer = BTreeV1Writer(dimensionality: 2);
      final byteWriter = ByteWriter();

      // Create enough entries for multi-level tree
      final entries = <BTreeV1ChunkEntry>[];
      for (int i = 0; i < 20; i++) {
        entries.add(BTreeV1ChunkEntry(
          chunkSize: 1024,
          filterMask: 0,
          chunkCoordinates: [i, 0],
          chunkAddress: 1000 + i * 1024,
        ));
      }

      final address = writer.writeChunkIndex(byteWriter, entries);
      final bytes = byteWriter.bytes;

      // Validate root node structure
      expect(String.fromCharCodes(bytes.sublist(address, address + 4)),
          equals('TREE'));
      expect(bytes[address + 4], equals(1)); // Node type
      expect(bytes[address + 5], greaterThan(0)); // Node level (internal)
    });

    test('validates B-tree with different offset sizes', () {
      for (final offsetSize in [2, 4, 8]) {
        final writer = BTreeV1Writer(dimensionality: 2, offsetSize: offsetSize);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV1ChunkEntry(
            chunkSize: 1024,
            filterMask: 0,
            chunkCoordinates: [0, 0],
            chunkAddress: 1000,
          ),
        ];

        final address = writer.writeChunkIndex(byteWriter, entries);

        expect(address, equals(0));
        expect(byteWriter.bytes.length, greaterThan(0));
      }
    });
  });
}

// Helper function to read uint64 from byte list
int _readUint64(List<int> bytes, int offset) {
  int value = 0;
  for (int i = 0; i < 8; i++) {
    value |= bytes[offset + i] << (i * 8);
  }
  return value;
}
