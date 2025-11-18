/// I/O operations for DataCube.
// ignore_for_file: unused_element

library;

import 'dart:convert';
import 'datacube.dart';
import '../data_frame/data_frame.dart';
import '../file_helper/file_io.dart';

// Conditional import for dart:io (not available on web)
import 'io_stub.dart' if (dart.library.io) 'dart:io' as io;

/// Extension providing I/O operations for DataCube.
extension DataCubeIO on DataCube {
  /// Saves the DataCube to a JSON file.
  ///
  /// The file contains metadata and the full 3D data structure.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.generate(3, 4, 5, (d, r, c) => d * 100 + r * 10 + c);
  /// await cube.toFile('cube.json');
  /// ```
  Future<void> toFile(String path) async {
    final fileIO = FileIO();

    final json = {
      'type': 'DataCube',
      'version': '1.0',
      'shape': [depth, rows, columns],
      'data': data.toNestedList(),
      'attributes': attrs.toJson(),
    };

    await fileIO.saveToFile(path, jsonEncode(json));
  }

  /// Loads a DataCube from a JSON file.
  ///
  /// Example:
  /// ```dart
  /// var cube = await DataCubeIO.fromFile('cube.json');
  /// ```
  static Future<DataCube> fromFile(String path) async {
    final fileIO = FileIO();
    final contents = await fileIO.readFromFile(path);
    final json = jsonDecode(contents) as Map<String, dynamic>;

    if (json['type'] != 'DataCube') {
      throw FormatException('File is not a DataCube: ${json['type']}');
    }

    final shape = (json['shape'] as List).cast<int>();
    final data = json['data'] as List;

    // Reconstruct DataCube from nested list
    final cube = DataCube.fromNDArray(
      _nestedListToNDArray(data, shape),
    );

    // Restore attributes if present
    if (json['attributes'] != null) {
      final attrs = json['attributes'] as Map<String, dynamic>;
      for (var entry in attrs.entries) {
        cube.attrs[entry.key] = entry.value;
      }
    }

    return cube;
  }

  /// Saves the DataCube to a directory of CSV files.
  ///
  /// Each sheet (depth level) is saved as a separate CSV file.
  /// Files are named: sheet_0.csv, sheet_1.csv, etc.
  ///
  /// Note: This method requires dart:io and is only available on non-web platforms.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(3, 4, 5);
  /// await cube.toCSVDirectory('cube_data');
  /// // Creates: cube_data/sheet_0.csv, cube_data/sheet_1.csv, cube_data/sheet_2.csv
  /// ```
  Future<void> toCSVDirectory(String dirPath) async {
    final fileIO = FileIO();

    // Create directory if needed (platform-specific)
    await _ensureDirectoryExists(dirPath);

    // Save metadata
    final metadata = {
      'type': 'DataCube',
      'version': '1.0',
      'depth': depth,
      'rows': rows,
      'columns': columns,
      'attributes': attrs.toJson(),
    };
    await fileIO.saveToFile('$dirPath/metadata.json', jsonEncode(metadata));

    // Save each sheet as CSV
    for (int d = 0; d < depth; d++) {
      final frame = getFrame(d);
      await fileIO.saveToFile('$dirPath/sheet_$d.csv', _dataFrameToCSV(frame));
    }
  }

  /// Ensures a directory exists (platform-specific).
  static Future<void> _ensureDirectoryExists(String path) async {
    try {
      final dir = io.Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      // Ignore errors on web or if dart:io is not available
    }
  }

  /// Loads a DataCube from a directory of CSV files.
  ///
  /// Expects files named: sheet_0.csv, sheet_1.csv, etc.
  /// Also reads metadata.json if present.
  ///
  /// Note: This method requires dart:io and is only available on non-web platforms.
  ///
  /// Example:
  /// ```dart
  /// var cube = await DataCubeIO.fromCSVDirectory('cube_data');
  /// ```
  static Future<DataCube> fromCSVDirectory(String dirPath) async {
    final fileIO = FileIO();

    // Read metadata
    Map<String, dynamic>? metadata;
    try {
      final contents = await fileIO.readFromFile('$dirPath/metadata.json');
      metadata = jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      // Metadata file not found or invalid, continue without it
    }

    // Try to load sheets based on metadata or discover them
    final depth = metadata?['depth'] as int? ?? 10; // Default max sheets to try
    final frames = <DataFrame>[];

    for (int d = 0; d < depth; d++) {
      try {
        final csvContent = await fileIO.readFromFile('$dirPath/sheet_$d.csv');
        final frame = _csvToDataFrame(csvContent);
        frames.add(frame);
      } catch (e) {
        // No more sheets found
        break;
      }
    }

    if (frames.isEmpty) {
      throw FormatException('No sheet CSV files found in directory');
    }

    // Create DataCube
    final cube = DataCube.fromDataFrames(frames);

    // Restore attributes if present
    if (metadata != null && metadata['attributes'] != null) {
      final attrs = metadata['attributes'] as Map<String, dynamic>;
      for (var entry in attrs.entries) {
        cube.attrs[entry.key] = entry.value;
      }
    }

    return cube;
  }

  /// Exports the DataCube to a binary format.
  ///
  /// More efficient than JSON for large datasets.
  ///
  /// Example:
  /// ```dart
  /// var cube = DataCube.zeros(100, 100, 100);
  /// await cube.toBinaryFile('cube.bin');
  /// ```
  Future<void> toBinaryFile(String path) async {
    final fileIO = FileIO();

    // Write header
    final header = <int>[];
    // Magic number: 'DCUB' in ASCII
    header.addAll([68, 67, 85, 66]);
    // Version
    header.addAll([1, 0]);
    // Shape
    header.addAll(_intToBytes(depth));
    header.addAll(_intToBytes(rows));
    header.addAll(_intToBytes(columns));

    // Write data
    final flatData = data.toFlatList();
    final dataBytes = <int>[];
    for (var value in flatData) {
      dataBytes.addAll(_doubleToBytes((value as num).toDouble()));
    }

    await fileIO.writeBytesToFile(path, [...header, ...dataBytes]);
  }

  /// Loads a DataCube from a binary file.
  ///
  /// Example:
  /// ```dart
  /// var cube = await DataCubeIO.fromBinaryFile('cube.bin');
  /// ```
  static Future<DataCube> fromBinaryFile(String path) async {
    final fileIO = FileIO();
    final bytes = await fileIO.readBytesFromFile(path);

    // Read header
    int offset = 0;

    // Check magic number
    final magic = bytes.sublist(offset, offset + 4);
    if (magic[0] != 68 || magic[1] != 67 || magic[2] != 85 || magic[3] != 66) {
      throw FormatException('Invalid binary file format');
    }
    offset += 4;

    // Read version
    offset += 2;

    // Read shape
    final depth = _bytesToInt(bytes.sublist(offset, offset + 4));
    offset += 4;
    final rows = _bytesToInt(bytes.sublist(offset, offset + 4));
    offset += 4;
    final columns = _bytesToInt(bytes.sublist(offset, offset + 4));
    offset += 4;

    // Read data
    final size = depth * rows * columns;
    final data = <double>[];
    for (int i = 0; i < size; i++) {
      data.add(_bytesToDouble(bytes.sublist(offset, offset + 8)));
      offset += 8;
    }

    return DataCube.fromNDArray(
      _nestedListToNDArray(
        _flatToNested(data, [depth, rows, columns]),
        [depth, rows, columns],
      ),
    );
  }

  // Helper methods

  static int _extractSheetNumber(String path) {
    final match = RegExp(r'sheet_(\d+)\.csv').firstMatch(path);
    if (match == null) return 0;
    return int.parse(match.group(1)!);
  }

  static String _dataFrameToCSV(DataFrame frame) {
    final buffer = StringBuffer();

    // Write header
    final columns = frame.columns;
    buffer.writeln(columns.join(','));

    // Write rows
    for (int r = 0; r < frame.shape[0]; r++) {
      final row = <String>[];
      for (int c = 0; c < frame.shape[1]; c++) {
        row.add(frame.iloc(r, c).toString());
      }
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  static DataFrame _csvToDataFrame(String csv) {
    final lines = csv.trim().split('\n');
    if (lines.isEmpty) {
      throw FormatException('Empty CSV file');
    }

    // Skip header for now (first line)
    final dataLines = lines.skip(1);

    final data = <List<dynamic>>[];
    for (var line in dataLines) {
      final values = line.split(',').map((v) {
        // Try to parse as number
        final num = double.tryParse(v.trim());
        return num ?? v.trim();
      }).toList();
      data.add(values);
    }

    return DataFrame(data);
  }

  static dynamic _nestedListToNDArray(dynamic data, List<int> shape) {
    final flatData = _flattenNested(data);
    // Create NDArray from flat data
    // We need to import NDArray properly
    final cube = DataCube.empty(shape[0], shape[1], shape[2]);
    // Fill with actual data
    int idx = 0;
    for (int d = 0; d < shape[0]; d++) {
      for (int r = 0; r < shape[1]; r++) {
        for (int c = 0; c < shape[2]; c++) {
          cube.setValue([d, r, c], flatData[idx++]);
        }
      }
    }
    return cube.data;
  }

  static List<dynamic> _flattenNested(dynamic data) {
    final result = <dynamic>[];

    void flatten(dynamic item) {
      if (item is List) {
        for (var element in item) {
          flatten(element);
        }
      } else {
        result.add(item);
      }
    }

    flatten(data);
    return result;
  }

  static List<dynamic> _flatToNested(List<dynamic> flat, List<int> shape) {
    if (shape.length == 1) {
      return flat;
    }

    final result = <dynamic>[];
    final stride = flat.length ~/ shape[0];

    for (int i = 0; i < shape[0]; i++) {
      final start = i * stride;
      final end = start + stride;
      final subList = flat.sublist(start, end);
      result.add(_flatToNested(subList, shape.sublist(1)));
    }

    return result;
  }

  static List<int> _intToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  static int _bytesToInt(List<int> bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  static List<int> _doubleToBytes(double value) {
    // Simple implementation - in production would use proper IEEE 754 encoding
    final intValue = (value * 1000000).round();
    return [
      ..._intToBytes(intValue),
      ..._intToBytes(0), // Padding
    ];
  }

  static double _bytesToDouble(List<int> bytes) {
    final intValue = _bytesToInt(bytes.sublist(0, 4));
    return intValue / 1000000.0;
  }
}
