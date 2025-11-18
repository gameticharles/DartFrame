# Getting Started with DartFrame

## Installation

Add DartFrame to your `pubspec.yaml`:

```yaml
dependencies:
  dartframe: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### Basic NDArray Operations

```dart
import 'package:dartframe/dartframe.dart';

void main() {
  // Create an array
  final array = NDArray([[1, 2, 3], [4, 5, 6]]);
  
  print('Shape: ${array.shape}');  // Shape: [2, 3]
  print('Size: ${array.size}');    // Size: 6
  
  // Arithmetic operations
  final doubled = array * 2;
  final sum = array + 10;
  
  // Aggregations
  print('Sum: ${array.sum()}');    // Sum: 21
  print('Mean: ${array.mean()}');  // Mean: 3.5
  
  // Slicing
  final slice = array.slice([
    SliceRange(0, 2),  // All rows
    SliceRange(1, 3),  // Columns 1-2
  ]);
  print(slice);  // [[2, 3], [5, 6]]
}
```

### Working with DataCubes

```dart
import 'package:dartframe/dartframe.dart';

void main() {
  // Create a DataCube (3D data structure)
  final cube = DataCube.generate(
    3,  // depth (e.g., time periods)
    5,  // rows
    4,  // columns
    (d, r, c) => d * 100 + r * 10 + c,
  );
  
  print('Shape: ${cube.shape}');  // [3, 5, 4]
  
  // Access frames
  final frame0 = cube.getFrame(0);
  print('Frame 0:\n$frame0');
  
  // Aggregate across dimensions
  final meanByFrame = cube.mean(axis: 1);  // Mean per frame
  print('Mean by frame: $meanByFrame');
  
  // Filter and select
  final filtered = cube.selectFrames((frame) => 
    frame.getValue(0, 0) > 50
  );
  print('Filtered frames: ${filtered.depth}');
}
```

## Core Concepts

### 1. NDArray - Multi-dimensional Arrays

NDArray is the foundation for numerical computing in DartFrame:

```dart
// Create arrays in different ways
final zeros = NDArray.zeros([3, 4]);
final ones = NDArray.ones([2, 3]);
final filled = NDArray.filled([2, 3], 5);
final generated = NDArray.generate([5], (indices) => indices[0] * 2);

// From existing data
final fromList = NDArray([[1, 2], [3, 4]]);
```

### 2. DataCube - 3D Data Structures

DataCube extends DataFrame concepts to three dimensions:

```dart
// Create from DataFrames
final frame1 = DataFrame([{'a': 1, 'b': 2}]);
final frame2 = DataFrame([{'a': 3, 'b': 4}]);
final cube = DataCube([frame1, frame2]);

// Or generate directly
final generated = DataCube.generate(10, 100, 5, 
  (d, r, c) => random.nextDouble()
);
```

### 3. Storage Backends

DartFrame supports multiple storage backends:

```dart
// In-memory (default)
final array = NDArray([1, 2, 3]);

// Memory-mapped files
final mmapped = NDArray.zeros([1000, 1000]);
await mmapped.save('data.bin', backend: 'mmap');

// HDF5 format
final cube = DataCube.generate(100, 1000, 50, (d, r, c) => d);
await cube.save('data.h5', format: 'hdf5');
```

### 4. Compression

Reduce storage size with compression:

```dart
// Save with compression
await cube.save('data.h5', 
  compression: ZstdCodec(level: 3)
);

// Automatic compression for large arrays
final large = NDArray.zeros([10000, 10000]);
await large.save('large.h5', compression: ZstdCodec());
```

## Common Operations

### Filtering and Selection

```dart
final array = NDArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

// Filter by condition
final filtered = array.where((x) => x > 5);
print(filtered);  // [6, 7, 8, 9, 10]

// Get indices
final indices = array.whereIndices((x) => x % 2 == 0);
print(indices);  // [[1], [3], [5], [7], [9]]

// Boolean masking
final mask = array.createMask((x) => x > 5);
final masked = array.mask(mask);
```

### Reshaping

```dart
final array = NDArray([1, 2, 3, 4, 5, 6]);

// Reshape to 2D
final reshaped = array.reshape([2, 3]);
print(reshaped);  // [[1, 2, 3], [4, 5, 6]]

// Flatten back to 1D
final flat = reshaped.flatten();
print(flat);  // [1, 2, 3, 4, 5, 6]

// Transpose
final transposed = reshaped.transpose();
print(transposed);  // [[1, 4], [2, 5], [3, 6]]
```

### Aggregations

```dart
final array = NDArray([[1, 2, 3], [4, 5, 6]]);

// Overall statistics
print('Sum: ${array.sum()}');      // 21
print('Mean: ${array.mean()}');    // 3.5
print('Min: ${array.min()}');      // 1
print('Max: ${array.max()}');      // 6
print('Std: ${array.std()}');      // ~1.71

// Along axes
print('Row sums: ${array.sum(axis: 0)}');     // [5, 7, 9]
print('Column sums: ${array.sum(axis: 1)}');  // [6, 15]
```

## Performance Tips

### 1. Use Appropriate Data Types

```dart
// Use int32 for integer data
final ints = NDArray([1, 2, 3], dtype: DType.int32);

// Use float32 for reduced precision
final floats = NDArray([1.0, 2.0, 3.0], dtype: DType.float32);
```

### 2. Leverage Lazy Evaluation

```dart
// Chain operations lazily
final result = array.lazy()
  .map((x) => x * 2)
  .filter((x) => x > 10)
  .map((x) => x / 2)
  .compute();  // Execute all at once
```

### 3. Use Memory-Mapped Files for Large Data

```dart
// For data larger than RAM
final large = NDArray.zeros([100000, 10000]);
await large.save('large.bin', backend: 'mmap');

// Load without reading entire file into memory
final loaded = await NDArray.load('large.bin', backend: 'mmap');
```

### 4. Enable Compression

```dart
// Compress when saving
await cube.save('data.h5', compression: ZstdCodec(level: 3));

// Automatic decompression on load
final loaded = await DataCube.load('data.h5');
```

## Next Steps

- [NDArray Basics](ndarray_basics.md) - Deep dive into NDArray
- [DataCube Basics](datacube_basics.md) - Working with 3D data
- [Performance Guide](performance.md) - Optimization techniques
- [API Reference](../api/ndarray.md) - Complete API documentation

## Examples

Check out the `example/` directory for more examples:

- `basic_ndarray.dart` - NDArray fundamentals
- `datacube_operations.dart` - DataCube usage
- `filtering_selection.dart` - Advanced filtering
- `large_dataset.dart` - Working with large data
- `compression_demo.dart` - Compression examples

## Getting Help

- GitHub Issues: [Report bugs or request features](https://github.com/yourusername/dartframe/issues)
- Documentation: [Full documentation](https://dartframe.dev)
- Examples: [Code examples](https://github.com/yourusername/dartframe/tree/main/example)
