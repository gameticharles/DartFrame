import 'package:dartframe/dartframe.dart';

Future<void> inspectObject(Hdf5File file, String path, {int indent = 0}) async {
  final indentStr = '  ' * indent;

  try {
    final objType = await file.getObjectType(path);

    if (objType == 'dataset') {
      print('$indentStr📊 Dataset: $path');
      final ds = await file.dataset(path);
      print('$indentStr   Shape: ${ds.shape}');
      print('$indentStr   Dtype: ${ds.datatype.typeName}');
      print('$indentStr   Layout: ${ds.layout.runtimeType}');

      // Show attributes
      final attrs = ds.attributes;
      if (attrs.isNotEmpty) {
        print(
            '$indentStr   Attributes: ${attrs.map((a) => '${a.name}=${a.value}').join(", ")}');
      }

      // Try to read
      try {
        final data = await file.readDataset(path);
        print('$indentStr   ✅ Read OK: ${data.length} elements');
        if (data.isNotEmpty && data.length <= 5) {
          print('$indentStr   Data: $data');
        } else if (data.isNotEmpty) {
          print('$indentStr   First 3: ${data.take(3).toList()}');
        }
      } catch (e) {
        print('$indentStr   ❌ Read failed: ${e.toString().split('\n').first}');
      }
    } else if (objType == 'group') {
      print('$indentStr📁 Group: $path');
      final group = await file.group(path);

      // Show attributes
      final attrs = group.header.findAttributes();
      if (attrs.isNotEmpty) {
        print(
            '$indentStr   Attributes: ${attrs.map((a) => '${a.name}=${a.value}').join(", ")}');
      }

      print(
          '$indentStr   Children (${group.children.length}): ${group.children.join(", ")}');

      // Recursively inspect children
      for (final child in group.children) {
        final childPath = path == '/' ? '/$child' : '$path/$child';
        await inspectObject(file, childPath, indent: indent + 1);
      }
    } else {
      print('$indentStr❓ Unknown: $path (type: $objType)');
    }
  } catch (e) {
    print('$indentStr❌ Error: $path - ${e.toString().split('\n').first}');
  }
}

void main() async {
  print('═' * 80);
  print('🔬 Recursive Inspection: example/data/processdata.h5');
  print('═' * 80);
  print('');

  try {
    final file = await Hdf5File.open('example/data/processdata.h5');

    try {
      final rootChildren = file.list('/');
      print('📁 Root (${rootChildren.length} objects)\n');

      for (final child in rootChildren) {
        await inspectObject(file, '/$child', indent: 1);
        print('');
      }

      print('═' * 80);
      print('✅ Inspection complete');
      print('═' * 80);
    } finally {
      await file.close();
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
