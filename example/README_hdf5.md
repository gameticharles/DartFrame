# HDF5 Reading Examples

This directory contains comprehensive examples for reading HDF5 files with DartFrame.

## Overview

DartFrame provides pure Dart HDF5 reading capabilities with no FFI dependencies, making it cross-platform compatible (Windows, macOS, Linux, Web, Mobile).

## Example Files

### Basic Examples

- **`hdf5_basic_reading.dart`** - Fundamental HDF5 reading operations
  - Opening and reading datasets
  - Converting to DataFrames
  - Basic error handling
  - Working with different data types

- **`hdf5_group_navigation.dart`** - Navigating HDF5 file hierarchies
  - Inspecting file structure
  - Listing datasets and groups
  - Accessing nested datasets
  - Understanding file organization

- **`hdf5_attributes.dart`** - Reading dataset attributes (metadata)
  - Accessing attribute values
  - Using attributes for data description
  - Handling missing attributes

- **`hdf5_advanced_features.dart`** - Advanced HDF5 capabilities
  - Reading compressed datasets (gzip, lzf)
  - Reading chunked datasets
  - Debug mode for troubleshooting
  - MATLAB v7.3 file compatibility

## Quick Start

### Reading a Simple Dataset

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Read a dataset from an HDF5 file
  final df = await FileReader.readHDF5(
    'data.h5',
    dataset: '/mydata',
  );
  
  print('Shape: ${df.shape}');
  print(df.head());
}
```


### Inspecting File Structure

```dart
// Get information about the file
final info = await HDF5Reader.inspect('data.h5');
print('HDF5 Version: ${info['version']}');
print('Datasets: ${info['datasets']}');

// List all datasets
final datasets = await HDF5Reader.listDatasets('data.h5');
print('Available datasets: $datasets');
```

### Reading Attributes

```dart
// Read metadata attached to a dataset
final attrs = await HDF5Reader.readAttributes(
  'data.h5',
  dataset: '/mydata',
);

print('Units: ${attrs['units']}');
print('Description: ${attrs['description']}');
```

### Debug Mode

```dart
// Enable debug mode for troubleshooting
final df = await FileReader.readHDF5(
  'data.h5',
  dataset: '/mydata',
  options: {'debug': true}, // Verbose logging
);
```

## Supported Features

### Data Types
- ✅ Integer types (int8, int16, int32, int64)
- ✅ Unsigned integer types (uint8, uint16, uint32, uint64)
- ✅ Floating-point types (float32, float64)
- ✅ String types (fixed-length and variable-length)
- ✅ Compound types (structs with multiple fields)
- ✅ Array types
- ✅ Enum types

### Storage Layouts
- ✅ Contiguous storage
- ✅ Chunked storage with B-tree indexing


### Compression
- ✅ Gzip compression
- ✅ LZF compression
- ✅ Shuffle filter

### File Formats
- ✅ HDF5 versions 0, 1, 2, 3
- ✅ MATLAB v7.3 MAT-files (HDF5-based)
- ✅ Files from Python h5py
- ✅ Files from R
- ✅ Files from other HDF5 tools

### Features
- ✅ Group navigation (old-style and new-style)
- ✅ Attribute reading
- ✅ File inspection without reading data
- ✅ Soft links and hard links
- ✅ External links
- ✅ Multi-offset signature detection

## Running the Examples

```bash
# Run basic reading examples
dart run example/hdf5_basic_reading.dart

# Run group navigation examples
dart run example/hdf5_group_navigation.dart

# Run attribute examples
dart run example/hdf5_attributes.dart

# Run advanced features examples
dart run example/hdf5_advanced_features.dart
```

## Creating Test Files

Some examples require test HDF5 files. You can create them using Python:

```bash
# Create chunked dataset file
python create_chunked_hdf5.py

# Create compressed dataset file
python create_compressed_hdf5.py

# Create file with attributes
python create_attributes_test.py
```

## API Reference

### FileReader.readHDF5()

Read an HDF5 dataset and convert to DataFrame.


```dart
Future<DataFrame> FileReader.readHDF5(
  String path, {
  String dataset = '/data',
  bool debug = false,
})
```

Parameters:
- `path`: Path to the HDF5 file
- `dataset`: Path to the dataset within the file (default: '/data')
- `debug`: Enable verbose logging (default: false)

Returns: DataFrame containing the dataset

### HDF5Reader.inspect()

Get information about an HDF5 file structure.

```dart
Future<Map<String, dynamic>> HDF5Reader.inspect(
  String path, {
  bool debug = false,
})
```

Returns: Map with file version, root children, and datasets

### HDF5Reader.listDatasets()

List all datasets in an HDF5 file.

```dart
Future<List<String>> HDF5Reader.listDatasets(
  String path, {
  bool debug = false,
})
```

Returns: List of dataset names

### HDF5Reader.readAttributes()

Read attributes (metadata) from a dataset.

```dart
Future<Map<String, dynamic>> HDF5Reader.readAttributes(
  String path, {
  String dataset = '/data',
  bool debug = false,
})
```

Returns: Map of attribute names to values

## Troubleshooting

### Common Issues

**"Invalid HDF5 signature"**
- The file is not a valid HDF5 file
- The file may be corrupted
- Try opening with debug mode to see details


**"Dataset not found"**
- Check the dataset path (use `listDatasets()` to see available datasets)
- Ensure the path starts with '/'
- Verify the file contains the expected dataset

**"Unsupported feature"**
- Some advanced HDF5 features may not be supported yet
- Enable debug mode to see what feature is unsupported
- Check the limitations section below

**Performance issues with large files**
- HDF5 reading uses random access I/O for efficiency
- Chunked datasets are read chunk-by-chunk
- Consider using streaming for very large datasets

### Debug Mode

Enable debug mode to see detailed information about file parsing:

```dart
HDF5Reader.setDebugMode(true);
// or
final df = await FileReader.readHDF5('data.h5', debug: true);
```

Debug output includes:
- Superblock parsing details
- Object header messages
- B-tree traversal
- Chunk reading operations
- Decompression steps

## Limitations

### Current Limitations
- Writing HDF5 files is not yet supported (read-only)
- Some advanced features (VDS, region references) are not supported

### Supported Features
- ✅ 1D and 2D datasets converted to DataFrames
- ✅ 3D+ datasets flattened with shape metadata
- ✅ All HDF5 datatypes (numeric, string, compound, enum, array, etc.)
- ✅ Chunked, contiguous, and compact storage layouts
- ✅ Compression (gzip, shuffle, etc.)

### Performance
- Optimized for files under 1GB
- Memory usage is approximately 2x dataset size
- Chunked reading helps with large datasets

## Limitations

### What's Supported
- ✅ Common datatypes: integers, floats, strings, compounds, arrays, enums
- ✅ Gzip and LZF compression
- ✅ Chunked and contiguous storage
- ✅ Group navigation and attributes
- ✅ 1D and 2D datasets

### What's Not Supported
- ❌ Writing HDF5 files (read-only)
- ❌ Complex numbers (not in HDF5 spec)
- ❌ Some advanced features (VDS, region references)
- ❌ Virtual datasets (VDS)
- ❌ Advanced filters (SZIP, scale-offset, n-bit)

For detailed limitations and workarounds, see the [complete documentation](../doc/hdf5.md#limitations).

## Additional Resources

- [HDF5 Format Specification](https://www.hdfgroup.org/solutions/hdf5/)
- [DartFrame Documentation](../doc/)
- [Python h5py Documentation](https://docs.h5py.org/)
- [Complete HDF5 Guide](../doc/hdf5.md) - Detailed documentation with limitations

## Contributing

Found a bug or want to add a feature? Contributions are welcome!
