#!/usr/bin/env python3
"""Inspect the attributes test file"""

import h5py

with h5py.File('example/data/test_attributes.h5', 'r') as f:
    print("File structure:")
    
    def print_attrs(name, obj):
        print(f"\n{name}:")
        print(f"  Type: {type(obj).__name__}")
        if isinstance(obj, h5py.Dataset):
            print(f"  Shape: {obj.shape}")
            print(f"  Dtype: {obj.dtype}")
        print(f"  Attributes ({len(obj.attrs)}):")
        for key, value in obj.attrs.items():
            print(f"    {key}: {value} (type: {type(value).__name__})")
    
    f.visititems(print_attrs)
