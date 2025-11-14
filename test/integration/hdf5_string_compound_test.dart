import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

void main() {
  group('HDF5 String Datatype Tests', () {
    test('Read fixed-length ASCII strings', () async {
      final hdf5File = await Hdf5File.open('test/fixtures/string_test.h5');

      final data = await hdf5File.readDataset('/fixed_ascii');

      expect(data, isA<List>());
      expect(data.length, equals(3));
      expect(data[0], equals('hello'));
      expect(data[1], equals('world'));
      expect(data[2], equals('test'));

      await hdf5File.close();
    });

    test('Read fixed-length UTF-8 strings', () async {
      final hdf5File = await Hdf5File.open('test/fixtures/string_test.h5');

      final data = await hdf5File.readDataset('/fixed_utf8');

      expect(data, isA<List>());
      expect(data.length, equals(3));
      expect(data[0], equals('hello'));
      expect(data[1], equals('world'));
      expect(data[2], equals('test'));

      await hdf5File.close();
    });
  });

  group('HDF5 Compound Datatype Tests', () {
    test('Read simple compound dataset', () async {
      final hdf5File = await Hdf5File.open('test/fixtures/compound_test.h5');

      final data = await hdf5File.readDataset('/simple_compound');

      expect(data, isA<List>());
      expect(data.length, equals(3));

      // Check first row
      expect(data[0]['x'], equals(1));
      expect(data[0]['y'], equals(2));
      expect(data[0]['value'], closeTo(3.14, 0.01));

      // Check second row
      expect(data[1]['x'], equals(4));
      expect(data[1]['y'], equals(5));
      expect(data[1]['value'], closeTo(6.28, 0.01));

      // Check third row
      expect(data[2]['x'], equals(7));
      expect(data[2]['y'], equals(8));
      expect(data[2]['value'], closeTo(9.42, 0.01));

      await hdf5File.close();
    });

    test('Read compound dataset with strings', () async {
      final hdf5File = await Hdf5File.open('test/fixtures/compound_test.h5');

      final data = await hdf5File.readDataset('/compound_with_string');

      expect(data, isA<List>());
      expect(data.length, equals(3));

      // Check first row
      expect(data[0]['id'], equals(1));
      expect(data[0]['name'], equals('Alice'));
      expect(data[0]['score'], closeTo(95.5, 0.1));

      // Check second row
      expect(data[1]['id'], equals(2));
      expect(data[1]['name'], equals('Bob'));
      expect(data[1]['score'], closeTo(87.3, 0.1));

      // Check third row
      expect(data[2]['id'], equals(3));
      expect(data[2]['name'], equals('Charlie'));
      expect(data[2]['score'], closeTo(92.1, 0.1));

      await hdf5File.close();
    });
  });

  group('HDF5 Chunked String and Compound Tests', () {
    test('Read chunked string dataset', () async {
      final hdf5File =
          await Hdf5File.open('test/fixtures/chunked_string_compound_test.h5');

      final data = await hdf5File.readDataset('/chunked_strings');

      expect(data, isA<List>());
      expect(data.length, equals(4));
      expect(data[0], equals('chunk1'));
      expect(data[1], equals('chunk2'));
      expect(data[2], equals('chunk3'));
      expect(data[3], equals('chunk4'));

      await hdf5File.close();
    });

    test('Read chunked compound dataset', () async {
      final hdf5File =
          await Hdf5File.open('test/fixtures/chunked_string_compound_test.h5');

      final data = await hdf5File.readDataset('/chunked_compound');

      expect(data, isA<List>());
      expect(data.length, equals(8));

      // Check a few rows
      expect(data[0]['id'], equals(1));
      expect(data[0]['value'], closeTo(1.1, 0.01));

      expect(data[4]['id'], equals(5));
      expect(data[4]['value'], closeTo(5.5, 0.01));

      expect(data[7]['id'], equals(8));
      expect(data[7]['value'], closeTo(8.8, 0.01));

      await hdf5File.close();
    });
  });
}
