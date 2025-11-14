#!/usr/bin/env python3
"""
Create an HDF5 file with links using older format that stores links in object headers.
"""

import h5py
import numpy as np

def create_simple_links_test():
    """Create test file with links in object headers"""
    
    # Create file with older format (libver='earliest')
    with h5py.File('test_simple_links.h5', 'w', libver='earliest') as f:
        # Create some datasets
        f.create_dataset('data1', data=np.arange(10))
        f.create_dataset('data2', data=np.arange(20, 30))
        
        # Create a group
        grp = f.create_group('group1')
        grp.create_dataset('dataset_in_group', data=np.arange(100, 110))
        
        # Hard link
        f['data1_hardlink'] = f['data1']
        
        print("Created test_simple_links.h5 with old-style format:")
        print("  - Datasets: data1, data2")
        print("  - Group: group1 with dataset_in_group")
        print("  - Hard link: data1_hardlink -> data1")

if __name__ == '__main__':
    create_simple_links_test()
    print("\nTest file created successfully!")
