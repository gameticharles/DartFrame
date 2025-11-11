[![Pub package](https://img.shields.io/pub/v/dartframe.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/dartframe)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Likes](https://img.shields.io/pub/likes/dartframe)](https://pub.dartlang.org/packages/dartframe/score)
[![Points](https://img.shields.io/pub/points/dartframe)](https://pub.dartlang.org/packages/dartframe/score)
[![SDK Version](https://badgen.net/pub/sdk-version/dartframe)](https://pub.dartlang.org/packages/dartframe)

[![Last Commits](https://img.shields.io/github/last-commit/gameticharles/dartframe?ogo=github&logoColor=white)](https://github.com/gameticharles/dartframe/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gameticharles/dartframe?ogo=github&logoColor=white)](https://github.com/gameticharles/dartframe/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gameticharles/dartframe?ogo=github&logoColor=white)](https://github.com/gameticharles/dartframe)
[![License](https://img.shields.io/github/license/gameticharles/dartframe?ogo=github&logoColor=white)](https://github.com/gameticharles/dartframe/blob/main/LICENSE)

[![Stars](https://img.shields.io/github/stars/gameticharles/dartFrame)](https://github.com/gameticharles/dartFrame/stargazers)
[![Forks](https://img.shields.io/github/forks/gameticharles/dartFrame)](https://github.com/gameticharles/dartFrame/network/members)
[![Github watchers](https://img.shields.io./github/watchers/gameticharles/dartFrame)](https://github.com/gameticharles/dartFrame/MyBadges)
[![Issues](https://img.shields.io./github/issues-raw/gameticharles/dartFrame)](https://github.com/gameticharles/dartFrame/issues)

# DartFrame

**DartFrame** is a robust, lightweight Dart library designed for data manipulation and analysis. Inspired by popular data science tools like Pandas and GeoPandas, DartFrame provides a DataFrame-like structure for handling tabular data, making it easy to clean, analyze, and transform data directly in your Dart applications.

## Key Features

### 🚀 **Enhanced Statistical Operations**

- **Advanced Statistics**: Calculate median, mode, quantile, standard deviation, variance, skewness, and kurtosis
- **Correlation Analysis**: Compute correlation and covariance matrices between DataFrame columns
- **Rolling Window Operations**: Perform rolling statistics with customizable window sizes
- **Cumulative Operations**: Calculate cumulative sums, products, minimums, and maximums

### 📊 **Data Manipulation & Reshaping**

- **Melt Operations**: Transform DataFrames from wide to long format
- **Stack/Unstack**: Reshape data with hierarchical indexing
- **Enhanced Pivot Tables**: Create sophisticated pivot tables with multiple aggregation functions
- **Advanced Merging**: Support for complex join operations with multiple keys and join types

### 🔧 **Missing Data Handling**

- **Interpolation Methods**: Fill missing values using linear, polynomial, and spline interpolation
- **Advanced Fill Operations**: Forward fill and backward fill with limits and direction control
- **Missing Data Analysis**: Analyze patterns in missing data for better data quality insights

### ⚡ **Performance Optimizations**

- **Memory Management**: Optimize data types and memory usage for large datasets
- **Vectorized Operations**: Perform element-wise operations with improved performance
- **Caching Mechanisms**: Cache results of expensive operations for faster repeated access
- **Parallel Processing**: Support for multi-threaded operations on CPU-intensive tasks

### 📈 **Enhanced I/O Capabilities**

- **Multiple Formats**: Support for Parquet, Excel, HDF5, and additional file formats
- **Database Connectivity**: Connect to SQL databases for data import and export
- **Chunked Reading**: Handle large files with memory-efficient chunked reading
- **Streaming Processing**: Process data streams for real-time analysis

### 📊 **Categorical Data Support**

- **Categorical Data Type**: Memory-efficient categorical data with ordered and unordered categories
- **Category Operations**: Specialized operations for categorical data analysis
- **Memory Optimization**: Reduce memory usage with categorical encoding

### ⏰ **Time Series Enhancements**

- **Resampling**: Resample time series data at different frequencies
- **Frequency Conversion**: Convert between different time frequencies with interpolation
- **Time-based Indexing**: Enhanced datetime indexing and time-based operations

### 🔄 **Core DataFrame Operations**

- **Creation**: Create DataFrames from various sources (CSV, JSON, lists, maps, databases)
- **Data Exploration**: `head()`, `tail()`, `describe()`, `info()`, `shape`, `columns`
- **Data Cleaning**: Handle missing values, rename columns, drop unwanted data
- **Data Transformation**: Add calculated columns, group operations, concatenation
- **Series Operations**: 1D data manipulation with element-wise operations

### 🛠️ **Flexible & Customizable**

- **Mixed Data Types**: Handle heterogeneous data with ease
- **Extensible Architecture**: Plugin-based architecture for custom operations
- **Memory Efficient**: Optimized for both small and large datasets

## Documentation

For comprehensive documentation on specific classes and their functionalities, please refer to the following:

### Core Documentation
- **[DataFrame](./doc/dataframe.md)**: Comprehensive guide covering all DataFrame operations, from basic data manipulation to advanced statistical analysis
- **[Series](./doc/series.md)**: Complete Series documentation including statistical methods, string operations, and datetime functionality


You can also find additional runnable examples in the `example` directory of the repository.

---

## Installation

To install DartFrame, add the following to your `pubspec.yaml`:

```yaml
dependencies:
  dartframe: any
```

Then, run:

```bash
dart pub get
```

## What's New in Latest Version

### 🎉 **Pandas Feature Parity Update**

This major update brings DartFrame closer to pandas functionality with comprehensive enhancements:

#### **Advanced Statistical Operations**
- Added `median()`, `mode()`, `quantile()`, `skew()`, `kurtosis()` methods
- Implemented correlation and covariance analysis with `corr()` and `cov()`
- Rolling window operations with `rolling()` for time series analysis

#### **Enhanced Data Manipulation**
- `melt()` operations for wide-to-long data transformation
- `stack()` and `unstack()` for hierarchical data reshaping
- Advanced pivot tables with multiple aggregation functions
- Improved merge operations with multiple join types

#### **Missing Data Handling**
- Interpolation methods: linear, polynomial, and spline
- Advanced fill operations with `ffill()` and `bfill()` with limits
- Missing data pattern analysis tools

#### **Geospatial Enhancements**
- Spatial joins based on geometric relationships
- Overlay operations (intersection, union, difference)
- Coordinate reference system transformations
- Spatial indexing for efficient queries
- Buffer, dissolve, and simplify operations

#### **Performance & I/O Improvements**
- Memory optimization utilities
- Vectorized operations for better performance
- Support for Parquet, Excel, and HDF5 formats
- Database connectivity for SQL operations
- Chunked reading for large files

#### **Time Series & Categorical Data**
- Time series resampling and frequency conversion
- Categorical data type with memory optimization
- Enhanced datetime operations and indexing

See the [examples](./example/) directory for comprehensive demonstrations of these new features.

---

```bash
dart pub get
```
To get started, import the library:
```dart
import 'package:dartframe/dartframe.dart';
```
For detailed examples and usage, please refer to the documentation in the `doc` folder and the examples in the `example` folder.

---

## Performance and Scalability

DartFrame is optimized for small to medium-sized datasets. While not designed for big data processing, it can handle thousands of rows efficiently in memory. For larger datasets, consider integrating with distributed processing tools or databases.

---

## Testing

Tests are located in the test directory. To run tests, execute dart test in the project root.

---

## Benchmarking

Performance benchmarks are available in the `benchmark` directory. These benchmarks, built using the `benchmark_harness` package, help measure the performance of various operations on `Series` and `DataFrame` objects.

For detailed instructions on how to run these benchmarks and interpret their output, please see [benchmark/BENCHMARKING.MD](./benchmark/BENCHMARKING.md).

Reference (simulated) performance numbers can be found in [benchmark/RESULTS.MD](./benchmark/RESULTS.md).

---

## Contributing Features and bugs

### :beer: Pull requests are welcome

Don't forget that `open-source` makes no sense without contributors. No matter how big your changes are, it helps us a lot even it is a line of change.

There might be a lot of grammar issues in the docs. It's a big help to us to fix them if you are fluent in English.

Reporting bugs and issues are contribution too, yes it is. Feel free to fork the repository, raise issues, and submit pull requests.

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/gameticharles/DartFrame/issues

## Author

Charles Gameti: [gameticharles@GitHub][github_cg].

[github_cg]: https://github.com/gameticharles

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
