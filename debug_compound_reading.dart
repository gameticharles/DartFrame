import 'dart:io';
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';
import 'package:dartframe/src/io/hdf5/byte_reader.dart';

void main() async {
  print('=== Testing matrix_array dataset ===');
  final hdf5File = await Hdf5File.open('test/fixtures/array_test.h5');

  final dataset = await hdf5File.dataset('/matrix_array');

  print('Dataset shape: ${dataset.shape}');
  print('Dataset size: ${dataset.datatype.size}');
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
        }
      }
    }
  }

  // Try to read the data
  print('\n=== Attempting to read data ===');
  try {
    final reader = ByteReader(await File('test/fixtures/array_test.h5').open());
    final data = await dataset.readData(reader);
    print('Success! Read ${data.length} records');
  } catch (e) {
    print('Error: $e');
  }

  await hdf5File.close();
}
