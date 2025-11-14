#!/usr/bin/env python3
"""Create HDF5 file with variable-length data for testing"""

import h5py
import numpy as np

# Create test file
with h5py.File('test_vlen.h5', 'w') as f:
    # Create variable-length string dataset
    vlen_str_type = h5py.string_dtype(encoding='utf-8')
    vlen_strings = ['Hello', 'World', 'Variable', 'Length', 'Strings!']
    f.create_dataset('vlen_strings', data=vlen_strings, dtype=vlen_str_type)
    
    # Create 2D variable-length string array
    vlen_2d = np.array([
        ['short', 'a bit longer', 'x'],
        ['medium length', 'y', 'another string'],
        ['z', 'final', 'test']
    ], dtype=object)
    f.create_dataset('vlen_strings_2d', data=vlen_2d, dtype=vlen_str_type)
    
    # Create variable-length integer array
    vlen_int_type = h5py.vlen_dtype(np.int32)
    vlen_ints = [
        np.array([1, 2, 3], dtype=np.int32),
        np.array([4, 5], dtype=np.int32),
        np.array([6, 7, 8, 9], dtype=np.int32),
    ]
    f.create_dataset('vlen_ints', data=vlen_ints, dtype=vlen_int_type)
    
    # Add attributes
    f['vlen_strings'].attrs['description'] = 'Variable-length UTF-8 strings'
    f['vlen_strings_2d'].attrs['description'] = '2D array of vlen strings'
    f['vlen_ints'].attrs['description'] = 'Variable-length integer arrays'

print('Created test_vlen.h5')
print('Datasets:')
print('  /vlen_strings: 1D vlen string array (5 elements)')
print('  /vlen_strings_2d: 2D vlen string array (3x3)')
print('  /vlen_ints: 1D vlen int array (3 elements, varying lengths)')
