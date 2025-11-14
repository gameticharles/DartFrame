import 'package:dartframe/src/io/hdf5/hdf5_file.dart';
import 'package:dartframe/src/io/hdf5/hdf5_error.dart';

void main() async {
  setHdf5DebugMode(true);

  final file = await Hdf5File.open('example/data/test_simple_attrs.h5');

  try {
    print('Opening dataset /data...');
    final ds = await file.dataset('/data');

    print('Dataset shape: ${ds.shape}');
    print('Dataset datatype: ${ds.datatype}');
    print('Dataset datatype class: ${ds.datatype.classId}');
    print('Dataset datatype size: ${ds.datatype.size}');

    print('\nAttributes:');
    final attrs = ds.attributes;
    for (final attr in attrs) {
      print('  ${attr.name}: ${attr.value}');
    }
  } catch (e, stack) {
    print('Error: $e');
    print('Stack: $stack');
  } finally {
    await file.close();
  }
}
