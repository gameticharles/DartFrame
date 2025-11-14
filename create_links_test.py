#!/usr/bin/env python3
"""
Create an HDF5 file with various link types for testing link message support.
"""

import h5py
import numpy as np

def create_links_test_file():
    """Create test file with hard, soft, and external links"""
    
    # Create main test file
    with h5py.File('test_links.h5', 'w') as f:
        # Create some datasets
        f.create_dataset('data1', data=np.arange(10))
        f.create_dataset('data2', data=np.arange(20, 30))
        
        # Create a group with a dataset
        grp = f.create_group('group1')
        grp.create_dataset('dataset_in_group', data=np.arange(100, 110))
        
        # Create a nested group
        nested = grp.create_group('nested')
        nested.create_dataset('nested_data', data=np.array([1, 2, 3, 4, 5]))
        
        # Create hard link (another name for the same object)
        f['data1_hardlink'] = f['data1']
        
        # Create soft link (symbolic link by path)
        f['data1_softlink'] = h5py.SoftLink('/data1')
        f['group1_softlink'] = h5py.SoftLink('/group1')
        f['nested_softlink'] = h5py.SoftLink('/group1/nested/nested_data')
        
        # Create a soft link to another soft link (chain)
        f['softlink_chain'] = h5py.SoftLink('/data1_softlink')
        
        print("Created test_links.h5 with:")
        print("  - Datasets: data1, data2")
        print("  - Group: group1 with dataset_in_group")
        print("  - Nested group: group1/nested with nested_data")
        print("  - Hard link: data1_hardlink -> data1")
        print("  - Soft links: data1_softlink, group1_softlink, nested_softlink")
        print("  - Soft link chain: softlink_chain -> data1_softlink -> data1")
    
    # Create external file for external link testing
    with h5py.File('test_external.h5', 'w') as f:
        f.create_dataset('external_data', data=np.arange(50, 60))
        print("\nCreated test_external.h5 with:")
        print("  - Dataset: external_data")
    
    # Add external link to main file
    with h5py.File('test_links.h5', 'a') as f:
        f['external_link'] = h5py.ExternalLink('test_external.h5', '/external_data')
        print("\nAdded external link to test_links.h5:")
        print("  - external_link -> test_external.h5:/external_data")

if __name__ == '__main__':
    create_links_test_file()
    print("\nTest files created successfully!")
