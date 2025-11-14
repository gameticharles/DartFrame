#!/usr/bin/env python3
"""
Inspect the array and enum test files to understand their structure
"""

import h5py
import numpy as np

def inspect_file(filename):
    print(f"\n{'='*60}")
    print(f"Inspecting: {filename}")
    print(f"{'='*60}")
    
    with h5py.File(filename, 'r') as f:
        for name in f.keys():
            ds = f[name]
            print(f"\nDataset: {name}")
            print(f"  Shape: {ds.shape}")
            print(f"  Dtype: {ds.dtype}")
            print(f"  Data:\n{ds[:]}")
            
            # For compound types, show field details
            if ds.dtype.names:
                print(f"  Fields:")
                for field_name in ds.dtype.names:
                    field_dtype = ds.dtype.fields[field_name][0]
                    print(f"    {field_name}: {field_dtype}")

if __name__ == '__main__':
    inspect_file('test/fixtures/array_test.h5')
    inspect_file('test/fixtures/enum_test.h5')
