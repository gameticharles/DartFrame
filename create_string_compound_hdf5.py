#!/usr/bin/env python3
"""
Create HDF5 test files with string and compound datatypes
"""
import h5py
import numpy as np

def create_string_datasets():
    """Create HDF5 file with various string datasets"""
    print("Creating string_test.h5...")
    
    with h5py.File('test/fixtures/string_test.h5', 'w') as f:
        # Fixed-length ASCII strings
        ascii_data = np.array([b'hello', b'world', b'test'], dtype='S5')
        f.create_dataset('fixed_ascii', data=ascii_data)
        
        # Fixed-length UTF-8 strings (using h5py string dtype)
        utf8_data = np.array(['hello', 'world', 'test'], dtype=h5py.string_dtype(encoding='utf-8', length=10))
        f.create_dataset('fixed_utf8', data=utf8_data)
        
        # Variable-length ASCII strings
        vlen_ascii = h5py.special_dtype(vlen=bytes)
        vlen_ascii_data = np.array([b'short', b'a longer string', b'x'], dtype=vlen_ascii)
        ds = f.create_dataset('vlen_ascii', data=vlen_ascii_data)
        
        # Variable-length UTF-8 strings
        vlen_utf8 = h5py.special_dtype(vlen=str)
        vlen_utf8_data = np.array(['short', 'a longer string', 'x'], dtype=vlen_utf8)
        f.create_dataset('vlen_utf8', data=vlen_utf8_data)
        
    print("Created string_test.h5")

def create_compound_datasets():
    """Create HDF5 file with compound datatypes"""
    print("Creating compound_test.h5...")
    
    with h5py.File('test/fixtures/compound_test.h5', 'w') as f:
        # Simple compound type with numeric fields
        dt = np.dtype([
            ('x', 'i4'),
            ('y', 'i4'),
            ('value', 'f8')
        ])
        data = np.array([
            (1, 2, 3.14),
            (4, 5, 6.28),
            (7, 8, 9.42)
        ], dtype=dt)
        f.create_dataset('simple_compound', data=data)
        
        # Compound type with strings
        dt_with_string = np.dtype([
            ('id', 'i4'),
            ('name', 'S10'),
            ('score', 'f4')
        ])
        data_with_string = np.array([
            (1, b'Alice', 95.5),
            (2, b'Bob', 87.3),
            (3, b'Charlie', 92.1)
        ], dtype=dt_with_string)
        f.create_dataset('compound_with_string', data=data_with_string)
        
        # Nested compound (compound within compound)
        dt_nested = np.dtype([
            ('id', 'i4'),
            ('position', [('x', 'f8'), ('y', 'f8')]),
            ('velocity', [('vx', 'f8'), ('vy', 'f8')])
        ])
        data_nested = np.array([
            (1, (1.0, 2.0), (0.1, 0.2)),
            (2, (3.0, 4.0), (0.3, 0.4)),
            (3, (5.0, 6.0), (0.5, 0.6))
        ], dtype=dt_nested)
        f.create_dataset('nested_compound', data=data_nested)
        
    print("Created compound_test.h5")

def create_chunked_string_compound():
    """Create HDF5 file with chunked string and compound datasets"""
    print("Creating chunked_string_compound_test.h5...")
    
    with h5py.File('test/fixtures/chunked_string_compound_test.h5', 'w') as f:
        # Chunked fixed-length strings
        ascii_data = np.array([b'chunk1', b'chunk2', b'chunk3', b'chunk4'], dtype='S6')
        f.create_dataset('chunked_strings', data=ascii_data, chunks=(2,))
        
        # Chunked compound data
        dt = np.dtype([
            ('id', 'i4'),
            ('value', 'f8')
        ])
        data = np.array([
            (1, 1.1), (2, 2.2), (3, 3.3), (4, 4.4),
            (5, 5.5), (6, 6.6), (7, 7.7), (8, 8.8)
        ], dtype=dt)
        f.create_dataset('chunked_compound', data=data, chunks=(4,))
        
    print("Created chunked_string_compound_test.h5")

if __name__ == '__main__':
    import os
    os.makedirs('test/fixtures', exist_ok=True)
    
    create_string_datasets()
    create_compound_datasets()
    create_chunked_string_compound()
    
    print("\nAll test files created successfully!")
