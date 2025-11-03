/// Native platform implementation (with isolates)
library;

import 'dart:isolate';
import 'dart:math' as math;
import '../series/series.dart';
import '../data_frame/data_frame.dart';

/// Platform information for native platforms
Map<String, dynamic> getPlatformInfo() {
  return {
    'isWeb': false,
    'supportsIsolates': true,
    'supportsParallelProcessing': true,
    'recommendedChunkSize': 1000,
    'platform': 'native',
  };
}

/// Native implementation - uses isolates for parallel processing
Future<Series> parallelApply(
  Series series,
  dynamic Function(dynamic) func,
  int chunkSize,
) async {
  List<dynamic> data = series.data;

  try {
    List<Future<List<dynamic>>> futures = [];

    for (int i = 0; i < data.length; i += chunkSize) {
      int end = math.min(i + chunkSize, data.length);
      List<dynamic> chunk = data.sublist(i, end);

      futures.add(Isolate.run(() {
        return chunk.map(func).toList();
      }));
    }

    List<List<dynamic>> results = await Future.wait(futures);
    List<dynamic> flatResult = results.expand((chunk) => chunk).toList();

    return Series(flatResult, name: series.name, index: series.index);
  } catch (e) {
    // Fallback to synchronous processing if isolates fail
    List<dynamic> result = [];
    for (dynamic value in series.data) {
      result.add(func(value));
    }
    return Series(result, name: series.name, index: series.index);
  }
}

/// Native implementation for DataFrame row operations using isolates
Future<List<dynamic>> parallelApplyDataFrameRows(
  DataFrame df,
  dynamic Function(Map<String, dynamic>) func,
  int chunkSize,
) async {
  try {
    List<Future<List<dynamic>>> futures = [];

    for (int i = 0; i < df.rowCount; i += chunkSize) {
      int end = math.min(i + chunkSize, df.rowCount);

      // Capture the data we need for the isolate
      Map<String, List<dynamic>> chunkData = {};
      List<String> columnNames = df.columns.cast<String>();

      // Extract column data for the chunk
      for (String columnName in columnNames) {
        List<dynamic> columnData = df[columnName].data;
        chunkData[columnName] = columnData.sublist(i, end);
      }

      futures.add(Isolate.run(() {
        List<dynamic> chunkResults = [];
        int chunkSize = chunkData[columnNames.first]!.length;

        for (int idx = 0; idx < chunkSize; idx++) {
          Map<String, dynamic> row = {};
          for (String columnName in columnNames) {
            row[columnName] = chunkData[columnName]![idx];
          }
          chunkResults.add(func(row));
        }
        return chunkResults;
      }));
    }

    List<List<dynamic>> results = await Future.wait(futures);
    return results.expand((chunk) => chunk).toList();
  } catch (e) {
    // Fallback to synchronous processing if isolates fail
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
}
