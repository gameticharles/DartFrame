import 'package:dartframe/dartframe.dart';

/// Demonstrates the refactored HDF5 datatype API
void main() {
  print('=== HDF5 Datatype API Demo ===\n');

  // 1. Predefined atomic types
  print('1. Predefined Atomic Types:');
  print('   int32: ${Hdf5Datatype.int32.typeName}');
  print('   float64: ${Hdf5Datatype.float64.typeName}');
  print('   uint8: ${Hdf5Datatype.uint8.typeName}\n');

  // 2. Type checking
  print('2. Type Checking:');
  print('   int32.isAtomic: ${Hdf5Datatype.int32.isAtomic}');
  print('   int32.isComposite: ${Hdf5Datatype.int32.isComposite}');
  print('   int32.dataclass: ${Hdf5Datatype.int32.dataclass}\n');

  // 3. Custom datatype creation
  print('3. Custom Datatype:');
  final customInt = Hdf5Datatype<int>(
    dataclass: Hdf5DatatypeClass.integer,
    size: 2,
  );
  print('   Custom int16: $customInt');
  print('   Type name: ${customInt.typeName}\n');

  // 4. String datatype with metadata
  print('4. String Datatype:');
  final stringType = Hdf5Datatype<String>(
    dataclass: Hdf5DatatypeClass.string,
    size: 50,
    stringInfo: StringInfo(
      paddingType: StringPaddingType.nullTerminate,
      characterSet: CharacterSet.utf8,
      isVariableLength: false,
    ),
  );
  print('   $stringType');
  print('   Type name: ${stringType.typeName}\n');

  // 5. Compound datatype
  print('5. Compound Datatype:');
  final compoundType = Hdf5Datatype<Map<String, dynamic>>(
    dataclass: Hdf5DatatypeClass.compound,
    size: 16,
    compoundInfo: CompoundInfo(
      fields: [
        CompoundField(
          name: 'id',
          offset: 0,
          datatype: Hdf5Datatype.int32,
        ),
        CompoundField(
          name: 'value',
          offset: 8,
          datatype: Hdf5Datatype.float64,
        ),
      ],
    ),
  );
  print('   $compoundType');
  print('   Type name: ${compoundType.typeName}');
  print('   Fields:');
  for (final field in compoundType.compoundInfo!.fields) {
    print(
        '     - ${field.name} @ offset ${field.offset}: ${field.datatype.typeName}');
  }
  print('');

  // 6. Enum usage
  print('6. Datatype Class Enum:');
  for (final cls in Hdf5DatatypeClass.values) {
    print('   ${cls.name} (id=${cls.id})');
  }
  print('');

  // 7. Legacy compatibility
  print('7. Legacy Compatibility:');
  print('   datatypeClassFixedPoint = $datatypeClassFixedPoint');
  print('   datatypeClassFloatingPoint = $datatypeClassFloatingPoint');
  print('   datatypeClassString = $datatypeClassString');
  print('   datatypeClassCompound = $datatypeClassCompound\n');

  print('=== Demo Complete ===');
}
