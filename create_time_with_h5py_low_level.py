#!/usr/bin/env python3
"""
Try to create HDF5 file with actual time datatype using low-level h5py API
Note: HDF5 time datatype is rarely used in practice
"""

import h5py
import numpy as np
from datetime import datetime, timezone

# According to HDF5 spec, time datatype (class 2) exists but is rarely implemented
# Most tools use int64 timestamps instead

# Let's check if we can inspect the datatype class
with h5py.File('test_time.h5', 'r') as f:
    ds = f['timestamps']
    dtype = ds.dtype
    print(f'Dataset dtype: {dtype}')
    print(f'Dataset dtype kind: {dtype.kind}')
    print(f'Dataset dtype itemsize: {dtype.itemsize}')
    
    # Get the HDF5 datatype ID
    tid = ds.id.get_type()
    print(f'HDF5 type class: {tid.get_class()}')
    print(f'HDF5 type size: {tid.get_size()}')
    
    # Type classes:
    # 0 = H5T_INTEGER
    # 1 = H5T_FLOAT
    # 2 = H5T_TIME (rarely used)
    # 3 = H5T_STRING
    # etc.

print('\nNote: HDF5 time datatype (class 2) is rarely used.')
print('Most applications store timestamps as int64 (class 0).')
print('DartFrame can provide a helper method to convert int64 timestamps to DateTime.')
