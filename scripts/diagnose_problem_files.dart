import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

Future<void> diagnoseDataset(Hdf5File file, String path) async {
  print('\n  🔍 Diagnosing: $path');

  try {
    final ds = await file.dataset(path);
    print('    ✓ Dataset opened');
    print('    - Datatype: ${ds.datatype}');
    print('    - Datatype class: ${ds.datatype.dataclass}');
    print('    - Size: ${ds.datatype.size} bytes');
    print('    - Shape: ${ds.shape}');
    print('    - Layout: ${ds.layout.runtimeType}');

    if (ds.filterPipeline != null && ds.filterPipeline!.isNotEmpty) {
      print('    - Filters: ${ds.filterPipeline}');
    }

    // Try to read the data
    try {
      print('    - Attempting to read data...');
      final data = await file.readDataset(path);
      print('    ✓ Data read successfully (${data.length} elements)');
      if (data.isNotEmpty) {
        print('    - First element: ${data[0]}');
      }
    } catch (e) {
      print('    ✗ Failed to read data: $e');
    }
  } catch (e) {
    print('    ✗ Failed to open dataset: $e');
    print('    Stack trace: ${StackTrace.current}');
  }
}

Future<void> diagnoseFile(String filePath) async {
  print('\n${'=' * 80}');
  print('📄 Diagnosing: $filePath');
  print('=' * 80);

  try {
    final file = await Hdf5File.open(filePath);

    try {
      final rootChildren = file.list('/');
      print('\n📁 Root children: ${rootChildren.join(", ")}');

      // Diagnose each child
      for (final child in rootChildren) {
        final childPath = '/$child';

        try {
          final objType = await file.getObjectType(childPath);
          print('\n  📊 $child (type: $objType)');

          if (objType == 'dataset') {
            await diagnoseDataset(file, childPath);
          } else if (objType == 'group') {
            print('    (Group - skipping detailed diagnosis)');
          }
        } catch (e) {
          print('    ✗ Error getting object type: $e');
        }
      }
    } finally {
      await file.close();
    }
  } catch (e) {
    print('\n❌ Error opening file: $e');
  }
}

void main() async {
  print('🔬 Detailed HDF5 File Diagnosis\n');

  await diagnoseFile('example/data/hdf5_test.h5');
  await diagnoseFile('example/data/processdata.h5');

  print('\n${'=' * 80}');
  print('Diagnosis complete');
  print('=' * 80);
}
