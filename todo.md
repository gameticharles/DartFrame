# DartFrame Development Roadmap

This document outlines missing features compared to pandas and strategies for adding data sources without bloating the library.

## 📊 Implementation Status Summary

### ✅ Already Implemented (Major Features)
- **Statistical Operations**: median, mode, quantile, std, variance, skew, kurtosis, corr (pearson/spearman), cov
- **Rolling Window Operations**: Full suite (mean, sum, std, var, min, max, median, quantile, corr, cov, skew, kurt, apply)
- **Reshaping**: stack, unstack, melt, pivot, pivot_table, transpose, explode, getDummies
- **Time Series**: resample, upsample, downsample with interpolation
- **I/O**: CSV, JSON, Excel (read/write), HDF5 (read), SQL database support, chunked reading
- **Data Manipulation**: sample, rank, round, bin/discretization, apply functions, filter, select
- **Missing Data**: fillna (forward/backward fill), dropna, isna, notna, interpolation
- **Categorical**: Basic categorical dtype with .cat accessor
- **Groupby**: Basic groupby with aggregations
- **Joining**: merge, join, concat with multiple join types

### ✅ Just Implemented (Quick Wins)
1. ~~**duplicated() / drop_duplicates()**~~ ✅ **DONE** - DataFrame duplicate detection and removal
2. ~~**nlargest() / nsmallest()**~~ ✅ **DONE** - For both DataFrame and Series
3. ~~**idxmax() / idxmin()**~~ ✅ **ALREADY IMPLEMENTED** - Both were already in series/functions.dart
4. ~~**abs() for Series**~~ ✅ **ALREADY IMPLEMENTED** - Found in series/statistics.dart
5. ~~**pct_change() / diff()**~~ ✅ **ALREADY IMPLEMENTED** - Found in series/statistics.dart

**Summary**: Implemented 4 new methods (duplicated, dropDuplicates, nlargest, nsmallest) and discovered 5 methods were already implemented!

### 🔴 High Priority Missing Features
- MultiIndex support
- Duplicate detection and removal
- Advanced groupby (transform, filter, pipe)
- Window functions (rank, row_number, dense_rank)
- Time series shift/lag operations
- String operations enhancements
- Visualization/plotting

---

## Missing Pandas Features

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
- [ ] Exponential weighted functions (ewm)
  - [ ] ewm().mean()
  - [ ] ewm().std()
  - [ ] ewm().var()
  - [ ] ewm().corr()
  - [ ] ewm().cov()
- [ ] Expanding window operations
  - [ ] expanding().mean()
  - [ ] expanding().sum()
  - [ ] expanding().std()
  - [ ] expanding().min()
  - [ ] expanding().max()
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
- [ ] clip() - Trim values at input thresholds
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
- [ ] rank() with methods (average, min, max, first, dense)
- [ ] dense_rank()
- [ ] row_number()
- [ ] percent_rank()
- [ ] cumulative distribution

#### Reshaping Operations
- [x] explode() - Transform list-like elements to rows ✅
- [x] transpose() - Swap rows and columns ✅
- [ ] swaplevel() - Swap levels in MultiIndex
- [ ] reorder_levels() - Rearrange index levels
- [ ] wide_to_long() - Wide panel to long format
- [x] get_dummies() enhancements ✅ (getDummies implemented)
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
- [x] read_sql_query() - Read SQL query results ✅ (via database.dart)
- [x] read_sql_table() - Read entire SQL table ✅ (via database.dart)
- [x] to_sql() - Write to SQL database ✅ (via database.dart)
- [ ] SQL connection pooling
- [ ] Parameterized queries
- [ ] Transaction support
- [ ] Batch inserts

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
- [ ] read_html() - Read HTML tables
- [ ] to_html() - Export to HTML
- [ ] read_clipboard() - Read from clipboard
- [ ] to_clipboard() - Write to clipboard
- [ ] read_xml() - Read XML files
- [ ] to_xml() - Export to XML

#### Export Formats
- [ ] to_latex() - Export to LaTeX tables
- [ ] to_markdown() - Export to Markdown tables
- [ ] to_string() - Formatted string representation
- [ ] to_records() - Convert to record array

#### Advanced I/O Options
- [x] Compression support (gzip for HDF5) ✅
- [ ] Encoding detection
- [x] Chunked reading for CSV ✅
- [ ] Parallel reading/writing
- [ ] Memory mapping for large files
- [ ] Streaming I/O

### 7. Visualization

#### Built-in Plotting
- [ ] plot() - General plotting interface
- [ ] plot.line() - Line plots
- [ ] plot.bar() - Bar plots
- [ ] plot.barh() - Horizontal bar plots
- [ ] plot.hist() - Histograms
- [ ] plot.box() - Box plots
- [ ] plot.kde() - Kernel density estimation
- [ ] plot.area() - Area plots
- [ ] plot.scatter() - Scatter plots
- [ ] plot.hexbin() - Hexagonal bin plots
- [ ] plot.pie() - Pie charts

#### Styling
- [ ] style.format() - Format values
- [ ] style.highlight_max() / min()
- [ ] style.background_gradient()
- [ ] style.bar() - Data bars
- [ ] style.set_properties() - CSS properties
- [ ] style.applymap() - Element-wise styling
- [ ] style.apply() - Column/row-wise styling

### 8. Performance & Memory

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
- [ ] Nullable integer dtype (Int8, Int16, Int32, Int64)
- [ ] Nullable boolean dtype (boolean)
- [ ] Nullable string dtype (string)
- [ ] Extension types framework
- [ ] Custom dtype registration

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
- [ ] Implement SmartLoader class
- [ ] Add URI parsing and validation
- [ ] Implement HTTP/HTTPS loader
- [ ] Implement file:// loader
- [ ] Add DataFrame.read() convenience method
- [ ] Add DataFrame.write() convenience method
- [ ] Document supported URI schemes
- [ ] Add examples for common sources

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
5. Duplicate handling (duplicated, drop_duplicates) ⚠️ **EASIEST TO IMPLEMENT**
6. ~~Sample() method for random sampling~~ ✅ **DONE**
7. Enhanced groupby operations
8. nlargest() / nsmallest() ⚠️ **VERY EASY**
9. idxmax() / idxmin() ⚠️ **VERY EASY**
10. abs() for Series ⚠️ **VERY EASY**
11. pct_change() and diff() ⚠️ **EASY**

### Medium Priority (6-12 months)
1. Stream-based reading for large files
2. Time series enhancements (shift, lag, lead)
3. Window functions (rank, row_number)
4. String operations enhancements
5. Statistical methods (pct_change, diff, clip)
6. MultiIndex support
7. Parquet format (full implementation)

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

**Last Updated:** 2024-11-15
**Next Review:** 2025-02-15
