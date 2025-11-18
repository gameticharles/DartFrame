import 'package:test/test.dart';
import 'package:dartframe/src/datacube/datacube.dart';
import 'package:dartframe/src/datacube/aggregations.dart';

void main() {
  group('DataCube Aggregations - Depth', () {
    test('aggregateDepth sum', () {
      final cube = DataCube.generate(3, 2, 2, (d, r, c) => d + 1);
      // Sheet 0: all 1s, Sheet 1: all 2s, Sheet 2: all 3s
      // Sum across depth: all 6s

      final result = cube.aggregateDepth('sum');

      expect(result.shape[0], 2);
      expect(result.shape[1], 2);
      expect(result.iloc(0, 0), 6);
      expect(result.iloc(1, 1), 6);
    });

    test('aggregateDepth mean', () {
      final cube = DataCube.generate(3, 2, 2, (d, r, c) => d + 1);

      final result = cube.aggregateDepth('mean');

      expect(result.iloc(0, 0), 2.0);
      expect(result.iloc(1, 1), 2.0);
    });

    test('aggregateDepth max', () {
      final cube = DataCube.generate(3, 2, 2, (d, r, c) => d + 1);

      final result = cube.aggregateDepth('max');

      expect(result.iloc(0, 0), 3);
      expect(result.iloc(1, 1), 3);
    });

    test('aggregateDepth min', () {
      final cube = DataCube.generate(3, 2, 2, (d, r, c) => d + 1);

      final result = cube.aggregateDepth('min');

      expect(result.iloc(0, 0), 1);
      expect(result.iloc(1, 1), 1);
    });
  });

  group('DataCube Aggregations - Rows', () {
    test('aggregateRows sum', () {
      final cube = DataCube.generate(2, 3, 2, (d, r, c) => r + 1);
      // Each sheet has rows [1,1], [2,2], [3,3]
      // Sum across rows: [6, 6]

      final result = cube.aggregateRows('sum');

      expect(result.shape[0], 2);
      expect(result.shape[1], 2);
      expect(result.iloc(0, 0), 6);
      expect(result.iloc(1, 1), 6);
    });

    test('aggregateRows mean', () {
      final cube = DataCube.generate(2, 3, 2, (d, r, c) => r + 1);

      final result = cube.aggregateRows('mean');

      expect(result.iloc(0, 0), 2.0);
      expect(result.iloc(1, 1), 2.0);
    });
  });

  group('DataCube Aggregations - Columns', () {
    test('aggregateColumns sum', () {
      final cube = DataCube.generate(2, 2, 3, (d, r, c) => c + 1);
      // Each row has [1, 2, 3]
      // Sum across columns: 6

      final result = cube.aggregateColumns('sum');

      expect(result.shape[0], 2);
      expect(result.shape[1], 2);
      expect(result.iloc(0, 0), 6);
      expect(result.iloc(1, 1), 6);
    });

    test('aggregateColumns mean', () {
      final cube = DataCube.generate(2, 2, 3, (d, r, c) => c + 1);

      final result = cube.aggregateColumns('mean');

      expect(result.iloc(0, 0), 2.0);
      expect(result.iloc(1, 1), 2.0);
    });
  });

  group('DataCube Statistical Operations', () {
    test('sum with axis', () {
      final cube = DataCube.ones(3, 4, 5);

      final depthSum = cube.sum(axis: 0);
      expect(depthSum.shape[0], 4);
      expect(depthSum.shape[1], 5);
      expect(depthSum.iloc(0, 0), 3);

      final rowSum = cube.sum(axis: 1);
      expect(rowSum.shape[0], 3);
      expect(rowSum.shape[1], 5);
      expect(rowSum.iloc(0, 0), 4);

      final colSum = cube.sum(axis: 2);
      expect(colSum.shape[0], 3);
      expect(colSum.shape[1], 4);
      expect(colSum.iloc(0, 0), 5);
    });

    test('sum without axis', () {
      final cube = DataCube.ones(3, 4, 5);

      final total = cube.sum();

      expect(total.shape[0], 1);
      expect(total.shape[1], 1);
      expect(total.iloc(0, 0), 60);
    });

    test('mean with axis', () {
      final cube = DataCube.empty(3, 4, 5, fillValue: 2);

      final depthMean = cube.mean(axis: 0);
      expect(depthMean.iloc(0, 0), 2.0);

      final rowMean = cube.mean(axis: 1);
      expect(rowMean.iloc(0, 0), 2.0);

      final colMean = cube.mean(axis: 2);
      expect(colMean.iloc(0, 0), 2.0);
    });

    test('mean without axis', () {
      final cube = DataCube.empty(3, 4, 5, fillValue: 2);

      final total = cube.mean();

      expect(total.iloc(0, 0), 2.0);
    });

    test('max with axis', () {
      final cube =
          DataCube.generate(3, 4, 5, (d, r, c) => d * 100 + r * 10 + c);

      final depthMax = cube.max(axis: 0);
      expect(depthMax.iloc(0, 0), 200);

      final rowMax = cube.max(axis: 1);
      expect(rowMax.iloc(0, 0), 30);

      final colMax = cube.max(axis: 2);
      expect(colMax.iloc(0, 0), 4);
    });

    test('max without axis', () {
      final cube =
          DataCube.generate(2, 2, 2, (d, r, c) => d * 100 + r * 10 + c);

      final total = cube.max();

      expect(total.iloc(0, 0), 111);
    });

    test('min with axis', () {
      final cube =
          DataCube.generate(3, 4, 5, (d, r, c) => d * 100 + r * 10 + c);

      final depthMin = cube.min(axis: 0);
      expect(depthMin.iloc(0, 0), 0);

      final rowMin = cube.min(axis: 1);
      expect(rowMin.iloc(0, 0), 0);

      final colMin = cube.min(axis: 2);
      expect(colMin.iloc(0, 0), 0);
    });

    test('min without axis', () {
      final cube =
          DataCube.generate(2, 2, 2, (d, r, c) => d * 100 + r * 10 + c);

      final total = cube.min();

      expect(total.iloc(0, 0), 0);
    });
  });

  group('DataCube Advanced Aggregations', () {
    test('std with axis', () {
      final cube = DataCube.generate(3, 2, 2, (d, r, c) => d);

      final result = cube.std(axis: 0);

      expect(result.shape[0], 2);
      expect(result.shape[1], 2);
      // Values are 0, 1, 2 -> std ≈ 0.816
      expect(result.iloc(0, 0), closeTo(0.816, 0.01));
    });

    test('std without axis', () {
      final cube = DataCube.generate(2, 2, 2, (d, r, c) => d);

      final result = cube.std();

      expect(result.shape[0], 1);
      expect(result.shape[1], 1);
    });

    test('variance with axis', () {
      final cube = DataCube.generate(3, 2, 2, (d, r, c) => d);

      final result = cube.variance(axis: 0);

      expect(result.shape[0], 2);
      expect(result.shape[1], 2);
      // Values are 0, 1, 2 -> variance ≈ 0.667
      expect(result.iloc(0, 0), closeTo(0.667, 0.01));
    });

    test('variance without axis', () {
      final cube = DataCube.generate(2, 2, 2, (d, r, c) => d);

      final result = cube.variance();

      expect(result.shape[0], 1);
      expect(result.shape[1], 1);
    });

    test('prod with axis', () {
      final cube = DataCube.generate(2, 2, 2, (d, r, c) => d + 1);

      final result = cube.prod(axis: 0);

      expect(result.shape[0], 2);
      expect(result.shape[1], 2);
      expect(result.iloc(0, 0), 2); // 1 * 2
    });

    test('prod without axis', () {
      final cube = DataCube.generate(2, 2, 2, (d, r, c) => 2);

      final result = cube.prod();

      expect(result.iloc(0, 0), 256); // 2^8
    });
  });

  group('DataCube Aggregation Edge Cases', () {
    test('invalid axis throws', () {
      final cube = DataCube.zeros(2, 3, 4);

      expect(() => cube.aggregateDepth('invalid'), throwsArgumentError);
    });

    test('single element cube', () {
      final cube = DataCube.empty(1, 1, 1, fillValue: 42);

      final sum = cube.sum();
      expect(sum.iloc(0, 0), 42);

      final mean = cube.mean();
      expect(mean.iloc(0, 0), 42.0);
    });

    test('aggregation preserves data types', () {
      final cube = DataCube.generate(2, 2, 2, (d, r, c) => d + r + c);

      final sum = cube.sum(axis: 0);
      expect(sum.iloc(0, 0), isA<num>());

      final mean = cube.mean(axis: 0);
      expect(mean.iloc(0, 0), isA<num>());
    });
  });
}
