import 'package:dartframe/dartframe.dart';
import 'dart:math' as math;

void main() async {
  print('=== Large Dataset Handling Examples ===\n');

  // 1. Creating Large Arrays Efficiently
  print('1. Creating Large Arrays');
  print('-' * 40);

  // Create large arrays
  final largeArray = NDArray.zeros([10000, 1000]);
  print('Large array: ${largeArray.shape}');
  print('Memory usage: ~${(10000 * 1000 * 8) ~/ 1024 ~/ 1024} MB');
  print('Note: dtype parameter not yet implemented\n');

  // 2. Batch Processing
  print('2. Batch Processing');
  print('-' * 40);

  // Simulate processing large dataset in batches
  final totalRows = 100000;
  final batchSize = 10000;
  final cols = 50;

  print('Processing $totalRows rows in batches of $batchSize');

  var totalSum = 0.0;
  for (int start = 0; start < totalRows; start += batchSize) {
    final end = (start + batchSize < totalRows) ? start + batchSize : totalRows;
    final batchRows = end - start;

    // Generate batch
    final batch = NDArray.generate(
      [batchRows, cols],
      (indices) => indices[0] + indices[1],
    );

    // Process batch
    final batchSum = batch.sum().toDouble();
    totalSum += batchSum;

    print('Processed rows $start-$end, batch sum: $batchSum');
  }

  print('Total sum: $totalSum\n');

  // 3. Memory-Mapped Files (Simulated)
  print('3. Memory-Mapped File Operations');
  print('-' * 40);

  // Create a moderately large array
  final data = NDArray.generate(
    [1000, 100],
    (indices) => indices[0] * 100 + indices[1],
  );

  print('Created array: ${data.shape}');
  print('Note: save/load methods not yet implemented');
  print('Would save to file and load back for verification\n');

  // TO DO: Implement save/load methods
  // await data.save(filename);
  // final loaded = await NDArray.load(filename);

  // 4. Compression for Storage
  print('4. Compression for Storage');
  print('-' * 40);

  // Create sample data
  final compressible = NDArray.generate(
    [1000, 100],
    (indices) =>
        (indices[0] % 10).toDouble(), // Repetitive data compresses well
  );

  print('Array shape: ${compressible.shape}');
  print('Uncompressed size: ~${(1000 * 100 * 8) ~/ 1024} KB');
  print('Note: Compression with save not yet implemented');
  print('Would save with compression and check file size\n');

  // TO DO: Implement save with compression
  // await compressible.save(compressedFile, compression: ZstdCodec(level: 3));

  // 5. Chunked Reading
  print('5. Chunked Reading');
  print('-' * 40);

  // Create a large dataset
  final fullData = NDArray.generate(
    [10000, 100],
    (indices) => indices[0] + indices[1],
  );

  print('Full dataset: ${fullData.shape}');

  // Read only a chunk
  final chunk = fullData.slice([
    Slice.range(1000, 2000), // Rows 1000-1999
    Slice.range(0, 50), // First 50 columns
  ]) as NDArray;

  print('Chunk shape: ${chunk.shape}');
  print('Chunk mean: ${chunk.mean()}\n');

  // 6. Efficient Aggregations
  print('6. Efficient Aggregations on Large Data');
  print('-' * 40);

  final timeSeries = DataCube.generate(
    365, // Days
    1000, // Sensors
    10, // Measurements per sensor
    (d, s, m) => 20.0 + (d % 30) + (s % 10) + m,
  );

  print('Time series shape: ${timeSeries.shape}');
  print('Total data points: ${365 * 1000 * 10}');

  // Aggregate by day (axis 1 and 2)
  print('\nComputing daily averages...');
  print('Daily averages computed');

  // Find extreme days
  final dailyMeans = <int, double>{};
  for (int day = 0; day < 365; day++) {
    final dayFrame = timeSeries.getFrame(day);
    final allValues = dayFrame.rows.expand((row) => row).whereType<num>();
    final mean = allValues.isEmpty
        ? 0
        : allValues.reduce((a, b) => a + b) / allValues.length;
    dailyMeans[day] = mean.toDouble();
  }

  final hottest =
      dailyMeans.entries.reduce((a, b) => a.value > b.value ? a : b);
  final coldest =
      dailyMeans.entries.reduce((a, b) => a.value < b.value ? a : b);

  print('Hottest day: ${hottest.key} (${hottest.value.toStringAsFixed(2)}°C)');
  print(
      'Coldest day: ${coldest.key} (${coldest.value.toStringAsFixed(2)}°C)\n');

  // 7. Parallel Processing Simulation
  print('7. Parallel Processing Pattern');
  print('-' * 40);

  // Simulate processing multiple files in parallel
  final fileCount = 5;
  print('Processing $fileCount datasets in parallel...');

  final futures = List.generate(fileCount, (i) async {
    // Simulate loading and processing
    await Future.delayed(Duration(milliseconds: 100));

    final dataset = NDArray.generate(
      [1000, 100],
      (indices) => i * 1000 + indices[0] + indices[1],
    );

    return dataset.sum();
  });

  final results = await Future.wait(futures);
  print('Results: $results');
  print('Total: ${results.reduce((a, b) => a + b)}\n');

  // 8. Streaming Computation
  print('8. Streaming Computation');
  print('-' * 40);

  // Process data in a streaming fashion
  print('Computing running statistics...');

  var count = 0;
  var sum = 0.0;
  var sumSquares = 0.0;

  // Simulate streaming data
  for (int batch = 0; batch < 10; batch++) {
    final batchData = NDArray.generate(
      [1000],
      (indices) => 50.0 + (indices[0] % 20) - 10,
    );

    count += batchData.size;
    sum += batchData.sum().toDouble();

    // Compute sum of squares for std dev
    final squared = batchData.map((x) => x * x);
    sumSquares += squared.sum().toDouble();
  }

  final mean = sum / count;
  final variance = (sumSquares / count) - (mean * mean);
  final stdDev = math.sqrt(variance);

  print('Processed $count values');
  print('Mean: ${mean.toStringAsFixed(2)}');
  print('Std Dev: ${stdDev.toStringAsFixed(2)}\n');

  // 9. Memory-Efficient Filtering
  print('9. Memory-Efficient Filtering');
  print('-' * 40);

  // Instead of loading all data, filter during generation
  print('Filtering large dataset during generation...');

  final threshold = 500;
  final filtered = <double>[];

  // Generate and filter in one pass
  for (int i = 0; i < 10000; i++) {
    final value = i % 1000;
    if (value > threshold) {
      filtered.add(value.toDouble());
    }
  }

  final result = NDArray(filtered);
  print('Generated 10000 values, kept ${result.size} after filtering');
  print('Filtered mean: ${result.mean()}\n');

  // 10. Practical Example: Log File Analysis
  print('10. Practical Example: Large Log Analysis');
  print('-' * 40);

  // Simulate analyzing large log file data
  final logEntries = 1000000;
  final logBatchSize = 100000;

  print('Analyzing $logEntries log entries...');

  var errorCount = 0;
  var warningCount = 0;
  var totalResponseTime = 0.0;

  for (int start = 0; start < logEntries; start += logBatchSize) {
    final end =
        (start + logBatchSize < logEntries) ? start + logBatchSize : logEntries;

    // Simulate log data: [timestamp, level, response_time]
    // level: 0=info, 1=warning, 2=error
    final batch = NDArray.generate(
      [end - start, 3],
      (indices) {
        if (indices[1] == 0) return start + indices[0]; // timestamp
        if (indices[1] == 1) {
          return (indices[0] % 10 < 1)
              ? 2
              : (indices[0] % 10 < 3)
                  ? 1
                  : 0; // level
        }
        return 100 + (indices[0] % 200); // response time
      },
    );

    // Count errors and warnings
    final levels = batch.slice([Slice.range(0, end - start), Slice.range(1, 2)])
        as NDArray;
    errorCount += levels.countWhere((x) => x == 2);
    warningCount += levels.countWhere((x) => x == 1);

    // Sum response times
    final responseTimes = batch
        .slice([Slice.range(0, end - start), Slice.range(2, 3)]) as NDArray;
    totalResponseTime += responseTimes.sum().toDouble();

    if ((start + logBatchSize) % 200000 == 0) {
      print('Processed ${start + logBatchSize} entries...');
    }
  }

  print('\nAnalysis Results:');
  print('Total entries: $logEntries');
  print(
      'Errors: $errorCount (${(errorCount / logEntries * 100).toStringAsFixed(2)}%)');
  print(
      'Warnings: $warningCount (${(warningCount / logEntries * 100).toStringAsFixed(2)}%)');
  print(
      'Avg response time: ${(totalResponseTime / logEntries).toStringAsFixed(2)}ms');

  print('\n=== Examples Complete ===');
}
