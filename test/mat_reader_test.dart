import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';
import 'dart:io';

/// Tests for MATLAB v7.3 .mat file reader
///
/// Prerequisites:
/// 1. Run test/generate_test_files.m in MATLAB to create test files
/// 2. Copy the generated .mat files to test/data/ directory
void main() {
  // Path to test data directory
  final testDataDir = 'test/data';

  group('MAT Reader - Basic Functionality', () {
    test('List variables in numeric test file', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) {
        print(
            'Skipping: $filePath not found. Run generate_test_files.m first.');
        return;
      }

      final vars = await MATReader.listVariables(filePath);
      expect(vars, isNotEmpty);
      expect(vars, contains('scalar_double'));
      expect(vars, contains('matrix_small'));
    });

    test('Read scalar double value', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final value = await MATReader.readVariable(filePath, 'scalar_double');
      expect(value, equals(42.5));
    });

    test('Read 2D matrix', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final matrix = await MATReader.readVariable(filePath, 'matrix_small');
      expect(matrix, isA<NDArray>());

      final arr = matrix as NDArray;
      expect(arr.shape, equals([5, 5]));
      expect(arr.size, equals(25));
    });

    test('Get variable info', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final info = await MATReader.getVariableInfo(filePath, 'double_array');
      expect(info.matlabClass, equals(MatlabClass.double));
      expect(info.shape, equals([2, 3]));
      expect(info.size, equals(6));
    });
  });

  group('MAT Reader - Numeric Types', () {
    test('Read different integer types', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final int8Data = await MATReader.readVariable(filePath, 'int8_array');
      final uint16Data = await MATReader.readVariable(filePath, 'uint16_array');
      final int32Data = await MATReader.readVariable(filePath, 'int32_array');

      expect(int8Data, isA<NDArray>());
      expect(uint16Data, isA<NDArray>());
      expect(int32Data, isA<NDArray>());
    });

    test('Read single precision floats', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final singleData = await MATReader.readVariable(filePath, 'single_array');
      expect(singleData, isA<NDArray>());
    });

    test('Read vectors', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final rowVec = await MATReader.readVariable(filePath, 'vec_row');
      final colVec = await MATReader.readVariable(filePath, 'vec_col');

      expect(rowVec, isA<List>());
      expect(colVec, isA<List>());
    });
  });

  group('MAT Reader - Strings', () {
    test('Read character scalar', () async {
      final filePath = '$testDataDir/test_strings.mat';
      if (!await File(filePath).exists()) return;

      final charData = await MATReader.readVariable(filePath, 'char_scalar');
      expect(charData, isA<String>());
      expect(charData, equals('Hello'));
    });

    test('Read character array', () async {
      final filePath = '$testDataDir/test_strings.mat';
      if (!await File(filePath).exists()) return;

      final charArray = await MATReader.readVariable(filePath, 'char_2d');
      expect(charArray, isA<List>());
    });
  });

  group('MAT Reader - Logical Arrays', () {
    test('Read logical scalar', () async {
      final filePath = '$testDataDir/test_logical.mat';
      if (!await File(filePath).exists()) return;

      final logicalData =
          await MATReader.readVariable(filePath, 'logical_scalar');
      expect(logicalData, isA<List<bool>>());
    });

    test('Read logical vector', () async {
      final filePath = '$testDataDir/test_logical.mat';
      if (!await File(filePath).exists()) return;

      final logicalVec =
          await MATReader.readVariable(filePath, 'logical_vector');
      expect(logicalVec, isA<List<bool>>());
      expect(logicalVec.length, equals(5));
    });

    test('Read logical matrix', () async {
      final filePath = '$testDataDir/test_logical.mat';
      if (!await File(filePath).exists()) return;

      final logicalMat =
          await MATReader.readVariable(filePath, 'logical_matrix');
      expect(logicalMat, isA<List<bool>>());
    });
  });

  group('MAT Reader - Cell Arrays', () {
    test('Read simple cell array', () async {
      final filePath = '$testDataDir/test_cells.mat';
      if (!await File(filePath).exists()) return;

      final cellData = await MATReader.readVariable(filePath, 'cell_simple');
      expect(cellData, isA<List>());
    });

    test('Read mixed type cell array', () async {
      final filePath = '$testDataDir/test_cells.mat';
      if (!await File(filePath).exists()) return;

      final cellMixed = await MATReader.readVariable(filePath, 'cell_mixed');
      expect(cellMixed, isA<List>());
    });

    test('Read nested cell array', () async {
      final filePath = '$testDataDir/test_cells.mat';
      if (!await File(filePath).exists()) return;

      final cellNested = await MATReader.readVariable(filePath, 'cell_nested');
      expect(cellNested, isA<List>());
    });
  });

  group('MAT Reader - Structures', () {
    test('Read simple structure', () async {
      final filePath = '$testDataDir/test_structures.mat';
      if (!await File(filePath).exists()) return;

      final structData =
          await MATReader.readVariable(filePath, 'struct_simple');
      expect(structData, isA<Map>());

      final struct = structData as Map;
      expect(struct.containsKey('name'), isTrue);
      expect(struct.containsKey('age'), isTrue);
      expect(struct.containsKey('scores'), isTrue);
    });

    test('Read nested structure', () async {
      final filePath = '$testDataDir/test_structures.mat';
      if (!await File(filePath).exists()) return;

      final structNested =
          await MATReader.readVariable(filePath, 'struct_nested');
      expect(structNested, isA<Map>());

      final struct = structNested as Map;
      expect(struct.containsKey('person'), isTrue);
      expect(struct.containsKey('location'), isTrue);
    });

    test('Read structure with mixed field types', () async {
      final filePath = '$testDataDir/test_structures.mat';
      if (!await File(filePath).exists()) return;

      final structMixed =
          await MATReader.readVariable(filePath, 'struct_mixed');
      expect(structMixed, isA<Map>());

      final struct = structMixed as Map;
      expect(struct['id'], isNotNull);
      expect(struct['name'], isA<String>());
      expect(struct['matrix'], isNotNull);
    });
  });

  group('MAT Reader - Edge Cases', () {
    test('Read empty arrays', () async {
      final filePath = '$testDataDir/test_edge_cases.mat';
      if (!await File(filePath).exists()) return;

      final emptyDouble =
          await MATReader.readVariable(filePath, 'empty_double');
      expect(emptyDouble, isA<List>());
    });

    test('Read special numeric values', () async {
      final filePath = '$testDataDir/test_edge_cases.mat';
      if (!await File(filePath).exists()) return;

      final infValue = await MATReader.readVariable(filePath, 'inf_value');
      expect(infValue, equals(double.infinity));

      final nanValue = await MATReader.readVariable(filePath, 'nan_value');
      expect(nanValue, isNaN);
    });

    test('Read single element', () async {
      final filePath = '$testDataDir/test_edge_cases.mat';
      if (!await File(filePath).exists()) return;

      final singleElem =
          await MATReader.readVariable(filePath, 'single_element');
      expect(singleElem, equals(42));
    });
  });

  group('MAT Reader - FileReader Integration', () {
    test('Read via FileReader.read()', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final df = await FileReader.read(filePath,
          options: {'variable': 'matrix_small'});
      expect(df, isA<DataFrame>());
    });

    test('Read via FileReader.readMAT()', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final df = await FileReader.readMAT(filePath, variable: 'double_array');
      expect(df, isA<DataFrame>());
    });

    test('List variables via FileReader', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final vars = await FileReader.listMATVariables(filePath);
      expect(vars, isNotEmpty);
    });

    test('Inspect file via FileReader', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final info = await FileReader.inspectMAT(filePath);
      expect(info, containsPair('variables', isA<List>()));
      expect(info, containsPair('variableCount', greaterThan(0)));
    });
  });

  group('MAT Reader - Read All', () {
    test('Read all variables from file', () async {
      final filePath = '$testDataDir/test_numeric.mat';
      if (!await File(filePath).exists()) return;

      final allData = await MATReader.readAll(filePath);
      expect(allData, isA<Map<String, dynamic>>());
      expect(allData.keys, isNotEmpty);
    });
  });

  group('MAT Reader - Multidimensional Arrays', () {
    test('Read 3D array', () async {
      final filePath = '$testDataDir/test_multidim.mat';
      if (!await File(filePath).exists()) return;

      final array3d = await MATReader.readVariable(filePath, 'array_3d');
      expect(array3d, isA<NDArray>());

      final arr = array3d as NDArray;
      expect(arr.ndim, equals(3));
    });

    test('Read 4D array', () async {
      final filePath = '$testDataDir/test_multidim.mat';
      if (!await File(filePath).exists()) return;

      final array4d = await MATReader.readVariable(filePath, 'array_4d');
      expect(array4d, isA<NDArray>());

      final arr = array4d as NDArray;
      expect(arr.ndim, equals(4));
    });
  });

  group('MAT Reader - Complex Data', () {
    test('Read complex experiment data structure', () async {
      final filePath = '$testDataDir/test_complex.mat';
      if (!await File(filePath).exists()) return;

      final expData = await MATReader.readVariable(filePath, 'experiment_data');
      expect(expData, isA<Map>());

      final data = expData as Map;
      expect(data.containsKey('samples'), isTrue);
      expect(data.containsKey('metadata'), isTrue);
      expect(data.containsKey('results'), isTrue);
    });
  });
}
