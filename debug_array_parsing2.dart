import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

void main() async {
  final hdf5File = await Hdf5File.open('test/fixtures/enum_test.h5');

  // Get the dataset with enum in compound
  final dataset = await hdf5File.dataset('/tasks');

  print('Dataset datatype: ${dataset.datatype}');
  print('Is compound: ${dataset.datatype.isCompound}');

  if (dataset.datatype.compoundInfo != null) {
    print('\nCompound fields:');
    for (final field in dataset.datatype.compoundInfo!.fields) {
      print('  Field: ${field.name}');
      print('    Offset: ${field.offset}');
      print('    Type class: ${field.datatype.classId}');
      print('    Type size: ${field.datatype.size}');
      print('    Is enum: ${field.datatype.isEnum}');

      if (field.datatype.isEnum && field.datatype.enumInfo != null) {
        print('    Enum members: ${field.datatype.enumInfo!.members.length}');
        for (final member in field.datatype.enumInfo!.members) {
          print('      ${member.name} = ${member.value}');
        }

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
