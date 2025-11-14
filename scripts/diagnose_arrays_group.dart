import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

Future<void> diagnoseDataset(Hdf5File file, String path) async {
  print('\n🔍 $path');

  try {
    final ds = await file.dataset(path);
    print('  ✓ Opened');
    print('  - Datatype: ${ds.datatype}');
    print('  - Class: ${ds.datatype.dataclass} (id: ${ds.datatype.classId})');
    print('  - Size: ${ds.datatype.size} bytes');
    print('  - Shape: ${ds.shape}');
    print('  - Layout: ${ds.layout.runtimeType}');

    // Try to read
    try {
      final data = await file.readDataset(path);
      print('  ✓ Read OK (${data.length} elements)');
      if (data.isNotEmpty && data.length <= 5) {
        print('  - Data: $data');
      } else if (data.isNotEmpty) {
        print('  - First 3: ${data.take(3).toList()}');
      }
    } catch (e) {
      print('  ✗ Read failed: $e');
    }
  } catch (e) {
    print('  ✗ Open failed: $e');
  }
}

void main() async {
  print('🔬 Diagnosing arrays group in hdf5_test.h5\n');

  final file = await Hdf5File.open('example/data/hdf5_test.h5');

  try {
    final arraysGroup = await file.group('/arrays');
    print('📁 /arrays children: ${arraysGroup.children.join(", ")}\n');

    for (final child in arraysGroup.children) {
      await diagnoseDataset(file, '/arrays/$child');
    }
  } finally {
    await file.close();
  }
}
