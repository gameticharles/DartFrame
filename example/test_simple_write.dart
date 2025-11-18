import 'package:dartframe/dartframe.dart';

/// Simple HDF5 write test
Future<void> main() async {
  print('Creating simple HDF5 file...\n');

  // Create a simple 1D array
  final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0, 5.0], [5]);

  print('Array: [1.0, 2.0, 3.0, 4.0, 5.0]');
  print('Shape: ${array.shape}\n');

  // Write to HDF5
  final outputFile = 'example/data/test_simple_output.h5';
  await array.toHDF5(outputFile, dataset: '/data');

  print('✓ Wrote to $outputFile\n');

  // Read it back
  print('Reading back...\n');
  final file = await Hdf5File.open(outputFile);

  try {
    final structure = await file.listRecursive();
    print('File structure:');
    structure.forEach((path, info) {
      print('   $path: ${info['type']}');
    });

    if (structure.containsKey('/data')) {
      final dataset = await file.dataset('/data');
      final data = await file.readDataset('/data');

      print('\nDataset /data:');
      print('   Shape: ${dataset.dataspace.dimensions}');
      print('   Type: ${dataset.datatype.typeName}');
      print('   Data: $data');

      print('\n✅ Success! Read data back from file');
    } else {
      print('\n❌ Dataset /data not found!');
    }
  } finally {
    await file.close();
  }
}
