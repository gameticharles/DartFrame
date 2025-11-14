import h5py
import numpy as np

# Create a simple HDF5 file
with h5py.File('test_simple.h5', 'w') as f:
    # Create a simple 1D dataset
    data1d = np.array([1.0, 2.0, 3.0, 4.0, 5.0])
    f.create_dataset('data1d', data=data1d)
    
    # Create a 2D dataset
    data2d = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
    f.create_dataset('data2d', data=data2d)
    
    # Create a group with a dataset
    grp = f.create_group('mygroup')
    grp.create_dataset('nested_data', data=np.array([10, 20, 30]))

print("Created test_simple.h5 with:")
print("  - /data1d: 1D array of 5 floats")
print("  - /data2d: 2D array (3x3) of integers")
print("  - /mygroup/nested_data: 1D array of 3 integers")
