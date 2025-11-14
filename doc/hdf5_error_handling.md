# HDF5 Error Handling and Diagnostics

This document describes the comprehensive error handling and diagnostic features in DartFrame's HDF5 implementation.

## Overview

DartFrame provides detailed error diagnostics for HDF5 operations, including:
- File path and object path in all errors
- Clear error messages with context
- Recovery suggestions for common issues
- Debug mode with verbose logging

## Error Types

All HDF5 errors inherit from the base `Hdf5Error` class, which provides:
- Operation that failed
- File path (when available)
- Object path (when available)
- Detailed error message
- Recovery suggestions
- Original error (in debug mode)

### Common Error Types

#### FileAccessError
Thrown when a file cannot be opened or accessed.

```dart
try {
  final file = await Hdf5File.open('nonexistent.h5');
} on FileAccessError catch (e) {
  print(e); // Shows file path and recovery suggestions
}
```

**Recovery Suggestions:**
- Check if the file exists at the specified path
- Verify you have read permissions for the file
- Ensure the file is not locked by another process
- Check if the path is correct and accessible

#### InvalidHdf5SignatureError
Thrown when the file is not a valid HDF5 file.

```dart
try {
  final file = await Hdf5File.open('not_hdf5.txt');
} on InvalidHdf5SignatureError catch (e) {
  print(e); // Shows which offsets were checked
}
```

**Recovery Suggestions:**
- Verify the file is a valid HDF5 file
- Check if the file is corrupted
- Ensure the file was not truncated during transfer
- Try opening the file with h5dump or HDFView to verify integrity

#### DatasetNotFoundError
Thrown when a dataset path does not exist.

```dart
try {
  final dataset = await file.dataset('/nonexistent');
} on DatasetNotFoundError catch (e) {
  print(e); // Shows available children
}
```

**Recovery Suggestions:**
- Verify the dataset path is correct
- Use HDF5Reader.listDatasets() to see available datasets
- Check if the path points to a group instead of a dataset
- Ensure the dataset exists in the file

#### GroupNotFoundError
Thrown when a group path does not exist.

```dart
try {
  final group = await file.group('/nonexistent/group');
} on GroupNotFoundError catch (e) {
  print(e); // Shows parent path
}
```

**Recovery Suggestions:**
- Verify the group path is correct
- Check if the path points to a dataset instead of a group
- Use HDF5Reader.inspect() to explore the file structure

#### NotADatasetError
Thrown when trying to read a group as a dataset.

```dart
try {
  final dataset = await file.dataset('/'); // Root is a group!
} on NotADatasetError catch (e) {
  print(e); // Shows actual object type
}
```

**Recovery Suggestions:**
- Use group() method instead if accessing a group
- Check the object type using getObjectType()
- Verify the correct path to the dataset

#### NotAGroupError
Thrown when trying to access a dataset as a group.

**Recovery Suggestions:**
- Use dataset() method instead if accessing a dataset
- Check the object type using getObjectType()
- Verify the correct path to the group

#### UnsupportedFeatureError
Thrown when an unsupported HDF5 feature is encountered.

```dart
try {
  final data = await dataset.readData(reader);
} on UnsupportedFeatureError catch (e) {
  print(e); // Shows which feature is not supported
}
```

**Recovery Suggestions:**
- Check if a newer version of dartframe supports this feature
- Consider converting the file to use supported features
- File an issue on GitHub if this feature is important

#### UnsupportedDatatypeError
Thrown when an unsupported datatype is encountered.

```dart
try {
  final data = await dataset.readData(reader);
} on UnsupportedDatatypeError catch (e) {
  print(e); // Shows datatype class and size
}
```

**Recovery Suggestions:**
- Check if the datatype is supported in the documentation
- Convert the dataset to a supported datatype (int, float, string)
- Use h5repack to convert the file to use standard datatypes

#### CorruptedFileError
Thrown when file corruption is detected.

**Recovery Suggestions:**
- Verify the file integrity using h5dump or HDFView
- Check if the file was completely downloaded/transferred
- Try to recover the file using HDF5 repair tools
- Restore from a backup if available

#### InvalidSignatureError
Thrown when an invalid structure signature is encountered.

**Recovery Suggestions:**
- The file may be corrupted at this location
- Check if the file offset is correct (e.g., MATLAB files use 512-byte offset)
- Verify the file integrity
- The address calculation may be incorrect

#### UnsupportedVersionError
Thrown when an unsupported version is encountered.

**Recovery Suggestions:**
- Check if a newer version of dartframe supports this version
- Try converting the file to an older HDF5 version
- Use h5repack to convert to a compatible version

## Debug Mode

Enable debug mode to see verbose logging of HDF5 operations:

```dart
import 'package:dartframe/src/io/hdf5_reader.dart';

// Enable debug mode
HDF5Reader.setDebugMode(true);

try {
  final file = await Hdf5File.open('test.h5');
  // Debug output will show:
  // [HDF5 DEBUG] Opening HDF5 file: test.h5
  // [HDF5 DEBUG] Reading superblock from file: test.h5
  // [HDF5 DEBUG] Checking for HDF5 signature at offset 0
  // [HDF5 DEBUG] Found valid HDF5 signature at offset 0
  // ... etc
} finally {
  // Disable debug mode
  HDF5Reader.setDebugMode(false);
}
```

You can also enable debug mode per-operation:

```dart
// Enable debug mode for a single read operation
final df = await FileReader.read('test.h5', options: {
  'dataset': '/data',
  'debug': true,
});

// Enable debug mode for inspection
final info = await HDF5Reader.inspect('test.h5', debug: true);

// Enable debug mode for listing datasets
final datasets = await HDF5Reader.listDatasets('test.h5', debug: true);
```

## Error Message Format

All errors follow a consistent format:

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

In debug mode, errors also include:
```
Original Error: <original exception>
Stack Trace:
<stack trace>
```

## Best Practices

### 1. Catch Specific Error Types

```dart
try {
  final dataset = await file.dataset('/data');
} on DatasetNotFoundError catch (e) {
  // Handle missing dataset
  print('Dataset not found: ${e.objectPath}');
  print('Available: ${await HDF5Reader.listDatasets(file.path)}');
} on NotADatasetError catch (e) {
  // Handle wrong object type
  print('Not a dataset: ${e.objectPath}');
} on Hdf5Error catch (e) {
  // Handle any other HDF5 error
  print('HDF5 error: $e');
}
```

### 2. Use Debug Mode for Troubleshooting

```dart
// Enable debug mode when investigating issues
HDF5Reader.setDebugMode(true);

try {
  // Your HDF5 operations
} finally {
  HDF5Reader.setDebugMode(false);
}
```

### 3. Inspect Files Before Reading

```dart
// Inspect file structure first
final info = await HDF5Reader.inspect('data.h5');
print('Available datasets: ${info['rootChildren']}');

// Then read specific datasets
final dataset = await file.dataset('/data');
```

### 4. Check Object Types

```dart
// Check if path is a dataset or group
final type = await file.getObjectType('/mypath');
if (type == 'dataset') {
  final dataset = await file.dataset('/mypath');
} else if (type == 'group') {
  final group = await file.group('/mypath');
}
```

## Examples

See `example/test_error_diagnostics.dart` for comprehensive examples of error handling.

## Implementation Details

The error handling system is implemented in `lib/src/io/hdf5/hdf5_error.dart` and integrated throughout the HDF5 implementation:

- `superblock.dart`: File signature validation, version checking
- `hdf5_file.dart`: File access, path navigation, object type checking
- `group.dart`: Group navigation, B-tree and heap parsing
- `dataset.dart`: Dataset reading, datatype validation
- `object_header.dart`: Object header parsing, message validation
- `hdf5_reader.dart`: High-level API integration

All errors include context about the operation, file path, and object path to help diagnose issues quickly.
