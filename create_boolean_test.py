#!/usr/bin/env python3
"""Create HDF5 file with boolean-like data for testing"""

import h5py
import numpy as np

# Create test file
with h5py.File('test_boolean.h5', 'w') as f:
    # Create boolean-like dataset (stored as uint8)
    bool_data = np.array([True, False, True, True, False], dtype=np.uint8)
    f.create_dataset('flags', data=bool_data)
    
    # Create 2D boolean array
    bool_2d = np.array([
        [True, False, True],
        [False, True, False],
        [True, True, False]
    ], dtype=np.uint8)
    f.create_dataset('mask_2d', data=bool_2d)
    
    # Add attributes
    f['flags'].attrs['description'] = 'Boolean flags stored as uint8'
    f['mask_2d'].attrs['description'] = '2D boolean mask'

print('Created test_boolean.h5')
print('Datasets:')
print('  /flags: 1D boolean array (5 elements)')
print('  /mask_2d: 2D boolean array (3x3)')
