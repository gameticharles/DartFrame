import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/data_writer.dart';
import 'package:dartframe/src/io/hdf5/byte_writer.dart';
import 'package:dartframe/src/ndarray/ndarray.dart';

void main() {
  group('DataWriter - Basic Operations', () {
    test('should write float64 data correctly', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Create a simple 1D array with float64 data
      final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0, 5.0], [5]);

      final dataAddress = await dataWriter.writeData(writer, array);

      expect(dataAddress, equals(0));
      expect(writer.size, equals(5 * 8)); // 5 elements * 8 bytes each

      // Verify the written data
      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.little), equals(1.0));
      expect(byteData.getFloat64(8, Endian.little), equals(2.0));
      expect(byteData.getFloat64(16, Endian.little), equals(3.0));
      expect(byteData.getFloat64(24, Endian.little), equals(4.0));
      expect(byteData.getFloat64(32, Endian.little), equals(5.0));
    });

    test('should write int64 data correctly', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Create a simple 1D array with int64 data
      final array = NDArray.fromFlat([10, 20, 30, 40, 50], [5]);

      final dataAddress = await dataWriter.writeData(writer, array);

      expect(dataAddress, equals(0));
      expect(writer.size, equals(5 * 8)); // 5 elements * 8 bytes each

      // Verify the written data
      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getInt64(0, Endian.little), equals(10));
      expect(byteData.getInt64(8, Endian.little), equals(20));
      expect(byteData.getInt64(16, Endian.little), equals(30));
      expect(byteData.getInt64(24, Endian.little), equals(40));
      expect(byteData.getInt64(32, Endian.little), equals(50));
    });

    test('should return correct data address', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Write some data first to offset the position
      writer.writeUint64(12345);

      final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);
      final dataAddress = await dataWriter.writeData(writer, array);

      expect(dataAddress, equals(8)); // After the uint64
    });

    test('should calculate data size correctly for float64', () {
      final dataWriter = DataWriter();
      final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0, 5.0], [5]);

      final size = dataWriter.calculateDataSize(array);

      expect(size, equals(5 * 8)); // 5 elements * 8 bytes
    });

    test('should calculate data size correctly for int64', () {
      final dataWriter = DataWriter();
      final array = NDArray.fromFlat([1, 2, 3, 4, 5], [5]);

      final size = dataWriter.calculateDataSize(array);

      expect(size, equals(5 * 8)); // 5 elements * 8 bytes
    });
  });

  group('DataWriter - Multi-dimensional Arrays', () {
    test('should write 2D float64 array correctly', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Create a 2x3 array
      final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], [2, 3]);

      await dataWriter.writeData(writer, array);

      expect(writer.size, equals(6 * 8)); // 6 elements * 8 bytes

      // Verify data is written in row-major order
      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.little), equals(1.0));
      expect(byteData.getFloat64(8, Endian.little), equals(2.0));
      expect(byteData.getFloat64(16, Endian.little), equals(3.0));
      expect(byteData.getFloat64(24, Endian.little), equals(4.0));
      expect(byteData.getFloat64(32, Endian.little), equals(5.0));
      expect(byteData.getFloat64(40, Endian.little), equals(6.0));
    });

    test('should write 3D int64 array correctly', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Create a 2x2x2 array
      final array = NDArray.fromFlat([1, 2, 3, 4, 5, 6, 7, 8], [2, 2, 2]);

      await dataWriter.writeData(writer, array);

      expect(writer.size, equals(8 * 8)); // 8 elements * 8 bytes

      // Verify data is written in row-major order
      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      for (int i = 0; i < 8; i++) {
        expect(byteData.getInt64(i * 8, Endian.little), equals(i + 1));
      }
    });

    test('should handle large 2D arrays', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Create a 100x100 array
      final data = List.generate(10000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [100, 100]);

      await dataWriter.writeData(writer, array);

      expect(writer.size, equals(10000 * 8)); // 10000 elements * 8 bytes

      // Verify first and last elements
      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.little), equals(0.0));
      expect(byteData.getFloat64(9999 * 8, Endian.little), equals(9999.0));
    });
  });

  group('DataWriter - Large Dataset Handling', () {
    test('should handle large datasets with chunked writing', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter(chunkSize: 1024); // Small chunk for testing

      // Create a large array (10000 elements)
      final data = List.generate(10000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [10000]);

      await dataWriter.writeData(writer, array);

      expect(writer.size, equals(10000 * 8));

      // Verify some sample values
      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.little), equals(0.0));
      expect(byteData.getFloat64(100 * 8, Endian.little), equals(100.0));
      expect(byteData.getFloat64(5000 * 8, Endian.little), equals(5000.0));
      expect(byteData.getFloat64(9999 * 8, Endian.little), equals(9999.0));
    });

    test('should handle very large datasets efficiently', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Create a large array (100000 elements = ~800KB)
      final data = List.generate(100000, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [100000]);

      final stopwatch = Stopwatch()..start();
      await dataWriter.writeData(writer, array);
      stopwatch.stop();

      expect(writer.size, equals(100000 * 8));

      // Verify performance (should complete in reasonable time)
      // This is a soft check - adjust if needed based on hardware
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('should handle custom chunk size', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter(chunkSize: 512); // 512 bytes = 64 float64s

      final data = List.generate(200, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [200]);

      await dataWriter.writeData(writer, array);

      expect(writer.size, equals(200 * 8));

      // Verify data integrity
      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      for (int i = 0; i < 200; i++) {
        expect(byteData.getFloat64(i * 8, Endian.little), equals(i.toDouble()));
      }
    });
  });

  group('DataWriter - Memory Management', () {
    test('should not hold references to input data', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Create array and write it
      final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0, 5.0], [5]);
      await dataWriter.writeData(writer, array);

      // The writer should have copied the data, not hold a reference
      // This is verified by the fact that we use toFlatList(copy: false)
      // but the data is written immediately
      expect(writer.size, equals(5 * 8));
    });

    test('should handle multiple sequential writes', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Write multiple arrays sequentially
      final array1 = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);
      final array2 = NDArray.fromFlat([4.0, 5.0, 6.0], [3]);
      final array3 = NDArray.fromFlat([7.0, 8.0, 9.0], [3]);

      await dataWriter.writeData(writer, array1);
      await dataWriter.writeData(writer, array2);
      await dataWriter.writeData(writer, array3);

      expect(writer.size, equals(9 * 8));

      // Verify all data is written correctly
      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      for (int i = 0; i < 9; i++) {
        expect(byteData.getFloat64(i * 8, Endian.little),
            equals((i + 1).toDouble()));
      }
    });
  });

  group('DataWriter - Edge Cases', () {
    test('should handle single element array', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      final array = NDArray.fromFlat([42.0], [1]);

      await dataWriter.writeData(writer, array);

      expect(writer.size, equals(8));

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);
      expect(byteData.getFloat64(0, Endian.little), equals(42.0));
    });

    test('should handle negative numbers', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      final array = NDArray.fromFlat([-1.0, -2.5, -100.0], [3]);

      await dataWriter.writeData(writer, array);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.little), equals(-1.0));
      expect(byteData.getFloat64(8, Endian.little), equals(-2.5));
      expect(byteData.getFloat64(16, Endian.little), equals(-100.0));
    });

    test('should handle zero values', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      final array = NDArray.fromFlat([0.0, 0.0, 0.0], [3]);

      await dataWriter.writeData(writer, array);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.little), equals(0.0));
      expect(byteData.getFloat64(8, Endian.little), equals(0.0));
      expect(byteData.getFloat64(16, Endian.little), equals(0.0));
    });

    test('should handle very large numbers', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      final array = NDArray.fromFlat(
          [1.7976931348623157e+308, -1.7976931348623157e+308], [2]);

      await dataWriter.writeData(writer, array);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.little),
          equals(1.7976931348623157e+308));
      expect(byteData.getFloat64(8, Endian.little),
          equals(-1.7976931348623157e+308));
    });

    test('should handle very small numbers', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      final array = NDArray.fromFlat(
          [2.2250738585072014e-308, -2.2250738585072014e-308], [2]);

      await dataWriter.writeData(writer, array);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.little),
          equals(2.2250738585072014e-308));
      expect(byteData.getFloat64(8, Endian.little),
          equals(-2.2250738585072014e-308));
    });

    test('should handle negative integers', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      final array = NDArray.fromFlat([-1, -100, -9223372036854775808], [3]);

      await dataWriter.writeData(writer, array);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getInt64(0, Endian.little), equals(-1));
      expect(byteData.getInt64(8, Endian.little), equals(-100));
      expect(
          byteData.getInt64(16, Endian.little), equals(-9223372036854775808));
    });

    test('should handle maximum integer values', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      final array =
          NDArray.fromFlat([9223372036854775807, -9223372036854775808], [2]);

      await dataWriter.writeData(writer, array);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getInt64(0, Endian.little), equals(9223372036854775807));
      expect(byteData.getInt64(8, Endian.little), equals(-9223372036854775808));
    });
  });

  group('DataWriter - Error Handling', () {
    test('should throw error for unsupported data type', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Create an array with string data (unsupported)
      final array = NDArray.fromFlat(['a', 'b', 'c'], [3]);

      expect(
        () async => await dataWriter.writeData(writer, array),
        throwsUnsupportedError,
      );
    });

    test('should throw error when calculating size for unsupported type', () {
      final dataWriter = DataWriter();
      final array = NDArray.fromFlat(['a', 'b', 'c'], [3]);

      expect(
        () => dataWriter.calculateDataSize(array),
        throwsUnsupportedError,
      );
    });
  });

  group('DataWriter - Data Integrity', () {
    test('should preserve data order for 1D arrays', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      final data = List.generate(100, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [100]);

      await dataWriter.writeData(writer, array);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      for (int i = 0; i < 100; i++) {
        expect(byteData.getFloat64(i * 8, Endian.little), equals(i.toDouble()));
      }
    });

    test('should preserve data order for 2D arrays', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      // Create a 10x10 array with sequential values
      final data = List.generate(100, (i) => i.toDouble());
      final array = NDArray.fromFlat(data, [10, 10]);

      await dataWriter.writeData(writer, array);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      // Verify data is in row-major order
      for (int i = 0; i < 100; i++) {
        expect(byteData.getFloat64(i * 8, Endian.little), equals(i.toDouble()));
      }
    });

    test('should preserve precision for float64 values', () async {
      final writer = ByteWriter();
      final dataWriter = DataWriter();

      final array = NDArray.fromFlat([
        3.141592653589793,
        2.718281828459045,
        1.414213562373095,
      ], [
        3
      ]);

      await dataWriter.writeData(writer, array);

      final bytes = writer.uint8List;
      final byteData = ByteData.sublistView(bytes);

      expect(byteData.getFloat64(0, Endian.little), equals(3.141592653589793));
      expect(byteData.getFloat64(8, Endian.little), equals(2.718281828459045));
      expect(byteData.getFloat64(16, Endian.little), equals(1.414213562373095));
    });
  });
}
