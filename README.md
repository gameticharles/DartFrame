[![Pub package](https://img.shields.io/pub/v/dartframe.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/dartframe)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Likes](https://img.shields.io/pub/likes/dartframe)](https://pub.dartlang.org/packages/dartframe/score)
[![Points](https://img.shields.io/pub/points/dartframe)](https://pub.dartlang.org/packages/dartframe/score)
[![SDK Version](https://badgen.net/pub/sdk-version/dartframe)](https://pub.dartlang.org/packages/dartframe)

[![Last Commits](https://img.shields.io/github/last-commit/gameticharles/dartframe?ogo=github&logoColor=white)](https://github.com/gameticharles/dartframe/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gameticharles/dartframe?ogo=github&logoColor=white)](https://github.com/gameticharles/dartframe/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gameticharles/dartframe?ogo=github&logoColor=white)](https://github.com/gameticharles/dartframe)
[![License](https://img.shields.io/github/license/gameticharles/dartframe?ogo=github&logoColor=white)](https://github.com/gameticharles/dartframe/blob/main/LICENSE)

[![Stars](https://img.shields.io/github/stars/gameticharles/DartFrame)](https://github.com/gameticharles/DartFrame/stargazers)
[![Forks](https://img.shields.io/github/forks/gameticharles/DartFrame)](https://github.com/gameticharles/DartFrame/network/members)
[![Github watchers](https://img.shields.io./github/watchers/gameticharles/DartFrame)](https://github.com/gameticharles/DartFrame/MyBadges)
[![Issues](https://img.shields.io./github/issues-raw/gameticharles/DartFrame)](https://github.com/gameticharles/DartFrame/issues)

# DartFrame

**DartFrame** is a robust, lightweight Dart library designed for data manipulation and analysis. Inspired by popular data science tools like Pandas and GeoPandas, DartFrame provides a DataFrame-like structure for handling tabular data, making it easy to clean, analyze, and transform data directly in your Dart applications.

## Key Features

### 1. **DataFrame Operations**

- **Creation**: Create DataFrames from various sources such as CSV strings, JSON strings, or directly from lists and maps.
- **Data Exploration**:
  - `head(n)`: View the first `n` rows.
  - `tail(n)`: View the last `n` rows.
  - `limit(n,index)`: View the first `n` rows starting from a specified index.
  - `describe()`: Generate summary statistics.
  - `structure()`: Display the structure and data types of the DataFrame.
  - `shape`: Get the dimensions of the DataFrame.
  - `columns`: Access or modify column names.
  - `rows`: Access or modify row labels.
  - `valueCounts(column)`: Get the frequency of each unique value in a column.
- **Data Cleaning**:
  - Handle missing values using `fillna()`, `replace()`, and missing data indicators.
  - Rename columns with `rename()`.
  - Drop unwanted columns with `drop()`.
  - Filter rows based on condition functions with `filter()`.

### 2. **Data Transformation**

- Add calculated columns directly: `df['new_column'] = df['existing_column'] > 30`.
- Group data with `groupBy()` for aggregated insights.
- Concatenate DataFrames vertically or horizontally.
- Add row labels with `addRow()`.
- Add column labels with `addColumn()`.
- Shuffle rows with `shuffle()`.

### 3. **Analysis Tools**

- Frequency counts of column values using `valueCounts()`.
- Count the number of zeros in a column using `countZeros()`.
- Count the number of null values in a column using `countNulls()`.
- Calculate mean, median, and other statistics directly on columns or grouped data.

### 4. **Series Operations**

- `Series` objects for 1D data manipulation.
- Perform element-wise operations, conditional updates, and concatenation.

### 5. **Data I/O**

- Import data from CSV or JSON formats:
  - `DataFrame.fromCSV()`
  - `DataFrame.fromJson()`
- Export data to JSON or CSV formats:
  - `toJSON()`

### 6. **Customizable and Flexible**

- Handle mixed data types with ease.
- Optionally format and clean data on import.
- Support for flexible column structures.

## Documentation

For comprehensive documentation on specific classes and their functionalities, please refer to the following:

- **[DataFrame](./doc/dataframe.md)**: Detailed guide on creating and manipulating DataFrames, including data loading, cleaning, transformation, and analysis.
- **[Series](./doc/series.md)**: In-depth information on Series objects, covering creation, operations, statistical methods, and more.
- **[GeoDataFrame](./doc/geodataframe.md)**: Documentation for working with geospatial data using GeoDataFrames.
- **[GeoSeries](./doc/geoseries.md)**: Details on GeoSeries, the geometry-aware counterpart to Series.

You can also find runnable examples in the `example` directory of the repository.

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
