import 'package:dartframe/dartframe.dart';

/// Recursively print the structure of a group
Future<void> printGroupStructure(
  Hdf5File file,
  String path,
  int indent,
) async {
  final indentStr = '  ' * indent;

  try {
    final group = await file.group(path);

    // Print attributes if any
    final attrs = group.header.findAttributes();
    if (attrs.isNotEmpty) {
      print('$indentStr  [Attributes: ${attrs.map((a) => a.name).join(", ")}]');
    }

    // List children
    for (final child in group.children) {
      final childPath = path == '/' ? '/$child' : '$path/$child';

      try {
        final objType = await file.getObjectType(childPath);

        if (objType == 'dataset') {
          final ds = await file.dataset(childPath);
          final shape = ds.shape.join(' x ');
          final dtype = ds.datatype.typeName;

          print('$indentStr📊 $child');
          print('$indentStr   Type: $dtype, Shape: [$shape]');

          // Print dataset attributes
          final dsAttrs = ds.attributes;
          if (dsAttrs.isNotEmpty) {
            print(
                '$indentStr   [Attributes: ${dsAttrs.map((a) => a.name).join(", ")}]');
          }
        } else if (objType == 'group') {
          print('$indentStr📁 $child/');
          await printGroupStructure(file, childPath, indent + 1);
        } else {
          print('$indentStr❓ $child (unknown type)');
        }
      } catch (e) {
        print('$indentStr❌ $child (error: ${e.toString().split('\n').first})');
      }
    }
  } catch (e) {
    print('${indentStr}Error reading group: ${e.toString().split('\n').first}');
  }
}

Future<void> inspectFile(String filePath) async {
  print('\n${'=' * 80}');
  print('📄 File: $filePath');
  print('=' * 80);

  try {
    final file = await Hdf5File.open(filePath);

    try {
      print('\n🌳 Structure:');
      print('/');
      await printGroupStructure(file, '/', 1);
    } finally {
      await file.close();
    }

    print('\n✅ Successfully inspected');
  } catch (e) {
    print('\n❌ Error: $e');
  }
}

void main() async {
  print('🔍 HDF5 File Structure Inspector');
  print('Scanning for all .h5 files...\n');

  // List of HDF5 files to inspect
  final h5Files = [
    'test/fixtures/compound_test.h5',
    'test/fixtures/string_test.h5',
    'test/fixtures/chunked_string_compound_test.h5',
    'example/data/hdf5_test.h5',
    'example/data/processdata.h5',
    'example/data/test_chunked.h5',
    'example/data/test_simple.h5',
    'example/data/test_compressed.h5',
    'example/data/test_attr_simple.h5',
  ];

  var successCount = 0;
  var failCount = 0;

  for (final filePath in h5Files) {
    if (await FileIO().fileExists(filePath)) {
      try {
        await inspectFile(filePath);
        successCount++;
      } catch (e) {
        print('Failed to inspect $filePath: $e');
        failCount++;
      }
    } else {
      print('⚠️  File not found: $filePath');
      failCount++;
    }
  }

  print('\n${'=' * 80}');
  print(
      '📊 Summary: $successCount files inspected successfully, $failCount failed/not found');
  print('=' * 80);
}
