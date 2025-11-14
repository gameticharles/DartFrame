import 'dart:io';
import 'package:dartframe/dartframe.dart';

Future<void> listAllItems(
  ByteReader reader,
  Group group,
  String path,
  int hdf5Offset,
  List<Map<String, dynamic>> results,
) async {
  for (final childName in group.children) {
    final childPath = path == '/' ? '/$childName' : '$path/$childName';
    final childAddress = group.getChildAddress(childName)!;
    final adjustedAddress = childAddress + hdf5Offset;

    try {
      // Try to read as dataset
      final dataset = await Dataset.read(reader, adjustedAddress);
      results.add({
        'path': childPath,
        'type': 'dataset',
        'shape': dataset.shape,
        'dtype':
            'class=${dataset.datatype.classId}, size=${dataset.datatype.size}',
      });
    } catch (e) {
      // Try to read as group
      try {
        final childGroup = await Group.read(reader, adjustedAddress);
        results.add({
          'path': childPath,
          'type': 'group',
          'children': childGroup.children.length,
        });

        // Recursively list children
        await listAllItems(reader, childGroup, childPath, hdf5Offset, results);
      } catch (e2) {
        results.add({
          'path': childPath,
          'type': 'unknown',
          'error': e.toString().split('\n')[0],
        });
      }
    }
  }
}

void main() async {
  final downloadsPath = 'example/data';

  final files = [
    'test_simple.h5',
    'test1.h5',
    'hdf5_test.h5',
    'processdata.h5'
  ];

  for (final filename in files) {
    final path = '$downloadsPath\\$filename';
    final file = File(path);

    if (!file.existsSync()) {
      print('❌ $filename: NOT FOUND\n');
      continue;
    }

    print('=' * 80);
    print('FILE: $filename');
    print('=' * 80);
    print('Size: ${file.lengthSync()} bytes\n');

    final raf = await file.open();
    final reader = ByteReader(raf);

    try {
      final superblock = await Superblock.read(reader);
      final rootAddress =
          superblock.rootGroupObjectHeaderAddress + superblock.hdf5StartOffset;
      final rootGroup = await Group.read(reader, rootAddress);

      print('HDF5 Version: ${superblock.version}');
      print('HDF5 Start Offset: ${superblock.hdf5StartOffset}\n');

      final results = <Map<String, dynamic>>[];
      await listAllItems(
          reader, rootGroup, '/', superblock.hdf5StartOffset, results);

      print('📊 Complete Structure (${results.length} items):\n');

      for (final item in results) {
        final indent = '  ' * (item['path'].split('/').length - 2);
        final name = item['path'].split('/').last;

        if (item['type'] == 'dataset') {
          print('$indent📄 $name');
          print('$indent   Path: ${item['path']}');
          print('$indent   Type: Dataset');
          print('$indent   Shape: ${item['shape']}');
          print('$indent   Dtype: ${item['dtype']}');
        } else if (item['type'] == 'group') {
          print('$indent📁 $name/');
          print('$indent   Path: ${item['path']}');
          print('$indent   Type: Group');
          print('$indent   Children: ${item['children']}');
        } else {
          print('$indent❓ $name');
          print('$indent   Path: ${item['path']}');
          print('$indent   Type: ${item['type']}');
        }
        print('');
      }
    } catch (e) {
      print('❌ Error: $e\n');
    } finally {
      await raf.close();
    }
  }
}
