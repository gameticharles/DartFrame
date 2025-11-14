/// Example demonstrating boolean and opaque datatype support
void main() async {
  print('=== HDF5 Boolean and Opaque Datatype Support ===\n');

  // Example 1: Reading boolean-like data (uint8 as boolean)
  print('Example 1: Boolean Data');
  print('------------------------');
  print(
      'HDF5 doesn\'t have a native boolean type, but uint8 is commonly used.');
  print('Use readAsBoolean() to convert uint8 values to Dart booleans.\n');

  print('Example usage:');
  print('  final file = await Hdf5File.open(\'data.h5\');');
  print('  final dataset = file.getDataset(\'/flags\');');
  print('  ');
  print('  // Check if dataset can be read as boolean');
  print('  if (dataset.datatype.isBoolean) {');
  print('    final boolArray = await dataset.readAsBoolean(file.reader);');
  print('    print(\'Flags: \$boolArray\');');
  print('  }');
  print('');

  // Example 2: Opaque data
  print('Example 2: Opaque Data');
  print('----------------------');
  print('Opaque datatypes store binary blobs with an optional tag identifier.');
  print('The data is returned as OpaqueData with raw bytes and tag info.\n');

  print('Example usage:');
  print('  final dataset = file.getDataset(\'/binary_data\');');
  print('  final data = await dataset.readData(file.reader);');
  print('  ');
  print('  for (final item in data) {');
  print('    if (item is OpaqueData) {');
  print('      print(\'Tag: \${item.tag}\');');
  print('      print(\'Size: \${item.data.length} bytes\');');
  print('      print(\'Hex: \${item.toHexString()}\');');
  print('    }');
  print('  }');
  print('');

  // Example 3: Bitfield data
  print('Example 3: Bitfield Data');
  print('------------------------');
  print('Bitfield datatypes store packed bits (flags, boolean arrays).');
  print('The data is returned as Uint8List for manual bit manipulation.\n');

  print('Example usage:');
  print('  final dataset = file.getDataset(\'/bitflags\');');
  print('  final data = await dataset.readData(file.reader);');
  print('  ');
  print('  for (final bitfield in data) {');
  print('    if (bitfield is Uint8List) {');
  print('      // Extract individual bits');
  print('      for (int i = 0; i < bitfield.length; i++) {');
  print('        final byte = bitfield[i];');
  print('        for (int bit = 0; bit < 8; bit++) {');
  print('          final flag = (byte >> bit) & 1;');
  print('          print(\'Bit \${i * 8 + bit}: \$flag\');');
  print('        }');
  print('      }');
  print('    }');
  print('  }');
  print('');

  print('=== Summary ===');
  print('✓ Boolean support: Use readAsBoolean() for uint8 datasets');
  print('✓ Opaque support: Returns OpaqueData with tag and raw bytes');
  print('✓ Bitfield support: Returns Uint8List for bit manipulation');
}
