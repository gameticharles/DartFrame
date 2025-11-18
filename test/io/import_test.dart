import 'dart:io';
import 'package:dartframe/dartframe.dart';
import 'package:test/test.dart';

void main() {
  // Cleanup helper
  Future<void> cleanup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  group('NDArrayImport', () {
    final testArray = NDArray([
      [1, 2, 3],
      [4, 5, 6],
    ]);

    tearDown(() async {
      await cleanup('test_import.dcf');
      await cleanup('test_import.json');
      await cleanup('test_import.h5');
    });

    test('import from DCF', () async {
      await testArray.toDCF('test_import.dcf');

      final loaded = await NDArrayImport.fromDCF('test_import.dcf');

      expect(loaded.shape.toList(), equals([2, 3]));
      expect(loaded.getValue([0, 0]), equals(1));
      expect(loaded.getValue([1, 2]), equals(6));
    });

    test('import from JSON', () async {
      await testArray.toJSON('test_import.json');

      final loaded = await NDArrayImport.fromJSON('test_import.json');

      expect(loaded.shape.toList(), equals([2, 3]));
      expect(loaded.getValue([0, 0]), equals(1));
      expect(loaded.getValue([1, 2]), equals(6));
    });

    test('import from HDF5', () async {
      await testArray.toHDF5('test_import.h5');

      final loaded = await NDArrayImport.fromHDF5('test_import.h5');

      expect(loaded.shape.toList(), equals([2, 3]));
    }, skip: 'HDF5 writer not fully functional yet');

    test('auto-detect DCF format', () async {
      await testArray.toDCF('test_import.dcf');

      final loaded = await NDArrayImport.fromFile('test_import.dcf');

      expect(loaded.shape.toList(), equals([2, 3]));
    });

    test('auto-detect JSON format', () async {
      await testArray.toJSON('test_import.json');

      final loaded = await NDArrayImport.fromFile('test_import.json');

      expect(loaded.shape.toList(), equals([2, 3]));
    });

    test('auto-detect HDF5 format', () async {
      await testArray.toHDF5('test_import.h5');

      final loaded = await NDArrayImport.fromFile('test_import.h5');

      expect(loaded.shape.toList(), equals([2, 3]));
    }, skip: 'HDF5 writer not fully functional yet');

    test('unsupported format throws error', () async {
      expect(
        () => NDArrayImport.fromFile('test.xyz'),
        throwsArgumentError,
      );
    });

    test('unimplemented format throws error', () async {
      expect(
        () => NDArrayImport.fromParquet('test.parquet'),
        throwsUnimplementedError,
      );
    });
  });

  group('DataCubeImport', () {
    final testCube = DataCube.generate(2, 3, 4, (d, r, c) => d + r + c);

    tearDown(() async {
      await cleanup('test_cube_import.dcf');
      await cleanup('test_cube_import.json');
      await cleanup('test_cube_import.h5');
    });

    test('import from DCF', () async {
      await testCube.toDCF('test_cube_import.dcf');

      final loaded = await DataCubeImport.fromDCF('test_cube_import.dcf');

      expect(loaded.depth, equals(2));
      expect(loaded.rows, equals(3));
      expect(loaded.columns, equals(4));
    });

    test('import from JSON', () async {
      await testCube.toJSON('test_cube_import.json');

      final loaded = await DataCubeImport.fromJSON('test_cube_import.json');

      expect(loaded.depth, equals(2));
      expect(loaded.rows, equals(3));
      expect(loaded.columns, equals(4));
    });

    test('import from HDF5', () async {
      await testCube.toHDF5('test_cube_import.h5');

      final loaded = await DataCubeImport.fromHDF5('test_cube_import.h5');

      expect(loaded.depth, equals(2));
      expect(loaded.rows, equals(3));
      expect(loaded.columns, equals(4));
    }, skip: 'HDF5 writer not fully functional yet');

    test('auto-detect DCF format', () async {
      await testCube.toDCF('test_cube_import.dcf');

      final loaded = await DataCubeImport.fromFile('test_cube_import.dcf');

      expect(loaded.depth, equals(2));
    });

    test('auto-detect JSON format', () async {
      await testCube.toJSON('test_cube_import.json');

      final loaded = await DataCubeImport.fromFile('test_cube_import.json');

      expect(loaded.depth, equals(2));
    });

    test('auto-detect HDF5 format', () async {
      await testCube.toHDF5('test_cube_import.h5');

      final loaded = await DataCubeImport.fromFile('test_cube_import.h5');

      expect(loaded.depth, equals(2));
    }, skip: 'HDF5 writer not fully functional yet');

    test('unsupported format throws error', () async {
      expect(
        () => DataCubeImport.fromFile('test.xyz'),
        throwsArgumentError,
      );
    });

    test('unimplemented format throws error', () async {
      expect(
        () => DataCubeImport.fromParquet('test.parquet'),
        throwsUnimplementedError,
      );
    });
  });

  group('Import with attributes', () {
    tearDown(() async {
      await cleanup('test_attrs.dcf');
      await cleanup('test_attrs.h5');
    });

    test('DCF preserves attributes', () async {
      final array = NDArray([1, 2, 3]);
      array.attrs['units'] = 'meters';
      array.attrs['experiment'] = 'test-001';

      await array.toDCF('test_attrs.dcf');

      final loaded = await NDArrayImport.fromDCF('test_attrs.dcf');

      expect(loaded.attrs['units'], equals('meters'));
      expect(loaded.attrs['experiment'], equals('test-001'));
    });

    test('HDF5 preserves attributes', () async {
      final array = NDArray([1, 2, 3]);
      array.attrs['units'] = 'meters';
      array.attrs['description'] = 'Test data';

      await array.toHDF5('test_attrs.h5');

      final loaded = await NDArrayImport.fromHDF5('test_attrs.h5');

      expect(loaded.attrs['units'], equals('meters'));
      expect(loaded.attrs['description'], equals('Test data'));
    }, skip: 'HDF5 writer not fully functional yet');
  });

  group('Import edge cases', () {
    tearDown(() async {
      await cleanup('test_edge.dcf');
      await cleanup('test_edge.json');
    });

    test('import 1D array', () async {
      final array = NDArray([1, 2, 3, 4, 5]);
      await array.toDCF('test_edge.dcf');

      final loaded = await NDArrayImport.fromFile('test_edge.dcf');

      expect(loaded.shape.toList(), equals([5]));
      expect(loaded.ndim, equals(1));
    });

    test('import 3D array', () async {
      final array = NDArray.zeros([2, 3, 4]);
      await array.toDCF('test_edge.dcf');

      final loaded = await NDArrayImport.fromFile('test_edge.dcf');

      expect(loaded.shape.toList(), equals([2, 3, 4]));
      expect(loaded.ndim, equals(3));
    });

    test('import large array', () async {
      final array = NDArray.generate([100, 100], (i) => i[0] * 100 + i[1]);
      await array.toDCF('test_edge.dcf');

      final loaded = await NDArrayImport.fromFile('test_edge.dcf');

      expect(loaded.shape.toList(), equals([100, 100]));
      expect(loaded.getValue([50, 50]), equals(5050));
    });
  });
}
