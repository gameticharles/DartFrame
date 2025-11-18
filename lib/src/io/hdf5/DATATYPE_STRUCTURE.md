# HDF5 Datatype Files Structure

## Overview

The HDF5 datatype implementation is split into two complementary files:
- `datatype.dart` - Reading/parsing HDF5 datatypes from files
- `datatype_writer.dart` - Writing/serializing HDF5 datatypes to files

## Shared Constants and Enums

All shared constants and enums are defined in `datatype.dart` and imported by `datatype_writer.dart`. This follows the **Option 1: Shared Constants** approach.

### Shared Types

The following types are defined in `datatype.dart` and used by both files:

1. **`Hdf5DatatypeClass` enum** - HDF5 datatype class enumeration
   - `integer(0)` - Fixed-point integers
   - `float(1)` - Floating-point numbers
   - `time(2)` - Date/time values
   - `string(3)` - Character strings
   - `bitfield(4)` - Bit fields
   - `opaque(5)` - Opaque binary data
   - `compound(6)` - Compound/struct types
   - `reference(7)` - Object/region references
   - `enumType(8)` - Enumeration types
   - `vlen(9)` - Variable-length sequences
   - `array(10)` - Fixed-size arrays

2. **`StringPaddingType` enum** - String padding types
   - `nullTerminate` - Null-terminated strings
   - `nullPad` - Null-padded strings
   - `spacePad` - Space-padded strings

3. **`CharacterSet` enum** - Character encoding
   - `ascii` - ASCII encoding
   - `utf8` - UTF-8 encoding

4. **`ReferenceType` enum** - Reference types
   - `object` - Reference to an HDF5 object
   - `region` - Reference to a dataset region

5. **Legacy constants** (for backward compatibility)
   - `datatypeClassFixedPoint = 0`
   - `datatypeClassFloatingPoint = 1`
   - `datatypeClassTime = 2`
   - `datatypeClassString = 3`
   - `datatypeClassBitfield = 4`
   - `datatypeClassOpaque = 5`
   - `datatypeClassCompound = 6`
   - `datatypeClassReference = 7`
   - `datatypeClassEnum = 8`
   - `datatypeClassVariableLength = 9`
   - `datatypeClassArray = 10`

### Additional Shared Types

The following supporting types are also defined in `datatype.dart`:

- `StringInfo` - String-specific datatype information
- `CompoundField` / `Hdf5DatatypeField` - Compound field information
- `CompoundInfo` - Compound datatype information
- `ArrayInfo` - Array datatype information
- `EnumMember` - Enum member information
- `EnumInfo` - Enum datatype information
- `ReferenceInfo` - Reference datatype information
- `OpaqueData` - Opaque data wrapper

## File Organization

### datatype.dart (Reading)
**Purpose:** Parse HDF5 datatype messages from binary format

**Key Classes:**
- `Hdf5Datatype<T>` - Main datatype representation with read capabilities
- Static `read()` method for parsing from ByteReader
- Helper methods for specific datatype classes

**Responsibilities:**
- Parse datatype messages from HDF5 files
- Decode binary format to Dart objects
- Provide type information and metadata
- Support all HDF5 datatype classes

### datatype_writer.dart (Writing)
**Purpose:** Serialize HDF5 datatypes to binary format

**Key Classes:**
- `DatatypeWriter` - Abstract base class for all writers
- `DatatypeWriterFactory` - Factory for creating appropriate writers
- Specific writer classes:
  - `NumericDatatypeWriter` - Integers and floats
  - `StringDatatypeWriter` - Fixed and variable-length strings
  - `BooleanDatatypeWriter` - Boolean values (as enums)
  - `CompoundDatatypeWriter` - Compound/struct types
  - `ArrayDatatypeWriter` - Fixed-size arrays
  - `VlenDatatypeWriter` - Variable-length sequences
  - `EnumDatatypeWriter` - Enumeration types
  - `ReferenceDatatypeWriter` - Object/region references
  - `OpaqueDatatypeWriter` - Opaque binary data
  - `BitfieldDatatypeWriter` - Bit fields
  - `TimeDatatypeWriter` - Date/time values

**Responsibilities:**
- Generate HDF5 datatype messages
- Encode Dart objects to binary format
- Support type hints for ambiguous cases
- Provide encoding utilities

## Design Rationale

### Why Keep Files Separate?

1. **Clear Separation of Concerns**
   - Reading and writing have different workflows
   - Different error handling requirements
   - Different performance characteristics

2. **Independent Evolution**
   - Reader can support more formats without affecting writer
   - Writer can optimize for specific use cases
   - Easier to maintain and test independently

3. **Different Use Cases**
   - Reading: Parse existing HDF5 files (must handle all versions)
   - Writing: Create new HDF5 files (can use optimal format)

### Why Share Constants?

1. **Single Source of Truth**
   - Enum values must match between reading and writing
   - Reduces risk of inconsistencies
   - Easier to update when HDF5 spec changes

2. **Type Safety**
   - Shared enums provide compile-time type checking
   - Prevents invalid datatype class values
   - Better IDE support and autocomplete

3. **Maintainability**
   - Changes to constants only need to be made once
   - Reduces code duplication
   - Easier to understand the relationship between files

## Import Structure

```dart
// datatype_writer.dart imports from datatype.dart
import 'datatype.dart';

// This provides access to:
// - Hdf5DatatypeClass enum
// - StringPaddingType enum
// - CharacterSet enum
// - ReferenceType enum
// - All supporting info classes
```

## Best Practices

1. **Adding New Datatype Classes**
   - Add enum value to `Hdf5DatatypeClass` in `datatype.dart`
   - Implement reader in `Hdf5Datatype.read()` method
   - Create new writer class in `datatype_writer.dart`
   - Update factory methods as needed

2. **Modifying Shared Constants**
   - Only modify in `datatype.dart`
   - Verify both reader and writer still work
   - Update tests for both files

3. **Testing**
   - Test reader and writer independently
   - Add roundtrip tests to verify compatibility
   - Test edge cases for each datatype class

## Conclusion

The current structure follows best practices by:
- Keeping reading and writing logic separate
- Sharing constants and enums to ensure consistency
- Providing clear interfaces for each responsibility
- Maintaining type safety throughout

This approach balances separation of concerns with code reuse, making the codebase maintainable and extensible.
