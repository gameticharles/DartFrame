# DataCube Project Structure & Setup Guide

## Directory Structure

```
dartframe/
├── lib/
│   ├── dartframe.dart                    # Main export file
│   └── src/
│       ├── core/                         # Core abstractions (EXISTING + NEW)
│       │   ├── dtype.dart                # EXISTING - Data types
│       │   ├── dtype_integration.dart    # EXISTING - Type integration
│       │   ├── dart_data.dart            # NEW - Base interface for all dimensional types
│       │   ├── shape.dart                # NEW - Enhanced Shape class with N-D support
│       │   ├── scalar.dart               # NEW - 0D type
│       │   ├── slice_spec.dart           # NEW - Slicing system
│       │   ├── attributes.dart           # NEW - HDF5-style metadata
│       │   └── ndarray_config.dart       # NEW - NDArray/DataCube configuration
│       │
│       ├── index/                        # Index classes (EXISTING)
│       │   ├── datetime_index.dart       # EXISTING
│       │   ├── multi_index.dart          # EXISTING
│       │   └── axis_index.dart           # NEW - For NDArray axis labels
│       │
│       ├── storage/                      # NEW - Storage backends for NDArray/DataCube
│       │   ├── storage_backend.dart      # Abstract backend interface
│       │   ├── inmemory_backend.dart     # In-memory storage
│       │   ├── chunked_backend.dart      # Chunked storage with LRU cache
│       │   ├── file_backend.dart         # File-backed lazy loading
│       │   ├── chunk_manager.dart        # Chunk cache manager
│       │   └── memory_monitor.dart       # Memory usage tracking
│       │
│       ├── ndarray/                      # NEW - N-dimensional array
│       │   ├── ndarray.dart              # Main NDArray class
│       │   ├── smart_slicer.dart         # Smart slicing (returns appropriate type)
│       │   ├── operations.dart           # Element-wise operations
│       │   ├── aggregations.dart         # Reduce operations (sum, mean, etc.)
│       │   ├── broadcasting.dart         # Broadcasting logic
│       │   ├── streaming.dart            # Stream operations for large data
│       │   ├── parallel.dart             # Parallel processing with isolates
│       │   └── lazy_eval.dart            # Lazy evaluation engine
│       │
│       ├── datacube/                     # NEW - 3D specialization
│       │   ├── datacube.dart             # Main DataCube class (stack of DataFrames)
│       │   ├── dataframe_integration.dart # DataFrame interop
│       │   ├── aggregations.dart         # 3D aggregations
│       │   ├── transformations.dart      # Reshape, transpose, permute
│       │   └── io.dart                   # Basic I/O operations
│       │
│       ├── compression/                  # NEW - Compression codecs
│       │   ├── codec.dart                # Codec interface
│       │   ├── gzip_codec.dart           # Gzip implementation
│       │   ├── zstd_codec.dart           # Zstd (modern, fast)
│       │   ├── lz4_codec.dart            # LZ4 (very fast)
│       │   ├── snappy_codec.dart         # Snappy
│       │   └── adaptive.dart             # Auto-select best codec
│       │
│       ├── io/                           # File I/O (EXISTING + NEW)
│       │   ├── readers.dart              # EXISTING - Reader registry
│       │   ├── writers.dart              # EXISTING - Writer registry
│       │   ├── csv_reader.dart           # EXISTING
│       │   ├── csv_writer.dart           # EXISTING
│       │   ├── json_reader.dart          # EXISTING
│       │   ├── json_writer.dart          # EXISTING
│       │   ├── excel_reader.dart         # EXISTING
│       │   ├── excel_writer.dart         # EXISTING
│       │   ├── parquet_reader.dart       # EXISTING
│       │   ├── parquet_writer.dart       # EXISTING
│       │   ├── hdf5_reader.dart          # EXISTING - Enhance for NDArray
│       │   ├── smart_loader.dart         # EXISTING
│       │   ├── data_source.dart          # EXISTING
│       │   ├── file_source.dart          # EXISTING
│       │   ├── http_source.dart          # EXISTING
│       │   ├── database.dart             # EXISTING
│       │   ├── scientific_datasets.dart  # EXISTING
│       │   ├── chunked_reader.dart       # EXISTING
│       │   │
│       │   ├── hdf5/                     # NEW - Enhanced HDF5 support
│       │   │   ├── hdf5_writer.dart      # NEW - Write NDArray/DataCube to HDF5
│       │   │   ├── hdf5_ndarray_reader.dart # NEW - Read N-D from HDF5
│       │   │   └── hdf5_utils.dart       # NEW - HDF5 utilities
│       │   │
│       │   ├── dcf/                      # NEW - DartCube Format (.dcf)
│       │   │   ├── format_spec.dart      # Format specification
│       │   │   ├── dcf_file.dart         # File handle
│       │   │   ├── dcf_writer.dart       # Write .dcf files
│       │   │   ├── dcf_reader.dart       # Read .dcf files
│       │   │   ├── group.dart            # Hierarchical groups
│       │   │   ├── transaction.dart      # Transaction support
│       │   │   └── versioning.dart       # Snapshot/versioning system
│       │   │
│       │   └── converters/               # NEW - Format conversion utilities
│       │       ├── ndarray_export.dart   # Export NDArray to various formats
│       │       ├── ndarray_import.dart   # Import from various formats
│       │       ├── mat_converter.dart    # MATLAB .mat file support
│       │       └── netcdf_converter.dart # NetCDF support
│       │
│       ├── query/                        # NEW - Query system (Phase 6)
│       │   ├── query_parser.dart         # SQL-like query parser
│       │   ├── query_executor.dart       # Execute queries on NDArray
│       │   └── optimizer.dart            # Query optimization
│       │
│       ├── series/                       # Series (EXISTING + MINIMAL ENHANCEMENT)
│       │   ├── series.dart               # EXISTING - Main Series class
│       │   ├── functions.dart            # EXISTING
│       │   ├── operations.dart           # EXISTING
│       │   ├── statistics.dart           # EXISTING
│       │   ├── additional_functions.dart # EXISTING
│       │   ├── categorical.dart          # EXISTING
│       │   ├── date_time_accessor.dart   # EXISTING
│       │   ├── string_accessor.dart      # EXISTING
│       │   ├── interpolation.dart        # EXISTING
│       │   └── ndarray_integration.dart  # NEW - Minimal DartData interface
│       │
│       ├── data_frame/                   # DataFrame (EXISTING + MINIMAL ENHANCEMENT)
│       │   ├── data_frame.dart           # EXISTING - Main DataFrame class
│       │   ├── functions.dart            # EXISTING
│       │   ├── operations.dart           # EXISTING
│       │   ├── statistics.dart           # EXISTING
│       │   ├── accessors.dart            # EXISTING
│       │   ├── advanced_slicing.dart     # EXISTING
│       │   ├── duplicate_functions.dart  # EXISTING
│       │   ├── export_formats.dart       # EXISTING
│       │   ├── expression_evaluation.dart # EXISTING
│       │   ├── functional_programming.dart # EXISTING
│       │   ├── groupby.dart              # EXISTING
│       │   ├── multi_index_integration.dart # EXISTING
│       │   ├── resampling.dart           # EXISTING
│       │   ├── reshaping.dart            # EXISTING
│       │   ├── sampling_enhanced.dart    # EXISTING
│       │   ├── smart_loader.dart         # EXISTING
│       │   ├── time_series.dart          # EXISTING
│       │   ├── timezone_operations.dart  # EXISTING
│       │   ├── web_api.dart              # EXISTING
│       │   ├── window_functions.dart     # EXISTING
│       │   └── ndarray_integration.dart  # NEW - Minimal DartData interface
│       │
│       ├── file_helper/                  # EXISTING - Keep as-is
│       │   ├── file_io.dart              # EXISTING
│       │   ├── file_io_other.dart        # EXISTING
│       │   ├── file_io_web.dart          # EXISTING
│       │   └── file_io_stub.dart         # EXISTING
│       │
│       └── utils/                        # EXISTING - Keep as-is
│           ├── utils.dart                # EXISTING
│           ├── lists.dart                # EXISTING
│           ├── memory.dart               # EXISTING
│           ├── performance.dart          # EXISTING
│           ├── performance_native.dart   # EXISTING
│           ├── performance_web.dart      # EXISTING
│           ├── performance_stub.dart     # EXISTING
│           └── time_series.dart          # EXISTING
│
├── test/
│   ├── core/
│   │   ├── shape_test.dart
│   │   ├── slice_spec_test.dart
│   │   ├── attributes_test.dart
│   │   └── index_test.dart
│   │
│   ├── storage/
│   │   ├── inmemory_backend_test.dart
│   │   ├── chunked_backend_test.dart
│   │   └── chunk_manager_test.dart
│   │
│   ├── ndarray/
│   │   ├── ndarray_test.dart
│   │   ├── slicing_test.dart
│   │   ├── operations_test.dart
│   │   ├── aggregations_test.dart
│   │   └── streaming_test.dart
│   │
│   ├── datacube/
│   │   ├── datacube_test.dart
│   │   ├── dataframe_integration_test.dart
│   │   └── aggregations_test.dart
│   │
│   ├── compression/
│   │   ├── gzip_codec_test.dart
│   │   └── adaptive_test.dart
│   │
│   ├── io/
│   │   ├── hdf5_test.dart
│   │   ├── dcf_test.dart
│   │   └── converters_test.dart
│   │
│   ├── interop/
│   │   ├── python_interop_test.dart      # Python compatibility
│   │   ├── matlab_interop_test.dart      # MATLAB compatibility
│   │   └── roundtrip_test.dart           # Round-trip tests
│   │
│   └── performance/
│       ├── memory_test.dart
│       ├── speed_benchmark.dart
│       └── compression_benchmark.dart
│
├── example/
│   ├── basic_ndarray.dart                # Basic NDArray usage
│   ├── datacube_operations.dart          # DataCube examples
│   ├── slicing_examples.dart             # Slicing patterns
│   ├── lazy_evaluation.dart              # Lazy ops
│   ├── chunked_processing.dart           # Large datasets
│   ├── hdf5_interop.dart                 # HDF5 I/O
│   ├── python_workflow.dart              # Python integration
│   ├── matlab_workflow.dart              # MATLAB integration
│   ├── compression_demo.dart             # Compression
│   └── large_dataset_demo.dart           # Big data example
│
├── doc/
│   ├── ndarray.md                        # NDArray guide
│   ├── datacube.md                       # DataCube guide
│   ├── slicing.md                        # Slicing reference
│   ├── storage_backends.md               # Backend guide
│   ├── compression.md                    # Compression guide
│   ├── interoperability.md               # Python/MATLAB guide
│   ├── performance.md                    # Performance tips
│   ├── dcf_format.md                     # .dcf specification
│   └── api_reference.md                  # Complete API
│
├── scripts/
│   ├── generate_test_data.py             # Python test data
│   ├── generate_test_data.m              # MATLAB test data
│   └── benchmark.dart                    # Benchmarking script
│
├── pubspec.yaml
├── DATACUBE_IMPLEMENTATION_PLAN.md       # This plan
├── DATACUBE_PROJECT_STRUCTURE.md         # This file
├── MULTIDIMENSIONAL_ANALYSIS.md          # Analysis doc
├── CHANGELOG.md
└── README.md
```

---

## Phase 1 Implementation Checklist

### Week 1: Shape & Core Types

#### Day 1-2: Enhanced Shape Class
- [ ] Create `lib/src/core/shape.dart`
- [ ] Implement strides calculation
- [ ] Add `toFlatIndex()` method
- [ ] Add `fromFlatIndex()` method
- [ ] Implement broadcasting logic
- [ ] Write tests: `test/core/shape_test.dart`

#### Day 3-4: Base Type Hierarchy
- [ ] Create `lib/src/core/dart_data.dart`
- [ ] Define abstract interface
- [ ] Create `lib/src/core/scalar.dart`
- [ ] Implement Scalar class
- [ ] Write tests: `test/core/scalar_test.dart`

#### Day 5: Slice Specification
- [ ] Create `lib/src/core/slice_spec.dart`
- [ ] Implement SliceSpec class
- [ ] Implement Slice helper class
- [ ] Add resolve() method
- [ ] Write tests: `test/core/slice_spec_test.dart`

### Week 2: Storage Backends

#### Day 1-2: Backend Interface
- [ ] Create `lib/src/storage/storage_backend.dart`
- [ ] Define abstract interface
- [ ] Document backend contract

#### Day 3-4: InMemory Backend
- [ ] Create `lib/src/storage/inmemory_backend.dart`
- [ ] Implement flat array storage
- [ ] Implement getValue/setValue
- [ ] Implement slicing
- [ ] Write tests: `test/storage/inmemory_backend_test.dart`

#### Day 5: Chunked Backend (Basic)
- [ ] Create `lib/src/storage/chunked_backend.dart`
- [ ] Implement chunk calculation
- [ ] Implement basic caching
- [ ] Write tests: `test/storage/chunked_backend_test.dart`

### Week 3: Attributes & Config

#### Day 1-2: Attributes System
- [ ] Create `lib/src/core/attributes.dart`
- [ ] Implement get/set operators
- [ ] Add JSON serialization
- [ ] Add common metadata properties
- [ ] Write tests: `test/core/attributes_test.dart`

#### Day 3: Index Class
- [ ] Create `lib/src/core/index.dart`
- [ ] Implement label storage
- [ ] Add position/label lookup
- [ ] Write tests: `test/core/index_test.dart`

#### Day 4-5: Configuration
- [ ] Create `lib/src/core/config.dart`
- [ ] Define global settings
- [ ] Add backend auto-selection logic
- [ ] Document configuration options

---

## Initial Setup Steps

### 1. Create Directory Structure
```bash
# NEW directories only (existing ones already present)

# Core - add new files to existing directory
# lib/src/core already exists

# Index - add new file to existing directory  
# lib/src/index already exists

# Storage - NEW directory
mkdir -p lib/src/storage

# NDArray - NEW directory
mkdir -p lib/src/ndarray

# DataCube - NEW directory
mkdir -p lib/src/datacube

# Compression - NEW directory
mkdir -p lib/src/compression

# I/O subdirectories - NEW (lib/src/io already exists)
mkdir -p lib/src/io/hdf5
mkdir -p lib/src/io/dcf
mkdir -p lib/src/io/converters

# Query - NEW directory
mkdir -p lib/src/query

# Test directories - NEW
mkdir -p test/core
mkdir -p test/storage
mkdir -p test/ndarray
mkdir -p test/datacube
mkdir -p test/compression
mkdir -p test/io/hdf5
mkdir -p test/io/dcf
mkdir -p test/interop
mkdir -p test/performance

# Documentation - may already exist
mkdir -p doc

# Examples - may already exist
mkdir -p example

# Scripts - NEW
mkdir -p scripts
```

### 2. Update pubspec.yaml
```yaml
name: dartframe
description: A powerful data manipulation library with N-dimensional support
version: 2.0.0
homepage: https://github.com/yourusername/dartframe

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  intl: ^0.18.0
  archive: ^3.4.0  # For compression
  ffi: ^2.1.0      # For memory-mapped files

dev_dependencies:
  test: ^1.24.0
  benchmark_harness: ^2.2.0
  lints: ^2.1.0

# Optional dependencies (add as needed)
# dependency_overrides:
#   zstd: ^1.0.0
#   lz4: ^1.0.0
```

### 3. Update Main Export File
```dart
// lib/dartframe.dart

library dartframe;

// Existing exports
export 'src/series/series.dart';
export 'src/data_frame/data_frame.dart';
export 'src/index/index.dart';

// New exports (Phase 1)
export 'src/core/dart_data.dart';
export 'src/core/shape.dart';
export 'src/core/scalar.dart';
export 'src/core/slice_spec.dart';
export 'src/core/index.dart';
export 'src/core/attributes.dart';
export 'src/core/config.dart';

// Storage backends (Phase 2)
export 'src/storage/storage_backend.dart';
export 'src/storage/inmemory_backend.dart';
export 'src/storage/chunked_backend.dart';

// NDArray (Phase 2-3)
export 'src/ndarray/ndarray.dart';

// DataCube (Phase 3)
export 'src/datacube/datacube.dart';

// I/O (Phase 4)
export 'src/io/hdf5/hdf5_writer.dart';
export 'src/io/hdf5/hdf5_reader.dart';
export 'src/io/dcf/dcf_file.dart';

// Compression (Phase 5)
export 'src/compression/codec.dart';
```

### 4. Create Test Helper
```dart
// test/test_helpers.dart

import 'package:dartframe/dartframe.dart';

/// Create test NDArray
NDArray createTestArray(List<int> shape) {
  int size = shape.reduce((a, b) => a * b);
  List<dynamic> data = List.generate(size, (i) => i);
  return NDArray(data, shape);
}

/// Create test DataCube
DataCube createTestCube(int depth, int rows, int cols) {
  List<DataFrame> frames = [];
  for (int d = 0; d < depth; d++) {
    List<List<dynamic>> data = [];
    for (int r = 0; r < rows; r++) {
      data.add(List.generate(cols, (c) => d * rows * cols + r * cols + c));
    }
    frames.add(DataFrame(data));
  }
  return DataCube.fromDataFrames(frames);
}

/// Compare arrays with tolerance
bool arraysEqual(List<dynamic> a, List<dynamic> b, {double tolerance = 1e-10}) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] is num && b[i] is num) {
      if ((a[i] - b[i]).abs() > tolerance) return false;
    } else if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
```

### 5. Create Interop Test Scripts

#### Python Test Script
```python
# scripts/generate_test_data.py

import h5py
import numpy as np

def create_test_hdf5():
    """Create HDF5 test file for Dart interop testing"""
    
    # 3D array
    data_3d = np.random.rand(10, 50, 20)
    
    with h5py.File('test_data/python_test.h5', 'w') as f:
        # Create dataset
        ds = f.create_dataset('/measurements', data=data_3d)
        
        # Add attributes
        ds.attrs['units'] = 'celsius'
        ds.attrs['description'] = 'Temperature measurements'
        ds.attrs['created'] = '2024-01-01'
        
        # Create group
        grp = f.create_group('/metadata')
        grp.attrs['source'] = 'Python test script'

if __name__ == '__main__':
    create_test_hdf5()
    print("Created test_data/python_test.h5")
```

#### MATLAB Test Script
```matlab
% scripts/generate_test_data.m

function generate_test_data()
    % Create HDF5 test file for Dart interop testing
    
    % 3D array
    data_3d = rand(10, 50, 20);
    
    % Create file
    filename = 'test_data/matlab_test.h5';
    
    % Write dataset
    h5create(filename, '/measurements', size(data_3d));
    h5write(filename, '/measurements', data_3d);
    
    % Write attributes
    h5writeatt(filename, '/measurements', 'units', 'celsius');
    h5writeatt(filename, '/measurements', 'description', 'Temperature measurements');
    h5writeatt(filename, '/measurements', 'created', '2024-01-01');
    
    fprintf('Created test_data/matlab_test.h5\n');
end
```

### 6. Create Initial Documentation

#### README.md Update
```markdown
# DartFrame 2.0 - N-Dimensional Data Structures

## New Features

### NDArray - N-Dimensional Arrays
```dart
// Create 3D array
var array = NDArray([...], [10, 20, 30]);

// Smart slicing
var slice2d = array[5, :, :];  // Returns DataFrame
var slice1d = array[5, 10, :]; // Returns Series
var scalar = array[5, 10, 15]; // Returns value
```

### DataCube - 3D Data Structure
```dart
// Stack DataFrames
var cube = DataCube.fromDataFrames([df1, df2, df3]);

// Access sheets
var sheet = cube[0];  // Returns DataFrame

// Aggregate
var summary = cube.aggregateDepth('mean');
```

### Interoperability
```dart
// Write for Python/MATLAB
await cube.toHDF5('data.h5');

// Read from Python/MATLAB
var cube = await DataCube.fromHDF5('data.h5');
```

## Installation

```yaml
dependencies:
  dartframe: ^2.0.0
```

## Documentation

- [NDArray Guide](doc/ndarray.md)
- [DataCube Guide](doc/datacube.md)
- [Interoperability](doc/interoperability.md)
- [Performance Tips](doc/performance.md)
```

---

## Development Workflow

### Daily Workflow
1. **Morning:** Review previous day's work
2. **Implementation:** Write code following plan
3. **Testing:** Write tests alongside code
4. **Documentation:** Update docs for new features
5. **Evening:** Commit with clear messages

### Git Commit Messages
```
Phase 1: Implement enhanced Shape class with strides
Phase 1: Add SliceSpec for smart slicing
Phase 2: Implement InMemory storage backend
Phase 3: Add DataCube with DataFrame integration
Phase 4: Add HDF5 writer for Python/MATLAB interop
```

### Testing Strategy
- Write tests before or alongside implementation
- Test edge cases
- Test interoperability early and often
- Run performance tests weekly

### Code Review Checklist
- [ ] Follows existing code style
- [ ] Has comprehensive tests
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Performance acceptable
- [ ] Memory usage reasonable

---

## Success Metrics

### Phase 1 (Weeks 1-3)
- [ ] All core classes implemented
- [ ] 90%+ test coverage
- [ ] Documentation complete
- [ ] No memory leaks

### Phase 2 (Weeks 4-6)
- [ ] NDArray fully functional
- [ ] Lazy evaluation working
- [ ] Handles 1GB+ datasets
- [ ] Performance benchmarks established

### Phase 3 (Weeks 7-9)
- [ ] DataCube operational
- [ ] DataFrame integration seamless
- [ ] Streaming works for large data
- [ ] Examples complete

### Phase 4 (Weeks 10-12)
- [ ] HDF5 read/write works
- [ ] Python interop verified
- [ ] MATLAB interop verified
- [ ] .dcf format functional

---

## Next Actions

1. **Create directory structure** (30 minutes)
2. **Update pubspec.yaml** (10 minutes)
3. **Create test helpers** (30 minutes)
4. **Start Phase 1, Week 1, Day 1** - Enhanced Shape class
5. **Set up CI/CD** for automated testing

Ready to begin implementation?
