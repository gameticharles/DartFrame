import 'package:dartframe/dartframe.dart';

/// Inspect the structure of vlen datasets
void main() async {
  print('=== Inspecting VLen Dataset Structure ===\n');

  final file = await Hdf5File.open('test_vlen.h5');

  // Inspect vlen strings
  print('Dataset: /vlen_strings');
  final ds1 = await file.dataset('/vlen_strings');
  print('  Datatype class: ${ds1.datatype.dataclass}');
  print('  Datatype size: ${ds1.datatype.size}');
  print('  Is variable-length: ${ds1.datatype.isVariableLength}');
  print('  Base type: ${ds1.datatype.baseType}');
  if (ds1.datatype.baseType != null) {
    print('  Base type class: ${ds1.datatype.baseType!.dataclass}');
    print('  Base type size: ${ds1.datatype.baseType!.size}');
    print('  Base type is string: ${ds1.datatype.baseType!.isString}');
    if (ds1.datatype.baseType!.stringInfo != null) {
      print('  Base type string info: ${ds1.datatype.baseType!.stringInfo}');
    }
  }
  print('');

  // Inspect vlen ints
  print('Dataset: /vlen_ints');
  final ds2 = await file.dataset('/vlen_ints');
  print('  Datatype class: ${ds2.datatype.dataclass}');
  print('  Datatype size: ${ds2.datatype.size}');
  print('  Is variable-length: ${ds2.datatype.isVariableLength}');
  print('  Base type: ${ds2.datatype.baseType}');
  if (ds2.datatype.baseType != null) {
    print('  Base type class: ${ds2.datatype.baseType!.dataclass}');
    print('  Base type size: ${ds2.datatype.baseType!.size}');
  }
  print('');

  await file.close();
}
