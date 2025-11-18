# DataCube Implementation Plan
## N-Dimensional Data Structure with HDF5/MATLAB/Python Interoperability

**Version:** 1.0  
**Target:** Full N-dimensional support with lazy evaluation  
**Interoperability:** HDF5, MATLAB, Python (pandas, xarray)  
**Type System:** `dynamic` (matching DataFrame/Series)  
**Evaluation:** Lazy by default  

---

## Executive Summary

This plan outlines the implementation of a complete N-dimensional data system:
- **NDArray**: Base N-dimensional structure
- **DataCube**: 3D specialization (stack of DataFrames)
- **Smart Slicing**: Returns appropriate type (Scalar/Series/DataFrame/DataCube/NDArray)
- **Dual Format**: `.dcf` (native, optimized) + HDF5 (interoperability)
- **Lazy Evaluation**: Memory-efficient by default
- **Chunked Storage**: Handle datasets larger than RAM
- **Compression**: Modern codecs (Zstd, LZ4)

---

## Phase 1: Core Foundation (Weeks 1-3)

### Week 1: Type Hierarchy & Shape System

#### 1.1 Enhanced Shape Class
**File:** `lib/src/core/shape.dart`

**Features:**
- Strides calculation for flat indexing
- Broadcasting support
- Dimension manipulation
- Index conversion (flat ↔ multi-dimensional)

**Key Methods:**
```dart
class Shape {
  List<int> get strides;
  int toFlatIndex(List<int> indices);
  List<int> fromFlatIndex(int flatIndex);
  bool canBroadcastWith(Shape other);
  Shape broadcastWith(Shape other);
}
```


#### 1.2 Base Type Hierarchy
**File:** `lib/src/core/dart_data.dart`

**Abstract Base:**
```dart
abstract class DartData {
  Shape get shape;
  int get ndim;
  int get size;
  Attributes get attrs;
  dynamic getValue(List<int> indices);
  void setValue(List<int> indices, dynamic value);
  DartData slice(List<dynamic> sliceSpec);
}
```

**Concrete Types:**
- `Scalar` (0D) - `lib/src/core/scalar.dart`
- `Series` (1D) - Enhance existing
- `DataFrame` (2D) - Enhance existing
- `DataCube` (3D) - New
- `NDArray` (N-D) - New

#### 1.3 Slice Specification System
**File:** `lib/src/core/slice_spec.dart`

**Classes:**
```dart
class SliceSpec {
  final int? start;
  final int? stop;
  final int? step;
  bool get isSingleIndex;
  (int, int, int) resolve(int dimSize);
}

class Slice {
  static SliceSpec all();
  static SliceSpec range(int start, int stop, {int step});
  static SliceSpec single(int index);
}
```

### Week 2: Storage Backend System

#### 2.1 Backend Interface
**File:** `lib/src/storage/storage_backend.dart`

```dart
abstract class StorageBackend {
  Shape get shape;
  dynamic getValue(List<int> indices);
  void setValue(List<int> indices, dynamic value);
  StorageBackend getSlice(List<SliceSpec> slices);
  Future<void> load();
  Future<void> unload();
  List<dynamic> getFlatData({bool copy});
  int get memoryUsage;
  bool get isInMemory;
}
```

#### 2.2 InMemory Backend
**File:** `lib/src/storage/inmemory_backend.dart`

- Flat array storage
- Fast access
- For small-medium datasets

#### 2.3 Chunked Backend
**File:** `lib/src/storage/chunked_backend.dart`

- LRU cache for chunks
- Configurable chunk size
- Automatic chunk eviction
- For large datasets

### Week 3: Attributes & Configuration

#### 3.1 Attributes System (HDF5-style)
**File:** `lib/src/core/attributes.dart`

```dart
class Attributes {
  Map<String, dynamic> _attrs;
  dynamic operator [](String key);
  void operator []=(String key, dynamic value);
  T get<T>(String key, {T? defaultValue});
  Map<String, dynamic> toJson();
  factory Attributes.fromJson(Map<String, dynamic> json);
}
```

#### 3.2 Global Configuration
**File:** `lib/src/core/config.dart`

```dart
class NDArrayConfig {
  static int maxMemoryBytes;
  static int defaultChunkSize;
  static int maxCachedChunks;
  static bool autoSelectBackend;
  static bool lazyByDefault;
  static CompressionCodec defaultCodec;
}
```

---

## Phase 2: NDArray Core (Weeks 4-6)

### Week 4: NDArray Implementation

#### 4.1 NDArray Class
**File:** `lib/src/ndarray/ndarray.dart`

**Core Features:**
- Generic N-dimensional support
- Lazy evaluation by default
- Smart slicing
- Backend abstraction

**Key Methods:**
```dart
class NDArray extends DartData {
  NDArray(List<dynamic> data, List<int> shape);
  NDArray.empty(List<int> shape, {dynamic fillValue});
  NDArray.generate(List<int> shape, Function generator);
  NDArray.withBackend(List<int> shape, StorageBackend backend);
  
  // Slicing
  DartData operator [](dynamic indexOrSlice);
  DartData slice(List<dynamic> sliceSpec);
  
  // Operations
  NDArray map(Function fn);
  NDArray where(bool Function(dynamic) predicate);
  NDArray reshape(List<int> newShape);
}
```

#### 4.2 Smart Slicing Logic
**File:** `lib/src/ndarray/smart_slicer.dart`

- Analyze slice specification
- Calculate result dimensions
- Return appropriate type (Scalar/Series/DataFrame/DataCube/NDArray)

### Week 5: Indexing & Operations

#### 5.1 Index Class (Axis Labels)
**File:** `lib/src/core/index.dart`

```dart
class Index {
  final List<dynamic> labels;
  int getPosition(dynamic label);
  dynamic getLabel(int position);
  bool contains(dynamic label);
  Index slice(SliceSpec spec);
}
```

#### 5.2 Basic Operations
**File:** `lib/src/ndarray/operations.dart`

- Element-wise operations
- Broadcasting
- Aggregations (sum, mean, max, min, etc.)
- Axis-specific operations

### Week 6: Streaming & Chunked Processing

#### 6.1 Streaming API
**File:** `lib/src/ndarray/streaming.dart`

```dart
extension Streaming on NDArray {
  Stream<NDArray> streamAlongAxis(int axis, {int chunkSize});
  Future<R> processChunked<R>({
    required int axis,
    required int chunkSize,
    required Function processor,
    required Function combiner,
  });
}
```

#### 6.2 Parallel Processing
**File:** `lib/src/ndarray/parallel.dart`

- Isolate-based parallelism
- Work distribution
- Result aggregation

---

## Phase 3: DataCube Implementation (Weeks 7-9)

### Week 7: DataCube Core

#### 7.1 DataCube Class
**File:** `lib/src/datacube/datacube.dart`

```dart
class DataCube extends DartData {
  // Always 3D: [depth, rows, columns]
  
  // Properties
  int get depth;
  int get rows;
  int get columns;
  
  // Construction
  factory DataCube.fromDataFrames(List<DataFrame> frames);
  factory DataCube.empty(int depth, int rows, int columns);
  
  // Slicing
  DataFrame operator [](int depth);  // Single sheet
  DartData slice(List<dynamic> sliceSpec);
  
  // DataFrame operations
  DataFrame getFrame(int depth);
  void setFrame(int depth, DataFrame frame);
  List<DataFrame> toDataFrames();
  Iterable<DataFrame> get frames;
  Stream<DataFrame> streamFrames();
}
```

#### 7.2 DataFrame Integration
**File:** `lib/src/datacube/dataframe_integration.dart`

- Convert DataFrame to DataCube
- Stack multiple DataFrames
- Validate frame compatibility

### Week 8: DataCube Operations

#### 8.1 Aggregations
**File:** `lib/src/datacube/aggregations.dart`

```dart
extension DataCubeAggregations on DataCube {
  DataFrame aggregateDepth(String operation);
  DataFrame aggregateRows(String operation);
  DataFrame aggregateColumns(String operation);
  
  // Statistical operations
  DataFrame sum({int? axis});
  DataFrame mean({int? axis});
  DataFrame max({int? axis});
  DataFrame min({int? axis});
}
```

#### 8.2 Transformations
**File:** `lib/src/datacube/transformations.dart`

- Transpose
- Reshape
- Permute axes
- Squeeze/expand dimensions

### Week 9: DataCube I/O

#### 9.1 Basic I/O
**File:** `lib/src/datacube/io.dart`

```dart
extension DataCubeIO on DataCube {
  Future<void> toFile(String path);
  static Future<DataCube> fromFile(String path);
  
  // CSV directory (one CSV per sheet)
  Future<void> toCSVDirectory(String dirPath);
  static Future<DataCube> fromCSVDirectory(String dirPath);
}
```

---

## Phase 4: File Formats (Weeks 10-12)

### Week 10: HDF5 Integration (Interoperability)

#### 10.1 HDF5 Writer
**File:** `lib/src/io/hdf5/hdf5_writer.dart`

**Features:**
- Write NDArray to HDF5
- Preserve attributes
- Chunked writing
- Compression support

**MATLAB/Python Compatibility:**
```dart
// Write in format compatible with:
// - Python: h5py, pandas.read_hdf()
// - MATLAB: h5read(), h5info()
// - R: rhdf5

await cube.toHDF5('data.h5', 
  dataset: '/measurements',
  attrs: {
    'units': 'celsius',
    'description': 'Temperature data',
  },
);
```

**Python Example:**
```python
import h5py
import pandas as pd

# Read DataCube as 3D array
with h5py.File('data.h5', 'r') as f:
    data = f['/measurements'][:]
    attrs = dict(f['/measurements'].attrs)
    
# Or use pandas for 2D slices
df = pd.read_hdf('data.h5', '/measurements/sheet_0')
```

**MATLAB Example:**
```matlab
% Read DataCube
data = h5read('data.h5', '/measurements');
info = h5info('data.h5', '/measurements');
attrs = info.Attributes;

% Access as 3D array
slice = data(:, :, 1);  % First sheet
```

#### 10.2 HDF5 Reader Enhancement
**File:** `lib/src/io/hdf5/hdf5_reader.dart`

- Read N-dimensional datasets
- Lazy loading support
- Partial reads (slicing)
- Attribute preservation

### Week 11: .dcf Format (Native)

#### 11.1 File Format Specification
**File:** `lib/src/io/dcf/format_spec.dart`

**Structure:**
```
.dcf File Layout:
[Header - 512 bytes]
  - Magic: "DCF\0"
  - Version: uint16
  - Flags: uint32
  - Root offset: uint64
  - Metadata offset: uint64
  - Checksum: uint32

[Metadata Section]
  - JSON metadata
  - Schema definitions
  - Compression info

[Group Tree]
  - Hierarchical structure
  - Group metadata
  - Dataset references

[Dataset Index]
  - B-tree for fast lookup
  - Chunk offset table
  - Chunk size table

[Data Chunks]
  - Compressed chunks
  - Independent compression
```

#### 11.2 DCF Writer
**File:** `lib/src/io/dcf/dcf_writer.dart`

```dart
class DartCubeFile {
  static Future<DartCubeFile> open(String path, {FileMode mode});
  
  Group createGroup(String path);
  Future<void> writeDataset(String path, NDArray data, {
    List<int>? chunkShape,
    CompressionCodec? codec,
    Map<String, dynamic>? attributes,
  });
  
  Future<void> close();
}
```

#### 11.3 DCF Reader
**File:** `lib/src/io/dcf/dcf_reader.dart`

- Lazy loading
- Chunk-based reading
- Partial reads
- Memory-efficient

### Week 12: Format Conversion

#### 12.1 Export Utilities
**File:** `lib/src/io/converters/export.dart`

```dart
extension DataCubeExport on DataCube {
  // HDF5 (for MATLAB/Python)
  Future<void> toHDF5(String path, {
    String dataset = '/data',
    Map<String, dynamic>? attrs,
  });
  
  // Parquet (for Python pandas)
  Future<void> toParquet(String path);
  
  // MAT file (for MATLAB)
  Future<void> toMAT(String path, {String varName = 'data'});
  
  // NetCDF (for scientific tools)
  Future<void> toNetCDF(String path);
}
```

#### 12.2 Import Utilities
**File:** `lib/src/io/converters/import.dart`

```dart
class DataCube {
  static Future<DataCube> fromHDF5(String path, {String? dataset});
  static Future<DataCube> fromParquet(String path);
  static Future<DataCube> fromMAT(String path, {String? varName});
  static Future<DataCube> fromNetCDF(String path);
}
```

---

## Phase 5: Compression & Optimization (Weeks 13-15)

### Week 13: Compression System

#### 13.1 Codec Interface
**File:** `lib/src/compression/codec.dart`

```dart
abstract class CompressionCodec {
  String get name;
  List<int> compress(List<int> data, {int level});
  List<int> decompress(List<int> compressed);
  double estimateRatio(List<int> sample);
}
```

#### 13.2 Codec Implementations
**Files:**
- `lib/src/compression/gzip_codec.dart`
- `lib/src/compression/zstd_codec.dart`
- `lib/src/compression/lz4_codec.dart`
- `lib/src/compression/snappy_codec.dart`

#### 13.3 Adaptive Compression
**File:** `lib/src/compression/adaptive.dart`

- Auto-select best codec
- Balance speed vs ratio
- Sample-based testing

### Week 14: Memory Management

#### 14.1 Chunk Manager
**File:** `lib/src/storage/chunk_manager.dart`

```dart
class ChunkManager {
  Future<Chunk> getChunk(List<int> indices);
  void evictChunk(List<int> chunkIndex);
  Future<void> prefetch(List<List<int>> chunkIndices);
  void clearCache();
  int get cacheSize;
  int get memoryUsage;
}
```

#### 14.2 Memory Monitor
**File:** `lib/src/core/memory_monitor.dart`

- Track memory usage
- Automatic cleanup
- Memory pressure handling

### Week 15: Performance Optimization

#### 15.1 Lazy Evaluation Engine
**File:** `lib/src/ndarray/lazy_eval.dart`

- Deferred computation
- Operation fusion
- Automatic optimization

#### 15.2 Parallel Execution
**File:** `lib/src/ndarray/parallel_executor.dart`

- Isolate pool
- Work stealing
- Load balancing

---

## Phase 6: Advanced Features (Weeks 16-18)

### Week 16: Query System

#### 16.1 Query Language
**File:** `lib/src/query/query_parser.dart`

```dart
// SQL-like queries on NDArray
var result = cube.query('''
  SELECT * FROM data
  WHERE temperature > 20 AND humidity < 80
  ORDER BY timestamp
  LIMIT 100
''');
```

#### 16.2 Query Optimizer
**File:** `lib/src/query/optimizer.dart`

- Query planning
- Index usage
- Chunk-aware execution

### Week 17: Transactions & Versioning

#### 17.1 Transaction Support
**File:** `lib/src/io/dcf/transaction.dart`

```dart
await file.transaction((txn) async {
  await txn.writeDataset('/data1', array1);
  await txn.writeDataset('/data2', array2);
  // Atomic commit
});
```

#### 17.2 Versioning System
**File:** `lib/src/io/dcf/versioning.dart`

```dart
await file.createSnapshot('v1.0');
var oldData = await file.readSnapshot('v1.0', '/data');
```

### Week 18: Integration & Polish

#### 18.1 Series/DataFrame Enhancement
**Files:**
- `lib/src/series/series_extensions.dart`
- `lib/src/data_frame/dataframe_extensions.dart`

- Implement DartData interface
- Add conversion methods
- Ensure API consistency

#### 18.2 Documentation
**Files:**
- `doc/ndarray.md`
- `doc/datacube.md`
- `doc/interoperability.md`
- `doc/performance.md`

---

## Interoperability Guide

### Python Integration

#### Writing from Dart, Reading in Python:
```dart
// Dart
await cube.toHDF5('data.h5', dataset: '/measurements');
```

```python
# Python
import h5py
import numpy as np

with h5py.File('data.h5', 'r') as f:
    data = f['/measurements'][:]  # 3D numpy array
    attrs = dict(f['/measurements'].attrs)
```

#### Writing from Python, Reading in Dart:
```python
# Python
import h5py
import numpy as np

data = np.random.rand(10, 50, 20)
with h5py.File('data.h5', 'w') as f:
    ds = f.create_dataset('/measurements', data=data)
    ds.attrs['units'] = 'celsius'
```

```dart
// Dart
var cube = await DataCube.fromHDF5('data.h5', dataset: '/measurements');
print(cube.attrs['units']);  // 'celsius'
```

### MATLAB Integration

#### Writing from Dart, Reading in MATLAB:
```dart
// Dart
await cube.toHDF5('data.h5', dataset: '/measurements');
```

```matlab
% MATLAB
data = h5read('data.h5', '/measurements');
info = h5info('data.h5', '/measurements');
units = h5readatt('data.h5', '/measurements', 'units');
```

#### Writing from MATLAB, Reading in Dart:
```matlab
% MATLAB
data = rand(10, 50, 20);
h5create('data.h5', '/measurements', size(data));
h5write('data.h5', '/measurements', data);
h5writeatt('data.h5', '/measurements', 'units', 'celsius');
```

```dart
// Dart
var cube = await DataCube.fromHDF5('data.h5', dataset: '/measurements');
```

---

## Testing Strategy

### Unit Tests (Each Phase)
- Core functionality
- Edge cases
- Error handling

### Integration Tests
- Cross-format compatibility
- Python interop tests
- MATLAB interop tests

### Performance Tests
- Large dataset handling
- Memory usage
- Compression ratios
- Query performance

### Interoperability Tests
- Write in Dart, read in Python
- Write in Python, read in Dart
- Write in MATLAB, read in Dart
- Round-trip tests

---

## File Structure

```
lib/
├── src/
│   ├── core/
│   │   ├── shape.dart
│   │   ├── dart_data.dart
│   │   ├── scalar.dart
│   │   ├── slice_spec.dart
│   │   ├── index.dart
│   │   ├── attributes.dart
│   │   └── config.dart
│   ├── storage/
│   │   ├── storage_backend.dart
│   │   ├── inmemory_backend.dart
│   │   ├── chunked_backend.dart
│   │   ├── file_backend.dart
│   │   ├── chunk_manager.dart
│   │   └── memory_monitor.dart
│   ├── ndarray/
│   │   ├── ndarray.dart
│   │   ├── smart_slicer.dart
│   │   ├── operations.dart
│   │   ├── streaming.dart
│   │   ├── parallel.dart
│   │   └── lazy_eval.dart
│   ├── datacube/
│   │   ├── datacube.dart
│   │   ├── dataframe_integration.dart
│   │   ├── aggregations.dart
│   │   ├── transformations.dart
│   │   └── io.dart
│   ├── compression/
│   │   ├── codec.dart
│   │   ├── gzip_codec.dart
│   │   ├── zstd_codec.dart
│   │   ├── lz4_codec.dart
│   │   └── adaptive.dart
│   ├── io/
│   │   ├── hdf5/
│   │   │   ├── hdf5_writer.dart
│   │   │   └── hdf5_reader.dart
│   │   ├── dcf/
│   │   │   ├── format_spec.dart
│   │   │   ├── dcf_writer.dart
│   │   │   ├── dcf_reader.dart
│   │   │   ├── transaction.dart
│   │   │   └── versioning.dart
│   │   └── converters/
│   │       ├── export.dart
│   │       └── import.dart
│   └── query/
│       ├── query_parser.dart
│       └── optimizer.dart
├── series/
│   └── series_extensions.dart
└── data_frame/
    └── dataframe_extensions.dart

test/
├── core/
├── storage/
├── ndarray/
├── datacube/
├── compression/
├── io/
├── interop/
│   ├── python_interop_test.dart
│   └── matlab_interop_test.dart
└── performance/

doc/
├── ndarray.md
├── datacube.md
├── interoperability.md
├── performance.md
└── api_reference.md

example/
├── basic_ndarray.dart
├── datacube_operations.dart
├── hdf5_interop.dart
├── python_workflow.dart
├── matlab_workflow.dart
└── large_dataset.dart
```

---

## Dependencies

### Required Packages
```yaml
dependencies:
  # Existing
  intl: ^0.18.0
  
  # New for NDArray
  archive: ^3.4.0  # Compression
  ffi: ^2.1.0  # Memory-mapped files
  
  # HDF5 (existing)
  # Your current HDF5 implementation
  
dev_dependencies:
  test: ^1.24.0
  benchmark_harness: ^2.2.0
```

### Optional Packages (for advanced features)
```yaml
  # For better compression
  zstd: ^1.0.0  # If available
  lz4: ^1.0.0   # If available
  
  # For parallel processing
  isolate: ^2.1.0
```

---

## Success Criteria

### Phase 1-3 (Core)
- [ ] NDArray supports N dimensions
- [ ] Smart slicing returns correct types
- [ ] DataCube works as stack of DataFrames
- [ ] Lazy evaluation by default
- [ ] Memory usage < 2x data size

### Phase 4 (Formats)
- [ ] HDF5 read/write works
- [ ] Python can read Dart-written HDF5
- [ ] MATLAB can read Dart-written HDF5
- [ ] Dart can read Python-written HDF5
- [ ] .dcf format functional

### Phase 5 (Optimization)
- [ ] Compression reduces file size by 50%+
- [ ] Chunked processing handles 10GB+ datasets
- [ ] Parallel operations use all CPU cores
- [ ] Memory usage stays within limits

### Phase 6 (Advanced)
- [ ] Query system works
- [ ] Transactions are atomic
- [ ] Versioning preserves history
- [ ] Documentation complete

---

## Risk Mitigation

### Risk 1: HDF5 Compatibility Issues
**Mitigation:** 
- Test with real Python/MATLAB workflows early
- Follow HDF5 specification strictly
- Create comprehensive interop tests

### Risk 2: Memory Management
**Mitigation:**
- Implement memory monitoring early
- Test with large datasets frequently
- Add memory pressure handling

### Risk 3: Performance
**Mitigation:**
- Benchmark each phase
- Profile memory and CPU usage
- Optimize hot paths

### Risk 4: API Complexity
**Mitigation:**
- Keep API consistent with DataFrame/Series
- Provide clear examples
- Document common patterns

---

## Next Steps

1. **Review this plan** - Confirm approach
2. **Set up project structure** - Create directories
3. **Start Phase 1, Week 1** - Enhanced Shape class
4. **Create test framework** - Interop test harness
5. **Begin implementation** - Core foundation

Ready to start implementation?
