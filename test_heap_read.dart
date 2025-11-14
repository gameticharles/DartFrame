import 'package:dartframe/src/io/hdf5/hdf5_file.dart';
import 'package:dartframe/src/io/hdf5/hdf5_error.dart';

void main() async {
  setHdf5DebugMode(true);

  try {
    final hdf5File = await Hdf5File.open('example/data/test_attributes.h5');
    final dataset = await hdf5File.dataset('/data');
    final attributes = dataset.header.findAttributes();

    print('\nFound ${attributes.length} attributes:');
    for (final attr in attributes) {
      print('  ${attr.name}: ${attr.value}');
    }

    await hdf5File.close();
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack: $stackTrace');
  }
}
