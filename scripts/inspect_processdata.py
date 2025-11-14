#!/usr/bin/env python3
"""
Inspect processdata.h5 using Python h5py to understand its true structure
"""

import h5py
import numpy as np

def inspect_dataset(name, obj):
    """Inspect a dataset and print its details"""
    if isinstance(obj, h5py.Dataset):
        print(f"\n{'='*80}")
        print(f"📊 Dataset: {name}")
        print(f"{'='*80}")
        print(f"  Shape: {obj.shape}")
        print(f"  Dtype: {obj.dtype}")
        print(f"  Size: {obj.size} elements")
        print(f"  Chunks: {obj.chunks}")
        print(f"  Compression: {obj.compression}")
        print(f"  Compression opts: {obj.compression_opts}")
        
        # Check if it's a virtual dataset
        if hasattr(obj, 'is_virtual') and obj.is_virtual:
            print(f"  ⚠️  VIRTUAL DATASET")
            try:
                print(f"  Virtual sources: {obj.virtual_sources()}")
            except:
                print(f"  (Cannot get virtual sources)")
        
        # Print attributes
        if len(obj.attrs) > 0:
            print(f"\n  🏷️  Attributes ({len(obj.attrs)}):")
            for attr_name, attr_value in obj.attrs.items():
                print(f"     - {attr_name}: {attr_value}")
        
        # Try to read data
        print(f"\n  📖 Attempting to read data...")
        try:
            data = obj[...]
            print(f"  ✅ Success! Shape: {data.shape}, Dtype: {data.dtype}")
            
            if data.size <= 10:
                print(f"  Data: {data}")
            else:
                print(f"  First 5 elements: {data.flat[:5]}")
                print(f"  Last 5 elements: {data.flat[-5:]}")
                print(f"  Min: {np.min(data)}, Max: {np.max(data)}, Mean: {np.mean(data)}")
        except Exception as e:
            print(f"  ❌ Failed to read: {e}")

def inspect_group(name, obj):
    """Inspect a group and print its details"""
    if isinstance(obj, h5py.Group):
        print(f"\n{'='*80}")
        print(f"📁 Group: {name}")
        print(f"{'='*80}")
        print(f"  Children: {list(obj.keys())}")
        
        # Print attributes
        if len(obj.attrs) > 0:
            print(f"\n  🏷️  Attributes ({len(obj.attrs)}):")
            for attr_name, attr_value in obj.attrs.items():
                print(f"     - {attr_name}: {attr_value}")

def main():
    filename = 'example/data/processdata.h5'
    
    print("="*80)
    print(f"🔬 Python h5py Inspection: {filename}")
    print("="*80)
    
    try:
        with h5py.File(filename, 'r') as f:
            print(f"\n📋 File Information:")
            print(f"   HDF5 Version: {h5py.version.hdf5_version}")
            print(f"   h5py Version: {h5py.version.version}")
            print(f"   Root keys: {list(f.keys())}")
            
            # Inspect root attributes
            if len(f.attrs) > 0:
                print(f"\n🏷️  Root Attributes ({len(f.attrs)}):")
                for attr_name, attr_value in f.attrs.items():
                    print(f"   - {attr_name}: {attr_value}")
            
            # Visit all objects
            print(f"\n{'='*80}")
            print("📂 Visiting all objects...")
            print(f"{'='*80}")
            
            def visitor(name, obj):
                if isinstance(obj, h5py.Dataset):
                    inspect_dataset(name, obj)
                elif isinstance(obj, h5py.Group):
                    inspect_group(name, obj)
            
            f.visititems(visitor)
            
            print(f"\n{'='*80}")
            print("✅ Inspection complete")
            print(f"{'='*80}")
            
    except Exception as e:
        print(f"\n❌ Error opening file: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
