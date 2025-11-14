# HDF5 Attribute Reading Examples

This directory contains examples demonstrating the HDF5 attribute reading functionality in DartFrame.

## Examples

### 1. Print File Structure (`print_structure.dart`)

Prints the complete HDF5 file structure including all datasets, groups, and their attributes.

```dart
final file = await Hdf5File.open('data.h5');
await file.printStructure();
await file.close();
```

### 2. Get Structure as Map (`get_structure.dart`)

Retrieves the file structure as a map for programmatic access.

```dart
final file = await Hdf5File.open('data.h5');
final structure = await file.getStructure();

// Access specific information
print('Shape: ${structure['/data']['shape']}');
print('Units: ${structure['/data']['attributes']['units']['value']}');

await file.close();
```

### 3. Export to JSON (`structure_to_json.dart`)

Exports the complete file structure to a JSON file.

```dart
final file = await Hdf5File.open('data.h5');
final structure = await file.getStructure();

final jsonString = JsonEncoder.withIndent('  ').convert(structure);
await File('structure.json').writeAsString(jsonString);

await file.close();
```

### 4. Read Attributes Directly (`test_attributes.dart`)

Demonstrates reading attributes from specific datasets.

```dart
final file = await Hdf5File.open('data.h5');
final dataset = await file.dataset('/data');
final attributes = dataset.header.findAttributes();

for (final attr in attributes) {
  print('${attr.name}: ${attr.value}');
}

await file.close();
```

## Supported Attribute Types

DartFrame supports all common HDF5 attribute types:

- **Scalar attributes**: Single values (string, int, float)
- **Array attributes**: Lists of values
- **Variable-length strings**: Strings stored in the local heap
- **Numeric types**: Integers and floating-point numbers of various sizes
- **Compound types**: Structured data with named fields

## API Methods

### Hdf5File Methods

- `getStructure()`: Returns the complete file structure as a map
- `printStructure()`: Prints the file structure to console
- `dataset(path)`: Gets a dataset by path
- `group(path)`: Gets a group by path
- `getObjectType(path)`: Determines if a path is a dataset or group

### Dataset/Group Methods

- `header.findAttributes()`: Returns a list of all attributes
- `dataspace.dimensions`: Gets the shape of a dataset
- `datatype`: Gets the data type information

### Attribute Methods

- `getValue<T>()`: Gets a scalar attribute value as a specific type
- `getArray<T>()`: Gets an array attribute as a typed list
- `isScalar`: Checks if the attribute is a scalar
- `isArray`: Checks if the attribute is an array

## Test Files

The `test_attributes.h5` file contains:
- `/data`: 10x10 float64 dataset with 8 attributes
- `/measurements`: 50-element float64 dataset with 6 attributes
- `/experiment`: Group with 3 attributes
- `/experiment/results`: 5x5 int32 dataset with 2 attributes

Total: 19 attributes across 4 objects

## Creating Test Files

Use the Python scripts to create test files:

```bash
python create_attributes_test.py
python create_simple_attributes.py
```

These scripts use h5py to create HDF5 files with various attribute types for testing.
