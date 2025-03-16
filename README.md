[![Pub package](https://img.shields.io/pub/v/dartframe.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/dartframe)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Likes](https://img.shields.io/pub/likes/dartframe)](https://pub.dartlang.org/packages/dartframe/score)
[![Points](https://img.shields.io/pub/points/dartframe)](https://pub.dartlang.org/packages/dartframe/score)
[![Popularity](https://img.shields.io/pub/popularity/dartframe)](https://pub.dartlang.org/packages/dartframe/score)
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

## GeoDataFrame

The `GeoDataFrame` class extends the functionality of DataFrame by adding support for geospatial data, similar to GeoPandas in Python. It maintains a geometry column alongside attribute data, making it easy to work with geographic information.

### Features

- Read and write various geospatial file formats (GeoJSON, CSV with coordinates, GPX, KML)
- Store and manipulate vector geometries (Point, LineString, Polygon, etc.)
- Calculate spatial properties (area, bounds, validity)
- Perform spatial operations and queries
- Seamless integration with the DataFrame API for attribute manipulation

### Creating a GeoDataFrame

There are several ways to create a GeoDataFrame:

#### From a file

```dart
// Read from a CSV file with coordinate columns
final geoDataFrame = await GeoDataFrame.readFile(
  'path/to/data.csv',
  coordinatesColumns: {
    'longitude': 1,  // column index for longitude
    'latitude': 2    // column index for latitude
  },
  coordinateType: 'lonlat'
);

// Read from a GeoJSON file
final geoJson = await GeoDataFrame.readFile('path/to/data.geojson');

// Read from a GPX file
final gpxData = await GeoDataFrame.readFile('path/to/tracks.gpx');
```

#### From coordinates

```dart
// Create from a list of coordinate pairs
final coordinates = [
  [0.0, 0.0],
  [1.0, 0.0],
  [1.0, 1.0],
  [0.0, 1.0]
];

final geoDataFrame = GeoDataFrame.fromCoordinates(
  coordinates,
  coordinateType: 'xy'  // or 'lonlat'
);
```

#### From an existing DataFrame

```dart
// Convert a DataFrame with a geometry column to a GeoDataFrame
final dataFrame = DataFrame(
  columns: ['id', 'name', 'geometry'],
  data: [
    [1, 'Point A', [0.0, 0.0]],
    [2, 'Point B', [1.0, 1.0]],
  ]
);

final geoDataFrame = GeoDataFrame.fromDataFrame(
  dataFrame,
  geometryColumn: 'geometry',
  geometryType: 'point',
  coordinateType: 'xy'
);
```

### Accessing Data

```dart
// Get the number of features
print(geoDataFrame.featureCount);

// Access the attribute table as DataFrame
print(geoDataFrame.attributes);

// Access a specific feature
var feature = geoDataFrame.getFeature(1);

// Get all geometries
var geometries = geoDataFrame.geometries();
```

### Manipulating Data

```dart
// Add a new feature
geoDataFrame.addFeature(
  GeoJSONPoint([10.0, 20.0]),
  properties: {'name': 'New Point', 'value': 42}
);

// Delete a feature
geoDataFrame.deleteFeature(0);

// Add a property to all features
geoDataFrame.addProperty('category', defaultValue: 'default');

// Update properties
geoDataFrame.attributes['population'][3] = 1500;

// Use DataFrame operations on attributes
var filtered = geoDataFrame.attributes.filter((row) => row[2] > 1000);
```

### Spatial Properties

GeoDataFrame automatically calculates and provides access to several spatial properties:

```dart
// Each feature has these properties in the attributes DataFrame:
// - geometry: WKT representation of the geometry
// - area: Area of polygon features (0 for points and lines)
// - geom_type: Type of geometry (Point, LineString, Polygon, etc.)
// - is_valid: Boolean indicating if the geometry is valid
// - bounds: Bounding box of the geometry

// Access these properties
print(geoDataFrame.attributes['geometry'][0]);  // POINT (10.0 20.0)
print(geoDataFrame.attributes['area'][0]);      // 0.0 for a point
print(geoDataFrame.attributes['geom_type'][0]); // Point
```

### Exporting Data

```dart
// Export to GeoJSON
await geoDataFrame.toFile('output.geojson');

// Export to CSV
await geoDataFrame.toFile('output.csv');

// Export to GPX
await geoDataFrame.toFile('output.gpx');

// Export to KML
await geoDataFrame.toFile('output.kml');
```

### Finding Features

```dart
// Find features based on a query
var foundFeatures = geoDataFrame.findFeatures((feature) => 
  feature.properties!['population'] > 1000 && 
  feature.properties!['area'] < 500
);
```

### Complete Example

```dart
Future<void> main() async {
  // Read file
  final geoDataFrame = await GeoDataFrame.readFile(
    'data.csv',
    delimiter: ',',
    hasHeader: true,
    coordinatesColumns: {
      'latitude': 1,
      'longitude': 2
    },
  );

  // Print information
  print('Number of features: ${geoDataFrame.featureCount}');
  print('Properties: ${geoDataFrame.headers}');
  
  // Add a new property
  geoDataFrame.addProperty('category', defaultValue: 'residential');
  
  // Calculate statistics on a numeric column
  print('Population statistics:');
  print(geoDataFrame.attributes['population'].describe());
  
  // Filter features
  var urbanAreas = geoDataFrame.findFeatures((feature) => 
    feature.properties!['population'] > 10000
  );
  
  print('Urban areas: ${urbanAreas.length}');
  
  // Export the filtered data
  final urbanGeoDataFrame = GeoDataFrame(
    GeoJSONFeatureCollection(urbanAreas),
    geoDataFrame.headers
  );
  
  await urbanGeoDataFrame.toFile('urban_areas.geojson');
}
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
