import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

void main() async {
  try {
    final hdf5File = await Hdf5File.open('example/data/test_attributes.h5');

    // Use the new printStructure method
    await hdf5File.printStructure();

    await hdf5File.close();
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack: $stackTrace');
  }
}
