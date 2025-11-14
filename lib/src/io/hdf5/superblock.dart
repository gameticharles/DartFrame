import 'dart:typed_data';
import 'byte_reader.dart';
import 'hdf5_error.dart';

/// HDF5 file superblock containing file metadata
class Superblock {
  static const signature = [0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A];

  final int version;
  final int offsetSize;
  final int lengthSize;
  final Endian endian;
  final int groupLeafNodeK;
  final int groupInternalNodeK;
  final int fileConsistencyFlags;
  final int baseAddress;
  final int superblockExtensionAddress;
  final int endOfFileAddress;
  final int rootGroupObjectHeaderAddress;
  final int
      hdf5StartOffset; // Offset where HDF5 data starts (e.g., 512 for MATLAB)

  Superblock({
    required this.version,
    required this.offsetSize,
    required this.lengthSize,
    required this.endian,
    required this.groupLeafNodeK,
    required this.groupInternalNodeK,
    required this.fileConsistencyFlags,
    required this.baseAddress,
    required this.superblockExtensionAddress,
    required this.endOfFileAddress,
    required this.rootGroupObjectHeaderAddress,
    required this.hdf5StartOffset,
  });

  static Future<Superblock> read(ByteReader reader, {String? filePath}) async {
    hdf5DebugLog(
        'Reading superblock from file${filePath != null ? ": $filePath" : ""}');

    // Try to find HDF5 signature at common offsets
    final offsets = [
      0,
      512,
      1024,
      2048
    ]; // Common offsets (0=standard, 512=MATLAB)

    int validOffset = -1;
    for (final offset in offsets) {
      hdf5DebugLog('Checking for HDF5 signature at offset $offset');
      reader.seek(offset);
      bool valid = true;

      for (var expectedByte in signature) {
        final byte = await reader.readUint8();
        if (byte != expectedByte) {
          valid = false;
          break;
        }
      }

      if (valid) {
        validOffset = offset;
        hdf5DebugLog('Found valid HDF5 signature at offset $offset');
        break;
      }
    }

    if (validOffset == -1) {
      throw InvalidHdf5SignatureError(
        filePath: filePath,
        details:
            'Signature not found at standard offsets: ${offsets.join(", ")}',
      );
    }

    // Position after signature
    reader.seek(validOffset + signature.length);

    // Read version information
    final version = await reader.readUint8();
    final freeSpaceVersion = await reader.readUint8();
    final rootGroupVersion = await reader.readUint8();
    await reader.readUint8(); // reserved

    final sharedHeaderVersion = await reader.readUint8();
    final offsetSize = await reader.readUint8();
    final lengthSize = await reader.readUint8();
    await reader.readUint8(); // reserved

    if (version == 0 || version == 1) {
      hdf5DebugLog('Reading superblock version $version');
      return await _readVersion0(
          reader, offsetSize, lengthSize, version, validOffset, filePath);
    } else if (version == 2 || version == 3) {
      hdf5DebugLog('Reading superblock version $version');
      return await _readVersion2(
          reader, offsetSize, lengthSize, version, validOffset, filePath);
    } else {
      throw UnsupportedVersionError(
        filePath: filePath,
        component: 'superblock',
        version: version,
      );
    }
  }

  static Future<Superblock> _readVersion0(
    ByteReader reader,
    int offsetSize,
    int lengthSize,
    int version,
    int hdf5StartOffset,
    String? filePath,
  ) async {
    final groupLeafNodeK = await reader.readUint16();
    final groupInternalNodeK = await reader.readUint16();
    final fileConsistencyFlags = await reader.readUint32();

    // Read addresses
    final baseAddress =
        await _readOffset(reader, offsetSize, filePath: filePath);
    final freeSpaceInfoAddress =
        await _readOffset(reader, offsetSize, filePath: filePath);
    final endOfFileAddress =
        await _readOffset(reader, offsetSize, filePath: filePath);
    final driverInfoBlockAddress =
        await _readOffset(reader, offsetSize, filePath: filePath);

    // Read root group symbol table entry
    final rootGroupSymbolTableAddress =
        await _readOffset(reader, offsetSize, filePath: filePath);
    final rootGroupObjectHeaderAddress =
        await _readOffset(reader, offsetSize, filePath: filePath);
    final rootGroupCacheType = await reader.readUint32();
    await reader.readBytes(4); // reserved

    // Skip scratch pad space (16 bytes)
    await reader.readBytes(16);

    return Superblock(
      version: version,
      offsetSize: offsetSize,
      lengthSize: lengthSize,
      endian: Endian.little,
      groupLeafNodeK: groupLeafNodeK,
      groupInternalNodeK: groupInternalNodeK,
      fileConsistencyFlags: fileConsistencyFlags,
      baseAddress: baseAddress,
      superblockExtensionAddress: freeSpaceInfoAddress,
      endOfFileAddress: endOfFileAddress,
      rootGroupObjectHeaderAddress: rootGroupObjectHeaderAddress,
      hdf5StartOffset: hdf5StartOffset,
    );
  }

  static Future<Superblock> _readVersion2(
    ByteReader reader,
    int offsetSize,
    int lengthSize,
    int version,
    int hdf5StartOffset,
    String? filePath,
  ) async {
    reader.seek(12);

    final groupLeafNodeK = await reader.readUint16();
    final groupInternalNodeK = await reader.readUint16();
    final fileConsistencyFlags = await reader.readUint32();

    // Skip indexed storage internal node K and reserved
    await reader.readUint16();
    await reader.readBytes(2);

    // Read addresses
    final baseAddress =
        await _readOffset(reader, offsetSize, filePath: filePath);
    final superblockExtensionAddress =
        await _readOffset(reader, offsetSize, filePath: filePath);
    final endOfFileAddress =
        await _readOffset(reader, offsetSize, filePath: filePath);
    final rootGroupObjectHeaderAddress =
        await _readOffset(reader, offsetSize, filePath: filePath);

    return Superblock(
      version: version,
      offsetSize: offsetSize,
      lengthSize: lengthSize,
      endian: Endian.little,
      groupLeafNodeK: groupLeafNodeK,
      groupInternalNodeK: groupInternalNodeK,
      fileConsistencyFlags: fileConsistencyFlags,
      baseAddress: baseAddress,
      superblockExtensionAddress: superblockExtensionAddress,
      endOfFileAddress: endOfFileAddress,
      rootGroupObjectHeaderAddress: rootGroupObjectHeaderAddress,
      hdf5StartOffset: hdf5StartOffset,
    );
  }

  static Future<int> _readOffset(ByteReader reader, int size,
      {String? filePath}) async {
    if (size == 2) return await reader.readUint16();
    if (size == 4) return await reader.readUint32();
    if (size == 8) return (await reader.readUint64()).toInt();
    throw InvalidMessageError(
      filePath: filePath,
      messageType: 'offset',
      reason: 'Invalid offset size: $size',
      details: 'Expected 2, 4, or 8 bytes',
    );
  }
}
