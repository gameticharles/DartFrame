/// Placeholder for MATLAB v5/v6/v7 (Level 5 MAT-file) reader
///
/// **Status**: Not implemented. Out of scope for Phase 1.
///
/// MATLAB v5, v6, and v7 files use a different binary format (Level 5 MAT-file)
/// that is not HDF5-based. These files have a 128-byte header followed by
/// tag-based data elements.
///
/// **Current support**: Only MATLAB v7.3 (HDF5-based) files are supported.
///
/// If you need to read older MATLAB files:
/// 1. Use Python's scipy.io.loadmat (supports v5-v7)
/// 2. Convert to v7.3 in MATLAB: `save('file.mat', '-v7.3')`
/// 3. Use MATLAB to resave the file in v7.3 format
///
/// Future implementation would require:
/// - Binary Level 5 format parser
/// - Tag structure decoder
/// - Support for compressed data (v7)
/// - Cell array and structure handling (different from v7.3)
class MatV5Reader {
  MatV5Reader._();

  /// Read a MATLAB v5/v6/v7 file
  ///
  /// **Not yet implemented** - Out of scope for Phase 1
  static Future<Map<String, dynamic>> readAll(String path) async {
    throw UnimplementedError(
      'MATLAB v5/v6/v7 (Level 5 MAT-file) reading is not yet supported. '
      'Only MATLAB v7.3 (HDF5-based) files are currently supported. '
      '\n\n'
      'To read older .mat files:\n'
      '1. Use Python scipy.io.loadmat\n'
      '2. Convert to v7.3 in MATLAB: save(\'file.mat\', \'-v7.3\')\n'
      '3. Use MATLAB to resave in v7.3 format',
    );
  }
}
