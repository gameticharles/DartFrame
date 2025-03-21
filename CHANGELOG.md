# 0.2.3
* **[Fix]** Fixed readme.
* **[FEATURE]** Added more properties
* **[FIX]** Fixed DataFrame constructor to create modifiable column lists, allowing column addition after initialization
* **[FIX]** Updated Series toString() method to properly display custom indices
* **[FEATURE]** Added GeoSeries class for spatial data analysis
* **[FEATURE]** Added GeoSeries.fromXY() factory constructor to create point geometries from x, y coordinates
* **[FEATURE]** Added GeoSeries.fromWKT() factory constructor to create geometries from WKT strings
* **[FEATURE]** Added GeoSeries.fromFeatureCollection() factory constructor to create geometries from GeoJSON
* **[FEATURE]** Added spatial analysis methods to GeoSeries:
  * getCoordinates() - extracts coordinates as a DataFrame
  * countCoordinates - counts coordinate pairs in each geometry
  * countGeometries - counts geometries in multi-part geometries
  * countInteriorRings - counts interior rings in polygonal geometries
  * isClosed - checks if LineStrings are closed
  * isEmpty - checks if geometries are empty
  * isRing - checks if features are rings
  * isValid - validates geometry structures
  * hasZ - checks for 3D coordinates
  * bounds - gets bounding boxes for geometries
  * totalBounds - gets overall bounds of all geometries
  * centroid - calculates centroids of geometries
  * type - gets geometry types
  * area - calculates areas of polygonal geometries
  * lengths - calculates lengths of linear geometries
  * isCCW - checks if rings are counterclockwise
  * contains - checks spatial containment relationships
* **[IMPROVEMENT]** Enhanced Series class to support custom indices similar to DataFrame
* **[IMPROVEMENT]** Renamed DataFrame's rowHeader to index for consistency with pandas API
* **[IMPROVEMENT]** Updated DataFrame constructor to accept index parameter

# 0.2.2
* **[Fix]** Fixed readme.
* **[FEATURE]** Added topics to the package/library

# 0.2.1
* **[Fix]** Fixed readme.

# 0.2.0

* **[FEATURE]** Added `isEmpty` and `isNotEmpty` properties to check if DataFrame has rows
* **[FEATURE]** Added `copy()` method to create deep copies of DataFrames
* **[FEATURE]** Added dimension properties: `rowCount`, `columnCount`, and `shape`
* **[FEATURE]** Added `dtypes` property to get column data types
* **[FEATURE]** Added `hasColumn()` method to check for column existence
* **[FEATURE]** Added `unique()` method to get DataFrame with only unique rows
* **[FEATURE]** Added `unique()` method to Series to get unique values
* **[FEATURE]** Added `resetIndex()` method for reindexing after filtering
* **[FEATURE]** Added conversion methods: `toListOfMaps()` and `toMap()`
* **[FEATURE]** Added `sample()` method for randomly sampling rows
* **[FEATURE]** Added `applyToColumn()` method for applying functions to column elements
* **[FEATURE]** Added `applyToRows()` method for applying functions to each row
* **[FEATURE]** Added `corr()` method for computing correlation coefficients
* **[FEATURE]** Added `bin()` method for creating bins from continuous data
* **[FEATURE]** Added `toCsv()` method for converting DataFrame to CSV string
* **[FEATURE]** Added `pivot()` method for creating pivot tables
* **[FEATURE]** Added `melt()` method for reshaping data from wide to long format
* **[FEATURE]** Added `join()` method for combining DataFrames
* **[IMPROVEMENT]** Enhanced `fillna()` method with strategies (mean, median, mode, forward, backward)
* **[FEATURE]** Added `dropna()` method to remove rows or columns with missing values
* **[IMPROVEMENT]** Improved `replace()` method with regex support and column targeting
* **[FEATURE]** Added `replaceInPlace()` method for in-place value replacement
* **[FEATURE]** Added `astype()` method to convert column data types
* **[FEATURE]** Added `round()` method to round numeric values to specified precision
* **[FEATURE]** Added `rolling()` method for computing rolling window calculations
* **[FEATURE]** Added `cumulative()` method for cumulative calculations (sum, product, min, max)
* **[FEATURE]** Added `quantile()` method to compute quantiles over a column
* **[FEATURE]** Added `rank()` method to compute numerical rank along a column
* **[FEATURE]** Added `abs()` method to Series for calculating absolute values
* **[FEATURE]** Added `copy()` method to Series for creating copies
* **[FEATURE]** Added `cummax()` method to Series for cumulative maximum calculations
* **[FEATURE]** Added `cummin()` method to Series for cumulative minimum calculations
* **[FEATURE]** Added `cumprod()` method to Series for cumulative product calculations
* **[IMPROVEMENT]** Enhanced `cumsum()` method in Series with skipna parameter
* **[FEATURE]** Added GeoDataFrame class for handling geospatial data
* **[Fix]** Fixed the ability to modify individual elements in DataFrame using `df['column'][index] = value` syntax
* **[FIX]** Improved row header display in `toString()` method to properly handle headers of varying lengths

# 0.1.3

* **[IMPROVEMENT]** Fixed Readme not showing the right status
* **[FEATURE]** Added unit tests
* **[FEATURE]** Added row header names/index

# 0.1.2

* Fixed description to match dart packaging

# 0.1.1

* Fixed description.

# 0.1.0

* Initial version.
