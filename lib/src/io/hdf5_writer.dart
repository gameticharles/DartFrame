import 'dart:async';
import '../data_frame/data_frame.dart';
import '../ndarray/ndarray.dart';
import 'writers.dart';
import 'hdf5/hdf5_writer.dart' as hdf5_internal;
import 'hdf5/hdf5_error.dart';

/// Writer for HDF5 files - integrates with dartframe
///
/// This class provides a high-level interface for writing DataFrames to HDF5 files,
/// compatible with Python (h5py, pandas), MATLAB, and R.
///
/// Example:
/// ```dart
/// final df = DataFrame.fromMap({
///   'temperature': [20.5, 21.0, 19.8],
///   'humidity': [65, 68, 62],
/// });
///
/// final writer = HDF5Writer();
/// await writer.write(df, 'data.h5', options: {
///   'dataset': '/measurements',
///   'attributes': {'units': 'celsius', 'location': 'lab'},
/// });
/// ```
class HDF5Writer implements DataWriter {
  @override
  Future<void> write(DataFrame df, String path,
      {Map<String, dynamic>? options}) async {
    final datasetPath = options?['dataset'] as String? ?? '/data';
    final attributes = options?['attributes'] as Map<String, dynamic>?;
    final debugMode = options?['debug'] as bool? ?? false;

    // Set debug mode if requested
    if (debugMode) {
      setHdf5DebugMode(true);
    }

    try {
      // Convert DataFrame to NDArray
      final array = _dataFrameToNDArray(df);

      // Write using the internal HDF5 writer
      await array.toHDF5(
        path,
        dataset: datasetPath,
        attributes: attributes,
      );
    } on HDF5WriteError {
      // Re-throw HDF5 write errors as-is
      rethrow;
    } catch (e, stackTrace) {
      // Log the actual error for debugging
      if (debugMode) {
        hdf5DebugLog('Error writing HDF5 file: $e');
        hdf5DebugLog('Stack trace: $stackTrace');
      }

      // Wrap other errors
      throw FileWriteError(
        filePath: path,
        reason: 'Failed to write HDF5 file: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    } finally {
      // Reset debug mode
      if (debugMode) {
        setHdf5DebugMode(false);
      }
    }
  }

  /// Convert DataFrame to NDArray for HDF5 writing
  ///
  /// This handles the conversion from DataFrame's column-oriented structure
  /// to NDArray's row-oriented structure suitable for HDF5.
  NDArray _dataFrameToNDArray(DataFrame df) {
    final numRows = df.shape[0];
    final numCols = df.shape[1];

    // Get all column data
    final columns = df.columns;
    final columnData = <List<dynamic>>[];

    for (final colName in columns) {
      final series = df[colName];
      columnData.add(series.data);
    }

    // Convert to 2D array (row-major order)
    final data = <dynamic>[];
    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numCols; col++) {
        data.add(columnData[col][row]);
      }
    }

    // Create NDArray with shape [rows, cols]
    return NDArray.fromFlat(data, [numRows, numCols]);
  }

  /// Write a DataFrame to HDF5 file with attributes
  ///
  /// This is a convenience method that provides a more explicit API.
  ///
  /// Example:
  /// ```dart
  /// await HDF5Writer.writeDataFrame(
  ///   df,
  ///   'output.h5',
  ///   dataset: '/data',
  ///   attributes: {'units': 'meters'},
  /// );
  /// ```
  static Future<void> writeDataFrame(
    DataFrame df,
    String path, {
    String dataset = '/data',
    Map<String, dynamic>? attributes,
    bool debug = false,
  }) async {
    final writer = HDF5Writer();
    await writer.write(df, path, options: {
      'dataset': dataset,
      if (attributes != null) 'attributes': attributes,
      'debug': debug,
    });
  }

  /// Write an NDArray to HDF5 file
  ///
  /// This is a convenience method for writing NDArray directly.
  ///
  /// Example:
  /// ```dart
  /// final array = NDArray.generate([100, 50], (i) => i[0] + i[1]);
  /// await HDF5Writer.writeNDArray(
  ///   array,
  ///   'output.h5',
  ///   dataset: '/measurements',
  /// );
  /// ```
  static Future<void> writeNDArray(
    NDArray array,
    String path, {
    String dataset = '/data',
    Map<String, dynamic>? attributes,
    bool debug = false,
  }) async {
    if (debug) {
      setHdf5DebugMode(true);
    }

    try {
      await array.toHDF5(
        path,
        dataset: dataset,
        attributes: attributes,
      );
    } finally {
      if (debug) {
        setHdf5DebugMode(false);
      }
    }
  }

  /// Write multiple datasets to a single HDF5 file
  ///
  /// Example:
  /// ```dart
  /// await HDF5Writer.writeMultiple('data.h5', {
  ///   '/temperature': tempDf,
  ///   '/humidity': humidityDf,
  ///   '/pressure': pressureDf,
  /// });
  /// ```
  static Future<void> writeMultiple(
    String path,
    Map<String, DataFrame> datasets, {
    bool debug = false,
  }) async {
    if (datasets.isEmpty) return;

    // For now, write the first dataset
    // A full implementation would merge multiple datasets into one file
    final firstEntry = datasets.entries.first;
    await writeDataFrame(
      firstEntry.value,
      path,
      dataset: firstEntry.key,
      debug: debug,
    );

    // TODO: Implement writing multiple datasets to the same file
    // This requires extending the HDF5FileBuilder to support multiple datasets
    if (datasets.length > 1) {
      throw UnsupportedError(
        'Writing multiple datasets to a single HDF5 file is not yet supported. '
        'Currently only the first dataset will be written.',
      );
    }
  }

  /// Enables or disables debug mode for verbose logging
  static void setDebugMode(bool enabled) {
    setHdf5DebugMode(enabled);
  }
}
