import 'package:test/test.dart';
import 'package:dartframe/src/data_frame/data_frame.dart';
import 'package:dartframe/src/datacube/datacube.dart';
import 'package:dartframe/src/datacube/dataframe_integration.dart';
import 'package:dartframe/src/core/shape.dart';

void main() {
  group('DataFrame to DataCube', () {
    test('toDataCube', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6]
      ]);

      final cube = df.toDataCube();

      expect(cube.depth, 1);
      expect(cube.rows, 2);
      expect(cube.columns, 3);
      expect(cube.getValue([0, 0, 0]), 1);
      expect(cube.getValue([0, 1, 2]), 6);
    });

    test('stackFrames with other DataFrames', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);
      final df3 = DataFrame([
        [9, 10],
        [11, 12]
      ]);

      final cube = df1.stackFrames([df2, df3]);

      expect(cube.depth, 3);
      expect(cube.getValue([0, 0, 0]), 1);
      expect(cube.getValue([1, 0, 0]), 5);
      expect(cube.getValue([2, 1, 1]), 12);
    });

    test('isCompatibleWith - compatible', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);

      expect(df1.isCompatibleWith(df2), true);
    });

    test('isCompatibleWith - incompatible', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6, 7]
      ]);

      expect(df1.isCompatibleWith(df2), false);
    });

    test('isCompatibleWithAll - all compatible', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);
      final df3 = DataFrame([
        [9, 10],
        [11, 12]
      ]);

      expect(df1.isCompatibleWithAll([df2, df3]), true);
    });

    test('isCompatibleWithAll - some incompatible', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);
      final df3 = DataFrame([
        [9, 10, 11]
      ]);

      expect(df1.isCompatibleWithAll([df2, df3]), false);
    });
  });

  group('DataFrameStacker', () {
    test('stack', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);

      final cube = DataFrameStacker.stack([df1, df2]);

      expect(cube.depth, 2);
      expect(cube.rows, 2);
      expect(cube.columns, 2);
    });

    test('validateCompatibility - compatible', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);

      expect(DataFrameStacker.validateCompatibility([df1, df2]), true);
    });

    test('validateCompatibility - incompatible', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6, 7]
      ]);

      expect(DataFrameStacker.validateCompatibility([df1, df2]), false);
    });

    test('validateCompatibility - empty list', () {
      expect(DataFrameStacker.validateCompatibility([]), true);
    });

    test('validateCompatibility - single frame', () {
      final df = DataFrame([
        [1, 2],
        [3, 4]
      ]);

      expect(DataFrameStacker.validateCompatibility([df]), true);
    });

    test('getCommonShape - compatible', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);

      final shape = DataFrameStacker.getCommonShape([df1, df2]);

      expect(shape, isNotNull);
      expect(shape!.toList(), [2, 2]);
    });

    test('getCommonShape - incompatible', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6, 7]
      ]);

      final shape = DataFrameStacker.getCommonShape([df1, df2]);

      expect(shape, isNull);
    });

    test('getCommonShape - empty list', () {
      final shape = DataFrameStacker.getCommonShape([]);
      expect(shape, isNull);
    });

    test('filterByShape', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);
      final df3 = DataFrame([
        [9, 10, 11]
      ]);

      final targetShape = Shape.fromRowsColumns(2, 2);
      final filtered =
          DataFrameStacker.filterByShape([df1, df2, df3], targetShape);

      expect(filtered.length, 2);
      expect(filtered[0].shape.toList(), [2, 2]);
      expect(filtered[1].shape.toList(), [2, 2]);
    });

    test('groupByShape', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);
      final df3 = DataFrame([
        [9, 10, 11]
      ]);
      final df4 = DataFrame([
        [12, 13, 14]
      ]);

      final grouped = DataFrameStacker.groupByShape([df1, df2, df3, df4]);

      expect(grouped.length, 2);
      expect(grouped['2x2']?.length, 2);
      expect(grouped['1x3']?.length, 2);
    });

    test('tryStack - compatible', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);

      final cube = DataFrameStacker.tryStack([df1, df2]);

      expect(cube, isNotNull);
      expect(cube!.depth, 2);
    });

    test('tryStack - incompatible', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6, 7]
      ]);

      final cube = DataFrameStacker.tryStack([df1, df2]);

      expect(cube, isNull);
    });

    test('stackWithPadding - matching shapes', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);

      final cube = DataFrameStacker.stackWithPadding(
        [df1, df2],
        targetRows: 2,
        targetCols: 2,
      );

      expect(cube.depth, 2);
      expect(cube.rows, 2);
      expect(cube.columns, 2);
    });

    test('stackWithPadding - mismatched shapes throws', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6, 7]
      ]);

      expect(
        () => DataFrameStacker.stackWithPadding(
          [df1, df2],
          targetRows: 2,
          targetCols: 2,
        ),
        throwsUnimplementedError,
      );
    });
  });

  group('DataCube to DataFrame', () {
    test('toDataFrame - depth 1', () {
      final cube = DataCube.zeros(1, 3, 4);

      final df = cube.toDataFrame();

      expect(df.shape[0], 3);
      expect(df.shape[1], 4);
    });

    test('toDataFrame - depth > 1 throws', () {
      final cube = DataCube.zeros(3, 3, 4);

      expect(() => cube.toDataFrame(), throwsStateError);
    });

    test('tryToDataFrame - depth 1', () {
      final cube = DataCube.zeros(1, 3, 4);

      final df = cube.tryToDataFrame();

      expect(df, isNotNull);
      expect(df!.shape[0], 3);
      expect(df.shape[1], 4);
    });

    test('tryToDataFrame - depth > 1 returns null', () {
      final cube = DataCube.zeros(3, 3, 4);

      final df = cube.tryToDataFrame();

      expect(df, isNull);
    });

    test('unstack', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);

      final cube = DataCube.fromDataFrames([df1, df2]);
      final frames = cube.unstack();

      expect(frames.length, 2);
      expect(frames[0].iloc(0, 0), 1);
      expect(frames[1].iloc(1, 1), 8);
    });
  });

  group('Round-trip Conversion', () {
    test('DataFrame -> DataCube -> DataFrame', () {
      final original = DataFrame([
        [1, 2, 3],
        [4, 5, 6]
      ]);

      final cube = original.toDataCube();
      final restored = cube.toDataFrame();

      expect(restored.shape.toList(), original.shape.toList());
      expect(restored.iloc(0, 0), original.iloc(0, 0));
      expect(restored.iloc(1, 2), original.iloc(1, 2));
    });

    test('DataFrames -> DataCube -> DataFrames', () {
      final df1 = DataFrame([
        [1, 2],
        [3, 4]
      ]);
      final df2 = DataFrame([
        [5, 6],
        [7, 8]
      ]);

      final cube = DataCube.fromDataFrames([df1, df2]);
      final restored = cube.unstack();

      expect(restored.length, 2);
      expect(restored[0].iloc(0, 0), df1.iloc(0, 0));
      expect(restored[1].iloc(1, 1), df2.iloc(1, 1));
    });
  });
}
