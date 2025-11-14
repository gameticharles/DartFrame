import h5py
import numpy as np

# Create an HDF5 file with compressed datasets
with h5py.File('example/data/test_compressed.h5', 'w') as f:
    # Create a 1D dataset with gzip compression
    data1d = np.arange(100, dtype=np.float64)
    f.create_dataset('gzip_1d', data=data1d, chunks=(10,), compression='gzip', compression_opts=6)
    
    # Create a 2D dataset with gzip compression
    data2d = np.arange(200, dtype=np.int32).reshape(20, 10)
    f.create_dataset('gzip_2d', data=data2d, chunks=(5, 5), compression='gzip', compression_opts=6)
    
    # Create a dataset with gzip and shuffle filter
    data_shuffle = np.arange(100, dtype=np.float32)
    f.create_dataset('gzip_shuffle', data=data_shuffle, chunks=(10,), 
                     compression='gzip', compression_opts=6, shuffle=True)
    
    # Create a 2D dataset with shuffle only (for testing)
    data2d_shuffle = np.arange(60, dtype=np.int32).reshape(6, 10)
    f.create_dataset('shuffle_only', data=data2d_shuffle, chunks=(2, 5), shuffle=True)
    
    # Try to create LZF compressed datasets (requires hdf5plugin or h5py with LZF support)
    try:
        # Create a 1D dataset with LZF compression
        data_lzf_1d = np.arange(50, dtype=np.int32)
        f.create_dataset('lzf_1d', data=data_lzf_1d, chunks=(10,), compression='lzf')
        
        # Create a 2D dataset with LZF compression
        data_lzf_2d = np.arange(120, dtype=np.int32).reshape(12, 10)
        f.create_dataset('lzf_2d', data=data_lzf_2d, chunks=(4, 5), compression='lzf')
        
        print("Created test_compressed.h5 with:")
        print("  - /gzip_1d: 1D array (100 elements), gzip compressed")
        print("  - /gzip_2d: 2D array (20x10), gzip compressed")
        print("  - /gzip_shuffle: 1D array (100 elements), gzip + shuffle")
        print("  - /shuffle_only: 2D array (6x10), shuffle filter only")
        print("  - /lzf_1d: 1D array (50 elements), LZF compressed")
        print("  - /lzf_2d: 2D array (12x10), LZF compressed")
    except (ValueError, OSError) as e:
        print("Created test_compressed.h5 with:")
        print("  - /gzip_1d: 1D array (100 elements), gzip compressed")
        print("  - /gzip_2d: 2D array (20x10), gzip compressed")
        print("  - /gzip_shuffle: 1D array (100 elements), gzip + shuffle")
        print("  - /shuffle_only: 2D array (6x10), shuffle filter only")
        print("\nNote: LZF compression not available in this h5py installation")
        print("To enable LZF support, install: pip install hdf5plugin")
        print(f"Error: {e}")
