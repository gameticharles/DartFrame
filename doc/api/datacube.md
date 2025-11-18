# DataCube API Reference

## Overview

`DataCube` is a 3-dimensional data structure that extends DataFrame concepts to multiple frames. It's ideal for time-series data, panel data, and multi-dimensional datasets.

## Constructor

### DataCube(List<DataFrame> frames, {List<String>? frameNames})

Creates a DataCube from a list of DataFrames.

```dart
final frame1 = DataFrame([
  {'name': 'Alice', 'age': 30},
  {'name': 'Bob', 'age': 25},
]);
final frame2 = DataFrame([
  {'name': 'Alice', 'age': 31},
  {'name': 'Bob', 'age': 26},
]);

final cube = DataCube([frame1, frame2], frameNames: ['2023', '2024']);
```

## Factory Constructors

### DataCube.empty(int depth, int rows, int cols, {List<String>? columnNames})

Creates an empty DataCube with specified dimensions.

```dart
final cube = DataCube.empty(10, 100, 5, 
  columnNames: ['A', 'B', 'C', 'D', 'E']
);
```

### DataCube.generate(int depth, int rows, int cols, dynamic Function(int, int, int) generator)

Creates a DataCube using a generator function.

```dart
final cube = DataCube.generate(3, 2, 2, (d, r, c) => d * 10 + r * 2 + c);
// Frame 0: [[0, 1], [2, 3]]
// Frame 1: [[10, 11], [12, 13]]
// Frame 2: [[20, 21], [22, 23]]
```

### DataCube.fromNDArray(NDArray array, {List<String>? columnNames, List<String>? frameNames})

Creates a DataCube from a 3D NDArray.

```dart
final array = NDArray([[[1, 2], [3, 4]], [[5, 6], [7, 8]]]);
final cube = DataCube.fromNDArray(array);
```

## Properties

### depth → int

Returns the number of frames (depth dimension).

```dart
final cube = DataCube.generate(5, 10, 3, (d, r, c) => 0);
print(cube.depth); // 5
```

### rows → int

Returns the number of rows per frame.

```dart
print(cube.rows); // 10
```

### cols → int

Returns the number of columns per frame.

```dart
print(cube.cols); // 3
```

### shape → List<int>

Returns the shape as [depth, rows, cols].

```dart
print(cube.shape); // [5, 10, 3]
```

### columnNames → List<String>

Returns the column names.

```dart
print(cube.columnNames); // ['col_0', 'col_1', 'col_2']
```

### frameNames → List<String>

Returns the frame names.

```dart
print(cube.frameNames); // ['frame_0', 'frame_1', ...]
```

## Frame Access

### getFrame(int index) → DataFrame

Gets a frame by index.

```dart
final frame = cube.getFrame(0);
```

### getFrameByName(String name) → DataFrame

Gets a frame by name.

```dart
final frame = cube.getFrameByName('2024');
```

### setFrame(int index, DataFrame frame)

Sets a frame at the specified index.

```dart
cube.setFrame(0, newFrame);
```

### frames → List<DataFrame>

Returns all frames as a list.

```dart
for (final frame in cube.frames) {
  print(frame);
}
```

## Value Access

### getValue(int depth, int row, int col) → dynamic

Gets a single value at the specified coordinates.

```dart
final value = cube.getValue(0, 5, 2);
```

### setValue(int depth, int row, int col, dynamic value)

Sets a single value at the specified coordinates.

```dart
cube.setValue(0, 5, 2, 42);
```

### getColumn(String columnName) → NDArray

Gets all values for a column across all frames as a 2D array.

```dart
final columnData = cube.getColumn('age');
// Shape: [depth, rows]
```

### getRow(int frameIndex, int rowIndex) → Map<String, dynamic>

Gets a row from a specific frame.

```dart
final row = cube.getRow(0, 5);
print(row); // {'name': 'Alice', 'age': 30, ...}
```

## Slicing & Selection

### slice(int startDepth, int endDepth, {int startRow = 0, int? endRow, int startCol = 0, int? endCol}) → DataCube

Extracts a sub-cube.

```dart
final subCube = cube.slice(0, 5, startRow: 10, endRow: 20);
// Frames 0-4, rows 10-19, all columns
```

### selectFrames(bool Function(DataFrame) condition) → DataCube

Selects frames that match a condition.

```dart
final selected = cube.selectFrames((frame) => 
  frame['age'].mean() > 30
);
```

### selectByIndices(List<int> frameIndices) → DataCube

Selects frames by their indices.

```dart
final selected = cube.selectByIndices([0, 2, 4]);
```

### whereColumn(String column, bool Function(dynamic) condition) → DataCube

Filters frames where a column meets a condition.

```dart
final filtered = cube.whereColumn('age', (age) => age > 25);
```

## Aggregation

### sum({int? axis}) → dynamic

Computes the sum across the specified axis.

```dart
// Sum all values
final total = cube.sum();

// Sum across depth (returns DataFrame)
final depthSum = cube.sum(axis: 0);

// Sum across rows (returns DataCube with 1 row)
final rowSum = cube.sum(axis: 1);
```

### mean({int? axis}) → dynamic

Computes the mean across the specified axis.

```dart
final avgByFrame = cube.mean(axis: 1); // Average per frame
```

### min({int? axis}) → dynamic

Finds the minimum value.

```dart
final minValue = cube.min();
```

### max({int? axis}) → dynamic

Finds the maximum value.

```dart
final maxValue = cube.max();
```

### std({int? axis}) → dynamic

Computes the standard deviation.

```dart
final stdDev = cube.std(axis: 0);
```

## Transformation

### map(dynamic Function(dynamic) fn) → DataCube

Applies a function to all values.

```dart
final doubled = cube.map((x) => x * 2);
```

### mapFrames(DataFrame Function(DataFrame) fn) → DataCube

Applies a function to each frame.

```dart
final normalized = cube.mapFrames((frame) => 
  frame.normalize()
);
```

### apply(dynamic Function(DataFrame) fn, {int? axis}) → dynamic

Applies a function along an axis.

```dart
// Apply to each frame
final result = cube.apply((frame) => frame['age'].sum(), axis: 0);
```

## Reshaping

### transpose({List<int>? axes}) → DataCube

Transposes the cube dimensions.

```dart
// Swap depth and rows
final transposed = cube.transpose(axes: [1, 0, 2]);
```

### flatten() → NDArray

Flattens the cube to a 1D array.

```dart
final flat = cube.flatten();
```

### toNDArray() → NDArray

Converts the cube to a 3D NDArray.

```dart
final array = cube.toNDArray();
```

## Combining

### concat(DataCube other, {int axis = 0}) → DataCube

Concatenates two cubes along an axis.

```dart
final combined = cube1.concat(cube2, axis: 0); // Stack frames
```

### merge(DataCube other, {String on, String how = 'inner'}) → DataCube

Merges two cubes frame-by-frame.

```dart
final merged = cube1.merge(cube2, on: 'id', how: 'left');
```

## Storage & I/O

### save(String path, {String format = 'hdf5', CompressionCodec? compression})

Saves the cube to disk.

```dart
await cube.save('data.h5', compression: ZstdCodec());
```

### static Future<DataCube> load(String path, {String format = 'hdf5'})

Loads a cube from disk.

```dart
final cube = await DataCube.load('data.h5');
```

### toCSV(String directory, {String prefix = 'frame'})

Exports each frame as a CSV file.

```dart
await cube.toCSV('output/', prefix: 'data');
// Creates: data_0.csv, data_1.csv, ...
```

## Lazy Operations

### lazy() → LazyDataCube

Creates a lazy version for deferred computation.

```dart
final lazy = cube.lazy()
  .map((x) => x * 2)
  .filter((x) => x > 10)
  .compute(); // Execute all operations
```

## Iteration

### forEach(void Function(int depth, int row, int col, dynamic value) fn)

Iterates over all values.

```dart
cube.forEach((d, r, c, value) {
  print('[$d, $r, $c] = $value');
});
```

### forEachFrame(void Function(int index, DataFrame frame) fn)

Iterates over frames.

```dart
cube.forEachFrame((index, frame) {
  print('Frame $index: ${frame.shape}');
});
```

## Validation

### validate() → bool

Validates the cube structure.

```dart
if (cube.validate()) {
  print('Cube is valid');
}
```

### isConsistent() → bool

Checks if all frames have consistent shapes.

```dart
if (cube.isConsistent()) {
  print('All frames have the same shape');
}
```

## See Also

- [NDArray API](ndarray.md)
- [Storage API](storage.md)
- [DataCube Basics Guide](../guides/datacube_basics.md)
