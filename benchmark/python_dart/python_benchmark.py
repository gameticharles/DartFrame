"""
NumPy/Pandas Performance Benchmark
Comparison baseline for DartFrame benchmarks
"""

import numpy as np
import pandas as pd
import time
from typing import Callable, Any

def benchmark(func: Callable, name: str, iterations: int = 5) -> dict:
    """Run benchmark and return timing results"""
    times = []
    result = None
    
    for _ in range(iterations):
        start = time.perf_counter()
        result = func()
        end = time.perf_counter()
        times.append((end - start) * 1000)  # Convert to milliseconds
    
    avg_time = sum(times) / len(times)
    min_time = min(times)
    max_time = max(times)
    
    return {
        'name': name,
        'avg_ms': avg_time,
        'min_ms': min_time,
        'max_ms': max_time,
        'result': result
    }

def print_result(result: dict):
    """Print benchmark result"""
    print(f"{result['name']:50} | Avg: {result['avg_ms']:8.2f}ms | Min: {result['min_ms']:8.2f}ms | Max: {result['max_ms']:8.2f}ms")

# ============ NumPy Benchmarks ============

def numpy_array_creation_small():
    """Create small array (100x100)"""
    return np.zeros((100, 100))

def numpy_array_creation_medium():
    """Create medium array (1000x1000)"""
    return np.zeros((1000, 1000))

def numpy_array_creation_large():
    """Create large array (5000x5000)"""
    return np.zeros((5000, 5000))

def numpy_array_sum_small():
    """Sum small array"""
    arr = np.random.rand(100, 100)
    return np.sum(arr)

def numpy_array_sum_medium():
    """Sum medium array"""
    arr = np.random.rand(1000, 1000)
    return np.sum(arr)

def numpy_array_sum_large():
    """Sum large array"""
    arr = np.random.rand(5000, 5000)
    return np.sum(arr)

def numpy_array_mean():
    """Calculate mean"""
    arr = np.random.rand(1000, 1000)
    return np.mean(arr)

def numpy_array_std():
    """Calculate standard deviation"""
    arr = np.random.rand(1000, 1000)
    return np.std(arr)

def numpy_matrix_multiply():
    """Matrix multiplication"""
    a = np.random.rand(500, 500)
    b = np.random.rand(500, 500)
    return np.dot(a, b)

def numpy_slicing():
    """Array slicing"""
    arr = np.random.rand(1000, 1000)
    return arr[100:200, 200:300]

# ============ Pandas Benchmarks ============

def pandas_dataframe_creation_small():
    """Create small DataFrame (100x10)"""
    return pd.DataFrame(np.random.rand(100, 10))

def pandas_dataframe_creation_medium():
    """Create medium DataFrame (10000x10)"""
    return pd.DataFrame(np.random.rand(10000, 10))

def pandas_dataframe_creation_large():
    """Create large DataFrame (100000x10)"""
    return pd.DataFrame(np.random.rand(100000, 10))

def pandas_column_sum():
    """Sum DataFrame column"""
    df = pd.DataFrame(np.random.rand(10000, 10))
    return df[0].sum()

def pandas_column_mean():
    """Mean of DataFrame column"""
    df = pd.DataFrame(np.random.rand(10000, 10))
    return df[0].mean()

def pandas_column_std():
    """Std of DataFrame column"""
    df = pd.DataFrame(np.random.rand(10000, 10))
    return df[0].std()

def pandas_groupby():
    """GroupBy operation"""
    df = pd.DataFrame({
        'category': np.random.choice(['A', 'B', 'C'], 10000),
        'value': np.random.rand(10000)
    })
    return df.groupby('category')['value'].sum()

def pandas_filtering():
    """Filter DataFrame"""
    df = pd.DataFrame(np.random.rand(10000, 10))
    return df[df[0] > 0.5]

def pandas_sorting():
    """Sort DataFrame"""
    df = pd.DataFrame(np.random.rand(10000, 10))
    return df.sort_values(by=0)

def pandas_merge():
    """Merge DataFrames"""
    df1 = pd.DataFrame({'key': range(1000), 'value1': np.random.rand(1000)})
    df2 = pd.DataFrame({'key': range(1000), 'value2': np.random.rand(1000)})
    return pd.merge(df1, df2, on='key')

def pandas_rolling_window():
    """Rolling window operation"""
    df = pd.DataFrame({'value': np.random.rand(10000)})
    return df['value'].rolling(window=100).mean()

def pandas_string_operations():
    """String operations"""
    s = pd.Series(['hello', 'world', 'python'] * 1000)
    return s.str.upper()

def pandas_categorical():
    """Categorical operations"""
    s = pd.Series(pd.Categorical(['A', 'B', 'C'] * 1000))
    return s.value_counts()

# ============ Main Benchmark Runner ============

def main():
    print("=" * 100)
    print("NumPy/Pandas Performance Benchmark")
    print("=" * 100)
    print()
    
    # NumPy Benchmarks
    print("NumPy Array Operations:")
    print("-" * 100)
    
    benchmarks = [
        (numpy_array_creation_small, "Array Creation (100x100)"),
        (numpy_array_creation_medium, "Array Creation (1000x1000)"),
        (numpy_array_creation_large, "Array Creation (5000x5000)"),
        (numpy_array_sum_small, "Array Sum (100x100)"),
        (numpy_array_sum_medium, "Array Sum (1000x1000)"),
        (numpy_array_sum_large, "Array Sum (5000x5000)"),
        (numpy_array_mean, "Array Mean (1000x1000)"),
        (numpy_array_std, "Array Std (1000x1000)"),
        (numpy_matrix_multiply, "Matrix Multiply (500x500)"),
        (numpy_slicing, "Array Slicing (1000x1000)"),
    ]
    
    for func, name in benchmarks:
        result = benchmark(func, name)
        print_result(result)
    
    print()
    print("Pandas DataFrame Operations:")
    print("-" * 100)
    
    benchmarks = [
        (pandas_dataframe_creation_small, "DataFrame Creation (100x10)"),
        (pandas_dataframe_creation_medium, "DataFrame Creation (10000x10)"),
        (pandas_dataframe_creation_large, "DataFrame Creation (100000x10)"),
        (pandas_column_sum, "Column Sum (10000 rows)"),
        (pandas_column_mean, "Column Mean (10000 rows)"),
        (pandas_column_std, "Column Std (10000 rows)"),
        (pandas_groupby, "GroupBy Sum (10000 rows)"),
        (pandas_filtering, "Filtering (10000 rows)"),
        (pandas_sorting, "Sorting (10000 rows)"),
        (pandas_merge, "Merge (1000 rows each)"),
        (pandas_rolling_window, "Rolling Window (10000 rows)"),
        (pandas_string_operations, "String Operations (3000 items)"),
        (pandas_categorical, "Categorical Operations (3000 items)"),
    ]
    
    for func, name in benchmarks:
        result = benchmark(func, name)
        print_result(result)
    
    print()
    print("=" * 100)
    print("Benchmark Complete!")
    print("=" * 100)

if __name__ == "__main__":
    main()
