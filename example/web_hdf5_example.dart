// Example of using HDF5 on web platform
// This demonstrates how to read HDF5 files in a web browser

import 'dart:typed_data';
import 'package:dartframe/dartframe.dart';

// Note: In a real web app, you would use dart:html
// This example shows the API usage

/// Example 1: Opening HDF5 from file input element
///
/// In your HTML:
/// ```html
/// <input type="file" id="fileInput" accept=".h5,.hdf5">
/// ```
///
/// In your Dart code:
/// ```dart
/// import 'dart:html';
///
/// void setupFileInput() {
///   final fileInput = querySelector('#fileInput') as InputElement;
///
///   fileInput.onChange.listen((event) async {
///     try {
///       // Same API as desktop! Just pass the input element
///       final file = await Hdf5File.open(
///         fileInput,
///         fileName: fileInput.files!.first.name,
///       );
///
///       await processHdf5File(file);
///       await file.close();
///     } catch (e) {
///       print('Error opening file: $e');
///     }
///   });
/// }
/// ```

/// Example 2: Opening HDF5 from bytes
Future<void> openFromBytes(Uint8List bytes) async {
  // Open HDF5 file from pre-loaded bytes - same API!
  final file = await Hdf5File.open(bytes, fileName: 'data.h5');

  try {
    // Display file structure
    print('Root children: ${file.root.children}');

    // List all datasets and groups
    final structure = await file.listRecursive();
    print('\nFile structure:');
    for (final entry in structure.entries) {
      final path = entry.key;
      final info = entry.value;
      print('  $path: ${info['type']}');
      if (info['type'] == 'dataset') {
        print('    Shape: ${info['shape']}');
        print('    Type: ${info['dtype']}');
      }
    }

    // Read a specific dataset
    if (structure.containsKey('/data')) {
      print('\nReading /data dataset...');
      final data = await file.readDataset('/data');
      print('Data length: ${data.length}');
      print('First few values: ${data.take(5).toList()}');
    }

    // Read dataset in chunks (for large datasets)
    if (structure.containsKey('/large_data')) {
      print('\nReading /large_data in chunks...');
      var totalElements = 0;
      await for (final chunk
          in file.readDatasetChunked('/large_data', chunkSize: 1000)) {
        totalElements += chunk.length;
        print('  Processed chunk: ${chunk.length} elements');
      }
      print('Total elements: $totalElements');
    }
  } finally {
    await file.close();
  }
}

/// Example 3: Processing HDF5 file with error handling
Future<Map<String, dynamic>> analyzeHdf5File(Uint8List bytes) async {
  Hdf5File? file;

  try {
    // Open file - same API!
    file = await Hdf5File.open(bytes, fileName: 'analysis.h5');

    // Get summary statistics
    final stats = await file.getSummaryStats();
    print('File statistics:');
    print('  Total datasets: ${stats['totalDatasets']}');
    print('  Total groups: ${stats['totalGroups']}');
    print('  Max depth: ${stats['maxDepth']}');
    print('  Compressed datasets: ${stats['compressedDatasets']}');

    // Get file info
    final info = file.info;
    print('\nFile info:');
    print('  HDF5 version: ${info['version']}');
    print('  Offset size: ${info['offsetSize']}');
    print('  Root children: ${info['rootChildren']}');

    return {
      'success': true,
      'stats': stats,
      'info': info,
    };
  } catch (e) {
    print('Error analyzing file: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  } finally {
    await file?.close();
  }
}

/// Example 4: Reading specific dataset with type checking
Future<List<double>?> readFloatDataset(
  Uint8List bytes,
  String datasetPath,
) async {
  Hdf5File? file;

  try {
    file = await Hdf5File.open(bytes, fileName: 'data.h5');

    // Check if dataset exists and is correct type
    final objectType = await file.getObjectType(datasetPath);
    if (objectType != 'dataset') {
      print('Error: $datasetPath is not a dataset');
      return null;
    }

    // Get dataset info
    final dataset = await file.dataset(datasetPath);
    print('Dataset info:');
    print('  Shape: ${dataset.dataspace.dimensions}');
    print('  Type: ${dataset.datatype}');

    // Read data
    final data = await file.readDataset(datasetPath);

    // Convert to List<double> if needed
    if (data is List<double>) {
      return data;
    } else if (data is List) {
      return data.map((e) => (e as num).toDouble()).toList();
    }

    return null;
  } catch (e) {
    print('Error reading dataset: $e');
    return null;
  } finally {
    await file?.close();
  }
}

/// Example 5: Interactive web application structure
///
/// Complete example of a web app that reads HDF5 files:
///
/// ```dart
/// import 'dart:html';
/// import 'package:dartframe/dartframe.dart';
///
/// void main() {
///   final fileInput = querySelector('#fileInput') as InputElement;
///   final output = querySelector('#output') as DivElement;
///   final progressBar = querySelector('#progress') as ProgressElement;
///
///   fileInput.onChange.listen((event) async {
///     final file = fileInput.files!.first;
///
///     // Check file size
///     if (file.size > 100 * 1024 * 1024) {
///       output.text = 'Warning: File is large (${file.size ~/ 1024 ~/ 1024}MB)';
///     }
///
///     try {
///       progressBar.value = 0;
///       output.text = 'Loading file...';
///
///       // Open HDF5 file - same API as desktop!
///       final hdf5 = await Hdf5File.open(fileInput, fileName: file.name);
///
///       progressBar.value = 50;
///       output.text = 'Analyzing structure...';
///
///       // Display structure
///       final structure = await hdf5.listRecursive();
///       final html = StringBuffer();
///       html.writeln('<h3>File Structure</h3>');
///       html.writeln('<ul>');
///
///       for (final entry in structure.entries) {
///         final path = entry.key;
///         final info = entry.value;
///         html.writeln('<li>');
///         html.writeln('<strong>$path</strong> (${info['type']})');
///
///         if (info['type'] == 'dataset') {
///           html.writeln('<br>Shape: ${info['shape']}');
///           html.writeln('<br>Type: ${info['dtype']}');
///         }
///
///         html.writeln('</li>');
///       }
///
///       html.writeln('</ul>');
///       output.innerHtml = html.toString();
///
///       progressBar.value = 100;
///
///       await hdf5.close();
///     } catch (e) {
///       output.text = 'Error: $e';
///       progressBar.value = 0;
///     }
///   });
/// }
/// ```

void main() {
  print('Web HDF5 examples - see comments for usage');
  print('These examples show how to use HDF5 on web platform');
  print('');
  print('Key points:');
  print('1. Use the same Hdf5File.open() API on both desktop and web');
  print('2. On desktop: pass file path string');
  print('3. On web: pass HTMLInputElement or Uint8List');
  print('4. File is loaded entirely into memory on web');
  print('5. Consider file size limits on web (recommend <100MB)');
  print('6. Always close files when done');
}
