# DartData Interface Implementation for DataFrame and Series

## Overview

This document describes the implementation of the DartData interface for DataFrame and Series classes, enabling them to work seamlessly with NDArray, DataCube, and other dimensional data structures in the DartFrame library.

## Changes Made

### 1. Enhanced DartData Interface

**File:** `lib/src/core/dart_data.dart`

Added three new properties to support heterogeneous data structures:

```dart
/// Whether this data structure is homogeneous (all elements same type)
bool get isHomogeneous => true;

/// For heterogeneous structures, get type information per column/dimension
Map<String, Type>? get columnTypes => null;
```

Updated `dtype` documentation to clarify behavior for both homogeneous and heterogeneous structures.

### 2. DataFrame Implementation

**File:** `lib/src/data_frame/data_frame.dart`

DataFrame now implements the `DartData` interface with the following additions:

#### Properties:
- `ndim` → Always returns 2 (rows × columns)
- `size` → Returns total elements (rowCount × columnCount)
- `shape` → Already existed, returns Shape object
- `attrs` → Metadata attributes (HDF5-style)
- `dtype` → Returns `dynamic` (heterogeneous)
- `isHomogeneous` → Always returns `false`
- `columnTypes` → Returns `Map<String, Type>` with inferred types per column

#### Methods:
- `getValue(List<int> indices)` → Get value at [row, col]
- `setValue(List<int> indices, dynamic value)` → Set value at [row, col]
- `slice(List<dynamic> sliceSpec)` → Unified slicing returning appropriate types:
  - Single element → `Scalar`
  - Single row/column → `Series`
  - Multiple rows/columns → `DataFrame`

#### Breaking Changes:
- **Old `slice()` method renamed to `sliceRange()`**
  - The previous `slice(start:, end:, step:, axis:)` method is now `sliceRange()`
  - This avoids conflict with the DartData interface's `slice()` method
  - Migration: Replace `df.slice(...)` with `df.sliceRange(...)`

### 3. Series Implementation

**File:** `lib/src/series/series.dart`

Series now implements the `DartData` interface with the following additions:

#### Properties:
- `ndim` → Always returns 1
- `size` → Returns data.length
- `shape` → Returns Shape([length])
- `attrs` → Metadata attributes (HDF5-style)
- `dtype` → Returns type of first non-null element (already existed)
- `isHomogeneous` → Checks if all non-null elements have same type
- `columnTypes` → Returns `null` (1D structure)
- `isEmpty` / `isNotEmpty` → Check if Series is empty

#### Methods:
- `getValue(List<int> indices)` → Get value at [index]
- `setValue(List<int> indices, dynamic value)` → Set value at [index]
- `slice(List<dynamic> sliceSpec)` → Unified slicing returning:
  - Single element → `Scalar`
  - Range → `Series`

### 4. Test Coverage

**File:** `test/dart_data_integration_test.dart`

Comprehensive test suite covering:
- DataFrame DartData interface compliance
- Series DartData interface compliance
- Type inference and heterogeneity detection
- getValue/setValue operations
- Slicing operations returning correct types
- Metadata attributes
- Polymorphic usage of DartData

## Usage Examples

### DataFrame with DartData Interface

```dart
// Create DataFrame
var df = DataFrame.fromMap({
  'id': [1, 2, 3],
  'name': ['Alice', 'Bob', 'Charlie'],
  'score': [95.5, 87.3, 92.1],
});

// DartData properties
print(df.ndim);           // 2
print(df.size);           // 9
print(df.isHomogeneous);  // false
print(df.columnTypes);    // {id: int, name: String, score: double}

// Metadata
df.attrs['units'] = 'points';
df.attrs['description'] = 'Student scores';

// Unified slicing
var scalar = df.slice([0, 1]);              // Scalar('Alice')
var row = df.slice([0, Slice.all()]);       // Series
var subDf = df.slice([Slice.range(0, 2), Slice.all()]);  // DataFrame

// getValue/setValue
print(df.getValue([0, 1]));  // 'Alice'
df.setValue([0, 1], 'Alicia');
```

### Series with DartData Interface

```dart
// Create Series
var series = Series([1, 2, 3, 4, 5], name: 'numbers');

// DartData properties
print(series.ndim);          // 1
print(series.size);          // 5
print(series.isHomogeneous); // true
print(series.dtype);         // int

// Metadata
series.attrs['units'] = 'meters';
series.attrs['sensor_id'] = 'DIST_001';

// Unified slicing
var scalar = series.slice([2]);              // Scalar(3)
var subSeries = series.slice([Slice.range(1, 4)]);  // Series([2, 3, 4])

// getValue/setValue
print(series.getValue([2]));  // 3
series.setValue([2], 99);
```

### Polymorphic Usage

```dart
// Treat DataFrame and Series uniformly
List<DartData> dataStructures = [
  DataFrame([[1, 2], [3, 4]]),
  Series([1, 2, 3], name: 'test'),
  NDArray([1, 2, 3, 4, 5, 6], [2, 3]),
];

for (var data in dataStructures) {
  print('Dimensions: ${data.ndim}');
  print('Size: ${data.size}');
  print('Shape: ${data.shape}');
  data.attrs['processed'] = DateTime.now();
}
```

## Design Decisions

### 1. Heterogeneous Support

**Decision:** Modify DartData to support both homogeneous and heterogeneous structures.

**Rationale:**
- DataFrame's heterogeneity is a core feature (like pandas, SQL tables)
- Forcing homogeneity would destroy DataFrame's primary use case
- NDArray/DataCube remain homogeneous for numeric operations
- Mirrors successful libraries (NumPy vs pandas)

### 2. Type Information

**Decision:** Add `isHomogeneous` and `columnTypes` properties.

**Rationale:**
- Allows generic algorithms to adapt to data structure type
- Provides detailed type information for heterogeneous structures
- Maintains backward compatibility
- Enables type-aware optimizations

### 3. Method Naming

**Decision:** Rename DataFrame's existing `slice()` to `sliceRange()`.

**Rationale:**
- Avoids conflict with DartData interface
- `sliceRange()` is more descriptive of its functionality
- Maintains all existing functionality
- Clear migration path for users

### 4. Attributes System

**Decision:** Add HDF5-style metadata attributes to all DartData structures.

**Rationale:**
- Enables rich metadata annotation
- Consistent with scientific computing practices
- Useful for data provenance and documentation
- JSON-serializable for persistence

## Migration Guide

### For Existing DataFrame Users

**Old code:**
```dart
var result = df.slice(start: 0, end: 10, step: 2);
```

**New code:**
```dart
var result = df.sliceRange(start: 0, end: 10, step: 2);
```

**Or use new unified slicing:**
```dart
var result = df.slice([Slice.range(0, 10, step: 2), Slice.all()]);
```

### For Library Developers

DataFrame and Series can now be used in generic algorithms:

```dart
T processData<T extends DartData>(T data) {
  // Works with DataFrame, Series, NDArray, DataCube
  print('Processing ${data.ndim}D data with ${data.size} elements');
  
  if (data.isHomogeneous) {
    print('Homogeneous type: ${data.dtype}');
  } else {
    print('Heterogeneous with types: ${data.columnTypes}');
  }
  
  return data;
}
```

## Compatibility

- **Backward Compatible:** All existing DataFrame and Series functionality preserved
- **Breaking Change:** `DataFrame.slice()` renamed to `DataFrame.sliceRange()`
- **New Features:** DartData interface methods and properties
- **Test Coverage:** 100% of new functionality tested

## Future Enhancements

1. **Performance Optimization:** Optimize type inference for large DataFrames
2. **Advanced Slicing:** Add more slicing syntaxes (boolean indexing, fancy indexing)
3. **Type Coercion:** Automatic type conversion in heterogeneous operations
4. **Metadata Persistence:** Save/load attributes with HDF5, Parquet, etc.

## Related Files

- `lib/src/core/dart_data.dart` - Interface definition
- `lib/src/data_frame/data_frame.dart` - DataFrame implementation
- `lib/src/series/series.dart` - Series implementation
- `lib/src/data_frame/advanced_slicing.dart` - Updated slicing methods
- `test/dart_data_integration_test.dart` - Integration tests
- `test/dataframe/advanced_slicing_test.dart` - Updated tests

## Conclusion

The DartData interface implementation successfully unifies DataFrame and Series with NDArray and DataCube, enabling:
- Polymorphic data structure handling
- Consistent API across dimensional types
- Rich metadata support
- Type-aware generic algorithms

This enhancement positions DartFrame as a comprehensive data manipulation library with seamless interoperability between tabular and tensor data structures.
