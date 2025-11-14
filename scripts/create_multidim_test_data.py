#!/usr/bin/env python3
"""
Create HDF5 test files with multi-dimensional datasets
"""
import h5py
import numpy as np
import os

# Create test_data directory if it doesn't exist
os.makedirs('test_data', exist_ok=True)

# Create 3D dataset
print("Creating 3D test file...")
with h5py.File('test_data/test_3d.h5', 'w') as f:
    # Create a 2x3x4 array
    data_3d = np.arange(24).reshape(2, 3, 4)
    f.create_dataset('volume', data=data_3d)
    print(f"  Created /volume with shape {data_3d.shape}")

# Create 4D dataset
print("Creating 4D test file...")
with h5py.File('test_data/test_4d.h5', 'w') as f:
    # Create a 2x3x4x5 array
    data_4d = np.arange(120).reshape(2, 3, 4, 5)
    f.create_dataset('tensor', data=data_4d)
    print(f"  Created /tensor with shape {data_4d.shape}")

# Create 5D dataset for extreme testing
print("Creating 5D test file...")
with h5py.File('test_data/test_5d.h5', 'w') as f:
    # Create a 2x2x2x2x2 array
    data_5d = np.arange(32).reshape(2, 2, 2, 2, 2)
    f.create_dataset('hypercube', data=data_5d)
    print(f"  Created /hypercube with shape {data_5d.shape}")

# Create mixed file with 1D, 2D, and 3D datasets
print("Creating mixed dimensionality test file...")
with h5py.File('test_data/test_mixed_dims.h5', 'w') as f:
    # 1D
    data_1d = np.arange(10)
    f.create_dataset('vector', data=data_1d)
    print(f"  Created /vector with shape {data_1d.shape}")
    
    # 2D
    data_2d = np.arange(20).reshape(4, 5)
    f.create_dataset('matrix', data=data_2d)
    print(f"  Created /matrix with shape {data_2d.shape}")
    
    # 3D
    data_3d = np.arange(60).reshape(3, 4, 5)
    f.create_dataset('cube', data=data_3d)
    print(f"  Created /cube with shape {data_3d.shape}")

print("\nTest files created successfully!")
print("Run tests with: dart test test/integration/hdf5_multidim_test.dart")
