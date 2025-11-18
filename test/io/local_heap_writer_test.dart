import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('LocalHeapWriter', () {
    group('Basic allocation', () {
      test('allocate returns offset 0 for first allocation', () {
        final writer = LocalHeapWriter();

        final offset = writer.allocate([1, 2, 3]);

        expect(offset, equals(0));
      });

      test('allocate adds null terminator by default', () {
        final writer = LocalHeapWriter();

        writer.allocate([1, 2, 3]);

        // Size should be 4 (3 bytes + 1 null terminator)
        expect(writer.dataSegmentSize, equals(4));
      });

      test('allocate without null terminator', () {
        final writer = LocalHeapWriter();

        writer.allocate([1, 2, 3], addNullTerminator: false);

        expect(writer.dataSegmentSize, equals(3));
      });

      test('allocate returns sequential offsets', () {
        final writer = LocalHeapWriter();

        final offset1 = writer.allocate([1, 2, 3]); // 4 bytes with null
        final offset2 = writer.allocate([4, 5]); // 3 bytes with null

        expect(offset1, equals(0));
        expect(offset2, equals(4));
      });

      test('allocate handles string data', () {
        final writer = LocalHeapWriter();

        final nameData = utf8.encode('dataset_name');
        final offset = writer.allocate(nameData);

        expect(offset, equals(0));
        expect(writer.allocationCount, equals(1));
      });

      test('allocate handles empty data', () {
        final writer = LocalHeapWriter();

        final offset = writer.allocate([]);

        expect(offset, equals(0));
        expect(writer.dataSegmentSize, equals(1)); // Just null terminator
      });
    });

    group('Free space management', () {
      test('free marks space as available', () {
        final writer = LocalHeapWriter();

        final offset = writer.allocate([1, 2, 3, 4, 5]);
        writer.free(offset);

        expect(writer.totalFreeSpace, equals(6)); // 5 bytes + null terminator
      });

      test('allocate reuses freed space', () {
        final writer = LocalHeapWriter();

        final offset1 = writer.allocate([1, 2, 3, 4, 5]); // 6 bytes
        writer.free(offset1);

        final offset2 = writer.allocate([6, 7, 8]); // 4 bytes

        expect(offset2, equals(0)); // Reuses the freed space
        expect(writer.totalFreeSpace, equals(2)); // 6 - 4 = 2 bytes remaining
      });

      test('adjacent free blocks are merged', () {
        final writer = LocalHeapWriter();

        final offset1 = writer.allocate([1, 2, 3]); // 4 bytes
        final offset2 = writer.allocate([4, 5, 6]); // 4 bytes
        writer.allocate([7, 8, 9]); // 4 bytes

        writer.free(offset1);
        writer.free(offset2);

        // Should merge into single 8-byte block
        expect(writer.totalFreeSpace, equals(8));
      });
    });

    group('Heap writing', () {
      test('write creates valid header', () {
        final writer = LocalHeapWriter();
        writer.allocate([1, 2, 3]);

        final bytes = writer.write(1024);

        // Check signature "HEAP"
        expect(bytes[0], equals(0x48)); // 'H'
        expect(bytes[1], equals(0x45)); // 'E'
        expect(bytes[2], equals(0x41)); // 'A'
        expect(bytes[3], equals(0x50)); // 'P'

        // Check version (0)
        expect(bytes[4], equals(0));
      });

      test('write includes data segment size', () {
        final writer = LocalHeapWriter();
        writer.allocate([1, 2, 3]); // 4 bytes with null terminator

        final bytes = writer.write(1024);

        // Data segment size is at offset 8 (8 bytes, little-endian)
        final buffer = ByteData.view(Uint8List.fromList(bytes).buffer);
        final dataSegmentSize = buffer.getUint64(8, Endian.little);

        expect(dataSegmentSize, equals(4));
      });

      test('write includes data segment address', () {
        final writer = LocalHeapWriter();
        writer.allocate([1, 2, 3]);

        final address = 1024;
        final bytes = writer.write(address);

        // Data segment address is at offset 24 (8 bytes, little-endian)
        // Header structure: signature(4) + version(1) + reserved(3) + size(8) + freelist(8) + address(8)
        final buffer = ByteData.view(Uint8List.fromList(bytes).buffer);
        final dataSegmentAddress = buffer.getUint64(24, Endian.little);

        expect(
            dataSegmentAddress, equals(address + 32)); // After 32-byte header
      });

      test('write includes allocated data', () {
        final writer = LocalHeapWriter();
        final data = [1, 2, 3];
        writer.allocate(data);

        final bytes = writer.write(1024);

        // Data starts at offset 32 (after header)
        expect(bytes[32], equals(1));
        expect(bytes[33], equals(2));
        expect(bytes[34], equals(3));
        expect(bytes[35], equals(0)); // Null terminator
      });

      test('write with multiple allocations', () {
        final writer = LocalHeapWriter();
        writer.allocate([1, 2, 3]);
        writer.allocate([4, 5]);

        final bytes = writer.write(1024);

        // First allocation at offset 32
        expect(bytes[32], equals(1));
        expect(bytes[33], equals(2));
        expect(bytes[34], equals(3));
        expect(bytes[35], equals(0)); // Null terminator

        // Second allocation at offset 36
        expect(bytes[36], equals(4));
        expect(bytes[37], equals(5));
        expect(bytes[38], equals(0)); // Null terminator
      });

      test('write with string data', () {
        final writer = LocalHeapWriter();
        final name = 'dataset_name';
        writer.allocate(utf8.encode(name));

        final bytes = writer.write(1024);

        // Extract string from data segment (starts at offset 32)
        final dataStart = 32;
        final stringBytes = <int>[];
        for (int i = dataStart; i < bytes.length && bytes[i] != 0; i++) {
          stringBytes.add(bytes[i]);
        }

        expect(utf8.decode(stringBytes), equals(name));
      });
    });

    group('Multiple blocks', () {
      test('needsMultipleBlocks returns false for small heap', () {
        final writer = LocalHeapWriter(maxBlockSize: 1024);
        writer.allocate(List<int>.filled(100, 42));

        expect(writer.needsMultipleBlocks, isFalse);
      });

      test('needsMultipleBlocks returns true for large heap', () {
        final writer = LocalHeapWriter(maxBlockSize: 1024);
        writer.allocate(List<int>.filled(2000, 42));

        expect(writer.needsMultipleBlocks, isTrue);
      });

      test('blockCount calculates correctly', () {
        final writer = LocalHeapWriter(maxBlockSize: 1000);
        writer.allocate(List<int>.filled(2500, 42));

        expect(writer.blockCount, equals(3)); // 2500 / 1000 = 3 blocks
      });

      test('writeMultipleBlocks creates correct number of blocks', () {
        final writer = LocalHeapWriter(maxBlockSize: 1000);
        writer.allocate(List<int>.filled(2500, 42));

        final blocks = writer.writeMultipleBlocks(1024);

        expect(blocks.length, equals(3));
      });

      test('writeMultipleBlocks creates valid headers for each block', () {
        final writer = LocalHeapWriter(maxBlockSize: 1000);
        writer.allocate(List<int>.filled(2500, 42));

        final blocks = writer.writeMultipleBlocks(1024);

        for (final block in blocks) {
          // Check signature "HEAP"
          expect(block[0], equals(0x48)); // 'H'
          expect(block[1], equals(0x45)); // 'E'
          expect(block[2], equals(0x41)); // 'A'
          expect(block[3], equals(0x50)); // 'P'

          // Check version (0)
          expect(block[4], equals(0));
        }
      });
    });

    group('Utility methods', () {
      test('clear resets writer state', () {
        final writer = LocalHeapWriter();
        writer.allocate([1, 2, 3]);
        writer.allocate([4, 5, 6]);

        writer.clear();

        expect(writer.dataSegmentSize, equals(0));
        expect(writer.allocationCount, equals(0));
        expect(writer.totalFreeSpace, equals(0));
      });

      test('toString provides useful information', () {
        final writer = LocalHeapWriter();
        writer.allocate([1, 2, 3]);

        final str = writer.toString();
        expect(str, contains('LocalHeapWriter'));
        expect(str, contains('size='));
        expect(str, contains('allocations='));
      });
    });
  });
}
