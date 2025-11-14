import h5py
import struct

# Open the file and inspect chunk storage
with h5py.File('example/data/test_compressed.h5', 'r') as f:
    ds = f['/gzip_1d']
    print(f"Dataset: {ds.name}")
    print(f"Shape: {ds.shape}")
    print(f"Chunks: {ds.chunks}")
    print(f"Compression: {ds.compression}")
    print(f"Dtype: {ds.dtype}")
    
    # Get chunk storage info
    dsid = ds.id
    print(f"\nDataset ID: {dsid}")
    
    # Try to get chunk info (this is internal h5py API)
    try:
        chunk_iter = dsid.chunk_iter()
        print("\nChunk information:")
        for chunk_info in chunk_iter:
            print(f"  Chunk offset: {chunk_info}")
    except:
        print("Cannot iterate chunks with this h5py version")
    
    # Read first chunk manually
    print(f"\nFirst 10 values: {ds[:10]}")
