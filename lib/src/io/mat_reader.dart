import 'dart:async';
import '../data_frame/data_frame.dart';
import 'readers.dart';
import 'mat/mat_v73_reader.dart';
import 'mat/matlab_types.dart';

/// Reader for MATLAB .mat files (v7.3 only)
///
/// This class provides a high-level interface for reading MATLAB v7.3 .mat files,
/// which use HDF5 as the underlying storage format.
///
/// **Supported:** MATLAB v7.3 (HDF5-based) files
/// **Not supported:** MATLAB v5, v6, v7 (Level 5 MAT-file format)
///
/// Example:
/// ```dart
/// // Read a specific variable
/// final data = await MATReader.readVariable('data.mat', 'myarray');
///
/// // Read all variables
/// final allVars = await MATReader.readAll('data.mat');
/// print('Variables: ${allVars.keys}');
///
/// // List variables without reading
/// final varNames = await MATReader.listVariables('data.mat');
/// ```
class MATReader implements DataReader {
  @override
  Future<DataFrame> read(String path, {Map<String, dynamic>? options}) async {
    final variableName = options?['variable'] as String?;

    if (variableName == null) {
      throw ArgumentError(
          'Must specify "variable" option to read as DataFrame. '
          'Use readVariable() or readAll() to read raw data.');
    }

    final reader = await MatV73Reader.open(path);
    try {
      // Try to read as DataFrame
      final df = await reader.readAsDataFrame(variableName);
      if (df != null) {
        return df;
      }

      // Fallback: try to convert variable to DataFrame
      final data = await reader.readVariable(variableName);

      if (data is Map) {
        // Structure - convert to DataFrame
        return DataFrame.fromMap(
            data.map((k, v) => MapEntry(k, v is List ? v : [v])));
      } else if (data is List && data.isNotEmpty) {
        // List - wrap in DataFrame
        return DataFrame.fromMap({'data': data});
      } else {
        // Scalar or unsupported - wrap in single-element DataFrame
        return DataFrame.fromMap({
          'value': [data]
        });
      }
    } finally {
      await reader.close();
    }
  }

  /// Read a specific MATLAB variable
  ///
  /// Returns the variable data in appropriate Dart type:
  /// - Numeric arrays → NDArray or List
  /// - Strings → String or `List<String>`
  /// - Logical → `List<bool>`
  /// - Cell array → `List<dynamic>`
  /// - Struct → `Map<String, dynamic>`
  ///
  /// Example:
  /// ```dart
  /// final matrix = await MATReader.readVariable('data.mat', 'A');
  /// final names = await MATReader.readVariable('data.mat', 'names');
  /// ```
  static Future<dynamic> readVariable(String path, String variableName) async {
    final reader = await MatV73Reader.open(path);
    try {
      return await reader.readVariable(variableName);
    } finally {
      await reader.close();
    }
  }

  /// Read all MATLAB variables in the file
  ///
  /// Returns a Map of variable names to their values.
  ///
  /// Example:
  /// ```dart
  /// final allData = await MATReader.readAll('experiment.mat');
  /// print('Variables: ${allData.keys}');
  /// print('Matrix A: ${allData['A']}');
  /// ```
  static Future<Map<String, dynamic>> readAll(String path) async {
    final reader = await MatV73Reader.open(path);
    try {
      return await reader.readAll();
    } finally {
      await reader.close();
    }
  }

  /// List all MATLAB variables in the file
  ///
  /// Returns a list of variable names (excludes internal structures like #refs#).
  ///
  /// Example:
  /// ```dart
  /// final vars = await MATReader.listVariables('data.mat');
  /// for (final varName in vars) {
  ///   print('Found variable: $varName');
  /// }
  /// ```
  static Future<List<String>> listVariables(String path) async {
    final reader = await MatV73Reader.open(path);
    try {
      return reader.listVariables();
    } finally {
      await reader.close();
    }
  }

  /// Get information about a specific variable
  ///
  /// Returns metadata including type, shape, and attributes.
  ///
  /// Example:
  /// ```dart
  /// final info = await MATReader.getVariableInfo('data.mat', 'myarray');
  /// print(info.matlabClass);  // e.g., MatlabClass.double
  /// print(info.shape);         // e.g., [100, 50]
  /// print(info.size);          // e.g., 5000
  /// ```
  static Future<MatlabVariableInfo> getVariableInfo(
    String path,
    String variableName,
  ) async {
    final reader = await MatV73Reader.open(path);
    try {
      return await reader.getVariableInfo(variableName);
    } finally {
      await reader.close();
    }
  }

  /// Inspect the file and return summary information
  ///
  /// Returns a map with file information including:
  /// - 'variables': List of variable names
  /// - 'variableInfo': Map of variable names to their info
  ///
  /// Example:
  /// ```dart
  /// final summary = await MATReader.inspect('data.mat');
  /// print('File contains ${summary['variables'].length} variables');
  /// ```
  static Future<Map<String, dynamic>> inspect(String path) async {
    final reader = await MatV73Reader.open(path);
    try {
      final varNames = reader.listVariables();
      final variableInfo = <String, MatlabVariableInfo>{};

      for (final varName in varNames) {
        try {
          variableInfo[varName] = await reader.getVariableInfo(varName);
        } catch (e) {
          // Skip variables that can't be inspected
          continue;
        }
      }

      return {
        'variables': varNames,
        'variableInfo': variableInfo,
        'variableCount': varNames.length,
      };
    } finally {
      await reader.close();
    }
  }

  /// Check if a file is a MATLAB v7.3 file
  ///
  /// Returns true if the file appears to be MATLAB v7.3 format.
  /// Note: This is a best-effort check based on HDF5 structure and attributes.
  static Future<bool> isMatlabFile(String path) async {
    try {
      final reader = await MatV73Reader.open(path);
      try {
        final varNames = reader.listVariables();
        return varNames.isNotEmpty;
      } finally {
        await reader.close();
      }
    } catch (_) {
      return false;
    }
  }

  /// Read a variable as DataFrame (if compatible)
  ///
  /// Returns null if the variable cannot be converted to a DataFrame.
  /// Best for 2D numeric arrays or structures with same-length fields.
  ///
  /// Example:
  /// ```dart
  /// final df = await MATReader.readAsDataFrame('data.mat', 'matrix');
  /// if (df != null) {
  ///   print(df.head());
  /// }
  /// ```
  static Future<DataFrame?> readAsDataFrame(
    String path,
    String variableName,
  ) async {
    final reader = await MatV73Reader.open(path);
    try {
      return await reader.readAsDataFrame(variableName);
    } finally {
      await reader.close();
    }
  }
}

/// Exception thrown when MATLAB reading fails
class MATReadError extends Error {
  final String message;
  final String? filePath;
  final String? variableName;

  MATReadError(this.message, {this.filePath, this.variableName});

  @override
  String toString() {
    final buffer = StringBuffer('MATReadError: $message');
    if (filePath != null) buffer.write(' (file: $filePath)');
    if (variableName != null) buffer.write(' (variable: $variableName)');
    return buffer.toString();
  }
}
