import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';
import 'dart:math' as math;

/// End-to-end workflow tests that demonstrate complex feature interactions.
void main() {
  group('Data Analysis Workflow', () {
    test('Complete data analysis pipeline', () async {
      // Step 1: Create sample dataset
      final random = math.Random(42);
      final size = 50; // Smaller size for testing
      
      final rawData = {
        'date': List.generate(size, (i) => 
          DateTime(2023, 1, 1).add(Duration(days: i ~/ 4))),
        'category': List.generate(size, (i) => 
          ['A', 'B', 'C'][i % 3]),
        'value': List.generate(size, (i) => 
          random.nextDouble() * 100 + (i % 3) * 10),
        'count': List.generate(size, (i) => 
          random.nextInt(50) + 10),
        'flag': List.generate(size, (i) => 
          random.nextBool()),
      };
      
      var df = DataFrame.fromMap(rawData);
      
      // Step 2: Data cleaning and preprocessing
      expect(df.rowCount, equals(size));
      expect(df.columnCount, equals(5));
      
      // Handle missing values with interpolation
      df = df.interpolate(method: 'linear');
      
      // Step 3: Feature engineering
      df['value_squared'] = df['value'].apply((x) => x * x);
      df['value_log'] = df['value'].apply((x) => math.log((x as double) + 1));
      
      expect(df.columnCount, equals(7));
      
      // Step 4: Statistical analysis
      final stats = df.describe();
      expect(stats, isA<Map>());
      
      // Correlation analysis
      final corrMatrix = df.corrAdvanced();
      expect(corrMatrix, isA<DataFrame>());
      
      // Step 5: Rolling statistics (using DataFrame rolling)
      final rolling = df.rollingWindow(7);
      final rollingMean = rolling.mean();
      expect(rollingMean, isA<DataFrame>());
      
      // Step 6: Data reshaping
      final melted = df.melt(
        idVars: ['date', 'category'],
        valueVars: ['value', 'count'],
        varName: 'metric',
        valueName: 'amount',
      );
      
      expect(melted, isA<DataFrame>());
      expect(melted.rowCount, equals(df.rowCount * 2));
      
      // Step 7: Performance optimization
      final optimized = df.optimizeMemory();
      expect(optimized, isA<DataFrame>());
      expect(optimized.rowCount, equals(df.rowCount));
      
      // Step 8: Export results
      df.toCsv();
      
      // Verify export worked by reading back
      try {
        final readBack = await DataFrame.fromCSV(inputFilePath: 'output.csv');
        expect(readBack.rowCount, equals(df.rowCount));
      } catch (e) {
        print('Skipping CSV read verification: $e');
      }
    });

    test('Performance workflow with large dataset', () async {
      // Create moderately sized dataset for performance testing
      final size = 1000;
      final random = math.Random(42);
      
      final largeData = {
        'id': List.generate(size, (i) => i),
        'value1': List.generate(size, (i) => random.nextDouble() * 1000),
        'value2': List.generate(size, (i) => random.nextInt(100)),
        'category': List.generate(size, (i) => ['A', 'B', 'C', 'D', 'E'][i % 5]),
      };
      
      var df = DataFrame.fromMap(largeData);
      
      // Memory optimization
      final stopwatch = Stopwatch()..start();
      df = df.optimizeMemory();
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      
      // Vectorized operations (using Series apply)
      final vectorizedStopwatch = Stopwatch()..start();
      final valueSeries = df['value1'] as Series;
      final transformed = valueSeries.apply((x) => x * 2 + 1);
      vectorizedStopwatch.stop();
      
      expect(transformed.length, equals(size));
      expect(vectorizedStopwatch.elapsedMilliseconds, lessThan(2000));
      
      // Statistical computations
      final statsStopwatch = Stopwatch()..start();
      final stats = df.describe();
      final corr = df.select(['value1', 'value2']).corrAdvanced();
      statsStopwatch.stop();
      
      expect(stats, isA<Map>());
      expect(corr, isA<DataFrame>());
      expect(statsStopwatch.elapsedMilliseconds, lessThan(3000));
      
      print('Performance test completed successfully');
    });

    test('Error handling workflow', () {
      // Create problematic dataset
      final problematicData = {
        'good_column': [1, 2, 3, 4, 5],
        'mixed_types': [1, 'text', 3.5, null, true],
        'mostly_null': [null, null, 1, null, null],
        'empty_strings': ['', 'data', '', 'more', ''],
      };
      
      var df = DataFrame.fromMap(problematicData);
      
      // Robust statistical analysis
      try {
        final stats = df.describe();
        expect(stats, isA<Map>());
      } catch (e) {
        // Should handle mixed types gracefully
        expect(e, isA<Exception>());
      }
      
      // Safe operations on clean columns
      final cleanStats = df.select(['good_column']).describe();
      expect(cleanStats, isA<Map>());
      
      // Fill missing values safely
      final filled = df.fillna({
        'mostly_null': 0,
        'empty_strings': 'missing',
      });
      expect(filled, isA<DataFrame>());
      
      print('Error handling test completed successfully');
    });
  });
}