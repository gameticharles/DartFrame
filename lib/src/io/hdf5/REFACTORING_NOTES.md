# HDF5 Code Refactoring Recommendations

## Overview
This document outlines recommended refactorings to improve the HDF5 codebase structure and maintainability.

## Completed Refactorings

### 1. Hdf5Dataspace - COMPLETED ✓
**Status**: Refactored in Task 10

**Before**: Separate `Hdf5Dataspace` (reader) and `DataspaceMessageWriter` (writer) classes

**After**: Unified `Hdf5Dataspace` class with both `read()` and `write()` methods
- Added `Hdf5Dataspace.simple()` factory constructor for creating dataspaces
- Added `write()` method to the class
- **Deleted** `DataspaceMessageWriter` (clean refactoring, no deprecation needed)
- Updated `HDF5FileBuilder` to use `Hdf5Dataspace` directly
- Enhanced documentation with comprehensive examples

**Benefits**:
- Related functionality is now in one place
- Reduced code duplication
- Better OOP design
- Easier to maintain and test
- Cleaner codebase without deprecated wrappers

### 2. Hdf5Attribute - COMPLETED ✓
**Status**: Refactored in Task 10

**Before**: Separate `Hdf5Attribute` (reader) and `AttributeMessageWriter` (writer) classes

**After**: Unified `Hdf5Attribute` class with both `read()` and `write()` methods
- Added `Hdf5Attribute.scalar()` factory constructor for creating attributes
- Added `write()` method to the class
- **Deleted** `AttributeMessageWriter` (clean refactoring, no deprecation needed)
- Updated `HDF5FileBuilder` to use `Hdf5Attribute` directly
- Enhanced documentation with comprehensive examples

**Benefits**:
- Simplified attribute creation and writing
- Consistent API with other HDF5 structures
- Reduced code duplication
- Cleaner codebase without deprecated wrappers

### 3. Superblock - COMPLETED ✓
**Status**: Refactored in Task 10

**Before**: Separate `Superblock` (reader) and `SuperblockWriter` (writer) classes

**After**: Unified `Superblock` class with both `read()` and `write()` methods
- Added `Superblock.create()` factory constructor for creating superblocks
- Added `write()` and `writeTo()` methods to the class
- Added static `updateEndOfFileAddress()` and `updateRootGroupAddress()` methods
- **Deleted** `SuperblockWriter` (clean refactoring, no deprecation needed)
- Updated `HDF5FileBuilder` to use `Superblock` directly
- Enhanced documentation with comprehensive examples

**Benefits**:
- File-level structure now unified
- Consistent API with other HDF5 structures
- Reduced code duplication
- Cleaner codebase without deprecated wrappers

### 4. Hdf5Datatype - COMPLETED ✓
**Status**: Refactored in Task 10

**Before**: Separate `Hdf5Datatype` (reader) and `DatatypeMessageWriter` (writer) classes

**After**: Unified `Hdf5Datatype` class with both `read()` and `write()` methods
- Added `write()` method to the class (supports float64 and int64)
- Added private `_writeFloat64()` and `_writeInt64()` methods
- **Deleted** `DatatypeMessageWriter` (clean refactoring, no deprecation needed)
- Updated `HDF5FileBuilder` and `Hdf5Attribute` to use `Hdf5Datatype` directly
- Enhanced documentation with comprehensive examples

**Benefits**:
- Core datatype functionality now unified
- Consistent API with other HDF5 structures
- Reduced code duplication
- Cleaner codebase without deprecated wrappers

## Recommended Future Refactorings

### 5. Hdf5ObjectHeader - IN PROGRESS
**Current State**: Separate `Hdf5ObjectHeader` (reader) and `ObjectHeaderWriter` (writer)

**Recommendation**: Merge into unified `Hdf5ObjectHeader` class
- **DONE**: Created unified `MessageType` enum (replacing constants and static class)
- **TODO**: Add `write()` method to `ObjectHeader` class supporting all versions (1 and 2)
- **TODO**: Move `HeaderMessage` class from writer to reader file
- **TODO**: Update `ObjectHeaderWriter.write()` logic to support version 2
- **TODO**: Delete `ObjectHeaderWriter` (clean refactoring)
- **TODO**: Update `HDF5FileBuilder` to use unified class

**Estimated Impact**: Medium - Object headers are core to HDF5 structure
**Complexity**: High - Complex structure with multiple versions and message types

**Implementation Notes**:
- The `MessageType` enum has been created with proper `fromId()` method
- Legacy constants kept for backward compatibility
- Writer currently only supports version 1, needs version 2 support
- Reader supports versions 1 and 2, writer should match

**Note**: This is the last remaining reader/writer pair. All other structures have been unified.

## Implementation Strategy

### ✅ Phase 1: Completed Refactorings
1. ✅ Hdf5Dataspace (simple structure)
2. ✅ Hdf5Attribute (simple structure)
3. ✅ Hdf5Superblock (file-level structure)
4. ✅ Hdf5Datatype (core datatype structure)

### Phase 2: Remaining Refactorings
5. Hdf5ObjectHeader (complex, core structure) - Last remaining pair

### Testing and Validation
- ✅ All tests passing after each refactoring
- ✅ No deprecated wrappers (clean refactoring)
- ✅ Enhanced documentation with examples
- ✅ 4 out of 5 refactorings completed

## Benefits of Complete Refactoring

1. **Consistency**: All HDF5 structures follow the same pattern
2. **Maintainability**: Related code is in one place
3. **Discoverability**: Easier to find read/write functionality
4. **Testing**: Easier to test complete functionality of each structure
5. **Code Reduction**: Eliminate duplicate validation and error handling
6. **Better OOP**: Each class represents a complete HDF5 concept

## Backward Compatibility

All refactorings should:
- Keep old writer classes as deprecated wrappers
- Maintain existing public APIs
- Add deprecation warnings with migration guidance
- Provide clear examples of new usage patterns

## Example Pattern

```dart
// Before (separate classes)
final writer = DataspaceMessageWriter();
final bytes = writer.write(dimensions: [100, 200]);

// After (unified class - clean refactoring)
final dataspace = Hdf5Dataspace.simple([100, 200]);
final bytes = dataspace.write();

// Old wrapper classes have been deleted (no deprecation needed since not yet published)
```

### Dataspace Example
```dart
// Creating and writing dataspaces
final space1d = Hdf5Dataspace.simple([1000]);
final space2d = Hdf5Dataspace.simple([100, 200]);
final space3d = Hdf5Dataspace.simple([10, 20, 30]);

// Write to bytes
final bytes = space2d.write();
```

### Attribute Example
```dart
// Creating and writing attributes
final attr1 = Hdf5Attribute.scalar('units', 'meters');
final attr2 = Hdf5Attribute.scalar('count', 42);
final attr3 = Hdf5Attribute.scalar('temperature', 23.5);

// Write to bytes
final bytes = attr1.write();
```

### Superblock Example
```dart
// Creating and writing superblocks
final superblock = Superblock.create(
  rootGroupAddress: 96,
  endOfFileAddress: 1024,
);

// Write to bytes
final bytes = superblock.write();

// Or write to existing ByteWriter
final writer = ByteWriter();
superblock.writeTo(writer);

// Update addresses after writing
Superblock.updateEndOfFileAddress(writer, newEofAddress);
Superblock.updateRootGroupAddress(writer, newRootAddress);
```

### Datatype Example
```dart
// Using predefined datatypes
final float64Type = Hdf5Datatype.float64;
final int64Type = Hdf5Datatype.int64;

// Write to bytes
final bytes1 = float64Type.write();
final bytes2 = int64Type.write();

// Write with explicit endianness
final bytes3 = float64Type.write(endian: Endian.big);
```

## Notes

- This refactoring aligns with standard OOP principles
- Similar patterns exist in other HDF5 libraries (h5py, HDF5 C++ API)
- Reduces cognitive load for developers working with the codebase
- Makes the codebase more approachable for new contributors
