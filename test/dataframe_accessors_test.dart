import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame.iloc Accessor', () {
    var df = DataFrame(
      [
        [1, 2.0, 'a'],
        [4, 5.0, 'b'],
        [7, 8.0, 'c'],
        [10, 11.0, 'd'],
      ],
      columns: ['col1', 'col2', 'col3'],
      index: ['r1', 'r2', 'r3', 'r4'],
    );

    test('df.iloc[rowIndex]', () {
      var series = df.iloc[1];
      expect(series, isA<Series>());
      expect(series.data, equals([4, 5.0, 'b']));
      expect(series.name, equals('r2')); // Row index label used as name
      expect(series.index, equals(['col1', 'col2', 'col3']));
      
      var seriesLast = df.iloc[3];
      expect(seriesLast.data, equals([10, 11.0, 'd']));
      expect(seriesLast.name, equals('r4'));
    });

    test('df.iloc[rowIndex, colIndex]', () {
      var value = df.iloc[0][1];
      expect(value, equals(2.0));
      var value2 = df.iloc[2][ 2];
      expect(value2, equals('c'));
    });

    test('df.iloc[rowIndex, List<int> colIndices]', () {
      var series = df.iloc[1][ [0, 2]];
      expect(series, isA<Series>());
      expect(series.data, equals([4, 'b']));
      expect(series.name, equals('r2'));
      expect(series.index, equals(['col1', 'col3']));
    });

    test('df.iloc[List<int> rowIndices]', () {
      var newDf = df.iloc[[0, 2]];
      expect(newDf, isA<DataFrame>());
      expect(newDf.rowCount, equals(2));
      expect(newDf.columnCount, equals(3));
      expect(newDf.rows, equals([[1, 2.0, 'a'], [7, 8.0, 'c']]));
      expect(newDf.columns, equals(['col1', 'col2', 'col3']));
      expect(newDf.index, equals(['r1', 'r3']));
    });

    test('df.iloc[List<int> rowIndices, colIndex]', () {
      var series = df.iloc[[0, 2, 3]][ 1];
      expect(series, isA<Series>());
      expect(series.data, equals([2.0, 8.0, 11.0]));
      expect(series.name, equals('col2')); // Column name used as name
      expect(series.index, equals(['r1', 'r3', 'r4']));
    });

    test('df.iloc[List<int> rowIndices, List<int> colIndices]', () {
      var newDf = df.iloc[[1, 3]][ [0, 2]];
      expect(newDf, isA<DataFrame>());
      expect(newDf.rowCount, equals(2));
      expect(newDf.columnCount, equals(2));
      expect(newDf.rows, equals([[4, 'b'], [10, 'd']]));
      expect(newDf.columns, equals(['col1', 'col3']));
      expect(newDf.index, equals(['r2', 'r4']));
    });

    test('iloc out-of-bounds errors', () {
      expect(() => df.iloc[10], throwsA(isA<RangeError>()));
      expect(() => df.iloc[0][ 10], throwsA(isA<RangeError>()));
      expect(() => df.iloc[[0][ 10]], throwsA(isA<RangeError>()));
      expect(() => df.iloc[[0]][ [0,10]], throwsA(isA<RangeError>()));
    });
  });

  group('DataFrame.loc Accessor', () {
    var dfStrIdx = DataFrame(
      [
        [1, 2.0, 'apple'],
        [4, 5.0, 'banana'],
        [7, 8.0, 'cherry'],
      ],
      columns: ['intCol', 'floatCol', 'strCol'],
      index: ['rowA', 'rowB', 'rowC'],
    );

    // DataFrame with integer labels for index (distinct from positional)
    var dfIntIdx = DataFrame(
      [
        [10, 20],
        [30, 40],
      ],
      columns: [100, 200], // Integer column labels
      index: [10, 20],    // Integer row labels
    );

    test('df.loc[rowLabel]', () {
      var series = dfStrIdx.loc['rowB'];
      expect(series, isA<Series>());
      expect(series.data, equals([4, 5.0, 'banana']));
      expect(series.name, equals('rowB'));
      expect(series.index, equals(['intCol', 'floatCol', 'strCol']));
      
      var seriesInt = dfIntIdx.loc[10];
      expect(seriesInt.data, equals([10,20]));
      expect(seriesInt.name, equals('10'));
      expect(seriesInt.index, equals([100,200]));
    });

    test('df.loc[rowLabel, colLabel]', () {
      var value = dfStrIdx.loc['rowA'][ 'floatCol'];
      expect(value, equals(2.0));
      
      var valueInt = dfIntIdx.loc[20][ 100];
      expect(valueInt, equals(30));
    });

    test('df.loc[rowLabel, List<String> colLabels]', () {
      var series = dfStrIdx.loc['rowC'][ ['intCol', 'strCol']];
      expect(series, isA<Series>());
      expect(series.data, equals([7, 'cherry']));
      expect(series.name, equals('rowC'));
      expect(series.index, equals(['intCol', 'strCol']));

      var seriesInt = dfIntIdx.loc[10][ [200, 100]]; // Order matters for selection
      expect(seriesInt.data, equals([20,10]));
      expect(seriesInt.index, equals([200,100]));
    });

    test('df.loc[List<dynamic> rowLabels]', () {
      var newDf = dfStrIdx.loc[['rowA', 'rowC']];
      expect(newDf, isA<DataFrame>());
      expect(newDf.rowCount, equals(2));
      expect(newDf.rows, equals([[1, 2.0, 'apple'], [7, 8.0, 'cherry']]));
      expect(newDf.columns, equals(['intCol', 'floatCol', 'strCol']));
      expect(newDf.index, equals(['rowA', 'rowC']));

      var newDfInt = dfIntIdx.loc[[20,10]]; // Order matters
      expect(newDfInt.rows, equals([[30,40],[10,20]]));
      expect(newDfInt.index, equals([20,10]));
    });

    test('df.loc[List<dynamic> rowLabels, colLabel]', () {
      var series = dfStrIdx.loc[['rowA', 'rowB']][ 'strCol'];
      expect(series, isA<Series>());
      expect(series.data, equals(['apple', 'banana']));
      expect(series.name, equals('strCol'));
      expect(series.index, equals(['rowA', 'rowB']));

      var seriesInt = dfIntIdx.loc[[10,20]][ 200];
      expect(seriesInt.data, equals([20,40]));
      expect(seriesInt.name, equals('200'));
      expect(seriesInt.index, equals([10,20]));
    });

    test('df.loc[List<dynamic> rowLabels, List<String> colLabels]', () {
      var newDf = dfStrIdx.loc[['rowC', 'rowA']][ ['strCol', 'intCol']];
      expect(newDf, isA<DataFrame>());
      expect(newDf.rowCount, equals(2));
      expect(newDf.rows, equals([['cherry', 7], ['apple', 1]]));
      expect(newDf.columns, equals(['strCol', 'intCol']));
      expect(newDf.index, equals(['rowC', 'rowA']));
    });

    test('loc label-not-found errors', () {
      expect(() => dfStrIdx.loc['nonExistentRow'], throwsA(isA<ArgumentError>()));
      expect(() => dfStrIdx.loc['rowA'][ 'nonExistentCol'], throwsA(isA<ArgumentError>()));
      expect(() => dfStrIdx.loc[['rowA', 'nonExistentRow']], throwsA(isA<ArgumentError>()));
      expect(() => dfStrIdx.loc[['rowA']][ ['intCol', 'nonExistentCol']], throwsA(isA<ArgumentError>()));
      
      expect(() => dfIntIdx.loc[99], throwsA(isA<ArgumentError>()));
      expect(() => dfIntIdx.loc[10][ 999], throwsA(isA<ArgumentError>()));
    });
  });
}
