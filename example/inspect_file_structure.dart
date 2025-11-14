import 'package:dartframe/dartframe.dart';

/// Example demonstrating file structure inspection and visualization
///
/// This example shows how to:
/// 1. Recursively list all objects in an HDF5 file
/// 2. Print a tree visualization of the file structure
/// 3. Get summary statistics about the file
/// 4. Inspect individual datasets and groups without reading data
Future<void> main() async {
  // Open an HDF5 file
  final file = await Hdf5File.open('test/fixtures/compound_test.h5');

  try {
    print('=== HDF5 File Structure Inspection ===\n');

    // 1. Print tree visualization
    print('File Structure Tree:');
    print('=' * 50);
    await file.printTree(showAttributes: true, showSizes: true);
    print('');

    // 2. Get recursive listing
    print('\nRecursive Listing:');
    print('=' * 50);
    final structure = await file.listRecursive();
    for (final entry in structure.entries) {
      final path = entry.key;
      final info = entry.value;
      print('$path: ${info['type']}');
      if (info['type'] == 'dataset') {
        print('  Shape: ${info['shape']}');
        print('  Type: ${info['dtype']}');
        print('  Storage: ${info['storage']}');
      }
    }
    print('');

    // 3. Get summary statistics
    print('\nSummary Statistics:');
    print('=' * 50);
    final stats = await file.getSummaryStats();
    print('Total datasets: ${stats['totalDatasets']}');
    print('Total groups: ${stats['totalGroups']}');
    print('Total objects: ${stats['totalObjects']}');
    print('Max depth: ${stats['maxDepth']}');
    print('Compressed datasets: ${stats['compressedDatasets']}');
    print('Chunked datasets: ${stats['chunkedDatasets']}');
    print('\nDatasets by type:');
    final datasetsByType = stats['datasetsByType'] as Map<String, int>;
    for (final entry in datasetsByType.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
    print('');

    // 4. Inspect individual dataset
    print('\nInspecting Individual Dataset:');
    print('=' * 50);
    final dataset = await file.dataset('/simple_compound');
    final datasetInfo = dataset.inspect();
    print('Dataset: /simple_compound');
    print('  Shape: ${datasetInfo['shape']}');
    print('  Type: ${datasetInfo['dtype']}');
    print('  Size: ${datasetInfo['size']} elements');
    print('  Storage: ${datasetInfo['storage']}');
    if (datasetInfo.containsKey('attributes')) {
      print('  Attributes: ${datasetInfo['attributes']}');
    }
    print('');

    // 5. Inspect individual group
    print('\nInspecting Root Group:');
    print('=' * 50);
    final rootGroup = file.root;
    final groupInfo = rootGroup.inspect();
    print('Group: /');
    print('  Children: ${groupInfo['childCount']}');
    print('  Names: ${groupInfo['children']}');
    if (groupInfo.containsKey('attributes')) {
      print('  Attributes: ${groupInfo['attributes']}');
    }
  } finally {
    await file.close();
  }
}
