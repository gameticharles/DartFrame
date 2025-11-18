# NumPy & Pandas vs DartFrame: Comprehensive Comparison

## Executive Summary

DartFrame is a Dart library that brings NumPy and pandas-like functionality to the Dart ecosystem. This document provides a detailed comparison of features, API design, and capabilities.

## Overview

| Aspect | NumPy/Pandas | DartFrame |
|--------|--------------|-----------|
| **Language** | Python | Dart |
| **Primary Use** | Data science, ML, analytics | Cross-platform data manipulation (mobile, web, desktop) |
| **Core Types** | ndarray, Series, DataFrame | NDArray, Series, DataFrame, DataCube |
| **Type System** | Dynamic typing | Static typing with generics |
| **Performance** | C/Fortran backend | Pure Dart (with potential for native extensions) |
| **Platform** | Desktop/Server | Mobile, Web, Desktop, Server |

## Core Data Structures

### 1. Array/Tensor Types

#### NumPy ndarray
```python
import numpy as np

# Create array
arr = np.array([[1, 2, 3], [4, 5, 6]])
print(arr.shape)  # (2, 3)
print(arr.ndim)   # 2
print(arr.dtype)  # int64
```

#### DartFrame NDArray
```dart
import 'package:dartframe/dartframe.dart';

// Create array
var arr = NDArray.fromFlat([1, 2, 3, 4, 5, 6], [2, 3]);
print(arr.shape);  // Shape(rows: 2, columns: 3)
print(arr.ndim);   // 2
print(arr.dtype);  // dynamic (or inferred type)
```

**Comparison:**
- ✅ Both support N-dimensional arrays
- ✅ Both have shape, ndim, dtype properties
- ✅ DartFrame adds `DataCube` for explicit 3D operations
- ⚠️ NumPy has more mature dtype system
- ✅ DartFrame has static typing advantages


### 2. Series (1D Data)

#### Pandas Series
```python
import pandas as pd

# Create Series
s = pd.Series([1, 2, 3, 4, 5], name='numbers')
print(s.dtype)        # int64
print(s.shape)        # (5,)
print(s.is_monotonic) # True
```

#### DartFrame Series
```dart
// Create Series
var s = Series([1, 2, 3, 4, 5], name: 'numbers');
print(s.dtype);          // int
print(s.shape);          // Shape([5])
print(s.isHomogeneous);  // true
```

**Comparison:**
- ✅ Both support labeled 1D data
- ✅ Both have name, dtype, shape
- ✅ DartFrame implements DartData interface for polymorphism
- ✅ Both support generic types (Series<T> in Dart)
- ✅ Similar API design

### 3. DataFrame (2D Tabular Data)

#### Pandas DataFrame
```python
import pandas as pd

# Create DataFrame
df = pd.DataFrame({
    'id': [1, 2, 3],
    'name': ['Alice', 'Bob', 'Charlie'],
    'score': [95.5, 87.3, 92.1]
})

print(df.shape)      # (3, 3)
print(df.dtypes)     # id: int64, name: object, score: float64
print(df.ndim)       # 2
```

#### DartFrame DataFrame
```dart
// Create DataFrame
var df = DataFrame.fromMap({
  'id': [1, 2, 3],
  'name': ['Alice', 'Bob', 'Charlie'],
  'score': [95.5, 87.3, 92.1],
});

print(df.shape);        // Shape(rows: 3, columns: 3)
print(df.columnTypes);  // {id: int, name: String, score: double}
print(df.ndim);         // 2
```

**Comparison:**
- ✅ Both support heterogeneous columns
- ✅ Both have shape, ndim, dtypes/columnTypes
- ✅ Similar construction methods (fromMap, fromRows, etc.)
- ✅ Both implement DartData/ndarray-like interface
- ✅ DartFrame has `isHomogeneous` property


## Unified Interface (DartData)

### NumPy/Pandas Approach
```python
# Different interfaces for different types
arr = np.array([1, 2, 3])      # ndarray
s = pd.Series([1, 2, 3])       # Series
df = pd.DataFrame([[1, 2]])    # DataFrame

# No unified interface - each has different methods
```

### DartFrame Approach
```dart
// Unified DartData interface
List<DartData> structures = [
  NDArray.fromFlat([1, 2, 3, 4], [2, 2]),
  Series([1, 2, 3], name: 'test'),
  DataFrame([[1, 2], [3, 4]]),
  DataCube.zeros(2, 3, 4),
];

// All share common interface
for (var data in structures) {
  print(data.ndim);          // Works for all
  print(data.shape);         // Works for all
  print(data.size);          // Works for all
  print(data.isHomogeneous); // Works for all
  data.attrs['source'] = 'test'; // Works for all
}
```

**Advantage: DartFrame**
- ✅ Unified interface for all dimensional types
- ✅ Polymorphic operations
- ✅ Consistent API across structures
- ✅ Type-safe generic algorithms

## Indexing and Slicing

### NumPy/Pandas
```python
import numpy as np
import pandas as pd

# NumPy slicing
arr = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
print(arr[0, 1])           # 2 (scalar)
print(arr[0, :])           # [1, 2, 3] (1D array)
print(arr[:2, :2])         # [[1, 2], [4, 5]] (2D array)

# Pandas slicing
df = pd.DataFrame(arr, columns=['A', 'B', 'C'])
print(df.iloc[0, 1])       # 2 (scalar)
print(df.iloc[0, :])       # Series
print(df.iloc[:2, :2])     # DataFrame
```

### DartFrame
```dart
// Unified slicing
var df = DataFrame([[1, 2, 3], [4, 5, 6], [7, 8, 9]]);

print(df.slice([0, 1]));              // Scalar(2)
print(df.slice([0, Slice.all()]));    // Series
print(df.slice([Slice.range(0, 2), Slice.range(0, 2)])); // DataFrame

// Also supports iloc/loc
print(df.iloc(0, 1));      // 2
print(df.iloc[0]);         // Series
```

**Comparison:**
- ✅ Both support multi-dimensional slicing
- ✅ DartFrame has unified `slice()` method across all types
- ✅ Both support iloc/loc accessors
- ✅ DartFrame returns appropriate types (Scalar, Series, DataFrame)
- ⚠️ NumPy syntax is more concise (arr[0, 1] vs df.slice([0, 1]))


## Data Type System

### NumPy/Pandas
```python
import numpy as np
import pandas as pd

# NumPy dtypes
arr = np.array([1, 2, 3], dtype=np.int8)
print(arr.dtype)  # int8

# Pandas dtypes (including nullable)
df = pd.DataFrame({
    'int_col': pd.array([1, 2, None], dtype='Int64'),  # Nullable int
    'str_col': pd.array(['a', 'b', None], dtype='string'),
    'bool_col': pd.array([True, False, None], dtype='boolean')
})
print(df.dtypes)
```

### DartFrame
```dart
// DartFrame dtypes
var df = DataFrame.fromMap({
  'int_col': [1, 2, null],
  'str_col': ['a', 'b', null],
  'bool_col': [true, false, null]
});

// Automatic type inference
print(df.columnTypes);  // {int_col: int, str_col: String, bool_col: bool}

// Explicit dtype system
df.astype({'int_col': DTypes.int64()});
print(df.dtypesDetailed);  // Detailed type info

// Nullable types
var intType = DTypes.int8(nullable: true);
var strType = DTypes.string(nullable: true);
```

**Comparison:**
- ✅ Both support nullable types
- ✅ Both have automatic type inference
- ✅ DartFrame has Int8, Int16, Int32, Int64 (like pandas)
- ✅ Both support string, boolean, datetime types
- ✅ DartFrame leverages Dart's null safety
- ⚠️ NumPy has more extensive dtype system (complex, structured arrays)

## Metadata and Attributes

### NumPy/Pandas
```python
# Pandas attributes (limited)
df = pd.DataFrame([[1, 2], [3, 4]])
df.attrs['description'] = 'Test data'
print(df.attrs)  # {'description': 'Test data'}

# NumPy has no built-in metadata system
```

### DartFrame
```dart
// HDF5-style attributes for all types
var df = DataFrame([[1, 2], [3, 4]]);
df.attrs['description'] = 'Test data';
df.attrs['units'] = 'meters';
df.attrs['created'] = DateTime.now();
df.attrs['version'] = '1.0';

print(df.attrs.keys);  // [description, units, created, version]
print(df.attrs.toJson());  // JSON serializable

// Works for all DartData types
var series = Series([1, 2, 3], name: 'test');
series.attrs['sensor_id'] = 'TEMP_001';

var array = NDArray.zeros([3, 4]);
array.attrs['experiment'] = 'trial_1';
```

**Advantage: DartFrame**
- ✅ Comprehensive metadata system for all types
- ✅ HDF5-style attributes
- ✅ JSON serializable
- ✅ Consistent across all dimensional types
- ✅ Better than pandas' limited attrs


## I/O Operations

### Pandas
```python
import pandas as pd

# CSV
df = pd.read_csv('data.csv')
df.to_csv('output.csv')

# JSON
df = pd.read_json('data.json')
df.to_json('output.json')

# Excel
df = pd.read_excel('data.xlsx')
df.to_excel('output.xlsx')

# HDF5
df = pd.read_hdf('data.h5', key='data')
df.to_hdf('output.h5', key='data')

# SQL
df = pd.read_sql('SELECT * FROM table', conn)
df.to_sql('table', conn)

# Parquet
df = pd.read_parquet('data.parquet')
df.to_parquet('output.parquet')
```

### DartFrame
```dart
// CSV
var df = await DataFrame.fromCSV(path: 'data.csv');
await df.toCSV(path: 'output.csv');

// JSON
var df = await DataFrame.fromJson(path: 'data.json');
df.toJSON(path: 'output.json');

// Excel
var df = await DataFrame.fromExcel(path: 'data.xlsx');
await df.toExcel(path: 'output.xlsx');

// HDF5 (Advanced support)
var df = await Hdf5File.open('data.h5').dataset('/data').read();
await DataFrameHDF5Writer().write(builder, '/data', df);

// SQL
var df = await DatabaseReader.readSqlQuery('SELECT * FROM table', conn);
await df.toSql(connection: conn, tableName: 'table');

// Parquet
await df.toParquet(path: 'output.parquet');

// Smart Loader (auto-detect format)
var df = await DataFrame.read('data.csv');  // Auto-detects format
```

**Comparison:**
- ✅ Both support CSV, JSON, Excel, HDF5, SQL, Parquet
- ✅ DartFrame has SmartLoader for auto-detection
- ✅ DartFrame has advanced HDF5 support (links, references, web)
- ✅ Both have similar API design
- ✅ DartFrame supports web/mobile platforms
- ⚠️ Pandas has more format support (Stata, SAS, etc.)

## Statistical Operations

### Pandas
```python
import pandas as pd

df = pd.DataFrame({'A': [1, 2, 3, 4, 5]})

# Basic stats
print(df.mean())
print(df.std())
print(df.min())
print(df.max())
print(df.sum())

# Advanced stats
print(df.describe())
print(df.corr())
print(df.cov())
print(df.quantile(0.5))
```

### DartFrame
```dart
var df = DataFrame.fromMap({'A': [1, 2, 3, 4, 5]});

// Basic stats
print(df.mean());
print(df.std());
print(df.min());
print(df.max());
print(df.sum());

// Advanced stats
print(df.describe());
print(df.corr());
print(df.cov());
print(df.quantile(0.5));
```

**Comparison:**
- ✅ Nearly identical API
- ✅ Both support comprehensive statistical operations
- ✅ Similar method names and behavior
- ⚠️ Pandas has more advanced statistical methods


## GroupBy Operations

### Pandas
```python
import pandas as pd

df = pd.DataFrame({
    'category': ['A', 'B', 'A', 'B'],
    'value': [1, 2, 3, 4]
})

# GroupBy operations
grouped = df.groupby('category')
print(grouped.sum())
print(grouped.mean())
print(grouped.agg(['sum', 'mean', 'count']))

# Transform
df['normalized'] = grouped['value'].transform(lambda x: (x - x.mean()) / x.std())

# Filter
filtered = grouped.filter(lambda x: x['value'].sum() > 3)
```

### DartFrame
```dart
var df = DataFrame.fromMap({
  'category': ['A', 'B', 'A', 'B'],
  'value': [1, 2, 3, 4]
});

// GroupBy operations
var grouped = df.groupBy2(['category']);
print(grouped.sum());
print(grouped.mean());
print(grouped.agg(['sum', 'mean', 'count']));

// Transform
var normalized = grouped.transform((group) => 
  (group['value'] - group['value'].mean()) / group['value'].std()
);

// Filter
var filtered = grouped.filter((group) => group['value'].sum() > 3);
```

**Comparison:**
- ✅ Nearly identical API
- ✅ Both support agg, transform, filter
- ✅ Both support multiple aggregation functions
- ✅ Similar method chaining
- ✅ DartFrame has `groupBy2()` for advanced operations

## Time Series Operations

### Pandas
```python
import pandas as pd

# Create time series
dates = pd.date_range('2024-01-01', periods=5, freq='D')
df = pd.DataFrame({'value': [1, 2, 3, 4, 5]}, index=dates)

# Shift operations
print(df.shift(1))
print(df.shift(-1))

# Resampling
print(df.resample('2D').sum())

# Rolling window
print(df.rolling(window=3).mean())

# Timezone operations
df_tz = df.tz_localize('UTC')
df_tz = df_tz.tz_convert('US/Eastern')
```

### DartFrame
```dart
// Create time series
var dates = List.generate(5, (i) => DateTime(2024, 1, i + 1));
var df = DataFrame.fromMap({'value': [1, 2, 3, 4, 5]}, index: dates);

// Shift operations
print(df.shift(1));
print(df.shift(-1));

// Resampling
print(df.resample('2D', 'sum'));

// Rolling window
print(df.rollingWindow(3).mean());

// Timezone operations
var dfTz = df.tzLocalize('UTC');
dfTz = dfTz.tzConvert('US/Eastern');
```

**Comparison:**
- ✅ Nearly identical API
- ✅ Both support shift, resample, rolling
- ✅ Both support timezone operations
- ✅ Similar method names
- ⚠️ Pandas has more advanced time series features


## String Operations

### Pandas
```python
import pandas as pd

s = pd.Series(['Hello', 'World', 'Python'])

# String operations
print(s.str.lower())
print(s.str.upper())
print(s.str.contains('o'))
print(s.str.replace('o', 'X'))
print(s.str.split(' '))
print(s.str.len())
```

### DartFrame
```dart
var s = Series(['Hello', 'World', 'Python'], name: 'text');

// String operations
print(s.str.lower());
print(s.str.upper());
print(s.str.contains('o'));
print(s.str.replace('o', 'X'));
print(s.str.split(' '));
print(s.str.len());
```

**Comparison:**
- ✅ Identical API design
- ✅ Both use `.str` accessor
- ✅ Same method names
- ✅ Similar functionality

## Categorical Data

### Pandas
```python
import pandas as pd

s = pd.Series(['A', 'B', 'A', 'C'], dtype='category')

# Categorical operations
print(s.cat.categories)
print(s.cat.codes)
s = s.cat.add_categories(['D'])
s = s.cat.remove_categories(['C'])
s = s.cat.rename_categories({'A': 'Alpha'})
```

### DartFrame
```dart
var s = Series(['A', 'B', 'A', 'C'], name: 'cat');
s.astype('category');

// Categorical operations
print(s.cat.categories);
print(s.cat.codes);
s.cat.addCategories(['D']);
s.cat.removeCategories(['C']);
s.cat.renameCategories({'A': 'Alpha'});
```

**Comparison:**
- ✅ Nearly identical API
- ✅ Both use `.cat` accessor
- ✅ Similar method names
- ✅ Same functionality

## Window Functions

### Pandas
```python
import pandas as pd

df = pd.DataFrame({'value': [1, 2, 3, 4, 5]})

# Rolling window
print(df.rolling(window=3).mean())
print(df.rolling(window=3).sum())
print(df.rolling(window=3).std())

# Expanding window
print(df.expanding().mean())
print(df.expanding().sum())

# Exponentially weighted
print(df.ewm(span=3).mean())
print(df.ewm(alpha=0.5).mean())
```

### DartFrame
```dart
var df = DataFrame.fromMap({'value': [1, 2, 3, 4, 5]});

// Rolling window
print(df.rollingWindow(3).mean());
print(df.rollingWindow(3).sum());
print(df.rollingWindow(3).std());

// Expanding window
print(df.expanding().mean());
print(df.expanding().sum());

// Exponentially weighted
print(df.ewm(span: 3).mean());
print(df.ewm(alpha: 0.5).mean());
```

**Comparison:**
- ✅ Identical API design
- ✅ Same method names
- ✅ Similar functionality
- ✅ Both support rolling, expanding, ewm


## Advanced Features Unique to DartFrame

### 1. DataCube (3D Data Structure)
```dart
// DartFrame has explicit 3D support
var cube = DataCube.fromDataFrames([df1, df2, df3]);
print(cube.shape);  // Shape(3×10×5) - depth, rows, columns

// Slice 3D data
var frame = cube[0];  // Get first DataFrame
var slice = cube.slice([Slice.all(), 0, Slice.all()]);  // Get row across all frames

// Operations
print(cube.sum(axis: 0));  // Sum across depth
print(cube.mean(axis: 1)); // Mean across rows
```

**Advantage: DartFrame**
- ✅ Explicit 3D data structure (pandas uses MultiIndex)
- ✅ Cleaner API for 3D operations
- ✅ Better for stacked time series or panel data

### 2. Storage Backends
```dart
// DartFrame has pluggable storage backends
var array = NDArray.zeros([1000, 1000]);  // In-memory

// Chunked storage for large arrays
NDArrayConfig.defaultBackend = BackendType.chunked;
var largeArray = NDArray.zeros([10000, 10000]);  // Chunked storage

// Custom backends possible
var customBackend = MyCustomBackend();
var array = NDArray.withBackend([1000, 1000], customBackend);
```

**Advantage: DartFrame**
- ✅ Pluggable storage backends
- ✅ Chunked storage for large data
- ✅ Extensible architecture

### 3. Cross-Platform Support
```dart
// DartFrame works on all platforms
// - Mobile (iOS, Android)
// - Web (JavaScript compilation)
// - Desktop (Windows, macOS, Linux)
// - Server

// Web-specific features
var df = await DataFrame.read('https://example.com/data.csv');
var hdf5 = await Hdf5File.open(uint8ListFromWeb);
```

**Advantage: DartFrame**
- ✅ True cross-platform (mobile, web, desktop)
- ✅ Web browser support for HDF5
- ✅ Single codebase for all platforms

### 4. Static Typing
```dart
// DartFrame leverages Dart's static typing
Series<int> intSeries = Series([1, 2, 3], name: 'numbers');
Series<String> strSeries = Series(['a', 'b', 'c'], name: 'letters');

// Compile-time type checking
// intSeries.data.add('string');  // Compile error!

// Generic algorithms
T processData<T extends DartData>(T data) {
  // Type-safe operations
  return data;
}
```

**Advantage: DartFrame**
- ✅ Compile-time type checking
- ✅ Better IDE support
- ✅ Fewer runtime errors
- ✅ Generic programming support


## Performance Comparison

### NumPy/Pandas
- ✅ C/Fortran backend (very fast)
- ✅ Highly optimized for numerical operations
- ✅ BLAS/LAPACK integration
- ✅ Mature performance optimizations
- ⚠️ Python overhead for small operations
- ⚠️ GIL limitations for parallelism

### DartFrame
- ✅ Pure Dart (good performance)
- ✅ JIT compilation benefits
- ✅ Potential for native extensions
- ✅ No GIL - true parallelism
- ⚠️ Not as fast as NumPy for large numerical operations
- ⚠️ Less mature optimization

**Verdict:**
- NumPy/Pandas: Better for heavy numerical computation
- DartFrame: Better for cross-platform apps with moderate data processing

## Ecosystem Comparison

### NumPy/Pandas Ecosystem
- ✅ Massive ecosystem (scikit-learn, matplotlib, scipy)
- ✅ Extensive documentation
- ✅ Large community
- ✅ Many tutorials and resources
- ✅ Industry standard for data science

### DartFrame Ecosystem
- ✅ Growing Dart/Flutter ecosystem
- ✅ Cross-platform mobile/web apps
- ✅ Integration with Flutter UI
- ✅ Modern language features
- ⚠️ Smaller community
- ⚠️ Fewer third-party libraries

## Use Case Recommendations

### Use NumPy/Pandas When:
1. **Heavy numerical computation** - Scientific computing, ML training
2. **Python ecosystem** - Need scikit-learn, TensorFlow, PyTorch
3. **Desktop/Server only** - No mobile/web requirements
4. **Mature libraries** - Need battle-tested solutions
5. **Data science workflows** - Jupyter notebooks, visualization

### Use DartFrame When:
1. **Cross-platform apps** - Mobile, web, desktop from single codebase
2. **Flutter integration** - Building data-driven Flutter apps
3. **Type safety** - Want compile-time type checking
4. **Modern language** - Prefer Dart's features (null safety, async/await)
5. **Moderate data processing** - Not heavy numerical computation
6. **Web deployment** - Need browser-based data processing
7. **Mobile apps** - Data processing on mobile devices


## Feature Parity Matrix

| Feature | NumPy | Pandas | DartFrame |
|---------|-------|--------|-----------|
| **Core Data Structures** |
| N-dimensional arrays | ✅ | ❌ | ✅ |
| 1D Series | ❌ | ✅ | ✅ |
| 2D DataFrame | ❌ | ✅ | ✅ |
| 3D DataCube | ❌ | ⚠️ (MultiIndex) | ✅ |
| **Unified Interface** | ❌ | ❌ | ✅ |
| **Type System** |
| dtype system | ✅ | ✅ | ✅ |
| Nullable types | ⚠️ | ✅ | ✅ |
| Static typing | ❌ | ❌ | ✅ |
| **Indexing** |
| Integer indexing | ✅ | ✅ | ✅ |
| Label indexing | ❌ | ✅ | ✅ |
| Boolean indexing | ✅ | ✅ | ✅ |
| MultiIndex | ❌ | ✅ | ✅ |
| **I/O Operations** |
| CSV | ⚠️ | ✅ | ✅ |
| JSON | ⚠️ | ✅ | ✅ |
| Excel | ❌ | ✅ | ✅ |
| HDF5 | ✅ | ✅ | ✅ (Advanced) |
| SQL | ❌ | ✅ | ✅ |
| Parquet | ❌ | ✅ | ✅ |
| **Statistical Operations** |
| Basic stats | ✅ | ✅ | ✅ |
| Correlation | ✅ | ✅ | ✅ |
| Covariance | ✅ | ✅ | ✅ |
| Quantiles | ✅ | ✅ | ✅ |
| **GroupBy** |
| Basic groupby | ❌ | ✅ | ✅ |
| Aggregation | ❌ | ✅ | ✅ |
| Transform | ❌ | ✅ | ✅ |
| Filter | ❌ | ✅ | ✅ |
| **Time Series** |
| Date/time types | ✅ | ✅ | ✅ |
| Resampling | ❌ | ✅ | ✅ |
| Rolling window | ❌ | ✅ | ✅ |
| Timezone support | ✅ | ✅ | ✅ |
| **String Operations** |
| String methods | ⚠️ | ✅ | ✅ |
| Regex support | ⚠️ | ✅ | ✅ |
| **Categorical Data** |
| Categorical type | ❌ | ✅ | ✅ |
| Category operations | ❌ | ✅ | ✅ |
| **Advanced Features** |
| Metadata/attributes | ❌ | ⚠️ | ✅ |
| Storage backends | ❌ | ❌ | ✅ |
| Cross-platform | ❌ | ❌ | ✅ |
| Web support | ❌ | ❌ | ✅ |
| Mobile support | ❌ | ❌ | ✅ |

**Legend:**
- ✅ Full support
- ⚠️ Partial support
- ❌ Not supported


## Code Examples: Side-by-Side

### Example 1: Data Loading and Basic Operations

**Pandas:**
```python
import pandas as pd

# Load data
df = pd.read_csv('sales.csv')

# Basic operations
print(df.shape)
print(df.dtypes)
print(df.head())

# Statistics
print(df['amount'].mean())
print(df['amount'].std())

# Filtering
high_sales = df[df['amount'] > 1000]

# Grouping
by_category = df.groupby('category')['amount'].sum()
```

**DartFrame:**
```dart
import 'package:dartframe/dartframe.dart';

// Load data
var df = await DataFrame.fromCSV(path: 'sales.csv');

// Basic operations
print(df.shape);
print(df.columnTypes);
print(df.head());

// Statistics
print(df['amount'].mean());
print(df['amount'].std());

// Filtering
var highSales = df[df['amount'] > 1000];

// Grouping
var byCategory = df.groupBy2(['category'])['amount'].sum();
```

### Example 2: Time Series Analysis

**Pandas:**
```python
import pandas as pd

# Create time series
dates = pd.date_range('2024-01-01', periods=100, freq='D')
df = pd.DataFrame({
    'date': dates,
    'value': range(100)
})
df.set_index('date', inplace=True)

# Rolling window
rolling_mean = df['value'].rolling(window=7).mean()

# Resampling
weekly = df.resample('W').sum()

# Shift
lagged = df['value'].shift(1)
```

**DartFrame:**
```dart
// Create time series
var dates = List.generate(100, (i) => DateTime(2024, 1, i + 1));
var df = DataFrame.fromMap({
  'date': dates,
  'value': List.generate(100, (i) => i)
}, index: dates);

// Rolling window
var rollingMean = df['value'].rollingWindow(7).mean();

// Resampling
var weekly = df.resample('W', 'sum');

// Shift
var lagged = df['value'].shift(1);
```

### Example 3: Data Transformation

**Pandas:**
```python
import pandas as pd

df = pd.DataFrame({
    'A': [1, 2, 3, 4],
    'B': [5, 6, 7, 8]
})

# Apply function
df['C'] = df['A'] + df['B']

# Transform
df['A_normalized'] = (df['A'] - df['A'].mean()) / df['A'].std()

# Pivot
pivot = df.pivot_table(values='A', index='B', aggfunc='mean')
```

**DartFrame:**
```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4],
  'B': [5, 6, 7, 8]
});

// Apply function
df['C'] = df['A'] + df['B'];

// Transform
df['A_normalized'] = (df['A'] - df['A'].mean()) / df['A'].std();

// Pivot
var pivot = df.pivot(values: 'A', index: 'B', aggFunc: 'mean');
```

## Migration Guide: Pandas → DartFrame

### Common Patterns

| Pandas | DartFrame | Notes |
|--------|-----------|-------|
| `pd.DataFrame()` | `DataFrame()` | Same constructor |
| `pd.read_csv()` | `DataFrame.fromCSV()` | Async in Dart |
| `df.iloc[0, 1]` | `df.iloc(0, 1)` | Method call vs property |
| `df[df['A'] > 5]` | `df[df['A'] > 5]` | Same syntax |
| `df.groupby('A')` | `df.groupBy2(['A'])` | List of columns |
| `df.rolling(3)` | `df.rollingWindow(3)` | Different name |
| `df.str.lower()` | `df.str.lower()` | Same accessor |
| `df.cat.codes` | `df.cat.codes` | Same accessor |
| `df.to_csv()` | `await df.toCSV()` | Async in Dart |

### Key Differences

1. **Async/Await**: DartFrame uses async for I/O operations
2. **Method Calls**: Some properties in pandas are methods in DartFrame
3. **Type Safety**: DartFrame requires explicit types in some cases
4. **Null Safety**: DartFrame leverages Dart's null safety


## Conclusion

### DartFrame Strengths
1. ✅ **Cross-Platform**: Works on mobile, web, desktop, server
2. ✅ **Unified Interface**: DartData interface for all dimensional types
3. ✅ **Type Safety**: Compile-time type checking
4. ✅ **Modern Language**: Dart's features (null safety, async/await)
5. ✅ **Metadata System**: Comprehensive HDF5-style attributes
6. ✅ **Storage Backends**: Pluggable storage architecture
7. ✅ **DataCube**: Explicit 3D data structure
8. ✅ **Pandas-like API**: Familiar for pandas users

### NumPy/Pandas Strengths
1. ✅ **Performance**: C/Fortran backend for speed
2. ✅ **Ecosystem**: Massive library ecosystem
3. ✅ **Maturity**: Battle-tested and widely adopted
4. ✅ **Community**: Large community and resources
5. ✅ **Advanced Features**: More specialized operations
6. ✅ **Industry Standard**: De facto standard for data science

### When to Choose DartFrame
- Building **cross-platform applications** (mobile, web, desktop)
- Need **type safety** and compile-time checking
- Working with **Flutter** for UI
- Want **modern language features**
- Need **moderate data processing** (not heavy ML)
- Deploying to **web browsers** or **mobile devices**
- Want **unified interface** across dimensional types

### When to Choose NumPy/Pandas
- Heavy **numerical computation** and scientific computing
- Need **Python ecosystem** (scikit-learn, TensorFlow, etc.)
- **Desktop/Server only** deployment
- **Data science workflows** with Jupyter notebooks
- Need **maximum performance** for large datasets
- Want **mature, battle-tested** solutions
- Industry-standard **data science** work

## Summary

DartFrame successfully brings NumPy and pandas-like functionality to Dart, with a **pandas-inspired API** that will be familiar to Python data scientists. While it may not match NumPy/Pandas in raw performance or ecosystem size, it excels in:

- **Cross-platform support** (mobile, web, desktop)
- **Type safety** and modern language features
- **Unified interface** for all dimensional types
- **Comprehensive metadata system**
- **Flutter integration** for data-driven apps

DartFrame is an excellent choice for developers building **cross-platform data applications** with Flutter/Dart, while NumPy/Pandas remains the gold standard for **Python-based data science** and **heavy numerical computation**.

## Resources

### DartFrame
- GitHub: [DartFrame Repository]
- Documentation: [API Documentation]
- Examples: See `example/` directory

### NumPy/Pandas
- NumPy: https://numpy.org/
- Pandas: https://pandas.pydata.org/
- Documentation: Extensive official docs

---

**Last Updated:** November 2024  
**DartFrame Version:** 0.8.6  
**Pandas Version:** 2.x  
**NumPy Version:** 1.x
