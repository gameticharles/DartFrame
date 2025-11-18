import 'package:test/test.dart';
import 'package:dartframe/src/io/hdf5/symbol_table_writer.dart';

void main() {
  test('debug symbol table structure', () {
    final writer = SymbolTableWriter(format: SymbolTableFormat.v1);
    final entries = [
      SymbolTableEntry(name: '/data', objectHeaderAddress: 0x1000),
    ];

    final result = writer.write(
      entries: entries,
      startAddress: 0x100,
    );

    final bytes = result['bytes'] as List<int>;

    print('Total bytes: ${bytes.length}');
    print(
        'Expected: 48 (B-tree) + 40 (symbol table node) + 24 (heap header) + 6 (data) = 118');

    // Print all bytes in hex
    for (int i = 0; i < bytes.length; i++) {
      if (i % 16 == 0) print('');
      print(
          '${i.toString().padLeft(3)}: 0x${bytes[i].toRadixString(16).padLeft(2, '0')} ');
    }

    // Find signatures
    print('\n\nSearching for signatures:');
    for (int i = 0; i < bytes.length - 3; i++) {
      final sig = String.fromCharCodes(bytes.sublist(i, i + 4));
      if (sig == 'TREE' || sig == 'SNOD' || sig == 'HEAP') {
        print('Found $sig at offset $i');
      }
    }
  });
}
