import 'package:dartframe/dartframe.dart';

/// Example demonstrating polymorphic usage of DartData interface
/// across DataFrame, Series, NDArray, and DataCube
void main() {
  print('=== DartData Polymorphism Example ===\n');

  // Create different data structures
  final dataStructures = <DartData>[
    // 2D DataFrame (heterogeneous)
    DataFrame.fromMap({
      'id': [1, 2, 3],
      'name': ['Alice', 'Bob', 'Charlie'],
      'score': [95.5, 87.3, 92.1],
    }),

    // 1D Series (homogeneous)
    Series([10, 20, 30, 40, 50], name: 'measurements'),

    // 3D NDArray (homogeneous)
    NDArray.generate([2, 3, 4], (indices) {
      return indices[0] * 100 + indices[1] * 10 + indices[2];
    }),

    // 3D DataCube (homogeneous)
    DataCube.generate(2, 3, 4, (d, r, c) => d * 100 + r * 10 + c),
  ];

  // Process all structures polymorphically
  for (var i = 0; i < dataStructures.length; i++) {
    final data = dataStructures[i];
    print('Structure ${i + 1}: ${data.runtimeType}');
    print('  Dimensions: ${data.ndim}D');
    print('  Shape: ${data.shape}');
    print('  Size: ${data.size} elements');
    print('  Homogeneous: ${data.isHomogeneous}');
    print('  Data type: ${data.dtype}');

    if (data.columnTypes != null) {
      print('  Column types: ${data.columnTypes}');
    }

    // Add metadata
    data.attrs['created'] = DateTime.now();
    data.attrs['source'] = 'example';
    data.attrs['version'] = '1.0';

    print('  Metadata: ${data.attrs.length} attributes');
    print('');
  }

  // Demonstrate unified slicing
  print('=== Unified Slicing ===\n');

  final df = DataFrame([
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  ], columns: [
    'A',
    'B',
    'C'
  ]);

  print('Original DataFrame:');
  print(df);
  print('');

  // Single element -> Scalar
  final scalar = df.slice([0, 1]);
  print('df.slice([0, 1]) -> Scalar: ${(scalar as Scalar).value}');

  // Single row -> Series
  final row = df.slice([1, Slice.all()]);
  print('df.slice([1, Slice.all()]) -> Series: ${(row as Series).data}');

  // Range -> DataFrame
  final subDf = df.slice([Slice.range(0, 2), Slice.range(1, 3)]);
  print('df.slice([Slice.range(0, 2), Slice.range(1, 3)]) -> DataFrame:');
  print(subDf);
  print('');

  // Demonstrate metadata usage
  print('=== Metadata Example ===\n');

  final series = Series([1.5, 2.3, 3.7, 4.2], name: 'temperature');
  series.attrs['units'] = 'celsius';
  series.attrs['sensor_id'] = 'TEMP_001';
  series.attrs['location'] = 'Lab A';
  series.attrs['calibration_date'] = DateTime(2024, 1, 15);

  print('Series: ${series.name}');
  print('Data: ${series.data}');
  print('Metadata:');
  for (var key in series.attrs.keys) {
    print('  $key: ${series.attrs[key]}');
  }
  print('');

  // Generic function that works with any DartData
  print('=== Generic Processing ===\n');
  processAnyData(df);
  processAnyData(series);
  processAnyData(NDArray.fromFlat([1, 2, 3, 4, 5, 6], [2, 3]));
}

/// Generic function that processes any DartData structure
void processAnyData(DartData data) {
  print('Processing ${data.runtimeType}:');
  print('  Shape: ${data.shape}');
  print('  Total elements: ${data.size}');

  if (data.isHomogeneous) {
    print('  Type: ${data.dtype} (homogeneous)');
  } else {
    print('  Type: mixed (heterogeneous)');
    if (data.columnTypes != null) {
      print('  Column types: ${data.columnTypes}');
    }
  }

  // Add processing metadata
  data.attrs['processed_at'] = DateTime.now();
  data.attrs['processor'] = 'processAnyData';

  print('  Metadata added: ${data.attrs.length} attributes');
  print('');
}
