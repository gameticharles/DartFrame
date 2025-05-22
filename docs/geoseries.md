# GeoSeries Class Documentation

The `GeoSeries` class in DartFrame represents a one-dimensional array (a column) specifically for holding geometry data. It extends the base `Series` class, endowing it with spatial awareness and functionalities.

## Relationship with Series

`GeoSeries` is a subclass of `Series`. This means it inherits all the fundamental properties and methods of a `Series` (like `data`, `name`, `index`, `length`) and adds features tailored for handling geometric objects (e.g., Points, LineStrings, Polygons).

## Creating a GeoSeries

There are multiple ways to construct a `GeoSeries`:

### 1. Default Constructor

Creates a `GeoSeries` directly from a list of `GeoJSONGeometry` objects.

**Syntax:**

```dart
GeoSeries(
  List<dynamic> values, // List of GeoJSONGeometry objects (or nulls)
  {
  String? crs,
  String name = 'geometry',
  List<dynamic>? index,
});
```

**Parameters:**

- `values`: A list where each element is typically a `GeoJSONGeometry` object (e.g., `GeoJSONPoint`, `GeoJSONLineString`, `GeoJSONPolygon`) or `null`.
- `crs`: (Optional) The Coordinate Reference System for the geometries (e.g., 'EPSG:4326').
- `name`: (Optional) The name for the `GeoSeries`. Defaults to 'geometry'.
- `index`: (Optional) A list to use as the index. Defaults to a standard integer index.

**Example:**

```dart
var point = GeoJSONPoint([0, 0]);
var line = GeoJSONLineString([[1,1], [2,2]]);
var polygon = GeoJSONPolygon([[[0,0], [0,1], [1,1], [1,0], [0,0]]]);

var gs = GeoSeries(
  [point, line, polygon, null],
  name: 'MyGeometries',
  crs: 'EPSG:4326',
  index: ['feat1', 'feat2', 'feat3', 'feat4'],
);
print(gs);
```

### 2. `GeoSeries.fromWKT()`

Creates a `GeoSeries` from a list of Well-Known Text (WKT) strings. Each WKT string is parsed into its corresponding `GeoJSONGeometry` object.

**Syntax:**

```dart
factory GeoSeries.fromWKT(
  List<String> wktStrings, {
  String? crs,
  String name = 'geometry',
  List<dynamic>? index,
})
```

**Example:**

```dart
var wktData = [
  'POINT(0 5)',
  'LINESTRING(0 0, 1 1, 2 2)',
  'POLYGON((10 10, 10 20, 20 20, 20 10, 10 10))'
];

var gsFromWkt = GeoSeries.fromWKT(wktData, name: 'WKT_Geoms', crs: 'EPSG:3857');
print(gsFromWkt);
```

### 3. `GeoSeries.fromFeatureCollection()`

Creates a `GeoSeries` by extracting geometries from a `GeoJSONFeatureCollection`.

**Syntax:**

```dart
factory GeoSeries.fromFeatureCollection(
  GeoJSONFeatureCollection featureCollection, {
  String? crs,
  String name = 'geometry',
  List<dynamic>? index,
})
```

**Example:**

```dart
// Assume 'featureCollection' is a GeoJSONFeatureCollection object
// (e.g., parsed from a GeoJSON file or created programmatically)
var point = GeoJSONPoint([10.0, 20.0]);
var feature1 = GeoJSONFeature(point, properties: {'id': 1});
var line = GeoJSONLineString([[0,0], [1,1]]);
var feature2 = GeoJSONFeature(line, properties: {'id': 2});
var featureCollection = GeoJSONFeatureCollection([feature1, feature2, null]);


var gsFromFc = GeoSeries.fromFeatureCollection(featureCollection, name: 'FC_Geoms');
print(gsFromFc);
```

### 4. `GeoSeries.fromXY()`

Creates a `GeoSeries` of `GeoJSONPoint` geometries from lists of X and Y coordinates (and optionally Z coordinates).

**Syntax:**

```dart
factory GeoSeries.fromXY(
  List<num> x,
  List<num> y, {
  List<num>? z,
  List<dynamic>? index,
  String? crs,
  String name = 'geometry',
})
```

**Parameters:**

- `x`: List of X coordinates (e.g., longitudes).
- `y`: List of Y coordinates (e.g., latitudes).
- `z`: (Optional) List of Z coordinates for 3D points.
- `index`, `crs`, `name`: Same as other constructors.

**Example:**

```dart
final xCoords = [2.5, 5.0, -3.0];
final yCoords = [0.5, 1.0, 1.5];
final zCoords = [10.0, 12.0, 15.0];

var points2D = GeoSeries.fromXY(xCoords, yCoords, name: 'Points2D', crs: "EPSG:4326");
print(points2D);

var points3D = GeoSeries.fromXY(xCoords, yCoords, z: zCoords, name: 'Points3D');
print(points3D);
```

## Accessing Data and Properties

### 1. `crs` (String?)

The Coordinate Reference System of the geometries in the `GeoSeries`. This is a read-only property defined at construction.

**Example:**

```dart
var gs = GeoSeries.fromWKT(['POINT(0 0)'], crs: 'EPSG:4326');
print(gs.crs); // Output: EPSG:4326
```

### 2. `geometries({bool asGeoJSON = false})`

Extracts the geometries from the `GeoSeries` into a `List`.

**Syntax:**

`List<dynamic> geometries({bool asGeoJSON = false})`

- If `asGeoJSON` is `true`, returns a list of `GeoJSONGeometry` objects.
- If `asGeoJSON` is `false` (default), returns a list of coordinate lists (e.g., `[x,y]` for points, `[[x1,y1],[x2,y2]]` for linestrings).

**Example:**

```dart
var gs = GeoSeries([
  GeoJSONPoint([10, 20]),
  GeoJSONLineString([[0,0], [1,1]])
], name: 'MyGeoms');

List<GeoJSONGeometry> geoJsonObjects = gs.geometries(asGeoJSON: true);
print(geoJsonObjects[0].type); // Output: GeoJSONType.point

List<dynamic> coordinateLists = gs.geometries(asGeoJSON: false);
print(coordinateLists[0]); // Output: [10, 20]
print(coordinateLists[1]); // Output: [[0,0], [1,1]]
```

Inherited from `Series`, you can also access:
- `data`: The raw `List<dynamic>` holding the `GeoJSONGeometry` objects.
- `name`: The name of the `GeoSeries`.
- `index`: The index of the `GeoSeries`.
- `length`: The number of geometries in the `GeoSeries`.

## Conversions

### 1. `toWkt()` / `asWkt()`

Converts the `GeoSeries` into a new `Series` containing WKT string representations of the geometries. If a geometry is null or invalid for WKT conversion, it defaults to 'POINT(0 0)'.

**Syntax:**

`Series toWkt()`
`Series asWkt()` (alias for `toWkt()`)

**Example:**

```dart
var gs = GeoSeries([
  GeoJSONPoint([5, 10]),
  GeoJSONLineString([[1,1], [2,2], [3,3]])
], name: 'OriginalGeoms');

Series wktSeries = gs.toWkt();
print(wktSeries);
/*
Output:
      OriginalGeoms_wkt
0             POINT(5 10)
1  LINESTRING(1 1,2 2,3 3)

Length: 2
Type: String
*/
```

## Operations

### 1. `makeValid()`

Creates a new `GeoSeries` by attempting to ensure all geometries are valid. For example, invalid polygons (e.g., not closed, self-intersecting based on simple checks) might be replaced with a default `GeoJSONPoint([0,0])`. The exact validation logic depends on internal helpers like `_isValidPolygon`.

**Syntax:**

`GeoSeries makeValid()`

**Example:**

```dart
// Assuming a GeoSeries 'gs' might contain some invalid geometries
// For instance, a polygon that isn't properly closed
var invalidPoly = GeoJSONPolygon([[[0,0], [0,1], [1,1]]]); // Not closed
var gsWithInvalid = GeoSeries([invalidPoly], name: 'MaybeInvalid');

var validGs = gsWithInvalid.makeValid();
print(validGs.data[0]); // If invalidPoly was corrected or replaced
```

## Geospatial Properties and Methods (from examples)

The `example/geoseries.dart` showcases several geospatial properties and methods that operate on the geometries within a `GeoSeries`. These typically return a new `Series` where each element corresponds to the result of the operation on the respective geometry in the `GeoSeries`.

*(Note: These methods might be implemented as extension methods or directly on `GeoSeries` or its underlying geometry types. The documentation here is based on their usage in the example.)*

### 1. `area` (Series)
Calculates the area of each geometry (meaningful for Polygons and MultiPolygons).
```dart
// GeoSeries series = ...;
// Series areas = series.area;
// print(areas);
```

### 2. `bounds` (Series)
Returns the bounding box for each geometry as a `List<double> [minX, minY, maxX, maxY]`.
```dart
// GeoSeries series = ...;
// Series boundsList = series.bounds;
// print(boundsList);
```

### 3. `length` (Series) - *Note: This is different from `GeoSeries.length` property*
Calculates the length of each geometry (meaningful for LineStrings and MultiLineStrings).
```dart
var series = GeoSeries([
  GeoJSONLineString([[0,0], [1,1], [0,1]]), // Length approx 2.414
  GeoJSONPoint([0,1])                       // Length 0.0
]);
Series lengths = series.lengths; // Assuming 'lengths' is the correct accessor from example
print(lengths);
// Expected: A Series with [2.414..., 0.0]
```

### 4. `centroid` (GeoSeries)
Returns a new `GeoSeries` containing the centroid of each geometry.
```dart
// GeoSeries series = ...;
// GeoSeries centroids = series.centroid;
// print(centroids);
```

### 5. `countCoordinates` (Series<int>)
Counts the total number of coordinates in each geometry.
```dart
var series = GeoSeries([
  GeoJSONLineString([[0,0], [1,1], [1,-1], [0,1]]), // 4 coordinate pairs
  GeoJSONPoint([0,0])                               // 1 coordinate pair
]);
Series counts = series.countCoordinates;
print(counts); // Expected: Series [4, 1] (actual output might vary based on how pairs are counted)
```

### 6. `countGeometries` (Series<int>)
Counts the number of simple geometries within each potentially multi-part geometry. For simple geometries (Point, LineString, Polygon), this is 1. For MultiPoint, MultiLineString, MultiPolygon, it's the number of constituent parts.
```dart
var series = GeoSeries([
  GeoJSONMultiPoint([[0,0], [1,1]]), // 2 points
  GeoJSONLineString([[0,0], [1,1]])  // 1 line
]);
Series geomCounts = series.countGeometries;
print(geomCounts); // Expected: Series [2, 1]
```

### 7. `countInteriorRings` (Series<int>)
Counts the number of interior rings (holes) in each Polygon or MultiPolygon. Returns 0 for other geometry types.
```dart
var series = GeoSeries([
  GeoJSONPolygon([ [[0,0],[0,5],[5,5],[5,0],[0,0]], [[1,1],[1,4],[4,4],[4,1],[1,1]] ]), // 1 hole
  GeoJSONPoint([0,1]) // 0 holes
]);
Series interiorRingCounts = series.countInteriorRings;
print(interiorRingCounts); // Expected: Series [1, 0]
```

### 8. `isEmpty` (Series<bool>)
Checks if each geometry is empty (e.g., a Point with no coordinates, a LineString with no points).
```dart
var series = GeoSeries([
  GeoJSONPoint([0,0]), // Not empty
  GeoJSONPoint([]),    // Empty (conceptually, actual representation might vary)
  null
]);
Series emptyFlags = series.isEmpty;
print(emptyFlags); // Expected: Series [false, true, true] (assuming null is treated as empty)
```

### 9. `isClosed` (Series<bool>)
Checks if each LineString geometry is closed (start and end points are the same). Returns `false` for non-LineString types.
```dart
var series = GeoSeries([
  GeoJSONLineString([[0,0], [1,1], [0,1], [0,0]]), // Closed
  GeoJSONLineString([[0,0], [1,1], [0,1]])       // Not closed
]);
Series closedFlags = series.isClosed;
print(closedFlags); // Expected: Series [true, false]
```

### 10. `isRing` (Series<bool>)
Checks if each LineString is a ring (closed and simple/non-self-intersecting). The simplicity check might be basic. Returns `false` for non-LineStrings.
```dart
var series = GeoSeries([
  GeoJSONLineString([[0,0], [1,1], [1,-1], [0,0]]), // Closed, likely simple
  GeoJSONLineString([[0,0], [1,1], [0,1]])        // Not closed
]);
Series ringFlags = series.isRing;
print(ringFlags); // Expected: Series [true, false]
```

### 11. `hasZ` (Series<bool>)
Checks if each geometry has Z-coordinates (3D).
```dart
var series = GeoSeries([
  GeoJSONPoint([0,1]),       // 2D
  GeoJSONPoint([0,1,2])    // 3D
]);
Series zFlags = series.hasZ;
print(zFlags); // Expected: Series [false, true]
```

### 12. `contains(dynamic other, {bool align = true})` (Series<bool>)
Performs a spatial "contains" test for each geometry in the `GeoSeries` against another geometry or a corresponding geometry in another `GeoSeries`.
- `other`: Can be a single `GeoJSONGeometry` or another `GeoSeries`.
- `align`: If `true` (default) and `other` is a `GeoSeries`, performs element-wise comparison based on index. If `false`, the behavior might be a Cartesian-like check or comparison against the first element of `other` (behavior needs clarification from library specifics if not element-wise). The example `series2.contains(series1, align: false)` seems to imply an element-wise comparison if `series1` and `series2` have the same length.

**Example:**
```dart
final series1 = GeoSeries([GeoJSONPolygon([[[0,0],[1,1],[0,1],[0,0]]]), GeoJSONPoint([0.5, 0.5])]);
final pointInPoly = GeoJSONPoint([0.2, 0.5]);
final pointOutside = GeoJSONPoint([5,5]);

Series containsPoint = series1.contains(pointInPoly);
print(containsPoint); // Expected: Series [true, false] (Polygon contains pointInPoly, Point does not)

final series2 = GeoSeries([GeoJSONPolygon([[[0,0],[2,2],[0,2],[0,0]]]), GeoJSONPoint([0.5, 0.5])]);
// series2[0] is a larger polygon, series2[1] is the same point

Series s2ContainsS1Aligned = series2.contains(series1, align: true);
print(s2ContainsS1Aligned); // Expected: Series [true, true]
                               // (larger polygon contains smaller, point contains itself)
```

This documentation covers the creation, properties, conversions, and key operations of the `GeoSeries` class, including common geospatial analyses demonstrated in the examples. For inherited functionalities, refer to the `Series` documentation.
