import 'dart:math';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dartframe/dartframe.dart'; // Assuming this is the correct import path

// Helper for generating random data
final Random _random = Random(42); // Seed for reproducibility

// --- Creation Benchmarks ---
class DataFrameCreationFromMapBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  late Map<String, List<dynamic>> dataMap;

  DataFrameCreationFromMapBenchmark(this.rows, this.cols)
      : super('DataFrame.creation.fromMap(rows:$rows,cols:$cols)');

  @override
  void setup() {
    dataMap = {};
    for (int j = 0; j < cols; j++) {
      if (j % 3 == 0) {
        dataMap['col_$j'] = List.generate(rows, (i) => _random.nextInt(rows));
      } else if (j % 3 == 1) {
        dataMap['col_$j'] = List.generate(rows, (i) => _random.nextDouble() * rows);
      } else {
        dataMap['col_$j'] = List.generate(rows, (i) => 'val_${_random.nextInt(rows)}');
      }
    }
  }

  @override
  void run() {
    DataFrame.fromMap(dataMap);
  }
}

class DataFrameCreationFromRowsBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  late List<Map<String, dynamic>> rowMaps;

  DataFrameCreationFromRowsBenchmark(this.rows, this.cols)
      : super('DataFrame.creation.fromRows(rows:$rows,cols:$cols)');

  @override
  void setup() {
    rowMaps = List.generate(rows, (i) {
      Map<String, dynamic> row = {};
      for (int j = 0; j < cols; j++) {
        if (j % 3 == 0) {
          row['col_$j'] = _random.nextInt(rows);
        } else if (j % 3 == 1) {
          row['col_$j'] = _random.nextDouble() * rows;
        } else {
          row['col_$j'] = 'val_${_random.nextInt(rows)}';
        }
      }
      return row;
    });
  }

  @override
  void run() {
    DataFrame.fromRows(rowMaps);
  }
}

class DataFrameCreationFromCSVStringBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  late String csvString;

  DataFrameCreationFromCSVStringBenchmark(this.rows, this.cols)
      : super('DataFrame.creation.fromCSVString(rows:$rows,cols:$cols)');

  @override
  void setup() {
    final buffer = StringBuffer();
    // Header
    buffer.writeln(List.generate(cols, (j) => 'col_$j').join(','));
    // Data
    for (int i = 0; i < rows; i++) {
      buffer.writeln(List.generate(cols, (j) {
        if (j % 3 == 0) return _random.nextInt(rows).toString();
        if (j % 3 == 1) return (_random.nextDouble() * rows).toStringAsFixed(2);
        return 'val_${_random.nextInt(rows)}';
      }).join(','));
    }
    csvString = buffer.toString();
  }

  @override
  void run() {
    DataFrame.fromCSV(csv: csvString);
  }
}

// --- Column Access Benchmarks ---
class DataFrameColumnAccessByNameBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  late DataFrame df;
  late String columnToAccess;

  DataFrameColumnAccessByNameBenchmark(this.rows, this.cols)
      : super('DataFrame.columnAccess.byName(rows:$rows,cols:$cols)');

  @override
  void setup() {
    final Map<String, List<dynamic>> dataMap = {};
    for (int j = 0; j < cols; j++) {
      dataMap['col_$j'] = List.generate(rows, (i) => i);
    }
    df = DataFrame.fromMap(dataMap);
    columnToAccess = 'col_${cols ~/ 2}'; // Access a column in the middle
  }

  @override
  void run() {
    // ignore: unused_local_variable
    Series s = df[columnToAccess];
  }
}

class DataFrameColumnAssignmentBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  late DataFrame df;
  late Series seriesToAssign;

  DataFrameColumnAssignmentBenchmark(this.rows, this.cols)
      : super('DataFrame.columnAssignment(rows:$rows,cols:$cols)');
  
  @override
  void setup() {
    final Map<String, List<dynamic>> dataMap = {};
    for (int j = 0; j < cols; j++) {
      dataMap['col_$j'] = List.generate(rows, (i) => i);
    }
    df = DataFrame.fromMap(dataMap);
    seriesToAssign = Series(List.generate(rows, (i) => i + 100), name: 'newCol');
  }

  @override
  void run() {
    df['newCol'] = seriesToAssign;
  }

  @override
  void teardown() {
    // Potentially remove the column if it interferes with next setup for same df instance
    // However, benchmark_harness creates new instance for each run by default.
  }
}

// --- Row Access Benchmarks ---
class DataFrameRowAccessIlocBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  late DataFrame df;
  late int indexToAccess;
  late List<int> indicesToAccess;


  DataFrameRowAccessIlocBenchmark(this.rows, this.cols)
      : super('DataFrame.rowAccess.iloc(rows:$rows,cols:$cols)');

  @override
  void setup() {
    final Map<String, List<dynamic>> dataMap = {};
    for (int j = 0; j < cols; j++) {
      dataMap['col_$j'] = List.generate(rows, (i) => i);
    }
    df = DataFrame.fromMap(dataMap);
    indexToAccess = rows ~/ 2;
    indicesToAccess = [0, rows ~/ 2, rows -1];
    if (rows < 3) indicesToAccess = [0];
     if (rows == 0) indicesToAccess = []; // Handle empty case
  }

  @override
  void run() {
    if (rows == 0) return; // Avoid error on empty
    // ignore: unused_local_variable
    var row = df.iloc[indexToAccess]; // Access single row
    // ignore: unused_local_variable
    var multiRows = df.iloc[indicesToAccess]; // Access multiple rows
  }
}

class DataFrameRowAccessLocBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  late DataFrame df;
  late String labelToAccess;
  late List<String> labelsToAccess;

  DataFrameRowAccessLocBenchmark(this.rows, this.cols)
      : super('DataFrame.rowAccess.loc(rows:$rows,cols:$cols)');
  
  @override
  void setup() {
    final Map<String, List<dynamic>> dataMap = {};
    for (int j = 0; j < cols; j++) {
      dataMap['col_$j'] = List.generate(rows, (i) => i);
    }
    final index = List.generate(rows, (i) => 'idx_$i');
    df = DataFrame.fromMap(dataMap, index: index);
    
    if (rows > 0) {
      labelToAccess = 'idx_${rows ~/ 2}';
      labelsToAccess = ['idx_0', 'idx_${rows ~/2}', 'idx_${rows-1}'];
      if (rows < 3) labelsToAccess = ['idx_0'];
    } else {
      labelToAccess = 'idx_dummy'; // Avoid null error, though it won't be accessed
      labelsToAccess = [];
    }
  }

  @override
  void run() {
    if (rows == 0) return; // Avoid error on empty
    // ignore: unused_local_variable
    var row = df.loc[labelToAccess];
    // ignore: unused_local_variable
    var multiRows = df.loc[labelsToAccess];
  }
}

// --- groupBy() Benchmarks ---
class DataFrameGroupByOneColumnAggregateMeanBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  final int numGroups;
  late DataFrame df;

  DataFrameGroupByOneColumnAggregateMeanBenchmark(this.rows, this.cols, this.numGroups)
      : super('DataFrame.groupBy.oneColMean(rows:$rows,cols:$cols,groups:$numGroups)');

  @override
  void setup() {
    final Map<String, List<dynamic>> dataMap = {};
    dataMap['groupKey'] = List.generate(rows, (i) => 'group_${_random.nextInt(numGroups)}');
    for (int j = 1; j < cols; j++) { // One key, rest numerical
      dataMap['valCol_$j'] = List.generate(rows, (i) => _random.nextDouble() * 100);
    }
    df = DataFrame.fromMap(dataMap);
  }

  @override
  void run() {
    if (rows == 0 || cols <=1 ) return;
    df.groupBy('groupKey');
  }
}

class DataFrameGroupByMultipleColumnsAggregateSumBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  final int numGroups1;
  final int numGroups2;
  late DataFrame df;

  DataFrameGroupByMultipleColumnsAggregateSumBenchmark(this.rows, this.cols, this.numGroups1, this.numGroups2)
      : super('DataFrame.groupBy.multiColSum(rows:$rows,cols:$cols,g1:$numGroups1,g2:$numGroups2)');
  
  @override
  void setup() {
    final Map<String, List<dynamic>> dataMap = {};
    dataMap['groupKey1'] = List.generate(rows, (i) => 'g1_${_random.nextInt(numGroups1)}');
    dataMap['groupKey2'] = List.generate(rows, (i) => 'g2_${_random.nextInt(numGroups2)}');
    for (int j = 2; j < cols; j++) { // Two keys, rest numerical
      dataMap['valCol_$j'] = List.generate(rows, (i) => _random.nextInt(100));
    }
    df = DataFrame.fromMap(dataMap);
  }

  @override
  void run() {
    if (rows == 0 || cols <= 2) return;
    df.groupByAgg(['groupKey1', 'groupKey2'],{'groupKey1': 'sum', 'groupKey2':'sum'});
  }
}

// --- Concatenate Benchmarks ---
class DataFrameConcatenateRowsBenchmark extends BenchmarkBase {
  final int rows1, cols, rows2;
  late DataFrame df1, df2;

  DataFrameConcatenateRowsBenchmark(this.rows1, this.cols, this.rows2)
      : super('DataFrame.concatenate.rows(r1:$rows1,c:$cols,r2:$rows2)');

  @override
  void setup() {
    final Map<String, List<dynamic>> map1 = {};
    for (int j = 0; j < cols; j++) {
      map1['col_$j'] = List.generate(rows1, (i) => i);
    }
    df1 = DataFrame.fromMap(map1);

    final Map<String, List<dynamic>> map2 = {};
    for (int j = 0; j < cols; j++) {
      map2['col_$j'] = List.generate(rows2, (i) => i + rows1);
    }
    df2 = DataFrame.fromMap(map2);
  }

  @override
  void run() {
    df1.concatenate([df2],  axis: 0);
  }
}

class DataFrameConcatenateColsBenchmark extends BenchmarkBase {
  final int rows, cols1, cols2;
  late DataFrame df1, df2;

  DataFrameConcatenateColsBenchmark(this.rows, this.cols1, this.cols2)
      : super('DataFrame.concatenate.cols(r:$rows,c1:$cols1,c2:$cols2)');

  @override
  void setup() {
    final Map<String, List<dynamic>> map1 = {};
    for (int j = 0; j < cols1; j++) {
      map1['colA_$j'] = List.generate(rows, (i) => i);
    }
    df1 = DataFrame.fromMap(map1);

    final Map<String, List<dynamic>> map2 = {};
    for (int j = 0; j < cols2; j++) {
      map2['colB_$j'] = List.generate(rows, (i) => i * 2);
    }
    df2 = DataFrame.fromMap(map2);
  }

  @override
  void run() {
    df1.concatenate([df2],  axis: 1);
  }
}

// --- Filtering Benchmarks ---
class DataFrameFilterOneConditionBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  late dynamic df;

  DataFrameFilterOneConditionBenchmark(this.rows, this.cols)
      : super('DataFrame.filter.oneCondition(rows:$rows,cols:$cols)');

  @override
  void setup() {
    final Map<String, List<dynamic>> dataMap = {};
    for (int j = 0; j < cols; j++) {
      dataMap['col_$j'] = List.generate(rows, (i) => _random.nextInt(rows));
    }
    df = DataFrame.fromMap(dataMap);
  }

  @override
  void run() {
    if (rows == 0 || cols == 0) return;
    // ignore: unused_local_variable
    var filtered = df[df['col_0'] > (rows / 2)];
  }
}

class DataFrameFilterMultipleConditionsBenchmark extends BenchmarkBase {
  final int rows;
  final int cols;
  late dynamic df;

  DataFrameFilterMultipleConditionsBenchmark(this.rows, this.cols)
      : super('DataFrame.filter.multiConditions(rows:$rows,cols:$cols)');
  
  @override
  void setup() {
    final Map<String, List<dynamic>> dataMap = {};
     dataMap['col_0'] = List.generate(rows, (i) => _random.nextInt(rows));
     dataMap['col_1'] = List.generate(rows, (i) => _random.nextDouble() * rows);
    for (int j = 2; j < cols; j++) {
      dataMap['col_$j'] = List.generate(rows, (i) => 'val_$i');
    }
    df = DataFrame.fromMap(dataMap);
  }

  @override
  void run() {
    if (rows == 0 || cols < 2) return;
    // ignore: unused_local_variable
    var filtered = df[(df['col_0'] > (rows * 0.25)) & (df['col_1'] < (rows * 0.75))];
  }
}


void main() {
  final rowCounts = [1000, 10000, 100000, 1000000]; // Updated row counts
  final colCounts = [5, 20];
  final groupCounts = [5, 50]; // Number of distinct groups

  // Add an empty DataFrame case for robustness checks on creation/access
  DataFrameCreationFromMapBenchmark(0,0).report();
  DataFrameRowAccessIlocBenchmark(0,0).report();
  DataFrameRowAccessLocBenchmark(0,0).report();


  for (var r in rowCounts) {
    for (var c in colCounts) {
      DataFrameCreationFromMapBenchmark(r, c).report();
      DataFrameCreationFromRowsBenchmark(r, c).report();
      DataFrameCreationFromCSVStringBenchmark(r, c).report();

      if (c > 0) { // Column access needs at least one column
        DataFrameColumnAccessByNameBenchmark(r, c).report();
        DataFrameColumnAssignmentBenchmark(r, c).report();
      }
      
      //DataFrameRowAccessIlocBenchmark(r, c).report();
      DataFrameRowAccessLocBenchmark(r, c).report();

      if (c > 1) { // Need at least one value column for aggregation
        for (var g in groupCounts) {
          if (g > 0 && g <= r) { // Number of groups should be positive and not exceed rows
             DataFrameGroupByOneColumnAggregateMeanBenchmark(r, c, g).report();
             if (c > 2 && g*g <=r) { // Need at least one value column for multi-group
                DataFrameGroupByMultipleColumnsAggregateSumBenchmark(r, c, g, g).report();
             }
          }
        }
      }
      
      if (c > 0) { // Filtering needs at least one column
        //DataFrameFilterOneConditionBenchmark(r, c).report();
      }
      if (c > 1) { // Multi-condition filter needs at least two columns
        //DataFrameFilterMultipleConditionsBenchmark(r, c).report();
      }
    }
  }
  
  // Concatenate benchmarks with specific sizes
  DataFrameConcatenateRowsBenchmark(5000, 10, 5000).report();
  DataFrameConcatenateColsBenchmark(5000, 5, 5).report();
  DataFrameConcatenateRowsBenchmark(10000, 5, 10000).report();
  DataFrameConcatenateColsBenchmark(10000, 3, 7).report();
}
