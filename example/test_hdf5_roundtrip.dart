import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// HDF5 Round-trip Test
///
/// This script:
/// 1. Reads an existing HDF5 file
/// 2. Writes the data to a new HDF5 file
/// 3. Reads the new file back
/// 4. Compares structure and data between original and recreated files
///
/// This validates that the HDF5 writer produces correct, readable files.
Future<void> main(List<String> args) async {
  final inputFile = args.isNotEmpty ? args[0] : 'example/data/test_chunked.h5';
  final outputFile =
      args.length > 1 ? args[1] : 'example/data/test_roundtrip_output.h5';

  print('╔═══════════════════════════════════════════════════════════╗');
  print('║           HDF5 Round-trip Validation Test                 ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');

  print('Input:  $inputFile');
  print('Output: $outputFile\n');

  try {
    // Phase 1: Read original file
    print('═' * 60);
    print('PHASE 1: Reading Original File');
    print('${'═' * 60}\n');

    final originalData = await readHDF5File(inputFile);

    if (originalData.isEmpty) {
      print('❌ No datasets found in original file');
      return;
    }

    print('✓ Read ${originalData.length} dataset(s) from original file\n');

    // Phase 2: Write to new file
    print('═' * 60);
    print('PHASE 2: Writing to New File');
    print('${'═' * 60}\n');

    await writeHDF5File(outputFile, originalData);

    print('✓ Wrote data to new file\n');

    // Phase 3: Read back the new file
    print('═' * 60);
    print('PHASE 3: Reading New File');
    print('${'═' * 60}\n');

    final recreatedData = await readHDF5File(outputFile);

    if (recreatedData.isEmpty) {
      print('❌ No datasets found in recreated file');
      return;
    }

    print('✓ Read ${recreatedData.length} dataset(s) from recreated file\n');

    // Phase 4: Compare
    print('═' * 60);
    print('PHASE 4: Comparing Files');
    print('${'═' * 60}\n');

    final comparison = compareData(originalData, recreatedData);

    // Print results
    print('\n${'═' * 60}');
    print('RESULTS');
    print('${'═' * 60}\n');

    if (comparison['success'] == true) {
      print('✅ SUCCESS: Files match!');
      print('   • All datasets present');
      print('   • All shapes match');
      print('   • All data values match');
      print('   • All attributes match');
    } else {
      print('❌ FAILURE: Files differ');
      if (comparison['errors'] != null) {
        print('\nErrors:');
        for (final error in comparison['errors'] as List<String>) {
          print('   • $error');
        }
      }
    }

    // File size comparison
    final originalSize = await File(inputFile).length();
    final recreatedSize = await File(outputFile).length();
    print('\nFile Sizes:');
    print('   Original:  ${_formatBytes(originalSize)}');
    print('   Recreated: ${_formatBytes(recreatedSize)}');
    print(
        '   Difference: ${_formatBytes((recreatedSize - originalSize).abs())} '
        '(${((recreatedSize - originalSize) / originalSize * 100).toStringAsFixed(1)}%)');
  } catch (e, stackTrace) {
    print('❌ Error during round-trip test: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Read all datasets from an HDF5 file
Future<Map<String, DatasetInfo>> readHDF5File(String filePath) async {
  final result = <String, DatasetInfo>{};
  Hdf5File? file;

  try {
    file = await Hdf5File.open(filePath);

    // Get file structure
    final structure = await file.listRecursive();

    print('File structure:');
    structure.forEach((path, info) {
      print('   $path: ${info['type']}');
    });
    print('');

    // Read all datasets
    for (final entry in structure.entries) {
      final path = entry.key;
      final info = entry.value;

      if (info['type'] == 'dataset') {
        try {
          final dataset = await file.dataset(path);
          final data = await file.readDataset(path);

          result[path] = DatasetInfo(
            path: path,
            data: data,
            shape: dataset.dataspace.dimensions,
            datatype: dataset.datatype,
            attributes: _extractAttributes(dataset.attributes),
          );

          print('✓ Read dataset: $path');
          print('   Shape: ${dataset.dataspace.dimensions}');
          print('   Type: ${dataset.datatype.typeName}');
          if (dataset.attributes.isNotEmpty) {
            print('   Attributes: ${dataset.attributes.length}');
          }
        } catch (e) {
          print('⚠️  Could not read dataset $path: $e');
        }
      }
    }
  } finally {
    await file?.close();
  }

  return result;
}

/// Write datasets to a new HDF5 file
Future<void> writeHDF5File(
    String filePath, Map<String, DatasetInfo> datasets) async {
  // For now, we can only write one dataset at a time with the current writer
  // So we'll write the first dataset we find

  if (datasets.isEmpty) {
    print('⚠️  No datasets to write');
    return;
  }

  // Get the first dataset
  final firstDataset = datasets.values.first;

  print('Writing dataset: ${firstDataset.path}');
  print('   Shape: ${firstDataset.shape}');
  print('   Type: ${firstDataset.datatype.typeName}');

  // Convert data to NDArray
  final array = _convertToNDArray(firstDataset.data, firstDataset.shape);

  if (array == null) {
    print('❌ Could not convert data to NDArray');
    return;
  }

  // Write using NDArrayHDF5Writer
  try {
    // Add attributes to the array
    firstDataset.attributes.forEach((key, value) {
      array.attrs[key] = value;
    });

    await array.toHDF5(
      filePath,
      dataset: firstDataset.path,
    );

    print('✓ Wrote dataset successfully');

    if (firstDataset.attributes.isNotEmpty) {
      print('   Attributes written: ${firstDataset.attributes.length}');
      firstDataset.attributes.forEach((key, value) {
        print('      • $key: $value');
      });
    }
  } catch (e) {
    print('❌ Error writing dataset: $e');
    rethrow;
  }
}

/// Convert data to NDArray
NDArray? _convertToNDArray(dynamic data, List<int> shape) {
  try {
    // Flatten the data
    final flatData = _flattenData(data);

    if (flatData.isEmpty) {
      print('⚠️  Empty data');
      return null;
    }

    // Check data type
    final firstValue = flatData.first;

    if (firstValue is double) {
      return NDArray.fromFlat(flatData.cast<double>(), shape);
    } else if (firstValue is int) {
      // Convert ints to doubles for now (HDF5 writer supports float64 and int64)
      return NDArray.fromFlat(
          flatData.map((v) => (v as int).toDouble()).toList(), shape);
    } else {
      print('⚠️  Unsupported data type: ${firstValue.runtimeType}');
      return null;
    }
  } catch (e) {
    print('⚠️  Error converting to NDArray: $e');
    return null;
  }
}

/// Flatten nested list data
List<num> _flattenData(dynamic data) {
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

/// Extract attributes from dataset
Map<String, dynamic> _extractAttributes(List<Hdf5Attribute> attributes) {
  final result = <String, dynamic>{};

  for (final attr in attributes) {
    result[attr.name] = attr.value;
  }

  return result;
}

/// Compare two datasets
Map<String, dynamic> compareData(
  Map<String, DatasetInfo> original,
  Map<String, DatasetInfo> recreated,
) {
  final errors = <String>[];

  print('Comparing datasets...\n');

  // Check dataset count
  if (original.length != recreated.length) {
    errors.add(
        'Dataset count mismatch: ${original.length} vs ${recreated.length}');
  }

  // Compare each dataset
  for (final entry in original.entries) {
    final path = entry.key;
    final origData = entry.value;

    print('Checking dataset: $path');

    if (!recreated.containsKey(path)) {
      errors.add('Dataset missing in recreated file: $path');
      print('   ❌ Missing in recreated file');
      continue;
    }

    final recData = recreated[path]!;

    // Compare shapes
    if (!_listsEqual(origData.shape, recData.shape)) {
      errors.add(
          'Shape mismatch for $path: ${origData.shape} vs ${recData.shape}');
      print('   ❌ Shape mismatch: ${origData.shape} vs ${recData.shape}');
      continue;
    }
    print('   ✓ Shape matches: ${origData.shape}');

    // Compare data types
    if (origData.datatype.typeName != recData.datatype.typeName) {
      // Allow some flexibility in type names
      print(
          '   ⚠️  Type differs: ${origData.datatype.typeName} vs ${recData.datatype.typeName}');
    } else {
      print('   ✓ Type matches: ${origData.datatype.typeName}');
    }

    // Compare data values
    final dataMatch = _compareValues(origData.data, recData.data);
    if (dataMatch) {
      print('   ✓ Data values match');
    } else {
      errors.add('Data values mismatch for $path');
      print('   ❌ Data values differ');
    }

    // Compare attributes
    final attrMatch =
        _compareAttributes(origData.attributes, recData.attributes);
    if (attrMatch) {
      print('   ✓ Attributes match (${origData.attributes.length})');
    } else {
      errors.add('Attributes mismatch for $path');
      print('   ❌ Attributes differ');
    }

    print('');
  }

  return {
    'success': errors.isEmpty,
    'errors': errors,
  };
}

/// Compare two lists for equality
bool _listsEqual(List a, List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Compare data values with tolerance for floating point
bool _compareValues(dynamic a, dynamic b, {double tolerance = 1e-10}) {
  if (a is num && b is num) {
    if (a is double || b is double) {
      return (a - b).abs() < tolerance;
    }
    return a == b;
  }

  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_compareValues(a[i], b[i], tolerance: tolerance)) {
        return false;
      }
    }
    return true;
  }

  return a == b;
}

/// Compare attributes
bool _compareAttributes(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;

  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    if (!_compareValues(a[key], b[key])) return false;
  }

  return true;
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

/// Dataset information container
class DatasetInfo {
  final String path;
  final dynamic data;
  final List<int> shape;
  final Hdf5Datatype datatype;
  final Map<String, dynamic> attributes;

  DatasetInfo({
    required this.path,
    required this.data,
    required this.shape,
    required this.datatype,
    required this.attributes,
  });
}
