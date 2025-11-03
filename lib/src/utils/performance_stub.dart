/// Stub implementation for unsupported platforms
library;

import '../series/series.dart';
import '../data_frame/data_frame.dart';

/// Platform information for stub implementation
Map<String, dynamic> getPlatformInfo() {
  return {
    'isWeb': false,
    'supportsIsolates': false,
    'supportsParallelProcessing': false,
    'recommendedChunkSize': 10000,
    'platform': 'unknown',
  };
}

/// Stub implementation - always uses synchronous processing
Future<Series> parallelApply(
  Series series,
  dynamic Function(dynamic) func,
  int chunkSize,
) async {
  List<dynamic> result = [];
  for (dynamic value in series.data) {
    result.add(func(value));
  }
  return Series(result, name: series.name, index: series.index);
}

/// Stub implementation for DataFrame row operations
Future<List<dynamic>> parallelApplyDataFrameRows(
  DataFrame df,
  dynamic Function(Map<String, dynamic>) func,
  int chunkSize,
) async {
  List<dynamic> results = [];
  for (int i = 0; i < df.rowCount; i++) {
    Map<String, dynamic> row = {};
    for (String columnName in df.columns.cast<String>()) {
      row[columnName] = df[columnName].data[i];
    }
    results.add(func(row));
  }
  return results;
}
