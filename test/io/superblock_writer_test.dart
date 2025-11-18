import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/superblock.dart';
import 'package:dartframe/src/io/hdf5/byte_writer.dart';

void main() {
  group('Superblock.create', () {
    test('should create superblock with correct default values', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      expect(superblock.version, equals(0));
      expect(superblock.offsetSize, equals(8));
      expect(superblock.lengthSize, equals(8));
      expect(superblock.endian, equals(Endian.little));
      expect(superblock.groupLeafNodeK, equals(4));
      expect(superblock.groupInternalNodeK, equals(16));
      expect(superblock.fileConsistencyFlags, equals(0));
      expect(superblock.baseAddress, equals(0));
      expect(superblock.rootGroupObjectHeaderAddress, equals(96));
      expect(superblock.endOfFileAddress, equals(1024));
    });

    test('should set undefined addresses correctly', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      expect(superblock.superblockExtensionAddress,
          equals(Superblock.undefinedAddress));
      expect(
          superblock.freeSpaceInfoAddress, equals(Superblock.undefinedAddress));
      expect(superblock.driverInfoBlockAddress,
          equals(Superblock.undefinedAddress));
    });

    test('should accept different root group addresses', () {
      final superblock1 = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );
      final superblock2 = Superblock.create(
        rootGroupAddress: 512,
        endOfFileAddress: 2048,
      );

      expect(superblock1.rootGroupObjectHeaderAddress, equals(96));
      expect(superblock2.rootGroupObjectHeaderAddress, equals(512));
    });

    test('should accept different end of file addresses', () {
      final superblock1 = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );
      final superblock2 = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 8192,
      );

      expect(superblock1.endOfFileAddress, equals(1024));
      expect(superblock2.endOfFileAddress, equals(8192));
    });
  });

  group('Superblock.write', () {
    test('should write correct HDF5 signature', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // Verify HDF5 signature (first 8 bytes)
      final expectedSignature = [
        0x89,
        0x48,
        0x44,
        0x46,
        0x0D,
        0x0A,
        0x1A,
        0x0A
      ];
      for (int i = 0; i < expectedSignature.length; i++) {
        expect(bytes[i], equals(expectedSignature[i]),
            reason: 'Signature byte $i mismatch');
      }
    });

    test('should write correct version information', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // Version of superblock (byte 8)
      expect(bytes[8], equals(0));

      // Version of file free-space storage (byte 9)
      expect(bytes[9], equals(0));

      // Version of root group symbol table entry (byte 10)
      expect(bytes[10], equals(0));

      // Reserved (byte 11)
      expect(bytes[11], equals(0));

      // Version of shared header message format (byte 12)
      expect(bytes[12], equals(0));
    });

    test('should write correct offset and length sizes', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // Size of offsets (byte 13)
      expect(bytes[13], equals(8));

      // Size of lengths (byte 14)
      expect(bytes[14], equals(8));

      // Reserved (byte 15)
      expect(bytes[15], equals(0));
    });

    test('should write correct group K values', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // Group leaf node K (bytes 16-17)
      final leafK = ByteData.sublistView(Uint8List.fromList(bytes), 16, 18)
          .getUint16(0, Endian.little);
      expect(leafK, equals(4));

      // Group internal node K (bytes 18-19)
      final internalK = ByteData.sublistView(Uint8List.fromList(bytes), 18, 20)
          .getUint16(0, Endian.little);
      expect(internalK, equals(16));
    });

    test('should write correct file consistency flags', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // File consistency flags (bytes 20-23)
      final flags = ByteData.sublistView(Uint8List.fromList(bytes), 20, 24)
          .getUint32(0, Endian.little);
      expect(flags, equals(0));
    });

    test('should write correct base address', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // Base address (bytes 24-31)
      final baseAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 24, 32)
              .getUint64(0, Endian.little);
      expect(baseAddress, equals(0));
    });

    test('should write undefined address for free space info', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // Free space info address (bytes 32-39)
      final freeSpaceAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 32, 40)
              .getUint64(0, Endian.little);
      expect(freeSpaceAddress, equals(Superblock.undefinedAddress));
    });

    test('should write correct end of file address', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // End of file address (bytes 40-47)
      final eofAddress = ByteData.sublistView(Uint8List.fromList(bytes), 40, 48)
          .getUint64(0, Endian.little);
      expect(eofAddress, equals(1024));
    });

    test('should write undefined address for driver info block', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // Driver info block address (bytes 48-55)
      final driverInfoAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 48, 56)
              .getUint64(0, Endian.little);
      expect(driverInfoAddress, equals(Superblock.undefinedAddress));
    });

    test('should write correct root group symbol table entry', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // Link name offset (bytes 56-63)
      final linkNameOffset =
          ByteData.sublistView(Uint8List.fromList(bytes), 56, 64)
              .getUint64(0, Endian.little);
      expect(linkNameOffset, equals(0));

      // Object header address (bytes 64-71)
      final objectHeaderAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 64, 72)
              .getUint64(0, Endian.little);
      expect(objectHeaderAddress, equals(96));

      // Cache type (bytes 72-75)
      final cacheType = ByteData.sublistView(Uint8List.fromList(bytes), 72, 76)
          .getUint32(0, Endian.little);
      expect(cacheType, equals(0));

      // Reserved (bytes 76-79)
      final reserved = ByteData.sublistView(Uint8List.fromList(bytes), 76, 80)
          .getUint32(0, Endian.little);
      expect(reserved, equals(0));

      // Scratch pad space (bytes 80-95) - should all be zeros
      for (int i = 80; i < 96; i++) {
        expect(bytes[i], equals(0), reason: 'Scratch pad byte $i should be 0');
      }
    });

    test('should write exactly 96 bytes', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      expect(bytes.length, equals(96));
      expect(bytes.length, equals(Superblock.superblockSize));
    });

    test('should handle large addresses correctly', () {
      final superblock = Superblock.create(
        rootGroupAddress: 0x7FFFFFFFFFFFFFFF,
        endOfFileAddress: 0x7FFFFFFFFFFFFFFE,
      );

      final bytes = superblock.write();

      // Root group address (bytes 64-71)
      final rootGroupAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 64, 72)
              .getUint64(0, Endian.little);
      expect(rootGroupAddress, equals(0x7FFFFFFFFFFFFFFF));

      // EOF address (bytes 40-47)
      final eofAddress = ByteData.sublistView(Uint8List.fromList(bytes), 40, 48)
          .getUint64(0, Endian.little);
      expect(eofAddress, equals(0x7FFFFFFFFFFFFFFE));
    });
  });

  group('Superblock.writeTo', () {
    test('should write to existing ByteWriter', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final writer = ByteWriter();
      superblock.writeTo(writer);

      final bytes = writer.bytes;

      // Verify signature
      expect(bytes[0], equals(0x89));
      expect(bytes[1], equals(0x48));
      expect(bytes[2], equals(0x44));
      expect(bytes[3], equals(0x46));

      // Verify length
      expect(bytes.length, equals(96));
    });

    test('should append to ByteWriter with existing data', () {
      final writer = ByteWriter();

      // Write some data first
      writer.writeUint32(0x12345678);

      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      superblock.writeTo(writer);

      final bytes = writer.bytes;

      // Should have 4 bytes + 96 bytes = 100 bytes
      expect(bytes.length, equals(100));

      // First 4 bytes should be our initial data
      expect(bytes[0], equals(0x78));
      expect(bytes[1], equals(0x56));
      expect(bytes[2], equals(0x34));
      expect(bytes[3], equals(0x12));

      // Superblock should start at byte 4
      expect(bytes[4], equals(0x89)); // HDF5 signature
    });
  });

  group('Superblock.updateEndOfFileAddress', () {
    test('should update EOF address at correct position', () {
      final writer = ByteWriter();
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      superblock.writeTo(writer);

      // Update EOF address
      Superblock.updateEndOfFileAddress(writer, 2048);

      final bytes = writer.bytes;

      // Verify EOF address was updated (bytes 40-47)
      final eofAddress = ByteData.sublistView(Uint8List.fromList(bytes), 40, 48)
          .getUint64(0, Endian.little);
      expect(eofAddress, equals(2048));
    });

    test('should not affect other fields when updating EOF', () {
      final writer = ByteWriter();
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      superblock.writeTo(writer);

      // Store original bytes for comparison
      final originalBytes = List<int>.from(writer.bytes);

      // Update EOF address
      Superblock.updateEndOfFileAddress(writer, 4096);

      final bytes = writer.bytes;

      // Verify signature unchanged
      for (int i = 0; i < 8; i++) {
        expect(bytes[i], equals(originalBytes[i]),
            reason: 'Signature byte $i changed');
      }

      // Verify root group address unchanged (bytes 64-71)
      final rootGroupAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 64, 72)
              .getUint64(0, Endian.little);
      expect(rootGroupAddress, equals(96));

      // Verify EOF was updated
      final eofAddress = ByteData.sublistView(Uint8List.fromList(bytes), 40, 48)
          .getUint64(0, Endian.little);
      expect(eofAddress, equals(4096));
    });

    test('should handle large EOF addresses', () {
      final writer = ByteWriter();
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      superblock.writeTo(writer);

      // Update with large address
      Superblock.updateEndOfFileAddress(writer, 0x7FFFFFFFFFFFFFFF);

      final bytes = writer.bytes;

      final eofAddress = ByteData.sublistView(Uint8List.fromList(bytes), 40, 48)
          .getUint64(0, Endian.little);
      expect(eofAddress, equals(0x7FFFFFFFFFFFFFFF));
    });
  });

  group('Superblock.updateRootGroupAddress', () {
    test('should update root group address at correct position', () {
      final writer = ByteWriter();
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      superblock.writeTo(writer);

      // Update root group address
      Superblock.updateRootGroupAddress(writer, 512);

      final bytes = writer.bytes;

      // Verify root group address was updated (bytes 64-71)
      final rootGroupAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 64, 72)
              .getUint64(0, Endian.little);
      expect(rootGroupAddress, equals(512));
    });

    test('should not affect other fields when updating root group', () {
      final writer = ByteWriter();
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      superblock.writeTo(writer);

      // Store original bytes for comparison
      final originalBytes = List<int>.from(writer.bytes);

      // Update root group address
      Superblock.updateRootGroupAddress(writer, 256);

      final bytes = writer.bytes;

      // Verify signature unchanged
      for (int i = 0; i < 8; i++) {
        expect(bytes[i], equals(originalBytes[i]),
            reason: 'Signature byte $i changed');
      }

      // Verify EOF unchanged (bytes 40-47)
      final eofAddress = ByteData.sublistView(Uint8List.fromList(bytes), 40, 48)
          .getUint64(0, Endian.little);
      expect(eofAddress, equals(1024));

      // Verify root group was updated
      final rootGroupAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 64, 72)
              .getUint64(0, Endian.little);
      expect(rootGroupAddress, equals(256));
    });

    test('should handle large root group addresses', () {
      final writer = ByteWriter();
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      superblock.writeTo(writer);

      // Update with large address
      Superblock.updateRootGroupAddress(writer, 0x7FFFFFFFFFFFFFFF);

      final bytes = writer.bytes;

      final rootGroupAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 64, 72)
              .getUint64(0, Endian.little);
      expect(rootGroupAddress, equals(0x7FFFFFFFFFFFFFFF));
    });
  });

  group('Superblock Constants', () {
    test('should have correct signature', () {
      expect(Superblock.signature,
          equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
    });

    test('should have correct undefined address', () {
      expect(Superblock.undefinedAddress, equals(0xFFFFFFFFFFFFFFFF));
    });

    test('should have correct superblock size', () {
      expect(Superblock.superblockSize, equals(96));
    });
  });

  group('Superblock Integration', () {
    test('should create valid superblock for minimal HDF5 file', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      final bytes = superblock.write();

      // Verify it's a valid HDF5 superblock
      expect(bytes.length, equals(96));

      // Verify signature
      final signature = bytes.sublist(0, 8);
      expect(signature, equals(Superblock.signature));

      // Verify version 0
      expect(bytes[8], equals(0));

      // Verify addresses are reasonable
      final rootAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 64, 72)
              .getUint64(0, Endian.little);
      expect(rootAddress, equals(96));
      expect(rootAddress, greaterThanOrEqualTo(Superblock.superblockSize));
    });

    test('should support updating addresses after creation', () {
      final writer = ByteWriter();
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      superblock.writeTo(writer);

      // Simulate writing more data and updating addresses
      Superblock.updateRootGroupAddress(writer, 128);
      Superblock.updateEndOfFileAddress(writer, 2048);

      final bytes = writer.bytes;

      // Verify both updates
      final rootAddress =
          ByteData.sublistView(Uint8List.fromList(bytes), 64, 72)
              .getUint64(0, Endian.little);
      expect(rootAddress, equals(128));

      final eofAddress = ByteData.sublistView(Uint8List.fromList(bytes), 40, 48)
          .getUint64(0, Endian.little);
      expect(eofAddress, equals(2048));
    });

    test('should maintain consistency across write and writeTo', () {
      final superblock = Superblock.create(
        rootGroupAddress: 96,
        endOfFileAddress: 1024,
      );

      // Write using write()
      final bytes1 = superblock.write();

      // Write using writeTo()
      final writer = ByteWriter();
      superblock.writeTo(writer);
      final bytes2 = writer.bytes;

      // Both should produce identical output
      expect(bytes1, equals(bytes2));
    });
  });
}
