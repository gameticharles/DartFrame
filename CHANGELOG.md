# 0.8.9

- **[MAJOR FEATURE]** MATLAB File Format Support - Pure Dart Implementation

  - **NEW**: `MatReader` class for reading MATLAB (.mat) files (v5 and v7.3 formats)
    - Support for MAT v5 format (uncompressed and compressed)
    - Support for MAT v7.3 format (HDF5-based) with full group hierarchy
    - Automatic format detection and version handling
    - Cross-platform compatibility (Windows, macOS, Linux, Web, iOS, Android)
  - **NEW**: `MatWriter` class for writing MATLAB (.mat) files (v7.3 format)
    - Full HDF5-based MAT v7.3 writer implementation
    - Support for nested group structures
    - MATLAB attribute conventions (`MATLAB_class`, `H5PATH`)
    - Automatic type conversion to MATLAB-compatible formats
  - **NEW**: Comprehensive MAT file data type support
    - Numeric arrays (double, single, int8, uint8, int16, uint16, int32, uint32, int64, uint64)
    - Character arrays and strings
    - Cell arrays and structures
    - Sparse matrices (COO format)
    - Complex numbers
    - Logical/boolean arrays
    - Nested structures and cell arrays
  - **NEW**: MATLAB interoperability features
    - `MatlabObject` class for representing MATLAB structs
    - `SparseMatrix` class for sparse matrix representation
    - `MatlabConventions` for MATLAB attribute handling
    - `ReferenceResolver` for object reference resolution in MAT files
  - **NEW**: Example files demonstrating MAT file operations
    - `example/mat_reader_example.dart` - Reading MAT files
    - `example/nested_groups_demo.dart` - Working with nested structures
    - `example/test_mat_roundtrip.dart` - Round-trip read/write testing
  - **ARCHITECTURE**: Modular implementation with separate readers/writers
    - `MatV5Reader` for legacy MAT v5 format
    - `MatV73Reader` for HDF5-based v7.3 format
    - `MatV73Writer` for writing v7.3 files
    - Integration with existing HDF5 infrastructure
  - **COMPATIBILITY**: Full Python/MATLAB/R interoperability for MAT files

- **[MAJOR FEATURE]** NDArray Enhancements - Advanced Array Operations

  - **NEW**: Comprehensive NDArray documentation with examples
    - Added detailed docstrings to all NDArray methods
    - Included practical examples for every operation
    - Covered all use cases for array manipulation
  - **NEW**: Enhanced lazy operations (`lazy_operations.dart`)
    - Advanced lazy evaluation and computation graph
    - Memory-efficient operations for large arrays
    - Deferred computation with optimization
    - Operation fusion for better performance
  - **NEW**: Enhanced filtering operations (`filtering.dart`)
    - Advanced filtering and selection methods
    - Conditional filtering with predicates
    - Index-based and value-based filtering
    - Multi-dimensional filtering support
  - **NEW**: Enhanced array operations (`operations.dart`)
    - Extended mathematical and statistical operations
    - Broadcasting support for operations
    - Element-wise operations
    - Reduction operations along axes
  - **ENHANCEMENT**: Core NDArray improvements (`ndarray.dart`)
    - Better memory management
    - Optimized indexing and slicing
    - Enhanced shape manipulation
    - Improved type handling

- **[FEATURE]** DataFrame Enhancements

  - **ENHANCEMENT**: Improved metadata formatting
    - Streamlined metadata handling
    - Better integration with HDF5 attributes
    - Removed redundant formatting code (152 lines removed)
  - **ENHANCEMENT**: Enhanced DataFrame core operations
    - Optimized data manipulation (219 lines changed)
    - Better null handling
    - Improved performance for large datasets
    - Enhanced type inference

- **[FEATURE]** Series Enhancements

  - **ENHANCEMENT**: Streamlined Series operations (`enhancements.dart`)
    - Removed duplicate functionality (78 lines removed)
    - Consolidated operations into core Series class
    - Better code organization
  - **ENHANCEMENT**: Enhanced Series core (`series.dart`)
    - Improved data handling (109 lines changed)
    - Better null value processing
    - Enhanced type conversion
    - Optimized memory usage

- **[FEATURE]** HDF5 and File I/O Improvements

  - **ENHANCEMENT**: Enhanced `Hdf5FileBuilder` for MAT file support
    - Better group hierarchy handling
    - Improved attribute writing
    - Enhanced datatype conversion
    - Optimized for MATLAB conventions
  - **ENHANCEMENT**: Improved HDF5 universal reader example
    - Better error handling
    - Enhanced output formatting
    - Demonstration of nested structures
  - **NEW**: Enhanced `FileReader` class (`readers.dart`)
    - Added MAT file reading capabilities
    - Unified interface for multiple file formats
    - Better format detection
    - Improved error messages

- **[FEATURE]** Package Configuration

  - **NEW**: Exported MAT file classes in main library export
    - `MatReader` and `MatWriter` now publicly accessible
    - Streamlined import for MAT file operations
    - Single import for all file format operations
  - **ENHANCEMENT**: Improved package organization
    - Better separation of concerns
    - Modular architecture for file format support
    - Clean public API

- **[TESTING]** Comprehensive Test Coverage

  - **NEW**: MAT file reader tests (`test/mat_reader_test.dart`)
    - Round-trip testing (read/write/read)
    - Format compatibility tests
    - Data integrity validation
  - **NEW**: Compile-time tests (`test/compile_test.dart`)
    - Type safety validation
    - API consistency checks
  - **NEW**: Test data generation (`test/generate_test_files.m`)
    - MATLAB script for generating test files
    - Various data types and structures
    - Edge case coverage

- **[ENHANCEMENT]** Code Quality and Maintenance
  - **REFACTOR**: Removed redundant code across multiple files
    - 397 lines removed
    - 1312 lines added
    - Net improvement in functionality with better organization
  - **REFACTOR**: Improved code organization
    - Better separation of file format handlers
    - Cleaner extension organization
    - More maintainable codebase
  - **ENHANCEMENT**: Better documentation
    - Comprehensive examples for all NDArray operations
    - Improved docstrings across the board
    - Better inline comments

# 0.8.8

- **[FIX]** Fixed error with `pow` function being exported
- **[ENHANCEMENT]** updated the package description

# 0.8.7

- **[MAJOR FEATURE]** High-Priority DataFrame and Series Methods Implementation (64 new methods total)

  **Data Inspection Methods:**

  - **NEW**: `DataFrame.info()` - Print concise summary with dtypes, non-null counts, and memory usage
  - **NEW**: `DataFrame.describeDataFrame()` - Generate descriptive statistics (pandas-style DataFrame output)
  - **NEW**: `DataFrame.memoryUsageDetailed()` - Return memory usage of each column in bytes
  - **NEW**: `DataFrame.selectDtypes()` - Select columns based on their data type
  - **NEW**: `Series.describeSeries()` - Generate descriptive statistics (pandas-style Series output)
  - **NEW**: `Series.info()` - Print concise summary of Series
  - **NEW**: `Series.memoryUsage()` - Return memory usage in bytes
  - **NEW**: `Series.hasnans` - Property to check if Series contains any NaN values
  - **NEW**: `Series.firstValidIndex()` - Return index of first non-NA value
  - **NEW**: `Series.lastValidIndex()` - Return index of last non-NA value

  **Data Alignment Methods:**

  - **NEW**: `DataFrame.reindex()` - Conform DataFrame to new index with optional filling logic
  - **NEW**: `DataFrame.align()` - Align two DataFrames on their axes with specified join method
  - **NEW**: `DataFrame.setAxis()` - Set the name of the axis for the index or columns
  - **NEW**: `Series.reindex()` - Conform Series to new index with optional filling logic
  - **NEW**: `Series.align()` - Align two Series with specified join method
  - **NEW**: `Series.renameAxis()` - Rename the index of the Series

  **Conditional Operations:**

  - **NEW**: `DataFrame.where()` - Replace values where condition is False
  - **NEW**: `DataFrame.mask()` - Replace values where condition is True (inverse of where)
  - **NEW**: `DataFrame.assign()` - Assign new columns to DataFrame (functional style)
  - **NEW**: `DataFrame.insert()` - Insert column at specific position
  - **NEW**: `DataFrame.pop()` - Return item and drop from DataFrame
  - **NEW**: `Series.where()` - Replace values where condition is False
  - **NEW**: `Series.mask()` - Replace values where condition is True
  - **NEW**: `Series.between()` - Return boolean Series for values between bounds
  - **NEW**: `Series.update()` - Update values from another Series
  - **NEW**: `Series.combine()` - Combine with another Series using a function
  - **NEW**: `Series.combineFirst()` - Update null elements with value from another Series

  **Comparison Operations:**

  - **NEW**: `DataFrame.equals()` - Test whether two DataFrames contain the same elements
  - **NEW**: `DataFrame.compare()` - Compare to another DataFrame and show differences
  - **NEW**: `DataFrame.eq()` - Element-wise equality comparison
  - **NEW**: `DataFrame.ne()` - Element-wise not-equal comparison
  - **NEW**: `DataFrame.lt()` - Element-wise less-than comparison
  - **NEW**: `DataFrame.gt()` - Element-wise greater-than comparison
  - **NEW**: `DataFrame.le()` - Element-wise less-than-or-equal comparison
  - **NEW**: `DataFrame.ge()` - Element-wise greater-than-or-equal comparison
  - **NEW**: `Series.equals()` - Test whether two Series contain the same elements
  - **NEW**: `Series.compare()` - Compare to another Series and show differences

  **Iteration Methods:**

  - **NEW**: `DataFrame.iterrows()` - Iterate over DataFrame rows as (index, Series) pairs
  - **NEW**: `DataFrame.itertuples()` - Iterate over DataFrame rows as named tuples
  - **NEW**: `DataFrame.items()` - Iterate over (column name, Series) pairs
  - **NEW**: `DataFrame.keys()` - Get column names
  - **NEW**: `DataFrame.values` - Return list representation of DataFrame
  - **NEW**: `Series.items()` - Iterate over (index, value) pairs
  - **NEW**: `Series.keys()` - Get the index
  - **NEW**: `Series.values` - Return array representation
  - **NEW**: `Series.iterValues()` - Iterate over values
  - **NEW**: `Series.iterIndex()` - Iterate over indices

  **Missing Data Analysis:**

  - **NEW**: `DataFrame.isnaCounts()` - Count missing values in each column
  - **NEW**: `DataFrame.isnaPercentage()` - Get percentage of missing values per column
  - **NEW**: `DataFrame.hasna()` - Check if any value is missing in each column

  **Architecture:**

  - Created 9 new extension files for organized functionality
  - All methods follow pandas conventions and naming
  - Comprehensive documentation with examples for each method
  - Two demo files showcasing all 41 new methods

  **Data Inspection Enhancements (NEW):**

  - **NEW**: `DataFrame.dtypesSeries` - Return data types as Series
  - **NEW**: `DataFrame.inferObjects()` - Infer better dtypes for object columns
  - **NEW**: `DataFrame.convertDtypes()` - Convert columns to best possible dtypes

  **Data Alignment Enhancements (NEW):**

  - **NEW**: `DataFrame.reindexLike()` - Match indices to another DataFrame
  - **NEW**: `Series.reindexLike()` - Match indices to another Series

  **Missing Data Handling Enhancements (NEW):**

  - **NEW**: `DataFrame.dropnaEnhanced()` - Enhanced dropna with thresh and subset parameters
  - **NEW**: `DataFrame.fillnaEnhanced()` - Enhanced fillna with DataFrame-to-DataFrame filling

  **Sorting Enhancements (NEW):**

  - **NEW**: `DataFrame.sortValuesEnhanced()` - Enhanced sort with key, kind, ignoreIndex parameters
  - **NEW**: `DataFrame.sortIndexEnhanced()` - Enhanced index sort with key, level, sortRemaining parameters

  **Aggregation Enhancements (NEW):**

  - **NEW**: `DataFrame.aggEnhanced()` - Different functions per column, multiple functions
  - **NEW**: `DataFrame.prod()` - Product of values
  - **NEW**: `DataFrame.sem()` - Standard error of mean
  - **NEW**: `DataFrame.mad()` - Mean absolute deviation
  - **NEW**: `DataFrame.nunique()` - Count unique values per column
  - **NEW**: `DataFrame.valueCountsDataFrame()` - Count unique rows

  **Architecture:**

  - Created 13 new extension files for organized functionality
  - All methods follow pandas conventions and naming
  - Comprehensive documentation with examples for each method
  - Four demo files showcasing all 64 new methods

  **Coverage Improvement:**

  - DataFrame: ~46% → ~65% pandas compatibility (+19%)
  - Series: ~53% → ~67% pandas compatibility (+14%)

# 0.8.6

- **[MAJOR FEATURE]** DartData Interface Implementation for DataFrame and Series
  - **NEW**: DataFrame now implements `DartData` interface for unified dimensional data handling
    - Added `ndim` property (always 2 for DataFrame)
    - Added `size` property (total elements = rows × columns)
    - Added `attrs` property for HDF5-style metadata attributes
    - Added `dtype` property (returns `dynamic` for heterogeneous data)
    - Added `isHomogeneous` property (always `false` for DataFrame)
    - Added `columnTypes` property returning `Map<String, Type>` with inferred types per column
    - Added `getValue(List<int> indices)` method for multi-dimensional indexing
    - Added `setValue(List<int> indices, dynamic value)` method for multi-dimensional assignment
    - Added `slice(List<dynamic> sliceSpec)` method for unified slicing returning appropriate types (Scalar, Series, or DataFrame)
  - **NEW**: Series now implements `DartData` interface for unified dimensional data handling
    - Added `ndim` property (always 1 for Series)
    - Added `size` property (total elements)
    - Added `shape` property returning `Shape([length])`
    - Added `attrs` property for HDF5-style metadata attributes
    - Added `isHomogeneous` property (checks if all non-null elements have same type)
    - Added `getValue(List<int> indices)` method for indexed access
    - Added `setValue(List<int> indices, dynamic value)` method for indexed assignment
    - Added `slice(List<dynamic> sliceSpec)` method for unified slicing returning Scalar or Series
    - Added `isEmpty` and `isNotEmpty` properties
  - **ENHANCEMENT**: Enhanced `DartData` interface to support heterogeneous data structures
    - Added `isHomogeneous` property to distinguish homogeneous vs heterogeneous structures
    - Added `columnTypes` property for detailed type information in heterogeneous structures
    - Enhanced `dtype` documentation to clarify behavior for both homogeneous and heterogeneous types
  - **BREAKING CHANGE**: DataFrame's existing `slice()` method renamed to `sliceRange()`
    - Old: `df.slice(start: 0, end: 10, step: 2)`
    - New: `df.sliceRange(start: 0, end: 10, step: 2)`
    - The new `slice()` method implements the DartData interface for unified slicing
    - Migration: Replace all `df.slice(...)` calls with `df.sliceRange(...)`
  - **FEATURE**: Polymorphic data structure handling
    - DataFrame, Series, NDArray, and DataCube can now be used interchangeably via DartData interface
    - Generic algorithms can work with any DartData structure
    - Type-aware operations via `isHomogeneous` and `columnTypes` properties
  - **FEATURE**: Metadata attributes system
    - HDF5-style attributes for all DartData structures
    - JSON-serializable metadata storage
    - Useful for data provenance, documentation, and scientific computing workflows
  - **FEATURE**: Unified slicing across all dimensional types
    - Consistent slicing API using `Slice` specifications
    - Automatic type inference: single element → Scalar, single dimension → Series/NDArray, multiple dimensions → DataFrame/NDArray/DataCube
    - Support for negative indices and step parameters
  - **ARCHITECTURE**: Design decision to support heterogeneous types
    - DataFrame remains heterogeneous (different column types) as core feature
    - NDArray and DataCube remain homogeneous for numeric operations
    - Mirrors successful libraries (pandas for heterogeneous, NumPy for homogeneous)
    - Enables both tabular data (DataFrame) and tensor operations (NDArray/DataCube) in unified framework
  - **TESTING**: Comprehensive test coverage
    - 60+ tests covering all new functionality
    - Integration tests for polymorphic usage
    - Type inference and heterogeneity detection tests
    - Slicing operations returning correct types
    - Metadata attributes functionality
  - **EXAMPLES**: New example demonstrating polymorphic capabilities
    - `example/dart_data_polymorphism_example.dart` - Shows unified interface usage across all dimensional types
  - **DOCUMENTATION**: Complete implementation documentation
    - `DARTDATA_IMPLEMENTATION.md` - Detailed implementation guide with usage examples and migration path
  - **COMPATIBILITY**: Backward compatible except for `slice()` method rename
    - All existing DataFrame and Series functionality preserved
    - Clear migration path for `slice()` → `sliceRange()`
    - No changes to existing NDArray or DataCube implementations
- **[MAJOR FEATURE]** HDF5 File Support - Advanced Features and Web Compatibility

  - **NEW**: Full web browser support for reading HDF5 files via `Hdf5File.open()` which now accepts `Uint8List` and HTML `InputElement`s in addition to file paths.
  - **NEW**: Support for Header Continuation Blocks, allowing the reader to correctly parse object headers that span multiple locations in the file.
  - **NEW**: Link Resolution - `Hdf5File` can now navigate and resolve:
    - **Soft Links:** Symbolic links to other objects within the same file.
    - **External Links:** Links to datasets and groups in other HDF5 files.
    - **Circular Link Detection:** Prevents infinite loops when resolving links.
  - **NEW**: Added `Hdf5File.listRecursive()`, `getStructure()`, and `printTree()` methods for comprehensive, user-friendly inspection of the entire file hierarchy, including attributes and metadata.
  - **NEW**: Added `Hdf5File.getSummaryStats()` for a statistical overview of file contents (dataset counts, types, compression, etc.).
  - **NEW**: Implemented `Hdf5File.resolveObjectReference()` and `resolveRegionReference()` to handle HDF5's reference datatypes.
  - **ENHANCEMENT**: `Hdf5File.dataset()` and `Hdf5File.group()` are now more robust, correctly handling link navigation.
  - **ENHANCEMENT**: Added `MetadataCache` to `Hdf5File` to cache superblocks, groups, and other metadata, improving performance when accessing the same objects multiple times.

- **[FEATURE]** HDF5 Datatype and Attribute Enhancements

  - **NEW**: Support for additional HDF5 datatypes:
    - **Enum Types:** Reads enumerated types, including member names and values.
    - **Array Types:** Parses array datatypes and their dimensions.
    - **Opaque Types:** Handles opaque data with optional tags.
    - **Reference Types:** Correctly identifies object and region references.
  - **NEW**: Support for Variable-Length (vlen) strings stored in `LocalHeap`. Attributes and datasets with vlen strings can now be read correctly.
  - **FIX**: `Hdf5Attribute.read()` now gracefully handles and skips attributes with unsupported datatypes instead of throwing an error, improving compatibility with diverse HDF5 files.
  - **ARCHITECTURE**: `Hdf5Datatype.read()` refactored to recursively parse complex and nested types like compounds, arrays, and enums.

- **[FEATURE]** HDF5 Data Layout and Storage Support

  - **ENHANCEMENT**: `ObjectHeader` message parsing is more robust, correctly handling different message versions and alignments.
  - **ENHANCEMENT**: `DataLayout` parsing now supports more versions and variations, including:
    - Version 3, 2, and 1 layouts for `Contiguous`, `Chunked`, and `Compact` storage.
    - Special cases for MATLAB-generated files (layout class 3).
    - `Single Chunk` layout (version 2 and 4).
  - **FIX**: Correctly calculates chunk dimensions by removing the element size from the dimension list in version 1 and 3 chunked layouts.

- **[FEATURE]** HDF5 Writer-Side Implementation

  - **NEW**: `LocalHeapWriter` for creating and managing local heaps used for object names in groups.
  - **NEW**: `GlobalHeapWriter` for creating global heap collections to store variable-length data.
  - **NEW**: `Hdf5Attribute.write()` and `Hdf5Attribute.scalar()` for creating and writing attribute messages.
  - **NEW**: `ObjectHeader.write()` for constructing and writing object headers with various messages.
  - **NEW**: `Superblock.write()` and `Superblock.create()` for generating version 0 superblocks for new HDF5 files.
  - **ARCHITECTURE**: Foundational writer components (`ByteWriter`, `Hdf5Datatype.write()`, etc.) have been added, paving the way for full HDF5 file writing capabilities.

- **[FEATURE]** DataFrame I/O Enhancements

  - **NEW**: `DataFrame.read()` static method, a pandas-like universal reader that uses `SmartLoader` to automatically detect and load data from various URI schemes (file, http, etc.).
  - **NEW**: `DataFrame.inspect()` static method to get metadata from a data source without loading the entire file.
  - **ENHANCEMENT**: `DataFrame.fromCSV()` and `DataFrame.fromJson()` now use the new `FileIO` and `FileReader` backend, supporting both file paths and string content seamlessly and enabling web compatibility.
  - **BREAKING CHANGE**: In `DataFrame.fromCSV()` and `DataFrame.fromJson()`, the `fieldDelimiter` parameter in `fromCSV` was renamed to `delimiter` for consistency.

- **[FIX]** General Fixes & Refinements
  - **FIX**: `LocalHeap` reader now correctly handles both `HEAP` (version 0) and `GCOL` (version 1) signatures and determines the data segment address accordingly.
  - **FIX**: `Superblock` reader now correctly detects the HDF5 signature at various file offsets (e.g., 0 for standard, 512 for MATLAB) to properly locate the start of HDF5 data.
  - **FIX**: Resolved an issue in `DataFrame.[]=` (column assignment) where creating a new column on an empty DataFrame with a `Series` that had a non-default index would not correctly adopt the new index.

# 0.8.5

- **[FIX]** Removed MySQL since it caused plaform issues

# 0.8.4

- **[MAJOR FEATURE]** Window Functions - Exponentially Weighted Moving (EWM) Operations

  - **NEW**: `DataFrame.ewm()` - Create exponentially weighted window with span, alpha, halflife, or com parameters
  - **NEW**: `ewm().mean()` - Exponentially weighted moving average for smoothing time series data
  - **NEW**: `ewm().std()` - Exponentially weighted moving standard deviation for volatility analysis
  - **NEW**: `ewm().var_()` - Exponentially weighted moving variance for risk measurement
  - **NEW**: `ewm().corr()` - Exponentially weighted moving correlation (pairwise and with other DataFrame)
  - **NEW**: `ewm().cov()` - Exponentially weighted moving covariance (pairwise and with other DataFrame)
  - **ENHANCEMENT**: Support for adjustWeights and ignoreNA parameters for flexible weighting schemes
  - **COMPATIBILITY**: Pandas-like API for familiar exponential smoothing workflows

- **[MAJOR FEATURE]** Window Functions - Expanding Window Operations

  - **NEW**: `DataFrame.expanding()` - Create expanding window with minPeriods parameter
  - **NEW**: `expanding().mean()` - Expanding mean (cumulative average) for running statistics
  - **NEW**: `expanding().sum()` - Expanding sum (cumulative sum) for accumulation analysis
  - **NEW**: `expanding().std()` - Expanding standard deviation for growing window volatility
  - **NEW**: `expanding().min()` - Expanding minimum (running minimum) for tracking lowest values
  - **NEW**: `expanding().max()` - Expanding maximum (running maximum) for tracking highest values
  - **ENHANCEMENT**: All expanding operations support minPeriods parameter for minimum observation requirements

- **[FEATURE]** DataFrame Statistical Methods - Data Manipulation Operations

  - **NEW**: `DataFrame.clip()` - Trim values at input thresholds with lower/upper bounds for outlier control
  - **NEW**: `DataFrame.abs()` - Compute absolute values for all numeric columns
  - **NEW**: `DataFrame.pctChange()` - Calculate percentage change between consecutive rows for growth analysis
  - **NEW**: `DataFrame.diff()` - Calculate first discrete difference between consecutive rows
  - **NEW**: `DataFrame.idxmax()` - Return index labels of maximum values for each column
  - **NEW**: `DataFrame.idxmin()` - Return index labels of minimum values for each column
  - **NEW**: `DataFrame.qcut()` - Quantile-based discretization for specified columns into equal-sized bins
  - **ENHANCEMENT**: Enhanced `DataFrame.round()` with parameter validation and error handling

- **[FEATURE]** Series Statistical Methods

  - **NEW**: `Series.clip()` - Trim values at input thresholds with lower/upper bounds
  - **FIX**: Resolved duplicate `abs()` method causing ambiguity errors in Series extensions
  - **FIX**: Fixed Series extension methods not working on `Series<dynamic>` by proper type handling

- **[MAJOR FEATURE]** GroupBy Enhancements - Advanced Aggregation and Operations

  - **NEW**: `DataFrame.groupBy2()` - Create GroupBy object for advanced operations with chainable API
  - **NEW**: `GroupBy.transform()` - Transform values within groups while maintaining original DataFrame shape
  - **NEW**: `GroupBy.filter()` - Filter entire groups based on conditions for group-level selection
  - **NEW**: `GroupBy.pipe()` - Apply chainable functions for method chaining and custom operations
  - **NEW**: `GroupBy.nth()` - Get nth row from each group (supports negative indexing)
  - **NEW**: `GroupBy.head()` / `GroupBy.tail()` - Get first/last n rows from each group
  - **NEW**: Cumulative Operations within Groups:
    - `GroupBy.cumsum()` - Cumulative sum within each group for running totals
    - `GroupBy.cumprod()` - Cumulative product within each group
    - `GroupBy.cummax()` - Cumulative maximum within each group
    - `GroupBy.cummin()` - Cumulative minimum within each group
  - **NEW**: Flexible Aggregation with Enhanced `GroupBy.agg()`:
    - Single function mode: `agg('sum')` for simple aggregations
    - Multiple functions mode: `agg(['sum', 'mean', 'count'])` for multiple statistics
    - Column-specific mode: `agg({'col1': 'sum', 'col2': ['mean', 'max']})` for targeted aggregations
    - Named aggregations mode: `agg({'total': NamedAgg('amount', 'sum')})` for custom column names
  - **NEW**: `NamedAgg` class for custom aggregation column names and multiple function support
  - **NEW**: Convenience aggregation methods: `sum()`, `mean()`, `count()`, `min()`, `max()`, `std()`, `var_()`, `first()`, `last()`
  - **NEW**: Utility methods: `ngroups` property, `size()` method, `groups` property for group inspection
  - **FIX**: Fixed list equality issue in `groupBy()` when using multiple columns - now uses string representation for proper map key equality
  - **ARCHITECTURE**: Lazy evaluation in GroupBy operations for memory efficiency

- **[FEATURE]** Advanced Slicing Methods (Previously Implemented)

  - **NEW**: `DataFrame.slice()` - Slice with step parameter (forward and reverse slicing)
  - **NEW**: `DataFrame.sliceByLabel()` - Label-based range slicing (inclusive endpoints)
  - **NEW**: `DataFrame.sliceByPosition()` - Combined position slicing with step parameter
  - **NEW**: `DataFrame.sliceByLabelWithStep()` - Label + step combination for flexible slicing
  - **NEW**: `DataFrame.everyNthRow()` / `DataFrame.everyNthColumn()` - Convenience sampling methods
  - **NEW**: `DataFrame.reverseRows()` / `DataFrame.reverseColumns()` - Simple reversal operations

- **[ENHANCEMENT]** Method Chaining Support

  - All new operations return DataFrames/Series for seamless method chaining
  - Example: `df.clip(lower: 0, upper: 100).abs().round(2)` for fluent API usage
  - Consistent API design across all statistical and manipulation methods

- **[ENHANCEMENT]** Null Value Handling

  - Consistent null value handling across all new operations
  - Null values are preserved appropriately in all transformations
  - Graceful handling of edge cases (empty DataFrames, single rows, mixed types)

- **[ENHANCEMENT]** Performance Optimizations

  - Efficient O(n) and O(n\*m) implementations for all new methods
  - Lazy evaluation in GroupBy operations for reduced memory footprint
  - Memory-efficient implementations suitable for large datasets (1000+ rows tested)
  - Performance targets: < 1 second for typical operations

- **[ENHANCEMENT]** Error Handling

  - Comprehensive parameter validation with descriptive error messages
  - Proper type checking and conversion for mixed data types
  - Clear error messages for invalid operations and edge cases

- **[MAJOR FEATURE]** Data Type System - Nullable Types and Type Management

  - **NEW**: Comprehensive DType system with nullable integer, boolean, and string types
    - `Int8DType`, `Int16DType`, `Int32DType`, `Int64DType` - Nullable integer types with range validation (-128 to 127, -32768 to 32767, etc.)
    - `BooleanDType` - Nullable boolean with flexible string parsing ('true', 'yes', '1', 'false', 'no', '0')
    - `StringDType` - Nullable string with optional max length constraints
    - `Float32DType`, `Float64DType` - Nullable float types with NaN handling
    - `DateTimeDType` - Nullable datetime with string and timestamp parsing
    - `ObjectDType` - Generic object type for mixed data
  - **NEW**: `DTypeRegistry` - Custom data type registration system
    - `register(name, constructor)` - Register custom types with string names
    - `get(name)` - Retrieve registered types by name
    - Built-in type lookup with fallback to custom types
    - Type validation and management
  - **NEW**: `DTypes` convenience class - Easy type creation
    - `DTypes.int8()`, `DTypes.int16()`, `DTypes.int32()`, `DTypes.int64()` - Integer type constructors
    - `DTypes.float32()`, `DTypes.float64()` - Float type constructors
    - `DTypes.boolean()`, `DTypes.string()`, `DTypes.datetime()` - Other type constructors
    - All types support nullable/non-nullable variants via `nullable` parameter
  - **NEW**: `DataFrame.dtypesDetailed` - Automatic type inference
    - Detects optimal types based on data content and value ranges
    - Chooses smallest integer type that fits the data range (Int8 for [-128, 127], etc.)
    - Handles nullable vs non-nullable type detection
    - Smart string parsing: infers numeric types from parsable strings (e.g., '123' → Int8DType)
  - **NEW**: `DataFrame.astype()` - Enhanced type conversion with categorical support
    - Convert columns to specific DType objects: `df.astype({'col': DTypes.int32()})`
    - Support for Map<String, DType> and Map<String, String> formats
    - Error handling modes: 'raise', 'ignore', 'coerce' for flexible conversion
    - **CATEGORICAL SUPPORT**: `df.astype({'col': 'category'})` delegates to existing categorical system
    - Automatic fallback for categorical and other existing types
    - Full compatibility with existing `astype()` behavior
  - **NEW**: `DataFrame.inferDTypes()` - Automatic type optimization
    - Infer and convert to optimal types automatically
    - Downcast options: 'integer', 'float', 'all' for memory optimization
    - Smart string-to-number inference for data cleaning
    - Reduces memory usage by selecting smallest appropriate types
  - **NEW**: `DataFrame.memoryUsageByDType()` - Memory usage analysis
    - Calculate memory usage per column based on dtype
    - Fixed-size type calculations (Int8=1 byte, Int16=2 bytes, etc.)
    - Variable-size type estimation for strings and objects
    - Returns Map<String, int> of column names to bytes
  - **NEW**: `Series.dtypeInfo` - Series type information
    - Get DType information for Series data
    - Automatic type inference with range-based integer selection
    - Avoids conflict with existing `dtype` property
  - **NEW**: `Series.astype()` - Series type conversion with categorical support
    - Convert Series to specific DType: `s.astype(DTypes.int8())`
    - **CATEGORICAL SUPPORT**: `s.astype('category', categories: [...], ordered: true)`
    - In-place conversion for categorical type (modifies original Series)
    - Returns new Series for other type conversions
    - Support for 'int', 'float', 'string', 'object' string names
    - Error handling: 'raise', 'ignore', 'coerce' modes
    - Full compatibility with existing categorical system
  - **NEW**: `Series.memoryUsageByDType()` - Series memory analysis
    - Calculate memory usage based on inferred dtype
    - Range-based integer type detection for accurate estimates
  - **NEW**: Series public methods for dtype management
    - `toCategorical(categories, ordered)` - Convert to categorical type
    - `setDType(dtype)` - Set dtype string identifier
    - `clearCategorical()` - Clear categorical data
  - **ENHANCEMENT**: Smart Type Inference
    - Parses string content to infer numeric types: `['1', '2', '3']` → Int8DType
    - Range-based integer type selection: values [1,2,3] → Int8, [1000,2000] → Int16
    - Automatic detection of parsable integers and floats in string data
  - **ENHANCEMENT**: Robust Error Handling
    - All numeric and datetime types throw `FormatException` for unparsable strings
    - Proper exception propagation with 'raise' error mode
    - Null coercion with 'coerce' error mode
    - Value preservation with 'ignore' error mode
  - **COMPATIBILITY**: Works alongside existing type system
    - Categorical conversion delegates to existing `_Categorical` implementation
    - No breaking changes to existing DataFrame/Series behavior
    - Extension-based implementation for clean separation of concerns
  - **PERFORMANCE**: Memory-efficient type storage and conversion
    - Optimal type selection reduces memory footprint
    - Efficient conversion algorithms
    - Lazy evaluation where appropriate
  - **VALIDATION**: Comprehensive type validation and range checking
    - Integer range validation (Int8: -128 to 127, Int16: -32768 to 32767, etc.)
    - Type compatibility checks
    - Null handling for nullable types
  - **TESTING**: 52 comprehensive tests (22 dtype + 30 categorical)
    - Full integration testing with DataFrame and Series
    - Categorical compatibility testing
    - Error handling and edge case coverage
    - Memory usage calculation verification

- **[MAJOR FEATURE]** Database Support - SQL Database Integration

  - **NEW**: `DatabaseConnection` abstract interface for database operations
    - `query()` - Execute SQL queries and return DataFrame
    - `execute()` - Execute SQL commands (INSERT, UPDATE, DELETE) and return affected rows
    - `executeBatch()` - Execute multiple SQL commands efficiently
    - `beginTransaction()` - Start database transactions for ACID compliance
    - `close()` - Close database connection
    - `isConnected()` - Check connection status
    - `databaseType` - Get database type identifier
  - **NEW**: `DatabaseTransaction` interface for transaction management
    - `query()` - Execute queries within transaction
    - `execute()` - Execute commands within transaction
    - `commit()` - Commit transaction changes
    - `rollback()` - Rollback transaction on errors
  - **NEW**: `ConnectionPool` class for efficient connection management
    - `getConnection()` - Get connection from pool
    - `releaseConnection()` - Return connection to pool
    - `close()` - Close all pooled connections
    - `activeConnectionCount` - Monitor active connections
    - `availableConnectionCount` - Monitor available connections
    - Configurable max connections (default: 5)
    - Automatic connection lifecycle management
  - **NEW**: Database-specific implementations
    - `SQLiteConnection` - SQLite database support
    - `PostgreSQLConnection` - PostgreSQL database support
    - `MySQLConnection` - MySQL database support
    - Each with transaction support and batch operations
  - **NEW**: `DatabaseReader` utility class
    - `readSqlQuery()` - Read SQL query results into DataFrame (pandas-like read_sql_query)
    - `readSqlTable()` - Read entire SQL table into DataFrame (pandas-like read_sql_table)
    - `createConnection()` - Factory method for creating database connections
    - Support for WHERE clauses, LIMIT, OFFSET, column selection
  - **NEW**: `DataFrame.toSql()` extension method (pandas-like to_sql)
    - Write DataFrame to SQL database tables
    - `ifExists` modes: 'fail', 'replace', 'append' for table handling
    - Automatic table creation with type inference
    - Custom data type mapping via `dtype` parameter
    - Chunked inserts for large datasets (configurable `chunkSize`)
    - Index column support with custom labels
    - Automatic SQL type inference from Dart types
  - **FEATURE**: Parameterized Queries
    - All query methods support `parameters` argument
    - SQL injection prevention through parameter binding
    - Type-safe parameter handling
  - **FEATURE**: Batch Operations
    - `executeBatch()` for bulk inserts/updates
    - Optimized for high-performance bulk operations
    - Reduces database round-trips
  - **FEATURE**: Transaction Support
    - Full ACID compliance with begin/commit/rollback
    - Automatic rollback on errors
    - Nested transaction prevention
    - Transaction state management
  - **ARCHITECTURE**: Production-ready structure
    - Abstract interfaces for easy extension
    - Mock implementations for testing
    - Ready for real database driver integration (sqflite, postgres, mysql1)
    - Separation of concerns with transaction classes
  - **ERROR HANDLING**: Comprehensive exception types
    - `DatabaseConnectionError` - Connection failures
    - `DatabaseQueryError` - Query execution failures
    - `DatabaseTransactionError` - Transaction failures
    - `UnsupportedDatabaseError` - Unsupported database types
  - **EXAMPLES**: Complete example files
    - `example/database_example.dart` - Mock examples with 10 scenarios
    - `example/database_real_example.dart` - Real database examples (SQLite Northwind, PostgreSQL PostGIS)
    - `DATABASE_SETUP.md` - Comprehensive setup guide
  - **COMPATIBILITY**: Pandas-like API for familiar usage patterns

- **[FEATURE]** Export Formats - Multiple Output Formats

  - **NEW**: `toLatex()` - Export DataFrame to LaTeX table format
    - Support for captions, labels, and position specifiers
    - Automatic escaping of special LaTeX characters
    - Longtable environment for multi-page tables
    - Custom column format strings
    - Bold headers and configurable styling
  - **NEW**: `toMarkdown()` - Export DataFrame to Markdown table format
    - GitHub-flavored markdown (pipe format)
    - Grid and simple table formats
    - Column alignment options (left, center, right)
    - Float formatting for numeric precision
    - Maximum column width for truncation
  - **NEW**: `toStringFormatted()` - Enhanced formatted string representation
    - Intelligent truncation for large DataFrames
    - Configurable max rows and columns
    - Float formatting support
    - Shape information footer
    - Pandas-like display with ellipsis
  - **NEW**: `toRecords()` - Convert DataFrame to list of record maps
    - Optional index inclusion
    - Custom index column naming
    - Perfect for JSON serialization
    - Row-by-row iteration support
  - **COMPATIBILITY**: Pandas-like API for familiar export workflows

- **[FEATURE]** Web & API - HTML and XML Support
  - **NEW**: `toHtml()` - Export DataFrame to HTML table format
    - CSS classes and table ID support
    - Notebook styling for Jupyter-like display
    - Configurable borders and alignment
    - Automatic HTML entity escaping
    - Truncation for large DataFrames
    - Dimension display footer
  - **NEW**: `toXml()` - Export DataFrame to XML format
    - Custom root and row element names
    - Attribute and element column modes
    - XML entity escaping
    - Pretty print with indentation
    - Index inclusion control
  - **NEW**: `DataFrame.readHtml()` - Read HTML tables from string
    - Automatic table detection and parsing
    - Header row specification
    - Numeric value parsing
    - HTML entity decoding
    - Multiple table support
  - **NEW**: `DataFrame.readXml()` - Read XML data into DataFrame
    - Custom row element selection
    - Attribute extraction with prefix
    - Numeric value parsing
    - XML entity decoding
    - Flexible column detection
  - **COMPATIBILITY**: Round-trip support for HTML and XML formats

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
