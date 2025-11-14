import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Debug vlen heap reading
void main() async {
  print('=== Debugging VLen Heap Reading ===\n');

  final file = await Hdf5File.open('test_vlen.h5');
  final dataset = await file.dataset('/vlen_strings');

  // Manually read the vlen references
  final raf = await File('test_vlen.h5').open();
  final reader = ByteReader(raf);

  // Get the dataset layout
  print('Dataset layout: ${dataset.layout.runtimeType}');
  if (dataset.layout is ContiguousLayout) {
    final layout = dataset.layout as ContiguousLayout;
    print('Data address: 0x${layout.address.toRadixString(16)}');

    // Read first few vlen references
    reader.seek(layout.address);

    for (int i = 0; i < 5; i++) {
      final vlenBytes = await reader.readBytes(16);
      final vlenRef = VlenReference.fromBytes(vlenBytes);
      print('Element $i: $vlenRef');
    }
  }

  await raf.close();
  await file.close();
}
