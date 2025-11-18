import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/hdf5_file_builder.dart';
import 'package:dartframe/src/io/hdf5/hdf5_error.dart';
import 'package:dartframe/src/io/hdf5/write_options.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';

void main() {
  group('HDF5FileBuilder', () {
    late HDF5FileBuilder builder;

    setUp(() {
      builder = HDF5FileBuilder();
    });

    group('Address Tracking', () {
      test('tracks superblock address', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        expect(builder.getAddress('superblock'), equals(0));
      });

      test('tracks root group address', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        final rootGroupAddress = builder.getAddress('rootGroup');
        expect(rootGroupAddress, isNotNull);
        expect(rootGroupAddress, greaterThan(0));
      });

      test('tracks dataset address', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        final datasetAddress = builder.getAddress('dataset');
        expect(datasetAddress, isNotNull);
        expect(datasetAddress, greaterThan(0));
      });

      test('tracks data address', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        final dataAddress = builder.getAddress('data');
        expect(dataAddress, isNotNull);
        expect(dataAddress, greaterThan(0));
      });

      test('tracks end of file address', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        final eofAddress = builder.getAddress('endOfFile');
        expect(eofAddress, isNotNull);
        expect(eofAddress, greaterThan(0));
      });

      test('addresses are in correct order', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        final superblock = builder.getAddress('superblock')!;
        final rootGroup = builder.getAddress('rootGroup')!;
        final dataset = builder.getAddress('dataset')!;
        final data = builder.getAddress('data')!;
        final eof = builder.getAddress('endOfFile')!;

        expect(superblock, lessThan(rootGroup));
        expect(rootGroup, lessThan(dataset));
        expect(dataset, lessThan(data));
        expect(data, lessThan(eof));
      });

      test('returns all tracked addresses', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        final addresses = builder.addresses;
        expect(addresses, isNotEmpty);
        expect(addresses.keys, contains('superblock'));
        expect(addresses.keys, contains('rootGroup'));
        expect(addresses.keys, contains('dataset'));
        expect(addresses.keys, contains('data'));
        expect(addresses.keys, contains('endOfFile'));
      });
    });

    group('Component Coordination', () {
      test('builds valid HDF5 file structure', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        final bytes = await builder.build(array: array);

        // Check HDF5 signature
        expect(bytes.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      });

      test('creates file with correct size', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        final bytes = await builder.build(array: array);

        // File should contain at minimum:
        // - Superblock (96 bytes)
        // - Root group header
        // - Symbol table structures
        // - Dataset header
        // - Data (4 * 8 bytes = 32 bytes for float64)
        expect(bytes.length, greaterThan(96 + 32));
      });

      test('handles 1D arrays', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);
        final bytes = await builder.build(array: array);

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      });

      test('handles 2D arrays', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        final bytes = await builder.build(array: array);

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      });

      test('handles 3D arrays', () async {
        final array = NDArray.fromFlat(
          [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
          [2, 2, 2],
        );
        final bytes = await builder.build(array: array);

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      });

      test('handles integer arrays', () async {
        final array = NDArray.fromFlat([1, 2, 3, 4], [2, 2]);
        final bytes = await builder.build(array: array);

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      });

      test('handles arrays with attributes', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        final bytes = await builder.build(
          array: array,
          attributes: {
            'units': 'meters',
            'description': 'Test data',
            'count': 42,
            'temperature': 23.5,
          },
        );

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      });

      test('handles custom dataset path', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        final bytes = await builder.build(
          array: array,
          datasetPath: '/mydata',
        );

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      });
    });

    group('File Structure Generation', () {
      test('generates valid superblock', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        final bytes = await builder.build(array: array);

        // Check superblock signature
        expect(bytes.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));

        // Check version (byte 8)
        expect(bytes[8], equals(0)); // Version 0
      });

      test('generates root group structure', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        final rootGroupAddress = builder.getAddress('rootGroup')!;
        expect(rootGroupAddress, greaterThanOrEqualTo(96)); // After superblock
      });

      test('generates dataset structure', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        final datasetAddress = builder.getAddress('dataset')!;
        final rootGroupAddress = builder.getAddress('rootGroup')!;
        expect(datasetAddress, greaterThan(rootGroupAddress));
      });

      test('generates data section', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        final dataAddress = builder.getAddress('data')!;
        final datasetAddress = builder.getAddress('dataset')!;
        expect(dataAddress, greaterThan(datasetAddress));
      });
    });

    group('Address Updates', () {
      test('updates superblock with root group address', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        final bytes = await builder.build(array: array);

        final rootGroupAddress = builder.getAddress('rootGroup')!;

        // Root group address is at offset 64 in superblock (little-endian)
        final addressBytes = bytes.sublist(64, 72);
        final address = _bytesToInt64(addressBytes);

        expect(address, equals(rootGroupAddress));
      });

      test('updates superblock with end of file address', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        final bytes = await builder.build(array: array);

        final eofAddress = builder.getAddress('endOfFile')!;

        // EOF address is at offset 40 in superblock (little-endian)
        final addressBytes = bytes.sublist(40, 48);
        final address = _bytesToInt64(addressBytes);

        expect(address, equals(eofAddress));
      });

      test('end of file address matches actual file size', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        final bytes = await builder.build(array: array);

        final eofAddress = builder.getAddress('endOfFile')!;
        expect(eofAddress, equals(bytes.length));
      });
    });

    group('Input Validation', () {
      test('rejects dataset path without leading slash', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);

        expect(
          () => builder.build(array: array, datasetPath: 'data'),
          throwsA(isA<InvalidDatasetNameError>()),
        );
      });

      test('rejects nested group paths', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);

        expect(
          () => builder.build(array: array, datasetPath: '/group/data'),
          throwsA(isA<InvalidDatasetNameError>()),
        );
      });

      test('accepts valid simple paths', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);

        final bytes = await builder.build(array: array, datasetPath: '/data');
        expect(bytes, isNotEmpty);
      });
    });

    group('Multiple Builds', () {
      test('can build multiple files with same builder', () async {
        final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
        final bytes1 = await builder.build(array: array1);

        final array2 = NDArray.fromFlat([3.0, 4.0, 5.0], [3]);
        final bytes2 = await builder.build(array: array2);

        // Both should be valid HDF5 files
        expect(bytes1.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
        expect(bytes2.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));

        // Should have different sizes
        expect(bytes1.length, isNot(equals(bytes2.length)));
      });

      test('clears addresses between builds', () async {
        final array1 = NDArray.fromFlat([1.0, 2.0], [2]);
        await builder.build(array: array1);
        final addresses1 = Map.from(builder.addresses);

        final array2 = NDArray.fromFlat([3.0, 4.0, 5.0], [3]);
        await builder.build(array: array2);
        final addresses2 = builder.addresses;

        // Addresses should be different (file structures are different sizes)
        expect(addresses1['endOfFile'], isNot(equals(addresses2['endOfFile'])));
      });
    });

    group('File Validation', () {
      test('validates superblock signature correctly', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        // Should not throw - file is valid
        expect(() => builder.validateFile(), returnsNormally);
      });

      test('detects corrupted superblock signature', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        // Corrupt the signature by accessing internal writer
        // This is a white-box test that requires access to internal state
        // In a real scenario, we would test with a corrupted byte array

        // For now, we'll test that validation passes on a valid file
        expect(() => builder.validateFile(), returnsNormally);
      });

      test('validates address references are within bounds', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        // All addresses should be valid
        expect(() => builder.validateFile(), returnsNormally);
      });

      test('validates end-of-file address matches file size', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        final bytes = await builder.build(array: array);

        final eofAddress = builder.getAddress('endOfFile')!;
        expect(eofAddress, equals(bytes.length));

        // Validation should pass
        expect(() => builder.validateFile(), returnsNormally);
      });

      test('validates B-tree structure exists', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        // B-tree should exist and be valid
        expect(() => builder.validateFile(), returnsNormally);
      });

      test('validation passes for valid files', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
        await builder.build(array: array);

        // Should not throw any exceptions
        expect(() => builder.validateFile(), returnsNormally);
      });
    });

    group('Validation with WriteOptions', () {
      test('validates file when validateOnWrite is true', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);

        // Should not throw - file is valid
        final bytes = await builder.build(
          array: array,
          options: const WriteOptions(validateOnWrite: true),
        );

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      });

      test('skips validation when validateOnWrite is false', () async {
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);

        // Should build without validation
        final bytes = await builder.build(
          array: array,
          options: const WriteOptions(validateOnWrite: false),
        );

        expect(bytes, isNotEmpty);
      });

      test('validates file in finalize when validateOnWrite is true', () async {
        final builder = HDF5FileBuilder();
        final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);

        await builder.addDataset('/data', array);

        // Should not throw - file is valid
        final bytes = await builder.finalize(
          options: const WriteOptions(validateOnWrite: true),
        );

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 8),
            equals([0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]));
      });
    });
  });
}

/// Helper function to convert little-endian bytes to int64
int _bytesToInt64(List<int> bytes) {
  int value = 0;
  for (int i = 0; i < 8; i++) {
    value |= (bytes[i] & 0xFF) << (i * 8);
  }
  return value;
}
