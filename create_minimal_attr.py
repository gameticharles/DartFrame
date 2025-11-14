#!/usr/bin/env python3
"""Create minimal HDF5 file with one attribute"""

import h5py
import numpy as np

# Try with latest format to see if it works better
with h5py.File('example/data/test_attr_simple.h5', 'w', libver='latest') as f:
    ds = f.create_dataset('data', data=np.arange(10, dtype=np.float64))
    ds.attrs['test'] = 'hello'
    ds.attrs['number'] = 42

print("Created test_attr_simple.h5 with latest format")
