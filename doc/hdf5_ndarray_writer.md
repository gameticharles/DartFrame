# HDF5 Writer for NDArray

The HDF5 writer provides comprehensive support for writing N-dimensional arrays to HDF5 files with advanced features including chunked storage, compression, and full interoperability with Python (h5py, pandas), MATLAB, and R.

## Features

- **N-dimensional array support**: Write arrays of any dimensionality
- **Storage layouts**: Contiguous and chunked storage
- **Compression**: GZIP and LZF compression algorithms
- **Auto-chunking**: Automatic calculation of optimal chunk dimensions
- **Attribute preservation**: Metadata is automatically preserved
- **Memory efficiency**: Chunked writing for large datasets
- **C-contiguous layout**: Row-major layout for MATLAB/Python compatibility
- **Datatype support**: int64 and float64 datatypes
- **Multiple datasets**: Write multiple arrays to a single file

## Basic Usage

### Simple Write

```dart
import 'package:dartframe/dartframe.dart';

// Create an NDArray
final array = NDArray.generate([10, 20], (indices) {
  return indices[0] * 20 + indices[1];
});

// Write to HDF5 file
await array.toHDF5('data.h5', dataset: '/data');
```

### With Attributes

```dart
final array = NDArray.zeros([5, 5]);
array.attrs['units'] = 'meters';
array.attrs['description'] = 'Temperature data';

await array.toHDF5('data.h5', dataset: '/temperature');
```

## Storage Layouts

### Contiguous Storage

Contiguous storage writes data in a single continuous block. This is the default and is best for small to medium datasets that are typically read in their entirety.

```dart
await array.toHDF5(
  'data.h5',
  dataset: '/data',
  options: WriteOptions(
    layout: StorageLayout.contiguous,
  ),
);
```

**Advantages:**
- Simple and fast for small datasets
- No overhead from chunk indexing
- Best for sequential access patterns

**Disadvantages:**
- Cannot use compression
- Inefficient for partial reads of large datasets

### Chunked Storage

Chunked storage divides the dataset into fixed-size chunks. This enables compression and efficient partial I/O.

```dart
await array.toHDF5(
  'data.h5',
  dataset: '/data',
  options: WriteOptions(
    layout: StorageLayout.chunked,
    chunkDimensions: [100, 100],
  ),
);
```

**Advantages:**
- Enables compression
- Efficient partial reads
- Better for large datasets
- Supports parallel I/O

**Disadvantages:**
- Small overhead from chunk indexing
- Requires careful chunk size selection

## Compression

### GZIP Compression

GZIP (DEFLATE) is the most widely supported compression algorithm in HDF5. It provides good compression ratios but is slower than LZF.

```dart
await array.toHDF5(
  'data.h5',
  dataset: '/data',
  options: WriteOptions(
    layout: StorageLayout.chunked,
    chunkDimensions: [100, 100],
    compression: CompressionType.gzip,
    compressionLevel: 6,  // 1-9, default is 6
  ),
);
```

**Compression levels:**
- 1: Fastest compression, larger output
- 6: Balanced (default)
- 9: Best compression, slower

**Use cases:**
- Long-term storage where file size matters
- Data with high redundancy
- When compatibility is important

### LZF Compression

LZF is a fast compression algorithm with moderate compression ratios. It's faster than GZIP but produces larger files.

```dart
await array.toHDF5(
  'data.h5',
  dataset: '/data',
  options: WriteOptions(
    layout: StorageLayout.chunked,
    chunkDimensions: [100, 100],
    compression: CompressionType.lzf,
  ),
);
```

**Use cases:**
- When write speed is critical
- Temporary or intermediate files
- Real-time data acquisition

## Chunk Dimensions

### Manual Chunk Selection

Specify exact chunk dimensions for fine-grained control:

```dart
await array.toHDF5(
  'data.h5',
  dataset: '/data',
  options: WriteOptions(
    layout: StorageLayout.chunked,
    chunkDimensions: [50, 100, 80],  // Must match array rank
  ),
);
```

**Guidelines for chunk selection:**
- Aim for chunks around 1MB in size
- Consider access patterns (row-wise vs column-wise)
- Balance between I/O efficiency and overhead
- Smaller chunks = more overhead but better partial access
- Larger chunks = less overhead but less flexible access

### Auto-Calculated Chunks

Let the system calculate optimal chunk dimensions:

```dart
await array.toHDF5(
  'data.h5',
  dataset: '/data',
  options: WriteOptions(
    layout: StorageLayout.chunked,
    compression: CompressionType.gzip,
    // chunkDimensions omitted - will be auto-calculated
  ),
);
```

The auto-calculation algorithm:
- Targets chunks around 1MB in size
- Maintains proportions relative to dataset shape
- Ensures at least 1 element per dimension
- Optimizes for balanced access patterns

## Memory-Efficient Writing

For large datasets, the writer automatically uses chunked processing to avoid memory spikes:

```dart
// Large 3D array (400,000 elements)
final array = NDArray.generate([50, 100, 80], (indices) {
  return (indices[0] * 8000 + indices[1] * 80 + indices[2]).toDouble();
});

// Writes in chunks to manage memory
await array.toHDF5(
  'large_data.h5',
  dataset: '/data',
  options: WriteOptions(
    layout: StorageLayout.chunked,
    compression: CompressionType.gzip,
  ),
);
```

The writer processes data in 1MB chunks by default, allowing garbage collection between chunks.

## Multiple Datasets

Write multiple arrays to a single HDF5 file:

```dart
final temp = NDArray.generate([10, 10], (i) => (i[0] + i[1]) * 2.5);
final pressure = NDArray.generate([10, 10], (i) => (i[0] * 10 + i[1]) * 0.1);

await HDF5WriterUtils.writeMultiple(
  'data.h5',
  {
    '/temperature': temp,
    '/pressure': pressure,
  },
  defaultOptions: WriteOptions(
    layout: StorageLayout.chunked,
    compression: CompressionType.gzip,
  ),
);
```

You can also specify per-dataset options:

```dart
await HDF5WriterUtils.writeMultiple(
  'data.h5',
  {
    '/large_data': largeArray,
    '/small_data': smallArray,
  },
  perDatasetOptions: {
    '/large_data': WriteOptions(
      layout: StorageLayout.chunked,
      compression: CompressionType.gzip,
      compressionLevel: 9,
    ),
    '/small_data': WriteOptions(
      layout: StorageLayout.contiguous,
    ),
  },
);
```

## Datatype Mapping

The writer automatically maps Dart types to HDF5 native types:

| Dart Type | HDF5 Type | Size | Notes |
|-----------|-----------|------|-------|
| `int` | H5T_NATIVE_INT64 | 8 bytes | Signed 64-bit integer |
| `double` | H5T_NATIVE_DOUBLE | 8 bytes | IEEE 754 double precision |

The datatype is inferred from the first element of the array.

## Interoperability

### Python (h5py)

Files written by DartFrame can be read with h5py:

```python
import h5py
import numpy as np

with h5py.File('data.h5', 'r') as f:
    data = f['/data'][:]
    print(f"Shape: {data.shape}")
    print(f"Dtype: {data.dtype}")
    
    # Access attributes
    units = f['/data'].attrs['units']
```

### Python (pandas)

For 2D arrays, use pandas:

```python
import pandas as pd

df = pd.read_hdf('data.h5', '/data')
```

### MATLAB

Files are compatible with MATLAB's h5read:

```matlab
data = h5read('data.h5', '/data');
info = h5info('data.h5', '/data');

% Access attributes
units = h5readatt('data.h5', '/data', 'units');
```

### R

Use the rhdf5 package:

```r
library(rhdf5)

data <- h5read('data.h5', '/data')
attrs <- h5readAttributes('data.h5', '/data')
```

## C-Contiguous Layout

All data is written in C-contiguous (row-major) layout, which is the standard for:
- NumPy arrays in Python
- MATLAB arrays
- Most scientific computing tools

This ensures seamless interoperability without data reordering.

## Performance Tips

1. **Use chunked storage for large datasets** (> 100MB)
2. **Enable compression for redundant data** (can reduce size by 10-90%)
3. **Choose chunk sizes around 1MB** for optimal I/O
4. **Use LZF for speed, GZIP for size**
5. **Let auto-chunking handle complex cases**
6. **Write multiple small datasets together** to reduce file overhead

## Error Handling

The writer provides detailed error messages:

```dart
try {
  await array.toHDF5('data.h5', dataset: '/data');
} on HDF5WriteError catch (e) {
  print('HDF5 write failed: ${e.message}');
  print('Details: ${e.details}');
  print('Suggestions: ${e.recoverySuggestions}');
}
```

Common errors:
- **InvalidDatasetNameError**: Invalid dataset path
- **DataValidationError**: Invalid data or options
- **InvalidChunkDimensionsError**: Chunk dimensions don't match dataset
- **UnsupportedWriteDatatypeError**: Unsupported data type
- **FileWriteError**: File system error

## Complete Example

```dart
import 'dart:io';
import 'package:dartframe/dartframe.dart';

Future<void> main() async {
  // Create a 3D array
  final array = NDArray.generate([20, 30, 40], (indices) {
    return (indices[0] * 1200 + indices[1] * 40 + indices[2]).toDouble();
  });

  // Add metadata
  array.attrs['units'] = 'meters';
  array.attrs['description'] = 'Spatial measurements';
  array.attrs['timestamp'] = DateTime.now().toIso8601String();

  // Write with compression
  await array.toHDF5(
    'measurements.h5',
    dataset: '/spatial_data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [10, 10, 10],
      compression: CompressionType.gzip,
      compressionLevel: 6,
      attributes: {
        'processing': 'raw',
        'version': 1,
      },
    ),
  );

  print('File written successfully!');
  print('Size: ${File('measurements.h5').lengthSync()} bytes');
}
```

## See Also

- [HDF5 Format Specification](https://portal.hdfgroup.org/display/HDF5/HDF5)
- [h5py Documentation](https://docs.h5py.org/)
- [MATLAB HDF5 Functions](https://www.mathworks.com/help/matlab/hdf5-files.html)
- [NDArray Documentation](ndarray.md)
- [DataCube Documentation](datacube.md)
