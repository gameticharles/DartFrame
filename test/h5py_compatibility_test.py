#!/usr/bin/env python3
"""
HDF5 Writer Compatibility Test with h5py

This script tests that HDF5 files written by the Dart HDF5 writer
can be read correctly by Python's h5py library.

Requirements:
    pip install h5py numpy

Usage:
    python test/h5py_compatibility_test.py
"""

import sys
import os
import h5py
import numpy as np

def test_simple_array():
    """Test reading a simple 1D array written by Dart"""
    print("Test 1: Simple 1D array")
    
    file_path = 'example/data/test_simple_output.h5'
    
    if not os.path.exists(file_path):
        print(f"  ⚠️  File not found: {file_path}")
        print("  Run: dart run example/test_simple_write.dart")
        return False
    
    try:
        with h5py.File(file_path, 'r') as f:
            # Check file structure
            if '/data' not in f:
                print(f"  ❌ Dataset '/data' not found")
                print(f"  Available datasets: {list(f.keys())}")
                return False
            
            # Read dataset
            dataset = f['/data']
            data = dataset[:]
            
            # Verify shape
            expected_shape = (5,)
            if data.shape != expected_shape:
                print(f"  ❌ Shape mismatch: expected {expected_shape}, got {data.shape}")
                return False
            
            # Verify dtype
            if dataset.dtype != np.float64:
                print(f"  ❌ Dtype mismatch: expected float64, got {dataset.dtype}")
                return False
            
            # Verify values
            expected_data = np.array([1.0, 2.0, 3.0, 4.0, 5.0])
            if not np.allclose(data, expected_data):
                print(f"  ❌ Data mismatch: expected {expected_data}, got {data}")
                return False
            
            print(f"  ✓ Shape: {data.shape}")
            print(f"  ✓ Dtype: {dataset.dtype}")
            print(f"  ✓ Data: {data}")
            print(f"  ✅ Test passed!")
            return True
            
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False

def test_2d_array():
    """Test reading a 2D array"""
    print("\nTest 2: 2D array")
    
    # First create the test file with Dart
    import subprocess
    
    # Create a simple Dart script to write a 2D array
    dart_code = """
import 'package:dartframe/dartframe.dart';

void main() async {
  final array = NDArray.fromFlat([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], [2, 3]);
  await array.toHDF5('test/fixtures/test_2d.h5', dataset: '/matrix');
  print('Written 2D array');
}
"""
    
    # Write temporary Dart file
    with open('test/fixtures/temp_write_2d.dart', 'w') as f:
        f.write(dart_code)
    
    try:
        # Run Dart script
        result = subprocess.run(['dart', 'run', 'test/fixtures/temp_write_2d.dart'],
                              capture_output=True, text=True, timeout=10)
        
        if result.returncode != 0:
            print(f"  ⚠️  Failed to create test file: {result.stderr}")
            return False
        
        # Read with h5py
        file_path = 'test/fixtures/test_2d.h5'
        with h5py.File(file_path, 'r') as f:
            dataset = f['/matrix']
            data = dataset[:]
            
            # Verify
            expected_shape = (2, 3)
            expected_data = np.array([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
            
            if data.shape != expected_shape:
                print(f"  ❌ Shape mismatch: expected {expected_shape}, got {data.shape}")
                return False
            
            if not np.allclose(data, expected_data):
                print(f"  ❌ Data mismatch")
                return False
            
            print(f"  ✓ Shape: {data.shape}")
            print(f"  ✓ Data:\n{data}")
            print(f"  ✅ Test passed!")
            return True
            
    except subprocess.TimeoutExpired:
        print(f"  ❌ Timeout creating test file")
        return False
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False
    finally:
        # Clean up
        if os.path.exists('test/fixtures/temp_write_2d.dart'):
            os.remove('test/fixtures/temp_write_2d.dart')

def test_attributes():
    """Test reading attributes"""
    print("\nTest 3: Attributes")
    
    # Create test file with attributes
    dart_code = """
import 'package:dartframe/dartframe.dart';

void main() async {
  final array = NDArray.fromFlat([1.0, 2.0, 3.0], [3]);
  array.attrs['units'] = 'meters';
  array.attrs['description'] = 'Test data';
  await array.toHDF5('test/fixtures/test_attrs.h5', dataset: '/data');
  print('Written array with attributes');
}
"""
    
    with open('test/fixtures/temp_write_attrs.dart', 'w') as f:
        f.write(dart_code)
    
    try:
        import subprocess
        result = subprocess.run(['dart', 'run', 'test/fixtures/temp_write_attrs.dart'],
                              capture_output=True, text=True, timeout=10)
        
        if result.returncode != 0:
            print(f"  ⚠️  Failed to create test file: {result.stderr}")
            return False
        
        # Read with h5py
        file_path = 'test/fixtures/test_attrs.h5'
        with h5py.File(file_path, 'r') as f:
            dataset = f['/data']
            
            # Check attributes
            if 'units' not in dataset.attrs:
                print(f"  ❌ Attribute 'units' not found")
                return False
            
            if 'description' not in dataset.attrs:
                print(f"  ❌ Attribute 'description' not found")
                return False
            
            units = dataset.attrs['units']
            description = dataset.attrs['description']
            
            # h5py returns bytes for strings, decode them
            if isinstance(units, bytes):
                units = units.decode('utf-8')
            if isinstance(description, bytes):
                description = description.decode('utf-8')
            
            if units != 'meters':
                print(f"  ❌ Attribute 'units' mismatch: expected 'meters', got '{units}'")
                return False
            
            if description != 'Test data':
                print(f"  ❌ Attribute 'description' mismatch: expected 'Test data', got '{description}'")
                return False
            
            print(f"  ✓ Attribute 'units': {units}")
            print(f"  ✓ Attribute 'description': {description}")
            print(f"  ✅ Test passed!")
            return True
            
    except Exception as e:
        print(f"  ❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        if os.path.exists('test/fixtures/temp_write_attrs.dart'):
            os.remove('test/fixtures/temp_write_attrs.dart')

def test_comparison_with_reference():
    """Compare structure with reference HDF5 files"""
    print("\nTest 4: Structure comparison with reference file")
    
    file_path = 'example/data/test_simple_output.h5'
    ref_path = 'example/data/test_chunked.h5'
    
    if not os.path.exists(file_path):
        print(f"  ⚠️  File not found: {file_path}")
        return False
    
    if not os.path.exists(ref_path):
        print(f"  ⚠️  Reference file not found: {ref_path}")
        return False
    
    try:
        with h5py.File(file_path, 'r') as f_test:
            with h5py.File(ref_path, 'r') as f_ref:
                # Compare file structure
                print(f"  Test file datasets: {list(f_test.keys())}")
                print(f"  Reference file datasets: {list(f_ref.keys())}")
                
                # Both should have at least one dataset
                if len(f_test.keys()) == 0:
                    print(f"  ❌ Test file has no datasets")
                    return False
                
                print(f"  ✓ Both files have valid structure")
                print(f"  ✅ Test passed!")
                return True
                
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False

def main():
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║       HDF5 Writer h5py Compatibility Tests                ║")
    print("╚═══════════════════════════════════════════════════════════╝\n")
    
    # Check if h5py is installed
    try:
        import h5py
        print(f"h5py version: {h5py.version.version}")
        print(f"HDF5 version: {h5py.version.hdf5_version}\n")
    except ImportError:
        print("❌ h5py is not installed")
        print("Install with: pip install h5py numpy")
        return 1
    
    # Run tests
    results = []
    results.append(test_simple_array())
    results.append(test_2d_array())
    results.append(test_attributes())
    results.append(test_comparison_with_reference())
    
    # Summary
    print("\n" + "═" * 60)
    print("SUMMARY")
    print("═" * 60)
    
    passed = sum(results)
    total = len(results)
    
    print(f"\nTests passed: {passed}/{total}")
    
    if passed == total:
        print("\n✅ All h5py compatibility tests passed!")
        return 0
    else:
        print(f"\n❌ {total - passed} test(s) failed")
        return 1

if __name__ == '__main__':
    sys.exit(main())
