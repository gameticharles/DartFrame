# 0.8.3

- **[MAJOR FEATURE]** Comprehensive String Operations Extension
  - **NEW**: Pattern extraction methods - `str.extract()`, `str.extractall()`, `str.findall()` for regex-based text processing
  - **NEW**: String padding and justification - `str.pad()`, `str.center()`, `str.ljust()`, `str.rjust()`, `str.zfill()` for text alignment
  - **NEW**: String slicing and manipulation - `str.slice()`, `str.get()` for advanced substring operations
  - **NEW**: String concatenation and repetition - `str.cat()`, `str.repeat()` for text composition
  - **NEW**: String type checking methods - `str.isalnum()`, `str.isalpha()`, `str.isdigit()`, `str.isspace()`, `str.islower()`, `str.isupper()`, `str.istitle()`, `str.isnumeric()`, `str.isdecimal()` for character validation
  - **COMPATIBILITY**: Pandas-like string accessor API for familiar text operations

- **[MAJOR FEATURE]** Enhanced Categorical Data Operations
  - **NEW**: `cat.reorderCategories()` - Reorder category levels with ordering control
  - **NEW**: `cat.addCategories()` - Add new categories to existing categorical data
  - **NEW**: `cat.removeCategories()` - Remove unused categories with validation
  - **NEW**: `cat.renameCategories()` - Rename categories using mapping dictionaries
  - **NEW**: `cat.setCategories()` - Set categories with recode and rename modes
  - **NEW**: `cat.asOrdered()` / `cat.asUnordered()` - Convert between ordered and unordered categorical types
  - **NEW**: `cat.min()` / `cat.max()` - Min/max operations for ordered categories
  - **NEW**: `cat.memoryUsage()` - Memory usage analysis and optimization metrics for categorical storage
  - **ENHANCEMENT**: All categorical operations integrated with CategoricalAccessor interface

- **[FEATURE]** DataFrame Duplicate Handling and Selection Methods
  - **NEW**: `duplicated()` - Identify duplicate rows with configurable subset and keep options
  - **NEW**: `dropDuplicates()` - Remove duplicate rows from DataFrame
  - **NEW**: `nlargest()` - Select N rows with largest values in specified column
  - **NEW**: `nsmallest()` - Select N rows with smallest values in specified column

- **[FEATURE]** Functional Programming Extensions
  - **NEW**: `apply()` - Apply function along axis (rows or columns) with flexible operation support
  - **NEW**: `applymap()` - Element-wise function application across entire DataFrame
  - **NEW**: `agg()` - Aggregate with multiple functions simultaneously for complex aggregations
  - **NEW**: `transform()` - Transform values while preserving DataFrame structure
  - **NEW**: `pipe()` - Apply chainable functions for method composition

- **[MAJOR FEATURE]** GroupBy Enhancements with Advanced Operations
  - **NEW**: `GroupBy` class providing chainable API for grouped operations
  - **NEW**: `groupBy2()` - Returns GroupBy object for method chaining and advanced groupby workflows
  - **NEW**: Transform operations - `transform()`, `transformMean()`, `transformSum()` for group-wise transformations
  - **NEW**: Filter operations - `filter()` method for group-wise filtering based on conditions
  - **NEW**: Cumulative operations - `cumsum()`, `cumprod()`, `cummax()`, `cummin()` for cumulative calculations within groups
  - **NEW**: Row selection - `nth()`, `head()`, `tail()` for selecting specific rows within groups
  - **NEW**: `NamedAgg` class for named aggregations with multiple function support
  - **NEW**: `pipe()` for method chaining and custom group operations
  - **ARCHITECTURE**: Seamless integration with existing groupBy functionality

- **[MAJOR FEATURE]** Advanced Time Series Operations (12 new methods)
  - **NEW**: Shift operations - `shift()`, `lag()`, `lead()` for time series data alignment
  - **NEW**: Time index operations - `tshift()` for shifting by time period, `asfreq()` for frequency conversion
  - **NEW**: Time-based filtering - `atTime()`, `betweenTime()` for time window selection, `first()`, `last()` for period endpoints
  - **NEW**: Timezone operations - `tzLocalize()` for adding timezone info, `tzConvert()` for timezone conversion, `tzNaive()` for removing timezone
  - **COMPATIBILITY**: Pandas-like API for seamless time series workflows

- **[FEATURE]** Enhanced Resampling Operations
  - **NEW**: `resampleOHLC()` - Open, High, Low, Close resampling for OHLC data aggregation
  - **NEW**: `resampleNunique()` - Count unique values per resampling period
  - **NEW**: `resampleWithOffset()` - Resampling with custom time offset support
  - **ENHANCEMENT**: Advanced time series data transformations with period-based aggregation

- **[FEATURE]** Advanced Data Slicing Methods (6 new methods)
  - **NEW**: `slice()` - Flexible slicing with step parameter support
  - **NEW**: `sliceByLabel()` - Label-based range slicing for index-based selection
  - **NEW**: `sliceByPosition()` - Combined position and range slicing operations
  - **NEW**: `sliceByLabelWithStep()` - Label-based slicing with step increments
  - **NEW**: `everyNthRow()` / `everyNthColumn()` - Convenience methods for sampling every nth element
  - **NEW**: `reverseRows()` / `reverseColumns()` - Row and column reversal operations

- **[FEATURE]** Expression Evaluation and Querying
  - **NEW**: `eval()` - Evaluate string expressions for computed columns and values
  - **NEW**: `query()` - Query DataFrame using intuitive string expressions with variable binding
  - **ENHANCEMENT**: Chainable expression evaluation for complex data transformations

- **[FEATURE]** MultiIndex and Advanced Indexing Support
  - **NEW**: `MultiIndex` - Hierarchical indexing for multi-level row/column structures
  - **NEW**: `DatetimeIndex` - Timezone-aware datetime indexing with frequency support
  - **NEW**: `TimedeltaIndex` - Time difference indexing for duration-based operations
  - **NEW**: `PeriodIndex` - Time period indexing for period-based time series
  - **ARCHITECTURE**: Native support for multi-dimensional hierarchical data structures

# 0.8.2

- **[FIX]** Code fix
- **[Fixed]** Doc Strings.
- **[IMPROVEMENT]** Improved dart format.

# 0.8.1

- **[FIX]** Code fix

# 0.8.0

- **[MAJOR FEATURE]** Enhanced File I/O Support with Web Compatibility
  - **NEW**: Full CSV support using `csv` package - read/write with custom delimiters, headers, encoding
  - **NEW**: Full Excel support using `excel` package- read/write .xlsx/.xls files with multi-sheet operations
  - **NEW**: Multi-sheet Excel operations - `readAllExcelSheets()` and `writeExcelSheets()` for working with entire workbooks
  - **NEW**: Platform-agnostic FileIO abstraction - works on desktop, mobile, and web without code changes
  - **NEW**: Binary file support - `readBytesFromFile()` and `writeBytesToFile()` for Excel and other binary formats
  - **NEW**: `deleteFile()` method added to FileIO interface for temporary file cleanup
  - **ENHANCEMENT**: All file readers/writers now use FileIO for cross-platform compatibility
  - **ENHANCEMENT**: DataFrame I/O methods now support both file paths and string content
    - `DataFrame.fromCSV()` supports both `path` and `csv` parameters with full DataFrame options (formatData, missingDataIndicator, replaceMissingValueWith, allowFlexibleColumns)
    - `DataFrame.fromJson()` supports both `path` and `jsonString` parameters with all orientations and DataFrame options
    - Automatic temporary file handling for string-based input with proper cleanup
  - **ENHANCEMENT**: Unified `toJSON()` method combines in-memory conversion and file writing
    - Returns JSON structure when `path` is null (in-memory mode)
    - Writes to file when `path` is provided (file mode)
    - Supports all orientations: 'records', 'index', 'columns', 'values'
  - **WEB**: Full web browser support - upload files for processing, download results
  - Comprehensive documentation with examples for all file formats

- **[MAJOR FEATURE]** HDF5 File Support - Pure Dart implementation
  - **NEW**: Read HDF5 datasets with `FileReader.readHDF5()` - compatible with Python h5py, MATLAB v7.3, R
  - **NEW**: All major datatypes supported (numeric, strings, compounds, arrays, enums, variable-length, timestamps)
  - **NEW**: Multi-dimensional datasets (3D+) with automatic flattening and shape preservation
  - **NEW**: Compression support (gzip, lzf, shuffle filter) and chunked storage with B-tree indexing
  - **NEW**: Group navigation, attributes, metadata, and dataset slicing
  - **NEW**: Cross-platform compatible (Windows, macOS, Linux, Web, iOS, Android) - no FFI dependencies
- **[BREAKING CHANGE]** All functions with field name `inputFilePath` have been simplified to `path`.

# 0.7.0

- **[BREAKING CHANGE]** Removed all geospatial features (`GeoDataFrame`, `GeoSeries`).
  - **REMOVAL**: The `GeoDataFrame` and `GeoSeries` classes, along with all related spatial analysis methods, have been completely removed from the `dartframe` package.
  - **REASON**: This change was made to streamline the core library, reduce its size, and separate concerns. Geospatial functionality is now housed in a dedicated, specialized package.
  - **MIGRATION**: All geospatial features have been migrated to the new `geoengine` package. To continue using `GeoDataFrame` and `GeoSeries`, please add `geoengine` to your `pubspec.yaml` dependencies.
  - You can find the new package here: [geoengine](https://pub.dev/packages/geoengine) on pub.dev.
  - This move allows for more focused development on both the core data manipulation features in `dartframe` and the geospatial capabilities in `geoengine`.

# 0.6.3

- **[IMPROVEMENT]** Improved dart format.

# 0.6.2

- **[IMPROVEMENT]** Improved dart format.

# 0.6.1

- **[Fixed]** Doc Strings.
- **[IMPROVEMENT]** Improved dart format.

# 0.6.0

- **[FEATURE]** Added comprehensive time series enhancements
  - **NEW**: `TimeSeriesIndex` class for time-based indexing and operations
    - Support for timestamps with frequency information (Daily, Hourly, Monthly, Yearly)
    - Factory constructor `TimeSeriesIndex.dateRange()` for creating time series ranges
    - Automatic frequency detection with `detectFrequency()` method
    - Utility methods: `slice()`, `contains()`, `indexOf()`, `asFreq()` for frequency conversion
    - Support for empty time series with proper error handling
  - **NEW**: `FrequencyUtils` class with time series utilities
    - Frequency normalization and validation (`normalizeFrequency()`, `isValidFrequency()`)
    - Human-readable frequency descriptions (`frequencyDescription()`)
    - Duration calculations for supported frequencies (`getFrequencyDuration()`)
    - Support for frequency aliases (daily, hourly, monthly, yearly, annual)
  - **NEW**: `DataFrameTimeSeries` extension for DataFrame time series operations
    - `resample()` method for changing time series frequency with aggregation functions
    - Support for multiple aggregation functions: mean, sum, min, max, count, first, last
    - `upsample()` method for increasing frequency with fill methods (pad/ffill, backfill/bfill, nearest)
    - `downsample()` method for decreasing frequency with aggregation
    - Automatic date column detection in DataFrames
    - Comprehensive error handling for edge cases and invalid inputs
  - **NEW**: Comprehensive test coverage with 43 passing tests
    - Tests for `TimeSeriesIndex` constructor, properties, and utility methods
    - Tests for `dateRange()` factory constructor with various frequencies (D, H, M, Y)
    - Tests for frequency detection and validation functionality
    - Tests for DataFrame resampling, upsampling, and downsampling operations
    - Edge case testing for empty DataFrames, null dates, and mixed data types
    - Error handling validation for unsupported frequencies and methods
  - **ARCHITECTURE**: Seamless integration with existing DataFrame and Series classes
  - **COMPATIBILITY**: Pandas-like API for familiar time series operations
  - **PERFORMANCE**: Efficient time-based operations with proper indexing
  - All time series functionality follows pandas conventions for easy migration
- **[FEATURE]** Added comprehensive categorical data support integrated directly into Series
  - **NEW**: `Series.astype('category')` method for converting Series to categorical dtype (pandas-compatible)
  - **NEW**: `CategoricalAccessor` (.cat) providing pandas-like categorical operations interface
  - **NEW**: Efficient memory storage using integer codes with category labels mapping
  - **NEW**: Support for both ordered and unordered categorical data types
  - **NEW**: Category management operations:
    - `series.cat.addCategories()` - Add new categories to existing categorical data
    - `series.cat.removeCategories()` - Remove unused categories with validation
    - `series.cat.renameCategories()` - Rename categories using mapping dictionary
    - `series.cat.reorderCategories()` - Reorder categories and set ordered flag
  - **NEW**: Categorical properties and methods:
    - `series.cat.categories` - Access category labels
    - `series.cat.codes` - Access integer codes
    - `series.cat.ordered` - Check if categories are ordered
    - `series.cat.nCategories` - Get number of categories
    - `series.cat.unique()` - Get unique categories present in data
    - `series.cat.contains()` - Check if categorical contains specific value
  - **NEW**: `series.isCategorical` property to check if Series is categorical
  - **NEW**: `series.isCategoricalLike()` method to detect categorical-suitable data
  - **NEW**: `series.seriesDtype` property for pandas-like dtype information
  - **NEW**: Enhanced `series.dtype` getter to handle categorical data types
  - **NEW**: Seamless DataFrame integration - categorical Series work in all DataFrame operations
  - **NEW**: Automatic data synchronization between categorical codes and Series values
  - **NEW**: Type conversion support: 'category', 'object', 'int', 'float', 'string' dtypes
  - **ARCHITECTURE**: Integrated approach - no separate CategoricalSeries class needed
  - **ARCHITECTURE**: Internal `_Categorical` class for efficient categorical storage
  - **PERFORMANCE**: Memory optimization - categorical encoding only when beneficial
  - **COMPATIBILITY**: Full pandas API compatibility for categorical operations
  - All existing Series methods (length, nunique, valueCounts, etc.) work seamlessly with categorical data
  - Maintains backward compatibility - no breaking changes to existing Series functionality
- **[IMPROVEMENT]** Improved performance optimizations
- **[FEATURE]** Added comprehensive functions for missing data operations
  - **NEW**: Complete test coverage for Series interpolation methods (linear, polynomial, spline)
  - **NEW**: Extensive testing of enhanced fill operations (ffill, bfill) with limit parameters
  - **NEW**: Missing data analysis accuracy validation using isna() and notna() methods
  - **NEW**: Integration for combining interpolation, fill operations, and missing data detection
  - **NEW**: Edge case testing for invalid parameters, insufficient data, and mixed data types
  - **NEW**: Custom missing value handling across different scenarios (-999, 'NA', etc.)
  - **NEW**: DataFrame-level missing data operations testing for multi-column scenarios
  - Validates error handling, data preservation, and method parameter combinations
  - Ensures robust behavior for complex missing data workflows and edge cases
- **[FEATURE]** Added Shape class with multi-dimensional data structure support
  - Supports both named access (`shape.rows`, `shape.columns`) and indexed access (`shape[0]`, `shape[1]`)
  - Future-proofed for 3D+ data structures (tensors)
  - Added utility methods: `addDimension()`, `removeDimension()`, `transpose()`, `size`, `isEmpty`, etc.
- **[FEATURE]** Implemented comprehensive rolling window operations
  - **NEW**: `rollingWindow()` method with pandas-like API for all columns simultaneously
  - Basic operations: `mean()`, `sum()`, `std()`, `variance()`, `min()`, `max()`
  - Advanced operations: `median()`, `quantile()`, `skew()`, `kurt()`
  - Correlation operations: `corr()`, `cov()` with other DataFrames
  - Custom functions: `apply()` method for user-defined operations
  - Support for centered windows, minimum periods, and flexible parameters
- **[FEATURE]** Implemented comprehensive statistical methods and consolidated statistical functions
  - **CONSOLIDATION**: Moved all basic statistical functions from `functions.dart` to `statistics.dart` for better organization
    - Migrated `count()`, `mean()`, `min()`, `max()`, `sum()`, `describe()` with enhanced APIs
    - All functions now have consistent `skipna` parameter (defaults to `true`)
    - Improved error handling with `ArgumentError` instead of generic exceptions
    - Better missing value handling using internal `_isMissing()` method
    - Enhanced return types: `dynamic` for min/max/sum to handle missing values properly
  - **NEW**: 19 additional statistical functions added to SeriesStatistics extension
  - **NEW**: Basic Statistics Functions:
    - `cumsum()` - Cumulative sum over the Series with skipna support
    - `nunique()` - Count number of unique values with dropna parameter
    - `value_counts()` - Frequency count with normalize, sort, ascending, and dropna options
  - **NEW**: Percentile Functions:
    - `percentile()` - Alternative to quantile using 0-100 scale for easier interpretation
    - `iqr()` - Interquartile Range (Q3 - Q1) for measuring statistical dispersion
  - **NEW**: Advanced Statistics Functions:
    - `sem()` - Standard Error of the Mean with configurable degrees of freedom
    - `mad()` - Mean Absolute Deviation for robust central tendency measurement
    - `range()` - Range (max - min) for measuring data spread
  - **NEW**: Correlation and Covariance Functions:
    - `corr()` - Pearson correlation coefficient with another Series
    - `cov()` - Covariance with another Series and configurable degrees of freedom
    - `autocorr()` - Autocorrelation with configurable lag periods for time series analysis
  - **NEW**: Rank and Order Statistics Functions:
    - `rank()` - Rank values with 5 tie-breaking methods ('average', 'min', 'max', 'first', 'dense')
    - `pct_change()` - Percentage change between consecutive values for time series analysis
    - `diff()` - Difference between consecutive values with configurable periods
  - **NEW**: Robust Statistics Functions:
    - `trimmed_mean()` - Mean after removing outliers from both tails (configurable proportion)
    - `winsorized_mean()` - Mean after capping outliers at boundary values
  - **NEW**: Distribution Functions:
    - `entropy()` - Shannon entropy with configurable logarithm base for information theory
    - `geometric_mean()` - Geometric mean for positive values (nth root of product)
    - `harmonic_mean()` - Harmonic mean for positive values (reciprocal of arithmetic mean of reciprocals)
  - **ENHANCEMENT**: All statistical functions feature:
    - Consistent API design with `skipna` parameters
    - Comprehensive documentation with mathematical explanations and examples
    - Proper edge case handling (empty data, insufficient samples, non-numeric data)
    - Return `double.nan` or `_missingRepresentation` for invalid cases instead of throwing exceptions
    - Full integration with existing Series functionality and DataFrame operations
  - **PERFORMANCE**: Optimized mathematical operations using dart:math library functions
  - **COMPATIBILITY**: Pandas-like API for familiar data science workflows
  - **ARCHITECTURE**: Over 40 statistical functions now available in Series class
  - Fixed broken `describe()` function that was calling undefined `std()` and `quantile()` methods
  - Removed duplicate `cumsum()` function from `functions.dart` to avoid conflicts
  - All existing tests pass with enhanced statistical functionality
- **[DEPRECATION]** Deprecated single-column `rolling()` method in favor of `rollingWindow()`
  - Added migration guide and compatibility documentation
  - Maintained backward compatibility for existing code
  - Enhanced performance for multiple rolling operations
- **[FEATURE]** Added comprehensive data reshaping and manipulation extensions
  - **NEW**: `DataFrameReshaping` extension with advanced reshaping operations
    - `stack()` and `unstack()` methods for hierarchical indexing and multi-level data structures
    - Enhanced `meltEnhanced()` method with additional pandas-like parameters (ignoreIndex, colLevel)
    - `widen()` method as intuitive inverse of melt for long-to-wide format conversion
    - Corrected `transpose()` method with proper matrix transposition logic
  - **NEW**: Enhanced pivot table functionality
    - `pivotTableEnhanced()` with support for multiple index and column levels
    - `crosstab()` method for cross-tabulation analysis with margins and normalization
    - Advanced aggregation options and margin calculations
  - **NEW**: `DataFrameMerging` extension with enhanced join operations
    - `merge()` method with pandas-like parameters and validation options
    - `concat()` method for concatenating DataFrames with flexible options
    - `joinEnhanced()` method with additional join strategies
    - Merge validation (one-to-one, one-to-many, many-to-one, many-to-many)
    - Framework for `mergeAsof()` (asynchronous merge operations)
- **[ARCHITECTURE]** Maintained dual approach for reshaping methods
  - `functions.dart`: Contains standard, fully functional methods (`melt`, `pivotTable`, `join`)
  - `reshaping.dart`: Contains enhanced versions with "Enhanced" suffixes (`meltEnhanced`, `pivotTableEnhanced`, `joinEnhanced`)
  - Users can choose between standard functionality or enhanced features
  - No breaking changes - both approaches coexist for maximum compatibility
- **[FIX]** Corrected transpose method implementation
  - Fixed incorrect column structure that was using index values as column names
  - Implemented proper matrix transposition where columns become rows and vice-versa
  - Added proper copy logic with `_copyValue()` helper for different data types
  - Enhanced documentation with clear examples of transpose behavior

# 0.5.5

- **[FEATURE]** Changed to MIT License

# 0.5.4

- **[IMPROVEMENT]** Cleaned code

# 0.5.3

- **[IMPROVEMENT]** Cleaned code

# 0.5.2

- **[FIX]** Fixed FileIO not exported

# 0.5.1

- **[IMPROVEMENT]** Cleaned code
- **[IMPROVEMENT]** Added documentation strings to functions and classes
- **[FIX]** Moved all experiments to new branch
- **[IMPROVEMENT]** Updated README and improved documentation
- **[FEATURE]** Add quantile calculation with tests for edge cases

# 0.5.0

- **[IMPROVEMENT]** Reorganize codebase into discrete libraries and update dependencies
- **[IMPROVEMENT]** Restructure into separate library with parts
- **[IMPROVEMENT]** Cleaned code base
- **[IMPROVEMENT]** Refactor(utils): make functions public and remove main test
- **[IMPROVEMENT]** Chore(dependencies): update intl and geoxml versions

# 0.4.5

- **[Fix]** fix formatting and indentation in multiple files

# 0.4.4

- **[Fix]** Refactor(geo_series): rename snake_case methods to camelCase for consistency

# 0.4.3

- **[Fix]** Formatted files.
- **[IMPROVEMENT]** Reorganize test files into dataframe_series directory
- **[IMPROVEMENT]** Rename geoJSONToGEOS to GeoJSONToGEOS for consistency fix(geo_series)
- **[IMPROVEMENT]** Specify Series return type for isEmpty getter chore(dartframe)
- **[IMPROVEMENT]** Add dart:ffi import and include src/utils/lists.dart fix(series)
- **[IMPROVEMENT]** Change default errors parameter to 'ignore' in toNumeric refactor(string_accessor)
- **[IMPROVEMENT]** Improve split pattern handling with n parameter

# 0.4.2

- **[Fix]** Formatted files.

# 0.4.1

- **[Fix]** Fixed readme.

# 0.4.0

- **[FEATURE]** Added main library file lib/dartframe.dart exporting library parts and initializing fileIO.
- **[FEATURE]** Implemented DataFrameILocAccessor and DataFrameLocAccessor in lib/src/dart_frame/accessors.dart for integer and label-based data selection in DataFrames.
- **[FEATURE]** Implemented core DataFrame class in lib/src/dart_frame/dart_frame.dart with constructors, data cleaning, accessors, and string representation.
- **[FEATURE]** Added extensive DataFrame manipulation functions in lib/src/dart_frame/functions.dart (selection, filtering, sorting, stats, transformations, I/O, grouping).
- **[FEATURE]** Implemented DataFrame operator overloads ([], []=) in lib/src/dart_frame/operations.dart.
- **[FEATURE]** Added file I/O abstraction (FileIOBase) with platform-specific implementations in lib/src/file_helper/.
- **[FEATURE]** Implemented core Series class in lib/src/series/ for 1D arrays, with constructors, operators, statistical functions, string accessor, and date/time conversions.
- **[DOCS]** Added markdown documentation for DataFrame, GeoDataFrame, GeoSeries, and Series classes in docs/.
- **[DOCS]** Added example/example.dart demonstrating DataFrame and Series usage.
- **[DOCS]** Added example/geodataframe_example.dart demonstrating GeoDataFrame usage.
- **[DOCS]** Added example/geoseries.dart demonstrating GeoSeries usage.
- **[MISC]** Added output.geojson example output file.
- **[TEST]** Added a suite of unit tests in test/ covering DataFrame and Series functionalities.
- **[DOCS]** Added bin/dartframe.dart as a simple executable example.

# 0.3.4

- **[Fixed]** Doc Strings.
- **[IMPROVEMENT]** Improved dart format.

# 0.3.3

- **[Fixed]** Doc Strings.

# 0.3.2

- **[IMPROVEMENT]** Migrated to WASM.

# 0.3.1

- **[Fix]** Fixed readme.

# 0.3.0

- **[Fix]** Fixed readme.
- **[FEATURE]** Added more properties
- **[FIX]** Fixed DataFrame constructor to create modifiable column lists, allowing column addition after initialization
- **[FIX]** Updated Series toString() method to properly display custom indices
- **[FEATURE]** Added GeoSeries class for spatial data analysis
- **[FEATURE]** Added GeoSeries.fromXY() factory constructor to create point geometries from x, y coordinates
- **[FEATURE]** Added GeoSeries.fromWKT() factory constructor to create geometries from WKT strings
- **[FEATURE]** Added GeoSeries.fromFeatureCollection() factory constructor to create geometries from GeoJSON
- **[FEATURE]** Added spatial analysis methods to GeoSeries:
  - getCoordinates() - extracts coordinates as a DataFrame
  - countCoordinates - counts coordinate pairs in each geometry
  - countGeometries - counts geometries in multi-part geometries
  - countInteriorRings - counts interior rings in polygonal geometries
  - isClosed - checks if LineStrings are closed
  - isEmpty - checks if geometries are empty
  - isRing - checks if features are rings
  - isValid - validates geometry structures
  - hasZ - checks for 3D coordinates
  - bounds - gets bounding boxes for geometries
  - totalBounds - gets overall bounds of all geometries
  - centroid - calculates centroids of geometries
  - type - gets geometry types
  - area - calculates areas of polygonal geometries
  - lengths - calculates lengths of linear geometries
  - isCCW - checks if rings are counterclockwise
  - contains - checks spatial containment relationships
- **[IMPROVEMENT]** Enhanced Series class to support custom indices similar to DataFrame
- **[IMPROVEMENT]** Renamed DataFrame's rowHeader to index for consistency with pandas API
- **[IMPROVEMENT]** Updated DataFrame constructor to accept index parameter

# 0.2.2

- **[Fix]** Fixed readme.
- **[FEATURE]** Added topics to the package/library

# 0.2.1

- **[Fix]** Fixed readme.

# 0.2.0

- **[FEATURE]** Added `isEmpty` and `isNotEmpty` properties to check if DataFrame has rows
- **[FEATURE]** Added `copy()` method to create deep copies of DataFrames
- **[FEATURE]** Added dimension properties: `rowCount`, `columnCount`, and `shape`
- **[FEATURE]** Added `dtypes` property to get column data types
- **[FEATURE]** Added `hasColumn()` method to check for column existence
- **[FEATURE]** Added `unique()` method to get DataFrame with only unique rows
- **[FEATURE]** Added `unique()` method to Series to get unique values
- **[FEATURE]** Added `resetIndex()` method for reindexing after filtering
- **[FEATURE]** Added conversion methods: `toListOfMaps()` and `toMap()`
- **[FEATURE]** Added `sample()` method for randomly sampling rows
- **[FEATURE]** Added `applyToColumn()` method for applying functions to column elements
- **[FEATURE]** Added `applyToRows()` method for applying functions to each row
- **[FEATURE]** Added `corr()` method for computing correlation coefficients
- **[FEATURE]** Added `bin()` method for creating bins from continuous data
- **[FEATURE]** Added `toCsv()` method for converting DataFrame to CSV string
- **[FEATURE]** Added `pivot()` method for creating pivot tables
- **[FEATURE]** Added `melt()` method for reshaping data from wide to long format
- **[FEATURE]** Added `join()` method for combining DataFrames
- **[IMPROVEMENT]** Enhanced `fillna()` method with strategies (mean, median, mode, forward, backward)
- **[FEATURE]** Added `dropna()` method to remove rows or columns with missing values
- **[IMPROVEMENT]** Improved `replace()` method with regex support and column targeting
- **[FEATURE]** Added `replaceInPlace()` method for in-place value replacement
- **[FEATURE]** Added `astype()` method to convert column data types
- **[FEATURE]** Added `round()` method to round numeric values to specified precision
- **[FEATURE]** Added `rolling()` method for computing rolling window calculations
- **[FEATURE]** Added `cumulative()` method for cumulative calculations (sum, product, min, max)
- **[FEATURE]** Added `quantile()` method to compute quantiles over a column
- **[FEATURE]** Added `rank()` method to compute numerical rank along a column
- **[FEATURE]** Added `abs()` method to Series for calculating absolute values
- **[FEATURE]** Added `copy()` method to Series for creating copies
- **[FEATURE]** Added `cummax()` method to Series for cumulative maximum calculations
- **[FEATURE]** Added `cummin()` method to Series for cumulative minimum calculations
- **[FEATURE]** Added `cumprod()` method to Series for cumulative product calculations
- **[IMPROVEMENT]** Enhanced `cumsum()` method in Series with skipna parameter
- **[FEATURE]** Added GeoDataFrame class for handling geospatial data
- **[Fix]** Fixed the ability to modify individual elements in DataFrame using `df['column'][index] = value` syntax
- **[FIX]** Improved row header display in `toString()` method to properly handle headers of varying lengths

# 0.1.3

- **[IMPROVEMENT]** Fixed Readme not showing the right status
- **[FEATURE]** Added unit tests
- **[FEATURE]** Added row header names/index

# 0.1.2

- Fixed description to match dart packaging

# 0.1.1

- Fixed description.

# 0.1.0

- Initial version.
