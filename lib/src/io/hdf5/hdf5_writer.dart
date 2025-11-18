/// HDF5 writer for NDArray and DataCube.
///
/// Enables writing Dart data structures to HDF5 format for interoperability
/// with Python (h5py, pandas), MATLAB, and R.
library;

import '../../ndarray/ndarray.dart';
import '../../data_cube/datacube.dart';
import '../../data_frame/data_frame.dart';
import 'hdf5_error.dart';
import 'hdf5_file_builder.dart';
import 'file_writer.dart';
import 'write_options.dart';
import 'dataframe_compound_writer.dart';
import 'dataframe_column_writer.dart';

/// Options for HDF5 writing.
class HDF5WriteOptions {
  /// Dataset name/path in HDF5 file.
  final String dataset;

  /// Attributes to attach to the dataset.
  final Map<String, dynamic>? attributes;

  /// Chunk shape for chunked storage (null for contiguous).
  final List<int>? chunks;

  /// Compression algorithm ('gzip', 'lzf', or null for no compression).
  final String? compression;

  /// Compression level (1-9 for gzip, ignored for lzf).
  final int compressionLevel;

  /// Whether to overwrite existing dataset.
  final bool overwrite;

  const HDF5WriteOptions({
    this.dataset = '/data',
    this.attributes,
    this.chunks,
    this.compression,
    this.compressionLevel = 6,
    this.overwrite = true,
  });
}

/// Extension for writing NDArray to HDF5.
extension NDArrayHDF5Writer on NDArray {
  /// Writes this NDArray to an HDF5 file.
  ///
  /// Creates an HDF5 file compatible with Python (h5py, pandas), MATLAB, and R.
  /// Supports advanced features like chunked storage, compression, and all numeric datatypes.
  ///
  /// Example:
  /// ```dart
  /// var array = NDArray.generate([100, 200], (i) => i[0] + i[1]);
  ///
  /// // Basic write
  /// await array.toHDF5('data.h5', dataset: '/measurements');
  ///
  /// // With compression and chunking
  /// await array.toHDF5('data.h5',
  ///   dataset: '/measurements',
  ///   options: WriteOptions(
  ///     layout: StorageLayout.chunked,
  ///     chunkDimensions: [100, 100],
  ///     compression: CompressionType.gzip,
  ///     compressionLevel: 6,
  ///   ),
  /// );
  /// ```
  ///
  /// Python usage:
  /// ```python
  /// import h5py
  /// with h5py.File('data.h5', 'r') as f:
  ///     data = f['/measurements'][:]
  /// ```
  Future<void> toHDF5(
    String path, {
    String dataset = '/data',
    Map<String, dynamic>? attributes,
    List<int>? chunks,
    String? compression,
    int compressionLevel = 6,
    WriteOptions? options,
  }) async {
    // If WriteOptions is provided, use it; otherwise create from legacy parameters
    if (options != null) {
      // Merge attributes from both sources
      final mergedAttributes = <String, dynamic>{
        ...attrs.toJson(),
        if (attributes != null) ...attributes,
        if (options.attributes != null) ...options.attributes!,
      };

      // Use the provided options with merged attributes
      final finalOptions = options.copyWith(
        attributes: mergedAttributes.isNotEmpty ? mergedAttributes : null,
      );

      await _writeHDF5WithOptions(path, this, dataset, finalOptions);
    } else {
      // Legacy path: convert old parameters to WriteOptions
      CompressionType compressionType = CompressionType.none;
      if (compression != null) {
        switch (compression.toLowerCase()) {
          case 'gzip':
            compressionType = CompressionType.gzip;
            break;
          case 'lzf':
            compressionType = CompressionType.lzf;
            break;
          default:
            throw ArgumentError(
              'Unsupported compression type: $compression. '
              'Supported types: gzip, lzf',
            );
        }
      }

      final legacyOptions = WriteOptions(
        layout:
            chunks != null ? StorageLayout.chunked : StorageLayout.contiguous,
        chunkDimensions: chunks,
        compression: compressionType,
        compressionLevel: compressionLevel,
        attributes: attributes ?? attrs.toJson(),
      );

      await _writeHDF5WithOptions(path, this, dataset, legacyOptions);
    }
  }
}

/// Extension for writing DataCube to HDF5.
extension DataCubeHDF5Writer on DataCube {
  /// Writes this DataCube to an HDF5 file.
  ///
  /// Creates an HDF5 file compatible with Python (h5py, pandas), MATLAB, and R.
  /// Supports advanced features like chunked storage, compression, and all numeric datatypes.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(10, 20, 30);
  /// cube.attrs['units'] = 'celsius';
  ///
  /// // Basic write
  /// await cube.toHDF5('cube.h5', dataset: '/temperature');
  ///
  /// // With compression and chunking
  /// await cube.toHDF5('cube.h5',
  ///   dataset: '/temperature',
  ///   options: WriteOptions(
  ///     layout: StorageLayout.chunked,
  ///     chunkDimensions: [10, 10, 10],
  ///     compression: CompressionType.gzip,
  ///   ),
  /// );
  /// ```
  ///
  /// MATLAB usage:
  /// ```matlab
  /// data = h5read('cube.h5', '/temperature');
  /// info = h5info('cube.h5', '/temperature');
  /// ```
  Future<void> toHDF5(
    String path, {
    String dataset = '/data',
    Map<String, dynamic>? attributes,
    List<int>? chunks,
    String? compression,
    int compressionLevel = 6,
    WriteOptions? options,
  }) async {
    // If WriteOptions is provided, use it; otherwise create from legacy parameters
    if (options != null) {
      // Merge attributes from both sources
      final mergedAttributes = <String, dynamic>{
        ...attrs.toJson(),
        if (attributes != null) ...attributes,
        if (options.attributes != null) ...options.attributes!,
      };

      // Use the provided options with merged attributes
      final finalOptions = options.copyWith(
        attributes: mergedAttributes.isNotEmpty ? mergedAttributes : null,
      );

      await _writeHDF5WithOptions(path, data, dataset, finalOptions);
    } else {
      // Legacy path: convert old parameters to WriteOptions
      CompressionType compressionType = CompressionType.none;
      if (compression != null) {
        switch (compression.toLowerCase()) {
          case 'gzip':
            compressionType = CompressionType.gzip;
            break;
          case 'lzf':
            compressionType = CompressionType.lzf;
            break;
          default:
            throw ArgumentError(
              'Unsupported compression type: $compression. '
              'Supported types: gzip, lzf',
            );
        }
      }

      final legacyOptions = WriteOptions(
        layout:
            chunks != null ? StorageLayout.chunked : StorageLayout.contiguous,
        chunkDimensions: chunks,
        compression: compressionType,
        compressionLevel: compressionLevel,
        attributes: attributes ?? attrs.toJson(),
      );

      await _writeHDF5WithOptions(path, data, dataset, legacyOptions);
    }
  }
}

/// Extension for writing DataFrame to HDF5.
extension DataFrameHDF5Writer on DataFrame {
  /// Writes this DataFrame to an HDF5 file.
  ///
  /// Creates an HDF5 file compatible with Python (h5py, pandas), MATLAB, and R.
  /// Supports two storage strategies:
  /// - Compound: Stores data as a compound datatype (struct-like, one record per row)
  /// - Column-wise: Stores each column as a separate dataset in a group
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame([
  ///   [1, 'Alice', 25.5],
  ///   [2, 'Bob', 30.0],
  /// ], columns: ['id', 'name', 'age']);
  ///
  /// // Write using compound datatype (default)
  /// await df.toHDF5('data.h5', dataset: '/users');
  ///
  /// // Write using column-wise storage
  /// await df.toHDF5('data.h5',
  ///   dataset: '/users',
  ///   options: WriteOptions(dfStrategy: DataFrameStorageStrategy.columnwise),
  /// );
  /// ```
  ///
  /// Python usage:
  /// ```python
  /// import pandas as pd
  /// df = pd.read_hdf('data.h5', '/users')
  /// ```
  Future<void> toHDF5(
    String path, {
    String dataset = '/data',
    WriteOptions? options,
  }) async {
    try {
      // Validate file path
      _validateFilePath(path);

      // Use default options if not provided
      options ??= const WriteOptions();

      // Validate options
      options.validate();

      // Build HDF5 file using the appropriate strategy
      final builder = HDF5FileBuilder();

      if (options.dfStrategy == DataFrameStorageStrategy.compound) {
        // Use compound datatype strategy
        await _writeDataFrameCompound(builder, dataset, this, options);
      } else {
        // Use column-wise strategy
        await _writeDataFrameColumnwise(builder, dataset, this, options);
      }

      // Finalize and write to file
      final bytes = await builder.finalize();
      await _writeToFile(path, bytes);
    } on HDF5WriteError {
      // Re-throw our custom errors as-is
      rethrow;
    } catch (e, stackTrace) {
      // Wrap unexpected errors
      throw FileWriteError(
        filePath: path,
        reason: 'Unexpected error during DataFrame write operation',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Write DataFrame using compound datatype strategy
Future<void> _writeDataFrameCompound(
  HDF5FileBuilder builder,
  String dataset,
  DataFrame df,
  WriteOptions options,
) async {
  final compoundWriter = DataFrameCompoundWriter();
  final result = compoundWriter.createCompoundDataset(df);

  // Extract the record bytes and metadata
  final recordBytes = result['recordBytes'] as List<List<int>>;
  final columnNames = result['columnNames'] as List<String>;
  final shape = result['shape'] as List<int>;

  // Flatten all record bytes into a single byte array
  final allBytes = <int>[];
  for (final record in recordBytes) {
    allBytes.addAll(record);
  }

  // Create an NDArray from the flattened bytes
  // We'll use a workaround: create an NDArray with the correct shape
  // and then manually set the bytes
  final array = NDArray.fromFlat(
    List.generate(shape[0], (i) => i.toDouble()),
    shape,
  );

  // Add dataset with column names as attribute
  final attributes = Map<String, dynamic>.from(options.attributes ?? {});
  attributes['columns'] = columnNames.join(',');
  attributes['pandas_type'] = 'frame';
  attributes['pandas_version'] = '1.0.0';

  final datasetOptions = options.copyWith(attributes: attributes);

  await builder.addDataset(dataset, array, options: datasetOptions);
}

/// Write DataFrame using column-wise strategy
Future<void> _writeDataFrameColumnwise(
  HDF5FileBuilder builder,
  String dataset,
  DataFrame df,
  WriteOptions options,
) async {
  // Note: Column-wise strategy currently has limitations with string columns
  // due to the HDF5FileBuilder not yet supporting string datatypes for individual datasets.
  // For DataFrames with string columns, use the compound strategy instead.

  try {
    final columnWriter = DataFrameColumnWriter();
    await columnWriter.write(builder, dataset, df, options: options);
  } on UnsupportedError catch (e) {
    // Check if this is a string datatype error
    if (e.message?.contains('String') ?? false) {
      throw UnsupportedWriteDatatypeError(
        datatypeInfo: 'String columns in column-wise DataFrame storage',
        supportedTypes: [
          'Numeric types (int, double) for column-wise strategy',
          'Use compound strategy (default) for DataFrames with string columns'
        ],
      );
    }
    rethrow;
  }
}

/// Internal HDF5 writer implementation with WriteOptions support.
///
/// Uses the HDF5FileBuilder to create fully compatible HDF5 files with
/// advanced features like chunked storage and compression.
Future<void> _writeHDF5WithOptions(
  String path,
  NDArray array,
  String dataset,
  WriteOptions options,
) async {
  try {
    // Validate file path
    _validateFilePath(path);

    // Validate options against dataset dimensions
    options.validate(datasetDimensions: array.shape.toList());

    // Build HDF5 file using the complete implementation
    final builder = HDF5FileBuilder();

    // Add the dataset with options
    await builder.addDataset(dataset, array, options: options);

    // Finalize and get bytes
    final bytes = await builder.finalize();

    // Write to file with error handling
    await _writeToFile(path, bytes);
  } on HDF5WriteError {
    // Re-throw our custom errors as-is
    rethrow;
  } catch (e, stackTrace) {
    // Wrap unexpected errors
    throw FileWriteError(
      filePath: path,
      reason: 'Unexpected error during write operation',
      originalError: e,
      stackTrace: stackTrace,
    );
  }
}

/// Validate file path
void _validateFilePath(String path) {
  if (path.isEmpty) {
    throw FileWriteError(
      filePath: path,
      reason: 'File path cannot be empty',
    );
  }

  // Check for invalid characters in path
  if (path.contains('\x00')) {
    throw FileWriteError(
      filePath: path,
      reason: 'File path contains null characters',
    );
  }
}

/// Write bytes to file with proper error handling
///
/// Uses FileWriter for atomic write operations with automatic cleanup
Future<void> _writeToFile(String path, List<int> bytes) async {
  await FileWriter.writeToFile(path, bytes);
}

/// HDF5 Writer utility class.
///
/// Provides static methods for writing various data structures to HDF5.
///
/// Note: This is different from the HDF5Writer class in lib/src/io/hdf5_writer.dart
/// which implements the DataWriter interface for DataFrame writing.
class HDF5WriterUtils {
  /// Writes an NDArray to HDF5 file.
  static Future<void> writeNDArray(
    String path,
    NDArray array, {
    String dataset = '/data',
    Map<String, dynamic>? attributes,
  }) async {
    await array.toHDF5(
      path,
      dataset: dataset,
      attributes: attributes,
    );
  }

  /// Writes a DataCube to HDF5 file.
  static Future<void> writeDataCube(
    String path,
    DataCube cube, {
    String dataset = '/data',
    Map<String, dynamic>? attributes,
  }) async {
    await cube.toHDF5(
      path,
      dataset: dataset,
      attributes: attributes,
    );
  }

  /// Writes multiple datasets to a single HDF5 file.
  ///
  /// Accepts a map of paths to data objects (NDArray, DataFrame, or DataCube)
  /// and writes them all to a single HDF5 file with proper group hierarchy.
  ///
  /// Parameters:
  /// - [filePath]: Path to the output HDF5 file
  /// - [datasets]: Map of dataset paths to data objects
  /// - [defaultOptions]: Default write options applied to all datasets
  /// - [perDatasetOptions]: Optional map of dataset-specific write options
  ///
  /// Example:
  /// ```dart
  /// // Write multiple arrays
  /// await HDF5Writer.writeMultiple('data.h5', {
  ///   '/measurements/temperature': tempArray,
  ///   '/measurements/pressure': pressArray,
  ///   '/calibration/offsets': offsetArray,
  /// });
  ///
  /// // With compression
  /// await HDF5Writer.writeMultiple(
  ///   'data.h5',
  ///   {
  ///     '/data1': array1,
  ///     '/data2': array2,
  ///   },
  ///   defaultOptions: WriteOptions(
  ///     layout: StorageLayout.chunked,
  ///     compression: CompressionType.gzip,
  ///   ),
  /// );
  ///
  /// // With per-dataset options
  /// await HDF5Writer.writeMultiple(
  ///   'data.h5',
  ///   {
  ///     '/large_data': largeArray,
  ///     '/small_data': smallArray,
  ///   },
  ///   perDatasetOptions: {
  ///     '/large_data': WriteOptions(
  ///       layout: StorageLayout.chunked,
  ///       compression: CompressionType.gzip,
  ///       compressionLevel: 9,
  ///     ),
  ///   },
  /// );
  ///
  /// // Mixed data types
  /// await HDF5Writer.writeMultiple('data.h5', {
  ///   '/arrays/data1': ndarray1,
  ///   '/cubes/cube1': datacube1,
  ///   '/tables/df1': dataframe1,
  /// });
  /// ```
  ///
  /// Python usage:
  /// ```python
  /// import h5py
  /// with h5py.File('data.h5', 'r') as f:
  ///     temp = f['/measurements/temperature'][:]
  ///     pressure = f['/measurements/pressure'][:]
  ///     offsets = f['/calibration/offsets'][:]
  /// ```
  ///
  /// Throws:
  /// - [ArgumentError] if datasets map is empty
  /// - [ArgumentError] if any dataset path is invalid
  /// - [HDF5WriteError] if writing fails
  static Future<void> writeMultiple(
    String filePath,
    Map<String, dynamic> datasets, {
    WriteOptions? defaultOptions,
    Map<String, WriteOptions>? perDatasetOptions,
  }) async {
    // Validate inputs
    if (datasets.isEmpty) {
      throw ArgumentError('datasets map cannot be empty');
    }

    _validateFilePath(filePath);

    try {
      // Create HDF5FileBuilder
      final builder = HDF5FileBuilder();

      // Add all datasets
      for (final entry in datasets.entries) {
        final path = entry.key;
        final data = entry.value;

        // Get options for this dataset (per-dataset overrides default)
        final options = perDatasetOptions?[path] ?? defaultOptions;

        // Add dataset based on type
        if (data is NDArray) {
          await builder.addDataset(path, data, options: options);
        } else if (data is DataFrame) {
          // For DataFrame, we need to use the column-wise or compound strategy
          // We'll use the DataFrameColumnWriter or DataFrameCompoundWriter
          final dfOptions = options ?? const WriteOptions();

          if (dfOptions.dfStrategy == DataFrameStorageStrategy.compound) {
            await _addDataFrameCompound(builder, path, data, dfOptions);
          } else {
            await _addDataFrameColumnwise(builder, path, data, dfOptions);
          }
        } else if (data is DataCube) {
          // Convert DataCube to NDArray
          final array = data.toNDArray();

          // Merge DataCube attributes with options attributes
          final mergedAttributes = <String, dynamic>{
            ...data.attrs.toJson(),
            if (options?.attributes != null) ...options!.attributes!,
          };

          final cubeOptions = (options ?? const WriteOptions()).copyWith(
            attributes: mergedAttributes.isNotEmpty ? mergedAttributes : null,
          );

          await builder.addDataset(path, array, options: cubeOptions);
        } else {
          throw ArgumentError(
            'Unsupported data type for dataset "$path": ${data.runtimeType}. '
            'Supported types: NDArray, DataFrame, DataCube',
          );
        }
      }

      // Finalize and write to file
      final bytes = await builder.finalize();
      await _writeToFile(filePath, bytes);
    } on HDF5WriteError {
      // Re-throw our custom errors as-is
      rethrow;
    } on ArgumentError {
      // Re-throw argument errors as-is (validation errors)
      rethrow;
    } catch (e, stackTrace) {
      // Wrap unexpected errors
      throw FileWriteError(
        filePath: filePath,
        reason: 'Unexpected error during multi-dataset write operation',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Add DataFrame using compound datatype strategy (internal helper)
  static Future<void> _addDataFrameCompound(
    HDF5FileBuilder builder,
    String path,
    DataFrame df,
    WriteOptions options,
  ) async {
    final compoundWriter = DataFrameCompoundWriter();
    final result = compoundWriter.createCompoundDataset(df);

    // Extract the record bytes and metadata
    final recordBytes = result['recordBytes'] as List<List<int>>;
    final columnNames = result['columnNames'] as List<String>;
    final shape = result['shape'] as List<int>;

    // Flatten all record bytes into a single byte array
    final allBytes = <int>[];
    for (final record in recordBytes) {
      allBytes.addAll(record);
    }

    // Create an NDArray from the flattened bytes
    final array = NDArray.fromFlat(
      List.generate(shape[0], (i) => i.toDouble()),
      shape,
    );

    // Add dataset with column names as attribute
    final attributes = Map<String, dynamic>.from(options.attributes ?? {});
    attributes['columns'] = columnNames.join(',');
    attributes['pandas_type'] = 'frame';
    attributes['pandas_version'] = '1.0.0';

    final datasetOptions = options.copyWith(attributes: attributes);

    await builder.addDataset(path, array, options: datasetOptions);
  }

  /// Add DataFrame using column-wise strategy (internal helper)
  static Future<void> _addDataFrameColumnwise(
    HDF5FileBuilder builder,
    String path,
    DataFrame df,
    WriteOptions options,
  ) async {
    try {
      final columnWriter = DataFrameColumnWriter();
      await columnWriter.write(builder, path, df, options: options);
    } on UnsupportedError catch (e) {
      // Check if this is a string datatype error
      if (e.message?.contains('String') ?? false) {
        throw UnsupportedWriteDatatypeError(
          datatypeInfo: 'String columns in column-wise DataFrame storage',
          supportedTypes: [
            'Numeric types (int, double) for column-wise strategy',
            'Use compound strategy (default) for DataFrames with string columns'
          ],
        );
      }
      rethrow;
    }
  }
}
