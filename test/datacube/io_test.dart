import 'dart:io';
import 'package:test/test.dart';
import 'package:dartframe/src/data_cube/datacube.dart';
import 'package:dartframe/src/data_cube/io.dart';

void main() {
  // Cleanup helper
  Future<void> cleanup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  group('DataCube JSON I/O', () {
    final testFile = 'test_cube.json';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('save and load JSON file', () async {
      final cube =
          DataCube.generate(2, 3, 4, (d, r, c) => d * 100 + r * 10 + c);
      cube.attrs['name'] = 'test';

      await cube.toFile(testFile);

      final loaded = await DataCubeIO.fromFile(testFile);

      expect(loaded.depth, cube.depth);
      expect(loaded.rows, cube.rows);
      expect(loaded.columns, cube.columns);
      expect(loaded.getValue([0, 0, 0]), cube.getValue([0, 0, 0]));
      expect(loaded.getValue([1, 2, 3]), cube.getValue([1, 2, 3]));
      expect(loaded.attrs['name'], 'test');
    });

    test('load invalid file throws', () async {
      final file = File(testFile);
      await file.writeAsString('{"type": "Invalid"}');

      expect(
        () => DataCubeIO.fromFile(testFile),
        throwsFormatException,
      );
    });

    test('save small cube', () async {
      final cube = DataCube.ones(2, 2, 2);

      await cube.toFile(testFile);

      final file = File(testFile);
      expect(await file.exists(), true);

      final loaded = await DataCubeIO.fromFile(testFile);
      expect(loaded.getValue([0, 0, 0]), 1);
    });
  });

  group('DataCube CSV Directory I/O', () {
    final testDir = 'test_cube_csv';

    tearDown(() async {
      await cleanup(testDir);
    });

    test('save and load CSV directory', () async {
      final cube =
          DataCube.generate(3, 4, 5, (d, r, c) => d * 100 + r * 10 + c);
      cube.attrs['description'] = 'test cube';

      await cube.toCSVDirectory(testDir);

      // Check files exist
      final dir = Directory(testDir);
      expect(await dir.exists(), true);

      final metadataFile = File('$testDir/metadata.json');
      expect(await metadataFile.exists(), true);

      for (int i = 0; i < 3; i++) {
        final sheetFile = File('$testDir/sheet_$i.csv');
        expect(await sheetFile.exists(), true);
      }

      // Load back
      final loaded = await DataCubeIO.fromCSVDirectory(testDir);

      expect(loaded.depth, cube.depth);
      expect(loaded.rows, cube.rows);
      expect(loaded.columns, cube.columns);
      expect(loaded.attrs['description'], 'test cube');
    });

    test('load from non-existent directory throws', () async {
      expect(
        () => DataCubeIO.fromCSVDirectory('non_existent'),
        throwsFormatException,
      );
    });

    test('load from empty directory throws', () async {
      final dir = Directory(testDir);
      await dir.create();

      expect(
        () => DataCubeIO.fromCSVDirectory(testDir),
        throwsFormatException,
      );
    });

    test('save creates directory if not exists', () async {
      final cube = DataCube.zeros(2, 3, 4);

      await cube.toCSVDirectory(testDir);

      final dir = Directory(testDir);
      expect(await dir.exists(), true);
    });
  });

  group('DataCube Binary I/O', () {
    final testFile = 'test_cube.bin';

    tearDown(() async {
      await cleanup(testFile);
    });

    test('save and load binary file', () async {
      final cube =
          DataCube.generate(2, 3, 4, (d, r, c) => (d + r + c).toDouble());

      await cube.toBinaryFile(testFile);

      final file = File(testFile);
      expect(await file.exists(), true);

      final loaded = await DataCubeIO.fromBinaryFile(testFile);

      expect(loaded.depth, cube.depth);
      expect(loaded.rows, cube.rows);
      expect(loaded.columns, cube.columns);

      // Check values (with tolerance for binary encoding)
      for (int d = 0; d < cube.depth; d++) {
        for (int r = 0; r < cube.rows; r++) {
          for (int c = 0; c < cube.columns; c++) {
            expect(
              loaded.getValue([d, r, c]),
              closeTo(cube.getValue([d, r, c]), 0.001),
            );
          }
        }
      }
    });

    test('load invalid binary file throws', () async {
      final file = File(testFile);
      await file.writeAsBytes([1, 2, 3, 4]);

      expect(
        () => DataCubeIO.fromBinaryFile(testFile),
        throwsFormatException,
      );
    });

    test('binary file exists and is valid', () async {
      final cube = DataCube.zeros(10, 10, 10);

      await cube.toBinaryFile(testFile);

      final binFile = File(testFile);
      expect(await binFile.exists(), true);

      // Verify it can be loaded
      final loaded = await DataCubeIO.fromBinaryFile(testFile);
      expect(loaded.depth, 10);
      expect(loaded.rows, 10);
      expect(loaded.columns, 10);
    });
  });

  group('DataCube I/O Edge Cases', () {
    test('save and load single element cube', () async {
      final cube = DataCube.empty(1, 1, 1, fillValue: 42);
      final testFile = 'single_element.json';

      await cube.toFile(testFile);
      final loaded = await DataCubeIO.fromFile(testFile);

      expect(loaded.getValue([0, 0, 0]), 42);

      await cleanup(testFile);
    });

    test('save and load cube with attributes', () async {
      final cube = DataCube.zeros(2, 2, 2);
      cube.attrs['name'] = 'test';
      cube.attrs['version'] = 1;
      cube.attrs['tags'] = ['a', 'b', 'c'];

      final testFile = 'attrs_cube.json';

      await cube.toFile(testFile);
      final loaded = await DataCubeIO.fromFile(testFile);

      expect(loaded.attrs['name'], 'test');
      expect(loaded.attrs['version'], 1);
      expect(loaded.attrs['tags'], ['a', 'b', 'c']);

      await cleanup(testFile);
    });

    test('CSV directory with single sheet', () async {
      final cube = DataCube.zeros(1, 3, 4);
      final testDir = 'single_sheet';

      await cube.toCSVDirectory(testDir);
      final loaded = await DataCubeIO.fromCSVDirectory(testDir);

      expect(loaded.depth, 1);
      expect(loaded.rows, 3);
      expect(loaded.columns, 4);

      await cleanup(testDir);
    });
  });

  group('DataCube I/O Round-trip', () {
    test('JSON round-trip preserves data', () async {
      final original = DataCube.generate(
        3,
        4,
        5,
        (d, r, c) => d * 100 + r * 10 + c,
      );
      original.attrs['test'] = 'value';

      final testFile = 'roundtrip.json';

      await original.toFile(testFile);
      final loaded = await DataCubeIO.fromFile(testFile);

      // Check all values
      for (int d = 0; d < original.depth; d++) {
        for (int r = 0; r < original.rows; r++) {
          for (int c = 0; c < original.columns; c++) {
            expect(
              loaded.getValue([d, r, c]),
              original.getValue([d, r, c]),
            );
          }
        }
      }

      expect(loaded.attrs['test'], 'value');

      await cleanup(testFile);
    });

    test('CSV round-trip preserves structure', () async {
      final original = DataCube.ones(2, 3, 4);
      final testDir = 'csv_roundtrip';

      await original.toCSVDirectory(testDir);
      final loaded = await DataCubeIO.fromCSVDirectory(testDir);

      expect(loaded.depth, original.depth);
      expect(loaded.rows, original.rows);
      expect(loaded.columns, original.columns);

      await cleanup(testDir);
    });

    test('Binary round-trip preserves data', () async {
      final original = DataCube.generate(
        2,
        3,
        4,
        (d, r, c) => (d + r + c).toDouble(),
      );

      final testFile = 'binary_roundtrip.bin';

      await original.toBinaryFile(testFile);
      final loaded = await DataCubeIO.fromBinaryFile(testFile);

      expect(loaded.depth, original.depth);
      expect(loaded.rows, original.rows);
      expect(loaded.columns, original.columns);

      await cleanup(testFile);
    });
  });
}
