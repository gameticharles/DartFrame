/// Manual diagnostic test - compile only, doesn't run
/// Just checks if code compiles correctly
library;

import 'package:dartframe/dartframe.dart';

void main() async {
  // Test 1: Can we create nested datasets?
  final builder = HDF5FileBuilder();

  final data1 = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0], [2, 2]);
  final data2 = NDArray.fromFlat([5.0, 6.0, 7.0, 8.0], [2, 2]);
  final data3 = NDArray.fromFlat([9.0, 10.0, 11.0, 12.0], [2, 2]);

  // These should create intermediate groups automatically
  await builder.addDataset('/group1/dataset1', data1);
  await builder.addDataset('/group1/subgroup/dataset2', data2);
  await builder.addDataset('/group2/dataset3', data3);

  // Build the file
  final bytes = await builder.finalize();

  print('Compilation test passed. File would be ${bytes.length} bytes');
}
