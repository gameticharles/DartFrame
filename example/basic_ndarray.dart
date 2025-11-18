import 'package:dartframe/dartframe.dart';

void main() {
  print('=== DartFrame NDArray Examples ===\n');

  // 1. Creating Arrays
  print('1. Creating Arrays');
  print('-' * 40);

  final array1 = NDArray([1, 2, 3, 4, 5]);
  print('1D array: $array1');

  final array2d = NDArray([
    [1, 2, 3],
    [4, 5, 6]
  ]);
  print('2D array:\n$array2d');

  final zeros = NDArray.zeros([3, 3]);
  print('Zeros:\n$zeros');

  final ones = NDArray.ones([2, 4]);
  print('Ones:\n$ones');

  final filled = NDArray.filled([3, 2], 7);
  print('Filled with 7:\n$filled');

  final generated = NDArray.generate([5], (indices) => indices[0] * 2);
  print('Generated (0, 2, 4, 6, 8): $generated\n');

  // 2. Array Properties
  print('2. Array Properties');
  print('-' * 40);

  final array = NDArray([
    [1, 2, 3],
    [4, 5, 6]
  ]);
  print('Array:\n$array');
  print('Shape: ${array.shape}');
  print('Dimensions: ${array.ndim}');
  print('Size: ${array.size}\n');

  // 3. Indexing
  print('3. Indexing');
  print('-' * 40);

  final matrix = NDArray([
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12]
  ]);
  print('Matrix:\n$matrix');

  print('Element at [1, 2]: ${matrix.getValue([1, 2])}');
  print('Element at [0, 0]: ${matrix.getValue([0, 0])}\n');

  // 4. Arithmetic Operations
  print('4. Arithmetic Operations');
  print('-' * 40);

  final a = NDArray([1, 2, 3, 4]);
  final b = NDArray([5, 6, 7, 8]);

  print('a = $a');
  print('b = $b');
  print('a + b = ${a + b}');
  print('a - b = ${a - b}');
  print('a * b = ${a * b}');
  print('a / b = ${a / b}');
  print('a + 10 = ${a + 10}');
  print('a * 2 = ${a * 2}\n');

  // 5. Reshaping
  print('5. Reshaping');
  print('-' * 40);

  final original = NDArray([1, 2, 3, 4, 5, 6]);
  print('Original: $original');

  final reshaped = original.reshape([2, 3]);
  print('Reshaped to [2, 3]:\n$reshaped');

  final flattened = reshaped.reshape([6]);
  print('Flattened: $flattened\n');

  // 6. Filtering
  print('6. Filtering');
  print('-' * 40);

  final numbers = NDArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  print('Numbers: $numbers');

  final filtered = numbers.where((x) => x > 5);
  print('Greater than 5: $filtered');

  final even = numbers.where((x) => x % 2 == 0);
  print('Even numbers: $even');

  final count = numbers.countWhere((x) => x > 5);
  print('Count > 5: $count');

  final hasLarge = numbers.any((x) => x > 8);
  print('Any > 8: $hasLarge');

  final allPositive = numbers.all((x) => x > 0);
  print('All positive: $allPositive\n');

  // 7. Boolean Masking
  print('7. Boolean Masking');
  print('-' * 40);

  final values = NDArray([1, 2, 3, 4, 5]);
  print('Values: $values');

  final mask = values.createMask((x) => x > 2);
  print('Mask (x > 2): $mask');

  final masked = values.mask(mask);
  print('Masked values: $masked\n');

  // 8. Advanced Indexing
  print('8. Advanced Indexing');
  print('-' * 40);

  final arr = NDArray([10, 20, 30, 40, 50]);
  print('Array: $arr');

  final selected = arr.indexWith([0, 2, 4]);
  print('Select indices [0, 2, 4]: $selected');

  final taken = arr.take([1, 3]);
  print('Take indices [1, 3]: $taken\n');

  // 9. In-place Modifications
  print('9. In-place Modifications');
  print('-' * 40);

  final mutable = NDArray([1, 2, 3, 4, 5]);
  print('Original: $mutable');

  mutable.put([0, 2, 4], 0);
  print('After put([0, 2, 4], 0): $mutable');

  final mutable2 = NDArray([1, 2, 3, 4, 5]);
  mutable2.putValues([1, 3], [10, 20]);
  print('After putValues([1, 3], [10, 20]): $mutable2\n');

  // 10. Mapping
  print('10. Mapping');
  print('-' * 40);

  final data = NDArray([1, 2, 3, 4, 5]);
  print('Original: $data');

  final doubled = data.map((x) => x * 2);
  print('Doubled: $doubled');

  final squared = data.map((x) => x * x);
  print('Squared: $squared\n');

  // 11. Copying
  print('11. Copying');
  print('-' * 40);

  final source = NDArray([1, 2, 3]);
  print('Source: $source');

  final copied = source.copy();
  copied.setValue([0], 100);

  print('After modifying copy:');
  print('Source: $source');
  print('Copy: $copied\n');

  // 12. Conversion
  print('12. Conversion');
  print('-' * 40);

  final array3d = NDArray([
    [
      [1, 2],
      [3, 4]
    ],
    [
      [5, 6],
      [7, 8]
    ]
  ]);
  print('3D Array: $array3d');

  final nested = array3d.toNestedList();
  print('To nested list: $nested');

  final flat = array3d.toFlatList();
  print('To flat list: $flat\n');

  print('=== Examples Complete ===');
}
