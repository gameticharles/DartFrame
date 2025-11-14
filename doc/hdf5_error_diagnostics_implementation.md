# HDF5 Error Diagnostics Implementation Summary

## Task 1.3: Add Comprehensive Error Diagnostics

This document summarizes the implementation of comprehensive error diagnostics for the HDF5 reader in DartFrame.

## Implementation Overview

### 1. Core Error System (`lib/src/io/hdf5/hdf5_error.dart`)

Created a comprehensive error handling system with:

- **Base `Hdf5Error` class**: Provides structured error information including:
  - Operation that failed
  - File path (when available)
  - Object path (when available)
  - Detailed error message
  - Additional context/details
  - Recovery suggestions
  - Original error (in debug mode)
  - Stack trace (in debug mode)

- **Specialized error types** for different failure scenarios:
  - `InvalidHdf5SignatureError` - Invalid HDF5 file signature
  - `PathNotFoundError` - Path does not exist in file
  - `DatasetNotFoundError` - Dataset not found
  - `GroupNotFoundError` - Group not found
  - `NotADatasetError` - Object is not a dataset
  - `NotAGroupError` - Object is not a group
  - `UnsupportedFeatureError` - Feature not yet implemented
  - `UnsupportedDatatypeError` - Datatype not supported
  - `CorruptedFileError` - File corruption detected
  - `DecompressionError` - Decompression failed
  - `DataReadError` - Data reading failed
  - `FileAccessError` - File access failed
  - `UnsupportedVersionError` - Version not supported
  - `InvalidMessageError` - Invalid message in object header
  - `InvalidSignatureError` - Invalid structure signature

### 2. Debug Mode

Implemented debug logging system:

- **Global debug flag**: `setHdf5DebugMode(bool enabled)`
- **Debug logging function**: `hdf5DebugLog(String message)`
- **Integration**: Debug logs throughout the HDF5 implementation showing:
  - File opening
  - Superblock reading
  - Signature detection
  - Group navigation
  - Dataset reading
  - Object header parsing

### 3. Integration Across HDF5 Implementation

Updated all HDF5 components to use the new error system:

#### `superblock.dart`
- Added file path parameter to error messages
- Replaced generic exceptions with `InvalidHdf5SignatureError`
- Added `UnsupportedVersionError` for unsupported versions
- Added `InvalidMessageError` for invalid offset sizes
- Added debug logging for signature detection and version reading

#### `hdf5_file.dart`
- Added file path to all error messages
- Replaced generic exceptions with specific error types:
  - `FileAccessError` for file not found
  - `DatasetNotFoundError` for missing datasets
  - `GroupNotFoundError` for missing groups
  - `NotADatasetError` for wrong object type
  - `PathNotFoundError` for invalid paths
- Added debug logging for file operations
- Enhanced error messages with available children lists

#### `group.dart`
- Added file path tracking for error reporting
- Replaced generic exceptions with `InvalidSignatureError` for:
  - Invalid heap signatures
  - Invalid B-tree signatures
  - Invalid symbol table node signatures
- Added `CorruptedFileError` for uninitialized heap addresses
- Added debug logging for group reading

#### `dataset.dart`
- Added file path and object path tracking
- Replaced generic exceptions with specific error types:
  - `CorruptedFileError` for missing required messages
  - `UnsupportedFeatureError` for chunked datasets
  - `UnsupportedDatatypeError` for unsupported datatypes
  - `DataReadError` for read failures
- Added debug logging for dataset operations
- Enhanced error messages with datatype information

#### `object_header.dart`
- Added file path parameter to error messages
- Replaced generic exceptions with:
  - `UnsupportedVersionError` for unsupported versions
  - `UnsupportedFeatureError` for virtual datasets
  - `InvalidMessageError` for invalid layout classes
- Added debug logging for object header reading

#### `hdf5_reader.dart`
- Added debug mode support to public API
- Added `setDebugMode(bool enabled)` static method
- Added debug parameter to `read()`, `inspect()`, and `listDatasets()`
- Replaced generic exceptions with specific error types
- Proper error propagation (re-throw `Hdf5Error`, wrap others)

### 4. Error Message Format

All errors follow a consistent, user-friendly format:

```
HDF5 Error: <operation> failed
Message: <error message>
File: <file path>
Path: <object path>
Details: <additional context>

Recovery Suggestions:
  1. <suggestion 1>
  2. <suggestion 2>
  ...
```

### 5. Recovery Suggestions

Each error type includes actionable recovery suggestions:

- File access errors: Check path, permissions, file locks
- Invalid signature: Verify file integrity, check for corruption
- Path not found: List available paths, check spelling
- Unsupported features: Check documentation, convert file format
- Corrupted files: Use repair tools, restore from backup

## Testing

Created comprehensive test suite in `example/test_error_diagnostics.dart`:

1. **FileAccessError**: File not found
2. **InvalidHdf5SignatureError**: Invalid file format
3. **DatasetNotFoundError**: Missing dataset with available children
4. **PathNotFoundError**: Invalid path with parent context
5. **Debug Mode**: Verbose logging demonstration
6. **NotADatasetError**: Wrong object type

All tests pass and demonstrate proper error reporting with context and recovery suggestions.

## Documentation

Created two documentation files:

1. **`doc/hdf5_error_handling.md`**: User-facing documentation
   - Overview of error types
   - Debug mode usage
   - Best practices
   - Code examples

2. **`doc/hdf5_error_diagnostics_implementation.md`**: This file
   - Implementation details
   - Integration points
   - Testing summary

## Requirements Coverage

This implementation satisfies all requirements from task 1.3:

✅ **Include file path, object path, and operation in all errors**
- All error types include operation name
- File path included when available
- Object path included for dataset/group operations

✅ **Add debug mode with verbose logging**
- Global debug mode flag
- Debug logging throughout implementation
- Can be enabled per-operation or globally
- Shows file operations, address calculations, signature checks

✅ **Create error recovery suggestions**
- Each error type has specific recovery suggestions
- Suggestions are actionable and context-aware
- Help users diagnose and fix issues quickly

## Benefits

1. **Better User Experience**: Clear, actionable error messages
2. **Faster Debugging**: Debug mode shows internal operations
3. **Easier Troubleshooting**: Recovery suggestions guide users
4. **Consistent Error Handling**: All errors follow same pattern
5. **Type-Safe Error Handling**: Specific error types for different scenarios
6. **Production Ready**: Errors include all context needed for logging/monitoring

## Future Enhancements

Potential improvements for future tasks:

1. Error codes for programmatic error handling
2. Localization support for error messages
3. Error telemetry/metrics collection
4. More granular debug levels (INFO, DEBUG, TRACE)
5. Performance impact measurement of debug mode
