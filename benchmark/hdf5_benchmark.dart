import 'dart:io';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';
import 'performance_test_runner.dart';

/// HDF5 file reading performance test
class Hdf5FileOpenTest extends PerformanceTest {
  final String filePath;
  final int fileSize;

  Hdf5FileOpenTest(this.filePath, this.fileSize)
      : super(
          'HDF5 File Open (${_formatBytes(fileSize)})',
          'Tests performance of opening and parsing HDF5 file headers',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    final file = await Hdf5File.open(filePath);
    await file.close();

    stopwatch.stop();

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      additionalMetrics: {
        'file_size': fileSize,
        'file_path': filePath,
      },
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// HDF5 contiguous dataset reading performance test
class Hdf5ContiguousReadTest extends PerformanceTest {
  final String filePath;
  final String datasetPath;
  final int expectedElements;

  Hdf5ContiguousReadTest(this.filePath, this.datasetPath, this.expectedElements)
      : super(
          'HDF5 Contiguous Read ($datasetPath, $expectedElements elements)',
          'Tests performance of reading contiguous datasets',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    final file = await Hdf5File.open(filePath);
    final data = await file.readDataset(datasetPath);
    await file.close();

    stopwatch.stop();

    final dataSize = _estimateDataSize(data);
    final throughputMBps =
        (dataSize / 1024 / 1024) / (stopwatch.elapsedMicroseconds / 1000000);

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      memoryUsage: dataSize,
      additionalMetrics: {
        'elements_read': data.length,
        'data_size_bytes': dataSize,
        'throughput_mbps': throughputMBps.toStringAsFixed(2),
      },
    );
  }

  int _estimateDataSize(List<dynamic> data) {
    if (data.isEmpty) return 0;
    final first = data.first;
    if (first is int) return data.length * 8;
    if (first is double) return data.length * 8;
    if (first is String) {
      return data.fold<int>(0, (sum, s) => sum + (s as String).length);
    }
    if (first is List) {
      return data.fold<int>(0, (sum, row) => sum + _estimateDataSize(row));
    }
    return data.length * 8; // Default estimate
  }
}

/// HDF5 chunked dataset reading performance test
class Hdf5ChunkedReadTest extends PerformanceTest {
  final String filePath;
  final String datasetPath;
  final int expectedElements;

  Hdf5ChunkedReadTest(this.filePath, this.datasetPath, this.expectedElements)
      : super(
          'HDF5 Chunked Read ($datasetPath, $expectedElements elements)',
          'Tests performance of reading chunked datasets with B-tree navigation',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    final file = await Hdf5File.open(filePath);
    final data = await file.readDataset(datasetPath);
    await file.close();

    stopwatch.stop();

    final dataSize = _estimateDataSize(data);
    final throughputMBps =
        (dataSize / 1024 / 1024) / (stopwatch.elapsedMicroseconds / 1000000);

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      memoryUsage: dataSize,
      additionalMetrics: {
        'elements_read': data.length,
        'data_size_bytes': dataSize,
        'throughput_mbps': throughputMBps.toStringAsFixed(2),
      },
    );
  }

  int _estimateDataSize(List<dynamic> data) {
    if (data.isEmpty) return 0;
    final first = data.first;
    if (first is int) return data.length * 8;
    if (first is double) return data.length * 8;
    if (first is String) {
      return data.fold<int>(0, (sum, s) => sum + (s as String).length);
    }
    if (first is List) {
      return data.fold<int>(0, (sum, row) => sum + _estimateDataSize(row));
    }
    return data.length * 8;
  }
}

/// HDF5 compressed dataset reading performance test
class Hdf5CompressedReadTest extends PerformanceTest {
  final String filePath;
  final String datasetPath;
  final int expectedElements;

  Hdf5CompressedReadTest(this.filePath, this.datasetPath, this.expectedElements)
      : super(
          'HDF5 Compressed Read ($datasetPath, $expectedElements elements)',
          'Tests performance of reading compressed datasets with decompression',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    final file = await Hdf5File.open(filePath);
    final data = await file.readDataset(datasetPath);
    await file.close();

    stopwatch.stop();

    final dataSize = _estimateDataSize(data);
    final throughputMBps =
        (dataSize / 1024 / 1024) / (stopwatch.elapsedMicroseconds / 1000000);

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      memoryUsage: dataSize,
      additionalMetrics: {
        'elements_read': data.length,
        'data_size_bytes': dataSize,
        'throughput_mbps': throughputMBps.toStringAsFixed(2),
      },
    );
  }

  int _estimateDataSize(List<dynamic> data) {
    if (data.isEmpty) return 0;
    final first = data.first;
    if (first is int) return data.length * 8;
    if (first is double) return data.length * 8;
    if (first is String) {
      return data.fold<int>(0, (sum, s) => sum + (s as String).length);
    }
    if (first is List) {
      return data.fold<int>(0, (sum, row) => sum + _estimateDataSize(row));
    }
    return data.length * 8;
  }
}

/// HDF5 string dataset reading performance test
class Hdf5StringReadTest extends PerformanceTest {
  final String filePath;
  final String datasetPath;

  Hdf5StringReadTest(this.filePath, this.datasetPath)
      : super(
          'HDF5 String Read ($datasetPath)',
          'Tests performance of reading string datasets',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    final file = await Hdf5File.open(filePath);
    final data = await file.readDataset(datasetPath);
    await file.close();

    stopwatch.stop();

    final totalChars =
        data.fold<int>(0, (sum, s) => sum + (s as String).length);
    final dataSize = totalChars * 2; // Approximate UTF-16 size

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      memoryUsage: dataSize,
      additionalMetrics: {
        'strings_read': data.length,
        'total_characters': totalChars,
        'data_size_bytes': dataSize,
      },
    );
  }
}

/// HDF5 compound dataset reading performance test
class Hdf5CompoundReadTest extends PerformanceTest {
  final String filePath;
  final String datasetPath;

  Hdf5CompoundReadTest(this.filePath, this.datasetPath)
      : super(
          'HDF5 Compound Read ($datasetPath)',
          'Tests performance of reading compound (struct) datasets',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    final file = await Hdf5File.open(filePath);
    final data = await file.readDataset(datasetPath);
    await file.close();

    stopwatch.stop();

    int fieldCount = 0;
    if (data.isNotEmpty && data.first is Map) {
      fieldCount = (data.first as Map).length;
    }

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      additionalMetrics: {
        'records_read': data.length,
        'fields_per_record': fieldCount,
        'total_fields': data.length * fieldCount,
      },
    );
  }
}

/// HDF5 group navigation performance test
class Hdf5GroupNavigationTest extends PerformanceTest {
  final String filePath;

  Hdf5GroupNavigationTest(this.filePath)
      : super(
          'HDF5 Group Navigation',
          'Tests performance of navigating through group hierarchies',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    final file = await Hdf5File.open(filePath);
    final structure = await file.listRecursive();
    await file.close();

    stopwatch.stop();

    int datasetCount = 0;
    int groupCount = 0;
    for (final info in structure.values) {
      if (info['type'] == 'dataset') datasetCount++;
      if (info['type'] == 'group') groupCount++;
    }

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      additionalMetrics: {
        'total_objects': structure.length,
        'datasets': datasetCount,
        'groups': groupCount,
      },
    );
  }
}

/// HDF5 metadata caching performance test
class Hdf5CachingTest extends PerformanceTest {
  final String filePath;
  final String datasetPath;
  final int iterations;

  Hdf5CachingTest(this.filePath, this.datasetPath, this.iterations)
      : super(
          'HDF5 Caching Test ($iterations iterations)',
          'Tests effectiveness of metadata caching',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    final file = await Hdf5File.open(filePath);

    // Read the same dataset multiple times to test caching
    for (int i = 0; i < iterations; i++) {
      await file.dataset(datasetPath);
    }

    await file.close();
    stopwatch.stop();

    final avgTimePerAccess = stopwatch.elapsedMilliseconds / iterations;

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      additionalMetrics: {
        'iterations': iterations,
        'avg_time_per_access_ms': avgTimePerAccess.toStringAsFixed(2),
      },
    );
  }
}

/// HDF5 attribute reading performance test
class Hdf5AttributeReadTest extends PerformanceTest {
  final String filePath;
  final String objectPath;

  Hdf5AttributeReadTest(this.filePath, this.objectPath)
      : super(
          'HDF5 Attribute Read ($objectPath)',
          'Tests performance of reading attributes',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    final file = await Hdf5File.open(filePath);
    final dataset = await file.dataset(objectPath);
    final attributes = dataset.header.findAttributes();
    await file.close();

    stopwatch.stop();

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      additionalMetrics: {
        'attribute_count': attributes.length,
      },
    );
  }
}

/// HDF5 file inspection performance test
class Hdf5InspectionTest extends PerformanceTest {
  final String filePath;

  Hdf5InspectionTest(this.filePath)
      : super(
          'HDF5 File Inspection',
          'Tests performance of inspecting file structure without reading data',
        );

  @override
  Future<PerformanceResult> run() async {
    final stopwatch = Stopwatch()..start();

    final file = await Hdf5File.open(filePath);
    final stats = await file.getSummaryStats();
    await file.close();

    stopwatch.stop();

    return PerformanceResult(
      testName: name,
      executionTime: stopwatch.elapsedMilliseconds,
      additionalMetrics: {
        'total_datasets': stats['totalDatasets'],
        'total_groups': stats['totalGroups'],
        'max_depth': stats['maxDepth'],
        'compressed_datasets': stats['compressedDatasets'],
        'chunked_datasets': stats['chunkedDatasets'],
      },
    );
  }
}

/// Main function to run all HDF5 performance tests
void main() async {
  final runner = PerformanceTestRunner();

  // Check which test files exist
  final testFiles = {
    'example/data/test_simple.h5': true,
    'example/data/test_chunked.h5': true,
    'example/data/test_compressed.h5': true,
    'test/fixtures/string_test.h5': true,
    'test/fixtures/compound_test.h5': true,
    'example/data/test_attributes.h5': true,
    'example/data/processdata.h5': true,
  };

  // Verify files exist
  for (final path in testFiles.keys.toList()) {
    if (!await File(path).exists()) {
      print('Warning: Test file not found: $path');
      testFiles[path] = false;
    }
  }

  print('=== HDF5 PERFORMANCE BENCHMARK SUITE ===\n');

  // File opening tests
  if (testFiles['example/data/test_simple.h5']!) {
    final file = File('example/data/test_simple.h5');
    final size = await file.length();
    runner.addTest(Hdf5FileOpenTest('example/data/test_simple.h5', size));
  }

  if (testFiles['example/data/test_chunked.h5']!) {
    final file = File('example/data/test_chunked.h5');
    final size = await file.length();
    runner.addTest(Hdf5FileOpenTest('example/data/test_chunked.h5', size));
  }

  // Contiguous dataset reading tests
  if (testFiles['example/data/test_simple.h5']!) {
    runner.addTest(Hdf5ContiguousReadTest(
      'example/data/test_simple.h5',
      '/data1d',
      100,
    ));
    runner.addTest(Hdf5ContiguousReadTest(
      'example/data/test_simple.h5',
      '/data2d',
      100,
    ));
  }

  // Chunked dataset reading tests
  if (testFiles['example/data/test_chunked.h5']!) {
    runner.addTest(Hdf5ChunkedReadTest(
      'example/data/test_chunked.h5',
      '/chunked_1d',
      10000,
    ));
    runner.addTest(Hdf5ChunkedReadTest(
      'example/data/test_chunked.h5',
      '/chunked_2d',
      10000,
    ));
  }

  // Compressed dataset reading tests
  if (testFiles['example/data/test_compressed.h5']!) {
    runner.addTest(Hdf5CompressedReadTest(
      'example/data/test_compressed.h5',
      '/gzip_1d',
      10000,
    ));
    runner.addTest(Hdf5CompressedReadTest(
      'example/data/test_compressed.h5',
      '/lzf_1d',
      10000,
    ));
  }

  // String dataset reading tests
  if (testFiles['test/fixtures/string_test.h5']!) {
    runner.addTest(Hdf5StringReadTest(
      'test/fixtures/string_test.h5',
      '/fixed_ascii',
    ));
    runner.addTest(Hdf5StringReadTest(
      'test/fixtures/string_test.h5',
      '/vlen_ascii',
    ));
  }

  // Compound dataset reading tests
  if (testFiles['test/fixtures/compound_test.h5']!) {
    runner.addTest(Hdf5CompoundReadTest(
      'test/fixtures/compound_test.h5',
      '/simple_compound',
    ));
  }

  // Group navigation tests
  if (testFiles['example/data/test_simple.h5']!) {
    runner.addTest(Hdf5GroupNavigationTest('example/data/test_simple.h5'));
  }

  // Caching tests
  if (testFiles['example/data/test_simple.h5']!) {
    runner.addTest(Hdf5CachingTest(
      'example/data/test_simple.h5',
      '/data1d',
      10,
    ));
    runner.addTest(Hdf5CachingTest(
      'example/data/test_simple.h5',
      '/data1d',
      50,
    ));
  }

  // Attribute reading tests
  if (testFiles['example/data/test_attributes.h5']!) {
    runner.addTest(Hdf5AttributeReadTest(
      'example/data/test_attributes.h5',
      '/data',
    ));
  }

  // File inspection tests
  if (testFiles['example/data/test_simple.h5']!) {
    runner.addTest(Hdf5InspectionTest('example/data/test_simple.h5'));
  }

  if (testFiles['example/data/processdata.h5']!) {
    runner.addTest(Hdf5InspectionTest('example/data/processdata.h5'));
  }

  // Run all tests
  await runner.runAllTests();

  print('\n=== PERFORMANCE ANALYSIS ===\n');
  print(
      'Benchmark complete. See benchmark/performance_report.txt for details.');
}
