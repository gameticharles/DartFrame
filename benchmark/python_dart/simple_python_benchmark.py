"""Simple NumPy/Pandas Performance Benchmark"""

import numpy as np
import pandas as pd
import time

def benchmark(func, name, iterations=5):
    times = []
    for _ in range(iterations):
        start = time.perf_counter()
        func()
        end = time.perf_counter()
        times.append((end - start) * 1000)
    
    avg_time = sum(times) / len(times)
    return f"{name:50} | {avg_time:10.2f}ms"

print("=" * 80)
print("NumPy/Pandas Performance Benchmark")
print("=" * 80)
print()

# NumPy Benchmarks
print("NumPy Array Operations:")
print("-" * 80)

print(benchmark(lambda: np.zeros((100, 100)), "Array Creation (100x100)"))
print(benchmark(lambda: np.zeros((1000, 1000)), "Array Creation (1000x1000)"))
print(benchmark(lambda: np.sum(np.random.rand(100, 100)), "Array Sum (100x100)"))
print(benchmark(lambda: np.sum(np.random.rand(1000, 1000)), "Array Sum (1000x1000)"))

print()
print("Pandas DataFrame Operations:")
print("-" * 80)

print(benchmark(lambda: pd.DataFrame(np.random.rand(100, 10)), "DataFrame Creation (100x10)"))
print(benchmark(lambda: pd.DataFrame(np.random.rand(10000, 10)), "DataFrame Creation (10000x10)"))
print(benchmark(lambda: pd.DataFrame(np.random.rand(10000, 10))[0], "Column Access (10000 rows)"))
print(benchmark(lambda: pd.DataFrame(np.random.rand(10000, 10)).iloc[0, 0], "Value Access (10000 rows)"))
print(benchmark(lambda: pd.DataFrame(np.random.rand(1000, 10)).head(), "Head Operation (1000 rows)"))
print(benchmark(lambda: pd.DataFrame(np.random.rand(1000, 10)).describe(), "Describe Operation (1000 rows)"))
print(benchmark(lambda: pd.DataFrame({'col1': range(1000), 'col2': np.random.rand(1000)}), "DataFrame.from_dict (1000 rows)"))
print(benchmark(lambda: pd.DataFrame({'col1': range(1000), 'col2': np.random.rand(1000)}).to_dict(), "DataFrame.to_dict (1000 rows)"))

print()
print("=" * 80)
print("Benchmark Complete!")
print("=" * 80)
