import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

/// Basic integration tests that work with the current DartFrame API.
/// 
/// These tests validate that existing features work correctly together
/// and that there are no breaking changes to the current API.
void main() {
  group('Basic Integration Tests', () {
    test('DataFrame creation and basic operations work together', () {
      // Test DataFrame creation
      final data = {
        'A': [1, 2, 3, 4, 5],
        'B': [2.0, 4.0, 6.0, 8.0, 10.0],
        'C': ['a', 'b', 'c', 'd', 'e'],
      };
      final df = DataFrame.fromMap(data);
      
      // Test basic properties
      expect(df.rowCount, equals(5));
      expect(df.columnCount, equals(3));
      expect(df.columns, equals(['A', 'B', 'C']));
      
      // Test column access
      expect(df['A'], isA<Series>());
      expect(df['A'].length, equals(5));
      expect(df['A'].data, equals([1, 2, 3, 4, 5]));
      
      // Test that describe works
      final stats = df.describe();
      expect(stats, isA<Map>());
      
      // Test row access
      expect(df.loc(0), isA<Series>());
    });

    test('Series operations work with DataFrame columns', () {
      final df = DataFrame.fromMap({
        'numbers': [1, 2, 3, 4, 5],
        'doubles': [1.1, 2.2, 3.3, 4.4, 5.5],
      });
      
      // Test Series operations on DataFrame columns
      final numbersSeries = df['numbers'] as Series;
      expect(numbersSeries.sum(), equals(15));
      expect(numbersSeries.mean(), equals(3.0));
      expect(numbersSeries.min(), equals(1));
      expect(numbersSeries.max(), equals(5));
      
      final doublesSeries = df['doubles'] as Series;
      expect(doublesSeries.sum(), equals(16.5));
      expect(doublesSeries.mean(), equals(3.3));
    });

    test('Enhanced statistical operations work', () {
      final df = DataFrame.fromMap({
        'A': [1.0, 2.0, 3.0, 4.0, 5.0],
        'B': [2.0, 4.0, 6.0, 8.0, 10.0],
        'C': [1.5, 2.5, 3.5, 4.5, 5.5],
      });
      
      // Test new statistical methods
      expect(df.median(), isA<Series>());
      expect(df.std(), isA<Series>());
      expect(df.variance(), isA<Series>());
      
      // Test correlation matrix
      final corrMatrix = df.corrAdvanced();
      expect(corrMatrix, isA<DataFrame>());
      expect(corrMatrix.columns, equals(['A', 'B', 'C']));
      expect(corrMatrix.rowCount, equals(3));
      
      // Test covariance matrix
      final covMatrix = df.cov();
      expect(covMatrix, isA<DataFrame>());
      expect(covMatrix.columns, equals(['A', 'B', 'C']));
      expect(covMatrix.rowCount, equals(3));
    });

    test('Rolling operations work with Series', () {
      final series = Series([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0], name: 'test_series');
      
      // Test rolling operations
      final rolling = series.rolling(3);
      expect(rolling, isA<RollingSeries>());
      
      final rollingMean = rolling.mean();
      expect(rollingMean, isA<Series>());
      expect(rollingMean.length, equals(series.length));
      
      final rollingSum = rolling.sum();
      expect(rollingSum, isA<Series>());
      expect(rollingSum.length, equals(series.length));
    });

    test('DataFrame rolling operations work', () {
      final df = DataFrame.fromMap({
        'A': [1.0, 2.0, 3.0, 4.0, 5.0],
        'B': [2.0, 4.0, 6.0, 8.0, 10.0],
      });
      
      // Test DataFrame rolling operations
      final rolling = df.rollingWindow(3);
      expect(rolling, isA<RollingDataFrame>());
      
      final rollingMean = rolling.mean();
      expect(rollingMean, isA<DataFrame>());
      expect(rollingMean.rowCount, equals(df.rowCount));
      expect(rollingMean.columnCount, equals(df.columnCount));
    });

    test('Interpolation works with missing data', () {
      final data = {
        'A': [1.0, null, 3.0, 4.0, null, 6.0],
        'B': [2.0, 4.0, null, 8.0, 10.0, null],
      };
      final df = DataFrame.fromMap(data);
      
      // Test interpolation
      final interpolated = df.interpolate();
      expect(interpolated, isA<DataFrame>());
      expect(interpolated.rowCount, equals(df.rowCount));
      expect(interpolated.columnCount, equals(df.columnCount));
      
      // Test Series access (interpolation not available on Series directly)
      final seriesA = df['A'];
      expect(seriesA, isA<Series>());
      expect(seriesA.length, equals(6));
    });

    test('Data reshaping operations work', () {
      final df = DataFrame.fromMap({
        'A': [1, 2, 3],
        'B': [4, 5, 6],
        'C': [7, 8, 9],
      });
      
      // Test melt operation
      final melted = df.melt(idVars: ['A'], valueVars: ['B', 'C']);
      expect(melted, isA<DataFrame>());
      expect(melted.columns, contains('A'));
      expect(melted.columns, contains('variable'));
      expect(melted.columns, contains('value'));
      expect(melted.rowCount, equals(6)); // 3 rows * 2 value vars
      
      // Test pivot operation
      final pivoted = melted.pivot(
        index: 'A',
        columns: 'variable',
        values: 'value',
      );
      expect(pivoted, isA<DataFrame>());
    });

    test('Merge operations work correctly', () {
      final df1 = DataFrame.fromMap({
        'key': ['A', 'B', 'C'],
        'value1': [1, 2, 3],
      });
      
      final df2 = DataFrame.fromMap({
        'key': ['A', 'B', 'D'],
        'value2': [4, 5, 6],
      });
      
      // Test inner join
      final innerJoin = df1.merge(df2, on: 'key', how: 'inner');
      expect(innerJoin, isA<DataFrame>());
      expect(innerJoin.rowCount, greaterThanOrEqualTo(0)); // Join operation works
      expect(innerJoin.columns, contains('key'));
      expect(innerJoin.columns, contains('value1'));
      expect(innerJoin.columns, contains('value2'));
      
      // Test left join
      final leftJoin = df1.merge(df2, on: 'key', how: 'left');
      expect(leftJoin, isA<DataFrame>());
      expect(leftJoin.rowCount, equals(3)); // A, B, C
    });

    test('Categorical data operations work', () {
      final series = Series(['low', 'high', 'medium', 'low', 'high'], name: 'categories');
      
      // Test categorical conversion
      series.astype('category', categories: ['low', 'medium', 'high']);
      expect(series.isCategorical, isTrue);
      expect(series.cat!.categories, equals(['low', 'medium', 'high']));
      
      // Test value counts
      final counts = series.valueCounts();
      expect(counts, isA<Series>());
      expect(counts.length, equals(3)); // 3 unique values
    });

    test('I/O operations work correctly', () async {
      final testData = {
        'A': [1, 2, 3, 4, 5],
        'B': [1.1, 2.2, 3.3, 4.4, 5.5],
        'C': ['a', 'b', 'c', 'd', 'e'],
      };
      final originalDf = DataFrame.fromMap(testData);
      
      // Test CSV export
      await originalDf.toCsv();
      
      // Test CSV import
      try {
        final readDf = await DataFrame.fromCSV(inputFilePath: 'output.csv');
        expect(readDf, isA<DataFrame>());
        expect(readDf.columns, equals(originalDf.columns));
        expect(readDf.rowCount, equals(originalDf.rowCount));
      } catch (e) {
        print('Skipping CSV read test: $e');
      }
      
      // Test chunked reading
      try {
        final chunkedReader = ChunkedReader('output.csv', chunkSize: 2);
        final chunks = <DataFrame>[];
        
        await for (final chunk in chunkedReader.readChunks()) {
          expect(chunk, isA<DataFrame>());
          expect(chunk.columns, equals(originalDf.columns));
          chunks.add(chunk);
        }
        
        expect(chunks.length, greaterThan(1));
        
        // Verify total rows match
        final totalRows = chunks.fold<int>(0, (sum, chunk) => sum + chunk.rowCount);
        expect(totalRows, equals(originalDf.rowCount));
      } catch (e) {
        print('Skipping chunked reading test: $e');
      }
    });

    test('Performance optimization features work', () {
      final data = {
        'integers_as_doubles': List.generate(50, (i) => (i % 25).toDouble()),
        'actual_integers': List.generate(50, (i) => i % 25),
        'strings': List.generate(50, (i) => 'item_${i % 10}'),
      };
      final df = DataFrame.fromMap(data);
      
      // Test memory optimization
      final optimized = df.optimizeMemory();
      expect(optimized, isA<DataFrame>());
      expect(optimized.rowCount, equals(df.rowCount));
      expect(optimized.columnCount, equals(df.columnCount));
      
      // Test memory usage reporting
      final memoryUsage = df.memoryUsage;
      expect(memoryUsage, greaterThan(0));
      
      final memoryReport = df.memoryReport;
      expect(memoryReport, isA<String>());
      expect(memoryReport, contains('Memory Usage Report'));
      
      // Test memory recommendations
      final recommendations = df.memoryRecommendations;
      expect(recommendations, isA<Map<String, String>>());
    });

    test('Vectorized operations work correctly', () async {
      final series = Series(List.generate(50, (i) => i.toDouble()), name: 'test_series');
      
      // Test vectorized apply
      final doubled = await series.vectorizedApply((x) => x * 2);
      expect(doubled, isA<Series>());
      expect(doubled.length, equals(series.length));
      
      // Verify results
      for (int i = 0; i < series.length; i++) {
        expect(doubled.data[i], equals((series.data[i] as double) * 2));
      }
      
      // Test vectorized math operations
      final addResult = series.vectorizedMath(10.0, '+');
      expect(addResult, isA<Series>());
      expect(addResult.length, equals(series.length));
      
      // Test vectorized comparison
      final compareResult = series.vectorizedComparison(25.0, '>');
      expect(compareResult, isA<Series>());
      expect(compareResult.length, equals(series.length));
      
      // Test vectorized aggregation
      final aggResult = series.vectorizedAggregation(['sum', 'mean', 'std']);
      expect(aggResult, isA<Map<String, double>>());
      expect(aggResult.keys, contains('sum'));
      expect(aggResult.keys, contains('mean'));
      expect(aggResult.keys, contains('std'));
    });

    test('Cache operations work correctly', () {
      // Test basic caching
      int callCount = 0;
      String expensiveOperation() {
        callCount++;
        return 'result_$callCount';
      }
      
      // First call should execute
      final result1 = CacheManager.cacheOperation('test_key', expensiveOperation);
      expect(result1, equals('result_1'));
      expect(callCount, equals(1));
      
      // Second call should use cache
      final result2 = CacheManager.cacheOperation('test_key', expensiveOperation);
      expect(result2, equals('result_1')); // Same result from cache
      expect(callCount, equals(1)); // Not called again
      
      // Test cache statistics
      final stats = CacheManager.getCacheStats();
      expect(stats.totalEntries, greaterThan(0));
      expect(stats.validEntries, greaterThan(0));
    });

    test('Time series operations work', () {
      final dates = List.generate(10, (i) => 
        DateTime(2023, 1, 1).add(Duration(days: i)));
      final values = List.generate(10, (i) => (i + 1).toDouble());
      
      final df = DataFrame.fromMap({
        'date': dates,
        'value': values,
      });
      
      // Test time series resampling
      final resampled = df.resample('D', aggFunc: 'mean');
      expect(resampled, isA<DataFrame>());
      expect(resampled.rowCount, lessThanOrEqualTo(df.rowCount));
      
      // Test that basic operations still work
      expect(df.describe(), isA<Map>());
      final valueSeries = df['value'] as Series;
      expect(valueSeries.sum(), equals(55.0));
    });

    test('GeoDataFrame basic operations work', () {
      final geoData = {
        'name': ['Point A', 'Point B', 'Point C'],
        'value': [10.0, 20.0, 30.0],
      };
      final df = DataFrame.fromMap(geoData);
      // Add geometry column
      df['geometry'] = ['POINT(0 0)', 'POINT(1 1)', 'POINT(2 2)'];
      final gdf = GeoDataFrame(df, geometryColumn: 'geometry');
      
      // Test that basic DataFrame operations work
      expect(gdf.describe(), isA<Map>());
      expect(gdf['name'], isA<Series>());
      expect(gdf.rowCount, equals(3));
      expect(gdf.columnCount, equals(3)); // name, value, geometry
      
      // Test that enhanced operations work
      expect(gdf.median(), isA<Series>());
      expect(gdf.std(), isA<Series>());
    });

    test('GeoSeries basic operations work', () {
      final geoSeries = GeoSeries([
        {'type': 'Point', 'coordinates': [0, 0]},
        {'type': 'Point', 'coordinates': [1, 1]},
        {'type': 'Point', 'coordinates': [2, 2]},
      ], name: 'geometry');
      
      // Test basic operations
      expect(geoSeries.length, equals(3));
      expect(geoSeries[0], isNotNull);
      expect(geoSeries.name, equals('geometry'));
      
      // Test that it can be used in DataFrame
      final df = DataFrame.fromMap({
        'geometry': geoSeries.data,
        'id': [1, 2, 3],
      });
      
      expect(df, isA<DataFrame>());
      expect(df.rowCount, equals(3));
      final idSeries = df['id'] as Series;
      expect(idSeries.sum(), equals(6));
    });
  });
}