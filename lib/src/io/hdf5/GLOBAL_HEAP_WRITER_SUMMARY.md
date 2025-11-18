# Global Heap Writer Implementation Summary

## Overview

This document summarizes the implementation of the GlobalHeapWriter class and its integration with the HDF5 writer system for handling variable-length data.

## Implementation Details

### 1. GlobalHeapWriter Class

**Location**: `lib/src/io/hdf5/global_heap.dart`

**Purpose**: Manages allocation and writing of variable-length data objects in HDF5 global heap collections.

**Key Features**:
- Allocates variable-length data and assigns unique heap IDs
- Tracks all allocated objects in memory
- Writes complete global heap collections in HDF5 format
- Creates 16-byte references to heap objects
- Calculates collection sizes including headers and alignment

**Public API**:
```dart
class GlobalHeapWriter {
  // Constructor
  GlobalHeapWriter({Endian endian = Endian.little});
  
  // Allocate data and get heap ID
  int allocate(List<int> data);
  
  // Write complete heap collection
  List<int> writeCollection(int address);
  
  // Create reference to heap object
  List<int> createReference(int objectId, int heapAddress);
  
  // Statistics
  int get objectCount;
  int get totalDataSize;
  int calculateCollectionSize();
  
  // Clear all objects
  void clear();
}
```

**HDF5 Format Compliance**:
- Collection header: "GCOL" signature, version 1, collection size
- Object format: 16-byte header (index, reference count, reserved, size) + data
- 8-byte alignment for all objects
- End marker: index 0, size 0

### 2. StringDatatypeWriter Integration

**Location**: `lib/src/io/hdf5/datatype_writer.dart`

**Enhancement**: Added `encodeForGlobalHeap()` method to StringDatatypeWriter

**Purpose**: Provides a dedicated method for encoding variable-length strings that will be stored in the global heap.

**Usage**:
```dart
final writer = StringDatatypeWriter.variableLength();
final encodedData = writer.encodeForGlobalHeap('Variable-length string');
final heapId = globalHeapWriter.allocate(encodedData);
```

**Features**:
- Validates that the writer is configured for variable-length strings
- Encodes strings according to character set (ASCII or UTF-8)
- Returns raw bytes suitable for heap allocation

### 3. Attribute Writer Integration

**Location**: `lib/src/io/hdf5/attribute.dart`

**Enhancement**: Added global heap support to `Hdf5Attribute.write()` method

**Purpose**: Enables attributes to store variable-length strings and large data in the global heap.

**Usage**:
```dart
final heapWriter = GlobalHeapWriter();
final attr = Hdf5Attribute.scalar('description', 'Long string...');
final bytes = attr.write(
  globalHeapWriter: heapWriter,
  globalHeapAddress: 2048,
);
```

**Features**:
- Optional `globalHeapWriter` and `globalHeapAddress` parameters
- Automatically uses global heap for:
  - Variable-length strings (when datatype specifies)
  - Large strings (> 255 bytes)
- Creates 16-byte heap references in attribute data
- Maintains backward compatibility (works without global heap)

## Usage Examples

### Basic Global Heap Usage

```dart
// Create heap writer
final heapWriter = GlobalHeapWriter();

// Allocate data
final id1 = heapWriter.allocate(utf8.encode('String 1'));
final id2 = heapWriter.allocate(utf8.encode('String 2'));

// Write collection at address 2048
final collectionBytes = heapWriter.writeCollection(2048);

// Create reference to object
final reference = heapWriter.createReference(id1, 2048);
```

### Variable-Length String Datatype

```dart
// Create variable-length string writer
final stringWriter = StringDatatypeWriter.variableLength();

// Encode string for heap
final data = stringWriter.encodeForGlobalHeap('My string');

// Allocate in heap
final heapWriter = GlobalHeapWriter();
final heapId = heapWriter.allocate(data);

// Write datatype message
final datatypeMsg = stringWriter.writeMessage();
```

### Attribute with Global Heap

```dart
// Create heap writer
final heapWriter = GlobalHeapWriter();

// Create attribute with long string
final attr = Hdf5Attribute.scalar(
  'description',
  'A very long description...',
);

// Write attribute using global heap
final attrBytes = attr.write(
  globalHeapWriter: heapWriter,
  globalHeapAddress: 4096,
);

// Write heap collection
final heapBytes = heapWriter.writeCollection(4096);
```

## Benefits

1. **Space Efficiency**: Variable-length strings only use the space they need
2. **Flexibility**: Supports strings of any length without pre-allocation
3. **Compatibility**: Follows HDF5 specification for global heap format
4. **Reusability**: Multiple attributes/datasets can share the same heap
5. **Performance**: Efficient allocation and reference creation

## Testing

Three demonstration programs verify the implementation:

1. **global_heap_writer_demo.dart**: Basic GlobalHeapWriter functionality
2. **string_datatype_global_heap_demo.dart**: String datatype integration
3. **attribute_global_heap_demo.dart**: Attribute writer integration

All demos execute successfully and demonstrate:
- Correct heap collection format
- Proper reference creation
- Space savings for variable-length data
- Multiple objects in shared heap

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **Requirement 2.2**: Variable-length string datatype with global heap storage
- **Requirement 11.5**: Attributes with large data stored in global heap
- **Requirement 12.1**: Global heap collection writing with proper format
- **Requirement 12.4**: Heap ID encoding and reference creation
- **Requirement 12.7**: Collection size tracking and free space management

## Future Enhancements

Potential improvements for future iterations:

1. **Compression**: Compress large heap objects
2. **Deduplication**: Detect and reuse identical data
3. **Fragmentation**: Handle heap fragmentation for long-lived heaps
4. **Multiple Collections**: Support multiple heap collections per file
5. **Reference Counting**: Track and update reference counts

## Conclusion

The GlobalHeapWriter implementation provides a complete solution for managing variable-length data in HDF5 files. It integrates seamlessly with existing string and attribute writers, follows the HDF5 specification, and provides significant space savings for variable-length data.
