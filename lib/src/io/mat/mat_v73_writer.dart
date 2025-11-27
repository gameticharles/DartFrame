import '../../ndarray/ndarray.dart';
import '../hdf5/hdf5_file_builder.dart';
import '../hdf5/file_writer.dart';
import '../hdf5/write_options.dart';
import 'matlab_types.dart';
import 'matlab_attribute_writer.dart';
import 'matlab_object.dart';
import 'sparse_matrix.dart';

/// Writer for MATLAB v7.3 .mat files
///
/// This class provides functionality to create MATLAB-compatible HDF5 files
/// with proper MATLAB attributes and conventions.
///
/// Example:
/// ```dart
/// // Write a simple numeric array
/// await MATWriter.writeVariable('output.mat', 'myArray', [1, 2, 3, 4, 5]);
///
/// // Write multiple variables
/// await MATWriter.writeAll('data.mat', {
///   'temperature': [20.5, 21.0, 19.8],
///   'humidity': [65, 68, 62],
///   'label': 'Sensor Data',
/// });
/// ```
class MatV73Writer {
  // Reference counter for cell arrays and complex structures
  int _refCounter = 0;
  final Map<String, dynamic> _pendingReferences = {};

  MatV73Writer._();

  /// Create a new MATLAB v7.3 file writer
  static MatV73Writer create() {
    return MatV73Writer._();
  }

  /// Write a single variable to a MATLAB file
  ///
  /// [filePath] - Output `.mat` file path
  /// [variableName] - MATLAB variable name
  /// [data] - Data to write (supports various types)
  /// [append] - If true, append to existing file (placeholder for future)
  ///
  /// Currently creates a new file each time. Appending will be supported later.
  Future<void> writeVariable(
    String filePath,
    String variableName,
    dynamic data, {
    bool append = false,
  }) async {
    if (append) {
      throw UnimplementedError('Append mode not yet implemented');
    }

    // Write single variable as a simple file with one dataset
    await writeAll(filePath, {variableName: data});
  }

  /// Write multiple variables to a MATLAB file
  ///
  /// [filePath] - Output `.mat` file path
  /// [variables] - Map of variable names to data
  ///
  /// Example:
  /// ```dart
  /// await writer.writeAll('output.mat', {
  ///   'A': [[1,2], [3, 4]],
  ///   'B': 'hello',
  ///   'C': {'field1': 1, 'field2': 'test'},
  /// });
  /// ```
  Future<void> writeAll(
    String filePath,
    Map<String, dynamic> variables,
  ) async {
    if (variables.isEmpty) {
      throw ArgumentError('Cannot write empty variable map');
    }

    // Reset reference counter for new file
    _refCounter = 0;
    _pendingReferences.clear();

    // Use HDF5FileBuilder directly for group support
    final builder = HDF5FileBuilder();

    // Process each variable
    for (final entry in variables.entries) {
      final varName = entry.key;
      final varData = entry.value;

      // Validate variable name
      _validateVariableName(varName);

      // Write variable using builder (supports groups)
      await _writeVariableToBuilder(builder, varName, varData);
    }

    // Write all pending references if any were created
    if (_pendingReferences.isNotEmpty) {
      // Create #refs# group
      await builder.createGroup('/#refs#');

      for (final entry in _pendingReferences.entries) {
        final refName = entry.key;
        final refData = entry.value;

        await _writeVariableToBuilder(
          builder,
          '#refs#/$refName',
          refData,
          isReference: true,
        );
      }
    }

    // Build and write the file
    try {
      final bytes = await builder.buildMultiple();
      await FileWriter.writeToFile(filePath, bytes);
    } catch (e) {
      throw MatlabFileFormatError('Failed to write MATLAB file: $e');
    }
  }

  /// Write a variable to the HDF5 file builder
  ///
  /// Handles all MATLAB data types including groups for structures and sparse
  Future<void> _writeVariableToBuilder(
    HDF5FileBuilder builder,
    String varName,
    dynamic data, {
    bool isReference = false,
  }) async {
    final basePath = isReference ? '/$varName' : '/$varName';

    // Handle different data types
    if (data is NDArray) {
      await _writeNumericArray(builder, basePath, data);
    } else if (data is List && _isNumericList(data)) {
      final array = NDArray.fromFlat(data, [data.length]);
      await _writeNumericArray(builder, basePath, array);
    } else if (data is String) {
      await _writeString(builder, basePath, data);
    } else if (data is List<String>) {
      await _writeCellArray(builder, basePath, data);
    } else if (data is List<bool>) {
      await _writeLogicalArray(builder, basePath, data);
    } else if (data is bool) {
      await _writeLogicalArray(builder, basePath, [data]);
    } else if (data is List && !_isNumericList(data)) {
      await _writeCellArray(builder, basePath, data);
    } else if (data is Map<String, dynamic>) {
      await _writeStructure(builder, basePath, data);
    } else if (data is List<Map<String, dynamic>>) {
      await _writeStructureArray(builder, basePath, data);
    } else if (data is SparseMatrix) {
      await _writeSparseMatrix(builder, basePath, data);
    } else if (data is MatlabObject) {
      await _writeMatlabObject(builder, basePath, data);
    } else {
      // Try to convert to numeric
      try {
        final numData = NDArray.generate([1], (_) => data);
        await _writeNumericArray(builder, basePath, numData);
      } catch (_) {
        throw MatlabFileFormatError(
          'Unsupported data type for variable "$varName": ${data.runtimeType}',
        );
      }
    }
  }

  /// Write numeric array to builder
  Future<void> _writeNumericArray(
    HDF5FileBuilder builder,
    String path,
    NDArray array,
  ) async {
    // Get flat data and infer MATLAB class
    final flatData = <dynamic>[];
    for (int i = 0; i < array.size; i++) {
      flatData.add(array[i]);
    }
    final matlabClass = _inferMatlabClass(flatData);

    final attributes = MatlabAttributeWriter.createMatlabAttributes(
      matlabClass: matlabClass,
    );

    await builder.addDataset(
      path,
      array,
      options: WriteOptions(attributes: attributes),
    );
  }

  /// Write string to builder
  Future<void> _writeString(
    HDF5FileBuilder builder,
    String path,
    String str,
  ) async {
    final charData = str.codeUnits;

    final attributes = MatlabAttributeWriter.createMatlabAttributes(
      matlabClass: MatlabClass.char,
    );

    final array = NDArray.fromFlat(charData, [charData.length]);

    await builder.addDataset(
      path,
      array,
      options: WriteOptions(attributes: attributes),
    );
  }

  /// Write logical array to builder
  Future<void> _writeLogicalArray(
    HDF5FileBuilder builder,
    String path,
    List<bool> bools,
  ) async {
    final data = bools.map((b) => b ? 1 : 0).toList();

    final attributes = MatlabAttributeWriter.createMatlabAttributes(
      matlabClass: MatlabClass.logical,
    );

    final array = NDArray.fromFlat(data, [data.length]);

    await builder.addDataset(
      path,
      array,
      options: WriteOptions(attributes: attributes),
    );
  }

  /// Write cell array to builder
  ///
  /// Cell arrays in MATLAB v7.3 use object references stored in a group
  Future<void> _writeCellArray(
    HDF5FileBuilder builder,
    String path,
    List<dynamic> cells,
  ) async {
    // Create a group for the cell array
    await builder.createGroup(path);

    // Add MATLAB_class attribute to the group
    final attributes = MatlabAttributeWriter.createMatlabAttributes(
      matlabClass: MatlabClass.cell,
    );

    // MATLAB stores cell array dimensions
    // For simplicity, treating as 1D array with N elements
    final dimsArray = NDArray.fromFlat([cells.length], [1]);
    await builder.addDataset(
      '$path/dims',
      dimsArray,
      options: WriteOptions(attributes: attributes),
    );

    // Write each cell element as a dataset
    for (int i = 0; i < cells.length; i++) {
      final cellPath = '$path/cell_$i';
      await _writeVariableToBuilder(builder, cellPath.substring(1), cells[i],
          isReference: true);
    }
  }

  /// Write structure to builder
  ///
  /// Structures are groups with field datasets
  Future<void> _writeStructure(
    HDF5FileBuilder builder,
    String path,
    Map<String, dynamic> struct,
  ) async {
    // Create a group for the structure
    await builder.createGroup(path);

    // Add MATLAB_class attribute
    final structAttrs = MatlabAttributeWriter.createMatlabAttributes(
      matlabClass: MatlabClass.struct,
      structFields: struct.keys.toList(),
    );

    // Write a marker dataset with struct metadata
    final markerArray = NDArray.fromFlat([1], [1]);
    await builder.addDataset(
      '$path/__struct_marker__',
      markerArray,
      options: WriteOptions(attributes: structAttrs),
    );

    // Write each field as a dataset
    for (final entry in struct.entries) {
      final fieldPath = '$path/${entry.key}';
      await _writeVariableToBuilder(
          builder, fieldPath.substring(1), entry.value);
    }
  }

  /// Write structure array to builder
  Future<void> _writeStructureArray(
    HDF5FileBuilder builder,
    String path,
    List<Map<String, dynamic>> structs,
  ) async {
    if (structs.isEmpty) {
      throw MatlabFileFormatError('Cannot write empty structure array');
    }

    // Get all unique field names
    final allFields = <String>{};
    for (final struct in structs) {
      allFields.addAll(struct.keys);
    }

    // Create a group for the structure array
    await builder.createGroup(path);

    // Add MATLAB_class attribute
    final attrs = MatlabAttributeWriter.createMatlabAttributes(
      matlabClass: MatlabClass.struct,
      structFields: allFields.toList(),
    );

    // Write dimensions
    final dimsArray = NDArray.fromFlat([structs.length], [1]);
    await builder.addDataset(
      '$path/dims',
      dimsArray,
      options: WriteOptions(attributes: attrs),
    );

    // Write each structure as a subgroup
    for (int i = 0; i < structs.length; i++) {
      final structPath = '$path/struct_$i';
      await _writeStructure(builder, structPath, structs[i]);
    }
  }

  /// Write sparse matrix to builder
  ///
  /// Sparse matrices use CSC format with ir, jc, data fields
  Future<void> _writeSparseMatrix(
    HDF5FileBuilder builder,
    String path,
    SparseMatrix sparse,
  ) async {
    // Create a group for the sparse matrix
    await builder.createGroup(path);

    // Add MATLAB_class attribute (sparse)
    final attributes = MatlabAttributeWriter.createMatlabAttributes(
      matlabClass: MatlabClass.double,
      isSparse: true,
    );

    // Write dimensions [rows, cols]
    final dimsArray = NDArray.fromFlat([sparse.rows, sparse.cols], [2]);
    await builder.addDataset(
      '$path/dims',
      dimsArray,
      options: WriteOptions(attributes: attributes),
    );

    // Write IR (row indices)
    final irArray =
        NDArray.fromFlat(sparse.rowIndices, [sparse.rowIndices.length]);
    await builder.addDataset(
      '$path/ir',
      irArray,
      options: const WriteOptions(),
    );

    // Write JC (column pointers)
    final jcArray =
        NDArray.fromFlat(sparse.colPointers, [sparse.colPointers.length]);
    await builder.addDataset(
      '$path/jc',
      jcArray,
      options: const WriteOptions(),
    );

    // Write data values
    final dataArray = NDArray.fromFlat(sparse.data, [sparse.data.length]);
    await builder.addDataset(
      '$path/data',
      dataArray,
      options: const WriteOptions(),
    );

    // Write nzmax (maximum number of nonzeros)
    final nzmaxArray = NDArray.fromFlat([sparse.data.length], [1]);
    await builder.addDataset(
      '$path/nzmax',
      nzmaxArray,
      options: const WriteOptions(),
    );
  }

  /// Write MATLAB object to builder
  ///
  /// Objects are structures with a CLASSNAME attribute
  Future<void> _writeMatlabObject(
    HDF5FileBuilder builder,
    String path,
    MatlabObject obj,
  ) async {
    // Create a group for the object
    await builder.createGroup(path);

    // Add MATLAB_class and CLASSNAME attributes
    final attrs = MatlabAttributeWriter.createMatlabAttributes(
      matlabClass: MatlabClass.struct,
      structFields: obj.properties.keys.toList(),
    );

    // Add CLASSNAME to attributes
    final fullAttrs = Map<String, dynamic>.from(attrs);
    fullAttrs['CLASSNAME'] = obj.className;

    // Write marker dataset with object metadata
    final markerArray = NDArray.fromFlat([1], [1]);
    await builder.addDataset(
      '$path/__object_marker__',
      markerArray,
      options: WriteOptions(attributes: fullAttrs),
    );

    // Write each property as a dataset
    for (final entry in obj.properties.entries) {
      final propPath = '$path/${entry.key}';
      await _writeVariableToBuilder(
          builder, propPath.substring(1), entry.value);
    }
  }

  /// Infer MATLAB class from data
  MatlabClass _inferMatlabClass(List<dynamic> data) {
    if (data.isEmpty) return MatlabClass.double;

    final first = data.first;
    if (first is double || first is num) {
      return MatlabClass.double;
    } else if (first is int) {
      // Check magnitude to determine int type
      final maxVal =
          data.whereType<int>().reduce((a, b) => a.abs() > b.abs() ? a : b);
      if (maxVal.abs() <= 127) return MatlabClass.int8;
      if (maxVal.abs() <= 32767) return MatlabClass.int16;
      return MatlabClass.int32;
    }

    return MatlabClass.double; // Default
  }

  /// Check if list contains only numeric values
  bool _isNumericList(List<dynamic> list) {
    if (list.isEmpty) return true;
    return list.every((item) => item is num);
  }

  /// Validate MATLAB variable name
  void _validateVariableName(String name) {
    if (name.isEmpty) {
      throw ArgumentError('Variable name cannot be empty');
    }

    // MATLAB variable names must start with a letter
    if (!RegExp(r'^[a-zA-Z]').hasMatch(name)) {
      throw ArgumentError(
        'Variable name must start with a letter: "$name"',
      );
    }

    // Can only contain letters, numbers, and underscores
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name)) {
      throw ArgumentError(
        'Variable name can only contain letters, numbers, and underscores: "$name"',
      );
    }

    // Maximum 63 characters (MATLAB limit)
    if (name.length > 63) {
      throw ArgumentError(
        'Variable name too long (max 63 characters): "$name"',
      );
    }
  }
}
