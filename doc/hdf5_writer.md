# HDF5 Writing Guide

## Overview

DartFrame provides comprehensive support for writing HDF5 (Hierarchical Data Format version 5) files. The implementation is pure Dart with no FFI dependencies, making it fully cross-platform compatible. Written files are fully compatible with Python (h5py, pandas), MATLAB, R, and other standard HDF5 tools.

## Features

### Supported Capabilities

- ✅ Write NDArray, DataFrame, and DataCube objects
- ✅ Multiple datasets per file with group hierarchies
- ✅ All numeric datatypes (int8/16/32/64, uint8/16/32/64, float32/64)
- ✅ String datatypes (fixed-length and variable-length)
- ✅ Boolean and compound datatypes
- ✅ Chunked storage with automatic chunk size calculation
- ✅ Compression (gzip and lzf)
- ✅ Attributes (metadata) on datasets and groups
- ✅ Nested group structures
- ✅ DataFrame storage strategies (compound and column-wise)
- ✅ Full interoperability with h5py, pandas, MATLAB, and R

### Platform Support

- Windows
- macOS
- Linux
- Web
- Mobile (iOS, Android)

## Basic Usage

### Writing an NDArray

The simplest way to write an NDArray to HDF5:

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Create an NDArray
  final array = NDArray.generate([100, 200], (i) => i[0] + i[1]);
  
  // Write to HDF5 file
  await array.toHDF5('data.h5', dataset: '/measurements');
  
  print('File written successfully!');
}
```

### Writing a DataFrame

Write a DataFrame to HDF5:

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Create a DataFrame
  final df = DataFrame([
    [1, 'Alice', 25.5],
    [2, 'Bob', 30.0],
    [3, 'Charlie', 35.5],
  ], columns: ['id', 'name', 'age']);
  
  // Write to HDF5 file
  await df.toHDF5('users.h5', dataset: '/users');
  
  print('DataFrame written successfully!');
}
```

### Writing a DataCube

Write a 3D DataCube to HDF5:

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Create a DataCube
  final cube = DataCube.zeros(10, 20, 30);
  cube.attrs['units'] = 'celsius';
  cube.attrs['description'] = 'Temperature measurements';
  
  // Write to HDF5 file
  await cube.toHDF5('temperature.h5', dataset: '/temperature');
  
  print('DataCube written successfully!');
}
```

## Advanced Features

### Chunked Storage

Chunked storage divides datasets into fixed-size chunks for efficient partial I/O and compression:

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  final array = NDArray.generate([1000, 2000], (i) => i[0] * i[1]);
  
  // Write with chunked storage
  await array.toHDF5(
    'chunked_data.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [100, 100],
    ),
  );
}
```

**Benefits of chunked storage:**
- Efficient access to subsets of data
- Required for compression
- Better performance for large datasets
- Optimized for partial reads/writes

**Automatic chunk size calculation:**
```dart
// Let DartFrame calculate optimal chunk size
await array.toHDF5(
  'data.h5',
  options: WriteOptions(
    layout: StorageLayout.chunked,
    // chunkDimensions not specified - will be auto-calculated
  ),
);
```

### Compression

Reduce file size with compression (requires chunked storage):

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  final array = NDArray.generate([1000, 1000], (i) => i[0] + i[1]);
  
  // Write with gzip compression
  await array.toHDF5(
    'compressed.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [100, 100],
      compression: CompressionType.gzip,
      compressionLevel: 6,  // 1-9, where 9 is best compression
    ),
  );
  
  // Write with lzf compression (faster, less compression)
  await array.toHDF5(
    'compressed_lzf.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      compression: CompressionType.lzf,
    ),
  );
}
```

**Compression types:**
- `CompressionType.none` - No compression (default)
- `CompressionType.gzip` - GZIP/DEFLATE compression (best compatibility)
- `CompressionType.lzf` - LZF compression (faster, less compression)

**Compression levels (gzip only):**
- 1: Fastest compression, larger files
- 6: Balanced (default)
- 9: Best compression, slower

### Attributes (Metadata)

Attach metadata to datasets:

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  final array = NDArray.generate([100, 100], (i) => i[0] + i[1]);
  
  // Write with attributes
  await array.toHDF5(
    'data.h5',
    dataset: '/measurements',
    options: WriteOptions(
      attributes: {
        'units': 'meters',
        'description': 'Distance measurements',
        'created': DateTime.now().toIso8601String(),
        'version': 1.0,
        'calibrated': true,
      },
    ),
  );
}
```

**Supported attribute types:**
- Strings
- Numbers (int, double)
- Booleans
- Lists of the above types

### Multiple Datasets

Write multiple datasets to a single file with group hierarchies:

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Create multiple arrays
  final temperature = NDArray.generate([100, 100], (i) => 20.0 + i[0] * 0.1);
  final pressure = NDArray.generate([100, 100], (i) => 1013.0 + i[1] * 0.5);
  final humidity = NDArray.generate([100, 100], (i) => 50.0 + i[0] * 0.2);
  
  // Write all to one file with group structure
  await HDF5WriterUtils.writeMultiple('weather.h5', {
    '/measurements/temperature': temperature,
    '/measurements/pressure': pressure,
    '/measurements/humidity': humidity,
    '/calibration/offsets': NDArray.fromList([0.1, 0.2, 0.3]),
  });
  
  print('Multi-dataset file created!');
}
```

**With per-dataset options:**
```dart
await HDF5WriterUtils.writeMultiple(
  'data.h5',
  {
    '/large_data': largeArray,
    '/small_data': smallArray,
  },
  defaultOptions: WriteOptions(
    layout: StorageLayout.chunked,
    compression: CompressionType.gzip,
  ),
  perDatasetOptions: {
    '/large_data': WriteOptions(
      layout: StorageLayout.chunked,
      compression: CompressionType.gzip,
      compressionLevel: 9,  // Maximum compression for large data
    ),
    '/small_data': WriteOptions(
      layout: StorageLayout.contiguous,  // No chunking for small data
      compression: CompressionType.none,
    ),
  },
);
```

### DataFrame Storage Strategies

DataFrames can be stored using two different strategies:

#### Compound Datatype Strategy (Default)

Stores data as a compound datatype (struct-like, one record per row):

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  final df = DataFrame([
    [1, 'Alice', 25.5],
    [2, 'Bob', 30.0],
  ], columns: ['id', 'name', 'age']);
  
  // Write using compound datatype (default)
  await df.toHDF5(
    'users.h5',
    dataset: '/users',
    options: WriteOptions(
      dfStrategy: DataFrameStorageStrategy.compound,
    ),
  );
}
```

**Best for:**
- Mixed datatype columns (numeric + strings)
- Compatibility with pandas
- Row-oriented access patterns

#### Column-wise Strategy

Stores each column as a separate dataset in a group:

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  final df = DataFrame([
    [1, 2, 3],
    [4, 5, 6],
  ], columns: ['a', 'b', 'c']);
  
  // Write using column-wise storage
  await df.toHDF5(
    'data.h5',
    dataset: '/data',
    options: WriteOptions(
      dfStrategy: DataFrameStorageStrategy.columnwise,
    ),
  );
}
```

**Best for:**
- Large DataFrames with numeric columns
- Column-oriented access patterns
- When you need to read individual columns efficiently

**Note:** Column-wise strategy currently works best with numeric columns. For DataFrames with string columns, use the compound strategy.

## Interoperability

### Reading in Python (h5py)

```python
import h5py
import numpy as np

# Read a dataset
with h5py.File('data.h5', 'r') as f:
    data = f['/measurements'][:]
    print(f'Shape: {data.shape}')
    print(f'Dtype: {data.dtype}')
    
    # Read attributes
    units = f['/measurements'].attrs['units']
    print(f'Units: {units}')
    
    # Navigate groups
    for key in f.keys():
        print(f'Group: {key}')
```

### Reading in Python (pandas)

```python
import pandas as pd

# Read DataFrame
df = pd.read_hdf('users.h5', '/users')
print(df.head())
print(df.dtypes)
```

### Reading in MATLAB

```matlab
% Read a dataset
data = h5read('data.h5', '/measurements');
disp(size(data));

% Read attributes
units = h5readatt('data.h5', '/measurements', 'units');
disp(units);

% Get file info
info = h5info('data.h5');
disp(info);
```

### Reading in R

```r
library(rhdf5)

# Read a dataset
data <- h5read('data.h5', '/measurements')
print(dim(data))

# Read attributes
attrs <- h5readAttributes('data.h5', '/measurements')
print(attrs$units)

# List contents
h5ls('data.h5')
```

## WriteOptions Reference

The `WriteOptions` class provides comprehensive configuration for HDF5 write operations:

```dart
class WriteOptions {
  /// Storage layout for the dataset
  final StorageLayout layout;  // contiguous or chunked
  
  /// Chunk dimensions for chunked storage (null for auto-calculate)
  final List<int>? chunkDimensions;
  
  /// Compression algorithm to use
  final CompressionType compression;  // none, gzip, or lzf
  
  /// Compression level (1-9 for gzip, ignored for other types)
  final int compressionLevel;
  
  /// HDF5 format version (0, 1, or 2)
  final int formatVersion;
  
  /// Automatically create intermediate groups in dataset paths
  final bool createIntermediateGroups;
  
  /// Storage strategy for DataFrame objects
  final DataFrameStorageStrategy dfStrategy;  // compound or columnwise
  
  /// Attributes to attach to the dataset or group
  final Map<String, dynamic>? attributes;
  
  /// Whether to validate the file after writing
  final bool validateOnWrite;
}
```

### Default Values

```dart
const WriteOptions({
  this.layout = StorageLayout.contiguous,
  this.chunkDimensions,
  this.compression = CompressionType.none,
  this.compressionLevel = 6,
  this.formatVersion = 0,
  this.createIntermediateGroups = true,
  this.dfStrategy = DataFrameStorageStrategy.compound,
  this.attributes,
  this.validateOnWrite = false,
});
```

### Examples

**Minimal options (defaults):**
```dart
final options = WriteOptions();
```

**Chunked with compression:**
```dart
final options = WriteOptions(
  layout: StorageLayout.chunked,
  chunkDimensions: [100, 100],
  compression: CompressionType.gzip,
  compressionLevel: 6,
);
```

**With attributes:**
```dart
final options = WriteOptions(
  attributes: {
    'units': 'meters',
    'created': DateTime.now().toIso8601String(),
  },
);
```

**DataFrame column-wise:**
```dart
final options = WriteOptions(
  dfStrategy: DataFrameStorageStrategy.columnwise,
);
```

**With validation:**
```dart
final options = WriteOptions(
  validateOnWrite: true,  // Verify file integrity after writing
);
```

## Error Handling

### Common Errors

**Invalid chunk dimensions:**
```dart
try {
  await array.toHDF5(
    'data.h5',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [1000, 1000],  // Exceeds dataset dimensions
    ),
  );
} on InvalidChunkDimensionsError catch (e) {
  print('Error: ${e.message}');
  print('Chunk dims: ${e.chunkDimensions}');
  print('Dataset dims: ${e.datasetDimensions}');
}
```

**Compression without chunking:**
```dart
try {
  await array.toHDF5(
    'data.h5',
    options: WriteOptions(
      layout: StorageLayout.contiguous,  // Wrong!
      compression: CompressionType.gzip,
    ),
  );
} on DataValidationError catch (e) {
  print('Error: ${e.message}');
  // Error: Compression requires chunked storage layout
}
```

**File write errors:**
```dart
try {
  await array.toHDF5('/invalid/path/data.h5');
} on FileWriteError catch (e) {
  print('Error: ${e.message}');
  print('File: ${e.filePath}');
  if (e.originalError != null) {
    print('Cause: ${e.originalError}');
  }
}
```

### Best Practices

1. **Validate options before writing:**
```dart
final options = WriteOptions(
  layout: StorageLayout.chunked,
  compression: CompressionType.gzip,
);

try {
  options.validate(datasetDimensions: array.shape.toList());
  await array.toHDF5('data.h5', options: options);
} on DataValidationError catch (e) {
  print('Invalid options: ${e.message}');
}
```

2. **Use try-catch for robust error handling:**
```dart
try {
  await array.toHDF5('data.h5');
} on HDF5WriteError catch (e) {
  print('HDF5 write error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

3. **Check file paths:**
```dart
import 'dart:io';

Future<void> safeWrite(String path, NDArray array) async {
  // Check directory exists
  final dir = Directory(path).parent;
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  
  // Write file
  await array.toHDF5(path);
}
```

## Performance Considerations

### Memory Usage

- Memory usage is approximately 2x the dataset size during writing
- Chunked writing processes one chunk at a time for better memory efficiency
- For very large datasets, use chunked storage with appropriate chunk sizes

### Chunk Size Selection

**General guidelines:**
- Chunk size should be 10KB - 1MB for optimal performance
- Balance between read/write patterns and compression efficiency
- Smaller chunks: better for random access, more overhead
- Larger chunks: better for sequential access, less overhead

**Auto-calculation:**
```dart
// Let DartFrame choose optimal chunk size
await array.toHDF5(
  'data.h5',
  options: WriteOptions(
    layout: StorageLayout.chunked,
    // chunkDimensions omitted - auto-calculated
  ),
);
```

**Manual calculation:**
```dart
// For a 1000x1000 array, use 100x100 chunks
final chunkSize = [100, 100];
await array.toHDF5(
  'data.h5',
  options: WriteOptions(
    layout: StorageLayout.chunked,
    chunkDimensions: chunkSize,
  ),
);
```

### Compression Trade-offs

**GZIP:**
- Better compression ratios
- Slower compression/decompression
- Best compatibility (supported everywhere)
- Use for: archival, network transfer, maximum space savings

**LZF:**
- Faster compression/decompression
- Lower compression ratios
- Good compatibility
- Use for: temporary files, fast I/O, moderate space savings

**Compression levels (GZIP):**
- Level 1: ~2x faster, ~10% larger files
- Level 6: Balanced (default)
- Level 9: ~2x slower, ~5% smaller files

### Optimization Tips

1. **Use chunked storage for large datasets:**
```dart
if (array.size > 1000000) {
  // Use chunked storage for large data
  await array.toHDF5(
    'data.h5',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      compression: CompressionType.gzip,
    ),
  );
}
```

2. **Choose appropriate compression:**
```dart
// For network transfer or archival
final archiveOptions = WriteOptions(
  layout: StorageLayout.chunked,
  compression: CompressionType.gzip,
  compressionLevel: 9,
);

// For fast local I/O
final fastOptions = WriteOptions(
  layout: StorageLayout.chunked,
  compression: CompressionType.lzf,
);
```

3. **Batch multiple datasets:**
```dart
// More efficient than multiple separate writes
await HDF5WriterUtils.writeMultiple('data.h5', {
  '/data1': array1,
  '/data2': array2,
  '/data3': array3,
});
```

## Complete Examples

### Example 1: Scientific Data with Metadata

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Create measurement data
  final temperature = NDArray.generate(
    [100, 100],
    (i) => 20.0 + (i[0] * 0.1) + (i[1] * 0.05),
  );
  
  // Write with comprehensive metadata
  await temperature.toHDF5(
    'experiment.h5',
    dataset: '/measurements/temperature',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [10, 10],
      compression: CompressionType.gzip,
      compressionLevel: 6,
      attributes: {
        'units': 'celsius',
        'instrument': 'ThermoProbe 3000',
        'calibration_date': '2024-01-15',
        'sample_rate_hz': 100,
        'location': 'Lab A',
        'experimenter': 'Dr. Smith',
      },
    ),
  );
  
  print('Experiment data saved!');
}
```

### Example 2: Multi-Dataset File with Groups

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Create various datasets
  final rawData = NDArray.generate([1000, 500], (i) => i[0] + i[1]);
  final processed = NDArray.generate([1000, 500], (i) => (i[0] + i[1]) * 2.0);
  final calibration = NDArray.fromList([1.0, 1.05, 0.98, 1.02]);
  
  // Create a DataFrame for metadata
  final metadata = DataFrame([
    ['2024-01-15', 'Experiment 1', 'Success'],
    ['2024-01-16', 'Experiment 2', 'Success'],
  ], columns: ['date', 'name', 'status']);
  
  // Write everything to one file
  await HDF5WriterUtils.writeMultiple(
    'analysis.h5',
    {
      '/raw/data': rawData,
      '/processed/data': processed,
      '/calibration/factors': calibration,
      '/metadata/experiments': metadata,
    },
    defaultOptions: WriteOptions(
      layout: StorageLayout.chunked,
      compression: CompressionType.gzip,
    ),
  );
  
  print('Analysis file created with multiple datasets!');
}
```

### Example 3: DataFrame with Mixed Types

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Create a DataFrame with mixed types
  final users = DataFrame([
    [1, 'Alice', 25, true, 75000.0],
    [2, 'Bob', 30, false, 85000.0],
    [3, 'Charlie', 35, true, 95000.0],
    [4, 'Diana', 28, true, 80000.0],
  ], columns: ['id', 'name', 'age', 'active', 'salary']);
  
  // Write using compound datatype strategy
  await users.toHDF5(
    'employees.h5',
    dataset: '/employees',
    options: WriteOptions(
      dfStrategy: DataFrameStorageStrategy.compound,
      attributes: {
        'created': DateTime.now().toIso8601String(),
        'department': 'Engineering',
        'version': 1,
      },
    ),
  );
  
  print('Employee data saved!');
  print('Read in Python with: pd.read_hdf("employees.h5", "/employees")');
}
```

### Example 4: Large Dataset with Optimal Settings

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Create a large dataset
  final largeData = NDArray.generate(
    [10000, 5000],
    (i) => i[0] * 0.001 + i[1] * 0.0001,
  );
  
  print('Dataset size: ${largeData.size} elements');
  print('Memory: ~${(largeData.size * 8) / (1024 * 1024)} MB');
  
  // Write with optimal settings for large data
  final stopwatch = Stopwatch()..start();
  
  await largeData.toHDF5(
    'large_data.h5',
    dataset: '/data',
    options: WriteOptions(
      layout: StorageLayout.chunked,
      chunkDimensions: [1000, 500],  // ~4MB chunks
      compression: CompressionType.gzip,
      compressionLevel: 6,
      attributes: {
        'description': 'Large dataset example',
        'shape': '${largeData.shape}',
      },
    ),
  );
  
  stopwatch.stop();
  print('Write completed in ${stopwatch.elapsedMilliseconds}ms');
}
```

## API Reference

### NDArray.toHDF5()

```dart
Future<void> toHDF5(
  String path, {
  String dataset = '/data',
  Map<String, dynamic>? attributes,
  List<int>? chunks,
  String? compression,
  int compressionLevel = 6,
  WriteOptions? options,
})
```

Write NDArray to HDF5 file.

**Parameters:**
- `path`: Path to output HDF5 file
- `dataset`: Dataset path within file (default: '/data')
- `attributes`: Metadata to attach (legacy parameter)
- `chunks`: Chunk dimensions (legacy parameter)
- `compression`: Compression type (legacy parameter)
- `compressionLevel`: Compression level 1-9 (legacy parameter)
- `options`: WriteOptions object (recommended)

**Throws:**
- `HDF5WriteError` - HDF5-specific errors
- `FileWriteError` - File I/O errors
- `DataValidationError` - Invalid options
- `InvalidChunkDimensionsError` - Invalid chunk dimensions

### DataFrame.toHDF5()

```dart
Future<void> toHDF5(
  String path, {
  String dataset = '/data',
  WriteOptions? options,
})
```

Write DataFrame to HDF5 file.

**Parameters:**
- `path`: Path to output HDF5 file
- `dataset`: Dataset path within file (default: '/data')
- `options`: WriteOptions object

**Throws:**
- `HDF5WriteError` - HDF5-specific errors
- `FileWriteError` - File I/O errors

### DataCube.toHDF5()

```dart
Future<void> toHDF5(
  String path, {
  String dataset = '/data',
  Map<String, dynamic>? attributes,
  List<int>? chunks,
  String? compression,
  int compressionLevel = 6,
  WriteOptions? options,
})
```

Write DataCube to HDF5 file.

**Parameters:** Same as NDArray.toHDF5()

### HDF5WriterUtils.writeMultiple()

```dart
static Future<void> writeMultiple(
  String filePath,
  Map<String, dynamic> datasets, {
  WriteOptions? defaultOptions,
  Map<String, WriteOptions>? perDatasetOptions,
})
```

Write multiple datasets to a single HDF5 file.

**Parameters:**
- `filePath`: Path to output HDF5 file
- `datasets`: Map of dataset paths to data objects (NDArray, DataFrame, DataCube)
- `defaultOptions`: Default options for all datasets
- `perDatasetOptions`: Per-dataset option overrides

**Throws:**
- `ArgumentError` - Invalid inputs
- `HDF5WriteError` - HDF5-specific errors
- `FileWriteError` - File I/O errors

## Troubleshooting

### Problem: "Compression requires chunked storage layout"

**Cause:** Trying to use compression with contiguous storage

**Solution:**
```dart
// Wrong
await array.toHDF5('data.h5', options: WriteOptions(
  layout: StorageLayout.contiguous,
  compression: CompressionType.gzip,  // Error!
));

// Correct
await array.toHDF5('data.h5', options: WriteOptions(
  layout: StorageLayout.chunked,
  compression: CompressionType.gzip,
));
```

### Problem: "Chunk dimensions exceed dataset dimensions"

**Cause:** Chunk size larger than dataset

**Solution:**
```dart
final array = NDArray.generate([100, 100], (i) => i[0] + i[1]);

// Wrong
await array.toHDF5('data.h5', options: WriteOptions(
  layout: StorageLayout.chunked,
  chunkDimensions: [200, 200],  // Too large!
));

// Correct
await array.toHDF5('data.h5', options: WriteOptions(
  layout: StorageLayout.chunked,
  chunkDimensions: [50, 50],  // Within bounds
));
```

### Problem: File not readable in Python

**Cause:** Usually a bug in the writer (please report!)

**Debugging:**
```dart
// Enable validation
await array.toHDF5('data.h5', options: WriteOptions(
  validateOnWrite: true,
));

// Check with h5dump
// $ h5dump -H data.h5
```

### Problem: Out of memory

**Cause:** Dataset too large for available memory

**Solution:**
```dart
// Use chunked storage for better memory efficiency
await largeArray.toHDF5('data.h5', options: WriteOptions(
  layout: StorageLayout.chunked,
  chunkDimensions: [100, 100],  // Process in smaller chunks
));
```

## Limitations

### Current Limitations

**Datatypes:**
- ✅ All numeric types supported
- ✅ Fixed-length strings supported
- ✅ Variable-length strings supported
- ✅ Boolean and compound types supported
- ✅ Time datatypes not yet supported
- ❌ Complex numbers not yet supported

**Features:**
- ✅ Chunked and contiguous storage
- ✅ GZIP and LZF compression
- ✅ Multiple datasets per file
- ✅ Nested group hierarchies
- ❌ Appending to existing files not yet supported
- ❌ Modifying existing datasets not yet supported
- ❌ Virtual datasets not yet supported

**DataFrame:**
- ✅ Compound datatype strategy fully supported
- ⚠️ Column-wise strategy: limited string support

### Workarounds

**For complex numbers:**
```dart
// Store as compound type with real/imaginary fields
final complexData = DataFrame([
  [1.0, 2.0],  // 1+2i
  [3.0, 4.0],  // 3+4i
], columns: ['real', 'imag']);

await complexData.toHDF5('complex.h5');
```

**For appending:**
```dart
// Currently not supported - use Python for appending
// Or write to separate files and merge with h5py
```

## Additional Resources

- [HDF5 Format Specification](https://www.hdfgroup.org/solutions/hdf5/)
- [Python h5py Documentation](https://docs.h5py.org/)
- [MATLAB HDF5 Documentation](https://www.mathworks.com/help/matlab/hdf5-files.html)
- [DartFrame Examples](../example/)
- [HDF5 Reading Guide](hdf5.md)

## Quick Reference

### Common Patterns

**Basic write:**
```dart
await array.toHDF5('data.h5');
```

**With compression:**
```dart
await array.toHDF5('data.h5', options: WriteOptions(
  layout: StorageLayout.chunked,
  compression: CompressionType.gzip,
));
```

**With attributes:**
```dart
await array.toHDF5('data.h5', options: WriteOptions(
  attributes: {'units': 'meters', 'created': '2024-01-15'},
));
```

**Multiple datasets:**
```dart
await HDF5WriterUtils.writeMultiple('data.h5', {
  '/data1': array1,
  '/data2': array2,
});
```

**DataFrame:**
```dart
await df.toHDF5('data.h5', dataset: '/table');
```

**With validation:**
```dart
await array.toHDF5('data.h5', options: WriteOptions(
  validateOnWrite: true,
));
```
