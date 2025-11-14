import 'dart:io';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

/// Memory profiling for HDF5 operations
class Hdf5MemoryProfiler {
  /// Profiles memory usage for a specific operation
  static Future<MemoryProfile> profile(
    String operationName,
    Future<void> Function() operation,
  ) async {
    // Force garbage collection before measurement
    for (int i = 0; i < 3; i++) {
      await Future.delayed(Duration(milliseconds: 10));
    }

    final stopwatch = Stopwatch()..start();

    await operation();

    stopwatch.stop();

    // Force garbage collection after measurement
    for (int i = 0; i < 3; i++) {
      await Future.delayed(Duration(milliseconds: 10));
    }

    return MemoryProfile(
      operationName: operationName,
      executionTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Profiles memory usage for opening HDF5 files
  static Future<void> profileFileOpen(String filePath) async {
    print('Profiling file open: $filePath');

    final profile = await Hdf5MemoryProfiler.profile(
      'File Open',
      () async {
        final file = await Hdf5File.open(filePath);
        await file.close();
      },
    );

    print('  Time: ${profile.executionTimeMs}ms');
  }

  /// Profiles memory usage for reading datasets
  static Future<void> profileDatasetRead(
    String filePath,
    String datasetPath,
  ) async {
    print('Profiling dataset read: $filePath -> $datasetPath');

    List<dynamic>? data;
    final profile = await Hdf5MemoryProfiler.profile(
      'Dataset Read',
      () async {
        final file = await Hdf5File.open(filePath);
        data = await file.readDataset(datasetPath);
        await file.close();
      },
    );

    final dataSize = _estimateDataSize(data!);
    print('  Time: ${profile.executionTimeMs}ms');
    print('  Data size: ${_formatBytes(dataSize)}');
    print('  Elements: ${data!.length}');
  }

  /// Profiles memory usage for recursive listing
  static Future<void> profileRecursiveListing(String filePath) async {
    print('Profiling recursive listing: $filePath');

    Map<String, Map<String, dynamic>>? structure;
    final profile = await Hdf5MemoryProfiler.profile(
      'Recursive Listing',
      () async {
        final file = await Hdf5File.open(filePath);
        structure = await file.listRecursive();
        await file.close();
      },
    );

    print('  Time: ${profile.executionTimeMs}ms');
    print('  Objects found: ${structure!.length}');
  }

  /// Profiles memory usage for multiple dataset reads (caching test)
  static Future<void> profileCaching(
    String filePath,
    String datasetPath,
    int iterations,
  ) async {
    print(
        'Profiling caching ($iterations iterations): $filePath -> $datasetPath');

    final profile = await Hdf5MemoryProfiler.profile(
      'Caching Test',
      () async {
        final file = await Hdf5File.open(filePath);
        for (int i = 0; i < iterations; i++) {
          await file.dataset(datasetPath);
        }
        await file.close();
      },
    );

    final avgTime = profile.executionTimeMs / iterations;
    print('  Total time: ${profile.executionTimeMs}ms');
    print('  Avg time per access: ${avgTime.toStringAsFixed(2)}ms');
  }

  static int _estimateDataSize(List<dynamic> data) {
    if (data.isEmpty) return 0;
    final first = data.first;
    if (first is int) return data.length * 8;
    if (first is double) return data.length * 8;
    if (first is String) {
      return data.fold<int>(0, (sum, s) => sum + (s as String).length * 2);
    }
    if (first is List) {
      return data.fold<int>(0, (sum, row) => sum + _estimateDataSize(row));
    }
    if (first is Map) {
      // Compound data
      int totalSize = 0;
      for (final record in data) {
        final map = record as Map;
        for (final value in map.values) {
          if (value is int)
            totalSize += 8;
          else if (value is double)
            totalSize += 8;
          else if (value is String) totalSize += value.length * 2;
        }
      }
      return totalSize;
    }
    return data.length * 8;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class MemoryProfile {
  final String operationName;
  final int executionTimeMs;

  MemoryProfile({
    required this.operationName,
    required this.executionTimeMs,
  });
}

/// Main function to run memory profiling
void main() async {
  print('=== HDF5 MEMORY PROFILING ===\n');

  // Check which test files exist
  final testFiles = [
    'example/data/test_simple.h5',
    'example/data/test_chunked.h5',
    'example/data/test_compressed.h5',
    'test/fixtures/string_test.h5',
    'test/fixtures/compound_test.h5',
    'example/data/processdata.h5',
  ];

  final availableFiles = <String>[];
  for (final path in testFiles) {
    if (await File(path).exists()) {
      availableFiles.add(path);
    } else {
      print('Warning: Test file not found: $path\n');
    }
  }

  if (availableFiles.isEmpty) {
    print('No test files available for profiling.');
    return;
  }

  // Profile file opening
  print('--- File Opening ---');
  for (final file in availableFiles) {
    await Hdf5MemoryProfiler.profileFileOpen(file);
  }
  print('');

  // Profile dataset reading
  print('--- Dataset Reading ---');
  if (availableFiles.contains('example/data/test_simple.h5')) {
    await Hdf5MemoryProfiler.profileDatasetRead(
      'example/data/test_simple.h5',
      '/data1d',
    );
  }
  if (availableFiles.contains('example/data/test_chunked.h5')) {
    await Hdf5MemoryProfiler.profileDatasetRead(
      'example/data/test_chunked.h5',
      '/chunked_1d',
    );
  }
  if (availableFiles.contains('example/data/test_compressed.h5')) {
    await Hdf5MemoryProfiler.profileDatasetRead(
      'example/data/test_compressed.h5',
      '/gzip_1d',
    );
  }
  if (availableFiles.contains('test/fixtures/string_test.h5')) {
    await Hdf5MemoryProfiler.profileDatasetRead(
      'test/fixtures/string_test.h5',
      '/fixed_ascii',
    );
  }
  if (availableFiles.contains('test/fixtures/compound_test.h5')) {
    await Hdf5MemoryProfiler.profileDatasetRead(
      'test/fixtures/compound_test.h5',
      '/simple_compound',
    );
  }
  print('');

  // Profile recursive listing
  print('--- Recursive Listing ---');
  for (final file in availableFiles.take(3)) {
    await Hdf5MemoryProfiler.profileRecursiveListing(file);
  }
  print('');

  // Profile caching
  print('--- Caching Performance ---');
  if (availableFiles.contains('example/data/test_simple.h5')) {
    await Hdf5MemoryProfiler.profileCaching(
      'example/data/test_simple.h5',
      '/data1d',
      10,
    );
    await Hdf5MemoryProfiler.profileCaching(
      'example/data/test_simple.h5',
      '/data1d',
      50,
    );
  }
  print('');

  print('=== PROFILING COMPLETE ===');
}
