# Design Document: Complete HDF5 Support for DartFrame

## Overview

This design document describes the architecture and implementation approach for comprehensive HDF5 file reading support in DartFrame. The solution uses a pure Dart implementation with no FFI dependencies, ensuring cross-platform compatibility while providing efficient access to HDF5 datasets.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    DartFrame Public API                      │
│  FileReader.read() / FileReader.readHDF5()                  │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    HDF5Reader                                │
│  - Implements DataReader interface                           │
│  - Converts HDF5 datasets to DataFrames                     │
│  - Handles inspection and listing                           │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    Hdf5File                                  │
│  - Main file handle and navigation                          │
│  - Manages superblock and root group                        │
│  - Provides dataset/group access by path                    │
└─────┬──────────────────┬──────────────────┬────────────────┘
      │                  │                  │
┌─────▼─────┐   ┌───────▼────────┐   ┌────▼──────────┐
│  Group    │   │    Dataset     │   │  Attribute    │
│           │   │                │   │               │
│ - Children│   │ - Datatype     │   │ - Name/Value  │
│ - B-tree  │   │ - Dataspace    │   │ - Datatype    │
│ - Heap    │   │ - Layout       │   │               │
└───────────┘   │ - Data reading │   └───────────────┘
                └────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
┌───────▼──────┐  ┌─────▼──────┐  ┌─────▼──────────┐
│ Contiguous   │  │  Chunked   │  │  Compressed    │
│ Layout       │  │  Layout    │  │  Data          │
│              │  │            │  │                │
│ - Direct read│  │ - B-tree   │  │ - Gzip         │
│              │  │ - Chunks   │  │ - LZF          │
└──────────────┘  └────────────┘  └────────────────┘
```

### Component Responsibilities

#### 1. ByteReader
- **Purpose**: Low-level binary file I/O with endianness support
- **Responsibilities**:
  - Random access file reading
  - Type-safe reading (uint8-64, int8-64, float32/64)
  - Position tracking and seeking
  - Endianness handling (little/big endian)

#### 2. Superblock
- **Purpose**: Parse HDF5 file header and metadata
- **Responsibilities**:
  - Validate HDF5 signature at multiple offsets
  - Parse version-specific superblock structures
  - Extract file metadata (version, offset size, root group address)
  - Handle MATLAB MAT-file offset detection

#### 3. ObjectHeader
- **Purpose**: Parse HDF5 object headers and messages
- **Responsibilities**:
  - Read object header versions 1 and 2
  - Parse header messages (datatype, dataspace, layout, etc.)
  - Handle message alignment and padding
  - Extract metadata from various message types

#### 4. Group
- **Purpose**: Navigate HDF5 group hierarchies
- **Responsibilities**:
  - Parse symbol tables (old-style groups)
  - Parse link messages (new-style groups)
  - Traverse B-trees for group members
  - Read local heaps for name strings
  - List children (datasets and subgroups)
  - Navigate nested paths

#### 5. Dataset
- **Purpose**: Read HDF5 dataset data
- **Responsibilities**:
  - Parse dataset metadata (datatype, dataspace, layout)
  - Read contiguous data
  - Read chunked data with B-tree navigation
  - Handle compressed data
  - Convert raw bytes to typed arrays
  - Support multi-dimensional arrays

#### 6. Datatype
- **Purpose**: Represent HDF5 data types
- **Responsibilities**:
  - Parse datatype messages
  - Support numeric types (int, uint, float)
  - Support string types (fixed, variable)
  - Support compound types (structs)
  - Map HDF5 types to Dart types

#### 7. Dataspace
- **Purpose**: Represent array dimensions
- **Responsibilities**:
  - Parse dataspace messages
  - Extract dimensions and shape
  - Calculate total element count
  - Handle unlimited dimensions

#### 8. Attribute
- **Purpose**: Read dataset and group attributes
- **Responsibilities**:
  - Parse attribute messages
  - Read attribute data
  - Support scalar and array attributes
  - Handle various attribute datatypes

#### 9. Compression
- **Purpose**: Decompress compressed datasets
- **Responsibilities**:
  - Detect compression type from filter pipeline
  - Decompress gzip data
  - Decompress lzf data
  - Handle decompression errors

#### 10. HDF5Reader
- **Purpose**: Integrate with DartFrame
- **Responsibilities**:
  - Implement DataReader interface
  - Convert datasets to DataFrames
  - Handle 1D and 2D array conversion
  - Provide inspection utilities
  - Format error messages

## Data Models

### Hdf5File
```dart
class Hdf5File {
  final File _file;
  final RandomAccessFile _raf;
  final Superblock _superblock;
  final Group _rootGroup;
  
  Future<Dataset> dataset(String path);
  Future<Group> group(String path);
  Future<List<Attribute>> attributes(String path);
  List<String> list(String path);
  Map<String, dynamic> get info;
}
```

### Dataset
```dart
class Dataset<T> {
  final ObjectHeader header;
  final Hdf5Datatype<T> datatype;
  final Hdf5Dataspace dataspace;
  final DataLayout layout;
  final List<Filter>? filters;
  
  Future<List<T>> readData(ByteReader reader);
  List<int> get shape;
  String get dtype;
}
```

### Group
```dart
class Group {
  final ObjectHeader header;
  final Map<String, int> _childAddresses;
  
  List<String> get children;
  int? getChildAddress(String name);
  bool isDataset(String name);
  bool isGroup(String name);
}
```

### Attribute
```dart
class Attribute {
  final String name;
  final Hdf5Datatype datatype;
  final Hdf5Dataspace dataspace;
  final dynamic value;
  
  T getValue<T>();
  List<T> getArray<T>();
}
```

## Key Algorithms

### 1. Multi-Offset Signature Detection
```
Algorithm: FindHDF5Signature
Input: ByteReader reader
Output: int offset (or throw exception)

offsets = [0, 512, 1024, 2048]
signature = [0x89, 0x48, 0x44, 0x46, 0x0D, 0x0A, 0x1A, 0x0A]

for each offset in offsets:
    reader.seek(offset)
    valid = true
    for each byte in signature:
        if reader.readUint8() != byte:
            valid = false
            break
    if valid:
        return offset

throw Exception("Invalid HDF5 signature")
```

### 2. Group Navigation
```
Algorithm: NavigateToPath
Input: String path (e.g., "/group1/group2/dataset")
Output: int address

parts = path.split('/').filter(not empty)
currentGroup = rootGroup

for each part in parts[0..-1]:  // All but last
    childAddress = currentGroup.getChildAddress(part)
    if childAddress is null:
        throw Exception("Group not found: " + part)
    currentGroup = Group.read(reader, childAddress + hdf5Offset)

finalName = parts.last
finalAddress = currentGroup.getChildAddress(finalName)
if finalAddress is null:
    throw Exception("Object not found: " + finalName)

return finalAddress + hdf5Offset
```

### 3. Chunked Data Reading
```
Algorithm: ReadChunkedDataset
Input: Dataset dataset, ByteReader reader
Output: List<T> data

chunkLayout = dataset.layout as ChunkedLayout
chunkDims = chunkLayout.chunkDimensions
datasetDims = dataset.dataspace.dimensions

// Calculate number of chunks in each dimension
numChunks = []
for i in 0..datasetDims.length:
    numChunks[i] = ceil(datasetDims[i] / chunkDims[i])

// Initialize result array
totalElements = product(datasetDims)
result = new Array(totalElements)

// Read each chunk
for each chunkIndex in allChunkIndices(numChunks):
    chunkAddress = findChunkAddress(chunkLayout.btreeAddress, chunkIndex)
    chunkData = readChunk(reader, chunkAddress, chunkDims, dataset.filters)
    
    // Place chunk data in correct position
    copyChunkToResult(chunkData, result, chunkIndex, chunkDims, datasetDims)

return result
```

### 4. Compression Handling
```
Algorithm: DecompressData
Input: byte[] compressedData, Filter filter
Output: byte[] decompressedData

switch filter.type:
    case GZIP:
        return gzipDecompress(compressedData)
    case LZF:
        return lzfDecompress(compressedData)
    case SHUFFLE:
        return shuffleUnshuffle(compressedData, filter.params)
    default:
        throw Exception("Unsupported compression: " + filter.type)
```

## Data Flow

### Reading a Dataset

1. **Open File**
   ```
   User → FileReader.readHDF5(path, dataset: "/data")
   → HDF5Reader.read()
   → Hdf5File.open(path)
   ```

2. **Parse Superblock**
   ```
   Hdf5File.open()
   → ByteReader.seek(0)
   → Superblock.read(reader)
   → Detect HDF5 offset
   → Parse version-specific structure
   ```

3. **Navigate to Dataset**
   ```
   Hdf5File.dataset("/group/data")
   → Group.read(rootAddress)
   → Navigate through "group"
   → Find "data" address
   → Dataset.read(dataAddress)
   ```

4. **Read Dataset Metadata**
   ```
   Dataset.read(address)
   → ObjectHeader.read(address)
   → Parse datatype message
   → Parse dataspace message
   → Parse data layout message
   → Parse filter pipeline (if present)
   ```

5. **Read Dataset Data**
   ```
   Dataset.readData(reader)
   → If contiguous: read from layout.address
   → If chunked: read chunks via B-tree
   → If compressed: decompress each chunk
   → Convert bytes to typed array
   ```

6. **Convert to DataFrame**
   ```
   HDF5Reader.read()
   → Get data as List<dynamic>
   → Get shape from dataspace
   → Create DataFrame columns
   → Return DataFrame
   ```

## Error Handling Strategy

### Error Categories

1. **File Errors**
   - Invalid HDF5 signature → `InvalidHDF5FileException`
   - File not found → `FileNotFoundException`
   - Permission denied → `FileAccessException`

2. **Format Errors**
   - Unsupported version → `UnsupportedVersionException`
   - Corrupted structure → `CorruptedFileException`
   - Invalid message → `InvalidMessageException`

3. **Navigation Errors**
   - Path not found → `PathNotFoundException`
   - Not a dataset → `NotADatasetException`
   - Not a group → `NotAGroupException`

4. **Data Errors**
   - Unsupported datatype → `UnsupportedDatatypeException`
   - Decompression failed → `DecompressionException`
   - Invalid data → `DataReadException`

### Error Message Format
```
HDF5ReadError: {operation} failed
File: {filepath}
Path: {dataset_path}
Reason: {specific_error}
Details: {additional_context}
```

## Testing Strategy

### Unit Tests

1. **ByteReader Tests**
   - Test all read methods (uint8-64, int8-64, float32/64)
   - Test endianness handling
   - Test position tracking

2. **Superblock Tests**
   - Test version 0, 1, 2, 3 parsing
   - Test multi-offset detection
   - Test MATLAB offset handling

3. **Datatype Tests**
   - Test all numeric types
   - Test string types
   - Test compound types

4. **Dataspace Tests**
   - Test 1D, 2D, 3D dimensions
   - Test unlimited dimensions
   - Test element count calculation

5. **Group Tests**
   - Test symbol table parsing
   - Test B-tree traversal
   - Test heap name reading

6. **Dataset Tests**
   - Test contiguous reading
   - Test chunked reading
   - Test compressed reading

### Integration Tests

1. **Python h5py Files**
   - Create test files with h5py
   - Test various datatypes
   - Test nested groups
   - Test attributes

2. **MATLAB Files**
   - Test MAT-file v7.3 reading
   - Test variable access
   - Test structure handling

3. **Real-World Files**
   - Test with scientific datasets
   - Test with large files
   - Test with complex hierarchies

### Performance Tests

1. **Benchmark Reading Speed**
   - Measure MB/s throughput
   - Compare contiguous vs chunked
   - Measure compression overhead

2. **Memory Usage**
   - Monitor memory during large file reading
   - Test streaming capabilities
   - Verify no memory leaks

## Implementation Phases

### Phase 1: Core Enhancement (Current → Complete)
- ✅ Basic file reading
- ✅ Contiguous datasets
- ✅ Simple groups
- ✅ Numeric datatypes
- ⚠️ Fix remaining issues (test1.h5, processdata.h5)

### Phase 2: Chunked Storage
- Implement B-tree v1 for chunk indexing
- Implement chunk assembly
- Test with chunked datasets

### Phase 3: Compression
- Implement gzip decompression
- Implement lzf decompression
- Handle filter pipelines

### Phase 4: Advanced Types
- Implement string datatypes
- Implement compound datatypes
- Implement array datatypes

### Phase 5: Attributes
- Parse attribute messages
- Read attribute data
- Expose attribute API

### Phase 6: Optimization
- Implement metadata caching
- Optimize B-tree traversal
- Add streaming support

## Dependencies

### External Packages
- `archive` (for gzip decompression) - may be needed
- No FFI dependencies
- No platform-specific code

### Internal Dependencies
- DartFrame DataFrame API
- DartFrame Series API
- Dart core libraries (dart:io, dart:typed_data)

## Performance Considerations

### Memory Management
- Use RandomAccessFile for efficient I/O
- Read only required data, not entire file
- Cache frequently accessed metadata
- Provide streaming options for large datasets

### I/O Optimization
- Minimize file seeks
- Read contiguous blocks when possible
- Reuse file handles
- Buffer small reads

### Caching Strategy
- Cache superblock and root group
- Cache group structures during navigation
- Cache datatype and dataspace for repeated access
- Provide cache size limits

## Security Considerations

- Validate all file offsets before reading
- Check array bounds before allocation
- Limit recursion depth in group navigation
- Validate string lengths before allocation
- Handle malformed files gracefully

## Future Enhancements

1. **Writing Support**
   - Create new HDF5 files
   - Write datasets
   - Create groups
   - Set attributes

2. **Advanced Features**
   - Virtual datasets (VDS)
   - External links
   - Object references
   - Region references

3. **Performance**
   - Parallel chunk reading
   - Memory-mapped I/O
   - Lazy loading

4. **Compatibility**
   - HDF4 reading
   - NetCDF reading
   - More compression algorithms
