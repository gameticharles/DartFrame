/// Web platform implementation (no isolates)
library;

import '../series/series.dart';
import '../data_frame/data_frame.dart';

/// Platform information for web
Map<String, dynamic> getPlatformInfo() {
  return {
    'isWeb': true,
    'supportsIsolates': false,
    'supportsParallelProcessing': false,
    'recommendedChunkSize': 10000,
    'platform': 'web',
  };
}

/// Web implementation - uses synchronous processing (no isolates available)
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

/// Web implementation for DataFrame row operations
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
