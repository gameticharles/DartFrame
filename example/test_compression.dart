import 'package:dartframe/dartframe.dart';

void main() async {
  try {
    // Enable debug logging
    setHdf5DebugMode(true);

    print('Testing compressed HDF5 reading...');

    // Test gzip compressed dataset
    print('\n1. Reading gzip compressed 1D dataset...');
    final df1 = await FileReader.readHDF5(
      'example/data/test_compressed.h5',
      dataset: '/gzip_1d',
    );
    print('Success! Shape: ${df1.shape}');
    print('First few values: ${df1[0].data.take(5)}');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}
