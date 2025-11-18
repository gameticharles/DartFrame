/// Format conversion utilities for DartFrame
///
/// Provides conversion between different scientific data formats:
/// - HDF5 (Python, MATLAB, R)
/// - DCF (DartFrame native)
/// - JSON (human-readable)
/// - CSV (tabular data)
/// - Binary (raw data)
/// - Parquet (planned)
/// - MAT (planned)
/// - NetCDF (planned)
library;

import 'dart:convert';
import '../../ndarray/ndarray.dart';
import '../../datacube/datacube.dart';
import '../../file_helper/file_io.dart';
import '../dcf/dcf_writer.dart';
import '../dcf/dcf_reader.dart';
import '../dcf/format_spec.dart';

/// Format types supported
enum DataFormat {
  hdf5,
  dcf,
  json,
  csv,
  binary,
  parquet,
  mat,
  netcdf,
}

/// Conversion options
class ConversionOptions {
  /// Target format
  final DataFormat targetFormat;

  /// Compression codec
  final CompressionCodec? compression;

  /// Compression level
  final int compressionLevel;

  /// Chunk shape for chunked formats
  final List<int>? chunkShape;

  /// Preserve attributes
  final bool preserveAttributes;

  /// Overwrite existing file
  final bool overwrite;

  const ConversionOptions({
    required this.targetFormat,
    this.compression,
    this.compressionLevel = 6,
    this.chunkShape,
    this.preserveAttributes = true,
    this.overwrite = false,
  });
}

/// Format converter
class FormatConverter {
  /// Convert NDArray between formats
  static Future<void> convertNDArray(
    String sourcePath,
    String targetPath,
    DataFormat sourceFormat,
    ConversionOptions options,
  ) async {
    // Read from source format
    final array = await readNDArray(sourcePath, sourceFormat);

    // Write to target format
    await _writeNDArray(targetPath, array, options);
  }

  /// Convert DataCube between formats
  static Future<void> convertDataCube(
    String sourcePath,
    String targetPath,
    DataFormat sourceFormat,
    ConversionOptions options,
  ) async {
    // Read from source format
    final cube = await readDataCube(sourcePath, sourceFormat);

    // Write to target format
    await _writeDataCube(targetPath, cube, options);
  }

  /// Batch convert multiple files
  static Future<void> convertBatch(
    List<String> sourcePaths,
    String targetDir,
    DataFormat sourceFormat,
    ConversionOptions options,
  ) async {
    for (var sourcePath in sourcePaths) {
      final fileName = sourcePath.split('/').last.split('.').first;
      final extension = _getExtension(options.targetFormat);
      final targetPath = '$targetDir/$fileName.$extension';

      await convertNDArray(sourcePath, targetPath, sourceFormat, options);
    }
  }

  /// Read NDArray from format
  static Future<NDArray> readNDArray(
    String path,
    DataFormat format,
  ) async {
    switch (format) {
      case DataFormat.dcf:
        return await NDArrayDCF.fromDCF(path);

      case DataFormat.json:
        final fileIO = FileIO();
        final jsonStr = await fileIO.readFromFile(path);
        final json = jsonDecode(jsonStr);
        return NDArray.fromFlat(
          (json['data'] as List).map((e) => (e as num).toDouble()).toList(),
          (json['shape'] as List).cast<int>(),
        );

      case DataFormat.binary:
        final fileIO = FileIO();
        final bytes = await fileIO.readBytesFromFile(path);
        // Assume float64 data
        final data = <double>[];
        for (int i = 0; i < bytes.length; i += 8) {
          final buffer = bytes.sublist(i, i + 8);
          // Simple conversion (little-endian)
          data.add(_bytesToDouble(buffer));
        }
        // Shape must be inferred or stored separately
        return NDArray(data);

      case DataFormat.hdf5:
        throw UnimplementedError(
          'HDF5 reading: Use NDArrayHDF5.fromHDF5() directly',
        );

      case DataFormat.csv:
      case DataFormat.parquet:
      case DataFormat.mat:
      case DataFormat.netcdf:
        throw UnimplementedError('Format not yet supported: $format');
    }
  }

  /// Read DataCube from format
  static Future<DataCube> readDataCube(
    String path,
    DataFormat format,
  ) async {
    switch (format) {
      case DataFormat.dcf:
        return await DataCubeDCF.fromDCF(path);

      case DataFormat.json:
        final array = await readNDArray(path, format);
        if (array.ndim != 3) {
          throw ArgumentError('DataCube requires 3D data');
        }
        return DataCube.fromNDArray(array);

      case DataFormat.hdf5:
        throw UnimplementedError(
          'HDF5 reading: Use DataCubeHDF5.fromHDF5() directly',
        );

      case DataFormat.binary:
      case DataFormat.csv:
      case DataFormat.parquet:
      case DataFormat.mat:
      case DataFormat.netcdf:
        throw UnimplementedError('Format not yet supported: $format');
    }
  }

  /// Write NDArray to format
  static Future<void> _writeNDArray(
    String path,
    NDArray array,
    ConversionOptions options,
  ) async {
    switch (options.targetFormat) {
      case DataFormat.dcf:
        await array.toDCF(
          path,
          codec: options.compression ?? CompressionCodec.none,
          compressionLevel: options.compressionLevel,
          chunkShape: options.chunkShape,
        );
        break;

      case DataFormat.json:
        final json = {
          'shape': array.shape.toList(),
          'data': array.toFlatList(),
          if (options.preserveAttributes) 'attributes': array.attrs.toJson(),
        };
        final fileIO = FileIO();
        await fileIO.saveToFile(path, jsonEncode(json));
        break;

      case DataFormat.binary:
        final data = array.toFlatList();
        final bytes = <int>[];
        for (var value in data) {
          bytes.addAll(_doubleToBytes((value as num).toDouble()));
        }
        final fileIO = FileIO();
        await fileIO.writeBytesToFile(path, bytes);
        break;

      case DataFormat.hdf5:
        throw UnimplementedError(
          'HDF5 writing: Use array.toHDF5() directly',
        );

      case DataFormat.csv:
        if (array.ndim != 2) {
          throw ArgumentError('CSV export requires 2D array');
        }
        await _writeCSV(path, array);
        break;

      case DataFormat.parquet:
      case DataFormat.mat:
      case DataFormat.netcdf:
        throw UnimplementedError(
            'Format not yet supported: ${options.targetFormat}');
    }
  }

  /// Write DataCube to format
  static Future<void> _writeDataCube(
    String path,
    DataCube cube,
    ConversionOptions options,
  ) async {
    switch (options.targetFormat) {
      case DataFormat.dcf:
        await cube.toDCF(
          path,
          codec: options.compression ?? CompressionCodec.none,
          compressionLevel: options.compressionLevel,
          chunkShape: options.chunkShape,
        );
        break;

      case DataFormat.json:
        await _writeNDArray(path, cube.data, options);
        break;

      case DataFormat.hdf5:
        throw UnimplementedError(
          'HDF5 writing: Use cube.toHDF5() directly',
        );

      case DataFormat.binary:
        await _writeNDArray(path, cube.data, options);
        break;

      case DataFormat.csv:
      case DataFormat.parquet:
      case DataFormat.mat:
      case DataFormat.netcdf:
        throw UnimplementedError(
            'Format not yet supported: ${options.targetFormat}');
    }
  }

  /// Write CSV file
  static Future<void> _writeCSV(String path, NDArray array) async {
    final rows = <String>[];

    for (int i = 0; i < array.shape[0]; i++) {
      final row = <String>[];
      for (int j = 0; j < array.shape[1]; j++) {
        row.add(array.getValue([i, j]).toString());
      }
      rows.add(row.join(','));
    }

    final fileIO = FileIO();
    await fileIO.saveToFile(path, rows.join('\n'));
  }

  /// Get file extension for format
  static String _getExtension(DataFormat format) {
    switch (format) {
      case DataFormat.hdf5:
        return 'h5';
      case DataFormat.dcf:
        return 'dcf';
      case DataFormat.json:
        return 'json';
      case DataFormat.csv:
        return 'csv';
      case DataFormat.binary:
        return 'bin';
      case DataFormat.parquet:
        return 'parquet';
      case DataFormat.mat:
        return 'mat';
      case DataFormat.netcdf:
        return 'nc';
    }
  }

  /// Helper: bytes to double
  static double _bytesToDouble(List<int> bytes) {
    // Simple little-endian conversion
    int bits = 0;
    for (int i = 0; i < 8; i++) {
      bits |= (bytes[i] << (i * 8));
    }
    // Convert to double (simplified)
    return bits.toDouble();
  }

  /// Helper: double to bytes
  static List<int> _doubleToBytes(double value) {
    final bits = value.toInt();
    final bytes = <int>[];
    for (int i = 0; i < 8; i++) {
      bytes.add((bits >> (i * 8)) & 0xFF);
    }
    return bytes;
  }
}

/// Extension for NDArray format conversion
extension NDArrayFormatConversion on NDArray {
  /// Export to different formats
  Future<void> exportTo(
    String path,
    DataFormat format, {
    CompressionCodec? compression,
    int compressionLevel = 6,
    List<int>? chunkShape,
  }) async {
    final options = ConversionOptions(
      targetFormat: format,
      compression: compression,
      compressionLevel: compressionLevel,
      chunkShape: chunkShape,
    );

    await FormatConverter._writeNDArray(path, this, options);
  }

  /// Convert to JSON
  Future<void> toJSON(String path) async {
    await exportTo(path, DataFormat.json);
  }

  /// Convert to CSV (2D only)
  Future<void> toCSV(String path) async {
    if (ndim != 2) {
      throw ArgumentError('CSV export requires 2D array');
    }
    await exportTo(path, DataFormat.csv);
  }

  /// Convert to binary
  Future<void> toBinary(String path) async {
    await exportTo(path, DataFormat.binary);
  }
}

/// Extension for DataCube format conversion
extension DataCubeFormatConversion on DataCube {
  /// Export to different formats
  Future<void> exportTo(
    String path,
    DataFormat format, {
    CompressionCodec? compression,
    int compressionLevel = 6,
    List<int>? chunkShape,
  }) async {
    final options = ConversionOptions(
      targetFormat: format,
      compression: compression,
      compressionLevel: compressionLevel,
      chunkShape: chunkShape,
    );

    await FormatConverter._writeDataCube(path, this, options);
  }

  /// Convert to JSON
  Future<void> toJSON(String path) async {
    await exportTo(path, DataFormat.json);
  }

  /// Convert to binary
  Future<void> toBinary(String path) async {
    await exportTo(path, DataFormat.binary);
  }
}
