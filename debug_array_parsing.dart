import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

void main() async {
  final hdf5File = await Hdf5File.open('test/fixtures/array_test.h5');

  // Get the dataset
  final dataset = await hdf5File.dataset('/simple_array');

  print('Dataset datatype: ${dataset.datatype}');
  print('Is compound: ${dataset.datatype.isCompound}');

  if (dataset.datatype.compoundInfo != null) {
    print('\nCompound fields:');
    for (final field in dataset.datatype.compoundInfo!.fields) {
      print('  Field: ${field.name}');
      print('    Offset: ${field.offset}');
      print('    Type class: ${field.datatype.classId}');
      print('    Type size: ${field.datatype.size}');
      print('    Is array: ${field.datatype.isArray}');

      if (field.datatype.isArray && field.datatype.arrayInfo != null) {
        print('    Array dimensions: ${field.datatype.arrayInfo!.dimensions}');
        print(
            '    Array total elements: ${field.datatype.arrayInfo!.totalElements}');

        if (field.datatype.baseType != null) {
          print('    Base type class: ${field.datatype.baseType!.classId}');
          print('    Base type size: ${field.datatype.baseType!.size}');
        } else {
          print('    Base type: NULL');
        }
      }
    }
  }

  await hdf5File.close();
}
