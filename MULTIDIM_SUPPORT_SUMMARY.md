# Multi-dimensional Dataset Support Implementation

## Summary

Successfully implemented support for 3D+ (multi-dimensional) HDF5 datasets in DartFrame. Previously, only 1D and 2D datasets were supported, and 3D+ datasets would throw an error. Now all dimensionalities are supported.

## Changes Made

### 1. Core Implementation (`lib/src/io/hdf5_reader.dart`)

Modified the `HDF5Reader.read()` method to handle 3D+ datasets:

- **Before**: Threw `UnsupportedFeatureError` for datasets with more than 2 dimensions
- **After**: Flattens 3D+ datasets to 1D and stores shape information in special columns:
  - `data`: The flattened dataset values (row-major order)
  - `_shape`: Shape as a string (e.g., "2x3x4")
  - `_ndim`: Number of dimensions (e.g., 3)

### 2. Documentation Updates

#### `doc/hdf5.md`
- Updated limitations section to show 3D+ support
- Added comprehensive guide on working with multi-dimensional datasets
- Included example code for parsing shape and reshaping data

#### `example/README_hdf5.md`
- Removed 3D+ limitation from "Current Limitations"
- Added to "Supported Features" list
- Updated "What's Not Supported" section

### 3. Test Infrastructure

#### `test/integration/hdf5_multidim_test.dart`
- Tests for reading 3D datasets with shape information
- Tests for reading 4D datasets
- Backward compatibility tests for 1D and 2D datasets

#### `scripts/create_multidim_test_data.py`
- Python script to generate test HDF5 files with:
  - 3D dataset (2x3x4)
  - 4D dataset (2x3x4x5)
  - 5D dataset (2x2x2x2x2)
  - Mixed dimensionality file (1D, 2D, and 3D datasets)

### 4. Example Code

#### `example/hdf5_multidimensional.dart`
- Demonstrates reading 3D and 4D datasets
- Shows how to parse shape information
- Includes helper functions for reshaping:
  - `reshape3D()`: Converts flat list to 3D structure
  - `reshape4D()`: Converts flat list to 4D structure

## Usage Example

```dart
// Read a 3D dataset
final df = await FileReader.readHDF5('data.h5', dataset: '/volume');

// Access shape information
final shapeStr = df['_shape'][0]; // e.g., "2x3x4"
final ndim = df['_ndim'][0];      // e.g., 3

// Parse the shape
final shape = shapeStr.split('x').map(int.parse).toList();
print('Original shape: $shape'); // [2, 3, 4]

// Access flattened data
final flatData = df['data'].data; // .data gets the underlying list from Series

// Reshape if needed
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

final reshaped = reshape3D(flatData, shape);
```

## Design Decisions

### Why Flatten Instead of Nested Lists?

1. **DataFrame Compatibility**: DataFrame is designed for 2D tabular data. Storing nested lists would break many DataFrame operations.

2. **Consistency**: All data is stored in a consistent columnar format, making it easier to work with.

3. **Flexibility**: Users can reshape the data as needed for their specific use case.

4. **Metadata Preservation**: Shape information is preserved and easily accessible.

### Why Use Special Columns Instead of Metadata?

DataFrame doesn't currently have a metadata system. Using special columns (`_shape`, `_ndim`) is:
- Simple and works with existing DataFrame infrastructure
- Easy to access and query
- Doesn't require changes to the DataFrame class
- Follows a clear naming convention (underscore prefix)

## Testing

To test the implementation:

1. Generate test data:
   ```bash
   python3 scripts/create_multidim_test_data.py
   ```

2. Run tests:
   ```bash
   dart test test/integration/hdf5_multidim_test.dart
   ```

3. Run example:
   ```bash
   dart run example/hdf5_multidimensional.dart
   ```

## Backward Compatibility

- ✅ 1D datasets work exactly as before (single 'data' column)
- ✅ 2D datasets work exactly as before (multiple columns)
- ✅ No breaking changes to existing code
- ✅ Special columns (`_shape`, `_ndim`) only added for 3D+ datasets

## Limitations Resolved

| Limitation | Status | Notes |
|------------|--------|-------|
| 1D datasets | ✅ Supported | Always supported |
| 2D datasets | ✅ Supported | Always supported |
| 3D+ datasets | ✅ **NOW SUPPORTED** | Flattened with shape metadata |
| Writing HDF5 | ❌ Not supported | Read-only (future enhancement) |

## Future Enhancements

Potential improvements for the future:
1. Add DataFrame metadata system for cleaner shape storage
2. Add built-in reshape methods to DataFrame
3. Support for tensor operations on multi-dimensional data
4. Lazy loading for very large multi-dimensional datasets
