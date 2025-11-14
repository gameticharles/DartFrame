/// Debug mode flag for verbose logging
bool _debugMode = false;

/// Sets the debug mode for HDF5 operations
void setHdf5DebugMode(bool enabled) {
  _debugMode = enabled;
}

/// Gets the current debug mode status
bool get isHdf5DebugMode => _debugMode;

/// Logs a debug message if debug mode is enabled
void hdf5DebugLog(String message) {
  if (_debugMode) {
    print('[HDF5 DEBUG] $message');
  }
}

/// Base class for all HDF5 errors with comprehensive diagnostics
class Hdf5Error implements Exception {
  final String operation;
  final String? filePath;
  final String? objectPath;
  final String message;
  final String? details;
  final List<String> recoverySuggestions;
  final Object? originalError;
  final StackTrace? stackTrace;

  Hdf5Error({
    required this.operation,
    this.filePath,
    this.objectPath,
    required this.message,
    this.details,
    this.recoverySuggestions = const [],
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('HDF5 Error: $operation failed');
    buffer.writeln('Message: $message');

    if (filePath != null) {
      buffer.writeln('File: $filePath');
    }

    if (objectPath != null) {
      buffer.writeln('Path: $objectPath');
    }

    if (details != null) {
      buffer.writeln('Details: $details');
    }

    if (recoverySuggestions.isNotEmpty) {
      buffer.writeln('\nRecovery Suggestions:');
      for (int i = 0; i < recoverySuggestions.length; i++) {
        buffer.writeln('  ${i + 1}. ${recoverySuggestions[i]}');
      }
    }

    if (_debugMode && originalError != null) {
      buffer.writeln('\nOriginal Error: $originalError');
      if (stackTrace != null) {
        buffer.writeln('Stack Trace:\n$stackTrace');
      }
    }

    return buffer.toString();
  }
}

/// Error thrown when HDF5 signature is invalid
class InvalidHdf5SignatureError extends Hdf5Error {
  InvalidHdf5SignatureError({
    super.filePath,
    super.details,
  }) : super(
          operation: 'Open HDF5 file',
          message: 'Invalid HDF5 signature',
          recoverySuggestions: [
            'Verify the file is a valid HDF5 file',
            'Check if the file is corrupted',
            'Ensure the file was not truncated during transfer',
            'Try opening the file with h5dump or HDFView to verify integrity',
          ],
        );
}

/// Error thrown when a path is not found
class PathNotFoundError extends Hdf5Error {
  PathNotFoundError({
    super.filePath,
    required String super.objectPath,
    super.details,
  }) : super(
          operation: 'Navigate to path',
          message: 'Path not found: $objectPath',
          recoverySuggestions: [
            'Check the path spelling and case sensitivity',
            'Use HDF5Reader.inspect() to list available paths',
            'Verify the path exists in the file using h5dump or HDFView',
            'Ensure you are using absolute paths starting with "/"',
          ],
        );
}

/// Error thrown when a dataset is not found
class DatasetNotFoundError extends Hdf5Error {
  DatasetNotFoundError({
    super.filePath,
    required String datasetPath,
    super.details,
  }) : super(
          operation: 'Read dataset',
          objectPath: datasetPath,
          message: 'Dataset not found: $datasetPath',
          recoverySuggestions: [
            'Verify the dataset path is correct',
            'Use HDF5Reader.listDatasets() to see available datasets',
            'Check if the path points to a group instead of a dataset',
            'Ensure the dataset exists in the file',
          ],
        );
}

/// Error thrown when a group is not found
class GroupNotFoundError extends Hdf5Error {
  GroupNotFoundError({
    super.filePath,
    required String groupPath,
    String? parentPath,
  }) : super(
          operation: 'Navigate to group',
          objectPath: groupPath,
          message: 'Group not found: $groupPath',
          details: parentPath != null ? 'Parent path: $parentPath' : null,
          recoverySuggestions: [
            'Verify the group path is correct',
            'Check if the path points to a dataset instead of a group',
            'Use HDF5Reader.inspect() to explore the file structure',
          ],
        );
}

/// Error thrown when an object is not a dataset
class NotADatasetError extends Hdf5Error {
  NotADatasetError({
    super.filePath,
    required String super.objectPath,
    String? actualType,
  }) : super(
          operation: 'Read dataset',
          message: 'Path points to a $actualType, not a dataset',
          details: actualType != null
              ? 'The object at "$objectPath" is a $actualType'
              : null,
          recoverySuggestions: [
            'Use group() method instead if accessing a group',
            'Check the object type using getObjectType()',
            'Verify the correct path to the dataset',
          ],
        );
}

/// Error thrown when an object is not a group
class NotAGroupError extends Hdf5Error {
  NotAGroupError({
    super.filePath,
    required String super.objectPath,
    String? actualType,
  }) : super(
          operation: 'Navigate to group',
          message: 'Path points to a $actualType, not a group',
          details: actualType != null
              ? 'The object at "$objectPath" is a $actualType'
              : null,
          recoverySuggestions: [
            'Use dataset() method instead if accessing a dataset',
            'Check the object type using getObjectType()',
            'Verify the correct path to the group',
          ],
        );
}

/// Error thrown when an unsupported feature is encountered
class UnsupportedFeatureError extends Hdf5Error {
  UnsupportedFeatureError({
    super.filePath,
    super.objectPath,
    required String feature,
    super.details,
  }) : super(
          operation: 'Read HDF5 data',
          message: 'Unsupported feature: $feature',
          recoverySuggestions: [
            'Check if a newer version of dartframe supports this feature',
            'Consider converting the file to use supported features',
            'File an issue on GitHub if this feature is important',
          ],
        );
}

/// Error thrown when an unsupported datatype is encountered
class UnsupportedDatatypeError extends Hdf5Error {
  UnsupportedDatatypeError({
    super.filePath,
    super.objectPath,
    required String datatypeInfo,
  }) : super(
          operation: 'Read dataset',
          message: 'Unsupported datatype',
          details: datatypeInfo,
          recoverySuggestions: [
            'Check if the datatype is supported in the documentation',
            'Convert the dataset to a supported datatype (int, float, string)',
            'Use h5repack to convert the file to use standard datatypes',
          ],
        );
}

/// Error thrown when file corruption is detected
class CorruptedFileError extends Hdf5Error {
  CorruptedFileError({
    super.filePath,
    super.objectPath,
    required String reason,
    super.details,
  }) : super(
          operation: 'Read HDF5 file',
          message: 'File appears to be corrupted: $reason',
          recoverySuggestions: [
            'Verify the file integrity using h5dump or HDFView',
            'Check if the file was completely downloaded/transferred',
            'Try to recover the file using HDF5 repair tools',
            'Restore from a backup if available',
          ],
        );
}

/// Error thrown when decompression fails
class DecompressionError extends Hdf5Error {
  DecompressionError({
    super.filePath,
    super.objectPath,
    required String compressionType,
    super.originalError,
  }) : super(
          operation: 'Decompress data',
          message: 'Failed to decompress $compressionType data',
          recoverySuggestions: [
            'Verify the compression filter is supported',
            'Check if the compressed data is corrupted',
            'Try recompressing the dataset with a supported filter',
          ],
        );
}

/// Error thrown when data reading fails
class DataReadError extends Hdf5Error {
  DataReadError({
    super.filePath,
    super.objectPath,
    required String reason,
    super.details,
    super.originalError,
  }) : super(
          operation: 'Read data',
          message: reason,
          recoverySuggestions: [
            'Check if the file is accessible and not locked',
            'Verify sufficient memory is available',
            'Try reading a smaller dataset first',
          ],
        );
}

/// Error thrown when file access fails
class FileAccessError extends Hdf5Error {
  FileAccessError({
    required String super.filePath,
    required String reason,
    super.originalError,
  }) : super(
          operation: 'Open file',
          message: reason,
          recoverySuggestions: [
            'Check if the file exists at the specified path',
            'Verify you have read permissions for the file',
            'Ensure the file is not locked by another process',
            'Check if the path is correct and accessible',
          ],
        );
}

/// Error thrown when an unsupported version is encountered
class UnsupportedVersionError extends Hdf5Error {
  UnsupportedVersionError({
    super.filePath,
    required String component,
    required int version,
  }) : super(
          operation: 'Parse HDF5 structure',
          message: 'Unsupported $component version: $version',
          details: 'This version of $component is not supported',
          recoverySuggestions: [
            'Check if a newer version of dartframe supports this version',
            'Try converting the file to an older HDF5 version',
            'Use h5repack to convert to a compatible version',
          ],
        );
}

/// Error thrown when an invalid message is encountered
class InvalidMessageError extends Hdf5Error {
  InvalidMessageError({
    super.filePath,
    super.objectPath,
    required String messageType,
    required String reason,
    super.details,
  }) : super(
          operation: 'Parse object header',
          message: 'Invalid $messageType message: $reason',
          recoverySuggestions: [
            'The file may be corrupted',
            'Verify the file with h5dump or HDFView',
            'Try to recover using HDF5 repair tools',
          ],
        );
}

/// Error thrown when an invalid signature is encountered
class InvalidSignatureError extends Hdf5Error {
  InvalidSignatureError({
    super.filePath,
    super.objectPath,
    required String structureType,
    required String expected,
    required String actual,
    required int address,
  }) : super(
          operation: 'Parse HDF5 structure',
          message: 'Invalid $structureType signature',
          details:
              'Expected "$expected", got "$actual" at address 0x${address.toRadixString(16)}',
          recoverySuggestions: [
            'The file may be corrupted at this location',
            'Check if the file offset is correct (e.g., MATLAB files use 512-byte offset)',
            'Verify the file integrity',
            'The address calculation may be incorrect',
          ],
        );
}

/// Error thrown when a circular soft link is detected
class CircularLinkError extends Hdf5Error {
  CircularLinkError({
    super.filePath,
    required String linkPath,
    required List<String> visitedPaths,
  }) : super(
          operation: 'Resolve soft link',
          objectPath: linkPath,
          message: 'Circular soft link detected',
          details: 'Link chain: ${visitedPaths.join(' -> ')} -> $linkPath',
          recoverySuggestions: [
            'Check the file for circular link references',
            'The file may have been created with incorrect links',
            'Use h5dump or HDFView to inspect the link structure',
            'Remove or fix the circular link in the source file',
          ],
        );
}
