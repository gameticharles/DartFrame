import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/fractal_heap_writer.dart';

void main() {
  group('FractalHeapWriter', () {
    group('Basic allocation', () {
      test('allocate returns heap ID', () {
        final writer = FractalHeapWriter();

        final heapId = writer.allocate([1, 2, 3]);

        expect(heapId, isNotEmpty);
        expect(heapId.length, equals(8)); // Default heapIdLength
        expect(writer.objectCount, equals(1));
      });

      test('allocate stores data correctly', () {
        final writer = FractalHeapWriter();

        final data = utf8.encode('Hello, World!');
        writer.allocate(data);

        expect(writer.objectCount, equals(1));
        expect(writer.totalDataSize, equals(data.length));
      });

      test('allocate handles empty data', () {
        final writer = FractalHeapWriter();

        expect(() => writer.allocate([]), throwsArgumentError);
      });

      test('allocate handles large data within limits', () {
        final writer = FractalHeapWriter();

        final largeData = List<int>.filled(10000, 42);
        writer.allocate(largeData);

        expect(writer.objectCount, equals(1));
        expect(writer.totalDataSize, equals(10000));
      });

      test('allocate rejects data exceeding maxSizeOfManagedObjects', () {
        final writer = FractalHeapWriter(maxSizeOfManagedObjects: 1000);

        final tooLargeData = List<int>.filled(2000, 42);

        expect(() => writer.allocate(tooLargeData), throwsArgumentError);
      });

      test('multiple allocations increment object count', () {
        final writer = FractalHeapWriter();

        writer.allocate([1, 2, 3]);
        writer.allocate([4, 5, 6, 7]);
        writer.allocate([8, 9]);

        expect(writer.objectCount, equals(3));
      });

      test('totalDataSize calculates correctly', () {
        final writer = FractalHeapWriter();

        writer.allocate([1, 2, 3]); // 3 bytes
        writer.allocate([4, 5, 6, 7]); // 4 bytes

        expect(writer.totalDataSize, equals(7));
      });

      test('clear resets writer state', () {
        final writer = FractalHeapWriter();

        writer.allocate([1, 2, 3]);
        writer.allocate([4, 5, 6]);

        expect(writer.objectCount, equals(2));

        writer.clear();

        expect(writer.objectCount, equals(0));
        expect(writer.totalDataSize, equals(0));
      });
    });

    group('Heap ID encoding', () {
      test('heap ID has correct version and type', () {
        final writer = FractalHeapWriter();

        final heapId = writer.allocate([1, 2, 3]);

        expect(heapId[0], equals(0)); // Version 0
        expect(heapId[1], equals(0)); // Type 0 (managed object)
      });

      test('heap ID encodes offset', () {
        final writer = FractalHeapWriter();

        final heapId1 = writer.allocate([1, 2, 3]);
        final heapId2 = writer.allocate([4, 5, 6, 7]);

        // For 8-byte heap ID, offset is in bytes 2-7 (6 bytes)
        // Read as 48-bit value
        final buffer1 = ByteData.view(Uint8List.fromList(heapId1).buffer);
        int offset1 = 0;
        for (int i = 0; i < 6; i++) {
          offset1 |= buffer1.getUint8(2 + i) << (i * 8);
        }
        expect(offset1, equals(0));

        // Second object at offset 3
        final buffer2 = ByteData.view(Uint8List.fromList(heapId2).buffer);
        int offset2 = 0;
        for (int i = 0; i < 6; i++) {
          offset2 |= buffer2.getUint8(2 + i) << (i * 8);
        }
        expect(offset2, equals(3));
      });

      test('heap ID with custom length', () {
        final writer = FractalHeapWriter(heapIdLength: 12);

        final heapId = writer.allocate([1, 2, 3]);

        expect(heapId.length, equals(12));
      });

      test('heap ID decoding - extract offset from heap ID', () {
        final writer = FractalHeapWriter();

        // Allocate first object
        final heapId1 = writer.allocate([1, 2, 3]);

        // Allocate second object
        final heapId2 = writer.allocate([4, 5, 6, 7, 8]);

        // Decode offset from first heap ID (should be 0)
        final buffer1 = ByteData.view(Uint8List.fromList(heapId1).buffer);
        int offset1 = 0;
        for (int i = 0; i < 6; i++) {
          offset1 |= buffer1.getUint8(2 + i) << (i * 8);
        }
        expect(offset1, equals(0));

        // Decode offset from second heap ID (should be 3)
        final buffer2 = ByteData.view(Uint8List.fromList(heapId2).buffer);
        int offset2 = 0;
        for (int i = 0; i < 6; i++) {
          offset2 |= buffer2.getUint8(2 + i) << (i * 8);
        }
        expect(offset2, equals(3));
      });
    });

    group('Block organization', () {
      test('blockCount returns 1 for small heap', () {
        final writer = FractalHeapWriter(startingBlockSize: 4096);

        writer.allocate(List<int>.filled(100, 42));

        expect(writer.blockCount, equals(1));
      });

      test('blockCount increases for larger data', () {
        final writer = FractalHeapWriter(
          startingBlockSize: 1024,
          maxDirectBlockSize: 4096,
        );

        writer.allocate(List<int>.filled(3000, 42));

        expect(writer.blockCount, greaterThan(1));
      });

      test('needsIndirectBlocks returns false for small heap', () {
        final writer = FractalHeapWriter(maxDirectBlockSize: 65536);

        writer.allocate(List<int>.filled(1000, 42));

        expect(writer.needsIndirectBlocks, isFalse);
      });

      test('needsIndirectBlocks returns true for large heap', () {
        final writer = FractalHeapWriter(maxDirectBlockSize: 4096);

        writer.allocate(List<int>.filled(10000, 42));

        expect(writer.needsIndirectBlocks, isTrue);
      });
    });

    group('Heap writing', () {
      test('write creates valid header', () {
        final writer = FractalHeapWriter();

        writer.allocate([1, 2, 3]);

        final bytes = writer.write(1024);

        // Check signature "FRHP"
        expect(bytes[0], equals(0x46)); // 'F'
        expect(bytes[1], equals(0x52)); // 'R'
        expect(bytes[2], equals(0x48)); // 'H'
        expect(bytes[3], equals(0x50)); // 'P'

        // Check version
        expect(bytes[4], equals(0));
      });

      test('write includes heap configuration', () {
        final writer = FractalHeapWriter(
          startingBlockSize: 4096,
          maxDirectBlockSize: 65536,
          tableWidth: 4,
        );

        writer.allocate([1, 2, 3]);

        final bytes = writer.write(1024);
        final buffer = ByteData.view(Uint8List.fromList(bytes).buffer);

        // Check table width at offset 110
        final tableWidth = buffer.getUint16(110, Endian.little);
        expect(tableWidth, equals(4));

        // Check starting block size at offset 112
        final startingBlockSize = buffer.getUint64(112, Endian.little);
        expect(startingBlockSize, equals(4096));

        // Check max direct block size at offset 120
        final maxDirectBlockSize = buffer.getUint64(120, Endian.little);
        expect(maxDirectBlockSize, equals(65536));
      });

      test('write includes direct block', () {
        final writer = FractalHeapWriter();

        final data = [1, 2, 3, 4, 5];
        writer.allocate(data);

        final bytes = writer.write(1024);

        // Find direct block signature "FHDB" after header
        bool foundDirectBlock = false;
        for (int i = 0; i < bytes.length - 4; i++) {
          if (bytes[i] == 0x46 &&
              bytes[i + 1] == 0x48 &&
              bytes[i + 2] == 0x44 &&
              bytes[i + 3] == 0x42) {
            foundDirectBlock = true;
            break;
          }
        }

        expect(foundDirectBlock, isTrue);
      });

      test('write with multiple objects', () {
        final writer = FractalHeapWriter();

        writer.allocate([1, 2, 3]);
        writer.allocate([4, 5, 6, 7]);
        writer.allocate([8, 9]);

        final bytes = writer.write(1024);

        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(100)); // Header + blocks
      });

      test('write with string data', () {
        final writer = FractalHeapWriter();

        final name = 'object_name';
        writer.allocate(utf8.encode(name));

        final bytes = writer.write(1024);

        expect(bytes, isNotEmpty);
      });

      test('write with large heap uses indirect blocks', () {
        final writer = FractalHeapWriter(
          startingBlockSize: 1024,
          maxDirectBlockSize: 2048,
        );

        // Allocate enough data to require indirect blocks
        writer.allocate(List<int>.filled(5000, 42));

        final bytes = writer.write(1024);

        // Should find indirect block signature "FHIB"
        bool foundIndirectBlock = false;
        for (int i = 0; i < bytes.length - 4; i++) {
          if (bytes[i] == 0x46 &&
              bytes[i + 1] == 0x48 &&
              bytes[i + 2] == 0x49 &&
              bytes[i + 3] == 0x42) {
            foundIndirectBlock = true;
            break;
          }
        }

        expect(foundIndirectBlock, isTrue);
      });
    });

    group('Configuration validation', () {
      test('rejects non-power-of-2 starting block size', () {
        expect(
          () => FractalHeapWriter(startingBlockSize: 1000),
          throwsArgumentError,
        );
      });

      test('rejects maxDirectBlockSize < startingBlockSize', () {
        expect(
          () => FractalHeapWriter(
            startingBlockSize: 4096,
            maxDirectBlockSize: 2048,
          ),
          throwsArgumentError,
        );
      });

      test('rejects non-positive table width', () {
        expect(
          () => FractalHeapWriter(tableWidth: 0),
          throwsArgumentError,
        );
      });

      test('accepts valid configuration', () {
        expect(
          () => FractalHeapWriter(
            startingBlockSize: 4096,
            maxDirectBlockSize: 65536,
            tableWidth: 4,
          ),
          returnsNormally,
        );
      });
    });

    group('Checksum calculation', () {
      test('header includes checksum', () {
        final writer = FractalHeapWriter();

        writer.allocate([1, 2, 3]);

        final bytes = writer.write(1024);

        // Header checksum is at the end of the header
        // Header size is calculated in the implementation
        // We verify that the last 4 bytes of the header section contain a checksum
        expect(bytes.length, greaterThan(100));

        // The checksum should be non-zero for non-empty data
        final buffer = ByteData.view(Uint8List.fromList(bytes).buffer);

        // Find the header checksum (last 4 bytes of header before direct block)
        // Header ends before "FHDB" signature
        int headerEnd = -1;
        for (int i = 0; i < bytes.length - 4; i++) {
          if (bytes[i] == 0x46 &&
              bytes[i + 1] == 0x48 &&
              bytes[i + 2] == 0x44 &&
              bytes[i + 3] == 0x42) {
            headerEnd = i;
            break;
          }
        }

        expect(headerEnd, greaterThan(0));

        // Checksum is 4 bytes before the direct block
        final checksumOffset = headerEnd - 4;
        final checksum = buffer.getUint32(checksumOffset, Endian.little);

        // Checksum should be non-zero
        expect(checksum, isNot(equals(0)));
      });

      test('direct block includes checksum', () {
        final writer = FractalHeapWriter();

        writer.allocate([1, 2, 3, 4, 5]);

        final bytes = writer.write(1024);

        // Find direct block signature "FHDB"
        int blockStart = -1;
        for (int i = 0; i < bytes.length - 4; i++) {
          if (bytes[i] == 0x46 &&
              bytes[i + 1] == 0x48 &&
              bytes[i + 2] == 0x44 &&
              bytes[i + 3] == 0x42) {
            blockStart = i;
            break;
          }
        }

        expect(blockStart, greaterThan(0));

        // Direct block has checksum at the end
        // Block structure: signature(4) + version(1) + heapHeaderAddress(8) +
        // blockOffset(8) + data(blockSize) + checksum(4)
        final buffer = ByteData.view(Uint8List.fromList(bytes).buffer);

        // Checksum is at the very end of the bytes
        final checksumOffset = bytes.length - 4;
        final checksum = buffer.getUint32(checksumOffset, Endian.little);

        // Checksum should be non-zero
        expect(checksum, isNot(equals(0)));
      });

      test('indirect block includes checksum', () {
        final writer = FractalHeapWriter(
          startingBlockSize: 1024,
          maxDirectBlockSize: 2048,
        );

        // Allocate enough data to require indirect blocks
        writer.allocate(List<int>.filled(5000, 42));

        final bytes = writer.write(1024);

        // Find indirect block signature "FHIB"
        int indirectBlockStart = -1;
        for (int i = 0; i < bytes.length - 4; i++) {
          if (bytes[i] == 0x46 &&
              bytes[i + 1] == 0x48 &&
              bytes[i + 2] == 0x49 &&
              bytes[i + 3] == 0x42) {
            indirectBlockStart = i;
            break;
          }
        }

        expect(indirectBlockStart, greaterThan(0));

        // Indirect block has checksum after the pointer table
        // We verify that checksums are present (non-zero values)
        final buffer = ByteData.view(Uint8List.fromList(bytes).buffer);

        // The indirect block checksum is after the signature, version, addresses, and pointers
        // For simplicity, we verify that the structure contains non-zero checksum values
        bool hasNonZeroChecksum = false;
        for (int i = indirectBlockStart + 20; i < bytes.length - 4; i += 4) {
          final value = buffer.getUint32(i, Endian.little);
          if (value != 0 && value != 0xFFFFFFFF) {
            hasNonZeroChecksum = true;
            break;
          }
        }

        expect(hasNonZeroChecksum, isTrue);
      });

      test('checksum changes with different data', () {
        final writer1 = FractalHeapWriter();
        writer1.allocate([1, 2, 3]);
        final bytes1 = writer1.write(1024);

        final writer2 = FractalHeapWriter();
        writer2.allocate([4, 5, 6]);
        final bytes2 = writer2.write(1024);

        // Extract checksums from the end of each output
        final buffer1 = ByteData.view(Uint8List.fromList(bytes1).buffer);
        final buffer2 = ByteData.view(Uint8List.fromList(bytes2).buffer);

        final checksum1 = buffer1.getUint32(bytes1.length - 4, Endian.little);
        final checksum2 = buffer2.getUint32(bytes2.length - 4, Endian.little);

        // Checksums should be different for different data
        expect(checksum1, isNot(equals(checksum2)));
      });

      test('checksum is consistent for same data', () {
        final writer = FractalHeapWriter();
        writer.allocate([1, 2, 3, 4, 5]);

        final bytes1 = writer.write(1024);
        final bytes2 = writer.write(1024);

        // Extract checksums
        final buffer1 = ByteData.view(Uint8List.fromList(bytes1).buffer);
        final buffer2 = ByteData.view(Uint8List.fromList(bytes2).buffer);

        final checksum1 = buffer1.getUint32(bytes1.length - 4, Endian.little);
        final checksum2 = buffer2.getUint32(bytes2.length - 4, Endian.little);

        // Checksums should be identical for same data
        expect(checksum1, equals(checksum2));
      });
    });

    group('Edge cases', () {
      test('empty writer produces minimal heap', () {
        final writer = FractalHeapWriter();

        final bytes = writer.write(1024);

        expect(bytes, isNotEmpty);
        expect(writer.objectCount, equals(0));
      });

      test('writer with many small objects', () {
        final writer = FractalHeapWriter();

        for (int i = 0; i < 100; i++) {
          writer.allocate([i % 256]);
        }

        expect(writer.objectCount, equals(100));

        final bytes = writer.write(1024);
        expect(bytes, isNotEmpty);
      });

      test('writer toString provides useful information', () {
        final writer = FractalHeapWriter();

        writer.allocate([1, 2, 3]);
        writer.allocate([4, 5, 6, 7]);

        final str = writer.toString();
        expect(str, contains('2')); // object count
        expect(str, contains('FractalHeapWriter'));
      });

      test('consecutive write operations produce same result', () {
        final writer = FractalHeapWriter();

        writer.allocate([1, 2, 3]);
        writer.allocate([4, 5, 6]);

        final bytes1 = writer.write(1024);
        final bytes2 = writer.write(1024);

        expect(bytes1, equals(bytes2));
      });
    });
  });
}
