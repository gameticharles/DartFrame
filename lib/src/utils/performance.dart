library;

import 'dart:math' as math;
import '../series/series.dart';
import '../data_frame/data_frame.dart';

// Platform-specific conditional imports
import 'performance_stub.dart'
    if (dart.library.isolate) 'performance_native.dart'
    if (dart.library.html) 'performance_web.dart' as platform;

/// Performance optimization utilities for DartFrame.
///
/// This class provides methods to improve performance through:
/// - Vectorized operations on Series and DataFrame
/// - Parallel processing for CPU-intensive tasks (when supported)
/// - Optimized mathematical operations
/// - Batch processing capabilities
///
/// Note: Parallel processing automatically falls back to synchronous processing
/// on web platforms where isolates are not supported.
class PerformanceOptimizer {
  /// Returns information about the current platform's performance capabilities.
  static Map<String, dynamic> getPlatformInfo() {
    return platform.getPlatformInfo();
  }

  /// Prints platform capabilities to help with debugging and optimization.
  static void printPlatformInfo() {
    Map<String, dynamic> info = getPlatformInfo();
    print('DartFrame Performance Platform Info:');
    print('- Platform: ${info['platform']}');
    print('- Supports Isolates: ${info['supportsIsolates']}');
    print(
        '- Supports Parallel Processing: ${info['supportsParallelProcessing']}');
    print('- Recommended Chunk Size: ${info['recommendedChunkSize']}');

    if (!info['supportsParallelProcessing']) {
      print(
          '- Note: Parallel operations will fall back to synchronous processing');
    }
  }

  /// Applies a function to each element of a Series using vectorized operations.
  ///
  /// This method is optimized for performance and should be preferred over
  /// manual iteration when applying the same operation to all elements.
  ///
  /// **Cross-Platform Behavior:**
  /// - On native platforms (mobile, desktop): Uses isolates for parallel processing when `parallel=true`
  /// - On web platforms: Automatically falls back to synchronous processing (isolates not supported)
  /// - The API remains the same across all platforms for seamless development
  ///
  /// Parameters:
  /// - `series`: The Series to apply the function to
  /// - `func`: The function to apply to each element
  /// - `parallel`: Whether to use parallel processing for large Series (auto-fallback on web)
  /// - `chunkSize`: Size of chunks for parallel processing (larger chunks recommended for web)
  ///
  /// Returns:
  /// A new Series with the function applied to each element.
  ///
  /// Example:
  /// ```dart
  /// var series = Series([1, 2, 3, 4, 5], name: 'numbers');
  /// var squared = await PerformanceOptimizer.vectorizedApply(
  ///   series,
  ///   (x) => x * x,
  ///   parallel: true, // Will use isolates on native, sync on web
  /// );
  /// // Result: Series([1, 4, 9, 16, 25], name: 'numbers')
  /// ```
  static Future<Series> vectorizedApply(
    Series series,
    dynamic Function(dynamic) func, {
    bool parallel = false,
    int chunkSize = 1000,
  }) async {
    if (!parallel || series.length < chunkSize) {
      // Sequential processing for small Series or when parallel is disabled
      List<dynamic> result = [];
      for (dynamic value in series.data) {
        result.add(func(value));
      }
      return Series(result, name: series.name, index: series.index);
    }

    // Parallel processing for large Series
    return await _parallelApply(series, func, chunkSize);
  }

  /// Applies a function to each row of a DataFrame using vectorized operations.
  ///
  /// Parameters:
  /// - `df`: The DataFrame to apply the function to
  /// - `func`: The function to apply to each row (receives a Map&lt;String, dynamic&gt;)
  /// - `axis`: 0 for rows, 1 for columns
  /// - `parallel`: Whether to use parallel processing
  /// - `chunkSize`: Size of chunks for parallel processing
  ///
  /// Returns:
  /// A Series containing the results of applying the function to each row/column.
  static Future<Series> vectorizedApplyDataFrame(
    DataFrame df,
    dynamic Function(Map<String, dynamic>) func, {
    int axis = 0,
    bool parallel = false,
    int chunkSize = 1000,
  }) async {
    if (axis == 0) {
      // Apply to rows
      List<dynamic> results = [];
      List<dynamic> resultIndex = [];

      if (!parallel || df.rowCount < chunkSize) {
        // Sequential processing
        for (int i = 0; i < df.rowCount; i++) {
          Map<String, dynamic> row = {};
          for (int j = 0; j < df.columnCount; j++) {
            row[df.columns[j].toString()] = df.iloc[i][j];
          }
          results.add(func(row));
          resultIndex.add(df.index[i]);
        }
      } else {
        // Parallel processing
        results = await _parallelApplyDataFrameRows(df, func, chunkSize);
        resultIndex = df.index;
      }

      return Series(results, name: 'applied', index: resultIndex);
    } else {
      // Apply to columns
      List<dynamic> results = [];
      List<dynamic> resultIndex = [];

      for (String columnName in df.columns.cast<String>()) {
        Series column = df[columnName];
        Map<String, dynamic> columnData = {
          'name': columnName,
          'data': column.data,
          'index': column.index,
        };
        results.add(func(columnData));
        resultIndex.add(columnName);
      }

      return Series(results, name: 'applied', index: resultIndex);
    }
  }

  /// Performs vectorized mathematical operations on numeric Series.
  ///
  /// Parameters:
  /// - `series1`: First Series
  /// - `series2`: Second Series or a scalar value
  /// - `operation`: The operation to perform ('+', '-', '*', '/', '^', '%')
  ///
  /// Returns:
  /// A new Series with the operation applied element-wise.
  static Series vectorizedMath(
    Series series1,
    dynamic series2,
    String operation,
  ) {
    List<dynamic> result = [];

    if (series2 is Series) {
      // Element-wise operation between two Series
      int minLength = math.min(series1.length, series2.length);
      for (int i = 0; i < minLength; i++) {
        dynamic val1 = series1.data[i];
        dynamic val2 = series2.data[i];
        result.add(_performMathOperation(val1, val2, operation));
      }
    } else {
      // Operation between Series and scalar
      for (dynamic value in series1.data) {
        result.add(_performMathOperation(value, series2, operation));
      }
    }

    return Series(result, name: series1.name, index: series1.index);
  }

  /// Performs vectorized comparison operations on Series.
  ///
  /// Parameters:
  /// - `series1`: First Series
  /// - `series2`: Second Series or a scalar value
  /// - `operation`: The comparison operation ('==', '!=', '<', '>', '<=', '>=')
  ///
  /// Returns:
  /// A new Series of boolean values.
  static Series vectorizedComparison(
    Series series1,
    dynamic series2,
    String operation,
  ) {
    List<bool> result = [];

    if (series2 is Series) {
      // Element-wise comparison between two Series
      int minLength = math.min(series1.length, series2.length);
      for (int i = 0; i < minLength; i++) {
        dynamic val1 = series1.data[i];
        dynamic val2 = series2.data[i];
        result.add(_performComparisonOperation(val1, val2, operation));
      }
    } else {
      // Comparison between Series and scalar
      for (dynamic value in series1.data) {
        result.add(_performComparisonOperation(value, series2, operation));
      }
    }

    return Series(result.cast<dynamic>(),
        name: '${series1.name}_comparison', index: series1.index);
  }

  /// Performs vectorized string operations on Series containing strings.
  ///
  /// Parameters:
  /// - `series`: The Series containing string data
  /// - `operation`: The string operation ('upper', 'lower', 'trim', 'length', 'contains', 'startsWith', 'endsWith')
  /// - `argument`: Optional argument for operations that require it (e.g., 'contains', 'startsWith', 'endsWith')
  ///
  /// Returns:
  /// A new Series with the string operation applied.
  static Series vectorizedStringOperation(
    Series series,
    String operation, {
    String? argument,
  }) {
    List<dynamic> result = [];

    for (dynamic value in series.data) {
      if (value == null) {
        result.add(null);
        continue;
      }

      String stringValue = value.toString();

      switch (operation.toLowerCase()) {
        case 'upper':
          result.add(stringValue.toUpperCase());
          break;
        case 'lower':
          result.add(stringValue.toLowerCase());
          break;
        case 'trim':
          result.add(stringValue.trim());
          break;
        case 'length':
          result.add(stringValue.length);
          break;
        case 'contains':
          if (argument != null) {
            result.add(stringValue.contains(argument));
          } else {
            throw ArgumentError('Argument required for contains operation');
          }
          break;
        case 'startswith':
          if (argument != null) {
            result.add(stringValue.startsWith(argument));
          } else {
            throw ArgumentError('Argument required for startsWith operation');
          }
          break;
        case 'endswith':
          if (argument != null) {
            result.add(stringValue.endsWith(argument));
          } else {
            throw ArgumentError('Argument required for endsWith operation');
          }
          break;
        default:
          throw ArgumentError('Unsupported string operation: $operation');
      }
    }

    return Series(result,
        name: '${series.name}_$operation', index: series.index);
  }

  /// Performs batch operations on multiple Series simultaneously.
  ///
  /// This is useful for operations that need to be applied to multiple
  /// columns of a DataFrame efficiently.
  ///
  /// Parameters:
  /// - `seriesList`: List of Series to process
  /// - `func`: Function to apply to each Series
  /// - `parallel`: Whether to process Series in parallel
  ///
  /// Returns:
  /// A list of Series with the function applied.
  static Future<List<Series>> batchProcess(
    List<Series> seriesList,
    dynamic Function(Series) func, {
    bool parallel = false,
  }) async {
    Map<String, dynamic> platformInfo = getPlatformInfo();
    if (!parallel || !platformInfo['supportsParallelProcessing']) {
      // Sequential processing (always used on web or unsupported platforms)
      List<Series> results = [];
      for (Series series in seriesList) {
        results.add(func(series));
      }
      return results;
    }

    try {
      // Parallel processing (only on non-web platforms)
      List<Future<Series>> futures = [];
      for (Series series in seriesList) {
        futures.add(Future(() => func(series)));
      }

      return await Future.wait(futures);
    } catch (e) {
      // Fallback to sequential processing
      List<Series> results = [];
      for (Series series in seriesList) {
        results.add(func(series));
      }
      return results;
    }
  }

  /// Optimizes DataFrame operations by processing columns in parallel.
  ///
  /// Parameters:
  /// - `df`: The DataFrame to process
  /// - `func`: Function to apply to each column (Series)
  /// - `columnNames`: Optional list of column names to process. If null, all columns are processed.
  ///
  /// Returns:
  /// A new DataFrame with the function applied to specified columns.
  static Future<DataFrame> parallelColumnProcess(
    DataFrame df,
    Series Function(Series) func, {
    List<String>? columnNames,
  }) async {
    List<String> columnsToProcess = columnNames ?? df.columns.cast<String>();
    Map<String, List<dynamic>> resultData = {};

    Map<String, dynamic> platformInfo = getPlatformInfo();
    if (!platformInfo['supportsParallelProcessing']) {
      // Sequential processing on web or unsupported platforms
      for (String columnName in columnsToProcess) {
        Series column = df[columnName];
        Series processedColumn = func(column);
        resultData[columnName] = processedColumn.data;
      }

      // Keep original data for unprocessed columns
      for (String columnName in df.columns.cast<String>()) {
        if (!columnsToProcess.contains(columnName)) {
          resultData[columnName] = df[columnName].data;
        }
      }
    } else {
      try {
        // Process specified columns in parallel (non-web platforms)
        List<Future<MapEntry<String, Series>>> futures = [];

        for (String columnName in columnsToProcess) {
          Series column = df[columnName];
          futures.add(Future(() {
            Series processedColumn = func(column);
            return MapEntry(columnName, processedColumn);
          }));
        }

        List<MapEntry<String, Series>> results = await Future.wait(futures);

        // Build result data map
        for (String columnName in df.columns.cast<String>()) {
          if (columnsToProcess.contains(columnName)) {
            // Find the processed result for this column
            MapEntry<String, Series> result = results.firstWhere(
              (entry) => entry.key == columnName,
            );
            resultData[columnName] = result.value.data;
          } else {
            // Keep original data for unprocessed columns
            resultData[columnName] = df[columnName].data;
          }
        }
      } catch (e) {
        // Fallback to sequential processing
        for (String columnName in columnsToProcess) {
          Series column = df[columnName];
          Series processedColumn = func(column);
          resultData[columnName] = processedColumn.data;
        }

        // Keep original data for unprocessed columns
        for (String columnName in df.columns.cast<String>()) {
          if (!columnsToProcess.contains(columnName)) {
            resultData[columnName] = df[columnName].data;
          }
        }
      }
    }

    return DataFrame.fromMap(
      resultData,
      index: df.index,
      allowFlexibleColumns: df.allowFlexibleColumns,
      replaceMissingValueWith: df.replaceMissingValueWith,
    );
  }

  /// Calculates aggregation statistics for numeric Series using vectorized operations.
  ///
  /// Parameters:
  /// - `series`: The numeric Series to analyze
  /// - `operations`: List of operations to perform ('sum', 'mean', 'min', 'max', 'std', 'var')
  ///
  /// Returns:
  /// A map containing the calculated statistics.
  static Map<String, double> vectorizedAggregation(
    Series series,
    List<String> operations,
  ) {
    Map<String, double> results = {};
    List<num> numericValues =
        series.data.where((v) => v != null && v is num).cast<num>().toList();

    if (numericValues.isEmpty) {
      for (String operation in operations) {
        results[operation] = double.nan;
      }
      return results;
    }

    // Pre-calculate commonly needed values
    double sum = 0;
    double min = numericValues.first.toDouble();
    double max = numericValues.first.toDouble();

    for (num value in numericValues) {
      double doubleValue = value.toDouble();
      sum += doubleValue;
      if (doubleValue < min) min = doubleValue;
      if (doubleValue > max) max = doubleValue;
    }

    double mean = sum / numericValues.length;

    for (String operation in operations) {
      switch (operation.toLowerCase()) {
        case 'sum':
          results[operation] = sum;
          break;
        case 'mean':
          results[operation] = mean;
          break;
        case 'min':
          results[operation] = min;
          break;
        case 'max':
          results[operation] = max;
          break;
        case 'std':
          results[operation] = _calculateStandardDeviation(numericValues, mean);
          break;
        case 'var':
          double std = _calculateStandardDeviation(numericValues, mean);
          results[operation] = std * std;
          break;
        default:
          throw ArgumentError('Unsupported aggregation operation: $operation');
      }
    }

    return results;
  }

  // Private helper methods

  static Future<Series> _parallelApply(
    Series series,
    dynamic Function(dynamic) func,
    int chunkSize,
  ) async {
    // Use platform-specific implementation
    return platform.parallelApply(series, func, chunkSize);
  }

  static Future<List<dynamic>> _parallelApplyDataFrameRows(
    DataFrame df,
    dynamic Function(Map<String, dynamic>) func,
    int chunkSize,
  ) async {
    // Use platform-specific implementation
    return platform.parallelApplyDataFrameRows(df, func, chunkSize);
  }

  static dynamic _performMathOperation(
      dynamic val1, dynamic val2, String operation) {
    if (val1 == null || val2 == null) return null;

    if (val1 is! num || val2 is! num) {
      throw ArgumentError('Math operations require numeric values');
    }

    switch (operation) {
      case '+':
        return val1 + val2;
      case '-':
        return val1 - val2;
      case '*':
        return val1 * val2;
      case '/':
        return val2 != 0 ? val1 / val2 : double.infinity;
      case '^':
        return math.pow(val1, val2);
      case '%':
        return val1 % val2;
      default:
        throw ArgumentError('Unsupported math operation: $operation');
    }
  }

  static bool _performComparisonOperation(
      dynamic val1, dynamic val2, String operation) {
    if (val1 == null && val2 == null) return operation == '==';
    if (val1 == null || val2 == null) return operation == '!=';

    switch (operation) {
      case '==':
        return val1 == val2;
      case '!=':
        return val1 != val2;
      case '<':
        return (val1 as Comparable).compareTo(val2) < 0;
      case '>':
        return (val1 as Comparable).compareTo(val2) > 0;
      case '<=':
        return (val1 as Comparable).compareTo(val2) <= 0;
      case '>=':
        return (val1 as Comparable).compareTo(val2) >= 0;
      default:
        throw ArgumentError('Unsupported comparison operation: $operation');
    }
  }

  static double _calculateStandardDeviation(List<num> values, double mean) {
    double sumSquaredDifferences = 0;
    for (num value in values) {
      double diff = value.toDouble() - mean;
      sumSquaredDifferences += diff * diff;
    }
    return math.sqrt(sumSquaredDifferences / values.length);
  }
}

/// Extension methods for Series vectorized operations.
extension SeriesVectorizedOperations on Series {
  /// Applies a function to each element using vectorized operations.
  Future<Series> vectorizedApply(
    dynamic Function(dynamic) func, {
    bool parallel = false,
    int chunkSize = 1000,
  }) {
    return PerformanceOptimizer.vectorizedApply(
      this,
      func,
      parallel: parallel,
      chunkSize: chunkSize,
    );
  }

  /// Performs vectorized mathematical operations.
  Series vectorizedMath(dynamic other, String operation) {
    return PerformanceOptimizer.vectorizedMath(this, other, operation);
  }

  /// Performs vectorized comparison operations.
  Series vectorizedComparison(dynamic other, String operation) {
    return PerformanceOptimizer.vectorizedComparison(this, other, operation);
  }

  /// Performs vectorized string operations.
  Series vectorizedStringOperation(String operation, {String? argument}) {
    return PerformanceOptimizer.vectorizedStringOperation(
      this,
      operation,
      argument: argument,
    );
  }

  /// Calculates multiple aggregation statistics efficiently.
  Map<String, double> vectorizedAggregation(List<String> operations) {
    return PerformanceOptimizer.vectorizedAggregation(this, operations);
  }

  // Convenience methods for comparison operations (arithmetic operators already exist in SeriesOperations)
  Series eq(dynamic other) => vectorizedComparison(other, '==');
  Series ne(dynamic other) => vectorizedComparison(other, '!=');
  Series lt(dynamic other) => vectorizedComparison(other, '<');
  Series gt(dynamic other) => vectorizedComparison(other, '>');
  Series le(dynamic other) => vectorizedComparison(other, '<=');
  Series ge(dynamic other) => vectorizedComparison(other, '>=');
}

/// Extension methods for DataFrame vectorized operations.
extension DataFrameVectorizedOperations on DataFrame {
  /// Applies a function to each row using vectorized operations.
  Future<Series> vectorizedApply(
    dynamic Function(Map<String, dynamic>) func, {
    int axis = 0,
    bool parallel = false,
    int chunkSize = 1000,
  }) {
    return PerformanceOptimizer.vectorizedApplyDataFrame(
      this,
      func,
      axis: axis,
      parallel: parallel,
      chunkSize: chunkSize,
    );
  }

  /// Processes columns in parallel.
  Future<DataFrame> parallelColumnProcess(
    Series Function(Series) func, {
    List<String>? columnNames,
  }) {
    return PerformanceOptimizer.parallelColumnProcess(
      this,
      func,
      columnNames: columnNames,
    );
  }
}

/// Caching mechanisms for expensive DataFrame and Series operations.
///
/// This class provides various caching strategies to improve performance
/// by storing results of expensive computations and reusing them when
/// the same operations are requested again.
class CacheManager {
  static final Map<String, CacheEntry> _cache = {};
  static int _maxCacheSize = 100;
  static Duration _defaultTtl = Duration(minutes: 30);

  /// Sets the maximum number of entries in the cache.
  static void setMaxCacheSize(int size) {
    _maxCacheSize = size;
    _evictIfNecessary();
  }

  /// Sets the default time-to-live for cache entries.
  static void setDefaultTtl(Duration ttl) {
    _defaultTtl = ttl;
  }

  /// Clears all cache entries.
  static void clearCache() {
    _cache.clear();
  }

  /// Gets cache statistics.
  static CacheStats getCacheStats() {
    int validEntries = 0;
    int expiredEntries = 0;
    int totalSize = 0;

    DateTime now = DateTime.now();
    for (CacheEntry entry in _cache.values) {
      if (entry.isExpired(now)) {
        expiredEntries++;
      } else {
        validEntries++;
      }
      totalSize += entry.estimatedSize;
    }

    return CacheStats(
      totalEntries: _cache.length,
      validEntries: validEntries,
      expiredEntries: expiredEntries,
      totalSize: totalSize,
      maxSize: _maxCacheSize,
    );
  }

  /// Caches the result of an expensive operation.
  static T cacheOperation<T>(
    String key,
    T Function() operation, {
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    ttl ??= _defaultTtl;

    if (!forceRefresh && _cache.containsKey(key)) {
      CacheEntry entry = _cache[key]!;
      if (!entry.isExpired(DateTime.now())) {
        entry.accessCount++;
        entry.lastAccessed = DateTime.now();
        return entry.value as T;
      } else {
        _cache.remove(key);
      }
    }

    // Execute the operation and cache the result
    T result = operation();
    _cache[key] = CacheEntry(
      value: result,
      createdAt: DateTime.now(),
      ttl: ttl,
      estimatedSize: _estimateSize(result),
    );

    _evictIfNecessary();
    return result;
  }

  /// Caches DataFrame operations with automatic key generation.
  static T cacheDataFrameOperation<T>(
    DataFrame df,
    String operationName,
    T Function() operation, {
    List<String>? additionalKeyComponents,
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    String key =
        _generateDataFrameKey(df, operationName, additionalKeyComponents);
    return cacheOperation(key, operation, ttl: ttl, forceRefresh: forceRefresh);
  }

  /// Caches Series operations with automatic key generation.
  static T cacheSeriesOperation<T>(
    Series series,
    String operationName,
    T Function() operation, {
    List<String>? additionalKeyComponents,
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    String key =
        _generateSeriesKey(series, operationName, additionalKeyComponents);
    return cacheOperation(key, operation, ttl: ttl, forceRefresh: forceRefresh);
  }

  /// Invalidates cache entries that depend on a specific DataFrame.
  static void invalidateDataFrameCache(DataFrame df) {
    String dfHash = _generateDataFrameHash(df);
    List<String> keysToRemove = [];

    for (String key in _cache.keys) {
      if (key.contains(dfHash)) {
        keysToRemove.add(key);
      }
    }

    for (String key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Invalidates cache entries that depend on a specific Series.
  static void invalidateSeriesCache(Series series) {
    String seriesHash = _generateSeriesHash(series);
    List<String> keysToRemove = [];

    for (String key in _cache.keys) {
      if (key.contains(seriesHash)) {
        keysToRemove.add(key);
      }
    }

    for (String key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Removes expired entries from the cache.
  static void cleanupExpiredEntries() {
    DateTime now = DateTime.now();
    List<String> expiredKeys = [];

    for (MapEntry<String, CacheEntry> entry in _cache.entries) {
      if (entry.value.isExpired(now)) {
        expiredKeys.add(entry.key);
      }
    }

    for (String key in expiredKeys) {
      _cache.remove(key);
    }
  }

  // Private helper methods

  static void _evictIfNecessary() {
    if (_cache.length <= _maxCacheSize) return;

    // Remove expired entries first
    cleanupExpiredEntries();

    if (_cache.length <= _maxCacheSize) return;

    // Use LRU eviction strategy
    List<MapEntry<String, CacheEntry>> entries = _cache.entries.toList();
    entries
        .sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

    int entriesToRemove = _cache.length - _maxCacheSize;
    for (int i = 0; i < entriesToRemove; i++) {
      _cache.remove(entries[i].key);
    }
  }

  static String _generateDataFrameKey(
    DataFrame df,
    String operationName,
    List<String>? additionalComponents,
  ) {
    String dfHash = _generateDataFrameHash(df);
    String key = 'df_${dfHash}_$operationName';

    if (additionalComponents != null) {
      key += '_${additionalComponents.join('_')}';
    }

    return key;
  }

  static String _generateSeriesKey(
    Series series,
    String operationName,
    List<String>? additionalComponents,
  ) {
    String seriesHash = _generateSeriesHash(series);
    String key = 'series_${seriesHash}_$operationName';

    if (additionalComponents != null) {
      key += '_${additionalComponents.join('_')}';
    }

    return key;
  }

  static String _generateDataFrameHash(DataFrame df) {
    // Generate a hash based on DataFrame structure and a sample of data
    StringBuffer buffer = StringBuffer();
    buffer.write('${df.rowCount}x${df.columnCount}');
    buffer.write('_${df.columns.join(',')}');

    // Sample first and last few rows for hash
    int sampleSize = math.min(3, df.rowCount);
    for (int i = 0; i < sampleSize; i++) {
      buffer.write('_${df.iloc[i].join(',')}');
    }
    if (df.rowCount > sampleSize) {
      for (int i = df.rowCount - sampleSize; i < df.rowCount; i++) {
        buffer.write('_${df.iloc[i].join(',')}');
      }
    }

    return buffer.toString().hashCode.toString();
  }

  static String _generateSeriesHash(Series series) {
    // Generate a hash based on Series structure and a sample of data
    StringBuffer buffer = StringBuffer();
    buffer.write('${series.length}_${series.name}');

    // Sample first and last few values for hash
    int sampleSize = math.min(5, series.length);
    for (int i = 0; i < sampleSize; i++) {
      buffer.write('_${series.data[i]}');
    }
    if (series.length > sampleSize) {
      for (int i = series.length - sampleSize; i < series.length; i++) {
        buffer.write('_${series.data[i]}');
      }
    }

    return buffer.toString().hashCode.toString();
  }

  static int _estimateSize(dynamic value) {
    if (value is DataFrame) {
      return value.rowCount * value.columnCount * 8; // Rough estimate
    } else if (value is Series) {
      return value.length * 8; // Rough estimate
    } else if (value is List) {
      return value.length * 8;
    } else if (value is Map) {
      return value.length * 16;
    } else if (value is String) {
      return value.length * 2;
    } else {
      return 64; // Default estimate
    }
  }
}

/// Represents a cached entry with metadata.
class CacheEntry {
  final dynamic value;
  final DateTime createdAt;
  final Duration ttl;
  final int estimatedSize;
  DateTime lastAccessed;
  int accessCount;

  CacheEntry({
    required this.value,
    required this.createdAt,
    required this.ttl,
    required this.estimatedSize,
  })  : lastAccessed = DateTime.now(),
        accessCount = 1;

  bool isExpired(DateTime now) {
    return now.difference(createdAt) > ttl;
  }
}

/// Cache statistics for monitoring and debugging.
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int totalSize;
  final int maxSize;

  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.totalSize,
    required this.maxSize,
  });

  double get hitRatio {
    if (totalEntries == 0) return 0.0;
    return validEntries / totalEntries;
  }

  double get fillRatio {
    if (maxSize == 0) return 0.0;
    return totalEntries / maxSize;
  }

  @override
  String toString() {
    return '''
Cache Statistics:
- Total Entries: $totalEntries
- Valid Entries: $validEntries
- Expired Entries: $expiredEntries
- Total Size: ${_formatBytes(totalSize)}
- Max Size: $maxSize entries
- Hit Ratio: ${(hitRatio * 100).toStringAsFixed(1)}%
- Fill Ratio: ${(fillRatio * 100).toStringAsFixed(1)}%
''';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// Mixin for adding caching capabilities to DataFrame operations.
mixin DataFrameCaching on DataFrame {
  /// Caches the result of an expensive DataFrame operation.
  T cacheOperation<T>(
    String operationName,
    T Function() operation, {
    List<String>? additionalKeyComponents,
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    return CacheManager.cacheDataFrameOperation(
      this,
      operationName,
      operation,
      additionalKeyComponents: additionalKeyComponents,
      ttl: ttl,
      forceRefresh: forceRefresh,
    );
  }

  /// Invalidates all cached operations for this DataFrame.
  void invalidateCache() {
    CacheManager.invalidateDataFrameCache(this);
  }
}

/// Mixin for adding caching capabilities to Series operations.
mixin SeriesCaching on Series {
  /// Caches the result of an expensive Series operation.
  T cacheOperation<T>(
    String operationName,
    T Function() operation, {
    List<String>? additionalKeyComponents,
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    return CacheManager.cacheSeriesOperation(
      this,
      operationName,
      operation,
      additionalKeyComponents: additionalKeyComponents,
      ttl: ttl,
      forceRefresh: forceRefresh,
    );
  }

  /// Invalidates all cached operations for this Series.
  void invalidateCache() {
    CacheManager.invalidateSeriesCache(this);
  }
}

/// Extension methods for DataFrame caching.
extension DataFrameCachingExtension on DataFrame {
  /// Caches the result of correlation calculation.
  DataFrame cachedCorr({
    String method = 'pearson',
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    return CacheManager.cacheDataFrameOperation(
      this,
      'corr',
      () {
        // This would call the actual correlation method
        // For now, we'll return a placeholder
        throw UnimplementedError('Correlation method not implemented yet');
      },
      additionalKeyComponents: [method],
      ttl: ttl,
      forceRefresh: forceRefresh,
    );
  }

  /// Caches the result of statistical description.
  DataFrame cachedDescribe({
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    return CacheManager.cacheDataFrameOperation(
      this,
      'describe',
      () {
        // This would call the actual describe method
        // For now, we'll return a placeholder
        throw UnimplementedError('Describe method not implemented yet');
      },
      ttl: ttl,
      forceRefresh: forceRefresh,
    );
  }
}

/// Extension methods for Series caching.
extension SeriesCachingExtension on Series {
  /// Caches the result of value counts calculation.
  Series cachedValueCounts({
    bool normalize = false,
    bool sort = true,
    bool ascending = false,
    bool dropna = true,
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    return CacheManager.cacheSeriesOperation(
      this,
      'value_counts',
      () => valueCounts(
        normalize: normalize,
        sort: sort,
        ascending: ascending,
        dropna: dropna,
      ),
      additionalKeyComponents: [
        normalize.toString(),
        sort.toString(),
        ascending.toString(),
        dropna.toString(),
      ],
      ttl: ttl,
      forceRefresh: forceRefresh,
    );
  }

  /// Caches the result of unique values calculation.
  List<dynamic> cachedUnique({
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    return CacheManager.cacheSeriesOperation(
      this,
      'unique',
      () {
        Set<dynamic> uniqueSet = {};
        for (dynamic value in data) {
          if (value != null) {
            uniqueSet.add(value);
          }
        }
        return uniqueSet.toList();
      },
      ttl: ttl,
      forceRefresh: forceRefresh,
    );
  }
}
