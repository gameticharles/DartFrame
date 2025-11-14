#!/usr/bin/env python3
"""
Analyze compound datatype structure using h5py low-level API
"""
import h5py
import numpy as np

# Open file and get dataset
with h5py.File('test/fixtures/compound_test.h5', 'r') as f:
    ds = f['/simple_compound']
    
    print("Dataset: /simple_compound")
    print(f"Shape: {ds.shape}")
    print(f"Dtype: {ds.dtype}")
    print(f"Itemsize: {ds.dtype.itemsize}")
    print(f"\nFields:")
    for name in ds.dtype.names:
        field_dtype, offset = ds.dtype.fields[name]
        print(f"  {name}: offset={offset}, dtype={field_dtype}, size={field_dtype.itemsize}")
    
    print(f"\nData:")
    data = ds[:]
    for i, row in enumerate(data):
        print(f"  [{i}]: {row}")
    
    # Get the HDF5 type ID
    print(f"\nHDF5 Type ID: {ds.id.get_type()}")
    type_id = ds.id.get_type()
    print(f"Type class: {type_id.get_class()}")
    print(f"Type size: {type_id.get_size()}")
    
    if type_id.get_class() == h5py.h5t.COMPOUND:
        nmembers = type_id.get_nmembers()
        print(f"Number of members: {nmembers}")
        for i in range(nmembers):
            name = type_id.get_member_name(i)
            offset = type_id.get_member_offset(i)
            member_type = type_id.get_member_type(i)
            print(f"  Member {i}: name={name}, offset={offset}")
            print(f"    Type class: {member_type.get_class()}")
            print(f"    Type size: {member_type.get_size()}")
