# JSON Reader Implementation

## Overview

Successfully implemented full JSON file reading support for DartFrame with multiple orientation formats, matching pandas functionality.

## Implementation

### JsonReader Class

**Location:** `lib/src/io/json_reader.dart`

**Features:**
- ✅ Full JSON reading with 4 orientation formats
- ✅ Automatic type inference
- ✅ Null value handling
- ✅ Empty DataFrame support
- ✅ Comprehensive error handling
- ✅ Platform-agnostic using FileIO

### Supported Orientations

#### 1. Records Format (Default)
```json
[
  {"col1": val1, "col2": val2},
  {"col1": val3, "col2": val4}
]
```
**Usage:**
```dart
final df = await FileReader.readJson('data.json');
// or explicitly
final df = await FileReader.readJson('data.json', orient: 'records');
```

#### 2. Columns Format
```json
{
  "col1": [val1, val3],
  "col2": [val2, val4]
}
```
**Usage:**
```dart
final df = await FileReader.readJson('data.json', orient: 'columns');
```

#### 3. Index Format
```json
{
  "0": {"col1": val1, "col2": val2},
  "1": {"col1": val3, "col2": val4}
}
```
**Usage:**
```dart
final df = await FileReader.readJson('data.json', orient: 'index');
```

#### 4. Values Format
```json
[
  [val1, val2],
  [val3, val4]
]
```
**Usage:**
```dart
final df = await FileReader.readJson('data.json', 
  orient: 'values',
  columns: ['col1', 'col2']
);
```

## API Methods

### FileReader.readJson()

```dart
static Future<DataFrame> readJson(
  String path, {
  String orient = 'records',
  List<String>? columns,
  Map<String, dynamic>? options,
})
```

**Parameters:**
- `path`: Path to JSON file
- `orient`: JSON orientation ('records', 'index', 'columns', 'values')
- `columns`: Column names for 'values' orientation
- `options`: Additional parsing options

### JsonReader().read()

```dart
Future<DataFrame> read(
  String path, {
  Map<String, dynamic>? options,
})
```

**Options:**
- `orient` (String): JSON orientation format
- `columns` (List<String>?): Column names for values format

## Implementation Details

### Parsing Methods

1. **_fromRecordsFormat()** - Converts list of objects to DataFrame
   - Handles missing keys by filling with null
   - Ensures all columns have same length

2. **_fromIndexFormat()** - Converts indexed objects to DataFrame
   - Sorts index keys for consistent ordering
   - Builds columns from row objects

3. **_fromColumnsFormat()** - Converts column arrays to DataFrame
   - Direct mapping from JSON to DataFrame
   - Validates that values are arrays

4. **_fromValuesFormat()** - Converts 2D array to DataFrame
   - Generates column names if not provided
   - Validates column count matches data

### Error Handling

**JsonReadError** thrown for:
- Invalid JSON syntax
- Unsupported orientation
- Mismatched data structures
- File read failures
- Type mismatches

## Integration

### FileReader Updates

Added JSON support to generic FileReader:
- `.json` extension mapped to JsonReader
- Auto-detection in `FileReader.read()`
- Convenience method `FileReader.readJson()`

### Exports

Added to `lib/dartframe.dart`:
```dart
export 'src/io/json_reader.dart';
export 'src/io/csv_reader.dart';
export 'src/io/excel_reader.dart';
```

## Testing

**Location:** `test/io/json_test.dart`

**Test Coverage (10 tests):**
- ✅ Records format read/write
- ✅ Columns format read/write
- ✅ Index format read/write
- ✅ Values format read/write
- ✅ Pretty printing with indentation
- ✅ Auto-detect format
- ✅ Empty DataFrame handling
- ✅ Null value handling
- ✅ Invalid orientation error
- ✅ Values format with/without columns

All tests pass! ✅

## Example

**Location:** `example/json_example.dart`

Demonstrates:
- All 4 orientation formats
- Pretty printing
- Auto-detection
- Complex data types
- Round-trip read/write

## Comparison with Pandas

DartFrame JSON API matches pandas:

**Pandas:**
```python
# Read
df = pd.read_json('data.json', orient='records')

# Write
df.to_json('output.json', orient='records', indent=2)
```

**DartFrame:**
```dart
// Read
final df = await FileReader.readJson('data.json', orient: 'records');

// Write
await FileWriter.writeJson(df, 'output.json', orient: 'records', indent: 2);
```

## Benefits

### 1. Complete Implementation
- ✅ All 4 pandas orientations supported
- ✅ Full feature parity with JsonWriter
- ✅ No more placeholder/workaround needed

### 2. Easy to Use
- ✅ Simple API matching pandas
- ✅ Auto-detection by file extension
- ✅ Sensible defaults (records format)

### 3. Robust
- ✅ Comprehensive error handling
- ✅ Type validation
- ✅ Null value support
- ✅ Empty DataFrame support

### 4. Well Tested
- ✅ 10 comprehensive tests
- ✅ All edge cases covered
- ✅ Integration with existing I/O tests

### 5. Well Documented
- ✅ Comprehensive docstrings
- ✅ Usage examples
- ✅ Working example file
- ✅ Error documentation

## File Organization

The JSON I/O implementation follows the established pattern:

```
lib/src/io/
├── json_reader.dart    - JSON reading (NEW - fully implemented)
├── json_writer.dart    - JSON writing (existing)
├── csv_reader.dart     - CSV reading
├── csv_writer.dart     - CSV writing
├── excel_reader.dart   - Excel reading
├── excel_writer.dart   - Excel writing
├── readers.dart        - Generic reader interface
└── writers.dart        - Generic writer interface
```

## Summary

The JsonReader implementation:
- ✅ Fully functional - no longer a placeholder
- ✅ Supports all 4 pandas orientations
- ✅ Comprehensive error handling
- ✅ Well tested (10 tests passing)
- ✅ Well documented with examples
- ✅ Integrated with FileReader
- ✅ Platform-agnostic (web compatible)

DartFrame now has complete JSON I/O support! 🎉
