import 'package:dartframe/dartframe.dart';

/// Universal HDF5 File Writer
///
/// A comprehensive HDF5 writer that:
/// - Writes NDArray and DataCube data to HDF5 format
/// - Supports multiple datasets per file
/// - Handles attributes and metadata
/// - Creates files compatible with h5py, MATLAB, and R
/// - Provides detailed progress and validation
///
/// This mirrors the capabilities of the universal reader and demonstrates
/// best practices for HDF5 writing.
Future<void> main(List<String> args) async {
  final outputPath =
      args.isNotEmpty ? args[0] : 'example/data/test_writer_output.h5';

  print('╔═══════════════════════════════════════════════════════════╗');
  print('║        Universal HDF5 File Writer & Validator             ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');
  print('Output: $outputPath\n');

  final writer = UniversalHDF5Writer(outputPath);
  await writer.write();
}

/// Universal HDF5 Writer with validation and progress tracking
class UniversalHDF5Writer {
  final String filePath;

  // Statistics
  int datasetsWritten = 0;
  int datasetsFailed = 0;
  int attributesWritten = 0;
  final Map<String, int> datatypeStats = {};

  UniversalHDF5Writer(this.filePath);

  /// Main write entry point
  Future<void> write() async {
    try {
      // Phase 1: Create sample data
      print('═' * 60);
      print('PHASE 1: Creating Sample Data');
      print('═' * 60);
      print('');

      final datasets = _createSampleDatasets();

      print('✓ Created ${datasets.length} sample datasets\n');

      // Phase 2: Write datasets
      print('═' * 60);
      print('PHASE 2: Writing to HDF5 File');
      print('═' * 60);
      print('');

      for (final dataset in datasets) {
        await _writeDataset(dataset);
      }

      // Phase 3: Validate by reading back
      print('\n═' * 60);
      print('PHASE 3: Validation');
      print('═' * 60);
      print('');

      await _validateFile();

      // Phase 4: Summary
      _printSummary();
    } catch (e, stackTrace) {
      print('❌ Error during write: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Create sample datasets for demonstration
  List<DatasetSpec> _createSampleDatasets() {
    final datasets = <DatasetSpec>[];

    // 1D array - simple vector
    print('Creating 1D array (vector)...');
    final array1d = NDArray.fromFlat(
      List.generate(10, (i) => (i + 1).toDouble()),
      [10],
    );
    array1d.attrs['description'] = 'Simple 1D vector';
    array1d.attrs['units'] = 'meters';
    datasets.add(DatasetSpec(
      path: '/vector',
      array: array1d,
      description: '1D vector (10 elements)',
    ));

    // 2D array - matrix
    print('Creating 2D array (matrix)...');
    final array2d = NDArray.fromFlat(
      List.generate(20, (i) => (i + 1).toDouble()),
      [4, 5],
    );
    array2d.attrs['description'] = 'Sample 2D matrix';
    array2d.attrs['rows'] = 4;
    array2d.attrs['cols'] = 5;
    datasets.add(DatasetSpec(
      path: '/matrix',
      array: array2d,
      description: '2D matrix (4×5)',
    ));

    // 3D array - cube
    print('Creating 3D array (cube)...');
    final array3d = NDArray.fromFlat(
      List.generate(24, (i) => (i + 1).toDouble()),
      [2, 3, 4],
    );
    array3d.attrs['description'] = 'Sample 3D cube';
    array3d.attrs['dimensions'] = '2×3×4';
    datasets.add(DatasetSpec(
      path: '/cube',
      array: array3d,
      description: '3D cube (2×3×4)',
    ));

    // Large array
    print('Creating large array...');
    final arrayLarge = NDArray.fromFlat(
      List.generate(1000, (i) => i.toDouble()),
      [100, 10],
    );
    arrayLarge.attrs['description'] = 'Large dataset for performance testing';
    arrayLarge.attrs['size'] = '100×10';
    datasets.add(DatasetSpec(
      path: '/large',
      array: arrayLarge,
      description: 'Large array (100×10)',
    ));

    // Integer array
    print('Creating integer array...');
    final arrayInt = NDArray.fromFlat(
      List.generate(15, (i) => i),
      [3, 5],
    );
    arrayInt.attrs['description'] = 'Integer data';
    arrayInt.attrs['type'] = 'int64';
    datasets.add(DatasetSpec(
      path: '/integers',
      array: arrayInt,
      description: 'Integer array (3×5)',
    ));

    return datasets;
  }

  /// Write a single dataset to the file
  Future<void> _writeDataset(DatasetSpec spec) async {
    try {
      print('Writing dataset: ${spec.path}');
      print('   Description: ${spec.description}');
      print('   Shape: ${spec.array.shape}');
      print('   Type: ${_getDataType(spec.array)}');
      print('   Attributes: ${spec.array.attrs.length}');

      // Track datatype
      final dtype = _getDataType(spec.array);
      datatypeStats[dtype] = (datatypeStats[dtype] ?? 0) + 1;

      // Write the dataset
      await spec.array.toHDF5(filePath, dataset: spec.path);

      datasetsWritten++;
      attributesWritten += spec.array.attrs.length;

      print('   ✓ Written successfully\n');
    } catch (e) {
      print('   ❌ Failed: $e\n');
      datasetsFailed++;
    }
  }

  /// Validate the written file by reading it back
  Future<void> _validateFile() async {
    print('Opening file for validation...\n');

    Hdf5File? file;
    try {
      file = await Hdf5File.open(filePath);

      // Check file structure
      final structure = await file.listRecursive();

      print('File structure:');
      if (structure.isEmpty) {
        print('   ❌ File is empty!');
        return;
      }

      structure.forEach((path, info) {
        print('   $path: ${info['type']}');
      });
      print('');

      // Validate each dataset
      var validCount = 0;
      var invalidCount = 0;

      for (final entry in structure.entries) {
        if (entry.value['type'] == 'dataset') {
          final path = entry.key;
          try {
            final dataset = await file.dataset(path);
            final data = await file.readDataset(path);

            print('✓ Validated dataset: $path');
            print('   Shape: ${dataset.dataspace.dimensions}');
            print('   Type: ${dataset.datatype.typeName}');
            print('   Attributes: ${dataset.attributes.length}');

            // Show sample data
            if (data.isNotEmpty) {
              final sample = _formatSample(data);
              print('   Sample: $sample');
            }

            validCount++;
          } catch (e) {
            print('❌ Failed to validate $path: $e');
            invalidCount++;
          }
          print('');
        }
      }

      print('Validation Summary:');
      print('   ✓ Valid datasets: $validCount');
      if (invalidCount > 0) {
        print('   ❌ Invalid datasets: $invalidCount');
      }
    } catch (e) {
      print('❌ Error opening file for validation: $e');
    } finally {
      await file?.close();
    }
  }

  /// Get data type string from array
  String _getDataType(NDArray array) {
    final firstValue = array.getValue(List.filled(array.ndim, 0));
    if (firstValue is double) {
      return 'float64';
    } else if (firstValue is int) {
      return 'int64';
    } else {
      return 'unknown';
    }
  }

  /// Format sample data for display
  String _formatSample(dynamic data) {
    if (data is List) {
      if (data.isEmpty) return '[]';
      if (data.length <= 5) {
        return data.map((v) => _formatValue(v)).join(', ');
      } else {
        final sample = data.take(3).map((v) => _formatValue(v)).join(', ');
        return '$sample, ... (${data.length} total)';
      }
    }
    return _formatValue(data);
  }

  /// Format a single value for display
  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    } else if (value is List) {
      if (value.isEmpty) return '[]';
      if (value.length <= 3) {
        return '[${value.map((v) => _formatValue(v)).join(', ')}]';
      } else {
        return '[${_formatValue(value[0])}, ...]';
      }
    }
    return value.toString();
  }

  /// Print final summary
  void _printSummary() {
    print('\n═' * 60);
    print('SUMMARY');
    print('═' * 60);
    print('');

    print('✓ Datasets Written: $datasetsWritten');
    if (datasetsFailed > 0) {
      print('❌ Datasets Failed: $datasetsFailed');
    }
    print('✓ Attributes Written: $attributesWritten');

    if (datatypeStats.isNotEmpty) {
      print('\n📊 Datatypes Written:');
      datatypeStats.forEach((type, count) {
        print('   • $type: $count');
      });
    }

    print('\n═' * 60);
    if (datasetsFailed == 0) {
      print('✅ Write Complete - All datasets written successfully!');
    } else {
      print('⚠️  Write Complete - Some datasets failed');
    }
    print('═' * 60);
  }
}

/// Specification for a dataset to write
class DatasetSpec {
  final String path;
  final NDArray array;
  final String description;

  DatasetSpec({
    required this.path,
    required this.array,
    required this.description,
  });
}
