#!/usr/bin/env python3
"""
Create HDF5 test file with array datatypes for testing.
This file tests Requirements 3.6: Array datatype support
"""

import h5py
import numpy as np

def create_array_datatype_test():
    """Create HDF5 file with various array datatypes"""
    
    with h5py.File('test/fixtures/array_test.h5', 'w') as f:
        # Test 1: Simple 1D array field in compound type
        # Each record has a 3-element integer array
        dt1 = np.dtype([
            ('id', 'i4'),
            ('values', 'i4', (3,))
        ])
        data1 = np.array([
            (1, [10, 20, 30]),
            (2, [40, 50, 60]),
            (3, [70, 80, 90])
        ], dtype=dt1)
        f.create_dataset('simple_array', data=data1)
        
        # Test 2: 2D array field in compound type
        # Each record has a 2x3 float array
        dt2 = np.dtype([
            ('name', 'S10'),
            ('matrix', 'f4', (2, 3))
        ])
        data2 = np.array([
            (b'first', [[1.1, 1.2, 1.3], [1.4, 1.5, 1.6]]),
            (b'second', [[2.1, 2.2, 2.3], [2.4, 2.5, 2.6]]),
        ], dtype=dt2)
        f.create_dataset('matrix_array', data=data2)
        
        # Test 3: Multiple array fields
        dt3 = np.dtype([
            ('id', 'i4'),
            ('coords', 'f8', (3,)),
            ('flags', 'u1', (4,))
        ])
        data3 = np.array([
            (1, [1.0, 2.0, 3.0], [1, 0, 1, 0]),
            (2, [4.0, 5.0, 6.0], [0, 1, 0, 1]),
        ], dtype=dt3)
        f.create_dataset('multi_array', data=data3)
        
        # Test 4: Nested structure with arrays
        dt4 = np.dtype([
            ('timestamp', 'i8'),
            ('measurements', 'f4', (5,)),
            ('status', 'i2')
        ])
        data4 = np.array([
            (1000, [1.1, 2.2, 3.3, 4.4, 5.5], 1),
            (2000, [6.6, 7.7, 8.8, 9.9, 10.0], 2),
            (3000, [11.1, 12.2, 13.3, 14.4, 15.5], 3),
        ], dtype=dt4)
        f.create_dataset('sensor_data', data=data4)
        
        print("Created test/fixtures/array_test.h5 with array datatypes")
        print("Datasets:")
        print("  - simple_array: compound with 1D array field")
        print("  - matrix_array: compound with 2D array field")
        print("  - multi_array: compound with multiple array fields")
        print("  - sensor_data: compound with array measurements")

if __name__ == '__main__':
    create_array_datatype_test()
