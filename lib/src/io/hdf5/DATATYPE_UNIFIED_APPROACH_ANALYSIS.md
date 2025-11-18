# Analysis: Why Not Unify Reading and Writing in Single Classes?

## The Question

Why can't we make all datatype classes inherit from a base class that has both `encode()` and `decode()` functions for reading and writing?

## The Unified Approach (What We're Avoiding)

```dart
// Hypothetical unified approach
abstract class Hdf5Datatype {
  // Reading
  static Hdf5Datatype decode(ByteReader reader);
  
  // Writing
  List<int> encode();
  
  // Common properties
  Hdf5DatatypeClass get datatypeClass;
  int get size;
}

class IntegerDatatype extends Hdf5Datatype {
  final bool signed;
  final int bitOffset;
  final int bitPrecision;
  
  // Constructor for creating new datatypes (writing)
  IntegerDatatype({required this.signed, ...});
  
  // Constructor for reading from HDF5
  IntegerDatatype.fromReader(ByteReader reader) { ... }
  
  // Writing
  @override
  List<int> encode() { ... }
}
```

## Why This Doesn't Work Well

### 1. **Asymmetric Construction Patterns**

**Reading (Decoding):**
- Starts with binary data (ByteReader)
- Must handle ALL versions (0, 1, 2, 3) of HDF5 format
- Must handle malformed/corrupted data
- Must validate against spec
- Returns a populated object with all fields set

**Writing (Encoding):**
- Starts with Dart values or explicit parameters
- Only needs to write ONE version (typically latest)
- Assumes valid input (or validates upfront)
- Generates spec-compliant output
- Needs minimal state

```dart
// Reading: Complex, version-dependent parsing
static Future<Hdf5Datatype> read(ByteReader reader) async {
  final version = await reader.readUint8();
  
  if (version == 0) {
    // Handle version 0 format (different structure)
    await reader.readUint16(); // bit offset
    await reader.readUint16(); // bit precision
    size = await reader.readUint8(); // size comes AFTER properties
  } else if (version == 1) {
    // Handle version 1 format
    size = await reader.readUint32(); // size comes FIRST
    await reader.readUint16(); // bit offset
    await reader.readUint16(); // bit precision
  }
  // ... more version handling
}

// Writing: Simple, single version
List<int> write() {
  // Always write version 1 (latest stable)
  writer.writeUint8((1 << 4) | classId);
  writer.writeUint32(size); // version 1 format
  writer.writeUint16(0); // bit offset
  writer.writeUint16(size * 8); // bit precision
  return writer.bytes;
}
```

**Problem:** The reading logic is 3-5x more complex than writing. Combining them creates bloated classes where most of the code is only used in one direction.

### 2. **Different State Requirements**

**Reading State (What you need after parsing):**
```dart
class Hdf5Datatype {
  final int? filePosition;        // For debugging
  final int version;              // Which version was read
  final List<String> warnings;    // Parsing warnings
  final bool isLegacyFormat;      // Compatibility flag
  final Map<String, dynamic> rawProperties; // All parsed data
}
```

**Writing State (What you need to generate output):**
```dart
class DatatypeWriter {
  final int size;                 // Just the size
  final Endian endian;            // Byte order
  // That's it!
}
```

**Problem:** Readers need to track metadata about the parsing process. Writers don't need any of this. Combining them means every writer instance carries unnecessary baggage.

### 3. **Error Handling Philosophy**

**Reading Errors:**
- Must be tolerant (files might be from old software)
- Should provide detailed diagnostics
- May need to guess/infer missing information
- Should continue parsing when possible

```dart
// Reading: Defensive, detailed errors
try {
  final classId = classAndVersion & 0x0F;
  if (classId > 10) {
    throw Exception(
      'Unknown HDF5 datatype class: $classId at position $startPos. '
      'File may be corrupted or use unsupported HDF5 extension. '
      'Context: version=$version, bitfields=[$bf1, $bf2, $bf3]'
    );
  }
} catch (e) {
  // Try to recover or provide helpful context
}
```

**Writing Errors:**
- Should fail fast (programmer error)
- Simple validation
- No recovery needed

```dart
// Writing: Fail fast, simple errors
if (size <= 0) {
  throw ArgumentError('Size must be positive');
}
```

**Problem:** Different error handling strategies don't mix well in the same class.

### 4. **API Design Conflicts**

**Reading API (Discovery-oriented):**
```dart
// User doesn't know what type they'll get
final datatype = await Hdf5Datatype.read(reader);

// Then inspect it
if (datatype.isCompound) {
  final fields = datatype.compoundInfo!.fields;
  for (final field in fields) {
    print('${field.name}: ${field.datatype}');
  }
}
```

**Writing API (Construction-oriented):**
```dart
// User knows exactly what they want
final writer = CompoundDatatypeWriter.fromFields({
  'x': NumericDatatypeWriter.float64(),
  'y': NumericDatatypeWriter.float64(),
});

final message = writer.writeMessage();
```

**Problem:** Reading is discovery-based (inspect after parsing), writing is construction-based (specify upfront). These are fundamentally different workflows.

### 5. **Dependency Injection Issues**

**Reading Dependencies:**
```dart
class Hdf5Datatype {
  // Needs ByteReader for parsing
  static Future<Hdf5Datatype> read(ByteReader reader);
  
  // Might need file context
  static Future<Hdf5Datatype> readWithContext(
    ByteReader reader,
    FileContext context,  // For resolving references
  );
}
```

**Writing Dependencies:**
```dart
class DatatypeWriter {
  // Needs ByteWriter for output
  List<int> writeMessage(); // Creates its own ByteWriter internally
  
  // No external context needed
}
```

**Problem:** Readers need external context (file position, other objects), writers are self-contained. Unified classes would need to handle both scenarios.

### 6. **Testing Complexity**

**Reading Tests:**
```dart
test('parse version 0 integer datatype', () async {
  final bytes = [0x00, 0x01, 0x02, ...]; // Complex binary format
  final reader = ByteReader(bytes);
  final datatype = await Hdf5Datatype.read(reader);
  
  expect(datatype.size, 4);
  expect(datatype.version, 0);
  // ... many assertions about parsed state
});

test('handle corrupted datatype gracefully', () async {
  final bytes = [0xFF, 0xFF, ...]; // Invalid data
  final reader = ByteReader(bytes);
  
  expect(
    () => Hdf5Datatype.read(reader),
    throwsA(isA<FormatException>()),
  );
});
```

**Writing Tests:**
```dart
test('write integer datatype', () {
  final writer = NumericDatatypeWriter.int32();
  final bytes = writer.writeMessage();
  
  expect(bytes.length, 12); // Known size
  expect(bytes[0], 0x10); // Version 1, class 0
  // ... simple byte-level assertions
});
```

**Problem:** Reading tests need complex setup and many edge cases. Writing tests are straightforward. Combining them makes test suites harder to organize and maintain.

### 7. **Performance Characteristics**

**Reading Performance:**
- I/O bound (reading from disk/network)
- Async operations required
- May need buffering
- Unpredictable timing

```dart
// Reading: Async, I/O bound
static Future<Hdf5Datatype> read(ByteReader reader) async {
  final byte1 = await reader.readUint8(); // Async I/O
  final byte2 = await reader.readUint8(); // Async I/O
  // ... more async operations
}
```

**Writing Performance:**
- CPU bound (byte manipulation)
- Synchronous operations
- In-memory only
- Predictable timing

```dart
// Writing: Sync, CPU bound
List<int> writeMessage() {
  final writer = ByteWriter(); // In-memory
  writer.writeUint8(0x10);     // Sync
  writer.writeUint32(size);    // Sync
  return writer.bytes;         // Sync
}
```

**Problem:** Mixing async and sync operations in the same class hierarchy creates awkward APIs and potential performance issues.

### 8. **Versioning and Evolution**

**Reading Evolution:**
- Must support OLD formats forever
- Adds complexity over time
- Can't remove version support

```dart
// Reading: Accumulates complexity
static Future<Hdf5Datatype> read(ByteReader reader) async {
  final version = await reader.readUint8();
  
  // Must support all versions
  switch (version) {
    case 0: return _readVersion0(reader);
    case 1: return _readVersion1(reader);
    case 2: return _readVersion2(reader);
    case 3: return _readVersion3(reader);
    // Future: case 4, 5, 6...
  }
}
```

**Writing Evolution:**
- Can use LATEST format only
- Stays simple
- Can upgrade format easily

```dart
// Writing: Stays simple
List<int> writeMessage() {
  // Always use latest stable version
  return _writeVersion1(); // Or upgrade to version 2 when ready
}
```

**Problem:** Over time, the unified class becomes dominated by reading logic for old versions, making the writing code hard to find and maintain.

### 9. **Memory Footprint**

**Reading Objects:**
```dart
// After reading, object contains ALL parsed data
class Hdf5Datatype {
  final Hdf5DatatypeClass dataclass;
  final int size;
  final Endian endian;
  final StringInfo? stringInfo;
  final CompoundInfo? compoundInfo;
  final ArrayInfo? arrayInfo;
  final EnumInfo? enumInfo;
  final ReferenceInfo? referenceInfo;
  final String? tag;
  final Hdf5Datatype? baseType;
  final int? filePosition;
  // ... potentially many more fields
}
```

**Writing Objects:**
```dart
// For writing, only need minimal state
class NumericDatatypeWriter {
  final Hdf5DatatypeClass _dataclass;
  final int _size;
  final Endian _endian;
  final bool _isSigned;
  // That's all!
}
```

**Problem:** Unified classes would need all fields for reading, even when just writing. This wastes memory when creating many writer instances.

### 10. **Code Organization and Maintainability**

**Current Separate Approach:**
```
datatype.dart (1,200 lines)
├── Reading logic
├── Parsing methods
└── Data structures

datatype_writer.dart (2,000 lines)
├── Writing logic
├── Encoding methods
└── Factory methods
```

**Unified Approach:**
```
datatype.dart (3,200+ lines)
├── Reading logic
├── Writing logic
├── Parsing methods
├── Encoding methods
├── Data structures
├── Factory methods
└── Mixed concerns everywhere
```

**Problem:** A 3,200+ line file with mixed concerns is much harder to navigate, understand, and maintain than two focused files.

## Real-World Example: Compound Datatype

Let's look at how compound datatypes differ:

### Reading Compound (Complex)
```dart
static Future<Hdf5Datatype> _readCompoundType(
  ByteReader reader,
  int version,
  int classBitField1,
  int classBitField2,
  int size,
  Endian endian,
) async {
  // Number of members encoded differently by version
  int numMembers;
  if (version < 3) {
    numMembers = classBitField1 | (classBitField2 << 8);
  } else {
    numMembers = await reader.readUint16();
  }

  final fields = <CompoundField>[];
  for (int i = 0; i < numMembers; i++) {
    // Read member name (null-terminated)
    final nameBytes = <int>[];
    int byte;
    do {
      byte = await reader.readUint8();
      if (byte != 0) nameBytes.add(byte);
    } while (byte != 0);

    final name = String.fromCharCodes(nameBytes);

    // Align to 8-byte boundary (version 1 and 2 only)
    if (version < 3) {
      final nameLength = nameBytes.length + 1;
      final padding = (8 - (nameLength % 8)) % 8;
      if (padding > 0) {
        await reader.readBytes(padding);
      }
    }

    final offset = await reader.readUint32();

    // Version 1: read dimensionality info
    if (version == 1) {
      await reader.readUint8(); // dimensionality
      await reader.readBytes(3); // reserved
      await reader.readBytes(4); // dimension permutation
      await reader.readBytes(4); // reserved
      await reader.readBytes(16); // dimension sizes
    }

    // Read member datatype (recursive)
    final memberType = await read(reader);

    fields.add(CompoundField(
      name: name,
      offset: offset,
      datatype: memberType,
    ));
  }

  return Hdf5Datatype<Map<String, dynamic>>(
    dataclass: Hdf5DatatypeClass.compound,
    size: size,
    endian: endian,
    compoundInfo: CompoundInfo(fields: fields),
  );
}
```

### Writing Compound (Simple)
```dart
@override
List<int> writeMessage() {
  final writer = ByteWriter(endian: _endian);

  // Class and version: class=6 (compound), version=1
  final classAndVersion = (1 << 4) | 6;
  writer.writeUint8(classAndVersion);

  // Number of members
  final numMembers = _fields.length;
  writer.writeUint8(numMembers & 0xFF);
  writer.writeUint8((numMembers >> 8) & 0xFF);
  writer.writeUint8(0); // reserved

  // Size in bytes
  writer.writeUint32(_totalSize);

  // Write each member
  for (final fieldName in _fields.keys) {
    final fieldWriter = _fields[fieldName]!;
    final fieldOffset = _offsets[fieldName]!;
    _writeMember(writer, fieldName, fieldOffset, fieldWriter);
  }

  return writer.bytes;
}
```

**Notice:**
- Reading: 50+ lines, handles 3 versions, async, complex logic
- Writing: 20 lines, one version, sync, straightforward

Combining these would create a class where 70% of the code is only used for reading.

## The Better Approach: Separation with Shared Constants

**What we have now:**
```dart
// datatype.dart - Focused on reading
class Hdf5Datatype {
  static Future<Hdf5Datatype> read(ByteReader reader) { ... }
  // All reading logic here
}

// datatype_writer.dart - Focused on writing
class DatatypeWriter {
  List<int> writeMessage() { ... }
  // All writing logic here
}

// Both import shared constants from datatype.dart
enum Hdf5DatatypeClass { ... }
enum StringPaddingType { ... }
```

**Benefits:**
1. ✅ Each file has a single, clear purpose
2. ✅ Reading complexity doesn't affect writing
3. ✅ Writing simplicity doesn't constrain reading
4. ✅ Easy to test independently
5. ✅ Easy to optimize separately
6. ✅ Shared constants ensure consistency
7. ✅ Can evolve independently
8. ✅ Better code organization
9. ✅ Smaller memory footprint for writers
10. ✅ Clear async/sync boundaries

## Conclusion

While it might seem elegant to have a single class hierarchy with both encode and decode methods, the practical reality is that:

1. **Reading and writing are fundamentally different operations** with different complexity, requirements, and constraints
2. **The unified approach creates bloated classes** where most code is only used in one direction
3. **Separation provides better organization** and makes the codebase easier to understand and maintain
4. **Shared constants give us consistency** without the downsides of unification

The current approach follows the **Single Responsibility Principle** - each class has one reason to change. A unified class would have two reasons to change (reading format changes OR writing format changes), making it harder to maintain.

## When Unification Makes Sense

Unification would make sense if:
- Reading and writing had similar complexity ❌ (Reading is 3-5x more complex)
- Both needed the same state ❌ (Readers need much more state)
- Both had the same error handling ❌ (Different philosophies)
- Both had the same performance profile ❌ (Async vs sync)
- The code wouldn't become bloated ❌ (Would be 3,200+ lines)

Since none of these conditions are met, separation is the better choice.
