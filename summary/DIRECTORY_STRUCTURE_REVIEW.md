# Directory Structure Review & Approval

## ✅ Structure Approved with Modifications

The directory structure has been reviewed and updated to integrate seamlessly with the existing DartFrame codebase.

---

## Key Changes Made

### 1. **Preserved Existing Structure**
All existing directories and files are kept intact:
- ✅ `lib/src/core/` - Enhanced with new files
- ✅ `lib/src/index/` - Enhanced with axis_index.dart
- ✅ `lib/src/series/` - Minimal enhancement only
- ✅ `lib/src/data_frame/` - Minimal enhancement only
- ✅ `lib/src/io/` - Enhanced with subdirectories
- ✅ `lib/src/file_helper/` - No changes
- ✅ `lib/src/utils/` - No changes

### 2. **New Directories Added**
- 🆕 `lib/src/storage/` - Storage backends for NDArray/DataCube
- 🆕 `lib/src/ndarray/` - N-dimensional array implementation
- 🆕 `lib/src/datacube/` - 3D specialization
- 🆕 `lib/src/compression/` - Compression codecs
- 🆕 `lib/src/io/hdf5/` - Enhanced HDF5 support
- 🆕 `lib/src/io/dcf/` - Native .dcf format
- 🆕 `lib/src/io/converters/` - Format conversion utilities
- 🆕 `lib/src/query/` - Query system (Phase 6)

### 3. **Minimal Enhancements to Existing**
Only ONE new file added to each existing directory:
- `lib/src/series/ndarray_integration.dart` - DartData interface
- `lib/src/data_frame/ndarray_integration.dart` - DartData interface
- `lib/src/index/axis_index.dart` - For NDArray axis labels

---

## Directory Organization

### Core Abstractions (`lib/src/core/`)
```
EXISTING:
├── dtype.dart
└── dtype_integration.dart

NEW:
├── dart_data.dart          # Base interface
├── shape.dart              # Enhanced Shape class
├── scalar.dart             # 0D type
├── slice_spec.dart         # Slicing system
├── attributes.dart         # Metadata
└── ndarray_config.dart     # Configuration
```

### Index Classes (`lib/src/index/`)
```
EXISTING:
├── datetime_index.dart
└── multi_index.dart

NEW:
└── axis_index.dart         # For NDArray axis labels
```

### Storage Backends (`lib/src/storage/`) - NEW
```
├── storage_backend.dart    # Abstract interface
├── inmemory_backend.dart   # In-memory
├── chunked_backend.dart    # Chunked with cache
├── file_backend.dart       # File-backed lazy
├── chunk_manager.dart      # Cache manager
└── memory_monitor.dart     # Memory tracking
```

### NDArray (`lib/src/ndarray/`) - NEW
```
├── ndarray.dart            # Main class
├── smart_slicer.dart       # Smart slicing
├── operations.dart         # Element-wise ops
├── aggregations.dart       # Reduce ops
├── broadcasting.dart       # Broadcasting
├── streaming.dart          # Stream ops
├── parallel.dart           # Parallel processing
└── lazy_eval.dart          # Lazy evaluation
```

### DataCube (`lib/src/datacube/`) - NEW
```
├── datacube.dart           # Main class
├── dataframe_integration.dart # DataFrame interop
├── aggregations.dart       # 3D aggregations
├── transformations.dart    # Reshape, transpose
└── io.dart                 # Basic I/O
```

### Compression (`lib/src/compression/`) - NEW
```
├── codec.dart              # Interface
├── gzip_codec.dart         # Gzip
├── zstd_codec.dart         # Zstd
├── lz4_codec.dart          # LZ4
├── snappy_codec.dart       # Snappy
└── adaptive.dart           # Auto-select
```

### I/O (`lib/src/io/`)
```
EXISTING (keep as-is):
├── readers.dart
├── writers.dart
├── csv_reader.dart
├── csv_writer.dart
├── json_reader.dart
├── json_writer.dart
├── excel_reader.dart
├── excel_writer.dart
├── parquet_reader.dart
├── parquet_writer.dart
├── hdf5_reader.dart        # Will enhance
├── smart_loader.dart
├── data_source.dart
├── file_source.dart
├── http_source.dart
├── database.dart
├── scientific_datasets.dart
└── chunked_reader.dart

NEW subdirectories:
├── hdf5/
│   ├── hdf5_writer.dart
│   ├── hdf5_ndarray_reader.dart
│   └── hdf5_utils.dart
├── dcf/
│   ├── format_spec.dart
│   ├── dcf_file.dart
│   ├── dcf_writer.dart
│   ├── dcf_reader.dart
│   ├── group.dart
│   ├── transaction.dart
│   └── versioning.dart
└── converters/
    ├── ndarray_export.dart
    ├── ndarray_import.dart
    ├── mat_converter.dart
    └── netcdf_converter.dart
```

### Series (`lib/src/series/`)
```
EXISTING (keep as-is):
├── series.dart
├── functions.dart
├── operations.dart
├── statistics.dart
├── additional_functions.dart
├── categorical.dart
├── date_time_accessor.dart
├── string_accessor.dart
└── interpolation.dart

NEW (minimal):
└── ndarray_integration.dart  # DartData interface only
```

### DataFrame (`lib/src/data_frame/`)
```
EXISTING (keep as-is):
├── data_frame.dart
├── functions.dart
├── operations.dart
├── statistics.dart
├── accessors.dart
├── advanced_slicing.dart
├── duplicate_functions.dart
├── export_formats.dart
├── expression_evaluation.dart
├── functional_programming.dart
├── groupby.dart
├── multi_index_integration.dart
├── resampling.dart
├── reshaping.dart
├── sampling_enhanced.dart
├── smart_loader.dart
├── time_series.dart
├── timezone_operations.dart
├── web_api.dart
└── window_functions.dart

NEW (minimal):
└── ndarray_integration.dart  # DartData interface only
```

---

## Test Structure

```
test/
├── core/                   # NEW - Core tests
│   ├── shape_test.dart
│   ├── slice_spec_test.dart
│   ├── attributes_test.dart
│   └── scalar_test.dart
│
├── storage/                # NEW - Storage backend tests
│   ├── inmemory_backend_test.dart
│   ├── chunked_backend_test.dart
│   └── chunk_manager_test.dart
│
├── ndarray/                # NEW - NDArray tests
│   ├── ndarray_test.dart
│   ├── slicing_test.dart
│   ├── operations_test.dart
│   ├── aggregations_test.dart
│   └── streaming_test.dart
│
├── datacube/               # NEW - DataCube tests
│   ├── datacube_test.dart
│   ├── dataframe_integration_test.dart
│   └── aggregations_test.dart
│
├── compression/            # NEW - Compression tests
│   ├── gzip_codec_test.dart
│   └── adaptive_test.dart
│
├── io/                     # NEW - I/O tests
│   ├── hdf5/
│   │   ├── hdf5_writer_test.dart
│   │   └── hdf5_reader_test.dart
│   ├── dcf/
│   │   ├── dcf_writer_test.dart
│   │   └── dcf_reader_test.dart
│   └── converters_test.dart
│
├── interop/                # NEW - Interoperability tests
│   ├── python_interop_test.dart
│   ├── matlab_interop_test.dart
│   └── roundtrip_test.dart
│
└── performance/            # NEW - Performance tests
    ├── memory_test.dart
    ├── speed_benchmark.dart
    └── compression_benchmark.dart
```

---

## Integration Points

### 1. **Core Integration**
- New `Shape` class enhances existing dtype system
- `dart_data.dart` provides common interface
- Existing `dtype.dart` and `dtype_integration.dart` remain unchanged

### 2. **Index Integration**
- New `axis_index.dart` works alongside existing index classes
- `datetime_index.dart` and `multi_index.dart` unchanged
- Can be used for NDArray axis labels

### 3. **I/O Integration**
- Existing readers/writers remain functional
- New HDF5 subdirectory enhances existing `hdf5_reader.dart`
- New `.dcf` format adds native option
- Converters bridge between formats

### 4. **Series/DataFrame Integration**
- Only ONE new file each: `ndarray_integration.dart`
- Implements `DartData` interface
- Adds conversion methods (`toNDArray()`, `toCube()`)
- All existing functionality preserved

---

## File Count Summary

### New Files to Create
- **Core**: 6 new files
- **Index**: 1 new file
- **Storage**: 6 new files (new directory)
- **NDArray**: 8 new files (new directory)
- **DataCube**: 5 new files (new directory)
- **Compression**: 6 new files (new directory)
- **I/O**: 14 new files (3 subdirectories)
- **Query**: 3 new files (new directory)
- **Series**: 1 new file
- **DataFrame**: 1 new file

**Total: ~51 new files**

### Existing Files
- **Unchanged**: ~40+ existing files
- **Enhanced**: 1 file (`hdf5_reader.dart` - minor enhancement)

---

## Backward Compatibility

✅ **100% Backward Compatible**
- All existing files remain unchanged
- All existing APIs work as before
- New functionality is additive only
- Users can adopt new features gradually

---

## Next Steps

1. ✅ Directory structure approved
2. ⏭️ Create new directories
3. ⏭️ Begin Phase 1 implementation
4. ⏭️ Add files incrementally following the plan

---

## Approval Status

**Status**: ✅ **APPROVED**

The directory structure:
- Integrates seamlessly with existing code
- Preserves all existing functionality
- Adds new features in isolated directories
- Maintains backward compatibility
- Follows existing organizational patterns

**Ready to begin implementation!**
