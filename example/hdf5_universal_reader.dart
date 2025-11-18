import 'dart:math' as math;
import 'package:dartframe/dartframe.dart';

/// Universal HDF5 File Reader
///
/// A comprehensive, generalized HDF5 reader that automatically:
/// - Discovers and reads all groups, datasets, and attributes
/// - Handles all 11 HDF5 datatype classes:
///   1. Integer (int8, int16, int32, int64, uint8, uint16, uint32, uint64)
///   2. Float (float32, float64)
///   3. Time (date/time values)
///   4. String (fixed-length and variable-length)
///   5. Bitfield (bit-level data)
///   6. Opaque (uninterpreted binary data)
///   7. Compound (structures with multiple fields)
///   8. Reference (object and region references)
///   9. Enum (enumerated types)
///   10. Variable-length (vlen sequences)
///   11. Array (fixed-size multi-dimensional arrays)
/// - Supports chunked data, compression, and caching
/// - Provides detailed statistics and summaries
/// - Gracefully handles errors and corrupted data
///
/// Note: Images are stored as regular numeric arrays (2D/3D/4D) with optional
/// attributes describing image properties. There is no separate "image" datatype.
///
/// This is a production-ready example showing best practices for HDF5 reading.
Future<void> main(List<String> args) async {
  //'test/fixtures/compound_test.h5'
  //'example/data/test_chunked.h5'
  //'test/fixtures/chunked_string_compound_test.h5'
  // 'example/data/hdf5_test.h5'
  // 'example/data/test_compressed.h5'
  // 'example/data/processdata.h5'
  final filePath = args.isNotEmpty ? args[0] : 'example/data/processdata.h5';

  print('╔═══════════════════════════════════════════════════════════╗');
  print('║        Universal HDF5 File Reader & Analyzer              ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');
  print('File: $filePath\n');

  final reader = UniversalHDF5Reader(filePath);
  await reader.analyze();
}

/// Universal HDF5 Reader with automatic type detection and handling
class UniversalHDF5Reader {
  final String filePath;
  late Hdf5File file;

  // Statistics
  int datasetsRead = 0;
  int datasetsFailed = 0;
  int groupsProcessed = 0;
  int attributesRead = 0;
  final Map<String, int> datatypeStats = {};
  final Map<String, dynamic> dataCache = {};

  UniversalHDF5Reader(this.filePath);

  /// Main analysis entry point
  Future<void> analyze() async {
    Hdf5File? openedFile;

    try {
      openedFile = await Hdf5File.open(filePath);
      file = openedFile;

      // Phase 1: File Overview
      await _printFileOverview();

      // Phase 2: Recursive Group and Dataset Analysis
      print('\n${'═' * 60}');
      print('DETAILED ANALYSIS');
      print('${'═' * 60}\n');
      await _analyzeGroup(file.root, '/');

      // Phase 3: Summary
      _printSummary();
    } catch (e, stackTrace) {
      print('❌ Error opening file: $e');

      // Check if it's an HDF4 file
      if (e.toString().contains('Invalid HDF5 signature')) {
        final isHdf4 = await _checkIfHdf4(filePath);

        if (isHdf4) {
          print('\n💡 Detected: This is an HDF4 file, not HDF5!');
          print('   HDF4 and HDF5 are completely different formats.');
          print('   This reader only supports HDF5 files (.h5, .hdf5).');
          print('\n   To work with HDF4 files:');
          print('   1. Convert to HDF5 using: h4toh5 <input.hdf> <output.h5>');
          print('   2. Use HDF4-specific libraries (e.g., pyhdf for Python)');
          print('   3. Use HDFView which supports both formats');
        } else if (filePath.toLowerCase().endsWith('.hdf')) {
          print('\n💡 Note: File has .hdf extension (typically HDF4).');
          print('   This reader only supports HDF5 files (.h5, .hdf5).');
        }
      }

      // Don't print full stack trace for known errors
      if (!e.toString().contains('HDF5 Error')) {
        print('Stack trace: $stackTrace');
      }
    } finally {
      if (openedFile != null) {
        await openedFile.close();
      }
    }
  }

  /// Print file overview and statistics
  Future<void> _printFileOverview() async {
    print('FILE OVERVIEW');
    print('─' * 60);

    // Superblock information
    final sb = file.superblock;
    print('📄 Superblock:');
    print('   Version: ${sb.version}');
    print('   Offset Size: ${sb.offsetSize} bytes');
    print('   Length Size: ${sb.lengthSize} bytes');
    print('   HDF5 start offset: ${sb.hdf5StartOffset}');
    print(
        '   Root group address: 0x${sb.rootGroupObjectHeaderAddress.toRadixString(16)}');

    if (sb.freeSpaceVersion != 0 ||
        sb.rootGroupVersion != 0 ||
        sb.sharedHeaderVersion != 0) {
      print('   Component Versions:');
      print('      Free Space: ${sb.freeSpaceVersion}');
      print('      Root Group: ${sb.rootGroupVersion}');
      print('      Shared Header: ${sb.sharedHeaderVersion}');
    }
    if (sb.version <= 1) {
      print('   Legacy Format (v0/v1):');
      if (sb.freeSpaceInfoAddress != null &&
          sb.freeSpaceInfoAddress != 0xFFFFFFFFFFFFFFFF) {
        print(
            '      Free Space Info: 0x${sb.freeSpaceInfoAddress!.toRadixString(16)}');
      }
      if (sb.driverInfoBlockAddress != null &&
          sb.driverInfoBlockAddress != 0xFFFFFFFFFFFFFFFF) {
        print(
            '      Driver Info Block: 0x${sb.driverInfoBlockAddress!.toRadixString(16)}');
      }
      if (sb.rootGroupSymbolTableAddress != null) {
        print(
            '      Root Symbol Table: 0x${sb.rootGroupSymbolTableAddress!.toRadixString(16)}');
      }
    }
    print('');

    final stats = await file.getSummaryStats();

    print('📊 Statistics:');
    print('   Total Datasets: ${stats['totalDatasets']}');
    print('   Total Groups: ${stats['totalGroups']}');
    print('   Max Depth: ${stats['maxDepth']}');
    print('   Compressed Datasets: ${stats['compressedDatasets']}');
    print('   Chunked Datasets: ${stats['chunkedDatasets']}');

    if (stats['datasetsByType'] != null) {
      final typeMap = stats['datasetsByType'] as Map<String, int>;
      if (typeMap.isNotEmpty) {
        print('\n📋 Dataset Types:');
        typeMap.forEach((type, count) {
          print('   • $type: $count');
        });
      }
    }

    // Root attributes
    final rootAttrs = file.root.attributes;
    if (rootAttrs.isNotEmpty) {
      print('\n🏷️  Root Attributes:');
      for (final attr in rootAttrs) {
        print('   ${attr.name}: ${_formatValue(attr.value)}');
      }
    }
  }

  /// Recursively analyze groups and their contents
  Future<void> _analyzeGroup(Group group, String path) async {
    groupsProcessed++;

    print('\n📁 Group: $path');
    print('   ${'─' * 55}');

    // Group attributes
    final attrs = group.attributes;
    if (attrs.isNotEmpty) {
      print('   Attributes:');
      for (final attr in attrs) {
        attributesRead++;
        print('   • ${attr.name}: ${_formatValue(attr.value)}');
      }
    }

    // Process children
    final children = group.children;
    if (children.isEmpty) {
      print('   (empty group)');
      return;
    }

    print('   Children: ${children.length}');

    // Get all paths from structure to determine what's a group vs dataset
    final structure = await file.listRecursive();

    for (final childName in children) {
      final childPath = path == '/' ? '/$childName' : '$path/$childName';

      // Check if it's a group or dataset from structure
      if (structure.containsKey(childPath)) {
        final info = structure[childPath]!;

        if (info['type'] == 'dataset') {
          try {
            final dataset = await file.dataset(childPath);
            await _analyzeDataset(dataset, childPath);
          } catch (e) {
            print('\n   ⚠️  Could not read dataset: $childName');
            print('      Error: ${e.toString().split('\n').first}');
            datasetsFailed++;
          }
        } else if (info['type'] == 'group') {
          // Recursively process nested groups
          await _analyzeNestedGroup(childPath, structure);
        }
      }
    }
  }

  /// Analyze nested group (workaround since we can't get Group objects directly)
  Future<void> _analyzeNestedGroup(
      String groupPath, Map<String, Map<String, dynamic>> structure) async {
    groupsProcessed++;

    print('\n📁 Group: $groupPath');
    print('   ${'─' * 55}');

    // Find all direct children of this group
    final children = structure.keys.where((path) {
      if (path == groupPath) return false;
      final parentPath = path.substring(0, path.lastIndexOf('/'));
      return parentPath == groupPath;
    }).toList();

    if (children.isEmpty) {
      print('   (empty group)');
      return;
    }

    print('   Children: ${children.length}');

    for (final childPath in children) {
      final info = structure[childPath]!;

      if (info['type'] == 'dataset') {
        try {
          final dataset = await file.dataset(childPath);
          await _analyzeDataset(dataset, childPath);
        } catch (e) {
          print(
              '\n   ⚠️  Could not read dataset: ${childPath.split('/').last}');
          print('      Error: ${e.toString().split('\n').first}');
          datasetsFailed++;
        }
      } else if (info['type'] == 'group') {
        await _analyzeNestedGroup(childPath, structure);
      }
    }
  }

  /// Analyze and read a dataset
  Future<void> _analyzeDataset(Dataset dataset, String path) async {
    print('\n   📊 Dataset: ${path.split('/').last}');
    print('      ${'┄' * 50}');

    final datatype = dataset.datatype;
    final dataspace = dataset.dataspace;
    final info = dataset.inspect();

    // Basic info
    print('      Type: ${datatype.typeName}');
    print('      Shape: ${dataspace.dimensions}');
    print('      Elements: ${dataspace.totalElements}');
    print('      Storage: ${info['storage']}');

    // Detect image-like datasets
    if (_looksLikeImage(dataspace.dimensions, datatype)) {
      print(
          '      📷 Likely Image Data: ${_describeImageFormat(dataspace.dimensions)}');
    }

    // Track datatype statistics
    final typeName = datatype.typeName;
    datatypeStats[typeName] = (datatypeStats[typeName] ?? 0) + 1;

    // Chunking info
    if (info.containsKey('chunkDimensions')) {
      final chunkDims = info['chunkDimensions'] as List<int>;
      final chunkSize = chunkDims.fold<int>(1, (a, b) => a * b) * datatype.size;
      print('      Chunked: $chunkDims (${_formatBytes(chunkSize)})');
    }

    // Compression info
    if (info.containsKey('compression')) {
      print('      Compression: ${info['compression']}');
    }

    // Attributes
    final attrs = dataset.attributes;
    if (attrs.isNotEmpty) {
      print('      Attributes: ${attrs.length}');
      for (final attr in attrs) {
        attributesRead++;
        print('         • ${attr.name}: ${_formatValue(attr.value)}');
      }
    }

    // Type-specific details
    _printDatatypeDetails(datatype);

    // Read data
    await _readAndDisplayData(dataset, path);
  }

  /// Print datatype-specific details
  void _printDatatypeDetails(Hdf5Datatype datatype) {
    // Check for time datatype
    if (datatype.isTime) {
      print('      Time/Date datatype');
    }

    // Check for bitfield datatype
    if (datatype.isBitfield) {
      print('      Bitfield datatype');
    }

    if (datatype.isString && datatype.stringInfo != null) {
      final strInfo = datatype.stringInfo!;
      print('      String: ${strInfo.characterSet}, ${strInfo.paddingType}');
      if (strInfo.isVariableLength) {
        print('      Variable-length string');
      }
    }

    if (datatype.isCompound && datatype.compoundInfo != null) {
      final compInfo = datatype.compoundInfo!;
      print('      Compound Fields: ${compInfo.fields.length}');
      for (final field in compInfo.fields) {
        print(
            '         • ${field.name}: ${field.datatype.typeName} @ offset ${field.offset}');
      }
    }

    if (datatype.isArray && datatype.arrayInfo != null) {
      final arrInfo = datatype.arrayInfo!;
      print(
          '      Array: ${arrInfo.dimensions} of ${datatype.baseType?.typeName}');
    }

    if (datatype.isEnum && datatype.enumInfo != null) {
      final enumInfo = datatype.enumInfo!;
      print('      Enum Values: ${enumInfo.members.length}');
      for (final member in enumInfo.members.take(5)) {
        print('         • ${member.name} = ${member.value}');
      }
      if (enumInfo.members.length > 5) {
        print('         ... and ${enumInfo.members.length - 5} more');
      }
    }

    if (datatype.isReference && datatype.referenceInfo != null) {
      print('      Reference Type: ${datatype.referenceInfo!.type}');
    }

    if (datatype.isOpaque && datatype.tag != null) {
      print('      Opaque Tag: ${datatype.tag}');
    }
  }

  /// Read and display dataset data with intelligent sampling
  Future<void> _readAndDisplayData(Dataset dataset, String path) async {
    try {
      final totalElements = dataset.dataspace.totalElements;

      // Skip very large datasets (>1M elements) unless explicitly requested
      if (totalElements > 1000000) {
        print('      Data: ($totalElements elements - too large to display)');
        datasetsRead++;
        return;
      }

      // Read data with caching
      final data = await _readDatasetWithCache(path);

      if (data == null) {
        datasetsFailed++;
        return;
      }

      datasetsRead++;

      // Display data based on type and size
      _displayData(data, dataset.datatype, dataset.dataspace.dimensions);
    } catch (e) {
      print('      ⚠️  Error reading data: $e');
      datasetsFailed++;
    }
  }

  /// Read dataset with caching
  Future<dynamic> _readDatasetWithCache(String path) async {
    if (dataCache.containsKey(path)) {
      print('      Data: (cached)');
      return dataCache[path];
    }

    try {
      final data = await file.readDataset(path);
      dataCache[path] = data;
      return data;
    } catch (e) {
      // Extract the main error message
      final errorStr = e.toString();
      final lines = errorStr.split('\n');

      // For HDF5 errors, show the message line
      if (errorStr.contains('HDF5 Error')) {
        final messageLine = lines.firstWhere(
          (line) => line.contains('Message:'),
          orElse: () => lines.first,
        );
        print(
            '      ⚠️  Read failed: ${messageLine.replaceAll('Message:', '').trim()}');

        // Show details if available
        final detailsLine =
            lines.where((line) => line.contains('Details:')).firstOrNull;
        if (detailsLine != null) {
          print('         ${detailsLine.trim()}');
        }
      } else {
        print('      ⚠️  Read failed: ${lines.first}');
      }
      return null;
    }
  }

  /// Display data intelligently based on type and size
  void _displayData(dynamic data, Hdf5Datatype datatype, List<int> shape) {
    if (data is! List) {
      print('      Data: $data');
      return;
    }

    final totalElements = shape.fold<int>(1, (a, b) => a * b);

    // For small datasets, show all data
    if (totalElements <= 10) {
      print('      Data:');
      _printDataRecursive(data, '         ');
      return;
    }

    // For larger datasets, show sample
    print('      Data Sample:');

    if (shape.length == 1) {
      // 1D array
      _print1DSample(data);
    } else if (shape.length == 2) {
      // 2D array
      _print2DSample(data, shape);
    } else if (shape.length >= 3) {
      // 3D+ array
      _printNDSample(data, shape);
    }

    // Statistics for numeric data
    if (datatype.dataclass == Hdf5DatatypeClass.integer ||
        datatype.dataclass == Hdf5DatatypeClass.float) {
      _printNumericStats(data);
    }
  }

  /// Print 1D data sample
  void _print1DSample(List data) {
    final sampleSize = data.length < 5 ? data.length : 5;
    for (var i = 0; i < sampleSize; i++) {
      print('         [$i]: ${_formatValue(data[i])}');
    }
    if (data.length > sampleSize) {
      print('         ... (${data.length - sampleSize} more elements)');
    }
  }

  /// Print 2D data sample
  void _print2DSample(List data, List<int> shape) {
    final rows = shape[0] < 3 ? shape[0] : 3;
    final cols = shape[1] < 5 ? shape[1] : 5;

    for (var i = 0; i < rows; i++) {
      final row = data[i] is List ? data[i] as List : [data[i]];
      final sample = row.take(cols).map((v) => _formatValue(v)).join(', ');
      print('         Row $i: [$sample${row.length > cols ? ', ...' : ''}]');
    }
    if (shape[0] > rows) {
      print('         ... (${shape[0] - rows} more rows)');
    }
  }

  /// Print N-dimensional data sample
  void _printNDSample(List data, List<int> shape) {
    print('         Shape: $shape');
    print('         First element: ${_formatValue(_getFirstElement(data))}');
    print('         (${shape.fold<int>(1, (a, b) => a * b)} total elements)');
  }

  /// Get first element from nested list
  dynamic _getFirstElement(dynamic data) {
    while (data is List && data.isNotEmpty) {
      data = data[0];
    }
    return data;
  }

  /// Print data recursively (for small datasets)
  void _printDataRecursive(dynamic data, String indent) {
    if (data is List) {
      for (var i = 0; i < data.length; i++) {
        if (data[i] is List || data[i] is Map) {
          print('$indent[$i]:');
          _printDataRecursive(data[i], '$indent   ');
        } else {
          print('$indent[$i]: ${_formatValue(data[i])}');
        }
      }
    } else if (data is Map) {
      data.forEach((key, value) {
        if (value is List || value is Map) {
          print('$indent$key:');
          _printDataRecursive(value, '$indent   ');
        } else {
          print('$indent$key: ${_formatValue(value)}');
        }
      });
    } else {
      print('$indent${_formatValue(data)}');
    }
  }

  /// Print numeric statistics
  void _printNumericStats(dynamic data) {
    try {
      final numbers = _flattenToNumbers(data);
      if (numbers.isEmpty) return;

      final sum = numbers.fold<double>(0, (a, b) => a + b);
      final mean = sum / numbers.length;
      final min = numbers.reduce((a, b) => a < b ? a : b);
      final max = numbers.reduce((a, b) => a > b ? a : b);

      // Calculate standard deviation
      final variance = numbers.fold<double>(
              0, (sum, val) => sum + (val - mean) * (val - mean)) /
          numbers.length;
      final stdDev = math.sqrt(variance);

      print('      Statistics:');
      print('         Mean: ${mean.toStringAsFixed(4)}');
      print('         Std Dev: ${stdDev.toStringAsFixed(4)}');
      print('         Min: $min');
      print('         Max: $max');
    } catch (e) {
      // Skip statistics if data can't be processed
    }
  }

  /// Flatten nested lists to numbers
  List<num> _flattenToNumbers(dynamic data) {
    final result = <num>[];

    void flatten(dynamic item) {
      if (item is num) {
        result.add(item);
      } else if (item is List) {
        for (final element in item) {
          flatten(element);
        }
      }
    }

    flatten(data);
    return result;
  }

  /// Format value for display
  String _formatValue(dynamic value) {
    if (value is String) {
      return value.length > 50 ? '"${value.substring(0, 47)}..."' : '"$value"';
    } else if (value is double) {
      return value.toStringAsFixed(4);
    } else if (value is Map) {
      final entries =
          value.entries.take(3).map((e) => '${e.key}: ${e.value}').join(', ');
      return '{$entries${value.length > 3 ? ', ...' : ''}}';
    } else if (value is List) {
      if (value.isEmpty) return '[]';
      final sample = value.take(3).map((v) => _formatValue(v)).join(', ');
      return '[$sample${value.length > 3 ? ', ...' : ''}]';
    }
    return value.toString();
  }

  /// Format bytes in human-readable format
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Check if file is HDF4 format
  Future<bool> _checkIfHdf4(String path) async {
    try {
      final fileIO = FileIO();
      final raf = await fileIO.openRandomAccess(path);

      try {
        // HDF4 files start with 0x0E031301 or 0x0E031302
        final bytes = await raf.read(4);
        if (bytes.length >= 4) {
          // Check for HDF4 magic numbers
          if ((bytes[0] == 0x0E && bytes[1] == 0x03 && bytes[2] == 0x13) ||
              (bytes[0] == 0x89 &&
                  bytes[1] == 0x48 &&
                  bytes[2] == 0x44 &&
                  bytes[3] == 0x46)) {
            // Second pattern is actually HDF5, but check more carefully
            if (bytes[0] == 0x0E) {
              return true; // Definitely HDF4
            }
          }
        }
      } finally {
        await raf.close();
      }
    } catch (e) {
      // If we can't read the file, assume not HDF4
    }
    return false;
  }

  /// Check if dataset looks like image data
  bool _looksLikeImage(List<int> shape, Hdf5Datatype datatype) {
    // Images are typically 2D or 3D numeric arrays
    if (shape.length < 2 || shape.length > 4) return false;

    // Must be integer or float type
    if (datatype.dataclass != Hdf5DatatypeClass.integer &&
        datatype.dataclass != Hdf5DatatypeClass.float) {
      return false;
    }

    // Common image dimensions
    if (shape.length == 2) {
      // Grayscale: height × width
      return shape[0] > 1 && shape[1] > 1;
    } else if (shape.length == 3) {
      // RGB/RGBA: height × width × channels (or channels × height × width)
      final hasChannelDim = shape.any((d) => d == 1 || d == 3 || d == 4);
      return hasChannelDim && shape.every((d) => d > 0);
    } else if (shape.length == 4) {
      // Image sequence: frames × height × width × channels
      return shape.every((d) => d > 0);
    }

    return false;
  }

  /// Describe image format based on shape
  String _describeImageFormat(List<int> shape) {
    if (shape.length == 2) {
      return 'Grayscale ${shape[0]}×${shape[1]}';
    } else if (shape.length == 3) {
      // Try to determine channel position
      if (shape[2] == 1) {
        return 'Grayscale ${shape[0]}×${shape[1]}';
      } else if (shape[2] == 3) {
        return 'RGB ${shape[0]}×${shape[1]}';
      } else if (shape[2] == 4) {
        return 'RGBA ${shape[0]}×${shape[1]}';
      } else if (shape[0] == 3) {
        return 'RGB ${shape[1]}×${shape[2]}';
      } else if (shape[0] == 4) {
        return 'RGBA ${shape[1]}×${shape[2]}';
      }
      return '${shape[0]}×${shape[1]}×${shape[2]}';
    } else if (shape.length == 4) {
      return 'Sequence ${shape[0]} frames of ${shape[1]}×${shape[2]}×${shape[3]}';
    }
    return shape.join('×');
  }

  /// Print final summary
  void _printSummary() {
    print('\n${'═' * 60}');
    print('SUMMARY');
    print('${'═' * 60}\n');

    print('✓ Groups Processed: $groupsProcessed');
    print('✓ Datasets Read: $datasetsRead');
    if (datasetsFailed > 0) {
      print('⚠️  Datasets Failed: $datasetsFailed');
    }
    print('✓ Attributes Read: $attributesRead');
    print('✓ Cached Items: ${dataCache.length}');

    if (datatypeStats.isNotEmpty) {
      print('\n📊 Datatypes Encountered:');
      datatypeStats.forEach((type, count) {
        print('   • $type: $count');
      });
    }

    print('\n${'═' * 60}');
    print('Analysis Complete!');
    print('═' * 60);
  }
}
