import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('ArrayDatatypeWriter', () {
    group('Basic functionality', () {
      test('creates 1D array writer', () {
        final writer = ArrayDatatypeWriter(
          baseType: NumericDatatypeWriter.float64(),
          dimensions: [10],
        );

        expect(writer.datatypeClass, Hdf5DatatypeClass.array);
        expect(writer.dimensions, [10]);
        expect(writer.totalElements, 10);
        expect(writer.getSize(), 80); // 10 * 8 bytes
      });

      test('creates 2D array writer', () {
        final writer = ArrayDatatypeWriter(
          baseType: NumericDatatypeWriter.int32(),
          dimensions: [3, 4],
        );

        expect(writer.dimensions, [3, 4]);
        expect(writer.totalElements, 12);
        expect(writer.getSize(), 48); // 12 * 4 bytes
      });

      test('creates 3D array writer', () {
        final writer = ArrayDatatypeWriter(
          baseType: NumericDatatypeWriter.uint8(),
          dimensions: [2, 3, 4],
        );

        expect(writer.dimensions, [2, 3, 4]);
        expect(writer.totalElements, 24);
        expect(writer.getSize(), 24); // 24 * 1 byte
      });

      test('rejects empty dimensions', () {
        expect(
          () => ArrayDatatypeWriter(
            baseType: NumericDatatypeWriter.float64(),
            dimensions: [],
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects zero or negative dimensions', () {
        expect(
          () => ArrayDatatypeWriter(
            baseType: NumericDatatypeWriter.float64(),
            dimensions: [0],
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => ArrayDatatypeWriter(
            baseType: NumericDatatypeWriter.float64(),
            dimensions: [-1],
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Message format verification', () {
      test('array message format matches HDF5 specification', () {
        final writer = ArrayDatatypeWriter(
          baseType: NumericDatatypeWriter.float64(),
          dimensions: [5],
        );

        final message = writer.writeMessage();

        expect(message, isNotEmpty);

        // Class and version byte: version 2, class 10 (array)
        expect(message[0], 0x2A);

        // Size field (bytes 4-7): 40 bytes (5 * 8)
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 40);

        // Dimensionality (byte 8): 1
        expect(message[8], 1);

        // Dimension size (bytes 12-15): 5
        final dim = ByteData.sublistView(Uint8List.fromList(message), 12, 16)
            .getUint32(0, Endian.little);
        expect(dim, 5);
      });

      test('2D array message contains correct dimensions', () {
        final writer = ArrayDatatypeWriter(
          baseType: NumericDatatypeWriter.int32(),
          dimensions: [3, 4],
        );

        final message = writer.writeMessage();

        // Dimensionality: 2
        expect(message[8], 2);

        // First dimension: 3
        final dim1 = ByteData.sublistView(Uint8List.fromList(message), 12, 16)
            .getUint32(0, Endian.little);
        expect(dim1, 3);

        // Second dimension: 4
        final dim2 = ByteData.sublistView(Uint8List.fromList(message), 16, 20)
            .getUint32(0, Endian.little);
        expect(dim2, 4);
      });
    });
  });

  group('VlenDatatypeWriter', () {
    group('Basic functionality', () {
      test('creates vlen sequence writer', () {
        final writer = VlenDatatypeWriter(
          baseType: NumericDatatypeWriter.int32(),
          vlenType: VlenType.sequence,
        );

        expect(writer.datatypeClass, Hdf5DatatypeClass.vlen);
        expect(writer.vlenType, VlenType.sequence);
        expect(writer.getSize(), 16); // Global heap reference
      });

      test('creates vlen string writer', () {
        final writer = VlenDatatypeWriter(
          baseType: StringDatatypeWriter.fixedLength(length: 1),
          vlenType: VlenType.string,
        );

        expect(writer.vlenType, VlenType.string);
        expect(writer.getSize(), 16);
      });
    });

    group('Message format verification', () {
      test('vlen message format matches HDF5 specification', () {
        final writer = VlenDatatypeWriter(
          baseType: NumericDatatypeWriter.float64(),
        );

        final message = writer.writeMessage();

        expect(message, isNotEmpty);

        // Class and version byte: version 1, class 9 (vlen)
        expect(message[0], 0x19);

        // Class bit field 1: type (0=sequence)
        expect(message[1], 0);

        // Size field: 16 bytes
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 16);
      });
    });
  });

  group('EnumDatatypeWriter', () {
    group('Basic functionality', () {
      test('creates enum writer with uint8 base', () {
        final writer = EnumDatatypeWriter(
          baseType: NumericDatatypeWriter.uint8(),
          members: {
            'RED': 0,
            'GREEN': 1,
            'BLUE': 2,
          },
        );

        expect(writer.datatypeClass, Hdf5DatatypeClass.enumType);
        expect(writer.getSize(), 1);
        expect(writer.members.length, 3);
      });

      test('creates enum writer with int32 base', () {
        final writer = EnumDatatypeWriter(
          baseType: NumericDatatypeWriter.int32(),
          members: {
            'PENDING': 0,
            'ACTIVE': 1,
            'COMPLETE': 2,
          },
        );

        expect(writer.getSize(), 4);
        expect(writer.members.length, 3);
      });

      test('rejects empty members', () {
        expect(
          () => EnumDatatypeWriter(
            baseType: NumericDatatypeWriter.uint8(),
            members: {},
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects non-integer base type', () {
        expect(
          () => EnumDatatypeWriter(
            baseType: NumericDatatypeWriter.float64(),
            members: {'A': 0},
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('encodeValue returns correct integer', () {
        final writer = EnumDatatypeWriter(
          baseType: NumericDatatypeWriter.uint8(),
          members: {
            'RED': 0,
            'GREEN': 1,
            'BLUE': 2,
          },
        );

        expect(writer.encodeValue('RED'), 0);
        expect(writer.encodeValue('GREEN'), 1);
        expect(writer.encodeValue('BLUE'), 2);
      });

      test('encodeValue throws for unknown member', () {
        final writer = EnumDatatypeWriter(
          baseType: NumericDatatypeWriter.uint8(),
          members: {'RED': 0},
        );

        expect(
          () => writer.encodeValue('YELLOW'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('decodeValue returns correct string', () {
        final writer = EnumDatatypeWriter(
          baseType: NumericDatatypeWriter.uint8(),
          members: {
            'RED': 0,
            'GREEN': 1,
            'BLUE': 2,
          },
        );

        expect(writer.decodeValue(0), 'RED');
        expect(writer.decodeValue(1), 'GREEN');
        expect(writer.decodeValue(2), 'BLUE');
      });

      test('decodeValue throws for unknown value', () {
        final writer = EnumDatatypeWriter(
          baseType: NumericDatatypeWriter.uint8(),
          members: {'RED': 0},
        );

        expect(
          () => writer.decodeValue(99),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Message format verification', () {
      test('enum message format matches HDF5 specification', () {
        final writer = EnumDatatypeWriter(
          baseType: NumericDatatypeWriter.uint8(),
          members: {
            'A': 0,
            'B': 1,
          },
        );

        final message = writer.writeMessage();

        expect(message, isNotEmpty);

        // Class and version byte: version 1, class 8 (enum)
        expect(message[0], 0x18);

        // Number of members: 2
        expect(message[1], 2);
        expect(message[2], 0);

        // Size: 1 byte
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 1);
      });
    });
  });

  group('ReferenceDatatypeWriter', () {
    group('Basic functionality', () {
      test('creates object reference writer', () {
        final writer = ReferenceDatatypeWriter(
          referenceType: ReferenceType.object,
        );

        expect(writer.datatypeClass, Hdf5DatatypeClass.reference);
        expect(writer.referenceType, ReferenceType.object);
        expect(writer.getSize(), 8);
      });

      test('creates region reference writer', () {
        final writer = ReferenceDatatypeWriter(
          referenceType: ReferenceType.region,
        );

        expect(writer.referenceType, ReferenceType.region);
        expect(writer.getSize(), 12);
      });
    });

    group('Message format verification', () {
      test('object reference message format matches HDF5 specification', () {
        final writer = ReferenceDatatypeWriter(
          referenceType: ReferenceType.object,
        );

        final message = writer.writeMessage();

        expect(message, isNotEmpty);

        // Class and version byte: version 1, class 7 (reference)
        expect(message[0], 0x17);

        // Class bit field 1: type (0=object)
        expect(message[1], 0);

        // Size: 8 bytes
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 8);
      });

      test('region reference message format matches HDF5 specification', () {
        final writer = ReferenceDatatypeWriter(
          referenceType: ReferenceType.region,
        );

        final message = writer.writeMessage();

        // Class bit field 1: type (1=region)
        expect(message[1], 1);

        // Size: 12 bytes
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 12);
      });
    });
  });

  group('OpaqueDatatypeWriter', () {
    group('Basic functionality', () {
      test('creates opaque writer with tag', () {
        final writer = OpaqueDatatypeWriter(
          size: 128,
          tag: 'JPEG_IMAGE',
        );

        expect(writer.datatypeClass, Hdf5DatatypeClass.opaque);
        expect(writer.getSize(), 128);
        expect(writer.tag, 'JPEG_IMAGE');
      });

      test('creates opaque writer without tag', () {
        final writer = OpaqueDatatypeWriter(
          size: 64,
        );

        expect(writer.getSize(), 64);
        expect(writer.tag, isNull);
      });

      test('rejects zero or negative size', () {
        expect(
          () => OpaqueDatatypeWriter(size: 0),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => OpaqueDatatypeWriter(size: -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects tag longer than 255 characters', () {
        expect(
          () => OpaqueDatatypeWriter(
            size: 10,
            tag: 'A' * 256,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Message format verification', () {
      test('opaque message format matches HDF5 specification', () {
        final writer = OpaqueDatatypeWriter(
          size: 100,
          tag: 'TEST',
        );

        final message = writer.writeMessage();

        expect(message, isNotEmpty);

        // Class and version byte: version 1, class 5 (opaque)
        expect(message[0], 0x15);

        // Class bit field 1: tag length (4)
        expect(message[1], 4);

        // Size: 100 bytes
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 100);

        // Tag should be present
        final tagStr = String.fromCharCodes(message.sublist(8, 12));
        expect(tagStr, 'TEST');
      });

      test('opaque message without tag', () {
        final writer = OpaqueDatatypeWriter(
          size: 50,
        );

        final message = writer.writeMessage();

        // Tag length should be 0
        expect(message[1], 0);

        // Message should be shorter (no tag bytes)
        expect(message.length, 8);
      });
    });
  });

  group('BitfieldDatatypeWriter', () {
    group('Basic functionality', () {
      test('creates 8-bit bitfield writer', () {
        final writer = BitfieldDatatypeWriter(size: 1);

        expect(writer.datatypeClass, Hdf5DatatypeClass.bitfield);
        expect(writer.getSize(), 1);
      });

      test('creates 16-bit bitfield writer', () {
        final writer = BitfieldDatatypeWriter(size: 2);
        expect(writer.getSize(), 2);
      });

      test('creates 32-bit bitfield writer', () {
        final writer = BitfieldDatatypeWriter(size: 4);
        expect(writer.getSize(), 4);
      });

      test('creates 64-bit bitfield writer', () {
        final writer = BitfieldDatatypeWriter(size: 8);
        expect(writer.getSize(), 8);
      });

      test('rejects invalid sizes', () {
        expect(
          () => BitfieldDatatypeWriter(size: 3),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => BitfieldDatatypeWriter(size: 16),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Message format verification', () {
      test('bitfield message format matches HDF5 specification', () {
        final writer = BitfieldDatatypeWriter(size: 4);

        final message = writer.writeMessage();

        expect(message, isNotEmpty);

        // Class and version byte: version 1, class 4 (bitfield)
        expect(message[0], 0x14);

        // Class bit field 1: byte order (0=little-endian)
        expect(message[1], 0);

        // Size: 4 bytes
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 4);

        // Bit precision: 32 bits
        final bitPrecision =
            ByteData.sublistView(Uint8List.fromList(message), 10, 12)
                .getUint16(0, Endian.little);
        expect(bitPrecision, 32);
      });
    });
  });

  group('TimeDatatypeWriter', () {
    group('Basic functionality', () {
      test('creates time writer', () {
        final writer = TimeDatatypeWriter(size: 8);

        expect(writer.datatypeClass, Hdf5DatatypeClass.time);
        expect(writer.getSize(), 8);
      });

      test('creates 32-bit time writer', () {
        final writer = TimeDatatypeWriter(size: 4);
        expect(writer.getSize(), 4);
      });

      test('rejects zero or negative size', () {
        expect(
          () => TimeDatatypeWriter(size: 0),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => TimeDatatypeWriter(size: -1),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Message format verification', () {
      test('time message format matches HDF5 specification', () {
        final writer = TimeDatatypeWriter(size: 8);

        final message = writer.writeMessage();

        expect(message, isNotEmpty);

        // Class and version byte: version 1, class 2 (time)
        expect(message[0], 0x12);

        // Class bit field 1: byte order (0=little-endian)
        expect(message[1], 0);

        // Size: 8 bytes
        final size = ByteData.sublistView(Uint8List.fromList(message), 4, 8)
            .getUint32(0, Endian.little);
        expect(size, 8);

        // Bit precision: 64 bits
        final bitPrecision =
            ByteData.sublistView(Uint8List.fromList(message), 8, 10)
                .getUint16(0, Endian.little);
        expect(bitPrecision, 64);
      });
    });
  });

  group('Integration tests', () {
    test('all datatype writers can be created', () {
      expect(NumericDatatypeWriter.int32(), isNotNull);
      expect(StringDatatypeWriter.fixedLength(length: 10), isNotNull);
      expect(BooleanDatatypeWriter(), isNotNull);
      expect(
          CompoundDatatypeWriter.fromFields(
              {'x': NumericDatatypeWriter.float64()}),
          isNotNull);
      expect(
          ArrayDatatypeWriter(
              baseType: NumericDatatypeWriter.int32(), dimensions: [5]),
          isNotNull);
      expect(VlenDatatypeWriter(baseType: NumericDatatypeWriter.float64()),
          isNotNull);
      expect(
          EnumDatatypeWriter(
              baseType: NumericDatatypeWriter.uint8(), members: {'A': 0}),
          isNotNull);
      expect(ReferenceDatatypeWriter(referenceType: ReferenceType.object),
          isNotNull);
      expect(OpaqueDatatypeWriter(size: 10), isNotNull);
      expect(BitfieldDatatypeWriter(size: 4), isNotNull);
      expect(TimeDatatypeWriter(size: 8), isNotNull);
    });

    test('nested array in compound type', () {
      final arrayWriter = ArrayDatatypeWriter(
        baseType: NumericDatatypeWriter.float64(),
        dimensions: [3],
      );

      final compoundWriter = CompoundDatatypeWriter.fromFields({
        'id': NumericDatatypeWriter.int32(),
        'values': arrayWriter,
      });

      expect(compoundWriter.getSize(), greaterThan(0));
      final message = compoundWriter.writeMessage();
      expect(message, isNotEmpty);
    });
  });
}
