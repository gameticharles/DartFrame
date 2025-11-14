#!/usr/bin/env python3
"""
Create simpler HDF5 test files to isolate array datatype issues
"""

import h5py
import numpy as np

def create_simple_tests():
    """Create simple test files with one array field"""
    
    # Test 1: Just an array field with integers
    with h5py.File('test/fixtures/simple_int_array.h5', 'w') as f:
        dt = np.dtype([('values', 'i4', (3,))])
        data = np.array([([10, 20, 30],), ([40, 50, 60],)], dtype=dt)
        f.create_dataset('data', data=data)
        print("Created simple_int_array.h5")
    
    # Test 2: Just an array field with floats
    with h5py.File('test/fixtures/simple_float_array.h5', 'w') as f:
        dt = np.dtype([('values', 'f4', (3,))])
        data = np.array([([1.1, 2.2, 3.3],), ([4.4, 5.5, 6.6],)], dtype=dt)
        f.create_dataset('data', data=data)
        print("Created simple_float_array.h5")
    
    # Test 3: Just an enum field
    with h5py.File('test/fixtures/simple_enum.h5', 'w') as f:
        color_enum = h5py.enum_dtype({'RED': 0, 'GREEN': 1, 'BLUE': 2}, basetype='i')
        dt = np.dtype([('color', color_enum)])
        data = np.array([(0,), (1,), (2,)], dtype=dt)
        f.create_dataset('data', data=data)
        print("Created simple_enum.h5")

if __name__ == '__main__':
    create_simple_tests()
