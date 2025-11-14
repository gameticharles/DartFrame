import 'dart:async';
import '../data_frame/data_frame.dart';
import 'readers.dart';
import 'hdf5/hdf5_file.dart';
import 'hdf5/hdf5_error.dart';

/// Reader for HDF5 files - integrates with dartframe
class HDF5Reader implements DataReader {
  @override
  Future<DataFrame> read(String path, {Map<String, dynamic>? options}) async {
    final datasetPath = options?['dataset'] as String? ?? '/data';
    final debugMode = options?['debug'] as bool? ?? false;

    // Set debug mode if requested
    if (debugMode) {
      setHdf5DebugMode(true);
    }

    try {
      final file = await Hdf5File.open(path);

      try {
        // Try to read the specified dataset
        final data = await file.readDataset(datasetPath);
        final dataset = await file.dataset(datasetPath);
        final shape = dataset.shape;

        // Convert to DataFrame
        if (shape.length == 1) {
          // 1D array - single column
          return DataFrame.fromMap({
            'data': data,
          });
        } else if (shape.length == 2) {
          // 2D array - multiple columns
          final rows = shape[0];
          final cols = shape[1];
          final columns = <String, List<dynamic>>{};

          for (int col = 0; col < cols; col++) {
            final columnData = <dynamic>[];
            for (int row = 0; row < rows; row++) {
              columnData.add(data[row * cols + col]);
            }
            columns['col_$col'] = columnData;
          }

          return DataFrame.fromMap(columns);
        } else {
          // 3D+ array - flatten to 1D with shape info in separate columns
          // Store the flattened data and shape information
          return DataFrame.fromMap({
            'data': data,
            '_shape': List.filled(data.length, shape.join('x')),
            '_ndim': List.filled(data.length, shape.length),
          });
        }
      } finally {
        await file.close();
      }
    } on Hdf5Error {
      // Re-throw HDF5 errors as-is
      rethrow;
    } catch (e) {
      // Wrap other errors
      throw DataReadError(
        filePath: path,
        objectPath: datasetPath,
        reason: 'Failed to read HDF5 file',
        originalError: e,
      );
    } finally {
      // Reset debug mode
      if (debugMode) {
        setHdf5DebugMode(false);
      }
    }
  }

  /// Read dataset attributes from an HDF5 file
  ///
  /// Returns a map of attribute names to their values.
  /// This allows accessing dataset metadata that was stored with the HDF5 file.
  ///
  /// Example:
  /// ```dart
  /// final attrs = await HDF5Reader.readAttributes('data.h5', dataset: '/mydata');
  /// print(attrs['units']); // e.g., 'meters'
  /// print(attrs['description']); // e.g., 'Temperature measurements'
  /// ```
  static Future<Map<String, dynamic>> readAttributes(
    String path, {
    String dataset = '/data',
    bool debug = false,
  }) async {
    if (debug) {
      setHdf5DebugMode(true);
    }

    try {
      final file = await Hdf5File.open(path);
      try {
        final ds = await file.dataset(dataset);
        final attributes = ds.attributes;

        final result = <String, dynamic>{};
        for (final attr in attributes) {
          result[attr.name] = attr.value;
        }

        return result;
      } finally {
        await file.close();
      }
    } finally {
      if (debug) {
        setHdf5DebugMode(false);
      }
    }
  }

  /// Reads HDF5 file and returns information about its structure
  static Future<Map<String, dynamic>> inspect(String path,
      {bool debug = false}) async {
    if (debug) {
      setHdf5DebugMode(true);
    }

    try {
      final file = await Hdf5File.open(path);
      try {
        final info = file.info;
        final children = file.root.children;

        return {
          'version': info['version'],
          'rootChildren': children,
          'datasets': children,
        };
      } finally {
        await file.close();
      }
    } finally {
      if (debug) {
        setHdf5DebugMode(false);
      }
    }
  }

  /// Lists all datasets in the HDF5 file
  static Future<List<String>> listDatasets(String path,
      {bool debug = false}) async {
    if (debug) {
      setHdf5DebugMode(true);
    }

    try {
      final file = await Hdf5File.open(path);
      try {
        return file.root.children;
      } finally {
        await file.close();
      }
    } finally {
      if (debug) {
        setHdf5DebugMode(false);
      }
    }
  }

  /// Enables or disables debug mode for verbose logging
  static void setDebugMode(bool enabled) {
    setHdf5DebugMode(enabled);
  }
}

/// Exception thrown when HDF5 reading fails
/// @deprecated Use Hdf5Error and its subclasses instead
class HDF5ReadError extends Error {
  final String message;
  HDF5ReadError(this.message);

  @override
  String toString() => 'HDF5ReadError: $message';
}
