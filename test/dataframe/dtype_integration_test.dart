import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DType Integration', () {
    group('DataFrame.dtypesDetailed', () {
      test('infers dtypes correctly', () {
        var df = DataFrame([
          [1, 'Alice', true, 3.14],
          [2, 'Bob', false, 2.71],
        ], columns: [
          'ID',
          'Name',
          'Active',
          'Score'
        ]);

        var dtypes = df.dtypesDetailed;

        expect(dtypes['ID'], isA<Int8DType>());
        expect(dtypes['Name'], isA<StringDType>());
        expect(dtypes['Active'], isA<BooleanDType>());
        expect(dtypes['Score'], isA<Float64DType>());
      });

      test('detects nullable types', () {
        var df = DataFrame([
          [1, 'Alice'],
          [null, 'Bob'],
          [3, null],
        ], columns: [
          'ID',
          'Name'
        ]);

        var dtypes = df.dtypesDetailed;

        expect(dtypes['ID']!.nullable, isTrue);
        expect(dtypes['Name']!.nullable, isTrue);
      });

      test('chooses smallest int type', () {
        var df1 = DataFrame([
          [1],
          [127],
        ], columns: [
          'Small'
        ]);

        expect(df1.dtypesDetailed['Small'], isA<Int8DType>());

        var df2 = DataFrame([
          [1],
          [32767],
        ], columns: [
          'Medium'
        ]);

        expect(df2.dtypesDetailed['Medium'], isA<Int16DType>());

        var df3 = DataFrame([
          [1],
          [2147483647],
        ], columns: [
          'Large'
        ]);

        expect(df3.dtypesDetailed['Large'], isA<Int32DType>());
      });
    });

    group('DataFrame.astype', () {
      test('converts single column', () {
        var df = DataFrame([
          [1, 2],
          [3, 4],
        ], columns: [
          'A',
          'B'
        ]);

        var df2 = df.astype({'A': DTypes.float64()});

        expect(df2['A'][0], isA<double>());
        expect(df2['B'][0], isA<int>());
      });

      test('converts multiple columns', () {
        var df = DataFrame([
          ['1', '2.5', 'true'],
          ['3', '4.5', 'false'],
        ], columns: [
          'A',
          'B',
          'C'
        ]);

        var df2 = df.astype({
          'A': DTypes.int32(),
          'B': DTypes.float64(),
          'C': DTypes.boolean(),
        });

        expect(df2['A'][0], equals(1));
        expect(df2['B'][0], equals(2.5));
        expect(df2['C'][0], equals(true));
      });

      test('converts using string dtype names', () {
        var df = DataFrame([
          ['1', '2'],
        ], columns: [
          'A',
          'B'
        ]);

        var df2 = df.astype({'A': 'int32', 'B': 'float64'});

        expect(df2['A'][0], isA<int>());
        expect(df2['B'][0], isA<double>());
      });

      test('handles conversion errors with raise', () {
        var df = DataFrame([
          ['not a number'],
        ], columns: [
          'A'
        ]);

        expect(() => df.astype({'A': DTypes.int32()}, errors: 'raise'),
            throwsException);
      });

      test('handles conversion errors with coerce', () {
        var df = DataFrame([
          ['not a number'],
          ['123'],
        ], columns: [
          'A'
        ]);

        var df2 = df.astype({'A': DTypes.int32()}, errors: 'coerce');

        expect(df2['A'][0], isNull);
        expect(df2['A'][1], equals(123));
      });

      test('handles conversion errors with ignore', () {
        var df = DataFrame([
          ['not a number'],
        ], columns: [
          'A'
        ]);

        var df2 = df.astype({'A': DTypes.int32()}, errors: 'ignore');

        expect(df2['A'][0], equals('not a number'));
      });
    });

    group('DataFrame.inferDTypes', () {
      test('optimizes dtypes automatically', () {
        var df = DataFrame([
          ['1', '2', '3'],
          ['4', '5', '6'],
        ], columns: [
          'A',
          'B',
          'C'
        ]);

        var optimized = df.inferDTypes();

        expect(optimized['A'][0], isA<int>());
        expect(optimized['B'][0], isA<int>());
      });

      test('downcasts integers', () {
        var df = DataFrame([
          [1, 1000, 100000],
          [2, 2000, 200000],
        ], columns: [
          'Small',
          'Medium',
          'Large'
        ]);

        var optimized = df.inferDTypes(downcast: 'integer');

        var dtypes = optimized.dtypesDetailed;
        expect(dtypes['Small'], isA<Int8DType>());
        expect(dtypes['Medium'], isA<Int16DType>());
        expect(dtypes['Large'], isA<Int32DType>());
      });

      test('downcasts floats', () {
        var df = DataFrame([
          [1.5, 2.5],
        ], columns: [
          'A',
          'B'
        ]);

        var optimized = df.inferDTypes(downcast: 'float');

        // Note: Dart doesn't distinguish between float32 and float64 at runtime
        // Both are represented as 'double', so dtypesDetailed will infer Float64
        var dtypes = optimized.dtypesDetailed;
        expect(dtypes['A'], isA<Float64DType>());
      });
    });

    group('DataFrame.memoryUsageByDType', () {
      test('calculates memory for fixed-size types', () {
        var df = DataFrame([
          [1, 2, 3],
          [4, 5, 6],
        ], columns: [
          'A',
          'B',
          'C'
        ]);

        var df2 = df.astype({'A': DTypes.int8()});
        var memory = df2.memoryUsageByDType();

        expect(memory['A'], equals(2)); // 2 rows * 1 byte
      });

      test('estimates memory for variable-size types', () {
        var df = DataFrame([
          ['hello', 'world'],
          ['foo', 'bar'],
        ], columns: [
          'A',
          'B'
        ]);

        var memory = df.memoryUsageByDType();

        expect(memory['A'], greaterThan(0));
        expect(memory['B'], greaterThan(0));
      });
    });

    group('Series.dtypeInfo', () {
      test('infers dtype correctly', () {
        var s1 = Series([1, 2, 3], name: 's1');
        expect(s1.dtypeInfo, isA<Int8DType>()); // [1,2,3] fits in Int8

        var s2 = Series([true, false, true], name: 's2');
        expect(s2.dtypeInfo, isA<BooleanDType>());

        var s3 = Series(['a', 'b', 'c'], name: 's3');
        expect(s3.dtypeInfo, isA<StringDType>());

        var s4 = Series([1.5, 2.5, 3.5], name: 's4');
        expect(s4.dtypeInfo, isA<Float64DType>());
      });

      test('detects nullable types', () {
        var s = Series([1, null, 3], name: 's');
        expect(s.dtypeInfo.nullable, isTrue);
      });
    });

    group('Series.astype', () {
      test('converts to different dtype', () {
        var s = Series([1, 2, 3], name: 's');
        var s2 = s.astype(DTypes.float64());

        expect(s2[0], isA<double>());
        expect(s2[0], equals(1.0));
      });

      test('converts using string dtype name', () {
        var s = Series(['1', '2', '3'], name: 's');
        var s2 = s.astype('int32');

        expect(s2[0], equals(1));
        expect(s2[1], equals(2));
      });

      test('handles conversion errors', () {
        var s = Series(['1', 'not a number', '3'], name: 's');

        var s2 = s.astype(DTypes.int32(), errors: 'coerce');
        expect(s2[0], equals(1));
        expect(s2[1], isNull);
        expect(s2[2], equals(3));
      });
    });

    group('Series.memoryUsageByDType', () {
      test('calculates memory usage', () {
        var s = Series([1, 2, 3], name: 's');
        var s2 = s.astype(DTypes.int8());

        var memory = s2.memoryUsageByDType();
        expect(memory, equals(3)); // 3 values * 1 byte (inferred as Int8)
      });
    });

    group('Integration Tests', () {
      test('complete dtype workflow', () {
        // Create DataFrame with mixed types
        var df = DataFrame([
          ['1', '100', 'true', '2024-01-01'],
          ['2', '200', 'false', '2024-01-02'],
          ['3', '300', 'true', '2024-01-03'],
        ], columns: [
          'ID',
          'Amount',
          'Active',
          'Date'
        ]);

        // Check initial dtypes - strings that look like numbers are inferred as numbers
        var dtypes1 = df.dtypesDetailed;
        expect(
            dtypes1['ID'], isA<Int8DType>()); // Inferred from parsable strings

        // Convert to appropriate types
        var df2 = df.astype({
          'ID': DTypes.int8(),
          'Amount': DTypes.int16(),
          'Active': DTypes.boolean(),
          'Date': DTypes.datetime(),
        });

        // Verify conversions
        expect(df2['ID'][0], equals(1));
        expect(df2['Amount'][0], equals(100));
        expect(df2['Active'][0], equals(true));
        expect(df2['Date'][0], isA<DateTime>());

        // Check memory usage
        var memory = df2.memoryUsageByDType();
        expect(memory['ID'], equals(3)); // 3 * 1 byte (Int8)
        expect(memory['Amount'], equals(6)); // 3 * 2 bytes (Int16)
      });

      test('automatic type inference and optimization', () {
        var df = DataFrame([
          [1, 100, 10000, 1.5],
          [2, 200, 20000, 2.5],
          [3, 300, 30000, 3.5],
        ], columns: [
          'Tiny',
          'Small',
          'Medium',
          'Float'
        ]);

        var optimized = df.inferDTypes(downcast: 'all');
        var dtypes = optimized.dtypesDetailed;

        expect(dtypes['Tiny'], isA<Int8DType>()); // [1,2,3] fits in Int8
        expect(dtypes['Small'], isA<Int16DType>()); // [100,200,300] needs Int16
        expect(dtypes['Medium'],
            isA<Int16DType>()); // [10000,20000,30000] fits in Int16
        // Note: Dart doesn't distinguish float32/float64 at runtime
        expect(dtypes['Float'], isA<Float64DType>());
      });
    });
  });
}
