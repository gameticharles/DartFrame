# HDF5 Attribute Support

## Overview

DartFrame now supports reading attributes from HDF5 datasets and groups. Attributes are metadata that provide additional information about the data, such as units, descriptions, calibration information, etc.

## Usage

### Reading Attributes from a Dataset

```dart
import 'package:dartframe/dartframe.dart';

// Read attributes using HDF5Reader
final attrs = await HDF5Reader.readAttributes(
  'data.h5',
  dataset: '/mydata',
);

// Access attribute values
print(attrs['units']);        // e.g., 'meters'
print(attrs['description']);  // e.g., 'Temperature measurements'
print(attrs['version']);      // e.g., 1.0
```

### Using the Low-Level API

```dart
import 'package:dartframe/src/io/hdf5/hdf5_file.dart';

final file = await Hdf5File.open('data.h5');
final dataset = await file.dataset('/mydata');

// List all attribute names
final attrNames = dataset.listAttributes();
print('Attributes: $attrNames');

// Get a specific attribute
final unitsAttr = dataset.getAttribute('units');
if (unitsAttr != null) {
  print('Units: ${unitsAttr.value}');
}

// Get all attributes
for (final attr in dataset.attributes) {
  print('${attr.name}: ${attr.value}');
}

await file.close();
```

### Attribute Types

Attributes can contain:
- **Scalar values**: Single numbers or strings
- **Array values**: Lists of numbers or strings
- **Compound values**: Structured data with multiple fields

```dart
// Scalar attribute
final version = attr.getValue<double>();

// Array attribute
final range = attr.getArray<double>();  // [min, max]

// Check attribute type
if (attr.isScalar) {
  print('Scalar value: ${attr.value}');
} else if (attr.isArray) {
  print('Array with ${attr.value.length} elements');
}
```

## Supported Datatypes

Currently supported attribute datatypes:
- Integers (int8, int16, int32, int64)
- Floating-point (float32, float64)
- Fixed-length strings
- Compound types (structs)
- Arrays of the above types

## Limitations

- Variable-length strings in attributes are not yet supported
- Some older HDF5 datatype versions (created by certain tools) may not be fully supported
- Enum and reference datatypes in attributes are not yet supported

## Examples

### Scientific Data with Metadata

```dart
// Read dataset with calibration attributes
final data = await HDF5Reader.read('experiment.h5', options: {'dataset': '/sensor1'});
final attrs = await HDF5Reader.readAttributes('experiment.h5', dataset: '/sensor1');

print('Sensor: ${attrs['sensor_name']}');
print('Location: ${attrs['location']}');
print('Calibration date: ${attrs['calibration_date']}');
print('Units: ${attrs['units']}');

// Apply calibration
final offset = attrs['offset'] as double;
final scale = attrs['scale'] as double;
// ... use offset and scale with data
```

### Inspecting File Metadata

```dart
final file = await Hdf5File.open('data.h5');

for (final datasetName in file.root.children) {
  final ds = await file.dataset('/$datasetName');
  
  print('\nDataset: $datasetName');
  print('Shape: ${ds.shape}');
  print('Type: ${ds.datatype.typeName}');
  
  if (ds.attributes.isNotEmpty) {
    print('Attributes:');
    for (final attr in ds.attributes) {
      print('  ${attr.name}: ${attr.value}');
    }
  }
}

await file.close();
```

## Future Enhancements

Planned improvements for attribute support:
- Variable-length string attributes
- Support for all HDF5 datatype versions
- Enum and reference datatypes
- Writing attributes (currently read-only)
- Group attributes (partially supported)

## See Also

- [HDF5 Reading Guide](hdf5_error_handling.md)
- [Datatype Support](../DATATYPE_REFACTOR.md)
- [HDF5 Specification](https://portal.hdfgroup.org/display/HDF5/HDF5)
