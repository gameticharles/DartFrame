# GeoDataFrame Class Documentation

The `GeoDataFrame` class extends `DataFrame` to provide support for geospatial data. It manages a special "geometry" column alongside other attribute data, similar to libraries like GeoPandas in Python. This allows for the storage and manipulation of geographic features (points, lines, polygons) and their associated properties.

## Relationship with DataFrame

`GeoDataFrame` is a subclass of `DataFrame`. This means it inherits all the standard data manipulation capabilities of a `DataFrame` (like accessing columns, rows, filtering, adding/removing data, etc.) and adds specialized geospatial functionalities. The non-geometric data is referred to as "attributes".

## Creating a GeoDataFrame

There are several ways to create a `GeoDataFrame`:

### 1. Default Constructor (from a `DataFrame`)

You can create a `GeoDataFrame` from an existing `DataFrame` that contains a column with geometry information (e.g., Well-Known Text (WKT) strings or coordinate lists).

**Syntax:**

```dart
GeoDataFrame(
  DataFrame dataFrame, {
  String geometryColumn = 'geometry', // Name of the column holding geometry data
  String? crs,                       // Coordinate Reference System (e.g., 'EPSG:4326')
})
```

**Parameters:**

- `dataFrame`: The input `DataFrame`.
- `geometryColumn`: The name of the column in `dataFrame` that contains the geometry data. This column can contain WKT strings, lists of coordinates, or actual `GeoJSONGeometry` objects.
- `crs`: (Optional) The Coordinate Reference System of the geometries.

**Example:**

```dart
var df = DataFrame(
  columns: ['id', 'name', 'wkt_geometry'],
  [
    [1, 'Point A', 'POINT(0 0)'],
    [2, 'Line B', 'LINESTRING(0 0, 1 1, 2 2)'],
    [3, 'Polygon C', 'POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))']
  ]
);

var gdf = GeoDataFrame(df, geometryColumn: 'wkt_geometry', crs: 'EPSG:4326');
print(gdf);
print(gdf.geometry);
```

During construction, the `geometryColumn` is processed:
- If values are `GeoJSONGeometry` objects, they are used directly.
- If values are `String`, they are parsed as WKT.
- If values are `List`, they are interpreted as coordinates for `GeoJSONPoint`.
- If parsing fails, a default `GeoJSONPoint([0,0])` is used.

### 2. `GeoDataFrame.fromFeatureCollection()`

Creates a `GeoDataFrame` from a `GeoJSONFeatureCollection` object.

**Syntax:**

```dart
factory GeoDataFrame.fromFeatureCollection(
  GeoJSONFeatureCollection featureCollection, {
  String geometryColumn = 'geometry',
  String? crs,
})
```

**Example:**

```dart
// Assume 'featureCollection' is a GeoJSONFeatureCollection object
// (e.g., parsed from a GeoJSON file or created programmatically)

// Example of creating a simple FeatureCollection manually:
var point = GeoJSONPoint([10.0, 20.0]);
var feature = GeoJSONFeature(point, properties: {'name': 'My Point', 'value': 100});
var featureCollection = GeoJSONFeatureCollection([feature]);

var gdf = GeoDataFrame.fromFeatureCollection(featureCollection, crs: 'EPSG:4326');
print(gdf);
```

### 3. `GeoDataFrame.fromDataFrame()`

A static factory method to create a `GeoDataFrame` from a `DataFrame`, with more explicit control over how geometries are derived from columns (either a dedicated geometry column or separate coordinate columns).

**Syntax:**

```dart
static GeoDataFrame fromDataFrame(
  DataFrame dataFrame, {
  String? geometryColumn,          // Name of the column with WKT or parsable geometry strings
  String geometryType = 'point',  // 'point', 'linestring', 'polygon' if deriving from coordinates
  String coordinateType = 'lonlat', // 'lonlat' (looks for 'longitude'/'lat', 'latitude'/'lat')
                                  // or 'xy' (looks for 'x', 'y')
  String? crs,
})
```

**Details:**

- If `geometryColumn` is provided, it attempts to parse geometries from this column (similar to the default constructor).
- If `geometryColumn` is *not* provided, it looks for coordinate columns based on `coordinateType`:
    - `'lonlat'`: Searches for columns named 'longitude' (or 'lon') and 'latitude' (or 'lat'). An 'altitude' (or 'alt', 'elevation') column can also be used for 3D points.
    - `'xy'`: Searches for columns named 'x' and 'y'. A 'z' column can be used for 3D points.
- The `geometryType` helps in constructing the correct geometry (e.g., `GeoJSONPoint`) when using coordinate columns.

**Example (using coordinate columns):**

```dart
var df = DataFrame(
  columns: ['id', 'city_name', 'longitude', 'latitude', 'population'],
  [
    [1, 'City Alpha', -74.0060, 40.7128, 8000000],
    [2, 'City Beta', 2.3522, 48.8566, 2000000],
  ]
);

var gdf = GeoDataFrame.fromDataFrame(
  df,
  coordinateType: 'lonlat', // Will find 'longitude' and 'latitude' columns
  geometryType: 'point',
  crs: 'EPSG:4326',
);
print(gdf);
print(gdf.geometry.getCoordinates());
```

### 4. `GeoDataFrame.fromCoordinates()`

Creates a `GeoDataFrame` (with `Point` geometries) directly from a list of coordinate pairs.

**Syntax:**

```dart
static GeoDataFrame fromCoordinates(
  List<List<double>> coordinates, {
  DataFrame? attributes,        // Optional DataFrame for attribute data
  String coordinateType = 'xy', // 'xy', 'lonlat', etc. (mainly for context, as input is List<double>)
  String? crs,
})
```

**Example:**

```dart
final coordinates = [
  [105.7743099, 21.0717561], // [lon, lat]
  [105.7771289, 21.0715458],
];

final attributeDF = DataFrame(
  columns: ['name', 'type'],
  [
    ['Location 1', 'School'],
    ['Location 2', 'Park'],
  ],
);

final gdf = GeoDataFrame.fromCoordinates(
  coordinates,
  attributes: attributeDF,
  coordinateType: 'lonlat', // Indicates the order in coordinates list
  crs: 'EPSG:4326',
);
print(gdf);
```

### 5. `GeoDataFrame.readFile()`

Reads spatial data from a file, automatically attempting to determine the file type (driver) based on the file extension.

**Syntax:**

```dart
static Future<GeoDataFrame> readFile(
  String filePath, {
  String driver = 'Auto',                 // 'Auto', 'CSV', 'TXT', 'GeoJSON', 'GPX', 'KML', 'ESRI Shapefile' (Shapefile is not fully implemented for reading)
  String delimiter = ',',                 // For CSV/TXT
  bool hasHeader = true,                  // For CSV/TXT
  Map<String, int>? coordinatesColumns, // For CSV/TXT: e.g., {'latitude': 4, 'longitude': 5} (column indices)
  String? geometryColumn,               // For CSV/TXT: Name of column with WKT geometries
  String coordinateType = 'lonlat',       // For CSV/TXT with coordinateColumns: 'lonlat', 'xy', 'lonlatz', 'xyz'
  String? crs,
}) async
```

**Supported Formats (based on implementation):**

- **CSV/TXT:** Reads tabular text files.
    - If `geometryColumn` is provided, it attempts to parse WKT from that column.
    - If `coordinatesColumns` are provided (e.g., `{'latitude': 3, 'longitude': 4}` mapping column names to their 0-based index), it creates Point geometries. `coordinateType` helps interpret these columns.
- **GeoJSON:** Parses GeoJSON files.
- **GPX (GPS Exchange Format):** Parses GPX files, converting waypoints, tracks, and routes to GeoJSON features.
- **KML (Keyhole Markup Language):** Parses KML files, primarily converting placemarks with Point geometries.
- **ESRI Shapefile:** Reading is mentioned but might be unimplemented or partially implemented.

**Examples:**

**Reading a CSV with Latitude/Longitude columns:**

```dart
// Assuming 'data.csv':
// id,name,my_lat,my_lon
// 1,PlaceA,21.071,105.774
// 2,PlaceB,21.072,105.775

final gdfFromCsv = await GeoDataFrame.readFile(
  'data.csv',
  delimiter: ',',
  hasHeader: true,
  coordinatesColumns: {'latitude': 2, 'longitude': 3}, // Column indices for lat/lon
  coordinateType: 'lonlat',
  crs: 'EPSG:4326',
);
print(gdfFromCsv);
```

**Reading a CSV with a WKT geometry column:**

```dart
// Assuming 'data_wkt.csv':
// id,description,geom_wkt
// 1,Feature One,"POINT(10 20)"
// 2,Feature Two,"LINESTRING(0 0, 1 1)"

final gdfFromWktCsv = await GeoDataFrame.readFile(
  'data_wkt.csv',
  geometryColumn: 'geom_wkt',
  crs: 'EPSG:4326',
);
print(gdfFromWktCsv);
```

**Reading a GeoJSON file:**

```dart
// Assuming 'map.geojson' exists
final gdfFromGeoJson = await GeoDataFrame.readFile(
  'map.geojson',
  crs: 'EPSG:4326', // CRS might be in the GeoJSON file, this can be a default/override
);
print(gdfFromGeoJson.head());
```

**Reading a GPX file:**

```dart
// Assuming 'track.gpx' exists
final gdfFromGpx = await GeoDataFrame.readFile('track.gpx');
print(gdfFromGpx.head());
```

## Accessing Data and Properties

### 1. `geometry` (GeoSeries)

Returns the geometry column as a `GeoSeries` object. `GeoSeries` provides geometry-specific operations.

**Example:**

```dart
GeoSeries geometries = gdf.geometry;
print(geometries.area()); // Example: calculate area if polygons
print(geometries.length()); // Example: calculate length if linestrings
print(geometries.getCoordinates(indexParts: true));
```

### 2. `attributes` (DataFrame)

Returns a `DataFrame` containing only the attribute data (all columns except the geometry column).

**Example:**

```dart
DataFrame attributeTable = gdf.attributes;
print(attributeTable.describe());
```

### 3. `featureCount` (int)

Gets the number of features (rows) in the `GeoDataFrame`.

**Example:**

```dart
print('Number of features: ${gdf.featureCount}');
```

### 4. `headers` (List)

Gets the list of all column names, including the geometry column.

**Example:**

```dart
print('Column headers: ${gdf.headers}');
```

### 5. `propertyCount` (int)

Gets the number of properties (columns) in the `GeoDataFrame`. Equivalent to `gdf.columns.length`.

**Example:**

```dart
print('Number of properties: ${gdf.propertyCount}');
```

### 6. `totalBounds` (List<double>)

Calculates the total bounding box for all geometries in the `GeoDataFrame`. Returns a list: `[minX, minY, maxX, maxY]`.

**Example:**

```dart
List<double> bounds = gdf.totalBounds;
print('Total bounds: $bounds');
```

### 7. `centroid` (GeoSeries)

Returns a `GeoSeries` containing the centroids of all geometries in the `GeoDataFrame`.

**Example:**

```dart
GeoSeries centroids = gdf.centroid;
print(centroids.getCoordinates());
```

### 8. `geometries({bool asGeoJSON = false})` (List<dynamic>)

Extracts the geometries.
- If `asGeoJSON` is `true` (default is `false`), returns a list of `GeoJSONGeometry` objects.
- If `asGeoJSON` is `false`, returns a list of coordinate lists (behavior might depend on geometry type).

**Example:**

```dart
List<GeoJSONGeometry> geoJsonGeoms = gdf.geometries(asGeoJSON: true);
// List<dynamic> coordGeoms = gdf.geometries(); // Default might be coordinate lists
```

### 9. `featureCollection` (GeoJSONFeatureCollection)

A getter that converts the `GeoDataFrame` into a `GeoJSONFeatureCollection` object. Equivalent to calling `toFeatureCollection()`.

**Example:**

```dart
GeoJSONFeatureCollection fc = gdf.featureCollection;
// print(fc.toJSON()); // To get the JSON string representation
```

## Modifying Data

Since `GeoDataFrame` extends `DataFrame`, you can use standard `DataFrame` methods to modify attribute data:

- Adding columns: `gdf.addColumn('new_prop', defaultValue: 'someValue');` or `gdf['new_prop'] = [...];`
- Updating values: `gdf.updateColumn(rowIndex, 'propName', newValue);` or `gdf['propName'][rowIndex] = newValue;`
- Dropping columns: `gdf.drop('propName');`
- Filtering rows (which returns a new `DataFrame` that can be used to create a new `GeoDataFrame`).

To modify geometries, you typically assign a new `GeoSeries` or a list of new geometry objects to the geometry column:
```dart
// Example: Buffering geometries and updating the geometry column
GeoSeries bufferedGeometries = gdf.geometry.buffer(distance: 10.0);
gdf[gdf.geometryColumn] = bufferedGeometries.data; // Assign the list of new geometries
```

## Geospatial Operations

### 1. `toFile()`

Exports the `GeoDataFrame` to various file formats. The driver is auto-detected from the file extension but can be specified.

**Syntax:**

```dart
Future<void> toFile(
  String filePath, {
  String driver = 'Auto',         // 'Auto', 'CSV', 'TXT', 'GeoJSON', 'GPX', 'KML', 'ESRI Shapefile' (Shapefile export is UnimplementedError)
  String delimiter = ',',         // For CSV/TXT
  bool includeHeader = true,      // For CSV/TXT
  // ... other format-specific parameters
}) async
```

**Supported Formats for Writing:**

- **CSV/TXT:** Writes attribute data. Geometries are typically not written directly unless they are in a simple string format (like WKT) in an attribute column.
- **GeoJSON:** Exports the `GeoDataFrame` as a GeoJSON FeatureCollection.
- **GPX:** Converts features to GPX format (Points to waypoints, LineStrings to tracks).
- **KML:** Converts Point features to KML Placemarks.
- **ESRI Shapefile:** Export is currently unimplemented.

**Examples:**

**Writing to GeoJSON:**

```dart
await gdf.toFile('output_map.geojson');
print('Exported to GeoJSON.');
```

**Writing attributes to CSV:**

```dart
// Note: This will primarily save the attribute table.
// For geometries, ensure they are in a WKT string column if you want them in the CSV.
await gdf.attributes.toFile('attributes_output.csv');
print('Attributes exported to CSV.');
```

**Writing to GPX:**
```dart
// Create a GeoDataFrame with some Point and LineString features
// ...
await gdf.toFile('output_track.gpx');
print('Exported to GPX');
```

### 2. `toFeatureCollection()`

Converts the `GeoDataFrame` into a `GeoJSONFeatureCollection` object. This is useful for working with GeoJSON data structures directly or for preparing data for JSON serialization.

**Syntax:**

```dart
GeoJSONFeatureCollection toFeatureCollection()
```

**Example:**

```dart
GeoJSONFeatureCollection featureCollection = gdf.toFeatureCollection();
// You can then iterate through features, access properties, geometries,
// or convert to a JSON string.
// String jsonOutput = featureCollection.toJSON(indent: 2);
// print(jsonOutput);
```

This documentation provides a comprehensive overview of the `GeoDataFrame` class, its functionalities, and how to use it for handling geospatial data within the DartFrame environment. For more specific methods inherited from `DataFrame`, please refer to the `DataFrame` documentation.
