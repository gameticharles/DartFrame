/// Writer for MATLAB .mat files (v7.3)
///
/// **Status**: Not yet implemented. Placeholder for Phase 2.
library;

import 'dart:async';
import 'mat/mat_v73_writer.dart';

/// Public API for writing MATLAB v7.3 .mat files
///
/// This class provides a high-level interface for creating MATLAB-compatible
/// HDF5 files from Dart data structures.
///
/// Example:
/// ```dart
/// // Write a single variable
/// await MATWriter.writeVariable('output.mat', 'myData', [1, 2, 3, 4, 5]);
///
/// // Write multiple variables
/// await MATWriter.writeAll('data.mat', {
///   'temperature': [20.5, 21.0, 19.8],
///   'humidity': [65, 68, 62],
///   'label': 'Sensor Data',
/// });
/// ```
///
/// **Supported Data Types** (Phase 3 Sprint 1):
/// - Numeric arrays (int, double, NDArray)
/// - Strings (single and arrays)
/// - Logical arrays (bool lists)
///
/// **Coming Soon**:
/// - Cell arrays
/// - Structures
/// - Sparse matrices
/// - MATLAB objects
class MATWriter {
  MATWriter._(); // Private constructor - use static methods

  /// Write a single variable to a MATLAB file
  ///
  /// [filePath] - Output `.mat` file path
  /// [variableName] - MATLAB variable name
  /// [data] - Data to write
  ///
  /// Example:
  /// ```dart
  /// await MATWriter.writeVariable('output.mat', 'A', [1, 2, 3]);
  /// ```
  static Future<void> writeVariable(
    String filePath,
    String variableName,
    dynamic data,
  ) async {
    final writer = MatV73Writer.create();
    await writer.writeVariable(filePath, variableName, data);
  }

  /// Write multiple variables to a MATLAB file
  ///
  /// [filePath] - Output `.mat` file path
  /// [variables] - Map of variable names to data
  ///
  /// Example:
  /// ```dart
  /// await MATWriter.writeAll('data.mat', {
  ///   'matrix': [[1, 2], [3, 4]],
  ///   'label': 'Test Data',
  /// });
  /// ```
  static Future<void> writeAll(
    String filePath,
    Map<String, dynamic> variables,
  ) async {
    final writer = MatV73Writer.create();
    await writer.writeAll(filePath, variables);
  }

  /// Create a writer instance for advanced usage
  ///
  /// Most users should use the static methods instead.
  static MatV73Writer createWriter() {
    return MatV73Writer.create();
  }
}
