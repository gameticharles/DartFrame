# HDF5 File Inspection and Navigation

This document describes the new file inspection and navigation features added to the DartFrame HDF5 reader.

## Features

### 1. Dataset Inspection (`Dataset.inspect()`)

Inspect dataset metadata without reading the actual data:

```dart
final file = await Hdf5File.open('data.h5');
final dataset = await file.dataset('/mydata');
final info = dataset.inspect();

print('Shape: ${info['shape']}');
print('Type: ${info['dtype']}');
print('Size: ${info['size']} elements');
print('Storage: ${info['storage']}');

if (info.containsKey('chunkDimensions')) {
  print('Chunk dimensions: ${info['chunkDimensions']}');
}

if (info.containsKey('compression')) {
  print('Compression: ${info['compression']}');
}
```

Returns:
- `shape`: List of dimensions
- `dtype`: Data type name (e.g., 'int32', 'float64', 'compound {x, y}')
- `size`: Total number of elements
- `storage`: Storage layout ('contiguous', 'chunked', or 'compact')
- `chunkDimensions`: Chunk dimensions (if chunked)
- `compression`: Compression info (if compressed)
- `attributes`: Map of attribute names to values

### 2. Group Inspection (`Group.inspect()`)

Inspect group metadata:

```dart
final file = await Hdf5File.open('data.h5');
final group = await file.group('/experiment');
final info = group.inspect();

print('Children: ${info['childCount']}');
print('Names: ${info['children']}');
```

Returns:
- `childCount`: Number of children (datasets and groups)
- `children`: List of child names
- `attributes`: Map of attribute names to values

### 3. Recursive Listing (`Hdf5File.listRecursive()`)

Get a complete hierarchical structure of the file:

```dart
final file = await Hdf5File.open('data.h5');
final structure = await file.listRecursive();

for (final entry in structure.entries) {
  final path = entry.key;
  final info = entry.value;
  
  print('$path: ${info['type']}');
  if (info['type'] == 'dataset') {
    print('  Shape: ${info['shape']}');
    print('  Type: ${info['dtype']}');
  }
}
```

Returns a map where keys are paths and values contain all metadata from `inspect()` plus a `type` field ('dataset' or 'group').

### 4. Tree Visualization (`Hdf5File.printTree()`)

Print a tree-like visualization of the file structure:

```dart
final file = await Hdf5File.open('data.h5');
await file.printTree(
  showAttributes: true,
  showSizes: true,
);
```

Example output:
```
/
├── data (dataset)
│   Shape: [100, 50]
│   Type: float64
│   Size: 5000 elements
│   Storage: chunked [10, 10]
│   Compression: deflate
│   Attributes: units=meters
└── experiment (group)
    Children: 2
    ├── measurements (dataset)
    │   Shape: [1000]
    │   Type: int32
    │   Size: 1000 elements
    │   Storage: contiguous
    └── metadata (group)
        Children: 0
```

### 5. Summary Statistics (`Hdf5File.getSummaryStats()`)

Get summary statistics about the file:

```dart
final file = await Hdf5File.open('data.h5');
final stats = await file.getSummaryStats();

print('Total datasets: ${stats['totalDatasets']}');
print('Total groups: ${stats['totalGroups']}');
print('Max depth: ${stats['maxDepth']}');
print('Compressed: ${stats['compressedDatasets']}');
print('Chunked: ${stats['chunkedDatasets']}');

final datasetsByType = stats['datasetsByType'] as Map<String, int>;
for (final entry in datasetsByType.entries) {
  print('${entry.key}: ${entry.value}');
}
```

Returns:
- `totalDatasets`: Total number of datasets
- `totalGroups`: Total number of groups
- `totalObjects`: Total number of objects (datasets + groups)
- `maxDepth`: Maximum nesting depth
- `datasetsByType`: Count of datasets by data type
- `compressedDatasets`: Number of compressed datasets
- `chunkedDatasets`: Number of chunked datasets

## Examples

See the following example files:
- `example/inspect_file_structure.dart` - Comprehensive inspection example
- `example/inspect_chunked_file.dart` - Chunked dataset inspection

## Use Cases

1. **File exploration**: Quickly understand the structure of an HDF5 file without reading all data
2. **Metadata extraction**: Get dataset shapes, types, and attributes for documentation
3. **Performance planning**: Identify chunked and compressed datasets before reading
4. **Validation**: Verify file structure matches expectations
5. **Debugging**: Diagnose issues with file structure or data layout

## Performance

All inspection methods are designed to be fast and memory-efficient:
- Only metadata is read, not actual dataset data
- File structure is traversed once and cached
- Suitable for large files with many datasets

## Requirements Satisfied

This implementation satisfies the following requirements from the HDF5 Full Support specification:

- **Requirement 8.3**: Recursively list all groups and datasets
- **Requirement 8.4**: Inspect datasets without reading data
- **Requirement 8.5**: Inspect groups and their children
- **Requirement 8.1-8.5**: Complete file inspection capabilities
