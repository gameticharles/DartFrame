import 'dart:typed_data';
import '../hdf5/hdf5_file.dart';
import '../hdf5/dataset.dart';
import '../hdf5/object_header.dart';
import 'matlab_types.dart';

/// MATLAB-specific HDF5 conventions and utilities
///
/// This class provides helper functions to work with MATLAB v7.3 .mat files,
/// which use HDF5 with specific conventions for variable storage and metadata.
class MatlabConventions {
  /// Check if an HDF5 file is a MATLAB v7.3 file
  ///
  /// This checks for MATLAB-specific attributes or patterns in the file.
  /// Note: All valid HDF5 files could potentially be MATLAB files,
  /// so this is a best-effort detection.
  static Future<bool> isMatlabFile(Hdf5File file) async {
    try {
      // Check if there are datasets with MATLAB_class attributes
      final rootChildren = file.root.children;

      for (final childName in rootChildren) {
        // Skip special groups
        if (MatlabSpecialNames.isSpecialName(childName)) {
          continue;
        }

        try {
          final dataset = await file.dataset('/$childName');
          final attrs = dataset.header.findAttributes();

          // Look for MATLAB_class attribute
          for (final attr in attrs) {
            if (attr.name == MatlabAttributes.matlabClass) {
              return true; // Found MATLAB attribute
            }
          }
        } catch (_) {
          // Not a dataset, might be a group
          continue;
        }
      }

      // Also check if #refs# group exists (common in MATLAB files)
      if (rootChildren.contains(MatlabSpecialNames.refs)) {
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// List all user-visible MATLAB variables in a file
  ///
  /// This excludes special internal groups like #refs# and #subsystem#
  static List<String> listVariables(Hdf5File file) {
    return file.root.children
        .where((name) => !MatlabSpecialNames.isSpecialName(name))
        .toList();
  }

  /// Get MATLAB class type from a dataset or group
  static MatlabClass? getMatlabClass(ObjectHeader header) {
    final attrs = header.findAttributes();

    for (final attr in attrs) {
      if (attr.name == MatlabAttributes.matlabClass) {
        final value = attr.value;
        if (value is String) {
          return MatlabClass.fromString(value);
        } else if (value is List && value.isNotEmpty) {
          // Sometimes stored as list of characters
          final str = value.join('');
          return MatlabClass.fromString(str);
        }
      }
    }

    return null;
  }

  /// Get structure field names from MATLAB_fields attribute
  static List<String>? getStructureFields(ObjectHeader header) {
    final attrs = header.findAttributes();

    for (final attr in attrs) {
      if (attr.name == MatlabAttributes.matlabFields) {
        final value = attr.value;

        if (value is List<String>) {
          return value;
        } else if (value is List) {
          // Convert to strings
          return value.map((e) => e.toString()).toList();
        } else if (value is String) {
          // Single field
          return [value];
        }
      }
    }

    return null;
  }

  /// Check if a variable is sparse
  static bool isSparse(ObjectHeader header) {
    final attrs = header.findAttributes();

    for (final attr in attrs) {
      if (attr.name == MatlabAttributes.matlabSparse) {
        final value = attr.value;
        if (value is int) {
          return value != 0;
        } else if (value is bool) {
          return value;
        }
      }
    }

    return false;
  }

  /// Check if a variable is global
  static bool isGlobal(ObjectHeader header) {
    final attrs = header.findAttributes();

    for (final attr in attrs) {
      if (attr.name == MatlabAttributes.matlabGlobal) {
        final value = attr.value;
        if (value is int) {
          return value != 0;
        } else if (value is bool) {
          return value;
        }
      }
    }

    return false;
  }

  /// Check if a variable is empty
  static bool isEmpty(ObjectHeader header) {
    final attrs = header.findAttributes();

    for (final attr in attrs) {
      if (attr.name == MatlabAttributes.matlabEmpty) {
        final value = attr.value;
        if (value is int) {
          return value != 0;
        } else if (value is bool) {
          return value;
        }
      }
    }

    return false;
  }

  /// Get class name for MATLAB objects
  static String? getClassName(ObjectHeader header) {
    final attrs = header.findAttributes();

    for (final attr in attrs) {
      if (attr.name == MatlabAttributes.className) {
        final value = attr.value;
        if (value is String) {
          return value;
        }
      }
    }

    return null;
  }

  /// Extract variable information from a dataset/group
  static MatlabVariableInfo getVariableInfo(
    String name,
    ObjectHeader header,
    List<int> shape,
  ) {
    final matlabClass = getMatlabClass(header) ?? MatlabClass.unknown;
    final isSparse = MatlabConventions.isSparse(header);
    final isGlobal = MatlabConventions.isGlobal(header);
    final isEmpty = MatlabConventions.isEmpty(header);
    final fields = getStructureFields(header);
    final className = getClassName(header);

    return MatlabVariableInfo(
      name: name,
      matlabClass: matlabClass,
      shape: shape,
      isSparse: isSparse,
      isGlobal: isGlobal,
      isEmpty: isEmpty,
      fields: fields,
      className: className,
    );
  }

  /// Convert MATLAB logical array to boolean list
  ///
  /// MATLAB logical arrays are stored as uint8 with values 0 or 1
  static List<bool> logicalToBoolList(List<dynamic> data) {
    return data.map((e) {
      if (e is int) {
        return e != 0;
      } else if (e is bool) {
        return e;
      } else {
        return false;
      }
    }).toList();
  }

  /// Convert character array to string
  ///
  /// MATLAB char arrays can be stored in different ways
  static String charArrayToString(List<dynamic> data) {
    if (data.isEmpty) return '';

    if (data.first is String) {
      // Already strings
      return data.join('');
    } else if (data.first is int) {
      // Character codes
      return String.fromCharCodes(data.cast<int>());
    } else {
      // Fallback: convert to string
      return data.map((e) => e.toString()).join('');
    }
  }

  /// Reshape flat data to given shape
  ///
  /// MATLAB stores arrays in column-major order, while Dart uses row-major.
  /// This function handles the conversion.
  static List<dynamic> reshapeData(List<dynamic> flatData, List<int> shape) {
    if (shape.isEmpty || shape.length == 1) {
      return flatData;
    }

    if (shape.length == 2) {
      // 2D array - most common case
      final rows = shape[0];
      final cols = shape[1];

      // MATLAB is column-major, so we need to transpose
      final result = List<dynamic>.filled(rows * cols, 0);

      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
          // Column-major index: j * rows + i
          final matlabIndex = j * rows + i;
          // Row-major index: i * cols + j
          final dartIndex = i * cols + j;

          if (matlabIndex < flatData.length) {
            result[dartIndex] = flatData[matlabIndex];
          }
        }
      }

      return result;
    }

    // For higher dimensions, return as-is for now
    // TODO: Implement n-dimensional reshape if needed
    return flatData;
  }

  /// Check if dataset contains HDF5 object references
  static bool isObjectReferenceType(Dataset dataset) {
    // Check if datatype is reference type
    final datatype = dataset.datatype;
    return datatype.isReference;
  }

  /// Validate MATLAB variable name
  ///
  /// MATLAB variable names must:
  /// - Start with a letter
  /// - Contain only letters, digits, and underscores
  /// - Be no more than 63 characters (MATLAB R2014a+)
  static bool isValidVariableName(String name) {
    if (name.isEmpty || name.length > 63) {
      return false;
    }

    // Must start with letter
    if (!RegExp(r'^[a-zA-Z]').hasMatch(name)) {
      return false;
    }

    // Must contain only alphanumeric and underscore
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(name)) {
      return false;
    }

    return true;
  }

  /// Check if a group represents a structure array
  ///
  /// Structure arrays have numeric indices as children (0, 1, 2, ...)
  static Future<bool> isStructureArray(Hdf5File file, String groupPath) async {
    try {
      final group = await file.group(groupPath);
      final children = group.children;

      if (children.isEmpty) return false;

      // Check if all children are numeric indices
      final indices = <int>[];
      for (final child in children) {
        final index = int.tryParse(child);
        if (index == null) return false; // Non-numeric child
        indices.add(index);
      }

      // Should have consecutive indices starting from 0
      indices.sort();
      return indices.first == 0 && indices.length == indices.last + 1;
    } catch (_) {
      return false;
    }
  }

  /// Get the length of a structure array
  static Future<int> getStructureArrayLength(
      Hdf5File file, String groupPath) async {
    try {
      final group = await file.group(groupPath);
      final children = group.children;

      if (children.isEmpty) return 0;

      final indices =
          children.map((name) => int.tryParse(name)).whereType<int>().toList();

      if (indices.isEmpty) return 0;

      indices.sort();
      return indices.last + 1;
    } catch (_) {
      return 0;
    }
  }

  /// Get human-readable description of a MATLAB variable
  static String describeVariable(MatlabVariableInfo info) {
    final buffer = StringBuffer();
    buffer.write('${info.name}: ');
    buffer.write(MatlabTypeMappings.getDescription(info.matlabClass));
    buffer.write(' ${info.shape.join('x')}');

    if (info.isSparse) buffer.write(' (sparse)');
    if (info.isGlobal) buffer.write(' (global)');
    if (info.isEmpty) buffer.write(' (empty)');

    if (info.fields != null && info.fields!.isNotEmpty) {
      buffer.write(' with fields: ${info.fields!.join(', ')}');
    }

    if (info.className != null) {
      buffer.write(' [class: ${info.className}]');
    }

    return buffer.toString();
  }
}

/// MATLAB file version detection
class MatlabVersion {
  /// Detect MATLAB file version from file signature
  ///
  /// Returns version string or null if not a MATLAB file
  static String? detectVersion(Uint8List headerBytes) {
    if (headerBytes.length < 128) {
      return null;
    }

    // Read first 128 bytes as ASCII
    final headerText = String.fromCharCodes(headerBytes.sublist(0, 128));

    if (headerText.contains('MATLAB 7.3')) {
      return '7.3';
    } else if (headerText.contains('MATLAB 5.0')) {
      // v5, v6, or v7 (all use same "Level 5" format)
      return '5.0';
    }

    return null;
  }

  /// Check if version is supported
  static bool isSupported(String version) {
    return version == '7.3';
  }

  /// Get description of version
  static String getVersionDescription(String version) {
    switch (version) {
      case '7.3':
        return 'MATLAB v7.3 (HDF5-based)';
      case '5.0':
        return 'MATLAB v5/v6/v7 (Level 5 MAT-file)';
      default:
        return 'Unknown MATLAB version';
    }
  }
}
