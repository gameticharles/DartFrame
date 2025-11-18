library;

export 'src/series/series.dart';
export 'src/data_frame/data_frame.dart';
export 'src/file_helper/file_io.dart';
export 'src/io/readers.dart';
export 'src/io/writers.dart';
export 'src/io/database.dart';
export 'src/io/chunked_reader.dart';
export 'src/io/hdf5_reader.dart';
export 'src/io/hdf5_writer.dart';
export 'src/io/json_reader.dart';
export 'src/io/csv_reader.dart';
export 'src/io/excel_reader.dart';

// Smart Loader and Data Sources
export 'src/io/smart_loader.dart';
export 'src/io/data_source.dart';
export 'src/io/file_source.dart';
export 'src/io/http_source.dart';
export 'src/io/scientific_datasets.dart';

// HDF5 Advanced API - for users who need low-level access
export 'src/io/hdf5/hdf5_file.dart';
export 'src/io/hdf5/hdf5_error.dart';
export 'src/io/hdf5/datatype.dart';
export 'src/io/hdf5/datatype_writer.dart';
export 'src/io/hdf5/filter.dart';
export 'src/io/hdf5/storage_layout_writer.dart';
export 'src/io/hdf5/chunked_layout_writer.dart';
export 'src/io/hdf5/dataset.dart';
export 'src/io/hdf5/group.dart';
export 'src/io/hdf5/attribute.dart';
export 'src/io/hdf5/dataspace.dart';
export 'src/io/hdf5/hdf5_writer.dart'
    show
        HDF5WriterUtils,
        HDF5WriteOptions,
        NDArrayHDF5Writer,
        DataCubeHDF5Writer,
        DataFrameHDF5Writer;
export 'src/io/hdf5/hdf5_reader_extensions.dart';
export 'src/io/hdf5/write_options.dart';
export 'src/io/hdf5/heap_manager.dart';
export 'src/io/hdf5/hdf5_file_builder.dart';
export 'src/io/hdf5/dataframe_compound_writer.dart';
export 'src/io/hdf5/dataframe_column_writer.dart';

// HDF5 Internal utilities - for advanced users building tools
export 'src/io/hdf5/byte_reader.dart';
export 'src/io/hdf5/superblock.dart';
export 'src/io/hdf5/object_header.dart';
export 'src/io/hdf5/global_heap.dart';
export 'src/io/hdf5/local_heap.dart';

// DCF (DartCube File) - Native format
export 'src/io/dcf/format_spec.dart';
export 'src/io/dcf/dcf_writer.dart';
export 'src/io/dcf/dcf_reader.dart';

// Format Converters
export 'src/io/converters/format_converter.dart';
export 'src/io/converters/import.dart';

// Compression
export 'src/compression/codec.dart';
export 'src/compression/none_codec.dart';
export 'src/compression/gzip_codec.dart';
export 'src/compression/zlib_codec.dart';
export 'src/compression/registry.dart';
export 'src/compression/adaptive.dart';

export 'src/utils/utils.dart';
export 'src/utils/array_utils.dart';
export 'src/utils/profiler.dart';

// Data type system
export 'src/core/dtype.dart';
export 'src/core/dtype_integration.dart';

// N-dimensional support (Phase 1)
export 'src/core/shape.dart';
export 'src/core/dart_data.dart';
export 'src/core/attributes.dart';
export 'src/core/scalar.dart';
export 'src/core/slice_spec.dart';

// Storage backends (Phase 1 - Week 2)
export 'src/storage/storage_backend.dart';
export 'src/storage/inmemory_backend.dart';
export 'src/storage/chunked_backend.dart';
export 'src/storage/chunk_manager.dart';
export 'src/utils/lists.dart';
export 'src/utils/memory.dart';
export 'src/utils/performance.dart';
export 'src/utils/time_series.dart';
export 'src/utils/benchmark.dart';

// Index types (Phase 1 - Week 3)
export 'src/index/multi_index.dart';
export 'src/index/datetime_index.dart';
export 'src/index/axis_index.dart';
export 'src/core/ndarray_config.dart';

// NDArray (Phase 2 - Week 4-6)
export 'src/ndarray/ndarray.dart';
export 'src/ndarray/operations.dart';
export 'src/ndarray/transformations.dart';
export 'src/ndarray/streaming.dart';
export 'src/ndarray/parallel.dart';
export 'src/ndarray/lazy_operations.dart';
export 'src/ndarray/filtering.dart';

// DataCube (Phase 3 - Week 7-9)
export 'src/data_cube/datacube.dart';
export 'src/data_cube/dataframe_integration.dart';
export 'src/data_cube/aggregations.dart';
export 'src/data_cube/transformations.dart';
export 'src/data_cube/io.dart';
export 'src/data_cube/selection.dart';

// Integration layer (Week 18)
export 'src/integration/dart_data_integration.dart';
