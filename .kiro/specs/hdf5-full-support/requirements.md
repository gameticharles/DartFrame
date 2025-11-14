# Requirements Document: Complete HDF5 Support for DartFrame

## Introduction

This specification defines the requirements for implementing comprehensive HDF5 (Hierarchical Data Format version 5) file reading support in the DartFrame library. The implementation must be pure Dart (no FFI), cross-platform compatible, and seamlessly integrate with DartFrame's DataFrame API.

## Glossary

- **HDF5**: Hierarchical Data Format version 5, a file format for storing large amounts of data
- **DartFrame**: The Dart library for data manipulation and analysis
- **Dataset**: An HDF5 object containing a multidimensional array of data elements
- **Group**: An HDF5 object that serves as a container for other groups and datasets
- **Datatype**: Specification of how data is stored (int, float, string, etc.)
- **Dataspace**: Specification of array dimensions and shape
- **Attribute**: Metadata attached to datasets or groups
- **Chunked Storage**: Data stored in fixed-size blocks for efficient access
- **Contiguous Storage**: Data stored as a single continuous block
- **Symbol Table**: Old-style HDF5 group storage mechanism using B-trees
- **Link**: Reference to another object in the HDF5 file hierarchy
- **Compression**: Data encoding to reduce file size (gzip, lzf, etc.)
- **MATLAB MAT-file v7.3**: MATLAB's file format based on HDF5 with 512-byte offset

## Requirements

### Requirement 1: Core File Reading

**User Story:** As a data scientist, I want to open and read HDF5 files created by various tools (Python h5py, MATLAB, R, etc.), so that I can analyze scientific data in Dart applications.

#### Acceptance Criteria

1. WHEN an HDF5 file is opened, THE System SHALL validate the HDF5 signature at standard offsets (0, 512, 1024, 2048 bytes)
2. WHEN the HDF5 signature is found, THE System SHALL parse the superblock to extract file metadata
3. WHEN the superblock version is 0, 1, 2, or 3, THE System SHALL correctly parse version-specific structures
4. WHEN a MATLAB MAT-file v7.3 is opened, THE System SHALL detect the 512-byte offset and adjust all addresses accordingly
5. WHEN file reading fails, THE System SHALL provide clear error messages indicating the failure reason

### Requirement 2: Dataset Reading

**User Story:** As a developer, I want to read datasets from HDF5 files and convert them to DataFrames, so that I can use DartFrame's analysis capabilities on HDF5 data.

#### Acceptance Criteria

1. WHEN a dataset path is provided, THE System SHALL navigate the group hierarchy to locate the dataset
2. WHEN a dataset is found, THE System SHALL read its datatype, dataspace, and data layout metadata
3. WHEN the dataset uses contiguous storage, THE System SHALL read the data from the specified address
4. WHEN the dataset uses chunked storage, THE System SHALL read and assemble data from multiple chunks
5. WHEN the dataset is 1-dimensional, THE System SHALL create a DataFrame with a single column
6. WHEN the dataset is 2-dimensional, THE System SHALL create a DataFrame with multiple columns
7. WHEN the dataset has more than 2 dimensions, THE System SHALL flatten or reject with a clear error message
8. WHEN dataset reading succeeds, THE System SHALL return a valid DataFrame with correct shape and data

### Requirement 3: Data Type Support

**User Story:** As a data analyst, I want to read datasets with various data types, so that I can work with different kinds of scientific data.

#### Acceptance Criteria

1. WHEN a dataset has integer datatype (int8, int16, int32, int64), THE System SHALL correctly read and convert the values
2. WHEN a dataset has unsigned integer datatype (uint8, uint16, uint32, uint64), THE System SHALL correctly read and convert the values
3. WHEN a dataset has floating-point datatype (float32, float64), THE System SHALL correctly read and convert the values
4. WHEN a dataset has string datatype (fixed or variable length), THE System SHALL correctly read and convert the strings
5. WHEN a dataset has compound datatype, THE System SHALL read each field and create appropriate DataFrame columns
6. WHEN a dataset has unsupported datatype, THE System SHALL provide a clear error message with the datatype details

### Requirement 4: Group Navigation

**User Story:** As a user, I want to navigate through HDF5 group hierarchies, so that I can access datasets organized in nested structures.

#### Acceptance Criteria

1. WHEN the root group is accessed, THE System SHALL list all immediate children (groups and datasets)
2. WHEN a group path is provided, THE System SHALL navigate through the hierarchy to reach the target group
3. WHEN a group uses symbol table storage, THE System SHALL parse B-trees and symbol table nodes
4. WHEN a group uses new-style link storage, THE System SHALL parse link messages and fractal heaps
5. WHEN listing group contents, THE System SHALL distinguish between datasets and subgroups
6. WHEN a nested dataset path is provided (e.g., "/group1/group2/dataset"), THE System SHALL correctly navigate and read the dataset

### Requirement 5: Attribute Reading

**User Story:** As a researcher, I want to read attributes attached to datasets and groups, so that I can access metadata describing my data.

#### Acceptance Criteria

1. WHEN a dataset has attributes, THE System SHALL provide a method to list all attribute names
2. WHEN an attribute name is provided, THE System SHALL read and return the attribute value
3. WHEN an attribute has scalar value, THE System SHALL return the single value
4. WHEN an attribute has array value, THE System SHALL return the array
5. WHEN an attribute has string value, THE System SHALL return the string correctly decoded

### Requirement 6: Compression Support

**User Story:** As a user working with large datasets, I want to read compressed HDF5 datasets, so that I can work with space-efficient files.

#### Acceptance Criteria

1. WHEN a dataset uses gzip compression, THE System SHALL decompress the data before reading
2. WHEN a dataset uses lzf compression, THE System SHALL decompress the data before reading
3. WHEN a dataset uses unsupported compression, THE System SHALL provide a clear error message
4. WHEN decompression fails, THE System SHALL provide diagnostic information

### Requirement 7: Chunked Storage

**User Story:** As a developer, I want to read datasets with chunked storage layout, so that I can access large datasets efficiently.

#### Acceptance Criteria

1. WHEN a dataset uses chunked storage, THE System SHALL read the chunk dimensions from the data layout message
2. WHEN reading chunked data, THE System SHALL locate each chunk using the B-tree index
3. WHEN a chunk is found, THE System SHALL read the chunk data and place it in the correct position
4. WHEN chunks are compressed, THE System SHALL decompress each chunk before assembly
5. WHEN all chunks are read, THE System SHALL return the complete dataset as a DataFrame

### Requirement 8: File Inspection

**User Story:** As a user, I want to inspect HDF5 file structure without reading all data, so that I can understand the file contents efficiently.

#### Acceptance Criteria

1. WHEN inspecting a file, THE System SHALL return the HDF5 version and file metadata
2. WHEN listing root contents, THE System SHALL return all groups and datasets at the root level
3. WHEN recursively listing contents, THE System SHALL traverse all groups and return the complete hierarchy
4. WHEN inspecting a dataset, THE System SHALL return shape, datatype, and storage information without reading the data
5. WHEN inspecting a group, THE System SHALL return the number of children and their names

### Requirement 9: Error Handling

**User Story:** As a developer, I want clear error messages when HDF5 reading fails, so that I can diagnose and fix issues quickly.

#### Acceptance Criteria

1. WHEN an invalid HDF5 file is opened, THE System SHALL throw an exception with message "Invalid HDF5 signature"
2. WHEN a dataset path does not exist, THE System SHALL throw an exception with message "Dataset not found: {path}"
3. WHEN an unsupported feature is encountered, THE System SHALL throw an exception describing the unsupported feature
4. WHEN file corruption is detected, THE System SHALL throw an exception with diagnostic information
5. WHEN reading fails, THE System SHALL include the file path and dataset path in the error message

### Requirement 10: Performance

**User Story:** As a user working with large files, I want efficient HDF5 reading, so that I can process data quickly.

#### Acceptance Criteria

1. WHEN reading a dataset, THE System SHALL use random access file I/O to minimize memory usage
2. WHEN reading multiple datasets, THE System SHALL reuse the file handle to avoid repeated opening
3. WHEN reading large datasets, THE System SHALL provide progress indication or streaming capabilities
4. WHEN caching is beneficial, THE System SHALL cache frequently accessed metadata (group structures, datatypes)
5. WHEN memory usage exceeds reasonable limits, THE System SHALL provide options for chunked or streaming reading

### Requirement 11: MATLAB Compatibility

**User Story:** As a MATLAB user, I want to read MATLAB v7.3 MAT-files, so that I can analyze MATLAB data in Dart.

#### Acceptance Criteria

1. WHEN a MATLAB v7.3 MAT-file is opened, THE System SHALL detect the 512-byte offset
2. WHEN reading MATLAB variables, THE System SHALL correctly adjust all addresses by the offset
3. WHEN MATLAB-specific structures are encountered, THE System SHALL handle them appropriately
4. WHEN MATLAB metadata is present, THE System SHALL make it accessible through attributes
5. WHEN MATLAB cell arrays or structures are encountered, THE System SHALL provide appropriate conversion or error messages

### Requirement 12: Integration with DartFrame

**User Story:** As a DartFrame user, I want HDF5 reading to work seamlessly with existing DartFrame APIs, so that I can use familiar methods.

#### Acceptance Criteria

1. WHEN using FileReader.read() with .h5 or .hdf5 extension, THE System SHALL automatically use the HDF5 reader
2. WHEN using FileReader.readHDF5(), THE System SHALL provide HDF5-specific options
3. WHEN a dataset is read, THE System SHALL return a standard DataFrame object
4. WHEN DataFrame operations are applied, THE System SHALL work correctly with HDF5-sourced data
5. WHEN errors occur, THE System SHALL use DartFrame's standard error handling patterns

## Non-Functional Requirements

### Performance
- File opening SHALL complete within 100ms for files under 100MB
- Dataset reading SHALL achieve at least 50MB/s throughput on standard hardware
- Memory usage SHALL not exceed 2x the dataset size being read

### Compatibility
- The System SHALL work on all platforms supported by Dart (Windows, macOS, Linux, Web, Mobile)
- The System SHALL not use FFI or platform-specific code
- The System SHALL be compatible with HDF5 files created by h5py, MATLAB, R, and other standard tools

### Maintainability
- Code SHALL follow Dart style guidelines
- All public APIs SHALL have comprehensive documentation
- Complex algorithms SHALL have inline comments explaining the HDF5 specification references

### Testing
- Unit tests SHALL cover all data type conversions
- Integration tests SHALL verify reading of real-world HDF5 files
- Test files SHALL include examples from Python h5py, MATLAB, and other sources
