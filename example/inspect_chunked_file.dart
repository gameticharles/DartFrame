import 'package:dartframe/dartframe.dart';

/// Example demonstrating inspection of chunked and compressed datasets
Future<void> main() async {
  // Open a chunked HDF5 file
  final file =
      await Hdf5File.open('test/fixtures/chunked_string_compound_test.h5');

  try {
    print('=== Chunked File Structure ===\n');

    // Print tree with all details
    await file.printTree(showAttributes: true, showSizes: true);
    print('');

    // Get summary statistics
    print('\nSummary Statistics:');
    print('=' * 50);
    final stats = await file.getSummaryStats();
    print('Total datasets: ${stats['totalDatasets']}');
    print('Total groups: ${stats['totalGroups']}');
    print('Chunked datasets: ${stats['chunkedDatasets']}');
    print('Compressed datasets: ${stats['compressedDatasets']}');
  } finally {
    await file.close();
  }
}
