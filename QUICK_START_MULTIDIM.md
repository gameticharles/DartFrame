# Quick Start: Multi-dimensional HDF5 Datasets

## Reading 3D+ Datasets

```dart
import 'package:dartframe/dartframe.dart';

// Read a 3D dataset
final df = await FileReader.readHDF5('data.h5', dataset: '/volume');

// Get shape information
final shapeStr = df['_shape'][0];  // "2x3x4"
final ndim = df['_ndim'][0];       // 3

// Parse shape
final shape = shapeStr.split('x').map(int.parse).toList(); // [2, 3, 4]

// Get flattened data (row-major order)
final flatData = df['data'].data;  // Note: .data gets the list from Series
```

## Reshaping Data

### 3D Reshape

```dart
List<List<List<dynamic>>> reshape3D(List<dynamic> flat, List<int> shape) {
  final result = <List<List<dynamic>>>[];
  int idx = 0;
  
  for (int i = 0; i < shape[0]; i++) {
    final plane = <List<dynamic>>[];
    for (int j = 0; j < shape[1]; j++) {
      final row = <dynamic>[];
      for (int k = 0; k < shape[2]; k++) {
        row.add(flat[idx++]);
      }
      plane.add(row);
    }
    result.add(plane);
  }
  
  return result;
}

// Usage
final reshaped = reshape3D(flatData, shape);
print(reshaped[0][0][0]); // Access element at [0,0,0]
```

### 4D Reshape

```dart
List<List<List<List<dynamic>>>> reshape4D(List<dynamic> flat, List<int> shape) {
  final result = <List<List<List<dynamic>>>>[];
  int idx = 0;
  
  for (int i = 0; i < shape[0]; i++) {
    final volume = <List<List<dynamic>>>[];
    for (int j = 0; j < shape[1]; j++) {
      final plane = <List<dynamic>>[];
      for (int k = 0; k < shape[2]; k++) {
        final row = <dynamic>[];
        for (int l = 0; l < shape[3]; l++) {
          row.add(flat[idx++]);
        }
        plane.add(row);
      }
      volume.add(plane);
    }
    result.add(volume);
  }
  
  return result;
}
```

## Complete Example

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Read 3D dataset
  final df = await FileReader.readHDF5('volume.h5', dataset: '/data');
  
  // Parse shape
  final shape = (df['_shape'][0] as String)
      .split('x')
      .map(int.parse)
      .toList();
  
  print('Dataset shape: $shape');
  print('Dimensions: ${df['_ndim'][0]}');
  
  // Get data
  final data = df['data'].data;
  print('Total elements: ${data.length}');
  
  // Reshape to 3D
  final reshaped = reshape3D(data, shape);
  
  // Access specific elements
  print('Element at [0,0,0]: ${reshaped[0][0][0]}');
  print('Element at [1,2,3]: ${reshaped[1][2][3]}');
  
  // Process slices
  for (int i = 0; i < shape[0]; i++) {
    print('Slice $i: ${reshaped[i]}');
  }
}
```

## Key Points

1. **Data is flattened**: All 3D+ datasets are stored as 1D arrays in row-major order
2. **Shape preserved**: Use `_shape` and `_ndim` columns to get original dimensions
3. **Series access**: Remember to use `.data` to get the underlying list from Series
4. **Backward compatible**: 1D and 2D datasets work exactly as before

## Testing

Generate test data:
```bash
python3 scripts/create_multidim_test_data.py
```

Run example:
```bash
dart run example/hdf5_multidimensional.dart
```

Run tests:
```bash
dart test test/integration/hdf5_multidim_test.dart
```
