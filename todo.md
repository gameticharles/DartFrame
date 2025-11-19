# DartFrame Development Roadmap

This document outlines missing features compared to pandas and strategies for adding data sources without bloating the library.

## 📊 Implementation Status Summary

Based on comprehensive analysis of DartFrame vs pandas (as of pandas 2.x), this document tracks implementation progress.

### 🔴 High Priority Missing Features

- [x] Window functions (rank, row_number, dense_rank) ✅
- [ ] Visualization/plotting
- [ ] Memory optimization methods
- [ ] Advanced merge/join options

---

## 🔍 Comprehensive Feature Comparison: DartFrame vs Pandas

### DataFrame Methods Analysis

#### ✅ IMPLEMENTED (Core functionality complete)

**Data Access & Selection:**
- iloc, loc, at, iat (position/label-based indexing)
- head(), tail(), sample()
- take(), nlargest(), nsmallest()
- query(), eval() (expression evaluation)
- filter() (filtering operations)

**Data Manipulation:**
- drop(), dropna(), fillna(), ffill(), bfill()
- replace(), rename()
- sort_values(), sort_index()
- reset_index(), set_index()
- transpose()
- explode()

**Aggregation & Statistics:**
- sum(), mean(), median(), mode(), std(), var()
- min(), max(), count()
- quantile(), percentile()
- corr(), cov()
- cumsum(), cummax(), cummin(), cumprod()
- rank(), pct_change(), diff()
- abs(), round(), clip()

**GroupBy Operations:**
- groupby() with agg(), transform(), filter()
- Multiple aggregations per column
- Named aggregations
- nth(), head(), tail() on groups

**Reshaping:**
- pivot(), pivot_table()
- melt(), stack(), unstack()
- merge(), join()
- concat()
- get_dummies()

**Time Series:**
- shift(), lag(), lead(), tshift()
- resample(), asfreq()
- rolling(), expanding(), ewm()
- at_time(), between_time()
- first(), last()

**I/O Operations:**
- CSV: read_csv(), to_csv()
- JSON: read_json(), to_json()
- Excel: read_excel(), to_excel()
- HDF5: read_hdf5()
- HTML: read_html(), to_html()
- XML: read_xml(), to_xml()
- SQL: read_sql(), to_sql()
- Parquet: read_parquet(), to_parquet()
- LaTeX: to_latex()
- Markdown: to_markdown()

**Window Functions:**
- rank(), dense_rank(), row_number()
- percent_rank(), cumulative_distribution()

**Duplicate Handling:**
- duplicated(), drop_duplicates()

**String Operations (Series.str):**
- All major string methods implemented
- Pattern matching, extraction, replacement
- Case conversion, padding, trimming

**Categorical Data:**
- Categorical dtype support
- cat accessor with full functionality

---

## Missing Pandas Features

### 🔴 HIGH PRIORITY - Missing Core DataFrame Methods

#### Data Inspection & Information
- [ ] **info()** - Concise summary of DataFrame (dtypes, non-null counts, memory usage)
- [ ] **describe()** - Generate descriptive statistics (currently partial)
- [ ] **memory_usage()** - Return memory usage of each column
- [ ] **dtypes** - Return data types of columns (currently basic)
- [ ] **select_dtypes()** - Select columns based on dtype
- [ ] **infer_objects()** - Attempt to infer better dtypes for object columns
- [ ] **convert_dtypes()** - Convert columns to best possible dtypes

#### Data Alignment & Reindexing
- [ ] **reindex()** - Conform DataFrame to new index with optional fill method
- [ ] **reindex_like()** - Return object with matching indices to other object
- [ ] **align()** - Align two objects on their axes with specified join method
- [ ] **set_axis()** - Assign desired index to given axis

#### Missing Data Handling (Advanced)
- [ ] **interpolate()** - Fill NaN values using interpolation (Series has it, DataFrame needs it)
- [ ] **dropna()** enhancements:
  - [ ] thresh parameter (minimum non-NA values required)
  - [ ] subset parameter for specific columns
- [ ] **fillna()** enhancements:
  - [ ] method='pad'/'backfill' with limit
  - [ ] DataFrame-to-DataFrame filling
- [ ] **isna()** / **isnull()** - Detect missing values (return DataFrame of booleans)
- [ ] **notna()** / **notnull()** - Detect non-missing values

#### Data Transformation
- [ ] **assign()** - Assign new columns to DataFrame (functional style)
- [ ] **insert()** - Insert column at specific position
- [ ] **pop()** - Return item and drop from frame
- [ ] **where()** - Replace values where condition is False
- [ ] **mask()** - Replace values where condition is True
- [ ] **update()** - Modify in place using non-NA values from another DataFrame
- [ ] **combine()** - Combine with another DataFrame using func
- [ ] **combine_first()** - Update null elements with value from another DataFrame

#### Comparison & Equality
- [ ] **equals()** - Test whether two objects contain the same elements
- [ ] **compare()** - Compare to another DataFrame and show differences
- [ ] **eq()**, **ne()**, **lt()**, **gt()**, **le()**, **ge()** - Comparison operators returning DataFrame

#### Iteration
- [ ] **items()** - Iterate over (column name, Series) pairs
- [ ] **iterrows()** - Iterate over DataFrame rows as (index, Series) pairs
- [ ] **itertuples()** - Iterate over DataFrame rows as named tuples
- [ ] **keys()** - Get the 'info axis' (column names)
- [ ] **values** - Return numpy array representation (or List<List> in Dart)

#### Sorting & Ranking (Enhancements)
- [ ] **sort_values()** enhancements:
  - [ ] key parameter (apply function before sorting)
  - [ ] kind parameter (sorting algorithm)
  - [ ] ignore_index parameter
- [ ] **sort_index()** enhancements:
  - [ ] level parameter for MultiIndex
  - [ ] sort_remaining parameter

#### Aggregation (Advanced)
- [ ] **agg()** / **aggregate()** enhancements:
  - [ ] Different functions per column
  - [ ] Multiple functions returning MultiIndex columns
- [ ] **prod()** / **product()** - Product of values
- [ ] **sem()** - Standard error of mean
- [ ] **mad()** - Mean absolute deviation
- [ ] **nunique()** - Count unique values per column
- [ ] **value_counts()** - Count unique values (for DataFrame, not just Series)

#### Reshaping (Advanced)
- [ ] **squeeze()** - Squeeze 1-dimensional axis objects into scalars
- [ ] **to_numpy()** - Convert to numpy array (or native Dart equivalent)
- [ ] **to_dict()** - Convert to dictionary (various orientations)
- [ ] **to_records()** - Convert to structured array
- [ ] **from_dict()** enhancements (various orientations)
- [ ] **from_records()** - Convert structured array to DataFrame

#### Merging & Joining (Advanced)
- [ ] **merge()** enhancements:
  - [ ] indicator parameter (show merge type)
  - [ ] validate parameter (one-to-one, one-to-many, many-to-one)
  - [ ] suffixes for overlapping columns
- [ ] **merge_ordered()** - Merge with optional filling/interpolation
- [ ] **merge_asof()** enhancements (tolerance, direction parameters)
- [ ] **join()** enhancements:
  - [ ] Multiple DataFrames at once
  - [ ] lsuffix/rsuffix parameters

#### Grouping (Advanced)
- [ ] **groupby()** enhancements:
  - [ ] as_index parameter
  - [ ] group_keys parameter
  - [ ] observed parameter (for categorical)
  - [ ] dropna parameter
- [ ] **rolling()** enhancements:
  - [ ] win_type parameter (window types)
  - [ ] center parameter
  - [ ] closed parameter
- [ ] **expanding()** enhancements
- [ ] **ewm()** enhancements

#### Time Series (Advanced)
- [ ] **tz_localize()** - Localize tz-naive index to tz-aware
- [ ] **tz_convert()** - Convert tz-aware index to another timezone
- [ ] **infer_freq()** - Infer frequency of time series
- [ ] **to_period()** - Convert to PeriodIndex
- [ ] **to_timestamp()** - Convert PeriodIndex to DatetimeIndex

#### Plotting & Visualization
- [ ] **plot()** - DataFrame plotting interface
  - [ ] plot.line()
  - [ ] plot.bar()
  - [ ] plot.barh()
  - [ ] plot.hist()
  - [ ] plot.box()
  - [ ] plot.kde()
  - [ ] plot.area()
  - [ ] plot.scatter()
  - [ ] plot.hexbin()
  - [ ] plot.pie()
- [ ] **hist()** - Draw histogram
- [ ] **boxplot()** - Make box plot

#### Sparse Data
- [ ] **sparse** accessor for sparse data operations
- [ ] **to_sparse()** - Convert to SparseDataFrame
- [ ] **from_sparse()** - Create from sparse data

#### Style & Formatting
- [ ] **style** - Returns Styler object for formatting
- [ ] **to_string()** enhancements (formatters, max_rows, etc.)

#### Metadata & Attributes
- [ ] **attrs** - Dictionary of global attributes
- [ ] **flags** - Get flags for this object
- [ ] **set_flags()** - Return new object with updated flags

---

### 🟡 MEDIUM PRIORITY - Missing Series Methods

#### Data Inspection
- [ ] **describe()** - Generate descriptive statistics
- [ ] **info()** - Print concise summary
- [ ] **memory_usage()** - Return memory usage
- [ ] **hasnans** - Return True if there are any NaNs
- [ ] **dtype** enhancements (better type inference)

#### Data Alignment
- [ ] **reindex()** - Conform Series to new index
- [ ] **reindex_like()** - Match indices to other object
- [ ] **align()** - Align two Series
- [ ] **rename_axis()** - Set name of axis

#### Data Transformation
- [ ] **map()** enhancements (na_action parameter)
- [ ] **replace()** enhancements (regex, method parameters)
- [ ] **update()** - Modify in place using values from another Series
- [ ] **where()** - Replace values where condition is False
- [ ] **mask()** - Replace values where condition is True
- [ ] **combine()** - Combine with another Series using func
- [ ] **combine_first()** - Update null elements with value from another Series
- [ ] **repeat()** - Repeat elements
- [ ] **squeeze()** - Squeeze to scalar if possible

#### Comparison
- [ ] **equals()** - Test equality with another Series
- [ ] **compare()** - Compare and show differences
- [ ] **between()** - Return boolean Series for values between bounds

#### Iteration
- [ ] **items()** - Iterate over (index, value) pairs
- [ ] **keys()** - Return index
- [ ] **values** - Return array of values

#### Sorting & Ranking (Enhancements)
- [ ] **argsort()** - Return integer indices that would sort the Series
- [ ] **searchsorted()** - Find indices where elements should be inserted
- [ ] **sort_values()** enhancements (key parameter)

#### Aggregation (Advanced)
- [ ] **agg()** / **aggregate()** with multiple functions
- [ ] **sem()** - Standard error of mean
- [ ] **mad()** - Mean absolute deviation
- [ ] **describe()** - Descriptive statistics

#### Conversion
- [ ] **to_numpy()** - Convert to array
- [ ] **to_list()** - Convert to list (already has toList())
- [ ] **to_dict()** - Convert to dictionary
- [ ] **to_frame()** - Convert to DataFrame (already has toDataFrame())

#### Datetime Accessor (Series.dt) - Additional Methods
- [ ] **dt.normalize()** - Set time to midnight
- [ ] **dt.strftime()** - Format using strftime
- [ ] **dt.round()** - Round to specified frequency
- [ ] **dt.floor()** - Floor to specified frequency
- [ ] **dt.ceil()** - Ceil to specified frequency
- [ ] **dt.month_name()** - Return month names
- [ ] **dt.day_name()** - Return day names
- [ ] **dt.days_in_month** - Number of days in month
- [ ] **dt.is_month_start** - Indicator for month start
- [ ] **dt.is_month_end** - Indicator for month end
- [ ] **dt.is_quarter_start** - Indicator for quarter start
- [ ] **dt.is_quarter_end** - Indicator for quarter end
- [ ] **dt.is_year_start** - Indicator for year start
- [ ] **dt.is_year_end** - Indicator for year end
- [ ] **dt.is_leap_year** - Indicator for leap year
- [ ] **dt.quarter** - Quarter of the date
- [ ] **dt.tz** - Return timezone
- [ ] **dt.freq** - Return frequency
- [ ] **dt.to_period()** - Convert to Period
- [ ] **dt.to_pydatetime()** - Convert to DateTime objects
- [ ] **dt.tz_localize()** - Localize timezone
- [ ] **dt.tz_convert()** - Convert timezone

#### String Accessor (Series.str) - Additional Methods
- [ ] **str.wrap()** - Wrap strings to specified width
- [ ] **str.get_dummies()** - Return DataFrame of dummy variables
- [ ] **str.translate()** - Map characters through translation table
- [ ] **str.count()** - Count occurrences of pattern
- [ ] **str.removeprefix()** - Remove prefix from string
- [ ] **str.removesuffix()** - Remove suffix from string
- [ ] **str.casefold()** - Convert to casefolded strings
- [ ] **str.swapcase()** - Convert uppercase to lowercase and vice versa
- [ ] **str.normalize()** - Return Unicode normal form
- [ ] **str.partition()** - Split at first occurrence of separator
- [ ] **str.rpartition()** - Split at last occurrence of separator
- [ ] **str.rsplit()** - Split from the end

#### Categorical Accessor (Series.cat) - Additional Methods
- [ ] **cat.codes** - Return Series of codes
- [ ] **cat.categories** - Return categories
- [ ] **cat.ordered** - Whether categories are ordered
- [ ] **cat.remove_unused_categories()** - Remove categories not in data

#### Sparse Accessor (Series.sparse)
- [ ] **sparse.density** - Ratio of non-sparse points to total
- [ ] **sparse.fill_value** - Fill value for sparse data
- [ ] **sparse.from_coo()** - Create from COO sparse matrix
- [ ] **sparse.to_coo()** - Convert to COO sparse matrix
- [ ] **sparse.to_dense()** - Convert to dense Series

#### Statistical Methods (Advanced)
- [ ] **autocorr()** - Compute autocorrelation
- [ ] **cov()** - Compute covariance with another Series
- [ ] **corr()** - Compute correlation with another Series
- [ ] **nlargest()** enhancements (keep='all' option)
- [ ] **nsmallest()** enhancements (keep='all' option)
- [ ] **pct_change()** enhancements (fill_method, limit)
- [ ] **diff()** enhancements (periods parameter)

#### Time Series (Series-specific)
- [ ] **asof()** - Return last non-NaN value before index
- [ ] **first_valid_index()** - Return index of first non-NA value
- [ ] **last_valid_index()** - Return index of last non-NA value

#### Binary Operations
- [ ] **add()**, **sub()**, **mul()**, **div()**, **truediv()**, **floordiv()**, **mod()**, **pow()** with fill_value parameter
- [ ] **radd()**, **rsub()**, **rmul()**, **rdiv()**, etc. (reverse operations)
- [ ] **dot()** - Compute dot product

#### Indexing (Advanced)
- [ ] **xs()** - Return cross-section from Series/DataFrame
- [ ] **get()** - Get item from object for given key
- [ ] **take()** enhancements (axis parameter)

---

### 🟢 LOW PRIORITY - Nice to Have

#### Advanced Statistical Methods
- [ ] **rolling_apply()** with custom functions
- [ ] **expanding_apply()** with custom functions
- [ ] **ewm_apply()** with custom functions

#### Performance & Memory
- [ ] **memory_usage()** with deep parameter
- [ ] **nbytes** - Number of bytes in the underlying data
- [ ] **ndim** - Number of dimensions
- [ ] **size** - Number of elements
- [ ] **empty** - Indicator whether DataFrame is empty

#### Flags & Configuration
- [ ] **flags.allows_duplicate_labels** - Whether to allow duplicate labels
- [ ] **set_flags()** - Set flags on object

#### Metadata
- [ ] **attrs** - Dictionary for storing metadata
- [ ] **copy()** enhancements (deep parameter)

#### Conversion & Export (Additional)
- [ ] **to_clipboard()** - Copy to clipboard (platform-specific)
- [ ] **to_pickle()** - Pickle (serialize) object
- [ ] **read_pickle()** - Load pickled object
- [ ] **to_feather()** - Write to Feather format
- [ ] **read_feather()** - Read from Feather format
- [ ] **to_stata()** - Export to Stata format
- [ ] **read_stata()** - Read Stata file
- [ ] **to_gbq()** - Write to Google BigQuery
- [ ] **read_gbq()** - Read from Google BigQuery

#### Specialized Indexing
- [ ] **at_time()** - Select values at particular time of day (DataFrame needs it)
- [ ] **between_time()** - Select values between times (DataFrame needs it)
- [ ] **truncate()** - Truncate before and after some index value

---

### 1. Core Data Structures & Indexing

#### MultiIndex & Advanced Indexing

- [x] MultiIndex (hierarchical indexing) support ✅
- [x] DatetimeIndex with timezone awareness ✅
- [x] TimedeltaIndex for time differences ✅
- [x] PeriodIndex for time periods ✅
- [x] Index set operations (union, intersection, difference) ✅
- [x] Advanced slicing with step parameter ✅
- [x] Label-based slicing with ranges ✅

#### Index Operations

- [x] Index.get_level_values() ✅
- [x] Index.set_names() ✅
- [x] Index.droplevel() ✅
- [x] Index.swaplevel() ✅
- [x] Index.reorder_levels() ✅

### 2. Statistical & Mathematical Operations

#### Window Functions

- [x] Exponential weighted functions (ewm) ✅
  - [x] ewm().mean() ✅
  - [x] ewm().std() ✅
  - [x] ewm().var() ✅
  - [x] ewm().corr() ✅
  - [x] ewm().cov() ✅
- [x] Expanding window operations ✅
  - [x] expanding().mean() ✅
  - [x] expanding().sum() ✅
  - [x] expanding().std() ✅
  - [x] expanding().min() ✅
  - [x] expanding().max() ✅
- [x] Rolling window operations ✅
  - [x] rolling().mean() ✅
  - [x] rolling().sum() ✅
  - [x] rolling().std() ✅
  - [x] rolling().var() ✅
  - [x] rolling().min() ✅
  - [x] rolling().max() ✅
  - [x] rolling().median() ✅
  - [x] rolling().quantile() ✅
  - [x] rolling().corr() ✅
  - [x] rolling().cov() ✅
  - [x] rolling().skew() ✅
  - [x] rolling().kurt() ✅
  - [x] rolling().apply() ✅

#### Statistical Methods

- [x] rank() - Compute numerical data ranks ✅
- [x] pct_change() - Percentage change between elements ✅
- [x] diff() - First discrete difference ✅
- [x] clip() - Trim values at input thresholds ✅
- [x] qcut() - Quantile-based discretization ✅ (via bin())
- [x] nlargest() / nsmallest() - Return n largest/smallest values ✅
- [x] idxmax() / idxmin() - Return index of max/min values ✅
- [x] abs() - Absolute values ✅
- [x] round() - Round to specified decimals ✅
- [x] cov() with methods (pearson, spearman, kendall) ✅ (pearson, spearman)
- [x] corr() with methods (pearson, spearman, kendall) ✅ (pearson, spearman)

### 3. Data Manipulation

#### GroupBy Enhancements

- [x] groupby().transform() - Transform values within groups ✅
- [x] groupby().filter() - Filter groups based on conditions ✅
- [x] groupby().pipe() - Apply chainable functions ✅
- [x] groupby().nth() - Take nth row from each group ✅
- [x] groupby().head() / tail() - First/last n rows per group ✅
- [x] groupby().cumsum() / cumprod() / cummax() / cummin() ✅
- [x] Multiple aggregation functions per column ✅
- [x] Named aggregations ✅

#### Window Functions (SQL-style)

- [x] rank() with methods (average, min, max, first, dense) ✅
- [x] dense_rank() ✅
- [x] row_number() ✅
- [x] percent_rank() ✅
- [x] cumulative distribution ✅

#### Reshaping Operations

- [x] explode() - Transform list-like elements to rows ✅
- [x] transpose() - Swap rows and columns ✅
- [x] swaplevel() - Swap levels in MultiIndex ✅
- [x] reorder_levels() - Rearrange index levels ✅
- [x] wide_to_long() - Wide panel to long format ✅
- [x] get_dummies() enhancements ✅ (getDummiesEnhanced with dropFirst, dummyNa, dtype options)
- [x] stack() - Pivot columns to rows ✅
- [x] unstack() - Pivot rows to columns ✅
- [x] melt() - Wide to long format ✅
- [x] pivot() - Long to wide format ✅
- [x] pivot_table() - Aggregated pivot ✅

#### Duplicate Handling

- [x] duplicated() - Return boolean Series denoting duplicates ✅
- [x] drop_duplicates() - Remove duplicate rows ✅
- [x] keep parameter (first, last, False) ✅
- [x] subset parameter for specific columns ✅

#### Sampling & Selection

- [x] sample() - Random sampling ✅
  - [x] n parameter (number of items) ✅
  - [x] frac parameter (fraction of items) ✅
  - [x] replace parameter (with/without replacement) ✅
  - [x] weights parameter (probability weights) ✅
  - [x] random_state for reproducibility ✅
- [x] nlargest() / nsmallest() for DataFrames  ✅
- [x] take() - Return elements at given positions ✅

### 4. Time Series Operations

#### Time-based Operations

- [x] shift() - Shift index by desired number of periods ✅
- [x] lag() / lead() - Lag or lead values ✅
- [x] tshift() - Shift time index ✅
- [x] asfreq() - Convert to specified frequency ✅
- [x] at_time() - Select values at particular time of day ✅
- [x] between_time() - Select values between times ✅
- [x] first() / last() - Select first/last periods ✅
- [x] head() - First n rows ✅
- [x] tail() - Last n rows ✅

#### Frequency & Period Handling

- [x] Period and frequency conversion ✅ (via asfreq)
- [ ] Business day calendars
- [ ] Holiday calendars
- [ ] Custom business day frequencies
- [ ] Week/month/quarter/year end frequencies

#### Timezone Support

- [x] tz_localize() - Localize timezone-naive index ✅
- [x] tz_convert() - Convert timezone-aware index ✅
- [x] Timezone-aware datetime operations ✅

#### Resampling Enhancements

- [x] More aggregation methods (ohlc, nunique) ✅
- [x] Upsampling with interpolation ✅
- [x] Downsampling with custom functions ✅
- [x] Resampling with offset ✅
- [x] Resampling with closed/label parameters ✅
- [x] resample() - Basic resampling ✅
- [x] upsample() - Increase frequency ✅
- [x] downsample() - Decrease frequency ✅

### 5. String Operations (Series.str)

#### String Methods

- [x] str.len() - String length ✅ (already implemented)
- [x] str.lower() / upper() - Case conversion ✅ (already implemented)
- [x] str.strip() - Remove whitespace ✅ (already implemented)
- [x] str.startswith() / endswith() - Pattern matching ✅ (already implemented)
- [x] str.contains() - Contains pattern ✅ (already implemented)
- [x] str.replace() - Replace pattern ✅ (already implemented)
- [x] str.split() - Split strings ✅ (already implemented)
- [x] str.match() - Regex matching ✅ (already implemented)

#### Newly Implemented String Methods ✅

- [x] str.extract() - Extract capture groups from regex ✅
- [x] str.extractall() - Extract all matches ✅
- [x] str.findall() - Find all occurrences ✅
- [x] str.pad() - Pad strings to specified width ✅
- [x] str.center() - Center strings ✅
- [x] str.ljust() - Left-justify strings ✅
- [x] str.rjust() - Right-justify strings ✅
- [x] str.zfill() - Pad with zeros ✅
- [x] str.slice() - Slice strings ✅
- [x] str.sliceReplace() - Replace slice with value ✅
- [x] str.cat() - Concatenate strings ✅
- [x] str.repeat() - Repeat strings ✅
- [x] str.isalnum() / isalpha() / isdigit() / isspace() ✅
- [x] str.islower() / isupper() / istitle() ✅
- [x] str.isnumeric() / isdecimal() ✅
- [x] str.get() - Extract element from lists ✅

#### Not Implemented (Low Priority)

- [ ] str.normalize() - Unicode normalization (requires unicode package)
- [ ] str.encode() / decode() - Encode/decode strings (requires codec support)

### 6. I/O Operations

#### Database Support

- [x] read_sql_query() - Read SQL query results ✅
- [x] read_sql_table() - Read entire SQL table ✅
- [x] to_sql() - Write to SQL database ✅
- [x] SQL connection pooling ✅
- [x] Parameterized queries ✅
- [x] Transaction support ✅
- [x] Batch inserts ✅

#### File Format Support

- [x] CSV - Read/Write ✅
- [x] JSON - Read/Write ✅
- [x] Excel - Read/Write ✅
- [x] HDF5 - Read only ✅ (Pure Dart implementation)
- [ ] Parquet (full implementation with compression)
  - [ ] Read with column selection
  - [ ] Read with row filtering
  - [ ] Write with compression (snappy, gzip, brotli)
  - [ ] Partitioned datasets
- [ ] Feather format (Apache Arrow)
- [ ] ORC format
- [ ] Avro format
- [ ] Pickle format (serialization)
- [ ] Stata (.dta) format
- [ ] SAS (.sas7bdat, .xpt) format
- [ ] SPSS (.sav) format

#### Web & API

- [x] read_html() - Read HTML tables ✅
- [x] to_html() - Export to HTML ✅
- [ ] read_clipboard() - Read from clipboard (platform-specific, not suitable for cross-platform library)
- [ ] to_clipboard() - Write to clipboard (platform-specific, not suitable for cross-platform library)
- [x] read_xml() - Read XML files ✅
- [x] to_xml() - Export to XML ✅

#### Export Formats

- [x] to_latex() - Export to LaTeX tables ✅
- [x] to_markdown() - Export to Markdown tables ✅
- [x] to_string() - Formatted string representation ✅ (toStringFormatted)
- [x] to_records() - Convert to record array ✅

#### Advanced I/O Options

- [x] Compression support (gzip for HDF5) ✅
- [ ] Encoding detection
- [x] Chunked reading for CSV ✅
- [ ] Parallel reading/writing
- [ ] Memory mapping for large files
- [ ] Streaming I/O


### 7. Performance & Memory

#### Optimization

- [ ] Sparse data structures (SparseDataFrame, SparseSeries)
- [ ] Memory profiling (memory_usage())
- [ ] Query optimization
- [ ] Lazy evaluation
- [ ] Parallel operations (using Isolates)
- [ ] SIMD operations for numeric data

#### Categorical Enhancements

- [x] Categorical data type support ✅
- [x] Series.astype('category') ✅
- [x] Categorical accessor (.cat) ✅
- [x] cat.reorderCategories() ✅
- [x] cat.addCategories() ✅
- [x] cat.removeCategories() ✅
- [x] cat.renameCategories() ✅
- [x] cat.setCategories() ✅
- [x] cat.asOrdered() / asUnordered() ✅
- [x] cat.min() / max() for ordered categories ✅
- [x] cat.memoryUsage() - Memory usage comparison ✅

#### Data Types

- [x] Nullable integer dtype (Int8, Int16, Int32, Int64)
- [x] Nullable boolean dtype (boolean)
- [x] Nullable string dtype (string)
- [x] Extension types framework
- [x] Custom dtype registration

### 9. Advanced Features

#### Functional Programming

- [x] pipe() - Apply chainable functions ✅
- [x] apply() - Apply function to DataFrame ✅
- [x] applyToColumn() - Apply to specific column ✅
- [x] applyToRows() - Apply to rows ✅
- [x] apply() enhancements (result_type parameter) ✅
- [x] applymap() - Element-wise function application ✅
- [x] agg() with multiple functions ✅
- [x] transform() - Transform values ✅

#### Expression Evaluation

- [x] eval() - Evaluate string expressions ✅
- [x] query() - Query DataFrame with boolean expression ✅
- [ ] numexpr integration for fast evaluation (not applicable in Dart)

#### Custom Accessors

- [ ] Custom accessor registration
- [ ] Extension type system
- [ ] Plugin architecture for custom methods

#### Metadata

- [ ] attrs - Dictionary for global metadata
- [ ] flags - Flags for DataFrame properties
- [ ] info() enhancements (memory usage, null counts)

### 10. Data Validation & Quality

#### Validation

- [ ] assert_frame_equal() - Test DataFrame equality
- [ ] assert_series_equal() - Test Series equality
- [ ] Testing utilities
- [ ] Schema validation
- [ ] Data type validation

#### Data Quality

- [ ] Outlier detection methods
- [ ] Data profiling (summary statistics)
- [ ] Missing data patterns analysis
- [ ] Duplicate detection strategies
- [ ] Data consistency checks

---

## Data Source Integration Strategy

### Architecture Principles

1. **Keep core library lightweight** - No bloat in main package
2. **Plugin-based architecture** - Easy to extend
3. **Lazy loading** - Load adapters only when needed
4. **Community-driven** - Enable third-party sources
5. **Consistent API** - Uniform interface across sources

### Implementation Approaches

#### 1. Plugin Architecture (HIGH PRIORITY)

Create an abstract data source interface:

```dart
// lib/src/io/data_source.dart
abstract class DataSource {
  String get name;
  List<String> get supportedSchemes;
  
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options);
  Future<void> write(DataFrame df, Uri uri, Map<String, dynamic> options);
  
  bool canHandle(Uri uri);
}

// lib/src/io/data_source_registry.dart
class DataSourceRegistry {
  static final Map<String, DataSource> _sources = {};
  
  static void register(String name, DataSource source) {
    _sources[name] = source;
  }
  
  static DataSource? get(String name) => _sources[name];
  
  static DataSource? findByUri(Uri uri) {
    return _sources.values.firstWhere(
      (source) => source.canHandle(uri),
      orElse: () => null,
    );
  }
}
```

**Tasks:**

- [ ] Create DataSource abstract class
- [ ] Implement DataSourceRegistry
- [ ] Add registration mechanism
- [ ] Document plugin creation guide
- [ ] Create example plugin template

#### 2. Companion Packages (HIGH PRIORITY)

Create separate packages that depend on dartframe:

**Package Structure:**

```
dartframe_sql/          # Database connectors
  - PostgreSQL
  - MySQL
  - SQLite
  - SQL Server
  - Oracle

dartframe_cloud/        # Cloud storage
  - AWS S3
  - Google Cloud Storage
  - Azure Blob Storage
  - MinIO

dartframe_api/          # API integrations
  - REST API reader
  - GraphQL reader
  - gRPC reader
  - WebSocket streams

dartframe_formats/      # Additional formats
  - Apache Parquet
  - Apache Arrow
  - Feather
  - ORC
  - Avro

dartframe_streaming/    # Streaming sources
  - Apache Kafka
  - MQTT
  - RabbitMQ
  - Redis Streams

dartframe_bigdata/      # Big data integration
  - Apache Spark connector
  - Dask integration
  - Ray integration
```

**Tasks:**

- [ ] Create package templates
- [ ] Set up CI/CD for companion packages
- [ ] Create dartframe_sql package
- [ ] Create dartframe_cloud package
- [ ] Create dartframe_api package
- [ ] Create dartframe_formats package
- [ ] Document package creation guidelines
- [ ] Set up monorepo structure (optional)

#### 3. URL-Based Data Loading (MEDIUM PRIORITY)

Smart loader that detects source type from URL:

```dart
// lib/src/io/smart_loader.dart
class SmartLoader {
  static Future<DataFrame> read(
    String uri, {
    Map<String, dynamic>? options,
  }) async {
    final parsedUri = Uri.parse(uri);
    
    // Try registered data sources first
    final source = DataSourceRegistry.findByUri(parsedUri);
    if (source != null) {
      return await source.read(parsedUri, options ?? {});
    }
    
    // Fallback to built-in loaders
    switch (parsedUri.scheme) {
      case 'http':
      case 'https':
        return await _loadHttp(parsedUri, options);
      case 'file':
      case '':
        return await _loadFile(parsedUri, options);
      default:
        throw UnsupportedError('Unsupported URI scheme: ${parsedUri.scheme}');
    }
  }
}

// Usage examples:
await DataFrame.read('https://api.example.com/data.json');
await DataFrame.read('s3://bucket/data.csv');
await DataFrame.read('postgresql://user:pass@host/db?table=users');
await DataFrame.read('gs://bucket/data.parquet');
await DataFrame.read('file:///path/to/data.csv');
```

**Tasks:**

- [x] Implement SmartLoader class
- [x] Add URI parsing and validation
- [x] Implement HTTP/HTTPS loader
- [x] Implement file:// loader
- [x] Add DataFrame.read() convenience method
- [x] Add DataFrame.write() convenience method
- [ ] Document supported URI schemes
- [x] Add examples for common sources

#### 4. Stream-Based Reading (MEDIUM PRIORITY)

For large datasets that don't fit in memory:

```dart
// lib/src/io/streaming_reader.dart
class StreamingDataFrame {
  /// Read data in chunks
  Stream<DataFrame> readChunked(
    String source, {
    int chunkSize = 1000,
    Map<String, dynamic>? options,
  });
  
  /// Process data in chunks without loading all into memory
  Future<T> processInChunks<T>(
    String source,
    T Function(DataFrame chunk, T accumulator) processor, {
    T? initialValue,
    int chunkSize = 1000,
  });
  
  /// Aggregate data from chunks
  Future<DataFrame> aggregateChunks(
    String source,
    Map<String, String> aggregations, {
    int chunkSize = 1000,
  });
}

// Usage:
await for (final chunk in StreamingDataFrame().readChunked('large_file.csv')) {
  // Process each chunk
  print('Processing ${chunk.rowCount} rows');
}
```

**Tasks:**

- [ ] Implement StreamingDataFrame class
- [ ] Add chunked reading for CSV
- [ ] Add chunked reading for JSON
- [ ] Add chunked reading for Excel
- [ ] Implement processInChunks()
- [ ] Implement aggregateChunks()
- [ ] Add memory usage monitoring
- [ ] Document streaming best practices

#### 5. Configuration-Based Sources (LOW PRIORITY)

Define data sources in configuration files:

```yaml
# data_sources.yaml
sources:
  my_api:
    type: rest
    url: https://api.example.com
    auth:
      type: bearer
      token: ${API_TOKEN}
    headers:
      User-Agent: DartFrame/1.0
  
  my_db:
    type: postgresql
    connection: postgresql://localhost/mydb
    username: ${DB_USER}
    password: ${DB_PASS}
    pool_size: 10
  
  my_s3:
    type: s3
    bucket: my-data-bucket
    region: us-east-1
    credentials:
      access_key: ${AWS_ACCESS_KEY}
      secret_key: ${AWS_SECRET_KEY}
```

```dart
// lib/src/io/config_loader.dart
class DataSourceConfig {
  static Future<void> loadConfig(String path) async {
    // Load and parse YAML config
    // Register sources from config
  }
  
  static Future<DataFrame> fromConfig(
    String sourceName, {
    Map<String, dynamic>? params,
  }) async {
    // Load from configured source
  }
}

// Usage:
await DataSourceConfig.loadConfig('data_sources.yaml');
final df = await DataFrame.fromConfig('my_api', params: {'endpoint': '/users'});
```

**Tasks:**

- [ ] Implement DataSourceConfig class
- [ ] Add YAML config parsing
- [ ] Add environment variable substitution
- [ ] Add config validation
- [ ] Support multiple config formats (YAML, JSON, TOML)
- [ ] Add config encryption for sensitive data
- [ ] Document configuration schema

#### 6. Middleware/Interceptor Pattern (LOW PRIORITY)

Allow users to add custom data transformations:

```dart
// lib/src/io/data_pipeline.dart
abstract class DataTransformer {
  Future<dynamic> transform(dynamic data);
}

class DataPipeline {
  final List<DataTransformer> _transformers = [];
  
  void use(DataTransformer transformer) {
    _transformers.add(transformer);
  }
  
  Future<DataFrame> load(String source) async {
    var data = await _loadRaw(source);
    
    for (var transformer in _transformers) {
      data = await transformer.transform(data);
    }
    
    return DataFrame.fromData(data);
  }
}

// Usage:
final pipeline = DataPipeline()
  ..use(JsonNormalizer())
  ..use(DateParser())
  ..use(MissingValueHandler());

final df = await pipeline.load('data.json');
```

**Tasks:**

- [ ] Implement DataTransformer interface
- [ ] Implement DataPipeline class
- [ ] Create common transformers (normalization, parsing, etc.)
- [ ] Add transformer composition
- [ ] Add async transformer support
- [ ] Document transformer creation
- [ ] Create transformer examples

#### 7. FFI Bridge for Native Libraries (LOW PRIORITY)

For performance-critical formats:

```dart
// lib/src/io/native/parquet_reader.dart
class NativeParquetReader {
  static Future<DataFrame> read(String path) async {
    // Load native library only when needed
    final lib = DynamicLibrary.open(_getLibraryPath());
    
    // FFI calls to native Parquet library
    // ...
  }
  
  static String _getLibraryPath() {
    if (Platform.isLinux) return 'libparquet.so';
    if (Platform.isMacOS) return 'libparquet.dylib';
    if (Platform.isWindows) return 'parquet.dll';
    throw UnsupportedError('Platform not supported');
  }
}
```

**Tasks:**

- [ ] Research FFI requirements for Parquet
- [ ] Research FFI requirements for Arrow
- [ ] Create FFI bindings generator
- [ ] Implement native library loading
- [ ] Add platform-specific library paths
- [ ] Create fallback to pure Dart implementation
- [ ] Benchmark performance vs pure Dart
- [ ] Document native library setup

#### 8. Community Marketplace (ONGOING)

Foster a community ecosystem:

**Tasks:**

- [ ] Create pub.dev topic tag `dartframe-source`
- [ ] Maintain curated list in documentation
- [ ] Create plugin template repository
- [ ] Set up plugin showcase website
- [ ] Create plugin development guide
- [ ] Establish plugin quality guidelines
- [ ] Create version compatibility matrix
- [ ] Set up plugin testing framework
- [ ] Create plugin submission process
- [ ] Add plugin discovery in documentation

#### 9. Documentation & Examples (HIGH PRIORITY)

Comprehensive documentation for data sources:

**Tasks:**

- [ ] Create "Data Sources" documentation section
- [ ] Add examples for common APIs (GitHub, Twitter, etc.)
- [ ] Add examples for cloud providers (AWS, GCP, Azure)
- [ ] Add examples for databases (PostgreSQL, MySQL, MongoDB)
- [ ] Create performance benchmarks
- [ ] Add troubleshooting guide
- [ ] Create video tutorials
- [ ] Add interactive examples (DartPad)
- [ ] Document best practices
- [ ] Create migration guides from pandas

---

## Priority Matrix

### High Priority (Next 3-6 months)

1. Plugin architecture implementation
2. Companion packages (dartframe_sql, dartframe_cloud)
3. URL-based data loading
4. Documentation & examples

### Medium Priority (6-12 months)

1. Stream-based reading for large files
2. Window functions (rank, row_number)
3. String operations enhancements
4. Parquet format (full implementation)

### Low Priority (12+ months)

1. Configuration-based sources
2. Middleware/interceptor pattern
3. FFI bridge for native libraries
4. Visualization (plotting)
5. Sparse data structures
6. Expression evaluation (eval, query)
7. Advanced time series (timezone support)

---

## Contributing Guidelines

### For Core Features

1. Open an issue to discuss the feature
2. Reference this TODO document
3. Follow existing code style
4. Add comprehensive tests
5. Update documentation
6. Add examples

### For Data Source Plugins

1. Use the plugin template
2. Follow naming convention: `dartframe_<source_type>`
3. Implement DataSource interface
4. Add comprehensive tests
5. Document usage with examples
6. Submit to pub.dev with `dartframe-source` topic
7. Add to community showcase

### Testing Requirements

- Unit tests for all new features
- Integration tests for data sources
- Performance benchmarks for critical paths
- Documentation examples must be runnable

---

## Version Planning

### v0.9.0 (Current → Next Minor)

- [ ] Plugin architecture
- [ ] URL-based loading
- [ ] duplicated() / drop_duplicates()
- [ ] sample() method
- [ ] Enhanced documentation

### v1.0.0 (Stable Release)

- [ ] All high-priority features complete
- [ ] Comprehensive test coverage (>90%)
- [ ] Complete documentation
- [ ] At least 3 companion packages released
- [ ] Performance benchmarks published
- [ ] Migration guide from pandas

### v1.1.0

- [ ] Stream-based reading
- [ ] Time series enhancements
- [ ] Window functions
- [ ] MultiIndex support

### v1.2.0

- [ ] Visualization support
- [ ] Advanced statistical methods
- [ ] Expression evaluation

### v2.0.0 (Future)

- [ ] Breaking changes if needed
- [ ] Major performance improvements
- [ ] Advanced features (sparse, extension types)

---

## Performance Goals

### Benchmarks to Achieve

- [ ] Read 1M rows CSV in < 2 seconds
- [ ] GroupBy aggregation on 1M rows in < 1 second
- [ ] Join two 100K row DataFrames in < 500ms
- [ ] Memory usage < 2x data size for typical operations
- [ ] Streaming read 10M rows with < 100MB memory

### Optimization Strategies

- [ ] Implement column-oriented storage
- [ ] Use typed lists where possible
- [ ] Implement lazy evaluation
- [ ] Add parallel processing for CPU-intensive operations
- [ ] Optimize memory allocations
- [ ] Add caching for expensive operations

---

## Documentation Improvements

### Needed Documentation

- [ ] Complete API reference
- [ ] Tutorial series (beginner to advanced)
- [ ] Cookbook with common recipes
- [ ] Performance guide
- [ ] Migration guide from pandas
- [ ] Video tutorials
- [ ] Interactive examples
- [ ] Architecture documentation
- [ ] Contributing guide
- [ ] Plugin development guide

### Documentation Structure

```
docs/
├── getting-started/
│   ├── installation.md
│   ├── quick-start.md
│   └── basic-concepts.md
├── user-guide/
│   ├── data-structures.md
│   ├── io-operations.md
│   ├── data-manipulation.md
│   ├── statistics.md
│   └── time-series.md
├── api-reference/
│   ├── dataframe.md
│   ├── series.md
│   └── io.md
├── cookbook/
│   ├── data-cleaning.md
│   ├── data-analysis.md
│   └── data-visualization.md
├── advanced/
│   ├── performance.md
│   ├── plugins.md
│   └── architecture.md
└── migration/
    └── from-pandas.md
```

---

## Community & Ecosystem

### Community Building

- [ ] Set up Discord/Slack community
- [ ] Create GitHub Discussions
- [ ] Regular blog posts
- [ ] Conference talks
- [ ] Podcast appearances
- [ ] Social media presence

### Ecosystem Development

- [ ] Plugin marketplace
- [ ] Example projects repository
- [ ] Integration with popular Dart frameworks
- [ ] Jupyter kernel for Dart (if possible)
- [ ] VS Code extension
- [ ] IntelliJ plugin

---

## Notes

- This is a living document - update as priorities change
- Mark items as complete with [x] when done
- Add new items as they are identified
- Review and update quarterly
- Community feedback should influence priorities

---

## 📈 Implementation Recommendations

### Quick Wins (Easy to Implement, High Value)

1. **DataFrame.info()** - Essential for data exploration
2. **DataFrame.describe()** - Already partially implemented, needs completion
3. **DataFrame.memory_usage()** - Important for performance monitoring
4. **DataFrame.isna() / notna()** - Return DataFrame of booleans (Series already has these)
5. **DataFrame.assign()** - Functional style column assignment
6. **DataFrame.where() / mask()** - Conditional replacement
7. **DataFrame.equals()** - Test equality
8. **Series.between()** - Range checking
9. **Series.hasnans** - Quick missing data check
10. **Series.first_valid_index() / last_valid_index()** - Find valid data boundaries

### Medium Effort, High Impact

1. **DataFrame.reindex()** - Critical for data alignment
2. **DataFrame.align()** - Align two DataFrames
3. **DataFrame.select_dtypes()** - Filter columns by type
4. **DataFrame.iterrows() / itertuples()** - Iteration support
5. **DataFrame.compare()** - Show differences between DataFrames
6. **Series.dt enhancements** - Additional datetime properties
7. **Binary operations with fill_value** - Handle missing data in operations
8. **DataFrame.to_dict() / from_dict()** - Various orientations

### Complex but Important

1. **Plotting interface** - Visualization support
2. **Sparse data structures** - Memory optimization
3. **Style API** - Formatted output
4. **Advanced merge options** - indicator, validate parameters
5. **Memory optimization** - Efficient data storage

---

## 🎯 Suggested Implementation Order (Next 20 Methods)

### Phase 1: Data Inspection (Week 1-2)
1. DataFrame.info()
2. DataFrame.describe() (complete)
3. DataFrame.memory_usage()
4. DataFrame.select_dtypes()
5. Series.describe()

### Phase 2: Data Alignment (Week 3-4)
6. DataFrame.reindex()
7. DataFrame.align()
8. Series.reindex()
9. Series.align()
10. DataFrame.set_axis()

### Phase 3: Conditional Operations (Week 5-6)
11. DataFrame.where()
12. DataFrame.mask()
13. Series.where()
14. Series.mask()
15. Series.between()

### Phase 4: Comparison & Equality (Week 7-8)
16. DataFrame.equals()
17. DataFrame.compare()
18. Series.equals()
19. Series.compare()
20. DataFrame.eq/ne/lt/gt/le/ge (comparison operators)

### Phase 5: Data Transformation (Week 9-10)
21. DataFrame.assign()
22. DataFrame.insert()
23. DataFrame.pop()
24. DataFrame.update()
25. Series.update()

---

## 📊 Feature Coverage Statistics

### DataFrame Methods
- **Implemented:** ~85 core methods
- **Missing (High Priority):** ~45 methods
- **Missing (Medium Priority):** ~30 methods
- **Missing (Low Priority):** ~25 methods
- **Total Coverage:** ~46% of pandas DataFrame API

### Series Methods
- **Implemented:** ~95 core methods
- **Missing (High Priority):** ~25 methods
- **Missing (Medium Priority):** ~40 methods
- **Missing (Low Priority):** ~20 methods
- **Total Coverage:** ~53% of pandas Series API

### Overall Assessment
DartFrame has excellent coverage of:
- ✅ Statistical operations (90%+)
- ✅ GroupBy operations (85%+)
- ✅ Time series basics (80%+)
- ✅ I/O operations (75%+)
- ✅ String operations (90%+)
- ✅ Categorical data (95%+)

Areas needing improvement:
- ⚠️ Data alignment & reindexing (40%)
- ⚠️ Iteration methods (30%)
- ⚠️ Comparison operations (50%)
- ⚠️ Memory optimization (20%)
- ❌ Visualization (0%)
- ❌ Sparse data (0%)

---

**Last Updated:** 2025-11-19
**Next Review:** 2025-12-01
