import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrame.toHDF5() Integration Tests', () {
    late Directory testDir;

    setUp(() {
      testDir = Directory('test_output/dataframe_hdf5');
      if (!testDir.existsSync()) {
        testDir.createSync(recursive: true);
      }
    });

    tearDown(() {
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    });

    group('Compound Storage Strategy', () {
      test('writes numeric-only DataFrame', () async {
        final df = DataFrame([
          [1, 2.5, 3],
          [4, 5.5, 6],
          [7, 8.5, 9],
        ], columns: [
          'a',
          'b',
          'c'
        ]);

        final path = '${testDir.path}/numeric_compound.h5';
        await df.toHDF5(path, dataset: '/data');

        expect(File(path).existsSync(), isTrue);

        // Verify file has valid HDF5 signature
        final bytes = await File(path).readAsBytes();
        expect(bytes.sublist(0, 8), equals([137, 72, 68, 70, 13, 10, 26, 10]));
      });

      test('writes mixed datatype DataFrame', () async {
        final df = DataFrame([
          [1, 'Alice', 25.5, true],
          [2, 'Bob', 30.0, false],
          [3, 'Charlie', 35.2, true],
        ], columns: [
          'id',
          'name',
          'age',
          'active'
        ]);

        final path = '${testDir.path}/mixed_compound.h5';
        await df.toHDF5(path, dataset: '/users');

        expect(File(path).existsSync(), isTrue);

        // Verify file size is reasonable (should contain data)
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes DataFrame with string columns', () async {
        final df = DataFrame([
          ['Alice', 'Engineer', 'NYC'],
          ['Bob', 'Designer', 'LA'],
          ['Charlie', 'Manager', 'SF'],
        ], columns: [
          'name',
          'job',
          'city'
        ]);

        final path = '${testDir.path}/string_compound.h5';
        await df.toHDF5(path, dataset: '/employees');

        expect(File(path).existsSync(), isTrue);

        // Verify file has valid HDF5 structure
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes DataFrame with boolean columns', () async {
        final df = DataFrame([
          [true, false, true],
          [false, true, false],
          [true, true, true],
        ], columns: [
          'flag1',
          'flag2',
          'flag3'
        ]);

        final path = '${testDir.path}/boolean_compound.h5';
        await df.toHDF5(path, dataset: '/flags');

        expect(File(path).existsSync(), isTrue);

        // Verify file was created
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes large DataFrame', () async {
        final rows = List.generate(
          1000,
          (i) => [i, 'row_$i', i * 1.5, i % 2 == 0],
        );
        final df = DataFrame(rows, columns: ['id', 'name', 'value', 'even']);

        final path = '${testDir.path}/large_compound.h5';
        await df.toHDF5(path, dataset: '/data');

        expect(File(path).existsSync(), isTrue);

        // Verify file size is substantial for 1000 rows
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(5000));
      });

      test('writes DataFrame with custom attributes', () async {
        final df = DataFrame([
          [1, 2, 3],
          [4, 5, 6],
        ], columns: [
          'a',
          'b',
          'c'
        ]);

        final path = '${testDir.path}/with_attributes.h5';
        await df.toHDF5(
          path,
          dataset: '/data',
          options: const WriteOptions(
            attributes: {
              'description': 'Test data',
              'version': '1.0',
              'created': '2024-01-01',
            },
          ),
        );

        expect(File(path).existsSync(), isTrue);

        // Verify file was created
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes DataFrame to nested group path', () async {
        final df = DataFrame([
          [1, 2],
          [3, 4],
        ], columns: [
          'x',
          'y'
        ]);

        final path = '${testDir.path}/nested_groups.h5';
        await df.toHDF5(
          path,
          dataset: '/level1/level2/data',
          options: const WriteOptions(
            createIntermediateGroups: true,
          ),
        );

        expect(File(path).existsSync(), isTrue);

        // Verify file was created with nested structure
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });
    });

    group('Column-wise Storage Strategy', () {
      test('writes numeric-only DataFrame column-wise', () async {
        final df = DataFrame([
          [1.0, 2.0, 3.0],
          [4.0, 5.0, 6.0],
          [7.0, 8.0, 9.0],
        ], columns: [
          'x',
          'y',
          'z'
        ]);

        final path = '${testDir.path}/numeric_columnwise.h5';
        await df.toHDF5(
          path,
          dataset: '/measurements',
          options: const WriteOptions(
            dfStrategy: DataFrameStorageStrategy.columnwise,
          ),
        );

        expect(File(path).existsSync(), isTrue);

        // Verify file was created
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes integer DataFrame column-wise', () async {
        final df = DataFrame([
          [1, 10, 100],
          [2, 20, 200],
          [3, 30, 300],
        ], columns: [
          'col1',
          'col2',
          'col3'
        ]);

        final path = '${testDir.path}/integer_columnwise.h5';
        await df.toHDF5(
          path,
          dataset: '/data',
          options: const WriteOptions(
            dfStrategy: DataFrameStorageStrategy.columnwise,
          ),
        );

        expect(File(path).existsSync(), isTrue);

        // Verify file was created
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes mixed numeric types column-wise', () async {
        final df = DataFrame([
          [1, 2.5, 3],
          [4, 5.5, 6],
        ], columns: [
          'int_col',
          'float_col',
          'int_col2'
        ]);

        final path = '${testDir.path}/mixed_numeric_columnwise.h5';
        await df.toHDF5(
          path,
          dataset: '/data',
          options: const WriteOptions(
            dfStrategy: DataFrameStorageStrategy.columnwise,
          ),
        );

        expect(File(path).existsSync(), isTrue);

        // Verify file was created
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });
    });

    group('Various DataFrame Structures', () {
      test('writes single-row DataFrame', () async {
        final df = DataFrame([
          [1, 'Alice', 25.5]
        ], columns: [
          'id',
          'name',
          'age'
        ]);

        final path = '${testDir.path}/single_row.h5';
        await df.toHDF5(path, dataset: '/data');

        expect(File(path).existsSync(), isTrue);

        // Verify file was created
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes single-column DataFrame', () async {
        final df = DataFrame([
          [1],
          [2],
          [3]
        ], columns: [
          'value'
        ]);

        final path = '${testDir.path}/single_column.h5';
        await df.toHDF5(path, dataset: '/data');

        expect(File(path).existsSync(), isTrue);

        // Verify file was created
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes DataFrame with varying string lengths', () async {
        final df = DataFrame([
          [1, 'A'],
          [2, 'Medium length string'],
          [3, 'Very long string that should be handled correctly'],
        ], columns: [
          'id',
          'text'
        ]);

        final path = '${testDir.path}/varying_strings.h5';
        await df.toHDF5(path, dataset: '/data');

        expect(File(path).existsSync(), isTrue);

        // Verify file was created
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes DataFrame with special characters in column names',
          () async {
        final df = DataFrame([
          [1, 2, 3],
          [4, 5, 6],
        ], columns: [
          'col_1',
          'col-2',
          'col.3'
        ]);

        final path = '${testDir.path}/special_column_names.h5';
        await df.toHDF5(path, dataset: '/data');

        expect(File(path).existsSync(), isTrue);

        // Verify file was created
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes DataFrame with unicode column names', () async {
        final df = DataFrame([
          [1, 2, 3],
          [4, 5, 6],
        ], columns: [
          'température',
          '数据',
          'Größe'
        ]);

        final path = '${testDir.path}/unicode_columns.h5';
        await df.toHDF5(path, dataset: '/data');

        expect(File(path).existsSync(), isTrue);

        // Verify file was created
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(500));
      });

      test('writes wide DataFrame (many columns)', () async {
        final columns = List.generate(50, (i) => 'col_$i');
        final row = List.generate(50, (i) => i.toDouble());
        final df = DataFrame([row, row, row], columns: columns);

        final path = '${testDir.path}/wide_dataframe.h5';
        await df.toHDF5(path, dataset: '/data');

        expect(File(path).existsSync(), isTrue);

        // Verify file was created with substantial size
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(800));
      });

      test('writes tall DataFrame (many rows)', () async {
        final rows = List.generate(500, (i) => [i, i * 2.0, i * 3]);
        final df = DataFrame(rows, columns: ['a', 'b', 'c']);

        final path = '${testDir.path}/tall_dataframe.h5';
        await df.toHDF5(path, dataset: '/data');

        expect(File(path).existsSync(), isTrue);

        // Verify file was created with substantial size
        final fileSize = await File(path).length();
        expect(fileSize, greaterThan(4000));
      });
    });

    group('Both Storage Strategies', () {
      test('compound strategy creates valid HDF5 file', () async {
        final df = DataFrame([
          [1, 2.5, 3],
          [4, 5.5, 6],
        ], columns: [
          'a',
          'b',
          'c'
        ]);

        final path = '${testDir.path}/compound_strategy.h5';
        await df.toHDF5(
          path,
          dataset: '/data',
          options: const WriteOptions(
            dfStrategy: DataFrameStorageStrategy.compound,
          ),
        );

        expect(File(path).existsSync(), isTrue);

        // Verify HDF5 signature
        final bytes = await File(path).readAsBytes();
        expect(bytes.sublist(0, 8), equals([137, 72, 68, 70, 13, 10, 26, 10]));
      });

      test('column-wise strategy creates valid HDF5 file', () async {
        final df = DataFrame([
          [1.0, 2.0, 3.0],
          [4.0, 5.0, 6.0],
        ], columns: [
          'x',
          'y',
          'z'
        ]);

        final path = '${testDir.path}/columnwise_strategy.h5';
        await df.toHDF5(
          path,
          dataset: '/data',
          options: const WriteOptions(
            dfStrategy: DataFrameStorageStrategy.columnwise,
          ),
        );

        expect(File(path).existsSync(), isTrue);

        // Verify HDF5 signature
        final bytes = await File(path).readAsBytes();
        expect(bytes.sublist(0, 8), equals([137, 72, 68, 70, 13, 10, 26, 10]));
      });

      test('both strategies produce different file structures', () async {
        final df = DataFrame([
          [1.0, 2.0],
          [3.0, 4.0],
        ], columns: [
          'a',
          'b'
        ]);

        final compoundPath = '${testDir.path}/compare_compound.h5';
        final columnwisePath = '${testDir.path}/compare_columnwise.h5';

        await df.toHDF5(
          compoundPath,
          dataset: '/data',
          options: const WriteOptions(
            dfStrategy: DataFrameStorageStrategy.compound,
          ),
        );

        await df.toHDF5(
          columnwisePath,
          dataset: '/data',
          options: const WriteOptions(
            dfStrategy: DataFrameStorageStrategy.columnwise,
          ),
        );

        // Both files should exist
        expect(File(compoundPath).existsSync(), isTrue);
        expect(File(columnwisePath).existsSync(), isTrue);

        // Files should have different sizes (different internal structure)
        final compoundSize = await File(compoundPath).length();
        final columnwiseSize = await File(columnwisePath).length();
        expect(compoundSize, isNot(equals(columnwiseSize)));
      });
    });

    group('Error Handling', () {
      test('throws on empty file path', () async {
        final df = DataFrame([
          [1, 2]
        ], columns: [
          'a',
          'b'
        ]);

        expect(
          () => df.toHDF5('', dataset: '/data'),
          throwsA(isA<FileWriteError>()),
        );
      });

      test('handles invalid dataset path gracefully', () async {
        final df = DataFrame([
          [1, 2]
        ], columns: [
          'a',
          'b'
        ]);

        final path = '${testDir.path}/invalid_dataset.h5';

        // Invalid dataset path (missing leading slash) should be caught
        expect(
          () => df.toHDF5(path, dataset: 'invalid'),
          throwsA(isA<HDF5WriteError>()),
        );
      });
    });

    group('File Overwrite', () {
      test('overwrites existing file', () async {
        final df1 = DataFrame([
          [1, 2]
        ], columns: [
          'a',
          'b'
        ]);
        final df2 = DataFrame([
          [3, 4],
          [5, 6]
        ], columns: [
          'x',
          'y'
        ]);

        final path = '${testDir.path}/overwrite.h5';

        // Write first DataFrame
        await df1.toHDF5(path, dataset: '/data');
        final size1 = await File(path).length();

        // Overwrite with second DataFrame
        await df2.toHDF5(path, dataset: '/data');
        final size2 = await File(path).length();

        // File should exist and size should change
        expect(File(path).existsSync(), isTrue);
        expect(size2, isNot(equals(size1)));
      });
    });
  });
}
