#!/usr/bin/env python3
"""
Create HDF5 test file with enum datatypes for testing.
This file tests Requirements 3.6: Enum datatype support
"""

import h5py
import numpy as np

def create_enum_datatype_test():
    """Create HDF5 file with various enum datatypes"""
    
    with h5py.File('test/fixtures/enum_test.h5', 'w') as f:
        # Test 1: Simple enum dataset
        # Define color enum: RED=0, GREEN=1, BLUE=2
        color_enum = h5py.enum_dtype({'RED': 0, 'GREEN': 1, 'BLUE': 2}, basetype='i')
        data1 = np.array([0, 1, 2, 1, 0], dtype='i')
        ds1 = f.create_dataset('colors', data=data1, dtype=color_enum)
        
        # Test 2: Status enum with more values
        status_enum = h5py.enum_dtype({
            'IDLE': 0,
            'RUNNING': 1,
            'PAUSED': 2,
            'STOPPED': 3,
            'ERROR': 4
        }, basetype='i')
        data2 = np.array([0, 1, 1, 2, 3, 1, 4], dtype='i')
        ds2 = f.create_dataset('status', data=data2, dtype=status_enum)
        
        # Test 3: Enum in compound type
        priority_enum = h5py.enum_dtype({
            'LOW': 0,
            'MEDIUM': 1,
            'HIGH': 2,
            'CRITICAL': 3
        }, basetype='i')
        
        dt3 = np.dtype([
            ('id', 'i4'),
            ('priority', priority_enum),
            ('value', 'f4')
        ])
        data3 = np.array([
            (1, 0, 10.5),
            (2, 2, 20.3),
            (3, 3, 30.1),
            (4, 1, 40.7),
        ], dtype=dt3)
        f.create_dataset('tasks', data=data3)
        
        # Test 4: Multiple enums in compound
        day_enum = h5py.enum_dtype({
            'MONDAY': 0,
            'TUESDAY': 1,
            'WEDNESDAY': 2,
            'THURSDAY': 3,
            'FRIDAY': 4,
            'SATURDAY': 5,
            'SUNDAY': 6
        }, basetype='i')
        
        weather_enum = h5py.enum_dtype({
            'SUNNY': 0,
            'CLOUDY': 1,
            'RAINY': 2,
            'SNOWY': 3
        }, basetype='i')
        
        dt4 = np.dtype([
            ('day', day_enum),
            ('weather', weather_enum),
            ('temperature', 'f4')
        ])
        data4 = np.array([
            (0, 0, 25.5),  # Monday, Sunny, 25.5°C
            (1, 1, 22.3),  # Tuesday, Cloudy, 22.3°C
            (2, 2, 18.7),  # Wednesday, Rainy, 18.7°C
        ], dtype=dt4)
        f.create_dataset('weather_log', data=data4)
        
        # Test 5: Enum with uint8 base type
        level_enum = h5py.enum_dtype({
            'TRACE': 0,
            'DEBUG': 1,
            'INFO': 2,
            'WARN': 3,
            'ERROR': 4,
            'FATAL': 5
        }, basetype='u1')
        data5 = np.array([2, 2, 3, 4, 2, 1], dtype='u1')
        ds5 = f.create_dataset('log_levels', data=data5, dtype=level_enum)
        
        print("Created test/fixtures/enum_test.h5 with enum datatypes")
        print("Datasets:")
        print("  - colors: simple color enum (RED, GREEN, BLUE)")
        print("  - status: status enum (IDLE, RUNNING, PAUSED, STOPPED, ERROR)")
        print("  - tasks: compound with priority enum")
        print("  - weather_log: compound with day and weather enums")
        print("  - log_levels: enum with uint8 base type")

if __name__ == '__main__':
    create_enum_datatype_test()
