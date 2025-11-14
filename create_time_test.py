#!/usr/bin/env python3
"""Create HDF5 file with time datatype for testing"""

import h5py
import numpy as np
from datetime import datetime, timezone

# Create test file
with h5py.File('test_time.h5', 'w') as f:
    # Create time datatype (stored as Unix timestamps)
    # Note: h5py doesn't have native time type, so we'll use int64 with time semantics
    
    # Create timestamps (seconds since epoch)
    timestamps = np.array([
        int(datetime(2020, 1, 1, 0, 0, 0, tzinfo=timezone.utc).timestamp()),
        int(datetime(2021, 6, 15, 12, 30, 0, tzinfo=timezone.utc).timestamp()),
        int(datetime(2022, 12, 31, 23, 59, 59, tzinfo=timezone.utc).timestamp()),
        int(datetime(2023, 7, 4, 16, 20, 0, tzinfo=timezone.utc).timestamp()),
        int(datetime(2024, 11, 14, 10, 0, 0, tzinfo=timezone.utc).timestamp()),
    ], dtype=np.int64)
    
    # Create dataset with time data
    ds = f.create_dataset('timestamps', data=timestamps)
    ds.attrs['description'] = 'Unix timestamps (seconds since epoch)'
    ds.attrs['units'] = 'seconds since 1970-01-01 00:00:00 UTC'
    
    # Create 32-bit timestamps
    timestamps_32 = np.array([
        int(datetime(2020, 1, 1, 0, 0, 0, tzinfo=timezone.utc).timestamp()),
        int(datetime(2021, 6, 15, 12, 30, 0, tzinfo=timezone.utc).timestamp()),
        int(datetime(2022, 12, 31, 23, 59, 59, tzinfo=timezone.utc).timestamp()),
    ], dtype=np.int32)
    
    ds32 = f.create_dataset('timestamps_32bit', data=timestamps_32)
    ds32.attrs['description'] = '32-bit Unix timestamps'
    
    # Create millisecond timestamps
    timestamps_ms = np.array([
        int(datetime(2020, 1, 1, 0, 0, 0, tzinfo=timezone.utc).timestamp() * 1000),
        int(datetime(2021, 6, 15, 12, 30, 0, tzinfo=timezone.utc).timestamp() * 1000),
        int(datetime(2022, 12, 31, 23, 59, 59, tzinfo=timezone.utc).timestamp() * 1000),
    ], dtype=np.int64)
    
    dsms = f.create_dataset('timestamps_ms', data=timestamps_ms)
    dsms.attrs['description'] = 'Millisecond timestamps'
    dsms.attrs['units'] = 'milliseconds since 1970-01-01 00:00:00 UTC'

print('Created test_time.h5')
print('Datasets:')
print('  /timestamps: 64-bit Unix timestamps (5 elements)')
print('  /timestamps_32bit: 32-bit Unix timestamps (3 elements)')
print('  /timestamps_ms: 64-bit millisecond timestamps (3 elements)')
print('')
print('Expected dates:')
print('  2020-01-01 00:00:00')
print('  2021-06-15 12:30:00')
print('  2022-12-31 23:59:59')
print('  2023-07-04 16:20:00')
print('  2024-11-14 10:00:00')
