import 'package:dartframe/dartframe.dart';

void main() {
  print('=== DartFrame DataCube Examples ===\n');

  // 1. Creating DataCubes
  print('1. Creating DataCubes');
  print('-' * 40);

  // Generate a simple cube
  final cube = DataCube.generate(
    3, // depth (3 frames)
    4, // rows per frame
    3, // columns per frame
    (d, r, c) => d * 100 + r * 10 + c,
  );

  print('Cube shape: ${cube.shape}');
  print('Depth: ${cube.depth}');
  print('Rows: ${cube.rows}');
  print('Cols: ${cube.columns}\n');

  // 2. Accessing Frames
  print('2. Accessing Frames');
  print('-' * 40);

  final frame0 = cube.getFrame(0);
  print('Frame 0:');
  print(frame0);

  final frame1 = cube.getFrame(1);
  print('\nFrame 1:');
  print(frame1);
  print('');

  // 3. Accessing Values
  print('3. Accessing Values');
  print('-' * 40);

  print('Value at [0, 0, 0]: ${cube.getValue([0, 0, 0])}');
  print('Value at [1, 2, 1]: ${cube.getValue([1, 2, 1])}');
  print('Value at [2, 3, 2]: ${cube.getValue([2, 3, 2])}\n');

  // 4. Slicing
  print('4. Slicing');
  print('-' * 40);

  final sliced = cube.slice([
    Slice.range(0, 2), // Frames 0-1
    Slice.range(1, 3), // Rows 1-2
    Slice.range(0, 2), // Columns 0-1
  ]) as DataCube;

  print('Sliced cube shape: ${sliced.shape}');
  print('Frame 0 of sliced cube:');
  print(sliced.getFrame(0));
  print('');

  // 5. Aggregations
  print('5. Aggregations');
  print('-' * 40);

  final data = DataCube.generate(3, 4, 3, (d, r, c) => d + r + c);

  print('Overall statistics:');
  print('Sum: ${data.sum()}');
  print('Mean: ${data.mean()}');
  print('Min: ${data.min()}');
  print('Max: ${data.max()}');
  print('Std: ${data.std()}');

  print('\nAggregation along depth (axis 0):');
  final depthSum = data.sum(axis: 0);
  print('Sum across frames (returns DataFrame):');
  print(depthSum);

  print('\nAggregation along rows (axis 1):');
  final rowMean = data.mean(axis: 1);
  print('Mean per frame: $rowMean\n');

  // 6. Transformations
  print('6. Transformations');
  print('-' * 40);

  final original = DataCube.generate(2, 3, 2, (d, r, c) => d * 10 + r);
  print('Original cube:');
  print('Frame 0:');
  print(original.getFrame(0));

  final doubled = DataCube.fromNDArray(original.data.map((x) => x * 2));
  print('\nDoubled cube:');
  print('Frame 0:');
  print(doubled.getFrame(0));

  final squared = DataCube.fromNDArray(original.data.map((x) => x * x));
  print('\nSquared cube:');
  print('Frame 0:');
  print(squared.getFrame(0));
  print('');

  // 7. Frame-level Operations
  print('7. Frame-level Operations');
  print('-' * 40);

  final timeSeries = DataCube.generate(5, 10, 3, (d, r, c) => d * 10 + r + c);

  // Apply operation to each frame
  final frameSums = <double>[];
  timeSeries.forEachFrame((index, frame) {
    final allValues = frame.rows.expand((row) => row).whereType<num>();
    final sum = allValues.isEmpty ? 0 : allValues.reduce((a, b) => a + b);
    frameSums.add(sum.toDouble());
    print('Frame $index sum: $sum');
  });
  print('');

  // 8. Selection and Filtering
  print('8. Selection and Filtering');
  print('-' * 40);

  final dataset = DataCube.generate(10, 5, 3, (d, r, c) => d * 10 + r);

  // Select specific frames
  final selected = dataset.selectByIndices([0, 2, 4, 6, 8]);
  print('Selected frames: ${selected.depth}');
  print('Original depth: ${dataset.depth}');

  // Filter frames by condition
  final filtered = dataset.selectFrames((frame) {
    final allValues = frame.rows.expand((row) => row).whereType<num>();
    final mean = allValues.isEmpty
        ? 0
        : allValues.reduce((a, b) => a + b) / allValues.length;
    return mean > 20;
  });
  print('Filtered frames (mean > 20): ${filtered.depth}\n');

  // 9. Column Operations
  print('9. Column Operations');
  print('-' * 40);

  final namedCube = DataCube.generate(
    3,
    4,
    3,
    (d, r, c) => d * 100 + r * 10 + c,
  );

  print('Column names: ${namedCube.columnNames}');

  // Get all values for a column across frames
  final col0 = namedCube.getColumn('col_0');
  print('Column 0 shape: ${col0.shape}');
  print('Column 0 data:\n$col0\n');

  // 10. Combining Cubes
  print('10. Combining Cubes');
  print('-' * 40);

  final cube1 = DataCube.generate(2, 3, 2, (d, r, c) => 1);
  final cube2 = DataCube.generate(2, 3, 2, (d, r, c) => 2);

  print('Cube 1 depth: ${cube1.depth}');
  print('Cube 2 depth: ${cube2.depth}');

  final combined = cube1.concat(cube2, axis: 0);
  print('Combined depth: ${combined.depth}');
  print('Combined shape: ${combined.shape}\n');

  // 11. Conversion to NDArray
  print('11. Conversion to NDArray');
  print('-' * 40);

  final smallCube = DataCube.generate(2, 2, 2, (d, r, c) => d * 4 + r * 2 + c);
  print('Cube shape: ${smallCube.shape}');

  final array = smallCube.toNDArray();
  print('NDArray shape: ${array.shape}');
  print('NDArray:\n$array');

  final flattened = smallCube.flatten();
  print('\nFlattened: $flattened\n');

  // 12. Practical Example: Time Series Analysis
  print('12. Practical Example: Time Series Analysis');
  print('-' * 40);

  // Simulate monthly sales data for 12 months, 100 products, 5 regions
  final salesData = DataCube.generate(
    12, // 12 months
    100, // 100 products
    5, // 5 regions
    (month, product, region) {
      // Simulate seasonal sales pattern
      final seasonal = 1.0 + 0.3 * (month / 12);
      final base = 100 + product * 10 + region * 50;
      return (base * seasonal).round();
    },
  );

  print('Sales data shape: ${salesData.shape}');
  print('Total sales: ${salesData.sum()}');
  print('Average sales per month: ${salesData.mean(axis: 1)}');

  // Find best performing month
  final monthlySales = <int, double>{};
  salesData.forEachFrame((month, frame) {
    final allValues = frame.rows.expand((row) => row).whereType<num>();
    final sum = allValues.isEmpty ? 0 : allValues.reduce((a, b) => a + b);
    monthlySales[month] = sum.toDouble();
  });

  final bestMonth =
      monthlySales.entries.reduce((a, b) => a.value > b.value ? a : b);
  print('Best month: ${bestMonth.key} with sales: ${bestMonth.value}');

  // Analyze specific region (column 0)
  final region0Sales = salesData.getColumn('col_0');
  print('\nRegion 0 sales across all months:');
  print('Total: ${region0Sales.sum()}');
  print('Average: ${region0Sales.mean()}\n');

  print('=== Examples Complete ===');
}
