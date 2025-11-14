import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

void main() {
  group('HDF5 File Inspection', () {
    test('Dataset inspect() returns correct metadata', () async {
      final file = await Hdf5File.open('test/fixtures/compound_test.h5');

      try {
        final dataset = await file.dataset('/simple_compound');
        final info = dataset.inspect();

        expect(info['type'], isNull); // type is added by listRecursive
        expect(info['shape'], equals([3]));
        expect(info['dtype'], contains('compound'));
        expect(info['size'], equals(3));
        expect(info['storage'], equals('contiguous'));
        expect(info.containsKey('compression'), isFalse);
      } finally {
        await file.close();
      }
    });

    test('Group inspect() returns correct metadata', () async {
      final file = await Hdf5File.open('test/fixtures/compound_test.h5');

      try {
        final group = file.root;
        final info = group.inspect();

        expect(info['childCount'], equals(3));
        expect(info['children'], isA<List<String>>());
        expect(info['children'].length, equals(3));
        expect(info['children'], contains('simple_compound'));
      } finally {
        await file.close();
      }
    });

    test('listRecursive() returns all objects', () async {
      final file = await Hdf5File.open('test/fixtures/compound_test.h5');

      try {
        final structure = await file.listRecursive();

        expect(structure.length, equals(3));
        expect(structure.containsKey('/simple_compound'), isTrue);
        expect(structure.containsKey('/compound_with_string'), isTrue);
        expect(structure.containsKey('/nested_compound'), isTrue);

        final datasetInfo = structure['/simple_compound']!;
        expect(datasetInfo['type'], equals('dataset'));
        expect(datasetInfo['shape'], equals([3]));
        expect(datasetInfo['storage'], equals('contiguous'));
      } finally {
        await file.close();
      }
    });

    test('getSummaryStats() returns correct statistics', () async {
      final file = await Hdf5File.open('test/fixtures/compound_test.h5');

      try {
        final stats = await file.getSummaryStats();

        expect(stats['totalDatasets'], equals(3));
        expect(stats['totalGroups'], equals(0));
        expect(stats['totalObjects'], equals(3));
        expect(stats['maxDepth'], equals(1));
        expect(stats['compressedDatasets'], equals(0));
        expect(stats['chunkedDatasets'], equals(0));
        expect(stats['datasetsByType'], isA<Map<String, int>>());
      } finally {
        await file.close();
      }
    });

    test('Chunked dataset inspection shows chunk info', () async {
      final file =
          await Hdf5File.open('test/fixtures/chunked_string_compound_test.h5');

      try {
        final dataset = await file.dataset('/chunked_compound');
        final info = dataset.inspect();

        expect(info['storage'], equals('chunked'));
        expect(info['chunkDimensions'], equals([4]));
        expect(info['shape'], equals([8]));
      } finally {
        await file.close();
      }
    });

    test('Chunked file summary shows chunked datasets', () async {
      final file =
          await Hdf5File.open('test/fixtures/chunked_string_compound_test.h5');

      try {
        final stats = await file.getSummaryStats();

        expect(stats['totalDatasets'], equals(2));
        expect(stats['chunkedDatasets'], equals(2));
      } finally {
        await file.close();
      }
    });

    test('printTree() executes without errors', () async {
      final file = await Hdf5File.open('test/fixtures/compound_test.h5');

      try {
        // This should not throw
        await file.printTree(showAttributes: true, showSizes: true);
        await file.printTree(showAttributes: false, showSizes: false);
      } finally {
        await file.close();
      }
    });

    test('String dataset inspection shows correct dtype', () async {
      final file =
          await Hdf5File.open('test/fixtures/chunked_string_compound_test.h5');

      try {
        final dataset = await file.dataset('/chunked_strings');
        final info = dataset.inspect();

        expect(info['dtype'], contains('string'));
        expect(info['dtype'], contains('fixed-length'));
      } finally {
        await file.close();
      }
    });
  });
}
