import 'dart:convert';
import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Example demonstrating how to export HDF5 structure to JSON
///
/// This example shows how to use getStructure() to export the complete
/// file structure to a JSON file, which can be useful for documentation,
/// APIs, or integration with other tools.
void main() async {
  // Open the HDF5 file
  final file = await Hdf5File.open('example/data/test_attributes.h5');

  // Get the structure as a map
  final structure = await file.getStructure();

  // Convert to pretty-printed JSON
  final encoder = JsonEncoder.withIndent('  ');
  final jsonString = encoder.convert(structure);

  // Save to file
  final outputFile = File('example/data/structure.json');
  await outputFile.writeAsString(jsonString);

  print('File structure exported to: ${outputFile.path}');
  print('Total objects: ${structure.length}');

  // Show a sample of the JSON
  print('\nSample JSON output:');
  final lines = jsonString.split('\n');
  for (int i = 0; i < lines.length && i < 30; i++) {
    print(lines[i]);
  }
  if (lines.length > 30) {
    print('  ...');
    print('  (${lines.length - 30} more lines)');
  }

  // Close the file
  await file.close();
}
