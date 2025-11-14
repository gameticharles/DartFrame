#!/usr/bin/env python3
"""
Create a simple HDF5 file with attributes using older format for better compatibility.
"""

import h5py
import numpy as np

def create_test_file():
    """Create test HDF5 file with various attributes using older format"""
    
    # Use earliest format for maximum compatibility
    with h5py.File('example/data/test_attributes.h5', 'w', libver='earliest') as f:
        # Create a simple dataset
        data = np.arange(100, dtype=np.float64).reshape(10, 10)
        ds = f.create_dataset('data', data=data)
        
        # Add scalar attributes
        ds.attrs['units'] = 'meters'
        ds.attrs['description'] = 'Test dataset with attributes'
        ds.attrs['version'] = 1.0
        ds.attrs['count'] = 100
        
        # Add array attributes
        ds.attrs['range'] = np.array([0.0, 100.0])
        ds.attrs['dimensions'] = np.array([10, 10])
        
        # Add string attributes
        ds.attrs['author'] = 'Test Suite'
        ds.attrs['date'] = '2024-01-01'
        
        # Create another dataset with different attributes
        data2 = np.random.randn(50)
        ds2 = f.create_dataset('measurements', data=data2)
        
        ds2.attrs['sensor'] = 'Temperature Sensor A'
        ds2.attrs['location'] = 'Lab Room 101'
        ds2.attrs['calibration_date'] = '2023-12-15'
        ds2.attrs['min_value'] = float(np.min(data2))
        ds2.attrs['max_value'] = float(np.max(data2))
        ds2.attrs['mean_value'] = float(np.mean(data2))
        
        # Create a group with attributes
        grp = f.create_group('experiment')
        grp.attrs['name'] = 'Experiment 001'
        grp.attrs['status'] = 'completed'
        grp.attrs['samples'] = 1000
        
        # Create dataset in group with attributes
        data3 = np.ones((5, 5), dtype=np.int32)
        ds3 = grp.create_dataset('results', data=data3)
        ds3.attrs['units'] = 'counts'
        ds3.attrs['threshold'] = 10
    
    print("Created test_attributes.h5 with earliest format:")
    print("  - /data: 10x10 float64 array with 8 attributes")
    print("  - /measurements: 50-element float64 array with 6 attributes")
    print("  - /experiment (group) with 3 attributes")
    print("  - /experiment/results: 5x5 int32 array with 2 attributes")

if __name__ == '__main__':
    create_test_file()
