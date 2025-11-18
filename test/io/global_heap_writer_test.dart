import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/global_heap.dart';

void main() {
  group('GlobalHeapWriter', () {
    group('Object allocation and ID generation', () {
      test('allocate returns sequential IDs starting from 1', () {
        final writer = GlobalHeapWriter();

        final id1 = writer.allocate([1, 2, 3]);
        final id2 = writer.allocate([4, 5, 6]);
        final id3 = writer.allocate([7, 8, 9]);

        expect(id1, 1);
        expect(id2, 2);
        expect(id3, 3);
      });

      test('allocate stores data correctly', () {
        final writer = GlobalHeapWriter();
        final data = utf8.encode('Hello, World!');

        final id = writer.allocate(data);

        expect(id, 1);
        expect(writer.objectCount, 1);
      });

      test('allocate handles empty data', () {
        final writer = GlobalHeapWriter();

        final id = writer.allocate([]);

        expect(id, 1);
        expect(writer.objectCount, 1);
      });

      test('allocate handles large data', () {
        final writer = GlobalHeapWriter();
        final largeData = List<int>.filled(10000, 42);

        final id = writer.allocate(largeData);

        expect(id, 1);
        expect(writer.objectCount, 1);
      });

      test('multiple allocations increment object count', () {
        final writer = GlobalHeapWriter();

        writer.allocate([1, 2, 3]);
        expect(writer.objectCount, 1);

        writer.allocate([4, 5, 6]);
        expect(writer.objectCount, 2);

        writer.allocate([7, 8, 9]);
        expect(writer.objectCount, 3);
      });

      test('totalDataSize calculates correctly', () {
        final writer = GlobalHeapWriter();

        writer.allocate([1, 2, 3]); // 3 bytes
        writer.allocate([4, 5, 6, 7]); // 4 bytes
        writer.allocate([8, 9]); // 2 bytes

        expect(writer.totalDataSize, 9);
      });

      test('clear resets writer state', () {
        final writer = GlobalHeapWriter();

        writer.allocate([1, 2, 3]);
        writer.allocate([4, 5, 6]);
        expect(writer.objectCount, 2);

        writer.clear();

        expect(writer.objectCount, 0);
        expect(writer.totalDataSize, 0);

        // Next allocation should start from ID 1 again
        final id = writer.allocate([7, 8, 9]);
        expect(id, 1);
      });
    });

    group('Collection writing with multiple objects', () {
      test('writeCollection creates valid header', () {
        final writer = GlobalHeapWriter();
        writer.allocate([1, 2, 3]);

        final bytes = writer.writeCollection(1024);

        // Check signature "GCOL"
        expect(bytes[0], 0x47); // 'G'
        expect(bytes[1], 0x43); // 'C'
        expect(bytes[2], 0x4F); // 'O'
        expect(bytes[3], 0x4C); // 'L'

        // Check version (should be 1)
        expect(bytes[4], 1);

        // Check reserved bytes (should be 0)
        expect(bytes[5], 0);
        expect(bytes[6], 0);
        expect(bytes[7], 0);
      });

      test('writeCollection includes collection size', () {
        final writer = GlobalHeapWriter();
        writer.allocate([1, 2, 3]);

        final bytes = writer.writeCollection(1024);
        final expectedSize = writer.calculateCollectionSize();

        // Collection size is at bytes 8-15 (8 bytes, little-endian)
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes), 8, 16);
        final collectionSize = buffer.getUint64(0, Endian.little);

        expect(collectionSize, expectedSize);
      });

      test('writeCollection writes single object correctly', () {
        final writer = GlobalHeapWriter();
        final data = [1, 2, 3, 4, 5];
        final id = writer.allocate(data);

        final bytes = writer.writeCollection(1024);

        // Object starts at byte 16 (after header)
        final objectStart = 16;

        // Check heap object index (2 bytes)
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes));
        final objectIndex = buffer.getUint16(objectStart, Endian.little);
        expect(objectIndex, id);

        // Check reference count (2 bytes at offset 2)
        final refCount = buffer.getUint16(objectStart + 2, Endian.little);
        expect(refCount, 1);

        // Check object size (8 bytes at offset 8)
        final objectSize = buffer.getUint64(objectStart + 8, Endian.little);
        expect(objectSize, data.length);

        // Check object data (starts at offset 16)
        final objectData =
            bytes.sublist(objectStart + 16, objectStart + 16 + data.length);
        expect(objectData, equals(data));
      });

      test('writeCollection writes multiple objects correctly', () {
        final writer = GlobalHeapWriter();
        final data1 = [1, 2, 3];
        final data2 = [4, 5, 6, 7];
        final data3 = [8, 9];

        final id1 = writer.allocate(data1);
        final id2 = writer.allocate(data2);
        final id3 = writer.allocate(data3);

        final bytes = writer.writeCollection(1024);
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes));

        // First object at byte 16
        int pos = 16;
        expect(buffer.getUint16(pos, Endian.little), id1);
        expect(buffer.getUint64(pos + 8, Endian.little), data1.length);
        expect(bytes.sublist(pos + 16, pos + 16 + data1.length), equals(data1));

        // Calculate next object position (aligned to 8 bytes)
        final obj1Size = 16 + data1.length;
        final obj1Aligned = (obj1Size + 7) & ~7;
        pos += obj1Aligned;

        // Second object
        expect(buffer.getUint16(pos, Endian.little), id2);
        expect(buffer.getUint64(pos + 8, Endian.little), data2.length);
        expect(bytes.sublist(pos + 16, pos + 16 + data2.length), equals(data2));

        // Calculate next object position
        final obj2Size = 16 + data2.length;
        final obj2Aligned = (obj2Size + 7) & ~7;
        pos += obj2Aligned;

        // Third object
        expect(buffer.getUint16(pos, Endian.little), id3);
        expect(buffer.getUint64(pos + 8, Endian.little), data3.length);
        expect(bytes.sublist(pos + 16, pos + 16 + data3.length), equals(data3));
      });

      test('writeCollection includes end marker', () {
        final writer = GlobalHeapWriter();
        writer.allocate([1, 2, 3]);

        final bytes = writer.writeCollection(1024);

        // Find end marker (should be near the end)
        // End marker: index=0, refcount=0, reserved=0, size=0
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes));

        // Calculate position of end marker
        // Header (16) + Object1 (16 + 3 = 19, aligned to 24) = 40
        final endMarkerPos = 40;

        expect(buffer.getUint16(endMarkerPos, Endian.little), 0); // index
        expect(
            buffer.getUint16(endMarkerPos + 2, Endian.little), 0); // refcount
        expect(
            buffer.getUint32(endMarkerPos + 4, Endian.little), 0); // reserved
        expect(buffer.getUint64(endMarkerPos + 8, Endian.little), 0); // size
      });

      test('writeCollection aligns objects to 8-byte boundaries', () {
        final writer = GlobalHeapWriter();
        writer.allocate([1, 2, 3]); // 3 bytes data
        writer.allocate([4, 5]); // 2 bytes data

        final bytes = writer.writeCollection(1024);

        // First object: 16 (header) + 3 (data) = 19 bytes
        // Aligned to 8: 24 bytes
        // Second object should start at position 16 + 24 = 40
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes));
        final secondObjectIndex = buffer.getUint16(40, Endian.little);
        expect(secondObjectIndex, 2);
      });

      test('writeCollection with string data', () {
        final writer = GlobalHeapWriter();
        final stringData = utf8.encode('Variable-length string');
        final id = writer.allocate(stringData);

        final bytes = writer.writeCollection(2048);
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes));

        // Check object at position 16
        expect(buffer.getUint16(16, Endian.little), id);
        expect(buffer.getUint64(24, Endian.little), stringData.length);

        final objectData = bytes.sublist(32, 32 + stringData.length);
        expect(utf8.decode(objectData), 'Variable-length string');
      });

      test('calculateCollectionSize returns correct size', () {
        final writer = GlobalHeapWriter();
        writer.allocate([1, 2, 3]); // 3 bytes
        writer.allocate([4, 5, 6, 7]); // 4 bytes

        final calculatedSize = writer.calculateCollectionSize();

        // Header: 16 bytes
        // Object 1: 16 (header) + 3 (data) = 19, aligned to 24
        // Object 2: 16 (header) + 4 (data) = 20, aligned to 24
        // End marker: 16 bytes
        // Total: 16 + 24 + 24 + 16 = 80 bytes
        expect(calculatedSize, 80);

        // Verify by writing
        final bytes = writer.writeCollection(1024);
        expect(bytes.length, calculatedSize);
      });

      test('writeCollection with big-endian', () {
        final writer = GlobalHeapWriter(endian: Endian.big);
        writer.allocate([1, 2, 3]);

        final bytes = writer.writeCollection(1024);

        // Signature should still be ASCII "GCOL"
        expect(bytes[0], 0x47);
        expect(bytes[1], 0x43);
        expect(bytes[2], 0x4F);
        expect(bytes[3], 0x4C);

        // Collection size should be in big-endian
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes), 8, 16);
        final collectionSize = buffer.getUint64(0, Endian.big);
        expect(collectionSize, greaterThan(0));
      });
    });

    group('Heap ID encoding and decoding (createReference)', () {
      test('createReference creates 16-byte reference', () {
        final writer = GlobalHeapWriter();
        final data = utf8.encode('Test data');
        final objectId = writer.allocate(data);
        final heapAddress = 2048;

        final reference = writer.createReference(objectId, heapAddress);

        expect(reference.length, 16);
      });

      test('createReference encodes data length correctly', () {
        final writer = GlobalHeapWriter();
        final data = [1, 2, 3, 4, 5];
        final objectId = writer.allocate(data);
        final heapAddress = 1024;

        final reference = writer.createReference(objectId, heapAddress);
        final buffer = ByteData.sublistView(Uint8List.fromList(reference));

        // Length is first 4 bytes
        final length = buffer.getUint32(0, Endian.little);
        expect(length, data.length);
      });

      test('createReference encodes heap address correctly', () {
        final writer = GlobalHeapWriter();
        final objectId = writer.allocate([1, 2, 3]);
        final heapAddress = 0x12345678;

        final reference = writer.createReference(objectId, heapAddress);
        final buffer = ByteData.sublistView(Uint8List.fromList(reference));

        // Heap address is bytes 4-11 (as two 32-bit values)
        final heapAddrLow = buffer.getUint32(4, Endian.little);
        final heapAddrHigh = buffer.getUint32(8, Endian.little);
        final reconstructedAddress = heapAddrLow | (heapAddrHigh << 32);

        expect(reconstructedAddress, heapAddress);
      });

      test('createReference encodes object ID correctly', () {
        final writer = GlobalHeapWriter();
        final data = [1, 2, 3];
        final objectId = writer.allocate(data);
        final heapAddress = 2048;

        final reference = writer.createReference(objectId, heapAddress);
        final buffer = ByteData.sublistView(Uint8List.fromList(reference));

        // Object ID is last 4 bytes
        final encodedObjectId = buffer.getUint32(12, Endian.little);
        expect(encodedObjectId, objectId);
      });

      test('createReference handles large heap addresses', () {
        final writer = GlobalHeapWriter();
        final objectId = writer.allocate([1, 2, 3]);
        final heapAddress = 0x123456789ABC; // > 32-bit

        final reference = writer.createReference(objectId, heapAddress);
        final buffer = ByteData.sublistView(Uint8List.fromList(reference));

        final heapAddrLow = buffer.getUint32(4, Endian.little);
        final heapAddrHigh = buffer.getUint32(8, Endian.little);
        final reconstructedAddress = heapAddrLow | (heapAddrHigh << 32);

        expect(reconstructedAddress, heapAddress);
      });

      test('createReference throws for invalid object ID', () {
        final writer = GlobalHeapWriter();
        writer.allocate([1, 2, 3]);

        expect(
          () => writer.createReference(999, 1024),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('createReference with multiple objects', () {
        final writer = GlobalHeapWriter();
        final data1 = utf8.encode('First');
        final data2 = utf8.encode('Second');
        final data3 = utf8.encode('Third');

        final id1 = writer.allocate(data1);
        final id2 = writer.allocate(data2);
        final id3 = writer.allocate(data3);

        final heapAddress = 4096;

        final ref1 = writer.createReference(id1, heapAddress);
        final ref2 = writer.createReference(id2, heapAddress);
        final ref3 = writer.createReference(id3, heapAddress);

        // All references should point to same heap address
        final buffer1 = ByteData.sublistView(Uint8List.fromList(ref1));
        final buffer2 = ByteData.sublistView(Uint8List.fromList(ref2));
        final buffer3 = ByteData.sublistView(Uint8List.fromList(ref3));

        final addr1 = buffer1.getUint32(4, Endian.little);
        final addr2 = buffer2.getUint32(4, Endian.little);
        final addr3 = buffer3.getUint32(4, Endian.little);

        expect(addr1, addr2);
        expect(addr2, addr3);

        // But different object IDs
        expect(buffer1.getUint32(12, Endian.little), id1);
        expect(buffer2.getUint32(12, Endian.little), id2);
        expect(buffer3.getUint32(12, Endian.little), id3);
      });

      test('createReference with big-endian', () {
        final writer = GlobalHeapWriter(endian: Endian.big);
        final data = [1, 2, 3, 4, 5];
        final objectId = writer.allocate(data);
        final heapAddress = 2048;

        final reference = writer.createReference(objectId, heapAddress);
        final buffer = ByteData.sublistView(Uint8List.fromList(reference));

        // Values should be in big-endian
        final length = buffer.getUint32(0, Endian.big);
        expect(length, data.length);

        final heapAddrLow = buffer.getUint32(4, Endian.big);
        final objectIdDecoded = buffer.getUint32(12, Endian.big);
        expect(objectIdDecoded, objectId);
      });

      test('VlenReference.fromBytes decodes reference correctly', () {
        final writer = GlobalHeapWriter();
        final data = [1, 2, 3, 4, 5];
        final objectId = writer.allocate(data);
        final heapAddress = 2048;

        final reference = writer.createReference(objectId, heapAddress);

        // Decode using VlenReference
        final vlenRef = VlenReference.fromBytes(reference);

        expect(vlenRef.length, data.length);
        expect(vlenRef.heapAddress, heapAddress);
        expect(vlenRef.objectIndex, objectId);
      });
    });

    group('Edge cases and integration', () {
      test('empty writer produces minimal collection', () {
        final writer = GlobalHeapWriter();

        final bytes = writer.writeCollection(1024);

        // Should have header (16 bytes) + end marker (16 bytes) = 32 bytes
        expect(bytes.length, 32);
        expect(writer.calculateCollectionSize(), 32);
      });

      test('writer with many small objects', () {
        final writer = GlobalHeapWriter();

        for (int i = 0; i < 100; i++) {
          writer.allocate([i]);
        }

        expect(writer.objectCount, 100);

        final bytes = writer.writeCollection(8192);
        expect(bytes.length, greaterThan(0));

        // Verify signature
        expect(bytes[0], 0x47);
        expect(bytes[1], 0x43);
        expect(bytes[2], 0x4F);
        expect(bytes[3], 0x4C);
      });

      test('writer toString provides useful information', () {
        final writer = GlobalHeapWriter();
        writer.allocate([1, 2, 3]);
        writer.allocate([4, 5, 6, 7]);

        final str = writer.toString();
        expect(str, contains('2')); // object count
        expect(str, contains('GlobalHeapWriter'));
      });

      test('consecutive write operations produce same result', () {
        final writer = GlobalHeapWriter();
        writer.allocate([1, 2, 3]);
        writer.allocate([4, 5, 6]);

        final bytes1 = writer.writeCollection(1024);
        final bytes2 = writer.writeCollection(1024);

        expect(bytes1, equals(bytes2));
      });

      test('writer handles zero-length data', () {
        final writer = GlobalHeapWriter();
        final id = writer.allocate([]);

        final bytes = writer.writeCollection(1024);
        final buffer = ByteData.sublistView(Uint8List.fromList(bytes));

        // Object at position 16
        expect(buffer.getUint16(16, Endian.little), id);
        expect(buffer.getUint64(24, Endian.little), 0); // size = 0
      });
    });
  });
}
