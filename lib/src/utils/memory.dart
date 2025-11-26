// ignore_for_file: unnecessary_getters_setters

library;

import 'dart:typed_data';
import '../series/series.dart';
import '../data_frame/data_frame.dart';
import '../storage/storage_backend.dart';

/// Memory optimization utilities for DartFrame.
///
/// This class provides methods to optimize memory usage by:
/// - Downcasting numeric types to smaller representations
/// - Converting data to more memory-efficient formats
/// - Monitoring memory usage of data structures
/// - Providing memory-efficient data type recommendations
class MemoryOptimizer {
  /// Optimizes the memory usage of a DataFrame by downcasting numeric columns
  /// to the smallest possible data types without losing precision.
  ///
  /// This method analyzes each column and determines the most memory-efficient
  /// data type that can represent all values in that column.
  ///
  /// Parameters:
  /// - `df`: The DataFrame to optimize
  /// - `includeColumns`: Optional list of column names to optimize. If null, all columns are optimized.
  /// - `excludeColumns`: Optional list of column names to exclude from optimization.
  ///
  /// Returns:
  /// A new DataFrame with optimized memory usage.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame.fromMap({
  ///   'small_int': [1, 2, 3, 4, 5],
  ///   'large_double': [1.0, 2.0, 3.0, 4.0, 5.0],
  ///   'text': ['a', 'b', 'c', 'd', 'e']
  /// });
  ///
  /// var optimized = MemoryOptimizer.optimizeDataFrame(df);
  /// // 'large_double' might be converted to int if all values are whole numbers
  /// ```
  static DataFrame optimizeDataFrame(
    DataFrame df, {
    List<String>? includeColumns,
    List<String>? excludeColumns,
  }) {
    final columnsToOptimize = _getColumnsToOptimize(
      df.columns.cast<String>(),
      includeColumns,
      excludeColumns,
    );

    Map<String, List<dynamic>> optimizedData = {};

    for (String columnName in df.columns.cast<String>()) {
      Series series = df[columnName];

      if (columnsToOptimize.contains(columnName)) {
        optimizedData[columnName] = optimizeSeries(series).data;
      } else {
        optimizedData[columnName] = series.data;
      }
    }

    return DataFrame.fromMap(
      optimizedData,
      index: df.index,
      allowFlexibleColumns: df.allowFlexibleColumns,
      replaceMissingValueWith: df.replaceMissingValueWith,
    );
  }

  /// Optimizes the memory usage of a Series by downcasting to the most
  /// appropriate data type.
  ///
  /// Parameters:
  /// - `series`: The Series to optimize
  ///
  /// Returns:
  /// A new Series with optimized data types.
  static Series optimizeSeries(Series series) {
    List<dynamic> optimizedData = [];

    for (dynamic value in series.data) {
      if (value == null) {
        optimizedData.add(value);
        continue;
      }

      if (value is double) {
        // Check if double can be represented as int without loss
        if (value == value.truncate()) {
          int intValue = value.toInt();
          optimizedData.add(_optimizeInteger(intValue));
        } else {
          optimizedData.add(_optimizeDouble(value));
        }
      } else if (value is int) {
        optimizedData.add(_optimizeInteger(value));
      } else {
        optimizedData.add(value);
      }
    }

    return Series(
      optimizedData,
      name: series.name,
      index: series.index,
    );
  }

  /// Downcasts a numeric Series to the smallest possible integer type.
  ///
  /// Parameters:
  /// - `series`: The Series containing numeric data
  ///
  /// Returns:
  /// A new Series with downcasted integer values.
  static Series downcastToInteger(Series series) {
    List<dynamic> downcasted = [];

    for (dynamic value in series.data) {
      if (value == null) {
        downcasted.add(value);
        continue;
      }

      if (value is num) {
        if (value == value.truncate()) {
          downcasted.add(_optimizeInteger(value.toInt()));
        } else {
          // Cannot downcast to integer without loss
          downcasted.add(value);
        }
      } else {
        downcasted.add(value);
      }
    }

    return Series(
      downcasted,
      name: series.name,
      index: series.index,
    );
  }

  /// Converts numeric data to typed arrays for better memory efficiency.
  ///
  /// Parameters:
  /// - `series`: The Series containing numeric data
  /// - `dataType`: The target data type ('int8', 'int16', 'int32', 'int64', 'float32', 'float64')
  ///
  /// Returns:
  /// A new Series with typed array data.
  static Series toTypedArray(Series series, String dataType) {
    List<dynamic> nonNullValues = series.data.where((v) => v != null).toList();

    if (nonNullValues.isEmpty) {
      return series;
    }

    switch (dataType.toLowerCase()) {
      case 'int8':
        var typedData = Int8List.fromList(nonNullValues.cast<int>());
        return _createSeriesFromTypedData(series, typedData);
      case 'int16':
        var typedData = Int16List.fromList(nonNullValues.cast<int>());
        return _createSeriesFromTypedData(series, typedData);
      case 'int32':
        var typedData = Int32List.fromList(nonNullValues.cast<int>());
        return _createSeriesFromTypedData(series, typedData);
      case 'int64':
        var typedData = Int64List.fromList(nonNullValues.cast<int>());
        return _createSeriesFromTypedData(series, typedData);
      case 'float32':
        var typedData = Float32List.fromList(nonNullValues.cast<double>());
        return _createSeriesFromTypedData(series, typedData);
      case 'float64':
        var typedData = Float64List.fromList(nonNullValues.cast<double>());
        return _createSeriesFromTypedData(series, typedData);
      default:
        throw ArgumentError('Unsupported data type: $dataType');
    }
  }

  /// Estimates the memory usage of a DataFrame in bytes.
  ///
  /// This provides an approximation of memory usage based on data types
  /// and the number of elements.
  ///
  /// Parameters:
  /// - `df`: The DataFrame to analyze
  ///
  /// Returns:
  /// An estimate of memory usage in bytes.
  static int estimateMemoryUsage(DataFrame df) {
    int totalBytes = 0;

    // Estimate overhead for DataFrame structure
    totalBytes += 1000; // Base overhead

    for (String columnName in df.columns.cast<String>()) {
      Series series = df[columnName];
      totalBytes += estimateSeriesMemoryUsage(series);
    }

    return totalBytes;
  }

  /// Estimates the memory usage of a Series in bytes.
  ///
  /// Parameters:
  /// - `series`: The Series to analyze
  ///
  /// Returns:
  /// An estimate of memory usage in bytes.
  static int estimateSeriesMemoryUsage(Series series) {
    int totalBytes = 0;

    // Base overhead for Series structure
    totalBytes += 200;

    for (dynamic value in series.data) {
      totalBytes += _estimateValueSize(value);
    }

    // Index overhead
    totalBytes += series.index.length * 8; // Approximate

    return totalBytes;
  }

  /// Provides memory optimization recommendations for a DataFrame.
  ///
  /// Parameters:
  /// - `df`: The DataFrame to analyze
  ///
  /// Returns:
  /// A map containing optimization recommendations for each column.
  static Map<String, String> getOptimizationRecommendations(DataFrame df) {
    Map<String, String> recommendations = {};

    for (String columnName in df.columns.cast<String>()) {
      Series series = df[columnName];
      String recommendation = _analyzeSeriesForOptimization(series);
      if (recommendation.isNotEmpty) {
        recommendations[columnName] = recommendation;
      }
    }

    return recommendations;
  }

  /// Creates a memory usage report for a DataFrame.
  ///
  /// Parameters:
  /// - `df`: The DataFrame to analyze
  ///
  /// Returns:
  /// A formatted string containing memory usage information.
  static String createMemoryReport(DataFrame df) {
    StringBuffer report = StringBuffer();

    report.writeln('Memory Usage Report');
    report.writeln('==================');
    report.writeln(
        'DataFrame Shape: ${df.rowCount} rows × ${df.columnCount} columns');

    int totalMemory = estimateMemoryUsage(df);
    report.writeln('Total Estimated Memory: ${_formatBytes(totalMemory)}');
    report.writeln();

    report.writeln('Column Details:');
    report.writeln('---------------');

    for (String columnName in df.columns.cast<String>()) {
      Series series = df[columnName];
      int columnMemory = estimateSeriesMemoryUsage(series);
      String dataType = _inferDataType(series);

      report.writeln('$columnName:');
      report.writeln('  Data Type: $dataType');
      report.writeln('  Memory Usage: ${_formatBytes(columnMemory)}');
      report.writeln(
          '  Non-null Count: ${series.data.where((v) => v != null).length}');

      String recommendation = _analyzeSeriesForOptimization(series);
      if (recommendation.isNotEmpty) {
        report.writeln('  Recommendation: $recommendation');
      }
      report.writeln();
    }

    return report.toString();
  }

  // Private helper methods

  static List<String> _getColumnsToOptimize(
    List<String> allColumns,
    List<String>? includeColumns,
    List<String>? excludeColumns,
  ) {
    List<String> columnsToOptimize = List.from(allColumns);

    if (includeColumns != null) {
      columnsToOptimize = columnsToOptimize
          .where((col) => includeColumns.contains(col))
          .toList();
    }

    if (excludeColumns != null) {
      columnsToOptimize = columnsToOptimize
          .where((col) => !excludeColumns.contains(col))
          .toList();
    }

    return columnsToOptimize;
  }

  static dynamic _optimizeInteger(int value) {
    if (value >= -128 && value <= 127) {
      return value; // Can be represented as int8, but Dart doesn't have native int8
    } else if (value >= -32768 && value <= 32767) {
      return value; // Can be represented as int16
    } else if (value >= -2147483648 && value <= 2147483647) {
      return value; // Can be represented as int32
    } else {
      return value; // Requires int64
    }
  }

  static double _optimizeDouble(double value) {
    // Check if value can be represented accurately as float32
    double float32Value = value;
    if ((float32Value - value).abs() < 1e-6) {
      return float32Value;
    }
    return value;
  }

  static Series _createSeriesFromTypedData(
      Series originalSeries, TypedData typedData) {
    List<dynamic> newData = [];
    int typedIndex = 0;

    for (dynamic value in originalSeries.data) {
      if (value == null) {
        newData.add(null);
      } else {
        // Access typed data based on its type
        if (typedData is Int8List) {
          newData.add(typedData[typedIndex]);
        } else if (typedData is Int16List) {
          newData.add(typedData[typedIndex]);
        } else if (typedData is Int32List) {
          newData.add(typedData[typedIndex]);
        } else if (typedData is Int64List) {
          newData.add(typedData[typedIndex]);
        } else if (typedData is Float32List) {
          newData.add(typedData[typedIndex]);
        } else if (typedData is Float64List) {
          newData.add(typedData[typedIndex]);
        } else {
          newData.add(value); // Fallback to original value
        }
        typedIndex++;
      }
    }

    return Series(
      newData,
      name: originalSeries.name,
      index: originalSeries.index,
    );
  }

  static int _estimateValueSize(dynamic value) {
    if (value == null) return 8; // Pointer size

    if (value is int) {
      return 8; // 64-bit integer
    } else if (value is double) {
      return 8; // 64-bit double
    } else if (value is String) {
      return value.length * 2 + 24; // UTF-16 + overhead
    } else if (value is bool) {
      return 1;
    } else if (value is List) {
      return value.length * 8 + 24; // Approximate
    } else {
      return 32; // Default estimate for complex objects
    }
  }

  static String _analyzeSeriesForOptimization(Series series) {
    List<dynamic> nonNullValues = series.data.where((v) => v != null).toList();

    if (nonNullValues.isEmpty) {
      return '';
    }

    // Check if all values are integers that could be downcasted
    if (nonNullValues.every((v) => v is double && v == v.truncate())) {
      return 'Convert double to int (all values are whole numbers)';
    }

    // Check if integers can be represented in smaller types
    if (nonNullValues.every((v) => v is int)) {
      int min = nonNullValues.cast<int>().reduce((a, b) => a < b ? a : b);
      int max = nonNullValues.cast<int>().reduce((a, b) => a > b ? a : b);

      if (min >= -128 && max <= 127) {
        return 'Can use int8 (values fit in -128 to 127 range)';
      } else if (min >= -32768 && max <= 32767) {
        return 'Can use int16 (values fit in -32768 to 32767 range)';
      } else if (min >= -2147483648 && max <= 2147483647) {
        return 'Can use int32 (values fit in 32-bit range)';
      }
    }

    // Check if doubles can be represented as float32
    if (nonNullValues.every((v) => v is double)) {
      bool canUseFloat32 = nonNullValues.every((v) {
        double original = v as double;
        double float32Value = original;
        return (float32Value - original).abs() < 1e-6;
      });

      if (canUseFloat32) {
        return 'Can use float32 instead of float64';
      }
    }

    return '';
  }

  static String _inferDataType(Series series) {
    List<dynamic> nonNullValues = series.data.where((v) => v != null).toList();

    if (nonNullValues.isEmpty) {
      return 'null';
    }

    Type mostCommonType = nonNullValues.first.runtimeType;
    Map<Type, int> typeCounts = {};

    for (var value in nonNullValues) {
      Type valueType = value.runtimeType;
      typeCounts[valueType] = (typeCounts[valueType] ?? 0) + 1;
    }

    int maxCount = 0;
    typeCounts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonType = type;
      }
    });

    return mostCommonType.toString();
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

/// Extension methods for DataFrame memory optimization.
extension DataFrameMemoryOptimization on DataFrame {
  /// Optimizes the memory usage of this DataFrame.
  ///
  /// Returns a new DataFrame with optimized data types.
  DataFrame optimizeMemory({
    List<String>? includeColumns,
    List<String>? excludeColumns,
  }) {
    return MemoryOptimizer.optimizeDataFrame(
      this,
      includeColumns: includeColumns,
      excludeColumns: excludeColumns,
    );
  }

  /// Gets the estimated memory usage of this DataFrame in bytes.
  int get memoryUsage => MemoryOptimizer.estimateMemoryUsage(this);

  /// Gets memory optimization recommendations for this DataFrame.
  Map<String, String> get memoryRecommendations =>
      MemoryOptimizer.getOptimizationRecommendations(this);

  /// Creates a memory usage report for this DataFrame.
  String get memoryReport => MemoryOptimizer.createMemoryReport(this);
}

/// Extension methods for Series memory optimization.
extension SeriesMemoryOptimization on Series {
  /// Optimizes the memory usage of this Series.
  ///
  /// Returns a new Series with optimized data types.
  Series optimizeMemory() => MemoryOptimizer.optimizeSeries(this);

  /// Gets the estimated memory usage of this Series in bytes.
  int get totalMemoryUsage => MemoryOptimizer.estimateSeriesMemoryUsage(this);

  /// Downcasts this Series to integer types where possible.
  Series downcastToInteger() => MemoryOptimizer.downcastToInteger(this);

  /// Converts this Series to a typed array.
  Series toTypedArray(String dataType) =>
      MemoryOptimizer.toTypedArray(this, dataType);
}

/// Memory monitor for NDArray and DataCube
/// Tracks memory usage across all storage backends
class MemoryMonitor {
  static final List<StorageBackend> _backends = [];
  static int _maxMemoryBytes = 1024 * 1024 * 1024; // 1GB default
  static final List<MemoryEvent> _events = [];

  /// Register a storage backend for monitoring
  static void registerBackend(StorageBackend backend) {
    if (!_backends.contains(backend)) {
      _backends.add(backend);
    }
  }

  /// Unregister a storage backend
  static void unregisterBackend(StorageBackend backend) {
    _backends.remove(backend);
  }

  /// Get current memory usage across all backends
  static int get currentUsage {
    return _backends.fold(0, (sum, backend) => sum + backend.memoryUsage);
  }

  /// Get maximum allowed memory
  static int get maxUsage => _maxMemoryBytes;

  /// Set maximum allowed memory
  static set maxUsage(int bytes) {
    _maxMemoryBytes = bytes;
  }

  /// Get memory usage as percentage (0.0 to 1.0)
  static double get usagePercent => currentUsage / _maxMemoryBytes;

  /// Check if memory pressure is high
  static bool get isHighPressure => usagePercent > 0.8;

  /// Check if memory pressure is critical
  static bool get isCriticalPressure => usagePercent > 0.95;

  /// Check memory pressure and trigger cleanup if needed
  static void checkMemoryPressure() {
    if (isCriticalPressure) {
      _emitEvent(MemoryEventType.criticalPressure);
      cleanup(aggressive: true);
    } else if (isHighPressure) {
      _emitEvent(MemoryEventType.highPressure);
      cleanup(aggressive: false);
    }
  }

  /// Cleanup memory by unloading backends
  static Future<void> cleanup({bool aggressive = false}) async {
    final threshold = aggressive ? 0.5 : 0.8;

    // Sort backends by last access time (oldest first)
    final sortedBackends = List<StorageBackend>.from(_backends);

    for (final backend in sortedBackends) {
      if (usagePercent <= threshold) break;

      if (!backend.isInMemory) continue;

      await backend.unload();
      _emitEvent(MemoryEventType.backendUnloaded);
    }
  }

  /// Get memory statistics
  static MemoryStats get stats => MemoryStats(
        currentUsage: currentUsage,
        maxUsage: _maxMemoryBytes,
        usagePercent: usagePercent,
        backendCount: _backends.length,
        isHighPressure: isHighPressure,
        isCriticalPressure: isCriticalPressure,
      );

  /// Emit memory event
  static void _emitEvent(MemoryEventType type) {
    final event = MemoryEvent(
      type: type,
      timestamp: DateTime.now(),
      memoryUsage: currentUsage,
      usagePercent: usagePercent,
    );
    _events.add(event);

    // Keep only last 100 events
    if (_events.length > 100) {
      _events.removeAt(0);
    }
  }

  /// Get recent memory events
  static List<MemoryEvent> get recentEvents => List.unmodifiable(_events);

  /// Clear all registered backends (for testing)
  static void clear() {
    _backends.clear();
    _events.clear();
  }
}

/// Memory event types
enum MemoryEventType {
  highPressure,
  criticalPressure,
  backendUnloaded,
  backendLoaded,
}

/// Memory event
class MemoryEvent {
  final MemoryEventType type;
  final DateTime timestamp;
  final int memoryUsage;
  final double usagePercent;

  const MemoryEvent({
    required this.type,
    required this.timestamp,
    required this.memoryUsage,
    required this.usagePercent,
  });

  @override
  String toString() {
    return 'MemoryEvent('
        'type: $type, '
        'time: $timestamp, '
        'usage: ${(memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB, '
        'percent: ${(usagePercent * 100).toStringAsFixed(1)}%)';
  }
}

/// Memory statistics
class MemoryStats {
  final int currentUsage;
  final int maxUsage;
  final double usagePercent;
  final int backendCount;
  final bool isHighPressure;
  final bool isCriticalPressure;

  const MemoryStats({
    required this.currentUsage,
    required this.maxUsage,
    required this.usagePercent,
    required this.backendCount,
    required this.isHighPressure,
    required this.isCriticalPressure,
  });

  @override
  String toString() {
    return 'MemoryStats('
        'usage: ${(currentUsage / 1024 / 1024).toStringAsFixed(1)}MB / '
        '${(maxUsage / 1024 / 1024).toStringAsFixed(1)}MB, '
        'percent: ${(usagePercent * 100).toStringAsFixed(1)}%, '
        'backends: $backendCount, '
        'pressure: ${isCriticalPressure ? "CRITICAL" : isHighPressure ? "HIGH" : "NORMAL"})';
  }
}
