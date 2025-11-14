import 'package:dartframe/src/io/hdf5/hdf5_file.dart';
import 'package:dartframe/src/io/hdf5/hdf5_error.dart';

void main() async {
  // Enable debug logging
  setHdf5DebugMode(true);
  try {
    print('Opening file with debug logging enabled...\n');
    final hdf5File = await Hdf5File.open('example/data/test_attributes.h5');

    print('\n\nAttempting to read dataset...\n');
    final dataset = await hdf5File.dataset('/data');

    print('\n\nChecking for attributes...\n');
    final attributes = dataset.header.findAttributes();
    print('Found ${attributes.length} attributes');

    for (final attr in attributes) {
      print('  - ${attr.name}: ${attr.value}');
    }

    await hdf5File.close();
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}
