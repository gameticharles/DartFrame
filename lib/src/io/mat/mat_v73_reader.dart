import 'dart:async';
import '../hdf5/hdf5_file.dart';
import '../../ndarray/ndarray.dart';
import '../../data_frame/data_frame.dart';
import 'matlab_types.dart';
import 'matlab_conventions.dart';
import 'reference_resolver.dart';
import 'sparse_matrix.dart';
import 'matlab_object.dart';

/// Reader for MATLAB v7.3 .mat files
///
/// This class provides low-level reading functionality for MATLAB v7.3 files,
/// which use HDF5 as the underlying storage format.
class MatV73Reader {
  final Hdf5File _file;
  late final ReferenceResolver _refResolver;

  MatV73Reader._(this._file) {
    _refResolver = ReferenceResolver(_file);
  }

  /// Open a MATLAB v7.3 .mat file
  ///
  /// [pathOrData] can be a file path (String) or file data (Uint8List/File input)
  static Future<MatV73Reader> open(dynamic pathOrData,
      {String? fileName}) async {
    final file = await Hdf5File.open(pathOrData, fileName: fileName);

    // Verify it's a MATLAB file (best effort)
    if (!await MatlabConventions.isMatlabFile(file)) {
      // Could still be valid, just no MATLAB attributes found
      // Don't throw error, just warn via debug
      print('[MAT-DEBUG] Warning: File may not be a MATLAB v7.3 file');
    }

    return MatV73Reader._(file);
  }

  /// Close the file and release resources
  Future<void> close() async {
    await _file.close();
    _refResolver.clearCache();
  }

  /// List all MATLAB variables in the file
  ///
  /// Returns variable names (excludes internal groups like #refs#)
  List<String> listVariables() {
    return MatlabConventions.listVariables(_file);
  }

  /// Get information about a specific variable
  ///
  /// Returns metadata including type, shape, and attributes
  Future<MatlabVariableInfo> getVariableInfo(String variableName) async {
    final path = '/$variableName';

    try {
      // Try as dataset first
      final dataset = await _file.dataset(path);
      final shape = dataset.shape;
      final header = dataset.header;

      return MatlabConventions.getVariableInfo(variableName, header, shape);
    } catch (_) {
      // Try as group (for structures)
      try {
        final group = await _file.group(path);
        final header = group.header;

        return MatlabConventions.getVariableInfo(
            variableName, header, [1]); // Scalar struct
      } catch (e) {
        throw MatlabFileFormatError(
            'Variable "$variableName" not found in file: $e');
      }
    }
  }

  /// Read a MATLAB variable
  ///
  /// Returns the appropriate Dart type based on MATLAB class:
  /// - Numeric arrays → NDArray or List
  /// - Strings → String or List`<String>`
  /// - Logical → List`<bool>`
  /// - Cell array → List`<dynamic>`
  /// - Struct → Map`<String, dynamic>`
  Future<dynamic> readVariable(String variableName) async {
    final info = await getVariableInfo(variableName);

    switch (info.matlabClass) {
      case MatlabClass.double:
      case MatlabClass.single:
      case MatlabClass.int8:
      case MatlabClass.int16:
      case MatlabClass.int32:
      case MatlabClass.int64:
      case MatlabClass.uint8:
      case MatlabClass.uint16:
      case MatlabClass.uint32:
      case MatlabClass.uint64:
        return await _readNumericVariable(variableName, info);

      case MatlabClass.char:
      case MatlabClass.string:
        return await _readStringVariable(variableName, info);

      case MatlabClass.logical:
        return await _readLogicalVariable(variableName, info);

      case MatlabClass.cell:
        return await _readCellArray(variableName, info);

      case MatlabClass.struct:
        return await _readStructure(variableName, info);

      case MatlabClass.sparse:
        return await _readSparseMatrix(variableName, info);

      case MatlabClass.object:
        // MATLAB objects/classes - read as MatlabObject
        return await _readMatlabObject(variableName, info);

      default:
        throw UnsupportedMatlabTypeError(
            info.matlabClass, 'Type not supported in Phase 1');
    }
  }

  /// Read all variables into a Map
  ///
  /// Returns `Map<variableName, value>`
  Future<Map<String, dynamic>> readAll() async {
    final result = <String, dynamic>{};
    final varNames = listVariables();

    for (final varName in varNames) {
      try {
        result[varName] = await readVariable(varName);
      } catch (e) {
        print('[MAT-DEBUG] Warning: Failed to read variable "$varName": $e');
        // Continue with other variables
      }
    }

    return result;
  }

  // Private helper methods

  Future<dynamic> _readNumericVariable(
      String variableName, MatlabVariableInfo info) async {
    final data = await _file.readDataset('/$variableName');

    // Reshape if needed (MATLAB is column-major)
    final reshapedData = MatlabConventions.reshapeData(data, info.shape);

    // Return as NDArray for multi-dimensional data
    if (info.shape.length > 1) {
      return NDArray.fromFlat(reshapedData, info.shape);
    }

    return reshapedData; // 1D list
  }

  Future<dynamic> _readStringVariable(
      String variableName, MatlabVariableInfo info) async {
    final data = await _file.readDataset('/$variableName');

    if (data is String) {
      return data;
    }

    // Character array
    if (info.shape.length == 1 ||
        (info.shape.length == 2 && info.shape[0] == 1)) {
      // 1D or row vector - single string
      return MatlabConventions.charArrayToString(data);
    } else {
      // Multiple strings (each row is a string)
      final rows = info.shape[0];
      final cols = info.shape.length > 1 ? info.shape[1] : data.length;
      final strings = <String>[];

      for (int i = 0; i < rows; i++) {
        final rowData = data.skip(i * cols).take(cols).toList();
        strings.add(MatlabConventions.charArrayToString(rowData));
      }

      return strings;
    }

    return data.toString();
  }

  Future<List<bool>> _readLogicalVariable(
      String variableName, MatlabVariableInfo info) async {
    final data = await _file.readDataset('/$variableName');

    final dataList = data;
    return MatlabConventions.logicalToBoolList(dataList);
  }

  Future<List<dynamic>> _readCellArray(
      String variableName, MatlabVariableInfo info) async {
    final dataset = await _file.dataset('/$variableName');

    // Check if this dataset contains object references
    if (MatlabConventions.isObjectReferenceType(dataset)) {
      // Cell array with references - resolve them
      return await _refResolver.resolveCellArray(dataset);
    } else {
      // Simple cell array (rare in v7.3)
      final data = await _file.readDataset('/$variableName');
      return data;
    }
  }

  Future<dynamic> _readStructure(
      String variableName, MatlabVariableInfo info) async {
    final structPath = '/$variableName';

    // Check if this is a structure array (multiple structs)
    final isArray = await MatlabConventions.isStructureArray(_file, structPath);

    if (isArray) {
      return await _readStructureArray(variableName, info);
    }

    // Read single structure (original behavior)
    try {
      final group = await _file.group(structPath);
      final result = <String, dynamic>{};

      // Read each field
      final fields = info.fields ?? group.children;

      for (final fieldName in fields) {
        try {
          final fieldPath = '$structPath/$fieldName';

          // Try to read as dataset
          try {
            final fieldData = await _file.readDataset(fieldPath);
            result[fieldName] = fieldData;
          } catch (_) {
            // Try as nested structure - recursive read
            final nestedData = await readVariable(fieldPath.substring(1));
            result[fieldName] = nestedData;
          }
        } catch (e) {
          print('[MAT-DEBUG] Warning: Failed to read field "$fieldName": $e');
        }
      }

      return result;
    } catch (e) {
      throw MatlabFileFormatError(
          'Failed to read structure "$variableName": $e');
    }
  }

  Future<List<Map<String, dynamic>>> _readStructureArray(
      String variableName, MatlabVariableInfo info) async {
    final structPath = '/$variableName';
    final length =
        await MatlabConventions.getStructureArrayLength(_file, structPath);

    final result = <Map<String, dynamic>>[];

    for (int i = 0; i < length; i++) {
      final elemPath = '$structPath/$i';

      try {
        final elemGroup = await _file.group(elemPath);
        final elemData = <String, dynamic>{};

        // Read fields for this array element
        final fields = info.fields ?? elemGroup.children;

        for (final fieldName in fields) {
          final fieldPath = '$elemPath/$fieldName';

          try {
            final fieldData = await _file.readDataset(fieldPath);
            elemData[fieldName] = fieldData;
          } catch (_) {
            // Field might be nested structure
            try {
              final nestedData = await readVariable(fieldPath.substring(1));
              elemData[fieldName] = nestedData;
            } catch (e) {
              print(
                  '[MAT-DEBUG] Warning: Failed to read field "$fieldName" in struct($i): $e');
            }
          }
        }

        result.add(elemData);
      } catch (e) {
        print(
            '[MAT-DEBUG] Warning: Failed to read struct array element $i: $e');
      }
    }

    return result;
  }

  Future<SparseMatrix> _readSparseMatrix(
      String variableName, MatlabVariableInfo info) async {
    // Sparse matrices in MATLAB v7.3 are stored as groups with subfields:
    // /<varname>/data - non-zero values
    // /<varname>/ir - row indices
    // /<varname>/jc - column pointers

    final basePath = '/$variableName';

    try {
      // Read sparse matrix components
      final data = await _file.readDataset('$basePath/data');
      final ir = await _file.readDataset('$basePath/ir');
      final jc = await _file.readDataset('$basePath/jc');

      // Convert to int lists for indices
      final rowIndices = ir.cast<int>();
      final colPointers = jc.cast<int>();
      final dataList = data;

      return SparseMatrix(
        data: dataList,
        rowIndices: rowIndices,
        colPointers: colPointers,
        shape: info.shape,
        dataClass: info.matlabClass,
      );
    } catch (e) {
      throw MatlabFileFormatError(
          'Failed to read sparse matrix "$variableName": $e');
    }
  }

  Future<MatlabObject> _readMatlabObject(
      String variableName, MatlabVariableInfo info) async {
    // MATLAB objects are stored as structures with a class name
    final structData = await _readStructure(variableName, info);

    // Convert to MatlabObject
    final properties =
        structData is Map<String, dynamic> ? structData : {'value': structData};

    return MatlabObject(
      className: info.className ?? 'unknown',
      properties: properties,
    );
  }

  /// Read variable as DataFrame (if applicable)
  ///
  /// Best for 2D numeric arrays or structures
  Future<DataFrame?> readAsDataFrame(String variableName) async {
    final info = await getVariableInfo(variableName);

    if (info.matlabClass.isNumeric && info.shape.length == 2) {
      // 2D numeric array - can convert to DataFrame
      final array = await _readNumericVariable(variableName, info) as NDArray;

      // Create column names
      final cols = info.shape[1];
      final columns = List.generate(cols, (i) => 'col_$i');

      // Convert to column-oriented data
      final rows = info.shape[0];
      final columnData = <String, List<dynamic>>{};

      for (int col = 0; col < cols; col++) {
        final colData = <dynamic>[];
        for (int row = 0; row < rows; row++) {
          colData.add(array[[row, col]]);
        }
        columnData[columns[col]] = colData;
      }

      return DataFrame.fromMap(columnData);
    }

    if (info.matlabClass == MatlabClass.struct) {
      // Structure might be convertible to DataFrame
      // if all fields are same-length arrays
      final structData = await _readStructure(variableName, info);

      try {
        return DataFrame.fromMap(
            structData.map((k, v) => MapEntry(k, v is List ? v : [v])));
      } catch (_) {
        return null; // Can't convert to DataFrame
      }
    }

    return null; // Not convertible to DataFrame
  }

  /// Get reference resolver (for advanced use)
  ReferenceResolver get refResolver => _refResolver;

  /// Get underlying HDF5 file (for advanced use)
  Hdf5File get hdf5File => _file;
}
