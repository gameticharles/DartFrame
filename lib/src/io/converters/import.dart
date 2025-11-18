/// Import utilities for DartFrame
///
/// Provides convenient import methods for various data formats
library;

import '../../ndarray/ndarray.dart';
import '../../data_cube/datacube.dart';
import '../dcf/dcf_reader.dart';
import '../hdf5/hdf5_reader_extensions.dart';
import 'format_converter.dart';

/// Import utilities for NDArray
class NDArrayImport {
  /// Import from HDF5 file
  static Future<NDArray> fromHDF5(
    String path, {
    String? dataset,
  }) async {
    return await NDArrayHDF5.fromHDF5(
      path,
      dataset: dataset ?? '/data',
    );
  }

  /// Import from DCF file
  static Future<NDArray> fromDCF(String path) async {
    return await NDArrayDCF.fromDCF(path);
  }

  /// Import from JSON file
  static Future<NDArray> fromJSON(String path) async {
    return await FormatConverter.readNDArray(path, DataFormat.json);
  }

  /// Import from binary file
  static Future<NDArray> fromBinary(String path) async {
    return await FormatConverter.readNDArray(path, DataFormat.binary);
  }

  /// Import from Parquet file (planned)
  static Future<NDArray> fromParquet(String path) async {
    throw UnimplementedError('Parquet import not yet implemented');
  }

  /// Import from MAT file (planned)
  static Future<NDArray> fromMAT(
    String path, {
    String? varName,
  }) async {
    throw UnimplementedError('MAT import not yet implemented');
  }

  /// Import from NetCDF file (planned)
  static Future<NDArray> fromNetCDF(
    String path, {
    String? variable,
  }) async {
    throw UnimplementedError('NetCDF import not yet implemented');
  }

  /// Auto-detect format and import
  static Future<NDArray> fromFile(String path) async {
    final ext = path.split('.').last.toLowerCase();

    switch (ext) {
      case 'h5':
      case 'hdf5':
        return await fromHDF5(path);
      case 'dcf':
        return await fromDCF(path);
      case 'json':
        return await fromJSON(path);
      case 'bin':
      case 'binary':
        return await fromBinary(path);
      case 'parquet':
        return await fromParquet(path);
      case 'mat':
        return await fromMAT(path);
      case 'nc':
      case 'netcdf':
        return await fromNetCDF(path);
      default:
        throw ArgumentError('Unsupported file format: $ext');
    }
  }
}

/// Import utilities for DataCube
class DataCubeImport {
  /// Import from HDF5 file
  static Future<DataCube> fromHDF5(
    String path, {
    String? dataset,
  }) async {
    return await DataCubeHDF5.fromHDF5(
      path,
      dataset: dataset ?? '/data',
    );
  }

  /// Import from DCF file
  static Future<DataCube> fromDCF(String path) async {
    return await DataCubeDCF.fromDCF(path);
  }

  /// Import from JSON file
  static Future<DataCube> fromJSON(String path) async {
    return await FormatConverter.readDataCube(path, DataFormat.json);
  }

  /// Import from binary file
  static Future<DataCube> fromBinary(String path) async {
    throw UnimplementedError(
      'Binary import for DataCube requires shape information',
    );
  }

  /// Import from Parquet file (planned)
  static Future<DataCube> fromParquet(String path) async {
    throw UnimplementedError('Parquet import not yet implemented');
  }

  /// Import from MAT file (planned)
  static Future<DataCube> fromMAT(
    String path, {
    String? varName,
  }) async {
    throw UnimplementedError('MAT import not yet implemented');
  }

  /// Import from NetCDF file (planned)
  static Future<DataCube> fromNetCDF(
    String path, {
    String? variable,
  }) async {
    throw UnimplementedError('NetCDF import not yet implemented');
  }

  /// Auto-detect format and import
  static Future<DataCube> fromFile(String path) async {
    final ext = path.split('.').last.toLowerCase();

    switch (ext) {
      case 'h5':
      case 'hdf5':
        return await fromHDF5(path);
      case 'dcf':
        return await fromDCF(path);
      case 'json':
        return await fromJSON(path);
      case 'parquet':
        return await fromParquet(path);
      case 'mat':
        return await fromMAT(path);
      case 'nc':
      case 'netcdf':
        return await fromNetCDF(path);
      default:
        throw ArgumentError('Unsupported file format: $ext');
    }
  }
}

/// Extension methods for convenient imports
extension NDArrayImportExtension on NDArray {
  /// Create NDArray from file (auto-detect format)
  static Future<NDArray> fromFile(String path) async {
    return await NDArrayImport.fromFile(path);
  }
}

/// Extension methods for convenient imports
extension DataCubeImportExtension on DataCube {
  /// Create DataCube from file (auto-detect format)
  static Future<DataCube> fromFile(String path) async {
    return await DataCubeImport.fromFile(path);
  }
}
