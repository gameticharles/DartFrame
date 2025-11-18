import 'dart:typed_data';
import 'byte_reader.dart';
import 'byte_writer.dart';
import 'hdf5_error.dart';

/// HDF5 file superblock containing file metadata
///
/// This class handles both reading and writing of HDF5 superblocks.
/// The superblock is the header structure at the beginning of an HDF5 file.
class Superblock {
  static const signature = [0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A];

  /// Undefined address marker
  static const undefinedAddress = 0xFFFFFFFFFFFFFFFF;

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

  // Version information
  final int freeSpaceVersion;
  final int rootGroupVersion;
  final int sharedHeaderVersion;

  // Additional addresses (version 0/1 only)
  final int? freeSpaceInfoAddress;
  final int? driverInfoBlockAddress;
  final int? rootGroupSymbolTableAddress;
  final int? rootGroupCacheType;

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
    required this.freeSpaceVersion,
    required this.rootGroupVersion,
    required this.sharedHeaderVersion,
    this.freeSpaceInfoAddress,
    this.driverInfoBlockAddress,
    this.rootGroupSymbolTableAddress,
    this.rootGroupCacheType,
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
          reader,
          offsetSize,
          lengthSize,
          version,
          validOffset,
          filePath,
          freeSpaceVersion,
          rootGroupVersion,
          sharedHeaderVersion);
    } else if (version == 2 || version == 3) {
      hdf5DebugLog('Reading superblock version $version');
      return await _readVersion2(
          reader,
          offsetSize,
          lengthSize,
          version,
          validOffset,
          filePath,
          freeSpaceVersion,
          rootGroupVersion,
          sharedHeaderVersion);
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
    int freeSpaceVersion,
    int rootGroupVersion,
    int sharedHeaderVersion,
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
      freeSpaceVersion: freeSpaceVersion,
      rootGroupVersion: rootGroupVersion,
      sharedHeaderVersion: sharedHeaderVersion,
      freeSpaceInfoAddress: freeSpaceInfoAddress,
      driverInfoBlockAddress: driverInfoBlockAddress,
      rootGroupSymbolTableAddress: rootGroupSymbolTableAddress,
      rootGroupCacheType: rootGroupCacheType,
    );
  }

  static Future<Superblock> _readVersion2(
    ByteReader reader,
    int offsetSize,
    int lengthSize,
    int version,
    int hdf5StartOffset,
    String? filePath,
    int freeSpaceVersion,
    int rootGroupVersion,
    int sharedHeaderVersion,
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
      freeSpaceVersion: freeSpaceVersion,
      rootGroupVersion: rootGroupVersion,
      sharedHeaderVersion: sharedHeaderVersion,
      // Version 2/3 doesn't have these fields
      freeSpaceInfoAddress: null,
      driverInfoBlockAddress: null,
      rootGroupSymbolTableAddress: null,
      rootGroupCacheType: null,
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

  /// Create a new version 0 superblock for writing
  ///
  /// This is a convenience constructor for creating superblocks for new HDF5 files.
  ///
  /// Parameters:
  /// - [rootGroupAddress]: Address of the root group object header
  /// - [endOfFileAddress]: Address marking the end of the file
  ///
  /// Example:
  /// ```dart
  /// final superblock = Superblock.create(
  ///   rootGroupAddress: 96,
  ///   endOfFileAddress: 1024,
  /// );
  /// final bytes = superblock.write();
  /// ```
  factory Superblock.create({
    required int rootGroupAddress,
    required int endOfFileAddress,
  }) {
    return Superblock(
      version: 0,
      offsetSize: 8,
      lengthSize: 8,
      endian: Endian.little,
      groupLeafNodeK: 4,
      groupInternalNodeK: 16,
      fileConsistencyFlags: 0,
      baseAddress: 0,
      superblockExtensionAddress: undefinedAddress,
      endOfFileAddress: endOfFileAddress,
      rootGroupObjectHeaderAddress: rootGroupAddress,
      hdf5StartOffset: 0,
      freeSpaceVersion: 0,
      rootGroupVersion: 0,
      sharedHeaderVersion: 0,
      freeSpaceInfoAddress: undefinedAddress,
      driverInfoBlockAddress: undefinedAddress,
      rootGroupSymbolTableAddress: 0,
      rootGroupCacheType: 0,
    );
  }

  /// Write this superblock as HDF5 bytes
  ///
  /// Returns the superblock bytes following HDF5 superblock format version 0.
  /// The superblock structure (version 0) is:
  /// - Signature (8 bytes)
  /// - Version info (8 bytes)
  /// - Offset and length sizes (2 bytes)
  /// - Group K values (4 bytes)
  /// - File consistency flags (4 bytes)
  /// - Base address (8 bytes)
  /// - Free space address (8 bytes)
  /// - EOF address (8 bytes)
  /// - Driver info address (8 bytes)
  /// - Root group symbol table entry (32 bytes)
  ///
  /// Total size: 96 bytes
  ///
  /// Examples:
  /// ```dart
  /// // Create and write a new superblock
  /// final superblock = Superblock.create(
  ///   rootGroupAddress: 96,
  ///   endOfFileAddress: 1024,
  /// );
  /// final bytes = superblock.write();
  ///
  /// // Write to a ByteWriter
  /// final writer = ByteWriter();
  /// superblock.writeTo(writer);
  /// ```
  List<int> write() {
    final writer = ByteWriter();
    writeTo(writer);
    return writer.bytes;
  }

  /// Write this superblock to a ByteWriter
  ///
  /// This method writes the superblock directly to an existing ByteWriter,
  /// useful when building a complete HDF5 file.
  ///
  /// Parameters:
  /// - [writer]: The ByteWriter to write to
  void writeTo(ByteWriter writer) {
    // Write HDF5 signature (8 bytes)
    writer.writeBytes(signature);

    // Version of superblock (1 byte)
    writer.writeUint8(version);

    // Version of file free-space storage (1 byte)
    writer.writeUint8(freeSpaceVersion);

    // Version of root group symbol table entry (1 byte)
    writer.writeUint8(rootGroupVersion);

    // Reserved (1 byte)
    writer.writeUint8(0);

    // Version of shared header message format (1 byte)
    writer.writeUint8(sharedHeaderVersion);

    // Size of offsets (1 byte)
    writer.writeUint8(offsetSize);

    // Size of lengths (1 byte)
    writer.writeUint8(lengthSize);

    // Reserved (1 byte)
    writer.writeUint8(0);

    // Group leaf node K (2 bytes)
    writer.writeUint16(groupLeafNodeK);

    // Group internal node K (2 bytes)
    writer.writeUint16(groupInternalNodeK);

    // File consistency flags (4 bytes)
    writer.writeUint32(fileConsistencyFlags);

    // Base address (8 bytes)
    writer.writeUint64(baseAddress);

    // Address of file free space info (8 bytes)
    writer.writeUint64(freeSpaceInfoAddress ?? undefinedAddress);

    // End of file address (8 bytes)
    writer.writeUint64(endOfFileAddress);

    // Driver information block address (8 bytes)
    writer.writeUint64(driverInfoBlockAddress ?? undefinedAddress);

    // Root group symbol table entry (32 bytes)
    _writeRootGroupSymbolTableEntry(writer);
  }

  /// Writes the root group symbol table entry
  void _writeRootGroupSymbolTableEntry(ByteWriter writer) {
    // Link name offset in local heap (8 bytes)
    writer.writeUint64(rootGroupSymbolTableAddress ?? 0);

    // Object header address (8 bytes)
    writer.writeUint64(rootGroupObjectHeaderAddress);

    // Cache type (4 bytes)
    writer.writeUint32(rootGroupCacheType ?? 0);

    // Reserved (4 bytes)
    writer.writeUint32(0);

    // Scratch pad space (16 bytes)
    for (int i = 0; i < 16; i++) {
      writer.writeUint8(0);
    }
  }

  /// Returns the fixed size of a version 0 superblock in bytes
  static int get superblockSize => 96;

  /// Update the end-of-file address in a ByteWriter
  ///
  /// This is useful when the file size is not known until after writing
  /// all data. The EOF address is located at offset 40 in the superblock.
  ///
  /// Parameters:
  /// - [writer]: The ByteWriter containing the superblock
  /// - [endOfFileAddress]: The new EOF address to write
  static void updateEndOfFileAddress(ByteWriter writer, int endOfFileAddress) {
    const eofOffset = 40; // Position of EOF address in superblock

    // Convert address to bytes (little-endian)
    final bytes = <int>[];
    for (int i = 0; i < 8; i++) {
      bytes.add((endOfFileAddress >> (i * 8)) & 0xFF);
    }

    // Write at the EOF address position
    writer.writeAt(eofOffset, bytes);
  }

  /// Update the root group address in a ByteWriter
  ///
  /// The root group address is part of the symbol table entry at offset 64.
  ///
  /// Parameters:
  /// - [writer]: The ByteWriter containing the superblock
  /// - [rootGroupAddress]: The new root group address to write
  static void updateRootGroupAddress(ByteWriter writer, int rootGroupAddress) {
    // Root group symbol table entry starts at offset 56
    // Link name offset is at offset 56-63 (8 bytes)
    // Object header address is at offset 64-71 (8 bytes)
    const rootGroupObjectHeaderOffset = 64;

    // Convert address to bytes (little-endian)
    final bytes = <int>[];
    for (int i = 0; i < 8; i++) {
      bytes.add((rootGroupAddress >> (i * 8)) & 0xFF);
    }

    // Write at the root group object header address position
    writer.writeAt(rootGroupObjectHeaderOffset, bytes);
  }
}
