import h5py
import numpy as np

# Create an HDF5 file with chunked datasets
with h5py.File('example/data/test_chunked.h5', 'w') as f:
    # Create a simple 1D chunked dataset
    data1d = np.arange(20, dtype=np.float64)
    f.create_dataset('chunked_1d', data=data1d, chunks=(5,))
    
    # Create a 2D chunked dataset
    data2d = np.arange(60, dtype=np.int32).reshape(6, 10)
    f.create_dataset('chunked_2d', data=data2d, chunks=(2, 3))
    
    # Create a larger 2D chunked dataset
    data_large = np.arange(100, dtype=np.float32).reshape(10, 10)
    f.create_dataset('chunked_large', data=data_large, chunks=(3, 3))
    
    # Create a 3D chunked dataset (small)
    data3d = np.arange(24, dtype=np.int16).reshape(2, 3, 4)
    f.create_dataset('chunked_3d', data=data3d, chunks=(1, 2, 2))

print("Created test_chunked.h5 with:")
print("  - /chunked_1d: 1D array (20 elements), chunks=(5,)")
print("  - /chunked_2d: 2D array (6x10), chunks=(2, 3)")
print("  - /chunked_large: 2D array (10x10), chunks=(3, 3)")
print("  - /chunked_3d: 3D array (2x3x4), chunks=(1, 2, 2)")
