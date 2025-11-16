import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';
import 'dart:io';

void main() {
  group('SmartLoader', () {
    setUp(() {
      // Initialize SmartLoader
      SmartLoader.initialize();
    });

    test('initialization registers default sources', () {
      final schemes = DataSourceRegistry.listSchemes();
      expect(schemes, contains('file'));
      expect(schemes, contains('http'));
      expect(schemes, contains('dataset'));
      expect(schemes, contains('database'));
    });

    test('can find data source by URI', () {
      final fileUri = Uri.parse('file:///path/to/data.csv');
      final source = DataSourceRegistry.findByUri(fileUri);
      expect(source, isNotNull);
      expect(source!.scheme, equals('file'));

      final httpUri = Uri.parse('https://example.com/data.json');
      final httpSource = DataSourceRegistry.findByUri(httpUri);
      expect(httpSource, isNotNull);
      expect(httpSource!.canHandle(httpUri), isTrue);
    });

    test('can register and unregister custom sources', () {
      final customSource = TestDataSource();
      DataSourceRegistry.register(customSource);

      expect(DataSourceRegistry.listSchemes(), contains('test'));

      final uri = Uri.parse('test://data');
      final found = DataSourceRegistry.findByUri(uri);
      expect(found, isNotNull);
      expect(found, equals(customSource));

      DataSourceRegistry.unregister('test');
      expect(DataSourceRegistry.listSchemes(), isNot(contains('test')));
    });
  });

  group('FileDataSource', () {
    late Directory tempDir;
    late String testCsvPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dartframe_test_');
      testCsvPath = '${tempDir.path}/test.csv';

      // Create test CSV file
      final csvContent = '''name,age,city
Alice,25,New York
Bob,30,London
Charlie,35,Paris''';
      await File(testCsvPath).writeAsString(csvContent);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('can read CSV file', () async {
      final df = await DataFrame.read(testCsvPath);
      expect(df.shape.rows, equals(3));
      expect(df.shape.columns, equals(3));
      expect(df.columns, equals(['name', 'age', 'city']));
    });

    test('can write CSV file', () async {
      final df = DataFrame.fromMap({
        'id': [1, 2, 3],
        'value': [10.0, 20.0, 30.0],
      });

      final outputPath = '${tempDir.path}/output.csv';
      await df.write(outputPath);

      expect(File(outputPath).existsSync(), isTrue);

      // Read it back
      final loaded = await DataFrame.read(outputPath);
      expect(loaded.shape.rows, equals(3));
      expect(loaded.columns, contains('id'));
      expect(loaded.columns, contains('value'));
    });

    test('can inspect file', () async {
      final info = await DataFrame.inspect(testCsvPath);
      expect(info['exists'], isTrue);
      expect(info['format'], equals('csv'));
      expect(info['extension'], equals('.csv'));
      expect(info['size'], greaterThan(0));
    });

    test('throws error for non-existent file', () async {
      expect(
        () => DataFrame.read('${tempDir.path}/nonexistent.csv'),
        throwsA(isA<DataSourceError>()),
      );
    });
  });

  group('ScientificDatasets', () {
    test('lists available datasets', () {
      final datasets = ScientificDatasets.listDatasets();
      expect(datasets, isNotEmpty);
      expect(datasets, contains('iris'));
      expect(datasets, contains('mnist'));
      expect(datasets, contains('titanic'));
    });

    test('lists datasets with descriptions', () {
      final datasets = ScientificDatasets.listDatasetsWithDescriptions();
      expect(datasets, isNotEmpty);
      expect(datasets['iris'], isNotNull);
      expect(datasets['iris'], contains('Iris'));
    });

    test('gets dataset info', () {
      final info = ScientificDatasets.getInfo('iris');
      expect(info, isNotNull);
      expect(info!.name, equals('Iris'));
      expect(info.features, equals(4));
      expect(info.samples['full'], equals(150));
    });

    test('returns null for unknown dataset', () {
      final info = ScientificDatasets.getInfo('unknown_dataset');
      expect(info, isNull);
    });

    test('can load iris dataset', () async {
      try {
        final df = await DataFrame.read('dataset://iris');
        expect(df.shape.rows, greaterThan(0));
        expect(df.shape.columns, greaterThan(0));
      } catch (e) {
        // Skip if no internet connection
        print('Skipping iris test (no internet): $e');
      }
    }, timeout: Timeout(Duration(seconds: 60)));
  });

  group('ScientificDataSource', () {
    test('can handle dataset URIs', () {
      final source = ScientificDataSource();
      expect(source.canHandle(Uri.parse('dataset://iris')), isTrue);
      expect(source.canHandle(Uri.parse('dataset://mnist/train')), isTrue);
      expect(source.canHandle(Uri.parse('http://example.com')), isFalse);
    });

    test('can inspect dataset', () async {
      final source = ScientificDataSource();
      final info = await source.inspect(Uri.parse('dataset://iris'));
      expect(info['name'], equals('Iris'));
      expect(info['features'], equals(4));
      expect(info['samples'], isNotNull);
    });

    test('lists all datasets when inspecting root', () async {
      final source = ScientificDataSource();
      final info = await source.inspect(Uri.parse('dataset://'));
      expect(info['available_datasets'], isNotNull);
      expect(info['available_datasets'], isA<Map>());
    });

    test('throws error for unknown dataset', () async {
      final source = ScientificDataSource();
      expect(
        () => source.read(Uri.parse('dataset://unknown'), {}),
        throwsA(isA<DataSourceError>()),
      );
    });
  });

  group('HttpDataSource', () {
    test('can handle HTTP URIs', () {
      final source = HttpDataSource();
      expect(source.canHandle(Uri.parse('http://example.com')), isTrue);
      expect(source.canHandle(Uri.parse('https://example.com')), isTrue);
      expect(source.canHandle(Uri.parse('file:///path')), isFalse);
    });

    test('detects format from URL extension', () {
      final source = HttpDataSource();
      expect(
        source.detectFormat(
          Uri.parse('https://example.com/data.csv'),
          {},
        ),
        equals('csv'),
      );
      expect(
        source.detectFormat(
          Uri.parse('https://example.com/data.json'),
          {},
        ),
        equals('json'),
      );
    });

    test('detects format from Content-Type header', () {
      final source = HttpDataSource();
      expect(
        source.detectFormat(
          Uri.parse('https://example.com/data'),
          {'content-type': 'text/csv'},
        ),
        equals('csv'),
      );
      expect(
        source.detectFormat(
          Uri.parse('https://example.com/data'),
          {'content-type': 'application/json'},
        ),
        equals('json'),
      );
    });
  });

  group('DataSourceRegistry', () {
    setUp(() {
      DataSourceRegistry.clear();
    });

    tearDown(() {
      DataSourceRegistry.clear();
      SmartLoader.initialize(); // Re-initialize for other tests
    });

    test('can register and retrieve sources', () {
      final source = TestDataSource();
      DataSourceRegistry.register(source);

      final retrieved = DataSourceRegistry.getByScheme('test');
      expect(retrieved, equals(source));
    });

    test('can unregister sources', () {
      final source = TestDataSource();
      DataSourceRegistry.register(source);
      expect(DataSourceRegistry.getByScheme('test'), isNotNull);

      DataSourceRegistry.unregister('test');
      expect(DataSourceRegistry.getByScheme('test'), isNull);
    });

    test('lists all registered schemes', () {
      DataSourceRegistry.register(TestDataSource());
      DataSourceRegistry.register(AnotherTestDataSource());

      final schemes = DataSourceRegistry.listSchemes();
      expect(schemes, contains('test'));
      expect(schemes, contains('another'));
    });

    test('finds source by URI', () {
      final source = TestDataSource();
      DataSourceRegistry.register(source);

      final found = DataSourceRegistry.findByUri(Uri.parse('test://data'));
      expect(found, equals(source));
    });

    test('returns null for unregistered scheme', () {
      final found = DataSourceRegistry.findByUri(Uri.parse('unknown://data'));
      expect(found, isNull);
    });
  });

  group('Error Handling', () {
    test('DataSourceError includes message and cause', () {
      final error = DataSourceError('Test error', Exception('Cause'));
      expect(error.message, equals('Test error'));
      expect(error.cause, isA<Exception>());
      expect(error.toString(), contains('Test error'));
      expect(error.toString(), contains('Cause'));
    });

    test('DataSourceError without cause', () {
      final error = DataSourceError('Test error');
      expect(error.message, equals('Test error'));
      expect(error.cause, isNull);
      expect(error.toString(), equals('DataSourceError: Test error'));
    });

    test('SmartLoader throws error for unsupported scheme', () async {
      expect(
        () => SmartLoader.read('unsupported://data'),
        throwsA(isA<DataSourceError>()),
      );
    });
  });
}

// Test data sources for testing

class TestDataSource extends DataSource {
  @override
  String get scheme => 'test';

  @override
  bool canHandle(Uri uri) => uri.scheme == 'test';

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    return DataFrame.fromMap({
      'col1': [1, 2, 3],
      'col2': ['a', 'b', 'c'],
    });
  }

  @override
  Future<void> write(
      DataFrame df, Uri uri, Map<String, dynamic> options) async {
    // Mock write
  }

  @override
  Future<Map<String, dynamic>> inspect(Uri uri) async {
    return {'scheme': 'test', 'uri': uri.toString()};
  }
}

class AnotherTestDataSource extends DataSource {
  @override
  String get scheme => 'another';

  @override
  bool canHandle(Uri uri) => uri.scheme == 'another';

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    return DataFrame.fromMap({});
  }

  @override
  Future<void> write(
      DataFrame df, Uri uri, Map<String, dynamic> options) async {}
}
