# H5PY Compatibility Tests

This directory contains tests to verify that HDF5 files written by the Dart HDF5 writer can be read correctly by Python's h5py library.

## Prerequisites

1. **Python 3.7+** installed
2. **h5py** and **numpy** packages:
   ```bash
   pip install h5py numpy
   ```

## Running the Tests

### Option 1: Run all compatibility tests
```bash
python test/h5py_compatibility_test.py
```

### Option 2: Run individual tests in Python
```python
import h5py
import numpy as np

# Read a file written by Dart
with h5py.File('example/data/test_simple_output.h5', 'r') as f:
    data = f['/data'][:]
    print(f"Shape: {data.shape}")
    print(f"Data: {data}")
    print(f"Dtype: {f['/data'].dtype}")
```

## Test Coverage

The compatibility tests verify:

1. **Simple 1D arrays** - Basic array reading
2. **2D arrays** - Multi-dimensional data
3. **Attributes** - Metadata attached to datasets
4. **File structure** - Comparison with reference files

## Expected Output

```
╔═══════════════════════════════════════════════════════════╗
║       HDF5 Writer h5py Compatibility Tests                ║
╚═══════════════════════════════════════════════════════════╝

h5py version: 3.x.x
HDF5 version: 1.x.x

Test 1: Simple 1D array
  ✓ Shape: (5,)
  ✓ Dtype: float64
  ✓ Data: [1. 2. 3. 4. 5.]
  ✅ Test passed!

Test 2: 2D array
  ✓ Shape: (2, 3)
  ✓ Data:
[[1. 2. 3.]
 [4. 5. 6.]]
  ✅ Test passed!

Test 3: Attributes
  ✓ Attribute 'units': meters
  ✓ Attribute 'description': Test data
  ✅ Test passed!

Test 4: Structure comparison with reference file
  Test file datasets: ['data']
  Reference file datasets: ['chunked_1d', 'chunked_2d', 'chunked_3d', 'chunked_large']
  ✓ Both files have valid structure
  ✅ Test passed!

════════════════════════════════════════════════════════════
SUMMARY
════════════════════════════════════════════════════════════

Tests passed: 4/4

✅ All h5py compatibility tests passed!
```

## Troubleshooting

### h5py not installed
```bash
pip install h5py numpy
```

### Test files not found
Run the Dart examples first to generate test files:
```bash
dart run example/test_simple_write.dart
```

### Permission errors
Ensure you have write permissions in the `test/fixtures/` directory.

## Compatibility Notes

The Dart HDF5 writer creates files compatible with:
- **Python**: h5py 2.x, 3.x
- **MATLAB**: R2011a and later
- **R**: rhdf5 package
- **Julia**: HDF5.jl package

Files use HDF5 format version 0 (superblock v0) for maximum compatibility.
