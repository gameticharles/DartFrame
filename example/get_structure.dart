import 'dart:convert';
import 'package:dartframe/dartframe.dart';

/// Example demonstrating how to get HDF5 file structure as a map
///
/// This example shows how to use the getStructure() method to
/// retrieve the file structure as a map that can be used programmatically
/// or converted to JSON.
void main() async {
  // Open the HDF5 file
  final file = await Hdf5File.open('example/data/test_attributes.h5');

  // Get the structure as a map
  final structure = await file.getStructure();

  // Access specific information programmatically
  print('Accessing structure programmatically:\n');

  // Get dataset shape
  final dataShape = structure['/data']['shape'];
  print('Shape of /data: $dataShape');

  // Get dataset dtype
  final dataDtype = structure['/data']['dtype'];
  print('Dtype of /data: $dataDtype');

  // Get attribute value
  final unitsValue = structure['/data']['attributes']['units']['value'];
  print('Units attribute: $unitsValue');

  // Count total attributes across all objects
  int totalAttributes = 0;
  for (final entry in structure.entries) {
    final attrs = entry.value['attributes'] as Map;
    totalAttributes += attrs.length;
  }
  print('\nTotal attributes in file: $totalAttributes');

  // List all datasets
  print('\nDatasets in file:');
  for (final entry in structure.entries) {
    if (entry.value['type'] == 'dataset') {
      final shape = entry.value['shape'];
      final dtype = entry.value['dtype'];
      print('  ${entry.key}: shape=$shape, dtype=$dtype');
    }
  }

  // List all groups
  print('\nGroups in file:');
  for (final entry in structure.entries) {
    if (entry.value['type'] == 'group') {
      final attrCount = (entry.value['attributes'] as Map).length;
      print('  ${entry.key}: $attrCount attributes');
    }
  }

  // Convert to JSON (useful for APIs or serialization)
  print('\nStructure as JSON (first 500 chars):');
  final jsonStr = jsonEncode(structure);
  print(jsonStr.substring(0, jsonStr.length > 500 ? 500 : jsonStr.length));
  if (jsonStr.length > 500) print('...');

  // Close the file
  await file.close();
}
