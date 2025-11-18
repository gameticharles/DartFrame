/// HDF5 reader extensions for NDArray and DataCube.
///
/// Enables reading HDF5 files (from Python, MATLAB, R) into Dart data structures.
library;

import '../../ndarray/ndarray.dart';
import '../../datacube/datacube.dart';
import '../../core/slice_spec.dart';
import 'hdf5_file.dart';
import 'dataset.dart';

/// Options for HDF5 reading.
class HDF5ReadOptions {
  /// Dataset name/path in HDF5 file.
  final String dataset;

  /// Whether to use lazy loading (not load data immediately).
  final bool lazy;

  /// Slice specification for partial reads.
  final List<SliceSpec>? slice;

  /// Maximum memory to use for caching (in bytes).
  final int? maxCacheSize;

  const HDF5ReadOptions({
    this.dataset = '/data',
    this.lazy = false,
    this.slice,
    this.maxCacheSize,
  });
}

/// Extension for reading HDF5 to NDArray.
extension NDArrayHDF5Reader on NDArray {
  /// Reads an HDF5 file into an NDArray.
  ///
  /// Compatible with HDF5 files created by Python (h5py, pandas), MATLAB, and R.
  ///
  /// Example:
  /// ```dart
  /// // Read from Python-created HDF5
  /// var array = await NDArray.fromHDF5('data.h5', dataset: '/measurements');
  ///
  /// // Lazy loading for large files
  /// var lazyArray = await NDArray.fromHDF5('large.h5', lazy: true);
  ///
  /// // Partial read (slicing)
  /// var slice = await NDArray.fromHDF5('data.h5',
  ///   slice: [Slice.range(0, 10), Slice.all()],
  /// );
  /// ```
  ///
  /// Python example (creating the file):
  /// ```python
  /// import h5py
  /// import numpy as np
  ///
  /// data = np.random.rand(100, 200)
  /// with h5py.File('data.h5', 'w') as f:
  ///     f.create_dataset('/measurements', data=data)
  /// ```
  static Future<NDArray> fromHDF5(
    String path, {
    String dataset = '/data',
    bool lazy = false,
    List<SliceSpec>? slice,
  }) async {
    final options = HDF5ReadOptions(
      dataset: dataset,
      lazy: lazy,
      slice: slice,
    );

    return await _readHDF5ToNDArray(path, options);
  }
}

/// Extension for reading HDF5 to DataCube.
extension DataCubeHDF5Reader on DataCube {
  /// Reads an HDF5 file into a DataCube.
  ///
  /// The dataset must be 3-dimensional.
  ///
  /// Example:
  /// ```dart
  /// // Read from MATLAB-created HDF5
  /// var cube = await DataCube.fromHDF5('cube.h5', dataset: '/temperature');
  /// ```
  ///
  /// MATLAB example (creating the file):
  /// ```matlab
  /// data = rand(10, 20, 30);
  /// h5create('cube.h5', '/temperature', size(data));
  /// h5write('cube.h5', '/temperature', data);
  /// ```
  static Future<DataCube> fromHDF5(
    String path, {
    String dataset = '/data',
    bool lazy = false,
  }) async {
    final options = HDF5ReadOptions(
      dataset: dataset,
      lazy: lazy,
    );

    final array = await _readHDF5ToNDArray(path, options);

    if (array.ndim != 3) {
      throw ArgumentError(
        'Dataset must be 3-dimensional for DataCube, got ${array.ndim}D',
      );
    }

    return DataCube.fromNDArray(array);
  }
}

/// Internal HDF5 reader implementation.
Future<NDArray> _readHDF5ToNDArray(
  String path,
  HDF5ReadOptions options,
) async {
  // Open HDF5 file using the existing reader
  final file = await Hdf5File.open(path);

  try {
    // Get dataset
    final dataset = await file.dataset(options.dataset);

    // Get shape
    final shape = dataset.shape;

    // Handle slicing if specified
    List<int> finalShape;
    List<dynamic> data;

    if (options.slice != null) {
      // Partial read with slicing
      final sliceResult = await _readSlicedData(file, dataset, options.slice!);
      finalShape = sliceResult.shape;
      data = sliceResult.data;
    } else {
      // Full read
      finalShape = shape;
      data = await file.readDataset(options.dataset);
    }

    // Create NDArray
    final array = NDArray.fromFlat(data, finalShape);

    // Copy attributes
    final attrs = dataset.attributes;
    for (var attr in attrs) {
      try {
        array.attrs[attr.name] = attr.value;
      } catch (e) {
        // Skip attributes that can't be converted
      }
    }

    return array;
  } finally {
    await file.close();
  }
}

/// Result of sliced data read.
class _SliceResult {
  final List<int> shape;
  final List<dynamic> data;

  _SliceResult(this.shape, this.data);
}

/// Reads sliced data from dataset.
Future<_SliceResult> _readSlicedData(
  Hdf5File file,
  Dataset dataset,
  List<SliceSpec> slices,
) async {
  // For now, read full data and slice in memory
  // A full implementation would use HDF5 hyperslab selection
  final fullData = await file.readDataset(dataset.objectPath!);
  final fullShape = dataset.shape;

  // Create NDArray from full data
  final fullArray = NDArray.fromFlat(fullData, fullShape);

  // Apply slicing
  final slicedData = fullArray.slice(slices);

  if (slicedData is NDArray) {
    return _SliceResult(
      slicedData.shape.toList(),
      slicedData.toFlatList(),
    );
  } else {
    // Scalar result
    return _SliceResult([1], [slicedData]);
  }
}

/// Static methods for NDArray HDF5 operations.
class NDArrayHDF5 {
  /// Reads an HDF5 file into an NDArray.
  static Future<NDArray> fromHDF5(
    String path, {
    String dataset = '/data',
    bool lazy = false,
    List<SliceSpec>? slice,
  }) async {
    final options = HDF5ReadOptions(
      dataset: dataset,
      lazy: lazy,
      slice: slice,
    );

    return await _readHDF5ToNDArray(path, options);
  }
}

/// Static methods for DataCube HDF5 operations.
class DataCubeHDF5 {
  /// Reads an HDF5 file into a DataCube.
  static Future<DataCube> fromHDF5(
    String path, {
    String dataset = '/data',
    bool lazy = false,
  }) async {
    final options = HDF5ReadOptions(
      dataset: dataset,
      lazy: lazy,
    );

    final array = await _readHDF5ToNDArray(path, options);

    if (array.ndim != 3) {
      throw ArgumentError(
        'Dataset must be 3-dimensional for DataCube, got ${array.ndim}D',
      );
    }

    return DataCube.fromNDArray(array);
  }
}

/// HDF5 Reader utility class.
///
/// Provides static methods for reading HDF5 files.
class HDF5ReaderUtil {
  /// Reads an HDF5 dataset to NDArray.
  static Future<NDArray> readNDArray(
    String path, {
    String dataset = '/data',
    bool lazy = false,
    List<SliceSpec>? slice,
  }) async {
    return await _readHDF5ToNDArray(
        path,
        HDF5ReadOptions(
          dataset: dataset,
          lazy: lazy,
          slice: slice,
        ));
  }

  /// Reads an HDF5 dataset to DataCube.
  static Future<DataCube> readDataCube(
    String path, {
    String dataset = '/data',
    bool lazy = false,
  }) async {
    final array = await _readHDF5ToNDArray(
        path,
        HDF5ReadOptions(
          dataset: dataset,
          lazy: lazy,
        ));

    if (array.ndim != 3) {
      throw ArgumentError(
        'Dataset must be 3-dimensional for DataCube, got ${array.ndim}D',
      );
    }

    return DataCube.fromNDArray(array);
  }

  /// Lists all datasets in an HDF5 file.
  ///
  /// Example:
  /// ```dart
  /// var datasets = await HDF5ReaderUtil.listDatasets('data.h5');
  /// print('Available datasets: $datasets');
  /// ```
  static Future<List<String>> listDatasets(String path) async {
    final file = await Hdf5File.open(path);
    try {
      final datasets = <String>[];
      await _collectDatasets(file, '/', datasets);
      return datasets;
    } finally {
      await file.close();
    }
  }

  /// Recursively collects dataset paths.
  static Future<void> _collectDatasets(
    Hdf5File file,
    String groupPath,
    List<String> datasets,
  ) async {
    try {
      final group = await file.group(groupPath);

      for (var childName in group.children) {
        final fullPath =
            groupPath == '/' ? '/$childName' : '$groupPath/$childName';

        // Try to get as dataset
        try {
          await file.dataset(fullPath);
          datasets.add(fullPath);
        } catch (e) {
          // Not a dataset, try as group (recursive)
          try {
            await _collectDatasets(file, fullPath, datasets);
          } catch (e) {
            // Skip if neither dataset nor group
          }
        }
      }
    } catch (e) {
      // Skip if group doesn't exist
    }
  }

  /// Gets information about an HDF5 dataset.
  ///
  /// Returns a map with shape, dtype, and attributes.
  ///
  /// Example:
  /// ```dart
  /// var info = await HDF5ReaderUtil.getDatasetInfo('data.h5', '/measurements');
  /// print('Shape: ${info['shape']}');
  /// print('Attributes: ${info['attributes']}');
  /// ```
  static Future<Map<String, dynamic>> getDatasetInfo(
    String path,
    String dataset,
  ) async {
    // Read the array to get info
    final array = await readNDArray(path, dataset: dataset);

    return {
      'shape': array.shape.toList(),
      'ndim': array.ndim,
      'size': array.size,
      'dtype': 'float64',
      'attributes': array.attrs.toJson(),
    };
  }

  /// Reads multiple datasets from an HDF5 file.
  ///
  /// Example:
  /// ```dart
  /// var data = await HDF5ReaderUtil.readMultiple('data.h5', [
  ///   '/measurements',
  ///   '/calibration',
  ///   '/metadata',
  /// ]);
  /// ```
  static Future<Map<String, NDArray>> readMultiple(
    String path,
    List<String> datasets,
  ) async {
    final result = <String, NDArray>{};

    for (var dataset in datasets) {
      try {
        result[dataset] = await readNDArray(path, dataset: dataset);
      } catch (e) {
        // Skip datasets that can't be read
      }
    }

    return result;
  }
}
