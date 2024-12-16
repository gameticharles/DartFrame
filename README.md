[![Pub package](https://img.shields.io/pub/v/advance_math.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/advance_math)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Likes](https://img.shields.io/pub/likes/advance_math)](https://pub.dartlang.org/packages/advance_math/score)
[![Points](https://img.shields.io/pub/points/advance_math)](https://pub.dartlang.org/packages/advance_math/score)
[![Popularity](https://img.shields.io/pub/popularity/advance_math)](https://pub.dartlang.org/packages/advance_math/score)
[![SDK Version](https://badgen.net/pub/sdk-version/advance_math)](https://pub.dartlang.org/packages/advance_math)

[![Last Commits](https://img.shields.io/github/last-commit/gameticharles/advance_math?ogo=github&logoColor=white)](https://github.com/gameticharles/advance_math/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gameticharles/advance_math?ogo=github&logoColor=white)](https://github.com/gameticharles/advance_math/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gameticharles/advance_math?ogo=github&logoColor=white)](https://github.com/gameticharles/advance_math)
[![License](https://img.shields.io/github/license/gameticharles/advance_math?ogo=github&logoColor=white)](https://github.com/gameticharles/advance_math/blob/main/LICENSE)

[![Stars](https://img.shields.io/github/stars/gameticharles/advance_math)](https://github.com/gameticharles/advance_math/stargazers)
[![Forks](https://img.shields.io/github/forks/gameticharles/advance_math)](https://github.com/gameticharles/advance_math/network/members)
[![Github watchers](https://img.shields.io./github/watchers/gameticharles/advance_math)](https://github.com/gameticharles/advance_math/MyBadges)
[![Issues](https://img.shields.io./github/issues-raw/gameticharles/advance_math)](https://github.com/gameticharles/advance_math/issues)

# DartFrame

**DartFrame** is a robust, lightweight Dart library designed for data manipulation and analysis. Inspired by popular data science tools like Pandas, DartFrame provides a DataFrame-like structure for handling tabular data, making it easy to clean, analyze, and transform data directly in your Dart applications.

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

---

## Installation

To install DartFrame, add the following to your `pubspec.yaml`:

```yaml
dependencies:
  dartframe: ^0.0.1
```

Then, run:

```bash
dart pub get
```

---

## Getting Started

### Creating a DataFrame

#### From CSV

```dart
var csvData = """
Name,Age,City
Alice,30,New York
Bob,25,Los Angeles
Charlie,35,Chicago
""";

var df = DataFrame.fromCSV(csv: csvData);
print(df.head(3));
```

#### From JSON

```dart
var jsonData = '''
[
  {"Name": "Alice", "Age": 30, "City": "New York"},
  {"Name": "Bob", "Age": 25, "City": "Los Angeles"},
  {"Name": "Charlie", "Age": 35, "City": "Chicago"}
]
''';

var df = DataFrame.fromJson(jsonString: jsonData);
print(df.describe());
```

#### Directly from Lists

```dart
var df = DataFrame(
  columns: ['ID', 'Value'],
  data: [
    [1, 'A'],
    [2, 'B'],
    [3, 'C'],
  ],
);
print(df);
```

---

## Example Usage

### Data Exploration

```dart
print('Columns: ${df.columns}');
print('Shape: ${df.shape}');
print('Head:\n${df.head(5)}');
print('Tail:\n${df.tail(5)}');
print('Summary:\n${df.describe()}');
```

### Data Cleaning

```dart
df.fillna('Unknown');       // Replace missing values with "Unknown"
df.replace('<NA>', null);   // Replace placeholder values with null
df.rename({'Name': 'FullName'}); // Rename column
df.drop('Age');             // Drop the "Age" column
```

### Analysis

```dart
// Group by City and calculate mean age
var grouped = df.groupBy('City');
grouped.forEach((key, group) {
  print('City: $key, Mean Age: ${group['Age'].mean()}');
});

// Frequency counts
print(df.valueCounts('City'));
```

### Data Transformation

```dart
// Add a calculated column
df['IsAdult'] = df['Age'] > 18;
print(df);

// Filter rows
var filtered = df[df['City'] == 'New York'];
print(filtered);
```

### Concatenation

```dart
var df1 = DataFrame(columns: ['A', 'B'], data: [[1, 2], [3, 4]]);
var df2 = DataFrame(columns: ['C', 'D'], data: [[5, 6], [7, 8]]);

// Horizontal concatenation
var horizontal = df1.concatenate(df2, axis: 1);
print(horizontal);

// Vertical concatenation
var vertical = df1.concatenate(df2);
print(vertical);
```

---

## Performance and Scalability

DartFrame is optimized for small to medium-sized datasets. While not designed for big data processing, it can handle thousands of rows efficiently in memory. For larger datasets, consider integrating with distributed processing tools or databases.

---

## Testing

Tests are located in the test directory. To run tests, execute dart test in the project root.

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

This library is provided under the
[Apache License - Version 2.0][apache_license].

[apache_license]: https://www.apache.org/licenses/LICENSE-2.0.txt
