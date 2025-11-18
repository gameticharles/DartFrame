import 'package:dartframe/dartframe.dart';

void main() {
  print('=== Filtering & Selection Examples ===\n');

  // 1. Basic Filtering
  print('1. Basic Filtering with where()');
  print('-' * 40);

  final numbers = NDArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  print('Original: $numbers');

  final greaterThan5 = numbers.where((x) => x > 5);
  print('Greater than 5: $greaterThan5');

  final even = numbers.where((x) => x % 2 == 0);
  print('Even numbers: $even');

  final range = numbers.where((x) => x >= 3 && x <= 7);
  print('Between 3 and 7: $range\n');

  // 2. Getting Indices
  print('2. Getting Indices with whereIndices()');
  print('-' * 40);

  final matrix = NDArray([
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
  ]);
  print('Matrix:\n$matrix');

  final indices = matrix.whereIndices((x) => x > 5);
  print('Indices where value > 5:');
  for (final idx in indices) {
    print('  $idx -> ${matrix.getValue(idx)}');
  }
  print('');

  // 3. Selecting by Indices
  print('3. Selecting by Indices');
  print('-' * 40);

  final data = NDArray([
    [10, 20, 30],
    [40, 50, 60],
    [70, 80, 90]
  ]);
  print('Data:\n$data');

  final selected = data.select([
    [0, 0], // 10
    [1, 1], // 50
    [2, 2], // 90
  ]);
  print('Diagonal elements: $selected\n');

  // 4. Range Filtering
  print('4. Range Filtering');
  print('-' * 40);

  final values = NDArray([5, 15, 25, 35, 45, 55, 65, 75, 85, 95]);
  print('Values: $values');

  final inRange = values.filterRange(20, 60);
  print('Values between 20 and 60: $inRange\n');

  // 5. Multi-condition Filtering
  print('5. Multi-condition Filtering');
  print('-' * 40);

  final dataset = NDArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  print('Dataset: $dataset');

  // AND logic
  final andFiltered = dataset.filterMulti([
    (x) => x > 2,
    (x) => x < 8,
    (x) => x % 2 == 0,
  ], logic: 'and');
  print('AND (>2 AND <8 AND even): $andFiltered');

  // OR logic
  final orFiltered = dataset.filterMulti([
    (x) => x < 3,
    (x) => x > 8,
  ], logic: 'or');
  print('OR (<3 OR >8): $orFiltered\n');

  // 6. Counting and Checking
  print('6. Counting and Checking');
  print('-' * 40);

  final scores = NDArray([45, 67, 89, 92, 78, 56, 34, 88, 91, 73]);
  print('Scores: $scores');

  final passing = scores.countWhere((x) => x >= 60);
  print('Passing scores (>=60): $passing');

  final hasExcellent = scores.any((x) => x >= 90);
  print('Has excellent score (>=90): $hasExcellent');

  final allPassing = scores.all((x) => x >= 60);
  print('All passing: $allPassing\n');

  // 7. Finding Elements
  print('7. Finding Elements');
  print('-' * 40);

  final sequence = NDArray([10, 20, 30, 40, 50, 40, 30, 20, 10]);
  print('Sequence: $sequence');

  final firstLarge = sequence.findFirst((x) => x >= 40);
  print('First element >= 40 at index: $firstLarge');

  final lastLarge = sequence.findLast((x) => x >= 40);
  print('Last element >= 40 at index: $lastLarge');

  final notFound = sequence.findFirst((x) => x > 100);
  print('Element > 100: $notFound\n');

  // 8. Replacing Values
  print('8. Replacing Values');
  print('-' * 40);

  final original = NDArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  print('Original: $original');

  final replaced = original.replaceWhere((x) => x > 5, 0);
  print('Replace >5 with 0: $replaced');

  final capped = original.replaceWhere((x) => x > 7, 7);
  print('Cap at 7: $capped\n');

  // 9. Boolean Masking
  print('9. Boolean Masking');
  print('-' * 40);

  final temps = NDArray([18, 22, 25, 19, 30, 28, 15, 20, 26, 24]);
  print('Temperatures: $temps');

  final hotMask = temps.createMask((x) => x >= 25);
  print('Hot days mask (>=25): $hotMask');

  final hotTemps = temps.mask(hotMask);
  print('Hot temperatures: $hotTemps');

  // Custom mask
  final customMask = NDArray(
      [true, false, true, false, true, false, true, false, true, false]);
  final custom = temps.mask(customMask);
  print('Custom mask result: $custom\n');

  // 10. Advanced Indexing
  print('10. Advanced Indexing');
  print('-' * 40);

  final arr = NDArray([10, 20, 30, 40, 50, 60, 70, 80, 90, 100]);
  print('Array: $arr');

  final fancy = arr.indexWith([0, 2, 4, 6, 8]);
  print('Every other element: $fancy');

  final reversed = arr.indexWith([9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
  print('Reversed: $reversed');

  final sample = arr.take([1, 4, 7]);
  print('Sample [1, 4, 7]: $sample\n');

  // 11. In-place Modifications
  print('11. In-place Modifications');
  print('-' * 40);

  final mutable = NDArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  print('Original: $mutable');

  mutable.put([0, 4, 9], 0);
  print('After put([0, 4, 9], 0): $mutable');

  final mutable2 = NDArray([1, 2, 3, 4, 5]);
  mutable2.putValues([1, 3], [100, 200]);
  print('After putValues([1, 3], [100, 200]): $mutable2\n');

  // 12. DataCube Selection
  print('12. DataCube Selection');
  print('-' * 40);

  final cube = DataCube.generate(10, 5, 3, (d, r, c) => d * 10 + r);
  print('Cube shape: ${cube.shape}');

  // Select frames by indices
  final selectedFrames = cube.selectByIndices([0, 2, 4, 6, 8]);
  print('Selected frames: ${selectedFrames.depth}');

  // Filter frames by condition
  final filteredCube = cube.selectFrames((frame) {
    // Calculate mean of all values in the frame
    final allValues = frame.rows.expand((row) => row).whereType<num>();
    final mean = allValues.isEmpty
        ? 0
        : allValues.reduce((a, b) => a + b) / allValues.length;
    return mean > 25;
  });
  print('Frames with mean > 25: ${filteredCube.depth}');

  // Filter by column condition
  final columnFiltered = cube.whereColumn('col_0', (x) => x > 30);
  print('Frames where col_0 > 30: ${columnFiltered.depth}\n');

  // 13. Practical Example: Data Cleaning
  print('13. Practical Example: Data Cleaning');
  print('-' * 40);

  // Simulated sensor data with outliers
  final sensorData = NDArray([
    22.5, 23.1, 22.8, 999.0, // 999.0 is an error
    23.5, 22.9, 23.2, -999.0, // -999.0 is an error
    23.0, 22.7, 23.4, 23.1
  ]);

  print('Raw sensor data: $sensorData');

  // Remove error values
  final cleaned = sensorData.where((x) => x > -100 && x < 100);
  print('Cleaned data: $cleaned');
  print('Valid readings: ${cleaned.size}');
  print('Average temperature: ${cleaned.mean()}\n');

  // 14. Practical Example: Grade Analysis
  print('14. Practical Example: Grade Analysis');
  print('-' * 40);

  final grades = NDArray([
    [85, 92, 78, 88, 95], // Student 1
    [76, 84, 91, 79, 88], // Student 2
    [92, 95, 89, 94, 97], // Student 3
    [68, 72, 75, 70, 74], // Student 4
    [88, 86, 90, 87, 89], // Student 5
  ]);

  print('Grades matrix (5 students, 5 tests):');
  print(grades);

  // Find all A grades (>=90)
  final aGrades = grades.where((x) => x >= 90);
  print('\nA grades (>=90): $aGrades');
  print('Number of A grades: ${aGrades.size}');

  // Find students with perfect scores
  final perfectIndices = grades.whereIndices((x) => x >= 95);
  print('\nPerfect scores (>=95) at:');
  for (final idx in perfectIndices) {
    print(
        '  Student ${idx[0] + 1}, Test ${idx[1] + 1}: ${grades.getValue(idx)}');
  }

  // Check if any student failed (< 70)
  final hasFailures = grades.any((x) => x < 70);
  print('\nHas any failing grade: $hasFailures');

  // Count passing grades per student
  for (int i = 0; i < 5; i++) {
    final studentGrades = grades.slice([
      Slice.range(i, i + 1),
      Slice.range(0, 5),
    ]) as NDArray;
    final passing = studentGrades.countWhere((x) => x >= 70);
    print('Student ${i + 1} passing tests: $passing/5');
  }

  print('\n=== Examples Complete ===');
}
