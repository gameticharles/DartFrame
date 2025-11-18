import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/btree_v2_writer.dart';
import 'package:dartframe/src/io/hdf5/btree_v2.dart';
import 'package:dartframe/src/io/hdf5/byte_writer.dart';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() {
  group('BTreeV2Writer', () {
    group('Header writing', () {
      test('writeChunkIndex creates valid header signature', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);

        final bytes = byteWriter.bytes;
        // Header should be at the end after nodes
        expect(bytes[headerAddress], 0x42); // 'B'
        expect(bytes[headerAddress + 1], 0x54); // 'T'
        expect(bytes[headerAddress + 2], 0x48); // 'H'
        expect(bytes[headerAddress + 3], 0x44); // 'D'
      });

      test('writeChunkIndex sets correct version', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Version should be 0
        expect(bytes[headerAddress + 4], 0);
      });

      test('writeChunkIndex sets type to 1 for chunked dataset', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Type should be 1 (chunked dataset index)
        expect(bytes[headerAddress + 5], 1);
      });

      test('writeChunkIndex includes node size', () async {
        final writer = BTreeV2Writer(dimensionality: 2, nodeSize: 8192);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Node size at offset 6 (4 bytes, little-endian)
        final buffer =
            ByteData.sublistView(Uint8List.fromList(bytes), headerAddress + 6);
        final nodeSize = buffer.getUint32(0, Endian.little);
        expect(nodeSize, 8192);
      });

      test('writeChunkIndex includes record size', () async {
        final writer = BTreeV2Writer(dimensionality: 3);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0, 0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Record size at offset 10 (2 bytes)
        final buffer =
            ByteData.sublistView(Uint8List.fromList(bytes), headerAddress + 10);
        final recordSize = buffer.getUint16(0, Endian.little);
        // Record size = 8 + (8 * dim) + offsetSize = 8 + 24 + 8 = 40
        expect(recordSize, 40);
      });

      test('writeChunkIndex includes depth', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        // Single entry should create depth 0 (leaf only)
        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Depth at offset 12 (2 bytes)
        final buffer =
            ByteData.sublistView(Uint8List.fromList(bytes), headerAddress + 12);
        final depth = buffer.getUint16(0, Endian.little);
        expect(depth, 0);
      });

      test('writeChunkIndex includes total record count', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
              chunkCoordinates: [0, 0], chunkAddress: 1024, chunkSize: 512),
          BTreeV2ChunkEntry(
              chunkCoordinates: [0, 1], chunkAddress: 2048, chunkSize: 512),
          BTreeV2ChunkEntry(
              chunkCoordinates: [1, 0], chunkAddress: 3072, chunkSize: 512),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Total records at offset 26 (8 bytes)
        // Offset: signature(4) + version(1) + type(1) + nodeSize(4) + recordSize(2) +
        //         depth(2) + split%(1) + merge%(1) + rootAddr(8) + numRecords(2) = 26
        final buffer =
            ByteData.sublistView(Uint8List.fromList(bytes), headerAddress + 26);
        final totalRecords = buffer.getUint64(0, Endian.little);
        expect(totalRecords, 3);
      });
    });

    group('Node structure for various record counts', () {
      test('single entry creates leaf node only', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Should have leaf node signature "BTLF"
        expect(bytes[0], 0x42); // 'B'
        expect(bytes[1], 0x54); // 'T'
        expect(bytes[2], 0x4C); // 'L'
        expect(bytes[3], 0x46); // 'F'
      });

      test('multiple entries within node capacity create single leaf',
          () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
              chunkCoordinates: [0, 0], chunkAddress: 1024, chunkSize: 512),
          BTreeV2ChunkEntry(
              chunkCoordinates: [0, 1], chunkAddress: 2048, chunkSize: 512),
          BTreeV2ChunkEntry(
              chunkCoordinates: [1, 0], chunkAddress: 3072, chunkSize: 512),
        ];

        await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Should still be a single leaf node
        expect(bytes[0], 0x42); // 'B'
        expect(bytes[1], 0x54); // 'T'
        expect(bytes[2], 0x4C); // 'L'
        expect(bytes[3], 0x46); // 'F'
      });

      test('entries exceeding node capacity create internal nodes', () async {
        final writer = BTreeV2Writer(dimensionality: 2, nodeSize: 512);
        final byteWriter = ByteWriter();

        // Create enough entries to exceed single node capacity
        final entries = <BTreeV2ChunkEntry>[];
        for (int i = 0; i < 50; i++) {
          entries.add(BTreeV2ChunkEntry(
            chunkCoordinates: [i, 0],
            chunkAddress: 1024 + (i * 512),
            chunkSize: 512,
          ));
        }

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Should have internal node at root
        // Depth should be > 0
        final buffer =
            ByteData.sublistView(Uint8List.fromList(bytes), headerAddress + 12);
        final depth = buffer.getUint16(0, Endian.little);
        expect(depth, greaterThan(0));
      });

      test('leaf node contains correct record data', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [5, 10],
            chunkAddress: 2048,
            chunkSize: 1024,
            filterMask: 1,
          ),
        ];

        await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Skip signature (4) + version (1) + type (1) = 6 bytes
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes), 6);

        // Chunk size (4 bytes)
        final chunkSize = buffer.getUint32(0, Endian.little);
        expect(chunkSize, 1024);

        // Filter mask (4 bytes)
        final filterMask = buffer.getUint32(4, Endian.little);
        expect(filterMask, 1);

        // Coordinates (8 bytes each)
        final coord0 = buffer.getUint64(8, Endian.little);
        final coord1 = buffer.getUint64(16, Endian.little);
        expect(coord0, 5);
        expect(coord1, 10);

        // Chunk address (8 bytes)
        final chunkAddress = buffer.getUint64(24, Endian.little);
        expect(chunkAddress, 2048);
      });

      test('entries are sorted by coordinates', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        // Add entries in non-sorted order
        final entries = [
          BTreeV2ChunkEntry(
              chunkCoordinates: [2, 0], chunkAddress: 3072, chunkSize: 512),
          BTreeV2ChunkEntry(
              chunkCoordinates: [0, 0], chunkAddress: 1024, chunkSize: 512),
          BTreeV2ChunkEntry(
              chunkCoordinates: [1, 0], chunkAddress: 2048, chunkSize: 512),
        ];

        await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Read first record coordinates (after signature + version + type)
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes), 6);

        // Skip chunk size (4) + filter mask (4) = 8 bytes
        final firstCoord0 = buffer.getUint64(8, Endian.little);
        expect(firstCoord0, 0); // Should be sorted to [0,0] first
      });
    });

    group('Checksum calculation', () {
      test('leaf node includes checksum', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Checksum should be at end of node (last 4 bytes before header)
        // Node size is 4096 by default
        final checksumOffset = 4096 - 4;
        final buffer =
            ByteData.sublistView(Uint8List.fromList(bytes), checksumOffset);
        final checksum = buffer.getUint32(0, Endian.little);

        // Checksum should be non-zero
        expect(checksum, isNot(0));
      });

      test('header includes checksum', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Header checksum is at the end of header
        // Header size: signature(4) + version(1) + type(1) + nodeSize(4) +
        //              recordSize(2) + depth(2) + split%(1) + merge%(1) +
        //              rootAddr(8) + numRecords(2) + totalRecords(8) = 34 bytes
        // Checksum at offset 34
        final buffer =
            ByteData.sublistView(Uint8List.fromList(bytes), headerAddress + 34);
        final checksum = buffer.getUint32(0, Endian.little);

        // Checksum should be non-zero
        expect(checksum, isNot(0));
      });

      test('internal node includes checksum', () async {
        final writer = BTreeV2Writer(dimensionality: 2, nodeSize: 512);
        final byteWriter = ByteWriter();

        // Create enough entries to force internal nodes
        final entries = <BTreeV2ChunkEntry>[];
        for (int i = 0; i < 50; i++) {
          entries.add(BTreeV2ChunkEntry(
            chunkCoordinates: [i, 0],
            chunkAddress: 1024 + (i * 512),
            chunkSize: 512,
          ));
        }

        await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Find internal node (should be after leaf nodes)
        // Look for "BTIN" signature
        bool foundInternalNode = false;
        for (int i = 0; i < bytes.length - 4; i++) {
          if (bytes[i] == 0x42 &&
              bytes[i + 1] == 0x54 &&
              bytes[i + 2] == 0x49 &&
              bytes[i + 3] == 0x4E) {
            foundInternalNode = true;

            // Checksum at end of node
            final checksumOffset = i + 512 - 4;
            final buffer =
                ByteData.sublistView(Uint8List.fromList(bytes), checksumOffset);
            final checksum = buffer.getUint32(0, Endian.little);
            expect(checksum, isNot(0));
            break;
          }
        }

        expect(foundInternalNode, isTrue);
      });
    });

    group('Tree can be read by existing B-tree v2 reader', () {
      test('reader can parse written header', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Create reader from written bytes
        final byteReader = ByteReader.fromBytes(Uint8List.fromList(bytes));
        final btree = await BTreeV2.read(byteReader, headerAddress);

        expect(btree.version, 0);
        expect(btree.type, 1);
        expect(btree.depth, 0);
        expect(btree.totalNumRecords, 1);
      });

      test('reader can parse tree with multiple entries', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
              chunkCoordinates: [0, 0], chunkAddress: 1024, chunkSize: 512),
          BTreeV2ChunkEntry(
              chunkCoordinates: [0, 1], chunkAddress: 2048, chunkSize: 512),
          BTreeV2ChunkEntry(
              chunkCoordinates: [1, 0], chunkAddress: 3072, chunkSize: 512),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        final byteReader = ByteReader.fromBytes(Uint8List.fromList(bytes));
        final btree = await BTreeV2.read(byteReader, headerAddress);

        expect(btree.totalNumRecords, 3);
        expect(btree.numRecordsInRoot, 3);
      });

      test('reader can parse tree with internal nodes', () async {
        final writer = BTreeV2Writer(dimensionality: 2, nodeSize: 512);
        final byteWriter = ByteWriter();

        final entries = <BTreeV2ChunkEntry>[];
        for (int i = 0; i < 50; i++) {
          entries.add(BTreeV2ChunkEntry(
            chunkCoordinates: [i, 0],
            chunkAddress: 1024 + (i * 512),
            chunkSize: 512,
          ));
        }

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        final byteReader = ByteReader.fromBytes(Uint8List.fromList(bytes));
        final btree = await BTreeV2.read(byteReader, headerAddress);

        expect(btree.totalNumRecords, 50);
        expect(btree.depth, greaterThan(0));
      });

      test('round-trip: write and read preserves data', () async {
        final writer = BTreeV2Writer(dimensionality: 3);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [1, 2, 3],
            chunkAddress: 4096,
            chunkSize: 2048,
            filterMask: 5,
          ),
          BTreeV2ChunkEntry(
            chunkCoordinates: [4, 5, 6],
            chunkAddress: 8192,
            chunkSize: 2048,
            filterMask: 0,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        final byteReader = ByteReader.fromBytes(Uint8List.fromList(bytes));
        final btree = await BTreeV2.read(byteReader, headerAddress);

        expect(btree.version, 0);
        expect(btree.type, 1);
        expect(btree.nodeSize, 4096);
        expect(btree.totalNumRecords, 2);
        expect(btree.depth, 0);
      });
    });

    group('Edge cases and validation', () {
      test('throws on empty entry list', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        expect(
          () => writer.writeChunkIndex(byteWriter, []),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles single entry correctly', () async {
        final writer = BTreeV2Writer(dimensionality: 1);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        expect(headerAddress, greaterThan(0));
      });

      test('handles high dimensionality', () async {
        final writer = BTreeV2Writer(dimensionality: 5);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 1, 2, 3, 4],
            chunkAddress: 1024,
            chunkSize: 512,
          ),
        ];

        final headerAddress = await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        final byteReader = ByteReader.fromBytes(Uint8List.fromList(bytes));
        final btree = await BTreeV2.read(byteReader, headerAddress);

        expect(btree.totalNumRecords, 1);
      });

      test('handles large chunk addresses', () async {
        final writer = BTreeV2Writer(dimensionality: 2);
        final byteWriter = ByteWriter();

        final entries = [
          BTreeV2ChunkEntry(
            chunkCoordinates: [0, 0],
            chunkAddress: 0x123456789ABC,
            chunkSize: 512,
          ),
        ];

        await writer.writeChunkIndex(byteWriter, entries);
        final bytes = byteWriter.bytes;

        // Verify address is written correctly (after header fields)
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes), 6);
        final chunkAddress = buffer.getUint64(24, Endian.little);
        expect(chunkAddress, 0x123456789ABC);
      });

      test('maxRecordsPerNode calculation is reasonable', () {
        final writer = BTreeV2Writer(dimensionality: 2, nodeSize: 4096);

        expect(writer.maxRecordsPerNode, greaterThan(0));
        expect(writer.maxRecordsPerNode, lessThan(1000));
      });

      test('recordSize calculation matches dimensionality', () {
        final writer2d = BTreeV2Writer(dimensionality: 2);
        final writer3d = BTreeV2Writer(dimensionality: 3);

        // Record size = 8 + (8 * dim) + offsetSize
        expect(writer2d.recordSize, 8 + (8 * 2) + 8);
        expect(writer3d.recordSize, 8 + (8 * 3) + 8);
        expect(writer3d.recordSize, greaterThan(writer2d.recordSize));
      });

      test('BTreeV2ChunkEntry compareTo works correctly', () {
        final entry1 = BTreeV2ChunkEntry(
          chunkCoordinates: [0, 0],
          chunkAddress: 1024,
          chunkSize: 512,
        );
        final entry2 = BTreeV2ChunkEntry(
          chunkCoordinates: [0, 1],
          chunkAddress: 2048,
          chunkSize: 512,
        );
        final entry3 = BTreeV2ChunkEntry(
          chunkCoordinates: [1, 0],
          chunkAddress: 3072,
          chunkSize: 512,
        );

        expect(entry1.compareTo(entry2), lessThan(0));
        expect(entry2.compareTo(entry1), greaterThan(0));
        expect(entry1.compareTo(entry3), lessThan(0));
        expect(entry3.compareTo(entry2), greaterThan(0));
      });
    });
  });
}
