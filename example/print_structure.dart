import 'package:dartframe/dartframe.dart';

/// Example demonstrating how to print HDF5 file structure
///
/// This example shows how to use the printStructure() method to
/// display the complete structure of an HDF5 file, including all
/// datasets, groups, and their attributes.
void main() async {
  // Open the HDF5 file
  final file = await Hdf5File.open('example/data/processdata.h5');

  // Print the complete file structure
  // This will show all datasets, groups, shapes, dtypes, and attributes
  await file.printStructure();

  // Close the file
  await file.close();
}
