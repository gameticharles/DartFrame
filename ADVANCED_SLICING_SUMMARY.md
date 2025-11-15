# Advanced Slicing Implementation Summary

## Overview
Implemented advanced slicing operations for DataFrame, including step parameters, label-based range slicing, and convenience methods for common patterns.

## Files Created/Modified

### New Files
1. **lib/src/data_frame/advanced_slicing.dart** - Advanced slicing operations
2. **test/advanced_slicing_test.dart** - Comprehensive tests (44 tests)

### Modified Files
1. **lib/src/data_frame/data_frame.dart** - Added part directive
2. **todo.md** - Updated completed features

## Features Implemented

### 1. Slice with Step Parameter

#### `slice({start, end, step, axis})`
Slice DataFrame with step parameter for flexible data selection.

```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  'B': [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
});

// Every other row
var result = df.slice(start: 0, end: 10, step: 2);
// Returns rows 0, 2, 4, 6, 8

// Every third row starting from 1
var result = df.slice(start: 1, end: 10, step: 3);
// Returns rows 1, 4, 7

// Reverse order
var result = df.slice(start: 9, end: -1, step: -1);
// Returns rows 9, 8, 7, ..., 0

// Every other row in reverse
var result = df.slice(start: 9, end: -1, step: -2);
// Returns rows 9, 7, 5, 3, 1

// Slice columns
var result = df.slice(start: 0, end: 2, step: 1, axis: 1);
// Returns columns A, B
```

**Features:**
- Positive step: forward slicing
- Negative step: reverse slicing
- Works on rows (axis=0) or columns (axis=1)
- Python-style slicing semantics
- Efficient index-based selection

### 2. Label-Based Slicing

#### `sliceByLabel({start, end, axis})`
Slice DataFrame by label range (inclusive on both ends).

```dart
var df = DataFrame.fromMap(
  {'value': [10, 20, 30, 40, 50]},
  index: ['a', 'b', 'c', 'd', 'e']
);

// Slice from 'b' to 'd' (inclusive)
var result = df.sliceByLabel(start: 'b', end: 'd');
// Returns rows with index 'b', 'c', 'd'

// Slice from start to 'c'
var result = df.sliceByLabel(end: 'c');
// Returns rows 'a', 'b', 'c'

// Slice from 'c' to end
var result = df.sliceByLabel(start: 'c');
// Returns rows 'c', 'd', 'e'

// Slice columns by label
var df = DataFrame.fromMap({
  'A': [1], 'B': [2], 'C': [3], 'D': [4]
});

var result = df.sliceByLabel(start: 'B', end: 'C', axis: 1);
// Returns columns B, C
```

**Features:**
- Inclusive on both ends (unlike Python's exclusive end)
- Works with any index type
- Supports row and column slicing
- Clear error messages for invalid labels

### 3. Combined Position and Label Slicing

#### `sliceByPosition({rowSlice, colSlice})`
Slice by position with step in one call.

```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4, 5],
  'B': [10, 20, 30, 40, 50],
  'C': [100, 200, 300, 400, 500]
});

// Every other row, first two columns
var result = df.sliceByPosition(
  rowSlice: [0, 5, 2],  // start, end, step
  colSlice: [0, 2, 1]   // start, end, step
);
// Returns rows 0, 2, 4 and columns A, B
```

#### `sliceByLabelWithStep({rowStart, rowEnd, rowStep, colStart, colEnd, colStep})`
Slice by label with step parameter.

```dart
var df = DataFrame.fromMap(
  {
    'A': [1, 2, 3, 4, 5],
    'B': [10, 20, 30, 40, 50],
    'C': [100, 200, 300, 400, 500]
  },
  index: ['a', 'b', 'c', 'd', 'e']
);

// Slice from 'a' to 'd', every other row
var result = df.sliceByLabelWithStep(
  rowStart: 'a',
  rowEnd: 'd',
  rowStep: 2
);
// Returns rows 'a', 'c'

// Slice columns with step
var result = df.sliceByLabelWithStep(
  colStart: 'A',
  colEnd: 'C',
  colStep: 2
);
// Returns columns A, C
```

### 4. Convenience Methods

#### `everyNthRow(n, {offset})`
Get every nth row.

```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
});

// Every 3rd row
var result = df.everyNthRow(3);
// Returns rows 0, 3, 6, 9

// Every 3rd row starting from index 1
var result = df.everyNthRow(3, offset: 1);
// Returns rows 1, 4, 7
```

#### `everyNthColumn(n, {offset})`
Get every nth column.

```dart
var df = DataFrame.fromMap({
  'A': [1], 'B': [2], 'C': [3], 'D': [4], 'E': [5]
});

// Every 2nd column
var result = df.everyNthColumn(2);
// Returns columns A, C, E

// Every 2nd column starting from B
var result = df.everyNthColumn(2, offset: 1);
// Returns columns B, D
```

#### `reverseRows()` and `reverseColumns()`
Reverse the order of rows or columns.

```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4, 5]
});

// Reverse rows
var reversed = df.reverseRows();
// Returns rows in order: 5, 4, 3, 2, 1

// Reverse columns
var df = DataFrame.fromMap({
  'A': [1], 'B': [2], 'C': [3]
});

var reversed = df.reverseColumns();
// Returns columns in order: C, B, A
```

## Real-World Use Cases

### 1. Downsampling Time Series

```dart
var timeSeries = DataFrame.fromMap({
  'timestamp': List.generate(1000, (i) => DateTime(2024, 1, 1).add(Duration(seconds: i))),
  'value': List.generate(1000, (i) => i * 0.1)
});

// Take every 10th point for visualization
var downsampled = timeSeries.everyNthRow(10);
// Reduces from 1000 to 100 points
```

### 2. Feature Selection

```dart
var features = DataFrame.fromMap({
  'f1': [1], 'f2': [2], 'f3': [3], 'f4': [4], 
  'f5': [5], 'f6': [6], 'f7': [7], 'f8': [8]
});

// Select alternating features
var selected = features.everyNthColumn(2);
// Returns f1, f3, f5, f7
```

### 3. Reverse Chronological Display

```dart
var events = DataFrame.fromMap({
  'date': [
    DateTime(2024, 1, 1),
    DateTime(2024, 1, 2),
    DateTime(2024, 1, 3)
  ],
  'event': ['first', 'second', 'third']
});

// Show most recent first
var reversed = events.reverseRows();
```

### 4. Training Data Range Selection

```dart
var data = DataFrame.fromMap(
  {'value': List.generate(100, (i) => i)},
  index: List.generate(100, (i) => 'obs_$i')
);

// Select observations 20-80 for training
var train = data.sliceByLabel(start: 'obs_20', end: 'obs_80');

// Select every 5th observation for validation
var validation = train.everyNthRow(5);
```

### 5. Batch Processing

```dart
var largeDf = DataFrame.fromMap({
  'data': List.generate(10000, (i) => i)
});

// Process every 1000th row as checkpoint
var checkpoints = largeDf.everyNthRow(1000);
```

### 6. Column Reordering

```dart
var df = DataFrame.fromMap({
  'A': [1], 'B': [2], 'C': [3], 'D': [4]
});

// Reverse column order
var reversed = df.reverseColumns();
// Columns: D, C, B, A
```

## Test Coverage

### Comprehensive Tests (44 tests)
- ✅ slice() with step (9 tests)
  - Every other row
  - Every third row
  - With offset
  - Reverse order
  - Negative step
  - Column slicing
  - Default parameters
  - Error handling
  
- ✅ sliceByLabel() (7 tests)
  - Range slicing
  - From start
  - To end
  - Column slicing
  - Error handling
  
- ✅ sliceByPosition() (3 tests)
  - Rows and columns
  - Rows only
  - Columns only
  
- ✅ sliceByLabelWithStep() (3 tests)
  - Row step
  - Column step
  - Both dimensions
  
- ✅ everyNthRow() (5 tests)
  - Various step sizes
  - With offset
  - Error handling
  
- ✅ everyNthColumn() (3 tests)
  - Various step sizes
  - With offset
  
- ✅ reverseRows() (3 tests)
  - Basic reversal
  - Preserves columns
  - Double reverse
  
- ✅ reverseColumns() (3 tests)
  - Basic reversal
  - Preserves data
  - Double reverse
  
- ✅ Real-world use cases (5 tests)
  - Downsampling
  - Feature selection
  - Reverse chronological
  - Range selection
  - Sampling
  
- ✅ Edge cases (4 tests)
  - Empty DataFrame
  - Large step
  - Single row
  - Start equals end

**Total: 44 tests, all passing ✅**

## Technical Implementation

### Key Design Decisions

1. **Python-Style Slicing**
   - Positive step: forward direction
   - Negative step: reverse direction
   - Inclusive end for label-based slicing
   - Exclusive end for position-based slicing

2. **Flexible Parameters**
   - Optional start/end with sensible defaults
   - Step parameter for all slicing operations
   - Axis parameter for row/column selection

3. **Convenience Methods**
   - everyNthRow/Column for common patterns
   - reverseRows/Columns for simple reversal
   - Clear, intuitive naming

4. **Error Handling**
   - Validates step != 0
   - Checks label existence
   - Clear error messages

### Performance Characteristics

- **slice():** O(n/step) where n is range size
- **sliceByLabel():** O(n) for label lookup + O(k) for slicing
- **everyNthRow():** O(n/step)
- **reverseRows():** O(n)

All operations use efficient index-based selection.

## Pandas Compatibility

These implementations closely follow pandas API:

| Feature | Pandas | DartFrame | Status |
|---------|--------|-----------|--------|
| df[start:end:step] | ✅ | ✅ | Implemented (slice) |
| df.loc[start:end] | ✅ | ✅ | Implemented (sliceByLabel) |
| df.iloc[start:end:step] | ✅ | ✅ | Implemented (slice) |
| df[::-1] | ✅ | ✅ | Implemented (reverseRows) |
| df[::n] | ✅ | ✅ | Implemented (everyNthRow) |

## Dependencies

No new dependencies added. Uses only:
- Existing DartFrame utilities (take method)
- Dart core libraries

## Breaking Changes

None. All new features are additive.

## Conclusion

Successfully implemented advanced slicing operations:
- ✅ slice() with step parameter
- ✅ sliceByLabel() for label-based ranges
- ✅ sliceByPosition() for combined slicing
- ✅ sliceByLabelWithStep() for label + step
- ✅ everyNthRow() and everyNthColumn() convenience methods
- ✅ reverseRows() and reverseColumns() for reversal
- ✅ 44 comprehensive tests
- ✅ Full documentation with examples
- ✅ Real-world use case demonstrations

All features are production-ready and fully tested.

## API Reference

### slice
```dart
DataFrame slice({
  int? start,
  int? end,
  int step = 1,
  int axis = 0,
})
```

### sliceByLabel
```dart
DataFrame sliceByLabel({
  dynamic start,
  dynamic end,
  int axis = 0,
})
```

### sliceByPosition
```dart
DataFrame sliceByPosition({
  List<int>? rowSlice,
  List<int>? colSlice,
})
```

### sliceByLabelWithStep
```dart
DataFrame sliceByLabelWithStep({
  dynamic rowStart,
  dynamic rowEnd,
  int rowStep = 1,
  dynamic colStart,
  dynamic colEnd,
  int colStep = 1,
})
```

### Convenience Methods
```dart
DataFrame everyNthRow(int n, {int offset = 0})
DataFrame everyNthColumn(int n, {int offset = 0})
DataFrame reverseRows()
DataFrame reverseColumns()
```

## Examples Repository

All examples from this document are available in the test suite:
- `test/advanced_slicing_test.dart`
