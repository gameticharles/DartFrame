#!/usr/bin/env python3
"""Check HDF5 file version and structure"""

import h5py

with h5py.File('example/data/test_attributes.h5', 'r') as f:
    print(f"HDF5 File Version: {f.libver}")
    print(f"File format version: {f.id.get_vfd_handle()}")
    
    # Check dataset
    ds = f['data']
    print(f"\nDataset 'data':")
    print(f"  Shape: {ds.shape}")
    print(f"  Dtype: {ds.dtype}")
    print(f"  Chunks: {ds.chunks}")
    print(f"  Compression: {ds.compression}")
    print(f"  Number of attributes: {len(ds.attrs)}")
    
    for name, value in ds.attrs.items():
        print(f"    {name}: {value} (type: {type(value).__name__})")
