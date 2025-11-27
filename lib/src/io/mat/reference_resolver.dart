import '../hdf5/hdf5_file.dart';
import '../hdf5/dataset.dart';
import 'matlab_types.dart';
import 'matlab_conventions.dart';

/// Resolves HDF5 object references in MATLAB v7.3 files
///
/// MATLAB v7.3 stores complex data structures (cell arrays, nested structures)
/// using HDF5 object references. These references point to datasets/groups in
/// the special /#refs#/ group.
class ReferenceResolver {
  final Hdf5File _file;
  final Map<int, dynamic> _cache = {};

  /// Maximum recursion depth to prevent infinite loops
  static const int maxDepth = 100;

  ReferenceResolver(this._file);

  /// Check if #refs# group exists
  Future<bool> hasRefsGroup() async {
    try {
      await _file.group('/${MatlabSpecialNames.refs}');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Resolve a single object reference
  ///
  /// [ref] is the reference value (typically a byte array or integer)
  /// Returns the dereferenced data
  Future<dynamic> resolveReference(dynamic ref) async {
    // Check cache first
    final refHash = ref.hashCode;
    if (_cache.containsKey(refHash)) {
      return _cache[refHash];
    }

    try {
      // In HDF5, object references are typically stored as addresses
      // For MATLAB files, we need to find the referenced object in #refs#

      // Try to resolve by searching in #refs# group
      final refsPath = '/${MatlabSpecialNames.refs}';

      // Get the #refs# group
      final refsGroup = await _file.group(refsPath);
      final refChildren = refsGroup.children;

      // For now, we'll try a simpler approach: read all ref objects
      // and match by looking at the reference value
      // This is a fallback - proper implementation would decode the reference

      // Try each reference object
      for (final childName in refChildren) {
        try {
          final refObjPath = '$refsPath/$childName';
          final data = await _file.readDataset(refObjPath);

          // Cache and return
          _cache[refHash] = data;
          return data;
        } catch (_) {
          continue;
        }
      }

      // If we couldn't resolve, return the reference itself
      return ref;
    } catch (e) {
      // Fallback: return raw reference
      return ref;
    }
  }

  /// Resolve a reference recursively for nested structures
  ///
  /// This handles deeply nested cell arrays and complex references.
  /// [ref] is the reference value
  /// [depth] tracks recursion depth to prevent infinite loops
  Future<dynamic> resolveReferenceRecursive(
    dynamic ref, {
    int depth = 0,
  }) async {
    if (depth > maxDepth) {
      throw MatlabFileFormatError(
          'Maximum recursion depth ($maxDepth) exceeded while resolving references');
    }

    // First resolve the immediate reference
    final resolved = await resolveReference(ref);

    // If the resolved value contains more references, recurse
    if (resolved is List) {
      // Check if list contains reference-like objects
      final hasNestedRefs = resolved.any((item) => _looksLikeReference(item));

      if (hasNestedRefs) {
        final results = <dynamic>[];
        for (final item in resolved) {
          if (_looksLikeReference(item)) {
            // Recursively resolve nested reference
            results
                .add(await resolveReferenceRecursive(item, depth: depth + 1));
          } else {
            results.add(item);
          }
        }
        return results;
      }
    }

    return resolved;
  }

  /// Check if a value looks like it might be a reference
  ///
  /// This is a heuristic check since HDF5 references can have various formats
  bool _looksLikeReference(dynamic value) {
    // References are often represented as byte arrays or special objects
    // This is a simplified check - may need refinement based on actual data
    if (value is List && value.isNotEmpty && value.length <= 16) {
      // Small byte arrays are often references (typically 8 or 12 bytes)
      return value.every((item) => item is int && item >= 0 && item <= 255);
    }
    return false;
  }

  /// Resolve an array of object references
  ///
  /// Used for cell arrays where each cell contains a reference
  Future<List<dynamic>> resolveReferences(List<dynamic> refs) async {
    final results = <dynamic>[];

    for (final ref in refs) {
      final resolved = await resolveReference(ref);
      results.add(resolved);
    }

    return results;
  }

  /// Resolve references in a cell array dataset
  ///
  /// Reads the dataset containing references and dereferences each element
  Future<List<dynamic>> resolveCellArray(Dataset dataset) async {
    // Read the dataset to get references
    final data = await _file.readDataset(dataset.objectPath ?? '/unknown');

    // Check if this contains references
    if (!MatlabConventions.isObjectReferenceType(dataset)) {
      // Not references, return as-is
      return data;
    }

    // Resolve each reference
    return await resolveReferences(data);
  }

  /// Resolve all references in #refs# group
  ///
  /// Returns a map of reference object names to their data
  Future<Map<String, dynamic>> resolveAllRefs() async {
    final result = <String, dynamic>{};

    if (!await hasRefsGroup()) {
      return result;
    }

    final refsPath = '/${MatlabSpecialNames.refs}';
    final refsGroup = await _file.group(refsPath);
    final refChildren = refsGroup.children;

    for (final childName in refChildren) {
      try {
        final refObjPath = '$refsPath/$childName';
        final data = await _file.readDataset(refObjPath);
        result[childName] = data;
      } catch (_) {
        // Skip if can't read
        continue;
      }
    }

    return result;
  }

  /// Get the number of reference objects
  Future<int> getRefCount() async {
    if (!await hasRefsGroup()) {
      return 0;
    }

    try {
      final refsGroup = await _file.group('/${MatlabSpecialNames.refs}');
      return refsGroup.children.length;
    } catch (_) {
      return 0;
    }
  }

  /// Clear the reference cache
  void clearCache() {
    _cache.clear();
  }

  /// Read a referenced dataset by name
  ///
  /// [refName] is the reference object name (e.g., "#Refs#0000")
  Future<dynamic> readRefByName(String refName) async {
    final refPath = '/${MatlabSpecialNames.refs}/$refName';

    try {
      final data = await _file.readDataset(refPath);
      return data;
    } catch (e) {
      throw MatlabFileFormatError(
          'Failed to read reference object $refName: $e');
    }
  }

  /// Find reference object containing specific data
  ///
  /// This is a helper for debugging/testing
  Future<String?> findRefByData(dynamic searchData) async {
    if (!await hasRefsGroup()) {
      return null;
    }

    final refsGroup = await _file.group('/${MatlabSpecialNames.refs}');
    final refChildren = refsGroup.children;

    for (final childName in refChildren) {
      try {
        final data = await readRefByName(childName);
        if (data == searchData) {
          return childName;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }
}

/// Helper class for building object reference mappings
class ReferenceBuilder {
  final Map<String, dynamic> _references = {};
  int _refCounter = 0;

  /// Add data to references and get reference name
  String addReference(dynamic data) {
    final refName = MatlabSpecialNames.generateRefName(_refCounter);
    _references[refName] = data;
    _refCounter++;
    return refName;
  }

  /// Get all references
  Map<String, dynamic> get references => Map.unmodifiable(_references);

  /// Get reference count
  int get count => _refCounter;

  /// Clear all references
  void clear() {
    _references.clear();
    _refCounter = 0;
  }
}
