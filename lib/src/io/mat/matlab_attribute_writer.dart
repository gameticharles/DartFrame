import 'matlab_types.dart';

/// Utilities for writing MATLAB-specific attributes to HDF5 datasets
///
/// MATLAB v7.3 files require specific attributes to be recognized correctly.
/// This class provides helpers for writing those attributes.
class MatlabAttributeWriter {
  /// Write MATLAB_class attribute to identify variable type
  ///
  /// This is the most important attribute - MATLAB uses it to determine
  /// how to interpret the data.
  static void writeMatlabClass(
    Map<String, dynamic> attributes,
    MatlabClass matlabClass,
  ) {
    attributes[MatlabAttributes.matlabClass] = matlabClass.toMatlabString();
  }

  /// Write MATLAB_fields attribute for structures
  ///
  /// Structures must have this attribute listing all field names
  static void writeStructureFields(
    Map<String, dynamic> attributes,
    List<String> fields,
  ) {
    attributes[MatlabAttributes.matlabFields] = fields;
  }

  /// Write MATLAB_sparse attribute for sparse matrices
  static void writeSparseFlag(Map<String, dynamic> attributes) {
    attributes[MatlabAttributes.matlabSparse] = 1;
  }

  /// Write MATLAB_global attribute for global variables
  static void writeGlobalFlag(Map<String, dynamic> attributes) {
    attributes[MatlabAttributes.matlabGlobal] = 1;
  }

  /// Write MATLAB_empty attribute for empty arrays
  static void writeEmptyFlag(Map<String, dynamic> attributes) {
    attributes[MatlabAttributes.matlabEmpty] = 1;
  }

  /// Write CLASSNAME attribute for MATLAB objects
  static void writeClassName(
    Map<String, dynamic> attributes,
    String className,
  ) {
    attributes['CLASSNAME'] = className;
  }

  /// Create a complete attribute map for a MATLAB variable
  ///
  /// This is a convenience method that creates all necessary attributes
  /// for a given variable type.
  static Map<String, dynamic> createMatlabAttributes({
    required MatlabClass matlabClass,
    List<String>? structFields,
    bool isSparse = false,
    bool isGlobal = false,
    bool isEmpty = false,
    String? className,
  }) {
    final attributes = <String, dynamic>{};

    // Always write MATLAB_class
    writeMatlabClass(attributes, matlabClass);

    // Optional attributes
    if (structFields != null && structFields.isNotEmpty) {
      writeStructureFields(attributes, structFields);
    }

    if (isSparse) {
      writeSparseFlag(attributes);
    }

    if (isGlobal) {
      writeGlobalFlag(attributes);
    }

    if (isEmpty) {
      writeEmptyFlag(attributes);
    }

    if (className != null) {
      writeClassName(attributes, className);
    }

    return attributes;
  }
}
