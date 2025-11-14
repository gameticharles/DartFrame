import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// HDF5 Attribute Reading Examples
///
/// This example demonstrates how to read attributes (metadata) from HDF5 files:
/// - Reading dataset attributes
/// - Accessing attribute values
/// - Understanding metadata
/// - Using attributes for data description
void main() async {
  print('=== DartFrame HDF5 Attribute Reading Examples ===\n');

  // Example 1: Reading basic attributes
  await example1BasicAttributes();

  // Example 2: Using attributes for data understanding
  await example2AttributeMetadata();

  // Example 3: Handling missing attributes
  await example3MissingAttributes();

  print('\n=== Examples Complete ===');
}

/// Example 1: Reading basic attributes
///
/// Shows how to read attributes attached to datasets
Future<void> example1BasicAttributes() async {
  print('Example 1: Reading Basic Attributes');
  print('-' * 50);

  final filePath = 'example/data/test_attributes.h5';

  if (!File(filePath).existsSync()) {
    print('File not found: $filePath');
    print('Note: Create test file with attributes using Python h5py\n');
    return;
  }

  try {
    // Read attributes from a dataset
    final attrs = await HDF5Reader.readAttributes(
      filePath,
      dataset: '/data',
    );

    print('Attributes found: ${attrs.length}');
    if (attrs.isNotEmpty) {
      print('\nAttribute details:');
      attrs.forEach((name, value) {
        print('  $name: $value (${value.runtimeType})');
      });
    } else {
      print('No attributes found on this dataset');
    }
  } catch (e) {
    print('Error reading attributes: $e');
  }

  print('');
}

/// Example 2: Using attributes for data understanding
///
/// Demonstrates how attributes provide context for datasets
Future<void> example2AttributeMetadata() async {
  print('Example 2: Using Attributes for Metadata');
  print('-' * 50);

  print('Attributes typically contain important metadata such as:');
  print('  - units: Physical units of measurement (e.g., "meters", "seconds")');
  print('  - description: Human-readable description of the data');
  print('  - creation_date: When the data was created');
  print('  - author: Who created the data');
  print('  - version: Data format version');
  print('  - scale_factor: Scaling factor for the data');
  print('  - offset: Offset value for the data');
  print('');

  // Example of how you might use attributes
  final filePath = 'example/data/test_attributes.h5';

  if (!File(filePath).existsSync()) {
    print('Example file not found. Here\'s how you would use attributes:\n');
    print('```dart');
    print(
        'final attrs = await HDF5Reader.readAttributes(filePath, dataset: "/temperature");');
    print('final units = attrs["units"]; // e.g., "celsius"');
    print(
        'final description = attrs["description"]; // e.g., "Daily temperature readings"');
    print('');
    print('// Read the data');
    print(
        'final df = await FileReader.readHDF5(filePath, dataset: "/temperature");');
    print('');
    print('// Use metadata to understand the data');
    print('print("Temperature data in \$units: \$description");');
    print('```');
  } else {
    try {
      final attrs = await HDF5Reader.readAttributes(filePath, dataset: '/data');

      // Common attribute patterns
      if (attrs.containsKey('units')) {
        print('Data units: ${attrs['units']}');
      }
      if (attrs.containsKey('description')) {
        print('Description: ${attrs['description']}');
      }
      if (attrs.containsKey('scale_factor')) {
        print('Scale factor: ${attrs['scale_factor']}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  print('');
}

/// Example 3: Handling missing attributes
///
/// Shows how to gracefully handle datasets without attributes
Future<void> example3MissingAttributes() async {
  print('Example 3: Handling Missing Attributes');
  print('-' * 50);

  final testFiles = [
    'example/data/test1.h5',
    'example/data/test_chunked.h5',
  ];

  for (final filePath in testFiles) {
    if (!File(filePath).existsSync()) {
      continue;
    }

    try {
      // Try to read attributes
      final attrs = await HDF5Reader.readAttributes(
        filePath,
        dataset: '/data',
      );

      print('$filePath:');
      if (attrs.isEmpty) {
        print('  No attributes (this is normal for many files)');
      } else {
        print('  Found ${attrs.length} attribute(s)');
        attrs.forEach((name, value) {
          print('    $name: $value');
        });
      }
    } catch (e) {
      // If the dataset doesn't exist, try listing available datasets
      try {
        final datasets = await HDF5Reader.listDatasets(filePath);
        print('$filePath:');
        print('  Dataset "/data" not found');
        print('  Available datasets: $datasets');
      } catch (e2) {
        print('$filePath: Error - $e2');
      }
    }
  }

  print('');
}
