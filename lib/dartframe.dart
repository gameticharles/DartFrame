library;

export 'src/series/series.dart';
export 'src/data_frame/data_frame.dart';
export 'src/file_helper/file_io.dart';
export 'src/io/readers.dart';
export 'src/io/writers.dart';
export 'src/io/database.dart';
export 'src/io/chunked_reader.dart';
export 'src/io/hdf5_reader.dart';
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
export 'src/io/hdf5/dataset.dart';
export 'src/io/hdf5/group.dart';
export 'src/io/hdf5/attribute.dart';
export 'src/io/hdf5/dataspace.dart';

// HDF5 Internal utilities - for advanced users building tools
export 'src/io/hdf5/byte_reader.dart';
export 'src/io/hdf5/superblock.dart';
export 'src/io/hdf5/object_header.dart';
export 'src/io/hdf5/global_heap.dart';

export 'src/utils/utils.dart';

// Data type system
export 'src/core/dtype.dart';
export 'src/core/dtype_integration.dart';
export 'src/utils/lists.dart';
export 'src/utils/memory.dart';
export 'src/utils/performance.dart';
export 'src/utils/time_series.dart';

// Index types
export 'src/index/multi_index.dart';
export 'src/index/datetime_index.dart';
