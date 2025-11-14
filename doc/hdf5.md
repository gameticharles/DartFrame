# HDF5 Reading Guide

## Overview

DartFrame provides comprehensive support for reading HDF5 (Hierarchical Data Format version 5) files. The implementation is pure Dart with no FFI dependencies, making it fully cross-platform compatible.

## Features

### Supported Capabilities

- ✅ Read datasets and convert to DataFrames
- ✅ Navigate group hierarchies (old-style and new-style)
- ✅ Read attributes (metadata)
- ✅ Compressed datasets (gzip, lzf)
- ✅ Chunked storage with B-tree indexing
- ✅ Multiple data types (integers, floats, strings, compounds, arrays, enums, references)
- ✅ **Variable-length data** (vlen strings, vlen arrays) with global heap support
- ✅ **Boolean arrays** with dedicated `readAsBoolean()` method
- ✅ **Opaque data** with tag information
- ✅ **Bitfield data** for packed bits
- ✅ MATLAB v7.3 MAT-file compatibility
- ✅ Soft links, hard links, and external links
- ✅ HDF5 versions 0, 1, 2, 3
- ✅ Files from Python h5py, MATLAB, R, and other tools

### Platform Support

- Windows
- macOS
- Linux
- Web
- Mobile (iOS, Android)

## Basic Usage

### Reading a Dataset

The simplest way to read an HDF5 dataset:

```dart
import 'package:dartframe/dartframe.dart';

void main() async {
  // Read a dataset and convert to DataFrame
  final df = await FileReader.readHDF5(
    'data.h5',
    dataset: '/mydata',
  );
  
  print('Shape: ${df.shape}');
  print(df.head());
}
```


### Parameters

- `path` (String): Path to the HDF5 file
- `dataset` (String, optional): Path to the dataset within the file (default: '/data')
- `options` (Map<String, dynamic>, optional): Additional options
  - `'debug'` (bool): Enable verbose logging for troubleshooting (default: false)

## File Inspection

### Inspecting File Structure

Get information about an HDF5 file without reading all data:

```dart
// Get file metadata and structure
final info = await HDF5Reader.inspect('data.h5');

print('HDF5 Version: ${info['version']}');
print('Root children: ${info['rootChildren']}');
print('Available datasets: ${info['datasets']}');
```

### Listing Datasets

List all datasets in a file:

```dart
final datasets = await HDF5Reader.listDatasets('data.h5');

print('Available datasets:');
for (final dataset in datasets) {
  print('  - $dataset');
}
```

## Reading Attributes

Attributes are metadata attached to datasets or groups. They typically contain information like units, descriptions, creation dates, etc.

### Basic Attribute Reading

```dart
// Read all attributes from a dataset
final attrs = await HDF5Reader.readAttributes(
  'data.h5',
  dataset: '/mydata',
);

// Access specific attributes
print('Units: ${attrs['units']}');
print('Description: ${attrs['description']}');
print('Creation date: ${attrs['creation_date']}');
```

### Common Attribute Patterns

```dart
// Check if an attribute exists
if (attrs.containsKey('units')) {
  print('Data is measured in ${attrs['units']}');
}

// Handle missing attributes gracefully
final units = attrs['units'] ?? 'unknown';
final description = attrs['description'] ?? 'No description available';
```


## Common Workflows

### Workflow 1: Exploring an Unknown HDF5 File

When working with a new HDF5 file, follow this workflow:

```dart
// Step 1: Inspect the file structure
final info = await HDF5Reader.inspect('unknown_file.h5');
print('HDF5 Version: ${info['version']}');

// Step 2: List all available datasets
final datasets = await HDF5Reader.listDatasets('unknown_file.h5');
print('Available datasets: $datasets');

// Step 3: Read a specific dataset
if (datasets.isNotEmpty) {
  final firstDataset = '/${datasets.first}';
  final df = await FileReader.readHDF5(
    'unknown_file.h5',
    dataset: firstDataset,
  );
  print('Shape: ${df.shape}');
  print(df.head());
}

// Step 4: Check for metadata
final attrs = await HDF5Reader.readAttributes(
  'unknown_file.h5',
  dataset: firstDataset,
);
if (attrs.isNotEmpty) {
  print('Metadata: $attrs');
}
```

### Workflow 2: Working with Large Files

For large HDF5 files, use this approach:

```dart
// 1. First, inspect without reading data
final datasets = await HDF5Reader.listDatasets('large_file.h5');

// 2. Read only the datasets you need
for (final datasetName in datasets) {
  if (datasetName.contains('summary')) {
    final df = await FileReader.readHDF5(
      'large_file.h5',
      dataset: '/$datasetName',
    );
    // Process only summary data
    print('$datasetName: ${df.shape}');
  }
}

// 3. For very large datasets, consider reading in chunks
// (if the dataset is organized with chunked storage)
```

### Workflow 3: Handling Errors Gracefully

Robust error handling for production code:

```dart
Future<DataFrame?> safeReadHDF5(String path, String dataset) async {
  try {
    // Check file exists first
    if (!File(path).existsSync()) {
      print('File not found: $path');
      return null;
    }

    // Try to read the dataset
    return await FileReader.readHDF5(path, dataset: dataset);
  } on Hdf5Error catch (e) {
    print('HDF5 error: ${e.message}');
    
    // Try to list available datasets as fallback
    try {
      final datasets = await HDF5Reader.listDatasets(path);
      print('Available datasets: $datasets');
    } catch (_) {}
    
    return null;
  } catch (e) {
    print('Unexpected error: $e');
    return null;
  }
}
```

## Advanced Features

### Compressed Datasets

DartFrame automatically handles decompression:

```dart
// Read gzip-compressed dataset
final df = await FileReader.readHDF5(
  'compressed_data.h5',
  dataset: '/gzip_data',
);
// Decompression happens automatically

// Read lzf-compressed dataset
final dfLzf = await FileReader.readHDF5(
  'compressed_data.h5',
  dataset: '/lzf_data',
);
```

Supported compression formats:
- Gzip (deflate)
- LZF
- Shuffle filter (for numeric data)

### Chunked Datasets

Chunked datasets are automatically assembled:

```dart
// Read chunked dataset
final df = await FileReader.readHDF5(
  'chunked_data.h5',
  dataset: '/chunked_array',
);
// Chunks are read and assembled automatically
```

Benefits of chunked storage:
- Efficient access to subsets of data
- Better compression ratios
- Optimized for large datasets

### MATLAB File Compatibility

Read MATLAB v7.3 MAT-files (which are HDF5-based):

```dart
// Read a MATLAB variable
final df = await FileReader.readHDF5(
  'data.mat',
  dataset: '/myVariable',
);

// List MATLAB variables
final variables = await HDF5Reader.listDatasets('data.mat');
print('MATLAB variables: $variables');
```

MATLAB-specific features:
- Automatic detection of 512-byte offset
- Handles MATLAB metadata
- Variables stored as datasets

## Data Types

### Supported Data Types

DartFrame supports a wide range of HDF5 data types:

**Numeric Types:**
- Integers: int8, int16, int32, int64
- Unsigned integers: uint8, uint16, uint32, uint64
- Floating-point: float32, float64

**String Types:**
- Fixed-length strings (ASCII and UTF-8)
- **✨ Variable-length strings** (with global heap support)

**Time Data Support:**
- **✨ Time datatype (class 2)**: Full support for HDF5 time datatypes (rare)
- **✨ Integer timestamps**: Helper method `readAsDateTime()` to convert int32/int64 timestamps
  - Auto-detects seconds vs milliseconds
  - Supports forced unit specification

**Complex Types:**
- Compound types (structs with multiple fields)
- Array types (multi-dimensional arrays)
- Enum types (enumerated values)
- **✨ Variable-length arrays** (vlen numeric arrays)

**Special Types:**
- **✨ Boolean arrays** (uint8 with boolean conversion)
- **✨ Opaque data** (binary blobs with tags)
- **✨ Bitfield data** (packed bits)
- Reference types (object references)

### Variable-Length Data

DartFrame now fully supports variable-length (vlen) data through global heap implementation:

#### Variable-Length Strings

```dart
// Read vlen string dataset
final df = await FileReader.readHDF5(
  'vlen_data.h5',
  dataset: '/vlen_strings',
);

// Strings of different lengths are handled automatically
print(df.head());
// Output: ['Hello', 'World', 'Variable', 'Length', 'Strings!']
```

#### Variable-Length Arrays

```dart
// Read vlen integer arrays
final file = await Hdf5File.open('vlen_data.h5');
final data = await file.readDataset('/vlen_ints');

// Each element can be an array of different length
print(data);
// Output: [[1, 2, 3], [4, 5], [6, 7, 8, 9]]

await file.close();
```

#### How It Works

Variable-length data is stored using HDF5's global heap:
- Each vlen element contains a reference (16 bytes) to data in the global heap
- The global heap stores the actual variable-length data
- DartFrame automatically resolves these references and fetches the data
- Heap collections are cached for performance

### Boolean Arrays

Convert uint8 datasets to boolean arrays:

```dart
final file = await Hdf5File.open('data.h5');
final dataset = await file.dataset('/flags');

// Check if dataset can be read as boolean
if (dataset.datatype.isBoolean) {
  final boolArray = await dataset.readAsBoolean(reader);
  print(boolArray); // [true, false, true, true, false]
}

await file.close();
```

### Opaque Data

Opaque datatypes now return structured data with tag information:

```dart
final file = await Hdf5File.open('data.h5');
final data = await file.readDataset('/binary_data');

for (final item in data) {
  if (item is OpaqueData) {
    print('Tag: ${item.tag}');
    print('Size: ${item.data.length} bytes');
    print('Hex: ${item.toHexString()}');
  }
}

await file.close();
```

### Bitfield Data

Bitfield datatypes for packed bits:

```dart
final file = await Hdf5File.open('data.h5');
final data = await file.readDataset('/bitflags');

for (final bitfield in data) {
  if (bitfield is Uint8List) {
    // Extract individual bits
    for (int i = 0; i < bitfield.length; i++) {
      final byte = bitfield[i];
      for (int bit = 0; bit < 8; bit++) {
        final flag = (byte >> bit) & 1;
        print('Bit ${i * 8 + bit}: $flag');
      }
    }
  }
}

await file.close();
```

### Time Data (NEW)

Convert integer timestamps to DateTime objects:

```dart
import 'dart:io';

final file = await Hdf5File.open('data.h5');
final dataset = await file.dataset('/timestamps');
final raf = await File('data.h5').open();
final reader = ByteReader(raf);

// Auto-detect seconds vs milliseconds
final dates = await dataset.readAsDateTime(reader);
print('First date: ${dates[0].toUtc()}');
// Output: 2020-01-01 00:00:00.000Z

// Force seconds interpretation
final datesSeconds = await dataset.readAsDateTime(
  reader,
  unit: 'seconds',
);

// Force milliseconds interpretation
final datesMs = await dataset.readAsDateTime(
  reader,
  unit: 'milliseconds',
);

await raf.close();
await file.close();
```

**How it works:**
- Reads integer datasets (int32 or int64)
- Converts Unix timestamps to DateTime objects
- Auto-detects unit: values > 1e10 treated as milliseconds, otherwise seconds
- Can force specific unit with `unit` parameter

**Note:** HDF5 time datatype (class 2) is extremely rare. Most applications store timestamps as int64 (class 0). DartFrame supports both:
- If you encounter actual HDF5 time datatype, it's automatically converted to DateTime
- For integer timestamps (the common case), use `readAsDateTime()` helper method


### DataFrame Conversion

**1D Arrays:**
Converted to a DataFrame with a single column:
```dart
// 1D array [1, 2, 3, 4, 5]
// Becomes DataFrame with column 'data'

// Example: Reading 1D chunked dataset
final df1d = await FileReader.readHDF5(
  'data.h5',
  dataset: '/chunked_1d',
);
print('Shape: ${df1d.shape}'); // e.g., (100, 1)
print('First values: ${df1d[0].data.take(5).toList()}');
print('Last values: ${df1d[0].data.skip(df1d.shape[0] - 5).toList()}');
```

**2D Arrays:**
Converted to a DataFrame with multiple columns:
```dart
// 2D array [[1, 2], [3, 4], [5, 6]]
// Becomes DataFrame with columns 'col_0', 'col_1'

// Example: Reading 2D chunked dataset
final df2d = await FileReader.readHDF5(
  'data.h5',
  dataset: '/chunked_2d',
);
print('Shape: ${df2d.shape}'); // e.g., (10, 6)
print('Columns: ${df2d.columns}'); // ['col_0', 'col_1', ..., 'col_5']
```

**Compound Types:**
Each field becomes a column:
```dart
// Compound with fields: name (string), age (int), score (float)
// Becomes DataFrame with columns: 'name', 'age', 'score'
```

## Group Navigation

### Hierarchical Structure

HDF5 files organize data in a hierarchical structure similar to a file system:

```
/                    (root group)
├── data/           (group)
│   ├── dataset1    (dataset)
│   └── dataset2    (dataset)
├── metadata/       (group)
│   └── info        (dataset)
└── results         (dataset)
```

### Accessing Nested Datasets

Use forward slashes to specify paths:

```dart
// Read dataset in root
final df1 = await FileReader.readHDF5('file.h5', dataset: '/results');

// Read dataset in nested group
final df2 = await FileReader.readHDF5('file.h5', dataset: '/data/dataset1');

// Read deeply nested dataset
final df3 = await FileReader.readHDF5('file.h5', dataset: '/group1/group2/data');
```

### Programmatic Structure Access

For advanced use cases, you can access the file structure programmatically:

```dart
import 'package:dartframe/dartframe.dart';

// Open file directly for low-level access
final file = await Hdf5File.open('data.h5');

// Get structure as a map
final structure = await file.getStructure();

// Access dataset information
final datasetInfo = structure['/mydata'];
print('Shape: ${datasetInfo['shape']}');
print('Dtype: ${datasetInfo['dtype']}');
print('Attributes: ${datasetInfo['attributes']}');

// Close when done
await file.close();
```

See `example/get_structure.dart` for a complete example.

## Advanced API Usage

### Working with Datatypes Directly

For advanced use cases, you can work directly with HDF5 datatypes. This is useful when:
- Creating custom datatypes
- Understanding compound type structures
- Working with the internal HDF5 API
- Building HDF5 tools or utilities

#### Predefined Atomic Types

DartFrame provides predefined datatypes for common types:

```dart
import 'package:dartframe/dartframe.dart';

// Access predefined types
print('int32: ${Hdf5Datatype.int32.typeName}');
print('float64: ${Hdf5Datatype.float64.typeName}');
print('uint8: ${Hdf5Datatype.uint8.typeName}');

// Check type properties
print('int32.isAtomic: ${Hdf5Datatype.int32.isAtomic}');
print('int32.dataclass: ${Hdf5Datatype.int32.dataclass}');
```

Available predefined types:
- Integers: `int8`, `int16`, `int32`, `int64`
- Unsigned: `uint8`, `uint16`, `uint32`, `uint64`
- Floats: `float32`, `float64`

#### Creating Custom Datatypes

Create custom datatypes for specific needs:

```dart
// Custom integer type (int16)
final customInt = Hdf5Datatype<int>(
  dataclass: Hdf5DatatypeClass.integer,
  size: 2,
);
print('Custom int16: ${customInt.typeName}');

// Custom string type with metadata
final stringType = Hdf5Datatype<String>(
  dataclass: Hdf5DatatypeClass.string,
  size: 50,
  stringInfo: StringInfo(
    paddingType: StringPaddingType.nullTerminate,
    characterSet: CharacterSet.utf8,
    isVariableLength: false,
  ),
);
print('String type: ${stringType.typeName}');
```

#### Working with Compound Types

Compound types represent structured data (like C structs):

```dart
// Define a compound type with multiple fields
final compoundType = Hdf5Datatype<Map<String, dynamic>>(
  dataclass: Hdf5DatatypeClass.compound,
  size: 16,
  compoundInfo: CompoundInfo(
    fields: [
      CompoundField(
        name: 'id',
        offset: 0,
        datatype: Hdf5Datatype.int32,
      ),
      CompoundField(
        name: 'value',
        offset: 8,
        datatype: Hdf5Datatype.float64,
      ),
    ],
  ),
);

// Access field information
for (final field in compoundType.compoundInfo!.fields) {
  print('${field.name} @ offset ${field.offset}: ${field.datatype.typeName}');
}
```

#### Datatype Classes

HDF5 organizes types into classes:

```dart
// Available datatype classes
for (final cls in Hdf5DatatypeClass.values) {
  print('${cls.name} (id=${cls.id})');
}

// Common classes:
// - integer: Fixed-point integers
// - floatingPoint: Floating-point numbers
// - string: Character strings
// - compound: Structured types
// - array: Array types
// - enumerated: Enumeration types
```

#### Type Checking

Check datatype properties:

```dart
final dtype = Hdf5Datatype.int32;

// Check if atomic (single value) or composite (structured)
print('Is atomic: ${dtype.isAtomic}');
print('Is composite: ${dtype.isComposite}');

// Get datatype class
print('Class: ${dtype.dataclass}');

// Get size in bytes
print('Size: ${dtype.size} bytes');
```

### When to Use the Advanced API

**Use the high-level API** (`FileReader.readHDF5()`) for:
- Reading datasets into DataFrames
- Standard data analysis workflows
- Most common use cases

**Use the advanced API** (`Hdf5File`, `Hdf5Datatype`) for:
- Building HDF5 tools or utilities
- Custom datatype handling
- Low-level file inspection
- Understanding file structure in detail
- Performance-critical applications

See `example/datatype_api_demo.dart` for a complete demonstration of the datatype API.

## Error Handling

### Common Errors

**Invalid HDF5 File:**
```dart
try {
  final df = await FileReader.readHDF5('not_hdf5.txt');
} catch (e) {
  // Throws: Invalid HDF5 signature
  print('Error: $e');
}
```

**Dataset Not Found:**
```dart
try {
  final df = await FileReader.readHDF5('data.h5', dataset: '/missing');
} catch (e) {
  // Throws: Dataset not found: /missing
  print('Error: $e');
}
```

**Unsupported Feature:**
```dart
try {
  final df = await FileReader.readHDF5('data.h5', dataset: '/complex_data');
} catch (e) {
  // Throws: UnsupportedFeatureError with details
  print('Error: $e');
}
```


### Best Practices

1. **Check file existence first:**
```dart
if (File('data.h5').existsSync()) {
  final df = await FileReader.readHDF5('data.h5');
}
```

2. **List datasets before reading:**
```dart
final datasets = await HDF5Reader.listDatasets('data.h5');
if (datasets.contains('mydata')) {
  final df = await FileReader.readHDF5('data.h5', dataset: '/mydata');
}
```

3. **Use try-catch for robust error handling:**
```dart
try {
  final df = await FileReader.readHDF5('data.h5', dataset: '/data');
  // Process data
} on Hdf5Error catch (e) {
  print('HDF5 error: $e');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Debug Mode

### Enabling Debug Mode

For troubleshooting, enable debug mode to see detailed logging:

```dart
// Method 1: Enable globally
HDF5Reader.setDebugMode(true);
final df = await FileReader.readHDF5('data.h5', dataset: '/data');
HDF5Reader.setDebugMode(false);

// Method 2: Enable for single read
final df = await FileReader.readHDF5(
  'data.h5',
  dataset: '/data',
  options: {'debug': true},
);
```

### Debug Output

Debug mode provides information about:
- Superblock parsing (file format version, offsets)
- Object header messages (datatype, dataspace, layout)
- B-tree traversal (for chunked datasets)
- Chunk reading operations
- Decompression steps
- Error details and stack traces

### When to Use Debug Mode

- File won't open (check signature and version)
- Dataset not found (see group structure)
- Unexpected data values (check datatype parsing)
- Performance issues (see chunk reading patterns)
- Unsupported features (identify what's not supported)

### Practical Debug Example

```dart
// Enable debug for a problematic file
try {
  final df = await FileReader.readHDF5(
    'problematic.h5',
    dataset: '/data',
    options: {'debug': true},
  );
  print('Success! Shape: ${df.shape}');
} catch (e) {
  print('Error even with debug: $e');
  // Debug output will show where the parsing failed
}
```

## Performance Considerations

### Memory Usage

- Memory usage is approximately 2x the dataset size
- Chunked reading helps with large datasets
- Consider reading subsets for very large files

### Metadata Caching

DartFrame automatically caches metadata to improve performance when accessing the same objects multiple times:

```dart
import 'package:dartframe/dartframe.dart';

final file = await Hdf5File.open('data.h5');

// First access - reads from file
final group1 = await file.group('/mygroup');

// Second access - uses cache (faster)
final group2 = await file.group('/mygroup');

// Check cache statistics
print(file.cacheStats);
// Output: Cache hits: 1, misses: 1, size: 1

// Clear cache if needed
file.clearCache();

await file.close();
```

**What gets cached:**
- Group metadata and structure
- Dataset headers (not data)
- Datatype information
- Object addresses

**Benefits:**
- Faster repeated access to same objects
- Reduced file I/O operations
- Better performance for complex hierarchies

### Dataset Streaming and Slicing

For large datasets, use streaming and slicing to avoid loading everything into memory:

#### Reading Dataset Slices

Read only a portion of a dataset:

```dart
import 'package:dartframe/dartframe.dart';

final file = await Hdf5File.open('large_data.h5');

// Read first 100 rows of a 2D dataset
final slice = await file.readDatasetSlice(
  '/large_dataset',
  start: [0, 0],        // Start at row 0, column 0
  end: [100, null],     // Read 100 rows, all columns (null = to end)
);

print('Slice size: ${slice.length}');

await file.close();
```

**Slice parameters:**
- `start`: Starting indices for each dimension (0-based)
- `end`: Ending indices (exclusive), use `null` for "to end"
- Returns: Flattened list of values

**Use cases:**
- Preview large datasets
- Process data in sections
- Extract specific regions of interest

#### Chunked Reading (Streaming)

Process large datasets in chunks without loading all data:

```dart
import 'package:dartframe/dartframe.dart';

final file = await Hdf5File.open('large_data.h5');

// Process dataset in chunks of 1000 elements
await for (final chunk in file.readDatasetChunked('/large_dataset', chunkSize: 1000)) {
  // Process each chunk
  print('Processing chunk of ${chunk.length} elements');
  
  // Example: Calculate statistics on chunk
  final sum = chunk.fold<num>(0, (a, b) => a + (b as num));
  print('Chunk sum: $sum');
}

await file.close();
```

**Benefits:**
- Constant memory usage regardless of dataset size
- Process datasets larger than available RAM
- Real-time processing as data is read

**Use cases:**
- Computing statistics on huge datasets
- Data transformation pipelines
- Streaming data to other systems

#### Complete Streaming Example

```dart
import 'package:dartframe/dartframe.dart';

Future<void> processLargeDataset(String path, String dataset) async {
  final file = await Hdf5File.open(path);
  
  try {
    // Get dataset info first
    final structure = await file.getStructure();
    final info = structure[dataset];
    final shape = info['shape'] as List;
    final totalElements = shape.fold<int>(1, (a, b) => a * (b as int));
    
    print('Dataset: $dataset');
    print('Shape: $shape');
    print('Total elements: $totalElements');
    
    // Process in chunks if large
    if (totalElements > 10000) {
      print('Processing in chunks...');
      
      double sum = 0;
      int count = 0;
      
      await for (final chunk in file.readDatasetChunked(dataset, chunkSize: 1000)) {
        for (final value in chunk) {
          sum += (value as num).toDouble();
          count++;
        }
      }
      
      print('Average: ${sum / count}');
    } else {
      // Small dataset - read all at once
      final data = await file.readDataset(dataset);
      print('Read ${data.length} elements');
    }
  } finally {
    await file.close();
  }
}
```

### Optimization Tips

1. **Use chunked datasets for large data:**
   - Better memory efficiency
   - Faster access to subsets
   - Enable compression for better performance

2. **Enable compression for storage:**
   - Reduces file size
   - Minimal decompression overhead
   - Gzip and LZF supported

3. **Use metadata caching:**
   - Automatically enabled
   - Speeds up repeated access
   - Check `cacheStats` to monitor effectiveness

4. **Stream large datasets:**
   - Use `readDatasetChunked()` for huge files
   - Use `readDatasetSlice()` for specific regions
   - Avoid loading entire dataset if not needed

5. **Read only needed datasets:**
   - Use `inspect()` to understand structure first
   - List datasets before reading
   - Don't read entire file if you only need specific data

6. **Reuse file handles:**
   ```dart
   // Good: Reuse file handle
   final file = await Hdf5File.open('data.h5');
   final data1 = await file.readDataset('/dataset1');
   final data2 = await file.readDataset('/dataset2');
   await file.close();
   
   // Less efficient: Multiple opens
   final df1 = await FileReader.readHDF5('data.h5', dataset: '/dataset1');
   final df2 = await FileReader.readHDF5('data.h5', dataset: '/dataset2');
   ```

See `example/test_caching.dart` for a complete demonstration of caching and streaming features.


## Limitations

### Current Limitations

#### Dimensionality
- ✅ 1D and 2D datasets are automatically converted to DataFrames
- ✅ 3D+ datasets are flattened to 1D with shape information preserved
  - Shape stored in `_shape` column (e.g., "2x3x4")
  - Dimension count stored in `_ndim` column
  - Use this information to reshape data as needed

#### File Operations
- ❌ Writing HDF5 files is not yet supported (read-only access)
- ❌ Modifying existing files not supported
- ❌ Creating new files not supported

#### Datatypes

**Fully Supported:**
- ✅ Integers: int8, int16, int32, int64
- ✅ Unsigned integers: uint8, uint16, uint32, uint64
- ✅ Floating-point: float32, float64
- ✅ Strings: fixed-length (ASCII, UTF-8)
- ✅ **✨ Variable-length strings**: Full support with global heap
- ✅ **✨ Variable-length arrays**: Full support for vlen numeric arrays
- ✅ Compound types: structs with multiple fields
- ✅ Array types: multi-dimensional arrays
- ✅ **✨ Opaque types**: Returns structured `OpaqueData` with tag and hex string support
- ✅ Enum types: enumerated values
- ✅ **✨ Boolean arrays**: Dedicated `readAsBoolean()` method for uint8 → boolean conversion
- ✅ **✨ Bitfield types**: Returns Uint8List for bit manipulation
- ✅ Reference types: Object references fully supported
- ✅ **Time Data Support:**
- ✅ **✨ Time datatype (class 2)**: Full support for HDF5 time datatypes (rare)
- ✅ **✨ Integer timestamps**: Helper method `readAsDateTime()` to convert int32/int64 timestamps
  - Auto-detects seconds vs milliseconds
  - Supports forced unit specification
  - Common in scientific data (most tools use int64 instead of time datatype)

**Partially Supported:**
- ⚠️ **Region references**: Object references work, but region selection parsing not yet implemented
  - Impact: Cannot extract specific regions from referenced datasets
  - Workaround: Access full datasets directly by path

**Not Supported:**
- ❌ **Complex numbers**: No support for complex float32/float64
  - Impact: Scientific data with complex numbers cannot be read
  - Workaround: Store as compound type with real/imaginary fields
  
- ❌ **Fixed-point decimal**: No fixed-point number support
  - Impact: Precision issues with financial/scientific data
  - Workaround: Use floating-point or store as integers with scale factor

#### Storage and Compression

**Supported:**
- ✅ Contiguous storage
- ✅ Chunked storage with B-tree v1 indexing
- ✅ Gzip compression
- ✅ LZF compression
- ✅ Shuffle filter

**Not Supported:**
- ❌ **Virtual datasets (VDS)**: Cannot read datasets that reference other datasets
  - Impact: VDS files will fail to read
  - Workaround: Materialize VDS in Python before reading
  
- ❌ **Scale-offset filter**: Lossy compression not supported
  - Impact: Datasets with scale-offset filter will fail
  - Workaround: Disable filter when creating files
  
- ❌ **N-bit filter**: N-bit packing not supported
  - Impact: N-bit packed datasets will fail
  - Workaround: Use standard compression instead
  
- ❌ **SZIP compression**: Not supported
  - Impact: SZIP compressed datasets will fail
  - Workaround: Use gzip or lzf compression
  
- ❌ **Fletcher32 checksum**: No data integrity verification
  - Impact: Cannot verify data integrity
  - Workaround: Verify files with h5check or Python h5py

#### Dataset Features

- ❌ **Fill values**: Not handled for uninitialized data
  - Impact: May return incorrect values for sparse datasets
  - Workaround: Ensure datasets are fully initialized
  
- ❌ **External storage**: Cannot read datasets stored in external files
  - Impact: Externally stored datasets will fail
  - Workaround: Use internal storage only
  
- ❌ **Compact storage**: Small datasets stored in object header not supported
  - Impact: Some small datasets may fail to read
  - Workaround: Use contiguous storage

### Working with 3D+ Datasets

3D and higher-dimensional datasets are now supported! They are automatically flattened to 1D with shape information preserved:

```dart
// Read a 3D dataset
final df = await FileReader.readHDF5('data.h5', dataset: '/volume');

// Access the shape information
final shapeStr = df['_shape'][0]; // e.g., "2x3x4"
final ndim = df['_ndim'][0];      // e.g., 3

// Parse the shape
final shape = shapeStr.split('x').map(int.parse).toList();
print('Original shape: $shape'); // [2, 3, 4]

// The data is flattened in row-major order
final flatData = df['data'].data; // .data gets the underlying list from Series

// Reshape manually if needed
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

#### Complete Working Example

Here's a full example demonstrating reading and reshaping multi-dimensional datasets:

```dart
import 'dart:io';
import 'package:dartframe/dartframe.dart';

/// Example demonstrating reading multi-dimensional (3D+) HDF5 datasets
void main() async {
  print('=== HDF5 Multi-dimensional Dataset Example ===\n');

  // Example 1: Read 3D dataset
  print('--- Example 1: Reading 3D Dataset ---');
  final df3d = await FileReader.readHDF5(
    'test_data/test_3d.h5',
    dataset: '/volume',
  );

  print('Shape information:');
  print('  Shape string: ${df3d['_shape'][0]}');
  print('  Dimensions: ${df3d['_ndim'][0]}');

  // Parse the shape
  final shapeStr = df3d['_shape'][0] as String;
  final shape3d = shapeStr.split('x').map(int.parse).toList();
  print('  Parsed shape: $shape3d');
  print('');

  final data3d = df3d['data'].data; // Get the underlying list from Series
  print('Flattened data (first 10 elements): ${data3d.take(10).toList()}');
  print('Total elements: ${data3d.length}');
  print('');

  // Example 2: Read 4D dataset
  print('--- Example 2: Reading 4D Dataset ---');
  final df4d = await FileReader.readHDF5(
    'test_data/test_4d.h5',
    dataset: '/tensor',
  );

  final shape4dStr = df4d['_shape'][0] as String;
  final shape4d = shape4dStr.split('x').map(int.parse).toList();
  print('Original shape: $shape4d');
  print('Total elements: ${df4d['data'].length}');
  print('');

  // Example 3: Reshape 3D data
  print('--- Example 3: Reshaping 3D Data ---');
  print('Reshaping from flat array to ${shape3d[0]}x${shape3d[1]}x${shape3d[2]}...');

  final reshaped = reshape3D(data3d, shape3d);
  print('Reshaped dimensions: ${reshaped.length} x ${reshaped[0].length} x ${reshaped[0][0].length}');
  print('');
  print('Sample slice [0][0]: ${reshaped[0][0]}');
  print('Sample slice [1][2]: ${reshaped[1][2]}');
  print('');

  // Example 4: Mixed dimensionality file
  print('--- Example 4: Mixed Dimensionality File ---');

  final dfVector = await FileReader.readHDF5(
    'test_data/test_mixed_dims.h5',
    dataset: '/vector',
  );
  print('1D vector: ${dfVector['data'].data.take(5).toList()}...');

  final dfMatrix = await FileReader.readHDF5(
    'test_data/test_mixed_dims.h5',
    dataset: '/matrix',
  );
  print('2D matrix columns: ${dfMatrix.columns}');

  final dfCube = await FileReader.readHDF5(
    'test_data/test_mixed_dims.h5',
    dataset: '/cube',
  );
  final cubeShapeStr = dfCube['_shape'][0] as String;
  final cubeShape = cubeShapeStr.split('x').map(int.parse).toList();
  print('3D cube shape: $cubeShape');
  print('');

  print('=== Examples Complete ===');
}

/// Helper function to reshape flat data into 3D structure
List<List<List<dynamic>>> reshape3D(List<dynamic> flat, List<int> shape) {
  if (shape.length != 3) {
    throw ArgumentError('Shape must have exactly 3 dimensions');
  }

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

/// Helper function to reshape flat data into 4D structure
List<List<List<List<dynamic>>>> reshape4D(List<dynamic> flat, List<int> shape) {
  if (shape.length != 4) {
    throw ArgumentError('Shape must have exactly 4 dimensions');
  }

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

**Output:**
```
=== HDF5 Multi-dimensional Dataset Example ===

--- Example 1: Reading 3D Dataset ---
Shape information:
  Shape string: 2x3x4
  Dimensions: 3
  Parsed shape: [2, 3, 4]

Flattened data (first 10 elements): [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
Total elements: 24

--- Example 2: Reading 4D Dataset ---
Original shape: [2, 3, 4, 5]
Total elements: 120

--- Example 3: Reshaping 3D Data ---
Reshaping from flat array to 2x3x4...
Reshaped dimensions: 2 x 3 x 4

Sample slice [0][0]: [0, 1, 2, 3]
Sample slice [1][2]: [20, 21, 22, 23]

--- Example 4: Mixed Dimensionality File ---
1D vector: [0, 1, 2, 3, 4]...
2D matrix columns: [col_0, col_1, col_2, col_3, col_4]
3D cube shape: [3, 4, 5]

=== Examples Complete ===
```

**Key Points:**
- Use `df['_shape'][0]` to get the shape string (e.g., "2x3x4")
- Use `df['_ndim'][0]` to get the number of dimensions
- Use `df['data'].data` to get the underlying list from the Series
- Data is stored in row-major (C-style) order
- Reshape functions can be adapted for any dimensionality

See `example/hdf5_multidimensional.dart` for the complete runnable example.

#### Legacy Manual Approach

If you prefer direct access without DataFrame conversion:

```dart
// Option 1: Flatten in Python before reading
import h5py
import numpy as np

with h5py.File('data.h5', 'r+') as f:
    data_3d = f['dataset_3d'][:]
    # Flatten to 2D
    data_2d = data_3d.reshape(-1, data_3d.shape[-1])
    f.create_dataset('dataset_2d', data=data_2d)

// Option 2: Read multiple 2D slices
// Access each slice separately if organized that way

// Option 3: Use low-level API to read raw data
import 'package:dartframe/dartframe.dart';

final file = await Hdf5File.open('data.h5');
final data = await file.readDataset('/dataset_3d');
// Manually reshape the flat list
```

#### For Variable-Length Types

```python
# Convert vlen to fixed-length in Python
import h5py
import numpy as np

with h5py.File('input.h5', 'r') as fin:
    with h5py.File('output.h5', 'w') as fout:
        # For vlen strings
        vlen_data = fin['vlen_strings'][:]
        max_len = max(len(s) for s in vlen_data)
        fixed_data = np.array(vlen_data, dtype=f'S{max_len}')
        fout.create_dataset('fixed_strings', data=fixed_data)
```

#### For Complex Numbers

```python
# Store complex as compound type
import h5py
import numpy as np

complex_data = np.array([1+2j, 3+4j, 5+6j])

# Create compound type with real and imaginary parts
dt = np.dtype([('real', 'f8'), ('imag', 'f8')])
compound_data = np.empty(len(complex_data), dtype=dt)
compound_data['real'] = complex_data.real
compound_data['imag'] = complex_data.imag

with h5py.File('output.h5', 'w') as f:
    f.create_dataset('complex_as_compound', data=compound_data)
```

#### For Writing Files

```dart
// Use Python h5py or other tools to create HDF5 files
// DartFrame can then read them
```

```python
# Python example for creating compatible files
import h5py
import numpy as np

with h5py.File('output.h5', 'w') as f:
    # Use supported datatypes
    f.create_dataset('integers', data=np.arange(100, dtype='i4'))
    f.create_dataset('floats', data=np.random.randn(100).astype('f8'))
    f.create_dataset('strings', data=np.array(['a', 'b', 'c'], dtype='S10'))
    
    # Use supported compression
    f.create_dataset('compressed', data=np.arange(1000), 
                     compression='gzip', compression_opts=9)
    
    # Use chunked storage for large data
    f.create_dataset('chunked', data=np.arange(10000).reshape(100, 100),
                     chunks=(10, 10))
```

### Compatibility Notes

**Works Well With:**
- Files created by Python h5py (most common)
- MATLAB v7.3 MAT-files
- Files from R's rhdf5 package
- Files from C/C++ HDF5 library (standard features)

**May Have Issues With:**
- Files using advanced compression (SZIP, scale-offset, n-bit)
- Files with virtual datasets
- Files with complex numbers
- Files with time datatypes
- Files with extensive use of variable-length types

**Best Practices for Compatibility:**
1. Use standard datatypes (integers, floats, fixed-length strings)
2. Use gzip or lzf compression only
3. Avoid virtual datasets
4. Keep datasets 1D or 2D when possible
5. Use contiguous or chunked storage (not compact or external)
6. Test with small sample files first

## Creating Test Files

The examples reference test HDF5 files that you can create using Python:

### Python Script for Compressed Data

```python
# create_compressed_hdf5.py
import h5py
import numpy as np

with h5py.File('test_compressed.h5', 'w') as f:
    # Create gzip-compressed dataset
    data = np.arange(100, dtype=np.float64)
    f.create_dataset('gzip_1d', data=data, compression='gzip')
    
    # Create lzf-compressed dataset
    f.create_dataset('lzf_1d', data=data, compression='lzf')
```

### Python Script for Chunked Data

```python
# create_chunked_hdf5.py
import h5py
import numpy as np

with h5py.File('test_chunked.h5', 'w') as f:
    # Create 1D chunked dataset
    data1d = np.arange(100, dtype=np.float64)
    f.create_dataset('chunked_1d', data=data1d, chunks=(10,))
    
    # Create 2D chunked dataset
    data2d = np.arange(60).reshape(10, 6)
    f.create_dataset('chunked_2d', data=data2d, chunks=(5, 3))
```

### Checking File Existence

Always check if files exist before reading:

```dart
import 'dart:io';

Future<void> readIfExists(String path) async {
  if (!File(path).existsSync()) {
    print('File not found: $path');
    print('Note: Create using create_compressed_hdf5.py');
    return;
  }
  
  final df = await FileReader.readHDF5(path, dataset: '/data');
  print('Successfully read: ${df.shape}');
}
```

## Troubleshooting

### Problem: "Invalid HDF5 signature"

**Causes:**
- File is not HDF5 format
- File is corrupted
- File is truncated

**Solutions:**
- Verify file with `h5dump` or Python h5py
- Check file size (should be > 512 bytes)
- Try opening with debug mode

### Problem: "Dataset not found"

**Causes:**
- Incorrect dataset path
- Dataset doesn't exist
- Case sensitivity issue

**Solutions:**
- Use `listDatasets()` to see available datasets
- Check path starts with '/'
- Verify path spelling and case

### Problem: "Unsupported feature"

**Causes:**
- Advanced HDF5 feature not implemented
- Rare data type
- Complex structure

**Solutions:**
- Enable debug mode to see what's unsupported
- Check limitations section
- Consider preprocessing with Python

### Problem: Performance issues

**Causes:**
- Very large file
- Many small chunks
- Uncompressed data

**Solutions:**
- Use chunked datasets
- Enable compression
- Read subsets instead of entire dataset
- Consider file optimization with h5repack

## Examples

See the `example` directory for complete working examples:

### New Comprehensive Examples
- `hdf5_basic_reading.dart` - Basic reading operations, error handling, data types
- `hdf5_group_navigation.dart` - Navigating file hierarchies, inspecting structure
- `hdf5_attributes.dart` - Reading metadata and attributes
- `hdf5_advanced_features.dart` - Compression, chunking, debug mode, MATLAB files

### Additional Examples
- `get_structure.dart` - Get file structure as a map for programmatic access
- `inspect_file_structure.dart` - Inspect and display file structure
- `list_all_datasets_recursive.dart` - Recursively list all datasets
- `datatype_api_demo.dart` - Working with HDF5 datatypes directly (advanced)
- `test_attributes.dart` - Test attribute reading functionality
- `test_chunked_reading.dart` - Test chunked dataset reading
- `test_compression.dart` - Test compressed dataset reading
- `test_error_diagnostics.dart` - Error handling and diagnostics
- `test_object_type_detection.dart` - Object type detection
- `test_caching.dart` - Caching mechanisms

## API Reference

### FileReader.readHDF5()

```dart
Future<DataFrame> FileReader.readHDF5(
  String path, {
  String? dataset,
  Map<String, dynamic>? options,
})
```

Read an HDF5 dataset and convert to DataFrame.

**Parameters:**
- `path`: Path to the HDF5 file
- `dataset`: Path to dataset within file (optional, defaults to '/data' if not specified)
- `options`: Additional options map (optional)
  - `'debug'`: Enable debug logging (bool)

**Returns:** DataFrame containing the dataset

**Throws:**
- `Hdf5Error` - HDF5-specific errors
- `FileSystemException` - File access errors

### HDF5Reader.inspect()

```dart
Future<Map<String, dynamic>> HDF5Reader.inspect(
  String path, {
  bool debug = false,
})
```

Get information about HDF5 file structure.

**Parameters:**
- `path`: Path to the HDF5 file
- `debug`: Enable debug logging (optional, default: false)

**Returns:** Map with keys:
- `version` - HDF5 format version
- `rootChildren` - List of root-level objects
- `datasets` - List of available datasets

### HDF5Reader.listDatasets()

```dart
Future<List<String>> HDF5Reader.listDatasets(
  String path, {
  bool debug = false,
})
```

List all datasets in the file.

**Parameters:**
- `path`: Path to the HDF5 file
- `debug`: Enable debug logging (optional, default: false)

**Returns:** List of dataset names

### HDF5Reader.readAttributes()

```dart
Future<Map<String, dynamic>> HDF5Reader.readAttributes(
  String path, {
  String dataset = '/data',
  bool debug = false,
})
```

Read attributes (metadata) from a dataset.

**Parameters:**
- `path`: Path to the HDF5 file
- `dataset`: Path to dataset (optional, default: '/data')
- `debug`: Enable debug logging (optional, default: false)

**Returns:** Map of attribute names to values

### HDF5Reader.setDebugMode()

```dart
static void HDF5Reader.setDebugMode(bool enabled)
```

Enable or disable debug mode globally.

## Additional Resources

- [HDF5 Format Specification](https://www.hdfgroup.org/solutions/hdf5/)
- [Python h5py Documentation](https://docs.h5py.org/)
- [MATLAB HDF5 Documentation](https://www.mathworks.com/help/matlab/hdf5-files.html)
- [DartFrame Examples](../example/)

## Quick Reference

### Common Patterns

**Read and display basic info:**
```dart
final df = await FileReader.readHDF5('data.h5', dataset: '/mydata');
print('Shape: ${df.shape}');
print('Columns: ${df.columns}');
print(df.head());
```

**Explore file before reading:**
```dart
final datasets = await HDF5Reader.listDatasets('data.h5');
print('Available: $datasets');
```

**Read with error handling:**
```dart
try {
  final df = await FileReader.readHDF5('data.h5', dataset: '/data');
} on Hdf5Error catch (e) {
  print('HDF5 error: $e');
}
```

**Enable debug mode:**
```dart
final df = await FileReader.readHDF5(
  'data.h5',
  dataset: '/data',
  options: {'debug': true},
);
```

**Read MATLAB file:**
```dart
final datasets = await HDF5Reader.listDatasets('data.mat');
final df = await FileReader.readHDF5('data.mat', dataset: '/${datasets.first}');
```

**Check metadata:**
```dart
final attrs = await HDF5Reader.readAttributes('data.h5', dataset: '/data');
print('Units: ${attrs['units']}');
```

**Stream large dataset:**
```dart
import 'package:dartframe/dartframe.dart';

final file = await Hdf5File.open('data.h5');
await for (final chunk in file.readDatasetChunked('/data', chunkSize: 1000)) {
  // Process chunk
}
await file.close();
```

**Read dataset slice:**
```dart
final file = await Hdf5File.open('data.h5');
final slice = await file.readDatasetSlice('/data', start: [0, 0], end: [100, null]);
await file.close();
```

**Check cache stats:**
```dart
final file = await Hdf5File.open('data.h5');
print(file.cacheStats);
file.clearCache();
await file.close();
```

### File Existence Pattern

```dart
if (!File(filePath).existsSync()) {
  print('File not found: $filePath');
  return;
}
final df = await FileReader.readHDF5(filePath, dataset: '/data');
```

## Contributing

Found a bug or want to add a feature? Contributions are welcome!

- Report issues on GitHub
- Submit pull requests
- Improve documentation
- Add more examples
