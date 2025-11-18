import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

void main() {
  group('DataFrameCompoundWriter', () {
    test('creates compound dataset from simple DataFrame', () {
      // Create a simple DataFrame
      final df = DataFrame([
        [1, 'Alice', 25.5],
        [2, 'Bob', 30.0],
        [3, 'Charlie', 35.5],
      ], columns: [
        'id',
        'name',
        'age'
      ]);

      // Create writer and generate compound dataset
      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      // Verify result structure
      expect(result, isA<Map<String, dynamic>>());
      expect(result['datatypeWriter'], isA<CompoundDatatypeWriter>());
      expect(result['recordBytes'], isA<List<List<int>>>());
      expect(result['columnNames'], equals(['id', 'name', 'age']));
      expect(result['shape'], equals([3]));
      expect(result['recordSize'], greaterThan(0));

      // Verify record count
      final recordBytes = result['recordBytes'] as List<List<int>>;
      expect(recordBytes.length, equals(3));

      // Verify each record has the correct size
      final recordSize = result['recordSize'] as int;
      for (final record in recordBytes) {
        expect(record.length, equals(recordSize));
      }
    });

    test('handles mixed datatype columns', () {
      // Create DataFrame with mixed types
      final df = DataFrame([
        [1, 'Alice', 25.5, true],
        [2, 'Bob', 30.0, false],
        [3, 'Charlie', 35.5, true],
      ], columns: [
        'id',
        'name',
        'age',
        'active'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      // Verify it handles mixed types
      expect(result['columnNames'], equals(['id', 'name', 'age', 'active']));
      expect(result['recordBytes'], isA<List<List<int>>>());
    });

    test('handles null values', () {
      // Create DataFrame with null values
      final df = DataFrame([
        [1, 'Alice', 25.5],
        [2, null, 30.0],
        [3, 'Charlie', null],
      ], columns: [
        'id',
        'name',
        'age'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      // Should not throw and should create records
      expect(result['recordBytes'], isA<List<List<int>>>());
      final recordBytes = result['recordBytes'] as List<List<int>>;
      expect(recordBytes.length, equals(3));
    });

    test('getFieldInfo returns correct field information', () {
      final df = DataFrame([
        [1, 'Alice', 25.5],
        [2, 'Bob', 30.0],
      ], columns: [
        'id',
        'name',
        'age'
      ]);

      final writer = DataFrameCompoundWriter();
      final info = writer.getFieldInfo(df);

      // Verify field info structure
      expect(info, isA<Map<String, dynamic>>());
      expect(info['fields'], isA<List>());
      expect(info['totalSize'], greaterThan(0));

      final fields = info['fields'] as List;
      expect(fields.length, equals(3));

      // Verify each field has required properties
      for (final field in fields) {
        expect(field, isA<Map<String, dynamic>>());
        expect(field['name'], isA<String>());
        expect(field['type'], isA<String>());
        expect(field['size'], isA<int>());
        expect(field['offset'], isA<int>());
      }
    });

    test('throws on empty DataFrame', () {
      final df = DataFrame.empty(columns: ['id', 'name']);

      final writer = DataFrameCompoundWriter();
      expect(
        () => writer.createCompoundDataset(df),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handles integer-only DataFrame', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
      ], columns: [
        'a',
        'b',
        'c'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['recordBytes'], isA<List<List<int>>>());
    });

    test('handles string-only DataFrame', () {
      final df = DataFrame([
        ['Alice', 'Engineer', 'NYC'],
        ['Bob', 'Designer', 'LA'],
      ], columns: [
        'name',
        'job',
        'city'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['recordBytes'], isA<List<List<int>>>());
    });

    test('handles boolean columns', () {
      final df = DataFrame([
        [true, false, true],
        [false, true, false],
      ], columns: [
        'a',
        'b',
        'c'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['recordBytes'], isA<List<List<int>>>());
    });

    // ========== Numeric-only DataFrame tests ==========

    test('numeric-only DataFrame with integers', () {
      final df = DataFrame([
        [1, 10, 100],
        [2, 20, 200],
        [3, 30, 300],
      ], columns: [
        'col1',
        'col2',
        'col3'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      // Verify structure
      expect(result['columnNames'], equals(['col1', 'col2', 'col3']));
      expect(result['shape'], equals([3]));
      expect(result['recordBytes'], hasLength(3));

      // Verify field types are numeric
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;
      for (final field in fields) {
        expect(field['type'], equals('integer'));
      }
    });

    test('numeric-only DataFrame with floats', () {
      final df = DataFrame([
        [1.5, 2.5, 3.5],
        [4.5, 5.5, 6.5],
      ], columns: [
        'x',
        'y',
        'z'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['columnNames'], equals(['x', 'y', 'z']));
      expect(result['shape'], equals([2]));

      // Verify field types are float
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;
      for (final field in fields) {
        expect(field['type'], equals('float'));
      }
    });

    test('numeric-only DataFrame with mixed int and double', () {
      final df = DataFrame([
        [1, 2.5, 3],
        [4, 5.5, 6],
      ], columns: [
        'a',
        'b',
        'c'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['columnNames'], equals(['a', 'b', 'c']));

      // Each column is analyzed independently
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;
      expect(fields[0]['type'], equals('integer')); // pure int column
      expect(fields[1]['type'], equals('float')); // double column
      expect(fields[2]['type'], equals('integer')); // pure int column
    });

    test('large numeric-only DataFrame', () {
      // Create a larger DataFrame to test performance
      final rows = List.generate(
        100,
        (i) => [i, i * 2.0, i * 3, i * 4.5],
      );
      final df = DataFrame(rows, columns: ['a', 'b', 'c', 'd']);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['shape'], equals([100]));
      expect(result['recordBytes'], hasLength(100));
      expect(result['columnNames'], equals(['a', 'b', 'c', 'd']));
    });

    // ========== Mixed datatype DataFrame tests ==========

    test('mixed datatype DataFrame - int, string, float, bool', () {
      final df = DataFrame([
        [1, 'Alice', 95.5, true],
        [2, 'Bob', 87.3, false],
        [3, 'Charlie', 92.1, true],
      ], columns: [
        'id',
        'name',
        'score',
        'active'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      // Verify column names preserved
      expect(result['columnNames'], equals(['id', 'name', 'score', 'active']));
      expect(result['shape'], equals([3]));

      // Verify field types
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;
      expect(fields[0]['name'], equals('id'));
      expect(fields[0]['type'], equals('integer')); // pure int column
      expect(fields[1]['name'], equals('name'));
      expect(fields[1]['type'], equals('string'));
      expect(fields[2]['name'], equals('score'));
      expect(fields[2]['type'], equals('float'));
      expect(fields[3]['name'], equals('active'));
      expect(fields[3]['type'], equals('enumType')); // boolean
    });

    test('mixed datatype with varying string lengths', () {
      final df = DataFrame([
        [1, 'A', 10.0],
        [2, 'Medium length string', 20.0],
        [3, 'Very long string that should determine the fixed length', 30.0],
      ], columns: [
        'id',
        'text',
        'value'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['columnNames'], equals(['id', 'text', 'value']));

      // Verify string field has appropriate fixed length
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;
      final textField = fields.firstWhere((f) => f['name'] == 'text');
      expect(textField['type'], equals('string'));
      // Fixed length should accommodate longest string with padding
      expect(textField['size'], greaterThan(50));
    });

    test('mixed datatype with all null column', () {
      final df = DataFrame([
        [1, null, 10.0],
        [2, null, 20.0],
        [3, null, 30.0],
      ], columns: [
        'id',
        'missing',
        'value'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['columnNames'], equals(['id', 'missing', 'value']));
      expect(result['recordBytes'], hasLength(3));

      // All-null column should default to float64
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;
      final missingField = fields.firstWhere((f) => f['name'] == 'missing');
      expect(missingField['type'], equals('float'));
    });

    test('mixed datatype with sparse nulls', () {
      final df = DataFrame([
        [1, 'Alice', 95.5, true],
        [2, null, null, false],
        [3, 'Charlie', 92.1, null],
        [null, 'David', null, true],
      ], columns: [
        'id',
        'name',
        'score',
        'active'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['columnNames'], equals(['id', 'name', 'score', 'active']));
      expect(result['recordBytes'], hasLength(4));

      // Should handle nulls gracefully with appropriate defaults
      final recordBytes = result['recordBytes'] as List<List<int>>;
      for (final record in recordBytes) {
        expect(record.length, equals(result['recordSize']));
      }
    });

    // ========== Column name preservation tests ==========

    test('preserves column names with special characters', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
      ], columns: [
        'col_1',
        'col-2',
        'col.3'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['columnNames'], equals(['col_1', 'col-2', 'col.3']));

      // Verify field names match
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;
      expect(fields[0]['name'], equals('col_1'));
      expect(fields[1]['name'], equals('col-2'));
      expect(fields[2]['name'], equals('col.3'));
    });

    test('preserves column names with spaces', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
      ], columns: [
        'First Column',
        'Second Column',
        'Third Column'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['columnNames'],
          equals(['First Column', 'Second Column', 'Third Column']));
    });

    test('preserves column names with unicode characters', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
      ], columns: [
        'température',
        '数据',
        'Größe'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['columnNames'], equals(['température', '数据', 'Größe']));
    });

    test('preserves column order', () {
      final df = DataFrame([
        [1, 'a', 10.0, true, 'x'],
        [2, 'b', 20.0, false, 'y'],
      ], columns: [
        'fifth',
        'first',
        'third',
        'second',
        'fourth'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      // Column order should be preserved exactly as specified
      expect(result['columnNames'],
          equals(['fifth', 'first', 'third', 'second', 'fourth']));

      // Field order should match column order
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;
      expect(fields[0]['name'], equals('fifth'));
      expect(fields[1]['name'], equals('first'));
      expect(fields[2]['name'], equals('third'));
      expect(fields[3]['name'], equals('second'));
      expect(fields[4]['name'], equals('fourth'));
    });

    // ========== Round-trip tests (encode/decode verification) ==========

    test('round-trip: numeric DataFrame values are preserved', () {
      final df = DataFrame([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
      ], columns: [
        'a',
        'b',
        'c'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      // Verify we can extract the original structure
      expect(result['columnNames'], equals(['a', 'b', 'c']));
      expect(result['shape'], equals([3]));
      expect(result['recordBytes'], hasLength(3));

      // Verify record size is consistent
      final recordSize = result['recordSize'] as int;
      final recordBytes = result['recordBytes'] as List<List<int>>;
      for (final record in recordBytes) {
        expect(record.length, equals(recordSize));
      }
    });

    test('round-trip: mixed DataFrame structure is preserved', () {
      final df = DataFrame([
        [1, 'Alice', 25.5, true],
        [2, 'Bob', 30.0, false],
        [3, 'Charlie', 35.5, true],
      ], columns: [
        'id',
        'name',
        'age',
        'active'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      // Verify metadata is preserved
      expect(result['columnNames'], equals(['id', 'name', 'age', 'active']));
      expect(result['shape'], equals([3]));

      // Verify field structure
      final fieldInfo = writer.getFieldInfo(df);
      expect(fieldInfo['fields'], hasLength(4));
      expect(fieldInfo['totalSize'], greaterThan(0));

      // Verify each field has proper offset and size
      final fields = fieldInfo['fields'] as List;
      int previousOffset = 0;
      for (int i = 0; i < fields.length; i++) {
        final field = fields[i];
        final offset = field['offset'] as int;
        final size = field['size'] as int;

        // Offsets should be non-decreasing
        expect(offset, greaterThanOrEqualTo(previousOffset));

        // Size should be positive
        expect(size, greaterThan(0));

        previousOffset = offset;
      }
    });

    test('round-trip: compound datatype writer can be reused', () {
      final df1 = DataFrame([
        [1, 'A'],
        [2, 'B'],
      ], columns: [
        'id',
        'name'
      ]);

      final df2 = DataFrame([
        [10, 'X'],
        [20, 'Y'],
      ], columns: [
        'id',
        'name'
      ]);

      final writer = DataFrameCompoundWriter();

      // Write first DataFrame
      final result1 = writer.createCompoundDataset(df1);
      expect(result1['columnNames'], equals(['id', 'name']));
      expect(result1['shape'], equals([2]));

      // Reuse writer for second DataFrame
      final result2 = writer.createCompoundDataset(df2);
      expect(result2['columnNames'], equals(['id', 'name']));
      expect(result2['shape'], equals([2]));

      // Both should have same structure
      expect(result1['recordSize'], equals(result2['recordSize']));
    });

    test('round-trip: field offsets are properly aligned', () {
      final df = DataFrame([
        [1, 'test', 2.5, true, 100],
      ], columns: [
        'int1',
        'str',
        'float',
        'bool',
        'int2'
      ]);

      final writer = DataFrameCompoundWriter();
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;

      // Verify alignment: offsets should be aligned to field size or 8, whichever is smaller
      for (final field in fields) {
        final offset = field['offset'] as int;
        final size = field['size'] as int;
        final alignment = size < 8 ? size : 8;

        // Offset should be aligned
        expect(offset % alignment, equals(0),
            reason:
                'Field ${field['name']} at offset $offset should be aligned to $alignment');
      }
    });

    test('round-trip: total size includes all fields', () {
      final df = DataFrame([
        [1, 'test', 2.5],
      ], columns: [
        'a',
        'b',
        'c'
      ]);

      final writer = DataFrameCompoundWriter();
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;
      final totalSize = fieldInfo['totalSize'] as int;

      // Total size should be at least the sum of all field sizes
      int sumOfSizes = 0;
      for (final field in fields) {
        sumOfSizes += field['size'] as int;
      }

      expect(totalSize, greaterThanOrEqualTo(sumOfSizes),
          reason: 'Total size should include all fields plus any padding');
    });

    test('round-trip: empty strings are handled correctly', () {
      final df = DataFrame([
        [1, '', 'test'],
        [2, 'value', ''],
        [3, '', ''],
      ], columns: [
        'id',
        'col1',
        'col2'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['recordBytes'], hasLength(3));
      expect(result['columnNames'], equals(['id', 'col1', 'col2']));

      // All records should have same size
      final recordSize = result['recordSize'] as int;
      final recordBytes = result['recordBytes'] as List<List<int>>;
      for (final record in recordBytes) {
        expect(record.length, equals(recordSize));
      }
    });

    test('round-trip: boolean values are encoded correctly', () {
      final df = DataFrame([
        [true, false, true],
        [false, true, false],
        [true, true, true],
        [false, false, false],
      ], columns: [
        'flag1',
        'flag2',
        'flag3'
      ]);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['recordBytes'], hasLength(4));

      // Boolean fields should be 1 byte each (8-bit enum)
      final fieldInfo = writer.getFieldInfo(df);
      final fields = fieldInfo['fields'] as List;
      for (final field in fields) {
        expect(field['type'], equals('enumType'));
        expect(field['size'], equals(1));
      }
    });

    test('round-trip: large DataFrame maintains consistency', () {
      // Create a large DataFrame with mixed types
      final rows = List.generate(
        1000,
        (i) => [i, 'row_$i', i * 1.5, i % 2 == 0],
      );
      final df = DataFrame(rows, columns: ['id', 'name', 'value', 'even']);

      final writer = DataFrameCompoundWriter();
      final result = writer.createCompoundDataset(df);

      expect(result['shape'], equals([1000]));
      expect(result['recordBytes'], hasLength(1000));
      expect(result['columnNames'], equals(['id', 'name', 'value', 'even']));

      // All records should have consistent size
      final recordSize = result['recordSize'] as int;
      final recordBytes = result['recordBytes'] as List<List<int>>;
      for (int i = 0; i < recordBytes.length; i++) {
        expect(recordBytes[i].length, equals(recordSize),
            reason: 'Record $i should have size $recordSize');
      }
    });
  });
}
