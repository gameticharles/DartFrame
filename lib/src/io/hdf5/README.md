# HDF5 Support for DartFrame

Pure Dart implementation of HDF5 file format reading for DartFrame.

## Features

- **Pure Dart**: No FFI dependencies, works on all Dart platforms
- **File I/O**: Efficient random access reading
- **Core Format**: Superblock, object headers, messages
- **Data Types**: int8, uint8, int16, uint16, int32, uint32, float32, float64
- **Datasets**: Contiguous layout support
- **Groups**: Basic navigation
- **Dataspaces**: Multi-dimensional array support

## Usage

### Basic Reading

```dart
import 'package:dartframe/dartframe.dart';

// Read HDF5 file into DataFrame
final df = await FileReader.readHDF5(
  'data.h5',
  dataset: '/my_dataset',
);

print(df.head());
```

### Inspect File Structure

```dart
// Get file information
final info = await FileReader.inspectHDF5('data.h5');
print('Version: ${info['version']}');
print('Datasets: ${info['rootChildren']}');

// List all datasets
final datasets = await FileReader.listHDF5Datasets('data.h5');
for (final dataset in datasets) {
  print('Found dataset: $dataset');
}
```

### Automatic Format Detection

```dart
// FileReader automatically detects .h5 and .hdf5 extensions
final df = await FileReader.read('data.h5', options: {
  'dataset': '/my_data',
});
```

## Architecture

### Components

- **byte_reader.dart**: Low-level binary file reading with endianness support
- **superblock.dart**: HDF5 file header parsing
- **object_header.dart**: Object metadata and messages
- **datatype.dart**: Type system mapping
- **dataspace.dart**: Array dimensionality
- **dataset.dart**: Typed array data reading
- **group.dart**: Hierarchical structure navigation
- **hdf5_file.dart**: High-level file interface

### Integration

- **hdf5_reader.dart**: DataReader implementation for dartframe
- Registered in `FileReader` for `.h5` and `.hdf5` extensions
- Converts HDF5 datasets to DataFrame format

## Limitations

Current implementation is focused on common use cases:

- **Read-only**: No file creation or modification
- **Contiguous layout**: Chunked datasets not yet supported
- **No compression**: Uncompressed data only
- **No attributes**: Metadata attributes not read
- **Simple groups**: Basic group navigation only
- **Common types**: Standard numeric types only

## Creating HDF5 Files

For creating HDF5 files, we recommend using Python with h5py:

```python
import h5py
import numpy as np

with h5py.File('data.h5', 'w') as f:
    # 1D dataset
    f.create_dataset('data1d', data=np.array([1.0, 2.0, 3.0]))
    
    # 2D dataset
    f.create_dataset('data2d', data=np.array([[1, 2], [3, 4]]))
```

Then read in Dart:

```dart
final df = await FileReader.readHDF5('data.h5', dataset: '/data2d');
```

## Error Handling

```dart
try {
  final df = await FileReader.readHDF5('data.h5', dataset: '/mydata');
} on HDF5ReadError catch (e) {
  print('HDF5 error: $e');
} catch (e) {
  print('General error: $e');
}
```

## Performance

- Efficient random access file reading
- Minimal memory overhead
- Suitable for small to medium datasets
- For large datasets, consider chunked reading (future enhancement)

## Future Enhancements

- Chunked dataset support
- Compression (gzip, lzf)
- Attribute reading
- String datasets
- Compound datatypes
- Virtual datasets
- Parallel I/O

## Contributing

Contributions welcome! Areas for improvement:

1. Chunked dataset reading
2. More datatype support
3. Attribute handling
4. Performance optimizations
5. Test coverage
6. Documentation

## References

- [HDF5 File Format Specification](https://docs.hdfgroup.org/hdf5/develop/_f_m_t3.html)
- [HDF5 User Guide](https://portal.hdfgroup.org/display/HDF5/HDF5)
- [h5py Documentation](https://docs.h5py.org/)
